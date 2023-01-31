// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract PromiseMe {

    // 3 basic values to track
    address payable promiseProposer;
    address payable promiseRecipient;
    uint256 promiseExpiration;        
    bool promiseClaimed;

    // errors
    error Promise_Has_Not_Expired();
    error Not_Promise_Proposer();
    error Not_Promise_Recipient();
    error AlreadyClaimed();
    error EthTransferFail();
    error Promise_Not_Fuffilled();
    event Claimed(address claimer, address recipient);
    event Reverted(address claimer, address recipient);
    event Received(uint256 amount);    

    constructor(address payable _promiseProposer, address payable _promiseRecipient, uint256 _promiseExpiration) {
        promiseProposer = _promiseProposer;
        promiseRecipient = _promiseRecipient;
        promiseExpiration = _promiseExpiration;
    }    
    
    function promiseFufilled() public view returns (bool) {

        // write arbitary logic about what makes the promiseFuffilled here
        // simple example of just a timebased promise below:
        if (block.timestamp > 1675174404) {
            return true;
        }

        return false;
    }

    function revertPromise() public {

        // can only revert promise to claw back funds if promise has expired
        if (block.timestamp < promiseExpiration) {
            revert Promise_Has_Not_Expired();
        }        
        // check to see if claimer is the promiseProposer
        if (msg.sender != promiseProposer) {
            revert Not_Promise_Proposer();
        }
        // cant claw back funds if promise has already been claimed by recipient
        if (promiseClaimed != false) {
            revert AlreadyClaimed();
        }        
        // send eth to desired recipient. revert txn if transfer fails
        (bool success, ) = promiseProposer.call{ value: address(this).balance }("");
        if (!success) {
            revert EthTransferFail();
        }

        // update promiseClaimed status
        promiseClaimed = true;

        emit Reverted(msg.sender, promiseRecipient);
    }


    function withdrawPromise() public {

        // check to see if claimer is the promise recipient
        if (msg.sender != promiseRecipient) {
            revert Not_Promise_Recipient();
        }
        // cant claw back funds if promise has already been claimed by recipient or reverted by proposer
        if (promiseClaimed != false) {
            revert AlreadyClaimed();
        }    
        // check to see if promise has been fufilled
        if (promiseFufilled() != true) {
            revert Promise_Not_Fuffilled();
        }
        // send eth to desired recipient. revert txn if transfer fails
        (bool success, ) = promiseRecipient.call{ value: address(this).balance }("");
        if (!success) {
            revert EthTransferFail();
        }

        // update promiseClaimed status
        promiseClaimed = true;

        emit Claimed(msg.sender, promiseRecipient);
    }

    receive() external payable {
        emit Received(msg.value);
    }
}