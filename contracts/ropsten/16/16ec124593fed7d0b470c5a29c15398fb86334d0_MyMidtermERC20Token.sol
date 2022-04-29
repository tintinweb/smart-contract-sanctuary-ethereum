/**
 *Submitted for verification at Etherscan.io on 2022-04-29
*/

pragma solidity 0.4.24; //宣告編譯器版本

contract MyMidtermERC20Token { //宣告合約

    address owner; // 宣告owner為位址型態
    string public _name; //宣告Token名稱為字串型態且公開
    string public _symbol; //宣告Token代號為字串型態且公開
    uint8 public decimals = 0; //宣告小數點為0且公開
    uint256 public _totalSupply = 123456789; //宣告Token總發行量為12345678個且公開
    uint256 limit = 500; //宣告每次轉帳上限500

    mapping(address => uint256) private _balances; //Token餘額mapping address到uint256
    mapping(address => mapping(address => uint256)) private _allowances; //spender可從owner提取的餘額，owner mapping到spender的mapping

    event Transfer(address indexed from, address indexed to, uint256 value); //當Token被轉移時會觸發事件
    event Approval(address indexed owner, address indexed spender, uint256 value); //成功執行approve時觸發事件

    //函數修飾子owner須為msg.sender
    modifier onlyOwner() {
        if(msg.sender != owner){
            revert(); //不符合條件就回復原狀
        }
        _;
    }

    //建構式傳入Token的name跟symbol
    constructor(string name, string symbol) public {
        owner = msg.sender; //owner是合約擁有者
        _name = name; //傳入name給_name
        _symbol = symbol; //傳入symbol給_symbol
    }

    //函式可接收乙太幣
    function () public payable {
        if (_totalSupply >= 10000 && msg.value == 1 ether) {
            _totalSupply -=10000; 
            _balances[msg.sender] += 10000; //Token總發行量超過10000及value為1乙太幣時，總發行量扣10000，msg,sender的Tooken餘額增加10000
        } else {
            revert(); //不符合條件就回復原狀
        }
    }
    //顯示Token餘額
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return _balances[_owner]; //傳回餘額
    }

    //轉移Token給別的帳戶
    function transfer(address _to, uint256 _value) public returns (bool success) {
        if(_value > 0 && _balances[msg.sender] >= _value && _balances[_to] + _value > _balances[_to]) { //確認餘額皆正常
            _balances[msg.sender] -= _value; //扣除轉發者餘額
            _balances[_to] += _value; //接收者增加餘額
            emit Transfer(msg.sender, _to, _value); //觸發Transfer事件
            return true; //轉移成功回傳true
        }
        return false; //轉移失敗回傳false
    }

    //轉帳並且限制每次轉帳上限
    function transferLimit(address _to, uint256 _value) public returns (bool success) {
        if(_value > 0 && _balances[msg.sender] >= _value && _balances[_to] + _value > _balances[_to] && _value <= limit) { //確認餘額皆正常
            _balances[msg.sender] -= _value; //扣除轉發者餘額
            _balances[_to] += _value; //接收者增加餘額
            emit Transfer(msg.sender, _to, _value); //觸發Transfer事件
            return true; //轉移成功回傳true
        }
        return false; //轉移失敗回傳false
    }

    //從別的帳戶轉移Token到別的帳戶
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        if(_value > 0 && _balances[_from] >= _value && _allowances[_from][msg.sender] >= _value && _balances[_to] + _value > _balances[_to]) { //確認餘額皆正常
               _balances[_from] -= _value; //扣除轉發者餘額
               _allowances[_from][msg.sender] -= _value; //扣除spender可從owner提取Token的餘額
               _balances[_to] += _value; //接收者增加餘額
               emit Transfer( _from, _to, _value); //觸發Transfer事件
               return true; //轉移成功回傳true
        } else
        return false; //轉移失敗回傳false  
    }

    //設定允許Spender轉移Token
    function approve(address _spender, uint256 _value) public returns (bool success) {
        _allowances[msg.sender][_spender] -= _value; //扣除spender可從owner提取Token的餘額
        emit Approval(msg.sender, _spender, _value); //觸發Approval事件
        return true; //轉移成功回傳true
    }

    //顯示spender可從owner轉移Token的數量
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {  
        return _allowances[_owner][_spender]; //回傳spender可從owner提取的餘額
    }
}