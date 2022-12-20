/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

pragma solidity ^0.4.26;

contract Array {
    uint256[] public ageArray;
  
    function AgeLength()public view returns(uint256) {
        return ageArray.length;
    }
    
    function AgePush(uint256 _age)public{
        ageArray.push(_age);
    }
    function AgeChange(uint256 _index, uint256 _age)public{
        ageArray[_index] = _age;
    }
    function AgeGet(uint256 _index)public view returns(uint256){
        return ageArray[_index];
    }
    
    function Agedelete(uint256 _index)public {
        delete ageArray[_index];
    }


}