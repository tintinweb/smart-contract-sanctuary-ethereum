/**
 *Submitted for verification at Etherscan.io on 2021-03-25
*/

pragma solidity ^0.4.16;

contract ERC20Basic {
    uint256 public totalSupply = 30000000;
    function balanceOf(address who) constant returns (uint);
    function transfer(address _to, uint _value) returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
}

 /*
 * Contract that is working with ERC223 tokens
 */
 
contract ERC20ReceivingContract {
    function tokenFallback(address _from, uint _value, bytes _data);
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
 
  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }
 
  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }
 
  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }

//   function assert(bool assertion) internal {
//     if (!assertion) revert();
//   }
}

contract ERC20BasicToken is ERC20Basic{
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    // Standard function transfer similar to ERC20 transfer with no _data .
    // Added due to backwards compatibility reasons .
    function transfer(address _to, uint _value) returns (bool success) {
        uint codeLength;
        bytes memory empty;

        assembly {
            // Retrieve the size of the code on target address, this needs assembly .
            codeLength := extcodesize(_to)
        }
        
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        if(codeLength>0) {
            ERC20ReceivingContract receiver = ERC20ReceivingContract(_to);
            receiver.tokenFallback(msg.sender, _value, empty);
        }
        Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) constant returns (uint balance) {
        return balances[_owner];
    }
}

contract TriumphDinar is ERC20BasicToken{
	address admin;
	string public name = "Triumph Dinar";
    string public symbol = "TRHD";
    uint public decimals = 6;
	mapping (address => bool) public mintable;

	event Minted(address indexed recipient, uint256 value);
	event Burned(address indexed user, uint256 value);

	function TriumphDinar() {
		admin = msg.sender;
	}

	modifier onlyadmin { if (msg.sender == admin) _; }

	function changeAdmin(address _newAdminAddr) onlyadmin {
		admin = _newAdminAddr;
	}

	function createNewMintableUser (address newAddr) onlyadmin {
		if(balances[newAddr] == 0)  
    		mintable[newAddr] = true;
	}
	
	function deleteMintable (address addr) onlyadmin {
	    mintable[addr] = false;
	}
	
	function adminTransfer(address from, address to, uint256 value) onlyadmin {
        if(mintable[from] == true) {
    	    balances[from] = balances[from].sub(value);
    	    balances[to] = balances[to].add(value);
    	    Transfer(from, to, value);
        }
	}
	
	function mintNewTRHD(address user, uint256 quantity) onlyadmin {
	    uint256 correctedQuantity = quantity * (10**(decimals-1));
        if(mintable[user] == true) {
            totalSupply = totalSupply.add(correctedQuantity);
            balances[user] = balances[user].add(correctedQuantity);
            Transfer(0, user, correctedQuantity);
            Minted(user, correctedQuantity);
        }   
	}
	
	function burnTRHD(address user, uint256 quantity) onlyadmin {
	    uint256 correctedQuantity = quantity * (10**(decimals-1));
	    if(mintable[user] == true) {
            balances[user] = balances[user].sub(correctedQuantity);
            totalSupply = totalSupply.sub(correctedQuantity);
            Transfer(user, 0, correctedQuantity);
            Burned(user, correctedQuantity);
	    }
	}
}