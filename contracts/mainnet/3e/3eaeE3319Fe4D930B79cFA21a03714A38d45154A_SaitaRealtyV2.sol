// SPDX-License-Identifier: NOLICENSE
pragma solidity ^0.8.10;

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

    function _setOwner(address newOwner) internal {
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
    function addTreasuryETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint treasury);

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;

    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);

}

contract SaitaRealtyV2 is IERC20, Ownable {

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isExcluded;
    mapping(address => bool) private _isBot;
    mapping(address => bool) private _isPair;

    address[] private _excluded;
    
    bool private swapping;

    IRouter public router;
    address public pair;

    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal = 12e10 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));

    
    uint256 public swapTokensAtAmount = 1_000 * 10 ** 6;
    uint256 public maxTxAmount = 100_000_000_000 * 10**_decimals;
    
    // Anti Dump //
    mapping (address => uint256) public _lastTrade;
    bool public coolDownEnabled = true;
    uint256 public coolDownTime = 30 seconds;

    address public capitalAddress = 0x22D5c2837FFB86392C81D3Be0aDe307F81AF10C1;
    address public marketingAddress = 0x2084f438b1EFf6Bd5FbdE57215eaB741CAC7aDb7;
    address public burnAddress = 0x000000000000000000000000000000000000dEaD;

    address public USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    string private constant _name = "SaitaRealtyV2";
    string private constant _symbol = "SRLTY";


    struct Taxes {
      uint256 reflection;
      uint256 capital;
      uint256 marketing;
      uint256 burn;
      uint256 treasury;
    }

    Taxes private taxes = Taxes(10,10,10,10,50);

    struct TotFeesPaidStruct {
        uint256 reflection;
        uint256 capital;
        uint256 marketing;
        uint256 burn;
        uint256 treasury;
    }

    TotFeesPaidStruct public totFeesPaid;

    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rReflection;
      uint256 rCapital;
      uint256 rMarketing;
      uint256 rBurn;
      uint256 rTreasury;
      uint256 tTransferAmount;
      uint256 tReflection;
      uint256 tCapital;
      uint256 tMarketing;
      uint256 tBurn;
      uint256 tTreasury;
    }
    
    struct splitETHStruct{
        uint256 capital;
        uint256 marketing;
    }

    splitETHStruct private splitETH = splitETHStruct(40,10);

    struct ETHAmountStruct{
        uint256 capital;
        uint256 marketing;
    }

    ETHAmountStruct public ETHAmount;

    event FeesChanged();

    modifier lockTheSwap {
        swapping = true;
        _;
        swapping = false;
    }

    modifier addressValidation(address _addr) {
        require(_addr != address(0), 'SaitaRealty: Zero address');
        _;
    }

    constructor (address routerAddress, address owner_) {
        IRouter _router = IRouter(routerAddress);
        address _pair = IFactory(_router.factory())
            .createPair(address(this), _router.WETH());

        router = _router;
        pair = _pair;
        
        addPair(pair);
    
        excludeFromReward(pair);

        _setOwner(owner_);

        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[capitalAddress] = true;
        _isExcludedFromFee[burnAddress] = true;
        _isExcludedFromFee[marketingAddress] = true;

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
        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");

        _transfer(sender, recipient, amount);
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

    function tokenFromReflection(uint256 rAmount) public view returns(uint256) {
        require(rAmount <= _rTotal, "Amount must be less than total reflections");
        uint256 currentRate =  _getRate();
        return rAmount/currentRate;
    }

    function excludeFromReward(address account) public onlyOwner {
        require(!_isExcluded[account], "Account is already excluded");
        require(_excluded.length <= 200, "Invalid length");
        require(account != owner(), "Owner cannot be excluded");
        if(_rOwned[account] > 0) {
            _tOwned[account] = tokenFromReflection(_rOwned[account]);
        }
        _isExcluded[account] = true;
        _excluded.push(account);
    }

    function includeInReward(address account) external onlyOwner() {
        require(_isExcluded[account], "Account is not excluded");
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

    function addPair(address _pair) public onlyOwner {
        _isPair[_pair] = true;
    }

    function removePair(address _pair) public onlyOwner {
        _isPair[_pair] = false;
    }

    function isPair(address account) public view returns(bool){
        return _isPair[account];
    }

    function setTaxes(uint256 _reflection, uint256 _capital, uint256 _marketing, uint256 _burn, uint256 _treasury) public onlyOwner {
        taxes.reflection = _reflection;
        taxes.capital = _capital;
        taxes.marketing = _marketing;
        taxes.burn = _burn;
        taxes.treasury = _treasury;
        emit FeesChanged();
    }

    function setSplitETH(uint256 _capital, uint256 _marketing) public onlyOwner {
        splitETH.capital = _capital;
        splitETH.marketing = _marketing;
        emit FeesChanged();
    }

    function _reflectReflection(uint256 rReflection, uint256 tReflection) private {
        _rTotal -=rReflection;
        totFeesPaid.reflection += tReflection;
    }

    function _takeTreasury(uint256 rTreasury, uint256 tTreasury) private {
        totFeesPaid.treasury += tTreasury;
        if(_isExcluded[address(this)]) _tOwned[address(this)] += tTreasury;
        _rOwned[address(this)] += rTreasury;
    }

    function _takeCapital(uint256 rCapital, uint256 tCapital) private {
        totFeesPaid.capital += tCapital;
        if(_isExcluded[capitalAddress]) _tOwned[capitalAddress] += tCapital;
        _rOwned[capitalAddress] +=rCapital;
    }
    
    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private{
        totFeesPaid.marketing += tMarketing;
        if(_isExcluded[marketingAddress]) _tOwned[marketingAddress] += tMarketing;
        _rOwned[marketingAddress] += rMarketing;
    }

    function _takeBurn(uint256 rBurn, uint256 tBurn) private {
        totFeesPaid.burn += tBurn;
        if(_isExcluded[marketingAddress])_tOwned[burnAddress] += tBurn;
        _rOwned[burnAddress] += rBurn;
    }

    function _getValues(uint256 tAmount, uint8 takeFee) private  returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rReflection, to_return.rCapital,to_return.rMarketing, to_return.rBurn, to_return.rTreasury) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }

    function _getTValues(uint256 tAmount, uint8 takeFee) private returns (valuesFromGetValues memory s) {

        if(takeFee == 0) {
          s.tTransferAmount = tAmount;
          return s;
        } else if(takeFee == 1){
            s.tReflection = (tAmount*taxes.reflection)/1000;
            s.tCapital = (tAmount*taxes.capital)/1000;
            s.tMarketing = tAmount*taxes.marketing/1000;
            s.tBurn = tAmount*taxes.burn/1000;
            s.tTreasury = tAmount*taxes.treasury/1000;
            ETHAmount.capital += s.tTreasury*splitETH.capital/taxes.treasury;
            ETHAmount.marketing += s.tTreasury*splitETH.marketing/taxes.treasury;
            s.tTransferAmount = tAmount-s.tReflection-s.tCapital-s.tTreasury-s.tMarketing-s.tBurn;
            return s;
        } else {
            s.tReflection = tAmount*taxes.reflection/1000;
            s.tMarketing = tAmount*taxes.marketing/1000;
            s.tBurn = tAmount*taxes.burn/1000;
            s.tTreasury = tAmount*splitETH.marketing/1000;
            ETHAmount.marketing += s.tTreasury;
            s.tTransferAmount = tAmount-s.tReflection-s.tTreasury-s.tMarketing-s.tBurn;
            return s;
        }
        
    }

    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, uint8 takeFee, uint256 currentRate) private pure returns (uint256 rAmount, uint256 rTransferAmount, uint256 rReflection,uint256 rCapital,uint256 rMarketing,uint256 rBurn,uint256 rTreasury) {
        rAmount = tAmount*currentRate;

        if(takeFee == 0) {
          return(rAmount, rAmount, 0,0,0,0,0);
        }else if(takeFee == 1){
            rReflection = s.tReflection*currentRate;
            rCapital = s.tCapital*currentRate;
            rTreasury = s.tTreasury*currentRate;
            rMarketing = s.tMarketing*currentRate;
            rBurn = s.tBurn*currentRate;
            rTransferAmount =  rAmount-rReflection-rCapital-rTreasury-rMarketing-rBurn;
            return (rAmount, rTransferAmount, rReflection,rCapital,rMarketing,rBurn,rTreasury);
        }
        else{
            rReflection = s.tReflection*currentRate;
            rTreasury = s.tTreasury*currentRate;
            rMarketing = s.tMarketing*currentRate;
            rBurn = s.tBurn*currentRate;
            rTransferAmount =  rAmount-rReflection-rTreasury-rMarketing-rBurn;
            return (rAmount, rTransferAmount, rReflection,0,rMarketing,rBurn,rTreasury);
        }

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

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }


    function _transfer(address from, address to, uint256 amount) private {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Zero amount");
        require(amount <= balanceOf(from),"Insufficient balance");
        require(!_isBot[from] && !_isBot[to], "You are a bot");
        require(amount <= maxTxAmount ,"Amount is exceeding maxTxAmount");

        if (coolDownEnabled) {
            uint256 timePassed = block.timestamp - _lastTrade[from];
            require(timePassed > coolDownTime, "You must wait coolDownTime");
        }
        
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !swapping) {//check this !swapping
            if(_isPair[from] || _isPair[to]) {
                _tokenTransfer(from, to, amount, 1);
            } else {
                _tokenTransfer(from, to, amount, 2);
            }
        } else {
            _tokenTransfer(from, to, amount, 0);
        }

        _lastTrade[from] = block.timestamp;
        
        if(!swapping && from != pair && to != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            address[] memory path = new address[](3);
                path[0] = address(this);
                path[1] = router.WETH();
                path[2] = USDT;
            uint _amount = router.getAmountsOut(balanceOf(address(this)), path)[2];
            if(_amount >= swapTokensAtAmount) swapTokensForETH(balanceOf(address(this)));
        }

    }


    //this method is responsible for taking all fee, if takeFee is true
    function _tokenTransfer(address sender, address recipient, uint256 tAmount, uint8 takeFee) private {

        valuesFromGetValues memory s = _getValues(tAmount, takeFee);

        if (_isExcluded[sender] ) {  //from excluded
                _tOwned[sender] = _tOwned[sender] - tAmount;
        }
        if (_isExcluded[recipient]) { //to excluded
                _tOwned[recipient] = _tOwned[recipient] + s.tTransferAmount;
        }

        _rOwned[sender] = _rOwned[sender]-s.rAmount;
        _rOwned[recipient] = _rOwned[recipient]+s.rTransferAmount;
        
        if(s.rReflection > 0 || s.tReflection > 0) _reflectReflection(s.rReflection, s.tReflection);
        if(s.rTreasury > 0 || s.tTreasury > 0) {
            _takeTreasury(s.rTreasury,s.tTreasury);
        }
        if(s.rCapital > 0 || s.tCapital > 0){
            _takeCapital(s.rCapital, s.tCapital);
            emit Transfer(sender, capitalAddress, s.tMarketing);
        }
        if(s.rMarketing > 0 || s.tMarketing > 0){
            _takeMarketing(s.rMarketing, s.tMarketing);
            emit Transfer(sender, marketingAddress, s.tMarketing);
        }
        if(s.rBurn > 0 || s.tBurn > 0){
            _takeBurn(s.rBurn, s.tBurn);
            emit Transfer(sender, burnAddress, s.tBurn);
        }
        
        emit Transfer(sender, recipient, s.tTransferAmount);
        if(s.tTreasury > 0){
        emit Transfer(sender, address(this), s.tTreasury);
        }
    }

    function swapTokensForETH(uint256 tokenAmount) private lockTheSwap {
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

        (bool success, ) = capitalAddress.call{value: (ETHAmount.capital * address(this).balance)/tokenAmount}("");
        require(success, 'ETH_TRANSFER_FAILED');
        ETHAmount.capital = 0;

        (success, ) = marketingAddress.call{value: (ETHAmount.marketing * address(this).balance)/tokenAmount}("");
        require(success, 'ETH_TRANSFER_FAILED');
        ETHAmount.marketing = 0;
    }

    function updateCapitalWallet(address newWallet) external onlyOwner addressValidation(newWallet) {
        require(capitalAddress != newWallet, 'SaitaRealty: Wallet already set');
        capitalAddress = newWallet;
        _isExcludedFromFee[capitalAddress];
    }

    function updateBurnWallet(address newWallet) external onlyOwner addressValidation(newWallet) {
        require(burnAddress != newWallet, 'SaitaRealty: Wallet already set');
        burnAddress = newWallet;
        _isExcludedFromFee[burnAddress];
    }

    function updateMarketingWallet(address newWallet) external onlyOwner addressValidation(newWallet) {
        require(marketingAddress != newWallet, 'SaitaRealty: Wallet already set');
        marketingAddress = newWallet;
        _isExcludedFromFee[marketingAddress];
    }

    function updateStableCoin(address _usdt) external onlyOwner  addressValidation(_usdt) {
        require(USDT != _usdt, 'SaitaRealty: Wallet already set');
        USDT = _usdt;
    }

    function updateMaxTxAmt(uint256 amount) external onlyOwner {
        require(amount >= 100);
        maxTxAmount = amount * 10**_decimals;
    }

    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner {
        require(amount > 0);
        swapTokensAtAmount = amount * 10**6;
    }

    function updateCoolDownSettings(bool _enabled, uint256 _timeInSeconds) external onlyOwner{
        coolDownEnabled = _enabled;
        coolDownTime = _timeInSeconds * 1 seconds;
    }

    function setAntibot(address account, bool state) external onlyOwner{
        require(_isBot[account] != state, 'SaitaRealty: Value already set');
        _isBot[account] = state;
    }
    
    function bulkAntiBot(address[] memory accounts, bool state) external onlyOwner {
        require(accounts.length <= 100, "SaitaRealty: Invalid");
        for(uint256 i = 0; i < accounts.length; i++){
            _isBot[accounts[i]] = state;
        }
    }
    
    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner {
        router = IRouter(newRouter);
        pair = newPair;
        addPair(pair);
    }
    
    function isBot(address account) public view returns(bool){
        return _isBot[account];
    }
    
    function airdropTokens(address[] memory recipients, uint256[] memory amounts) external onlyOwner {
        require(recipients.length == amounts.length,"Invalid size");
         address sender = msg.sender;

         for(uint256 i; i<recipients.length; i++){
            address recipient = recipients[i];
            uint256 rAmount = amounts[i]*_getRate();
            _rOwned[sender] = _rOwned[sender]- rAmount;
            _rOwned[recipient] = _rOwned[recipient] + rAmount;
            emit Transfer(sender, recipient, amounts[i]);
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

    receive() external payable {
    }
}