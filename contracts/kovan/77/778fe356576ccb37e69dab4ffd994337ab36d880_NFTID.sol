/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

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

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// File: contracts/minty.sol


pragma solidity ^0.8.3;




contract NFTID is IERC20, Ownable {
    uint256 private constant MAX_UINT256 = 2**256 - 1;
    address private constant RANDOM =
    0x777788889999AaAAbBbbCcccddDdeeeEfFFfCcCc;
    address private constant TOKEN_OWNER =
    0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db;
    struct Metadata {
        uint256 documentHash;
        uint256 issueTime;
        uint256 expiryTime;
        uint256 documentClass;
        uint8 status;
    }

    string public name;
    string public symbol;

    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    // tokenId => address of owner
    mapping(uint256 => address) private _owners;
    // owner => tokenId[]
    mapping(address => uint256[]) private userTokens;
    // tokenId => Metadata
    mapping(uint256 => Metadata) public metadata;
    // documentHash => tokenId
    mapping(uint256 => uint256) public documentHashes;
    // tokenId => approved address
    mapping(uint256 => address) private _tokenApprovals;
    address public admin;
    constructor() {
        name = "nftid";
        symbol = "FTN";
        admin = tx.origin;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return MAX_UINT256;
    }

    function createToken(address owner) public onlyOwner returns (uint256) {
        require(owner != address(0), "NTFID: mint to the zero address");
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();

        userTokens[owner].push(newItemId);
        _owners[newItemId] = owner;

        return newItemId;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address owner)
    public
    view
    virtual
    override
    returns (uint256)
    {
        require(
            owner != address(0),
            "NFTID: balance query for the zero address"
        );
        return userTokens[owner].length;
    }

    function ownerOf(uint256 tokenId) public view virtual returns (address) {
        address owner = _owners[tokenId];
        require(
            owner != address(0),
            "NFTID: owner query for nonexistent token"
        );
        return owner;
    }
    function transferOwnership(address newOwner) override public virtual {
        require(tx.origin == admin, "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }
    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount)
    public
    virtual
    override
    returns (bool)
    {
        require(false, "Forbidden");
        to = address(0);
        amount = 0;
        return false;
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
    ) public virtual override onlyOwner returns (bool) {
        require(false, "Forbidden");
        to = from;
        amount = 0;
        return false;
    }

    function _transfer(address to, uint256 tokenId) internal virtual onlyOwner {
        require(to != address(0), "NFTID: transfer to the zero address");

        // _beforeTokenTransfer(from, to, tokenId);

        address from = ownerOf(tokenId);
        _approve(address(0), tokenId);
        uint256[] storage tokens = userTokens[from];
        for (uint256 index = 0; index < tokens.length; index++) {
            if (tokens[index] == tokenId) {
                tokens[index] = tokens[tokens.length - 1];
                tokens.pop();
                break;
            }
        }
        userTokens[to].push(tokenId);
        _owners[tokenId] = to;
        // emit Transfer(from, to, tokenId);
        // _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender)
    public
    view
    virtual
    override
    onlyOwner
    returns (uint256)
    {
        require(false, "Forbidden");
        owner = spender;
        return 0;
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
    function approve(address spender, uint256 amount)
    public
    virtual
    override
    onlyOwner
    returns (bool)
    {
        require(false, "Forbidden");
        spender = address(0);
        amount = 0;
        return false;
    }

    function _approve(address to, uint256 tokenId) internal virtual onlyOwner {
        _tokenApprovals[tokenId] = to;
    }

    function getMyTokens() public view returns (uint256[] memory) {
        return UserTokens(msg.sender);
    }

    function UserTokens(address owner) public view returns (uint256[] memory) {
        return userTokens[owner];
    }

    function mintMetadata(
        uint256 tokenId_,
        uint256 documentHash_,
        uint256 issueTime_,
        uint256 expiryTime_,
        uint256 documentClass_,
        uint8 status_
    ) public onlyOwner {
        metadata[tokenId_] = Metadata(
            documentHash_,
            issueTime_,
            expiryTime_,
            documentClass_,
            status_
        );
        documentHashes[documentHash_] = tokenId_;
    }

    function mint2() public onlyOwner {
        uint256 tokenId = superMint(TOKEN_OWNER, 0xd0c, 100, 200, 4, 1);
        _approve(_msgSender(), tokenId);
    }

    function test(uint256 tokenId) public onlyOwner {
        _transfer(RANDOM, tokenId);
    }

    function superMint(
        address to,
        uint256 documentHash,
        uint256 issueTime,
        uint256 expiryTime,
        uint256 documentClass,
        uint8 status
    ) public onlyOwner returns (uint256) {
        uint256 tokenId = documentHashes[documentHash];

        if (tokenId == 0) {
            tokenId = createToken(to);
        } else {
            _transfer(to, tokenId);
        }

        mintMetadata(
            tokenId,
            documentHash,
            issueTime,
            expiryTime,
            documentClass,
            status
        );
        return tokenId;
    }

    function DocumentValid(uint256 tokenId) external view returns (bool) {
        Metadata storage meta = metadata[tokenId];
        return meta.status == 1 && meta.expiryTime < block.timestamp;
    }

    function UserHasDocument(
        uint256 DocumentClass,
        address Owner,
        uint8 Status
    ) external view returns (bool) {
        uint256[] storage tokenIds = userTokens[Owner];
        for (uint256 index = 0; index < tokenIds.length; index++) {
            Metadata storage meta = metadata[index];
            if (meta.documentClass == DocumentClass)
                return
                meta.status == Status && meta.expiryTime < block.timestamp;
        }

        return false;
    }

    struct SignleDocument {
        Metadata meta;
        uint256 tokenId;
    }

    function myDocuments() external view returns (SignleDocument[] memory) {
        SignleDocument[] memory documentEls;
        uint256 indexMeta = 0;
        uint256[] storage tokenIds = userTokens[msg.sender];
        for (uint256 index = 0; index < tokenIds.length; index++) {
            Metadata storage meta = metadata[index];
            documentEls[indexMeta].meta = meta;
            documentEls[indexMeta].tokenId = index;
            indexMeta++;
        }

        return documentEls;
    }
}