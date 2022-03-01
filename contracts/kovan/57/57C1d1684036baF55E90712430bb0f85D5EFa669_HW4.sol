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
    // Hint: Who should be able to call this? - done
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
        uint256 i;
        uint256 largest = 0;
        for (i = 0; i < array.length; i++) {
            if (array[i] > largest) {
                largest = array[i];
            }
        }
        return largest;
    }

    // Declare any necessary variables here
    bool internal ison; //Determines whether contract is on
    address private theowner;
    mapping(address => uint256) public _Balances;

    // What goes in here? - This sets owner as the deployer of the contract.
    constructor() {
        theowner = msg.sender;
    }

    // Add any modifiers here

    modifier onlyNotPaused() {
        require(ison == false, "contract is paused."); /// @notice Explain to an end user what this does
        /// Only works function when utrned on.
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == theowner, "Must be owner.");
        _;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        theowner = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    function togglePause() external override onlyOwner {
        if (ison == true) {
            ison = false;
        } else {
            ison = true;
        }
    }

    //toggles pause

    function deposit(address[] calldata recipients)
        external
        payable
        override
        onlyNotPaused
    {
        uint256 perUser = (msg.value / recipients.length);
        uint256 i = 0;

        for (i = 0; i < recipients.length; i++) {
            //require (recipients[i] >= address(0), "Empty address in recipients");
            _Balances[recipients[i]] += perUser;
        }
        emit DidDepositFunds(msg.value, recipients);
    }

    function withdraw(uint256 amount) external override onlyNotPaused {
        require(amount <= _Balances[msg.sender], "You don't have that amount");
        payable(msg.sender).transfer(amount);
        _Balances[msg.sender] -= amount;
        emit DidWithdrawFunds(amount, msg.sender);
    }

    function owner() external view override returns (address) {
        return theowner;
    }

    //returns owner of contract
    function paused() external view override returns (bool) {
        return ison;
    }

    function balanceOf(address addr) external view override returns (uint256) {
        return _Balances[addr];
    }
}