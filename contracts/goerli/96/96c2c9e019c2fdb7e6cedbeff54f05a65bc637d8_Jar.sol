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

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.14;

contract Jar {
    /// @dev The DaiJoin adapter from MCD.
    DaiJoinLike public immutable daiJoin;
    /// @dev The Dai token.
    DaiLike public immutable dai;
    /// @dev The Vow address from MCD.
    address public immutable vow;

    /**
     * @notice Revert reason when the Dai balance of this contract is zero and `flock` is called.
     */
    error EmptyJar();

    /**
     * @notice Emitted whenever Dai is sent to the `vow`.
     * @param amount The amount of Dai sent.
     */
    event Toss(uint256 amount);

    /**
     * @dev The Dai address is obtained from the DaiJoin contract.
     * @param _daiJoin The DaiJoin adapter from MCD.
     * @param _vow The vow from MCD.
     */
    constructor(address _daiJoin, address _vow) {
        daiJoin = DaiJoinLike(_daiJoin);
        dai = DaiLike(DaiJoinLike(_daiJoin).dai());
        vow = _vow;

        DaiLike(DaiJoinLike(_daiJoin).dai()).approve(_daiJoin, type(uint256).max);
    }

    /**
     * @notice Transfers any outstanding Dai balance in this contract to the `vow`.
     * @dev This effectively burns ERC-20 Dai and credits it to the internal Dai balance of the `vow` in the Vat.
     */
    function flock() external {
        uint256 balance = dai.balanceOf(address(this));

        if (balance == 0) {
            revert EmptyJar();
        }

        daiJoin.join(vow, balance);

        emit Toss(balance);
    }

    /**
     * @notice Pulls `wad` amount of Dai from the sender's wallet into the `vow`.
     * @dev Requires `msg.sender` to have previously `approve`d this contract to spend at least `wad` Dai.
     * @dev This effectively burns ERC-20 Dai and credits it to the internal Dai balance of the `vow` in the Vat.
     * @param wad The amount of Dai.
     */
    function toss(uint256 wad) external {
        dai.transferFrom(msg.sender, address(this), wad);
        daiJoin.join(vow, wad);

        emit Toss(wad);
    }
}

interface DaiLike {
    function approve(address, uint256) external;

    function transferFrom(
        address,
        address,
        uint256
    ) external returns (bool);

    function balanceOf(address) external view returns (uint256);
}

interface DaiJoinLike {
    function dai() external view returns (address);

    function join(address, uint256) external;
}