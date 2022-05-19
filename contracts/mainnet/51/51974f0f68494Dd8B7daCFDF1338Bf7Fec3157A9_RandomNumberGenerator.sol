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

    // Non-duplicate methods

    // Simple random number generating does not account for duplication.
    // Thus, I created a method to account for duplication, at the cost of a loooooot
    // (and I mean, a looooot) of processing cost as solidity does not have a 
    // native method to find duplicates.

    // We create an internal function to check an array for duplicate numbers and return
    // a bool value.
    function _existsInArray(uint256[] memory randomNumbers_, uint256 lengthToCheck_,
    uint256 numberToCheck_) internal pure returns (bool) {
        // Run through the defined length on the array to check
        for (uint256 i = 0; i <= lengthToCheck_; i++) {
            // If the number to check exists in the randomNumbers_ array
            if (numberToCheck_ == randomNumbers_[i]) {
                return true;
            }
        }

        // If the loop runs and no if-statements hit then...
        return false;
    }

    // Now, we define a free view-only function for free usage
    function returnRandomNumbersNoDuplicates(uint256 maxNumber_, uint256 amount_) public
    view returns (uint256[] memory) {
        // First, we create a memory array with intended size
        uint256[] memory _randomNumbers = new uint256[] (amount_);

        // Then, here we create an internal nonce to use
        uint256 _internalNonce;

        // Then, we call the RNC contract to consume its number with nonces for seed
        for (uint256 i = 0; i < amount_; i++) {

            // NoDuplicates: we first loop through the entire memory array to check if 
            // the returned number exists in the array already. If so, pull a new number
            // and run the check again.

            uint256 _randomNumber = RNC.returnRandomNumber(maxNumber_, _internalNonce);
            
            // Keep doing this if _existsInArray returns true
            while (_existsInArray(_randomNumbers, i, _randomNumber)) {
                // Increase the nonce and reroll the number
                _randomNumber = RNC.returnRandomNumber(maxNumber_, ++_internalNonce);
            }

            // If the doesn't exist in the array... Increase the _internalNonce 
            _internalNonce++;

            // And set the _randomNumber into the array!
            _randomNumbers[i] = _randomNumber;
        }

        // After the entire loop runs, return the _randomNumbers array.
        return _randomNumbers;
    }

    // This function can get stupidly expensive. CHECK YOUR GAS COSTS FIRST.
    // The cost grows exponentially with the number of items you want.
    function emitRandomNumbersNoDuplicates(string calldata message_, uint256 maxNumber_,
    uint256 amount_) external returns (uint256[] memory) {
        // First, we call returnRandomNumbers() to get the array
        uint256[] memory _randomNumbers = 
            returnRandomNumbersNoDuplicates(maxNumber_, amount_);
        
        // Now, we emit the standard event.
        emit RandomNumbersPulled(message_, _randomNumbers);

        // Return it in case external contracts or functions want to interface this
        return _randomNumbers;
    }
}