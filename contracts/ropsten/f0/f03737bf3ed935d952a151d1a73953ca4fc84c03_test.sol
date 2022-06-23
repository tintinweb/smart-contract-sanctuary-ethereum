/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

pragma solidity ^0.8.0;

contract test {
    uint number;

    function set_number (uint _user_number) public {
        number = _user_number;
  }

    function view_number () public view returns (uint) {
        return number;
    }

}