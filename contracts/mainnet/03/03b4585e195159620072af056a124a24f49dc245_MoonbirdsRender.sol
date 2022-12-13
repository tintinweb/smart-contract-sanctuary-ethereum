/**
 *Submitted for verification at Etherscan.io on 2022-12-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

struct Features {
    /// @dev Valid range [0, 11)
    uint8 background;
    /// @dev Valid range [0, 20)
    uint8 beak;
    /// @dev Valid range [0, 113)
    uint8 body;
    /// @dev Valid range [0, 63)
    uint8 eyes;
    /// @dev Valid range [0, 13)
    uint8 eyewear;
    /// @dev Valid range [0, 38)
    uint8 headwear;
    /// @dev Valid range [0, 9)
    uint8 outerwear;
}

struct Mutators {
    bool useProofBackground;
}

interface IMoonbirds {
    function renderingContract() external view returns (address);
}

interface ITokenURIGenerator {
    function getFeatures(uint256 tokenId) external view returns (Features memory);
    function getMutators(uint256 tokenId) external view returns (Mutators memory);
    function artworkURI(Features memory features, Mutators memory mutators, uint32 scaleupFactor) external view returns (string memory);
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

abstract contract Ownable {
    address private _owner;

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _owner = msg.sender;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
}

// https://etherscan.io/address/0x85701AD420553315028a49A16f078D5FF62F4762#code
contract MoonbirdsRender is Ownable{

    IMoonbirds public moonbirds;
    uint32 internal _bmpScale;

    constructor(IMoonbirds _moonbirds) {
        moonbirds = _moonbirds;
        _bmpScale = 12;
    }

    function setBmpScale(uint32 bmpScale_) external onlyOwner {
        _bmpScale = bmpScale_;
    }

    function substring(bytes memory strBytes, uint startIndex, uint endIndex) public pure returns(string memory) {
        bytes memory result = new bytes(endIndex-startIndex);
        for(uint i = startIndex; i < endIndex; i++) {
            result[i-startIndex] = strBytes[i];
        }
        return string(result);
    }

    function render(uint256 tokenId) external view returns (bytes memory) {
        ITokenURIGenerator generator = ITokenURIGenerator(moonbirds.renderingContract());
        Features memory features = generator.getFeatures(tokenId);
        Mutators memory mutators = generator.getMutators(tokenId);
        bytes memory img = bytes(generator.artworkURI(features, mutators, _bmpScale));
        return Base64.decode(substring(img, 22, img.length));
    }
}