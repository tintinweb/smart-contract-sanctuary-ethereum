// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/**
 * @title BallotArchive
 * @author ThompsonA93
 * @notice Stores ballots and their creators in form of mappings
 * @dev Storing data by external smart contract calls.
 */
contract BallotArchive{
    /****************************************/
    /* Variables                            */
    /****************************************/
    address public archiveAddress;
    address public archiveOwner;

    /**
     * @dev Count of ballots. 0 must be reserved for default mapping
     */
    uint public ballotCount = 1;

    /**
     * @dev Map a creators address to all his deployed ballots
     */
    mapping(address => address[]) creators;

    /**
     * @dev Mapping for created ballots
     */
    mapping(address => uint) ballots;

    /**
     * @dev Reverse lookup table for created ballots.
     */
    mapping(uint => address) ballotsRLT;

    /****************************************/
    /* Modifiers                            */
    /****************************************/
    /**
     * Require that one Ballot has exactly one Address.
     */
    modifier ballotDoesNotExist(address _ballot){
        require(ballots[_ballot] == 0);
        _;
    }

    /****************************************/
    /* Functions                            */
    /****************************************/
    /**
     * @dev Setup contract with ownership. TODO -- May be relevant later
     */
    constructor(){
        archiveOwner = msg.sender;
        archiveAddress = address(this);
    }

    /**
     * @param _creator as specified wallet ID
     * @param _ballot as specified smart contract address
     */
    function createNewBallot(address _creator, address _ballot) external ballotDoesNotExist(_ballot) {
        creators[_creator].push(_ballot);

        ballots[_ballot] = ballotCount;
        ballotsRLT[ballotCount] = _ballot;
        
        ballotCount += 1;
    }

    /**
     * @dev Iterate through RLT and fetches ballot address
     */
    function getAllBallots() public view returns(address[] memory){
        address[] memory retSet = new address[](ballotCount-1);
        for(uint i = 1; i < ballotCount; i++){
            retSet[i-1] = ballotsRLT[i];
        }
        return retSet;
    }

    /**
     * @param _creator wallet id to scan for
     * @return address[] as set of deployed contracts from _creator
     */
    function getBallotsByCreator(address _creator) public view returns(address[] memory){
        return creators[_creator];
    }

    /**
     * @param _ballot smart contract to scan for
     * @return address of deployed contract or null-address
     */
    function getBallotByAddress(address _ballot) public view returns(address){
        return (ballots[_ballot] > 0) ? _ballot : address(0);
    }
}