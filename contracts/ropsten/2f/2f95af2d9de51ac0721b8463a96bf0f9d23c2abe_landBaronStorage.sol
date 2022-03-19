/**
 *Submitted for verification at Etherscan.io on 2022-03-18
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

//web3 engineer www.twitter.com/SCowboy88

contract landBaronStorage{
    address owner;
    address public propertiesContract;
    address public grouperLooperContractAddress;
    address public votingContractAddress;


    modifier onlyVotingContract{
        require(msg.sender == votingContractAddress, "Only the owner of the contract can call this function");
        _;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner, "Only the owner of the contract can call this function");
        _;
    }

    modifier onlyPropertyContract{
        require(msg.sender == propertiesContract, "Only the property contract can call this function");
        _;
    }


    constructor(){
        owner = msg.sender;
    } 

    function getOwner() external view returns(address){
        return owner;
    }

    function transferOwnership(address _newOwner) external onlyOwner{
        owner = _newOwner;
    }

    ///////////////Only Owner//////////////////

    function setPropertiesContract(address _propertiesContractAddress) external onlyOwner{
        propertiesContract = _propertiesContractAddress;
    }

    function setVotingContractAddress(address _votingContractAddress) external onlyOwner{
        votingContractAddress = _votingContractAddress;
    }
    ////////////////////////////////


    ///////////////////Properties Contract////////////////
    mapping (address=>bool) tenant;

    struct reservationTimes{
        address tenantAddress;
        uint startTimestamp;
        uint stopTimestamp;
    }

    reservationTimes[] reset; //for resetting reservations array for property

    mapping (string=>bool) reservableStatus;
    mapping (string=>bool) propertyExists;
    mapping (string=>reservationTimes[]) reservations;
    
    string[] properties;

    function addTenant(address _address) external onlyPropertyContract{
        tenant[_address] = true;
    }

    function removeTenant(address _address) external onlyPropertyContract{
        tenant[_address] = false;
    }

    function isTenant(address _address) external view returns(bool) {
        return tenant[_address];
    }

    function updateProperties(string[] memory _properties) external onlyPropertyContract{
        properties = _properties;
    }

    function getProperties() external view returns(string[] memory){
        return properties;
    }

    function getReservableStatus(string calldata _propertyName) external view returns(bool){
        return reservableStatus[_propertyName];
    }

    function getPropertyExists(string calldata _propertyName) external view returns(bool){
        return propertyExists[_propertyName];
    }

    function getReservations(string calldata _propertyName) external view returns(reservationTimes[] memory){
        require(propertyExists[_propertyName], "Property doesn't exist");
        return reservations[_propertyName];
    }

    function setReservableStatus(string calldata _propertyName, bool _status) external onlyPropertyContract{
        reservableStatus[_propertyName] = _status;
    }

    function setPropertyExists(string calldata _propertyName, bool _status) external onlyPropertyContract{
        propertyExists[_propertyName] = _status;
    }

    function resetReservations(string calldata _propertyName) external onlyPropertyContract{
        reservations[_propertyName] = reset;
    }

    function addReservation(address _address, string calldata _propertyName, uint _startTimestamp, uint _stopTimestamp) external onlyPropertyContract{
        reservations[_propertyName].push(reservationTimes(_address, _startTimestamp, _stopTimestamp));
    }
    /////////////////End Properties Contract//////////////





    //////////////Land Baron Token Contract///////////////
    uint price = 1000000000000000000;
    // address = [];
    //////////////End Land Baron Contract/////////////////



    //////////////Land Baron Voting Contract///////////////
    struct option{
        string propertyName;
        string propertyLink;
        uint voteCount;
    }

    struct vote{
        uint voteId;
        string voteName;
        uint startTimestamp;
        uint stopTimestamp;
        bool status;
        uint votesCount;
    }

    mapping (string=>vote) voteDetails;
    mapping (string=>option[]) options;

    vote[] votes;
    uint voteIncrementor = 0;

    struct choice {
        string voteName;
        uint choice;
    }

    mapping(address=>choice[]) submittedVotes;
    address[] voters;

    function addSubmittedVotes(address _address, string calldata _voteName, uint _choice) external onlyVotingContract{
        submittedVotes[_address].push(choice(_voteName, _choice));
    }

    function getSubmittedVotes(address _address, string calldata _voteName) external view returns(choice memory){
        return submittedVotes[_address][voteDetails[_voteName].voteId];
    }

    function getVoteDetails(string calldata _voteName) external view returns(vote memory){
        return voteDetails[_voteName];
    }

    function addVote(string calldata _voteName, uint _startTimestamp, uint _stopTimestamp) external onlyVotingContract{
        votes.push(voteDetails[_voteName] = vote(voteIncrementor, _voteName, _startTimestamp, _stopTimestamp, true, 0));
        voteIncrementor++;
    }

    function getOptions(string calldata _voteName) public view returns(option[] memory){
        return options[_voteName];
    }

    function addOption(string calldata _voteName, string calldata _propertyName, string calldata _propertyLink) external onlyVotingContract{
        options[_voteName].push(option(_propertyName, _propertyLink, 0));
    }

    function getVoteOptions(string calldata _voteName) public view returns(option[] memory){
        require(voteDetails[_voteName].stopTimestamp > block.timestamp, "The voting time period has expired for the vote you chose");
        require(keccak256(abi.encodePacked(voteDetails[_voteName].voteName)) == keccak256(abi.encodePacked(_voteName)), "Vote name don't exist");
        return options[_voteName];
    }

    function getVotes() public view returns(vote[] memory){
        return votes;
    }

    function addVoter(address _address) external onlyVotingContract{
        voters.push(_address);
    }

    function getVoteChoice(string calldata _voteName) public view returns(choice memory){
        require(keccak256(abi.encodePacked(submittedVotes[msg.sender][voteDetails[_voteName].voteId].voteName)) == keccak256(abi.encodePacked(_voteName)), "Looks like you haven't cast a vote yet.");
        return submittedVotes[msg.sender][voteDetails[_voteName].voteId];
    }

    function incrementVoteCount(string calldata _voteName, uint _choice) external onlyVotingContract{
        options[_voteName][_choice-1].voteCount++;
    }

    function getVoteCount(string calldata _voteName, uint _choice) external view returns(uint){
        return options[_voteName][_choice-1].voteCount;
    }
    //////////////End Land Baron Voting Contract/////////////////

}