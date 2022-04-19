/**
 *Submitted for verification at Etherscan.io on 2022-04-19
*/

pragma solidity ^0.8.0;

contract EstimateGas {
    uint256 k = 1500;

    function test() external returns (bytes memory s) {
        if (k < 600) {
            for (uint256 i; i < 100; ++i) {
                s = abi.encode("qj laina");
            }
        }

        k -= 500;
    }   

    function fix() external {
        k = 1500;
    }
}