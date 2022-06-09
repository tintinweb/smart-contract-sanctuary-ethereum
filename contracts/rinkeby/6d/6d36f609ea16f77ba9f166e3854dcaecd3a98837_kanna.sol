/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.7;


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


abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


abstract contract Pausable is Context {
   
    event Paused(address account);

  
    event Unpaused(address account);

    bool private _paused;

    
    constructor() {
        _paused = false;
    }

   
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    
    
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    
    
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

   
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

   
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}


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

   
    function transferOwnership(address newOwner) external virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

   
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}


abstract contract ReentrancyGuard {
    
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

   
    modifier nonReentrant() {
        
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        _status = _ENTERED;

        _;

       
        _status = _NOT_ENTERED;
    }
}

contract ERC20 is Context, IERC20, Pausable, Ownable, ReentrancyGuard {

    mapping (address => uint256) private _balances;

    mapping (address => mapping (address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;
    uint8 private _decimals;

    event ExternalTokenTransfered(address indexed contractAddress, address from, uint256 value);

    constructor (string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }

    function name() external view virtual returns (string memory) {
        return _name;
    }

  
    function symbol() external view virtual returns (string memory) {
        return _symbol;
    }

   
    function decimals() external view virtual returns (uint8) {
        return _decimals;
    }

    function totalSupply() external view virtual override returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address account) external view virtual override returns (uint256) {
        return _balances[account];
    }

    
    function transfer(address recipient, uint256 amount) external virtual override whenNotPaused returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

   
    function allowance(address owner, address spender) external view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

   
    function approve(address spender, uint256 amount) external virtual override whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

   
    function transferFrom(address sender, address recipient, uint256 amount) external virtual override whenNotPaused returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

   
    function increaseAllowance(address spender, uint256 addedValue) public virtual whenNotPaused returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

 
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual whenNotPaused returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    
    function mint(uint256 amount) external onlyOwner whenNotPaused returns(bool) {
        _mint(msg.sender, amount);
        return true;
    }

    
    function burn(uint256 amount) external onlyOwner whenNotPaused returns(bool) {
        _burn(msg.sender, amount);
        return true;
    }

    
    function destroy(address ethReceiver) external onlyOwner whenNotPaused{
        selfdestruct(payable(ethReceiver));
    }

   
    function tokenRecover(address contractAddress, uint256 amount) external onlyOwner whenNotPaused nonReentrant {
        require(contractAddress != address(0), "ERC20: Address cant be zero address");

        IERC20(contractAddress).transfer(msg.sender, amount);
        emit ExternalTokenTransfered(contractAddress, msg.sender, amount);
    }

    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        _beforeTokenTransfer(amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }

   
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");
        _beforeTokenTransfer(amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");
        _beforeTokenTransfer(amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }
    
    
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function pauseContract() external virtual onlyOwner {
        _pause();
    }
    
    
    function unPauseContract() external virtual onlyOwner {
        _unpause();
    }

    
    function _beforeTokenTransfer(uint256 amount) internal virtual { 
        require(amount != 0, "ERC20: amount cant be zero or negative values");
    }
}

contract kanna is ERC20
{

    constructor () ERC20("kanna", "P", 18) {
        _mint(msg.sender, 1000000000 * 10 ** 18);
    }
}