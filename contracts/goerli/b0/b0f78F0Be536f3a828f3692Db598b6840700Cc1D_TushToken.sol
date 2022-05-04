/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

pragma solidity 0.8.0; 

contract TushToken {
    // Fungible Token - ERC20
    // Non Fungible Tokens (NFT) - ERC721
    constructor(string memory _name, string memory _symbol, uint8 _decimals, uint256 _tSupply) {
        name_ = _name;
        symbol_ = _symbol;
        decimals_ = _decimals;
        tSupply = _tSupply;
        // assign initial supply to deployer of the contract
        balances[msg.sender] = tSupply; 
        admin = msg.sender; //deployer
    }
    address admin;
    string name_;
    string symbol_;
    uint8 decimals_;
    uint256 tSupply;
    mapping(address => uint256) balances;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);


    function name() public view returns (string memory) {
            return name_;
    }
    function symbol() public view returns (string memory){
        return symbol_;
    }
    function decimals() public view returns (uint8) {
        return decimals_;
    }
    function totalSupply() public view returns (uint256){
        return tSupply;
    }
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender] >= _value, "Error::: Not enough balance");
        // a = a+1; a+=1; a=a+b; a+=b
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        // balances[admin] += _value*1/100;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    // transferFrom:  Sender -> _from , Receiver -> _to , Amount -> _value
    function transferFrom(address _from,address _to, uint256 _value) public returns (bool success){
        require(balances[_from] >= _value, "Error : Not enough tokens in owner's account");
        require(allowed[_from][msg.sender] >= _value, "Error : Not enough allowance available");
        balances[_from] -= _value;
        balances[_to] += _value;
        allowed[_from][msg.sender] -= _value;
        emit Transfer(_from, _to, _value);
        return true;

    }
    mapping(address => mapping (address => uint256)) allowed;
    //approve => Owner -> msg.sender, Spender -> _spender, Amount -> _value
    function approve (address _spender, uint256 _value) public returns(bool) {
        allowed[msg.sender][_spender] = _value;

        return true;

    }
    function allowance(address _owner, address _spender) public view returns(uint256 remaining){
        return allowed[_owner][_spender];
    }

    // owner: 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
    // spender: 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
    // receiver: 0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db

    // Increase / Decrease allowance (not part of standard ERC20 token)
    function increaseAllowance(address _spender, uint256 _amount) public returns(bool){
    allowed[msg.sender][_spender] += _amount;
    return true;
    }

    function decreaseAllowance(address _spender, uint256 _amount) public returns(bool){
    require(allowed[msg.sender][_spender]>= _amount, "Not enough allowance to decrease");
    allowed[msg.sender][_spender] -= _amount;
    return true;
    }


    // Mint / Burn tokens - mint and burn functions (also not part of standard ERC20)
    function mint(address _addr, uint256 _amount) public {
        require(admin == msg.sender, "Only owner");
        // a = a+1; a += 1; 
        tSupply += _amount;
        // 1. Mint tokens to msg.sender
        //balances[msg.sender] += _amount;
        // 2. Mint tokens to owner only. at this point ^ anyone could run this function and have tokens minted into their account.
        //balances[admin] += _amount;
        // 3. to mint to a specific address:
        balances[_addr] += _amount;

    }
    function burn(address _addr, uint256 _amount) public {
        require(admin == msg.sender, "Only owner");
        require(balances[admin] >= _amount, "Not enough tokens to burn");
        tSupply -= _amount;
        require(allowed[_addr][admin]>= _amount, "Not enough allowance to burn");
        allowed[_addr][admin] -= _amount;
        balances[_addr] -= _amount;

    }
    

    }