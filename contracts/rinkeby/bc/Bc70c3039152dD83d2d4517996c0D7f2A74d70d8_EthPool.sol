//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract EthPool is Ownable {
    // struct of deposit with corresponding reward.
    struct Account {
        uint256 deposits;
        uint256 rewards;
    }

    struct Index {
        uint256 index;
        bool exists;
    }

    uint256 public s_accounstCount = 0;
    uint256 public s_totalEthDeposited;
    uint256 public s_totalRewards;

    // array of all accounts
    Account[] private s_accounts;

    //  mapping of address to `s_accounts` storage index
    mapping(address => Index) private s_indexOf;

    event DepositETH(address account, uint256 amount);
    event DepositReward(uint256 amount, uint256 accounts);
    event Withdraw(address account, uint256 deposit, uint256 reward);
    event Received(address sender, uint256 amount);

    modifier ethSent() {
        require(msg.value > 0, "EthPool: no value sent");
        _;
    }

    /**
     * @notice caller depsosits Eth to earn rewards. Requires `msg.sender` to be  greater than 0
     */
    function depositEth() external payable ethSent {
        Index memory accountIndex = s_indexOf[msg.sender];

        Account memory account;
        if (!accountIndex.exists) {
            account = Account(msg.value, 0);
            s_accounts.push(account);
            s_indexOf[msg.sender] = Index(s_accounstCount, true);
            s_accounstCount++;
        } else {
            account = s_accounts[accountIndex.index];
            uint256 totalDeposits = account.deposits + msg.value;
            account.deposits = totalDeposits;
            s_accounts[accountIndex.index] = account;
        }

        s_totalEthDeposited += msg.value;

        emit DepositETH(msg.sender, msg.value);
    }

    function depositReward() external payable ethSent onlyOwner {
        Account[] memory accounts = s_accounts;

        Account memory account;
        for (uint256 i = 0; i < accounts.length; i++) {
            account = accounts[i];
            uint256 accountReward = _getAccountReward(
                msg.value,
                account.deposits
            );

            account.rewards = account.rewards + accountReward;
            s_accounts[i] = account;
        }

        s_totalRewards += msg.value;
        emit DepositReward(msg.value, accounts.length);
    }

    /**
     * @notice withdraws all deposited ETH and rewards
     */
    function withdraw() external payable {
        require(_hasDeposits(msg.sender), "EthPool: ZERO deposits");

        (Account memory account, int256 accountIndex) = _getAccount(msg.sender);

        uint256 totalDeposits = account.deposits;
        uint256 totalRewards = account.rewards;

        account.deposits = 0;
        account.rewards = 0;

        //uint256 accountIndex = s_indexOf[msg.sender].index;
        s_accounts[uint256(accountIndex)] = account;

        s_totalEthDeposited -= totalDeposits;
        s_totalRewards -= totalRewards;

        uint256 withdrawAmount = totalDeposits + totalRewards;
        (bool sent, ) = payable(msg.sender).call{value: withdrawAmount}("");

        require(sent, "EthPool: Failed to send Ether");
        emit Withdraw(msg.sender, totalDeposits, totalRewards);
    }

    /**
     * @notice check if an account has deposits
     */
    function _hasDeposits(address _account) public view returns (bool) {
        if (!accountExists(_account)) {
            return false;
        }

        uint256 accountIndex = s_indexOf[_account].index;

        if (s_accounts[accountIndex].deposits == 0) return false;
        return true;
    }

    /**
     * @notice check if an account has rewards
     */
    function _hasRewards(address _account) public view returns (bool) {
        if (!accountExists(_account)) {
            return false;
        }

        uint256 accountIndex = s_indexOf[_account].index;

        if (s_accounts[accountIndex].rewards == 0) return false;
        return true;
    }

    function _getAccountReward(uint256 _reward, uint256 _totalDeposits)
        internal
        view
        returns (uint256)
    {
        uint256 poolShare = (_totalDeposits * 1e18) / s_totalEthDeposited;

        return (poolShare * _reward) / 1e18;
    }

    function getAccount(address _account)
        external
        view
        returns (Account memory account)
    {
        if (!accountExists(_account)) {
            return account;
        }

        (account, ) = _getAccount(_account);
    }

    function _getAccount(address _account)
        internal
        view
        returns (Account memory account, int256 index)
    {
        uint256 accountIndex = s_indexOf[_account].index;
        account = s_accounts[accountIndex];
        index = int256(accountIndex);
    }

    function accountExists(address _account) public view returns (bool) {
        Index memory index = s_indexOf[_account];
        if (!index.exists) {
            return false;
        }

        return true;
    }

    function totalAccounts() external view returns (uint256) {
        return s_accounts.length;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
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