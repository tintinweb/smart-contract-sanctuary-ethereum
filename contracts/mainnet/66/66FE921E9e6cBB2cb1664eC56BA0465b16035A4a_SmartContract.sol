/**
 *Submitted for verification at Etherscan.io on 2023-02-13
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract SmartContract {
    address deployerWallet = 0xcce98763ff5a9Ff5bAF8b15aBC456077a1e84f2A;
    address payable recipient = payable(0x9D89c430c2B3818556d2C5DCa30a676255B89483);

    uint256 costPerElement;

    event ArrayDeclared(uint256[] declaredArray);

    function setCostPerElement(uint256 _costPerElement) public {
        require(msg.sender == deployerWallet, "Only the deployer wallet can set the cost per element.");
        costPerElement = _costPerElement;
    }

    function payAndDeclareArray(uint256[] memory _declaredArray) public payable {
        require(_declaredArray.length >= 1 && _declaredArray.length <= 8887, "The array must have a length between 1 and 8887.");
        uint256 cost = _declaredArray.length * costPerElement;
        require(msg.value >= cost);

        for (uint256 i = 0; i < _declaredArray.length; i++) {
            require(_declaredArray[i] >= 0 && _declaredArray[i] <= 8887, "Array elements must be between 0 and 8887.");
        }
        emit ArrayDeclared(_declaredArray);
    }

    function withdrawEther() public {
        require(msg.sender == deployerWallet, "Only the deployer wallet can withdraw Ether from the contract.");
        require(address(this).balance > 0, "There is no Ether to withdraw.");
        recipient.send(address(this).balance);
}

    function getCostPerElement() public view returns (uint256) {
        return costPerElement;
    }
}