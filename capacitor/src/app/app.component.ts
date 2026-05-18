import { Component, computed, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { AgeSignal } from './age-signal.plugin';
import {
  AgeScenario,
  AgeSignalMode,
  DerivedAgeOutput,
  sandboxScenarios,
} from './age-signal.model';

@Component({
  selector: 'app-root',
  imports: [FormsModule],
  templateUrl: './app.component.html',
  styleUrl: './app.component.css',
})
export class AppComponent {
  protected readonly modes: AgeSignalMode[] = ['sandbox', 'native'];
  protected readonly scenarios = sandboxScenarios;

  protected readonly mode = signal<AgeSignalMode>('sandbox');
  protected readonly selectedScenarioId = signal('16to17');
  protected readonly nativeStatus = signal('Not requested yet.');
  protected readonly nativeBusy = signal(false);
  protected readonly lastNativePayload = signal('');
  protected readonly focus = signal(70);
  protected readonly exposure = signal(42);
  protected readonly note = signal('Capacitor shell mirrors the native age signal flow.');

  protected readonly currentScenario = computed(() => {
    return (
      this.scenarios.find((scenario) => scenario.id === this.selectedScenarioId()) ??
      this.scenarios[0]
    );
  });

  protected readonly activeSignal = computed<AgeScenario>(() => {
    if (this.mode() === 'sandbox') {
      return this.currentScenario();
    }

    return this.nativePayloadToScenario();
  });

  protected readonly derivedOutput = computed<DerivedAgeOutput>(() => {
    const signal = this.activeSignal();

    if (signal.status === 'declined') {
      return {
        tier: 'Unknown',
        experience: 'Use the privacy-preserving fallback experience.',
        declaredAgeRequired: true,
        parentalConsentRequired: false,
        adultNotificationRequired: false,
        communicationLimited: true,
      };
    }

    if (signal.status === 'notAvailable') {
      return {
        tier: 'No age obligation',
        experience: 'Run the general app experience.',
        declaredAgeRequired: false,
        parentalConsentRequired: false,
        adultNotificationRequired: false,
        communicationLimited: false,
      };
    }

    if ((signal.upperBound ?? 99) < 13) {
      return {
        tier: 'Child',
        experience: 'Disable open sharing and keep guided controls visible.',
        declaredAgeRequired: true,
        parentalConsentRequired: true,
        adultNotificationRequired: false,
        communicationLimited: true,
      };
    }

    if ((signal.upperBound ?? 99) < 18) {
      return {
        tier: 'Teen',
        experience: 'Enable limited collaboration with guardian-aware changes.',
        declaredAgeRequired: true,
        parentalConsentRequired: false,
        adultNotificationRequired: true,
        communicationLimited: true,
      };
    }

    return {
      tier: 'Adult',
      experience: 'Enable full prototype controls.',
      declaredAgeRequired: true,
      parentalConsentRequired: false,
      adultNotificationRequired: false,
      communicationLimited: false,
    };
  });

  protected readonly readiness = computed(() => {
    const signal = this.activeSignal();
    const ageWeight = signal.status === 'shared' ? 20 : signal.status === 'declined' ? 8 : 14;
    return Math.min(100, Math.round((this.focus() + this.exposure()) / 2 + ageWeight));
  });

  protected setMode(mode: AgeSignalMode): void {
    this.mode.set(mode);
  }

  protected setScenario(id: string): void {
    this.selectedScenarioId.set(id);
  }

  protected async requestNativeSignal(): Promise<void> {
    this.mode.set('native');
    this.nativeBusy.set(true);
    this.nativeStatus.set('Opening native declared age request...');

    try {
      const result = await AgeSignal.requestDeclaredAge({ ageGates: [13, 16, 18] });
      this.lastNativePayload.set(JSON.stringify(result, null, 2));

      if (!result.available) {
        this.nativeStatus.set(result.message ?? 'Declared Age Range is unavailable here.');
        return;
      }

      if (result.status === 'shared') {
        this.nativeStatus.set(`${this.sourceLabel(result.source)} returned a declared age range.`);
      } else if (result.status === 'declined') {
        this.nativeStatus.set('The person declined to share their age range.');
      } else {
        this.nativeStatus.set(result.message ?? 'No age range is required for this context.');
      }
    } catch (error) {
      this.nativeStatus.set('Native plugin call failed.');
      this.lastNativePayload.set(JSON.stringify(error, null, 2));
    } finally {
      this.nativeBusy.set(false);
    }
  }

  protected async checkNativeAvailability(): Promise<void> {
    this.mode.set('native');
    this.nativeBusy.set(true);

    try {
      const result = await AgeSignal.checkAvailability();
      this.lastNativePayload.set(JSON.stringify(result, null, 2));
      this.nativeStatus.set(result.message ?? (result.available ? 'Native API is available.' : 'Native API is unavailable.'));
    } catch (error) {
      this.nativeStatus.set('Native availability check failed.');
      this.lastNativePayload.set(JSON.stringify(error, null, 2));
    } finally {
      this.nativeBusy.set(false);
    }
  }

  private nativePayloadToScenario(): AgeScenario {
    if (!this.lastNativePayload()) {
      return {
        id: 'native-pending',
        label: 'Native pending',
        status: 'notAvailable',
      };
    }

    try {
      const parsed = JSON.parse(this.lastNativePayload());
      return {
        id: 'native',
        label: `${this.sourceLabel(parsed.source)} signal`,
        lowerBound: parsed.lowerBound,
        upperBound: parsed.upperBound,
        status: parsed.status === 'shared' ? 'shared' : parsed.status === 'declined' ? 'declined' : 'notAvailable',
      };
    } catch {
      return {
        id: 'native-error',
        label: 'Native error',
        status: 'notAvailable',
      };
    }
  }

  private sourceLabel(source: string | undefined): string {
    return source === 'google' ? 'Google Play' : source === 'apple' ? 'Apple' : 'Native';
  }
}
