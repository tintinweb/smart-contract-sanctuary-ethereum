/**
 *Submitted for verification at Etherscan.io on 2022-10-17
*/

pragma solidity ^0.5.11;

/** @title A contract for issuing, redeeming and transfering SilaUSD StableCoin
* 
* @author www.silamoney.com
* Email: [email protected]
*
*/

/**Run
* @title SafeMath
* @dev Math operations with safety checks that revert on error
*/
 
library SafeMath{
    
  /**
  * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
  */
  
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    require(_b <= _a);
    uint256 c = _a - _b;

    return c;
  }

  /**
  * @dev Adds two numbers, reverts on overflow.
  */
  
  function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
    uint256 c = _a + _b;
    require(c >= _a);

    return c;
  }

}

/**
* @title Arrays
* @dev  overload array operations
*/

library Arrays{
    
  function arr(address _a) internal pure returns (address[] memory _arr) {
    _arr = new address[](1);
    _arr[0] = _a; 
  }

  function arr(address _a, address _b) internal pure returns (address[] memory _arr) {
    _arr = new address[](2);
    _arr[0] = _a; 
    _arr[1] = _b;
  }

  function arr(address _a, address _b, address _c) internal pure returns (address[] memory _arr) {
    _arr = new address[](3);
    _arr[0] = _a; 
    _arr[1] = _b; 
    _arr[2] = _c; 
  }

}

/**
* @title Ownable
* @dev The Ownable contract hotOwner and ColdOwner, and provides authorization control
* functions, this simplifies the implementation of "user permissions".
*/

contract Ownable{
    
    // hot and cold wallet addresses
    
    address public hotOwner = 0x0eBF7dccdA9AFE32431A329A8020E1237e127228;

    address public coldOwner = 0xD0A7B396d5304dBC318b42E03EB21c5B423d4Fd3;
    
    // event for ownership transfer
    
    event OwnershipTransferred(address indexed _newHotOwner, address indexed _newColdOwner, address indexed _oldColdOwner);

   /**
   * @dev Reverts if called by any account other than the hotOwner.
   */
   
    modifier onlyHotOwner() {
        require(msg.sender == hotOwner);
        _;
    }
    
   /**
   * @dev Reverts if called by any account other than the coldOwner.
   */
    
    modifier onlyColdOwner() {
        require(msg.sender == coldOwner);
        _;
    }
    
   /**
   * @dev Assigns new hotowner and coldOwner
   * @param _newHotOwner address The address which is a new hot owner.
   * @param _newColdOwner address The address which can change the hotOwner.
   */
    
    function transferOwnership(address _newHotOwner, address _newColdOwner) public onlyColdOwner {
        require(_newHotOwner != address(0));
        require(_newColdOwner!= address(0));
        hotOwner = _newHotOwner;
        coldOwner = _newColdOwner;
        emit OwnershipTransferred(_newHotOwner, _newColdOwner, msg.sender);
    }

}

/**
* @title EmergencyToggle
* @dev The EmergencyToggle contract provides a way to pause the contract in emergency
*/

contract EmergencyToggle is Ownable{
     
    // pause the entire contract if true
    bool public emergencyFlag; 

    // constructor
    constructor () public{
      emergencyFlag = false;                            
    }
  
    /**
    * @dev onlyHotOwner can can pause the usage of issue,redeem, transfer functions
    */
    
    function emergencyToggle() external onlyHotOwner {
      emergencyFlag = !emergencyFlag;
    }

}

/**
* @title Authorizable
* @dev The Authorizable contract can be used to authorize addresses to control silausd main
* functions, this will provide more flexibility in terms of signing trasactions
*/

