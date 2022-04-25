// SPDX-License-Identifier: UNLICENSED
/// @title CryptoPunksMarket
/// @notice Mock CryptoPunksMarket
/// @author CyberPnk <cybe[email protected]>
//        __________________________________________________________________________________________________________
//       _____/\/\/\/\/\______________/\/\________________________________/\/\/\/\/\________________/\/\___________
//      ___/\/\__________/\/\__/\/\__/\/\__________/\/\/\____/\/\__/\/\__/\/\____/\/\__/\/\/\/\____/\/\__/\/\_____ 
//     ___/\/\__________/\/\__/\/\__/\/\/\/\____/\/\/\/\/\__/\/\/\/\____/\/\/\/\/\____/\/\__/\/\__/\/\/\/\_______  
//    ___/\/\____________/\/\/\/\__/\/\__/\/\__/\/\________/\/\________/\/\__________/\/\__/\/\__/\/\/\/\_______   
//   _____/\/\/\/\/\________/\/\__/\/\/\/\______/\/\/\/\__/\/\________/\/\__________/\/\__/\/\__/\/\__/\/\_____    
//  __________________/\/\/\/\________________________________________________________________________________     
// __________________________________________________________________________________________________________     

pragma solidity ^0.8.13;

// Mock CryptoPunksMarket to use in testing
contract CryptoPunksMarket {
    mapping (uint => address) public punkIndexToAddress;

    constructor() {
        punkIndexToAddress[1] = address(this);
        punkIndexToAddress[2] = address(this);
        punkIndexToAddress[3] = msg.sender;
        punkIndexToAddress[4] = address(this);
        punkIndexToAddress[5] = address(this);
        punkIndexToAddress[6] = msg.sender;
        punkIndexToAddress[7] = address(this);
        punkIndexToAddress[8] = address(this);
        punkIndexToAddress[9] = msg.sender;
        punkIndexToAddress[10] = address(this);
        punkIndexToAddress[11] = address(this);
        punkIndexToAddress[12] = msg.sender;
        punkIndexToAddress[13] = address(this);
        punkIndexToAddress[14] = address(this);
        punkIndexToAddress[15] = msg.sender;
        punkIndexToAddress[16] = address(this);
        punkIndexToAddress[17] = address(this);
        punkIndexToAddress[18] = msg.sender;
        punkIndexToAddress[19] = address(this);
        punkIndexToAddress[20] = address(this);
        punkIndexToAddress[21] = msg.sender;
    }

}