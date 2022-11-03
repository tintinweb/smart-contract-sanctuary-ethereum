// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";

contract Abstimmung {

    string[] public useCases = ["0", "1.4", "1.5", "1.6", "1.7", "1.8", "1.9", "1.10", "1.11", "1.12", "1.13", 
                                "1.14", "1.15", "2", "2.1", "2.1.1", "2.1.2", "2.1.3", "2.1.4", "2.1.5", 
                                "2.1.6", "2.1.7", "2.1.8", "2.1.9", "2.1.10", "2.2", "2.2.1", "2.2.2", 
                                "2.2.3", "2.3", "2.3.1", "2.3.2", "2.3.3", "2.4", "2.5", "3", "3.1", 
                                "3.1.1", "3.1.2", "3.2.3", "3.1.4", "3.2", "3.2.1", "3.2.2", "3.2.3", 
                                "3.2.4", "3.2.5", "3.2.6", "3.2.7", "3.2.8", "3.2.9", "3.2.10", "3.2.11", 
                                "3.2.12", "3.2.13", "3.2.14", "3.2.15", "3.1.16", "3.3", "3.3.1", "3.3.2", 
                                "3.3.3", "3.3.4", "3.3.5", "3.4", "3.4.1", "3.4.2", "3.4.3", "4", "4.1", 
                                "4.1.1", "4.1.2", "4.1.3", "4.1.4", "4.1.5", "4.1.6", "4.1.6", "4.1.7", 
                                "4.1.8", "4.1.9", "4.1.10", "4.1.11", "4.1.12", "4.1.13", "4.1.14", "4.1.15", 
                                "4.2", "4.2.1", "4.2.2", "4.2.3", "4.2.4", "4.2.5", "4.2.6", "4.2.7", "4.3", 
                                "5", "5.1.1", "5.1.2", "5.1.3", "5.1.4", "5.2", "5.2.1", "5.2.2", "5.3", 
                                "5.3.1", "5.3.2", "5.3.3", "5.4", "5.4.1", "5.4.2", "6", "6.1", "6.2", "6.2.1", 
                                "6.2.2", "7", "7.1", "7.2", "7.3", "7.4", "7.5", "7.6", "7.7", "7.8"];

    address public owner;
    bool public voteActive;
    uint256 public totalVotes;

    struct votesStruct {
        address user;
        string[] votesArray;
    }

    mapping(address => votesStruct) private votes;
    mapping(address => uint256) private voteCount; // im prinzip redundant weil über votes rray und length countbar
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

    function _deposit() public payable {}

    function _getBalance() public view returns(uint256) {
        return address(this).balance;
    }

    function _onlyOwner() internal view returns(bool){
        require(msg.sender == owner, "You are not the owner");
        return true;
    }

    function _onlyUser() internal view returns(bool){
        require(voteCount[msg.sender] > 0, "You are not allowed");
        return true;
    }

    function _addUser(address _user) public onlyOwner {
        require(voteActive == false, "Voting is still active");
        voteCount[_user] = 1;
        users.push(_user);
    }

    function _countUser() public view onlyUser returns(uint256) {
        return users.length;
    }

    function _addUseCase(string memory _usecase) public onlyOwner {
        useCases.push(_usecase);
    }

    function isInUseCases(string memory _useCase) internal view returns (uint256){
        require(keccak256(abi.encodePacked(_useCase)) != keccak256(abi.encodePacked("0")), "This use case does not exist");
        for(uint256 i = 0; i < useCases.length; i++){
            if(keccak256(abi.encodePacked(useCases[i])) == keccak256(abi.encodePacked(_useCase))){
                return i;
            }
        } return 0;  
    }

    function _deleteUseCase(string memory _useCase) public onlyOwner {
        require(isInUseCases(_useCase) > 0, "This use Case does not exist");
                delete useCases[isInUseCases(_useCase)];
    }

    function distributeETH() public onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 1000000000000000, "Please get more ETH");
        uint256 userCount = users.length;
        uint256 distributionAmount = contractBalance / 5 / userCount;
        for(uint256 i = 0; i < userCount; i++){
            address payable payableUser = payable(users[i]);
            payableUser.transfer(distributionAmount);
        }
    }

    function voting(string memory _vote) public onlyUser {
        require(totalVotes < _countUser() *3, "Voting is finished");
        require(voteActive == true, "Voting is not active");
        require(isInUseCases(_vote) > 0, "This use Case does not exist");
        require(voteCount[msg.sender] <= 3, "You have already voted 3 times");
        if(voteCount[msg.sender] != 0) {
            for(uint256 i = 0; i < votes[msg.sender].votesArray.length; i++){
                if(keccak256(abi.encodePacked(votes[msg.sender].votesArray[i])) == keccak256(abi.encodePacked(_vote))){
                    revert("You have already voted for this use case");
                }
            }
        }
        votes[msg.sender].user = msg.sender;
        votes[msg.sender].votesArray.push(_vote);

        // add points for vote to use case
        if(voteCount[msg.sender] == 1){
            pointsPerUseCase[_vote] += 3;
        } else if(voteCount[msg.sender] == 2) {
            pointsPerUseCase[_vote] += 2;
        } else if(voteCount[msg.sender] == 3) {
            pointsPerUseCase[_vote] += 1;
        }

        // add use case to voted uses cases
        bool inVotedUseCases = false;
        for(uint256 j = 0; j < votedUseCases.length; j++){
            if(keccak256(abi.encodePacked(votedUseCases[j])) == keccak256(abi.encodePacked(_vote))){
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
            voteActive = false;
        }
    }

    function yourVotes() public view onlyUser returns(string[] memory _yourVotes) {
        _yourVotes = new string[](votes[msg.sender].votesArray.length);
        for(uint256 i = 0; i < votes[msg.sender].votesArray.length; i++){
            bytes memory conc = abi.encodePacked("-- ", votes[msg.sender].votesArray[i], " --");
            _yourVotes[i] = string(conc);
        }
        return _yourVotes;
    }

    function _users() public view onlyUser returns(address[] memory){
        return users;
    }

    function showVotesByUser() public view onlyUser returns(string[] memory votesByUser){
        require(voteActive == false, "Voting is still active");
        votesByUser = new string[](users.length);
        for(uint256 i = 0; i < users.length; i++){
            string memory addressString = Strings.toHexString(users[i]);
            bytes memory addressBytes = bytes(addressString);
            bytes memory addressShort = new bytes(6-0);
            for(uint j = 0; j < 6; j++){
                addressShort[j-0] = addressBytes[j];
            }
            bytes memory conc = abi.encodePacked("-- ", addressShort, " = ", votes[users[i]].votesArray[0], " + ", votes[users[i]].votesArray[1], " + ", votes[users[i]].votesArray[2], " ", " --");
            votesByUser[i] = string(conc);
        }
        return votesByUser;
    }

    function _votedUsesCases() public view onlyUser returns(string[] memory votedUC){
        require(voteActive == false, "Voting is still active");  
        votedUC = new string[](votedUseCases.length);
        for(uint256 i = 0; i < votedUseCases.length; i++){
            bytes memory conc = abi.encodePacked("-- ", votedUseCases[i], " --");
            votedUC[i] = string(conc);
        }

        return votedUC;
    }

    function showRankAndPoints() public view onlyUser returns (string[] memory ranks) {
        require(voteActive == false, "Voting is still active");
        uint256 len = votedUseCases.length;
        ranks = new string[](len);
        string memory UC = "default";  
        uint256 VAL;
        bool inRanks;
        for(uint256 j = 0; j < len; j++){   
            VAL = 0;
            for(uint256 i = 0; i < len; i++){
                inRanks = false;
                for(uint256 k = 0; k < ranks.length; k++){
                    if(keccak256(abi.encodePacked(votedUseCases[i])) == keccak256(abi.encodePacked(ranks[k]))){
                        inRanks = true;
                    }
                }
                if(inRanks == false){
                    if(VAL <= pointsPerUseCase[votedUseCases[i]]){
                        VAL = pointsPerUseCase[votedUseCases[i]];
                        UC = votedUseCases[i];
                    }
                }
            }
            //bytes memory conc = abi.encodePacked("-- ", compareUC, " = ", Strings.toString(compareVal), "P --");
            ranks[j] = UC;
        } return ranks;
    }

    function voteStart() public onlyOwner {
        voteActive = true;
    }

    function voteEnd() public onlyOwner {
        // frist einräumen
        // emit results as event
        voteActive = false;
    }

    function clearVoting() public onlyOwner {
        for(uint256 i = 0; i < users.length; i++) {
            delete votes[users[i]];
            voteCount[users[i]] = 1;
        }
        totalVotes = 0;
    }

    function deleteAllUsers() public onlyOwner {

        }

    function deleteUser(address _user) public onlyOwner {
        require(voteActive == false, "Voting is still active");
        // you cannot delete a user while voting is not cleared
        require(voteCount[_user] >= 0, "User does not exist");
        delete voteCount[_user];
        delete votes[_user];

        for(uint256 i = 0; i < users.length; i++){
            if(users[i] == _user) {
                delete users[i];
                break;
            }
        }
    }
}

// ranking noch falsch auch bei 3 votes (wenn welche gleich ist noch falsch)
// showvotesbyuser revert wenn ncht alle gevotet haben
// _users shorting + seperation

// 2) any problems if someone did not vote 3 times?



// bei gleichstan muss auch für zweites votng funtionieren, also muss clear klappem
// Alle user zeigen die noch ncht drei mal gevoted haben und auflisten wie oft die gevoted habem
// ggf functon order  für testnet optimieren
// Alle Use Cases einfügen
// test ob auch geht wenn nicht alle zuende gevotet haben
// emit events für so viel wie möglich (voting results, add user, del user)
// list all use cases
// alls nochmal testen
// ropsten / kovan testnet eth minen
// auf testnet testen
// anlitung für metamask und testnet adden
// self user deletion
// self user vote deletion oder overwrite

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