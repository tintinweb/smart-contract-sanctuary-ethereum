// SPDX-License-Identifier: AGPL-3.0-or-later

/// jug.sol -- irdt Lending Rate

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

interface VatLike {
    function ilks(bytes32)
        external
        returns (
            uint256 Art, // [wad]
            uint256 rate // [ray]
        );

    function fold(
        bytes32,
        address,
        int256
    ) external;
}

contract Jug {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external {
        wards[usr] = 1;
    }

    function deny(address usr) external {
        wards[usr] = 0;
    }

    // --- Data ---
    struct Ilk {
        uint256 duty; // Collateral-specific, per-second stability fee contribution [ray]
        uint256 rho; // Time of last drip [unix epoch time]
    }

    mapping(bytes32 => Ilk) public ilks;
    VatLike public vat; // CDP Engine
    address public vow; // Debt Engine
    uint256 public base; // Global, per-second stability fee contribution [ray]

    event Init(bytes32 indexed ilk);

    event File(bytes32 indexed ilk, bytes32 indexed what, uint256 indexed data);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);

    event Drip(bytes32 indexed ilk, uint256 indexed rate);

    // --- Init ---
    constructor(address vat_) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
    }

    // --- Math ---
    function _rpow(
        uint256 x,
        uint256 n,
        uint256 b
    ) internal pure returns (uint256 z) {
        assembly {
            switch x
            case 0 {
                switch n
                case 0 {
                    z := b
                }
                default {
                    z := 0
                }
            }
            default {
                switch mod(n, 2)
                case 0 {
                    z := b
                }
                default {
                    z := x
                }
                let half := div(b, 2) // for rounding.
                for {
                    n := div(n, 2)
                } n {
                    n := div(n, 2)
                } {
                    let xx := mul(x, x)
                    if iszero(eq(div(xx, x), x)) {
                        revert(0, 0)
                    }
                    let xxRound := add(xx, half)
                    if lt(xxRound, xx) {
                        revert(0, 0)
                    }
                    x := div(xxRound, b)
                    if mod(n, 2) {
                        let zx := mul(z, x)
                        if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) {
                            revert(0, 0)
                        }
                        let zxRound := add(zx, half)
                        if lt(zxRound, zx) {
                            revert(0, 0)
                        }
                        z := div(zxRound, b)
                    }
                }
            }
        }
    }

    uint256 constant ONE = 10**27;

    function _add(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x + y;
        require(z >= x);
    }

    function _diff(uint256 x, uint256 y) internal pure returns (int256 z) {
        z = int256(x) - int256(y);
        require(int256(x) >= 0 && int256(y) >= 0);
    }

    function _rmul(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / ONE;
    }

    // --- Administration ---
    function init(bytes32 ilk) external {
        Ilk storage i = ilks[ilk];
        require(i.duty == 0, "Jug/ilk-already-init");
        i.duty = ONE;
        i.rho = now;
        emit Init(ilk);
    }

    function file(
        bytes32 ilk,
        bytes32 what,
        uint256 data
    ) external {
        require(now == ilks[ilk].rho, "Jug/rho-not-updated");
        if (what == "duty") ilks[ilk].duty = data;
        else revert("Jug/file-unrecognized-param");
        emit File(ilk, what, data);
    }

    function file(bytes32 what, uint256 data) external {
        if (what == "base") base = data;
        else revert("Jug/file-unrecognized-param");
        emit File(what, data);
    }

    function file(bytes32 what, address data) external {
        if (what == "vow") vow = data;
        else revert("Jug/file-unrecognized-param");
        emit File(what, data);
    }

    // --- Stability Fee Collection ---
    function drip(bytes32 ilk) external returns (uint256 rate) {
        require(now >= ilks[ilk].rho, "Jug/invalid-now");
        (, uint256 prev) = vat.ilks(ilk);
        rate = _rmul(
            _rpow(_add(base, ilks[ilk].duty), now - ilks[ilk].rho, ONE),
            prev
        );
        vat.fold(ilk, vow, _diff(rate, prev));
        ilks[ilk].rho = now;
        emit Drip(ilk, rate);
    }
}