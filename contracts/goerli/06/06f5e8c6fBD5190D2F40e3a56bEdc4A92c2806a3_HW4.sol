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
    address private _owner;
    bool private _pause;

    mapping(address => uint256) private _balances;

    // What goes in here?
    modifier onlyOwnerAccess() {
        require(msg.sender == _owner, "Unauthorized, not owner");
        _;
    }
    modifier checkPause() {
        require(_pause == false, "Contract is paused");
        _;
    }

    constructor() {
        _owner = msg.sender;
        //I think this pause = false is not necessary?
        _pause = false;
    }

    // Add any modifiers here

    function transferOwnership(
        address newOwner
    ) external override onlyOwnerAccess {
        require(newOwner != address(0), "Invalid owner address");
        _owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    function togglePause() external override onlyOwnerAccess {
        _pause = !_pause;
        /* write code that allows the currentOwner to toggle 
        the pause Boolean status of a defined variable PAUSE 
        ADD A CHECK OWNER MODIFIER */
    }

    function deposit(
        address[] calldata recipients
    ) external payable override checkPause {
        require(msg.value > 0, "Amount must be greater than 0");
        require(recipients.length > 0, "Must have at least one recipient");
        uint256 amount = msg.value / recipients.length;
        for (uint256 i = 0; i < recipients.length; i++) {
            _balances[recipients[i]] += amount;
        }
        emit DidDepositFunds(amount, recipients);
        /* split the deposit evenly between the address array
        and update thier balances 
        require that the payable is more than 0
        require that the address array is not empty
        can not be called if contract is PAUSE*/
    }

    function withdraw(uint256 amount) external override checkPause {
        require(_balances[msg.sender] >= amount, "Insufficient balance");
        _balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
        /* write code that allows the msg.sender to withdraw funds from the callers balance
        require the balance be greater or equal to the withdraw amount
        send funds to the msg caller
        can not be called if contract is PAUSE */
        emit DidWithdrawFunds(amount, msg.sender);
    }

    function owner() external view override returns (address) {
        return _owner;
    }

    function paused() external view override returns (bool) {
        return _pause;
        /* write code that returns the current pause status */
    }

    function balanceOf(address addr) external view override returns (uint256) {
        return _balances[addr];
        /* write code that returns the current balance of an address */
    }
}