// SPDX-License-Identifier: MIT

////   //////////          //////////////        /////////////////          //////////////
////          /////      /////        /////      ////          /////      /////        /////
////            ///     ////            ////     ////            ////    ////            ////
////           ////     ////            ////     ////            ////    ////            ////
//////////////////      ////            ////     ////            ////    ////            ////
////                    ////     ///    ////     ////            ////    ////     ///    ////
////      ////          ////     /////  ////     ////            ////    ////     /////  ////
////        ////        ////       /////////     ////            ////    ////       /////////
////         /////       /////       //////      ////          /////      /////       //////
////           /////       ////////    ////      ////   //////////          ////////    ////

pragma solidity ^0.8.0;

import "./Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./IERC721Dispatcher.sol";
import "./IERC721Delegable.sol";

/**
 * @title RQDQURI
 * @dev Render library for tokenURI of RQDQ sDQ tokens.
 * @author 0xAnimist (kanon.art)
 */
library RQDQURI {

  function packSVG(uint256 _tokenId) public pure returns(string memory) {
    string[9] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base {fill: rgb(40,40,40); font-family: "Helvetica", Arial, sans-serif;} .firstLevel { font-size: 14px;} .secondLevel {font-size: 8px; line-height: 10px;}</style><rect width="100%" height="100%" fill="WhiteSmoke" /><text x="10" y="25" class="base firstLevel">RQDQ token # ';

        parts[1] = Strings.toString(_tokenId);

        parts[2] = '</text><text x="10" y="40" class="base secondLevel">';

        parts[3] = 'See description for redemption chain';

        parts[4] = '</text></svg>';

        return string(abi.encodePacked(parts[0], parts[1], parts[2], parts[3], parts[4]));
  }

  function packName(uint256 _tokenId) public pure returns(string memory) {
    return string(abi.encodePacked('"name": "RQDQ token #', Strings.toString(_tokenId), '",'));
  }

  function packDescription(address _RQContract, address _DQContract, uint256 _RQTokenId, uint256 _DQTokenId, uint256 _tokenId) public pure returns(string memory) {
    string[8] memory description;
    description[0] = '"description": "This RQDQ token is redeemable for token #';
    description[1] = Strings.toString(_DQTokenId);
    description[2] = ' of the NFT contract at ';
    description[3] = toString(_DQContract);
    description[4] = ' which is the delegate token for ERC721Delegable token #';
    description[5] = Strings.toString(_RQTokenId);
    description[6] = ' of the NFT contract at ';
    description[7] = toString(_RQContract);

    string memory desc = string(abi.encodePacked(
      description[0],
      description[1],
      description[2],
      description[3],
      description[4],
      description[5],
      description[6],
      description[7]
    ));

    return string(abi.encodePacked(desc, '.",'));
  }

  function tokenURI(uint256 _tokenId) public view returns(string memory) {
    (address RQContract, uint256 RQTokenId) = IERC721Dispatcher(msg.sender).getDepositByTokenId(_tokenId);
    (address DQContract, uint256 DQTokenId) = IERC721Delegable(RQContract).getDelegateToken(RQTokenId);

    string memory name = packName(_tokenId);
    string memory description = packDescription(RQContract, DQContract, RQTokenId, DQTokenId, _tokenId);
    string memory svg = packSVG(_tokenId);

    string memory metadata = string(abi.encodePacked(
      '{',
      name,
      description
    ));

    string memory json = Base64.encode(bytes(string(abi.encodePacked(
      metadata,
      '"image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(svg)),
      '"}'))));

    return string(abi.encodePacked('data:application/json;base64,', json));
  }


  //Address to string encodeing by k06a
  //see: https://ethereum.stackexchange.com/questions/8346/convert-address-to-string
  function toString(address account) internal pure returns(string memory) {
    return toString(abi.encodePacked(account));
  }

  function toString(bytes32 value) internal pure returns(string memory) {
    return toString(abi.encodePacked(value));
  }

  function toString(bytes memory data) internal pure returns(string memory) {
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(2 + data.length * 2);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < data.length; i++) {
        str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
    }
    return string(str);
  }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


