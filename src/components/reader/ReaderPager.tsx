import React, { useCallback, useState } from 'react';
import { View } from 'react-native';
import PagerView, { type PagerViewOnPageSelectedEvent } from 'react-native-pager-view';
import { ReaderPageImage } from './ReaderPageImage';
import { ReaderPageText } from './ReaderPageText';
import type { ReaderTextFont } from '../../lib/prefs';

type Props = {
  path: string;
  pageCount: number;
  initialPage: number;
  textMode: boolean;
  invert: boolean;
  textSize: number;
  lineSpacing: number;
  textFont: ReaderTextFont;
  colors: {
    loading: string;
    hint: string;
    text: string;
  };
  onPageSelected: (page: number) => void;
};

/**
 * التقليب الأفقي بالسحب يمينًا ويسارًا (بلا أزرار سابق/تالٍ) مع اتجاه RTL،
 * وكل صفحة قابلة للتمرير العمودي من الداخل. تُصيَّر الصفحات القريبة فقط
 * (الحالية وما جاورها) حفاظًا على الذاكرة والسلاسة على هواتف متوسطة.
 */
export function ReaderPager(props: Props) {
  const [current, setCurrent] = useState(props.initialPage);

  const onPageSelected = useCallback(
    (event: PagerViewOnPageSelectedEvent) => {
      const page = event.nativeEvent.position;
      setCurrent(page);
      props.onPageSelected(page);
    },
    [props],
  );

  const pages: React.ReactNode[] = [];
  for (let index = 0; index < props.pageCount; index += 1) {
    const near = Math.abs(index - current) <= 1;
    pages.push(
      <View key={index} collapsable={false} style={{ flex: 1 }}>
        {near &&
          (props.textMode ? (
            <ReaderPageText
              path={props.path}
              page={index}
              textSize={props.textSize}
              lineSpacing={props.lineSpacing}
              fontFamily={props.textFont}
              textColor={props.colors.text}
              hintColor={props.colors.hint}
              loadingColor={props.colors.loading}
            />
          ) : (
            <ReaderPageImage
              path={props.path}
              page={index}
              invert={props.invert}
              loadingColor={props.colors.loading}
              errorColor={props.colors.hint}
            />
          ))}
      </View>,
    );
  }

  return (
    <PagerView
      style={{ flex: 1 }}
      initialPage={props.initialPage}
      layoutDirection="rtl"
      onPageSelected={onPageSelected}
      offscreenPageLimit={1}
    >
      {pages}
    </PagerView>
  );
}
