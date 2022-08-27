/**
 *Submitted for verification at Etherscan.io on 2022-08-26
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
/**
contract Ballot {

    struct Box {
        //address address1;
        bytes32 abc;
    }

    //Box public box;

    //Box public box = Box({ address1: 0xF4be845C8159a194113d6b684c1a5Df4D1d382ee, abc: keccak256(abi.encodePacked(address1))} );
    Box public box = Box({ abc: keccak256(abi.encodePacked(address(0xF4be845C8159a194113d6b684c1a5Df4D1d382ee)))});
    //console.log("Your debug message" + Box.box);
    //address1 = 0xF4be845C8159a194113d6b684c1a5Df4D1d382ee;
    //abc = keccak256(abi.encodePacked(address));
    //function retrieve() public view returns (bytes32){ 
    //    return Box.abc;
    //}

    
}
**/
contract Storage {

    bytes32 abc; //state variable

    function store(bytes32 num) public returns (bytes32) {
        abc = num;
        //even this will not return any value in the decoded output field
        return num;         }

    //the retrieve() view function will return a value in the 
   // "decodedoutput" field of the transaction

    function retrieve() public view returns (bytes32){ 
        return abc;
    }

    // this method (not being a view method) will not return a value
    function retrieve2() public returns (bytes32){ 
        return abc;
    }
}