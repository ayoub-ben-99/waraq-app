import React, { useEffect, useRef, useState } from 'react';
import { AccessibilityInfo, Animated, Pressable, StyleSheet, View } from 'react-native';
import MaterialCommunityIcons from '@expo/vector-icons/MaterialCommunityIcons';
import type { NavigationProp } from '@react-navigation/native';
import { Text } from 'react-native-paper';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useAppTheme } from '../theme/ThemeProvider';
import { motion } from '../theme/motion';
import { t } from '../lib/strings';
import type { RootStackParamList } from './types';

type Props = { navigation: NavigationProp<RootStackParamList> };
type Action = { label: string; icon: keyof typeof MaterialCommunityIcons.glyphMap; onPress: () => void };

export function QuickActionsFab({ navigation }: Props) {
  const { colors, spacing, radius, fonts } = useAppTheme();
  const insets = useSafeAreaInsets();
  const [mounted, setMounted] = useState(false);
  const [open, setOpen] = useState(false);
  const [reduceMotion, setReduceMotion] = useState(false);
  const progress = useRef([0, 1, 2, 3].map(() => new Animated.Value(0))).current;
  const rotation = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    let active = true;
    void AccessibilityInfo.isReduceMotionEnabled().then((enabled) => {
      if (active) setReduceMotion(enabled);
    });
    const subscription = AccessibilityInfo.addEventListener('reduceMotionChanged', setReduceMotion);
    return () => {
      active = false;
      subscription.remove();
    };
  }, []);

  const close = () => setOpen(false);
  const run = (callback: () => void) => {
    close();
    callback();
  };
  const actions: Action[] = [
    { label: t.bookAdd, icon: 'book-plus-outline', onPress: () => run(() => navigation.navigate('BookEdit')) },
    { label: t.entryNew, icon: 'note-plus-outline', onPress: () => run(() => navigation.navigate('EntryEdit', { type: 1 })) },
    { label: t.categoriesAdd, icon: 'shape-plus-outline', onPress: () => run(() => navigation.navigate('Categories')) },
    { label: t.reviewStart, icon: 'cards-outline', onPress: () => run(() => navigation.navigate('Tabs', { screen: 'Review' })) },
  ];

  useEffect(() => {
    if (!mounted) return;
    const duration = reduceMotion ? 0 : motion.duration.short;
    const openAnimations = progress.map((value, index) =>
      Animated.timing(value, {
        toValue: open ? 1 : 0,
        duration,
        delay: open ? index * motion.stagger : 0,
        useNativeDriver: true,
      }),
    );
    Animated.parallel([
      ...openAnimations,
      Animated.timing(rotation, { toValue: open ? 1 : 0, duration, useNativeDriver: true }),
    ]).start(({ finished }) => {
      if (finished && !open) setMounted(false);
    });
  }, [mounted, open, progress, reduceMotion, rotation]);

  const toggle = () => {
    if (open) {
      close();
      return;
    }
    setMounted(true);
    setOpen(true);
  };

  const rotate = rotation.interpolate({ inputRange: [0, 1], outputRange: ['0deg', '45deg'] });

  return (
    <View pointerEvents="box-none" style={StyleSheet.absoluteFill}>
      {mounted ? <Pressable accessibilityLabel={t.cancel} onPress={close} style={StyleSheet.absoluteFill} /> : null}
      {mounted ? (
        <View
          pointerEvents="box-none"
          style={[styles.actions, { right: spacing.m, bottom: insets.bottom + 156 }]}
        >
          {actions.map((action, index) => {
            const animatedStyle = {
              opacity: progress[index],
              transform: [
                { translateY: progress[index].interpolate({ inputRange: [0, 1], outputRange: [12, 0] }) },
                { scale: progress[index].interpolate({ inputRange: [0, 1], outputRange: [0.96, 1] }) },
              ],
            };
            return (
              <Animated.View key={action.label} style={animatedStyle}>
                <Pressable
                  accessibilityRole="button"
                  accessibilityLabel={action.label}
                  onPress={action.onPress}
                  style={({ pressed }) => [
                    styles.action,
                    {
                      borderRadius: radius.card,
                      paddingHorizontal: spacing.m,
                      backgroundColor: pressed ? colors.surfaceContainerHighest : colors.surfaceContainerHigh,
                    },
                  ]}
                >
                  <MaterialCommunityIcons name={action.icon} size={22} color={colors.primary} />
                  <Text style={{ color: colors.onSurface, fontFamily: fonts.medium, marginEnd: spacing.s }}>{action.label}</Text>
                </Pressable>
              </Animated.View>
            );
          })}
        </View>
      ) : null}
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={open ? t.cancel : 'إضافة'}
        accessibilityState={{ expanded: open }}
        onPress={toggle}
        style={({ pressed }) => [
          styles.fab,
          {
            right: spacing.m,
            bottom: insets.bottom + 88,
            borderRadius: radius.card+10,
            backgroundColor: pressed ? colors.primaryContainer : colors.primary,
          },
        ]}
      >
        <Animated.View style={{ transform: [{ rotate }] }}>
          <MaterialCommunityIcons name="plus" size={28} color={colors.onPrimary} />
        </Animated.View>
      </Pressable>
    </View>
  );
}

const styles = StyleSheet.create({
  actions: {
    position: 'absolute',
    alignItems: 'flex-end',
    gap: 8,
  },
  action: {
    minHeight: 48,
    flexDirection: 'row-reverse',
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 8,
  },
  fab: {
    position: 'absolute',
    width: 56,
    height: 56,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
