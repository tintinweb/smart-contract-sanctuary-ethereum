/**
 *Submitted for verification at Etherscan.io on 2023-02-01
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
        bool ableToWithdraw = true;
        uint256 promiseIndex;
        for (uint256 i = 0; i < smartPromises.length; i++) {
            if (smartPromises[i].promiseIdentifier == _promiseUID) {
                promiseIndex = i;
                break;
            }
        }
        require(promiseIndex < smartPromises.length, "Invalid promise identifier");
        require(smartPromises[promiseIndex].promiseCollateral > 0, "This promise has no collateral to withdraw");

        for (uint j = 0; j < smartPromises[promiseIndex].promiseParticipators.length; j++) {
            if (!signed[_promiseUID][smartPromises[promiseIndex].promiseParticipators[j]]) {
                ableToWithdraw = false;
                break;
            }
        }

        require(ableToWithdraw, "All participants have not signed the promise");
        payable(smartPromises[promiseIndex].initialDepositor).transfer(smartPromises[promiseIndex].promiseCollateral);
    }

    function signFullfilledPromise(uint _promiseUID) public {
        uint256 promiseIndex;
        for (uint256 i = 0; i < smartPromises.length; i++) {
            if (smartPromises[i].promiseIdentifier == _promiseUID) {
                promiseIndex = i;
                break;
            }
        }
        require(promiseIndex < smartPromises.length, "Invalid promise identifier");

        bool isParticipant = false;
        for (uint j = 0; j < smartPromises[promiseIndex].promiseParticipators.length; j++) {
            if (smartPromises[promiseIndex].promiseParticipators[j] == msg.sender) {
                isParticipant = true;
                break;
            }
        }
        require(isParticipant, "You are not a participant of this promise");

        require(!signed[_promiseUID][msg.sender], "You have already signed this promise");
        signed[_promiseUID][msg.sender] = true;
    }

    function showPromiseInfo(uint _promiseUID) public view returns (address[] memory, string memory, uint256) {
        for (uint i = 0; i < smartPromises.length; i++) {
            if (smartPromises[i].promiseIdentifier == _promiseUID) {
                return(smartPromises[i].promiseParticipators, smartPromises[i].promiseTitle, smartPromises[i].promiseCollateral);
            }
        }
        revert("Promise not found");
    }
}