// SPDX-License-Identifier: UNLICENCED
pragma solidity 0.8.7;

contract Oracle {
    
    address admin;
    mapping(address => bool) private signers;
    uint256 public lastActionTimestamp;
    bool public paused;
    uint256 timeThreshold;

    constructor(address _admin, uint256 _timeThreshold){
        admin = _admin;
        timeThreshold = _timeThreshold;
        lastActionTimestamp = block.timestamp;
    }

    modifier isAdmin(){
        require(msg.sender == admin, "Caller is not admin");
        _;
    }

    modifier isActive(){
        require(!paused, "Contract is paused");
        _;
    }

    modifier isModifiable(){
        require(block.timestamp > lastActionTimestamp + timeThreshold, "Last action is too recent");
        _;
    }

    modifier isUnpausable(){
        require(paused,"Contract is not paused");
        require(block.timestamp > lastActionTimestamp + 2*timeThreshold, "Last action is too recent");
        _;
    }

    function getSigner(address _signer) public view returns(bool){
        return signers[_signer];
    }

    function addSigner(address _signer) external isAdmin isActive isModifiable {
        signers[_signer]=true;
        lastActionTimestamp = block.timestamp;
    }

    function removeSigner(address _signer) external isAdmin isActive isModifiable {
        signers[_signer]=false;
        lastActionTimestamp = block.timestamp;
    }

    function pause() external isAdmin {
        paused = true;
        lastActionTimestamp = block.timestamp;
        
    }

    function unpause() external isAdmin isUnpausable {
        paused = false;
        lastActionTimestamp = block.timestamp;
    }
}