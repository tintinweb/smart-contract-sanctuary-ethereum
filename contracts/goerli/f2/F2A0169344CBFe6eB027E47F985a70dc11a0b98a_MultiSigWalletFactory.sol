/**
 *Submitted for verification at Etherscan.io on 2022-07-21
*/

// File: contracts/Factory.sol



pragma solidity ^0.8.15;

contract Factory {
    event ContractInstantiation(address sender, address instantiation);

    mapping(address => bool) public isInstantiation;
    mapping(address => address[]) public instantiations;

    function getInstantiationCount(address creator)
        public view
        returns (uint)
    {
        return instantiations[creator].length;
    }
    
    function register(address instantiation)
        internal
    {
        isInstantiation[instantiation] = true;
        instantiations[msg.sender].push(instantiation);
        emit ContractInstantiation(msg.sender, instantiation);
    }
}
// File: contracts/MultiSigWallet.sol



pragma solidity ^0.8.15;

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

    struct Transaction{
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

    // EVENTS
    
    // Owner
    event OwnerAddRequest(address owner);
    event OwnerRemoveRequest(address owner);
    event NewOwnerVote(address owner, bool vote);
    event RemoveOwnerVote(address owner, bool vote);
    event NewOwnerResult(address owner, bool result);
    event OwnerRemove(address owner);

    // Transaction
    event TransactionRequest(address owner);
    event TransactionVote(address owner, bool vote);
    event TransactionExecution(uint transactionId);
    event TransactionRejection(uint transactionId);


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
        owners = _owners;
        factoryAddress = _factoryAddress;
    }

    

    // TRANSACTION FUNCTIONS
    function requestTransaction(address destination, uint value)
        public
        ownerExists(msg.sender)
    {
        Transaction storage t = transactions[numTransactions++];
        t.destination = destination;
        t.value = value;
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
        executeTransaction(transactionId);
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
            emit TransactionExecution(transactionId);
        } else if(transactions[transactionId].votes.rejectCount >= owners.length/2+1) {
            transactions[transactionId].executed = true;
            emit TransactionRejection(transactionId);
        }
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
        returns(address, bool, uint, uint, uint, uint)
    {
        Transaction storage t = transactions[transactionId];
        return(t.destination, t.executed, t.value, t.votes.confirmCount, t.votes.rejectCount, owners.length);
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

    function newOwnerRequest(address addr)
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

    function removeOwnerRequest(address addr)
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
            emit NewOwnerResult(addr, true);
        }
        else if(pendingOwnerVotes[addr].votes.rejectCount >= owners.length/2+1) {
            isOwner[addr] = OwnerStatus.NONE;
            delete pendingOwnerVotes[addr];
            removeFromList(pendingNewOwners, addr);
            emit NewOwnerResult(addr, false);
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
// File: contracts/MultiSigWalletFactory.sol



pragma solidity ^0.8.15;



contract MultiSigWalletFactory is Factory {
    MultiSigWallet[] wallets;
    function create(address[] memory _owners, string[] memory seedPhrases)
        public
        returns (MultiSigWallet wallet)
    {
        wallet = new MultiSigWallet(_owners, seedPhrases, address(this));
        wallets.push(wallet);
        register(address(wallet));
    }

    function recover(string memory secret) public {
        for (uint256 i = 0; i < wallets.length; i++) {
            wallets[i].recover(secret, msg.sender);
        }
    }
}