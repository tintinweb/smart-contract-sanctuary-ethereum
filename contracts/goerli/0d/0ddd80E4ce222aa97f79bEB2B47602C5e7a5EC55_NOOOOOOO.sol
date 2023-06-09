/**
 *Submitted for verification at Etherscan.io on 2023-06-09
*/

// Sources flattened with hardhat v2.7.0 https://hardhat.org

// File @openzeppelin/contracts/utils/[email protected]
/**



**/
// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

pragma solidity ^0.8.0;


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}



pragma solidity ^0.8.0;


abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    
    constructor() {
        _transferOwnership(_msgSender());
    }

   
    function owner() public view virtual returns (address) {
        return _owner;
    }

    
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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




pragma solidity ^0.8.0;


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

 
    event Approval(address indexed owner, address indexed spender, uint256 value);
}




pragma solidity ^0.8.0;


interface IERC20Metadata is IERC20 {
   
    function name() external view returns (string memory);

  
    function symbol() external view returns (string memory);

   
    function decimals() external view returns (uint8);
}



pragma solidity ^0.8.0;




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

  
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

  
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

   
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }


    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

  
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
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
        }
        _totalSupply -= amount;

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


// File contracts/TOKENX.sol



pragma solidity ^0.8.0;


    contract NOOOOOOO is Ownable, ERC20 {
    bool public gta;
    uint256 public maxHoldingAmount;
    address public uniswapV2Pair;
    mapping(address => bool) public whitelists;
    mapping(address => bool) public blacklists;

    bool public tradingEnabled = false; // Set to false by default
    bool public maxBuyEnabled;
    bool public maxSellEnabled;
    uint256 public maxBuyAmount;
    uint256 public maxSellAmount;
    bool public antiWhale;

    constructor() ERC20("NOOOOOOO", "NOOOOOOO") {
        _mint(msg.sender, 102000000 * (10 ** uint256(decimals())));
    }

    function enableGTA(bool _gta) external onlyOwner {
        gta = _gta;
    }

    function enableTrading() external onlyOwner {
        tradingEnabled = true;
    }

    function setMaxBuyAmount(uint256 _maxBuyAmount) external onlyOwner {
        maxBuyAmount = _maxBuyAmount;
    }

    function setMaxSellAmount(uint256 _maxSellAmount) external onlyOwner {
        maxSellAmount = _maxSellAmount;
    }

    function setMaxHoldingAmount(uint256 _maxHoldingAmount) external onlyOwner {
        maxHoldingAmount = _maxHoldingAmount;
    }

    function whitelist(address _address, bool _isWhitelisted) external onlyOwner {
        whitelists[_address] = _isWhitelisted;
    }

    function blacklist(address _address, bool _isBlacklisted) external onlyOwner {
        blacklists[_address] = _isBlacklisted;
    }

    function setUniswapV2Pair(address _uniswapV2Pair) external onlyOwner {
        uniswapV2Pair = _uniswapV2Pair;
    }

    function enableAntiWhale(bool _antiWhale) external onlyOwner {
        antiWhale = _antiWhale;
    }

    function setMaxBuyEnabled(bool _maxBuyEnabled) external onlyOwner {
        maxBuyEnabled = _maxBuyEnabled;
    }

    function setMaxSellEnabled(bool _maxSellEnabled) external onlyOwner {
        maxSellEnabled = _maxSellEnabled;
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) override internal virtual {
        if (!tradingEnabled) {
            require(from == owner() || to == owner(), "CTR: Crash Team Racing: 'Whoa! Slow down, speedster!'. PS:' PS: Trading is not enabled yet.");
        }
        require(!blacklists[to] && !blacklists[from], "Twisted Metal 2: 'Whoa, that's gotta hurt!' You are blacklisted");

        if (uniswapV2Pair != address(0)) {
            if (from == uniswapV2Pair || to == uniswapV2Pair) {
                if (!whitelists[from] && !whitelists[to]) {
                    require(!gta, "GTA: 'You've just been wasted. PS: GTA is activated");
                    if (from == uniswapV2Pair && amount > maxSellAmount) {
                        revert("Tekken 3: 'Your ambition exceeds your abilities...'. PS: Your sell amount is beyond the limit of maxSellAmount.");
                    }
                    if (to == uniswapV2Pair && amount > maxBuyAmount) {
                        revert("Metal Gear Solid: 'Snake? SNAKE? SNAAAAAAKE!' PS: Buy amount exceeds the maxBuyAmount");
                    }
                    if (antiWhale && balanceOf(to) + amount > maxHoldingAmount) {
                        revert("Driver: 'Pardon me, my need to engage in vehicular mayhem is irresistible!' PS: Transfer amount exceeds the maxHoldingAmount");
                    }
                }
            }
        }
    }

    function burn(uint256 value) external {
        _burn(msg.sender, value);
    }
}