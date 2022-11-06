// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract Abstimmung {

    // event votingResults(string[]);
    // event voters(string[]);
    // event votedPerUser(string[]);

    string[] private useCases = ["0", "1", "1.1", "1.2", "1.3", "1.3.1", "1.3.2", "1.3.3", "1.3.4", "1.3.5",
                                "1.4", "1.5", "1.6", "1.7", "1.8", "1.9", "1.10", "1.11", "1.12", "1.13", 
                                "1.14", "1.15", "1.15.1", "1.15.2", "2", "2.1", "2.1.1", "2.1.2", "2.1.3", "2.1.4", "2.1.5", 
                                "2.1.6", "2.1.7", "2.1.8", "2.1.9", "2.1.10", "2.2", "2.2.1", "2.2.2", 
                                "2.2.3", "2.3", "2.3.1", "2.3.2", "2.3.3", "2.4", "2.5", "3", "3.1", 
                                "3.1.1", "3.1.2", "3.2.3", "3.1.4", "3.2", "3.2.1", "3.2.2", "3.2.3", 
                                "3.2.4", "3.2.5", "3.2.6", "3.2.7", "3.2.8", "3.2.9", "3.2.10", "3.2.11", 
                                "3.2.12", "3.2.13", "3.2.14", "3.2.15", "3.2.16", "3.3", "3.3.1", "3.3.2", 
                                "3.3.3", "3.3.4", "3.3.5", "3.4", "3.4.1", "3.4.2", "3.4.3", "4", "4.1", 
                                "4.1.1", "4.1.2", "4.1.3", "4.1.4", "4.1.5", "4.1.6", "4.1.7", 
                                "4.1.8", "4.1.9", "4.1.10", "4.1.11", "4.1.12", "4.1.13", "4.1.14", "4.1.15", "4.1.16",  
                                "4.2", "4.2.1", "4.2.2", "4.2.3", "4.2.4", "4.2.5", "4.2.6", "4.2.7", "4.3", 
                                "5", "5.1", "5.1.1", "5.1.2", "5.1.3", "5.1.4", "5.2", "5.2.1", "5.2.2", "5.3", 
                                "5.3.1", "5.3.2", "5.3.3", "5.4", "5.4.1", "5.4.2", "6", "6.1", "6.2", "6.2.1", 
                                "6.2.2", "7", "7.1", "7.2", "7.3", "7.4", "7.5", "7.6", "7.7", "7.8"];

    address public owner;
    bool public voteActive;
    bool public voteCleared = true;
    uint256 public totalVotes;

    struct votesStruct {
        address user;
        string[] votesArray;
    }

    mapping(address => votesStruct) private votes;
    mapping(address => uint256) private voteCount;
    mapping(string => uint256) private pointsPerUseCase;
    string[] private votedUseCases;
    address[] private users;

    constructor() payable {
        owner = msg.sender;
    }

    modifier onlyOwner {
        _onlyOwner();
        _;
    }
    modifier onlyUser {
        _onlyUser();
        _;
    }

    modifier requireVotingInactive {
        _requireVotingInactive();
        _;
    }

    modifier requireVotingCleared {
        _requireVotingCleared();
        _;
    }

    modifier requireVotingActive {
        _requireVotingActive();
        _;
    }

    modifier requireVotingUncleared {
        _requireVotingUncleared();
        _;
    }

    function _onlyOwner() internal view returns(bool){
        require(msg.sender == owner, "Not allowed");
        return true;
    }

    function _onlyUser() internal view returns(bool){
        require(voteCount[msg.sender] > 0 || msg.sender == owner, "Not allowed");
        return true;
    }

    function _requireVotingInactive() internal view {
        require(voteActive == false, "Voting active");
    }

    function _requireVotingCleared() internal view {
        require(voteCleared == true, "Voting not cleared");
    }

    function _requireVotingActive() internal view {
        require(voteActive == true, "Voting not active");
    }

    function _requireVotingUncleared() internal view {
        require(voteCleared == false, "Voting already cleared");
    }

    function _deposit() public payable {}

    function _getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function changeOwner(address _newOwner) public onlyOwner requireVotingInactive requireVotingCleared {
        require(_newOwner != msg.sender);
        owner = _newOwner;
    }

    function addUser(address _user) public onlyOwner requireVotingInactive requireVotingCleared {
        address[] memory USERS = users;
        uint256 len = USERS.length;
        uint256 cntUsers;
        for(uint256 i = 0; i < len; i++){
            if(_user == USERS[i]){
                cntUsers++;
            }
        }
        require(cntUsers == 0, "User exists");
        users.push(_user);
        voteCount[_user] = 1;
    }

    function addListOfUsers(address[] memory _userList) public onlyOwner requireVotingInactive requireVotingCleared {
        address[] memory USERS = users;
        uint256 len = USERS.length;
        bytes memory conc = abi.encodePacked("Already in List: ");
        for(uint256 i = 0; i < _userList.length; i++){
            for(uint256 j = 0; j < len; j++){
                if(_userList[i] == USERS[j]){
                    conc = abi.encodePacked(conc, "-- ", Strings.toHexString(USERS[j]), " --,");
                }
            }
        }
        require(keccak256(conc) == keccak256(abi.encodePacked("Already in List: ")), string(conc));
        for(uint256 k = 0; k < _userList.length; k++){
            users.push(_userList[k]);
            voteCount[_userList[k]] = 1;
        }
    }

    function _countUser() public view onlyUser returns(uint256) {
        return users.length;
    }

    function isInUseCases(string memory _useCase) internal view returns (uint256){
        require(keccak256(abi.encodePacked(_useCase)) != keccak256(abi.encodePacked("0")), "Use Case not valid");
        require(keccak256(abi.encodePacked(_useCase)) != keccak256(abi.encodePacked("")), "Use Case not valid");    
        string[] memory USECASES = useCases;
        uint256 lenUC = USECASES.length;
        for(uint256 i = 0; i < lenUC; i++){
            if(keccak256(abi.encodePacked(USECASES[i])) == keccak256(abi.encodePacked(_useCase))){
                return 1;
            }
        } return 0;
    }

    function _addUseCase(string memory _usecase) public onlyOwner requireVotingInactive requireVotingCleared {
        require(isInUseCases(_usecase) == 0, "Already exists");
        useCases.push(_usecase);
    }

    function addUCList(string[] memory _useCaseList) public onlyOwner requireVotingInactive requireVotingCleared {
        string[] memory USECASES = useCases;        
        uint256 lenUC = USECASES.length;
        bytes memory conc = abi.encodePacked("Already in List: ");
        for(uint256 i = 0; i < _useCaseList.length; i++){
            for(uint256 j = 0; j < lenUC; j++){
                if(keccak256(abi.encodePacked(_useCaseList[i])) == keccak256(abi.encodePacked(USECASES[j]))){
                    conc = abi.encodePacked(conc, "-- ", _useCaseList[i]," --,");
                }
            }
        }
        require(keccak256(conc) != keccak256(abi.encodePacked("Already in List: ")), string(conc));
        for(uint256 k = 0; k < _useCaseList.length; k++){
            useCases.push(_useCaseList[k]);
        }
        useCases = USECASES;
    }

    function deleteUseCase(string memory _useCase) public onlyOwner requireVotingInactive requireVotingCleared {
        require(isInUseCases(_useCase) == 1, "No such use case");
        string[] memory USECASES = useCases;
        uint256 lenUC = USECASES.length;
        uint256 cntMember;
        string[] memory newUSECASES = new string[](lenUC-1);
            for(uint256 i = 0; i < lenUC; i++){
                if(keccak256(abi.encodePacked(USECASES[i])) != keccak256(abi.encodePacked(_useCase))){
                    newUSECASES[cntMember] = USECASES[i];
                    cntMember++;
                }
            }
            useCases = newUSECASES;
    }

    function deleteAllUseCases() public onlyOwner requireVotingInactive requireVotingCleared {
        string[] memory newUSECASES = new string[](1);
        newUSECASES[0] = "0";
        useCases = newUSECASES;
    }

    function listUseCases() public view onlyUser returns(string[] memory){
        return useCases;
    }

    function distributeETH() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 5000000000000, "Get more ETH"); // für test minimum 0,0005 ETH // minimum 0,5 ETH
        address[] memory USERS = users;
        uint256 len = USERS.length;
        uint256 distributionAmount = contractBalance / 3 / len;
        for(uint256 i = 0; i < len; i++){
            address payable payableUser = payable(USERS[i]);
            payableUser.transfer(distributionAmount);
        }
    }

    function VOTING(string memory _vote) public onlyUser requireVotingActive {
        require(isInUseCases(_vote) == 1, "No such use case");
        require(voteCount[msg.sender] <= 3, "You voted 3 times");
        string[] memory VOTEDUSECASES = votedUseCases;
        uint256 lenVotedUC = VOTEDUSECASES.length;
        if(voteCount[msg.sender] != 0) {
            string[] memory VOTESARRAY = votes[msg.sender].votesArray;
            uint256 VOTESARRAYLENGTH = VOTESARRAY.length;
            for(uint256 i = 0; i < VOTESARRAYLENGTH; i++){
                if(keccak256(abi.encodePacked(VOTESARRAY[i])) == keccak256(abi.encodePacked(_vote))){
                    revert("You already voted this");
                }
            }
            // add points for vote to use case
            if(VOTESARRAYLENGTH == 0){
                pointsPerUseCase[_vote] += 3;
            } else if(VOTESARRAYLENGTH == 1) {
                pointsPerUseCase[_vote] += 2;
            } else if(VOTESARRAYLENGTH == 2) {
                pointsPerUseCase[_vote] += 1;
            }
        }
        votes[msg.sender].user = msg.sender;
        votes[msg.sender].votesArray.push(_vote);

        // add use case to voted uses cases
        bool inVotedUseCases = false;
        for(uint256 j = 0; j < lenVotedUC; j++){
            if(keccak256(abi.encodePacked(VOTEDUSECASES[j])) == keccak256(abi.encodePacked(_vote))){
                inVotedUseCases = true;
                break;
            }
        } 
        if(inVotedUseCases == false) {
            votedUseCases.push(_vote);
        }
        voteCount[msg.sender]++;
        totalVotes++;
        if(totalVotes == _countUser() *3){
            voteEnd();
        }
    }

    function yourVotes() public view onlyUser requireVotingUncleared returns(string[] memory _yourVotes) {
        string[] memory VOTESARRAY = votes[msg.sender].votesArray;
        uint256 len = VOTESARRAY.length;
        bytes memory conc;
        if(len == 0){
            _yourVotes = new string[](1);
            conc = abi.encodePacked("-- ", "You have not voted yet", " --");
            _yourVotes[0] = string(conc);
        }else{
            _yourVotes = new string[](len);
            for(uint256 i = 0; i < len; i++){
                conc = abi.encodePacked("-- ", VOTESARRAY[i], " --");
                _yourVotes[i] = string(conc);
            }
        }
        return _yourVotes;
    }

    function showUsers() public view onlyUser returns(string[] memory _users){
        address[] memory USERS = users;
        uint256 len = USERS.length;
        _users = new string[](len);
        bytes memory conc;
        for(uint256 i = 0; i < len; i++){
            conc = abi.encodePacked("-- ", Strings.toHexString(USERS[i]), " --");
            _users[i] = string(conc);
        }
        return _users;
    }

    function countVotesPerUser() public view onlyUser requireVotingUncleared returns (string[] memory votesPerUser) {
        uint256 len =  users.length;
        address[] memory USERS = users;        
        votesPerUser = new string[](len);
        bytes memory conc;
        for(uint256 i = 0; i < len; i++){
            conc = abi.encodePacked("-- ", USERS[i], " = ", voteCount[USERS[i]] -1, " --");
            votesPerUser[i] = string(conc);
        }
        return votesPerUser;
    }

    function showVotesByUser() public view onlyUser requireVotingInactive requireVotingUncleared returns(string[] memory votesByUser){
        uint256 len = users.length;
        address[] memory USERS = users;       
        votesByUser = new string[](len);
        bytes memory conc;
        string memory addressString;
        bytes memory addressBytes;
        bytes memory addressShort;
        for(uint256 i = 0; i < len; i++){
            addressString = Strings.toHexString(USERS[i]);
            addressBytes = bytes(addressString);
            addressShort = new bytes(6-0);
            for(uint j = 0; j < 6; j++){
                addressShort[j-0] = addressBytes[j];
            }
            conc = abi.encodePacked("-- ", addressShort, " = ");
            if(votes[USERS[i]].votesArray.length == 0){
                conc = abi.encodePacked(conc, "no votes");
            }else{
                for(uint256 j = 0; j < votes[USERS[i]].votesArray.length; j++){
                    conc = abi.encodePacked(conc, " + ", votes[USERS[i]].votesArray[j]);
                }
            }
            conc = abi.encodePacked(conc, " --");
            votesByUser[i] = string(conc);
        }
        return votesByUser;
    }

    function incompleteVoters() public view onlyUser requireVotingUncleared returns(string[] memory countVotes){
        uint256 countImcompleteVoters;
        address[] memory USERS = users;    
        uint256 len = USERS.length;
        for(uint256 j = 0; j < len; j++){
            if(voteCount[USERS[j]] < 4){  
                 countImcompleteVoters++;
            }
        }
        if(countImcompleteVoters == 0){
            countVotes = new string[](1);
            countVotes[0] = "Everyone has voted 3 times";
        }else{
            countVotes = new string[](countImcompleteVoters);
            bytes memory conc;
            string memory addressString;
            bytes memory addressBytes;
            bytes memory addressShort;
            for(uint256 i = 0; i < len; i++){
                if(voteCount[USERS[i]] < 4){
                    addressString = Strings.toHexString(USERS[i]);
                    addressBytes = bytes(addressString);
                    addressShort = new bytes(6-0);
                    for(uint j = 0; j < 6; j++){
                        addressShort[j-0] = addressBytes[j];
                    }
                    conc = abi.encodePacked("-- ", string(addressShort), " = ", Strings.toString(voteCount[USERS[i]]-1)); 
                    countVotes[i] = string(conc);
                }
            }  
        }
        return countVotes;
    }

    function showRankAndPoints() public view onlyUser requireVotingInactive requireVotingUncleared returns (string[] memory ranks) {  
        string[] memory VOTEDUSECASES = votedUseCases;
        uint256 len = VOTEDUSECASES.length;
        ranks = new string[](len);
        string memory UC = "default";  
        bytes memory conc;
        uint256 VAL;
        bool inRanks;
        for(uint256 j = 0; j < len; j++){   
            VAL = 0;
            for(uint256 i = 0; i < len; i++){
                inRanks = false;
                for(uint256 k = 0; k < ranks.length; k++){
                    if(keccak256(bytes(VOTEDUSECASES[i])) == keccak256(bytes(ranks[k]))){
                        inRanks = true;
                    }
                }
                if(inRanks == false){
                    if(VAL <= pointsPerUseCase[VOTEDUSECASES[i]]){
                        VAL = pointsPerUseCase[VOTEDUSECASES[i]];
                        UC = VOTEDUSECASES[i];
                    }
                }
            }
            conc = abi.encodePacked("-- ", UC, " = ", Strings.toString(VAL), "P --");
            ranks[j] = string(conc);
        }
        return ranks;
    }

    function voteStart() public onlyOwner requireVotingInactive requireVotingCleared  {
        voteCleared = false;
        voteActive = true;
    }

    function voteEnd() public onlyOwner requireVotingActive {
        voteActive = false;
        // emit votingResults(showRankAndPoints());
        // emit voters(showUsers());
        // emit votedPerUser(showVotesByUser());
    }

    function clearVoting() public onlyOwner requireVotingInactive requireVotingUncleared {
        address[] memory USERS = users;
        uint256 len = USERS.length;
        string[] memory USECASES = useCases;
        uint256 lenUC = USECASES.length;
        for(uint256 i = 0; i < len; i++) {
            votes[USERS[i]].user = address(0);
            delete votes[USERS[i]].votesArray;
            delete votes[USERS[i]];
            voteCount[USERS[i]] = 1;
        }
        for(uint256 j = 0; j < lenUC; j++){
            pointsPerUseCase[USECASES[j]] = 0;
        }  
        totalVotes = 0; 
        delete votedUseCases;
        voteCleared = true;
    }

    function _deleteUser(address _user) internal requireVotingInactive requireVotingCleared {
        require(_user != address(0));
        uint256 cntUserinUsers;
        address[] memory USERS = users;
        uint256 len = USERS.length;
        for(uint256 i = 0; i < len; i++){
            if(USERS[i] == _user){
                cntUserinUsers++;
            }
        }
        require(cntUserinUsers > 0, "No such user");
        require(voteCount[_user] >= 0, "No such user");
        uint256 cntMember;
        address[] memory newUSERS = new address[](len-1);
        votes[_user].user = address(0);
        votes[_user].votesArray = new string[](0);
        delete voteCount[_user];
        delete votes[_user];
        for(uint256 i = 0; i < len; i++){
            if(USERS[i] != _user) {
                newUSERS[cntMember] = USERS[i];
                cntMember++;
            }
        }
        users = newUSERS;
    }

    function deleteUser(address _user) public onlyOwner {
        _deleteUser(_user);
    }

    function deleteMySelf() public onlyUser {
        _deleteUser(msg.sender);
    }

    function deleteAllUsers() public onlyOwner requireVotingInactive requireVotingCleared {
        address[] memory USERS = users;
        uint256 len = USERS.length;
        for(uint256 i = 0; i < len; i++){
            votes[USERS[i]].user = address(0);
            votes[USERS[i]].votesArray = new string[](0);
            delete voteCount[USERS[i]];
            delete votes[USERS[i]];
        }
        users = new address[](0);


    }


}


// any maping ietartions? = check if value is null before functionality
// any more dyamic arrays??
// totalVotes kann raus liber in separarter view function über memory counten

// 2)
// testen (siehe 3)
// Excel Formatierung anpassen
// mehr / andere gas optimisation oder wieder raus???
// use cases strings nicht default in contract, erst nach deploy adden 


// 3)
// alles testen (notiere varianten)
    // alle funktionen
    // weniger als 3 votes
    // versch punkteverteilung
    // einer votet garnicht
    // events
// eth minen

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}