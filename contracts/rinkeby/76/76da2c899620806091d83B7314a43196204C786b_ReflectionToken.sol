// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Address.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ReflectionToken is ERC20, Ownable {
    using Address for address;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    uint256 private _simpleTokenTotal;
    uint256 private _reflectionPoolTotal;
    uint16 private _taxRate; // Tax rate, represented as hundredths of a percent, e.g 100 = 1%
    uint256 private _totalFeesDeducted;
    uint256 private _totalReflectionFeesDeducted;

    mapping(address => uint256) private _reflectionPoolBalances;
    mapping(address => uint256) private _simpleTokenBalances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcluded;

    uint256 private _excludedTokenAmount;
    uint256 private _excludedReflectionAmount;

    event TaxRateChange(uint16 newTaxRate);
    event ExcludeAccount(address indexed excludedAccount);
    event IncludeAccount(address indexed includedAccount);

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 decimals_,
        uint256 initialSupply_,
        uint16 initialTaxRate_
    ) ERC20(name_, symbol_) {
        _decimals = decimals_;
        _taxRate = initialTaxRate_;
        _reflectionPoolTotal = type(uint256).max;
        _reflectionPoolBalances[_msgSender()] = type(uint256).max;
        _simpleTokenTotal = initialSupply_; //5_000_000_000 * (10**_decimals); /// 5 billion tokens
        emit Transfer(address(0), _msgSender(), _simpleTokenTotal);
    }

    /** @dev Calculate the balance of the given address
    * @param account The address holding the tokens
    * @return The balance of the given address
    If an excluded account, simply return a balance from the simple token balances
    Otherwise, calculate the token balance based on the account's reflection pool balance    
    */
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        if (_isExcluded[account]) return _simpleTokenBalances[account];
        return
            _tokenFromReflection(_reflectionPoolBalances[account], getRate());
    }

    /** @dev Returns the total number of tokens.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _simpleTokenTotal;
    }

    /** @dev Return true if the `account` is excluded from the reflection tax system
     * @param account The address of the account
     */
    function isExcluded(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    /** @dev Return the initial reflection pool amount */
    function initialReflectionPool() public pure returns (uint256) {
        return type(uint256).max;
    }

    function reflectionPoolTotal() public view returns (uint256) {
        return _reflectionPoolTotal;
    }

    /** @dev Return the total of tokens deducted as fees */
    function totalFeesDeducted() public view returns (uint256) {
        return _totalFeesDeducted;
    }

    /** @dev Return the total reflection deducted as fees */
    function totalReflectionFeesDeducted() public view returns (uint256) {
        return _totalReflectionFeesDeducted;
    }

    function reflectionFromToken(uint256 amount) public view returns (uint256) {
        return _reflectionFromToken(amount, getRate());
    }

    /** @dev Given a reflection amount, return the equivalent token amount
     * @param reflectionAmount The amount of reflection to be converted to tokens
     * @param currentRate The current exchange rate
     */
    function _tokenFromReflection(uint256 reflectionAmount, uint256 currentRate)
        private
        pure
        returns (uint256)
    {
        if (currentRate == 0 || reflectionAmount == 0) return 0;

        return reflectionAmount / currentRate;
    }

    /** @dev Given a token amount, return the equivalent reflection amount
     * @param tokenAmount The amount of tokens to be converted to reflection
     * @param currentRate The current exchange rate
     */
    function _reflectionFromToken(uint256 tokenAmount, uint256 currentRate)
        private
        view
        returns (uint256)
    {
        require(
            tokenAmount <= _simpleTokenTotal,
            "Amount must be less than simple token total"
        );

        return tokenAmount * currentRate;
    }

    /** @dev Exclude an account from participating in the reflection system.
     * Transfers to or from accounts marked as excluded will not be charged a transfer fee, and will not receive reflection tax.
     * Their reflection balance is converted to a simple token balance.
     * @param account The address of the account to be excluded
     */
    function excludeAccount(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");

        // If the account has a reflection balance, convert it to a simple token balance
        uint256 currentReflectionBalance = _reflectionPoolBalances[account];
        if (currentReflectionBalance > 0) {
            uint256 simpleTokenBalanceToRestore = _tokenFromReflection(
                currentReflectionBalance,
                getRate()
            );
            _excludedReflectionAmount += currentReflectionBalance;
            _simpleTokenBalances[account] = simpleTokenBalanceToRestore;
            _excludedTokenAmount += simpleTokenBalanceToRestore;
        }
        //Update the lookup
        _isExcluded[account] = true;

        emit ExcludeAccount(account);
    }

    /** @dev Include a previously excluded account in the reflection system.
     * Their simple token balance is converted to reflection balance.
     * @param account The address of the account to be excluded
     */
    function includeAccount(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");

        // If the account has a simple token balance, move it back to the reflection pool
        uint256 currentSimpleTokenBalance = _simpleTokenBalances[account];
        if (currentSimpleTokenBalance > 0) {
            uint256 reflectionBalanceToRestore = _reflectionFromToken(
                currentSimpleTokenBalance,
                getRate()
            );
            _excludedTokenAmount -= currentSimpleTokenBalance;
            _reflectionPoolBalances[account] = reflectionBalanceToRestore;
            _excludedReflectionAmount -= reflectionBalanceToRestore;
        }
        // Update the lookup
        _isExcluded[account] = false;

        emit IncludeAccount(account);
    }

    /** @dev Transfer, deducting and distributing a fee if required
     * Excluded accounts are not charged a fee, and will not receive reflection tax.
     * @param from The address of the sender
     * @param recipient The address of the recipient
     * @param tokenAmount The quantity of tokens to be transferred
     */
    function _transfer(
        address from,
        address recipient,
        uint256 tokenAmount
    ) internal virtual override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(
            tokenAmount > 0,
            "ERC20: transfer amount must be greater than 0"
        );
        require(from != recipient, "ERC20: cannot transfer to self");
        require(balanceOf(from) >= tokenAmount, "ERC20: insufficient balance");

        uint256 rate = getRate();
        uint256 reflectionAmount = _reflectionFromToken(tokenAmount, rate);

        uint256 tokenFee;
        uint256 reflectionFee;

        // If neither are excluded, a fee is charged
        if (!_isExcluded[from] && !_isExcluded[recipient]) {
            (tokenFee, reflectionFee) = _calculateTransferFees(
                tokenAmount,
                rate
            );
            _addToBalance(
                recipient,
                reflectionAmount - reflectionFee,
                tokenAmount - tokenFee
            );
            _deductFromBalance(from, reflectionAmount, tokenAmount);
            _reflectFee(reflectionFee, tokenFee);
        } else {
            // If either are excluded, no fee is charged
            _addToBalance(recipient, reflectionAmount, tokenAmount);
            _deductFromBalance(from, reflectionAmount, tokenAmount);
        }
        // Update excluded totals
        if (_isExcluded[from] && !_isExcluded[recipient]) {
            _excludedReflectionAmount -= reflectionAmount;
            _excludedTokenAmount -= tokenAmount;
        } else if (!_isExcluded[from] && _isExcluded[recipient]) {
            _excludedReflectionAmount += reflectionAmount;
            _excludedTokenAmount += tokenAmount;
        }
        emit Transfer(from, recipient, tokenAmount);
    }

    function _addToBalance(
        address account,
        uint256 reflectionAmount,
        uint256 tokenAmount
    ) internal {
        if (_isExcluded[account]) {
            _simpleTokenBalances[account] += tokenAmount;
        }
        _reflectionPoolBalances[account] += reflectionAmount;
    }

    function _deductFromBalance(
        address account,
        uint256 reflectionAmount,
        uint256 tokenAmount
    ) internal {
        if (_isExcluded[account]) {
            _simpleTokenBalances[account] -= tokenAmount;
        }
        _reflectionPoolBalances[account] -= reflectionAmount;
    }

    /** @dev Deduct the fee from the reflection pool, and add to the total fees deducted
    @param reflectionFeeAmount The amount of reflection to deduct from the reflection pool
    @param tokenFeeAmount The amount of tokens to deduct
     */
    function _reflectFee(uint256 reflectionFeeAmount, uint256 tokenFeeAmount)
        private
    {
        if (_reflectionPoolTotal <= reflectionFeeAmount) {
            return;
        }
        _reflectionPoolTotal -= reflectionFeeAmount;
        _totalFeesDeducted += tokenFeeAmount;
        _totalReflectionFeesDeducted += reflectionFeeAmount;
    }

    /** @dev Given a token amount, return the token and reflection fee amounts
     */
    function _calculateTransferFees(uint256 tokenAmount, uint256 currentRate)
        public
        view
        returns (uint256 tokenFee, uint256 reflectionFee)
    {
        //uint256 reflectionAmount = reflectionFromToken(tokenAmount, currentRate);
        tokenFee = calculateTransferFee(tokenAmount);
        reflectionFee = _reflectionFromToken(tokenFee, currentRate);
    }

    /** @dev Given a token amount, calculate the fee that should be charged
     */
    function calculateTransferFee(uint256 tokenAmount)
        public
        view
        returns (uint256)
    {
        uint256 tokenFee = (tokenAmount * _taxRate) / 10_000; // Calculate fee based on tax rate expessed as hundredths of a percent
        return tokenFee;
    }

    /** @dev Get the current exchange rate
     * returns The current exchange rate: reflections per token
     */
    function getRate() public view returns (uint256) {
        uint256 currentUnexcludedReflectionSupply = _reflectionPoolTotal -
            _excludedReflectionAmount;
        uint256 currentUnexcludedTokenSupply = _simpleTokenTotal - _excludedTokenAmount;
        if (
            currentUnexcludedTokenSupply == 0 || // If all tokens are excluded, no need to consider the excluded amounts in the rate calculation
            currentUnexcludedReflectionSupply == 0 ||
            currentUnexcludedTokenSupply > currentUnexcludedReflectionSupply //
        ) {
            return type(uint256).max / _simpleTokenTotal;
        }
        return currentUnexcludedReflectionSupply / currentUnexcludedTokenSupply;
    }

    // New tax rate, expressed as hundredths of a percent
    /** @dev Set the tax rate for the token
     * @param newRate The new tax rate for the token, expressed as hundredths of a percent
     */
    function setTaxRate(uint16 newRate) external onlyOwner {
        require(newRate <= 10_000, "Tax rate must be less than 100%");
        _taxRate = newRate;
        emit TaxRateChange(newRate);
    }

    /** @dev Get the current tax rate
     * returns The current tax rate for the token, expressed as hundredths of a percent
     */
    function getTaxRate() public view returns (uint16) {
        return _taxRate;
    }

    /** @dev Get the number of reflections held by an account
     * @param account The address of the account
     */
    function getReflectionBalance(address account)
        public
        view
        returns (uint256)
    {
        return _reflectionPoolBalances[account];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

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
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
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
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
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
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
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

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
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

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
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
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
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

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

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