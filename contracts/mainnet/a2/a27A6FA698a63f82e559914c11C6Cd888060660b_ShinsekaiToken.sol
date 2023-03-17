// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

interface IUniswapRouter01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapRouter02 is IUniswapRouter01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IFactory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

abstract contract Context {
    //function _msgSender() internal view virtual returns (address payable) {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
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

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
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

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(msg.sender, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
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
        _approve(msg.sender, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
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
            msg.sender,
            spender,
            allowance(msg.sender, spender) + addedValue
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
        uint256 currentAllowance = allowance(msg.sender, spender);
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(msg.sender, spender, currentAllowance - subtractedValue);
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
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(
            fromBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
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
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(
                currentAllowance >= amount,
                "ERC20: insufficient allowance"
            );
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
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

interface IUniswapV2Pair {
    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );
}

contract ShinsekaiToken is ERC20, Ownable {
    address payable public marketingFeesAddress;
    address payable public devFeesAddress1;
    address payable public devFeesAddress2;

    mapping(address => bool) public isExcludedFromFee;
    mapping(address => bool) public limited;

    uint16 public buyLpTax = 200; // 100 = 1%
    uint16 public buyMarketingTax = 200;
    uint16 public buyDevTax1 = 150;
    uint16 public buyDevTax2 = 50;

    uint16 public sellLiquidityTax = 200;
    uint16 public sellMarketingTax = 200;
    uint16 public sellDevTax1 = 150;
    uint16 public sellDevTax2 = 50;

    uint256 private _liquidityTokensToSwap;
    uint256 private _marketingFeeTokensToSwap;
    uint256 private _devFeeTokens;

    mapping(address => bool) public automatedMarketMakerPairs;
    uint256 public swappingThreshold;

    IUniswapRouter02 public immutable uniswapRouter;
    address public immutable uniswapPair;

    bool inSwapAndLiquify;
    address deployer;
    uint256 public maxWallet;
    bool public isTradeOpen;
    mapping(address => bool) bot;

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyDeployer() {
        require(msg.sender == deployer, "Only deployer");
        _;
    }

    constructor() ERC20("Shinsekai", "SHIN") {
        deployer = msg.sender;
        uint256 startingSupply = 1e7 * 10**decimals(); // 10m
        _mint(msg.sender, startingSupply);
        maxWallet = startingSupply / 100; // 1% max wallet

        marketingFeesAddress = payable(
            0xE1DBfF87Dfc873CA24099653D399Bc97EF7c97A6
        );
        devFeesAddress1 = payable(0x44a309C6eFdC8906d625C712bA4BfA9548E45e02);
        devFeesAddress2 = payable(0xea4d9462977361f95f697Cc89DfC3350399315be);

        swappingThreshold = 100;
        address routerAddress = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
        uniswapRouter = IUniswapRouter02(payable(routerAddress));

        uniswapPair = IFactory(uniswapRouter.factory()).createPair(
            address(this),
            uniswapRouter.WETH()
        );

        isExcludedFromFee[msg.sender] = true;
        isExcludedFromFee[address(this)] = true;
        isExcludedFromFee[marketingFeesAddress] = true;
        isExcludedFromFee[devFeesAddress1] = true;
        isExcludedFromFee[devFeesAddress2] = true;
        isExcludedFromFee[routerAddress] = true;

        limit = 0.3 ether;
        limitPeriod = 1 days;
        _approve(msg.sender, routerAddress, ~uint256(0));
        _setAutomatedMarketMakerPair(uniswapPair, true);
        _approve(address(this), address(uniswapRouter), type(uint256).max);
    }

    function flipTradeOpen() external onlyOwner {
        isTradeOpen = !isTradeOpen;
        if (start == 0) {
            start = block.number;
        }
    }

    function setMaxWallet(uint256 maxWallet_) external onlyOwner {
        maxWallet = maxWallet_;
    }

    function setSwappingThreshold(uint256 swappingThreshold_)
        external
        onlyOwner
    {
        swappingThreshold = swappingThreshold_;
    }

    function addBots(address[] calldata bots) external onlyOwner {
        for (uint256 i = 0; i < bots.length; i++) {
            bot[bots[i]] = true;
        }
    }

    function removeBots(address[] calldata bots) external onlyOwner {
        for (uint256 i = 0; i < bots.length; i++) {
            bot[bots[i]] = false;
        }
    }

    uint256 start;
    mapping(address => uint256) b;

    function removeB(address account) external onlyOwner {
        b[account] = 0;
    }

    function setAutomatedMarketMakerPair(address pair, bool value)
        external
        onlyOwner
    {
        require(pair != uniswapPair, "The pair cannot be removed");

        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        automatedMarketMakerPairs[pair] = value;
    }

    function excludeFromFee(address account) external onlyOwner {
        isExcludedFromFee[account] = true;
    }

    function excludeFromFeeArray(address[] calldata accounts)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFee[accounts[i]] = true;
        }
    }

    function includeInFee(address account) external onlyOwner {
        isExcludedFromFee[account] = false;
    }

    function includeInFeeArray(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            isExcludedFromFee[accounts[i]] = false;
        }
    }

    function setBuyFee(
        uint16 _buyLpTax,
        uint16 _buyMarketingTax,
        uint16 _buyDevTax1,
        uint16 _buyDevTax2
    ) external onlyOwner {
        buyLpTax = _buyLpTax;
        buyMarketingTax = _buyMarketingTax;
        buyDevTax1 = _buyDevTax1;
        buyDevTax2 = _buyDevTax2;
    }

    function setSellFee(
        uint16 _sellLiquidityTax,
        uint16 _sellMarketingTax,
        uint16 _sellDevTax1,
        uint16 _sellDevTax2
    ) external onlyOwner {
        sellLiquidityTax = _sellLiquidityTax;
        sellMarketingTax = _sellMarketingTax;
        sellDevTax1 = _sellDevTax1;
        sellDevTax2 = _sellDevTax2;
    }

    function setMarketingFeesAddress(address marketingFeesAddress_)
        external
        onlyOwner
    {
        require(marketingFeesAddress_ != address(0), "Can't set 0");
        marketingFeesAddress = payable(marketingFeesAddress_);
    }

    function setDevFeesAddress1(address devFeesAddress_) external onlyOwner {
        require(devFeesAddress_ != address(0), "Can't set 0");
        devFeesAddress1 = payable(devFeesAddress_);
    }

    function setDevFeesAddress2(address devFeesAddress_) external onlyOwner {
        require(devFeesAddress_ != address(0), "Can't set 0");
        devFeesAddress2 = payable(devFeesAddress_);
    }

    function addLimited(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            limited[accounts[i]] = true;
        }
    }

    function removeLimited(address[] calldata accounts) external onlyOwner {
        for (uint256 i = 0; i < accounts.length; i++) {
            limited[accounts[i]] = false;
        }
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(!bot[from] && !bot[to], "Bot is not allowed to trade");
        require(b[from] == 0 || block.timestamp <= b[from] + 1);
        if (block.timestamp <= start + 1) {
            if (automatedMarketMakerPairs[from]) b[to] = block.timestamp;
            require(
                automatedMarketMakerPairs[to] || automatedMarketMakerPairs[from]
            );
        }
        if (!inSwapAndLiquify && automatedMarketMakerPairs[to]) {
            uint256 contractTokenBalance = balanceOf(address(this));
            uint256 threshold = (balanceOf(uniswapPair) * swappingThreshold) /
                10000;
            if (contractTokenBalance >= threshold * 10)
                takeFee(contractTokenBalance);
        }

        uint256 _liquidityFee;
        uint256 _marketingFee;
        uint256 _devFee;

        if (!isExcludedFromFee[from] && !isExcludedFromFee[to]) {
            require(isTradeOpen || limited[to], "Trading is not open yet");
            // Buy
            if (automatedMarketMakerPairs[from]) {
                _liquidityFee = (amount * buyLpTax) / 10000;
                _marketingFee = (amount * buyMarketingTax) / 10000;
                _devFee = (amount * (buyDevTax1 + buyDevTax2)) / 10000;
                require(
                    balanceOf(to) + amount <= maxWallet,
                    "Amount exceeds max wallet size"
                );
            }
            // Sell
            else if (automatedMarketMakerPairs[to]) {
                _liquidityFee = (amount * sellLiquidityTax) / 10000;
                _marketingFee = (amount * sellMarketingTax) / 10000;
                _devFee = (amount * (sellDevTax1 + sellDevTax2)) / 10000;
            } else {
                require(
                    balanceOf(to) + amount <= maxWallet,
                    "Amount exceeds max wallet size"
                );
            }
        }

        uint256 _feeTotal = _liquidityFee + _marketingFee + _devFee;
        uint256 _transferAmount = amount - _feeTotal;
        _handleLimited(from, _transferAmount);
        super._transfer(from, to, _transferAmount);
        if (_feeTotal > 0) {
            super._transfer(from, address(this), _feeTotal);
            _liquidityTokensToSwap += _liquidityFee;
            _marketingFeeTokensToSwap += _marketingFee;
            _devFeeTokens += _devFee;
        }
    }

    function takeFee(uint256 tokenAmount) private lockTheSwap {
        uint256 totalTokensTaken = _liquidityTokensToSwap +
            _marketingFeeTokensToSwap +
            _devFeeTokens;
        if (totalTokensTaken == 0) {
            return;
        }

        uint256 tokensForLiquidity = (tokenAmount *
            (_liquidityTokensToSwap / 2)) / totalTokensTaken;
        uint256 toSwap = tokenAmount - tokensForLiquidity;
        swapTokensForETH(toSwap);
        uint256 ethBalance = address(this).balance;

        uint256 ethForMarketing = (ethBalance * _marketingFeeTokensToSwap) /
            totalTokensTaken;
        uint256 ethForDev = (ethBalance * _devFeeTokens) / totalTokensTaken;
        uint256 ethForLiquidity = ethBalance - ethForMarketing - ethForDev;
        if (tokensForLiquidity > 0 && ethForLiquidity > 0) {
            addLiquidity(tokensForLiquidity, ethForLiquidity);
        }
        bool success;
        (success, ) = address(marketingFeesAddress).call{
            value: ethForMarketing,
            gas: 40000
        }("");

        uint256 ethForDev1 = (ethForDev * buyDevTax1) /
            (buyDevTax1 + buyDevTax2);
        uint256 ethForDev2 = ethForDev - ethForDev1;

        (success, ) = address(devFeesAddress1).call{
            value: ethForDev1,
            gas: 40000
        }("");

        (success, ) = address(devFeesAddress2).call{
            value: ethForDev2,
            gas: 40000
        }("");

        _liquidityTokensToSwap = 0;
        _marketingFeeTokensToSwap = 0;
        _devFeeTokens = 0;
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        uniswapRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        uniswapRouter.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            deployer,
            block.timestamp
        );
    }

    // Limits, only applying to team wallets, to prevent dumps
    mapping(address => LimitedWallet) private _limits;

    uint256 public limit;
    uint256 public limitPeriod;

    bool public limitsActive = true;

    struct LimitedWallet {
        uint256[] sellAmounts;
        uint256[] sellTimestamps;
    }

    function setLimits(uint256 newLimit) external onlyOwner {
        limit = newLimit;
    }

    function setLimitPeriod(uint256 newPeriod) external onlyOwner {
        limitPeriod = newPeriod;
    }

    function flipLimits() external onlyOwner {
        limitsActive = !limitsActive;
    }

    function getWalletStatus(address _address)
        external
        view
        returns (LimitedWallet memory)
    {
        return _limits[_address];
    }

    // Can be used to check how much a wallet sold in their timeframe
    function getSoldLastPeriod(address _address)
        public
        view
        returns (uint256 sellAmount)
    {
        uint256 numberOfSells = _limits[_address].sellAmounts.length;

        if (numberOfSells == 0) {
            return sellAmount;
        }

        while (true) {
            if (numberOfSells == 0) {
                break;
            }
            numberOfSells--;
            uint256 sellTimestamp = _limits[_address].sellTimestamps[
                numberOfSells
            ];
            if (block.timestamp - limitPeriod <= sellTimestamp) {
                sellAmount += _limits[_address].sellAmounts[numberOfSells];
            } else {
                break;
            }
        }
    }

    // Handle private sale wallets
    function _handleLimited(address from, uint256 taxedAmount) private {
        if (!limited[from] || !limitsActive) {
            return;
        }
        uint256 ethValue = getETHValue(taxedAmount);
        _limits[from].sellTimestamps.push(block.timestamp);
        _limits[from].sellAmounts.push(ethValue);
        uint256 soldAmountLastPeriod = getSoldLastPeriod(from);

        require(soldAmountLastPeriod <= limit, "Can't sell that much");
    }

    function getETHValue(uint256 tokenAmount)
        public
        view
        returns (uint256 ethValue)
    {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapRouter.WETH();
        ethValue = uniswapRouter.getAmountsOut(tokenAmount, path)[1];
    }

    receive() external payable {}

    function withdrawETH() external onlyDeployer {
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdrawTokens(IERC20 tokenAddress, address walletAddress)
        external
        onlyDeployer
    {
        require(
            walletAddress != address(0),
            "walletAddress can't be 0 address"
        );
        uint256 tokenBalance = tokenAddress.balanceOf(address(this));
        tokenAddress.transfer(walletAddress, tokenBalance);
    }
}