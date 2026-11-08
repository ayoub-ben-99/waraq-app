import React, { useEffect, useState } from 'react';
import { Alert, Linking, Pressable, ScrollView, View } from 'react-native';
import { Button, Card, Divider, Text, TextInput } from 'react-native-paper';
import MaterialCommunityIcons from '@expo/vector-icons/MaterialCommunityIcons';
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
  const { colors, spacing, radius, mode, setMode } = useAppTheme();
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

  const openExternalLink = async (url: string) => {
    try {
      await Linking.openURL(url);
    } catch {
      Alert.alert(t.settingsLinkError);
    }
  };

  const themeOptions: { value: ThemeMode; label: string }[] = [
    { value: 'system', label: t.settingsSystem },
    { value: 'light', label: t.settingsLight },
    { value: 'dark', label: t.settingsDark },
  ];
  const themeIcons: Record<ThemeMode, React.ComponentProps<typeof MaterialCommunityIcons>['name']> = {
    system: 'theme-light-dark',
    light: 'weather-sunny',
    dark: 'weather-night',
  };

  return (
    <ScrollView className="flex-1" style={{ backgroundColor: colors.background }} contentContainerStyle={{ padding: spacing.m, paddingBottom: 140 }}>
      <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.s, marginBottom: spacing.s }}>
        <MaterialCommunityIcons name="palette-outline" size={20} color={colors.primary} />
        <Text variant="labelLarge" style={{ color: colors.primary, textAlign: 'right' }}>{t.settingsAppearance}</Text>
      </View>
      <Card style={{ backgroundColor: colors.surfaceContainerLow }}>
        <Card.Content>
          <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.s }}>
            <MaterialCommunityIcons name="palette-outline" size={24} color={colors.primary} />
            <View style={{ flex: 1 }}>
              <Text variant="titleSmall" style={{ color: colors.onSurface, textAlign: 'right' }}>
                {t.settingsTheme}
              </Text>
              <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: 2 }}>
                {t.settingsThemeHelp}
              </Text>
            </View>
          </View>
          <View
            accessibilityRole="radiogroup"
            style={{
              flexDirection: 'row-reverse',
              gap: spacing.xs,
              marginTop: spacing.m,
              borderRadius: radius.card,
              padding: spacing.xs,
              backgroundColor: colors.surfaceContainerHigh,
            }}
          >
            {themeOptions.map((option) => {
              const selected = mode === option.value;
              return (
                <Pressable
                  key={option.value}
                  accessibilityRole="radio"
                  accessibilityState={{ selected }}
                  onPress={() => setMode(option.value)}
                  style={({ pressed }) => ({
                    flex: 1,
                    minHeight: 40,
                    flexDirection: 'row-reverse',
                    alignItems: 'center',
                    justifyContent: 'center',
                    gap: spacing.xs,
                    borderRadius: radius.control,
                    paddingHorizontal: spacing.s,
                    backgroundColor: selected
                      ? colors.secondaryContainer
                      : pressed
                        ? colors.surfaceContainer
                        : 'transparent',
                  })}
                >
                  <MaterialCommunityIcons name={themeIcons[option.value]} size={18} color={selected ? colors.onSecondaryContainer : colors.onSurfaceVariant} />
                  {selected ? <MaterialCommunityIcons name="check" size={18} color={colors.onSecondaryContainer} /> : null}
                  <Text
                    variant="labelLarge"
                    style={{ color: selected ? colors.onSecondaryContainer : colors.onSurfaceVariant }}
                  >
                    {option.label}
                  </Text>
                </Pressable>
              );
            })}
          </View>
          <Divider style={{ backgroundColor: colors.outlineVariant, marginVertical: spacing.m }} />
          <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.xs, marginTop: spacing.s }}>
            <MaterialCommunityIcons name="view-dashboard-outline" size={20} color={colors.onSurface} />
            <Text variant="titleSmall" style={{ color: colors.onSurface, textAlign: 'right' }}>{t.settingsLibraryView}</Text>
          </View>
          <View className="mt-2 flex-row-reverse" style={{ gap: spacing.s }}>
            <Button
              mode={view === 'grid' ? 'contained' : 'outlined'}
              icon="view-grid-outline"
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
              icon="view-list-outline"
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

      <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.s, marginTop: spacing.l, marginBottom: spacing.s }}>
        <MaterialCommunityIcons name="calendar-clock-outline" size={20} color={colors.primary} />
        <Text variant="labelLarge" style={{ color: colors.primary, textAlign: 'right' }}>{t.settingsReview}</Text>
      </View>
      <Card style={{ backgroundColor: colors.surfaceContainerLow }}>
        <Card.Content>
          <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', lineHeight: 22 }}>
            {t.settingsIntervalsHelp}
          </Text>
          <View className="mt-2 flex-row-reverse flex-wrap" style={{ gap: spacing.s }}>
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
          <Button mode="contained" icon="content-save-outline" onPress={save} style={{ marginTop: spacing.s }}>
            {t.save}
          </Button>
        </Card.Content>
      </Card>

      <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.s, marginTop: spacing.l, marginBottom: spacing.s }}>
        <MaterialCommunityIcons name="database-outline" size={20} color={colors.primary} />
        <Text variant="labelLarge" style={{ color: colors.primary, textAlign: 'right' }}>{t.settingsData}</Text>
      </View>
      <Button mode="outlined" icon="archive-outline" onPress={() => navigation.navigate('Backup')} style={{ marginBottom: spacing.s }}>
        {t.settingsBackup}
      </Button>
      <Button mode="outlined" icon="playlist-remove" onPress={() => navigation.navigate('ClearData')} style={{ marginBottom: spacing.s }}>
        {t.settingsClear}
      </Button>
      <Button mode="outlined" icon="tag-multiple-outline" onPress={() => navigation.navigate('Categories')} style={{ marginBottom: spacing.s }}>
        {t.categories}
      </Button>

      <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.s, marginTop: spacing.l, marginBottom: spacing.s }}>
        <MaterialCommunityIcons name="shield-lock-outline" size={20} color={colors.primary} />
        <Text variant="labelLarge" style={{ color: colors.primary, textAlign: 'right' }}>{t.settingsPrivacy}</Text>
      </View>
      <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', lineHeight: 22 }}>
        {t.settingsPrivacyBody}
      </Text>
      <Text variant="bodySmall" style={{ color: colors.error, textAlign: 'right', marginTop: spacing.s, lineHeight: 22 }}>
        {t.settingsPrivacyWarning}
      </Text>

      <View style={{ flexDirection: 'row-reverse', alignItems: 'center', gap: spacing.s, marginTop: spacing.l, marginBottom: spacing.s }}>
        <MaterialCommunityIcons name="information-outline" size={20} color={colors.primary} />
        <Text variant="labelLarge" style={{ color: colors.primary, textAlign: 'right' }}>{t.settingsAbout}</Text>
      </View>
      <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right' }}>
        {t.settingsAboutBody}
      </Text>
      <Text variant="bodySmall" style={{ color: colors.onSurfaceVariant, textAlign: 'right', marginTop: 4 }}>
        {t.settingsVersion(Constants.expoConfig?.version ?? '2.3.7')}
      </Text>
      <Button
        mode="outlined"
        icon="whatsapp"
        onPress={() => void openExternalLink('https://chat.whatsapp.com/IsysOrI7U0vCW7PVUHPPnD')}
        style={{ marginTop: spacing.m }}
      >
        {t.settingsCommunity}
      </Button>
      <Button
        mode="outlined"
        icon="github"
        onPress={() => void openExternalLink('https://github.com/ayoub-ben-99/waraq-app')}
        style={{ marginTop: spacing.s }}
      >
        {t.settingsSourceCode}
      </Button>
    </ScrollView>
  );
}
