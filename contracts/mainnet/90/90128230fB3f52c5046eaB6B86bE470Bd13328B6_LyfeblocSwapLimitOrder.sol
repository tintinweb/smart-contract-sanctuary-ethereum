pragma solidity 0.6.0;

import "./LyfeblocNetworkProxyInterface.sol";
import "./SafeERC20.sol";
import "./SafeMath.sol";
import "./Withdrawable.sol";


contract LyfeblocSwapLimitOrder is Withdrawable {

    //userAddress => concatenated token addresses => nonce
    mapping(address => mapping(uint256 => uint256)) public nonces;
    bool public tradeEnabled;
    LyfeblocNetworkProxyInterface public lyfeblocNetworkProxy;
    uint256 public constant MAX_DEST_AMOUNT = 2 ** 256 - 1;
    uint256 public constant PRECISION = 10**4;
    using SafeMath for uint256;
    using SafeERC20 for ERC20;

    //Constructor
    constructor(
        address _admin,
        LyfeblocNetworkProxyInterface _lyfeblocNetworkProxy
    )
        public
        Withdrawable(_admin) {
            require(_admin != address(0));
            require(address(_lyfeblocNetworkProxy) != address(0));

            lyfeblocNetworkProxy = _lyfeblocNetworkProxy;
        }

    event TradeEnabled(bool tradeEnabled);

    function enableTrade() external onlyAdmin {
        tradeEnabled = true;
        emit TradeEnabled(tradeEnabled);
    }

    function disableTrade() external onlyAdmin {
        tradeEnabled = false;
        emit TradeEnabled(tradeEnabled);
    }

    function listToken(ERC20 token)
        external
        onlyAdmin
    {
        require(address(token) != address(0));
        /*
        No need to set allowance to zero first, as there's only 1 scenario here (from zero to max allowance).
        No one else can set allowance on behalf of this contract to Lyfebloc.
        */
        token.safeApprove(address(lyfeblocNetworkProxy), MAX_DEST_AMOUNT);
    }

    struct VerifyParams {
        address user;
        uint8 v;
        uint256 concatenatedTokenAddresses;
        uint256 nonce;
        bytes32 hashedParams;
        bytes32 r;
        bytes32 s;
    }

    struct TradeInput {
        ERC20 srcToken;
        uint256 srcQty;
        ERC20 destToken;
        address payable destAddress;
        uint256 minConversionRate;
        uint256 feeInPrecision;
    }

    event LimitOrderExecute(address indexed user, uint256 nonce, address indexed srcToken,
        uint256 actualSrcQty, uint256 destAmount, address indexed destToken,
        address destAddress, uint256 feeInSrcTokenWei);

    function executeLimitOrder(
        address user,
        uint256 nonce,
        ERC20 srcToken,
        uint256 srcQty,
        ERC20 destToken,
        address payable destAddress,
        uint256 minConversionRate,
        uint256 feeInPrecision,
        uint8 v,
        bytes32 r,
        bytes32 s
    )
        onlyOperator
        external
    {
        require(tradeEnabled);

        VerifyParams memory verifyParams;
        verifyParams.user = user;
        verifyParams.concatenatedTokenAddresses = concatTokenAddresses(address(srcToken), address(destToken));
        verifyParams.nonce = nonce;
        verifyParams.hashedParams = keccak256(abi.encodePacked(
            user, nonce, srcToken, srcQty, destToken, destAddress, minConversionRate, feeInPrecision));
        verifyParams.v = v;
        verifyParams.r = r;
        verifyParams.s = s;
        require(verifyTradeParams(verifyParams));

        TradeInput memory tradeInput;
        tradeInput.srcToken = srcToken;
        tradeInput.srcQty = srcQty;
        tradeInput.destToken = destToken;
        tradeInput.destAddress = destAddress;
        tradeInput.minConversionRate = minConversionRate;
        tradeInput.feeInPrecision = feeInPrecision;
        trade(tradeInput, verifyParams);
    }

    event OldOrdersInvalidated(address user, uint256 concatenatedTokenAddresses, uint256 nonce);

    function invalidateOldOrders(uint256 concatenatedTokenAddresses, uint256 nonce) external {
        require(validAddressInNonce(nonce));
        require(isValidNonce(msg.sender, concatenatedTokenAddresses, nonce));
        updateNonce(msg.sender, concatenatedTokenAddresses, nonce);
        emit OldOrdersInvalidated(msg.sender, concatenatedTokenAddresses, nonce);
    }

    function concatTokenAddresses(address srcToken, address destToken) public pure returns (uint256) {
        return ((uint256(srcToken) >> 32) << 128) + (uint256(destToken) >> 32);
    }

    function validAddressInNonce(uint256 nonce) public view returns (bool) {
        //check that first 16 bytes in nonce corresponds to first 16 bytes of contract address
        return (nonce >> 128) == (uint256(address(this)) >> 32);
    }

    function isValidNonce(address user, uint256 concatenatedTokenAddresses, uint256 nonce) public view returns (bool) {
        return nonce > nonces[user][concatenatedTokenAddresses];
    }

    function verifySignature(bytes32 hash, uint8 v, bytes32 r, bytes32 s, address user) public pure returns (bool) {
        //Users have to sign the message using wallets (Trezor, Ledger, Geth)
        //These wallets prepend a prefix to the data to prevent some malicious signing scheme
        //Eg. website that tries to trick users to sign an Ethereum message
        //https://ethereum.stackexchange.com/questions/15364/ecrecover-from-geth-and-web3-eth-sign
        bytes memory prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 prefixedHash = keccak256(abi.encodePacked(prefix, hash));
        return ecrecover(prefixedHash, v, r, s) == user;
    }

    //used SafeMath lib
    function deductFee(uint256 srcQty, uint256 feeInPrecision) public pure returns
    (uint256 actualSrcQty, uint256 feeInSrcTokenWei) {
        require(feeInPrecision <= 100 * PRECISION);
        feeInSrcTokenWei = srcQty.mul(feeInPrecision).div(100 * PRECISION);
        actualSrcQty = srcQty.sub(feeInSrcTokenWei);
    }

    event NonceUpdated(address user, uint256 concatenatedTokenAddresses, uint256 nonce);

    function updateNonce(address user, uint256 concatenatedTokenAddresses, uint256 nonce) internal {
        nonces[user][concatenatedTokenAddresses] = nonce;
        emit NonceUpdated(user, concatenatedTokenAddresses, nonce);
    }

    function verifyTradeParams(VerifyParams memory verifyParams) internal view returns (bool) {
        require(validAddressInNonce(verifyParams.nonce));
        require(isValidNonce(verifyParams.user, verifyParams.concatenatedTokenAddresses, verifyParams.nonce));
        require(verifySignature(
            verifyParams.hashedParams,
            verifyParams.v,
            verifyParams.r,
            verifyParams.s,
            verifyParams.user
            ));
        return true;
    }

    function trade(TradeInput memory tradeInput, VerifyParams memory verifyParams) internal {
        tradeInput.srcToken.safeTransferFrom(verifyParams.user, address(this), tradeInput.srcQty);
        uint256 actualSrcQty;
        uint256 feeInSrcTokenWei;
        (actualSrcQty, feeInSrcTokenWei) = deductFee(tradeInput.srcQty, tradeInput.feeInPrecision);

        updateNonce(verifyParams.user, verifyParams.concatenatedTokenAddresses, verifyParams.nonce);
        uint256 destAmount = lyfeblocNetworkProxy.tradeWithHint(
            tradeInput.srcToken,
            actualSrcQty,
            tradeInput.destToken,
            tradeInput.destAddress,
            MAX_DEST_AMOUNT,
            tradeInput.minConversionRate,
            address(this), //walletId
            "PERM" //hint: only Permissioned reserves to be used
        );

        emit LimitOrderExecute(
            verifyParams.user,
            verifyParams.nonce,
            address(tradeInput.srcToken),
            actualSrcQty,
            destAmount,
            address(tradeInput.destToken),
            tradeInput.destAddress,
            feeInSrcTokenWei
        );
    }
}

