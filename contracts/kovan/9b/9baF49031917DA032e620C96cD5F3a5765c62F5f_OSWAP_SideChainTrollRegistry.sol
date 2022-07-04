/**
 *Submitted for verification at Etherscan.io on 2022-07-04
*/

// SPDX-License-Identifier: GPL-3.0-only

// Sources flattened with hardhat v2.9.9 https://hardhat.org

// File @openzeppelin/contracts/token/ERC20/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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
}


// File @openzeppelin/contracts/token/ERC20/extensions/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}




pragma solidity 0.8.6;

interface IAuthorization {
    function owner() external view returns (address owner);
    function newOwner() external view returns (address newOwner);

    function isPermitted(address) external view returns (bool isPermitted);

    event Authorize(address user);
    event Deauthorize(address user);
    event StartOwnershipTransfer(address user);
    event TransferOwnership(address user);

    function transferOwnership(address newOwner_) external;
    function takeOwnership() external;
    function permit(address user) external;
    function deny(address user) external;
}




pragma solidity 0.8.6;
interface IOSWAP_VotingExecutorManager {
    function govToken() external view returns (IERC20 govToken);
    function votingExecutor(uint256 index) external view returns (address);
    function votingExecutorInv(address) external view returns (uint256 votingExecutorInv);
    function isVotingExecutor(address) external view returns (bool isVotingExecutor);
    function trollRegistry() external view returns (address trollRegistry);
    function newVotingExecutorManager() external view returns (IOSWAP_VotingExecutorManager newVotingExecutorManager);

    function votingExecutorLength() external view returns (uint256);
    function setVotingExecutor(address _votingExecutor, bool _bool) external;
}




pragma solidity >= 0.8.6;


interface IOSWAP_SwapPolicy {

    function allowToSwap(IOSWAP_BridgeVault.Order calldata order) external view returns (bool isAllow);
}




pragma solidity 0.8.6;
interface IOSWAP_ConfigStore is IAuthorization {

    event ParamSet1(bytes32 indexed name, bytes32 value1);
    event ParamSet2(bytes32 indexed name, bytes32 value1, bytes32 value2);
    event UpdateVotingExecutorManager(IOSWAP_VotingExecutorManager newVotingExecutorManager);
    event Upgrade(IOSWAP_ConfigStore newConfigStore);

    function govToken() external view returns (IERC20 govToken);
    function votingExecutorManager() external view returns (IOSWAP_VotingExecutorManager votingExecutorManager);
    function swapPolicy() external view returns (IOSWAP_SwapPolicy swapPolicy);

    function priceOracle(IERC20 token) external view returns (address priceOracle); // priceOracle[token] = oracle
    function baseFee(IERC20 asset) external view returns (uint256 baseFee);
    function isApprovedProxy(address proxy) external view returns (bool isApprovedProxy);
    function lpWithdrawlDelay() external view returns (uint256 lpWithdrawlDelay);
    function transactionsGap() external view returns (uint256 transactionsGap); // side chain
    function superTrollMinCount() external view returns (uint256 superTrollMinCount); // side chain
    function generalTrollMinCount() external view returns (uint256 generalTrollMinCount); // side chain
    function transactionFee() external view returns (uint256 transactionFee);
    function router() external view returns (address router);
    function rebalancer() external view returns (address rebalancer);
    function newConfigStore() external view returns (IOSWAP_ConfigStore newConfigStore);
    function feeTo() external view returns (address feeTo);
    struct Params {
        IOSWAP_VotingExecutorManager votingExecutorManager;
        IOSWAP_SwapPolicy swapPolicy;
        uint256 lpWithdrawlDelay;
        uint256 transactionsGap;
        uint256 superTrollMinCount;
        uint256 generalTrollMinCount;
        uint256 minStakePeriod;
        uint256 transactionFee;
        address router;
        address rebalancer;
        address wrapper;
        IERC20[] asset;
        uint256[] baseFee;
    }

    function initAddress(IOSWAP_VotingExecutorManager _votingExecutorManager) external;
    function upgrade(IOSWAP_ConfigStore _configStore) external;
    function updateVotingExecutorManager() external;
    function setMinStakePeriod(uint256 _minStakePeriod) external;
    function setConfigAddress(bytes32 name, bytes32 _value) external;
    function setConfig(bytes32 name, bytes32 _value) external;
    function setConfig2(bytes32 name, bytes32 value1, bytes32 value2) external;
    function setOracle(IERC20 asset, address oracle) external;
    function setSwapPolicy(IOSWAP_SwapPolicy _swapPolicy) external;
    function getSignatureVerificationParams() external view returns (uint256,uint256,uint256);
    function getBridgeParams(IERC20 asset) external view returns (IOSWAP_SwapPolicy,address,address,address,uint256,uint256);
    function getRebalanceParams(IERC20 asset) external view returns (address rebalancer, address govTokenOracle, address assetTokenOracle);
}




pragma solidity 0.8.6;
interface IOSWAP_SideChainTrollRegistry is IAuthorization, IOSWAP_VotingExecutorManager {

    event Shutdown(address indexed account);
    event Resume();

    event AddTroll(address indexed troll, uint256 indexed trollProfileIndex, bool isSuperTroll);
    event UpdateTroll(uint256 indexed trollProfileIndex, address indexed troll);
    event RemoveTroll(uint256 indexed trollProfileIndex);
    event DelistTroll(uint256 indexed trollProfileIndex);
    event LockSuperTroll(uint256 indexed trollProfileIndex, address lockedBy);
    event LockGeneralTroll(uint256 indexed trollProfileIndex, address lockedBy);
    event UnlockSuperTroll(uint256 indexed trollProfileIndex, bool unlock, address bridgeVault, uint256 penalty);
    event UnlockGeneralTroll(uint256 indexed trollProfileIndex);
    event UpdateConfigStore(IOSWAP_ConfigStore newConfigStore);
    event NewVault(IERC20 indexed token, IOSWAP_BridgeVault indexed vault);
    event SetVotingExecutor(address newVotingExecutor, bool isActive);
    event Upgrade(address newTrollRegistry);

    enum TrollType {NotSpecified, SuperTroll, GeneralTroll, BlockedSuperTroll, BlockedGeneralTroll}

    struct TrollProfile {
        address troll;
        TrollType trollType;
    }
    // function govToken() external view returns (IERC20 govToken);
    function configStore() external view returns (IOSWAP_ConfigStore configStore);
    // function votingExecutor(uint256 index) external view returns (address);
    // function votingExecutorInv(address) external view returns (uint256 votingExecutorInv);
    // function isVotingExecutor(address) external view returns (bool isVotingExecutor);
    function trollProfiles(uint256 trollProfileIndex) external view returns (TrollProfile memory trollProfiles); // trollProfiles[trollProfileIndex] = {troll, trollType}
    function trollProfileInv(address troll) external view returns (uint256 trollProfileInv); // trollProfileInv[troll] = trollProfileIndex
    function superTrollCount() external view returns (uint256 superTrollCount);
    function generalTrollCount() external view returns (uint256 generalTrollCount);
    function transactionsCount() external view returns (uint256 transactionsCount);
    function lastTrollTxCount(address troll) external view returns (uint256 lastTrollTxCount); // lastTrollTxCount[troll]
    function usedNonce(uint256) external view returns (bool usedNonce);

