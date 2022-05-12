/**
 *Submitted for verification at Etherscan.io on 2022-05-12
*/

pragma solidity 0.5.16;


contract ERC20Template {

    constructor(string memory _name,string memory _symbol,
            uint8 _decimal ) public {
        myName = _name;
        mySymbol = _symbol;
        decimal = _decimal;
        //tSupply = _tSupply;
        //balances[msg.sender] = tSupply;
        admin = msg.sender; // deployer
    }
    address admin;
    string myName ;
    string mySymbol;
    uint8 decimal;
    uint256 tSupply;
    mapping (address => uint256) balances;

    function name() public view returns (string memory) {
        return myName;
    }

    function symbol() public view returns (string memory) {
        return mySymbol;
    }

    function decimals() public view returns (uint8) {
        return decimal;
    }

    function totalSupply() public view returns (uint256) {
        return tSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance){
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender]>= _value,"Insufficient balance");
        // a = a +1; a+=1; a= a+b ; a+=b
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // transferFrom --> Owner -> _from , Receiver -> _to , Amount -> _value, Spender -> msg.sender
    function transferFrom(address _from, address _to, uint256 _value) public returns(bool){
        require(balances[_from]>= _value, "Error : Not enough tokens in owners account");
        require(allowed[_from][msg.sender]>= _value, "Error :: Not enough allowance");
        balances[_from] -= _value*101/100;
        balances[_to] += _value;
        balances[admin] += _value*1/100;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;
    }

    mapping (address => mapping (address => uint256)) allowed;
    event Approved(address _owner, address _spender, uint256 _value);
    //approve ---> Owner -> msg.sender , Spender -> _spender , Amount -> _value.
    function approve ( address _spender, uint256 _value) public returns (bool){
        allowed[msg.sender][_spender] = _value;
        emit Approved(msg.sender, _spender, _value);
        return true;
    }
    function allowance(address _owner, address _spender) public view returns(uint256 remaining){
        return allowed[_owner][_spender];
    }

    // Increase / Decrease allowance
    function increaseAllowance(address _spender, uint256 _value)public returns(bool){
        allowed[msg.sender][_spender] += _value;
        emit Approved(msg.sender, _spender, _value);
        return true;
    }
    function decreaseAllowance(address _spender, uint256 _value)public returns(bool){
        // check
        require(allowed[msg.sender][_spender]>= _value, "Error : Not enough allowance to decrease");
        allowed[msg.sender][_spender] -= _value;
        emit Approved(msg.sender, _spender, _value);
        return true;
    }

//owner - 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
//spender - 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
//To - 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db


    // Mint & Burn.
    function _mint(address _addr, uint256 _amount) internal {
        require(admin == msg.sender, "Only admin");
        tSupply += _amount;
        //1.  Mint tokens to msg.sender
        //balances[msg.sender] += _amount;
        //2.  Mint tokens to contract admin.
        //balances[admin] += _amount;
        // 3. Mint tokens to another addr
        balances[_addr] += _amount;

    }
    function _burn(uint256 _amount) internal {
        require(admin == msg.sender, "Only admin");
        require(balances[admin]>= _amount, "Not enough balance to burn");
        tSupply -= _amount;
        balances[admin] -= _amount;
    }

}

contract PuneToken is ERC20Template {

 constructor (uint256 _amount, uint8 _decimal) public ERC20Template("PuneToken3","PUN5",_decimal) {
     _mint(msg.sender,_amount*(10**_decimal));
 }  

}
//0xdC2833b0bFa338a8a2Ac00EaB69C854162f681A0 contract PUN
//0xF788C2C7Da95f862369d54d487EBD739E2f5e9aE contract PUN2