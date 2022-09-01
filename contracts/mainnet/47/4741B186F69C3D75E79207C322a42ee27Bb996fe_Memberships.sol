// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;
// @dev: based on https://github.com/abdelhamidbakhta/token-vesting-contracts/blob/main/contracts/TokenVesting.sol

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

import "./MembershipsTypes.sol";
import "./HelperLib.sol";
import "./EternalStorage.sol";
import "./MembershipsImpl.sol";
import "./MembershipsErrors.sol";

contract Memberships is
	Ownable,
	Pausable,
	ReentrancyGuard,
	MembershipsTypes,
	MembershipsErrors
{
	using SafeERC20 for IERC20;

	address eternalStorage;
	address membershipsImpl;

	address private _rollWallet;
	uint256 private _minRollFee;

	uint256 constant BETA_PERIOD_DURATION = 6 * 30; // six months
	uint256 immutable betaPeriodExpiration;

	// ================
	// EVENTS
	// ================
	event EventScheduleCreated(
		address indexed from,
		bytes32 indexed scheduleId
	);

	event EventScheduleCreatedWithToken(
		address indexed from,
		bytes32 indexed scheduleId,
		address indexed token
	);

	event Revoked(bytes32 indexed scheduleId);

	event EventReferralUpdated(
		address indexed from,
		bytes32 indexed scheduleId,
		address indexed newReferral
	);

	event EventTokenAllowedUpdated(
		address indexed from,
		address indexed token,
		bool value
	);

	event EventMembershipsImplUpdated(
		address indexed from,
		address indexed addr
	);

	event EventRollWalletUpdated(address indexed from, address indexed addr);

	event EventEternalStorageUpdated(
		address indexed from,
		address indexed addr
	);

	event EventScheduleReferralSet(
		address indexed sender,
		bytes32 indexed scheduleId,
		address indexed referral,
		uint256 referralFee
	);

	event EventMinRollFeeUpdated(uint256 newMinRollFee);

	constructor(
		address eternalStorage_,
		address membershipsImpl_,
		address rollWallet,
		uint256 minRollFee
	) {
		if (
			eternalStorage_ == address(0) ||
			membershipsImpl_ == address(0) ||
			rollWallet == address(0)
		) {
			revert ErrorME13InvalidAddress();
		}
		eternalStorage = eternalStorage_;
		membershipsImpl = membershipsImpl_;
		_rollWallet = rollWallet;
		_minRollFee = minRollFee;
		betaPeriodExpiration = getCurrentTime() + BETA_PERIOD_DURATION * 1 days;
	}

	// ================
	// MODIFIERS
	// ================
	modifier onlyCampaignOwner(bytes32 scheduleId) {
		MintingSchedule memory schedule = MembershipsImpl(membershipsImpl)
			.getSchedule(scheduleId);
		if (msg.sender != schedule.owner) {
			revert ErrorME05OnlyOwnerAllowed();
		}
		_;
	}

	modifier onlyIfScheduleNotRevoked(bytes32 scheduleId) {
		MintingSchedule memory schedule = MembershipsImpl(membershipsImpl)
			.getSchedule(scheduleId);
		if (!schedule.initialized || schedule.revoked) {
			revert ErrorME07ScheduleRevoked();
		}
		_;
	}

	modifier onlyIfScheduleIsActive(bytes32 scheduleId) {
		MintingSchedule memory schedule = MembershipsImpl(membershipsImpl)
			.getSchedule(scheduleId);
		if (
			!schedule.initialized ||
			schedule.revoked ||
			schedule.start > getCurrentTime() ||
			schedule.start + schedule.duration <= getCurrentTime()
		) {
			revert ErrorME08ScheduleNotActive();
		}
		_;
	}

	modifier onlyScheduleAlreadyFinish(bytes32 scheduleId) {
		MintingSchedule memory schedule = MembershipsImpl(membershipsImpl)
			.getSchedule(scheduleId);
		if (schedule.start + schedule.duration >= getCurrentTime()) {
			revert ErrorME09ScheduleNotFinished();
		}
		_;
	}

	modifier onlyScheduleAlreadyFinishOrSoldOut(bytes32 scheduleId) {
		MintingSchedule memory schedule = MembershipsImpl(membershipsImpl)
			.getSchedule(scheduleId);
		if (
			schedule.start + schedule.duration >= getCurrentTime() &&
			schedule.released != schedule.amountTotal
		) {
			revert ErrorME25ScheduleNotFinishedOrSoldOut();
		}
		_;
	}

	modifier onlyMembershipsImpl() {
		if (msg.sender != membershipsImpl) {
			revert ErrorME26OnlyMembershipsImpl();
		}
		_;
	}

	// ================
	// PUBLIC FUNCTIONS
	// ================
	/**
	 * @notice Creates a new schedule for a beneficiary.
	 */
	function createMintingSchedule(
		CreateMintingScheduleParams memory params,
		uint256 phaseIndex
	) internal returns (bytes32) {
		MembershipsImpl(membershipsImpl).createMintingScheduleValidation(
			params
		);
		if (
			params.rollFee < _minRollFee ||
			params.rollFee > HelperLib.FEE_SCALE ||
			(params.rollFee + params.referralFee > HelperLib.FEE_SCALE)
		) revert ErrorME01InvalidFee(_minRollFee, HelperLib.FEE_SCALE);

		// valid payments are ETH or allowed tokens
		if (
			params.paymentAsset.assetType == AssetType.ERC20 &&
			!MembershipsImpl(membershipsImpl).isTokenAllowed(
				params.paymentAsset.token
			)
		) revert ErrorME02TokenNotAllowed();

		// transfer the reward tokens to the contract
		for (uint256 i = 0; i < params.lotToken.length; i++) {
			IERC20 token = IERC20(params.lotToken[i]);
			token.safeIncreaseAllowance(
				membershipsImpl,
				params.lotSize[i] * params.amountTotal
			);

			token.safeTransferFrom(
				msg.sender,
				address(this),
				params.lotSize[i] * params.amountTotal
			);
		}

		if (params.paymentAsset.assetType == AssetType.ERC20) {
			IERC20 token = IERC20(params.paymentAsset.token);
			token.safeIncreaseAllowance(
				address(this),
				params.pricePerLot * params.amountTotal
			);
		}

		MintingSchedule memory m = MintingSchedule(
			true,
			false,
			msg.sender,
			params.start,
			params.duration,
			params.merkleRoot,
			params.amountTotal,
			0,
			params.lotToken,
			params.lotSize,
			params.paymentAsset,
			params.pricePerLot,
			params.rollFee,
			params.maxBuyPerWallet
		);

		bytes32 scheduleId = computeNextScheduleIdForHolder(
			msg.sender,
			phaseIndex
		);
		MembershipsImpl(membershipsImpl).setSchedule(scheduleId, m);

		if (params.referral != address(0)) {
			MembershipsImpl(membershipsImpl).setReferral(
				scheduleId,
				ScheduleReferral(params.referral, params.referralFee)
			);
			emit EventScheduleReferralSet(
				msg.sender,
				scheduleId,
				params.referral,
				params.referralFee
			);
		}

		emit EventScheduleCreated(msg.sender, scheduleId);
		for (uint256 i = 0; i < params.lotToken.length; i++) {
			emit EventScheduleCreatedWithToken(
				msg.sender,
				scheduleId,
				params.lotToken[i]
			);
		}

		return scheduleId;
	}

	function createCampaign(
		CreateMintingScheduleParams[] memory params,
		string memory metadata
	) external nonReentrant whenNotPaused {
		uint256 phasesLength = uint256(params.length);
		if (phasesLength < 1) revert ErrorME04NotEnoughPhases();

		Campaign memory campaign = Campaign({
			campaignId: "",
			phases: new bytes32[](phasesLength),
			metadata: metadata
		});
		for (uint256 i = 0; i < phasesLength; i++) {
			bytes32 scheduleId = createMintingSchedule(params[i], i);
			campaign.phases[i] = scheduleId;
		}
		campaign.campaignId = campaign.phases[0];
		MembershipsImpl(membershipsImpl).addCampaign(campaign);
	}

	/**
	 * @notice Revokes the vesting schedule for given identifier.
	 */
	function revoke(bytes32 scheduleId)
		external
		onlyCampaignOwner(scheduleId)
		onlyIfScheduleNotRevoked(scheduleId)
		whenNotPaused
	{
		MembershipsImpl(membershipsImpl).revoke(scheduleId);
	}

	/**
	 * @notice Updates the campaign metadata.
	 */
	function updateCampaignMetadata(
		bytes32 campaignId,
		string calldata metadata
	) external onlyCampaignOwner(campaignId) whenNotPaused {
		MembershipsImpl(membershipsImpl).updateCampaignMetadata(
			campaignId,
			metadata
		);
	}

	/**
	 * @notice In original contract this method is called Withdraw
	 */
	function claim(bytes32 scheduleId)
		external
		whenNotPaused
		nonReentrant
		onlyScheduleAlreadyFinishOrSoldOut(scheduleId)
	{
		MembershipsImpl(membershipsImpl).claim(address(this), scheduleId);
	}

	function claimRoll(bytes32 scheduleId)
		external
		whenNotPaused
		nonReentrant
		onlyScheduleAlreadyFinishOrSoldOut(scheduleId)
	{
		MembershipsImpl(membershipsImpl).claimRoll(
			address(this),
			_rollWallet,
			scheduleId
		);
	}

	function claimReferral(bytes32 scheduleId)
		external
		whenNotPaused
		nonReentrant
		onlyScheduleAlreadyFinishOrSoldOut(scheduleId)
	{
		MembershipsImpl(membershipsImpl).claimReferral(
			address(this),
			scheduleId
		);
	}

	function claimUnsoldTokens(bytes32 scheduleId)
		external
		whenNotPaused
		nonReentrant
		onlyScheduleAlreadyFinish(scheduleId)
	{
		MembershipsImpl(membershipsImpl).claimUnsoldTokens(
			address(this),
			scheduleId
		);
	}

	/**
	 * @notice Buy method when there's no allowlist
	 */
	function buy(bytes32 scheduleId, uint256 amount)
		external
		payable
		whenNotPaused
		nonReentrant
		onlyIfScheduleIsActive(scheduleId)
	{
		MintingSchedule memory schedule = MembershipsImpl(membershipsImpl)
			.getSchedule(scheduleId);
		if (schedule.merkleRoot != bytes32("")) {
			revert ErrorME10ActionAllowlisted();
		}

		MembershipsImpl(membershipsImpl).buy(
			address(this),
			msg.sender,
			scheduleId,
			amount,
			msg.value
		);
	}

	/**
	 * @notice Buy method when there's an allowlist
	 */
	function buyWithAllowlist(
		bytes32 scheduleId,
		uint256 amount,
		bytes32[] memory proof
	)
		external
		payable
		whenNotPaused
		nonReentrant
		onlyIfScheduleIsActive(scheduleId)
	{
		MembershipsImpl(membershipsImpl).verifyMerkle(
			msg.sender,
			scheduleId,
			proof
		);

		MembershipsImpl(membershipsImpl).buy(
			address(this),
			msg.sender,
			scheduleId,
			amount,
			msg.value
		);
	}

	function doTransfer(
		AssetType assetType,
		address tokenAddress,
		address from,
		address to,
		uint256 value
	) external onlyMembershipsImpl {
		if (to == address(0)) revert ErrorME13InvalidAddress();

		if (assetType == AssetType.ETH) {
			(bool sent, ) = to.call{ value: value }("");
			if (!sent) revert ErrorME11TransferError();
		} else {
			IERC20 token = IERC20(tokenAddress);
			token.safeTransferFrom(from, to, value);
		}
	}

	// ================
	// ADMIN FUNCTIONS
	// ================

	// set a new merkle tree root
	function setAllowlist(bytes32 scheduleId, bytes32 root)
		external
		onlyCampaignOwner(scheduleId)
	{
		MembershipsImpl(membershipsImpl).setAllowlist(scheduleId, root);
	}

	// transfer the ownership
	function transferScheduleOwner(bytes32 scheduleId, address owner_)
		external
		onlyCampaignOwner(scheduleId)
	{
		MembershipsImpl(membershipsImpl).transferScheduleOwner(
			scheduleId,
			owner_
		);
	}

	// change referral
	function updateReferral(bytes32 scheduleId, address referral)
		external
		nonReentrant
		onlyCampaignOwner(scheduleId)
	{
		MembershipsImpl(membershipsImpl).updateReferral(scheduleId, referral);
		emit EventReferralUpdated(msg.sender, scheduleId, referral);
	}

	// ================
	// GETTER FUNCTIONS
	// ================

	/**
	 * @notice Computes the vested amount of tokens for the given vesting schedule identifier.
	 * @return the vested amount
	 */
	function computeUnsoldLots(bytes32 scheduleId)
		external
		view
		onlyIfScheduleNotRevoked(scheduleId)
		returns (uint256)
	{
		return MembershipsImpl(membershipsImpl).computeUnsoldLots(scheduleId);
	}

	/**
	 * @dev Computes the next vesting schedule identifier for a given holder address.
	 */
	function computeNextScheduleIdForHolder(address holder, uint256 phaseIndex)
		internal
		view
		returns (bytes32)
	{
		return
			computeScheduleIdForAddressAndIndex(
				holder,
				phaseIndex,
				MembershipsImpl(membershipsImpl).getCampaignCreatedByAddress(
					holder
				)
			);
	}

	/**
	 * @dev Computes the vesting schedule identifier for an address and an index.
	 */
	function computeScheduleIdForAddressAndIndex(
		address holder,
		uint256 index,
		uint256 length
	) public pure returns (bytes32) {
		return keccak256(abi.encodePacked(holder, index, length));
	}

	function getMinRollFee() external view returns (uint256) {
		return _minRollFee;
	}

	// ==================
	// ROLL ADMIN FUNCTIONS
	// ==================
	function setRollWallet(address newRollWallet) external onlyOwner {
		if (newRollWallet == address(0)) {
			revert ErrorME13InvalidAddress();
		}
		_rollWallet = newRollWallet;
		emit EventRollWalletUpdated(msg.sender, newRollWallet);
	}

	function setMinRollFee(uint256 newMinRollFee) external onlyOwner {
		if (newMinRollFee >= HelperLib.FEE_SCALE)
			revert ErrorME01InvalidFee(newMinRollFee, HelperLib.FEE_SCALE);

		_minRollFee = newMinRollFee;
		emit EventMinRollFeeUpdated(newMinRollFee);
	}

	function setTokenAllow(address token, bool value) external onlyOwner {
		if (token == address(0)) {
			revert ErrorME13InvalidAddress();
		}
		MembershipsImpl(membershipsImpl).setTokensAllowed(token, value);
		emit EventTokenAllowedUpdated(msg.sender, token, value);
	}

	function setEternalStorageAddress(address addr) external onlyOwner {
		if (addr == address(0)) {
			revert ErrorME13InvalidAddress();
		}
		eternalStorage = addr;

		emit EventEternalStorageUpdated(msg.sender, addr);
	}

	function setMembershipsImplAddress(address addr) external onlyOwner {
		if (addr == address(0)) {
			revert ErrorME13InvalidAddress();
		}
		membershipsImpl = addr;

		emit EventMembershipsImplUpdated(msg.sender, addr);
	}

	function pause() external onlyOwner {
		if (betaPeriodExpiration < getCurrentTime())
			revert ErrorME14BetaPeriodAlreadyFinish();
		_pause();
	}

	// ==================
	// INTERNAL FUNCTIONS
	// ==================

	function getCurrentTime() internal view virtual returns (uint256) {
		return block.timestamp;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

interface MembershipsTypes {
	enum UserType {
		OWNER,
		ROLL,
		REFERRAL,
		UNSOLD
	}

	enum AssetType {
		ETH,
		ERC20
	}
	struct Asset {
		address token;
		AssetType assetType;
	}

	struct MintingSchedule {
		bool initialized;
		// whether or not the minting has been revoked
		bool revoked;
		// creator
		address owner;
		// start time of the minting period
		uint256 start;
		// duration of the minting period in seconds
		uint256 duration;
		// merkleRoot. If merkleRoot is 0 then means there’s no allowed for this schedule
		bytes32 merkleRoot;
		// total amount of lots to be released at the end of the minting
		uint256 amountTotal;
		// amount of lots released
		uint256 released;
		// rewarded tokens
		address[] lotToken;
		// lot size in wei
		uint256[] lotSize;
		// ETH / ERC20
		Asset paymentAsset;
		// price per lot
		uint256 pricePerLot;
		// roll fee
		uint256 rollFee;
		// maxBuyPerWallet
		uint256 maxBuyPerWallet;
	}

	struct ScheduleReferral {
		// referral
		address referral;
		// referral fee
		uint256 referralFee;
	}

	struct CreateMintingScheduleParams {
		uint256 start;
		uint256 duration;
		bytes32 merkleRoot;
		uint256 amountTotal;
		address[] lotToken;
		uint256[] lotSize;
		uint256 pricePerLot;
		Asset paymentAsset;
		uint256 rollFee;
		address referral;
		uint256 referralFee;
		uint256 maxBuyPerWallet;
	}

	struct Campaign {
		bytes32 campaignId;
		bytes32[] phases;
		string metadata;
	}

	struct ScheduleCampaign {
		bytes32 campaignId;
		uint256 campaignIndex;
		uint256 scheduleIndex;
	}

	struct CampaignsAddress {
		uint256 campaignIndex;
		UserType userType;
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;

library HelperLib {
	uint256 constant FEE_SCALE = 1_000_000;

	function getFeeFraction(uint256 amount, uint256 fee)
		internal
		pure
		returns (uint256)
	{
		if (fee == 0) return 0;
		return (amount * fee) / FEE_SCALE;
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;
// @dev: based on https://github.com/abdelhamidbakhta/token-vesting-contracts/blob/main/contracts/TokenVesting.sol

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

import "./MembershipsTypes.sol";

contract EternalStorage is MembershipsTypes, AccessControl {
	bytes32 public constant WRITER_ROLE = keccak256("WRITER_ROLE");

	Campaign[] private campaigns;

	mapping(bytes32 => uint256) private campaignToIndex;

	mapping(bytes32 => ScheduleCampaign) public scheduleToCampaign;

	mapping(address => uint256) private campaignsByAddressLength;

	mapping(address => mapping(uint256 => CampaignsAddress))
		public campaignsByAddress;

	mapping(address => uint256) public campaignsCreatedByAddress;

	mapping(bytes32 => MintingSchedule) public schedules;

	mapping(bytes32 => mapping(UserType => uint256)) private _claimed;

	mapping(bytes32 => mapping(address => uint256)) private _buyPerWallet;

	// No of addresses who have bought per schedule
	mapping(bytes32 => uint256) private _buyPerWalletCount;

	mapping(bytes32 => ScheduleReferral) private schedulesReferral;

	event CampaignCreated(address indexed from, uint256 indexed campaignIndex);

	address[] private tokensAllowedArr;

	constructor() {
		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_grantRole(WRITER_ROLE, address(this));
	}

	function getSchedule(bytes32 record)
		external
		view
		returns (MintingSchedule memory)
	{
		return schedules[record];
	}

	function setSchedule(bytes32 record, MintingSchedule calldata value)
		external
		onlyRole(WRITER_ROLE)
	{
		schedules[record] = value;
	}

	function getReferral(bytes32 record)
		external
		view
		returns (ScheduleReferral memory)
	{
		return schedulesReferral[record];
	}

	function setReferral(bytes32 record, ScheduleReferral calldata value)
		external
		onlyRole(WRITER_ROLE)
	{
		schedulesReferral[record] = value;
	}

	function removeReferral(bytes32 record, address oldReferral)
		external
		onlyRole(WRITER_ROLE)
	{
		//@dev: this is to remove indexes to filter campaings by referral
		uint256 campaignsByOwner = campaignsByAddressLength[oldReferral];
		for (uint256 i = 0; i < campaignsByOwner; i++) {
			if (
				campaignsByAddress[oldReferral][i].campaignIndex ==
				scheduleToCampaign[record].campaignIndex
			) {
				campaignsByAddress[oldReferral][i] = campaignsByAddress[
					oldReferral
				][campaignsByOwner - 1];
				delete campaignsByAddress[oldReferral][campaignsByOwner - 1];
				campaignsByAddressLength[oldReferral]--;
				break;
			}
		}
	}

	function setBuyPerWallet(
		bytes32 scheduleID,
		address addr,
		uint256 value
	) external onlyRole(WRITER_ROLE) {
		if (_buyPerWallet[scheduleID][addr] == 0) {
			_buyPerWalletCount[scheduleID]++;
		}
		_buyPerWallet[scheduleID][addr] = value;
	}

	function getBuyPerWallet(bytes32 scheduleID, address addr)
		external
		view
		returns (uint256)
	{
		return _buyPerWallet[scheduleID][addr];
	}

	function setTokensAllowed(address token, bool value)
		external
		onlyRole(WRITER_ROLE)
	{
		for (uint256 i = 0; i < tokensAllowedArr.length; i++) {
			if (tokensAllowedArr[i] == token) {
				if (value) {
					return;
				} else {
					tokensAllowedArr[i] = tokensAllowedArr[
						tokensAllowedArr.length - 1
					];
					tokensAllowedArr.pop();
					return;
				}
			}
		}
		if (value) {
			tokensAllowedArr.push(token);
		}
	}

	function getTokensAllowed() external view returns (address[] memory) {
		return tokensAllowedArr;
	}

	function isTokenAllowed(address addr) external view returns (bool) {
		for (uint256 i = 0; i < tokensAllowedArr.length; i++) {
			if (tokensAllowedArr[i] == addr) {
				return true;
			}
		}
		return false;
	}

	function getBuyWalletCount(bytes32 scheduleID)
		external
		view
		returns (uint256)
	{
		return _buyPerWalletCount[scheduleID];
	}

	function updateCampaignMetadata(
		bytes32 campaignId,
		string calldata metadata
	) external onlyRole(WRITER_ROLE) {
		campaigns[campaignToIndex[campaignId]].metadata = metadata;
	}

	function getCampaignMetadata(bytes32 campaignId)
		external
		view
		returns (string memory)
	{
		return campaigns[campaignToIndex[campaignId]].metadata;
	}

	function setClaimed(
		bytes32 scheduleID,
		UserType userType,
		uint256 value
	) external onlyRole(WRITER_ROLE) {
		_claimed[scheduleID][userType] = value;
	}

	function getClaimed(bytes32 scheduleID, UserType userType)
		external
		view
		returns (uint256)
	{
		return _claimed[scheduleID][userType];
	}

	function addCampaign(Campaign calldata value)
		external
		onlyRole(WRITER_ROLE)
	{
		bytes32 phase0 = value.phases[0];

		campaigns.push(value);

		for (uint256 i = 0; i < value.phases.length; i++) {
			scheduleToCampaign[value.phases[i]] = ScheduleCampaign(
				value.campaignId,
				campaigns.length - 1,
				i
			);
		}

		//@dev: this is to update indexes to filter campaings by owner
		address owner = schedules[phase0].owner;
		uint256 campaignsByOwner = campaignsByAddressLength[owner];
		campaignsByAddress[owner][campaignsByOwner].campaignIndex =
			campaigns.length -
			1;
		campaignsByAddress[owner][campaignsByOwner].userType = UserType.OWNER;
		campaignsByAddressLength[owner]++;

		//@dev: this is to update indexes to filter campaings by referral
		for (uint256 i = 0; i < value.phases.length; i++) {
			address referral = schedulesReferral[value.phases[i]].referral;
			if (referral != address(0)) {
				this.updateReferralIndex(referral, campaigns.length - 1);
			}
		}

		campaignsCreatedByAddress[owner]++;
		campaignToIndex[value.campaignId] = campaigns.length - 1;
		emit CampaignCreated(owner, campaigns.length);
	}

	function updateReferralIndex(address referral, uint256 campaignIndex)
		external
		onlyRole(WRITER_ROLE)
	{
		uint256 referralCampaignsCount = campaignsByAddressLength[referral];
		campaignsByAddress[referral][referralCampaignsCount]
			.campaignIndex = campaignIndex;
		campaignsByAddress[referral][referralCampaignsCount].userType = UserType
			.REFERRAL;
		campaignsByAddressLength[referral]++;
	}

	function getCampaign(uint256 record)
		external
		view
		returns (Campaign memory)
	{
		return campaigns[record];
	}

	function getCampaignCreatedByAddress(address addr)
		external
		view
		returns (uint256)
	{
		return campaignsCreatedByAddress[addr];
	}

	function getCampaignByAddressLength(address addr)
		external
		view
		returns (uint256)
	{
		return campaignsByAddressLength[addr];
	}

	function getCampaignsLength() external view returns (uint256) {
		return campaigns.length;
	}
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;
// @dev: based on https://github.com/abdelhamidbakhta/token-vesting-contracts/blob/main/contracts/TokenVesting.sol

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

import "./MembershipsTypes.sol";
import "./HelperLib.sol";
import "./EternalStorage.sol";
import "./MembershipsErrors.sol";

interface IMemberships {
	function doTransfer(
		MembershipsTypes.AssetType assetType,
		address token,
		address from,
		address to,
		uint256 value
	) external;
}

contract MembershipsImpl is MembershipsTypes, AccessControl, MembershipsErrors {
	using SafeERC20 for IERC20;

	bytes32 public constant MEMBERSHIP_ROLE = keccak256("MEMBERSHIP_ROLE");
	EternalStorage private _eternalStorage;

	event EventAllowlistUpdated(
		bytes32 indexed scheduleId,
		bytes32 indexed newRoot
	);

	event EventScheduleOwnerTransferred(
		bytes32 indexed scheduleId,
		address indexed oldOwner,
		address indexed newOwner
	);

	event EventScheduleRevoked(bytes32 indexed scheduleId);

	event EventUnsoldTokensClaimed(
		address indexed memberships,
		bytes32 indexed scheduleId,
		uint256 amount
	);

	// @dev: we emit two kind of event, one per buy and one per token
	event EventBuyLot(
		address indexed from,
		bytes32 indexed scheduleId,
		uint256 lots
	);

	event EventBuyToken(
		address indexed from,
		bytes32 indexed scheduleId,
		address indexed token,
		uint256 tokens
	);

	event EventClaim(
		address indexed from,
		bytes32 indexed scheduleId,
		uint256 value
	);

	constructor(address eternalStorage) {
		if (eternalStorage == address(0)) {
			revert ErrorME13InvalidAddress();
		}

		_grantRole(DEFAULT_ADMIN_ROLE, msg.sender);

		_eternalStorage = EternalStorage(eternalStorage);
	}

	// ==================
	// STORAGE GET/SET
	// ==================
	function getCampaignCreatedByAddress(address addr)
		external
		view
		returns (uint256)
	{
		return _eternalStorage.getCampaignCreatedByAddress(addr);
	}

	function getBuyPerWallet(bytes32 scheduleId, address addr)
		internal
		view
		returns (uint256)
	{
		return _eternalStorage.getBuyPerWallet(scheduleId, addr);
	}

	function setBuyPerWallet(
		bytes32 scheduleId,
		address addr,
		uint256 value
	) public onlyRole(MEMBERSHIP_ROLE) {
		_eternalStorage.setBuyPerWallet(scheduleId, addr, value);
	}

	function isTokenAllowed(address addr) external view returns (bool) {
		return _eternalStorage.isTokenAllowed(addr);
	}

	function getTokensAllowed() internal view returns (address[] memory) {
		return _eternalStorage.getTokensAllowed();
	}

	function setTokensAllowed(address token, bool value)
		public
		onlyRole(MEMBERSHIP_ROLE)
	{
		_eternalStorage.setTokensAllowed(token, value);
	}

	function getClaimed(bytes32 scheduleId, UserType userType)
		public
		view
		returns (uint256)
	{
		return _eternalStorage.getClaimed(scheduleId, userType);
	}

	function setClaimed(
		bytes32 scheduleId,
		UserType userType,
		uint256 value
	) public onlyRole(MEMBERSHIP_ROLE) {
		_eternalStorage.setClaimed(scheduleId, userType, value);
	}

	function addCampaign(Campaign memory value)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		_eternalStorage.addCampaign(value);
	}

	function getSchedule(bytes32 record)
		public
		view
		returns (MintingSchedule memory)
	{
		return _eternalStorage.getSchedule(record);
	}

	function setSchedule(bytes32 record, MintingSchedule memory value)
		public
		onlyRole(MEMBERSHIP_ROLE)
	{
		_eternalStorage.setSchedule(record, value);
	}

	function getReferral(bytes32 record)
		public
		view
		returns (ScheduleReferral memory)
	{
		return _eternalStorage.getReferral(record);
	}

	function setReferral(bytes32 record, ScheduleReferral memory value)
		public
		onlyRole(MEMBERSHIP_ROLE)
	{
		_eternalStorage.setReferral(record, value);
	}

	function _removeReferral(bytes32 record, address oldReferral)
		internal
		onlyRole(MEMBERSHIP_ROLE)
	{
		_eternalStorage.removeReferral(record, oldReferral);
	}

	function updateCampaignMetadata(
		bytes32 campaignId,
		string calldata metadata
	) public onlyRole(MEMBERSHIP_ROLE) {
		_eternalStorage.updateCampaignMetadata(campaignId, metadata);
	}

	// ==================
	// VALIDATORS
	// ==================
	function createMintingScheduleValidation(
		CreateMintingScheduleParams calldata params
	) external view {
		if (params.start < getCurrentTime()) revert ErrorME15InvalidDate();
		if (params.duration == 0) revert ErrorME16InvalidDuration();
		if (params.pricePerLot == 0) revert ErrorME17InvalidPrice();
		if (
			params.lotToken.length == 0 ||
			params.lotSize.length == 0 ||
			params.lotToken.length != params.lotSize.length
		) revert ErrorME18LotArrayLengthMismatch();
		if (
			(params.referral != address(0) || params.referralFee != 0) &&
			(params.referral == address(0) || params.referralFee == 0)
		) revert ErrorME20InvalidReferral();
		if (params.referralFee >= HelperLib.FEE_SCALE)
			revert ErrorME21InvalidReferralFee();
		if (params.amountTotal == 0) revert ErrorME28InvalidAmount();
		if (params.maxBuyPerWallet == 0)
			revert ErrorME29InvalidMaxBuyPerWallet();
	}

	// ==================
	// BUY / CLAIM FUNCTIONS
	// ==================

	function buy(
		address memberships,
		address caller,
		bytes32 scheduleId,
		uint256 amount,
		uint256 msgValue
	) external onlyRole(MEMBERSHIP_ROLE) {
		MintingSchedule memory schedule = getSchedule(scheduleId);

		uint256 callerPreviousAmount = getBuyPerWallet(scheduleId, caller);

		if (amount + schedule.released > schedule.amountTotal)
			revert ErrorME27TotalAmountExceeded();

		if (amount + callerPreviousAmount > schedule.maxBuyPerWallet)
			revert ErrorME22MaxBuyPerWalletExceeded();

		if (schedule.paymentAsset.assetType == AssetType.ETH) {
			if (msgValue != schedule.pricePerLot * amount)
				revert ErrorME19NotEnoughEth();
		} else {
			IERC20 token = IERC20(schedule.paymentAsset.token);
			token.safeTransferFrom(
				caller,
				memberships,
				schedule.pricePerLot * amount
			);
		}
		schedule.released = schedule.released + amount;
		setSchedule(scheduleId, schedule);
		setBuyPerWallet(scheduleId, caller, callerPreviousAmount + amount);
		for (uint256 i = 0; i < schedule.lotToken.length; i++) {
			IERC20 token = IERC20(schedule.lotToken[i]);
			token.safeTransferFrom(
				memberships,
				caller,
				schedule.lotSize[i] * amount
			);

			emit EventBuyToken(
				caller,
				scheduleId,
				schedule.lotToken[i],
				schedule.lotSize[i] * amount
			);
		}

		emit EventBuyLot(caller, scheduleId, amount);
	}

	/**
	 * @notice In original contract this method is called Withdraw
	 */
	function claim(address memberships, bytes32 scheduleId)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		MintingSchedule memory schedule = getSchedule(scheduleId);

		uint256 earned = schedule.pricePerLot * schedule.released;

		uint256 totalClaimed = getClaimed(
			scheduleId,
			MembershipsTypes.UserType.OWNER
		);

		if (totalClaimed != 0 && totalClaimed >= earned)
			revert ErrorME23TotalClaimedError();

		uint256 referralFee = getReferral(scheduleId).referralFee;

		earned =
			earned -
			HelperLib.getFeeFraction(earned, schedule.rollFee) -
			HelperLib.getFeeFraction(earned, referralFee);

		IMemberships(memberships).doTransfer(
			schedule.paymentAsset.assetType,
			schedule.paymentAsset.token,
			memberships,
			schedule.owner,
			earned - totalClaimed
		);

		setClaimed(scheduleId, MembershipsTypes.UserType.OWNER, earned);

		emit EventClaim(msg.sender, scheduleId, earned);
	}

	function claimRoll(
		address memberships,
		address wallet,
		bytes32 scheduleId
	) external onlyRole(MEMBERSHIP_ROLE) {
		MintingSchedule memory schedule = getSchedule(scheduleId);

		uint256 earned = HelperLib.getFeeFraction(
			schedule.pricePerLot * schedule.released,
			schedule.rollFee
		);

		uint256 totalClaimed = getClaimed(
			scheduleId,
			MembershipsTypes.UserType.ROLL
		);

		if (totalClaimed != 0 && totalClaimed >= earned)
			revert ErrorME23TotalClaimedError();

		IMemberships(memberships).doTransfer(
			schedule.paymentAsset.assetType,
			schedule.paymentAsset.token,
			memberships,
			wallet,
			earned - totalClaimed
		);

		setClaimed(scheduleId, MembershipsTypes.UserType.ROLL, earned);

		emit EventClaim(msg.sender, scheduleId, earned);
	}

	function claimReferral(address memberships, bytes32 scheduleId)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		MintingSchedule memory schedule = getSchedule(scheduleId);

		ScheduleReferral memory scheduleR = getReferral(scheduleId);

		uint256 earned = HelperLib.getFeeFraction(
			schedule.pricePerLot * schedule.released,
			scheduleR.referralFee
		);

		uint256 totalClaimed = getClaimed(
			scheduleId,
			MembershipsTypes.UserType.REFERRAL
		);

		if (totalClaimed != 0 && totalClaimed >= earned)
			revert ErrorME23TotalClaimedError();

		IMemberships(memberships).doTransfer(
			schedule.paymentAsset.assetType,
			schedule.paymentAsset.token,
			memberships,
			scheduleR.referral,
			earned - totalClaimed
		);

		setClaimed(scheduleId, MembershipsTypes.UserType.REFERRAL, earned);

		emit EventClaim(msg.sender, scheduleId, earned);
	}

	function claimUnsoldTokens(address memberships, bytes32 scheduleId)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		MintingSchedule memory schedule = getSchedule(scheduleId);

		uint256 totalClaimed = getClaimed(
			scheduleId,
			MembershipsTypes.UserType.UNSOLD
		);

		if (
			schedule.amountTotal - schedule.released != 0 &&
			totalClaimed == (schedule.amountTotal - schedule.released)
		) revert ErrorME23TotalClaimedError();

		for (uint256 i = 0; i < schedule.lotToken.length; i++) {
			IERC20 token = IERC20(schedule.lotToken[i]);
			token.safeTransferFrom(
				memberships,
				schedule.owner,
				schedule.lotSize[i] * (schedule.amountTotal - schedule.released)
			);
		}

		setClaimed(
			scheduleId,
			MembershipsTypes.UserType.UNSOLD,
			(schedule.amountTotal - schedule.released)
		);

		emit EventUnsoldTokensClaimed(
			memberships,
			scheduleId,
			schedule.amountTotal - schedule.released
		);
	}

	function verifyMerkle(
		address caller,
		bytes32 scheduleId,
		bytes32[] memory proof
	) external view {
		MintingSchedule memory schedule = getSchedule(scheduleId);
		// Verify merkle proof
		bytes32 leaf = keccak256(abi.encodePacked(caller));

		if (!MerkleProof.verify(proof, schedule.merkleRoot, leaf))
			revert ErrorME24InvalidProof();
	}

	// ================
	// OWNER ADMIN FUNCTIONS
	// ================

	// set a new merkle tree root
	function setAllowlist(bytes32 scheduleId, bytes32 root)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		MintingSchedule memory s = getSchedule(scheduleId);
		if (s.merkleRoot != root) {
			s.merkleRoot = root;
			setSchedule(scheduleId, s);
			emit EventAllowlistUpdated(scheduleId, root);
		}
	}

	// transfer the ownership
	function transferScheduleOwner(bytes32 scheduleId, address owner_)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		MintingSchedule memory s = getSchedule(scheduleId);
		if (s.owner != owner_) {
			address oldOwner = s.owner;
			s.owner = owner_;
			setSchedule(scheduleId, s);
			emit EventScheduleOwnerTransferred(scheduleId, oldOwner, owner_);
		}
	}

	// change referral
	function updateReferral(bytes32 scheduleId, address referral)
		external
		onlyRole(MEMBERSHIP_ROLE)
	{
		ScheduleReferral memory s = getReferral(scheduleId);
		address oldReferral = s.referral;
		s.referral = referral;

		(, uint256 campaignIndex, ) = _eternalStorage.scheduleToCampaign(
			scheduleId
		);

		setReferral(scheduleId, s);
		_eternalStorage.updateReferralIndex(referral, campaignIndex);

		if (oldReferral != address(0)) {
			_removeReferral(scheduleId, oldReferral);
		}
	}

	function revoke(bytes32 scheduleId) external onlyRole(MEMBERSHIP_ROLE) {
		MembershipsTypes.MintingSchedule memory schedule = getSchedule(
			scheduleId
		);
		schedule.revoked = true;
		setSchedule(scheduleId, schedule);
		emit EventScheduleRevoked(scheduleId);
	}

	// ==================
	// INTERNAL IMPL
	// ==================

	/**
	 * @dev Computes the releasable amount of tokens for a vesting schedule.
	 * @return the amount of releasable tokens
	 */
	function computeUnsoldLots(bytes32 scheduleId)
		external
		view
		returns (uint256)
	{
		MembershipsTypes.MintingSchedule memory schedule = getSchedule(
			scheduleId
		);
		uint256 currentTime = getCurrentTime();
		if (schedule.revoked) {
			return 0;
		} else if (currentTime >= schedule.start + schedule.duration) {
			return schedule.amountTotal - schedule.released;
		}
		return 0;
	}

	// ==================
	// INTERNAL FUNCTIONS
	// ==================

	function getCurrentTime() internal view virtual returns (uint256) {
		return block.timestamp;
	}
}

// SPDX-License-Identifier: MIT
pragma solidity =0.8.7;

interface MembershipsErrors {
	error ErrorME01InvalidFee(uint256 minRollFee, uint256 maxFee);
	error ErrorME02TokenNotAllowed();
	error ErrorME03NotEnoughTokens();
	error ErrorME04NotEnoughPhases();
	error ErrorME05OnlyOwnerAllowed();
	error ErrorME06ScheduleDoesNotExists();
	error ErrorME07ScheduleRevoked();
	error ErrorME08ScheduleNotActive();
	error ErrorME09ScheduleNotFinished();
	error ErrorME10ActionAllowlisted();
	error ErrorME11TransferError();
	error ErrorME12IndexOutOfBounds();
	error ErrorME13InvalidAddress();
	error ErrorME14BetaPeriodAlreadyFinish();
	error ErrorME15InvalidDate();
	error ErrorME16InvalidDuration();
	error ErrorME17InvalidPrice();
	error ErrorME18LotArrayLengthMismatch();
	error ErrorME19NotEnoughEth();
	error ErrorME20InvalidReferral();
	error ErrorME21InvalidReferralFee();
	error ErrorME22MaxBuyPerWalletExceeded();
	error ErrorME23TotalClaimedError();
	error ErrorME24InvalidProof();
	error ErrorME25ScheduleNotFinishedOrSoldOut();
	error ErrorME26OnlyMembershipsImpl();
	error ErrorME27TotalAmountExceeded();
	error ErrorME28InvalidAmount();
	error ErrorME29InvalidMaxBuyPerWallet();
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
// OpenZeppelin Contracts v4.4.1 (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role, _msgSender());
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
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
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Trees proofs.
 *
 * The proofs can be generated using the JavaScript library
 * https://github.com/miguelmota/merkletreejs[merkletreejs].
 * Note: the hashing algorithm should be keccak256 and pair sorting should be enabled.
 *
 * See `test/utils/cryptography/MerkleProof.test.js` for some examples.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merklee tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                // Hash(current computed hash + current element of the proof)
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                // Hash(current element of the proof + current computed hash)
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        return computedHash;
    }
}