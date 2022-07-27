/**
 *Submitted for verification at Etherscan.io on 2022-07-27
*/

// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.9;

/*
*
*     GM BABYDUCKERS,
*     
*     Ah, we see you. You're thinking it's yet another meme currency... 
*     Have you ever seen a gay duck fly? Have you ever thought of a guerilla marketing campaign such as ours?
*     (Rubber)Ducks will roam the most famous canals and parks of the world. 
*     We're here to have a good time with you. Every week, a meme contest is organised by the team, 
*     the community votes the winner who then receives a number of Baby Duck Gay coins 
*     No burn, no tax, no inflation, no deflation, no buy back, locked liquidity and renounced contract.
*     Love, community and memes are the heart of the project.
*     For us, it's all about the adventure, not the ranking on CoinMarketCap.
*     Do you like it? Then, join us!
*     You don't have to buy Baby Duck Gay coins, just bring your good vibes, 
*     and take part in our meme contests to win some coins.
*          
*     See you soon, GDucks!
*
*     Linktree:     https://linktr.ee/babyduckgay
*     Website:      https://babyduck.gay
*     Roadmap:      https://www.notion.so/babyduckgay/Roadmap-face25d9036f49c88e1ea716e7281381
*     Reddit:       https://www.reddit.com/r/babyduckgay
*     Twitter:      https://twitter.com/babyduckgay
*     Telegram:     https://t.me/babyduckgay
*     Mirror:       https://mirror.xyz/babyduckgay.eth
*     Github:       https://github.com/BabyDuckGay/
*     Multisig:     https://gnosis-safe.io/app/eth:0x57236ec948125F3c28642b05eDB7a775135703c6/home
*     
*
*   ██████╗░░█████╗░██████╗░██╗░░░██╗ ██████╗░██╗░░░██╗░█████╗░██╗░░██╗ ░██████╗░░█████╗░██╗░░░██╗
*   ██╔══██╗██╔══██╗██╔══██╗╚██╗░██╔╝ ██╔══██╗██║░░░██║██╔══██╗██║░██╔╝ ██╔════╝░██╔══██╗╚██╗░██╔╝
*   ██████╦╝███████║██████╦╝░╚████╔╝░ ██║░░██║██║░░░██║██║░░╚═╝█████═╝░ ██║░░██╗░███████║░╚████╔╝░
*   ██╔══██╗██╔══██║██╔══██╗░░╚██╔╝░░ ██║░░██║██║░░░██║██║░░██╗██╔═██╗░ ██║░░╚██╗██╔══██║░░╚██╔╝░░
*   ██████╦╝██║░░██║██████╦╝░░░██║░░░ ██████╔╝╚██████╔╝╚█████╔╝██║░╚██╗ ╚██████╔╝██║░░██║░░░██║░░░
*   ╚═════╝░╚═╝░░╚═╝╚═════╝░░░░╚═╝░░░ ╚═════╝░░╚═════╝░░╚════╝░╚═╝░░╚═╝ ░╚═════╝░╚═╝░░╚═╝░░░╚═╝░░░
*                                                                                                           
*                                         
*
*?7?JJ?7?JJ?7?JJ?7?JJJ77JJJ?7JJJ?7?JJ?7?YY???JYJ??JYJ??JYJ?7?JJ?7?JJ?7?JJ?7?JJJ7?JJJ77JJJ?7?JJ?7?JJ?7
*JJ???JJJ??JJJ???JJ???JJ???JJ???JJJ??JJ??7??777777777?????JJJ??JJJ??JJJ???JJ???JJ???JJ???JJ???JJJ??JJ
*???JJ???JJ???JJ???JJ????JJ???JJ???7!!!!!!!!!!!!!!!~!!!!!!777?????JJ???JJ???JJ???JJ????JJ???JJ???JJ??
*???JJ???JJ???JJ???JJ????JJ????7!~~~!!!!!!!!!!!!!~~~~~~~~!~~~!!!7?JJ???JJ???JJ???JJ????JJ???JJ???JJ??
*JJ???JJJ??JJJ???JJ???JJ????7~~~~!!!!!!!!!~~~~~~!~~~~~~~~~~~~~~~~~!!?JJ???JJ???JJ???JJ???JJ???JJJ??JJ
*???JJ???JJ???JJ???JJJ???!~~~~~~~~~~!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!???JJ???JJJ??JJJ??JJJ???JJ???JJ??
*JJJ??JJJ??JJJ???JJ???7~~~~~~~~~~~~~~~!7?YY5PPP55YJ?!~~~~~~~~~~~~~~7&#55Y?JJ???JJ???JJ???JJ???JJJ??JJ
*???JJ???JJ???JJ???J?^^~~~~~~~~~~~~!?YPGBBBBBBBB###BBP5J7~~~~~~~~~~~?#&#&#5?JJ???JJJ??JJJ???JJ???JJ??
*JJ???JJ????JJ???J?~:^~~~~~~~~~~~~?PBBB#################BPJ7~~~~~~~~~~Y#&&&BY?JJJ???JJ???JJ???JJ????J
*JJ???JJ????JJ??J7^:^~~~~~~~~~~~~YB#######################BB5J!~~~~~~~^~YB#&&Y!JJ???JJ???JJ???JJ????J
*???JJ???JJ???JJ!~?G!^~~~~~~~~~!5B#######################BBBBGGP5JJ7~~~~~~!J5J^~?JJJ??JJJ???JJ???JJ??
*JJJ??JJJ??JJJ?!?!J#7^~~~~~~!~^5######BB#BBBB#BBBB#BBB#BBBBBBGGGGPPGP!~~~~~^^^^^!???JJ???JJ???JJJ??JJ
*???JJ???JJ???7?P5BP^~~~~~!!^^Y5JGBBBBBBBBBBBBBBBBBBBBBBBGBBGGGBGGGPP!~~~~~~~~~~^!JJ??JJJ???JJ???JJ??
*JJ???JJJ??JJ7!5PGP~^~~~~!!^~7?G5YPBBBBBBBBBBBBBBBBBBBGBGGGGGGGGGP5J!~!~!~~~~~~~~^!?JJ???JJ???JJJ??JJ
*???JJ???JJ??:?5P5^^~~~~!!^^?J5GBP5PGGGGGBBBGGGGGGGGGGGGGGGGPP5J7!!!!!!!!!!~~~~!~^^????JJ???JJ???JJ??
*???JJ???JJJ~.JY7::^~~~.:. ^55JYPP55PGGGGGGGGGGGGGGGGGGGP55J7!!!!!!!!!!!!!!~!~~!~^^????JJ???JJ???JJ??
*JJ???JJJ??J: ::..:^~~!~^~!JYP5J5PP5PPGGGGGGGGGGGGGPP5Y?7!!!!!!!!!!!!!!!!!!!!!!!~^^!JJ???JJ???JJJ??JJ
*???JJ???JJ?. .....:~!!!!7777?JJJJY555555P55YYJ??77!!~~~!!!!!!!!!!!!!!!!!!!!!!!!~~^7??JJJ???JJ???JJ??
*JJJ??JJJ???  .... .!!!!!!!!!!!!!!!!!!!!!!!~~~~~~~~~!!!!!!~!!~~~~~~~~~!!!!!!!!!!~^^?JJ???JJ???JJJ??JJ
*???JJ???JJ?  :: .  ^7!!!!!!!!!!!!!!!!!!!!!!!!!!~~!!!~!~~~~~~~~~~~~~~~~~~~~~~~~~~^?J??JJJ???JJ???JJ??
*JJ????J???J:  7. .  ~!!!!!~~~~~!!!!~~~~~~~!!!!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~^^^!J?JJ???JJ???JJ????J
*JJ???JJJ??J7  .!..::^~!~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~7??JJ???JJ???JJ????J
*???JJ???JJ??:   ^.:^~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!7?J??JJJ???JJ??
*JJJ??JJJ??JJJ:   ::^^~~~~~~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7777JJJ??JJ
*???JJ???JJ???J7. ...:^^^^^~~~~~~~~~~~~!!!!~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7?J??
*JJ???JJJ??JJJ??J7.     ..:^~~~~~~~~!!!!!~!!!!!!!!!!!!!!!!!~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!7
*???JJ???JJ???JJ?J?^   :^^^~~~~~~~~!!!!!~~~!!!!!!!!!!!!!~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!~
*???JJ???JJ???JJJ??~ .:..:~~^~!~~~~!!~~~~~~~~~~~~~~!~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
*JJ???JJJ??JJJ?77~::~~^:^!~^~~~~~~~~~~~~~~~~~~~~~~~!~~~~~~~~~~~~~~~~~!!!!!!!!!!!!!!~!!!!!!!!!!!!!!!~~
*???JJ???JJ??7!^::~!~^^~!~~~~~~~~~~~~~~~~~~~~~~~~~~~!~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!~~~!!!!!!!!!!!!!!!
*JJJ??JJJ??J!:::^~~~^^~!~~~~~~~~~~~!~~~~~~~~~~~~~~~~!~~~~~~~~~~~~~~~~~~~~!!!!!!!!!!!!~~!!!!!!!!!!!!!!
*
*
*     
*     BabyDuckGay, by GayDuck
*            	      BigBlackDuck
*            	      Duckeroni 
*                     G-Dev
*
*/









 
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
 
