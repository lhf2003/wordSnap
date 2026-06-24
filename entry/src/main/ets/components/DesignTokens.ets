import { uiMaterial } from '@kit.ArkUI';

export class DesignTokens {
  // Primary: soft indigo with light-sense glow
  static readonly primary: string = '#6C7AFC';
  static readonly primaryLight: string = '#A5B4FF';
  static readonly primaryDark: string = '#4F5FDB';
  static readonly success: string = '#34D399';
  static readonly warning: string = '#FBBF24';
  static readonly danger: string = '#FB7185';

  // Semantic surfaces (tinted backgrounds for badges, chips, cards)
  static readonly successSurface: string = 'rgba(52, 211, 153, 0.12)';
  static readonly successSurfaceSoft: string = 'rgba(52, 211, 153, 0.08)';
  static readonly warningSurface: string = 'rgba(251, 191, 36, 0.12)';
  static readonly primarySurface: string = 'rgba(108, 122, 252, 0.12)';
  static readonly primarySurfaceSoft: string = 'rgba(108, 122, 252, 0.10)';
  static readonly primarySurfaceSubtle: string = 'rgba(108, 122, 252, 0.08)';
  static readonly neutralSurface: string = 'rgba(100, 116, 139, 0.10)';
  static readonly neutralSurfaceMedium: string = 'rgba(100, 116, 139, 0.15)';

  // Text/icons on colored backgrounds
  static readonly textOnPrimary: string = '#FFFFFF';

  // Backgrounds: mist-blue grey for immersive atmosphere
  static readonly bgBase: string = '#F0F4F8';
  static readonly bgBaseDark: string = '#0F172A';
  static readonly bgCard: string = '#FFFFFF';
  static readonly bgInput: string = '#F1F5F9';

  // Text
  static readonly textPrimary: string = '#1E293B';
  static readonly textSecondary: string = '#64748B';
  static readonly textTertiary: string = '#94A3B8';

  // Borders & shadows
  static readonly border: string = '#E2E8F0';
  static readonly shadow: string = 'rgba(108, 122, 252, 0.10)';
  static readonly shadowSoft: string = 'rgba(15, 23, 42, 0.06)';

  // Immersive light-sense colors (used with materialColor, must be translucent)
  static readonly materialPrimaryTint: string = 'rgba(165, 180, 255, 0.18)';
  static readonly materialSurfaceTint: string = 'rgba(255, 255, 255, 0.35)';
  static readonly materialGlow: string = 'rgba(165, 180, 255, 0.30)';

  // Spacing (4dp/8dp rhythm)
  static readonly spacing4: number = 4;
  static readonly spacing8: number = 8;
  static readonly spacing12: number = 12;
  static readonly spacing16: number = 16;
  static readonly spacing20: number = 20;
  static readonly spacing24: number = 24;
  static readonly spacing32: number = 32;
  static readonly spacing48: number = 48;

  // Radius
  static readonly radius8: number = 8;
  static readonly radius12: number = 12;
  static readonly radius16: number = 16;
  static readonly radius20: number = 20;
  static readonly radius24: number = 24;
  static readonly radiusFull: number = 9999;

  // Typography scale
  static readonly font10: number = 10;
  static readonly font12: number = 12;
  static readonly font14: number = 14;
  static readonly font16: number = 16;
  static readonly font18: number = 18;
  static readonly font20: number = 20;
  static readonly font24: number = 24;
  static readonly font28: number = 28;
  static readonly font32: number = 32;

  // Immersive material presets (API 26+)
  static readonly materialThin: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THIN,
    applyShadow: true,
    interactive: true,
    lightEffect: { color: undefined }
  });

  static readonly materialRegular: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.REGULAR,
    applyShadow: true,
    interactive: true,
    lightEffect: { color: undefined }
  });

  static readonly materialUltraThin: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.ULTRA_THIN,
    applyShadow: true,
    interactive: true,
    lightEffect: { color: undefined }
  });

  static readonly materialThick: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THICK,
    applyShadow: true,
    interactive: true
  });

  static readonly materialGlowPreset: uiMaterial.Material = new uiMaterial.ImmersiveMaterial({
    style: uiMaterial.ImmersiveStyle.THIN,
    applyShadow: true,
    interactive: true,
    lightEffect: { color: DesignTokens.materialGlow }
  });
}
