// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// create a timer for increement and decreement but they should only work after 30secs 

contract count{
    uint256 count;
     uint256 lastRun;

    function add() external {
        require(block.timestamp - lastRun > 30 seconds, 'Need to wait 30 seconds, be calming down');

        // TODO perform the action

        lastRun = block.timestamp;
        count++;
      
}

    function dec() external {
        require(block.timestamp - lastRun > 30 seconds, 'Need to wait 30 seconds, be calming down');

        // TODO perform the action

        lastRun = block.timestamp;

        count--;
        
}

 function getlastRun() public view returns (uint256){
      return count;
  }

}