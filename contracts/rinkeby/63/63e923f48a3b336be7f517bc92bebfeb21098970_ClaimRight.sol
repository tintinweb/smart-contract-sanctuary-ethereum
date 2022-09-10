/**
 *Submitted for verification at Etherscan.io on 2022-09-09
*/

// File: contracts/openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;


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

// File: contracts/openzeppelin/contracts/utils/Context.sol


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

// File: contracts/openzeppelin/contracts/token/ERC20/ERC20.sol


// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;




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
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
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

// File: contracts/openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/types/extensions/Address.sol



pragma solidity ^0.8.10;

library Address {

    function isContract(address account) internal view returns (bool) {
        uint256 size;
        
        assembly { 
            size := extcodesize(account)
        }
        
        return size > 0;
    }
}
// File: contracts/tokens/IERC721Receiver.sol



pragma solidity ^0.8.10;

interface IERC721Receiver {

    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}
// File: contracts/tokens/IERC165.sol



pragma solidity ^0.8.10;

interface IERC165 {

    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}
// File: contracts/tokens/IERC721.sol



pragma solidity ^0.8.10;


interface IERC721 is IERC165 {

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);

    function ownerOf(uint256 tokenId) external view returns (address owner);

    function safeTransferFrom(address from, address to, uint256 tokenId) external;

    function transferFrom(address from, address to, uint256 tokenId) external;

    function approve(address to, uint256 tokenId) external;

    function getApproved(uint256 tokenId) external view returns (address operator);

    function setApprovalForAll(address operator, bool _approved) external;

    function isApprovedForAll(address owner, address operator) external view returns (bool);

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}
// File: contracts/tokens/IERC721Metadata.sol



pragma solidity ^0.8.10;


interface IERC721Metadata is IERC721 {

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);
}
// File: contracts/tokens/IERC721Enumerable.sol



pragma solidity ^0.8.10;


interface IERC721Enumerable is IERC721 {

    function totalSupply() external view returns (uint256);

    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    function tokenByIndex(uint256 index) external view returns (uint256);
}
// File: contracts/tokens/IERC721Schema.sol



pragma solidity ^0.8.10;



interface IERC721Schema is IERC721Enumerable, IERC721Metadata {
    
    function schemaOf(uint256 tokenId) external view returns (uint256 schemaId);

    function minterOf(uint256 schemaId) external view returns (address owner);
    
    function holdsTokenOfSchema(address holder, uint256 schemaId) external view returns (bool hasRight);
    
    function totalSchemas() external view returns (uint256 total);
    
    function totalMintedFor(uint256 schemaId) external view returns (uint256 total);

    function tokenOfSchemaByIndex(uint256 schema, uint256 index) external view returns (uint256 tokenId);
}
// File: contracts/SignataIdentity.sol



pragma solidity ^0.8.11;

