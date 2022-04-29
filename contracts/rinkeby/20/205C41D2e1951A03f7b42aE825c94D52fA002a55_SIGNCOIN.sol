/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IERC20 {

    event Transfer(address indexed from, address indexed to, uint256 amount);
    event Approval(address indexed owner, address indexed spender, uint256 amount);


    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
    function totalSupply() external view returns (uint256);
    function balanceOf(address owner) external view returns (uint256 balance);
    function transfer(address to, uint256 amount) external returns (bool success);  
    function approve(address spender, uint256 amount) external returns (bool success);
    function allowance(address owner, address spender) external view returns (uint256 remaining);
    function transferFrom(address from, address to, uint256 amount) external returns (bool success);
}

abstract contract ERC20 is IERC20 {
    string _name;
    string _symbol;
    uint256  _totalSupply;
    mapping(address=>uint) _balances;
    mapping(address=>mapping(address=>uint))_allowances;

    constructor(string memory name_, string memory symbol_){
        _name =name_;
        _symbol = symbol_;
    }

    function name() public override view returns (string memory){
        return _name;
    }

    function symbol() public override view returns (string memory){
        return _symbol;
    }

    function decimals() public override pure returns (uint8){
        return 18;
    }

    function totalSupply() public override view returns (uint256){
        return _totalSupply ;
    }

    function balanceOf(address owner) public override view returns (uint256 balance){
        return _balances[owner];
    }

    function transfer(address to, uint256 amount) public override returns (bool success){
        _transfer(msg.sender,to,amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool success){
        _approve(msg.sender, spender,amount);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint256 remaining){
        return _allowances[owner][spender];
    }

    function transferFrom(address from, address to, uint256 amount) public override returns (bool success){
        if (from != msg.sender) {
            uint allowanceAmount = _allowances[from][msg.sender];
            require(amount <= allowanceAmount,"transfer amount exceeds allowance");
            _approve(from,msg.sender,allowanceAmount - amount);
        }
        _transfer(from,to,amount);
        return true;
    }

    //== Private or Internal Function =======
    function _transfer(address from, address to, uint amount) internal {
        require(from != address(0),"transfer from zero address");
        require(to != address(0),"transfer to zero address");
        require(amount > _balances[from],"transfer amount exceeds balance");

        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from,to,amount);
    }

    function _approve(address owner, address spender, uint amount) internal{
        require(owner != address(0),"approve from zero address");
        require(spender != address(0),"spender from zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner,spender,amount);

    }

    function _mint(address to , uint amount) internal {
        require(to != address(0),"mint to zero address");
        _balances[to] += amount;
        _totalSupply +=amount;

        emit Transfer(address(0),to,amount);
    }

    function _brun(address from ,uint amount) internal{
        require(from != address(0),"brun  to zero address");
        require(amount <= _balances[from],"brun amount exceeds balance");
        _balances[from] -= amount;
        _totalSupply -= amount;

        emit Transfer(from,address(0),amount);

    }
}
contract SIGNCOIN is ERC20 {
    constructor() ERC20("SIGN COIN","SIG") {

    }

    function desposit() public payable{
        require(msg.value >0,"amount is zero");
        _mint(msg.sender,msg.value);

    }

    function withdraw(uint amount) public {
        require(amount > 0 &&amount <=  _balances[msg.sender],"withdraw amount exceeds balance ");
        payable(msg.sender).transfer(amount);
        _brun(msg.sender,amount);

    }
        
}