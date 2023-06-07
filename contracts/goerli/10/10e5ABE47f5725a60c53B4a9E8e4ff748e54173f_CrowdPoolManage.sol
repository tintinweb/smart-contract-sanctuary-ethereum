// SPDX-License-Identifier: UNLICENSED
// @Credits Unicrypt Network 2021

// This contract generates CrowdPool01 contracts and registers them in the CrowdPoolFactory.
// Ideally you should not interact with this contract directly, and use the Octofi crowdpool app instead so warnings can be shown where necessary.

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../TransferHelper.sol";
import "../CrowdPoolSettings.sol";
import "./SharedStructs.sol";
import "./CrowdPoolLockForwarder.sol";
import "./CrowdPoolFactory.sol";
import "./CrowdPool.sol";

contract CrowdPoolManage {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private crowdpools;

    CrowdPoolFactory internal crowdpoolFactory;

    address public crowdpool_lock_forward_addr;
    address public crowdpool_setting_addr;
    CrowdPoolLockForwarder _lock;

    address private uniswap_factory_address;
    address private uniswap_pair_address;

    address private weth_address;

    address payable owner;

    SharedStructs.CrowdPoolInfo crowdpool_info;
    SharedStructs.CrowdPoolLink crowdpoollink;

    CrowdPoolSettings public settings;

    event OwnerWithdrawSuccess(uint256 value);
    event CreateCrowdpoolSucess(address, address);

    constructor(
        address payable _owner,
        address lock_addr,
        address uniswapfactory_addr,
        address uniswaprouter_Addr,
        address weth_addr,
        CrowdPoolFactory _crowdpoolFactory
    ) {
        owner = _owner;

        uniswap_factory_address = uniswapfactory_addr;
        weth_address = weth_addr;

        _lock = new CrowdPoolLockForwarder(
            address(this),
            lock_addr,
            uniswapfactory_addr,
            uniswaprouter_Addr,
            weth_addr
        );
        crowdpool_lock_forward_addr = address(_lock);

        CrowdPoolSettings _setting;

        _setting = new CrowdPoolSettings(address(this), _owner, lock_addr);

        _setting.init(owner, 0.01 ether, owner, 10, owner, 10, owner, 10);

        crowdpool_setting_addr = address(_setting);

        settings = CrowdPoolSettings(crowdpool_setting_addr);

        crowdpoolFactory = _crowdpoolFactory;
    }

    function ownerWithdraw() public {
        require(
            msg.sender == settings.getCreateFeeAddress(),
            "Only creater can withdraw"
        );
        address payable reciver = payable(settings.getCreateFeeAddress());
        reciver.transfer(address(this).balance);
        // owner.transfer(address(this).balance);
        emit OwnerWithdrawSuccess(address(this).balance);
    }

    /**
     * @notice Creates a new CrowdPool contract and registers it in the CrowdPoolFactory.sol.
     */

    function calculateAmountRequired(
        uint256 _amount,
        uint256 _tokenPrice,
        uint256 _listingRate,
        uint256 _liquidityPercent,
        uint256 _tokenFee
    ) public pure returns (uint256) {
        uint256 tokenamount = (_amount * _tokenPrice) / (10**18);
        uint256 TokenFee = (((_amount * _tokenFee) / 100) / 10**18) *
            _tokenPrice;
        uint256 liqudityrateamount = (_amount * _listingRate) / (10**18);
        uint256 liquiditytoken = (liqudityrateamount * _liquidityPercent) / 100;
        uint256 tokensRequiredForCrowdPool = tokenamount +
            liquiditytoken +
            TokenFee;
        return tokensRequiredForCrowdPool;
    }

    function createCrowdPool(
        SharedStructs.CrowdPoolInfo memory _crowdpool_info,
        SharedStructs.CrowdPoolLink memory _crowdpoollink
    ) public payable {
        crowdpool_info = _crowdpool_info;

        crowdpoollink = _crowdpoollink;

        // if ( (crowdpool_info.crowdpool_end - crowdpool_info.crowdpool_start) < 1 weeks) {
        //     crowdpool_info.crowdpool_end = crowdpool_info.crowdpool_start + 1 weeks;
        // }

        // if ( (crowdpool_info.lock_end - crowdpool_info.lock_start) < 4 weeks) {
        //     crowdpool_info.lock_end = crowdpool_info.lock_start + 4 weeks;
        // }

        // Charge ETH fee for contract creation
        require(
            msg.value >= settings.getCrowdPoolCreateFee() + settings.getLockFee(),
            "Balance is insufficent"
        );

        require(_crowdpool_info.token_rate > 0, "token rate is invalid");
        require(
            _crowdpool_info.raise_min < _crowdpool_info.raise_max,
            "raise min/max in invalid"
        );
        require(
            _crowdpool_info.softcap <= _crowdpool_info.hardcap,
            "softcap/hardcap is invalid"
        );
        require(
            _crowdpool_info.liqudity_percent >= 30 &&
                _crowdpool_info.liqudity_percent <= 100,
            "Liqudity percent is invalid"
        );
        require(_crowdpool_info.listing_rate > 0, "Listing rate is invalid");

        //require(
          //  (_crowdpool_info.crowdpool_end - _crowdpool_info.crowdpool_start) > 0,
            //"CrowdPool start/end time is invalid"
        //);
        //require(
        //    (_crowdpool_info.lock_end - _crowdpool_info.lock_start) >= 4 weeks,
        //    "Lock end is invalid"
        //);

        // Calculate required token amount
        uint256 tokensRequiredForCrowdPool = calculateAmountRequired(
            _crowdpool_info.hardcap,
            _crowdpool_info.token_rate,
            _crowdpool_info.listing_rate,
            _crowdpool_info.liqudity_percent,
            settings.getSoldFee()
        );

        // Create New crowdpool
        CrowdPoolV1 newCrowdPool = crowdpoolFactory.deploy{
            value: settings.getLockFee()
        }(
            address(this),
            weth_address,
            crowdpool_setting_addr,
            crowdpool_lock_forward_addr
        );

        // newCrowdPool.delegatecall(bytes4(sha3("destroy()")));

        if (address(newCrowdPool) == address(0)) {
            // newCrowdPool.destroy();
            require(false, "Create crowdpool Failed");
        }

        TransferHelper.safeTransferFrom(
            address(_crowdpool_info.sale_token),
            address(msg.sender),
            address(newCrowdPool),
            tokensRequiredForCrowdPool
        );

        newCrowdPool.init_private(_crowdpool_info);

        newCrowdPool.init_link(_crowdpoollink);

        newCrowdPool.init_fee();

        crowdpools.add(address(newCrowdPool));

        emit CreateCrowdpoolSucess(address(newCrowdPool), address(msg.sender));
    }

    function getCount() external view returns (uint256) {
        return crowdpools.length();
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getCrowdPoolAt(uint256 index) external view returns (address) {
        return crowdpools.at(index);
    }

    function IsRegistered(address crowdpool_addr) external view returns (bool) {
        return crowdpools.contains(crowdpool_addr);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/EnumerableSet.sol)
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

// SPDX-License-Identifier: UNLICENSED
// @Credits Unicrypt Network 2021

// Settings to initialize crowdpool contracts and edit fees.

pragma solidity ^0.8.0;

interface ILpLocker {
    function price() external pure returns (uint256);
}

contract CrowdPoolSettings {
    address private owner;
    address private manage;
    ILpLocker locker;

    struct SettingsInfo {
        uint256 raised_fee; // divided by 100
        uint256 sold_fee; // divided by 100
        uint256 referral_fee; // divided by 100
        uint256 crowdpool_create_fee; // divided by 100
        address payable raise_fee_address;
        address payable sole_fee_address;
        address payable referral_fee_address; // if this is not address(0), there is a valid referral
        address payable create_fee_address; // if this is not address(0), there is a valid referral
    }

    SettingsInfo public info;

    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    modifier onlyManager() {
        require(manage == msg.sender, "Ownable: caller is not the manager");
        _;
    }

    event setRaiseFeeAddrSuccess(address indexed addr);
    event setRaisedFeeSuccess(uint256 num);
    event setSoleFeeAddrSuccess(address indexed addr);
    event setSoldFeeSuccess(uint256 num);
    event setReferralFeeAddrSuccess(address addr);
    event setReferralFeeSuccess(uint256 num);
    event setCreateFeeAddrSuccess(address addr);
    event setCreateFeeSuccess(uint256 num);
    event setFeeInfoSuccess(uint256);

    constructor(
        address _manage,
        address _owner,
        address lockaddr
    ) public {
        owner = _owner;
        manage = _manage;
        locker = ILpLocker(lockaddr);
    }

    function init(
        address payable _crowdpool_create_fee_addr,
        uint256 _crowdpool_create_fee,
        address payable _raise_fee_addr,
        uint256 _raised_fee,
        address payable _sole_fee_address,
        uint256 _sold_fee,
        address payable _referral_fee_address,
        uint256 _referral_fee
    ) public onlyManager {
        info.crowdpool_create_fee = _crowdpool_create_fee;
        info.raise_fee_address = _raise_fee_addr;
        info.raised_fee = _raised_fee;
        info.sole_fee_address = _sole_fee_address;
        info.sold_fee = _sold_fee;
        info.referral_fee_address = _referral_fee_address;
        info.referral_fee = _referral_fee;
        info.create_fee_address = _crowdpool_create_fee_addr;
    }

    function getRaisedFeeAddress()
        external
        view
        returns (address payable _raise_fee_addr)
    {
        return info.raise_fee_address;
    }

    function setRaisedFeeAddress(address payable _raised_fee_addr)
        external
        onlyOwner
    {
        info.raise_fee_address = _raised_fee_addr;
        emit setRaiseFeeAddrSuccess(info.raise_fee_address);
    }

    function getRasiedFee() external view returns (uint256) {
        return info.raised_fee;
    }

    function setRaisedFee(uint256 _raised_fee) external onlyOwner {
        info.raised_fee = _raised_fee;
        emit setRaisedFeeSuccess(info.raised_fee);
    }

    function getSoleFeeAddress()
        external
        view
        returns (address payable _sole_fee_address)
    {
        return info.sole_fee_address;
    }

    function setSoleFeeAddress(address payable _sole_fee_address)
        external
        onlyOwner
    {
        info.sole_fee_address = _sole_fee_address;
        emit setSoleFeeAddrSuccess(info.sole_fee_address);
    }

    function getSoldFee() external view returns (uint256) {
        return info.sold_fee;
    }

    function setSoldFee(uint256 _sold_fee) external onlyOwner {
        info.sold_fee = _sold_fee;
        emit setSoldFeeSuccess(info.sold_fee);
    }

    function getReferralFeeAddress() external view returns (address payable) {
        return info.referral_fee_address;
    }

    function setReferralFeeAddress(address payable _referral_fee_address)
        external
        onlyOwner
    {
        info.sole_fee_address = _referral_fee_address;
        emit setReferralFeeAddrSuccess(info.referral_fee_address);
    }

    function getRefferralFee() external view returns (uint256) {
        return info.referral_fee;
    }

    function setRefferralFee(uint256 _referral_fee) external onlyOwner {
        info.referral_fee = _referral_fee;
        emit setReferralFeeSuccess(info.referral_fee);
    }

    function getLockFee() external view returns (uint256) {
        return locker.price();
    }

    function getCrowdPoolCreateFee() external view returns (uint256) {
        return info.crowdpool_create_fee;
    }

    function setSetCrowdPoolCreateFee(uint256 _crowdpool_create_fee)
        external
        onlyOwner
    {
        info.crowdpool_create_fee = _crowdpool_create_fee;
        emit setCreateFeeSuccess(info.crowdpool_create_fee);
    }

    function getCreateFeeAddress() external view returns (address payable) {
        return info.create_fee_address;
    }

    function setCreateFeeAddress(address payable _create_fee_address)
        external
        onlyOwner
    {
        info.create_fee_address = _create_fee_address;
        emit setReferralFeeAddrSuccess(info.create_fee_address);
    }

    function setFeeInfo(
        address payable _create_address,
        address payable _raise_address,
        address payable _sold_address,
        uint256 _create_fee,
        uint256 _raise_fee,
        uint256 _sold_fee
    ) external onlyOwner {
        info.create_fee_address = _create_address;
        info.raise_fee_address = _raise_address;
        info.sole_fee_address = _sold_address;

        info.crowdpool_create_fee = _create_fee;
        info.raised_fee = _raise_fee;
        info.sold_fee = _sold_fee;

        emit setFeeInfoSuccess(1);
    }
}

// SPDX-License-Identifier: UNLICENSED
// @Credits Defi Site Network 2021

// CrowdPool contract. Version 1

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../../interfaces/IWETH.sol";
import "../TransferHelper.sol";
import "./SharedStructs.sol";
import "./CrowdPoolLockForwarder.sol";
import "../CrowdPoolSettings.sol";

contract CrowdPoolV1 is ReentrancyGuard {
    /// @notice CrowdPool Contract Version, used to choose the correct ABI to decode the contract
    //   uint256 public contract_version = 1;

    struct CrowdPoolFeeInfo {
        uint256 raised_fee; // divided by 100
        uint256 sold_fee; // divided by 100
        uint256 referral_fee; // divided by 100
        address payable raise_fee_address;
        address payable sole_fee_address;
        address payable referral_fee_address; // if this is not address(0), there is a valid referral
    }

    struct CrowdPoolStatus {
        bool lp_generation_complete; // final flag required to end a crowdpool and enable withdrawls
        bool force_failed; // set this flag to force fail the crowdpool
        uint256 raised_amount; // total base currency raised (usually ETH)
        uint256 sold_amount; // total crowdpool tokens sold
        uint256 token_withdraw; // total tokens withdrawn post successful crowdpool
        uint256 base_withdraw; // total base tokens withdrawn on crowdpool failure
        uint256 num_buyers; // number of unique participants
    }

    struct BuyerInfo {
        uint256 base; // total base token (usually ETH) deposited by user, can be withdrawn on crowdpool failure
        uint256 sale; // num crowdpool tokens a user is owed, can be withdrawn on crowdpool success
    }

    struct TokenInfo {
        string name;
        string symbol;
        uint256 totalsupply;
        uint256 decimal;
    }

    SharedStructs.CrowdPoolInfo public crowdpool_info;
    CrowdPoolStatus public status;
    SharedStructs.CrowdPoolLink public link;
    CrowdPoolFeeInfo public crowdpool_fee_info;
    TokenInfo public tokeninfo;

    address manage_addr;

    // IUniswapV2Factory public uniswapfactory;
    IWETH private WETH;
    CrowdPoolSettings public crowdpool_setting;
    CrowdPoolLockForwarder public crowdpool_lock_forwarder;

    mapping(address => BuyerInfo) public buyers;

    event UserDepsitedSuccess(address, uint256);
    event UserWithdrawSuccess(uint256);
    event UserWithdrawTokensSuccess(uint256);
    event AddLiquidtySuccess(uint256);

    constructor(
        address manage,
        address wethfact,
        address setting,
        address lockaddr
    ) payable {
        crowdpool_setting = CrowdPoolSettings(setting);

        require(
            msg.value >= crowdpool_setting.getLockFee(),
            "Balance is insufficent"
        );

        manage_addr = manage;

        // uniswapfactory = IUniswapV2Factory(uniswapfact);
        WETH = IWETH(wethfact);

        crowdpool_lock_forwarder = CrowdPoolLockForwarder(lockaddr);
    }

    function init_private(SharedStructs.CrowdPoolInfo memory _crowdpool_info)
        external
    {
        require(msg.sender == manage_addr, "Only manage address is available");

        crowdpool_info = _crowdpool_info;

        //Set token token info
        tokeninfo.name = IERC20Metadata(_crowdpool_info.sale_token).name();
        tokeninfo.symbol = IERC20Metadata(_crowdpool_info.sale_token).symbol();
        tokeninfo.decimal = IERC20Metadata(_crowdpool_info.sale_token).decimals();
        tokeninfo.totalsupply = IERC20Metadata(_crowdpool_info.sale_token)
            .totalSupply();
    }

    function init_link(SharedStructs.CrowdPoolLink memory _link) external {
        require(msg.sender == manage_addr, "Only manage address is available");

        link = _link;
    }

    function init_fee() external {
        require(msg.sender == manage_addr, "Only manage address is available");

        crowdpool_fee_info.raised_fee = crowdpool_setting.getRasiedFee(); // divided by 100
        crowdpool_fee_info.sold_fee = crowdpool_setting.getSoldFee(); // divided by 100
        crowdpool_fee_info.referral_fee = crowdpool_setting.getRefferralFee(); // divided by 100
        crowdpool_fee_info.raise_fee_address = crowdpool_setting
            .getRaisedFeeAddress();
        crowdpool_fee_info.sole_fee_address = crowdpool_setting.getSoleFeeAddress();
        crowdpool_fee_info.referral_fee_address = crowdpool_setting
            .getReferralFeeAddress(); // if this is not address(0), there is a valid referral
    }

    modifier onlyCrowdPoolOwner() {
        require(crowdpool_info.crowdpool_owner == msg.sender, "NOT CROWDPOOL OWNER");
        _;
    }

    //   uint256 tempstatus;

    //   function setTempStatus(uint256 flag) public {
    //       tempstatus = flag;
    //   }

    function crowdpoolStatus() public view returns (uint256) {
        // return tempstatus;
        if (status.force_failed) {
            return 3; // FAILED - force fail
        }
        if (
            (block.timestamp > crowdpool_info.crowdpool_end) &&
            (status.raised_amount < crowdpool_info.softcap)
        ) {
            return 3;
        }
        if (status.raised_amount >= crowdpool_info.hardcap) {
            return 2; // SUCCESS - hardcap met
        }
        if (
            (block.timestamp > crowdpool_info.crowdpool_end) &&
            (status.raised_amount >= crowdpool_info.softcap)
        ) {
            return 2; // SUCCESS - preslae end and soft cap reached
        }
        if (
            (block.timestamp >= crowdpool_info.crowdpool_start) &&
            (block.timestamp <= crowdpool_info.crowdpool_end)
        ) {
            return 1; // ACTIVE - deposits enabled
        }
        return 0; // QUED - awaiting start block
    }

    // accepts msg.value for eth or _amount for ERC20 tokens
    function userDeposit() public payable nonReentrant {
        require(crowdpoolStatus() == 1, "NOT ACTIVE"); //
        require(crowdpool_info.raise_min <= msg.value, "balance is insufficent");
        require(crowdpool_info.raise_max >= msg.value, "balance is too much");

        BuyerInfo storage buyer = buyers[msg.sender];

        uint256 amount_in = msg.value;
        uint256 allowance = crowdpool_info.raise_max - buyer.base;
        uint256 remaining = crowdpool_info.hardcap - status.raised_amount;
        allowance = allowance > remaining ? remaining : allowance;
        if (amount_in > allowance) {
            amount_in = allowance;
        }
        uint256 tokensSold = (amount_in * crowdpool_info.token_rate) / (10**18);
        require(tokensSold > 0, "ZERO TOKENS");
        require(
            tokensSold <=
                IERC20(crowdpool_info.sale_token).balanceOf(address(this)),
            "Token reamin error"
        );
        if (buyer.base == 0) {
            status.num_buyers++;
        }
        buyers[msg.sender].base = buyers[msg.sender].base + amount_in;
        buyers[msg.sender].sale = buyers[msg.sender].sale + tokensSold;
        status.raised_amount = status.raised_amount + amount_in;
        status.sold_amount = status.sold_amount + tokensSold;

        // return unused ETH
        if (amount_in < msg.value) {
            payable(msg.sender).transfer(msg.value - amount_in);
        }

        emit UserDepsitedSuccess(msg.sender, msg.value);
    }

    // withdraw crowdpool tokens
    // percentile withdrawls allows fee on transfer or rebasing tokens to still work
    function userWithdrawTokens() public nonReentrant {
        require(status.lp_generation_complete, "AWAITING LP GENERATION");
        BuyerInfo storage buyer = buyers[msg.sender];
        uint256 tokensRemainingDenominator = status.sold_amount -
            status.token_withdraw;
        uint256 tokensOwed = (IERC20(crowdpool_info.sale_token).balanceOf(
            address(this)
        ) * buyer.sale) / tokensRemainingDenominator;
        require(tokensOwed > 0, "NOTHING TO WITHDRAW");
        status.token_withdraw = status.token_withdraw + buyer.sale;
        buyers[msg.sender].sale = 0;
        buyers[msg.sender].base = 0;
        TransferHelper.safeTransfer(
            address(crowdpool_info.sale_token),
            msg.sender,
            tokensOwed
        );

        emit UserWithdrawTokensSuccess(tokensOwed);
    }

    // on crowdpool failure
    // percentile withdrawls allows fee on transfer or rebasing tokens to still work
    function userWithdrawBaseTokens() public nonReentrant {
        require(crowdpoolStatus() == 3, "NOT FAILED"); // FAILED

        if (msg.sender == crowdpool_info.crowdpool_owner) {
            ownerWithdrawTokens();
            // return;
        }

        BuyerInfo storage buyer = buyers[msg.sender];
        uint256 baseRemainingDenominator = status.raised_amount -
            status.base_withdraw;
        uint256 remainingBaseBalance = address(this).balance;
        uint256 tokensOwed = (remainingBaseBalance * buyer.base) /
            baseRemainingDenominator;
        require(tokensOwed > 0, "NOTHING TO WITHDRAW");
        status.base_withdraw = status.base_withdraw + buyer.base;
        buyer.base = 0;
        buyer.sale = 0;

        address payable reciver = payable(msg.sender);
        reciver.transfer(tokensOwed);

        emit UserWithdrawSuccess(tokensOwed);
        // TransferHelper.safeTransferBaseToken(address(crowdpool_info.base_token), msg.sender, tokensOwed, false);
    }

    // on crowdpool failure
    // allows the owner to withdraw the tokens they sent for crowdpool & initial liquidity
    function ownerWithdrawTokens() private onlyCrowdPoolOwner {
        require(crowdpoolStatus() == 3, "Only failed status"); // FAILED
        TransferHelper.safeTransfer(
            address(crowdpool_info.sale_token),
            crowdpool_info.crowdpool_owner,
            IERC20(crowdpool_info.sale_token).balanceOf(address(this))
        );

        emit UserWithdrawSuccess(
            IERC20(crowdpool_info.sale_token).balanceOf(address(this))
        );
    }

    // Can be called at any stage before or during the crowdpool to cancel it before it ends.
    // If the pair already exists on uniswap and it contains the crowdpool token as liquidity
    // the final stage of the crowdpool 'addLiquidity()' will fail. This function
    // allows anyone to end the crowdpool prematurely to release funds in such a case.
    function forceFailIfPairExists() public {
        require(!status.lp_generation_complete && !status.force_failed);
        if (
            crowdpool_lock_forwarder.uniswapPairIsInitialised(
                address(crowdpool_info.sale_token),
                address(WETH)
            )
        ) {
            status.force_failed = true;
        }
    }

    // if something goes wrong in LP generation
    // function forceFail () external {
    //     require(msg.sender == OCTOFI_FEE_ADDRESS);
    //     status.force_failed = true;
    // }

    // on crowdpool success, this is the final step to end the crowdpool, lock liquidity and enable withdrawls of the sale token.
    // This function does not use percentile distribution. Rebasing mechanisms, fee on transfers, or any deflationary logic
    // are not taken into account at this stage to ensure stated liquidity is locked and the pool is initialised according to
    // the crowdpool parameters and fixed prices.
    function addLiquidity() public nonReentrant onlyCrowdPoolOwner {
        require(!status.lp_generation_complete, "GENERATION COMPLETE");
        require(crowdpoolStatus() == 2, "NOT SUCCESS"); // SUCCESS
        // Fail the crowdpool if the pair exists and contains crowdpool token liquidity

        if (
            crowdpool_lock_forwarder.uniswapPairIsInitialised(
                address(crowdpool_info.sale_token),
                address(WETH)
            )
        ) {
            status.force_failed = true;
            emit AddLiquidtySuccess(0);
            return;
        }

        // require(!crowdpool_lock_forwarder.uniswapPairIsInitialised(address(crowdpool_info.sale_token), address(WETH)), "Liqudity exist");

        uint256 crowdpool_raisedfee = (status.raised_amount *
            crowdpool_setting.getRasiedFee()) / 100;

        // base token liquidity
        uint256 baseLiquidity = ((status.raised_amount - crowdpool_raisedfee) *
            (crowdpool_info.liqudity_percent)) / 100;

        // WETH.deposit{value : baseLiquidity}();

        // require(WETH.approve(address(crowdpool_lock_forwarder), baseLiquidity), 'approve failed.');

        // TransferHelper.safeApprove(address(crowdpool_info.base_token), address(crowdpool_lock_forwarder), baseLiquidity);

        // sale token liquidity
        uint256 tokenLiquidity = (baseLiquidity * crowdpool_info.listing_rate) /
            (10**18);
        require(tokenLiquidity > 0, "ZERO Tokens");
        TransferHelper.safeApprove(
            address(crowdpool_info.sale_token),
            address(crowdpool_lock_forwarder),
            tokenLiquidity
        );

        crowdpool_lock_forwarder.lockLiquidity{
            value: crowdpool_setting.getLockFee() + baseLiquidity
        }(
            address(crowdpool_info.sale_token),
            baseLiquidity,
            tokenLiquidity,
            crowdpool_info.lock_end,
            crowdpool_info.crowdpool_owner
        );

        uint256 crowdpoolSoldFee = (status.sold_amount *
            crowdpool_setting.getSoldFee()) / 100;

        address payable reciver = payable(
            address(crowdpool_fee_info.raise_fee_address)
        );
        reciver.transfer(crowdpool_raisedfee);

        // TransferHelper.safeTransferBaseToken(address(crowdpool_info.base_token), crowdpool_fee_info.raise_fee_address, crowdpool_raisedfee, false);
        TransferHelper.safeTransfer(
            address(crowdpool_info.sale_token),
            crowdpool_fee_info.sole_fee_address,
            crowdpoolSoldFee
        );

        // burn unsold tokens
        uint256 remainingSBalance = IERC20(crowdpool_info.sale_token).balanceOf(
            address(this)
        );
        if (remainingSBalance > status.sold_amount) {
            uint256 burnAmount = remainingSBalance - status.sold_amount;
            TransferHelper.safeTransfer(
                address(crowdpool_info.sale_token),
                0x000000000000000000000000000000000000dEaD,
                burnAmount
            );
        }

        // send remaining base tokens to crowdpool owner
        uint256 remainingBaseBalance = address(this).balance;

        address payable crowdpool_fee_reciver = payable(
            address(crowdpool_info.crowdpool_owner)
        );
        crowdpool_fee_reciver.transfer(remainingBaseBalance);

        status.lp_generation_complete = true;
        emit AddLiquidtySuccess(1);
    }

    function destroy() public {
        require(status.lp_generation_complete, "lp generation incomplete");
        selfdestruct(crowdpool_info.crowdpool_owner);
    }

    //   function getTokenNmae() public view returns (string memory) {
    //       return crowdpool_info.sale_token.name();
    //   }

    //   function getTokenSymbol() public view returns (string memory) {
    //       return crowdpool_info.sale_token.symbol();
    //   }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./CrowdPool.sol";

contract CrowdPoolFactory {
    function deploy(
        address manage,
        address wethfact,
        address setting,
        address lockaddr
    ) external payable returns (CrowdPoolV1) {
        return
            (new CrowdPoolV1){value: msg.value}(
                manage,
                wethfact,
                setting,
                lockaddr
            );
    }
}

// SPDX-License-Identifier: UNLICENSED
// @Credits Unicrypt Network 2021

/**
    This contract creates the lock on behalf of each crowdpool. This contract will be whitelisted to bypass the flat rate 
    ETH fee. Please do not use the below locking code in your own contracts as the lock will fail without the ETH fee
*/

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./CrowdPoolManage.sol";
import "../../interfaces/IWETH.sol";
import "../../interfaces/IUniswapV2Factory.sol";
import "../../interfaces/IUniswapV2Router02.sol";
import "../../interfaces/IUniswapV2Pair.sol";
import "../../LiquidityLock/LPLock.sol";
import "../TransferHelper.sol";

contract CrowdPoolLockForwarder {
    LPLocker public lplocker;
    IUniswapV2Factory public uniswapfactory;
    IUniswapV2Router02 public uniswaprouter;

    CrowdPoolManage manage;
    IWETH public WETH;

    mapping(address => address) public locked_lp_tokens;
    mapping(address => address) public locked_lp_owner;

    constructor(
        address _manage,
        address lplock_addrress,
        address unifactaddr,
        address unirouter,
        address wethaddr
    ) public {
        lplocker = LPLocker(lplock_addrress);
        uniswapfactory = IUniswapV2Factory(unifactaddr);
        uniswaprouter = IUniswapV2Router02(unirouter);
        WETH = IWETH(wethaddr);
        manage = CrowdPoolManage(_manage);
    }

    /**
        Send in _token0 as the CROWDPOOL token, _token1 as the BASE token (usually WETH) for the check to work. As anyone can create a pair,
        and send WETH to it while a crowdpool is running, but no one should have access to the crowdpool token. If they do and they send it to 
        the pair, scewing the initial liquidity, this function will return true
    */
    function uniswapPairIsInitialised(address _token0, address _token1)
        public
        view
        returns (bool)
    {
        address pairAddress = uniswapfactory.getPair(_token0, _token1);
        if (pairAddress == address(0)) {
            return false;
        }
        uint256 balance = IERC20(_token0).balanceOf(pairAddress);
        if (balance > 0) {
            return true;
        }
        return false;
    }

    // function lockLiquidity (IERC20 _saleToken, uint256 _unlock_date, address payable _withdrawer) payable external {

    //     require(msg.value >= lplocker.price(), 'Balance is insufficient');

    //     address pair = uniswapfactory.getPair(address(WETH), address(_saleToken));

    //     uint256 totalLPTokensMinted = IUniswapV2Pair(pair).balanceOf(address(this));
    //     require(totalLPTokensMinted != 0 , "LP creation failed");

    //     TransferHelper.safeApprove(pair, address(lplocker), totalLPTokensMinted);
    //     uint256 unlock_date = _unlock_date > 9999999999 ? 9999999999 : _unlock_date;

    //     lplocker.lpLock{value:lplocker.price()}(pair, totalLPTokensMinted, unlock_date, _withdrawer );

    //     lptokens[msg.sender] = pair;
    // }

    function lockLiquidity(
        address _saleToken,
        uint256 _baseAmount,
        uint256 _saleAmount,
        uint256 _unlock_date,
        address payable _withdrawer
    ) external payable {
        require(manage.IsRegistered(msg.sender), "CROWDPOOL NOT REGISTERED");
        require(
            msg.value >= lplocker.price() + _baseAmount,
            "Balance is insufficient"
        );

        // if (pair == address(0)) {
        //     uniswapfactory.createPair(address(WETH), address(_saleToken));
        //     pair = uniswapfactory.getPair(address(WETH), address(_saleToken));
        // }

        // require(WETH.transferFrom(msg.sender, address(this), _baseAmount), 'WETH transfer failed.');
        // TransferHelper.safeTransferFrom(address(_baseToken), msg.sender, address(pair), _baseAmount);
        TransferHelper.safeTransferFrom(
            address(_saleToken),
            msg.sender,
            address(this),
            _saleAmount
        );
        // IUniswapV2Pair(pair).mint(address(this));
        // return;
        // require(WETH.approve(address(uniswaprouter), _baseAmount), 'router approve failed.');
        // _saleToken.approve(address(uniswaprouter), _saleAmount);
        TransferHelper.safeApprove(
            address(_saleToken),
            address(uniswaprouter),
            _saleAmount
        );
        // construct token path
        // address[] memory path = new address[](2);
        // path[0] = address(WETH);
        // path[1] = address(_saleToken);

        // IUniswapV2Router02(uniswaprouter).swapExactTokensForTokens(
        //     WETH.balanceOf(address(this)).div(2),
        //     0,
        //     path,
        //     address(this),
        //     block.timestamp + 5 minutes
        // );

        // // calculate balances and add liquidity
        // uint256 wethBalance = WETH.balanceOf(address(this));
        // uint256 balance = _saleToken.balanceOf(address(this));

        // IUniswapV2Router02(uniswaprouter).addLiquidity(
        //     address(_saleToken),
        //     address(WETH),
        //     balance,
        //     wethBalance,
        //     0,
        //     0,
        //     address(this),
        //     block.timestamp + 5 minutes
        // );

        IUniswapV2Router02(address(uniswaprouter)).addLiquidityETH{
            value: _baseAmount
        }(
            address(_saleToken),
            _saleAmount,
            0,
            0,
            payable(address(this)),
            block.timestamp + 5 minutes
        );

        address pair = uniswapfactory.getPair(
            address(WETH),
            address(_saleToken)
        );

        uint256 totalLPTokensMinted = IUniswapV2Pair(pair).balanceOf(
            address(this)
        );
        require(totalLPTokensMinted != 0, "LP creation failed");

        TransferHelper.safeApprove(
            pair,
            address(lplocker),
            totalLPTokensMinted
        );
        uint256 unlock_date = _unlock_date > 9999999999
            ? 9999999999
            : _unlock_date;

        lplocker.lpLock{value: lplocker.price()}(
            pair,
            totalLPTokensMinted,
            unlock_date,
            _withdrawer
        );

        locked_lp_tokens[address(_saleToken)] = pair;
        locked_lp_owner[address(_saleToken)] = _withdrawer;

        payable(_withdrawer).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library SharedStructs {
    struct CrowdPoolInfo {
        address payable crowdpool_owner;
        address sale_token; // sale token
        uint256 token_rate; // 1 base token = ? s_tokens, fixed price
        uint256 raise_min; // maximum base token BUY amount per buyer
        uint256 raise_max; // the amount of crowdpool tokens up for crowdpool
        uint256 hardcap; // Maximum riase amount
        uint256 softcap; //Minimum raise amount
        uint256 liqudity_percent; // divided by 1000
        uint256 listing_rate; // fixed rate at which the token will list on uniswap
        uint256 lock_end; // uniswap lock timestamp -> e.g. 2 weeks
        uint256 lock_start;
        uint256 crowdpool_end; // crowdpool period
        uint256 crowdpool_start; // crowdpool start
    }

    struct CrowdPoolLink {
        string website_link;
        string github_link;
        string twitter_link;
        string reddit_link;
        string telegram_link;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
    helper methods for interacting with ERC20 tokens that do not consistently return true/false
    with the addition of a transfer function to send eth or an erc20 token
*/
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    // sends ETH or an erc20 token
    function safeTransferBaseToken(
        address token,
        address payable to,
        uint256 value,
        bool isERC20
    ) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(0xa9059cbb, to, value)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "TransferHelper: TRANSFER_FAILED"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LPLocker {
    address public owner;
    uint256 public price;
    uint256 public penaltyfee;

    struct holder {
        address holderAddress;
        mapping(address => Token) tokens;
    }

    struct Token {
        uint256 balance;
        address tokenAddress;
        uint256 unlockTime;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only available to the contract owner.");
        _;
    }

    mapping(address => holder) public holders;

    constructor(address _owner, uint256 _price) {
        owner = _owner;
        price = _price;
        penaltyfee = 10; // default value
    }

    event Hold(
        address indexed holder,
        address token,
        uint256 amount,
        uint256 unlockTime
    );

    event PanicWithdraw(
        address indexed holder,
        address token,
        uint256 amount,
        uint256 unlockTime
    );

    event Withdrawal(address indexed holder, address token, uint256 amount);

    event FeesClaimed();

    event SetOwnerSuccess(address owner);

    event SetPriceSuccess(uint256 _price);

    event SetPenaltyFeeSuccess(uint256 _fee);

    event OwnerWithdrawSuccess(uint256 amount);

    function lpLock(
        address token,
        uint256 amount,
        uint256 unlockTime,
        address withdrawer
    ) public payable {
        require(msg.value >= price, "Required price is low");

        holder storage holder0 = holders[withdrawer];
        holder0.holderAddress = withdrawer;

        Token storage lockedToken = holders[withdrawer].tokens[token];

        if (lockedToken.balance > 0) {
            lockedToken.balance += amount;

            if (lockedToken.unlockTime < unlockTime) {
                lockedToken.unlockTime = unlockTime;
            }
        } else {
            holders[withdrawer].tokens[token] = Token(
                amount,
                token,
                unlockTime
            );
        }

        IERC20(token).transferFrom(withdrawer, address(this), amount);

        emit Hold(withdrawer, token, amount, unlockTime);
    }

    function withdraw(address token) public {
        holder storage holder0 = holders[msg.sender];

        require(
            msg.sender == holder0.holderAddress,
            "Only available to the token owner."
        );

        require(
            block.timestamp > holder0.tokens[token].unlockTime,
            "Unlock time not reached yet."
        );

        uint256 amount = holder0.tokens[token].balance;

        holder0.tokens[token].balance = 0;

        IERC20(token).transfer(msg.sender, amount);

        emit Withdrawal(msg.sender, token, amount);
    }

    function panicWithdraw(address token) public {
        holder storage holder0 = holders[msg.sender];

        require(
            msg.sender == holder0.holderAddress,
            "Only available to the token owner."
        );

        uint256 feeAmount = (holder0.tokens[token].balance / 100) * penaltyfee;
        uint256 withdrawalAmount = holder0.tokens[token].balance - feeAmount;

        holder0.tokens[token].balance = 0;

        //Transfers fees to the contract administrator/owner
        // holders[address(owner)].tokens[token].balance = feeAmount;

        // Transfers fees to the token owner
        IERC20(token).transfer(msg.sender, withdrawalAmount);

        // Transfers fees to the contract administrator/owner
        IERC20(token).transfer(owner, feeAmount);

        emit PanicWithdraw(
            msg.sender,
            token,
            withdrawalAmount,
            holder0.tokens[token].unlockTime
        );
    }

    // function claimTokenListFees(address[] memory tokenList) public onlyOwner {

    //     for (uint256 i = 0; i < tokenList.length; i++) {

    //         uint256 amount = holders[owner].tokens[tokenList[i]].balance;

    //         if (amount > 0) {

    //             holders[owner].tokens[tokenList[i]].balance = 0;

    //             IERC20(tokenList[i]).transfer(owner, amount);
    //         }
    //     }
    //     emit FeesClaimed();
    // }

    // function claimTokenFees(address token) public onlyOwner {

    //     uint256 amount = holders[owner].tokens[token].balance;

    //     require(amount > 0, "No fees available for claiming.");

    //     holders[owner].tokens[token].balance = 0;

    //     IERC20(token).transfer(owner, amount);

    //     emit FeesClaimed();
    // }

    function OwnerWithdraw() public onlyOwner {
        uint256 amount = address(this).balance;
        address payable ownerAddress = payable(owner);

        ownerAddress.transfer(amount);

        emit OwnerWithdrawSuccess(amount);
    }

    function getcurtime() public view returns (uint256) {
        return block.timestamp;
    }

    function GetBalance(address token) public view returns (uint256) {
        Token storage lockedToken = holders[msg.sender].tokens[token];
        return lockedToken.balance;
    }

    function SetOwner(address contractowner) public onlyOwner {
        owner = contractowner;
        emit SetOwnerSuccess(owner);
    }

    function SetPrice(uint256 _price) public onlyOwner {
        price = _price;
        emit SetPriceSuccess(price);
    }

    // function GetPrice() public view returns (uint256) {
    //     return price;
    // }

    function SetPenaltyFee(uint256 _penaltyfee) public onlyOwner {
        penaltyfee = _penaltyfee;
        emit SetPenaltyFeeSuccess(penaltyfee);
    }

    // function GetPenaltyFee() public view returns (uint256) {
    //     return penaltyfee;
    // }

    function GetUnlockTime(address token) public view returns (uint256) {
        Token storage lockedToken = holders[msg.sender].tokens[token];
        return lockedToken.unlockTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IUniswapV2Router01.sol";

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IWETH {
    function deposit() external payable;

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address src,
        address dst,
        uint256 wad
    ) external returns (bool);

    function approve(address spender, uint256 value) external returns (bool);

    function balanceOf(address owner) external view returns (uint256);

    function decimals() external view returns (uint256);
}