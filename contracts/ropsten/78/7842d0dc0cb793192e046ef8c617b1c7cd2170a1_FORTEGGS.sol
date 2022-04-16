/**
 *Submitted for verification at Etherscan.io on 2022-04-16
*/

pragma solidity 0.4.26;

contract ERC20 {
    function totalSupply() public constant returns (uint);
    function balanceOf(address tokenOwner) public constant returns (uint balance);
    function allowance(address tokenOwner, address spender) public constant returns (uint remaining);
    function transfer(address to, uint tokens) public returns (bool success);
    function approve(address spender, uint tokens) public returns (bool success);
    function transferFrom(address from, address to, uint tokens) public returns (bool success);
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract FORTEGGS {
	
    address FORT = 0x722dd3F80BAC40c951b51BdD28Dd19d435762180;
    address admin = 0x2123542F8D42CB13ab40220A395F3aE8e6A4D0cE;

	uint private toteggBought;
    
    mapping(address => User) private users;
    
    struct User {
		uint eggBought;
		uint fortEarned;
    }

    event TokenOperation(address indexed account, string txType, uint tokenAmount, uint trxAmount);     
   
    function buyEGG() public payable {
	
	require(msg.value >= 1e18, "Zero amount");
    require(msg.value == 10000000000000000000, "An egg costs 10 FORT");
    
    ERC20(FORT).transferFrom(address(msg.sender), address(this), msg.value);	

		User storage user = users[msg.sender];

        user.eggBought += 1;
        toteggBought += 1;	  
		
		uint random = getRandomNumber(msg.sender);
        
		uint numberFort = random*10000000000000000;
        ERC20(FORT).transfer(msg.sender, numberFort);

		user.fortEarned += numberFort;
		
	}
		
        function getRandomNumber(address _addr) public view returns(uint){
        return uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,_addr))) % 10;
		}
        
    }

    library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

  /**
  * @dev Substracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}