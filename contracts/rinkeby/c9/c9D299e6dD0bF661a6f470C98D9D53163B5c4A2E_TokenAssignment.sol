// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TokenAssignment is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    mapping(address => bool) public proxyToApproved; // proxy allowance for interaction with future contract
    struct Token {
        uint256 id;
        address tokenAddress;
        uint256 deposited;
    }

    struct VestingStages{
        uint256 unlockDuration;
        bool toClaim;
        uint16 percentage;
    }
    
    mapping(uint256 => mapping(address => VestingStages[])) public MB1vestingToAddress;
    mapping(uint256 => mapping(address => VestingStages[])) public GGvestingToAddress;
    mapping(uint256=>mapping(address=>bool)) public MB1isVested;
    mapping(uint256=>mapping(address=>bool)) public GGisVested;


    mapping(uint256=> mapping(address=>uint256)) public MB1Cliff;
    mapping(uint256=> mapping(address=>uint256)) public GGCliff;

    mapping(uint256 => mapping(address=> uint256)) public MB1tokenToClaim;
    mapping(uint256 => mapping(address=> uint256)) public GGtokenToClaim;

    mapping(uint256 =>mapping(address=> uint256)) public MB1stageClaimedStart;
    mapping(uint256 =>mapping(address=> uint256)) public GGstageClaimedStart;
  

    mapping(uint256 => mapping(address=> uint256)) private MB1nextUnlock;
    mapping(uint256 => mapping(address=> uint256)) private GGnextUnlock;
    

    Token[] public tokenList;
    mapping(address => uint256) public TokenToCount;
    mapping(address => bool) public tokenExists;
    mapping(uint256 => mapping(address => uint256)) public MB1IDToTokenToAmount;
    mapping(uint256 => mapping(address => uint256)) public GGIDToTokenToAmount;
    mapping(uint256 => bool) public WithdrawRequests;
    //mapping(uint256 => bool) public WithdrawMultipleRequests;

    constructor() {
        proxyToApproved[_msgSender()] = true;
    }

    function addToken(address token) external onlyProxy{
        TokenToCount[token] = tokenList.length;
        tokenList.push(Token({ id: tokenList.length, tokenAddress: token, deposited: 0}));
        tokenExists[token] = true;
        emit AddToken(_msgSender(), token);
    }


    function addVestingPlanMB1(uint256 nftID, address token, uint256 _cliff, uint16[] calldata _percentages, uint256[] calldata _unlockDuration, uint256 _startTime ) external onlyProxy validToken(token){        
        require(_percentages.length==_unlockDuration.length,"LENGTH_MISMATCH");
        require(block.timestamp<=_startTime,"INVALID_START_TIME");
        require(!MB1isVested[nftID][token],"ALREADY_VESTED");
        VestingStages[] storage stages = MB1vestingToAddress[nftID][token];
        for(uint256 i=0;i<_percentages.length;i++){
            stages.push(VestingStages(_unlockDuration[i],true,_percentages[i]));
        }
        MB1Cliff[nftID][token]=_cliff;
        MB1nextUnlock[nftID][token]= _startTime+_cliff;
        MB1isVested[nftID][token]=true;
    } 

    function addVestingPlanGG(uint256 nftID, address token, uint256 _cliff, uint16[] calldata _percentages, uint256[] calldata _unlockDuration, uint256 _startTime) external onlyProxy validToken(token){
        require(_percentages.length==_unlockDuration.length,"LENGTH_MISMATCH");
        require(block.timestamp<=_startTime,"INVALID_START_TIME");
        require(!GGisVested[nftID][token],"ALREADY_VESTED");
        VestingStages[] storage stages = GGvestingToAddress[nftID][token];
        for(uint256 i=0;i<_percentages.length ;i++){
            stages.push(VestingStages(_unlockDuration[i],true,_percentages[i]));
        }
        GGCliff[nftID][token]=_cliff;
        GGnextUnlock[nftID][token]= _startTime+_cliff;
        GGisVested[nftID][token]=true;
    }     

    // vesting add here with nft
    function depositTokenForMB1(uint256 nftID, address token, uint256 amount) 
        external onlyProxy validToken(token) 
    {
        // add amount independent for non vesting token holders
        MB1IDToTokenToAmount[nftID][token] += amount;
        tokenList[TokenToCount[token]].deposited += amount;
        emit DepositTokenForMB1(_msgSender(), nftID, token, amount);
    }

    function depositTokensForMB1(uint256[] calldata nftIDs, address[] calldata token, 
        uint256[] calldata amounts) external onlyProxy 
    {
        require(nftIDs.length == tokenList.length && tokenList.length == amounts.length, "INCONSISTENT_LENGTHS");
        for(uint256 x; x < nftIDs.length; x++) {
            require(TokenToCount[token[x]] > 0, "INVALID_TOKEN");
            MB1IDToTokenToAmount[nftIDs[x]][token[x]] += amounts[x];
            tokenList[TokenToCount[token[x]]].deposited += amounts[x];
            emit DepositTokenForMB1(_msgSender(), nftIDs[x], token[x], amounts[x]);
        }
    } 

    function withdrawForMB1(uint256 withdrawRequestID, uint256 nftID, address token, 
        uint256 amount, address user, address recipient) external onlyProxy validToken(token) 
    {
        require(!WithdrawRequests[withdrawRequestID], "PREVIOUSLY_PROCESSED");
        require(amount>0,"AMOUNT_INVALID");
        if(MB1isVested[nftID][token]){
            if(amount>MB1tokenToClaim[nftID][token]){
                _calculateAndClaimMB1(nftID, token);
            }
            require(MB1tokenToClaim[nftID][token]>=amount,"AMOUNT_INVALID");
            MB1tokenToClaim[nftID][token] -= amount;
        }else{
            require(MB1IDToTokenToAmount[nftID][token]>=amount,"AMOUNT_INVALID");
            MB1IDToTokenToAmount[nftID][token]-=amount;
        }

        IERC20(token).transfer(recipient, amount);
        WithdrawRequests[withdrawRequestID] = true;
        emit WithdrawTokenForMB1(_msgSender(), nftID, token, amount, user, recipient, withdrawRequestID);
    }

    function depositTokenForGG(uint256 nftID, address token, uint256 amount) external 
        onlyProxy validToken(token) 
    {
        GGIDToTokenToAmount[nftID][token] += amount;
        tokenList[TokenToCount[token]].deposited += amount;
        emit DepositTokenForGG(_msgSender(), nftID, token, amount);
    }

    function depositTokensForGG(uint256[] calldata nftIDs, address[] calldata token, 
        uint256[] calldata amounts) external onlyProxy 
    {
        require(nftIDs.length == tokenList.length && tokenList.length == amounts.length, "INCONSISTENT_LENGTHS");
        for(uint256 x; x < nftIDs.length; x++) {
            require(tokenExists[token[x]], "INVALID_TOKEN");
            GGIDToTokenToAmount[nftIDs[x]][token[x]] += amounts[x];
            tokenList[TokenToCount[token[x]]].deposited += amounts[x];
            emit DepositTokenForGG(_msgSender(), nftIDs[x], token[x], amounts[x]);
        }
    }

    function withdrawForGG(uint256 withdrawRequestID, uint256 nftID, address token, 
        uint256 amount, address user, address recipient) external onlyProxy validToken(token) 
    {
        require(!WithdrawRequests[withdrawRequestID], "PREVIOUSLY_PROCESSED");
        require(amount>0,"AMOUNT_INVALID");
        if (GGisVested[nftID][token]){
            if(amount>GGtokenToClaim[nftID][token]){
                _calculateAndClaimGG(nftID, token);
            }

            require(GGtokenToClaim[nftID][token]>=amount,"AMOUNT_INVALID");
            GGtokenToClaim[nftID][token] -= amount;

        }else{
            require(GGIDToTokenToAmount[nftID][token]>=amount,"AMOUNT_INVALID");
            GGIDToTokenToAmount[nftID][token]-=amount;
        }

        IERC20(token).transfer(recipient, amount);
        WithdrawRequests[withdrawRequestID] = true;
        emit WithdrawTokenForGG(_msgSender(), nftID, token, amount, user, recipient, withdrawRequestID);
    }

    function getTokenStats(address token) external view validToken(token) returns(uint256, uint256) {
        return (tokenList[TokenToCount[token]].deposited, IERC20(token).balanceOf(address(this)));
    }

    function setProxyState(address proxyAddress, bool value) external onlyOwner {
        proxyToApproved[proxyAddress] = value;
    }    

    modifier onlyProxy() {
        require(proxyToApproved[_msgSender()], "onlyProxy");
        _;
    }   

    modifier validToken(address token) {
        require(tokenExists[token], "INVALID_TOKEN");
        _;
    }    

    function _calculateAndClaimMB1(uint256 nftID,address token) internal{
        uint256 time= block.timestamp;
        VestingStages[] storage stages= MB1vestingToAddress[nftID][token];
        uint256 balance= MB1IDToTokenToAmount[nftID][token];
        uint256 totalToClaim = 0;
        uint256 toSend=0;
        uint256 i=MB1stageClaimedStart[nftID][token];
        uint256 unlock=MB1nextUnlock[nftID][token];
        uint256 finalstage=i;
        for (i;i<stages.length;i++){
            if((balance!=0)&&(stages[i].toClaim)&&(time>=stages[i].unlockDuration+unlock)){
                toSend=(balance*stages[i].percentage)/1000;
                if(toSend>=balance){
                    toSend=balance;
                }
                balance= balance-toSend;
                stages[i].toClaim=false;
                totalToClaim+=toSend;
                finalstage=i+1;
                unlock=unlock+stages[i].unlockDuration;
            }else{
                MB1nextUnlock[nftID][token]=unlock;
                MB1stageClaimedStart[nftID][token]=finalstage;
                break;
            }
        }
            MB1IDToTokenToAmount[nftID][token]-=totalToClaim;
            MB1tokenToClaim[nftID][token]+=totalToClaim;
    }


    function _calculateAndClaimGG(uint256 nftID,address token) internal{
        uint256 time= block.timestamp;
        VestingStages[] storage stages=GGvestingToAddress[nftID][token];
        uint256 balance=GGIDToTokenToAmount[nftID][token];
        uint256 totalToClaim = 0;
        uint256 toSend=0;
        uint256 i=GGstageClaimedStart[nftID][token];
        uint256 unlock=GGnextUnlock[nftID][token];
        uint256 finalstage=i;
        for (i;i<stages.length;i++){
            if((balance!=0)&&(stages[i].toClaim)&&(time>=stages[i].unlockDuration+unlock)){
                toSend=(balance*stages[i].percentage)/1000;
                if(toSend>=balance){
                    toSend=balance;
                }
                balance= balance-toSend;
                stages[i].toClaim=false;
                totalToClaim+=toSend;
                finalstage=i+1;
                unlock=unlock+stages[i].unlockDuration;
            }else{
                GGnextUnlock[nftID][token]=unlock;
                GGstageClaimedStart[nftID][token]=finalstage;
                break;
            }
        }
            GGIDToTokenToAmount[nftID][token]-=totalToClaim;
            GGtokenToClaim[nftID][token]+=totalToClaim;
    }

    function calculateClaimableTokens(bool isMB1,uint256 nftID, address token) external view returns(uint256){
        if(isMB1? MB1isVested[nftID][token]:GGisVested[nftID][token]){
            uint256 time= block.timestamp;
            VestingStages[] storage stages= isMB1? MB1vestingToAddress[nftID][token]:GGvestingToAddress[nftID][token];
            uint256 balance= isMB1 ? MB1IDToTokenToAmount[nftID][token]: GGIDToTokenToAmount[nftID][token];
            uint256 totalToClaim = 0;
            uint256 toSend=0;
            uint256 i=isMB1? MB1stageClaimedStart[nftID][token]:GGstageClaimedStart[nftID][token];
            uint256 unlock=isMB1? MB1nextUnlock[nftID][token]:GGnextUnlock[nftID][token];
            for (i;i<stages.length;i++){
                if((balance!=0)&&(stages[i].toClaim)&&(time>=stages[i].unlockDuration+unlock)){
                    toSend=(balance*stages[i].percentage)/1000;
                    if(toSend>=balance){
                        toSend=balance;
                    }
                    balance= balance-toSend;
                    totalToClaim+=toSend;
                    unlock=unlock+stages[i].unlockDuration;
                }else{
                    break;
                }
            }
            return isMB1 ? MB1tokenToClaim[nftID][token]+totalToClaim : GGtokenToClaim[nftID][token]+totalToClaim;
        }

        return isMB1? MB1IDToTokenToAmount[nftID][token]: GGIDToTokenToAmount[nftID][token];
    }

    function flipVesting(uint256 nftID, address token, bool isMB1) external onlyOwner{
        bool state= isMB1? MB1isVested[nftID][token] : GGisVested[nftID][token];
        require(state,"INVALID_VEST_PAIR");

        if (isMB1){
            MB1isVested[nftID][token]=false;
            MB1IDToTokenToAmount[nftID][token]+=MB1tokenToClaim[nftID][token];
            MB1tokenToClaim[nftID][token]=0;
        }else{
            GGisVested[nftID][token]=false;
            GGIDToTokenToAmount[nftID][token]+=GGtokenToClaim[nftID][token];
            GGtokenToClaim[nftID][token]=0;
        }
    }

    function nextVestUnlock(bool isMB1, uint256 nftID,address token) external view returns(uint256){
        bool state= isMB1? MB1isVested[nftID][token] : GGisVested[nftID][token];
        require(state,"INVALID_VEST_PAIR");
       
        if(isMB1){
             uint256 unlock= MB1nextUnlock[nftID][token];
             uint256 stage= MB1stageClaimedStart[nftID][token];
             return MB1vestingToAddress[nftID][token][stage].unlockDuration+unlock;
        }else{
            uint256 unlock=GGnextUnlock[nftID][token];
            uint256 stage = GGstageClaimedStart[nftID][token];
            return GGvestingToAddress[nftID][token][stage].unlockDuration+unlock;
        }

    }

    function recoverTokens(address _token, address _to, uint256 balance) external onlyOwner{
        IERC20(_token).transfer(_to, balance);
    }

    event AddToken(address indexed sender, address indexed token);
    event DepositTokenForMB1(address indexed sender, uint256 indexed nftID, address indexed token, uint256 amount);
    event WithdrawTokenForMB1(address indexed sender, uint256 indexed nftID, address indexed token, uint256 amount, address user, address recipient, uint256 withdrawRequestID);
    event DepositTokenForGG(address indexed sender, uint256 indexed nftID, address indexed token, uint256 amount);
    event WithdrawTokenForGG(address indexed sender, uint256 indexed nftID, address indexed token, uint256 amount, address user, address recipient, uint256 withdrawRequestID);
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