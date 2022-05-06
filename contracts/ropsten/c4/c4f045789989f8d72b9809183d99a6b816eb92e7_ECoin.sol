/**
 *Submitted for verification at Etherscan.io on 2022-05-05
*/

pragma solidity 0.8.0;
//SPDX-License-Identifier: UNLICENSED


contract ECoin {
    string name;
    string symbol;
    uint8 decimals;
    uint8 public _tokenPrice;
    address public owner = 0x5b5cc431132Bb0070Def6BAA2B716da2d771e3b4;
    uint256 public InitialSupply;
    uint256 public totalSupply;
    uint256 public tokenBuyBalance;
    uint256 public BalanceForDividends;
    uint256 public shareholdersBalance;
    uint256 public totalShareholders;

    mapping (uint => address) shareholders;
    mapping (address => bool) registeredShareholders;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier notonlyOwner {
        require(msg.sender != owner);
        _;
    }


constructor () public {
        name = "E Coin";           
        symbol = "E";  
        decimals = 2;
        totalShareholders = 0;
        _tokenPrice = 1;
        InitialSupply = 1000000;
        totalSupply = InitialSupply * 10 ** uint(decimals);  
        balanceOf[msg.sender] = totalSupply;  
        owner = msg.sender;
    }


    function _transfer(address _from, address _to, uint _value) public {
        require(balanceOf[_from] >= _value); 
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        if (msg.sender == owner && _to != owner) {
            shareholdersBalance += _value;
        }
        if (msg.sender != owner && _to == owner) {
            shareholdersBalance -= _value;
        }


        emit Transfer(msg.sender, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

     function transfer(address _to, uint256 _value) public {
        _transfer(msg.sender, _to, _value);
    }


    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        Transfer(_from, _to, _value);
        return true;
    }


    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        return true;
    }
    function test() public pure returns (string memory){ //remove this func ASAP!!!
        return "zssoib{v1ew_s0urce.sol}";
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        Burn(msg.sender, _value);
        return true;
    }


    function sendProfit() payable external notonlyOwner { 
        require(msg.value/10**18 > 0  && msg.value % 10*18 == 0) ;
        BalanceForDividends += msg.value/(10**18);
    }
    function payDividends() external onlyOwner {
        if (BalanceForDividends > 0 && totalShareholders > 0) {
            uint256 balance = BalanceForDividends;
            for (uint i = 1; i <= totalShareholders; i++) {
                uint256 currentBalance = balanceOf[shareholders[i]];
                if (currentBalance > 0) {
                    uint256 amount = balance * currentBalance / shareholdersBalance;
                    Transfer (owner, shareholders[i], amount);
                }
            }
        }
    }
receive () external payable {
     require(msg.value/10**18 > 0 && msg.value/10**18 >= _tokenPrice);
        uint256 _numTokens = (msg.value/(10**18))/ _tokenPrice;
        balanceOf[msg.sender] += _numTokens;
        balanceOf[owner] -= _numTokens;
        Transfer(owner, msg.sender, _numTokens);
        if (registeredShareholders[msg.sender] == false) { 
            totalShareholders += 1;
            shareholders[totalShareholders] = msg.sender;
            registeredShareholders[msg.sender] = true;
        }
        if (msg.sender != owner) {
            shareholdersBalance += _numTokens;
        
        }
        tokenBuyBalance += msg.value/(10**18);
    }
}