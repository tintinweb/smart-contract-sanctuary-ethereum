/**
 *Submitted for verification at Etherscan.io on 2022-12-20
*/

pragma solidity ^0.8.14;

library SafeMath {
  
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

  
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
          
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

  
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

  
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    
     
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

   
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}contract Ownable { // Контракт позволяющий вызывать некоторые функции только владельцу
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
    using SafeMath for uint;
    
    string public constant name = "TestToken"; //название токена
    string public constant symbol = "Test"; //скоращение токена
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
        require(balances[fundsWallet] > 0 && _TotalSupply <= 10000000 && _TotalSupply > 0);
        uint a = 1000000;
        uint b = 1000000000000000000;
        uint tokens = a.mul(msg.value).div(b);
        if (tokens > balances[fundsWallet]){
            tokens = balances[fundsWallet];
            uint Wei = tokens.mul(b).div(a);
            require(balances[msg.sender] >= msg.value.sub(Wei) && balances[msg.sender] + msg.value.sub(Wei) >= balances[msg.sender]);
            balances[msg.sender] -= msg.value.sub(Wei);
            balances[msg.sender] += msg.value.sub(Wei);
            emit Transfer(msg.sender, msg.sender , msg.value.sub(Wei));
            
        }
        require (tokens > 0 && tokens < balances[fundsWallet]);
        balances[msg.sender] = balances[msg.sender].add(tokens);
        balances[fundsWallet] = balances[fundsWallet].sub(tokens);
                emit Transfer(fundsWallet, msg.sender, tokens);
                require(balances[msg.sender] >= msg.value && balances[fundsWallet] + msg.value >= balances[fundsWallet]);
                balances[msg.sender] -= msg.value;
                balances[fundsWallet] += msg.value;
                emit Transfer(msg.sender, fundsWallet , msg.value);
                
    }
}