// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "../contracts/interfaces/IPartnerStaking.sol";
import "../contracts/interfaces/IMaticX.sol";

contract PartnerStaking is
	IPartnerStaking,
	Initializable,
	AccessControlUpgradeable,
	PausableUpgradeable
{
	using SafeERC20Upgradeable for IERC20Upgradeable;

	mapping(uint32 => Partner) public partners;
	mapping(address => uint32) public partnerAddressToId;
	uint32 public override currentPartnerId;
	UnstakeRequest[] public unstakeRequests;

	mapping(uint32 => Batch) public batches;
	uint32 public override currentBatchId;
	uint8 public override feeReimbursalPercent;
	uint256 public override feeReimbursalPool;

	address private foundationAddress;
	mapping(address => uint64) private foundationApprovedAddresses;
	address private maticX;
	address private polygonERC20;
	address private manager;
	address private disbursalBotAddress;
	address private trustedForwarder;

	function initialize(
		address _foundationAddress,
		address _polygonERC20,
		address _maticX,
		address _manager,
		address _disbursalBotAddress
	) external initializer {
		__AccessControl_init();
		__Pausable_init();

		foundationAddress = _foundationAddress;
		foundationApprovedAddresses[foundationAddress] = uint64(
			block.timestamp
		);
		maticX = _maticX;
		manager = _manager;
		disbursalBotAddress = _disbursalBotAddress;
		polygonERC20 = _polygonERC20;
		feeReimbursalPercent = 5;

		// create a new batch
		currentBatchId = 1;
		Batch storage _currentBatch = batches[currentBatchId];
		_currentBatch.createdAt = uint64(block.timestamp);
		_currentBatch.status = BatchStatus.CREATED;
	}

	modifier onlyFoundation() {
		require(_msgSender() == foundationAddress, "Not Authorized");
		_;
	}

	modifier onlyManager() {
		require(_msgSender() == manager, "Not Authorized");
		_;
	}

	modifier onlyDisbursalBot() {
		require(_msgSender() == disbursalBotAddress, "Not Authorized");
		_;
	}

	function addFoundationApprovedAddress(address _address)
		external
		override
		onlyFoundation
	{
		require(_address != address(0), "Invalid Address");
		foundationApprovedAddresses[_address] = uint64(block.timestamp);
		emit AddFoundationApprovedAddress(_address, block.timestamp);
	}

	function removeFoundationApprovedAddress(address _address)
		external
		override
		onlyFoundation
	{
		require(_address != address(0), "Invalid Address");
		foundationApprovedAddresses[_address] = uint64(0);
		emit RemoveFoundationApprovedAddress(_address, block.timestamp);
	}

	function isFoundationApprovedAddress(address _address)
		external
		view
		virtual
		returns (bool)
	{
		return (foundationApprovedAddresses[_address] > 0);
	}

	function setDisbursalBotAddress(address _address)
		external
		override
		onlyManager
	{
		require(_address != address(0), "Invalid Address");
		disbursalBotAddress = _address;

		emit SetDisbursalBotAddress(_address, block.timestamp);
	}

	function isDisbursalBotAddress(address _address)
		public
		view
		virtual
		returns (bool)
	{
		return _address == disbursalBotAddress;
	}

	function setTrustedForwarder(address _address)
		external
		override
		onlyManager
	{
		trustedForwarder = _address;

		emit SetTrustedForwarder(_address);
	}

	function isTrustedForwarder(address _address)
		public
		view
		virtual
		returns (bool)
	{
		return _address == trustedForwarder;
	}

	function _msgSender()
		internal
		view
		virtual
		override
		returns (address sender)
	{
		if (isTrustedForwarder(msg.sender)) {
			// The assembly code is more direct than the Solidity version using `abi.decode`.
			assembly {
				sender := shr(96, calldataload(sub(calldatasize(), 20)))
			}
		} else {
			return super._msgSender();
		}
	}

	function setFeeReimbursalPercent(uint8 _feeReimbursalPercent)
		external
		override
		whenNotPaused
		onlyManager
	{
		uint8 maticXFeePercent = IMaticX(maticX).feePercent();
		require(
			_feeReimbursalPercent <= maticXFeePercent,
			"_feePercent must not exceed maticX fee percent"
		);

		feeReimbursalPercent = _feeReimbursalPercent;

		emit SetFeeReimbursalPercent(_feeReimbursalPercent, block.timestamp);
	}

	function provideFeeReimbursalMatic(uint256 _amount)
		external
		override
		whenNotPaused
	{
		require(_amount > 0, "Invalid amount");
		IERC20Upgradeable(polygonERC20).safeTransferFrom(
			msg.sender,
			address(this),
			_amount
		);

		feeReimbursalPool += _amount;
		emit ProvideFeeReimbursalMatic(_amount, block.timestamp);
	}

	function getValidatedPartner(uint32 _partnerId)
		internal
		returns (Partner storage)
	{
		require(
			partners[_partnerId].walletAddress != address(0),
			"Invalid PartnerId"
		);
		return partners[_partnerId];
	}

	function registerPartner(
		address _walletAddress,
		string calldata _name,
		string calldata _website,
		bytes calldata _metadata,
		DisbursalCycleType _disbursalCycle,
		uint32 _disbursalCount,
		uint256 _pastManualRewards
	) external override whenNotPaused onlyFoundation returns (uint32) {
		require(
			partnerAddressToId[_walletAddress] == 0,
			"This partner is already registered"
		);
		require(
			_disbursalCount > 0,
			"Disbursal Count for partner delegation cannot be 0"
		);
		currentPartnerId += 1;
		uint32 _partnerId = currentPartnerId;
		partners[_partnerId] = Partner(
			_disbursalCount, //disbursalRemaining
			_disbursalCount, //disbursalCount
			uint64(block.timestamp), //registeredAt
			0, //totalMaticStaked;
			0, //totalMaticX
			_pastManualRewards, //pastManualRewards
			_walletAddress, //walletAddress;
			_name, //name
			_website, //website
			_metadata, //metadata;
			PartnerStatus.ACTIVE, //status;
			_disbursalCycle //disbursalCycle
		);
		partnerAddressToId[_walletAddress] = _partnerId;
		emit RegisterPartner(_partnerId, _walletAddress, block.timestamp);
		return _partnerId;
	}

	function changePartnerWalletAddress(
		uint32 _partnerId,
		address _newWalletAddress
	) external override onlyFoundation returns (Partner memory) {
		Partner storage _partner = getValidatedPartner(_partnerId);
		require(_newWalletAddress != address(0), "Invalid Addresses");
		require(
			partnerAddressToId[_newWalletAddress] == 0,
			"New Wallet address is already assigned to other partner"
		);
		address _oldWalletAddress = _partner.walletAddress;
		_partner.walletAddress = _newWalletAddress;
		partnerAddressToId[_newWalletAddress] = _partnerId;
		partnerAddressToId[_oldWalletAddress] = 0;

		emit ChangePartnerWalletAddress(
			_partnerId,
			_oldWalletAddress,
			_newWalletAddress,
			block.timestamp
		);
		return _partner;
	}

	function changePartnerDisbursalCount(
		uint32 _partnerId,
		uint32 _newDisbursalCount
	) external override onlyFoundation returns (Partner memory) {
		Partner memory _partner = getValidatedPartner(_partnerId);
		require(
			_newDisbursalCount != _partner.disbursalCount,
			"Nothing to change"
		);
		if (_newDisbursalCount > _partner.disbursalCount) {
			partners[_partnerId].disbursalRemaining +=
				_newDisbursalCount -
				_partner.disbursalCount;
			partners[_partnerId].disbursalCount = _newDisbursalCount;
		} else {
			require(
				_partner.disbursalCount - _newDisbursalCount <=
					_partner.disbursalRemaining,
				"Invalid Disbursal count"
			);
			partners[_partnerId].disbursalRemaining -=
				_partner.disbursalCount -
				_newDisbursalCount;
			partners[_partnerId].disbursalCount = _newDisbursalCount;
		}
		emit ChangePartnerDisbursalCount(
			_partnerId,
			_newDisbursalCount,
			block.timestamp
		);
		return _partner;
	}

	function changePartnerStatus(uint32 _partnerId, bool _isActive)
		external
		override
		whenNotPaused
		onlyFoundation
		returns (Partner memory)
	{
		Partner storage _partner = getValidatedPartner(_partnerId);
		_partner.status = _isActive
			? PartnerStatus.ACTIVE
			: PartnerStatus.INACTIVE;
		emit ChangePartnerStatus(
			_partnerId,
			_partner.walletAddress,
			_isActive,
			block.timestamp
		);
		return _partner;
	}

	function stake(uint32 _partnerId, uint256 _maticAmount)
		external
		override
		whenNotPaused
		onlyFoundation
	{
		require(_maticAmount > 0, "Invalid amount");
		Partner storage partner = getValidatedPartner(_partnerId);
		require(partner.status == PartnerStatus.ACTIVE, "Inactive Partner");
		IERC20Upgradeable(polygonERC20).safeTransferFrom(
			msg.sender,
			address(this),
			_maticAmount
		);
		IERC20Upgradeable(polygonERC20).safeApprove(maticX, _maticAmount);
		uint256 _maticXAmount = IMaticX(maticX).submit(_maticAmount);
		partner.totalMaticStaked += _maticAmount;
		partner.totalMaticX += _maticXAmount;
		emit FoundationStake(
			_partnerId,
			partner.walletAddress,
			_maticAmount,
			_maticXAmount,
			block.timestamp
		);
	}

	function unStake(uint32 _partnerId, uint256 _maticAmount)
		external
		override
		whenNotPaused
		onlyFoundation
	{
		Partner storage partner = getValidatedPartner(_partnerId);
		require(
			_maticAmount > 0 && _maticAmount <= partner.totalMaticStaked,
			"Invalid amount"
		);

		(uint256 _maticXAmount, , ) = IMaticX(maticX).convertMaticToMaticX(
			_maticAmount
		);

		IERC20Upgradeable(maticX).safeApprove(maticX, _maticXAmount);
		IMaticX(maticX).requestWithdraw(_maticXAmount);

		unstakeRequests.push(
			UnstakeRequest(
				_partnerId, // partnerId
				0, // batchId
				_maticXAmount //maticXBurned
			)
		);

		partner.totalMaticStaked -= _maticAmount;
		partner.totalMaticX -= _maticXAmount;
		emit FoundationStake(
			_partnerId,
			partner.walletAddress,
			_maticAmount,
			_maticXAmount,
			block.timestamp
		);
	}

	function withdrawUnstakedAmount(uint256 _reqIdx)
		external
		override
		whenNotPaused
		onlyFoundation
	{
		require(
			_reqIdx >= 0 && _reqIdx < unstakeRequests.length,
			"Invalid Request Index"
		);
		UnstakeRequest memory currentRequest = unstakeRequests[_reqIdx];
		require(
			currentRequest.partnerId > 0,
			"Not a foundation unstake request"
		);

		uint256 balanceBeforeClaim = IERC20Upgradeable(polygonERC20).balanceOf(
			address(this)
		);
		IMaticX(maticX).claimWithdrawal(_reqIdx);
		uint256 amountToClaim = IERC20Upgradeable(polygonERC20).balanceOf(
			address(this)
		) - balanceBeforeClaim;

		unstakeRequests[_reqIdx] = unstakeRequests[unstakeRequests.length - 1];
		unstakeRequests.pop();

		IERC20Upgradeable(polygonERC20).safeTransfer(
			_msgSender(),
			amountToClaim
		);
		emit FoundationWithdraw(_reqIdx, amountToClaim, block.timestamp);
	}

	function addDueRewardsToCurrentBatch(uint32[] calldata _partnerIds)
		external
		override
		whenNotPaused
		onlyDisbursalBot
	{
		Batch storage _currentBatch = batches[currentBatchId];
		require(
			_currentBatch.status == BatchStatus.CREATED,
			"Invalid Batch Status"
		);

		(uint256 _maticToMaticXRate, , ) = IMaticX(maticX).convertMaticToMaticX(
			10**18
		);

		for (uint32 i = 0; i < _partnerIds.length; i++) {
			uint32 _partnerId = _partnerIds[i];
			Partner storage _currentPartner = getValidatedPartner(_partnerId);

			require(
				_currentPartner.status == PartnerStatus.ACTIVE,
				"Inactive Partner"
			);

			require(
				_currentPartner.disbursalRemaining > 0,
				"No disbursals remaining for this partner"
			);

			uint256 _reward = _currentPartner.totalMaticX -
				((_currentPartner.totalMaticStaked * _maticToMaticXRate) /
					10**18);

			if (_reward == 0) continue;

			_currentPartner.totalMaticX -= _reward;

			_currentBatch.maticXBurned += _reward;
			// partner has already been visited
			if (_currentBatch.partnersShare[_partnerId].maticXUnstaked > 0) {
				_reward += _currentBatch
					.partnersShare[_partnerId]
					.maticXUnstaked;
			} else {
				partners[_partnerId].disbursalRemaining--;
			}
			_currentBatch.partnersShare[_partnerId] = PartnerUnstakeShare(
				_reward,
				0
			);

			emit UnstakePartnerReward(
				_partnerId,
				_currentPartner.walletAddress,
				currentBatchId,
				_reward,
				block.timestamp
			);
		}
	}

	function unDelegateCurrentBatch()
		external
		override
		whenNotPaused
		onlyDisbursalBot
	{
		uint32 _batchId = currentBatchId;
		Batch storage _currentBatch = batches[_batchId];
		require(
			_currentBatch.maticXBurned > 0,
			"Cannot undelegate empty batch"
		);
		require(
			_currentBatch.status == BatchStatus.CREATED,
			"Invalid Batch Status"
		);

		IERC20Upgradeable(maticX).safeApprove(
			maticX,
			_currentBatch.maticXBurned
		);
		IMaticX(maticX).requestWithdraw(_currentBatch.maticXBurned);
		uint32 _idx = uint32(unstakeRequests.length);
		IMaticX.WithdrawalRequest[] memory withdrawalRequests = IMaticX(maticX)
			.getUserWithdrawalRequests(address(this));
		uint256 _requestEpoch = withdrawalRequests[_idx].requestEpoch;
		unstakeRequests.push(
			UnstakeRequest(
				0, // partnerId
				_batchId,
				_currentBatch.maticXBurned //maticXBurned
			)
		);

		_currentBatch.undelegatedAt = uint64(block.timestamp);
		_currentBatch.withdrawalEpoch = uint64(_requestEpoch);
		_currentBatch.status = BatchStatus.UNDELEGATED;

		// create a new batch
		currentBatchId += 1;
		Batch storage _newBatch = batches[currentBatchId];
		_newBatch.createdAt = uint64(block.timestamp);
		_newBatch.status = BatchStatus.CREATED;

		emit UndelegateBatch(
			_batchId,
			_currentBatch.maticXBurned,
			block.timestamp
		);

		emit CreateBatch(currentBatchId, block.timestamp);
	}

	function getPartnerShare(uint32 _batchId, uint32 _partnerId)
		external
		view
		override
		whenNotPaused
		returns (PartnerUnstakeShare memory)
	{
		require(batches[_batchId].createdAt > 0, "Invalid Batch Id");
		return batches[_batchId].partnersShare[_partnerId];
	}

	function claimUnstakeRewards(uint32 _reqIdx)
		external
		override
		whenNotPaused
		onlyDisbursalBot
	{
		require(
			_reqIdx >= 0 && _reqIdx < unstakeRequests.length,
			"Invalid Request Index"
		);
		uint32 _batchId = unstakeRequests[_reqIdx].batchId;
		require(_batchId > 0, "Not a disbursal reward unstake request");
		Batch storage _currentBatch = batches[_batchId];
		require(
			_currentBatch.status == BatchStatus.UNDELEGATED,
			"Invalid Batch Status"
		);

		uint256 balanceBeforeClaim = IERC20Upgradeable(polygonERC20).balanceOf(
			address(this)
		);
		IMaticX(maticX).claimWithdrawal(_reqIdx);
		uint256 _maticReceived = IERC20Upgradeable(polygonERC20).balanceOf(
			address(this)
		) - balanceBeforeClaim;

		unstakeRequests[_reqIdx] = unstakeRequests[unstakeRequests.length - 1];
		unstakeRequests.pop();

		_currentBatch.maticReceived = _maticReceived;
		_currentBatch.claimedAt = uint64(block.timestamp);
		_currentBatch.status = BatchStatus.CLAIMED;
		emit ClaimBatch(_batchId, _maticReceived, block.timestamp);
	}

	function disbursePartnersReward(
		uint32 _batchId,
		uint32[] calldata _partnerIds
	) external override whenNotPaused onlyDisbursalBot {
		Batch storage _currentBatch = batches[_batchId];
		require(
			_currentBatch.status == BatchStatus.CLAIMED,
			"Batch Rewards haven't been claimed yet"
		);

		uint8 _maticXFeePercent = IMaticX(maticX).feePercent();
		uint8 _feeReimbursalPercent = feeReimbursalPercent;

		for (uint32 i = 0; i < _partnerIds.length; i++) {
			uint32 _partnerId = _partnerIds[i];
			PartnerUnstakeShare memory _partnerShare = _currentBatch
				.partnersShare[_partnerId];
			require(
				_partnerShare.maticXUnstaked > 0,
				"No Partner Share for this partnerId"
			);
			require(
				partners[_partnerId].status == PartnerStatus.ACTIVE,
				"Inactive Partner"
			);
			require(
				_partnerShare.disbursedAt == 0,
				"Partner Reward has already been disbursed"
			);
			_currentBatch.partnersShare[_partnerId].disbursedAt = uint64(
				block.timestamp
			);

			uint256 _maticShare = (_currentBatch.maticReceived *
				_partnerShare.maticXUnstaked) / _currentBatch.maticXBurned;

			uint256 _reimbursedFee = (_maticShare *
				(uint256(_feeReimbursalPercent))) /
				uint256(100 - _maticXFeePercent);

			// save the state
			require(
				feeReimbursalPool >= _reimbursedFee,
				"Not enough balance to reimburse fee"
			);
			feeReimbursalPool -= _reimbursedFee;

			// transfer rewards
			IERC20Upgradeable(polygonERC20).safeTransfer(
				partners[_partnerId].walletAddress,
				_maticShare + _reimbursedFee
			);
			emit DisbursePartnerReward(
				_partnerId,
				partners[_partnerId].walletAddress,
				_batchId,
				_maticShare + _reimbursedFee,
				_reimbursedFee,
				_partnerShare.maticXUnstaked,
				block.timestamp
			);
		}
	}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "../utils/ContextUpgradeable.sol";
import "../utils/StringsUpgradeable.sol";
import "../utils/introspection/ERC165Upgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
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
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(uint160(account), 20),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
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
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
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
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
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
        return !AddressUpgradeable.isContract(address(this));
    }
}

