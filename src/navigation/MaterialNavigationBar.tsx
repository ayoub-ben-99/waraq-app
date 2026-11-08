import React, { useEffect, useRef, useState } from 'react';
import { Animated, Easing, Pressable, View } from 'react-native';
import type { BottomTabBarProps } from '@react-navigation/bottom-tabs';
import MaterialCommunityIcons from '@expo/vector-icons/MaterialCommunityIcons';
import { Text } from 'react-native-paper';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { t } from '../lib/strings';
import { useAppTheme } from '../theme/ThemeProvider';

type IconName = keyof typeof MaterialCommunityIcons.glyphMap;

const icons: Record<string, { active: IconName; inactive: IconName }> = {
  Home: { active: 'home-variant', inactive: 'home-variant-outline' },
  Library: { active: 'book-open-page-variant', inactive: 'book-open-page-variant-outline' },
  Knowledge: { active: 'notebook', inactive: 'notebook-outline' },
  Review: { active: 'cards', inactive: 'cards-outline' },
  Stats: { active: 'chart-box', inactive: 'chart-box-outline' },
};

const labels: Record<string, string> = {
  Home: t.home,
  Library: t.library,
  Knowledge: t.knowledge,
  Review: t.review,
  Stats: t.stats,
};

export function MaterialNavigationBar({ state, descriptors, navigation }: BottomTabBarProps) {
  const { colors, spacing, radius, fonts } = useAppTheme();
  const insets = useSafeAreaInsets();
  const routes = state.routes;
  const [barWidth, setBarWidth] = useState(0);
  const indicatorX = useRef(new Animated.Value(0)).current;
  const iconScales = useRef(new Map<string, Animated.Value>()).current;
  const itemWidth = barWidth / Math.max(routes.length, 1);
  const indicatorWidth = Math.min(76, Math.max(64, itemWidth - spacing.m));
  const activeDisplayIndex = routes.length - 1 - state.index;
  const indicatorTarget = activeDisplayIndex * itemWidth + Math.max(0, (itemWidth - indicatorWidth) / 2);

  routes.forEach((route) => {
    if (!iconScales.has(route.key)) iconScales.set(route.key, new Animated.Value(1));
  });

  useEffect(() => {
    if (!barWidth) return;
    Animated.timing(indicatorX, {
      toValue: indicatorTarget,
      duration: 280,
      easing: Easing.bezier(0.2, 0, 0, 1),
      useNativeDriver: true,
    }).start();
  }, [activeDisplayIndex, barWidth, indicatorTarget, indicatorX]);

  useEffect(() => {
    routes.forEach((route, index) => {
      const scale = iconScales.get(route.key);
      if (!scale) return;
      Animated.spring(scale, {
        toValue: index === state.index ? 1.08 : 1,
        damping: 16,
        stiffness: 220,
        mass: 0.7,
        useNativeDriver: true,
      }).start();
    });
  }, [iconScales, routes, state.index]);

  return (
    <View
      onLayout={(event) => setBarWidth(event.nativeEvent.layout.width)}
      style={{
        marginHorizontal: spacing.s,
        paddingTop: spacing.xs,
        paddingBottom: Math.max(insets.bottom, spacing.s),
        borderRadius: radius.card,
        backgroundColor: "transparent",
      }}
    >
      {barWidth > 0 ? (
        <Animated.View
          pointerEvents="none"
          style={{
            position: 'absolute',
            top: spacing.xs+2,
            left: 0,
            width: indicatorWidth,
            height: 54,
            borderRadius: radius.full,
            backgroundColor: colors.secondaryContainer,
            opacity: barWidth > 0 ? 1 : 0,
            transform: [{ translateX: indicatorX }],
          }}
        />
      ) : null}

      <View style={{ flexDirection: 'row-reverse' }}>
        {routes.map((route) => {
          const isFocused = state.routes[state.index].key === route.key;
          const routeIcons = icons[route.name] ?? { active: 'circle', inactive: 'circle-outline' };
          const iconScale = iconScales.get(route.key) ?? new Animated.Value(1);
          const { options } = descriptors[route.key];
          const label = labels[route.name] ?? options.title ?? route.name;
          const onPress = () => {
            const event = navigation.emit({ type: 'tabPress', target: route.key, canPreventDefault: true });
            if (!isFocused && !event.defaultPrevented) navigation.navigate(route.name, route.params);
          };
          const onLongPress = () => navigation.emit({ type: 'tabLongPress', target: route.key });

          return (
            <Pressable
              key={route.key}
              accessibilityRole="tab"
              accessibilityState={{ selected: isFocused }}
              accessibilityLabel={options.tabBarAccessibilityLabel}
              testID={options.tabBarButtonTestID}
              onPress={onPress}
              onLongPress={onLongPress}
              style={{
                flex: 1,
                minHeight: 58,
                alignItems: 'center',
                justifyContent: 'center',
                gap: spacing.xs,
                paddingHorizontal: spacing.xs,
                paddingVertical: spacing.xs,
              }}
            >
              <Animated.View style={{ transform: [{ scale: iconScale }] }}>
                <MaterialCommunityIcons
                  name={isFocused ? routeIcons.active : routeIcons.inactive}
                  size={24}
                  color={isFocused ? colors.onSecondaryContainer : colors.onSurfaceVariant}
                />
              </Animated.View>
              <Text
                numberOfLines={1}
                style={{
                  maxWidth: '100%',
                  color: isFocused ? colors.onSecondaryContainer : colors.onSurfaceVariant,
                  fontFamily: fonts.medium,
                  fontSize: 11,
                  lineHeight: 16,
                  textAlign: 'center',
                }}
              >
                {label}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </View>
  );
}
