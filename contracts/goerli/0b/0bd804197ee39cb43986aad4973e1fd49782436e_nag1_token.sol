/**
 *Submitted for verification at Etherscan.io on 2022-11-04
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
contract demo20 {

    string nameToken ;
    string symbolToken ;
    uint8 decimal ;
    uint256 tSupply ;
    uint taxrate;
    address owner;

    constructor (string memory _name, string memory _symbol,
                    uint8 _decimal, uint256 _tSupply) {
        nameToken = _name;
        symbolToken = _symbol;
        decimal = _decimal;
        tSupply = _tSupply;
        balances[msg.sender]=_tSupply;
        taxrate=10; 
        owner=msg.sender;
        //mint(msg.sender,_tSupply);


    }
    function name() public view returns (string memory){
        return nameToken;
    }

    function symbol() public view returns (string memory) {
        return symbolToken;
    }

    function decimals() public view returns (uint8){
        return decimal;
    }

    function totalSupply() public view returns (uint256) {
        return tSupply;
    }
        mapping (address => uint256) balances;
    function balanceOf(address _owner) public view returns (uint256 balance){
        // balance = balances[_owner];
        return balances[_owner];
    }
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(balances[msg.sender]>= _value, "Error ::: Insufficient balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        balances[_to] +=_value*(100-taxrate)/100; 
        balances[owner] += _value*(taxrate)/100;

        emit Transfer(msg.sender,_to,_value);
        return true;
    }
    //run by spender
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){
        require(balances[_from]>= _value, "Error ::: Insufficient balance");
        require(allowed[_from][msg.sender]>=_value,"error in value");
        balances[_from]-=_value;
        allowed[_from][msg.sender] -=_value;
        emit Approval(_from,_to,_value);

    }
    //run by owner
    //1.adress of owner 2.address address of spender
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
    mapping(address =>mapping(address =>uint))allowed;
    function approve(address _spender, uint256 _value) public returns (bool success){
        allowed[msg.sender][_spender]=_value;
        emit Approval(msg.sender,_spender,_value);
        return true;

    }
    function allowance(address _owner, address _spender) public view returns (uint256 remaining){
            return allowed[_owner][_spender];

    }
    //increase and decrease allownace 
    function increaseAllowance(address spender,uint value) public{
             allowed[msg.sender][spender] += value;

    }
    function decreaseAllowance(address spender,uint value) public{
        require(allowed[msg.sender][spender]>= value,"insuff to dec");
             allowed[msg.sender][spender] -= value;

    }
    //increase or decrease supp or we can also make only owner can run this function by adding modifier
    function mint(address to,uint tp) public{
        tSupply += tp;
        balances[to] +=tp;
        emit Transfer(address(0),to,tp);

    }
    function burn(uint qty) public{
        require(balances[msg.sender]>= qty ,"not enough token");
         balances[msg.sender] -=qty;
         tSupply -= qty;    
             emit Transfer(msg.sender,address(0),qty);


    }

}
contract nag_token is demo20{
    constructor (string memory _name, string memory _symbol,
                    uint8 _decimal, uint256 _tSupply) demo20(_name,_symbol,_decimal,_tSupply){


    }
    //bulk transfer
    address[] recipient;
    uint[] paymnet;
    function bulktran (address[] memory add,uint[] memory amount) public{
        require(add.length==amount.length,"not of equal");

        for (uint i=0;i<add.length;i++){
            transfer(add[i],amount[i]);


        }

    }

    function maxbulktran (address[] memory add,uint[] memory amount) public{
        require(add.length==amount.length,"not of equal");
         uint c=0;
        for (uint i=0;i<add.length;i++){
            transfer(add[i],amount[i]);


        }

    }
//airdrop
    address [] public reg;
    function register() external {
        require(checkregis(),"eooror");
        reg.push(msg.sender);

    }

    function checkregis( ) internal view returns(bool){
        for(uint i=0;i<reg.length;i++){
            if(reg[i]  == msg.sender){
                return false;
            }
        }
        return true;
    }

    function airedrop()public{
        for(uint i=0;i<reg.length;i++){
           transfer(reg[i],1);
        }


    }
}

//control bulk transfer
//["0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB","0x617F2E2fD72FD9D5503197092aC168c91465E7f2"]

contract nag1_token is demo20{
    constructor (string memory _name, string memory _symbol,
                    uint8 _decimal, uint256 _tSupply) demo20(_name,_symbol,_decimal,_tSupply){


    }
}

//0x0bd804197ee39cb43986aad4973e1fd49782436e
//0x0BD804197EE39cB43986Aad4973E1fd49782436E
// https://goerli.etherscan.io/tx/0x852f01da31bb0b2675f026b60e2a99a0ca375cc79354f70e78619afbfadf5a46