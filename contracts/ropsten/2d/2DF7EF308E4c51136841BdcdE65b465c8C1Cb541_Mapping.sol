/**
 *Submitted for verification at Etherscan.io on 2022-03-15
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

    function addPauser(address account) public onlyPauser {
        _addPauser(account);
    }

    function renouncePauser() public {
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


// Dependency file: contracts/access/roles/SignerRole.sol

// pragma solidity ^0.5.0;

// import "contracts/access/Roles.sol";

contract SignerRole {
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    constructor () internal {
        _addSigner(msg.sender);
        _addSigner(0xb7e6D05813eDf46cB6BE7070b7C8D5DEE539A2f0); //2번째 관리자 주소값 직접 추가
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

  function mapToken(address originToken, address wrappedToken, bytes32 tokenType) external;
  function cleanMapToken(address originToken, address wrappedToken) external;
  function remapToken(address originToken, address wrappedToken) external;

  function originToWrappedToken(address originToken) external view returns (address);
  function wrappedToOriginToken(uint256 wrapperChain, address wrappedToken) external view returns (address);
  function tokenToType(address originToken) external view returns (bytes32);
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
    bytes32 tokenType,
    uint256 originChain,
    uint256 wrapperChain
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

// Root file: contracts/mapping/Mapping.sol

pragma solidity ^0.5.0;
// import '/Users/lambda256/git/luniverse-bridge-contract/node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol';
// import 'contracts/lifecycle/Pausable.sol';
// import 'contracts/access/roles/SignerRole.sol';
// import 'contracts/mapping/IMapping.sol';
// import 'contracts/IBridge.sol';

contract Mapping is IMapping, SignerRole, Pausable{
  using SafeMath for uint256;
  uint256 private _originChain;

  mapping(address => bool) private _isBridge;
  mapping(address => address) private _originToWrappedToken;
  mapping(uint256 => mapping(address => address)) private _wrappedToOriginToken; //uint256, 1st key in mapping is wrapperChain ID to prevent conlfict from same CA address in dffrent chain
  mapping(address => bytes32) private _tokenToType;

  constructor(
    uint256 originChain
  ) public {
    _originChain = originChain;
  }

  modifier onlyBridge() {
    require(isBridge(msg.sender) == true, "Mapping: caller must be a registered bridge contract address");
    _;
  }

  function setBridge(address bridgeAddress)
    public
    onlySigner
    whenNotPaused
  {
    require(bridgeAddress != address(0), "Mapping: setBridge to the zero address");
    uint256 originChainCheck = IBridge(bridgeAddress).getOriginChain();
    require(_originChain == originChainCheck, "Mapping: Submitted bridge is from diffent chain");
    _isBridge[bridgeAddress] = true;
    emit BridgeSet(bridgeAddress);  
  }

  function cleanBridge(address bridgeAddress)
    public
    onlySigner
    whenNotPaused
  {
    require(_isBridge[bridgeAddress] != false, "Mapping: Bridge is already cleaned");
    _isBridge[bridgeAddress] = false;
    emit BridgeSet(bridgeAddress);
  }

  function mapToken(address originToken, address wrappedToken, bytes32 tokenType) 
    external
    onlyBridge
    whenNotPaused
  {
    require(originToken != address(0), "Mapping: mapToken from the zero address");
    require(wrappedToken != address(0), "Mapping: mapToken to the zero address");

    uint256 wrapperChain = IBridge(msg.sender).getWrapperChain();
    require(
      _originToWrappedToken[originToken] == address(0) &&
      _wrappedToOriginToken[wrapperChain][wrappedToken] == address(0),
      "Mapping: ALREADY_MAPPED"
    );

    _mapToken(originToken, wrappedToken, tokenType, msg.sender, wrapperChain);
  }

  function cleanMapToken(address originToken, address wrappedToken) 
    external
    onlyBridge
    whenNotPaused
  {
    require(originToken != address(0), "Mapping: mapToken from the zero address");
    require(wrappedToken != address(0), "Mapping: mapToken to the zero address");

    uint256 wrapperChain = IBridge(msg.sender).getWrapperChain();
    _originToWrappedToken[originToken] = address(0);
    _wrappedToOriginToken[wrapperChain][wrappedToken] = address(0);
    _tokenToType[originToken] = bytes32(0);

    emit TokenMapped(originToken, wrappedToken, _tokenToType[originToken], _originChain, wrapperChain, msg.sender);
  } //if tokenType is zero byte it means clean

  function remapToken(address originToken, address wrappedToken)
    external
    onlyBridge
    whenNotPaused
  {
    require(originToken != address(0), "Mapping: mapToken from the zero address");
    require(wrappedToken != address(0), "Mapping: mapToken to the zero address");
  
    bytes32 tokenType = _tokenToType[originToken];
    require(
      IBridge(msg.sender).typeToCustody(tokenType) != address(0x0),
      "Mapping: TOKEN_TYPE_NOT_SUPPORTED"
    );

    uint256 wrapperChain = IBridge(msg.sender).getWrapperChain();
    address oldWrappedToken = _originToWrappedToken[originToken];
    address oldOriginToken = _wrappedToOriginToken[wrapperChain][wrappedToken];

    if (_originToWrappedToken[oldOriginToken] != address(0)) {
        _originToWrappedToken[oldOriginToken] = address(0);
        _tokenToType[oldOriginToken] = bytes32(0);
    }

    if (_wrappedToOriginToken[wrapperChain][oldWrappedToken] != address(0)) {
        _wrappedToOriginToken[wrapperChain][oldWrappedToken] = address(0);
    }

    _mapToken(originToken, wrappedToken, tokenType, msg.sender, wrapperChain);
  }

  function _mapToken (
    address originToken, 
    address wrappedToken, 
    bytes32 tokenType,
    address bridgeAddress,
    uint256 wrapperChain
  ) private {
      require(tokenType != bytes32(0), "Mapping: TOKEN_TYPE_NOT_SUPPORTED");
      _originToWrappedToken[originToken] = wrappedToken;
      _wrappedToOriginToken[wrapperChain][wrappedToken] = originToken;
      _tokenToType[originToken] = tokenType;

      emit TokenMapped(originToken, wrappedToken, tokenType, _originChain, wrapperChain, bridgeAddress);
  }

  function originToWrappedToken(address originToken) public view returns (address) {
    address wrappedTokenResult = _originToWrappedToken[originToken];
    require(wrappedTokenResult != address(0), "Mapping: originToWrappedToken query for nonexistent token");

    return wrappedTokenResult;
  }

  function wrappedToOriginToken(uint256 wrapperChain, address wrappedToken) public view returns (address) {
    address originTokenResult = _wrappedToOriginToken[wrapperChain][wrappedToken];
    require(originTokenResult != address(0), "Mapping: wrappedToOriginToken query for nonexistent token");

    return originTokenResult;
  }

  function tokenToType(address originToken) public view returns (bytes32) {
    bytes32 tokenType = _tokenToType[originToken];
    require(tokenType != bytes32(0), "Mapping: typeToCustody query for nonexistent type");

    return tokenType;
  }

  function isBridge(address bridgeAddress) public view returns (bool) {
    return _isBridge[bridgeAddress];
  }

  function getOriginChain() public view returns (uint256) {
    return _originChain;
  }

}