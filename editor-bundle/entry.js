import { Editor, defaultValueCtx, editorViewCtx, rootCtx } from '@milkdown/kit/core';
import { commonmark } from '@milkdown/kit/preset/commonmark';
import { gfm } from '@milkdown/kit/preset/gfm';
import { listener, listenerCtx } from '@milkdown/kit/plugin/listener';
import { getMarkdown, replaceAll } from '@milkdown/kit/utils';

window.MilkdownEditor = { Editor, defaultValueCtx, editorViewCtx, rootCtx };
window.MilkdownPresets = { commonmark, gfm };
window.MilkdownPlugins = { listener, listenerCtx };
window.MilkdownUtils = { getMarkdown, replaceAll };
