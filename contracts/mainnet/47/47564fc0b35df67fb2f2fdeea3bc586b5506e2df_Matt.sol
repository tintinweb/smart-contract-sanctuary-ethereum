/**
 *Submitted for verification at Etherscan.io on 2022-10-08
*/

pragma solidity ^0.4.21;

// ----------------------------------------------------------------------------
//
// 
// Symbol        : MMA
// Name          : MadMagazine
// Total supply  : 30
// Decimals      : 0
//
// 07.10.1992 - 30 Jahr Madness
// ----------------------------------------------------------------------------


library SafeMath {

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
      }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;}
    }
    


contract Matt{
    // Track how many tokens are owned by each address.
    mapping (address => uint256) public balanceOf;
    //Name of Token
    string public name = "MadMagazine";
    //Symbol of Token
    string public symbol = "MMA";
    //Decimals of Token
    uint8 public decimals = 0;
    //Address of the right man
    address public recipient = 0xE7811cCD75fa8c66F529A1Da698635CE1cD83df8;
    //Owner
    address private owner = msg.sender;

    
   
    //Total Supply 
    uint256 public totalSupply = 30;
    using SafeMath for uint256;
    //Default Transfer Option ERC20
    event Transfer(address indexed from, address indexed to, uint256 value);
    //Happy Birthday
    event Bday(string message);

    
    constructor() {
        // Initially assign all tokens to the contract's creator.
        balanceOf[msg.sender] = totalSupply;       
    }

    function transfer(address to, uint256 value) public returns (bool success) {
        require(balanceOf[msg.sender] >= value);

        balanceOf[msg.sender] -= value;  // deduct from sender's balance
        balanceOf[to] += value;          // add to recipient's balance
        emit Transfer(msg.sender, to, value);
        return true;
    }

    event Approval(address indexed owner, address indexed spender, uint256 value);

    mapping(address => mapping(address => uint256)) public allowance;

    function approve(address spender, uint256 value)
        public
        returns (bool success)
    {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value)
        public
        returns (bool success)
    {
        require(value <= balanceOf[from]);
        require(value <= allowance[from][msg.sender]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        allowance[from][msg.sender] -= value;
        emit Transfer(from, to, value);
        return true;
    }
    
    function _transferFrom(address from, address to, uint256 value)
        private
        returns (bool success)
    {
        require(value <= balanceOf[from]);

        balanceOf[from] -= value;
        balanceOf[to] += value;
        emit Transfer(from, to, value);
        return true;
    }
      
    
    // Happy Birthday Matt
    function BDayMatt() returns (uint256){
        if (msg.sender != recipient) throw;
        //nur wenn Guthaben
        if (balanceOf[owner] <= 0) throw;
        emit Bday("Happy Birthday Matt - viel Liebi Nati&Rebi");
        // Transfer the MadMagazine Token (Contract Owner Address)
        _transferFrom(owner, recipient, 30);  
    
    }

}