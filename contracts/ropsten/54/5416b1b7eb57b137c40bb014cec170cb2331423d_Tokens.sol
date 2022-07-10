/**
 *Submitted for verification at Etherscan.io on 2022-07-10
*/

pragma solidity ^0.8.7;


interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
}

contract Tokens is IERC20 {
    mapping (address => uint256) private _balances;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    address payable private _owner;

modifier onlyOwner(){

        require(msg.sender == _owner, "Only owner can call this function");
        _;
    }

    constructor (string memory name_, string memory symbol_, address payable owner_) {
        _name = name_;
        _symbol = symbol_;
        _owner = owner_;
    }

    function name() public view virtual returns (string memory) {
        return _name;
    }

    
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }

    function owner() public view virtual returns (address ) {
        return _owner;
    }
    
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    function transfer(address recipient, uint256 amount) onlyOwner public virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    }
   
    function _transfer(address sender, address recipient, uint256 amount) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        _balances[sender] = senderBalance - amount;
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);
    }
    
    function mint(uint256 amount) onlyOwner public virtual {

        _totalSupply += amount;
        _balances[_owner] += amount;
      
    }

    function burn(address recipient, uint amount) onlyOwner external {
        _balances[recipient] -= amount;
        _totalSupply -= amount;
        emit Transfer(msg.sender, address(0), amount);
    }
}