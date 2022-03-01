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
    function getMax(uint256[] calldata array)
        external
        pure
        returns (uint256 store_var)
    {
        for (uint256 i = 0; i < array.length; i++) {
            if (store_var < array[i]) {
                store_var = array[i];
            }
        }
        return store_var;
    }

    // Declare any necessary variables here
    address private _owner;
    address private _pauser;
    bool private _paused;

    // What goes in here?
    constructor() {
        _owner = msg.sender;
        _paused = false;
    }

    // Add any modifiers here
    modifier onlyOwner() {
        require(msg.sender == _owner, "Not owner");
        _;
    }
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }
    modifier onlyPauser() {
        require(msg.sender == _pauser, "caller is not the pauser");
        _;
    }

    function transferOwnership(address newOwner) external override onlyOwner {
        _owner = newOwner;
        emit OwnershipTransferred(newOwner);
    }

    function togglePause() external override onlyOwner {
        if (_paused == false) {
            _paused = true;
        } else {
            _paused = false;
        }
    }

    mapping(address => uint256) public balancesOf;

    function deposit(address[] calldata recipients) external payable override whenNotPaused {
        uint256 amount = ((msg.value) / recipients.length);
        for (uint256 i = 0; i < recipients.length; i++) {
            balancesOf[recipients[i]] += amount;
        }
        emit DidDepositFunds(msg.value, recipients);
    }

    function withdraw(uint256 amount) external override whenNotPaused {
        require(amount <= balancesOf[msg.sender], "can't withdraw without amount");
        balancesOf[msg.sender] -= amount;
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
        return balancesOf[addr];
    }
}