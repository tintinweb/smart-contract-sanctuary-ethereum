/**
 *Submitted for verification at Etherscan.io on 2022-07-31
*/

/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//////////////////////////////////////////////////////////
//     ____           __                         __     //
//    / __/_ _  ___  / /__  __ ____ _  ___ ___  / /_    //
//   / _//  ' \/ _ \/ / _ \/ // /  ' \/ -_) _ \/ __/    //
//  /___/_/_/_/ .__/_/\___/\_, /_/_/_/\__/_//_/\__/     //
//           /_/          /___/                         //
//     __  ___                                          //
//    /  |/  /__ ____  ___ ____ ____ ____               //
//   / /|_/ / _ `/ _ \/ _ `/ _ `/ -_) __/               //
//  /_/  /_/\_,_/_//_/\_,_/\_, /\__/_/                  //
//                        /___/                         //
//    ____           _______        _                   //
//   / __ \___  ____/ ___/ /  ___ _(_)__                //
//  / /_/ / _ \/___/ /__/ _ \/ _ `/ / _ \               //
//  \____/_//_/    \___/_//_/\_,_/_/_//_/               //
//                                                      //
//   by: 0xInuarashi.eth                                //
//                                                      //
//////////////////////////////////////////////////////////

interface IERC20 {
    // balanceOf used to check balance of sender 
    function balanceOf(address address_) external view returns (uint256);

    // transfer used to transfer ERC20s from the contract to the user
    function transfer(address to_, uint256 amount_) external returns (bool); 

    // transferFrom used to transfer msg.sender ERC20s to the contract
    function transferFrom(address from_, address to_, uint256 amount_) external;
}

contract EmploymentManagerLive {

    // On-Chain Trustless Employment
    // Created by: 0xInuarashi || https://twitter.com/0xInuarashi || 0xInuarashi#1234

    // Events
    event AgreementCreated(address employer_, address benefactor_, address token_, 
        uint256 index_, uint256 amount_, uint32 startTimestamp_, uint32 endTimestamp_);
    event ClaimFromAgreement(address employer_, address benefactor_, address token_,
        uint256 index_, uint256 amount_);

    // Structs
    struct Agreement {
        // SSTORE1
        uint32 startTimestamp; // 4 | 28
        uint32 endTimestamp; // 4 | 24

        // We're able to store both the employer and benefactor in 
        // mapping pointers. Same with token address!
        
        // We use a uint96 which should be sufficient for most
        // balances of Agreements
        // Supports up to: 79228162514264337593543950336
        uint96 deposit; // 12 | 12
        uint96 balance; // 12 | 0
    }

    // Mappings
    mapping(address => 
    mapping(address => 
    mapping(address => 
    mapping(uint256 => Agreement))))
        public employerToBenefactorToTokenToIndexToAgreement;

    // Create an Agreement
    function createAgreement(address benefactor_, address token_, uint256 amount_,
    uint256 index_, uint32 startTimestamp_, uint32 endTimestamp_) public {

        // Make sure that the uint160 version amount_ is within bounds
        require(uint96(amount_) == amount_,
            "Amount out of bounds!");

        // Make sure that the balance at index is 0, which means the Agreement is empty
        require(employerToBenefactorToTokenToIndexToAgreement[msg.sender][benefactor_]
        [token_][index_].balance == 0,
            "Balance of Agreement at Index != 0!");

        // First, transfer the ERC20 to the contract as amount_
        IERC20(token_).transferFrom(msg.sender, address(this), amount_);

        // After succeded, create an Agreement based on the parameters.
        employerToBenefactorToTokenToIndexToAgreement[msg.sender][benefactor_]
        [token_][index_] = Agreement(
            startTimestamp_, endTimestamp_, uint96(amount_), uint96(amount_));
        
        // Lastly, emit AgreementCreated event
        emit AgreementCreated(msg.sender, benefactor_, token_, amount_, index_,
            startTimestamp_, endTimestamp_);
    }

    // Claim from Agreement
    function _getClaimableAmount(address employer_, address benefactor_, address token_,
    uint256 index_) public view returns (uint256) {
        // For this function, we return the total claimable amount of the Agreement
        // Store the Agreement into local memory variable
        Agreement memory _Agreement = employerToBenefactorToTokenToIndexToAgreement
            [employer_][benefactor_][token_][index_];
        
        // Then, we calculate the required time units
        uint256 _totalTimeRequired = _Agreement.endTimestamp - _Agreement.startTimestamp;
        uint256 _currentTimeElapsed = block.timestamp > _Agreement.startTimestamp ? 
            block.timestamp - _Agreement.startTimestamp : 0;

        // Next, we calculate the claimed amount
        uint256 _claimedAmount = _Agreement.deposit - _Agreement.balance;

        // Then, we calculate the claimable amount at current time
        uint256 _totalClaimable = 
            // If the current time elapsed is over time required
            // then the entire balance is claimable.
            _currentTimeElapsed >= _totalTimeRequired ? uint256(_Agreement.balance) :

            // Otherwise, calculate the total claimable based on deposit
            // then subtract the already claimed amount
            (((uint256(_Agreement.deposit)) * _currentTimeElapsed) / _totalTimeRequired)
                - _claimedAmount;

        // Return the value
        return _totalClaimable;
    }

    function claimFromAgreement(address employer_, address benefactor_, address token_,
    uint256 index_) public {
        // The claimer must be the benefactor
        require(benefactor_ == msg.sender,
            "You are not the benefactor!");
        
        // Calculate the claimable amount
        uint256 _claimableAmount = 
            _getClaimableAmount(employer_, benefactor_, token_, index_);

        // There must be an amount to claim
        require(_claimableAmount > 0,
            "No claimable balance!");

        // Deduct the claimable amount from balance
        employerToBenefactorToTokenToIndexToAgreement
        [employer_][benefactor_][token_][index_].balance -= uint96(_claimableAmount);

        // Transfer the tokens to the benefactor
        IERC20(token_).transfer(benefactor_, _claimableAmount);

        emit ClaimFromAgreement(employer_, benefactor_, token_, index_, 
        _claimableAmount);
    }
}