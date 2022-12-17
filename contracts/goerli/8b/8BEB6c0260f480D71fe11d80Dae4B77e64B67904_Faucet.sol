/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.5;

error Faucet__NeverWithdraw();

contract Faucet {
    // State variables
    address[] private s_users;
    mapping(address => uint256) private userToTotalWithdraw;

    function withdraw(uint256 _amount) public {
        // users can only withdraw .1 ETH at a time, feel free to change this!
        require(_amount <= 100000000000000000);
        userToTotalWithdraw[msg.sender] += _amount;
        payable(msg.sender).transfer(_amount);
    }

    // pure, view
    function getTotalWithdraw(address _address) public view returns (uint256) {
        if (userToTotalWithdraw[_address] != 0) {
            return userToTotalWithdraw[_address];
        } else {
            revert Faucet__NeverWithdraw();
        }
    }

    // fallback function
    receive() external payable {}
}