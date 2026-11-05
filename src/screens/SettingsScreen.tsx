// Ported from app/src/main/java/com/waraq/app/ui/settings/SettingsActivity.java
import React, { useEffect, useState } from 'react';
import { Alert, ScrollView, StyleSheet, View } from 'react-native';
import { Button, Card, Divider, RadioButton, SegmentedButtons, Text, TextInput } from 'react-native-paper';
import Constants from 'expo-constants';
import { useNavigation, type NavigationProp } from '@react-navigation/native';
import { useQuery } from '@tanstack/react-query';
import { intervals, saveIntervals } from '../data/repos/settings';
import { getLibraryView, setLibraryView, type LibraryView } from '../lib/prefs';
import type { ThemeMode } from '../lib/prefs';
import { t } from '../lib/strings';
import type { RootStackParamList } from '../navigation/types';
import { useAppTheme } from '../theme/ThemeProvider';

export function SettingsScreen() {
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  const { colors, spacing, mode, setMode } = useAppTheme();
  const [values, setValues] = useState<string[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [view, setView] = useState<LibraryView>(getLibraryView());

  const query = useQuery({ queryKey: ['intervals'], queryFn: intervals });
  useEffect(() => {
    if (query.data) setValues(query.data.map(String));
  }, [query.data]);

  const save = async () => {
    const parsed = values.map((v) => Number.parseInt(v, 10));
    if (parsed.some((v) => !Number.isInteger(v) || v < 1 || v > 365)) {
      setError(t.settingsInvalidInterval);
      return;
    }
    setError(null);
    await saveIntervals(parsed);
    Alert.alert(t.settingsIntervalsSaved);
  };

  const themeOptions: { value: ThemeMode; label: string }[] = [
    { value: 'system', label: t.settingsSystem },
    { value: 'light', label: t.settingsLight },
    { value: 'dark', label: t.settingsDark },
  ];

  return (
    <ScrollView style={{ backgroundColor: colors.background }} contentContainerStyle={{ padding: spacing.m, paddingBottom: 140 }}>
      <Text variant="labelLarge" style={{ color: colors.primary, textAlign: 'right', marginBottom: spacing.s }}>
        {t.settingsAppearance}
      </Text>
      <Card style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.outline }]}>
        <Card.Content>
          <Text variant="titleSmall" style={{ color: colors.onSurface, textAlign: 'right' }}>{t.settingsTheme}</Text>
          <SegmentedButtons value={mode} onValueChange={(next) => setMode(next as ThemeMode)} buttons={themeOptions.map(o => ({ value: o.value, label: o.label }))} style={{ flexDirection: 'row-reverse' }} />
          <Divider style={{ backgroundColor: colors.outline }} />
          <Text variant="titleSmall" style={{ color: colors.onSurface, textAlign: 'right', marginTop: spacing.s }}>{t.settingsLibraryView}</Text>
          <View style={{ flexDirection: 'row-reverse', gap: spacing.s, marginTop: spacing.s }}>
            <Button
              mode={view === 'grid' ? 'contained' : 'outlined'}
              onPress={() => {
                setView('grid');
                setLibraryView('grid');
              }}
              style={{ flex: 1 }}
            >
              {t.libraryGrid}
            </Button>
            <Button
              mode={view === 'list' ? 'contained' : 'outlined'}
              onPress={() => {
                setView('list');
                setLibraryView('list');
              }}
              style={{ flex: 1 }}
            >
              {t.libraryList}
            </Button>
          </View>
        </Card.Content>
      </Card>

      <Text variant="labelLarge" style={{ color: colors.primary, textAlign: 'right', marginTop: spacing.l, marginBottom: spacing.s }}>
        {t.settingsReview}
      </Text>
      <Card style={[styles.card, { backgroundColor: colors.surface, borderColor: colors.outline }]}>
        <Card.Content>
          <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', lineHeight: 22 }}>
            {t.settingsIntervalsHelp}
          </Text>
          <View style={{ flexDirection: 'row-reverse', flexWrap: 'wrap', gap: spacing.s, marginTop: spacing.s }}>
            {values.map((value, index) => (
              <TextInput
                key={index}
                mode="outlined"
                label={`${index + 1}`}
                value={value}
                onChangeText={(next) => {
                  setError(null);
                  setValues((current) => current.map((v, i) => (i === index ? next : v)));
                }}
                keyboardType="number-pad"
                style={{ width: 64, backgroundColor: colors.surface }}
              />
            ))}
          </View>
          <Text variant="labelSmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: 4 }}>
            {t.settingsIntervalField}
          </Text>
          {error ? <Text style={{ color: colors.error, textAlign: 'right' }}>{error}</Text> : null}
          <Button mode="contained" onPress={save} style={{ marginTop: spacing.s }}>
            {t.save}
          </Button>
        </Card.Content>
      </Card>

      <Text variant="labelLarge" style={{ color: colors.primary, textAlign: 'right', marginTop: spacing.l, marginBottom: spacing.s }}>
        {t.settingsData}
      </Text>
      <Button mode="outlined" icon="archive-outline" onPress={() => navigation.navigate('Backup')} style={{ marginBottom: spacing.s }}>
        {t.settingsBackup}
      </Button>
      <Button mode="outlined" icon="playlist-remove" onPress={() => navigation.navigate('ClearData')} style={{ marginBottom: spacing.s }}>
        {t.settingsClear}
      </Button>
      <Button mode="outlined" icon="tag-multiple-outline" onPress={() => navigation.navigate('Categories')} style={{ marginBottom: spacing.s }}>
        {t.categories}
      </Button>

      <Text variant="labelLarge" style={{ color: colors.primary, textAlign: 'right', marginTop: spacing.l, marginBottom: spacing.s }}>
        {t.settingsPrivacy}
      </Text>
      <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', lineHeight: 22 }}>
        {t.settingsPrivacyBody}
      </Text>
      <Text variant="bodySmall" style={{ color: colors.error, textAlign: 'right', marginTop: spacing.s, lineHeight: 22 }}>
        {t.settingsPrivacyWarning}
      </Text>

      <Text variant="labelLarge" style={{ color: colors.primary, textAlign: 'right', marginTop: spacing.l, marginBottom: spacing.s }}>
        {t.settingsAbout}
      </Text>
      <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
        {t.settingsAboutBody}
      </Text>
      <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: 4 }}>
        {t.settingsVersion(Constants.expoConfig?.version ?? '2.3.7')}
      </Text>
    </ScrollView>
  );
}

const styles = StyleSheet.create({
  card: { borderWidth: StyleSheet.hairlineWidth },
});
