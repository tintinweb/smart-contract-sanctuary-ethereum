/**
 *Submitted for verification at Etherscan.io on 2022-11-20
*/

pragma solidity ^0.8.17;

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function approval(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

contract ERC20 is IERC20 {
    uint256 _totalSupply;
    mapping(address => uint256) _balance;
    mapping(address => mapping(address => uint256)) _allowance;
    string _name;
    string _symbol;
    address owner;

    modifier onlyOwner() {
        require(msg.sender == owner, "ERROR : Only Owner can access this function");
        _;
    }

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;

        _totalSupply = 100000;
        _balance[msg.sender] = 100000;
    }

    function mint(address account, uint256 amount) public onlyOwner {
        require(account != address(0x0), "ERROR : mint to address 0");
        _totalSupply += amount;
        _balance[account] += amount;
        emit Transfer(address(0), account, amount);
    }

    function burn(address account, uint256 amount) public onlyOwner {
        require(account != address(0x0), "ERROR : burn from address 0");
        
        uint256 accountBalance = _balance[account];
        require(accountBalance >= amount, "ERROR : no more token to brun");

        _totalSupply -= amount;
        _balance[account] -= amount;
        emit Transfer(account, address(0), amount);
    }

    function name() public view returns (string memory) {
        return _name;
    }
    function symbol() public view returns (string memory) {
        return _symbol;
    }
    function deciamls() public view returns (uint8) {
        return 18;
    }
    
     //內部使用的授權
    function _approval(address owner, address spender, uint256 amount) internal {
        _allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    //內部使用的轉帳
    function _transfer(address from, address to, uint256 amount) internal {
        uint256 myBalance =  _balance[from];

        //檢查餘額
        require (myBalance >= amount, "No money to transfer");
        require (to != address(0x0), "Transfer to address 0");

        //轉帳
        _balance[from] -= amount;
        _balance[to] += amount;

        emit Transfer(from, to, amount);
    }


    function totalSupply() external view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address account) public view returns (uint256) {
        return _balance[account];
    }

    function allowance(address owner, address spender) public view returns (uint256){
        return _allowance[owner][spender];
    }

    function approval(address spender, uint256 amount) public returns (bool){
        _approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool){

        //檢查授權的額度
        uint256 myAllowance = _allowance[from][msg.sender];
        require(myAllowance >= amount, "Error : No allowance to transfer");

        _approval(from, msg.sender, myAllowance - amount);
        _transfer(from, to, amount);

        return true;
    }

}