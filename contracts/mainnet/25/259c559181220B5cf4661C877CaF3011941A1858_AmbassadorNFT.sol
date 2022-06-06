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

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './token/ERC721Enumerable.sol';
import './token/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract AmbassadorNFT is ERC721Enumerable {
  using Base64 for *;
  using Strings for uint256;

  struct Base {
    string image; // base image
    address collection; // Drops dToken
  }

  /// @dev emit when new collection registered
  event CollectionRegistered(address collection, string name);

  /// @dev emit when base gets added or updated
  event BaseUpdated(uint256 index, Base base);

  /// @dev emit when base/votingWeight for ambassador being set
  event AmbassadorUpdated(uint256 tokenId, uint256 base, uint256 weight);

  uint128 public constant DEFAULT_WEIGHT = 3_000 * 1e18; // 3k

  string public constant DESCRIPTION =
    'The Ambassador NFT is a non-transferable token exclusively available to Drops DAO ambassadors. Each NFT provides veDOP voting power which is used in DAO governance process.';

  bool public initialized;

  /// @dev collection name mapped by collection address
  mapping(address => string) public collectionNames;

  /// @dev array of Bases
  Base[] public bases;

  /// @dev tokenId => base info
  /// top 128 bit = base_index
  /// bottom 128 bit = weight
  mapping(uint256 => uint256) public info;

  /// @dev baseURI
  string private baseURI;

  function initialize(string memory _baseURI) external {
    require(msg.sender == admin);
    require(!initialized);
    initialized = true;

    name = 'Drops DAO Ambassadors';
    symbol = 'DROPSAMB';

    baseURI = _baseURI;
  }

  /// @dev register collection name
  /// @param collection collection address
  /// @param name collection name
  function registerCollection(address collection, string calldata name) external onlyOwner {
    collectionNames[collection] = name;

    emit CollectionRegistered(collection, name);
  }

  /// @dev add new base
  /// @param image base image
  /// @param collection base collection
  function addBase(string calldata image, address collection) external onlyOwner {
    require(bytes(collectionNames[collection]).length > 0, 'addBase: Invalid collection');
    Base memory base = Base(image, collection);
    emit BaseUpdated(bases.length, base);
    bases.push(base);
  }

  /// @dev update base
  /// @param index base index
  /// @param image base image
  /// @param collection base collection
  function updateBase(
    uint256 index,
    string calldata image,
    address collection
  ) external onlyOwner {
    require(index < bases.length, 'updateBase: Invalid index');

    Base storage base = bases[index];
    base.image = image;
    base.collection = collection;

    emit BaseUpdated(index, base);
  }

  /// @dev return total number of bases
  /// @return uint256
  function totalBases() external view returns (uint256) {
    return bases.length;
  }

  /// @dev mint new NFT
  /// @param tokenId ambassador id
  /// @param to ambassador wallet
  /// @param base ambassador index
  function mintInternal(
    uint256 tokenId,
    address to,
    uint256 base
  ) internal {
    require(to != address(0), 'mint: Invalid to');
    require(base < bases.length, 'mint: Invalid base');

    // Mint new token
    info[tokenId] = (base << 128) | DEFAULT_WEIGHT;
    _mint(to, tokenId);

    emit AmbassadorUpdated(tokenId, base, DEFAULT_WEIGHT);
  }

  /// @dev mint new NFT
  /// @param tokenId ambassador id
  /// @param to ambassador wallet
  /// @param base ambassador index
  function mint(
    uint256 tokenId,
    address to,
    uint256 base
  ) public onlyOwner {
    mintInternal(tokenId, to, base);
  }

  /// @dev mint new NFTs
  /// @param tokenIds ambassador ids
  /// @param wallets ambassador wallets
  /// @param baseIndexes ambassador bases
  function mints(
    uint256[] calldata tokenIds,
    address[] calldata wallets,
    uint256[] calldata baseIndexes
  ) external onlyOwner {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      mintInternal(tokenIds[i], wallets[i], baseIndexes[i]);
    }
  }

  /// @dev update weight
  /// @param tokenId ambassador id
  /// @param weight ambassador weight
  function updateAmbWeight(uint256 tokenId, uint256 weight) external onlyOwner {
    require(ownerOf[tokenId] != address(0), 'updateWeight: Non-existent token');

    uint256 base = info[tokenId] >> 128;
    info[tokenId] = (base << 128) | weight;

    emit AmbassadorUpdated(tokenId, base, weight);
  }

  /// @dev update base
  /// @param tokenId ambassador id
  /// @param base ambassador base
  function updateAmbBase(uint256 tokenId, uint256 base) external onlyOwner {
    require(ownerOf[tokenId] != address(0), 'updateBase: Non-existent token');

    uint128 weight = uint128(info[tokenId]);
    info[tokenId] = (base << 128) | weight;

    emit AmbassadorUpdated(tokenId, base, weight);
  }

  /// @dev get ambassador
  /// @param tokenId ambassador id
  /// @return weight ambassador weight
  /// @return image ambassador image
  /// @return collection ambassador collection
  function getAmbassador(uint256 tokenId)
    public
    view
    returns (
      uint256 weight,
      string memory image,
      address collection
    )
  {
    require(ownerOf[tokenId] != address(0), 'getAmbassador: Non-existent token');

    uint256 base = info[tokenId];
    weight = uint128(base);
    base = base >> 128;
    image = bases[base].image;
    collection = bases[base].collection;
  }

  /// @dev burns FNT
  /// Only the owner can do this action
  /// @param tokenId tokenID of NFT to be burnt
  function burn(uint256 tokenId) external onlyOwner {
    _burn(tokenId);
  }

  /// @dev return tokenURI per tokenId
  /// @return tokenURI string
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(ownerOf[tokenId] != address(0), 'tokenURI: Non-existent token');

    (uint256 weight, string memory image, address collection) = getAmbassador(tokenId);

    string memory attributes = string(
      abi.encodePacked(
        '[{"trait_type":"Collection","value":"',
        collectionNames[collection],
        '"},{"display_type":"number","trait_type":"veDOP","value":',
        (weight / 1e18).toString(),
        '}]'
      )
    );

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              string(abi.encodePacked('Ambassador', ' #', tokenId.toString())),
              '","description":"',
              DESCRIPTION,
              '","image":"',
              string(abi.encodePacked(baseURI, image)),
              '","attributes":',
              attributes,
              '}'
            )
          )
        )
      );
  }

  /// @dev check if caller is owner
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override onlyOwner {
    // one wallet cannot hold more than 1 NFT
    require(balanceOf[to] == 0, 'transfer: Already an ambassador');
    ERC721Enumerable._beforeTokenTransfer(from, to, tokenId);
  }

  /// @dev See {IERC721-transferFrom}.
  /// clear approve or owner logic since admin will transfer NFTs without permissions from owner
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual override {
    // admin will transfer NFTs without approve
    _transfer(from, to, tokenId);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library Base64 {
  string private constant base64stdchars =
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return '';

    // load the table into memory
    string memory table = base64stdchars;

    // multiply by 4/3 rounded up
    uint256 encodedLen = 4 * ((data.length + 2) / 3);

    // add some extra buffer at the end required for the writing
    string memory result = new string(encodedLen + 32);

    assembly {
      // set the actual output length
      mstore(result, encodedLen)

      // prepare the lookup table
      let tablePtr := add(table, 1)

      // input ptr
      let dataPtr := data
      let endPtr := add(dataPtr, mload(data))

      // result ptr, jump over length
      let resultPtr := add(result, 32)

      // run over the input, 3 bytes at a time
      for {

      } lt(dataPtr, endPtr) {

      } {
        dataPtr := add(dataPtr, 3)

        // read 3 bytes
        let input := mload(dataPtr)

        // write 4 characters
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F)))))
        resultPtr := add(resultPtr, 1)
        mstore(resultPtr, shl(248, mload(add(tablePtr, and(input, 0x3F)))))
        resultPtr := add(resultPtr, 1)
      }

      // padding with '='
      switch mod(mload(data), 3)
      case 1 {
        mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
      }
      case 2 {
        mstore(sub(resultPtr, 1), shl(248, 0x3d))
      }
    }

    return result;
  }
}

