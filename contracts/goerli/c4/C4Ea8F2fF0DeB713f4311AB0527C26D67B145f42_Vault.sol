pragma solidity 0.6.12;
pragma experimental ABIEncoderV2;

import "../interfaces/IERC20.sol";
import "../openzeppelin/Ownable.sol";
import "../interfaces/IDSProxy.sol";
import "../libraries/SafeMath.sol";
import "../libraries/Address.sol";
import "../libraries/SafeERC20.sol";
import "../base/Logs.sol";

interface ICRPPool {
    function getController() external view returns (address);

    enum Etypes {
        OPENED,
        CLOSED
    }

    function etype() external view returns (Etypes);
}

interface IDesynOwnable {
    function adminList(address adr) external view returns (bool);
    function getController() external view returns (address);
    function getOwners() external view returns (address[] memory);
    function getOwnerPercentage() external view returns (uint[] memory);
    function allOwnerPercentage() external view returns (uint);
}

interface IUserVault {
    function depositToken(
        address pool,
        uint types,
        address[] calldata poolTokens,
        uint[] calldata tokensAmount
    ) external;
}

interface ICRPFactory {
    function isCrp(address addr) external view returns (bool);
}

/**
 * @author Desyn Labs
 * @title Vault managerFee
 */
contract Vault is Ownable, Logs {
    using SafeMath for uint;
    using Address for address;
    using SafeERC20 for IERC20;

    ICRPFactory crpFactory;
    address public userVault;

    event ManagersClaim(address indexed caller,address indexed pool, address token, uint amount, uint time);
    event ManagerClaim(address indexed caller,address indexed manager, address token, uint amount, uint time);

    // pool of tokens
    struct PoolTokens {
        address[] tokenList;
        uint[] managerAmount;
        uint[] issueAmount;
        uint[] redeemAmount;
        uint[] perfermanceAmount;
    }

    struct PoolStatus {
        bool couldManagerClaim;
        bool isBlackList;
    }
    
    struct ClaimTokens {
        address[] tokens;
        uint[] amounts;
    }

    // pool tokens
    mapping(address => PoolTokens) poolsTokens;
    mapping(address => PoolStatus) public poolsStatus;

    mapping (address => ClaimTokens) manageHasClaimed;

    // default ratio config
    uint public TOTAL_RATIO = 1000;
    uint public management_portion = 800;
    uint public issuance_portion = 800;
    uint public redemption_portion = 800;
    uint public performance_portion = 800;

    receive() external payable {}

    function depositManagerToken(address[] calldata tokensIn, uint[] calldata amountsIn) external {
        address pool = msg.sender;
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        require(tokensIn.length == amountsIn.length, "ERR_TOKEN_LENGTH_NOT_MATCH");
        _depositTokenIM(0, pool, tokensIn, amountsIn);

        poolsStatus[pool].couldManagerClaim = true;
        
        if (_isClosePool(pool)) this.managerClaim(pool);
    }

    function depositIssueRedeemPToken(
        address[] calldata tokensIn,
        uint[] calldata amountsIn,
        uint[] calldata tokensAmountIR,
        bool isPerfermance
    ) external {
        address pool = msg.sender;
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        require(tokensIn.length == amountsIn.length, "ERR_TOKEN_LENGTH_NOT_MATCH");

        isPerfermance
                // I-issuce； M-mamager； R-redeem；p-performance
                ? _depositTokenRP(pool, tokensIn, amountsIn, tokensAmountIR)
                : _depositTokenIM(1, pool, tokensIn, amountsIn);

        poolsStatus[pool].couldManagerClaim = true;

        if (_isClosePool(pool)) this.managerClaim(pool);   
    }

    function getManagerClaimBool(address pool) external view returns (bool) {
        return poolsStatus[pool].couldManagerClaim;
    }

    function setBlackList(address pool, bool bools) external onlyOwner _logs_ {
        poolsStatus[pool].isBlackList = bools;
    }

    function setUserVaultAdr(address adr) external onlyOwner _logs_ {
        require(adr != address(0), "ERR_INVALID_USERVAULT_ADDRESS");
        userVault = adr;
    }

    function setCrpFactory(address adr) external onlyOwner _logs_ {
        crpFactory = ICRPFactory(adr);
    }

    function claimToken(
        address token,
        address user,
        uint amount
    ) external onlyOwner {
        IERC20(token).safeTransfer(user, amount);
    }

    function claimEther() external payable onlyOwner {
        msg.sender.transfer(address(this).balance);
    }

    function setManagerRatio(uint amount) external onlyOwner _logs_ {
        require(amount <= TOTAL_RATIO, "Maximum limit exceeded");
        management_portion = amount;
    }

    function setIssueRatio(uint amount) external onlyOwner _logs_ {
        require(amount <= TOTAL_RATIO, "Maximum limit exceeded");
        issuance_portion = amount;
    }

    function setRedeemRatio(uint amount) external onlyOwner _logs_ {
        require(amount <= TOTAL_RATIO, "Maximum limit exceeded");
        redemption_portion = amount;
    }

    function setPerfermanceRatio(uint amount) external onlyOwner _logs_{
        performance_portion = amount;
    }

    function managerClaim(address pool) external {
        require(crpFactory.isCrp(pool), "ERR_INVALID_POOL_ADDRESS");
        address managerAddr = ICRPPool(pool).getController();

        PoolTokens memory tokens = poolsTokens[pool];
        PoolStatus storage status = poolsStatus[pool];
        bool isCloseETF = _isClosePool(pool);

        address[] memory poolManageTokens = tokens.tokenList;
        uint len = poolManageTokens.length;
        require(!status.isBlackList, "ERR_POOL_IS_BLACKLIST");
        require(len > 0, "ERR_NOT_MANGER_FEE");
        require(status.couldManagerClaim, "ERR_MANAGER_COULD_NOT_CLAIM");
        status.couldManagerClaim = false;

        uint[] memory managerTokenAmount = new uint[](len);
        uint[] memory issueTokenAmount = new uint[](len);
        uint[] memory redeemTokenAmount = new uint[](len);
        uint[] memory perfermanceTokenAmount = new uint[](len);

        for (uint i; i < len; i++) {
            address t = poolManageTokens[i];
            uint b;
            (b, managerTokenAmount[i], issueTokenAmount[i], redeemTokenAmount[i], perfermanceTokenAmount[i]) = _computeBalance(i, pool);
            if(!isCloseETF) b = b.sub(_getManagerHasClaimed(pool,t));
            if(b != 0) _transferHandle(pool, managerAddr, t, b);
        }
        
        if (isCloseETF) {
            _recordUserVault(pool, poolManageTokens, managerTokenAmount, issueTokenAmount, redeemTokenAmount, perfermanceTokenAmount);
            _clearPool(pool);
        }   
    }

    function getManagerFeeTypes(address pool) external view returns(PoolTokens memory result){     
        PoolTokens memory tokens = poolsTokens[pool];
        address[] memory poolManageTokens = tokens.tokenList;
        uint len = poolManageTokens.length;

        result.tokenList = tokens.tokenList;
        result.managerAmount = new uint[](len);
        result.issueAmount = new uint[](len);
        result.redeemAmount = new uint[](len);
        result.perfermanceAmount = new uint[](len);

        for(uint i; i< len; i++){
            (,result.managerAmount[i],result.issueAmount[i],result.redeemAmount[i],result.perfermanceAmount[i]) = _computeBalance(i,pool);
        }
    }

    function getUnManagerReward(address pool) external view returns (address[] memory tokensList, uint[] memory amounts) {
        PoolTokens memory tokens = poolsTokens[pool];
        address[] memory poolManageTokens = tokens.tokenList;
        uint len = poolManageTokens.length;

        tokensList = new address[](len);
        amounts = new uint[](len);

        for (uint i; i < len; i++) {
            address t = poolManageTokens[i];
            tokensList[i] = t;
            (amounts[i],,,,) = _computeBalance(i,pool);
            amounts[i] = amounts[i].sub(_getManagerHasClaimed(pool, t));
        }
    }

    function _addTokenInPool(address pool, address tokenAddr) internal {
        PoolTokens storage tokens = poolsTokens[pool];

        tokens.tokenList.push(tokenAddr);
        tokens.managerAmount.push(0);
        tokens.issueAmount.push(0);
        tokens.redeemAmount.push(0);
        tokens.perfermanceAmount.push(0);
    }
    // for old token
    function _updateTokenAmountInPool(uint types, address pool, uint tokenIndex, uint amount) internal {
        PoolTokens storage tokens = poolsTokens[pool];

        if(types == 0) tokens.managerAmount[tokenIndex] = tokens.managerAmount[tokenIndex].add(amount);
        if(types == 1) tokens.issueAmount[tokenIndex] = tokens.issueAmount[tokenIndex].add(amount);
        if(types == 2) tokens.redeemAmount[tokenIndex] = tokens.redeemAmount[tokenIndex].add(amount);
        if(types == 3) tokens.perfermanceAmount[tokenIndex] = tokens.perfermanceAmount[tokenIndex].add(amount);
    }
    // for new token
    function _updateTokenAmountInPool(uint types, address pool, uint amount) internal {
        PoolTokens storage tokens = poolsTokens[pool];
        uint tokenIndex = tokens.tokenList.length - 1;

        if(types == 0) tokens.managerAmount[tokenIndex] = amount;
        if(types == 1) tokens.issueAmount[tokenIndex] = amount;
        if(types == 2) tokens.redeemAmount[tokenIndex] = amount;
        if(types == 3) tokens.perfermanceAmount[tokenIndex] = amount;
    }

    function _depositTokenIM(
        uint types,
        address pool,
        address[] memory tokensIn,
        uint[] memory amountsIn
    ) internal {
        PoolTokens memory tokens = poolsTokens[pool];

        uint len = tokensIn.length;
        for (uint i; i < len; i++) {
            address t = tokensIn[i];
            uint b = amountsIn[i];

            IERC20(t).safeTransferFrom(msg.sender, address(this), b);
            (bool isExit, uint index) = _arrIncludeAddr(tokens.tokenList,t);
            if (isExit) {
                _updateTokenAmountInPool(types,pool,index,b);
            } else { 
                _addTokenInPool(pool,t); 
                _updateTokenAmountInPool(types,pool,b);    
            }
        }
    }

    function _arrIncludeAddr(address[] memory tokens, address target) internal pure returns(bool isInclude, uint index){
        for(uint i; i<tokens.length; i++){
            if(tokens[i] == target){ 
                isInclude = true;
                index = i;
                break;
            }
        }
    }

    function _depositTokenRP(
        address pool,
        address[] calldata tokenIns,
        uint[] calldata tokensAmount,
        uint[] calldata tokensAmountIR
    ) internal {
        address[] memory tokenList = poolsTokens[pool].tokenList;

        uint len = tokensAmount.length;
        for (uint i; i < len; i++) {
            address t = tokenIns[i];
            uint b = tokensAmount[i];
            // uint bIR = tokensAmountIR[i];
            IERC20(t).safeTransferFrom(msg.sender, address(this), b);

            (bool isExit,uint index) = _arrIncludeAddr(tokenList, t);
            if(isExit){
                _updateTokenAmountInPool(3, pool, index, tokensAmountIR[i]);
                _updateTokenAmountInPool(4, pool, index, b.sub(tokensAmountIR[i]));
            } else {
                _addTokenInPool(pool, t);
                _updateTokenAmountInPool(3,pool, tokensAmountIR[i]);
                _updateTokenAmountInPool(4, pool,b.sub(tokensAmountIR[i]));        
            }
        }
    }

    function _isClosePool(address pool) internal view returns (bool) {
        return ICRPPool(pool).etype() == ICRPPool.Etypes.CLOSED;
    }

    function _computeBalance(uint i, address pool)
        internal
        view
        returns (
            uint balance,
            uint bManagerAmount,
            uint bIssueAmount,
            uint bRedeemAmount,
            uint bPerfermanceAmount
        )
    {
        PoolTokens memory tokens = poolsTokens[pool];

        if (tokens.managerAmount.length != 0) {
            bManagerAmount = tokens.managerAmount[i].mul(management_portion).div(TOTAL_RATIO);
            balance = balance.add(bManagerAmount);
        }
        if (tokens.issueAmount.length != 0) {
            bIssueAmount = tokens.issueAmount[i].mul(issuance_portion).div(TOTAL_RATIO);
            balance = balance.add(bIssueAmount);
        }
        if (tokens.redeemAmount.length != 0) {
            bRedeemAmount = tokens.redeemAmount[i].mul(redemption_portion).div(TOTAL_RATIO);
            balance = balance.add(bRedeemAmount);
        }
        if (tokens.perfermanceAmount.length != 0) {
            bPerfermanceAmount = tokens.perfermanceAmount[i].mul(performance_portion).div(TOTAL_RATIO);
            balance = balance.add(bPerfermanceAmount);
        }
    }

    function _clearPool(address pool) internal {
        delete poolsTokens[pool];
    }

    function _recordUserVault(
        address pool,
        address[] memory tokenList,
        uint[] memory managerTokenAmount,
        uint[] memory issueTokenAmount,
        uint[] memory redeemTokenAmount,
        uint[] memory perfermanceTokenAmount
    ) internal {
        PoolTokens memory tokens = poolsTokens[pool];

        if (tokens.managerAmount.length != 0) 
            IUserVault(userVault).depositToken(pool, 0, tokenList, managerTokenAmount);
        
        if (tokens.issueAmount.length != 0) 
            IUserVault(userVault).depositToken(pool, 1, tokenList, issueTokenAmount);
        
        if (tokens.redeemAmount.length != 0) 
            IUserVault(userVault).depositToken(pool, 2, tokenList, redeemTokenAmount);
        
        if (tokens.perfermanceAmount.length != 0) 
            IUserVault(userVault).depositToken(pool, 3, tokenList, perfermanceTokenAmount);
        
    }

    function _transferHandle(
        address pool,
        address managerAddr,
        address t,
        uint balance
    ) internal {
        require(balance != 0, "ERR_ILLEGAL_BALANCE");
        bool isCloseETF = _isClosePool(pool);
        bool isOpenETF = !isCloseETF;
        bool isContractManager = managerAddr.isContract();

        if(isCloseETF){
            IERC20(t).safeTransfer(userVault, balance);
        }

        if(isOpenETF && isContractManager){
            address[] memory managerAddressList = IDesynOwnable(pool).getOwners();
            uint[] memory ownerPercentage = IDesynOwnable(pool).getOwnerPercentage();
            uint allOwnerPercentage = IDesynOwnable(pool).allOwnerPercentage();

            for (uint k; k < managerAddressList.length; k++) {
                address reciver = address(managerAddressList[k]).isContract()? IDSProxy(managerAddressList[k]).owner(): managerAddressList[k];
                uint b = balance.mul(ownerPercentage[k]).div(allOwnerPercentage);
                IERC20(t).safeTransfer(reciver, b);
                emit ManagerClaim(msg.sender,reciver,t,b,block.timestamp);
            }
            _updateManageHasClaimed(pool,t,balance);
            emit ManagersClaim(msg.sender, pool, t, balance, block.timestamp);
        }

        if(isOpenETF && !isContractManager){
            IERC20(t).safeTransfer(managerAddr, balance);
        }
    }

    function _updateManageHasClaimed(address pool, address token, uint amount) internal {
        ClaimTokens storage claimInfo = manageHasClaimed[pool];
        (bool isExit, uint index) = _arrIncludeAddr(claimInfo.tokens, token);

        if(isExit){
            claimInfo.amounts[index] = claimInfo.amounts[index].add(amount);
        } else{
            claimInfo.tokens.push(token);
            claimInfo.amounts.push(amount);
        }
    }

    function _getManagerHasClaimed(address pool, address token) internal view returns(uint){
        require(!_isClosePool(pool),"ERR_NOT_OPEN_POOL");

        ClaimTokens memory claimInfo = manageHasClaimed[pool];
        (bool isExit,uint index) = _arrIncludeAddr(claimInfo.tokens, token);

        if(isExit) return claimInfo.amounts[index];
        if(!isExit) return 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

// Interface declarations

/* solhint-disable func-order */

interface IERC20 {
    // Emitted when the allowance of a spender for an owner is set by a call to approve.
    // Value is the new allowance
    event Approval(address indexed owner, address indexed spender, uint value);

    // Emitted when value tokens are moved from one account (from) to another (to).
    // Note that value may be zero
    event Transfer(address indexed from, address indexed to, uint value);

    // Returns the amount of tokens in existence
    function totalSupply() external view returns (uint);

    // Returns the amount of tokens owned by account
    function balanceOf(address account) external view returns (uint);

    // Returns the decimals of tokens
    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    // Returns the remaining number of tokens that spender will be allowed to spend on behalf of owner
    // through transferFrom. This is zero by default
    // This value changes when approve or transferFrom are called
    function allowance(address owner, address spender) external view returns (uint);

    // Sets amount as the allowance of spender over the caller’s tokens
    // Returns a boolean value indicating whether the operation succeeded
    // Emits an Approval event.
    function approve(address spender, uint amount) external returns (bool);

    // Moves amount tokens from the caller’s account to recipient
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event.
    function transfer(address recipient, uint amount) external returns (bool);

    // Moves amount tokens from sender to recipient using the allowance mechanism
    // Amount is then deducted from the caller’s allowance
    // Returns a boolean value indicating whether the operation succeeded
    // Emits a Transfer event
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
}

pragma solidity >=0.6.0 <0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

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
    constructor () internal {
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

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint a, uint b) internal pure returns (uint) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b <= a, errorMessage);
        uint c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint a, uint b) internal pure returns (uint) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint a, uint b) internal pure returns (uint) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint a, uint b) internal pure returns (uint) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(
        uint a,
        uint b,
        string memory errorMessage
    ) internal pure returns (uint) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

