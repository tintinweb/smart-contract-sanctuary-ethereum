/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

pragma solidity ^0.8.7;

/**
 @title Apella wallet
 @author dybbuk.eth
 @notice "Ἀπέλλα - ancient Spartan assembly. Its monthly meetings were presided over at first by the kings, later by ephors (magistrates) .... Only kings, elders, ephors, and perhaps other magistrates could debate, and voting was conducted by shouts. " Encyclopaedia Britannica

*/
contract ApellaWallet {
    

    uint public maxEphors;
    uint public quorum;
    uint public transactionCount;

    mapping (uint => Transaction) public transactions;
    mapping (uint => mapping (address => bool)) public confirmations;
    mapping (address => bool) public isEphor;
    address[] public ephors;

    struct Transaction {
        address payable destination;
        uint value;
        bool executed;
    }
/** 
@dev Contract constructor sets maximum number of approvers (Ephors) and quorum parameter (number of confirmations required to execute transaction).
@param _maxEphors Maximum number of Ephors
@param _quorum Number of required confirmations.
@notice the initial Ephor assigned is contract deployer address.
*/
constructor(uint _quorum, uint _maxEphors) public {                 
        quorum = _quorum;
        maxEphors = _maxEphors;
        ephors.push(msg.sender); 
        isEphor[msg.sender] = true;
    }   
/** 
@dev modifier to allow only Ephor to perform particular contract functions
*/
modifier byEphor() {
        require(isEphor[msg.sender], "Only Ephors are allowed to do this.");
        _;
    }
/**
@dev Function for ether depositing
*/
receive() external payable {

}

/** 
@dev Function to add new Ephor. Transaction to be sent by existing Ephor only.
@param _ephor - address of the new Ephor
*/
function addEphor(address _ephor) public byEphor {
        require(!isEphor[_ephor]);
        isEphor[_ephor] = true;
        ephors.push(_ephor);
    }
/** 
@dev Function to remove Ephor. Transaction to be sent by existing Ephor only.
@param _ephor - address of the Ephor
*/
function removeEphor(address _ephor) public byEphor {
        isEphor[_ephor] = false;
        for (uint i=0; i<ephors.length - 1; i++)
            if (ephors[i] == _ephor) {
                ephors[i] = ephors[ephors.length - 1];
                break;
            }
    }
/**    
@dev Allows an Ephor to submit transaction for execution. Transaction is confirmed within the function by the submitting Ephor.
@param destination Transaction 'to' address.
@param value Transaction ether value.
*/
function submitTransaction(address payable destination, uint value)
        public
        byEphor
        returns (uint transactionId)
    {
        transactionId = transactionCount;
        transactions[transactionId] = Transaction({
            destination: destination,
            value: value,
            executed: false
        });
        transactionCount ++;
        confirmTransaction(transactionId);
    }

/**
@dev Allows an Ephor to confirm a transaction.
@param transactionId Transaction ID.
 */
function confirmTransaction(uint transactionId)
        public
        byEphor
    {
        confirmations[transactionId][msg.sender] = true;
        executeTransaction(transactionId);
    }

/**
@dev Allows an Ephor to revoke a confirmation for a transaction.
@param transactionId Transaction ID.
*/
function revokeConfirmation(uint transactionId)
        public
        byEphor
    {
        confirmations[transactionId][msg.sender] = false;
    }
/**
@dev Checks whether required number of confirmations is obtained for transaction.
@param transactionId Transaction ID.
@return Confirmation status.
*/
function isConfirmed(uint transactionId)
        public
        returns (bool)
    {
        uint count = 0;
        for (uint i=0; i<ephors.length; i++) {
            if (confirmations[transactionId][ephors[i]])
                count += 1;
            if (count == quorum)
                return true;
        }
    }
/**
@dev Allows to execute a confirmed transaction. Can be performed by anyone.
@param transactionId Transaction ID.
 */
function executeTransaction(uint transactionId)
        public
    {
        require(!transactions[transactionId].executed);
        if (isConfirmed(transactionId)) {
            Transaction storage txn = transactions[transactionId];
            txn.executed = true;
            address payable to = txn.destination;
            uint amount = txn.value;
            to.transfer(amount);
        }
    }
/** 
@dev Returns number of confirmations of a transaction.
@param transactionId Transaction ID.
*/
function getConfirmationCount(uint transactionId)
        public
    //    constant
        returns (uint count)
    {
        for (uint i=0; i<ephors.length; i++)
            if (confirmations[transactionId][ephors[i]])
                count += 1;
    }

/**
@dev Returns list of Ephors.
 */
function getEphors()
        public
        returns (address[] memory)
    {
        return ephors;
    }

}