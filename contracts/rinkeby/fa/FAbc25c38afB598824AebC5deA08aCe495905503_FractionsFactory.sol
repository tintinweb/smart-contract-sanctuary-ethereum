//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "./vault/presets/CompleteFractionsVaultPreset.sol";
import "./interfaces/ISettings.sol";
import "./interfaces/IAdapters.sol";


/// @title FractionsFactory that deploys FractionVaults
/// @author George Spasov
/// @notice This contract creates new instances of Fraction Vault
contract FractionsFactory {

    address[] public vaults;
    mapping(address => mapping(uint256 => address[])) public vaultsFor;

    address immutable public governance;
    address immutable public settings;
    address immutable public adapters;
    address immutable public farmingVaultsRouter;

    event VaultCreated(address vault, address indexed token, uint256 indexed tokenId, address manager);

    constructor(address _governance, address _settings, address _adapters, address _farmingVaultsRouter) {
        require(_governance != address(0x0), "Governance cannot be 0");
        require(_settings != address(0x0), "Settings cannot be 0");
        require(_adapters != address(0x0), "Adapters cannot be 0");
        require(_farmingVaultsRouter != address(0x0), "Farming Vaults Router cannot be 0");
        governance = _governance;
        settings = _settings;
        adapters = _adapters;
        farmingVaultsRouter = _farmingVaultsRouter;
    }

    /// @notice Deploys a new CompleteFractionsVaultPreset and issues ERC20 fractions to the manager
    /// @notice Sets an initial management fee for the vault. 
    /// @notice The management fee will be applied only on the profit amount (ex. rent).
    /// Everything else will be used for the farming strategy
    /// @dev Expects that the msg.sender has approved the ERC721 token.
    /// @dev Only supports ERC20 as exitToken. If you need ETH, use WETH.
    /// @param manager The address of the soon to be manager of the vault. The manager needs to be the current owner of the token and need to approve the factory.
    /// @param tokenAddress The address of the ERC721 token
    /// @param tokenId The id of the token in the ERC721 contract
    /// @param exitToken The address of the ERC20 token that will denominate the exit fee in
    /// @param exitFee The fee in `exitToken` that will start the exit auction
    /// @param fractionsCount The number of fractions that will be issued
    /// @return vault The address of the new vault
    function deployVault(
        address manager,
        address tokenAddress,
        uint256 tokenId,
        address exitToken,
        uint256 exitFee,
        uint256 fractionsCount)
        public returns(address vault)
    {
        vault = address(
            new CompleteFractionsVaultPreset(
                BasicFractionsVault.BasicVaultParams({
                    _governance: governance,
                    _settings: settings,
                    _manager: manager,
                    _tokenAddress: tokenAddress, 
                    _tokenId: tokenId, 
                    _fractionsCount: fractionsCount
                }),
                exitToken,
                exitFee,
                adapters,
                farmingVaultsRouter
            )
        );

        vaults.push(vault);
        vaultsFor[tokenAddress][tokenId].push(vault);
        IERC721(tokenAddress).safeTransferFrom(manager, vault, tokenId);

        emit VaultCreated(vault, tokenAddress, tokenId, manager);
    }

    /// @notice Returns the count of all the vaults ever created
    /// @return The number of vaults ever created by this factory
    function totalVaultsCount() public view returns (uint256) {
        return vaults.length;
    }

    /// @notice Returns the count of all the vaults ever created for a given token + tokenId combination
    /// @param token The address of the ERC721 token
    /// @param tokenId The id of the token in the ERC721 contract
    /// @return The number of vaults ever created for this token
    function vaultsCountFor(address token, uint256 tokenId) public view returns (uint256) {
        return vaultsFor[token][tokenId].length;
    }

    /// @notice Returns the last and most likely active vault for this asset
    /// @param token The address of the ERC721 token
    /// @param tokenId The id of the token in the ERC721 contract
    /// @return The address of the last vault created
    function lastVaultFor(address token, uint256 tokenId) public view returns (address) {
        uint256 len = vaultsFor[token][tokenId].length;
        return vaultsFor[token][tokenId][len - 1];
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./../extensions/PricedAuctionYieldingVault.sol";
import "./../extensions/FarmingYieldingVault.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/** 
    @title CompleteFractionsVaultPreset takes a deposit of ERC721 token and fractionalizes it
    @author George Spasov
    @notice This contract receives an NFT and issues a number of fractions against it. This vault is targeted at NFTs generating profit.
    The vault can be disbanded and the NFT can be withdrawn if someone deposits all the fractions or if a certain `ridiculousPrice` is paid.
    Upon disbanding the vault the earned profit is shared between the different fractions owners proportionally.
    The initial depositor is called manager and is entitled to a certain commission fee out of the profit.
    @dev Ownership must be transferred to the DAO
    @dev Combines the BasicFractionsVault and all the extensions
 */
contract CompleteFractionsVaultPreset is PricedAuctionYieldingVault, FarmingYieldingVault {
    using EnumerableSet for EnumerableSet.AddressSet;

    // @notice Creates the contract and sets the various parameters for the operation of the vault
    constructor(
        BasicFractionsVault.BasicVaultParams memory basicParams,
        address _exitToken,
        uint256 _exitFee,
        address _adapters,
        address _farmingRouter
    )
    BasicFractionsVault(basicParams)
    {
        _setupAuction(_exitToken, _exitFee, basicParams._fractionsCount);
        _setupYielding(_adapters);
        _setupVaultsRouter(_farmingRouter);
    }

    function exit() public virtual override(PricedAuctionYieldingVault, YieldingVault) {
        exit(_harvestingTokens.values());
    }

    function exit(address[] memory harvestedTokens) public virtual override(PricedAuctionYieldingVault, YieldingVault) {
        YieldingVault.exit(harvestedTokens);
    }

    function _accountHarvest(
        address harvestedToken,
        uint256 harvestedAmount,
        address rewardAddress
    ) internal virtual override(FarmingYieldingVault, YieldingVault) {
        FarmingYieldingVault._accountHarvest(harvestedToken, harvestedAmount, rewardAddress);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(PricedAuctionYieldingVault, ERC20) {
        PricedAuctionYieldingVault._beforeTokenTransfer(from, to, amount);
    }

    function _disburseYield(address user, address[] memory harvestedTokens) internal virtual override(FarmingYieldingVault, YieldingVault) {
        FarmingYieldingVault._disburseYield(user, harvestedTokens);
    }

    /// @notice extends the base functionality by giving you a share of the accumulated harvest
    function redeemFractions(address[] memory harvestedTokens) public virtual override {
        FarmingYieldingVault._disburseYield(msg.sender, harvestedTokens);
        PricedAuctionVault.redeemFractions();
    }

    /// @notice extends the base functionality by giving you a share of the accumulated harvest
    function redeemFractions() public virtual override {
        redeemFractions(_harvestingTokens.values());
    }

    /// @dev overrides the calculation of harvested amount to include the funds that are deposited for farming
    /// @param harvestedToken The token whose yield should be claimed
    function calculateHarvestedAmount(address harvestedToken) internal view virtual override(FarmingYieldingVault, YieldingVault) returns(uint256 harvestedAmount) {
        return FarmingYieldingVault.calculateHarvestedAmount(harvestedToken);
    }



}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;


interface ISettings {
    function maxFractions() external view returns (uint256);

    function minFractions() external view returns (uint256);

    function MAX_PERCENT() external view returns (uint256);

    function managementFee() external view returns (uint256);

    function governanceFee() external view returns (uint256);

    function harvesterFee() external view returns (uint256);

    function votingQuorum() external view returns (uint256);

    function auctionLength() external view returns (uint256);

    function lastBidBuffer() external view returns (uint256);

    function minBidIncrease() external view returns (uint256);

    function weth() external view returns (address);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;


interface IAdapters {

    event AdaptersSet(address indexed tokenAddress, address harvestAdapters, address managementAdapter);

    function adapters(uint256) external view returns (address);

    function adapterOf(address) external view returns (address, address);

    function setAdapters(address tokenAddress, address harvestAdapter, address managementAdapter) external;

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./PricedAuctionVault.sol";
import "./YieldingVault.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

/** 
    @title PricedAuctionYieldingVault combines the auction and yieldingVault extensions
    @author George Spasov
 */
abstract contract PricedAuctionYieldingVault is PricedAuctionVault, YieldingVault {
    using EnumerableSet for EnumerableSet.AddressSet;

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override(PricedAuctionVault, ERC20) {
        PricedAuctionVault._beforeTokenTransfer(from, to, amount);
    }

    function exit(address[] memory harvestedTokens) public virtual override(YieldingVault) {
        super.exit(harvestedTokens);
    }

    function exit() public virtual override(PricedAuctionVault, YieldingVault) {
        exit(_harvestingTokens.values());
    }

    /// @notice extends the base functionality by giving you a share of the accumulated harvest
    function redeemFractions(address[] memory harvestedTokens) public virtual {
        super._disburseYield(msg.sender, harvestedTokens);
        super.redeemFractions();
    }

    /// @notice extends the base functionality by giving you a share of the accumulated harvest
    function redeemFractions() public virtual override(PricedAuctionVault) {
        redeemFractions(_harvestingTokens.values());
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "./YieldingVault.sol";
import "./../../interfaces/IFarmingRouter.sol";

/** 
    @title FarmingYieldingVault is a vault that enables the idle capital to be used by strategies
    @author George Spasov
 */
abstract contract FarmingYieldingVault is YieldingVault {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice the farming protocol router that will enable us to get vaults to farm via
    IFarmingRouter public farmingRouter;

    /// @notice the accrued balance of certain token
    mapping(address => uint256) public depositedOf;

    event FarmingDepositComplete(address farmingToken, uint256 depositedAmount);

    /// @notice initializes the farming router
    /// @param _router The address of the router contract
    function _setupVaultsRouter(address _router) internal virtual {
        require(_router != address(0x0), "Router cannot be 0");

        farmingRouter = IFarmingRouter(_router);
    }

    /// @notice withdraws all the capital that is currently farming
    /// @param harvestedTokens The tokens that the vault has chosen to harvest
    function _withdrawAllCapital(address[] memory harvestedTokens) internal virtual {
        uint256 tokensLen = harvestedTokens.length;
        for (uint256 i = 0; i < tokensLen; i++) {
            address harvestedToken = harvestedTokens[i];
            // TODO check if this there is a possibility for the capital to not be in the best vault
            address vault = farmingRouter.bestVault(harvestedToken);
            if (vault == address(0x0)) {// No vault for this token
                continue;
            }
            uint256 balance = farmingRouter.balanceOf(harvestedToken, address(this));
            if(balance == 0) {
                continue;
            }
            farmingRouter.exit(harvestedToken);
        }
    }

    /// @notice deposits all the free capital that is lying in the vault. If no vault is available in the router nothing is deposited.
    /// @dev needs to be called after harvest is accounted for.
    /// @param _token The token that we want to deposit to a vault
    /// @return depositedAmount How much is deposited into a vault. Can be 0 if no vault is found
    function _depositFreeCapital(address _token) internal virtual returns (uint256 depositedAmount) {
        address vault = farmingRouter.bestVault(_token);
        if (vault == address(0x0)) {// No vault for this token
            return 0;
        }
        depositedAmount = IERC20(_token).balanceOf(address(this));
        return _gracefulDeposit(_token, depositedAmount);
    }

    /// @notice used for fail tolerant deposit into the farming router. If for some reason the farming router reverts on depositing the amount, we still want the harvest to succeed.
    /// @dev this function assumes that a check that a vault for this token exists
    /// @param _token The token that we want to deposit to a vault
    /// @param depositedAmount How much do we want to deposit of this token into a vault
    /// @return How much was deposited into a vault. Can be 0 if the farming router reverted
    function _gracefulDeposit(address _token, uint256 depositedAmount) internal returns(uint256) {
        IERC20(_token).approve(address(farmingRouter), depositedAmount);
        try farmingRouter.deposit(_token, depositedAmount) {
            emit FarmingDepositComplete(_token, depositedAmount);
            return depositedAmount;
        } catch Error(string memory /*reason*/) {
            // This is executed in case
            // revert was called inside getData
            // and a reason string was provided.
            
            return 0;
        } catch (bytes memory /*lowLevelData*/) {
            // This is executed in case revert() was used
            // or there was a failing assertion, division
            // by zero, etc. inside getData.
            return 0;
        }
    }

    /// @notice extends the harvesting accounting and adds depositing of the free capital
    function _accountHarvest(address harvestedToken, uint256 harvestedAmount, address rewardAddress) internal virtual override(YieldingVault) {
        super._accountHarvest(harvestedToken, harvestedAmount, rewardAddress);
        depositedOf[harvestedToken] += _depositFreeCapital(harvestedToken);
    }

    /// @dev overrides the calculation of harvested amount to include the funds that are deposited for farming
    /// @param harvestedToken The token whose yield should be claimed
    function calculateHarvestedAmount(address harvestedToken) internal view virtual override returns(uint256 harvestedAmount) {
        harvestedAmount = (IERC20(harvestedToken).balanceOf(address(this)) + depositedOf[harvestedToken]) - harvestedOf[harvestedToken];
        return harvestedAmount;
    }

    /// @notice extends the disbursement by doing a withdrawal
    function _disburseYield(address user, address[] memory harvestedTokens) internal virtual override(YieldingVault) {
        _withdrawAllCapital(harvestedTokens);
        super._disburseYield(user, harvestedTokens);
    }

    /// @notice gets the vault capital available. It includes the deposited in farming and the accrued farming yield
    /// @param token The token that we want to view the capital for
    /// @return capital How much is the capital of this vault
    function getVaultCapital(address token) public view returns (uint256 capital) {
        address vault = farmingRouter.bestVault(token);
        // TODO check if this there is a possibility for the capital to not be in the best vault
        if (vault == address(0x0)) {
            return IERC20(token).balanceOf(address(this));
        }
        return farmingRouter.balanceOf(token, address(this));
    }

}

// SPDX-License-Identifier: MIT
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

        assembly {
            result := store
        }

        return result;
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./../BasicFractionsVault.sol";

/** 
    @title PricedAuctionVault extends the BasicFractionsVault with the ability to auction away the underlying NFT
    @author George Spasov
 */
abstract contract PricedAuctionVault is BasicFractionsVault {
    using SafeERC20 for IERC20;

    /// @notice the number of fractions voting on the `exitFee` at any given time
    uint256 public votingTokens;

    /// @notice a mapping of users to their desired token price
    mapping(address => uint256) public userPrices;

    /// @notice the ERC20 token used for exit fee
    IERC20 public exitToken;

    /// @dev The sum of all `userPrices` multiplied by the number of their fractions (weight) at the time of setting their price
    uint256 public exitTotal;

    /// @notice the unix timestamp end time of the token auction
    uint256 public auctionEnd;

    /// @notice the current price of the token during an auction
    uint256 public livePrice;

    /// @notice the current user winning the token auction
    address public winning;

    enum State {inactive, live, ended}

    /// @notice the state of the auction
    State public auctionState;

    event PriceUpdate(address indexed user, uint price);
    event AuctionStarted(address bidder, uint256 bidAmount);
    event AuctionBid(address indexed bidder, uint256 bidAmount);
    event AuctionWon(address winner, uint256 bidAmount);
    event FractionsRedeemed(address indexed user, uint256 share);

    /// @notice Sets up the param for the exit auction
    /// @dev The votingTokens are set to the fractions count initially as the creator votes right away
    /// @param _exitToken The address of the token the exit will be denominated in
    /// @param _exitFee The initial exit fee set by the manager
    /// @param fractionsCount The total number of fractions that are being created
    function _setupAuction(
        address _exitToken,
        uint256 _exitFee,
        uint256 fractionsCount
    ) internal virtual
    {
        require(_exitToken != address(0x0), "_setupAuction :: Exit token cannot be 0");
        require(_exitFee > 0, "_setupAuction :: Exit fee cannot be 0");
        exitToken = IERC20(_exitToken);
        userPrices[manager] = _exitFee;
        votingTokens = fractionsCount;
        exitTotal = votingTokens * _exitFee;
    }

    /// @notice Allows the owner of all fractions to exit, burning all the fractions and getting the deposited NFT
    /// @notice Returns the bid to the winner if called during live auction
    function exit() public virtual override(BasicFractionsVault) {
        // There is an auction going on and we need to return the bid to the winner
        if (auctionState == State.live) {
            address winning1 = winning;
            uint256 livePrice1 = livePrice;

            auctionState = State.inactive;
            winning = address(0x0);
            livePrice = 0;

            exitToken.safeTransfer(winning1, livePrice1);
        }

        require(auctionState == State.inactive, "An auction has already completed for the NFT");
        super.exit();
    }

    /// @notice Returns the current price that can trigger the start of an auction for the NFT (weighted average)
    function exitPrice() public view returns (uint256) {
        return votingTokens == 0 ? 0 : exitTotal / votingTokens;
    }

    /// @notice an internal function used to update sender and receivers price on token transfer
    /// @param _from the ERC20 token sender
    /// @param _to the ERC20 token receiver
    /// @param _amount the ERC20 token amount
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal virtual override {
        super._beforeTokenTransfer(_from, _to, _amount);

        // only do something if there is no auction underway
        if (auctionState != State.inactive) {
            return;
        }
        uint256 fromPrice = userPrices[_from];
        uint256 toPrice = userPrices[_to];

        // Only do something if users have different reserve price
        // This also covers the case where both new and old holders are not voters
        if (toPrice == fromPrice) {
            return;
        }

        // New holder is not a voter
        if (toPrice == 0) {
            // Remove the tokens from the voting tokens as they are not voting anymore
            votingTokens -= _amount;
        }

        // Old holder is not a voter
        if (fromPrice == 0) {
            // Add the tokens to the voting tokens as they are now voting
            votingTokens += _amount;
        }

        exitTotal = exitTotal + (_amount * toPrice) - (_amount * fromPrice);

    }

    /// @notice a function for an user to update their desired sale price
    /// @param newUserPrice the desired price in `exitToken`
    function updateUserPrice(uint256 newUserPrice) external virtual {
        require(auctionState == State.inactive, "updateUserPrice :: Auction is live");
        uint256 oldUserPrice = userPrices[msg.sender];
        require(newUserPrice != oldUserPrice, "updateUserPrice :: Not an update");
        uint256 weight = balanceOf(msg.sender);

        userPrices[msg.sender] = newUserPrice;
        emit PriceUpdate(msg.sender, newUserPrice);

        // New voter
        if (oldUserPrice == 0) {
            votingTokens += weight;
        }

        // Vote withdrawal
        if (newUserPrice == 0) {
            votingTokens -= weight;
        }

        exitTotal = exitTotal + (weight * newUserPrice) - (weight * oldUserPrice);
    }

    /// @notice kick off an auction. Must send exitPrice in `exitToken`
    /// @param bidAmount The amount of `exitToken` that the user is bidding to start the auction
    function auctionStart(uint256 bidAmount) external virtual {
        require(exitPrice() > 0, "auctionStart :: No price is set for an auction");
        require(auctionState == State.inactive, "auctionStart :: Auction has already started");
        require(bidAmount >= exitPrice(), "auctionStart :: Bid too low");
        require(votingTokens * MAX_PERCENT >= settings.votingQuorum() * totalSupply(), "auctionStart :: Quorum not reached");

        auctionEnd = block.timestamp + settings.auctionLength();
        auctionState = State.live;
        livePrice = bidAmount;
        winning = msg.sender;

        exitToken.safeTransferFrom(msg.sender, address(this), bidAmount);
        emit AuctionStarted(msg.sender, bidAmount);
    }

    /// @notice an external function to bid on purchasing the vaults NFT.
    /// @param bidAmount The amount of `exitToken` that the user is bidding to start the auction
    function auctionBid(uint256 bidAmount) external virtual {
        require(auctionState == State.live, "auctionBid :: auction is not live");
        require(block.timestamp < auctionEnd, "auctionBid :: auction ended");
        require((bidAmount - livePrice) * MAX_PERCENT >= livePrice * settings.minBidIncrease(), "auctionBid :: bid not increased enough");

        address prevWinner = winning;
        uint256 prevLivePrice = livePrice;
        winning = msg.sender;
        livePrice = bidAmount;

        // If bid is within `lastBidBuffer` of auction end, extend auction
        if (auctionEnd - block.timestamp <= settings.lastBidBuffer()) {
            auctionEnd += settings.lastBidBuffer();
        }

        exitToken.safeTransfer(prevWinner, prevLivePrice); // Send the last bidder their money back
        exitToken.safeTransferFrom(msg.sender, address(this), bidAmount); // Get the new bid in

        emit AuctionBid(msg.sender, bidAmount);
    }

    /// @notice an external function to end an auction after the timer has run out
    function endAuction() external virtual {
        require(auctionState == State.live, "endAuction :: vault has already closed");
        require(block.timestamp >= auctionEnd, "endAuction :: auction live");

        auctionState = State.ended;

        // transfer erc721 to winner
        IERC721(token).safeTransferFrom(address(this), winning, tokenId);

        emit AuctionWon(winning, livePrice);
    }

    /// @notice Burns fractions to receive `exitToken` from the ERC721 token purchase proportional to the sender balance
    function redeemFractions() public virtual {
        require(auctionState == State.ended, "redeemFractions :: auction not ended");
        uint256 bal = balanceOf(msg.sender);
        uint256 share = (bal * exitToken.balanceOf(address(this))) / totalSupply();

        _burn(msg.sender, bal);

        exitToken.safeTransfer(msg.sender, share);
        emit FractionsRedeemed(msg.sender, share);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./../BasicFractionsVault.sol";
import "./../../external/IWETH.sol";
import "./../../interfaces/IAdapters.sol";
import "./../../interfaces/IHarvestAdapter.sol";
import "./../../interfaces/IManagementAdapter.sol";

/** 
    @title YieldingVault extends the BasicFractionsVault with the ability claim yield from the NFT
    @author George Spasov
    @notice This contract assumes that yield bearing NFT is deposited inside. Based on adapters provided externally,
    this contract delegatecalls harvesting or certain business logic.
 */
abstract contract YieldingVault is BasicFractionsVault {
    using EnumerableSet for EnumerableSet.AddressSet;

    /// @notice the adapter contract to get specific nft logic from
    IAdapters public adapters;

    /// @notice all the tokens that we have ever harvested in (and should have balance in theory)
    EnumerableSet.AddressSet internal _harvestingTokens;

    /// @notice the accrued balance of certain token
    mapping(address => uint256) public harvestedOf;

    event HarvestComplete(address harvestedToken, uint256 harvestedAmount, address indexed harvester);
    event YieldDisbursed(address yieldToken, uint256 yieldAmount, address indexed receiver);
    event ManagementExecuted(address addressCall, string signature, bytes data);

    /// @notice Sets up the params for the yielding
    /// @param _adapters The address of the adapters that will expose the claiming and management logic
    function _setupYielding(address _adapters) internal virtual {
        require(_adapters != address(0x0), "_setupYielding :: Adapters cannot be 0");
        adapters = IAdapters(_adapters);
    }

    /// @return Returns all tokens we have ever harvested in and we should have balance in if the vault is still active
    function harvestingTokens() public view returns (address[] memory) {
        return _harvestingTokens.values();
    }

    receive() external payable {}

    /// @notice triggers a harvest of the yield for the deposited yield bearing token
    /// @notice this works for harvesting where the nft owner (the vault in our case) needs to proactively claim.
    /// @notice Look at `acknowledgeHarvest` for yield that gets pushed into the owner of the token
    /// @notice Acknowledged ETH is converted to WETH
    /// @dev approves the NFT to the adapter in case it needs it
    /// @dev sends the commission fees to the relevant parties
    /// @dev If harvestedToken is 0x0, acknowledges ETH harvest
    /// @param rewardAddress The address where the sender would like the reward to be sent to
    function harvest(address rewardAddress) public virtual returns (address harvestedToken, uint256 harvestedAmount) {
        address harvestAdapterAddress;
        (harvestAdapterAddress,) = adapters.adapterOf(address(token));

        if (token.getApproved(tokenId) != harvestAdapterAddress) {
            // Approve the adapter in case it needs some permission. Notice that the due diligence process of the adapters need to account for that
            token.approve(harvestAdapterAddress, tokenId);
        }

        // TODO maybe pass `data` argument?
        (harvestedToken, harvestedAmount) = IHarvestAdapter(harvestAdapterAddress).harvest(address(token), tokenId);
        if (harvestedToken == address(0)) {
            acknowledgeETHHarvest(rewardAddress);
        } else {
            _accountHarvest(harvestedToken, harvestedAmount, rewardAddress);

            emit HarvestComplete(harvestedToken, harvestedAmount, msg.sender);
        }
    }

    /// @notice acknowledges that certain harvested amount has been received
    /// @notice this works for harvesting the yield when it is pushed rather than pulled.
    /// @notice Look at `harvest` for yield that needs to be pulled
    /// @dev sends the commission fees to the relevant parties
    /// @param harvestedToken The token whose yield should be claimed
    /// @param rewardAddress The address where the sender would like the reward to be sent to
    function acknowledgeHarvest(address harvestedToken, address rewardAddress) public virtual returns (uint256 harvestedAmount) {
        harvestedAmount = calculateHarvestedAmount(harvestedToken);

        _accountHarvest(harvestedToken, harvestedAmount, rewardAddress);

        emit HarvestComplete(harvestedToken, harvestedAmount, msg.sender);
    }

    /// @notice acknowledges that certain harvested ETH amount has been received,
    /// @notice converting it into WETH.
    /// @notice Reference: `acknowledgeHarvest`.
    /// @param rewardAddress The address where the sender would like the reward to be sent to
    function acknowledgeETHHarvest(address rewardAddress) public virtual returns (uint256 harvestedAmount) {
        uint256 amount = address(this).balance;
        address weth = settings.weth();
        IWETH(weth).deposit{value: amount}();

        return acknowledgeHarvest(weth, rewardAddress);
    }

    /// @dev Separating this calculation so that further extensions that make use of the capital can do their own version of the calculation
    /// @param harvestedToken The token whose yield should be claimed
    function calculateHarvestedAmount(address harvestedToken) internal view virtual returns (uint256 harvestedAmount) {
        harvestedAmount = IERC20(harvestedToken).balanceOf(address(this)) - harvestedOf[harvestedToken];
        return harvestedAmount;
    }

    /// @dev internal function to do the accounting and fees disbursement for the harvesting process
    /// @param harvestedToken The token whose yield should be claimed
    /// @param harvestedAmount The amount of tokens to be accounted for
    /// @param rewardAddress The address where the sender would like the reward to be sent to
    function _accountHarvest(address harvestedToken, uint256 harvestedAmount, address rewardAddress) internal virtual {
        require(harvestedAmount > 0, "Nothing harvested");

        // EnumerableSet will take care of no duplicates
        _harvestingTokens.add(harvestedToken);

        uint256 managerFee = (harvestedAmount * settings.managementFee()) / MAX_PERCENT;
        uint256 senderFee = (harvestedAmount * settings.harvesterFee()) / MAX_PERCENT;
        uint256 governanceFee = (harvestedAmount * settings.governanceFee()) / MAX_PERCENT;

        IERC20(harvestedToken).transfer(manager, managerFee);
        IERC20(harvestedToken).transfer(rewardAddress, senderFee);
        IERC20(harvestedToken).transfer(governance, governanceFee);

        harvestedOf[harvestedToken] += (harvestedAmount - (managerFee + senderFee + governanceFee));
    }

    /// @notice enables the manager to execute a managing functions defined in the management adapter
    /// @dev The address and signature need to be whitelisted in the management adapter
    /// @param callAddress The address that will be called to execute the function denoted by `signature`
    /// @param signature The signature of the function that will be called
    /// @param data The data to be sent to the function
    function manage(address callAddress, string memory signature, bytes calldata data) public onlyManager {
        address managementAdapter;
        (, managementAdapter) = adapters.adapterOf(address(token));

        require(IManagementAdapter(managementAdapter).isAllowed(callAddress, signature), "Call not allowed");

        Address.functionCall(callAddress, bytes.concat(bytes4(keccak256(bytes(signature))), data));

        emit ManagementExecuted(callAddress, signature, data);
    }

    /// @notice Sends all the harvest to the address exiting
    /// @param harvestedTokens The tokens that the user has chosen to harvest
    function exit(address[] memory harvestedTokens) public virtual {
        _disburseYield(msg.sender, harvestedTokens);
        super.exit();
    }


    /// @notice Exits with all the tokens that we have been harvesting
    function exit() public virtual override(BasicFractionsVault) {
        exit(_harvestingTokens.values());
    }

    /// @notice Used to distribute the yield to the user based on his ownership of the fractions
    /// @param user The address of the user to be given the yield
    /// @param harvestedTokens The tokens that the user has chosen to harvest
    /// @dev the user can decide not to harvest all tokens
    function _disburseYield(address user, address[] memory harvestedTokens) internal virtual {
        uint256 bal = balanceOf(user);
        uint256 tokensLen = harvestedTokens.length; // The end user needs to make sure this will go through
        for (uint256 i = 0; i < tokensLen; i++) {
            IERC20 harvestedToken = IERC20(harvestedTokens[i]);
            uint256 balance = harvestedToken.balanceOf(address(this));
            uint256 harvestShare = (bal * balance) / totalSupply();
            IERC20(harvestedToken).transfer(user, harvestShare);
            emit YieldDisbursed(address(harvestedToken), harvestShare, user);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
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

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/presets/ERC20PresetFixedSupply.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./../interfaces/ISettings.sol";

/** 
    @title BasicFractionsVault takes a deposit of ERC721 token and fractionalizes it
    @author George Spasov
    @notice This contract receives an NFT and issues a number of fractions against it. This vault is targeted at NFTs generating profit.
    The vault can be disbanded and the NFT can be withdrawn if someone deposits all the fractions or if a certain `ridiculousPrice` is paid.
    Upon disbanding the vault the earned profit is shared between the different fractions owners proportionally.
    The initial depositor is called manager and is entitled to a certain commission fee out of the profit.
    @dev Ownership must be transferred to the DAO
 */
contract BasicFractionsVault is ERC20PresetFixedSupply, ERC721Holder {
    using SafeERC20 for IERC20;

    /// @dev Percentages are represented as basis points, with each point being 0.01%
    /// @dev ex. 100% = 10000, 1% = 100 0.01% = 1
    /// @notice The representation of 100%
    uint256 public constant MAX_PERCENT = 10000;

    /// Vault Fields

    /// @notice the address for the dao governing this vault
    address public governance;

    /// @notice the settings contract to get parameters from
    ISettings public settings;

    /// @notice the manager of the contract who (possibly) deposited the NFT in the first place
    address public manager;

    /// @notice the NFT token
    IERC721 public token;

    /// @notice the NFT token id
    uint256 public tokenId;

    enum Status {
        INACTIVE,
        ACTIVE
    }

    /// Offering Fields

    /// @notice the token to be paid for this offering
    IERC20 public offerToken;

    /// @notice the remaining payment on the active offering
    uint256 public remainingTotalPayment;

    modifier onlyManager() {
        require(msg.sender == manager, "Not called by the manager");
        _;
    }

    modifier onlyActive() {
        require(getVaultStatus() == Status.ACTIVE, "Vault is inactive");
        _;
    }

    event ManagerChanged(address indexed oldManager, address indexed newManager);
    event OfferCreated(address manager, uint256 fractions, address offerToken, uint256 totalPayment);
    event FractionsBought(address indexed buyer, uint256 fractions, uint256 payment);

    event VaultExited(address exiter);


    /// @notice Params for the vault creation
    /// @param _governance The Governing DAO address 
    /// @param _settings The address of Settings contract that is responsible of enforcing parameter restrictions
    /// @param _manager The creator and manager of this vault. The manager is entitled to management fee specified in the `_managementFee` param.
    /// @param _tokenAddress The address of the deposited token
    /// @param _tokenId The id of the deposited token
    /// @param _fractionsCount The total number of fractions that are being created
    struct BasicVaultParams {
        address _governance;
        address _settings;
        address _manager;
        address _tokenAddress;
        uint256 _tokenId;
        uint256 _fractionsCount;
    }

    /// @notice Creates the contract and sets the various parameters for the operation of the vault
    constructor(BasicVaultParams memory params)
        ERC20PresetFixedSupply(
            string(abi.encodePacked("Yielding Fractions ", IERC721Metadata(params._tokenAddress).name(), "-", Strings.toString(params._tokenId))),
            string(abi.encodePacked("YFRC-", IERC721Metadata(params._tokenAddress).symbol(), "-", Strings.toString(params._tokenId))),
            params._fractionsCount,
            params._manager)
    {
        require(params._governance != address(0x0), "FractionsVault :: Governance cannot be 0");
        require(params._settings != address(0x0), "FractionsVault :: Settings cannot be 0");
        require(params._manager != address(0x0), "FractionsVault :: Manager cannot be 0");
        require(params._tokenAddress != address(0x0), "FractionsVault :: Deposited token cannot be 0");

        require(params._fractionsCount <= ISettings(params._settings).maxFractions(), "FractionsVault :: too many fractions");
        require(params._fractionsCount > ISettings(params._settings).minFractions(), "FractionsVault :: too few fractions");

        governance = params._governance;
        manager = params._manager;
        settings = ISettings(params._settings);
        token = IERC721(params._tokenAddress);
        tokenId = params._tokenId;

    }

    /// @notice returns the status of the vault. The vault is active if the NFT is still in it
    /// @return 1 if active and 0 otherwise
    function getVaultStatus() public view returns (Status) {
        if (token.ownerOf(tokenId) == address(this)) {
            return Status.ACTIVE;
        }

        return Status.INACTIVE;
    }

    /// @notice Changes the manager of this vault.
    /// @param newManager the new manager of the vault
    function changeManager(address newManager) external virtual onlyManager {
        emit ManagerChanged(manager, newManager);
        manager = newManager;
    }

    /// @notice Allows the manager to offer certain number of fractions for sale. No new offering can start until the last one is complete.
    /// @dev The offered fractions are kept in this contract and the balance. If someone is stupid enough to send fractions to this contract they will get included in the next offering.
    /// @dev The offering state is determined based on any remaining total payment
    /// @param fractions The number of fractions to be offered
    /// @param _offerToken The token the manager wants to be paid
    /// @param totalPayment The total payment in `_offerToken` that the manager wants to receive
    function offer(uint256 fractions, address _offerToken, uint256 totalPayment) external virtual onlyActive onlyManager {
        require(fractions > 0, "Offer :: Need to offer at least 1 fraction");
        require(totalPayment > 0, "Offer :: The total price needs to be at least 1");
        require(_offerToken != address(0x0), "Offer :: The offer token cannot be 0");
        require(remainingTotalPayment == 0, "Offer :: Current offer has not finished");
        require(balanceOf(msg.sender) >= fractions, "Offer :: The manager does not have enough tokens");

        _transfer(msg.sender, address(this), fractions);

        offerToken = IERC20(_offerToken);
        remainingTotalPayment = totalPayment;

        emit OfferCreated(msg.sender, fractions, _offerToken, totalPayment);
    }

    /// @notice Allows users to buy fractions currently offered by the manager.
    /// The function calculate how much fractions you are going to get based on the payment you are sending
    /// @dev In order to prevent dust being left in the contract, if someone sends exactly the same amount of payment as
    /// the remaining payment, the full balance of this contract is sent to them
    /// @param _offerToken Explicitly stating the token in which buyer will pay for the fractions
    /// @param payment The user payment that will determine how much fractions they will get.
    /// @return boughtFractions The amount of fractions the user just bought
    function buy(address _offerToken, uint256 payment) external virtual returns (uint256 boughtFractions) {
        require(address(offerToken) == _offerToken, "Buy :: Invalid _offerToken provided");
        require(payment > 0 && payment <= remainingTotalPayment, "Buy :: Incorrect price for fractions buy");

        if (payment == remainingTotalPayment) {
            boughtFractions = balanceOf(address(this));
        } else {
            boughtFractions = (balanceOf(address(this)) * payment) / remainingTotalPayment;
        }

        remainingTotalPayment -= payment;
        _transfer(address(this), msg.sender, boughtFractions);
        offerToken.safeTransferFrom(msg.sender, manager, payment);
        emit FractionsBought(msg.sender, boughtFractions, payment);

        return boughtFractions;
    }

    /// @notice Allows the owner of all fractions to exit, burning all the fractions and getting the deposited NFT
    /// @notice Cannot be called if an auction is already live
    function exit() public virtual {
        _burn(msg.sender, totalSupply());
        token.safeTransferFrom(address(this), msg.sender, tokenId);

        emit VaultExited(msg.sender);
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/presets/ERC20PresetFixedSupply.sol)
pragma solidity ^0.8.0;

import "../extensions/ERC20Burnable.sol";

/**
 * @dev {ERC20} token, including:
 *
 *  - Preminted initial supply
 *  - Ability for holders to burn (destroy) their tokens
 *  - No access control mechanism (for minting/pausing) and hence no governance
 *
 * This contract uses {ERC20Burnable} to include burn capabilities - head to
 * its documentation for details.
 *
 * _Available since v3.4._
 */
contract ERC20PresetFixedSupply is ERC20Burnable {
    /**
     * @dev Mints `initialSupply` amount of token and transfers them to `owner`.
     *
     * See {ERC20-constructor}.
     */
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) ERC20(name, symbol) {
        _mint(owner, initialSupply);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

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
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

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
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
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
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

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
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
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
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: Unlicense
pragma solidity >=0.5.0;

interface IWETH {
    function deposit() external payable;
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;


interface IHarvestAdapter {

    function harvest(address tokenAddress, uint256 tokenId) external returns (address token, uint256 claimedAmount);

    function accruedHarvest(address tokenAddress, uint256 tokenId) external view returns (address token, uint256 claimedAmount);

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

interface IManagementAdapter {
    function isAllowed(address callAddress, string memory signature)
        external
        view
        returns (bool allowed);
}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;


interface IFarmingRouter {

    function bestVault(address token) external view returns(address);

    function balanceOf(address token, address account) external view returns (uint256 balance);

    function deposit(address token, uint256 amount) external;

    function exit(address token) external returns (uint256 withdrawnAmount);

}