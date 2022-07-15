/**
 *Submitted for verification at Etherscan.io on 2022-07-15
*/

pragma solidity >=0.7.0 <0.9.0;

contract TheValue {
    address public owner;
    string public value;
    uint256 public price = 1000;

    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    event ChangeValue(string newValue, address addressWhoChanged);

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

    function returnToOwner() public isOwner {
        payable(owner).transfer(address(this).balance);
    }

    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    function changePrice(uint256 _price) public isOwner {
        price = _price;
    }

    function changeValue(string memory _value) public payable isPaid {
        require(
            keccak256(abi.encodePacked(_value)) !=
                keccak256(abi.encodePacked(value)),
            "Value must be different"
        );
        value = _value;
        emit ChangeValue(value, msg.sender);
    }
}