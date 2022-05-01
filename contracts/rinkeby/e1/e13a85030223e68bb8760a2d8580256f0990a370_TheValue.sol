/**
 *Submitted for verification at Etherscan.io on 2022-05-01
*/

pragma solidity >=0.7.0 <0.9.0;

contract TheValue {

    address private owner;
    string public value;
    uint price = 1000;
    
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    modifier isPaid() {
        require(msg.value >= price, "Must pay equal or more than price");
        _;
    }

    constructor() {
        owner = msg.sender;
        emit OwnerSet(address(0), owner);
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function getOwner() external view returns (address) {
        return owner;
    }
    function changePrice(uint _price) public  isOwner {
        price = _price;
    }

    function changeValue(string memory _value) public payable isPaid {
        require(keccak256(abi.encodePacked(_value)) != keccak256(abi.encodePacked(value)), "Value must be different");
        value = _value;
    }
}