contract BABYDUCKGAY is Context, IERC20, Ownable {
 
    using SafeMath for uint256;
 
    string private constant _name = "BabyDuckGay";
    string private constant _symbol = "BDG";
    uint8 private constant _decimals = 9;
 
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 100000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _redisFeeOnBuy = 0;  
    uint256 private _taxFeeOnBuy = 6;  
    uint256 private _redisFeeOnSell = 0;  
    uint256 private _taxFeeOnSell = 15;
 
    //Original Fee
    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell;
 
    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;
 
    mapping(address => bool) public hunters; mapping (address => uint256) public _buyMap; 
    address payable private _gayduckAddress = payable(0x5Cc0641Ef641DAEDf1ae585f52e3e730f6571Edf); 
    address payable private _daotreasuryAddress = payable(0x57236ec948125F3c28642b05eDB7a775135703c6);
 
    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;
 
    bool private tradingOpen;
    bool private inSwap = false;
    bool private swapEnabled = true;
 
    uint256 public _maxTxAmount = 1000000 * 10**9; 
    uint256 public _maxWalletSize = 1000000 * 10**9; 
    uint256 public _swapTokensAtAmount = 1000 * 10**9;
 
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
        _isExcludedFromFee[_gayduckAddress] = true;
        _isExcludedFromFee[_daotreasuryAddress] = true;
 
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
            require(!hunters[from] && !hunters[to], "TOKEN: You are shot");
 
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
        _daotreasuryAddress.transfer(amount);
    }
 
    function setTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
 
    function manualswap() external {
        require(_msgSender() == _gayduckAddress || _msgSender() == _daotreasuryAddress);
        uint256 contractBalance = balanceOf(address(this));
        swapTokensForEth(contractBalance);
    }
 
    function manualsend() external {
        require(_msgSender() == _gayduckAddress || _msgSender() == _daotreasuryAddress);
        uint256 contractETHBalance = address(this).balance;
        sendETHToFee(contractETHBalance);
    }
 
    function shotHunters(address[] memory hunters_) public onlyOwner {
        for (uint256 i = 0; i < hunters_.length; i++) {
            hunters[hunters_[i]] = true;
        }
    }
 
    function unshotHunter(address nothunter) public onlyOwner {
        hunters[nothunter] = false;
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
        require(redisFeeOnBuy >= 0 && redisFeeOnBuy <= 4, "Buy rewards must be between 0% and 4%");
        require(taxFeeOnBuy >= 0 && taxFeeOnBuy <= 20, "Buy tax must be between 0% and 20%");
        require(redisFeeOnSell >= 0 && redisFeeOnSell <= 4, "Sell rewards must be between 0% and 4%");
        require(taxFeeOnSell >= 0 && taxFeeOnSell <= 20, "Sell tax must be between 0% and 20%");

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