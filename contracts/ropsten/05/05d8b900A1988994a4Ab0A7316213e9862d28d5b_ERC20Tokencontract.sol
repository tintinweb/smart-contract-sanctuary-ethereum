/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

pragma solidity 0.4.24;//編譯版本

contract ERC20Tokencontract{
    address owner;

    string public name;
    string public symbol;
    uint8  public decimals=0;//精度(小數)為0
    uint256 public totalSupply=10000000;//幣的總數
    mapping(address=>uint256) balances;//設定代表帳戶擁有的餘額
    mapping(address=>mapping(address=>uint256)) allowed;//設定



    event Transfer(address indexed _from, address indexed _to, uint256 _value);//當有交易時才會處發事件,將訊息(a傳給b多少錢)公開在鏈上
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);//當有交易時才會處發事件,將訊息(a同意b多少錢)公開在鏈上

    modifier onlyOwner(){//檢查擁有者時使用
        if( msg.sender != owner){
            revert();
        }
        _;
    }


    constructor(string _name,string _symbol) public{
        owner=msg.sender;
        name=_name;//設定名字
        symbol=_symbol;//設定名字
    }


    function () public payable{//當收到乙太幣時,傳給購買者10000個幣
        if(totalSupply>=10000
            &&msg.value==1 ether){
                totalSupply-=10000;
                balances[msg.sender]+=10000;
            }else{
            revert();}
    } 

    function balanceOf(address _owner) public view returns (uint256 balance){//查詢輸入地址的餘額
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success){//傳給誰多少錢,同時排除例外狀況
        if(_value>0
            &&balances[msg.sender]>=_value
            &&balances[_to]+_value>balances[_to]){
                balances[msg.sender] -= _value;
                balances[_to] +=_value;
                emit Transfer(msg.sender,_to,_value);
                return true;
            }else
        return false;
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){//傳_from的錢到_to多少_value,同時排除例外狀況
        if(_value>0
            &&balances[_from]>=_value
            &&allowed[_from][msg.sender]>=_value
            &&balances[_to]+_value>balances[_to]){
                balances[_from]-=_value;
                allowed[_from][msg.sender]-=_value;
                balances[_to] +=_value;
                emit Transfer(_from,_to,_value);
                return true;
            }else
        return false;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){//同意輸入的地址可以操作多少自己帳戶的餘額,同時排除例外狀況
        if(_value>0
            &&balances[msg.sender]>=_value
        ){
        allowed[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;}else
        return false;
    }
    
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){//查詢_owner同意_spender操作的餘額為多少
        return allowed[_owner][_spender];
    }
    function mint(uint amount) external{//增加totalSupply,增加發行的幣數
        balances[msg.sender]+=amount;
        totalSupply+=amount;
        emit Transfer(address(0),msg.sender,amount);
    }

    function burn(uint amount) external{//減少totalSupply,減少發行的幣數
       balances[msg.sender]-=amount;
       totalSupply-=amount;
       emit Transfer(msg.sender,address(0),amount);
    }

    function increaseAllowance(address _spender, uint256 _addedValue) public  returns (bool success){//增加同意的_spender操作餘額,同時排除例外狀況
        if(_addedValue>0
            &&balances[msg.sender]>=_addedValue
            &&allowed[msg.sender][_spender]+_addedValue<=balances[msg.sender]
            &&allowed[msg.sender][_spender]+_addedValue>allowed[msg.sender][_spender]){
                allowed[msg.sender][_spender]+=_addedValue;
                emit Approval(msg.sender,_spender,_addedValue);
                return true;
            }else{
            return false;}
  
    }

    function decreaseAllowance(address _spender, uint256 _addedValue) public  returns (bool success){//減少同意的_spender操作餘額,同時排除例外狀況
        if(_addedValue>0
            &&allowed[msg.sender][_spender]>=_addedValue){
                allowed[msg.sender][_spender]-=_addedValue;
                emit Approval(msg.sender,_spender,_addedValue);
                 return true;
            }else{
            return false;}

    }

    function get(uint256 _value) public returns (bool success){//直接取得幣,方便測試用
        
        balances[msg.sender] += _value;
        totalSupply-=_value;      
        return true;
            
    }
}