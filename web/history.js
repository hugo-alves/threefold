export class SessionHistory {
  constructor(ids) { this.entries = [...ids]; this.cursor = ids.length - 1; }
  get current() { return this.entries[this.cursor]; }
  destination(direction) { return this.entries[this.cursor + direction]; }
  move(direction) { if (this.destination(direction) !== undefined) this.cursor += direction; }
  select(index) { if (Number.isInteger(index) && index >= 0 && index < this.entries.length) this.cursor = index; }
  visit(id) {
    if (id === this.current) return;
    this.entries = [...this.entries.slice(0, this.cursor + 1), id];
    this.cursor = this.entries.length - 1;
  }
}

export const defaultSettings = Object.freeze({swipeDistance:96, flickSensitivity:1, overviewDistance:145, overviewReleaseSpeed:420, cardScale:.72, cardSpacing:28});

export function historyStep(distance) { return distance < 0 ? 1 : distance > 0 ? -1 : 0; }

export function shouldOpenOverview(distance, velocity, height, settings=defaultSettings) {
  return Math.abs(distance) >= Math.min(settings.overviewDistance, height * .45) * .75
    && Math.abs(distance) < height * .72 && Math.abs(velocity) <= settings.overviewReleaseSpeed
    && !(distance * velocity < 0 && Math.abs(velocity) > 160);
}

export function cardScaleAt(distance, height, settings=defaultSettings) {
  const travel = height + settings.cardSpacing;
  const peak = Math.min(settings.overviewDistance, travel * .45);
  const d = Math.abs(distance);
  const progress = d <= peak ? d / peak : Math.max(0, (travel - d) / (travel - peak));
  return 1 - (1 - settings.cardScale) * progress;
}

export function shouldCommit(distance, velocity, height, settings=defaultSettings) {
  if (distance * velocity < 0 && Math.abs(velocity) > 160) return false;
  return Math.abs(distance) >= Math.min(settings.swipeDistance, height * .22) ||
    (Math.abs(distance) > 24 && Math.abs(velocity) > 650 / settings.flickSensitivity && distance * velocity > 0);
}

// A touch-count gate: one/two/four fingers never enter the history interaction.
export class ThreeFingerGesture {
  constructor(callbacks) { this.callbacks = callbacks; this.reset(); }
  reset() { this.active = false; this.blocked = false; this.axis = null; this.origins = new Map(); this.samples = []; this.dy = 0; }
  start(points, time) {
    if (points.length > 3) { this.cancel(); this.blocked = true; return false; }
    if (this.active || this.blocked || points.length !== 3) return this.active;
    this.active = true;
    this.axis = null;
    this.dy = 0;
    this.origins = new Map(points.map(p => [p.id, p]));
    this.samples = [{ y: 0, time }];
    if (this.callbacks.begin() === false) { this.reset(); this.blocked = true; return false; }
    return true;
  }
  move(points, time) {
    if (!this.active) return false;
    if (points.length !== 3 || points.some(p => !this.origins.has(p.id))) { this.cancel(); return true; }
    const xs = points.map(p => p.x - this.origins.get(p.id).x);
    const ys = points.map(p => p.y - this.origins.get(p.id).y);
    const dx = xs.reduce((a, b) => a + b) / 3;
    const dy = ys.reduce((a, b) => a + b) / 3;
    if (!this.axis && Math.hypot(dx, dy) < 10) return true;
    if (!this.axis) {
      if (Math.abs(dy) <= Math.abs(dx) * 1.2) { this.cancel(); return true; }
      this.axis = 'vertical';
    }
    if (Math.max(...ys) - Math.min(...ys) > Math.max(36, Math.abs(dy) * .7)) { this.cancel(); return true; }
    this.dy = dy;
    this.samples.push({ y: dy, time });
    while (this.samples.length > 2 && this.samples[1].time < time - 100) this.samples.shift();
    this.callbacks.move(dy);
    return true;
  }
  end(points, time) {
    if (this.active && points.length < 3) {
      const first = this.samples[0];
      const last = this.samples.at(-1);
      const velocity = time - last.time > 100 ? 0 : (last.y - first.y) / Math.max(1, last.time - first.time) * 1000;
      this.callbacks.end(this.dy, this.axis ? velocity : 0, !this.axis);
      this.active = false;
      this.blocked = true;
    }
    if (points.length === 0) this.reset();
  }
  cancel() {
    if (this.active) this.callbacks.end(this.dy, 0, true);
    this.active = false;
    this.blocked = true;
  }
}
