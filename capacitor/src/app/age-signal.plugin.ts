import { registerPlugin } from '@capacitor/core';

export interface AgeSignalResult {
  available: boolean;
  source: 'apple' | 'google' | 'sandbox';
  status: 'shared' | 'declined' | 'notAvailable' | 'error';
  lowerBound?: number;
  upperBound?: number;
  ageRangeDeclaration?: string;
  activeParentalControls?: string[];
  userStatus?: string;
  installId?: string;
  mostRecentApprovalDate?: string;
  isEligibleForAgeFeatures?: boolean;
  requiredRegulatoryFeatures?: string[];
  message?: string;
}

export interface AgeSignalPlugin {
  requestDeclaredAge(options: { ageGates: number[] }): Promise<AgeSignalResult>;
  checkAvailability(): Promise<AgeSignalResult>;
}

export const AgeSignal = registerPlugin<AgeSignalPlugin>('AgeSignal');
