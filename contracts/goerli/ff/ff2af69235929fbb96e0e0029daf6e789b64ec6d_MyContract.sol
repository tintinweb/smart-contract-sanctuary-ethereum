/**
 *Submitted for verification at Etherscan.io on 2022-10-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract MyContract {
    address addrAnothContr;
    
    function setAddr (address _setAddr) external {
        addrAnothContr = _setAddr;
    }

    function callSetName (string memory _name) external returns(string memory) {
        AnotherContract a = AnotherContract(addrAnothContr);
        return a.setName(_name);
    }

}

contract AnotherContract {
    string public name;

    function setName(string calldata _name) external returns(string memory) {
        name = _name;
        return name;
    }

   
}