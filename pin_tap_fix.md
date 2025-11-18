## ピンタップ位置ずれ修正ドキュメント

### 概要

- **目的**: 拡大していない状態で、ユーザーがタップした位置とピンの表示位置に縦方向のズレが出ていた問題を解消する。  
- **原因**:  
  - タップ座標を「画面全体基準」で取得しており、上部の操作パネル高さ分だけ Y 座標が下方向にずれていた。  
  - ピン描画時のアンカー位置が「ピンの下端」になっており、タップ位置と視覚的な位置の差が大きく見えていた。  

対象ファイル: `lib/widgets/custom_map_widget.dart`

---

### 修正内容

#### 1. ピン描画位置（アンカー）の変更

- **修正前の挙動**  
  保存している座標を **ピンの下端（底辺）** に合わせて描画していた。

  ```dart
  // 概念的なイメージ
  final double pinX = memo.latitude! * _actualDisplayWidth + _offsetX;
  final double pinY = memo.longitude! * _actualDisplayHeight + _offsetY;

  return Positioned(
    left: pinX - pinSize / 2, // X は中心
    top: pinY - pinSize,      // Y は下端
    child: ...
  );
  ```

- **修正後の挙動**  
  保存している座標を **ピンの中心** に合わせて描画するように変更。

  ```dart
  final double pinX = memo.latitude! * _actualDisplayWidth + _offsetX;
  final double pinY = memo.longitude! * _actualDisplayHeight + _offsetY;

  return Positioned(
    left: pinX - pinSize / 2,
    top: pinY - pinSize / 2, // 中心基準に変更
    child: ...
  );
  ```

これにより、「タップした位置 ≒ 丸いピンの中心」となる自然な挙動に統一される。

---

#### 2. タップ時の座標取得方法の変更

- **修正前**  
  `context.findRenderObject().globalToLocal(details.globalPosition)` を使い、  
  画面全体からのグローバル座標を `CustomMapWidget` 基準に変換していた。

  ```dart
  final RenderBox renderBox = context.findRenderObject() as RenderBox;
  final localPosition = renderBox.globalToLocal(details.globalPosition);
  ```

  この方法だと、上部の地図操作パネルなどの高さの分だけ **Y 座標が下方向にずれてしまう** 状態だった。  
  さらに、`TransformationController` の行列を逆変換して座標を補正する、複雑なロジックになっていた。

- **修正後**  
  `details.localPosition` を使用し、**地図表示エリア内の `GestureDetector` 自身を原点とするローカル座標**をそのまま利用。

  ```dart
  onTapDown: (details) {
    // この GestureDetector 内のローカル座標
    final Offset localPosition = details.localPosition;

    // 画像表示領域内かどうかを判定
    if (localPosition.dx < _offsetX ||
        localPosition.dx > _offsetX + _actualDisplayWidth ||
        localPosition.dy < _offsetY ||
        localPosition.dy > _offsetY + _actualDisplayHeight) {
      return; // 画像外のタップは無視
    }

    // 画像表示領域内のローカル座標に変換
    final Offset imageLocalPosition = Offset(
      localPosition.dx - _offsetX,
      localPosition.dy - _offsetY,
    );

    // 相対座標（0.0〜1.0）に変換
    final double relativeX =
        imageLocalPosition.dx / _actualDisplayWidth;
    final double relativeY =
        imageLocalPosition.dy / _actualDisplayHeight;

    if (relativeX >= 0.0 &&
        relativeX <= 1.0 &&
        relativeY >= 0.0 &&
        relativeY <= 1.0) {
      widget.onTap(relativeX, relativeY);
    }
  },
  ```

- `InteractiveViewer` の変換行列（ズーム・パン）を自前で逆変換する処理を削除し、  
  **常に「画像がフィットしている座標系」で相対座標を計算**するシンプルなロジックになった。

---

### 期待される挙動の変化

- ズームの有無に関わらず、格子の交点などをタップすると、**その地点のほぼ中心にピンが表示される**。  
- 上部パネルの高さや画面レイアウトの違いによって、ピンが一様に下へずれる現象は解消される。  
- 丸いピンのデザインと、ユーザーの直感的な「ここを指したい」という感覚が一致しやすくなる。  

---

### 印刷処理との整合性

- 印刷用の処理（`lib/utils/print_helper.dart` 内の `_createMapWithPins`）では、  
  もともと「相対座標 → 画像座標 → 円の中心として描画」という流れで実装されている。
- 今回の修正で、画面表示時のピン位置も「中心基準」に統一されたため、  
  **画面上のピン位置と印刷されたピン位置の意味が揃う** 形になっている。

---

### 今後の拡張に関するメモ

- 将来的に「しずく型のピン画像（先端が鋭いマーカー）」に変更する場合は、  
  その先端が座標に合うように、`Positioned` の `top` / `left` の計算を再度調整する必要がある。  
- その場合は「座標 = 先端位置」とした上で、画像内のアンカーオフセット（先端が画像内のどこにあるか）を考慮したレイアウトにする。  


