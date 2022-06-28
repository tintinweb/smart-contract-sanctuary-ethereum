/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

pragma solidity ^0.4.0;

contract helloworld {
    string myword = "helloworld";
    
    function show() public view returns(string){
        return myword;
    }

    function show(string _input) public view returns(string){
        bytes memory _ba = bytes(myword);
        bytes memory _bb = bytes(_input);
        string memory ret = new string(_ba.length + _bb.length);
        bytes memory bret = bytes(ret);
        uint k = 0;
        for (uint i = 0; i < _ba.length; i++)bret[k++] = _ba[i];
        for (i = 0; i < _bb.length; i++) bret[k++] = _bb[i];
        return string(ret);
    }
}