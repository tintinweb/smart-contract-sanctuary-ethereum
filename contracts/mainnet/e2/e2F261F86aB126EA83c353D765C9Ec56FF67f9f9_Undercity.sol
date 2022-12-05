/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

/**
 * SPDX-License-Identifier: MIT
 *
 * Tokenomics:
 *  Total Supply: 57,000,000
 *  Decimals: 18
 *  Token Name: Undercity
 *  Symbol: UND
 *  Taxes : 0%
 *
 */

 pragma solidity ^0.8.15;

 abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return (msg.sender);
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

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping (address => uint256) internal _balances;

    mapping (address => mapping (address => uint256)) internal _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor (string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
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

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        _balances[account] = accountBalance - amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal virtual { }
}

 /*
 * This contract is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;
    address private _previousOwner;
    uint256 private _lockTime;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor ()  {
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
interface IUniswapV2Factory {
    event PairCreated(address indexed token0, address indexed token1, address pair, uint);

    function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IUniswapV2Router02 {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
}

interface IUniswapV3Factory {

    event PoolCreated(address indexed token0, address indexed token1, uint24 indexed fee, int24 tickSpacing, address pool);

    function createPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);
    function getPool(address tokenA, address tokenB, uint24 fee) external returns (address pool);


}
library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}
contract Undercity is Context, Ownable, ERC20  {

    using Address for address payable;

    mapping (address => bool) private _isExcludedFromCooldown;
    /*
     whitelisted addresses will be able to send tokens before the trading is activated.
     This allows to manage the presale and to create the liquidity pools without any problem.
    */
    mapping (address => bool) private _isWhitelisted;
    bool private _isTradingEnabled = false;

    address constant private _DEAD = 0x000000000000000000000000000000000000dEaD;
    
    // CoolDown system
    mapping(address => uint256) private _lastTimeTx;
    bool public coolDownEnabled = true;
    uint32 public coolDownTime = 60 seconds;

    // Routers and Factories
    IUniswapV2Router02 constant private UNISWAPV2_ROUTER = IUniswapV2Router02(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    IUniswapV3Factory constant private UNISWAPV3_FACTORY = IUniswapV3Factory(0x1F98431c8aD98523631AE4a59f267346ea31F984);
    address constant private USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant private WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    // Any transfer to these addresses could be subject to some cooldown
    mapping (address => bool) private _automatedMarketMakerPairs;

    event ExcludeFromCooldown(address indexed account, bool isExcluded);

    event AddAutomatedMarketMakerPair(address indexed pair, bool indexed value);
   
    event Burn(uint256 amount);

    event CoolDownUpdated(bool state,uint32 timeInSeconds);

    event Whitelisted(address indexed account, bool isWhitelisted);

    event TradingEnabled();

    constructor() ERC20("Undercity", "UND") { 
        // Create supply
        _mint(owner(), 57_000_000 * 10**18);

         // Create V2 pairs
        IUniswapV2Factory uniswapV2Factory = IUniswapV2Factory(UNISWAPV2_ROUTER.factory());
        address uniswapV2ETHPair = uniswapV2Factory.createPair(address(this), UNISWAPV2_ROUTER.WETH());
        address uniswapV2USDTPair = uniswapV2Factory.createPair(address(this), USDT);
        _setAutomatedMarketMakerPair(uniswapV2ETHPair, true);
        _setAutomatedMarketMakerPair(uniswapV2USDTPair, true);

        // Create V3 pairs
        address uniswapV3ETHPair500 = UNISWAPV3_FACTORY.createPool(WETH,address(this),500);
        address uniswapV3ETHPair3000 = UNISWAPV3_FACTORY.createPool(WETH,address(this),3000);
        address uniswapV3ETHPair10000 = UNISWAPV3_FACTORY.createPool(WETH,address(this),10000);
        _setAutomatedMarketMakerPair(uniswapV3ETHPair500, true);
        _setAutomatedMarketMakerPair(uniswapV3ETHPair3000, true);
        _setAutomatedMarketMakerPair(uniswapV3ETHPair10000, true);

        address uniswapV3USDTPair3000 = UNISWAPV3_FACTORY.createPool(address(this),USDT,3000);
        _setAutomatedMarketMakerPair(uniswapV3USDTPair3000, true);

        excludeFromCooldown(owner(),true);
        excludeFromCooldown(address(this),true);

        // To avoid remove LP issues
        excludeFromCooldown(address(UNISWAPV2_ROUTER),true);
        excludeFromCooldown(address(0xC36442b4a4522E871399CD717aBDD847Ab11FE88),true);

        _isWhitelisted[owner()] = true;
    }


    function excludeFromCooldown(address account, bool excluded) public onlyOwner {
        require(_isExcludedFromCooldown[account] != excluded, "UND: Account has already the value of 'excluded'");
        _isExcludedFromCooldown[account] = excluded;

        emit ExcludeFromCooldown(account, excluded);
    }

    function setAutomatedMarketMakerPair(address pair, bool value) public onlyOwner {
        _setAutomatedMarketMakerPair(pair, value);
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(_automatedMarketMakerPairs[pair] != value, "UND: Automated market maker pair is already set to that value");
        _automatedMarketMakerPairs[pair] = value;

        emit AddAutomatedMarketMakerPair(pair, value);
    }

    function updateCooldown(bool state, uint32 timeInSeconds) external onlyOwner{
        require(timeInSeconds <= 600, "UND: The cooldown must be lower or equals to 600 seconds");
         coolDownTime = timeInSeconds * 1 seconds;
         coolDownEnabled = state;
         emit CoolDownUpdated(state,timeInSeconds);
    }

    function burn(uint256 amount) external returns (bool) {
        _transfer(_msgSender(), _DEAD, amount);
        emit Burn(amount);
        return true;
    }

    function whitelist(address account, bool value) external onlyOwner {
        require(_isWhitelisted[account] != value, "UND: Account is already set to that value");
        _isWhitelisted[account] = value;
        emit Whitelisted(account,value);
    }

    function enableTrading() external onlyOwner {
        require(!_isTradingEnabled, "UND: Trading is already enabled");
        _isTradingEnabled = true;
        emit TradingEnabled();
    }

    function _transfer(address from, address to, uint256 amount) internal override {
        require(from != address(0), "UND: Transfer from the zero address");
        require(to != address(0), "UND: Transfer to the zero address");
        require(amount >= 0, "UND: Transfer amount must be greater or equals to zero");

        // Only whitelisted addresses can send tokens before trading is enabled
            require(_isTradingEnabled || _isWhitelisted[from], "UND: You cannot send tokens before the trading is enabled");

        bool isBuyTransfer = _automatedMarketMakerPairs[from];

        if(coolDownEnabled && !isBuyTransfer && !_isExcludedFromCooldown[from]){
            uint256 timePassed = block.timestamp - _lastTimeTx[from];
            require(timePassed >= coolDownTime, "UND: The cooldown is not finished, please retry the transfer later");
        }
    
        // Buy
        if(isBuyTransfer && coolDownEnabled){
           _lastTimeTx[to] = block.timestamp;
        }
        super._transfer(from, to, amount);

    }

    // To distribute airdrops easily
    function batchTokensTransfer(address[] calldata _holders, uint256[] calldata _amounts) external onlyOwner {
        if(!_isTradingEnabled) {
            require(_isWhitelisted[owner()], "UND: You cannot send tokens before the trading is enabled");
        }
        require(_holders.length <= 200);
        require(_holders.length == _amounts.length);
            for (uint i = 0; i < _holders.length; i++) {
              if (_holders[i] != address(0)) {
                super._transfer(_msgSender(), _holders[i], _amounts[i]);
            }
        }
    }

    function withdrawStuckERC20Tokens(address token, address to) external onlyOwner {
        require(IERC20(token).balanceOf(address(this)) > 0, "UND: There are no tokens in the contract");
        require(IERC20(token).transfer(to, IERC20(token).balanceOf(address(this))));
    }

    function getCirculatingSupply() external view returns (uint256) {
        return totalSupply() - balanceOf(_DEAD) - balanceOf(address(0));
    }

    function isExcludedFromCooldown(address account) external view returns(bool) {
        return _isExcludedFromCooldown[account];
    }

    function isAutomatedMarketMakerPair(address account) external view returns(bool) {
        return _automatedMarketMakerPairs[account];
    }

    function isTradingEnabled() external view returns(bool) {
        return _isTradingEnabled;
    }



}