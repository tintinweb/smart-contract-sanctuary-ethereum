/**
 *Submitted for verification at Etherscan.io on 2022-10-14
*/

/**
 *Submitted for verification at Etherscan.io on 2022-10-12
*/

// SPDX-License-Identifier: NOLICENSE
pragma solidity ^0.8.14;

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
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

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}

contract Fmoney is Context, IERC20, Ownable {

    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
    mapping (address => bool) private _isBot;

    address[] private _excluded;
    
    bool public swapEnabled;
    bool private swapping;

    IRouter public router;
    address public pair;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 10e9 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    
    uint256 public swapTokensAtAmount = 5_000_000 * 10**_decimals;
    uint256 public maxTxAmount = 5_000_000 * 10**_decimals;
    bool private maxTxAmountFilterEnabled = true;
    
    // Anti Dump //
    mapping (address => uint256) public _lastTrade;
    bool private coolDownEnabled = true;
    uint256 public coolDownTime = 10 seconds;

    address public treasuryAddress = 0x6cd8B2464779C8F18EC2d5576C43266d4bEE197e;
    address public megaPoolAddress = 0x45B5AA9BB3041e69f125841E451372805f34A69D;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;
    address public lpRecipient = 0x8b49089bd60B69D111FbA4cE2DaEc92316631d86;

    string private constant _name = "FMONEY TOKEN";
    string private constant _symbol = "FMON";

    struct Taxes {
      uint256 rfi;
      uint256 treasury;
      uint256 megaPool;
      uint256 burn;
      uint256 liquidity;
    }

    Taxes public taxes = Taxes(10,10,10,0,0);

    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 treasury;
        uint256 megaPool;
        uint256 burn;
        uint256 liquidity;
    }
    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rTreasury;
      uint256 rMegaPool;
      uint256 rBurn;
      uint256 rLiquidity;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tTreasury;
      uint256 tMegaPool;
      uint256 tBurn;
      uint256 tLiquidity;
    }

    event FeesChanged();
    event UpdatedRouter(address oldRouter, address newRouter);

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    constructor (address routerAddress) {
        IRouter _router = IRouter(routerAddress);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;
        
        excludeFromReward(pair);

        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[treasuryAddress]=true;
        _isExcludedFromFee[burnAddress] = true;
        _isExcludedFromFee[megaPoolAddress] = true;
        _isExcludedFromFee[lpRecipient] = true;

        emit Transfer(address(0), owner(), _tTotal);
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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        if (_isExcluded[account]) return _tOwned[account];
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        _approve(_msgSender(), spender, currentAllowance - subtractedValue);

        return true;
    }

    function isExcludedFromReward(address account) public view returns (bool) {
        return _isExcluded[account];
    }

    function reflectionFromToken(uint256 tAmount, bool deductTransferRfi) public view returns(uint256) {
        require(tAmount <= _tTotal, "Amount must be less than supply");
        if (!deductTransferRfi) {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rAmount;
        } else {
            valuesFromGetValues memory s = _getValues(tAmount, true);
            return s.rTransferAmount;
        }
    }

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    function excludeFromReward(address account) public onlyOwner() {
        require(!_isExcluded[account], "Account is already excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
        require(_excluded.length <= 2000, "Excluded accounts array is too big, please consider to review it");
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


    function isExcludedFromFee(address account) public view returns(bool) {
        return _isExcludedFromFee[account];
    }

    function setTaxes(uint256 _rfi, uint256 _treasury, uint256 _megaPool, uint256 _burn, uint256 _liquidity) public onlyOwner {
        taxes.rfi = _rfi;
        taxes.treasury = _treasury;
        taxes.megaPool = _megaPool;
        taxes.burn = _burn;
        taxes.liquidity = _liquidity;
        emit FeesChanged();
    }


    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi +=tRfi;
    }

    function _takeLiquidity(uint256 rLiquidity, uint256 tLiquidity) private {
        totFeesPaid.liquidity +=tLiquidity;
        if(_isExcluded[address(this)]) _tOwned[address(this)]+=tLiquidity;
        _rOwned[address(this)] +=rLiquidity;
    }

    function _takeTreasury(uint256 rTreasury, uint256 tTreasury) private {
        totFeesPaid.treasury +=tTreasury;
        if(_isExcluded[treasuryAddress]) _tOwned[treasuryAddress]+=tTreasury;
        _rOwned[treasuryAddress] +=rTreasury;
    }
    
    function _takeMegaPool(uint256 rMegaPool, uint256 tMegaPool) private{
        totFeesPaid.megaPool +=tMegaPool;
        if(_isExcluded[megaPoolAddress]) _tOwned[megaPoolAddress]+=tMegaPool;
        _rOwned[megaPoolAddress] +=rMegaPool;
    }

    function _takeBurn(uint256 rBurn, uint256 tBurn) private{
        totFeesPaid.burn +=tBurn;
        if(_isExcluded[burnAddress])_tOwned[burnAddress]+=tBurn;
        _rOwned[burnAddress] +=rBurn;
    }

    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi, to_return.rTreasury,to_return.rMegaPool, to_return.rBurn, to_return.rLiquidity) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {

        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        
        s.tRfi = tAmount*taxes.rfi/1000;
        s.tTreasury = tAmount*taxes.treasury/1000;
        s.tMegaPool = tAmount*taxes.megaPool/1000;
        s.tBurn = tAmount*taxes.burn/1000;
        s.tLiquidity = tAmount*taxes.liquidity/1000;
        s.tTransferAmount = tAmount-s.tRfi-s.tTreasury-s.tLiquidity-s.tMegaPool-s.tBurn;
        return s;
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rRfi,uint256 rTreasury,uint256 rMegaPool,uint256 rBurn,uint256 rLiquidity) {
        rAmount = tAmount*currentRate;

        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0,0,0);
        }

        rRfi = s.tRfi*currentRate;
        rTreasury = s.tTreasury*currentRate;
        rLiquidity = s.tLiquidity*currentRate;
        rMegaPool = s.tMegaPool*currentRate;
        rBurn = s.tBurn*currentRate;
        rTransferAmount =  rAmount-rRfi-rTreasury-rLiquidity-rMegaPool-rBurn;
        return (rAmount, rTransferAmount, rRfi,rTreasury,rMegaPool,rBurn,rLiquidity);
    }

    function _getRate() private view returns(uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply/tSupply;
    }

    function _getCurrentSupply() private view returns(uint256, uint256) {
        require(_excluded.length <= 2000, "Excluded accounts array is too big, please consider to review it");
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
        // require(amount <= balanceOf(from),"You are trying to transfer more than your balance");
        require(!_isBot[from] && !_isBot[to], "You are a bot");

        if((!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !swapping) || maxTxAmountFilterEnabled){
            require(amount <= maxTxAmount ,"Amount is exceeding maxTxAmount");
            // _handleCoolDownFilter(from, to);
            if(from != pair && coolDownEnabled){
                uint256 timePassed = block.timestamp - _lastTrade[from];
                require(timePassed > coolDownTime, "You must wait coolDownTime");
                _lastTrade[from] = block.timestamp;
            }
            
            if(to != pair && coolDownEnabled){
                uint256 timePassed2 = block.timestamp - _lastTrade[to];
                require(timePassed2 > coolDownTime, "You must wait coolDownTime");
                _lastTrade[to] = block.timestamp;
            }
        }

        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if(!swapping && swapEnabled && canSwap && from != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            swapAndLiquify(swapTokensAtAmount);
        }

        _tokenTransfer(from, to, amount, !(_isExcludedFromFee[from] || _isExcludedFromFee[to]));
    }

    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, bool takeFee) private {

        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender]-tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient]+s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        
        if(s.rRfi > 0 || s.tRfi > 0) _reflectRfi(s.rRfi, s.tRfi);

        if(s.rLiquidity > 0 || s.tLiquidity > 0) {
            _takeLiquidity(s.rLiquidity,s.tLiquidity);
            emit Transfer(sender, address(this), s.tLiquidity);
        }
        if(s.rTreasury > 0 || s.tTreasury > 0){
            _takeTreasury(s.rTreasury, s.tTreasury);
            emit Transfer(sender, treasuryAddress, s.tTreasury);
        }
        if(s.rMegaPool > 0 || s.tMegaPool > 0){
            _takeMegaPool(s.rMegaPool, s.tMegaPool);
            emit Transfer(sender, megaPoolAddress, s.tMegaPool);
        }
        if(s.rBurn > 0 || s.tBurn > 0){
            _takeBurn(s.rBurn, s.tBurn);
            emit Transfer(sender, burnAddress, s.tBurn);
        }
        
        emit Transfer(sender, recipient, s.tTransferAmount);
    }

    function swapAndLiquify(uint256 tokens) private lockTheSwap{
       // Split the contract balance into halves
        uint256 tokensToAddLiquidityWith = tokens / 2;
        uint256 toSwap = tokens - tokensToAddLiquidityWith;

        uint256 initialBalance = address(this).balance;
        swapTokensForETH(toSwap);
        uint256 ETHToAddLiquidityWith = address(this).balance - initialBalance;

        if(ETHToAddLiquidityWith > 0){
            // Add liquidity to pancake
            addLiquidity(tokensToAddLiquidityWith, ETHToAddLiquidityWith);
        }

    }

    function addLiquidity(uint256 tokenAmount, uint256 ETHAmount) private {
        // approve token transfer to cover all possible scenarios
        _approve(address(this), address(router), tokenAmount);

        // add the liquidity
        router.addLiquidityETH{value: ETHAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lpRecipient,
            block.timestamp
        );
    }

    function swapTokensForETH(uint256 tokenAmount) private {
        // generate the uniswap pair path of token -> weth
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokenAmount);

        // make the swap
        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0, // accept any amount of ETH
            path,
            address(this),
            block.timestamp
        );
    }

    function updateTreasuryWallet(address newWallet) external onlyOwner{
        require(treasuryAddress != newWallet ,'Wallet already set');
        treasuryAddress = newWallet;
        _isExcludedFromFee[treasuryAddress];
    }

    function updateBurnWallet(address newWallet) external onlyOwner{
        require(burnAddress != newWallet ,'Wallet already set');
        burnAddress = newWallet;
        _isExcludedFromFee[burnAddress];
    }

    function updateMegaPoolWallet(address newWallet) external onlyOwner{
        require(megaPoolAddress != newWallet ,'Wallet already set');
        megaPoolAddress = newWallet;
        _isExcludedFromFee[megaPoolAddress];
    }

    function updateLPRecipient(address newWallet) external onlyOwner{
        require(lpRecipient != newWallet ,'Wallet already set');
        lpRecipient = newWallet;
        _isExcludedFromFee[lpRecipient];
    }

    function updateMaxTxAmt(uint256 amount) external onlyOwner{
        maxTxAmount = amount * 10**_decimals;
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**_decimals;
    }

    function updateMaxTxAmountFilterEnabled(bool _enabled) external onlyOwner{
        maxTxAmountFilterEnabled = _enabled;
    }

    function updateSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }

    function updateCoolDownSettings(bool _enabled, uint256 _timeInSeconds) external onlyOwner{
        coolDownEnabled = _enabled;
        coolDownTime = _timeInSeconds * 1 seconds;
    }

    function setAntibot(address account, bool state) external onlyOwner{
        require(_isBot[account] != state, 'Value already set');
        _isBot[account] = state;
    }
    
    function bulkAntiBot(address[] memory accounts, bool state) external onlyOwner{
        require(accounts.length <= 10, "This bulk only accept a length of 10 accounts");
        for(uint256 i = 0; i < accounts.length; i++){
            _isBot[accounts[i]] = state;
        }
    }
    
    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
    }
    
    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }

    function getLiquidityProtectionData() public view onlyOwner returns(bool _maxTxAmountFilterEnabled, bool _coolDownEnabled){
        return (maxTxAmountFilterEnabled, coolDownEnabled);
    }
    
    function airdropTokens(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length <= 100, "This bulk only accept a length of 100 recipients");
        require(recipients.length == amounts.length,"Invalid size");
        address sender = msg.sender;
        for(uint256 i; i < recipients.length; i++) {
            if (_isExcluded[recipients[i]] == false) {
                address recipient = recipients[i];
                uint256 rAmount = amounts[i] * _getRate();
                _rOwned[sender] = _rOwned[sender] - rAmount;
                _rOwned[recipient] = _rOwned[recipient] + rAmount;
                emit Transfer(sender, recipient, amounts[i]);
            }
        }
    }

    //Use this in case ETH are sent to the contract by mistake
    function rescueETH(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient ETH balance");
        payable(owner()).transfer(weiAmount);
    }
    
    // Function to allow admin to claim *other* ERC20 tokens sent to this contract (by mistake)
    // Owner cannot transfer out catecoin from this smart contract
    function rescueAnyERC20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }

    receive() external payable{
    }
}