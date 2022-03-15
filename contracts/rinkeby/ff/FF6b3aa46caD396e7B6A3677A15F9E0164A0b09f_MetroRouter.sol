// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "../interfaces/IMetroNFTRouter.sol";

contract MetroRouter is IMetroNFTRouter {

    address genesisAddress;

    address blackoutAddress;

    constructor(
        address _genesisAddress, 
        address _blackoutAddress
    ) {
        genesisAddress = _genesisAddress;
        blackoutAddress = _blackoutAddress;
    }

    function getNFTContractAddress(uint256 tokenId) external view returns (address) {
        require(tokenId > 0 && tokenId <= 20000, "Invalid token id");
        return tokenId <= 10_000 ? genesisAddress : blackoutAddress;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity 0.8.12;

interface IMetroNFTRouter {

    function getNFTContractAddress(uint256 tokenId) external view returns (address);
}