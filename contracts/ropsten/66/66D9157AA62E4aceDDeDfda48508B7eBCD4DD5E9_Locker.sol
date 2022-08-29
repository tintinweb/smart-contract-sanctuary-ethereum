/**
 *Submitted for verification at Etherscan.io on 2022-08-29
*/

//SPDX-License-Identifier:MIT

pragma solidity 0.8.15;


interface ERC20 {
    function totalSupply() external view returns (uint _totalSupply);
    function balanceOf(address _owner) external view returns (uint balance);
    function transfer(address _to, uint _value) external returns (bool success);
    function transferFrom(address _from, address _to, uint _value) external returns (bool success);
    function approve(address _spender, uint _value) external returns (bool success);
    function allowance(address _owner, address _spender) external view returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);

}



contract Locker is ERC20 {
    string public constant symbol = "LKR";
    string public constant name = "Locker";
    uint8 public constant decimals = 18;
 
    uint private constant __totalSupply = 1000000000000000000000000;

    mapping (address => uint) private __balanceOf;

    mapping (address => mapping (address => uint)) private __allowances;

    //the creator of the contract has the total supply and no one can create tokens
    constructor() public {
        __balanceOf[msg.sender] = __totalSupply;
    }

    function totalSupply() public pure override returns (uint _totalSupply) {
        _totalSupply = __totalSupply;
    }

    function balanceOf(address _addr) public view override returns (uint balance) {
        return __balanceOf[_addr];
    }
    
    function transfer(address _to, uint _value) public override returns (bool success) {
        if (_value > 0 && _value <= balanceOf(msg.sender)) {
            __balanceOf[msg.sender] -= _value;
            __balanceOf[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        }
        return false;
    }

    function transferFrom(address _from, address _to, uint _value) public override returns (bool success) {
        if (__allowances[_from][msg.sender] > 0 &&
            _value >0 &&
            __allowances[_from][msg.sender] >= _value
            //  the to address is not a contract
            && !isContract(_to)) {
            __balanceOf[_from] -= _value;
            __balanceOf[_to] += _value;
            emit Transfer(_from, _to, _value);
            return true;
        }
        return false;
    }


    //This check is to determine if we are sending to a contract?
    //Is there code at this address?  If the code size is greater then 0 then it is a contract.
    function isContract(address _addr) public view returns (bool) {
        uint codeSize;
        //in line assembly code
        assembly {
            codeSize := extcodesize(_addr)
        }
        // i=s code size > 0  then true
        return codeSize > 0;    
    }

 
    function approve(address _spender, uint _value) external override returns (bool success) {
        __allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }


    //shows how much a spender has the approval to spend to a specific address
    function allowance(address _owner, address _spender) external override view returns (uint remaining) {
        return __allowances[_owner][_spender];
    }
}