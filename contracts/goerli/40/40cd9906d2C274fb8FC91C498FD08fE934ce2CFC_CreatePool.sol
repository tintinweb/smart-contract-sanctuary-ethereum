/**
 *Submitted for verification at Etherscan.io on 2023-03-05
*/

pragma solidity ^0.8.0;

interface IWeightedPoolFactory {
    function create(
        string calldata name,
        string calldata symbol,
        address[] calldata tokens,
        uint256[] calldata normalizedWeights,
        address[] calldata rateProviders,
        uint256 swapFeePercentage,
        address owner
    ) external returns (address);
}

contract CreatePool {
    address public constant BAL_WEIGHTED_POOL_FACTORY_ADDRESS =
        0x5Dd94Da3644DDD055fcf6B3E1aa310Bb7801EB8b;
    IWeightedPoolFactory public constant balFactory =
        IWeightedPoolFactory(BAL_WEIGHTED_POOL_FACTORY_ADDRESS);

    function deployPool() public {
        string memory name = "Tigres Weighted Pool";

        string memory symbol = "TWP";

        address[] memory tokenAddress = new address[](3);
        tokenAddress[0] = 0x8DedA75997326E7C6BFF81739B5A5dce405d1E2D;
        tokenAddress[1] = 0x9F9033F67c0c62b70213443218B44462EC99c006;
        tokenAddress[2] = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6;

        uint256[] memory normalizedWeights = new uint256[](3);
        normalizedWeights[0] = 400000000000000000;
        normalizedWeights[1] = 300000000000000000;
        normalizedWeights[2] = 300000000000000000;

        address[] memory rateProviders = new address[](3);
        rateProviders[0] = 0x0000000000000000000000000000000000000000;
        rateProviders[1] = 0x0000000000000000000000000000000000000000;
        rateProviders[2] = 0x0000000000000000000000000000000000000000;

        uint256 swapFeePercentage = 3000000000000000;
        balFactory.create(
            name,
            symbol,
            tokenAddress,
            normalizedWeights,
            rateProviders,
            swapFeePercentage,
            0xFe1b47BbD0cBD4E2Fb6118A585aab108843D7a3F
        );
    }
}