/**
 *Submitted for verification at Etherscan.io on 2022-08-12
*/

pragma solidity ^0.4.20;

/*
1、本节学习：ERC20代币（token）的接口interface
2、
*/

contract ERC20Interface {
    string public name;//代币名字
    string public symbol;//代币符号缩写
    uint8 public decimals;//代币小数点位数
    uint public totalSupply;//代币总供应量

    //转账函数，传入地址和金额，返回布尔值
    function transfer(address _to,uint256 _value) returns(bool success);
    //第三方代转账函数，传入转出地址、转入地址和金额，返回布尔值
    function transferFrom(address _from,address _to,uint _value) returns(bool success);
    //授权函数，传入被授权人地址和金额，返回布尔值
    function approve(address _spender,uint _value) returns(bool success);
    //查询剩余授权限额函数，传入授权人地址、被授权人地址，返回整型
    function allowance(address _owner,address _spender) returns(uint256 remaining);


    //事件记录函数，传入已编入索引的，转出地址、转入地址和金额，记录转移信息
    event Transfer(address indexed _from,address indexed _to,uint256 _value);
    //事件记录函数，传入已编入索引的，授权人地址、被授权人地址和金额，记录授权信息
    event Approval(address indexed _owner,address indexed _spender,uint256 _value);
    //事件记录函数，传入已编入索引的，代币数量，记录增发的代币数量
    event AddSupply(uint256 indexed _value);
}

//把接口文件的属性和方法继承过来
contract ERC20 is ERC20Interface{
   //把地址映射成一个整型，方法名是：balanceOf 直观翻译：余额来自,（用mapping来保存账本信息）balanceOf[address]代表账户代币余额，是一个整型
   mapping(address => uint256) public balanceOf;
   //把被授权人地址映射成一个整型（代表额度）再把这个整型映射给授权人地址（代表只属于这个授权人的额度），方法名是：allowed 直观翻译：已授权额度
   //第一个地址是授权人owner，第二个地址是授权给谁,allowed[address1][address2]代表已【谁1】授权给【谁2】的额度，是一个整型
   mapping(address => mapping(address => uint256)) public allowed;

    constructor(string _name,string _symbol,uint8 _decimals,uint _totalSupply)public {
        name = _name;//中国人币
        symbol = _symbol;
        decimals = _decimals;
        totalSupply = _totalSupply;//总发行量13亿
        balanceOf[msg.sender] = totalSupply;
    }


    //转账函数，传入地址和金额，返回布尔值
    function transfer(address _to,uint256 _value) returns(bool success){
        require(_to != address(0));//目标账号不是全0地址
        require(balanceOf[msg.sender] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;

        //跟之前不同的是，这里要发出一个转账事件，说明成功了，如果转账失败也不会执行到这里
        emit Transfer(msg.sender,_to,_value);
        return true;

    }
    //第三方代转账函数，传入转出地址、转入地址和金额，返回布尔值
    function transferFrom(address _from,address _to,uint _value) returns(bool success){
            require(_to != address(0));
            require(balanceOf[_from] >= _value);
            require(balanceOf[_to] + _value > balanceOf[_to]);
            require(allowed[_from][msg.sender] >= _value);

            balanceOf[_from] -= _value;
            balanceOf[_to] += _value;
            allowed[_from][msg.sender] -= _value;

            emit Transfer(_from,_to,_value);
            return true;
        
    }


    //授权函数，传入被授权人地址和金额，返回布尔值
    function approve(address _spender,uint _value) returns(bool success){
       //授权额度不要超过授权人的代币余额
        require(balanceOf[msg.sender] >= _value);
        //【谁1】授权给【谁2】的额度赋值给_value
        allowed[msg.sender][_spender] = _value;
        //发出一个事件
        emit Approval(msg.sender,_spender,_value);
        return true;

    }
    //查询剩余授权限额函数，传入授权人地址、被授权人地址，返回整型
    function allowance(address _owner,address _spender) returns(uint256 remaining){
        return allowed[_owner][_spender];
    }

}

contract owned{
    //定义一个地址变量owner，用来保存代币管理者
    address public owner;
    //定义一个构造函数，用来初始化代币管理者
    constructor()public{
      owner = msg.sender;
    }
    
    //定义一个函数修改器，用来限定当前调用者就是代币管理者
    modifier onlyOwner(){
        require(owner == msg.sender);
        _;
    }

    //定义一个函数方法，把代币管理者赋值给传入参数，实现代币管理者的转让
    function transferOwnerShip(address _newOwner) onlyOwner public{
        
        owner= _newOwner;
    }

}

//创建一个合约，让它继承以上两个合约
contract advanceToken is ERC20,owned {
    //由于ERC20合约的构造函数里面有可传参数，所以这里也要把这个参数写到构造函数里
    constructor(string _name,string _symbol,uint8 _decimals,uint _totalSupply)  ERC20(_name,_symbol,_decimals,_totalSupply) public {

    }

    //定义一个挖矿函数,传入一个地址，数量，来增加代币数量
    function mine(address _target, uint _value) onlyOwner public {
        //把增加的代币数量给这个地址
        balanceOf[_target] += _value;
        //发出一个转账事件，新增发的代币数量其实就相当于从全0地址给这个地址转了一笔钱
        emit Transfer(0,_target,_value);

        //修改一下总发行量
        totalSupply += _value;
        //发出一个增加总发行量的事件
        emit AddSupply(_value);
       
    }


}