/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// hevm: flattened sources of src/CurveLpTokenUniv3Callee.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity =0.6.12;
pragma experimental ABIEncoderV2;

////// src/CurveLpTokenUniv3Callee.sol
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

interface GemJoinLike_2 {
    function dec() external view returns (uint256);
    function gem() external view returns (address);
    function exit(address, uint256) external;
}

interface DaiJoinLike_1 {
    function dai() external view returns (TokenLike_1);
    function join(address, uint256) external;
}

interface TokenLike_1 {
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function symbol() external view returns (string memory);
}

interface ManagerLike {
    function exit(address crop, address usr, uint256 val) external;
}

interface CurvePoolLike_1 {
    function remove_liquidity_one_coin(uint256 _token_amount, int128 i, uint256 _min_amount)
        external returns (uint256);
    function coins(uint256) external view returns (address);
}

interface WethLike_1 is TokenLike_1 {
    function deposit() external payable;
}

interface UniV3RouterLike_1 {
    
    struct ExactInputParams_1 {
        bytes   path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(UniV3RouterLike_1.ExactInputParams_1 calldata params)
        external payable returns (uint256 amountOut);
}

contract CurveLpTokenUniv3Callee {
    UniV3RouterLike_1 public immutable uniV3Router;
    DaiJoinLike_1     public immutable daiJoin;
    TokenLike_1       public immutable dai;
    address         public immutable weth;

    uint256         public constant RAY = 10 ** 27;
    address         public constant ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function _add(uint x, uint y) internal pure returns (uint z) {
        require((z = x + y) >= x, "ds-math-add-overflow");
    }
    function _sub(uint x, uint y) internal pure returns (uint z) {
        require((z = x - y) <= x, "ds-math-sub-underflow");
    }
    function _divup(uint256 x, uint256 y) internal pure returns (uint256 z) {
        z = _add(x, _sub(y, 1)) / y;
    }

    struct CurveData {
        address pool;
        uint256 coinIndex;
    }

    constructor(
        address uniV3Router_,
        address daiJoin_,
        address weth_
    ) public {
        uniV3Router    = UniV3RouterLike_1(uniV3Router_);
        daiJoin        = DaiJoinLike_1(daiJoin_);
        TokenLike_1 dai_ = DaiJoinLike_1(daiJoin_).dai();
        dai            = dai_;
        weth           = weth_;

        dai_.approve(daiJoin_, type(uint256).max);
    }

    receive() external payable {}

    function _fromWad(address gemJoin, uint256 wad) internal view returns (uint256 amt) {
        amt = wad / 10 ** (_sub(18, GemJoinLike_2(gemJoin).dec()));
    }

    function clipperCall(
        address sender,            // Clipper caller, pays back the loan
        uint256 owe,               // Dai amount to pay back        [rad]
        uint256 slice,             // Gem amount received           [wad]
        bytes calldata data        // Extra data, see below
    ) external {
        (
            address          to,        // address to send remaining DAI to
            address          gemJoin,   // gemJoin adapter address
            uint256          minProfit, // minimum profit in DAI to make [wad]
            bytes memory     path,      // uniswap v3 path
            address          manager,   // pass address(0) if no manager
            CurveData memory curveData  // curve pool data
        ) = abi.decode(data, (address, address, uint256, bytes, address, CurveData));

        address gem = GemJoinLike_2(gemJoin).gem();

        // Convert slice to token precision
        slice = _fromWad(gemJoin, slice);

        // Exit gem to token
        if(manager != address(0)) {
            ManagerLike(manager).exit(gemJoin, address(this), slice);
        } else {
            GemJoinLike_2(gemJoin).exit(address(this), slice);
        }

        // curveData used explicitly to avoid stack too deep
        TokenLike_1(gem).approve(curveData.pool, slice);
        slice = CurvePoolLike_1(curveData.pool).remove_liquidity_one_coin({
            _token_amount: slice,
            i:             int128(curveData.coinIndex),
            _min_amount:   0 // minProfit is checked below
        });

        gem = CurvePoolLike_1(curveData.pool).coins(curveData.coinIndex);
        if (gem == ETH) {
            gem = weth;
            WethLike_1(gem).deposit{
                value: slice
            }();
        }

        // Approve uniV3 to take gem
        TokenLike_1(gem).approve(address(uniV3Router), slice);

        // Calculate amount of DAI to Join (as erc20 WAD value)
        uint256 daiToJoin = _divup(owe, RAY);

        UniV3RouterLike_1.ExactInputParams_1 memory params = UniV3RouterLike_1.ExactInputParams_1({
            path:             path,
            recipient:        address(this),
            deadline:         block.timestamp,
            amountIn:         slice,
            amountOutMinimum: _add(daiToJoin, minProfit)
        });
        uniV3Router.exactInput(params);

        // Although Uniswap will accept all gems, this check is a sanity check, just in case
        // Transfer any lingering gem to specified address
        if (TokenLike_1(gem).balanceOf(address(this)) > 0) {
            TokenLike_1(gem).transfer(to, TokenLike_1(gem).balanceOf(address(this)));
        }

        // Convert DAI bought to internal vat value of the msg.sender of Clipper.take
        daiJoin.join(sender, daiToJoin);

        // Transfer remaining DAI to specified address
        dai.transfer(to, dai.balanceOf(address(this)));
    }
}