/**
 *Submitted for verification at Etherscan.io on 2022-01-30
*/

// SPDX-License-Identifier: Unlicensed

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
    
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
    
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

contract GoldenTiger is Context, IERC20, Ownable {
    
    using SafeMath for uint256;

    string private constant _name = "Golden Tiger";
    string private constant _symbol = "TIGER";
    uint8 private constant _decimals = 9;

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    
    //Buy Fee
    uint256 private _redisFeeOnBuy = 1;
    uint256 private _taxFeeOnBuy = 10;
    
    //Sell Fee
    uint256 private _redisFeeOnSell = 1;
    uint256 private _taxFeeOnSell = 10;

    uint256 public _liquidityFee = 2;

    uint256 public _timeBetweenTransactions = 2 minutes;
    
    //Original Fee
    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell;
    uint256 private _previousLiqFee = _liquidityFee;
    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;
    struct ValueInfo {
         uint256 rAmount;
            uint256 rTransferAmount;
            uint256 rFee;
            uint256 tTransferAmount;
            uint256 tFee;
            uint256 tTeam;
          uint256 tLiq;
    } 
    mapping(address => bool) public bots;
    mapping (address => bool) public preTrader;
    mapping(address => uint256) private cooldown;
    
    address payable private _developmentAddress = payable(0x6b39FeA5b47fbd19381Ad1362376C1E39f9a0781);
    address payable private _marketingAddress = payable(0x289Ff7dB03E509EFC171062EfcDb1b63cabD61Db);
    
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
    
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = true;

    bool public launchAddLiquidity = false;
    bool public antiwhaleEnabled = false;
    uint256 public launchTime = 0;

    /**
        Sniper Bot configuration
     */
    uint256 public _launchBlock = 0;
    uint256 public _finalSniperBlock = 25;
    uint256 public _increaseAmountBy = 1000 * 10 **9;
    uint256 public _defaultAmountBot = 100 * 10**9;

    bool public antibotEnable = true;


    uint256 public _maxTxAmount = 10000000 * 10**9; 
    uint256 public _maxWalletSize = 10000000 * 10**9; //1
    uint256 public _swapTokensAtAmount = 1000000 * 10**9; //0.1

    mapping(address => bool) private _isExcludedAntiwhale;
    mapping(address => bool) private _isExcludedMaxwallet;
    mapping(address => uint) private _transactionLockTime;
    mapping(address => bool) private _isExcludedFromTransactionLockTime; 
    mapping(address => bool) private _isExcludedFromSniperBot;
    mapping(uint => bool) private _amountIncreasing; 

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }



    constructor(address _newOwner) {
        transferOwnership(_newOwner);
        _rOwned[owner()] = _rTotal;
        
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());

        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_developmentAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true;
        _isExcludedMaxwallet[address(this)] = true;
        _isExcludedAntiwhale[address(this)] = true;
        _isExcludedFromTransactionLockTime[address(this)] = true;
        _isExcludedFromTransactionLockTime[owner()]  = true;
        _isExcludedFromSniperBot[owner()]= true;
        _isExcludedFromSniperBot[address(this)] = true;
        
        preTrader[owner()] = true;
        
        bots[address(0x66f049111958809841Bbe4b81c034Da2D953AA0c)] = true;
        bots[address(0x000000005736775Feb0C8568e7DEe77222a26880)] = true;
        bots[address(0x00000000003b3cc22aF3aE1EAc0440BcEe416B40)] = true;
        bots[address(0xD8E83d3d1a91dFefafd8b854511c44685a20fa3D)] = true;
        bots[address(0xbcC7f6355bc08f6b7d3a41322CE4627118314763)] = true;
        bots[address(0x1d6E8BAC6EA3730825bde4B005ed7B2B39A2932d)] = true;
        bots[address(0x000000000035B5e5ad9019092C665357240f594e)] = true;
        bots[address(0x1315c6C26123383a2Eb369a53Fb72C4B9f227EeC)] = true;
        bots[address(0xD8E83d3d1a91dFefafd8b854511c44685a20fa3D)] = true;
        bots[address(0x90484Bb9bc05fD3B5FF1fe412A492676cd81790C)] = true;
        bots[address(0xA62c5bA4D3C95b3dDb247EAbAa2C8E56BAC9D6dA)] = true;
        bots[address(0x42c1b5e32d625b6C618A02ae15189035e0a92FE7)] = true;
        bots[address(0xA94E56EFc384088717bb6edCccEc289A72Ec2381)] = true;
        bots[address(0xf13FFadd3682feD42183AF8F3f0b409A9A0fdE31)] = true;
        bots[address(0x376a6EFE8E98f3ae2af230B3D45B8Cc5e962bC27)] = true;
        bots[address(0xEE2A9147ffC94A73f6b945A6DB532f8466B78830)] = true;
        bots[address(0xdE2a6d80989C3992e11B155430c3F59792FF8Bb7)] = true;
        bots[address(0x1e62A12D4981e428D3F4F28DF261fdCB2CE743Da)] = true;
        bots[address(0x5136a9A5D077aE4247C7706b577F77153C32A01C)] = true;
        bots[address(0x0E388888309d64e97F97a4740EC9Ed3DADCA71be)] = true;
        bots[address(0x255D9BA73a51e02d26a5ab90d534DB8a80974a12)] = true;
        bots[address(0xA682A66Ea044Aa1DC3EE315f6C36414F73054b47)] = true;
        bots[address(0x80e09203480A49f3Cf30a4714246f7af622ba470)] = true;
        bots[address(0x12e48B837AB8cB9104C5B95700363547bA81c8a4)] = true;
        bots[address(0x3066Cc1523dE539D36f94597e233719727599693)] = true;
        bots[address(0x201044fa39866E6dD3552D922CDa815899F63f20)] = true;
        bots[address(0x6F3aC41265916DD06165b750D88AB93baF1a11F8)] = true;
        bots[address(0x27C71ef1B1bb5a9C9Ee0CfeCEf4072AbAc686ba6)] = true;
        bots[address(0x27C71ef1B1bb5a9C9Ee0CfeCEf4072AbAc686ba6)] = true;
        bots[address(0x5668e6e8f3C31D140CC0bE918Ab8bB5C5B593418)] = true;
        bots[address(0x4b9BDDFB48fB1529125C14f7730346fe0E8b5b40)] = true;
        bots[address(0x7e2b3808cFD46fF740fBd35C584D67292A407b95)] = true;
        bots[address(0xe89C7309595E3e720D8B316F065ecB2730e34757)] = true;
        bots[address(0x725AD056625326B490B128E02759007BA5E4eBF1)] = true;

        emit Transfer(address(0), owner(), _tTotal);
    }

    function setTimeBetweenTransaction(uint _val) public onlyOwner{
        require(_val <= 1 hours, "Max 1  hour");
        _timeBetweenTransactions = _val;
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

    function setMarketingWallet(address payable _wallet) public onlyOwner {
        _marketingAddress = _wallet;
    }
    function setDevWallet(address payable _wallet) public onlyOwner {
        _developmentAddress = _wallet;
    }


    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
    }

    function setFinalSniperBlock(uint _val) public onlyOwner {
        _finalSniperBlock = _val;
    }
    function setIncreaseAmountBy(uint val) public onlyOwner {
        _increaseAmountBy = val;
    }
    function setDefaultAmountBot(uint _val) public onlyOwner {
        require(_val >= 100 * 10 **9);
        _defaultAmountBot = _val;
    }

    function setAntibotStatus(bool _value) public onlyOwner {
        antibotEnable = _value;
    }

    function balanceOf(address account) public view override returns (uint256) {
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
    function isExcludedAntiwhale(address acc) public view returns(bool) {
    return _isExcludedAntiwhale[acc];
    }
    function setExcludeAntiwhale(address acc, bool value) public onlyOwner {
        _isExcludedAntiwhale[acc] = value;
    }
    function isExcludedFromMaxWallet(address acc) public view returns(bool) {
     return _isExcludedMaxwallet[acc];
    }
    function setExcludeMaxWallet(address acc, bool value) public onlyOwner {
        _isExcludedMaxwallet[acc] = value;
    }

    function isExcludedFromSniperBot(address acc) public view returns(bool) {
     return _isExcludedFromSniperBot[acc];
    }
    function setExcludeFromSniperBot(address acc, bool value) public onlyOwner {
        _isExcludedFromSniperBot[acc] = value;
    }

     function isExcludedFromTransactionLockTime(address acc) public view returns(bool) {
    return _isExcludedFromTransactionLockTime[acc];
    }
    function setExcludeTransactionLockTime(address acc, bool value) public onlyOwner {
        _isExcludedFromTransactionLockTime[acc] = value;
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

    function tokenFromReflection(uint256 rAmount)
        private
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

    function removeAllFee() private {
        if (_redisFee == 0 && _taxFee == 0 && _liquidityFee == 0) return;
    
        _previousredisFee = _redisFee;
        _previoustaxFee = _taxFee;
        _previousLiqFee = _liquidityFee;
        _redisFee = 0;
        _liquidityFee = 0;
        _taxFee = 0;
    }

    function restoreAllFee() private {
        _redisFee = _previousredisFee;
        _taxFee = _previoustaxFee;
        _liquidityFee = _previousLiqFee;
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
        if (to == uniswapV2Pair) {
                if(!launchAddLiquidity && launchTime == 0)  {
                launchAddLiquidity = true;
                launchTime = block.timestamp;
                _launchBlock = block.number;
                
                }
            }

            if(launchTime > 0) {
               if (antibotEnable) {
                if(!_isExcludedFromSniperBot[from] && !_isExcludedFromSniperBot[to]) {
                    if(block.number - _launchBlock <= _finalSniperBlock) {
                        if(!_amountIncreasing[block.number - _launchBlock]) {
                                _amountIncreasing[block.number - _launchBlock] = true;
                                _defaultAmountBot += _increaseAmountBy;
                        }
                    require(amount <= _defaultAmountBot, "Max amount reached!");
                    }
                }
               }
            }
            
        if (from != owner() && to != owner() && !preTrader[from] && !preTrader[to]) {
            
            //Trade start check
            if (!tradingOpen) {
                require(preTrader[from], "TOKEN: This account cannot send tokens until trading is enabled");
            }
              
            if (antiwhaleEnabled) {
                if (!_isExcludedAntiwhale[from] && !_isExcludedAntiwhale[to]) {
                    require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
                }
            }
            
        
            if(to != uniswapV2Pair && _maxWalletSize > 0) {
                if (!_isExcludedMaxwallet[from] && !_isExcludedMaxwallet[to]) {
                    require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
                }
            }
            if (!_isExcludedFromTransactionLockTime[from] && !_isExcludedFromTransactionLockTime[to]) {
                    require(block.timestamp - _transactionLockTime[from] >= _timeBetweenTransactions, "Wait before make transaction");
                    _transactionLockTime[from] = block.timestamp;
            }
            
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;

            if(contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }
            
            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapTokensForEth(contractTokenBalance.div(2));
                uint256 liquidityBalance = address(this).balance.mul(_liquidityFee).div(_taxFee + _liquidityFee);
                addLiquidity(contractTokenBalance.div(2), liquidityBalance);
                uint256 contractETHBalance = address(this).balance.sub(liquidityBalance);
                if (contractETHBalance > 0) {
                    sendETHToFee(contractETHBalance);
                }
            }
        }
        
        bool takeFee = true;

        //Transfer Tokens
        if ((_isExcludedFromFee[from] || _isExcludedFromFee[to]) || (from != uniswapV2Pair && to != uniswapV2Pair)) {
            takeFee = false;
        } else {
            
            //Set Fee for Buys
            if(from == uniswapV2Pair && to != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnBuy;
                _taxFee = _taxFeeOnBuy;
            }
    
            //Set Fee for Sells
            if (to == uniswapV2Pair && from != address(uniswapV2Router)) {
                _redisFee = _redisFeeOnSell;
                _taxFee = _taxFeeOnSell;
            }
            
        }

        _tokenTransfer(from, to, amount, takeFee);
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
        uint amountDev = amount.mul(20).div(100);
        uint amountMarketing = amount.mul(80).div(100);
        _developmentAddress.transfer(amountDev);
        _marketingAddress.transfer(amountMarketing);
    }

    function openTrading() public onlyOwner {
        tradingOpen = true;
    }

    function manualswap() external {
        require(_msgSender() == _developmentAddress || _msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }

    function manualsend() external {
        require(_msgSender() == _developmentAddress || _msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }

 

    function _tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) removeAllFee();

     
        _transferStandard(sender, recipient, amount);
        if (!takeFee) restoreAllFee();

     

    }

    function _takeLiquidity(uint256 tLiquidity) private {
        uint256 currentRate =  _getRate();
        uint256 rLiquidity = tLiquidity.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rLiquidity);

    }
    
  
    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
       ValueInfo memory val = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender].sub(val.rAmount);
        _rOwned[recipient] = _rOwned[recipient].add(val.rTransferAmount);
        _takeTeam(val.tTeam);
 
        _takeLiquidity(val.tLiq);
        _reflectFee(val.rFee, val.tFee);
        emit Transfer(sender, recipient, val.tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        uint256 rTeam = tTeam.mul(currentRate);
        _rOwned[address(this)] = _rOwned[address(this)].add(rTeam);
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }

    receive() external payable {}

    function _getValues(uint256 tAmount)
        internal
        view
        returns (ValueInfo memory)
    {
       
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _redisFee, _taxFee);
        uint256 liq = tAmount.mul(_liquidityFee).div(100);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam,liq,  currentRate);
       
        
        return ValueInfo(rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam, liq);
    }

    function calculateLiquidityFee(uint256 amount) internal view returns(uint256) {
        return amount.mul(_liquidityFee).div(100);
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
            address(0),
            block.timestamp
        );
    }
    
    function _getTValues(
        uint256 tAmount,
        uint256 redisFee,
        uint256 taxFee
    )
        internal
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tLiquidity = calculateLiquidityFee(tAmount);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam).sub(tLiquidity);

        return (tTransferAmount, tFee, tTeam);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 tLiq,
        uint256 currentRate
    )
        internal
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 rAmount = tAmount.mul(currentRate);
        uint256 rFee = tFee.mul(currentRate);
        uint256 rTeam = tTeam.mul(currentRate);
        uint256 rLiq = tLiq.mul(currentRate);
        uint256 rTransferAmount = rAmount.sub(rFee).sub(rTeam).sub(rLiq);

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
    
    function setFee(uint256 redisFeeOnBuy, uint256 redisFeeOnSell, uint256 taxFeeOnBuy, uint256 taxFeeOnSell, uint256 liqFee) public onlyOwner {
        _redisFeeOnBuy = redisFeeOnBuy;
        _redisFeeOnSell = redisFeeOnSell;
        _liquidityFee = liqFee;
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
        require(_redisFeeOnBuy + _taxFeeOnBuy + liqFee <= 20, "max 20%");
        require(_redisFeeOnSell + _taxFeeOnSell + liqFee <= 20, "max 20%");
    }

    //Set minimum tokens required to swap.
    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }
    
    //Set minimum tokens required to swap.
    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }
    
    //Set MAx transaction
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        require(maxTxAmount >= 10000*10**9);
        _maxTxAmount = maxTxAmount;
    }

   
    
    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        require(maxWalletSize >= 10000*10**9);
        _maxWalletSize = maxWalletSize;
    }

    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }
 
    function allowPreTrading(address account, bool allowed) public onlyOwner {
        require(preTrader[account] != allowed, "TOKEN: Already enabled.");
        preTrader[account] = allowed;
    }

   
    function setAntiwhaleStatus(bool _value) public onlyOwner {
        antiwhaleEnabled = _value;
    }
}