/**
 *Submitted for verification at Etherscan.io on 2022-04-10
*/

// Dependency file: openzeppelin-solidity/contracts/math/SafeMath.sol

// pragma solidity ^0.5.0;

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
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
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
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}


// Dependency file: contracts/access/Roles.sol

// pragma solidity ^0.5.0;

/**
 * @title Roles
 * @dev Library for managing addresses assigned to a Role.
 */
library Roles {
    struct Role {
        mapping (address => bool) bearer;
    }

    /**
     * @dev Give an account access to this role.
     */
    function add(Role storage role, address account) internal {
        require(!has(role, account), "Roles: account already has role");
        role.bearer[account] = true;
    }

    /**
     * @dev Remove an account's access to this role.
     */
    function remove(Role storage role, address account) internal {
        require(has(role, account), "Roles: account does not have role");
        role.bearer[account] = false;
    }

    /**
     * @dev Check if an account has this role.
     * @return bool
     */
    function has(Role storage role, address account) internal view returns (bool) {
        require(account != address(0), "Roles: account is the zero address");
        return role.bearer[account];
    }
}


// Dependency file: contracts/access/roles/PauserRole.sol

// pragma solidity ^0.5.0;

// import "contracts/access/Roles.sol";

contract PauserRole {
    using Roles for Roles.Role;

    event PauserAdded(address indexed account);
    event PauserRemoved(address indexed account);

    Roles.Role private _pausers;

    constructor () internal {
        _addPauser(msg.sender);
    }

    modifier onlyPauser() {
        require(isPauser(msg.sender), "PauserRole: caller does not have the Pauser role");
        _;
    }

    function isPauser(address account) public view returns (bool) {
        return _pausers.has(account);
    }

    function changePauser(address account) public onlyPauser {
        _addPauser(account);
        _removePauser(msg.sender);
    }

    function _addPauser(address account) internal {
        _pausers.add(account);
        emit PauserAdded(account);
    }

    function _removePauser(address account) internal {
        _pausers.remove(account);
        emit PauserRemoved(account);
    }
}


// Dependency file: contracts/lifecycle/Pausable.sol

// pragma solidity ^0.5.0;

