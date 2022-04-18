pragma solidity^0.8.13;//SPDX-License-Identifier:None
contract OwlLand20AC{
    event Transfer(address indexed from,address indexed to,uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);
    mapping(address=>uint256)private _balances;
    mapping(address=>bool)private _access;
    uint256 private _totalSupply;
    modifier onlyAccess(){require(_access[msg.sender]);_;}
    constructor(){_access[msg.sender]=true;}
    function name()external pure returns(string memory){return "Owl War Land";}
    function symbol()external pure returns(string memory){return "OWL";}
    function decimals()external pure returns(uint8){return 18;}
    function totalSupply()external view returns(uint256){return _totalSupply;}
    function balanceOf(address account)external view returns(uint256){return _balances[account];}
    function transfer(address to,uint256 amount)external returns(bool){
        transferFrom(msg.sender,to,amount);
        return true;
    }
    function allowance(address owner,address spender)external pure returns(uint256){
        require(owner!=spender);
        return 0;
    }
    function approve(address spender,uint256 amount)external returns(bool){
        emit Approval(msg.sender,spender,amount);
        return true;
    }
    function transferFrom(address from,address to,uint256 amount)public returns(bool){unchecked{
        amount*=10**18;
        require(_balances[from]>=amount);
        _balances[from]-=amount;
        _balances[to]+=amount;
        emit Transfer(from,to,amount);
        return true;
    }}
    function ACCESS(address _a,bool _b)external onlyAccess{
        if(!_b)delete _access[_a];
        else _access[_a]=true;
    }
    function MINT(address account,uint256 amount)external onlyAccess{unchecked{
        amount*=10**18;
        _totalSupply+=amount;
        _balances[account]+=amount;
        emit Transfer(address(0),account,amount);
    }}
    function BURN(address account,uint256 amount)external onlyAccess{unchecked{
        amount*=10**18;
        _balances[account]-=amount;
        _totalSupply-=amount;
        emit Transfer(account,address(0),amount);
    }}
}