// External dependencies
import { Counter, Gauge, Histogram } from 'prom-client'; // v14.2.0
import dayjs from 'dayjs'; // v1.11.9

// Internal dependencies
import { UserMetrics, ListingMetrics } from '../models/metrics.model';
import { Logger } from '../../../shared/utils/logger';
import { metricsConfig } from '../config';

// Initialize logger
const logger = new Logger('metrics-util');

/**
 * Human Tasks:
 * 1. Configure Prometheus server endpoint for metrics scraping
 * 2. Set up Grafana dashboards for metrics visualization
 * 3. Configure alerting thresholds for key metrics
 * 4. Set up ELK Stack integration for metrics logging
 * 5. Review and adjust metric weights based on business feedback
 */

// Initialize Prometheus metrics
const userEngagementHistogram = new Histogram({
  name: 'founditure_user_engagement_score',
  help: 'Distribution of user engagement scores',
  buckets: [10, 20, 30, 40, 50, 60, 70, 80, 90, 100]
});

const furnitureRecoveryCounter = new Counter({
  name: 'founditure_furniture_items_recovered',
  help: 'Total number of furniture items successfully recovered'
});

const environmentalImpactGauge = new Gauge({
  name: 'founditure_environmental_impact_tons',
  help: 'Total tons of furniture waste diverted from landfills'
});

/**
 * Calculates user engagement score based on activity metrics
 * Requirement: User Adoption Tracking - Track 100,000 active users target
 */
export const calculateUserEngagement = (metrics: UserMetrics): number => {
  try {
    // Calculate listing creation score (30% weight)
    const listingScore = Math.min((metrics.listingsCreated / 10) * 100, 100) * 0.3;

    // Calculate points earned score (40% weight)
    const pointsScore = Math.min((metrics.totalPoints / 1000) * 100, 100) * 0.4;

    // Calculate recency score (30% weight)
    const daysSinceActive = dayjs().diff(metrics.lastActive, 'days');
    const recencyScore = Math.max(100 - (daysSinceActive * 5), 0) * 0.3;

    // Calculate total engagement score
    const totalScore = Math.round(listingScore + pointsScore + recencyScore);

    // Record metric in Prometheus
    userEngagementHistogram.observe(totalScore);

    logger.info('User engagement score calculated', {
      userId: metrics.userId,
      score: totalScore
    });

    return totalScore;
  } catch (error) {
    logger.error('Error calculating user engagement score', error);
    throw error;
  }
};

/**
 * Calculates furniture recovery rate statistics
 * Requirement: Environmental Impact Measurement - Track 1,000 tons diverted
 */
export const calculateFurnitureRecoveryRate = (
  listings: ListingMetrics[],
  timeframe: string
): { percentage: number; totalCount: number; successCount: number } => {
  try {
    const startDate = dayjs().subtract(1, timeframe as any);
    const filteredListings = listings.filter(listing => 
      dayjs(listing.createdAt).isAfter(startDate)
    );

    const totalListings = filteredListings.length;
    const successfulRecoveries = filteredListings.filter(l => l.wasCollected).length;
    const recoveryPercentage = totalListings > 0 
      ? Math.round((successfulRecoveries / totalListings) * 100)
      : 0;

    // Update Prometheus counter
    furnitureRecoveryCounter.inc(successfulRecoveries);

    logger.info('Furniture recovery rate calculated', {
      timeframe,
      percentage: recoveryPercentage,
      total: totalListings,
      recovered: successfulRecoveries
    });

    return {
      percentage: recoveryPercentage,
      totalCount: totalListings,
      successCount: successfulRecoveries
    };
  } catch (error) {
    logger.error('Error calculating furniture recovery rate', error);
    throw error;
  }
};

/**
 * Calculates environmental impact metrics
 * Requirement: Environmental Impact Measurement - Track 1,000 tons diverted
 */
export const calculateEnvironmentalImpact = (
  recoveredItems: ListingMetrics[]
): {
  wasteReduction: number;
  carbonSavings: number;
  totalItems: number;
} => {
  try {
    const AVERAGE_ITEM_WEIGHT = 50; // kg
    const CARBON_PER_KG = 2.5; // kg CO2 per kg of furniture

    const totalItems = recoveredItems.length;
    const totalWeight = totalItems * AVERAGE_ITEM_WEIGHT;
    const wasteReduction = totalWeight / 1000; // Convert to tons
    const carbonSavings = (totalWeight * CARBON_PER_KG) / 1000; // Convert to tons CO2

    // Update Prometheus gauge
    environmentalImpactGauge.set(wasteReduction);

    logger.info('Environmental impact calculated', {
      wasteReduction,
      carbonSavings,
      totalItems
    });

    return {
      wasteReduction,
      carbonSavings,
      totalItems
    };
  } catch (error) {
    logger.error('Error calculating environmental impact', error);
    throw error;
  }
};

/**
 * Aggregates metrics data within a specified time range
 * Requirement: Community Growth Monitoring - Track 25% month-over-month growth
 */
export const aggregateMetricsByTimeRange = (
  startDate: Date,
  endDate: Date,
  metricType: string,
  interval: string
): Array<{ timestamp: Date; value: number }> => {
  try {
    const start = dayjs(startDate);
    const end = dayjs(endDate);
    const intervals: Array<{ timestamp: Date; value: number }> = [];

    let current = start;
    while (current.isBefore(end) || current.isSame(end)) {
      const nextInterval = current.add(1, interval as any);
      
      // Add data point for current interval
      intervals.push({
        timestamp: current.toDate(),
        value: Math.random() * 100 // Placeholder - replace with actual metric calculation
      });

      current = nextInterval;
    }

    logger.info('Metrics aggregated by time range', {
      metricType,
      interval,
      startDate,
      endDate,
      pointCount: intervals.length
    });

    return intervals;
  } catch (error) {
    logger.error('Error aggregating metrics by time range', error);
    throw error;
  }
};