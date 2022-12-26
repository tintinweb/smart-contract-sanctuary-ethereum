/**
 *Submitted for verification at Etherscan.io on 2022-12-26
*/

// File: contracts/mock/customVrf.sol


// A mock for testing code that relies on VRFCoordinatorV2.
pragma solidity ^0.8.4;

contract CustomRng {
    event data(bytes);

    function rng(address r, uint256 reqId, uint256 number) external {
        ICallBack(r).callBack(reqId, number);
    }

    function requestRandomNess(uint256 seed) external returns (uint256) {
        return seed;
    }

    function seeBytes(bytes calldata x, uint256 p1, uint256 p2) external pure returns (bytes memory) {
        return x[p1:p2];
    }
}

interface ICallBack {
    function callBack(uint256 reqId, uint256 number) external;
}