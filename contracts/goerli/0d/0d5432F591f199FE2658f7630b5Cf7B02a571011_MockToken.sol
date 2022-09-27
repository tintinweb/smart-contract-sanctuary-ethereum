// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract MockToken is ERC721 {
    // Optional mapping for token URIs
    mapping(uint256 => uint256) private _tokenURIs;

    string private artLink =
        '{"name": "Ale token", "image": "data:image/svg+xml;base64,';
    string private artEnd = '"}';

    string[] private COLORS = [
        '<svg xmlns="http://www.w3.org/2000/svg" xml:space="preserve" shape-rendering="crispEdges" viewBox="0 0 64 64"><path stroke="#354332" d="M0 .5h30m7 0h27m-64 1h25m17 0h22m-64 1h21m26 0h17m-64 1h19m29 0h16m-64 1h16m32 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m33 0h16m-64 1h15m34 0h15m-64 1h15m36 0h13m-64 1h15m37 0h12m-64 1h15m39 0h10m-64 1h15m40 0h9m-64 1h15m42 0h7m-64 1h15m43 0h6m-64 1h15m42 0h7m-64 1h15m41 0h8m-64 1h15m40 0h9m-64 1h15m39 0h10m-64 1h15m38 0h11m-64 1h14m38 0h12m-64 1h13m39 0h12m-64 1h12m39 0h13m-64 1h11m40 0h13m-64 1h10m41 0h13m-64 1h9m42 0h13m-64 1h8m42 0h14m-64 1h7m42 0h15m-64 1h7m39 0h18m-64 1h6m37 0h21m-64 1h7m35 0h22m-64 1h6m34 0h24m-64 1h7m32 0h25m-64 1h7m31 0h26m-64 1h8m29 0h27m-64 1h10m18 0h36m-64 1h10m17 0h37m-64 1h11m11 0h42m-64 1h14m7 0h43"/><path stroke="#000" d="M30 .5h7m-12 1h5m7 0h5m-21 1h4m17 0h5m-28 1h2m26 0h1m-32 1h3m28 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m31 0h1m-33 1h1m32 0h1m-34 1h1m33 0h2m-36 1h1m35 0h1m-37 1h1m36 0h2m-39 1h1m38 0h1m-40 1h1m39 0h2m-42 1h1m41 0h1m-43 1h1m40 0h1m-42 1h1m39 0h1m-41 1h1m38 0h1m-40 1h1m37 0h1m-39 1h1m36 0h1m-39 1h1m36 0h1m-39 1h1m37 0h1m-40 1h1m37 0h1m-40 1h1m38 0h1m-41 1h1m39 0h1m-42 1h1m40 0h1m-43 1h1m40 0h1m-43 1h1m38 0h3m-42 1h1m35 0h3m-40 1h1m35 0h1m-36 1h1m32 0h2m-36 1h1m32 0h1m-33 1h1m30 0h1m-32 1h1m29 0h1m-30 1h2m18 0h9m-27 1h1m16 0h1m-18 1h1m11 0h5m-16 1h3m7 0h1m-8 1h7"/><path stroke="#6b7b7c" d="M30 1.5h7m-12 1h17m-16 1h1m4 0h13m-8 1h7m0 1h1"/><path stroke="#7a8b8d" d="M21 3.5h5m-7 1h3"/><path stroke="#2e322f" d="M27 3.5h1m16 0h2m-3 1h1"/><path stroke="#292c2a" d="M28 3.5h3m15 0h1m-19 1h2m4 0h2m8 0h2m-9 1h1m2 0h3"/><path stroke="#3d4141" d="M22 4.5h4m-9 1h4"/><path stroke="#384025" d="M26 4.5h2m5 0h1m-13 1h1m13 0h2m-18 1h1m16 0h2m-11 3h1m12 0h1m-13 26h4m1 0h1m-10 1h1m6 0h2m-14 1h2"/><path stroke="#3f482a" d="M30 4.5h3m-11 1h2m6 0h5m-15 1h2m9 0h5m-10 1h15m-21 1h1m1 0h2m1 0h16m-21 1h3m3 0h1m5 0h1m5 0h2m-1 3h1m-20 16h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-2 1h2m11 0h1m1 0h1m-16 1h2"/><path stroke="#95a164" d="M46 4.5h1m-1 2h1m-2 2h2m-5 1h3m-3 1h2m1 0h1m-1 1h2m-26 4h1m14 12h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m7 1h1m-1 1h1m-4 1h1m2 0h3m-3 1h2"/><path stroke="#7b7f57" d="M16 5.5h1m0 1h1m0 3h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-2 15h1m-10 12h1m-1 1h1m-2 1h1"/><path stroke="#818f4d" d="M24 5.5h6m-8 1h1m4 0h4m-11 1h6m-7 1h1m1 0h1m2 0h1m-6 1h1m3 0h1m1 0h1m2 0h2m5 0h3m-18 1h3m15 0h3m-4 1h2m-3 1h2m2 0h1m-4 1h4m-21 2h1m-1 4h1m18 0h2m-22 1h2m18 0h2m-22 1h2m18 0h2m-22 1h2m17 0h3m-22 1h3m15 0h4m-22 1h3m12 0h2m1 0h4m-22 1h3m12 0h1m2 0h4m-22 1h3m10 0h4m1 0h4m-22 1h3m9 0h1m1 0h3m1 0h4m-22 1h1m1 0h1m8 0h2m2 0h2m1 0h4m-22 1h1m1 0h2m9 0h4m1 0h4m-22 1h1m1 0h2m8 0h5m1 0h4m-22 1h1m1 0h2m9 0h4m1 0h4m-22 1h1m1 0h1m9 0h5m1 0h4m-22 1h1m6 0h1m3 0h5m2 0h4m-22 1h1m2 0h1m2 0h1m2 0h1m1 0h5m2 0h3m3 0h1m-22 1h1m1 0h3"/><path stroke="#11160e" d="M38 5.5h1m1 1h1m9 29h1m-1 2h1m2 0h1m0 1h1m-1 1h3m-3 1h2m-2 1h1"/><path stroke="#22291b" d="M39 5.5h1m-2 1h2"/><path stroke="#646648" d="M44 5.5h2m-4 1h4m-5 1h6m-6 1h4m-1 2h1m1 25h1m0 1h1m-25 1h3m1 0h2m8 0h1m9 0h1m-25 1h6m16 0h1m2 0h1m-25 1h1m19 0h1m-22 1h1m16 0h1m3 0h3m-7 1h1m3 0h2m-3 1h3m3 0h1m1 0h2m-11 1h4m2 0h4m-11 1h3m2 0h2m2 0h1m-12 1h1m1 0h3m1 0h4m-11 1h1m1 0h3m2 0h3m-9 1h2m1 0h5m-17 1h1m6 0h1m1 0h1m3 0h1m-11 1h1m3 0h3m2 0h2m2 0h1m-26 1h1m7 0h1m3 0h1m1 0h2m2 0h2m2 0h1m-20 1h6m2 0h5m9 0h1m-22 1h5m1 0h4m1 0h1m4 0h1m1 0h1m-22 1h1m3 0h1m4 0h2m4 0h2m2 0h2m-33 1h1m10 0h1m2 0h2m6 0h4m2 0h1m-18 1h2m2 0h1m1 0h2m3 0h2m2 0h3m-32 1h1m5 0h1m7 0h3m2 0h3m1 0h2m2 0h1m-26 1h1m13 0h1m3 0h1m2 0h3m1 0h1m-25 1h2m1 0h1m1 0h1m1 0h2m4 0h1m1 0h1m2 0h1m7 0h1m-26 1h5m1 0h1m2 0h2m5 0h1m-13 1h1m5 0h6m-16 1h1m3 0h7m-8 1h1m1 0h1m1 0h1"/><path stroke="#b4b785" d="M46 5.5h1m-2 4h1m0 1h1m-3 1h1m1 1h1m-3 1h1m-1 1h1m-5 1h1m5 5h1m-2 1h2m-2 1h2m-2 1h2m-2 1h2m-2 1h2m-2 1h2m-1 1h1m-2 1h2m-2 1h2m-3 1h3m-3 1h3m-2 1h2m-2 1h2m-31 7h1m-1 1h1"/><path stroke="#c9cc95" d="M16 6.5h1m7 0h1m-9 1h1m-1 1h1m-1 1h2m-2 1h2m6 0h2m1 0h5m-16 1h2m4 0h7m1 0h3m-17 1h2m3 0h6m2 0h7m5 0h2m-27 1h2m3 0h16m4 0h2m-27 1h2m1 0h1m2 0h17m2 0h3m-28 1h2m5 0h17m1 0h4m-29 1h2m3 0h24m-29 1h2m1 0h1m1 0h14m1 0h2m3 0h4m-29 1h2m1 0h1m2 0h13m1 0h1m4 0h4m-29 1h2m4 0h8m1 0h3m2 0h2m3 0h3m-28 1h2m4 0h10m9 0h4m-29 1h2m5 0h4m1 0h3m10 0h4m-29 1h2m5 0h4m2 0h1m12 0h2m-28 1h2m5 0h4m14 0h3m-28 1h2m5 0h2m1 0h1m1 0h2m12 0h3m-29 1h2m5 0h2m1 0h1m1 0h1m15 0h1m-29 1h2m5 0h2m1 0h1m-11 1h2m6 0h1m19 0h1m-22 1h2m18 0h2m-21 1h1m19 0h1m-28 1h1m6 0h1m-8 1h1m6 0h1"/><path stroke="#52582c" d="M18 6.5h1m-1 1h1m-1 1h1m-1 18h1m-1 1h1m-1 1h1m-1 6h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-2 1h2"/><path stroke="#a6b470" d="M23 6.5h1m1 0h2m-3 3h1m5 0h2m1 0h2m-16 1h1m3 0h1m2 0h1m5 0h6m3 0h1m-23 1h3m7 0h1m3 0h4m2 0h4m-24 1h2m6 0h2m9 0h1m4 0h1m-25 1h2m22 0h1m-24 1h2m17 0h1m-21 1h1m2 0h1m-4 1h2m-1 1h1m14 0h1m2 0h3m-21 1h2m13 0h1m1 0h4m-22 1h1m1 0h1m8 0h1m3 0h2m2 0h1m5 0h1m-24 1h1m10 0h7m-18 1h2m4 0h1m3 0h8m-18 1h2m4 0h2m1 0h8m3 0h1m2 0h1m-23 1h1m4 0h10m7 0h1m-23 1h1m2 0h1m1 0h1m2 0h4m2 0h1m4 0h1m-20 1h1m2 0h1m1 0h1m1 0h5m1 0h2m4 0h3m-22 1h1m2 0h1m1 0h5m4 0h1m4 0h4m-23 1h2m1 0h6m1 0h1m8 0h3m-22 1h1m2 0h5m2 0h2m7 0h2m-20 1h1m1 0h7m9 0h3m-21 1h1m1 0h6m10 0h3m-21 1h1m1 0h7m9 0h3m-22 1h9m10 0h3m-22 1h4m1 0h3m11 0h3m-21 1h2m1 0h2m1 0h1m12 0h1m-20 1h1"/><path stroke="#595b40" d="M41 6.5h1m-1 3h1m5 24h1m-1 1h1m-1 1h1m-3 1h2m-2 1h2m2 1h4m-3 1h3m-2 2h1m-34 10h5m-5 1h6m-5 1h1m1 0h1"/><path stroke="#8a8e61" d="M17 7.5h1m-1 1h1m25 3h1m-28 17h2m-2 1h2m-2 1h1m-1 1h1m-1 1h2m-2 1h2m-2 1h2m-2 1h2m-2 1h2m26 0h1m-28 1h1m-2 1h1m-1 1h1"/><path stroke="#738045" d="M19 7.5h1m20 7h1m-5 18h1m-16 1h1m13 0h2m-16 1h1m13 0h2m3 0h1m-20 1h1m5 0h1m7 0h4m3 0h2m-23 1h3m6 0h1m2 0h1m-13 1h1"/><path stroke="#e3e5a7" d="M46 9.5h1m-3 3h2m-1 1h2m-2 1h2m-2 1h2m-2 1h2m-2 1h2m-2 1h2m-2 1h2m-2 1h1m-1 7h1"/><path stroke="#5c6332" d="M18 29.5h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m24 3h1m-28 1h1m26 0h1m-27 1h1"/><path stroke="#5d5038" d="M48 34.5h1m0 1h1m-22 1h1m6 0h2m13 0h2m-8 1h1m3 0h2m1 0h2m-34 1h1m9 0h2m22 0h1m-24 1h1m17 0h1m-32 2h1m-2 1h1m24 0h1m-1 1h1m-2 2h1m8 0h2m-13 2h1m-5 2h1m-18 2h1m26 1h1m-18 2h1"/><path stroke="#717435" d="M39 35.5h3m-3 1h4m-3 1h1"/><path stroke="#574a34" d="M48 35.5h1m-1 1h2m-1 3h1m3 0h1m-1 1h1m-1 1h1m-31 10h1m-7 1h1m0 1h1m1 0h1"/><path stroke="#434a0c" d="M25 36.5h1m11 0h2m-1 1h2m1 0h2m-3 1h3m-3 1h3m-1 1h1"/><path stroke="#4d511a" d="M26 36.5h2"/><path stroke="#8b826c" d="M29 36.5h1m-8 1h1m6 0h2m-13 3h1m16 9h1m-6 2h1m-15 1h1"/><path stroke="#382b15" d="M34 36.5h1m4 2h1m6 0h2m-7 3h1m11 1h1m-15 4h1m-8 4h1m-5 4h1"/><path stroke="#9b9179" d="M26 37.5h1m4 0h4m1 0h1m-16 1h2m14 0h2m-20 1h1m1 0h3m1 0h5m1 0h1m3 0h3m1 0h1m5 0h1m-24 1h1m1 0h8m2 0h6m9 0h1m-27 1h2m3 0h3m1 0h8m7 0h2m-30 1h1m2 0h5m1 0h2m3 0h8m7 0h1m-27 1h2m2 0h1m5 0h9m-19 1h4m4 0h11m4 0h1m-22 1h15m5 0h1m-23 1h16m5 0h1m-25 1h5m1 0h8m1 0h4m-21 1h13m1 0h6m-20 1h2m2 0h12m3 0h1m12 0h1m-33 1h4m1 0h7m1 0h1m3 0h1m2 0h2m2 0h1m6 0h1m-12 1h1m2 0h3m-19 1h1m10 0h1m1 0h4m1 0h1m-20 1h3m9 0h2m2 0h2m-22 1h2m2 0h1m12 0h2m1 0h3m-22 1h1m2 0h2m14 0h1m-29 1h2m1 0h5m1 0h1m3 0h2m3 0h1m8 0h1m-25 1h3m5 0h1m5 0h2m-21 1h1m6 0h1m2 0h4m-13 1h1m5 0h1m5 0h1m-12 1h4m1 0h1m-4 1h2m0 1h1m1 0h1"/><path stroke="#c8bfb5" d="M35 37.5h1m-16 1h1m10 0h6m-17 1h1m11 0h3m3 0h1m-20 1h3m10 0h2m14 0h1m-31 1h5m2 0h3m3 0h1m-15 1h2m1 0h2m5 0h1m2 0h3m-16 1h5m2 0h2m1 0h5m-16 1h6m4 0h4m14 0h1m-29 1h8m-8 1h6m-6 1h3m5 0h1m-10 1h2m-2 1h2m2 0h2m-7 1h3m25 0h1m-30 1h3m22 0h2m-27 1h3m-7 1h1m3 0h3m-4 1h7m-8 1h9m-1 1h1m-3 1h5m-5 3h1"/><path stroke="#3e3c05" d="M43 38.5h1m-3 2h1"/><path stroke="#3f3018" d="M44 38.5h1m-2 1h1m2 0h2m-5 1h1m3 0h1m2 0h1m-9 1h2m2 0h1m2 0h2m-9 1h1m3 0h1m3 0h1m-5 1h2m4 0h1m-5 1h2m1 0h1m-8 2h1m3 0h3m-18 1h1m7 0h1m5 0h3m-12 1h1m1 0h3m1 0h6m-10 1h2m2 0h2m1 0h2m-18 1h1m12 0h4m-17 1h1m11 0h3m-16 1h1m-4 1h4m2 0h2m-13 1h1m3 0h1m2 0h3m-24 1h3m15 0h1m2 0h3m2 0h2m-28 1h3m21 0h2m1 0h3m-30 1h1m1 0h4m10 0h3m6 0h1m1 0h3m-30 1h1m3 0h1m1 0h1m9 0h1m1 0h2m1 0h7m-18 1h2m3 0h4m-9 1h3m-9 1h1m6 1h2"/><path stroke="#b6ae9e" d="M51 40.5h2m-1 1h1m-6 1h1m-32 1h1m-6 6h1m2 0h1m-5 2h1m5 0h1m-1 2h2"/><path stroke="#726958" d="M15 45.5h1m-2 1h1m-2 1h2m-3 1h2m-2 1h2m-2 1h1m-4 2h1m-2 2h2"/><path stroke="#9a9889" d="M15 46.5h1m-1 1h1m-2 1h1m-2 2h1m33 1h1m-3 1h1"/><path stroke="#a0a581" d="M10 50.5h1"/><path stroke="#cdcdbd" d="M11 50.5h1m37 0h1m-39 1h2m35 0h1m-39 1h3m-3 1h3m-2 1h1"/><path stroke="#62665a" d="M9 51.5h1"/></svg>"}'
        '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 -0.5 64 64"><path stroke="#707980" d="M0 0h29m3 0h4m3 0h25M0 1h29m11 0h24M0 2h28m12 0h24M0 3h28m12 0h24M0 4h28m12 0h24M0 5h28m12 0h24M0 6h28m12 0h24M0 7h28m12 0h24M0 8h28m12 0h24M0 9h28m12 0h24M0 10h28m12 0h24M0 11h28m12 0h24M0 12h28m12 0h24M0 13h28m12 0h24M0 14h28m12 0h24M0 15h28m12 0h1m7 0h16M0 16h28m12 0h1m9 0h14M0 17h28m24 0h12M0 18h28m25 0h11M0 19h28m25 0h11M0 20h28m25 0h11M0 21h28m25 0h11M0 22h22m31 0h11M0 23h21m32 0h11M0 24h21m32 0h11M0 25h21m31 0h12M0 26h21m31 0h12M0 27h21m30 0h13M0 28h22m29 0h13M0 29h22m29 0h13M0 30h18m32 0h14M0 31h16m34 0h14M0 32h15m34 0h15M0 33h14m38 0h12M0 34h13m40 0h11M0 35h12m41 0h11M0 36h12m41 0h11M0 37h11m42 0h11M0 38h10m42 0h12M0 39h9m43 0h12M0 40h10m41 0h13M0 41h11m39 0h14M0 42h12m38 0h14M0 43h14m35 0h15M0 44h15m34 0h15M0 45h16m34 0h14M0 46h17m33 0h14M0 47h18m32 0h14M0 48h20m30 0h14M0 49h22m28 0h14M0 50h22m27 0h15M0 51h22m27 0h15M0 52h22m26 0h16M0 53h23m24 0h17M0 54h24m22 0h18M0 55h24m22 0h18M0 56h25m21 0h18M0 57h26m21 0h17M0 58h26m21 0h17M0 59h27m20 0h17M0 60h28m19 0h17M0 61h29m17 0h18M0 62h30m7 0h5m3 0h19M0 63h32m1 0h10m1 0h20"/><path stroke="#6f787e" d="M29 0h1m1 0h1m4 0h3m-7 63h1m10 0h1"/><path stroke="#6f7a81" d="M30 0h1"/><path stroke="#000" d="M29 1h1m9 3h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m1 0h3m1 0h1m1 0h1m-9 1h1m9 0h1m-11 1h2m10 0h1m-29 5h2m1 0h1m-6 1h1m30 0h1m-32 1h1m-1 1h1m29 0h1m-31 1h1m29 0h1m-2 1h1m-29 1h1m-4 2h4m26 0h1m-33 1h1m30 1h1m-35 1h1m33 0h3m-38 1h1m34 0h1m-37 2h1m39 1h1m-43 1h1m40 0h1m-42 2h1m0 1h1m37 0h1m-37 1h1m0 1h1m0 1h1m32 0h1m-33 1h1m0 1h1m1 1h1m29 0h1m-29 1h1m27 0h1m-28 1h1m-1 1h1m25 0h1m-2 2h1m-25 1h1m21 2h1m-21 1h1m0 1h1m19 0h1m-20 2h1m18 0h1m-1 1h1m-18 1h1m8 0h1m6 0h1m-16 1h1m4 0h1"/><path stroke="#020404" d="M30 1h1m0 1h1m20 20h1"/><path stroke="#030505" d="M31 1h1m1 0h3m10 14h1m1 1h1m1 1h1m1 2h1m-1 1h1m-1 1h1"/><path stroke="#707a81" d="M32 1h1"/><path stroke="#030404" d="M36 1h1m-9 1h1m10 0h1M28 3h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 2h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m23 14h1m-1 1h1"/><path stroke="#020303" d="M37 1h2m0 2h1M28 8h1m17 45h1m-4 9h2"/><path stroke="#6f7980" d="M39 1h1"/><path stroke="#086581" d="M29 2h2m3 0h1m1 0h2m-8 1h1m1 0h1m3 0h3m-9 1h3m3 0h3m-9 1h1m1 0h1m3 0h1m-1 1h1m1 0h1m-3 2h1m2 10h3m-2 1h4m-4 1h4m-15 1h1m9 0h2m1 0h2m2 0h2m-9 1h1m2 0h1m3 0h1m1 0h2m-10 1h3m3 0h3m-8 1h2m4 0h1m-7 1h1m5 0h1m2 0h1m-28 1h2m4 0h1m16 0h2m-25 1h2m24 0h1m-26 1h2m3 0h1m-6 1h3m-2 1h2m2 0h2m-1 1h1m-1 1h1m-1 1h1m-1 1h1m18 0h1m-20 1h5m15 0h1m-27 1h1m5 0h2m15 0h2m-19 1h1m17 0h1m-19 1h1m5 0h1m8 0h4m-23 1h2m2 0h2m2 0h2m8 0h4m-21 1h2m1 0h1m5 0h1m4 0h1m1 0h4m-10 1h1m2 0h7m-9 1h6m1 0h1m-7 1h5m-4 1h4m1 0h2m-6 1h2m1 0h2"/><path stroke="#020505" d="M32 2h1"/><path stroke="#3ba9ce" d="M33 2h1m1 0h1m2 0h1M29 3h1m1 0h1m2 0h1m-6 1h1m-1 1h1m1 0h1m5 0h2M29 6h2m6 0h1m-7 1h2m3 0h3M29 8h1m1 0h2m4 0h2M29 9h1m1 0h2m3 0h3m-3 1h3m-10 1h1m-1 3h1m1 2h1m10 0h2m2 0h1m-6 1h5m3 0h1m-7 1h7m-6 1h7m-22 1h1m14 0h2m1 0h4m-21 1h1m3 0h1m1 0h1m4 0h1m2 0h1m-16 1h2m5 0h1m3 0h2m1 0h2m2 0h1m2 0h1m-29 1h1m1 0h1m4 0h2m3 0h1m1 0h1m1 0h2m4 0h2m4 0h1m-29 1h2m5 0h2m3 0h4m1 0h2m2 0h1m1 0h2m1 0h4m-30 1h1m6 0h3m2 0h4m2 0h1m1 0h1m1 0h3m2 0h1m-16 1h3m4 0h1m2 0h2m2 0h3m-22 1h2m3 0h3m8 0h4m-26 1h1m6 0h1m3 0h2m10 0h1m1 0h2m-22 1h3m3 0h3m-14 1h2m6 0h6m-14 1h1m1 0h1m1 0h1m1 0h1m1 0h6m-9 1h2m1 0h6m-9 1h2m1 0h4m1 0h1m-14 1h1m4 0h2m1 0h5m11 0h1m2 0h2m-29 1h2m4 0h1m5 0h1m2 0h1m7 0h1m1 0h1m2 0h1m-26 1h2m1 0h1m4 0h2m1 0h1m4 0h1m2 0h2m3 0h1m-25 1h2m1 0h1m4 0h1m2 0h2m5 0h3m3 0h1m-25 1h4m4 0h2m1 0h1m3 0h4m5 0h1m-23 1h2m6 0h1m4 0h3m5 0h2m-22 1h1m7 0h1m2 0h1m1 0h1m5 0h2m-3 1h2m-5 1h1m1 0h3m-5 1h4m-4 1h1m-2 1h1m2 0h1m-4 1h3m-2 1h1"/><path stroke="#70dbfd" d="M33 3h1m1 0h1m-3 1h3m-3 1h1m1 0h1m-5 1h1m1 0h3m-7 1h2m2 0h1m1 0h1m-6 1h1m2 0h3m-6 1h1m2 0h3m-7 1h4m2 0h1m-6 1h2m3 0h2m1 0h1m-10 1h1m1 0h1m-3 1h1m-1 2h3m-3 1h2m1 0h3m1 0h1m7 0h1m2 0h1m-19 1h2m2 0h4m9 0h3m-20 1h2m3 0h1m1 0h1m1 0h1m3 0h1m7 0h2m-23 1h2m3 0h2m2 0h1m12 0h1m-22 1h7m1 0h1m12 0h1m-21 1h3m1 0h1m1 0h2m6 0h1m3 0h3m-21 1h5m1 0h2m6 0h1m5 0h1m-29 1h1m7 0h3m1 0h1m1 0h1m5 0h1m5 0h1m1 0h1m-28 1h2m5 0h3m4 0h1m5 0h1m-13 1h2m4 0h2m3 0h1m4 0h1m-27 1h1m7 0h4m3 0h1m1 0h2m1 0h2m-22 1h1m8 0h3m3 0h2m1 0h5m-18 1h1m3 0h3m2 0h3m1 0h1m3 0h2m1 0h1m-25 1h1m7 0h3m3 0h4m4 0h5m-23 1h2m8 0h3m8 0h1m-23 1h1m1 0h1m8 0h3m8 0h1m-27 1h6m10 0h4m2 0h1m1 0h2m-26 1h6m9 0h8m1 0h2m-24 1h3m9 0h8m1 0h2m-22 1h4m7 0h2m1 0h7m-21 1h1m2 0h1m7 0h1m1 0h4m1 0h2m6 0h1m-27 1h1m2 0h1m6 0h2m2 0h5m7 0h1m-14 1h3m-4 1h4m-3 1h2m-2 1h2"/><path stroke="#b3ffff" d="M34 5h1m-3 1h1m1 1h1m-2 3h2m-3 1h3m2 0h1m-8 1h1m1 0h7m-9 1h9m-9 1h9m-7 1h7m-4 1h1m1 0h2m-8 1h2m4 0h2m-8 1h3m1 0h1m1 0h1m-7 1h3m2 0h2m-1 1h1m0 6h1m0 1h1m-1 1h1m1 0h3m-17 1h1m13 0h4m-5 1h8m-24 1h1m15 0h8m-11 1h1m4 0h2m1 0h1m-11 1h1m9 0h1m-19 1h1m16 0h1"/><path stroke="#030303" d="M44 15h1m7 3h1m-1 6h1m-3 4h1m-1 1h1m-2 2h1m1 2h1m0 1h1m-2 5h1m-2 1h1m-2 2h1m-2 1h1m0 2h1m-1 1h1m-1 3h1m-2 2h1"/><path stroke="#040505" d="M41 16h1"/><path stroke="#005069" d="M45 16h1m-7 3h1m8 2h1m-26 4h3m-1 1h1m-1 1h1m0 1h1m1 0h1m20 7h1m-1 1h1m-19 1h1m17 0h1m-1 1h1m-2 1h1m-18 1h1m-5 1h1m14 5h1"/><path stroke="#2b8daf" d="M39 20h1m6 0h1m0 15h1m-1 2h1m-1 3h1m-20 1h1m1 0h1m16 3h1"/><path stroke="#010102" d="M22 22h1m2 0h1m-5 5h1m0 2h1m-5 1h1m-4 2h1m-4 3h1m-2 2h1m-3 2h1m2 3h1m5 5h1m1 1h1m1 3h1m-1 1h1m1 3h1m1 3h1m1 2h1"/><path stroke="#020304" d="M27 22h2"/><path stroke="#5abbd9" d="M25 23h1m5 15h1m-3 3h1m15 6h1"/><path stroke="#001" d="M26 23h2m-2 1h1m0 3h1"/><path stroke="#66b9d3" d="M28 23h1m-1 1h1m-3 1h1m1 0h1m-3 1h1m1 0h1m-3 1h1m1 0h1"/><path stroke="#000b1e" d="M27 24h1m-1 1h1m-1 1h1"/><path stroke="#111314" d="M16 31h1"/><path stroke="#eaffff" d="M18 31h4m-4 1h3m-6 1h5m-6 1h3m1 0h2m1 0h1m-9 1h2m1 0h4m1 0h1m-9 1h3m1 0h1m1 0h1m12 0h2m-19 1h3m1 0h1m-9 1h2m1 0h3m1 0h3m-10 1h7m1 0h3m3 0h1m-14 1h2m1 0h4m3 0h4m8 0h1m-19 1h2m4 0h2m1 0h1m9 0h1m-22 1h1m1 0h3m5 0h4m2 0h2m2 0h1m1 0h2m-23 1h2m1 0h3m5 0h2m1 0h2m1 0h3m1 0h2m-22 1h1m1 0h5m1 0h1m1 0h1m1 0h1m3 0h7m-22 1h1m1 0h1m1 0h2m2 0h3m2 0h6m2 0h3m6 0h2m-31 1h3m5 0h1m4 0h2m4 0h4m6 0h2m-29 1h2m9 0h1m5 0h1m1 0h3m4 0h1m-18 1h1m1 0h3m1 0h1m2 0h2m1 0h2m1 0h1m-19 1h1m3 0h1m4 0h2m4 0h4m-17 1h1m2 0h2m2 0h1m1 0h2m4 0h1m-14 1h1m4 0h4m4 0h1m-9 1h5m3 0h2m-10 1h3m2 0h1m1 0h2m-4 1h3"/><path stroke="#95afb1" d="M22 31h1m-2 1h1m-2 1h2m0 1h1m-11 3h2m4 0h1m13 0h2m-17 1h1m7 0h1m-16 1h1m7 0h1m-8 1h1m2 0h1m4 0h3m13 0h1m-24 1h4m2 0h4m4 0h1m-8 1h5m4 0h2m-13 1h1m3 0h5m2 0h1m6 0h1m-19 1h1m5 0h1m1 0h1m1 0h1m1 0h3m-14 1h1m1 0h1m2 0h2m11 0h1m-16 1h5m1 0h1m18 0h1m-25 1h6m15 0h1m3 0h2m-27 1h6m17 0h3m-25 1h3m1 0h1m6 0h1m10 0h2m-24 1h5m8 0h1m7 0h2m-23 1h7m1 0h4m9 0h2m-22 1h11m10 0h1m-21 1h10m3 0h2m4 0h1m-18 1h10m1 0h2m3 0h1m-16 1h6m5 0h4m-15 1h4m8 0h3m-14 1h1m1 0h1m8 0h1m4 0h1m-6 1h1m4 0h1m-4 1h2m-2 1h3m-2 1h2"/><path stroke="#e2f6f6" d="M16 32h1"/><path stroke="#e9fefe" d="M17 32h1"/><path stroke="#fff" d="M17 34h1m2 0h1m-6 1h1m4 0h1m1 0h1m-7 1h1m1 0h1m1 0h3m-9 1h1m5 0h4m-11 1h1m7 0h4m-3 1h3m7 1h2m-10 1h1m6 0h4m1 0h1m-22 1h1m16 0h2m1 0h1m-5 1h1m-4 2h2m7 0h1m-10 1h3m2 0h4m4 0h1m-14 1h3m1 0h5m1 0h1m3 0h1m-15 1h1m1 0h1m3 0h1m1 0h2m2 0h1m2 0h1m-16 1h2m1 0h3m3 0h4m-12 1h2m2 0h2m4 0h4m-4 1h4m-3 1h3m-2 1h1"/><path stroke="#c7e4e6" d="M23 36h1m0 1h1m7 1h2m-1 1h1m5 5h1"/><path stroke="#2b3131" d="M32 39h1m-7 1h1m11 3h1m5 11h1m-19 1h1m16 0h1m-3 2h1m-3 2h2"/><path stroke="#294a4e" d="M48 48h1m-2 1h2m-3 1h2m-2 1h2m-25 1h1m22 0h1m-23 1h1m20 0h1m-21 1h2m10 0h1m-13 1h1m1 0h1m6 0h5m-13 1h2m4 0h8m3 0h2m-18 1h2m1 0h1m1 0h8m2 0h3m-18 1h13m1 0h4m-17 1h11m2 0h1m2 0h2m-17 1h13m3 0h1m-16 1h7m5 0h1"/><path stroke="#000101" d="M24 54h1m20 0h1m-15 8h4"/><path stroke="#2a4b4f" d="M44 55h1"/><path stroke="#020202" d="M45 56h1m0 2h1"/><path stroke="#000202" d="M37 61h1m3 0h1m0 1h1"/><path stroke="#010202" d="M39 61h2m-5 1h1"/></svg>',
        '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 -0.5 64 64"><path stroke="#354332" d="M0 0h37m3 0h24M0 1h36m5 0h23M0 2h34m8 0h22M0 3h33m10 0h21M0 4h31m13 0h20M0 5h30m15 0h19M0 6h29m17 0h18M0 7h28m19 0h1m1 0h15M0 8h28m22 0h14M0 9h28m23 0h13M0 10h27m25 0h12M0 11h26m27 0h11M0 12h25m29 0h10M0 13h23m32 0h9M0 14h22m34 0h8M0 15h21m36 0h7M0 16h21m37 0h6M0 17h21m38 0h5M0 18h20m40 0h4M0 19h19m42 0h3M0 20h17m45 0h2M0 21h16m46 0h2M0 22h15m47 0h2M0 23h14m47 0h3M0 24h11m49 0h4M0 25h10m49 0h5M0 26h10m48 0h6M0 27h10m46 0h8M0 28h9m46 0h9M0 29h7m47 0h10M0 30h6m46 0h12M0 31h4m47 0h13M0 32h3m46 0h15M0 33h2m46 0h16M0 34h1m45 0h18M0 35h2m43 0h19M0 36h3m41 0h20M0 37h4m40 0h20M0 38h5m39 0h20M0 39h6m39 0h19M0 40h6m41 0h17M0 41h7m42 0h15M0 42h7m43 0h14M0 43h7m43 0h14M0 44h8m42 0h14M0 45h9m41 0h14M0 46h10m41 0h13M0 47h11m41 0h12M0 48h11m41 0h12M0 49h10m42 0h12M0 50h10m42 0h12M0 51h10m41 0h13M0 52h10m40 0h14M0 53h10m39 0h15M0 54h10m35 0h19M0 55h10m39 0h15M0 56h10m40 0h14M0 57h9m41 0h14M0 58h9m40 0h15M0 59h9m38 0h17M0 60h10m35 0h19M0 61h13m30 0h21M0 62h14m27 0h23M0 63h23m14 0h27"/><path stroke="#010101" d="M37 0h2m-5 2h1m-2 1h1m-3 1h1m-2 1h1m13 0h1m0 1h1m0 1h1m1 0h1M28 8h1m17 0h1m2 0h1M28 9h2m20 0h1m-24 1h1m2 0h1m20 0h1m-26 1h1m26 1h1m-31 1h1m-2 1h1m-2 1h1m-1 1h1m-1 1h1m-2 1h1m39 1h1m-44 1h1m43 0h1m-46 1h1m44 0h1m-2 2h1m-49 1h2m45 0h1m-4 2h1m-47 1h1m44 0h1M9 28h2m-4 1h1m44 0h1M4 31h1m44 0h1M3 32h1m44 0h1m-10 1h1m6 0h2M1 34h1m38 0h1m4 0h1M2 35h1m38 0h2m1 0h1m-2 1h1m-1 1h1M5 38h1m0 1h1m37 0h1m0 1h2m1 1h1M7 42h1m41 1h1m-1 2h1m-40 1h1m39 0h1m-40 1h1m39 0h1m-41 1h1m39 0h1m-42 1h1m40 0h1m-1 1h1m-2 1h1m-2 1h1m-40 1h1m35 0h1m1 0h1m-39 1h1m33 1h3m1 0h1m0 2h1m-3 1h1m-3 1h2m-37 1h2m30 1h1m-29 1h1m25 0h1m-9 1h5"/><path stroke="#000" d="M39 0h1m-4 1h1m3 0h1m-6 1h1m5 0h1m0 1h1M32 4h1m10 0h1M29 6h1m-2 1h1m16 0h1M29 8h1m17 0h1M30 9h1m15 0h1m-19 1h2m22 1h1m-28 1h1m-2 1h1m29 0h1m0 1h1m0 1h1m-35 1h1m34 0h1m-36 1h2m34 0h1m0 1h1m-41 1h1m-2 1h1m-4 2h1m45 0h1m-48 1h1m-4 1h1m-2 1h1m47 0h1m-49 1h1m46 0h1m-4 2h1M8 29h1m44 0h1M6 30h1m44 0h1M5 31h1m44 0h1M2 33h1m0 3h1m0 1h1m38 1h1M6 40h1m0 1h1m41 1h1M7 43h1m0 1h1m40 0h1M9 45h1m1 1h1m-2 4h1m-1 1h1m-1 1h1m34 1h1m1 0h1m-4 1h1m-35 1h1m36 0h1m-38 1h1m38 0h1M9 57h1m-1 1h1m38 0h1M9 59h1m2 1h1m30 0h2m-32 1h1m27 0h1m-27 1h1m3 0h3m15 0h3m-17 1h9"/><path stroke="#de95de" d="M37 1h3m-4 1h2m1 0h2m-7 1h3m3 0h2m-9 1h1m6 0h3M31 5h2m8 0h3M30 6h1m11 0h3M29 7h1m14 0h1m-1 2h1m-18 2h2m-3 1h1m4 0h1m20 0h1m-28 1h1m4 0h1m22 0h1m-31 1h2m3 0h2m24 0h1m-33 1h2m3 0h1m25 0h3m-33 1h4m25 0h1m1 0h3m-33 1h1m10 0h1m17 0h1m1 0h3m-37 1h1m12 0h1m19 0h1m1 0h3m-39 1h1m11 0h2m21 0h1m1 0h3m-41 1h1m2 0h2m7 0h2m22 0h2m1 0h2m-43 1h2m2 0h1m7 0h2m25 0h2m1 0h1m-44 1h1m2 0h2m7 0h2m28 0h2m-45 1h1m2 0h2m6 0h3m8 0h1m19 0h2m-42 1h1m7 0h2m10 0h2m17 0h2m-42 1h1m7 0h2m10 0h2m17 0h2m-34 1h1m11 0h4m15 0h2m-35 1h2m13 0h2m1 0h1m13 0h2m-35 1h1m16 0h2m1 0h1m10 0h3m-36 1h2m18 0h2m1 0h1m8 0h2m-35 1h2m17 0h1m2 0h2m1 0h1m5 0h3m-14 1h1m2 0h2m1 0h1m3 0h2m-11 1h1m2 0h2m2 0h3m-6 1h4m-13 1h1m9 0h2"/><path stroke="#7c426f" d="M38 2h1m-2 1h3m-6 1h4m-4 1h2m-5 1h1m2 0h1m6 0h1M31 7h1m10 0h2M30 8h2m11 0h3M31 9h1m13 0h1m-2 1h1m-23 8h1m-2 1h2m-3 1h1m-2 1h1m-3 1h2m21 0h1m-25 1h1m22 0h1m-26 1h2m17 1h1m-2 1h2m-14 1h1m9 0h1m-12 1h1m9 0h1m-4 2h1m11 1h1m-16 1h1m-5 3h1m-6 1h1m3 0h1m-4 2h2"/><path stroke="#cc88c0" d="M38 4h1m-6 1h1m2 0h2m-6 1h1m3 0h1m-7 1h1m3 0h2m-3 1h1m-2 1h1m10 0h1m-13 1h1m-3 1h1m13 0h1m-17 1h1m1 0h1m21 0h1m-26 1h1m1 0h1m-2 1h1m-3 1h2m13 0h1m6 0h1m-4 1h1m3 0h1m-24 1h1m23 0h1m0 1h1m-13 1h1m12 0h1m-22 1h1m3 0h2m16 0h1m-31 1h1m9 0h3m6 0h2m9 0h2m-23 1h3m7 0h2m11 0h1m-25 1h2m6 0h1m15 0h2m-28 1h3m-4 1h2m-3 1h2m-4 1h3m4 0h2m-12 1h1m1 0h2m5 0h1m-10 1h3m4 0h2m3 0h2m-15 1h3m4 0h1m4 0h2m-15 1h2m4 0h2m3 0h2m-14 1h2m4 0h2m3 0h1m-13 1h1m4 0h2m3 0h2m-14 1h2m4 0h2m3 0h2m-13 1h1m4 0h2m3 0h1m6 0h1m-14 1h1m3 0h2m-3 1h2m-3 1h1"/><path stroke="#e37dd3" d="M39 4h1m0 1h1M23 22h2m-3 1h1m-3 1h2m-2 1h1m14 6h1m-2 1h1m1 0h1m-4 1h1m3 0h1m-6 1h1"/><path stroke="#ae86c7" d="M38 5h1m10 6h1m-1 1h1m-11 9h1m0 2h1m2 1h2m-2 1h2m6 0h1m-10 1h2m1 0h2m4 0h1m-10 1h1m2 0h1m-3 1h2"/><path stroke="#503a5f" d="M39 5h1m-5 1h1m4 0h1m-5 2h1m-3 1h2m-4 1h1m1 0h1m-2 1h1m2 0h1m10 0h2m-21 1h1m1 0h1m1 0h1m1 0h1m2 0h1m6 0h1m1 0h3m1 0h1m-24 1h1m1 0h1m1 0h1m3 0h2m8 0h2m2 0h2m1 0h1m-28 1h2m8 0h1m9 0h1m1 0h1m1 0h1m2 0h2m-30 1h1m3 0h1m16 0h2m5 0h1m-26 1h1m4 0h1m18 0h1m1 0h1m-23 1h1m22 0h1m-32 1h1m2 0h1m26 0h1m1 0h1m-32 1h2m30 0h1m0 1h1m2 0h1m-3 1h1m1 0h1m-25 1h2m18 0h2m2 0h1m-25 1h1m22 0h1m-2 1h1m-25 1h2m2 0h1m18 0h1m-20 2h1m0 1h1m0 1h1m0 1h1m-6 1h1m2 0h1m2 0h1m-6 1h1m2 0h1m0 1h1m0 1h1m0 1h1"/><path stroke="#8f62a9" d="M33 6h1m-1 1h1m5 1h1m-1 1h1m1 0h1m-2 1h1m1 0h1m-13 1h1m8 0h1m1 0h2m-3 1h1m1 0h2m-5 1h1m1 0h1m2 0h1m6 0h1m-14 1h1m1 0h1m9 0h1m-14 1h1m1 0h1m-2 1h1m6 0h1m-6 1h1m4 0h1m1 1h1m-20 1h1m15 0h1m1 0h1m1 0h1m-22 1h1m13 0h1m5 0h1m-20 1h1m19 0h1m-4 1h1m-3 1h1m8 0h1m-13 1h2m-23 1h1m19 0h1m-22 1h1m12 4h1m13 0h1"/><path stroke="#141117" d="M37 6h2m-3 1h3m-5 1h2m1 0h2m-6 1h1m2 0h2m-5 1h1m1 0h2m-3 1h2m1 0h1m-5 1h1m1 0h1m-4 1h3m-5 1h5m1 0h1m14 0h1m-23 1h4m2 0h2m13 0h1m-23 1h4m1 0h2m1 0h1m-11 1h3m1 0h1m1 0h2m-10 1h2m1 0h1m3 0h1m-6 1h2m1 0h2m-3 1h1m-3 1h2m7 0h2m-12 1h2m7 0h2m-12 1h1m8 0h3m-17 1h1m3 0h1m8 0h3m20 0h1m-38 1h1m2 0h2m7 0h3m8 0h2m-26 1h1m2 0h1m8 0h3m2 0h1m4 0h3m-24 1h2m7 0h3m4 0h2m4 0h2m-24 1h1m7 0h3m6 0h2m4 0h2m2 0h1m-22 1h4m8 0h2m4 0h3m-29 1h1m6 0h3m11 0h2m4 0h1M8 31h3m11 0h3m-5 1h3m-8 1h1m3 0h3m-4 1h3m-5 1h3m-4 1h3m-3 1h3m0 3h2m4 6h2m-3 1h4m-5 1h6m-7 1h8m4 0h1m-14 1h1m3 0h2m2 0h2m2 0h3m-15 1h1m1 0h1m6 0h3m2 0h2m-14 1h2m10 0h1m-11 1h1m8 0h1m-9 1h1m2 3h1m-15 1h1m14 0h1m-15 1h2m11 0h1m-13 1h1"/><path stroke="#da9cec" d="M39 6h1m0 1h1m0 1h1m6 0h1M38 9h1m1 0h1m1 0h1m4 0h3m-11 1h1m1 0h1m1 0h1m1 0h6m-13 1h1m1 0h1m3 0h3m3 0h2m-13 1h1m1 0h1m3 0h1m-8 1h1m1 0h1m1 0h2m-5 1h1m1 0h4m-7 1h1m2 0h2m-6 1h1m1 0h1m2 0h2m-7 1h3m3 0h2m-7 1h3m3 0h1m-6 1h2m4 0h1m-7 1h2m4 0h2m-7 1h1m5 0h2m-1 1h2m-13 2h1"/><path stroke="#7e5591" d="M32 7h1m8 0h1M32 8h1m9 0h1m-6 6h1m-4 1h1m8 0h1m-9 1h1m4 0h1m-7 1h1m6 0h1m-10 1h1m4 0h1m3 0h1m1 0h1m-13 1h1m-3 1h1m19 0h1m0 1h1m-24 1h1m15 0h1m5 0h1m-25 1h1m16 0h1m1 0h1m-21 1h1m14 0h1m5 0h1m4 0h1m2 0h2m-32 1h1m16 0h1m5 0h1m5 0h2m-33 1h2m29 0h1m-3 1h1m-2 1h1m-3 1h1m-2 1h1m-3 1h1"/><path stroke="#3b2e4f" d="M39 7h1m0 1h1m-4 2h2m-1 2h1m-2 1h1m6 2h1m3 0h2m-9 1h1m4 0h2m2 0h1m-9 1h1m3 0h1m-5 1h1m2 0h2m-6 1h2m4 0h1m-6 1h1m5 0h1m4 0h1m-5 1h1m4 0h1m0 1h1m-8 1h1m-14 1h1m9 1h1m-2 1h1m-2 1h2"/><path stroke="#281d2b" d="M31 11h2m3 1h1m-4 3h1m-5 2h1m18 0h1m-21 1h3m18 0h1m-27 1h1m11 0h1m14 0h1m2 0h1m-33 1h1m2 0h3m17 0h1m9 0h1m-32 1h2m20 0h1m9 0h1m-35 1h2m27 0h1m-34 1h1m2 0h1m2 0h1m17 0h1m5 0h1m5 0h1m-38 1h1m1 0h1m3 0h1m19 0h1m8 0h1m-2 1h1m3 0h1m-36 1h1m33 0h1m-21 1h1m18 0h1m-37 1h2m7 0h1m5 0h4m-20 1h2m13 0h3m16 0h1m-38 1h1m1 0h2m12 0h3m3 0h2m-22 1h3m4 0h1m6 0h2m2 0h1m1 0h1m-21 1h3m9 0h2m3 0h1m1 0h1m5 0h1m-26 1h1m9 0h3m3 0h3m7 0h1m-24 1h1m5 0h3m4 0h2m6 0h2m1 0h1m-20 1h2m5 0h1m6 0h1m1 0h3m-21 1h3m2 0h1m10 0h2m2 0h2m-23 1h3m2 0h1m12 0h2m2 0h2m-21 1h1m2 0h1m13 0h1m2 0h1m-19 1h1m17 0h2m-1 1h2m-3 1h1m1 0h3m-6 1h3m2 0h1m-4 1h2m-2 1h2m-1 1h1m-32 1h1m3 0h1m-6 1h1m-1 1h1m-2 1h1m3 1h1m5 0h3m-9 1h2m4 0h1m1 0h2m-4 1h1m9 0h2m-10 1h1m8 0h1m-10 1h2m14 0h1m0 1h2m-30 1h1m8 0h1m17 0h1m6 0h1m-35 1h1m7 0h1m6 1h2m10 0h1m-22 1h4m16 0h2m4 0h1m-27 1h1m1 0h2m5 0h1m10 0h1m1 0h3m-21 1h1m2 0h3m9 0h2m1 0h1m-17 1h5m7 0h1"/><path stroke="#ceb5f4" d="M47 13h2m-3 1h1m1 0h1m-12 5h1m-1 1h2m-2 1h2m-1 1h2m9 4h2m-3 1h2m-3 1h2m-3 1h1"/><path stroke="#9c78b2" d="M51 15h1m-3 1h1m0 1h1m0 1h1m0 1h1m-2 1h1m-27 1h1m27 1h1m2 1h1m-22 6h1m-3 2h1m-4 1h1m1 0h1m-4 1h1m-2 1h1m-2 1h1m-2 1h1m-2 1h1m-3 1h2"/><path stroke="#432637" d="M36 17h1m-4 1h1m1 0h2m-3 1h1m-2 1h1m-14 1h1m10 0h1m-2 1h1m-10 1h1m7 0h1m-3 1h1m-11 1h1m8 0h1m-3 1h2m-3 1h1m-2 1h1m-3 1h1m-2 1h1"/><path stroke="#2e2641" d="M47 17h1m0 1h1m-6 1h1m5 0h1m-7 1h1m6 0h1m-8 1h2m6 0h1m-8 1h1m1 0h1m4 0h2m-8 1h2m2 0h3m-6 1h4m2 0h1m-6 1h3m-3 1h1m0 31h1"/><path stroke="#5d6b6f" d="M51 17h2m-1 1h1m1 1h1M39 36h1m0 1h1m0 1h1m2 4h2m-1 1h1m1 1h1m-1 3h1m-34 2h1m11 1h2m-15 1h2m4 0h1m5 0h1m2 0h1m15 0h1m-32 1h3m4 0h1m3 0h1m1 0h1m2 0h1m13 0h1m-30 1h1m6 0h1m3 0h3m2 0h1m7 0h1m-24 1h1m6 0h1m4 0h2m2 0h1m5 0h1m2 0h1m2 0h1m-28 1h1m6 0h3m2 0h2m2 0h1m5 0h1m-22 1h1m1 0h1m2 0h1m6 0h3m1 0h1m8 0h2m-21 1h1m6 0h1m1 0h1m2 0h1m7 0h2m-26 1h3m2 0h1m1 0h1m4 0h1m2 0h2m5 0h1m-20 1h1m2 0h1m4 0h1m2 0h2m2 0h1m2 0h1m-24 1h1m1 0h1m3 0h1m1 0h2m2 0h1m3 0h1m2 0h1m2 0h1m-21 1h3m2 0h1m5 0h1m3 0h2m3 0h1m-9 1h1"/><path stroke="#343124" d="M36 19h1m-1 1h1m-5 3h1m-2 1h1m-3 1h1m-2 1h1m-11 5h1m8 0h1m-10 2h1m-5 1h1m19 0h1m1 0h1m-23 1h1m15 0h1m2 0h1m-6 1h2m5 0h1m-18 1h1m8 0h1m4 0h1m3 0h1m-11 1h1m5 0h1m2 0h2m1 0h1m-21 1h1m4 0h1m1 0h1m3 0h1m1 0h1m1 0h1m-11 1h2m1 0h1m1 0h1m1 0h1m1 0h1m-14 1h2m4 0h1m2 0h1m1 0h2m-12 1h2m3 0h1m1 0h1m1 0h1m2 0h1m-23 1h1m10 0h2m3 0h1m1 0h1m-18 1h1m22 0h2m0 1h1m-1 1h2m-5 1h1m3 0h2m-18 1h1m13 0h1m-21 1h1m4 0h1m18 0h2m-25 1h1m1 0h2m20 0h2m-25 1h2m-3 1h1m-1 1h1m0 1h1m0 1h1m-6 4h1m-1 1h1m0 1h5"/><path stroke="#6c4c3c" d="M11 25h2m-1 1h2m0 1h1m-2 3h1m-1 1h1m21 1h1m0 1h1m1 0h1m-2 1h1m-3 9h1m-26 1h1"/><path stroke="#ecc281" d="M13 25h2m-4 1h1m2 0h2m-4 1h2m1 0h1m-3 1h2m2 10h2m-2 1h1"/><path stroke="#494d3d" d="M15 25h1m0 1h1m-6 1h1m4 0h1m-5 1h1m2 0h1m-3 1h2m-6 1h1m-4 1h2m3 0h1m-7 1h1m4 0h1m2 0h1M3 33h1m2 0h2m1 0h1m2 0h2M4 34h1m2 0h1m1 0h1m2 0h1m-8 1h1m2 0h1m1 0h1m-5 1h1m2 0h1m1 0h1m-5 1h1m2 0h1m1 0h1m-5 1h1m2 0h3m23 0h1M9 39h1m2 0h3m23 0h3M7 40h1m2 0h1m3 0h2m23 0h3M8 41h1m2 0h1m3 0h1m21 0h1m1 0h3M9 42h1m2 0h1m5 0h1m21 0h1m7 0h1m-36 1h2m2 0h2m1 0h1m19 0h3m-27 1h1m10 0h1m1 0h1m11 0h2m2 0h1m-34 1h1m1 0h2m12 0h1m13 0h2m2 0h1m-35 1h1m20 0h1m13 0h1m-16 1h1m1 0h1m13 0h1m-19 1h3m16 0h1m-19 1h1m16 0h1m-10 1h1m7 0h1m-37 1h1m28 0h1m-30 1h1m6 0h1m11 0h1m4 0h1m5 0h1m-23 1h1m2 0h1m8 0h1m2 0h1m7 0h1m-23 1h1m11 0h2m9 1h1m-9 1h1m1 0h1m-23 1h1m11 0h1m6 0h1m1 0h1m2 0h1m1 0h1m-26 1h1m16 0h1m6 0h1m1 0h1m2 0h1m-32 1h1m17 0h1m10 0h1m-30 1h2m16 0h1m4 0h1m-5 1h1m2 0h1m-3 1h2"/><path stroke="#8fafc8" d="M48 26h1m-2 1h1m-2 1h1m-2 1h1m-2 1h1M17 41h1m-3 1h2m30 0h1m-2 1h1m1 0h1m-1 2h1m0 1h1m-36 4h1m26 1h1m-15 1h1m0 1h1m0 1h1m0 1h1m5 0h1m2 0h1m2 0h1m-3 1h2m2 0h1m3 0h1m-23 1h1m11 0h1m1 0h1m1 0h1m-6 1h2m4 0h1m-8 1h1m4 0h2m-12 1h1m3 0h1m-4 1h1m0 1h1"/><path stroke="#a46864" d="M17 27h1m-1 2h1m-1 2h1m-1 1h1m10 0h1m-13 1h1m7 2h1m12 0h1"/><path stroke="#273541" d="M46 27h1M32 51h2m-1 1h1m-8 2h1m0 1h1m5 0h1m-6 1h1m3 0h1m14 0h1m-19 1h1m1 0h1m-2 1h1m-2 1h1m-2 1h1m-1 1h2m-1 1h2"/><path stroke="#2a1e2d" d="M51 27h1m-2 1h1m-3 1h1m-2 1h1m-3 1h2m-4 1h2m-19 3h1M16 47h1m-2 1h1m34 2h1m-2 1h1m-2 1h1m-38 3h1m10 0h1m-12 1h1m10 4h1m0 1h1m-1 1h1"/><path stroke="#9b9235" d="M11 28h1m-3 1h2m-4 1h2m22 6h1m-2 1h1m4 0h1m-7 1h1m3 0h2m-13 1h1m7 0h1m1 0h1m-11 1h1m8 0h1m-9 1h1m3 2h1m5 0h1m-15 1h1m5 0h1m6 0h1m-9 1h1m6 0h1m8 0h1m-18 1h1m6 0h1m12 0h1m-22 1h1m19 0h1m-26 2h1"/><path stroke="#161317" d="M11 29h1m-2 1h1"/><path stroke="#272015" d="M12 29h1m-2 1h1m-6 2h3m20 2h1m-2 1h1m-2 1h1m-2 1h1m8 3h2m-4 1h4m-4 1h2m1 0h2m-7 1h2m1 0h1m2 0h2m-9 1h2m6 0h2m-24 1h3m10 0h2m4 0h1m3 0h1m-26 1h2m13 0h1m10 0h1m-28 1h2m26 0h1m-29 1h1m24 0h2m-28 1h1m-2 1h2"/><path stroke="#d3d3a5" d="M12 31h1m-2 1h2m-5 1h1m1 0h2m-2 1h2m-1 1h1m19 0h1m2 0h1m-23 1h1m17 0h1m3 0h1m-24 1h1m1 0h1m14 0h2m1 0h1m-18 1h1m4 0h2m6 0h1m2 0h1m-12 1h3m4 0h1m9 0h2m-18 1h2m3 0h1m11 0h2m-18 1h2m1 0h1m13 0h1m-20 1h1m2 0h2m11 0h1m3 0h1m-21 1h1m3 0h3m10 0h1m-17 1h5m1 0h1m9 0h2m-19 1h2m1 0h2m1 0h3m4 0h2m3 0h2m2 0h1m-24 1h2m1 0h2m3 0h3m2 0h2m1 0h1m3 0h2m2 0h1m-26 1h2m1 0h2m5 0h5m3 0h1m3 0h2m-25 1h2m1 0h2m7 0h2m3 0h2m11 0h2m-32 1h1m1 0h2m9 0h2m1 0h1m1 0h1m10 0h1m4 0h1m-34 1h1m12 0h2m12 0h1m4 0h1m-2 1h1m-2 1h1m-4 6h1"/><path stroke="#c1dbda" d="M4 32h1m0 1h1m-4 1h2m1 0h2m-4 1h2m1 0h2m-4 1h2m1 0h2m-4 1h2m1 0h2m-4 1h2m1 0h2m-4 1h2m1 0h2m-4 1h2m1 0h2m-4 1h2m1 0h2m-4 1h2m1 0h2m2 0h1m-7 1h2m2 0h2m-5 1h4m-3 1h1m31 1h2m-3 1h2m-3 1h2m-3 1h2m-2 1h1m3 0h1m-4 1h1m1 0h1m-2 1h1m-22 4h2m-4 1h2m1 0h2m-4 1h2m1 0h1m-3 1h2"/><path stroke="#b5b38a" d="M9 32h1m24 1h2M8 34h1m4 0h1m-5 1h1m2 0h1m-3 1h1m2 0h1m0 1h1m0 2h1m-3 1h1m2 0h1m-3 1h1m1 0h1m1 0h1m19 1h1m0 1h1m-7 1h1m6 0h1m-7 1h1m10 0h1m-11 1h1m8 0h1m-9 1h1m6 0h1m-7 1h1m2 0h1m1 0h1m-8 1h1m5 0h1m-6 1h1m0 1h1m0 1h1"/><path stroke="#7e857d" d="M4 33h1m12 11h2m27 3h1m-2 1h1m-2 1h1m-2 1h1m-2 1h1m3 0h1m-30 1h1m27 0h1m-28 1h1m25 0h1m-26 1h1m0 1h1m-11 2h2m1 0h1m-4 1h1m1 0h2m-4 1h3"/><path stroke="#b1a74d" d="M35 34h1m-1 1h1m-4 1h2m-1 1h2m-7 1h1m2 0h1m-16 1h1m10 0h2m-12 1h1m9 0h1m1 0h1m-4 1h2m1 0h1m-6 1h1m1 0h1m1 0h1m-8 3h1m-2 1h1m20 0h1m-23 1h1m-2 1h1"/><path stroke="#dfd443" d="M13 35h1m20 4h2m-3 1h2m-3 1h1m-3 1h2m-3 1h2m-3 1h1"/><path stroke="#e2decc" d="M38 36h1m0 1h1m0 1h1m0 1h1m0 1h1m0 1h1m3 2h1m-2 1h1m1 0h1m-2 1h1m0 1h1m0 1h2m-3 1h1m1 0h1m-5 1h2m1 0h1m-5 1h1m2 0h1m-2 1h1m-2 1h1"/><path stroke="#000001" d="M42 36h1m4 5h1M16 62h3m3 0h1"/><path stroke="#3b452d" d="M8 42h1m-1 1h2m-1 1h1m0 1h2"/><path stroke="#333936" d="M16 46h1m-2 1h1m-2 1h1m-2 1h1m24 0h1m-26 1h1m21 0h1m0 1h1m-18 1h1m17 0h1m-27 1h2m2 0h1m4 0h1m-9 1h2m2 0h1m4 0h1m-9 1h2m2 0h1m3 0h1m-8 1h2m4 0h1m-5 1h1m1 0h2m-9 1h1m5 0h2m-2 1h1"/><path stroke="#d9fafb" d="M36 48h1m0 1h1m0 1h1m-12 1h1m11 0h1m-12 1h1m7 0h1m3 0h1m-12 1h1m5 0h1m3 0h1m-10 1h1m3 0h1m3 0h1m-8 1h1m3 0h1m1 0h1m-2 1h1"/><path stroke="#7495a0" d="M41 48h1m-6 1h1m0 1h1m-12 1h1m11 0h1m-14 1h1m13 0h1m-4 1h2m-27 1h1m23 0h2m-25 1h1m13 0h1m7 0h1m-22 1h1m12 0h2m-14 1h1m30 0h1m1 0h1m-33 1h1m30 0h1"/><path stroke="#76a182" d="M12 51h1m-1 1h1m0 1h1m3 0h1m-4 1h1m3 0h1m-4 1h1m3 0h1m-4 1h1m1 0h1m-2 1h1"/><path stroke="#a0c5e1" d="M42 52h1m-3 1h2m1 0h1m-3 1h2m-18 2h1m8 0h1m3 0h1m6 0h1m-13 1h1m3 0h1m8 0h1m-15 1h1m3 0h1m-11 1h2m3 0h1m3 0h1m-12 1h1m5 0h1m3 0h1m-4 1h1m0 1h1"/></svg>',
        '<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="crispEdges" viewBox="0 -0.5 64 64"><path stroke="#354332" d="M0 0h31m4 0h29M0 1h29m7 0h28M0 2h28m9 0h27M0 3h27m10 0h27M0 4h26m12 0h26M0 5h25m14 0h25M0 6h24m17 0h23M0 7h23m20 0h21M0 8h22m22 0h20M0 9h22m23 0h19M0 10h21m25 0h18M0 11h21m25 0h18M0 12h20m27 0h17M0 13h20m27 0h17M0 14h19m28 0h17M0 15h19m28 0h17M0 16h18m30 0h16M0 17h18m30 0h16M0 18h17m31 0h16M0 19h17m31 0h16M0 20h17m31 0h16M0 21h17m31 0h16M0 22h17m31 0h16M0 23h17m31 0h16M0 24h17m31 0h16M0 25h17m31 0h16M0 26h17m31 0h16M0 27h17m31 0h16M0 28h16m32 0h16M0 29h16m32 0h16M0 30h16m32 0h16M0 31h16m32 0h16M0 32h16m32 0h16M0 33h16m32 0h16M0 34h16m32 0h16M0 35h16m32 0h16M0 36h16m32 0h16M0 37h16m32 0h16M0 38h16m32 0h16M0 39h16m32 0h16M0 40h16m32 0h16M0 41h16m32 0h16M0 42h17m31 0h16M0 43h17m31 0h16M0 44h17m31 0h16M0 45h17m31 0h16M0 46h17m31 0h16M0 47h17m31 0h16M0 48h17m31 0h16M0 49h18m30 0h16M0 50h18m29 0h17M0 51h18m29 0h17M0 52h19m28 0h17M0 53h19m28 0h17M0 54h20m27 0h17M0 55h20m26 0h18M0 56h21m25 0h18M0 57h22m24 0h18M0 58h23m22 0h19M0 59h24m20 0h20M0 60h25m17 0h22M0 61h26m14 0h24M0 62h27m12 0h25M0 63h29m7 0h28"/><path stroke="#030201" d="M31 0h1m-2 1h1M19 52h1m0 2h1m15 8h1"/><path stroke="#010100" d="M32 0h1"/><path stroke="#000" d="M33 0h1m-6 2h1m-2 1h1m8 0h1M26 4h1m10 0h1m0 1h1m0 1h1m1 1h1m1 1h1M22 9h1m-2 2h1m23 0h1m-26 2h1m25 0h1m-1 1h1m-28 1h1m26 0h1m-29 2h1m-2 5h1m-1 4h1m-1 1h1m-2 7h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m0 3h1m-1 1h1m0 6h1m-1 1h1m27 0h1m-29 1h1m27 0h1m-1 1h1m-28 1h1m26 0h1m-2 2h1m-25 1h1m23 0h1m-24 1h1m0 1h1m0 1h1m17 0h1m-3 1h1m-13 2h1m8 0h1m-7 1h4"/><path stroke="#010101" d="M34 0h1m-6 1h1m5 0h1m0 1h1M25 5h1m-2 1h1m15 0h1M23 7h1m18 0h1M22 8h1m21 1h1m-24 1h1m23 0h1m-26 2h1m25 0h1m-28 2h1m-2 2h1m28 0h1m-1 1h1m-31 1h1m29 0h1m-31 1h1m29 0h1m-31 1h1m29 0h1m-31 1h1m29 0h1m-1 1h1m-31 1h1m29 0h1m-31 1h1m29 0h1m-31 1h1m29 0h1m-1 1h1m-1 1h1m-32 1h1m30 0h1m-32 1h1m30 0h1m-32 1h1m30 0h1m-32 1h1m30 0h1m-32 1h1m30 0h1m-32 1h1m30 0h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-1 1h1m-32 1h1m30 0h1m-32 1h1m30 0h1m-1 1h1m-1 1h1m-31 1h1m29 0h1m-31 1h1m29 0h1m-31 1h1m29 0h1m-31 1h1m29 0h1m-31 1h1m29 0h1m-1 1h1m-2 5h1m-27 1h1m24 2h1m-2 1h1m-2 1h1m-19 1h1m15 0h1m-16 1h1m12 0h1m-13 1h1m10 0h1m-10 1h2m4 0h1"/><path stroke="#ebc168" d="M31 1h1m-3 1h2m-3 1h3m-4 1h1m-2 1h1m-2 1h1m2 0h1m-6 2h1m3 0h1m-2 2h1m-4 3h1m-3 1h1m1 0h1m-3 1h2m-3 1h3m-3 1h2m-2 1h1m20 0h2m-25 1h3m20 0h2m-25 1h3m20 0h2m2 0h1m-28 1h3m20 0h2m-25 1h3m20 0h4m-27 1h3m20 0h4m-27 1h2m21 0h4m-27 1h2m11 0h1m9 0h4m-27 1h2m6 0h1m15 0h3m-27 1h1m24 0h3m-29 1h2m18 0h1m5 0h2m-28 1h2m24 0h2m-28 1h1m26 0h1m-28 1h1m18 0h1m4 0h3m-3 1h3m-27 1h2m22 0h2m-2 1h2m1 0h1m-28 1h1m9 0h1m12 0h5m-28 1h1m24 0h3m-28 1h1m17 0h1m6 0h3m-28 1h1m1 0h1m22 0h4m-29 1h1m1 0h2m20 0h5m-29 1h1m5 0h1m13 0h1m4 0h4m-29 1h1m2 0h1m21 0h4m-3 1h3m-25 1h1m21 0h4m-26 1h1m21 0h2m-18 1h1m9 0h2m4 0h2m-27 1h1m3 0h1m1 0h1m13 0h1m5 0h1m-24 1h1m1 0h2m-7 1h7m-6 1h7m12 0h1m-20 1h7m8 0h1m3 0h1m5 0h1m-26 1h7m7 0h3m2 0h1m4 0h3m-26 1h6m12 0h1m4 0h3m-26 1h7m5 0h2m4 0h1m4 0h3m-25 1h6m1 0h7m3 0h1m4 0h3m-25 1h3m4 0h2m1 0h6m1 0h1m4 0h2m-23 1h3m1 0h1m3 0h3m2 0h5m3 0h2m-22 1h1m1 0h1m4 0h2m3 0h5m3 0h2m-21 1h1m4 0h1m1 0h1m3 0h3m5 0h1m-19 1h1m2 0h3m3 0h4m-10 1h3m2 0h5m-9 1h2m3 0h4m-9 1h6"/><path stroke="#a9958a" d="M32 1h1m0 2h1m-1 1h1m1 0h1m-6 1h3m1 0h3m-7 1h3m1 0h2m-7 1h1m1 1h1m-4 1h1m6 0h1m1 0h1m-2 1h2m-10 1h3m3 0h1m1 0h3m-11 1h10m-9 1h7"/><path stroke="#716059" d="M33 1h1m3 4h1m-1 3h1m-10 2h4m6 3h1"/><path stroke="#543729" d="M34 1h1m-3 1h1m2 0h1m-4 1h1m-1 1h1m0 1h1m2 2h1m-5 3h1m-2 4h1m2 0h2"/><path stroke="#955c27" d="M31 2h1m-3 3h1m-2 2h1m-3 4h1m11 21h1m-1 1h1m-21 5h1m-1 2h1m-1 5h1m2 1h1m-2 1h1"/><path stroke="#7e6c64" d="M33 2h1m-3 1h1m2 0h1m-4 1h1m2 0h1m-2 2h1m2 0h1m-7 1h6m-7 1h2m1 0h5m-8 1h6m1 0h1m-4 1h3m-5 1h3m1 0h1m2 1h1m-3 1h2"/><path stroke="#6a564b" d="M34 2h1m0 1h1m0 1h1m1 2h1m-1 4h1m5 2h1m-6 1h3"/><path stroke="#a6672c" d="M28 4h2m-3 1h2m-3 1h2m-4 1h2m1 0h1m-4 1h1m1 0h1m-3 1h3m-5 1h1m1 0h2m-4 1h2m1 0h1m-5 1h3m1 0h1m-5 1h2m3 0h1m-5 1h1m-3 1h1m4 0h2m17 0h1m-22 1h1m2 0h1m16 0h3m-27 1h1m2 0h1m12 0h2m3 0h1m1 0h4m-28 1h1m2 0h5m8 0h2m2 0h1m4 0h3m-25 1h5m7 0h3m2 0h1m4 0h3m-25 1h6m6 0h4m1 0h1m4 0h2m-24 1h2m1 0h1m1 0h1m5 0h7m5 0h2m-25 1h2m7 0h3m1 0h5m6 0h1m-25 1h2m6 0h11m5 0h1m-26 1h1m3 0h1m2 0h10m1 0h1m6 0h1m-26 1h5m3 0h3m1 0h9m4 0h1m-26 1h6m1 0h6m3 0h1m2 0h2m4 0h1m-27 1h3m4 0h3m2 0h1m6 0h2m6 0h1m-28 1h3m7 0h3m4 0h1m1 0h2m5 0h2m-28 1h3m6 0h4m4 0h4m-20 1h2m7 0h3m1 0h1m2 0h1m1 0h2m5 0h2m-28 1h5m4 0h3m3 0h2m1 0h2m6 0h1m-26 1h1m2 0h1m3 0h5m1 0h4m8 0h1m-26 1h1m2 0h1m3 0h7m1 0h2m8 0h2m-30 1h1m1 0h3m5 0h10m8 0h2m-28 1h1m1 0h1m6 0h10m-19 1h3m2 0h1m4 0h8m9 0h1m-26 1h1m1 0h1m1 0h10m1 0h2m-15 1h1m2 0h11m-10 1h10m-10 1h10m1 0h1m-12 1h10m1 0h1m1 0h1m-14 1h12m-12 1h12m-17 1h1m4 0h8m1 0h2m-19 1h1m1 0h1m9 0h1m1 0h3m10 0h1m-28 1h2m6 0h7m1 0h1m1 0h1m7 0h1m-28 1h2m7 0h1m1 0h7m9 0h1m-19 1h2m1 0h4m2 0h1m8 0h2m-20 1h6m13 0h1m-20 1h4m-3 1h1m-4 4h1"/><path stroke="#d3ad5d" d="M30 4h1m-2 2h1m-2 2h1m-2 1h1m-1 1h1m-1 1h1m-9 7h1m-2 21h1m0 1h1m18 20h1m-1 1h1"/><path stroke="#3d2e29" d="M37 6h1m-1 1h1m-11 5h1m0 1h1m3 1h2m2 0h1"/><path stroke="#6a3513" d="M26 7h1m-2 1h1m-3 1h1m-1 1h1m0 1h1m-1 1h1m1 0h1m-3 1h2m17 0h3m-26 1h1m3 0h7m6 0h2m1 0h6m-23 1h2m2 0h17m1 0h1m-27 1h1m4 0h2m2 0h15m3 0h1m-24 1h12m2 0h3m6 0h1m-21 1h8m2 0h2m1 0h1m6 0h1m-21 1h7m3 0h2m1 0h1m6 0h1m-19 1h5m4 0h1m1 0h1m6 0h1m-24 1h1m1 0h1m1 0h5m7 0h1m6 0h1m-24 1h7m3 0h1m5 0h1m6 0h1m-24 1h6m17 0h1m-26 1h3m1 0h2m10 0h1m1 0h1m6 0h1m-22 1h3m18 0h1m-14 1h3m1 0h2m7 0h1m-25 1h4m3 0h2m1 0h6m-16 1h7m3 0h4m-14 1h6m4 0h4m-17 1h1m2 0h7m3 0h1m1 0h2m1 0h1m-14 1h4m3 0h3m-13 1h2m1 0h3m5 0h1m4 0h1m-17 1h2m1 0h3m7 0h1m2 0h1m-16 1h5m10 0h2m-19 1h1m1 0h5m11 0h1m-17 1h2m1 0h4m8 0h2m-17 1h1m15 0h1m-2 1h2m-2 1h2m-19 4h1m-1 2h1m7 0h3m1 0h1m3 0h1m-9 2h1m0 1h1"/><path stroke="#7f6051" d="M38 7h2m-2 1h2m1 0h1m-4 1h4m1 0h1m-5 1h5m-5 1h5m-5 1h5m1 0h1m-4 1h1"/><path stroke="#bebcbe" d="M40 7h1m1 1h1m-1 1h1m1 1h1m-1 1h1"/><path stroke="#aaa8aa" d="M40 8h1"/><path stroke="#5f2f11" d="M27 13h1m11 1h1m-13 2h1m-1 4h1"/><path stroke="#f0a82e" d="M41 17h1m-2 1h1m-1 1h1m-1 1h1m-1 1h1m2 0h1m-4 1h1m-1 1h1m-1 1h1m0 2h1m-2 1h3m-3 1h3m-3 1h3m2 0h2m-29 1h1m21 0h4m-26 1h1m20 0h2m3 0h1m1 0h1m-30 1h3m19 0h2m3 0h1m1 0h1m-28 1h1m19 0h2m2 0h2m-27 1h1m20 0h2m2 0h1m-26 1h1m20 0h1m5 0h2m-29 1h1m20 0h3m3 0h1m-28 1h3m3 0h1m14 0h3m3 0h2m-27 1h3m1 0h2m13 0h3m4 0h1m-26 1h6m12 0h2m5 0h1m-27 1h3m1 0h3m12 0h3m4 0h1m-26 1h6m10 0h1m1 0h1m1 0h1m4 0h1m-26 1h6m12 0h4m3 0h1m-25 1h5m12 0h4m-20 1h4m8 0h1m2 0h5m2 0h2m-25 1h5m12 0h4m2 0h1m-23 1h1m1 0h2m7 0h1m1 0h1m2 0h5m2 0h1m-25 1h1m2 0h2m9 0h9m-20 1h2m7 0h2m1 0h8m-19 1h1m6 0h5m1 0h7m-20 1h1m4 0h3m1 0h3m1 0h5m1 0h1m-20 1h2m1 0h4m3 0h2m1 0h4m-17 1h12m1 0h4m-16 1h5m2 0h4m1 0h4m-16 1h1m7 0h3m1 0h4m-19 1h1m1 0h2m2 0h1m6 0h1m1 0h4m-18 1h1m1 0h3m3 0h2m5 0h3m-19 1h1m1 0h4m2 0h3m5 0h3m-18 1h4m1 0h1m1 0h3m4 0h4m-17 1h2m3 0h3m4 0h4m-16 1h2m3 0h2m6 0h1m-13 1h2m2 0h3m1 1h1"/><path stroke="#7d3c10" d="M18 41h1m-1 1h2m-1 1h1m0 1h1"/><path stroke="#ba8a57" d="M19 41h1m-2 2h1"/><path stroke="#a77b4e" d="M20 42h1m-3 2h2"/><path stroke="#d79629" d="M46 47h1m-9 11h1"/></svg>'
    ];

    constructor() ERC721("Aleko", "ale") {}

    function mintToken(uint256 tokenId) external {
        _safeMint(msg.sender, tokenId);
    }

    function setTokenURI(uint256 tokenId, uint256 _tokenURI) external {
        _setTokenURI(tokenId, _tokenURI);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            string(
                                abi.encodePacked(
                                    artLink,
                                    Base64.encode(bytes(COLORS[tokenId - 1])),
                                    artEnd
                                )
                            )
                        )
                    )
                )
            );
    }

    function _setTokenURI(uint256 tokenId, uint256 _tokenURI) internal virtual {
        require(
            _exists(tokenId),
            "ERC721URIStorage: URI set of nonexistent token"
        );
        _tokenURIs[tokenId] = _tokenURI;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/extensions/ERC721URIStorage.sol)

pragma solidity ^0.8.0;

import "../ERC721.sol";

/**
 * @dev ERC721 token with storage based token URI management.
 */
abstract contract ERC721URIStorage is ERC721 {
    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    /**
     * @dev Sets `_tokenURI` as the tokenURI of `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(uint256 tokenId) internal virtual override {
        super._burn(tokenId);

        if (bytes(_tokenURIs[tokenId]).length != 0) {
            delete _tokenURIs[tokenId];
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: address zero is not a valid owner");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        _requireMinted(tokenId);

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not token owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        _requireMinted(tokenId);

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: caller is not token owner nor approved");
        _safeTransfer(from, to, tokenId, data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits an {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits an {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Reverts if the `tokenId` has not been minted yet.
     */
    function _requireMinted(uint256 tokenId) internal view virtual {
        require(_exists(tokenId), "ERC721: invalid token ID");
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    /// @solidity memory-safe-assembly
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}