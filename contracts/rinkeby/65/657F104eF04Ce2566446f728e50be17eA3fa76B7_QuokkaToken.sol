//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract QuokkaToken {
    string public symbol = "QTN";
    string public name = "QuokkaToken";
    uint8 public decimals = 9;
    uint public existingTokens = 1000000000000000000;
    uint public IPOrate = 1000000;
    address public owner ;
 
    mapping(address => uint) private userBalance;
    mapping(address => mapping(address => uint)) private allowed;

    event Result (address, address, uint);
 
    constructor() {
        owner = msg.sender;
        userBalance[owner] = existingTokens;    
    }

    function totalSupply() public view returns (uint) {
        return userBalance[owner];
    }

    function balanceOf(address tokenOwner) public view returns (uint balance) {
        return userBalance[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view returns (uint tokens) {
        return allowed[tokenOwner][spender];
    }

    function transfer (address to, uint tokens) public {
        require(tokens <= userBalance[msg.sender], "Not enough tokens to transfer");
        userBalance[msg.sender] -= tokens;
        userBalance[to] += tokens;
        emit Result(msg.sender, to, tokens);
    }

    function approve(address spender, uint tokens) public {
        require(userBalance[msg.sender] >= tokens, "Not enough tokens to approve");
        allowed[msg.sender][spender] = tokens;
        emit Result(msg.sender, spender, tokens);
    }

    function transferFrom(address from, address to, uint tokens) public {
        require(allowed[from][to] >= tokens, "Not enough allowed tokens");
        allowed[from][to] -= tokens;
        userBalance[from] -= tokens;
        userBalance[to] += tokens;
        emit Result(from, to, tokens);
    }

    function buyToken() public payable {
        require(msg.value > 0, "You have to pay to buy QTN tokens");
        require(userBalance[owner] > 0, "No token left");
        allowed[owner][msg.sender] += currentQuokkaRate() * msg.value / 1000000000000000;
    }

    function burn(uint tokens) public {
        userBalance[msg.sender] -= tokens;
        existingTokens -= tokens;
        emit Result(msg.sender, msg.sender, tokens);
    }

    function mint(address to, uint tokens) external onlyOwner {
        userBalance[to] += tokens;
        existingTokens += tokens;
        emit Result(owner, to, tokens);
    }

    function currentQuokkaRate() public view returns (uint rate) {
       uint current = totalSupply() / IPOrate;
       if (current > IPOrate) {
           return current;
       } 
       return IPOrate;
    }

    function withdrawFee(address payable _receiver, uint amount) external onlyOwner {
        _receiver.transfer(amount);
    }

    function getContractBalance() public view returns (uint) {
       return address(this).balance;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "You`re not an owner!");
        _;
    }
}