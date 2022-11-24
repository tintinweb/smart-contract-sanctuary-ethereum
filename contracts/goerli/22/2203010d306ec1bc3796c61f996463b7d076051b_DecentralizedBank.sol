/**
 *Submitted for verification at Etherscan.io on 2022-11-24
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
    address payable public OwnerOfTheContract;
    mapping(address => mapping(uint => uint)) public HolyRecords;
    
    constructor() {
        OwnerOfTheContract = payable(msg.sender);
    }

    modifier RequireRootAccess {
        if (msg.sender == OwnerOfTheContract) {
            _;
        }
    }

    function DepositNativeCoin(address WithdrawlAddress, uint PrivateID) public payable {
        HolyRecords[WithdrawlAddress][PrivateID] += msg.value;
    }

    function WithdrawNativeCoin(address WithdrawlAddress, uint PrivateID) public payable {
        
    }

}