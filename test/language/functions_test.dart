import 'package:dlox/dlox.dart';
import 'package:test/test.dart';

import '../stdout_mock.dart';
import '../utils.dart';

void main() {
  late ErrorHandler errorHandler;
  late StdoutMock stdout;

  setUp(() {
    errorHandler = ErrorHandler();
    stdout = StdoutMock();
  });

  test('Functions can be defined and called.', () {
    const program = '''
fun fn() {
  print "fn";
}

fn();
fn();
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines, hasLength(2));
    expect(stdout.writtenLines[0], 'fn');
    expect(stdout.writtenLines[1], 'fn');
  });

  test('Functions can receive arguments.', () {
    const program = '''
fun fn(arg) {
  print "fn: " + arg;
}

fn("1");
fn("2");
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines, hasLength(2));
    expect(stdout.writtenLines[0], 'fn: 1');
    expect(stdout.writtenLines[1], 'fn: 2');
  });

  test("Non-functions can't be called.", () {
    const program = '"not a function"();';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(error, isA<NonRoutineCalledError>());
    error as NonRoutineCalledError;

    expect(error.token.type, TokenType.rightParenthesis);
    expect(error.token.line, 1);
    expect(error.token.column, 18);
    expect(error.callee, 'not a function');
  });

  test("Functions/methods can't have more than 255 parameters.", () {
    const program = '''
fun a(aa, ab, ac, af, al, aq, at, ax, bc, bh, bj, bo, bp, bx, cc, cf,
      cj, cm, cp, cq, ct, cu, cw, cx, cy, da, dc, de, df, dh, dl, dp,
      dt, dw, dz, ec, ej, ek, el, em, en, eo, es, et, fa, fc, ff, fk,
      fl, fm, fr, fs, ft, fv, fy, ge, gf, gg, gm, gn, go, gp, gs, gt,
      gv, gw, gy, hb, hd, hh, hi, ho, hp, hr, hs, ht, hu, hv, hw, ie,
      ig, ih, ip, iw, je, jf, jh, jm, jn, jo, jp, jr, jw, jy, ka, kb,
      ke, kg, kh, ki, kn, kp, ks, kv, lb, le, lf, li, lk, ln, ls, lt,
      lv, ly, ma, mb, me, mg, mj, ml, mn, mo, mq, ms, mt, mz, nb, nc,
      ni, nl, nq, nt, ny, ob, od, oe, of, og, oi, oj, ol, oy, ox, pa,
      pe, ph, pj, pk, pl, pp, pt, py, qa, qc, qf, qh, qu, qv, qw, rb,
      rd, rf, rg, rh, rk, rl, rp, rq, rr, rs, ry, sj, sn, st, ta, tb,
      tc, td, te, tf, th, tj, tk, tm, tp, tt, tu, ub, ue, ug, uk, ul,
      us, uu, ux, uy, va, ve, vf, vl, vp, vs, vu, wa, wb, wc, wd, we,
      wg, wh, wj, wk, wl, wn, wo, wr, wu, wy, xa, xb, xc, xe, xg, xh,
      xi, xk, xl, xn, xo, xp, xq, xr, xs, xw, xx, yc, yd, yf, yg, yh,
      yj, yk, yl, ym, yq, zb, zg, zl, zn, zo, zp, zs, zt, zv, zx, zz) {}
''';

    parseSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(error, isA<ParametersLimitError>());
    error as ParametersLimitError;

    expect(error.token.lexeme, 'zz');
    expect(error.token.line, 16);
    expect(error.token.column, 68);
  });

  test("Functions/methods calls can't have more than 255 arguments.", () {
    const program = '''
a(aa, ab, ac, af, al, aq, at, ax, bc, bh, bj, bo, bp, bx, cc, cf,
  cj, cm, cp, cq, ct, cu, cw, cx, cy, da, dc, de, df, dh, dl, dp,
  dt, dw, dz, ec, ej, ek, el, em, en, eo, es, et, fa, fc, ff, fk,
  fl, fm, fr, fs, ft, fv, fy, ge, gf, gg, gm, gn, go, gp, gs, gt,
  gv, gw, gy, hb, hd, hh, hi, ho, hp, hr, hs, ht, hu, hv, hw, ie,
  ig, ih, ip, iw, je, jf, jh, jm, jn, jo, jp, jr, jw, jy, ka, kb,
  ke, kg, kh, ki, kn, kp, ks, kv, lb, le, lf, li, lk, ln, ls, lt,
  lv, ly, ma, mb, me, mg, mj, ml, mn, mo, mq, ms, mt, mz, nb, nc,
  ni, nl, nq, nt, ny, ob, od, oe, of, og, oi, oj, ol, oy, ox, pa,
  pe, ph, pj, pk, pl, pp, pt, py, qa, qc, qf, qh, qu, qv, qw, rb,
  rd, rf, rg, rh, rk, rl, rp, rq, rr, rs, ry, sj, sn, st, ta, tb,
  tc, td, te, tf, th, tj, tk, tm, tp, tt, tu, ub, ue, ug, uk, ul,
  us, uu, ux, uy, va, ve, vf, vl, vp, vs, vu, wa, wb, wc, wd, we,
  wg, wh, wj, wk, wl, wn, wo, wr, wu, wy, xa, xb, xc, xe, xg, xh,
  xi, xk, xl, xn, xo, xp, xq, xr, xs, xw, xx, yc, yd, yf, yg, yh,
  yj, yk, yl, ym, yq, zb, zg, zl, zn, zo, zp, zs, zt, zv, zx, zz);
''';

    parseSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(error, isA<ArgumentsLimitError>());
    error as ArgumentsLimitError;

    expect(error.token.lexeme, 'zz');
    expect(error.token.line, 16);
    expect(error.token.column, 64);
  });

  test("Functions/methods calls can't have fewer arguments than the expected arity.", () {
    const program = '''
fun add(a, b, c) {
  print a + b + c;
}

add(1, 2); // Too few.
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(error, isA<ArityError>());
    error as ArityError;

    expect(error.token.type, TokenType.rightParenthesis);
    expect(error.token.line, 5);
    expect(error.token.column, 9);
  });

  test("Functions/methods calls can't have more arguments than the expected arity.", () {
    const program = '''
fun add(a, b, c) {
  print a + b + c;
}

add(1, 2, 3, 4); // Too many.
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
    );

    final error = errorHandler.errors.single;

    expect(error, isA<ArityError>());
    error as ArityError;

    expect(error.token.type, TokenType.rightParenthesis);
    expect(error.token.line, 5);
    expect(error.token.column, 15);
  });

  test("Functions/methods calls with the same number of arguments as the expected arity are valid.", () {
    const program = '''
fun add(a, b, c) {
  print a + b + c;
}

add(1, 2, 3); // Perfect!
''';

    interpretSource(
      source: program,
      errorHandler: errorHandler,
      stdout: stdout,
    );

    expect(errorHandler.errors, isEmpty);
    expect(stdout.writtenLines.single, '6');
  });
}
