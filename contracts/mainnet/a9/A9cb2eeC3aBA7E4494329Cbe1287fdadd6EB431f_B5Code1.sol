// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./ICode.sol";

contract B5Code1 is ICode, Ownable{

    string public code = 'let n = "global" == t ? window : this;n.canvas = document.createElement("canvas");let o = n.canvas.getContext("2d");n.width = 100;n.height = 100;n.canvas.width = n.width;n.canvas.height = n.height;"offscreen" != t && (document.body ? document.body.appendChild(n.canvas) : window.addEventListener("load", function () {document.body.appendChild(n.canvas)}));m();n.MAGIC = 161533525;n.RGB = 0;n.HSV = 1;n.HSB = 1;n.CHORD = 0;n.PIE = 1;n.OPEN = 2;n.RADIUS = 1;n.CORNER = 2;n.CORNERS = 3;n.ROUND = "round";n.SQUARE = "butt";n.PROJECT = "square";n.MITER = "miter";n.BEVEL = "bevel";n.CLOSE = 1;n.NORMAL = "normal";n.ITALIC = "italic";n.BOLD = "bold";n.BOLDITALIC = "italic bold";n.CENTER = "center";n.LEFT = "left";n.RIGHT = "right";n.TOP = "top";n.BOTTOM = "bottom";n.BASELINE = "alphabetic";n.LANDSCAPE = "landscape";n.PORTRAIT = "portrait";n.HALF_PI = Math.PI / 2;n.PI = Math.PI;n.QUARTER_PI = Math.PI / 4;n.TAU = 2 * Math.PI;n.TWO_PI = 2 * Math.PI;n.THRESHOLD = 1;n.GRAY = 2;n.OPAQUE = 3;n.INVERT = 4;n.POSTERIZE = 5;n.DILATE = 6;n.ERODE = 7;n.BLUR = 8;n.ARROW = "default";n.CROSS = "crosshair";n.HAND = "pointer";n.MOVE = "move";n.TEXT = "text";n.SHR3 = 1;n.LCG = 2;n.hint = function (e, t) {n[e] = t};n.frameCount = 0;n.mouseX = 0;n.mouseY = 0;n.pmouseX = 0;n.pmouseY = 0;n.mouseButton = null;n.keyIsPressed = !1;n.mouseIsPressed = !1;n.key = null;n.keyCode = null;n.pixels = null;n._colorMode = n.RGB;n._noStroke = !1;n._noFill = !1;n._ellipseMode = n.CENTER;n._rectMode = n.CORNER;n._curveDetail = 20;n._curveAlpha = 0;n._noLoop = !1;n._textFont = "sans-serif";n._textSize = 12;n._textLeading = 12;n._textStyle = "normal";n._pixelDensity = 1;n._frameRate = null;n._tint = null;let a = null;let r = !0;let i = [];let l = null;let u = 0;let s = {};let c = 0;let h = null;let f = null;let d = null;Object.defineProperty(n, "deviceOrientation", {get: function () {return 90 == Math.abs(window.orientation) ? n.LANDSCAPE : n.PORTRAIT}});Object.defineProperty(n, "windowWidth", {get: function () {return window.innerWidth}});Object.defineProperty(n, "windowHeight", {get: function () {return window.innerHeight}});Object.defineProperty(n, "drawingContext", {get: function () {return o}});n.createCanvas = function (e, t) {n.width = e, n.height = t, n.canvas.width = e, n.canvas.height = t, m()};n.resizeCanvas = function (e, t) {n.width = e, n.height = t, n.canvas.width = e, n.canvas.height = t};n.createGraphics = n.createImage = function (t, n) {let o = new e("offscreen");return o.createCanvas(t, n), o.noLoop(), o};n.pixelDensity = function (e) {return null == e ? n._pixelDensity : (n._pixelDensity = e, n.canvas.width = Math.ceil(n.width * e), n.canvas.height = Math.ceil(n.height * e), n.canvas.style.width = n.width + "px", n.canvas.style.height = n.height + "px", o.scale(n._pixelDensity, n._pixelDensity), m(), n._pixelDensity)};n.map = function (e, t, n, o, a, r) {let i = o + 1 * (e - t) / (n - t) * (a - o);return r ? o < a ? Math.min(Math.max(i, o), a) : Math.min(Math.max(i, a), o) : i};n.lerp = function (e, t, n) {return e * (1 - n) + t * n};n.constrain = function (e, t, n) {return Math.min(Math.max(e, t), n)};n.dist = function () {return 4 == arguments.length ? Math.hypot(arguments[0] - arguments[2], arguments[1] - arguments[3]) : Math.hypot(arguments[0] - arguments[3], arguments[1] - arguments[4], arguments[2] - arguments[5])};n.norm = function (e, t, o) {return n.map(e, t, o, 0, 1)};n.sq = function (e) {return e * e};n.fract = function (e) {return e - Math.floor(e)};n.degrees = function (e) {return 180 * e / Math.PI};n.radians = function (e) {return e * Math.PI / 180};n.abs = Math.abs;n.ceil = Math.ceil;n.exp = Math.exp;n.floor = Math.floor;n.log = Math.log;n.mag = Math.hypot;n.max = Math.max;n.min = Math.min;n.round = Math.round;n.sqrt = Math.sqrt;n.sin = Math.sin;n.cos = Math.cos;n.tan = Math.tan;n.asin = Math.asin;n.acos = Math.acos;n.atan = Math.atan;n.atan2 = Math.atan2;n.curvePoint = function (e, t, n, o, a) {const r = a * a * a, i = a * a, l = -.5 * r + i - .5 * a, u = 1.5 * r - 2.5 * i + 1,s = -1.5 * r + 2 * i + .5 * a, c = .5 * r - .5 * i;return e * l + t * u + n * s + o * c};n.bezierPoint = function (e, t, n, o, a) {const r = 1 - a;return Math.pow(r, 3) * e + 3 * Math.pow(r, 2) * a * t + 3 * r * Math.pow(a, 2) * n + Math.pow(a, 3) * o};n.curveTangent = function (e, t, n, o, a) {const r = a * a, i = -3 * r / 2 + 2 * a - .5, l = 9 * r / 2 - 5 * a, u = -9 * r / 2 + 4 * a + .5,s = 3 * r / 2 - a;return e * i + t * l + n * u + o * s};n.bezierTangent = function (e, t, n, o, a) {const r = 1 - a;return 3 * o * Math.pow(a, 2) - 3 * n * Math.pow(a, 2) + 6 * n * r * a - 6 * t * r * a + 3 * t * Math.pow(r, 2) - 3 * e * Math.pow(r, 2)};function p(e, t, n) {let o, a, r, i, l, u, s, c, h;if (0 == t) return [255 * (o = n), 255 * (a = n), 255 * (r = n)];switch ((i = e) > 360 && (i = 0), s = n * (1 - t), c = n * (1 - t * (u = (i /= 60) - (l = ~~i))), h = n * (1 - t * (1 - u)), l) {case 0:o = n, a = h, r = s;break;case 1:o = c, a = n, r = s;break;case 2:o = s, a = n, r = h;break;case 3:o = s, a = c, r = n;break;case 4:o = h, a = s, r = n;break;default:o = n, a = s, r = c}return [255 * o, 255 * a, 255 * r]}n.Color = function (e, t, n, o) {let a = this;a.MAGIC = 786698, a._r = e, a._g = t, a._b = n, a._a = o, a._h = 0, a._s = 0, a._v = 0, a._hsvInferred = !1, a.setRed = function (e) {a._r = e, a._hsvInferred = !1}, a.setGreen = function (e) {a._g = e, a._hsvInferred = !1}, a.setBlue = function (e) {a._b = e, a._hsvInferred = !1}, a.setAlpha = function (e) {a._a = e / 255, a._hsvInferred = !1}, a._inferHSV = function () {a._hsvInferred || ([a._h, a._s, a._v] = function (e, t, n) {let o, a, r, i, l;if (o = e < t ? e < n ? e : n : t < n ? t : n, 0 == (l = 100 * (a = e > t ? e > n ? e : n : t > n ? t : n) / 255)) return [r = 0, i = 0, l];if (0 == (i = 100 * (a - o) / a)) return [r = 0, i, l];r = a == e ? 0 + 60 * (t - n) / (a - o) : a == t ? 120 + 60 * (n - e) / (a - o) : 240 + 60 * (e - t) / (a - o);return [r, i, l]}(a._r, a._g, a._b), a._hsvInferred = !0)}, a.toString = function () {return `rgba(${Math.round(a._r)},${Math.round(a._g)},${Math.round(a._b)},${~~(1e3 * a._a) / 1e3})`}};n.colorMode = function (e) {n._colorMode = e};n.color = function () {let a = arguments;if (1 == a.length && 786698 == a[0].MAGIC) {return a[0];}if (n._colorMode == n.RGB) {if (1 == a.length) return new n.Color(a[0], a[0], a[0], 1);if (2 == a.length) return new n.Color(a[0], a[0], a[0], a[1] / 255);if (3 == a.length) return new n.Color(a[0], a[1], a[2], 1);if (4 == a.length) return new n.Color(a[0], a[1], a[2], a[3] / 255)} else {if (1 == a.length) return new n.Color(...p(0, 0, a[0] / 100), 1);if (2 == a.length) return new n.Color(...p(0, 0, a[0] / 100), a[1] / 255);if (3 == a.length) return new n.Color(...p(a[0], a[1] / 100, a[2] / 100), 1);if (4 == a.length) return new n.Color(...p(a[0], a[1] / 100, a[2] / 100), a[3])}return null};n.lightness = function (e) {return 100 * (.2126 * e._r + .7152 * e._g + .0722 * e._b) / 255};n.lerpColor = function (e, t, o) {return n._colorMode == n.RGB ? new n.Color(n.constrain(n.lerp(e._r, t._r, o), 0, 255), n.constrain(n.lerp(e._g, t._g, o), 0, 255), n.constrain(n.lerp(e._b, t._b, o), 0, 255), n.constrain(n.lerp(e._a, t._a, o), 0, 1)) : (e._inferHSV(), t._inferHSV(), new n.Color(n.constrain(function (e, t, o) {var a = [[Math.abs(t - e), n.map(o, 0, 1, e, t)], [Math.abs(t + 360 - e), n.map(o, 0, 1, e, t + 360)], [Math.abs(t - 360 - e), n.map(o, 0, 1, e, t - 360)]];return a.sort((e, t) => e[0] - t[0]), (a[0][1] + 720) % 360}(e._h, t._h, o), 0, 360), n.constrain(n.lerp(e._s, t._s, o), 0, 100), n.constrain(n.lerp(e._v, t._v, o), 0, 100), n.constrain(n.lerp(e._a, t._a, o), 0, 1)))};function m() {o.fillStyle = "white", o.strokeStyle = "black", o.lineCap = "round", o.lineJoin = "miter"}n.strokeWeight = function (e) {n._noStroke = !1, o.lineWidth = e};n.stroke = function () {if (n._noStroke = !1, "string" == typeof arguments[0]) return void (o.strokeStyle = arguments[0]);let e = n.color.apply(null, arguments);e._a <= 0 ? n._noStroke = !0 : o.strokeStyle = e};n.noStroke = function () {n._noStroke = !0};n.fill = function () {if (n._noFill = !1, "string" == typeof arguments[0]) return void (o.fillStyle = arguments[0]);let e = n.color.apply(null, arguments);e._a <= 0 ? n._noFill = !0 : o.fillStyle = e};n.noFill = function () {n._noFill = !0};n.blendMode = function (e) {o.globalCompositeOperation = e};n.strokeCap = function (e) {o.lineCap = e};n.strokeJoin = function (e) {o.lineJoin = e};n.ellipseMode = function (e) {n._ellipseMode = e};n.rectMode = function (e) {n._rectMode = e};n.curveDetail = function (e) {n._curveDetail = e};n.curveAlpha = function (e) {n._curveAlpha = e};n.curveTightness = function (e) {console.warn("call curveAlpha() directly (note not same as p5s)"), n._curveAlpha = e};n.clear = function () {o.clearRect(0, 0, n.width, n.height)};n.background = function () {if (arguments[0] && arguments[0].MAGIC == n.MAGIC) return n.image(arguments[0], 0, 0, n.width, n.height);o.save(), o.resetTransform(), "string" == typeof arguments[0] ? o.fillStyle = arguments[0] : o.fillStyle = n.color(...Array.from(arguments)), o.fillRect(0, 0, n.width, n.height), o.restore()};n.line = function (e, t, a, r) {n._noStroke || (o.beginPath(), o.moveTo(e, t), o.lineTo(a, r), o.stroke())};function g(e) {if (0 <= e && e < 2 * Math.PI) return e;for (; e < 0;) e += 2 * Math.PI;for (; e >= Math.PI;) e -= 2 * Math.PI;return e}function v(e, t, a, r, i, l, u, s) {if (n._noFill && n._noStroke) return;let c = g(i), h = g(l);o.beginPath();for (let i = 0; i < s + 1; i++) {let l = i / s, u = n.lerp(c, h, l), f = Math.cos(u) * a / 2, d = Math.sin(u) * r / 2;o[i ? "lineTo" : "moveTo"](e + f, t + d)}u == n.CHORD ? o.closePath() : u == n.PIE && (o.lineTo(e, t), o.closePath()), n._noFill || o.fill(), n._noStroke || o.stroke()}n.arc = function (e, t, o, a, r, i, l, u) {if (r == i) return n.ellipse(e, t, o, a);null == u && (u = 25), null == l && (l = n.PIE), n._ellipseMode == n.CENTER ? v(e, t, o, a, r, i, l, u) : n._ellipseMode == n.RADIUS ? v(e, t, 2 * o, 2 * a, r, i, l, u) : n._ellipseMode == n.CORNER ? v(e + o / 2, t + a / 2, o, a, r, i, l, u) : n._ellipseMode == n.CORNERS && v((e + o) / 2, (t + a) / 2, o - e, a - t, r, i, l, u)};function M(e, t, a, r) {n._noFill && n._noStroke || (o.beginPath(), o.ellipse(e, t, a / 2, r / 2, 0, 0, 2 * Math.PI), n._noFill || o.fill(), n._noStroke || o.stroke())}n.ellipse = function (e, t, o, a) {null == a && (a = o), n._ellipseMode == n.CENTER ? M(e, t, o, a) : n._ellipseMode == n.RADIUS ? M(e, t, 2 * o, 2 * a) : n._ellipseMode == n.CORNER ? M(e + o / 2, t + a / 2, o, a) : n._ellipseMode == n.CORNERS && M((e + o) / 2, (t + a) / 2, o - e, a - t)};n.circle = function (e, t, o) {return n.ellipse(e, t, o, o)};n.point = function (e, t) {e.x && (t = e.y, e = e.x), o.beginPath(), o.ellipse(e, t, .4, .4, 0, 0, 2 * Math.PI), o.stroke()};function _(e, t, a, r, i, l, u, s) {if (n._noFill && n._noStroke) return;if (null == i) return function (e, t, a, r) {n._noFill || o.fillRect(e, t, a, r);n._noStroke || o.strokeRect(e, t, a, r)}(e, t, a, r);if (null == l) return _(e, t, a, r, i, i, i, i);const c = Math.min(Math.abs(r), Math.abs(a)) / 2;i = Math.min(c, i), l = Math.min(c, l), s = Math.min(c, s), u = Math.min(c, u), o.beginPath(), o.moveTo(e + i, t), o.arcTo(e + a, t, e + a, t + r, l), o.arcTo(e + a, t + r, e, t + r, u), o.arcTo(e, t + r, e, t, s), o.arcTo(e, t, e + a, t, i), o.closePath(), n._noFill || o.fill(), n._noStroke || o.stroke()}n.rect = function (e, t, o, a, r, i, l, u) {n._rectMode == n.CENTER ? _(e - o / 2, t - a / 2, o, a, r, i, l, u) : n._rectMode == n.RADIUS ? _(e - o, t - a, 2 * o, 2 * a, r, i, l, u) : n._rectMode == n.CORNER ? _(e, t, o, a, r, i, l, u) : n._rectMode == n.CORNERS && _(e, t, o - e, a - t, r, i, l, u)};n.square = function (e, t, o, a, r, i, l) {return n.rect(e, t, o, o, a, r, i, l)};function x() {i = []}n.beginShape = function () {x(), o.beginPath(), r = !0};n.beginContour = function () {o.closePath(), x(), r = !0};n.endContour = function () {x(), r = !0};n.vertex = function (e, t) {x(), r ? o.moveTo(e, t) : o.lineTo(e, t), r = !1};n.bezierVertex = function (e, t, n, a, r, i) {x(), o.bezierCurveTo(e, t, n, a, r, i)};n.quadraticVertex = function (e, t, n, a) {x(), o.quadraticCurveTo(e, t, n, a)};n.bezier = function (e, t, o, a, r, i, l, u) {n.beginShape(), n.vertex(e, t), n.bezierVertex(o, a, r, i, l, u), n.endShape()};n.triangle = function (e, t, o, a, r, i) {n.beginShape(), n.vertex(e, t), n.vertex(o, a), n.vertex(r, i), n.endShape(n.CLOSE)};n.quad = function (e, t, o, a, r, i, l, u) {n.beginShape(), n.vertex(e, t), n.vertex(o, a), n.vertex(r, i), n.vertex(l, u), n.endShape(n.CLOSE)};n.endShape = function (e) {x(), e && o.closePath(), n._noFill || o.fill(), n._noStroke || o.stroke(), n._noFill && n._noStroke && (o.save(), o.fillStyle = "none", o.fill(), o.restore())};n.curveVertex = function (e, t) {if (i.push([e, t]), i.length < 4) return;let a = i[i.length - 4], l = i[i.length - 3], u = i[i.length - 2], s = i[i.length - 1],c = function (e, t, n, o, a, r, i, l, u, s) {function c(e, t, n, o, a, r) {let i = Math.pow(o - t, 2) + Math.pow(a - n, 2), l = Math.pow(i, .5 * r);return l + e}let h = [], f = c(0, e, t, n, o, s), d = c(f, n, o, a, r, s), p = c(d, a, r, i, l, s);for (let s = 0; s < u; s++) {let c = f + s / (u - 1) * (d - f),m = [(f - c) / (f - 0), (c - 0) / (f - 0), (d - c) / (d - f), (c - f) / (d - f), (p - c) / (p - d), (c - d) / (p - d), (d - c) / (d - 0), (c - 0) / (d - 0), (p - c) / (p - f), (c - f) / (p - f)];for (let e = 0; e < m.length; e += 2) isNaN(m[e]) && (m[e] = 1, m[e + 1] = 0), isFinite(m[e]) || (m[e] > 0 ? (m[e] = 1, m[e + 1] = 0) : (m[e] = 0, m[e + 1] = 1));let g = e * m[0] + n * m[1], v = t * m[0] + o * m[1], M = n * m[2] + a * m[3],_ = o * m[2] + r * m[3], x = a * m[4] + i * m[5], y = r * m[4] + l * m[5],w = g * m[6] + M * m[7], R = v * m[6] + _ * m[7], I = M * m[8] + x * m[9],E = _ * m[8] + y * m[9], S = w * m[2] + I * m[3], C = R * m[2] + E * m[3];h.push([S, C])}return h}(...a, ...l, ...u, ...s, n._curveDetail, n._curveAlpha);for (let e = 0; e < c.length; e++) r ? o.moveTo(...c[e]) : o.lineTo(...c[e]), r = !1};n.curve = function (e, t, o, a, r, i, l, u) {n.beginShape(), n.curveVertex(e, t), n.curveVertex(o, a), n.curveVertex(r, i), n.curveVertex(l, u), n.endShape()};';

    function getCode(string calldata) external view override returns(string memory) {
        return code;
    }

    function setCodeEnd(string calldata codeStr) public virtual onlyOwner {
        code = codeStr;
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ICode {
    function getCode(string calldata params) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}