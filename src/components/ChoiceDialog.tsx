// Ported from app/src/main/java/com/waraq/app/ui/Ui.java
import React from 'react';
import { ScrollView, TouchableOpacity, View } from 'react-native';
import { Dialog, Portal, Text, TextInput } from 'react-native-paper';
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
  const { colors, spacing } = useAppTheme();
  return (
    <Portal>
      <Dialog visible={visible} onDismiss={onDismiss} style={{ backgroundColor: colors.surface }}>
        <Dialog.Title style={{ textAlign: 'right', color: colors.onSurface }}>{title}</Dialog.Title>
        <Dialog.Content style={{ maxHeight: 420, paddingHorizontal: 0 }}>
          <ScrollView>
            {options.map((option) => (
              <TouchableOpacity
                key={String(option.value)}
                onPress={() => {
                  onSelect(option.value);
                  onDismiss();
                }}
                style={{
                  paddingVertical: spacing.m,
                  paddingHorizontal: spacing.l,
                  backgroundColor: option.value === value ? colors.primaryContainer : 'transparent',
                }}
              >
                <Text
                  variant="bodyLarge"
                  style={{ color: option.value === value ? colors.onPrimaryContainer : colors.onSurface, textAlign: 'right' }}
                >
                  {option.label}
                </Text>
              </TouchableOpacity>
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
  const { colors } = useAppTheme();
  return (
    <Portal>
      <Dialog visible={visible} onDismiss={onDismiss} style={{ backgroundColor: colors.surface }}>
        <Dialog.Title style={{ textAlign: 'right', color: colors.onSurface }}>{title}</Dialog.Title>
        <Dialog.Content>
          <Text variant="bodyMedium" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
            {message}
          </Text>
        </Dialog.Content>
        <Dialog.Actions>
          <Text onPress={onDismiss} style={{ color: colors.onSurfaceVariant }}>
            إلغاء
          </Text>
          <Text
            onPress={() => {
              onConfirm();
              onDismiss();
            }}
            style={{ color: destructive ? colors.error : colors.primary, marginStart: 20 }}
          >
            {confirmLabel}
          </Text>
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
  const { colors } = useAppTheme();
  return (
    <Portal>
      <Dialog visible={visible} onDismiss={onDismiss} style={{ backgroundColor: colors.surface }}>
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
          <Text onPress={onDismiss} style={{ color: colors.onSurfaceVariant }}>
            إلغاء
          </Text>
          <Text onPress={onSave} style={{ color: colors.primary, marginStart: 20 }}>
            حفظ
          </Text>
        </Dialog.Actions>
      </Dialog>
    </Portal>
  );
}

export function DialogContent({ children }: { children: React.ReactNode }) {
  return <View style={{ gap: 8 }}>{children}</View>;
}