    function vaultToken(uint256 index) external view returns (IERC20);
    function vaults(IERC20) external view returns (IOSWAP_BridgeVault vaults); // vaultRegistries[token] = vault

    function newTrollRegistry() external view returns (address newTrollRegistry);

    function initAddress(address _votingExecutor, IERC20[] calldata tokens, IOSWAP_BridgeVault[] calldata _vaults) external;

    /*
     * upgrade
     */
    function updateConfigStore() external;
    function upgrade(address _trollRegistry) external;
    function upgradeByAdmin(address _trollRegistry) external;

    /*
     * pause / resume
     */
    function paused() external view returns (bool);
    function shutdownByAdmin() external;
    function shutdownByVoting() external;
    function resume() external;

    // function votingExecutorLength() external view returns (uint256);
    // function setVotingExecutor(address _votingExecutor, bool _bool) external;

    function vaultTokenLength() external view returns (uint256);
    function allVaultToken() external view returns (IERC20[] memory);

    function isSuperTroll(address troll, bool returnFalseIfBlocked) external view returns (bool);
    function isSuperTrollByIndex(uint256 trollProfileIndex, bool returnFalseIfBlocked) external view returns (bool);
    function isGeneralTroll(address troll, bool returnFalseIfBlocked) external view returns (bool);
    function isGeneralTrollByIndex(uint256 trollProfileIndex, bool returnFalseIfBlocked) external view returns (bool);

    function verifySignatures(address msgSender, bytes[] calldata signatures, bytes32 paramsHash, uint256 _nonce) external;
    function hashAddTroll(uint256 trollProfileIndex, address troll, bool _isSuperTroll, uint256 _nonce) external view returns (bytes32);
    function hashUpdateTroll(uint256 trollProfileIndex, address newTroll, uint256 _nonce) external view returns (bytes32);
    function hashRemoveTroll(uint256 trollProfileIndex, uint256 _nonce) external view returns (bytes32);
    function hashUnlockTroll(uint256 trollProfileIndex, bool unlock, address[] memory vaultRegistry, uint256[] memory penalty, uint256 _nonce) external view returns (bytes32);
    function hashRegisterVault(IERC20 token, IOSWAP_BridgeVault vaultRegistry, uint256 _nonce) external view returns (bytes32);

    function addTroll(bytes[] calldata signatures, uint256 trollProfileIndex, address troll, bool _isSuperTroll, uint256 _nonce) external;
    function updateTroll(bytes[] calldata signatures, uint256 trollProfileIndex, address newTroll, uint256 _nonce) external;
    function removeTroll(bytes[] calldata signatures, uint256 trollProfileIndex, uint256 _nonce) external;

    function lockSuperTroll(uint256 trollProfileIndex) external;
    function unlockSuperTroll(bytes[] calldata signatures, uint256 trollProfileIndex, bool unlock, address[] calldata vaultRegistry, uint256[] calldata penalty, uint256 _nonce) external;
    function lockGeneralTroll(uint256 trollProfileIndex) external;
    function unlockGeneralTroll(bytes[] calldata signatures, uint256 trollProfileIndex, uint256 _nonce) external;

    function registerVault(bytes[] calldata signatures, IERC20 token, IOSWAP_BridgeVault vault, uint256 _nonce) external;
}




pragma solidity 0.8.6;
interface IOSWAP_BridgeVaultTrollRegistry {

    event Stake(address indexed backer, uint256 indexed trollProfileIndex, uint256 amount, uint256 shares, uint256 backerBalance, uint256 trollBalance, uint256 totalShares);
    event UnstakeRequest(address indexed backer, uint256 indexed trollProfileIndex, uint256 shares, uint256 backerBalance);
    event Unstake(address indexed backer, uint256 indexed trollProfileIndex, uint256 amount, uint256 shares, uint256 approvalDecrement, uint256 trollBalance, uint256 totalShares);
    event UnstakeApproval(address indexed backer, address indexed msgSender, uint256[] signers, uint256 shares);
    event UpdateConfigStore(IOSWAP_ConfigStore newConfigStore);
    event UpdateTrollRegistry(IOSWAP_SideChainTrollRegistry newTrollRegistry);
    event Penalty(uint256 indexed trollProfileIndex, uint256 amount);

    struct Stakes{
        uint256 trollProfileIndex;
        uint256 shares;
        uint256 pendingWithdrawal;
        uint256 approvedWithdrawal;
    }
    // struct StakedBy{
    //     address backer;
    //     uint256 index;
    // }
    function govToken() external view returns (IERC20 govToken);
    function configStore() external view returns (IOSWAP_ConfigStore configStore);
    function trollRegistry() external view returns (IOSWAP_SideChainTrollRegistry trollRegistry);
    function backerStakes(address backer) external view returns (Stakes memory backerStakes); // backerStakes[bakcer] = Stakes;
    function stakedBy(uint256 trollProfileIndex, uint256 index) external view returns (address stakedBy); // stakedBy[trollProfileIndex][idx] = backer;
    function stakedByInv(uint256 trollProfileIndex, address backer) external view returns (uint256 stakedByInv); // stakedByInv[trollProfileIndex][backer] = stakedBy_idx;
    function trollStakesBalances(uint256 trollProfileIndex) external view returns (uint256 trollStakesBalances); // trollStakesBalances[trollProfileIndex] = balance
    function trollStakesTotalShares(uint256 trollProfileIndex) external view returns (uint256 trollStakesTotalShares); // trollStakesTotalShares[trollProfileIndex] = shares
    function transactionsCount() external view returns (uint256 transactionsCount);
    function lastTrollTxCount(address troll) external view returns (uint256 lastTrollTxCount); // lastTrollTxCount[troll]
    function usedNonce(bytes32 nonce) external view returns (bool used);

    function updateConfigStore() external;
    function updateTrollRegistry() external;

    function getBackers(uint256 trollProfileIndex) external view returns (address[] memory backers);
    function stakedByLength(uint256 trollProfileIndex) external view returns (uint256 length);

    function stake(uint256 trollProfileIndex, uint256 amount) external returns (uint256 shares);

    function maxWithdrawal(address backer) external view returns (uint256 amount);
    function hashUnstakeRequest(address backer, uint256 trollProfileIndex, uint256 shares, uint256 _nonce) external view returns (bytes32 hash);
    function unstakeRequest(uint256 shares) external;
    function unstakeApprove(bytes[] calldata signatures, address backer, uint256 trollProfileIndex, uint256 shares, uint256 _nonce) external;
    function unstake(address backer, uint256 shares) external;

    function verifyStakedValue(address msgSender, bytes[] calldata signatures, bytes32 paramsHash) external returns (uint256 superTrollCount, uint totalStake, uint256[] memory signers);

    function penalizeSuperTroll(uint256 trollProfileIndex, uint256 amount) external;
}




pragma solidity 0.8.6;
interface IOSWAP_BridgeVault is IERC20, IERC20Metadata {

