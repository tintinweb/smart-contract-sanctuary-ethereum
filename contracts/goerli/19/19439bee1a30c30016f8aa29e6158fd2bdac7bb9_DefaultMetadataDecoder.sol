// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import {IDefaultMetadataDecoder} from "./interfaces/IDefaultMetadataDecoder.sol";

/** 
 * @title DefaultMetadataDecoder
 * @notice Simple bytes => string decoder usable by all tokens that init address of this contract
 *      as their renderer
 * @dev Can be used by any contract
 * @author Max Bochman
 */
contract DefaultMetadataDecoder is IDefaultMetadataDecoder {

    /// @notice metadataDecoder
    /// @dev returns blank if token not initialized
    /// @return tokenURI uri for given token of collection address (if set)
    function metadataDecoder(bytes memory artifactMetadata)
        external
        pure
        returns (string memory)
    {
        // data format: tokenURI
        (string memory tokenURI) = abi.decode(artifactMetadata, (string));        

        return tokenURI;
    }    
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

interface IDefaultMetadataDecoder {
    function metadataDecoder(bytes memory artifactMetadata) external pure returns (string memory);
}