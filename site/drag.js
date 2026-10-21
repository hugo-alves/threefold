// The web preview is a small phone inside a page: use its rendered size,
// rather than the native app's full-screen travel distances.
export function defaultTouchMode(maxTouchPoints, coarsePointer, requested) {
  if (requested === '1' || requested === '3') return Number(requested);
  return maxTouchPoints >= 3 && coarsePointer ? 3 : 1;
}

export function dragSettings(width, height) {
  return {
    travel: Math.min(height * .5, Math.max(120, width * .7)),
    switchDistance: Math.max(36, Math.min(60, width * .16)),
    overviewStart: Math.max(48, Math.min(72, width * .22)),
    overviewEnd: Math.max(100, Math.min(150, width * .48)),
    pause: 200,
  };
}

export function dragOutcome({distance, velocity, heldFor}, settings) {
  const amount = Math.abs(distance);
  if (distance * velocity < 0 && Math.abs(velocity) > 160) return 'cancel';
  if (amount >= settings.overviewStart && amount <= settings.overviewEnd && heldFor >= settings.pause) return 'overview';
  if (amount >= settings.switchDistance || (amount > 20 && Math.abs(velocity) > 500 && distance * velocity > 0)) return 'switch';
  return 'cancel';
}

export class PreviewDrag {
  constructor(y, time) {
    this.origin = y;
    this.distance = 0;
    this.restY = y;
    this.movedAt = time;
    this.samples = [{y, time}];
  }
  move(y, time) {
    this.distance = y - this.origin;
    // A little fingertip jitter should not reset a deliberate pause.
    if (Math.abs(y - this.restY) > 4) { this.restY = y; this.movedAt = time; }
    this.samples.push({y, time});
    while (this.samples.length > 2 && this.samples[1].time < time - 100) this.samples.shift();
  }
  sample(time) {
    const first = this.samples[0], last = this.samples.at(-1);
    const velocity = time - this.movedAt >= 100 ? 0 : (last.y - first.y) / Math.max(1, last.time - first.time) * 1000;
    return {distance: this.distance, velocity, heldFor: time - this.movedAt};
  }
}
