import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:ugym_core/ugym_core.dart';

import '../session/business_role.dart';
import '../session/business_session_controller.dart';

/// Global read-only banner shown when company trial/subscription is expired.
final class SubscriptionReadOnlyBanner extends StatelessWidget {
  const SubscriptionReadOnlyBanner({
    super.key,
    required this.controller,
    this.onOpenDetails,
  });

  final BusinessSessionController controller;
  final VoidCallback? onOpenDetails;

  @override
  Widget build(BuildContext context) {
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
                  Icons.lock_outline,
                  size: 20,
                  color: colors.warningForeground,
                ),
                const SizedBox(width: UcraftSpacing.iconLabelGap),
                Expanded(
                  child: Text(
                    'Подписка истекла — доступен только просмотр',
                    style: UcraftTypography.bodyMedium.copyWith(
                      color: colors.warningForeground,
                    ),
                  ),
                ),
                if (onOpenDetails != null) ...[
                  const SizedBox(width: UcraftSpacing.space2),
                  UcraftButton(
                    label: 'Подробнее',
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
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (controller.role == BusinessRole.noCompany) {
          final colors = context.ucraftColors;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(UcraftSpacing.space6),
              child: UcraftCard(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Вы не являетесь сотрудником зала',
                      style: UcraftTypography.title.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(height: UcraftSpacing.space2),
                    Text(
                      'Создайте свою компанию или откройте клиентское приложение uGym.',
                      style: UcraftTypography.body.copyWith(
                        color: colors.foregroundSecondary,
                      ),
                    ),
                    if (onCreateCompany != null) ...[
                      const SizedBox(height: UcraftSpacing.space4),
                      UcraftButton(
                        label: 'Создать компанию (14 дней бесплатно)',
                        fullWidth: true,
                        onPressed: onCreateCompany,
                      ),
                    ],
                    if (onOpenClientApp != null) ...[
                      const SizedBox(height: UcraftSpacing.space3),
                      UcraftButton(
                        label: 'Перейти в клиентское приложение uGym',
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
          return const UcraftEmptyState(
            icon: Icons.lock_outline,
            title: 'Недостаточно прав для доступа к разделу',
            description: 'Доступ ограничен вашей текущей ролью в компании.',
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
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final colors = context.ucraftColors;
        final gyms = controller.gyms;
        final selected = controller.selectedGym;
        final label = selected?.name ?? 'Филиал не выбран';

        final Widget chip = Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(
            horizontal: UcraftSpacing.space3,
            vertical: UcraftSpacing.space2,
          ),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: UcraftRadius.borderSm,
            border: Border.all(
              color: colors.border,
              width: UcraftElevation.borderDefault,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: UcraftSpacing.iconLabelGap),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UcraftTypography.bodyMedium.copyWith(
                    color: colors.foreground,
                  ),
                ),
              ),
              if (gyms.length > 1) ...[
                const SizedBox(width: UcraftSpacing.space1),
                Icon(
                  Icons.keyboard_arrow_down,
                  size: 20,
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
          child: chip,
        );
      },
    );
  }
}
