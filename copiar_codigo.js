(() => {
  'use strict';

  function copyWithSelection(text) {
    const focused = document.activeElement;
    const selection = window.getSelection();
    const ranges = [];
    if (selection) {
      for (let i = 0; i < selection.rangeCount; i++) {
        ranges.push(selection.getRangeAt(i).cloneRange());
      }
    }
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.readOnly = true;
    textarea.style.cssText = 'position:fixed;left:-9999px;top:0;font-size:16px';
    document.body.appendChild(textarea);
    try {
      textarea.focus({ preventScroll: true });
      textarea.select();
      textarea.setSelectionRange(0, text.length);
      if (!document.execCommand('copy')) {
        throw new Error('Cópia indisponível');
      }
    } finally {
      textarea.remove();
      if (focused) focused.focus({ preventScroll: true });
      if (selection) {
        selection.removeAllRanges();
        ranges.forEach(range => selection.addRange(range));
      }
    }
  }

  async function copyText(text) {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      try {
        await navigator.clipboard.writeText(text);
        return;
      } catch {
        // Arquivos locais e permissões do navegador podem exigir a seleção.
      }
    }
    copyWithSelection(text);
  }

  const ICON_COPY = '<svg viewBox="0 0 16 16" aria-hidden="true" focusable="false"><rect x="5.5" y="5.5" width="8.5" height="8.5" rx="1.5"/><path d="M10.5 3.5V3A1.5 1.5 0 0 0 9 1.5H3.5A1.5 1.5 0 0 0 2 3v5.5A1.5 1.5 0 0 0 3.5 10H4"/></svg>';
  const ICON_OK = '<svg viewBox="0 0 16 16" aria-hidden="true" focusable="false"><path d="M3 8.5l3.2 3.2L13 4.8"/></svg>';
  const STATES = {
    idle: [ICON_COPY, 'Copiar'],
    ok: [ICON_OK, 'Copiado!'],
    erro: [ICON_COPY, 'Selecionado: tecle Ctrl+C']
  };

  function setState(button, state) {
    const [icon, label] = STATES[state];
    button.dataset.state = state;
    button.innerHTML = icon + '<span>' + label + '</span>';
  }

  function addCopyButtons() {
    if (!document.getElementById('copiar-codigo-estilos')) {
      const style = document.createElement('style');
      style.id = 'copiar-codigo-estilos';
      style.textContent = `
        .code-block{margin:1em 0;min-width:0}
        .code-block>pre{margin:0;border-top-width:0;border-radius:0 0 8px 8px}
        .code-copy-toolbar{display:flex;align-items:center;justify-content:space-between;gap:12px;padding:4px 6px 4px 16px;background:#1b2635;border:1px solid #364456;border-radius:8px 8px 0 0}
        .code-copy-label{font:600 12px/1 Consolas,monospace;letter-spacing:.08em;text-transform:uppercase;color:#9fb0c3}
        .code-block .copy-code-button{display:inline-flex;align-items:center;gap:6px;min-height:32px;margin:0;padding:4px 10px;font:600 13px/1.2 "Segoe UI",Arial,sans-serif;color:#c9d6e3;background:transparent;border:1px solid transparent;border-radius:6px;cursor:pointer;transition:background-color .15s,border-color .15s,color .15s}
        .code-block .copy-code-button svg{width:16px;height:16px;flex:none;fill:none;stroke:currentColor;stroke-width:1.5;stroke-linecap:round;stroke-linejoin:round}
        .code-block .copy-code-button:hover{color:#fff;background:#26354a;border-color:#4a5d75}
        .code-block .copy-code-button:active{background:#2c4564}
        .code-block .copy-code-button:focus-visible{outline:2px solid #8dcaff;outline-offset:2px}
        .code-block .copy-code-button[data-state="ok"]{color:#8be0b1;background:#15302a;border-color:#2f6f50}
        .code-block .copy-code-button[data-state="erro"]{color:#ffd58f;background:#33291a;border-color:#7a6230}
        .code-copy-status{position:absolute;width:1px;height:1px;padding:0;margin:-1px;overflow:hidden;clip-path:inset(50%);white-space:nowrap}
        @media (prefers-reduced-motion:reduce){.code-block .copy-code-button{transition:none}}
        @media print{.code-copy-toolbar{display:none!important}.code-block>pre{border-top-width:1px;border-radius:8px}}
      `;
      document.head.appendChild(style);
    }

    document.querySelectorAll('pre > code').forEach(code => {
      const pre = code.parentElement;
      if (pre.closest('.code-block')) return;
      const wrapper = document.createElement('div');
      wrapper.className = 'code-block';
      const toolbar = document.createElement('div');
      toolbar.className = 'code-copy-toolbar';
      const label = document.createElement('span');
      label.className = 'code-copy-label';
      // Todos os blocos do material são SQL, exceto o exemplo de psql do nível 1.
      label.textContent = /^\s*psql\s/.test(code.textContent) ? 'Terminal' : 'SQL';
      const button = document.createElement('button');
      button.type = 'button';
      button.className = 'copy-code-button';
      button.setAttribute('aria-label', 'Copiar bloco de código');
      setState(button, 'idle');
      const status = document.createElement('span');
      status.className = 'code-copy-status';
      status.setAttribute('role', 'status');
      toolbar.append(label, button, status);
      pre.before(wrapper);
      wrapper.append(toolbar, pre);

      let copying = false;
      let resetTimer;
      button.addEventListener('click', async () => {
        if (copying) return;
        copying = true;
        clearTimeout(resetTimer);
        status.textContent = '';
        try {
          await copyText(code.textContent);
          setState(button, 'ok');
          status.textContent = 'Código copiado para a área de transferência.';
        } catch {
          const selection = window.getSelection();
          const range = document.createRange();
          range.selectNodeContents(code);
          if (selection) {
            selection.removeAllRanges();
            selection.addRange(range);
          }
          setState(button, 'erro');
          status.textContent = 'Não foi possível copiar automaticamente. O código foi selecionado; tecle Ctrl+C para copiá-lo.';
        } finally {
          copying = false;
          resetTimer = setTimeout(() => {
            setState(button, 'idle');
            status.textContent = '';
          }, button.dataset.state === 'erro' ? 6000 : 2500);
        }
      });
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', addCopyButtons, { once: true });
  } else {
    addCopyButtons();
  }
})();
