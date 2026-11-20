import 'dart:async';

import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../l10n/business_localizations.dart';
import '../session/business_role.dart';
import '../session/business_session_controller.dart';

/// Global read-only banner shown when company trial/subscription is expired.
final class SubscriptionReadOnlyBanner extends StatelessWidget {
  const SubscriptionReadOnlyBanner({
    super.key,
    required this.controller,
    this.message,
    this.onOpenDetails,
  });

  final BusinessSessionController controller;
  final String? message;
  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
    final strings = BusinessStringsScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isReadOnly) {
          return const SizedBox.shrink();
        }

        final colors = context.ucraftColors;
        return Semantics(
          liveRegion: true,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(UcraftSpacing.space3),
            decoration: BoxDecoration(
              color: colors.warningBackground,
              borderRadius: UcraftRadius.borderSm,
              border: Border.all(
                color: colors.warning,
                width: UcraftElevation.borderDefault,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  LucideIcons.lock,
                  size: 20,
                  color: colors.warningForeground,
                ),
                const SizedBox(width: UcraftSpacing.iconLabelGap),
                Expanded(
                  child: Text(
                    message ?? strings.readOnlyBanner,
                    style: UcraftTypography.bodyMedium.copyWith(
                      color: colors.warningForeground,
                    ),
                  ),
                ),
                if (onOpenDetails != null) ...[
                  const SizedBox(width: UcraftSpacing.space2),
                  UcraftButton(
                    label: strings.detailsLabel,
                    variant: UcraftButtonVariant.secondary,
                    onPressed: onOpenDetails,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Guards a route or section according to the active user's [BusinessRole].
final class RoleGuard extends StatelessWidget {
  const RoleGuard({
    super.key,
    required this.controller,
    required this.permission,
    required this.child,
    this.onCreateCompany,
    this.onOpenClientApp,
  });

  final BusinessSessionController controller;
  final BusinessPermission permission;
  final Widget child;
  final VoidCallback? onCreateCompany;
  final VoidCallback? onOpenClientApp;

  @override
  Widget build(BuildContext context) {
    final strings = BusinessStringsScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.role == BusinessRole.noCompany) {
          final colors = context.ucraftColors;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(UcraftSpacing.space6),
              child: UcraftCard(
                variant: UcraftCardVariant.highlight,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      strings.noCompanyTitle,
                      style: UcraftTypography.title.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: UcraftSpacing.space2),
                    Text(
                      strings.noCompanyDescription,
                      style: UcraftTypography.body.copyWith(
                        color: colors.foregroundSecondary,
                      ),
                    ),
                    if (onCreateCompany != null) ...[
                      const SizedBox(height: UcraftSpacing.space4),
                      UcraftButton(
                        label: strings.createCompanyCta,
                        fullWidth: true,
                        onPressed: onCreateCompany,
                      ),
                    ],
                    if (onOpenClientApp != null) ...[
                      const SizedBox(height: UcraftSpacing.space3),
                      UcraftButton(
                        label: strings.openClientAppCta,
                        variant: UcraftButtonVariant.secondary,
                        fullWidth: true,
                        onPressed: onOpenClientApp,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }

        if (!controller.canView(permission)) {
          return UcraftEmptyState(
            icon: LucideIcons.lock,
            title: strings.permissionDeniedTitle,
            description: strings.permissionDeniedDescription,
          );
        }

        return child;
      },
    );
  }
}

/// Branch switcher bound to [BusinessSessionController.selectedGym].
final class GymBranchSelector extends StatelessWidget {
  const GymBranchSelector({super.key, required this.controller});

  final BusinessSessionController controller;

  @override
  Widget build(BuildContext context) {
    final strings = BusinessStringsScope.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final colors = context.ucraftColors;
        final gyms = controller.gyms;
        final selected = controller.selectedGym;
        final label = selected?.name ?? strings.branchNotSelected;

        final Widget chip = Container(
          constraints: const BoxConstraints(minHeight: UcraftSpacing.space10),
          padding: const EdgeInsets.symmetric(
            horizontal: UcraftSpacing.space3,
            vertical: UcraftSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceSecondary,
            borderRadius: UcraftRadius.borderSm,
            border: Border.all(
              color: colors.border,
              width: UcraftElevation.borderDefault,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.dumbbell, size: 16, color: colors.accent),
              const SizedBox(width: UcraftSpacing.space2),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UcraftTypography.label.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.foreground,
                  ),
                ),
              ),
              if (gyms.length > 1) ...[
                const SizedBox(width: UcraftSpacing.space1),
                Icon(
                  LucideIcons.chevronDown,
                  size: 16,
                  color: colors.foregroundSecondary,
                ),
              ],
            ],
          ),
        );

        if (gyms.length <= 1) {
          return chip;
        }

        return PopupMenuButton<GymSummary>(
          initialValue: selected,
          onSelected: (gym) => unawaited(controller.selectGym(gym)),
          itemBuilder: (context) => [
            for (final gym in gyms)
              PopupMenuItem<GymSummary>(value: gym, child: Text(gym.name)),
          ],
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: UcraftSpacing.space12),
            child: Center(widthFactor: 1, child: chip),
          ),
        );
      },
    );
  }
}
