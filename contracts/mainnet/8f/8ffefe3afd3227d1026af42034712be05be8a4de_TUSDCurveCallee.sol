/**
 *Submitted for verification at Etherscan.io on 2022-03-20
*/

// hevm: flattened sources of src/TUSDCurveCallee.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

////// src/TUSDCurveCallee.sol
// Copyright (C) 2022 Dai Foundation
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

/* pragma solidity 0.6.12; */
/* pragma experimental ABIEncoderV2; */

interface GemJoinLike_4 {
    function gem() external view returns (address);
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

interface CurvePoolLike_2 {
    function exchange_underlying(int128 i, int128 j, uint256 dx, uint256 min_dy)
        external returns (uint256 dy);
}

contract TUSDCurveCallee {
    CurvePoolLike_2   public immutable curvePool;
    DaiJoinLike_3     public immutable daiJoin;
    TokenLike_3       public immutable dai;

    uint256         public constant RAY = 10 ** 27;

    function _add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function _sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function _divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = _add(x, _sub(y, 1)) / y;
    }

    constructor(
        address curvePool_,
        address daiJoin_
    ) public {
        curvePool      = CurvePoolLike_2(curvePool_);
        daiJoin        = DaiJoinLike_3(daiJoin_);
        TokenLike_3 dai_ = DaiJoinLike_3(daiJoin_).dai();
        dai            = dai_;

        dai_.approve(daiJoin_, type(uint256).max);
    }

    receive() external payable {}

    function clipperCall(
        address sender,            // Clipper caller, pays back the loan
        uint256 owe,               // Dai amount to pay back        [rad]
        uint256 slice,             // Gem amount received           [wad]
        bytes calldata data        // Extra data, see below
    ) external {
        (
            address to,            // address to send remaining DAI to
            address gemJoin,       // gemJoin adapter address
            uint256 minProfit      // minimum profit in DAI to make [wad]
        ) = abi.decode(data, (address, address, uint256));

        address tusd = GemJoinLike_4(gemJoin).gem();

        // Note - no need to convert slice to token precision as this contract TUSD specific (18 decimals)

        // Exit gem to token
        GemJoinLike_4(gemJoin).exit(address(this), slice);

        // Convert `owe` from RAD to WAD
        uint256 daiToJoin = _divup(owe, RAY);

        TokenLike_3(tusd).approve(address(curvePool), slice);
        curvePool.exchange_underlying({
            i:      0,     // send token id (TUSD)
            j:      1,     // receive token id (DAI)
            dx:     slice, // send `slice` amount of TUSD
            min_dy: _add(daiToJoin, minProfit)
        });

        // Although Curve will accept all gems, this check is a sanity check, just in case
        // Transfer any lingering gem to specified address
        if (TokenLike_3(tusd).balanceOf(address(this)) > 0) {
            TokenLike_3(tusd).transfer(to, TokenLike_3(tusd).balanceOf(address(this)));
        }

        // Convert DAI bought to internal vat value of the msg.sender of Clipper.take
        daiJoin.join(sender, daiToJoin);

        // Transfer remaining DAI to specified address
        dai.transfer(to, dai.balanceOf(address(this)));
    }
}