/**
 * @title IERC721Dispatcher
 * @dev Interface for an ERC721Delegable token dispatcher.
 * @author 0xAnimist (kanon.art)
 */
interface IERC721Dispatcher {

  /**
   * @dev Emitted when a delegate token has been deposited.
   */
  event Deposited(address indexed sourceTokenContract, uint256 indexed sourceTokenId, uint256 tokenId, address depositedBy, bytes[] terms, bytes data);

  /**
   * @dev Emitted when a delegate token has been withdrawn.
   */
  event Withdrawn(address indexed sourceTokenContract, uint256 indexed sourceTokenId, uint256 tokenId, address withdrawnBy, bytes data);

  /**
   * @dev Emitted when an approval request has been granted.
   */
  event ApprovalGranted(address indexed sourceTokenContract, uint256 indexed sourceTokenId, address indexed to, address payee, bytes terms, bytes data);

  /**
   * @dev Emitted when terms are set for a token.
   */
  event TermsSet(address indexed owner, bytes[] terms, uint256 tokenId, bytes data);

  /**
   * @dev Deposits an array of delegate tokens of their corresponding delegable Tokens
   * in exchange for sDQ receipt tokens.
   *
   * Requirements:
   *
   * - must be the owner of the delegate token
   *
   * Emits a {Deposited} event.
   */
  function deposit(address[] memory _ERC721DelegableContract, uint256[] memory _ERC721DelegableTokenId, bytes[][] memory _terms, bytes calldata _data) external returns (uint256[] memory tokenIds);

  /**
   * @dev Withdraws a staked delegate token in exchange for `_tokenId` sDQ token receipt.
   *
   * Emits a {Withdrawn} event.
   */
  function withdraw(uint256 _tokenId, bytes calldata _data) external;

  /**
   * @dev Sets the terms by which an approval request will be granted.
   *
   * Emits a {TermsSet} event.
   */
  function setTerms(bytes[] memory _terms, uint256 _tokenId, bytes calldata _data) external;

  /**
   * @dev Gets the terms by which an approval request will be granted.
   */
  function getTerms(uint256 _tokenId) external view returns (bytes[] memory terms);

  /**
   * @dev Gets array of methodIds served by the dispatcher.
   */
  function getServedMethodIds() external view returns (bytes4[] memory methodIds);

  /**
   * @dev Gets source ERC721Delegable token for a given `_tokenId` token.
   */
  function getDepositByTokenId(uint256 _tokenId) external view returns (address contractAddress, uint256 tokenId);

  /**
   * @dev Gets tokenId` token ID for a given source ERC721Delegable token.
   */
  function getTokenIdByDeposit(address _ERC721DelegableContract, uint256 _ERC721DelegableTokenId) external view returns (bool success, uint256 tokenId);

  /**
   * @dev Requests dispatcher call approveByDelegate() on the source ERC721Delegable
   * token corresponding to `_tokenId` token for `_to` address with `_terms` terms.
   */
  function requestApproval(address _payee, address _to, address _ERC721DelegableContract, uint256 _ERC721DelegableTokenId, bytes memory _terms, bytes calldata _data) external payable;

  /**
   * @dev Withdraws fees accrued to all eligible recipients for `_tokenId` token without withdrawing the token itself.
   *
   * Requirements:
   *
   * - token must exist.
   *
   */
  function claimFeesAccrued(uint256 _tokenId) external returns (bool success, address currency);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

/**
 * @title IERC721Delegable
 * @dev Interface for a delegable ERC721 token contract
 * @author 0xAnimist (kanon.art)
 */
interface IERC721Delegable is IERC721 {
  /**
   * @dev Emitted when the delegate token is set for `tokenId` token.
   */
  event DelegateTokenSet(address indexed delegateContract, uint256 indexed delegateTokenId, uint256 indexed tokenId, address operator, bytes data);

  /**
   * @dev Sets the delegate NFT for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {DelegateTokenSet} event.
   */
  function setDelegateToken(address _delegateContract, uint256 _delegateTokenId, uint256 _tokenId) external;

