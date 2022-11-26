// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

contract ERC20Token {
    address private owner;
    string private name;
    string private symbol;
    uint private immutable MAX_SUPPLY;
    uint currentSupply = 0;

    mapping(address => uint) private balances;
    mapping(address => mapping(address => uint256)) private allowed;

    event tokenMinted(address _to, uint _amount);
    event tokenBurned(address _from, uint _amount);
    event Transfer(address _from, address _to, uint _amount);
    event Approval(address _from, address _spender, uint _amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call method");
        _;
    }

    modifier insufficientBalance(address _from, uint _amount) {
        require(balances[_from] >= _amount, "Insufficient balance");
        _;
    }

    constructor(string memory _name, string memory _symbol, uint _totalSupply) {
        name = _name;
        symbol = _symbol;
        owner = msg.sender;
        MAX_SUPPLY = _totalSupply;
    }

    /**
     * @dev Returns the name of the token.
     */
    function getName() public view returns (string memory) {
        return name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function getSymbol() public view returns (string memory) {
        return symbol;
    }

    function mintToken(address _to, uint _amount) public onlyOwner {
        require(_to != address(0), "ERC20: mint to the zero address");
        require(
            currentSupply + _amount <= MAX_SUPPLY,
            "Cannot mint more than total supply"
        );
        currentSupply += _amount;
        balances[_to] += _amount;
        emit tokenMinted(_to, _amount);
    }

    function burnToken(
        uint _amount
    ) public insufficientBalance(msg.sender, _amount) {
        currentSupply -= _amount;
        balances[msg.sender] -= _amount;
        emit tokenBurned(msg.sender, _amount);
    }

    function totalSupply() public view returns (uint256) {
        return MAX_SUPPLY;
    }

    function balanceOf(address _user) public view returns (uint) {
        require(
            _user != address(0),
            "ERC721: address zero is not a valid owner"
        );
        return balances[_user];
    }

    function allowance(
        address _owner,
        address _spender
    ) public view returns (uint) {
        return allowed[_owner][_spender];
    }

    function transfer(
        address _to,
        uint _amount
    ) public insufficientBalance(msg.sender, _amount) returns (bool) {
        require(_to != address(0), "ERC20: transfer to the zero address");
        balances[msg.sender] -= _amount;
        balances[_to] += _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function approve(
        address _spender,
        uint _oldAmount,
        uint _amount
    ) public returns (bool) {
        require(_spender != address(0), "ERC20: approve to the zero address");
        // Avoid attackers frontrun the transactions and double spend the allowance = oldAmount + amount. Ref: https://docs.google.com/document/d/1YLPtQxZu1UAvO9cZ1O2RPXBbT0mooh4DYKjA_jp-RLM/edit
        require(
            allowed[msg.sender][_spender] == _oldAmount,
            "Approval has been changed"
        );
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint _amount
    ) public insufficientBalance(_from, _amount) returns (bool) {
        require(_from != address(0), "ERC20: transfer from the zero address");
        require(_to != address(0), "ERC20: transfer to the zero address");

        require(allowed[_from][msg.sender] >= _amount);

        allowed[_from][msg.sender] -= _amount;
        balances[_from] -= _amount;
        balances[_to] += _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }
}