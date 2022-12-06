/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// hevm: flattened sources of src/PSMCallee.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

////// src/PSMCallee.sol
// Copyright (C) 2021 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published
// by the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/* pragma solidity >=0.6.12; */
/* pragma experimental ABIEncoderV2; */

interface GemJoinLike_4 {
    function dec() external view returns (uint256);
    function gem() external view returns (TokenLike_3);
    function exit(address, uint256) external;
}

interface DaiJoinLike_3 {
    function dai() external view returns (TokenLike_3);
    function join(address, uint256) external;
}

interface TokenLike_3 {
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
}

interface PSMLike {
    function sellGem(address usr, uint256 gemAmt) external;
    function gemJoin() external view returns (address);
}

contract PSMCallee {
    DaiJoinLike_3             public daiJoin;
    TokenLike_3               public dai;

    uint256                 public constant RAY = 10 ** 27;

    function _add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function _sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function _divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = _add(x, _sub(y, 1)) / y;
    }

    constructor(address daiJoin_) public {
        daiJoin = DaiJoinLike_3(daiJoin_);
        dai = daiJoin.dai();

        dai.approve(daiJoin_, uint256(-1));
    }

    function _fromWad(address gemJoin, uint256 wad) internal view returns (uint256 amt) {
        amt = wad / 10 ** (_sub(18, GemJoinLike_4(gemJoin).dec()));
    }

    function clipperCall(
        address sender,            // Clipper caller, pays back the loan
        uint256 owe,               // Dai amount to pay back        [rad]
        uint256 slice,             // Gem amount received           [wad]
        bytes calldata data        // Extra data, see below
    ) external {
        (
            address to,            // address to send remaining DAI to
            address gemJoin,       // gemJoin adapter address
            uint256 minProfit,     // minimum profit in DAI to make [wad]
            address psm            // psm address for swapping collateral to DAI
        ) = abi.decode(data, (address, address, uint256, address));

        // Convert slice to token precision
        slice = _fromWad(gemJoin, slice);

        // Exit gem to token
        GemJoinLike_4(gemJoin).exit(address(this), slice);

        // Approve psm's gemJoin to take gem
        TokenLike_3 gem = GemJoinLike_4(gemJoin).gem();
        gem.approve(PSMLike(psm).gemJoin(), slice);

        // Calculate amount of DAI to Join (as erc20 WAD value)
        uint256 daiToJoin = _divup(owe, RAY);

        PSMLike(psm).sellGem(address(this), slice);
        require(dai.balanceOf(address(this)) > _add(daiToJoin, minProfit), "Not enough dai from psm");

        // Although psm will accept all gems, this check is a sanity check, just in case
        // Transfer any lingering gem to specified address
        if (gem.balanceOf(address(this)) > 0) {
            gem.transfer(to, gem.balanceOf(address(this)));
        }

        // Convert DAI bought to internal vat value of the msg.sender of Clipper.take
        daiJoin.join(sender, daiToJoin);

        // Transfer remaining DAI to specified address
        dai.transfer(to, dai.balanceOf(address(this)));
    }
}