/**
 *Submitted for verification at Etherscan.io on 2022-05-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-15
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;
 
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
 
library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
 
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
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
 
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
 
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}
 
contract BeepBeep is Context, IERC20, Ownable {
    using Address for address payable;
 
    mapping (address => uint256) private _rOwned;
    mapping (address => uint256) private _tOwned;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private _isExcluded;
 
 
    address[] private _excluded;
 
    bool public swapEnabled = true;
    bool private swapping;
 
    IRouter public router;
    address public pair;
 
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);
 
    uint256 private _tTotal = 100e12 * 10**_decimals;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
 
    uint256 public swapTokensAtAmount = 5e9 * 10**_decimals;
    uint256 public maxSellAmount = 5e11 * 10**_decimals;
    uint256 public maxWalletAmount = 15e11 * 10**_decimals;
 
    address public marketingWallet = 0xd462B75B7bBc93b5934a7DF6A30EFDE01B7196a5;
    address public charityWallet = 0xbFc9d74D1ca8DdC222549c00EC554b92850aa969;
    address public devWallet = 0xC5aA62A70BeDDa5bEef4cAAb5a7784B054C5c743;
 
    string private constant _name = "SBH Easy Cash";
    string private constant _symbol = "SBH";
 
 
    struct Taxes {
      uint256 rfi;
      uint256 burn;
      uint256 marketing;
      uint256 charity;
      uint256 dev;
    }
    Taxes public taxes = Taxes(2,1,3,2,2);
 
    struct TotFeesPaidStruct{
        uint256 rfi;
        uint256 burn;
        uint256 marketing;
        uint256 charity;
        uint256 dev;
    }
    TotFeesPaidStruct public totFeesPaid;
 
    struct valuesFromGetValues{
      uint256 rAmount;
      uint256 rTransferAmount;
      uint256 rRfi;
      uint256 rBurn;
      uint256 rMarketing;
      uint256 rCharity;
      uint256 rDev;
      uint256 tTransferAmount;
      uint256 tRfi;
      uint256 tBurn;
      uint256 tMarketing;
      uint256 tCharity;
      uint256 tDev;
    }
 
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
        excludeFromReward(address(0xdead));
 
        _rOwned[owner()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[marketingWallet]=true;
        _isExcludedFromFee[charityWallet] = true;
        _isExcludedFromFee[devWallet] = true;
 
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
 
    function setTaxes(uint256 _rfi, uint256 _burn,uint256 _marketing, uint256 _charity, uint256 _dev) public onlyOwner {
        taxes = Taxes(_rfi,_burn, _marketing, _charity, _dev);
    }
 
    function _reflectRfi(uint256 rRfi, uint256 tRfi) private {
        _rTotal -=rRfi;
        totFeesPaid.rfi +=tRfi;
    }
 
    function _takeCharity(uint256 rCharity, uint256 tCharity) private {
        totFeesPaid.charity +=tCharity;
 
        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tCharity;
        }
        _rOwned[address(this)] +=rCharity;
    }
 
    function _takeMarketing(uint256 rMarketing, uint256 tMarketing) private {
        totFeesPaid.marketing +=tMarketing;
 
        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tMarketing;
        }
        _rOwned[address(this)] +=rMarketing;
    }
 
    function _takeBurn(uint256 rBurn, uint256 tBurn) private {
        totFeesPaid.burn +=tBurn;
 
        if(_isExcluded[address(0xdead)])
        {
            _tOwned[address(0xdead)]+=tBurn;
        }
        _rOwned[address(0xdead)] +=rBurn;
    }
 
 
    function _takeDev(uint256 rDev, uint256 tDev) private {
        totFeesPaid.dev +=tDev;
 
        if(_isExcluded[address(this)])
        {
            _tOwned[address(this)]+=tDev;
        }
        _rOwned[address(this)] +=rDev;
    }
 
    function _getValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory to_return) {
        to_return = _getTValues(tAmount, takeFee);
        (to_return.rAmount, to_return.rTransferAmount, to_return.rRfi, to_return.rBurn, to_return.rMarketing, to_return.rCharity, to_return.rDev) = _getRValues(to_return, tAmount, takeFee, _getRate());
        return to_return;
    }
 
    function _getTValues(uint256 tAmount, bool takeFee) private view returns (valuesFromGetValues memory s) {
 
        if(!takeFee) {
          s.tTransferAmount = tAmount;
          return s;
        }
        s.tRfi = tAmount*taxes.rfi/100;
        s.tBurn = tAmount*taxes.burn/100;
        s.tMarketing = tAmount*taxes.marketing/100;
        s.tCharity = tAmount*taxes.charity/100;
        s.tDev = tAmount*taxes.dev/100;
        s.tTransferAmount = tAmount-s.tRfi-s.tBurn-s.tMarketing-s.tCharity-s.tDev;
        return s;
    }
 
    function _getRValues(valuesFromGetValues memory s, uint256 tAmount, bool takeFee, uint256 currentRate) private pure returns (
        uint256 rAmount, uint256 rTransferAmount, uint256 rRfi,uint256 rBurn, 
        uint256 rMarketing, uint256 rCharity, uint256 rDev) {
 
        rAmount = tAmount*currentRate;
 
        if(!takeFee) {
          return(rAmount, rAmount, 0,0,0,0,0);
        }
 
        rRfi = s.tRfi*currentRate;
        rBurn = s.tBurn*currentRate;
        rMarketing = s.tMarketing*currentRate;
        rCharity = s.tCharity*currentRate;
        rDev = s.tDev*currentRate;
        rTransferAmount =  rAmount-rRfi-rBurn-rMarketing-rCharity-rDev;
        return (rAmount, rTransferAmount, rRfi,rBurn,rMarketing,rCharity,rDev);
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
        require(amount > 0, "Transfer amount must be greater than zero");
        require(amount <= balanceOf(from),"You are trying to transfer more than your balance");       
 
        if(!_isExcludedFromFee[from] && !_isExcludedFromFee[to] && !swapping){
            if(to == pair) require(amount <= maxSellAmount ,"Amount is exceeding maxSellAmount");
            else if (to != pair) require(balanceOf(to) + amount <= maxWalletAmount, "You are exceeding maxWalletAmount");
        }
 
 
        bool canSwap = balanceOf(address(this)) >= swapTokensAtAmount;
        if(!swapping && swapEnabled && canSwap && from != pair && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]){
            swapAndSendToFees(swapTokensAtAmount);
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
        if(s.rCharity > 0 || s.tCharity > 0) _takeCharity(s.rCharity,s.tCharity);
        if(s.rMarketing > 0 || s.tMarketing > 0) _takeMarketing(s.rMarketing, s.tMarketing);
        if(s.rDev > 0 || s.tDev > 0) _takeDev(s.rDev, s.tDev);
        if(s.rBurn > 0 || s.tBurn > 0) {
            _takeBurn(s.rBurn, s.tBurn);
            emit Transfer(sender, address(0xdead), s.tBurn);
        }
 
        emit Transfer(sender, recipient, s.tTransferAmount);
        emit Transfer(sender, address(this), s.tCharity + s.tDev + s.tMarketing);
 
    }
 
    function swapAndSendToFees(uint256 tokens) private lockTheSwap{
        uint256 initialBalance = address(this).balance;
 
        swapTokensForBNB(tokens);
 
        uint256 tempBalance = address(this).balance - initialBalance;
 
        uint256 totalTax = taxes.charity + taxes.marketing + taxes.dev;
 
        uint256 marketingAmt = tempBalance * taxes.marketing / totalTax;
        uint256 charityAmt = tempBalance * taxes.charity / totalTax;
        uint256 devAmt = tempBalance * taxes.dev / totalTax;
        if(marketingAmt > 0) payable(marketingWallet).sendValue(marketingAmt);
        if(charityAmt > 0) payable(charityWallet).sendValue(charityAmt);
        if(devAmt > 0) payable(devWallet).sendValue(devAmt);
    }
 
 
    function swapTokensForBNB(uint256 tokenAmount) private {
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
 
    function updateWallets(address _marketingWallet, address _charityWallet, address _devWallet) external onlyOwner{
        marketingWallet = _marketingWallet;
        charityWallet = _charityWallet;
        devWallet = _devWallet;
    }
 
    function updateMaxSellAmount(uint256 amount) external onlyOwner{
        maxSellAmount = amount * 10**_decimals;
    }
 
    function updateMaxWalletAmount(uint256 amount) external onlyOwner{
        maxWalletAmount = amount * 10**_decimals;
    }
 
    function updateSwapTokensAtAmount(uint256 amount) external onlyOwner{
        swapTokensAtAmount = amount * 10**_decimals;
    }
 
    function updateSwapEnabled(bool _enabled) external onlyOwner{
        swapEnabled = _enabled;
    }
 
    function updateRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
    }
 
 
    //Use this in case BNB are sent to the contract by mistake
    function rescueBNB(uint256 weiAmount) external onlyOwner{
        require(address(this).balance >= weiAmount, "insufficient BNB balance");
        payable(msg.sender).transfer(weiAmount);
    }
 
    // Function to allow admin to claim *other* BEP20 tokens sent to this contract (by mistake)
    // Owner cannot transfer out catecoin from this smart contract
    function rescueAnyBEP20Tokens(address _tokenAddr, address _to, uint _amount) public onlyOwner {
        IERC20(_tokenAddr).transfer(_to, _amount);
    }
 
    receive() external payable{
    }
}