/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IUncirculatedFakeInternetMoney {
  function owner() external view returns (address);
  function exists(uint256 tokenId) external view returns (bool);
}

contract TokenURI {
  using Strings for uint256;

  IUncirculatedFakeInternetMoney public immutable uFIMContract;
  string public baseImgUrl = 'ipfs://bafybeierik4sprq6kr4jocdwxpx52kwsorqqqw6t5xo6ymcw6tvsfscfga/';
  string public baseExternalUrl = 'https://uncirculatedmoney.com/';
  string public license = 'CC BY-NC 4.0';
  string public imgExtension = '.jpeg';
  string public description = 'Uncirculated Fake Internet Money is a purely commemorative collection, and holds no monetary value whatsoever.';

  constructor(address _uFIMContractAddress) {
    uFIMContract = IUncirculatedFakeInternetMoney(_uFIMContractAddress);
  }

  modifier onlyOwner() {
    require(msg.sender == uFIMContract.owner(), "Ownable: caller is not the owner");
    _;
  }

  function tokenURI(uint256 tokenId) external view returns (string memory) {
    require(uFIMContract.exists(tokenId), 'ERC721Metadata: URI query for nonexistent token');

    string memory tokenString = tokenId.toString();

    string memory json = Base64.encode(
      abi.encodePacked(
        '{"name": "Uncirculated Fake Internet Money #', tokenString,
        '", "description": "', description,
        '", "license": "', license,
        '", "image": "', baseImgUrl, tokenString, imgExtension,
        '", "external_url": "', baseExternalUrl,
        '"}'
      )
    );
    return string(abi.encodePacked('data:application/json;base64,', json));
  }

  function setBaseMetadata(
    string calldata _baseImgUrl,
    string calldata _imgExtension,
    string calldata _baseExternalUrl,
    string calldata _license,
    string calldata _description
  ) external onlyOwner {
    baseImgUrl = _baseImgUrl;
    imgExtension = _imgExtension;
    baseExternalUrl = _baseExternalUrl;
    license = _license;
    description = _description;
  }
}


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

library Strings {
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
}