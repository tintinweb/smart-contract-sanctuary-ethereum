/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.15;

interface IERC20 {
    function transfer(address _to, uint256 _value) external returns (bool);
}

contract MultiSigWallet {
    
    enum OwnerStatus{ NONE, OWNER, WAITING }
    address factoryAddress;
    address[] public owners;
    mapping(address=>OwnerStatus) isOwner;
    mapping (bytes32 => address) private recOwner;

    address[] pendingNewOwners;
    address[] pendingRemoveOwners;
    mapping(address=>WaitingOwner) pendingOwnerVotes;

    mapping(uint=>Transaction) transactions;
    uint numTransactions;

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

    struct WaitingOwner{
        bool addOrRemove;
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
        Transaction storage t = transactions[numTransactions++];
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
        require(value <= tokenAddresses[token].balance - reservedBalances[token], "Insufficient funds");
        Transaction storage t = transactions[numTransactions++];
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
            IERC20 xToken = IERC20(transactions[transactionId].tokenAddress);
            xToken.transfer(transactions[transactionId].destination, transactions[transactionId].value);
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

    function isInVoterIndex(PendingToken storage pToken, address isIn) internal returns(bool) {
        for(uint i = 0; i < pToken.voters.votersIndex.length; i++)
        {
            if(pToken.voters.votersIndex[i] == isIn)
            {
                return true;
            }
        }
        return false;
    }
    
    function isInNewTokenNames(string memory tokenName) internal returns(bool) {
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

    function isInTokenAddresses(string memory token) private returns(bool) {
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
        require(isOwner[addr] == OwnerStatus.NONE);
        pendingNewOwners.push(addr);
        isOwner[addr] = OwnerStatus.WAITING;
        pendingOwnerVotes[addr].addOrRemove = true;
        emit OwnerAddRequest(addr);
        voteNewOwner(addr, true);
    }

    function voteNewOwner(address addr, bool vote)
        public
        ownerExists(msg.sender)
    {
        require(isOwner[addr]==OwnerStatus.WAITING, "There isn't a voting for this user");
        require(!pendingOwnerVotes[addr].votes.voters[msg.sender], "You have already voted");
        if(vote) {
            pendingOwnerVotes[addr].votes.confirmCount++;
        } else {
            pendingOwnerVotes[addr].votes.rejectCount++;
        }
        pendingOwnerVotes[addr].votes.voters[msg.sender] = true;
        emit NewOwnerVote(addr, vote);
        checkNewOwner(addr);
    }

    function requestRemoveOwner(address addr)
        public
        ownerExists(msg.sender)
        ownerExists(addr)
    {
        pendingRemoveOwners.push(addr);
        pendingOwnerVotes[addr].addOrRemove = false;
        emit OwnerRemoveRequest(addr);
        voteRemoveOwner(addr, true);
    }

    function voteRemoveOwner(address addr, bool vote)
        public
        ownerExists(msg.sender)
        ownerExists(addr)
    {
        require(!pendingOwnerVotes[addr].votes.voters[msg.sender]);
        if(vote) {
            pendingOwnerVotes[addr].votes.confirmCount++;
        }else {
            pendingOwnerVotes[addr].votes.rejectCount++;
        }
        pendingOwnerVotes[addr].votes.voters[msg.sender] = true;
        emit RemoveOwnerVote(addr, vote);
        checkRemoveOwner(addr);
    }

    function checkNewOwner(address addr) 
        internal
        ownerDoesNotExist(addr)
    {
        if(pendingOwnerVotes[addr].votes.confirmCount >= owners.length/2+1) {
            owners.push(addr);
            isOwner[addr] = OwnerStatus.OWNER;
            delete pendingOwnerVotes[addr];
            removeFromList(pendingNewOwners, addr);
            emit OwnerAdd(addr);
        }
        else if(pendingOwnerVotes[addr].votes.rejectCount >= owners.length/2+1) {
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
        if(pendingOwnerVotes[addr].votes.confirmCount >= owners.length/2+1) {
            isOwner[addr] = OwnerStatus.NONE;
            delete pendingOwnerVotes[addr];
            removeFromList(owners, addr);
            removeFromList(pendingRemoveOwners, addr);
            emit OwnerRemove(addr);
        }
        else if(pendingOwnerVotes[addr].votes.rejectCount >= owners.length/2+1) {
            delete pendingOwnerVotes[addr];
            removeFromList(pendingRemoveOwners, addr);
            emit OwnerRemove(addr);
        }
    }

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
        require(!isInVoterIndex(pendingTokens[tokenName], msg.sender));
        if (vote) {
            pendingTokens[tokenName].voters.votersIndex.push(msg.sender);
            pendingTokens[tokenName].voters.confirmCount += 1;
        }
        else {
            pendingTokens[tokenName].voters.votersIndex.push(msg.sender);
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
        return (owners.length, pendingOwnerVotes[addr].votes.confirmCount, pendingOwnerVotes[addr].votes.rejectCount);
    }
    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    receive() external payable{}
}