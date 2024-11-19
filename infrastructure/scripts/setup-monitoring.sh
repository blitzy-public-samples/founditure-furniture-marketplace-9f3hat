#!/bin/bash

# Human Tasks:
# 1. Verify Kubernetes cluster access and permissions
# 2. Configure MinIO credentials for Tempo storage
# 3. Set up SMTP server credentials for email alerts
# 4. Configure Slack webhook URL for notifications
# 5. Set up PagerDuty integration keys
# 6. Review storage class configurations for persistent volumes
# 7. Validate network policies allow monitoring stack communication

# Required versions:
# docker-ce: 24.0+
# kubernetes-cli: 1.27+

set -euo pipefail

# Global variables
NAMESPACE="${MONITORING_NAMESPACE:-founditure-monitoring}"
GRAFANA_VERSION="${GRAFANA_VERSION:-9.5.0}"
PROMETHEUS_VERSION="${PROMETHEUS_VERSION:-2.45.0}"
ALERTMANAGER_VERSION="${ALERTMANAGER_VERSION:-0.25.0}"
LOKI_VERSION="${LOKI_VERSION:-2.8.0}"
TEMPO_VERSION="${TEMPO_VERSION:-2.2.0}"

# Setup monitoring namespace
# Addresses requirement: System Monitoring - Centralized metrics collection
setup_namespace() {
    echo "Setting up monitoring namespace..."
    
    if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
        kubectl create namespace "$NAMESPACE"
    fi
    
    # Label namespace for network policies
    kubectl label namespace "$NAMESPACE" \
        purpose=monitoring \
        environment=production \
        --overwrite
    
    # Apply resource quotas
    cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ResourceQuota
metadata:
  name: monitoring-quota
  namespace: $NAMESPACE
spec:
  hard:
    requests.cpu: "8"
    requests.memory: 16Gi
    limits.cpu: "16"
    limits.memory: 32Gi
    persistentvolumeclaims: "10"
EOF

    # Apply network policies
    cat <<EOF | kubectl apply -f -
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: monitoring-network-policy
  namespace: $NAMESPACE
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: default
    ports:
    - protocol: TCP
      port: 9090
    - protocol: TCP
      port: 3000
    - protocol: TCP
      port: 9093
EOF
}

# Deploy Prometheus
# Addresses requirement: Production Monitoring - 24/7 production monitoring
deploy_prometheus() {
    echo "Deploying Prometheus..."
    
    # Create ConfigMap from prometheus.yml
    kubectl create configmap prometheus-config \
        --from-file=../monitoring/prometheus/prometheus.yml \
        --from-file=../monitoring/prometheus/rules/alert.rules \
        --from-file=../monitoring/prometheus/rules/recording.rules \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy Prometheus StatefulSet
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: prometheus
  namespace: $NAMESPACE
spec:
  serviceName: prometheus
  replicas: 1
  selector:
    matchLabels:
      app: prometheus
  template:
    metadata:
      labels:
        app: prometheus
    spec:
      containers:
      - name: prometheus
        image: prom/prometheus:v${PROMETHEUS_VERSION}
        args:
        - --config.file=/etc/prometheus/prometheus.yml
        - --storage.tsdb.path=/prometheus
        - --storage.tsdb.retention.time=15d
        - --web.enable-lifecycle
        ports:
        - containerPort: 9090
        volumeMounts:
        - name: prometheus-config
          mountPath: /etc/prometheus
        - name: prometheus-storage
          mountPath: /prometheus
      volumes:
      - name: prometheus-config
        configMap:
          name: prometheus-config
  volumeClaimTemplates:
  - metadata:
      name: prometheus-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 50Gi
EOF

    # Create Prometheus Service
    kubectl create service clusterip prometheus \
        --tcp=9090:9090 \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
}

# Deploy Grafana
# Addresses requirement: System Monitoring - Centralized monitoring system
deploy_grafana() {
    echo "Deploying Grafana..."
    
    # Create ConfigMap for datasources
    kubectl create configmap grafana-datasources \
        --from-file=../monitoring/grafana/provisioning/datasources/datasource.yml \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy Grafana StatefulSet
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: grafana
  namespace: $NAMESPACE
spec:
  serviceName: grafana
  replicas: 1
  selector:
    matchLabels:
      app: grafana
  template:
    metadata:
      labels:
        app: grafana
    spec:
      containers:
      - name: grafana
        image: grafana/grafana:${GRAFANA_VERSION}
        ports:
        - containerPort: 3000
        env:
        - name: GF_SECURITY_ADMIN_PASSWORD
          valueFrom:
            secretKeyRef:
              name: grafana-admin
              key: password
        volumeMounts:
        - name: grafana-storage
          mountPath: /var/lib/grafana
        - name: grafana-datasources
          mountPath: /etc/grafana/provisioning/datasources
      volumes:
      - name: grafana-datasources
        configMap:
          name: grafana-datasources
  volumeClaimTemplates:
  - metadata:
      name: grafana-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
EOF

    # Create Grafana Service
    kubectl create service clusterip grafana \
        --tcp=3000:3000 \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
}

