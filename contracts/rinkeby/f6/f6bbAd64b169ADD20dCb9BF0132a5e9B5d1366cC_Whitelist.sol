/**
 *Submitted for verification at Etherscan.io on 2022-08-07
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//create contract

contract Whitelist{

    // Max number of whitelisted addresses allowed 宣告較小的型別可以節省gas
    uint8 public maxWhitelistAddresses;
    // Create a mapping of whitelistedAddresses mapping是一種函數式宣告型別，為array
    mapping(address => bool) public  whitelistedAddresses;
    // numAddressesWhitelisted would be used to keep track of how many addresses have been whitelisted
    // NOTE: Don't change this variable name, as it will be part of verification
    uint8 public numAddressesWhitelisted;
    // Setting the Max number of whitelisted addresses
    // User will put the value at the time of deployment
    constructor(uint8 _maxWhitelistAddresses){ //deploy時啟動
        maxWhitelistAddresses = _maxWhitelistAddresses;
        }

    /**
          addAddressToWhitelist - This function adds the address of the sender to the
          whitelist
    */
    function addAddressToWhitelist() public {
        // check if the user has already been whitelisted 若狀態錯誤則輸出錯誤訊息，會將剩餘的 Gas 歸還，並將合約狀態回復
        require(!whitelistedAddresses[msg.sender],"Sender has already been whitelisted");
        // check if the numAddressesWhitelisted < maxWhitelistedAddresses, if not then throw an numAddressesWhitelisted < maxWhitelistedAddresses.
        require(numAddressesWhitelisted < maxWhitelistAddresses,"More addresses cant be added, limit reached");
        // Add the address which called the function to the whitelistedAddress array
        //若不屬於上述錯誤狀態則加入白名單
        whitelistedAddresses[msg.sender]=true;
        // Increase the number of whitelisted addresses
        numAddressesWhitelisted += 1;
    }

}