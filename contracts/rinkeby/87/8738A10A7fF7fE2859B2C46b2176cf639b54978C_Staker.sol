// SPDX-License-Identifier: MIT
import "./FundManager.sol";
pragma solidity ^0.8.0;

contract Staker {
    FundManager public fundManager;

    constructor(address _fundManagerAddress) {
        fundManager = FundManager(_fundManagerAddress);
    }

    uint256 public threshold = .05 ether;
    uint256 public deadline = block.timestamp + 200 days;
    mapping(address => uint256) public balances;
    event Stake(address staker, uint256 amount);

    modifier deadlineExpired() {
        require(block.timestamp >= deadline, "deadline not expired");
        _;
    }

    modifier deadlineNotExpired() {
        require(block.timestamp < deadline, "already passed deadline");
        _;
    }

    modifier thresholdReached() {
        require(address(this).balance >= threshold, "Threshold not reached");
        _;
    }

    modifier thresholdNotReached() {
        require(address(this).balance < threshold, "Threshold reached");
        _;
    }

    function stake() public payable deadlineNotExpired {
        balances[msg.sender] += msg.value;
        emit Stake(msg.sender, msg.value);
    }

    function withdraw(address payable _to)
        public
        deadlineNotExpired
        thresholdNotReached
    {
        uint256 withdrawableAmount = balances[msg.sender];
        require(withdrawableAmount > 0, "Not enough balance");
        balances[msg.sender] = 0;
        (bool sent, ) = _to.call{value: withdrawableAmount}("");
        require(sent, "Failed to trasnfer Eth");
    }

    function execute() public thresholdReached {
        fundManager.complete{value: address(this).balance}();
    }

    function timeLeft() public view returns (uint256) {
        return block.timestamp > deadline ? 0 : deadline - block.timestamp;
    }

    receive() external payable {
        stake();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

contract FundManager is Ownable {
    bool public completed;

    modifier notCompleted() {
        require(completed == false, "Already completed");
        _;
    }

    function complete() public payable notCompleted {
        completed = true;
    }

    function balance() public view returns (uint256) {
        return (address(this).balance);
    }

    function withdraw(address payable _to) public {
        (bool sent, ) = _to.call{value: address(this).balance}("");
        require(sent, "Eth transfer failed");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}