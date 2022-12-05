// SPDX-License-Identifier: AGPL-3.0-or-later

/// vat.sol -- SIM CDP database

// Copyright (C) 2018 Rain <[email protected]>
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.6.12;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

contract Vat {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        require(live == 1, "Vat/not-live");
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external {
        require(live == 1, "Vat/not-live");
        wards[usr] = 0;
        emit Deny(usr);
    }

    mapping(address => mapping(address => uint256)) public can;

    function hope(address usr) external {
        can[msg.sender][usr] = 1;
        emit Hope(usr);
    }

    function nope(address usr) external {
        can[msg.sender][usr] = 0;
        emit Nope(usr);
    }

    function wish(address bit, address usr) internal view returns (bool) {
        return either(bit == usr, can[bit][usr] == 1);
    }

    // --- Data ---
    struct Ilk {
        uint256 Art; // Total Normalised Debt     [wad]
        uint256 rate; // Accumulated Rates         [ray]
        uint256 spot; // Price with Safety Margin  [ray]
        uint256 line; // Debt Ceiling              [rad]
        uint256 dust; // Urn Debt Floor            [rad]
    }
    struct Urn {
        uint256 ink; // Locked Collateral  [wad]
        uint256 art; // Normalised Debt    [wad]
    }

    mapping(bytes32 => Ilk) public ilks;
    mapping(bytes32 => mapping(address => Urn)) public urns;
    mapping(bytes32 => mapping(address => uint256)) public gem; // [wad]
    mapping(address => uint256) public sim; // [rad]
    mapping(address => uint256) public sin; // [rad]

    uint256 public debt; // Total SIM Issued    [rad]
    uint256 public vice; // Total Unbacked SIM  [rad]
    uint256 public Line; // Total Debt Ceiling  [rad]
    uint256 public live; // Active Flag

    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event Hope(address indexed usr);
    event Nope(address indexed usr);

    event Init(bytes32 indexed ilk);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 indexed data);
    event Cage();
    event Slip(bytes32 indexed ilk, address indexed usr, int256 indexed wad);
    event Flux(
        bytes32 indexed ilk,
        address indexed src,
        address indexed dst,
        uint256 wad
    );

    event Move(address indexed src, address indexed dst, uint256 rad);
    event Frob(
        bytes32 i,
        address indexed u,
        address indexed v,
        address indexed w,
        int256 dink,
        int256 dart
    );

    event Fork(
        bytes32 indexed ilk,
        address indexed src,
        address indexed dst,
        int256 dink,
        int256 dart
    );

    event Grab(
        bytes32 i,
        address indexed u,
        address indexed v,
        address indexed w,
        int256 dink,
        int256 dart
    );
    event Heal(uint256 indexed rad);

    event Suck(address indexed u, address indexed v, uint256 indexed rad);

    event Fess(uint256 indexed tab);
    event Flog(uint256 indexed era);

    event Kiss(uint256 indexed rad);
    event Flop(uint256 indexed id);
    event Flap(uint256 indexed id);
    event Fold(bytes32 indexed i, address indexed u, int256 indexed rate);

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        live = 1;
    }

    // --- Math ---
    function _add(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x + uint256(y);
        require(y >= 0 || z <= x);
        require(y <= 0 || z >= x);
    }

    function _sub(uint256 x, int256 y) internal pure returns (uint256 z) {
        z = x - uint256(y);
        require(y <= 0 || z <= x);
        require(y >= 0 || z >= x);
    }

    function _mul(uint256 x, int256 y) internal pure returns (int256 z) {
        z = int256(x) * y;
        require(int256(x) >= 0);
        require(y == 0 || z / y == int256(x));
    }

    function _add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x + y) >= x);
    }

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }

    function _mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }

    // --- Administration ---
    function init(bytes32 ilk) external {
        require(ilks[ilk].rate == 0, "Vat/ilk-already-init");
        ilks[ilk].rate = 10**27;
    }

    function file(bytes32 what, uint256 data) external {
        require(live == 1, "Vat/not-live");
        if (what == "Line") Line = data;
        else revert("Vat/file-unrecognized-param");
    }

    function file(
        bytes32 ilk,
        bytes32 what,
        uint256 data
    ) external {
        require(live == 1, "Vat/not-live");
        if (what == "spot") ilks[ilk].spot = data;
        else if (what == "line") ilks[ilk].line = data;
        else if (what == "dust") ilks[ilk].dust = data;
        else revert("Vat/file-unrecognized-param");
    }

    function cage() external {
        live = 0;
        emit Cage();
    }

    // --- Fungibility ---
    function slip(
        bytes32 ilk,
        address usr,
        int256 wad
    ) external {
        gem[ilk][usr] = _add(gem[ilk][usr], wad);
        emit Slip(ilk, usr, wad);
    }

    function flux(
        bytes32 ilk,
        address src,
        address dst,
        uint256 wad
    ) external {
        require(wish(src, msg.sender), "Vat/not-allowed1");
        gem[ilk][src] = _sub(gem[ilk][src], wad);
        gem[ilk][dst] = _add(gem[ilk][dst], wad);
        emit Flux(ilk, src, dst, wad);
    }

    function move(
        address src,
        address dst,
        uint256 rad
    ) external {
        require(wish(src, msg.sender), "Vat/not-allowed2");
        sim[src] = _sub(sim[src], rad);
        sim[dst] = _add(sim[dst], rad);
        emit Move(src, dst, rad);
    }

    function either(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := or(x, y)
        }
    }

    function both(bool x, bool y) internal pure returns (bool z) {
        assembly {
            z := and(x, y)
        }
    }

    // --- CDP Manipulation ---
    function frob(
        bytes32 i,
        address u,
        address v,
        address w,
        int256 dink,
        int256 dart
    ) external {
        // system is live
        require(live == 1, "Vat/not-live");

        Urn memory urn = urns[i][u];
        Ilk memory ilk = ilks[i];
        // ilk has been initialised
        require(ilk.rate != 0, "Vat/ilk-not-init");

        urn.ink = _add(urn.ink, dink);
        urn.art = _add(urn.art, dart);
        ilk.Art = _add(ilk.Art, dart);

        int256 dtab = _mul(ilk.rate, dart);
        uint256 tab = _mul(ilk.rate, urn.art);
        debt = _add(debt, dtab);

        // either debt has decreased, or debt ceilings are not exceeded
        require(
            either(
                dart <= 0,
                both(_mul(ilk.Art, ilk.rate) <= ilk.line, debt <= Line)
            ),
            "Vat/ceiling-exceeded"
        );
        // urn is either less risky than before, or it is safe
        require(
            either(both(dart <= 0, dink >= 0), tab <= _mul(urn.ink, ilk.spot)),
            "Vat/not-safe"
        );

        // urn is either more safe, or the owner consents
        require(
            either(both(dart <= 0, dink >= 0), wish(u, msg.sender)),
            "Vat/not-allowed-u"
        );
        // collateral src consents
        require(either(dink <= 0, wish(v, msg.sender)), "Vat/not-allowed-v");
        // debt dst consents
        require(either(dart >= 0, wish(w, msg.sender)), "Vat/not-allowed-w");

        // urn has no debt, or a non-dusty amount
        require(either(urn.art == 0, tab >= ilk.dust), "Vat/dust");

        gem[i][v] = _sub(gem[i][v], dink);
        sim[w] = _add(sim[w], dtab);

        urns[i][u] = urn;
        ilks[i] = ilk;
        emit Frob(i, u, v, w, dink, dart);
    }

    // --- CDP Fungibility ---
    function fork(
        bytes32 ilk,
        address src,
        address dst,
        int256 dink,
        int256 dart
    ) external {
        Urn storage u = urns[ilk][src];
        Urn storage v = urns[ilk][dst];
        Ilk storage i = ilks[ilk];

        u.ink = _sub(u.ink, dink);
        u.art = _sub(u.art, dart);
        v.ink = _add(v.ink, dink);
        v.art = _add(v.art, dart);

        uint256 utab = _mul(u.art, i.rate);
        uint256 vtab = _mul(v.art, i.rate);

        // both sides consent
        require(
            both(wish(src, msg.sender), wish(dst, msg.sender)),
            "Vat/not-allowed3"
        );

        // both sides safe
        require(utab <= _mul(u.ink, i.spot), "Vat/not-safe-src");
        require(vtab <= _mul(v.ink, i.spot), "Vat/not-safe-dst");

        // both sides non-dusty
        require(either(utab >= i.dust, u.art == 0), "Vat/dust-src");
        require(either(vtab >= i.dust, v.art == 0), "Vat/dust-dst");
        emit Fork(ilk, src, dst, dink, dart);
    }

    // --- CDP Confiscation ---
    function grab(
        bytes32 i,
        address u,
        address v,
        address w,
        int256 dink,
        int256 dart
    ) external {
        Urn storage urn = urns[i][u];
        Ilk storage ilk = ilks[i];

        urn.ink = _add(urn.ink, dink);
        urn.art = _add(urn.art, dart);
        ilk.Art = _add(ilk.Art, dart);

        int256 dtab = _mul(ilk.rate, dart);

        gem[i][v] = _sub(gem[i][v], dink);
        sin[w] = _sub(sin[w], dtab);
        vice = _sub(vice, dtab);
        emit Grab(i, u, v, w, dink, dart);
    }

    // --- Settlement ---
    function heal(uint256 rad) external {
        address u = msg.sender;
        sin[u] = _sub(sin[u], rad);
        sim[u] = _sub(sim[u], rad);
        vice = _sub(vice, rad);
        debt = _sub(debt, rad);

        emit Heal(rad);
    }

    function suck(
        address u,
        address v,
        uint256 rad
    ) external {
        sin[u] = _add(sin[u], rad);
        sim[v] = _add(sim[v], rad);
        vice = _add(vice, rad);
        debt = _add(debt, rad);

        emit Suck(u, v, rad);
    }

    // --- Rates ---
    function fold(
        bytes32 i,
        address u,
        int256 rate
    ) external {
        require(live == 1, "Vat/not-live");
        Ilk storage ilk = ilks[i];
        ilk.rate = _add(ilk.rate, rate);
        int256 rad = _mul(ilk.Art, rate);
        sim[u] = _add(sim[u], rad);
        debt = _add(debt, rad);
        emit Fold(i, u, rate);
    }
}