// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract CheeseChainV2 {

    uint public totalSteps; //starts at 0
    uint public totalLots; //starts at 0
    address public administrator;

    enum Role {
        ViewOnly,
        Basic,
        Laboratory,
        MilkProducer
    }

    //structs
    struct Coordinates {
        string latitude;
        string longitude;
    }

    struct Participant {
        string name;
        Role role;
        address owner;
    }

    struct TestResult {
        bool result;
        uint timestamp;
    }

    struct Lot {
        TestResult testResult;
        uint lastStep;
        uint timestamp;
        uint[] milkBatchId;
    }

    struct Step {
        address owner;
        uint previousStep;
        uint timestamp;
        string description;
        Coordinates coordinates;
    }

    constructor() {
        administrator = msg.sender;
    }

    //getter function for Lot
    function getLot(uint lotNumber) external view returns (Lot memory){
        return lots[lotNumber];
    }

    //mappings
    mapping(uint => Step) public steps;
    mapping(uint => Lot) public lots;
    mapping(address => Participant) public participants;


    //events
    event LotAdded(uint indexed _lotId, uint _timestamp);
    event StepAdded(uint indexed _stepId, uint _timestamp);
    event ParticipantAdded(Participant participant);
    event LabResultAdded(uint indexed _lotId, bool indexed _result, uint indexed _timestamp);
    event RoleChanged(Participant participant);


    //modifiers
    modifier onlyAdministrator {
        require(msg.sender == administrator, 'This function is only callable by an admin!');
        _;
    }
    modifier onlyBasicParticipant {
        require(isAdministrator(msg.sender) || isBasicParticipant(msg.sender), 'Msg.sender is not basic or admin');
        _;
    }
    modifier onlyLaboratory {
        require(isAdministrator(msg.sender) || isLaboratory(msg.sender), 'Msg.sender is not lab or admin');
        _;
    }
    modifier notEmptyAddress(address _address) {
        require(_address != address(0), 'The address cannot be a 0 address!');
        _;
    }
    modifier participantDoesntExist(address _address){
        require(participants[_address].owner == address(0), "A participant with this address exists already");
        _;
    }
    modifier participantExists(address _address){
        require(participants[_address].owner != address(0), "A participant with this address does not exist");
        _;
    }
    modifier lotExists(uint _lotId){
        require(lots[_lotId].timestamp != 0, 'The lot with the given number does not exist!');
        _;
    }

    modifier milkBatchExists(uint[] calldata _batchIds){
        require(_batchIds.length > 0, "Please provide at least one milk batch identifier!");
        for (uint i=0; i < _batchIds.length; i++){
            require(milkBatches[_batchIds[i]].timestamp != 0, "Please provide only existing milk batch identifiers");
        }
        _;
    }


    //utility functions
    function isBasicParticipant(address _address) view public returns(bool) {
        return participants[_address].role == Role.Basic;
    }

    function isLaboratory(address _address) view public returns(bool) {
        return participants[_address].role == Role.Laboratory;
    }

    function isAdministrator(address _address) view public returns(bool) {
        return _address == administrator;
    }


    //actual functions
    // extended
    function addLot(uint[] calldata milkBatchIds) onlyBasicParticipant milkBatchExists(milkBatchIds) external {
        totalLots += 1;
        TestResult memory test = TestResult(false, 0);
        lots[totalLots] = Lot(test, 0, block.timestamp, milkBatchIds);
        emit LotAdded(totalLots, block.timestamp);
    }

    function addStep(uint lotNumber, string calldata description, Coordinates calldata coordinates) onlyBasicParticipant lotExists(lotNumber) external {
        totalSteps += 1;
        steps[totalSteps] = Step(msg.sender, lots[lotNumber].lastStep, block.timestamp, description, coordinates);
        lots[lotNumber].lastStep = totalSteps;
        emit StepAdded(totalSteps, block.timestamp);
    }

    function addLabResult(uint lotNumber, bool result) onlyLaboratory external {
        lots[lotNumber].testResult = TestResult(result, block.timestamp);
        emit LabResultAdded(lotNumber, result, block.timestamp);
    }

    function addParticipant(Participant calldata participant)
    onlyAdministrator
    notEmptyAddress(participant.owner)
    participantDoesntExist(participant.owner)
    external {
        participants[participant.owner] = participant;
        emit ParticipantAdded(participant);
    }

    function removeParticipant(address _address) onlyAdministrator participantExists(_address) external {
        delete participants[_address];
    }

    function changeParticipantRole(address _address, Role _newRole) onlyAdministrator participantExists(_address) external {
        participants[_address].role = _newRole;
        emit RoleChanged(participants[_address]);
    }

    // extended

    uint public totalBatches;

    struct MilkBatch {
        uint timestamp;
        address owner;
        Coordinates coordinates;
    }

    mapping(uint => MilkBatch) public milkBatches;

    function isMilkProducer(address _address) view public returns(bool) {
        return participants[_address].role == Role.MilkProducer;
    }

    modifier onlyMilkProducer(){
        require(isAdministrator(msg.sender) || isMilkProducer(msg.sender), 'This function is only callable by a milk producer!');
        _;
    }

    event NewMilkBatch(uint indexed _milkBatchId, uint _timestamp);

    function addMilkBatch(Coordinates calldata coordinates) onlyMilkProducer external {
        totalBatches += 1;
        milkBatches[totalBatches] = MilkBatch(block.timestamp, msg.sender, coordinates);
        emit NewMilkBatch(totalBatches, block.timestamp);
    }

}