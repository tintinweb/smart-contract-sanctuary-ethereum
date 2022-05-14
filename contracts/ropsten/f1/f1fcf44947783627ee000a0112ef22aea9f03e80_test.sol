/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

pragma solidity ^0.8.0;

contract test{ //265121
    uint256[] private myArray = [3,4,5,6];
    uint256[] private secondArray = [6,7,8,9];
    mapping(uint256 => uint256) public _myIndex;
    
   function getArray() external view returns(uint[] memory){
        return myArray;
    }

    function C(address payable to) public{
        selfdestruct(to);
    }

}