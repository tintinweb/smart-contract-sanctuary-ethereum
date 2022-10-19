/**
 *Submitted for verification at Etherscan.io on 2022-10-19
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

contract RPAATokenURI {
  string public constant image = '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1500 500"><style type="text/css">.text{font:bold 155px serif;text-anchor:middle;font-weight:bold}.italic{font-style:italic}.blue{fill:#00f}.red{fill:#f00}.black{fill:#000}.white{fill:#fff}</style><rect x="0" y="0" width="100%" height="100%" fill="#fff"/><text class="text blue" x="49.6%" y="30.7%">RADICAL</text><text class="text italic blue" x="49.6%" y="60.7%">PRO-ABORTION</text><text class="text blue" x="49.6%" y="90.7%">AGENDA</text><text class="text white" x="49.85%" y="30.3%">RADICAL</text><text class="text italic white" x="49.85%" y="60.3%">PRO-ABORTION</text><text class="text white" x="49.85%" y="90.3%">AGENDA</text><text class="text black" x="50%" y="30%">RADICAL</text><text class="text italic red" x="50%" y="60%">PRO-ABORTION</text><text class="text black" x="50%" y="90%">AGENDA</text></svg>';

  function uri(uint256) public view  returns (string memory) {
    bytes memory encodedImage = abi.encodePacked('"image": "data:image/svg+xml;base64,', getEncodedSVG(), '",');

    bytes memory json = abi.encodePacked(
      'data:application/json;utf8,',
      '{"name": "Radical Pro-Abortion Agenda",',
      '"symbol": "RPAA",',
      '"description": "Support the Radical Pro-Abortion Agenda!",',
      encodedImage,
      '"license": "CC0",'
      '"external_url": "https://steviep.xyz/rpaa"',
      '}'
    );
    return string(json);
  }

  function getEncodedSVG() public pure returns (string memory) {
    return Base64.encode(abi.encodePacked(image));
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