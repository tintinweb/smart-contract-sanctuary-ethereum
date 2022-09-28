/**
 *Submitted for verification at Etherscan.io on 2022-09-28
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
* TODO
* 1. research to what other necessary functions will be needed in the contract (burn tokens? transfer tokens back to orignal wallet after redeeming?)
* 2. identitfy what is not needed
* 3. investigate when to use the approval method
*/
  
// ----------------------------------------------------------------------------
// ERC Token Standard #20 Interface
// Used to maintain erc20 standard functions and events
//
// ----------------------------------------------------------------------------
abstract contract ERC20Interface {
    function totalSupply() virtual public view returns (uint);
    function balanceOf(address tokenOwner) virtual public view returns (uint balance);
    function allowance(address tokenOwner, address spender) virtual public view returns (uint remaining);
    function transfer(address to, uint tokens) virtual public returns (bool success);
    function approve(address spender, uint tokens) virtual public returns (bool success);
    function transferFrom(address from, address to, uint tokens) virtual public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
   // event LogNewAddress(address sender, address newAddress);
}

// ----------------------------------------------------------------------------
// Safe Math Library for computations
// ----------------------------------------------------------------------------
contract SafeMath {
    function safeAdd(uint a, uint b) public pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function safeSub(uint a, uint b) public pure returns (uint c) {
        require(b <= a); c = a - b; } function safeMul(uint a, uint b) public pure returns (uint c) { c = a * b; require(a == 0 || c / a == b); } function safeDiv(uint a, uint b) public pure returns (uint c) { require(b > 0);
        c = a / b;
    }
}

/**
*  Contract which creates BadgeToken with an ERC20 interface.
* 
*/
contract BadgeToken is ERC20Interface, SafeMath {
    string public name;
    string public symbol;
    uint8 public decimals; // 18 decimals is the strongly suggested default, avoid changing it
    

    uint256 public _totalSupply;

    mapping(address => uint) balances; // can be used to determine who has the most supply; this will not get deleted each day lime addr_array
    mapping(address => mapping(address => uint)) allowed;
    mapping (address => bool) public Wallets; // holds all addresses that have interacted with the site
    


    /**
     * Constrctor function
     *
     * Initializes contract with initial supply tokens to the creator of the contract.
     * Called in ~/scripts/deploy_token.js as Token.deploy()
     */
    constructor()  {
        name = "BadgeToken";
        symbol = "BT";
        decimals = 18;
        _totalSupply = 100000000000000000000000000;

        balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply); // address(0) is a special case used to indcate a new contract is being deployed
    }

    /**
     * 
     * Determines if passed address is in the ones that already to the addr_array
     * 
     * returns true: If user address already in memory
     * returns false: If user address is new
     * https://ethereum.stackexchange.com/questions/32297/store-addresses-in-array-or-mapping
     */
    // function setWallet(address _wallet) public{
    //     Wallets[_wallet ]= true;
    // }

    // function contains(address _wallet) public view returns (bool){
    //     return Wallets[_wallet];
    // }

    // function resetWallet(address _wallet) public {
    //     Wallets[_wallet ]= false; // set all mappings to false
    // }
    // ^^ in production

    function totalSupply() public view override returns (uint) {
        return _totalSupply  - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view override returns (uint balance) {
        return balances[tokenOwner];
    }

    function allowance(address tokenOwner, address spender) public view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint tokens) public override returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    }

    function transfer(address to, uint tokens) public override returns (bool success) {
        // if(contains(to)){
        //     return false;
        // }
        // setWallet(to); 
        // ^^ in production
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        
        // possibly create event for LogNewAddres
        return true;
    }

    function transferFrom(address from, address to, uint tokens) public override returns (bool success) {
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
        return true;
    }
}