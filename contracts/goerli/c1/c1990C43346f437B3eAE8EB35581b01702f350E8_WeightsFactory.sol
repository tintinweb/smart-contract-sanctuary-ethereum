// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;


contract WeightsRegistry {
    address public factory;
    mapping(uint256 => uint256) public tokenWeights;
    address public NFT;

    constructor(address _NFT) {
        NFT = _NFT;
        factory = msg.sender;
    }

    function setWeight(uint256 tokenId, uint256 weight) internal {
        tokenWeights[tokenId] = weight;
    }

    function setWeights() external {

        uint256[] memory tokenIds = new uint256[](20);
        uint256[] memory weights = new uint256[](20);

        tokenIds[0] = 2912;
        tokenIds[1] = 2927;
        tokenIds[2] = 2926;
        tokenIds[3] = 2914;
        tokenIds[4] = 2911;
        tokenIds[5] = 2923;
        tokenIds[6] = 2921;
        tokenIds[7] = 2920;
        tokenIds[8] = 2924;
        tokenIds[9] = 2917;
        tokenIds[10] = 2922;
        tokenIds[11] = 2916;
        tokenIds[12] = 2919;
        tokenIds[13] = 2925;
        tokenIds[14] = 2918;
        tokenIds[15] = 2915;
        tokenIds[16] = 2913;

        weights[0] = 379154;
        weights[1] = 94769;
        weights[2] = 1154;
        weights[3] = 2615;
        weights[4] = 2462;
        weights[5] = 2000;
        weights[6] = 1077;
        weights[7] = 1077;
        weights[8] = 1154;
        weights[9] = 1154;
        weights[10] = 1077;
        weights[11] = 1000;
        weights[12] = 1308;
        weights[13] = 1154;
        weights[14] = 1154;
        weights[15] = 1154;
        weights[16] = 1308;
        
        require(tokenIds.length == weights.length, "Array lengths must match");

        for (uint256 i = 0; i < tokenIds.length; i++) {
            tokenWeights[tokenIds[i]] = weights[i];
        }
    }

    function getWeight(uint256 tokenId) external view returns (uint256) {
        return tokenWeights[tokenId];
    }

    function getWeights(uint256[] calldata tokenIds) external view returns (uint256[] memory) {
        uint256[] memory weights = new uint256[](tokenIds.length);

        for (uint256 i = 0; i < tokenIds.length; i++) {
            weights[i] = tokenWeights[tokenIds[i]];
        }

        return weights;
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

import "./interfaces/IWeightsFactory.sol";
import {WeightsRegistry} from "./DoodlesWeightsRegistry.sol";

contract WeightsFactory is IWeightsFactory {

    bytes32 public constant REGISTRY_HASH =
        keccak256(type(WeightsRegistry).creationCode);

    mapping(address => mapping(address => address)) public override getRegistry;
    address[] public override allRegistries;

    constructor() {
    }

    function allRegistriesLength() external view override returns (uint256) {
        return allRegistries.length;
    }

    // function createRegistry(
    //     address NFT,
    //     address tokenB,
    //     uint256[] memory tokenIds,
    //     uint256[] memory weights
    // ) external override returns (address registry) {

    //     require(NFT != address(0), "TokoV1: ZERO_ADDRESS");
    //     require(
    //         getRegistry[NFT][tokenB] == address(0),
    //         "TokoV2: REGISTRY_EXISTS"
    //     ); // single check is sufficient

    //     registry = address(
    //         new WeightsRegistry{
    //             salt: keccak256(abi.encodePacked(NFT, tokenB))
    //         }(NFT)
    //     );

    //     WeightsRegistry(registry).setWeights(tokenIds, weights);
    //     getRegistry[NFT][tokenB] = registry;
    //     allRegistries.push(registry);
    //     emit WeightsRegistryCreated(NFT, registry, allRegistries.length);
    // }

    function createDoodlesRegistry(
        address NFT,
        address tokenB
    ) external override returns (address registry) {

        require(NFT != address(0), "TokoV1: ZERO_ADDRESS");
        require(
            getRegistry[NFT][tokenB] == address(0),
            "TokoV2: REGISTRY_EXISTS"
        ); // single check is sufficient

        registry = address(
            new WeightsRegistry{
                salt: keccak256(abi.encodePacked(NFT, tokenB))
            }(NFT)
        );

        WeightsRegistry(registry).setWeights();
        // WeightsRegistry(registry).setWeights(tokenIds, weights);  // use chainlink oracle to set initial pool weights or feed from front end
        
        getRegistry[NFT][tokenB] = registry;
        allRegistries.push(registry);
        emit WeightsRegistryCreated(NFT, registry, allRegistries.length);
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;



interface IWeightsFactory {

    event WeightsRegistryCreated(
        address indexed NFT,
        address weights,
        uint256 weights_length
    );

    function getRegistry(
        address NFT,
        address tokenB
    ) external view returns (address registry);

    function allRegistries(uint256) external view returns (address registry);

    function allRegistriesLength() external view returns (uint256);

    // function createRegistry(
    //     address NFT,
    //     address tokenB,
    //     uint256[] memory tokenIds,
    //     uint256[] memory weights
    // ) external returns (address registry);


    function createDoodlesRegistry(
        address NFT,
        address tokenB
    ) external returns (address registry);

}