/**
 *Submitted for verification at Etherscan.io on 2022-02-15
*/

// Dependency file: openzeppelin-solidity/contracts/introspection/IERC165.sol

// pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * [EIP](https://eips.ethereum.org/EIPS/eip-165).
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others (`ERC165Checker`).
 *
 * For an implementation, see `ERC165`.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}


// Dependency file: openzeppelin-solidity/contracts/token/ERC721/IERC721.sol

// pragma solidity ^0.5.0;

// import "openzeppelin-solidity/contracts/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
contract IERC721 is IERC165 {
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of NFTs in `owner`'s account.
     */
    function balanceOf(address owner) public view returns (uint256 balance);

    /**
     * @dev Returns the owner of the NFT specified by `tokenId`.
     */
    function ownerOf(uint256 tokenId) public view returns (address owner);

    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * 
     *
     * Requirements:
     * - `from`, `to` cannot be zero.
     * - `tokenId` must be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this
     * NFT by either `approve` or `setApproveForAll`.
     */
    function safeTransferFrom(address from, address to, uint256 tokenId) public;
    /**
     * @dev Transfers a specific NFT (`tokenId`) from one account (`from`) to
     * another (`to`).
     *
     * Requirements:
     * - If the caller is not `from`, it must be approved to move this NFT by
     * either `approve` or `setApproveForAll`.
     */
    function transferFrom(address from, address to, uint256 tokenId) public;
    function approve(address to, uint256 tokenId) public;
    function getApproved(uint256 tokenId) public view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) public;
    function isApprovedForAll(address owner, address operator) public view returns (bool);


    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data) public;
}


// Dependency file: openzeppelin-solidity/contracts/access/Roles.sol

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


// Dependency file: openzeppelin-solidity/contracts/access/roles/SignerRole.sol

// pragma solidity ^0.5.0;

// import "openzeppelin-solidity/contracts/access/Roles.sol";

