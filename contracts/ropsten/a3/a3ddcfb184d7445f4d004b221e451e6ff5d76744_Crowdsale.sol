/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

pragma solidity ^0.8.0;


contract Crowdsale {

    uint public price = 2 ether;
    address public owner;
    address public contractAddress;
    bool fullyPaid; // false

    event PriceFullyPaid(uint _price); 
    
    Mrserg86TokenCoin public token = new Mrserg86TokenCoin();
    
    uint start = 1644476400;
    
    uint period = 28;
 
    constructor() {
        owner = msg.sender;
    }
    
    function payForItem() public payable {
        require(block.timestamp > start && block.timestamp < start + period*24*60*60);
        address payable contractAddress = payable(address(this));
        contractAddress.transfer(msg.value);
        
    }

    receive() external payable {
        require(msg.value <= price && !fullyPaid, "Rejected");

        if(address(this).balance >= price) {
            fullyPaid = true;

            emit PriceFullyPaid(price);
        } else {
            token.mint(address(0x0),msg.sender, msg.value*1000);    
        }
        
    }
    
    function withdrawAll() public {
        require(owner == msg.sender, "You are not an owner");
        address payable receiver = payable(msg.sender);
        receiver.transfer(address(this).balance);
    }

}

contract Mrserg86TokenCoin {
    
    string public constant name = "Mrserg86 Token";
    
    string public constant symbol = "SERG1";
    
    uint32 public constant decimals = 18;
    
    uint public totalSupply = 0;
    
    mapping (address => uint) balances;
    
    // mapping (address => mapping(address => uint)) allowed;
    
    function mint(address _from, address _to, uint _value) public  {
        assert(totalSupply + _value >= totalSupply && balances[_to] + _value >= balances[_to]);
        balances[_to] += _value;
        totalSupply += _value;
        emit Transfer(_from, _to, _value);
    }
    
    function balanceOf(address _owner) public view returns (uint balance) {
        return balances[_owner];
    }
 
    function transfer(address _to, uint _value) public returns (bool success) {
        if(balances[msg.sender] >= _value && balances[_to] + _value >= balances[_to]) {
            balances[msg.sender] -= _value; 
            balances[_to] += _value;
            emit Transfer(msg.sender, _to, _value);
            return true;
        } 
        return false;
    }
    
    function transferFrom() public pure returns (uint nol) {
        return 0;
    }
    
    function approve() public pure returns (bool success) {
        return false;
    }
    
    function allowance() public pure returns (bool success) {
        return false;
    }
    
    event Transfer(address indexed _from, address indexed _to, uint _value);
    
    event Approval(address indexed _owner, address indexed _spender, uint _value);
    
}