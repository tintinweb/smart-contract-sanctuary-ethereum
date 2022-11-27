/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: contracts/4_Chat.sol


pragma solidity ^0.8.9;


// Error codes
uint8 constant ErrUserAlreadyInitialized = 1;
uint8 constant ErrChatNotInitialized = 2;
uint8 constant ErrUserNotInitialized = 3;
uint8 constant ErrPeerNotInitialized = 4; 
uint8 constant ErrIncorrectEntryFee = 5; 
error BlockchattingError(uint8 code);

/// @title Blockchatting: P2P Chatting via Smart Contracts
/// @author Erhan Tezcan (erhant)
/// @dev A chat contract that allows EOAs to send messages via their addresses
/// with end-to-end encryption and a symmetric key per peer
contract Chat is Ownable {
  /// @dev See `initializeUser` function
  struct UserInitialization {
    bytes encryptedUserSecret;
    bool publicKeyPrefix;
    bytes32 publicKeyX;
  }

  event MessageSent(address indexed _from, address indexed _to, string _message, uint256 _time);
  event EntryFeeChanged(uint256 amount);
  event UserInitialized(address indexed user);
  event ChatInitialized(address indexed initializer, address indexed peer);

  /// @notice Users must pay this entry fee to start using the application
  uint256 public entryFee = 0.008 ether;

  /// @notice Mapping of user to their initialization object
  mapping(address => UserInitialization) public userInitializations;

  /// @notice A shared secret between two users, encrypted by the public key of first user
  mapping(address => mapping(address => bytes)) public chatInitializations;

  /// @notice Checks if a user has been initialized
  /// @param user address
  function isUserInitialized(address user) public view returns (bool) {
    return
      !(userInitializations[user].encryptedUserSecret.length == 0 &&
        userInitializations[user].publicKeyX == bytes32(0));
  }

  /// @notice Checks if two users has initialized their chat
  /// @param initializer address
  /// @param peer address
  function isChatInitialized(address initializer, address peer) public view returns (bool) {
    return !(chatInitializations[initializer][peer].length == 0 && chatInitializations[peer][initializer].length == 0);
  }

  /// @notice Emits a MessageEvent, assuming chat is initialized
  /// @param ciphertext A message encrypted by the secret chatting key
  /// @param to recipient address
  function sendMessage(
    string calldata ciphertext,
    address to,
    uint256 time
  ) external {
    if (!isChatInitialized(msg.sender, to)) {
      revert BlockchattingError(ErrChatNotInitialized);
    } 
    emit MessageSent(msg.sender, to, ciphertext, time);
  }

  /// @notice Initializes a user, which allows two things:
  /// - user will be able to generate their own key on later logins, by retrieving the encrypted key-gen input and decrypt with their MetaMask
  /// - other users will be able to encrypt messages using this users public key
  /// @param encryptedUserSecret user secret to generate key-pair for the chatting application. it is encrypted by the MetaMask public key
  /// @param publicKeyPrefix prefix of the compressed key stored as a boolean (0x02: true, 0x03: false)
  /// @param publicKeyX 32-byte X-coordinate of the compressed key
  function initializeUser(
    bytes calldata encryptedUserSecret,
    bool publicKeyPrefix,
    bytes32 publicKeyX
  ) external payable {
    if (isUserInitialized(msg.sender)) {
      revert BlockchattingError(ErrUserAlreadyInitialized);
    }
    if (msg.value != entryFee) {
      revert BlockchattingError(ErrIncorrectEntryFee);
    } 
    userInitializations[msg.sender] = UserInitialization(encryptedUserSecret, publicKeyPrefix, publicKeyX);
    emit UserInitialized(msg.sender);
  }

  /// @notice Initializes a chatting session between two users: msg.sender and a given peer.
  /// A symmetric key is encrypted with both public keys once and stored for each
  /// @dev Both users must be initialized
  /// @param yourEncryptedChatSecret Symmetric key, encrypted by the msg.sender's public key
  /// @param peerEncryptedChatSecret Symmetric key, encrypted by the peer's public key
  /// @param peer address of the peer
  function initializeChat(
    bytes calldata yourEncryptedChatSecret,
    bytes calldata peerEncryptedChatSecret,
    address peer
  ) external {
    if (!isUserInitialized(msg.sender)) {
      revert BlockchattingError(ErrUserNotInitialized);
    }
    if (!isUserInitialized(peer)) {
      revert BlockchattingError(ErrPeerNotInitialized);
    } 
    chatInitializations[msg.sender][peer] = yourEncryptedChatSecret;
    chatInitializations[peer][msg.sender] = peerEncryptedChatSecret;
    emit ChatInitialized(msg.sender, peer);
  }

  /// @notice Changes the entry fee
  /// @param _entryFee new entry fee
  function setEntryFee(uint256 _entryFee) external onlyOwner {
    entryFee = _entryFee;
    emit EntryFeeChanged(_entryFee);
  }

  /// @notice Transfers the balance of the contract to the owner
  function withdraw() external onlyOwner {
    payable(owner()).transfer(address(this).balance);
  }

  receive() external payable {}
  fallback() external payable {}
}