# Deploy Alertmanager
# Addresses requirement: Security Monitoring - Real-time monitoring and alerting
deploy_alertmanager() {
    echo "Deploying Alertmanager..."
    
    # Create ConfigMap from alertmanager.yml
    kubectl create configmap alertmanager-config \
        --from-file=../monitoring/alertmanager/alertmanager.yml \
        --from-file=../monitoring/alertmanager/templates/default.tmpl \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy Alertmanager StatefulSet
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: alertmanager
  namespace: $NAMESPACE
spec:
  serviceName: alertmanager
  replicas: 1
  selector:
    matchLabels:
      app: alertmanager
  template:
    metadata:
      labels:
        app: alertmanager
    spec:
      containers:
      - name: alertmanager
        image: prom/alertmanager:v${ALERTMANAGER_VERSION}
        args:
        - --config.file=/etc/alertmanager/alertmanager.yml
        - --storage.path=/alertmanager
        ports:
        - containerPort: 9093
        volumeMounts:
        - name: alertmanager-config
          mountPath: /etc/alertmanager
        - name: alertmanager-storage
          mountPath: /alertmanager
      volumes:
      - name: alertmanager-config
        configMap:
          name: alertmanager-config
  volumeClaimTemplates:
  - metadata:
      name: alertmanager-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 5Gi
EOF

    # Create Alertmanager Service
    kubectl create service clusterip alertmanager \
        --tcp=9093:9093 \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
}

# Deploy Loki logging stack
# Addresses requirement: System Monitoring - Centralized log aggregation
deploy_logging() {
    echo "Deploying Loki logging stack..."
    
    # Create ConfigMap from loki.yml
    kubectl create configmap loki-config \
        --from-file=../monitoring/loki/loki.yml \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy Loki StatefulSet
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: loki
  namespace: $NAMESPACE
spec:
  serviceName: loki
  replicas: 1
  selector:
    matchLabels:
      app: loki
  template:
    metadata:
      labels:
        app: loki
    spec:
      containers:
      - name: loki
        image: grafana/loki:${LOKI_VERSION}
        args:
        - -config.file=/etc/loki/loki.yml
        ports:
        - containerPort: 3100
        volumeMounts:
        - name: loki-config
          mountPath: /etc/loki
        - name: loki-storage
          mountPath: /data
      volumes:
      - name: loki-config
        configMap:
          name: loki-config
  volumeClaimTemplates:
  - metadata:
      name: loki-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 50Gi
EOF

    # Create Loki Service
    kubectl create service clusterip loki \
        --tcp=3100:3100 \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
}

# Deploy Tempo distributed tracing
# Addresses requirement: System Monitoring - Distributed tracing implementation
deploy_tracing() {
    echo "Deploying Tempo tracing..."
    
    # Create ConfigMap from tempo.yml
    kubectl create configmap tempo-config \
        --from-file=../monitoring/tempo/tempo.yml \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
    
    # Deploy Tempo StatefulSet
    cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: tempo
  namespace: $NAMESPACE
spec:
  serviceName: tempo
  replicas: 1
  selector:
    matchLabels:
      app: tempo
  template:
    metadata:
      labels:
        app: tempo
    spec:
      containers:
      - name: tempo
        image: grafana/tempo:${TEMPO_VERSION}
        args:
        - -config.file=/etc/tempo/tempo.yml
        ports:
        - containerPort: 3200
        - containerPort: 9095
        volumeMounts:
        - name: tempo-config
          mountPath: /etc/tempo
        - name: tempo-storage
          mountPath: /data
      volumes:
      - name: tempo-config
        configMap:
          name: tempo-config
  volumeClaimTemplates:
  - metadata:
      name: tempo-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 50Gi
EOF

    # Create Tempo Service
    kubectl create service clusterip tempo \
        --tcp=3200:3200,9095:9095 \
        -n "$NAMESPACE" \
        --dry-run=client -o yaml | kubectl apply -f -
}

# Verify monitoring stack deployment
# Addresses requirement: Production Monitoring - Full metrics collection and alerting
verify_monitoring() {
    echo "Verifying monitoring stack deployment..."
    
    # Wait for all pods to be ready
    kubectl wait --for=condition=ready pod \
        -l app in (prometheus,grafana,alertmanager,loki,tempo) \
        -n "$NAMESPACE" \
        --timeout=300s
    
    # Verify service endpoints
    for service in prometheus grafana alertmanager loki tempo; do
        if ! kubectl get service "$service" -n "$NAMESPACE" &>/dev/null; then
            echo "Error: $service service not found"
            return 1
        fi
    done
    
    # Check Prometheus targets
    if ! kubectl exec -n "$NAMESPACE" prometheus-0 -- \
        wget -qO- http://localhost:9090/api/v1/targets | grep -q "health\":\"up\""; then
        echo "Error: Prometheus targets not healthy"
        return 1
    fi
    
    # Verify Grafana datasources
    if ! kubectl exec -n "$NAMESPACE" grafana-0 -- \
        curl -s http://admin:admin@localhost:3000/api/datasources | grep -q "Prometheus"; then
        echo "Error: Grafana datasources not configured"
        return 1
    fi
    
    echo "Monitoring stack verification completed successfully"
    return 0
}

# Main script execution
main() {
    echo "Starting monitoring stack deployment..."
    
    setup_namespace
    deploy_prometheus
    deploy_grafana
    deploy_alertmanager
    deploy_logging
    deploy_tracing
    verify_monitoring
    
    echo "Monitoring stack deployment completed"
}

main "$@"