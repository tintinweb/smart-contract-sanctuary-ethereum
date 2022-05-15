/**
 *Submitted for verification at Etherscan.io on 2022-05-15
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
    address public owner;
 
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
 
   /**
    * @dev Throws if called by any account other than the owner.
    */ 
   modifier onlyOwner(){
        require(msg.sender == owner, 'Can be called by owner only');
        _;
    }
 
   /**
    * @dev Allows the current owner to transfer control of the contract to a newOwner.
    * @param newOwner The address to transfer ownership to.
    */ 
   function transferOwnership(address newOwner) onlyOwner public{
        require(newOwner != address(0), 'Wrong new owner address');
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */ 
library SafeMath{
    function sub(uint a, uint b) internal pure returns (uint){
        assert(b <= a); 
        return a - b; 
    } 
  
    function add(uint a, uint b) internal pure returns (uint){ 
        uint c = a + b; assert(c >= a);
        return c;
    }
}

/**
 * @title PLTT token
 * @dev ERC20 Token implementation, with its own specific
 */
contract PlatinumClubToken is Ownable{
    using SafeMath for uint;
    
    // Tokent basic initialization
    string public constant name = "Platinum Club Apartments in Montenegro";
    string public constant symbol = "PCAM2";
    uint32 public constant decimals = 0;
    uint public totalSupply = 49;
    
    // Company is owned all tokens at start
    address public companyAddress = payable(address(0));
    // Transfers from addresses but the company are locked at start
    bool public transfersUnlocked = false;
    // Unlock transfers when this pool is empty (number of tokens required to be transfered to get unlocked)
    uint public unlockTransferRemain = 49;
    // Manually unlocked addresses
    mapping (address => bool) public unlocked;

    mapping(address => uint) balances;
    mapping (address => mapping (address => uint)) internal allowed;
    
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
    event TransfersUnlocked();

    /** 
     * @dev Allow transfers to company and send it all tokens.
     */
    constructor(){
        owner = msg.sender;
        companyAddress = msg.sender;

        // Transfer all tokens to company address
        balances[companyAddress] = totalSupply;
        emit Transfer(address(0), companyAddress, totalSupply);

        // Allow transfers to company
        unlockAddress(companyAddress, true);
    }
    
    /** 
     * @dev Gets the balance of the specified address.
     * @param _owner The address to query the the balance of.
     * @return An uint256 representing the amount owned by the passed address.
     */
    function balanceOf(address _owner) public view returns (uint){
        return balances[_owner];
    }
 
    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */ 
    function _transfer(address _to, uint _value) private returns (bool){
        require(msg.sender != address(0));
        require(_to != address(0));
        require(_to != address(this));
        require(transfersUnlocked || unlocked[msg.sender], 'Transfer is locked for you');
        require(_value > 0 && _value <= balances[msg.sender], 'Insufficient balance');

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        if(msg.sender == companyAddress){
            if(unlockTransferRemain > _value){
                unlockTransferRemain = unlockTransferRemain.sub(_value);
            }else{
                unlockTransferRemain = 0;
                transfersUnlocked = true;
                emit TransfersUnlocked();
            }
        }

        emit Transfer(msg.sender, _to, _value);

        return true; 
    }

    /**
     * @dev Transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */ 
    function transfer(address _to, uint _value) public returns (bool){
        return _transfer(_to, _value);
    } 
    
    /**
     * @dev Transfer several token for a specified addresses
     * @param _to The array of addresses to transfer to.
     * @param _value The array of amounts to be transferred.
     */ 
    function massTransfer(address[] memory _to, uint[] memory _value) public returns (bool){
        require(_to.length == _value.length);

        uint len = _to.length;
        for(uint i = 0; i < len; i++){
            if(!_transfer(_to[i], _value[i])){
                return false;
            }
        }
        return true;
    } 
    
    /**
     * @dev Transfer tokens from one address to another
     * @param _from address The address which you want to send tokens from
     * @param _to address The address which you want to transfer to
     * @param _value uint256 the amount of tokens to be transferred
     */ 
    function transferFrom(address _from, address _to, uint _value) public returns (bool){
        require(msg.sender != address(0));
        require(_from != address(0));
        require(_to != address(0));
        require(_to != address(this));
        require(_value <= allowed[_from][msg.sender]);
        require(transfersUnlocked || unlocked[_from], 'Transfer is locked for address');
        require(_value > 0 && _value <= balances[_from], 'Insufficient balance');

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
 
    /**
     * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _value The amount of tokens to be spent.
     */
    function approve(address _spender, uint _value) public returns (bool){
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
 
    /** 
     * @dev Function to check the amount of tokens that an owner allowed to a spender.
     * @param _owner address The address which owns the funds.
     * @param _spender address The address which will spend the funds.
     * @return A uint256 specifying the amount of tokens still available for the spender.
     */
    function allowance(address _owner, address _spender) public view returns (uint){
        return allowed[_owner][_spender]; 
    } 
 
    /**
     * @dev Increase approved amount of tokents that could be spent on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _addedValue The amount of tokens to be spent.
     */
    function increaseApproval(address _spender, uint _addedValue) public returns (bool){
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]); 
        return true; 
    }
 
    /**
     * @dev Decrease approved amount of tokents that could be spent on behalf of msg.sender.
     * @param _spender The address which will spend the funds.
     * @param _subtractedValue The amount of tokens to be spent.
     */
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool){
        uint oldValue = allowed[msg.sender][_spender];
        if(_subtractedValue > oldValue){
            allowed[msg.sender][_spender] = 0;
        }else{
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }
    
    /**
     * @dev Emit new tokens and transfer from 0 to client address.
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */ 
    function mint(address _to, uint _value) onlyOwner public{
        require(_to != address(0));
        require(_to != address(this));
        require(_value > 0);
        
        totalSupply = totalSupply.add(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(address(0), _to, _value);
    }
    
    /**
     * @dev Burn tokens at some address.
     * @param _from The address where the tokens should be burned down.
     * @param _value The amount to be burned.
     */ 
    function burn(address _from, uint _value) onlyOwner public{
        require(_from != address(0));
        require(_from != address(this));
        require(_value > 0 && _value <= balances[_from], 'Insufficient balance');

        totalSupply = totalSupply.sub(_value);
        balances[_from] = balances[_from].sub(_value);

        emit Transfer(_from, address(0), _value);
    }

    /** 
     * @dev Manually unlock transfers from any address.
     * @param _addr Allowed address
     * @param status Unlock status: true = unlocked, false = locked
     */
    function unlockAddress(address _addr, bool status) onlyOwner public{
        unlocked[_addr] = status;
    }
  
    /** 
     * @dev Change company address. Be sure you have transferred tokens first.
     * @param _addr New company address
     */
    function setCompanyAddress(address _addr) onlyOwner public{
        companyAddress = _addr;
    }
  
    /** 
     * @dev Set lock flag manually.
     * @param isLocked Are transfers locked? true = locked, false = unlocked
     */
    function setLockState(bool isLocked) onlyOwner public{
        transfersUnlocked = !isLocked;
    }
  
    /** 
     * @dev Set new amount of tokens to be transfered before unlock. Transfers are also locked.
     * @param amount New amount of tokens.
     */
    function setTransferRemain(uint amount) onlyOwner public{
        unlockTransferRemain = amount;
        setLockState(true);
    }
}