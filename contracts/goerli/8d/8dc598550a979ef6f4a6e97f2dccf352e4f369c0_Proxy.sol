/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

// File: contracts/PyraContract/ProxyContract.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
contract Proxy {
    
    //bytes32 public b1;

    constructor(bytes memory constructData, address contractLogic ) {

    //interact with EVM storage
        assembly {
            sstore(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7, contractLogic)
        }
        //make a delegate call to contract logic/business code contract
        (bool success,) =  contractLogic.delegatecall(constructData);
        require(success, "Deleteget call failede");
    }

    //have a fallback function when going for upgrade or proxy pattern
    fallback () external payable {

        assembly {
            let contractLogic := sload(0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7)
            calldatacopy(0x0, 0x0, calldatasize())
             let success := delegatecall(sub(gas(), 10000), contractLogic, 0x0, calldatasize(), 0, 0)
             let retSz := returndatasize()
            returndatacopy(0, 0, retSz)
            switch success
            case 0 {
                revert(0, retSz)
            }
            default {
                return(0, retSz)
            }
        }

    }


    // function getProxy() public returns (bytes32) {
    //     b1 = keccak256("PROXIABLE");
    //     return b1; //0xc5f16f0fcc639fa48a6947836d9850f504798523bf8c9a3a87d5876cf622bcf7
    // }
}