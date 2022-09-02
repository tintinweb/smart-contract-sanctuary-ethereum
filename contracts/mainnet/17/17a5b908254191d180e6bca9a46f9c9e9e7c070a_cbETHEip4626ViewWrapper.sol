// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

/**
    cbETH Wrapper that implements EIP-4626. It only includes the view functions that is not related to deposit, withdraw, redeem as those functions are not publically accessible. 
 */
contract cbETHEip4626ViewWrapper {
    IERC20 public constant cbETH = IERC20(0xBe9895146f7AF43049ca1c1AE358B0541Ea49704);
    address public constant asset = address(0);
    uint256 private constant BASE_UNIT = 1e18;

    function totalAssets() public view returns (uint256) {
        return cbETH.totalSupply() * cbETH.exchangeRate() / BASE_UNIT;
    }

    function convertToShares(uint256 assets) public view virtual returns (uint256) {
        return assets * BASE_UNIT / cbETH.exchangeRate() ;
    }

    function convertToAssets(uint256 shares) public view virtual returns (uint256) {
        return shares * cbETH.exchangeRate() / BASE_UNIT;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function exchangeRate() external view returns (uint256 _exchangeRate);
}