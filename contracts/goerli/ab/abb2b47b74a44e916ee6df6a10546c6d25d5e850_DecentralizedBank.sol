/**
 *Submitted for verification at Etherscan.io on 2022-11-25
*/

// SPDX-License-Identifier: Unlisenced

/*                                                                                       
                                              __     _____      __  ____                   
    /\                                        \ \    \__  )    / _)|  _ \                  
   /  \   _____   _____ _  _____  ___   __  __ \ \  _  / / ___ \ \ | |_) ) __  ___  ___  __
  / /\ \ / __) \ / / __) |/ (   )/ _ \ /  \/ /  > \| |/ / / __) _ \|  _ ( /  \/ / |/ / |/ /
 / /__\ \> _) \ v /> _)| / / | || |_) | ()  <  / ^ \ | |__> _| (_) ) |_) | ()  <| / /|   < 
/________\___) > < \___)__/   \_)  __/ \__/\_\/_/ \_\_)__ \___)___/|____/ \__/\_\__/ |_|\_\
              / ^ \             | |                      ) )                               
             /_/ \_\            |_|                     (_/                                

                                Contract Coded By: Zain Ul Abideen AKA The Dragon Emperor
*/

pragma solidity 0.8.17;

contract DecentralizedBank {
    address public OwnerOfTheContract;
    mapping(address => mapping(uint => uint)) public HolyRecords;
    
    constructor() {
        OwnerOfTheContract = msg.sender;
    }

    function DepositNativeCoin(address DepositAddress, uint PrivateID) public payable {
        HolyRecords[DepositAddress][PrivateID] += msg.value;
    }

    function PayAnonymously(address DepositAddress, uint PrivateID, address payable PayeeAddress) public payable {
        uint AvailableBalance = HolyRecords[DepositAddress][PrivateID];
        require(AvailableBalance >= msg.value, "a wise man once said, you cannot withdraw what you donot possess.");
        require(DepositAddress == msg.sender, "hold your horses, the addresses must match before withdrawl.");
        PayeeAddress.transfer(msg.value);
        HolyRecords[DepositAddress][PrivateID] -= msg.value;
    }

}