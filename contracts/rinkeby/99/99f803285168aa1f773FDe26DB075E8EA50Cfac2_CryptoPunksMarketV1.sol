// SPDX-License-Identifier: UNLICENSED
/// @title CryptoPunksMarket
/// @notice Mock CryptoPunksMarket v1
/// @author CyberPnk <[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.2;

// import "hardhat/console.sol";

// Mock CryptoPunksMarket to use in rinkeby
contract CryptoPunksMarketV1 {
    mapping (uint => address) public punkIndexToAddress;

    constructor() {
        punkIndexToAddress[1] = address(this);
        punkIndexToAddress[2] = msg.sender;
        punkIndexToAddress[3] = address(this);
        punkIndexToAddress[4] = msg.sender;
        punkIndexToAddress[5] = address(this);
        punkIndexToAddress[6] = msg.sender;
        punkIndexToAddress[7] = address(this);
        punkIndexToAddress[8] = msg.sender;
        punkIndexToAddress[9] = address(this);
    }

}