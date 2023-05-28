/**
 *Submitted for verification at Etherscan.io on 2023-05-28
*/

/**
  ______ _      ____  _   _ 
 |  ____| |    / __ \| \ | |
 | |__  | |   | |  | |  \| |
 |  __| | |   | |  | | . ` |
 | |____| |___| |__| | |\  |
 |______|______\____/|_| \_|
 |  \/  | |  | |/ ____| |/ /
 | \  / | |  | | (___ | ' / 
 | |\/| | |  | |\___ \|  <  
 | |  | | |__| |____) | . \ 
 |_|_ |_|\____/|_____/|_|\_\
 |__ \ / _ \__ \| || |      
    ) | | | | ) | || |_     
   / /| | | |/ /|__   _|    
  / /_| |_| / /_   | |      
 |____|\___/____|  |_|      
                            
https://t.me/VoteElonMusk
http://vote-elonmusk.online

*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

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
        _transferOwnership(_msgSender());
    }

    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

interface IERC20Metadata is IERC20 {

    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
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

    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

interface IFactory{
        function createPair(address tokenA, address tokenB) external returns (address pair);
}

interface IRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline) external;
}


library Address{
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
}

contract ElonMusk is ERC20, Ownable{
    using Address for address payable;
        
    mapping (address user => bool status) public isExcludedFromFees;
    mapping (address user => bool status) public isBlacklisted;
    mapping (address user => uint256 timestamp) public lastTrade;
    
    IRouter public router;
    address public pair;
    address public marketingWallet = 0x8d012DcFDb0822F673e68e809da6F2Bf9B23B187;

    bool private swapping;
    bool public swapEnabled;
    bool public tradingEnabled;
    
    uint256 public swapThreshold = 75000 * 10**9;
    uint256 public maxWallet = 1000000 * 10**9;
    uint256 public maxTx = 1000000 * 10**9;
    uint256 public delay;
    
    struct Taxes {
        uint256 buy;
        uint256 sell;
        uint256 transfer;
    }

    Taxes public taxes = Taxes(25,25,25);

    modifier mutexLock() {
        if (!swapping) {
            swapping = true;
            _;
            swapping = false;
        }
    }
  
    constructor(address _router) ERC20("President Elon Musk", "VOTE") {
        _mint(msg.sender, 50000000 * 10 ** 9);

        router = IRouter(_router);
        pair = IFactory(router.factory()).createPair(address(this), router.WETH());


        isExcludedFromFees[address(this)] = true;
        isExcludedFromFees[msg.sender] = true;
        isExcludedFromFees[marketingWallet] = true;

        _approve(address(this), address(router), type(uint256).max);
    }

    function decimals() public view virtual override returns (uint8) {
        return 9;
    }

    function _transfer(address sender, address recipient, uint256 amount) internal override {
        require(amount > 0, "Transfer amount must be greater than zero");

        if (swapping || isExcludedFromFees[sender] || isExcludedFromFees[recipient]) {
            super._transfer(sender, recipient, amount);
            return;
        }

        else{
            require(tradingEnabled, "Trading not enabled");
            require(!isBlacklisted[sender] && !isBlacklisted[recipient], "Blacklisted address");
            require(amount <= maxTx, "MaxTx limit exceeded");
            if(sender != pair) {
                require(lastTrade[sender] + delay <= block.timestamp, "WAIT PLEASE");
                lastTrade[sender] = block.timestamp;
            }
            if(recipient != pair){
                require(balanceOf(recipient) + amount <= maxWallet, "Wallet limit exceeded");
                require(lastTrade[recipient] + delay <= block.timestamp, "WAIT PLEASE");
                lastTrade[recipient] = block.timestamp;
            }
        }
        
        uint256 fees;

        if(recipient == pair) fees = amount * taxes.sell / 100;
        else if(sender == pair) fees = amount * taxes.buy / 100;
        else fees = amount * taxes.transfer / 100; 

        if (swapEnabled && sender != pair && !swapping) swapFees();

        super._transfer(sender, recipient, amount - fees);
        if(fees > 0){
            super._transfer(sender, address(this), fees);
        }
    }

    function swapFees() private mutexLock {
        uint256 contractBalance = balanceOf(address(this));
        if (contractBalance >= swapThreshold) {
            uint256 amountToSwap = swapThreshold;
            if(contractBalance >= maxTx) amountToSwap = maxTx;

            uint256 initialBalance = address(this).balance;
            swapTokensForEth(amountToSwap);
            uint256 deltaBalance = address(this).balance - initialBalance;
            payable(marketingWallet).sendValue(deltaBalance);
        }
    }

    function swapTokensForEth(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(tokenAmount, 0, path, address(this), block.timestamp);
    }

    function setSwapEnabled(bool status) external onlyOwner {
        swapEnabled = status;
    }

    function setSwapTreshhold(uint256 amount) external onlyOwner {
        swapThreshold = amount * 10**9;
    }
    
    function setTaxes(uint256 _buyTax, uint256 _sellTax, uint256 _transferTax) external onlyOwner {
        taxes = Taxes(_buyTax, _sellTax, _transferTax);
    }
    
    function setRouterAndPair(address newRouter, address newPair) external onlyOwner{
        router = IRouter(newRouter);
        pair = newPair;
        _approve(address(this), address(newRouter), type(uint256).max);
    }
    
    function frankenstein() external onlyOwner{
        tradingEnabled = true;
        swapEnabled = true;
        taxes.transfer = 50;
    }
 
    function removeLimits() external onlyOwner{
        maxTx = totalSupply();
        maxWallet = totalSupply();
        taxes.transfer = 0;
    }

    function setDelay(uint256 time) external onlyOwner{
        delay = time;
    }

    function setLimits(uint256 _maxTx, uint256 _maxWallet) external onlyOwner{
        maxTx = _maxTx * 10**9;
        maxWallet = _maxWallet * 10**9;
    }
    
    function setMarketingWallet(address newWallet) external onlyOwner{
        marketingWallet = newWallet;
    }

    function setIsExcludedFromFees(address _address, bool state) external onlyOwner {
        isExcludedFromFees[_address] = state;
    }
    
    function bulkIsExcludedFromFees(address[] memory accounts, bool state) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            isExcludedFromFees[accounts[i]] = state;
        }
    }

    function setBlacklist(address[] memory accounts, bool status) external onlyOwner{
        for(uint256 i = 0; i < accounts.length; i++){
            isBlacklisted[accounts[i]] = status;
        }
    }

    function rescueETH(uint256 weiAmount) external{
        payable(marketingWallet).sendValue(weiAmount);
    }
    
    function rescueERC20(address tokenAdd, uint256 amount) external{
        IERC20(tokenAdd).transfer(marketingWallet, amount);
    }

    // fallbacks
    receive() external payable {}

}