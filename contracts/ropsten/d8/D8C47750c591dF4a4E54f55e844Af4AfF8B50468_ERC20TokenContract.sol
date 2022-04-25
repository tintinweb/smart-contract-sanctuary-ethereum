/**
 *Submitted for verification at Etherscan.io on 2022-04-23
*/

pragma solidity 0.4.24;

contract ERC20TokenContract{

    address owner; // owner地址
    string public name ; //代幣名稱
    string public symbol ; // 代幣token代幣token
    uint8 public decimals = 0;
    uint256 public totalSupply = 100000000; //發行上限
    mapping (address => uint256) balances; //帳戶餘額
    mapping(address => mapping(address=> uint256)) allowed; // 代理人mapping


    event Transfer(address indexed _from, address indexed _to, uint256 _value); //轉帳活動
    event Approval(address indexed _owner, address indexed _spender, uint256 _value); // 授權代理人活動



    modifier onlyOwner(){ //只有owner可以
        if(msg.sender != owner){
            revert();
        }
        _;
    }

    constructor(string _name,string _symbol) public{ //建構式
        owner = msg.sender;
        name = _name;
        symbol = _symbol;
    }

    function  ()public payable{
        if(totalSupply>10000 && msg.value == 1 ether){ //收到1乙太幣發10000token
            totalSupply -= 10000;
            balances[msg.sender] += 10000; // 錢包+10000token

        }
        else{
            revert();
        }
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner]; //這裡帳戶餘額
    }

    function transfer(address _to, uint256 _value) public returns (bool success){

        if (_value>0 && balances[msg.sender]>= _value && balances[_to] + _value > balances[_to] ){ // 地址>0 轉進來的錢>0
            balances[msg.sender] -= _value; // 自己錢包減少

            balances[_to] += _value; //對方錢包增加

            emit Transfer(msg.sender, _to, _value); // 呼叫移轉活動

            return true ; 
        }
        return false;




    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){ //代理人操作轉帳

        if (_value>0 && balances[_from]>= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to] ){
            balances[_from] -= _value; //balances[_from] = balances[_from] - _value 

            allowed[_from][msg.sender] -= _value; // 代理者減少可使用錢

            balances[_to] += _value; // 對方錢包增加

            emit Transfer(_from, _to, _value); // 呼叫轉移活動

            return true ; 
        }
        return false;
    }


    function approve(address _spender, uint256 _value) public returns (bool success){ // 代理人授權轉帳
        allowed[msg.sender][_spender] =_value; // 允許代理操作，設定數字限制

        emit Approval(msg.sender, _spender, _value);  //呼叫允許活動

        return true;

    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining){ // 還剩下多少錢可以用
        return allowed[_owner][_spender]; //回傳剩下的錢
    }


/*

*/

/*

    function symbol() public view returns (string) {

    }

    function totalSupply() public view returns (uint256){

    }
    function balanceOf(address _owner) public view returns (uint256 balance){

    }

    
    
    

    */

}