// SPDX-License-Identifier: AGPL-3.0-only
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

/// @notice Modern and gas efficient ERC-721 + ERC-20/EIP-2612-like implementation,
/// including the MetaData, and partially, Enumerable extensions.
contract ERC721 {
  /*///////////////////////////////////////////////////////////////
                                  EVENTS
    //////////////////////////////////////////////////////////////*/

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

  event Approval(address indexed owner, address indexed spender, uint256 indexed tokenId);

  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /*///////////////////////////////////////////////////////////////
                             METADATA STORAGE
    //////////////////////////////////////////////////////////////*/

  address implementation_;
  address admin;

  string public name;
  string public symbol;

  /*///////////////////////////////////////////////////////////////
                             ERC-721 STORAGE
    //////////////////////////////////////////////////////////////*/

  mapping(address => uint256) public balanceOf;

  mapping(uint256 => address) public ownerOf;

  mapping(uint256 => address) public getApproved;

  mapping(address => mapping(address => bool)) public isApprovedForAll;

  /*///////////////////////////////////////////////////////////////
                             VIEW FUNCTION
    //////////////////////////////////////////////////////////////*/

  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  function owner() external view returns (address) {
    return admin;
  }

  /*///////////////////////////////////////////////////////////////
                              ERC-20-LIKE LOGIC
    //////////////////////////////////////////////////////////////*/

  function transfer(address to, uint256 tokenId) external {
    require(msg.sender == ownerOf[tokenId], "NOT_OWNER");

    _transfer(msg.sender, to, tokenId);
  }

  /*///////////////////////////////////////////////////////////////
                              ERC-721 LOGIC
    //////////////////////////////////////////////////////////////*/

  function supportsInterface(bytes4 interfaceId) external pure returns (bool supported) {
    // supported = interfaceId == 0x80ac58cd || interfaceId == 0x5b5e139f || interfaceId == 0x2a55205a;
    supported = true;
  }

  function approve(address spender, uint256 tokenId) external {
    address owner_ = ownerOf[tokenId];

    require(msg.sender == owner_ || isApprovedForAll[owner_][msg.sender], "NOT_APPROVED");

    getApproved[tokenId] = spender;

    emit Approval(owner_, spender, tokenId);
  }

  function setApprovalForAll(address operator, bool approved) external {
    isApprovedForAll[msg.sender][operator] = approved;

    emit ApprovalForAll(msg.sender, operator, approved);
  }

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) public virtual {
    require(
      msg.sender == from || msg.sender == getApproved[tokenId] || isApprovedForAll[from][msg.sender],
      "NOT_APPROVED"
    );

    _transfer(from, to, tokenId);
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external {
    safeTransferFrom(from, to, tokenId, "");
  }

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes memory data
  ) public {
    transferFrom(from, to, tokenId);

    if (to.code.length != 0) {
      try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, data) returns (bytes4 retval) {
        require(retval == IERC721Receiver.onERC721Received.selector);
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert("ERC721: transfer to non ERC721Receiver implementer");
        } else {
          assembly {
            revert(add(32, reason), mload(reason))
          }
        }
      }
    }
  }

  /*///////////////////////////////////////////////////////////////
                          INTERNAL UTILS
    //////////////////////////////////////////////////////////////*/

  function _transfer(
    address from,
    address to,
    uint256 tokenId
  ) internal {
    require(ownerOf[tokenId] == from);
    _beforeTokenTransfer(from, to, tokenId);

    balanceOf[from]--;
    balanceOf[to]++;

    delete getApproved[tokenId];

    ownerOf[tokenId] = to;
    emit Transfer(from, to, tokenId);

    _afterTokenTransfer(from, to, tokenId);
  }

  function _mint(address to, uint256 tokenId) internal {
    require(ownerOf[tokenId] == address(0), "ALREADY_MINTED");
    _beforeTokenTransfer(address(0), to, tokenId);

    // This is safe because the sum of all user
    // balances can't exceed type(uint256).max!
    unchecked {
      balanceOf[to]++;
    }

    ownerOf[tokenId] = to;

    emit Transfer(address(0), to, tokenId);

    _afterTokenTransfer(address(0), to, tokenId);
  }

  function _burn(uint256 tokenId) internal {
    address owner_ = ownerOf[tokenId];

    require(owner_ != address(0), "NOT_MINTED");
    _beforeTokenTransfer(owner_, address(0), tokenId);

    balanceOf[owner_]--;

    delete ownerOf[tokenId];

    emit Transfer(owner_, address(0), tokenId);

    _afterTokenTransfer(owner_, address(0), tokenId);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}

  function _afterTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/ERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "./ERC721.sol";

