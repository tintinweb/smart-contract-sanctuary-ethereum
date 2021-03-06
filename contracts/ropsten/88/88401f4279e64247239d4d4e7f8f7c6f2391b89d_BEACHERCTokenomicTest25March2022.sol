/**
 *Submitted for verification at Etherscan.io on 2022-03-25
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

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

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
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

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        return c;
    }
}


contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

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

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(_owner, newOwner);
        _previousOwner = _owner ;
        _owner = newOwner;
    }

    function previousOwner() public view returns (address) {
        return _previousOwner;
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
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
    ) external payable returns (uint256 amountToken, uint256 amountETH, uint256 liquidity);
}

contract BEACHERCTokenomicTest25March2022 is Context, IERC20, Ownable {
    using SafeMath for uint256;

    IUniswapV2Router02 private uniswapV2Router;
    address public uniswapV2Pair;

    string private constant _name = "BEACH ERC Tokenomic Test 25March2022";
    string private constant _symbol = "BEACHERCTokenomicTest25March2022";
    uint8 private constant _decimals = 9;
    uint256 private constant MAX = ~uint256(0);
    uint256 private _tTotal = 100000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 public _tFeeTotal;
    uint256 public _BeachTokenBurned;
    bool public _cooldownEnabled = true;
    bool public tradeAllowed = false;
    bool private liquidityAdded = false;
    bool private inSwap = false;
    bool public swapEnabled = false;
    bool public feeEnabled = false;
    bool private limitTX = false;
    bool public doubleFeeEnable = false;
    uint256 private _maxTxAmount = _tTotal;
    uint256 private _maxBuyAmount;
    uint256 private buyLimitEnd;
    address payable private _development;
    address payable private _boost;

    address public targetToken = 0x351714Df444b8213f2C46aaA28829Fc5a8921304;
    address public boostFund = 0xa638F4Bb8202049eb4A6782511c3b8A64A2F90a1;
    address payable public _conduitAddress = payable(0xa638F4Bb8202049eb4A6782511c3b8A64A2F90a1);

    uint256 private _reflection ;
    uint256 private _contractFee ;
    uint256 private _burn ;
    uint256 private _boostFee ;
    uint256 private _futureFee ;
    uint256 private _conduitFee; 


    uint256 private _buyReflection;
    uint256 private _buyContractFee;
    uint256 private _buyBurn;
    uint256 private _buyBoostFee ;
    uint256 private _buyFutureFee ;
    uint256 private _buyConduitFee ;
    uint256 public _currentBuyFee ;


    uint256 private _sellReflection;
    uint256 private _sellContractFee;
    uint256 private _sellBurn;
    uint256 private _sellBoostFee ;
    uint256 private _sellFutureFee ;
    uint256 private _sellConduitFee ;
    uint256 public _currentSellFee ;


    bool public buyFeeEnabled = false;
    bool public sellFeeEnabled = false;





    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping (address => User) private cooldown;
    mapping(address => bool) private _isExcludedFromFee;
    mapping(address => bool) private _isBlacklisted;

    struct User {
        uint256 buy;
        uint256 sell;
        bool exists;
    }

    event CooldownEnabledUpdated(bool _cooldown);
    event MaxBuyAmountUpdated(uint _maxBuyAmount);
    event MaxTxAmountUpdated(uint256 _maxTxAmount);

    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;


    }

    constructor(address payable addr1, address payable addr2, address addr3) {
        _development = addr1;
        _boost = addr2;
        _rOwned[_msgSender()] = _rTotal;
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_development] = true;
        _isExcludedFromFee[_boost] = true;
        _isExcludedFromFee[addr3] = true;

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

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function setTargetAddress(address target_adr) external onlyOwner {
        targetToken = target_adr;
    }

    function setExcludedFromFee(address _address,bool _bool) external onlyOwner {
        address addr3 = _address;
        _isExcludedFromFee[addr3] = _bool;
    }



    function setAddressIsBlackListed(address _address, bool _bool) external onlyOwner {
        _isBlacklisted[_address] = _bool;
    }

    function viewIsBlackListed(address _address) public view returns(bool) {
        return _isBlacklisted[_address];
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

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender,_msgSender(),_allowances[sender][_msgSender()].sub(amount,"ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function setFeeEnabled(bool enable) external onlyOwner {
        feeEnabled = enable;
    }

    function setdoubleFeeEnabled( bool enable) external onlyOwner {
        doubleFeeEnable = enable;
    }

    function setLimitTx(bool enable) external onlyOwner {
        limitTX = enable;
    }

    function enableTrading(bool enable) external onlyOwner {
        require(liquidityAdded);
        tradeAllowed = enable;
        //  first 15 minutes after launch.
        buyLimitEnd = block.timestamp + (900 seconds);
    }

    function addLiquidity() external onlyOwner() {
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        _approve(address(this), address(uniswapV2Router), _tTotal);
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory()).createPair(address(this), _uniswapV2Router.WETH());
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this),balanceOf(address(this)),0,0,owner(),block.timestamp);
        swapEnabled = true;
        liquidityAdded = true;
        feeEnabled = true;
        limitTX = true;
        _maxTxAmount = 1000000000000000 * 10**9;
        _maxBuyAmount = 300000000000000 * 10**9;
        IERC20(uniswapV2Pair).approve(address(uniswapV2Router),type(uint256).max);
    }

    function manualSwapTokensForEth() external onlyOwner() {
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualDistributeETH() external onlyOwner() {
        uint256 contractETHBalance = address(this).balance;
        distributeETH(contractETHBalance);
    }

    function manualSwapEthForTargetToken(uint amount) external onlyOwner() {
        swapETHfortargetToken(amount);
    }

    function setMaxTxPercent(uint256 maxTxPercent) external onlyOwner() {
        require(maxTxPercent > 0, "Amount must be greater than 0");
        _maxTxAmount = _tTotal.mul(maxTxPercent).div(10**2);
        emit MaxTxAmountUpdated(_maxTxAmount);
    }

    function setCooldownEnabled(bool onoff) external onlyOwner() {
        _cooldownEnabled = onoff;
        emit CooldownEnabledUpdated(_cooldownEnabled);
    }

    function timeToBuy(address buyer) public view returns (uint) {
        return block.timestamp - cooldown[buyer].buy;
    }

    function timeToSell(address buyer) public view returns (uint) {
        return block.timestamp - cooldown[buyer].sell;
    }

    function amountInPool() public view returns (uint) {
        return balanceOf(uniswapV2Pair);
    }

    function tokenFromReflection(uint256 rAmount) private view returns (uint256) {
        require(rAmount <= _rTotal,"Amount must be less than total reflections");
        uint256 currentRate = _getRate();
        return rAmount.div(currentRate);
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

        bool chargeTax = true;

        if (from != owner() && to != owner() && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
            require(tradeAllowed);
            require(!_isBlacklisted[from] && !_isBlacklisted[to]);
            if(_cooldownEnabled) {
                if(!cooldown[msg.sender].exists) {
                    cooldown[msg.sender] = User(0,0,true);
                }
            }
            // buy 
            if (from == uniswapV2Pair && to != address(uniswapV2Router)) {
                
                chargeTax = buyFeeEnabled;
                setBuyFeeOnTrancation();

                if (limitTX) {
                    require(amount <= _maxTxAmount);
                }
                if(_cooldownEnabled) {
                    if(buyLimitEnd > block.timestamp) {
                        require(amount <= _maxBuyAmount);
                        require(cooldown[to].buy < block.timestamp, "Your buy cooldown has not expired.");
                        //  2min BUY cooldown
                        cooldown[to].buy = block.timestamp + (120 seconds);
                    }
                    // 5mins cooldown to SELL after a BUY to ban front-runner bots
                    cooldown[to].sell = block.timestamp + (300 seconds);
                }
                uint contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    swapETHfortargetToken(address(this).balance);
                }
            }

            // sale
            if(to == address(uniswapV2Pair) || to == address(uniswapV2Router) ) {

                chargeTax = sellFeeEnabled;
                setSellFeeOnTrancation();

                if(_cooldownEnabled) {
                    require(cooldown[from].sell < block.timestamp, "Your sell cooldown has not expired.");
                }
                uint contractTokenBalance = balanceOf(address(this));
                if (!inSwap && from != uniswapV2Pair && swapEnabled) {
                    if (limitTX) {
                    require(amount <= balanceOf(uniswapV2Pair).mul(3).div(100) && amount <= _maxTxAmount);
                    }
                    uint initialETHBalance = address(this).balance;
                    swapTokensForEth(contractTokenBalance);
                    uint newETHBalance = address(this).balance;
                    uint ethToDistribute = newETHBalance.sub(initialETHBalance);
                    if (ethToDistribute > 0) {
                        distributeETH(ethToDistribute);
                    }
                }
            }
        }
        bool takeFee = true;
        if (_isExcludedFromFee[from] || _isExcludedFromFee[to] || !feeEnabled || !chargeTax) {
            takeFee = false;
        }
        _tokenTransfer(from, to, amount, takeFee);
        removeAllFee;
    }

       function removeAllFee() private {
        if (_reflection == 0 && _contractFee == 0 && _burn == 0) return;
        _reflection = 0;
        _contractFee = 0;
        _burn = 0;
        _boostFee = 0 ;
        _futureFee =0 ;
        _conduitFee = 0;
    }

    function setBuyFeeOnTrancation() private {

        _reflection = _buyReflection;
        _contractFee = _buyContractFee;
        _burn = _buyBurn;
        _boostFee = _buyBoostFee ;
        _futureFee =_buyFutureFee ;
        _conduitFee = _buyConduitFee;
    }

    function setSellFeeOnTrancation() private {
        _reflection = _sellReflection;
        _contractFee = _sellContractFee;
        _burn = _sellBurn;
        _boostFee = _sellBoostFee ;
        _futureFee =_sellFutureFee ;
        _conduitFee = _sellConduitFee;
    }

//  tokenomic dyanmic 

    function setBuyFee(uint256  _per ) external onlyOwner() {

        if (_per == 0 )
        {
        _buyReflection = 0;
        _buyContractFee = 0;
        _buyBurn = 0;
        _buyBoostFee =0;
        _buyFutureFee = 0;
        _conduitFee = 0;
        _currentBuyFee = 0;

        buyFeeEnabled = false;
        
        }else if (_per == 5){
        _buyReflection = 0;
        _buyContractFee = 4;
        _buyBurn = 1;
        _buyBoostFee =_buyContractFee.div(2); // 2% boost fee
        _buyFutureFee = _buyContractFee.div(1); // 1 % future fee
        _buyConduitFee = _buyContractFee.div(1); // 1 % conduit fee
        _currentBuyFee = 5;

        buyFeeEnabled = true;

        }else if (_per == 10){
        _buyReflection = 0;
        _buyContractFee = 6;
        _buyBurn = 4;
        _buyBoostFee = _buyContractFee.div(3); // 3 % boost fee;
        _buyFutureFee = _buyContractFee.div(1); // 1 % future
        _buyConduitFee = _buyContractFee.div(1); // 1 % conduit fee
        _currentBuyFee = 10;        
        buyFeeEnabled = true;

        }else {
            revert(" Invalid input for buy tax. supported input are  5% and 10%");
        }
 
    }

    function setSellFee(uint256  _per ) external onlyOwner() {
        if (_per == 0 )
        {
        _sellReflection = 0;
        _sellContractFee = 0;
        _sellBurn = 0;
        _sellBoostFee = 0;
        _sellFutureFee = 0;
        _currentSellFee = 0;
        sellFeeEnabled = false;

        }else if (_per == 10){
        _sellReflection = 0;
        _sellContractFee = 6;
        _sellBurn = 4;
        _sellBoostFee = _sellContractFee.div(3); // 3 % boost fee;
        _sellFutureFee = _sellContractFee.div(1); // 1 % future
        _sellConduitFee = _sellContractFee.div(1); // 1 % conduit fee
        _currentSellFee = 10;
        sellFeeEnabled = true;

        }else if (_per == 15){
        _sellReflection = 0;
        _sellContractFee = 12;
        _sellBurn = 3; // 3% burn fee
        _sellBoostFee = _sellContractFee.div(4); // 4 % boost fee
        _sellFutureFee = _sellContractFee.div(1); // 1 % future
        _sellConduitFee = _sellContractFee.div(3); // 3 % conduit fee
        _currentSellFee = 15;
        sellFeeEnabled = true;

        }
        else {
            revert(" Invalid input for sell tax. supported input are  10% and 15%");
        }
 
    }

  

    function _tokenTransfer(address sender, address recipient, uint256 amount, bool takeFee) private {
        if (!takeFee) removeAllFee();
        _transferStandard(sender, recipient, amount);
        if (!takeFee) removeAllFee();
    }

    function _transferStandard(address sender, address recipient, uint256 amount) private {
        (uint256 tAmount, uint256 tBurn) = _BeachTokenEthBurn(amount);
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee, uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getValues(tAmount, tBurn);
        _rOwned[sender] = _rOwned[sender].sub(rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(rTransferAmount);
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _BeachTokenEthBurn(uint amount) private returns (uint, uint) {
        uint orgAmount = amount;
        uint256 currentRate = _getRate();
        uint256 tBurn = amount.mul(_burn).div(100);
        uint256 rBurn = tBurn.mul(currentRate);
        _tTotal = _tTotal.sub(tBurn);
        _rTotal = _rTotal.sub(rBurn);
        _BeachTokenBurned = _BeachTokenBurned.add(tBurn);
        return (orgAmount, tBurn);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    function _getValues(uint256 tAmount, uint256 tBurn) private view returns (uint256, uint256, uint256, uint256, uint256, uint256) {
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) = _getTValues(tAmount, _reflection, _contractFee, tBurn);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(tAmount, tFee, tTeam, currentRate);
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }

    function _getTValues(uint256 tAmount, uint256 taxFee, uint256 teamFee, uint256 tBurn) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = tAmount.mul(taxFee).div(100);
        uint256 tTeam = tAmount.mul(teamFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam).sub(tBurn);
        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(uint256 tAmount, uint256 tFee, uint256 tTeam, uint256 currentRate) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam);
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply.div(tSupply);
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal.div(_tTotal)) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

     function swapETHfortargetToken(uint ethAmount) private {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(targetToken);

        _approve(address(this), address(uniswapV2Router), ethAmount);
        uniswapV2Router.swapExactETHForTokensSupportingFeeOnTransferTokens{value: ethAmount}(ethAmount,path,address(boostFund),block.timestamp);
    }

      function distributeETH(uint256 amount) private {
        if(_boostFee !=0 || _futureFee != 0 || _conduitFee !=0){
            _development.transfer(amount.div(_boostFee)); //future fund fee
            _boost.transfer(amount.div(_futureFee)); //  boost fund erc fee
            _conduitAddress.transfer(amount.div(_conduitFee));
            // remaining  boost fund dai fee 
        }else{
            return;
        }
    }

    receive() external payable {}
}