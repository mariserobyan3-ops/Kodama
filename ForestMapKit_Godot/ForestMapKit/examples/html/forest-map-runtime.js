'use strict';
/* Forest Map Kit - HTML5 canvas runtime (reference implementation of MAP_FORMAT.md, version 2).
   No dependencies. Load a map.json (or a world.json), draw it in layers with depth sorting, test collision, move an actor,
   walk from map to map across the edges. Use it as it is, or read it as the specification for your own engine.

   const kit = ForestMapKit;
   const map = await kit.loadMap('sample/cells/A1/map.json', '../../');     // the map file, and the kit folder (tiles/, overlays/, objects/)
   kit.drawMap(ctx, map, camera, [actor]);                                   // actor: { x, y, r, draw(ctx) }  (x, y = feet, r = body radius)
   kit.move(map, actor, dx, dy);                                             // slides along walls, never enters a blocked polygon
   const world = await kit.loadWorld('sample/world.json', '../../');        // a grid of maps
   const next = kit.travel(world, 'A1', actor);                              // { cell, map } when the actor crossed an edge, else null
*/
const ForestMapKit = (() => {
  const images = new Map();
  function loadImage(url) {
    if (!images.has(url)) images.set(url, new Promise((ok, bad) => { const im = new Image(); im.onload = () => ok(im); im.onerror = () => bad(new Error('missing ' + url)); im.src = url; }));
    return images.get(url);
  }
  const bbox = p => { let x0 = 1e9, y0 = 1e9, x1 = -1e9, y1 = -1e9; for (const [x, y] of p) { if (x < x0) x0 = x; if (y < y0) y0 = y; if (x > x1) x1 = x; if (y > y1) y1 = y; } return [x0, y0, x1, y1]; };
  const inPoly = (x, y, p) => { let yes = false; for (let i = 0, j = p.length - 1; i < p.length; j = i++) if ((p[i][1] > y) !== (p[j][1] > y) && x < (p[j][0] - p[i][0]) * (y - p[i][1]) / (p[j][1] - p[i][1]) + p[i][0]) yes = !yes; return yes; };
  const dirname = url => url.slice(0, url.lastIndexOf('/') + 1);

  // ---- a map: pictures loaded, draw list and collision list prepared
  async function prepare(data, kitBase) {
    if (data.format !== 'forest-map-kit-map') throw new Error('not a Forest Map Kit map file');
    const m = { data, size: data.size[0], under: [], sorted: [], blockers: [], water: [] };
    [m.tile, m.overlay] = await Promise.all([loadImage(kitBase + data.ground.tile), loadImage(kitBase + data.ground.overlay)]);
    const ims = await Promise.all(data.objects.map(o => loadImage(kitBase + o.file)));
    data.objects.forEach((o, i) => {
      const im = ims[i];
      if (o.collision === 'ground') m.under.push({ im, x: o.x, y: o.y, sortY: o.sortY });                    // lying objects: always under actors
      else if (o.pieces && o.pieces.length) for (const p of o.pieces) m.sorted.push({ im, sx: p.srcX, sw: p.srcW, x: p.x, y: o.y, h: o.h, sortY: p.sortY });   // a long object, slice by slice
      else m.sorted.push({ im, x: o.x, y: o.y, sortY: o.sortY });
      for (const poly of [o.feet, ...(o.parts || [])]) if (poly) m.blockers.push({ poly, box: bbox(poly) });
    });
    for (const poly of (data.water && data.water.polygons) || []) { const b = { poly, box: bbox(poly) }; m.water.push(b); m.blockers.push(b); }
    m.sorted.sort((a, b) => a.sortY - b.sortY);
    return m;
  }
  async function loadMap(url, kitBase) { return prepare(await (await fetch(url)).json(), kitBase); }

  // ---- drawing: tile, overlay, lying objects, then standing objects and actors together by their sort line
  function drawMap(ctx, m, cam, actors) {
    ctx.save();
    ctx.imageSmoothingEnabled = false;
    ctx.translate(-Math.round(cam.x), -Math.round(cam.y));
    ctx.drawImage(m.tile, 0, 0, m.size, m.size);
    ctx.drawImage(m.overlay, 0, 0, m.size, m.size);
    for (const e of m.under) ctx.drawImage(e.im, e.x, e.y);
    const items = m.sorted.slice();
    for (const a of actors || []) items.push({ actor: a, sortY: a.y });
    items.sort((a, b) => a.sortY - b.sortY);
    for (const e of items) {
      if (e.actor) e.actor.draw(ctx);
      else if (e.sw !== undefined) ctx.drawImage(e.im, e.sx, 0, e.sw, e.h, e.x, e.y, e.sw, e.h);
      else ctx.drawImage(e.im, e.x, e.y);
    }
    ctx.restore();
  }
  function drawCollision(ctx, m, cam) {           // debug view: blocking polygons (red) and water (cyan)
    ctx.save(); ctx.translate(-Math.round(cam.x), -Math.round(cam.y)); ctx.lineWidth = 2;
    for (const b of m.blockers) {
      const water = m.water.includes(b);
      ctx.fillStyle = water ? 'rgba(40,230,230,.35)' : 'rgba(255,60,40,.3)'; ctx.strokeStyle = water ? '#28e6e6' : '#ff3c28';
      ctx.beginPath(); b.poly.forEach(([x, y], i) => i ? ctx.lineTo(x, y) : ctx.moveTo(x, y)); ctx.closePath(); ctx.fill(); ctx.stroke();
    }
    ctx.restore();
  }

  // ---- collision: the actor is an oval on the ground (radius r, 1.6 x flatter in y, like a top-down body)
  function blocked(m, x, y, r) {
    if (x < r || y < r || x > m.size - r || y > m.size - r) return false;     // the edges are open: travel() decides what happens there
    for (const b of m.blockers) {
      if (x < b.box[0] - r || x > b.box[2] + r || y < b.box[1] - r || y > b.box[3] + r) continue;
      const p = b.poly;
      if (inPoly(x, y, p)) return true;
      for (let i = 0; i < p.length; i++) {
        const a = p[i], q = p[(i + 1) % p.length], dx = q[0] - a[0], dy = (q[1] - a[1]) * 1.6, px = x - a[0], py = (y - a[1]) * 1.6;
        const t = Math.max(0, Math.min(1, (px * dx + py * dy) / (dx * dx + dy * dy || 1)));
        if ((px - t * dx) ** 2 + (py - t * dy) ** 2 < r * r) return true;
      }
    }
    return false;
  }
  function move(m, actor, dx, dy) {               // one axis at a time, so the actor slides along a wall
    if (dx && !blocked(m, actor.x + dx, actor.y, actor.r)) actor.x += dx;
    if (dy && !blocked(m, actor.x, actor.y + dy, actor.r)) actor.y += dy;
  }
  function freeNear(m, x, y, r) {                 // the nearest open spot (to place an actor)
    if (!blocked(m, x, y, r)) return [x, y];
    for (let d = 8; d < 600; d += 8) for (let a = 0; a < 16; a++) { const px = x + Math.cos(a * Math.PI / 8) * d, py = y + Math.sin(a * Math.PI / 8) * d; if (px > r && py > r && px < m.size - r && py < m.size - r && !blocked(m, px, py, r)) return [px, py]; }
    return [x, y];
  }

  // ---- a world: world.json + cells/<name>/map.json, loaded when first entered
  async function loadWorld(url, kitBase) {
    const data = await (await fetch(url)).json();
    if (data.format !== 'forest-map-kit-world') throw new Error('not a Forest Map Kit world file');
    const w = { data, base: dirname(url), kitBase, maps: new Map() };
    w.cell = async name => {
      const c = data.cells[name]; if (!c) return null;
      if (!w.maps.has(name)) w.maps.set(name, loadMap(w.base + c.folder + 'map.json', kitBase));
      return w.maps.get(name);
    };
    return w;
  }
  // The actor left the map across an edge: enter the neighbour at the same place on its opposite edge. A missing neighbour is a wall.
  async function travel(w, cellName, actor) {
    const S = w.data.cellSize, c = w.data.cells[cellName];
    const side = actor.x < 0 ? 'W' : actor.x >= S ? 'E' : actor.y < 0 ? 'N' : actor.y >= S ? 'S' : null;
    if (!side) return null;
    const next = c.neighbours[side];
    if (!next) { actor.x = Math.max(actor.r, Math.min(S - actor.r, actor.x)); actor.y = Math.max(actor.r, Math.min(S - actor.r, actor.y)); return null; }
    const map = await w.cell(next);
    if (side === 'W') actor.x += S; else if (side === 'E') actor.x -= S; else if (side === 'N') actor.y += S; else actor.y -= S;
    if (blocked(map, actor.x, actor.y, actor.r)) [actor.x, actor.y] = freeNear(map, actor.x, actor.y, actor.r);
    return { cell: next, map };
  }

  return { loadImage, loadMap, loadWorld, drawMap, drawCollision, blocked, move, freeNear, travel };
})();
