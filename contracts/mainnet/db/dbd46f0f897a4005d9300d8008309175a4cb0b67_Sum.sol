// SPDX-License-Identifier: AGPL-3.0-or-later

/// sum.sol -- Integer counter value (ICV) database

// Copyright (C) 2022 Horsefacts <[email protected]>
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

pragma solidity >=0.5.0;

import {DSNote} from "ds-note/note.sol";

contract Sum is DSNote {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth note { require(live == 1, "Sum/not-live"); wards[usr] = 1; }
    function deny(address usr) external auth note { require(live == 1, "Sum/not-live"); wards[usr] = 0; }
    modifier auth {
        require(wards[msg.sender] == 1, "Sum/not-authorized");
        _;
    }

    mapping(address => mapping (address => uint)) public can;
    function hope(address usr) external note { can[msg.sender][usr] = 1; }
    function nope(address usr) external note { can[msg.sender][usr] = 0; }
    function wish(address bit, address usr) internal view returns (bool) {
        return either(bit == usr, can[bit][usr] == 1);
    }

    // --- Data ---
    struct Inc {
        uint net;  // Net counter value
        uint tab;  // Sum of increments
        uint tax;  // Sum of decrements
        uint num;  // Total counter operations
        uint hop;  // Counter increment unit
    }

    mapping (address => Inc) public incs;

    uint public One;   // Global increment parameter
    uint public live;  // Active Flag

    // --- Init ---
    constructor() public {
        wards[msg.sender] = 1;
        One = 1;
        live = 1;
    }

    // --- Math ---
    function add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x);
    }
    function sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x);
    }

    // --- Administration ---
    function file(bytes32 what, uint data) external note auth {
        require(live == 1, "Sum/not-live");
        if (what == "One") {
            if (data != 0) One = data;
            else revert("Sum/not-allowed-one");
        }
        else revert("Sum/file-unrecognized-param");
    }
    function cage() external note auth {
        live = 0;
    }
    function free() external note auth {
        live = 1;
    }

    function either(bool x, bool y) internal pure returns (bool z) {
        assembly{ z := or(x, y)}
    }

    // --- ICV Creation ---
    function boot(address i) external note {
        // system is live
        require(live == 1, "Sum/not-live");

        // caller is allowed
        require(wish(i, msg.sender), "Sum/not-allowed");

        // inc has not been initialised
        require(incs[i].hop == 0, "Sum/inc-already-init");

        incs[i].hop = One;
    }

    // --- ICV Reset ---
    function zero(address i) external note {
        // system is live
        require(live == 1, "Sum/not-live");

        // caller is allowed
        require(wish(i, msg.sender), "Sum/not-allowed");

        Inc memory inc = incs[i];
        // inc has been initialised
        require(inc.hop != 0, "Sum/inc-not-init");

        inc.net = 0;
        inc.tab = 0;
        inc.tax = 0;
        inc.num = add(inc.num, 1);
        incs[i] = inc;
    }

    // --- ICV Manipulation ---
    function frob(address i, int sinc) external note {
        // system is live
        require(live == 1, "Sum/not-live");

        // caller is allowed
        require(wish(i, msg.sender), "Sum/not-allowed");

        // sinc is allowed
        require(either(sinc == 1, sinc == -1), "Sum/not-allowed-sinc");

        Inc memory inc = incs[i];
        // inc has been initialised
        require(inc.hop != 0, "Sum/inc-not-init");

        // hop is safe
        require(either(sinc == 1, inc.net >= inc.hop), "Sum/not-safe-hop");

        if (sinc == 1) {
            inc.net = add(inc.net, inc.hop);
            inc.tab = add(inc.tab, inc.hop);
        }
        if (sinc == -1) {
            inc.net = sub(inc.net, inc.hop);
            inc.tax = add(inc.tax, inc.hop);
        }
        inc.num = add(inc.num, 1);
        incs[i] = inc;
    }
}

/// note.sol -- the `note' modifier, for logging calls as events

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity >=0.4.23;

contract DSNote {
    event LogNote(
        bytes4   indexed  sig,
        address  indexed  guy,
        bytes32  indexed  foo,
        bytes32  indexed  bar,
        uint256           wad,
        bytes             fax
    ) anonymous;

    modifier note {
        bytes32 foo;
        bytes32 bar;
        uint256 wad;

        assembly {
            foo := calldataload(4)
            bar := calldataload(36)
            wad := callvalue()
        }

        _;

        emit LogNote(msg.sig, msg.sender, foo, bar, wad, msg.data);
    }
}