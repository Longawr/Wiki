/* ============================================================================
   EBF5 Wiki — Logic hiển thị (vanilla JS, không cần thư viện)
   Trang chủ -> index.html | Danh sách -> list.html?type=... | Chi tiết -> detail.html?type=...&id=...
   ============================================================================ */

(function () {
  'use strict';

  const D = window.EBF5DATA;
  const CAT = {};
  D.categories.forEach(function (c) { CAT[c.key] = c; });

  /* ------------------------------ Tiện ích chung --------------------------- */

  function $(sel, root) { return (root || document).querySelector(sel); }

  function esc(s) {
    return String(s == null ? '' : s).replace(/[&<>"\u0027]/g, function (c) {
      return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
    });
  }

  function norm(s) {
    return (s || '').toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd');
  }

  function params() { return new URLSearchParams(location.search); }

  function elOf(id) { return D.elements.find(function (e) { return e.id === id; }); }
  function catOf(key) { return CAT[key]; }
  function list(key) { return D[key] || []; }
  function getOne(key, id) {
    return list(key).find(function (x) { return x.id === id; });
  }
  function typeEx(key) { return key; }

  function hrefTo(key, id) {
    return 'detail.html?type=' + encodeURIComponent(key) + '&id=' + encodeURIComponent(id);
  }
  function hrefList(key) { return 'list.html?type=' + encodeURIComponent(key); }

  function charOf(id) { return getOne('characters', id); }
  function charName(id) { var c = charOf(id); return c ? c.name : ''; }
  function charLink(id) {
    var c = charOf(id);
    return c ? '<a href="' + hrefTo('characters', c.id) + '">' + esc(c.name) + '</a>' : '';
  }

  function elementChips(arr) {
    return (arr || []).map(function (id) {
      var e = elOf(id);
      if (!e) return '';
      return '<span class="chip el" style="background:' + esc(e.color) + '">' +
        '<span class="dot" style="background:rgba(0,0,0,.25)"></span>' +
        esc(e.icon + ' ' + e.name) + '</span>';
    }).join('');
  }
  /* --- Khắc chế của kẻ địch (bảng % từ FoeTableEBF5 trên wiki) ---------------- */
  var RES_LBL = {
    'stun': 'Choáng', 'dispel': 'Dispel',
    'syphon&disable': 'Syphon & Disable', 'chill&freeze': 'Lạnh & Đóng băng',
    'poison&virus': 'Nhiễm độc & Virus', 'weaken&tired': 'Yếu đi & Mỏi',
    'stagger&confuse': 'Chững & Hoang mang', 'death&doom': 'Chết ngay & Doom',
    'burn&scorch': 'Đốt & Xém', 'wet&dry': 'Ướt & Khô', 'heavy&light': 'Nặng & Nhẹ',
    'atkdown': 'Trừ Attack', 'defdown': 'Trừ Defence', 'magdown': 'Trừ Magic Attack',
    'mdedown': 'Trừ Magic Defence', 'accdown': 'Trừ Chính xác', 'evadown': 'Trừ Né',
    'hpdown': 'Trừ Max HP'
  };

  function resLabel(k) {
    if (RES_LBL[k]) return RES_LBL[k];
    var e = elOf(k);
    return e ? e.name : k;
  }

  function resPct(v) {
    if (v >= 200) return 'hấp thụ';
    if (v >= 100) return '0% sát thương';
    if (v > 0)    return '−' + v + '% sát thương';
    if (v < 0)    return '+' + (-v) + '% sát thương';
    return '';
  }

  function resRow(label, keys, res) {
    if (!keys.length) return '';
    var cells = keys.map(function (k) {
      var v = res[k];
      var e = elOf(k);
      var icon = e ? '<span class="dot" style="background:rgba(0,0,0,.25)"></span>' : '';
      var cls = 'chip';
      if (e) cls += ' el';
      var style = e ? ' style="background:' + esc(e.color) + '"' : '';
      return '<span class="' + cls + '"' + style + '>' + icon + esc(resLabel(k) + ' — ' + resPct(v)) + '</span>';
    }).join(' ');
    return '<tr><th>' + label + '</th><td>' + cells + '</td></tr>';
  }

  function resTable(res) {
    if (!res) return '<p class="muted">Không có dữ liệu khắc chế trên wiki.</p>';
    var keys = Object.keys(res);
    var weak = [], resist = [], immune = [], absorb = [];
    keys.sort(function (a, b) {
      var ea = elOf(a) ? 0 : 1, eb = elOf(b) ? 0 : 1;
      if (ea !== eb) return ea - eb;
      return res[b] - res[a];
    });
    keys.forEach(function (k) {
      var v = res[k];
      if (v >= 200)      absorb.push(k);
      else if (v >= 100) immune.push(k);
      else if (v > 0)    resist.push(k);
      else if (v < 0)    weak.push(k);
    });
    var rows =
      resRow('Yếu', weak, res) +
      resRow('Kháng', resist, res) +
      resRow('Miễn', immune, res) +
      resRow('Hấp thụ', absorb, res);
    if (!rows) return '<p class="muted">Cân bằng với mọi nguyên tố — không có điểm yếu/kháng nổi bật theo wiki.</p>';
    return '<table class="data-table res-table"><tbody>' + rows + '</tbody></table>' +
      '<p class="muted res-note">Số % lấy từ bảng FoeTableEBF5 của wiki: phần trăm kháng (dương) giảm sát thương, phần trăm âm tăng sát thương nhận vào, 200% là hấp thụ (chữa HP).</p>';
  }

  function kindChip(kind) {
    return kind ? '<span class="chip">' + esc(kind) + '</span>' : '';
  }

  /* ---------------------------- Tiêu đề phụ của card ----------------------- */

  function slotChip(slot) {
    return slot ? '<span class="chip">' + esc(slot) + '</span>' : '';
  }

  function cardSub(item, key) {
    if (key === 'characters') return kindChip(item.kind) + elementChips(item.elements);
    if (key === 'enemies')    return kindChip(item.kind) + elementChips(item.elements);
    if (key === 'skills')     return item.user ? kindChip(item.kind) + charChip(item.user) : kindChip(item.kind);
    if (key === 'items')      return kindChip(item.kind) + elementChips(item.elements);
    if (key === 'equipment')  return item.forChar ? kindChip(item.kind) + slotChip(item.slot) + charChip(item.forChar)
                                                   : kindChip(item.kind) + slotChip(item.slot);
    if (key === 'statuses')   return kindChip(item.kind) + elementChips(item.elements);
    if (key === 'areas')      return kindChip(item.kind) + (item.grid ? '<span class="chip">Ô ' + esc(item.grid) + '</span>' : '');
    if (key === 'summons')    return kindChip(item.kind) + (item.sp ? '<span class="chip">SP ' + esc(item.sp) + '</span>' : '') + elementChips(item.elements);
    if (key === 'limits')     return kindChip(item.kind) + (item.chars || []).map(charChip).join('') + elementChips(item.elements);
    return '';
  }

  function charChip(id) {
    var c = charOf(id);
    return c ? '<span class="chip">🧙 ' + esc(c.name) + '</span>' : '';
  }

  /* ------------------- Đoạn văn có tooltip trạng thái ---------------------- */

  // Bảng tra tên trạng thái -> mục (cache 1 lần).
  function stMap() {
    if (!stMap.cache) {
      stMap.cache = {};
      list('statuses').forEach(function (s) { stMap.cache[s.name] = s; });
    }
    return stMap.cache;
  }

  // Nhận văn bản ĐÃ esc(), bọc tên trạng thái bằng span tooltip.
  // Chỉ dùng cho trang chi tiết; card grid giữ esc() thuần cho nhẹ.
  function withStatusTips(text) {
    var map = stMap();
    var names = Object.keys(map).sort(function (a, b) { return b.length - a.length; });
    names.forEach(function (n) {
      var en = esc(n);
      if (text.indexOf(en) === -1) return;
      text = text.split(en).join(
        '<span class="st-tip" tabindex="0" data-st="' + esc(map[n].id) + '">' + en + '</span>'
      );
    });
    return text;
  }

  function txt(s) { return withStatusTips(esc(s)); }

  /* ------------------- Chrome dùng chung: lên đầu trang -------------------- */

  function initToTop() {
    if (document.getElementById('toTop')) return;
    var btn = document.createElement('button');
    btn.id = 'toTop';
    btn.className = 'to-top';
    btn.type = 'button';
    btn.setAttribute('aria-label', 'Quay lại đầu trang');
    btn.textContent = '↑ Đầu trang';
    document.body.appendChild(btn);
    btn.addEventListener('click', function () {
      window.scrollTo({ top: 0, behavior: 'smooth' });
    });
    window.addEventListener('scroll', function () {
      btn.classList.toggle('show', window.scrollY > 400);
    }, { passive: true });
  }

  /* ------------------------- Lightbox xem ảnh full ------------------------- */

  var lbEl = null, lbIsOpen = false;

  function initLightbox() {
    if (lbEl) return;
    lbEl = document.createElement('div');
    lbEl.id = 'lightbox';
    lbEl.className = 'lightbox hidden';
    lbEl.innerHTML =
      '<button class="lightbox-close" type="button" aria-label="Đóng (Esc)">✕</button>' +
      '<img alt="" />' +
      '<p class="lightbox-cap"></p>';
    document.body.appendChild(lbEl);

    function close() {
      lbEl.classList.add('hidden');
      document.body.classList.remove('no-scroll');
      lbIsOpen = false;
    }
    lbEl.addEventListener('click', function (e) {
      if (e.target === lbEl || e.target.classList.contains('lightbox-close')) close();
    });
    lbEl._close = close;
  }

  function openLightbox(src, cap) {
    initLightbox();
    lbEl.querySelector('img').src = src;
    lbEl.querySelector('.lightbox-cap').textContent = cap || '';
    lbEl.classList.remove('hidden');
    document.body.classList.add('no-scroll');
    lbIsOpen = true;
  }

  function closeLightbox() {
    if (lbIsOpen && lbEl) lbEl._close();
  }

  /* -------------------- Tooltip cho tên trạng thái (hover) ----------------- */

  var tipEl = null;

  function initStatusTip() {
    if (tipEl) return;
    tipEl = document.createElement('div');
    tipEl.id = 'statusTip';
    tipEl.className = 'status-tip hidden';
    document.body.appendChild(tipEl);

    function show(target) {
      var st = getOne('statuses', target.getAttribute('data-st'));
      if (!st) return;
      var img = st.image
        ? '<img src="' + esc(st.image) + '" alt="" onerror="this.style.display=\'none\'">'
        : '';
      tipEl.innerHTML =
        '<div class="st-tip-head">' + img +
          '<div><strong>' + esc(st.name) + '</strong>' +
          '<div class="muted small">' + esc(st.kind) + '</div></div>' +
        '</div>' +
        '<div class="st-tip-body">' + esc((st.desc || '').slice(0, 160)) +
          ((st.desc || '').length > 160 ? '…' : '') +
          '<div class="small" style="margin-top:4px">Nhấp để xem chi tiết →</div>' +
        '</div>';
      tipEl.classList.remove('hidden');

      // Đặt vị trí: ưu tiên bên trên mục tiêu, lật xuống nếu chạm mép màn hình.
      var r = target.getBoundingClientRect();
      tipEl.style.visibility = 'hidden';
      tipEl.classList.remove('flip');
      requestAnimationFrame(function () {
        var w = tipEl.offsetWidth, h = tipEl.offsetHeight;
        var left = Math.min(Math.max(8, r.left + r.width / 2 - w / 2), window.innerWidth - w - 8);
        var top = r.top - h - 8;
        if (top < 60) { top = r.bottom + 8; tipEl.classList.add('flip'); }
        tipEl.style.left = left + 'px';
        tipEl.style.top = top + 'px';
        tipEl.style.visibility = '';
      });
    }
    function hide() { tipEl.classList.add('hidden'); }

    document.addEventListener('mouseover', function (e) {
      var t = e.target.closest('.st-tip');
      if (t) show(t); else hide();
    });
    document.addEventListener('focusin', function (e) {
      var t = e.target.closest && e.target.closest('.st-tip');
      if (t) show(t);
    });
    document.addEventListener('focusout', function () { hide(); });
    document.addEventListener('scroll', hide, { passive: true });
    document.addEventListener('click', function (e) {
      var t = e.target.closest && e.target.closest('.st-tip');
      if (!t) return;
      var st = getOne('statuses', t.getAttribute('data-st'));
      if (st) location.href = hrefTo('statuses', st.id);
    });
  }

  /* ---------------------- Tìm kiếm sâu (mọi trường) ------------------------ */

  // Gộp mọi trường text của mục thành 1 chuỗi đã bỏ dấu để filter.
  function searchText(catKey, item) {
    var parts = [item.name, item.desc, item.kind];
    if (item.effect) parts.push(item.effect);
    if (item.unlock) parts.push(item.unlock);
    if (item.slot) parts.push(item.slot);
    ['tips', 'features', 'strengths', 'weaknesses', 'drops'].forEach(function (f) {
      if (Array.isArray(item[f])) parts.push(item[f].join(' '));
    });
    if (catKey === 'characters' && Array.isArray(item.skills)) {
      item.skills.forEach(function (s) { parts.push(s.name, s.desc || ''); });
    }
    if (catKey === 'areas' && Array.isArray(item.cells)) {
      item.cells.forEach(function (c) {
        parts.push('Ô ' + c.grid, (c.foes || []).join(' '), (c.keys || []).join(' '), (c.notes || []).join(' '));
      });
    }
    if (catKey === 'skills' && item.user) parts.push(charName(item.user));
    return norm(parts.join(' '));
  }

  function cardFor(key, item) {
    var sub = cardSub(item, key);
    var img = item.image
      ? '<img class="card-img" src="' + esc(item.image) + '" alt="' + esc(item.name) + '" loading="lazy" onerror="this.classList.add(\'img-fail\')">'
      : '';
    return '' +
      '<a class="card" href="' + hrefTo(key, item.id) + '">' +
        '<div class="card-top">' +
          (item.icon ? '<span class="card-icon">' + esc(item.icon) + '</span>' : '') +
          '<span class="card-title">' + esc(item.name) + '</span>' +
        '</div>' +
        img +
        '<div class="chip-row">' + sub + '</div>' +
        '<div class="card-desc">' + esc(item.desc || '') + '</div>' +
      '</a>';
  }

  /* ------------------------------ Menu điều hướng --------------------------- */

  function renderNav(activeKey) {
    var el = $('#mainNav');
    if (!el) return;
    el.innerHTML = D.categories.map(function (c) {
      var cls = (c.key === activeKey) ? 'active' : '';
      return '<a href="' + hrefList(c.key) + '" class="' + cls + '">' +
        esc(c.icon + ' ' + c.title) + '</a>';
    }).join('');
  }

  function appInit(activeKey) { renderNav(activeKey); }

  /* ---------------------------------- Trang chủ ----------------------------- */

  function renderHome() {
    appInit(null);

    var catBox = $('#homeCategories');
    if (catBox) {
      catBox.innerHTML = D.categories.map(function (c) {
        var count = list(c.key).length;
        return '<a class="card" href="' + hrefList(c.key) + '">' +
          '<div class="card-top">' +
            '<span class="card-icon">' + esc(c.icon) + '</span>' +
            '<span class="card-title">' + esc(c.title) + '</span>' +
            '<span class="card-count">' + count + ' mục</span>' +
          '</div>' +
          '<div class="card-desc">' + esc(c.desc) + '</div>' +
        '</a>';
      }).join('');
    }

    var charBox = $('#homeCharacters');
    if (charBox) {
      charBox.innerHTML = list('characters').map(function (ch) {
        return cardFor('characters', ch);
      }).join('');
    }

    var elBox = $('#homeElements');
    if (elBox) {
      elBox.innerHTML = D.elements.map(function (e) {
        return '<div class="panel chip-row"><span class="chip el" style="background:' + esc(e.color) + '">' +
          esc(e.icon + ' ' + e.name) + '</span></div>';
      }).join('');
    }

    var input = $('#homeSearch'), btn = $('#homeSearchBtn');
    function go() {
      location.href = 'list.html?type=all&q=' + encodeURIComponent(input.value.trim());
    }
    if (btn) btn.addEventListener('click', go);
    if (input) input.addEventListener('keydown', function (e) { if (e.key === 'Enter') go(); });
  }

  /* ------------------------------------ Danh sách ---------------------------- */

  function renderList() {
    var p = params();
    var key = p.get('type') || 'characters';
    var cat = CAT[key];
    if (!cat && key !== 'all') { location.href = hrefList('characters'); return; }

    appInit(key === 'all' ? null : key);

    var isAll = (key === 'all');
    var title = isAll ? 'Kết quả tìm kiếm' : cat.title;
    var desc  = isAll ? 'Tìm kiếm trên toàn bộ wiki.' : cat.desc;

    $('#listTitle').textContent = title;
    $('#listDesc').textContent = desc;
    $('#breadcrumb').innerHTML =
      '<a href="index.html">Trang chủ</a> / ' + esc(title);

    /* Danh sách cần hiển thị: 1 chủ đề hoặc tất cả */
    var entries = isAll
      ? D.categories.reduce(function (acc, c) {
          return acc.concat(list(c.key).map(function (item) {
            return { item: item, catKey: c.key };
          }));
        }, [])
      : list(key).map(function (item) { return { item: item, catKey: key }; });

    /* Bộ lọc theo loại (kinds) — chỉ hiện khi có dữ liệu kinds */
    var kindSel = $('#filterKind');
    var kinds = isAll ? [] : (cat.kinds || []);
    if (kinds.length) {
      kinds.forEach(function (k) {
        var o = document.createElement('option');
        o.value = k; o.textContent = k;
        kindSel.appendChild(o);
      });
    } else {
      kindSel.classList.add('hidden');
    }

    var elSel = $('#filterElement');
    D.elements.forEach(function (e) {
      var o = document.createElement('option');
      o.value = e.id; o.textContent = e.icon + ' ' + e.name;
      elSel.appendChild(o);
    });

    /* Đồng bộ từ URL xuống bộ lọc */
    var fSearch = $('#filterSearch');
    fSearch.value = p.get('q') || '';
    if (elSel.querySelector('option[value="' + (p.get('element') || '') + '"]')) {
      elSel.value = p.get('element');
    }
    if (kindSel.querySelector('option[value="' + (p.get('kind') || '') + '"]')) {
      kindSel.value = p.get('kind');
    }

    function drawBox() {
      var q = norm(fSearch.value.trim());
      var fe = elSel.value;
      var fk = kindSel.value;

      var out = entries.filter(function (ent) {
        var it = ent.item;
        if (fe && !(it.elements || []).includes(fe)) return false;
        if (fk && it.kind !== fk) return false;
        if (q && searchText(ent.catKey, it).indexOf(q) === -1) return false;
        return true;
      });

      var box = $('#listResult'), empty = $('#listEmpty');
      box.innerHTML = out.map(function (ent) { return cardFor(ent.catKey, ent.item); }).join('');
      empty.classList.toggle('hidden', out.length > 0);
    }

    function sync() {
      var u = new URLSearchParams();
      if (fSearch.value.trim()) u.set('q', fSearch.value.trim());
      if (elSel.value) u.set('element', elSel.value);
      if (kindSel.value && !kindSel.classList.contains('hidden')) u.set('kind', kindSel.value);
      var newUrl = location.pathname + '?type=' + encodeURIComponent(key) +
        (u.toString() ? '&' + u.toString() : '');
      history.replaceState({}, '', newUrl);
      drawBox();
    }

    fSearch.addEventListener('input', sync);
    elSel.addEventListener('change', sync);
    kindSel.addEventListener('change', sync);
    $('#filterReset').addEventListener('click', function () {
      fSearch.value = ''; elSel.value = ''; kindSel.value = ''; sync();
    });

    drawBox();
  }

  /* ------------------------------------- Chi tiết ---------------------------- */

  function renderDetail() {
    var p = params();
    var key = p.get('type') || 'characters';
    var id = p.get('id') || '';
    var cat = CAT[key];
    var item = cat ? getOne(key, id) : null;

    appInit(key);

    if (!item) { $('#detailEmpty').classList.remove('hidden'); return; }

    document.title = item.name + ' — EBF5 Wiki';
    $('#breadcrumb').innerHTML =
      '<a href="index.html">Trang chủ</a> / ' +
      '<a href="' + hrefList(key) + '">' + esc(cat.title) + '</a> / ' +
      '<span>' + esc(item.name) + '</span>';

    var chips = kindChip(item.kind) + elementChips(item.elements);
    var media = item.image
      ? '<div class="detail-media" title="Nhấp vào ảnh để phóng to"><img src="' + esc(item.image) + '" alt="' + esc(item.name) + '" onerror="this.classList.add(\'img-fail\')"></div>'
      : '';
    var html = '' +
      '<section class="detail-head">' +
        '<div class="detail-head-row">' +
          '<div>' +
            (item.icon ? '<div class="card-icon" style="font-size:2.2rem">' + esc(item.icon) + '</div>' : '') +
            '<h1>' + esc(item.name) + '</h1>' +
            '<div class="chip-row">' + chips + '</div>' +
            '<p class="muted" style="margin:10px 0 0">' + txt(item.desc || '') + '</p>' +
          '</div>' +
          media +
        '</div>' +
      '</section>' +
      '<section class="detail-body">';

    /* ----- Nhân vật ----- */
    if (key === 'characters') {
      html +=
        '<div class="two-col">' +
          '<div class="panel"><h3>Điểm mạnh</h3><ul class="clean good">' +
            (item.strengths || []).map(function (s) { return '<li>' + txt(s) + '</li>'; }).join('') +
          '</ul></div>' +
          '<div class="panel"><h3>Điểm yếu</h3><ul class="clean bad">' +
            (item.weaknesses || []).map(function (s) { return '<li>' + txt(s) + '</li>'; }).join('') +
          '</ul></div>' +
        '</div>' +
        '<div class="panel"><h3>Kỹ năng nổi bật</h3>' + skillsTable(item.skills) + '</div>' +
        '<div class="panel"><h3>Gợi ý chơi</h3><ul class="clean tips">' +
          (item.tips || []).map(function (s) { return '<li>' + txt(s) + '</li>'; }).join('') +
        '</ul></div>';
    }

    /* ----- Kẻ địch ----- */
    if (key === 'enemies') {
      html +=
        '<div class="panel"><h3>Khắc chế nguyên tố & trạng thái</h3>' + resTable(item.res) + '</div>' +
        '<div class="two-col">' +
          '<div class="panel"><h3>Vật phẩm rơi (mẫu)</h3><ul class="clean">' +
            (item.drops || []).map(function (s) { return '<li>' + txt(s) + '</li>'; }).join('') +
          '</ul></div>' +
          '<div class="panel"><h3>Mẹo đối phó</h3><ul class="clean tips">' +
            (item.tips || []).map(function (s) { return '<li>' + txt(s) + '</li>'; }).join('') +
          '</ul></div>' +
        '</div>';
    }

    /* ----- Kỹ năng ----- */
    if (key === 'skills') {
      html +=
        '<div class="panel"><h3>Thông tin</h3>' +
          '<table class="data-table"><tbody>' +
            '<tr><td>Người dùng</td><td>' + (item.user ? charLink(item.user) : 'Dùng chung') + '</td></tr>' +
            '<tr><td>Loại</td><td>' + esc(item.kind || '') + '</td></tr>' +
            '<tr><td>Nguyên tố</td><td>' + elementChips([item.element]) + '</td></tr>' +
          '</tbody></table>' +
        '</div>';
    }

    /* ----- Vật phẩm ----- */
    if (key === 'items') {
      html +=
        '<div class="panel"><h3>Thông tin</h3>' +
          '<table class="data-table"><tbody>' +
            '<tr><td>Loại</td><td>' + esc(item.kind || '') + '</td></tr>' +
            '<tr><td>Hiệu quả</td><td>' + txt(item.effect || '') + '</td></tr>' +
            '<tr><td>Nguyên tố</td><td>' + elementChips(item.elements) + '</td></tr>' +
          '</tbody></table>' +
        '</div>';
    }

    /* ----- Trang bị ----- */
    if (key === 'equipment') {
      html +=
        '<div class="panel"><h3>Thông tin</h3>' +
          '<table class="data-table"><tbody>' +
            '<tr><td>Dành cho</td><td>' + (item.forChar ? charLink(item.forChar) : 'Dùng chung') + '</td></tr>' +
            '<tr><td>Loại</td><td>' + esc(item.kind || '') + '</td></tr>' +
            '<tr><td>Vị trí</td><td>' + esc(item.slot || '') + '</td></tr>' +
            '<tr><td>Hiệu quả</td><td>' + txt(item.effect || '') + '</td></tr>' +
            '<tr><td>Nguyên tố</td><td>' + elementChips(item.elements) + '</td></tr>' +
          '</tbody></table>' +
        '</div>';
    }

    /* ----- Khu vực ----- */
    if (key === 'areas') {
      html +=
        '<div class="panel"><h3>Thông tin</h3>' +
          '<table class="data-table"><tbody>' +
            '<tr><td>Loại</td><td>' + esc(item.kind || '') + '</td></tr>' +
            '<tr><td>Lưới bản đồ</td><td>Ô ' + esc(item.grid || '?') + '</td></tr>' +
          '</tbody></table>' +
        '</div>' +
        '<div class="two-col">' +
          '<div class="panel"><h3>Điểm nhấn</h3><ul class="clean good">' +
            (item.features || []).map(function (s) { return '<li>' + txt(s) + '</li>'; }).join('') +
          '</ul></div>' +
          '<div class="panel"><h3>Lưu ý khi qua khu</h3><ul class="clean tips">' +
            (item.tips || []).map(function (s) { return '<li>' + txt(s) + '</li>'; }).join('') +
          '</ul></div>' +
        '</div>' +
        ((item.cells || []).length ?
          '<div class="panel"><h3>Ô lưới — Quái và Key Items</h3><table class="data-table"><tbody>' +
            item.cells.map(function (c) {
              var rows = '';
              (c.foes || []).forEach(function (s) { rows += '<li>' + txt(s) + '</li>'; });
              var foesHtml = rows ? '<ul class="clean">' + rows + '</ul>' : '<span class="muted">—</span>';
              var rowsK = '';
              (c.keys || []).forEach(function (s) { rowsK += '<li>' + txt(s) + '</li>'; });
              var keysHtml = rowsK ? '<ul class="clean">' + rowsK + '</ul>' : '<span class="muted">—</span>';
              var notesHtml = (c.notes || []).map(function (s) { return '<p class="muted" style="margin:4px 0">' + txt(s) + '</p>'; }).join('') +
                (c.subs ? '<p class="muted" style="margin:4px 0">Vị trí con: ' + esc(c.subs) + '</p>' : '');
              return '<tr><td style="white-space:nowrap"><strong>Ô ' + esc(c.grid) + '</strong></td>' +
                '<td>' + foesHtml + '<hr style="border:none;border-top:1px solid #eee;margin:6px 0">' +
                '<div>' + keysHtml + '</div>' + notesHtml + '</td></tr>';
            }).join('') +
          '</tbody></table></div>' : '');
    }

    /* ----- Triệu hồi ----- */
    if (key === 'summons') {
      html +=
        '<div class="panel"><h3>Thông tin</h3>' +
          '<table class="data-table"><tbody>' +
            '<tr><td>Loại</td><td>' + esc(item.kind || '') + '</td></tr>' +
            '<tr><td>SP tiêu hao</td><td>' + esc(item.sp || '?') + '</td></tr>' +
            '<tr><td>Nguyên tố</td><td>' + elementChips(item.elements) + '</td></tr>' +
            '<tr><td>Mở khoá</td><td>' + txt(item.unlock || 'Bắt quái tương ứng (Capture) để mở khoá.') + '</td></tr>' +
          '</tbody></table>' +
        '</div>';
    }

    /* ----- Limit Break ----- */
    if (key === 'limits') {
      html +=
        '<div class="panel"><h3>Thông tin</h3>' +
          '<table class="data-table"><tbody>' +
            '<tr><td>Loại</td><td>' + esc(item.kind || '') + '</td></tr>' +
            '<tr><td>Nhân vật</td><td>' + (item.chars || []).map(charLink).join(', ') + '</td></tr>' +
            '<tr><td>Nguyên tố</td><td>' + elementChips(item.elements) + '</td></tr>' +
          '</tbody></table>' +
        '</div>';
    }

    /* ----- Ghi chú nguồn ----- */
    html +=
      '<div class="panel' + (key === 'statuses' ? '"><h3>Về trạng thái này</h3>' : '"><h3>Nguồn dữ liệu</h3>') +
        '<p class="muted" style="margin:0">Nội dung đối chiếu theo Epic Battle Fantasy Wiki chính thức tại' +
        ' <a href="' + esc(D.externalWiki) + '" target="_blank" rel="noopener">epicbattlefantasy.fandom.com</a>' +
        (key === 'areas' ? ' — xem trang <em>Epic Battle Fantasy 5 Map</em> để tra từng ô lưới chi tiết (quái, Key Items, rương).' : '') +
        (key === 'summons' ? ' — xem trang <em>Summons/Epic Battle Fantasy 5</em> để xem toàn bộ hơn 190 summon, giá SP và điều kiện mở khoá.' : '') +
        (key === 'limits' ? ' — xem trang <em>Limit Break</em> để đối chiếu nhiệm vụ mở khoá từng skill (một số chỉ có ở v2).' : '') +
        '. Muốn bổ sung, sửa trực tiếp trong <code>js/data.js</code>.</p>' +
      '</div>';

    html += '</section>';
    $('#detailContent').innerHTML = html;

    /* Kỹ năng liên quan — nếu là kỹ năng có user, gợi ý kỹ năng khác cùng user */
    if (key === 'skills' && item.user) {
      var related = list('skills').filter(function (s) {
        return s.user === item.user && s.id !== item.id;
      });
      if (related.length) {
        var holder = document.createElement('section');
        holder.className = 'section';
        holder.innerHTML = '<h2>Xem thêm</h2><div class="card-grid">' +
          related.map(function (s) { return cardFor(key, s); }).join('') + '</div>';
        $('#detailContent').appendChild(holder);
      }
    }

    /* ----- UI polish: lightbox ảnh, lên đầu trang, phím tắt, mục trước/sau ---- */

    initToTop();
    initStatusTip();

    var mediaImg = $('#detailContent .detail-media img');
    if (mediaImg) mediaImg.addEventListener('click', function () {
      openLightbox(mediaImg.src, item.name + ' — ' + cat.title);
    });

    /* Điều hướng mục trước / sau trong cùng chủ đề */
    var seq = list(key);
    var idx = -1;
    seq.forEach(function (x, i) { if (x.id === item.id) idx = i; });
    var prev = idx > 0 ? seq[idx - 1] : null;
    var next = idx > -1 && idx < seq.length - 1 ? seq[idx + 1] : null;

    var navRow = document.createElement('div');
    navRow.className = 'prev-next';
    navRow.innerHTML =
      (prev ? '<a class="btn" href="' + hrefTo(key, prev.id) + '">‹ ' + esc(prev.name) + '</a>'
            : '<span></span>') +
      '<a class="btn" href="' + hrefList(key) + '">☰ ' + esc(cat.title) + '</a>' +
      (next ? '<a class="btn" href="' + hrefTo(key, next.id) + '">' + esc(next.name) + ' ›</a>'
            : '<span></span>');
    $('#detailContent').appendChild(navRow);

    /* Phím tắt: ← mục trước, → mục sau, Esc về danh sách (Esc ưu tiên đóng lightbox) */
    document.addEventListener('keydown', function (e) {
      var tag = e.target && e.target.tagName;
      if (tag === 'INPUT' || tag === 'TEXTAREA' || tag === 'SELECT') return;
      if (lbIsOpen) {
        if (e.key === 'Escape') closeLightbox();
        return;
      }
      if (e.key === 'ArrowLeft' && prev) location.href = hrefTo(key, prev.id);
      else if (e.key === 'ArrowRight' && next) location.href = hrefTo(key, next.id);
      else if (e.key === 'Escape') location.href = hrefList(key);
    });
  }

  function skillsTable(rows) {
    if (!rows || !rows.length) return '<p class="muted">Chưa có kỹ năng nào — bạn hãy bổ sung trong <code>js/data.js</code>.</p>';
    return '' +
      '<table class="data-table">' +
        '<thead><tr><th>Tên</th><th>Loại</th><th>Nguyên tố</th><th>Mô tả</th></tr></thead>' +
        '<tbody>' + rows.map(function (s) {
          return '<tr><td>' + esc(s.name) + '</td><td>' + esc(s.kind || '') + '</td>' +
            '<td>' + elementChips([s.element]) + '</td><td>' + txt(s.desc || '') + '</td></tr>';
        }).join('') + '</tbody>' +
      '</table>';
  }

  /* --------------------------------- Xuất API ------------------------------- */

  window.EBF5App = {
    renderHome: renderHome,
    renderList: renderList,
    renderDetail: renderDetail
  };
})();
