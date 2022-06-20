/**
 *Submitted for verification at Etherscan.io on 2022-06-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.14;

contract ERC20 {

    string public name;
    string public symbol;
    uint public totalSupply;
    uint public decimals = 18;
    address public owner;

    mapping(address=>uint) private balances;
    mapping(address=>mapping(address=>uint)) private _allowances; 

    //Events
    event Transfer( address,address,uint);
    event Approval (address,address,uint);

    constructor (string memory _name,string memory _symbol,uint _totalSupply){

        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        
        owner = msg.sender;
        balances[msg.sender] = totalSupply;
    }

    function allowance(address _owner ,address _spender) internal view returns(uint) {
        return _allowances[_owner][_spender];
    }

    function _spendAllowance(address _owner, address _spender, uint _amount) internal {
        uint currentAllowance = allowance(_owner,_spender);
        if(currentAllowance != type(uint).max){
            require(currentAllowance >= _amount,"ERC20: Insufficient Balance of Allowance");
            unchecked{
                _approve(_owner,_spender,currentAllowance-_amount);
            }
        }
    }

    function balanceOf(address account) public view returns(uint){
        return balances[account]; 
    }

    function transfer(address _to, uint _amount) public {
        address _owner = msg.sender;

        _transfer(_owner,_to,_amount);
    }

    function _transfer(address _owner, address _to, uint _amount) internal returns (bool){
        require(_owner != address(0),"Owner Address Should not be zero from transfer");
        require(_to != address(0),"Receiver Address Should not be zero from transfer");
        require(balances[owner] >= _amount,"Insufficient balance to transfer");
            _owner = msg.sender;
        balances[owner] -= _amount;
        balances[_to] += _amount;

        emit Transfer(owner,_to,_amount);
        return true;
    }

    function approve(address _spender, uint _amount) public returns(bool){
        address _owner = msg.sender;
        _approve(_owner,_spender,_amount);

        return true;
    }

    function _approve (address _owner,address _spender, uint _amount) internal returns(bool){

        require(_owner != address(0),"Owner Address should not be zero");
        require(_spender != address(0),"Spender address should not be zer0");

        _allowances[_owner][_spender] = _amount;
        emit Approval(_owner,_spender,_amount);

        return true;


    }

    function transferFrom(address _from,address _to, uint _amount) public returns(bool) {
        address spender = msg.sender;
        _spendAllowance(_from, spender, _amount);
        _transfer(_from, _to, _amount);
        return true;

    }

    function mint(address _account, uint _amount) public  returns(bool){
        require(_account != address(0),"Mint Function:Minting Address is zero");
        totalSupply += _amount;
        balances[_account] += _amount;

        emit Transfer(address(0),_account,_amount);

        return true;
    }

    function burn(address _account,uint _amount ) public returns(bool) {
        require(_account!= address(0),"Burn Function: Burning Address is zero");
        require(balances[_account] >= _amount,"Burn Function: Account balance exceed to burn");

        totalSupply -= _amount;
        balances[_account] -= _amount;

        emit Transfer(address(0),_account,_amount);

        return true;
    }

    function increaseAllowance(address _spender, uint _addeValue ) public returns(bool) {
        address owner_ = msg.sender;
        _approve(owner_,_spender, allowance(owner_,_spender) + _addeValue);

        return true;
    }

    function decreaseAllowance(address _spender, uint _subtractedValue ) public returns(bool) {
        address owner_ = msg.sender;
        uint currentAllowance = allowance(owner_,_spender);
        require(currentAllowance >= _subtractedValue,"decreaseAllowance Function: Allowance balance exceed to subtracted value");
        _approve(owner_,_spender, allowance(owner_,_spender) - _subtractedValue);

        return true;
    }


}