// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "./dependencies/@openzeppelin/security/ReentrancyGuard.sol";
import "./dependencies/@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import "./access/Governable.sol";
import "./storage/ESVSPStorage.sol";

/**
 * @title Non-transferable escrowed VSP.
 */
contract ESVSP is ReentrancyGuard, Governable, ESVSPStorageV1 {
    using SafeERC20 for IERC20;

    string public constant VERSION = "1.0.0";
    IERC20 public VSP;
    uint256 public constant MINIMUM_LOCK_PERIOD = 7 days;
    uint256 public constant MAXIMUM_LOCK_PERIOD = 2 * 365 days;
    uint256 public constant MAXIMUM_BOOST = 4;

    /// Emitted when a new position is created (i.e. when user locks VSP)
    event VspLocked(uint256 tokenId, address account, uint256 amount, uint256 lockPeriod);

    /// Emitted when a position is burned due to unlock or kick
    event VspUnlocked(uint256 tokenId, uint256 amount, uint256 unlocked, uint256 penalty);

    /// Emitted when the exit penalty is updated
    event ExitPenaltyUpdated(uint256 oldExitPenalty, uint256 newExitPenalty);

    /// Emitted when the treasury address is updated
    event TreasuryUpdated(address oldTreasury, address newTreasury);

    function initialize(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        IESVSP721 esVSP721_,
        address treasury_,
        address vsp_
    ) external initializer {
        require(address(esVSP721_) != address(0), "esVSP721-is-null");
        require(treasury_ != address(0), "treasury-is-null");
        VSP = IERC20(vsp_);
        __Governable_init();
        name = name_;
        symbol = symbol_;
        decimals = decimals_;
        esVSP721 = esVSP721_;
        exitPenalty = 0.5e18; // 50%;
        treasury = treasury_;
    }

    /**
     * @notice Get boosted VSP balance of user. This is different than ESVSP721.balanceOf()
     * It is sum of boosted amount of VSP in each ERC721 (i.e. ESVSP721) token of user
     * @param account_ The account
     * @return user's boost VSP balance. Boost VSP > locked VSP
     */
    function balanceOf(address account_) external view override returns (uint256) {
        return boosted[account_];
    }

    /**
     * @notice Calculate exit penalty for a position
     * @param tokenId_ The position/token id
     */
    function calculateExitPenalty(uint256 tokenId_) external view returns (uint256 _penalty) {
        LockPosition memory _position = positions[tokenId_];
        if (block.timestamp < _position.unlockTime) {
            _penalty = _calculateExitPenalty(_position);
        }
    }

    /**
     * @notice Get the lock period
     * @param tokenId_ The position/token id
     */
    function getLockedPeriodOf(uint256 tokenId_) external view returns (uint256 _lockPeriod) {
        return _getLockedPeriodOf(positions[tokenId_]);
    }

    /**
     * @notice Burn an expired position and send locked amount to the owner
     * @param tokenId_ ERC721 tokenId
     */
    function kick(uint256 tokenId_) external override nonReentrant {
        address _owner = esVSP721.ownerOf(tokenId_);
        _updateReward(_owner);
        _kick(tokenId_, _owner);
    }

    /**
     * @notice Kick all expired positions from a given account
     * @param account_ The target account
     */
    function kickAllExpiredOf(address account_) external override nonReentrant {
        _updateReward(account_);
        _kickAllExpiredOf(account_);
    }

    /**
     * @notice Lock VSP to get boosted revenue and voting power. Lock VSP and generate users position by minting ERC721
     * @param amount_ The VSP amount to lock
     * @param lockPeriod_ The lock period
     */
    function lock(uint256 amount_, uint256 lockPeriod_) external override nonReentrant {
        address _to = _msgSender();
        _updateReward(_to);
        _lock(_to, amount_, lockPeriod_);
    }

    /**
     * @notice Lock VSP to get boosted revenue and voting power. Lock VSP and generate users position by minting ERC721
     * @param amount_ The VSP amount to lock
     * @param lockPeriod_ The lock period
     */
    function lockFor(
        address to_,
        uint256 amount_,
        uint256 lockPeriod_
    ) external override nonReentrant {
        _updateReward(to_);
        _lock(to_, amount_, lockPeriod_);
    }

    /**
     * @notice Get total locked VSP balance of user
     * It is sum of locked VSP in each ERC721 (i.e. ESVSP721) token of user
     * @param account_ The account
     * @return user's locked VSP balance
     */
    function lockedBalanceOf(address account_) external view override returns (uint256) {
        return locked[account_];
    }

    /**
     * @notice Total boosted amount
     */
    function totalSupply() external view override returns (uint256) {
        return totalBoosted;
    }

    /**
     * @notice Transfer position (i.e. locked and boosted amounts) between accounts
     * @dev Revert if caller isn't the esVSP721 contract
     * @param tokenId_ The position (NFT) to transfer
     * @param to_ The recipient
     */
    function transferPosition(uint256 tokenId_, address to_) external override {
        require(_msgSender() == address(esVSP721), "not-esvsp721");
        address _from = esVSP721.ownerOf(tokenId_);

        _updateReward(_from);
        _updateReward(to_);

        LockPosition memory _position = positions[tokenId_];
        uint256 _locked = _position.lockedAmount;
        uint256 _boosted = _position.boostedAmount;

        locked[_from] -= _locked;
        boosted[_from] -= _boosted;
        locked[to_] += _locked;
        boosted[to_] += _boosted;

        emit Transfer(_from, to_, _boosted);
    }

    /**
     * @notice Unlock VSP by burning given ERC721 tokenId_
     * @param tokenId_ ERC721 tokenId
     * @param beforeUnlockTime_ When `true` unlock before expiration and pays exit penalty
     */
    function unlock(uint256 tokenId_, bool beforeUnlockTime_) external override nonReentrant {
        _updateReward(_msgSender());
        _unlock(tokenId_, !beforeUnlockTime_);
    }

    /**
     * @notice Burn given position and transfer locked amount to the owner (charges penalty if applicable)
     * @param tokenId_ The id of the position (NFT)
     * @param onlyIfExpired_ When `true` revert if didn't reach unlockTime
     * @param _account The account to burn position from
     */
    function _burn(
        uint256 tokenId_,
        bool onlyIfExpired_,
        address _account
    ) private {
        LockPosition memory _position = positions[tokenId_];
        uint256 _unlockTime = _position.unlockTime;

        bool _isExpired = block.timestamp > _unlockTime;

        if (onlyIfExpired_) {
            require(_isExpired, "not-unlocked-yet");
        }

        uint256 _locked = _position.lockedAmount;
        uint256 _boosted = _position.boostedAmount;

        esVSP721.burn(tokenId_);
        delete positions[tokenId_];

        locked[_account] -= _locked;
        totalLocked -= _locked;
        boosted[_account] -= _boosted;
        totalBoosted -= _boosted;

        uint256 _toTransfer = _locked;

        if (!_isExpired && exitPenalty > 0) {
            uint256 _penalty = _calculateExitPenalty(_position);
            if (_penalty > 0) {
                VSP.safeTransfer(treasury, _penalty);
                _toTransfer -= _penalty;
            }
        }

        VSP.safeTransfer(_account, _toTransfer);

        emit Transfer(_account, address(0), _boosted);
        emit VspUnlocked(tokenId_, _locked, _toTransfer, _locked - _toTransfer);
    }

    /**
     * @notice Calculate exit penalty for a non-expired position
     * @param _position The position to check (must be non-expired)
     */
    function _calculateExitPenalty(LockPosition memory _position) private view returns (uint256 _penalty) {
        uint256 _progress = ((_position.unlockTime - block.timestamp) * 1e18) / _getLockedPeriodOf(_position);
        return (((_position.lockedAmount * exitPenalty) / 1e18) * _progress) / 1e18;
    }

    /**
     * @notice Get the lock period
     * @param _position The position
     */
    function _getLockedPeriodOf(LockPosition memory _position) private pure returns (uint256 _lockPeriod) {
        return (_position.boostedAmount * MAXIMUM_LOCK_PERIOD) / MAXIMUM_BOOST / _position.lockedAmount;
    }

    /**
     * @notice Kick all expired positions of a user
     * @param account_ The target account
     */
    function _kickAllExpiredOf(address account_) private {
        uint256 _len = esVSP721.balanceOf(account_);
        uint256 i;
        while (i < _len) {
            uint256 _tokenId = esVSP721.tokenOfOwnerByIndex(account_, i);
            if (block.timestamp > positions[_tokenId].unlockTime) {
                _kick(_tokenId, account_);
                _len--;
            } else {
                i++;
            }
        }
    }

    /**
     * @notice Burn an expired position and send locked amount to the owner
     * @param tokenId_ ERC721 tokenId
     */
    function _kick(uint256 tokenId_, address owner_) private {
        _burn(tokenId_, true, owner_);
    }

    /**
     * @notice Lock VSP to get boosted revenue and voting power. Lock VSP and generate users position by minting ERC721
     * @param to_ The beneficiary account
     * @param amount_ The VSP amount to lock
     * @param lockPeriod_ The lock period
     */
    function _lock(
        address to_,
        uint256 amount_,
        uint256 lockPeriod_
    ) internal {
        require(amount_ > 0, "amount-is-zero");
        require(lockPeriod_ > MINIMUM_LOCK_PERIOD, "lock-period-lt-minimum");
        require(lockPeriod_ <= MAXIMUM_LOCK_PERIOD, "lock-period-gt-maximum");

        uint256 balanceBefore_ = VSP.balanceOf(address(this));
        VSP.safeTransferFrom(_msgSender(), address(this), amount_);
        uint256 _lockedAmount = VSP.balanceOf(address(this)) - balanceBefore_;

        uint256 _boostedAmount = (_lockedAmount * lockPeriod_ * MAXIMUM_BOOST) / MAXIMUM_LOCK_PERIOD;

        locked[to_] += _lockedAmount;
        boosted[to_] += _boostedAmount;
        totalLocked += _lockedAmount;
        totalBoosted += _boostedAmount;

        uint256 _tokenId = esVSP721.mint(to_);

        positions[_tokenId] = LockPosition({
            lockedAmount: _lockedAmount,
            boostedAmount: _boostedAmount,
            unlockTime: block.timestamp + lockPeriod_
        });

        emit Transfer(address(0), to_, _boostedAmount);
        emit VspLocked(_tokenId, to_, amount_, lockPeriod_);
    }

    /**
     * @notice Unlock VSP by burning given ERC721 tokenId_
     * @param tokenId_ ERC721 tokenId
     */
    function _unlock(uint256 tokenId_, bool onlyIfExpired_) private {
        address _owner = esVSP721.ownerOf(tokenId_);
        require(_msgSender() == _owner, "not-position-owner");
        _burn(tokenId_, onlyIfExpired_, _owner);
    }

    /**
     * @notice Update related rewards
     * @param account_ The account to update
     */
    function _updateReward(address account_) private {
        if (address(rewards) != address(0)) {
            rewards.updateReward(account_);
        }
    }

    /** Governance methods **/

    /**
     * @notice Initialize the Rewards contract
     * @dev Called once
     * @param rewards_ The new contract
     */
    function initializeRewards(IRewards rewards_) external onlyGovernor {
        require(address(rewards) == address(0), "already-initialized");
        require(address(rewards_) != address(0), "address-is-null");
        rewards = rewards_;
    }

    /**
     * @notice Update exit penalty
     * @param exitPenalty_ The new exit penalty
     */
    function updateExitPenalty(uint256 exitPenalty_) external onlyGovernor {
        require(exitPenalty_ <= 1e18, "exit-fee-gt-100%");
        require(exitPenalty_ != exitPenalty, "fee-is-same-as-current");
        emit ExitPenaltyUpdated(exitPenalty, exitPenalty_);
        exitPenalty = exitPenalty_;
    }

    /**
     * @notice Update treasury contract
     * @param treasury_ The new treasury address
     */
    function updateTreasury(address treasury_) external onlyGovernor {
        require(treasury_ != address(0), "address-null");
        require(treasury_ != treasury, "address-is-same-as-current");
        emit TreasuryUpdated(treasury, treasury_);
        treasury = treasury_;
    }

    /** Methods not supported **/

    function allowance(
        address, /*owner*/
        address /*spender*/
    ) public view virtual override returns (uint256) {
        revert("allowance-not-supported");
    }

    function approve(
        address, /*spender*/
        uint256 /*amount*/
    ) public virtual override returns (bool) {
        revert("approval-not-supported");
    }

    function decreaseAllowance(
        address, /*spender*/
        uint256 /*subtractedValue*/
    ) public virtual returns (bool) {
        revert("allowance-not-supported");
    }

    function increaseAllowance(
        address, /*spender*/
        uint256 /*addedValue*/
    ) public virtual returns (bool) {
        revert("allowance-not-supported");
    }

    function transfer(
        address, /*recipient*/
        uint256 /*amount*/
    ) public virtual override returns (bool) {
        revert("transfer-not-supported");
    }

    function transferFrom(
        address, /*sender*/
        address, /*recipient*/
        uint256 /*amount*/
    ) public virtual override returns (bool) {
        revert("transfer-not-supported");
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/@openzeppelin/utils/Context.sol";
import "../dependencies/@openzeppelin/proxy/utils/Initializable.sol";
import "../interface/IGovernable.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (governor) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the governor account will be the one that deploys the contract. This
 * can later be changed with {transferGovernorship}.
 *
 */
abstract contract Governable is IGovernable, Initializable, Context {
    address public governor;
    address public proposedGovernor;

    event UpdatedGovernor(address indexed previousGovernor, address indexed proposedGovernor);

    /**
     * @dev If inheriting child is using proxy then child contract can use
     * __Governable_init() function to initialization this contract
     */
    // solhint-disable-next-line func-name-mixedcase
    function __Governable_init() internal onlyInitializing {
        governor = _msgSender();
        emit UpdatedGovernor(address(0), governor);
    }

    /**
     * @dev Throws if called by any account other than the governor.
     */
    modifier onlyGovernor() {
        require(governor == _msgSender(), "not-governor");
        _;
    }

    /**
     * @dev Transfers governorship of the contract to a new account (`proposedGovernor`).
     * Can only be called by the current owner.
     */
    function transferGovernorship(address _proposedGovernor) external onlyGovernor {
        require(_proposedGovernor != address(0), "proposed-governor-is-zero");
        proposedGovernor = _proposedGovernor;
    }

    /**
     * @dev Allows new governor to accept governorship of the contract.
     */
    function acceptGovernorship() external {
        require(proposedGovernor == _msgSender(), "not-the-proposed-governor");
        emit UpdatedGovernor(governor, proposedGovernor);
        governor = proposedGovernor;
        proposedGovernor = address(0);
    }
}

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !Address.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

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

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
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

// SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/@openzeppelin/token/ERC20/extensions/IERC20Metadata.sol";
import "./IRewards.sol";

interface IESVSP is IERC20Metadata {
    function totalLocked() external view returns (uint256);

    function totalBoosted() external view returns (uint256);

    function locked(address _account) external view returns (uint256);

    function boosted(address _account) external view returns (uint256);

    function lock(uint256 amount_, uint256 lockPeriod_) external;

    function lockFor(
        address to_,
        uint256 amount_,
        uint256 lockPeriod_
    ) external;

    function updateExitPenalty(uint256 exitPenalty_) external;

    function unlock(uint256 tokenId_, bool unexpired_) external;

    function kick(uint256 tokenId_) external;

    function kickAllExpiredOf(address account_) external;

    function lockedBalanceOf(address account_) external view returns (uint256);

    function transferPosition(uint256 tokenId_, address to_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../dependencies/@openzeppelin/token/ERC721/extensions/IERC721Enumerable.sol";

interface IESVSP721 is IERC721Enumerable {
    function mint(address to_) external returns (uint256);

    function burn(uint256 tokenId_) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

/**
 * @notice Governable interface
 */
interface IGovernable {
    function governor() external view returns (address _governor);

    function transferGovernorship(address _proposedGovernor) external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

interface IRewards {
    function addRewardToken(
        address rewardsToken_,
        address distributor_,
        bool isBoosted_
    ) external;

    function claimRewards(address account_) external;

    function claimableRewards(address account_)
        external
        view
        returns (address[] memory rewardTokens_, uint256[] memory claimableAmounts_);

    function dripRewardAmount(address rewardToken_, uint256 rewardAmount_) external;

    function setRewardDistributorApproval(
        address rewardsToken_,
        address distributor_,
        bool approved_
    ) external;

    function updateReward(address account_) external;

    function lastTimeRewardApplicable(address _rewardToken) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.9;

import "../interface/IESVSP.sol";
import "../interface/IESVSP721.sol";

abstract contract ESVSPStorageV1 is IESVSP {
    struct LockPosition {
        uint256 lockedAmount; // VSP locked
        uint256 boostedAmount; // based on the `lockPeriod`
        uint256 unlockTime; // now + `lockPeriod`
    }

    uint8 public decimals;
    string public name;
    string public symbol;

    /**
     * @notice The treasury contract (will receive exit penalty collected)
     */
    address public treasury;

    /**
     * @notice NFT contract
     */
    IESVSP721 public esVSP721;

    /**
     * @notice Rewards contract
     */
    IRewards public rewards;

    /**
     * @notice Total VSP locked
     */
    uint256 public override totalLocked;

    /**
     * @notice Total boosted amount
     */
    uint256 public override totalBoosted;

    /**
     * @notice Fee paid when withdrawing. Decreases linearly as period finish approaches.
     * @dev Use 18 decimals (e.g. 0.5e18 is 50%)
     */
    uint256 public exitPenalty;

    /**
     * @notice Lock positions
     * @dev tokenId => position
     */
    mapping(uint256 => LockPosition) public positions;

    /**
     * @notice Total VSP locked by user among all his positions
     * @dev user => total locked;
     */
    mapping(address => uint256) public override locked;

    /**
     * @notice Total boosted amount by user among all his positions
     * @dev user => total boosted;
     */
    mapping(address => uint256) public override boosted;
}