// import "contracts/access/roles/PauserRole.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
contract Pausable is PauserRole {
    /**
     * @dev Emitted when the pause is triggered by a pauser (`account`).
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by a pauser (`account`).
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state. Assigns the Pauser role
     * to the deployer.
     */
    constructor () internal {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     */
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     */
    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    /**
     * @dev Called by a pauser to pause, triggers stopped state.
     */
    function pause() public onlyPauser whenNotPaused {
        _paused = true;
        emit Paused(msg.sender);
    }

    /**
     * @dev Called by a pauser to unpause, returns to normal state.
     */
    function unpause() public onlyPauser whenPaused {
        _paused = false;
        emit Unpaused(msg.sender);
    }
}


// Dependency file: contracts/ownership/Ownable.sol

// pragma solidity ^0.5.0;

// import "contracts/lifecycle/Pausable.sol";
/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable is Pausable{
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
        changePauser(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


// Dependency file: contracts/access/roles/SignerRole.sol

// pragma solidity ^0.5.0;

// import "contracts/access/Roles.sol";

contract SignerRole {
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    constructor (address signer) internal {
        _addSigner(signer);
    }

    modifier onlySigner() {
        require(isSigner(msg.sender), "SignerRole: caller does not have the Signer role");
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function _addSigner(address account) internal {
        _signers.add(account);
        emit SignerAdded(account);
    }

    function _removeSigner(address account) internal {
        _signers.remove(account);
        emit SignerRemoved(account);
    }
}


// Dependency file: contracts/ICustody.sol

// pragma solidity ^0.5.0;

interface ICustody {
  event LockToken(
    bytes32 tokenType,
    address indexed depositor,
    address indexed depositReceiver,
    address indexed wrappedToken,
    uint256 tokenId
  );

  event UnlockToken(
    bytes32 tokenType,
    address indexed withdrawReceiver,
    address indexed originToken,
    uint256 tokenId
  );

  event MintWrappedToken(
    bytes32 tokenType,
    address indexed depositReceiver,
    address indexed originToken,
    uint256 tokenId
  );

  event BurnWrappedToken(
    bytes32 tokenType,
    address indexed withdrawer,
    address indexed wrappedToken,
    uint256 tokenId
  );

  event SetBridge(address bridgeAddress);

  function lockToken(
    address depositor,
    address depositReceiver,
    address wrappedToken,
    bytes calldata tokenData
  ) external;

  function unlockToken(
    address withdrawReceiver,
    address originToken,
    bytes calldata tokenData
  )  external;

  function mintWrappedToken(
    address depositReceiver,
    address wrappedToken,
    bytes calldata tokenData
  )  external;

  function burnWrappedToken(
    address withdrawer,
    address originToken,
    bytes calldata tokenData
  )  external; 

  function getBridge() external view returns (address);
  function tokenType() external view returns (bytes32);
}


// Dependency file: contracts/IBridge.sol

// pragma solidity ^0.5.0;

interface IBridge {

  event Deposit(
    address indexed depositor,
    address indexed depositReceiver,
    address indexed originToken,
    address wrappedToken,
    bytes tokenData,
    bytes32 tokenType,
    uint256 originChain,
    uint256 wrapperChain,
    uint256 originChainCounter
  );

  event Withdraw(
    address indexed withdrawer,
    address indexed withdrawReceiver,
    address originToken,
    address indexed wrappedToken,
    bytes tokenData,
    bytes32 tokenType,
    uint256 originChian,
    uint256 wrapperChain,
    uint256 wrapperChainCounter
  );

  event UnlockAndReturnToken(
    address indexed withdrawReceiver,
    address indexed originToken,
    address wrappedToken,
    bytes tokenData,  
    bytes32 tokenType,
    uint256 originChain,
    uint256 wrapperChain,
    uint256 indexed wrapperChainCounter
  );

  event MintWrappedToken(
    address indexed depositReceiver,
    address originToken,
    address indexed wrappedToken,
    bytes tokenData,  
    bytes32 tokenType,
    uint256 originChain,
    uint256 wrapperChain,
    uint256 indexed originChainCounter
  );

  event TokenMapped(
    address indexed originToken,
    address indexed wrappedToken,
    bytes32 tokenType
  );

  event CustodyChanged(address indexed custody, bytes32 tokenType);
  event MappingContractChanged(address indexed mappingContractAddress);

  event ClearOriginChainCounterChecker(uint256 originChainCounter);
  event ClearWrapperChainCounterChecker(uint256 wrapperChainCounter);

  function getOriginChain() external view returns (uint256);
  function getWrapperChain() external view returns (uint256);
  function getOriginChainCounter() external view returns (uint256);
  function getWrapperChainCounter() external view returns (uint256);

  function typeToCustody(bytes32 tokenType) external view returns (address);
  function getOriginChainCounterChecker(uint256 originChainCounter) external view returns (bool);
  function getWrapperChainCounterChecker(uint256 wrapperChainCounter) external view returns (bool);
  function getMappingContractAddress() external view returns (address);
}

// Dependency file: contracts/mapping/IMapping.sol

// pragma solidity ^0.5.0;

interface IMapping {

  event TokenMapped(
    address indexed originToken,
    address indexed wrappedToken,
    bytes32 tokenType,
    uint256 originChain,
    uint256 wrapperChain,
    address indexed bridgeAddress
  );

  event BridgeSet(
    address indexed bridgeAddress 
  );

  function mapToken(address originToken, address wrappedToken, bytes32 tokenType, bool wrapped) external;
  function cleanMapToken(address originToken, address wrappedToken, bool wrapped) external;
  function remapToken(address originToken, address wrappedToken, bool wrapped) external;

  function originToWrappedToken(address originToken) external view returns (address);
  function wrappedToOriginToken(uint256 wrapperChain, address wrappedToken) external view returns (address);
  function tokenToType(address originToken) external view returns (bytes32);
}

// Root file: contracts/Bridge.sol

pragma solidity ^0.5.0;

// import '/Users/lambda256/git/deployTest/luniverseTestRopsten/luniverse-bridge-contract/node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol';
// import 'contracts/ownership/Ownable.sol';
// import 'contracts/access/roles/SignerRole.sol';
// import 'contracts/ICustody.sol';
// import 'contracts/IBridge.sol';
// import 'contracts/mapping/IMapping.sol';

contract Bridge is IBridge, Ownable, SignerRole{
  using SafeMath for uint256;
  uint256 private _originChain;
  uint256 private _wrapperChain;
  uint256 private _originChainCounter;
  uint256 private _wrapperChainCounter;
  IMapping mappingContract;

  mapping(bytes32 => address) private _typeToCustody;
  mapping(uint256 => bool) private _originChainCounterChecker;
  mapping(uint256 => bool) private _wrapperChainCounterChecker;

  constructor(
    uint256 originChain,
    uint256 wrapperChain,
    address mappingContractAddress,
    address signer
  ) 
  SignerRole(signer) public {
    _originChain = originChain;
    _wrapperChain = wrapperChain;
    _originChainCounter = 0;
    _wrapperChainCounter = 0;
    mappingContract = IMapping(mappingContractAddress);
  }

  function changeSigner(address oldAccount, address newAccount) public onlyOwner {
    _removeSigner(oldAccount);
    _addSigner(newAccount);
  }

  function deposit(
    address depositReceiver,
    address originToken,
    bytes memory tokenData
  ) 
    public
    whenNotPaused
  {
    require(originToken != address(0), "Bridge: deposit to the zero contract address");
    address wrappedToken = mappingContract.originToWrappedToken(originToken);
    bytes32 tokenType = mappingContract.tokenToType(originToken);
    _deposit(msg.sender,depositReceiver,originToken,tokenData,tokenType);
    _originChainCounter = _originChainCounter.add(1);
    emit Deposit(msg.sender, depositReceiver, originToken, wrappedToken, tokenData, tokenType, _originChain, _wrapperChain, _originChainCounter);
  }

  function _deposit(
    address depositor,
    address depositReceiver,
    address originToken,
    bytes memory tokenData,
    bytes32 tokenType
  )
    private
  {
    require(depositReceiver != address(0), "Bridge: deposit to the zero address");
    address custody = typeToCustody(tokenType);
    ICustody(custody).lockToken(depositor, depositReceiver, originToken, tokenData);
  }

  function withdraw(
    address withdrawReceiver,
    address wrappedToken,
    bytes memory tokenData
  )
    public
    whenNotPaused
  {
    require(withdrawReceiver != address(0), "Bridge: withdraw to the zero address");
    address originToken = mappingContract.wrappedToOriginToken(_originChain,wrappedToken);
    bytes32 tokenType = mappingContract.tokenToType(originToken);
    _withdraw(msg.sender, wrappedToken, tokenData, tokenType);
    _wrapperChainCounter = _wrapperChainCounter.add(1);

    emit Withdraw(msg.sender, withdrawReceiver, originToken, wrappedToken, tokenData, tokenType, _wrapperChain, _originChain, _wrapperChainCounter);
  }

  function _withdraw(
    address withdrawer,
    address wrappedToken,
    bytes memory tokenData,
    bytes32 tokenType
  ) 
    private
  {
    require(wrappedToken != address(0), "Bridge: withdraw to zero contract address");
    address custody = typeToCustody(tokenType);
    ICustody(custody).burnWrappedToken(withdrawer, wrappedToken, tokenData);
  }

  function mintWrappedToken(
    address wrappedToken,
    address depositReceiver,
    bytes memory tokenData,
    uint256 originChainCounter
    )
      public
      onlySigner
      whenNotPaused
     {
      require(
        _originChainCounterChecker[originChainCounter] != true,
        "Bridge: double spending transaction from originChain"
      );
      address originToken = mappingContract.wrappedToOriginToken(_originChain,wrappedToken);
      bytes32 tokenType = mappingContract.tokenToType(originToken);
      _mintWrappedToken(wrappedToken, depositReceiver, tokenData, tokenType);
      _originChainCounterChecker[originChainCounter] = true;
      emit MintWrappedToken(depositReceiver, originToken, wrappedToken, tokenData, tokenType, _wrapperChain, _originChain, originChainCounter);
  }

  function _mintWrappedToken(
    address wrappedToken, 
    address depositReceiver, 
    bytes memory tokenData,
    bytes32 tokenType
    ) private {
      require(wrappedToken != address(0), "Bridge: mintWrappedToken to the zero contract address"); //wrappedToOriginToken에서 막힘
      require(depositReceiver != address(0), "Bridge: mintWrappedToken to the zero address");
      address custody = typeToCustody(tokenType);
      ICustody(custody).mintWrappedToken(wrappedToken, depositReceiver, tokenData);
  }

  function unlockAndReturnToken(
    address originToken,
    address withdrawReceiver,
    bytes memory tokenData,
    uint256 wrapperChainCounter
    )
      public
      onlySigner
      whenNotPaused
     {
      require(
        _wrapperChainCounterChecker[wrapperChainCounter] != true,
        "Bridge: double spending transaction from wrapperChain"
      );
    address wrappedToken = mappingContract.originToWrappedToken(originToken);
    bytes32 tokenType = mappingContract.tokenToType(originToken);
    _unlockAndReturnToken(originToken, withdrawReceiver, tokenData, tokenType);
    _wrapperChainCounterChecker[wrapperChainCounter] = true;
    emit UnlockAndReturnToken(withdrawReceiver, originToken, wrappedToken, tokenData, tokenType, _originChain, _wrapperChain, wrapperChainCounter);
  }

  function _unlockAndReturnToken(
    address originToken,
    address withdrawReceiver,
    bytes memory tokenData,
    bytes32 tokenType
    ) private {
      require(originToken != address(0), "Bridge: unlockAndReturnToken to zero contract address"); //originToWrapped Token에서 걸러짐
      require(withdrawReceiver != address(0), "Bridge: unlockAndReturnToken to the zero address");
    address custody = typeToCustody(tokenType);
    ICustody(custody).unlockToken(originToken, withdrawReceiver, tokenData);
  }

  function mapToken(
    address originToken,
    address wrappedToken,
    bytes32 tokenType,
    bool wrapped
  )
    public 
    onlyOwner
    whenNotPaused
  {
    require(originToken != address(0), "Bridge: mapToken from the zero address");
    require(wrappedToken != address(0), "Bridge: mapToken to the zero address");
    mappingContract.mapToken(originToken, wrappedToken, tokenType, wrapped);
    emit TokenMapped(originToken, wrappedToken, tokenType);
  }

  function cleanMapToken(
    address originToken,
    address wrappedToken,
    bool wrapped
  ) 
    public
    onlyOwner
    whenNotPaused
  {
    require(originToken != address(0), "Bridge: mapToken from the zero address");
    require(wrappedToken != address(0), "Bridge: mapToken to the zero address");
    mappingContract.cleanMapToken(originToken, wrappedToken, wrapped);
    emit TokenMapped(originToken, wrappedToken, bytes32(0));
  }

  function remapToken(
    address originToken,
    address wrappedToken,
    bool wrapped
  )
    public
    onlyOwner
    whenNotPaused
  {
    mappingContract.remapToken(originToken, wrappedToken, wrapped);
    bytes32 tokenType = mappingContract.tokenToType(originToken);
    emit TokenMapped(originToken, wrappedToken, tokenType);
  }

  function clearOriginChainCounterChecker (uint256 originChainCounter) public onlyOwner {
    require(_originChainCounterChecker[originChainCounter] != false, "Bridge: originChainCounter is already cleared");
    _originChainCounterChecker[originChainCounter] = false;
    emit ClearOriginChainCounterChecker(originChainCounter);
  }

  function clearWrapperChainCounterChecker (uint256 wrapperChainCounter) public onlyOwner {
    require(_wrapperChainCounterChecker[wrapperChainCounter] != false, "Bridge: wrapperChainCounter is already cleared");
    _wrapperChainCounterChecker[wrapperChainCounter] = false;
    emit ClearWrapperChainCounterChecker(wrapperChainCounter);
  }

  function getOriginChain() public view returns (uint256) {
    return _originChain;
  }

  function getWrapperChain() public view returns (uint256) {
    return _wrapperChain;
  }

  function getOriginChainCounter() public view returns (uint256) {
    return _originChainCounter;
  }

  function getWrapperChainCounter() public view returns (uint256) {
    return _wrapperChainCounter;
  }

  function setCustody(address custody, bytes32 tokenType) public onlyOwner{
    require(custody != address(0), "Bridge: new custody Address should exist");
    require(_typeToCustody[tokenType] != custody, "Bridge: custody Address is already exist");
    _typeToCustody[tokenType] = custody;
    emit CustodyChanged(custody, tokenType);
  }

  function typeToCustody(bytes32 tokenType) public view returns (address) {
    address custody = _typeToCustody[tokenType];
    require(custody != address(0), "Bridge: typeToCustody query for nonexistent custody address");

    return custody;
  }

  function setMappingContractAddress(address mappingContractAddress) public onlyOwner{
    require(mappingContractAddress != address(0), "Bridge: mapping contract address should exist");
    mappingContract = IMapping(mappingContractAddress);
    emit MappingContractChanged(mappingContractAddress);
  }

  function getMappingContractAddress() public view returns (address) {
    return address(mappingContract);
  }

  function getOriginChainCounterChecker(uint256 originChainCounter) public view returns (bool) {
    return _originChainCounterChecker[originChainCounter];
  }

  function getWrapperChainCounterChecker(uint256 wrapperChainCounter) public view returns (bool) {
    return _wrapperChainCounterChecker[wrapperChainCounter];
  }
  

}