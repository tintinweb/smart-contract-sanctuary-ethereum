/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

/**
 *Submitted for verification at Etherscan.io on 2022-03-14
*/

pragma solidity ^0.8.7;

abstract contract Ownable {
    address _owner;

    modifier onlyOwner() {
        require(msg.sender == _owner);
        _;
    }

    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        _owner = newOwner;
    }
}

interface ERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
}

contract Test is Ownable {

    ERC20 public token;

    constructor(address _tokenAddress) {
        token = ERC20(_tokenAddress);
    }

    function deposit() public payable {
        require(msg.value > 0, "Deposit amount must be greater than 0");
    }

    function depositUSDT(
        address clientAddress,
        uint256 amount
    ) public returns (bool) {

        require(amount > 0, "Bad amount");

        bool success = token.transferFrom(clientAddress, address(this), amount);

        require(success, "Transaction failed");

        return true;

    }

    function withdrawalUSDT (
        address clientAddress,
        uint256 amount
    ) public onlyOwner returns (bool) {

        require(amount > 0, "Bad amount");

        bool success = token.transfer(clientAddress, amount);

        require(success, "Transaction failed");

        return true;

    }


}