    event AddLiquidity(address indexed provider, uint256 amount, uint256 mintAmount, uint256 newBalance, uint256 newLpAssetBalance);
    event RemoveLiquidityRequest(address indexed provider, uint256 amount, uint256 burnAmount, uint256 newBalance, uint256 newLpAssetBalance, uint256 newPendingWithdrawal);
    event RemoveLiquidity(address indexed provider, uint256 amount, uint256 newPendingWithdrawal);
    event NewOrder(uint256 indexed orderId, address indexed owner, Order order, int256 newImbalance);
    event WithdrawUnexecutedOrder(address indexed owner, uint256 orderId, int256 newImbalance);
    event AmendOrderRequest(uint256 indexed orderId, uint256 indexed amendment, Order order);
    event RequestCancelOrder(address indexed owner, uint256 indexed sourceChainId, uint256 indexed orderId, bytes32 hashedOrderId);
    event OrderCanceled(uint256 indexed orderId, address indexed sender, uint256[] signers, bool canceledByOrderOwner, int256 newImbalance, uint256 newProtocolFeeBalance);
    event Swap(uint256 indexed orderId, address indexed sender, uint256[] signers, address owner, uint256 amendment, Order order, uint256 outAmount, int256 newImbalance, uint256 newLpAssetBalance, uint256 newProtocolFeeBalance);
    event VoidOrder(bytes32 indexed orderId, address indexed sender, uint256[] signers);
    event UpdateConfigStore(IOSWAP_ConfigStore newConfigStore);
    event UpdateTrollRegistry(IOSWAP_SideChainTrollRegistry newTrollRegistry);
    event Rebalance(address rebalancer, int256 amount, int256 newImbalance);
    event WithdrawlTrollFee(address feeTo, uint256 amount, uint256 newProtocolFeeBalance);
    event Sync(uint256 excess, uint256 newProtocolFeeBalance);

    // pending must be the init status which have value of 0
    enum OrderStatus{NotSpecified, Pending, Executed, RequestCancel, RefundApproved, Cancelled, RequestAmend}

    function trollRegistry() external view returns (IOSWAP_SideChainTrollRegistry trollRegistry);
    function govToken() external view returns (IERC20 govToken);
    function asset() external view returns (IERC20 asset);
    function assetDecimalsScale() external view returns (int8 assetDecimalsScale);
    function configStore() external view returns (IOSWAP_ConfigStore configStore);
    function vaultRegistry() external view returns (IOSWAP_BridgeVaultTrollRegistry vaultRegistry);
    function imbalance() external view returns (int256 imbalance);
    function lpAssetBalance() external view returns (uint256 lpAssetBalance);
    function totalPendingWithdrawal() external view returns (uint256 totalPendingWithdrawal);
    function protocolFeeBalance() external view returns (uint256 protocolFeeBalance);
    function pendingWithdrawalAmount(address liquidityProvider) external view returns (uint256 pendingWithdrawalAmount);
    function pendingWithdrawalTimeout(address liquidityProvider) external view returns (uint256 pendingWithdrawalTimeout);

    // source chain
    struct Order {
        uint256 peerChain;
        uint256 inAmount;
        address outToken;
        uint256 minOutAmount;
        address to;
        uint256 expire;
    }
    // source chain
    function orders(uint256 orderId) external view returns (uint256 peerChain, uint256 inAmount, address outToken, uint256 minOutAmount, address to, uint256 expire);
    function orderAmendments(uint256 orderId, uint256 amendment) external view returns (uint256 peerChain, uint256 inAmount, address outToken, uint256 minOutAmount, address to, uint256 expire);
    function orderOwner(uint256 orderId) external view returns (address orderOwner);
    function orderStatus(uint256 orderId) external view returns (OrderStatus orderStatus);
    function orderRefunds(uint256 orderId) external view returns (uint256 orderRefunds);
    // target chain
    function swapOrderStatus(bytes32 orderHash) external view returns (OrderStatus swapOrderStatus);

    function initAddress(IOSWAP_BridgeVaultTrollRegistry _vaultRegistry) external;
    function updateConfigStore() external;
    function updateTrollRegistry() external;
    function ordersLength() external view returns (uint256 length);
    function orderAmendmentsLength(uint256 orderId) external view returns (uint256 length);

    function getOrders(uint256 start, uint256 length) external view returns (Order[] memory list);

    function lastKnownBalance() external view returns (uint256 balance);

    /*
     * signatures related functions
     */
    function getChainId() external view returns (uint256 chainId);
    function hashCancelOrderParams(uint256 orderId, bool canceledByOrderOwner, uint256 protocolFee) external view returns (bytes32);
    function hashVoidOrderParams(bytes32 orderId) external view returns (bytes32);
    function hashSwapParams(
        bytes32 orderId,
        uint256 amendment,
        Order calldata order,
        uint256 protocolFee,
        address[] calldata pair
    ) external view returns (bytes32);
    function hashWithdrawParams(address _owner, uint256 amount, uint256 _nonce) external view returns (bytes32);
    function hashOrder(address _owner, uint256 sourceChainId, uint256 orderId) external view returns (bytes32);

    /*
     * functions called by LP
     */
    function addLiquidity(uint256 amount) external;
    function removeLiquidityRequest(uint256 lpTokenAmount) external;
    function removeLiquidity(address provider, uint256 assetAmount) external;

    /*
     *  functions called by traders on source chain
     */
    function newOrder(Order memory order) external returns (uint256 orderId);
    function withdrawUnexecutedOrder(uint256 orderId) external;
    function requestAmendOrder(uint256 orderId, Order calldata order) external;

    /*
     *  functions called by traders on target chain
     */
    function requestCancelOrder(uint256 sourceChainId, uint256 orderId) external;

    /*
     * troll helper functions
     */
    function assetPriceAgainstGovToken(address govTokenOracle, address assetTokenOracle) external view returns (uint256 price);

    /*
     *  functions called by trolls on source chain
     */
    function cancelOrder(bytes[] calldata signatures, uint256 orderId, bool canceledByOrderOwner, uint256 protocolFee) external;

    /*
     *  functions called by trolls on target chain
     */
    function swap(
        bytes[] calldata signatures,
        address _owner,
        uint256 _orderId,
        uint256 amendment,
        uint256 protocolFee,
        address[] calldata pair,
        Order calldata order
    ) external returns (uint256 amount);
    function voidOrder(bytes[] calldata signatures, bytes32 orderId) external;

    function newOrderFromRouter(Order calldata order, address trader) external returns (uint256 orderId);

    /*
     * rebalancing
     */
    function rebalancerDeposit(uint256 assetAmount) external;
    function rebalancerWithdraw(bytes[] calldata signatures, uint256 assetAmount, uint256 _nonce) external;

    /*
     * anyone can call
     */
    function withdrawlTrollFee(uint256 amount) external;
    function sync() external;
}


// File @openzeppelin/contracts/security/[email protected]



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
     * by making the `nonReentrant` function external, and make it call a
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


// File @openzeppelin/contracts/utils/[email protected]



pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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


// File @openzeppelin/contracts/token/ERC20/utils/[email protected]



pragma solidity ^0.8.0;


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


// File @openzeppelin/contracts/utils/cryptography/[email protected]



pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}




pragma solidity 0.8.6;

contract Authorization {
    address public owner;
    address public newOwner;
    mapping(address => bool) public isPermitted;
    event Authorize(address user);
    event Deauthorize(address user);
    event StartOwnershipTransfer(address user);
    event TransferOwnership(address user);
    constructor() {
        owner = msg.sender;
    }
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier auth {
        require(isPermitted[msg.sender], "Action performed by unauthorized address.");
        _;
    }
    function transferOwnership(address newOwner_) external onlyOwner {
        newOwner = newOwner_;
        emit StartOwnershipTransfer(newOwner_);
    }
    function takeOwnership() external {
        require(msg.sender == newOwner, "Action performed by unauthorized address.");
        owner = newOwner;
        newOwner = address(0x0000000000000000000000000000000000000000);
        emit TransferOwnership(owner);
    }
    function permit(address user) external onlyOwner {
        isPermitted[user] = true;
        emit Authorize(user);
    }
    function deny(address user) external onlyOwner {
        isPermitted[user] = false;
        emit Deauthorize(user);
    }
}




