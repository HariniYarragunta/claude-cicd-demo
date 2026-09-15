import { test } from "node:test";
import assert from "node:assert/strict";
import { add } from "./math.js";

test("add() sums two positive numbers", () => {
  assert.equal(add(2, 3), 5);
});

test("add() handles negative numbers", () => {
  assert.equal(add(-4, 1), -3);
});

test("add() handles zero", () => {
  assert.equal(add(0, 0), 0);
});
