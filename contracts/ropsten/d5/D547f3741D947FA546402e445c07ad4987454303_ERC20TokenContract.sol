/**
 *Submitted for verification at Etherscan.io on 2022-04-30
*/

pragma solidity 0.4.24;

contract ERC20TokenContract{

    address owner;
    string public name ; //代幣名稱
    string public symbol ; // 代幣token
    uint8 public decimals = 0; // decimals設定0
    uint256 public totalSupply = 100000000; //發行上限
    mapping (address => uint256) balances; //帳戶餘額，用address鎖定
    mapping(address => mapping(address=> uint256)) allowed; // 代理人mapping，地址指定代理人地址


    event Transfer(address indexed _from, address indexed _to, uint256 _value); //轉帳活動
    event Approval(address indexed _owner, address indexed _spender, uint256 _value); // 授權代理人活動



    modifier onlyOwner(){ //只有owner可以
        if(msg.sender != owner){ // 檢查是否為owner
            revert(); // 發出警告
        }
        _;
    }

    constructor(string _name,string _symbol) public{ //建構式
        owner = msg.sender; //owner是建立合約的人類
        name = _name; // 另外設定的name，取代原本合約的
        symbol = _symbol; // 另外設定的symbol，取代原本合約的
    }

    function  ()public payable{
        if(totalSupply>=10000 && msg.value == 1 ether){ //收到1乙太幣發10000token
            totalSupply -= 10000; // 已發行量減少10000
            balances[msg.sender] += 10000; // 錢包+10000token

        }
        else{
            revert(); // 發出警告
        }
    }

    function balanceOf(address _owner) public view returns (uint256 balance){ 
        return balances[_owner]; //回傳owner帳戶餘額
    }

    function transfer(address _to, uint256 _value) public returns (bool success){ //轉帳

        if (_value>0 && balances[msg.sender]>= _value && balances[_to] + _value > balances[_to] ){ // 如果 地址>0 轉的錢>0 對方錢更多
            balances[msg.sender] -= _value; // 自己錢包減少

            balances[_to] += _value; //對方錢包增加

            emit Transfer(msg.sender, _to, _value); // 呼叫移轉活動

            return true ; // 成功
        }
        return false; // 失敗




    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){ //代理人操作轉帳

        if (_value>0 && balances[_from]>= _value && allowed[_from][msg.sender] >= _value && balances[_to] + _value > balances[_to] ){ // 如果 轉的錢>0  錢包錢大於等於轉的錢 允許的錢>=轉的錢 對方錢更多
            balances[_from] -= _value; //balances[_from] = balances[_from] - _value 錢包減少錢

            allowed[_from][msg.sender] -= _value; // 代理者減少可使用錢

            balances[_to] += _value; // 對方錢包增加

            emit Transfer(_from, _to, _value); // 呼叫轉移活動

            return true ; // 成功
        }
        return false; // 失敗
    }


    function approve(address _spender, uint256 _value) public returns (bool success){ // 代理人授權轉帳
        allowed[msg.sender][_spender] =_value; // 允許代理操作，設定數字限制

        emit Approval(msg.sender, _spender, _value);  //呼叫允許活動

        return true; // 成功

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