/**
 *Submitted for verification at Etherscan.io on 2022-01-29
*/

pragma solidity 0.4.24;


/**
 * @title ERC20Basic
 * @dev Simpler version of ERC20 interface
 * See https://github.com/ethereum/EIPs/issues/179
 */
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address _who) public view returns (uint256);
  function transfer(address _to, uint256 _value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}





/**
 * @title ERC20 interface
 * @dev see https://github.com/ethereum/EIPs/issues/20
 */
contract ERC20 is ERC20Basic {
  function allowance(address _owner, address _spender)
    public view returns (uint256);

  function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

  function approve(address _spender, uint256 _value) public returns (bool);
  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}



/**
 * @title Ownable
 * @dev The Ownable contract has an owner address, and provides basic authorization control
 * functions, this simplifies the implementation of "user permissions".
 */
contract Ownable {
  address public owner;


  event OwnershipRenounced(address indexed previousOwner);
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );


  /**
   * @dev The Ownable constructor sets the original `owner` of the contract to the sender
   * account.
   */
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

  /**
   * @dev Allows the current owner to relinquish control of the contract.
   * @notice Renouncing to ownership will leave the contract without an owner.
   * It will not be possible to call the functions with the `onlyOwner`
   * modifier anymore.
   */
  function renounceOwnership() public onlyOwner {
    emit OwnershipRenounced(owner);
    owner = address(0);
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    _transferOwnership(_newOwner);
  }

  /**
   * @dev Transfers control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function _transferOwnership(address _newOwner) internal {
    require(_newOwner != address(0));
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}










/**
 * @title ERC865Basic
 * @dev Simpler version of the ERC865 interface from https://github.com/adilharis2001/ERC865Demo
 * @author jsdavis28
 * @notice ERC865Token allows for users to pay gas costs to a delegate in an ERC20 token
 * https://github.com/ethereum/EIPs/issues/865
 */
 contract ERC865Basic is ERC20 {
     function _transferPreSigned(
         bytes _signature,
         address _from,
         address _to,
         uint256 _value,
         uint256 _fee,
         uint256 _nonce
     )
        internal;

     event TransferPreSigned(
         address indexed delegate,
         address indexed from,
         address indexed to,
         uint256 value);
}










/**
 * @title Basic token
 * @dev Basic version of StandardToken, with no allowances.
 */
