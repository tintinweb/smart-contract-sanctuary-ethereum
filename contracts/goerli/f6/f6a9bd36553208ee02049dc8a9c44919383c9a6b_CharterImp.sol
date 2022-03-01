/**
 *Submitted for verification at Etherscan.io on 2022-03-01
*/

// hevm: flattened sources of src/Charter.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12;

////// src/Charter.sol
// Copyright (C) 2021 Dai Foundation
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

/* pragma solidity 0.6.12; */

interface VatLike_16 {
    function live() external view returns (uint256);
    function wards(address) external view returns (uint256);
    function urns(bytes32, address) external view returns (uint256, uint256);
    function fork(bytes32, address, address, int256, int256) external;
    function frob(bytes32, address, address, address, int256, int256) external;
    function flux(bytes32, address, address, uint256) external;
    function move(address, address, uint256) external;
    function hope(address) external;
    function ilks(bytes32) external view returns (
        uint256 Art,  // [wad]
        uint256 rate, // [ray]
        uint256 spot, // [ray]
        uint256 line, // [rad]
        uint256 dust  // [rad]
    );
}

interface SpotterLike_3 {
    function ilks(bytes32) external returns (address, uint256);
}

interface GemLike_7 {
    function approve(address, uint256) external;
    function transferFrom(address, address, uint256) external;
}

interface ManagedGemJoinLike {
    function gem() external view returns (GemLike_7);
    function ilk() external view returns (bytes32);
    function join(address, uint256) external;
    function exit(address, address, uint256) external;
}

contract UrnProxy {
    address immutable public usr;

    constructor(address vat_, address usr_) public {
        usr = usr_;
        VatLike_16(vat_).hope(msg.sender);
    }
}

