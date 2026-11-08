import React from 'react';
import { Pressable, ScrollView, View } from 'react-native';
import { Button, Dialog, Portal, Text, TextInput } from 'react-native-paper';
import { useAppTheme } from '../theme/ThemeProvider';

export function ChoiceDialog<T extends string | number | null>({
  visible,
  title,
  options,
  value,
  onSelect,
  onDismiss,
}: {
  visible: boolean;
  title: string;
  options: { value: T; label: string }[];
  value: T;
  onSelect: (value: T) => void;
  onDismiss: () => void;
}) {
  const { colors, spacing, radius } = useAppTheme();
  return (
    <Portal>
      <Dialog visible={visible} onDismiss={onDismiss} style={{ borderRadius: radius.card, backgroundColor: colors.surface }}>
        <Dialog.Title style={{ textAlign: 'right', color: colors.onSurface }}>{title}</Dialog.Title>
        <Dialog.Content style={{ maxHeight: 420, paddingHorizontal: 0 }}>
          <ScrollView>
            {options.map((option) => (
              <Pressable
                key={String(option.value)}
                onPress={() => {
                  onSelect(option.value);
                  onDismiss();
                }}
                style={({ pressed }) => ({
                  marginInline :"10px",
                  borderRadius:radius.full,
                  minHeight: 48,
                  justifyContent: 'center',
                  paddingVertical: spacing.m,
                  paddingHorizontal: spacing.l,
                  backgroundColor: option.value === value
                    ? colors.secondaryContainer
                    : pressed
                      ? colors.surfaceContainerHigh
                      : 'transparent',
                })}
              >
                <Text
                  variant="bodyLarge"
                  style={{ color: option.value === value ? colors.onPrimaryContainer : colors.onSurface, textAlign: 'right' }}
                >
                  {option.label}
                </Text>
              </Pressable>
            ))}
          </ScrollView>
        </Dialog.Content>
      </Dialog>
    </Portal>
  );
}

export function ConfirmDialog({
  visible,
  title,
  message,
  confirmLabel,
  onConfirm,
  onDismiss,
  destructive,
}: {
  visible: boolean;
  title: string;
  message: string;
  confirmLabel: string;
  onConfirm: () => void;
  onDismiss: () => void;
  destructive?: boolean;
}) {
  const { colors, radius } = useAppTheme();
  return (
    <Portal>
      <Dialog visible={visible} onDismiss={onDismiss} style={{ borderRadius: radius.card, backgroundColor: colors.surface }}>
        <Dialog.Title style={{ textAlign: 'right', color: colors.onSurface }}>{title}</Dialog.Title>
        <Dialog.Content>
          <Text variant="bodyMedium" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
            {message}
          </Text>
        </Dialog.Content>
        <Dialog.Actions>
          <Button mode="text" textColor={colors.onSurfaceVariant} onPress={onDismiss}>
            إلغاء
          </Button>
          <Button
            mode="text"
            textColor={destructive ? colors.error : colors.primary}
            onPress={() => {
              onConfirm();
              onDismiss();
            }}
          >
            {confirmLabel}
          </Button>
        </Dialog.Actions>
      </Dialog>
    </Portal>
  );
}

export function FormDialog({
  visible,
  title,
  value,
  onChange,
  onSave,
  onDismiss,
  label,
}: {
  visible: boolean;
  title: string;
  value: string;
  onChange: (value: string) => void;
  onSave: () => void;
  onDismiss: () => void;
  label?: string;
}) {
  const { colors, radius } = useAppTheme();
  return (
    <Portal>
      <Dialog visible={visible} onDismiss={onDismiss} style={{ borderRadius: radius.card, backgroundColor: colors.surface }}>
        <Dialog.Title style={{ textAlign: 'right', color: colors.onSurface }}>{title}</Dialog.Title>
        <Dialog.Content>
          <TextInput
            mode="outlined"
            label={label}
            value={value}
            onChangeText={onChange}
            autoFocus
            style={{ backgroundColor: colors.surface, textAlign: 'right' }}
          />
        </Dialog.Content>
        <Dialog.Actions>
          <Button mode="text" textColor={colors.onSurfaceVariant} onPress={onDismiss}>
            إلغاء
          </Button>
          <Button mode="text" textColor={colors.primary} onPress={onSave}>
            حفظ
          </Button>
        </Dialog.Actions>
      </Dialog>
    </Portal>
  );
}

export function DialogContent({ children }: { children: React.ReactNode }) {
  return <View style={{ gap: 8 }}>{children}</View>;
}