contract SignataIdentity {
    uint256 public constant MAX_UINT256 = type(uint256).max;
    
    // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)")
    bytes32 public constant EIP712DOMAINTYPE_DIGEST = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;
    
    // keccak256("Signata")
    bytes32 public constant NAME_DIGEST = 0xfc8e166e81add347414f67a8064c94523802ae76625708af4cddc107b656844f;
    
    // keccak256("1")
    bytes32 public constant VERSION_DIGEST = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
    
    bytes32 public constant SALT = 0x233cdb81615d25013bb0519fbe69c16ddc77f9fa6a9395bd2aecfdfc1c0896e3;
    
    // keccak256("create(uint8 identityV, bytes32 identityR, bytes32 identityS, address delegateAddress, address securityKey)")
    bytes32 public constant TXTYPE_CREATE_DIGEST = 0x087280f638c5afab2bc9df90375624dfabc18c6dcec33665afdc2db6ad4048b1;
    
    // keccak256("destroy(address identity, uint8 delegateV, bytes32 delegateR, bytes32 delegateS, uint8 securityV, bytes32 securityR, bytes32 securityS)");
    bytes32 public constant TXTYPE_DESTROY_DIGEST = 0x9b364f015edab2a56fcadebbd609a6626a0612d05dd5d0b2203e1b1317d70ef7;
    
    // keccak256("lock(address identity, uint8 sigV, bytes32 sigR, bytes32 sigS)")
    bytes32 public constant TXTYPE_LOCK_DIGEST = 0x703ed461c8d1c12e6e8b4708e8034e12d743b6221f0dbc5d301224713022c204;

    // keccak256("unlock(address identity, uint8 securityV, bytes32 securityR, bytes32 securityS)")
    bytes32 public constant TXTYPE_UNLOCK_DIGEST = 0x8364584c57b345e5810179c75cd470a8b1bd71cc8ee2c05074a1ffe55b48b865;

    // keccak256("rollover(address identity, uint8 delegateV, bytes32 delegateR, bytes32 delegateS, uint8 securityV, bytes32 securityR, bytes32 securityS, address newDelegateAddress, address newSecurityAddress)")
    bytes32 public constant TXTYPE_ROLLOVER_DIGEST = 0x7c62ea77dc835faa5b9bff6fd0f00c7b793acdd94960f48e7c9f47e28462085f;
    
    bytes32 public immutable _domainSeparator;
    
    // storage
    mapping(address => address) public _delegateKeyToIdentity;
    mapping(address => uint256) public _identityLockCount;
    mapping(address => uint256) public _identityRolloverCount;
    mapping(address => address) public _identityToSecurityKey;
    mapping(address => address) public _identityToDelegateKey;
    mapping(address => bool) public _identityDestroyed;
    mapping(address => bool) public _identityExists;
    mapping(address => bool) public _identityLocked;
    
    constructor(uint256 chainId) {
        _domainSeparator = keccak256(
            abi.encode(
                EIP712DOMAINTYPE_DIGEST,
                NAME_DIGEST,
                VERSION_DIGEST,
                chainId,
                this,
                SALT
            )
        );
    }
    
    event Create(address indexed identity, address indexed delegateKey, address indexed securityKey);
    event Destroy(address indexed identity);
    event Lock(address indexed identity);
    event Rollover(address indexed identity, address indexed delegateKey, address indexed securityKey);
    event Unlock(address indexed identity);
    
    function create(
        uint8 identityV, 
        bytes32 identityR, 
        bytes32 identityS,
        address identityAddress,
        address delegateAddress, 
        address securityAddress
    )
        external
    {
        require(
            _delegateKeyToIdentity[delegateAddress] == address(0),
            "SignataIdentity: Delegate key must not already be in use."
        );
        
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(
                    abi.encode(
                        TXTYPE_CREATE_DIGEST,
                        delegateAddress,
                        securityAddress
                    )
                )
            )
        );
        
        address identity = ecrecover(digest, identityV, identityR, identityS);

        require(identity == identityAddress, "SignataIdentity: Invalid signature for identity");
        
        require(
            identity != delegateAddress && identity != securityAddress && delegateAddress != securityAddress,
            "SignataIdentity: Keys must be unique."
        );
        
        require(
            !_identityExists[identity],
            "SignataIdentity: The identity must not already exist."
        );
        
        _delegateKeyToIdentity[delegateAddress] = identity;
        _identityToDelegateKey[identity] = delegateAddress;
        _identityExists[identity] = true;
        _identityToSecurityKey[identity] = securityAddress;
        
        emit Create(identity, delegateAddress, securityAddress);
    }

    function destroy(
        address identity,
        uint8 delegateV,
        bytes32 delegateR, 
        bytes32 delegateS,
        uint8 securityV,
        bytes32 securityR, 
        bytes32 securityS
    )
        external
    {
        require(
            _identityExists[identity],
            "SignataIdentity: The identity must exist."
        );
        
        require(
            !_identityDestroyed[identity],
            "SignataIdentity: The identity has already been destroyed."
        );
        
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(
                    abi.encode(
                        TXTYPE_DESTROY_DIGEST
                    )
                )
            )
        );
        
        address delegateAddress = ecrecover(digest, delegateV, delegateR, delegateS);
        
        require(
            _identityToDelegateKey[identity] == delegateAddress,
            "SignataIdentity: Invalid delegate key signature provided."
        );
        
        address securityAddress = ecrecover(digest, securityV, securityR, securityS);
        
        require(
            _identityToSecurityKey[identity] == securityAddress,
            "SignataIdentity: Invalid security key signature provided."
        );
        
        _identityDestroyed[identity] = true;
        
        delete _delegateKeyToIdentity[delegateAddress];
        delete _identityLockCount[identity];
        delete _identityRolloverCount[identity];
        delete _identityToSecurityKey[identity];
        delete _identityToDelegateKey[identity];
        delete _identityLocked[identity];
        
        emit Destroy(identity);
    }

    function lock(
        address identity,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS
    )
        external
    {
        require(
            _identityExists[identity],
            "SignataIdentity: The identity must exist."
        );
        
        require(
            !_identityDestroyed[identity],
            "SignataIdentity: The identity has been destroyed."
        );
        
        require(
            !_identityLocked[identity],
            "SignataIdentity: The identity has already been locked."
        );
                
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(
                    abi.encode(
                        TXTYPE_LOCK_DIGEST,
                        _identityLockCount[identity]
                    )
                )
            )
        );
        
        address recoveredAddress = ecrecover(digest, sigV, sigR, sigS);
        
        require(
            _identityToDelegateKey[identity] == recoveredAddress || _identityToSecurityKey[identity] == recoveredAddress,
            "SignataIdentity: Invalid key signature provided."
        );

        _identityLocked[identity] = true;
        _identityLockCount[identity] += 1;
        
        emit Lock(identity);
    }

    function unlock(
        address identity,
        uint8 securityV,
        bytes32 securityR,
        bytes32 securityS
    ) 
        external 
    {
        require(
            _identityExists[identity],
            "SignataIdentity: The identity must exist."
        );
        
        require(
            !_identityDestroyed[identity],
            "SignataIdentity: The identity has been destroyed."
        );
        
        require(
            _identityLocked[identity],
            "SignataIdentity: The identity is already unlocked."
        );
        
        require(
            _identityLockCount[identity] != MAX_UINT256,
            "SignataIdentity: The identity is permanently locked."
        );
        
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(
                    abi.encode(
                        TXTYPE_UNLOCK_DIGEST,
                        _identityLockCount[identity]
                    )
                )
            )
        );
        
        address securityAddress = ecrecover(digest, securityV, securityR, securityS);
        
        require(
            _identityToSecurityKey[identity] == securityAddress,
            "SignataIdentity: Invalid security key signature provided."
        );
        
        _identityLocked[identity] = false;
        
        emit Unlock(identity);
    }
    
    function rollover(
        address identity,
        uint8 delegateV,
        bytes32 delegateR,
        bytes32 delegateS,
        uint8 securityV,
        bytes32 securityR,
        bytes32 securityS,
        address newDelegateAddress,
        address newSecurityAddress
    ) 
        external 
    {
        require(
            _identityExists[identity],
            "SignataIdentity: The identity must exist."
        );
        
        require(
            !_identityDestroyed[identity],
            "SignataIdentity: The identity has been destroyed."
        );
        
        require(
            identity != newDelegateAddress && identity != newSecurityAddress && newDelegateAddress != newSecurityAddress,
            "SignataIdentity: The keys must be unique."
        );
        
        require(
            _delegateKeyToIdentity[newDelegateAddress] == address(0),
            "SignataIdentity: The new delegate key must not already be in use."
        );
        
        require(
            _identityRolloverCount[identity] != MAX_UINT256,
            "SignataIdentity: The identity has already reached the maximum number of rollovers allowed."
        );

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                _domainSeparator,
                keccak256(
                    abi.encode(
                        TXTYPE_ROLLOVER_DIGEST,
                        newDelegateAddress,
                        newSecurityAddress,
                        _identityRolloverCount[identity]
                    )
                )
            )
        );
        
        address delegateAddress = ecrecover(digest, delegateV, delegateR, delegateS);
        
        require(
            _identityToDelegateKey[identity] == delegateAddress,
            "SignataIdentity: Invalid delegate key signature provided."
        );
        
        address securityAddress = ecrecover(digest, securityV, securityR, securityS);
        
        require(
            _identityToSecurityKey[identity] == securityAddress,
            "SignataIdentity: Invalid delegate key signature provided."
        );
        
        delete _delegateKeyToIdentity[delegateAddress];
        
        _delegateKeyToIdentity[newDelegateAddress] = identity;
        _identityToDelegateKey[identity] = newDelegateAddress;
        _identityToSecurityKey[identity] = newSecurityAddress;
        _identityRolloverCount[identity] += 1;
        
        emit Rollover(identity, newDelegateAddress, newSecurityAddress);
    }
    
    function getDelegate(address identity)
        external
        view
        returns (address)
    {
        require(
            _identityExists[identity],
            "SignataIdentity: The identity must exist."
        );
        
        require(
            !_identityDestroyed[identity],
            "SignataIdentity: The identity has been destroyed."
        );
        
        return _identityToDelegateKey[identity];
    }
    
    function getIdentity(address delegateKey) 
        external
        view 
        returns (address) 
    {
        address identity = _delegateKeyToIdentity[delegateKey];
        
        require(
            identity != address(0),
            "SignataIdentity: The delegate key provided is not linked to an existing identity."
        );
        
        return identity;
    }

    function getLockCount(address identity)
        external
        view
        returns (uint256) 
    {
         require(
            _identityExists[identity],
            "SignataIdentity: The identity must exist."
        );
        
        require(
            !_identityDestroyed[identity],
            "SignataIdentity: The identity has been destroyed."
        );
        
        return _identityLockCount[identity];
    }    
    
    function getRolloverCount(address identity)
        external
        view
        returns (uint256) 
    {
        require(
            _identityExists[identity],
            "SignataIdentity: The identity must exist."
        );
        
        require(
            !_identityDestroyed[identity],
            "SignataIdentity: The identity has been destroyed."
        );
        
        return _identityRolloverCount[identity];
    }
    
    function isLocked(address identity)
        external
        view
        returns (bool) 
    {
        require(
            _identityExists[identity],
            "SignataIdentity: The identity must exist."
        );
        
        require(
            !_identityDestroyed[identity],
            "SignataIdentity: The identity has been destroyed."
        );
        
        return _identityLocked[identity];
    }
}
// File: contracts/SignataRight.sol


