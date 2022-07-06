/**
 *Submitted for verification at Etherscan.io on 2022-07-06
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

contract HealthyEmployee {
    mapping(address => uint256) coffeeKitchenLatestAqcuiredTime;
    mapping(address => uint256) diningHallLatestAqcuiredTime;
    mapping(address => uint256) starBalances;
    address[] userAddresses;

    address private contractOwner;

    constructor() {
        contractOwner = msg.sender;
    }

    modifier onlyOwner {
    	//is the message sender owner of the contract?
        require(msg.sender == contractOwner,"Caller Address is not owner of the contract");
        _;
    }

    
    //-----------------------------------------------
    // Utility Section
    //-----------------------------------------------
    function secretUtil(uint256 val1, uint256 val2) public pure returns (bytes memory) {
        return (abi.encode(val1, val2));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    //-----------------------------------------------
    // Contract Owner Administrative Section
    //-----------------------------------------------

    function fundContract() onlyOwner public payable {
        // Directly Funds the Contract with the Gas Price
    }

    function getUserAddresses() onlyOwner public view returns(address[] memory) {
        return userAddresses;
    }

    function getDebugData(address[] memory usrAddresses) onlyOwner public view returns(string memory) {
        string memory userStarBalances;
        for(uint index=0; index<usrAddresses.length; index++){
            userStarBalances = string.concat(userStarBalances,",");
            userStarBalances = string.concat(userStarBalances,toString(starBalances[usrAddresses[index]]));
        }
        return userStarBalances;
    }

    //-----------------------------------------------
    // Writable Transaction Section
    //-----------------------------------------------

    function requestStarCoinFromCoffeeKitchenFaucet(bytes memory data) public {
        // Is Faucet Available
        uint256 epochNow = block.timestamp;
        uint256 secondsInPartialDay = ( epochNow % ( 60 * 60 * 24 ));
        uint256 hour = ( secondsInPartialDay / ( 60 * 60 ) ) ;
        require(hour >= 5 && hour <= 15,"Coffee Kitchen Faucet is active from 8AM to 6PM UTC");

        // Is Caller Already Retrieved
        address callerAddress = msg.sender;
        uint256 userLastRetrieveTime = coffeeKitchenLatestAqcuiredTime[callerAddress];
        if (userLastRetrieveTime != 0){
            require(userLastRetrieveTime < epochNow - 7200,"You need to wait for 2 hours from your last call");
        }

        // Check Location of the Caller.
        uint256 longitude;
        uint256 lattitude;
        (longitude, lattitude) = abi.decode(data, (uint256, uint256));    
        require((longitude > 40900581) && (longitude < 40900847)  && (lattitude > 29201414) && (lattitude < 29201748),"You are not near by the coffee kitchen");

        // Mint StarCoin For Caller                
        uint256 starBalance = starBalances[callerAddress];
        if(starBalance == 0){
            userAddresses.push(callerAddress);
        }
        starBalances[callerAddress] = starBalance + 2;
        coffeeKitchenLatestAqcuiredTime[callerAddress] = epochNow;  
    }

    function requestStarCoinFromDiningHallFaucet() public {
        // Is Faucet Available
        uint256 epochNow = block.timestamp;
        uint256 secondsInPartialDay = ( epochNow % ( 60 * 60 * 24 ));
        uint256 hour = ( secondsInPartialDay / ( 60 * 60 ) ) ;
        require(hour >= 8 && hour <= 11,"Dining Hall Faucet is active from 11AM to 2PM UTC");

        // Is Caller Already Retrieved
        address callerAddress = msg.sender;
        uint256 userLastRetrieveTime = diningHallLatestAqcuiredTime[callerAddress];
        if (userLastRetrieveTime != 0){
            require(userLastRetrieveTime < epochNow - 36000,"You can request star coin from this faucet once in a day");
        }

        // Mint StarCoin For Caller
        uint256 starBalance = starBalances[callerAddress];
        if(starBalance == 0){
            userAddresses.push(callerAddress);
        }
        starBalances[callerAddress] = starBalance + 5;
        diningHallLatestAqcuiredTime[callerAddress] = epochNow;  
    }

    //-----------------------------------------------
    // ReadOnly View Calls Section
    //-----------------------------------------------

    function getStarBalance(address usrAddress) public view returns(uint256){
        return starBalances[usrAddress];
    }
}