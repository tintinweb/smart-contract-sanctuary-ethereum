// SPDX-License-Identifier: GPL-3.0
// Implementation of a contract to select validators using an allowlist

pragma solidity >=0.5.0;

import "./ValidatorSmartContractInterface.sol";

contract ValidatorSmartContractAllowList is ValidatorSmartContractInterface {
     event AllowedAccount(
        address indexed account,
        bool added
    );

    event Validator(
        address indexed validator,
        address indexed byAccount,
        uint numValidators,
        bool activated 
    );

    struct accountInfo {
        bool allowed;
        bool activeValidator;
        uint8 validatorIndex;
    }

    uint constant MIN_STAKE = 200;

    address[] private validators;
    mapping(address => accountInfo) private allowedAccounts;
    mapping(address => address) private validatorToAccount;
    uint public numAllowedAccounts;

    mapping(address => address[]) private currentVotes;// mapping the votes for adding or removing an account to the accounts that voted for it

    modifier senderIsAllowed() {
        require(allowedAccounts[msg.sender].allowed, "sender is not on the allowlist");
        _;
    }

    constructor (address[] memory initialAccounts, address[] memory initialValidators, uint initialStake) payable {
        // require(initialAccounts.length > 0, "no initial allowed accounts");
        // require(initialValidators.length > 0, "no initial validator accounts");
        // require(initialAccounts.length >= initialValidators.length, "number of initial accounts smaller than number of initial validators");
        require(initialStake < MIN_STAKE, "number of staking amount cannot be lesser than 200");

        for (uint i = 0; i < initialAccounts.length; i++) {
            require(initialAccounts[i] != address(0), "initial accounts cannot be zero");
            if (i < initialValidators.length) {
                require(initialValidators[i] != address(0), "initial validators cannot be zero");
                allowedAccounts[initialAccounts[i]] = accountInfo(true, true, uint8(i));
                validators.push(initialValidators[i]);
                validatorToAccount[initialValidators[i]] = initialAccounts[i];
            } else {
                allowedAccounts[initialAccounts[i]] = accountInfo(true, false, 0);
            }
        }
        numAllowedAccounts = initialAccounts.length;
    }

    function getValidators() override external view returns (address[] memory) {
        return validators;
    }

}

// ["0xfe94A38BC902A9E094F2a3bE369F33eEe6E57e60","0x97f451c13fCF354194A730A6E207a786281A8C85"]