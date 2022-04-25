/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

pragma solidity 0.4.26;

contract ERC20TokenContract {
    
    address owner;   

    string public name;     
    string public symbol;
    uint8 public decimals = 0;
    uint256 public totalSupply = 100000000;      //設定token總發行量為100000000
    mapping (address => uint256) balances;    //查詢一個位址的餘額
    mapping (address => mapping(address => uint256)) allowed;                   //第一個address是token的持有者，第二個address是此token持有者授權的代理人，uint256是授權token的數量。這種寫法一個token持有者，只能授權給一個人當操作員。

    event Transfer(address indexed _from, address indexed _to, uint256 _value);   //每用到transfer時，就必須再打事件。
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);   //每用到approval時，就必須再打事件。

    modifier onlyOwner() {            //檢查跟合約互動的是否為owner
        if(msg.sender != owner){
            revert();
        }
        _;        
    }

   constructor(string _name, string _symbol) public {
        owner = msg.sender;     //設置owner是msg.sender
        name = _name;
        symbol = _symbol;
    }

    function TransferOwnership(address newOwner) onlyOwner public {   //合約持有者可以轉換合約持有者
        owner = newOwner;
    } 

    function balanceOf(address _owner) public view returns (uint256 balance) {
       return balances[_owner];     //利用balances的mapping找特定address的balance
    }
    function transfer(address _to, uint256 _value) public returns (bool success){    //傳_value的token量給_to
        if (_value >0                          
            && balances[msg.sender] >= _value         //看傳送者的餘額是否大於要傳送的_value
            && balances[_to] +_value > balances[_to]) {   //預防溢位
                balances[msg.sender] -= _value;           //扣掉傳送者的餘額
                balances[_to] += _value;                  //增加接收者的餘額
                emit Transfer( msg.sender, _to, _value);     //宣告tranfer的事件
                return true;
            }
        else
        return false;      
    }

    function () public payable{               //當有人買token時的檢查
        if(totalSupply > 10000                //檢測合約裡面是否有足夠的token以及msg.sender是否寄一塊的ether
            && msg.value == 1 ether) {
            totalSupply -= 10000;             //然後合約減掉token，Msg.sender的帳戶加token
            balances[msg.sender] += 10000;
        } else {
            revert();
        } 
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){   //從_from傳_value到_to的位址，是給操作員用的
         if (_value >0              
            && balances[_from] >= _value                  //查看代理人的balance是否有足夠
            && allowed[_from][msg.sender] >= _value       //查看代理人被授權可使用的token量是否有達到發送量
            && balances[_to] +_value > balances[_to]) {   //預防溢位
               balances[_from] -= _value;                 //balances[_from] = balances[_from] - _value;   減少代理人的token  
               allowed[_from][msg.sender] -= _value;      //減少代理人可動用的token量
               balances[_to] += _value;                   //增加接收者的token量
               emit Transfer( _from, _to, _value);        //紀錄Transfer的事件
               return true;}
        else
        return false;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success){   //token持有人授權給一個人管理他的token
        allowed [msg.sender][_spender] = _value;             //token持有人授權給_spender管理_value的token量
        emit Approval(msg.sender,_spender, _value);          //紀錄Approval的事件
        return true;
    }

    function increaseApproval (address _spender, uint _addedValue) public returns (bool success){    //增加代理人可動用的token量
        allowed[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender ,allowed[msg.sender][_spender]);
        return true;
    }
    
    function decreaseApproval (address _spender, uint _subtractedvalue) public returns (bool success){  //減少代理人可動用的token量
        uint oldValue = allowed[msg.sender][_spender]; 
        if (_subtractedvalue > oldValue){
            allowed[msg.sender][_spender] = 0;
        } 
        else{
            allowed[msg.sender][_spender] -= _subtractedvalue;
        }
        emit Approval(msg.sender, _spender , allowed[msg.sender][_spender]);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){  //輸入token持有人以及操作員的位址可查詢這個操作員可操作的token量
        return allowed[_owner][_spender];
    }

    function sendback() public onlyOwner{         //傳輸這個合約中的錢給owner
        uint balancethis = address(this).balance;
        msg.sender.transfer(balancethis);
    }

}