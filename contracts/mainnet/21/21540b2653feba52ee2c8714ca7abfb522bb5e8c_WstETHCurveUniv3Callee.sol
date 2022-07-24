/**
 *Submitted for verification at Etherscan.io on 2022-07-24
*/

// hevm: flattened sources of src/WstETHCurveUniv3Callee.sol
// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.6.12;
pragma experimental ABIEncoderV2;

////// src/WstETHCurveUniv3Callee.sol
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

interface GemJoinLike_7 {
    function dec() external view returns (uint256);
    function gem() external view returns (address);
    function exit(address, uint256) external;
}

interface DaiJoinLike_6 {
    function dai() external view returns (TokenLike_6);
    function join(address, uint256) external;
}

interface TokenLike_6 {
    function approve(address, uint256) external;
    function transfer(address, uint256) external;
    function balanceOf(address) external view returns (uint256);
    function symbol() external view returns (string memory);
}

interface CharterManagerLike_4 {
    function exit(address crop, address usr, uint256 val) external;
}

interface WstEthLike is TokenLike_6 {
    function unwrap(uint256 _wstEthAmount) external returns (uint256);
    function stETH() external view returns (address);
}

interface CurvePoolLike_2 {
    function exchange(int128 i, int128 j, uint256 dx, uint256 min_dy)
        external returns (uint256 dy);
}

interface WethLike_2 is TokenLike_6 {
    function deposit() external payable;
}

interface UniV3RouterLike_3 {
    
    struct ExactInputParams_3 {
        bytes   path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    function exactInput(UniV3RouterLike_3.ExactInputParams_3 calldata params)
        external payable returns (uint256 amountOut);
}

contract WstETHCurveUniv3Callee {
    CurvePoolLike_2   public immutable curvePool;
    UniV3RouterLike_3 public immutable uniV3Router;
    DaiJoinLike_6     public immutable daiJoin;
    TokenLike_6       public immutable dai;
    address         public immutable weth;

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
        address uniV3Router_,
        address daiJoin_,
        address weth_
    ) public {
        curvePool      = CurvePoolLike_2(curvePool_);
        uniV3Router    = UniV3RouterLike_3(uniV3Router_);
        daiJoin        = DaiJoinLike_6(daiJoin_);
        TokenLike_6 dai_ = DaiJoinLike_6(daiJoin_).dai();
        dai            = dai_;
        weth           = weth_;

        dai_.approve(daiJoin_, type(uint256).max);
    }

    receive() external payable {}

    function _fromWad(address gemJoin, uint256 wad) internal view returns (uint256 amt) {
        amt = wad / 10 ** (_sub(18, GemJoinLike_7(gemJoin).dec()));
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
            bytes memory path,     // uniswap v3 path
            address charterManager // pass address(0) if no manager
        ) = abi.decode(data, (address, address, uint256, bytes, address));

        address gem = GemJoinLike_7(gemJoin).gem();

        // Convert slice to token precision
        slice = _fromWad(gemJoin, slice);

        // Exit gem to token
        if(charterManager != address(0)) {
            CharterManagerLike_4(charterManager).exit(gemJoin, address(this), slice);
        } else {
            GemJoinLike_7(gemJoin).exit(address(this), slice);
        }

        slice = WstEthLike(gem).unwrap(slice);
        gem = WstEthLike(gem).stETH();

        TokenLike_6(gem).approve(address(curvePool), slice);
        slice = curvePool.exchange({
            i:      1,     // send token id 1 (stETH)
            j:      0,     // receive token id 0 (ETH)
            dx:     slice, // send `slice` amount of stETH
            min_dy: 0      // accept any amount of ETH (`minProfit` is checked below)
        });

        gem = weth;
        WethLike_2(gem).deposit{
            value: slice
        }();

        // Approve uniV3 to take gem
        WethLike_2(gem).approve(address(uniV3Router), slice);

        // Calculate amount of DAI to Join (as erc20 WAD value)
        uint256 daiToJoin = _divup(owe, RAY);

        // Do operation and get dai amount bought (checking the profit is achieved)
        UniV3RouterLike_3.ExactInputParams_3 memory params = UniV3RouterLike_3.ExactInputParams_3({
            path:             path,
            recipient:        address(this),
            deadline:         block.timestamp,
            amountIn:         slice,
            amountOutMinimum: _add(daiToJoin, minProfit)
        });
        uniV3Router.exactInput(params);

        // Although Uniswap will accept all gems, this check is a sanity check, just in case
        // Transfer any lingering gem to specified address
        if (WethLike_2(gem).balanceOf(address(this)) > 0) {
            WethLike_2(gem).transfer(to, WethLike_2(gem).balanceOf(address(this)));
        }

        // Convert DAI bought to internal vat value of the msg.sender of Clipper.take
        daiJoin.join(sender, daiToJoin);

        // Transfer remaining DAI to specified address
        dai.transfer(to, dai.balanceOf(address(this)));
    }
}