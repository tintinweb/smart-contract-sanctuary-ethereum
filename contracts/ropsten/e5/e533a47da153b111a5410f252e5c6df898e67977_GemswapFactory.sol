/**
 *Submitted for verification at Etherscan.io on 2022-04-06
*/

// SPDX-License-Identifier: WTFPL
pragma solidity >=0.8.0;

//  ██████╗ ███████╗███╗   ███╗███████╗██╗    ██╗ █████╗ ██████╗ 
// ██╔════╝ ██╔════╝████╗ ████║██╔════╝██║    ██║██╔══██╗██╔══██╗
// ██║  ███╗█████╗  ██╔████╔██║███████╗██║ █╗ ██║███████║██████╔╝
// ██║   ██║██╔══╝  ██║╚██╔╝██║╚════██║██║███╗██║██╔══██║██╔═══╝ 
// ╚██████╔╝███████╗██║ ╚═╝ ██║███████║╚███╔███╔╝██║  ██║██║     
//  ╚═════╝ ╚══════╝╚═╝     ╚═╝╚══════╝ ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   

// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)



// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)



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
contract GemswapFactory is Ownable {

    event PairCreated(address indexed token0, address indexed token1, address pair, uint256);

    /* -------------------------------------------------------------------------- */
    /*                                   STORAGE                                  */
    /* -------------------------------------------------------------------------- */
    
    uint256 typeCount; // amount of pool types
    address[] public allPairs;
    mapping(uint256 => bool) public typeAllowed;
    mapping(uint256 => address) public typeToImplementation;
    mapping(address => mapping(address => mapping(uint256 => address))) private _getPair;

    /* -------------------------------------------------------------------------- */
    /*                               PUBLIC LOGIC                                 */
    /* -------------------------------------------------------------------------- */

    error IDENTICAL_ADDRESSES();
    error PAIR_ALREADY_EXISTS();
    error ZERO_ADDRESS();
    error POOL_NOT_ALLOWED();

    function createPair(
        address tokenA, 
        address tokenB, 
        uint256 poolType
    ) public returns (address pair) {
        if (tokenA == tokenB) revert IDENTICAL_ADDRESSES();
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        if (token0 == address(0)) revert ZERO_ADDRESS(); 
        if (_getPair[token0][token1][poolType] != address(0)) revert PAIR_ALREADY_EXISTS(); // single check is sufficient
        if (typeAllowed[poolType] == false) revert POOL_NOT_ALLOWED();

        pair = _clonePair(typeToImplementation[poolType], keccak256(abi.encodePacked(token0, token1, poolType)));
        IGemswap(pair).initialize(token0, token1, 25);
        
        _getPair[token0][token1][poolType] = pair;
        allPairs.push(pair);
        emit PairCreated(token0, token1, pair, allPairs.length);
    }

    function createPair(
        address tokenA, 
        address tokenB
    ) external returns (address pair) {
        return createPair(tokenA, tokenB, 1);
    }

    function getPair(address tokenA, address tokenB, uint256 poolType) external view returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = _getPair[token0][token1][poolType];
        require(pair != address(0), "!nonexistent");
    }

    function getPair(address tokenA, address tokenB) external view returns (address pair) {
        (address token0, address token1) = tokenA < tokenB ? (tokenA, tokenB) : (tokenB, tokenA);
        pair = _getPair[token0][token1][1];
    }
    
    function allPairsLength() external view returns (uint256) {
        return allPairs.length;
    }

    /* -------------------------------------------------------------------------- */
    /*                              MANAGEMENT LOGIC                              */
    /* -------------------------------------------------------------------------- */

    function newPoolType(address impl) external onlyOwner {
        unchecked { ++typeCount; }
        typeToImplementation[typeCount] = impl;
    }

    function allowPoolType(uint256 poolType, bool allowed) external onlyOwner {
        typeAllowed[poolType] = allowed;
    }

    /* -------------------------------------------------------------------------- */
    /*                                 CLONE LOGIC                                */
    /* -------------------------------------------------------------------------- */

    function _clonePair(address impl, bytes32 salt) internal returns (address instance) {
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(ptr, 0x14), shl(0x60, impl))
            mstore(add(ptr, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            instance := create2(0, ptr, 0x37, salt)
            // WAGMI send it
            if iszero(instance) { revert(3, 3) }
        }
    }
}

interface IGemswap {
    function initialize(address token0, address token1, uint256 swapFee) external;
}