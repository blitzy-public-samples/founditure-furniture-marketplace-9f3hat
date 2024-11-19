// External dependencies
import { Document } from 'mongoose'; // v7.5.0
import { BaseEntity } from 'typeorm'; // v0.3.17

/**
 * Human Tasks:
 * 1. Ensure MongoDB and TypeORM are properly configured in the application
 * 2. Configure audit logging middleware/hooks to populate auditLogs
 * 3. Set up proper user context management to track createdBy/updatedBy/deletedBy
 */

/**
 * Base interface that all domain entities must extend to ensure consistent data structure
 * Requirement: 3.2.2 Data Management Strategy - Implements consistent data operations
 * Requirement: 2.2.1 Core Components - Base interfaces for domain entities
 */
export interface BaseModel extends Document, BaseEntity {
  id: string;
  createdAt: Date;
  updatedAt: Date;
  isActive: boolean;
  createdBy: string;
  updatedBy: string;
}

/**
 * Interface for tracking data changes and versioning
 * Requirement: 5.2 DATA SECURITY - Supports data auditing and tracking
 */
export interface AuditLog {
  entityId: string;
  entityType: string;
  action: string; // CREATE, UPDATE, DELETE, etc.
  userId: string;
  timestamp: Date;
  changes: Record<string, any>; // Stores before/after values of changed fields
}

/**
 * Interface for auditable entities with versioning and change tracking
 * Requirement: 5.2 DATA SECURITY - Supports data auditing and tracking
 * Requirement: 3.2.2 Data Management Strategy - Implements consistent data operations
 */
export interface AuditableModel extends BaseModel {
  version: number;
  auditLogs: AuditLog[];
}

/**
 * Interface for entities that support soft deletion
 * Requirement: 3.2.2 Data Management Strategy - Implements consistent data operations
 */
export interface SoftDeletable {
  isDeleted: boolean;
  deletedAt: Date;
  deletedBy: string;
}