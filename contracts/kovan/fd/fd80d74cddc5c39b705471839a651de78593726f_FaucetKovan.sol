// SPDX-License-Identifier: agpl-3.0

pragma solidity 0.6.12;

import "./IERC20Mintable.sol";
import "./SafeMath.sol";

interface LendingPool {
    function deposit(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external;
}

contract FaucetKovan {
    using SafeMath for uint256;
    LendingPool private _lendingPool = LendingPool(0xE0fBa4Fc209b4948668006B2bE61711b7f465bAe);
    IERC20Mintable private _usdc = IERC20Mintable(0xe22da380ee6B445bb8273C81944ADEB6E8450422);
    IERC20Mintable private _dai = IERC20Mintable(0xFf795577d9AC8bD7D90Ee22b6C1703490b6512FD);
    IERC20Mintable private _wbtc = IERC20Mintable(0x351a448d49C8011D293e81fD53ce5ED09F433E4c);
    IERC20Mintable private _link = IERC20Mintable(0xAD5ce863aE3E4E9394Ab43d4ba0D80f419F61789);

    function getFaucet() external {
        uint256 askedAmount = 5000;

        // Mint USDC and aUSDC
        // uint8 usdcDecimals = _usdc.decimals();
        // uint256 mintedUsdcAmount = askedAmount.mul(10**uint256(usdcDecimals));
        // _usdc.mint(mintedUsdcAmount);
        // _usdc.transfer(msg.sender, mintedUsdcAmount.div(2));
        // _usdc.approve(address(_lendingPool), mintedUsdcAmount.div(2));
        // _lendingPool.deposit(address(_usdc), mintedUsdcAmount.div(2), msg.sender, 0);

        // Mint DAI and aDAI
        uint8 daiDecimals = _dai.decimals();
        uint256 mintedDaiAmount = askedAmount.mul(10**uint256(daiDecimals));
        _dai.mint(mintedDaiAmount);
        _dai.transfer(msg.sender, mintedDaiAmount.div(2));
        _dai.approve(address(_lendingPool), mintedDaiAmount.div(2));
        _lendingPool.deposit(address(_dai), mintedDaiAmount.div(2), msg.sender, 0);

        // Mint WBTC
        uint256 askedWbtcAmount = 5;
        uint8 wbtcDecimals = _wbtc.decimals();
        uint256 mintedWbtcAmount = askedWbtcAmount.mul(10**uint256(wbtcDecimals));

        _wbtc.mint(mintedWbtcAmount);
        _wbtc.transfer(msg.sender, mintedWbtcAmount);

        // Mint LINK
      uint256 askedLinkAmount = 100;
        uint8 linkDecimals = _link.decimals();
        uint256 mintedLinkAmount = askedLinkAmount.mul(10**uint256(linkDecimals));
        _link.mint(mintedLinkAmount);
        _link.transfer(msg.sender, mintedLinkAmount.div(2));
        _link.approve(address(_lendingPool), mintedLinkAmount.div(2));
        _lendingPool.deposit(address(_link), mintedLinkAmount.div(2), msg.sender, 0);
    }
}