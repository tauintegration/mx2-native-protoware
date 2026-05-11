export type AgeSignalMode = 'sandbox' | 'apple';

export interface AgeScenario {
  id: string;
  label: string;
  lowerBound?: number;
  upperBound?: number;
  status: 'shared' | 'declined' | 'notAvailable';
}

export interface DerivedAgeOutput {
  tier: string;
  experience: string;
  declaredAgeRequired: boolean;
  parentalConsentRequired: boolean;
  adultNotificationRequired: boolean;
  communicationLimited: boolean;
}

export const sandboxScenarios: AgeScenario[] = [
  {
    id: 'under13',
    label: 'Under 13',
    upperBound: 12,
    status: 'shared',
  },
  {
    id: '13to15',
    label: '13-15',
    lowerBound: 13,
    upperBound: 15,
    status: 'shared',
  },
  {
    id: '16to17',
    label: '16-17',
    lowerBound: 16,
    upperBound: 17,
    status: 'shared',
  },
  {
    id: '18plus',
    label: '18+',
    lowerBound: 18,
    status: 'shared',
  },
  {
    id: 'declined',
    label: 'Declined',
    status: 'declined',
  },
  {
    id: 'notAvailable',
    label: 'Not required',
    status: 'notAvailable',
  },
];
