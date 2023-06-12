// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IYieldSyncV1Vault } from "@yield-sync/v1-sdk/contracts/interface/IYieldSyncV1Vault.sol";

import { IYieldSyncV1VaultAccessControl } from "./interface/IYieldSyncV1VaultAccessControl.sol";


struct Access {
	bool admin;
	bool member;
}


contract YieldSyncV1VaultAccessControl is
	IYieldSyncV1VaultAccessControl
{
	mapping (address admin => address[] yieldSyncV1Vaults) internal _admin_yieldSyncV1Vaults;
	mapping (address yieldSyncV1Vault  => address[] admins) internal _yieldSyncV1Vault_admins;
	mapping (address yieldSyncV1Vault => address[] members) internal _yieldSyncV1Vault_members;
	mapping (address member => address[] yieldSyncV1Vaults) internal _member_yieldSyncV1Vaults;
	mapping (
		address participant => mapping (address yieldSyncV1Vault => Access access)
	) internal _participant_yieldSyncV1Vault_access;


	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function admin_yieldSyncV1Vaults(address admin)
		public
		view
		override
		returns (address[] memory)
	{
		return _admin_yieldSyncV1Vaults[admin];
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function yieldSyncV1Vault_admins(address yieldSyncV1Vault)
		public
		view
		override
		returns (address[] memory)
	{
		return _yieldSyncV1Vault_admins[yieldSyncV1Vault];
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function yieldSyncV1Vault_members(address yieldSyncV1Vault)
		public
		view
		override
		returns (address[] memory)
	{
		return _yieldSyncV1Vault_members[yieldSyncV1Vault];
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function member_yieldSyncV1Vaults(address member)
		public
		view
		override
		returns (address[] memory)
	{
		return _member_yieldSyncV1Vaults[member];
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function participant_yieldSyncV1Vault_access(address participant, address yieldSyncV1Vault)
		public
		view
		override
		returns (bool admin, bool member)
	{
		admin = _participant_yieldSyncV1Vault_access[participant][yieldSyncV1Vault].admin;
		member = _participant_yieldSyncV1Vault_access[participant][yieldSyncV1Vault].member;
	}


	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function addAdmin(address _yieldSyncV1Vault, address admin)
		public
		override
	{
		require(_yieldSyncV1Vault == msg.sender, "!_yieldSyncV1Vault");

		require(!_participant_yieldSyncV1Vault_access[admin][_yieldSyncV1Vault].admin, "Already admin");

		_admin_yieldSyncV1Vaults[admin].push(_yieldSyncV1Vault);

		_yieldSyncV1Vault_admins[_yieldSyncV1Vault].push(admin);

		_participant_yieldSyncV1Vault_access[admin][_yieldSyncV1Vault] = Access({
			member: _participant_yieldSyncV1Vault_access[admin][_yieldSyncV1Vault].member,
			admin: true
		});
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function removeAdmin(address _yieldSyncV1Vault, address admin)
		public
		override
	{
		require(_yieldSyncV1Vault == msg.sender, "!_yieldSyncV1VaultAddress");

		// [update] _admin_yieldSyncV1Vaults
		for (uint256 i = 0; i < _admin_yieldSyncV1Vaults[admin].length; i++)
		{
			if (_admin_yieldSyncV1Vaults[admin][i] == _yieldSyncV1Vault)
			{
				_admin_yieldSyncV1Vaults[admin][i] = _admin_yieldSyncV1Vaults[admin][
					_admin_yieldSyncV1Vaults[admin].length - 1
				];

				_admin_yieldSyncV1Vaults[admin].pop();

				break;
			}
		}

		// [update] _yieldSyncV1Vault_admins
		for (uint256 i = 0; i < _yieldSyncV1Vault_admins[_yieldSyncV1Vault].length; i++)
		{
			if (_yieldSyncV1Vault_admins[_yieldSyncV1Vault][i] == admin)
			{
				_yieldSyncV1Vault_admins[_yieldSyncV1Vault][i] = _yieldSyncV1Vault_admins[_yieldSyncV1Vault][
					_yieldSyncV1Vault_admins[_yieldSyncV1Vault].length - 1
				];

				_yieldSyncV1Vault_admins[_yieldSyncV1Vault].pop();

				break;
			}
		}

		_participant_yieldSyncV1Vault_access[admin][_yieldSyncV1Vault] = Access({
			admin: false,
			member: _participant_yieldSyncV1Vault_access[admin][_yieldSyncV1Vault].member
		});
	}


	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function addMember(address _yieldSyncV1Vault, address member)
		public
		override
	{
		require(_yieldSyncV1Vault == msg.sender, "!_yieldSyncV1Vault");

		require(!_participant_yieldSyncV1Vault_access[member][_yieldSyncV1Vault].member, "Already member");

		_member_yieldSyncV1Vaults[member].push(_yieldSyncV1Vault);

		_yieldSyncV1Vault_members[_yieldSyncV1Vault].push(member);

		_participant_yieldSyncV1Vault_access[member][_yieldSyncV1Vault] = Access({
			admin:  _participant_yieldSyncV1Vault_access[member][_yieldSyncV1Vault].admin,
			member: true
		});
	}

	/// @inheritdoc IYieldSyncV1VaultAccessControl
	function removeMember(address _yieldSyncV1Vault, address member)
		public
		override
	{
		require(_yieldSyncV1Vault == msg.sender, "!_yieldSyncV1VaultAddress");

		// [update] _member_yieldSyncV1Vaults
		for (uint256 i = 0; i < _member_yieldSyncV1Vaults[member].length; i++)
		{
			if (_member_yieldSyncV1Vaults[member][i] == _yieldSyncV1Vault)
			{
				_member_yieldSyncV1Vaults[member][i] = _member_yieldSyncV1Vaults[member][
					_member_yieldSyncV1Vaults[member].length - 1
				];

				_member_yieldSyncV1Vaults[member].pop();

				break;
			}
		}

		// [update] _yieldSyncV1Vault_members
		for (uint256 i = 0; i < _yieldSyncV1Vault_members[_yieldSyncV1Vault].length; i++)
		{
			if (_yieldSyncV1Vault_members[_yieldSyncV1Vault][i] == member)
			{
				_yieldSyncV1Vault_members[_yieldSyncV1Vault][i] = _yieldSyncV1Vault_members[_yieldSyncV1Vault][
					_yieldSyncV1Vault_members[_yieldSyncV1Vault].length - 1
				];

				_yieldSyncV1Vault_members[_yieldSyncV1Vault].pop();

				break;
			}
		}

		_participant_yieldSyncV1Vault_access[member][_yieldSyncV1Vault] = Access({
			admin: _participant_yieldSyncV1Vault_access[member][_yieldSyncV1Vault].admin,
			member: false
		});
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
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";
import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";


struct TransferRequest {
	bool forERC20;
	bool forERC721;
	address creator;
	address token;
	uint256 tokenId;
	uint256 amount;
	address to;
	uint256 forVoteCount;
	uint256 againstVoteCount;
	uint256 latestRelevantForVoteTime;
	address[] votedVoters;
}


/**
* @title IYieldSyncV1Vault
*/
interface IYieldSyncV1Vault is
	IAccessControlEnumerable,
	IERC1271
{
	event CreatedTransferRequest(uint256 transferRequestId);
	event DeletedTransferRequest(uint256 transferRequestId);
	event TokensTransferred(address indexed to, address indexed token, uint256 amount);
	event UpdatedAgainstVoteCountRequired(uint256 againstVoteCountRequired);
	event UpdatedForVoteCountRequired(uint256 forVoteCountRequired);
	event UpdatedSignatureManger(address signatureManager);
	event UpdatedTransferDelaySeconds(uint256 transferDelaySeconds);
	event UpdatedTransferRequest(TransferRequest transferRequest);
	event MemberVoted(uint256 transferRequestId, address indexed member, bool vote);
	event TransferRequestReadyToBeProcessed(uint256 transferRequestId);
	event ProcessTransferRequestFailed(uint256 transferRequestId);


	receive ()
		external
		payable
	;

	fallback ()
		external
		payable
	;


	/**
	* @notice YieldSyncV1Vault Contract Address
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function YieldSyncV1VaultRecord()
		external
		view
		returns (address)
	;

	/**
	* @notice signatureManager Contract Address
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function signatureManager()
		external
		view
		returns (address)
	;

	/**
	* @notice Against Vote Count Required
	* @dev [!restriction]
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function againstVoteCountRequired()
		external
		view
		returns (uint256)
	;

	/**
	* @notice For Vote Count Required
	* @dev [!restriction]
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function forVoteCountRequired()
		external
		view
		returns (uint256)
	;

	/**
	* @notice Transfer Delay In Seconds
	* @dev [!restriction]
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function transferDelaySeconds()
		external
		view
		returns (uint256)
	;


	/**
	* @notice Ids of Open transferRequests
	* @dev [!restriction]
	* @dev [view-uint256[]]
	* @return {uint256[]}
	*/
	function idsOfOpenTransferRequests()
		external
		view
		returns (uint256[] memory)
	;

	/**
	* @notice transferRequestId to transferRequest
	* @dev [!restriction]
	* @dev [view][mapping]
	* @param transferRequestId {uint256}
	* @return {TransferRequest}
	*/
	function transferRequestId_transferRequest(uint256 transferRequestId)
		external
		view returns (TransferRequest memory)
	;


	/**
	* @notice Add Admin
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [add] admin on `YieldSyncV1Record`
	* @param targetAddress {address}
	*/
	function addAdmin(address targetAddress)
		external
	;

	/**
	* @notice Remove Admin
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [remove] admin on `YieldSyncV1Record`
	* @param admin {address}
	*/
	function removeAdmin(address admin)
		external
	;

	/**
	* @notice Add Member
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [add] member `YieldSyncV1Record`
	* @param targetAddress {address}
	*/
	function addMember(address targetAddress)
		external
	;

	/**
	* @notice Remove Member
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [remove] member on `YieldSyncV1Record`
	* @param member {address}
	*/
	function removeMember(address member)
		external
	;

	/**
	* @notice Delete transferRequest & all associated values
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [call][internal] {_deleteTransferRequest}
	* @param transferRequestId {uint256}
	* Emits: `DeletedTransferRequest`
	*/
	function deleteTransferRequest(uint256 transferRequestId)
		external
	;

	/**
	* @notice Update transferRequest
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `_transferRequest`
	* @param transferRequestId {uint256}
	* @param __transferRequest {TransferRequest}
	* Emits: `UpdatedTransferRequest`
	*/
	function updateTransferRequest(uint256 transferRequestId, TransferRequest memory __transferRequest)
		external
	;

	/**
	* @notice Update Against Vote Count Required
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `againstVoteCountRequired`
	* @param _againstVoteCountRequired {uint256}
	* Emits: `UpdatedAgainstVoteCountRequired`
	*/
	function updateAgainstVoteCountRequired(uint256 _againstVoteCountRequired)
		external
	;

	/**
	* @notice Update For Vote Count Required
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `forVoteCountRequired`
	* @param _forVoteCountRequired {uint256}
	* Emits: `UpdatedRequiredVoteCount`
	*/
	function updateForVoteCountRequired(uint256 _forVoteCountRequired)
		external
	;

	/**
	* @notice Update Signature Manager Contract
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `signatureManager`
	* @param _signatureManager {address}
	*/
	function updateSignatureManager(address _signatureManager)
		external
	;

	/**
	* @notice Update `transferDelaySeconds`
	* @dev [restriction] `YieldSyncV1Record` → admin
	* @dev [update] `transferDelaySeconds` to new value
	* @param _transferDelaySeconds {uint256}
	* Emits: `UpdatedTransferDelaySeconds`
	*/
	function updateTransferDelaySeconds(uint256 _transferDelaySeconds)
		external
	;


	/**
	* @notice Create a transferRequest
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [increment] `_transferRequestId`
	*      [add] `_transferRequest` value
	*      [push-into] `_transferRequestIds`
	* @param forEther {bool}
	* @param forERC20 {bool}
	* @param forERC721 {bool}
	* @param to {address}
	* @param tokenAddress {address} Token contract
	* @param amount {uint256}
	* @param tokenId {uint256} ERC721 token id
	* Emits: `CreatedTransferRequest`
	*/
	function createTransferRequest(
		bool forEther,
		bool forERC20,
		bool forERC721,
		address to,
		address tokenAddress,
		uint256 amount,
		uint256 tokenId
	)
		external
	;

	/**
	* @notice Vote on transferRequest
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [update] `_transferRequest`
	* @param transferRequestId {uint256}
	* @param vote {bool} true (approve) or false (deny)
	* Emits: `TransferRequestReadyToBeProcessed`
	* Emits: `MemberVoted`
	*/
	function voteOnTransferRequest(uint256 transferRequestId, bool vote)
		external
	;

	/**
	* @notice Process transferRequest with given `transferRequestId`
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [erc20-transfer]
	*      [decrement] `_tokenBalance`
	*      [call][internal] `_deleteTransferRequest`
	* @param transferRequestId {uint256} Id of the TransferRequest
	* Emits: `TokensWithdrawn`
	*/
	function processTransferRequest(uint256 transferRequestId)
		external
	;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


interface IYieldSyncV1VaultAccessControl
{
	/**
	* @notice
	* @dev [!restriction]
	* @dev [view]
	* @param admin {address}
	* @return {address[]}
	*/
	function admin_yieldSyncV1Vaults(address admin)
		external
		view
		returns (address[] memory)
	;

	/**
	* @notice Getter for `_yieldSyncV1Vault_admins`
	* @dev [!restriction]
	* @dev [view]
	* @param yieldSyncV1Vault {address}
	* @return {address[]}
	*/
	function yieldSyncV1Vault_admins(address yieldSyncV1Vault)
		external
		view
		returns (address[] memory)
	;

	/**
	* @notice Getter for `_yieldSyncV1Vault_members`
	* @dev [!restriction]
	* @dev [view]
	* @param yieldSyncV1Vault {address}
	* @return {address[]}
	*/
	function yieldSyncV1Vault_members(address yieldSyncV1Vault)
		external
		view
		returns (address[] memory)
	;

	/**
	* @notice Getter for `_member_yieldSyncV1Vaults`
	* @dev [!restriction]
	* @dev [view]
	* @param member {address}
	* @return {address[]}
	*/
	function member_yieldSyncV1Vaults(address member)
		external
		view
		returns (address[] memory)
	;

	/**
	* @notice Getter for `_participant_yieldSyncV1Vault_access`
	* @dev [!restriction]
	* @dev [view]
	* @param participant {address}
	* @param yieldSyncV1Vault {address}
	* @return admin {bool}
	* @return member {bool}
	*/
	function participant_yieldSyncV1Vault_access(address participant, address yieldSyncV1Vault)
		external
		view
		returns (bool admin, bool member)
	;


	/**
	* @notice Add Admin
	* @dev [!restriction]
	* @dev [update] `_admin_yieldSyncV1Vaults`
	*      [update] `_yieldSyncV1Vault_admins`
	*      [update] `participant_yieldSyncV1Vault_access`
	* @param _yieldSyncV1Vault {address}
	* @param admin {address}
	*/
	function addAdmin(address _yieldSyncV1Vault, address admin)
		external
	;

	/**
	* @notice Remove Admin
	* @dev [!restriction]
	* @dev [update] `_admin_yieldSyncV1Vaults`
	*      [update] `_yieldSyncV1Vault_admins`
	*      [update] `participant_yieldSyncV1Vault_access`
	* @param _yieldSyncV1Vault {address}
	* @param admin {address}
	*/
	function removeAdmin(address _yieldSyncV1Vault, address admin)
		external
	;


	/**
	* @notice Add Member
	* @dev [!restriction]
	* @dev [update] `_member_yieldSyncV1Vaults`
	*      [update] `_yieldSyncV1Vault_members`
	*      [update] `participant_yieldSyncV1Vault_access`
	* @param _yieldSyncV1Vault {address}
	* @param member {address}
	*/
	function addMember(address _yieldSyncV1Vault, address member)
		external
	;

	/**
	* @notice Remove Member
	* @dev [!restriction]
	* @dev [update] `_member_yieldSyncV1Vaults`
	*      [update] `_yieldSyncV1Vault_members`
	*      [update] `participant_yieldSyncV1Vault_access`
	* @param _yieldSyncV1Vault {address}
	* @param member {address}
	*/
	function removeMember(address _yieldSyncV1Vault, address member)
		external
	;
}