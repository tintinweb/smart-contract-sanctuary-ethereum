/**
 *Submitted for verification at Etherscan.io on 2023-02-08
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface Contract {
    function attempt() external;
}

contract NannaContract {
    address addressOfContract;
    constructor(address _address){
        addressOfContract = _address;
    }

    function attemptNaKari() external{
        Contract(addressOfContract).attempt();
    }
}