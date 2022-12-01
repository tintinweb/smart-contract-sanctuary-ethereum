/**
 *Submitted for verification at Etherscan.io on 2022-11-30
*/

/**
 * SPDX-License-Identifier: MIT
 **/

pragma solidity ^0.8.17;
pragma experimental ABIEncoderV2;

interface IWETH {
    function withdraw(uint256) external;
    function balanceOf(address) external returns (uint256);
}

/// @title UnwrapAndSendETH
/// @notice Helper contract for pipeline to unwrap WETH and send to an account
/// @author 0xkokonut
contract UnwrapAndSendETH {
    receive() external payable {}

    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    /// @notice Unwrap WETH and send ETH to the specified address
    /// @dev Make sure to load WETH into this contract before calling this function
    function unwrapAndSendETH(address to) external {
        uint256 wethBalance = IWETH(WETH).balanceOf(address(this));
        require(wethBalance > 0, "Insufficient WETH");
        IWETH(WETH).withdraw(wethBalance);
        (bool success, ) = to.call{value: address(this).balance}(
            new bytes(0)
        );
        require(success, "Eth transfer Failed.");
    }
}