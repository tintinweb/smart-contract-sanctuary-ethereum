/**
 *Submitted for verification at Etherscan.io on 2022-05-16
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {
    int private result;

    function add(int a,int b) public returns (int){
        result = a+b;
        return result;
    }
    function min(int a,int b) public returns (int){
        result = a-b;
        return result;
    }
    function mul(int a,int b) public returns (int){
        result = a*b;
        return result;
    }
    function div(int a,int b) public returns (int){
        result = a/b;
        return result;
    }
    function getResult() public view returns (int){
        return result;
    }
}