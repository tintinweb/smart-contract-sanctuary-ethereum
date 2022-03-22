/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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

/// @title EthPool provides a pool for users to deposit into in order to earn rewards in ETH
/// @author Rootul Patel
/// @notice You can use this contract to deposit ETH into. If a pool operator deposits rewards
/// into the pool while you have funds in the pool, you will be distributed some of the rewards proportional to your share of the total pool. You may withdraw your entire balance at any time.
/// @dev This is an unaudited contract and shouldn't be used in production
contract EthPool is Ownable {

    // State
    address[] internal depositors;
    mapping(address => uint) public balances;
    uint256 public totalBalance;

    // Events
    event DistributeReward(uint amount);
    event Deposit(address indexed from, uint amount);
    event Withdrawal(address indexed to, uint amount);

    constructor() {} // no-op

    function deposit() external payable {
        require(msg.sender != address(0));
        require(msg.value > 0, "Value must be greater than zero");

        bool hasValue = balances[msg.sender] > 0;
        if (!hasValue){
            depositors.push(msg.sender);
        }

        balances[msg.sender] += msg.value;
        totalBalance += msg.value;

        assert(address(this).balance == totalBalance);
        emit Deposit(msg.sender, msg.value);
    }

    function distributeReward() external payable onlyOwner() {
        for (uint i = 0; i < depositors.length; i++) {
            address user = depositors[i];
            balances[user] += balances[user] * msg.value / totalBalance;
        }

        totalBalance += msg.value;
        emit DistributeReward(msg.value);
    }

    function withdraw() public payable {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "User balance is zero");

        balances[msg.sender] = 0;
        totalBalance -= balance;
        // TODO: we may remove msg.sender from depositors here

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "Withdrawal failed");
        emit Withdrawal(msg.sender, balance);
    }
}