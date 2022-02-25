// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "sol-temple/src/tokens/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/// @title Tejiverse
/// @author naomsa <https://twitter.com/naomsa666>
/// @author Teji <https://twitter.com/0xTeji>
contract Tejiverse is Ownable, ERC721 {
  using Strings for uint256;
  using ECDSA for bytes32;

  /* -------------------------------------------------------------------------- */
  /*                                Token Details                               */
  /* -------------------------------------------------------------------------- */

  /// @notice Max supply.
  uint256 public constant TEJI_MAX = 1000;

  /* -------------------------------------------------------------------------- */
  /*                              Metadata Details                              */
  /* -------------------------------------------------------------------------- */

  /// @notice Unrevealed metadata URI.
  string public unrevealedURI;

  /// @notice Metadata base URI.
  string public baseURI;

  /* -------------------------------------------------------------------------- */
  /*                             Marketplace Details                            */
  /* -------------------------------------------------------------------------- */

  /// @notice OpenSea proxy registry.
  address public opensea;

  /// @notice LooksRare marketplace transfer manager.
  address public looksrare;

  /// @notice Check if marketplaces pre-approve is enabled.
  bool public marketplacesApproved;

  /* -------------------------------------------------------------------------- */
  /*                                Sale Details                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Whitelist verified signer address.
  address public signer;

  /// @notice 0 = CLOSED, 1 = WHITELIST, 2 = PUBLIC.
  uint256 public saleState;

  /// @notice address => has minted on presale.
  mapping(address => bool) internal _boughtPresale;

  constructor(string memory newUnrevealedURI, address newSigner) ERC721("Tejiverse", "TEJI") {
    unrevealedURI = newUnrevealedURI;
    signer = newSigner;

    marketplacesApproved = true;
    opensea = 0xa5409ec958C83C3f309868babACA7c86DCB077c1;
    looksrare = 0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e;
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Sale Logic                                 */
  /* -------------------------------------------------------------------------- */

  /// @notice Claim one teji.
  function claim() external {
    uint256 supply = totalSupply;
    require(supply < TEJI_MAX, "Tejiverse: max supply exceeded");
    if (msg.sender != owner()) {
      require(saleState == 2, "Tejiverse: public sale is not open");
    }

    _safeMint(msg.sender, supply);
  }

  /// @notice Claim one teji with whitelist proof.
  /// @param signature Whitelist proof signature.
  function claimWhitelist(bytes memory signature) external {
    uint256 supply = totalSupply;
    require(supply < TEJI_MAX, "Tejiverse: max supply exceeded");
    require(saleState == 1, "Tejiverse: whitelist sale is not open");
    require(!_boughtPresale[msg.sender], "Tejiverse: already claimed");

    bytes32 digest = keccak256(abi.encodePacked(address(this), msg.sender));
    require(digest.toEthSignedMessageHash().recover(signature) == signer, "Tejiverse: invalid signature");

    _boughtPresale[msg.sender] = true;
    _safeMint(msg.sender, supply);
  }

  /* -------------------------------------------------------------------------- */
  /*                                 Owner Logic                                */
  /* -------------------------------------------------------------------------- */

  /// @notice Set unrevealedURI to `newUnrevealedURI`.
  /// @param newUnrevealedURI New unrevealed uri.
  function setUnrevealedURI(string memory newUnrevealedURI) external onlyOwner {
    unrevealedURI = newUnrevealedURI;
  }

  /// @notice Set baseURI to `newBaseURI`.
  /// @param newBaseURI New base uri.
  function setBaseURI(string memory newBaseURI) external onlyOwner {
    baseURI = newBaseURI;
    delete unrevealedURI;
  }

  /// @notice Set `saleState` to `newSaleState`.
  /// @param newSaleState New sale state.
  function setSaleState(uint256 newSaleState) external onlyOwner {
    saleState = newSaleState;
  }

  /// @notice Set `signer` to `newSigner`.
  /// @param newSigner New whitelist signer address.
  function setSigner(address newSigner) external onlyOwner {
    signer = newSigner;
  }

  /// @notice Set `opensea` to `newOpensea` and `looksrare` to `newLooksrare`.
  /// @param newOpensea Opensea's proxy registry contract address.
  /// @param newLooksrare Looksrare's transfer manager contract address.
  function setMarketplaces(address newOpensea, address newLooksrare) external onlyOwner {
    opensea = newOpensea;
    looksrare = newLooksrare;
  }

  /// @notice Toggle pre-approve feature state for sender.
  function toggleMarketplacesApproved() external onlyOwner {
    marketplacesApproved = !marketplacesApproved;
  }

  /* -------------------------------------------------------------------------- */
  /*                                ERC-721 Logic                               */
  /* -------------------------------------------------------------------------- */

  /// @notice See {ERC721-tokenURI}.
  function tokenURI(uint256 id) public view override returns (string memory) {
    require(_exists(id), "ERC721Metadata: query for nonexisting token");

    if (bytes(unrevealedURI).length > 0) return unrevealedURI;
    return string(abi.encodePacked(baseURI, id.toString()));
  }

  /// @notice See {ERC721-isApprovedForAll}.
  /// @dev Modified for opensea and looksrare pre-approve so users can make truly gasless sales.
  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    if (!marketplacesApproved) return super.isApprovedForAll(owner, operator);

    return
      operator == address(ProxyRegistry(opensea).proxies(owner)) ||
      operator == looksrare ||
      super.isApprovedForAll(owner, operator);
  }
}

