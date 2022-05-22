// SPDX-License-Identifier: MIT
pragma solidity ^0.7.6;
pragma abicoder v2;


contract Ownable {
  address private _owner;

  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
  constructor()  {
    _owner = msg.sender;
    emit OwnershipTransferred(address(0), _owner);
  }

  /**
   * @return the address of the owner.
   */
  function owner() public view returns(address) {
    return _owner;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(isOwner());
    _;
  }

  /**
   * @return true if `msg.sender` is the owner of the contract.
   */
  function isOwner() public view returns(bool) {
    return msg.sender == _owner;
  }

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipTransferred(_owner, address(0));
    _owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function transferOwnership(address newOwner) public onlyOwner {
    _transferOwnership(newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address newOwner) internal {
    require(newOwner != address(0));
    emit OwnershipTransferred(_owner, newOwner);
    _owner = newOwner;
  }
}
library SafeMath {

  /**
  * @dev Multiplies two numbers, reverts on overflow.
  */
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (a == 0) {
      return 0;
    }

    uint256 c = a * b;
    require(c / a == b);

    return c;
  }

  /**
  * @dev Integer division of two numbers truncating the quotient, reverts on division by zero.
  */
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b > 0); // Solidity only automatically asserts when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold

    return c;
  }

  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    uint256 c = a - b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);

    return c;
  }

  /**
  * @dev Divides two numbers and returns the remainder (unsigned integer modulo),
  * reverts when dividing by zero.
  */
  function mod(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b != 0);
    return a % b;
  }
}



library Address {
	function isContract(address account) internal view returns (bool) {
		uint size;
		assembly { size := extcodesize(account) }
		return size > 0;
	}

	function sendValue(address payable recipient, uint amount) internal {
		require(address(this).balance >= amount, "Address: insufficient balance");
		(bool success, ) = recipient.call{ value: amount }("");
		require(success, "Address: unable to send value, recipient may have reverted");
	}

	function functionCall(address target, bytes memory data) internal returns (bytes memory) {
	  return functionCall(target, data, "Address: low-level call failed");
	}

	function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		return functionCallWithValue(target, data, 0, errorMessage);
	}

	function functionCallWithValue(address target, bytes memory data, uint value) internal returns (bytes memory) {
		return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
	}

	function functionCallWithValue(address target, bytes memory data, uint value, string memory errorMessage) internal returns (bytes memory) {
		require(address(this).balance >= value, "Address: insufficient balance for call");
		require(isContract(target), "Address: call to non-contract");
		(bool success, bytes memory returndata) = target.call{ value: value }(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
		return functionStaticCall(target, data, "Address: low-level static call failed");
	}

	function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
		require(isContract(target), "Address: static call to non-contract");

		(bool success, bytes memory returndata) = target.staticcall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
		return functionDelegateCall(target, data, "Address: low-level delegate call failed");
	}

	function functionDelegateCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
		require(isContract(target), "Address: delegate call to non-contract");
		(bool success, bytes memory returndata) = target.delegatecall(data);
		return _verifyCallResult(success, returndata, errorMessage);
	}

	function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
		if (success) {
			return returndata;
		} else {
			if (returndata.length > 0) {
				assembly {
					let returndata_size := mload(returndata)
					revert(add(32, returndata), returndata_size)
				}
			} else {
				revert(errorMessage);
			}
		}
	}
}



contract MLM is Ownable {
    using SafeMath for uint256;
    using Address for address;
    string public NAME;
    
    
    struct userStruct {
        address[] referrers;    
        address[] referrals;   
        uint next_payment;     
        bool isRegitered;     
        bytes32 ref_link;    
    }

    mapping(address=>userStruct) users;
    mapping(bytes32=>address) ref_to_users;
    
    uint public min_paymnet = 100 ;              
    uint public min_time_to_add = 604800;         
    uint[] public reward_parts = [35, 25, 15, 15, 10]; 

    event RegisterEvent(address indexed user, address indexed referrer);
    event PayEvent(address indexed payer, uint amount, bool[3] levels);
    
    constructor() {
        NAME = "MLM project";
    }


	receive() external payable {
        require(!address(msg.sender).isContract());
        require(users[msg.sender].isRegitered);
        Pay(0x00);
    }

    function Pay(bytes32 referrer_addr) public payable {
        require(!address(msg.sender).isContract());
        require(msg.value >= min_paymnet);
        if(!users[msg.sender].isRegitered){
            _register(referrer_addr);
        }
        
        uint amount = msg.value;
        bool[3] memory levels = [false,false,false];
        for(uint i = 0; i < users[msg.sender].referrers.length; i++){
            address ref = users[msg.sender].referrers[i];
            if(users[ref].next_payment > block.timestamp){
                uint reward = amount.mul(reward_parts[i]).div(100);
                Address.sendValue(payable(ref), reward);
                levels[i] = true;
            }
        }
        
        address fomo_user = msg.sender;
        if(users[msg.sender].referrers.length>0 && users[users[msg.sender].referrers[0]].next_payment > block.timestamp)
            fomo_user = users[msg.sender].referrers[0];
            users[fomo_user].next_payment = block.timestamp.add(amount.mul(min_time_to_add).div(min_paymnet));
        if(block.timestamp > users[msg.sender].next_payment)
            users[msg.sender].next_payment = block.timestamp.add(amount.mul(min_time_to_add).div(min_paymnet));
        else 
            users[msg.sender].next_payment = users[msg.sender].next_payment.add(amount.mul(min_time_to_add).div(min_paymnet));        
        emit PayEvent(msg.sender, amount, levels);
    }
    
    
    function _register(bytes32 referrer_addr) internal {
        require(!users[msg.sender].isRegitered);
        address referrer = ref_to_users[referrer_addr];
        require(referrer!=msg.sender);
        if(referrer != address(0)){
            _setReferrers(referrer, 0);
        }
        users[msg.sender].isRegitered = true;
        _getReferralLink(referrer);
        emit RegisterEvent(msg.sender, referrer);
    }
    
    function _getReferralLink(address referrer) internal {
        do{
            users[msg.sender].ref_link = keccak256(abi.encodePacked(uint(msg.sender) ^  uint(referrer) ^ block.timestamp));
        } while(ref_to_users[users[msg.sender].ref_link] != address(0));
        ref_to_users[users[msg.sender].ref_link] = msg.sender;
    }
    
    function _setReferrers(address referrer, uint level) internal {
        if(users[referrer].next_payment > block.timestamp){
            users[msg.sender].referrers.push(referrer);
            if(level == 0){
                users[referrer].referrals.push(msg.sender);
            }
            level++;
        }
        if(level<3 && users[referrer].referrers.length>0)
            _setReferrers(users[referrer].referrers[0], level);
    }
    
    function GetUser() public view returns(uint, bool, bytes32) {
        return (
            users[msg.sender].next_payment,
            users[msg.sender].isRegitered,
            users[msg.sender].ref_link
        );
    }
    
    function GetReferrers() public view returns(address[] memory) {
        return users[msg.sender].referrers;
    }
    
    function GetReferrals() public view returns(address[] memory) {
        return users[msg.sender].referrals;
    }
    
    function widthdraw(address to, uint amount) public onlyOwner {
        Address.sendValue(payable(to), amount);
    }
}