pragma solidity ^0.8.11;









contract SignataRight is IERC721Schema {
    using Address for address;
    
    event MintSchema(uint256 indexed schemaId, uint256 indexed mintingRightId, bytes32 indexed uriHash);
    
    event MintRight(uint256 indexed schemaId, uint256 indexed rightId, bool indexed unbound);
    
    event Revoke(uint256 indexed rightId);
    
    uint256 private constant MAX_UINT256 = type(uint256).max;
    
    bytes4 private constant INTERFACE_ID_ERC165 = type(IERC165).interfaceId;
    bytes4 private constant INTERFACE_ID_ERC721 = type(IERC721).interfaceId;
    bytes4 private constant INTERFACE_ID_ERC721_ENUMERABLE = type(IERC721Enumerable).interfaceId;
    bytes4 private constant INTERFACE_ID_ERC721_METADATA = type(IERC721Metadata).interfaceId;
    bytes4 private constant INTERFACE_ID_ERC721_SCHEMA = type(IERC721Schema).interfaceId;

    string private _name;
    string private _symbol;
    SignataIdentity private _signataIdentity;
    
    // Schema Storage
    mapping(uint256 => uint256) private _schemaToRightBalance;
    mapping(uint256 => mapping(uint256 => uint256)) private _schemaToRights;
    mapping(uint256 => bool) _schemaRevocable;
    mapping(uint256 => bool) _schemaTransferable;
    mapping(uint256 => string) private _schemaToURI;
    mapping(bytes32 => uint256) private _uriHashToSchema;
    mapping(uint256 => uint256) private _schemaToMintingRight;
    mapping(address => mapping(uint256 => uint256)) _ownerToSchemaBalance;
    uint256 private _schemasTotal;
    
    // Rights Storage
    mapping(uint256 => address) private _rightToOwner;
    mapping(address => uint256) private _ownerToRightBalance;
    mapping(uint256 => address) private _rightToApprovedAddress;
    mapping(uint256 => bool) private _rightToRevocationStatus;
    mapping(uint256 => uint256) private _rightToSchema;
    mapping(address => mapping (address => bool)) private _ownerToOperatorStatuses;
    mapping(address => mapping(uint256 => uint256)) private _ownerToRights;
    mapping(uint256 => uint256) _rightToOwnerRightsIndex;
    uint256 private _rightsTotal;
    
    constructor(
        string memory name_, 
        string memory symbol_,
        address signataIdentity_,
        string memory mintingSchemaURI_
    ) {
        address thisContract = address(this);
        bytes32 uriHash = keccak256(bytes(mintingSchemaURI_));

        _name = name_;
        _symbol = symbol_;

        _signataIdentity = SignataIdentity(signataIdentity_);

        _schemaToRightBalance[1] = 1;
        _schemaToRights[1][0] = 1;
        _schemaRevocable[1] = false;
        _schemaTransferable[1] = true;
        _schemaToURI[1] = mintingSchemaURI_;
        _uriHashToSchema[uriHash] = 1;
        _schemaToMintingRight[1] = 1;
        _ownerToSchemaBalance[thisContract][1] = 1;
        _schemasTotal = 1;

        _rightToOwner[1] = thisContract;
        _ownerToRightBalance[thisContract] = 1;
        _rightToSchema[1] = 1;
        _ownerToRights[thisContract][0] = 1;
        _rightToOwnerRightsIndex[1] = 0;
        _rightsTotal = 1;
        
        emit MintSchema(1, 1, uriHash);
        
        emit MintRight(1, 1, false);
        
        emit Transfer(address(0), thisContract, 1);
    }

    function supportsInterface(bytes4 interfaceId) public pure override returns (bool) {
        return interfaceId == INTERFACE_ID_ERC165
            || interfaceId == INTERFACE_ID_ERC721
            || interfaceId == INTERFACE_ID_ERC721_ENUMERABLE
            || interfaceId == INTERFACE_ID_ERC721_METADATA
            || interfaceId == INTERFACE_ID_ERC721_SCHEMA;
    }
    
    function mintSchema(
        address minter,
        bool schemaTransferable, 
        bool schemaRevocable, 
        string calldata schemaURI
    ) external returns (uint256) {
        require(
            _schemasTotal != MAX_UINT256,
            "SignataRight: Maximum amount of schemas already minted."
        );
        
        require(
            _rightsTotal != MAX_UINT256,
            "SignataRight: Maximum amount of rights already minted."
        );
        
        bytes32 uriHash = keccak256(bytes(schemaURI));
        
        require(
            _uriHashToSchema[uriHash] == 0,
            "SignataRight: The URI provided for the schema is not unique."
        );
        
        address recipient;
        
        if (minter.isContract()) {
            recipient = minter;
        } else {
            recipient = _signataIdentity.getIdentity(minter);
            
            require(
                !_signataIdentity.isLocked(recipient),
                "SignataRight: The sender's account is locked."
            );
        }
        
        _rightsTotal += 1;
        _rightToOwner[_rightsTotal] = recipient;
        _rightToSchema[_rightsTotal] = 1;
        
        uint256 schemaToRightsLength = _schemaToRightBalance[1];

        _schemaToRights[1][schemaToRightsLength] = _rightsTotal;
        _schemaToRightBalance[1] += 1;
        _ownerToSchemaBalance[recipient][1] += 1;

        uint256 ownerToRightsLength = _ownerToRightBalance[recipient];
        
        _ownerToRights[recipient][ownerToRightsLength] = _rightsTotal;
        _rightToOwnerRightsIndex[_rightsTotal] = ownerToRightsLength;
        _ownerToRightBalance[recipient] += 1;
        
        _schemasTotal += 1;
        _schemaToMintingRight[_schemasTotal] = _rightsTotal;
        _schemaToURI[_schemasTotal] = schemaURI;
        _uriHashToSchema[uriHash] = _schemasTotal;
        _schemaTransferable[_schemasTotal] = schemaTransferable;
        _schemaRevocable[_schemasTotal] = schemaRevocable;
        
        require(
            _isSafeToTransfer(address(0), recipient, _rightsTotal, ""),
            "SignataRight: must only transfer to ERC721Receiver implementers when recipient is a smart contract."
        );
        
        emit MintRight(1, _rightsTotal, false);
        
        emit Transfer(address(0), minter, _rightsTotal);
        
        emit MintSchema(_schemasTotal, _rightsTotal, uriHash);
        
        return _schemasTotal;
    }
    
    function mintRight(uint256 schemaId, address to, bool unbound) external {
        require(
            _rightsTotal != MAX_UINT256,
            "SignataRight: Maximum amount of tokens already minted."
        );
        
        require(
            _schemaToMintingRight[schemaId] != 0,
            "SignataRight: Schema ID must correspond to an existing schema."
        );

        address minter;
        
        if (msg.sender.isContract()) {
            minter = msg.sender;
        } else {
            minter = _signataIdentity.getIdentity(msg.sender);
            
            require(
                !_signataIdentity.isLocked(minter),
                "SignataRight: The sender's account is locked."
            );
        }
        
        require(
            minter == _rightToOwner[_schemaToMintingRight[schemaId]],
            "SignataRight: The sender is not the minter for the schema specified."
        );
        
        address recipient;
        
        if (to.isContract()) {
            recipient = to;
        } else if (unbound == true) {
            recipient = to;
        } else {
            recipient = _signataIdentity.getIdentity(to);
            
            require(
                !_signataIdentity.isLocked(minter),
                "SignataRight: The sender's account is locked."
            );
        }
        
        _rightsTotal += 1;
        _rightToOwner[_rightsTotal] = recipient;
        _rightToSchema[_rightsTotal] = schemaId;
        
        uint256 schemaToRightsLength = _schemaToRightBalance[schemaId];

        _schemaToRights[schemaId][schemaToRightsLength] = _rightsTotal;
        _schemaToRightBalance[schemaId] += 1;
        _ownerToSchemaBalance[recipient][schemaId] += 1;

        uint256 ownerToRightsLength = _ownerToRightBalance[recipient];
        
        _ownerToRights[recipient][ownerToRightsLength] = _rightsTotal;
        _rightToOwnerRightsIndex[_rightsTotal] = ownerToRightsLength;
        _ownerToRightBalance[recipient] += 1;
        
        require(
            _isSafeToTransfer(address(0), recipient, _rightsTotal, ""),
            "SignataRight: must only transfer to ERC721Receiver implementers when recipient is a smart contract."
        );
        
        emit MintRight(schemaId, _rightsTotal, unbound);
        
        emit Transfer(address(0), to, _rightsTotal);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        if (owner.isContract()) {
            return _ownerToRightBalance[owner];
        }
        
        return _ownerToRightBalance[_signataIdentity.getIdentity(owner)];
    }

    function ownerOf(uint256 tokenId) public view override returns (address) {
        address owner = _rightToOwner[tokenId];
        
        require(
            owner != address(0),
            "SignataRight: Token ID must correspond to an existing right."
        );
        
        if (owner.isContract()) {
            return owner;
        }
        
        return _signataIdentity.getDelegate(owner);
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 tokenId) external view override returns (string memory) {
        require(
            _rightToOwner[tokenId] != address(0), 
            "SignataRight: Token ID must correspond to an existing right."
        );

        return _schemaToURI[_rightToSchema[tokenId]];
    }

    function approve(address to, uint256 tokenId) external override {
        address owner = _rightToOwner[tokenId];
        
        require(
            owner != address(0),
            "SignataRight: Token ID must correspond to an existing right."
        );
        
        require(
            to != owner, 
            "SignataRight: Approval is not required for the owner of the right."
        );
        
        address controller;
        
        if (owner.isContract()) {
            controller = owner;
        } else {
            controller = _signataIdentity.getDelegate(owner);
            
            require(
                to != controller, 
                "SignataRight: Approval is not required for the owner of the right."
            );
            
            require(
                !_signataIdentity.isLocked(owner),
                "SignataRight: The owner's account is locked."
            );
        }
            
        require(
            msg.sender == controller || isApprovedForAll(owner, msg.sender),
            "SignataRight: The sender is not authorised to provide approvals."
        );
        
        _rightToApprovedAddress[tokenId] = to;
    
        emit Approval(controller, to, tokenId);
    }
    
    function revoke(uint256 tokenId) external {
        require(
            _rightToOwner[tokenId] != address(0),
            "SignataRight: Right ID must correspond to an existing right."
        );
        
        uint256 schemaId = _rightToSchema[tokenId];
        
        require(
            _schemaRevocable[schemaId],
            "SignataRight: The right specified is not revocable."
        );
        
        address minter = _rightToOwner[_schemaToMintingRight[schemaId]];
        
        address controller;
        
        if (minter.isContract()) {
            controller = minter;
        } else {
            controller = _signataIdentity.getDelegate(minter);
            
            require(
                !_signataIdentity.isLocked(minter),
                "SignataRight: The minter's account is locked."
            );
        }
            
        require(
            msg.sender == controller,
            "SignataRight: The sender is not authorised to revoke the right."
        );
        
        _rightToRevocationStatus[tokenId] = true;

        _ownerToSchemaBalance[_rightToOwner[tokenId]][schemaId] -= 1;
    
        emit Revoke(tokenId);        
    }
    
    function isRevoked(uint256 tokenId) external view returns (bool) {
        require(
            _rightToOwner[tokenId] != address(0),
            "SignataRight: Token ID must correspond to an existing right."
        );
        
        return _rightToRevocationStatus[tokenId];
    }

    function getApproved(uint256 tokenId) public view override returns (address) {
        require(
            _rightToOwner[tokenId] != address(0),
            "SignataRight: Token ID must correspond to an existing right."
        );

        return _rightToApprovedAddress[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public override {
        address owner;
        
        require(
            operator != msg.sender, 
            "SignataRight: Self-approval is not required."
        );
        
        if (msg.sender.isContract()) {
            owner = msg.sender;
        } else {
            owner = _signataIdentity.getIdentity(msg.sender);
            
            require(
                operator != owner, 
                "SignataRight: Self-approval is not required."
            );
            
            require(
                !_signataIdentity.isLocked(owner),
                "SignataRight: The owner's account is locked."
            );
        }

        _ownerToOperatorStatuses[owner][operator] = approved;
        
        emit ApprovalForAll(owner, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view override returns (bool) {
        address owner_ = (owner.isContract())
            ? owner
            :_signataIdentity.getIdentity(msg.sender);
            
        return _ownerToOperatorStatuses[owner_][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public override {
        require(
            _rightToOwner[tokenId] != address(0),
            "SignataRight: Token ID must correspond to an existing right."
        );
        
        uint256 schemaId = _rightToSchema[tokenId];
        
        require(
            _schemaTransferable[schemaId],
            "SignataRight: This right is non-transferable."
        );
        
        require(
            !_rightToRevocationStatus[tokenId],
            "SignataRight: This right has been revoked."
        );
        
        require(
            to != address(0), 
            "SignataRight: Transfers to the zero address are not allowed."
        );
        
        address owner;
        
        if (from.isContract()) {
            owner = from;
        } else {
            owner = _signataIdentity.getIdentity(from);
            
            require(
                !_signataIdentity.isLocked(owner),
                "SignataRight: The owner's account is locked."
            );
        }
        
        require(
            _rightToOwner[tokenId] == owner,
            "SignataRight: The account specified does not hold the right corresponding to the Token ID provided."
        );
        

        require(
            msg.sender == owner || msg.sender == _rightToApprovedAddress[tokenId] || _ownerToOperatorStatuses[owner][msg.sender],
            "SignataRight: The sender is not authorised to transfer this right."
        );
        
        address recipient;

        if (to.isContract()) {
            recipient = to;
        } else {
            recipient = _signataIdentity.getIdentity(to);
            
            require(
                !_signataIdentity.isLocked(recipient),
                "SignataRight: The recipient's account is locked."
            );
        }
        
        uint256 lastRightIndex = _ownerToRightBalance[owner] - 1;
        uint256 rightIndex = _rightToOwnerRightsIndex[tokenId];

        if (rightIndex != lastRightIndex) {
            uint256 lastTokenId = _ownerToRights[owner][lastRightIndex];

            _ownerToRights[owner][rightIndex] = lastTokenId;
            _rightToOwnerRightsIndex[lastTokenId] = rightIndex;
        }

        delete _ownerToRights[owner][lastRightIndex];
        delete _rightToOwnerRightsIndex[tokenId];
        
        _ownerToSchemaBalance[owner][schemaId] -= 1;
        
        uint256 length = _ownerToRightBalance[recipient];
        
        _ownerToRights[recipient][length] = tokenId;
        _rightToOwnerRightsIndex[tokenId] = length;
        
        _rightToApprovedAddress[tokenId] = address(0);
        
        emit Approval(from, address(0), tokenId);

        _ownerToRightBalance[owner] -= 1;
        _ownerToRightBalance[recipient] += 1;
        _rightToOwner[tokenId] = recipient;
        
        _ownerToSchemaBalance[recipient][schemaId] += 1;

        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) external override {
        safeTransferFrom(from, to, tokenId, "");
    }

    function safeTransferFrom(address from, address to, uint256 tokenId, bytes memory _data) public override {
        transferFrom(from, to, tokenId);
        
        require(
            _isSafeToTransfer(from, to, tokenId, _data),
            "SignataRight: must only transfer to ERC721Receiver implementers when recipient is a smart contract."
        );
    }
    
    function tokenOfOwnerByIndex(address owner, uint256 index) public view override returns (uint256) {
        address holder;
        
        if (owner.isContract()) {
            holder = owner;
        } else {
            holder = _signataIdentity.getIdentity(owner);
        }
        
        require(
            index < _ownerToRightBalance[holder], 
            "SignataRight: The index provided is out of bounds for the owner specified."
        );
        
        return _ownerToRights[holder][index];
    }

    function totalSupply() public view override returns (uint256) {
        return _rightsTotal;
    }

    function tokenByIndex(uint256 index) public view override returns (uint256) {
        require(
            index < _rightsTotal, 
            "SignataRight: The index provided is out of bounds."
        );
        
        return index + 1;
    }
    
    function schemaOf(uint256 tokenId) external view override returns (uint256) {
        require(
            _rightToOwner[tokenId] != address(0),
            "SignataRight: Token ID must correspond to an existing right."
        );

        return _rightToSchema[tokenId];    
    }

    function minterOf(uint256 schemaId) external view override returns (address) {
        uint256 mintingToken = _schemaToMintingRight[schemaId];
        
        require(
            mintingToken != 0,
            "SignataRight: Schema ID must correspond to an existing schema."
        );
        
        address owner = _rightToOwner[mintingToken];

        if (owner.isContract()) {
            return owner;
        }
        
        return _signataIdentity.getDelegate(owner);        
    }
    
    function holdsTokenOfSchema(address holder, uint256 schemaId) external view override returns (bool) {
        require(
            _schemaToMintingRight[schemaId] != 0,
            "SignataRight: Schema ID must correspond to an existing schema."
        );
        
        address owner;

        if (owner.isContract()) {
            owner = holder;
        } else {
            owner = _signataIdentity.getIdentity(holder);
        }
        
        return _ownerToSchemaBalance[owner][schemaId] > 0;
    }
    
    function totalSchemas() external view override returns (uint256) {
        return _schemasTotal;
    }
    
    function totalMintedFor(uint256 schemaId) external view override returns (uint256) {
        require(
            _schemaToMintingRight[schemaId] != 0,
            "SignataRight: Schema ID must correspond to an existing schema."
        );
        
        return _schemaToRightBalance[schemaId];
    }

    function tokenOfSchemaByIndex(uint256 schemaId, uint256 index) external view override returns (uint256) {
        require(
            _schemaToMintingRight[schemaId] != 0,
            "SignataRight: Schema ID must correspond to an existing schema."
        );
        
        require(
            index < _schemaToRightBalance[schemaId], 
            "SignataRight: The index provided is out of bounds for the owner specified."
        );
        
        return _schemaToRights[schemaId][index];       
    }
        
    function _isSafeToTransfer(address from, address to, uint256 tokenId, bytes memory _data) private returns (bool)
    {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msg.sender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("SignataRight: must only transfer to ERC721Receiver implementers when recipient is a smart contract.");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }
}
// File: contracts/ClaimRight.sol


pragma solidity ^0.8.16;







contract ClaimRight is Ownable, IERC721Receiver {
    string public name;
    IERC20 private signataToken;
    SignataRight private signataRight;
    SignataIdentity private signataIdentity;
    address private signingAuthority;
    uint256 public feeAmount = 10 * 1e18; // 10 SATA to start with
    uint256 public schemaId;
    bytes32 public constant VERSION_DIGEST = 0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6;
    bytes32 public constant SALT = 0x03ea6995167b253ad0cf79271b4ddbacfb51c7a4fb2872207de8a19eb0cb724b;
    bytes32 public constant NAME_DIGEST = 0xfc8e166e81add347414f67a8064c94523802ae76625708af4cddc107b656844f;
    bytes32 public constant EIP712DOMAINTYPE_DIGEST = 0xd87cd6ef79d4e2b95e15ce8abf732db51ec771f1ca2edccf22a46c729ac56472;
    bytes32 public constant TXTYPE_CLAIM_DIGEST = 0x8891c73a2637b13c5e7164598239f81256ea5e7b7dcdefd496a0acd25744091c;
    bytes32 public immutable domainSeparator;
    bytes4 private constant _ERC721_RECEIVED = 0x150b7a02;

    mapping(address => bool) public claimedRight;
    mapping(address => bool) public cancelledClaim;
    mapping(address => uint) public expiresAt;
    mapping(address => bytes32) public claimSalt;

    event RightAssigned();
    event EmergencyRightClaimed();
    event ModifiedFee(uint256 oldAmount, uint256 newAmount);
    event FeesTaken(uint256 feesAmount);
    event ClaimCancelled(address identity);
    event RightClaimed(address identity);
    event ClaimReset(address identity);

    constructor(
        address _signataToken,
        address _signataRight,
        address _signataIdentity,
        address _signingAuthority,
        string memory _name
    ) {
        signataToken = IERC20(_signataToken);
        signataRight = SignataRight(_signataRight);
        signataIdentity = SignataIdentity(_signataIdentity);
        signingAuthority = _signingAuthority;
        name = _name;

         domainSeparator = keccak256(
            abi.encode(
                EIP712DOMAINTYPE_DIGEST,
                NAME_DIGEST,
                VERSION_DIGEST,
                SALT
            )
        );
    }

    receive() external payable {}

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    )
        external
        pure
        returns (bytes4)
    {
        return _ERC721_RECEIVED;
    }

    function mintSchema(
        string memory _schemaURI
    ) external onlyOwner {
        schemaId = signataRight.mintSchema(address(this), true, true, _schemaURI);
    }

    function claimRight(
        address identity,
        address delegate,
        uint8 sigV,
        bytes32 sigR,
        bytes32 sigS,
        bytes32 salt
    )
        external
    {
        // take the fee
        if (feeAmount > 0) {
            signataToken.transferFrom(msg.sender, address(this), feeAmount);
            emit FeesTaken(feeAmount);
        }

        // check if the right is already claimed
        require(!claimedRight[identity], "ClaimRight: Right already claimed");
        require(!cancelledClaim[identity], "ClaimRight: Claim cancelled");
        require(claimSalt[identity] != salt, "ClaimRight: Salt already used");

        require(expiresAt[identity] == 0 || block.timestamp > expiresAt[identity], "ClaimRight: Claim expired");

        expiresAt[identity] = 1 weeks;
        claimSalt[identity] = salt;

        // validate the signature
        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode(
                        TXTYPE_CLAIM_DIGEST,
                        identity,
                        salt
                    )
                )
            )
        );

        address signerAddress = ecrecover(digest, sigV, sigR, sigS);
        require(signerAddress == signingAuthority, "ClaimRight: Invalid signature");

        // assign the right to the identity
        signataRight.mintRight(schemaId, delegate, false);

        emit RightClaimed(identity);
    }

    function cancelClaim(
        address identity
    )
        external onlyOwner
    {
        require(!claimedRight[identity], "CancelClaim: Right already claimed");
        require(!cancelledClaim[identity], "CancelClaim: Claim already cancelled");

        cancelledClaim[identity] = true;

        emit ClaimCancelled(identity);
    }

    function resetClaim(
        address identity
    )
        external onlyOwner
    {
        claimedRight[identity] = false;
        cancelledClaim[identity] = false;

        emit ClaimReset(identity);
    }
    
    function updateSigningAuthority(
        address _signingAuthority
    )
        external onlyOwner
    {
        signingAuthority = _signingAuthority;
    }

    function modifyFee(
        uint256 newAmount
    )
        external
        onlyOwner
    {
        uint256 oldAmount = feeAmount;
        feeAmount = newAmount;
        emit ModifiedFee(oldAmount, newAmount);
    }

    function withdrawCollectedFees()
        external
        onlyOwner
    {
        signataToken.transferFrom(address(this), msg.sender, signataToken.balanceOf(address(this)));
    }

    function withdrawNative()
        external
        onlyOwner
        returns (bool)
    {
        (bool success,) = payable(msg.sender).call{value: address(this).balance}("");
        return success;
    }
}