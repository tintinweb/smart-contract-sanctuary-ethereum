// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./interfaces/IRewardMaster.sol";
import "./interfaces/IRewardTokenSales.sol";
import "./interfaces/IRewardFundProvider.sol";
import "./RewardWhitelist.sol";
import "./RewardTokenSales.sol";

/**
 * @title  RewardMaster
 * @author Astra Developers
 * @notice Main logic contract controlling flow to buy reward token
 */
contract RewardMaster is
    ReentrancyGuardUpgradeable,
    RewardWhitelist,
    IRewardMaster
{
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @notice reward keeper contract
    IRewardFundProvider public rewardVault;

    /// @notice rewardTokenSales contract
    IRewardTokenSales public rewardTokenSales;

    /// @notice reward provider count
    uint256 public rpCount;

    /// @notice Maps Reward Provider ID => RP info
    mapping(uint256 => RPInfo) private _rewardProviders;

    /// @notice Maps Reward Provider ID => is lock?
    mapping(uint256 => bool) public lockProviders;

    /// @notice Maps reward provider owner/operator => their Reward Providers' ID
    mapping(address => EnumerableSetUpgradeable.UintSet)
        private _providersByUser;

    /// @notice Maps Reward Provider ID  => its operators
    mapping(uint256 => EnumerableSetUpgradeable.AddressSet)
        private _rpOperators;

    /**
     * @notice Emits when change reward vault
     * @param rewardVault new reward vault contract
     */
    event RewardVaultChanged(address rewardVault);

    /**
     * @notice Emits when change rewardTokenSales
     * @param rewardTokenSales new rewardTokenSales contract
     */
    event rewardTokenSalesChanged(address rewardTokenSales);

    /**
     * @notice Emits when lock reward providers
     * @param rpIds list of reward provider
     */
    event RewardProviderLocked(uint256[] rpIds);

    /**
     * @notice Emits when unlock reward providers
     * @param rpIds list of reward provider
     */
    event RewardProviderUnlocked(uint256[] rpIds);

    /**
     * @notice Emits when transfer owner of reward provider
     * @param rpId list of reward provider
     * @param currentOwner current owner of reward provider
     * @param newOwner new owner of reward provider
     */
    event TransferRpOwner(
        uint256 indexed rpId,
        address currentOwner,
        address newOwner
    );

    /**
     * @notice Emits when change receiver of reward provider
     * @param rpId list of reward provider
     * @param currentReceiver current receiver of reward provider
     * @param newReceiver new receiver of reward provider
     */
    event RpReceiverChanged(
        uint256 indexed rpId,
        address currentReceiver,
        address newReceiver
    );

    /**
     * @notice Emits when whitelist operator reward provider
     * @param rpId list of reward provider
     * @param operator operator of reward provider
     * @param valid is valid or not
     */
    event WhitelistRpOperator(
        uint256 indexed rpId,
        address operator,
        bool valid
    );

    /**
     * @notice Emits when whitelist many operators reward provider
     * @param rpId list of reward provider
     * @param operators operators of reward provider
     * @param valid is valid or not
     */
    event WhitelistManyRpOperators(
        uint256 indexed rpId,
        address[] operators,
        bool valid
    );

    /* =====================================
    Modifiers 
    ====================================== */

    modifier notZeroAddress(address _wallet) {
        require(
            _wallet != address(0),
            "RewardTokenSales: wallet is address zero"
        );
        _;
    }

    function __RewardMaster_init(
        IRewardFundProvider _rewardVault,
        IRewardTokenSales _rewardTokenSales,
        address[] calldata payments
    ) public initializer {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        __RewardWhitelist_init_unchained(payments);

        rewardVault = _rewardVault;
        rewardTokenSales = _rewardTokenSales;
    }

    /* =====================================
    Modifiers 
    ====================================== */
    /**
     * @dev Reverts if sender is not reward provider owner.
     */
    modifier onlyRpOwner(uint256 rpId) {
        require(
            _rewardProviders[rpId].owner == msg.sender,
            "RewardMaster: caller is not the reward provider owner"
        );
        _;
    }

    /**
     * @dev Reverts if reward provider is locked
     */
    modifier whenNotLocked(uint256 rpId) {
        require(!lockProviders[rpId], "RewardMaster: provider is locked");
        _;
    }

    /* =====================================
    Admin functions 
    ====================================== */
    function setRewardVault(IRewardFundProvider _rewardVault)
        external
        onlyOwner
    {
        rewardVault = _rewardVault;
        emit RewardVaultChanged(address(_rewardVault));
    }

    function setrewardTokenSales(IRewardTokenSales _rewardTokenSales)
        external
        onlyOwner
    {
        rewardTokenSales = _rewardTokenSales;
        emit rewardTokenSalesChanged(address(_rewardTokenSales));
    }

    /// @inheritdoc IRewardMaster
    function lock(uint256[] calldata rpIds) external onlyOwner {
        for (uint256 i = 0; i < rpIds.length; i++) {
            lockProviders[rpIds[i]] = true;
        }

        emit RewardProviderLocked(rpIds);
    }

    /// @inheritdoc IRewardMaster
    function unlock(uint256[] calldata rpIds) external onlyOwner {
        for (uint256 i = 0; i < rpIds.length; i++) {
            lockProviders[rpIds[i]] = false;
        }

        emit RewardProviderUnlocked(rpIds);
    }

    /// @inheritdoc IRewardMaster
    function registerRewardTokenPurchase(
        uint256 rpId,
        uint256 amount,
        uint256 lockPeriod,
        uint256 claimPeriod
    ) external override onlyOwner whenNotLocked(rpId) {
        uint256 purchaseId = rewardTokenSales.buyRewardTokens(
            address(0),
            rpId,
            amount,
            IRewardTokenSales.PriceType.AlreadyPaid,
            IERC20Upgradeable(address(0)),
            lockPeriod,
            claimPeriod
        );

        // claim first time right after buy
        _claimRewardTokens(rpId, purchaseId);
    }

    /* =====================================
    User functions 
    ====================================== */
    /// @inheritdoc IRewardMaster
    function register(
        address _owner,
        string calldata _name,
        address _receiver,
        address[] calldata _operators
    ) external override notZeroAddress(_owner) nonReentrant returns (uint256) {
        // TODO: currently comment this line for testing purpose
        // )
        //     external
        //     override
        //     onlyWhitelistedRP
        //     notZeroAddress(_owner)
        //     nonReentrant
        //     returns (uint256)
        // {
        uint256 rpId = rpCount;
        rpCount++;

        RPInfo storage rp = _rewardProviders[rpId];
        rp.id = rpId;
        rp.name = _name;
        rp.owner = _owner;
        rp.receiver = _receiver;

        _addUserRewardProviders(_owner, rpId);

        _whitelistManyRpOperators(rpId, _operators, true);
        emit WhitelistManyRpOperators(rpId, _operators, true);

        emit RewardProviderAdded(rpId, _name, _owner, _receiver);

        // Prevent user from registering multiple providers
        // TODO: currently comment this line for testing purpose
        // _whitelistRP(msg.sender, false);

        return rpId;
    }

    /**
     * @notice reward provider's owner transfers ownership to other user
     * @param rpId list of reward provider
     * @param newOwner address of new owner
     */
    function transferRpOwnership(uint256 rpId, address newOwner)
        external
        onlyRpOwner(rpId)
    {
        _setRpOwner(rpId, newOwner);

        _removeUserRewardProviders(msg.sender, rpId);
        _addUserRewardProviders(newOwner, rpId);

        emit TransferRpOwner(rpId, msg.sender, newOwner);
    }

    /**
     * @notice reward provider's owner change receiver address
     * @param rpId list of reward provider
     * @param newReceiver address of new receiver
     */
    function changeRpReceiver(uint256 rpId, address newReceiver)
        external
        onlyRpOwner(rpId)
    {
        emit RpReceiverChanged(
            rpId,
            _rewardProviders[rpId].receiver,
            newReceiver
        );

        _rewardProviders[rpId].receiver = newReceiver;
    }

    function whitelistManyRpOperators(
        uint256 rpId,
        address[] calldata operators,
        bool valid
    ) external onlyRpOwner(rpId) {
        _whitelistManyRpOperators(rpId, operators, valid);
        emit WhitelistManyRpOperators(rpId, operators, valid);
    }

    function whitelistRpOperator(
        uint256 rpId,
        address operator,
        bool valid
    ) external onlyRpOwner(rpId) {
        _whitelistRpOperator(rpId, operator, valid);
        emit WhitelistRpOperator(rpId, operator, valid);
    }

    /// @inheritdoc IRewardMaster
    function buyRewardTokens(
        uint256 rpId,
        uint256 amount,
        IRewardTokenSales.PriceType priceType,
        IERC20Upgradeable paymentToken,
        uint256 lockPeriod,
        uint256 claimPeriod
    )
        external
        override
        whenNotLocked(rpId)
        onlyRpOwner(rpId)
        onlyWhitelistedPayment(address(paymentToken))
    {
        require(
            amount <= rewardTokenSupply(),
            "RewardMaster: total supply is smaller than request amount"
        );

        uint256 purchaseId = rewardTokenSales.buyRewardTokens(
            msg.sender,
            rpId,
            amount,
            priceType,
            paymentToken,
            lockPeriod,
            claimPeriod
        );

        // claim first time right after buy
        _claimRewardTokens(rpId, purchaseId);
    }

    function _whitelistManyRpOperators(
        uint256 rpId,
        address[] calldata operators,
        bool valid
    ) internal {
        for (uint256 i = 0; i < operators.length; i++) {
            _whitelistRpOperator(rpId, operators[i], valid);
        }
    }

    function _whitelistRpOperator(
        uint256 rpId,
        address operator,
        bool valid
    ) internal {
        if (valid) {
            require(
                _rpOperators[rpId].add(operator),
                "RewardMaster: operator already exists"
            );
            _addUserRewardProviders(operator, rpId);
        } else {
            require(
                _rpOperators[rpId].remove(operator),
                "RewardMaster: operator not exist"
            );
            _removeUserRewardProviders(operator, rpId);
        }
    }

    function _claimRewardTokens(uint256 rpId, uint256 purchaseId) internal {
        // update reward provider balance
        uint256 amount = rewardTokenSales.claimRewardTokens(rpId, purchaseId);

        // release fund
        rewardVault.releaseFund(_rewardProviders[rpId].receiver, amount);
    }

    /// @inheritdoc IRewardMaster
    function claimRewardTokens(uint256 rpId, uint256 purchaseId)
        external
        override
        whenNotLocked(rpId)
    {
        require(
            isRpClaimerOrStudioOperator(rpId),
            "RewardMaster: caller is not the owner/operator of reward provider or owner/manager of studio"
        );
        return _claimRewardTokens(rpId, purchaseId);
    }

    /// @inheritdoc IRewardMaster
    function claimAll(uint256 rpId) external override whenNotLocked(rpId) {
        require(
            isRpClaimerOrStudioOperator(rpId),
            "RewardMaster: caller is not the owner/operator of reward provider or owner/manager of studio"
        );

        uint256[] memory purchases = rewardTokenSales.getPurchasesByProvider(
            rpId
        );

        for (uint256 i = 0; i < purchases.length; i++) {
            (, bool isClaimed) = rewardTokenSales.getClaimWindowInfo(
                purchases[i]
            );
            if (!isClaimed) {
                _claimRewardTokens(rpId, purchases[i]);
            }
        }
    }

    function _addUserRewardProviders(address user, uint256 rpId) internal {
        _providersByUser[user].add(rpId);
    }

    function _removeUserRewardProviders(address user, uint256 rpId) internal {
        _providersByUser[user].remove(rpId);
    }

    function _setRpOwner(uint256 rpId, address owner)
        internal
        notZeroAddress(owner)
    {
        _rewardProviders[rpId].owner = owner;
    }

    function isRpClaimerOrStudioOperator(uint256 rpId)
        internal
        view
        returns (bool)
    {
        return isRpClaimer(rpId) || isStudioOperator();
    }

    function isRpClaimer(uint256 rpId) internal view returns (bool) {
        return
            msg.sender == _rewardProviders[rpId].owner ||
            _rpOperators[rpId].contains(msg.sender);
    }

    function isStudioOperator() internal view returns (bool) {
        return manager() == msg.sender || owner() == msg.sender;
    }

    /* =====================================
    Getter functions 
    ====================================== */
    function getRewardProviders(uint256 rpId)
        public
        view
        returns (RPInfo memory, address[] memory)
    {
        return (_rewardProviders[rpId], getRewardProviderOperators(rpId));
    }

    function getRewardProviderOperators(uint256 rpId)
        public
        view
        returns (address[] memory)
    {
        return _rpOperators[rpId].values();
    }

    function getUserRewardProviders(address user)
        public
        view
        returns (uint256[] memory)
    {
        return _providersByUser[user].values();
    }

    function rewardTokenSupply() public view returns (uint256) {
        require(
            address(rewardVault).balance >
                rewardTokenSales.totalSold() - rewardTokenSales.totalReleased(),
            "RewardMaster: reward token run out"
        );

        return
            address(rewardVault).balance -
            (rewardTokenSales.totalSold() - rewardTokenSales.totalReleased());
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ReentrancyGuardUpgradeable is Initializable {
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

    function __ReentrancyGuard_init() internal onlyInitializing {
        __ReentrancyGuard_init_unchained();
    }

    function __ReentrancyGuard_init_unchained() internal onlyInitializing {
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
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

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
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSetUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "./IRewardTokenSales.sol";

interface IRewardMaster {
    /**
     * @notice Struct for reward provider information
     * @param rewardProviderId id of reward provider
     * @param name of reward provider
     * @param owner of reward provider
     * @param receiver reward token receiver
     */
    struct RPInfo {
        uint256 id;
        string name;
        address owner;
        address receiver;
    }

    /**
     * @notice Emits when reward provider registered
     * @param rewardProviderId id of reward provider
     * @param name of reward provider
     * @param owner of reward provider
     * @param receiver reward token receiver
     */
    event RewardProviderAdded(
        uint256 indexed rewardProviderId,
        string name,
        address indexed owner,
        address receiver
    );

    /**
     * @notice registers new reward provider information
     * @dev require msg.sender is whitelisted
     * @param _owner reward provider owner
     * @param _name reward provider name
     * @param _receiver reward provider ASA receiver
     * @param _operators list of users can claim reward token on behalf of owner
     * @return rewardProviderId id of new added reward provider
     */
    function register(
        address _owner,
        string calldata _name,
        address _receiver,
        address[] calldata _operators
    ) external returns (uint256 rewardProviderId);

    /**
     * @notice buy reward tokens
     * @param rpId id of reward provider
     * @param amount of reward token
     * @param priceType how to calculate reward token price
     * @param paymentToken token used as payment
     * @param lockPeriod total time to lock reward token
     * @param claimPeriod time between claims
     */
    function buyRewardTokens(
        uint256 rpId,
        uint256 amount,
        IRewardTokenSales.PriceType priceType,
        IERC20Upgradeable paymentToken,
        uint256 lockPeriod,
        uint256 claimPeriod
    ) external;

    /**
     * @notice register a reward token purchase
     * @param rpId id of reward provider
     * @param amount of reward token
     * @param lockPeriod total time to lock reward token
     * @param claimPeriod time between claims
     */
    function registerRewardTokenPurchase(
        uint256 rpId,
        uint256 amount,
        uint256 lockPeriod,
        uint256 claimPeriod
    ) external;

    /**
     * @notice claim reward tokens of a purchase
     * @param rpId id of reward provider
     * @param purchaseId id of purchase
     */
    function claimRewardTokens(uint256 rpId, uint256 purchaseId) external;

    /**
     * @notice claim reward tokens of all purchases
     * @param rpId id of reward provider
     */
    function claimAll(uint256 rpId) external;

    /**
     * @notice lock provider from buying and submitting payment
     * @param rpIds list of provider to lock
     */
    function lock(uint256[] calldata rpIds) external;

    /**
     * @notice unlock provider from buying and submitting payment
     * @param rpIds list of provider to unlock
     */
    function unlock(uint256[] calldata rpIds) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

interface IRewardTokenSales {
    /**
     * @notice mode to calculate reward token price
     */
    enum PriceType {
        // 0 - pay all at first, price is predefined
        FixedPrice,
        // 1 - already paid
        AlreadyPaid
    }

    /**
     * @notice Struct for purchase
     * @param id purchase id
     * @param rpId reward provider id
     * @param amount amount of reward
     * @param priceType how to calculate reward token price
     * @param paymentToken token to pay
     * @param paymentAmount amount of payment token paid
     * @param createdAt purchase create timestamp
     * @param lockPeriod  total locking period
     * @param claimPeriod  time between claim
     * @param totalClaimWindows number of windows provider could claim
     * @param lastClaimWindow claim window of the last claim time
     * @param claimedWindows windows provider already claimed
     */
    struct Purchase {
        uint256 id;
        uint256 rpId;
        uint256 amount;
        PriceType priceType;
        IERC20Upgradeable paymentToken;
        uint256 paymentAmount;
        uint256 createdAt;
        uint256 lockPeriod;
        uint256 claimPeriod;
        uint256 totalClaimWindows;
        uint256 lastClaimWindow;
        mapping(uint256 => bool) claimedWindows;
    }

    /**
     * @notice Emits when reward provider buy reward tokens
     * @param purchaseId id of purchase
     * @param rewardProviderId id of reward provider
     * @param rewardAmount amount of reward tokens
     * @param priceType how to calculate reward token price
     * @param paymentAmount amount of payment token paid
     * @param lockPeriod total time to lock reward token
     * @param claimPeriod time between claims
     */
    event RewardTokenPurchased(
        uint256 indexed purchaseId,
        uint256 indexed rewardProviderId,
        uint256 rewardAmount,
        PriceType priceType,
        uint256 paymentAmount,
        uint256 lockPeriod,
        uint256 claimPeriod
    );

    /**
     * @notice Emits when reward provider claim reward tokens
     * @param purchaseId id of purchase
     * @param rewardProviderId id of reward provider
     * @param claimWindow claim window of claim
     * @param claimAmount amount of reward tokens
     */
    event RewardTokenReleased(
        uint256 indexed purchaseId,
        uint256 indexed rewardProviderId,
        uint256 claimWindow,
        uint256 claimAmount
    );

    /**
     * @notice buy reward tokens
     * @param payer fee payer
     * @param rpId id of reward provider
     * @param amount of reward token
     * @param priceType how to calculate reward token price
     * @param paymentToken token used as payment
     * @param lockPeriod total time to lock reward token
     * @param claimPeriod time between claims
     * @return purchaseId id of new purchase
     */
    function buyRewardTokens(
        address payer,
        uint256 rpId,
        uint256 amount,
        PriceType priceType,
        IERC20Upgradeable paymentToken,
        uint256 lockPeriod,
        uint256 claimPeriod
    ) external returns (uint256 purchaseId);

    /**
     * @notice claim reward tokens
     * @param rpId id of reward provider
     * @param purchaseId id of purchase
     * @return claimAmount amount of claimed reward tokens
     */
    function claimRewardTokens(uint256 rpId, uint256 purchaseId)
        external
        returns (uint256 claimAmount);

    /**
     * @notice return total reward token sold
     */
    function totalSold() external view returns (uint256);

    /**
     * @notice return total reward token released
     */
    function totalReleased() external view returns (uint256);

    /**
     * @notice get all purchases made by a reward provider
     * @param rpId id of reward provider
     */
    function getPurchasesByProvider(uint256 rpId)
        external
        returns (uint256[] memory);

    /**
     * @notice get current claim window information of a purchase
     * @param purchaseId id of purchase
     * @return currentWindow claim window at current time
     * @return isClaimed is currentWindow used
     */
    function getClaimWindowInfo(uint256 purchaseId)
        external
        returns (uint256, bool);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface IRewardFundProvider {
    /**
     * @notice Emits when release fund
     * @param beneficiary reward token receiver
     * @param amount reward token amount
     */
    event FundReleased(address indexed beneficiary, uint256 amount);

    /**
     * @notice send reward tokens to buyer
     * @param beneficiary reward token receiver
     * @param amount reward token amount
     */
    function releaseFund(address beneficiary, uint256 amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "./utilities/ManageableUpgradeable.sol";

/**
 * @title  RewardWhitelist
 * @author Astra Developers
 * @notice Whitelist payment tokens & reward providers
 */
contract RewardWhitelist is ManageableUpgradeable {
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.AddressSet;

    /// @notice list of valid payment tokens
    EnumerableSetUpgradeable.AddressSet private _paymentWhitelist;

    /// @notice List of valid users who can register reward provider
    EnumerableSetUpgradeable.AddressSet private _rpWhitelist;

    /** @notice Emits on whitelist single payment token
     * @param payment Address of payment token
     * @param valid true if whitelist, false if not
     */
    event WhitelistPayment(address payment, bool valid);

    /** @notice Emits on whitelist a list of payment tokens
     * @param payments Addresses of payment tokens
     * @param valid true if whitelist, false if not
     */
    event WhitelistManyPayments(address[] payments, bool valid);

    /** @notice Emits on whitelist single address who can register reward provider
     * @param registerer user who can register new provider
     * @param valid true if whitelist, false if not
     */
    event WhitelistRewardProvider(address registerer, bool valid);

    /** @notice Emits on whitelist many addresses who can register reward provider
     * @param registerers users who can register new provider
     * @param valid true if whitelist, false if not
     */
    event WhitelistManyRewardProviders(address[] registerers, bool valid);

    function __RewardWhitelist_init(address[] calldata payments)
        public
        initializer
    {
        __Ownable_init_unchained();
        __RewardWhitelist_init_unchained(payments);
    }

    function __RewardWhitelist_init_unchained(address[] calldata payments)
        internal
        onlyInitializing
    {
        for (uint256 i = 0; i < payments.length; i++) {
            _paymentWhitelist.add(payments[i]);
        }
    }

    /* =====================================
    Modifiers 
    ====================================== */
    /**
     * @dev Reverts if RP is not whitelisted.
     */
    modifier onlyWhitelistedRP() {
        require(
            _rpWhitelist.contains(msg.sender),
            "RewardWhitelist: caller is not the valid reward provider"
        );
        _;
    }

    /**
     * @dev Reverts if RP is not whitelisted.
     */
    modifier onlyWhitelistedPayment(address payment) {
        require(
            _paymentWhitelist.contains(payment),
            "RewardWhitelist: invalid payment"
        );
        _;
    }

    /* =====================================
    Admin functions 
    ====================================== */
    /**
     * @notice Whitelist single user who can register new provider
     * @param registerer user who can register new provider
     * @param valid true if whitelist, false if not
     */
    function whitelistRP(address registerer, bool valid) external onlyOwner {
        _whitelistRP(registerer, valid);
        emit WhitelistRewardProvider(registerer, valid);
    }

    /**
     * @notice Whitelist list of users who can register new provider
     * @param registerers users who can register new provider
     * @param valid true if whitelist, false if not
     */
    function whitelistManyRPs(address[] calldata registerers, bool valid)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < registerers.length; i++) {
            _whitelistRP(registerers[i], valid);
        }
        emit WhitelistManyRewardProviders(registerers, valid);
    }

    /**
     * @notice whitelist single token to paymentWhitelist.
     * @param payment Address of payment token
     * @param valid true if whitelist, false if not
     */
    function whitelistPayment(address payment, bool valid) external onlyOwner {
        _whitelistPayment(payment, valid);
        emit WhitelistPayment(payment, valid);
    }

    /**
     * @notice Whitelist list of tokens to paymentWhitelist.
     * @param payments Addresses of payment tokens
     * @param valid true if whitelist, false if not
     */
    function whitelistManyPayments(address[] calldata payments, bool valid)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < payments.length; i++) {
            _whitelistPayment(payments[i], valid);
        }
        emit WhitelistManyPayments(payments, valid);
    }

    function _whitelistRP(address registerer, bool valid) internal {
        if (valid) {
            require(
                _rpWhitelist.add(registerer),
                "RewardWhitelist: reward provider already exists"
            );
        } else {
            require(
                _rpWhitelist.remove(registerer),
                "RewardWhitelist: reward provider not exist"
            );
        }
    }

    function _whitelistPayment(address payment, bool valid) internal {
        if (valid) {
            require(
                _paymentWhitelist.add(payment),
                "RewardWhitelist: payment already exists"
            );
        } else {
            require(
                _paymentWhitelist.remove(payment),
                "RewardWhitelist: payment not exist"
            );
        }
    }

    /* =====================================
    Getter functions 
    ====================================== */
    function getPaymentWhitelist() public view returns (address[] memory) {
        return _paymentWhitelist.values();
    }

    function getRewardProviderWhitelist()
        public
        view
        returns (address[] memory)
    {
        return _rpWhitelist.values();
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/structs/EnumerableSetUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/MathUpgradeable.sol";
import "./utilities/ManageableUpgradeable.sol";
import "./interfaces/IRewardTokenSales.sol";
import "./interfaces/ISolarSwapRouter.sol";
import "./interfaces/IERC20Decimals.sol";

/**
 * @title  RewardTokenSales
 * @author Astra Developers
 * @notice Manages rules for buying reward token (ASA)
 */
contract RewardTokenSales is
    IRewardTokenSales,
    ManageableUpgradeable,
    ReentrancyGuardUpgradeable
{
    using MathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using EnumerableSetUpgradeable for EnumerableSetUpgradeable.UintSet;

    uint256 public constant INVERSE_BASIS_POINT = 10000;

    // TODO: change to WASA,USDT - Astra network
    // address public constant WASA = 0xEfd086F56311a6DD26DF0951Cdd215F538689B3a; // WASA - Astra testnet
    // address public constant USDT = 0x41591484aEB5FA3d1759f1cbA369dC8dc1281298; // USDT - Astra testnet

    // address public constant WASA = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2; // WETH - Ethereum mainnet
    // address public constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7; // USDT - Ethereum mainnet

    address public constant WASA = 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6; // WETH - Ethereum goerli
    address public constant USDT = 0xE71AEc04b96196DA1245f0E90BC82DBd0Bc3A0f4; // my USDT - Ethereum goerli

    /// @notice wallet to receive payment when user buy reward token
    address public wallet;

    /// @notice predefined price of reward token - number of stable coin / 1e18 ASA
    uint256 public rewardTokenPrice;

    /// @notice swapRouter used to check price
    ISolarSwapRouter public swapRouter;

    /// @notice maximum amount of reward token a provider could buy
    uint256 public rewardLimitPerProvider;

    /// @notice minimun amount of reward token a provider must buy in one purchase
    uint256 public minPurchaseAmount;

    /// @notice total reward token sold
    uint256 public totalSold;

    /// @notice  total reward token released to buyer
    uint256 public totalReleased;

    /// @notice total purchase
    uint256 public purchaseCount;

    /// @notice reward total locking period
    EnumerableSetUpgradeable.UintSet private lockPeriods;

    /// @notice time between claims
    EnumerableSetUpgradeable.UintSet private claimPeriods;

    /// @notice Maps Reward Provider ID => total ASA purchased
    mapping(uint256 => uint256) public purchasedReward;

    /// @notice Maps Reward Provider ID => total ASA received
    mapping(uint256 => uint256) public receivedReward;

    /// @notice Maps lock time => discount percent
    mapping(uint256 => uint256) public discountPlans;

    /// @notice Maps purchaseId => Purchase
    mapping(uint256 => Purchase) public purchases;

    /// @notice Maps providerId => list of purchaseId
    mapping(uint256 => uint256[]) public purchasesByProvider;

    /**
     * @notice Emits when change wallet
     * @param wallet new address to receive payment
     */
    event WalletChanged(address wallet);

    /**
     * @notice Emits when change reward token price
     * @param rewardTokenPrice new reward token price
     */
    event RewardTokenPriceChanged(uint256 rewardTokenPrice);

    /**
     * @notice Emits when change min purchase amount
     * @param mintAmount new min purchase amount
     */
    event MinPurchaseAmountChanged(uint256 mintAmount);

    /**
     * @notice Emits when change reward limit per provider
     * @param limit new address to receive payment
     */
    event RewardLimitChanged(uint256 limit);

    /**
     * @notice Emits when change swap router
     * @param router new address to receive payment
     */
    event SwapRouterChanged(address router);

    /**
     * @notice Emits when add claim periods
     * @param periods list of claim periods added
     */
    event ClaimPeriodsAdded(uint256[] periods);

    /**
     * @notice Emits when remove claim periods
     * @param periods list of claim periods removed
     */
    event ClaimPeriodsRemoved(uint256[] periods);

    /**
     * @notice Emits when add lock periods
     * @param periods list of lock periods added
     * @param discounts list of discount plans for each periods
     */
    event LockPeriodsAdded(uint256[] periods, uint256[] discounts);

    /**
     * @notice Emits when add lock periods
     * @param periods list of lock periods added
     */
    event LockPeriodsRemoved(uint256[] periods);

    /* =====================================
    Modifiers 
    ====================================== */

    modifier notZeroAddress(address _wallet) {
        require(
            _wallet != address(0),
            "RewardTokenSales: wallet is address zero"
        );
        _;
    }

    function __RewardTokenSales_init(
        address _wallet,
        uint256 _rewardTokenPrice,
        ISolarSwapRouter _swapRouter,
        uint256 _rewardLimitPerProvider,
        uint256 _minPurchaseAmount
    ) public initializer notZeroAddress(_wallet) {
        __Ownable_init_unchained();
        __ReentrancyGuard_init_unchained();
        wallet = _wallet;
        rewardTokenPrice = _rewardTokenPrice;
        swapRouter = _swapRouter;
        rewardLimitPerProvider = _rewardLimitPerProvider;
        minPurchaseAmount = _minPurchaseAmount;
    }

    /* =====================================
    Admin functions 
    ====================================== */
    function setWallet(address _wallet)
        external
        onlyOwner
        notZeroAddress(_wallet)
    {
        wallet = _wallet;
        emit WalletChanged(_wallet);
    }

    function setRewardTokenPrice(uint256 _rewardTokenPrice) external onlyOwner {
        rewardTokenPrice = _rewardTokenPrice;
        emit RewardTokenPriceChanged(_rewardTokenPrice);
    }

    function setMinPurchaseAmount(uint256 _minPurchaseAmount)
        external
        onlyOwner
    {
        minPurchaseAmount = _minPurchaseAmount;
        emit MinPurchaseAmountChanged(_minPurchaseAmount);
    }

    function setRewardLimit(uint256 _limit) external onlyOwner {
        rewardLimitPerProvider = _limit;
        emit RewardLimitChanged(_limit);
    }

    function setSwapRouter(ISolarSwapRouter _swapRouter) external onlyOwner {
        swapRouter = _swapRouter;
        emit SwapRouterChanged(address(_swapRouter));
    }

    function addClaimPeriods(uint256[] calldata periods) external onlyOwner {
        for (uint256 i = 0; i < periods.length; i++) {
            require(
                claimPeriods.add(periods[i]),
                "RewardTokenSales: claim period already exists"
            );
        }

        emit ClaimPeriodsAdded(periods);
    }

    function removeClaimPeriods(uint256[] calldata periods) external onlyOwner {
        for (uint256 i = 0; i < periods.length; i++) {
            require(
                claimPeriods.remove(periods[i]),
                "RewardTokenSales: claim period not exist"
            );
        }

        emit ClaimPeriodsRemoved(periods);
    }

    function addLockPeriods(
        uint256[] calldata _lockPeriods,
        uint256[] calldata _discounts
    ) external onlyOwner {
        require(
            _lockPeriods.length == _discounts.length,
            "RewardTokenSales: _lockPeriods and _discounts length mismatch"
        );
        for (uint256 i = 0; i < _lockPeriods.length; i++) {
            uint256 period = _lockPeriods[i];
            uint256 discount = _discounts[i];
            require(
                discount <= INVERSE_BASIS_POINT,
                "RewardTokenSales: discount must be in range [0-10000]"
            );
            require(
                lockPeriods.add(period),
                "RewardTokenSales: lock period already exists"
            );

            discountPlans[period] = discount;
        }

        emit LockPeriodsAdded(_lockPeriods, _discounts);
    }

    function removeLockPeriods(uint256[] calldata _lockPeriods)
        external
        onlyOwner
    {
        for (uint256 i = 0; i < _lockPeriods.length; i++) {
            uint256 period = _lockPeriods[i];
            require(
                lockPeriods.remove(period),
                "RewardTokenSales: lock period not exist"
            );

            discountPlans[period] = 0;
        }

        emit LockPeriodsRemoved(_lockPeriods);
    }

    /* =====================================
    User functions 
    ====================================== */
    /// @inheritdoc IRewardTokenSales
    function buyRewardTokens(
        address payer,
        uint256 rpId,
        uint256 amount,
        PriceType priceType,
        IERC20Upgradeable paymentToken,
        uint256 lockPeriod,
        uint256 claimPeriod
    ) external override onlyManager nonReentrant returns (uint256) {
        require(
            lockPeriods.contains(lockPeriod),
            "RewardTokenSales: invalid lockPeriod"
        );
        require(
            claimPeriods.contains(claimPeriod),
            "RewardTokenSales: invalid claimPeriod"
        );
        require(
            claimPeriod < lockPeriod,
            "RewardTokenSales: claimPeriod exceeds lockPeriod"
        );
        require(
            amount >= minPurchaseAmount,
            "RewardTokenSales: amount is less than minimum"
        );
        require(
            purchasedReward[rpId] + amount <= rewardLimitPerProvider,
            "RewardTokenSales: total amount exceeds limit"
        );

        // general statistic
        uint256 purchaseId = purchaseCount;
        purchaseCount++;

        purchasedReward[rpId] += amount;
        totalSold += amount;
        purchasesByProvider[rpId].push(purchaseId);

        // new purchase
        Purchase storage p = purchases[purchaseId];
        p.id = purchaseId;
        p.rpId = rpId;
        p.amount = amount;
        p.priceType = priceType;
        p.paymentToken = paymentToken;
        p.createdAt = block.timestamp;
        p.lockPeriod = lockPeriod;
        p.claimPeriod = claimPeriod;
        p.totalClaimWindows = lockPeriod.ceilDiv(claimPeriod) + 1;
        p.lastClaimWindow = 0;

        uint256 paymentAmount = 0;
        if (priceType != PriceType.AlreadyPaid) {
            paymentAmount = _executePayment(
                p,
                payer,
                amount,
                priceType,
                paymentToken,
                lockPeriod
            );
        }

        emit RewardTokenPurchased(
            purchaseId,
            rpId,
            amount,
            priceType,
            paymentAmount,
            lockPeriod,
            claimPeriod
        );

        return purchaseId;
    }

    /**
     * @dev calculate and transfer payment from buyer to wallet
     * @param p purchase info
     * @param payer fee payer
     * @param amount of reward token
     * @param priceType how to calculate reward token price
     * @param paymentToken token used as payment
     * @param lockPeriod total time to lock reward token
     * @return paymentAmount amount of paymentToken paid
     */
    function _executePayment(
        Purchase storage p,
        address payer,
        uint256 amount,
        PriceType priceType,
        IERC20Upgradeable paymentToken,
        uint256 lockPeriod
    ) private returns (uint256) {
        // calculate origin price
        uint256 price = 0;
        if (priceType == PriceType.FixedPrice) {
            uint256 usdtAmount = (rewardTokenPrice * amount) / 1e18;
            if (address(paymentToken) == USDT) {
                price = usdtAmount;
            } else {
                price = getSwapAmountIn(
                    address(paymentToken),
                    USDT,
                    usdtAmount
                );
            }
        }

        // calculate discounted price
        uint256 paymentAmount = price -
            (price * discountPlans[lockPeriod]) /
            INVERSE_BASIS_POINT;
        p.paymentAmount = paymentAmount;

        // Execute payment
        if (paymentAmount != 0) {
            paymentToken.safeTransferFrom(payer, wallet, paymentAmount);
        }

        return paymentAmount;
    }

    /// @inheritdoc IRewardTokenSales
    function claimRewardTokens(uint256 rpId, uint256 purchaseId)
        external
        override
        onlyManager
        nonReentrant
        returns (uint256)
    {
        Purchase storage p = purchases[purchaseId];

        // claim window starts at index 1 (i.e. 1 for first claim, 2 for second claim, and so on).
        uint256 currentWindow = 1;

        if (block.timestamp < p.createdAt + p.lockPeriod) {
            currentWindow = (block.timestamp - p.createdAt) / p.claimPeriod + 1;
        } else {
            currentWindow = p.totalClaimWindows;
        }

        require(
            !p.claimedWindows[currentWindow],
            "RewardTokenSales: already claimed in this window"
        );

        uint256 remainWindows = p.totalClaimWindows - currentWindow;

        uint256 claimAmount = (p.amount *
            (p.totalClaimWindows - p.lastClaimWindow - remainWindows)) /
            p.totalClaimWindows;

        // Update state
        p.claimedWindows[currentWindow] = true;
        p.lastClaimWindow = currentWindow;

        receivedReward[rpId] += claimAmount;
        totalReleased += claimAmount;

        emit RewardTokenReleased(p.id, p.rpId, claimAmount, currentWindow);

        return claimAmount;
    }

    /* =====================================
    Getter functions 
    ====================================== */
    function getLockPeriods() public view returns (uint256[] memory) {
        return lockPeriods.values();
    }

    function getClaimPeriods() public view returns (uint256[] memory) {
        return claimPeriods.values();
    }

    function getPurchasesByProvider(uint256 rpId)
        public
        view
        override
        returns (uint256[] memory)
    {
        return purchasesByProvider[rpId];
    }

    /// @inheritdoc IRewardTokenSales
    function getClaimWindowInfo(uint256 purchaseId)
        public
        view
        override
        returns (uint256, bool)
    {
        require(
            purchaseId < purchaseCount,
            "RewardTokenSales: purchase not exist"
        );

        Purchase storage p = purchases[purchaseId];

        uint256 currentWindow = _getCurrentWindow(purchaseId);

        return (currentWindow, p.claimedWindows[currentWindow]);
    }

    /**
     * @notice get current claim window information of a purchase
     * @param fromToken token to estimate
     * @param toToken destination token
     * @param toAmount amount of toToken
     * @return fromAmount amount of fromToken that equal (in price) to toAmount
     */
    function getSwapAmountIn(
        address fromToken,
        address toToken,
        uint256 toAmount
    ) public view returns (uint256) {
        /* If we estimate with toAmount, the swap fee is high.
        => estimate with oneUnit and then multiply by toAmount */
        uint256 toTokenDecimals = IERC20Decimals(toToken).decimals();
        uint256 oneUnit = 10**toTokenDecimals;

        uint256 paymentForOneUnit = _estimateSwapAmountIn(
            fromToken,
            toToken,
            oneUnit
        );
        return (paymentForOneUnit * toAmount) / oneUnit;
    }

    function _getCurrentWindow(uint256 purchaseId)
        internal
        view
        returns (uint256 currentWindow)
    {
        Purchase storage p = purchases[purchaseId];
        if (block.timestamp < p.createdAt + p.lockPeriod) {
            currentWindow = (block.timestamp - p.createdAt) / p.claimPeriod + 1;
        } else {
            currentWindow = p.totalClaimWindows;
        }
    }

    function _estimateSwapAmountIn(
        address fromToken,
        address toToken,
        uint256 amountOut
    ) private view returns (uint256) {
        address[] memory path = _getSwapPath(fromToken, toToken);

        uint256[] memory amounts = swapRouter.getAmountsIn(amountOut, path);

        return amounts[0];
    }

    function _getSwapPath(address fromToken, address toToken)
        private
        pure
        returns (address[] memory)
    {
        if (fromToken == WASA || toToken == WASA) {
            address[] memory path = new address[](2);
            path[0] = fromToken;
            path[1] = toToken;
            return path;
        } else {
            address[] memory path = new address[](3);
            path[0] = fromToken;
            path[1] = WASA;
            path[2] = toToken;
            return path;
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
                /// @solidity memory-safe-assembly
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

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
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
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
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
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
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
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
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
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
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
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
                /// @solidity memory-safe-assembly
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
pragma solidity 0.8.9;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

/**
 * @title Abstract manageable contract that can be inherited by other contracts
 * @notice Contract module based on Ownable which provides a basic access control mechanism, where
 * there is an owner and a manager that can be granted exclusive access to specific functions.
 *
 * By default, the owner is the deployer of the contract.
 *
 * The owner account is set through a two steps process.
 *      1. The current `owner` calls {transferOwnership} to set a `pendingOwner`
 *      2. The `pendingOwner` calls {acceptOwnership} to accept the ownership transfer
 *
 * The manager account needs to be set using {setManager}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyManager`, which can be applied to your functions to restrict their use to
 * the manager.
 */
abstract contract ManageableUpgradeable is OwnableUpgradeable {
    address private _manager;

    /**
     * @dev Emitted when `_manager` has been changed.
     * @param previousManager previous `_manager` address.
     * @param newManager new `_manager` address.
     */
    event ManagerTransferred(
        address indexed previousManager,
        address indexed newManager
    );

    /* ============ External Functions ============ */

    /**
     * @notice Gets current `_manager`.
     * @return Current `_manager` address.
     */
    function manager() public view virtual returns (address) {
        return _manager;
    }

    /**
     * @notice Set or change of manager.
     * @dev Throws if called by any account other than the owner.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function setManager(address _newManager) external onlyOwner returns (bool) {
        return _setManager(_newManager);
    }

    /* ============ Internal Functions ============ */

    /**
     * @notice Set or change of manager.
     * @param _newManager New _manager address.
     * @return Boolean to indicate if the operation was successful or not.
     */
    function _setManager(address _newManager) private returns (bool) {
        address _previousManager = _manager;

        require(_newManager != _previousManager, "Manageable: manager exists");

        _manager = _newManager;

        emit ManagerTransferred(_previousManager, _newManager);
        return true;
    }

    /* ============ Modifier Functions ============ */

    /**
     * @dev Throws if called by any account other than the manager.
     */
    modifier onlyManager() {
        require(
            manager() == msg.sender,
            "Manageable: caller is not the manager"
        );
        _;
    }

    /**
     * @dev Throws if called by any account other than the manager or the owner.
     */
    modifier onlyManagerOrOwner() {
        require(
            manager() == msg.sender || owner() == msg.sender,
            "Manageable: caller is not the manager or owner"
        );
        _;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../extensions/draft-IERC20PermitUpgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20PermitUpgradeable token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

interface ISolarSwapRouter {
    function swapExactETHForTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable returns (uint256[] memory amounts);

    function swapExactTokensForETH(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity 0.8.9;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Decimals {
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

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Returns the decimals of tokens owned by `account`.
     */
    function decimals() external view returns (uint256);

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20PermitUpgradeable {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}