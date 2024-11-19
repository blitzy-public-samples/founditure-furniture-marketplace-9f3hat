<!-- 
This pull request template enforces standardized code review processes for the Founditure application.
It addresses the following requirements:
- Code Quality (Technical Specification/2.4 Cross-Cutting Concerns/2.4.1 System Monitoring):
  Ensures code changes maintain high quality standards and proper monitoring implementation
- System Reliability (Technical Specification/1.2 System Overview/Success Criteria):
  Contributes to maintaining 70% monthly active user retention by ensuring stable and well-tested code changes
- Security Compliance (Technical Specification/5.1 Authentication and Authorization):
  Enforces security review requirements for code changes affecting authentication, authorization, and data protection
-->

# Pull Request: [Feature/Fix/Refactor] Brief Title

## Description
- Type: [Feature/Bugfix/Refactor/Performance/Security]
- Related Issue: #issue_number
- Impact Area: [Mobile Apps/Backend Services/Infrastructure/AI Services]

Detailed description of the changes and their purpose

<!-- For bug fixes, reference the bug report (#issue_number) and include relevant details from the bug description and environment sections -->
<!-- For features, reference the feature request (#issue_number) and align with the documented requirements and impact areas -->

## Changes Made
- [ ] Mobile App Changes
  - iOS:
  - Android:
- [ ] Backend Service Changes
  - Services Modified:
  - API Changes:
- [ ] AI/ML Component Changes
  - Models Modified:
  - Training Updates:
- [ ] Infrastructure Changes
  - Components Modified:
  - Configuration Updates:

## Testing
- [ ] Unit Tests Added/Updated
- [ ] Integration Tests Added/Updated
- [ ] UI Tests Added/Updated
- [ ] AI/ML Model Tests Added/Updated
- [ ] Manual Testing Performed

Test Coverage Report:
Performance Impact Analysis:

<!-- Include specific test scenarios that verify the changes meet reliability requirements -->
<!-- Document performance impact on system monitoring metrics -->

## Security Considerations
- [ ] Authentication/Authorization Impact
- [ ] Data Protection Impact
- [ ] Security Tests Added/Updated
- [ ] Vulnerability Scan Performed
- [ ] AI/ML Model Security Reviewed

<!-- Document any changes affecting:
- User authentication flows
- Authorization rules
- Data encryption
- Privacy controls
- AI/ML model security -->

## Deployment Requirements
- [ ] Database Migrations
- [ ] Environment Variables
- [ ] Infrastructure Updates
- [ ] Third-party Service Changes
- [ ] AI/ML Model Deployment Changes

<!-- Specify all configuration changes needed for deployment -->
<!-- Include rollback procedures if applicable -->

## Pre-merge Checklist
- [ ] Code follows project style guidelines
- [ ] Documentation updated
- [ ] All tests passing
- [ ] No new security vulnerabilities introduced
- [ ] Performance requirements met
- [ ] Accessibility requirements met
- [ ] AI/ML model metrics validated
- [ ] Product owner approval obtained
- [ ] Tech lead review completed

<!-- 
Reviewers:
- @tech-lead
- @security-team
- @ai-team

Labels:
- needs-review
- waiting-for-ci

Version: 1.1.0
Last Updated: 2024-01-01
-->