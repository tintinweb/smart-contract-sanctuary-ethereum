// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./TurToken.sol";

contract TShop {
    IERC20 public token;
    address payable public owner;
    event Bought(uint _amount, address _buyer);
    event Sold(uint _amount, address _seller);

    constructor (){
        token = new TurToken(address(this));
        owner = payable(msg.sender);
    }

    uint public decimal;

    function ddd() public {
        decimal = token.decimals();
    }
    


    modifier onlyOwner(){
        require(msg.sender == owner, "You are not the owner!");
        _;
    }

    function sell(uint _amountToSell) external {   //don't need 'payable' as we don't receive money
        require(
            _amountToSell > 0 && 
            token.balanceOf(msg.sender) >= _amountToSell,
            "Incorrect amount!"
        );

        uint allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amountToSell, "chcek allownace");

        token.transferFrom(msg.sender, address(this), _amountToSell);
        emit Sold(_amountToSell, msg.sender);

        payable(msg.sender).transfer(_amountToSell);    //check other way!
        //transfer
        //call
        //send  address.send()
    }

    receive() external payable{
        uint tokensToBuy = msg.value; // 1 wei = 1 token
        require(tokensToBuy > 0, "Not enough funds!!!");
        require(tokenBalance() >= tokensToBuy, "not enough tokens!");
        token.transfer(msg.sender, tokensToBuy);
        emit Bought(tokensToBuy, msg.sender);
    }

    function tokenBalance() public view returns(uint){
        return token.balanceOf(address(this));
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Erc.sol";

contract TurToken is ERC20{
    constructor(address shop) ERC20("Turtoken", "TUR", 30, shop){}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IERC20.sol";

contract ERC20 is IERC20 {
    uint totalTokens;
    address owner;
    mapping (address => uint) public balances;
    mapping (address => mapping(address => uint)) public allowances;

    string _name;
    string _symbol;

     constructor(string memory name_,string memory symbol_,uint initialSupply,address shop) {
        _name = name_;
        _symbol = symbol_;
        owner = msg.sender;
        mint(initialSupply, shop);
    }

    function name() external view returns(string memory){
        return _name;
    }

    function symbol() external view returns(string memory){
        return _symbol;
    }

    function decimals() external pure returns(uint){
        return 18; // 1 token = 1 wei
    }

    function totalSupply() public view returns(uint){
        return totalTokens;
    }

    function balanceOf(address account) public view returns(uint){
        return balances[account];
    }

    function transfer(address to, uint amount) external enoughTokens(msg.sender, amount){
        _beforeTokenTransfer(msg.sender, to, amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }


    modifier enoughTokens(address _from, uint _amount) {
        require(balanceOf(_from) >= _amount, "not enough funds, baby");
        _;
    } 

    modifier onlyOwner() {
        require(msg.sender == owner, "You are not the owner");
        _;
    }

   

    function mint(uint amount, address shop) public onlyOwner {
        _beforeTokenTransfer(address(0), shop, amount);
        balances[shop] += amount;
        totalTokens += amount;
        emit Transfer(address(0), shop, amount);
    }

    function burn(address _from, uint amount) public onlyOwner enoughTokens(msg.sender, amount){
        _beforeTokenTransfer(_from, address(0), amount);
        balances[_from] -= amount;
        totalTokens -= amount;
    }

    function _beforeTokenTransfer (     //Used in Openzeppelin. 
        address from, 
        address to,
        uint amount) internal virtual {}


    function allowance(address _owner, address spender) public view returns(uint){
        return allowances[_owner][spender];
    }

    function approve(address spender, uint amount) public {
        _approve(msg.sender, spender, amount);
    }

     function _approve(address sender, address spender, uint amount) internal virtual {
        allowances[sender][spender] = amount;
        emit Approve(sender, spender, amount); 
    }

    function transferFrom(address sender, address receipient, uint amount) external enoughTokens(sender, amount){
        _beforeTokenTransfer(sender, receipient, amount);
        // require(allowances[sender][receipient] >= amount. "don't have allowance");
        allowances[sender][receipient] -= amount;

        balances[sender]-= amount;
        balances[receipient] += amount;
        emit Transfer(sender, receipient, amount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {
    function name() external view returns(string memory);
    function symbol() external view returns(string memory);
    function decimals() external pure returns(uint);
    function totalSupply() external view returns(uint);
    function balanceOf(address account) external view returns(uint);

    function transfer(address to,uint amount) external;  //from initiator's wallet to other's wallet

    function approve(address spender, uint amount) external; 
    function allowance(address _owner, address spender) external returns(uint);

    function transferFrom(address sender, address receipient, uint amount) external;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approve(address indexed from, address indexed to, uint amount); 
    
}