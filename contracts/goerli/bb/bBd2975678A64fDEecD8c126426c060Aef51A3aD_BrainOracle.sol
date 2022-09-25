pragma solidity ^0.8.0;


import "../interfaces/IBrainOracle.sol";


contract BrainOracle is IBrainOracle {

    address public immutable override wethAddr;

    constructor(address wethAddr_) {
        wethAddr = wethAddr_;
    }

    function getRandFightNum(uint anftTokenId) external view override returns (uint) {
        // I know, I know. This is temporary. Gotta move fast
        return uint(keccak256(abi.encodePacked(anftTokenId, wethAddr.balance)));
    }
}

pragma solidity ^0.8.0;


interface IBrainOracle {
    function wethAddr() external view returns (address);
    function getRandFightNum(uint anftTokenId) external view returns (uint);
}