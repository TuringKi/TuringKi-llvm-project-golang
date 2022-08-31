; NOTE: Assertions have been autogenerated by utils/update_test_checks.py
; RUN: opt -passes=globalopt < %s -S | FileCheck %s

@i = internal unnamed_addr global i32 1, align 4
@r = internal global i64 0, align 8

; negative test for store-once-global - the urem constant expression must not be speculated

declare dso_local void @use(i32)

define i32 @cantrap_constant() {
; CHECK-LABEL: @cantrap_constant(
; CHECK-NEXT:  entry:
; CHECK-NEXT:    [[TMP0:%.*]] = load i32, i32* @i, align 4
; CHECK-NEXT:    [[TOBOOL:%.*]] = icmp eq i32 [[TMP0]], 0
; CHECK-NEXT:    [[NOT_TOBOOL:%.*]] = xor i1 [[TOBOOL]], true
; CHECK-NEXT:    [[SPEC_SELECT:%.*]] = zext i1 [[NOT_TOBOOL]] to i32
; CHECK-NEXT:    tail call void @use(i32 [[SPEC_SELECT]])
; CHECK-NEXT:    br i1 [[TOBOOL]], label [[IF_THEN:%.*]], label [[EXIT:%.*]]
; CHECK:       if.then:
; CHECK-NEXT:    store i32 trunc (i64 urem (i64 7, i64 zext (i1 icmp eq (i64* inttoptr (i64 1 to i64*), i64* @r) to i64)) to i32), i32* @i, align 4
; CHECK-NEXT:    br label [[EXIT]]
; CHECK:       exit:
; CHECK-NEXT:    ret i32 0
;
entry:
  %0 = load i32, i32* @i, align 4
  %tobool = icmp eq i32 %0, 0
  %not.tobool = xor i1 %tobool, true
  %spec.select = zext i1 %not.tobool to i32
  tail call void @use(i32 %spec.select)
  br i1 %tobool, label %if.then, label %exit

if.then:
  store i32 trunc (i64 urem (i64 7, i64 zext (i1 icmp eq (i64* inttoptr (i64 1 to i64*), i64* @r) to i64)) to i32), i32* @i, align 4
  br label %exit

exit:
  ret i32 0
}

; negative test for store-once-global - the srem constant expression must not be speculated

@b1 = internal global i64* null, align 8
@d1 = internal unnamed_addr global i32 0, align 2

define void @maytrap() {
; CHECK-LABEL: @maytrap(
; CHECK-NEXT:    store i32 srem (i32 7, i32 zext (i1 icmp eq (i64** inttoptr (i64 16 to i64**), i64** @b1) to i32)), i32* @d1, align 2
; CHECK-NEXT:    ret void
;
  store i32 srem (i32 7, i32 zext (i1 icmp eq (i64** inttoptr (i64 16 to i64**), i64** @b1) to i32)), i32* @d1, align 2
  ret void
}

define i32 @main1() {
; CHECK-LABEL: @main1(
; CHECK-NEXT:    [[T0:%.*]] = load i32, i32* @d1, align 2
; CHECK-NEXT:    ret i32 [[T0]]
;
  %t0 = load i32, i32* @d1, align 2
  ret i32 %t0
}

; This is fine to optimize as a store-once-global constant because the expression can't trap

@b2 = internal global i64* null, align 8
@d2 = internal unnamed_addr global i32 0, align 2

define void @maynottrap() {
; CHECK-LABEL: @maynottrap(
; CHECK-NEXT:    store i1 true, i1* @d2, align 1
; CHECK-NEXT:    ret void
;
  store i32 mul (i32 7, i32 zext (i1 icmp eq (i64** inttoptr (i64 16 to i64**), i64** @b2) to i32)), i32* @d2, align 2
  ret void
}

define i32 @main2() {
; CHECK-LABEL: @main2(
; CHECK-NEXT:    [[T0_B:%.*]] = load i1, i1* @d2, align 1
; CHECK-NEXT:    [[T0:%.*]] = select i1 [[T0_B]], i32 mul (i32 zext (i1 icmp eq (i64** inttoptr (i64 16 to i64**), i64** @b2) to i32), i32 7), i32 0
; CHECK-NEXT:    ret i32 [[T0]]
;
  %t0 = load i32, i32* @d2, align 2
  ret i32 %t0
}