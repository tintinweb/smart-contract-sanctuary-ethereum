/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

pragma solidity ^0.8.0;

contract Sample{
    uint[] public arr;
    //uint name;

    function loop(uint count) public returns(uint[] memory){
        for(uint i=0; i<count; i++)
    {
        arr.push(i);
        
    }
      return arr;
    }
    function getArr() public view returns(uint[] memory){
        return arr;
    }
}