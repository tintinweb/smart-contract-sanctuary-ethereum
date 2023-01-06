/**
 *Submitted for verification at Etherscan.io on 2023-01-06
*/

// File: openzeppelin-solidity/contracts/ownership/Ownable.sol

pragma solidity ^0.4.24;


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

// File: contracts/WhiteList.sol

pragma solidity ^0.4.18;

contract WhiteList is Ownable {
    mapping(address => uint8) public whitelist;
    bool public presaleNeedWhitelist = true;
    bool public publicsaleNeedWhitelist = true;

    event ImportList(address indexed owner, address[] users, uint8 flag);
    event UpdatePresaleWhitelistStatus(address indexed owner, bool flag);
    event UpdatePublicSaleWhitelistStatus(address indexed owner, bool flag);

    /**
     * @dev Function to import user's address into whitelist, only user who in the whitelist can purchase token.
     *      Whitelistにユーザーアドレスを記録。sale期間に、Whitelistに記録したユーザーたちしかトークンを購入できない
     * @param _users The address list that can purchase token when sale period.
     * @param _flag The flag for record different lv user, 1: pre sale user, 2: public sale user.
     * @return A bool that indicates if the operation was successful.
     */
    function importList(address[] _users, uint8 _flag)
        public
        onlyOwner
        returns (bool)
    {
        require(_users.length > 0);

        for (uint256 i = 0; i < _users.length; i++) {
            whitelist[_users[i]] = _flag;
        }

        emit ImportList(msg.sender, _users, _flag);

        return true;
    }

    /**
     * @dev Function check the current user can purchase token or not.
     * ユーザーアドレスはWhitelistに記録かどうかチェック
     * @param _user The user address that can purchase token or not when public salse.
     * @return A bool that indicates if the operation was successful.
     */
    function checkList(address _user) public view returns (uint8) {
        return whitelist[_user];
    }

    /**
     * @dev Function get whitelist able status in presale
     * @return A bool that indicates if the operation was successful.
     */
    function getPresaleWhitelistStatus() public view returns (bool) {
        return presaleNeedWhitelist;
    }

    /**
     * @dev Function get whitelist able status in public sale
     * @return A bool that indicates if the operation was successful.
     */
    function getPublicSaleWhitelistStatus() public view returns (bool) {
        return publicsaleNeedWhitelist;
    }

    /**
     * @dev Function update whitelist able status in presale
     * @param _flag bool whitelist status
     * @return A bool that indicates if the operation was successful.
     */
    function updatePresaleWhitelistStatus(bool _flag)
        public
        onlyOwner
        returns (bool)
    {
        presaleNeedWhitelist = _flag;

        emit UpdatePresaleWhitelistStatus(msg.sender, _flag);

        return true;
    }

    /**
     * @dev Function update whitelist able status in public sale
     * @param _flag bool whitelist status
     * @return A bool that indicates if the operation was successful.
     */
    function updatePublicSaleWhitelistStatus(bool _flag)
        public
        onlyOwner
        returns (bool)
    {
        publicsaleNeedWhitelist = _flag;

        emit UpdatePublicSaleWhitelistStatus(msg.sender, _flag);

        return true;
    }
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.4.24;


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

// File: contracts/GroupLockup.sol

pragma solidity ^0.4.18;


contract GroupLockup is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public lockupList; //users lockup list
    mapping(uint256 => bool) public lockupListFlag;
    address[] public userList; //users address list

    event UpdateLockupList(
        address indexed owner,
        address indexed userAddress,
        uint256 lockupDate
    );
    event UpdateLockupTime(
        address indexed owner,
        uint256 indexed oldLockupDate,
        uint256 newLockupDate
    );
    event LockupTimeList(uint256 indexed lockupDate, bool active);

    /**
     * @dev Function to get lockup list
     * @param userAddress address
     * @return A uint256 that indicates if the operation was successful.
     */
    function getLockupTime(address userAddress) public view returns (uint256) {
        return lockupList[userAddress];
    }

    /**
     * @dev Function to check token locked date that is reach or not
     * @param lockupDate uint256
     * @return A bool that indicates if the operation was successful.
     */
    function isLockup(uint256 lockupDate) public view returns (bool) {
        return (now < lockupDate);
    }

    /**
     * @dev Function get user's lockup status
     * @param userAddress address
     * @return A bool that indicates if the operation was successful.
     */
    function inLockupList(address userAddress) public view returns (bool) {
        if (lockupList[userAddress] == 0) {
            return false;
        }
        return true;
    }

    /**
     * @dev Function update lockup status for purchaser, if user in the lockup list, they can only transfer token after lockup date
     * @param userAddress address
     * @param lockupDate uint256 this user's token time
     * @return A bool that indicates if the operation was successful.
     */
    function updateLockupList(address userAddress, uint256 lockupDate)
        public
        onlyOwner
        returns (bool)
    {
        if (lockupDate == 0) {
            delete lockupList[userAddress];

            for (
                uint256 userListIndex = 0;
                userListIndex < userList.length;
                userListIndex++
            ) {
                if (userList[userListIndex] == userAddress) {
                    //Swap and pop the array instead of deleting by index,
                    //so that we do not leave a gap in the array. (Storage and gas efficiency.)
                    //delete userList[userListIndex];
                    userList[userListIndex] = userList[userList.length - 1];
                    delete userList[userList.length - 1];
                    userList.length--;
                    break;
                }
            }
        } else {
            bool userIsExist = inLockupList(userAddress);

            if (!userIsExist) {
                userList.push(userAddress);
            }
            //Limit the userList size to prevent gas exhaustion.
            uint8 maxUserListLength = 100;
            require(userList.length <= maxUserListLength, "user list too large");

            lockupList[userAddress] = lockupDate;

            //insert lockup time into lockup time list, if this lockup time is the new one
            if (!lockupListFlag[lockupDate]) {
                lockupListFlag[lockupDate] = true;
                emit LockupTimeList(lockupDate, true);
            }
        }
        emit UpdateLockupList(msg.sender, userAddress, lockupDate);

        return true;
    }

    /**
     * @dev Function update lockup time
     * @param oldLockupDate uint256 old group lockup time
     * @param newLockupDate uint256 new group lockup time
     * @return A bool that indicates if the operation was successful.
     */
    function updateLockupTime(uint256 oldLockupDate, uint256 newLockupDate)
        public
        onlyOwner
        returns (bool)
    {
        require(oldLockupDate != 0);
        require(newLockupDate != 0);
        require(newLockupDate != oldLockupDate);

        address userAddress;
        uint256 userLockupTime;

        //update the user's lockup time who was be setted as old lockup time
        for (
            uint256 userListIndex = 0;
            userListIndex < userList.length;
            userListIndex++
        ) {
            if (userList[userListIndex] != 0) {
                userAddress = userList[userListIndex];
                userLockupTime = getLockupTime(userAddress);
                if (userLockupTime == oldLockupDate) {
                    lockupList[userAddress] = newLockupDate;
                    emit UpdateLockupList(
                        msg.sender,
                        userAddress,
                        newLockupDate
                    );
                }
            }
        }

        //delete the old lockup time from lockup time list, if this old lockup time is existing in the lockup time list
        if (lockupListFlag[oldLockupDate]) {
            lockupListFlag[oldLockupDate] = false;
            emit LockupTimeList(oldLockupDate, false);
        }

        //insert lockup time into lockup time list, if this lockup time is the new one
        if (!lockupListFlag[newLockupDate]) {
            lockupListFlag[newLockupDate] = true;
            emit LockupTimeList(newLockupDate, true);
        }

        emit UpdateLockupTime(msg.sender, oldLockupDate, newLockupDate);
        return true;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20Basic.sol

pragma solidity ^0.4.24;


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

// File: openzeppelin-solidity/contracts/token/ERC20/BasicToken.sol

pragma solidity ^0.4.24;


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

// File: openzeppelin-solidity/contracts/token/ERC20/ERC20.sol

pragma solidity ^0.4.24;

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

// File: openzeppelin-solidity/contracts/token/ERC20/StandardToken.sol

pragma solidity ^0.4.24;


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

// File: openzeppelin-solidity/contracts/token/ERC20/MintableToken.sol

pragma solidity ^0.4.24;


/**
 * @title Mintable token
 * @dev Simple ERC20 Token example, with mintable token creation
 * Based on code by TokenMarketNet: https://github.com/TokenMarketNet/ico/blob/master/contracts/MintableToken.sol
 */
contract MintableToken is StandardToken, Ownable {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;


  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasMintPermission() {
    require(msg.sender == owner);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param _to The address that will receive the minted tokens.
   * @param _amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(
    address _to,
    uint256 _amount
  )
    public
    hasMintPermission
    canMint
    returns (bool)
  {
    totalSupply_ = totalSupply_.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

  /**
   * @dev Function to stop minting new tokens.
   * @return True if the operation was successful.
   */
  function finishMinting() public onlyOwner canMint returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/BurnableToken.sol

pragma solidity ^0.4.24;

/**
 * @title Burnable Token
 * @dev Token that can be irreversibly burned (destroyed).
 */
contract BurnableToken is BasicToken {

  event Burn(address indexed burner, uint256 value);

  /**
   * @dev Burns a specific amount of tokens.
   * @param _value The amount of token to be burned.
   */
  function burn(uint256 _value) public {
    _burn(msg.sender, _value);
  }

  function _burn(address _who, uint256 _value) internal {
    require(_value <= balances[_who]);
    // no need to require value <= totalSupply, since that would imply the
    // sender's balance is greater than the totalSupply, which *should* be an assertion failure

    balances[_who] = balances[_who].sub(_value);
    totalSupply_ = totalSupply_.sub(_value);
    emit Burn(_who, _value);
    emit Transfer(_who, address(0), _value);
  }
}

// File: openzeppelin-solidity/contracts/token/ERC20/StandardBurnableToken.sol

pragma solidity ^0.4.24;


/**
 * @title Standard Burnable Token
 * @dev Adds burnFrom method to ERC20 implementations
 */
contract StandardBurnableToken is BurnableToken, StandardToken {

  /**
   * @dev Burns a specific amount of tokens from the target address and decrements allowance
   * @param _from address The address which you want to send tokens from
   * @param _value uint256 The amount of token to be burned
   */
  function burnFrom(address _from, uint256 _value) public {
    require(_value <= allowed[_from][msg.sender]);
    // Should https://github.com/OpenZeppelin/zeppelin-solidity/issues/707 be accepted,
    // this function needs to emit an event with the updated approval.
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _burn(_from, _value);
  }
}

// File: contracts/ERC20Token.sol

pragma solidity ^0.4.18;




contract ERC20Token is MintableToken, StandardBurnableToken {
    using SafeMath for uint256;

    string public constant NAME = "TERC20 TOKEN";
    string public constant SYMBOL = "terc20token";
    uint8 public constant DECIMALS = 18;
    uint256 public constant INITIAL_SUPPLY =
        300 * (10**uint256(DECIMALS));
    uint256 public constant INITIAL_SALE_SUPPLY =
        120 * (10**uint256(DECIMALS));
    uint256 public constant INITIAL_UNSALE_SUPPLY =
        INITIAL_SUPPLY - INITIAL_SALE_SUPPLY;

    address public ownerWallet;
    address public unsaleOwnerWallet;

    GroupLockup public groupLockup;

    event BatchTransferFail(
        address indexed from,
        address indexed to,
        uint256 value,
        string msg
    );

    /**
     * @dev Constructor that gives msg.sender all of existing tokens.
     */
    constructor(
        address _saleOwnerWallet,
        address _unsaleOwnerWallet,
        GroupLockup _groupLockup
    ) public {
        groupLockup = _groupLockup;
        ownerWallet = _saleOwnerWallet;
        unsaleOwnerWallet = _unsaleOwnerWallet;

        mint(ownerWallet, INITIAL_SALE_SUPPLY);
        mint(unsaleOwnerWallet, INITIAL_UNSALE_SUPPLY);
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function sendTokens(address _to, uint256 _value)
        public
        onlyOwner
        returns (bool)
    {
        require(_to != address(0));
        require(_value <= balances[ownerWallet]);

        // SafeMath.sub will throw if there is not enough balance.
        balances[ownerWallet] = balances[ownerWallet].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(ownerWallet, _to, _value);
        return true;
    }

    /**
     * @dev transfer token for a specified address
     * @param _to The address to transfer to.
     * @param _value The amount to be transferred.
     */
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(_value > 0);

        bool inLockupList = groupLockup.inLockupList(msg.sender);

        //if user in the lockup list, they can only transfer token after lockup date
        if (inLockupList) {
            uint256 lockupTime = groupLockup.getLockupTime(msg.sender);
            require(groupLockup.isLockup(lockupTime) == false);
        }

        // SafeMath.sub will throw if there is not enough balance.
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

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
    ) public returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        //Validate the lockup time about the `from` address.
        bool inLockupList = groupLockup.inLockupList(_from);
        //if user in the lockup list, they can only transfer token after lockup date
        if (inLockupList) {
            uint256 lockupTime = groupLockup.getLockupTime(_from);
            require(groupLockup.isLockup(lockupTime) == false);
        }

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    /**
     * @dev transfer token to mulitipule user
     * @param _from which wallet's token will be taken.
     * @param _users The address list to transfer to.
     * @param _values The amount list to be transferred.
     */
    function batchTransfer(
        address _from,
        address[] _users,
        uint256[] _values
    ) public onlyOwner returns (bool) {
        address to;
        uint256 value;
        bool isUserAddress;
        bool canTransfer;
        string memory transferFailMsg;

        for (uint256 i = 0; i < _users.length; i++) {
            to = _users[i];
            value = _values[i];
            isUserAddress = false;
            canTransfer = false;
            transferFailMsg = "";

            // can not send token to contract address
            //コントラクトアドレスにトークンを発送できない検証
            assembly {
                isUserAddress := iszero(extcodesize(to))
            }

            //data check
            if (!isUserAddress) {
                transferFailMsg = "try to send token to contract";
            } else if (value <= 0) {
                transferFailMsg = "try to send wrong token amount";
            } else if (to == address(0)) {
                transferFailMsg = "try to send token to empty address";
            } else if (value > balances[_from]) {
                transferFailMsg = "token amount is larger than giver holding";
            } else {
                canTransfer = true;
            }

            if (canTransfer) {
                balances[_from] = balances[_from].sub(value);
                balances[to] = balances[to].add(value);
                emit Transfer(_from, to, value);
            } else {
                emit BatchTransferFail(_from, to, value, transferFailMsg);
            }
        }

        return true;
    }

    /**
     * @dev Burns msg.sender's token.
     * @param _value The amount to burn.
     */
    function burn(uint256 _value) public onlyOwner {
        super.burn(_value);
    }

    /**
     * @dev Burns token of an address.
     * @param _from The address to burn token from.
     * @param _value The amount to burn.
     */
    function burnFrom(address _from, uint256 _value) public onlyOwner {
        super.burnFrom(_from, _value);
    }

}

// File: contracts/SaleInfo.sol

pragma solidity ^0.4.18;

contract SaleInfo {
    using SafeMath for uint256;

    uint256 public privateOpeningTime;
    uint256 public privateClosingTime;
    uint256 public publicOpeningTime;
    uint256 public publicClosingTime;
    address public adminWallet;
    address public saleOwnerWallet;
    address public unsaleOwnerWallet;
    address public ethManagementWallet;

    constructor(
        uint256 _privateOpeningTime,
        uint256 _privateClosingTime,
        uint256 _publicOpeningTime,
        uint256 _publicClosingTime,
        address _adminWallet,
        address _saleOwnerWallet,
        address _unsaleOwnerWallet,
        address _ethManagementWallet
    ) public {
        privateOpeningTime = _privateOpeningTime;
        privateClosingTime = _privateClosingTime;
        publicOpeningTime = _publicOpeningTime;
        publicClosingTime = _publicClosingTime;
        adminWallet = _adminWallet;
        saleOwnerWallet = _saleOwnerWallet;
        unsaleOwnerWallet = _unsaleOwnerWallet;
        ethManagementWallet = _ethManagementWallet;
    }

    /**
     * @dev get admin wallet
     */
    function getAdminAddress() public view returns (address) {
        return adminWallet;
    }

    /**
     * @dev get owner wallet
     */
    function getSaleOwnerAddress() public view returns (address) {
        return saleOwnerWallet;
    }

    /**
     * @dev get unsale owner wallet
     */
    function getUnsaleOwnerAddress() public view returns (address) {
        return unsaleOwnerWallet;
    }

    /**
     * @dev get eth management owner wallet
     */
    function getEtherManagementAddress() public view returns (address) {
        return ethManagementWallet;
    }

    /**
     * @dev get start date for presale
     */
    function getPresaleOpeningDate() public view returns (uint256) {
        return privateOpeningTime;
    }

    /**
     * @dev get end date for presale
     */
    function getPresaleClosingDate() public view returns (uint256) {
        return privateClosingTime;
    }

    /**
     * @dev get start date for public sale
     */
    function getPublicsaleOpeningDate() public view returns (uint256) {
        return publicOpeningTime;
    }

    /**
     * @dev get end date for public sale
     */
    function getPublicsaleClosingDate() public view returns (uint256) {
        return publicClosingTime;
    }

    /**
     * @dev current time is in presale period or not
     */
    function inPresalePeriod() public view returns (bool) {
        return ((now >= privateOpeningTime) && (now <= privateClosingTime));
    }

    /**
     * @dev current time is in public sale period or not
     */
    function inPublicsalePeriod() public view returns (bool) {
        return ((now >= publicOpeningTime) && (now <= publicClosingTime));
    }
}

// File: contracts/BatchTransferable.sol

pragma solidity ^0.4.18;

/**
 * @title BatchTransferable
 * @dev Base contract which allows children to run batch transfer token.
 */
contract BatchTransferable is Ownable {
    event BatchTransferStop();

    bool public batchTransferStopped = false;

    /**
     * @dev Modifier to make a function callable only when the contract is do batch transfer token.
     */
    modifier whenBatchTransferNotStopped() {
        require(!batchTransferStopped);
        _;
    }

    /**
     * @dev called by the owner to stop, triggers stopped state
     */
    function batchTransferStop() public onlyOwner whenBatchTransferNotStopped {
        batchTransferStopped = true;
        emit BatchTransferStop();
    }

    /**
     * @dev called to check that can do batch transfer or not
     */
    function isBatchTransferStop() public view returns (bool) {
        return batchTransferStopped;
    }
}

// File: openzeppelin-solidity/contracts/token/ERC20/SafeERC20.sol

pragma solidity ^0.4.24;


/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure.
 * To use this library you can add a `using SafeERC20 for ERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
  function safeTransfer(
    ERC20Basic _token,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transfer(_to, _value));
  }

  function safeTransferFrom(
    ERC20 _token,
    address _from,
    address _to,
    uint256 _value
  )
    internal
  {
    require(_token.transferFrom(_from, _to, _value));
  }

  function safeApprove(
    ERC20 _token,
    address _spender,
    uint256 _value
  )
    internal
  {
    require(_token.approve(_spender, _value));
  }
}

// File: openzeppelin-solidity/contracts/crowdsale/Crowdsale.sol

pragma solidity ^0.4.24;



/**
 * @title Crowdsale
 * @dev Crowdsale is a base contract for managing a token crowdsale,
 * allowing investors to purchase tokens with ether. This contract implements
 * such functionality in its most fundamental form and can be extended to provide additional
 * functionality and/or custom behavior.
 * The external interface represents the basic interface for purchasing tokens, and conform
 * the base architecture for crowdsales. They are *not* intended to be modified / overridden.
 * The internal interface conforms the extensible and modifiable surface of crowdsales. Override
 * the methods to add functionality. Consider using 'super' where appropriate to concatenate
 * behavior.
 */
contract Crowdsale {
  using SafeMath for uint256;
  using SafeERC20 for ERC20;

  // The token being sold
  ERC20 public token;

  // Address where funds are collected
  address public wallet;

  // How many token units a buyer gets per wei.
  // The rate is the conversion between wei and the smallest and indivisible token unit.
  // So, if you are using a rate of 1 with a DetailedERC20 token with 3 decimals called TOK
  // 1 wei will give you 1 unit, or 0.001 TOK.
  uint256 public rate;

  // Amount of wei raised
  uint256 public weiRaised;

  /**
   * Event for token purchase logging
   * @param purchaser who paid for the tokens
   * @param beneficiary who got the tokens
   * @param value weis paid for purchase
   * @param amount amount of tokens purchased
   */
  event TokenPurchase(
    address indexed purchaser,
    address indexed beneficiary,
    uint256 value,
    uint256 amount
  );

  /**
   * @param _rate Number of token units a buyer gets per wei
   * @param _wallet Address where collected funds will be forwarded to
   * @param _token Address of the token being sold
   */
  constructor(uint256 _rate, address _wallet, ERC20 _token) public {
    require(_rate > 0);
    require(_wallet != address(0));
    require(_token != address(0));

    rate = _rate;
    wallet = _wallet;
    token = _token;
  }

  // -----------------------------------------
  // Crowdsale external interface
  // -----------------------------------------

  /**
   * @dev fallback function ***DO NOT OVERRIDE***
   */
  function () external payable {
    buyTokens(msg.sender);
  }

  /**
   * @dev low level token purchase ***DO NOT OVERRIDE***
   * @param _beneficiary Address performing the token purchase
   */
  function buyTokens(address _beneficiary) public payable {

    uint256 weiAmount = msg.value;
    _preValidatePurchase(_beneficiary, weiAmount);

    // calculate token amount to be created
    uint256 tokens = _getTokenAmount(weiAmount);

    // update state
    weiRaised = weiRaised.add(weiAmount);

    _processPurchase(_beneficiary, tokens);
    emit TokenPurchase(
      msg.sender,
      _beneficiary,
      weiAmount,
      tokens
    );

    _updatePurchasingState(_beneficiary, weiAmount);

    _forwardFunds();
    _postValidatePurchase(_beneficiary, weiAmount);
  }

  // -----------------------------------------
  // Internal interface (extensible)
  // -----------------------------------------

  /**
   * @dev Validation of an incoming purchase. Use require statements to revert state when conditions are not met. Use `super` in contracts that inherit from Crowdsale to extend their validations.
   * Example from CappedCrowdsale.sol's _preValidatePurchase method:
   *   super._preValidatePurchase(_beneficiary, _weiAmount);
   *   require(weiRaised.add(_weiAmount) <= cap);
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    require(_beneficiary != address(0));
    require(_weiAmount != 0);
  }

  /**
   * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid conditions are not met.
   * @param _beneficiary Address performing the token purchase
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _postValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
   * @param _beneficiary Address performing the token purchase
   * @param _tokenAmount Number of tokens to be emitted
   */
  function _deliverTokens(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    token.safeTransfer(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Executed when a purchase has been validated and is ready to be executed. Not necessarily emits/sends tokens.
   * @param _beneficiary Address receiving the tokens
   * @param _tokenAmount Number of tokens to be purchased
   */
  function _processPurchase(
    address _beneficiary,
    uint256 _tokenAmount
  )
    internal
  {
    _deliverTokens(_beneficiary, _tokenAmount);
  }

  /**
   * @dev Override for extensions that require an internal state to check for validity (current user contributions, etc.)
   * @param _beneficiary Address receiving the tokens
   * @param _weiAmount Value in wei involved in the purchase
   */
  function _updatePurchasingState(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    // optional override
  }

  /**
   * @dev Override to extend the way in which ether is converted to tokens.
   * @param _weiAmount Value in wei to be converted into tokens
   * @return Number of tokens that can be purchased with the specified _weiAmount
   */
  function _getTokenAmount(uint256 _weiAmount)
    internal view returns (uint256)
  {
    return _weiAmount.mul(rate);
  }

  /**
   * @dev Determines how ETH is stored/forwarded on purchases.
   */
  function _forwardFunds() internal {
    wallet.transfer(msg.value);
  }
}

// File: openzeppelin-solidity/contracts/crowdsale/validation/TimedCrowdsale.sol

pragma solidity ^0.4.24;


/**
 * @title TimedCrowdsale
 * @dev Crowdsale accepting contributions only within a time frame.
 */
contract TimedCrowdsale is Crowdsale {
  using SafeMath for uint256;

  uint256 public openingTime;
  uint256 public closingTime;

  /**
   * @dev Reverts if not in crowdsale time range.
   */
  modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime);
    _;
  }

  /**
   * @dev Constructor, takes crowdsale opening and closing times.
   * @param _openingTime Crowdsale opening time
   * @param _closingTime Crowdsale closing time
   */
  constructor(uint256 _openingTime, uint256 _closingTime) public {
    // solium-disable-next-line security/no-block-members
    require(_openingTime >= block.timestamp);
    require(_closingTime >= _openingTime);

    openingTime = _openingTime;
    closingTime = _closingTime;
  }

  /**
   * @dev Checks whether the period in which the crowdsale is open has already elapsed.
   * @return Whether crowdsale period has elapsed
   */
  function hasClosed() public view returns (bool) {
    // solium-disable-next-line security/no-block-members
    return block.timestamp > closingTime;
  }

  /**
   * @dev Extend parent behavior requiring to be within contributing period
   * @param _beneficiary Token purchaser
   * @param _weiAmount Amount of wei contributed
   */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
    onlyWhileOpen
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
  }

}

// File: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

pragma solidity ^0.4.24;

/**
 * @title Pausable
 * @dev Base contract which allows children to implement an emergency stop mechanism.
 */
contract Pausable is Ownable {
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
  function pause() public onlyOwner whenNotPaused {
    paused = true;
    emit Pause();
  }

  /**
   * @dev called by the owner to unpause, returns to normal state
   */
  function unpause() public onlyOwner whenPaused {
    paused = false;
    emit Unpause();
  }
}

// File: contracts/ERC20TokenCrowdsale.sol

pragma solidity ^0.4.18;









contract ERC20TokenCrowdsale is
    TimedCrowdsale,
    Ownable,
    Pausable,
    BatchTransferable
{
    using SafeMath for uint256;

    address public adminWallet; //wallet to controll system
    address public saleOwnerWallet;
    address public unsaleOwnerWallet;
    address public ethManagementWallet; //wallet to reveive eth

    uint256 public minimumWeiAmount;
    uint256 private rateDigit;

    ERC20Token public erc20Token;
    SaleInfo public saleInfo;
    WhiteList public whiteList;
    GroupLockup public groupLockup;

    event PresalePurchase(address indexed purchaser, uint256 value);
    event PublicsalePurchase(
        address indexed purchaser,
        uint256 value,
        uint256 amount,
        uint256 rate
    );
    event UpdateRate(address indexed updater, uint256 rate);
    event UpdateMinimumAmount(
        address indexed updater,
        uint256 minimumWeiAmount
    );
    event GiveToken(
        address indexed purchaser,
        uint256 amount,
        uint256 lockupTime
    );

    constructor(
        uint256 _openingTime,
        uint256 _closingTime,
        uint256 _rate,
        uint256 _rateDigit,
        uint256 _minimumWeiAmount,
        address _adminWallet,
        address _saleOwnerWallet,
        address _unsaleOwnerWallet,
        address _ethManagementWallet,
        ERC20Token _erc20,
        SaleInfo _saleInfo,
        WhiteList _whiteList,
        GroupLockup _groupLockup
    )
        public
        Crowdsale(_rate, _ethManagementWallet, _erc20)
        TimedCrowdsale(_openingTime, _closingTime)
    {
        adminWallet = _adminWallet;
        saleOwnerWallet = _saleOwnerWallet;
        unsaleOwnerWallet = _unsaleOwnerWallet;
        ethManagementWallet = _ethManagementWallet;
        erc20Token = _erc20;
        saleInfo = _saleInfo;
        whiteList = _whiteList;
        groupLockup = _groupLockup;
        rateDigit = _rateDigit;
        minimumWeiAmount = _minimumWeiAmount;

        emit UpdateRate(msg.sender, _rate);
        emit UpdateMinimumAmount(msg.sender, _minimumWeiAmount);
    }

    /**
     * @dev low level token purchase ***DO NOT OVERRIDE***
     * @param _beneficiary Address performing the token purchase
     */
    function buyTokens(address _beneficiary)
        public
        payable
        onlyWhileOpen
        whenNotPaused
    {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount.div(rateDigit));

        // update state
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        emit TokenPurchase(msg.sender, _beneficiary, weiAmount, tokens);

        _updatePurchasingState(_beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(_beneficiary, weiAmount);
    }

    /**
     * @dev Validation of an incoming purchase. Use require statemens to revert state when conditions are not met. Use super to concatenate validations.
     * @param _beneficiary Address performing the token purchase
     * @param _weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount)
        internal
    {
        require(_beneficiary != address(0));
        require(_weiAmount != 0);
        require(_weiAmount % rateDigit == 0);

        //minimum ether check
        require(_weiAmount >= minimumWeiAmount);

        //owner can not purchase token
        require(_beneficiary != adminWallet);
        require(_beneficiary != saleOwnerWallet);
        require(_beneficiary != unsaleOwnerWallet);
        require(_beneficiary != ethManagementWallet);

        require(saleInfo.inPresalePeriod() || saleInfo.inPublicsalePeriod());

        //whitelist check
        //whitelist status:1-presale user, 2-public sale user
        uint8 inWhitelist = whiteList.checkList(_beneficiary);

        if (saleInfo.inPresalePeriod()) {
            //if need to check whitelist status in presale period
            if (whiteList.getPresaleWhitelistStatus()) {
                require(inWhitelist == 1);
            }
        } else {
            //if need to check whitelist status in public sale period
            if (whiteList.getPublicSaleWhitelistStatus()) {
                require((inWhitelist == 1) || (inWhitelist == 2));
            }
        }
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends its tokens.
     * @param _beneficiary Address performing the token purchase
     * @param _tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount)
        internal
    {
        //will not send token directly when purchaser purchase the token in presale
        if (saleInfo.inPresalePeriod()) {
            emit PresalePurchase(_beneficiary, msg.value);
        } else {
            require(erc20Token.sendTokens(_beneficiary, _tokenAmount));
            emit PublicsalePurchase(
                _beneficiary,
                msg.value,
                _tokenAmount,
                rate
            );
        }
    }

    /**
     * @dev send token and set token lockup status to specific user
     *  file format:
     *          [
     *                  [<address>, <token amount>, <lockup time>],
     *                  [<address>, <token amount>, <lockup time>],...
     *          ]
     * @param _beneficiary Address
     * @param _tokenAmount token amount
     * @param _lockupTime uint256 this address's lockup time
     * @return A bool that indicates if the operation was successful.
     */
    function giveToken(
        address _beneficiary,
        uint256 _tokenAmount,
        uint256 _lockupTime
    ) public onlyOwner returns (bool) {
        require(_beneficiary != address(0));

        require(_tokenAmount > 0);

        if (_lockupTime != 0) {
            //add this account in to lockup list
            require(updateLockupList(_beneficiary, _lockupTime));
        }

        require(erc20Token.sendTokens(_beneficiary, _tokenAmount));

        emit GiveToken(_beneficiary, _tokenAmount, _lockupTime);

        return true;
    }

    /**
     * @dev send token to mulitple user
     * @param _from token provider address
     * @param _users user address list
     * @param _values the token amount list that want to deliver
     * @return A bool the operation was successful.
     */
    function batchTransfer(
        address _from,
        address[] _users,
        uint256[] _values
    ) public onlyOwner whenBatchTransferNotStopped returns (bool) {
        require(
            _users.length > 0 &&
                _values.length > 0 &&
                _users.length == _values.length,
            "list error"
        );

        require(
            _from != address(0),
            "token giver wallet is not the correct address"
        );

        require(erc20Token.batchTransfer(_from, _users, _values), "batch transfer failed");
        return true;
    }

    /**
     * @dev set lockup status to mulitple user
     * @param _users user address list
     * @param _lockupDates uint256 user lockup time
     * @return A bool the operation was successful.
     */
    function batchUpdateLockupList(address[] _users, uint256[] _lockupDates)
        public
        onlyOwner
        returns (bool)
    {
        require(
            _users.length > 0 &&
                _lockupDates.length > 0 &&
                _users.length == _lockupDates.length,
            "list error"
        );

        address user;
        uint256 lockupDate;

        for (uint256 i = 0; i < _users.length; i++) {
            user = _users[i];
            lockupDate = _lockupDates[i];

            updateLockupList(user, lockupDate);
        }

        return true;
    }

    /**
     * @dev Function update lockup status for purchaser
     * @param _add address
     * @param _lockupDate uint256 this user's lockup time
     * @return A bool that indicates if the operation was successful.
     */
    function updateLockupList(address _add, uint256 _lockupDate)
        public
        onlyOwner
        returns (bool)
    {
        return groupLockup.updateLockupList(_add, _lockupDate);
    }

    /**
     * @dev Function update lockup time
     * @param _oldLockupDate uint256
     * @param _newLockupDate uint256
     * @return A bool that indicates if the operation was successful.
     */
    function updateLockupTime(uint256 _oldLockupDate, uint256 _newLockupDate)
        public
        onlyOwner
        returns (bool)
    {
        return groupLockup.updateLockupTime(_oldLockupDate, _newLockupDate);
    }

    /**
     * @dev called for get status of pause.
     */
    function ispause() public view returns (bool) {
        return paused;
    }

    /**
     * @dev Function update rate
     * @param _newRate rate
     * @return A bool that indicates if the operation was successful.
     */
    function updateRate(int256 _newRate) public onlyOwner returns (bool) {
        require(_newRate >= 1);

        rate = uint256(_newRate);

        emit UpdateRate(msg.sender, rate);

        return true;
    }

    /**
     * @dev Function get rate
     * @return A uint256 that indicates if the operation was successful.
     */
    function getRate() public view returns (uint256) {
        return rate;
    }

    /**
     * @dev Function get minimum wei amount
     * @return A uint256 that indicates if the operation was successful.
     */
    function getMinimumAmount() public view returns (uint256) {
        return minimumWeiAmount;
    }

    /**
     * @dev Function update minimum wei amount
     * @return A uint256 that indicates if the operation was successful.
     */
    function updateMinimumAmount(int256 _newMnimumWeiAmount)
        public
        onlyOwner
        returns (bool)
    {
        require(_newMnimumWeiAmount >= 0);

        minimumWeiAmount = uint256(_newMnimumWeiAmount);

        emit UpdateMinimumAmount(msg.sender, minimumWeiAmount);

        return true;
    }

    /**
     * @dev Function mint token
     * @param _add user wallet
     * @param _amount amount want to mint
     * @return A bool that indicates if the operation was successful.
     */
    function mint(address _add, int256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        require(_add != address(0), "user wallet is not the correct address");

        require(_amount > 0, "invalid amount");

        uint256 amount = uint256(_amount);

        erc20Token.mint(_add, amount);

        return true;
    }

    /**
     * @dev Function mint stop
     * @return A bool that indicates if the operation was successful.
     */
    function finishMinting() public onlyOwner returns (bool) {
        erc20Token.finishMinting();

        return true;
    }

    /**
     * @dev Function burn token
     * @param _amount amount to burn.
     * @return A bool that indicates if the operation was successful.
     */
    function burn(int256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        require(_amount > 0, "invalid amount");

        uint256 amount = uint256(_amount);
        erc20Token.burn(amount);
        return true;
    }

    /**
     * @dev Function burn token
     * @param _add address to burn token from
     * @param _amount amount to burn.
     * @return A bool that indicates if the operation was successful.
     */
    function burnFrom(address _add, int256 _amount)
        public
        onlyOwner
        returns (bool)
    {
        require(_add != address(0), "user wallet is not the correct address");
        require(_amount > 0, "invalid amount");

        uint256 amount = uint256(_amount);
        erc20Token.burnFrom(_add, amount);

        return true;
    }
}