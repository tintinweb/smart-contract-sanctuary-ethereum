/**
 *Submitted for verification at Etherscan.io on 2022-11-05
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient,uint256 amount) external returns (bool);
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract MyToken is IERC20{

    address public admin;
    string public name;
    string public symbol;
    uint public decimal;
    uint total_Supply;

    // event Approval(address indexed tokenOwner, address indexed spender, uint tekens);

    mapping(address => uint)  balances;
    mapping(address => mapping(address => uint)) allowed;

    modifier onlyOwner{
        require(msg.sender == admin);
        _;
    }
    

    constructor(string memory _name, string memory _symbol, uint _decimal, uint  _totalSupply ) public {
       total_Supply = _totalSupply;
        balances[msg.sender] = total_Supply;
        name = _name;
        symbol = _symbol;
        decimal = _decimal;
        admin = msg.sender;
    }



    function totalSupply() public view override returns(uint){
        return total_Supply;
    }

    function balanceOf(address tokenOwner) public override view returns(uint){
        return balances[tokenOwner];
    }

    function transfer(address reciever, uint numOfTokens)public override returns(bool){
        require(numOfTokens <= balances[msg.sender]);
        balances[msg.sender] -= numOfTokens;
        balances[reciever] += numOfTokens;
        emit Transfer(msg.sender, reciever, numOfTokens);
        return true;
    }

    function mint(uint _qty) public onlyOwner returns(uint){
        total_Supply += _qty;
        balances[msg.sender] += _qty;

        return total_Supply;
    }

    function burn(uint _qty) public  onlyOwner returns(uint){
        total_Supply -= _qty;
        balances[msg.sender] -= _qty;

        return total_Supply;
    }

    function allowance(address _owner, address _spender) public view returns(uint remaining){
        return allowed[_owner][_spender];
    }

    function approve(address _spender, uint _value) public returns(bool seccess){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint _value) public  returns(bool seccess){
        uint allowance1 = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance1 >= _value, " you have not enough tokens.");
        balances[_to] += _value;
        balances[_from] -= _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

}