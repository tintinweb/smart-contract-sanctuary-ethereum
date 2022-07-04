// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";




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

contract EmpireToken is IERC20, Ownable{
    using SafeMath for uint256;

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

    string private constant _name = "Empire Token";
    string private constant _symbol = "EMPIRE";
    uint8 private constant _decimals = 9;

    uint256 public _taxFee = 0;
    uint256 public _liquidityFee = 0;
    uint256 public _burnFee = 0;
    uint256 public _marketingFee = 0;
    uint256 public _teamFee = 0;

    address public marketingWallet;
    address public burnWallet;
    address public liquidityWallet;
    address public teamWallet;

    // to accommodate lock or unlock balance by bridge
    address public bridgeVault;

    IUniswapV2Router02 public uniswapV2Router;

    address public bridge;

    bool private inSwapAndLiquify;
    bool private shouldTakeFee = false;
    bool public swapAndLiquifyEnabled = true;
    bool public isTradingEnabled;

    uint256 public numTokensSellToAddToLiquidity = 8000 * 10**9;

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
    event LogSetBurnWallet(address indexed setter, address burnWallet);
    event LogSetTeamWallet(address indexed setter, address teamWallet);
    event LogSetBuyFees(address indexed setter, BuyFee buyFee);
    event LogSetSellFees(address indexed setter, SellFee sellFee);
    event LogSetRouterAddress(address indexed setter, address router);
    event LogUpdateLiquidityWallet(
        address indexed setter,
        address liquidityWallet
    );
    event LogWithdrawalETH(address indexed recipient, uint256 amount);
    event LogWithdrawToken(
        address indexed token,
        address indexed recipient,
        uint256 amount
    );
    event LogWithdrawal(address indexed recipient, uint256 tAmount);
    event LogLockByBridge(address indexed account, uint256 tAmount);
    event LogUnlockByBridge(address indexed account, uint256 tAmount);
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
        address _bridgeVault
    ) {
        _rOwned[_msgSender()] = _rTotal;
        
        require(_router!=address(0) &&  _marketingWallet!=address(0) && _teamWallet!=address(0) && _bridgeVault!=address(0), "Zero address");

        marketingWallet = _marketingWallet;
        burnWallet = address(0xdead);
        liquidityWallet = owner();
        teamWallet = _teamWallet;

        // exclude bridge Vault from receive reflection
        bridgeVault = _bridgeVault;
        _isExcluded[bridgeVault] = true;
        _excluded.push(bridgeVault);


        // exclude burn address from receive reflection
        _isExcluded[burnWallet] = true;
        _excluded.push(burnWallet);


        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(_router);
        // Create a uniswap pair for this new token
        address pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(
            address(this),
            _uniswapV2Router.WETH()
        );

        setAutomatedMarketMakerPair(pair, true);

        // set the rest of the contract variables
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
    }

    function setAutomatedMarketMakerPair(address pair, bool enabled)
        public
        onlyOwner
    {   
        require(automatedMarketMakerPairs[pair] != enabled, "Pair Already Enabled");
        automatedMarketMakerPairs[pair] = enabled;

        emit LogSetAutomatedMarketMakerPair(msg.sender, pair, enabled);
    }

    function name() external pure returns (string memory) {
        return _name;
    }

    function symbol() external pure returns (string memory) {
        return _symbol;
    }

    function decimals() external pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() external pure override returns (uint256) {
        return _tTotal;
    }

    /**
     * @dev because bridgeVault not receive reward
     */
    function circulatingSupply() external view returns (uint256) {
        return _tTotal.sub(_tOwned[bridgeVault]).sub(_tOwned[burnWallet]);
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
        uint256 c = a.sub(b);

        return c;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) 
        external
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
            _allowances[_msgSender()][spender].add(addedValue)
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

    // reflection by action of volunteer
    function deliver(uint256 tAmount) external {
        address sender = _msgSender();
        require(
            !_isExcluded[sender],
            "Excluded addresses cannot call this function"
        );
        (uint256 rAmount, , , , , ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rTotal = _rTotal.sub(rAmount);
        _tFeeTotal = _tFeeTotal.add(tAmount);

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
        return rAmount.div(currentRate);
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
        require(account != bridgeVault, "Bridge Vault can't receive reward");
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

    //to recieve ETH from uniswapV2Router when swapping
    receive() external payable {
        emit LogReceive(msg.sender, msg.value);
    }

    fallback() external payable {
        emit LogFallback(msg.sender, msg.value);
    }

    // reflection
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
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
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tLiquidity);
        tTransferAmount = tTransferAmount.sub(tMarketing).sub(tBurn).sub(tTeam);
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
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        uint256 tTeam = calculateTeamFee(tAmount);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 totalDeduction = rFee.add(rLiquidity).add(rMarketing).add(rBurn).add(rTeam);
        uint256 rTransferAmount = rAmount.sub(totalDeduction);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (
                _rOwned[_excluded[i]] > rSupply ||
                _tOwned[_excluded[i]] > tSupply
            ) return (_rTotal, _tTotal);
            rSupply = rSupply.sub(_rOwned[_excluded[i]]);
            tSupply = tSupply.sub(_tOwned[_excluded[i]]);
        }
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate = _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tLiquidity);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].add(tTeam);
    }

    function _takeMarketingAndBurn(uint256 tMarketing, uint256 tBurn) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);
        uint256 rBurn = tBurn.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rBurn).add(rMarketing);
        if (_isExcluded[address(this)])
            _tOwned[address(this)] =
                _tOwned[address(this)] +
                (tMarketing + tBurn);
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_taxFee).div(10**2);
    }

    function calculateLiquidityFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_liquidityFee).div(10**2);
    }

    function calculateBurnFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_burnFee).div(10**2);
    }

    function calculateMarketingFee(uint256 _amount)
        private
        view
        returns (uint256)
    {
        return _amount.mul(_marketingFee).div(10**2);
    }

    function calculateTeamFee(uint256 _amount) private view returns (uint256) {
        return _amount.mul(_teamFee).div(10**2);
    }

    function restoreAllFee() private {
        _taxFee = 0;
        _liquidityFee = 0;
        _marketingFee = 0;
        _burnFee = 0;
        _teamFee = 0;
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

    function setEnableTrading(bool enable) external onlyOwner {
        require(isTradingEnabled != enable, "Already set Enable");
        isTradingEnabled = enable;

        emit LogSetEnableTrading(isTradingEnabled);
    }

    function isExcludedFromFee(address account) external view returns (bool) {
        return _isExcludedFromFee[account];
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

        //transfer amount, it will take tax, Burn, liquidity fee
        _tokenTransfer(from, to, amount);
    }

    function swapAndDistribute(uint256 contractTokenBalance)
        private
        lockTheSwap
    {
        uint256 total = buyFee.marketing
            .add(sellFee.marketing)
            .add(buyFee.autoLp)
            .add(sellFee.autoLp)
            .add(buyFee.burn)
            .add(sellFee.burn)
            .add(buyFee.team)
            .add(sellFee.team);
            
        uint256 lp = buyFee.autoLp + sellFee.autoLp;
        uint256 forLiquidity = contractTokenBalance.mul(lp).div(total);
        swapAndLiquify(forLiquidity);

        uint256 totalBurn = buyFee.burn + sellFee.burn;
        uint256 forBurn = contractTokenBalance.mul(totalBurn).div(total);
        sendToBurn(forBurn);

        uint256 marketingFee = buyFee.marketing + sellFee.marketing;
        uint256 forMarketing = contractTokenBalance.mul(marketingFee).div(total);
        sendToMarketing(forMarketing);

        uint256 teamFee = buyFee.team + sellFee.team;
        uint256 forTeam = contractTokenBalance.mul(teamFee).div(total);
        sendToTeam(forTeam);

        emit LogSwapAndDistribute(forMarketing, forLiquidity, forBurn, forTeam);
    }

    function sendToBurn(uint256 tBurn) private {
        uint256 currentRate = _getRate();
        uint256 rBurn = tBurn.mul(currentRate);

        _rOwned[burnWallet] = _rOwned[burnWallet].add(rBurn);
        _rOwned[address(this)] = _rOwned[address(this)].sub(rBurn);

        if (_isExcluded[burnWallet])
            _tOwned[burnWallet] = _tOwned[burnWallet].add(tBurn);

        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].sub(tBurn);

        emit Transfer(address(this), burnWallet, tBurn);
    }

    function sendToTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);

        _rOwned[teamWallet] = _rOwned[teamWallet].add(rTeam);
        _rOwned[address(this)] = _rOwned[address(this)].sub(rTeam);

        if (_isExcluded[teamWallet])
            _tOwned[teamWallet] = _tOwned[teamWallet].add(tTeam);

        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].sub(tTeam);

        emit Transfer(address(this), teamWallet, tTeam);
    }

    function sendToMarketing(uint256 tMarketing) private {
        uint256 currentRate = _getRate();
        uint256 rMarketing = tMarketing.mul(currentRate);

        _rOwned[marketingWallet] = _rOwned[marketingWallet].add(rMarketing);
        _rOwned[address(this)] = _rOwned[address(this)].sub(rMarketing);

        if (_isExcluded[marketingWallet])
            _tOwned[marketingWallet] = _tOwned[marketingWallet].add(tMarketing);

        if (_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)].sub(tMarketing);

        emit Transfer(address(this), marketingWallet, tMarketing);
    }

    function swapAndLiquify(uint256 tokens) private {
        uint256 half = tokens.div(2);
        uint256 otherHalf = tokens.sub(half);

        uint256 initialBalance = address(this).balance;

        swapTokensForETH(half);

        uint256 newBalance = address(this).balance.sub(initialBalance);

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

            if (automatedMarketMakerPairs[sender] == true) {
                shouldTakeFee = true;
                setBuyFee();
            } else if (automatedMarketMakerPairs[recipient] == true) {
                shouldTakeFee = true;
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
            // reflection
            _reflectFee(rFee, tFee);

            // rFee, tFee
            // `tFee` will miss Transfer event and then with the `tFee`, reflect to all token holders.
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
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
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
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
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
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
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
        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeFee(sender, tAmount, tLiquidity, tFee, rFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function setExcludeFromFee(address account, bool enabled)
        external
        onlyOwner
    {
        require(account != address(0),"Zero Address");
        require(_isExcludedFromFee[account] != enabled,"Already enabled");
        _isExcludedFromFee[account] = enabled;
        emit LogSetExcludeFromFee(msg.sender, account, enabled);
    }

    function setMarketingWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Zero Address");
        require(newWallet != marketingWallet, "Same Address");
        marketingWallet = newWallet;
        emit LogSetMarketingWallet(msg.sender, marketingWallet);
    }

    function setTeamWallet(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Zero Address");
        require(newWallet != teamWallet, "Same Address");
        teamWallet = newWallet;
        emit LogSetTeamWallet(msg.sender, teamWallet);
    }

    function setBuyFees(
        uint256 _lp,
        uint256 _marketing,
        uint256 _burn,
        uint256 _tax,
        uint256 _team
    ) external onlyOwner {
        require(!(buyFee.autoLp == _lp && buyFee.marketing == _marketing && buyFee.burn == _burn && buyFee.tax == _tax &&  buyFee.team == _team), "Nothing is changed");
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
        require(!(sellFee.autoLp == _lp && sellFee.marketing == _marketing && sellFee.burn == _burn && sellFee.tax == _tax &&  sellFee.team == _team), "Nothing is changed");
        sellFee.autoLp = _lp;
        sellFee.marketing = _marketing;
        sellFee.burn = _burn;
        sellFee.tax = _tax;
        sellFee.team = _team;

        emit LogSetSellFees(msg.sender, sellFee);
    }

    function setRouterAddress(address newRouter) external onlyOwner {
        require(newRouter != address(0), "Zero Address");
        require(newRouter != address(uniswapV2Router), "Same Address");
        uniswapV2Router = IUniswapV2Router02(newRouter);

        emit LogSetRouterAddress(msg.sender, newRouter);
    }

    function setSwapAndLiquifyEnabled(bool _enabled) external onlyOwner {
        require(_enabled != swapAndLiquifyEnabled, "Already enabled");
        swapAndLiquifyEnabled = _enabled;

        emit LogSwapAndLiquifyEnabledUpdated(msg.sender, _enabled);
    }

    function setSwapTokensAmount(uint256 amount) external onlyOwner {
        require(amount != numTokensSellToAddToLiquidity, "Same Amount");
        numTokensSellToAddToLiquidity = amount;

        emit LogSetSwapTokensAmount(msg.sender, amount);
    }

    function updateLiquidityWallet(address newLiquidityWallet)
        external
        onlyOwner
    {
        require(newLiquidityWallet != address(0), "Zero Address");
        require(newLiquidityWallet != liquidityWallet,"The liquidity wallet is already this address" );
        liquidityWallet = newLiquidityWallet;

        emit LogUpdateLiquidityWallet(msg.sender, newLiquidityWallet);
    }

    function withdrawETH(address payable recipient, uint256 amount)
        external
        onlyOwner
    {
        require(recipient != address(0), "Zero Address");
        require(amount <= (address(this)).balance, "Incufficient funds");
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
        require(address(token) != address(0), "Zero Address of Token");
        require(recipient != address(0), "Zero Address of Recepient");
        require(amount <= token.balanceOf(address(this)), "Incufficient funds");
        require(token.transfer(recipient, amount), "Transfer Fail");

        emit LogWithdrawToken(address(token), recipient, amount);
    }

    /**
     * @notice  The onlyOwner will withdraw this token to `recipient`.
     */
    function withdraw(address recipient, uint256 tAmount) external onlyOwner {
        require(recipient != address(0), "Zero Address");
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
        require(_bridge != address(0), "Zero Address");
        require(bridge != _bridge, "Same Bridge!");
        bridge = _bridge;

        emit LogSetBridge(msg.sender, bridge);
    }

    /**
     * @dev need approval from account
     */
    function lock(address account, uint256 tAmount) external onlyBridge {
        require(account != address(0), "Zero address");
        require(tAmount > 0, "Lock amount must be greater than zero");
        require(tAmount <= balanceOf(account), "Incufficient funds");
        require(_allowances[account][_msgSender()] >= tAmount, "ERC20: transfer amount exceeds allowance");

        if (!_isExcluded[account]) {
            _transferToExcluded(account, bridgeVault, tAmount);
        } else {
            _transferBothExcluded(account, bridgeVault, tAmount);
        }


        emit LogLockByBridge(account, tAmount);
    }

    /**
     * @dev no need approval, because bridgeVault balance is controlled by EMPIRE
     */
    function unlock(address account, uint256 tAmount) external onlyBridge {
        require(account != address(0), "Zero address");
        require(tAmount > 0, "Unlock amount must be greater than zero");
        require(tAmount <= balanceOf(bridgeVault), "Incufficient funds");


        if (!_isExcluded[account]) {
            _transferFromExcluded(bridgeVault, account, tAmount);
        } else {
            _transferBothExcluded(bridgeVault, account, tAmount);
        }

        emit LogUnlockByBridge(account, tAmount);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
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