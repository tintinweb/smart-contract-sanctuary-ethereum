/**
 *Submitted for verification at Etherscan.io on 2022-12-28
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract Owner {

    address private owner;
    
    // event for EVM logging
    event OwnerSet(address indexed oldOwner, address indexed newOwner);
    
    // modifier to check if caller is owner
    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }
    
    /**
     * @dev Set contract deployer as owner
     */
    constructor() {
        owner = msg.sender; // 'msg.sender' is sender of current call, contract deployer for a constructor
        emit OwnerSet(address(0), owner);
    }

    /**
     * @dev Change owner
     * @param newOwner address of new owner
     */
    function changeOwner(address newOwner) public isOwner {
        emit OwnerSet(owner, newOwner);
        owner = newOwner;
    }

    /**
     * @dev Return owner address 
     * @return address of owner
     */
    function getOwner() external view returns (address) {
        return owner;
    }
}

struct Geofence
{
    int32 down_lat_x100000;
    int32 up_lat_x100000;
    int32 left_lon_x100000;
    int32 right_lon_x100000;
}

contract SmartProposal is Owner {
    bool public saidYes = false;
    bool public saidNo = false;
    uint32 public proposal_expected_time = 0;
    int32 public proposal_location_lat_x100000;
    int32 public proposal_location_lon_x100000;
    bytes32 public proposal_yes_art_hash = 0;
    bool public location_verified = false;
    
    Geofence geofence; 

    bytes32 private proposal_his_proof_hash = 0;
    bytes32 private proposal_her_proof_hash = 0;
    
    // events
    event LocationVerifiedEvent();
    event ProposalExpectedTimeEvent(uint32 timestamp);
    event ProposalEvent(bool yes, bool no);
    
    constructor(int32 down_lat_x100000, int32 up_lat_x100000, int32 left_lon_x100000, int32 right_lon_x100000) {
        geofence.down_lat_x100000 = down_lat_x100000; 
        geofence.up_lat_x100000 = up_lat_x100000;
        geofence.left_lon_x100000 =  left_lon_x100000; 
        geofence.right_lon_x100000 = right_lon_x100000;
    }

    function verifyLocation(int32 lat_x100000, int32 lon_x100000) external isOwner
    {   
        //require(location_verified == false, "Location has been already verified");
        //check left -> right
        require((lon_x100000 >= geofence.left_lon_x100000 && lon_x100000 <= geofence.right_lon_x100000), "Wrong location"); 
        //check down -> up
        require((lat_x100000 >= geofence.down_lat_x100000 && lat_x100000 <= geofence.up_lat_x100000), "Wrong location");
    
        location_verified = true;
        emit LocationVerifiedEvent();
    }

    function setProposalExpectedTime(uint32 timestamp) public isOwner
    {   
        require(location_verified == true, "Location has not been verified yet");
        require(timestamp >= block.timestamp, "Time is in the past");
        // require(proposal_expected_time == 0, "Expected time of proposal has been already set");
        proposal_expected_time = timestamp;
        emit ProposalExpectedTimeEvent(proposal_expected_time);
    }

    function sayYes(int32 lat_x100000, int32 lon_x100000, bytes32 her_proof_hash, bytes32 his_proof_hash) external payable isOwner 
    {   
        require((block.timestamp >= proposal_expected_time - 600) && (block.timestamp <= proposal_expected_time + 600), 
            "Time is up'");
        require((saidNo == false) && (saidYes == false), "Proposal has been already finished ");
        require(msg.value >= 0.0035 ether, "Deposit is too small");
        proposal_her_proof_hash = her_proof_hash;
        proposal_his_proof_hash = his_proof_hash;
        saidYes = true;
        proposal_location_lat_x100000 = lat_x100000;
        proposal_location_lon_x100000 = lon_x100000;
        emit ProposalEvent(saidYes, saidNo);
    }

    function sayNo() external isOwner
    {   
        require((block.timestamp >= proposal_expected_time - 600) && (block.timestamp <= proposal_expected_time + 600), 
            "Time is up'");
        require((saidNo == false) && (saidYes == false), "Proposal has been already finished ");
        saidNo = true;
        emit ProposalEvent(saidYes, saidNo);
    }
    
    function setProposalArtHash(bytes32 art_hash) external isOwner
    {
        require((block.timestamp >= proposal_expected_time - 600) && (block.timestamp <= proposal_expected_time + 600), 
            "Time is up");
        require(saidYes == true, "Yes is needed");
        proposal_yes_art_hash = art_hash;
    }

    function getProposalFund(bytes memory her_proof, bytes memory his_proof) external payable
    {
        require(saidYes == true, "Yes is needed");
        require(msg.value >= 0.00035 ether, "Deposit is too small");
        bytes32 her_hash = keccak256(her_proof);
        bytes32 his_hash = keccak256(his_proof);
        if((her_hash == proposal_her_proof_hash) && (his_hash == proposal_his_proof_hash)) 
        {
            uint256 amount = address(this).balance;
            (bool success,) = msg.sender.call{value:amount}("");
            require(success, "Withdrawal error");
        }     
    }
}