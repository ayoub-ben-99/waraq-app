import React from 'react';
import { Dimensions, Image, PixelRatio, ScrollView, View } from 'react-native';
import { ActivityIndicator, Text } from 'react-native-paper';
import { useAppTheme } from '../../theme/ThemeProvider';
import { t } from '../../lib/strings';
import { useRenderedPage } from './useRenderedPage';

/** عرض الصياغة: عرض الشاشة بكثافة البكسل، بسقف معقول حفاظًا على الذاكرة. */
export function renderWidth(): number {
  const width = Math.round(Dimensions.get('window').width * PixelRatio.get());
  return Math.min(1440, Math.max(720, width));
}

type Props = {
  path: string;
  page: number;
  invert: boolean;
  loadingColor: string;
  errorColor: string;
};

/**
 * صفحة واحدة في وضع الصفحات: صورة كاملة مع تمرير عمودي سلس داخل الصفحة،
 * والتقليب الأفقي يتكفل به PagerView في الأعلى.
 */
export function ReaderPageImage(props: Props) {
  const width = renderWidth();
  const state = useRenderedPage(props.path, props.page, width, props.invert);

  if (state.status === 'error') {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center', padding: 24 }}>
        <Text style={{ color: props.errorColor, textAlign: 'center', fontSize: 14 }}>{t.pdfUnreadable}</Text>
      </View>
    );
  }

  if (state.status === 'loading' || !state.page.uri) {
    return (
      <View style={{ flex: 1, alignItems: 'center', justifyContent: 'center' }}>
        <ActivityIndicator color={props.loadingColor} />
        <Text style={{ color: props.errorColor, marginTop: 12, fontSize: 13 }}>{t.pdfLoading}</Text>
      </View>
    );
  }

  const aspect = state.page.width > 0 ? state.page.width / state.page.height : 1;
  return (
    <ScrollView
      style={{ flex: 1 }}
      contentContainerStyle={{ padding: 12 }}
      showsVerticalScrollIndicator={false}
      maximumZoomScale={2.5}
      minimumZoomScale={1}
    >
      <Image
        source={{ uri: state.page.uri }}
        resizeMode="contain"
        style={{
          width: '100%',
          aspectRatio: aspect,
          borderRadius: 8,
          backgroundColor: 'transparent',
        }}
      />
    </ScrollView>
  );
}
