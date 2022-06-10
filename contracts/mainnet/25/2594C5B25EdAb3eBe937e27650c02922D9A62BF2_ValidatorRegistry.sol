// SPDX-License-Identifier: GPL-3.0
pragma solidity =0.8.14;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./interfaces/IValidatorRegistry.sol";
import "./interfaces/IJMS.sol";
import "./interfaces/IStakeManager.sol";

/// @title ValidatorRegistry
/// @notice ValidatorRegistry is the main contract that manage validators
/// @dev ValidatorRegistry is the main contract that manage validators.
contract ValidatorRegistry is
    IValidatorRegistry,
    Pausable,
    Ownable,
    ReentrancyGuard
{
    address private stakeManager;

    uint256 public override preferredDepositValidatorId;
    uint256 public override preferredWithdrawalValidatorId;
    mapping(uint256 => bool) public override validatorIdExists;

    uint256[] private validators;

    constructor(address _stakeManager) {
        stakeManager = _stakeManager;
    }

    /// ----------------------------- API --------------------------------------

    /// @notice Allows a validator that was already staked on the polygon stake manager
    /// to join the JMS protocol.
    /// @param _validatorId id of the validator.
    function addValidator(uint256 _validatorId)
        external
        override
        whenNotPaused
        whenValidatorIdDoesNotExist(_validatorId)
        onlyOwner
    {
        IStakeManager.Validator memory smValidator = IStakeManager(stakeManager)
            .validators(_validatorId);

        require(
            smValidator.contractAddress != address(0),
            "Validator has no ValidatorShare"
        );
        require(
            (smValidator.status == IStakeManager.Status.Active) &&
                smValidator.deactivationEpoch == 0,
            "Validator isn't ACTIVE"
        );

        validators.push(_validatorId);
        validatorIdExists[_validatorId] = true;

        emit AddValidator(_validatorId);
    }

    /// @notice Allows to remove an validator from the registry.
    /// @param _validatorId the validator id.
    function removeValidator(uint256 _validatorId)
        external
        override
        whenNotPaused
        whenValidatorIdExists(_validatorId)
        onlyOwner
    {
        require(
            preferredDepositValidatorId != _validatorId,
            "Can't remove a preferred validator for deposits"
        );
        require(
            preferredWithdrawalValidatorId != _validatorId,
            "Can't remove a preferred validator for withdrawals"
        );

        address validatorShare = IStakeManager(stakeManager)
            .getValidatorContract(_validatorId);
        (uint256 validatorBalance, ) = IValidatorShare(validatorShare)
            .getTotalStake(address(this));
        require(validatorBalance == 0, "Validator has some shares left");

        // swap with the last item and pop it.
        uint256 validatorsLength = validators.length;
        for (uint256 idx = 0; idx < validatorsLength - 1; ++idx) {
            if (_validatorId == validators[idx]) {
                validators[idx] = validators[validatorsLength - 1];
                break;
            }
        }
        validators.pop();

        delete validatorIdExists[_validatorId];

        emit RemoveValidator(_validatorId);
    }

    /// -------------------------------Setters-----------------------------------

    /// @notice Allows to set the preffered validator id for deposits
    /// @param _validatorId the validator id.
    function setPreferredDepositValidatorId(uint256 _validatorId)
        external
        override
        whenNotPaused
        whenValidatorIdExists(_validatorId)
        onlyOwner
    {
        preferredDepositValidatorId = _validatorId;

        emit SetPreferredDepositValidatorId(_validatorId);
    }

    /// @notice Allows to set the preffered validator id for withdrawals
    /// @param _validatorId the validator id.
    function setPreferredWithdrawalValidatorId(uint256 _validatorId)
        external
        override
        whenNotPaused
        whenValidatorIdExists(_validatorId)
        onlyOwner
    {
        preferredWithdrawalValidatorId = _validatorId;

        emit SetPreferredWithdrawalValidatorId(_validatorId);
    }

    /// @notice Allows to pause the contract.
    function togglePause() external override onlyOwner {
        paused() ? _unpause() : _pause();
    }

    /// -------------------------------Getters-----------------------------------

    /// @notice Get the StakeManager contract addresses
    function getStakeManager()
        external
        view
        override
        returns (address _stakeManager)
    {
        _stakeManager = stakeManager;
    }

    /// @notice Get validator id by its index.
    /// @param _index validator index
    function getValidatorId(uint256 _index)
        external
        view
        override
        returns (uint256)
    {
        return validators[_index];
    }

    /// @notice Get validators.
    function getValidators() external view override returns (uint256[] memory) {
        return validators;
    }

    /// -------------------------------Modifiers-----------------------------------

    /**
     * @dev Modifier to make a function callable only when the validator id exists in our registry.
     *
     * Requirements:
     *
     * - The validator id must exist in our registry.
     */
    modifier whenValidatorIdExists(uint256 _validatorId) {
        require(
            validatorIdExists[_validatorId] == true,
            "Validator id doesn't exist in our registry"
        );
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the validator id doesn't exist in our registry.
     *
     * Requirements:
     *
     * - The validator id must not exist in our registry.
     */
    modifier whenValidatorIdDoesNotExist(uint256 _validatorId) {
        require(
            validatorIdExists[_validatorId] == false,
            "Validator id already exists in our registry"
        );
        _;
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title polygon stake manager interface.
/// @notice User to interact with the polygon stake manager.
interface IStakeManager {
	/// @notice Request unstake a validator.
	/// @param validatorId validator id.
	function unstake(uint256 validatorId) external;

	/// @notice Get the validator id using the user address.
	/// @param user user that own the validator in our case the validator contract.
	/// @return return the validator id
	function getValidatorId(address user) external view returns (uint256);

	/// @notice get the validator contract used for delegation.
	/// @param validatorId validator id.
	/// @return return the address of the validator contract.
	function getValidatorContract(uint256 validatorId)
		external
		view
		returns (address);

	/// @notice Withdraw accumulated rewards
	/// @param validatorId validator id.
	function withdrawRewards(uint256 validatorId) external;

	/// @notice Get validator total staked.
	/// @param validatorId validator id.
	function validatorStake(uint256 validatorId)
		external
		view
		returns (uint256);

	/// @notice Allows to unstake the staked tokens on the stakeManager.
	/// @param validatorId validator id.
	function unstakeClaim(uint256 validatorId) external;

	/// @notice Allows to migrate the staked tokens to another validator.
	/// @param fromValidatorId From validator id.
	/// @param toValidatorId To validator id.
	/// @param amount amount in Matic.
	function migrateDelegation(
		uint256 fromValidatorId,
		uint256 toValidatorId,
		uint256 amount
	) external;

	/// @notice Returns a withdrawal delay.
	function withdrawalDelay() external view returns (uint256);

	/// @notice Transfers amount from delegator
	function delegationDeposit(
		uint256 validatorId,
		uint256 amount,
		address delegator
	) external returns (bool);

	function epoch() external view returns (uint256);

	enum Status {
		Inactive,
		Active,
		Locked,
		Unstaked
	}

	struct Validator {
		uint256 amount;
		uint256 reward;
		uint256 activationEpoch;
		uint256 deactivationEpoch;
		uint256 jailTime;
		address signer;
		address contractAddress;
		Status status;
		uint256 commissionRate;
		uint256 lastCommissionUpdate;
		uint256 delegatorsReward;
		uint256 delegatedAmount;
		uint256 initialRewardPerStake;
	}

	function validators(uint256 _index)
		external
		view
		returns (Validator memory);

	// TODO: Remove it and use stakeFor instead
	function createValidator(uint256 _validatorId) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IValidatorShare.sol";
import "./IValidatorRegistry.sol";

/// @title JMS interface.
interface IJMS is IERC20 {
	struct WithdrawalRequest {
		uint256 validatorNonce;
		uint256 requestEpoch;
		address validatorAddress;
	}

	function treasury() external view returns (address);

	function feePercent() external view returns (uint8);

	function submit(uint256 _amount) external returns (uint256);

	function requestWithdraw(uint256 _amount) external;

	function claimWithdrawal(uint256 _idx) external;

	function withdrawRewards(uint256 _validatorId) external returns (uint256);

	function stakeRewardsAndDistributeFees(uint256 _validatorId) external;

	function migrateDelegation(
		uint256 _fromValidatorId,
		uint256 _toValidatorId,
		uint256 _amount
	) external;

	function togglePause() external;

	function convertJMSToMatic(uint256 _balance)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);

	function convertMaticToJMS(uint256 _balance)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);

	function setFeePercent(uint8 _feePercent) external;

	function setValidatorRegistry(address _address) external;

	function setTreasury(address _address) external;

	function getUserWithdrawalRequests(address _address)
		external
		view
		returns (WithdrawalRequest[] memory);

	function getSharesAmountOfUserWithdrawalRequest(
		address _address,
		uint256 _idx
	) external view returns (uint256);

	function getTotalStake(IValidatorShare _validatorShare)
		external
		view
		returns (uint256, uint256);

	function getTotalStakeAcrossAllValidators() external view returns (uint256);

	function getTotalPooledMatic() external view returns (uint256);

	function getContracts()
		external
		view
		returns (
			address _stakeManager,
			address _polygonERC20,
			address _validatorRegistry
		);

	event Submit(address indexed _from, uint256 _amount);
	event Delegate(uint256 indexed _validatorId, uint256 _amountDelegated);
	event RequestWithdraw(
		address indexed _from,
		uint256 _amountJMS,
		uint256 _amountMatic
	);
	event ClaimWithdrawal(
		address indexed _from,
		uint256 indexed _idx,
		uint256 _amountClaimed
	);
	event WithdrawRewards(uint256 indexed _validatorId, uint256 _rewards);
	event StakeRewards(uint256 indexed _validatorId, uint256 _amountStaked);
	event DistributeFees(address indexed _address, uint256 _amount);
	event MigrateDelegation(
		uint256 indexed _fromValidatorId,
		uint256 indexed _toValidatorId,
		uint256 _amount
	);
	event SetFeePercent(uint8 _feePercent);
	event SetTreasury(address _address);
	event SetValidatorRegistry(address _address);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

/// @title IValidatorRegistry
/// @notice Node validator registry interface
interface IValidatorRegistry {
    function addValidator(uint256 _validatorId) external;

    function removeValidator(uint256 _validatorId) external;

    function setPreferredDepositValidatorId(uint256 _validatorId) external;

    function setPreferredWithdrawalValidatorId(uint256 _validatorId) external;

    function togglePause() external;

    function preferredDepositValidatorId() external view returns (uint256);

    function preferredWithdrawalValidatorId() external view returns (uint256);

    function validatorIdExists(uint256 _validatorId)
        external
        view
        returns (bool);

    function getStakeManager() external view returns (address _stakeManager);

    function getValidatorId(uint256 _index) external view returns (uint256);

    function getValidators() external view returns (uint256[] memory);

    event AddValidator(uint256 indexed _validatorId);
    event RemoveValidator(uint256 indexed _validatorId);
    event SetPreferredDepositValidatorId(uint256 indexed _validatorId);
    event SetPreferredWithdrawalValidatorId(uint256 indexed _validatorId);
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

interface IValidatorShare {
    struct DelegatorUnbond {
        uint256 shares;
        uint256 withdrawEpoch;
    }

    function minAmount() external view returns (uint256);

    function unbondNonces(address _address) external view returns (uint256);

    function validatorId() external view returns (uint256);

    function delegation() external view returns (bool);

    function buyVoucher(uint256 _amount, uint256 _minSharesToMint)
        external
        returns (uint256);

    function sellVoucher_new(uint256 claimAmount, uint256 maximumSharesToBurn)
        external;

    function unstakeClaimTokens_new(uint256 unbondNonce) external;

    function restake() external returns (uint256, uint256);

    function withdrawRewards() external;

    function getTotalStake(address user)
        external
        view
        returns (uint256, uint256);

    function getLiquidRewards(address user) external view returns (uint256);

    function unbonds_new(address _address, uint256 _unbondNonce)
        external
        view
        returns (DelegatorUnbond memory);
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
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
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