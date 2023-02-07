/**
 *Submitted for verification at Etherscan.io on 2023-02-07
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


// KAMIMART PRODUCTIONS
contract DataMon {
    uint8 public foodSupply = 10;
    bool public hungry;
    bool public alive = true;
    uint256 public currentTime;
    uint8 public feedCounter;
    uint8 public happiness = 10;
    string public status = "Welcome to DataMon!";

    
    
    
    
    function reset() public {
        currentTime = block.timestamp;
        status = "Your DataMon is alive!";
    }

    function check() public {
        while(block.timestamp >= currentTime + 1) {
            feedCounter++;
            currentTime = block.timestamp;
            if(feedCounter > 0) {
                hungry = true;
                happiness--;
                if(happiness <= 0) {
                    alive = false;
                    status = "Your DataMon has died :(";
                }
            }
            
        }
    }
    
    function feed() public {
        if(hungry) {
            happiness = 10;
            foodSupply--;
            status = "Your DataMon is nice and full!";
            hungry = false;
        }
    }

    


}