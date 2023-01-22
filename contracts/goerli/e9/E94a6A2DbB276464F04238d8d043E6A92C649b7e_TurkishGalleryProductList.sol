// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/**
 * @title Interface for FlavorInfo objects.
 */
interface IFlavorInfo {
    struct FlavorInfo {
        uint64 flavorId;
        uint64 price;
        uint64 maxSupply;
        uint64 totalMinted;
        string uriFragment;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

// NFTC Prerelease Contracts
import './IFlavorInfo.sol';

/**
 * @title Interface for Providing a FlavorInfo definition.
 * @author @NFTCulture
 */
interface IFlavorInfoProvider is IFlavorInfo {
    function provideFlavorInfos() external view returns (FlavorInfo[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

// NFTC Prerelease Contracts
import '@nftculture/nftc-contracts-private/contracts/token/IFlavorInfoProvider.sol';

/**
 * @title Product Definition for the Turkish Gallery
 * @author @NFTCulture
 */
contract TurkishGalleryProductList is IFlavorInfoProvider {
    FlavorInfo[] private _initialFlavors;

    constructor() {
        _initialFlavors.push(FlavorInfo(200100, 6 ether, 1, 0, 'token2'));
        _initialFlavors.push(FlavorInfo(200101, 6 ether, 1, 0, 'token3'));
        _initialFlavors.push(FlavorInfo(200102, 6 ether, 1, 0, 'token4'));
        _initialFlavors.push(FlavorInfo(200103, 6 ether, 1, 0, 'token5'));
        _initialFlavors.push(FlavorInfo(200104, 6 ether, 1, 0, 'token6'));
        _initialFlavors.push(FlavorInfo(200105, 6 ether, 1, 0, 'token7'));
        _initialFlavors.push(FlavorInfo(200106, 6 ether, 1, 0, 'token8'));
        _initialFlavors.push(FlavorInfo(200107, 6 ether, 1, 0, 'token9'));
        _initialFlavors.push(FlavorInfo(200108, 6 ether, 1, 0, 'token10'));
        _initialFlavors.push(FlavorInfo(200109, 6 ether, 1, 0, 'token11'));
        _initialFlavors.push(FlavorInfo(200200, 3.5 ether, 1, 0, 'token12'));
        _initialFlavors.push(FlavorInfo(200201, 3.5 ether, 1, 0, 'token13'));
        _initialFlavors.push(FlavorInfo(200202, 3.5 ether, 1, 0, 'token14'));
        _initialFlavors.push(FlavorInfo(200203, 3.5 ether, 1, 0, 'token15'));
        _initialFlavors.push(FlavorInfo(200204, 3.5 ether, 1, 0, 'token16'));
        _initialFlavors.push(FlavorInfo(200205, 3.5 ether, 1, 0, 'token17'));
        _initialFlavors.push(FlavorInfo(200206, 3.5 ether, 1, 0, 'token18'));
        _initialFlavors.push(FlavorInfo(200207, 3.5 ether, 1, 0, 'token19'));
        _initialFlavors.push(FlavorInfo(200208, 3.5 ether, 1, 0, 'token20'));
        _initialFlavors.push(FlavorInfo(200209, 3.5 ether, 1, 0, 'token21'));
        _initialFlavors.push(FlavorInfo(200300, 2 ether, 1, 0, 'token22'));
        _initialFlavors.push(FlavorInfo(200301, 2 ether, 1, 0, 'token23'));
        _initialFlavors.push(FlavorInfo(200302, 2 ether, 1, 0, 'token24'));
        _initialFlavors.push(FlavorInfo(200303, 2 ether, 1, 0, 'token25'));
        _initialFlavors.push(FlavorInfo(200304, 2 ether, 1, 0, 'token26'));
        _initialFlavors.push(FlavorInfo(200305, 2 ether, 1, 0, 'token27'));
        _initialFlavors.push(FlavorInfo(200306, 2 ether, 1, 0, 'token28'));
        _initialFlavors.push(FlavorInfo(200307, 2 ether, 1, 0, 'token29'));
        _initialFlavors.push(FlavorInfo(200308, 2 ether, 1, 0, 'token30'));
        _initialFlavors.push(FlavorInfo(200309, 2 ether, 1, 0, 'token31'));
        _initialFlavors.push(FlavorInfo(300100, 0.5 ether, 50, 0, 'token32'));
        _initialFlavors.push(FlavorInfo(300101, 0.5 ether, 50, 0, 'token33'));
        _initialFlavors.push(FlavorInfo(300102, 0.5 ether, 50, 0, 'token34'));
        _initialFlavors.push(FlavorInfo(300103, 0.5 ether, 50, 0, 'token35'));
        _initialFlavors.push(FlavorInfo(300104, 0.5 ether, 50, 0, 'token36'));
        _initialFlavors.push(FlavorInfo(400100, 0.2 ether, 20, 0, 'token37'));
        _initialFlavors.push(FlavorInfo(400101, 0.2 ether, 20, 0, 'token38'));
        //_initialFlavors.push(FlavorInfo(500000, 0.06 ether, 0, 0, 'token39'));
    }

    function provideFlavorInfos() external view returns (FlavorInfo[] memory) {
        return _initialFlavors;
    }
}