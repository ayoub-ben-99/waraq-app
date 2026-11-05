// Ported from app/src/main/java/com/waraq/app/ui/MainActivity.java
import React from 'react';
import { I18nManager, Pressable } from 'react-native';
import {  DefaultTheme as NavLight, DarkTheme as NavDark } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import MaterialCommunityIcons from '@expo/vector-icons/MaterialCommunityIcons';
import { useNavigation, type NavigationProp } from '@react-navigation/native';
import type { RootStackParamList, TabParamList } from './types';
import { useAppTheme } from '../theme/ThemeProvider';
import { t } from '../lib/strings';
import { HomeScreen } from '../screens/HomeScreen';
import { LibraryScreen } from '../screens/LibraryScreen';
import { KnowledgeScreen } from '../screens/KnowledgeScreen';
import { ReviewScreen } from '../screens/ReviewScreen';
import { StatsScreen } from '../screens/StatsScreen';
import { BookDetailScreen } from '../screens/BookDetailScreen';
import { BookEditScreen } from '../screens/BookEditScreen';
import { CategoriesScreen } from '../screens/CategoriesScreen';
import { EntryEditScreen } from '../screens/EntryEditScreen';
import { SummaryScreen } from '../screens/SummaryScreen';
import { ReviewSessionScreen } from '../screens/ReviewSessionScreen';
import { SearchScreen } from '../screens/SearchScreen';
import { SettingsScreen } from '../screens/SettingsScreen';
import { BackupScreen } from '../screens/BackupScreen';
import { ClearDataScreen } from '../screens/ClearDataScreen';
import { AudioNoteScreen } from '../screens/AudioNoteScreen';
import { PdfReaderScreen } from '../screens/PdfReaderScreen';

I18nManager.allowRTL(true);
I18nManager.forceRTL(true);

const Stack = createNativeStackNavigator<RootStackParamList>();
const Tabs = createBottomTabNavigator<TabParamList>();

const icons: Record<keyof TabParamList, keyof typeof MaterialCommunityIcons.glyphMap> = {
  Home: 'home-variant-outline',
  Library: 'bookshelf',
  Knowledge: 'notebook-outline',
  Review: 'cards-outline',
  Stats: 'chart-box-outline',
};

const labels: Record<keyof TabParamList, string> = {
  Home: t.home,
  Library: t.library,
  Knowledge: t.knowledge,
  Review: t.review,
  Stats: t.stats,
};

function TabNavigator() {
  const { colors, paper, dark } = useAppTheme();
  const navigation = useNavigation<NavigationProp<RootStackParamList>>();
  return (
    <Tabs.Navigator
      screenOptions={({ route }) => ({
        headerStyle: { backgroundColor: colors.background },
        headerShadowVisible: false,
        headerTitleStyle: { color: colors.onSurface, fontFamily: paper.fonts.titleLarge.fontFamily, fontSize: 21 },
        headerTitleAlign: 'center',
        headerRight: () => (
          <Pressable onPress={() => navigation.navigate('Search')} hitSlop={12} style={{ paddingHorizontal: 12 }}>
            <MaterialCommunityIcons name="magnify" size={24} color={colors.onSurface} />
          </Pressable>
        ),
        headerLeft: () => (
          <Pressable onPress={() => navigation.navigate('Settings')} hitSlop={12} style={{ paddingHorizontal: 12 }}>
            <MaterialCommunityIcons name="cog-outline" size={24} color={colors.onSurface} />
          </Pressable>
        ),
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.onSurfaceVariant,
        tabBarStyle: { backgroundColor: colors.surface, borderTopColor: colors.outline, height: 64, paddingBottom: 8, paddingTop: 6 },
        tabBarLabelStyle: { fontFamily: paper.fonts.labelSmall.fontFamily, fontSize: 11 },
        tabBarIcon: ({ color, size }) => (
          <MaterialCommunityIcons name={icons[route.name]} size={size} color={color} />
        ),
        title: labels[route.name],
        headerShown: route.name !== 'Home' ? true : true,
        tabBarHideOnKeyboard: true,
        freezeOnBlur: true,
        sceneStyle: { backgroundColor: dark ? colors.background : colors.background },
      })}
    >
      <Tabs.Screen name="Home" component={HomeScreen} options={{ title: labels.Home }} />
      <Tabs.Screen name="Library" component={LibraryScreen} options={{ title: labels.Library }} />
      <Tabs.Screen name="Knowledge" component={KnowledgeScreen} options={{ title: labels.Knowledge }} />
      <Tabs.Screen name="Review" component={ReviewScreen} options={{ title: labels.Review }} />
      <Tabs.Screen name="Stats" component={StatsScreen} options={{ title: labels.Stats }} />
    </Tabs.Navigator>
  );
}

export function RootNavigator() {
  const { colors, paper, dark } = useAppTheme();
  const base = dark ? NavDark : NavLight;
  const navTheme = {
    ...base,
    colors: {
      ...base.colors,
      primary: colors.primary,
      background: colors.background,
      card: colors.surface,
      text: colors.onSurface,
      border: colors.outline,
      notification: colors.error,
    },
    fonts: base.fonts,
  };

  return (
    <Stack.Navigator
      screenOptions={{
        headerStyle: { backgroundColor: colors.background },
        headerShadowVisible: false,
        headerTintColor: colors.onSurface,
        headerTitleStyle: { fontFamily: paper.fonts.titleLarge.fontFamily, fontSize: 20, color: colors.onSurface },
        headerTitleAlign: 'center',
        headerBackButtonDisplayMode: 'minimal',
        contentStyle: { backgroundColor: colors.background },
        animation: 'slide_from_left',
      }}
    >
      <Stack.Screen name="Tabs" component={TabNavigator} options={{ headerShown: false }} />
      <Stack.Screen name="BookDetail" component={BookDetailScreen} options={{ title: t.bookDetail, animation: 'slide_from_left' }} />
      <Stack.Screen name="BookEdit" component={BookEditScreen} options={{ title: t.bookEdit, presentation: 'modal' }} />
      <Stack.Screen name="Categories" component={CategoriesScreen} options={{ title: t.categories }} />
      <Stack.Screen name="EntryEdit" component={EntryEditScreen} options={{ title: t.entryNew, presentation: 'modal' }} />
      <Stack.Screen name="Summary" component={SummaryScreen} options={{ title: t.bookSummary }} />
      <Stack.Screen name="ReviewSession" component={ReviewSessionScreen} options={{ title: t.reviewSessionTitle, presentation: 'modal' }} />
      <Stack.Screen name="Search" component={SearchScreen} options={{ title: t.search }} />
      <Stack.Screen name="Settings" component={SettingsScreen} options={{ title: t.settings }} />
      <Stack.Screen name="Backup" component={BackupScreen} options={{ title: t.backupTitle }} />
      <Stack.Screen name="ClearData" component={ClearDataScreen} options={{ title: t.clearTitle }} />
      <Stack.Screen name="AudioNote" component={AudioNoteScreen} options={{ title: t.audioTitle, presentation: 'modal' }} />
      <Stack.Screen name="PdfReader" component={PdfReaderScreen} options={{ headerShown: false }} />
    </Stack.Navigator>
  );
}
