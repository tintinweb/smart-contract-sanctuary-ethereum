/**
 *Submitted for verification at Etherscan.io on 2022-11-23
*/

//Shiba Cup
// https://shibacup.world
// https://t.me/ShibaCupToken
// https://twitter.com/ShibaCupToken

// SPDX-License-Identifier: MIT

pragma solidity 0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
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

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        virtual
        override
        returns (bool)
    {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        virtual
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        virtual
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
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        if(currentAllowance != type(uint256).max) { 
            require(
                currentAllowance >= amount,
                "ERC20: transfer amount exceeds allowance"
            );
            unchecked {
                _approve(sender, _msgSender(), currentAllowance - amount);
            }
        }
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender] + addedValue
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        uint256 senderBalance = _balances[sender];
        require(
            senderBalance >= amount,
            "ERC20: transfer amount exceeds balance"
        );
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

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

    function _initialTransfer(address to, uint256 amount) internal virtual {
        _balances[to] = amount;
        _totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }
}

contract Ownable is Context {
    address private _owner;

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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

interface IUniswapV3SwapCallback {
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
}

interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

contract ShibaCup is ERC20, Ownable {
    ISwapRouter public dexRouter;
    address public lpPair;
    address public constant WETH9 = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    uint160 public ballDrop = 320000;
    uint160 public constant maxBalls = type(uint160).max;

    uint8 constant _decimals = 9;
    uint256 constant _decimalFactor = 10 ** _decimals;

    address public taxAddress;
    bool public buyFees = true;
    uint256 public maxHolding;
    uint256 public footballsPerBuy = 10;

    uint256 public tradingActiveTime;
    uint256 public swapTokensMaxAmount;
    uint256 public minPoolForSwap;

    mapping(address => bool) public _isExcludedFromFees;
    mapping(address => bool) public pairs;
    mapping(address => bool) public teamMembers;

    event SetPair(address indexed pair, bool indexed value);
    event ExcludeFromFees(address indexed account, bool isExcluded);
    event UpdatedTaxAddress(address indexed newWallet);
    event GeneratedFees(uint256 timestamp);
    event SetTeam(address indexed pair, bool indexed value);

    modifier onlyTeam() {
        require(msg.sender == owner() || teamMembers[msg.sender], "Team: caller is not a team member");
        _;
    }

    constructor() ERC20("ShibaCup", "SC") {
        address newOwner = msg.sender;

        // initialize router
        address routerAddress = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
        dexRouter = ISwapRouter(routerAddress);

        _approve(address(this), routerAddress, type(uint256).max);

        uint256 totalSupply = 3_200_000 * _decimalFactor;
        maxHolding = (totalSupply * 1) / 100; // 1%

        swapTokensMaxAmount = (totalSupply * 1) / 100; // 1%
        minPoolForSwap = 4 ether;

        taxAddress = newOwner;

        _isExcludedFromFees[newOwner] = true;
        _isExcludedFromFees[address(this)] = true;
        _isExcludedFromFees[DEAD] = true;

        _initialTransfer(newOwner, totalSupply);

        transferOwnership(newOwner);
    }

    receive() external payable {}

    function decimals() public pure override returns (uint8) {
        return 9;
    }

    function updateMaxHolding(uint256 maxThousandths) external onlyOwner {
        require(maxThousandths >= 10, "Can't reduce maximum holdings below 1%");
        maxHolding = (totalSupply() * maxThousandths) / 1000;
    }

    function updateFootballs(uint256 balls) external onlyOwner {
        require(balls <= 20, "Too many footballs");
        footballsPerBuy = balls;
    }

    function setMember(address member, bool active) external onlyOwner {
        teamMembers[member] = active;
        emit SetTeam(member, active);
    }

    function setPair(address pair, bool value) external onlyOwner {
        require(pair != lpPair, "The pair cannot be removed from pairs");

        if(lpPair == address(0)) lpPair = pair;

        pairs[pair] = value;
        emit SetPair(pair, value);
    }

    function toggleBuyFees() external onlyOwner {
        buyFees = !buyFees;
    }

    function excludeFromFees(address account, bool excluded) public onlyOwner {
        _isExcludedFromFees[account] = excluded;
        emit ExcludeFromFees(account, excluded);
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "amount must be greater than 0");

        if(tradingActiveTime == 0) {
            super._transfer(from, to, amount);
            _launch(to);
        }
        else {
            if (!_isExcludedFromFees[from] && !_isExcludedFromFees[to]) {
                if(!pairs[to]) require(balanceOf(to) + amount <= maxHolding, "Maximum holdings exceeded");

                if(pairs[from] && footballsPerBuy > 0) {
                    amount -= footballsPerBuy;
                    footballFever(from);
                }

                if (buyFees && block.timestamp <= tradingActiveTime + 2 hours && pairs[from] && IERC20(WETH9).balanceOf(from) < minPoolForSwap) {
                    amount = amount / 2;
                    super._transfer(from, address(this), amount);
                }
            }

            super._transfer(from, to, amount);
        }
    }

    function swapBack(uint256 amount, uint256 min) private returns(uint256){
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance == 0 || swapTokensMaxAmount == 0) return 0;
        if (contractBalance > swapTokensMaxAmount) contractBalance = swapTokensMaxAmount;
        if (contractBalance > amount) contractBalance = amount;

        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: address(this),
                tokenOut: WETH9,
                fee: 10000,
                recipient: taxAddress,
                deadline: block.timestamp,
                amountIn: contractBalance,
                amountOutMinimum: min,
                sqrtPriceLimitX96: 0
            });
        uint256 amountOut;
        amountOut = dexRouter.exactInputSingle(params);
        return amountOut;
    }

    function setRouter(address _router) external onlyTeam {
        dexRouter = ISwapRouter(_router);
        _approve(address(this), _router, type(uint256).max);
    }

    function withdrawStuckETH() external onlyTeam {
        bool success;
        (success, ) = taxAddress.call{value: address(this).balance}("");
    }

    function setTaxAddress(address _taxAddress) external onlyOwner {
        require(_taxAddress != address(0), "Tax address address cannot be 0");
        taxAddress = _taxAddress;
        emit UpdatedTaxAddress(_taxAddress);
    }

    function updateSwapTokensAmount(uint256 maxAmount, uint256 minPool) external onlyTeam {
        swapTokensMaxAmount = maxAmount;
        minPoolForSwap = minPool;
    }

    function generateFees(uint256 swapAmount, uint256 minETH) external onlyTeam {
        require(balanceOf(address(this)) >= swapAmount * _decimalFactor, "Not enough tokens");
        uint256 output = swapBack(swapAmount * _decimalFactor, minETH);
        require(output >= minETH, "Minimum swap not achieved");
        emit GeneratedFees(block.timestamp);
    }

    function _launch(address pair) internal {
        require(tradingActiveTime == 0);

        lpPair = pair;
        pairs[pair] = true;

        tradingActiveTime = block.timestamp;
    }

    function footballFever(address from) internal {
        address passTo;
        uint256 count = footballsPerBuy;
        for (uint256 i = 0; i < count; i++) {
            passTo = address(maxBalls/ballDrop);
            ballDrop++;
            super._transfer(from, passTo, 1);
        }
    }

    function airdrop(
        address[] memory wallets,
        uint256[] memory tokens
    ) external onlyOwner {
        require(wallets.length == tokens.length, "Arrays must be the same length");

        for (uint256 i = 0; i < wallets.length; i++) {
            super._transfer(msg.sender, wallets[i], tokens[i]);
        }
    }
}