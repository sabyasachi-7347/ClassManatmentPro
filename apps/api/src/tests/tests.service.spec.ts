import { rankOf, shortName } from './tests.service';

describe('rankOf', () => {
  it('ranks highest first', () => {
    const r = rankOf({ a: 50, b: 80, c: 65 });
    expect([r.get('b'), r.get('c'), r.get('a')]).toEqual([1, 2, 3]);
  });

  it('gives ties the same rank and skips the next', () => {
    const r = rankOf({ a: 90, b: 75, c: 75, d: 60 });
    expect([r.get('a'), r.get('b'), r.get('c'), r.get('d')]).toEqual([1, 2, 2, 4]);
  });

  it('handles an empty test', () => {
    expect(rankOf({}).size).toBe(0);
  });
});

describe('shortName', () => {
  it('abbreviates the surname', () => expect(shortName('Ishita Rane')).toBe('Ishita R.'));
  it('uses the last part of a long name', () => expect(shortName('Aarav Sunil Kulkarni')).toBe('Aarav K.'));
  it('keeps a single name', () => expect(shortName('Om')).toBe('Om'));
});
