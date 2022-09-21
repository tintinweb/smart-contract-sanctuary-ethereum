// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


// import "@openzeppelin/contract/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";


contract TimeLock is Ownable{
    /**
     * @dev  the MIN_DELAY Varialbe will hold the transaction for given time period in this 24 hours
     *
     * MAX_DELAY variable will not allow to execute any transactroin after given time.
     */
    uint internal constant MIN_DELAY = 24 hours; 
    uint internal  constant MAX_DELAY = 30 days;

    struct Transaction{
        address target; 
        address caller; 
        uint value;     
        string func;    
        address parameter;  
        uint currenttime; 
        uint timestamp;   
        bytes _tx;     
    }  

    mapping(string => Transaction) public queuedTx;
    mapping(string => bool) internal isQueued;    
    string[] public allQueues; 

    /**
     * @dev Emitted when the Transaction is Queued delay .
     */

    event TransactionQueued(address indexed _Target,address indexed Msgcaller,uint Etherval,string FunctionName,uint time,bytes _TxIds);

    /**
     * @dev Emitted when the Remove admin delay .
     */

    event Removeadmin(address indexed _Target,address indexed Msgcaller,uint Etherval,string FunctionName,uint time,bytes _TxIds);

     /**
     * @dev Emitted when the Add Admin is Queued delay .
     */

    event AddAdmin(address indexed _Target,address indexed Msgcaller,uint Etherval,string FunctionName,uint time,bytes _TxIds);
     /**
     * @dev Emitted when the Execution is done for a particular id 
     */

    event Execute(bytes TXID, address indexed Target, uint Value,string FunctionName, uint Timestamp,address indexed AdminName);
     /**
     *  @dev Emitted when the Cancel is done for a particular id 
     */
    event CancelEvent(bytes TXID, address indexed Target, uint Value,string FunctionName, uint Timestamp,address indexed AdminName);
     /**
     * @dev Emitted when the TokenTransfer Ownership is Queued in transaction.
     */
    event TokenTransferOwnership(address indexed _Target,address indexed Msgcaller,uint Etherval,string FunctionName,uint time,bytes _TxIds);
    
    // Making Gnosis safe address as the Owner.
    constructor(address ownerAddress){
       
        transferOwnership(ownerAddress);
    }

     /**
     * @dev function queueTransaction Returns bytes data an id correspond to a registered operation. This
     * queueTransaction we can call function from AMR smart contract using data as a parameter 
     * we have to pass the transaction bytes data properly while passing data parameter.
     */

    function queueTransaction(address _target, uint _value, string memory _func, bytes calldata data) public onlyOwner returns (bytes memory txId) {
        string memory _id = toString(data);
        require(_target != address(0), "ERC20: _target address cannot be zero address");
        if (isQueued[_id]) {
            revert("it is already in queued");
        }
        queuedTx[_id] = Transaction({
            target:_target,
            caller:msg.sender,
            value:_value,
            func:_func,
            parameter:address(0),
            currenttime:block.timestamp,
            timestamp:block.timestamp+MIN_DELAY,
            _tx:data
            });
        isQueued[_id] = true;
        allQueues.push(_id);
        emit TransactionQueued(_target,msg.sender,_value,_func,block.timestamp,txId);
        return data;
    }

    /**
     * @dev function tokenTransferOwnership Returns bytes data an id correspond to a registered operation. This
     * tokenTransferOwnership is used to transfer ownership.
     * and this can be called by the owner.
     */
     

    function tokenTransferOwnership(
        address _target,
        address _Owneraddress
    ) external onlyOwner returns (bytes memory txId) {
        require(_target != address(0), "ERC20: _target address cannot be zero address"); 
        require(_Owneraddress != address(0), "ERC20: _Owneraddress address cannot be zero address"); 
        string memory _func = "transferOwnership(address)";    
        bytes memory txid = (abi.encodeWithSignature(_func, _Owneraddress)); 
        string memory _id = string(abi.encodePacked(_func,toString(_Owneraddress))); 

     /**
     * @dev isQueued checking condition to unique or each transaction is in queue or not  . 
     * l.
     */
        if (isQueued[_id]) {
            revert("it is already in queued");
        }
         /**
     * @dev storing all the varialbe data into the Transaction struct  . 
     *
     */
        queuedTx[_id] = Transaction({
            target:_target,
            caller:msg.sender,
            value:0,
            func:_func, 
            parameter:_Owneraddress,
            currenttime:block.timestamp,  
            timestamp:block.timestamp+MIN_DELAY, 
            _tx:txid
            });
        isQueued[_id] = true;  
        allQueues.push(_id);
        emit TokenTransferOwnership(_target,msg.sender,0,_func,block.timestamp,txId);
    }

     /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */


    function tokenRenounceOwnership(
        address _target
    ) external onlyOwner returns (bytes memory txId) {
        require(_target != address(0), "ERC20: _target address cannot be zero address");  
        string memory _func="renounceOwnership()";
        txId = (abi.encodeWithSignature(_func));
        string memory _id = string(abi.encodePacked(_func,toString(_target)));
        if (isQueued[_id]) {
            revert("it is already in queued");
        }
        queuedTx[_id] = Transaction({
            target:_target,
            caller:msg.sender,
            value:0,
            func:_func, 
            parameter:address(this),
            currenttime:block.timestamp,
            timestamp:block.timestamp+MIN_DELAY, 
            _tx:txId
            });
        isQueued[_id] = true;        
        allQueues.push(_id);
        emit TokenTransferOwnership(_target,msg.sender,0,_func,block.timestamp,txId);
        
    }


    /*
    * @dev Removes the `account` address from the Admin list.
    * @param account The account address to be removed
    * Emits an {AdminRemoved} event.
    * its removing the old Admin from the AMR smart contract 
    */
    function tokenRemoveAdmin(
        address _target,
        address _Adminaddress
    ) external onlyOwner returns (bytes memory txId) {
        require(_target != address(0), "ERC20: _target address cannot be zero address"); 
        require(_Adminaddress != address(0), "ERC20: _Adminaddress address cannot be zero address"); 
        string memory _func="removeAdmin(address)";
        txId = (abi.encodeWithSignature(_func, _Adminaddress));
        string memory _id = string(abi.encodePacked(_func,toString(_target),toString(_Adminaddress)));
        if (isQueued[_id]) {
            revert("it is already in queued");
        }
        queuedTx[_id] = Transaction({
            target:_target,
            caller:msg.sender,
            value:0,
            func:_func, 
            parameter:_Adminaddress,
            currenttime:block.timestamp,
            timestamp:block.timestamp+MIN_DELAY,
            _tx:txId
            });
        isQueued[_id] = true;
        allQueues.push(_id);
        emit Removeadmin(_target,msg.sender,0,_func,block.timestamp,txId);
    }

    
     /**
      * Adds the `account` address in the Admin list.
      * Param account The account address to be added.
      * new Admin will added to the AMR smart contract 
     */
     
    function tokenAddAdmin(
        address _target,
        address _Adminaddress
    ) external onlyOwner returns (bytes memory txId) {
        require(_target != address(0), "ERC20: _target address cannot be zero address");
        require(_Adminaddress != address(0), "ERC20: _Adminaddress address cannot be zero address"); 
        string memory _func="addAdmin(address)";
        txId = abi.encodeWithSignature(_func, _Adminaddress);
        string memory _id = string(abi.encodePacked(_func,toString(_target),toString(_Adminaddress)));
        if (isQueued[_id]) {
            revert("it is already in queued");
        }
        queuedTx[_id] = Transaction({
            target:_target,
            caller:msg.sender,
            value:0,
            func:_func, 
            parameter:_Adminaddress,
            currenttime:block.timestamp,
            timestamp:block.timestamp+MIN_DELAY,
            _tx:txId
            });
        isQueued[_id] = true;
        allQueues.push(_id);
        emit AddAdmin(_target,msg.sender,0,_func,block.timestamp,txId);
    }


     /**
     * @dev Cancel an operation.
     *
     * Requirements:
     *
     * - the caller must have the 'canceller' role.
     */

     function cancelQueuedTx(string memory _id)  public onlyOwner{
        if (!isQueued[_id]) {
            revert("Transaction is not Queued");
        }
        Transaction storage transaction = queuedTx[_id];
        allQueues[indexOf(allQueues, _id)] = allQueues[allQueues.length -1];
        allQueues.pop();
        delete isQueued[_id];
        delete queuedTx[_id];
         emit CancelEvent(transaction._tx, transaction.target, transaction.value, transaction.func, transaction.timestamp,msg.sender);
    }
     /**
     * @dev indexOf is used to get the searching index.
     *
     * Requirements:
     *
     * - its private function .
     */

    function indexOf(string[] memory arr, string memory searchFor) private pure returns (uint256) {
        if (arr.length > 0){
            for (uint256 i = 0; i < arr.length; i++) {
                if (bytes(arr[i]).length == bytes(searchFor).length) {
                    return i;
                }
            }
        }
        revert("Not Found"); // not found
    }

    /**
     * @dev Execute an (ready) operation containing a single transaction.
     *
     * Emits a {CallExecuted} event.
     *
     * Requirements:
     *
     * - the caller must be onlyOwner.
     */
    function executeQueuedTx(
        string memory _id)
        public  onlyOwner returns (bytes memory) {
        if (!isQueued[_id]) {
            revert("Transaction is not Queued");
        }
        Transaction storage transaction = queuedTx[_id];
        if (block.timestamp < transaction.timestamp) {
            revert("Time stamp is not passed ");
        }
        if (block.timestamp > transaction.timestamp + MAX_DELAY) {
            revert("Time stamp Expired");
        }
        (bool ok, bytes memory res) = transaction.target.call{value: transaction.value}(transaction._tx);
        if (!ok) {
            revert("Transaction is failed");
        }
        emit Execute(transaction._tx, transaction.target, transaction.value, transaction.func, transaction.timestamp,msg.sender);
        cancelQueuedTx(_id);
        return res;
    }

    /**
     * @dev getQueuedTxnByIndex is used get the transaction details(completly).
     * this can called by anyone.
     */
    function getQueuedTxnById(string memory _id) public view returns (string memory){
        if (!isQueued[_id]) {
            revert("Transaction is not Queued");
        }
        return string(abi.encodePacked('{"target:"', toString(queuedTx[_id].target),',"address:"',toString(queuedTx[_id].caller),',"function:"', queuedTx[_id].func,',"parameter:"',toString(queuedTx[_id].parameter),',"invokeTimestamp:"',toString(queuedTx[_id].currenttime),',"endTime:"', toString(queuedTx[_id].timestamp),"}"));
    }

    /**
     * @dev getAllQueuedTxn is used get all Pending transaction .
     * this can called by anyone.
     */

    function getAllQueuedTxn() public view returns(string memory)  {
        if(allQueues.length > 0){
            string memory allTransaction = "";
            for (uint256 i = 0; i < allQueues.length; i++){
                allTransaction = string(abi.encodePacked(allTransaction, string(abi.encodePacked('"',allQueues[i],'"',' : {"target:"', toString(queuedTx[allQueues[i]].target),',"address:"',toString(queuedTx[allQueues[i]].caller),',"function:"', queuedTx[allQueues[i]].func,',"parameter:"',toString(queuedTx[allQueues[i]].parameter),',"invokeTimestamp:"',toString(queuedTx[allQueues[i]].currenttime),',"endTime:"', toString(queuedTx[allQueues[i]].timestamp),"}"))));
            }
            return allTransaction;
        }
        return "No Transaction Found";
    }

    /**
     * @dev getCurrentTxLength function is used get number of queued transactions count .
     * this can called by anyone.
     */
    function getCurrentTxLength() public view returns(uint){
        return allQueues.length-1;
    }
    
     /**
     * @dev toString function is used convert the given address to sting format.
     * this is internal function .
     */
    function toString(address account) internal  pure returns(string memory) {
    return toString(abi.encodePacked(account));
    }
    /**
     * @dev toString function is used convert the given INTERGER to sting format.
     * this is internal function .
     */

    function toString(uint256 value) internal pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }
    /**
     * @dev toString function is used convert the given bytes to sting format.
     * this is internal function .
     */

    function toString(bytes32 value) internal pure returns(string memory) {
        return toString(abi.encodePacked(value));
    }
    /**
     * @dev toString function is used convert the given bytes to sting format.
     * this is internal function .
     */

    function toString(bytes memory data) internal pure returns(string memory) {
        bytes memory alphabet = "0123456789abcdef";
        bytes memory str = new bytes(2 + data.length * 2);
        str[0] = "0";
        str[1] = "x";
        for (uint i = 0; i < data.length; i++) {
            str[2+i*2] = alphabet[uint(uint8(data[i] >> 4))];
            str[3+i*2] = alphabet[uint(uint8(data[i] & 0x0f))];
        }
        return string(str);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../utils/Context.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}