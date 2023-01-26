/**
 *Submitted for verification at Etherscan.io on 2023-01-26
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8;

contract EthDispenser {
    receive() external payable {}

    /* @function: stringToUint()
     * @params: s - incoming string to convert to uint
     * @description: converts incoming string to uint
     */
    function stringToUint(string memory s)
        private
        pure
        returns (uint256 result)
    {
        bytes memory b = bytes(s);
        uint256 i;
        result = 0;
        for (i = 0; i < b.length; i++) {
            uint256 c = uint256(uint8(b[i]));
            if (c >= 48 && c <= 57) {
                result = result * 10 + (c - 48);
            }
        }
    }

    /* @function: getBalance()
     * @params: n/a
     * @description: returns current contract balance
     */
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    /* @function: splitEther()
     * @params: address - payable address array of recipient addresses
     * @params: values - string array of amounts to dispense
     * @description: transfers specified amounts to each specified address
     */
    function dispenseEther(
        address payable[] calldata recipients,
        string[] calldata amounts
    ) external payable {
        require(recipients.length == amounts.length, "mismatched input!");

        for (uint256 i = 0; i < recipients.length; i++) {
            (bool sent, ) = recipients[i].call{value: stringToUint(amounts[i])}(
                ""
            );
            require(
                sent,
                "Failed to dispense Ether... contract may not have sufficient funds."
            );
        }

        uint256 remainingBalance = this.getBalance();

        if (remainingBalance > 0) {
            address payable sender = payable(msg.sender);

            (bool sent, ) = sender.call{value: remainingBalance}("");
            require(sent, "Refund failed.");
        }
    }
}