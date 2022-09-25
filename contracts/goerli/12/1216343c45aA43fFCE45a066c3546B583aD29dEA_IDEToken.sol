////SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);

    function allowance(address owner, address spender) external view returns (uint256);
    function transfer(address recipient, uint amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

contract IDEToken is IERC20 {
    
    string public constant name = "ERC20Basic";
    string public constant symbol = "IDE";
    uint8 public constant decimals = 18;


    mapping(address => uint256) balances;
    mapping(address => mapping (address => uint256)) allowed;
    uint256 _totalSupply = 10000000;

    constructor () {
        balances[msg.sender] = _totalSupply;
    }

    function totalSupply() public override view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address OwnerOfToken) public override view returns (uint256) {
        return balances[OwnerOfToken];
    }

    function transfer(address to, uint256 amountOfTokens) public override returns (bool) {
        require(balances[msg.sender] >= amountOfTokens);
        balances[msg.sender] -= amountOfTokens;
        balances[to] += amountOfTokens;

        emit Transfer(msg.sender, to, amountOfTokens);
        return true;
    }

    function approve(address spender, uint256 numberOfTokens) public override returns (bool) {
        allowed[msg.sender][spender] = numberOfTokens;
        emit Approval(msg.sender, spender, numberOfTokens);
        return true;
    }

    function allowance(address owner, address spender) public override view returns (uint) {
        return allowed[owner][spender];
    }

    function transferFrom(address owner, address buyer, uint256 numberOfTokens ) public override returns (bool) {
        require(numberOfTokens <= balances[owner]);
        require(numberOfTokens <= allowed[owner][msg.sender]);

        balances[owner] -= numberOfTokens;
        allowed[owner][msg.sender] = allowed[owner][msg.sender] - numberOfTokens;
        balances[buyer] += numberOfTokens;
        emit Transfer(owner, buyer, numberOfTokens);
        return true;

    }

}