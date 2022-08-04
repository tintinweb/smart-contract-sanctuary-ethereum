/**
 *Submitted for verification at Etherscan.io on 2022-08-04
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract ShopList {
    
    string list;

    function addList(string memory _list) public {
        list = _list;
    } 

    function viewList() external view returns (string memory) {
        return(list);
    }
}