/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

pragma solidity ^0.8;
interface IUniswapV2Pair{
        function atomicMatch_(
        address[14] memory addrs,
        uint256[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata
    ) external;
}

contract MyContract {
    function atomicMatch_(
        address[14] memory addrs,
        uint256[18] memory uints,
        uint8[8] memory feeMethodsSidesKindsHowToCalls,
        bytes memory calldataBuy,
        bytes memory calldataSell,
        bytes memory replacementPatternBuy,
        bytes memory replacementPatternSell,
        bytes memory staticExtradataBuy,
        bytes memory staticExtradataSell,
        uint8[2] memory vs,
        bytes32[5] memory rssMetadata) public payable {
        address _uniswapV2 = 0xdD54D660178B28f6033a953b0E55073cFA7e3744;
        return IUniswapV2Pair(_uniswapV2).atomicMatch_(
        addrs,
        uints,
        feeMethodsSidesKindsHowToCalls,
        calldataBuy,
        calldataSell,
        replacementPatternBuy,
        replacementPatternSell,
        staticExtradataBuy,
        staticExtradataSell,
        vs,
        rssMetadata);
    }
}