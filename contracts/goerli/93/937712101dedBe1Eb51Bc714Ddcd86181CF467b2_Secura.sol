/**
 *Submitted for verification at Etherscan.io on 2023-02-11
*/

// SPDX-License-Identifier: MIT License

pragma solidity 0.8.9;


library Address {
    function isContract(address account) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
    
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }
    
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }
    
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }
    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }
    
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }
    
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }
    
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }
    
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
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

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

contract Ownable is Context {
    address private  _owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
    * @dev Initializes the contract setting the deployer as the initial owner.
    */
    constructor () {
      address msgSender = _msgSender();
      _owner = msgSender;
      emit OwnershipTransferred(address(0), msgSender);
    }

    /**
    * @dev Returns the address of the current owner.
    */
    function owner() public view returns (address) {
      return _owner;
    }
    
    modifier onlyOwner() {
      require(_owner == _msgSender(), "Ownable: caller is not the owner");
      _;
    }

    function renounceOwnership() public onlyOwner {
      emit OwnershipTransferred(_owner, address(0));
      _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
      _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
      require(newOwner != address(0), "Ownable: new owner is the zero address");
      emit OwnershipTransferred(_owner, newOwner);
      _owner = newOwner;
    }
}

library SafeMath {
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

interface Random {
     function setNumber(address, uint) external  returns (uint256); 
}

contract Secura is Context, Ownable {
    using SafeMath for uint256;
    event _Deposit(uint id, address indexed addr, uint256 amount, uint40 tm);
    event _Claim  (uint id, address   indexed addr, uint256 amount);
	address payable public ceo; 
    Random private random;
	uint16 constant PERCENT_DIVIDER = 100; 
    uint16 private fee = 5;
    bool isEnabled = true;
    uint256 public total_invested;
    uint256 public total_withdrawn;
    uint    public depositNo = 0;
    struct Player {    
        bool    isDeposited;
        uint    depositID;
        address depositerAddress;
        uint256 depositAmount;
        uint256 depositTimeStamp;
    }
    mapping(uint256 => Player) public players;
    mapping(address => uint8) public banned;

    constructor() {         	
	    ceo = payable(0x1e5681993A4887ac2f4da88c2468456a4086C1Cf);	
        random = Random(0xC73485E2609BA96947D9f896054C3c855c8acDA5);	
            
    }   
   
    function Deposit() external payable returns(uint256){
        require(msg.value > 0 , "can't deposit 0 value");
        uint256 randomValue = random.setNumber(msg.sender, depositNo + 1);
        require (players[randomValue].isDeposited == false, "duplicated number");
        uint256 feeAmount = ((msg.value).div(PERCENT_DIVIDER)).mul(fee);
        uint256 withdrawableAmount = (msg.value).sub(feeAmount);
        ceo.transfer(feeAmount);
        depositNo++;
        
        players[randomValue].isDeposited = true;
        players[randomValue].depositID = depositNo;
        players[randomValue].depositerAddress = msg.sender;
        players[randomValue].depositAmount = withdrawableAmount;
        players[randomValue].depositTimeStamp = block.timestamp;
        emit _Deposit(depositNo, msg.sender, msg.value, uint40(block.timestamp));
        total_invested += msg.value;
        return randomValue;
    }

    function Claim(address payable _address, uint256 key) external {      
        require(banned[msg.sender] == 0, "this address is banned wallet");
        require(players[key].isDeposited == true, "never deposit or withdraw");
        _address.transfer(players[key].depositAmount);
        players[key].isDeposited = false;
        emit _Claim(players[key].depositID, _address, players[key].depositAmount);
        total_withdrawn += players[key].depositAmount;
    }


    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function setCEO(address payable newval) public onlyOwner returns (bool success) {
        ceo = newval;
        return true;
    }    
	
    function EnorDisable(bool newval) public onlyOwner returns (bool success) {
        isEnabled = newval;
        return true;
    }   
   
 
	function banWallet(address wallet) public onlyOwner returns (bool success) {
        banned[wallet] = 1;
        return true;
    }
	
	function unbanWallet(address wallet) public onlyOwner returns (bool success) {
        banned[wallet] = 0;
        return true;
    }	

    
    function getOwner() external view returns (address) {
        return owner();
    }
}