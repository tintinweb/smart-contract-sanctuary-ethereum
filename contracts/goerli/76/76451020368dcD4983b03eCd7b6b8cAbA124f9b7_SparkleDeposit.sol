// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma experimental ABIEncoderV2;

import "./interfaces/IDepositContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
// import "truffle/console.sol";

contract SparkleDeposit is ReentrancyGuard, Ownable, Pausable{
    
    uint256  public period;  // period for locking fund 
    uint256 public minAmount; 
    uint256 public maxAmount;
    uint256 public depositTarget; // target for raising fund 

    mapping(address => uint) public depositBalance;
    uint256 public totalDepositBalance;
    uint256  public stakingStarted;
    uint256  public operationPeriod; // period for superior to stake

    uint256 public stakingEnd;
    uint256 public stakingReward;
    /**
     * @dev Eth2 Deposit Contract address.
     */
    IDepositContract public depositContract;



     event DepositIndividual(address indexed from, uint256 amount, uint256 timestamp );
     event DepositToETH2(address indexed from, uint256 amount, uint256 timestamp );
     event WithdrawIndividual(address indexed from, uint256 amount, uint256 timestamp );
     event Claim(address indexed from, uint256 amount, uint256 timestamp );
     event Finish(address indexed from, uint256 amount, uint256 timestamp );
     event RewardChange(uint256 amount, uint256 timestamp );
     event Adjust(uint256 amount, uint256 timestamp );

// max amount must be less or equal than 32 ether;
    constructor(bool mainnet, uint256 _period, uint256 _minAmount, uint256 _maxAmount, uint256 _depositTarget, address _depositContract)  {
        period = _period;
        minAmount = _minAmount;
        maxAmount = _maxAmount;
        depositTarget = _depositTarget;
        totalDepositBalance = 0;
        stakingStarted = 0;
        stakingEnd = 0;
        stakingReward = 0;
        operationPeriod = 1 days;
        // must set valid address
        if (mainnet == true) {
            depositContract = IDepositContract(0x00000000219ab540356cBB839Cbe05303d7705Fa);
        } else if (_depositContract == 0x0000000000000000000000000000000000000000) {
            depositContract = IDepositContract(0x8c5fecdC472E27Bc447696F431E425D02dd46a8c);
        } else {
            depositContract = IDepositContract(_depositContract);
        }

    }
    // for adjust the contract balance if it needed. etc. lack of gas fee.
    function adjustBalance() public payable onlyOwner {
        emit Adjust(msg.value, block.timestamp);
    }

// if deposit over the max require, it will throw error. no transfer back.
// the  value of address(this).balance returns the result of   original balance added value directly 
    function deposit() public payable whenNotPaused{
        // console.log("contractBalance1:", address(this).balance);
        // console.log("msg.value1:", msg.value);
        // uint sumbalance = address(this).balance + msg.value;
        // console.log("sumbalance1 ",sumbalance);
        
        require(msg.value >= minAmount  && msg.value <= maxAmount, "SparkleDeposit: Invalid deposit amount.");
        require(msg.value % minAmount == 0, "SparkleDeposit: Deposit amount must be in increments of {minAmount} WEI"); 
        require(address(this).balance  <= depositTarget, "SparkleDeposit: Maximum deposit limit reached.");
    
        
    
        depositBalance[msg.sender] += msg.value;
        totalDepositBalance += msg.value;

        emit DepositIndividual(msg.sender, msg.value, block.timestamp);

         if(address(this).balance == depositTarget) {
            stakingStarted = block.timestamp + operationPeriod; // add days for superior to stake
        }
    }


    // withdraw before lock
    function withdraw(address payable _to, uint _amount) public whenNotPaused{
        uint contractBalance = address(this).balance;
        require(_to == msg.sender, "SparkleDeposit: Withdraw not allow.");
        require(stakingStarted == 0, "SparkleDeposit: Deposit is starting.");
        require(depositBalance[_to] >= _amount, "SparkleDeposit: No funds to withdraw.");
        require(contractBalance >= _amount, "SparkleDeposit: No funds to withdraw.");
        require(_amount % minAmount == 0, "SparkleDeposit: Withdraw amount must be in increments of {minAmount} WEI");
        uint amount = _amount;
        depositBalance[_to] -= amount;
        totalDepositBalance -= amount;
        _to.transfer(amount);
        
        emit WithdrawIndividual(msg.sender, _amount, block.timestamp);
    }

// claim after the staking end, must after the finish function trigger;
    function claim(address payable _to) public whenNotPaused{
        require(_to == msg.sender, "SparkleDeposit: Withdraw not allow.");
        require(stakingEnd != 0, "SparkleDeposit: Withdraw not allow.");
        require(stakingReward > 0, "SparkleDeposit: StakingReward not enough.");
        require(depositBalance[msg.sender] > 0, "SparkleDeposit: depositBalance not enough.");
        require(address(this).balance >= depositTarget, "SparkleDeposit: contract Balance not enough.");

        uint originAmount = depositBalance[msg.sender];
        uint claimAmount = originAmount + originAmount * stakingReward / depositTarget; 
        depositBalance[msg.sender] = 0;
        totalDepositBalance -= claimAmount;
        _to.transfer(claimAmount);
         emit WithdrawIndividual(msg.sender, claimAmount, block.timestamp);
    }

// trigger when staking is end 
    function finish() public payable onlyOwner {
        require(msg.value > 0, "SparkleDeposit: value(reward) must grater than 0. ");
        stakingEnd = block.timestamp;
        stakingReward = msg.value;
        totalDepositBalance += depositTarget + msg.value;
        emit Finish(msg.sender, totalDepositBalance, block.timestamp);
    }

// before the finish function trigger , for apy caculation
    function setStakingReward(uint _amount) public onlyOwner {  
        require(stakingEnd == 0, "SparkleDeposit: stakingEnd must equal 0. ");   
        require(stakingStarted > 0, "SparkleDeposit: stakingStartrd must equal 0. ");   
        stakingReward = _amount;

        emit RewardChange(_amount, block.timestamp);
    }
   
    /**
     * @dev Function that allows to deposit 1 nodes at once.
     *
     * - pubkey                -  of BLS12-381 public key.
     * - withdrawal_credential -  of commitments to a public key for withdrawals.
     * - signature             -  of BLS12-381 signature.
     * - deposit_data_root     -  of the SHA-256 hashe of the SSZ-encoded DepositData object.
     */
    function depositToETH2(
        bytes calldata _pubkey,
        bytes calldata _withdrawal_credential,
        bytes calldata _signature,
        bytes32  _deposit_data_root
    ) external payable onlyOwner whenNotPaused{
        uint contractBalance = address(this).balance;
        require(contractBalance >= depositTarget, "SparkleDeposit:  Funds not enough.");
        totalDepositBalance -= depositTarget;

        address payable stakerAddress = payable(msg.sender);
        stakerAddress.transfer(depositTarget);

            IDepositContract(address(depositContract)).deposit{value: depositTarget}(
                _pubkey,
                _withdrawal_credential,
                _signature,
                _deposit_data_root
            );
            emit DepositToETH2(msg.sender, depositTarget, block.timestamp);
    }

    receive() external payable {
        revert("SparkleDeposit: do not send ETH directly here");
    }

        /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() public onlyOwner {
      _pause();
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function unpause() public onlyOwner {
      _unpause();
    }


}

// SPDX-License-Identifier: CC0-1.0

pragma solidity ^0.8.0;

// This interface is designed to be compatible with the Vyper version.
/// @notice This is the Ethereum 2.0 deposit contract interface.
/// For more information see the Phase 0 specification under https://github.com/ethereum/eth2.0-specs
interface IDepositContract {
    /// @notice A processed deposit event.
    event DepositEvent(
        bytes pubkey,
        bytes withdrawal_credentials,
        bytes amount,
        bytes signature,
        bytes index
    );

    /// @notice Submit a Phase 0 DepositData object.
    /// @param pubkey A BLS12-381 public key.
    /// @param withdrawal_credentials Commitment to a public key for withdrawals.
    /// @param signature A BLS12-381 signature.
    /// @param deposit_data_root The SHA-256 hash of the SSZ-encoded DepositData object.
    /// Used as a protection against malformed input.
    function deposit(
        bytes calldata pubkey,
        bytes calldata withdrawal_credentials,
        bytes calldata signature,
        bytes32 deposit_data_root
    ) external payable;

    /// @notice Query the current deposit root hash.
    /// @return The deposit root hash.
    function get_deposit_root() external view returns (bytes32);

    /// @notice Query the current deposit count.
    /// @return The deposit count encoded as a little endian 64-bit number.
    function get_deposit_count() external view returns (bytes memory);
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
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