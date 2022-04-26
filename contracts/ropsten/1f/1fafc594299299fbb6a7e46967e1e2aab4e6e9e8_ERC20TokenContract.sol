/**
 *Submitted for verification at Etherscan.io on 2022-04-26
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
    // 交易事件: 設定從交易者(位置地址 _frpm)，交易給被交易者(位置地址 _to)，及Token數(_value)。

//授權事件   
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    //授權事件: 將授權者(位置地址 _Owner)授權Tokens(_value)給被授權者(位置地址 _spender)。

//刪除事件
    event Burn(address indexed _from, uint256 _value);
    //刪除事件: 將這個人(位置地址 _form)，刪除他要刪除的Tokes(_value)。


//確認是否為合約擁有者
    modifier onlyOwner(){
        //透過if判定，若不為合約擁有者不能執行，若可以才能執行後面內容
        if(msg.sender != owner){ //IF函式判斷不為擁有者的判斷式
            revert();            //終止執行
        } 
        _;                       //執行後面內容
         
    }

//建構子
    //基本建構:建構入稱呼(_name)及稱呼發行的Token名稱(_symbol)
    constructor(string _name, string _symbol)public{ //建構內容設定為Public 讓鏈中成員都能呼叫設定
        owner = msg.sender;                          //將跑合約的Account設定(msg.sender)為合約擁有者(owner)
        name = _name;                                //將輸入的name(_name)設定為該發行幣的稱呼
        symbol = _symbol;                            //將輸入的Tokne名稱設定為該幣Token的名稱
    }

//不同合約的交易使用
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }


//將Token刪除
    function burn(uint256 _value) public onlyOwner returns (bool success) {  
        
        /*Burn方法的本人驗證
        **方法A 加上OnlyOwner(間略版驗證，但無法確認數值是否足夠)
        **方法 B require(balances[msg.sender] >= _value);
        ** [B選擇比較好，可以同時驗證及確認數額]
        */ 

        require(balances[msg.sender] >= _value);        //確認擁用者餘額(_value)是否足夠，
        if(balances[msg.sender] >= _value){             //確認擁有者餘額使否大於燒毀餘額(_value)
            balances[msg.sender] -= _value;             //減少擁有者餘額
            totalsupply -= _value;                      //總發行量減少
            emit Burn(msg.sender, _value);              //觸發刪除事件完成變更
            return true;                                //回傳成功
        }
        else{
            return false;                               //回傳失敗
        }
        
    }


//代理人將代理的Token刪除
        /*缺乏代理人驗證
        **確認代理人代理使用者授權Tokes數量，並能同時驗證代理人資格
        */
    function burnFrom(address _from, uint256 _value)  public returns (bool success) {
        require(allowed[_from][msg.sender] >= _value);  //同時驗證Tokens數及代理人資格
        if(allowed[_from][msg.sender] >= _value         //確認代理數是否大於餘額
            && balances[_from]>= _value){               //確認擁有者餘額是否足夠
            allowed[_from][msg.sender] -= _value;       //代理人可代理餘額減少
            balances[_from] -= _value;                  //擁有者餘額(_value)減少
            totalsupply -= _value;                      //總發行量(_value)減少
            emit Burn(_from, _value);                   //觸發刪除事件完成變更
        return true;                                    //回傳成功
        }
        else{
            return false;
        }
    }
  

//購買合約Token
    function ()public payable{
        if(totalsupply >=10000                  //確認總發行額數
            && msg.value == 1 ether){           //確認是否花費 1 ether
            totalsupply -= 10000;               //目前鏈中可發行額度檢調10000
            balances[msg.sender]+=10000;        //將該帳戶增加（msg.sender）10000發行幣
        }
        else{
            revert();                           //如果前面兩個確定沒有，就終止執行
        }

    }

//查詢地址Token餘額
    function balanceOf(address _owner)public view returns (uint256 balance){ //查詢擁有者(位置地址 _Owner)
            return balances[_owner];                                         //回傳擁有者(位置地址 _Owner)餘額
    }

    
//擁有者移轉Token給他人
    function transfer (address _to, uint256 _value) public returns(bool success){
        if(_value > 0                                   //確定交易額(_value)大於0
            && balances[msg.sender] >= _value           //確定交易額(_value)大於擁有者額額(balances[msg.sender])
            && balances[_to] + _value > balances[_to]){ //避免溢位導致未增加
                balances[msg.sender] -= _value;         //擁有者額額(balances[msg.sender])減少交易額(_value)
                balances[_to ] += _value;               //交易者(位置地址 _to)增加交易額(_value)
                emit Transfer(msg.sender, _to, _value); //觸發事件交易完成上述內容設定
                return true;                            //回傳成功
        }else 
        return false;                                   //回傳失敗
        
    }

//代理者移轉Token給他人
    function transferFrom(address _from, address _to, uint256 _value)public returns(bool success){
        if( _value > 0
            && balances[_from] >= _value                //確定擁有者的餘額balances[_from]是否足夠
            && allowed[_from][msg.sender] >= _value     //確定代理者代理餘額allowed[_from][msg.sender]是否足夠
            && balances[_to] + _value > balances[_to]){ //避免溢位導致未增加
                balances[_from] -= _value;              //擁有者額額(balances[msg.sender])減少交易額(_value)
                allowed[_from][msg.sender] -=_value;    //減少代人者可代理額度(_value)
                balances[_to ] += _value;               //交易者(位置地址 _to)增加交易額(_value)
                emit Transfer(_from, _to, _value);      //觸發事件交易完成上述內容設定
                return true;                            //回傳成功
        }
        else
        return false;                                   //回傳失敗
            

    }

// 授權token的移轉
    function approve (address _spender,uint256 _value)public returns (bool success){
            allowed[msg.sender][_spender]= _value;          //設定代理人可代理Token數(_value)
            emit Approval (msg.sender, _spender ,_value);   //觸發代理事件變更合約設定
            return true;                                    //回傳變更成功

    }

//查詢代理人代理的Token餘額
    function allowance (address _owner ,address _spender)public view returns (uint256 remaining){
        return allowed[_owner][_spender];   //回傳代理人Tokes餘額
    }
}