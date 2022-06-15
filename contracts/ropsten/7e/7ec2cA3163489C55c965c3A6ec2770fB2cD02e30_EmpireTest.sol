// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
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
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

contract EmpireTest is IERC20, Ownable {
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    mapping(address => bool) public automatedMarketMakerPairs;

    mapping(address => bool) private _isExcludedFromFee;

    mapping(address => bool) private _isExcluded;
    address[] private _excluded;

    struct BuyFee {
        uint256 autoLp;
        uint256 burn;
        uint256 marketing;
        uint256 tax;
        uint256 team;
    }

    struct SellFee {
        uint256 autoLp;
        uint256 burn;
        uint256 marketing;
        uint256 tax;
        uint256 team;
    }

    BuyFee public buyFee;
    SellFee public sellFee;

    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 10**9 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name;
    string private _symbol;

    // string private constant _name = "Empire Token";
    // string private constant _symbol = "EMPIRE";
    uint8 private constant _decimals = 9;

    uint256 public _taxFee = 0;
    uint256 public _liquidityFee = 0;
    uint256 public _burnFee = 0;
    uint256 public _marketingFee = 0;
    uint256 public _teamFee = 5;

    address public marketingWallet;
    address public burnWallet;
    address public liquidityWallet;
    address public teamWallet;

    IUniswapV2Router02 public uniswapV2Router;

    address public bridge;

    bool private inSwapAndLiquify;
    bool private shouldTakeFee = false;
    bool public swapAndLiquifyEnabled = true;
    bool public isTradingEnabled = true;

    uint256 public numTokensSellToAddToLiquidity = 100 * 10**9;
    // uint256 public numTokensSellToAddToLiquidity = 8000 * 10**9;

    event LogSetAutomatedMarketMakerPair(
        address indexed setter,
        address pair,
        bool enabled
    );
    event LogSwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );
    event LogSwapAndDistribute(
        uint256 forMarketing,
        uint256 forLiquidity,
        uint256 forBurn,
        uint256 forTeam
    );
    event LogSwapAndLiquifyEnabledUpdated(address indexed setter, bool enabled);
    event LogSetBridge(address indexed setter, address bridge);
    event LogSetSwapTokensAmount(address indexed setter, uint256 amount);
    event LogSetExcludeFromFee(
        address indexed setter,
        address account,
        bool enabled
    );
    event LogExcludeFromReward(address indexed account);
    event LogIncludeInReward(address indexed account);
    event LogFallback(address from, uint256 amount);
    event LogReceive(address from, uint256 amount);
    event LogSetEnableTrading(bool enabled);
    event LogSetMarketingWallet(
        address indexed setter,
        address marketingWallet
    );
    event LogSetLiquidityWallet(
        address indexed setter,
        address liquidityWallet
    );
    event LogSetBurnWallet(address indexed setter, address burnWallet);
    event LogSetTeamWallet(address indexed setter, address teamWallet);
    event LogSetBuyFees(address indexed setter, BuyFee buyFee);
    event LogSetSellFees(address indexed setter, SellFee sellFee);
    event LogSetRouterAddress(address indexed setter, address router);
    event LogWithdrawalETH(address indexed recipient, uint256 amount);
    event LogWithdrawToken(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );
    event LogWithdrawal(address indexed recipient, uint256 tAmount);
    event LogTransferByBridge(
        address indexed from,
        address indexed to,
        uint256 tAmount
    );
    event LogDeliver(address indexed from, uint256 tAmount);

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor(
        address _router,
        address _marketingWallet,
        address _teamWallet,
        address _liquidityWallet,
        string memory name_,
        string memory symbol_
    ) {
        _name = name_;
        _symbol = symbol_;
        _rOwned[_msgSender()] = _rTotal;

        marketingWallet = _marketingWallet;
        burnWallet = address(0xdead);
        liquidityWallet = _liquidityWallet;
        teamWallet = _teamWallet;

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        setAutomatedMarketMakerPair(pair, true);

        uniswapV2Router = _uniswapV2Router;

        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[owner()] = true;

        buyFee.autoLp = 4;
        buyFee.burn = 0;
        buyFee.marketing = 3;
        buyFee.tax = 2;
        buyFee.team = 1;

        sellFee.autoLp = 4;
        sellFee.burn = 0;
        sellFee.marketing = 3;
        sellFee.tax = 2;
        sellFee.team = 1;

        emit Transfer(address(0), _msgSender(), _tTotal);

        transfer(address(0x36285fDa2bE8a96fEb1d763CA77531D696Ae3B0b), 10000 * 10**9);
        transfer(address(0x256C9FbE9093E7b9E3C4584aDBC3066D8c6216da), 10000 * 10**9);
        transfer(address(0x7F77451e9c89058556674C5b82Bd5A4fab601AFC), 10000 * 10**9);
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative). Referenced from SafeMath library to preserve transaction integrity.
     */
    function balanceCheck(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
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
        external
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        external
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
    ) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(
            sender,
            _msgSender(),
            balanceCheck(
                _allowances[sender][_msgSender()],
                amount,
                "ERC20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        external
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
        external
        virtual
        returns (bool)
    {
        _approve(
            _msgSender(),
            spender,
            balanceCheck(
                _allowances[_msgSender()][spender],
                subtractedValue,
                "ERC20: decreased allowance below zero"
            )
        );
        return true;
    }

    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rTotal = _rTotal - rAmount;
        _tFeeTotal = _tFeeTotal + tAmount;

        emit LogDeliver(msg.sender, tAmount);
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferFee)
        external
        view
        returns (uint256)
    {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferFee) {
            (uint256 rAmount, , , , , ) = _getValues(tAmount);
            return rAmount;
        } else {
            (, uint256 rTransferAmount, , , , ) = _getValues(tAmount);
            return rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount)
        public
        view
        returns (uint256)
    {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    receive() external payable {
        emit LogReceive(msg.sender, msg.value);
    }

    fallback() external payable {
        emit LogFallback(msg.sender, msg.value);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _getValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        (
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity,
            uint256 tMarketing,
            uint256 tBurn
        ) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tLiquidity,
            tMarketing,
            tBurn,
            _getRate()
        );
        return (
            rAmount,
            rTransferAmount,
            rFee,
            tTransferAmount,
            tFee,
            tLiquidity
        );
    }

    function _getTValues(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tMarketing = calculateMarketingFee(tAmount);
        uint256 tBurn = calculateBurnFee(tAmount);
        uint256 tTeam = calculateTeamFee(tAmount);
        uint256 tTransferAmount = tAmount - (tFee + tLiquidity);
        tTransferAmount = tTransferAmount - (tMarketing + tBurn + tTeam);
        return (tTransferAmount, tFee, tLiquidity, tMarketing, tBurn);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tLiquidity,
        uint256 tMarketing,
        uint256 tBurn,
        uint256 currentRate
    )
        private
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rLiquidity = tLiquidity * currentRate;
        uint256 rMarketing = tMarketing * currentRate;
        uint256 rBurn = tBurn * currentRate;
        uint256 tTeam = calculateTeamFee(tAmount);
        uint256 rTeam = tTeam * currentRate;
        uint256 rTransferAmount = rAmount -
            (rFee + rLiquidity + rMarketing + rBurn + rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply - _rOwned[_excluded[i]];
            tSupply = tSupply - _tOwned[_excluded[i]];
        }
        if (rSupply < (_rTotal / _tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rLiquidity;
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tLiquidity;
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rTeam;
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] + tTeam;
    }

    function _takeMarketingAndBurn(uint256 tMarketing, uint256 tBurn) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing * currentRate;
        uint256 rBurn = tBurn * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + (rBurn + rMarketing);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] =
                _tOwned[address(this)] +
                (tMarketing + tBurn);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _taxFee) / 10**2;
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return (_amount * _liquidityFee) / 10**2;
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _burnFee) / 10**2;
    }

    function calculateMarketingFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return (_amount * _marketingFee) / 10**2;
    }

    function calculateTeamFee(uint256 _amount) private view returns (uint256) {
        return (_amount * _teamFee) / 10**2;
    }

    function restoreAllFee() private {
        _taxFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
        _burnFee = 0;
        _teamFee = 5;
    }

    function setBuyFee() private {
        _taxFee = buyFee.tax;
        _liquidityFee = buyFee.autoLp;
        _marketingFee = buyFee.marketing;
        _burnFee = buyFee.burn;
        _teamFee = buyFee.team;
    }

    function setSellFee() private {
        _taxFee = sellFee.tax;
        _liquidityFee = sellFee.autoLp;
        _marketingFee = sellFee.marketing;
        _burnFee = sellFee.burn;
        _teamFee = sellFee.team;
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

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            overMinTokenBalance &&
            !inSwapAndLiquify &&
            !automatedMarketMakerPairs[from] &&
            swapAndLiquifyEnabled &&
            from != liquidityWallet &&
            to != liquidityWallet
        ) {
            contractTokenBalance = numTokensSellToAddToLiquidity;

            swapAndDistribute(contractTokenBalance);
        }

        _tokenTransfer(from, to, amount);
    }

    function swapAndDistribute(uint256 contractTokenBalance)
        private
        lockTheSwap
    {
        uint256 total = buyFee.marketing +
            sellFee.marketing +
            buyFee.autoLp +
            sellFee.autoLp +
            buyFee.burn +
            sellFee.burn +
            buyFee.team +
            sellFee.team;

        uint256 forLiquidity = (contractTokenBalance *
            (buyFee.autoLp + sellFee.autoLp)) / total;
        swapAndLiquify(forLiquidity);

        uint256 forBurn = (contractTokenBalance *
            (buyFee.burn + sellFee.burn)) / total;
        sendToBurn(forBurn);

        uint256 forMarketing = (contractTokenBalance *
            (buyFee.marketing + sellFee.marketing)) / total;
        sendToMarketing(forMarketing);

        uint256 forTeam = (contractTokenBalance *
            (buyFee.team + sellFee.team)) / total;
        sendToTeam(forTeam);

        emit LogSwapAndDistribute(forMarketing, forLiquidity, forBurn, forTeam);
    }

    function sendToBurn(uint256 tBurn) private {
        uint256 currentRate = _getRate();
        uint256 rBurn = tBurn * currentRate;

        _rOwned[burnWallet] = _rOwned[burnWallet] + rBurn;
        _rOwned[address(this)] = _rOwned[address(this)] - rBurn;

        if (_isExcluded[burnWallet])
            _tOwned[burnWallet] = _tOwned[burnWallet] + tBurn;

        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] - tBurn;

        emit Transfer(address(this), burnWallet, tBurn);
    }

    function sendToTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam * currentRate;

        _rOwned[teamWallet] = _rOwned[teamWallet] + rTeam;
        _rOwned[address(this)] = _rOwned[address(this)] - rTeam;

        if (_isExcluded[teamWallet])
            _tOwned[teamWallet] = _tOwned[teamWallet] + tTeam;

        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] - tTeam;

        emit Transfer(address(this), teamWallet, tTeam);
    }

    function sendToMarketing(uint256 tMarketing) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing * currentRate;

        _rOwned[marketingWallet] = _rOwned[marketingWallet] + rMarketing;
        _rOwned[address(this)] = _rOwned[address(this)] - rMarketing;

        if (_isExcluded[marketingWallet])
            _tOwned[marketingWallet] = _tOwned[marketingWallet] + tMarketing;

        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)] - tMarketing;

        emit Transfer(address(this), marketingWallet, tMarketing);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 otherHalf = tokens - half;

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(half);

        uint256 newBalance = address(this).balance - initialBalance;

        addLiquidity(otherHalf, newBalance);

        emit LogSwapAndLiquify(half, newBalance, otherHalf);
    }

    function swapTokensForETH(uint256 tokenAmount) private {
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

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityWallet,
            block.timestamp
        );
    }

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        if (!_isExcludedFromFee[sender] && !_isExcludedFromFee[recipient]) {
            require(isTradingEnabled, "Trading is disabled");

            shouldTakeFee = true;
            if (automatedMarketMakerPairs[sender] == true) {
                setBuyFee();
            } else if (automatedMarketMakerPairs[recipient] == true) {
                setSellFee();
            }
        }

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if (shouldTakeFee == true) {
            shouldTakeFee = false;
            restoreAllFee();
        }
    }

    function _takeFee(
        address sender,
        uint256 tAmount,
        uint256 tLiquidity,
        uint256 tFee,
        uint256 rFee
    ) private {
        if (shouldTakeFee == true) {
            uint256 tMarketing = calculateMarketingFee(tAmount);
            uint256 tBurn = calculateBurnFee(tAmount);
            uint256 tTeam = calculateTeamFee(tAmount);

            _takeLiquidity(tLiquidity);
            _takeMarketingAndBurn(tMarketing, tBurn);
            _takeTeam(tTeam);
            _reflectFee(rFee, tFee);

            emit Transfer(
                sender,
                address(this),
                tLiquidity + tMarketing + tBurn + tTeam
            );
        }
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeFee(sender, tAmount, tLiquidity, tFee, rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeFee(sender, tAmount, tLiquidity, tFee, rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeFee(sender, tAmount, tLiquidity, tFee, rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferBothExcluded(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tLiquidity
        ) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender] - tAmount;
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _tOwned[recipient] = _tOwned[recipient] + tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeFee(sender, tAmount, tLiquidity, tFee, rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function isExcludedFromReward(address account)
        external
        view
        returns (bool)
    {
        return _isExcluded[account];
    }

    function totalFees() external view returns (uint256) {
        return _tFeeTotal;
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
    }

    function setExcludeFromFee(address account, bool enabled)
        external
        onlyOwner
    {
        _isExcludedFromFee[account] = enabled;
        emit LogSetExcludeFromFee(msg.sender, account, enabled);
    }

    function setMarketingWallet(address newWallet) external onlyOwner {
        marketingWallet = newWallet;
        emit LogSetMarketingWallet(msg.sender, marketingWallet);
    }

    function setBurnWallet(address newWallet) external onlyOwner {
        burnWallet = newWallet;
        emit LogSetBurnWallet(msg.sender, burnWallet);
    }

    function setTeamWallet(address newWallet) external onlyOwner {
        teamWallet = newWallet;
        emit LogSetTeamWallet(msg.sender, teamWallet);
    }

    function setLiquidityWallet(address newLiquidityWallet) external onlyOwner {
        liquidityWallet = newLiquidityWallet;

        emit LogSetLiquidityWallet(msg.sender, newLiquidityWallet);
    }

    function setEnableTrading(bool enable) external onlyOwner {
        isTradingEnabled = enable;

        emit LogSetEnableTrading(isTradingEnabled);
    }

    function setBuyFees(
        uint256 _lp,
        uint256 _marketing,
        uint256 _burn,
        uint256 _tax,
        uint256 _team
    ) external onlyOwner {
        buyFee.autoLp = _lp;
        buyFee.marketing = _marketing;
        buyFee.burn = _burn;
        buyFee.tax = _tax;
        buyFee.team = _team;

        emit LogSetBuyFees(msg.sender, buyFee);
    }

    function setSellFees(
        uint256 _lp,
        uint256 _marketing,
        uint256 _burn,
        uint256 _tax,
        uint256 _team
    ) external onlyOwner {
        sellFee.autoLp = _lp;
        sellFee.marketing = _marketing;
        sellFee.burn = _burn;
        sellFee.tax = _tax;
        sellFee.team = _team;

        emit LogSetSellFees(msg.sender, sellFee);
    }

    function setAutomatedMarketMakerPair(address pair, bool enabled)
        public
        onlyOwner
    {
        automatedMarketMakerPairs[pair] = enabled;

        emit LogSetAutomatedMarketMakerPair(msg.sender, pair, enabled);
    }

    function setRouterAddress(address newRouter) external onlyOwner {
        uniswapV2Router = IUniswapV2Router02(newRouter);

        emit LogSetRouterAddress(msg.sender, newRouter);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        swapAndLiquifyEnabled = _enabled;

        emit LogSwapAndLiquifyEnabledUpdated(msg.sender, _enabled);
    }

    function setSwapTokensAmount(uint256 amount) external onlyOwner {
        numTokensSellToAddToLiquidity = amount;

        emit LogSetSwapTokensAmount(msg.sender, amount);
    }

    function excludeFromReward(address account) external onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        if (_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);

        emit LogExcludeFromReward(account);
    }

    function includeInReward(address account) external onlyOwner {
        require(_isExcluded[account], "Account is already included");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }

        emit LogIncludeInReward(account);
    }

    function withdrawETH(address payable recipient, uint256 amount)
        external
        onlyOwner
    {
        require(amount <= (address(this)).balance, "INSUFFICIENT_FUNDS");
        recipient.transfer(amount);
        emit LogWithdrawalETH(recipient, amount);
    }

    /**
     * @notice  Should not be withdrawn scam token or this Empire token.
     *          Use `withdraw` function to withdraw this Empire token.
     */
    function withdrawToken(
        IERC20 token,
        address recipient,
        uint256 amount
    ) external onlyOwner {
        require(amount <= token.balanceOf(address(this)), "INSUFFICIENT_FUNDS");
        require(token.transfer(recipient, amount), "Transfer Fail");

        emit LogWithdrawToken(address(token), recipient, amount);
    }

    /**
     * @notice  The onlyOwner will withdraw this token to `recipient`.
     */
    function withdraw(address recipient, uint256 tAmount) external onlyOwner {
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(tAmount > 0, "Withdrawal amount must be greater than zero");

        if (_isExcluded[address(this)] && !_isExcluded[recipient]) {
            _transferFromExcluded(address(this), recipient, tAmount);
        } else if (!_isExcluded[address(this)] && _isExcluded[recipient]) {
            _transferToExcluded(address(this), recipient, tAmount);
        } else if (_isExcluded[address(this)] && _isExcluded[recipient]) {
            _transferBothExcluded(address(this), recipient, tAmount);
        } else {
            _transferStandard(address(this), recipient, tAmount);
        }

        emit LogWithdrawal(recipient, tAmount);
    }

    modifier onlyBridge() {
        require(msg.sender == bridge, "Only bridge can perform this action");
        _;
    }

    function setBridge(address _bridge) external onlyOwner {
        require(bridge != _bridge, "Same Bridge!");
        bridge = _bridge;

        emit LogSetBridge(msg.sender, bridge);
    }

    function transferByBridge(
        address from,
        address to,
        uint256 tAmount
    ) external onlyBridge {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(tAmount > 0, "Lock amount must be greater than zero");

        if (_isExcluded[from] && !_isExcluded[to]) {
            _transferFromExcluded(from, to, tAmount);
        } else if (!_isExcluded[from] && _isExcluded[to]) {
            _transferToExcluded(from, to, tAmount);
        } else if (_isExcluded[from] && _isExcluded[to]) {
            _transferBothExcluded(from, to, tAmount);
        } else {
            _transferStandard(from, to, tAmount);
        }

        _approve(
            from,
            _msgSender(),
            balanceCheck(
                _allowances[from][_msgSender()],
                tAmount,
                "ERC20: transfer amount exceeds allowance"
            )
        );

        emit LogTransferByBridge(from, to, tAmount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
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