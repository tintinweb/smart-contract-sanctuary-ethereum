/**
 *Submitted for verification at Etherscan.io on 2023-01-29
*/

pragma solidity ^0.8.17;

contract MessageStore {
    string private data;

    // When declaring contract state, everything is assumed to be storage (persists on-chain) unless otherwise specified
    constructor(string memory initialData) {
        data = initialData;
    }

    function viewData() public view returns(string memory) {
        return data;
    }
}