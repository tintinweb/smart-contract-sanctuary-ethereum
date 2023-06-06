/**
 *Submitted for verification at Etherscan.io on 2023-06-05
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.4.17;


contract SafeMath {
    function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}



contract TokenERC20 is SafeMath {

    // Public variables of token
    string public name;
    string public symbol;
    uint8 public decimals = 6;
    uint256 public totalSupply;
    

    mapping(address => uint256) public balances;
    mapping(address => bool) public isBlackListed;
    
    mapping(address => mapping (address => uint256)) public allowed;


    event AddedBlackList(address _user);

    event RemovedBlackList(address _user);

    event DestroyedBlackFunds(address _blackListedUser, uint256 _balance);

    event Redeem(uint256 amount);
     // Called if contract ever adds fees
    event Params(uint256 feeBasisPoints, uint256 maxFee);
    
    event Transfer(address indexed from, address indexed to, uint256 tokens);
    // This notifies clients about the amount burnt  
    
    event Approval(address indexed tokenOwner, address indexed spender, uint256 tokens);
    

    constructor(uint256 _totalSupply, 
                string memory tokenName, 
                string memory tokenSymbol)
     public{
         totalSupply = _totalSupply *10^6;
         name = tokenName;
         symbol = tokenSymbol;       
     }


    function balanceOf(address tokenOwner) public view returns (uint256 balance){
        return balances[tokenOwner];
   
    }

     // Internal transfer, only can be called by hid contract
    function advanceTransfer(address from, address to, uint256 tokens) internal{
        require(to != address(0));
        require(balances[from] >= tokens);
        require(balances[to] + tokens >= balances[to]);
        require(!isBlackListed[from]);
        require(!isBlackListed[to]);
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
    }

     /** 
    * Transfer tokens.
    *@param 'to' The address of the recipient.
    *@param 'tokens' to send.
    */
    function _transfer(address to, uint256 tokens) public returns (bool success){
        require(tokens <= balances[msg.sender]);
        require(to != address(0));
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        return true;
    }

    
    
    /**
     * Set allowance for other address.
     * 
     * Allows `spender` to spend no more than `tokens` tokens in your behalf. 
     * 
     * @param spender The address authorized to spend. 
     * @param tokens the max amount they can spend .
     */  
    function approve(address spender, uint256 tokens) public  
        returns (bool success) {  
        allowed[msg.sender][spender] = tokens;  
        emit Approval(msg.sender, spender, tokens);  
        return true;  
    }
    /**
    * Set allowance for other address and notify.
    *
    * Allows 'spender' to spend not more than 'tokens'then ping the contract about it.
    *@param 'spender' the address authorized to spend..
    *@param 'tokens' the max amount they can spend.
    *@param 'data' some extra information to send to the approved contract.
    */
    function approveAndCall(address spender, uint256 tokens, bytes data) public returns (bool success) {
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        ApproveAndCallFallBack(spender).receiveApproval(msg.sender, tokens, this, data);
        return true;
    } 

}

// Contract function to receive approval and execute function in one call.
contract ApproveAndCallFallBack{
    function receiveApproval(address from, uint256 tokens, address _value, bytes data) public;
}


/**The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed from, address indexed to);
    
    constructor() public {
        owner = msg.sender;
    }

    /**
      * @dev Throws if called by any account other than the owner.
      */
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }
    function transferOwnership (address _newOwner) public onlyOwner{
        newOwner = _newOwner;
    }
    function acceptOwnership() public{
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}


/**
 * @title Pausable
 * @dev Base contract this allows an emergency stop mechanism .
 */
