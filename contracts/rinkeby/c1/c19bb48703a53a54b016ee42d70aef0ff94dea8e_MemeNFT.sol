/**
 *Submitted for verification at Etherscan.io on 2022-08-03
*/

//SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.15;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Ownable {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }

    function geUnlockTime() public view returns (uint256) {
        return _lockTime;
    }

    function lock(uint256 time) public virtual onlyOwner {
        _previousOwner = _owner;
        _owner = address(0);
        _lockTime = block.timestamp + time;
        emit OwnershipTransferred(_owner, address(0));
    }

    function unlock() public virtual {
        require(_previousOwner == msg.sender, "You don't have permission to unlock");
        require(block.timestamp > _lockTime , "Contract is locked until 7 days");
        emit OwnershipTransferred(_owner, _previousOwner);
        _owner = _previousOwner;
    }
}


interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
interface IUniswapV2Router01 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
}

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}


contract MemeNFT is IERC20, Ownable {

    address payable public councilWalletAddress = payable(0xF17d535EE94C5E472b277F71DDB9C1ae6F8eAEe8); // Team Address
    address payable public treasuryWalletAddress = payable(0x8DA48F43e271CcCac2f157f5723507e78251F4cc); // Marketing Address

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;

    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBlacklisted;
    address[] private _excluded;

    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 10000000 * 10**3 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;

    string private _name = "MemeNFT";
    string private _symbol = "MNFT";
    uint8 private _decimals = 9;

    uint256 public _taxFee =3;
    uint256 private _previousTaxFee = _taxFee;

    uint256 public _liquidityFee = 2;
    uint256 private _previousLiquidityFee = _liquidityFee;

    uint256 public _councilFee = 1;
    uint256 private _previousCouncilFee = _councilFee;

    uint256 public _treasuryFee = 4;
    uint256 private _previousTreasuryFee = _treasuryFee;

    uint256 public _totalTaxPercent = 0;
    uint256 private _prevTotalTaxPercent = 0;

    uint256 public _maxTxAmount = 5000000 * 10**9;
    uint256 public numTokensSellToAddToLiquidity = 50000 * 10**9;
    uint256 public minNumTokensSellToAddToLiquidity = 50000 * 10**9;

    address private _treasuryAddress = treasuryWalletAddress;
    address private _councilAddress = councilWalletAddress;

    IUniswapV2Router02 public immutable uniswapV2Router;
    address public immutable uniswapV2Pair;

    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public swapAndLiquifyByLimitOnly = false;

    event MinTokensBeforeSwapUpdated(uint256 minTokensBeforeSwap);
    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 ethReceived,
        uint256 tokensIntoLiqudity
    );

    event SwapETHForTokens(
        uint256 amountIn,
        address[] path
    );

    event SwapTokensForETH(
        uint256 amountIn,
        address[] path
    );

    modifier lockTheSwap {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    constructor () {
       _rOwned[msg.sender] = _rTotal;
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
            // Uniswap 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
            // PCS 0x10ED43C718714eb63d5aA57B78B54704E256024E
            //IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x9Ac64Cc6e4415144C455BD8E4837Fea55603e5c3); 
            // Create a uniswap pair for this new token
            uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
                .createPair(address(this), _uniswapV2Router.WETH());
            // set the rest of the contract variables
            uniswapV2Router = _uniswapV2Router;
        //Exclude owner and this contract from fee
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_treasuryAddress] = true;
        _isExcludedFromFee[_councilAddress] = true;
        _isExcluded[uniswapV2Pair] = true;
        _totalTaxPercent = _taxFee+_liquidityFee+_councilFee+_treasuryFee;
        _prevTotalTaxPercent = _totalTaxPercent;
        emit Transfer(address(0), msg.sender, _tTotal);
    }

    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, _allowances[sender][msg.sender]-amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender]+addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        _approve(msg.sender, spender, _allowances[msg.sender][spender]-subtractedValue);
        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function totalFees() public view returns (uint256) {
        return _tFeeTotal;
    }

    function deliver(uint256 tAmount) public {
        address sender = msg.sender;
        require(!_isExcluded[sender], "Excluded addresses cannot call this function");
        (uint256 rAmount,,,,,) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender]-rAmount;
        _rTotal = _rTotal-rAmount;
        _tFeeTotal = _tFeeTotal+tAmount;
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
        return rAmount/currentRate;
    }

    function excludeFromReward(address account) public onlyOwner() {
        // require(account != 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D, 'We can not exclude Uniswap router.');
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is already excluded");
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_excluded[i] == account) {
                _excluded[i] = _excluded[_excluded.length - 1];
                _tOwned[account] = 0;
                _isExcluded[account] = false;
                _excluded.pop();
                break;
            }
        }
    }

    function excludeFromFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = true;
    }

    function includeInFee(address account) public onlyOwner {
        _isExcludedFromFee[account] = false;
    }

    function setSwapAndLiquifyByLimitOnly(bool newValue) public onlyOwner {
        swapAndLiquifyByLimitOnly = newValue;
    }

    function setNumTokensBeforeSwap(uint256 newLimit) external onlyOwner() {
        minNumTokensSellToAddToLiquidity = newLimit;
    }

        function setTaxes(uint256 newLiquidityTax, uint256 newCouncilTax, uint256 newTreasuryTax, uint256 newTaxFee) external onlyOwner() {
        _liquidityFee = newLiquidityTax;
        _councilFee = newCouncilTax;
        _treasuryFee = newTreasuryTax;
        _taxFee = newTaxFee;
        _totalTaxPercent = _liquidityFee+_councilFee+_treasuryFee+_taxFee;
        _prevTotalTaxPercent = _totalTaxPercent;
    }

    function setcouncilWalletAddress(address newAddress) external onlyOwner() {
        councilWalletAddress = payable(newAddress);
    }

    function settreasuryWalletAddress(address newAddress) external onlyOwner() {
        treasuryWalletAddress = payable(newAddress);
    }



    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        _maxTxAmount = _tTotal*maxTxPercent/(
            10**2
        );
    }

    function setSwapAndLiquifyEnabled(bool _enabled) public onlyOwner {
        swapAndLiquifyEnabled = _enabled;
        emit SwapAndLiquifyEnabledUpdated(_enabled);
    }

     //to recieve ETH from uniswapV2Router when swaping
    receive() external payable {}

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal-rFee;
        _tFeeTotal = _tFeeTotal+tFee;
    }

    function _getValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tLiquidity, uint256 tCouncil, uint256 tTreasury) = _getTValues(tAmount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tLiquidity, tCouncil, tTreasury, _getRate());

        uint256 tOtherFee = tLiquidity+tCouncil+tTreasury;
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tOtherFee);
    }

    function _getTValues(uint256 tAmount) private view returns (uint256, uint256, uint256, uint256, uint256) {
        uint256 tFee = calculateTaxFee(tAmount);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tCouncil = calculateCouncilFee(tAmount);
        uint256 tTreasury = calculateTreasuryFee(tAmount);
        uint256 tTransferAmount = tAmount-tFee-tLiquidity;
        tTransferAmount = tTransferAmount-tCouncil-tTreasury;
        return (tTransferAmount, tFee, tLiquidity, tCouncil, tTreasury);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tLiquidity, uint256 tCouncil, uint256 tTreasury, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount*currentRate;
        uint256 rFee = tFee*currentRate;
        uint256 rLiquidity = tLiquidity*currentRate;
        uint256 rCouncil = tCouncil*currentRate;
        uint256 rTreasury = tTreasury*currentRate;
        uint256 rTransferAmount = rAmount-rFee-rLiquidity;
        rTransferAmount = rTransferAmount-rCouncil-rTreasury;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        for (uint256 i = 0; i < _excluded.length; i++) {
            if (_rOwned[_excluded[i]] > rSupply || _tOwned[_excluded[i]] > tSupply) return (_rTotal, _tTotal);
            rSupply = rSupply-_rOwned[_excluded[i]];
            tSupply = tSupply-_tOwned[_excluded[i]];
        }
        if (rSupply < _rTotal/_tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity*currentRate;
        _rOwned[address(this)] = _rOwned[address(this)]+rLiquidity;
        if(_isExcluded[address(this)])
            _tOwned[address(this)] = _tOwned[address(this)]+tLiquidity;
    }

    function _takeCouncil(uint256 tCouncil) private {
        uint256 currentRate =  _getRate();
        uint256 rCouncil = tCouncil*currentRate;
        _rOwned[_councilAddress] = _rOwned[_councilAddress]+rCouncil;
        if(_isExcluded[_councilAddress])
            _tOwned[_councilAddress] = _tOwned[_councilAddress]+tCouncil;
    }

    function _takeTreasury(uint256 tTreasury) private {
        uint256 currentRate =  _getRate();
        uint256 rTreasury = tTreasury*currentRate;
        _rOwned[_treasuryAddress] = _rOwned[_treasuryAddress]+rTreasury;
        if(_isExcluded[_treasuryAddress])
            _tOwned[_treasuryAddress] = _tOwned[_treasuryAddress]+tTreasury;
    }

    function calculateTaxFee(uint256 _amount) private view returns (uint256) {
        return _amount*_taxFee/(
            10**2
        );
    }

    function calculateLiquidityFee(uint256 _amount) private view returns (uint256) {
        return _amount*_liquidityFee/(
            10**2
        );
    }

    function calculateCouncilFee(uint256 _amount) private view returns (uint256) {
        return _amount*_councilFee/(
            10**2
        );
    }

    function calculateTreasuryFee(uint256 _amount) private view returns (uint256) {
        return _amount*_treasuryFee/(
            10**2
        );
    }

    function removeAllFee() private {
        if(_taxFee == 0 && _liquidityFee == 0 && _councilFee == 0 && _treasuryFee == 0) return;

        _previousTaxFee = _taxFee;
        _previousLiquidityFee = _liquidityFee;
        _previousCouncilFee = _councilFee;
        _previousTreasuryFee = _treasuryFee;

        _taxFee = 0;
        _liquidityFee = 0;
        _councilFee = 0;
        _treasuryFee = 0;
    }

    function restoreAllFee() private {
        _taxFee = _previousTaxFee;
        _liquidityFee = _previousLiquidityFee;
        _councilFee = _previousCouncilFee;
        _treasuryFee = _previousTreasuryFee;
    }

    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        if(from != owner() && to != owner())
            require(amount <= _maxTxAmount, "Transfer amount exceeds the maxTxAmount.");

        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= numTokensSellToAddToLiquidity;

        if(overMinimumTokenBalance && !inSwapAndLiquify && from != uniswapV2Pair && swapAndLiquifyEnabled)
        {
            if(swapAndLiquifyByLimitOnly)
                contractTokenBalance = numTokensSellToAddToLiquidity;
            swapAndLiquify(contractTokenBalance);
        }

        bool takefee = true;

        if(_isExcludedFromFee[from] || _isExcludedFromFee[to]){
            takefee = false;
        }
        if(from != uniswapV2Pair && to != uniswapV2Pair){
                takefee = false;
            }

        _tokenTransfer(from,to,amount,takefee);
    }

    function swapAndLiquify(uint256 contractTokenBalance) private lockTheSwap {

        uint256 forLiquidity = contractTokenBalance/(_totalTaxPercent*_liquidityFee);
        uint256 forWallets = contractTokenBalance-forLiquidity;

        if(forLiquidity > 0)
        {
            uint256 half = forLiquidity/2;
            uint256 otherHalf = forLiquidity-half;

            uint256 initialBalance = address(this).balance;
            swapTokensForEth(half);
            uint256 newBalance = address(this).balance-initialBalance;
            addLiquidity(otherHalf, newBalance);
            emit SwapAndLiquify(half, newBalance, otherHalf);
        }

        if(forWallets > 0 && _councilFee+_treasuryFee > 0)
        {
            uint256 initialBalance = address(this).balance;
            swapTokensForEth(forWallets);
            uint256 newBalance = address(this).balance-initialBalance;

            uint256 marketingShare = newBalance/((_councilFee+_treasuryFee)*_councilFee);
            uint256 WalletShare = newBalance-marketingShare;

            if(marketingShare > 0)
                transferToAddressETH(councilWalletAddress, marketingShare);

            if(WalletShare > 0)
                transferToAddressETH(treasuryWalletAddress, WalletShare);
        }
    }


    function swapTokensForEth(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // make the swap
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );

        emit SwapTokensForETH(tokenAmount, path);
    }

    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(uniswapV2Router), tokenAmount);

        // add the liquidity
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            owner(),
            block.timestamp
        );
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 amount,bool takeFee) private {
       if(!takeFee)
            removeAllFee();

        if (_isExcluded[sender] && !_isExcluded[recipient]) {
            _transferFromExcluded(sender, recipient, amount);
        } else if (!_isExcluded[sender] && _isExcluded[recipient]) {
            _transferToExcluded(sender, recipient, amount);
        } else if (_isExcluded[sender] && _isExcluded[recipient]) {
            _transferBothExcluded(sender, recipient, amount);
        } else {
            _transferStandard(sender, recipient, amount);
        }

        if(!takeFee)
            restoreAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tOtherFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender]-rAmount;
        _rOwned[recipient] = _rOwned[recipient]+rTransferAmount;
        uint256 otherFee = _getOtherFee();
        uint256 tLiquidity = tOtherFee*_liquidityFee/otherFee;
        uint256 tCouncil = tOtherFee*_councilFee/otherFee;
        uint256 tTreasury = tOtherFee*_treasuryFee/otherFee;
        _takeLiquidity(tLiquidity);
        _takeCouncil(tCouncil);
        _takeTreasury(tTreasury);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferToExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tOtherFee) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender]-rAmount;
        _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient]+rTransferAmount;
        uint256 otherFee = _getOtherFee();
        uint256 tLiquidity = tOtherFee*_liquidityFee/otherFee;
        uint256 tCouncil = tOtherFee*_councilFee/otherFee;
        uint256 tTreasury = tOtherFee*_treasuryFee/otherFee;
        _takeLiquidity(tLiquidity);
        _takeCouncil(tCouncil);
        _takeTreasury(tTreasury);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _transferFromExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tOtherFee) = _getValues(tAmount);
        _tOwned[sender] = _tOwned[sender]-tAmount;
        _rOwned[sender] = _rOwned[sender]-rAmount;
        _rOwned[recipient] = _rOwned[recipient]+rTransferAmount;
        uint256 otherFee = _getOtherFee();
        uint256 tLiquidity = tOtherFee*_liquidityFee/otherFee;
        uint256 tCouncil = tOtherFee*_councilFee/otherFee;
        uint256 tTreasury = tOtherFee*_treasuryFee/otherFee;
        _takeLiquidity(tLiquidity);
        _takeCouncil(tCouncil);
        _takeTreasury(tTreasury);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

       function _getOtherFee() private view returns (uint256) {
        uint256  otherFee = _previousLiquidityFee+_previousCouncilFee+_previousTreasuryFee;
        return otherFee;
    }

    function _transferBothExcluded(address sender, address recipient, uint256 tAmount) private {
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tOtherFee) = _getValues(tAmount);
    	_tOwned[sender] = _tOwned[sender]-tAmount;
        _rOwned[sender] = _rOwned[sender]-rAmount;
        _tOwned[recipient] = _tOwned[recipient]+tTransferAmount;
        _rOwned[recipient] = _rOwned[recipient]+rTransferAmount;
        uint256 otherFee = _getOtherFee();
        uint256 tLiquidity = tOtherFee*_liquidityFee/otherFee;
        uint256 tCouncil = tOtherFee*_councilFee/otherFee;
        uint256 tTreasury = tOtherFee*_treasuryFee/otherFee;
        _takeLiquidity(tLiquidity);
        _takeCouncil(tCouncil);
        _takeTreasury(tTreasury);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _withdrawETH(uint256 amount) external onlyOwner() {
        require(amount <= address(this).balance, 'withdrawETH::Insufficient amount');
        payable(msg.sender).transfer(amount);
        emit Transfer(address(this), msg.sender, amount);
    }

      function transferToAddressETH(address payable recipient, uint256 amount) private {
        recipient.transfer(amount);
    }


    function inCaseTokensGetStuck(address _token, uint256 _amount, address _to) external onlyOwner() {
        require(_token != address(this), 'inCaseTokensGetStuck: Native token transfer is unavailable');
        IERC20(_token).transfer(_to, _amount);
    }

    function setNumTokensSellToAddToLiquidity(uint256 _numTokensSellToAddToLiquidity) public onlyOwner() {
        require(_numTokensSellToAddToLiquidity >= minNumTokensSellToAddToLiquidity, "numTokens should be larger than min value");
        numTokensSellToAddToLiquidity = _numTokensSellToAddToLiquidity;
    }

    //removeFromBlackList
        function removeFromBlackList(address account) external onlyOwner{
        _isBlacklisted[account] = false;
        }
         //adding multiple address to the blacklist - used to manually block known bots and scammers
        function addToBlackList(address[] calldata  addresses) external onlyOwner {
        for(uint256 i; i < addresses.length; ++i) {
            _isBlacklisted[addresses[i]] = true;
            }
        }
}