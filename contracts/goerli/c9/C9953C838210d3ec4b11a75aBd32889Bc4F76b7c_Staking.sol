/**
 *Submitted for verification at Etherscan.io on 2023-02-11
*/

// SPDX-License-Identifier: MIT

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

contract Staking is Ownable {
    using Counters for Counters.Counter;

    // Authority Node Staking
    IERC20 governanceTokenContract;
    constructor(address governanceTokenAddress) payable {
        governanceTokenContract = IERC20(governanceTokenAddress);
    }

    function deposit() public payable {}

    struct AuthorityStaking {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 stakingAmount;
        uint256 withdrawn;
        uint256 percentageRate; // Divide by 10_000
    }

    mapping(address => bool) public authorities;
    mapping(address => Counters.Counter) public authorityStakingCount;
    mapping(address => mapping (uint256 => AuthorityStaking)) public authorityStakings;

    uint256 public authorityStakingPercentageRate = 12000; // Divide by 10_000
    uint256 public authorityStakingPeriodSeconds = 365 * 24 * 60 * 60;
    uint256 public authorityStakingAllowance = 1000000e18; // 1_000_000 eth
    uint256 public totalAuthorityStaking = 0;

    event authorityStakingCreated(address owner, uint256 stakingAmount, uint256 id);
    event authorityStakingWithdrawn(address owner, uint256 withdrawnAmount, uint256 id);

    event authorityAdded(address authority);
    event authorityRemoved(address authority);

    event authorityStakingPercentageRateUpdated(uint256 authorityStakingPercentageRate);
    event authorityStakingPeriodSecondsUpdated(uint256 authorityStakingPeriodSeconds);
    event authorityStakingAllowanceUpdated(uint256 authorityStakingAllowance);

    modifier onlyAuthorities() {
        require(authorities[msg.sender], "Only authorities are allowed");
        _;
    }

    function updateAuthorityStakingPercentageRate(uint256 newAuthorityStakingPercentageRate) public onlyOwner returns (bool) {
        require(newAuthorityStakingPercentageRate > 0, "Must be more than 0");

        authorityStakingPercentageRate = newAuthorityStakingPercentageRate;
        emit authorityStakingPercentageRateUpdated(newAuthorityStakingPercentageRate);

        return true;
    }

    function updateAuthorityStakingPeriodSeconds(uint256 newAuthorityStakingPeriodSeconds) public onlyOwner returns (bool) {
        require(newAuthorityStakingPeriodSeconds > 0, "Must be more than 0");

        authorityStakingPeriodSeconds = newAuthorityStakingPeriodSeconds;
        emit authorityStakingPeriodSecondsUpdated(newAuthorityStakingPeriodSeconds);

        return true;
    }

    function updatenewAuthorityStakingAllowance(uint256 newAuthorityStakingAllowance) public onlyOwner returns (bool) {
        require(newAuthorityStakingAllowance > 0, "Must be more than 0");

        authorityStakingAllowance = newAuthorityStakingAllowance;
        emit authorityStakingAllowanceUpdated(newAuthorityStakingAllowance);

        return true;
    }

    function addAuthority(address newAuthority) public onlyOwner returns (bool) {
        authorities[newAuthority] = true;
        emit authorityAdded(newAuthority);

        return true;
    }

    function removeAuthority(address authorityToRemove) public onlyOwner returns (bool) {
        authorities[authorityToRemove] = false;
        emit authorityRemoved(authorityToRemove);

        return true;
    }

    function authorityStake() public payable onlyAuthorities returns (bool) {
        uint256 stakingAmount = msg.value;
        require(stakingAmount > 0, "Must stake more than 0");
        require(stakingAmount + totalAuthorityStaking <= authorityStakingAllowance, "Exceed staking allowance");

        totalAuthorityStaking = stakingAmount + totalAuthorityStaking;
        authorityStakingCount[msg.sender].increment();
        uint256 newId = authorityStakingCount[msg.sender].current();

        authorityStakings[msg.sender][newId] = AuthorityStaking({
            id: newId,
            startTime: block.timestamp,
            endTime: block.timestamp + authorityStakingPeriodSeconds,
            stakingAmount: stakingAmount,
            withdrawn: 0,
            percentageRate: authorityStakingPercentageRate
        });

        emit authorityStakingCreated(msg.sender, msg.value, newId);

        return true;
    }

    function authorityWithdrawStaking(
        uint256 authorityStakingId
    ) public returns (bool) {
        require(block.timestamp >= authorityStakings[msg.sender][authorityStakingId].endTime, "Staking is not ready");

        uint256 toWithdraw = 
          authorityStakings[msg.sender][authorityStakingId].stakingAmount * (10000 + authorityStakings[msg.sender][authorityStakingId].percentageRate) / 10000;

        (bool success, ) = msg.sender.call{
            value: toWithdraw
        }("");
        require(success, "Failed to withdraw staking");

        governanceTokenContract.transfer(
            msg.sender,
            authorityStakings[msg.sender][authorityStakingId].stakingAmount * authorityStakings[msg.sender][authorityStakingId].percentageRate / 10000
        );

        authorityStakings[msg.sender][authorityStakingId].withdrawn = toWithdraw;
        authorityStakings[msg.sender][authorityStakingId].stakingAmount = 0;

        emit authorityStakingWithdrawn(
            msg.sender,
            toWithdraw,
            authorityStakingId
        );

        return true;
    }

    // Regional Node Staking
    struct UserStaking {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        uint256 stakingAmount;
        uint256 withdrawn;
    }

    Counters.Counter public regionCount;
    struct Region {
        uint256 id;
        string name;
        uint256 stakingAmount;
        uint256 stakingAllowance; // 1_000_000 eth
        uint256 percentageRate; // Divide by 10_000
        uint256 stakingPeriodSeconds;
    }
    mapping(uint256 => Region) public regions;
    mapping(uint256 => mapping (address => mapping (uint256 => UserStaking))) public regionUserStakings;
    mapping(uint256 => mapping (address => Counters.Counter)) public regionUserStakingCount;

    event regionCreated(uint256 id);
    event stakingCreated(address owner, uint256 regionId, uint256 stakingAmount, uint256 id);
    event stakingWithdrawn(address owner, uint256 regionId, uint256 withdrawnAmount, uint256 id);

    function createRegion(
        string memory name,
        uint256 stakingAllowance,
        uint256 percentageRate,
        uint256 stakingPeriodSeconds
    ) public onlyOwner returns (uint256) {
        regionCount.increment();
        uint256 newId = regionCount.current();

        regions[newId] = Region({
            id: newId,
            name: name,
            stakingAmount: 0,
            stakingAllowance: stakingAllowance,
            percentageRate: percentageRate,
            stakingPeriodSeconds: stakingPeriodSeconds
        });

        emit regionCreated(newId);

        return newId;
    }

    function stake(
        uint256 regionId
    ) public payable returns (bool) {
        uint256 stakingAmount = msg.value;
        require(stakingAmount > 0, "Must stake more than 0");
        require(regions[regionId].stakingAmount + msg.value <= regions[regionId].stakingAllowance, "Exceed staking allowance");

        regions[regionId].stakingAmount += msg.value;
        regionUserStakingCount[regionId][msg.sender].increment();

        uint256 newId = regionUserStakingCount[regionId][msg.sender].current();

        regionUserStakings[regionId][msg.sender][newId] = UserStaking({
            id: newId,
            startTime: block.timestamp,
            endTime: block.timestamp + regions[regionId].stakingPeriodSeconds,
            stakingAmount: stakingAmount,
            withdrawn: 0
        });

        emit stakingCreated(msg.sender, regionId, msg.value, newId);

        return true;
    }

    function withdrawStaking(
        uint256 regionId,
        uint256 regionUserStakingId
    ) public returns (bool) {
        require(block.timestamp >= regionUserStakings[regionId][msg.sender][regionUserStakingId].endTime, "Staking is not ready");

        uint256 toWithdraw = regionUserStakings[regionId][msg.sender][regionUserStakingId].stakingAmount * (10000 + regions[regionId].percentageRate) / 10000;

        (bool success, ) = msg.sender.call{
            value: toWithdraw
        }("");
        require(success, "Failed to withdraw staking");

        governanceTokenContract.transfer(
            msg.sender,
            regionUserStakings[regionId][msg.sender][regionUserStakingId].stakingAmount * regions[regionId].percentageRate / 10000
        );

        regionUserStakings[regionId][msg.sender][regionUserStakingId].withdrawn = toWithdraw;
        regionUserStakings[regionId][msg.sender][regionUserStakingId].stakingAmount = 0;

        emit stakingWithdrawn(
            msg.sender,
            regionId,
            toWithdraw,
            regionUserStakingId
        );

        return true;
    }
}