/**
 * @dev This implements an optional extension of {ERC721} defined in the EIP that adds
 * enumerability of all the token ids in the contract as well as all token ids owned by each
 * account.
 */
abstract contract ERC721Enumerable is ERC721 {
  // Mapping from owner to list of owned token IDs
  mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

  // Mapping from token ID to index of the owner tokens list
  mapping(uint256 => uint256) private _ownedTokensIndex;

  /**
   * @dev See {IERC721Enumerable-totalSupply}.
   */
  uint256 public totalSupply;

  /**
   * @dev See {IERC721Enumerable-tokenOfOwnerByIndex}.
   */
  function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual returns (uint256) {
    require(index < balanceOf[owner], "ERC721Enumerable: owner index out of bounds");
    return _ownedTokens[owner][index];
  }

  /**
   * @dev Hook that is called before any token transfer. This includes minting
   * and burning.
   *
   * Calling conditions:
   *
   * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
   * transferred to `to`.
   * - When `from` is zero, `tokenId` will be minted for `to`.
   * - When `to` is zero, ``from``'s `tokenId` will be burned.
   * - `from` cannot be the zero address.
   * - `to` cannot be the zero address.
   *
   * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual override {
    super._beforeTokenTransfer(from, to, tokenId);

    if (from == address(0)) {
      totalSupply++;
    } else if (from != to) {
      _removeTokenFromOwnerEnumeration(from, tokenId);
    }
    if (to == address(0)) {
      totalSupply--;
    } else if (to != from) {
      _addTokenToOwnerEnumeration(to, tokenId);
    }
  }

  /**
   * @dev Private function to add a token to this extension's ownership-tracking data structures.
   * @param to address representing the new owner of the given token ID
   * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
   */
  function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
    uint256 length = balanceOf[to];
    _ownedTokens[to][length] = tokenId;
    _ownedTokensIndex[tokenId] = length;
  }

  /**
   * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
   * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
   * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
   * This has O(1) time complexity, but alters the order of the _ownedTokens array.
   * @param from address representing the previous owner of the given token ID
   * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
   */
  function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
    // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
    // then delete the last slot (swap and pop).

    uint256 lastTokenIndex = balanceOf[from] - 1;
    uint256 tokenIndex = _ownedTokensIndex[tokenId];

    // When the token to delete is the last token, the swap operation is unnecessary
    if (tokenIndex != lastTokenIndex) {
      uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

      _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
      _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
    }

    // This also deletes the contents at the last position of the array
    delete _ownedTokensIndex[tokenId];
    delete _ownedTokens[from][lastTokenIndex];
  }
}