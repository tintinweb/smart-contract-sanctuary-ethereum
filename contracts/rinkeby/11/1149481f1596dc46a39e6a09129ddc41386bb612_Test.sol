/**
 *Submitted for verification at Etherscan.io on 2022-07-03
*/

// File: test.sol


pragma solidity ^0.8.0;

contract Test {
    
    string[] public arr;

    function setArray() public {
        string[] storage array = arr;

        for(int i = 0; i < 1000; i++) {
            array.push("Testing");
        }
    }

    // function getArray() public returns (string[] memory) {
    //     string[] storage array = arr;
    //     string[] memory res;
    //     uint len = arr.length;


    //     // for(int i = 0; i < len; i++) {
            
    //     //     res.push(array);
    //     // }

    // }
    
    function get() public view returns (string[] memory) {
        return arr;
    }
}