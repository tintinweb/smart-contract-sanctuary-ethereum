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

import '@openzeppelin/contracts/utils/Strings.sol';
import './token/ERC721Enumerable.sol';
import './token/Base64.sol';
import './utils/Vault.sol';
import './utils/TokenProxy.sol';
import './interfaces/IFlashLoan.sol';
import './interfaces/ICToken.sol';

contract Mortgage is ERC721Enumerable, Vault, IFlashLoanReceiver {
  using Base64 for *;
  using Strings for uint256;

  struct Data {
    uint256 tokenId;
    address[3] tokens; // [0] - borrowCToken, [1] - supplyCToken, [2] - supplyUnderlying
    uint256[] supplyTokenIds;
    uint256 ethValue;
  }

  bool public initialized;

  mapping(uint256 => TokenProxy) public proxies;

  IFlashLoanProvider public provider;
  Data data;

  function initialize(IFlashLoanProvider _provider) external {
    require(msg.sender == admin);
    require(!initialized);
    initialized = true;

    name = 'Drops Mortgage';
    symbol = 'DROPSMTG';

    provider = _provider;
  }

  function mint() public {
    uint256 tokenId = totalSupply + 1;
    TokenProxy proxy = new TokenProxy();
    proxies[tokenId] = proxy;
    _mint(msg.sender, tokenId);
  }

  function tokenURI(uint256 tokenId) public view returns (string memory) {
    require(ownerOf[tokenId] != address(0), 'tokenURI: Non-existent token');

    string memory attributes = string(
      abi.encodePacked('[{"trait_type":"Author","value":"Drops DAO"}]')
    );

    return
      string(
        abi.encodePacked(
          'data:application/json;base64,',
          Base64.encode(
            abi.encodePacked(
              '{"name":"',
              string(abi.encodePacked('Drops Mortgage', ' #', tokenId.toString())),
              '","description":"',
              'NFT Mortgage provided by Drops DAO',
              '","image":"',
              'https://ambassador.mypinata.cloud/ipfs/Qmf1z56YX8dPJKmC6VfQioxJrBFKPX3x9aMC2bbSqTcar5',
              '","attributes":',
              attributes,
              '}'
            )
          )
        )
      );
  }

  function mortgage(
    uint256 tokenId,
    address[3] calldata tokens,
    uint256[] calldata supplyTokenIds,
    address aggregator,
    uint256 value,
    bytes calldata trades
  ) external payable {
    require(data.tokenId == 0, 'Invalid entrance');
    require(ownerOf[tokenId] == msg.sender, 'Invalid access');

    data.tokenId = tokenId;
    data.tokens = tokens;
    data.supplyTokenIds = supplyTokenIds;
    data.ethValue = msg.value;
    provider.flashLoan(aggregator, value - msg.value, trades);
  }

  function onFlashLoanReceived(
    address aggregator,
    uint256 value,
    uint256 fee,
    bytes calldata trades
  ) external override {
    (bool success, ) = aggregator.call{value: (value + data.ethValue)}(trades);
    require(success, 'Invalid trades');

    ICERC721 supplyCToken = ICERC721(data.tokens[1]);
    IToken supplyUnderlying = IToken(data.tokens[2]);

    // Check ApprovalForAll
    if (!supplyUnderlying.isApprovedForAll(address(this), data.tokens[1])) {
      supplyUnderlying.setApprovalForAll(data.tokens[1], true);
    }

    // Supply Tokens
    supplyCToken.mints(data.supplyTokenIds);

    // Transfer cTokens
    TokenProxy proxy = proxies[data.tokenId];
    proxy.enterMarkets(supplyCToken);
    for (uint256 i = 0; i < data.supplyTokenIds.length; i++) {
      supplyCToken.transfer(address(proxy), 0);
    }

    // Borrow ETH
    uint256 repayAmount = value + fee;
    proxy.borrowETH(data.tokens[0], repayAmount);

    // Repay ETH
    payable(msg.sender).transfer(repayAmount);

    // return remaining ETH (if any)
    assembly {
      if gt(selfbalance(), 0) {
        let callStatus := call(gas(), caller(), selfbalance(), 0, 0, 0, 0)
      }
    }

    delete data.tokenId;
  }

  function claimNFTs(
    uint256 tokenId,
    address cToken,
    uint256[] calldata redeemTokenIndexes
  ) external {
    require(ownerOf[tokenId] == msg.sender, 'Invalid access');

    TokenProxy proxy = proxies[tokenId];
    proxy.claimNFTs(cToken, redeemTokenIndexes, msg.sender);
  }

  function claimCTokens(
    uint256 tokenId,
    address cToken,
    uint256 amount
  ) external {
    require(ownerOf[tokenId] == msg.sender, 'Invalid access');

    TokenProxy proxy = proxies[tokenId];
    proxy.claimCTokens(cToken, amount, msg.sender);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IComptroller {
  function enterMarkets(address[] memory cTokens) external returns (uint256[] memory);
}

interface ICEther {
  function borrow(uint256 borrowAmount) external returns (uint256);
}

interface ICERC721 {
  function mints(uint256[] calldata tokenIds) external returns (uint256[] memory);

  function transfer(address dst, uint256 amount) external returns (bool);

  function userTokens(address user, uint256 index) external view returns (uint256);

  function redeems(uint256[] calldata redeemTokenIds) external returns (uint256[] memory);

  function underlying() external view returns (address);

  function comptroller() external view returns (IComptroller);
}

interface IUnderlying {
  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IFlashLoanProvider {
  function flashLoan(
    address aggregator,
    uint256 value,
    bytes calldata trades
  ) external;
}

interface IFlashLoanReceiver {
  function onFlashLoanReceived(
    address aggregator,
    uint256 value,
    uint256 fee,
    bytes calldata trades
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ICToken.sol';

interface ITokenProxy {
  // Enter Markets
  function enterMarkets(ICERC721 cToken) external returns(uint256[] memory);

  // Borrow ETH
  function borrowETH(address cToken, uint256 amount) external;

  // Claim NFTs
  function claimNFTs(
    address cToken,
    uint256[] calldata redeemTokenIndexes,
    address to
  ) external;

  // Claim cToken
  function claimCTokens(
    address cToken,
    uint256 amount,
    address to
  ) external;
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

  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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
                             OWNER FUNCTION
    //////////////////////////////////////////////////////////////*/

  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  function owner() external view returns (address) {
    return admin;
  }

  function transferOwnership(address newOwner) external onlyOwner {
    admin = newOwner;

    emit OwnershipTransferred(msg.sender, newOwner);
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../utils/Vault.sol';
import '../interfaces/ITokenProxy.sol';
import '../interfaces/ICToken.sol';

contract TokenProxy is Vault, ITokenProxy {
  address admin;

  constructor() {
    admin = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == admin);
    _;
  }

  // Enter Markets
  function enterMarkets(ICERC721 supplyCToken) external override returns(uint256[] memory) {
    address[] memory cTokens = new address[](1);
    cTokens[0] = address(supplyCToken);
    return supplyCToken.comptroller().enterMarkets(cTokens);
  }

  // Borrow ETH
  function borrowETH(address cToken, uint256 amount) external override onlyOwner {
    ICEther(cToken).borrow(amount);
    payable(admin).transfer(amount);
  }

  // Claim NFT
  function claimNFTs(
    address cToken,
    uint256[] calldata redeemTokenIndexes,
    address to
  ) external override onlyOwner {
    uint256 amount = redeemTokenIndexes.length;
    uint256[] memory tokenIds = new uint256[](amount);

    ICERC721 supplyCToken = ICERC721(cToken);
    address _this = address(this);
    for (uint256 i = 0; i < amount; i++) {
      tokenIds[i] = supplyCToken.userTokens(_this, redeemTokenIndexes[i]);
    }

    supplyCToken.redeems(redeemTokenIndexes);

    IUnderlying underlying = IUnderlying(supplyCToken.underlying());
    for (uint256 i = 0; i < amount; i++) {
      underlying.transferFrom(_this, to, tokenIds[i]);
    }
  }

  // Claim cToken
  function claimCTokens(
    address cToken,
    uint256 amount,
    address to
  ) external override onlyOwner {
    ICERC721 supplyCToken = ICERC721(cToken);
    for (uint256 i = 0; i < amount; i++) {
      supplyCToken.transfer(to, 0);
    }
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IToken {
  function balanceOf(address account) external view returns (uint256);

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external payable;

  function safeTransferFrom(
    address from,
    address to,
    uint256 id,
    uint256 amount,
    bytes memory data
  ) external;

  function isApprovedForAll(address owner, address spender) external view returns (bool);

  function setApprovalForAll(address operator, bool approved) external;
}

contract Vault {
  function onERC1155Received(
    address,
    address,
    uint256,
    uint256,
    bytes calldata
  ) public virtual returns (bytes4) {
    return this.onERC1155Received.selector;
  }

  function onERC1155BatchReceived(
    address,
    address,
    uint256[] calldata,
    uint256[] calldata,
    bytes calldata
  ) public virtual returns (bytes4) {
    return this.onERC1155BatchReceived.selector;
  }

  function onERC721Received(
    address,
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return 0x150b7a02;
  }

  // Used by ERC721BasicToken.sol
  function onERC721Received(
    address,
    uint256,
    bytes calldata
  ) external virtual returns (bytes4) {
    return 0xf0b9e5ba;
  }

  receive() external payable {}
}