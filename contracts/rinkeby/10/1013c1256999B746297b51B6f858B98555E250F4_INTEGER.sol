// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract INTEGER{
    uint256 public number = 1000;
    address public owner = 0x32C58557B686D4a5Ad471D774F04Af746636ee61;
    uint[] public values;

    function returnNumbers() public view returns(uint theFinalNumber){
        if(number == 1000){
            return number;
        }else{
            revert("error in the numbers check");
        }
    }

    function addNumbers(uint _num) public {
        values.push(_num);
    }

    function returnNumberArray() public view returns(uint[] memory){
        return values;
    }

    function returnAd(address _ad) public view returns(address){
        if(_ad == owner){
            return _ad;
        }else{
            revert("The address is not equal");
        }
    }
}