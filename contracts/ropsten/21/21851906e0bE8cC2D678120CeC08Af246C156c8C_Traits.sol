// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;
import "./Ownable.sol";
import "./ITraits.sol";
import "./IDwarfs_NFT.sol";

contract Traits is Ownable, ITraits {
    
    IDwarfs_NFT public dwarfs_nft;

    constructor() {}

    /** ADMIN */

    function setDwarfs_NFT(address _dwarfs_nft) external onlyOwner {
        dwarfs_nft = IDwarfs_NFT(_dwarfs_nft);
    }

    /**
     * generates a base64 encoded metadata response without referencing off-chain content
     * @param tokenId the ID of the token to generate the metadata for
     * @return a base64 encoded JSON dictionary of the token's metadata and SVG
     */
    function tokenURI(uint256 tokenId)
        public
        view
        override
        returns (string memory)
    {
        IDwarfs_NFT.DwarfTrait memory s = dwarfs_nft.getTokenTraits(tokenId);
        bytes memory t = new bytes(14);
        t[0] = bytes1((uint8)(s.background_weapon >> 8));
        t[1] = bytes1((uint8)(s.background_weapon & 0x00FF));

        t[2] = bytes1((uint8)(s.body_outfit >> 8));
        t[3] = bytes1((uint8)(s.body_outfit & 0x00FF));

        t[4] = bytes1((uint8)(s.head_ears >> 8));
        t[5] = bytes1((uint8)(s.head_ears & 0x00FF));

        t[6] = bytes1((uint8)(s.mouth_nose >> 8));
        t[7] = bytes1((uint8)(s.mouth_nose & 0x00FF));

        t[8] = bytes1((uint8)(s.eyes_brows >> 8));
        t[9] = bytes1((uint8)(s.eyes_brows & 0x00FF));

        t[10] = bytes1((uint8)(s.hair_facialhair >> 8));
        t[11] = bytes1((uint8)(s.hair_facialhair & 0x00FF));

        t[12] = bytes1(s.eyewear);
        t[13] = bytes1(s.alphaIndex);

        return base64(t);
    }

    string internal constant TABLE =
        "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    function base64(bytes memory data) internal pure returns (string memory) {
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
}