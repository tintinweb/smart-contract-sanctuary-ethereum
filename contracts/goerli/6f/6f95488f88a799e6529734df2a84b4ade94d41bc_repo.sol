/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

contract repo{


    uint256 number = 8; //Storage variable.

    function viewNumber() public view returns (uint) {
        return number;
    }

    
    

    // This function changes the value of number and also calls view function. So it will cost more gas.


    function changeNumberAndCallFunction(uint256 _newNumber) public returns (uint) {
        number = _newNumber;
        return viewNumber();
    }

    //This function just changes the number and doesn't call the view function internally so it costs less

    function JustChangeNumber(uint256 _newNumber) public {
        number = _newNumber;
    }


}