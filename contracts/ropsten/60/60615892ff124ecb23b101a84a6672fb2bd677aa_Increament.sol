/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

//SPDX-License-Identifier:MIT

pragma solidity 0.8.15;

contract Increament {
    uint _totalValue;
    event Increamented (uint _totalValue, uint _newvalue);

    function increament (uint _newvalue) external {
        _totalValue += _newvalue;

        emit Increamented( _totalValue,  _newvalue);
  }

  
}