  /**
   * @dev Sets the delegate NFT for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   *
   * Emits a {DelegateTokenSet} event.
   */
  function setDelegateToken(address _delegateContract, uint256 _delegateTokenId, uint256 _tokenId, bytes calldata _data) external;

  /**
   * @dev Gets the delegate NFT for `tokenId` token.
   *
   * Requirements:
   *
   * - `tokenId` must exist.
   */
  function getDelegateToken(uint256 _tokenId) external view returns (address contractAddress, uint256 tokenId);

  /**
   * @dev Gives permission to `to` to transfer `tokenId` token to another account.
   * The approval is cleared when the token is transferred.
   *
   * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
   *
   * Requirements:
   *
   * - The caller must own the delegate token.
   * - `tokenId` must exist.
   *
   * Emits an {Approval} event.
   */
  function approveByDelegate(address to, uint256 tokenId) external;
}

// SPDX-License-Identifier: MIT

// https://kanon.art
//
//
//                                   [email protected]@@@@@@@@@@$$$
//                               [email protected]@@@@@$$$$$$$$$$$$$$##
//                           $$$$$$$$$$$$$$$$$#########***
//                        $$$$$$$$$$$$$$$#######**!!!!!!
//                     ##$$$$$$$$$$$$#######****!!!!=========
//                   ##$$$$$$$$$#$#######*#***!!!=!===;;;;;
//                 *#################*#***!*!!======;;;:::
//                ################********!!!!====;;;:::~~~~~
//              **###########******!!!!!!==;;;;::~~~--,,,-~
//             ***########*#*******!*!!!!====;;;::::~~-,,......,-
//            ******#**********!*!!!!=!===;;::~~~-,........
//           ***************!*!!!!====;;:::~~-,,..........
//         !************!!!!!!===;;::~~--,............
//         !!!*****!!*!!!!!===;;:::~~--,,..........
//        =!!!!!!!!!=!==;;;::~~-,,...........
//        =!!!!!!!!!====;;;;:::~~--,........
//       ==!!!!!!=!==;=;;:::~~--,...:~~--,,,..
//       ===!!!!!=====;;;;;:::~~~--,,..#*=;;:::~--,.
//       ;=============;;;;;;::::~~~-,,...$$###==;;:~--.
//      :;;==========;;;;;;::::~~~--,,[email protected]@$$##*!=;:~-.
//      :;;;;;===;;;;;;;::::~~~--,,...$$$$#*!!=;~-
//       :;;;;;;;;;;:::::~~~~---,,...!*##**!==;~,
//       :::;:;;;;:::~~~~---,,,...~;=!!!!=;;:~.
//       ~:::::::::::::~~~~~---,,,....-:;;=;;;~,
//        ~~::::::::~~~~~~~-----,,,......,~~::::~-.
//         -~~~~~~~~~~~~~-----------,,,.......,-~~~~~,.
//          ---~~~-----,,,,,........,---,.
//           ,,--------,,,,,,.........
//             .,,,,,,,,,,,,......
//                ...............
//                    .........


pragma solidity ^0.8.0;

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <[email protected]>
library Base64 {

  bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

  /// @notice Encodes some bytes to the base64 representation
  function encode(bytes memory data) internal pure returns (string memory) {
      uint256 len = data.length;
      if (len == 0) return "";

      // multiply by 4/3 rounded up
      uint256 encodedLen = 4 * ((len + 2) / 3);

      // Add some extra buffer at the end
      bytes memory result = new bytes(encodedLen + 32);

      bytes memory table = TABLE;

      assembly {
          let tablePtr := add(table, 1)
          let resultPtr := add(result, 32)

          for {
              let i := 0
          } lt(i, len) {

          } {
              i := add(i, 3)
              let input := and(mload(add(data, i)), 0xffffff)

              let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
              out := shl(8, out)
              out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
              out := shl(8, out)
              out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
              out := shl(8, out)
              out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
              out := shl(224, out)

              mstore(resultPtr, out)

              resultPtr := add(resultPtr, 4)
          }

          switch mod(len, 3)
          case 1 {
              mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
          }
          case 2 {
              mstore(sub(resultPtr, 1), shl(248, 0x3d))
          }

          mstore(result, encodedLen)
      }

      return string(result);
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