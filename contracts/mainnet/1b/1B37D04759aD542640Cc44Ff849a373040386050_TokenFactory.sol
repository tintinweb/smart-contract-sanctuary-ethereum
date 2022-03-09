/**
 *Submitted for verification at Etherscan.io on 2022-03-09
*/

// SPDX-License-Identifier: UNLICENSED

// File: contracts/abstract/FundDistribution.sol
pragma solidity 0.8.9;

/**
 * @title Fund Distribution interface that could be used by other contracts to reference
 * TokenFactory/MasterChef in order to enable minting/rewarding to a designated fund address.
 */
interface FundDistribution {
    /**
     * @dev an operation that triggers reward distribution by minting to the designated address
     * from TokenFactory. The fund address must be already configured in TokenFactory to receive
     * funds, else no funds will be retrieved.
     */
    function sendReward(address _fundAddress) external returns (bool);
}

// File: contracts/abstract/IERC20.sol


pragma solidity 0.8.9;

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



// File: contracts/abstract/Context.sol


pragma solidity 0.8.9;

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with GSN meta-transactions the account sending and
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



// File: contracts/abstract/Ownable.sol


pragma solidity 0.8.9;


// Part: OpenZeppelin/[email protected]/Ownable

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
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
    constructor () {
        _transferOwnership(_msgSender());
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
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/abstract/SafeMath.sol


pragma solidity 0.8.9;

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



// File: contracts/abstract/Address.sol


pragma solidity 0.8.9;

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
        // solhint-disable-next-line no-inline-assembly
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
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
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.3._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) private pure returns (bytes memory) {
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



// File: contracts/abstract/ERC20.sol


pragma solidity 0.8.9;





/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin guidelines: functions revert instead
 * of returning `false` on failure. This behavior is nonetheless conventional
 * and does not conflict with the expectations of ERC20 applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
abstract contract ERC20 is Context, IERC20 {

    using SafeMath for uint256;
    using Address for address;

    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    /**
     * @dev Sets the values for {name} and {symbol}, initializes {decimals} with
     * a default value of 18.
     *
     * To select a different value for {decimals}, use {_setupDecimals}.
     *
     * All three of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory tokenName, string memory tokenSymbol) {
        _name = tokenName;
        _symbol = tokenSymbol;
        _decimals = 18;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5,05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless {_setupDecimals} is
     * called.
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public override view returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        virtual
        override
        view
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20};
     *
     * Requirements:
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    /**
     * @dev Moves tokens `amount` from `sender` to `recipient`.
     *
     * This is internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        _balances[sender] = _balances[sender].sub(
            amount,
            "ERC20: transfer amount exceeds balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements
     *
     * - `to` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply = _totalSupply.add(amount);
        _balances[account] = _balances[account].add(amount);
        emit Transfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        _balances[account] = _balances[account].sub(
            amount,
            "ERC20: burn amount exceeds balance"
        );
        _totalSupply = _totalSupply.sub(amount);
        emit Transfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Sets {decimals} to a value other than the default one of 18.
     *
     * WARNING: This function should only be called from the constructor. Most
     * applications that interact with token contracts will not expect
     * {decimals} to ever change, and may work incorrectly if it does.
     */
    function _setupDecimals(uint8 decimals_) internal {
        _decimals = decimals_;
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be to transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// File: contracts/abstract/MeedsToken.sol


pragma solidity 0.8.9;



contract MeedsToken is ERC20("Meeds Token", "MEED"), Ownable {
    /// @notice Creates `_amount` token to `_to`. Must only be called by the owner (TokenFactory).
    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }
}

// File: contracts/abstract/SafeERC20.sol


pragma solidity 0.8.9;





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
    using SafeMath for uint256;
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        // solhint-disable-next-line max-line-length
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(
            value
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(
            value,
            "SafeERC20: decreased allowance below zero"
        );
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            // solhint-disable-next-line max-line-length
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// File: contracts/TokenFactory.sol


pragma solidity 0.8.9;







/**
 * @dev This contract will send MEED rewards to multiple funds by minting on MEED contract.
 * Since it is the only owner of the MEED Token, all minting operations will be exclusively
 * made here.
 * This contract will mint for the 3 type of Rewarding mechanisms as described in MEED white paper:
 * - Liquidity providers through renting and buying liquidity pools
 * - User Engagment within the software
 * - Work / services  provided by association members to build the DOM
 * 
 * In other words, MEEDs are created based on the involvment of three different categories
 * of stake holders:
 * - the capital owners
 * - the users
 * - the builders
 * 
 * Consequently, there will be two kind of Fund Contracts that will be managed by this one:
 * - ERC20 LP Token contracts: this contract will reward LP Token stakers
 * with a proportion of minted MEED per minute
 * - Fund contract : which will receive a proportion of minted MEED (unlike LP Token contract)
 *  to make the distribution switch its internal algorithm.
 */
contract TokenFactory is Ownable, FundDistribution {

    using SafeMath for uint256;
    using SafeERC20 for IERC20;
    using Address for address;

    // Info of each user who staked LP Tokens
    struct UserInfo {
        uint256 amount; // How many LP tokens the user has staked
        uint256 rewardDebt; // How much MEED rewards the user had received
    }

    // Info of each fund
    // A fund can be either a Fund that will receive Minted MEED
    // to use its own rewarding distribution strategy or a Liquidity Pool.
    struct FundInfo {
        uint256 fixedPercentage; // How many fixed percentage of minted MEEDs will be sent to this fund contract
        uint256 allocationPoint; // How many allocation points assigned to this pool comparing to other pools
        uint256 lastRewardTime; // Last block timestamp that MEEDs distribution has occurred
        uint256 accMeedPerShare; // Accumulated MEEDs per share: price of LP Token comparing to 1 MEED (multiplied by 10^12 to make the computation more precise)
        bool isLPToken; // // The Liquidity Pool rewarding distribution will be handled by this contract
        // in contrary to a simple Fund Contract which will manage distribution by its own and thus, receive directly minted MEEDs.
    }

    // Since, the minting privilege is exclusively hold
    // by the current contract and it's not transferable,
    // this will be the absolute Maximum Supply of all MEED Token.
    uint256 public constant MAX_MEED_SUPPLY = 1e26;

    uint256 public constant MEED_REWARDING_PRECISION = 1e12;

    // The MEED TOKEN!
    MeedsToken public meed;

    // MEEDs minted per minute
    uint256 public meedPerMinute;

    // List of fund addresses
    address[] public fundAddresses;

    // Info of each pool
    mapping(address => FundInfo) public fundInfos;

    // Info of each user that stakes LP tokens
    mapping(address => mapping(address => UserInfo)) public userLpInfos;

    // Total allocation points. Must be the sum of all allocation points in all pools.
    uint256 public totalAllocationPoints = 0;
    // Total fixed percentage. Must be the sum of all allocation points in all pools.
    uint256 public totalFixedPercentage = 0;

    // The block time when MEED mining starts
    uint256 public startRewardsTime;

    // LP Operations Events
    event Deposit(address indexed user, address indexed lpAddress, uint256 amount);
    event Withdraw(address indexed user, address indexed lpAddress, uint256 amount);
    event EmergencyWithdraw(address indexed user, address indexed lpAddress, uint256 amount);
    event Harvest(address indexed user, address indexed lpAddress, uint256 amount);

    // Fund Events
    event FundAdded(address indexed fundAddress, uint256 allocation, bool fixedPercentage, bool isLPToken);
    event FundAllocationChanged(address indexed fundAddress, uint256 allocation, bool fixedPercentage);

    // Max MEED Supply Reached
    event MaxSupplyReached(uint256 timestamp);

    constructor (
        MeedsToken _meed,
        uint256 _meedPerMinute,
        uint256 _startRewardsTime
    ) {
        meed = _meed;
        meedPerMinute = _meedPerMinute;
        startRewardsTime = _startRewardsTime;
    }

    /**
     * @dev changes the rewarded MEEDs per minute
     */
    function setMeedPerMinute(uint256 _meedPerMinute) external onlyOwner {
        require(_meedPerMinute > 0, "TokenFactory#setMeedPerMinute: _meedPerMinute must be strictly positive integer");
        meedPerMinute = _meedPerMinute;
    }

    /**
     * @dev add a new Fund Address. The address must be an ERC20 LP Token contract address.
     * 
     * The proportion of MEED rewarding can be fixed (30% by example) or variable (using allocationPoints).
     * The allocationPoint will determine the proportion (percentage) of MEED rewarding that a fund will take
     * comparing to other funds using the same percentage mechanism.
     * 
     * The computing of percentage using allocationPoint mechanism is as following:
     * Allocation percentage = allocationPoint / totalAllocationPoints * (100 - totalFixedPercentage)
     * 
     * The computing of percentage using fixedPercentage mechanism is as following:
     * Allocation percentage = fixedPercentage
     * 
     * If the rewarding didn't started yet, no fund address will receive rewards.
     * 
     * See {sendReward} method for more details.
     */
    function addLPToken(IERC20 _lpToken, uint256 _value, bool _isFixedPercentage) external onlyOwner {
        require(address(_lpToken).isContract(), "TokenFactory#addLPToken: _fundAddress must be an ERC20 Token Address");
        _addFund(address(_lpToken), _value, _isFixedPercentage, true);
    }

    /**
     * @dev add a new Fund Address. The address can be a contract that will receive
     * funds and distribute MEED earnings switch a specific algorithm (User and/or Employee Engagement Program,
     * DAO, xMEED staking...)
     * 
     * The proportion of MEED rewarding can be fixed (30% by example) or variable (using allocationPoints).
     * The allocationPoint will determine the proportion (percentage) of MEED rewarding that a fund will take
     * comparing to other funds using the same percentage mechanism.
     * 
     * The computing of percentage using allocationPoint mechanism is as following:
     * Allocation percentage = allocationPoint / totalAllocationPoints * (100 - totalFixedPercentage)
     * 
     * The computing of percentage using fixedPercentage mechanism is as following:
     * Allocation percentage = fixedPercentage
     * 
     * If the rewarding didn't started yet, no fund will receive rewards.
     * 
     * See {sendReward} method for more details.
     */
    function addFund(address _fundAddress, uint256 _value, bool _isFixedPercentage) external onlyOwner {
        _addFund(_fundAddress, _value, _isFixedPercentage, false);
    }

    /**
     * @dev Updates the allocated rewarding ratio to the ERC20 LPToken or Fund address.
     * See #addLPToken and #addFund for more information.
     */
    function updateAllocation(address _fundAddress, uint256 _value, bool _isFixedPercentage) external onlyOwner {
        FundInfo storage fund = fundInfos[_fundAddress];
        require(fund.lastRewardTime > 0, "TokenFactory#updateAllocation: _fundAddress isn't a recognized LPToken nor a fund address");

        sendReward(_fundAddress);

        if (_isFixedPercentage) {
            require(fund.accMeedPerShare == 0, "TokenFactory#setFundAllocation Error: can't change fund percentage from variable to fixed");
            totalFixedPercentage = totalFixedPercentage.sub(fund.fixedPercentage).add(_value);
            require(totalFixedPercentage <= 100, "TokenFactory#setFundAllocation: total percentage can't be greater than 100%");
            fund.fixedPercentage = _value;
            totalAllocationPoints = totalAllocationPoints.sub(fund.allocationPoint);
            fund.allocationPoint = 0;
        } else {
            require(!fund.isLPToken || fund.fixedPercentage == 0, "TokenFactory#setFundAllocation Error: can't change Liquidity Pool percentage from fixed to variable");
            totalAllocationPoints = totalAllocationPoints.sub(fund.allocationPoint).add(_value);
            fund.allocationPoint = _value;
            totalFixedPercentage = totalFixedPercentage.sub(fund.fixedPercentage);
            fund.fixedPercentage = 0;
        }
        emit FundAllocationChanged(_fundAddress, _value, _isFixedPercentage);
    }

    /**
     * @dev update all fund allocations and send minted MEED
     * See {sendReward} method for more details.
     */
    function sendAllRewards() external {
        uint256 length = fundAddresses.length;
        for (uint256 index = 0; index < length; index++) {
            sendReward(fundAddresses[index]);
        }
    }

    /**
     * @dev update designated fund allocations and send minted MEED
     * See {sendReward} method for more details.
     */
    function batchSendRewards(address[] memory _fundAddresses) external {
        uint256 length = _fundAddresses.length;
        for (uint256 index = 0; index < length; index++) {
            sendReward(fundAddresses[index]);
        }
    }

    /**
     * @dev update designated fund allocation and send minted MEED.
     * 
     * @param _fundAddress The address can be an LP Token or another contract
     * that will receive funds and distribute MEED earnings switch a specific algorithm
     * (User and/or Employee Engagement Program, DAO, xMEED staking...)
     * 
     * The proportion of MEED rewarding can be fixed (30% by example) or variable (using allocationPoints).
     * The allocationPoint will determine the proportion (percentage) of MEED rewarding that a fund will take
     * comparing to other funds using the same percentage mechanism.
     * 
     * The computing of percentage using allocationPoint mechanism is as following:
     * Allocation percentage = allocationPoint / totalAllocationPoints * (100 - totalFixedPercentage)
     * 
     * The computing of percentage using fixedPercentage mechanism is as following:
     * Allocation percentage = fixedPercentage
     * 
     * If the rewarding didn't started yet, no fund will receive rewards.
     * 
     * For LP Token funds, the reward distribution per wallet will be managed in this contract,
     * thus, by calling this method, the LP Token rewards will be sent to this contract and then
     * the reward distribution can be claimed wallet by wallet by using method {harvest}, {deposit}
     * or {withdraw}.
     * for other type of funds, the Rewards will be sent directly to the contract/wallet address
     * to manage Reward distribution to wallets switch its specific algorithm outside this contract.
     */
    function sendReward(address _fundAddress) public override returns (bool) {
        // Minting didn't started yet
        if (block.timestamp < startRewardsTime) {
            return true;
        }

        FundInfo storage fund = fundInfos[_fundAddress];
        require(fund.lastRewardTime > 0, "TokenFactory#sendReward: _fundAddress isn't a recognized LPToken nor a fund address");

        uint256 pendingRewardAmount = _pendingRewardBalanceOf(fund);
        if (fund.isLPToken) {
          fund.accMeedPerShare = _getAccMeedPerShare(_fundAddress, pendingRewardAmount);
          _mint(address(this), pendingRewardAmount);
        } else {
          _mint(_fundAddress, pendingRewardAmount);
        }
        fund.lastRewardTime = block.timestamp;
        return true;
    }

    /**
     * @dev a wallet will stake an LP Token amount to an already configured address
     * (LP Token address).
     * 
     * When staking LP Tokens, the pending MEED rewards will be sent to current wallet
     * and LP Token will be staked in current contract address.
     * The LP Farming algorithm is inspired from ERC-2917 Demo:
     * 
     * https://github.com/gnufoo/ERC2917-Proposal/blob/master/contracts/ERC2917.sol
     */
    function deposit(IERC20 _lpToken, uint256 _amount) public {
        address _lpAddress = address(_lpToken);
        FundInfo storage fund = fundInfos[_lpAddress];
        require(fund.isLPToken, "TokenFactory#deposit Error: Liquidity Pool doesn't exist");

        // Update & Mint MEED for the designated pool
        // to ensure systematically to have enough
        // MEEDs balance in current contract
        sendReward(_lpAddress);

        UserInfo storage user = userLpInfos[_lpAddress][msg.sender];
        if (user.amount > 0) {
            uint256 pending = user
                .amount
                .mul(fund.accMeedPerShare).div(MEED_REWARDING_PRECISION)
                .sub(user.rewardDebt);
            _safeMeedTransfer(msg.sender, pending);
        }
        IERC20(_lpAddress).safeTransferFrom(address(msg.sender), address(this), _amount);
        user.amount = user.amount.add(_amount);
        user.rewardDebt = user.amount.mul(fund.accMeedPerShare).div(MEED_REWARDING_PRECISION);
        emit Deposit(msg.sender, _lpAddress, _amount);
    }

    /**
     * @dev a wallet will withdraw an amount of already staked LP Tokens.
     * 
     * When this operation is triggered, the pending MEED rewards will be sent to current wallet
     * and LP Token will be send back to caller address from current contract balance of staked LP Tokens.
     * The LP Farming algorithm is inspired from ERC-2917 Demo:
     * https://github.com/gnufoo/ERC2917-Proposal/blob/master/contracts/ERC2917.sol
     * 
     * If the amount of withdrawn LP Tokens is 0, only {harvest}ing the pending reward will be made.
     */
    function withdraw(IERC20 _lpToken, uint256 _amount) public {
        address _lpAddress = address(_lpToken);
        FundInfo storage fund = fundInfos[_lpAddress];
        require(fund.isLPToken, "TokenFactory#withdraw Error: Liquidity Pool doesn't exist");

        // Update & Mint MEED for the designated pool
        // to ensure systematically to have enough
        // MEEDs balance in current contract
        sendReward(_lpAddress);

        UserInfo storage user = userLpInfos[_lpAddress][msg.sender];
        // Send pending MEED Reward to user
        uint256 pendingUserReward = user.amount.mul(fund.accMeedPerShare).div(1e12).sub(
            user.rewardDebt
        );
        _safeMeedTransfer(msg.sender, pendingUserReward);
        user.amount = user.amount.sub(_amount);
        user.rewardDebt = user.amount.mul(fund.accMeedPerShare).div(1e12);

        if (_amount > 0) {
          // Send pending Reward
          IERC20(_lpAddress).safeTransfer(address(msg.sender), _amount);
          emit Withdraw(msg.sender, _lpAddress, _amount);
        } else {
          emit Harvest(msg.sender, _lpAddress, pendingUserReward);
        }
    }

    /**
     * @dev Withdraw without caring about rewards. EMERGENCY ONLY.
     */
    function emergencyWithdraw(IERC20 _lpToken) public {
        address _lpAddress = address(_lpToken);
        FundInfo storage fund = fundInfos[_lpAddress];
        require(fund.isLPToken, "TokenFactory#emergencyWithdraw Error: Liquidity Pool doesn't exist");

        UserInfo storage user = userLpInfos[_lpAddress][msg.sender];
        uint256 amount = user.amount;
        user.amount = 0;
        user.rewardDebt = 0;

        IERC20(_lpAddress).safeTransfer(address(msg.sender), amount);
        emit EmergencyWithdraw(msg.sender, _lpAddress, amount);
    }

    /**
     * @dev Claim reward for current wallet from designated Liquidity Pool
     */
    function harvest(IERC20 _lpAddress) public {
        withdraw(_lpAddress, 0);
    }

    function fundsLength() public view returns (uint256) {
        return fundAddresses.length;
    }

    /**
     * @dev returns the pending amount of wallet rewarding from LP Token Fund.
     * this operation is possible only when the LP Token address is an ERC-20 Token.
     * If the rewarding program didn't started yet, 0 will be returned.
     */
    function pendingRewardBalanceOf(IERC20 _lpToken, address _user) public view returns (uint256) {
        address _lpAddress = address(_lpToken);
        if (block.timestamp < startRewardsTime) {
            return 0;
        }
        FundInfo storage fund = fundInfos[_lpAddress];
        if (!fund.isLPToken) {
            return 0;
        }
        uint256 pendingRewardAmount = _pendingRewardBalanceOf(fund);
        uint256 accMeedPerShare = _getAccMeedPerShare(_lpAddress, pendingRewardAmount);
        UserInfo storage user = userLpInfos[_lpAddress][_user];
        return user.amount.mul(accMeedPerShare).div(MEED_REWARDING_PRECISION).sub(user.rewardDebt);
    }

    /**
     * @dev returns the pending amount of MEED rewarding for a designated Fund address.
     * See {sendReward} method for more details.
     */
    function pendingRewardBalanceOf(address _fundAddress) public view returns (uint256) {
        if (block.timestamp < startRewardsTime) {
            return 0;
        }
        return _pendingRewardBalanceOf(fundInfos[_fundAddress]);
    }

    /**
     * @dev add a new Fund Address. The address can be an LP Token or another contract
     * that will receive funds and distribute MEED earnings switch a specific algorithm
     * (User and/or Employee Engagement Program, DAO, xMEED staking...)
     * 
     * The proportion of MEED rewarding can be fixed (30% by example) or variable (using allocationPoints).
     * The allocationPoint will determine the proportion (percentage) of MEED rewarding that a fund will take
     * comparing to other funds using the same percentage mechanism.
     * 
     * The computing of percentage using allocationPoint mechanism is as following:
     * Allocation percentage = allocationPoint / totalAllocationPoints * (100 - totalFixedPercentage)
     * 
     * The computing of percentage using fixedPercentage mechanism is as following:
     * Allocation percentage = fixedPercentage
     * 
     * If the rewarding didn't started yet, no fund will receive rewards.
     * 
     * See {sendReward} method for more details.
     */
    function _addFund(address _fundAddress, uint256 _value, bool _isFixedPercentage, bool _isLPToken) private {
        require(fundInfos[_fundAddress].lastRewardTime == 0, "TokenFactory#_addFund : Fund address already exists, use #setFundAllocation to change allocation");

        uint256 lastRewardTime = block.timestamp > startRewardsTime ? block.timestamp : startRewardsTime;

        fundAddresses.push(_fundAddress);
        fundInfos[_fundAddress] = FundInfo({
          lastRewardTime: lastRewardTime,
          isLPToken: _isLPToken,
          allocationPoint: 0,
          fixedPercentage: 0,
          accMeedPerShare: 0
        });

        if (_isFixedPercentage) {
            totalFixedPercentage = totalFixedPercentage.add(_value);
            fundInfos[_fundAddress].fixedPercentage = _value;
            require(totalFixedPercentage <= 100, "TokenFactory#_addFund: total percentage can't be greater than 100%");
        } else {
            totalAllocationPoints = totalAllocationPoints.add(_value);
            fundInfos[_fundAddress].allocationPoint = _value;
        }
        emit FundAdded(_fundAddress, _value, _isFixedPercentage, _isLPToken);
    }

    function _getMultiplier(uint256 _fromTimestamp, uint256 _toTimestamp) internal view returns (uint256) {
        return _toTimestamp.sub(_fromTimestamp).mul(meedPerMinute).div(1 minutes);
    }

    function _pendingRewardBalanceOf(FundInfo memory _fund) internal view returns (uint256) {
        uint256 periodTotalMeedRewards = _getMultiplier(_fund.lastRewardTime, block.timestamp);
        if (_fund.fixedPercentage > 0) {
          return periodTotalMeedRewards
            .mul(_fund.fixedPercentage)
            .div(100);
        } else if (_fund.allocationPoint > 0) {
          return periodTotalMeedRewards
            .mul(_fund.allocationPoint)
            .mul(100 - totalFixedPercentage)
            .div(totalAllocationPoints)
            .div(100);
        }
        return 0;
    }

    function _getAccMeedPerShare(address _lpAddress, uint256 pendingRewardAmount) internal view returns (uint256) {
        FundInfo memory fund = fundInfos[_lpAddress];
        if (block.timestamp > fund.lastRewardTime) {
            uint256 lpSupply = IERC20(_lpAddress).balanceOf(address(this));
            if (lpSupply > 0) {
              return fund.accMeedPerShare.add(pendingRewardAmount.mul(MEED_REWARDING_PRECISION).div(lpSupply));
            }
        }
        return fund.accMeedPerShare;
    }

    function _safeMeedTransfer(address _to, uint256 _amount) internal {
        uint256 meedBal = meed.balanceOf(address(this));
        if (_amount > meedBal) {
            meed.transfer(_to, meedBal);
        } else {
            meed.transfer(_to, _amount);
        }
    }

    function _mint(address _to, uint256 _amount) internal {
        uint256 totalSupply = meed.totalSupply();
        if (totalSupply.add(_amount) > MAX_MEED_SUPPLY) {
            if (MAX_MEED_SUPPLY > totalSupply) {
              uint256 remainingAmount = MAX_MEED_SUPPLY.sub(totalSupply);
              meed.mint(_to, remainingAmount);
              emit MaxSupplyReached(block.timestamp);
            }
        } else {
            meed.mint(_to, _amount);
        }
    }

}