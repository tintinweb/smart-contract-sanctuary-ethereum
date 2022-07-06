pragma solidity ^0.5.17;

import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract Token is IERC20 {
    function transferWithAuthorization(
        address from,
        address to,
        uint256 value,
        uint256 validAfter,
        uint256 validBefore,
        bytes32 nonce,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}


contract LocalCoinSwapV2Escrow {

    using SafeERC20 for Token;

    /***********************
    +       Globals        +
    ***********************/

    address public arbitrator;
    address public owner;
    address public relayer;

    uint16 public minimumTradeValue = 1; // Token

    struct Escrow {
      bool exists;
      uint128 totalGasFeesSpentByRelayer;
      address tokenContract;
    }

    mapping (bytes32 => Escrow) public escrows;
    mapping (address => uint256) public feesAvailableForWithdraw;

    uint256 MAX_INT = 2**256 - 1;

    /***********************
    +     Instructions     +
    ***********************/

    uint8 constant RELEASE_ESCROW = 0x01;
    uint8 constant BUYER_CANCELS = 0x02;
    uint8 constant RESOLVE_DISPUTE = 0x03;

    /***********************
    +       Events        +
    ***********************/

    event Created(bytes32 _tradeHash);
    event CancelledByBuyer(bytes32 _tradeHash, uint128 totalGasFeesSpentByRelayer);
    event Released(bytes32 _tradeHash, uint128 totalGasFeesSpentByRelayer);
    event DisputeResolved(bytes32 _tradeHash, uint128 totalGasFeesSpentByRelayer);

    /***********************
    +     Constructor      +
    ***********************/

    constructor(address initialAddress) public {
        owner = initialAddress;
        arbitrator = initialAddress;
        relayer = initialAddress;
    }

    /***********************
    +     Open Escrow     +
    ***********************/

    function createEscrow(
      bytes16 _tradeID,
      address _currency,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee, // Our fee in 1/10000ths of a token
      uint8 _v, // Signature value
      bytes32 _r, // Signature value
      bytes32 _s // Signature value
    ) external payable {
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeID, _seller, _buyer, _value, _fee));
        require(!escrows[_tradeHash].exists, "Trade already exists");
        bytes32 _invitationHash = keccak256(abi.encodePacked(_tradeHash));
        require(_value > minimumTradeValue, "Escrow value must be greater than minimum value"); // Check escrow value is greater than minimum value
        require(recoverAddress(_invitationHash, _v, _r, _s) == relayer, "Transaction signature did not come from relayer");

        Token(_currency).safeTransferFrom(msg.sender, address(this), _value);

        escrows[_tradeHash] = Escrow(true, 0, _currency);
        emit Created(_tradeHash);
    }

    function relayEscrow(
      bytes16 _tradeID,
      address _currency,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee, // Our fee in 1/10000ths of a token
      uint8 _v, // Signature value for trade invitation by LocalCoinSwap
      bytes32 _r, // Signature value for trade invitation by LocalCoinSwap
      bytes32 _s, // Signature value for trade invitation by LocalCoinSwp
      bytes32 _nonce, // Random nonce used for gasless send
      uint8 _v_gasless, // Signature value for GasLess send
      bytes32 _r_gasless, // Signature value for GasLess send
      bytes32 _s_gasless // Signature value for GasLess send
    ) external payable {
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeID, _seller, _buyer, _value, _fee));
        require(!escrows[_tradeHash].exists, "Trade already exists in escrow mapping");
        bytes32 _invitationHash = keccak256(abi.encodePacked(_tradeHash));
        require(_value > minimumTradeValue, "Escrow value must be greater than minimum value"); // Check escrow value is greater than minimum value
        require(recoverAddress(_invitationHash, _v, _r, _s) == relayer, "Transaction signature did not come from relayer");

        // Perform gasless send from seller to contract
        Token(_currency).transferWithAuthorization(
            msg.sender,
            address(this),
            _value,
            0,
            MAX_INT,
            _nonce,
            _v_gasless,
            _r_gasless,
            _s_gasless
        );

        escrows[_tradeHash] = Escrow(true, 0, _currency);
        emit Created(_tradeHash);
    }

    /***********************
    +   Complete Escrow    +
    ***********************/

    function release(
        bytes16 _tradeID,
        address payable _seller,
        address payable _buyer,
        uint256 _value,
        uint16 _fee
    ) external returns (bool){
        require(msg.sender == _seller, "Must be seller");
        return doRelease(_tradeID, _seller, _buyer, _value, _fee, 0);
    }

    uint16 constant GAS_doRelease = 3658;
    function doRelease(
        bytes16 _tradeID,
        address payable _seller,
        address payable _buyer,
        uint256 _value,
        uint16 _fee,
        uint128 _additionalGas
    ) private returns (bool) {
        Escrow memory _escrow;
        bytes32 _tradeHash;
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        if (!_escrow.exists) return false;
        uint128 _gasFees = _escrow.totalGasFeesSpentByRelayer + (msg.sender == relayer
                ? (GAS_doRelease + _additionalGas ) * uint128(tx.gasprice)
                : 0
            );
        delete escrows[_tradeHash];
        emit Released(_tradeHash, _gasFees);
        transferMinusFees(_escrow.tokenContract, _buyer, _value, _fee);
        return true;
    }

    uint16 constant GAS_doResolveDispute = 14060;
    function resolveDispute(
        bytes16 _tradeID,
        address payable _seller,
        address payable _buyer,
        uint256 _value,
        uint16 _fee,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint8 _buyerPercent
    ) external onlyArbitrator {
        address _signature = recoverAddress(keccak256(abi.encodePacked(
            _tradeID,
            RESOLVE_DISPUTE
        )), _v, _r, _s);
        require(_signature == _buyer || _signature == _seller, "Must be buyer or seller");

        Escrow memory _escrow;
        bytes32 _tradeHash;
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        require(_escrow.exists, "Escrow does not exist");
        require(_buyerPercent <= 100, "_buyerPercent must be 100 or lower");

        _escrow.totalGasFeesSpentByRelayer += (GAS_doResolveDispute * uint128(tx.gasprice));

        delete escrows[_tradeHash];
        emit DisputeResolved(_tradeHash, _escrow.totalGasFeesSpentByRelayer);
        if (_buyerPercent > 0) {
          // If dispute goes to buyer take the fee
          uint256 _totalFees = (_value * _fee / 10000);
          // Prevent underflow
          require(_value * _buyerPercent / 100 - _totalFees <= _value, "Overflow error");
          feesAvailableForWithdraw[_escrow.tokenContract] += _totalFees;
          Token(_escrow.tokenContract).safeTransfer(_buyer, _value * _buyerPercent / 100 - _totalFees);
        }
        if (_buyerPercent < 100) {
          Token(_escrow.tokenContract).safeTransfer(_seller, _value * (100 - _buyerPercent) / 100);
        }
    }

    function buyerCancel(
      bytes16 _tradeID,
      address payable _seller,
      address payable _buyer,
      uint256 _value,
      uint16 _fee
    ) external returns (bool) {
        require(msg.sender == _buyer, "Must be buyer");
        return doBuyerCancel(_tradeID, _seller, _buyer, _value, _fee, 0);
    }

    function increaseGasSpent(bytes32 _tradeHash, uint128 _gas) private {
        escrows[_tradeHash].totalGasFeesSpentByRelayer += _gas * uint128(tx.gasprice);
    }

    uint16 constant GAS_doBuyerCancel = 2367;
    function doBuyerCancel(
        bytes16 _tradeID,
        address payable _seller,
        address payable _buyer,
        uint256 _value,
        uint16 _fee,
        uint128 _additionalGas
    ) private returns (bool) {
        Escrow memory _escrow;
        bytes32 _tradeHash;
        (_escrow, _tradeHash) = getEscrowAndHash(_tradeID, _seller, _buyer, _value, _fee);
        require(_escrow.exists, "Escrow does not exist");
        if (!_escrow.exists) {
            return false;
        }
        uint128 _gasFees = _escrow.totalGasFeesSpentByRelayer + (msg.sender == relayer
                ? (GAS_doBuyerCancel + _additionalGas ) * uint128(tx.gasprice)
                : 0
            );
        delete escrows[_tradeHash];
        emit CancelledByBuyer(_tradeHash, _gasFees);
        transferMinusFees(_escrow.tokenContract, _seller, _value, 0);
        return true;
    }

    /***********************
    +        Relays        +
    ***********************/

    uint16 constant GAS_batchRelayBaseCost = 30000;
    function batchRelay(
        bytes16[] memory _tradeID,
        address payable[] memory _seller,
        address payable[] memory _buyer,
        uint256[] memory _value,
        uint16[] memory _fee,
        uint128[] memory _maximumGasPrice,
        uint8[] memory _v,
        bytes32[] memory _r,
        bytes32[] memory _s,
        uint8[] memory _instructionByte
    ) public returns (bool[] memory) {
        bool[] memory _results = new bool[](_tradeID.length);
        uint128 _additionalGas = uint128(msg.sender == relayer ? GAS_batchRelayBaseCost / _tradeID.length : 0);
        for (uint8 i = 0; i < _tradeID.length; i++) {
            _results[i] = relay(
                _tradeID[i],
                _seller[i],
                _buyer[i],
                _value[i],
                _fee[i],
                _maximumGasPrice[i],
                _v[i],
                _r[i],
                _s[i],
                _instructionByte[i],
                _additionalGas
            );
        }
        return _results;
    }

    function relay(
        bytes16 _tradeID,
        address payable _seller,
        address payable _buyer,
        uint256 _value,
        uint16 _fee,
        uint128 _maximumGasPrice,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint8 _instructionByte,
        uint128 _additionalGas
    ) public returns (bool) {
        address _relayedSender = getRelayedSender(
            _tradeID,
            _instructionByte,
            _maximumGasPrice,
            _v,
            _r,
            _s
        );
        if (_relayedSender == _buyer) {
            if (_instructionByte == BUYER_CANCELS) {
                return doBuyerCancel(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
            }
        } else if (_relayedSender == _seller) {
            if (_instructionByte == RELEASE_ESCROW) {
                return doRelease(_tradeID, _seller, _buyer, _value, _fee, _additionalGas);
            }
        } else {
            require(msg.sender == _seller, "Unrecognised party");
            return false;
        }
    }

    /***********************
    +      Management      +
    ***********************/

    function setArbitrator(address _newArbitrator) external onlyOwner {
        arbitrator = _newArbitrator;
    }

    function setOwner(address _newOwner) external onlyOwner {
        owner = _newOwner;
    }

    function setRelayer(address _newRelayer) external onlyOwner {
        relayer = _newRelayer;
    }

    function setMinimumValue(uint16 _newMinimumValue) external onlyOwner {
        minimumTradeValue = _newMinimumValue;
    }

    /***********************
    +   Helper Functions   +
    ***********************/

    function transferMinusFees(
        address _currency,
        address payable _to,
        uint256 _value,
        uint16 _fee
    ) private {
        uint256 _totalFees = (_value * _fee / 10000);
        // Prevent underflow
        if(_value - _totalFees > _value) {
            return;
        }
        // Add fees to the pot for localcoinswap to withdraw
        feesAvailableForWithdraw[_currency] += _totalFees;
        Token(_currency).safeTransfer(_to, _value - _totalFees);
    }

    function withdrawFees(address payable _to, address _currency, uint256 _amount) external onlyOwner {
        // This check also prevents underflow
        require(_amount <= feesAvailableForWithdraw[_currency], "Amount is higher than amount available");
        feesAvailableForWithdraw[_currency] -= _amount;
        Token(_currency).safeTransfer(_to, _amount);
    }

    function getEscrowAndHash(
      bytes16 _tradeID,
      address _seller,
      address _buyer,
      uint256 _value,
      uint16 _fee
    ) private view returns (Escrow storage, bytes32) {
        bytes32 _tradeHash = keccak256(abi.encodePacked(_tradeID, _seller, _buyer, _value, _fee));
        return (escrows[_tradeHash], _tradeHash);
    }

    function recoverAddress(
        bytes32 _h,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private pure returns (address) {
        bytes memory _prefix = "\x19Ethereum Signed Message:\n32";
        bytes32 _prefixedHash = keccak256(abi.encodePacked(_prefix, _h));
        return ecrecover(_prefixedHash, _v, _r, _s);
    }

    function getRelayedSender(
      bytes16 _tradeID,
      uint8 _instructionByte,
      uint128 _maximumGasPrice,
      uint8 _v,
      bytes32 _r,
      bytes32 _s
    ) private view returns (address) {
        bytes32 _hash = keccak256(abi.encodePacked(_tradeID, _instructionByte, _maximumGasPrice));
        require(tx.gasprice < _maximumGasPrice, "Gas price is higher than maximum gas price");
        return recoverAddress(_hash, _v, _r, _s);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only the current owner can change the owner");
        _;
    }

    modifier onlyArbitrator() {
        require(msg.sender == arbitrator, "Only the current owner can change the arbitrator");
        _;
    }
}

pragma solidity ^0.5.0;

import "./IERC20.sol";
import "../../math/SafeMath.sol";
import "../../utils/Address.sol";

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

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        // solhint-disable-next-line max-line-length
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function callOptionalReturn(IERC20 token, bytes memory data) private {
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

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

pragma solidity ^0.5.0;

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
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
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
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
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
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
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
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

pragma solidity ^0.5.5;

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
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }

    /**
     * @dev Converts an `address` into `address payable`. Note that this is
     * simply a type cast: the actual underlying value is not changed.
     *
     * _Available since v2.4.0._
     */
    function toPayable(address account) internal pure returns (address payable) {
        return address(uint160(account));
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
     *
     * _Available since v2.4.0._
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-call-value
        (bool success, ) = recipient.call.value(amount)("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}