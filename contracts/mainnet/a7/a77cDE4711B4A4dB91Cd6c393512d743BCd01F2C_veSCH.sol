// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault is IVault, Ownable {
    struct Share {
        uint256 amount;
        uint256 uncounted;
        uint256 counted;
    }

    mapping (address => uint256) voterClaims;

    mapping (address => uint256) public totalRewardsToVoter;

    mapping (address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDistributed;
    uint256 public rewardsPerShare;
    uint256 public constant decimals = 10 ** 36;

    address public vesch;
    IERC20 public immutable SCH;

    constructor (address _SCH) {
        vesch = msg.sender;
        SCH = IERC20(_SCH);
    }

    function _getCumulativeFees(uint256 _share) private view returns (uint256) {
        return _share * rewardsPerShare / decimals;
    }

    function setBalance(address _voter, uint256 _amount) external override {
        require(msg.sender == vesch);
        totalShares = totalShares - shares[_voter].amount + _amount;
        shares[_voter].amount = _amount;
        shares[_voter].uncounted = _getCumulativeFees(shares[_voter].amount);
    }

    function claimFees(address _voter) external override returns (uint256) {
        require(msg.sender == vesch);
        if (shares[_voter].amount == 0) return 0;
        uint256 _amount = getUnclaimedFees(_voter);
        if (_amount > 0) {
            voterClaims[_voter] = block.timestamp;
            shares[_voter].counted = shares[_voter].counted + _amount;
            shares[_voter].uncounted = _getCumulativeFees(shares[_voter].amount);
            (bool _success, ) = payable(vesch).call{value: _amount}("");
            require(_success);
            totalDistributed = totalDistributed + _amount;
            totalRewardsToVoter[_voter] = totalRewardsToVoter[_voter] + _amount;
            return _amount;
        } else {
            return 0;
        }
    }

    function deposit(uint256 _amount) external override {
        require(msg.sender == vesch);
        if (totalShares > 0) {
            rewardsPerShare = rewardsPerShare + (decimals * _amount / totalShares);
        }
    }

    function getUnclaimedFees(address _voter) public view returns (uint256) {
        if (shares[_voter].amount == 0) return 0;
        uint256 _voterRewards = _getCumulativeFees(shares[_voter].amount);
        uint256 _voterUncounted = shares[_voter].uncounted;
        if (_voterRewards <= _voterUncounted) return 0;
        return _voterRewards - _voterUncounted;
    }

    function getClaimedRewardsTotal() external view returns (uint256) {
        return totalDistributed;
    }

    function getClaimedRewards(address _voter) external view returns (uint256) {
        return totalRewardsToVoter[_voter];
    }

    function getLastClaim(address _voter) external view returns (uint256) {
        return voterClaims[_voter];
    }

    function balanceOf(address _voter) external view returns (uint256) {
        return shares[_voter].amount;
    }

    receive() external payable {}
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

interface IVault {
    function setBalance(address _voter, uint256 _amount) external;
    function deposit(uint256 _amount) external;
    function claimFees(address _voter) external returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;

interface IveSCH {
    function depositFees(uint256 _amount, uint256 _period) external payable;
    function getVotingPower(address _voter) external view returns (uint256);
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.8.13;
pragma abicoder v2;

import "./interfaces/IveSCH.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./Vault.sol";
import "./interfaces/IVault.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract veSCH is IveSCH, Ownable, ReentrancyGuard {
    uint256 private id;

    uint256[5] private periods = [86400, 15778800, 31557600, 63115200, 126230400];
    uint256[5] private weights = [1, 5, 10, 20, 40];

    mapping (uint256 => address) private vaults;

    uint256 private constant lockerLimit = 99;

    uint256 private votingPower;

    address public bribes;

    struct Locker {
        uint256 id;
        address minter;
        address locker;
        uint256 created;
        uint256 unlocks;
        uint256 amount;
        bool locked;
        uint256 period;
    }

    mapping (uint256 => Locker) private lockers;
    mapping (address => Locker[]) private lockersByVoter;
    mapping (address => uint256) private lockersByVoterTotal;
    mapping (uint256 => uint256) private lockersByVoterIds;

    IERC20 private SCH;

    bool private initialized;

    constructor() {}

    function initialize(address _SCH, address _bribes) external onlyOwner {
        require(!initialized);
        initialized = true;
        SCH = IERC20(_SCH);
        for (uint256 _i = 0; _i < 5; _i++) {
            Vault _vault = new Vault(_SCH);
            vaults[_i] = address(_vault);
            SCH.approve(address(_vault), type(uint256).max);
        }
        bribes = _bribes;
    }

    function createLocker(uint256 _amount, uint256 _period) external nonReentrant returns (uint256) {
        require(initialized && _amount > 0 && (_period >= 0 && _period < 5) && lockersByVoterTotal[msg.sender] < lockerLimit);

        SCH.transferFrom(msg.sender, address(this), _amount);

        uint256 _id = id;
        id++;

        uint256 _balance = getBalances(msg.sender)[_period];

        uint256 _seconds = periods[_period];

        IVault(vaults[_period]).setBalance(msg.sender, _balance + 1);
        votingPower += _amount * weights[_period];

        Locker memory _locker = Locker(_id, msg.sender, address(0), block.timestamp, block.timestamp + _seconds, _amount, true, _period);
        lockers[_id] = _locker;
        lockersByVoter[msg.sender].push(_locker);
        lockersByVoterIds[_id] = lockersByVoterTotal[msg.sender];
        lockersByVoterTotal[msg.sender] = lockersByVoterTotal[msg.sender] + 1;

        return _id;
    }

    function claimFees(uint256 _id) external nonReentrant {
        Locker memory _locker = lockers[_id];
        require(_locker.minter == msg.sender);
        require(_locker.unlocks > block.timestamp);
        require(_locker.locked);

        _refresh(msg.sender, _locker.period, false);

        Locker memory _lockerNew = Locker(_id, _locker.minter, _locker.locker, _locker.created, _locker.unlocks, _locker.amount, _locker.locked, _locker.period);
        lockers[_id] = _lockerNew;
        lockersByVoter[msg.sender][lockersByVoterIds[_id]] = _lockerNew;
    }

    function _refresh(address _voter, uint256 _period, bool _slash) private {
        uint256[5] memory _balances = getBalances(_voter);
        uint256 _amount = IVault(vaults[_period]).claimFees(_voter);
        if (_amount > 0) {
            if (_slash) {
                uint256 _reward = _amount * 300 / 10000;
                (bool _success, ) = payable(msg.sender).call{value: _reward}("");
                require(_success);
                (_success, ) = payable(_voter).call{value: _amount - _reward}("");
                require(_success);
            } else {
                (bool _success, ) = payable(_voter).call{value: _amount}("");
                require(_success);
            }
        }
        IVault(vaults[_period]).setBalance(_voter, _balances[_period]);
    }

    function _unlockSCH(uint256 _id, bool _slash) private {
        Locker memory _locker = lockers[_id];
        require(_locker.unlocks <= block.timestamp && _locker.locked);
        _refresh(_locker.minter, _locker.period, _slash);
        uint256 _amount = _locker.amount;
        SCH.transfer(_locker.minter, _amount);
        Locker memory _lockerNew = Locker(_id, _locker.minter, msg.sender, _locker.created, _locker.unlocks, _amount, false, _locker.period);
        lockers[_id] = _lockerNew;
        lockersByVoter[_locker.minter][lockersByVoterIds[_id]] = _lockerNew;
        votingPower -= _amount * weights[_locker.period];
    }

    function unlockSCH(uint256 _id) external nonReentrant {
        require(lockers[_id].minter == msg.sender);
        _unlockSCH(_id, false);
    }

    function slashLocker(uint256 _id) external nonReentrant {
        Locker memory _locker = lockers[_id];
        require(_locker.unlocks <= block.timestamp && _locker.locked);
        _unlockSCH(_id, true);
    }

    function depositFees(uint256 _amount, uint256 _period) external payable nonReentrant {
        require(bribes == msg.sender);
        require(_period >= 0 && _period < 5);
        require(msg.value == _amount);
        (bool _success, ) = payable(vaults[_period]).call{value: _amount}("");
        if (_success) {
            IVault(vaults[_period]).deposit(_amount);
        }
    }

    function getVotingPowerTotal() external view returns (uint256) {
        return votingPower;
    }

    function getVotingPower(address _voter) external view returns (uint256) {
        uint256 _votingPower;
        uint256 _matches = lockersByVoterTotal[_voter];
        Locker[] memory _array = lockersByVoter[_voter];
        for (uint256 _i = 0; _i < _matches; _i++) {
            if (_array[_i].locked && _array[_i].unlocks > block.timestamp) _votingPower += _array[_i].amount * weights[_array[_i].period];
        }
        return _votingPower;
    }

    function getLocker(uint256 _id) external view returns (Locker memory) {
        return lockers[_id];
    }

    function getLockersByVoter(address _voter) external view returns (Locker[] memory) {
        return lockersByVoter[_voter];
    }

    function getLockersByVoterTotal(address _voter) external view returns (uint256) {
        return lockersByVoterTotal[_voter];
    }

    function getVaultContract(uint256 _period) external view returns (address) {
        return (vaults[periods[_period]]);
    }

    function getAllVaultContracts() external view returns (address, address, address, address, address) {
        return (vaults[periods[0]], vaults[periods[1]], vaults[periods[2]], vaults[periods[3]], vaults[periods[4]]);
    }

    function getBalances(address _voter) public view returns (uint[5] memory) {
        uint256[5] memory _balances;
        uint256 _matches = lockersByVoterTotal[_voter];
        Locker[] memory _array = lockersByVoter[_voter];
        for (uint256 _i = 0; _i < _matches; _i++) {
            if (_array[_i].locked && _array[_i].unlocks > block.timestamp) _balances[_array[_i].period] = _balances[_array[_i].period] + 1;
        }
        return _balances;
    }

    receive() external payable {}
}