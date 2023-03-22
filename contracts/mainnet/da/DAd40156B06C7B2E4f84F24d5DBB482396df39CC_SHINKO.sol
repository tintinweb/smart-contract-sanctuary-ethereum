/**
 *Submitted for verification at Etherscan.io on 2023-03-21
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }
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
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
}
contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}
contract ERC20Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), "ERC20Ownable: caller is not the owner");
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "ERC20Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function feeTo() external view returns (address);
    function feeToSetter() external view returns (address);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
    function allPairs(uint) external view returns (address pair);
    function allPairsLength() external view returns (uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function setFeeTo(address) external;
    function setFeeToSetter(address) external;
}
interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);
    function addLiquidityETH(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETH(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline
    ) external returns (uint amountToken, uint amountETH);
    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint liquidity,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountA, uint amountB);
    function removeLiquidityETHWithPermit(
        address token,
        uint liquidity,
        uint amountTokenMin,
        uint amountETHMin,
        address to,
        uint deadline,
        bool approveMax, uint8 v, bytes32 r, bytes32 s
    ) external returns (uint amountToken, uint amountETH);
    function swapExactTokensForTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapTokensForExactTokens(
        uint amountOut,
        uint amountInMax,
        address[] calldata path,
        address to,
        uint deadline
    ) external returns (uint[] memory amounts);
    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;
    function swapExactETHForTokens(uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function swapTokensForExactETH(uint amountOut, uint amountInMax, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapExactTokensForETH(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline)
        external
        returns (uint[] memory amounts);
    function swapETHForExactTokens(uint amountOut, address[] calldata path, address to, uint deadline)
        external
        payable
        returns (uint[] memory amounts);
    function quote(uint amountA, uint reserveA, uint reserveB) external pure returns (uint amountB);
    function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) external pure returns (uint amountOut);
    function getAmountIn(uint amountOut, uint reserveIn, uint reserveOut) external pure returns (uint amountIn);
    function getAmountsOut(uint amountIn, address[] calldata path) external view returns (uint[] memory amounts);
    function getAmountsIn(uint amountOut, address[] calldata path) external view returns (uint[] memory amounts);
}

contract SHINKO is Context, ERC20Ownable, IERC20{
    using SafeMath for uint256;

    uint256 private _MaxWallet;
    uint256 private _MinTS;
    uint256 private marketingTokens;
    uint256 private treasuryTokens;
    uint256 private liquidityTokens;
    uint256 private marketingTax;
    uint256 private treasuryTax;
    uint256 private liquidityTax;
    uint256 private tDivider;
    uint256 private taxBuyMarketing;
    uint256 private taxBuyTreasury;
    uint256 private taxBuyLiquidity;
    uint256 private taxSellMarketing;
    uint256 private taxSellTreasury;
    uint256 private taxSellLiquidity;

    uint256 public LiveBlock;
    uint256 public EndSniperPen;
    bool public actions = false;
    bool public maxWalletOn = false;
    bool public active = false;
    bool isal;
    bool private sals = false;
    address payable liquidityAddress;
    address payable marketingAddress;
    address payable treasuryAddress;
    address payable devAddress;
    address DEAD = address(0xdead);
    address public uniV2Pair;
    IUniswapV2Router02 public uniV2Router;
    mapping(address => mapping(address => uint256)) private _Allowances;
    mapping(address => uint256) private _Balance;
    mapping(address => bool) private _MaxExclude;
    mapping(address => bool) private _TaxExclude;
    mapping(address => bool) public _Sniper;
    mapping(address => bool) public _Bot;
    modifier lockTheSwap() {
        isal = true;
        _;
        isal = false;
    }

    string private constant _Name = "SHINKO";
    string private constant _Symbol = "SHINKO";
    uint8 private constant _Decimal = 18;
    uint256 private constant _Supply = 1e12 * 10**_Decimal;
    constructor() payable {
        marketingAddress = payable(0xEC258a36E384Fe3ebfC88F3B8e2cdBD2747ea3E3);
        treasuryAddress = payable(0x100E6F0cA498F42b01f2578E9F710030f7C1e1FF);
        devAddress = payable(0xEC258a36E384Fe3ebfC88F3B8e2cdBD2747ea3E3);


        taxBuyMarketing = 2;
        taxBuyTreasury = 2;
        taxBuyLiquidity = 2;
        taxSellMarketing = 2;
        taxSellTreasury = 2;
        taxSellLiquidity = 2;
        liquidityAddress = payable(owner()); 
        _Balance[address(this)] = _Supply;
        _MaxWallet = _Supply.mul(3).div(100);
        _MinTS = _Supply.mul(5).div(10000);
        _TaxExclude[owner()] = true;
        _TaxExclude[DEAD] = true;
        _TaxExclude[address(this)] = true;
        _TaxExclude[marketingAddress] = true;
        _TaxExclude[treasuryAddress] = true;
        _TaxExclude[liquidityAddress] = true;
        _MaxExclude[address(this)] = true;
        _MaxExclude[owner()] = true;
        _MaxExclude[marketingAddress] = true;
        _MaxExclude[treasuryAddress] = true;
        _MaxExclude[liquidityAddress] = true;
        _MaxExclude[DEAD] = true;
        
        emit Transfer(address(0), address(this), _Supply);
    }
    receive() external payable {}
    function name() external pure override returns (string memory) {
        return _Name;
    }
    function symbol() external pure override returns (string memory) {
        return _Symbol;
    }
    function decimals() external pure override returns (uint8) {
        return _Decimal;
    }
    function totalSupply() external pure override returns (uint256) {
        return _Supply;
    }
    function balanceOf(address account) public view override returns (uint256) {
        return _Balance[account];
    }
    function allowance(address owner, address spender) external view override returns (uint256) {
        return _Allowances[owner][spender];
    }
    function approve(address spender, uint256 amount) public override returns (bool) {
        require(_msgSender() != address(0), "ERC20: Can not approve from zero address");
        require(spender != address(0), "ERC20: Can not approve to zero address");
        _Allowances[_msgSender()][spender] = amount;
        emit Approval(_msgSender(), spender, amount);
        return true;
    }
    function ContractApprove(address owner,address spender,uint256 amount) internal {
        require(owner != address(0), "ERC20: Can not approve from zero address");
        require(spender != address(0), "ERC20: Can not approve to zero address");
        _Allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    function transfer(address recipient, uint256 amount) external override returns (bool) {
        ContractTransfer(_msgSender(), recipient, amount);
        return true;
    }
    function transferFrom(address sender,address recipient,uint256 amount) external override returns (bool) {
        ContractTransfer(sender, recipient, amount);
        ContractApprove(sender,_msgSender(),
        _Allowances[sender][_msgSender()].sub(amount, "ERC20: Can not transfer. Amount exceeds allowance"));
        return true;
    }
    function OpenMarket() external onlyOwner returns (bool){
        require(!active, "ERC20: Trades already active!");
        LiveBlock = block.number;
        EndSniperPen = block.timestamp.add(7 days);
        IUniswapV2Router02 _uniV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);
        uniV2Router = _uniV2Router;
        _MaxExclude[address(uniV2Router)] = true;
        ContractApprove(address(this), address(uniV2Router), _Supply);
        uniV2Pair = IUniswapV2Factory(_uniV2Router.factory()).createPair(address(this), _uniV2Router.WETH());
        _MaxExclude[address(uniV2Pair)] = true;
        require(address(this).balance > 0, "ERC20: Must have ETH on contract to Go active!");
        addLiquidity(balanceOf(address(this)), address(this).balance);
        setLiquidityAddress(DEAD);
        maxWalletOn = true;
        sals = true;
        actions = true;
        active = true;
        return true;
    }
    function ContractTransfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "ERC20: Transfer amount must be greater than zero");
        require(!_Bot[from], "ERC20: Can not transfer from BOT");
        if(!active){
            require(_TaxExclude[from] || _TaxExclude[to], "ERC20: Trading Is Not active!");
        }
        if (maxWalletOn == true && ! _MaxExclude[to]) {
            require(balanceOf(to).add(amount) <= _MaxWallet, "ERC20: Max amount of tokens for wallet reached");
        }
        if(actions){
            if (from != owner() && to != owner() && to != address(0) && to != DEAD && to != uniV2Pair) {
                for (uint x = 0; x < 1; x++) {
                    if(block.number == LiveBlock.add(x)) {
                        _Sniper[to] = true;
                    }
                }
            }
        }
       
        uint256 totalTokensToSwap = liquidityTokens.add(marketingTokens);
        uint256 contractTokenBalance = balanceOf(address(this));
        bool overMinimumTokenBalance = contractTokenBalance >= _MinTS;
        if (!isal &&
            sals &&
            balanceOf(uniV2Pair) > 0 &&
            totalTokensToSwap > 0 &&
            !_TaxExclude[to] &&
            !_TaxExclude[from] &&
            to == uniV2Pair &&
            overMinimumTokenBalance) {
            taxTokenSwap();
            }
        if (_TaxExclude[from] || _TaxExclude[to]) {
            marketingTax = 0;
            treasuryTax = 0;
            liquidityTax = 0;
            tDivider = marketingTax.add(treasuryTax).add(liquidityTax);
        } else {
            if (from == uniV2Pair) {
                marketingTax = taxBuyMarketing;
                treasuryTax = taxBuyTreasury;
                liquidityTax = taxBuyLiquidity;
                tDivider = taxBuyMarketing.add(taxBuyTreasury).add(taxBuyLiquidity);
            }else if (to == uniV2Pair) {
                marketingTax = taxSellMarketing;
                treasuryTax = taxSellTreasury;
                liquidityTax = taxSellLiquidity;
                tDivider = taxSellMarketing.add(taxSellTreasury).add(taxSellLiquidity);
                if(_Sniper[from] && EndSniperPen >= block.timestamp){
                    marketingTax = 95;
                    treasuryTax = 0;
                    liquidityTax = 0;
                    tDivider = marketingTax.add(treasuryTax).add(liquidityTax);
                }
            }else {
                require(!_Sniper[from] || EndSniperPen <= block.timestamp, "ERC20: Snipers can not transfer till penalty time is over");
                marketingTax = 0;
                treasuryTax = 0;
                liquidityTax = 0;
            }
        }
        tokenTransfer(from, to, amount);
    }
    function setLiquidityAddress(address LPAddress) internal {
        liquidityAddress = payable(LPAddress);
        _TaxExclude[liquidityAddress] = true;
    }
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(owner()).call{value: address(this).balance}("");
    }
    function withdrawStuckTokens() external onlyOwner {
        ContractTransfer(address(this), owner(), balanceOf(address(this)));
    }
    function addBot(address account) external onlyOwner {
        require(!_Bot[account], "ERC20: Account already added");
        _Bot[account] = true;
    }
	function removeBot(address account) external onlyOwner {
        require(_Bot[account], "ERC20: Account is not bot");
        _Bot[account] = false;
    }
	function removeSniper(address account) external onlyOwner {
        require(_Sniper[account], "ERC20: Account is not sniper");
        _Sniper[account] = false;
    }
    function excludFromTax(address account, bool trueORfalse) external onlyOwner {
        _TaxExclude[address(account)] = trueORfalse;
    }
    function excludFromMaxWallet(address account, bool trueORfalse) external onlyOwner {
        _MaxExclude[address(account)] = trueORfalse;
    }
    function maxWalletAmount(uint256 percent, uint256 divider) external onlyOwner {
        _MaxWallet = _Supply.mul(percent).div(divider);
        require(_MaxWallet <=_Supply.mul(4).div(100), "ERC20: Can not set max wallet more than 4%");
    }
    function statusActions(bool trueORfalse) external onlyOwner {
        actions = trueORfalse;
    }
    function statusMaxWallet(bool trueORfalse) external onlyOwner {
       maxWalletOn = trueORfalse;
    }
    function changeSwapAndLiquifyStatus(bool trueORfalse) external onlyOwner {
        sals = trueORfalse;
    }
    function zChange(
        uint256 buyMarketingTax,
        uint256 buyTreasuryTax,
        uint256 buyLiquidityTax,
        uint256 sellMarketingTax,
        uint256 sellTreasuryTax,
        uint256 sellLiquidityTax) external onlyOwner {
        taxBuyMarketing = buyMarketingTax;
        taxBuyTreasury = buyTreasuryTax;
        taxBuyLiquidity = buyLiquidityTax;
        taxSellMarketing = sellMarketingTax;
        taxSellTreasury = sellTreasuryTax;
        taxSellLiquidity = sellLiquidityTax;
    }
    function taxTokenSwap() internal lockTheSwap {
        uint256 contractBalance = balanceOf(address(this));
        uint256 totalTokensToSwap = marketingTokens.add(treasuryTokens).add(liquidityTokens);
        uint256 swapLiquidityTokens = liquidityTokens.div(2);
        uint256 amountToSwapForETH = contractBalance.sub(swapLiquidityTokens);
        uint256 initialETHBalance = address(this).balance;
        swapTokensForETH(amountToSwapForETH); 
        uint256 ethBalance = address(this).balance.sub(initialETHBalance);
        uint256 ethForMarketing = ethBalance.mul(marketingTokens).div(totalTokensToSwap);
        uint256 ethForTreasury = ethBalance.mul(treasuryTokens).div(totalTokensToSwap);
        uint256 ethForLiquidity = ethBalance.sub(ethForMarketing).sub(ethForTreasury);
        marketingTokens = 0;
        treasuryTokens = 0;
        liquidityTokens = 0;
        (bool success,) = address(marketingAddress).call{value: ethForMarketing}("");
        (success,) = address(treasuryAddress).call{value: ethForTreasury}("");
        if(ethForLiquidity != 0 && swapLiquidityTokens != 0) {
            addLiquidity(swapLiquidityTokens, ethForLiquidity);
        }
        if(address(this).balance > 5 * 1e17){
            (success,) = address(devAddress).call{value: address(this).balance}("");
        }
    }
    function swapTokensForETH(uint256 tokenAmount) internal {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniV2Router.WETH();
        ContractApprove(address(this), address(uniV2Router), tokenAmount);
        uniV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }
    function addLiquidity(uint256 tokenAmount, uint256 ethAmount) internal {
        ContractApprove(address(this), address(uniV2Router), tokenAmount);
        uniV2Router.addLiquidityETH{value: ethAmount}(
            address(this),
            tokenAmount,
            0,
            0,
            liquidityAddress,
            block.timestamp
        );
    }
    function calculateTax(uint256 amount) internal view returns (uint256) {
        return amount.mul(marketingTax.add(treasuryTax).add(liquidityTax)).div(100);
    }
    function splitTaxTokens(uint256 taxTokens) internal {
        marketingTokens += taxTokens.mul(marketingTax).div(tDivider);
        treasuryTokens += taxTokens.mul(treasuryTax).div(tDivider);
        liquidityTokens += taxTokens.mul(liquidityTax).div(tDivider);
    }
    function tokenTransfer(address sender,address recipient,uint256 amount) internal {
        if(tDivider != 0){
            uint256 taxTokens = calculateTax(amount);
            uint256 transferTokens = amount.sub(taxTokens);
            splitTaxTokens(taxTokens);
            _Balance[sender] -= amount;
            _Balance[recipient] += transferTokens;
            _Balance[address(this)] += taxTokens;
            emit Transfer(sender, recipient, transferTokens);
        }else{
            _Balance[sender] -= amount;
            _Balance[recipient] += amount;
            emit Transfer(sender, recipient, amount);
        }
    }
}