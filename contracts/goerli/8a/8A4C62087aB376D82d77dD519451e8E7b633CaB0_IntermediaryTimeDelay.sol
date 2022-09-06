// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
import "./util/PermissionGroup.sol";

contract IntermediaryTimeDelay is PermissionGroup{
    
    uint256 public constant minimumDelayPeriod = 60;

    uint256 public delayPeriod;

    mapping (bytes32 => uint) public queuedTransactions;

    event SetDelayPeriod(uint256 oldDelayPeriod, uint256 newDelayPeriod);

    event QueueTransaction(address sender, bytes32 indexed txHash, address indexed target, uint256 lockTime, uint256 endLock, bytes data);
    event ExecuteTransaction(bytes32 indexed txHash, address indexed target, bytes data, address sender);
    event CancelTransaction(bytes32 indexed txHash, address indexed target, bytes data, address sender);

    constructor(uint _delayPeriod) {
        delayPeriod = _delayPeriod;
    }

    function setDelayPeriod(uint256 _delayPeriod) public {
        require(msg.sender == address(this), "IntermediaryTimeDelay: only using executeTransaction function to call");
        require(minimumDelayPeriod <= _delayPeriod, "IntermediaryTimeDelay: too low delayPeriod");
        emit SetDelayPeriod(delayPeriod, _delayPeriod);
        delayPeriod = _delayPeriod;
    }

    function queueTransaction(address _target, bytes memory _data) public onlyOperator returns (bytes32) {
        require(_target != address(0), "IntermediaryTimeDelay: invalid address");
        bytes32 txHash = keccak256(abi.encode(_target, _data));
        require(queuedTransactions[txHash] == 0, "IntermediaryTimeDelay: already in the queue");
        queuedTransactions[txHash] = block.timestamp;

        emit QueueTransaction(msg.sender, txHash, _target, block.timestamp, block.timestamp + delayPeriod,  _data);
        return txHash;
    }

    function cancelTransaction(address _target, bytes memory _data) public onlyOperator {
        require(_target != address(0), "IntermediaryTimeDelay: invalid address");
        bytes32 txHash = keccak256(abi.encode(_target, _data));
        require(queuedTransactions[txHash] != 0, "IntermediaryTimeDelay: not found");
        queuedTransactions[txHash] = 0;

        emit CancelTransaction(txHash, _target, _data, msg.sender);
    }

    function executeTransaction(address _target, bytes memory _data) public onlyOperator returns (bytes memory response) {
        require(_target != address(0), "IntermediaryTimeDelay: invalid address");
        bytes32 txHash = keccak256(abi.encode(_target, _data));
        require(queuedTransactions[txHash] != 0, "IntermediaryTimeDelay: Call first lockTransaction");
        require(block.timestamp >= queuedTransactions[txHash]+ delayPeriod, "IntermediaryTimeDelay: not time yet ");

        // solium-disable-next-line security/no-call-value
        (bool success, bytes memory returnData) = _target.call(_data);
        require(success, "IntermediaryTimeDelay: Transaction execution reverted.");
        queuedTransactions[txHash] = 0;

        emit ExecuteTransaction(txHash, _target, _data, msg.sender);

        return returnData;
    }


}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../openzeppelin/contracts/access/Ownable.sol";

contract PermissionGroup is Ownable {
    // List of authorized address to perform some restricted actions
    mapping(address => bool) public operators;
    event AddOperator(address newOperator);
    event RemoveOperator(address operator);

    modifier onlyOperator() {
        require(operators[msg.sender], "PermissionGroup: not operator");
        _;
    }

    /**
     * @notice Adds an address as operator.
     */
    function addOperator(address operator) external onlyOwner {
        operators[operator] = true;
        emit AddOperator(operator);
    }

    /**
    * @notice Removes an address as operator.
    */
    function removeOperator(address operator) external onlyOwner {
        operators[operator] = false;
        emit RemoveOperator(operator);
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
    constructor() {
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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