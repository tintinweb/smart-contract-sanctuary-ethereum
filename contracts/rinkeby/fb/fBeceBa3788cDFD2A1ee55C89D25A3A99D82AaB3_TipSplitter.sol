//SPDX-License-Identifier: MIT

pragma solidity 0.8.10;
contract TipSplitter {
    
    uint256 public percentage;
    address payable public owner;

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    constructor(uint256 _percentage, address payable _owner) {
        percentage = _percentage;
        owner = _owner;
    }

    function transferOwnerShip(address payable _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setPercentage(uint256 _percentage) external onlyOwner {
        percentage = _percentage;
    }

    function splitTip(address payable contentOwner) external payable {
        uint256 adminShare = msg.value * percentage / 100;
        owner.transfer(adminShare);
        contentOwner.transfer(address(this).balance);  
    }

}