interface IDSProxy {
    function owner() external view returns(address);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.6.12;

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
        // According to EIP-1052, 0x0 is the value returned for not-yet created accounts
        // and 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470 is returned
        // for accounts without code, i.e. `keccak256('')`
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            codehash := extcodehash(account)
        }
        return (codehash != accountHash && codehash != 0x0);
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
    function sendValue(address payable recipient, uint amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return _functionCallWithValue(target, data, 0, errorMessage);
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
        uint value
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
        uint value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        return _functionCallWithValue(target, data, value, errorMessage);
    }

    function _functionCallWithValue(
        address target,
        bytes memory data,
        uint weiValue,
        string memory errorMessage
    ) private returns (bytes memory) {
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: weiValue}(data);
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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

pragma solidity 0.6.12;

import {IERC20} from "../interfaces/IERC20.sol";
import {SafeMath} from "./SafeMath.sol";
import {Address} from "./Address.sol";

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
    using SafeMath for uint;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint value
    ) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(
        IERC20 token,
        address spender,
        uint value
    ) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0), "SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.6.12;

contract Logs {
    event LOG_CALL(bytes4 indexed sig, address indexed caller, bytes data) anonymous;

    modifier _logs_() {
        emit LOG_CALL(msg.sig, msg.sender, msg.data);
        _;
    }
}