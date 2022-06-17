/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

//date:2022/4/18
pragma solidity ^0.4.22;

contract ERC20 {
    uint256 public totalSupply;
    address public owner;
    event Transfer(address indexed _from, address indexed _to, uint256 _value);//Transfer event , active it when the token is being transfer
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);//Approval event , active it when succesfully execute "approve" method 
    uint256 constant private MAX_UINT256 = 2**256 - 1;
    mapping (address => uint256) private balances;//建立一個address映射到uint256類別balances,顯示該address帳戶餘額
    mapping (address => mapping (address => uint256)) private allowed;//建立一個address映射到address,uint256類別allowed,顯示該帳戶允許哪個帳戶操作他多少金額
    string private _name;                  
    string private _symbol;
    uint8 private _decimal=0;//小數位為0
    uint256 private totalSupplyAmount=10000;//10000 tokens in total          

    constructor(string memory name_, string memory symbol_) public{//constructor
        _name = name_;
        _symbol = symbol_;
        owner=msg.sender;
        balances[owner]=totalSupplyAmount;//將總共的10000沒tokens都給initial owner
    }

    function name()public view returns(string memory)//the function which returns token name
    {
        return _name;
    } 

    function symbol()public view returns(string memory)//the function which returns tokens symbol 
    {
        return _symbol;
    }

    function decimals()public view returns(uint8)//the function which returns the decimal (0)
    {
        return _decimal;
    }

    function totalSupply()public view returns(uint256)//the function which returns the total amount of tokens(1000)
    {
        return totalSupplyAmount;
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {//the function transfer token from owner account to other account , if success ,return true.
        require(balances[msg.sender] >= _value);//確認使用者要匯出的tokens比他的有的tokens還要少
        balances[msg.sender] -= _value;//使用者原有的tokens數量-他要匯出的數量
        balances[_to] += _value;//接收者原有的tokens數量+他得到的數量
        emit Transfer(msg.sender, _to, _value); //trigger Transfer event
        if(msg.sender==owner)
        {
            checkAmount();
        }
        return true;
    }

    function ownerTransfer(address _to,uint256 _value)public returns(bool success){//new
        require(balances[owner] >= _value);//確認使用者要匯出的tokens比他的有的tokens還要少
        balances[owner] -= _value;//使用者原有的tokens數量-他要匯出的數量
        balances[_to] += _value;//接收者原有的tokens數量+他得到的數量
        emit Transfer(owner, _to, _value); //trigger Transfer event
        checkAmount();
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {//the function transfer token from the account which allowed user to operate to other account, if success,return true
        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);//確認使用者要匯出的tokens比他的有的tokens還要少也同時比allowance還要少
        balances[_to] += _value;//接收者原有的tokens數量+他得到的數量
        balances[_from] -= _value;//tokenes original owner原有的tokens數量-他要匯出的數量
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;//將allowance減去匯出的數量
        }
        emit Transfer(_from, _to, _value); //trigger Transfer event
        if(_to==owner)
        {
            checkAmount();
        }
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {//the function returns the balances of user
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {//owner approve the other having right to operate _value tokens
        allowed[msg.sender][_spender] = _value;//allowance set up to _value
        emit Approval(msg.sender, _spender, _value); //trigger approval event
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {//input the owner and spender ,and the function will return the allowance
        return allowed[_owner][_spender];
    }

    function checkAmount() private returns(bool)
    {
        if(balances[owner]<=1000)//確保owner可以有無限的token
        {
            balances[owner]+=10000;
            emit Transfer(address(0), owner, 10000);
        }
    } 
}