contract SignerRole {
    using Roles for Roles.Role;

    event SignerAdded(address indexed account);
    event SignerRemoved(address indexed account);

    Roles.Role private _signers;

    constructor () internal {
        _addSigner(msg.sender);
    }

    modifier onlySigner() {
        require(isSigner(msg.sender), "SignerRole: caller does not have the Signer role");
        _;
    }

    function isSigner(address account) public view returns (bool) {
        return _signers.has(account);
    }

    function addSigner(address account) public onlySigner {
        _addSigner(account);
    }

    function renounceSigner() public {
        _removeSigner(msg.sender);
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


// Dependency file: openzeppelin-solidity/contracts/access/roles/PauserRole.sol

// pragma solidity ^0.5.0;

// import "openzeppelin-solidity/contracts/access/Roles.sol";

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


// Dependency file: openzeppelin-solidity/contracts/lifecycle/Pausable.sol

// pragma solidity ^0.5.0;

// import "openzeppelin-solidity/contracts/access/roles/PauserRole.sol";

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


// Dependency file: contracts/ICustody.sol

// pragma solidity ^0.5.0;

interface ICustody {
  event LockToken(
    bytes32 tokenType,
    address indexed depositor,
    address indexed depositReceiver,
    address indexed wrappedToken,
    bytes tokenData
  );

  event UnlockToken(
    bytes32 tokenType,
    address indexed withdrawReceiver,
    address indexed originToken,
    bytes tokenData
  );

  event MintWrappedToken(
    bytes32 tokenType,
    address indexed depositReceiver,
    address indexed originToken,
    bytes tokenData
  );

  event BurnWrappedToken(
    bytes32 tokenType,
    address indexed withdrawer,
    address indexed wrappedToken,
    bytes tokenData
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
  event TokenMapped(
    address indexed originToken,
    address indexed wrappedToken,
    bytes32 tokenType,
    uint256 originChain,
    uint256 wrapperChain
  );

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
    uint256 wrapperChain
  );

  event MintWrappedToken(
    address indexed depositReceiver,
    address originToken,
    address indexed wrappedToken,
    bytes tokenData,  
    bytes32 tokenType,
    uint256 originChain,
    uint256 wrapperChain
  );

  event CustodyChanged(address custody, bytes32 tokenType);
  // event BridgePaused(address from); 
  // event BridgeResumed(address from);

  function getOriginChain() external view returns (uint256);
  function getWrapperChain() external view returns (uint256);
  function getOriginChainCounter() external view returns (uint256);
  function getWrapperChainCounter() external view returns (uint256);

  function originToWrappedToken(address originToken) external view returns (address);
  function wrappedToOriginToken(address wrappedToken) external view returns (address);
  function typeToCustody(bytes32 tokenType) external view returns (address);
}

// Root file: contracts/Bridge.sol

pragma solidity ^0.5.0;

// import '/Users/lambda256/git/luniverse-bridge-contract/node_modules/openzeppelin-solidity/contracts/token/ERC721/IERC721.sol';
// import '/Users/lambda256/git/luniverse-bridge-contract/node_modules/openzeppelin-solidity/contracts/access/roles/SignerRole.sol';
// import '/Users/lambda256/git/luniverse-bridge-contract/node_modules/openzeppelin-solidity/contracts/math/SafeMath.sol';
// import '/Users/lambda256/git/luniverse-bridge-contract/node_modules/openzeppelin-solidity/contracts/lifecycle/Pausable.sol';
// import 'contracts/ICustody.sol';
// import 'contracts/IBridge.sol';

contract Bridge is IBridge, SignerRole, Pausable{
  using SafeMath for uint256;
  uint256 private _originChain;
  uint256 private _wrapperChain;
  uint256 private _originChainCounter;
  uint256 private _wrapperChainCounter;

  mapping(address => address) private _originToWrappedToken;
  mapping(address => address) private _wrappedToOriginToken;
  mapping(bytes32 => address) private _typeToCustody;
  mapping(address => bytes32) private _tokenToType;
  mapping(uint256 => bool) private _originChainCounterChecker;
  mapping(uint256 => bool) private _wrapperChainCounterChecker;

  constructor(
    uint256 originChain,
    uint256 wrapperChain
  ) public {
    _originChain = originChain;
    _wrapperChain = wrapperChain;
  }

  function mapToken(address originToken, address wrappedToken, bytes32 tokenType) 
    public
    onlySigner
    whenNotPaused
  {
      require(
      _originToWrappedToken[originToken] == address(0) &&
      _wrappedToOriginToken[wrappedToken] == address(0),
      "Bridge: ALREADY_MAPPED"
      );
    _mapToken(originToken, wrappedToken, tokenType);
  }

  function cleanMapToken(address originToken, address wrappedToken) 
    public 
    onlySigner
    whenNotPaused
  {
    _originToWrappedToken[originToken] = address(0);
    _wrappedToOriginToken[wrappedToken] = address(0);
    _tokenToType[originToken] = bytes32(0);

    emit TokenMapped(originToken, wrappedToken, _tokenToType[originToken], _originChain, _wrapperChain);
  } //if tokenType is zero byte it means clean

  function remapToken(address originToken, address wrappedToken) 
    public 
    onlySigner
    whenNotPaused
  {
    address oldWrappedToken = _originToWrappedToken[originToken];
    address oldOriginToken = _wrappedToOriginToken[wrappedToken];

    if (_originToWrappedToken[oldOriginToken] != address(0)) {
        _originToWrappedToken[oldOriginToken] = address(0);
        _tokenToType[oldOriginToken] = bytes32(0);
    }

    if (_wrappedToOriginToken[oldWrappedToken] != address(0)) {
        _wrappedToOriginToken[oldWrappedToken] = address(0);
    }

    _mapToken(originToken, wrappedToken, _tokenToType[originToken]);
  }

  function _mapToken (
    address originToken, 
    address wrappedToken, 
    bytes32 tokenType
  ) private {
      require(originToken != address(0), "Bridge: mapToken from the zero address");
      require(wrappedToken != address(0), "Bridge: mapToken to the zero address");

      require(
        _typeToCustody[tokenType] != address(0x0),
        "Bridge: TOKEN_TYPE_NOT_SUPPORTED"
      );

      _originToWrappedToken[originToken] = wrappedToken;
      _wrappedToOriginToken[wrappedToken] = originToken;
      _tokenToType[originToken] = tokenType;
      emit TokenMapped(originToken, wrappedToken, tokenType, _originChain, _wrapperChain);
  }

  function deposit(
      address depositReceiver,
      address originToken,
      bytes memory tokenData,
      bytes32 tokenType
  ) 
    public
    whenNotPaused
  {
    require(originToken != address(0), "Bridge: deposit to the zero contract address");
    _deposit(msg.sender,depositReceiver,originToken,tokenData,tokenType);
    _originChainCounterChecker[_originChainCounter] = true;
    _originChainCounter = _originChainCounter.add(1);
    address wrappedToken = originToWrappedToken(originToken);
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
    bytes memory tokenData,
    bytes32 tokenType
  )
    public
    whenNotPaused
  {
    require(withdrawReceiver != address(0), "Bridge: withdraw to the zero address");
    _withdraw(msg.sender, wrappedToken, tokenData, tokenType);
    _wrapperChainCounterChecker[_wrapperChainCounter] = true;
    _wrapperChainCounter = _wrapperChainCounter.add(1);
    address originToken = wrappedToOriginToken(wrappedToken);
    emit Withdraw(msg.sender, withdrawReceiver, originToken, wrappedToken, tokenData, tokenType, _originChain, _wrapperChain, _wrapperChainCounter);
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
    bytes32 tokenType
    )
      public
      onlySigner
      whenNotPaused
     {
      require(
        _wrapperChainCounterChecker[_wrapperChainCounter] = true,
        "Bridge: WrapperChainCounter is invalid"
      );
      require(
        wrappedToOriginToken(wrappedToken) != address(0x0),
        "Bridge: TOKEN_ADDRESS_NOT_MAPPED"
      );
      _mintWrappedToken(wrappedToken, depositReceiver, tokenData, tokenType);
      address originToken = wrappedToOriginToken(wrappedToken);
      emit MintWrappedToken(depositReceiver, originToken, wrappedToken, tokenData, tokenType, _originChain, _wrapperChain);
  }

  function _mintWrappedToken(
    address wrappedToken, 
    address depositReceiver, 
    bytes memory tokenData,
    bytes32 tokenType
    ) private {
      require(wrappedToken != address(0), "Bridge: mintWrappedToken to the zero contract address");
      require(depositReceiver != address(0), "Bridge: mintWrappedToken to the zero address");
      address custody = typeToCustody(tokenType);
      ICustody(custody).mintWrappedToken(wrappedToken, depositReceiver, tokenData);
  }

  function unlockAndReturnToken(
    address originToken,
    address withdrawReceiver,
    bytes memory tokenData,
    bytes32 tokenType
    )
      public
      onlySigner
      whenNotPaused
     {
      require(
        _originChainCounterChecker[_originChainCounter] = true,
        "Bridge: OriginChainCounter is invalid"
      );
      require(
        originToWrappedToken(originToken) != address(0x0),
        "Bridge: TOKENADDRESS_NOT_MAPPED"
      );
    _unlockAndReturnToken(originToken, withdrawReceiver, tokenData, tokenType);
    address wrappedToken = originToWrappedToken(originToken);
    emit UnlockAndReturnToken(withdrawReceiver, originToken, wrappedToken, tokenData, tokenType, _originChain, _wrapperChain);
  }

  function _unlockAndReturnToken(
    address originToken,
    address withdrawReceiver,
    bytes memory tokenData,
    bytes32 tokenType
    ) private {
      require(originToken != address(0), "Bridge: unlockAndReturnToken to zero contract address");
      require(withdrawReceiver != address(0), "Bridge: unlockAndReturnToken to the zero address");
    address custody = typeToCustody(tokenType);
    ICustody(custody).unlockToken(originToken, withdrawReceiver, tokenData);
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

  function originToWrappedToken(address originToken) public view returns (address) {
    address wrappedTokenResult = _originToWrappedToken[originToken];
    require(wrappedTokenResult != address(0), "Bridge: originToWrappedToken query for nonexistent token");

    return wrappedTokenResult;
  }

  function wrappedToOriginToken(address wrappedToken) public view returns (address) {
    address originTokenResult = _wrappedToOriginToken[wrappedToken];
    require(originTokenResult != address(0), "Bridge: wrappedToOriginToken query for nonexistent token");

    return originTokenResult;
  }

  function setCustody(address custody, bytes32 tokenType) public onlySigner{
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

  function tokenToType(address token) public view returns (bytes32) {
    bytes32 tokenType = _tokenToType[token];
    require(tokenType != bytes32(0), "Bridge: typeToCustody query for nonexistent type");

    return tokenType;
  }
}