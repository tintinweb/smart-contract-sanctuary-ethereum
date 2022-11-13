// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract Abstimmung {

    // store voting results on chain
    event votingResults(string[]);
    event voters(string[]);
    event votedPerUser(string[]);
    event ownershipTransfer(address prevOwner, address newOwner);

    string[] private useCases = ["0"];

    address private owner;
    bool private voteActive;
    bool private voteCleared = true;
    uint256 private totalVotes;

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
    // frequent require statements
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

    function _onlyOwner() internal view {
        require(msg.sender == owner, "Not allowed");
    }
    function _onlyUser() internal view {
        address[] memory _users = users;
        bool userExists = false;
        for(uint256 i = 0; i < _users.length; i++){
            if(msg.sender == _users[i]){
                userExists = true;
                break;
            }
        }
        require(userExists == true || msg.sender == owner, "Not allowed");
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

    // enable contraxt to receive funds by anyone
    function _deposit() public payable {}

    // enable users to read contract balance
    function _getBalance() public view onlyUser returns(uint256) {
        return address(this).balance;
    }

    // enable private variables to be read by users
    function _owner() public view onlyUser returns(address) {
        return owner;
    }
    function _voteActive() public view onlyUser returns(bool) {
        return voteActive;
    }
    function _voteCleared() public view onlyUser returns(bool) {
        return voteCleared;
    }
    function _totalVotes() public view onlyUser returns(uint256){
        return totalVotes;
    }

    function changeOwner(address _newOwner) public onlyOwner requireVotingInactive requireVotingCleared {
        require(_newOwner != address(0), "invalid address");
        //require(_newOwner != msg.sender, "Already owner"); // eliminated for contract ize reason
        address oldOwner = owner;
        owner = _newOwner;
        emit ownershipTransfer(oldOwner, owner);
    }

    function addUsers(address[] memory _userList) public onlyOwner requireVotingInactive requireVotingCleared {
        // count non-unique addresses in input array 
        uint256[] memory count = new uint[](_userList.length);
        for(uint256 i = 0; i < _userList.length; i++){
            for(uint256 j = i+1; j < _userList.length; j++){
                if(_userList[i] == _userList[j]){
                    count[i]++;
                }
            }
        }
        // get amount of non unique addresses
        uint256 cnt;
        for(uint256 k = 0; k < _userList.length; k++){
            if(count[k] == 1){
                cnt++;
            }
        }
        if(cnt != 0 ){
            // create string of non unique addresses
            bytes memory concInput = abi.encodePacked("Non unique input: ");
            for(uint256 l = 0; l < _userList.length; l++){
                if(count[l] == 1){
                    string memory currentAddress = Strings.toHexString(_userList[l]);
                    concInput = abi.encodePacked(concInput, "-- ", currentAddress, " --");
                }
            }
            require(cnt == 0, string(concInput));
        }else{
            // check if addresses in destination array
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
            // add strings to destination array
            for(uint256 k = 0; k < _userList.length; k++){
                users.push(_userList[k]);
                voteCount[_userList[k]] = 1;
            }
        }
    }

    function _countUsers() public view onlyUser returns(uint256) {
        return users.length;
    }

    function isInUseCases(string memory _useCase) internal view returns (uint256){
        // check if valid and existing use case
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

    function addUseCases(string[] memory _useCaseList) public onlyOwner requireVotingInactive requireVotingCleared {
        // count non-unique strings in input array 
        uint256[] memory count = new uint[](_useCaseList.length);
        for(uint256 i = 0; i < _useCaseList.length; i++){
            for(uint256 j = i+1; j < _useCaseList.length; j++){
                if(keccak256(abi.encodePacked(_useCaseList[i])) == keccak256(abi.encodePacked(_useCaseList[j]))){
                    count[i]++;
                }
            }
        }
        // get amount of non unique strings
        uint256 cnt;
        for(uint256 k = 0; k < _useCaseList.length; k++){
            if(count[k] == 1){
                cnt++;
            }
        }
        if(cnt != 0 ){
            // create string of non unique strings
            bytes memory concInput = abi.encodePacked("Non unique input: ");
            for(uint256 l = 0; l < _useCaseList.length; l++){
                if(count[l] == 1){
                    concInput = abi.encodePacked(concInput, "-- ", _useCaseList[l], " --");
                }
            }
            require(cnt == 0, string(concInput));
        }else{
            // check if one of the input strings is in destinaton array
            string[] memory USECASES = useCases;        
            uint256 lenUC = USECASES.length;
            bytes memory conc = abi.encodePacked("Already in List: ");
            uint256 cntExists;
            for(uint256 i = 0; i < _useCaseList.length; i++){
                for(uint256 j = 0; j < lenUC; j++){
                    if(keccak256(abi.encodePacked(_useCaseList[i])) == keccak256(abi.encodePacked(USECASES[j]))){
                        cntExists++;
                        conc = abi.encodePacked(conc, "-- ", _useCaseList[i]," --,");
                    }
                }
            }
            require(cntExists == 0, string(conc));
            // add strings to destination array
            for(uint256 k = 0; k < _useCaseList.length; k++){
                useCases.push(_useCaseList[k]);
            }
        }
    }

    function deleteUseCase(string memory _useCase) public onlyOwner requireVotingInactive requireVotingCleared {
        require(isInUseCases(_useCase) == 1, "No such use case");
        string[] memory USECASES = useCases;
        uint256 lenUC = USECASES.length;
        uint256 cntMember;
        // create new array, and only assign use cases not to be deleted
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
        // create "empty" array and assign to stoarge
        string[] memory newUSECASES = new string[](1);
        newUSECASES[0] = "0";
        useCases = newUSECASES;
    }

    function listUseCases() public view onlyUser returns(string[] memory newUseCases){
        newUseCases = new string[](useCases.length);
        bytes memory conc;
        string memory currentUseCase;
        // create array of seperated strings for comfortable reading
        for(uint256 i = 0; i < useCases.length; i++){
            currentUseCase = useCases[i];
            conc = abi.encodePacked("-- ", currentUseCase, " --");
            newUseCases[i] = string(conc);
        }
        return newUseCases;
    }

    function distributeETH() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 500000000000000000, "Get more ETH"); // minimum 0,5 ETH in contract
        address[] memory USERS = users;
        uint256 len = USERS.length;
        // distribute 33,33% of contract balance to users equally
        uint256 distributionAmount = contractBalance / 3 / len;
        for(uint256 i = 0; i < len; i++){
            address payable payableUser = payable(USERS[i]);
            payableUser.transfer(distributionAmount);
        }
    }

    function withdraw() public onlyOwner{
        require(address(this).balance > 0, "no funds");
        address payable payableOwner = payable(owner);
        payableOwner.transfer(address(this).balance);
    }

    function VOTING(string memory _vote) public onlyUser requireVotingActive {
        require(msg.sender.balance > 10000000000000000);
        require(isInUseCases(_vote) == 1, "No such use case");
        require(voteCount[msg.sender] <= 3, "You voted 3 times");
        // check if user has already voted this use case
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
            // check value of current vote and add to use case in mapping
            if(VOTESARRAYLENGTH == 0){
                pointsPerUseCase[_vote] += 3;
            } else if(VOTESARRAYLENGTH == 1) {
                pointsPerUseCase[_vote] += 2;
            } else if(VOTESARRAYLENGTH == 2) {
                pointsPerUseCase[_vote] += 1;
            }
        }
        // add vote to vote array of curret user
        votes[msg.sender].user = msg.sender;
        votes[msg.sender].votesArray.push(_vote);

        // check if use case has already been voted by other users
        bool inVotedUseCases = false;
        for(uint256 j = 0; j < lenVotedUC; j++){
            if(keccak256(abi.encodePacked(VOTEDUSECASES[j])) == keccak256(abi.encodePacked(_vote))){
                inVotedUseCases = true;
                break;
            }
        } 
        if(inVotedUseCases == false) {
            // add vote to array of voted use cases
            votedUseCases.push(_vote);
        }
        // increment number of votes by user
        voteCount[msg.sender]++;
        // increment votes fof all users
        totalVotes++;
        // automatically end voting if all users have voted 3 times
        if(totalVotes == users.length *3){
            voteEnd();
        }
    }

    function yourVotes() public view onlyUser requireVotingUncleared returns(string[] memory _yourVotes) {
        string[] memory VOTESARRAY = votes[msg.sender].votesArray;
        uint256 len = VOTESARRAY.length;
        bytes memory conc;
        if(len == 0){
            // message if user has not voted yet
            _yourVotes = new string[](1);
            conc = abi.encodePacked("-- ", "You have not voted yet", " --");
            _yourVotes[0] = string(conc);
        }else{
            // message if user has voted
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

    function showVotesByUser() public view onlyUser requireVotingInactive requireVotingUncleared returns(string[] memory votesByUser){      
        votesByUser = new string[](users.length);
        bytes memory conc;
        string memory _address;
        string memory currentUseCase;
        for(uint256 i = 0; i < users.length; i++){
            _address = Strings.toHexString(users[i]);
            conc = abi.encodePacked("-- ", _address, " = ");
            // prepare output if current user has not voted yet
            if(votes[users[i]].votesArray.length == 0){
                conc = abi.encodePacked(conc, "no votes");
            }else{
            // prepare output for use cases current user voted for
                for(uint256 j = 0; j < votes[users[i]].votesArray.length; j++){
                    if(j == 0){
                        currentUseCase = votes[users[i]].votesArray[j];
                        conc = abi.encodePacked(conc, currentUseCase);        
                    }else{
                        currentUseCase = votes[users[i]].votesArray[j];
                        conc = abi.encodePacked(conc, " / ", currentUseCase);
                    }

                }
            }
            // add message to output array
            conc = abi.encodePacked(conc, " --");
            votesByUser[i] = string(conc);
        }
        return votesByUser;
    }

    function incompleteVoters() public view onlyUser requireVotingUncleared returns(string[] memory countVotes){
        uint256 countIncompleteVoters;
        address[] memory USERS = users;    
        uint256 len = USERS.length;
        uint256 currentUserVotes;
        address currentUser;
        // check and count if null users or users voted 3 times to define output array length
        for(uint256 j = 0; j < len; j++){
            if(voteCount[USERS[j]] < 4 && voteCount[USERS[j]] > 0){  
                 countIncompleteVoters++;
            }
        }
        if(countIncompleteVoters == 0){
            // prepare message if every user voted 3 times
            countVotes = new string[](1);
            countVotes[0] = "Everyone has voted 3 times";
        }else{
            // prepare message of incomplete voters and votes
            countVotes = new string[](countIncompleteVoters);
            bytes memory conc;
            string memory addressString;
            bytes memory addressBytes;
            bytes memory addressShort;
            uint256 cnt;
            for(uint256 i = 0; i < len; i++){
                currentUserVotes = voteCount[USERS[i]];
                currentUser = USERS[i];
                // check and count if null users or users voted 3 times
                if(currentUserVotes < 4 && currentUserVotes > 0){
                    // reduce address to 6 chars for comfortable displaying
                    addressString = Strings.toHexString(currentUser);
                    addressBytes = bytes(addressString);
                    addressShort = new bytes(6-0);
                    for(uint j = 0; j < 6; j++){
                        addressShort[j-0] = addressBytes[j];
                    }
                    currentUserVotes--;
                    // create array with strings of key value pairs
                    conc = abi.encodePacked("-- ", string(addressShort), " = ", Strings.toString(currentUserVotes)); 
                    countVotes[cnt] = string(conc);
                    cnt++;
                }
            }  
        }
        return countVotes;
    }

    function showRankAndPoints() public view onlyUser requireVotingInactive requireVotingUncleared returns (string[] memory ranks) {  
        string[] memory VOTEDUSECASES = votedUseCases;
        uint256 len = VOTEDUSECASES.length;
        ranks = new string[](len);
        string memory UC;  
        bytes memory conc;
        uint256 VAL;
        // sort use case arrray by points per use case (descending)
        for(uint256 i = 0; i < len; i++){
            for(uint256 j = i+1; j < len; j++){               
                if(pointsPerUseCase[VOTEDUSECASES[i]] <= pointsPerUseCase[VOTEDUSECASES[j]]){
                    UC = VOTEDUSECASES[i];
                    VOTEDUSECASES[i] = VOTEDUSECASES[j];
                    VOTEDUSECASES[j] = UC;
                }
            }
        }
        // assign points to sorted use cases and create array of with string of key value pairs for output
        for(uint256 k = 0; k < len; k++){
            VAL = pointsPerUseCase[VOTEDUSECASES[k]];
            conc = abi.encodePacked("-- ", VOTEDUSECASES[k], " = ", Strings.toString(VAL), "P --");
            ranks[k] = string(conc);
        }
        return ranks;
    }

    function voteStart() public onlyOwner requireVotingInactive requireVotingCleared  {
        voteCleared = false;
        voteActive = true;
    }

    function voteEnd() internal requireVotingActive {
        // end voting and trigger storage of voting results on chain
        voteActive = false;
        emit votingResults(showRankAndPoints());
        emit voters(showUsers());
        emit votedPerUser(showVotesByUser());
    }

    function _voteEnd() public onlyOwner {
        voteEnd();
    }

    function clearVoting() public onlyOwner requireVotingInactive requireVotingUncleared {
        address[] memory USERS = users;
        uint256 len = USERS.length;
        string[] memory USECASES = useCases;
        uint256 lenUC = USECASES.length;
        // reset voting values to default
        for(uint256 i = 0; i < len; i++) {
            votes[USERS[i]].user = address(0);
            votes[USERS[i]].votesArray = new string[](0);
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
        // check if user exists in contract
        for(uint256 i = 0; i < len; i++){
            if(USERS[i] == _user){
                cntUserinUsers++;
            }
        }
        require(cntUserinUsers > 0, "No such user");
        require(voteCount[_user] >= 0, "No such user");
        // create new array, omit user to be deleted, and assign to storage array
        uint256 cntMember;
        address[] memory newUSERS = new address[](len-1);
        voteCount[_user] = 0;
        for(uint256 i = 0; i < len; i++){
            if(USERS[i] != _user) {
                newUSERS[cntMember] = USERS[i];
                cntMember++;
            }
        }
        users = newUSERS;
    }

    // enable owner to delete a user
    function deleteUser(address _user) public onlyOwner {
        _deleteUser(_user);
    }
    // enable self deletion to user
    function deleteMySelf() public onlyUser {
        _deleteUser(msg.sender);
    }

    function deleteAllUsers() public onlyOwner requireVotingInactive requireVotingCleared {
        // create new empty array, and assign to storage array
        address[] memory USERS = users;
        uint256 len = USERS.length;
        for(uint256 i = 0; i < len; i++){
            voteCount[USERS[i]] = 0;
        }
        users = new address[](0);
    }


}

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