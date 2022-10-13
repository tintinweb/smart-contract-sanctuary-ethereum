// SPDX-License-Identifier: None
pragma solidity =0.8.13;

import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/Base64.sol';

library RentaFiSVG {
  function weiToEther(uint256 num) public pure returns (string memory) {
    if (num == 0) return '0.0';
    bytes memory b = bytes(Strings.toString(num));
    uint256 n = b.length;
    if (n < 19) for (uint256 i = 0; i < 19 - n; i++) b = abi.encodePacked('0', b);
    n = b.length;
    uint256 k = 18;
    for (uint256 i = n - 1; i > n - 18; i--) {
      if (b[i] != '0') break;
      k--;
    }
    uint256 m = n - 18 + k + 1;
    bytes memory a = new bytes(m);
    for (uint256 i = 0; i < k; i++) a[m - 1 - i] = b[n - 19 + k - i];
    a[m - k - 1] = '.';
    for (uint256 i = 0; i < n - 18; i++) a[m - k - 2 - i] = b[n - 19 - i];
    return string(a);
  }

  function getYieldSVG(
    uint256 _lockId,
    uint256 _tokenId,
    uint256 _amount,
    uint256 _benefit,
    uint256 _lockStartTime,
    uint256 _lockExpireTime,
    address _collection,
    string memory _name,
    string memory _tokenSymbol
  ) public pure returns (bytes memory) {
    string memory parsed = weiToEther(_benefit);
    string memory svg = string(
      abi.encodePacked(
        abi.encodePacked(
          "<svg xmlns='http://www.w3.org/2000/svg' xmlns:xlink='http://www.w3.org/1999/xlink' fill='#fff' viewBox='0 0 486 300'><rect width='485.4' height='300' fill='#fff' rx='12'/><rect width='485.4' height='300' fill='url(#a)' rx='12'/><text fill='#5A6480' font-family='Poppins' font-size='10' font-weight='400'><tspan x='28' y='40'>Yield NFT - RentaFi</tspan></text><text fill='#5A6480' font-family='Poppins' font-size='10' font-weight='400' text-anchor='end'><tspan x='465' y='150'>",
          _tokenSymbol,
          "</tspan></text><text fill='#5A6480' font-family='Inter' font-size='24' font-weight='900'><tspan x='28' y='150'>Claimable Funds</tspan></text><text fill='#5A6480' font-family='Inter' font-size='36' font-weight='900'><tspan x='440' y='150' text-anchor='end'>",
          parsed,
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='270'>"
        ),
        abi.encodePacked(
          _name,
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='283'>",
          Strings.toHexString(uint256(uint160(_collection)), 20),
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400' text-anchor='end'><tspan x='463' y='270'>TokenID: ",
          Strings.toString(_tokenId),
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400' text-anchor='end'><tspan x='463' y='283'>Amount: ",
          Strings.toString(_amount),
          "</tspan></text><defs><linearGradient id='a' x1='0' x2='379' y1='96' y2='353' gradientUnits='userSpaceOnUse'><stop stop-color='#7DBCFF' stop-opacity='.1'/><stop offset='1' stop-color='#FF7DC0' stop-opacity='.1'/></linearGradient></defs></svg>"
        )
      )
    );

    bytes memory json = abi.encodePacked(
      abi.encodePacked(
        '{"name": "yieldNFT #',
        Strings.toString(_lockId),
        ' - RentaFi", "description": "YieldNFT represents Rental Fee deposited by Borrower in a RentaFi Escrow. The owner of this NFT can claim rental fee after lock-time expired by burn this.", "image": "data:image/svg+xml;base64,',
        Base64.encode(bytes(svg)),
        '", "attributes":[{"display_type": "date", "trait_type": "StartDate", "value":"'
      ),
      abi.encodePacked(
        Strings.toString(_lockStartTime),
        '"},{"display_type": "date", "trait_type":"ExpireDate", "value":"',
        Strings.toString(_lockExpireTime),
        '"},{"trait_type":"FeeAmount", "value":"',
        parsed,
        '"},{"trait_type":"Collection", "value":"',
        _name,
        '"}]}'
      )
    );

    return json;
  }

  function getOwnershipSVG(
    uint256 _lockId,
    uint256 _tokenId,
    uint256 _amount,
    uint256 _lockStartTime,
    uint256 _lockExpireTime,
    address _collection,
    string memory _name
  ) public pure returns (bytes memory) {
    string memory svg = string(
      abi.encodePacked(
        abi.encodePacked(
          "<svg xmlns='http://www.w3.org/2000/svg' fill='#fff' viewBox='0 0 486 300'><rect width='485.4' height='300' fill='#fff' rx='12'/><rect width='485.4' height='300' fill='url(#a)' rx='12'/><text fill='#5A6480' font-family='Poppins' font-size='10' font-weight='400'><tspan x='28' y='40'>RentaFi Ownership NFT</tspan></text><text fill='#5A6480' font-family='Poppins' font-size='10' font-weight='400'><tspan x='280' y='270'>Until Unlock</tspan><tspan x='430' y='270'>Day</tspan></text><text fill='#5A6480' font-family='Inter' font-size='24' font-weight='900'><tspan x='28' y='150'>",
          _name,
          "</tspan></text><text fill='#5A6480' font-family='Inter' font-size='36' font-weight='900' text-anchor='end'><tspan x='425' y='270'>",
          Strings.toString((_lockExpireTime - _lockStartTime) / 1 days)
        ),
        abi.encodePacked(
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='170'>",
          Strings.toHexString(uint256(uint160(_collection)), 20),
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='185'>TokenID: ",
          Strings.toString(_tokenId),
          "</tspan></text><text fill='#98AABE' font-family='Inter' font-size='10' font-weight='400'><tspan x='28' y='200'>Amount: ",
          Strings.toString(_amount),
          "</tspan></text><defs><linearGradient id='a' x1='0' x2='379' y1='96' y2='353' gradientUnits='userSpaceOnUse'><stop stop-color='#7DBCFF' stop-opacity='.1'/><stop offset='1' stop-color='#FF7DC0' stop-opacity='.1'/></linearGradient></defs></svg>"
        )
      )
    );

    bytes memory json = abi.encodePacked(
      '{"name": "OwnershipNFT #',
      Strings.toString(_lockId),
      ' - RentaFi", "description": "OwnershipNFT represents Original NFT locked in a RentaFi Escrow. The owner of this NFT can claim original NFT after lock-time expired by burn this.", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(svg)),
      '", "attributes":[{"display_type": "date", "trait_type": "StartDate", "value":"',
      Strings.toString(_lockStartTime),
      '"},{"display_type": "date", "trait_type":"ExpireDate", "value":"',
      Strings.toString(_lockExpireTime),
      '"},{"trait_type": "Collection", "value":"',
      _name,
      '"}]}'
    );

    return json;
  }
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Base64.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides a set of functions to operate with Base64 strings.
 *
 * _Available since v4.5._
 */
library Base64 {
    /**
     * @dev Base64 Encoding/Decoding Table
     */
    string internal constant _TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /**
     * @dev Converts a `bytes` to its Bytes64 `string` representation.
     */
    function encode(bytes memory data) internal pure returns (string memory) {
        /**
         * Inspired by Brecht Devos (Brechtpd) implementation - MIT licence
         * https://github.com/Brechtpd/base64/blob/e78d9fd951e7b0977ddca77d92dc85183770daf4/base64.sol
         */
        if (data.length == 0) return "";

        // Loads the table into memory
        string memory table = _TABLE;

        // Encoding takes 3 bytes chunks of binary data from `bytes` data parameter
        // and split into 4 numbers of 6 bits.
        // The final Base64 length should be `bytes` data length multiplied by 4/3 rounded up
        // - `data.length + 2`  -> Round up
        // - `/ 3`              -> Number of 3-bytes chunks
        // - `4 *`              -> 4 characters for each chunk
        string memory result = new string(4 * ((data.length + 2) / 3));

        /// @solidity memory-safe-assembly
        assembly {
            // Prepare the lookup table (skip the first "length" byte)
            let tablePtr := add(table, 1)

            // Prepare result pointer, jump over length
            let resultPtr := add(result, 32)

            // Run over the input, 3 bytes at a time
            for {
                let dataPtr := data
                let endPtr := add(data, mload(data))
            } lt(dataPtr, endPtr) {

            } {
                // Advance 3 bytes
                dataPtr := add(dataPtr, 3)
                let input := mload(dataPtr)

                // To write each character, shift the 3 bytes (18 bits) chunk
                // 4 times in blocks of 6 bits for each character (18, 12, 6, 0)
                // and apply logical AND with 0x3F which is the number of
                // the previous character in the ASCII table prior to the Base64 Table
                // The result is then added to the table to get the character to write,
                // and finally write it in the result pointer but with a left shift
                // of 256 (1 byte) - 8 (1 ASCII char) = 248 bits

                mstore8(resultPtr, mload(add(tablePtr, and(shr(18, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(12, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(shr(6, input), 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance

                mstore8(resultPtr, mload(add(tablePtr, and(input, 0x3F))))
                resultPtr := add(resultPtr, 1) // Advance
            }

            // When data `bytes` is not exactly 3 bytes long
            // it is padded with `=` characters at the end
            switch mod(mload(data), 3)
            case 1 {
                mstore8(sub(resultPtr, 1), 0x3d)
                mstore8(sub(resultPtr, 2), 0x3d)
            }
            case 2 {
                mstore8(sub(resultPtr, 1), 0x3d)
            }
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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