/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

//SPDX-License-Identifier: MIT 

pragma solidity ^0.8.0;

contract Piggee{
    mapping(address => uint256) public balancesETH;
    mapping(address => uint256) public unlockTimesETH;

    mapping(address => mapping(address => uint256)) public balancesERC20;
    mapping(address => mapping(address => uint256)) public unlockTimesERC20;

    function depositETH(uint256 _timestamp) external payable {
        require(_timestamp > unlockTimesETH[msg.sender], "The lock timestamp should be greater than the current one");
        balancesETH[msg.sender] += msg.value;
        unlockTimesETH[msg.sender] = _timestamp;
    }
    
    function withdrawETH(uint256 _amount) external {
        require(balancesETH[msg.sender] >= _amount, "Insufficent funds");
        require(unlockTimesETH[msg.sender] < block.timestamp, "The lock period is not over yet");

        balancesETH[msg.sender] -= _amount;
        (bool sent,) = msg.sender.call{value: _amount}("Sent");
        require(sent, "failed to send ETH");
    }

    function ETHBalance(address _address) external view returns (uint256) {
        return balancesETH[_address];
    }

    function ETHUnlockTimestamp(address _address) external view returns (uint256) {
        return unlockTimesETH[_address];
    }

}