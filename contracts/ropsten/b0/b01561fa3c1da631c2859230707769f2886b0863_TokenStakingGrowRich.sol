/**
 *Submitted for verification at Etherscan.io on 2022-08-18
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.16;

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

contract TokenStakingGrowRich is Context, Ownable, ReentrancyGuard {
    IERC20 public addressGrowRich;
    IERC20 public immutable addressUSDC;

    uint256 public stakingWindowStart;
    uint256 public stakingWindowEnd;
    uint256 public stakingDurationEnd;
    uint256 public distributionPercentage;

    uint256 private _distributionPercentage;
    bool private _firstClaim;
    uint256 private _currentRoundRewards;
    mapping(address => uint256) private _balances;
    uint256 private _totalBalanceGrowRich;

    event StakingRoundUpdated(uint256, uint256, uint256, uint256);
    event StakedGrowRich(address, uint256);
    event UnstakedGrowRich(address, uint256);
    event ClaimedUSDC(address, uint256);

    modifier onlyInStakingWindow() {
        require(
            block.timestamp > stakingWindowStart &&
                block.timestamp < stakingWindowEnd,
            "TokenStakingGrowRich: staking window is closed"
        );
        _;
    }

    modifier onlyAfterStakingDurationEnd() {
        require(
            block.timestamp > stakingDurationEnd,
            "TokenStakingGrowRich: staking duration not ended yet"
        );
        _;
    }

    modifier onlyBeforeStakingDurationEnd() {
        require(
            block.timestamp < stakingDurationEnd,
            "TokenStakingGrowRich: claim rewards first, staking duration is ended"
        );
        _;
    }

    constructor() {
        addressUSDC = IERC20(0xaD6D458402F60fD3Bd25163575031ACDce07538D);

        _totalBalanceGrowRich = 0;
        distributionPercentage = 100;
        _distributionPercentage = distributionPercentage * 10**16;
        stakingWindowStart = stakingWindowEnd = stakingDurationEnd = 1;

        _firstClaim = false;
        _currentRoundRewards = 0;
    }

    function setStakingRound(
        uint256 stakingWindowStart_,
        uint256 stakingWindowEnd_,
        uint256 stakingDurationEnd_,
        uint256 distributionPercentage_
    ) external onlyOwner onlyAfterStakingDurationEnd {
        stakingWindowStart = stakingWindowStart_;
        stakingWindowEnd = stakingWindowEnd_;
        stakingDurationEnd = stakingDurationEnd_;
        distributionPercentage = distributionPercentage_;
        _distributionPercentage = distributionPercentage * 10**16;

        _firstClaim = false;
        _currentRoundRewards = 0;

        emit StakingRoundUpdated(
            stakingWindowStart,
            stakingWindowEnd,
            stakingDurationEnd,
            distributionPercentage
        );
    }

    function stakeTokens(uint256 amount) external onlyInStakingWindow {
        address from = _msgSender();
        _stakeTokens(from, amount);

        emit StakedGrowRich(from, amount);
    }

    function unstakeTokens()
        external
        nonReentrant
        onlyBeforeStakingDurationEnd
    {
        address to = _msgSender();
        uint256 amount = _balances[to];
        require(
            amount > 0,
            "TokenStakingGrowRich: no staked amount exists for respective beneficiary"
        );

        _unstakeTokens(to, amount);

        emit UnstakedGrowRich(to, amount);
    }

    function _stakeTokens(address from, uint256 amount) private {
        address to = address(this);
        _balances[from] += amount;
        _totalBalanceGrowRich += amount;

        addressGrowRich.transferFrom(from, to, amount);
    }

    function _unstakeTokens(address to, uint256 amount) private {
        _balances[to] -= amount;
        _totalBalanceGrowRich -= amount;

        addressGrowRich.transfer(to, amount);
    }

    function claimRewards() external onlyAfterStakingDurationEnd nonReentrant {
        address beneficiary = _msgSender();
        uint256 claimableRewards = _claimRewards(beneficiary);
        emit ClaimedUSDC(beneficiary, claimableRewards);
    }

    function _claimRewards(address beneficiary) private returns (uint256) {
        if (!_firstClaim && (block.timestamp > stakingDurationEnd)) {
            _firstClaim = true;
            uint256 totalRewards = totalBalanceUSDC();
            _currentRoundRewards =
                (totalRewards * _distributionPercentage) /
                10**18;
        }

        uint256 claimableRewards = _calculateClaimableRewards(beneficiary);
        uint256 stakedAmount = _balances[beneficiary];
        _unstakeTokens(beneficiary, stakedAmount);
        _currentRoundRewards -= claimableRewards;

        addressUSDC.transfer(beneficiary, claimableRewards);

        return claimableRewards;
    }

    function _calculateClaimableRewards(address beneficiary)
        private
        view
        returns (uint256)
    {
        uint256 stakedAmount = _balances[beneficiary];
        require(
            stakedAmount > 0,
            "TokenStakingGrowRich: no staked amount exists for respective beneficiary"
        );

        uint256 currentRoundRewards = curentRoundRewards();
        uint256 holdingPercentage = (stakedAmount * 10**18) /
            _totalBalanceGrowRich;
        uint256 claimableRewards = (currentRoundRewards * holdingPercentage) /
            10**18;

        return claimableRewards;
    }

    function curentRoundRewards() public view returns (uint256) {
        uint256 currentRoundRewards;

        if (!_firstClaim) {
            uint256 totalRewards = totalBalanceUSDC();
            currentRoundRewards =
                (totalRewards * _distributionPercentage) /
                10**18;
        } else {
            currentRoundRewards = _currentRoundRewards;
        }

        return currentRoundRewards;
    }

    function viewRewardsUSDC(address beneficiary)
        public
        view
        returns (uint256)
    {
        return _calculateClaimableRewards(beneficiary);
    }

    function totalBalanceGrowRich() public view returns (uint256) {
        return _totalBalanceGrowRich;
    }

    function totalBalanceUSDC() public view returns (uint256) {
        return addressUSDC.balanceOf(address(this));
    }

    function changeGrowRichAddress(address newAddressGrowRich)
        external
        onlyOwner
        returns (bool)
    {
        addressGrowRich = IERC20(newAddressGrowRich);
        return true;
    }

    function getCurrentTime() public view virtual returns (uint256) {
        return block.timestamp;
    }
}