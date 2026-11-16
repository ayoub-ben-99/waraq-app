import { useEffect, useState } from 'react';
import { renderPage, type RenderedPage } from '../../features/pdf/native';

export type PageRenderState =
  | { status: 'loading' }
  | { status: 'ready'; page: RenderedPage }
  | { status: 'error' };

/** يُصيّر صفحة PDF واحدة إلى صورة، مع الذاكرة الأصلية فلا تُعاد الصياغة بلا داع. */
export function useRenderedPage(path: string | null, page: number, width: number, invert: boolean): PageRenderState {
  const [state, setState] = useState<PageRenderState>({ status: 'loading' });

  useEffect(() => {
    if (!path) {
      setState({ status: 'error' });
      return;
    }
    let active = true;
    setState({ status: 'loading' });
    void (async () => {
      try {
        const rendered = await renderPage(path, page, width, invert);
        if (active) setState({ status: 'ready', page: rendered });
      } catch {
        if (active) setState({ status: 'error' });
      }
    })();
    return () => {
      active = false;
    };
  }, [path, page, width, invert]);

  return state;
}
