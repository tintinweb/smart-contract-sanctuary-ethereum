/**
 *Submitted for verification at Etherscan.io on 2022-12-17
*/

pragma solidity 0.8.17;
//SPDX-License-Identifier: MIT

// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

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

interface IMetaHolder is IERC165 {
    /**
     * @dev Emitted when a new attestation `attestationId` with uri `uri` is minted on Desoc `society`
     */
    event SocietyUpdated(address society, string uri);

    /**
     * @dev Emitted when a new admin `admin` is assigned on Desoc `society`
     */
    event AdminUpdated(address society, address admin);

    /**
     * @dev Emitted when an attestation of ID `attestationId` is marked as the delegate role attestation
     */
    event DelegatesUpdated(address society, uint256 attestationId);

    /**
     * @dev Emitted when a new attestation `attestationId` with uri `uri` is minted on Desoc `society`
     */
    event AttestationUpdated(
        address society,
        uint256 attestationId,
        string uri
    );

    /**
     * @dev Emitted when a new token `tokenId` is minted to attestation `attestationId`
     */
    event Issued(
        address indexed society,
        address indexed recipient,
        address indexed issuedBy,
        uint256 attestationId,
        uint256 tokenId
    );

    /**
     * @dev Emitted when `tokenId` token which belongs to `owner` is revoked by `revokedBy`.
     */
    event Revoked(
        uint256 indexed tokenId,
        uint256 indexed attestationId,
        address indexed revokedBy,
        address _owner
    );

    /**
     * @dev set the desoc manager/factory contract address
     */
    function setFactoryAddress(address factory) external;

    /**
     * @dev external function called by factory contract to add a newly deployed society
     */
    function addSociety(address society, string calldata uri) external;

    /**
     * @dev external function called by factory contract to add a newly deployed society
     */
    function updateSociety(string calldata uri) external;

    /**
     * @dev external function called by a Desoc contract log it's updated admin
     */
    function updateAdmin(address admin) external;

    /**
     * @dev external function called by a Desoc contract log it's updated delegate attestation
     */
    function updateDelegate(uint256 attestationId) external;

    /**
     * @dev update attestation token uri
     */
    function updateAttestation(uint256 attestationId, string calldata uri)
        external;

    /**
     * @dev issue a new attestation to `recipient`
     */
    function issueAttestation(
        uint256 attestationId,
        uint256 tokenId,
        address recipient,
        address issuedBy
    ) external;

    /**
     * @dev Revoke a tokenId `tokenId` of attestation `attestationId` which was owned by `_owner`
     */
    function revokeToken(
        uint256 tokenId,
        uint256 attestationId,
        address _owner,
        address revokedBy
    ) external;
}

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

/// @title An experimental implementation of an event logging smart contract for Desoc Oss Protocol
/// @author DeSoc OSS collective
/// @notice This contract is linked to the factory and other sbt contracts for the purpose of event logging
/// @dev All functions are subject to changes in the future.
/// @custom:experimental This is an experimental contract.
contract MetadataHolder is IMetaHolder, Ownable {
    address public factoryAddress;
    mapping(address => bool) public societies;
    mapping(bytes32 => bool) public attestations;

    modifier onlyFactoryContract() {
        require(_msgSender() == factoryAddress, "unauthorized: factory only");
        _;
    }

    modifier onlyValidSociety() {
        require(societies[_msgSender()], "unauthorized: desoc only");
        _;
    }

    constructor(address _factoryAddress) {
        factoryAddress = _factoryAddress;
    }

    /**
     * @dev set the desoc manager/factory contract address
     */
    function setFactoryAddress(address factory) external onlyOwner {
        factoryAddress = factory;
    }

    /**
     * @dev external function called by factory contract to add a newly deployed society
     */
    function addSociety(address society, string calldata uri)
        external
        onlyFactoryContract
    {
        societies[society] = true;
        emit SocietyUpdated(society, uri);
    }

    /// @inheritdoc IMetaHolder
    function updateAdmin(address admin) external onlyValidSociety {
        emit AdminUpdated(_msgSender(), admin);
    }

    /// @inheritdoc IMetaHolder
    function updateDelegate(uint256 attestationId) external onlyValidSociety {
        emit DelegatesUpdated(_msgSender(), attestationId);
    }

    /// @inheritdoc IMetaHolder
    function updateSociety(string calldata uri) external onlyValidSociety {
        emit SocietyUpdated(_msgSender(), uri);
    }

    /// @inheritdoc IMetaHolder
    function updateAttestation(uint256 attestationId, string calldata uri)
        external
        onlyValidSociety
    {
        if (!isValidAttestation(_msgSender(), attestationId)) {
            bytes32 id = keccak256(abi.encode(_msgSender(), attestationId));
            attestations[id] = true;
        }
        emit AttestationUpdated(_msgSender(), attestationId, uri);
    }

    /// @inheritdoc IMetaHolder
    function issueAttestation(
        uint256 attestationId,
        uint256 tokenId,
        address recipient,
        address issuedBy
    ) external onlyValidSociety {
        require(
            isValidAttestation(_msgSender(), attestationId),
            "Invalid attestation"
        );
        emit Issued(_msgSender(), recipient, issuedBy, attestationId, tokenId);
    }

    /// @inheritdoc IMetaHolder
    function revokeToken(
        uint256 tokenId,
        uint256 attestationId,
        address _owner,
        address revokedby
    ) external onlyValidSociety {
        emit Revoked(tokenId, attestationId, revokedby, _owner);
    }

    /// @inheritdoc IERC165
    function supportsInterface(bytes4 interfaceId)
        public
        pure
        override(IERC165)
        returns (bool)
    {
        return interfaceId == type(IMetaHolder).interfaceId;
    }

    function isValidSociety(address society) public view returns (bool) {
        return societies[society];
    }

    function isValidAttestation(address society, uint256 attestationId)
        public
        view
        returns (bool)
    {
        bytes32 id = keccak256(abi.encode(society, attestationId));
        return attestations[id];
    }
}