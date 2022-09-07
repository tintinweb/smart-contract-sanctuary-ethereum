// SPDX-License-Identifier: AGPL-3.0-or-later

/// jug.sol -- USB Lending Rate

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

pragma solidity ^0.8.0;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

pragma solidity ^0.8.0;

interface VatLike {
    function ilks(bytes32) external returns (
        uint256 Art,   // [wad]
        uint256 rate   // [ray]
    );
    function fold(bytes32,address,int) external;
}

contract Jug {
    // --- Auth ---
    mapping (address => uint) public wards;
    function rely(address usr) external auth { wards[usr] = 1; }
    function deny(address usr) external auth { wards[usr] = 0; }
    event setDuty(bytes32 ilk, uint prevDuty, uint newDuty);
    event setBase(uint prevBase, uint newBase);
    event setBorrowFee(bytes32 ilk, uint fee);
    event logRate(bytes32 ilk, uint time, uint deltaRate);
    event setVow(address newVow);
    modifier auth {
        require(wards[msg.sender] == 1, "Jug/not-authorized");
        _;
    }

    // --- Data ---
    struct Ilk {
        uint256 duty;  // Collateral-specific, per-second stability fee contribution [ray]
        uint256  rho;  // Time of last drip [unix epoch time]
        uint256 feeBorrow;   // Collateral-specific, fee pay to treasury
    }

    mapping (bytes32 => Ilk) public ilks;
    VatLike                  public vat;   // CDP Engine
    address                  public vow;   // Debt Engine
    uint256                  public base;  // Global, per-second stability fee contribution [ray]
    address                  public treasury;

    // --- Init ---
    constructor(address vat_) {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
    }

    // --- Math ---
    function rpow(uint x, uint n, uint b) internal pure returns (uint z) {
      assembly {
        switch x case 0 {switch n case 0 {z := b} default {z := 0}}
        default {
          switch mod(n, 2) case 0 { z := b } default { z := x }
          let half := div(b, 2)  // for rounding.
          for { n := div(n, 2) } n { n := div(n,2) } {
            let xx := mul(x, x)
            if iszero(eq(div(xx, x), x)) { revert(0,0) }
            let xxRound := add(xx, half)
            if lt(xxRound, xx) { revert(0,0) }
            x := div(xxRound, b)
            if mod(n,2) {
              let zx := mul(z, x)
              if and(iszero(iszero(x)), iszero(eq(div(zx, x), z))) { revert(0,0) }
              let zxRound := add(zx, half)
              if lt(zxRound, zx) { revert(0,0) }
              z := div(zxRound, b)
            }
          }
        }
      }
    }
    uint256 constant ONE = 10 ** 27;

    function add(uint x, uint y) internal pure returns (uint z) {
        z = x + y;
        require(z >= x);
    }
    function diff(uint x, uint y) internal pure returns (int z) {
        z = int(x) - int(y);
        require(int(x) >= 0 && int(y) >= 0);
    }
    function rmul(uint x, uint y) internal pure returns (uint z) {
        z = x * y;
        require(y == 0 || z / y == x);
        z = z / ONE;
    }

    // --- Administration ---
    function init(bytes32 ilk) external auth {
        Ilk storage i = ilks[ilk];
        require(i.duty == 0, "Jug/ilk-already-init");
        i.duty = ONE;
        i.rho  = block.timestamp;
    }

    function setCollateralStabilityFee(bytes32 ilk, uint data) external auth {
        // require(block.timestamp == ilks[ilk].rho, "Jug/rho-not-updated");
        Ilk storage i = ilks[ilk];
        require(i.duty != 0, "Jug/invalid-ilk");
        require(data >= ONE, "Jug/invalid-Collateral-stability-fee");
        i.rho = block.timestamp;
        uint prevDuty = i.duty;
        i.duty = data;
        emit setDuty(ilk, prevDuty, data);
    }

    function setFeeBorrow(bytes32 ilk, uint data) external auth {
        require(ilks[ilk].duty != 0, "Jug/invalid-ilk");
        require(data >= ONE, "Jug/invalid-borrow-fee");
        ilks[ilk].feeBorrow = data;
        emit setBorrowFee(ilk, data);
    }

    function setGlobalStabilityFee(uint data) external auth {
        require(data >= ONE, "Jug/invalid-Global-stability-fee");
        uint prevBase = base;
        base = data;
        emit setBase(prevBase, data);
    }

    function setVowAddress(address data) external auth {
        require(data != address(0), "Jug/invalid-vow");
        vow = data;
        emit setVow(data);
    }

    // --- Stability Fee Collection ---
    function drip(bytes32 ilk) external returns (uint rate) {
        require(block.timestamp >= ilks[ilk].rho, "Jug/invalid-now");
        (, uint prev) = vat.ilks(ilk);
        uint time = block.timestamp;
        rate = rmul(rpow(add(base, ilks[ilk].duty), block.timestamp - ilks[ilk].rho, ONE), prev);
        vat.fold(ilk, vow, diff(rate, prev));
        ilks[ilk].rho = block.timestamp;
        emit logRate(ilk, time, rate);
    }

    function getFeeBorrow(bytes32 ilk) external view returns (uint) {
        return ilks[ilk].feeBorrow;
    }
}