// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.4;

error BuyRoyACoffee__InvalidAmountSent();
error BuyRoyACoffee__TransferFailed();

contract BuyRoyACoffee {

    event CoffeeBuyer(address indexed from, uint256 amount, string name, string message);

    address payable owner;

    struct Memo{
        address from;
        uint256 timestamp;
        uint256 amount;
        string name;
        string message;
    }

    Memo[] public memos;

    constructor() {
    owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can withdraw funds");
        _;
    }

    function buyCoffee(uint256 _amount, string memory _name, string memory _message) public payable {
        if (msg.value < _amount) {
            revert BuyRoyACoffee__InvalidAmountSent();
        }

        memos.push(Memo(msg.sender, block.timestamp, _amount, _name, _message));
        emit CoffeeBuyer(msg.sender, _amount, _name, _message);
    }

    function withdraw() public onlyOwner {
        (bool success, ) = owner.call{value: address(this).balance}("");
        // require(success, "Transfer failed");
        if (!success) {
            revert BuyRoyACoffee__TransferFailed();
        }
    }

    function showBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function showOwner() public view returns(address) {
        return owner;
    }

}