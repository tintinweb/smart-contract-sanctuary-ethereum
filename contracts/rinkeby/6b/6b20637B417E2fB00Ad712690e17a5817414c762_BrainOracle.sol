pragma solidity ^0.8.0;


import "../interfaces/IBrainOracle.sol";


contract BrainOracle is IBrainOracle {
    function getRandFightNum() external view override returns (uint) {
        // I know, I know. This is temporary. Gotta move fast
        // return keccak256(abi.encodePacked(block.timestamp));
        return uint(keccak256(abi.encode(block.timestamp)));
    }
}

pragma solidity ^0.8.0;


interface IBrainOracle {
    function getRandFightNum() external view returns (uint);
}