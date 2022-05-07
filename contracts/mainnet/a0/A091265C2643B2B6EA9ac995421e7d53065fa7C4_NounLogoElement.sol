//	SPDX-License-Identifier: MIT
/// @title  Nouns wrapper to be used as a Logo Element
pragma solidity ^0.8.0;

interface INounsToken {
    function seeds(uint256 seed) external view returns (Seed memory);
}

interface INounsDescriptor {
    function generateSVGImage(Seed memory seed) external view returns (string memory);
}

struct Seed {
  uint48 background;
  uint48 body;
  uint48 accessory;
  uint48 head;
  uint48 glasses;
}

/// @notice A wrapper contract which allows Nouns to be used for logo layers
/// @dev Use as an example for your own contract to be used for a logo layers
/// @dev mustBeOwner() and getSvg(uint256 tokenId) are required
contract NounLogoElement {
  INounsToken nounsToken;
  INounsDescriptor nounsDescriptor;

  constructor(address nounsToken_, address nounsDescriptor_) {
    nounsToken = INounsToken(nounsToken_);
    nounsDescriptor = INounsDescriptor(nounsDescriptor_);
  }

  /// @notice Specifies whether or not non-owners can use a token for their logo layer
  /// @dev Required for any element used for a logo layer
  function mustBeOwnerForLogo() external view returns (bool) {
    return false;
  }

  /// @notice Gets the SVG for the logo layer
  /// @dev Required for any element used for a logo layer
  /// @param tokenId, the tokenId that SVG will be fetched for
  function getSvg(uint256 tokenId) public view returns (string memory) {
    Seed memory seed = nounsToken.seeds(tokenId);
    string memory svg = string(Base64.decode(nounsDescriptor.generateSVGImage(seed)));
    // remove solid background
    return string(abi.encodePacked(getSlice(1, 116, svg), getSlice(167, bytes(svg).length, svg)));
    
  }

  function getSlice(uint256 begin, uint256 end, string memory text) public pure returns (string memory) {
    bytes memory slice = new bytes(end-begin+1);
    for(uint i = 0; i <= end-begin; i++) {
        slice[i] = bytes(text)[i + begin - 1];
    }
    return string(slice);    
  }
}

library Base64 {
    string internal constant TABLE_ENCODE = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
    bytes  internal constant TABLE_DECODE = hex"0000000000000000000000000000000000000000000000000000000000000000"
                                            hex"00000000000000000000003e0000003f3435363738393a3b3c3d000000000000"
                                            hex"00000102030405060708090a0b0c0d0e0f101112131415161718190000000000"
                                            hex"001a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132330000000000";

    function decode(string memory _data) internal pure returns (bytes memory) {
        bytes memory data = bytes(_data);

        if (data.length == 0) return new bytes(0);
        require(data.length % 4 == 0, "invalid base64 decoder input");

        // load the table into memory
        bytes memory table = TABLE_DECODE;

        // every 4 characters represent 3 bytes
        uint256 decodedLen = (data.length / 4) * 3;

        // add some extra buffer at the end required for the writing
        bytes memory result = new bytes(decodedLen + 32);

        assembly {
            // padding with '='
            let lastBytes := mload(add(data, mload(data)))
            if eq(and(lastBytes, 0xFF), 0x3d) {
                decodedLen := sub(decodedLen, 1)
                if eq(and(lastBytes, 0xFFFF), 0x3d3d) {
                    decodedLen := sub(decodedLen, 1)
                }
            }

            // set the actual output length
            mstore(result, decodedLen)

            // prepare the lookup table
            let tablePtr := add(table, 1)

            // input ptr
            let dataPtr := data
            let endPtr := add(dataPtr, mload(data))

            // result ptr, jump over length
            let resultPtr := add(result, 32)

            // run over the input, 4 characters at a time
            for {} lt(dataPtr, endPtr) {}
            {
               // read 4 characters
               dataPtr := add(dataPtr, 4)
               let input := mload(dataPtr)

               // write 3 bytes
               let output := add(
                   add(
                       shl(18, and(mload(add(tablePtr, and(shr(24, input), 0xFF))), 0xFF)),
                       shl(12, and(mload(add(tablePtr, and(shr(16, input), 0xFF))), 0xFF))),
                   add(
                       shl( 6, and(mload(add(tablePtr, and(shr( 8, input), 0xFF))), 0xFF)),
                               and(mload(add(tablePtr, and(        input , 0xFF))), 0xFF)
                    )
                )
                mstore(resultPtr, shl(232, output))
                resultPtr := add(resultPtr, 3)
            }
        }

        return result;
    }
}