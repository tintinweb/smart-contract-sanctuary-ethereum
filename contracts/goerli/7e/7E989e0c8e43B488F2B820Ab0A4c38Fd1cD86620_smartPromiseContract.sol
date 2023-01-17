/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.3;

contract smartPromiseContract {
    
    struct promiseData {
        address initialDepositor;
        uint256 promiseCollateral;
        string promiseTitle;
        uint promiseIdentifier;
        uint promiseAcceptDeadline;
        address[] promiseParticipators;
    }

    promiseData[] public smartPromises;
    mapping(uint => mapping(address => bool)) signed;
    event SmartPromiseCreated(uint promiseIdentifier);

    // mapping(promiseData.promiseIdentifier => bool) signed;

    function createSmartPromise(string memory _promiseTitle) public payable { //returns (uint promiseIdentifier) {
        promiseData memory newPromise;
        newPromise.initialDepositor = msg.sender;
        newPromise.promiseCollateral = msg.value;
        newPromise.promiseTitle = _promiseTitle;
        newPromise.promiseIdentifier = uint(keccak256(abi.encodePacked(
            block.difficulty, block.timestamp, block.coinbase))) % 2**160; 
            //generates a random number to use as a identifier
        signed[newPromise.promiseIdentifier][msg.sender] = false;
        newPromise.promiseAcceptDeadline = block.timestamp + 10 minutes;
        smartPromises.push(newPromise);
        promiseData storage arrPushPromise = smartPromises[smartPromises.length - 1];
        arrPushPromise.promiseParticipators.push(msg.sender);
        //return newPromise.promiseIdentifier;
        emit SmartPromiseCreated(newPromise.promiseIdentifier);
    }


    function joinPromise(uint _promiseUID) public payable {
        bool ableToJoin;
        for (uint i = 0; i < smartPromises.length; i++) {
            if (smartPromises[i].promiseIdentifier == _promiseUID &&
            smartPromises[i].promiseAcceptDeadline > block.timestamp &&
            smartPromises[i].promiseCollateral == msg.value) {
                ableToJoin = true;
                smartPromises[i].promiseParticipators.push(msg.sender); 
                signed[_promiseUID][msg.sender] = false;
                break;
            }
        }
        require(ableToJoin, "Error: Invalid promise UID or deadline has passed or collateral does not match");
    }

    function endSmartPromise(uint _promiseUID) public payable {
        bool ableToWithdraw = false;
        for (uint i = 0; i < smartPromises.length; i++) {
            if (smartPromises[i].promiseIdentifier == _promiseUID && smartPromises[i].promiseCollateral > 0) {
                for (uint j = 0; j < smartPromises[i].promiseParticipators.length; j++) {
                    require(signed[_promiseUID][smartPromises[i].promiseParticipators[j]], "test");
                    ableToWithdraw = true;
                }
                payable(msg.sender).transfer(smartPromises[i].promiseCollateral);
                break;
            }
        }
        require(ableToWithdraw, "Invalid promise identifier");
    }

    function signFullfilledPromise(uint _promiseUID) public {
        for (uint i = 0; i < smartPromises.length; i++) {
            if (smartPromises[i].promiseIdentifier == _promiseUID) {
                for (uint j = 0; j < smartPromises[i].promiseParticipators.length; j++) {
                    if (smartPromises[i].promiseParticipators[j] == msg.sender) {
                        require (!signed[_promiseUID][msg.sender], "You are not a participant of this promise");
                        signed[_promiseUID][msg.sender] = true;
                        break;
                    }
                }
            }
        }
    }

    function emptyPromiseData() public {
        delete smartPromises;
    }

    function showPromiseParticipants(uint _promiseUID) public view returns (address[] memory) {
        for (uint i = 0; i < smartPromises.length; i++) {
            if (smartPromises[i].promiseIdentifier == _promiseUID) {
                return smartPromises[i].promiseParticipators;
            }
        }
        revert("Promise not found");
    }
}