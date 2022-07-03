//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;

import "./interfaces/IERC4973.sol";

/// @notice simple implementation of an accountbound token
contract Readooooor is IERC4973 {
    /*
     *********************
     ** STATE VARIABLES **
     *********************
     */
    uint256 private _tokenId;
    string private _name = "Readooooor";
    string private _symbol = "RDOOOOOR";
    string private _uri = "";

    /// @notice id => URI
    mapping(uint256 => string) private _tokenURI;
    mapping(address => uint256) private _balances;
    mapping(uint256 => address) private _ownership;

    /*
     **************
     ** METADATA **
     **************
     */
    /// @dev see interface docs
    function name() external view returns (string memory) {
        return _name;
    }

    /// @dev see interface docs
    function symbol() external view returns (string memory) {
        return _symbol;
    }

    /// @dev see interface docs
    function tokenURI(uint256 tokenId) external view returns (string memory) {
        return _tokenURI[tokenId];
    }

    /*
     ******************
     ** ACCOUNTBOUND **
     ******************
     */
    function balanceOf(address owner) external view returns (uint256) {
        return _balances[owner];
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return _ownership[tokenId];
    }

    function mint() external {
        _updateAccount(0, _tokenId, msg.sender);
    }

    function burn(uint256 tokenId) external {
        require(
            msg.sender == this.ownerOf(tokenId),
            "burn: msg.sender != owner"
        );
        _updateAccount(1, tokenId, msg.sender);
    }

    /// @param _select - 0 - mint, 1 - burn
    function _updateAccount(
        uint256 _select,
        uint256 _id,
        address _account
    ) internal {
        if (_select == 0) {
            _tokenId++;
            _balances[_account]++;
            _ownership[(_id + 1)] = _account;
            _tokenURI[
                (_id + 1)
            ] = "https://skynetfree.net/AABDFCvj_VMrMS5RJZ7kgvsmXrOwt1LrCndy5oUZOYJOUw";

            emit Attest(_account, (_id+1));
        } else {
            _balances[_account]--;
            _ownership[_id] = address(0);

            emit Revoke(_account, (_id+1));
        }
    }

    /*
     ************
     ** ERC165 **
     ************
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

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import "./IERC721Metadata.sol";

/// @title Account-bound tokens
/// @dev See https://eips.ethereum.org/EIPS/eip-4973
interface IERC4973 is IERC165, IERC721Metadata {
  /// @dev This emits when a new token is created and bound to an account by
  /// any mechanism.
  /// Note: For a reliable `from` parameter, retrieve the transaction's
  /// authenticated `from` field.
  event Attest(address indexed to, uint256 indexed tokenId);
  
  /// @dev This emits when an existing ABT is revoked from an account and
  /// destroyed by any mechanism.
  /// Note: For a reliable `from` parameter, retrieve the transaction's
  /// authenticated `from` field.
  event Revoke(address indexed to, uint256 indexed tokenId);

  /// @notice Count all ABTs assigned to an owner
  /// @dev ABTs assigned to the zero address are considered invalid, and this
  ///  function throws for queries about the zero address.
  /// @param owner An address for whom to query the balance
  /// @return The number of ABTs owned by `owner`, possibly zero
  function balanceOf(address owner) external view returns (uint256);

  /// @notice Find the address bound to an ERC4973 account-bound token
  /// @dev ABTs assigned to zero address are considered invalid, and queries
  ///  about them do throw.
  /// @param tokenId The identifier for an ABT
  /// @return The address of the owner bound to the ABT
  function ownerOf(uint256 tokenId) external view returns (address);

  /// @notice Destroys `tokenId`. At any time, an ABT receiver must be able to
  ///  disassociate themselves from an ABT publicly through calling this
  ///  function.
  /// @dev Must emit a `event Revoke` with the `address to` field pointing to
  ///  the zero address.
  /// @param tokenId The identifier for an ABT
  function burn(uint256 tokenId) external;

  /// @notice additional function
  function mint() external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)
pragma solidity ^0.8.0;

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev Remove ERC721 `transfer`
 */
interface IERC721Metadata {
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