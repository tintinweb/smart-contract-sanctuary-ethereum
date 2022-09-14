// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "sgn-v2-contracts/contracts/message/interfaces/IMessageBus.sol";
import "./interfaces/IMessage.sol";
import "./libraries/DataTypes.sol";

/// @title A vault contract which deployed on EVM chain(Not BSC chain), user can stake LP token from liquidity pool
/// in EVM chain to participate MasterchefV2 farm pools(BSC chain), get native CAKE reward in BSC chain.
/// @dev deployed on EVM chain(source chain, not BSC chain).
contract CrossFarmingVault is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct UserInfo {
        uint256 amount; // user deposit original LP token amount.
        uint256 lastActionTime;
    }

    struct PoolInfo {
        IERC20 lpToken;
        uint256 mcv2PoolId; // pool id in Pancakeswap MastercherV2 farms.
        uint256 totalAmount; // total staked LP token amount.
    }

    // Info of each pool.
    PoolInfo[] public poolInfo;

    // cross farming sender contract deployed on other EVM chain(none bsc chain)
    // which send cross-chain msg to celer messagebus deployed on EVM chain.
    address public CROSS_FARMING_SENDER;
    // cross farming receiver contract deployed on BSC chain
    // which receive cross-chain msg from celer messagebus deployed on BSC chain.
    address public CROSS_FARMING_RECEIVER;
    // the operator for fallbackwithdraw/deposit.
    address public operator;
    // BSC chain ID
    uint64 public immutable BSC_CHAIN_ID;

    // whether LP tokend added to pool
    mapping(IERC20 => bool) public exists;
    // deposit records (account => (pid => (nonce => amount))
    /// @notice this is just for 'deposit' function, make sure operator fallbackDeposit amount
    /// exactly match original deposit amount, in withdraw related function should not consider this.
    mapping(address => mapping(uint256 => mapping(uint64 => uint256))) public deposits;
    // MCV2 pool 1:1 vault pool
    mapping(uint256 => uint256) public poolMapping;
    // white list masterchefv2 pool id. function 'add' mcv2 pool id should be in the list.
    mapping(uint256 => bool) public whitelistPool;
    // Info of each user.
    mapping(uint256 => mapping(address => UserInfo)) public userInfo;
    /// @notice used fallback nonce (user => (pid => (nonce => bool)))
    mapping(address => mapping(uint256 => mapping(uint64 => bool))) public fallbackNonce;

    event Pause();
    event Unpause();
    event AddedWhiteListPool(uint256 pid);
    event AddedPool(address indexed lpToken, uint256 mockPoolId);
    event Deposit(address indexed sender, uint256 pid, uint256 amount);
    event Withdraw(address indexed sender, uint256 pid, uint256 amount);
    event EmergencyWithdraw(address indexed sender, uint256 pid, uint256 amount);
    event OperatorUpdated(address indexed newOperator, address indexed oldOperator);
    event AckWithdraw(address indexed sender, uint256 pid, uint256 amount, uint64 nonce);
    event FallbackDeposit(address indexed sender, uint256 pid, uint256 amount, uint64 nonce);
    event FallbackWithdraw(address indexed sender, uint256 pid, uint256 amount, uint64 nonce);
    event AckEmergencyWithdraw(address indexed sender, uint256 pid, uint256 amount, uint64 nonce);
    event FarmingContractUpdated(address indexed sender, address senderContract, address receiverContract);

    /**
     * @param _operator: a priviledged user for fallback operation.
     * @param _sender: cross farming sender contract on EVM chain
     * @param _receiver: cross farming receiver contract on BSC
     * @param _chainId: BSC chain ID
     */
    constructor(
        address _operator,
        address _sender,
        address _receiver,
        uint64 _chainId
    ) {
        operator = _operator;
        CROSS_FARMING_SENDER = _sender;
        CROSS_FARMING_RECEIVER = _receiver;
        BSC_CHAIN_ID = _chainId;

        // dummpy pool, poolInfo index increase from 1.
        poolInfo.push(PoolInfo({lpToken: IERC20(address(0)), mcv2PoolId: 0, totalAmount: 0}));
    }

    modifier onlySender() {
        require(msg.sender == CROSS_FARMING_SENDER, "not cross farming sender");
        _;
    }

    modifier onlyOperator() {
        require(msg.sender == operator, "not fallback operator");
        _;
    }

    modifier onlyNotFallback(
        address _user,
        uint256 _pid,
        uint64 _nonce
    ) {
        require(!fallbackNonce[_user][_pid][_nonce], "used fallback nonce");
        _;
    }

    modifier notContract() {
        require(!_isContract(msg.sender), "contract not allowed");
        require(msg.sender == tx.origin, "proxy contract not allowed");
        _;
    }

    /**
     * @notice Add available MasterchefV2 farm pool id for cross-farming.
     * @param _mcv2Pid MasterchefV2 pool id array.
     */
    function addWhiteListPool(uint256 _mcv2Pid) public onlyOwner {
        require(!whitelistPool[_mcv2Pid], "Added mcv2 pool id");
        whitelistPool[_mcv2Pid] = true;

        emit AddedWhiteListPool(_mcv2Pid);
    }

    /**
     * @notice Add lp token and pool id corresponding to masterchefv2 farm pool.
     * @dev same token can't be added repeatedly.
     * @param _lpToken lp token address.
     * @param _mcv2PoolId pool id in masterchefv2 farm pool.
     */
    function add(IERC20 _lpToken, uint256 _mcv2PoolId) public onlyOwner {
        require(!exists[_lpToken], "Token added");
        require(!whitelistPool[_mcv2PoolId], "None whitelist pool");
        require(poolMapping[_mcv2PoolId] == 0, "MCV2 pool mappinged");
        require(_lpToken.balanceOf(address(this)) >= 0, "None ERC20 token");

        // add poolInfo
        poolInfo.push(PoolInfo({lpToken: _lpToken, mcv2PoolId: _mcv2PoolId, totalAmount: 0}));

        // update mappping
        exists[_lpToken] = true;
        poolMapping[_mcv2PoolId] = poolInfo.length - 1;

        emit AddedPool(address(_lpToken), _mcv2PoolId);
    }

    /**
     * @notice deposit funds into current vault.
     * @dev only possible when contract not paused.
     * @param _pid lp token pool id in vault contract.
     * @param _amount deposit token amount.
     */
    function deposit(uint256 _pid, uint256 _amount) external payable nonReentrant whenNotPaused notContract {
        require(_amount > 0, "Nothing to deposit");

        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 before = pool.lpToken.balanceOf(address(this));
        pool.lpToken.safeTransferFrom(msg.sender, address(this), _amount);
        _amount = pool.lpToken.balanceOf(address(this)) - before;

        uint64 nonce = IMessage(CROSS_FARMING_SENDER).nonces(msg.sender, _pid);

        // encode farming message, for reuse 'nonce', don't call encodeMessage.
        bytes memory message = abi.encode(
            DataTypes.CrossFarmRequest({
                receiver: CROSS_FARMING_RECEIVER,
                dstChainId: BSC_CHAIN_ID,
                nonce: nonce,
                account: msg.sender,
                amount: _amount,
                pid: pool.mcv2PoolId,
                msgType: DataTypes.MessageTypes.Deposit
            })
        );

        // send message
        (bool success, ) = CROSS_FARMING_SENDER.call{value: msg.value}(
            abi.encodeWithSignature("sendFarmMessage(bytes)", message)
        );

        require(success, "send deposit farm message failed");

        // update poolInfo
        pool.totalAmount = pool.totalAmount + _amount;
        // update userInfo
        user.amount = user.amount + _amount;
        user.lastActionTime = block.timestamp;
        // save deposit record
        deposits[msg.sender][_pid][nonce] = _amount;

        emit Deposit(msg.sender, _pid, _amount);
    }

    /**
     * @notice withdraw funds from vault.
     * @dev just send 'withdraw' message to MasterchefV2 pool on BSC chain. didn't transfer LP token to user,
     * after withdraw on Masterchef pool success and send ack message back, ackWithdraw will finally transfer token back.
     * @dev only possible when contract not paused.
     * @param _pid lp token pool id in vault contract.
     * @param _amount withdraw token amount.
     */
    function withdraw(uint256 _pid, uint256 _amount) external payable nonReentrant whenNotPaused notContract {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        require(user.amount >= _amount && _amount > 0, "withdraw: Insufficient amount");

        // encode farming message
        bytes memory message = encodeMessage(msg.sender, pool.mcv2PoolId, _amount, DataTypes.MessageTypes.Withdraw);

        // send message
        (bool success, ) = CROSS_FARMING_SENDER.call{value: msg.value}(
            abi.encodeWithSignature("sendFarmMessage(bytes)", message)
        );

        require(success, "send withdraw farm message failed");

        // will not do any state change, wil do it at ackWithdraw

        emit Withdraw(msg.sender, _pid, _amount);
    }

    /**
     * @notice withdraw funds from vault.
     * @dev just send 'emergencyWithdraw' message to MasterchefV2 pool on BSC chain. didn't transfer LP token to user,
     * after emergencyWithdraw on Masterchef pool success and send ack message back, 'ackEmergencyWithdraw' will finally transfer token back.
     * @dev only possible when contract not paused.
     * @param _pid lp token pool id in vault contract.
     */
    function emergencyWithdraw(uint256 _pid) external payable nonReentrant notContract {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];

        uint256 amount = user.amount;
        require(amount > 0, "No fund left");

        bytes memory message = encodeMessage(
            msg.sender,
            pool.mcv2PoolId,
            amount,
            DataTypes.MessageTypes.EmergencyWithdraw
        );

        // send farming message
        (bool success, ) = CROSS_FARMING_SENDER.call{value: msg.value}(
            abi.encodeWithSignature("sendFarmMessage(bytes)", message)
        );

        require(success, "send emergencyWithdraw farm message failed");

        // will not do any state change, will do it at ackEmergencyWithdraw

        emit EmergencyWithdraw(msg.sender, _pid, amount);
    }

    /**
     * @notice only called by cross-chain sender contract. withdraw token in specific pool.
     * @param _user lp token pool id in vault contract.
     * @param _mcv2pid lp token pool id in mcv2 farm pool.
     * @param _amount withdraw token amount.
     * @param _nonce withdraw tx nonce from BSC chain.
     */
    function ackWithdraw(
        address _user,
        uint256 _mcv2pid,
        uint256 _amount,
        uint64 _nonce
    ) external payable nonReentrant onlySender {
        uint256 pid = poolMapping[_mcv2pid];
        require(!fallbackNonce[_user][pid][_nonce], "fallback nonce");

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_user];

        // check by ack amount
        require(user.amount >= _amount && _amount > 0, "ackWithdraw: Insufficient amount");

        // transfer LP token
        IERC20(pool.lpToken).safeTransfer(_user, _amount);

        // update poolInfo
        pool.totalAmount = pool.totalAmount - _amount;
        // update userInfo
        user.amount -= _amount;
        user.lastActionTime = block.timestamp;

        // mark fallback nonce used
        fallbackNonce[_user][pid][_nonce] = true;

        emit AckWithdraw(_user, pid, _amount, _nonce);
    }

    /**
     * @notice only called by cross-chain sender contract. withdraw all staked token in specific pool.
     * @param _user lp token pool id in vault contract.
     * @param _mcv2pid lp token pool id in mcv2 farm pool.
     * @param _nonce withdraw tx nonce from BSC chain.
     */
    function ackEmergencyWithdraw(
        address _user,
        uint256 _mcv2pid,
        uint64 _nonce
    ) external payable nonReentrant onlySender {
        uint256 pid = poolMapping[_mcv2pid];
        require(!fallbackNonce[_user][pid][_nonce], "fallback nonce");

        PoolInfo storage pool = poolInfo[pid];
        UserInfo storage user = userInfo[pid][_user];

        uint256 withdrawAmount = user.amount;
        // transfer token
        IERC20(pool.lpToken).safeTransfer(_user, withdrawAmount);

        // totalAmount > withdrawAmount
        pool.totalAmount -= withdrawAmount;
        // update userInfo
        user.amount = 0;
        user.lastActionTime = block.timestamp;
        // mark fallback nonce used
        fallbackNonce[_user][pid][_nonce] = true;

        emit AckEmergencyWithdraw(_user, pid, withdrawAmount, _nonce);
    }

    /**
     * @dev called by operator when user deposit success on sourcechin but failed on dest chain(BSC chain).
     * please make sure 'fallbackDeposit' called on BSC chain first.
     * @param _user user address.
     * @param _pid pool id in current vault, not mcv2 pid.
     * @param _amount fallbackDeposit withdraw token amount.
     * @param _nonce fallback nonce.
     */
    function fallbackDeposit(
        address _user,
        uint256 _pid,
        uint256 _amount,
        uint64 _nonce
    ) external onlyOperator onlyNotFallback(_user, _pid, _nonce) {
        // double check
        require(deposits[_user][_pid][_nonce] == _amount, "withdraw amount not match staking record");

        _fallback(_user, _pid, _amount, _nonce);

        emit FallbackDeposit(_user, _pid, _amount, _nonce);
    }

    /**
     * @dev called by operator when user wihtdraw/emergencywithdraw success on source chain(EVM)chain
     * but failed on dest chain, please make sure 'fallbackWithdraw' called on BSC chain first.
     * @param _user user address.
     * @param _pid pool id in current vault, not mcv2 pool id.
     * @param _amount fallbackwithdraw token amount.
     * @param _nonce fallback nonce.
     */
    function fallbackWithdraw(
        address _user,
        uint256 _pid,
        uint256 _amount,
        uint64 _nonce
    ) external onlyOperator onlyNotFallback(_user, _pid, _nonce) {
        _fallback(_user, _pid, _amount, _nonce);

        emit FallbackWithdraw(_user, _pid, _amount, _nonce);
    }

    function _fallback(
        address _user,
        uint256 _pid,
        uint256 _amount,
        uint64 _nonce
    ) internal {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        // check fallback amount
        require(user.amount >= _amount && _amount > 0, "fallback: Insufficient amount");

        // update poolInfo
        pool.totalAmount = pool.totalAmount - _amount;
        // update userInfo
        user.amount -= _amount;
        user.lastActionTime = block.timestamp;

        // mark fallback nonce used
        fallbackNonce[_user][_pid][_nonce] = true;

        // transfer LP token back
        IERC20(pool.lpToken).safeTransfer(_user, _amount);
    }

    // set fallbackwithdraw operator
    function setOperator(address _operator) external onlyOwner {
        require(_operator != address(0), "Operator can't be zero address");
        address temp = operator;
        operator = _operator;

        emit OperatorUpdated(operator, temp);
    }

    /**
     * @notice update cross farming contract address.
     * @param _crossSender cross-chain contract on source chain.
     * @param _crossReceiver cross-chain contract on dest chain.
     */
    function setCrossFarmingContract(address _crossSender, address _crossReceiver) external onlyOwner {
        require(
            address(_crossSender) != address(0) && address(_crossReceiver) != address(0),
            "Invalid farming contract"
        );

        CROSS_FARMING_SENDER = _crossSender;
        CROSS_FARMING_RECEIVER = _crossReceiver;

        emit FarmingContractUpdated(msg.sender, _crossSender, _crossReceiver);
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

    /**
     * @notice utility interface for FE to calc routing message fee charged by celer.
     * @param _message encoded cross-farm  message
     */
    function calcFee(bytes calldata _message) external returns (uint256) {
        address messageBus = IMessage(CROSS_FARMING_SENDER).messageBus();
        return IMessageBus(messageBus).calcFee(_message);
    }

    /**
     * @notice utility interface for FE to encode cross-farming message.
     * @param _account cross-farm user account.
     * @param _pid mock pool id in Pancake MasterchefV2.
     * @param _amount the input token amount.
     * @param _msgType farm message type.
     */
    function encodeMessage(
        address _account,
        uint256 _pid,
        uint256 _amount,
        DataTypes.MessageTypes _msgType
    ) public returns (bytes memory) {
        return
            abi.encode(
                DataTypes.CrossFarmRequest({
                    receiver: CROSS_FARMING_RECEIVER,
                    dstChainId: BSC_CHAIN_ID,
                    nonce: IMessage(CROSS_FARMING_SENDER).nonces(_account, _pid),
                    account: _account,
                    amount: _amount,
                    pid: _pid,
                    msgType: _msgType
                })
            );
    }

    /**
     * @notice Triggers stopped state
     * @dev Only possible when contract not paused.
     */
    function pause() external onlyOwner whenNotPaused {
        _pause();
        emit Pause();
    }

    /**
     * @notice Returns to normal state
     * @dev Only possible when contract is paused.
     */
    function unpause() external onlyOwner whenPaused {
        _unpause();
        emit Unpause();
    }

    function _isContract(address addr) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return size > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "../libraries/DataTypes.sol";

interface IMessage {
    function nonces(address account, uint256 pid) external returns (uint64);

    function messageBus() external returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

library DataTypes {
    enum MessageTypes {
        Deposit,
        Withdraw,
        EmergencyWithdraw
    }

    struct CrossFarmRequest {
        address receiver;
        uint64 dstChainId;
        uint64 nonce;
        address account;
        uint256 pid;
        uint256 amount;
        MessageTypes msgType;
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity >=0.8.0;

import "../libraries/MsgDataTypes.sol";

interface IMessageBus {
    function liquidityBridge() external view returns (address);

    function pegBridge() external view returns (address);

    function pegBridgeV2() external view returns (address);

    function pegVault() external view returns (address);

    function pegVaultV2() external view returns (address);

    /**
     * @notice Calculates the required fee for the message.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     @ @return The required fee.
     */
    function calcFee(bytes calldata _message) external view returns (uint256);

    /**
     * @notice Sends a message to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native gas token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessage(
        address _receiver,
        uint256 _dstChainId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Sends a message associated with a transfer to an app on another chain via MessageBus without an associated transfer.
     * A fee is charged in the native token.
     * @param _receiver The address of the destination app contract.
     * @param _dstChainId The destination chain ID.
     * @param _srcBridge The bridge contract to send the transfer with.
     * @param _srcTransferId The transfer ID.
     * @param _dstChainId The destination chain ID.
     * @param _message Arbitrary message bytes to be decoded by the destination app contract.
     */
    function sendMessageWithTransfer(
        address _receiver,
        uint256 _dstChainId,
        address _srcBridge,
        bytes32 _srcTransferId,
        bytes calldata _message
    ) external payable;

    /**
     * @notice Withdraws message fee in the form of native gas token.
     * @param _account The address receiving the fee.
     * @param _cumulativeFee The cumulative fee credited to the account. Tracked by SGN.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A withdrawal must be
     * signed-off by +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function withdrawFee(
        address _account,
        uint256 _cumulativeFee,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external;

    /**
     * @notice Execute a message with a successful transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransfer(
        bytes calldata _message,
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message with a refunded transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _transfer The transfer info.
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessageWithTransferRefund(
        bytes calldata _message, // the same message associated with the original transfer
        MsgDataTypes.TransferInfo calldata _transfer,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;

    /**
     * @notice Execute a message not associated with a transfer.
     * @param _message Arbitrary message bytes originated from and encoded by the source app contract
     * @param _sigs The list of signatures sorted by signing addresses in ascending order. A relay must be signed-off by
     * +2/3 of the sigsVerifier's current signing power to be delivered.
     * @param _signers The sorted list of signers.
     * @param _powers The signing powers of the signers.
     */
    function executeMessage(
        bytes calldata _message,
        MsgDataTypes.RouteInfo calldata _route,
        bytes[] calldata _sigs,
        address[] calldata _signers,
        uint256[] calldata _powers
    ) external payable;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: GPL-3.0-only

pragma solidity 0.8.9;

library MsgDataTypes {
    // bridge operation type at the sender side (src chain)
    enum BridgeSendType {
        Null,
        Liquidity,
        PegDeposit,
        PegBurn,
        PegV2Deposit,
        PegV2Burn,
        PegV2BurnFrom
    }

    // bridge operation type at the receiver side (dst chain)
    enum TransferType {
        Null,
        LqRelay, // relay through liquidity bridge
        LqWithdraw, // withdraw from liquidity bridge
        PegMint, // mint through pegged token bridge
        PegWithdraw, // withdraw from original token vault
        PegV2Mint, // mint through pegged token bridge v2
        PegV2Withdraw // withdraw from original token vault v2
    }

    enum MsgType {
        MessageWithTransfer,
        MessageOnly
    }

    enum TxStatus {
        Null,
        Success,
        Fail,
        Fallback,
        Pending // transient state within a transaction
    }

    struct TransferInfo {
        TransferType t;
        address sender;
        address receiver;
        address token;
        uint256 amount;
        uint64 wdseq; // only needed for LqWithdraw (refund)
        uint64 srcChainId;
        bytes32 refId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    struct RouteInfo {
        address sender;
        address receiver;
        uint64 srcChainId;
        bytes32 srcTxHash; // src chain msg tx hash
    }

    struct MsgWithTransferExecutionParams {
        bytes message;
        TransferInfo transfer;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }

    struct BridgeTransferParams {
        bytes request;
        bytes[] sigs;
        address[] signers;
        uint256[] powers;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}