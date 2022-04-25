/**
 *Submitted for verification at Etherscan.io on 2022-04-25
*/

pragma solidity 0.4.24;

//協助不同合約的交易
interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes a_extraData) external; }
contract ERC20TokenContract{

//設定各項變數
    address owner; //合約擁有者
    string public name; //代幣名稱
    string public symbol; //代幣稱號
    uint8 public decimals = 0; //設定token最小位數
    uint256 public totalsupply = 1000000 ; //總發行額
    mapping(address=>uint256) balances; //代理人設置
    mapping (address=>mapping(address=>uint256)) allowed; //代理人代理的人可以運用的數量
 
//交易事件 
    event Transfer(address indexed _from,address indexed _to,uint256 _value);

//授權事件   
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

//刪除事件
    event Burn(address indexed _from, uint256 _value);


//確認合約擁有者
    modifier onlyOwner(){
        if(msg.sender != owner){
            revert();
        } 
        _; 
    }

//建構子
    constructor(string _name, string _symbol)public{
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
    }

//不同合約的交易使用
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


//將擁有的Token刪除
    function burn(uint256 _value) public onlyOwner returns (bool success) {  
        
        /*Burn 方法 本人驗證
        **方法A 加上OnlyOwner(間略版驗證，但無法確認數值是否足夠)
        **方法 B require(balances[msg.sender] >= _value);
        ** [B選擇比較好，可以同時驗證及確認數額]
        */ 
        require(balances[msg.sender] >= _value);//確認使用者餘額是否足夠，

        balances[msg.sender] >= _value;
        balances[msg.sender] -= _value; 
        totalsupply -= _value; 
        emit Burn(msg.sender, _value);
        return true;
        
    }


//代理人將代理的Token刪除
    function burnFrom(address _from, uint256 _value)  public returns (bool success) {

        /*缺乏代理人驗證
        **確認代理人代理使用者授權Tokes數量，並能同時驗證代理人資格
        */
        require(allowed[_from][msg.sender] >= _value); //同時驗證Tokes數及代理人資格
        
        /* balanceOf[_from] >= _value 說明及更改
        **原目的為透過該方法確認Tokes 是否足夠，但發現兩個問題。
        **第一個問題:主要問題，這是查詢代理人的Tokens 餘額
        **第二個問題:排除主要問題，若需要驗證是否足夠，需要使用require連接才能完成
        */

        allowed[_from][msg.sender] -= _value;
        totalsupply -= _value;
        emit Burn(_from, _value);
        return true;
        
    }
  

//購買合約Token
    function ()public payable{
        if(totalsupply >=10000
            && msg.value == 1 ether){
            totalsupply -= 10000;
            balances[msg.sender]+=10000;
        }else{
            revert();
        }

    }

//查詢地址Token餘額
    function balanceOf(address _owner)public view returns (uint256 balance){
            return balances[_owner];
    }

    
//擁有者移轉Token給他人
    function transfer (address _to, uint256 _value) public returns(bool success){
        if(_value > 0
            && balances[msg.sender] >= _value
            && balances[_to] + _value > balances[_to]){ //避免溢位導致未增加
                balances[msg.sender] -= _value;
                balances[_to ] += _value;
                emit Transfer(msg.sender, _to, _value);
                return true; 
        }else 
        return false;
        
    }

//代理者移轉Token給他人
    function transferFrom(address _from, address _to, uint256 _value)public returns(bool success){
        if( _value > 0
            && balances[_from] >= _value
            && allowed[_from][msg.sender] >= _value
            && balances[_to] + _value > balances[_to]){
                balances[_from] -= _value;
                allowed[_from][msg.sender] -=_value;
                balances[_to ] += _value;
                emit Transfer(_from, _to, _value);
                return true; 
        }
        else
        return false;
            

    }

// 授權token的移轉
    function approve (address _spender,uint256 _value)public returns (bool success){
            allowed[msg.sender][_spender]= _value;
            emit Approval (msg.sender, _spender ,_value);
            return true;

    }

//查詢代理人代理的Token餘額
    function allowance (address _owner ,address _spender)public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }
}