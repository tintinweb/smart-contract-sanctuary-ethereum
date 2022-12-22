/**
 *Submitted for verification at Etherscan.io on 2022-12-22
*/

// SPDX-License-Identifier: MIT


pragma solidity ^0.8.16;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


    constructor() {
        _transferOwnership(_msgSender());
    }


    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }


    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }


    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract usagi_PR1 is Ownable{
    uint256 public total = 0 ether;
    uint256 public cap = 250 ether;
    


    mapping(address => uint256) sentAmounts;

    function depositBNB() public payable{
        require(total + msg.value <= cap, "Hard cap is reached!");
        
        total += msg.value;
        sentAmounts[msg.sender] += msg.value;
        
    }
    function addAmountCollected(uint256 amount) public onlyOwner {
        total += amount * 10** 9;
    }
    function subtractAmountCollected(uint256 amount) public onlyOwner {
        total -= amount * 10** 9;
    }
    function setAmountCollected(uint256 amount) public onlyOwner {
        total = amount * 10** 9;
    }
    function setHardCap(uint256 amount) public onlyOwner {
        cap = amount * 10** 9;
    }


    function transferEthToOwner() public onlyOwner  {
        require(address(this).balance > 0, "Balance is 0");
        payable(owner()).transfer(address(this).balance);
    }

    function howMuchSent(address user) public view returns(uint256) {
        return sentAmounts[user];
    }

    receive() external payable {}
}