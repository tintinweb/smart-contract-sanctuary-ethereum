/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

pragma solidity 0.4.24;

contract erc20token{
    
    string public name; //代幣名稱
    string public symbol; //代幣代號
    uint8 public decimals=0; //小數位數
    uint256 public totalsupply=10000; //總發行量
    mapping(address=>uint256) balances; //記錄地址有幾個代幣的索引
    mapping(address=>mapping(address=>uint256)) allowed; //記錄誰授權給誰，授權多少代幣

    address owner;
    modifier onlyOwner(){ //管理員限定
        if(msg.sender != owner){
            revert();
        }
    _;
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    //交易的事件 
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    //授權的事件

    constructor(string _name, string _symbol) public{ //建構式，管理員、代幣名稱、代幣代號
        owner=msg.sender;
        name=_name;
        symbol=_symbol;
    }
    
    function() public payable{ 
        if(totalsupply>0 && msg.value == 1 ether){ //如果總發行量大於零而且收到一個以太幣
            totalsupply -=100; //總發行量減少100
            balances[msg.sender] += 100; //發送以太幣的帳號拿到100代幣
        }
        revert();
    }

    function balanceof(address _owner) public view returns (uint256 balance){
        return balances[_owner]; //查詢該位址有多少代幣
    }

    function transfer(address _to, uint256 _value) public returns (bool success){
        if(_value>0 //如果交易量大於零
            && balances[msg.sender]>= _value //and該位址的代幣餘額大於等於交易量
            && balances[_to] + _value > balances[_to]){ //and收到代幣的位址餘額加上交易量大於原本的餘額（防溢位）
                balances[msg.sender] -= _value; //該位址的餘額要減掉交易量
                balances[_to] += _value; //收到代幣的位址餘額要加上交易量
                emit Transfer(msg.sender, _to, _value); //觸發事件
                return true;
        }
        return false;
    }

    function transferfrom(address _from, address _to, uint256 _value) public returns (bool success){
    if(_value>0 //如果交易量大於零
            && balances[_from]>= _value //and授權人的代幣餘額大於等於交易量
            && allowed[_from][msg.sender]>= _value //and被授權的代幣數量大於等於交易量
            && balances[_to]+ _value > balances[_to]){ //and收到代幣的位址餘額加上交易量大於原本的餘額（防溢位）
                balances[_from] -= _value; //授權人的代幣餘額要減掉交易量
                allowed[_from][msg.sender] -= _value; //被授權的代幣數量要減掉交易量
                balances[_to] += _value; //收到代幣的位址餘額要加上交易量
                emit Transfer(_from, _to, _value); //觸發事件
                return true;
        }
        return false;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value; //授權的代幣數量
        emit Approval(msg.sender, _spender,_value); //觸發事件
        return true;
    }

    function allowance(address _owner, address _spender) public view returns(uint256){
        return allowed[_owner][_spender]; //誰授權給誰
    }
}