//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Erc20Token {


 // const erc20token = await Erc20Token.deploy("Pepelaz","PPLZ", 1000000000000000);
     uint256 private totalAmount = 1000000000000000;

    string private tokenName= "Pepelaz";

    string private tokenSymbol = "PPLZ";

    mapping(address => uint256) balances;   

    mapping(address => mapping (address => uint256)) allowed;

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    event Transfer(address indexed from, address indexed to, uint tokens);

    // constructor(string memory _name, string memory _symbol, uint256 _totalAmount) {
    //     tokenName = _name;
    //     tokenSymbol = _symbol;
    //     totalAmount = _totalAmount;
    // }

    function name() public view returns (string memory) {
        return tokenName;
    }

    function symbol() public view returns (string memory) {
        return tokenSymbol;
    }

    function decimals() public pure returns (uint8) {
        return 18;
    }

    function totalSupply() public view returns (uint256) {
        return totalAmount;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function transfer(address _to, uint256 _amount) public returns (bool) {
        require(_amount <= balances[msg.sender],"");
        balances[msg.sender] = balances[msg.sender] - _amount;
        balances[_to] = balances[_to] + _amount;
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    function approve(address _spender, uint256 _amount) public returns (bool) {
        allowed[msg.sender][_spender] = _amount;
        emit Approval(msg.sender, _spender, _amount);
        return true;
    }

    function transferFrom(address _from, address _to, uint _amount) public returns (bool) {
        require(_amount <= balances[_from],"");
        require(_amount <= allowed[_from][msg.sender],"");
        balances[_from] = balances[_from] - _amount;
        allowed[_from][msg.sender] = allowed[_from][msg.sender] - _amount;
        balances[_to] = balances[_to] + _amount;
        emit Transfer(_from, _to, _amount);
        return true;
    }

    function _mint(address _account, uint256 _amount) internal  {
        totalAmount += _amount;
        balances[_account] += _amount;
        emit Transfer(address(0), _account, _amount);
    }

     function _burn(address _account, uint256 _amount) internal  {
        require(_amount <= balances[_account],"");
        balances[_account] = balances[_account] - _amount;
        totalAmount -= _amount;
        emit Transfer(_account, address(0), _amount);
    }

}