pragma solidity ^0.4.24;

contract ERC20Interface {
    function name() public view returns (string _name);
    function symbol() public view returns (string _symbol);
    function decimals() public view returns (uint8 _decimals);
    function totalSupply() public view returns (uint256 _totalSupply);
    // function balanceOf(address _owner) view returns (uint256 balance);
    // function transfer(address _to, uint256 _value) returns (bool success);
    // function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    // function approve(address _spender, uint256 _value) returns (bool success);
    // function allowance(address _owner, address _spender) view returns (uint256 remaining);
    // event Transfer(address indexed _from, address indexed _to, uint256 _value);
    // event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract MyToken is ERC20Interface {
    // 12.345678901234567890
    uint256 totalSupply_ = 12345678901234567890;
    
    function name() public view returns (string _name) {
        return "Bokky1";
    }

    function symbol() public view returns (string _symbol) {
        return "BOKKY1";
    }
    
    function decimals() public view returns (uint8 _decimals) {
        return 18;
    }
    
    function totalSupply() public view returns (uint256 _totalSupply) {
        return totalSupply_;
    }

    
    
}