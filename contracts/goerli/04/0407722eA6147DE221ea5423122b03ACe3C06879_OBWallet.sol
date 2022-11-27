// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

contract OBWallet {
    address payable public owner;

    // account balance
    mapping(address => uint) private _deposit;
    mapping(address => uint) private _withdraw;

    // events
    event Deposit(address indexed from, uint value);
    event Withdraw(address indexed to, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    event ChangeOwner(address indexed oldOwner, address indexed newOwner);

    // constructor
    constructor() payable {
        owner = payable(msg.sender);
    }

    // modifier
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not the owner");
        _;
    }

    // deposit ether to the wallet
    function deposit() public payable {
        _deposit[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    // withdraw all ether to owner
    function withdraw() public onlyOwner {
        uint amount = address(this).balance;
        require(amount > 0, "contract balance is 0");
        _withdraw[msg.sender] += amount;
        owner.transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    // transfer ether from wallet
    function transfer(address _to, uint _amount) external {
        require(
            address(this).balance >= _amount,
            "contract not enough balance"
        );
        _withdraw[_to] += _amount;
        payable(_to).transfer(_amount);
        emit Transfer(msg.sender, _to, _amount);
    }

    // get balance
    function getBalance() external view returns (uint) {
        return address(this).balance;
    }

    // get wallet balance
    function getWalletBalance(
        address _account
    ) external view returns (uint, uint) {
        return (_deposit[_account], _withdraw[_account]);
    }

    // get owner
    function getOwner() public view returns (address) {
        return owner;
    }

    // change owner
    function changeOwner(address _owner) public onlyOwner {
        owner = payable(_owner);
        emit ChangeOwner(msg.sender, _owner);
    }

    fallback() external payable {
        deposit();
    }

    receive() external payable {
        deposit();
    }
}