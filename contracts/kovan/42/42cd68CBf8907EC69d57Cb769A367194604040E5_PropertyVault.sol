// SPDX-License-Identifier: MIT
pragma solidity >=0.6.2 <0.8.0;

// upgradeable
import "./SafeMathUpgradeable.sol";
import "./Initializable.sol";

interface IERC20 {
  /**
   * @notice Gets the balance of the specified address     
   * @param owner The address from which the balance will be retrieved
   */    
  function balanceOf(address owner) external view returns (uint256 balance);    

  /**
   * @notice Transfer `amount` tokens from `msg.sender` to `dst`
   * @param dst The address of the destination account
   * @param amount The number of tokens to transfer   
   */
  function transfer(address dst, uint256 amount) external returns (bool success);
}

/**
 * @notice Whitelist interface for Compliance Registry
 *         
 *        Glossary :
 *        _trustedIntermediary the reference trusted intermediary of the user. 
 *        _userId the userId of the user.
 *        _attributeKeys storage for the token ids we want to whitelist, I am assuming its for token ids.
 *        _attributeValues storage for the token values user is whitelisted for, I am assuming its the allowance.
 *
 */
interface IWhitelist {

  // get userId
  function userId(address[] calldata _trustedIntermediaries, address _address) external view returns (uint256, address);
  // access one user attribute or token whitelist
  function attribute(address _trustedIntermediary, uint256 _userId, uint256 _key) external view returns (uint256);
  // access multiple user attributes or multiple tokens on whitelist
  function attributes(address _trustedIntermediary, uint256 _userId, uint256[] calldata _keys) external view returns (uint256[] memory);
  
  // register user
  function registerUser(address _address, uint256[] calldata _attributeKeys, uint256[] calldata _attributeValues) external;
  // update user attributes
  function updateUserAttributes(uint256 _userId, uint256[] calldata _attributeKeys, uint256[] calldata _attributeValues) external;
  // update users attributes
  function updateUsersAttributes(uint256[] calldata _userIds, uint256[] calldata _attributeKeys, uint256[] calldata _attributeValues) external;

  // attach address to existing userId
  function attachAddress(uint256 _userId, address _address) external;
  // attach addresses to existing userIds
  function attachAddresses(uint256[] calldata _userIds, address[] calldata _addresses) external;
  // detach address
  function detachAddress(address _address) external;
  // detach addresses
  function detachAddresses(address[] calldata _addresses) external;
}

/**
 * PropertyVault is a vault which contains ERC-20 tokens within the inventory.
 */
