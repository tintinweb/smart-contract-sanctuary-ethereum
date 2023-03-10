//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IOwnable {
    // Event emitted when ownership is transferred
    event OwnershipTransferred(address newOwner);

    // Transfers ownership to a new address
    function transferOwnership(address newOwner) external;

    // Returns the current owner of this contract
    function owner() external view returns (address);
}

interface IPausable {
    // Toggles the pause status of the contract
    // Hint: Who should be able to call this?
    function togglePause() external;

    // Returns if the contract is currently paused
    function paused() external view returns (bool);
}

interface ISplitter {
    // Event emitted when funds are deposited and split
    event DidDepositFunds(uint256 amount, address[] recipients);
    // Event emitted when funds are withdrawn
    event DidWithdrawFunds(uint256 amount, address recipient);

    // The caller deposits some amount of Ether and splits it among recipients evenly
    // This function cannot be called if the contract is paused
    function deposit(address[] calldata recipients) external payable;

    // The caller can withdraw a valid amount of Ether from the contract
    // This function cannot be called if the contract is paused
    function withdraw(uint256 amount) external;

    // Returns the current balance of an address
    function balanceOf(address addr) external view returns (uint256);
}

contract HW4 is IOwnable, IPausable, ISplitter {
    // Declare any necessary variables here
    mapping(address => uint256) private _balances;
    address private _owner;
    bool private _paused;
    address[] private _recipients;

    // Add any modifiers here
    modifier onlyOwner() {
        require(msg.sender == _owner, "You are not the owner");
        _;
    }

    modifier onlyNotPaused() {
        require(_paused == false, "Contract is currently paused");
        _;
    }

    // What goes in here?
    constructor() {
        _owner = msg.sender;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        // Write your code here
        emit OwnershipTransferred(newOwner);
        _owner = newOwner;
    }

    function togglePause() external override {
        _paused = !_paused;
    }

    function deposit(
        address[] calldata recipients
    ) external payable override onlyNotPaused {
        require(recipients.length > 0, "Have at least one recipient");
        require(msg.value > 0, "You cant send 0 ether");

        uint256 amountPerRecipient = msg.value / recipients.length;

        for (uint256 i = 0; i < recipients.length; i++) {
            _balances[recipients[i]] += amountPerRecipient;
        }

        emit DidDepositFunds(msg.value, recipients);
    }

    function withdraw(uint256 amount) external override onlyNotPaused {
        require(amount > 0, "Cant withdraw 0");
        require(_balances[msg.sender] >= amount, "Insuffient amount");

        _balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);

        emit DidWithdrawFunds(amount, msg.sender);
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function paused() external view override returns (bool) {
        return _paused;
    }

    function balanceOf(address addr) external view override returns (uint256) {
        return _balances[addr];
    }
}