pragma solidity 0.8.7;

interface IPartnerStaking {
	function currentPartnerId() external view returns (uint32);

	function currentBatchId() external view returns (uint32);

	function feeReimbursalPercent() external view returns (uint8);

	function feeReimbursalPool() external view returns (uint256);

	enum DisbursalCycleType {
		WEEK,
		FORTNIGHT,
		MONTH,
		QUARTER,
		YEAR
	}
	enum PartnerStatus {
		ACTIVE,
		INACTIVE
	}
	struct Partner {
		uint32 disbursalRemaining;
		uint32 disbursalCount;
		uint64 registeredAt;
		uint256 totalMaticStaked;
		uint256 totalMaticX;
		uint256 pastManualRewards;
		address walletAddress;
		string name;
		string website;
		bytes metadata;
		PartnerStatus status;
		DisbursalCycleType disbursalCycle;
	}

	///@@dev UI needs to differentiate between foundation unstake request and partner reward unstake request for a request, _batchId > 0 -> partner reward request, _partnerId > 0 -> foundation reward request
	struct UnstakeRequest {
		uint32 partnerId;
		uint32 batchId;
		uint256 maticXBurned;
	}

	struct PartnerUnstakeShare {
		uint256 maticXUnstaked;
		uint64 disbursedAt;
	}
	enum BatchStatus {
		CREATED,
		UNDELEGATED,
		CLAIMED
	}
	struct Batch {
		uint64 createdAt;
		uint64 undelegatedAt;
		uint64 claimedAt;
		uint64 withdrawalEpoch;
		uint256 maticXBurned;
		uint256 maticReceived;
		BatchStatus status;
		mapping(uint32 => PartnerUnstakeShare) partnersShare;
	}

