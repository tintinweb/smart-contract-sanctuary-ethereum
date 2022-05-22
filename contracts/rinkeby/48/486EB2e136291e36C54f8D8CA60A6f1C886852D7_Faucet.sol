/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Faucet {
    mapping(address => uint) balances;

    function withdraw(uint _amount) public {
        // users can only withdraw .1 ETH at a time
        require(_amount <= 0.1 * 10 ** 18);
        payable(msg.sender).transfer(_amount);
        updateBalance(msg.sender, _amount);
    }

    function updateBalance(address _address, uint _amount) internal {
        balances[_address] += _amount;
    }

    function checkBalance(address _address) public view returns(uint) {
        return balances[_address];
    }

    // fallback function
    receive() external payable {}
}