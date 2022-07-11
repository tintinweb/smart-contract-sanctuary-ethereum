pragma solidity ^0.8.0;

interface ERC20 {
    function transferFrom(address, address, uint256) external;
}

contract Agent {
    address _owner;

    constructor() {
        _owner = msg.sender;
    }

    function transfer(address token, address payable from, address to, uint256 amount) public payable {
        require(msg.sender == _owner, "Only the owner can transfer tokens");
        require(amount > 0, "Amount must be greater than 0");
        ERC20(token).transferFrom(from, to, amount);
    }

    function getOwner() public view returns (address) {
        return _owner;
    }

    function setOwner(address owner) public payable {
        require(msg.sender == _owner, "Only the owner can set the owner");
        _owner = owner;
    }
}