pragma solidity 0.6.0;

import "./PermissionGroups.sol";
import "./SafeERC20.sol";

/**
 * @title Contracts that should be able to recover tokens or ethers can inherit this contract.
 * @dev Allows to recover any tokens or Ethers received in a contract.
 * Should prevent any accidental loss of tokens.
 */
contract Withdrawable is PermissionGroups {
    using SafeERC20 for ERC20;
    constructor(address _admin) public PermissionGroups (_admin) {}

    event TokenWithdraw(ERC20 token, uint amount, address sendTo);

    /**
     * @dev Withdraw all ERC20 compatible tokens
     * @param token ERC20 The address of the token contract
     */
    function withdrawToken(ERC20 token, uint amount, address sendTo) external onlyAdmin {
        token.safeTransfer(sendTo, amount);
        emit TokenWithdraw(token, amount, sendTo);
    }

    event EtherWithdraw(uint amount, address sendTo);

    /**
     * @dev Withdraw Ethers
     */
    function withdrawEther(uint amount, address payable sendTo) external onlyAdmin {
        sendTo.transfer(amount);
        emit EtherWithdraw(amount, sendTo);
    }
}

pragma solidity 0.6.0;

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
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
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
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

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
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
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
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
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
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

pragma solidity 0.6.0;

import "../ERC20Interface.sol";
import "./SafeMath.sol";
import "./Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(ERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves.

        // A Solidity high level call has three parts:
        //  1. The target address is checked to verify it contains contract code
        //  2. The call itself is made, and success asserted
        //  3. The return value is decoded, which in turn checks the size of the returned data.
        // solhint-disable-next-line max-line-length
        require(address(token).isContract(), "SafeERC20: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            // solhint-disable-next-line max-line-length
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

pragma solidity 0.6.0;

import "./ERC20Interface.sol";


interface LyfeblocNetworkProxyInterface {
    function tradeWithHint(ERC20 src, uint srcAmount, ERC20 dest, address payable destAddress, uint maxDestAmount,
        uint minConversionRate, address walletId, bytes calldata hint) external payable returns(uint);

    function maxGasPrice() external view returns(uint);
    function getUserCapInWei(address user) external view returns(uint);
    function getUserCapInTokenWei(address user, ERC20 token) external view returns(uint);
    function enabled() external view returns(bool);
    function info(bytes32 id) external view returns(uint);

    function getExpectedRate(ERC20 src, ERC20 dest, uint srcQty) external view
        returns (uint expectedRate, uint slippageRate);
}

pragma solidity 0.6.0;


contract PermissionGroups {

    address public admin;
    address public pendingAdmin;
    mapping(address=>bool) public operators;
    mapping(address=>bool) public alerters;

    constructor(address _admin) public {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin);
        _;
    }

    modifier onlyOperator() {
        require(operators[msg.sender]);
        _;
    }

    modifier onlyAlerter() {
        require(alerters[msg.sender]);
        _;
    }

    event TransferAdminPending(address pendingAdmin);

    /**
     * @dev Allows the current admin to set the pendingAdmin address.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdmin(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit TransferAdminPending(pendingAdmin);
        pendingAdmin = newAdmin;
    }

    /**
     * @dev Allows the current admin to set the admin in one tx. Useful initial deployment.
     * @param newAdmin The address to transfer ownership to.
     */
    function transferAdminQuickly(address newAdmin) public onlyAdmin {
        require(newAdmin != address(0));
        emit TransferAdminPending(newAdmin);
        emit AdminClaimed(newAdmin, admin);
        admin = newAdmin;
    }

    event AdminClaimed( address newAdmin, address previousAdmin);

    /**
     * @dev Allows the pendingAdmin address to finalize the change admin process.
     */
    function claimAdmin() public {
        require(pendingAdmin == msg.sender);
        emit AdminClaimed(pendingAdmin, admin);
        admin = pendingAdmin;
        pendingAdmin = address(0);
    }

    event AlerterAdded (address newAlerter, bool isAdd);

    function addAlerter(address newAlerter) public onlyAdmin {
        require(!alerters[newAlerter]); // prevent duplicates.
        alerters[newAlerter] = true;
        emit AlerterAdded(newAlerter, true);
    }

    function removeAlerter (address alerter) public onlyAdmin {
        require(alerters[alerter]);
        alerters[alerter] = false;
        emit AlerterAdded(alerter, false);
    }

    event OperatorAdded(address newOperator, bool isAdd);

    function addOperator(address newOperator) public onlyAdmin {
        require(!operators[newOperator]); // prevent duplicates.
        operators[newOperator] = true;
        emit OperatorAdded(newOperator, true);
    }

    function removeOperator (address operator) public onlyAdmin {
        require(operators[operator]);
        operators[operator] = false;
        emit OperatorAdded(operator, false);
    }
}

pragma solidity 0.6.0;

/**
 * @dev Collection of functions related to the address type,
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * This test is non-exhaustive, and there may be false-negatives: during the
     * execution of a contract's constructor, its address will be reported as
     * not containing a contract.
     *
     * > It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies in extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
    }
}

pragma solidity 0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see `ERC20Detailed`.
 */
interface ERC20 {
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
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * > Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}