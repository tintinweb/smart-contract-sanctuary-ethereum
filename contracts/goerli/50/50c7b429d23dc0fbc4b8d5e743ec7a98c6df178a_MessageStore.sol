/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

/* stores text onchain */

contract MessageStore {
    // the business logic between {} //
    string private data;
    // function that tells the compiler how to initialize the contract //
    constructor (string memory initialData) {
        data = initialData;
    }
    /* 
    function to view the data 
    in between () contain external info, 
    here no external info is needed by the business logic
    return keyword (data in this case) that this function will provide as response
    view keyword indicates that this function will not alter the internal state
    */
    function viewData() public view returns(string memory){
        return data;
    }
}