// SPDX-License-Identifier: MIT
pragma solidity ^0.8.5;

import "./TransferHelper.sol";
import "./Ownable.sol";

interface Token {
    function balanceOf(address who) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);
}

contract DynamicBulkTransfer is Ownable {
    function makeTransfer(
        address payable[] memory addressArray,
        uint256[] memory amountArray,
        address contactAddress
    ) external {
        require(
            addressArray.length == amountArray.length,
            "Arrays must be of same size."
        );
        Token tokenInstance = Token(contactAddress);
        for (uint256 i = 0; i < addressArray.length; i++) {
            require(
                tokenInstance.allowance(msg.sender, address(this)) >=
                    amountArray[i],
                "Insufficient allowance."
            );
            require(
                tokenInstance.balanceOf(msg.sender) >= amountArray[i],
                "Owner has insufficient token balance."
            );
            TransferHelper.safeTransferFrom(
                contactAddress,
                msg.sender,
                addressArray[i],
                amountArray[i] 
            );
        }
    }
}