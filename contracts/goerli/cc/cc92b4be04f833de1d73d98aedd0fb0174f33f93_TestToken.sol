/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

pragma solidity ^0.8.14;

contract Ownable { // Контракт позволяющий вызывать некоторые функции только владельцу
    address private owner;
    
    modifier onlyOwner() {
        require(owner == msg.sender);
        _;
    }

    constructor ()  {
        owner = payable(msg.sender);
    }
}

contract TestToken is Ownable{

    
    string public constant name = "TestToken"; //название токена
    string public constant symbol = "Test1"; //скоращение токена
    uint8 public constant decimals = 1; //цифры после запятой
    address payable public fundsWallet;  //адресс для хранения токенов на ICO
    
    uint public _TotalSupply = 10000000; // Общее количество токенов
    mapping (address => uint) public balances; // массив балансов
    
    mapping (address => mapping(address => uint)) allowed;  // массив разрешений для использования функции transferFrom
    
    event Transfer(address indexed _from, address indexed _to, uint _value); // записывает транзакции в блокчейн
    
    
    
    function totalSupply() public view returns(uint) {          // функция, показывающая количество токенов
        return _TotalSupply;
    }
    
    function allowance(address _owner, address _spender) public view returns(uint){  // проверка количества разрешенных токенов для транзакции
        return allowed[_owner][_spender];
    }
    
    function balanceOf(address owner) public view returns(uint) {               // проверка баланса определённого кошелька
        return balances[owner];
    }
    
    function transfer(address _to, uint _value) public {                // функция перевода токенов с адресса отправителя
        require(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to , _value);
    }
    
     function transferFrom(address _from, address _to, uint _value) public {     //функция перевода токенов с указанного адреса (для отравки со смарт-котракта)
        require(balances[_from] >= _value && balances[_to] + _value >= balances[_to] && allowed[_from][msg.sender] >= _value); // проверка разрешения
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value; 
        emit Transfer(_from, _to , _value);
        
    }
    
    function approve(address _spender, uint _value) public {     // функция передачи разрешения на снятие токеной
        allowed[msg.sender][_spender] = _value;
    }
    

    
    function MakeICO() onlyOwner public{ // функция для начало ICO
        balances[msg.sender] = 10000000;                               
        fundsWallet = payable(msg.sender);                                    
    }
    
    function ICOballance() public view returns(uint){  // проверка количества оставшихся для продажи токенов
        
        return balances[fundsWallet];
    }
    
    
    
        function sell() external payable{ //  функция продажи токенов
        require(balances[fundsWallet] > 0);
        uint tokens = 1000000 * msg.value / 1000000000000000000;
        if (tokens > balances[fundsWallet]){
            tokens = balances[fundsWallet];
            uint Wei = tokens * 1000000000000000000 / 1000000;
            balances[msg.sender] -= msg.value - Wei;
            balances[payable(msg.sender)] += msg.value - Wei;
            
        }
        require (tokens > 0 && tokens < balances[fundsWallet]);
        balances[msg.sender] += tokens;
        balances[fundsWallet] -= tokens;
                emit Transfer(fundsWallet, msg.sender, tokens);
                balances[msg.sender] -= msg.value;
                balances[fundsWallet] += msg.value;
                

                
                
    }
}