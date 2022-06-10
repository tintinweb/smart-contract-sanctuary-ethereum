/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

pragma solidity ^0.6.2;
contract MyToken { 
    address payable public owner;
    string _name =  "HiGeneral";
    string _symbol = "SLF";
    uint8 _decimals = 8;
    uint _totalSupply = 1 * 1e18 ;
    uint TokenPrice = 1e15;
    uint private contractBalance = address(this).balance;
    mapping(address => uint256)private balances;
    modifier onlyOwner() { 
        require(msg.sender == owner);
        _;
    }
    constructor() public { 
        owner = msg.sender;
        balances[owner] = _totalSupply;
    }

    function buyToken() public payable { 
        require(msg.value > 0 && msg.value % 10 == 0);
        uint price = msg.value /TokenPrice;
        balances[owner] -= price;
        balances[msg.sender] += price;
        // owner.transfer(price);
        
    }
    function selToken(uint _count) public { 
        require(balances[msg.sender] > 0 );
        balances[msg.sender] -= _count;
        balances[owner] += _count;
        uint share = _count * TokenPrice;
        contractBalance -=  share; 
        msg.sender.transfer(share);

    }
    function tokenPrice(uint value) public onlyOwner{ 
        
        TokenPrice = value;
    }
    function name() public view returns (string memory) {
        return( _name);
    }
    
    function symbol() public view returns (string memory){
        return(_symbol);
    }

    function decimals() public view returns (uint8){
        return _decimals;
    }

    function totalSupply() public view returns (uint256){
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance){
        return (balances[_owner]);
    }

    function transfer(address payable _to, uint256 _value) public{
        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        uint share = (_value * 1) / 100;
        uint share2 = _value - share; 
        owner.transfer(share);
        _to.transfer(share2);

    }

    function transferFrom(address _from, address payable _to, uint256 _value) public {
        require(balances[_from] >= _value);
        balances[_from] -= _value;
        balances[_to] += _value;
        _to.transfer(_value);
    }
    function getValue() public view onlyOwner() returns(uint) { 
        return contractBalance;
    }
    // function approve(address _spender, uint256 _value) public returns (bool success)

    // function allowance(address _owner, address _spender) public view returns (uint256 remaining)
    
        
}