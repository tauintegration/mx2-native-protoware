import { registerPlugin } from '@capacitor/core';

export interface AgeSignalResult {
  available: boolean;
  source: 'apple' | 'sandbox';
  status: 'shared' | 'declined' | 'notAvailable' | 'error';
  lowerBound?: number;
  upperBound?: number;
  isEligibleForAgeFeatures?: boolean;
  requiredRegulatoryFeatures?: string[];
  message?: string;
}

export interface AgeSignalPlugin {
  requestDeclaredAge(options: { ageGates: number[] }): Promise<AgeSignalResult>;
  checkAvailability(): Promise<AgeSignalResult>;
}

export const AgeSignal = registerPlugin<AgeSignalPlugin>('AgeSignal');
