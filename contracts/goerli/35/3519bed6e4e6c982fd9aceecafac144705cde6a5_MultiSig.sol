/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract MultiSig {
    
    enum OwnerStatus{ NONE, OWNER, WAITING }
    address[] public owners;
    mapping(address=>OwnerStatus) isOwner;

    address[] pendingNewOwners;
    address[] pendingRemoveOwners;
    mapping(address=>WaitingOwner) pendingOwnerVotes;

    struct WaitingOwner{
        bool addOrRemove;
        VoteCounter votes;
    }

    struct VoteCounter {
        uint confirmCount;
        uint rejectCount;
        mapping(address=>bool) voters;
    }

    // EVENTS
    event OwnerAddRequest(address owner);
    event OwnerRemoveRequest(address owner);
    event NewOwnerVote(address owner, bool vote);
    event RemoveOwnerVote(address owner, bool vote);
    event NewOwnerResult(address owner, bool result);
    event OwnerRemove(address owner);

    // MODIFIERS
    modifier ownerExists(address owner) {
        require(isOwner[owner]==OwnerStatus.OWNER, "User is not owner");
        _;
    }
    
    modifier ownerDoesNotExists(address owner) {
        require(isOwner[owner]!=OwnerStatus.OWNER, "Owner already exists");
        _;
    }

    constructor(address[] memory _owners) {
        owners = _owners;
        for(uint i =0; i < owners.length; i++) {
            isOwner[owners[i]] = OwnerStatus.OWNER;
        }
    }


    // New Owner

    function newOwnerRequest(address addr)
        public
        ownerExists(msg.sender)
    {
        require(isOwner[addr] == OwnerStatus.NONE);
        pendingNewOwners.push(addr);
        isOwner[addr] = OwnerStatus.WAITING;
        pendingOwnerVotes[addr].addOrRemove = true;
        emit OwnerAddRequest(addr);
        voteNewOwner(addr, true);
    }

    function voteNewOwner(address addr, bool vote)
        public
        ownerExists(msg.sender)
    {
        require(isOwner[addr]==OwnerStatus.WAITING, "There isn't a voting for this user");
        require(!pendingOwnerVotes[addr].votes.voters[msg.sender], "You have already voted");
        if(vote) {
            pendingOwnerVotes[addr].votes.confirmCount++;
        } else {
            pendingOwnerVotes[addr].votes.rejectCount++;
        }
        pendingOwnerVotes[addr].votes.voters[msg.sender] = true;
        emit NewOwnerVote(addr, vote);
        checkNewOwner(addr);
    }

    // Remove Owner

    function removeOwnerRequest(address addr)
        public
        ownerExists(msg.sender)
        ownerExists(addr)
    {
        pendingRemoveOwners.push(addr);
        pendingOwnerVotes[addr].addOrRemove = false;
        emit OwnerRemoveRequest(addr);
        voteRemoveOwner(addr, true);
    }

    function voteRemoveOwner(address addr, bool vote)
        public
        ownerExists(msg.sender)
        ownerExists(addr)
    {
        require(!pendingOwnerVotes[addr].votes.voters[msg.sender]);
        if(vote) {
            pendingOwnerVotes[addr].votes.confirmCount++;
        }else {
            pendingOwnerVotes[addr].votes.rejectCount++;
        }
        pendingOwnerVotes[addr].votes.voters[msg.sender] = true;
        emit RemoveOwnerVote(addr, vote);
        checkRemoveOwner(addr);
    }


    // INTERNALS

    function checkNewOwner(address addr) 
        internal
        ownerDoesNotExists(addr)
    {
        if(pendingOwnerVotes[addr].votes.confirmCount>=(owners.length+1)/2) {
            owners.push(addr);
            isOwner[addr] = OwnerStatus.OWNER;
            delete pendingOwnerVotes[addr];
            removeFromList(pendingNewOwners, addr);
            emit NewOwnerResult(addr, true);
        }
        else if(pendingOwnerVotes[addr].votes.rejectCount>=(owners.length+1)/2) {
            isOwner[addr] = OwnerStatus.NONE;
            delete pendingOwnerVotes[addr];
            removeFromList(pendingNewOwners, addr);
            emit NewOwnerResult(addr, false);
        }
    }

    function checkRemoveOwner(address addr) 
        internal
        ownerExists(addr)
    {
        require(owners.length != 1, "One owner left, can't remove");
        if(pendingOwnerVotes[addr].votes.confirmCount>=(owners.length+1)/2) {
            isOwner[addr] = OwnerStatus.NONE;
            delete pendingOwnerVotes[addr];
            removeFromList(owners, addr);
            removeFromList(pendingRemoveOwners, addr);
            emit OwnerRemove(addr);
        }
        else if(pendingOwnerVotes[addr].votes.rejectCount>=(owners.length+1)/2) {
            delete pendingOwnerVotes[addr];
            removeFromList(pendingRemoveOwners, addr);
            emit OwnerRemove(addr);
        }
    }

    function removeFromList(address[] storage addresses, address addr)
        internal
    {
        if(addresses.length > 1) {
            uint idx = 0;
            while(addresses[idx]!=addr) idx++;
            addresses[idx] = addresses[owners.length-1];
        }
        addresses.pop();
    }


    // View Functions

    function getOwners() public view returns(address[] memory) {
        return owners;
    }
    function getPendingNewOwners() public view returns(address[] memory) {
        return pendingNewOwners;
    }
    function getPendingRemoveOwners() public view returns(address[] memory) {
        return pendingRemoveOwners;
    }
    function getPendingOwnerDetails(address addr) public view returns(uint, uint, uint) {
        return (owners.length, pendingOwnerVotes[addr].votes.confirmCount, pendingOwnerVotes[addr].votes.rejectCount);
    }

    receive() external payable{}
}