pragma solidity 0.8.6;
contract OSWAP_ConfigStore is Authorization {

    modifier onlyVoting() {
        require(votingExecutorManager.isVotingExecutor(msg.sender), "OSWAP: Not from voting");
        _;
    }

    event ParamSet1(bytes32 indexed name, bytes32 value1);
    event ParamSet2(bytes32 indexed name, bytes32 value1, bytes32 value2);
    event UpdateVotingExecutorManager(IOSWAP_VotingExecutorManager newVotingExecutorManager);
    event Upgrade(OSWAP_ConfigStore newConfigStore);

    IERC20 public immutable govToken;
    IOSWAP_VotingExecutorManager public votingExecutorManager;
    IOSWAP_SwapPolicy public swapPolicy;

    // side chain
    mapping(IERC20 => address) public priceOracle; // priceOracle[token] = oracle
    mapping(IERC20 => uint256) public baseFee;
    mapping(address => bool) public isApprovedProxy;
    uint256 public lpWithdrawlDelay;
    uint256 public transactionsGap;
    uint256 public superTrollMinCount;
    uint256 public generalTrollMinCount;
    uint256 public transactionFee;
    address public router;
    address public rebalancer;
    address public feeTo;

    OSWAP_ConfigStore public newConfigStore;

    struct Params {
        IERC20 govToken;
        IOSWAP_SwapPolicy swapPolicy;
        uint256 lpWithdrawlDelay;
        uint256 transactionsGap;
        uint256 superTrollMinCount;
        uint256 generalTrollMinCount;
        uint256 transactionFee;
        address router;
        address rebalancer;
        address feeTo;
        address wrapper;
        IERC20[] asset;
        uint256[] baseFee;
    }
    constructor(
        Params memory params
    ) {
        govToken = params.govToken;
        swapPolicy = params.swapPolicy;
        lpWithdrawlDelay = params.lpWithdrawlDelay;
        transactionsGap = params.transactionsGap;
        superTrollMinCount = params.superTrollMinCount;
        generalTrollMinCount = params.generalTrollMinCount;
        transactionFee = params.transactionFee;
        router = params.router;
        rebalancer = params.rebalancer;
        feeTo = params.feeTo;
        require(params.asset.length == params.baseFee.length);
        for (uint256 i ; i < params.asset.length ; i++){
            baseFee[params.asset[i]] = params.baseFee[i];
        }
        if (params.wrapper != address(0))
            isApprovedProxy[params.wrapper] = true;
        isPermitted[msg.sender] = true;
    }
    function initAddress(IOSWAP_VotingExecutorManager _votingExecutorManager) external onlyOwner {
        require(address(_votingExecutorManager) != address(0), "null address");
        require(address(votingExecutorManager) == address(0), "already init");
        votingExecutorManager = _votingExecutorManager;
    }

    function upgrade(OSWAP_ConfigStore _configStore) external onlyVoting {
        // require(address(_configStore) != address(0), "already set");
        newConfigStore = _configStore;
        emit Upgrade(newConfigStore);
    }
    function updateVotingExecutorManager() external {
        IOSWAP_VotingExecutorManager _votingExecutorManager = votingExecutorManager.newVotingExecutorManager();
        require(address(_votingExecutorManager) != address(0), "Invalid config store");
        votingExecutorManager = _votingExecutorManager;
        emit UpdateVotingExecutorManager(votingExecutorManager);
    }

    // side chain
    function setConfigAddress(bytes32 name, bytes32 _value) external onlyVoting {
        address value = address(bytes20(_value));

        if (name == "router") {
            router = value;
        } else if (name == "rebalancer") {
            rebalancer = value;
        } else if (name == "feeTo") {
            feeTo = value;
        } else {
            revert("Invalid config");
        }
        emit ParamSet1(name, _value);
    }
    function setConfig(bytes32 name, bytes32 _value) external onlyVoting {
        uint256 value = uint256(_value);
        if (name == "transactionsGap") {
            transactionsGap = value;
        } else if (name == "transactionFee") {
            transactionFee = value;
        } else if (name == "superTrollMinCount") {
            superTrollMinCount = value;
        } else if (name == "generalTrollMinCount") {
            generalTrollMinCount = value;
        } else if (name == "lpWithdrawlDelay") {
            lpWithdrawlDelay = value;
        } else {
            revert("Invalid config");
        }
        emit ParamSet1(name, _value);
    }
    function setConfig2(bytes32 name, bytes32 value1, bytes32 value2) external onlyVoting {
        if (name == "baseFee") {
            baseFee[IERC20(address(bytes20(value1)))] = uint256(value2);
        } else if (name == "isApprovedProxy") {
            isApprovedProxy[address(bytes20(value1))] = uint256(value2)==1;
        } else {
            revert("Invalid config");
        }
        emit ParamSet2(name, value1, value2);
    }
    function setOracle(IERC20 asset, address oracle) external auth {
        priceOracle[asset] = oracle;
        emit ParamSet2("oracle", bytes20(address(asset)), bytes20(oracle));
    }
    function setSwapPolicy(IOSWAP_SwapPolicy _swapPolicy) external auth {
        swapPolicy = _swapPolicy;
        emit ParamSet1("swapPolicy", bytes32(bytes20(address(_swapPolicy))));
    }
    function getSignatureVerificationParams() external view returns (uint256,uint256,uint256) {
        return (generalTrollMinCount, superTrollMinCount, transactionsGap);
    }
    function getBridgeParams(IERC20 asset) external view returns (IOSWAP_SwapPolicy,address,address,address,uint256,uint256) {
        return (swapPolicy, router, priceOracle[govToken], priceOracle[asset], baseFee[asset], transactionFee);
    }
    function getRebalanceParams(IERC20 asset) external view returns (address,address,address) {
        return (rebalancer, priceOracle[govToken], priceOracle[asset]);
    }
}




