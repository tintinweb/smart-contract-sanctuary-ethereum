/**
 *Submitted for verification at Etherscan.io on 2022-11-08
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// File: contracts/BoredMStake.sol


pragma solidity ^0.8.7;



contract TokenStoreNode {
    address public manager;
    constructor() {
       manager = msg.sender;
    }

    function withdrawToken(address _tokenAddress, address _toAddress, uint256 _tokenAmount) external {
        require(msg.sender == manager);
        IERC20(_tokenAddress).transfer(_toAddress, _tokenAmount);
    }
}


contract BoredMemes_Stake is Ownable {
    IERC20 public TOKEN;
    
    struct Share {
        uint256 amountFree;
        uint256 excludedFree;
        uint256 rewardConfirmedFree;
        uint256 rewardClaimedFree;
        uint256 stakeTimestampFree;

        uint256 amountLock;
        uint256 excludedLock;
        uint256 rewardConfirmedLock;
        uint256 rewardClaimedLock;
        uint256 stakeTimestampLock;
    }

    mapping(address => Share) public shares;

    uint256 public totalSharesFree;
    uint256 public totalDividendsFree;
    uint256 public totalDistributedFree;
    uint256 public dividendsPerShareFree;
    uint256 public dividendsPercentFree;
    address public unstakeFeeAddress;
    uint256 public unstakeFeePeriodFree;
    uint256 public unstakeFeePercentFree;
    
    uint256 public totalSharesLock;
    uint256 public totalDividendsLock;
    uint256 public totalDistributedLock;
    uint256 public dividendsPerShareLock;
    uint256 public dividendsPercentLock;
    uint256 public lockPeriod;

    uint256 public dividendsPerShareAccuracyFactor;
    
    uint256 public maxWalletTokenAmount;

    TokenStoreNode[] public storeNodeList;

    constructor(address tokenAddress) {
        TOKEN = IERC20(tokenAddress);
        dividendsPerShareAccuracyFactor = 10**36;
        maxWalletTokenAmount = 10000000000000000000000;
        lockPeriod = 30 days;
        dividendsPercentFree = 10;
        dividendsPercentLock = 90;
        unstakeFeeAddress = 0x2B72898f88c83881b09EA7D828484CE8A3b637F2;
        unstakeFeePeriodFree = 72 hours;
        unstakeFeePercentFree = 1;
    }

    function depositToken(address _from, uint256 _amount) internal returns (uint256) {
        require(_amount <= maxWalletTokenAmount, "Overflow Max Wallet Limit");
        
        for (uint256 i = 0; i < storeNodeList.length; i++) {
            uint256 currentNodeBalance = TOKEN.balanceOf(address(storeNodeList[i]));
            if (maxWalletTokenAmount - currentNodeBalance >= _amount) {
                TOKEN.transferFrom(_from, address(storeNodeList[i]), _amount);
                return TOKEN.balanceOf(address(storeNodeList[i])) - currentNodeBalance;
            }
        }

        TokenStoreNode newNode = new TokenStoreNode();
        storeNodeList.push(newNode);
        TOKEN.transferFrom(_from, address(newNode), _amount);
        return TOKEN.balanceOf(address(newNode));
    }

    function withdrawToken(address _to, uint256 _amount) internal {        
        require(_amount <= maxWalletTokenAmount, "Overflow Max Wallet Limit");

        uint256 withdrawAmount = _amount;
        for (uint256 i = 0; i < storeNodeList.length; i++) {
            uint256 currentNodeBalance = TOKEN.balanceOf(address(storeNodeList[i]));
            if (currentNodeBalance >= withdrawAmount) {
                storeNodeList[i].withdrawToken(address(TOKEN), _to, withdrawAmount);
                return;
            } else {
                storeNodeList[i].withdrawToken(address(TOKEN), _to, currentNodeBalance);
                withdrawAmount -= currentNodeBalance;
            }
        }
    }

    function setToken(address _token) external onlyOwner {
        TOKEN = IERC20(_token);
    }

    function setUnstakeFeeFree(address _feeAddress, uint256 _period, uint256 _percent) external onlyOwner {
        unstakeFeeAddress = _feeAddress;
        unstakeFeePeriodFree = _period;
        unstakeFeePercentFree = _percent;
    }

    function setMaxWalletTokenAmount(uint256 _maxWalletAmount) external onlyOwner {
        maxWalletTokenAmount = _maxWalletAmount;
    }

    function setLockPeriod(uint256 _lockPeriod) external onlyOwner {
        lockPeriod = _lockPeriod;
    }
    
    function setDividendsPercent(uint256 _percentFree, uint256 _percentLock) external onlyOwner {
        require(_percentFree + _percentLock == 100, "Sum of Percent not 100%");
        dividendsPercentFree = _percentFree;
        dividendsPercentLock = _percentLock;
    }

    function stakeFree(uint256 tokenAmount) external {
        require(tokenAmount > 0, "Stake amount can't be zero");
        
        if (shares[msg.sender].amountFree > 0) {
            distributeDividendFree(msg.sender);
        }

        uint256 realDepositAmount = depositToken(msg.sender, tokenAmount);
        totalSharesFree += realDepositAmount;
        shares[msg.sender].amountFree += realDepositAmount;
        shares[msg.sender].excludedFree = getCumulativeDividendsFree(shares[msg.sender].amountFree);
        shares[msg.sender].stakeTimestampFree = block.timestamp;
    }

    function stakeLock(uint256 tokenAmount) external {
        require(tokenAmount > 0, "Stake amount can't be zero");

        if (shares[msg.sender].amountLock > 0) {
            distributeDividendLock(msg.sender);
        }

        uint256 realDepositAmount = depositToken(msg.sender, tokenAmount);
        totalSharesLock += realDepositAmount;
        shares[msg.sender].amountLock += realDepositAmount;
        shares[msg.sender].excludedLock = getCumulativeDividendsLock(shares[msg.sender].amountLock);
        shares[msg.sender].stakeTimestampLock = block.timestamp;
    }

    function unstakeFree(uint256 tokenAmount) external {
        if (shares[msg.sender].amountFree > 0) {
            distributeDividendFree(msg.sender);
        }

        if (shares[msg.sender].amountFree <= tokenAmount) {
            if (block.timestamp - shares[msg.sender].stakeTimestampFree >= unstakeFeePeriodFree) {
                withdrawToken(msg.sender, shares[msg.sender].amountFree);
            } else {
                withdrawToken(unstakeFeeAddress, shares[msg.sender].amountFree * unstakeFeePercentFree / 100);
                withdrawToken(msg.sender, shares[msg.sender].amountFree * (100 - unstakeFeePercentFree) / 100);
            }
            totalSharesFree -= shares[msg.sender].amountFree;
            shares[msg.sender].amountFree = 0;
        } else {
            withdrawToken(msg.sender, tokenAmount);
            totalSharesFree -= tokenAmount;
            shares[msg.sender].amountFree -= tokenAmount;
        }

        shares[msg.sender].excludedFree = getCumulativeDividendsFree(shares[msg.sender].amountFree);
    }

    function unstakeLock(uint256 tokenAmount) external {
        require(block.timestamp - shares[msg.sender].stakeTimestampLock >= lockPeriod, "Staked tokens still locked");

        if (shares[msg.sender].amountLock > 0) {
            distributeDividendLock(msg.sender);
        }

        if (shares[msg.sender].amountLock <= tokenAmount) {
            withdrawToken(msg.sender, shares[msg.sender].amountLock);
            totalSharesLock -= shares[msg.sender].amountLock;
            shares[msg.sender].amountLock = 0;
        } else {
            withdrawToken(msg.sender, tokenAmount);
            totalSharesLock -= tokenAmount;
            shares[msg.sender].amountLock -= tokenAmount;
        }

        shares[msg.sender].excludedLock = getCumulativeDividendsLock(shares[msg.sender].amountLock);
    }

    function getCumulativeDividendsFree(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShareFree / dividendsPerShareAccuracyFactor;
    }

    function getCumulativeDividendsLock(uint256 share) internal view returns (uint256) {
        return share * dividendsPerShareLock / dividendsPerShareAccuracyFactor;
    }

    function distributeDividendFree(address shareholder) internal {
        if (shares[shareholder].amountFree == 0) return;

        uint256 amountFree = getUnpaidEarningsFree(shareholder);
        if (amountFree > 0) {
            totalDistributedFree += amountFree;
            shares[shareholder].rewardConfirmedFree += amountFree;
            shares[shareholder].excludedFree = getCumulativeDividendsFree(shares[shareholder].amountFree);
        }
    }

    function distributeDividendLock(address shareholder) internal {
        if (shares[shareholder].amountLock == 0) return;

        uint256 amountLock = getUnpaidEarningsLock(shareholder);
        if (amountLock > 0) {
            totalDistributedLock += amountLock;
            shares[shareholder].rewardConfirmedLock += amountLock;
            shares[shareholder].excludedLock = getCumulativeDividendsLock(shares[shareholder].amountLock);
        }
    }

    function getUnpaidEarningsFree(address shareholder) internal view returns (uint256) {
        if (shares[shareholder].amountFree == 0) return 0;

        uint256 shareholderTotalDividendsFree = getCumulativeDividendsFree(shares[shareholder].amountFree);

        uint256 shareholderTotalExcludedFree = shares[shareholder].excludedFree;

        if (shareholderTotalDividendsFree <= shareholderTotalExcludedFree) return 0;

        return shareholderTotalDividendsFree - shareholderTotalExcludedFree;
    }

    function getUnpaidEarningsLock(address shareholder) internal view returns (uint256) {
        if (shares[shareholder].amountLock == 0) return 0;

        uint256 shareholderTotalDividendsLock = getCumulativeDividendsLock(shares[shareholder].amountLock);

        uint256 shareholderTotalExcludedLock = shares[shareholder].excludedLock;

        if (shareholderTotalDividendsLock <= shareholderTotalExcludedLock) return 0;

        return shareholderTotalDividendsLock - shareholderTotalExcludedLock;
    }

    function getUnclaimedRewardsFree(address shareholder) public view returns (uint256) {
        return shares[shareholder].rewardConfirmedFree + getUnpaidEarningsFree(shareholder);
    }

    function getUnclaimedRewardsLock(address shareholder) public view returns (uint256) {
        return shares[shareholder].rewardConfirmedLock + getUnpaidEarningsLock(shareholder);
    }

    function getClaimedRewardsFree(address shareholder) public view returns (uint256) {
        return shares[shareholder].rewardClaimedFree;
    }

    function getClaimedRewardsLock(address shareholder) public view returns (uint256) {
        return shares[shareholder].rewardClaimedLock;
    }

    receive() external payable {
        totalDividendsFree += msg.value * dividendsPercentFree / 100;
        totalDividendsLock += msg.value * dividendsPercentLock / 100;

        dividendsPerShareFree += dividendsPerShareAccuracyFactor * (msg.value * dividendsPercentFree / 100) / totalSharesFree;
        dividendsPerShareLock += dividendsPerShareAccuracyFactor * (msg.value * dividendsPercentLock / 100) / totalSharesLock;
    }

    function claimRewardsFree() external {
        distributeDividendFree(msg.sender);
        require(shares[msg.sender].rewardConfirmedFree > 0, "Nothing Rewards");

        payable(msg.sender).transfer(shares[msg.sender].rewardConfirmedFree);
        shares[msg.sender].rewardClaimedFree += shares[msg.sender].rewardConfirmedFree;
        shares[msg.sender].rewardConfirmedFree = 0;
    }

    function claimRewardsLock() external {
        distributeDividendLock(msg.sender);
        require(shares[msg.sender].rewardConfirmedLock > 0, "Nothing Rewards");

        payable(msg.sender).transfer(shares[msg.sender].rewardConfirmedLock);
        shares[msg.sender].rewardClaimedLock += shares[msg.sender].rewardConfirmedLock;
        shares[msg.sender].rewardConfirmedLock = 0;
    }
}