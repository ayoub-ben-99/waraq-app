import React from 'react';
import { Dimensions, Image, Pressable, View } from 'react-native';
import { ActivityIndicator, Modal, Portal, Surface, Text } from 'react-native-paper';
import { FlashList } from '@shopify/flash-list';
import { t } from '../../lib/strings';
import { useAppTheme } from '../../theme/ThemeProvider';
import { useRenderedPage } from './useRenderedPage';

const THUMB_WIDTH = 220;

type Props = {
  visible: boolean;
  onDismiss: () => void;
  pageCount: number;
  currentPage: number;
  path: string;
  invert: boolean;
  onSelect: (page: number) => void;
};

function Thumb(props: { path: string; page: number; invert: boolean; active: boolean; onSelect: (page: number) => void }) {
  const { colors } = useAppTheme();
  const state = useRenderedPage(props.path, props.page, THUMB_WIDTH, props.invert);
  const aspect = state.status === 'ready' && state.page.height > 0 ? state.page.width / state.page.height : 0.7;
  return (
    <Pressable
      onPress={() => props.onSelect(props.page)}
      accessibilityLabel={t.readerThumbHint(props.page + 1)}
      style={{
        borderRadius: 12,
        borderWidth: 2,
        borderColor: props.active ? colors.primary : 'transparent',
        overflow: 'hidden',
        backgroundColor: colors.surfaceContainerHigh,
        marginHorizontal: 6,
        marginBottom: 12,
      }}
    >
      {state.status === 'ready' ? (
        <Image source={{ uri: state.page.uri }} style={{ width: '100%', aspectRatio: aspect }} resizeMode="cover" />
      ) : (
        <View style={{ width: '100%', aspectRatio: 0.7, alignItems: 'center', justifyContent: 'center' }}>
          {state.status === 'error' ? (
            <Text style={{ color: colors.onSurfaceVariant, fontSize: 11 }}>{t.none}</Text>
          ) : (
            <ActivityIndicator size="small" color={colors.primary} />
          )}
        </View>
      )}
      <View style={{ position: 'absolute', bottom: 0, left: 0, right: 0, padding: 6, backgroundColor: 'rgba(0,0,0,0.45)' }}>
        <Text style={{ color: '#FFFFFF', fontSize: 12, textAlign: 'center' }}>{t.readerPage(props.page + 1)}</Text>
      </View>
    </Pressable>
  );
}

/**
 * نافذة التنقل بين الصفحات: شبكة مصغّرات مع الصفحة الحالية مميّزة،
 * والاختيار يقفز مباشرة إلى الصفحة.
 */
export function ReaderNavSheet(props: Props) {
  const { colors } = useAppTheme();
  const columns = Dimensions.get('window').width > 600 ? 3 : 2;
  return (
    <Portal>
      <Modal visible={props.visible} onDismiss={props.onDismiss} contentContainerStyle={{ flex: 1, marginTop: 12 }}>
        <Surface
          elevation={2}
          style={{
            flex: 1,
            borderTopLeftRadius: 28,
            borderTopRightRadius: 28,
            backgroundColor: colors.surface,
            paddingTop: 8,
          }}
        >
          <Text style={{ fontSize: 18, color: colors.onSurface, textAlign: 'center', padding: 12 }}>
            {t.readerNavigation}
          </Text>
          <FlashList
            data={Array.from({ length: props.pageCount }, (_, index) => index)}
            numColumns={columns}
            keyExtractor={(page) => String(page)}
            contentContainerStyle={{ paddingHorizontal: 12, paddingBottom: 24 }}
            initialScrollIndex={Math.max(0, props.currentPage - 1)}
            renderItem={({ item }) => (
              <Thumb
                path={props.path}
                page={item}
                invert={props.invert}
                active={item === props.currentPage}
                onSelect={props.onSelect}
              />
            )}
          />
        </Surface>
      </Modal>
    </Portal>
  );
}
