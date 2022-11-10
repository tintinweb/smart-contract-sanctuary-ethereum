/**
 *Submitted for verification at Etherscan.io on 2022-05-13
 */

// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.6;

// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

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
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IERC165).interfaceId;
    }
}

interface IERC721Metadata {
    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}

/// @title Account-bound tokens
/// @dev See https://eips.ethereum.org/EIPS/eip-4973
///  Note: the ERC-165 identifier for this interface is 0x6352211e.
/* is ERC165, ERC721Metadata */
interface IERC4973 {
    /// @dev This emits when a new token is created and bound to an account by
    /// any mechanism.
    /// Note: For a reliable `_from` parameter, retrieve the transaction's
    /// authenticated `from` field.
    event Attest(address indexed _to, uint256 indexed _tokenId);
    /// @dev This emits when an existing ABT is revoked from an account and
    /// destroyed by any mechanism.
    /// Note: For a reliable `_from` parameter, retrieve the transaction's
    /// authenticated `from` field.
    event Revoke(address indexed _to, uint256 indexed _tokenId);

    /// @notice Find the address bound to an ERC4973 account-bound token
    /// @dev ABTs assigned to zero address are considered invalid, and queries
    ///  about them do throw.
    /// @param _tokenId The identifier for an ABT
    /// @return The address of the owner bound to the ABT
    function ownerOf(uint256 _tokenId) external view returns (address);
}

abstract contract ERC4973 is ERC165, IERC721Metadata, IERC4973 {
    string private _name;
    string private _symbol;

    mapping(uint256 => address) private _owners;
    mapping(uint256 => string) private _tokenURIs;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override
        returns (bool)
    {
        return
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IERC4973).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
    {
        require(_exists(tokenId), "tokenURI: token doesn't exist");
        return _tokenURIs[tokenId];
    }

    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ownerOf: token doesn't exist");
        return owner;
    }

    function _mint(
        address to,
        uint256 tokenId,
        string memory uri
    ) internal virtual returns (uint256) {
        require(!_exists(tokenId), "mint: tokenID exists");
        _owners[tokenId] = to;
        _tokenURIs[tokenId] = uri;
        emit Attest(to, tokenId);
        return tokenId;
    }

    function _burn(uint256 tokenId) internal virtual {
        address owner = ownerOf(tokenId);

        delete _owners[tokenId];
        delete _tokenURIs[tokenId];

        emit Revoke(owner, tokenId);
    }
}

// string constant uri = "https://ipfs.io/ipfs/QmdoUaYzKCMUmeH473amYJNyFrL1a6gtccQ5rYsqqeHBsC";

contract SBT is ERC4973 {
    uint256 public tokenId;
    // The URI of the token
    string public uri =
        "https://ipfs.io/ipfs/bafybeic2avs7cl4puzdegxjcenjtz4m3l42u54zy22sm5iypylznkr46m4/1.json";

    constructor() ERC4973("Rebel Dogs Club", "RDC") {
        super._mint(msg.sender, tokenId, uri);
    }

    function mint(address to) external returns (uint256) {
        super._mint(to, tokenId, uri);
        tokenId++;
        return tokenId - 1;
    }
}