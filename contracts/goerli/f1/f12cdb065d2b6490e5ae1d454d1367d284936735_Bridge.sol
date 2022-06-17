//SPDX-License-Identifier: GNU Affero
pragma solidity ^0.8.0;

import "./interfaces/IBridge.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract Bridge is IBridge, Ownable, ReentrancyGuard {
    /**
    * @notice Deposit structure to keep track about value and lock timeout
    * @param value - amount of ether that is locked in contract
    * @param releaseTime - time for which the transfer needs to be done, otherwise the ether is returned to the sender 
     */
    struct Deposit {
      uint256 value;
      uint256 releaseTime;
    }
    uint256 public releaseTime;
    mapping(address => Deposit) public deposits;
    mapping(bytes32 => bool) public withdrawExecuted;

    /** 
    * @notice Invalid address. The address can not be zero.
     */
    error InvalidAddress();

    /** 
    * @notice Invalid chain. The chain can not be zero, and fromChain and toChain need to be different.
     */
    error InvalidChain();

    /** 
    * @notice Invalid amount of ether to send. The amount must be at least 1 wei.
     */
    error InvalidValueToSend();

    /**
    * @notice Deposit for this account is not allowed at the moment, please try later.
     */
    error DepositNotAllowed();

    /**
    * @notice The bridge contract does not have enough funds to transfer to the requested account
     */
    error InsufficientBalance();

    /**
    * @notice The funds have already been trasferred to the user, either when completing the bridging or when cancelling the deposit
     */
    error FundsAlreadyTransferred();

    /**
    * @notice The account does not have a deposit registered, it was either returned or claimed, or was never made
     */
    error DepositNotFound();

    /**
    * @notice The release time has not yet elapsed, so the deposit cannot yet be returned
     */
    error WithdrawalStillPending();

    /**
    * @notice The sumbitted transaction hash is invalid
     */
    error InvalidHash();

    /**
    * @notice The transfer of Ether has failed for some external reason
     */
    error EthTransferFailed();


    constructor(uint256 _releaseTime) {
      releaseTime = _releaseTime;
    }

    receive() external payable {}

    function deposit(uint256 _fromChain, uint256 _toChain, address _toAddress, uint256 _amount) public override payable{
      if(msg.sender == address(0)) {
        revert InvalidAddress();
      }
      if(_toAddress == address(0)) {
        revert InvalidAddress();
      }
      if(_fromChain == 0) {
        revert InvalidChain();
      }
      if(_toChain == 0) {
        revert InvalidChain();
      }
      if(_fromChain == _toChain) {
        revert InvalidChain();
      }
      if(msg.value <= 0) {
        revert InvalidValueToSend();
      }
      if(msg.value != _amount) {
        revert InvalidValueToSend();
      }
      if(deposits[msg.sender].releaseTime != 0) {
        revert DepositNotAllowed();
      }

      uint256 lockTimeout = block.timestamp + releaseTime;
      deposits[msg.sender] = Deposit(msg.value, lockTimeout);

      emit DepositEth(_fromChain, _toChain, msg.sender, _toAddress, _amount);
    }

    function withdraw(uint256 _fromChain, uint256 _toChain, address _fromAddress, address payable _toAddress, uint256 _amount, bytes32 _txHash) public override onlyOwner nonReentrant {
      if(_fromAddress == address(0)) {
        revert InvalidAddress();
      }
      if(_toAddress == address(0)) {
        revert InvalidAddress();
      }
      if(_fromChain == 0) {
        revert InvalidChain();
      }
      if(_toChain == 0) {
        revert InvalidChain();
      }
      if(_fromChain == _toChain) {
        revert InvalidChain();
      }
      if(_txHash == bytes32(0)) {
        revert InvalidHash();
      }
      if (_amount == 0) {
        revert InvalidValueToSend();
      }
      if (address(this).balance < _amount) {
        revert InsufficientBalance();
      }
      if (withdrawExecuted[_txHash]) {
        revert FundsAlreadyTransferred();
      }

      withdrawExecuted[_txHash] = true;
      (bool success,) = _toAddress.call{value: _amount}("");
      if (!success) {
        revert EthTransferFailed();
      }
      emit WithdrawEth(_fromChain, _toChain, _fromAddress, _toAddress, _amount);
    }

    function returnDeposit(address payable _fromAddress) public override {
      if(_fromAddress == address(0)) {
        revert InvalidAddress();
      }
      if (address(this).balance < deposits[_fromAddress].value) {
        revert InsufficientBalance();
      }
      if(deposits[_fromAddress].value == 0 || deposits[_fromAddress].releaseTime == 0) {
        revert DepositNotFound();
      }
      if (block.timestamp < deposits[_fromAddress].releaseTime) {
        revert WithdrawalStillPending();
      }

      uint256 amountToTransfer = deposits[_fromAddress].value;
      deposits[_fromAddress] = Deposit(0, 0);
      (bool success,) = _fromAddress.call{value: amountToTransfer}("");
      if (!success) {
        revert EthTransferFailed();
      }
      emit DepositReturned(_fromAddress);
    }

    function collectDeposit(address _fromAddress) public override onlyOwner {
      if(_fromAddress == address(0)) {
        revert InvalidAddress();
      }
      if(deposits[_fromAddress].value == 0 || deposits[_fromAddress].releaseTime == 0) {
        revert DepositNotFound();
      }

      deposits[_fromAddress] = Deposit(0, 0);
      emit DepositCollected(_fromAddress);
    }

    function fundBridge() public override payable {
      emit BridgeFunded(msg.sender, msg.value);
    }
}

//SPDX-License-Identifier: GNU Affero
pragma solidity ^0.8.0;

interface IBridge {
  event DepositEth(uint256 fromChain, uint256 toChain, address indexed fromAddress, address indexed toAddress, uint256 amount);
  event WithdrawEth(uint256 fromChain, uint256 toChain, address indexed fromAddress, address indexed toAddress, uint256 amount);
  event DepositCollected(address indexed fromAddress);
  event DepositReturned(address indexed fromAddress);
  event BridgeFunded(address funder, uint256 amount);

  /**
  * @notice Process request of sending some amount ether from one chain to another chain by send ether to contract and lock it till varification processs finish.
  * @param toChain is a chain id of test network to which we want to send ether
  * @param toAddress is address of account where we send ether
   */
  function deposit(uint256 fromChain, uint256 toChain, address toAddress, uint256 amount) external payable;

  /**
  * @notice Process request of withdrawing an amount of ether on the bridged chain
  * @param fromChain is the id of the test network from which the ether was sent
  * @param toChain is a chain id of test network to which we want to send ether
  * @param fromAddress is the address of the ether sender
  * @param toAddress is the address of the ether recipient
  * @param amount is the amount of ether to transfer to the recipient
  * @param txHash is the hash of the deposit transaction executed on the chain the user bridging from
   */
  function withdraw(uint256 fromChain, uint256 toChain, address fromAddress, address payable toAddress, uint256 amount, bytes32 txHash) external;

  /**
  * @notice Function called by the client to cancel the withdrawal and return the deposit in case the timeout is exeeded 
  * @param fromAddress is the address of the account that requested the bridging
   */
  function returnDeposit(address payable fromAddress) external;

  /**
  * @notice Function called by the client to collect the withdrawal after successful withdrawal
  * @param fromAddress is the address of the account that requested the bridging
   */
  function collectDeposit(address fromAddress) external;

  /**
  * @notice Function to add liquidity to the bridge via direct donation
   */
  function fundBridge() external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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