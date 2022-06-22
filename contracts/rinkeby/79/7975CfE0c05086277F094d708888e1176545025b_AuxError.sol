/**
 *Submitted for verification at Etherscan.io on 2022-06-21
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract AuxError {
    uint8 fee;
    
    constructor() {
        fee = 2;
    }

	function pay(uint amount) external payable {
        require((amount + calculatePercent(amount, fee)) == msg.value, "The value sent must be equal to the amount from item more fee");       
    }

    function calculatePercent(uint256 amount, uint8 percent) private pure returns(uint256) {
        return amount / 100 * percent;
    }
}