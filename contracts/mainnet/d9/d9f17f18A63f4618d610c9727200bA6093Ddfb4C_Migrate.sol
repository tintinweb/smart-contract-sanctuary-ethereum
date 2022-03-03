/**
 *Submitted for verification at Etherscan.io on 2022-03-02
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

// File: TheAnomaly.sol



pragma solidity ^0.8.0;


interface IDynamic1155 {
    /**
     * @dev Destroys `amount` tokens of token type `id` from `from`
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `from` must have at least `amount` tokens of token type `id`.
     */
    function burn(
        address account,
        uint256 id,
        uint256 value
    ) external;

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

contract Migrate is Ownable {
    address public token;
    mapping(uint256 => mapping(uint256 => uint256)) private amountToMint;
    mapping(uint256 => mapping(uint256 => uint256)) private amountToBurn;
    mapping(uint256 => bool) private mintable;

    event TransformAdded(uint256 indexed _typeA, uint256 indexed _typeB);

    constructor(
        address _token,
        uint256 _typeA,
        uint256 _typeB,
        uint256 _amountToMint,
        uint256 _amountToBurn
    ) {
        token = _token;
        amountToMint[_typeA][_typeB] = _amountToMint;
        amountToBurn[_typeA][_typeB] = _amountToBurn;
        mintable[_typeB] = true;
    }

    function updateTokenContract(address _token) external onlyOwner {
        token = _token;
    }

    function setTransform(
        uint256 _typeA,
        uint256 _typeB,
        uint256 _amountToMint,
        uint256 _amountToBurn
    ) external onlyOwner {
        amountToMint[_typeA][_typeB] = _amountToMint;
        amountToBurn[_typeA][_typeB] = _amountToBurn;
        mintable[_typeB] = true;

        emit TransformAdded(_typeA, _typeB);
    }

    /**
     * @dev migrate X amount of type A to type B
     */
    function migration(
        uint256 from,
        uint256 to,
        uint256 count
    ) external {
        require(
            amountToMint[from][to] > 0 && amountToBurn[from][to] > 0,
            "Invalid transform"
        );
        IDynamic1155(token).burn(
            msg.sender,
            from,
            amountToBurn[from][to] * count
        );
        IDynamic1155(token).safeTransferFrom(
            address(this),
            msg.sender,
            to,
            count * amountToMint[from][to],
            ""
        );
    }

    function onERC1155Received(
        address,
        address,
        uint256 id,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        require(msg.sender == token && mintable[id], "Invalid token to mint");
        return 0xf23a6e61;
    }
}