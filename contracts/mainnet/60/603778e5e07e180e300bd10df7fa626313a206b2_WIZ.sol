/**
 *Submitted for verification at Etherscan.io on 2022-12-02
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;


abstract contract Context {
    function _msgSender() internal view returns (address payable) {
        return payable(msg.sender);
    }

    function _msgData() internal view returns (bytes memory) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the token decimals.
     */
    function decimals() external view returns (uint8);

    /**
     * @dev Returns the token symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the token name.
     */
    function name() external view returns (string memory);

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address _owner, address spender)
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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
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

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address lpPair,
        uint256
    );

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address lpPair);

    function createPair(address tokenA, address tokenB)
        external
        returns (address lpPair);
}

interface IUniswapV2Pair {
    function factory() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function token0() external view returns (address);

    function token1() external view returns (address);
}

interface IUniswapV2Router01 {
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

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);

    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountETH);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);
}

////////CONTRACT//IMPLEMENTATION/////////

contract WIZ is Context, IERC20 {
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    string private constant _name = "WIZ";
    string private constant _symbol = "WIZ";
    uint8 private constant _decimals = 4;

    uint256 private constant _totalSupply = 100_000_000_000 * (10**_decimals);
    uint256 private constant _tTotal = _totalSupply;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    uint private _feesAndLimitsStartTimestamp;
    bool private _inLiquidityOperation;

    uint16 public constant buyFeeReflect = 0;
    uint16 public constant buyFeeBurn = 0;
    uint16 public constant buyFeeMarketing = 100;
    uint16 public constant buyFeeTotalSwap = 300;

    uint16 public constant sellFeeReflect = 250;
    uint16 public constant sellFeeBurn = 50;
    uint16 public constant sellFeeMarketing = 0;
    uint16 public constant sellFeeTotalSwap = 500;

    uint16 public constant ratioLiquidity = 200;
    uint16 public constant ratioTreasury = 600;
    uint16 public constant ratioTotal = 800;

    uint256 public constant feeDivisor = 10000;

    address public constant dexRouterAddress =
        0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    IUniswapV2Router02 public dexRouter;
    address public lpPair;

    address public constant DEAD = 0x000000000000000000000000000000000000dEaD;

    address public constant marketingWallet =
        0x38649185909fD39fF2eCDB27Ac472a5ecb003a0c;

    address public constant treasuryWallet =
        0x1e18ed1bfCa02e59a43de32c60Ac0FD4923b64b5;

    bool private _inSwap;
    uint256 public constant contractSwapTimer = 10 seconds;
    uint256 private _lastSwapTimestamp;

    uint256 public constant swapThreshold = (_tTotal * 5) / 10000;
    uint256 public constant swapAmount = (_tTotal * 10) / 10000;

    uint256 private constant _maxTxAmount = (_tTotal * 300) / 10000;

    event AutoLiquify(uint256 amountCurrency, uint256 amountTokens);

    modifier lockTheSwap() {
        _inSwap = true;
        _;
        _inSwap = false;
    }

    modifier withoutTransferFees() {
        _inLiquidityOperation = true;
        _;
        _inLiquidityOperation = false;
    }

    constructor() payable {
        _rOwned[msg.sender] = _rTotal;

        // start applying fee and limits from this time
        _feesAndLimitsStartTimestamp = block.timestamp + 15 minutes;

        if (
            block.chainid == 1 || block.chainid == 5 || block.chainid == 31337
        ) {
            dexRouter = IUniswapV2Router02(dexRouterAddress);
        } else {
            revert("Deployment chain is not supported by this contract");
        }

        lpPair = IUniswapV2Factory(dexRouter.factory()).createPair(
            dexRouter.WETH(),
            address(this)
        );

        // FIXME: think about potential overflow after years
        _approve(msg.sender, dexRouterAddress, type(uint256).max);
        _approve(address(this), dexRouterAddress, type(uint256).max);
        IERC20(lpPair).approve(dexRouterAddress, type(uint256).max);

        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    receive() external payable {}

    function allowFeesAndLimits() external {
        _feesAndLimitsStartTimestamp = block.timestamp;
    }

    function totalSupply() external pure override returns (uint256) {
        if (_tTotal == 0) {
            revert();
        }
        return _tTotal;
    }

    function decimals() external pure override returns (uint8) {
        return _decimals;
    }

    function symbol() external pure override returns (string memory) {
        return _symbol;
    }

    function name() external pure override returns (string memory) {
        return _name;
    }

    function allowance(address holder, address spender)
        external
        view
        override
        returns (uint256)
    {
        return _allowances[holder][spender];
    }

    function balanceOf(address account) public view override returns (uint256) {
        address lpPair_ = lpPair;
        if (_isExcludedFromReflections(account, lpPair_))
            return _tOwned[account];
        return _tokenFromReflection(_rOwned[account], lpPair_);
    }

    function transfer(address recipient, uint256 amount)
        external
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount)
        external
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function _approve(
        address sender,
        address spender,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: Sender is not zero Address");
        require(spender != address(0), "ERC20: Spender is not zero Address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] -= amount;
        }

        _transfer(sender, recipient, amount);
        return true;
    }

    function getCirculatingSupply() public view returns (uint256) {
        return (_tTotal - (balanceOf(DEAD) + balanceOf(address(0))));
    }

    function _isExcludedFromReflections(address account, address lpPair_)
        private
        view
        returns (bool)
    {
        return
            account == address(this) ||
            account == DEAD ||
            account == marketingWallet ||
            account == lpPair_;
    }

    function isExcludedFromReflections(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromReflections(account, lpPair);
    }

    // function getExcludedFromReflections(uint256 index) public view returns (address);
    // }

    function addLiquidityETH(
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    )
        public
        payable
        withoutTransferFees
        returns (
            uint amountToken,
            uint amountETH,
            uint liquidity
        )
    {
        // we need to transfer WIZ to our contract for router to have access to it
        _transfer(msg.sender, address(this), amountTokenDesired);

        if (deadline == 0) deadline = block.timestamp;
        if (to == address(0)) to = msg.sender;

        (amountToken, amountETH, liquidity) = dexRouter.addLiquidityETH{
            value: msg.value
        }(
            address(this),
            amountTokenDesired,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );

        // refund dust eth, if any
        if (amountToken < amountTokenDesired) {
            _transfer(
                address(this),
                msg.sender,
                amountTokenDesired - amountToken
            );
        }
        // refund dust WIZ, if any
        if (amountETH < msg.value) {
            payable(msg.sender).transfer(msg.value - amountETH);
        }
    }

    function removeLiquidityETH(
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) public withoutTransferFees returns (uint amountToken, uint amountETH) {
        // we need to transfer LP Pair tokens to our contract for router to have access to it
        IERC20(lpPair).transferFrom(msg.sender, address(this), liquidity);

        if (liquidity == 0) liquidity = IERC20(lpPair).balanceOf(msg.sender);
        if (deadline == 0) deadline = block.timestamp;
        if (to == address(0)) to = msg.sender;

        uint balanceBefore = balanceOf(to);
        amountETH = dexRouter.removeLiquidityETHSupportingFeeOnTransferTokens(
            address(this),
            liquidity,
            amountTokenMin,
            amountETHMin,
            to,
            deadline
        );
        amountToken = balanceOf(to) - balanceBefore;
    }

    function _tokenFromReflection(uint256 rAmount, address lpPair_)
        private
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate(lpPair_);
        return rAmount / currentRate;
    }

    function isExcludedFromFees(address account) public view returns (bool) {
        return _isExcludedFromFees(account);
    }

    function _isExcludedFromFees(address account) private view returns (bool) {
        return account == address(this) || account == DEAD;
    }

    function getMaxTX() public pure returns (uint256) {
        return _maxTxAmount / (10**_decimals);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        bool feesAndLimitsAllowed = block.timestamp >=
            _feesAndLimitsStartTimestamp;

        if (feesAndLimitsAllowed) {
            require(
                amount <= _maxTxAmount,
                "Transfer amount exceeds the maxTxAmount."
            );
        }
        address lpPair_ = lpPair;
        bool takeFee = feesAndLimitsAllowed &&
            !(_isExcludedFromFees(from) || _isExcludedFromFees(to)) &&
            !_inLiquidityOperation;

        if (to == lpPair_) {
            if (!_inSwap && !_inLiquidityOperation) {
                if (_lastSwapTimestamp + contractSwapTimer < block.timestamp) {
                    uint256 contractTokenBalance = balanceOf(address(this));
                    if (contractTokenBalance >= swapThreshold) {
                        if (contractTokenBalance >= swapAmount) {
                            contractTokenBalance = swapAmount;
                        }
                        _contractSwap(contractTokenBalance);
                        _lastSwapTimestamp = block.timestamp;
                    }
                }
            }
        }
        _finalizeTransfer(from, to, amount, takeFee);
    }

    function _contractSwap(uint256 contractTokenBalance) private lockTheSwap {
        if (
            contractTokenBalance > _allowances[address(this)][dexRouterAddress]
        ) {
            _allowances[address(this)][dexRouterAddress] = type(uint256).max;
        }

        uint256 toLiquify = ((contractTokenBalance * ratioLiquidity) /
            ratioTotal) / 2;
        uint256 swapAmt = contractTokenBalance - toLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();

        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            swapAmt,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amtBalance = address(this).balance;
        uint256 liquidityBalance = (amtBalance * toLiquify) / swapAmt;

        if (toLiquify > 0) {
            dexRouter.addLiquidityETH{value: liquidityBalance}(
                address(this),
                toLiquify,
                0,
                0,
                DEAD,
                block.timestamp
            );
            emit AutoLiquify(liquidityBalance, toLiquify);
        }

        amtBalance -= liquidityBalance;
        uint256 treasuryBalance = amtBalance;
        if (ratioTreasury > 0) {
            payable(treasuryWallet).transfer(treasuryBalance);
        }
    }

    struct ExtraValues {
        uint256 tTransferAmount;
        uint256 tFee;
        uint256 tSwap;
        uint256 tBurn;
        uint256 tMarketing;
        uint256 rTransferAmount;
        uint256 rAmount;
        uint256 rFee;
        uint256 currentRate;
    }

    function _finalizeTransfer(
        address from,
        address to,
        uint256 tAmount,
        bool takeFee
    ) private {
        address lpPair_ = lpPair;
        ExtraValues memory values = _getValues(
            from,
            to,
            tAmount,
            takeFee,
            lpPair_
        );

        _rOwned[from] -= values.rAmount;
        _rOwned[to] += values.rTransferAmount;

        if (_isExcludedFromReflections(from, lpPair_)) {
            _tOwned[from] -= tAmount;
        }
        if (_isExcludedFromReflections(to, lpPair_)) {
            _tOwned[to] += values.tTransferAmount;
        }

        if (values.rFee > 0) {
            _rTotal -= values.rFee;
        }

        emit Transfer(from, to, values.tTransferAmount);
    }

    function _getValues(
        address from,
        address to,
        uint256 tAmount,
        bool takeFee,
        address lpPair_
    ) private returns (ExtraValues memory) {
        ExtraValues memory values;
        values.currentRate = _getRate(lpPair_);

        values.rAmount = tAmount * values.currentRate; // _rTotal / _tTotal

        if (takeFee) {
            uint256 currentReflect;
            uint256 currentSwap;
            uint256 currentBurn;
            uint256 currentMarketing;
            uint256 divisor = feeDivisor;

            if (Address.isContract(to)) {
                currentReflect = sellFeeReflect;
                currentBurn = sellFeeBurn;
                currentMarketing = sellFeeMarketing;
                currentSwap = sellFeeTotalSwap;
            } else if (Address.isContract(from)) {
                currentReflect = buyFeeReflect;
                currentBurn = buyFeeBurn;
                currentMarketing = buyFeeMarketing;
                currentSwap = buyFeeTotalSwap;
            }

            values.tFee = (tAmount * currentReflect) / divisor;
            values.tSwap = (tAmount * currentSwap) / divisor;
            values.tBurn = (tAmount * currentBurn) / divisor;
            values.tMarketing = (tAmount * currentMarketing) / divisor;
            values.tTransferAmount =
                tAmount -
                (values.tFee + values.tSwap + values.tBurn + values.tMarketing);

            values.rFee = values.tFee * values.currentRate;
        } else {
            values.tFee = 0;
            values.tSwap = 0;
            values.tBurn = 0;
            values.tMarketing = 0;
            values.tTransferAmount = tAmount;

            values.rFee = 0;
        }

        if (values.tSwap > 0) {
            _rOwned[address(this)] += values.tSwap * values.currentRate;
            _tOwned[address(this)] += values.tSwap;
            emit Transfer(from, address(this), values.tSwap);
        }

        if (values.tBurn > 0) {
            _rOwned[DEAD] += values.tBurn * values.currentRate;
            _tOwned[DEAD] += values.tBurn;
            emit Transfer(from, DEAD, values.tBurn);
        }

        if (values.tMarketing > 0) {
            _rOwned[marketingWallet] += values.tMarketing * values.currentRate;
            _tOwned[marketingWallet] += values.tMarketing;
            emit Transfer(from, marketingWallet, values.tMarketing);
        }

        values.rTransferAmount =
            values.rAmount -
            (values.rFee +
                (values.tSwap * values.currentRate) +
                (values.tBurn * values.currentRate) +
                (values.tMarketing * values.currentRate));
        return values;
    }

    function _getRate(address lpPair_) private view returns (uint256) {
        uint256 rTotal = _rTotal;
        uint256 tTotal = _tTotal;
        uint256 rSupply;
        uint256 tSupply;
        uint256 rOwned;
        uint256 tOwned;
        unchecked {
            rSupply = rTotal;
            tSupply = tTotal;

            rOwned = _rOwned[address(this)];
            tOwned = _tOwned[address(this)];
            if (rOwned > rSupply || tOwned > tSupply) return rTotal / tTotal;
            rSupply -= rOwned;
            tSupply -= tOwned;

            rOwned = _rOwned[DEAD];
            tOwned = _tOwned[DEAD];
            if (rOwned > rSupply || tOwned > tSupply) return rTotal / tTotal;
            rSupply -= rOwned;
            tSupply -= tOwned;

            rOwned = _rOwned[marketingWallet];
            tOwned = _tOwned[marketingWallet];
            if (rOwned > rSupply || tOwned > tSupply) return rTotal / tTotal;
            rSupply -= rOwned;
            tSupply -= tOwned;

            rOwned = _rOwned[lpPair_];
            tOwned = _tOwned[lpPair_];
            if (rOwned > rSupply || tOwned > tSupply) return rTotal / tTotal;
            rSupply -= rOwned;
            tSupply -= tOwned;
        }
        return rSupply / tSupply;
    }
}