//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import './Multisig.sol';
import "@openzeppelin/contracts/access/Ownable.sol";

contract PyjamaWallet is Ownable{
    
    mapping(address => mapping(uint256 => Multisig)) wallet;
    mapping(address => uint256) public userWalletCount; 

    function deposit(uint256 _walletId) public payable returns(uint256) {
        wallet[msg.sender][_walletId].deposit{value: msg.value}(msg.sender);
        return address(wallet[msg.sender][_walletId]).balance;
    }

    function requestTransaction(address payable _recipient, uint256 _amount, uint256 _walletId) public {
        wallet[msg.sender][_walletId].requestTransaction(_recipient, _amount, msg.sender);
    } 

    function approveTransaction(uint _txId, uint256 _walletId) public {
        wallet[msg.sender][_walletId].approveTransaction(_txId, msg.sender);
    }

    function sendTransaction(uint _txId, uint256 _walletId) public {
        wallet[msg.sender][_walletId].sendTransaction(_txId, msg.sender);
    }


    function getWalletAddress(address _user, uint256 _walletId) public view returns(address){
        return address(wallet[_user][_walletId]);
    }
    
    function getWalletBalance(address _user, uint256 _walletId) public view returns(uint256){
        return address(wallet[_user][_walletId]).balance;
    }

    function deploy(address[] memory _owners, uint256 _numOfApprovals) public returns (address payable _wallet) {
        _wallet = payable(address(new Multisig(_owners, _numOfApprovals, address(this), msg.sender)));
        for(uint256 i = 0; i<_owners.length; i++){
            wallet[_owners[i]][userWalletCount[_owners[i]]] = Multisig(_wallet);
            userWalletCount[_owners[i]]++;
        }
        wallet[msg.sender][userWalletCount[msg.sender]] = Multisig(_wallet);
        userWalletCount[msg.sender]++;
    }

    function withdraw() public onlyOwner {
        (bool sent, ) = msg.sender.call{value: address(this).balance}("");
        require(sent, "Failed to send Ether");
    }

    receive() external payable {}
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

contract Multisig {
    
    mapping(address => mapping(uint => bool)) approved;
    mapping(address => bool) owners;
    uint256 public requiredNumOfApprovals;

    constructor(address[] memory _owners, uint256 _numOfApprovals, address multisigFactory, address deployer){
        for (uint256 i = 0; i<_owners.length; i++){
            owners[_owners[i]] = true;
        } 
        owners[multisigFactory] = true;
        owners[deployer] = true;
        requiredNumOfApprovals = _numOfApprovals;
    }

    event Deposit(uint256 amount, address depositedFrom);
    event TransactionsUpdated(uint256 txId, uint256 Approvals, string action, address recipient, address msgSender, uint256 amount);
    
    modifier onlyOwners {
        require(owners[msg.sender] == true, "You are not the owner");
         _;
    }
    
    struct transaction {
        address payable to;
        uint256 amount;
        uint256 txId;
        uint256 numOfApprovals;
        bool transactionSent;
    }

    transaction[] transactionLog;

    function deposit(address _msgSender) external payable returns(uint256)  {
        emit Deposit(msg.value, _msgSender);
        return address(this).balance;
    }

    function requestTransaction(address payable _recipient, uint256 _amount, address _msgSender) external onlyOwners {
        require(address(this).balance >= _amount, "Balance not sufficient");
        transactionLog.push( transaction(_recipient, _amount, transactionLog.length, 1, false) );
        approved[_msgSender][transactionLog.length-1] = true;
        emit TransactionsUpdated(transactionLog.length-1, 1, "Requested", _recipient, _msgSender, _amount);
    } 

    function approveTransaction(uint _txId, address _msgSender) external onlyOwners {
        require(transactionLog[_txId].transactionSent == false, "Transaction alredy sent.");
        require(approved[_msgSender][_txId] != true, "You already approved this transaction."); 
        transactionLog[_txId].numOfApprovals += 1;
        approved[_msgSender][_txId] = true;
        emit TransactionsUpdated(_txId, transactionLog[_txId].numOfApprovals, "Approved", transactionLog[_txId].to, _msgSender, transactionLog[_txId].amount);
    }

    function sendTransaction(uint _txId, address _msgSender) external onlyOwners {
        require(transactionLog[_txId].transactionSent == false, "Transaction alredy sent.");
        require(transactionLog[_txId].numOfApprovals >= requiredNumOfApprovals, "Not approved you need more approvals");
        require(address(this).balance >= transactionLog[_txId].amount, "Balance not sufficient");
        (bool sent, ) = transactionLog[_txId].to.call{value: transactionLog[_txId].amount}("");
        require(sent, "Failed to send Ether");
        transactionLog[_txId].transactionSent = true;
        emit TransactionsUpdated(_txId, transactionLog[_txId].numOfApprovals, "Sent", transactionLog[_txId].to, _msgSender, transactionLog[_txId].amount);
    }

    receive() external payable {
        emit Deposit(msg.value, msg.sender);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
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
        return msg.data;
    }
}