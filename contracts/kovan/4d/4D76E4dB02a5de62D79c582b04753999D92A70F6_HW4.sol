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

//You will build a payment splitter that splits an incoming payment evenly between each recipient.
// **As opposed to sending the split funds immediately,
//you should keep track of the balance for each receiving party and enable them to withdraw at a later date.**

//Events are given in the interface and should be emitted at the appropriate time, per description.

contract HW4 is IOwnable, IPausable, ISplitter {
    //solhint-disable ordering
    function getMax(uint256[] calldata array) external pure returns (uint256) {
        // Write your code here
        uint256 max = 0;
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] > max) {
                max = array[i];
            }
        }

        return max;
    }

    // Declare any necessary variables here
    address private _owner;
    bool private _paused;
    mapping(address => uint256) public balances;

    // What goes in here?

    constructor() {
        _owner = msg.sender;
        _paused = false;
    }

    // Add any modifiers here
    modifier onlyOwner() {
        require(_owner == msg.sender, "Sender is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!_paused, "Contract paused");
        _;
    }

    // Write your code here
    function transferOwnership(address newOwner) external override onlyOwner {
        _owner = newOwner;

        emit OwnershipTransferred(newOwner);
    }

    function togglePause() external override onlyOwner {
        _paused = !_paused;
    }

    // This function cannot be called if the contract is paused
    function deposit(address[] calldata recipients)
        external
        payable
        override
        whenNotPaused
    {
        uint256 depositAmount = msg.value;
        uint256 numOfRecipients = recipients.length;
        // Calculate share by dividing deposit amount by number of recipients
        // Assuming the shares are equal
        uint256 recipientShare = depositAmount / numOfRecipients;

        // Add individual recipient shares to existing recipient balance
        for (uint256 i = 0; i < numOfRecipients; i++) {
            address recipient = recipients[i];
            // Add new share to balance as opposed to overwriting it
            balances[recipient] += recipientShare;
        }

        // Emit deposit event on deposit complete
        emit DidDepositFunds(depositAmount, recipients);
    }

    // This function cannot be called if the contract is paused
    // Assumes `amount` to withdraw is in wei and not ethers
    function withdraw(uint256 amount) external override whenNotPaused {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // Subtract amount from user balance
        balances[msg.sender] -= amount;
        // Transfer to user
        payable(msg.sender).transfer(amount);

        // Emit withdraw event on withdrawal complete;
        emit DidWithdrawFunds(amount, msg.sender);
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function paused() external view override returns (bool) {
        return _paused;
    }

    function balanceOf(address addr) external view override returns (uint256) {
        return balances[addr];
    }

    receive() external payable {}
}