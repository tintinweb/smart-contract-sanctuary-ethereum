// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;

import "../contracts/ERC20.sol";
import "../contracts/ERC20Burnable.sol";
import "../contracts/Pausable.sol";


contract SwillToken is ERC20, ERC20Burnable, Pausable {
    constructor(address shop)  ERC20("SwillToken", "ST", 10, 20, shop) {}
}

contract SShop {
    IERC20 public token;
    address payable owner;

    constructor() {
        token = new SwillToken(address(this));
        owner = payable(msg.sender);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner");
        _;
    }

    function withdrawAll() external onlyOwner {
        uint balance = address(this).balance;
        require(balance > 0, "no enough funds.");

        owner.transfer(balance);
    }

    function tokenBalance() public view returns(uint) {
        return token.balanceOf(address(this));
    }

    function buy() external payable {
        uint tokensToBuy = msg.value;
        require(tokensToBuy > 0, "not enough funds, boy.");
        uint currentBalance = tokenBalance();
        require(currentBalance >= tokensToBuy, "not enough tokens!");
        token.transfer(msg.sender, tokensToBuy);
    }

    function sell(uint _amountToSell ) external {
        require(
            _amountToSell > 0 && token.balanceOf(msg.sender) >= _amountToSell,
            "Not enough tokens"
        );
        uint allowance = token.allowance(msg.sender, address(this));
        require(allowance >= _amountToSell, "Sorry. Check your allowance.");
        token.transferFrom(msg.sender, address(this), _amountToSell);
    }

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;



interface ICounter {
    function count() external view returns (uint);

    function increment() external;
    event Transfer(address indexed from, address indexed to, uint amount);
    event Approve(address indexed owner, address indexed to, uint amount);
}

 interface IERC20 {

    function name() external view returns(string memory);
    function symbol() external view returns(string memory);

    function decimals() external pure returns(uint); // 0

    function totalSupply() external view returns(uint);

    function balanceOf(address account) external view returns(uint);

    function transfer(address to, uint amount) external;

    function allowance(address owner, address spender) external view returns(uint);

    function approve(address spender, uint amount) external;

    function transferFrom(address sender, address recipient, uint amount) external;

    event Transfer(address indexed from, address indexed to, uint amount);
    event Approve(address indexed owner, address indexed to, uint amount);
}

abstract contract ERC20 is IERC20 {
    uint totalTokens;
    address owner;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowances;
    string _name = "MCS Token";
    string _symbol = "MCT";
    uint private _cap;

    function _beforeTokenTransfer(address from, address to, uint amount) internal virtual {}

    function name() public override view returns(string memory) {
        return _name;
    }

    function symbol() public override view returns(string memory) {
        return _symbol;
    }

    modifier enoughTokens(address _from, uint _amount) {
        require(balanceOf(_from) >= _amount, "Not enough tokens!");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not an owner!");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint initialSupply, uint cap_, address _shop) {
        require( cap_ > 0, "ERC20Capped: cap is 0");
        _name= name_;
        _symbol = symbol_;
        owner = msg.sender;
        _cap = cap_;
        mint(initialSupply, _shop);
    }


    function cap() public view returns (uint) {
        return _cap;
    }

    function decimals() public override pure returns(uint) {
        return 18;
    }

    function totalSupply() public override view returns(uint) {
        return totalTokens;
    }

    function balanceOf(address account) public override view returns(uint) {
        return balances[account];
    }

    function transfer(address to, uint amount) external override enoughTokens(msg.sender, amount) {
        _beforeTokenTransfer(msg.sender, to, amount);
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function allowance(address _owner, address spender) public override view returns(uint) {
        return allowances[_owner][spender];
    }

    function approve(address spender, uint amount) public override {
       _approve(msg.sender, spender, amount);
    }

    function _approve(address sender, address spender, uint amount) internal {
       allowances[sender][spender] = amount;
       emit Approve(sender, spender, amount);
    }

    function transferFrom(address sender, address recipient, uint amount) public override enoughTokens(sender, amount) {
        _beforeTokenTransfer(msg.sender, recipient, amount);
        allowances[sender][recipient] -= amount; // overflow
        balances[sender] -= amount;
        balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
    }

    function mint(uint amount, address shop) public onlyOwner {
        _beforeTokenTransfer(address(0), msg.sender, amount);
        require(totalSupply() + amount <= cap(), "ERC20Capped: can exceeded");
        balances[shop] += amount;
        totalTokens += amount;
        emit Transfer(address(0), msg.sender, amount);
    }

    function _burn(address _from, uint amount) public onlyOwner enoughTokens(msg.sender, amount) {
        _beforeTokenTransfer(_from, address(0), amount);
        balances[_from] -= amount;
        totalTokens -= amount;
    }

    fallback() external payable {

    }

    receive() external payable {
        
    }



}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../contracts/ERC20.sol";

abstract contract ERC20Burnable is ERC20 {

    function burn(uint256 amount) public virtual {
        _burn(msg.sender, amount);
    }

    
    function burnFrom(address account, uint256 amount) public virtual {
        uint currentAllowance = allowance(account, msg.sender);
        require(currentAllowance >= amount, "ERC20 err");
        unchecked {
            _approve(account, msg.sender, currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.2;


abstract contract Pausable {
   
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
        emit Paused(msg.sender);
    }

    
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}