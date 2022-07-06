//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "./Dependencies/CheckContract.sol";
import "./Dependencies/OwnableUpgradeable.sol";
import "./Dependencies/SafeMath.sol";
import "./Dependencies/IERC20.sol";
import "./Dependencies/TransferHelper.sol";

contract MultiSender is CheckContract, OwnableUpgradeable {

    mapping(address => uint256) public txCount;
    mapping(address => bool) public freeList;

    using SafeMath for uint256;
    using TransferHelper for address;
    using TransferHelper for IERC20;

    uint16 public arrayLimit;
    uint256 public feePerAccount;
    uint256 public discountStep;


    function initialize() public initializer {
        __Ownable_init();
        arrayLimit = 250;
        feePerAccount =  0.0005 ether;
        discountStep = 0.0005 ether;
    }

    function changeFeePerAccount(uint256 _newFeePerAccount) external onlyOwner {
        feePerAccount = _newFeePerAccount;
    }

    function changeArrayLimit(uint16 _newArrayLimit) external onlyOwner {
        arrayLimit = _newArrayLimit;
    }

    function changeDiscountStep(uint256 _newDiscountStep) external onlyOwner {
        discountStep = _newDiscountStep;
    }

    function addFreeList(address[] memory _accounts) external onlyOwner {
        for (uint256 _idx = 0; _idx < _accounts.length; _idx++) {
            freeList[_accounts[_idx]] = true;
        }
    }

    function removeFreeList(address[] memory _accounts) external onlyOwner {
        for (uint256 _idx = 0; _idx < _accounts.length; _idx++) {
            freeList[_accounts[_idx]] = false;
        }
    }

    function isFree(address _account) public view returns(bool) {
        return _account == owner() || freeList[_account];
    }

    function discountRate(address _customer) public view returns(uint256) {
        uint256 count = txCount[_customer];
        return count * discountStep;
    }

    function withdraw(address _to) external onlyOwner {
        require(_to != address(0), "can't withdraw to zero address");
        uint256 _balance = address(this).balance;
        address(_to).safeTransferETH(_balance);
    }

    function withdrawToken(address _token, address _to) external onlyOwner {
        require(_to != address(0), "can't withdraw to zero address");
        uint256 _balance = IERC20(_token).balanceOf(address(this));
        IERC20(_token).transfer(_to, _balance);
    }

    function setFeePerAccount(uint256 _feePerAccount) external onlyOwner {
        feePerAccount = _feePerAccount;
    }

    function multiSend(address _token, address[] memory _accounts, uint256[] memory _amounts, uint256 _totalAmount) public payable {
        _multiSend(_token, msg.sender, _accounts, _amounts, _totalAmount);
    }

    function multiSendSameValue(address _token, address[] memory _accounts, uint256 _amount, uint256 _totalAmount) public payable {
        _multiSendSameValue(_token, msg.sender, _accounts, _amount, _totalAmount);
    }

    function _multiSend(address _token, address _sourceAccount, address[] memory _accounts, uint256[] memory _amounts, uint256  _totalAmount) internal {
        require(_accounts.length == _amounts.length, "the accounts size and amounts size not equals");
        require(_accounts.length <= arrayLimit, "array size exceed the array limit");
        bool _free = isFree(_sourceAccount);
        uint256 _needPayFee = _requireEnoughFee(_sourceAccount, _accounts.length, _free);
        if(_token == address(0x0)) {
            _multiSendETH(_token, _accounts, _amounts, _totalAmount, _needPayFee);
        } else {
            _multiSendToken(_token, _sourceAccount, _accounts, _amounts, _totalAmount, _needPayFee);
        }
        txCount[_sourceAccount]++;
    }

    function _multiSendSameValue(address _token, address _sourceAccount, address[] memory _accounts, uint256 _amount, uint256 _totalAmount) internal {
        require(_accounts.length <= arrayLimit, "array size exceed the array limit");
        bool _free = isFree(_sourceAccount);
        uint256 _needPayFee = _requireEnoughFee(_sourceAccount, _accounts.length, _free);

        if(_token == address(0x0)) {
            _multiSendETHSameValue(_token, _accounts, _amount, _totalAmount, _needPayFee);
        } else {
            _multiSendTokenSameValue(_token, _sourceAccount, _accounts, _amount , _totalAmount, _needPayFee);
        }
        txCount[_sourceAccount]++;
    }

    function _multiSendToken(address _token, address _sourceAccount, address[] memory _accounts, uint256[] memory _amounts, uint256 _totalAmount, uint256 _needPayFee) internal {
        require(msg.value.sub( _needPayFee ) <= 0, "has no enough eth to transfer");
        uint256 _balance = IERC20(_token).balanceOf(_sourceAccount);
        require(_totalAmount <= _balance, "has no enough eth to transfer");

        for (uint256 _idx = 0; _idx < _accounts.length; _idx++) {
            IERC20(_token).safeTransferFrom(_sourceAccount, _accounts[_idx], _amounts[_idx]);
        }
    }

    function _multiSendETH(address _token, address[] memory _accounts, uint256[] memory _amounts, uint256 _totalAmount, uint256 _needPayFee) internal {
        require(_totalAmount <= msg.value.sub( _needPayFee ), "has no enough eth to transfer");
        for (uint256 _idx = 0; _idx < _accounts.length; _idx++) {
            address(_token).safeTransferToken(_accounts[_idx], _amounts[_idx]);
        }
    }

     function _multiSendTokenSameValue(address _token, address _sourceAccount, address[] memory _accounts, uint256 _amount, uint256 _totalAmount, uint256 _needPayFee) internal {
        require(msg.value.sub( _needPayFee ) <= 0, "has no enough eth to transfer");
        uint256 _balance = IERC20(_token).balanceOf(_sourceAccount);
        require(_totalAmount <= _balance, "has no enough token to transfer");
        for (uint256 _idx = 0; _idx < _accounts.length; _idx++) {
            IERC20(_token).safeTransferFrom(_sourceAccount, _accounts[_idx], _amount);
        }
    }

    function _multiSendETHSameValue(address _token, address[] memory _accounts, uint256 _amount, uint256 _totalAmount, uint256 _needPayFee) internal {
        require(_totalAmount <= msg.value.sub( _needPayFee ), "has no enough eth to transfer");
        for (uint256 _idx = 0; _idx < _accounts.length; _idx++) {
            address(_token).safeTransferToken(_accounts[_idx], _amount);
        }
    }

    function _requireEnoughFee(address _sourceAccount, uint256 _accountSize, bool _free) internal view returns (uint256) {
        if ( !_free ) {
            uint256 needPayFee = _currentFee( _sourceAccount, _accountSize, _free);
            require(msg.value >= needPayFee , "has no enough fee");
            return needPayFee;
        }
        return 0;
    }

    function _currentFee(address _sourceAccount, uint256 _accountSize, bool _free) internal view returns (uint256) {
        if( _free ) {
            return 0;
        }
        return feePerAccount.mul(_accountSize) - discountRate(_sourceAccount);
    }

    receive() external payable {
    }

}

// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity 0.8.15;

import "./IERC20.sol";

library TransferHelper {

    function safeTransferToken(
        address token,
        address to,
        uint value
    ) internal {
        if (token == address(0x0)) {
            safeTransferETH(to, value);
        } else {
            safeTransfer(IERC20(token), to, value);
        }
    }

    function safeTransferETH(
        address to,
        uint value
    ) internal {
        (bool success, ) = address(to).call{value: value}("");
        require(success, "TransferHelper: Sending ETH failed");
    }

    function balanceOf(address token, address addr) internal view returns (uint) {
        if (token == address(0x0)) {
            return addr.balance;
        } else {
            return IERC20(token).balanceOf(addr);
        }
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transfer(address,uint256)'))) -> 0xa9059cbb
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0xa9059cbb, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransfer: transfer failed'
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        // bytes4(keccak256(bytes('transferFrom(address,address,uint256)'))) -> 0x23b872dd
        (bool success, bytes memory data) = address(token).call(abi.encodeWithSelector(0x23b872dd, from, to, value));
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            'TransferHelper::safeTransferFrom: transfer failed'
        );
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

/**
 * Based on OpenZeppelin's SafeMath:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/math/SafeMath.sol
 *
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

    function pow(uint256 _base, uint256 _pow) internal pure returns (uint256) {
        uint256 max = 2**256 - 1;
        uint256 x = _base;
        uint256 y = 1;

        // the pow == 0 of zero is 1
        if (_pow == 0) {
            return 1;
        }

        // the pow > 0 of zero is 0
        if (_base == 0) {
            return 0;
        }

        while (_pow > 1) {
            if (_pow % 2 == 1) {
                max = max / x; // x * y <= max, when y update, the max will update
                y = y * x;
            }
            require((max / x) >= x, "SafeMath: pow value exceed max value"); // make sure y * x * x <= MAX_VALUE, will make sure y will not exceed MAX_VALUE
            x = x * x;
            _pow = _pow / 2;
        }

        return x * y;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;

import "./ContextUpgradeable.sol";
import "./Initializable.sol";
/**
 * Based on OpenZeppelin's Ownable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.3.0/contracts/access/OwnableUpgradeable.sol
 *
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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal initializer {
        __Context_init_unchained();
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal initializer {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity 0.8.15;


/**
 * Based on OpenZeppelin's Initializable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.3.0/contracts/proxy/Initializable.sol
 *
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        // extcodesize checks the size of the code stored in an address, and
        // address returns the current address. Since the code is still not
        // deployed when running a constructor, any checks on its code size will
        // yield zero, making it an effective way to detect if a contract is
        // under construction or not.
        address self = address(this);
        uint256 cs;
        // solhint-disable-next-line no-inline-assembly
        assembly { cs := extcodesize(self) }
        return cs == 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.15;

/**
 * Based on the OpenZeppelin IER20 interface:
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol
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

pragma solidity 0.8.15;
import "./Initializable.sol";

/*
 * Based on OpenZeppelin's ContextUpgradeable contract:
 * https://github.com/OpenZeppelin/openzeppelin-contracts-upgradeable/blob/v3.3.0/contracts/GSN/ContextUpgradeable.sol
 *
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal initializer {
        __Context_init_unchained();
    }

    function __Context_init_unchained() internal initializer {
    }
    function _msgSender() internal view virtual returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.15;


contract CheckContract {
    /**
     * Check that the account is an already deployed non-destroyed contract.
     * See: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/Address.sol#L12
     */
    function checkContract(address _account) internal view {
        require(_account != address(0), "Account cannot be zero address");

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        require(size > 0, "Account code size cannot be zero");
    }

    function isContract(address _account) internal view returns (bool) {
        if (_account == address(0)) { return false; }

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(_account) }
        return size > 0;
    }
}