// SPDX-License-Identifier: AGPL-3.0-or-later

/// vow.sol -- ZAR settlement module

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

pragma solidity ^0.8.13;

// FIXME: This contract was altered compared to the production version.
// It doesn't use LibNote anymore.
// New deployments of this contract will need to include custom events (TO DO).

interface FlopLike {
    function kick(
        address gal,
        uint256 lot
    ) external returns (uint256);

    function cage() external;

    function live() external returns (uint256);
}

interface VatLike {
    function zar(address) external view returns (uint256);

    function sin(address) external view returns (uint256);

    function heal(uint256) external;

    function hope(address) external;

    function nope(address) external;
}

contract Vow {
    // --- Auth ---
    mapping(address => uint256) public wards;

    function rely(address usr) external auth {
        require(live == 1, "Vow/not-live");
        wards[usr] = 1;
        emit Rely(usr);
    }

    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    modifier auth {
        require(wards[msg.sender] == 1, "Vow/not-authorized");
        _;
    }

    // --- Data ---
    VatLike public vat; // CDP Engine
    FlopLike public flopper; // Debt Auction House

    mapping(uint256 => uint256) public sin; // debt queue
    uint256 public Sin; // Queued debt            [rad]
    uint256 public Ash; // On-auction debt        [rad]

    uint256 public wait; // Flop delay             [seconds]
    uint256 public sump; // Flop fixed bid size    [rad]

    uint256 public hump; // Surplus buffer         [rad]

    uint256 public live; // Active Flag

    event Rely(address indexed usr);
    event Deny(address indexed usr);

    event File(bytes32 indexed what, uint256 data);
    event File(bytes32 indexed what, address data);
    event Fess(uint256 indexed tab);
    event Flog(uint256 indexed era);
    event Heal(uint256 indexed rad);

    event Kiss(uint256 indexed rad);
    
    event Flop();

    event Cage();

    // --- Init ---
    constructor(
        address vat_,
        address flopper_
    ) public {
        wards[msg.sender] = 1;
        vat = VatLike(vat_);
        flopper = FlopLike(flopper_);
        live = 1;
    }

    // --- Math ---
    function min(uint256 x, uint256 y) internal pure returns (uint256 z) {
        return x <= y ? x : y;
    }

    // --- Administration ---
    function file(bytes32 what, uint256 data) external auth {
        if (what == "wait") wait = data;
        else if (what == "sump") sump = data;
        else if (what == "hump") hump = data;
        else revert("Vow/file-unrecognized-param");
        emit File(what, data);
    }

    function file(bytes32 what, address data) external auth {
        if (what == "flopper") flopper = FlopLike(data);
        else revert("Vow/file-unrecognized-param");
        emit File(what, data);
    }

    // Push to debt-queue
    function fess(uint256 tab) external auth {
        sin[block.timestamp] = sin[block.timestamp] + tab;
        Sin = Sin + tab;
        emit Fess(tab);
    }

    // Pop from debt-queue
    function flog(uint256 era) external {
        require(era + wait <= block.timestamp, "Vow/wait-not-finished");
        Sin = Sin - sin[era];
        sin[era] = 0;
        emit Flog(era);
    }

    // Debt settlement
    function heal(uint256 rad) external {
        require(rad <= vat.zar(address(this)), "Vow/insufficient-surplus");
        require(
            rad <= (vat.sin(address(this)) - Sin) - Ash,
            "Vow/insufficient-debt"
        );
        vat.heal(rad);
        emit Heal(rad);
    }

    function kiss(uint256 rad) external {
        require(rad <= Ash, "Vow/not-enough-ash");
        require(rad <= vat.zar(address(this)), "Vow/insufficient-surplus");
        Ash = Ash - rad;
        vat.heal(rad);

        emit Kiss(rad);
    }

    function flop() external {
        require(
            sump <= (vat.sin(address(this)) - Sin) - Ash,
            "Vow/insufficient-debt"
        );
        require(vat.zar(address(this)) == 0, "Vow/surplus-not-zero");
        Ash = Ash + sump;
        flopper.kick(address(this), sump);
        emit Flop();
    }

    function cage() external auth {
        require(live == 1, "Vow/not-live");
        live = 0;
        Sin = 0;
        Ash = 0;
        flopper.cage();
        vat.heal(min(vat.zar(address(this)), vat.sin(address(this))));
        emit Cage();
    }
}