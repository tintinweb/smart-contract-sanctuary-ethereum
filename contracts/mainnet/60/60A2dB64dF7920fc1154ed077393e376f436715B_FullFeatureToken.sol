// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Pausable.sol";
import { Helpers } from "./lib/Helpers.sol";

contract FullFeatureToken is ERC20, ERC20Burnable, ERC20Pausable, Ownable {
  /// @notice mapping of blacklisted addresses to a boolean
  mapping(address => bool) private _isBlacklisted;
  /// @notice mapping of whitelisted addresses to a boolean
  mapping(address => bool) public whitelist;
  /// @notice array holding all whitelisted addresses
  address[] public whitelistedAddresses;
  /// @notice support for attaching of documentation for security tokens
  string public initialDocumentUri;
  /// @notice the security token documentation
  string public documentUri;
  /// @notice initial number of tokens which will be minted during initialization
  uint256 public immutable initialSupply;
  /// @notice initial max amount of tokens allowed per wallet
  uint256 public immutable initialMaxTokenAmountPerAddress;
  /// @notice max amount of tokens allowed per wallet
  uint256 public maxTokenAmountPerAddress;
  /// @notice set of features supported by the token
  struct ERC20ConfigProps {
    bool _isMintable;
    bool _isBurnable;
    bool _isPausable;
    bool _isBlacklistEnabled;
    bool _isDocumentAllowed;
    bool _isWhitelistEnabled;
    bool _isMaxAmountOfTokensSet;
    bool _isForceTransferAllowed;
  }
  /// @notice features of the token
  ERC20ConfigProps private configProps;
  /// @notice owner of the contract
  address public immutable initialTokenOwner;
  /// @notice number of decimals of the token
  uint8 private immutable _decimals;

  /// @notice emitted when an address is blacklisted
  event UserBlacklisted(address indexed addr);
  /// @notice emitted when an address is unblacklisted
  event UserUnBlacklisted(address indexed addr);
  /// @notice emitted when a new document is set for the security token
  event DocumentUriSet(string newDocUri);
  /// @notice emitted when a new max amount of tokens per wallet is set
  event MaxTokenAmountPerSet(uint256 newMaxTokenAmount);
  /// @notice emitted when a new whitelist is set
  event UsersWhitelisted(address[] updatedAddresses);

  /// @notice raised when the amount sent is zero
  error InvalidMaxTokenAmount(uint256 maxTokenAmount);
  /// @notice raised when the decimals are not in the range 0 - 18
  error InvalidDecimals(uint8 decimals);
  /// @notice raised when setting maxTokenAmount less than current
  error MaxTokenAmountPerAddrLtPrevious();
  /// @notice raised when blacklisting is not enabled
  error BlacklistNotEnabled();
  /// @notice raised when the address is already blacklisted
  error AddrAlreadyBlacklisted(address addr);
  /// @notice raised when the address is already unblacklisted
  error AddrAlreadyUnblacklisted(address addr);
  /// @notice raised when attempting to blacklist a whitelisted address
  error CannotBlacklistWhitelistedAddr(address addr);
  /// @notice raised when a recipient address is blacklisted
  error RecipientBlacklisted(address addr);
  /// @notice raised when a sender address is blacklisted
  error SenderBlacklisted(address addr);
  /// @notice raised when a recipient address is not whitelisted
  error RecipientNotWhitelisted(address addr);
  /// @notice raised when a sender address is not whitelisted
  error SenderNotWhitelisted(address addr);
  /// @notice raised when recipient balance exceeds maxTokenAmountPerAddress
  error DestBalanceExceedsMaxAllowed(address addr);
  /// @notice raised minting is not enabled
  error MintingNotEnabled();
  /// @notice raised when burning is not enabled
  error BurningNotEnabled();
  /// @notice raised when pause is not enabled
  error PausingNotEnabled();
  /// @notice raised when whitelist is not enabled
  error WhitelistNotEnabled();
  /// @notice raised when attempting to whitelist a blacklisted address
  error CannotWhitelistBlacklistedAddr(address addr);
  /// @notice raised when trying to set a document URI when not allowed
  error DocumentUriNotAllowed();

  /**
   * @notice modifier for validating if transfer is possible and valid
   * @param sender the sender of the transaction
   * @param recipient the recipient of the transaction
   */
  modifier validateTransfer(address sender, address recipient) {
    if (isWhitelistEnabled()) {
      if (!whitelist[sender]) {
        revert SenderNotWhitelisted(sender);
      }
      if (!whitelist[recipient]) {
        revert RecipientNotWhitelisted(recipient);
      }
    }
    if (isBlacklistEnabled()) {
      if (_isBlacklisted[sender]) {
        revert SenderBlacklisted(sender);
      }
      if (_isBlacklisted[recipient]) {
        revert RecipientBlacklisted(recipient);
      }
    }
    _;
  }

  constructor(
    string memory name_,
    string memory symbol_,
    uint256 initialSupplyToSet,
    uint8 decimalsToSet,
    address tokenOwner,
    ERC20ConfigProps memory customConfigProps,
    uint256 maxTokenAmount,
    string memory newDocumentUri
  ) ERC20(name_, symbol_) {
    if (customConfigProps._isMaxAmountOfTokensSet) {
      if (maxTokenAmount == 0) {
        revert InvalidMaxTokenAmount(maxTokenAmount);
      }
    }
    if (decimalsToSet > 18) {
      revert InvalidDecimals(decimalsToSet);
    }
    Helpers.validateAddress(tokenOwner);

    initialSupply = initialSupplyToSet;
    initialMaxTokenAmountPerAddress = maxTokenAmount;
    initialDocumentUri = newDocumentUri;
    initialTokenOwner = tokenOwner;
    _decimals = decimalsToSet;
    configProps = customConfigProps;
    documentUri = newDocumentUri;
    maxTokenAmountPerAddress = maxTokenAmount;

    if (initialSupplyToSet != 0) {
      _mint(tokenOwner, initialSupplyToSet * 10**decimalsToSet);
    }

    if (tokenOwner != msg.sender) {
      transferOwnership(tokenOwner);
    }
  }

  /**
   * @notice hook called before any transfer of tokens. This includes minting and burning
   * imposed by the ERC20 standard
   * @param from - address of the sender
   * @param to - address of the recipient
   * @param amount - amount of tokens to transfer
   */
  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 amount
  ) internal virtual override(ERC20, ERC20Pausable) {
    super._beforeTokenTransfer(from, to, amount);
  }

  /// @notice method which checks if the token is pausable
  function isPausable() public view returns (bool) {
    return configProps._isPausable;
  }

  /// @notice method which checks if the token is mintable
  function isMintable() public view returns (bool) {
    return configProps._isMintable;
  }

  /// @notice method which checks if the token is burnable
  function isBurnable() public view returns (bool) {
    return configProps._isBurnable;
  }

  /// @notice method which checks if the token supports blacklisting
  function isBlacklistEnabled() public view returns (bool) {
    return configProps._isBlacklistEnabled;
  }

  /// @notice method which checks if the token supports whitelisting
  function isWhitelistEnabled() public view returns (bool) {
    return configProps._isWhitelistEnabled;
  }

  /// @notice method which checks if the token supports max amount of tokens per wallet
  function isMaxAmountOfTokensSet() public view returns (bool) {
    return configProps._isMaxAmountOfTokensSet;
  }

  /// @notice method which checks if the token supports documentUris
  function isDocumentUriAllowed() public view returns (bool) {
    return configProps._isDocumentAllowed;
  }

  /// @notice method which checks if the token supports force transfers
  function isForceTransferAllowed() public view returns (bool) {
    return configProps._isForceTransferAllowed;
  }

  /// @notice method which returns the number of decimals for the token
  function decimals() public view virtual override returns (uint8) {
    return _decimals;
  }

  /**
   * @notice which returns an array of all the whitelisted addresses
   * @return whitelistedAddresses array of all the whitelisted addresses
   */
  function getWhitelistedAddresses() external view returns (address[] memory) {
    return whitelistedAddresses;
  }

  /**
   * @notice method which allows the owner to set a documentUri
   * @param newDocumentUri - the new documentUri
   * @dev only callable by the owner
   */
  function setDocumentUri(string memory newDocumentUri) external onlyOwner {
    if (!isDocumentUriAllowed()) {
      revert DocumentUriNotAllowed();
    }
    documentUri = newDocumentUri;
    emit DocumentUriSet(newDocumentUri);
  }

  /**
   * @notice method which allows the owner to set a max amount of tokens per wallet
   * @param newMaxTokenAmount - the new max amount of tokens per wallet
   * @dev only callable by the owner
   */
  function setMaxTokenAmountPerAddress(uint256 newMaxTokenAmount)
    external
    onlyOwner
  {
    if (newMaxTokenAmount <= maxTokenAmountPerAddress) {
      revert MaxTokenAmountPerAddrLtPrevious();
    }

    maxTokenAmountPerAddress = newMaxTokenAmount;
    emit MaxTokenAmountPerSet(newMaxTokenAmount);
  }

  /**
   * @notice method which allows the owner to blacklist an address
   * @param addr - the address to blacklist
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   * @dev only callable if the token supports blacklisting
   * @dev only callable if the address is not already blacklisted
   * @dev only callable if the address is not whitelisted
   */
  function blackList(address addr) external onlyOwner whenNotPaused {
    Helpers.validateAddress(addr);
    if (!isBlacklistEnabled()) {
      revert BlacklistNotEnabled();
    }
    if (_isBlacklisted[addr]) {
      revert AddrAlreadyBlacklisted(addr);
    }
    if (isWhitelistEnabled() && whitelist[addr]) {
      revert CannotBlacklistWhitelistedAddr(addr);
    }

    _isBlacklisted[addr] = true;
    emit UserBlacklisted(addr);
  }

  /**
   * @notice method which allows the owner to unblacklist an address
   * @param addr - the address to unblacklist
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   * @dev only callable if the token supports blacklisting
   * @dev only callable if the address is blacklisted
   */
  function removeFromBlacklist(address addr) external onlyOwner whenNotPaused {
    Helpers.validateAddress(addr);
    if (!isBlacklistEnabled()) {
      revert BlacklistNotEnabled();
    }
    if (!_isBlacklisted[addr]) {
      revert AddrAlreadyUnblacklisted(addr);
    }

    _isBlacklisted[addr] = false;
    emit UserUnBlacklisted(addr);
  }

  /**
   * @notice method which allows to transfer a predefined amount of tokens to a predefined address
   * @param to - the address to transfer the tokens to
   * @param amount - the amount of tokens to transfer
   * @return true if the transfer was successful
   * @dev only callable if the token is not paused
   * @dev only callable if the balance of the receiver is lower than the max amount of tokens per wallet
   * @dev checks if blacklisting is enabled and if the sender and receiver are not blacklisted
   * @dev checks if whitelisting is enabled and if the sender and receiver are whitelisted
   */
  function transfer(address to, uint256 amount)
    public
    virtual
    override
    whenNotPaused
    validateTransfer(msg.sender, to)
    returns (bool)
  {
    if (isMaxAmountOfTokensSet()) {
      if (balanceOf(to) + amount > maxTokenAmountPerAddress) {
        revert DestBalanceExceedsMaxAllowed(to);
      }
    }
    return super.transfer(to, amount);
  }

  /**
   * @notice method which allows to transfer a predefined amount of tokens from a predefined address to a predefined address
   * @param from - the address to transfer the tokens from
   * @param to - the address to transfer the tokens to
   * @param amount - the amount of tokens to transfer
   * @return true if the transfer was successful
   * @dev only callable if the token is not paused
   * @dev only callable if the balance of the receiver is lower than the max amount of tokens per wallet
   * @dev checks if blacklisting is enabled and if the sender and receiver are not blacklisted
   * @dev checks if whitelisting is enabled and if the sender and receiver are whitelisted
   */
  function transferFrom(
    address from,
    address to,
    uint256 amount
  )
    public
    virtual
    override
    whenNotPaused
    validateTransfer(from, to)
    returns (bool)
  {
    if (isMaxAmountOfTokensSet()) {
      if (balanceOf(to) + amount > maxTokenAmountPerAddress) {
        revert DestBalanceExceedsMaxAllowed(to);
      }
    }

    if (isForceTransferAllowed() && owner() == msg.sender) {
      _transfer(from, to, amount);
      return true;
    } else {
      return super.transferFrom(from, to, amount);
    }
  }

  /**
   * @notice method which allows to mint a predefined amount of tokens to a predefined address
   * @param to - the address to mint the tokens to
   * @param amount - the amount of tokens to mint
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   * @dev only callable if the token supports additional minting
   * @dev only callable if the balance of the receiver is lower than the max amount of tokens per wallet
   * @dev checks if blacklisting is enabled and if the receiver is not blacklisted
   * @dev checks if whitelisting is enabled and if the receiver is whitelisted
   */
  function mint(address to, uint256 amount) external onlyOwner whenNotPaused {
    if (!isMintable()) {
      revert MintingNotEnabled();
    }
    if (isMaxAmountOfTokensSet()) {
      if (balanceOf(to) + amount > maxTokenAmountPerAddress) {
        revert DestBalanceExceedsMaxAllowed(to);
      }
    }
    if (isBlacklistEnabled()) {
      if (_isBlacklisted[to]) {
        revert RecipientBlacklisted(to);
      }
    }
    if (isWhitelistEnabled()) {
      if (!whitelist[to]) {
        revert RecipientNotWhitelisted(to);
      }
    }

    super._mint(to, amount);
  }

  /**
   * @notice method which allows to burn a predefined amount of tokens
   * @param amount - the amount of tokens to burn
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   * @dev only callable if the token supports burning
   */
  function burn(uint256 amount) public override onlyOwner whenNotPaused {
    if (!isBurnable()) {
      revert BurningNotEnabled();
    }
    super.burn(amount);
  }

  /**
   * @notice method which allows to burn a predefined amount of tokens from a predefined address
   * @param from - the address to burn the tokens from
   * @param amount - the amount of tokens to burn
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   * @dev only callable if the token supports burning
   */
  function burnFrom(address from, uint256 amount)
    public
    override
    onlyOwner
    whenNotPaused
  {
    if (!isBurnable()) {
      revert BurningNotEnabled();
    }
    super.burnFrom(from, amount);
  }

  /**
   * @notice method which allows to pause the token
   * @dev only callable by the owner
   */
  function pause() external onlyOwner {
    if (!isPausable()) {
      revert PausingNotEnabled();
    }
    _pause();
  }

  /**
   * @notice method which allows to unpause the token
   * @dev only callable by the owner
   */
  function unpause() external onlyOwner {
    if (!isPausable()) {
      revert PausingNotEnabled();
    }
    _unpause();
  }

  /**
   * @notice method which allows to removing the owner of the token
   * @dev methods which are only callable by the owner will not be callable anymore
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   */
  function renounceOwnership() public override onlyOwner whenNotPaused {
    super.renounceOwnership();
  }

  /**
   * @notice method which allows to transfer the ownership of the token
   * @param newOwner - the address of the new owner
   * @dev only callable by the owner
   * @dev only callable if the token is not paused
   */
  function transferOwnership(address newOwner)
    public
    override
    onlyOwner
    whenNotPaused
  {
    super.transferOwnership(newOwner);
  }

  /**
   * @notice method which allows to update the whitelist of the token
   * @param updatedAddresses - the new set of addresses
   * @dev only callable by the owner
   * @dev only callable if the token supports whitelisting
   */
  function updateWhitelist(address[] calldata updatedAddresses)
    external
    onlyOwner
  {
    if (!isWhitelistEnabled()) {
      revert WhitelistNotEnabled();
    }
    _clearWhitelist();
    _addManyToWhitelist(updatedAddresses);
    whitelistedAddresses = updatedAddresses;
    emit UsersWhitelisted(updatedAddresses);
  }

  /**
   * @notice method which allows for adding a new set of addresses to the whitelist
   * @param addresses - the addresses to add to the whitelist
   * @dev called internally by the contract
   * @dev only callable if any of the addresses are not already whitelisted
   */
  function _addManyToWhitelist(address[] calldata addresses) private {
    for (uint256 i; i < addresses.length; ) {
      Helpers.validateAddress(addresses[i]);
      if (configProps._isBlacklistEnabled && _isBlacklisted[addresses[i]]) {
        revert CannotWhitelistBlacklistedAddr(addresses[i]);
      }
      whitelist[addresses[i]] = true;
      unchecked {
        ++i;
      }
    }
  }

  /**
   * @notice method which allows for removing a set of addresses from the whitelist
   */
  function _clearWhitelist() private {
    unchecked {
      address[] memory addresses = whitelistedAddresses;
      for (uint256 i; i < addresses.length; i++) {
        whitelist[addresses[i]] = false;
      }
    }
  }
}

// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.7;

library Helpers {
  /// @notice raised when an address is zero
  error NonZeroAddress(address addr);
  /// @notice raised when payment fails
  error PaymentFailed(address to, uint256 amount);

  /**
   * @notice Helper function to check if an address is a zero address
   * @param addr - address to check
   */
  function validateAddress(address addr) internal pure {
    if (addr == address(0x0)) {
      revert NonZeroAddress(addr);
    }
  }

  /**
   * @notice method to pay a specific address with a specific amount
   * @dev inspired from https://github.com/transmissions11/solmate/blob/main/src/utils/SafeTransferLib.sol
   * @param to - the address to pay
   * @param amount - the amount to pay
   */
  function safeTransferETH(address to, uint256 amount) internal {
    bool success;
    // solhint-disable-next-line no-inline-assembly
    assembly {
      // Transfer the ETH and store if it succeeded or not.
      success := call(gas(), to, amount, 0, 0, 0, 0)
    }
    if (!success) {
      revert PaymentFailed(to, amount);
    }
  }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
        }
        _balances[to] += amount;

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Pausable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../security/Pausable.sol";

/**
 * @dev ERC20 token with pausable token transfers, minting and burning.
 *
 * Useful for scenarios such as preventing trades until the end of an evaluation
 * period, or having an emergency switch for freezing all token transfers in the
 * event of a large bug.
 */
abstract contract ERC20Pausable is ERC20, Pausable {
    /**
     * @dev See {ERC20-_beforeTokenTransfer}.
     *
     * Requirements:
     *
     * - the contract must not be paused.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, amount);

        require(!paused(), "ERC20Pausable: token transfer while paused");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        _spendAllowance(account, _msgSender(), amount);
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}