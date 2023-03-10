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
    address internal _ownerContract;
    mapping(address => uint256) internal _cashAmounts;
    bool internal _pausable = false; // should have declared in the constructor and not necesaary (default value is false anyway)

    modifier onlyOwner() {
        require(msg.sender == _ownerContract, "Not owner");
        _;
    }

    modifier onlyNotPaused() {
        require(_pausable == false, "All transaction are paused"); // require(!_pausable, "All transaction are paused")
        _;
    }

    constructor() {
        _ownerContract = msg.sender;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        require(newOwner != address(0), "Invalid owner address");
        _ownerContract = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    function togglePause() external override onlyOwner {
        _pausable = !_pausable;
    }

    function deposit(
        address[] calldata recipients
    ) external payable override onlyNotPaused {
        // require(msg.value > 0, "Amount must be greater than 0")
        // require(recipients.length > 0, "Must have at least one recipient)
        uint256 cashsent = msg.value;

        for (uint256 i = 0; i < recipients.length; i++) {
            _cashAmounts[recipients[i]] = cashsent / recipients.length;
        }

        // Shorter Version 
        // for (uint256 i = 0; i < recipients.length; i++) {
        //    _cashAmounts[recipients[i]] = msg.value / recipients.length;
        // }

        emit DidDepositFunds(msg.value, recipients);
        // payable means that the caller can send money along side the function call
    }

    function withdraw(uint256 amount) external override onlyNotPaused {
        uint256 accountAmount = _cashAmounts[msg.sender];

        require(amount <= accountAmount, "Not enough money sent");

        _cashAmounts[msg.sender] = _cashAmounts[msg.sender] - amount; //_cashAmounts[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);

        emit DidWithdrawFunds(amount, msg.sender);
    }

    function owner() external view override returns (address) {
        return _ownerContract;
    }

    function paused() external view override returns (bool) {
        return _pausable;
    }

    function balanceOf(address addr) external view override returns (uint256) {
        return _cashAmounts[addr];
    }
}

// TEST