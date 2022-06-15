/**
 *Submitted for verification at Etherscan.io on 2022-06-15
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
contract ownable{
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    modifier onlyowner() {
        require (msg.sender == owner, "only owner can call this function");
        _;
    }
    function transferownership(address newowner) public onlyowner{
        owner = newowner;
    }
}
contract MyERC20 is ownable{
    string public TokenName;
    string public Symbol;
    uint public TotalSupply;
    uint public Decimals = 18;
    mapping (address => uint) public balanceOf;
    mapping (address => mapping(address => uint)) public Allowances;
    mapping (address => bool) public AccountFrozen;

    constructor(
        string memory _TokenName,
        string memory _Symbol,
        uint _Totalsupply
        ){
            TokenName = _TokenName;
            Symbol = _Symbol;
            TotalSupply = _Totalsupply * 10 ** Decimals;
            balanceOf[msg.sender] = TotalSupply;
        }
        function _transfer(address _from, address _to, uint _value) internal {
            require( _to != address(0), "require correct address");
            require(balanceOf[_from] >= _value, "insufficent token");
            require(AccountFrozen[_from] != true,"your account is freezed");
            uint previousbalances = (balanceOf[_from]+balanceOf[_to]);
            balanceOf[_from] -= _value ;
            balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);
            assert(balanceOf[_from]+balanceOf[_to] == previousbalances);
        }

        event Transfer(address indexed _from, address indexed _to, uint _value);

        function transfer(address _to, uint _value)external returns (bool success){
            _transfer(msg.sender, _to , _value);
            return true;
        }
        event Allowance(address indexed _owner, address indexed _spender, uint _value);

        function approve(address _spender, uint _value) external returns (bool success){
            require (balanceOf[msg.sender] >= _value,"insufficent funds");
            require(AccountFrozen[msg.sender] != true,"your account is freezed");
            require(AccountFrozen[_spender] != true,"your account is freezed");
            Allowances[msg.sender][_spender] = _value ;
            emit Allowance(msg.sender, _spender, _value);
            return true;   
        }

        function transferfrom(address _from, address _to, uint _value) external returns (bool success){
            require (Allowances[_from][msg.sender] >= _value, "insufficent token to spent");
            require(AccountFrozen[_to] != true,"your account is freezed");
            _transfer(_from,_to, _value);
            Allowances[_from][msg.sender] -= _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        function _burn(address _from , uint _value)internal {
            balanceOf[_from] -= _value;
            TotalSupply -= _value;
        }
        event Burn(address indexed _from, uint _value);

        function burn(uint _value) external returns(bool success){
            require(balanceOf[msg.sender] >= _value, "insufficent balance");
            _burn(msg.sender,_value);
            emit Burn(msg.sender, _value);
            return true;
        }
        function burnfron (address _from, uint _value) external returns (bool success){
            require(Allowances[_from][msg.sender] >= _value,"insufficent balances");
            Allowances[_from][msg.sender] -= _value;
            _burn(_from,_value);
            emit Burn(_from, _value);
            return true;
        }
        function mint(uint _NoOfToken) external onlyowner{
            balanceOf[msg.sender]+= _NoOfToken;
            TotalSupply += _NoOfToken;
        }

        event Freeze (address indexed _person, bool Freezed);

        function FreezeAccout(address _person, bool Freezed)external onlyowner{
            AccountFrozen[_person] = Freezed;
            emit Freeze(_person, Freezed);
        }


        




}