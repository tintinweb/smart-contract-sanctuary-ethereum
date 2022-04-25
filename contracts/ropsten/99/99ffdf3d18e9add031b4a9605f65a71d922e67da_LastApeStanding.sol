/**
 *Submitted for verification at Etherscan.io on 2022-04-24
*/

/**
 *Submitted for verification at BscScan.com on 2022-04-11
*/

/*

This is the official contract of the LastApeStanding token. This token
is the first of its kind to implement an innovative jackpot mechanism.

Every buy and sell will feed the jackpot (2%/5%). If for 10 mins, no buys are
recorded, the last buyer will receive a portion of the jackpot. This will drive
a consistent buy pressure.

The jackpot has a hard limit ($100K) that, if reached, will trigger the big bang event. A portion
of the jackpot will be cashed out to the buyback wallet. The buyback wallet will
then either burn the tokens or dedicate a portion of it towards staking.


*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.13;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
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
contract Ownable is Context {
    address private _owner;
    address private _lockedLiquidity;
    address payable private _devWallet;
    address payable private _marketingWallet;
    address payable private _buybackWallet;

    mapping(address => bool) internal authorizations;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    event AuthorizationGranted(address indexed wallet);
    event AuthorizationRevoked(address indexed wallet);

    event DevWalletChanged(address indexed from, address indexed to);
    event MarketingWalletChanged(address indexed from, address indexed to);
    event BuybackWalletChanged(address indexed from, address indexed to);
    event LockedLiquidityAddressChanged(
        address indexed from,
        address indexed to
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor(address initialOwner) {
        _owner = initialOwner;
        authorizations[_owner] = true;

        emit OwnershipTransferred(address(0), initialOwner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    function lockedLiquidity() public view returns (address) {
        return _lockedLiquidity;
    }

    function devWallet() public view returns (address payable) {
        return _devWallet;
    }

    function marketingWallet() public view returns (address payable) {
        return _marketingWallet;
    }

    function buybackWallet() public view returns (address payable) {
        return _buybackWallet;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Throws if called by any account other than the dev wallet owner.
     */
    modifier onlyDev() {
        require(
            _devWallet == _msgSender(),
            "Ownable: caller is not the dev wallet owner"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the marketing wallet owner.
     */
    modifier onlyMarketing() {
        require(
            _marketingWallet == _msgSender(),
            "Ownable: caller is not the marketing wallet owner"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the buyback wallet owner.
     */
    modifier onlyBuyback() {
        require(
            _buybackWallet == _msgSender(),
            "Ownable: caller is not the buyback wallet owner"
        );
        _;
    }

    function setDevWalletAddress(address payable devWalletAddress)
        public
        virtual
        onlyOwner
    {
        require(
            devWalletAddress != address(0),
            "You must supply a non-zero address"
        );
        emit DevWalletChanged(_devWallet, devWalletAddress);
        _devWallet = devWalletAddress;
    }

    function setMarketingWalletAddress(address payable marketingWalletAddress)
        public
        virtual
        onlyOwner
    {
        require(
            marketingWalletAddress != address(0),
            "You must supply a non-zero address"
        );
        emit MarketingWalletChanged(_marketingWallet, marketingWalletAddress);
        _marketingWallet = marketingWalletAddress;
    }

    function setBuybackWallet(address payable buybackWalletAddress)
        public
        virtual
        onlyOwner
    {
        require(
            buybackWalletAddress != address(0),
            "You must supply a non-zero address"
        );
        emit BuybackWalletChanged(_buybackWallet, buybackWalletAddress);
        _buybackWallet = buybackWalletAddress;
    }

    function setLockedLiquidityAddress(address liquidityAddress)
        public
        virtual
        onlyOwner
    {
        require(
            liquidityAddress != _lockedLiquidity,
            "The same liquidity address is used"
        );
        emit LockedLiquidityAddressChanged(_lockedLiquidity, liquidityAddress);
        _lockedLiquidity = liquidityAddress;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        _owner = newOwner;
        authorizations[newOwner] = true;
        emit OwnershipTransferred(_owner, newOwner);
    }

    /**
     * Function modifier to require caller to be authorized
     */
    modifier onlyAuthorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    /**
     * Authorize address. Owner only
     */
    function authorize(address adr) public onlyOwner {
        require(!authorizations[adr], "Address is already authorized");
        authorizations[adr] = true;

        emit AuthorizationGranted(adr);
    }

    /**
     * Remove address' authorization. Owner only
     */
    function unauthorize(address adr) public onlyOwner {
        require(authorizations[adr], "Address is already NOT authorized");
        authorizations[adr] = false;

        emit AuthorizationRevoked(adr);
    }

    /**
     * Return address' authorization status
     */
    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router01.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router01 {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    )
        external
        returns (
            uint256 amountA,
            uint256 amountB,
            uint256 liquidity
        );

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
        external
        payable
        returns (
            uint256 amountToken,
            uint256 amountETH,
            uint256 liquidity
        );

    function removeLiquidity(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);

    function removeLiquidityWithPermit(
        address tokenA,
        address tokenB,
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountA, uint256 amountB);

    function removeLiquidityETHWithPermit(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountToken, uint256 amountETH);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapTokensForExactTokens(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapTokensForExactETH(
        uint256 amountOut,
        uint256 amountInMax,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapETHForExactTokens(
        uint256 amountOut,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function quote(
        uint256 amountA,
        uint256 reserveA,
        uint256 reserveB
    ) external pure returns (uint256 amountB);

    function getAmountOut(
        uint256 amountIn,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountOut);

    function getAmountIn(
        uint256 amountOut,
        uint256 reserveIn,
        uint256 reserveOut
    ) external pure returns (uint256 amountIn);

    function getAmountsOut(uint256 amountIn, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);

    function getAmountsIn(uint256 amountOut, address[] calldata path)
        external
        view
        returns (uint256[] memory amounts);
}

// File: @uniswap/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol

pragma solidity >=0.6.2;

interface IUniswapV2Router02 is IUniswapV2Router01 {
    function removeLiquidityETHSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountETH);

    function removeLiquidityETHWithPermitSupportingFeeOnTransferTokens(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline,
        bool approveMax,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external returns (uint256 amountETH);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol

pragma solidity >=0.5.0;

interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}

// File: @uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol

pragma solidity >=0.5.0;

interface IUniswapV2Factory {
    event PairCreated(
        address indexed token0,
        address indexed token1,
        address pair,
        uint256
    );

    function feeTo() external view returns (address);

    function feeToSetter() external view returns (address);

    function getPair(address tokenA, address tokenB)
        external
        view
        returns (address pair);

    function allPairs(uint256) external view returns (address pair);

    function allPairsLength() external view returns (uint256);

    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);

    function setFeeTo(address) external;

    function setFeeToSetter(address) external;
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
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

// File: @openzeppelin/contracts/utils/structs/EnumerableSet.sol

// OpenZeppelin Contracts v4.4.1 (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastvalue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastvalue;
                // Update the index for the moved value
                set._indexes[lastvalue] = valueIndex; // Replace lastvalue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value)
        private
        view
        returns (bool)
    {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index)
        private
        view
        returns (bytes32)
    {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index)
        internal
        view
        returns (bytes32)
    {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set)
        internal
        view
        returns (bytes32[] memory)
    {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index)
        internal
        view
        returns (address)
    {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set)
        internal
        view
        returns (address[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value)
        internal
        returns (bool)
    {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value)
        internal
        view
        returns (bool)
    {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index)
        internal
        view
        returns (uint256)
    {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set)
        internal
        view
        returns (uint256[] memory)
    {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        assembly {
            result := store
        }

        return result;
    }
}

// File: @openzeppelin/contracts/utils/math/SafeMath.sol

// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b)
        internal
        pure
        returns (bool, uint256)
    {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// File: @openzeppelin/contracts/utils/Address.sol

// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

contract LastApeStanding is Context, IERC20, Ownable {
    using SafeMath for uint256;
    using Address for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;

    EnumerableSet.AddressSet private _isExcludedFromFee;
    EnumerableSet.AddressSet private _isExcludedFromSwapAndLiquify;

    // 100%
    uint256 private constant MAX_PCT = 10000;
    uint256 private constant BNB_DECIMALS = 18;
    uint256 private constant USDT_DECIMALS = 18;
    address private constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address private constant DEAD = 0x000000000000000000000000000000000000dEaD;

    // At any given time, buy and sell fees can NOT exceed 25% each
    uint256 private constant TOTAL_FEES_LIMIT = 2500;
    // We don't add to liquidity unless we have at least 1 LAS token
    uint256 private constant LIQ_SWAP_THRESH = 10**_decimals;

    // PCS takes 0.25% fee on all txs
    uint256 private constant ROUTER_FEE = 25;

    // Jackpot hard limits
    uint256 private constant JACKPOT_TIMESPAN_LIMIT_MIN = 30;
    uint256 private constant JACKPOT_TIMESPAN_LIMIT_MAX = 1200;

    uint256 private constant JACKPOT_BIGBANG_MIN = 30000 * 10**USDT_DECIMALS;
    uint256 private constant JACKPOT_BIGBANG_MAX = 250000 * 10**USDT_DECIMALS;

    uint256 private constant JACKPOT_BUYER_SHARE_MIN = 5000;
    uint256 private constant JACKPOT_BUYER_SHARE_MAX = 10000;

    uint256 private constant JACKPOT_MINBUY_MIN = 5 * 10**(BNB_DECIMALS - 2);
    uint256 private constant JACKPOT_MINBUY_MAX = 5 * 10**(BNB_DECIMALS - 1);

    uint256 private constant JACKPOT_CASHOUT_MIN = 4000;
    uint256 private constant JACKPOT_CASHOUT_MAX = 7000;

    uint256 private constant JACKPOT_BIGBANG_BUYBACK_MIN = 3000;
    uint256 private constant JACKPOT_BIGBANG_BUYBACK_MAX = 7000;

    string private constant _name = "LastApeStanding";
    string private constant _symbol = "LAS";
    uint8 private constant _decimals = 9;
    uint256 private constant _tTotal = 10000000 * 10**_decimals;

    // Max wallet size initially set to 1%
    uint256 public maxWalletSize = _tTotal.div(100);

    // Buy fees
    // 1% liquidity
    uint256 public bLiquidityFee = 100;
    // 2% marketing
    uint256 public bMarketingFee = 200;
    // 2% dev
    uint256 public bDevFee = 200;
    // 2% jackpot
    uint256 public bJackpotFee = 200;

    // Sell fees
    // 1% liquidity
    uint256 public sLiquidityFee = 100;
    // 5% marketing
    uint256 public sMarketingFee = 500;
    // 2% dev
    uint256 public sDevFee = 200;
    // 5% jackpot
    uint256 public sJackpotFee = 500;

    // Fee variables for cross-method usage
    uint256 private _liquidityFee = 0;
    uint256 private _marketingFee = 0;
    uint256 private _devFee = 0;
    uint256 private _jackpotFee = 0;

    // Token distribution held by the contract
    uint256 private _liquidityTokens = 0;
    uint256 private _marketingTokens = 0;
    uint256 private _devTokens = 0;
    uint256 private _jackpotTokens = 0;

    // Jackpot related variables
    // 55.55% jackpot cashout to last buyer
    uint256 public jackpotCashout = 5555;
    // 90% of jackpot cashout to last buyer
    uint256 public jackpotBuyerShare = 9000;
    // Buys > 0.1 BNB will be eligible for the jackpot
    uint256 public jackpotMinBuy = 1 * 10**(BNB_DECIMALS - 1);
    // Jackpot time span is initially set to 10 mins
    uint256 public jackpotTimespan = 10 * 60;
    // Jackpot hard limit, BNB value
    uint256 public jackpotHardLimit = 250 * 10**(BNB_DECIMALS);
    // Jackpot hard limit buyback share
    uint256 public jackpotHardBuyback = 5000;

    address payable private _lastBuyer = payable(address(this));
    uint256 private _lastBuyTimestamp = 0;

    address private _lastAwarded = address(0);
    uint256 private _lastAwardedCash = 0;
    uint256 private _lastAwardedTokens = 0;
    uint256 private _lastAwardedTimestamp = 0;

    uint256 private _lastBigBangCash = 0;
    uint256 private _lastBigBangTokens = 0;
    uint256 private _lastBigBangTimestamp = 0;

    // The minimum transaction limit that can be set is 0.1% of the total supply
    uint256 private constant MIN_TX_LIMIT = 10;
    // Initially, max TX amount is set to the total supply
    uint256 public maxTxAmount = _tTotal;

    uint256 public numTokensSellToAddToLiquidity = 2000 * 10**_decimals;

    // Pending balances (BNB) ready to be collected
    uint256 private _pendingMarketingBalance = 0;
    uint256 private _pendingDevBalance = 0;
    uint256 private _pendingJackpotBalance = 0;

    // Total BNB/LAS collected by various mechanisms (dev, marketing, jackpot)
    uint256 private _totalMarketingFeesCollected = 0;
    uint256 private _totalDevFeesCollected = 0;
    uint256 private _totalJackpotCashedOut = 0;
    uint256 private _totalJackpotTokensOut = 0;
    uint256 private _totalJackpotBuyer = 0;
    uint256 private _totalJackpotBuyback = 0;
    uint256 private _totalJackpotBuyerTokens = 0;
    uint256 private _totalJackpotBuybackTokens = 0;

    bool public tradingOpen = false;
    // Liquidity
    bool public swapAndLiquifyEnabled = true;
    bool private _inSwapAndLiquify;

    IUniswapV2Router02 public uniswapV2Router;
    address public uniswapV2Pair;

    event SwapAndLiquifyEnabledUpdated(bool enabled);
    event SwapAndLiquify(
        uint256 tokensSwapped,
        uint256 bnbReceived,
        uint256 tokensIntoLiquidity
    );
    event DevFeesCollected(uint256 bnbCollected);
    event MarketingFeesCollected(uint256 bnbCollected);
    event JackpotAwarded(
        uint256 cashedOut,
        uint256 tokensOut,
        uint256 buyerShare,
        uint256 tokensToBuyer,
        uint256 toBuyback,
        uint256 tokensToBuyback
    );
    event BigBang(uint256 cashedOut, uint256 tokensOut);

    event BuyFeesChanged(
        uint256 liquidityFee,
        uint256 marketingFee,
        uint256 devFee,
        uint256 jackpotFee
    );

    event SellFeesChanged(
        uint256 liquidityFee,
        uint256 marketingFee,
        uint256 devFee,
        uint256 jackpotFee
    );

    event JackpotFeaturesChanged(
        uint256 jackpotCashout,
        uint256 jackpotBuyerShare,
        uint256 jackpotMinBuy
    );

    event JackpotTimespanChanged(uint256 jackpotTimespan);

    event MaxTransferAmountChanged(uint256 maxTxAmount);

    event MaxWalletSizeChanged(uint256 maxWalletSize);

    event TokenToSellOnSwapChanged(uint256 numTokens);

    event BigBangFeaturesChanged(
        uint256 jackpotHardBuyback,
        uint256 jackpotHardLimit
    );

    event JackpotFund(uint256 bnbSent, uint256 tokenAmount);

    modifier lockTheSwap() {
        _inSwapAndLiquify = true;
        _;
        _inSwapAndLiquify = false;
    }

    constructor(address cOwner) Ownable(cOwner) {
        _tOwned[cOwner] = _tTotal;

        uniswapV2Router = IUniswapV2Router02(
            0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
        );
        uniswapV2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(
                address(this),
                uniswapV2Router.WETH()
            );

        // Exclude system addresses from fee
        _isExcludedFromFee.add(owner());
        _isExcludedFromFee.add(address(this));

        _isExcludedFromSwapAndLiquify.add(uniswapV2Pair);

        emit Transfer(address(0), cOwner, _tTotal);
    }

    receive() external payable {}

    function name() public pure returns (string memory) {
        return _name;
    }

    function symbol() public pure returns (string memory) {
        return _symbol;
    }

    function decimals() public pure returns (uint8) {
        return _decimals;
    }

    function totalSupply() public pure returns (uint256) {
        return _tTotal;
    }

    function balanceOf(address account) public view override returns (uint256) {
        return _tOwned[account];
    }

    function transfer(address recipient, uint256 amount)
        public
        override
        returns (bool)
    {
        transfer(_msgSender(), recipient, amount);
        return true;
    }

    function allowance(address owner, address spender)
        public
        view
        override
        returns (uint256)
    {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount)
        public
        override
        returns (bool)
    {
        approve(_msgSender(), spender, amount);
        return true;
    }

    function approve(
        address owner,
        address spender,
        uint256 amount
    ) private {
        require(owner != address(0), "BEP20: approve from the zero address");
        require(spender != address(0), "BEP20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        transfer(sender, recipient, amount);
        approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()].sub(
                amount,
                "BEP20: transfer amount exceeds allowance"
            )
        );
        return true;
    }

    function increaseAllowance(address spender, uint256 addedValue)
        public
        virtual
        returns (bool)
    {
        approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].add(addedValue)
        );
        return true;
    }

    function decreaseAllowance(address spender, uint256 subtractedValue)
        public
        virtual
        returns (bool)
    {
        approve(
            _msgSender(),
            spender,
            _allowances[_msgSender()][spender].sub(
                subtractedValue,
                "BEP20: decreased allowance below zero"
            )
        );
        return true;
    }

    function totalMarketingFeesCollected()
        external
        view
        onlyMarketing
        returns (uint256)
    {
        return _totalMarketingFeesCollected;
    }

    function totalDevFeesCollected() external view onlyDev returns (uint256) {
        return _totalDevFeesCollected;
    }

    function totalJackpotOut() external view returns (uint256, uint256) {
        return (_totalJackpotCashedOut, _totalJackpotTokensOut);
    }

    function totalJackpotBuyer() external view returns (uint256, uint256) {
        return (_totalJackpotBuyer, _totalJackpotBuyerTokens);
    }

    function totalJackpotBuyback() external view returns (uint256, uint256) {
        return (_totalJackpotBuyback, _totalJackpotBuybackTokens);
    }

    function excludeFromFee(address account) public onlyAuthorized {
        _isExcludedFromFee.add(account);
    }

    function includeInFee(address account) public onlyAuthorized {
        _isExcludedFromFee.remove(account);
    }

    function setBuyFees(
        uint256 liquidityFee,
        uint256 marketingFee,
        uint256 devFee,
        uint256 jackpotFee
    ) external onlyAuthorized {
        require(
            liquidityFee.add(marketingFee).add(devFee).add(jackpotFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        bLiquidityFee = liquidityFee;
        bMarketingFee = marketingFee;
        bDevFee = devFee;
        bJackpotFee = jackpotFee;

        emit BuyFeesChanged(bLiquidityFee, bMarketingFee, bDevFee, bJackpotFee);
    }

    function getBuyTax() public view returns (uint256) {
        return bLiquidityFee.add(bMarketingFee).add(bDevFee).add(bJackpotFee);
    }

    function setSellFees(
        uint256 liquidityFee,
        uint256 marketingFee,
        uint256 devFee,
        uint256 jackpotFee
    ) external onlyAuthorized {
        require(
            liquidityFee.add(marketingFee).add(devFee).add(jackpotFee) <=
                TOTAL_FEES_LIMIT,
            "Total fees can not exceed the declared limit"
        );
        sLiquidityFee = liquidityFee;
        sMarketingFee = marketingFee;
        sDevFee = devFee;
        sJackpotFee = jackpotFee;

        emit SellFeesChanged(
            sLiquidityFee,
            sMarketingFee,
            sDevFee,
            sJackpotFee
        );
    }

    function getSellTax() public view returns (uint256) {
        return sLiquidityFee.add(sMarketingFee).add(sDevFee).add(sJackpotFee);
    }

    function setJackpotFeatures(
        uint256 _jackpotCashout,
        uint256 _jackpotBuyerShare,
        uint256 _jackpotMinBuy
    ) external onlyAuthorized {
        require(
            _jackpotCashout >= JACKPOT_CASHOUT_MIN &&
                _jackpotCashout <= JACKPOT_CASHOUT_MAX,
            "Jackpot cashout percentage needs to be between 40% and 70%"
        );
        require(
            _jackpotBuyerShare >= JACKPOT_BUYER_SHARE_MIN &&
                _jackpotBuyerShare <= JACKPOT_BUYER_SHARE_MAX,
            "Jackpot buyer share percentage needs to be between 50% and 100%"
        );
        require(
            _jackpotMinBuy >= JACKPOT_MINBUY_MIN &&
                _jackpotMinBuy <= JACKPOT_MINBUY_MAX,
            "Jackpot min buy needs to be between 0.05 and 0.5 BNB"
        );
        jackpotCashout = _jackpotCashout;
        jackpotBuyerShare = _jackpotBuyerShare;
        jackpotMinBuy = _jackpotMinBuy;

        emit JackpotFeaturesChanged(
            jackpotCashout,
            jackpotBuyerShare,
            jackpotMinBuy
        );
    }

    function setJackpotHardFeatures(
        uint256 _jackpotHardBuyback,
        uint256 _jackpotHardLimit
    ) external onlyAuthorized {
        require(
            _jackpotHardBuyback >= JACKPOT_BIGBANG_BUYBACK_MIN &&
                _jackpotHardBuyback <= JACKPOT_BIGBANG_BUYBACK_MAX,
            "Jackpot hard buyback percentage needs to be between 30% and 70%"
        );
        jackpotHardBuyback = _jackpotHardBuyback;

        uint256 hardLimitUsd = usdEquivalent(_jackpotHardLimit);
        require(
            hardLimitUsd >= JACKPOT_BIGBANG_MIN &&
                hardLimitUsd <= JACKPOT_BIGBANG_MAX,
            "Jackpot hard value limit for the big bang needs to be between 30K and 250K USD"
        );
        jackpotHardLimit = _jackpotHardLimit;

        emit BigBangFeaturesChanged(jackpotHardBuyback, jackpotHardLimit);
    }

    function setJackpotTimespanInSeconds(uint256 _jackpotTimespan)
        external
        onlyAuthorized
    {
        require(
            _jackpotTimespan >= JACKPOT_TIMESPAN_LIMIT_MIN &&
                _jackpotTimespan <= JACKPOT_TIMESPAN_LIMIT_MAX,
            "Jackpot timespan needs to be between 30 and 1200 seconds (20 minutes)"
        );
        jackpotTimespan = _jackpotTimespan;

        emit JackpotTimespanChanged(jackpotTimespan);
    }

    function setMaxTxAmount(uint256 txAmount) external onlyAuthorized {
        require(
            txAmount >= _tTotal.mul(MIN_TX_LIMIT).div(MAX_PCT),
            "Maximum transaction limit can't be less than 0.1% of the total supply"
        );
        maxTxAmount = txAmount;

        emit MaxTransferAmountChanged(maxTxAmount);
    }

    function setMaxWallet(uint256 amount) external onlyAuthorized {
        require(
            amount >= _tTotal.div(1000),
            "Max wallet size must be at least 0.1% of the total supply"
        );
        maxWalletSize = amount;

        emit MaxWalletSizeChanged(maxWalletSize);
    }

    function setNumTokensSellToAddToLiquidity(uint256 numTokens)
        external
        onlyAuthorized
    {
        numTokensSellToAddToLiquidity = numTokens;

        emit TokenToSellOnSwapChanged(numTokensSellToAddToLiquidity);
    }

    function fundJackpot(uint256 tokenAmount) external payable onlyAuthorized {
        require(
            balanceOf(msg.sender) >= tokenAmount,
            "You don't have enough tokens to fund the jackpot"
        );
        uint256 bnbSent = msg.value;
        _pendingJackpotBalance = _pendingJackpotBalance.add(bnbSent);
        if (tokenAmount > 0) {
            transferBasic(msg.sender, address(this), tokenAmount);
            _jackpotTokens = _jackpotTokens.add(tokenAmount);
        }

        emit JackpotFund(bnbSent, tokenAmount);
    }

    function isJackpotEligible(uint256 tokenAmount) public view returns (bool) {
        if (jackpotMinBuy == 0) {
            return true;
        }
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = address(this);

        uint256 tokensOut = uniswapV2Router
        .getAmountsOut(jackpotMinBuy, path)[1].mul(MAX_PCT.sub(ROUTER_FEE)).div(
                // We don't subtract the buy fee since the tokenAmount is pre-tax
                MAX_PCT
            );
        return tokenAmount >= tokensOut;
    }

    function usdEquivalent(uint256 bnbAmount) public view returns (uint256) {
        address[] memory path = new address[](2);
        path[0] = uniswapV2Router.WETH();
        path[1] = USDT;

        return uniswapV2Router.getAmountsOut(bnbAmount, path)[1];
    }

    function getUsedTokens(
        uint256 accSum,
        uint256 tokenAmount,
        uint256 tokens
    ) private pure returns (uint256, uint256) {
        if (accSum >= tokenAmount) {
            return (0, accSum);
        }
        uint256 available = tokenAmount - accSum;
        if (tokens <= available) {
            return (tokens, accSum.add(tokens));
        }
        return (available, accSum.add(available));
    }

    function getTokenShares(uint256 tokenAmount)
        private
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 accSum = 0;
        uint256 liquidityTokens = 0;
        uint256 marketingTokens = 0;
        uint256 devTokens = 0;
        uint256 jackpotTokens = 0;

        // Either 0 or 1+ LAS to prevent PCS errors on liq swap
        if (_liquidityTokens >= LIQ_SWAP_THRESH) {
            (liquidityTokens, accSum) = getUsedTokens(
                accSum,
                tokenAmount,
                _liquidityTokens
            );
            _liquidityTokens = _liquidityTokens.sub(liquidityTokens);
        }

        (marketingTokens, accSum) = getUsedTokens(
            accSum,
            tokenAmount,
            _marketingTokens
        );
        _marketingTokens = _marketingTokens.sub(marketingTokens);

        (devTokens, accSum) = getUsedTokens(accSum, tokenAmount, _devTokens);
        _devTokens = _devTokens.sub(devTokens);

        (jackpotTokens, accSum) = getUsedTokens(
            accSum,
            tokenAmount,
            _jackpotTokens
        );
        _jackpotTokens = _jackpotTokens.sub(jackpotTokens);

        return (liquidityTokens, marketingTokens, devTokens, jackpotTokens);
    }

    function setSwapAndLiquifyEnabled(bool enabled) public onlyOwner {
        swapAndLiquifyEnabled = enabled;
        emit SwapAndLiquifyEnabledUpdated(enabled);
    }

    function isExcludedFromFee(address account) public view returns (bool) {
        return _isExcludedFromFee.contains(account);
    }

    function isExcludedFromSwapAndLiquify(address account)
        public
        view
        returns (bool)
    {
        return _isExcludedFromSwapAndLiquify.contains(account);
    }

    function includeFromSwapAndLiquify(address account) external onlyOwner {
        _isExcludedFromSwapAndLiquify.remove(account);
    }

    function excludeFromSwapAndLiquify(address account) external onlyOwner {
        _isExcludedFromSwapAndLiquify.add(account);
    }

    function setUniswapRouter(address otherRouterAddress) external onlyOwner {
        uniswapV2Router = IUniswapV2Router02(otherRouterAddress);
    }

    function setUniswapPair(address otherPairAddress) external onlyOwner {
        require(
            otherPairAddress != address(0),
            "You must supply a non-zero address"
        );
        uniswapV2Pair = otherPairAddress;
    }

    function transfer(
        address from,
        address to,
        uint256 amount
    ) private {
        require(from != address(0), "BEP20: transfer from the zero address");
        require(to != address(0), "BEP20: transfer to the zero address");
        require(to != devWallet(), "Dev wallet address cannot receive tokens");
        require(from != devWallet(), "Dev wallet address cannot send tokens");
        require(amount > 0, "Transfer amount must be greater than zero");

        if (from != owner() && to != owner()) {
            require(
                amount <= maxTxAmount,
                "Transfer amount exceeds the maxTxAmount"
            );
        }

        if (!authorizations[from] && !authorizations[to]) {
            require(tradingOpen, "Trading is currently not open");
        }

        // Jackpot mechanism locks the swap if triggered. We should handle it as
        // soon as possible so that we could award the jackpot on a sell and on a buy
        if (!_inSwapAndLiquify && _pendingJackpotBalance >= jackpotHardLimit) {
            processBigBang();
        } else if (
            // We can't award the jackpot in swap and liquify
            // Pending balances need to be untouched (externally) for swaps
            !_inSwapAndLiquify &&
            _lastBuyer != address(0) &&
            _lastBuyer != address(this) &&
            block.timestamp.sub(_lastBuyTimestamp) >= jackpotTimespan
        ) {
            awardJackpot();
        }

        uint256 contractTokenBalance = balanceOf(address(this));

        if (contractTokenBalance >= maxTxAmount) {
            contractTokenBalance = maxTxAmount;
        }

        bool isOverMinTokenBalance = contractTokenBalance >=
            numTokensSellToAddToLiquidity;
        if (
            isOverMinTokenBalance &&
            !_inSwapAndLiquify &&
            !_isExcludedFromSwapAndLiquify.contains(from) &&
            swapAndLiquifyEnabled
        ) {
            swapAndLiquify(numTokensSellToAddToLiquidity);
        }

        bool takeFee = true;
        if (
            _isExcludedFromFee.contains(from) ||
            _isExcludedFromFee.contains(to) ||
            (uniswapV2Pair != from && uniswapV2Pair != to)
        ) {
            takeFee = false;
        }

        tokenTransfer(from, to, amount, takeFee);
    }

    function enableTrading() public onlyOwner {
        // Trading can only be enabled, so it can never be turned off
        tradingOpen = true;
    }

    function collectMarketingFees() public onlyMarketing {
        _totalMarketingFeesCollected = _totalMarketingFeesCollected.add(
            _pendingMarketingBalance
        );
        marketingWallet().transfer(_pendingMarketingBalance);
        emit MarketingFeesCollected(_pendingMarketingBalance);
        _pendingMarketingBalance = 0;
    }

    function collectDevFees() public onlyDev {
        _totalDevFeesCollected = _totalDevFeesCollected.add(_pendingDevBalance);
        devWallet().transfer(_pendingDevBalance);
        emit DevFeesCollected(_pendingDevBalance);
        _pendingDevBalance = 0;
    }

    function getJackpot() public view returns (uint256, uint256) {
        return (_pendingJackpotBalance, _jackpotTokens);
    }

    function jackpotBuyerShareAmount() public view returns (uint256, uint256) {
        uint256 bnb = _pendingJackpotBalance
            .mul(jackpotCashout)
            .div(MAX_PCT)
            .mul(jackpotBuyerShare)
            .div(MAX_PCT);
        uint256 tokens = _jackpotTokens
            .mul(jackpotCashout)
            .div(MAX_PCT)
            .mul(jackpotBuyerShare)
            .div(MAX_PCT);
        return (bnb, tokens);
    }

    function jackpotBuybackAmount() public view returns (uint256, uint256) {
        uint256 bnb = _pendingJackpotBalance
            .mul(jackpotCashout)
            .div(MAX_PCT)
            .mul(MAX_PCT.sub(jackpotBuyerShare))
            .div(MAX_PCT);
        uint256 tokens = _jackpotTokens
            .mul(jackpotCashout)
            .div(MAX_PCT)
            .mul(MAX_PCT.sub(jackpotBuyerShare))
            .div(MAX_PCT);

        return (bnb, tokens);
    }

    function getLastBuy() public view returns (address, uint256) {
        return (_lastBuyer, _lastBuyTimestamp);
    }

    function getLastAwarded()
        public
        view
        returns (
            address,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _lastAwarded,
            _lastAwardedCash,
            _lastAwardedTokens,
            _lastAwardedTimestamp
        );
    }

    function getLastBigBang()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (_lastBigBangCash, _lastBigBangTokens, _lastBigBangTimestamp);
    }

    function getPendingBalances()
        public
        view
        onlyAuthorized
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (
            _pendingMarketingBalance,
            _pendingDevBalance,
            _pendingJackpotBalance
        );
    }

    function getPendingTokens()
        public
        view
        onlyAuthorized
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (_liquidityTokens, _marketingTokens, _devTokens, _jackpotTokens);
    }

    function processBigBang() private lockTheSwap {
        uint256 cashedOut = _pendingJackpotBalance.mul(jackpotHardBuyback).div(
            MAX_PCT
        );
        uint256 tokensOut = _jackpotTokens.mul(jackpotHardBuyback).div(MAX_PCT);

        buybackWallet().transfer(cashedOut);
        transferBasic(address(this), buybackWallet(), tokensOut);
        emit BigBang(cashedOut, tokensOut);

        _lastBigBangCash = cashedOut;
        _lastBigBangTokens = tokensOut;
        _lastBigBangTimestamp = block.timestamp;

        _pendingJackpotBalance = _pendingJackpotBalance.sub(cashedOut);
        _jackpotTokens = _jackpotTokens.sub(tokensOut);

        _totalJackpotCashedOut = _totalJackpotCashedOut.add(cashedOut);
        _totalJackpotBuyback = _totalJackpotBuyback.add(cashedOut);
        _totalJackpotTokensOut = _totalJackpotTokensOut.add(tokensOut);
        _totalJackpotBuybackTokens = _totalJackpotBuybackTokens.add(tokensOut);
    }

    function awardJackpot() private lockTheSwap {
        require(
            _lastBuyer != address(0) && _lastBuyer != address(this),
            "No last buyer detected"
        );
        uint256 cashedOut = _pendingJackpotBalance.mul(jackpotCashout).div(
            MAX_PCT
        );
        uint256 tokensOut = _jackpotTokens.mul(jackpotCashout).div(MAX_PCT);
        uint256 buyerShare = cashedOut.mul(jackpotBuyerShare).div(MAX_PCT);
        uint256 tokensToBuyer = tokensOut.mul(jackpotBuyerShare).div(MAX_PCT);
        uint256 toBuyback = cashedOut - buyerShare;
        uint256 tokensToBuyback = tokensOut - tokensToBuyer;
        _lastBuyer.transfer(buyerShare);
        transferBasic(address(this), _lastBuyer, tokensToBuyer);
        buybackWallet().transfer(toBuyback);
        transferBasic(address(this), buybackWallet(), tokensToBuyback);

        _pendingJackpotBalance = _pendingJackpotBalance.sub(cashedOut);
        _jackpotTokens = _jackpotTokens.sub(tokensOut);

        emit JackpotAwarded(
            cashedOut,
            tokensOut,
            buyerShare,
            tokensToBuyer,
            toBuyback,
            tokensToBuyback
        );

        _lastAwarded = _lastBuyer;
        _lastAwardedTimestamp = block.timestamp;
        _lastAwardedCash = buyerShare;
        _lastAwardedTokens = tokensToBuyer;

        _lastBuyer = payable(address(this));
        _lastBuyTimestamp = 0;

        _totalJackpotCashedOut = _totalJackpotCashedOut.add(cashedOut);
        _totalJackpotTokensOut = _totalJackpotTokensOut.add(tokensOut);
        _totalJackpotBuyer = _totalJackpotBuyer.add(buyerShare);
        _totalJackpotBuyerTokens = _totalJackpotBuyerTokens.add(tokensToBuyer);
        _totalJackpotBuyback = _totalJackpotBuyback.add(toBuyback);
        _totalJackpotBuybackTokens = _totalJackpotBuybackTokens.add(
            tokensToBuyback
        );
    }

    function swapAndLiquify(uint256 tokenAmount) private lockTheSwap {
        (
            uint256 liqTokens,
            uint256 marketingTokens,
            uint256 devTokens,
            uint256 jackpotTokens
        ) = getTokenShares(tokenAmount);
        uint256 toBeSwapped = liqTokens.add(marketingTokens).add(devTokens).add(
            jackpotTokens
        );
        // This variable holds the liquidity tokens that won't be converted
        uint256 pureLiqTokens = liqTokens.div(2);

        // Everything else from the tokens should be converted
        uint256 tokensForBnbExchange = toBeSwapped.sub(pureLiqTokens);

        uint256 initialBalance = address(this).balance;
        swapTokensForBnb(tokensForBnbExchange);

        // How many BNBs did we gain after this conversion?
        uint256 gainedBnb = address(this).balance.sub(initialBalance);

        // Calculate the amount of BNB that's assigned to the marketing wallet
        uint256 balanceToMarketing = gainedBnb.mul(marketingTokens).div(
            tokensForBnbExchange
        );
        _pendingMarketingBalance += balanceToMarketing;

        // Same for dev
        uint256 balanceToDev = gainedBnb.mul(devTokens).div(
            tokensForBnbExchange
        );
        _pendingDevBalance += balanceToDev;

        // Same for Jackpot
        uint256 balanceToJackpot = gainedBnb.mul(jackpotTokens).div(
            tokensForBnbExchange
        );
        _pendingJackpotBalance += balanceToJackpot;

        uint256 remainingBnb = gainedBnb
            .sub(balanceToMarketing)
            .sub(balanceToDev)
            .sub(balanceToJackpot);

        if (liqTokens >= LIQ_SWAP_THRESH) {
            // The leftover BNBs are purely for liquidity here
            // We are not guaranteed to have all the pure liq tokens to be transferred to the pair
            // This is because the uniswap router, PCS in this case, will make a quote based
            // on the current reserves of the pair, so one of the parameters will be fully
            // consumed, but the other will have leftovers.
            uint256 prevBalance = balanceOf(address(this));
            uint256 prevBnbBalance = address(this).balance;
            addLiquidity(pureLiqTokens, remainingBnb);
            uint256 usedBnbs = prevBnbBalance.sub(address(this).balance);
            uint256 usedTokens = prevBalance.sub(balanceOf(address(this)));
            // Reallocate the tokens that weren't used back to the internal liquidity tokens tracker
            if (usedTokens < pureLiqTokens) {
                _liquidityTokens += pureLiqTokens.sub(usedTokens);
            }
            // Reallocate the unused BNBs to the pending marketing wallet balance
            if (usedBnbs < remainingBnb) {
                _pendingMarketingBalance += remainingBnb.sub(usedBnbs);
            }

            emit SwapAndLiquify(tokensForBnbExchange, usedBnbs, usedTokens);
        } else {
            // We could have some dust, so we'll just add it to the pending marketing wallet balance
            _pendingMarketingBalance += remainingBnb;

            emit SwapAndLiquify(tokensForBnbExchange, 0, 0);
        }
    }

    function swapTokensForBnb(uint256 tokenAmount) private {
        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = uniswapV2Router.WETH();

        approve(address(this), address(uniswapV2Router), tokenAmount);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            tokenAmount,
            0,
            path,
            address(this),
            block.timestamp
        );
    }

    function addLiquidity(uint256 tokenAmount, uint256 bnbAmount) private {
        // Approve token transfer to cover all possible scenarios
        approve(address(this), address(uniswapV2Router), tokenAmount);

        // Add the liquidity
        uniswapV2Router.addLiquidityETH{value: bnbAmount}(
            address(this),
            tokenAmount,
            0, // slippage is unavoidable
            0, // slippage is unavoidable
            lockedLiquidity(),
            block.timestamp
        );
    }

    function tokenTransfer(
        address sender,
        address recipient,
        uint256 amount,
        bool takeFee
    ) private {
        if (!takeFee) {
            // If we're here, it means either the sender or recipient is excluded from taxes
            // Also, it could be that this is just a transfer of tokens between wallets
            _liquidityFee = 0;
            _marketingFee = 0;
            _devFee = 0;
            _jackpotFee = 0;
        } else if (recipient == uniswapV2Pair) {
            // This is a sell
            _liquidityFee = sLiquidityFee;
            _marketingFee = sMarketingFee;
            _devFee = sDevFee;
            _jackpotFee = sJackpotFee;
        } else {
            // If we're here, it must mean that the sender is the uniswap pair
            // This is a buy
            if (isJackpotEligible(amount)) {
                _lastBuyTimestamp = block.timestamp;
                _lastBuyer = payable(recipient);
            }

            _liquidityFee = bLiquidityFee;
            _marketingFee = bMarketingFee;
            _devFee = bDevFee;
            _jackpotFee = bJackpotFee;
        }

        transferStandard(sender, recipient, amount);
    }

    function transferBasic(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        _tOwned[sender] = _tOwned[sender].sub(amount);
        _tOwned[recipient] = _tOwned[recipient].add(amount);

        emit Transfer(sender, recipient, amount);
    }

    function transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 tTransferAmount,
            uint256 tLiquidity,
            uint256 tMarketing,
            uint256 tDev,
            uint256 tJackpot
        ) = processAmount(tAmount);
        uint256 tFees = tLiquidity.add(tMarketing).add(tDev).add(tJackpot);
        if (recipient != uniswapV2Pair && recipient != DEAD) {
            require(
                isExcludedFromFee(recipient) ||
                    balanceOf(recipient).add(tTransferAmount) <= maxWalletSize,
                "Transfer amount will push this wallet beyond the maximum allowed size"
            );
        }

        _tOwned[sender] = _tOwned[sender].sub(tAmount);
        _tOwned[recipient] = _tOwned[recipient].add(tTransferAmount);

        takeTransactionFee(address(this), tFees);
        _liquidityTokens += tLiquidity;
        _marketingTokens += tMarketing;
        _devTokens += tDev;
        _jackpotTokens += tJackpot;

        emit Transfer(sender, recipient, tTransferAmount);
    }

    function processAmount(uint256 tAmount)
        private
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 tLiquidity = tAmount.mul(_liquidityFee).div(MAX_PCT);
        uint256 tMarketing = tAmount.mul(_marketingFee).div(MAX_PCT);
        uint256 tDev = tAmount.mul(_devFee).div(MAX_PCT);
        uint256 tJackpot = tAmount.mul(_jackpotFee).div(MAX_PCT);
        uint256 tTransferAmount = tAmount.sub(
            tLiquidity.add(tMarketing).add(tDev).add(tJackpot)
        );
        return (tTransferAmount, tLiquidity, tMarketing, tDev, tJackpot);
    }

    function takeTransactionFee(address to, uint256 tAmount) private {
        if (tAmount <= 0) {
            return;
        }
        _tOwned[to] = _tOwned[to].add(tAmount);
    }

}