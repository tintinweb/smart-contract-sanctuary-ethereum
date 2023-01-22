/**
 *Submitted for verification at Etherscan.io on 2023-01-22
*/

/*
   ____     __   ___    _ ,---.    ,---.,---.    ,---..-./`) .--.   .--.      ,-----.   .-./`) ,---.   .--. 
   \   \   /  /.'   |  | ||    \  /    ||    \  /    |\ .-.')|  | _/  /     .'  .-,  '. \ .-.')|    \  |  | 
    \  _. /  ' |   .'  | ||  ,  \/  ,  ||  ,  \/  ,  |/ `-' \| (`' ) /     / ,-.|  \ _ \/ `-' \|  ,  \ |  | 
     _( )_ .'  .'  '_  | ||  |\_   /|  ||  |\_   /|  | `-'`"`|(_ ()_)     ;  \  '_ /  | :`-'`"`|  |\_ \|  | 
 ___(_ o _)'   '   ( \.-.||  _( )_/ |  ||  _( )_/ |  | .---. | (_,_)   __ |  _`,/ \ _/  |.---. |  _( )_\  | 
|   |(_,_)'    ' (`. _` /|| (_ o _) |  || (_ o _) |  | |   | |  |\ \  |  |: (  '\_/ \   ;|   | | (_ o _)  | 
|   `-'  /     | (_ (_) _)|  (_,_)  |  ||  (_,_)  |  | |   | |  | \ `'   / \ `"/  \  ) / |   | |  (_,_)\  | 
 \      /       \ /  . \ /|  |      |  ||  |      |  | |   | |  |  \    /   '. \_/``".'  |   | |  |    |  | 
  `-..-'         ``-'`-'' '--'      '--''--'      '--' '---' `--'   `'-'      '-----'    '---' '--'    '--' 

                                        this one a coin for yumi frens
                                        yummi love u!!!
*/

pragma solidity ^0.8.0;
interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);}
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;}
    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;}}
interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);}
contract YUMMIKOIN is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    address yummi;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        yummi = msg.sender;}
    function name() public view virtual override returns (string memory) {
        return _name;}
    function symbol() public view virtual override returns (string memory) {
        return _symbol;}
    function decimals() public view virtual override returns (uint8) {
        return 0;}
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;}
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];}
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        require(msg.sender == yummi, "yummi said: u did a sili!!!");
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;}
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];}
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;}
    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        require(msg.sender == yummi, "yummi said: u did a sili!!!");
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;}
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;}
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "yummi said: u did a sili!!!");
        unchecked {_approve(owner, spender, currentAllowance - subtractedValue);}
        return true;}
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(msg.sender == yummi, "yummi said: u did a sili!!!");
        uint256 fromBalance = _balances[from];
        unchecked {
            _balances[from] = fromBalance - amount;
            _balances[to] += amount;}
        emit Transfer(from, to, amount);}
    function mint(address account, uint256 amount) public virtual {
        require(msg.sender == yummi, "yummi said: u did a sili!!!");
        _totalSupply += amount;
        unchecked {_balances[account] += amount;}
        emit Transfer(address(0), account, amount);}
    function burn(address account, uint256 amount) public virtual {
        require(msg.sender == yummi, "yummi said: u did a sili!!!");
        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "yummi said: u did a sili!!!");
        unchecked {
            _balances[account] = accountBalance - amount;
            _totalSupply -= amount;}
        emit Transfer(account, address(0), amount);}
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "yummi said: u did a sili!!!");
        require(spender != address(0), "yummi said: u did a sili!!!");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);}
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "yummi said: u did a sili!!!");
            unchecked {_approve(owner, spender, currentAllowance - amount);}}}
}