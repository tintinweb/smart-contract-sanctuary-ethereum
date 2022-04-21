// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";

// Some code are originally from https://etherscan.io/address/0xbad6186e92002e312078b5a1dafd5ddf63d3f731#code
library BeachLibrary {
  string internal constant TABLE =
  "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  function encode(bytes memory data) internal pure returns (string memory) {
    if (data.length == 0) return "";

    // load the table into memory
    string memory table = TABLE;

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
        mstore(
        resultPtr,
        shl(248, mload(add(tablePtr, and(shr(18, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
        resultPtr,
        shl(248, mload(add(tablePtr, and(shr(12, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
        resultPtr,
        shl(248, mload(add(tablePtr, and(shr(6, input), 0x3F))))
        )
        resultPtr := add(resultPtr, 1)
        mstore(
        resultPtr,
        shl(248, mload(add(tablePtr, and(input, 0x3F))))
        )
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

  function isContract(address account) internal view returns (bool) {
    // This method relies on extcodesize, which returns 0 for contracts in
    // construction, since the code is only stored at the end of the
    // constructor execution.

    uint256 size;
    assembly {
      size := extcodesize(account)
    }
    return size > 0;
  }

  function validateName(string memory str) public pure returns (bool){
    bytes memory b = bytes(str);
    if (b.length < 1) return false;
    if (b.length > 25) return false;
    // Cannot be longer than 25 characters
    if (b[0] == 0x20) return false;
    // Leading space
    if (b[b.length - 1] == 0x20) return false;
    // Trailing space

    bytes1 lastChar = b[0];

    for (uint i; i < b.length; i++) {
      bytes1 char = b[i];

      if (char == 0x20 && lastChar == 0x20) return false;
      // Cannot contain continuous spaces

      if (
        !(char >= 0x30 && char <= 0x39) && //9-0
      !(char >= 0x41 && char <= 0x5A) && //A-Z
      !(char >= 0x61 && char <= 0x7A) && //a-z
      !(char == 0x20) //space
      )
        return false;

      lastChar = char;
    }

    return true;
  }

  /**
  * @dev Converts the string to lowercase
	 */
  function toLower(string memory str) internal pure returns (string memory){
    bytes memory bStr = bytes(str);
    bytes memory bLower = new bytes(bStr.length);
    for (uint i = 0; i < bStr.length; i++) {
      // Uppercase character
      if ((uint8(bStr[i]) >= 65) && (uint8(bStr[i]) <= 90)) {
        bLower[i] = bytes1(uint8(bStr[i]) + 32);
      } else {
        bLower[i] = bStr[i];
      }
    }
    return string(bLower);
  }

  /**
   * @dev Converts the dictionary into metadata and returns the Token URI JSON
   */
  function dictToMetadata(uint tokenId_, string[] memory TRAITS_, string[] memory DICT_, mapping(uint256 => uint16[8]) storage beachMetadata_)
  public
  view
  returns (string memory)
  {
    string memory metadataString;

    for (uint8 i = 0; i < beachMetadata_[tokenId_].length; i++) {
      metadataString = string(
        abi.encodePacked(
          metadataString,
          '{"trait_type":"',
          TRAITS_[i],
          '","value":"',
          DICT_[beachMetadata_[tokenId_][i]],
          '"}'
        )
      );

      if (i < beachMetadata_[tokenId_].length - 1)
        metadataString = string(abi.encodePacked(metadataString, ","));
    }

    return string(abi.encodePacked("[", metadataString, "]"));
  }

  function getImagePath(uint tokenId_, bool revealed_, string memory baseURIPath_, string memory revealedPath_, string memory placeHolderURI_, bool small_) public view returns (bytes memory) {
    return revealed_ ?
    abi.encodePacked('"image', small_ ? '' : '_large', '": "', baseURIPath_, revealedPath_, '/', toString(tokenId_), small_ ? '.png",' : '_large.png",') :
    abi.encodePacked('"image', small_ ? '' : '_large', '": "', baseURIPath_, placeHolderURI_, '",');
  }

  function buildTokenURI(
    uint tokenId_,
    string memory beachName_,
    bytes memory smallImagePath_,
    bytes memory bigImagePath_,
    string memory attributes_
  ) public view returns (string memory) {
    return
    string(
      abi.encodePacked(
        "data:application/json;base64,",
        encode(
          bytes(
            string(
              abi.encodePacked(
                abi.encodePacked('{"name": "', beachName_, '",'),
                '"description": "What\'s the ocean if not Mother Nature\'s generative art? B34CH is procedurally formed by code. The varieties of waves, particles, colors, textures, sizes combine to create digital representations of realistic and surreal beaches.", ',
                '"token_id": ', toString(tokenId_), ', ',
                smallImagePath_,
                bigImagePath_,
                '"attributes":',
                attributes_,
                "}"
              )
            )
          )
        )
      )
    );
  }

  function buildContractURI(address beach_) public view returns (string memory) {
    return
    string(
      abi.encodePacked(
        "data:application/json;base64,",
        encode(
          bytes(
            string(
              abi.encodePacked(
                abi.encodePacked(
                  '{',
                  '"name": "B34CH DAO",',
                  '"description": "What\'s the ocean if not Mother Nature\'s generative art? B34CH is procedurally formed by code. The varieties of waves, particles, colors, textures, sizes combine to create digital representations of realistic and surreal beaches.",',
                  '"image": "https://b34ch.page.link/opensea_cover",',
                  '"external_link": "https://b34ch.xyz",',
                  '"seller_fee_basis_points": 1000,',
                  '"fee_recipient": "', addressToString(beach_), '"',
                  '}'
                )
              )
            )
          )
        )
      )
    );
  }

  function walletOfOwner(address wallet_, address creed_)
  public
  view
  returns (uint256[] memory)
  {
    uint256 tokenCount = IERC721Enumerable(creed_).balanceOf(wallet_);

    uint256[] memory tokensId = new uint256[](tokenCount);
    for (uint256 i; i < tokenCount; i++) {
      tokensId[i] = IERC721Enumerable(creed_).tokenOfOwnerByIndex(wallet_, i);
    }
    return tokensId;
  }

  function addressToString(address account) public pure returns (string memory) {
    return bytesToString(abi.encodePacked(account));
  }

  function bytesToString(bytes memory data) public pure returns (string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
      str[2 + i * 2] = alphabet[uint(uint8(data[i] >> 4))];
      str[3 + i * 2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/extensions/IERC721Enumerable.sol";

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