contract PropertyVault is Initializable {
  
  using SafeMathUpgradeable for uint256;
  
  /**
   * @notice Lock vault from use.
   */
  bool private lockVault;

  /**
   * @notice Vault Depositor address.
   */
  address private currentDepositor;

  /**
   * @notice Vault Compliance Registry address.
   */
  address private complianceRegistry;

  /**
   * @notice Token registry index, tracks total tokens in registry.
   */
  uint private tokenIndex;

  struct TokenRef {
    uint256 tokenId;
    bool held;
  }
  
  /**
   * @notice Investor struct to manage token holdings per investor.
   */
  struct Investor {
    mapping(uint256 => TokenRef) tokens; // token-ids with boolean flag indicating true or false
    uint nonce; // only increments to search for older token balances even at 0.
  }

  // investor references
  mapping(address => Investor) private investors;

  // tokens references registry (token id , address)
  mapping(uint256 => address) private tokenRegistry;

  // balances of credits by token address
  mapping(address => mapping(address => uint256)) private balances;

  // Emitted when the depositor address value changes to a new address.
  event DepositorTransferred(address indexed previousDepositor, address indexed newDepositor);

  // Emitted when the registry address value changes to a new address.
  event RegistryTransferred(address indexed previousRegistrar, address indexed newRegistrar);

  // Emitted when the recipient withdraws
  event Withdrawn(address indexed recipient, uint256 amount);

  // Emitted when the recipient withdraw ends in error
  event WithdrawnError(address indexed recipient, uint256 amount);

  /**
   * @dev Throws if called by any account other than the depositor.
   */
  modifier onlyDepositor() {
    require(depositor() == msg.sender, "Depositor: caller is not the depositor");
    _;
  }

  /**
   * @dev Upgradeable Implementation of Constructor. Called once from deployProxy.
   * @param _depositor Depositor address.
   * @param _complianceRegistry Administrative address which manages whitelisting.
   */
  function init(address _depositor, address _complianceRegistry) public {
    // depositor
    currentDepositor = _depositor;

    // compliance 
    complianceRegistry = _complianceRegistry;

    // unlock vault
    lockVault = false;

    // token index
    tokenIndex = 0;

    emit DepositorTransferred(address(0), currentDepositor);
  }

  /**
   * @dev Returns the address of the current owner.
   */
  function depositor() public view virtual returns (address) {
    return currentDepositor;
  }

  /**
   * @dev Returns the address of the current compliance registry.
   */
  function registry() public view virtual returns (address) {
    return complianceRegistry;
  }

  /**
   * @dev Transfers ownership of the contract to a new account (`newDepositor`).
   * Can only be called by the current depositor.
   */
  function transferDepositor(address newDepositor) public virtual onlyDepositor {
    require(newDepositor != address(0), "Depositor: new owner is zero address");
    emit DepositorTransferred(currentDepositor, newDepositor);
    currentDepositor = newDepositor;
  }

  /**
   * @dev Transfers compliance registry of the contract to a new compliance registry contract address (`newRegistry`).
   * Can only be called by the current depositor.
   */
  function transferRegistry(address newRegistry) public virtual onlyDepositor {
    require(newRegistry != address(0), "Depositor: new registry is zero address");
    emit RegistryTransferred(complianceRegistry, newRegistry);
    complianceRegistry = newRegistry;
  }

  /**
   * @notice Token Registry
   */

  /**
   * @dev Get token index. How many tokens are registered.
   */
  function getTokenIndex() public view returns (uint256) {
    return tokenIndex;
  }

  /**
   * @dev Add token to token registry.
   * @param _tokenId Token id for the token registration.
   * @param _tokenAddress Token address for the registered token.
   */
  function addToken(uint256 _tokenId, address _tokenAddress) public onlyDepositor returns (bool added) {
    require(_tokenId != 0, "tokenId must not be zero");
    tokenRegistry[_tokenId] = _tokenAddress;
    uint256 newTotal;
    (added, newTotal) = tokenIndex.tryAdd(1); // safe add 
    tokenIndex = newTotal;
  }

  /**
   * @dev Remove token from token registry.
   * @param _tokenId Token id for the token registration.
   */
  function removeToken(uint256 _tokenId) public onlyDepositor returns (bool removed) {
    require(_tokenId != 0, "tokenId must not be zero");
    tokenRegistry[_tokenId] = address(0);
    removed = true;
  }

  /**
   * @dev Add array of tokens to token registry.
   * @param _tokenIds Token ids for the token registration.
   * @param _tokenAddresses Token addresses for token registration.
   */
  function addTokens(uint256[] memory _tokenIds, address[] memory _tokenAddresses) public onlyDepositor returns (bool completed) {
    require(_tokenIds.length == _tokenAddresses.length, "argument lengths are inconsistent");
    uint len = _tokenAddresses.length;
    for(uint i=0; i< len; i++) {
      require(addToken(_tokenIds[i], _tokenAddresses[i]), "error adding token to tokenRegistry");
    }
    completed = true;
  }

  /**
   * @dev Remove array of tokens from token registry.
   * @param _tokenIds Token ids to de-register.
   */
  function removeTokens(uint256[] memory _tokenIds) public onlyDepositor returns (bool completed) {
    uint len = _tokenIds.length;
    for(uint i=0; i< len; i++) {
      require(removeToken(_tokenIds[i]), "error removing token from tokenRegistry");
    }
    completed = true;
  }

  /**
   * @dev Retrieve token address by token id.
   * @param _tokenId Token id reference to retrieve.
   */
  function getTokenAddress(uint256 _tokenId) public view returns(address) {
    return tokenRegistry[_tokenId];
  }

  function getRecipientTokenRef(address _recipient, uint256 _tokenId) public view returns(uint256, bool) {
    TokenRef memory ref = investors[_recipient].tokens[_tokenId];
    return (ref.tokenId, ref.held);
  }

  /**
   * @dev Retrieve collection of token ids for a given user.
   * @param _recipient Ethereum address of user we want to validate.
   */
  function getRecipientTokenIds(address _recipient) public view returns (uint256[] memory tids) {
    uint nonce = investors[_recipient].nonce;
    tids = new uint256[](nonce);
    // get token tids
    for(uint i=0; i < nonce; i++) {
      TokenRef memory tokenRef = investors[_recipient].tokens[i];
      (uint256 tid,) = getRecipientTokenRef(_recipient, tokenRef.tokenId);
      tids[i] = tid;
    }
  }

  // add token, init nonce and held.
  function addRecipientToken(address _recipient, uint256 _tokenId) public {
    require(investors[_recipient].tokens[_tokenId].tokenId != _tokenId);
    investors[_recipient].tokens[_tokenId] = TokenRef({tokenId: _tokenId, held: true});
    
    (, uint newTotal) = investors[_recipient].nonce.tryAdd(1); // safe add 
    investors[_recipient].nonce = newTotal;
  }

  /**
   * @notice Investor Helpers
   */
  function getInvestorNonce(address _recipient) public view returns (uint nonce) {
    Investor memory inv = investors[_recipient];
    nonce = inv.nonce;
  }

  /**
   * @notice Helpers
   */

  /**
   * @notice Balances
   */

  /**
   * @dev Returns the cumulative balance for an account or 0 if invalid token address.
   * @param _token Token address receiving credit.
   * @param _recipient Recipient balance of address receiving credit.
   */
  function balanceOf(address _token, address _recipient) public view returns (uint256) {
    // test invalid
    if(_token != address(0)) {
      // parent/top level balance
      return balances[_token][_recipient];
    } else {
      return 0;
    }
  }

  /**
   * @dev Get all the balances for a given set of token ids.
   * @param _recipient Recipient address for balances.
   */
  function getBalances(address _recipient, uint256[] memory _tokenIds) public view returns (uint256[] memory bals) {
    uint len = _tokenIds.length;
    bals = new uint256[](len);
    // get token ids
    for(uint i=0; i < len; i++) {
      uint256 _tokenId = _tokenIds[i];
      address _token = getTokenAddress(_tokenId);
      bals[i] = balanceOf(_token, _recipient);
    }
    return bals;
  }  

  /**
   * @notice Private Balances 
   */

  /**
   * @dev Adds and returns the cumulative balance for an account.
   * @param _token Token address receiving credit.
   * @param _recipient Recipient balance of address receiving credit.
   * @param _amount Amount to increase the recipient balance receiving credit.
   */
  function _addBalance(address _token, address _recipient, uint256 _amount) internal returns (uint256 newBal) {
    require(_amount > 0, "amount must be non-zero");
    (, newBal) = balances[_token][_recipient].tryAdd(_amount);
    balances[_token][_recipient] = newBal;
  }
  
  /**
   * @dev Subtracts and returns the cumulative balance for an account.
   * @param _token Token address subtracting credit.
   * @param _recipient Recipient balance of address subtracting credit.
   * @param _amount Amount to subtract from the recipient.
   */
  function _subBalance(address _token, address _recipient, uint256 _amount) internal returns (uint256 newBal) {
    require(_amount > 0, "amount must be non-zero");
    (, newBal) = balances[_token][_recipient].trySub(_amount);
    balances[_token][_recipient] = newBal;
  }

  /**
   * @notice Lockable 
   */

  /**
   * @dev Unlock the vault.
   */
  function unlock() public onlyDepositor {
    lockVault = false;
  }

  /**
   * @dev Lock the vault. Disables the withdrawals.
   */
  function lock() public onlyDepositor {
    lockVault = true;
  }

  /**
   * @dev Check if contract is locked for withdrawals.
   */
  function isLocked() public view returns (bool) {
    return lockVault;
  }


  /**
   * @notice Whitelist (Compliance Registry)
   */

  /**
   * @dev `PropertyVault.getUserId` retrieves the MT Pelerin Compliance Registry userId.
   * @param _trustedIntermediaries Array of Ethereum addresses related to the user.
   * @param _recipient Ethereum address to retrieve from the compliance service.
   */ 
  function getUserId(address[] memory _trustedIntermediaries, address _recipient) public view returns (uint256 userId) {
    (userId,) = IWhitelist(complianceRegistry).userId(_trustedIntermediaries, _recipient);
  }

  /**
   * @dev `PropertyVault.isWhitelisted` checks the MT Pelerin Compliance Registry.
   * @param _trustedIntermediaries Array of Ethereum addresses related to the user.
   * @param _recipient Ethereum address to validate against the compliance service.
   */ 
  function isWhitelisted(address[] memory _trustedIntermediaries, address _recipient) public view returns (bool whitelisted) {
    (uint256 userId,) = IWhitelist(complianceRegistry).userId(_trustedIntermediaries, _recipient);
    if(userId > 0) { 
      whitelisted = true;
    } else {
      whitelisted = false;
    }
  }

  /**
   * @dev `PropertyVault.whitelist` allows a recipient to pay for their own transaction.
   */
  function whitelist(address payable _recipient, uint256[] memory _tokens, uint256[] memory _whitelistValues) public returns (bool whitelisted) {
    IWhitelist(complianceRegistry).registerUser(_recipient, _tokens, _whitelistValues);
    whitelisted = true;
  }

  /**
   * @dev `PropertyVault.whitelistUpdate` allows a recipient to update their own whitelist values.
   */
  function whitelistUpdate(uint256 _userId, uint256[] memory _tokenIds, uint256[] memory _whitelistValues) public returns (bool updated) {
    // check existing attributes 
    IWhitelist(complianceRegistry).updateUserAttributes(_userId, _tokenIds, _whitelistValues);
    updated = true;
  }

  /**
   * @dev `PropertyVault.status` will return the whitelist status for a given token id.
   * @param _trustedIntermediary Ethereum address of the trusted intermediary you want to validate against.
   * @param _userId ComplianceRegistry user id to retrieve the latest values.
   * @param _tokenId Token id reference registered with the Compliance Registry.
   */
  function status(address _trustedIntermediary, uint256 _userId, uint256 _tokenId) public view returns (uint256) {
    // get token id whitelist status
    return IWhitelist(complianceRegistry).attribute(_trustedIntermediary, _userId, _tokenId);
  }

  /**
   * @dev `PropertyVault.statusForKeys` will return the whitelist status for a given token ids.
   * @param _trustedIntermediary Ethereum address of the trusted intermediary you want to validate against.
   * @param _userId ComplianceRegistry user id to retrieve the latest values.
   * @param _tokenIds Token id references registered with the Compliance Registry.
   */
  function statusForKeys(address _trustedIntermediary, uint256 _userId, uint256[] memory _tokenIds) public view returns (uint256[] memory) {
    // get status for multiple token ids
    return IWhitelist(complianceRegistry).attributes(_trustedIntermediary, _userId, _tokenIds);
  }

  /**
   * @dev `PropertyVault.attachAddress` will attach an address to the whitelist for a given root registered address.
   * @param _address Ethereum address to register with the Compliance Registry.
   * @param _newAddress Ethereum address to aggregate to the Compliance Registry.
   */
  function attachAddress(uint256 _userId, address payable _address, address _newAddress) public returns (bool attached) {
    require(msg.sender == _address, "msg.sender must equal argument address");
    // attach address to user id
    IWhitelist(complianceRegistry).attachAddress(_userId, _newAddress);
    attached = true;
  }

  /**
   * @dev `PropertyVault.detachAddress` will detach an address from the whitelist for a given address.
   * @param _address Ethereum address which owns the _targetAddress, to de-register from the Compliance Registry.
   * @param _targetAddress Ethereum address to de-register from the Compliance Registry.
   */
  function detachAddress(address payable _address, address _targetAddress) public returns (bool detached) {
    require(msg.sender == _address, "msg.sender must equal argument address");
    // detach address from registry
    IWhitelist(complianceRegistry).detachAddress(_targetAddress);
    detached = true;
  }

  /**
   * @notice Deposits 
   */

  /**
   * @dev `PropertyVault.depositAccount` which deposits value for a given recipient by token.
   * @param _tokenId Token id receiving credit.
   * @param _recipient Parent recipient account receiving the deposit.
   * @param _amount Amount of value for the deposit.
   */
  function depositAccount(uint256 _tokenId, address _recipient, uint256 _amount) public onlyDepositor returns (bool deposited) {
    require(_tokenId != 0, "deposit error from the zero token id");
    require(_recipient != address(0), "deposit error from the zero recipient address");
    require(_amount > 0, "amount must be non-zero");
    
    address _token = getTokenAddress(_tokenId);

    // update top level balance
    _addBalance(_token, _recipient, _amount);

    // update token holdings, add to their token total
    // if the requested slot is not 0
    if(investors[_recipient].tokens[_tokenId].tokenId == 0) {
      // add token to holdings
      addRecipientToken(_recipient, _tokenId);
    }

    deposited = true;
  }

  /**
   * @dev `PropertyVault.depositBatch` delivers batch of deposits.
   */
  function depositBatch(uint256[] memory _tokenIds, address[] memory _recipients, uint256[] memory _amounts) public onlyDepositor returns (bool deposited) {
    require (_recipients.length == _amounts.length, "deposit array(s) amounts length imbalance");
    
    // initialize deposits
    uint len = _recipients.length;
    for (uint i=0; i < len; i++) {
      // deposit
      require (depositAccount(_tokenIds[i], _recipients[i], _amounts[i]), "deposit error");
    }

    deposited = true;
  }


  /**
   * @notice Withdrawals
   */

  /**
   * @dev Withdraw an amount for a given token value.
   * @param _tokenId Valid token id reference.
   * @param _recipient Ethereum account who is withdrawing the funds.
   * @param _amount Amount to withdraw from account.
   */
  function withdraw(uint256 _tokenId, address payable _recipient, uint256 _amount) public {
    require (!lockVault, "vault locked error");
    require (msg.sender == _recipient, "must be owner to withdraw");
    require (_amount > 0, "non-zero amount provided");

    address _token = getTokenAddress(_tokenId);
    require (_amount <= balanceOf(_token, _recipient), "insufficient funds");

    // property token transfer 
    require (IERC20(_token).transfer(_recipient, _amount), "token transfer withdraw error");
    bool success;
    assembly {
      switch returndatasize()
      case 0 {                      // This is a non-standard ERC-20
        success := not(0)           // set success to true
      }
      case 32 {                     // This is a complaint ERC-20
        returndatacopy(0, 0, 32)
        success := mload(0)         // Set `success = returndata` of external call
      }
      default {                     // This is an excessively non-compliant ERC-20, revert.
        revert(0, 0)
      }
    }
    
    require(success, "token transfer failure");
    // execute debit from system once transaction has success with a returndatasize > 0, 
    // as if transaction fails we have not deducted from the internal ledger
    if(success) {
      // update balance to zero
      _subBalance(_token, _recipient, _amount);
      
      // emit withdraw in token value
      emit Withdrawn(msg.sender, _amount);
    } else {
      emit WithdrawnError(msg.sender, _amount);
    }
  }

  /**
   * @dev Withdraw all tokens from account by token id reference. Must be whitelisted to call this method.
   * @param _trustedIntermediaries Ethereum account reference, used to lookup where user data is stored.
   * @param _recipient Ethereum address of the recipient account.
   * @param _tokenIds Token id references to withdraw tokens.
   */
  function withdrawAll(address[] memory _trustedIntermediaries, address payable _recipient, uint256[] memory _tokenIds) public {
    require(msg.sender == _recipient, "must be owner to withdraw all tokens");
    
    // check if whitelisted by checking user id
    (uint256 userId,) = IWhitelist(complianceRegistry).userId(_trustedIntermediaries, _recipient);
    require(userId > 0, "user not whitelisted, no such user");
    
    // check attributes for token ids
    address _trustedIntermediary = _trustedIntermediaries[0]; // first element
    uint256[] memory statusKeys = statusForKeys(_trustedIntermediary, userId, _tokenIds);

    // get token addresses from tokenIds
    uint len = _tokenIds.length;
    for (uint i=0; i< len; i++) {
      // all tokens in whitelist = 1 for allowance to go through and withdraw
      if(statusKeys[i] == 1) {
        // allowed = false;
        uint _tokenId = _tokenIds[i];
        address _token = tokenRegistry[_tokenId];
        uint256 _amount = balanceOf(_token, _recipient);
        // withdraw recipient value
        if(_amount > 0) {
          withdraw(_tokenId, _recipient, _amount);
        }
      }
    }
  }

  /**
   * @dev Whitelist an account and token ids, then withdraw an amount a given set of tokenIds.
   * @param _trustedIntermediaries Ethereum account reference, used to lookup where user data is stored.
   * @param _recipient Ethereum address of the recipient account.
   * @param _tokenIds Token id references to whitelist.
   * @param _whitelistValues Binary values representing whitelisted 1 or not whitelisted 0.
   */
  function whitelistWithdrawAll(address[] memory _trustedIntermediaries, address payable _recipient, uint256[] memory _tokenIds, uint256[] memory _whitelistValues) public {
    require(msg.sender == _recipient, "must be owner to whitelist withdraw tokens");

    // check if whitelisted by checking user id
    (uint256 userId,) = IWhitelist(complianceRegistry).userId(_trustedIntermediaries, _recipient);

    // whitelist recipient
    if(userId == 0) {
      whitelist(_recipient, _tokenIds, _whitelistValues); // auto whitelist 
    } else {
      // update whitelist values
      whitelistUpdate(userId, _tokenIds, _whitelistValues); // update whitelist values
    }

    // withdraw tokens by tokenIds
    withdrawAll(_trustedIntermediaries, _recipient, _tokenIds);
  }

  /**
   * @notice Refunds
   */

  /**
   * @dev Refund a deposit by subtracting the amount from a recipient/child.
   */
  function refund(uint256 _tokenId, address _recipient, uint256 _amount) public onlyDepositor returns(bool) {
    require (_amount > 0, "non-zero amount error.");
    
    address _token = getTokenAddress(_tokenId);
    require (_amount > balances[_token][_recipient], "insufficient balance value for a refund");

    // find deposit id for a given recipient / child group
    uint256 newBal = _subBalance(_token, _recipient, _amount);

    balances[_token][_recipient] = newBal;

    return true;
  }

  /**
   * @dev Refund a batch of amounts from balances.
   */
  function refundBatch(uint256[] memory _tokenIds, address[] memory _recipients, uint256[] memory _amounts) public onlyDepositor returns (bool) {

    require (_recipients.length == _amounts.length, "refund array(s) amounts length imbalance");
    
    // initialize deposits
    uint len = _recipients.length;
    for (uint i=0; i < len; i++) {
      // refund
      require(refund(_tokenIds[i], _recipients[i], _amounts[i]), "refund batch error");
    }
    return true;
  }

  /**
   * @notice Exit 
   */

  /**
   * @dev Flush ERC20 token to provided recipient account by token address.
   */
  function flush(address _token, address payable _recipient) public payable onlyDepositor {
    uint256 balance = IERC20(_token).balanceOf(address(this));
    require (balance > 0, "zero token balance error");
    require (IERC20(_token).transfer(_recipient, balance), "token transfer withdraw error");
  }

}

// SPDX-License-Identifier: MIT

// solhint-disable-next-line compiler-version
pragma solidity >=0.4.24 <0.8.0;

import "./AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since a proxied contract can't have a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {UpgradeableProxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 */
abstract contract Initializable {

    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        require(_initializing || _isConstructor() || !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /// @dev Returns true if and only if the function is running in the constructor
    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.0 <0.8.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b > a) return (false, 0);
        return (true, a - b);
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) return 0;
        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");
        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: modulo by zero");
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        return a - b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryDiv}.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.6.2 <0.8.0;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        // solhint-disable-next-line avoid-low-level-calls, avoid-call-value
        (bool success, ) = recipient.call{ value: amount }("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain`call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
      return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data, string memory errorMessage) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(address target, bytes memory data, uint256 value, string memory errorMessage) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.call{ value: value }(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data, string memory errorMessage) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.staticcall(data);
        return _verifyCallResult(success, returndata, errorMessage);
    }

    function _verifyCallResult(bool success, bytes memory returndata, string memory errorMessage) private pure returns(bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                // solhint-disable-next-line no-inline-assembly
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