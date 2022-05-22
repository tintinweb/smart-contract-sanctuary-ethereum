/**
 *Submitted for verification at Etherscan.io on 2022-05-22
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;




contract HugSenderWithGifts{

 uint256 totalHugs;
 Hug[] hugs;
 mapping(address => uint256) public lastWavedAt;
 event NewHug(address indexed from, uint256 timestamp, string message);
struct Hug {
        address hugger; // The address of the user who waved.
        string message; // The message the user sent.
        uint256 timestamp; // The timestamp when the user waved.
    }
    receive() external payable {
        // you can leave this function body empty
    }

    constructor() payable {
  
}



    function hugMe(string memory _message) public {
        require(
            lastWavedAt[msg.sender] + 15 minutes < block.timestamp,
            "Wait 15m"
        );

        /*
         * Update the current timestamp we have for the user
         */
        lastWavedAt[msg.sender] = block.timestamp;
        totalHugs += 1;
      

        hugs.push(Hug(msg.sender, _message, block.timestamp));
         emit NewHug(msg.sender, block.timestamp, _message);
         uint256 prizeAmount = 0.00001 ether;
    require(
        prizeAmount <= address(this).balance,
        "Trying to withdraw more money than the contract has."
    );
    (bool success, ) = (msg.sender).call{value: prizeAmount}("");
    // (msg.sender).call{value: prizeAmount}("");
    require(success, "Failed to withdraw money from contract.");
}
    

    function getTotalHugs() public view returns (uint256) {
       
        return totalHugs;
    }

    function getAllHugs()public view returns (Hug[] memory) {
        // Optional: Add this line if you want to see the contract print the value!
        // We'll also print it over in run.js as well.
      
        return hugs;
    }

    function getLastHugged()public view returns (uint256) {
       
        return lastWavedAt[address(this)];
    }



}