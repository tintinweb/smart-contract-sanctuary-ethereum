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
    // solhint-disable ordering
    function getMax(uint256[] calldata array) external pure returns (uint256) {
        uint256 max = array[0];
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] > max) {
                max = array[i];
            }
        }
        return max;
    }

    // Declare any necessary variables here

    // What goes in here?
    address private _owner;
    bool private _toggle;
    mapping(address => uint256) internal _usrBal; // will keep track of users balance

    constructor() {
        _owner = msg.sender;
        _toggle = false;
    }

    // Add any modifiers here
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }
    modifier onlyNotPaused() {
        require(_toggle == false, "Do not have access");
        _;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        // Write your code here
        _owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    function togglePause() external override onlyOwner {
        if (_toggle == false) {
            _toggle = true;
        } else {
            _toggle = false;
        }
    }

    function deposit(address[] calldata recipients)
        external
        payable
        override
        onlyNotPaused
    {
        uint256 amt = msg.value;
        amt = amt / recipients.length; //used to equally share funds
        for (uint256 i = 0; i < recipients.length; i++) {
            _usrBal[recipients[i]] += amt;
        }
        emit DidDepositFunds(msg.value, recipients);
    }

    function withdraw(uint256 amount) external override onlyNotPaused {
        require(_usrBal[msg.sender] >= amount, "Not enough funds to withdraw");
        _usrBal[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        emit DidWithdrawFunds(amount, msg.sender);
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function paused() external view override returns (bool) {
        return _toggle;
    }

    function balanceOf(address addr) external view override returns (uint256) {
        return _usrBal[addr];
    }
}