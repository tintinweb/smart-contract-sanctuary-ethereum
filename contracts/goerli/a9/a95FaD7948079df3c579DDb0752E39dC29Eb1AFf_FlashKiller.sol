/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: AGPL-3.0-or-later
//
// Copyright (C) 2022 Dai Foundation
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

pragma solidity ^0.8.12;

interface VatLike {
    function live() external view returns (uint256);
}

interface FlashLike {
    function file(bytes32, uint256) external;
}

contract FlashKiller {
    VatLike public immutable vat;
    FlashLike public immutable flash;

    constructor(address vat_, address flash_) {
        vat = VatLike(vat_);
        flash = FlashLike(flash_);
    }

    function kill() external {
        require(vat.live() == 0, "FlashKiller/vat-still-live");
        flash.file("max", 0);
    }
}