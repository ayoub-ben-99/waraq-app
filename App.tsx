import './global.css';
import React, { useCallback, useEffect, useState } from 'react';
import { View, Text, StyleSheet, I18nManager } from 'react-native';
import { StatusBar } from 'expo-status-bar';
import * as SplashScreen from 'expo-splash-screen';
import { useFonts } from 'expo-font';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { md3DarkColors } from './src/theme/md3Colors';
import { md3LightColors } from './src/theme/md3Colors';
import { NavigationContainer, DefaultTheme as NavigationDefaultTheme, DarkTheme as NavigationDarkTheme } from '@react-navigation/native';
import { PaperProvider } from 'react-native-paper';
import { RootNavigator } from './src/navigation/RootNavigator';
import { initializeDatabase } from './src/data/db/client';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { AppThemeProvider, useAppTheme } from './src/theme/ThemeProvider';
import { useColorScheme } from 'react-native';
import { t } from './src/lib/strings';
import { AnimatedSplash } from './src/ui/motion/AnimatedSplash';

I18nManager.allowRTL(true);
I18nManager.forceRTL(true);
void SplashScreen.preventAutoHideAsync();

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      staleTime: 5_000,
      refetchOnWindowFocus: false,
      refetchOnReconnect: false,
      gcTime: 1000 * 60 * 10,
    },
    mutations: { retry: 0 },
  },
});

function ThemedApp() {
  const [splashDone, setSplashDone] = useState(false);
  const { paper, colors, dark } = useAppTheme();
  const base = dark ? NavigationDarkTheme : NavigationDefaultTheme;
  const navigationTheme = {
    ...base,
    colors: {
      ...base.colors,
      primary: colors.primary,
      background: colors.background,
      card: colors.surface,
      text: colors.onSurface,
      border: colors.outlineVariant,
      notification: colors.error,
    },
  };
  return (
    <PaperProvider theme={paper}>
      <NavigationContainer theme={navigationTheme}>
        <StatusBar style={dark ? 'light' : 'dark'} />
        <RootNavigator />
      </NavigationContainer>
      {!splashDone && <AnimatedSplash onDone={() => setSplashDone(true)} />}
    </PaperProvider>
  );
}

export default function App() {
  const [fontsLoaded, fontError] = useFonts({
    PlexRegular: require('./assets/fonts/plex_regular.ttf'),
    PlexMedium: require('./assets/fonts/plex_medium.ttf'),
    PlexSemiBold: require('./assets/fonts/plex_semibold.ttf'),
    Amiri: require('./assets/fonts/amiri_regular.ttf'),
  });
  const [dbError, setDbError] = useState<string | null>(null);
  const [dbReady, setDbReady] = useState(false);
  const scheme = useColorScheme();
  const colors = scheme === 'dark' ? md3DarkColors : md3LightColors;

  useEffect(() => {
    try {
      initializeDatabase();
      setDbReady(true);
    } catch (err) {
      const message = err instanceof Error ? err.message : '';
      setDbError(
        message.startsWith('waraq-db-newer:')
          ? `قاعدة البيانات من إصدار أحدث (${message.split(':')[1]}) ولا يمكن فتحها بهذا الإصدار من التطبيق.`
          : t.genericError,
      );
    }
  }, []);

  const ready = (fontsLoaded || !!fontError) && (dbReady || !!dbError);
  const onLayout = useCallback(() => {
    if (ready) void SplashScreen.hideAsync();
  }, [ready]);

  if (!ready) return null;

  if (dbError) {
    return (
      <View style={[styles.errorContainer, { backgroundColor: colors.surface }]} onLayout={onLayout}>
        <Text style={[styles.errorText, { color: colors.onSurface }]}>{dbError}</Text>
      </View>
    );
  }

  return (
    <View style={styles.root} onLayout={onLayout}>
      <SafeAreaProvider>
        <AppThemeProvider>
          <QueryClientProvider client={queryClient}>
            <ThemedApp />
          </QueryClientProvider>
        </AppThemeProvider>
      </SafeAreaProvider>
    </View>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1 },
  errorContainer: { flex: 1, alignItems: 'center', justifyContent: 'center', padding: 24 },
  errorText: { fontSize: 16, textAlign: 'center', lineHeight: 26 },
});