	//events
	event AddFoundationApprovedAddress(address _address, uint256 _timestamp);

	event RemoveFoundationApprovedAddress(address _address, uint256 _timestamp);

	event SetDisbursalBotAddress(address _address, uint256 _timestamp);

	event SetTrustedForwarder(address _address);

	event SetFeeReimbursalPercent(
		uint8 _feeReimbursalPercent,
		uint256 _timestamp
	);

	event ProvideFeeReimbursalMatic(uint256 _amount, uint256 _timestamp);

	event RegisterPartner(
		uint32 indexed _partnerId,
		address indexed _walletAddress,
		uint256 _timestamp
	);

	event ChangePartnerWalletAddress(
		uint32 indexed _partnerId,
		address indexed _oldWalletAddress,
		address indexed _newWalletAddress,
		uint256 _timestamp
	);

	event ChangePartnerDisbursalCount(
		uint32 indexed partnerId,
		uint32 _newDisbursalCount,
		uint256 _timestamp
	);

	event ChangePartnerStatus(
		uint32 indexed _partnerId,
		address indexed _partnerAddress,
		bool _isActive,
		uint256 _timestamp
	);

	event FoundationStake(
		uint32 indexed _partnerId,
		address indexed _partnerAddress,
		uint256 _maticAmount,
		uint256 _maticXMinted,
		uint256 _timestamp
	);

