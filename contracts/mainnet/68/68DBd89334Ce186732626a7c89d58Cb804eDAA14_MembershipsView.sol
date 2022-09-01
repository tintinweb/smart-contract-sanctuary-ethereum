// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.7;
// @dev: based on https://github.com/abdelhamidbakhta/token-vesting-contracts/blob/main/contracts/TokenVesting.sol

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./EternalStorage.sol";
import "./MembershipsTypes.sol";

contract MembershipsView is MembershipsTypes {
	EternalStorage private _eternalStorage;

	constructor(address eternalStorage) {
		_eternalStorage = EternalStorage(eternalStorage);
	}

	function getCampaignsLength() external view returns (uint256) {
		return _eternalStorage.getCampaignsLength();
	}

	function getCampaign(uint256 index)
		external
		view
		returns (Campaign memory)
	{
		return _eternalStorage.getCampaign(index);
	}

	function getCampaignBySchedule(bytes32 schedule)
		external
		view
		returns (ScheduleCampaign memory)
	{
		(
			bytes32 campaignId,
			uint256 campaignIndex,
			uint256 scheduleIndex
		) = _eternalStorage.scheduleToCampaign(schedule);
		return ScheduleCampaign(campaignId, campaignIndex, scheduleIndex);
	}

	function getCampaignByOwner(address owner)
		external
		view
		returns (uint256, Campaign[] memory)
	{
		uint256 campaignsByOwnerLength = _eternalStorage
			.getCampaignByAddressLength(owner);
		Campaign[] memory campaigns = new Campaign[](campaignsByOwnerLength);

		uint256 length = 0;
		for (uint256 i = 0; i < campaignsByOwnerLength; i++) {
			(
				uint256 campaignIndex,
				MembershipsTypes.UserType userType
			) = _eternalStorage.campaignsByAddress(owner, i);
			if (userType == MembershipsTypes.UserType.OWNER) {
				Campaign memory c = _eternalStorage.getCampaign(campaignIndex);
				campaigns[length++] = c;
			}
		}
		return (length, campaigns);
	}

	function getCampaignByReferral(address referral)
		external
		view
		returns (uint256, Campaign[] memory)
	{
		uint256 campaignsByAddressLength = _eternalStorage
			.getCampaignByAddressLength(referral);
		Campaign[] memory campaigns = new Campaign[](campaignsByAddressLength);

		uint256 length = 0;
		for (uint256 i = 0; i < campaignsByAddressLength; i++) {
			(
				uint256 campaignIndex,
				MembershipsTypes.UserType userType
			) = _eternalStorage.campaignsByAddress(referral, i);
			if (userType == MembershipsTypes.UserType.REFERRAL) {
				Campaign memory c = _eternalStorage.getCampaign(campaignIndex);
				campaigns[length++] = c;
			}
		}
		return (length, campaigns);
	}

	function getSchedule(bytes32 scheduleId)
		external
		view
		returns (MintingSchedule memory)
	{
		return _eternalStorage.getSchedule(scheduleId);
	}

	function getReferral(bytes32 record)
		external
		view
		returns (ScheduleReferral memory)
	{
		return _eternalStorage.getReferral(record);
	}

	function getBuyWalletCount(bytes32 record) external view returns (uint256) {
		return _eternalStorage.getBuyWalletCount(record);
	}

	function getClaimed(bytes32 scheduleID, UserType userType)
		external
		view
		returns (uint256)
	{
		return _eternalStorage.getClaimed(scheduleID, userType);
	}

	function getBuyPerWallet(bytes32 scheduleId, address addr)
		public
		view
		returns (uint256)
	{
		return _eternalStorage.getBuyPerWallet(scheduleId, addr);
	}

	function getTokensAllowed() public view returns (address[] memory) {
		return _eternalStorage.getTokensAllowed();
	}

	function getCampaignMetadata(bytes32 campaignId)
		public
		view
		returns (string memory)
	{
		return _eternalStorage.getCampaignMetadata(campaignId);
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