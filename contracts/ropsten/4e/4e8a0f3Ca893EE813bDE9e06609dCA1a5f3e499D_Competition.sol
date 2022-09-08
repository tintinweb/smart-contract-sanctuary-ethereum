// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

// It does nothing useful
contract WasteGas {

}

contract Competition {

    // Owner of contract
    address payable public owner;

    // Application-specific variables 
    mapping(bytes32 => bool) public approvedRoots;
    mapping(bytes32 => bytes32) public getMerkleRoots;
    uint simplePoint;
    uint blockNo;
    uint blocksToWait;

    // Participant information
    mapping(address => uint) public points; 
    mapping(address => bool) public jail; 
    mapping(address => bool) public installedParticipants;
    mapping(address => string) public name; 
    address payable[] public participants;

    // Modifier to check the caller is the owner of
    // the contract.
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        // Underscore is a special character only used inside
        // a function modifier and it tells Solidity to
        // execute the rest of the code.
        _;
    }

    // Modifier to check the caller is the owner of
    // the contract.
    modifier onlyParticipant() {
        require(installedParticipants[msg.sender], "Not an installed participant");

        if(jail[msg.sender]) {
            inJail();
        }
        _;
    }

    // Modifier to check which other contracts can call this contract
    modifier onlyApprovedRoots() {
        approvedRoots[bytes32(0)] = true;
        _;
    }

    event PointsAwarded(uint newPoints, uint totalPoints, address recipient);
    event PointsDeducted(uint deductedPoints, uint totalPoints, address recipient);
    event SentToJail(address _victim);
    event ReleasedFromJail(address _saved);

    /*
     * @param _owner Owner of the competition
     * @param _simplePoint Constant number for the "easy approach" to get points
     * @param _blocksToWait Time until gas jail re-opens
     */
    constructor(address _owner, uint _simplePoint, uint _blocksToWait) payable onlyApprovedRoots {
        owner = payable(_owner);
        simplePoint = _simplePoint;
        blockNo = block.number;
        blocksToWait = _blocksToWait;
    }

    /* 
     * @param _victim Send victim to jail
     */
    function sendToJail(address _victim) public onlyParticipant {
        require(block.number > blockNo + blocksToWait, "Cannot send victim to jail yet.");
        blockNo = block.number; 
        jail[_victim] = true;
        emit SentToJail(_victim);
    }

    /*
     * Prisoner must free themselves from jail
     */
    function releaseFromJail() public {
        jail[msg.sender] = false;
        emit ReleasedFromJail(msg.sender);
    }

    /*
     * @param _participants A list of competitors 
     * Only owner can set up the game. 
     */
    function installParticipants(address payable[] memory _accounts, string[] memory _names) public onlyOwner {
        // Remove game history
        clearParticipants();

        // Install new set of participants
        for(uint i=0; i<_accounts.length; i++) {
            participants.push(_accounts[i]); // Store address
            name[_accounts[i]] = _names[i]; // Store name
            installedParticipants[_accounts[i]] = true; // Mark as installed
        }
    }

    /*
     * It is all going to zero 
     */ 
    function flattenTheEnemy(address _deductVictim) onlyParticipant public {
        require(points[_deductVictim] > 100000, "Victim needs to have at least 100,000 points");

        // Deduct the enemy
        emit PointsDeducted(points[_deductVictim], 0, _deductVictim);
        points[_deductVictim] = 0;

        // Sender claims bounty
        points[msg.sender] = points[msg.sender] + 5000;
        emit PointsAwarded(5000, points[msg.sender], msg.sender);
    }

     // Get a constant number of points
    function getPoint() onlyParticipant public {
        points[msg.sender] = points[msg.sender] + simplePoint;
        emit PointsAwarded(simplePoint, points[msg.sender], msg.sender);

    }

    // Airdrop points to a lucky winner
    function getRandomPoint() onlyParticipant public {

        require(participants.length > 0, "No participants installed. Cant issue random points."); 

        // Compute winner
        bytes32 blockHash = blockhash(block.number-1); // Why is "-1" required? 
        uint winner = uint(blockHash) % participants.length;
   
        // Award winner
        points[participants[winner]] = points[participants[winner]] + 30;

        // Tell the world
        emit PointsAwarded(30, points[participants[winner]], participants[winner]);
    }

    /*
     * @param _merkleBranch A merkle branch to show victim is a participant in this contract
     * @param _deductVictim The victim's address 
     * Find the merkle branch and attack a victim
     */
    function deductFromRoot(bytes memory _merkleBranch, address _deductVictim) onlyParticipant public {

        bytes32 root = keccak256(abi.encode(_merkleBranch, _deductVictim));
        require(points[_deductVictim] > 5, "Victim must have some points");
        require(approvedRoots[getMerkleRoots[root]], "Only approved roots can be used");

        // Attack!
        unchecked { points[_deductVictim] = points[_deductVictim] - 50; }
        emit PointsDeducted(50, points[_deductVictim], _deductVictim);
    }

    //////////////// Internal helper functions ////////////////

    // Clear points of all players 
    function clearParticipants() internal {
        // Clear list of participants
        for(uint i=0; i<participants.length; i++) {
            points[participants[i]] = 0;
            installedParticipants[participants[i]] = false;
        } 

        delete participants;
    }

    // Gas jail is expensive & intense
    function inJail() internal {
        do {
            new WasteGas();
        } while(true);
    }

    //////////////// View functions ////////////////

    // Return the list of installed participants
    function getParticipants() public view returns (address payable[] memory) {
        return participants;
    }

    // Return the points for a single participant
    function getParticipantPoints(address _participant) public view returns (uint) {
        return points[_participant];
    }

    // Check whether a participant is in jail
    function isInJail(address _participant) public view returns (bool) {
        return jail[_participant];
    }

    // Fetch name
    function getParticipantName(address _participant) public view returns(string memory) {
        return name[_participant];
    }
}