	event FoundationUnStake(
		uint32 indexed _partnerId,
		address indexed _partnerAddress,
		uint256 _maticAmount,
		uint256 _maticXBurned,
		uint256 _timestamp
	);

	event FoundationWithdraw(
		uint256 _reqIdx,
		uint256 _maticAmount,
		uint256 _timestamp
	);

	event CreateBatch(uint32 indexed _batchId, uint256 _timestamp);

	event UndelegateBatch(
		uint32 indexed _batchId,
		uint256 _maticXBurned,
		uint256 _timestamp
	);

	event ClaimBatch(
		uint32 indexed _batchId,
		uint256 _maticAmount,
		uint256 _timestamp
	);

	event UnstakePartnerReward(
		uint32 indexed _partnerId,
		address indexed _partnerAddress,
		uint32 indexed _batchId,
		uint256 _maticXUnstaked,
		uint256 _timestamp
	);

	event DisbursePartnerReward(
		uint32 indexed _partnerId,
		address indexed _partnerAddress,
		uint32 indexed _batchId,
		uint256 _maticDisbursed,
		uint256 _reimbursedFee,
		uint256 _maticXUsed,
		uint256 _timestamp
	);

	function addFoundationApprovedAddress(address _address) external;

	function removeFoundationApprovedAddress(address _address) external;

