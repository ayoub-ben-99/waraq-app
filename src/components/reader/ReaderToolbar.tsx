import React from 'react';
import { I18nManager, View } from 'react-native';
import { IconButton, Text } from 'react-native-paper';
import { useAppTheme } from '../../theme/ThemeProvider';
import { t } from '../../lib/strings';

type Props = {
  title: string;
  pageLabel: string;
  titleColor: string;
  labelColor: string;
  iconColor: string;
  dark: boolean;
  textMode: boolean;
  onBack: () => void;
  onToggleDark: () => void;
  onToggleTextMode: () => void;
  onOpenNavigation: () => void;
  onOpenSettings: () => void;
};

export function ReaderToolbar(props: Props) {
  const { paper } = useAppTheme();
  // RTL: سهم الرجوع ينعكس تلقائيًا مع اتجاه الواجهة.
  const backIcon = I18nManager.isRTL ? 'arrow-forward' : 'arrow-back';
  return (
    <View
      style={{
        flexDirection: 'row',
        alignItems: 'center',
        paddingHorizontal: 4,
        height: 56,
      }}
    >
      <IconButton icon={backIcon} onPress={props.onBack} accessibilityLabel={t.back} iconColor={props.iconColor} />
      <View style={{ flex: 1, alignItems: 'center' }}>
        <Text
          numberOfLines={1}
          style={{
            fontFamily: paper.fonts.titleMedium.fontFamily,
            fontSize: 17,
            color: props.titleColor,
          }}
        >
          {props.title}
        </Text>
        <Text
          style={{
            fontFamily: paper.fonts.labelSmall.fontFamily,
            fontSize: 12,
            color: props.labelColor,
          }}
        >
          {props.pageLabel}
        </Text>
      </View>
      <ReaderIconButton
        icon={props.textMode ? 'book-open-page-variant' : 'format-annotations'}
        label={props.textMode ? t.readerModePages : t.readerModeText}
        onPress={props.onToggleTextMode}
        color={props.iconColor}
      />
      <ReaderIconButton
        icon={props.dark ? 'white-balance-sunny' : 'weather-night'}
        label={props.dark ? t.readerLightMode : t.readerDarkMode}
        onPress={props.onToggleDark}
        color={props.iconColor}
      />
      <ReaderIconButton
        icon="table-of-contents"
        label={t.readerNavigation}
        onPress={props.onOpenNavigation}
        color={props.iconColor}
      />
      <ReaderIconButton icon="tune" label={t.readerSettings} onPress={props.onOpenSettings} color={props.iconColor} />
    </View>
  );
}

function ReaderIconButton(props: { icon: string; label: string; onPress: () => void; color: string }) {
  return (
    <IconButton
      icon={props.icon}
      size={22}
      onPress={props.onPress}
      accessibilityLabel={props.label}
      iconColor={props.color}
      style={{ marginHorizontal: 1 }}
    />
  );
}
