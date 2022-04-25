/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

pragma solidity 0.4.24;

contract ERC20TokenContract {

    address owner;

    string public name = "Lovely Coin"; //token的名稱
    string public symbol = "LLC" ; //token的代稱
    uint256 public decimals = 0 ; //使用的小數點位數，選用
    uint256 public totalSupply = 100000000 ; //總發行量  合約還持有的token數量

    mapping (address => uint256) balances; //一個帳戶對應的餘額
    
    mapping (address => mapping(address => uint256)) allowed; //只能一個操作員
    /*struct operator{ 
        address operator; 
        uint256 tokens;
    } 
    mapping (address => operator[]) allowed; //可以多個操作員
    */

    event Transfer(address indexed _from, address indexed _to, uint256 _value); //當token被轉移時觸發
    event Approval(address indexed _owner, address indexed _spender, uint256 _value); //成功執行approve方法時觸發

    modifier onlyOwner() {
        if (msg.sender != owner){
            revert();
        }
        _;
    }

    constructor() public {
        owner = msg.sender; //msg.sender指的是執行這個合約的人/當前使用者
    }

    function () public payable{
        if(totalSupply > 0
            && msg.value == 1 ether){ //向合約傳送一個乙太幣
            totalSupply -= 10000; //總發行量-10000個token
            balances[msg.sender] += 10000; //當前使用者的帳戶位址+10000個token
        }else{
            revert();
        }
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }//傳回_owner位址的token數量

    function transfer(address _to, uint256 _value) public returns (bool success){
        if(_value > 0 //判斷轉出的token數量>0
           && balances[msg.sender] >= _value //且該轉出帳戶的token餘額要足夠支付這些token
           && balances[_to] + _value > balances[_to]){ //且對方的token餘額+被轉入的token要大於原本的token餘額
               balances[msg.sender] -= _value;
               balances[_to] += _value;
               emit Transfer(msg.sender, _to, _value); //當token被轉移時觸發
               return true;
        }else
        return false;
     }//發送數量為_value的token到位址_to，觸發Transfer事件

   function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
       if(_value > 0 //判斷轉出的token數量>0
           && balances[_from] >= _value //且該轉出帳戶的token餘額要足夠支付這些token
           && allowed[_from][msg.sender] >= _value //且_spender被授權可使用的token數量要>=這些token
           && balances[_to] + _value > balances[_to]){ //且對方的token餘額+被轉入的token要大於原本的token餘額
               balances[_from] -= _value;
               allowed[_from][msg.sender] -= _value;
               balances[_to] += _value;
               emit Transfer(_from, _to, _value); //當token被轉移時觸發
               return true;
        }else
        return false;
    }//從位址_from發送數量為_value的token到位址_to，觸發Transfer事件

    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender,  _value); //成功執行approve方法時觸發
        return true;
    }//授權_spender提取數量為_value的token ，觸發Approval事件

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
        return allowed[_owner][_spender];
    }//傳回_spender可從_owner提取的剩餘token數量

}