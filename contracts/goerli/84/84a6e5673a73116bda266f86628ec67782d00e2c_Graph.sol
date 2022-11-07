/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

//SPDX-License-Identifier:MIT
pragma solidity ^0.8.17;

contract Graph{

    event firstevent(
        uint uid,
        string firstname
    );

    event secondevent(
        uint uid,
        string lastname
    );

    function first(uint uid,string memory fname) public{
        emit firstevent(uid,fname);
    }

    function second(uint uid,string memory sname)public{
        emit secondevent(uid,sname);
    }

}