	function setDisbursalBotAddress(address _address) external;

	function setTrustedForwarder(address _address) external;

	function setFeeReimbursalPercent(uint8 _feeReimbursalPercent) external;

	function provideFeeReimbursalMatic(uint256 _amount) external;

	function registerPartner(
		address _walletAddress,
		string calldata _name,
		string calldata _website,
		bytes calldata _metadata,
		DisbursalCycleType _disbursalCycle,
		uint32 _totalFrequency,
		uint256 _pastManualRewards
	) external returns (uint32);

	function changePartnerWalletAddress(
		uint32 _partnerId,
		address _newWalletAddress
	) external returns (Partner memory);

	function changePartnerStatus(uint32 _partnerId, bool _isActive)
		external
		returns (Partner memory);

	function changePartnerDisbursalCount(
		uint32 _partnerId,
		uint32 _newDisbursalCount
	) external returns (Partner memory);

	function stake(uint32 _partnerId, uint256 _maticAmount) external;

	function unStake(uint32 _partnerId, uint256 _maticAmount) external;

	function withdrawUnstakedAmount(uint256 _reqIdx) external;

	function addDueRewardsToCurrentBatch(uint32[] calldata _partnerIds)
		external;

	function unDelegateCurrentBatch() external;

	function getPartnerShare(uint32 _batchId, uint32 _partnerId)
		external
		view
		returns (PartnerUnstakeShare memory);

