(() => {
  if (window.__mfbEmbedded) return;
  window.__mfbEmbedded = true;
  const nonce = __MFB_NONCE__;
  const send = (data) => MfbDashboard.postMessage(JSON.stringify({...data, nonce}));
  const style = document.createElement('style');
  style.textContent = `
    .crucix-app-left, .crucix-app-spacer,
    .crucix-map-controls, .crucix-standalone-map-controls, .map-controls,
    #topbar .top-left, #topbar .mainnav, #topbar .top-spacer { display: none !important; }
    .crucix-app-right > :not(.crucix-app-status):not(.crucix-app-theme-toggle),
    #topbar .top-right > :not(.tb-status):not(.theme-toggle) { display: none !important; }
    .crucix-app-toolbar { min-height: 0 !important; padding: 4px 12px !important; }
    .crucix-app-right, #topbar .top-right { width: 100% !important; justify-content: space-between !important; }
    #topbar { height: auto !important; min-height: 0 !important; padding: 4px 12px !important; }
    html, body { background: #05070b; overscroll-behavior-y: contain; }
    @media (max-width: 640px) {
      .crucix-map-control { min-width: 40px; min-height: 40px; }
    }
  `;
  document.head.appendChild(style);

  const normalize = (shape) => {
    if (!shape || typeof shape !== 'object') return shape;
    if (shape.kind === 'rect' && shape.sw && shape.ne) {
      const {sw, ne} = shape;
      return {kind: 'polygon', ring: [
        [sw.lng, sw.lat], [ne.lng, sw.lat],
        [ne.lng, ne.lat], [sw.lng, ne.lat], [sw.lng, sw.lat]
      ]};
    }
    if (shape.kind === 'poly' && Array.isArray(shape.ring)) {
      return {kind: 'polygon', ring: shape.ring.map(p => [p.lng, p.lat])};
    }
    return shape;
  };
  const originalFetch = window.fetch.bind(window);
  window.fetch = async (input, init) => {
    const url = new URL(typeof input === 'string' || input instanceof URL ? input : input.url, location.href);
    if (url.origin === location.origin && url.pathname === '/api/map/region' &&
        init && typeof init.body === 'string') {
      try {
        const payload = JSON.parse(init.body);
        payload.shape = normalize(payload.shape);
        init = {...init, body: JSON.stringify(payload)};
      } catch (_) {}
    }
    const response = await originalFetch(input, init);
    if (url.origin === location.origin && url.pathname === '/api/me/llm' &&
        ['PUT','DELETE'].includes(init?.method?.toUpperCase()) && response.ok) send({type:'profile'});
    return response;
  };

  const native = (url) => url.origin === location.origin &&
      /^\/(digest|media|telegram)(\/|$)/.test(url.pathname);
  const navigate = (value) => {
    const url = new URL(value, location.href);
    if (native(url) || url.origin !== location.origin) {
      send({type: 'navigate', url: url.href});
      return true;
    }
    return false;
  };
  document.addEventListener('click', (event) => {
    const link = event.target.closest?.('a[href]');
    if (link && navigate(link.href)) {
      event.preventDefault();
      event.stopImmediatePropagation();
    }
  }, true);
  window.open = (url) => { navigate(url); return null; };
  const params = new URL(location.href).searchParams;
  const hidden = new Set((params.get('_mobileHidden') || '').split(',').filter(Boolean));
  let restored = false;
  const locationChanged = () => {
    if (navigate(location.href) || !restored) return;
    const url = new URL(location.href);
    document.querySelectorAll('[data-layer]').forEach(chip => {
      if (chip.classList.contains('crucix-map-legend-chip--off')) hidden.add(chip.dataset.layer);
      else hidden.delete(chip.dataset.layer);
    });
    const time = document.querySelector('.crucix-map-legend-time--on')?.value;
    url.searchParams.set('_mobileHidden', [...hidden].join(','));
    if (time) url.searchParams.set('_mobileTime', time);
    url.searchParams.set('_mobileTheme', localStorage.getItem('crucix_theme') || 'dark');
    send({type: 'location', url: url.href, scroll: window.scrollY});
  };
  const restoreView = () => {
    const legend = document.querySelector('#mapLegend');
    const chips = document.querySelectorAll('[data-layer]');
    if (!legend || !chips.length || restored) return;
    restored = true;
    for (const chip of chips) {
      if (hidden.has(chip.dataset.layer) && !chip.classList.contains('crucix-map-legend-chip--off')) chip.click();
    }
    const time = params.get('_mobileTime');
    document.querySelectorAll('.crucix-map-legend-time').forEach(button => {
      if (button.value === time) button.click();
    });
    setTimeout(() => { window.scrollTo(0, window.__mfbRestoreScroll || 0); locationChanged(); }, 100);
    new MutationObserver(locationChanged).observe(legend, {subtree:true, childList:true, attributes:true, attributeFilter:['class']});
    observer.disconnect();
  };
  const observer = new MutationObserver(restoreView);
  observer.observe(document.body, {subtree:true, childList:true});
  setTimeout(() => observer.disconnect(), 30000);
  restoreView();
  for (const name of ['pushState', 'replaceState']) {
    const original = history[name].bind(history);
    history[name] = (...args) => { original(...args); locationChanged(); };
  }
  window.addEventListener('popstate', locationChanged);
  let timer;
  window.addEventListener('scroll', () => {
    clearTimeout(timer);
    timer = setTimeout(locationChanged, 150);
  }, {passive:true});
  locationChanged();
  send({type:'ready'});
})();