contract Authorizable is Ownable, EmergencyToggle {
    using SafeMath for uint256;
      
    // map to check if the address is authorized to issue, redeem and betalist sila
    mapping(address => bool) authorized;

    // events for when address is added or removed 
    event AuthorityAdded(address indexed _toAdd);
    event AuthorityRemoved(address indexed _toRemove);
    
    // modifier allowing only authorized addresses and hotOwner to call certain functions
    modifier onlyAuthorized() {
        require(authorized[msg.sender] || hotOwner == msg.sender);
        _;
    }
    
   /**
   * @dev Function addAuthorized adds addresses that can betalist, transfer, issue and redeem
   * @param _toAdd address of the added authority
   */

    function addAuthorized(address _toAdd) public onlyHotOwner {
        require (!emergencyFlag);
        require(_toAdd != address(0));
        require(!authorized[_toAdd]);
        authorized[_toAdd] = true;
        emit AuthorityAdded(_toAdd);
    }
    
   /**
   * @dev Function RemoveAuthorized removes addresses that can betalist and transfer 
   * @param _toRemove address of the added authority
   */

    function removeAuthorized(address _toRemove) public onlyHotOwner {
        require (!emergencyFlag);
        require(_toRemove != address(0));
        require(authorized[_toRemove]);
        authorized[_toRemove] = false;
        emit AuthorityRemoved(_toRemove);
    }
    
   /**
   * @dev check the specified address is authorized to do sila transactions
   * @param _authorized The address to be checked for authority
   */
   
    function isAuthorized(address _authorized) external view returns(bool _isauthorized) {
        return authorized[_authorized];
    }
    
}

/**
* @title  Token is Betalist,Blacklist
*/
 
 contract Betalist is Authorizable {

    // maps for betalisted and blacklisted addresses
    mapping(address => bool) betalisted;
    mapping(address => bool) blacklisted;

    // events for betalist and blacklist
    event BetalistedAddress (address indexed _betalisted);
    event BlacklistedAddress (address indexed _blacklisted);
    event RemovedAddressFromBlacklist(address indexed _toRemoveBlacklist);
    event RemovedAddressFromBetalist(address indexed _toRemoveBetalist);

    // variable to check if betalist is required when calling several functions on smart contract
    bool public requireBetalisted;
 
    // constructor
    constructor () public {
        requireBetalisted = true;
    }
    
    // modifier to check acceptableTransactor addresses
    
    modifier acceptableTransactors(address[] memory addresses) {
        require(!emergencyFlag);
        if (requireBetalisted){
          for(uint i = 0; i < addresses.length; i++) require( betalisted[addresses[i]] );
        }
        for(uint i = 0; i < addresses.length; i++) {
          address addr = addresses[i];
          require(addr != address(0));
          require(!blacklisted[addr]);
        }
        _;
    }
    
    /**
    * @dev betaList the specified address
    * @param _toBetalist The address to betalist
    */
  
    function betalistAddress(address _toBetalist) public onlyAuthorized returns(bool) {
        require(!emergencyFlag);
        require(_toBetalist != address(0));
        require(!blacklisted[_toBetalist]);
        require(!betalisted[_toBetalist]);
        betalisted[_toBetalist] = true;
        emit BetalistedAddress(_toBetalist);
        return true;
    }
    
    /**
    * @dev remove from betaList the specified address
    * @param _toRemoveBetalist The address to be removed
    */
  
    function removeAddressFromBetalist(address _toRemoveBetalist) public onlyAuthorized {
        require(!emergencyFlag);
        require(_toRemoveBetalist != address(0));
        require(betalisted[_toRemoveBetalist]);
        betalisted[_toRemoveBetalist] = false;
        emit RemovedAddressFromBetalist(_toRemoveBetalist);
    }
    
    /**
    * @dev blackList the specified address
    * @param _toBlacklist The address to blacklist
    */

    function blacklistAddress(address _toBlacklist) public onlyAuthorized returns(bool) {
        require(!emergencyFlag);
        require(_toBlacklist != address(0));
        require(!blacklisted[_toBlacklist]);
        blacklisted[_toBlacklist] = true;
        emit BlacklistedAddress(_toBlacklist);
        return true;
    }
        
    /**
    * @dev remove from blackList the specified address
    * @param _toRemoveBlacklist The address to blacklist
    */
  
    function removeAddressFromBlacklist(address _toRemoveBlacklist) public onlyAuthorized {
        require(!emergencyFlag);
        require(_toRemoveBlacklist != address(0));
        require(blacklisted[_toRemoveBlacklist]);
        blacklisted[_toRemoveBlacklist] = false;
        emit RemovedAddressFromBlacklist(_toRemoveBlacklist);
    }
        
    /**
    * @dev    BlackList addresses in batches 
    * @param _toBlacklistAddresses array of addresses to be blacklisted
    */

    function batchBlacklistAddresses(address[] memory _toBlacklistAddresses) public onlyAuthorized returns(bool) {
        for(uint i = 0; i < _toBlacklistAddresses.length; i++) {
            bool check = blacklistAddress(_toBlacklistAddresses[i]);
            require(check);
        }
        return true;
    }
    
    /**
    * @dev    Betalist addresses in batches 
    * @param _toBetalistAddresses array of addresses to be betalisted 
    */

    function batchBetalistAddresses(address[] memory _toBetalistAddresses) public onlyAuthorized returns(bool) {
        for(uint i = 0; i < _toBetalistAddresses.length; i++) {
            bool check = betalistAddress(_toBetalistAddresses[i]);
            require(check);
        }
        return true;
    }
        
    /**
    * @dev check the specified address if isBetaListed
    * @param _betalisted The address to be checked for betalisting
    */
  
    function isBetalisted(address _betalisted) external view returns(bool) {
            return (betalisted[_betalisted]);
    }
    
    /**
    * @dev check the specified address isBlackListed
    * @param _blacklisted The address to be checked for blacklisting
    */

    function isBlacklisted(address _blacklisted) external view returns(bool) {
        return (blacklisted[_blacklisted]);
    }
    
}

