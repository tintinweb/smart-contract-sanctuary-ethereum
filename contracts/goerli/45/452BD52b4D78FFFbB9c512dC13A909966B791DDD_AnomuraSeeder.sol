// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721MetadataUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

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
        _checkRole(role);
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
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     *
     * May emit a {RoleRevoked} event.
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
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleGranted} event.
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
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

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
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AutomationCompatibleInterface.sol";

import {AccessControlEnumerable, IAccessControlEnumerable} from "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import {LicenseVersion, CantBeEvil} from "./CantBeEvil.sol";
import {IAnomuraEquipment} from "./interfaces/IAnomuraEquipment.sol";
import {IEquipmentData} from "./EquipmentData.sol";
import {IAnomuraEquipment, EquipmentMetadata, EquipmentType, EquipmentRarity} from "./interfaces/IAnomuraEquipment.sol";
import {IAnomuraSeeder} from "./interfaces/IAnomuraSeeder.sol";

///@dev seeder for equipment contract. This is not upgradeable
contract AnomuraSeeder is
    IAnomuraSeeder,
    VRFConsumerBaseV2,
    AccessControlEnumerable,
    CantBeEvil,
    AutomationCompatibleInterface
{
    IEquipmentData public equipmentData;
    IAnomuraEquipment public equipmentContract;
    VRFCoordinatorV2Interface public coordinator;

    address private _automationRegistry;

    bytes32 public keyHash;
    bytes32 public constant SEEDER_ROLE = keccak256("SEEDER_ROLE");

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant CALLBACK_GAS_LIMIT = 240000;
    uint32 private constant NUM_WORDS = 1;
    uint64 public subscriptionId;
    uint256 private constant BATCH_SIZE = 50;

    mapping(uint256 => uint256) private _requestIdToGeneration;

    // genId => seed
    mapping(uint256 => uint256) private genSeed;

    /// @notice emitted when a random number is returned from Vrf callback
    /// @param requestId the request identifier, initially returned by {requestRandomness}
    /// @param randomness random number generated by chainlink vrf
    event RequestSeedFulfilled(uint256 indexed requestId, uint256 randomness);

    constructor(
        address coordinator_,
        bytes32 keyHash_,
        uint64 subscriptionId_,
        address equipmentData_
    )
        VRFConsumerBaseV2(address(coordinator_))
        CantBeEvil(LicenseVersion.PUBLIC)
    {
        coordinator = VRFCoordinatorV2Interface(address(coordinator_));
        keyHash = keyHash_;
        subscriptionId = subscriptionId_;
        equipmentData = IEquipmentData(equipmentData_);

        _setupRole(DEFAULT_ADMIN_ROLE, _msgSender());
        _setupRole(SEEDER_ROLE, _msgSender());
    }

    function requestSeed(uint256 _generationId)
        external
        onlyRole(SEEDER_ROLE)
        returns (uint256 requestId)
    {
        require(
            address(equipmentContract) != address(0x0),
            "Equipment contract not set"
        );
        if (equipmentContract.totalSupply() == 0) {
            revert("No token minted yet.");
        }
        uint256 divider = equipmentContract.totalSupply() / BATCH_SIZE;

        if (_generationId < 1 || _generationId > divider + 1) {
            revert("Invalid Generation Id");
        }
        if (genSeed[_generationId] != 0) {
            revert("Seed already set!");
        }
        requestId = coordinator.requestRandomWords(
            keyHash,
            subscriptionId,
            REQUEST_CONFIRMATIONS,
            CALLBACK_GAS_LIMIT,
            NUM_WORDS
        );

        _requestIdToGeneration[requestId] = _generationId;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        uint256 _generationId = _requestIdToGeneration[requestId];

        genSeed[_generationId] = randomWords[0];
        emit RequestSeedFulfilled(_generationId, randomWords[0]);
    }

    /// @dev To set the metadata manually instead of Chainlink Nodes, provided there is a seed for the tokenId.
    function setMetadataForToken(uint256 _tokenId) external
    {
        require(
            address(equipmentContract) != address(0x0),
            "Equipment contract not set"
        );
         require(
            address(equipmentData) != address(0x0),
            "Equipment data not set"
        );
        require(equipmentContract.isTokenExists(_tokenId), "Token not exists");
        require(equipmentContract.isMetadataReveal(_tokenId) == false, "Metadata revealed");

        uint256 _generationId = getGenerationOfToken(_tokenId);
        uint256 _generationSeed = genSeed[_generationId];

        require(_generationSeed != 0, "Seed not set for gen");

        uint256 _seedForThisToken = uint256(
            keccak256(abi.encode(_generationSeed, _tokenId))
        );

        string memory equipmentName;
        EquipmentRarity rarity;
        EquipmentType typeOf = equipmentData.pluckType(_seedForThisToken);

        if (typeOf == EquipmentType.BODY) {
            (equipmentName, rarity) = equipmentData.pluckBody(
                _seedForThisToken
            );
        } else if (typeOf == EquipmentType.CLAWS) {
            (equipmentName, rarity) = equipmentData.pluckClaws(
                _seedForThisToken
            );
        } else if (typeOf == EquipmentType.LEGS) {
            (equipmentName, rarity) = equipmentData.pluckLegs(
                _seedForThisToken
            );
        } else if (typeOf == EquipmentType.SHELL) {
            (equipmentName, rarity) = equipmentData.pluckShell(
                _seedForThisToken
            );
        } else if (typeOf == EquipmentType.HABITAT) {
            (equipmentName, rarity) = equipmentData.pluckHabitat(
                _seedForThisToken
            );
        } else if (typeOf == EquipmentType.HEADPIECES) {
            (equipmentName, rarity) = equipmentData.pluckHeadpieces(
                _seedForThisToken
            );
        } else {
            revert InvalidValue();
        }

        EquipmentMetadata memory metaData = EquipmentMetadata({
            name: equipmentName,
            equipmentRarity: rarity,
            equipmentType: typeOf
        });

        bytes memory _dataToSet = abi.encode(_tokenId, metaData);
        equipmentContract.revealMetadataForToken(_dataToSet);
    }

    function getGenerationOfToken(uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        if (!equipmentContract.isTokenExists(_tokenId)) {
            /* 
            As we want to allow the upkeep to keep running for token that existed within the range.
            We just return 0 and check that the 0 generation is an invalid generation 
             */
            return 0;
        }
        uint256 divider = _tokenId / BATCH_SIZE;
        return divider + 1;
    }

    /// @dev Check() to be called by Chainlink automation nodes
    /// @param checkerData the data can be decoded into lower and upper bound.
    /// 1. Read the token metadata
    /// 2. If metadata not set, then put into array to be processed
    /// 3. Processing the array of token, get its seed and calculate its equipment type, name, rarity
    /// 4. Hash the data for the perform function.
    function checkUpkeep(bytes calldata checkerData)
        external
        view
        override
        returns (bool canExec, bytes memory execPayload)
    {
        (uint256 lowerBound, uint256 upperBound) = abi.decode(
            checkerData,
            (uint256, uint256)
        );

        require(
            lowerBound > 0 &&
                upperBound <= equipmentContract.totalSupply() &&
                lowerBound <= upperBound,
            "Lower and Upper not correct"
        );
        require(
            address(equipmentContract) != address(0x0),
            "Equipment not set"
        );
        require(
            address(equipmentData) != address(0x0),
            "Equipment Data not set"
        );

        uint256 counter = 0;

        for (uint256 i = 0; i < upperBound - lowerBound + 1; i++) {
            uint256 tokenId = lowerBound + i;

            if (
                !equipmentContract.isTokenExists(tokenId) ||
                equipmentContract.isMetadataReveal(tokenId) == true
            ) {
                continue;
            }

            uint256 _generationId = getGenerationOfToken(tokenId);
            uint256 _seed = genSeed[_generationId];

            /* When generation Id is 0 or genSeed mapping is not set by Chainlink VRF, then _seed is 0 */
            if (_seed == 0) {
                continue;
            }

            counter++;
            if (counter == 10) {
                /* 
                1. Due to gas limit on chainlink vs gelato, we split this into chunks, allowing the nodes to execute multiple times
                2. Each chunk processing only 10 tokens, provided the range may have 100 tokens.
                3. The next chunk only process the tokens that do not have metadata set yet.
                 */
                break;
            }
        }

        if (counter == 0) {
            return (false, "Meta set for range");
        }

        canExec = false;

        /* to determine how many elements in an array need to update */
        uint256[] memory tokenIds = new uint256[](counter);
        EquipmentMetadata[] memory metaDataArray = new EquipmentMetadata[](
            counter
        );

        uint256 indexToAdd = 0;
        for (uint256 i = 0; i < upperBound - lowerBound + 1; i++) {
            uint256 tokenId = lowerBound + i;

            uint256 _generationId = getGenerationOfToken(tokenId);
            uint256 _generationSeed = genSeed[_generationId];

            if (
                equipmentContract.isTokenExists(tokenId) &&
                _generationSeed != 0 &&
                equipmentContract.isMetadataReveal(tokenId) == false
            ) {
                // do not access array index using tokenId as it is not be the correct index of the array
                canExec = true;
                tokenIds[indexToAdd] = tokenId;

                uint256 _seedForThisToken = uint256(
                    keccak256(abi.encode(_generationSeed, tokenId))
                );
                string memory equipmentName;
                EquipmentRarity rarity;
                EquipmentType typeOf = equipmentData.pluckType(
                    _seedForThisToken
                );

                if (typeOf == EquipmentType.BODY) {
                    (equipmentName, rarity) = equipmentData.pluckBody(
                        _seedForThisToken
                    );
                } else if (typeOf == EquipmentType.CLAWS) {
                    (equipmentName, rarity) = equipmentData.pluckClaws(
                        _seedForThisToken
                    );
                } else if (typeOf == EquipmentType.LEGS) {
                    (equipmentName, rarity) = equipmentData.pluckLegs(
                        _seedForThisToken
                    );
                } else if (typeOf == EquipmentType.SHELL) {
                    (equipmentName, rarity) = equipmentData.pluckShell(
                        _seedForThisToken
                    );
                } else if (typeOf == EquipmentType.HABITAT) {
                    (equipmentName, rarity) = equipmentData.pluckHabitat(
                        _seedForThisToken
                    );
                } else if (typeOf == EquipmentType.HEADPIECES) {
                    (equipmentName, rarity) = equipmentData.pluckHeadpieces(
                        _seedForThisToken
                    );
                } else {
                    return (false, "Invalid equipment type");
                }

                metaDataArray[indexToAdd] = EquipmentMetadata({
                    name: equipmentName,
                    equipmentRarity: rarity,
                    equipmentType: typeOf
                });

                indexToAdd++;
            }
            if (indexToAdd == 10) { /*index to add and counter must match, there should be 10 items to process each chunk */
                break;
            }
        }

        if (canExec == false) {
            return (false, "Nothing to set");
        }

        bytes memory performData = abi.encode(tokenIds, metaDataArray);
        return (canExec, performData);
    }

    /// @dev Function to be executed by Chainlink automation node, based on the data returned by checkUpkeep()
    /// @param performData the data returned by checkUpkeep
    /// Should only be called by automation registry.
    function performUpkeep(bytes calldata performData) external {
        require(
            _automationRegistry == msg.sender ||
                hasRole(DEFAULT_ADMIN_ROLE, msg.sender),
            "Not approved to perform upkeep"
        );

        (
            uint256[] memory tokenIds,
            EquipmentMetadata[] memory metaDataArray
        ) = abi.decode(performData, (uint256[], EquipmentMetadata[]));

        if (tokenIds.length != metaDataArray.length) {
            revert("Invalid performData");
        }

        // cross check that the data provided by the Automation Nodes is not corrupted.
        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 tokenId = tokenIds[index];

            uint256 _generationId = getGenerationOfToken(tokenId);
            uint256 _generationSeed = genSeed[_generationId];

            if (
                _generationSeed == 0 ||
                equipmentContract.isMetadataReveal(tokenId)== true
            ) {
                continue;
            }

            bytes memory _dataToSet = abi.encode(tokenId, metaDataArray[index]);
            equipmentContract.revealMetadataForToken(_dataToSet);
        }
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(CantBeEvil, AccessControlEnumerable)
        returns (bool)
    {
        return
            type(IAccessControlEnumerable).interfaceId == interfaceId ||
            CantBeEvil.supportsInterface(interfaceId) ||
            super.supportsInterface(interfaceId);
    }

    function setEquipmentContractAddress(address _equipmentContract)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        equipmentContract = IAnomuraEquipment(_equipmentContract);
    }

    /**
    @dev Manual set the address of the Anomura Equipment Data contract
    @param equipmentData_ Address of Equipment Data
    */
    function setEquipmentDataAddress(address equipmentData_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        equipmentData = IEquipmentData(equipmentData_);
    }

    /**
    @dev Manual set the address of Chainlink automation registry
    @param automationRegistry_ new registry address
    */
    function setAutomationRegistry(address automationRegistry_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        _automationRegistry = automationRegistry_;
    }

    /**
    @dev Manual set the subscription of Chainlink automation registry. Used when we move to another chainlink subscription on mainnet
    @param subscriptionId_ new subscriptionId
    */
    function setSubscriptionId(uint64 subscriptionId_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        subscriptionId = subscriptionId_;
    }

    /**
    @dev Manual set the keyash for Chainlink
    @param keyHash_ new keyHash
    */
    function setKeyHash(bytes32 keyHash_)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        keyHash = keyHash_;
    }
}

