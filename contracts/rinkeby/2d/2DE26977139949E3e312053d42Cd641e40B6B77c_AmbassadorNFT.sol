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

import './token/ERC721.sol';
import './token/Base64.sol';
import '@openzeppelin/contracts/utils/Strings.sol';

contract AmbassadorNFT is ERC721 {
  using Base64 for *;
  using Strings for uint256;

  struct Base {
    string image; // base image
    address pool; // unitroller
  }

  /// @dev emit when base gets added or updated
  event PoolRegistered(address pool, string name);

  /// @dev emit when base gets added or updated
  event BaseUpdated(uint256 index, Base base);

  /// @dev emit when base/votingWeight for ambassador being set
  event AmbassadorUpdated(uint256 tokenId, uint256 base, uint256 weight);

  uint128 public constant DEFAULT_WEIGHT = 3_000 * 1e18; // 3k

  string public constant DESCRIPTION =
    'The Ambassador NFT is a non-transferable token exclusively available to Drops DAO ambassadors. Each NFT provides veDOP voting power which is used in DAO governance process.';

  bool public initialized;

  /// @dev max supply & total supply
  uint256 public maxSupply;
  uint256 public totalSupply;

  /// @dev pool name mapped by pool address
  mapping(address => string) public poolNames;

  /// @dev array of Bases
  Base[] public bases;

  /// @dev tokenId => base info
  /// top 128 bit = base_index
  /// bottom 128 bit = weight
  mapping(uint256 => uint256) public info;

  /// @dev baseURI
  string private baseURI;

  function initialize(uint256 _maxSupply, string memory _baseURI) external {
    require(msg.sender == admin);
    require(!initialized);
    initialized = true;

    name = 'Drops Ambassador';
    symbol = 'AMB';

    maxSupply = _maxSupply;
    baseURI = _baseURI;
  }

  /// @dev register pool name
  /// @param pool pool address
  /// @param name pool name
  function registerPool(address pool, string calldata name) external onlyOwner {
    poolNames[pool] = name;

    emit PoolRegistered(pool, name);
  }

  /// @dev add new base
  /// @param image base image
  /// @param pool base pool
  function addBase(string calldata image, address pool) external onlyOwner {
    require(bytes(poolNames[pool]).length > 0, 'addBase: Invalid pool');
    Base memory base = Base(image, pool);
    emit BaseUpdated(bases.length, base);
    bases.push(base);
  }

  /// @dev update base
  /// @param index base index
  /// @param image base image
  /// @param pool base pool
  function updateBase(
    uint256 index,
    string calldata image,
    address pool
  ) external onlyOwner {
    require(index < bases.length, 'updateBase: Invalid index');

    Base storage base = bases[index];
    base.image = image;
    base.pool = pool;

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
    require(tokenId <= maxSupply, 'mint: Override Max Supply');
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
    totalSupply++;
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
    totalSupply += tokenIds.length;
  }

  /// @dev update weight
  /// @param tokenId ambassador id
  /// @param weight ambassador weight
  function updateWeight(uint256 tokenId, uint256 weight) external onlyOwner {
    require(ownerOf[tokenId] != address(0), 'updateWeight: Non-existent token');

    uint256 base = info[tokenId] >> 128;
    info[tokenId] = (base << 128) | weight;

    emit AmbassadorUpdated(tokenId, base, weight);
  }

  /// @dev update base
  /// @param tokenId ambassador id
  /// @param base ambassador base
  function updateBase(uint256 tokenId, uint256 base) external onlyOwner {
    require(ownerOf[tokenId] != address(0), 'updateBase: Non-existent token');

    uint128 weight = uint128(info[tokenId]);
    info[tokenId] = (base << 128) | weight;

    emit AmbassadorUpdated(tokenId, base, weight);
  }

  /// @dev get ambassador
  /// @param tokenId ambassador id
  /// @return weight ambassador weight
  /// @return image ambassador image
  /// @return pool ambassador pool
  function getAmbassador(uint256 tokenId)
    public
    view
    returns (
      uint256 weight,
      string memory image,
      address pool
    )
  {
    require(ownerOf[tokenId] != address(0), 'getAmbassador: Non-existent token');

    uint256 base = info[tokenId];
    weight = uint128(base);
    base = base >> 128;
    image = bases[base].image;
    pool = bases[base].pool;
  }

  /// @dev burns FNT
  /// Only the owner can do this action
  /// @param tokenId tokenID of NFT to be burnt
  function burn(uint256 tokenId) external onlyOwner {
    _burn(tokenId);
    totalSupply--;
  }

  /// @dev return tokenURI per tokenId
  /// @return tokenURI string
  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(ownerOf[tokenId] != address(0), 'tokenURI: Non-existent token');

    (uint256 weight, string memory image, address pool) = getAmbassador(tokenId);

    string memory attributes = string(
      abi.encodePacked(
        '[{"trait_type":"Pool","value":"',
        poolNames[pool],
        '"},{"display_type":"number","trait_type":"Weight","value":',
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
    address,
    address to,
    uint256
  ) internal virtual override onlyOwner {
    // one wallet cannot hold more than 1 NFT
    require(balanceOf[to] == 0, 'transfer: Already an base');
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