import React from 'react';
import { I18nManager, Pressable, View } from 'react-native';
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
import { MaterialNavigationBar } from './MaterialNavigationBar';
import { QuickActionsFab } from './QuickActionsFab';

I18nManager.allowRTL(true);
I18nManager.forceRTL(true);

const Stack = createNativeStackNavigator<RootStackParamList>();
const Tabs = createBottomTabNavigator<TabParamList>();

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
    <View style={{ flex: 1 }}>
      <Tabs.Navigator
        tabBar={(props) => <MaterialNavigationBar {...props} />}
        screenOptions={({ route }) => ({
        headerStyle: { backgroundColor: colors.background },
        headerShadowVisible: false,
        headerTitleStyle: { color: colors.onSurface, fontFamily: paper.fonts.titleLarge.fontFamily, fontSize: 21 },
        headerTitleAlign: 'center',
        headerRight: () => (
          <Pressable
            onPress={() => navigation.navigate('Search')}
            hitSlop={8}
            accessibilityRole="button"
            accessibilityLabel={t.search}
            style={{ minWidth: 48, minHeight: 48, alignItems: 'center', justifyContent: 'center' }}
          >
            <MaterialCommunityIcons name="magnify" size={24} color={colors.onSurface} />
          </Pressable>
        ),
        headerLeft: () => (
          <Pressable
            onPress={() => navigation.navigate('Settings')}
            hitSlop={8}
            accessibilityRole="button"
            accessibilityLabel={t.settings}
            style={{ minWidth: 48, minHeight: 48, alignItems: 'center', justifyContent: 'center' }}
          >
            <MaterialCommunityIcons name="cog-outline" size={24} color={colors.onSurface} />
          </Pressable>
        ),
        title: labels[route.name],
        headerShown: route.name !== 'Home' ? true : true,
        tabBarHideOnKeyboard: true,
        freezeOnBlur: true,
        animation: 'none',
        sceneStyle: { backgroundColor: dark ? colors.background : colors.background },
        })}
      >
        <Tabs.Screen name="Home" component={HomeScreen} options={{ title: labels.Home }} />
        <Tabs.Screen name="Library" component={LibraryScreen} options={{ title: labels.Library }} />
        <Tabs.Screen name="Knowledge" component={KnowledgeScreen} options={{ title: labels.Knowledge }} />
        <Tabs.Screen name="Review" component={ReviewScreen} options={{ title: labels.Review }} />
        <Tabs.Screen name="Stats" component={StatsScreen} options={{ title: labels.Stats }} />
      </Tabs.Navigator>
      <QuickActionsFab navigation={navigation} />
    </View>
  );
}

export function RootNavigator() {
  const { colors, paper } = useAppTheme();

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
        animation: 'fade_from_bottom',
        animationDuration: 600,
      }}
    >
      <Stack.Screen name="Tabs" component={TabNavigator} options={{ headerShown: false }} />
      <Stack.Screen name="BookDetail" component={BookDetailScreen} options={{ title: t.bookDetail, animation: 'fade_from_bottom', animationDuration: 600 }} />
      <Stack.Screen name="BookEdit" component={BookEditScreen} options={{ title: t.bookEdit, presentation: 'modal', animation: 'slide_from_bottom' }} />
      <Stack.Screen name="Categories" component={CategoriesScreen} options={{ title: t.categories }} />
      <Stack.Screen name="EntryEdit" component={EntryEditScreen} options={{ title: t.entryNew, presentation: 'modal', animation: 'slide_from_bottom' }} />
      <Stack.Screen name="Summary" component={SummaryScreen} options={{ title: t.bookSummary }} />
      <Stack.Screen name="ReviewSession" component={ReviewSessionScreen} options={{ title: t.reviewSessionTitle, presentation: 'modal', animation: 'slide_from_bottom' }} />
      <Stack.Screen name="Search" component={SearchScreen} options={{ title: t.search }} />
      <Stack.Screen name="Settings" component={SettingsScreen} options={{ title: t.settings }} />
      <Stack.Screen name="Backup" component={BackupScreen} options={{ title: t.backupTitle }} />
      <Stack.Screen name="ClearData" component={ClearDataScreen} options={{ title: t.clearTitle }} />
      <Stack.Screen name="AudioNote" component={AudioNoteScreen} options={{ title: t.audioTitle, presentation: 'modal', animation: 'slide_from_bottom' }} />
      <Stack.Screen name="PdfReader" component={PdfReaderScreen} options={{ headerShown: false }} />
    </Stack.Navigator>
  );
}