pragma solidity 0.8.6;
contract OSWAP_BridgeVaultTrollRegistry is ReentrancyGuard {
    using SafeERC20 for IERC20;
    using ECDSA for bytes32;


    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier whenNotPaused() {
        require(!trollRegistry.paused(), "PAUSED!");
        _;
    }

    event Stake(address indexed backer, uint256 indexed trollProfileIndex, uint256 amount, uint256 shares, uint256 backerBalance, uint256 trollBalance, uint256 totalShares);
    event UnstakeRequest(address indexed backer, uint256 indexed trollProfileIndex, uint256 shares, uint256 backerBalance);
    event Unstake(address indexed backer, uint256 indexed trollProfileIndex, uint256 amount, uint256 shares, uint256 approvalDecrement, uint256 trollBalance, uint256 totalShares);
    event UnstakeApproval(address indexed backer, address indexed msgSender, uint256[] signers, uint256 shares);
    event UpdateConfigStore(OSWAP_ConfigStore newConfigStore);
    event UpdateTrollRegistry(OSWAP_SideChainTrollRegistry newTrollRegistry);
    event Penalty(uint256 indexed trollProfileIndex, uint256 amount);

    struct Stakes{
        uint256 trollProfileIndex;
        uint256 shares;
        uint256 pendingWithdrawal;
        uint256 approvedWithdrawal;
    }
    // struct StakedBy{
    //     address backer;
    //     uint256 index;
    // }

    address owner;
    IERC20 public immutable govToken;
    OSWAP_ConfigStore public configStore;
    OSWAP_SideChainTrollRegistry public trollRegistry;
    IOSWAP_BridgeVault public bridgeVault;

    mapping(address => Stakes) public backerStakes; // backerStakes[bakcer] = Stakes;
    mapping(uint256 => address[]) public stakedBy; // stakedBy[trollProfileIndex][idx] = backer;
    mapping(uint256 => mapping(address => uint256)) public stakedByInv; // stakedByInv[trollProfileIndex][backer] = stakedBy_idx;

    mapping(uint256 => uint256) public trollStakesBalances; // trollStakesBalances[trollProfileIndex] = balance
    mapping(uint256 => uint256) public trollStakesTotalShares; // trollStakesTotalShares[trollProfileIndex] = shares


    uint256 public transactionsCount;
    mapping(address => uint256) public lastTrollTxCount; // lastTrollTxCount[troll]
    mapping(bytes32 => bool) public usedNonce;

    constructor(OSWAP_SideChainTrollRegistry _trollRegistry) {
        trollRegistry = _trollRegistry;
        configStore = _trollRegistry.configStore();
        govToken = _trollRegistry.govToken();
        owner = msg.sender;
    }
    function initAddress(IOSWAP_BridgeVault _bridgeVault) external onlyOwner {
        require(address(bridgeVault) == address(0), "address already set");
        bridgeVault = _bridgeVault;
    }
    function updateConfigStore() external {
        OSWAP_ConfigStore _configStore = configStore.newConfigStore();
        require(address(_configStore) != address(0), "Invalid config store");
        configStore = _configStore;
        emit UpdateConfigStore(configStore);
    }
    function updateTrollRegistry() external {
        OSWAP_SideChainTrollRegistry _trollRegistry = OSWAP_SideChainTrollRegistry(trollRegistry.newTrollRegistry());
        require(address(_trollRegistry) != address(0), "Invalid config store");
        trollRegistry = _trollRegistry;
        emit UpdateTrollRegistry(trollRegistry);
    }

    function stakedByLength(uint256 trollProfileIndex) external view returns (uint256 length) {
        length = stakedBy[trollProfileIndex].length;
    }
    function getBackers(uint256 trollProfileIndex) external view returns (address[] memory backers) {
        return stakedBy[trollProfileIndex];
    }

    function removeStakedBy(uint256 _index) internal {
        uint idx = stakedByInv[_index][msg.sender];
        uint256 lastIdx = stakedBy[_index].length - 1;
        if (idx != lastIdx){
            stakedBy[_index][idx] = stakedBy[_index][lastIdx];
            stakedByInv[_index][ stakedBy[_index][idx] ] = idx;
        }
        stakedBy[_index].pop();
        delete stakedByInv[_index][msg.sender];
    }

    function stake(uint256 trollProfileIndex, uint256 amount) external nonReentrant whenNotPaused returns (uint256 shares){
        (,OSWAP_SideChainTrollRegistry.TrollType trollType) = trollRegistry.trollProfiles(trollProfileIndex);
        // OSWAP_SideChainTrollRegistry.TrollProfile memory profile = trollRegistry.trollProfiles(trollProfileIndex);
        require(trollType == OSWAP_SideChainTrollRegistry.TrollType.SuperTroll, "Not a Super Troll");

        if (amount > 0) {
            uint256 balance = govToken.balanceOf(address(this));
            govToken.safeTransferFrom(msg.sender, address(this), amount);
            amount = govToken.balanceOf(address(this)) - balance;
        }

        Stakes storage staking = backerStakes[msg.sender];
        if (staking.shares > 0) {
            if (staking.trollProfileIndex != trollProfileIndex) {
                require(staking.pendingWithdrawal == 0 && staking.approvedWithdrawal == 0, "you have pending withdrawal");
                // existing staking found, remvoe stakes from old troll and found the latest stakes amount after penalties
                uint256 _index = staking.trollProfileIndex;
                uint256 stakedAmount = staking.shares * trollStakesBalances[_index] / trollStakesTotalShares[_index];
                trollStakesBalances[_index] -= stakedAmount;
                trollStakesTotalShares[_index] -= staking.shares;
                amount += stakedAmount;

                removeStakedBy(_index);

                emit UnstakeRequest(msg.sender, _index, staking.shares, 0);
                emit Unstake(msg.sender, _index, stakedAmount, staking.shares, 0, trollStakesBalances[_index], trollStakesTotalShares[_index]);

                stakedByInv[trollProfileIndex][msg.sender] = stakedBy[trollProfileIndex].length;
                stakedBy[trollProfileIndex].push(msg.sender);

                staking.trollProfileIndex = trollProfileIndex;
                staking.shares = 0;
            }
        } else {
            // new staking
            staking.trollProfileIndex = trollProfileIndex;
            stakedByInv[trollProfileIndex][msg.sender] = stakedBy[trollProfileIndex].length;
            stakedBy[trollProfileIndex].push(msg.sender);
        }

        uint256 trollActualBalance = trollStakesBalances[trollProfileIndex];
        shares = trollActualBalance == 0 ? amount : (amount * trollStakesTotalShares[trollProfileIndex] / trollActualBalance);
        require(shares > 0, "amount too small");
        trollStakesTotalShares[trollProfileIndex] += shares;
        trollStakesBalances[trollProfileIndex] += amount;
        staking.shares += shares;

        emit Stake(msg.sender, trollProfileIndex, amount, shares, staking.shares, trollStakesBalances[trollProfileIndex], trollStakesTotalShares[trollProfileIndex]);

    }
    function maxWithdrawal(address backer) external view returns (uint256 amount) {
        Stakes storage staking = backerStakes[backer];
        uint256 trollProfileIndex = staking.trollProfileIndex;
        amount = staking.shares * (trollStakesBalances[trollProfileIndex]) / trollStakesTotalShares[trollProfileIndex];
    }

    function hashUnstakeRequest(address backer, uint256 trollProfileIndex, uint256 shares, uint256 _nonce) public view returns (bytes32 hash) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return keccak256(abi.encodePacked(
            chainId,
            address(this),
            backer,
            trollProfileIndex,
            shares,
            _nonce
        ));
    }
    function unstakeRequest(uint256 shares) external whenNotPaused {
        Stakes storage staking = backerStakes[msg.sender];
        uint256 trollProfileIndex = staking.trollProfileIndex;
        require(trollProfileIndex != 0, "not a backer");
        staking.shares -= shares;
        staking.pendingWithdrawal += shares;

        if (staking.shares == 0){
            removeStakedBy(trollProfileIndex);
        }

        emit UnstakeRequest(msg.sender, trollProfileIndex, shares, staking.shares);
    }
    function unstakeApprove(bytes[] calldata signatures, address backer, uint256 trollProfileIndex, uint256 shares, uint256 _nonce) external {
        Stakes storage staking = backerStakes[backer];
        require(trollProfileIndex == staking.trollProfileIndex, "invalid trollProfileIndex");
        require(shares <= staking.pendingWithdrawal, "Invalid shares amount");
        (,, uint256[] memory signers) = _verifyStakedValue(msg.sender, signatures, hashUnstakeRequest(backer, trollProfileIndex, shares, _nonce));
        staking.approvedWithdrawal += shares;
        emit UnstakeApproval(backer, msg.sender, signers, shares);
    }
    function unstake(address backer, uint256 shares) external nonReentrant whenNotPaused {
        Stakes storage staking = backerStakes[backer];
        require(shares <= staking.approvedWithdrawal, "amount exceeded approval");
        uint256 trollProfileIndex = staking.trollProfileIndex;

        staking.approvedWithdrawal -= shares;
        staking.pendingWithdrawal -= shares;

        uint256 amount = shares * trollStakesBalances[trollProfileIndex] / trollStakesTotalShares[trollProfileIndex];

        trollStakesTotalShares[trollProfileIndex] -= shares;
        trollStakesBalances[trollProfileIndex] -= amount;

        govToken.safeTransfer(backer, amount);

        emit Unstake(backer, trollProfileIndex, amount, shares, shares, trollStakesBalances[trollProfileIndex], trollStakesTotalShares[trollProfileIndex]);
    }

    function verifyStakedValue(address msgSender, bytes[] calldata signatures, bytes32 paramsHash) external returns (uint256 superTrollCount, uint totalStake, uint256[] memory signers) {
        require(msg.sender == address(bridgeVault), "not authorized");
        return _verifyStakedValue(msgSender, signatures, paramsHash);
    }
    function _verifyStakedValue(address msgSender, bytes[] calldata signatures, bytes32 paramsHash) internal returns (uint256 superTrollCount, uint totalStake, uint256[] memory signers) {
        require(!usedNonce[paramsHash], "nonce used");
        usedNonce[paramsHash] = true;

        uint256 generalTrollCount;
        {
        uint256 length = signatures.length;
        signers = new uint256[](length);
        address lastSigningTroll;
        for (uint256 i = 0; i < length; ++i) {
            address troll = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", paramsHash)).recover(signatures[i]);
            require(troll != address(0), "Invalid signer");
            uint256 trollProfileIndex = trollRegistry.trollProfileInv(troll);
            if (trollProfileIndex > 0 && troll > lastSigningTroll) {
                signers[i] = trollProfileIndex;
                if (trollRegistry.isSuperTroll(troll, true)) {
                    superTrollCount++;
                } else if (trollRegistry.isGeneralTroll(troll, true)) {
                    generalTrollCount++;
                }
                totalStake += trollStakesBalances[trollProfileIndex];
                lastSigningTroll = troll;
            }
        }
        }

        (uint256 generalTrollMinCount, uint256 superTrollMinCount, uint256 transactionsGap) = configStore.getSignatureVerificationParams();
        require(generalTrollCount >= generalTrollMinCount, "OSWAP_BridgeVault: Mininum general troll count not met");
        require(superTrollCount >= superTrollMinCount, "OSWAP_BridgeVault: Mininum super troll count not met");

        // fuzzy round robin
        uint256 _transactionsCount = (++transactionsCount);
        require((lastTrollTxCount[msgSender] + transactionsGap < _transactionsCount) || (_transactionsCount <= transactionsGap), "too soon");
        lastTrollTxCount[msgSender] = _transactionsCount;
    }

    function penalizeSuperTroll(uint256 trollProfileIndex, uint256 amount) external {
        require(msg.sender == address(trollRegistry), "not from registry");
        require(amount <= trollStakesBalances[trollProfileIndex], "penalty exceeds troll balance");
        trollStakesBalances[trollProfileIndex] -= amount;
        // if penalty == balance, forfeit all backers' bonds
        if (trollStakesBalances[trollProfileIndex] == 0) {
            delete trollStakesBalances[trollProfileIndex];
            delete trollStakesTotalShares[trollProfileIndex];
            address[] storage backers = stakedBy[trollProfileIndex];
            uint256 length = backers.length;
            for (uint256 i = 0 ; i < length ; i++) {
                address backer = backers[i];
                delete backerStakes[backer];
                delete stakedByInv[trollProfileIndex][backer];
            }
            delete stakedBy[trollProfileIndex];
        }
        emit Penalty(trollProfileIndex, amount);
    }
}



