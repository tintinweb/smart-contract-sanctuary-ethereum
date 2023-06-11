// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Commitments {
    struct Commitment {
        bytes32 secretHashed;
        address receiver;
        uint amount;
        uint expiryBlock;
        address bridge;
        bool isCommitment;
        bool alreadyClaimed;
    }

    mapping(bytes32 => Commitment) public commitments;

    event CommitmentClaimed(bytes32 claimedHashed, address receiver, uint amount, uint expiryBlock);
    event CommitmentCreated(bytes32 secretHashed, address receiver, uint amount, uint expiryBlock);
    event CommitmentDeleted(bytes32 secretHashed);
    event CommitmentWithdrawn(bytes32 secretHashed);

    /**
    * @dev Checks if a commitment exists in the `commitments` mapping.
    * @param secretHashed The hash of the secret string.
    * @return exists Boolean.
    **/
    function isCommitment(bytes32 secretHashed) public view returns(bool exists) {
        return commitments[secretHashed].isCommitment;
    }

    /**
    * @dev Removes the commitment from the `commitments` mapping.
    * @param secretHashed The hash of the secret string.
    * @return success Whether the commitment had been successfully deleted.
    **/
    function deleteCommitment(bytes32 secretHashed) public returns(bool success) {
        if(!isCommitment(secretHashed)) revert();
        uint expiryBlock = commitments[secretHashed].expiryBlock;
        require(block.number > expiryBlock, "the withdrawal period has not expired.");
        require(
            commitments[secretHashed].alreadyClaimed == true, 
            "the commitment can still be claimed."
        );
        delete commitments[secretHashed];
        return true;
    }

    /**
    * @dev Removes the commitment from the `commitments` mapping.
    * @param secretHashed The hash of the secret string.
    * @param receiver The address to where the funds must be transfered when claimed. 
    * @param expiryBlock The block when a commitment can no longer be claimed.
    * @return success Whether the commitment had been successfully deleted.
    **/
    function createCommitment(bytes32 secretHashed, address receiver, uint expiryBlock) public payable returns(bool success) {
        uint amount = msg.value;
        address bridge = msg.sender;
        require(commitments[secretHashed].isCommitment == false, "commitment already exists.");
        if(isCommitment(secretHashed)) revert(); 
        Commitment memory newCommitment = Commitment(secretHashed, receiver, amount, expiryBlock, bridge, true, false);
        commitments[secretHashed] = newCommitment;
        emit CommitmentCreated(secretHashed, receiver, msg.value, expiryBlock);
        return true;
    }

    /**
    * @dev Checks if the hash of the secret matches the claimed hash. If that is the 
    * case, moves the funds in the commitment from the contract to the receiver address.
    * Changes the `alreadyClaimed` field to `true`.
    * @param secret The secret string known to the entity who requested the commitment.
    * @param claimedHash The hash of the commitment that the caller is trying to claim.
    **/
    function submitSecret(bytes memory secret, bytes32 claimedHash) public returns(bool success){
        address receiver = commitments[claimedHash].receiver;
        uint amount = commitments[claimedHash].amount;
        uint expiryBlock = commitments[claimedHash].expiryBlock;
        require(keccak256(secret) == claimedHash, "supplied secret does not match the claimed hash.");
        require(block.number <= expiryBlock, "the withdrawal period has expired.");
        require(commitments[claimedHash].alreadyClaimed == false, "the commitment has already been claimed.");
        (bool sent, bytes memory data) = receiver.call{value: amount}("");
        require(sent, "Failed to send Ether");
        commitments[claimedHash].alreadyClaimed = true;
        emit CommitmentClaimed(claimedHash, receiver, amount, expiryBlock);
        return true;
    }

    /**
    * @dev Checks if the commitment has expired. If that is the case, returns the funds
    * in the commitment from the contract back to the bridge. Deletes the commitment.
    * @param secretHashed The hash of the secret string.
    **/
    function withdrawToBridge(bytes32 secretHashed) public {
        if(!isCommitment(secretHashed)) revert();

        address bridge = commitments[secretHashed].bridge;
        uint expiryBlock = commitments[secretHashed].expiryBlock;
        uint amount = commitments[secretHashed].amount;
        require(
            bridge == msg.sender, 
            "only the bridge who created the commitment can withdraw."
        );
        require(block.number > expiryBlock, "the withdrawal period has not expired.");
        require(commitments[secretHashed].alreadyClaimed == false, "the commitment has already been claimed.");
        (bool sent, bytes memory data) = bridge.call{value: amount}("");
        require(sent, "Failed to send Ether");
        deleteCommitment(secretHashed);
        emit CommitmentWithdrawn(secretHashed);
    }
}