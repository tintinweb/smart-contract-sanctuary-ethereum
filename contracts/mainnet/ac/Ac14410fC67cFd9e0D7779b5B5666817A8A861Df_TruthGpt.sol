/**
 * THE FIRST PUBLIC AI TRUTH DATA TRAINING DAPP ON ETH.
 * Pass the Truth on real-time to the AI Engine.
 * TruthGPT bot will answer anything based on the data.
 * Truth can generate Images.
 * Our ERC20 Token offers a singular opportunity for individuals to secure part-ownership in TruthGPT.
 * In contrast to our competitors, we have already established a functional product with our in-house AI Image Generation.
 *
 * This token grants its holder the benefit of revenue sharing from nine distinct streams and the ability to hold prominent position with the ecosystem.
 * Fixed supply with monthly Buyback and Burn Program.
 *
 * Full details available at our platform: https://truthgpt.me
 * Twitter: https://twitter.com/truthgptme
 * Telegram: https://t.me/truthgptme_portal
 * 1 billion tokens, locked liquidity.
 *
 * Tax: 1% OpenAI Davinci Model Bills, 1% GPU clusters, 1% liquidity
 * Team tokens: 3%
 * Truth Ecosystem Development: 5%
 * Marketing: 4%
 * CEX Listing: 8%
 * 80% Fair Launch
 * Locked liquidity, No pre-sale, No VCs
 *
 * Launch Time is shared with the Telegram community.
 * Set slippage to 3-4% to buy TruthGPT token.
 *
 * truthgpt.me
 */
pragma solidity 0.8.17;

import "./Context.sol";
import "./IERC20.sol";
import "./Ownable.sol";
import "./SafeMath.sol";
import "./IUniswapV2Router02.sol";
import "./IUniswapV2Factory.sol";

contract TruthGpt is Context, IERC20, Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    // token details
    uint8 private constant _decimals = 8;
    uint256 private constant _tTotal = 1000000000 * 10**_decimals;
    string private constant _name = "truthgpt.me";
    string private constant _symbol = "TruthGPT";

    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _bots;

    address payable private _taxWallet;

    uint256 private _initialBuyTax = 10;
    uint256 private _initialSellTax = 15;
    uint256 private _finalTax = 3;
    uint256 private _reduceBuyTaxAt = 1;
    uint256 private _reduceSellTaxAt = 10;
    uint256 private _preventSwapBefore = 30;
    uint256 private _buyCount = 0;

    uint256 public _maxTxAmount = 10000000 * 10**_decimals;
    uint256 public _maxWalletSize = 30000000 * 10**_decimals;
    uint256 public _taxSwapThreshold = 5000000 * 10**_decimals;
    uint256 public _maxTaxSwap = 5000000 * 10**_decimals;

    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;

    bool private tradingOpen = false;
    bool private inSwap = false;
    bool private swapEnabled = false;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    modifier lockTheSwap() {
        inSwap = true;
        _;
        inSwap = false;
    }

    constructor() {
        _taxWallet = payable(_msgSender());
        _balances[_msgSender()] = _tTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_taxWallet] = true;

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
        return _balances[account];
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

        // check if the tranding is open
        if (!tradingOpen) {
            require(
                from == owner() || to == owner(),
                "Trading is not open yet"
            );
        }

        uint256 taxAmount = 0;

        // If any account belongs to _isExcludedFromFee account then remove the fee
        if (from != owner() && to != owner()) {
            require(!_bots[from] && !_bots[to], "Bot is not allowed");

            taxAmount = amount
                .mul((_buyCount > _reduceBuyTaxAt) ? _finalTax : _initialBuyTax)
                .div(100);

            // Buy - AntiWhale
            if (
                from == uniswapV2Pair &&
                to != address(uniswapV2Router) &&
                !_isExcludedFromFee[to]
            ) {
                require(
                    amount <= _maxTxAmount,
                    "Exceeds the max transaction amount"
                );
                require(
                    balanceOf(to) + amount <= _maxWalletSize,
                    "Exceeds the max wallet size"
                );

                _buyCount++;
            }

            // Sell - AntiWhale
            if (to == uniswapV2Pair && from != address(this)) {
                taxAmount = amount
                    .mul(
                        (_buyCount > _reduceSellTaxAt)
                            ? _finalTax
                            : _initialSellTax
                    )
                    .div(100);
            }

            // Swap and liquify
            uint256 contractTokenBalance = balanceOf(address(this));
            if (
                !inSwap &&
                to == uniswapV2Pair &&
                swapEnabled &&
                contractTokenBalance > _taxSwapThreshold &&
                _buyCount > _preventSwapBefore
            ) {
                swapTokensForEth(
                    min(amount, min(contractTokenBalance, _maxTaxSwap))
                );

                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
                }
            }
        }

        if (taxAmount > 0) {
            _balances[address(this)] = _balances[address(this)].add(taxAmount);

            emit Transfer(from, address(this), taxAmount);
        }

        _balances[from] = _balances[from].sub(amount);
        _balances[to] = _balances[to].add(amount.sub(taxAmount));

        emit Transfer(from, to, amount.sub(taxAmount));
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return (a > b) ? b : a;
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

    function removeLimits() external onlyOwner {
        _maxTxAmount = _tTotal;
        _maxWalletSize = _tTotal;

        emit MaxTxAmountUpdated(_tTotal);
    }

    function sendETHToFee(uint256 amount) private {
        _taxWallet.transfer(amount);
    }

    function addBot(address a) external onlyOwner {
        _bots[a] = true;
    }

    function removeBot(address a) external onlyOwner {
        _bots[a] = false;
    }

    function isBot(address a) public view returns (bool) {
        return _bots[a];
    }

    function openTrading(address pair) external onlyOwner {
        require(!tradingOpen, "trading is already open");

        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = pair;

        swapEnabled = true;
        tradingOpen = true;
    }

    receive() external payable {}

    function manualSwap() external {
        require(_msgSender() == _taxWallet);

        uint256 tokenBalance = balanceOf(address(this));
        if (tokenBalance > 0) {
            swapTokensForEth(tokenBalance);
        }

        uint256 ethBalance = address(this).balance;
        if (ethBalance > 0) {
            sendETHToFee(ethBalance);
        }
    }
}