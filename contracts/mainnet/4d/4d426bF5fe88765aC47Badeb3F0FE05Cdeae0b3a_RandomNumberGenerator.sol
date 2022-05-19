/**
 *Submitted for verification at Etherscan.io on 2022-05-19
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//////////////////////////////////////////////////////////////////////////
//     ___               __             _  __           __              //
//    / _ \___ ____  ___/ /__  __ _    / |/ /_ ____ _  / /  ___ ____    //
//   / , _/ _ `/ _ \/ _  / _ \/  ' \  /    / // /  ' \/ _ \/ -_) __/    //
//  /_/|_|\_,_/_//_/\_,_/\___/_/_/_/ /_/|_/\_,_/_/_/_/_.__/\__/_/       //
//    _____                      __                                     //
//   / ___/__ ___  ___ _______ _/ /____  ____                           //
//  / (_ / -_) _ \/ -_) __/ _ `/ __/ _ \/ __/                           //
//  \___/\__/_//_/\__/_/  \_,_/\__/\___/_/                              //
//                                                 by: 0xInuarashi.eth  //
//////////////////////////////////////////////////////////////////////////

// RandomNumberGenerator is the second interface of RandomNumberConsumer
// Made back in October 2021 by 0xInuarashi

// That contract generates random numbers.
// This contract interfaces that contract to return a fixed-array 
// Random number by using the random number from the RNC contract
// As a seed and then using nonces to increase the randomness.

interface IRandomNumberConsumer {
    function returnRandomNumber(uint256 maxNumber_, uint256 nonce_) external 
    view returns (uint256);
}

contract RandomNumberGenerator {

    // here, we define the event to store random numbers with a message and numbers
    event RandomNumbersPulled(string message_, uint256[] numbers_);

    // First, we define the contract interface.
    IRandomNumberConsumer public RNC = 
        IRandomNumberConsumer(0x9eE37A86b73fC615322E71D281a350A51dF2B3c3);

    // Now, we define a free view-only function for free usage
    function returnRandomNumbers(uint256 maxNumber_, uint256 amount_) public
    view returns (uint256[] memory) {
        // First, we create a memory array with intended size
        uint256[] memory _randomNumbers = new uint256[] (amount_);

        // Then, we call the RNC contract to consume its number with nonces for seed
        for (uint256 i = 0; i < amount_; i++) {
            _randomNumbers[i] = RNC.returnRandomNumber(maxNumber_, i);
        }

        return _randomNumbers;
    }

    // Now, we define a cheap event emitter that emits the random numbers as a 
    // way to store it on the blockchain. Accompanied with a message_ argument
    // so that you can define what the emitted numbers were for.
    function emitRandomNumbers(string calldata message_, uint256 maxNumber_,
    uint256 amount_) external returns (uint256[] memory) {
        // First, we call returnRandomNumbers() to get the array
        uint256[] memory _randomNumbers = returnRandomNumbers(maxNumber_, amount_);
        
        // Now, we emit the standard event.
        emit RandomNumbersPulled(message_, _randomNumbers);

        // Return it in case external contracts or functions want to interface this
        return _randomNumbers;
    }
}