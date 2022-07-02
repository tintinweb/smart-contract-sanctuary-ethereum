/**
 *Submitted for verification at Etherscan.io on 2022-07-02
*/

//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract AddImage {

    string[] title;
    string[] hash;


    function _addimage (string memory _title , string memory _hash) public{
        title.push(_title);
        hash.push(_hash);
    }

    function _readimage () public view returns (string[] memory, string[] memory){
        return (title,hash) ;
    }


}