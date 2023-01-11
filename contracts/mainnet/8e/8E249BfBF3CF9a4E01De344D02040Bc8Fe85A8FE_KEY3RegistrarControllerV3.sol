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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

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
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
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
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../utils/StringUtilsV2.sol";
import "../IKEY3FreeRegistrar.sol";
import "../resolvers/AddrResolver.sol";
import "../validators/IKEY3Validator.sol";
import "../validators/IKEY3MerkleValidator.sol";
import "../IKEY3InvitationRegistry.sol";
import "../IKEY3RewardRegistry.sol";
import "../IKEY3ClaimRegistry.sol";

contract KEY3RegistrarControllerV3 is Pausable, Ownable {
    using StringUtilsV2 for *;

    uint256 public constant EARLYBIRD_PERIOD = 0 hours;

    IKEY3FreeRegistrar public base;
    IKEY3MerkleValidator public merkleValidator;
    IKEY3Validator public validator;
    IKEY3InvitationRegistry public invitationRegistry;
    IKEY3RewardRegistry public rewardRegistry;
    IKEY3ClaimRegistry public claimRegistry;

    uint256 public minCommitmentAge;
    uint256 public maxCommitmentAge;

    mapping(bytes32 => uint256) public commitments;
    uint256 public startedTime;

    event Start();
    event NameRegistered(
        string name,
        bytes32 indexed label,
        address indexed owner
    );
    event SetBaseRegistrar(address indexed registrar);
    event SetMerkleValidator(address indexed validator);
    event SetValidator(address indexed validator);
    event SetInvitationRegistry(address indexed registry);
    event SetRewardRegistry(address indexed registry);
    event SetClaimRegistry(address indexed registry);

    modifier whenStarted() {
        require(startedTime > 0, "not started yet");
        _;
    }

    constructor(
        IKEY3FreeRegistrar freeRegistrar_,
        IKEY3InvitationRegistry invitationRegistry_,
        IKEY3Validator validator_,
        IKEY3MerkleValidator merkleValidator_,
        IKEY3RewardRegistry rewardRegistry_,
        IKEY3ClaimRegistry claimRegistry_,
        uint256 minCommitmentAge_,
        uint256 maxCommitmentAge_
    ) {
        require(maxCommitmentAge_ > minCommitmentAge_);

        base = freeRegistrar_;
        invitationRegistry = invitationRegistry_;
        validator = validator_;
        merkleValidator = merkleValidator_;
        rewardRegistry = rewardRegistry_;
        claimRegistry = claimRegistry_;

        minCommitmentAge = minCommitmentAge_;
        maxCommitmentAge = maxCommitmentAge_;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _invitationsOf(
        address inviter_
    ) internal view returns (address[] memory) {
        return invitationRegistry.invitationsOf(inviter_);
    }

    function invitationsOf(
        address inviter_
    ) public view returns (address[] memory) {
        return _invitationsOf(inviter_);
    }

    function claimsOf(address user_) public view returns (uint256) {
        return claimRegistry.claimsOf(user_);
    }

    function claimLimit() public view returns (uint256) {
        return claimRegistry.claimLimit();
    }

    function _validate(string memory name_) internal view returns (bool) {
        if (address(validator) == address(0)) {
            return true;
        }
        return validator.validate(name_.toLowerCase());
    }

    function validate(string memory name_) public view returns (bool) {
        return _validate(name_);
    }

    function _available(string memory name_) internal view returns (bool) {
        string memory name = name_.toLowerCase();
        bytes32 label = keccak256(bytes(name));
        if (!base.available(uint256(label))) {
            return false;
        }
        if (address(rewardRegistry) != address(0)) {
            (bool exist, ) = rewardRegistry.exists(msg.sender, name);
            if (exist) {
                return true;
            }
        }
        return _validate(name);
    }

    function available(string memory name_) public view returns (bool) {
        return _available(name_);
    }

    function start() public onlyOwner {
        require(startedTime == 0);
        require(address(validator) != address(0));
        require(address(merkleValidator) != address(0));
        require(address(invitationRegistry) != address(0));
        require(address(rewardRegistry) != address(0));
        require(address(claimRegistry) != address(0));
        startedTime = block.timestamp;
        emit Start();
    }

    function setMerkleValidator(
        address validator_
    ) public onlyOwner whenPaused {
        merkleValidator = IKEY3MerkleValidator(validator_);
        emit SetMerkleValidator(validator_);
    }

    function setBaseRegistrar(address registrar_) public onlyOwner whenPaused {
        base = IKEY3FreeRegistrar(registrar_);
        emit SetBaseRegistrar(registrar_);
    }

    function setValidator(address validator_) public onlyOwner whenPaused {
        validator = IKEY3Validator(validator_);
        emit SetValidator(validator_);
    }

    function setInvitationRegistry(
        address registry_
    ) public onlyOwner whenPaused {
        invitationRegistry = IKEY3InvitationRegistry(registry_);
        emit SetInvitationRegistry(registry_);
    }

    function setRewardRegistry(address registry_) public onlyOwner whenPaused {
        require(
            base.baseNode() == IKEY3RewardRegistry(registry_).baseNode(),
            "invalid base node"
        );
        rewardRegistry = IKEY3RewardRegistry(registry_);
        emit SetRewardRegistry(registry_);
    }

    function setClaimRegistry(address registry_) public onlyOwner whenPaused {
        require(
            base.baseNode() == IKEY3ClaimRegistry(registry_).baseNode(),
            "invalid base node"
        );
        claimRegistry = IKEY3ClaimRegistry(registry_);
        emit SetClaimRegistry(registry_);
    }

    function setCommitmentAges(
        uint256 minCommitmentAge_,
        uint256 maxCommitmentAge_
    ) public onlyOwner {
        require(maxCommitmentAge_ > minCommitmentAge_);
        minCommitmentAge = minCommitmentAge_;
        maxCommitmentAge = maxCommitmentAge_;
    }

    function generateCommitment(
        string memory name_,
        address owner_,
        bytes32 secret_,
        address resolver_,
        address addr_
    ) public pure returns (bytes32) {
        return _generateCommitment(name_, owner_, secret_, resolver_, addr_);
    }

    function _generateCommitment(
        string memory name_,
        address owner_,
        bytes32 secret_,
        address resolver_,
        address addr_
    ) internal pure returns (bytes32) {
        bytes32 label = keccak256(bytes(name_.toLowerCase()));
        if (resolver_ == address(0) && addr_ == address(0)) {
            return keccak256(abi.encodePacked(label, owner_, secret_));
        }
        require(resolver_ != address(0), "resolver_ != 0x0 required");
        return
            keccak256(
                abi.encodePacked(label, owner_, resolver_, addr_, secret_)
            );
    }

    function commit(
        bytes32 commitment_,
        bytes32[] memory merkleProofs_
    ) public whenStarted {
        if (
            block.timestamp <= startedTime + EARLYBIRD_PERIOD &&
            address(merkleValidator) != address(0)
        ) {
            require(
                merkleValidator.validate(msg.sender, merkleProofs_),
                "not on allowlist"
            );
        }

        require(claimRegistry.claimable(msg.sender), "reached maximum limit");

        require(
            commitments[commitment_] + maxCommitmentAge < block.timestamp,
            "commitment exists"
        );
        commitments[commitment_] = block.timestamp;
    }

    function register(
        string memory name_,
        address resolver_,
        address inviter_,
        bytes32 secret_
    ) public whenStarted {
        bytes32 commitment = _generateCommitment(
            name_,
            msg.sender,
            secret_,
            resolver_,
            msg.sender
        );
        require(commitments[commitment] + minCommitmentAge <= block.timestamp);
        require(commitments[commitment] + maxCommitmentAge > block.timestamp);

        _register(name_, resolver_, msg.sender, false);

        delete (commitments[commitment]);
        invitationRegistry.register(msg.sender, inviter_);
    }

    function claimRewards(address resolver_) public whenStarted {
        require(base.baseNode() == rewardRegistry.baseNode(), "invalid claim");
        string[] memory names = rewardRegistry.claim(msg.sender);
        if (names.length == 0) {
            return;
        }
        for (uint i = 0; i < names.length; i++) {
            _register(names[i], resolver_, msg.sender, true);
        }
    }

    function _register(
        string memory name_,
        address resolver_,
        address addr_,
        bool freeClaim_
    ) internal whenNotPaused {
        string memory name = name_.toLowerCase();
        require(_available(name), "this did is not available");

        bytes32 label = keccak256(bytes(name));
        uint256 tokenId = uint256(label);

        if (resolver_ != address(0)) {
            // Set this contract as the (temporary) owner, giving it
            // permission to set up the resolver.
            base.register(tokenId, address(this));

            // The nodehash of this label
            bytes32 nodehash = keccak256(
                abi.encodePacked(base.baseNode(), label)
            );

            // Set the resolver
            base.key3().setResolver(nodehash, resolver_);

            // Configure the resolver
            if (addr_ != address(0)) {
                AddrResolver(resolver_).setAddr(nodehash, addr_);
            }

            // Now transfer full ownership to the expected owner
            base.transferFrom(address(this), msg.sender, tokenId);
        } else {
            require(addr_ == address(0));
            base.register(tokenId, msg.sender);
        }

        if (!freeClaim_) {
            require(
                base.baseNode() == claimRegistry.baseNode(),
                "invalid claim"
            );
            claimRegistry.claim(msg.sender);
        }

        emit NameRegistered(name, label, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKEY3 {
    // Logged when the owner of a node assigns a new owner to a subnode.
    event NewOwner(bytes32 indexed node, bytes32 indexed label, address owner);

    // Logged when the owner of a node transfers ownership to a new account.
    event Transfer(bytes32 indexed node, address owner);

    // Logged when the resolver for a node changes.
    event NewResolver(bytes32 indexed node, address resolver);

    // Logged when the TTL of a node changes
    event NewTTL(bytes32 indexed node, uint64 ttl);

    // Logged when an operator is added or removed.
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

    function setRecord(
        bytes32 node,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeRecord(
        bytes32 node,
        bytes32 label,
        address owner,
        address resolver,
        uint64 ttl
    ) external;

    function setSubnodeOwner(
        bytes32 node,
        bytes32 label,
        address owner
    ) external returns (bytes32);

    function setResolver(bytes32 node, address resolver) external;

    function setOwner(bytes32 node, address owner) external;

    function setTTL(bytes32 node, uint64 ttl) external;

    function setApprovalForAll(address operator, bool approved) external;

    function owner(bytes32 node) external view returns (address);

    function resolver(bytes32 node) external view returns (address);

    function ttl(bytes32 node) external view returns (uint64);

    function recordExists(bytes32 node) external view returns (bool);

    function isApprovedForAll(address owner, address operator)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKEY3ClaimRegistry {
    event SetClaimLimit(uint256 indexed claimLimit);

    function claimLimit() external view returns (uint256);

    function baseNode() external view returns (bytes32);

    function claimable(address user_) external view returns (bool);

    function claimsOf(address user_) external view returns (uint256);

    function claim(address user_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./IKEY3.sol";

interface IKEY3FreeRegistrar is IERC721 {
    event NameRegistered(uint256 indexed id, address indexed owner);

    function baseNode() external view returns (bytes32);

    function key3() external view returns (IKEY3);

    // Authorizes a controller, who can register and renew domains.
    function addController(address controller) external;

    // Revoke controller permission for an address.
    function removeController(address controller) external;

    // Set the resolver for the TLD this registrar manages.
    function setResolver(address resolver) external;

    // Returns true iff the specified name is available for registration.
    function available(uint256 id) external view returns (bool);

    /**
     * @dev Register a name.
     */
    function register(uint256 id, address owner) external;

    /**
     * @dev Reclaim ownership of a name in KEY3, if you own it in the registrar.`
     */
    function reclaim(uint256 id, address owner) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKEY3InvitationRegistry {
    event CloseRound(uint256 indexed round, uint256 maxTicket);
    event NewRound(uint256 indexed round, uint256 minTicket);

    function addController(address controller) external;

    function removeController(address controller) external;

    function startNewRound() external;

    function register(address user, address inviter) external;

    function currentTicket() external view returns (uint256);

    function currentRound() external view returns (uint256);

    function ticketsOf(address inviter)
        external
        view
        returns (uint256[] memory);

    function invitationsOf(address inviter_)
        external
        view
        returns (address[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKEY3RewardRegistry {
    struct Reward {
        string name;
        uint256 claimedAt;
        uint256 expiredAt;
        bool claimed;
    }

    event Claim(address indexed user, string name);

    function baseNode() external view returns (bytes32);

    function rewardsOf(address user) external view returns (Reward[] memory);

    function exists(address user, string memory name)
        external
        view
        returns (bool, uint);

    function claim(address user) external returns (string[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "./BaseResolver.sol";

abstract contract AddrResolver is BaseResolver {
    bytes4 private constant ADDR_INTERFACE_ID = 0x3b3b57de;
    bytes4 private constant ADDRESS_INTERFACE_ID = 0xf1cb7e06;
    uint private constant COIN_TYPE_ETH = 60;

    event AddrChanged(bytes32 indexed node, address a);
    event AddressChanged(bytes32 indexed node, uint coinType, bytes newAddress);

    mapping(bytes32 => mapping(uint => bytes)) _addresses;

    /**
     * Sets the address associated with an KEY3 node.
     * May only be called by the owner of that node in the KEY3 registry.
     * @param node The node to update.
     * @param a The address to set.
     */
    function setAddr(bytes32 node, address a) external authorised(node) {
        setAddr(node, COIN_TYPE_ETH, _addressToBytes(a));
    }

    /**
     * Returns the address associated with an KEY3 node.
     * @param node The KEY3 node to query.
     * @return The associated address.
     */
    function addr(bytes32 node) public view returns (address payable) {
        bytes memory a = addr(node, COIN_TYPE_ETH);
        if (a.length == 0) {
            return payable(address(0));
        }
        return _bytesToAddress(a);
    }

    function setAddr(
        bytes32 node,
        uint coinType,
        bytes memory a
    ) public authorised(node) {
        emit AddressChanged(node, coinType, a);
        if (coinType == COIN_TYPE_ETH) {
            emit AddrChanged(node, _bytesToAddress(a));
        }
        _addresses[node][coinType] = a;
    }

    function addr(bytes32 node, uint coinType)
        public
        view
        returns (bytes memory)
    {
        return _addresses[node][coinType];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId == ADDR_INTERFACE_ID ||
            interfaceId == ADDRESS_INTERFACE_ID ||
            super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

abstract contract BaseResolver is ERC165 {
    modifier authorised(bytes32 node) {
        require(_isAuthorised(node));
        _;
    }

    function _isAuthorised(bytes32 node) internal view virtual returns (bool);

    function _bytesToAddress(bytes memory b)
        internal
        pure
        returns (address payable a)
    {
        require(b.length == 20);
        assembly {
            a := div(mload(add(b, 32)), exp(256, 12))
        }
    }

    function _addressToBytes(address a) internal pure returns (bytes memory b) {
        b = new bytes(20);
        assembly {
            mstore(add(b, 32), mul(a, exp(256, 12)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

library StringUtilsV2 {
    function strlen(string memory s) internal pure returns (uint) {
        uint len;
        uint i = 0;
        bytes memory b = bytes(s);
        for (len = 0; i < b.length; len++) {
            bytes1 char = b[i];
            if (char < 0x80) {
                i += 1;
            } else if (char < 0xE0) {
                i += 2;
            } else if (char < 0xF0) {
                i += 3;
            } else if (char < 0xF8) {
                i += 4;
            } else if (char < 0xFC) {
                i += 5;
            } else {
                i += 6;
            }
        }
        return len;
    }

    function onlyContainNumbers(string memory s) internal pure returns (bool) {
        bytes memory b = bytes(s);
        if (b.length == 0) {
            return false;
        }

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (!(char >= 0x30 && char <= 0x39)) {
                return false;
            }
        }

        return true;
    }

    function onlyContainLetters(string memory s) internal pure returns (bool) {
        bytes memory b = bytes(s);
        if (b.length == 0) {
            return false;
        }

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (
                !(char >= 0x41 && char <= 0x5A) &&
                !(char >= 0x61 && char <= 0x7A)
            ) {
                return false;
            }
        }

        return true;
    }

    function onlyContainNumbersAndLetters(
        string memory s
    ) internal pure returns (bool) {
        bytes memory b = bytes(s);
        if (b.length == 0) {
            return false;
        }

        for (uint i; i < b.length; i++) {
            bytes1 char = b[i];
            if (
                !(char >= 0x30 && char <= 0x39) &&
                !(char >= 0x41 && char <= 0x5A) &&
                !(char >= 0x61 && char <= 0x7A)
            ) {
                return false;
            }
        }

        return true;
    }

    function toLowerCase(
        string memory s
    ) internal pure returns (string memory) {
        bytes memory b = bytes(s);
        bytes memory lowers = new bytes(b.length);
        for (uint i = 0; i < b.length; i++) {
            bytes1 char = b[i];
            if (char >= 0x41 && char <= 0x5A) {
                lowers[i] = bytes1(uint8(char) + 0x20);
            } else {
                lowers[i] = b[i];
            }
        }
        return string(lowers);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKEY3MerkleValidator {
    function validate(address addr_, bytes32[] calldata merkleProofs_)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IKEY3Validator {
    function validate(string memory name) external view returns (bool);
}