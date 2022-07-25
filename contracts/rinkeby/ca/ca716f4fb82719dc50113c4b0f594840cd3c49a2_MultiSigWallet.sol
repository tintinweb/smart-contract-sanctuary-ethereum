// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

import "./Strings.sol";

import "./console.sol";

interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract MultiSigWallet {
    
    enum OwnerStatus{ NONE, OWNER, WAITING }
    enum WhiteListStatus{ NONE ,WAITING ,MEMBER }

    address factoryAddress;
    address[] public owners;
    address[] whiteList;
    mapping(address=>OwnerStatus) isOwner;
    mapping(address=>WhiteListStatus) inWhiteList;
    mapping (bytes32 => address) private recOwner;
    address[] pendingNewOwners;
    address[] pendingRemoveOwners;
    mapping(address=>VoteCounter) pendingOwnerVotes;
    address[] pendingWhiteListMember;
    address[] pendingRemoveWhiteListMember;
    mapping(address=>VoteCounter) pendingWhiteListVotes;

    mapping(uint=>Transaction) transactions;
    uint numTransactions;

    uint reservedBalance;
    
    mapping (string => PendingToken) pendingTokens;
    string[] pendingTokenNames;
    mapping (string => address) tokenAddresses;
    string[] tokenNames;

    mapping (string => uint) reservedBalances;
    
    struct PendingToken {
        address tokenAddress;
        VoteCounter2 voters;
        bool executed;
    }

    struct Transaction{
        string tokenName;
        address tokenAddress;
        address requestedBy;
        address destination;
        uint value;
        bool executed;
        VoteCounter votes;
    }

    struct VoteCounter {
        uint confirmCount;
        uint rejectCount;
        mapping(address=>bool) voters;
    }

    struct VoteCounter2 {
        uint confirmCount;
        uint rejectCount;
        mapping(address=>bool) voters;
        address[] votersIndex;
    }

    // EVENTS
    
    // Owner
    event OwnerAddRequest(address owner);
    event OwnerRemoveRequest(address owner);
    event NewOwnerVote(address owner, bool vote);
    event RemoveOwnerVote(address owner, bool vote);
    event OwnerAdd(address owner);
    event OwnerRemove(address owner);

    // Transaction
    event TransactionRequest(address owner);
    event TransactionVote(address owner, bool vote);
    event TransactionExecution(uint transactionId);
    event TransactionRejection(uint transactionId);
    event TransactionCancel(uint transactionId);

    //White List
    event WhiteListAddRequest(address adr);
    event WhiteListRemoveRequest(address adr);
    event WhiteListVote(address adr, bool vote);
    event RemoveFromWhiteListVote(address adr, bool vote);
    event WhiteListAdded(address adr);
    event WhiteListReject(address adr);
    event WhiteListRemoved(address adr);
    event WhiteListRemoveReject(address adr);

    //New Tokens
    event NewTokenRequest(string name, address contractAddress);
    event NewTokenVote(string name, address contractAddress, address voter);
    event NewTokenAddition(string name, address contractAddress);
    event NewTokenRejection(string name, address contractAddress);

    // MODIFIERS
    modifier ownerExists(address owner) {
        require(isOwner[owner]==OwnerStatus.OWNER, "User is not owner");
        _;
    }
    
    modifier ownerDoesNotExist(address owner) {
        require(isOwner[owner]!=OwnerStatus.OWNER, "Owner already exists");
        _;
    }
    
    modifier onlyFactory() {
        require(msg.sender == factoryAddress);
        _;
    }

    // CONSTRUCTOR
    constructor(address[] memory _owners, string[] memory _seedPhrases, address _factoryAddress) {
        require(_seedPhrases.length == _owners.length);
        for (uint i=0; i<_owners.length; i++) {
            require(_owners[i] != address(0));
            isOwner[_owners[i]] = OwnerStatus.OWNER;
            recOwner[sha256(abi.encodePacked(_seedPhrases[i]))] = _owners[i];
        }
        reservedBalances["eth"] = 0;
        owners = _owners;
        factoryAddress = _factoryAddress;
    }

    // TRANSACTION FUNCTIONS
    function requestTransaction(address destination, uint value)
        public
        ownerExists(msg.sender)
    {
        require(value <= address(this).balance - reservedBalances["eth"], "Insufficient funds");
        Transaction storage t = transactions[numTransactions];
        numTransactions++;
        t.tokenName = "eth";
        t.tokenAddress = address(this);
        t.destination = destination;
        t.value = value;
        t.requestedBy = msg.sender;
        reservedBalances["eth"] += value;
        emit TransactionRequest(msg.sender);
        voteTransaction(numTransactions-1, true);
    }

    function requestTransaction(address destination, uint value, string memory token)
        public
        ownerExists(msg.sender)
    {
        require(isInTokenAddresses(token), "Token is not available in this wallet");
        reservedBalances[token] = IERC20(tokenAddresses[token]).balanceOf(address(this));
        require(value <= tokenAddresses[token].balance - reservedBalances[token], "Insufficient funds");
        Transaction storage t = transactions[numTransactions];
        numTransactions++;
        t.tokenName = token;
        t.tokenAddress = tokenAddresses[token];
        t.destination = destination;
        t.value = value;
        t.requestedBy = msg.sender;
        reservedBalances[token] += value;
        emit TransactionRequest(msg.sender);
        voteTransaction(numTransactions-1, true);
    }

    function voteTransaction(uint transactionId, bool vote)
        public 
        ownerExists(msg.sender)
    {
        require(transactionId < numTransactions, "Transaction does not exist");
        require(!transactions[transactionId].votes.voters[msg.sender]);
        if(vote) {
            transactions[transactionId].votes.confirmCount++;
        } else {
            transactions[transactionId].votes.rejectCount++;
        }
        transactions[transactionId].votes.voters[msg.sender] = true;
        emit TransactionVote(msg.sender, vote);
        if (equalString(transactions[transactionId].tokenName, "eth"))
            executeTransaction(transactionId);
        else
            executeTransaction(transactionId, transactions[transactionId].tokenName);
    }

    function executeTransaction(uint transactionId)
        internal
        ownerExists(msg.sender)
    {
        require(transactionId < numTransactions, "There is no such transaction");
        require(!transactions[transactionId].executed, "Transaction is already executed or rejected");
        if(transactions[transactionId].votes.confirmCount >= owners.length/2+1) {
            payable(transactions[transactionId].destination).transfer(transactions[transactionId].value);
            transactions[transactionId].executed = true;
            reservedBalances["eth"] -= transactions[transactionId].value;
            emit TransactionExecution(transactionId);
        } else if(transactions[transactionId].votes.rejectCount >= owners.length/2+1) {
            transactions[transactionId].executed = true;
            reservedBalances["eth"] -= transactions[transactionId].value;
            emit TransactionRejection(transactionId);
        }
    }

    function executeTransaction(uint transactionId, string memory tokenName)
        internal
        ownerExists(msg.sender)
    {
        require(transactionId < numTransactions, "There is no such transaction");
        require(!transactions[transactionId].executed, "Transaction is already executed or rejected");
        if(transactions[transactionId].votes.confirmCount >= owners.length/2+1) {
            IERC20(transactions[transactionId].tokenAddress).approve(address(this),transactions[transactionId].value);
            IERC20(transactions[transactionId].tokenAddress).transferFrom(address(this), transactions[transactionId].destination, transactions[transactionId].value);
            transactions[transactionId].executed = true;
            reservedBalances[tokenName] -= transactions[transactionId].value;
            emit TransactionExecution(transactionId);
        } else if(transactions[transactionId].votes.rejectCount >= owners.length/2+1) {
            transactions[transactionId].executed = true;
            reservedBalances[tokenName] -= transactions[transactionId].value;
            emit TransactionRejection(transactionId);
        }
    }

    //HELPER

    function removeFromList(address[] storage addresses, address addr)
        internal
    {
        if(addresses.length > 1) {
            uint idx = 0;
            while(addresses[idx]!=addr) idx++;
            addresses[idx] = addresses[owners.length-1];
        }
        addresses.pop();
    }

    function isInVoterIndex(PendingToken storage pToken, address isIn) internal view returns(bool) {
        for(uint i = 0; i < pToken.voters.votersIndex.length; i++)
        {
            if(pToken.voters.votersIndex[i] == isIn)
            {
                return true;
            }
        }
        return false;
    }

    function isInNewTokenNames(string memory tokenName) internal view returns(bool) {
        for (uint i = 0; i < pendingTokenNames.length; i++){
            if(equalString(pendingTokenNames[i], tokenName))
                return true;
        }
        return false;
    }

    function equalString(string memory a, string memory b) internal pure returns (bool) {
        if(bytes(a).length != bytes(b).length) {
            return false;
        } else {
            return keccak256(abi.encode(a)) == keccak256(abi.encode(b));
        }
    }

    function isInTokenAddresses(string memory token) private view returns(bool) {
        for(uint i = 0; i < tokenNames.length; i++) {
            if (equalString(tokenNames[i], token))
                return true;
        }
        return false;
    }

    function cancelTransaction(uint transactionId)
        public
        ownerExists(msg.sender)
    {
        require(transactions[transactionId].requestedBy==msg.sender);
        require(!transactions[transactionId].executed, "Transaction is already executed or rejected");

        transactions[transactionId].executed = true;
        reservedBalances[transactions[transactionId].tokenName] -= transactions[transactionId].value;
        emit TransactionCancel(transactionId);
    }

    function getTransactionCount()
        public
        view
        returns(uint)
    {
        return numTransactions;
    }

    function getTransactionDetails(uint transactionId)
        public
        view
        returns(string memory, address, bool, uint, uint, uint, uint)
    {
        Transaction storage t = transactions[transactionId];
        return(t.tokenName, t.destination, t.executed, t.value, t.votes.confirmCount, t.votes.rejectCount, owners.length);
    }

    // RECOVERY

    function recover(string memory seedPhrase, address msgSender)
        onlyFactory()
        public
    {
        bool x = false;
        for (uint i = 0; i < owners.length; i++) {
            if (recOwner[sha256(abi.encodePacked(seedPhrase))] == owners[i]){
                x = true;
                break;
            }
        }
        if (x) {
            replaceOwner(recOwner[sha256(abi.encodePacked(seedPhrase))], msgSender);
        }
    }

    // OWNER FUNCTIONS

    function requestNewOwner(address addr)
        public
        ownerExists(msg.sender)
    {
        require(isOwner[addr] == OwnerStatus.NONE, "Owner already exists.");
        VoteCounter storage tmp = pendingOwnerVotes[addr];
        pendingNewOwners.push(addr);
        isOwner[addr] = OwnerStatus.WAITING;
        emit OwnerAddRequest(addr);
        voteNewOwner(addr, true);
    }

    function voteNewOwner(address addr, bool vote)
        public
        ownerExists(msg.sender)
    {
        require(isOwner[addr]==OwnerStatus.WAITING, "There isn't a voting for this user");
        require(!pendingOwnerVotes[addr].voters[msg.sender], "You have already voted");
        if(vote) {
            pendingOwnerVotes[addr].confirmCount++;
        } else {
            pendingOwnerVotes[addr].rejectCount++;
        }
        pendingOwnerVotes[addr].voters[msg.sender] = true;
        emit NewOwnerVote(addr, vote);
        checkNewOwner(addr);
    }

    function requestRemoveOwner(address addr)
        public
        ownerExists(msg.sender)
        ownerExists(addr)
    {
        VoteCounter storage tmp = pendingOwnerVotes[addr];
        pendingRemoveOwners.push(addr);
        for (uint i = 0; i < owners.length; i++){
            tmp.voters[owners[i]] = false;
        }
        emit OwnerRemoveRequest(addr);
        voteRemoveOwner(addr, true);
    }

    function voteRemoveOwner(address addr, bool vote)
        public
        ownerExists(msg.sender)
        ownerExists(addr)
    {
        require(!pendingOwnerVotes[addr].voters[msg.sender],"User already voted!");
        if(vote) {
            pendingOwnerVotes[addr].confirmCount++;
        }else {
            pendingOwnerVotes[addr].rejectCount++;
        }
        pendingOwnerVotes[addr].voters[msg.sender] = true;
        emit RemoveOwnerVote(addr, vote);
        checkRemoveOwner(addr);
    }

    function checkNewOwner(address addr) 
        internal
        ownerDoesNotExist(addr)
    {
        if(pendingOwnerVotes[addr].confirmCount >= owners.length/2+1) {
            owners.push(addr);
            isOwner[addr] = OwnerStatus.OWNER;
            delete pendingOwnerVotes[addr];
            removeFromList(pendingNewOwners, addr);
            emit OwnerAdd(addr);
        }
        else if(pendingOwnerVotes[addr].rejectCount >= owners.length/2+1) {
            isOwner[addr] = OwnerStatus.NONE;
            delete pendingOwnerVotes[addr];
            removeFromList(pendingNewOwners, addr);
            emit OwnerRemove(addr);
        }
    }

    function checkRemoveOwner(address addr) 
        internal
        ownerExists(addr)
    {
        require(owners.length != 1, "One owner left, can't remove");
        if(pendingOwnerVotes[addr].confirmCount >= owners.length/2+1) {
            isOwner[addr] = OwnerStatus.NONE;
            delete pendingOwnerVotes[addr];
            removeFromList(owners, addr);
            removeFromList(pendingRemoveOwners, addr);
            emit OwnerRemove(addr);
        }
        else if(pendingOwnerVotes[addr].rejectCount >= owners.length/2+1) {
            delete pendingOwnerVotes[addr];
            removeFromList(pendingRemoveOwners, addr);
            emit OwnerRemove(addr);
        }
    }

    function replaceOwner(address owner, address newOwner)
        private
        ownerExists(owner)
        ownerDoesNotExist(newOwner)
    {
        for (uint i=0; i<owners.length; i++)
            if (owners[i] == owner) {
                owners[i] = newOwner;
                break;
            }
        isOwner[owner] = OwnerStatus.NONE;
        isOwner[newOwner] = OwnerStatus.OWNER;
        emit OwnerRemove(owner);
    }

    //Add New Token

    function requestAddToken(string memory tokenName, address tokenAddress) 
        public
        ownerExists(msg.sender) 
    {
        require(!isInTokenAddresses(tokenName));
        PendingToken storage tmp = pendingTokens[tokenName];
        tmp.tokenAddress = tokenAddress;
        tmp.voters.confirmCount = 0;
        tmp.voters.rejectCount = 0;
        tmp.executed = false;
        pendingTokenNames.push(tokenName);
        emit NewTokenRequest(tokenName, tokenAddress);
        voteNewToken(tokenName, true);
    }

    function voteNewToken(string memory tokenName, bool vote)
        public
        ownerExists(msg.sender) 
    {
        require(isInNewTokenNames(tokenName));
        require(!pendingTokens[tokenName].executed);
        require(!pendingTokens[tokenName].voters.voters[msg.sender]);
        if (vote) {
            pendingTokens[tokenName].voters.votersIndex.push(msg.sender);
            pendingTokens[tokenName].voters.voters[msg.sender] = true;
            pendingTokens[tokenName].voters.confirmCount += 1;
        }
        else {
            pendingTokens[tokenName].voters.votersIndex.push(msg.sender);
            pendingTokens[tokenName].voters.voters[msg.sender] = true;
            pendingTokens[tokenName].voters.rejectCount += 1;
        }
        pendingTokens[tokenName].voters.voters[msg.sender] = true;
        emit NewTokenVote(tokenName, pendingTokens[tokenName].tokenAddress, msg.sender);
        addNewToken(tokenName);
    }

    function addNewToken(string memory tokenName) internal {
        if (pendingTokens[tokenName].voters.confirmCount >= owners.length/2+1) {
            emit NewTokenAddition(tokenName, pendingTokens[tokenName].tokenAddress);
            pendingTokens[tokenName].executed = true;
            tokenAddresses[tokenName] = pendingTokens[tokenName].tokenAddress;
            tokenNames.push(tokenName);
        }
        else if (pendingTokens[tokenName].voters.rejectCount >= owners.length/2+1) {
            pendingTokens[tokenName].executed = false;
        }
    }

    //WHITE LIST

    function requestAddWhiteList(address addr) 
        public
        ownerExists(msg.sender)
    {
        require(inWhiteList[addr] == WhiteListStatus.NONE, "User already in the white list.");
        VoteCounter storage tmp = pendingWhiteListVotes[addr];
        pendingWhiteListMember.push(addr);
        inWhiteList[addr] = WhiteListStatus.WAITING;
        for (uint i = 0; i < owners.length; i++){
            tmp.voters[owners[i]] = false;
        }
        emit WhiteListAddRequest(addr);
        voteAddWhiteList(addr, true);
    }

    function requestRemoveWhiteList(address addr)
        public
        ownerExists(msg.sender)
    {
        require(inWhiteList[addr] == WhiteListStatus.MEMBER, "User is not in the white list.");
        VoteCounter storage tmp = pendingWhiteListVotes[addr];
        pendingRemoveWhiteListMember.push(addr);
        inWhiteList[addr] = WhiteListStatus.WAITING;
        for (uint i = 0; i < owners.length; i++){
            tmp.voters[owners[i]] = false;
        }
        emit WhiteListRemoveRequest(addr);
        voteRemoveFromWhiteList(addr,true);
    }

    function voteAddWhiteList(address addr, bool vote) 
        public
        ownerExists(msg.sender)
    {
        require(inWhiteList[addr]==WhiteListStatus.WAITING, "There isn't a voting for this user");
        require(!pendingWhiteListVotes[addr].voters[msg.sender],"You have already voted!"); 
        if(vote){
            pendingWhiteListVotes[addr].confirmCount++;
        } else{
            pendingWhiteListVotes[addr].rejectCount++;
        }
        pendingWhiteListVotes[addr].voters[msg.sender] = true;
        emit WhiteListVote(addr, vote);
        checkAddWhiteList(addr);
    }

    function voteRemoveFromWhiteList(address addr, bool vote)
        public
        ownerExists(msg.sender)
    {
        require(!pendingWhiteListVotes[addr].voters[msg.sender],"You have already voted!");
        if(vote){
            pendingWhiteListVotes[addr].confirmCount++;
        }else{
            pendingWhiteListVotes[addr].rejectCount++;
        }
        pendingWhiteListVotes[addr].voters[msg.sender] = true;
        emit RemoveFromWhiteListVote(addr,vote);
        checkRemoveFromWhiteList(addr);
    }

    function checkAddWhiteList(address addr) 
        internal
    {
        if(pendingWhiteListVotes[addr].confirmCount >= owners.length/2+1){
            whiteList.push(addr);
            inWhiteList[addr] = WhiteListStatus.MEMBER;
            delete pendingWhiteListVotes[addr];
            removeFromList(pendingWhiteListMember, addr);
            emit WhiteListAdded(addr);
        }
        else if(pendingWhiteListVotes[addr].rejectCount >= owners.length/2+1){
            inWhiteList[addr] = WhiteListStatus.NONE;
            delete pendingWhiteListVotes[addr];
            removeFromList(pendingWhiteListMember, addr);
            emit WhiteListReject(addr);
        }

    }

    function checkRemoveFromWhiteList(address addr)
        internal
    {
        if(pendingWhiteListVotes[addr].confirmCount >= owners.length/2+1){
            inWhiteList[addr] = WhiteListStatus.NONE;
            delete pendingWhiteListVotes[addr];
            removeFromList(whiteList,addr);
            removeFromList(pendingRemoveWhiteListMember,addr);
            emit WhiteListRemoved(addr);
        }
        else if(pendingWhiteListVotes[addr].rejectCount >= owners.length/2+1){

            delete pendingWhiteListVotes[addr];
            removeFromList(pendingRemoveWhiteListMember,addr);
            emit WhiteListRemoveReject(addr);
        }
    }
	
    // Revoke New Token



    // View Functions

    function getOwners() public view returns(address[] memory) {
        return owners;
    }
    function getPendingNewOwners() public view returns(address[] memory) {
        return pendingNewOwners;
    }
    function getPendingRemoveOwners() public view returns(address[] memory) {
        return pendingRemoveOwners;
    }
    function getPendingOwnerDetails(address addr) public view returns(uint, uint, uint) {
        return (owners.length, pendingOwnerVotes[addr].confirmCount, pendingOwnerVotes[addr].rejectCount);
    }
    function getWhiteList() public view returns(address[] memory) {
        return whiteList;
    }
    function getPendingWhiteList() public view returns(address[] memory) {
        return pendingWhiteListMember;
    }
    function getPendingRemoveWhiteList() public view returns(address[] memory) {
        return pendingRemoveWhiteListMember;
    }
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }
    function getExistingTokens () public view returns (string memory) {
        string memory retAddresses;
        for (uint i = 0; i < tokenNames.length; i++) {
            uint balance = IERC20(tokenAddresses[tokenNames[i]]).balanceOf(address(this));
            retAddresses = string.concat(tokenNames[i], " => ");
            retAddresses = string.concat(retAddresses, Strings.toHexString(uint256(uint160(tokenAddresses[tokenNames[i]])), 20));
            retAddresses = string.concat(retAddresses, ": Balance => ");
            retAddresses = string.concat(retAddresses, Strings.toString(balance));
            retAddresses = string.concat(retAddresses, ", ");
        }
        return retAddresses;
    }

    receive() external payable {}
}