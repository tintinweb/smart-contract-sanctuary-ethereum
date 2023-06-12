// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IAccessControlEnumerable } from "@openzeppelin/contracts/access/IAccessControlEnumerable.sol";

import { YieldSyncV1Vault } from "./YieldSyncV1Vault.sol";
import { IYieldSyncV1VaultFactory } from "./interface/IYieldSyncV1VaultFactory.sol";


contract YieldSyncV1VaultFactory is
	IYieldSyncV1VaultFactory
{
	receive ()
		external
		payable
		override
	{}


	fallback ()
		external
		payable
		override
	{}


	address public override immutable YieldSyncGovernance;
	address public override immutable YieldSyncV1VaultAccessControl;
	address public override defaultSignatureManager;

	bool public override transferEtherLocked;

	uint256 public override fee;
	uint256 public override yieldSyncV1VaultIdTracker;

	mapping (
		address yieldSyncV1VaultAddress => uint256 yieldSyncV1VaultId
	) public override yieldSyncV1VaultAddress_yieldSyncV1VaultId;
	mapping (
		uint256 yieldSyncV1VaultId => address yieldSyncV1VaultAddress
	) public override yieldSyncV1VaultId_yieldSyncV1VaultAddress;


	constructor (address _YieldSyncGovernance, address _YieldSyncV1VaultAccessControl)
	{
		YieldSyncGovernance = _YieldSyncGovernance;
		YieldSyncV1VaultAccessControl = _YieldSyncV1VaultAccessControl;

		transferEtherLocked = false;

		fee = 0;
		yieldSyncV1VaultIdTracker = 0;
	}


	modifier only_YieldSyncGovernance_DEFAULT_ADMIN_ROLE()
	{
		require(IAccessControlEnumerable(YieldSyncGovernance).hasRole(bytes32(0), msg.sender), "!auth");

		_;
	}


	/// @inheritdoc IYieldSyncV1VaultFactory
	function deployYieldSyncV1Vault(
		address[] memory admins,
		address[] memory members,
		address signatureManager,
		bool useDefaultSignatureManager,
		uint256 againstVoteCountRequired,
		uint256 forVoteCountRequired,
		uint256 transferDelaySeconds
	)
		public
		payable
		override
		returns (address)
	{
		require(msg.value >= fee, "!msg.value");

		YieldSyncV1Vault deployedContract = new YieldSyncV1Vault(
			YieldSyncV1VaultAccessControl,
			admins,
			members,
			useDefaultSignatureManager ? defaultSignatureManager : signatureManager,
			againstVoteCountRequired,
			forVoteCountRequired,
			transferDelaySeconds
		);

		yieldSyncV1VaultAddress_yieldSyncV1VaultId[address(deployedContract)] = yieldSyncV1VaultIdTracker;
		yieldSyncV1VaultId_yieldSyncV1VaultAddress[yieldSyncV1VaultIdTracker] = address(deployedContract);

		yieldSyncV1VaultIdTracker++;

		emit DeployedYieldSyncV1Vault(address(deployedContract));

		return address(deployedContract);
	}


	/// @inheritdoc IYieldSyncV1VaultFactory
	function updateDefaultSignatureManager(address _defaultSignatureManager)
		public
		override
		only_YieldSyncGovernance_DEFAULT_ADMIN_ROLE()
	{
		defaultSignatureManager = _defaultSignatureManager;
	}

	/// @inheritdoc IYieldSyncV1VaultFactory
	function updateFee(uint256 _fee)
		public
		override
		only_YieldSyncGovernance_DEFAULT_ADMIN_ROLE()
	{
		fee = _fee;
	}

	/// @inheritdoc IYieldSyncV1VaultFactory
	function transferEther(address to)
		public
		override
		only_YieldSyncGovernance_DEFAULT_ADMIN_ROLE()
	{
		require(!transferEtherLocked, "transferEtherLocked");

		transferEtherLocked = true;

		// [transfer]
		(bool success, ) = to.call{value: address(this).balance}("");

		transferEtherLocked = false;

		require(success, "Failed");
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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
pragma solidity ^0.8.18;


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
	address[] votedMembers;
}


interface IYieldSyncV1Vault
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
	function YieldSyncV1VaultAccessControl()
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
	* @notice Process TransferRequest Locked
	* @dev [!restriction]
	* @dev [view-bool]
	* @return {bool}
	*/
	function processTransferRequestLocked()
		external
		view
		returns (bool)
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
	* @param forERC20 {bool}
	* @param forERC721 {bool}
	* @param to {address}
	* @param tokenAddress {address} Token contract
	* @param amount {uint256}
	* @param tokenId {uint256} ERC721 token id
	* Emits: `CreatedTransferRequest`
	*/
	function createTransferRequest(
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
	* Emits: `TokensTransferred`
	*/
	function processTransferRequest(uint256 transferRequestId)
		external
	;

	/**
	* @notice Renounce Membership
	* @dev [restriction] `YieldSyncV1Record` → member
	* @dev [remove] member on `YieldSyncV1Record`
	*/
	function renounceMembership()
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


interface IYieldSyncV1VaultFactory {
	event DeployedYieldSyncV1Vault(address indexed vaultAddress);


	receive ()
		external
		payable
	;


	fallback ()
		external
		payable
	;


	/**
	* @notice YieldSyncGovernance Contract Address
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function YieldSyncGovernance()
		external
		view
		returns (address)
	;

	/**
	* @notice YieldSyncV1VaultAccessControl Contract Address
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function YieldSyncV1VaultAccessControl()
		external
		view
		returns (address)
	;

	/**
	* @notice Default SignatureManager Contract Address
	* @dev [!restriction]
	* @dev [view-address]
	* @return {address}
	*/
	function defaultSignatureManager()
		external
		view
		returns (address)
	;

	/**
	* @notice Transfer Ether Locked
	* @dev [!restriction]
	* @dev [view-bool]
	* @return {bool}
	*/
	function transferEtherLocked()
		external
		view
		returns (bool)
	;

	/**
	* @notice Fee
	* @dev [!restriction]
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function fee()
		external
		view
		returns (uint256)
	;

	/**
	* @notice yieldSyncV1Vault Id Tracker
	* @dev [!restriction]
	* @dev [view-uint256]
	* @return {uint256}
	*/
	function yieldSyncV1VaultIdTracker()
		external
		view
		returns (uint256)
	;

	/**
	* @notice yieldSyncV1VaultAddress to yieldSyncV1VaultId
	* @dev [!restriction]
	* @dev [view-mapping]
	* @param yieldSyncV1VaultAddress {address}
	* @return {uint256}
	*/
	function yieldSyncV1VaultAddress_yieldSyncV1VaultId(address yieldSyncV1VaultAddress)
		external
		view
		returns (uint256)
	;

	/**
	* @notice yieldSyncV1VaultId to yieldSyncV1VaultAddress
	* @dev [!restriction]
	* @dev [view-mapping]
	* @param yieldSyncV1VaultId {uint256}
	* @return {address}
	*/
	function yieldSyncV1VaultId_yieldSyncV1VaultAddress(uint256 yieldSyncV1VaultId)
		external
		view
		returns (address)
	;

	/**
	* @notice Creates a Vault
	* @dev [!restriction]
	* @dev [create]
	* @param admins {address[]}
	* @param members {address[]}
	* @param signatureManager {address}
	* @param againstVoteCountRequired {uint256}
	* @param forVoteCountRequired {uint256}
	* @param transferDelaySeconds {uint256}
	* @return {address} Deployed vault
	*/
	function deployYieldSyncV1Vault(
		address[] memory admins,
		address[] memory members,
		address signatureManager,
		bool useDefaultSignatureManager,
		uint256 againstVoteCountRequired,
		uint256 forVoteCountRequired,
		uint256 transferDelaySeconds
	)
		external
		payable
		returns (address)
	;

	/**
	* @notice Updates default signature manager
	* @dev [restriction] `IYieldSyncGovernance` AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `defaultSignatureManager`
	* @param _defaultSignatureManager {address}
	*/
	function updateDefaultSignatureManager(address _defaultSignatureManager)
		external
	;

	/**
	* @notice Update fee
	* @dev [restriction] `IYieldSyncGovernance` AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [update] `fee`
	* @param _fee {uint256}
	*/
	function updateFee(uint256 _fee)
		external
	;

	/**
	* @notice Transfer Ether to
	* @dev [restriction] `IYieldSyncGovernance` AccessControlEnumerable → DEFAULT_ADMIN_ROLE
	* @dev [transfer]
	* @param to {uint256}
	*/
	function transferEther(address to)
		external
	;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import { IERC1271 } from "@openzeppelin/contracts/interfaces/IERC1271.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

import { IYieldSyncV1Vault, TransferRequest } from "./interface/IYieldSyncV1Vault.sol";
import { IYieldSyncV1VaultAccessControl } from "./interface/IYieldSyncV1VaultAccessControl.sol";


contract YieldSyncV1Vault is
	IERC1271,
	IYieldSyncV1Vault
{
	receive ()
		external
		payable
		override
	{}


	fallback ()
		external
		payable
		override
	{}


	address public override immutable YieldSyncV1VaultAccessControl;
	address public override signatureManager;

	bool public override processTransferRequestLocked;

	uint256 public override againstVoteCountRequired;
	uint256 public override forVoteCountRequired;
	uint256 public override transferDelaySeconds;
	uint256 internal _transferRequestIdTracker;
	uint256[] internal _idsOfOpenTransferRequests;

	mapping (
		uint256 transferRequestId => TransferRequest transferRequest
	) internal _transferRequestId_transferRequest;


	constructor (
		address _YieldSyncV1VaultAccessControl,
		address[] memory admins,
		address[] memory members,
		address _signatureManager,
		uint256 _againstVoteCountRequired,
		uint256 _forVoteCountRequired,
		uint256 _transferDelaySeconds
	)
	{
		YieldSyncV1VaultAccessControl = _YieldSyncV1VaultAccessControl;

		require(_forVoteCountRequired > 0, "!_forVoteCountRequired");

		for (uint i = 0; i < admins.length; i++)
		{
			IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addAdmin(address(this), admins[i]);
		}

		for (uint i = 0; i < members.length; i++)
		{
			IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addMember(address(this), members[i]);
		}

		signatureManager = _signatureManager;
		processTransferRequestLocked = false;
		againstVoteCountRequired = _againstVoteCountRequired;
		forVoteCountRequired = _forVoteCountRequired;
		transferDelaySeconds = _transferDelaySeconds;

		_transferRequestIdTracker = 0;
	}


	modifier validTransferRequest(uint256 transferRequestId)
	{
		require(
			_transferRequestId_transferRequest[transferRequestId].amount > 0,
			"No TransferRequest found"
		);

		_;
	}

	modifier onlyAdmin()
	{
		(bool admin,) = IYieldSyncV1VaultAccessControl(
			YieldSyncV1VaultAccessControl
		).participant_yieldSyncV1Vault_access(msg.sender, address(this));

		require(admin, "!admin");

		_;
	}

	modifier onlyMember()
	{
		(, bool member) = IYieldSyncV1VaultAccessControl(
			YieldSyncV1VaultAccessControl
		).participant_yieldSyncV1Vault_access(msg.sender, address(this));

		require(member, "!member");

		_;
	}


	/**
	* @notice Delete TransferRequest
	* @dev [restriction][internal]
	* @dev [delete] `_transferRequestId_transferRequest` value
	*      [delete] `_idsOfOpenTransferRequests` value
	* @param transferRequestId {uint256}
	* Emits: `DeletedTransferRequest`
	*/
	function _deleteTransferRequest(uint256 transferRequestId)
		internal
	{
		delete _transferRequestId_transferRequest[transferRequestId];

		for (uint256 i = 0; i < _idsOfOpenTransferRequests.length; i++)
		{
			if (_idsOfOpenTransferRequests[i] == transferRequestId)
			{
				_idsOfOpenTransferRequests[i] = _idsOfOpenTransferRequests[_idsOfOpenTransferRequests.length - 1];

				_idsOfOpenTransferRequests.pop();

				break;
			}
		}
	}


	/// @inheritdoc IERC1271
	function isValidSignature(bytes32 _messageHash, bytes memory _signature)
		public
		view
		override
		returns (bytes4 magicValue)
	{
		return IERC1271(signatureManager).isValidSignature(_messageHash, _signature);
	}


	/// @inheritdoc IYieldSyncV1Vault
	function idsOfOpenTransferRequests()
		public
		view
		override
		returns (uint256[] memory)
	{
		return _idsOfOpenTransferRequests;
	}

	/// @inheritdoc IYieldSyncV1Vault
	function transferRequestId_transferRequest(uint256 transferRequestId)
		public
		view
		override
		validTransferRequest(transferRequestId)
		returns (TransferRequest memory)
	{
		return _transferRequestId_transferRequest[transferRequestId];
	}


	/// @inheritdoc IYieldSyncV1Vault
	function addAdmin(address targetAddress)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addAdmin(address(this), targetAddress);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function removeAdmin(address admin)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).removeAdmin(address(this), admin);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function addMember(address targetAddress)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).addMember(address(this), targetAddress);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function removeMember(address member)
		public
		override
		onlyAdmin()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).removeMember(address(this), member);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function deleteTransferRequest(uint256 transferRequestId)
		public
		override
		onlyAdmin()
		validTransferRequest(transferRequestId)
	{
		_deleteTransferRequest(transferRequestId);

		emit DeletedTransferRequest(transferRequestId);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateTransferRequest(uint256 transferRequestId, TransferRequest memory __transferRequest)
		public
		override
		onlyAdmin()
		validTransferRequest(transferRequestId)
	{
		_transferRequestId_transferRequest[transferRequestId] = __transferRequest;

		emit UpdatedTransferRequest(__transferRequest);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateAgainstVoteCountRequired(uint256 _againstVoteCountRequired)
		public
		override
		onlyAdmin()
	{
		require(_againstVoteCountRequired > 0, "!_againstVoteCountRequired");

		againstVoteCountRequired = _againstVoteCountRequired;

		emit UpdatedAgainstVoteCountRequired(againstVoteCountRequired);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateForVoteCountRequired(uint256 _forVoteCountRequired)
		public
		override
		onlyAdmin()
	{
		require(_forVoteCountRequired > 0, "!_forVoteCountRequired");

		forVoteCountRequired = _forVoteCountRequired;

		emit UpdatedForVoteCountRequired(forVoteCountRequired);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateSignatureManager(address _signatureManager)
		public
		override
		onlyAdmin()
	{
		signatureManager = _signatureManager;

		emit UpdatedSignatureManger(signatureManager);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function updateTransferDelaySeconds(uint256 _transferDelaySeconds)
		public
		override
		onlyAdmin()
	{
		require(_transferDelaySeconds >= 0, "!_transferDelaySeconds");

		transferDelaySeconds = _transferDelaySeconds;

		emit UpdatedTransferDelaySeconds(transferDelaySeconds);
	}


	/// @inheritdoc IYieldSyncV1Vault
	function createTransferRequest(
		bool forERC20,
		bool forERC721,
		address to,
		address tokenAddress,
		uint256 amount,
		uint256 tokenId
	)
		public
		override
		onlyMember()
	{
		require(amount > 0, "!amount");

		address[] memory initialVotedMembers;

		_transferRequestId_transferRequest[_transferRequestIdTracker] = TransferRequest(
			{
				forERC20: forERC20,
				forERC721: forERC721,
				creator: msg.sender,
				token: tokenAddress,
				tokenId: tokenId,
				amount: amount,
				to: to,
				forVoteCount: 0,
				againstVoteCount: 0,
				latestRelevantForVoteTime: block.timestamp,
				votedMembers: initialVotedMembers
			}
		);

		_idsOfOpenTransferRequests.push(_transferRequestIdTracker);

		_transferRequestIdTracker++;

		emit CreatedTransferRequest(_transferRequestIdTracker - 1);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function voteOnTransferRequest(uint256 transferRequestId, bool vote)
		public
		override
		onlyMember()
		validTransferRequest(transferRequestId)
	{
		require(
			_transferRequestId_transferRequest[transferRequestId].forVoteCount < forVoteCountRequired &&
			_transferRequestId_transferRequest[transferRequestId].againstVoteCount < againstVoteCountRequired,
			"Voting closed"
		);

		for (uint256 i = 0; i < _transferRequestId_transferRequest[transferRequestId].votedMembers.length; i++)
		{
			require(
				_transferRequestId_transferRequest[transferRequestId].votedMembers[i] != msg.sender,
				"Already voted"
			);
		}

		if (vote)
		{
			_transferRequestId_transferRequest[transferRequestId].forVoteCount++;
		}
		else
		{
			_transferRequestId_transferRequest[transferRequestId].againstVoteCount++;
		}

		if (
			_transferRequestId_transferRequest[transferRequestId].forVoteCount >= forVoteCountRequired ||
			_transferRequestId_transferRequest[transferRequestId].againstVoteCount >= againstVoteCountRequired
		)
		{
			emit TransferRequestReadyToBeProcessed(transferRequestId);
		}

		_transferRequestId_transferRequest[transferRequestId].votedMembers.push(msg.sender);

		if (_transferRequestId_transferRequest[transferRequestId].forVoteCount < forVoteCountRequired)
		{
			_transferRequestId_transferRequest[transferRequestId].latestRelevantForVoteTime = block.timestamp;
		}

		emit MemberVoted(transferRequestId, msg.sender, vote);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function processTransferRequest(uint256 transferRequestId)
		public
		override
		onlyMember()
		validTransferRequest(transferRequestId)
	{
		require(!processTransferRequestLocked, "processTransferRequestLocked");
		require(
			_transferRequestId_transferRequest[transferRequestId].forVoteCount >= forVoteCountRequired ||
			_transferRequestId_transferRequest[transferRequestId].againstVoteCount >= againstVoteCountRequired,
			"!forVoteCountRequired && !againstVoteCount"
		);

		processTransferRequestLocked = true;

		if (_transferRequestId_transferRequest[transferRequestId].forVoteCount >= forVoteCountRequired)
		{
			require(
				block.timestamp - _transferRequestId_transferRequest[
					transferRequestId
				].latestRelevantForVoteTime >= transferDelaySeconds * 1 seconds,
				"Not enough time has passed"
			);

			if (
				_transferRequestId_transferRequest[transferRequestId].forERC20 &&
				!_transferRequestId_transferRequest[transferRequestId].forERC721
			)
			{
				if (
					IERC20(_transferRequestId_transferRequest[transferRequestId].token).balanceOf(address(this)) >=
					_transferRequestId_transferRequest[transferRequestId].amount
				)
				{
					// [ERC20-transfer]
					IERC20(_transferRequestId_transferRequest[transferRequestId].token).transfer(
						_transferRequestId_transferRequest[transferRequestId].to,
						_transferRequestId_transferRequest[transferRequestId].amount
					);
				}
				else
				{
					emit ProcessTransferRequestFailed(transferRequestId);
				}
			}

			if (
				!_transferRequestId_transferRequest[transferRequestId].forERC20 &&
				_transferRequestId_transferRequest[transferRequestId].forERC721
			)
			{
				if (
					IERC721(_transferRequestId_transferRequest[transferRequestId].token).ownerOf(
						_transferRequestId_transferRequest[transferRequestId].tokenId
					) == address(this)
				)
				{
					// [ERC721-transfer]
					IERC721(_transferRequestId_transferRequest[transferRequestId].token).transferFrom(
						address(this),
						_transferRequestId_transferRequest[transferRequestId].to,
						_transferRequestId_transferRequest[transferRequestId].tokenId
					);
				}
				else
				{
					emit ProcessTransferRequestFailed(transferRequestId);
				}
			}

			if (
				!_transferRequestId_transferRequest[transferRequestId].forERC20 &&
				!_transferRequestId_transferRequest[transferRequestId].forERC721
			)
			{
				// [transfer]
				(bool success, ) = _transferRequestId_transferRequest[transferRequestId].to.call{
					value: _transferRequestId_transferRequest[transferRequestId].amount
				}("");

				if (!success)
				{
					emit ProcessTransferRequestFailed(transferRequestId);
				}
			}

			emit TokensTransferred(
				msg.sender,
				_transferRequestId_transferRequest[transferRequestId].to,
				_transferRequestId_transferRequest[transferRequestId].amount
			);
		}

		processTransferRequestLocked = false;

		_deleteTransferRequest(transferRequestId);
	}

	/// @inheritdoc IYieldSyncV1Vault
	function renounceMembership()
		public
		override
		onlyMember()
	{
		IYieldSyncV1VaultAccessControl(YieldSyncV1VaultAccessControl).removeMember(address(this), msg.sender);
	}
}