// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/core/IDosFactory.sol";

contract TestFactory {
    address private constant FACTORY =
        0x67c93B6ffD9389C8d215F93d9E32E0CE660082CD;

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address)
    {
        return IDosFactory(FACTORY).getPair(tokenA, tokenB);
    }

    function createPair(address tokenA, address tokenB)
        external
        returns (address)
    {
        return IDosFactory(FACTORY).createPair(tokenA, tokenB);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IDosFactory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint256) external view returns (address pair);
    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB) external returns (address pair);

    function setFeeTo(address) external;
    function setFeeToSetter(address) external;

    function INIT_CODE_PAIR_HASH() external view returns (bytes32); // pancake
}