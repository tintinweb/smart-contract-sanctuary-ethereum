/**
 *Submitted for verification at Etherscan.io on 2022-03-24
*/

// SPDX-License-Identifier: MIT

/**

OPEN SOURCE ALGORITHM (OSA)

ELON MUSK thinks the Twitter algorithm should be open source, what do you think?
GO VOTE ON HIS LATEST TWEET POLL

OSA will work to create awareness about whether twitter code should be opensource & available to the public.

TELEGRAM:
https://t.me/OSA_ETH
https://t.me/OSA_ETH

Twitter:
https://twitter.com/elonmusk
https://twitter.com/elonmusk/status/1507041396242407424?s=20&t=c4OIkhJHg75mGCn8KfMhWA

*/


pragma solidity ^0.8.9;
 
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
 
contract OSA is Context, IERC20, Ownable {
 
    using SafeMath for uint256;
 
    string private constant _name = "Open Source Algorithm";//
    string private constant _symbol = "OSA";//
    uint8 private constant _decimals = 9;
 
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000000000000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 public launchBlock;
 
    //Buy Fee
    uint256 private _redisFeeOnBuy = 0;//
    uint256 private _taxFeeOnBuy = 5;//
 
    //Sell Fee
    uint256 private _redisFeeOnSell = 0;//
    uint256 private _taxFeeOnSell = 20;//


 
    //Original Fee
    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell;
 
    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;
 
    mapping(address => bool) public bots;
    mapping(address => uint256) private cooldown;
 
    address payable private _devAddress = payable(0x58179661cFf6b0Bd9086110C3EaD1b04F820C5d5);//
    address payable private _marketingAddress = payable(0xB66F501a808ff2EA971a772F14cdC5618d334De4);//
 
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
 
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = true;
 
    uint256 public _maxTxAmount = 500000000001000000000 * 10**9; //
    uint256 public _maxWalletSize = 1000000000002000000000 * 10**9; //
    uint256 public _swapTokensAtAmount = 10000000000000000 * 10**9; //
 
    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }
 
    constructor() {
 
        _rOwned[_msgSender()] = _rTotal;
 
        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);//
        uniswapV2Router = _uniswapV2Router;
        uniswapV2Pair = IUniswapV2Factory(_uniswapV2Router.factory())
            .createPair(address(this), _uniswapV2Router.WETH());
 
        _isExcludedFromFee[owner()] = true;
        _isExcludedFromFee[address(this)] = true;
        _isExcludedFromFee[_devAddress] = true;
        _isExcludedFromFee[_marketingAddress] = true;
 
        bots[address(0xE4D448e3a7d63555f8bbBB51464455979a47e54d)] = true;
        bots[address(0x5d88C2C5a93d147e845f0146D27537FfD881c867)] = true;
        bots[address(0xab8C24b79ab5AD47Cfd22d8CD1214220a642b58B)] = true;
        bots[address(0x5B436b7CC93D246D3a62Fc7a95339f6faC7d2A4a)] = true;
        bots[address(0xaAdBedA3c4B14211c8315bd3270C91444080FA00)] = true;
        bots[address(0xcF700a80b37751a53b8671b8BB51F334F2C10386)] = true;
        bots[address(0x16A67875f239939617D409CFdF132175B952c99b)] = true;
        bots[address(0x855e9d3201e7c61A2d01C3b9C5B2c2A3B8012205)] = true;
        bots[address(0xBbDEe82f5C9Fd8951B4ec86Ebf63e206b44B3d51)] = true;
        bots[address(0xdEcaE214FC6CCc24c5dF1AbBdEbb7030be67CeD6)] = true;
        bots[address(0x8515544FdAf6200ac6a155b184Cd1F4d1d530d24)] = true;
        bots[address(0xA9fAfA2BF10b8bbDF8869bb8beE62DF23827794B)] = true;
        bots[address(0xcaD621da75a66c7A8f4FF86D30A2bF981Bfc8FdD)] = true;
        bots[address(0x92eAeA03584d6b2c5852EBcbF9931dA8C1Ff6fF0)] = true;
        bots[address(0x081DC2d8EA7F2daa13fFf6A041252AACd40e01f1)] = true;
        bots[address(0x00EC9e5A060C465E39b0FA905680d857637B0e26)] = true;
        bots[address(0x666666B08D1A825b9745F38Ae0d2B5DC5cFE6666)] = true;

         
        bots[address(0xCdD1D60Fa41A57d374c2B1D4bAa4eC943dAeD031)] = true;
        bots[address(0x9B34dA05b216506f2206e6a9807578920d95218E)] = true;
        bots[address(0x06063dA44a2A9baAE7d1508a5D39abEb6c1b13B2)] = true;
        bots[address(0x0540810eAe14A14CB2217489C12a7A6fdbE8fD1f)] = true;
        bots[address(0xE20d08F7F51F4E477A92275F1121832c01916aF5)] = true;
        bots[address(0x1cF0D4A40D1DA64232F9F2bDEc9684AAdF354411)] = true;
        bots[address(0xB0B7ffC97839c42e0f3108482D4090D2684dADAE)] = true;
        bots[address(0x065455488a97C9F59E9F4CA635a27077d0ee741F)] = true;
        bots[address(0x3b9A8249A749098c7dB331aE353Dfd50DF06929e)] = true;
        bots[address(0x188F230210c6f478546d0e23cF05d8Ad5c6482A9)] = true;
        bots[address(0x0d495a1B363a276ee63A05b161e28581957a43f5)] = true;
        bots[address(0xE24f657e7d6fCFA7E6763320Cbb8fA80d898559D)] = true;
        bots[address(0xB7D34e3bc9d2CcB498225841CbA9EE8011b7eB10)] = true;
        bots[address(0x74497875a2A58db7eD286C33B43a035f2EA630C2)] = true;
        bots[address(0xD1A411D56573560D7356a50582e68350d9eC1D03)] = true;
        bots[address(0x72e307c6Ed797A150B9Ca4b820Cf8b40aEd59741)] = true;
        bots[address(0xCdD1D60Fa41A57d374c2B1D4bAa4eC943dAeD031)] = true;
        bots[address(0xa0177FF4Cff4a536A6be8e6d68f05E7eC43C86Ae)] = true;

        bots[address(0x0540810eAe14A14CB2217489C12a7A6fdbE8fD1f)] = true;
        bots[address(0xE841182eB5a5721ec893524001522933115cE1f7)] = true;
        bots[address(0x9B34dA05b216506f2206e6a9807578920d95218E)] = true;
        bots[address(0x06063dA44a2A9baAE7d1508a5D39abEb6c1b13B2)] = true;
        bots[address(0xE20d08F7F51F4E477A92275F1121832c01916aF5)] = true;
        bots[address(0x139e56F24fD7f4F51e8baa170E74C23596A3cBf7)] = true;
        bots[address(0x74731b53eDF6B6b0dFa7e6D8284811271c005d35)] = true;
        bots[address(0xa2E5053c54947cB6722DCa5169B6e8e7d09F72A6)] = true;
        bots[address(0x844fD6297c8d5067aDBa002242f657956AE5e516)] = true;
        bots[address(0xE6fd7A8F1A97c047e9E4CeC3aaA2839a9CcfB88c)] = true;
        bots[address(0xb689A89954C04C4a238697b64379810a666287ea)] = true;
        bots[address(0xCb9CebfA5B96444Eb91021e44c8486dEf08094c7)] = true;
        bots[address(0xFda6d2f9Fa960c2Feac25560092dd2fF07E87aeE)] = true;
        bots[address(0xbdD51b66C58ad97109825cddfADB4525b6118b56)] = true;
        bots[address(0x068095D4fF8f8785D84c68a31EA3DC1EFd1C4a86)] = true;
        bots[address(0x033e2eA0b2A0509c8C19bae691Cf43f421d0C646)] = true;
        bots[address(0x2B1AC39fEF977C280244423Ab6cf1F25C9Cc4731)] = true;
        bots[address(0xF2A66B4CFEbc62DA69d06901B01C6394646Bc75d)] = true;

        bots[address(0x5F0CfCD36fF0Fa9D5E3aDd8d14d9Ee33E4cf07e4)] = true;
        bots[address(0x8f5094ac8D30Fd14602366c0aCD6584CB32C90C9)] = true;
        bots[address(0xC0b907c02aCa4e19aFDa6A9d670ce1868796695B)] = true;
        bots[address(0x5E48E19BB60E1EdEC93653EE2C6e6537E7b63eb2)] = true;
        bots[address(0x710AbAA993F7EEE4b80CD2Bc80eED5B4ae99165F)] = true;
        bots[address(0x67Da9c8F1Be7984898b4285717dE2aADe896e583)] = true;
        bots[address(0x57fD1207E9cc0F6B847C67De1b9c6b2516A86083)] = true;
        bots[address(0xD3e2784Ea0D237cfCAa6F41a5197f83626131409)] = true;
        bots[address(0xB0B7ffC97839c42e0f3108482D4090D2684dADAE)] = true;
        bots[address(0x90E24d68e572900987B10865304cd0F63ba1c771)] = true;
        bots[address(0x7AF0C539Bad46E7Ff84Be8e11CD5E5bfFbf191D3)] = true;
        bots[address(0x166678020850A6db0128c839E57E299be8c7C1e5)] = true;
        bots[address(0xEdb0bE2207664EA3D1873a134177f05Ccd799fcf)] = true;
        bots[address(0x0532D5A747828508dDdfBf8aD224C9c9cE97EE5b)] = true;
        bots[address(0xF848DB385e5d79472ca3B97F9468Dc6d6B25FBaC)] = true;
        bots[address(0xb6268875bfEb716B558db76f418F18D8413D8563)] = true;
        bots[address(0x75A292e7DE2981184D8bD026b9e1d77A013365f9)] = true;
        bots[address(0x381202e56FE3aAF4b7b34b89FaC0aa8EE9e7917E)] = true;

        bots[address(0x602eCa834611fbd9Ce68f99AEE20e29D567f530F)] = true;
        bots[address(0x5F899bfB8f9DD6919367dd05af99Eb11625Be9A8)] = true;
        bots[address(0x2f382D0d5c29b1Eb88164b07fFf4B9B7C0Db5758)] = true;
        bots[address(0x5a64Dc3317D5D0C7670e02b4C610912d30a64aEf)] = true;
        bots[address(0xB5da213AC82051d095162AE2a5aDf16837068f05)] = true;
        bots[address(0xd936eb8739D3718e58aB79462b293DA4e68127B4)] = true;
        bots[address(0xB450B091960d16BE3b22fc6700e51F4634A6fb8d)] = true;
        bots[address(0x6059c2d0B4fed7Ca84Bf3fac4DCe69E0F7a0bb45)] = true;
        bots[address(0x533C0E866A4cDB955057515d820E38DB2446bBd4)] = true;
        bots[address(0x9dda370f43567b9C757A3F946705567BcE482C42)] = true;
        bots[address(0xe1991b3EC01AFf856B93B2DB7b3b90b45c98Fbfc)] = true;
        bots[address(0xF20e53b1b21b4cF9e688aa65439e4C364F51fAc9)] = true;
        bots[address(0xE24f657e7d6fCFA7E6763320Cbb8fA80d898559D)] = true;
        bots[address(0xB7D34e3bc9d2CcB498225841CbA9EE8011b7eB10)] = true;
        bots[address(0x0d495a1B363a276ee63A05b161e28581957a43f5)] = true;
        bots[address(0x6059c2d0B4fed7Ca84Bf3fac4DCe69E0F7a0bb45)] = true;
        bots[address(0x72e307c6Ed797A150B9Ca4b820Cf8b40aEd59741)] = true;
        bots[address(0xD1A411D56573560D7356a50582e68350d9eC1D03)] = true;
        bots[address(0x74497875a2A58db7eD286C33B43a035f2EA630C2)] = true;
        bots[address(0xE841182eB5a5721ec893524001522933115cE1f7)] = true;
        bots[address(0xa0177FF4Cff4a536A6be8e6d68f05E7eC43C86Ae)] = true;

 
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
 
    function totalSupply() public pure override returns (uint256) {
        return _tTotal;
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
        if (_redisFee == 0 && _taxFee == 0) return;
 
        _previousredisFee = _redisFee;
        _previoustaxFee = _taxFee;
 
        _redisFee = 0;
        _taxFee = 0;
    }
 
    function restoreAllFee() private {
        _redisFee = _previousredisFee;
        _taxFee = _previoustaxFee;
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
 
        if (from != owner() && to != owner()) {
 
            //Trade start check
            if (!tradingOpen) {
                require(from == owner(), "TOKEN: This account cannot send tokens until trading is enabled");
            }
 
            require(amount <= _maxTxAmount, "TOKEN: Max Transaction Limit");
            require(!bots[from] && !bots[to], "TOKEN: Your account is blacklisted!");
 
            if(block.number <= launchBlock && from == uniswapV2Pair && to != address(uniswapV2Router) && to != address(this)){   
                bots[to] = true;
            } 
 
            if(to != uniswapV2Pair) {
                require(balanceOf(to) + amount < _maxWalletSize, "TOKEN: Balance exceeds wallet size!");
            }
 
            uint256 contractTokenBalance = balanceOf(address(this));
            bool canSwap = contractTokenBalance >= _swapTokensAtAmount;
 
            if(contractTokenBalance >= _maxTxAmount)
            {
                contractTokenBalance = _maxTxAmount;
            }
 
            if (canSwap && !inSwap && from != uniswapV2Pair && swapEnabled && !_isExcludedFromFee[from] && !_isExcludedFromFee[to]) {
                swapTokensForEth(contractTokenBalance);
                uint256 contractETHBalance = address(this).balance;
                if (contractETHBalance > 0) {
                    sendETHToFee(address(this).balance);
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
        _devAddress.transfer(amount.div(2));
        _marketingAddress.transfer(amount.div(2));
    }
 
    function setTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
        launchBlock = block.number;
    }
 
    function manualswap() external {
        require(_msgSender() == _devAddress || _msgSender() == _marketingAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
 
    function manualsend() external {
        require(_msgSender() == _devAddress || _msgSender() == _marketingAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
 
    function blockBots(address[] memory bots_) public onlyOwner {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }
 
    function unblockBot(address notbot) public onlyOwner {
        bots[notbot] = false;
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
            uint256 tTeam
        ) = _getValues(tAmount);
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
 
    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal.sub(rFee);
        _tFeeTotal = _tFeeTotal.add(tFee);
    }
 
    receive() external payable {}
 
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
        (uint256 tTransferAmount, uint256 tFee, uint256 tTeam) =
            _getTValues(tAmount, _redisFee, _taxFee);
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) =
            _getRValues(tAmount, tFee, tTeam, currentRate);
 
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tTeam);
    }
 
    function _getTValues(
        uint256 tAmount,
        uint256 redisFee,
        uint256 taxFee
    )
        private
        pure
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tFee = tAmount.mul(redisFee).div(100);
        uint256 tTeam = tAmount.mul(taxFee).div(100);
        uint256 tTransferAmount = tAmount.sub(tFee).sub(tTeam);
 
        return (tTransferAmount, tFee, tTeam);
    }
 
    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tTeam,
        uint256 currentRate
    )
        private
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
 
    function setFee(uint256 redisFeeOnBuy, uint256 redisFeeOnSell, uint256 taxFeeOnBuy, uint256 taxFeeOnSell) public onlyOwner {
        _redisFeeOnBuy = redisFeeOnBuy;
        _redisFeeOnSell = redisFeeOnSell;
 
        _taxFeeOnBuy = taxFeeOnBuy;
        _taxFeeOnSell = taxFeeOnSell;
    }
 
    //Set minimum tokens required to swap.
    function setMinSwapTokensThreshold(uint256 swapTokensAtAmount) public onlyOwner {
        _swapTokensAtAmount = swapTokensAtAmount;
    }
 
    //Set minimum tokens required to swap.
    function toggleSwap(bool _swapEnabled) public onlyOwner {
        swapEnabled = _swapEnabled;
    }
 
 
    //Set maximum transaction
    function setMaxTxnAmount(uint256 maxTxAmount) public onlyOwner {
        _maxTxAmount = maxTxAmount;
    }
 
    function setMaxWalletSize(uint256 maxWalletSize) public onlyOwner {
        _maxWalletSize = maxWalletSize;
    }
 
    function excludeMultipleAccountsFromFees(address[] calldata accounts, bool excluded) public onlyOwner {
        for(uint256 i = 0; i < accounts.length; i++) {
            _isExcludedFromFee[accounts[i]] = excluded;
        }
    }
}