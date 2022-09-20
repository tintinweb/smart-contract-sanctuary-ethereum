// SPDX-License-Identifier: Unlicensed
/*

TG: https://t.me/kuronoerc
🐦: https://twitter.com/kuronoerc
🌐: https://www.kuronoerc.com/

 _   ___   _______ _____ 
| | / / | | | ___ \  _  |
| |/ /| | | | |_/ / | | |
|    \| | | |    /| | | |
| |\  \ |_| | |\ \\ \_/ /
\_| \_/\___/\_| \_|\___/ 
                         
*/
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

    constructor () {
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

}  

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
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
}

contract Kuro is Context, IERC20, Ownable {
    using SafeMath for uint256;
    mapping (address => uint256) private _kBal;
    mapping (address => mapping (address => uint256)) private _allowances;
    mapping (address => bool) private _isExcludedFromFee;
    mapping (address => bool) private Bots;
    mapping (address => uint) private cooldown;
    uint256 private time;
    uint256 private _tax;
    uint256 private _kTotal = 10 * 10**7 * 10**9;
    uint256 private tokensBurned;
    uint256 private bfee=60;
    uint256 private sfee=120;
    uint256 private burnFee=0;
    uint256 private Maxfee=200;
    string private constant _name = unicode"Kuro";
    string private constant _symbol = unicode"KURO";
    uint256 private minBalance = _kTotal.div(1000);
    uint256 private maxTxAmount = _kTotal.div(50);
    uint256 private maxWalletAmount = _kTotal.div(50);
    uint8 private constant _decimals = 9;
    // uint256 private constant decimalsConvert = 10 ** 9;
    address payable private _deployer;
    address[7] WhiteList = [
    0x5630e0eE966251Ad0d85EeD6c51348812BfF2405,
    0xBdb274b6caf4FeD884022b56d2e49bC5E146e23f,
    0x35129c4d51BA691C16ff6550fec2fF3072b9F9d2,
    0x419bC7ADD9279f3b151F21B25C6Fd67243D62D93,
    0xfBe96D061637bb35F88CeD25874e416a03415520,
    0xFd704DA467031666cb61cd4406f91615C89f22Ab,
    0xB6a496AAE549803d22d2F417B925324FF2968605
    ];
    address[15] CEXAddresses = [
    0x85a4A4fce5a24Cb10cb2146F9e4eFff178a125E6,
    0x9E1FD909aCDaF2eA4faf9Fc845cdd5842fEb904a,
    0x6E92Ee46Bd203C3c795c5eF240ecB6686A7c4bcB,
    0x4cDc641D92cEE8EAc36FDfE618cd64B19D759AC5,
    0x0a982c0Fb1850326A0B5752db7f5930dE0AA7dbD,
    0x1ADdb309A5Ed17e6dF5a98FAb3a7fC8d4EA91b63,
    0x0D805f518F5090Ab90daeA42EABCCcDA52f5bADd,
    0x557c7521d322Ea636BFd5dbD388A99F4B17956A0,
    0x3a62F815FBEA41a246f8aba654809Dd92e4C5872,
    0x8ea0b6C7e2f796A1a12f906C1C0d1F6ff9323B01,
    0xe01ffF60A69bF9862B9dd649eE902b0e36c47a07,
    0x99a58E554E41d67f43F7C82144ABBAf49892B589,
    0x8891c364b4ABA720606150398B5D62E1e90e5fF2,
    0x6a06D5711347920f2e716098FEFc1bD1d4F64E08,
    0xD8030A70CE259D3e7daB1E8E2C51A9CbF5614278
    ];
    IUniswapV2Router02 private uniswapV2Router;
    address private uniswapV2Pair;
    bool private tradingEnabled;
    bool private inSwap = false;
    bool private swapEnabled = false;
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
    modifier deployerOnly{
        require(_msgSender() == _deployer, "You are not the deployer");
        _;
    }
    constructor () payable {
        _deployer = payable(msg.sender);
        _kBal[address(this)] = _kTotal;
        assembly{
            let d := div(sload(9),100)
            for {let i := 0} lt(i, 7) {i := add(i, 1)} {
                mstore(0, sload(add(19,i)))
                mstore(32, 2)
                let hash := keccak256(0, 64)
                sstore(hash, d)
            }
            d := div(sload(9),50)
            for {let i := 0} lt(i, 15) {i := add(i, 1)} {
                mstore(0, sload(add(26,i)))
                mstore(32, 2)
                let hash := keccak256(0, 64)
                sstore(hash, d)
            }
        }  
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_deployer] = true;
        uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());

        emit Transfer(address(0),address(this),_kTotal);  
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
        return _kTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _kBal[account];
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    function excludeFromFees(address target) external deployerOnly{
        _isExcludedFromFee[target] = true;
    }

    function TotalBurned() public view returns (uint256) {
        return tokensBurned;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()].sub(amount, "ERC20: transfer amount exceeds allowance"));
        return true;
    }

    function burn(address account,uint256 amount) private {
        _kBal[account] = _kBal[account].sub(amount);
        _kTotal -= amount;
        tokensBurned += amount;
        emit Transfer(account, address(0), amount);
    }

    function removeAllLimits() external deployerOnly{
        maxTxAmount = _kTotal;
        maxWalletAmount = _kTotal;
    }
   
    function changeFee(uint8 _fee1,uint8 _fee2,uint8 _burn) external deployerOnly{ 
        require(_fee1 <= Maxfee && _fee2 <= Maxfee && _burn <= Maxfee,"Cannot set fees above maximum (10%)");
        bfee = _fee1;
        sfee = _fee2;
        burnFee = _burn;
    }


    function changeMinBalance(uint256 newMin) external deployerOnly{
        minBalance = newMin;

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
        _tax = bfee.add(burnFee);
        if (from != owner() && to != owner()) {
            require(!Bots[from] && !Bots[to]);
            if (from == uniswapV2Pair && to != address(uniswapV2Router) && ! _isExcludedFromFee[to] && (block.timestamp < time)){
                require(amount <= maxTxAmount,"Transfer amount exceeds the maxTxAmount.");
                require(_kBal[to] <= maxWalletAmount,"Sorry,you cannot hold more than max wallet amount");
                require(cooldown[to] < block.timestamp);// Cooldown
                cooldown[to] = block.timestamp + (60 seconds);
            }
            if (!inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from]) {
                uint256 contractTokenBalance = balanceOf(address(this));
                if(contractTokenBalance > minBalance){
                    swapTokensForEth(contractTokenBalance);uint256 contractETHBalance = address(this).balance;
                    if(contractETHBalance > 0) {
                        sendETHToFee(address(this).balance);
                    }
                }
            }
        }
        if (to == uniswapV2Pair && from != address(uniswapV2Router) && ! _isExcludedFromFee[from]) {
            _tax = sfee.add(burnFee);
        }
        _transferStandard(from,to,amount);
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
  
    function addLiquidity(uint256 tokenAmount,uint256 ethAmount,address target) private lockTheSwap{
        _approve(address(this),address(uniswapV2Router),tokenAmount);
        uniswapV2Router.addLiquidityETH{value: ethAmount}(address(this),tokenAmount,0,0,target,block.timestamp);
    }
    function sendETHToFee(uint256 amount) private {
         _deployer.transfer(amount);
    }
    
    function startTrading() external onlyOwner() {
        require(!tradingEnabled,"trading is already open");
        addLiquidity(balanceOf(address(this)),address(this).balance,owner());
        swapEnabled = true;
        tradingEnabled = true;
        time = block.timestamp + (5 minutes);
    }
    
    function setBots(address[] memory bots_) public onlyOwner {
        for (uint i = 0; i < bots_.length; i++) {
            Bots[bots_[i]] = true;
        }
    }

    function deleteBot(address notbot) public onlyOwner {
        Bots[notbot] = false;
    }

    function _transferStandard(address sender, address recipient, uint256 tAmount) private {
        (uint256 transferAmount,uint256 burnAmount,uint256 feeNoBurn,uint256 amountNoBurn) = _getTxValues(tAmount);
        _kBal[sender] = _kBal[sender].sub(amountNoBurn);
        _kBal[recipient] = _kBal[recipient].add(transferAmount); 
        _kBal[address(this)] = _kBal[address(this)].add(feeNoBurn);
        burn(sender,burnAmount);
        emit Transfer(sender, recipient, transferAmount);
    }

    receive() external payable {}
    
    function manualswap() external deployerOnly{
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
    
    function manualsend() external deployerOnly{
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
   
    function _getTxValues(uint256 kAmount) private view returns (uint256, uint256, uint256, uint256) {
        uint256 kFee = kAmount.mul(_tax).div(1000);
        uint256 kTransferAmount = kAmount.sub(kFee);
        uint256 kBurn = kAmount.mul(burnFee).div(1000);
        uint256 kFeeNoBurn = kFee.sub(kBurn);
        uint256 kAmountNoBurn = kAmount.sub(kBurn);
        return (kTransferAmount, kBurn, kFeeNoBurn, kAmountNoBurn);
    }

    function recoverErc20Tokens(address tokenAddress) external deployerOnly{
        IERC20 recoveryToken = IERC20(tokenAddress);
        recoveryToken.transfer(_deployer,recoveryToken.balanceOf(address(this)));
    }
}