contract Pausable is Owned {
  event Pause();
  event Unpause();

  bool public paused = false;


  /**
   * @dev Modifier to make a function callable only when the contract is not paused.
   */
  modifier whenNotPaused() {
    require(!paused);
    _;
  }

  /**
   * @dev Modifier to make a function callable only when the contract is paused.
   */
  modifier whenPaused() {
    require(paused);
    _;
  }

  /**
   * @dev called by the owner to pause, triggers stopped state
   */
  function pause() onlyOwner whenNotPaused public {
    paused = true;
   emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() onlyOwner whenPaused public {
    paused = false;
    emit Unpause();
  }
}




contract VoltrexGold is TokenERC20, Pausable {  
   
    event Transfer(address indexed from, address indexed to, uint256 tokens);

    
    /* Initializes contract with initial supply tokens to the creator of the contract*/
    constructor(
        uint256 _totalSupply,
        string memory tokenName,
        string memory tokenSymbol
    ) TokenERC20(_totalSupply, tokenName, tokenSymbol) public{
           
        
            balances[owner] = _totalSupply;

            emit Transfer(address(0), owner, _totalSupply);
        
    }

    

    function tSupply() public view returns (uint){
            return totalSupply - balances[address(0)];
    }

    function balanceOf(address tokenOwner) public view returns (uint256 balance){
        return balances[tokenOwner];
    }

     /** 
    * Transfer tokens.
    *@param 'to' The address of the recipient.
    *@param 'tokens' to send.
    */
    function transfer(address to, uint256 tokens) public whenNotPaused {
        require(tokens <= balances[msg.sender]);
        require(to != address(0));
        require(!isBlackListed[msg.sender]);
        balances[msg.sender] = safeSub(balances[msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
    }

    /** 
     * Transfer tokens from other address 
     * 
     * Send `tokens` tokens to `to` on behalf of `_from` 
     * 
     * @param from The address of the sender 
     * @param to The address of the recipient 
     * @param tokens the amount to send 
     */  
    function transferFrom(address from, address to, uint256 tokens) public whenNotPaused {
        require(!isBlackListed[from]);
        balances[from] = safeSub(balances[from], tokens);
        allowed[from][msg.sender] = safeSub(allowed[from][msg.sender], tokens);
        balances[to] = safeAdd(balances[to], tokens);
        emit Transfer(from, to, tokens);
    }
    

    /** 
     * Destroy tokens 
     * 
     * Remove `tokens` tokens from the system irreversibly 
     * 
     * @param tokens the amount of money to burn 
     */
    function burn(address account, uint256 tokens) public onlyOwner {  
        require(account != 0); 
        require(tokens <= balances[account]);      
        totalSupply = safeSub(totalSupply, tokens);
        balances[account] = safeSub(balances[account], tokens);
        emit Transfer(account, address(0), tokens);
    }
 
     /** 
     * Destroy tokens from other account 
     * 
     * Remove `tokens` tokens from the system irreversibly on behalf of `from`. 
     * 
     * @param account the address of the sender 
     * @param tokens the amount of money to burn 
     */  
    function burnFrom(address account, uint256 tokens) public onlyOwner {  
        require(tokens <= allowed[account][msg.sender]);            
        allowed[account][msg.sender] = safeSub(allowed[account][msg.sender], tokens);             
        burn(account, tokens); 
    } 

    // Redeem tokens.
    // These tokens are withdrawn from the owner address
    // if the balance must be enough to cover the redeem
    // or the call will fail.
    // @param _amount Number of tokens to be issued
    function redeem(uint256 tokens) public onlyOwner {
        require(totalSupply >= tokens);
        require(balances[owner] >= tokens);

        totalSupply -= tokens;
        balances[owner] -= tokens;
       emit Redeem(tokens);
    }
   
   
    /// @notice Create `mintedAmount` tokens and send it to `target`  
    /// @param target Address to receive the tokens  
    /// @param mintedAmount the amount of tokens it will receive  
    function mintToken(address target, uint256 mintedAmount) public onlyOwner {  
        balances[target] += mintedAmount;  
        totalSupply += mintedAmount;  
        emit Transfer(address(0), address(this), mintedAmount);  
        emit Transfer(address(this), target, mintedAmount);  
    }

    

    /** 
     * Set allowance for other address 
     *  
    */
    function allowance(address tokenOwner, address spender) public view returns(uint256){
        return allowed[tokenOwner][spender];
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool success){
        require(spender != address(0));
        allowed[msg.sender][spender] = safeAdd(allowed[msg.sender][spender], addedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool success){
        require(spender != address(0));
        allowed[msg.sender][spender]=safeSub(allowed[msg.sender][spender], subtractedValue);
        emit Approval(msg.sender, spender, allowed[msg.sender][spender]);
        return true;
    }
    
    /////// @notice Getters to allow the same blacklist to be used also by other contracts (including upgraded Tether) ///////
    function getBlackListStatus(address _maker) external constant returns (bool) {
        return isBlackListed[_maker];
    }

    // @notice To Add Blaclist users and preventing them from sending & receiving tokens.
    function addBlackList(address targetAccount) public onlyOwner {
        isBlackListed[targetAccount] = true;
       emit AddedBlackList(targetAccount);
    }
    // @notice To Remove Blaclist users the from sending & receiving tokens.
    function removeBlackList(address targetAccount) public onlyOwner {
        isBlackListed[targetAccount] = false;
      emit RemovedBlackList(targetAccount);
    }

    function destroyBlackFunds (address _blackListedUser) public onlyOwner {
        require(isBlackListed[_blackListedUser]);
        uint256 dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        totalSupply -= dirtyFunds;
      emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
  
        
}