	function claimUnstakeRewards(uint32 _reqIdx) external;

	function disbursePartnersReward(
		uint32 _batchId,
		uint32[] calldata _partnerIds
	) external;
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

import "./IValidatorShare.sol";
import "./IValidatorRegistry.sol";

/// @title MaticX interface.
interface IMaticX is IERC20Upgradeable {
	struct WithdrawalRequest {
		uint256 validatorNonce;
		uint256 requestEpoch;
		address validatorAddress;
	}

	function version() external view returns (string memory);

	function treasury() external view returns (address);

	function feePercent() external view returns (uint8);

	function instantPoolOwner() external view returns (address);

	function instantPoolMatic() external view returns (uint256);

	function instantPoolMaticX() external view returns (uint256);

	function fxStateRootTunnel() external view returns (address);

	function initialize(
		address _validatorRegistry,
		address _stakeManager,
		address _token,
		address _manager,
		address _instant_pool_manager,
		address _treasury
	) external;

	function provideInstantPoolMatic(uint256 _amount) external;

	function provideInstantPoolMaticX(uint256 _amount) external;

	function withdrawInstantPoolMaticX(uint256 _amount) external;

	function withdrawInstantPoolMatic(uint256 _amount) external;

	function mintMaticXToInstantPool() external;

	function swapMaticForMaticXViaInstantPool(uint256 _amount) external;

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

