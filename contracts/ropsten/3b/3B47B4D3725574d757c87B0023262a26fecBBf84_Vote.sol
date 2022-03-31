/**
 *Submitted for verification at Etherscan.io on 2022-03-31
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function safeMul(uint a, uint b) public pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function safeDiv(uint a, uint b) public pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// https://github.com/ethereum/EIPs/blob/master/EIPS/eip-20-token-standard.md
// ----------------------------------------------------------------------------
interface ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address tokenAddress) external view returns (uint balance);
    function transferFrom(address from, address to, uint tokens) external returns (bool success);
    function mint(address tokenAddress, uint256 tokens) external returns(bool);


    event Transfer(address indexed from, address indexed to, uint tokens);

}

contract Vote is ERC20Interface, SafeMath {
    string public symbol;
    string public  name;
    uint8 public decimals;
    uint private _totalSupply;
    address public owner;
    
    mapping(address => bool) private minters;
    mapping(address => uint) private balances;

    // ------------------------------------------------------------------------
    // Constructor
    // ------------------------------------------------------------------------
    constructor(){
        symbol = "TP";
        name ="TTIMPASS";
        _totalSupply = 0;
        balances[msg.sender] = _totalSupply;
        owner = msg.sender;
        minters[msg.sender] = true;
        
        emit Transfer(address(0),msg.sender,_totalSupply);    
    }
    
    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
    modifier onlyMinters(){
        require(minters[msg.sender]);
        _;
    }
    
    // ------------------------------------------------------------------------
    // Total supply
    // ------------------------------------------------------------------------
    function totalSupply() public override view returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    // ------------------------------------------------------------------------
    // Get the token balance for account tokenOwner
    // ------------------------------------------------------------------------
    function balanceOf(address tokenAddress) public override view returns (uint balance) {
        return balances[tokenAddress];
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        require(tokens <= balances[from],"You don't have enough balance");
        balances[from] = safeSub(balances[from], tokens);
       // allowed[from][to] = safeSub(allowed[from][to], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
    
    function mint(address recipient, uint256 amount) public override onlyMinters returns(bool) {
            MintYourToken(recipient, amount);
            return true;
    }
     function burn(address account,uint256 amount) external {
             burnYourVote(account, amount);
    }
    function MintYourToken(address account, uint256 amount) internal {
            require(account != address(0), "ERC20: mint to the zero address");
            if(account == owner){
                _totalSupply = safeAdd(_totalSupply, amount);
                balances[account] = safeAdd(balances[account], amount);
            }
        }

    function burnYourVote(address account, uint256 value) internal {
        require(account != address(0), "ERC20: burn from the zero address");
         _totalSupply = safeSub(_totalSupply, value);
         balances[account] = safeSub(balances[account], value);
    }   
}