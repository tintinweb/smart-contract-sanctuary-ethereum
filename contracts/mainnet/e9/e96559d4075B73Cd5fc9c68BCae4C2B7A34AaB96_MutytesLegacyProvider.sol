// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IMutytesLegacyProvider } from "./IMutytesLegacyProvider.sol";
import { IERC721TokenURIProvider } from "../../core/token/ERC721/tokenURI/IERC721TokenURIProvider.sol";

/**
 * @title Mutytes legacy token URI provider implementation
 */
contract MutytesLegacyProvider is IERC721TokenURIProvider {
    address _interpreterAddress;
    string _externalURL;

    constructor(address interpreterAddress, string memory externalURL) {
        _interpreterAddress = interpreterAddress;
        _externalURL = externalURL;
    }

    /**
     * @inheritdoc IERC721TokenURIProvider
     */
    function tokenURI(uint256 tokenId) external view virtual returns (string memory) {
        IMutytesLegacyProvider interpreter = IMutytesLegacyProvider(_interpreterAddress);
        IMutytesLegacyProvider.TokenData memory token;
        token.id = tokenId;
        token.dna = new uint256[](1);
        token.dna[0] = uint256(keccak256(abi.encode(tokenId)));
        token
            .info = "The Mutytes are a collection of severely mutated creatures that invaded Ethernia. Completely decentralized, every Mutyte is generated, stored and rendered 100% on-chain. Once acquired, a Mutyte grants its owner access to the lab and its facilities.";
        IMutytesLegacyProvider.MutationData memory mutation;
        mutation.count = 1;
        return interpreter.tokenURI(token, mutation, _externalURL);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title Mutytes legacy token URI provider interface
 */
interface IMutytesLegacyProvider {
    struct TokenData {
        uint256 id;
        string name;
        string info;
        uint256[] dna;
    }

    struct MutationData {
        uint256 id;
        string name;
        string info;
        uint256 count;
    }

    /**
     * @notice Get the URI of a token
     * @param token The token data
     * @param mutation The mutation data
     * @param externalURL External token URL
     * @return tokenURI The token URI
     */
    function tokenURI(
        TokenData calldata token,
        MutationData calldata mutation,
        string calldata externalURL
    ) external view returns (string memory);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @title ERC721 token URI provider interface
 */
interface IERC721TokenURIProvider {
    /**
     * @notice Get the URI of a token
     * @param tokenId The token id
     * @return tokenURI The token URI
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}