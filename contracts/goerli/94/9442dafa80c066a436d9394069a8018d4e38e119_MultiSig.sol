/**
 *Submitted for verification at Etherscan.io on 2022-07-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title MultiSig
*/
contract MultiSig {
    
    enum OwnerStatus{ NONE, OWNER, WAITING }
    address[] public owners;
    mapping(address=>OwnerStatus) isOwner;

    address[] waitingOwners;
    mapping(address=>WaitingOwner) waitingOwnerConfirmations;

    struct WaitingOwner{
        bool addOrRemove;
        uint confirmCount;
        mapping(address=>bool) confirmedBy;
    }

    // EVENTS
    event OwnerAddRequest(address owner);
    event OwnerRemoveRequest(address owner);
    event OwnerRequestConfirmation(address owner);
    event OwnerRemoveConfirmation(address owner);
    event OwnerAdd(address owner);
    event OwnerRemove(address owner);

    // MODIFIERS
    modifier ownerExists(address owner) {
        require(isOwner[owner]==OwnerStatus.OWNER, "Caller is not owner");
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


    // Owner Management Functions

    function newOwnerRequest(address addr)
        public
        ownerExists(msg.sender)
    {
        require(isOwner[addr] == OwnerStatus.NONE);
        waitingOwners.push(addr);
        isOwner[addr] = OwnerStatus.WAITING;
        waitingOwnerConfirmations[addr].addOrRemove = true;
        emit OwnerAddRequest(addr);
        confirmNewOwner(addr);
    }

    function confirmNewOwner(address addr)
        public
        ownerExists(msg.sender)
    {
        require(isOwner[addr]==OwnerStatus.WAITING);
        require(!waitingOwnerConfirmations[addr].confirmedBy[msg.sender]);
        waitingOwnerConfirmations[addr].confirmCount++;
        waitingOwnerConfirmations[addr].confirmedBy[msg.sender] = true;
        emit OwnerRequestConfirmation(addr);
        addOwner(addr);
    }

    function removeOwnerRequest(address addr)
        public
        ownerExists(msg.sender)
        ownerExists(addr)
    {
        waitingOwners.push(addr);
        waitingOwnerConfirmations[addr].addOrRemove = false;
        emit OwnerRemoveRequest(addr);
        confirmRemoveOwner(addr);
    }

    function confirmRemoveOwner(address addr)
        public
        ownerExists(msg.sender)
        ownerExists(addr)
    {
        require(!waitingOwnerConfirmations[addr].confirmedBy[msg.sender]);
        waitingOwnerConfirmations[addr].confirmCount++;
        waitingOwnerConfirmations[addr].confirmedBy[msg.sender] = true;
        emit OwnerRemoveConfirmation(addr);
        removeOwner(addr);
    }


    // INTERNALS

    function addOwner(address addr) 
        internal
        ownerDoesNotExists(addr)
    {
        if(waitingOwnerConfirmations[addr].confirmCount>=(owners.length+1)/2) {
            owners.push(addr);
            isOwner[addr] = OwnerStatus.OWNER;
            delete waitingOwnerConfirmations[addr];
            uint idx = 0;
            while(waitingOwners[idx]!=addr) idx++;
            waitingOwners[idx] = waitingOwners[waitingOwners.length-1];
            waitingOwners.pop();
            emit OwnerAdd(addr);
        }
    }

    function removeOwner(address addr) 
        internal
        ownerExists(addr)
    {
        if(waitingOwnerConfirmations[addr].confirmCount>=(owners.length+1)/2) {
            isOwner[addr] = OwnerStatus.NONE;
            delete waitingOwnerConfirmations[addr];
            uint idx = 0;
            while(owners[idx]!=addr) idx++;
            owners[idx] = owners[owners.length-1];
            owners.pop();
            emit OwnerAdd(addr);
        }
    }


    // View Functions

    function getOwners() public view returns(address[] memory) {
        return owners;
    }
    function getWaitingOwners() public view returns(address[] memory) {
        return waitingOwners;
    }
    function getWaitingOwnerStatus(address addr) public view returns(uint, uint, bool) 
    {
        return (waitingOwnerConfirmations[addr].confirmCount, owners.length, waitingOwnerConfirmations[addr].addOrRemove);
    }

    receive() external payable{}
}