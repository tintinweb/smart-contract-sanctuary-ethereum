// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract ZEscrow {
    address public owner;
    address public claimer1;
    address public claimer2;
    address public claimer3;
    // hasClaimed[address] == 0 when address has not claimed yet
    // hasClaimed[address] == 1 when address has claimed
    mapping(address => uint16) public hasClaimed;
    // Escrow will have 1.8 ETH if/when proposal goes through
    uint256 public immutable distributionBalance = 1800000000000000000;

    error OnlyOwner();
    error OnlyClaimer();
    error AlreadyClaimed();
    error EthTransferFail();
    event Claimed(address claimer, address recipient);
    event Claimer1Changed(address oldClaimer, address newClaimer);
    event Claimer2Changed(address oldClaimer, address newClaimer);
    event Claimer3Changed(address oldClaimer, address newClaimer);
    event Received(uint256 amount);

    constructor(address _owner, address _claimer1, address _claimer2, address _claimer3 ) {
        owner = _owner;
        claimer1 = _claimer1;
        claimer2 = _claimer2;
        claimer3 = _claimer3;
    }

    function claim(address recipient) public returns (bool) {
        // check if msg.sender is a valid claimer
        if (
            msg.sender != claimer1 && msg.sender != claimer2 
            && msg.sender != claimer3
        ) {
            revert OnlyClaimer();
        }

        // check if msg.sender has already claimed
        if (hasClaimed[msg.sender] != 0) {
            revert AlreadyClaimed();
        }

        // send eth to desired recipient. revert txn if transfer fails
        // eth value being senet = distributionBalance / 3
        (bool success, ) = recipient.call{ value: distributionBalance / 3 }("");
        if (!success) {
            revert EthTransferFail();
        }

        // update hasClaimed value for msg.sender
        // once updated, that claimer address is forever, and corresponding
        //      setClaimerX function will revert forever
        hasClaimed[msg.sender] = 1;

        emit Claimed(msg.sender, recipient);
        return success;
    }

    function setClaimer1(address _claimer) public {
        // only contract owner can update claimers
        if (msg.sender != owner) {
            revert OnlyOwner();
        }
        

        // cannot update claimer1 address if claimer1 has already claimed
        if (hasClaimed[claimer1] != 0) {
            revert AlreadyClaimed();
        }

        claimer1 = _claimer;
    }

    function setClaimer2(address _claimer) public {
        // only contract owner can update claimers        
        if (msg.sender != owner) {
            revert OnlyOwner();
        }

        // cannot update claimer2 address if claimer2 has already claimed
        if (hasClaimed[claimer2] != 0) {
            revert AlreadyClaimed();
        }        

        claimer2 = _claimer;
    }

    function setClaimer3(address _claimer) public {
        // only contract owner can update claimers        
        if (msg.sender != owner) {
            revert OnlyOwner();
        }

        // cannot update claimer3 address if claimer3 has already claimed
        if (hasClaimed[claimer3] != 0) {
            revert AlreadyClaimed();
        }                

        claimer3 = _claimer;
    }     

    receive() external payable {
        emit Received(msg.value);
    }
}