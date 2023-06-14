// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;


import "../access/Controller.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ILaunchPad.sol";
import "../interfaces/IRefunder.sol";
import "../interfaces/IVesting.sol";
enum VESTING_TYPE {
    FLEXIBLE,
    LINEAR
}
struct PoolInfo{
    VESTING_TYPE poolType;
    address token;
    string project_id;
    uint256 totalLocked;
    uint256 totalClaimed;
    address distributionAddress;
}

struct LinearPoolDetails{
    uint256  firstReleaseRatio;
    uint256  unlockTime;
    uint256  startReleaseTimestamp;
    uint256  endReleaseTimestamp;
}
struct FlexiblePoolDetails{
    uint256[] claimDates;
    uint256[] claimPercents;
}

struct Allocation{
    uint256 allocated;
    uint256 claimed;
}
error poolAlreadyExist();
error invalidTokenAddress();
error invalidStartTime();
error invalidEndTime();
error invalidUnlockTime();
error invalidReleaseRatio();
error poolNotFlexible();
error poolNotLinear();
error zeroClaimable();
error refunded();
error PoolNotSafeToDelete();
error notTreasury();
error amountMustBeZeorOrGreaterThanClaimed();
error PoolDoesntExist();
error mismatchClaimLengths();
contract NeoVestingCombined is IVesting,Controller,ReentrancyGuard{
    using SafeERC20 for IERC20;

    mapping(string=>PoolInfo)public Pools ;
    mapping(string=>LinearPoolDetails)internal linearPoolDetails;
    mapping(string=>FlexiblePoolDetails)internal felxiblePoolDetails;
    mapping(string=> bool)public NotSafeDelete;
    mapping(string=>mapping(address => Allocation))public allocations;
    mapping(string => uint256) public projectClaimedTotal;
    mapping(string=>mapping(address=>uint256)) public projectClaimedTotalByUser;
    uint256 public percision = 1e18;
    IRefunder public Refunder;
    constructor(address owner){
        adminList[msg.sender] = true;
        adminList[owner]  = true;
        transferOwnership(owner);
    }
    event PoolCreated(string indexed pool_id);
    function createLinearVesting(
        string calldata _project_id,
        string calldata _pool_id,
        address _token,
        uint256  _firstReleaseRatio,
        uint256  _unlockTime,
        uint256  _startReleaseTimestamp,
        uint256  _endReleaseTimestamp,
        address distributionAddress) external isNewPool(_pool_id) onlyAdmin {
            if(_token == address(0)){
                revert invalidTokenAddress();
            }
            if(_unlockTime < block.timestamp){
                revert invalidUnlockTime();
            }
            if(_startReleaseTimestamp < _unlockTime){
                revert invalidStartTime();
            }
            if(_endReleaseTimestamp < _startReleaseTimestamp){
                revert invalidEndTime();
            }
            if(_firstReleaseRatio >= 100 *1e18){
                revert invalidReleaseRatio();
            }
            Pools[_pool_id] = PoolInfo(
                VESTING_TYPE.LINEAR,
                _token,
                _project_id,
                0,
                0,
                distributionAddress
            );
            linearPoolDetails[_pool_id] = LinearPoolDetails(
                _firstReleaseRatio,
                _unlockTime,
                _startReleaseTimestamp,
                _endReleaseTimestamp
                
            );
            emit PoolCreated(_pool_id);
    }

    function createFlexibleVesting(
        string calldata _project_id,
        string calldata _pool_id,
        address _token, 
        uint256[] calldata _claimDates,
        uint256[] calldata _claimPercents,
        address distributionAddress) external isNewPool(_pool_id) onlyAdmin{
            if(_token == address(0)){
                revert invalidTokenAddress();
            }
            if(_claimDates.length !=_claimPercents.length){
                revert mismatchClaimLengths();
            }
            Pools[_pool_id] = PoolInfo(
                VESTING_TYPE.FLEXIBLE,
                _token,
                _project_id,
                0,
                0,
                distributionAddress
            );
            felxiblePoolDetails[_pool_id] = FlexiblePoolDetails(
                _claimDates,
                _claimPercents
            );
            emit PoolCreated(_pool_id);
    }

    function claim(string calldata _pool_id) external poolExist(_pool_id) {
        if(!NotSafeDelete[_pool_id]){
            NotSafeDelete[_pool_id] = true;
        }
        PoolInfo storage p =Pools[_pool_id];
        Allocation storage a = allocations[_pool_id][msg.sender];
        uint256 refundedAmount;
        if(address(Refunder) != address(0)){
            refundedAmount = Refunder.userRefundedAmountsToken(msg.sender,p.project_id);
        }
        uint256 amountUnlocked;
        uint256 amountClaimed;
        if(refundedAmount > 0){
            revert refunded();
        }
        if(a.allocated == a.claimed){
            revert zeroClaimable();
        }
        if(p.poolType ==VESTING_TYPE.FLEXIBLE){
            ( amountUnlocked, amountClaimed) = calculateAmountUnlockedAndClaimedFlexible(msg.sender,_pool_id);
        }
        else{
            (amountUnlocked,amountClaimed) = calculateAmountUnlockedAndClaimedLinear(msg.sender,_pool_id);         
        }
        if(amountUnlocked <= amountClaimed){
            revert zeroClaimable();
        }
        uint256 totalClaimable = amountUnlocked - amountClaimed; 
        IERC20(p.token).safeTransfer(msg.sender,totalClaimable);
        p.totalClaimed +=totalClaimable;
        a.claimed  +=totalClaimable;
        projectClaimedTotal[p.project_id] +=totalClaimable;
        projectClaimedTotalByUser[p.project_id][msg.sender]+=totalClaimable;
    }

    function allocate(string calldata _pool_id, address wallet,uint256 amount)external  poolExist(_pool_id) onlyAdmin{
        Allocation storage a = allocations[_pool_id][wallet];
        PoolInfo storage p = Pools[_pool_id];
        uint256 refundedAmount;
        if(address(Refunder) != address(0)){
            refundedAmount = Refunder.userRefundedAmountsToken(wallet,p.project_id);
        }
        if(refundedAmount > 0){
            p.totalLocked -= a.allocated - a.claimed;
            IERC20(p.token).safeTransfer(
                p.distributionAddress,
                a.allocated - a.claimed);
                 a.allocated = a.claimed;
        }
        else if(amount >a.allocated){
            p.totalLocked += amount - a.allocated;
            IERC20(p.token).safeTransferFrom(
                p.distributionAddress,
                address(this),
                amount - a.allocated);
                a.allocated = amount;
        }
        else if(amount == 0){
            p.totalLocked -= a.allocated - a.claimed;
            IERC20(p.token).safeTransfer(
                p.distributionAddress,
                a.allocated - a.claimed);
            a.allocated = a.claimed;
        }
        else{
            revert amountMustBeZeorOrGreaterThanClaimed();    
        }
    }
    function allocateBatch(string calldata _pool_id,address[] calldata wallets, uint256[] calldata amounts) external  poolExist(_pool_id)  onlyAdmin{
        PoolInfo storage p = Pools[_pool_id];
        uint256 transferHere;
        uint256 transferToDistribution;
        for(uint256 i; i<wallets.length;i++){
            Allocation storage a = allocations[_pool_id][wallets[i]];
            uint256 refundedAmount;
            if(address(Refunder) != address(0)){
                refundedAmount = Refunder.userRefundedAmountsToken(wallets[i],p.project_id);
            }
            if(refundedAmount >0){
                p.totalLocked -= a.allocated - a.claimed;
                transferToDistribution += a.allocated - a.claimed;
                a.allocated = a.claimed;
            }
            else if(amounts[i] > a.allocated){
                p.totalLocked += amounts[i] - a.allocated;
                transferHere += amounts[i] - a.allocated;
                a.allocated = amounts[i];
            }
            else if(amounts[i] == 0){
                p.totalLocked -= a.allocated - a.claimed;
                transferToDistribution += a.allocated - a.claimed;
                a.allocated  = a.claimed;
            }
            else{
                revert amountMustBeZeorOrGreaterThanClaimed();    
            }
        }  
        if(transferHere > transferToDistribution){
            IERC20(p.token).safeTransferFrom(
            p.distributionAddress,
            address(this),
            transferHere - transferToDistribution);
        }
        else if(transferToDistribution > transferHere){
            IERC20(p.token).safeTransfer(
                p.distributionAddress,
                transferToDistribution -transferHere
            );
        } 
    }
    
    function calculateAmountUnlockedAndClaimedFlexible(address wallet,string calldata _pool_id)public  poolExist(_pool_id) view returns(uint256,uint256){
        // check refunsd status and calculate claimable
        PoolInfo storage p =Pools[_pool_id];
        Allocation storage a = allocations[_pool_id][wallet];
        uint256 refundedAmount;
        if(address(Refunder) != address(0)){
            refundedAmount = Refunder.userRefundedAmountsToken(wallet,p.project_id);
        }      
        if(refundedAmount > 0){
            return(0,a.claimed);
        }
        if(p.poolType != VESTING_TYPE.FLEXIBLE){
            revert poolNotFlexible();
        }
        FlexiblePoolDetails storage f = felxiblePoolDetails[_pool_id];
            if (block.timestamp < f.claimDates[0]) {
                return (0, 0);
            }
            for (uint256 i = 1; i < f.claimDates.length; i++) {
                if (block.timestamp > f.claimDates[i - 1] &&block.timestamp < f.claimDates[i]) {
                    uint claimable =  (f.claimPercents[i - 1] * (a.allocated)/(100 * percision));
                    return (
                        claimable,
                        a.claimed
                    );
                }
            }
            return (a.allocated, a.claimed);
    }

    function calculateAmountUnlockedAndClaimedLinear(address wallet,string calldata _pool_id)public  poolExist(_pool_id) view returns(uint256,uint256){
        PoolInfo storage p =Pools[_pool_id];
        Allocation storage a = allocations[_pool_id][wallet];
        uint256 refundedAmount = Refunder.userRefundedAmountsToken(wallet,p.project_id); // in Stable
        uint256 UnlockedAmount = 0;
        if(refundedAmount > 0){
            return(0,a.claimed);
        }
        if(p.poolType != VESTING_TYPE.LINEAR){
            revert poolNotLinear();
        }
        LinearPoolDetails memory l = linearPoolDetails[_pool_id];
        if (block.timestamp < l.unlockTime) {
           return(0,a.claimed);
        } 
        else if(block.timestamp >= l.unlockTime && block.timestamp < l.startReleaseTimestamp) {
            UnlockedAmount = a.allocated * l.firstReleaseRatio /(100 * percision);
            return(UnlockedAmount,a.claimed);
        } 
        else if (block.timestamp >= l.endReleaseTimestamp){
            UnlockedAmount = a.allocated;
            return (UnlockedAmount,a.claimed);
        }
        else  {
            UnlockedAmount = a.allocated;
            uint256 releasedTime = block.timestamp - l.startReleaseTimestamp;
            uint256 totalVestingTime = l.endReleaseTimestamp - l.startReleaseTimestamp;
            uint256 firstUnlockAmount =  a.allocated *l.firstReleaseRatio/(100 * percision);
            uint256 totalLinearUnlockAmount =  a.allocated - firstUnlockAmount;
            uint256 linearUnlockAmount = totalLinearUnlockAmount *releasedTime / totalVestingTime;
            UnlockedAmount = firstUnlockAmount+linearUnlockAmount;
            return (UnlockedAmount,a.claimed);
        }     
    }
    function getFlexiblePoolDetails(string calldata pool_id)external poolExist(pool_id) view returns(uint256[] memory claimDates,uint256[] memory claimPercents){
        PoolInfo storage p = Pools[pool_id];
        if(p.poolType != VESTING_TYPE.FLEXIBLE){
            revert poolNotFlexible();
        }
        FlexiblePoolDetails storage f = felxiblePoolDetails[pool_id];
        claimDates = f.claimDates;
        claimPercents = f.claimPercents;
    }
    function getLinearPoolDetails(string calldata pool_id)external poolExist(pool_id) view returns(LinearPoolDetails memory){
        PoolInfo storage p = Pools[pool_id];
        if(p.poolType != VESTING_TYPE.LINEAR){
            revert poolNotLinear();
        }
        return linearPoolDetails[pool_id];
    } 
    modifier isNewPool(string calldata _poolId){
        if(Pools[_poolId].token != address(0)){
            revert poolAlreadyExist();
        }
        _;
    }
    modifier poolExist(string memory pool_id){
        if(Pools[pool_id].token == address(0)){
            revert PoolDoesntExist();
        }
        _;
    }
    function closePool(string calldata _pool_id) external onlyAdmin{
        if(NotSafeDelete[_pool_id]){
            revert PoolNotSafeToDelete();
        }
        PoolInfo storage p = Pools[_pool_id];
        if(p.poolType == VESTING_TYPE.FLEXIBLE){
            delete felxiblePoolDetails[_pool_id];
        }
        else{
            delete linearPoolDetails[_pool_id];
        }
        IERC20(p.token).safeTransfer(p.distributionAddress,p.totalLocked);
        delete Pools[_pool_id];
    }
    function setRefunder(IRefunder refunder_) external onlyAdmin{
        Refunder = refunder_;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

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
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Controller is Ownable {
    mapping(address => bool) public adminList;

    function setAdmin(address user_, bool status_) public onlyOwner {
        adminList[user_] = status_;
    }

    modifier onlyAdmin(){
        require(adminList[msg.sender], "Controller: Msg sender is not the admin");
        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.9;

interface ILaunchPad{
    // func getProjectInfo
    function projectToLaunchpads(string memory)external  view returns (
        uint256 startTime,
        uint256 endTime,
        uint256 entryPrice,
        uint256 minAllocation,
        uint256 maxAllocation,
        uint256 initialPrice,
        address depositFundAddress,
        uint256 hardcap,
        uint256 totalDeposited,
        address depositCurrency);
    function projectDeposits(string memory,address) external view returns(
        uint256 depositedTime,
        uint256 depositedAmount,
        uint256 claimableAmount
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;



interface IRefunder{

    function userRefundedAmountsUSD(address,string memory) external view returns(uint256);
    function userRefundedAmountsToken(address,string memory) external view returns(uint256);
    function ProjectRefundedTotal(string memory) external view returns(uint256);
    
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;



interface IVesting{
    function allocations(string memory, address) external view returns(uint256 allocated, uint256 claimed);
    function allocate(string memory _pool_id, address wallet,uint256 amount)external;
    function projectClaimedTotal(string memory) external view returns(uint256);
    function projectClaimedTotalByUser(string memory,address) external view returns(uint256);
}