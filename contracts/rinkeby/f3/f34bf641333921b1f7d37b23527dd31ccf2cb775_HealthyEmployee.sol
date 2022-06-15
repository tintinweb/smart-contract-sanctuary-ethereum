/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.14;

contract HealthyEmployee {
    
    
    mapping(address => uint256) public coffeKitchenLatestAqcuiredBalances;
    mapping(address => uint256) public diningHallLatestAqcuiredBalances;
    mapping(address => uint256) public starBalances;

    function requestStarCoinFromCoffeeKitchenFaucet() public {
        address callerAddress = msg.sender;
        uint256 userLastRetrieveTime = coffeKitchenLatestAqcuiredBalances[callerAddress];

        uint256 epochNow = block.timestamp;
        uint256 secondsInPartialDay = ( epochNow % ( 60 * 60 * 24 ));
        uint256 hour = ( secondsInPartialDay / ( 60 * 60 ) ) ;

        require(hour >= 5 && hour <= 15,"Coffee Kitchen Faucet is active from 5AM to 3PM UTC");

        if (userLastRetrieveTime != 0){
            require(userLastRetrieveTime < epochNow - 7200,"You need to wait for 2 hours from your last call");
        }

        uint256 starBalance = starBalances[callerAddress];
        starBalances[callerAddress] = starBalance + 2;
        coffeKitchenLatestAqcuiredBalances[callerAddress] = epochNow;  
    }

    function requestStarCoinFromDiningHallFaucet() public {
        address callerAddress = msg.sender;
        uint256 userLastRetrieveTime = diningHallLatestAqcuiredBalances[callerAddress];

        uint256 epochNow = block.timestamp;
        uint256 secondsInPartialDay = ( epochNow % ( 60 * 60 * 24 ));
        uint256 hour = ( secondsInPartialDay / ( 60 * 60 ) ) ;

        require(hour >= 8 && hour <= 11,"Dining Hall Faucet is active from 11AM to 2PM UTC");

        if (userLastRetrieveTime != 0){
            require(userLastRetrieveTime < epochNow - 36000,"You can request star coin from this faucet once in a day");
        }

        uint256 starBalance = starBalances[callerAddress];
        starBalances[callerAddress] = starBalance + 5;
        diningHallLatestAqcuiredBalances[callerAddress] = epochNow;  
    }

    function getStarBalance(address usrAddress) public view returns(uint256){
        return starBalances[usrAddress];
    }
}