/**
* @title  Token is token Interface
*/

contract Token{
    
    function balanceOf(address _owner) public view returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public  returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function allowance(address _owner, address _spender) public view returns (uint256 remaining);
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

/**
*@title StandardToken
*@dev Implementation of the basic standard token.
*/

contract StandardToken is Token, Betalist{
  using SafeMath for uint256;

    // maps to store balances and allowances
    mapping (address => uint256)  balances;
    
    mapping (address => mapping (address => uint256)) allowed;
    
    uint256 public totalSupply;
    
    /**
    * @dev Gets the balance of the specified address.
    * @return An uint256 representing the amount owned by the passed address.
    */
    
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

    /**
    * @dev Function to check the amount of tokens that an owner allowed to a spender.
    * @param _owner address The address which owns the funds.
    * @param _spender address The address which will spend the funds.
    * @return A uint256 specifying the amount of tokens still available for the spender.
    */
  
    function allowance(address _owner,address _spender)public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    /**
    * @dev Transfer token for a specified address
    * @param _to The address to transfer to.
    * @param _value The amount to be transferred.
    */

    function transfer(address _to, uint256 _value) public acceptableTransactors(Arrays.arr(_to, msg.sender)) returns (bool) {
        require(_value <= balances[msg.sender]);
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
  
    /**
    * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
    * Beware that changing an allowance with this method brings the risk that someone may use both the old
    * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
    * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
    * @param _value The amount of tokens to be spent.
    */
    
    function approve(address _spender, uint256 _value) public acceptableTransactors(Arrays.arr(_spender, msg.sender)) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
  
    /**
    * @dev Transfer tokens from one address to another
    * @param _from address The address which you want to send tokens from
    * @param _to address The address which you want to transfer to
    * @param _value uint256 the amount of tokens to be transferred
    */
    
    function transferFrom(address _from, address _to, uint256 _value) public acceptableTransactors(Arrays.arr(_from, _to, msg.sender)) returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

}

/**
*@title AuthroizeDeveloper
*@dev Implementation of the authorize developer contract to authorize developers 
* to control the users sila balance registered under an app
*/

contract AuthorizeDeveloper is StandardToken{
    
    // mapping to store authorization for DeveloperTransfer
    mapping(address => mapping(address => bool)) isAuthorizedDeveloper;
    
    // Events
    event SilaAuthorizedDeveloper (address indexed _developer, address indexed _user);
    event DeveloperTransfer (address indexed _developer, address indexed _from, address indexed _to, uint _amount);
    event SilaRemovedDeveloper (address indexed _developer, address indexed _user);
    event UserAuthorizedDeveloper (address indexed _developer, address indexed _user);
    event UserRemovedDeveloper (address indexed _developer, address indexed _user);

   /**
   * @dev silaAuthorizeDeveloper to transfer tokens on users behalf
   * @param _developer address The address which is allowed to transfer tokens on users behalf
   * @param _user address The address which developer want to transfer from
   */
    
    function silaAuthorizeDeveloper(address _developer, address _user) public acceptableTransactors(Arrays.arr(_developer, _user)) onlyAuthorized {
        require(!isAuthorizedDeveloper[_developer][_user]);
        isAuthorizedDeveloper[_developer][_user] = true;
        emit SilaAuthorizedDeveloper(_developer,_user);
    }
    
   /**
   * @dev user can Authorize Developer to transfer tokens on their behalf
   * @param _developer address The address which is allowed to transfer tokens on users behalf
   */
    
    function userAuthorizeDeveloper(address _developer) public acceptableTransactors(Arrays.arr(_developer, msg.sender)) {
        require(!isAuthorizedDeveloper[_developer][msg.sender]);
        isAuthorizedDeveloper[_developer][msg.sender] = true;
        emit UserAuthorizedDeveloper(_developer, msg.sender);
    }
    
   /**
   * @dev RemoveDeveloper allowed to transfer tokens on users behalf
   * @param _developer address The address which is allowed to transfer tokens on users behalf
   * @param _user address The address which developer want to transfer from
   */
    
    function silaRemoveDeveloper(address _developer, address _user) public onlyAuthorized {
        require(!emergencyFlag);
        require(_developer != address(0));
        require(_user != address(0));
        require(isAuthorizedDeveloper[_developer][_user]);
        isAuthorizedDeveloper[_developer][_user] = false;
        emit SilaRemovedDeveloper(_developer, _user);
    }
    
   /**
   * @dev userRemovDeveloper to remove the developer allowed to transfer sila
   * @param _developer, The address which is allowed to transfer tokens on users behalf
   */
    
    function userRemoveDeveloper(address _developer) public {
        require(!emergencyFlag);
        require(_developer != address(0));
        require(isAuthorizedDeveloper[_developer][msg.sender]);
        isAuthorizedDeveloper[_developer][msg.sender] = false;
        emit UserRemovedDeveloper(_developer,msg.sender);
    }
    
   /**
   * @dev developerTransfer for developer to transfer tokens on users behalf without requiring ethers in managed  ethereum accounts
   * @param _from address the address to transfer tokens from
   * @param _to address The address which developer want to transfer to
   * @param _amount the amount of tokens user wants to transfer
   */
    
    function developerTransfer(address _from, address _to, uint _amount) public acceptableTransactors(Arrays.arr(_from, _to, msg.sender)) {
        require(isAuthorizedDeveloper[msg.sender][_from]);
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit DeveloperTransfer(msg.sender, _from, _to, _amount);
        emit Transfer(_from, _to, _amount);
    }
    
   /**
   * @dev check if developer is allowed to transfer tokens on users behalf
   * @param _developer the address allowed to transfer tokens 
   * @param _for address The user address which developer want to transfer from
   */
    
    function checkIsAuthorizedDeveloper(address _developer, address _for) external view returns (bool) {
        return (isAuthorizedDeveloper[_developer][_for]);
    }

}

/**
*@title SilaUsd
*@dev Implementation for sila issue,redeem,protectedTransfer and batch functions
*/

contract SilaUsd is AuthorizeDeveloper{
    using SafeMath for uint256;
    
    // parameters for silatoken
    string  public constant name = "SILAUSD";
    string  public constant symbol = "SILA";
    uint256 public constant decimals = 18;
    string  public constant version = "2.0";
    
    // Events fired during successfull execution of main silatoken functions
    event Issued(address indexed _to, uint256 _value);
    event Redeemed(address indexed _from, uint256 _amount);
    event ProtectedTransfer(address indexed _from, address indexed _to, uint256 _amount);
    event GlobalLaunchSila(address indexed _launcher);
    event DestroyedBlackFunds(address _blackListedUser, uint _dirtyFunds);

   /**
   * @dev issue tokens from sila  to _to address
   * @dev only authorized addresses are allowed to call this function
   * @param _to address The address which you want to transfer to
   * @param _amount uint256 the amount of tokens to be issued
   */

   function issue(address _to, uint256 _amount) public acceptableTransactors(Arrays.arr(_to)) onlyAuthorized returns (bool) {
        totalSupply = totalSupply.add(_amount);
        balances[_to] = balances[_to].add(_amount);                 
        emit Issued(_to, _amount);                     
        return true;
    }
    
   /**
   * @dev redeem tokens from _from address
   * @dev onlyAuthorized  addresses can call this function
   * @param _from address is the address from which tokens are burnt
   * @param _amount uint256 the amount of tokens to be burnt
   */

    function redeem(address _from, uint256 _amount) public acceptableTransactors(Arrays.arr(_from)) onlyAuthorized returns(bool) {
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);   
        totalSupply = totalSupply.sub(_amount);
        emit Redeemed(_from, _amount);
        return true;
    }
    
   /**
   * @dev Transfer tokens from one address to another
   * @dev onlyAuthorized  addresses can call this function
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _amount uint256 the amount of tokens to be transferred
   */

    function protectedTransfer(address _from, address _to, uint256 _amount) public acceptableTransactors(Arrays.arr(_from, _to)) onlyAuthorized returns(bool) {
        require(_amount <= balances[_from]);
        balances[_from] = balances[_from].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
        emit ProtectedTransfer(_from, _to, _amount);
        emit Transfer(_from, _to, _amount);
        return true;
    }    
    
    /**
     * @dev destroy the funds of a blacklisted address
     * @param _blackListedUser the blacklisted user address for which the funds need to be destroyed
    */
    
    function destroyBlackFunds(address _blackListedUser) public onlyAuthorized {
        require(blacklisted[_blackListedUser]);
        uint dirtyFunds = balanceOf(_blackListedUser);
        balances[_blackListedUser] = 0;
        totalSupply = totalSupply.sub(dirtyFunds);
        emit DestroyedBlackFunds(_blackListedUser, dirtyFunds);
    }
    
    /**
    * @dev Launch sila for global transfer function to work as standard
    */
    
    function globalLaunchSila() public onlyHotOwner {
        require(!emergencyFlag);
        require(requireBetalisted);
        requireBetalisted = false;
        emit GlobalLaunchSila(msg.sender);
    }
    
    /**
    * @dev batchissue , isuue tokens in batches to multiple addresses at a time
    * @param _amounts The amount of tokens to be issued.
    * @param _toAddresses tokens to be issued to these addresses respectively
    */
    
    function batchIssue(address[] memory _toAddresses, uint256[]  memory _amounts) public onlyAuthorized returns(bool) {
        require(_toAddresses.length == _amounts.length);
        for(uint i = 0; i < _toAddresses.length; i++) {
            bool check = issue(_toAddresses[i],_amounts[i]);
            require(check);
        }
        return true;
    }
    
    /**
    * @dev batchredeem , redeem tokens in batches from multiple addresses at a time
    * @param _amounts array of amount of tokens to be redeemed.
    * @param _fromAddresses array of addresses from which tokens to be redeemed respectively
    */
    
    function batchRedeem(address[] memory  _fromAddresses, uint256[]  memory _amounts) public onlyAuthorized returns(bool) {
        require(_fromAddresses.length == _amounts.length);
        for(uint i = 0; i < _fromAddresses.length; i++) {
            bool check = redeem(_fromAddresses[i],_amounts[i]);
            require(check);
        }  
        return true;
    }
    
    /**
    * @dev batchTransfer, transfer tokens in batches between multiple addresses at a time
    * @param _fromAddresses tokens to be transfered to these addresses respectively
    * @param _toAddresses tokens to be transfered to these addresses respectively
    * @param _amounts The amount of tokens to be transfered
    */
    
    function protectedBatchTransfer(address[] memory _fromAddresses, address[]  memory _toAddresses, uint256[] memory  _amounts) public onlyAuthorized returns(bool) {
        require(_fromAddresses.length == _amounts.length);
        require(_toAddresses.length == _amounts.length);
        require(_fromAddresses.length == _toAddresses.length);
        for(uint i = 0; i < _fromAddresses.length; i++) {
            bool check = protectedTransfer(_fromAddresses[i], _toAddresses[i], _amounts[i]);
            require(check);
        }
        return true;
    } 
    
}