contract BasicToken is ERC20Basic {
  using SafeMath for uint256;

  mapping(address => uint256) internal balances;

  uint256 internal totalSupply_;

  /**
  * @dev Total number of tokens in existence
  */
  function totalSupply() public view returns (uint256) {
    return totalSupply_;
  }

  /**
  * @dev Transfer token for a specified address
  * @param _to The address to transfer to.
  * @param _value The amount to be transferred.
  */
  function transfer(address _to, uint256 _value) public returns (bool) {
    require(_value <= balances[msg.sender]);
    require(_to != address(0));

    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

  /**
  * @dev Gets the balance of the specified address.
  * @param _owner The address to query the the balance of.
  * @return An uint256 representing the amount owned by the passed address.
  */
  function balanceOf(address _owner) public view returns (uint256) {
    return balances[_owner];
  }

}




/**
 * @title Standard ERC20 token
 *
 * @dev Implementation of the basic standard token.
 * https://github.com/ethereum/EIPs/issues/20
 * Based on code by FirstBlood: https://github.com/Firstbloodio/token/blob/master/smart_contract/FirstBloodToken.sol
 */
contract StandardToken is ERC20, BasicToken {

  mapping (address => mapping (address => uint256)) internal allowed;


  /**
   * @dev Transfer tokens from one address to another
   * @param _from address The address which you want to send tokens from
   * @param _to address The address which you want to transfer to
   * @param _value uint256 the amount of tokens to be transferred
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _value
  )
    public
    returns (bool)
  {
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);
    require(_to != address(0));

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  /**
   * @dev Approve the passed address to spend the specified amount of tokens on behalf of msg.sender.
   * Beware that changing an allowance with this method brings the risk that someone may use both the old
   * and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this
   * race condition is to first reduce the spender's allowance to 0 and set the desired value afterwards:
   * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
   * @param _spender The address which will spend the funds.
   * @param _value The amount of tokens to be spent.
   */
  function approve(address _spender, uint256 _value) public returns (bool) {
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));
    if (allowed[msg.sender][_spender] == 0) {
        require(_value >= 0);
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    } else {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
    }
    return true;
  }

  /**
   * @dev Function to check the amount of tokens that an owner allowed to a spender.
   * @param _owner address The address which owns the funds.
   * @param _spender address The address which will spend the funds.
   * @return A uint256 specifying the amount of tokens still available for the spender.
   */
  function allowance(
    address _owner,
    address _spender
   )
    public
    view
    returns (uint256)
  {
    return allowed[_owner][_spender];
  }

  /**
   * @dev Increase the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To increment
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _addedValue The amount of tokens to increase the allowance by.
   */
  function increaseApproval(
    address _spender,
    uint256 _addedValue
  )
    public
    returns (bool)
  {
    allowed[msg.sender][_spender] = (
      allowed[msg.sender][_spender].add(_addedValue));
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  /**
   * @dev Decrease the amount of tokens that an owner allowed to a spender.
   * approve should be called when allowed[_spender] == 0. To decrement
   * allowed value is better to use this function to avoid 2 calls (and wait until
   * the first transaction is mined)
   * From MonolithDAO Token.sol
   * @param _spender The address which will spend the funds.
   * @param _subtractedValue The amount of tokens to decrease the allowance by.
   */
  function decreaseApproval(
    address _spender,
    uint256 _subtractedValue
  )
    public
    returns (bool)
  {
    uint256 oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue >= oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

}


/**
 * @title ERC865BasicToken
 * @dev Simpler version of the ERC865 token from https://github.com/adilharis2001/ERC865Demo
 * @author jsdavis28
 * @notice ERC865Token allows for users to pay gas costs to a delegate in an ERC20 token
 * https://github.com/ethereum/EIPs/issues/865
 */

 contract ERC865BasicToken is ERC865Basic, StandardToken {
    /**
     * @dev Sets internal variables for contract
     */
    address internal feeAccount;
    mapping(bytes => bool) internal signatures;

    /**
     * @dev Allows a delegate to submit a transaction on behalf of the token holder.
     * @param _signature The signature, issued by the token holder.
     * @param _to The recipient's address.
     * @param _value The amount of tokens to be transferred.
     * @param _fee The amount of tokens paid to the delegate for gas costs.
     * @param _nonce The transaction number.
     */
    function _transferPreSigned(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        internal
    {
        //Pre-validate transaction
        require(_to != address(0));
        require(signatures[_signature] == false);

        //Create a hash of the transaction details
        bytes32 hashedTx = _transferPreSignedHashing(_to, _value, _fee, _nonce);

        //Obtain the token holder's address and check balance
        address from = _recover(hashedTx, _signature);
        require(from == _from);
        uint256 total = _value.add(_fee);
        require(total <= balances[from]);

        //Transfer tokens
        balances[from] = balances[from].sub(_value).sub(_fee);
        balances[_to] = balances[_to].add(_value);
        balances[feeAccount] = balances[feeAccount].add(_fee);

        //Mark transaction as completed
        signatures[_signature] = true;

        //TransferPreSigned ERC865 events
        emit TransferPreSigned(msg.sender, from, _to, _value);
        emit TransferPreSigned(msg.sender, from, feeAccount, _fee);
        
        //Transfer ERC20 events
        emit Transfer(from, _to, _value);
        emit Transfer(from, feeAccount, _fee);
    }

    /**
     * @dev Creates a hash of the transaction information passed to transferPresigned.
     * @param _to address The address which you want to transfer to.
     * @param _value uint256 The amount of tokens to be transferred.
     * @param _fee uint256 The amount of tokens paid to msg.sender, by the owner.
     * @param _nonce uint256 Presigned transaction number.
     * @return A copy of the hashed message signed by the token holder, with prefix added.
     */
    function _transferPreSignedHashing(
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        internal
        returns (bytes32)
    {
        //Create a copy of thehashed message signed by the token holder
        bytes32 hash = keccak256(abi.encodePacked(_to, _value, _fee, _nonce));

        //Add prefix to hash
        return _prefix(hash);
    }

    /**
     * @dev Adds prefix to the hashed message signed by the token holder.
     * @param _hash The hashed message (keccak256) to be prefixed.
     * @return Prefixed hashed message to return from _transferPreSignedHashing.
     */
    function _prefix(bytes32 _hash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", _hash));
    }

    /**
     * @dev Validate the transaction information and recover the token holder's address.
     * @param _hash A prefixed version of the hash used in the original signed message.
     * @param _sig The signature submitted by the token holder.
     * @return The token holder/transaction signer's address.
     */
    function _recover(bytes32 _hash, bytes _sig) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;

        //Check the signature length
        if (_sig.length != 65) {
            return (address(0));
        }

        //Split the signature into r, s and v variables
        assembly {
            r := mload(add(_sig, 32))
            s := mload(add(_sig, 64))
            v := byte(0, mload(add(_sig, 96)))
        }

        //Version of signature should be 27 or 28, but 0 and 1 are also possible
        if (v < 27) {
            v += 27;
        }

        //If the version is correct, return the signer address
        if (v != 27 && v != 28) {
            return (address(0));
        } else {
            return ecrecover(_hash, v, r, s);
        }
    }
}


/**
 * @title Taxed token
 * @dev Version of BasicToken that allows for a fee on token transfers.
 * See https://github.com/OpenZeppelin/openzeppelin-solidity/pull/788
 * @author jsdavis28
 */
contract TaxedToken is ERC865BasicToken {
    /**
     * @dev Sets taxRate fee as public
     */
    uint8 public taxRate;

    /**
     * @dev Transfer tokens to a specified account after diverting a fee to a central account.
     * @param _to The receiving address.
     * @param _value The number of tokens to transfer.
     */
    function transfer(
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

        balances[msg.sender] = balances[msg.sender].sub(_value);
        uint256 fee = _value.mul(taxRate).div(100);
        uint256 taxedValue = _value.sub(fee);

        balances[_to] = balances[_to].add(taxedValue);
        emit Transfer(msg.sender, _to, taxedValue);
        balances[feeAccount] = balances[feeAccount].add(fee);
        emit Transfer(msg.sender, feeAccount, fee);

        return true;
    }

    /**
     * @dev Provides a taxed transfer on StandardToken's transferFrom() function
     * @param _from The address providing allowance to spend
     * @param _to The receiving address.
     * @param _value The number of tokens to transfer.
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
        public
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        uint256 fee = _value.mul(taxRate).div(100);
        uint256 taxedValue = _value.sub(fee);

        balances[_to] = balances[_to].add(taxedValue);
        emit Transfer(_from, _to, taxedValue);
        balances[feeAccount] = balances[feeAccount].add(fee);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, feeAccount, fee);

        return true;
    }
}







/**
 * @title SafeMath
 * @dev Math operations with safety checks that throw on error
 */
library SafeMath {

  /**
  * @dev Multiplies two numbers, throws on overflow.
  */
  function mul(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    // Gas optimization: this is cheaper than asserting 'a' not being zero, but the
    // benefit is lost if 'b' is also tested.
    // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
    if (_a == 0) {
      return 0;
    }

    c = _a * _b;
    assert(c / _a == _b);
    return c;
  }

  /**
  * @dev Integer division of two numbers, truncating the quotient.
  */
  function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
    // assert(_b > 0); // Solidity automatically throws when dividing by 0
    // uint256 c = _a / _b;
    // assert(_a == _b * c + _a % _b); // There is no case in which this doesn't hold
    return _a / _b;
  }

  /**
  * @dev Subtracts two numbers, throws on overflow (i.e. if subtrahend is greater than minuend).
  */
  function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
    assert(_b <= _a);
    return _a - _b;
  }

  /**
  * @dev Adds two numbers, throws on overflow.
  */
  function add(uint256 _a, uint256 _b) internal pure returns (uint256 c) {
    c = _a + _b;
    assert(c >= _a);
    return c;
  }
}


/**
 * @title Authorizable
 * @dev The Authorizable contract allows the owner to set a number of additional
 *  acccounts with limited administrative privileges to simplify user permissions.
 * Only the contract owner can add or remove authorized accounts.
 * @author jsdavis28
 */
contract Authorizable is Ownable {
    using SafeMath for uint256;

    address[] public authorized;
    mapping(address => bool) internal authorizedIndex;
    uint8 public numAuthorized;

    /**
     * @dev The Authorizable constructor sets the owner as authorized
     */
    constructor() public {
        authorized.length = 2;
        authorized[1] = msg.sender;
        authorizedIndex[msg.sender] = true;
        numAuthorized = 1;
    }

    /**
     * @dev Throws if called by any account other than an authorized account.
     */
    modifier onlyAuthorized {
        require(isAuthorized(msg.sender));
        _;
    }

    /**
     * @dev Allows the current owner to add an authorized account.
     * @param _account The address being added as authorized.
     */
    function addAuthorized(address _account) public onlyOwner {
        if (authorizedIndex[_account] == false) {
        	authorizedIndex[_account] = true;
        	authorized.length++;
        	authorized[authorized.length.sub(1)] = _account;
        	numAuthorized++;
        }
    }

    /**
     * @dev Validates whether an account is authorized for enhanced permissions.
     * @param _account The address being evaluated.
     */
    function isAuthorized(address _account) public constant returns (bool) {
        if (authorizedIndex[_account] == true) {
        	return true;
        }

        return false;
    }

    /**
     * @dev Allows the current owner to remove an authorized account.
     * @param _account The address to remove from authorized.
     */
    function removeAuthorized(address _account) public onlyOwner {
        require(isAuthorized(_account)); 
        authorizedIndex[_account] = false;
        numAuthorized--;
    }
}


/**
 * @title BlockWRKToken
 * @dev BlockWRKToken contains administrative features that allow the BlockWRK
 *  application to interface with the BlockWRK token, an ERC20-compliant token
 *  that integrates taxed token and ERC865 functionality.
 * @author jsdavis28
 */

contract BlockWRKToken is TaxedToken, Authorizable {
    /**
     * @dev Sets token information.
     */
    string public name = "BlockWRK";
    string public symbol = "WRK";
    uint8 public decimals = 4;
    uint256 public INITIAL_SUPPLY;

    /**
     * @dev Sets public variables for BlockWRK token.
     */
    address public distributionPoolWallet;
    address public inAppPurchaseWallet;
    address public reservedTokenWallet;
    uint256 public premineDistributionPool;
    uint256 public premineReserved;

    /**
     * @dev Sets private variables for custom token functions.
     */
    uint256 internal decimalValue = 10000;

    constructor() public {
        //Test values
        feeAccount = 0xf1614c0274832f0bE32ba40772a34D78C7b031b7;
        distributionPoolWallet = 0x7221c4368a7b20dbD265E4ccA90449638150F106;
        inAppPurchaseWallet = 0xFFDAAF4cb3DBBbEF6FFB33B037194c9430512292;
        reservedTokenWallet = 0x7e985952Bf5C54aa388cF3960E10645e04Ed386a;
        premineDistributionPool = decimalValue.mul(5600000000);
        premineReserved = decimalValue.mul(2000000000);
        INITIAL_SUPPLY = premineDistributionPool.add(premineReserved);
        balances[distributionPoolWallet] = premineDistributionPool;
        emit Transfer(address(this), distributionPoolWallet, premineDistributionPool);
        balances[reservedTokenWallet] = premineReserved;
        emit Transfer(address(this), reservedTokenWallet, premineReserved);
        totalSupply_ = INITIAL_SUPPLY;
        taxRate = 2;
    }

    /**
     * @dev Allows App to distribute WRK tokens to users.
     * This function will be called by authorized from within the App.
     * @param _to The recipient's BlockWRK address.
     * @param _value The amount of WRK to transfer.
     */
    function inAppTokenDistribution(
        address _to,
        uint256 _value
    )
        public
        onlyAuthorized
    {
        require(_value <= balances[distributionPoolWallet]);
        require(_to != address(0));

        balances[distributionPoolWallet] = balances[distributionPoolWallet].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(distributionPoolWallet, _to, _value);
    }

    /**
     * @dev Allows App to process fiat payments for WRK tokens, charging a fee in WRK.
     * This function will be called by authorized from within the App.
     * @param _to The buyer's BlockWRK address.
     * @param _value The amount of WRK to transfer.
     * @param _fee The fee charged in WRK for token purchase.
     */
    function inAppTokenPurchase(
        address _to,
        uint256 _value,
        uint256 _fee
    )
        public
        onlyAuthorized
    {
        require(_value <= balances[inAppPurchaseWallet]);
        require(_to != address(0));

        balances[inAppPurchaseWallet] = balances[inAppPurchaseWallet].sub(_value);
        uint256 netAmount = _value.sub(_fee);
        balances[_to] = balances[_to].add(netAmount);
        emit Transfer(inAppPurchaseWallet, _to, netAmount);
        balances[feeAccount] = balances[feeAccount].add(_fee);
        emit Transfer(inAppPurchaseWallet, feeAccount, _fee);
    }

    /**
     * @dev Allows owner to set the percentage fee charged by TaxedToken on external transfers.
     * @param _newRate The amount to be set.
     */
    function setTaxRate(uint8 _newRate) public onlyOwner {
        taxRate = _newRate;
    }

    /**
     * @dev Allows owner to set the fee account to receive transfer fees.
     * @param _newAddress The address to be set.
     */
    function setFeeAccount(address _newAddress) public onlyOwner {
        require(_newAddress != address(0));
        feeAccount = _newAddress;
    }

    /**
     * @dev Allows owner to set the wallet that holds WRK for sale via in-app purchases with fiat.
     * @param _newAddress The address to be set.
     */
    function setInAppPurchaseWallet(address _newAddress) public onlyOwner {
        require(_newAddress != address(0));
        inAppPurchaseWallet = _newAddress;
    }

    /**
     * @dev Allows authorized to act as a delegate to transfer a pre-signed transaction for ERC865
     * @param _signature The pre-signed message.
     * @param _from The token sender.
     * @param _to The token recipient.
     * @param _value The amount of WRK to send the recipient.
     * @param _fee The fee to be paid in WRK (calculated by App off-chain).
     * @param _nonce The transaction number (stored in App off-chain).
     */
    function transactionHandler(
        bytes _signature,
        address _from,
        address _to,
        uint256 _value,
        uint256 _fee,
        uint256 _nonce
    )
        public
        onlyAuthorized
    {
        _transferPreSigned(_signature, _from, _to, _value, _fee, _nonce);
    }
}