// SPDX-License-Identifier: MIT
// a16z Contracts v0.0.1 (CantBeEvil.sol)
pragma solidity 0.8.13;

import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {ERC165} from "@openzeppelin/contracts/utils/introspection/ERC165.sol";
import "./interfaces/ICantBeEvil.sol";

enum LicenseVersion {
    PUBLIC,
    EXCLUSIVE,
    COMMERCIAL,
    COMMERCIAL_NO_HATE,
    PERSONAL,
    PERSONAL_NO_HATE
}

contract CantBeEvil is ERC165, ICantBeEvil {
    using Strings for uint256;
    string internal constant _BASE_LICENSE_URI =
        "ar://zmc1WTspIhFyVY82bwfAIcIExLFH5lUcHHUN0wXg4W8/";
    LicenseVersion internal licenseVersion;

    constructor(LicenseVersion _licenseVersion) {
        licenseVersion = _licenseVersion;
    }

    function getLicenseURI() public view returns (string memory) {
        return
            string.concat(
                _BASE_LICENSE_URI,
                uint256(licenseVersion).toString()
            );
    }

    function getLicenseName() public view returns (string memory) {
        return _getLicenseVersionKeyByValue(licenseVersion);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165)
        returns (bool)
    {
        return
            interfaceId == type(ICantBeEvil).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function _getLicenseVersionKeyByValue(LicenseVersion _licenseVersion)
        internal
        pure
        returns (string memory)
    {
        require(uint8(_licenseVersion) <= 6);
        if (LicenseVersion.PUBLIC == _licenseVersion) return "PUBLIC";
        if (LicenseVersion.EXCLUSIVE == _licenseVersion) return "EXCLUSIVE";
        if (LicenseVersion.COMMERCIAL == _licenseVersion) return "COMMERCIAL";
        if (LicenseVersion.COMMERCIAL_NO_HATE == _licenseVersion)
            return "COMMERCIAL_NO_HATE";
        if (LicenseVersion.PERSONAL == _licenseVersion) return "PERSONAL";
        else return "PERSONAL_NO_HATE";
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import {EquipmentRarity, EquipmentType} from "./interfaces/IAnomuraEquipment.sol";
import {LicenseVersion, CantBeEvil} from "./CantBeEvil.sol";

interface IEquipmentData {
    function pluckType(uint256) external view returns (EquipmentType);

    function pluckBody(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckClaws(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckLegs(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckShell(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckHeadpieces(uint256)
        external
        view
        returns (string memory, EquipmentRarity);

    function pluckHabitat(uint256)
        external
        view
        returns (string memory, EquipmentRarity);
}

contract EquipmentData is IEquipmentData, CantBeEvil {
  
    string[] public BODY_PARTS = [
        "Premier Body",
        "Unhinged Body",
        "Mesmerizing Body",
        "Rave Body",
        "Combustion Body",
        "Radiating Eye",
        "Charring Body",
        "Inferno Body",
        "Siberian Body",
        "Antarctic Body",
        "Glacial Body",
        "Amethyst Body",
        "Beast",
        "Panga Panga",
        "Ceylon Ebony",
        "Katalox",
        "Diamond",
        "Golden"
    ];
    string[] public CLAW_PARTS = [
        "Natural Claw",
        "Coral Claw",
        "Titian Claw",
        "Pliers",
        "Scissorhands",
        "Laser Gun",
        "Snow Claw",
        "Sky Claw",
        "Icicle Claw",
        "Pincers",
        "Hammer Logs",
        "Carnivora Claw"
    ];
    string[] public LEGS_PARTS = [
        "Argent Leg",
        "Sunlit Leg",
        "Auroral Leg",
        "Steel Leg",
        "Tungsten Leg",
        "Titanium Leg",
        "Crystal Leg",
        "Empyrean Leg",
        "Azure Leg",
        "Bamboo Leg",
        "Walmara Leg",
        "Pintobortri Leg"
    ];
    string[] public SHELL_PARTS = [
        "Auger Shell",
        "Seasnail Shell",
        "Miter Shell",
        "Alembic",
        "Chimney",
        "Starship",
        "Ice Cube",
        "Ice Shell",
        "Frosty",
        "Mora",
        "Carnivora",
        "Pure Runes",
        "Architect",
        "Bee Hive",
        "Coral",
        "Crystal",
        "Diamond",
        "Ethereum",
        "Golden Skull",
        "Japan Temple",
        "Planter",
        "Snail",
        "Tentacles",
        "Tesla Coil",
        "Cherry Blossom",
        "Maple Green",
        "Volcano",
        "Gates of Hell",
        "Holy Temple",
        "ZED Skull"
    ];
    string[] public HEADPIECES_PARTS = [
        "Morning Sun Starfish",
        "Granulated Starfish",
        "Royal Starfish",
        "Sapphire",
        "Emerald",
        "Kunzite",
        "Rhodonite",
        "Aventurine",
        "Peridot",
        "Moldavite",
        "Jasper",
        "Alexandrite",
        "Copper Fire",
        "Chemical Fire",
        "Carmine Fire",
        "Charon",
        "Deimos",
        "Ganymede",
        "Sol",
        "Sirius",
        "Vega",
        "Aconite Skull",
        "Titan Arum Skull",
        "Nerium Oleander Skull"
    ];
    string[] public HABITAT_PARTS = [
        "Crystal Cave",
        "Crystal Cave Rainbow",
        "Emerald Forest",
        "Garden of Eden",
        "Golden Glade",
        "Beach",
        "Magical Deep Sea",
        "Natural Sea",
        "Bioluminescent Abyss",
        "Blazing Furnace",
        "Steam Apparatus",
        "Science Lab",
        "Starship Throne",
        "Happy Snowfield",
        "Midnight Mountain",
        "Cosmic Star",
        "Sunset Cliffs",
        "Space Nebula",
        "Plains of Vietnam",
        "ZED Run",
        "African Savannah"
    ];
    string[] public PREFIX_ATTRS = [
        "Briny",
        "Tempestuous",
        "Limpid",
        "Pacific",
        "Atlantic",
        "Abysmal",
        "Profound",
        "Misty",
        "Solar",
        "Empyrean",
        "Sideral",
        "Astral",
        "Ethereal",
        "Crystal",
        "Quantum",
        "Empiric",
        "Alchemic",
        "Crash Test",
        "Nuclear",
        "Syntethic",
        "Tempered",
        "Fossil",
        "Craggy",
        "Gemmed",
        "Verdant",
        "Lymphatic",
        "Gnarled",
        "Lithic"
    ];
    string[] public SUFFIX_ATTRS = [
        "of the Coast",
        "of Maelstrom",
        "of Depths",
        "of Eternity",
        "of Peace",
        "of Equilibrium",
        "of the Universe",
        "of the Galaxy",
        "of Absolute Zero",
        "of Constellations",
        "of the Moon",
        "of Lightspeed",
        "of Evidence",
        "of Relativity",
        "of Evolution",
        "of Consumption",
        "of Progress",
        "of Damascus",
        "of Gaia",
        "of The Wild",
        "of Overgrowth",
        "of Rebirth",
        "of World Roots",
        "of Stability"
    ];
    string[] public UNIQUE_ATTRS = [
        "The Leviathan",
        "Will of Oceanus",
        "Suijin's Touch",
        "Tiamat Kiss",
        "Poseidon Vow",
        "Long bao",
        "Uranus Wish",
        "Aim of Indra",
        "Cry of Yuki Onna",
        "Sirius",
        "Vega",
        "Altair",
        "Ephestos Skill",
        "Gift of Prometheus",
        "Pandora's",
        "Wit of Lu Dongbin",
        "Thoth's Trick",
        "Cyclopes Plan",
        "Root of Dimu",
        "Bhumi's Throne",
        "Rive of Daphne",
        "The Minotaur",
        "Call of Cernunnos",
        "Graze of Terra"
    ];
    string[] public BACKGROUND_PREFIX_ATTRS = [
        "Bountiful",
        "Isolated",
        "Mechanical",
        "Reborn"
    ];

    constructor() 
    CantBeEvil(LicenseVersion.PUBLIC)
    {}

    /* 
    1 / 25 = 4% headpieces => 96% rest, for 5 other parts
    0       -     191 = BODY
    192     -     383 = CLAWS
    384     -     575 = LEGS
    576     -     767 = SHELL
    768     -     959 = HABITAT
    960     -     999 - HEADPIECES
    */
    function pluckType(uint256 prob)
        external
        pure
        returns (EquipmentType typeOf)
    {
        uint256 rand = prob % 1000;

        if (rand < 192) typeOf = EquipmentType.BODY;
        else if (rand < 192 * 2) typeOf = EquipmentType.CLAWS;
        else if (rand < 192 * 3) typeOf = EquipmentType.LEGS;
        else if (rand < 192 * 4) typeOf = EquipmentType.SHELL;
        else if (rand < 192 * 5) typeOf = EquipmentType.HABITAT;
        else typeOf = EquipmentType.HEADPIECES;
    }

    function pluckBody(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(prob, EquipmentType.BODY);
    }

    function pluckClaws(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(prob, EquipmentType.CLAWS);
    }

    function pluckLegs(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(prob, EquipmentType.LEGS);
    }

    function pluckShell(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(prob, EquipmentType.SHELL);
    }

    function pluckHeadpieces(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluck(
            prob,
            EquipmentType.HEADPIECES
        );
    }

    function pluckHabitat(uint256 prob)
        external
        view
        returns (string memory equipmentName, EquipmentRarity equipmentRarity)
    {
        (equipmentName, equipmentRarity) = pluckBackground(prob);
    }

    function pluckBackground(uint256 _seed)
        internal
        view
        returns (string memory output, EquipmentRarity)
    {
        uint256 randomCount = 0;
        uint256 greatness = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        ) % 51;
        uint256 randNameSeed = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        );
        uint256 randPartSeed = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        );

        output = HABITAT_PARTS[randNameSeed % HABITAT_PARTS.length];

        if (greatness > 45) {
            output = string(
                abi.encodePacked(
                    BACKGROUND_PREFIX_ATTRS[
                        randPartSeed % BACKGROUND_PREFIX_ATTRS.length
                    ],
                    " ",
                    output
                )
            );
            return (output, EquipmentRarity.RARE);
        }
        return (output, EquipmentRarity.NORMAL); // does not have any special attributes
    }

    function pluck(uint256 _seed, EquipmentType typeOf)
        internal
        view
        returns (string memory output, EquipmentRarity)
    {
        uint256 randomCount = 0;
        uint256 greatness = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        ) % 94;
        uint256 randNameSeed = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        );
        uint256 randPartSeed = uint256(
            keccak256(abi.encode(_seed, randomCount++))
        );

        if (typeOf == EquipmentType.BODY) {
            output = BODY_PARTS[randNameSeed % BODY_PARTS.length];
        } else if (typeOf == EquipmentType.CLAWS) {
            output = CLAW_PARTS[randNameSeed % CLAW_PARTS.length];
        } else if (typeOf == EquipmentType.LEGS) {
            output = LEGS_PARTS[randNameSeed % LEGS_PARTS.length];
        } else if (typeOf == EquipmentType.SHELL) {
            output = SHELL_PARTS[randNameSeed % SHELL_PARTS.length];
        } else if (typeOf == EquipmentType.HEADPIECES) {
            output = HEADPIECES_PARTS[randNameSeed % HEADPIECES_PARTS.length];
        } else if (typeOf == EquipmentType.HABITAT) {
            output = HABITAT_PARTS[randNameSeed % HABITAT_PARTS.length];
        }

        if (greatness > 92) {
            output = string(
                abi.encodePacked(
                    UNIQUE_ATTRS[randPartSeed % UNIQUE_ATTRS.length],
                    " ",
                    output
                )
            );
            return (output, EquipmentRarity.LEGENDARY);
        }

        if (greatness > 83) {
            output = string(
                abi.encodePacked(
                    PREFIX_ATTRS[randPartSeed % PREFIX_ATTRS.length],
                    " ",
                    output,
                    " ",
                    SUFFIX_ATTRS[randPartSeed % SUFFIX_ATTRS.length]
                )
            );
            return (output, EquipmentRarity.RARE);
        }

        if (greatness > 74) {
            output = string(
                abi.encodePacked(
                    output,
                    " ",
                    SUFFIX_ATTRS[randPartSeed % SUFFIX_ATTRS.length]
                )
            );
            return (output, EquipmentRarity.MAGIC);
        }

        if (greatness > 65) {
            output = string(
                abi.encodePacked(
                    PREFIX_ATTRS[randPartSeed % PREFIX_ATTRS.length],
                    " ",
                    output
                )
            );
            return (output, EquipmentRarity.MAGIC);
        }
        return (output, EquipmentRarity.NORMAL); // does not have any special attributes
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import {IERC721AUpgradeable} from "./IERC721AUpgradeable.sol";

interface IAnomuraEquipment is IERC721AUpgradeable { 
    function isTokenExists(uint256 _tokenId) external view returns(bool); 
    function isMetadataReveal(uint256 _tokenId) external view returns(bool);
    function revealMetadataForToken(bytes calldata performData) external; 
}

// This will likely change in the future, this should not be used to store state, or can only use inside a mapping
struct EquipmentMetadata {
    string name;
    EquipmentType equipmentType;
    EquipmentRarity equipmentRarity;
}

/// @notice equipment information
enum EquipmentType {
    BODY,
    CLAWS,
    LEGS,
    SHELL,
    HEADPIECES,
    HABITAT
}

/// @notice rarity information
enum EquipmentRarity {
    NORMAL,
    MAGIC,
    RARE,
    LEGENDARY 
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

interface IAnomuraErrors {
    error InvalidRecipient();
    error InvalidTokenIds();
    error InvalidOwner();
    error InvalidItemType();
    error InvalidString();
    error InvalidLength();
    error InvalidValue();
    error InvalidEquipmentAddress();
    error InvalidCollectionType();
    error IsPaused();
}

//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
import "./IAnomuraEquipment.sol";
import {IAnomuraErrors} from "./IAnomuraErrors.sol";

interface IAnomuraSeeder is IAnomuraErrors
{
    function requestSeed(uint256 _tokenId) external returns(uint256);
}

// SPDX-License-Identifier: MIT
// a16z Contracts v0.0.1 (ICantBeEvil.sol)
pragma solidity 0.8.13;

interface ICantBeEvil {
    function getLicenseURI() external view returns (string memory);
    function getLicenseName() external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v3.3.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721MetadataUpgradeable.sol";

/**
 * @dev Interface of an ERC721A compliant contract.
 */
interface IERC721AUpgradeable is IERC721Upgradeable, IERC721MetadataUpgradeable {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * The caller cannot approve to the current owner.
     */
    error ApprovalToCurrentOwner();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    // Compiler will pack this into a single 256bit word.
    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Keeps track of the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
    }

    // Compiler will pack this into a single 256bit word.
    struct AddressData {
        // Realistically, 2**64-1 is more than enough.
        uint64 balance;
        // Keeps track of mint count with minimal overhead for tokenomics.
        uint64 numberMinted;
        // Keeps track of burn count with minimal overhead for tokenomics.
        uint64 numberBurned;
        // For miscellaneous variable(s) pertaining to the address
        // (e.g. number of whitelist mint slots used).
        // If there are multiple variables, please pack them into a uint64.
        uint64 aux;
    }

    /**
     * @dev Returns the total amount of tokens stored by the contract.
     * 
     * Burned tokens are calculated here, use `_totalMinted()` if you want to count just minted tokens.
     */
    function totalSupply() external view returns (uint256);
}