contract OwnableDelegateProxy {}

contract ProxyRegistry {
  mapping(address => OwnableDelegateProxy) public proxies;
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

/**
 * @title ERC721
 * @author naomsa <https://twitter.com/naomsa666>
 * @notice A complete ERC721 implementation including metadata and enumerable
 * functions. Completely gas optimized and extensible.
 */
abstract contract ERC721 is IERC165, IERC721, IERC721Metadata, IERC721Enumerable {
  /*         _           _            */
  /*        ( )_        ( )_          */
  /*    ___ | ,_)   _ _ | ,_)   __    */
  /*  /',__)| |   /'__` )| |   /'__`\  */
  /*  \__, \| |_ ( (_| || |_ (  ___/  */
  /*  (____/`\__)`\__,_)`\__)`\____)  */

  /// @notice See {ERC721Metadata-name}.
  string public name;

  /// @notice See {ERC721Metadata-symbol}.
  string public symbol;

  /// @notice See {ERC721Enumerable-totalSupply}.
  uint256 public totalSupply;

  /// @notice Array of all owners.
  address[] private _owners;

  /// @notice Mapping of all balances.
  mapping(address => uint256) private _balanceOf;

  /// @notice Mapping from token Id to it's approved address.
  mapping(uint256 => address) private _tokenApprovals;

  /// @notice Mapping of approvals between owner and operator.
  mapping(address => mapping(address => bool)) private _isApprovedForAll;

  /*   _                            */
  /*  (_ )                _         */
  /*   | |    _      __  (_)   ___  */
  /*   | |  /'_`\  /'_ `\| | /'___) */
  /*   | | ( (_) )( (_) || |( (___  */
  /*  (___)`\___/'`\__  |(_)`\____) */
  /*              ( )_) |           */
  /*               \___/'           */

  constructor(string memory name_, string memory symbol_) {
    name = name_;
    symbol = symbol_;
  }

  /// @notice See {ERC721-balanceOf}.
  function balanceOf(address account_) public view virtual returns (uint256) {
    require(account_ != address(0), "ERC721: balance query for the zero address");
    return _balanceOf[account_];
  }

  /// @notice See {ERC721-ownerOf}.
  function ownerOf(uint256 tokenId_) public view virtual returns (address) {
    require(_exists(tokenId_), "ERC721: query for nonexistent token");
    address owner = _owners[tokenId_];
    return owner;
  }

  /// @notice See {ERC721Metadata-tokenURI}.
  function tokenURI(uint256) public view virtual returns (string memory);

  /// @notice See {ERC721-approve}.
  function approve(address to_, uint256 tokenId_) public virtual {
    address owner = ownerOf(tokenId_);
    require(to_ != owner, "ERC721: approval to current owner");

    require(
      msg.sender == owner || _isApprovedForAll[owner][msg.sender],
      "ERC721: caller is not owner nor approved for all"
    );

    _approve(to_, tokenId_);
  }

  /// @notice See {ERC721-getApproved}.
  function getApproved(uint256 tokenId_) public view virtual returns (address) {
    require(_exists(tokenId_), "ERC721: query for nonexistent token");
    return _tokenApprovals[tokenId_];
  }

  /// @notice See {ERC721-setApprovalForAll}.
  function setApprovalForAll(address operator_, bool approved_) public virtual {
    _setApprovalForAll(msg.sender, operator_, approved_);
  }

  /// @notice See {ERC721-isApprovedForAll}.
  function isApprovedForAll(address account_, address operator_) public view virtual returns (bool) {
    return _isApprovedForAll[account_][operator_];
  }

  /// @notice See {ERC721-transferFrom}.
  function transferFrom(
    address from_,
    address to_,
    uint256 tokenId_
  ) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId_), "ERC721: transfer caller is not owner nor approved");
    _transfer(from_, to_, tokenId_);
  }

  /// @notice See {ERC721-safeTransferFrom}.
  function safeTransferFrom(
    address from_,
    address to_,
    uint256 tokenId_
  ) public virtual {
    safeTransferFrom(from_, to_, tokenId_, "");
  }

  /// @notice See {ERC721-safeTransferFrom}.
  function safeTransferFrom(
    address from_,
    address to_,
    uint256 tokenId_,
    bytes memory data_
  ) public virtual {
    require(_isApprovedOrOwner(msg.sender, tokenId_), "ERC721: transfer caller is not owner nor approved");
    _safeTransfer(from_, to_, tokenId_, data_);
  }

  /// @notice See {ERC721Enumerable.tokenOfOwnerByIndex}.
  function tokenOfOwnerByIndex(address account_, uint256 index_) public view returns (uint256 tokenId) {
    require(index_ < balanceOf(account_), "ERC721Enumerable: Index out of bounds");
    uint256 count;
    for (uint256 i; i < _owners.length; ++i) {
      if (account_ == _owners[i]) {
        if (count == index_) return i;
        else count++;
      }
    }
    revert("ERC721Enumerable: Index out of bounds");
  }

  /// @notice See {ERC721Enumerable.tokenByIndex}.
  function tokenByIndex(uint256 index_) public view virtual returns (uint256) {
    require(index_ < _owners.length, "ERC721Enumerable: Index out of bounds");
    return index_;
  }

  /// @notice Returns a list of all token Ids owned by `owner`.
  function walletOfOwner(address account_) public view returns (uint256[] memory) {
    uint256 balance = balanceOf(account_);
    uint256[] memory ids = new uint256[](balance);

    for (uint256 i = 0; i < balance; i++) ids[i] = tokenOfOwnerByIndex(account_, i);
    return ids;
  }

  /*             _                               _    */
  /*   _        ( )_                            (_ )  */
  /*  (_)  ___  | ,_)   __   _ __   ___     _ _  | |  */
  /*  | |/' _ `\| |   /'__`\( '__)/' _ `\ /'__` ) | |  */
  /*  | || ( ) || |_ (  ___/| |   | ( ) |( (_| | | |  */
  /*  (_)(_) (_)`\__)`\____)(_)   (_) (_)`\__,_)(___) */

  /**
   * @notice Safely transfers `tokenId_` token from `from_` to `to`, checking first that contract recipients
   * are aware of the ERC721 protocol to prevent tokens from being forever locked.
   */
  function _safeTransfer(
    address from_,
    address to_,
    uint256 tokenId_,
    bytes memory data_
  ) internal virtual {
    _transfer(from_, to_, tokenId_);
    _checkOnERC721Received(from_, to_, tokenId_, data_);
  }

  /// @notice Returns whether `tokenId_` exists.
  function _exists(uint256 tokenId_) internal view virtual returns (bool) {
    return tokenId_ < _owners.length && _owners[tokenId_] != address(0);
  }

  /// @notice Returns whether `spender_` is allowed to manage `tokenId`.
  function _isApprovedOrOwner(address spender_, uint256 tokenId_) internal view virtual returns (bool) {
    require(_exists(tokenId_), "ERC721: query for nonexistent token");
    address owner = _owners[tokenId_];
    return (spender_ == owner || getApproved(tokenId_) == spender_ || isApprovedForAll(owner, spender_));
  }

  /// @notice Safely mints `tokenId_` and transfers it to `to`.
  function _safeMint(address to_, uint256 tokenId_) internal virtual {
    _safeMint(to_, tokenId_, "");
  }

  /**
   * @notice Same as {_safeMint}, but with an additional `data_` parameter which is
   * forwarded in {ERC721Receiver-onERC721Received} to contract recipients.
   */
  function _safeMint(
    address to_,
    uint256 tokenId_,
    bytes memory data_
  ) internal virtual {
    _mint(to_, tokenId_);
    _checkOnERC721Received(address(0), to_, tokenId_, data_);
  }

  /// @notice Mints `tokenId_` and transfers it to `to_`.
  function _mint(address to_, uint256 tokenId_) internal virtual {
    require(!_exists(tokenId_), "ERC721: token already minted");

    _beforeTokenTransfer(address(0), to_, tokenId_);

    _owners.push(to_);
    totalSupply++;
    unchecked {
      _balanceOf[to_]++;
    }

    emit Transfer(address(0), to_, tokenId_);
    _afterTokenTransfer(address(0), to_, tokenId_);
  }

  /// @notice Destroys `tokenId`. The approval is cleared when the token is burned.
  function _burn(uint256 tokenId_) internal virtual {
    address owner = ownerOf(tokenId_);

    _beforeTokenTransfer(owner, address(0), tokenId_);

    // Clear approvals
    _approve(address(0), tokenId_);
    delete _owners[tokenId_];
    totalSupply--;
    _balanceOf[owner]--;

    emit Transfer(owner, address(0), tokenId_);
    _afterTokenTransfer(owner, address(0), tokenId_);
  }

  /// @notice Transfers `tokenId_` from `from_` to `to`.
  function _transfer(
    address from_,
    address to_,
    uint256 tokenId_
  ) internal virtual {
    require(_owners[tokenId_] == from_, "ERC721: transfer of token that is not own");

    _beforeTokenTransfer(from_, to_, tokenId_);

    // Clear approvals from the previous owner
    _approve(address(0), tokenId_);

    _owners[tokenId_] = to_;
    unchecked {
      _balanceOf[from_]--;
      _balanceOf[to_]++;
    }

    emit Transfer(from_, to_, tokenId_);
    _afterTokenTransfer(from_, to_, tokenId_);
  }

  /// @notice Approve `to_` to operate on `tokenId_`
  function _approve(address to_, uint256 tokenId_) internal virtual {
    _tokenApprovals[tokenId_] = to_;
    emit Approval(_owners[tokenId_], to_, tokenId_);
  }

  /// @notice Approve `operator_` to operate on all of `account_` tokens.
  function _setApprovalForAll(
    address account_,
    address operator_,
    bool approved_
  ) internal virtual {
    require(account_ != operator_, "ERC721: approve to caller");
    _isApprovedForAll[account_][operator_] = approved_;
    emit ApprovalForAll(account_, operator_, approved_);
  }

  /// @notice ERC721Receiver callback checking and calling helper.
  function _checkOnERC721Received(
    address from_,
    address to_,
    uint256 tokenId_,
    bytes memory data_
  ) private {
    if (to_.code.length > 0) {
      try IERC721Receiver(to_).onERC721Received(msg.sender, from_, tokenId_, data_) returns (bytes4 returned) {
        require(returned == 0x150b7a02, "ERC721: safe transfer to non ERC721Receiver implementation");
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: safe transfer to non ERC721Receiver implementation");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  /// @notice Hook that is called before any token transfer.
  function _beforeTokenTransfer(
    address from_,
    address to_,
    uint256 tokenId_
  ) internal virtual {}

  /// @notice Hook that is called after any token transfer.
  function _afterTokenTransfer(
    address from_,
    address to_,
    uint256 tokenId_
  ) internal virtual {}

  /*    ___  _   _  _ _      __   _ __  */
  /*  /',__)( ) ( )( '_`\  /'__`\( '__) */
  /*  \__, \| (_) || (_) )(  ___/| |    */
  /*  (____/`\___/'| ,__/'`\____)(_)    */
  /*               | |                  */
  /*               (_)                  */

  /// @notice See {ERC165-supportsInterface}.
  function supportsInterface(bytes4 interfaceId_) public view virtual returns (bool) {
    return
      interfaceId_ == type(IERC721).interfaceId || // ERC721
      interfaceId_ == type(IERC721Metadata).interfaceId || // ERC721Metadata
      interfaceId_ == type(IERC721Enumerable).interfaceId || // ERC721Enumerable
      interfaceId_ == type(IERC165).interfaceId; // ERC165
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
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