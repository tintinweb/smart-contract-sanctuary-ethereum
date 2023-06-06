// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./libraries/Context.sol";
import "./libraries/Ownable.sol";
import "./libraries/ProofReflectionFactoryFees.sol";
import "./interfaces/ITeamFinanceLocker.sol";
import "./interfaces/ITokenCutter.sol";
import "./interfaces/IFACTORY.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IProofReflectionTokenCutter.sol";
import "./tokenCutters/ProofReflectionTokenCutter.sol";

contract ProofReflectionFactory is Ownable {
    struct ProofToken {
        bool status;
        address pair;
        address owner;
        uint256 unlockTime;
        uint256 lockId;
    }

    struct TokenParam {
        string tokenName;
        string tokenSymbol;
        uint256 initialSupply;
        uint256 percentToLP;
        uint256 initialReflectionFee;
        uint256 initialReflectionFeeOnSell;
        uint256 initialLpFee;
        uint256 initialLpFeeOnSell;
        uint256 initialDevFee;
        uint256 initialDevFeeOnSell;
        uint256 unlockTime;
        address devWallet;
        uint256 whitelistEndTime;
        address[] whitelists;
    }

    struct WhitelistAdd_ {
        address [] whitelists;
    }

    mapping(address => ProofToken) public validatedPairs;

    address public proofAdmin;
    address public routerAddress;
    address public lockerAddress;
    address payable public revenueAddress;
    address payable public rewardPoolAddress;

    event TokenCreated(address _address);

    constructor(
        address initialRouterAddress,
        address initialLockerAddress,
        address initialRewardPoolAddress,
        address initialRevenueAddress
    ) {
        routerAddress = initialRouterAddress;
        lockerAddress = initialLockerAddress;
        proofAdmin = msg.sender;
        revenueAddress = payable(initialRevenueAddress);
        rewardPoolAddress = payable(initialRewardPoolAddress);
    }

    function addmoreWhitelist(address tokenAddress, WhitelistAdd_ memory _WhitelistAdd) external {
        _checkTokenStatus(tokenAddress);

        IProofReflectionTokenCutter(tokenAddress).addMoreToWhitelist(IProofReflectionTokenCutter.WhitelistAdd_(_WhitelistAdd.whitelists));
    
    }

    function createToken(TokenParam memory tokenParam_) external payable {
        require(
            tokenParam_.unlockTime >= block.timestamp + 30 days,
            "unlock under 30 days"
        );
        require(msg.value >= 1 ether, "not enough liquidity");

        //create token

        ProofReflectionFactoryFees.allFees
            memory fees = ProofReflectionFactoryFees.allFees(
                tokenParam_.initialReflectionFee,
                tokenParam_.initialReflectionFeeOnSell,
                tokenParam_.initialLpFee,
                tokenParam_.initialLpFeeOnSell,
                tokenParam_.initialDevFee,
                tokenParam_.initialDevFeeOnSell
            );

        ProofReflectionTokenCutter newToken = new ProofReflectionTokenCutter();
        IProofReflectionTokenCutter(address(newToken)).setBasicData(
            IProofReflectionTokenCutter.BaseData(
                tokenParam_.tokenName,
                tokenParam_.tokenSymbol,
                tokenParam_.initialSupply,
                tokenParam_.percentToLP,
                tokenParam_.whitelistEndTime,
                msg.sender,
                tokenParam_.devWallet,
                routerAddress,
                proofAdmin,
                tokenParam_.whitelists
            ),
            fees
        );
        emit TokenCreated(address(newToken));

        //add liquidity
        newToken.approve(routerAddress, type(uint256).max);
        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        router.addLiquidityETH{value: msg.value}(
            address(newToken),
            newToken.balanceOf(address(this)),
            0,
            0,
            address(this),
            block.timestamp + 111
        );

        // disable trading
        newToken.swapTradingStatus();

        validatedPairs[address(newToken)] = ProofToken(
            false,
            newToken.pair(),
            msg.sender,
            tokenParam_.unlockTime,
            0
        );
    }

    function finalizeToken(address tokenAddress) public payable {
        _checkTokenStatus(tokenAddress);

        address _pair = validatedPairs[tokenAddress].pair;
        uint256 _unlockTime = validatedPairs[tokenAddress].unlockTime;
        IERC20(_pair).approve(lockerAddress, type(uint256).max);

        uint256 lpBalance = IERC20(_pair).balanceOf(address(this));

        uint256 _lockId = ITeamFinanceLocker(lockerAddress).lockToken{
            value: msg.value
        }(_pair, msg.sender, lpBalance, _unlockTime, false);
        validatedPairs[tokenAddress].lockId = _lockId;

        //enable trading
        ITokenCutter(tokenAddress).swapTradingStatus();
        ITokenCutter(tokenAddress).setLaunchedAt();

        validatedPairs[tokenAddress].status = true;
    }

    function cancelToken(address tokenAddress) public {
        _checkTokenStatus(tokenAddress);

        address _pair = validatedPairs[tokenAddress].pair;
        address _owner = validatedPairs[tokenAddress].owner;

        IUniswapV2Router02 router = IUniswapV2Router02(routerAddress);
        IERC20(_pair).approve(routerAddress, type(uint256).max);
        uint256 _lpBalance = IERC20(_pair).balanceOf(address(this));

        // enable transfer and allow router to exceed tx limit to remove liquidity
        ITokenCutter(tokenAddress).cancelToken();
        router.removeLiquidityETH(
            address(tokenAddress),
            _lpBalance,
            0,
            0,
            _owner,
            block.timestamp
        );

        // disable transfer of token
        ITokenCutter(tokenAddress).swapTradingStatus();

        delete validatedPairs[tokenAddress];
    }

    function proofRevenueAddress() external view returns (address) {
        return revenueAddress;
    }

    function proofRewardPoolAddress() external view returns (address) {
        return rewardPoolAddress;
    }

    function distributeExcessFunds() external onlyOwner {
        (bool sent, ) = revenueAddress.call{value: address(this).balance / 2}("");
        require(sent, "");
        (bool sent1, ) = rewardPoolAddress.call{value: address(this).balance}("");
        require(sent1, "");
    }

    function setLockerAddress(address newlockerAddress) external onlyOwner {
        lockerAddress = newlockerAddress;
    }

    function setRouterAddress(address newRouterAddress) external onlyOwner {
        routerAddress = payable(newRouterAddress);
    }

    function setProofAdmin(address newProofAdmin) external onlyOwner {
        proofAdmin = newProofAdmin;
    }

    function setRevenueAddress(address newRevenueAddress) external onlyOwner {
        revenueAddress = payable(newRevenueAddress);
    }

    function setRewardPoolAddress(
        address newRewardPoolAddress
    ) external onlyOwner {
        rewardPoolAddress = payable(newRewardPoolAddress);
    }

    function _checkTokenStatus(address tokenAddress) internal view {
        require(validatedPairs[tokenAddress].owner == msg.sender, "!owner");
        require(validatedPairs[tokenAddress].status == false, "validated");
    }

    receive() external payable {}
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
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC20/IERC20.sol)

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
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

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
 * ```solidity
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
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
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
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
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
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
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
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
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
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
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
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
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
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
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
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
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
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
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
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
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
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
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
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
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
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface IDividendDistributor {
    function setDistributionCriteria(
        uint256 _minPeriod,
        uint256 _minDistribution
    ) external;

    function setShare(address shareholder, uint256 amount) external;

    function deposit() external payable;

    function process(uint256 gas) external;

    function setMinPeriod(uint256 _minPeriod) external;

    function setMinDistribution(uint256 _minDistribution) external;

    function rewardTokenAddress() external view returns(address);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface IFACTORY {
    function proofRevenueAddress() external view returns (address);

    function proofRewardPoolAddress() external view returns (address);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "../libraries/ProofReflectionFactoryFees.sol";

interface IProofReflectionTokenCutter is IERC20, IERC20Metadata {
    struct BaseData {
        string tokenName;
        string tokenSymbol;
        uint256 initialSupply;
        uint256 percentToLP;
        uint256 whitelistEndTime;
        address owner;
        address devWallet;
        address routerAddress;
        address initialProofAdmin;
        address[] whitelists;
    }

    struct WhitelistAdd_ {
        address [] whitelists;
    }

    function setBasicData(
        BaseData memory _baseData,
        ProofReflectionFactoryFees.allFees memory fees
    ) external;

    function addMoreToWhitelist(
        WhitelistAdd_ memory _WhitelistAdd
    ) external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface ITeamFinanceLocker {
    function lockToken(
        address _tokenAddress,
        address _withdrawalAddress,
        uint256 _amount,
        uint256 _unlockTime,
        bool _mintNFT
    ) external payable returns (uint256 _id);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface ITokenCutter {
    function swapTradingStatus() external;

    function setLaunchedAt() external;

    function cancelToken() external;
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
        external
        returns (address pair);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

interface IUniswapV2Router02 {
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
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

    function factory() external pure returns (address);

    function WETH() external pure returns (address);

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

    function removeLiquidityETH(
        address token,
        uint256 liquidity,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    ) external returns (uint256 amountToken, uint256 amountETH);
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "./Context.sol";

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(owner() == _msgSender(), "caller is not the owner");
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
        require(
            newOwner != address(0),
            "new owner is the zero address"
        );
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

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

library ProofReflectionFactoryFees {
    struct allFees {
        uint256 reflectionFee;
        uint256 reflectionFeeOnSell;
        uint256 lpFee;
        uint256 lpFeeOnSell;
        uint256 devFee;
        uint256 devFeeOnSell;
    }
}

// SPDX-License-Identifier: None
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../libraries/Ownable.sol";
import "../libraries/Context.sol";
import "../libraries/ProofReflectionFactoryFees.sol";
import "../interfaces/IFACTORY.sol";
import "../interfaces/IDividendDistributor.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IProofReflectionTokenCutter.sol";

contract ProofReflectionTokenCutter is Context, IProofReflectionTokenCutter {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private whitelists;
    //This token was created with PROOF, and audited by Solidity Finance — https://proofplatform.io/projects
    mapping(address => uint256) private _rOwned;
    mapping(address => uint256) private _tOwned;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private constant MAX = ~uint256(0);

    uint256 private _tTotal;
    uint256 private _rTotal;
    uint256 private _tFeeTotal;
    uint256 public swapThreshold;
    uint256 public whitelistEndTime;

    string private _name;
    string private _symbol;
    uint8 private constant _decimals = 9;

    address constant DEAD = 0x000000000000000000000000000000000000dEaD;
    address constant ZERO = 0x0000000000000000000000000000000000000000;
    address public proofAdmin;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isTxLimitExempt;

    uint256 public launchedAt;

    uint256 public reflectionFee;
    uint256 public lpFee;
    uint256 public devFee;

    uint256 public reflectionFeeOnSell;
    uint256 public lpFeeOnSell;
    uint256 public devFeeOnSell;

    uint256 public totalFee;
    uint256 public totalFeeIfSelling;

    uint256 private txnCurrentTaxFee = 0;
    uint256 private txnCurrentReflectionFee = 0;

    uint256 public revenueFee = 2;

    IUniswapV2Router02 public router;
    address public pair;
    address public factory;
    address public tokenOwner;
    address payable public devWallet;

    bool public inSwapAndLiquify;
    bool public swapAndLiquifyEnabled = true;
    bool public tradingStatus = true;

    mapping(address => bool) private bots;

    uint256 public _maxTxAmount;

    constructor() {
        factory = msg.sender;
    }

    modifier lockTheSwap() {
        inSwapAndLiquify = true;
        _;
        inSwapAndLiquify = false;
    }

    modifier onlyProofAdmin() {
        require(
            proofAdmin == _msgSender(),
            "Ownable: caller is not the proofAdmin"
        );
        _;
    }

    modifier onlyOwner() {
        require(tokenOwner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    modifier onlyFactory() {
        require(factory == _msgSender(), "Ownable: caller is not the factory");
        _;
    }

    function setBasicData(
        BaseData memory _baseData,
        ProofReflectionFactoryFees.allFees memory fees
    ) external onlyFactory {
        _name = _baseData.tokenName;
        _symbol = _baseData.tokenSymbol;
        _tTotal += _baseData.initialSupply;
        _rTotal = (MAX - (MAX % _tTotal));
        swapThreshold = (_baseData.initialSupply * 5) / 4000;

        require(
            _baseData.whitelistEndTime > block.timestamp,
            "invalid whitelistEndTime"
        );
        //Initial supply
        require(_baseData.percentToLP >= 70, "low lp percent");
        uint256 forLP = (_baseData.initialSupply * _baseData.percentToLP) / 100; //95%
        uint256 forOwner = _baseData.initialSupply - forLP; //5%

        _maxTxAmount = (_baseData.initialSupply * 1) / 100;

        router = IUniswapV2Router02(_baseData.routerAddress);
        pair = IUniswapV2Factory(router.factory()).createPair(
            router.WETH(),
            address(this)
        );

        _allowances[address(this)][address(router)] = MAX;

        isFeeExempt[address(this)] = true;
        isFeeExempt[factory] = true;

        whitelists.add(address(this));
        whitelists.add(pair);
        whitelists.add(factory);
        whitelists.add(_baseData.owner);
        whitelists.add(_baseData.initialProofAdmin);
        whitelists.add(address(router));
        _addWhitelist(_baseData.whitelists);

        isTxLimitExempt[address(this)] = true;
        isTxLimitExempt[_baseData.owner] = true;
        isTxLimitExempt[pair] = true;
        isTxLimitExempt[factory] = true;
        isTxLimitExempt[DEAD] = true;
        isTxLimitExempt[ZERO] = true;

        whitelistEndTime = _baseData.whitelistEndTime;
        reflectionFee = fees.reflectionFee;
        lpFee = fees.lpFee;
        devFee = fees.devFee;

        reflectionFeeOnSell = fees.reflectionFeeOnSell;
        lpFeeOnSell = fees.lpFeeOnSell;
        devFeeOnSell = fees.devFeeOnSell;

        totalFee = devFee + lpFee + reflectionFee + revenueFee;	
        totalFeeIfSelling = devFeeOnSell + lpFeeOnSell + reflectionFeeOnSell + revenueFee;

        require(totalFee <= 12, "Too high fee");
        require(totalFeeIfSelling <= 17, "Too high fee");

        tokenOwner = _baseData.owner;
        devWallet = payable(_baseData.devWallet);
        proofAdmin = _baseData.initialProofAdmin;

        _rOwned[address(0)] += _rTotal;

        _transferStandard(address(0), _msgSender(), forLP);
        _transferStandard(address(0), _baseData.owner, forOwner);

        emit Transfer(address(0), _msgSender(), forLP);
        emit Transfer(address(0), _baseData.owner, forOwner);
    }

    //proofAdmin functions
    function updateProofAdmin(address newAdmin) public virtual onlyProofAdmin {
        proofAdmin = newAdmin;
        whitelists.add(newAdmin);
    }

    function updateWhitelistEndTime(
        uint256 _whitelistEndTime
    ) external onlyProofAdmin {
        require(
            block.timestamp < _whitelistEndTime,
            "invalid whitelistEndTime"
        );
        whitelistEndTime = _whitelistEndTime;
    }

    function setBots(address[] memory bots_) external onlyProofAdmin {
        for (uint256 i = 0; i < bots_.length; i++) {
            bots[bots_[i]] = true;
        }
    }

    //Factory functions
    function swapTradingStatus() public onlyFactory {
        tradingStatus = !tradingStatus;
    }

    function setLaunchedAt() public onlyFactory {
        require(launchedAt == 0, "already launched");
        launchedAt = block.timestamp;
    }

    function cancelToken() public onlyFactory {
        isFeeExempt[address(router)] = true;
        isTxLimitExempt[address(router)] = true;
        isTxLimitExempt[tokenOwner] = true;
        tradingStatus = true;
        swapAndLiquifyEnabled = false;
    }

    function changeFees(
        uint256 initialReflectionFee,
        uint256 initialReflectionFeeOnSell,
        uint256 initialLpFee,
        uint256 initialLpFeeOnSell,
        uint256 initialDevFee,
        uint256 initialDevFeeOnSell
    ) external onlyOwner {
        reflectionFee = initialReflectionFee;
        lpFee = initialLpFee;
        devFee = initialDevFee;

        reflectionFeeOnSell = initialReflectionFeeOnSell;
        lpFeeOnSell = initialLpFeeOnSell;
        devFeeOnSell = initialDevFeeOnSell;

        totalFee = devFee + lpFee + reflectionFee + revenueFee;	
        totalFeeIfSelling = devFeeOnSell + lpFeeOnSell + reflectionFeeOnSell + revenueFee;

        require(totalFee <= 12, "Too high fee");
        require(totalFeeIfSelling <= 17, "Too high fee");
    }

    function reduceProofFee() external onlyOwner {
        require(revenueFee == 2, "!already reduced");
        require(launchedAt != 0, "!launched");
        require(block.timestamp >= launchedAt + 72 hours, "too soon");

        revenueFee = 1;
        totalFee = devFee + lpFee + reflectionFee + revenueFee;	
        totalFeeIfSelling = devFeeOnSell + lpFeeOnSell + reflectionFeeOnSell + revenueFee;
    }

    function adjustProofFee(uint256 _proofFee) external onlyProofAdmin {
        require(launchedAt != 0, "!launched");
        if (block.timestamp >= launchedAt + 72 hours) {
            require(_proofFee <= 1);
            revenueFee = _proofFee;
            totalFee = devFee + lpFee + reflectionFee + revenueFee;
            totalFeeIfSelling = devFeeOnSell + lpFeeOnSell + reflectionFeeOnSell + revenueFee;
        } else {
            require(_proofFee <= 2);
            revenueFee = _proofFee;
            totalFee = devFee + lpFee + reflectionFee + revenueFee;
            totalFeeIfSelling = devFeeOnSell + lpFeeOnSell + reflectionFeeOnSell + revenueFee;
        }
    }

    function changeTxLimit(uint256 newLimit) external onlyOwner {
        require(launchedAt != 0, "!launched");
        require(newLimit >= (_tTotal * 5) / 1000, "Min 0.5% limit");	
        require(newLimit <= (_tTotal * 3) / 100, "Max 3% limit");
        _maxTxAmount = newLimit;
    }

    function changeIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function changeIsTxLimitExempt(
        address holder,
        bool exempt
    ) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setDevWallet(address payable newDevWallet) external onlyOwner {
        devWallet = payable(newDevWallet);
    }

    function setOwnerWallet(address payable newOwnerWallet) external onlyOwner {	
        tokenOwner = newOwnerWallet;	
    }

    function changeSwapBackSettings(
        bool enableSwapBack,
        uint256 newSwapBackLimit
    ) external onlyOwner {
        swapAndLiquifyEnabled = enableSwapBack;
        swapThreshold = newSwapBackLimit;
    }

    function delBot(address notbot) external {
        address sender = _msgSender();
        require(
            sender == proofAdmin || sender == tokenOwner,
            "Owanble: caller doesn't have permission"
        );
        bots[notbot] = false;
    }

    function name() public view override returns (string memory) {
        return _name;
    }

    function symbol() public view override returns (string memory) {
        return _symbol;
    }

    function decimals() public pure override returns (uint8) {
        return _decimals;
    }

    function approve(
        address spender,
        uint256 amount
    ) public override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    function getWhitelists() external view returns (address[] memory) {
        return whitelists.values();
    }

    function totalSupply() public view override returns (uint256) {
        return _tTotal;
    }

    function balanceOf(
        address account
    ) public view virtual override returns (uint256) {
        return tokenFromReflection(_rOwned[account]);
    }

    function transfer(
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    function allowance(
        address owner,
        address spender
    ) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function tokenFromReflection(
        uint256 rAmount
    ) private view returns (uint256) {
        require(
            rAmount <= _rTotal,
            "Amount must be less than total reflections"
        );
        uint256 currentRate = _getRate();
        return rAmount / currentRate;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        _transfer(sender, recipient, amount);
        require(
            _allowances[sender][_msgSender()] >= amount,
            "ERC20: transfer amount exceeds allowance"
        );
        _approve(
            sender,
            _msgSender(),
            _allowances[sender][_msgSender()] - amount
        );
        return true;
    }

    function increaseAllowance(
        address spender,
        uint256 addedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
        return true;
    }

    function decreaseAllowance(
        address spender,
        uint256 subtractedValue
    ) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = _allowances[owner][spender];
        require(
            currentAllowance >= subtractedValue,
            "ERC20: decreased allowance below zero"
        );
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) private {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(
            amount <= _maxTxAmount ||
                (isTxLimitExempt[sender] && isTxLimitExempt[recipient]),
            "Max TX Amount"
        );
        require(
            block.timestamp > whitelistEndTime ||
                (whitelists.contains(sender) && whitelists.contains(recipient)),
            "only whitelist"
        );

        if (
            sender != tokenOwner &&
            recipient != tokenOwner &&
            !isTxLimitExempt[recipient]
        ) {
            require(!bots[sender] && !bots[recipient]);

            if (
                sender == pair &&
                recipient != address(router) &&
                !isFeeExempt[recipient]
            ) {
                require(tradingStatus, "!trading");
            }
        }

        if (
            !inSwapAndLiquify &&
            sender != pair &&
            tradingStatus &&
            swapAndLiquifyEnabled &&
            balanceOf(address(this)) >= swapThreshold
        ) {
            swapTokensForEth();
        }

        if (isFeeExempt[sender] || isFeeExempt[recipient]) {
            txnCurrentTaxFee = 0;
            txnCurrentReflectionFee = 0;
        } else if (recipient == pair) {
            txnCurrentTaxFee = totalFeeIfSelling;
            txnCurrentReflectionFee = reflectionFeeOnSell;
        } else if (sender == pair) {
            txnCurrentTaxFee = totalFee;
            txnCurrentReflectionFee = reflectionFee;
        } else {
            txnCurrentTaxFee = 0;
            txnCurrentReflectionFee = 0;
        }

        _transferStandard(sender, recipient, amount);
    }

    function _approve(address owner, address spender, uint256 amount) private {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _takeDev(uint256 tDev) private {
        uint256 currentRate = _getRate();
        uint256 rDev = tDev * currentRate;
        _rOwned[address(this)] = _rOwned[address(this)] + rDev;
    }

    function _reflectFee(uint256 rFee, uint256 tFee) private {
        _rTotal = _rTotal - rFee;
        _tFeeTotal = _tFeeTotal + tFee;
    }

    function _transferStandard(
        address sender,
        address recipient,
        uint256 tAmount
    ) private {
        (
            uint256 rAmount,
            uint256 rTransferAmount,
            uint256 rFee,
            uint256 tTransferAmount,
            uint256 tFee,
            uint256 tDev
        ) = _getValues(tAmount);
        _rOwned[sender] = _rOwned[sender] - rAmount;
        _rOwned[recipient] = _rOwned[recipient] + rTransferAmount;
        _takeDev(tDev);
        _reflectFee(rFee, tFee);
        emit Transfer(sender, recipient, tTransferAmount);
    }

    function _getValues(
        uint256 tAmount
    )
        private
        view
        returns (uint256, uint256, uint256, uint256, uint256, uint256)
    {
        (uint256 tTransferAmount, uint256 tFee, uint256 tDev) = _getTValues(
            tAmount,
            txnCurrentReflectionFee,
            txnCurrentTaxFee
        );
        uint256 currentRate = _getRate();
        (uint256 rAmount, uint256 rTransferAmount, uint256 rFee) = _getRValues(
            tAmount,
            tFee,
            tDev,
            currentRate
        );
        return (rAmount, rTransferAmount, rFee, tTransferAmount, tFee, tDev);
    }

    function _getTValues(
        uint256 tAmount,
        uint256 _taxFee,
        uint256 _devFee
    ) private pure returns (uint256, uint256, uint256) {
        uint256 tFee = (tAmount * _taxFee) / 100;
        uint256 tDev = (tAmount * _devFee) / 100;
        uint256 tTransferAmount = tAmount - tFee - tDev;
        return (tTransferAmount, tFee, tDev);
    }

    function _getRate() private view returns (uint256) {
        (uint256 rSupply, uint256 tSupply) = _getCurrentSupply();
        return rSupply / tSupply;
    }

    function _getCurrentSupply() private view returns (uint256, uint256) {
        uint256 rSupply = _rTotal;
        uint256 tSupply = _tTotal;
        if (rSupply < _rTotal / _tTotal) return (_rTotal, _tTotal);
        return (rSupply, tSupply);
    }

    function _getRValues(
        uint256 tAmount,
        uint256 tFee,
        uint256 tDev,
        uint256 currentRate
    ) private pure returns (uint256, uint256, uint256) {
        uint256 rAmount = tAmount * currentRate;
        uint256 rFee = tFee * currentRate;
        uint256 rDev = tDev * currentRate;
        uint256 rTransferAmount = rAmount - rFee - rDev;
        return (rAmount, rTransferAmount, rFee);
    }

    function swapTokensForEth() private lockTheSwap {
        uint256 tokensToLiquify = swapThreshold;

        uint256 amountToLiquify = (tokensToLiquify * lpFee) / totalFee / 2;
        uint256 amountToSwap = tokensToLiquify - amountToLiquify;
        if (amountToSwap == 0) return;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();

        _approve(address(this), address(router), tokensToLiquify);

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountETH = address(this).balance;
        uint256 amountEthLiquidity = (amountETH * lpFee) / totalFee / 2;

        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountEthLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                0x000000000000000000000000000000000000dEaD,
                block.timestamp
            );
        }

        uint256 amountETHafterLP = address(this).balance;

        uint256 devBalance = (amountETHafterLP * devFee) / totalFee;
        uint256 revenueBalance = (amountETHafterLP * revenueFee) / totalFee;

        if (amountETH > 0) {
            if (revenueBalance > 0) {
                uint256 revenueSplit = revenueBalance / 2;
                (bool sent, ) = payable(IFACTORY(factory).proofRevenueAddress()).call{value: revenueSplit}("");
                require(sent);
                (bool sent1, ) = payable(IFACTORY(factory).proofRewardPoolAddress()).call{value: revenueSplit}("");
                require(sent1);
            }
            if (devBalance > 0) {
                (bool sent, ) = devWallet.call{value: devBalance}("");
                require(sent, "ETH transfer failed");
            }
        }
    }

    function _addWhitelist(address[] memory _whitelists) internal {
        uint256 length = _whitelists.length;
        for (uint256 i = 0; i < length; i++) {
            address whitelist = _whitelists[i];
            if (!whitelists.contains(whitelist)) {
                whitelists.add(whitelist);
            }
        }
    }

    function addMoreToWhitelist(WhitelistAdd_ memory _WhitelistAdd) external onlyFactory {
        _addWhitelist(_WhitelistAdd.whitelists);
    }

    receive() external payable {}
}