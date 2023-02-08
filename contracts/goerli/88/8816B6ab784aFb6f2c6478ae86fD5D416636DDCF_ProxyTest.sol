// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

contract ProxyTest {
    address public implementation;

    constructor(address _implementation){
        implementation = _implementation;
    }


    fallback() external payable {
        address _implementation = implementation;
        assembly {
            calldatacopy(0,0,calldatasize())
            let result := delegatecall(gas(),_implementation,0,calldatasize(),0,0)
            returndatacopy(0,0,returndatasize())

            switch result
            case 0 {
                revert(0,returndatasize())
            }
            default {
                return(0,returndatasize())
            }
        }
    }
}