contract CharterImp {
    // --- Proxy Storage ---
    bytes32 slot0; // avoid collision with proxy's implementation field
    mapping (address => uint256) public wards;

    // --- Implementation Storage ---
    mapping (address => address) public proxy; // UrnProxy per user
    mapping (address => mapping (address => uint256))  public can;
    mapping (bytes32 => uint256)                       public gate;  // allow only permissioned vaults
    mapping (bytes32 => uint256)                       public Nib;   // fee percentage for un-permissioned vaults [wad]
    mapping (bytes32 => mapping (address => uint256))  public nib;   // fee percentage for permissioned vaults    [wad]
    mapping (bytes32 => uint256)                       public Peace; // min CR for un-permissioned vaults         [ray]
    mapping (bytes32 => mapping (address => uint256))  public peace; // min CR for permissioned vaults            [ray]
    mapping (bytes32 => mapping (address => uint256))  public uline; // debt ceiling for permissioned vaults      [rad]

    // srcIlk => dstIlk => src => dst => is_rollable
    mapping (bytes32 => mapping (bytes32 => mapping (address => mapping (address => uint256)))) public rollable;

    address public immutable vat;
    address public immutable vow;
    address public immutable spotter;

    // --- Events ---
    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 data);
    event File(bytes32 indexed ilk, address indexed usr, bytes32 indexed what, uint256 data);
    event File(bytes32 indexed srcIlk, bytes32 indexed dstIlk, address indexed src, address dst, bytes32 what, uint256 data);
    event Hope(address indexed from, address indexed to);
    event Nope(address indexed from, address indexed to);
    event NewProxy(address indexed usr, address indexed urp);

    // --- Administration ---
    function file(bytes32 ilk, bytes32 what, uint256 data) external auth {
        if (what == "gate") gate[ilk] = data;
        else if (what == "Nib") Nib[ilk] = data;
        else if (what == "Peace") Peace[ilk] = data;
        else revert("Charter/file-unrecognized-param");
        emit File(ilk, what, data);
    }
    function file(bytes32 ilk, address usr, bytes32 what, uint256 data) external auth {
        if (what == "uline") uline[ilk][usr] = data;
        else if (what == "nib") nib[ilk][usr] = data;
        else if (what == "peace") peace[ilk][usr] = data;
        else revert("Charter/file-unrecognized-param");
        emit File(ilk, usr, what, data);
    }
    function file(bytes32 srcIlk, bytes32 dstIlk, address src, address dst, bytes32 what, uint256 data) external auth {
        if (what == "rollable") rollable[srcIlk][dstIlk][src][dst] = data;
        else revert("Charter/file-unrecognized-param");
        emit File(srcIlk, dstIlk, src, dst, what, data);
    }

    // --- Math ---
    uint256 constant WAD = 10 ** 18;
    uint256 constant RAY = 10 ** 27;

    function _sub(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require((z = x - y) <= x);
    }
    function _mul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        require(y == 0 || (z = x * y) / y == x);
    }
    function _wmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = _mul(x, y) / WAD;
    }
    function _rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = _mul(x, y) / RAY;
    }
    function _rdiv(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = _mul(x, RAY) / y;
    }
    function _toInt(uint256 x) internal pure returns (int256 y) {
        y = int256(x);
        require(y >= 0);
    }

    // --- Auth ---
    modifier auth {
        require(wards[msg.sender] == 1, "Charter/non-authed");
        _;
    }

    constructor(address vat_, address vow_, address spotter_) public {
        vat = vat_;
        vow = vow_;
        spotter = spotter_;
    }

    modifier allowed(address usr) {
        require(msg.sender == usr || can[usr][msg.sender] == 1, "Charter/not-allowed");
        _;
    }
    function hope(address usr) external {
        can[msg.sender][usr] = 1;
        emit Hope(msg.sender, usr);
    }
    function nope(address usr) external {
        can[msg.sender][usr] = 0;
        emit Nope(msg.sender, usr);
    }

    function getOrCreateProxy(address usr) public returns (address urp) {
        urp = proxy[usr];
        if (urp == address(0)) {
            urp = proxy[usr] = address(new UrnProxy(address(vat), usr));
            emit NewProxy(usr, urp);
        }
    }

    function join(address gemJoin, address usr, uint256 amt) external {
        require(VatLike_16(vat).wards(gemJoin) == 1, "Charter/gem-join-not-authorized");

        GemLike_7 gem = ManagedGemJoinLike(gemJoin).gem();
        gem.transferFrom(msg.sender, address(this), amt);
        gem.approve(gemJoin, amt);
        ManagedGemJoinLike(gemJoin).join(getOrCreateProxy(usr), amt);
    }

    function exit(address gemJoin, address usr, uint256 amt) external {
        require(VatLike_16(vat).wards(gemJoin) == 1, "Charter/gem-join-not-authorized");

        address urp = proxy[msg.sender];
        require(urp != address(0), "Charter/non-existing-urp");
        ManagedGemJoinLike(gemJoin).exit(urp, usr, amt);
    }

    function move(address u, address dst, uint256 rad) external allowed(u) {
        address urp = proxy[u];
        require(urp != address(0), "Charter/non-existing-urp");

        VatLike_16(vat).move(urp, dst, rad);
    }

    function roll(bytes32 srcIlk, bytes32 dstIlk, address src, address dst, uint256 srcDart) external allowed(src) allowed(dst) {
        require(gate[srcIlk] == 1 && gate[dstIlk] == 1, "Charter/non-gated-ilks");
        require(rollable[srcIlk][dstIlk][src][dst] == 1, "Charter/non-rollable");

        (, uint256 srcRate,,,) = VatLike_16(vat).ilks(srcIlk);
        (, uint256 dstRate, uint256 dstSpot,,) = VatLike_16(vat).ilks(dstIlk);

        // Add a dart unit to avoid insufficiency due to precision loss
        int256 dstDart = _toInt(_mul(srcRate, srcDart) / dstRate + 1);

        address dstUrp = proxy[dst];
        require(dstUrp != address(0), "Charter/non-existing-dst-urp");
        VatLike_16(vat).frob(dstIlk, dstUrp, address(0), address(this), 0, dstDart);

        address srcUrp = proxy[src];
        require(srcUrp != address(0), "Charter/non-existing-src-urp");
        int256 srcDart_ = -_toInt(srcDart); // Not inlined to avoid stack too deep
        VatLike_16(vat).frob(srcIlk, srcUrp, address(0), address(this), 0, srcDart_);

        _validate(dstIlk, dst, dstUrp, 0, dstDart, dstRate, dstSpot, 1);
    }

    function _draw(
        bytes32 ilk, address u, address urp, address w, int256 dink, int256 dart, uint256 rate, uint256 _gate
        ) internal {
        uint256 _nib = (_gate == 1) ? nib[ilk][u] : Nib[ilk];
        uint256 dtab = _mul(rate, uint256(dart)); // rad
        uint256 coin = _wmul(dtab, _nib);         // rad

        VatLike_16(vat).frob(ilk, urp, urp, urp, dink, dart);
        VatLike_16(vat).move(urp, w, _sub(dtab, coin));
        VatLike_16(vat).move(urp, vow, coin);
    }

    function _validate(
        bytes32 ilk, address u, address urp, int256 dink, int256 dart, uint256 rate, uint256 spot, uint256 _gate
        ) internal {
        if (dart > 0 || dink < 0) {
            // vault is more risky than before

            (uint256 ink, uint256 art) = VatLike_16(vat).urns(ilk, urp);
            uint256 tab = _mul(art, rate); // rad

            if (dart > 0 && _gate == 1) {
                require(tab <= uline[ilk][u], "Charter/user-line-exceeded");
            }

            uint256 _peace = (_gate == 1) ? peace[ilk][u] : Peace[ilk];
            if (_peace > 0) {
                (, uint256 mat) = SpotterLike_3(spotter).ilks(ilk);
                // reconstruct price, avoid un-applying par so it's accounted for when comparing to tab
                uint256 peaceSpot = _rdiv(_rmul(spot, mat), _peace); // ray
                require(tab <= _mul(ink, peaceSpot), "Charter/below-peace-ratio");
            }
        }
    }

    function frob(bytes32 ilk, address u, address v, address w, int256 dink, int256 dart) external allowed(u) allowed(w) {
        require(u == v, "Charter/not-matching");
        address urp = getOrCreateProxy(u);
        (, uint256 rate, uint256 spot,,) = VatLike_16(vat).ilks(ilk);
        uint256 _gate = gate[ilk];

        if (dart <= 0) {
            VatLike_16(vat).frob(ilk, urp, urp, w, dink, dart);
        } else {
            _draw(ilk, u, urp, w, dink, dart, rate, _gate);
        }
        _validate(ilk, u, urp, dink, dart, rate, spot, _gate);
    }

    function flux(address gemJoin, address src, address dst, uint256 wad) external allowed(src) {
        address surp = getOrCreateProxy(src);
        address durp = getOrCreateProxy(dst);

        VatLike_16(vat).flux(ManagedGemJoinLike(gemJoin).ilk(), surp, durp, wad);
    }

    function flee(address) external {
        revert("Charter/unsupported");
    }

    function onLiquidation(address gemJoin, address usr, uint256 wad) external {}

    function onVatFlux(address gemJoin, address from, address to, uint256 wad) external {}

    function quit(bytes32 ilk, address u, address dst) external allowed(u) allowed(dst) {
        require(VatLike_16(vat).live() == 0, "Charter/vat-still-live");

        address urp = proxy[u];
        require(urp != address(0), "Charter/non-existing-urp");

        (uint256 ink, uint256 art) = VatLike_16(vat).urns(ilk, urp);
        require(int256(ink) >= 0, "Charter/overflow");
        require(int256(art) >= 0, "Charter/overflow");
        VatLike_16(vat).fork(
            ilk,
            urp,
            dst,
            int256(ink),
            int256(art)
        );
    }
}