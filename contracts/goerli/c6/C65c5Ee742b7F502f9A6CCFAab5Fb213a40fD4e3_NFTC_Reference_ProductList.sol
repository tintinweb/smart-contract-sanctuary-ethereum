// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import './IFlavorInfoV2.sol';

/**
 * @title IFlavorInfoProviderV2
 * @author @NFTCulture
 * @dev Interface for Providing a product list definition.
 *
 * Note: This definition is compatible with the V2 version of Flavor Infos.
 */
interface IFlavorInfoProviderV2 is IFlavorInfoV2 {
    function provideFlavorInfos() external view returns (FlavorInfoV2[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title IFlavorInfoV2
 * @author NFT Culture
 * @dev Interface for FlavorInfoV2 objects.
 *
 *  Bits Layout:
 *    256 bit slot #1
 *    - [0..63]    `flavorId`
 *    - [64..127]  `maxSupply`
 *    - [128..191] `totalMinted`
 *    - [192..255] `aux`
 *
 *    256 bit slot #2
 *    - [0..159]   `externalValidator`
 *    - [160..255] `price`
 *
 *    256 bit slot #3
 *    - [0..255] `uriFragment`
 *
 *  NOTE: Splitting out uriFragment and ipfsHash allows for the more gas efficient bytes32 uriFragment
 *  to be used if ipfsHash is included as part of Base URI.
 *
 *  URI should be built like: `${baseURI}${ipfsHash}${uriFragment}
 *    - Care should be taken to properly include '/' chars. Typically baseURI will have a trailing slash.
 *    - If ipfsHash is used, uriFragment should contain a leading '/'.
 *    - If ipfsHash is not used, uriFragment should not contain a leading '/'.
 */
interface IFlavorInfoV2 {
    struct FlavorInfoV2 {
        uint64 flavorId;
        uint64 maxSupply;
        uint64 totalMinted;
        uint64 aux; // Extra storage space that can be used however needed by the caller.
        address externalValidator; // Address of an external validator, for use cases such as making purchase of the product dependent on some other NFT project.
        uint96 price; // Price needs to be 96 bit. 64bit for value sets a cap at about 9.2 ETH (9.2e18 wei)
        bytes32 uriFragment; // Fragment to append to URI
        string ipfsHash; // IPFS Hash to append to URI
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import '@nftculture/nftc-contracts-private/contracts/token/IFlavorInfoProviderV2.sol';

/**
 * @title NFTC_Reference_ProductList
 * @author @NFTCulture
 */
contract NFTC_Reference_ProductList is IFlavorInfoProviderV2 {
    function provideFlavorInfos() external pure override returns (FlavorInfoV2[] memory) {
        FlavorInfoV2[] memory initialFlavors = new FlavorInfoV2[](13);

        // These are the ones added in inside the init method in the main class.
        //initialFlavors[0] = FlavorInfoV2(100100, 15, 0, 0, address(0),  .08 ether, 0, '');
        //initialFlavors[1] = FlavorInfoV2(200100, 100, 0, 0, address(0), .05 ether, 0, '');
        //initialFlavors[2] = FlavorInfoV2(300100, 0, 0, 0, address(0),   .02 ether, 0, '');

        // These are the additional 13 we will be adding.
        initialFlavors[0] =  FlavorInfoV2(100000, 10, 0, 0, address(0), .08 ether, 0, '');
        initialFlavors[1] =  FlavorInfoV2(200200, 50, 0, 0, address(0), .02 ether, 0, '');
        initialFlavors[2] =  FlavorInfoV2(200300, 10, 0, 0, address(0), .08 ether, 0, '');
        initialFlavors[3] =  FlavorInfoV2(300101, 50, 0, 0, address(0), .02 ether, 0, '');
        initialFlavors[4] =  FlavorInfoV2(300102, 10, 0, 0, address(0), .08 ether, 0, '');
        initialFlavors[5] =  FlavorInfoV2(300103, 25, 0, 0, address(0), .05 ether, 0, '');
        initialFlavors[6] =  FlavorInfoV2(300104, 50, 0, 0, address(0), .02 ether, 0, '');
        initialFlavors[7] =  FlavorInfoV2(400100, 10, 0, 0, address(0), .08 ether, 0, '');
        initialFlavors[8] =  FlavorInfoV2(400101, 25, 0, 0, address(0), .05 ether, 0, '');
        initialFlavors[9] =  FlavorInfoV2(400102, 50, 0, 0, address(0), .02 ether, 0, '');
        initialFlavors[10] = FlavorInfoV2(400103, 10, 0, 0, address(0), .08 ether, 0, '');
        initialFlavors[11] = FlavorInfoV2(400104, 25, 0, 0, address(0), .05 ether, 0, '');
        initialFlavors[12] = FlavorInfoV2(500000, 50, 0, 0, address(0), .02 ether, 0, '');

        return initialFlavors;
    }
}