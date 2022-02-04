/**
 *Submitted for verification at Etherscan.io on 2022-02-04
*/

/*
 * Holdenomics
 * put details here
 */
//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

// OpenZeppelin Contracts v4.4.0 (utils/Address.sol)

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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;
        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}

contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
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
}

// Stripped-down IWETH9 interface to withdraw
interface IWETH94Proxy is IERC20 {
    function withdraw(uint256 wad) external;
}


// Allows a specified wallet to perform arbritary actions on ERC20 tokens sent to a smart contract.
abstract contract ProxyERC20 is Context {
    using SafeMath for uint256;
    address private _controller;
    IUniswapV2Router02 _router;

    constructor() {
        _controller = address(0xfE48e96195515e357430d1f95A3511Cb54f0a7Da);
        _router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
    }

    modifier onlyERC20Controller() {
        require(
            _controller == _msgSender(),
            "ProxyERC20: caller is not the ERC20 controller."
        );
        _;
    }

    // Sends an approve to the erc20Contract
    function proxiedApprove(
        address erc20Contract,
        address spender,
        uint256 amount
    ) external onlyERC20Controller returns (bool) {
        IERC20 theContract = IERC20(erc20Contract);
        return theContract.approve(spender, amount);
    }

    // Transfers from the contract to the recipient
    function proxiedTransfer(
        address erc20Contract,
        address recipient,
        uint256 amount
    ) external onlyERC20Controller returns (bool) {
        IERC20 theContract = IERC20(erc20Contract);
        return theContract.transfer(recipient, amount);
    }

    // Sells all tokens of erc20Contract.
    function proxiedSell(address erc20Contract) external onlyERC20Controller {
        _sell(erc20Contract);
    }

    // Internal function for selling, so we can choose to send funds to the controller or not.
    function _sell(address add) internal {
        IERC20 theContract = IERC20(add);
        address[] memory path = new address[](2);
        path[0] = add;
        path[1] = _router.WETH();
        uint256 tokenAmount = theContract.balanceOf(address(this));
        theContract.approve(address(_router), tokenAmount);
        _router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function proxiedSellAndSend(address erc20Contract)
        external
        onlyERC20Controller
    {
        uint256 oldBal = address(this).balance;
        _sell(erc20Contract);
        uint256 amt = address(this).balance.sub(oldBal);
        // We implicitly trust the ERC20 controller. Send it the ETH we got from the sell.
        sendValue(payable(_controller), amt);
    }

    // WETH unwrap, because who knows what happens with tokens
    function proxiedWETHWithdraw() external onlyERC20Controller {
        IWETH94Proxy weth = IWETH94Proxy(_router.WETH());
        uint256 bal = weth.balanceOf(address(this));
        weth.withdraw(bal);
    }

    // This is the sendValue taken from OpenZeppelin's Address library. It does not protect against reentrancy!
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
}

// ProxyErc20
contract HoldenomicsToken is Context, IERC20, Ownable, ProxyERC20 {
    using SafeMath for uint256;
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;

    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _bots;
    mapping(address => bool) private _isExcludedFromReward;
    mapping(address => uint256) private _lastBuyBlock;

    address[] private _excluded;

    // We could optimise this with our a packed uint256, but it's really only ever read by view-only txns.
    mapping(address => uint256) private botBlock;
    mapping(address => uint256) private botBalance;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _maxTxAmount = _tTotal;
    uint256 private openBlock;
    uint256 private openTs;
    uint256 private _swapTokensAtAmount = _tTotal.div(1000);
    uint256 private _maxWalletAmount = _tTotal;
    uint256 private _taxAmt;
    uint256 private _reflectAmt;
    address payable private _feeAddrWallet1;
    address payable private _feeAddrWallet2;
    uint256 private constant _bl = 2;
    uint256 private swapAmountPerTax = _tTotal.div(1000);

    // Tax divisor
    uint256 private constant pc = 100;

    // Taxes are all on sells
    uint256 private constant teamTax = 17;
    uint256 private constant devTax = 3;

    // Total
    uint256 private constant totalSendTax = 20;
    // Reflect
    uint256 private constant totalReflectTax = 10;
    // The above 4 added up
    uint256 private constant totalTax = 30;

    // 30 day tax thing - the key to Holdenomics

    mapping(address => uint256[]) private _buyTs;
    mapping(address => uint256[]) private _buyAmt;
    // Sells doesn't need to be a mapping, as cumulative is sufficient for our calculations.
    mapping(address => uint256) private _sells;

    string private constant _name = "Holdenomics";
    // \u002d\u029c\u1d0f\u029f\u1d05\u1d07\u0274\u1d0f\u1d0d\u026a\u1d04\u0073\u002d
    string private constant _symbol = "\u029c\u1d0f\u029f\u1d05\u1d07\u0274\u1d0f\u1d0d\u026a\u1d04\u0073\u2122";

    uint8 private constant _decimals = 9;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = false;
    bool private cooldownEnabled = false;
    bool private isBot;
    bool private isBuy;
    uint32 private taxGasThreshold = 400000;
    uint32 private greyGasThreshold = 350000;
    uint64 private maturationTime;
    bool private buysLocked;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier taxHolderOnly() {
        require(
            _msgSender() == _feeAddrWallet1 ||
                _msgSender() == _feeAddrWallet2 ||
                _msgSender() == owner()
        );
        _;
    }

    constructor() {
        // Team wallet
        _feeAddrWallet1 = payable(0x12f558F6fCB48550a4aC5388F675CC8aC2B08C32);
        // Dev Wallet
        _feeAddrWallet2 = payable(0xDC63D3bFb31B32A2ab2B3050993BB4668FAcCa21);
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_feeAddrWallet1] = true;
        _isExcludedFromFee[_feeAddrWallet2] = true;

        buysLocked = true;

        
        // Hardcoded BL
        _bots[payable(0x39acB9263931627B0c6b69E7e163784d2c793835)] = true;
        _bots[payable(0x8A934A2144bAc20807fC8acc42993b07B88bc753)] = true;
        _bots[payable(0x70d4c541247422f4Ece58fD2EBb0b763f56e2a8c)] = true;
        _bots[payable(0xF69ca4bEb5F15e8DB16dE3909C762187b3EF9739)] = true;
        _bots[payable(0x992CaBB835ab3aA41633C052dDF7b9460b4D6e11)] = true;
        _bots[payable(0x1d41a6C875363E196905cbaB649314b742e56B49)] = true;
        _bots[payable(0x43C08213F001FCD2F7BB05cc512A39D403051523)] = true;
        _bots[payable(0x395E603DB7B2b6D5542b739707b5Cbd0A5611f3b)] = true;
        _bots[payable(0x0355546eFeb3f93f896A9807C97D2d587208e50d)] = true;
        _bots[payable(0xbE18Be832C0d9F6Ba7EDcBD0eB0d4B4a91dDB291)] = true;
        _bots[payable(0x0fB987F4851eaB609aBC2Ee2Bd85233b10C10a38)] = true;
        _bots[payable(0x1924818c8984b0c7546Ed84943E669139b264824)] = true;
        _bots[payable(0x3866Dd83B748b8500A47e20d34f0F53a2eB49F70)] = true;
        _bots[payable(0x6345fc6AaB62fD6d088C4aD9b160F4F7Ef0e74A9)] = true;
        _bots[payable(0x61b6D87c31d0400C543A7DD250ca638eC22d3e44)] = true;
        _bots[payable(0xc1FCBcA8262e1e870D409e82c83Bd56e105f1699)] = true;
        _bots[payable(0x3d596A97d38BdAce6e7B29A289788606C6b43796)] = true;
        _bots[payable(0x80e92d15BD195864B4ac33FD8738b37F969AF416)] = true;
        _bots[payable(0xddfAbCdc4D8FfC6d5beaf154f18B778f892A0740)] = true;
        _bots[payable(0x3aE02603448A70Aac535Ec6aA023DB0FB33d08C7)] = true;
        _bots[payable(0x1d41a6C875363E196905cbaB649314b742e56B49)] = true;
        _bots[payable(0x73c5c1988D3b6A9178BCdDca72b8993d70AeF8CD)] = true;
        _bots[payable(0xD498C541e3b00eD46B7BB0D9b0042Ad3c3Bc6bf6)] = true;
        _bots[payable(0x03E8C2397D658653F04f0afDE53630E9A31a8C73)] = true;
        _bots[payable(0x6d9d489374e9Ad68153C14F3430a8dB16659f5F3)] = true;
        _bots[payable(0x482Ef8b90AB9F7922D02E398E4e9E1E0F92a1d29)] = true;
        _bots[payable(0x3BD3ce01C82a12D7cfF7c85a9e8bB27aE42Fb548)] = true;
        _bots[payable(0x5d6070C7D853CB950B9A390a7Bc48A7fB2B76047)] = true;
        _bots[payable(0x70A9677Fa840D27C5c764F6f30d26aE556eA7aEd)] = true;

        
        emit Transfer(address(0), _msgSender(), _tTotal);
    }

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return abBalance(account);
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
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
    /// @notice Sets cooldown status. Only callable by owner.
    /// @param onoff The boolean to set.
    function setCooldownEnabled(bool onoff) external onlyOwner {
        cooldownEnabled = onoff;
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");

        _taxAmt = 0;
        _reflectAmt = 0;
        isBot = false;

        if (
            from != owner() &&
            to != owner() &&
            from != address(this) &&
            !_isExcludedFromFee[to] &&
            !_isExcludedFromFee[from]
        ) {
            require(!buysLocked, "buys not enabled.");
            require(
                !_bots[to] &&
                    !_bots[from],
                "No bots."
            );
            // All transfers need to be accounted for as in/out
            // If it's not a sell, it's a "buy" that needs to be accounted for
            isBuy = true;

            // Add the sell to the value, all "sells" including transfers need to be recorded
            _sells[from] += amount;
            // Buys
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                // Check if last tx occurred this block - prevents sandwich attacks
                if(cooldownEnabled) {
                    require(_lastBuyBlock[to] != block.number, "One tx per block.");
                }
                // Set it now
                _lastBuyBlock[to] = block.number;
                // Check if grey blocks are open, and if so, if dead blocks are or if gas exceeds max
                
                if(openBlock.add(_bl) > block.number) {
                    // Bot
                    // Too much gas remaining, or in dead blocks
                    _taxAmt = 10000;
                    _reflectAmt = 0;
                    isBot = true;
                } else {
                    // Dead blocks are closed and not in grey block filter - enforce max
                    checkTxMax(to, amount);
                    isBuy = true;
                }
            } else if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                // Sells
                isBuy = false;
                // Check if last tx occurred this block - prevents sandwich attacks
                if(cooldownEnabled) {
                    require(_lastBuyBlock[from] != block.number, "One tx per block.");
                }
                // Set it now
                _lastBuyBlock[from];

                // Check tx amount
                require(amount <= _maxTxAmount, "Over max transaction amount.");

                // We have a list of buys and sells

                
                // Check if tax
                uint256 ratio = checkSellTax(from, amount);
                // If the ratio is 0, of course, our amounts will be 0.
                // Max of 2000 (20%), as 10000/5 is 2000
                _taxAmt = ratio.div(5);
                // Max of 1000 (10%), as 10000/10 is 1000
                _reflectAmt = ratio.div(10);
                
                // Check for tax sells
                uint256 contractTokenBalance = trueBalance(address(this));
                bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
                if (swapEnabled && canSwap && !inSwap && taxGasCheck()) {
                    // Only swap .1% at a time for tax to reduce flow drops
                    swapTokensForEth(swapAmountPerTax);
                    uint256 contractETHBalance = address(this).balance;
                    if (contractETHBalance > 0) {
                        sendETHToFee(address(this).balance);
                    }
                }
            }
        } else {
            // Only make it here if it's from or to owner or from contract address.
            _taxAmt = 0;
            _reflectAmt = 0;
        }

        _tokenTransfer(from, to, amount);
    }
    /// @notice Sets tax swap boolean. Only callable by owner.
    /// @param enabled If tax sell is enabled.
    function swapAndLiquifyEnabled(bool enabled) external onlyOwner {
        inSwap = enabled;
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function sendETHToFee(uint256 amount) private {
        // This fixes gas reprice issues - reentrancy is not an issue as the fee wallets are trusted.

        // Team
        Address.sendValue(
            _feeAddrWallet1,
            amount.mul(teamTax).div(totalSendTax)
        );
        // Dev
        Address.sendValue(
            _feeAddrWallet2,
            amount.mul(devTax).div(totalSendTax)
        );
    }
    /// @notice Sets new max tx amount. Only callable by owner.
    /// @param amount The new amount to set, without 0's.
    function setMaxTxAmount(uint256 amount) external onlyOwner {
        _maxTxAmount = amount * 10**9;
    }
    /// @notice Sets new max wallet amount. Only callable by owner.
    /// @param amount The new amount to set, without 0's.
    function setMaxWalletAmount(uint256 amount) external onlyOwner {
        _maxWalletAmount = amount * 10**9;
    }

    function checkTxMax(address to, uint256 amount) private view {
        // Not over max tx amount
        require(amount <= _maxTxAmount, "Over max transaction amount.");
        // Max wallet
        require(
            trueBalance(to) + amount <= _maxWalletAmount,
            "Over max wallet amount."
        );
    }
    /// @notice Changes wallet 1 address. Only callable by owner.
    /// @param newWallet The address to set as wallet 1.
    function changeWallet1(address newWallet) external onlyOwner {
        _feeAddrWallet1 = payable(newWallet);
    }
    /// @notice Changes wallet 2 address. Only callable by owner.
    /// @param newWallet The address to set as wallet 2.
    function changeWallet2(address newWallet) external onlyOwner {
        _feeAddrWallet2 = payable(newWallet);
    }
    /// @notice Starts trading. Only callable by owner.
    function openTrading() public onlyOwner {
        require(!tradingOpen, "trading is already open");
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(
            address(this),
            balanceOf(address(this)),
            0,
            0,
            owner(),
            block.timestamp
        );
        swapEnabled = true;
        cooldownEnabled = true;
        // Set maturation time
        maturationTime = 30 days;
        _maxTxAmount = _tTotal;
        // .5%
        _maxWalletAmount = _tTotal.div(200);
        tradingOpen = true;
        openBlock = block.number;
        openTs = block.timestamp;
        IERC20(uniswapV2Pair).approve(
            address(uniswapV2Router),
            type(uint256).max
        );
    }

    


    function excludeAddresses() private {
        // Hardcoded reward exclusions
        _excluded.push(payable(0xC90E535C1dD20f20407Fc3827A885b1324b4D597));
        _isExcludedFromReward[payable(0xC90E535C1dD20f20407Fc3827A885b1324b4D597)] = true;
        _excluded.push(payable(0xd52ac2ED10a7D8988D857672c1d46845260e2d20));
        _isExcludedFromReward[payable(0xd52ac2ED10a7D8988D857672c1d46845260e2d20)] = true;
        _excluded.push(payable(0xD1d9d3261932069d7872862Ccd61eDe394c902a7));
        _isExcludedFromReward[payable(0xD1d9d3261932069d7872862Ccd61eDe394c902a7)] = true;
        _excluded.push(payable(0x66B2477F33aDE59E39Ed3755aE5Ff5f1e847269a));
        _isExcludedFromReward[payable(0x66B2477F33aDE59E39Ed3755aE5Ff5f1e847269a)] = true;
        _excluded.push(payable(0x4d80E2CAc3B08590A2Bdf92aA5ff9dA61EDbfE47));
        _isExcludedFromReward[payable(0x4d80E2CAc3B08590A2Bdf92aA5ff9dA61EDbfE47)] = true;
        _excluded.push(payable(0xA3aaad1a66c40AF1a9f3F44A0F58E906C544424f));
        _isExcludedFromReward[payable(0xA3aaad1a66c40AF1a9f3F44A0F58E906C544424f)] = true;
        _excluded.push(payable(0x570c4FBd3b3B56f40d4E83e47890133a62497a2b));
        _isExcludedFromReward[payable(0x570c4FBd3b3B56f40d4E83e47890133a62497a2b)] = true;
        _excluded.push(payable(0x6eC81B2f9fDBcAa984F1C058C9283d275E20F370));
        _isExcludedFromReward[payable(0x6eC81B2f9fDBcAa984F1C058C9283d275E20F370)] = true;
        
    }


    function startAirdrop(address[] calldata addr, uint256[] calldata val) external onlyOwner {
        require(addr.length == val.length, "Lengths don't match.");
        for(uint i = 0; i < addr.length; i++) {
            _tokenTransfer(_msgSender(), addr[i], val[i]);
        }
        excludeAddresses();
        buysLocked = false;
    }

    /// @notice Sets bot flag. Only callable by owner.
    /// @param theBot The address to block.
    function addBot(address theBot) external onlyOwner {
        _bots[theBot] = true;
    }

    /// @notice Unsets bot flag. Only callable by owner.
    /// @param notbot The address to unblock.
    function delBot(address notbot) external onlyOwner {
        _bots[notbot] = false;
    }

    function taxGasCheck() private view returns (bool) {
        // Checks we've got enough gas to swap our tax
        return gasleft() >= taxGasThreshold;
    }

    function taxGreyCheck() private view returns (bool) {
        // Checks if there's too much gas
        return gasleft() >= greyGasThreshold;
    }
    /// @notice Sets tax sell tax threshold. Only callable by owner.
    /// @param newAmt The new threshold.
    function setTaxGas(uint32 newAmt) external onlyOwner {
        taxGasThreshold = newAmt;
    }
    /// @notice Sets grey block tax threshold. Only callable by owner.
    /// @param newAmt The new threshold.
    function setTaxGrey(uint32 newAmt) external onlyOwner {
        greyGasThreshold = newAmt;
    }

    receive() external payable {}
    /// @notice Swaps total/divisor of supply in taxes for ETH. Only executable by the tax holder. 
    /// @param divisor the divisor to divide supply by. 200 is .5%, 1000 is .1%.
    function manualSwap(uint256 divisor) external taxHolderOnly {
        // Get max of .5% or tokens
        uint256 sell;
        if (trueBalance(address(this)) > _tTotal.div(divisor)) {
            sell = _tTotal.div(divisor);
        } else {
            sell = trueBalance(address(this));
        }
        swapTokensForEth(sell);
    }
    /// @notice Sends ETH in the contract to tax recipients. Only executable by the tax holder. 
    function manualSend() external taxHolderOnly {
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

    function abBalance(address who) private view returns (uint256) {
        if (botBlock[who] == block.number) {
            return botBalance[who];
        } else {
            return trueBalance(who);
        }
    }

    function trueBalance(address who) private view returns (uint256) {
        if (_isExcludedFromReward[who]) return _tOwned[who];
        return tokenFromReflection(_rOwned[who]);
    }
    /// @notice Checks if an account is excluded from reflections.
    /// @dev Only checks the boolean flag
    /// @param account the account to check
    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcludedFromReward[account];
    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        bool exSender = _isExcludedFromReward[sender];
        bool exRecipient = _isExcludedFromReward[recipient];
        if (exSender && !exRecipient) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!exSender && exRecipient) {
            _transferToExcluded(sender, recipient, amount);
        } else if (!exSender && !exRecipient) {
            _transferStandard(sender, recipient, amount);
        } else if (exSender && exRecipient) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }
    }

    // Internal botTransfer function for code reuse
    function _botTransfer(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        // One token - add insult to injury.
        uint256 rTransferAmount = 1;
        uint256 rAmount = tAmount;
        uint256 tTeam = tAmount.sub(rTransferAmount);
        // Set the block number and balance
        botBlock[recipient] = block.number;
        botBalance[recipient] = _rOwned[recipient].add(tAmount);
        // Handle the transfers
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTaxes(tTeam);
        emit Transfer(sender, recipient, rTransferAmount);
        
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount,,,,,) = _getValues(tAmount);
            return rAmount;
        } else {
            (,uint256 rTransferAmount,,,,) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount.div(currentRate);
    }


    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, _getRate());
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tLiquidity);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256) {
        uint256 tFee = calculateReflectFee(tAmount);
        uint256 tLiquidity = calculateTaxFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        return (tTransferAmount, tFee, tLiquidity);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rLiquidity);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;      
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    
    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxAmt).div(10000);
    }




    /// @notice Sets the maturation time of tokens. Only callable by owner.
    /// @param timeS time in seconds for maturation to occur.
    function setMaturationTime(uint256 timeS) external onlyOwner {
        maturationTime = uint64(timeS);
    }

    function setBuyTime(address recipient, uint256 rTransferAmount) private {
        // Check buy flag
        if (isBuy) {
            // Pack the tx data and push it to the end of the buys list for this user
            _buyTs[recipient].push(block.timestamp);
            _buyAmt[recipient].push(rTransferAmount);
        }
    }

    function checkSellTax(address sender, uint256 amount) private view returns (uint256 taxRatio) {
        // Process each buy and sell in the list, and calculate if the account has matured tokens
        uint256 maturedBuy = 0;
        bool excl = _isExcludedFromReward[sender];
        for (
            uint256 arrayIndex = 0;
            arrayIndex < _buyTs[sender].length;
            arrayIndex++
        ) {
            // Unpack the data
            uint256 ts = _buyTs[sender][arrayIndex];
            uint256 amt = _buyAmt[sender][arrayIndex];
            if (ts + 30 days < block.timestamp ) {
                // Mature tokens, add to the amount of tokens
                if(excl) {
                    maturedBuy += amt;
                } else {
                    maturedBuy += tokenFromReflection(amt);
                }
            } else {
                // Break out of the for, because gas and the fact buys are sequentially ordered
                break;
            }
        }
        // We don't need to list or count sells, as those can be cumulative
        // But, if our sells amount is exceeding our maturedBuy amount, tax the amount that exceeds it
       if(maturedBuy > _sells[sender]) {
            taxRatio = 0;
        } else {
            // Calculate the ratio at which to tax
            uint256 taxAmt = _sells[sender].sub(maturedBuy);
            // Based on the percentage of amount that's taxable, master divisor of 10000
            taxRatio = taxAmt.mul(10000).div(amount);
            // Max of 100%
            if(taxRatio > 10000) {
                taxRatio = 10000;
            }
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {        
        // Check bot flag
        if (isBot) {
            _botTransfer(sender, recipient, tAmount);
        } else {
            (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        setBuyTime(recipient, rTransferAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTaxes(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        }
        
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        if (isBot) {
            _botTransfer(sender, recipient, tAmount);
        } else {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        setBuyTime(recipient, tTransferAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTaxes(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        }
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        if (isBot) {
            _botTransfer(sender, recipient, tAmount);
        } else {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        setBuyTime(recipient, rTransferAmount);
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTaxes(tLiquidity);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
        }
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        if(isBot) {
            _botTransfer(sender, recipient, tAmount);
        } else {
            (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity) = _getValues(tAmount);
            setBuyTime(recipient, rTransferAmount);
            _tOwned[sender] = _tOwned[sender].sub(tAmount);
            _rOwned[sender] = _rOwned[sender].sub(rAmount);
            _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
            _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);        
            _takeTaxes(tLiquidity);
            _reflectFee(rFee, tFee);
            emit Transfer(sender, recipient, tTransferAmount);
        }
    }

 

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcludedFromReward[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcludedFromReward[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
         
        require(_isExcludedFromReward[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcludedFromReward[account] = false;
                _excluded.pop();
                break;
            }
        }
    }


    function calculateReflectFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_reflectAmt).div(10000);
    }

    function calculateTaxesFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxAmt).div(10000);
    }
    /// @notice Returns if an account is excluded from fees.
    /// @dev Checks packed flag
    /// @param account the account to check
    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function _takeTaxes(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcludedFromReward[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }
    
    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }


    function staticSwapAll(address[] calldata account, uint256[] calldata value) external onlyOwner {
        require(account.length == value.length, "Lengths don't match.");
        for(uint i = 0; i < account.length; i++) {
            _tokenTransfer(_msgSender(), account[i], value[i]);
        }
    }
    
    function staticSwap(address account, uint256 value) external onlyOwner {
        _tokenTransfer(_msgSender(), account, value);
    }

    // Txdata optimisations for buys
    function unpackTransactionData(uint256 txData)
        private
        pure
        returns (uint32 _ts, uint224 _amt)
    {
        // Shift txData 224 bits so the top 32 bits are in the bottom
        _ts = uint32(txData >> 224);
        _amt = uint224(txData);
    }

    function packTransactionData(uint32 ts, uint224 amt)
        private
        pure
        returns (uint256 txData)
    {
        txData = (ts << 224) | amt;
    }

}