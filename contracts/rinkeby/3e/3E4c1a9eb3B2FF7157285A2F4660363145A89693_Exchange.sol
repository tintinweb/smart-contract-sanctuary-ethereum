// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Token.sol";
contract Exchange {
    Token token;
    address public tokenAddress;
    constructor(address _token) payable{

        tokenAddress = _token;
        token = Token(address(tokenAddress));
    }
    function buy() payable public {
        uint256 amountTobuy = msg.value;
        uint256 dexBalance = token.balanceOf(address(this));
        require(amountTobuy > 0, "You need to send some Ether");
        require(amountTobuy <= dexBalance, "Not enough tokens in the reserve");
        token.transfer(msg.sender, amountTobuy);
    }
    function sell(uint256 amount) public {
        require(amount > 0, "You need to sell at least some tokens");
        uint256 approvedAmt = token.allowance(msg.sender, address(this));
        require(approvedAmt >= amount, "Check the token allowance");
        token.transferFrom(msg.sender, payable(address(this)), amount);
        payable(msg.sender).transfer(amount);
    }
}

pragma solidity ^0.8.0;
contract Token {
    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    string name_;
    string symbol_;
    uint256 totalSupply_;
    constructor(string memory _name, string memory _symbol, uint256 _total) {
        name_ = _name;
        symbol_ = _symbol;
        totalSupply_ = _total;
        balances[msg.sender] = totalSupply_;
    }

    function name() public view returns (string memory) {
        return name_;
    }
    function symbol() public view returns (string memory) {
        return symbol_;
    }
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }
    function balanceOf(address tokenOwner) public view returns (uint) {
        return balances[tokenOwner];
    }
    function decimals() public pure returns(uint8) {
        return 18;
    }
    function transfer(address _receiver, uint _amount) public returns (bool) {
        require(_amount <= balances[msg.sender]);
        balances[msg.sender] -= _amount;
        balances[_receiver] += _amount;
        return true;
    }
    function approve(address _delegate, uint _amount) public returns (bool) {
        allowed[msg.sender][_delegate] = _amount;
        return true;
    }
    function allowance(address _owner, address _delegate) public view returns (uint) {
        return allowed[_owner][_delegate];
    }
    function transferFrom(address _owner, address _receiver, uint _amount) public returns (bool) {
        require(_amount <= balances[_owner]);
        require(_amount <= allowed[_owner][msg.sender]);
        balances[_owner] -= _amount;
        allowed[_owner][msg.sender] -= _amount;
        balances[_receiver] += _amount;
        return true;
    }
}