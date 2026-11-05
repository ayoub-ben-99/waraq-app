// Ported from app/src/main/java/com/waraq/app/ui/settings/ClearDataActivity.java
import React, { useState } from 'react';
import { Alert, ScrollView, StyleSheet } from 'react-native';
import { Button, Card, Checkbox, Dialog, Portal, Text } from 'react-native-paper';
import { WIPE_HIGHLIGHTS, WIPE_OCR, WIPE_PROGRESS, wipeData } from '../data/repos/dataWiper';
import { t } from '../lib/strings';
import { useAppTheme } from '../theme/ThemeProvider';

export function ClearDataScreen() {
  const { colors, spacing } = useAppTheme();
  const [flags, setFlags] = useState<number[]>([]);
  const [confirm, setConfirm] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const toggle = (flag: number) => {
    setError(null);
    setFlags((current) => (current.includes(flag) ? current.filter((x) => x !== flag) : [...current, flag]));
  };
  const selected = flags.reduce((a, b) => a | b, 0);
  const labels: Record<number, string> = {
    [WIPE_PROGRESS]: t.clearProgress,
    [WIPE_HIGHLIGHTS]: t.clearMarks,
    [WIPE_OCR]: t.clearOcr,
  };

  const run = async () => {
    if (!selected) {
      setError(t.clearNothing);
      return;
    }
    setConfirm(false);
    try {
      await wipeData(selected);
      setFlags([]);
      Alert.alert(t.clearDone);
    } catch {
      Alert.alert(t.clearFailed);
    }
  };

  const rows = [
    { flag: WIPE_PROGRESS, title: t.clearProgress, body: t.clearProgressDesc },
    { flag: WIPE_HIGHLIGHTS, title: t.clearMarks, body: t.clearMarksDesc },
    { flag: WIPE_OCR, title: t.clearOcr, body: t.clearOcrDesc },
  ];

  return (
    <ScrollView style={{ backgroundColor: colors.bg }} contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }}>
      <Text variant="bodyMedium" style={{ color: colors.textSecondary, textAlign: 'right', lineHeight: 24 }}>
        {t.clearIntro}
      </Text>
      {rows.map((row) => (
        <Card key={row.flag} style={{ backgroundColor: colors.surface, borderColor: colors.outline, borderWidth: StyleSheet.hairlineWidth, marginTop: spacing.m }}>
          <Card.Content>
            <Checkbox.Item
              label={row.title}
              status={flags.includes(row.flag) ? 'checked' : 'unchecked'}
              onPress={() => toggle(row.flag)}
              labelStyle={{ color: colors.textPrimary, textAlign: 'right', flex: 1 }}
              style={{ flexDirection: 'row-reverse', paddingHorizontal: 0 }}
            />
            <Text variant="bodySmall" style={{ color: colors.textSecondary, textAlign: 'right', lineHeight: 22 }}>
              {row.body}
            </Text>
          </Card.Content>
        </Card>
      ))}
      {error ? <Text style={{ color: colors.danger, textAlign: 'right', marginTop: spacing.s }}>{error}</Text> : null}
      <Button mode="contained" buttonColor={colors.danger} textColor={colors.onDanger} onPress={() => (selected ? setConfirm(true) : setError(t.clearNothing))} style={{ marginTop: spacing.m }}>
        {t.clearDo}
      </Button>

      <Portal>
        <Dialog visible={confirm} onDismiss={() => setConfirm(false)} style={{ backgroundColor: colors.surface }}>
          <Dialog.Title style={{ textAlign: 'right' }}>{t.clearConfirmTitle}</Dialog.Title>
          <Dialog.Content>
            <Text style={{ color: colors.textPrimary, textAlign: 'right' }}>{t.clearConfirmBody}</Text>
            {flags.map((flag) => (
              <Text key={flag} style={{ color: colors.textSecondary, textAlign: 'right' }}>• {labels[flag]}</Text>
            ))}
            <Text style={{ color: colors.danger, textAlign: 'right', marginTop: spacing.s }}>{t.clearNoUndo}</Text>
          </Dialog.Content>
          <Dialog.Actions>
            <Button onPress={() => setConfirm(false)}>{t.cancel}</Button>
            <Button mode="contained" buttonColor={colors.danger} textColor={colors.onDanger} onPress={run}>
              {t.clearDo}
            </Button>
          </Dialog.Actions>
        </Dialog>
      </Portal>
    </ScrollView>
  );
}
