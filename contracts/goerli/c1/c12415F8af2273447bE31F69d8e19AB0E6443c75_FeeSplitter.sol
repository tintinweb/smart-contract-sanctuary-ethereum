// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.15;

// XXX REMOVE BEFORE PUBLIC RELEASE
// import "./console.sol"; // allows JS style console.log() from solidity code running in dev environment // allows JS style console.log() from solidity code running in dev environment

import "./IERC20.sol";

/**
 * @title FeeSplitter
 */
contract FeeSplitter {
    address payable private recipient1;
    address payable private recipient2;
    address payable private recipient3;

    constructor(
        address payable _recipient1,
        address payable _recipient2,
        address payable _recipient3
    )
    {
        recipient1 = _recipient1;
        recipient2 = _recipient2;
        recipient3 = _recipient3;
    }

    receive(
    )
        external
        payable
    {
        splitNative(msg.value);
    }

    error SplitNativeFailed(
        bool recipient1,
        bool recipient2,
        bool recipient3
    );
    function splitNative(uint256 value)
        private
    {
        // @dev do not refund remainder but include it in next splitNative() call
        uint256 prevBalance = address(this).balance - value;
        uint256 splitAmount = (value + prevBalance) / 3;

        (bool sent1,/* data */) = recipient1.call{value: splitAmount}("");
        (bool sent2,/* data */) = recipient2.call{value: splitAmount}("");
        (bool sent3,/* data */) = recipient3.call{value: splitAmount}("");

        if (!sent1 || !sent2 || !sent3) revert SplitNativeFailed(sent1, sent2, sent3);
    }

    function splitERC20(address tokenAddress, uint256 amount) public returns (bool) {
        require(amount > 0, "No tokens specified");

        IERC20 token = IERC20(tokenAddress);
        uint256 senderBalance = token.balanceOf(msg.sender);
        require(senderBalance >= amount, "Insufficient token balance");

        // @dev do not refund remainder but include it in next splitNative() call
        uint256 splitAmount = (senderBalance + amount) / 3;

        token.transferFrom(msg.sender, recipient1, splitAmount);
        token.transferFrom(msg.sender, recipient2, splitAmount);
        token.transferFrom(msg.sender, recipient3, splitAmount);

        return true;

    }
}