	function convertMaticXToMatic(uint256 _balance)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);

	function convertMaticToMaticX(uint256 _balance)
		external
		view
		returns (
			uint256,
			uint256,
			uint256
		);

	function mint(address _user, uint256 _amount) external;

	function setFeePercent(uint8 _feePercent) external;

	function setInstantPoolOwner(address _address) external;

	function setValidatorRegistry(address _address) external;

	function setTreasury(address _address) external;

	function setFxStateRootTunnel(address _address) external;

	function setVersion(string calldata _version) external;

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
		uint256 _amountMaticX,
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
	event MintFromPolygon(address indexed _user, uint256 _amount);
	event SetFeePercent(uint8 _feePercent);
	event SetInstantPoolOwner(address _address);
	event SetTreasury(address _address);
	event SetValidatorRegistry(address _address);
	event SetFxStateRootTunnel(address _address);
	event SetVersion(string _version);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
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
interface IERC165Upgradeable {
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

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

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

	function unbonds_new(address _address, uint256 _unbondNonce)
		external
		view
		returns (DelegatorUnbond memory);
}

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.7;

/// @title IValidatorRegistry
/// @notice Node validator registry interface
interface IValidatorRegistry {
	function addValidator(uint256 _validatorId) external;

	function removeValidator(uint256 _validatorId) external;

	function setPreferredDepositValidatorId(uint256 _validatorId) external;

	function setPreferredWithdrawalValidatorId(uint256 _validatorId) external;

	function setMaticX(address _maticX) external;

	function setVersion(string memory _version) external;

	function togglePause() external;

	function version() external view returns (string memory);

	function preferredDepositValidatorId() external view returns (uint256);

	function preferredWithdrawalValidatorId() external view returns (uint256);

	function validatorIdExists(uint256 _validatorId)
		external
		view
		returns (bool);

	function getContracts()
		external
		view
		returns (
			address _stakeManager,
			address _polygonERC20,
			address _maticX
		);

	function getValidatorId(uint256 _index) external view returns (uint256);

	function getValidators() external view returns (uint256[] memory);

	event AddValidator(uint256 indexed _validatorId);
	event RemoveValidator(uint256 indexed _validatorId);
	event SetPreferredDepositValidatorId(uint256 indexed _validatorId);
	event SetPreferredWithdrawalValidatorId(uint256 indexed _validatorId);
	event SetMaticX(address _address);
	event SetVersion(string _version);
}