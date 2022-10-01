// Implementation of a contract to select validators using an allowlist

pragma solidity >=0.5.0;

import "../ValidatorSmartContractInterface.sol";

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

    event Vote(
        address indexed accountVotedFor,
        address indexed votingAccount,
        uint numVotes,
        uint numVotesNeeded,
        bool voteToAdd,
        bool voteRemoved
    );

    struct accountInfo {
        bool allowed;
        bool activeValidator;
        uint8 validatorIndex;
    }

    uint constant MAX_VALIDATORS = 256;

    address[] private validators;
    mapping(address => accountInfo) private allowedAccounts;
    mapping(address => address) private validatorToAccount;
    uint public numAllowedAccounts;
    mapping(address => address[]) private currentVotes;// mapping the votes for adding or removing an account to the accounts that voted for it

    modifier senderIsAllowed() {
        require(allowedAccounts[msg.sender].allowed, "sender is not on the allowlist");
        _;
    }

    constructor (address[] memory initialAccounts, address[] memory initialValidators) public {
        require(initialAccounts.length > 0, "no initial allowed accounts");
        require(initialValidators.length > 0, "no initial validator accounts");
        require(initialAccounts.length >= initialValidators.length, "number of initial accounts smaller than number of initial validators");
        require(initialValidators.length < MAX_VALIDATORS, "number of validators cannot be larger than 256");

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

    function getValidators() external view returns (address[] memory) {
        return validators;
    }

    function getNewValidators() external view returns (address[] memory) {
        return validators;
    }

    function activate(address newValidator) external senderIsAllowed {
        require(newValidator != address(0), "cannot activate validator with address 0");
        uint i;
        for (i=0; i < validators.length; i++) {
            require(newValidator != validators[i], "validator is already active");
        }
        if (allowedAccounts[msg.sender].activeValidator) {
            validators[allowedAccounts[msg.sender].validatorIndex] = newValidator;
        } else {
            require(validators.length < MAX_VALIDATORS, "number of validators cannot be larger than 256");
            allowedAccounts[msg.sender].activeValidator = true;
            allowedAccounts[msg.sender].validatorIndex = uint8(validators.length);
            validators.push(newValidator);
        }
        validatorToAccount[newValidator] = msg.sender;
        emit Validator(newValidator, msg.sender, validators.length, true);
    }

    function deactivate() external senderIsAllowed {
        require(validators.length > 1, "cannot deactivate last validator");
        require(allowedAccounts[msg.sender].activeValidator, "sender does not have an active validator");
        allowedAccounts[msg.sender].activeValidator = false;
        uint8 deactivatedValidatorIndex = allowedAccounts[msg.sender].validatorIndex;
        address validatorRemoved = validators[deactivatedValidatorIndex];
        address validatorToBeMoved = validators[validators.length-1];
        validators[deactivatedValidatorIndex] = validatorToBeMoved;
        allowedAccounts[validatorToAccount[validatorToBeMoved]].validatorIndex = deactivatedValidatorIndex;
        validators.pop();
        delete(validatorToAccount[validatorRemoved]);
        emit Validator(validatorRemoved, msg.sender, validators.length, false);
    }

    function voteToAddAccountToAllowList(address account) external senderIsAllowed {
        require(allowedAccounts[account].allowed == false, "account to add is already on the allow list");

        for (uint i=0; i < currentVotes[account].length; i++) {
            require(currentVotes[account][i] != msg.sender, "sender has already voted to add account");
        }
        currentVotes[account].push(msg.sender);
        emit Vote(account, msg.sender, currentVotes[account].length, numAllowedAccounts/2 + 1, true, false);
    }

    function voteToRemoveAccountFromAllowList(address account) external senderIsAllowed {
        require(account != address(0), "account to be added cannot be 0");
        require(allowedAccounts[account].allowed == true, "account to remove is not on the allow list");

        for (uint i=0; i < currentVotes[account].length; i++) {
            require(currentVotes[account][i] != msg.sender, "sender has already voted to remove account");
        }
        currentVotes[account].push(msg.sender);
        emit Vote(account, msg.sender, currentVotes[account].length, numAllowedAccounts/2 + 1, false, false);
    }

    function removeVoteForAccount(address account) external senderIsAllowed {
        for (uint i=0; i < currentVotes[account].length; i++) {
            if (currentVotes[account][i] == msg.sender) {
                currentVotes[account][i] = currentVotes[account][currentVotes[account].length-1];
                currentVotes[account].pop();
                break;
            }
        }
        emit Vote(account, msg.sender, currentVotes[account].length, numAllowedAccounts/2 + 1, !(allowedAccounts[account].allowed), true);
    }

    function countVotes(address account) external senderIsAllowed returns(uint numVotes, uint requiredVotes, bool electionSucceeded) {
        for (uint i=0; i < currentVotes[account].length; i++) {
            if (allowedAccounts[currentVotes[account][i]].allowed) {
                // only increment numVotes if account that voted is still allowed
                numVotes++;
            }
        }
        if (numVotes > numAllowedAccounts / 2) {
            delete(currentVotes[account]);
            if (allowedAccounts[account].allowed) {
                numAllowedAccounts--;
                if(allowedAccounts[account].activeValidator) {
                    require(validators.length > 1, "cannot remove allowed account with last active validator");
                    uint8 indexToBeOverwritten = allowedAccounts[account].validatorIndex;
                    delete(validatorToAccount[validators[indexToBeOverwritten]]);
                    address validatorToBeMoved = validators[validators.length - 1];
                    validators[indexToBeOverwritten] = validatorToBeMoved;
                    validators.pop();
                    allowedAccounts[validatorToAccount[validatorToBeMoved]].validatorIndex = indexToBeOverwritten;
                }
                delete(allowedAccounts[account]);
            } else {
                numAllowedAccounts++;
                allowedAccounts[account] = accountInfo(true, false, 0);
            }
            emit AllowedAccount(account, allowedAccounts[account].allowed);
        }
        return (numVotes, numAllowedAccounts / 2 + 1, numVotes > numAllowedAccounts / 2);
    }
}