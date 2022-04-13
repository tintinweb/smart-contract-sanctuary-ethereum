/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// File: contracts/Storage.sol


pragma solidity 0.8.7;

//web3 engineer www.twitter.com/SCowboy88

interface ITokenContract{
    function balanceOf(address _address) external view returns(uint);
}

contract StorageContract{
    uint ownerStartThirtyDays;
    uint serverStartThirtyDays;
    uint secondsInThirtyDays = 2592000;
    address owner;
    address public propertiesContractAddress;
    address public votingContractAddress;
    address public adminContractAddress;
    address public tokenContractAddress;
    address public serverAddress;

    modifier onlyVotingContract{
        require(msg.sender == votingContractAddress, "Only the owner of the contract can call this function");
        _;
    }

    modifier onlyAdminContract{
        require(msg.sender == adminContractAddress, "Only the owner of the contract can call this function");
        _;
    }

    modifier onlyOwner{
        require(msg.sender == owner, "Only the owner of the contract can call this function");
        _;
    }

    modifier onlyPropertyContract{
        require(msg.sender == propertiesContractAddress, "Only the property contract can call this function");
        _;
    }


    constructor(){
        owner = msg.sender;
        ownerStartThirtyDays = block.timestamp;
        serverStartThirtyDays = block.timestamp;
    }

    event Received(address, uint);

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function getOwner() external view returns(address){
        return owner;
    }

    function getServerAddress() external view returns(address){
        return serverAddress;
    }

    function transferOwnership(address _newOwner) external onlyOwner{
        owner = _newOwner;
    }

    ///////////////Only Owner//////////////////
    function withdraw() public onlyOwner{
        require((block.timestamp - ownerStartThirtyDays) > secondsInThirtyDays, "You can only withdraw every 30 days.");
        ownerStartThirtyDays = block.timestamp;
        uint withdrawAmt = (address(this).balance / 100) * 10;
        payable(owner).transfer(withdrawAmt);
    }

    function serverWithdraw() public onlyOwner{
        require((block.timestamp - serverStartThirtyDays) > secondsInThirtyDays);
        serverStartThirtyDays = block.timestamp;
        uint withdrawAmt = (address(this).balance / 100) * 5;
        payable(owner).transfer(withdrawAmt);
    }

    function setServerAddress(address _address) external onlyOwner{
        serverAddress = _address;
    }

    function setPropertiesContractAddress(address _propertiesContractAddress) external onlyOwner{
        propertiesContractAddress = _propertiesContractAddress;
    }

    function setVotingContractAddress(address _votingContractAddress) external onlyOwner{
        votingContractAddress = _votingContractAddress;
    }

    function setAdminContractAddress(address _adminContractAddress) external onlyOwner{
        adminContractAddress = _adminContractAddress;
    }

    function setTokenContractAddress(address _tokenContractAddress) external onlyOwner{
        tokenContractAddress = _tokenContractAddress;
    }
    ////////////////////////////////

    ////////// MISC //////////////
    function getContractBalance() external view returns(uint){
        return address(this).balance;
    }

    function getRole() external view returns(string memory, string memory){
        //check if owner
        if(msg.sender == owner){
            if(isTenant(msg.sender)){
                return ("Owner", "Tenant");
            } else{
                return ("Owner", "");
            }
        //check if admin
        }else if(isAdmin(msg.sender)){
            if(isTenant(msg.sender)){
                return ("Admin", "Tenant");
            } else{
                return ("Admin", "");
            }
        //check if tokenHolder
        }else if(ITokenContract(tokenContractAddress).balanceOf(msg.sender) > 0){
            if(isTenant(msg.sender)){
                return ("LandBaron", "Tenant");
            } else{
                return ("LandBaron", "");
            }
        }
        if(isTenant(msg.sender)){
                return("NONE", "Tenant");
            } else{
                return("NONE", "");
            }
    }
    ////////////////////////////////////

    ///////////////////Admin Contract////////////////

    uint adminCounter = 0;
    uint maxAdmins = 10;
    mapping (address=>uint) adminId;
    mapping (uint=>address) admin;
    mapping (address=>uint) earnings;

    function withdrawUserEarnings(address _address) external onlyAdminContract{
        payable(_address).transfer(earnings[_address]);
    }

    function incrementAdminCounter() external onlyAdminContract{
        adminCounter++;
    }

    function decrementAdminCounter() external onlyAdminContract{
        adminCounter--;
    }

    function getAdminCounter() external view returns(uint){
        return adminCounter;
    }

    function setAdminId(address _address, uint _adminId) external onlyAdminContract{
        adminId[_address] = _adminId;
    }

    function getAdminId(address _address) external view returns(uint){
        return adminId[_address];
    }

    function setEarnings(address _address, uint _approvedAmt) external onlyAdminContract{
        earnings[_address] = _approvedAmt;
    }

    function getEarnings(address _address) external view returns(uint){
        return earnings[_address];
    }

    function setAdmin(uint _adminId, address _address) external onlyAdminContract{
        admin[_adminId] = _address;
    }

    function getAdmin(uint _adminId) external view returns(address){
        return admin[_adminId];
    }

    function getMaxAdmins() external view returns(uint){
        return maxAdmins;
    }

    function isAdmin(address _address) public view returns(bool){
        if(adminId[_address] > 0){
            return true;
        }else{
            return false;
        }
    }

    ///////////////End Admin Contract////////////////


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
    mapping (string=>uint) propertyPricePerHr;
    mapping (string=>reservationTimes[]) reservations;
    
    string[] properties;

    function updatePricePerHr(string calldata _propertyName, uint _pricePerHr) external onlyPropertyContract{
        propertyPricePerHr[_propertyName] = _pricePerHr;
    }

    function getPricePerHr(string calldata _propertyName) external view returns(uint){
        return propertyPricePerHr[_propertyName];
    }

    function addTenant(address _address) external onlyPropertyContract{
        tenant[_address] = true;
    }

    function removeTenant(address _address) external onlyPropertyContract{
        tenant[_address] = false;
    }

    function isTenant(address _address) public view returns(bool) {
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