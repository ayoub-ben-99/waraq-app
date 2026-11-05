// Ported from app/src/main/java/com/waraq/app/ui/settings/BackupActivity.java
import React, { useState } from 'react';
import { Alert, ScrollView, StyleSheet, View } from 'react-native';
import { Button, Card, Dialog, Portal, Switch, Text } from 'react-native-paper';
import * as DocumentPicker from 'expo-document-picker';
import * as Sharing from 'expo-sharing';
import { applyRestore, BackupError, exportBackup, readBackup, type BackupData } from '../features/backup/backupManager';
import { KEY_LAST_BACKUP, putSetting } from '../data/repos/settings';
import { t } from '../lib/strings';
import { useAppTheme } from '../theme/ThemeProvider';
import { Loading } from '../components/Layout';

export function BackupScreen() {
  const { colors, spacing } = useAppTheme();
  const [includePdfs, setIncludePdfs] = useState(false);
  const [busy, setBusy] = useState(false);
  const [backup, setBackup] = useState<BackupData | null>(null);
  const [confirmReplace, setConfirmReplace] = useState(false);

  const exportNow = async () => {
    if (busy) return;
    setBusy(true);
    try {
      const result = await exportBackup(includePdfs);
      await putSetting(KEY_LAST_BACKUP, String(Date.now()));
      if (await Sharing.isAvailableAsync()) {
        await Sharing.shareAsync(result.uri, {
          mimeType: 'application/zip',
          dialogTitle: t.backupExport,
          UTI: 'com.pkware.zip-archive',
        });
      }
      Alert.alert(t.backupExportOk);
    } catch {
      Alert.alert(t.backupExportFailed);
    } finally {
      setBusy(false);
    }
  };

  const pick = async () => {
    try {
      const picked = await DocumentPicker.getDocumentAsync({
        type: ['application/zip', 'application/octet-stream', '*/*'],
        copyToCacheDirectory: true,
      });
      if (picked.canceled) return;
      setBusy(true);
      const data = await readBackup(picked.assets[0].uri);
      setBackup(data);
    } catch (err) {
      Alert.alert(t.backupRestoreFailed, backupMessage(err));
    } finally {
      setBusy(false);
    }
  };

  const restore = async (replace: boolean) => {
    if (!backup) return;
    setBusy(true);
    try {
      const result = await applyRestore(backup, replace);
      setBackup(null);
      setConfirmReplace(false);
      Alert.alert(t.backupRestoreOk(result.books, result.entries));
    } catch (err) {
      Alert.alert(t.backupRestoreFailed, backupMessage(err));
    } finally {
      setBusy(false);
    }
  };

  if (busy && !backup) return <Loading />;

  return (
    <ScrollView style={{ backgroundColor: colors.bg }} contentContainerStyle={{ padding: spacing.m, paddingBottom: 120 }}>
      <Text variant="titleLarge" style={{ color: colors.textPrimary, textAlign: 'right' }}>{t.backupTitle}</Text>

      <Card style={{ backgroundColor: colors.surface, borderColor: colors.outline, borderWidth: StyleSheet.hairlineWidth, marginTop: spacing.m }}>
        <Card.Content>
          <Text variant="titleMedium" style={{ color: colors.textPrimary, textAlign: 'right' }}>{t.backupExport}</Text>
          <Text variant="bodySmall" style={{ color: colors.textSecondary, textAlign: 'right', marginTop: 4, lineHeight: 22 }}>
            {t.backupExportDesc}
          </Text>
          <View style={{ flexDirection: 'row-reverse', alignItems: 'center', justifyContent: 'space-between', marginTop: spacing.s }}>
            <Text variant="bodyMedium" style={{ color: colors.textPrimary }}>تضمين ملفات PDF</Text>
            <Switch value={includePdfs} onValueChange={setIncludePdfs} color={colors.accent} />
          </View>
          <Text variant="labelSmall" style={{ color: colors.danger, textAlign: 'right', marginTop: spacing.s }}>
            {t.backupNotEncrypted}
          </Text>
          <Button mode="contained" icon="archive-arrow-down" onPress={exportNow} loading={busy} disabled={busy} style={{ marginTop: spacing.s }}>
            {t.backupExport}
          </Button>
        </Card.Content>
      </Card>

      <Card style={{ backgroundColor: colors.surface, borderColor: colors.outline, borderWidth: StyleSheet.hairlineWidth, marginTop: spacing.m }}>
        <Card.Content>
          <Text variant="titleMedium" style={{ color: colors.textPrimary, textAlign: 'right' }}>{t.backupRestore}</Text>
          <Text variant="bodySmall" style={{ color: colors.textSecondary, textAlign: 'right', marginTop: 4, lineHeight: 22 }}>
            {t.backupRestoreDesc}
          </Text>
          <Button mode="outlined" icon="archive-arrow-up" onPress={pick} disabled={busy} style={{ marginTop: spacing.s }}>
            {t.backupRestore}
          </Button>
        </Card.Content>
      </Card>

      <Portal>
        <Dialog visible={backup != null} onDismiss={() => setBackup(null)} style={{ backgroundColor: colors.surface }}>
          <Dialog.Title style={{ textAlign: 'right' }}>{t.backupPreviewTitle}</Dialog.Title>
          <Dialog.Content>
            {backup ? (
              <Text style={{ color: colors.textSecondary, textAlign: 'right', lineHeight: 24 }}>
                {t.backupPreviewBody(
                  backup.createdAt,
                  backup.schema,
                  backup.books.length,
                  backup.sessions.length,
                  backup.entries.length,
                  backup.tags.length,
                  backup.reviews.length,
                  backup.covers.length,
                )}
              </Text>
            ) : null}
            {backup && backup.pdfDocs.length > backup.pdfFiles.length ? (
              <Text style={{ color: colors.gold, textAlign: 'right', marginTop: spacing.s }}>
                {t.backupUnlinkedPdfs(backup.pdfDocs.length - backup.pdfFiles.length)}
              </Text>
            ) : null}
          </Dialog.Content>
          <Dialog.Actions style={{ flexDirection: 'column', alignItems: 'stretch', gap: 4 }}>
            <Button mode="contained" onPress={() => restore(false)} disabled={busy}>{t.backupMerge}</Button>
            <Button mode="outlined" textColor={colors.danger} onPress={() => setConfirmReplace(true)} disabled={busy}>{t.backupReplace}</Button>
            <Button onPress={() => setBackup(null)}>{t.cancel}</Button>
          </Dialog.Actions>
        </Dialog>

        <Dialog visible={confirmReplace} onDismiss={() => setConfirmReplace(false)} style={{ backgroundColor: colors.surface }}>
          <Dialog.Title style={{ textAlign: 'right' }}>{t.backupModeTitle}</Dialog.Title>
          <Dialog.Content>
            <Text style={{ color: colors.danger, textAlign: 'right', lineHeight: 24 }}>{t.backupReplaceWarning}</Text>
          </Dialog.Content>
          <Dialog.Actions>
            <Button onPress={() => setConfirmReplace(false)}>{t.cancel}</Button>
            <Button mode="contained" buttonColor={colors.danger} textColor={colors.onDanger} onPress={() => restore(true)} disabled={busy}>
              {t.clearDo}
            </Button>
          </Dialog.Actions>
        </Dialog>
      </Portal>
    </ScrollView>
  );
}

function backupMessage(err: unknown): string {
  if (err instanceof BackupError) {
    if (err.code === 'corrupt') return t.backupCorrupt;
    if (err.code === 'invalid') return t.backupInvalid;
    if (err.code === 'too-large') return t.backupTooLarge;
    if (err.code.startsWith('newer:')) return t.backupNewer(Number(err.code.slice(6)));
  }
  return t.backupInvalid;
}