pragma solidity 0.8.6;
contract OSWAP_SideChainTrollRegistry is Authorization {
    using ECDSA for bytes32;

    modifier onlyVoting() {
        require(isVotingExecutor[msg.sender], "OSWAP: Not from voting");
        _;
    }
    modifier whenPaused() {
        require(paused(), "NOT PAUSED!");
        _;
    }
    modifier whenNotPaused() {
        require(!paused(), "PAUSED!");
        _;
    }

    event Shutdown(address indexed account);
    event Resume();

    event AddTroll(address indexed troll, uint256 indexed trollProfileIndex, bool isSuperTroll);
    event UpdateTroll(uint256 indexed trollProfileIndex, address indexed troll);
    event RemoveTroll(uint256 indexed trollProfileIndex);
    event DelistTroll(uint256 indexed trollProfileIndex);
    event LockSuperTroll(uint256 indexed trollProfileIndex, address lockedBy);
    event LockGeneralTroll(uint256 indexed trollProfileIndex, address lockedBy);
    event UnlockSuperTroll(uint256 indexed trollProfileIndex, bool unlock, address bridgeVault, uint256 penalty);
    event UnlockGeneralTroll(uint256 indexed trollProfileIndex);
    event UpdateConfigStore(OSWAP_ConfigStore newConfigStore);
    event NewVault(IERC20 indexed token, IOSWAP_BridgeVault indexed vault);
    event SetVotingExecutor(address newVotingExecutor, bool isActive);
    event Upgrade(address newTrollRegistry);

    enum TrollType {NotSpecified, SuperTroll, GeneralTroll, BlockedSuperTroll, BlockedGeneralTroll}

    struct TrollProfile {
        address troll;
        TrollType trollType;
    }

    bool private _paused;
    IERC20 public immutable govToken;
    OSWAP_ConfigStore public configStore;

    // votingManager
    address[] public votingExecutor;
    mapping (address => uint256) public votingExecutorInv;
    mapping (address => bool) public isVotingExecutor;
    address public immutable trollRegistry = address(this);

    mapping(uint256 => TrollProfile) public trollProfiles; // trollProfiles[trollProfileIndex] = {troll, trollType}
    mapping(address => uint256) public trollProfileInv; // trollProfileInv[troll] = trollProfileIndex

    uint256 public superTrollCount;
    uint256 public generalTrollCount;

    uint256 public transactionsCount;
    mapping(address => uint256) public lastTrollTxCount; // lastTrollTxCount[troll]
    mapping(uint256 => bool) public usedNonce;

    IERC20[] public vaultToken;
    mapping(IERC20 => IOSWAP_BridgeVault) public vaults; // vaultRegistries[token] = vault

    address public newTrollRegistry;
    function newVotingExecutorManager() external view returns (address) { return newTrollRegistry; }

    constructor(OSWAP_ConfigStore _configStore) {
        configStore = _configStore;
        govToken = _configStore.govToken();
        isPermitted[msg.sender] = true;
    }
    function initAddress(address _votingExecutor, IERC20[] calldata tokens, IOSWAP_BridgeVault[] calldata _vaults) external onlyOwner {
        require(address(_votingExecutor) != address(0), "null address");
        _setVotingExecutor(_votingExecutor, true);

        uint256 length = tokens.length;
        require(length == _vaults.length, "array length not matched");
        for (uint256 i ; i < length ; i++) {
            vaultToken.push(tokens[i]);
            vaults[tokens[i]] = _vaults[i];
            emit NewVault(tokens[i], _vaults[i]);
        }

        // renounceOwnership();
    }

    /*
     * upgrade
     */
    function updateConfigStore() external {
        OSWAP_ConfigStore _configStore = configStore.newConfigStore();
        require(address(_configStore) != address(0), "Invalid config store");
        configStore = _configStore;
        emit UpdateConfigStore(configStore);
    }

    function upgrade(address _trollRegistry) external onlyVoting {
        _upgrade(_trollRegistry);
    }
    function upgradeByAdmin(address _trollRegistry) external onlyOwner {
        _upgrade(_trollRegistry);
    }
    function _upgrade(address _trollRegistry) internal {
        // require(address(newTrollRegistry) == address(0), "already set");
        newTrollRegistry = _trollRegistry;
        emit Upgrade(_trollRegistry);
    }

    /*
     * pause / resume
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }
    function shutdownByAdmin() external auth whenNotPaused {
        _paused = true;
        emit Shutdown(msg.sender);
    }
    function shutdownByVoting() external onlyVoting whenNotPaused {
        _paused = true;
        emit Shutdown(msg.sender);
    }
    function resume() external onlyVoting whenPaused {
        _paused = false;
        emit Resume();
    }

    function votingExecutorLength() external view returns (uint256) {
        return votingExecutor.length;
    }
    function setVotingExecutor(address _votingExecutor, bool _bool) external onlyVoting {
        _setVotingExecutor(_votingExecutor, _bool);
    }
    function _setVotingExecutor(address _votingExecutor, bool _bool) internal {
        require(_votingExecutor != address(0), "OSWAP: Invalid executor");

        if (votingExecutor.length==0 || votingExecutor[votingExecutorInv[_votingExecutor]] != _votingExecutor) {
            votingExecutorInv[_votingExecutor] = votingExecutor.length;
            votingExecutor.push(_votingExecutor);
        } else {
            require(votingExecutorInv[_votingExecutor] != 0, "OSWAP: cannot reset main executor");
        }
        isVotingExecutor[_votingExecutor] = _bool;
        emit SetVotingExecutor(_votingExecutor, _bool);
    }

    function vaultTokenLength() external view returns (uint256) {
        return vaultToken.length;
    }
    function allVaultToken() external view returns (IERC20[] memory) {
        return vaultToken;
    }
    function isSuperTroll(address troll, bool returnFalseIfBlocked) public view returns (bool) {
        uint256 index = trollProfileInv[troll];
        return isSuperTrollByIndex(index, returnFalseIfBlocked);
    }
    function isSuperTrollByIndex(uint256 trollProfileIndex, bool returnFalseIfBlocked) public view returns (bool) {
        return trollProfiles[trollProfileIndex].trollType == TrollType.SuperTroll ||
               (trollProfiles[trollProfileIndex].trollType == TrollType.BlockedSuperTroll && !returnFalseIfBlocked);
    }
    function isGeneralTroll(address troll, bool returnFalseIfBlocked) public view returns (bool) {
        uint256 index = trollProfileInv[troll];
        return isGeneralTrollByIndex(index, returnFalseIfBlocked);
    }
    function isGeneralTrollByIndex(uint256 trollProfileIndex, bool returnFalseIfBlocked) public view returns (bool) {
        return trollProfiles[trollProfileIndex].trollType == TrollType.GeneralTroll ||
               (trollProfiles[trollProfileIndex].trollType == TrollType.BlockedGeneralTroll && !returnFalseIfBlocked);
    }

    function verifySignatures(address msgSender, bytes[] calldata signatures, bytes32 paramsHash, uint256 _nonce) external onlyVoting {
        _verifySignatures(msgSender, signatures, paramsHash, _nonce);
    }
    function _verifySignatures(address msgSender, bytes[] calldata signatures, bytes32 paramsHash, uint256 _nonce) internal {
        require(isSuperTroll(msgSender, false) || isPermitted[msgSender], "not from super troll");
        require(!usedNonce[_nonce], "nonce used");
        usedNonce[_nonce] = true;
        uint256 _superTrollCount;
        bool adminSigned;
        address lastSigningTroll;
        for (uint i = 0; i < signatures.length; ++i) {
            address troll = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", paramsHash)).recover(signatures[i]);
            require(troll != address(0), "Invalid signer");
            if (isSuperTroll(troll, false)) {
                if (troll > lastSigningTroll) {
                    _superTrollCount++;
                    lastSigningTroll = troll;
                }
            } else if (isPermitted[troll]) {
                adminSigned = true;
            }
        }

        uint256 transactionsGap = configStore.transactionsGap();

        // fuzzy round robin
        uint256 _transactionsCount = (++transactionsCount);
        if (!adminSigned)
            require((lastTrollTxCount[msgSender] + transactionsGap < _transactionsCount) || (_transactionsCount <= transactionsGap), "too soon");
        lastTrollTxCount[msgSender] = _transactionsCount;

        require(
            (superTrollCount > 0 && _superTrollCount == superTrollCount) || 
            ((_superTrollCount > (superTrollCount+1)/2 && adminSigned) || 
            (superTrollCount == 0 && adminSigned))
        , "OSWAP_TrollRegistry: SuperTroll count not met");
    }
    function hashAddTroll(uint256 trollProfileIndex, address troll, bool _isSuperTroll, uint256 _nonce) public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return keccak256(abi.encodePacked(
            chainId,
            address(this),
            trollProfileIndex,
            troll,
            _isSuperTroll,
            _nonce
        ));
    }
    function hashUpdateTroll(uint256 trollProfileIndex, address newTroll, uint256 _nonce) public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return keccak256(abi.encodePacked(
            chainId,
            address(this),
            trollProfileIndex,
            newTroll,
            _nonce
        ));
    }
    function hashRemoveTroll(uint256 trollProfileIndex, uint256 _nonce) public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return keccak256(abi.encodePacked(
            chainId,
            address(this),
            trollProfileIndex,
            _nonce
        ));
    }
    function hashUnlockTroll(uint256 trollProfileIndex, bool unlock, address[] memory vaultRegistry, uint256[] memory penalty, uint256 _nonce) public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return keccak256(abi.encodePacked(
            chainId,
            address(this),
            trollProfileIndex,
            unlock,
            vaultRegistry,
            penalty,
            _nonce
        ));
    }
    function hashRegisterVault(IERC20 token, IOSWAP_BridgeVault vault, uint256 _nonce) public view returns (bytes32) {
        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        return keccak256(abi.encodePacked(
            chainId,
            address(this),
            token,
            vault,
            _nonce
        ));
    }

    function addTroll(bytes[] calldata signatures, uint256 trollProfileIndex, address troll, bool _isSuperTroll, uint256 _nonce) external {
        bytes32 hash = hashAddTroll(trollProfileIndex, troll, _isSuperTroll, _nonce);
        _verifySignatures(msg.sender, signatures, hash, _nonce);
        require(troll != address(0), "Invalid troll");
        require(trollProfileIndex != 0, "trollProfileIndex cannot be zero");
        require(trollProfiles[trollProfileIndex].trollType == TrollType.NotSpecified, "already added");
        require(trollProfileInv[troll] == 0, "already added");
        trollProfiles[trollProfileIndex] = TrollProfile({troll:troll, trollType:_isSuperTroll ? TrollType.SuperTroll : TrollType.GeneralTroll});
        trollProfileInv[troll] = trollProfileIndex;
        if (trollProfiles[trollProfileIndex].trollType == TrollType.SuperTroll) {
            superTrollCount++;
        } else if (trollProfiles[trollProfileIndex].trollType == TrollType.GeneralTroll) {
            generalTrollCount++;
        } else {
            revert("invalid troll type");
        }
        emit AddTroll(troll, trollProfileIndex, _isSuperTroll);
    }
    function updateTroll(bytes[] calldata signatures, uint256 trollProfileIndex, address newTroll, uint256 _nonce) external {
        bytes32 hash = hashUpdateTroll(trollProfileIndex, newTroll, _nonce);
        _verifySignatures(msg.sender, signatures, hash, _nonce);
        require(newTroll != address(0), "Invalid troll");
        require(trollProfileInv[newTroll] == 0, "newTroll already exists");
        TrollProfile storage troll = trollProfiles[trollProfileIndex];
        require(troll.trollType != TrollType.NotSpecified, "not a valid troll");
        delete trollProfileInv[troll.troll];
        trollProfiles[trollProfileIndex].troll = newTroll;
        trollProfileInv[newTroll] = trollProfileIndex;
        emit UpdateTroll(trollProfileIndex, newTroll);
    }
    function removeTroll(bytes[] calldata signatures, uint256 trollProfileIndex, uint256 _nonce) external {
        bytes32 hash = hashRemoveTroll(trollProfileIndex, _nonce);
        _verifySignatures(msg.sender, signatures, hash, _nonce);
        TrollProfile storage troll = trollProfiles[trollProfileIndex];
        require(troll.trollType != TrollType.NotSpecified, "not a valid troll");
        emit RemoveTroll(trollProfileIndex);

        TrollType trollType = trollProfiles[trollProfileIndex].trollType;
        if (trollType == TrollType.SuperTroll || trollType == TrollType.BlockedSuperTroll) {
            superTrollCount--;
        } else if (trollType == TrollType.GeneralTroll || trollType == TrollType.BlockedGeneralTroll) {
            generalTrollCount--;
        } else {
            revert("invalid troll type");
        }
        delete trollProfileInv[troll.troll];
        delete trollProfiles[trollProfileIndex];
    }

    function lockSuperTroll(uint256 trollProfileIndex) external {
        require(isSuperTroll(msg.sender, false) || isPermitted[msg.sender], "not from super troll");
        TrollProfile storage troll = trollProfiles[trollProfileIndex];
        require(troll.trollType == TrollType.SuperTroll, "not a super troll");
        // require(msg.sender != troll.troll, "cannot self lock");
        troll.trollType = TrollType.BlockedSuperTroll;
        emit LockSuperTroll(trollProfileIndex, msg.sender);
    }
    function unlockSuperTroll(bytes[] calldata signatures, uint256 trollProfileIndex, bool unlock, address[] calldata vaultRegistry, uint256[] calldata penalty, uint256 _nonce) external {
        bytes32 hash = hashUnlockTroll(trollProfileIndex, unlock, vaultRegistry, penalty, _nonce);
        _verifySignatures(msg.sender, signatures, hash, _nonce);
        TrollProfile storage troll = trollProfiles[trollProfileIndex];
        require(troll.trollType == TrollType.BlockedSuperTroll, "not in locked status");
        uint256 length = vaultRegistry.length;
        require(length == penalty.length, "length not match");
        if (unlock)
            troll.trollType = TrollType.SuperTroll;

        for (uint256 i ; i < length ; i++) {
            OSWAP_BridgeVaultTrollRegistry(vaultRegistry[i]).penalizeSuperTroll(trollProfileIndex, penalty[i]);
            emit UnlockSuperTroll(trollProfileIndex, unlock, vaultRegistry[i], penalty[i]);
        }
    }
    function lockGeneralTroll(uint256 trollProfileIndex) external {
        require(isSuperTroll(msg.sender, false) || isPermitted[msg.sender], "not from super troll");
        TrollProfile storage troll = trollProfiles[trollProfileIndex];
        require(troll.trollType == TrollType.GeneralTroll, "not a general troll");
        troll.trollType = TrollType.BlockedGeneralTroll;
        emit LockGeneralTroll(trollProfileIndex, msg.sender);
    }
    function unlockGeneralTroll(bytes[] calldata signatures, uint256 trollProfileIndex, uint256 _nonce) external {
        bytes32 hash = hashUnlockTroll(trollProfileIndex, true, new address[](0), new uint256[](0), _nonce);
        _verifySignatures(msg.sender, signatures, hash, _nonce);
        TrollProfile storage troll = trollProfiles[trollProfileIndex];
        require(troll.trollType == TrollType.BlockedGeneralTroll, "not in locked status");
        troll.trollType = TrollType.GeneralTroll;
        emit UnlockGeneralTroll(trollProfileIndex);
    }

    function registerVault(bytes[] calldata signatures, IERC20 token, IOSWAP_BridgeVault vault, uint256 _nonce) external {
        bytes32 hash = hashRegisterVault(token, vault, _nonce);
        _verifySignatures(msg.sender, signatures, hash, _nonce);
        vaultToken.push(token);
        vaults[token] = vault;
        emit NewVault(token, vault);
    }
}




pragma solidity 0.8.6;

interface IOSWAP_HybridRouter2 {

    function registry() external view returns (address);
    function WETH() external view returns (address);

    function getPathIn(address[] calldata pair, address tokenIn) external view returns (address[] memory path);
    function getPathOut(address[] calldata pair, address tokenOut) external view returns (address[] memory path);

    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata pair,
        address tokenIn,
        address to,
        uint deadline,
        bytes calldata data
    ) external returns (address[] memory path, uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata pair,
        address tokenOut,
        address to,
        uint deadline,
        bytes calldata data
    ) external returns (address[] memory path, uint[] memory amounts);
    function swapExactETHForTokens(uint amountOutMin, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        payable
        returns (address[] memory path, uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        returns (address[] memory path, uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        returns (address[] memory path, uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata pair, address to, uint deadline, bytes calldata data)
        external
        payable
        returns (address[] memory path, uint[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address tokenIn,
        address to,
        uint deadline,
        bytes calldata data
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bytes calldata data
    ) external payable;
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline,
        bytes calldata data
    ) external;

    function getAmountsInStartsWith(uint amountOut, address[] calldata pair, address tokenIn, bytes calldata data) external view returns (uint[] memory amounts);
    function getAmountsInEndsWith(uint amountOut, address[] calldata pair, address tokenOut, bytes calldata data) external view returns (uint[] memory amounts);
    function getAmountsOutStartsWith(uint amountIn, address[] calldata pair, address tokenIn, bytes calldata data) external view returns (uint[] memory amounts);
    function getAmountsOutEndsWith(uint amountIn, address[] calldata pair, address tokenOut, bytes calldata data) external view returns (uint[] memory amounts);
}