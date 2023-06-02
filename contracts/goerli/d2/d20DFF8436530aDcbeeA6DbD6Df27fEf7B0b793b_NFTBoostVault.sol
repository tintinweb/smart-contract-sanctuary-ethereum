// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./external/council/libraries/History.sol";
import "./external/council/libraries/Storage.sol";

import "./libraries/NFTBoostVaultStorage.sol";
import "./interfaces/INFTBoostVault.sol";
import "./BaseVotingVault.sol";

import {
    NBV_DoesNotOwn,
    NBV_HasRegistration,
    NBV_AlreadyDelegated,
    NBV_InsufficientBalance,
    NBV_InsufficientWithdrawableBalance,
    NBV_MultiplierLimit,
    NBV_NoMultiplierSet,
    NBV_InvalidNft,
    NBV_ZeroAmount,
    NBV_ZeroAddress,
    NBV_ArrayTooManyElements,
    NBV_Locked,
    NBV_AlreadyUnlocked
} from "./errors/Governance.sol";

/**
 * @title NFTBoostVault
 * @author Non-Fungible Technologies, Inc.
 *
 * The voting power for participants in this vault holding reputation ERC1155 nfts
 * is enhanced by a multiplier. This contract enables holders of specific ERC1155 nfts
 * to gain an advantage wrt voting power for participation in governance. Participants
 * send their ERC20 tokens to the contract and provide their ERC1155 nfts as calldata.
 * Once the contract confirms their ownership of the ERC1155 token id, and matches the
 * ERC1155 address and tokenId to a multiplier, they are able to delegate their voting
 * power for participation in governance.
 *
 * This contract is Simple Proxy upgradeable which is the upgradeability system used for voting
 * vaults in Council.
 *
 * @dev There is no emergency withdrawal in this contract, any funds not sent via
 *      addNftAndDelegate() are unrecoverable by this version of the NFTBoostVault.
 *
 *      This contract is a proxy so we use the custom state management system from
 *      storage and return the following as methods to isolate that call.
 */
contract NFTBoostVault is INFTBoostVault, BaseVotingVault {
    // ======================================== STATE ==================================================

    // Bring History library into scope
    using History for History.HistoricalBalances;

    // ======================================== STATE ==================================================

    /// @dev Determines the maximum multiplier for any given NFT.
    /* solhint-disable var-name-mixedcase */
    uint128 public constant MAX_MULTIPLIER = 1.5e18;

    /// @dev Precision of the multiplier.
    uint128 public constant MULTIPLIER_DENOMINATOR = 1e18;

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @notice Deploys a voting vault, setting immutable values for the token
     *         and staleBlockLag.
     *
     * @param token                     The external erc20 token contract.
     * @param staleBlockLag             The number of blocks before which the delegation history is forgotten.
     * @param timelock                  The address of the timelock who can update the manager address.
     * @param manager                   The address of the manager who can update the multiplier values.
     */
    constructor(
        IERC20 token,
        uint256 staleBlockLag,
        address timelock,
        address manager
    ) BaseVotingVault(token, staleBlockLag) {
        if (timelock == address(0)) revert NBV_ZeroAddress();
        if (manager == address(0)) revert NBV_ZeroAddress();

        Storage.set(Storage.uint256Ptr("initialized"), 1);
        Storage.set(Storage.addressPtr("timelock"), timelock);
        Storage.set(Storage.addressPtr("manager"), manager);
        Storage.set(Storage.uint256Ptr("entered"), 1);
        Storage.set(Storage.uint256Ptr("locked"), 1);
    }

    // ===================================== USER FUNCTIONALITY =========================================

    /**
     * @notice Performs ERC1155 registration and delegation for a caller.
     *
     * @dev User has to own ERC1155 nft for receiving the benefits of a multiplier access.
     *
     * @param user                      The address of the user registering their tokens.
     * @param amount                    Amount of tokens sent to this contract by the user for locking
     *                                  in governance.
     * @param tokenId                   The id of the ERC1155 NFT.
     * @param tokenAddress              The address of the ERC1155 token the user is registering for multiplier
     *                                  access.
     * @param delegatee                 Optional param. The address to delegate the voting power associated
     *                                  with this Registration to
     */
    function addNftAndDelegate(
        address user,
        uint128 amount,
        uint128 tokenId,
        address tokenAddress,
        address delegatee
    ) external override nonReentrant {
        uint256 multiplier = 1e18;

        // confirm that the user is a holder of the tokenId and that a multiplier is set for this token
        if (tokenAddress != address(0) && tokenId != 0) {
            if (IERC1155(tokenAddress).balanceOf(user, tokenId) == 0) revert NBV_DoesNotOwn();

            multiplier = getMultiplier(tokenAddress, tokenId);

            if (multiplier == 0) revert NBV_NoMultiplierSet();
        }

        // load this contract's balance storage
        Storage.Uint256 storage balance = _balance();

        // load the registration
        NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[user];

        // If the token id and token address is not zero, revert because the Registration
        // is already initialized. Only one Registration per user
        if (registration.tokenId != 0 && registration.tokenAddress != address(0)) revert NBV_HasRegistration();

        // load the delegate. Defaults to the registration owner
        delegatee = delegatee == address(0) ? user : delegatee;

        // calculate the voting power provided by this registration
        uint128 newVotingPower = (amount * uint128(multiplier)) / MULTIPLIER_DENOMINATOR;

        // set the new registration
        _getRegistrations()[user] = NFTBoostVaultStorage.Registration(
            amount,
            newVotingPower,
            0,
            tokenId,
            tokenAddress,
            delegatee
        );

        // update this contract's balance
        balance.data += amount;

        _grantVotingPower(delegatee, newVotingPower);

        // transfer user ERC20 amount and ERC1155 nft into this contract
        _lockTokens(msg.sender, amount, tokenAddress, tokenId, 1);

        emit VoteChange(user, registration.delegatee, int256(uint256(newVotingPower)));
    }

    /**
     * @notice Changes the caller's token voting power delegation.
     *
     * @dev The total voting power is not guaranteed to go up because the token
     *      multiplier can be updated at any time.
     *
     * @param to                        The address to delegate to.
     */
    function delegate(address to) external override {
        NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[msg.sender];

        // If to address is already the delegate, don't send the tx
        if (to == registration.delegatee) revert NBV_AlreadyDelegated();

        History.HistoricalBalances memory votingPower = _votingPower();
        uint256 oldDelegateeVotes = votingPower.loadTop(registration.delegatee);

        // Remove voting power from old delegatee and emit event
        votingPower.push(registration.delegatee, oldDelegateeVotes - registration.latestVotingPower);
        emit VoteChange(msg.sender, registration.delegatee, -1 * int256(uint256(registration.latestVotingPower)));

        // Note - It is important that this is loaded here and not before the previous state change because if
        // to == registration.delegatee and re-delegation was allowed we could be working with out of date state
        uint256 newDelegateeVotes = votingPower.loadTop(to);
        // return the current voting power of the Registration. Varies based on the multiplier associated with the
        // user's ERC1155 token at the time of txn
        uint256 addedVotingPower = _currentVotingPower(registration);

        // add voting power to the target delegatee and emit event
        votingPower.push(to, newDelegateeVotes + addedVotingPower);

        // update registration properties
        registration.latestVotingPower = uint128(addedVotingPower);
        registration.delegatee = to;

        emit VoteChange(msg.sender, to, int256(addedVotingPower));
    }

    /**
     * @notice Removes a user's locked ERC20 tokens from this contract and if no tokens are remaining, the
     *         user's locked ERC1155 (if utilized) is also transferred back to them. Consequently, the user's
     *         delegatee loses the voting power associated with the aforementioned tokens.
     *
     * @dev Withdraw is unlocked when the locked state variable is set to 2.
     *
     * @param amount                      The amount of token to withdraw.
     */
    function withdraw(uint128 amount) external override nonReentrant {
        if (getIsLocked() == 1) revert NBV_Locked();
        if (amount == 0) revert NBV_ZeroAmount();

        // load the registration
        NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[msg.sender];

        // get this contract's balance
        Storage.Uint256 storage balance = _balance();
        if (balance.data < amount) revert NBV_InsufficientBalance();

        // get the withdrawable amount
        uint256 withdrawable = _getWithdrawableAmount(registration);
        if (withdrawable < amount) revert NBV_InsufficientWithdrawableBalance(withdrawable);

        // update contract balance
        balance.data -= amount;
        // update withdrawn amount
        registration.withdrawn += amount;
        // update the delegatee's voting power. Varies based on the multiplier associated with the
        // user's ERC1155 token at the time of the call
        _syncVotingPower(msg.sender, registration);

        if (registration.withdrawn == registration.amount) {
            if (registration.tokenAddress != address(0) && registration.tokenId != 0) {
                withdrawNft();
            }
            delete _getRegistrations()[msg.sender];
        }

        // transfer the token amount to the user
        token.transfer(msg.sender, amount);
    }

    /**
     * @notice Tops up a user's locked ERC20 token amount in this contract.
     *         Consequently, the user's delegatee gains voting power associated
     *         with the newly added tokens.
     *
     * @param amount                      The amount of tokens to add.
     */
    function addTokens(uint128 amount) external override nonReentrant {
        if (amount == 0) revert NBV_ZeroAmount();
        // load the registration
        NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[msg.sender];

        // get this contract's balance
        Storage.Uint256 storage balance = _balance();
        // update contract balance
        balance.data += amount;

        // update registration amount
        registration.amount += amount;
        // update the delegatee's voting power
        _syncVotingPower(msg.sender, registration);

        // transfer user ERC20 amount into this contract
        _lockTokens(msg.sender, amount, address(0), 0, 0);
    }

    /**
     * @notice Allows a users to withdraw the ERC1155 NFT they are using for
     *         accessing a voting power multiplier.
     */
    function withdrawNft() public override nonReentrant {
        // load the registration
        NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[msg.sender];

        if (registration.tokenAddress == address(0) || registration.tokenId == 0)
            revert NBV_InvalidNft(registration.tokenAddress, registration.tokenId);

        // transfer ERC1155 back to the user
        IERC1155(registration.tokenAddress).safeTransferFrom(
            address(this),
            msg.sender,
            registration.tokenId,
            1,
            bytes("")
        );

        // remove ERC1155 values from registration struct
        registration.tokenAddress = address(0);
        registration.tokenId = 0;

        // update the delegatee's voting power based on multiplier removal
        _syncVotingPower(msg.sender, registration);
    }

    /**
     * @notice A function that allows a user's to change the ERC1155 nft they are using for
     *         accessing a voting power multiplier.
     *
     * @param newTokenAddress            Address of the new ERC1155 token the user wants to use.
     * @param newTokenId                 Id of the new ERC1155 token the user wants to use.
     */
    function updateNft(uint128 newTokenId, address newTokenAddress) external override nonReentrant {
        if (newTokenAddress == address(0) || newTokenId == 0) revert NBV_InvalidNft(newTokenAddress, newTokenId);

        if (IERC1155(newTokenAddress).balanceOf(msg.sender, newTokenId) == 0) revert NBV_DoesNotOwn();

        NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[msg.sender];

        // withdraw the current ERC1155 from the registration
        withdrawNft();

        // set the new ERC1155 values in the registration
        registration.tokenAddress = newTokenAddress;
        registration.tokenId = newTokenId;

        _lockNft(msg.sender, newTokenAddress, newTokenId, 1);

        // update the delegatee's voting power based on new ERC1155 nft's multiplier
        _syncVotingPower(msg.sender, registration);
    }

    /**
     * @notice Update users' registration voting power.
     *
     * @dev Voting power is only updated for this block onward. See Council contract History.sol
     *      for more on how voting power is tracked and queried.
     *      Anybody can update up to 50 users' registration voting power.
     *
     * @param userAddresses             Array of addresses whose registration voting power this
     *                                  function updates.
     */
    function updateVotingPower(address[] memory userAddresses) public override {
        if (userAddresses.length > 50) revert NBV_ArrayTooManyElements();

        for (uint256 i = 0; i < userAddresses.length; ++i) {
            NFTBoostVaultStorage.Registration storage registration = _getRegistrations()[userAddresses[i]];
            _syncVotingPower(userAddresses[i], registration);
        }
    }

    // ===================================== ADMIN FUNCTIONALITY ========================================

    /**
     * @notice An onlyManager function for setting the multiplier value associated with an ERC1155
     *         contract address.
     *
     * @param tokenAddress              The address of the ERC1155 token to set the
     *                                  multiplier for.
     * @param tokenId                   The token id of the ERC1155 for which the multiplier is being set.
     * @param multiplierValue           The multiplier value corresponding to the token address and id.
     *
     */
    function setMultiplier(address tokenAddress, uint128 tokenId, uint128 multiplierValue) public override onlyManager {
        if (multiplierValue >= MAX_MULTIPLIER) revert NBV_MultiplierLimit();

        NFTBoostVaultStorage.AddressUintUint storage multiplierData = _getMultipliers()[tokenAddress][tokenId];
        // set multiplier value
        multiplierData.multiplier = multiplierValue;

        emit MultiplierSet(tokenAddress, tokenId, multiplierValue);
    }

    /**
     * @notice An Timelock only function for ERC20 allowing withdrawals.
     *
     * @dev Allows the timelock to unlock withdrawals. Cannot be reversed.
     */
    function unlock() external override onlyTimelock {
        if (getIsLocked() != 1) revert NBV_AlreadyUnlocked();
        Storage.set(Storage.uint256Ptr("locked"), 2);

        emit WithdrawalsUnlocked();
    }

    // ======================================= VIEW FUNCTIONS ===========================================

    /**
     * @notice Returns whether tokens can be withdrawn from the vault.
     *
     * @return locked                           Whether withdrawals are locked.
     */
    function getIsLocked() public view override returns (uint256) {
        return Storage.uint256Ptr("locked").data;
    }

    /**
     * @notice A function to access the storage of the nft's voting power multiplier.
     *
     * @param tokenAddress              The address of the ERC1155 token to set the
     *                                  multiplier for.
     * @param tokenId                   The token id of the ERC1155 for which the multiplier is being set.
     *
     * @return                          The token multiplier.
     */
    function getMultiplier(address tokenAddress, uint128 tokenId) public view override returns (uint256) {
        NFTBoostVaultStorage.AddressUintUint storage multiplierData = _getMultipliers()[tokenAddress][tokenId];

        // if a user does not specify a ERC1155 nft, their multiplier is set to 1
        if (tokenAddress == address(0) || tokenId == 0) {
            return 1e18;
        }

        return multiplierData.multiplier;
    }

    /**
     * @notice Getter for the registrations mapping.
     *
     * @param who                               The owner of the registration to query.
     *
     * @return registration                     Registration of the provided address.
     */
    function getRegistration(address who) external view override returns (NFTBoostVaultStorage.Registration memory) {
        return _getRegistrations()[who];
    }

    // =========================================== HELPERS ==============================================

    /**
     * @dev Grants the chosen delegate address voting power when a new user registers.
     *
     * @param delegatee                         The address to delegate the voting power associated
     *                                          with the Registration to.
     * @param newVotingPower                    Amount of votingPower associated with this Registration to
     *                                          be added to delegates existing votingPower.
     *
     */
    function _grantVotingPower(address delegatee, uint128 newVotingPower) internal {
        // update the delegatee's voting power
        History.HistoricalBalances memory votingPower = _votingPower();

        // loads the most recent timestamp of voting power for this delegate
        uint256 delegateeVotes = votingPower.loadTop(delegatee);

        // add block stamp indexed delegation power for this delegate to historical data array
        votingPower.push(delegatee, delegateeVotes + newVotingPower);
    }

    /**
     * @dev A single function endpoint for loading Registration storage
     *
     * @dev Only one Registration is allowed per user.
     *
     * @return registrations                 A storage mapping to look up registrations data
     */
    function _getRegistrations() internal pure returns (mapping(address => NFTBoostVaultStorage.Registration) storage) {
        // This call returns a storage mapping with a unique non overwrite-able storage location.
        return (NFTBoostVaultStorage.mappingAddressToRegistrationPtr("registrations"));
    }

    /**
     * @dev Helper to update a delegatee's voting power.
     *
     * @param who                        The address who's voting power we need to sync.
     *
     * @param registration               The storage pointer to the registration of that user.
     */
    function _syncVotingPower(address who, NFTBoostVaultStorage.Registration storage registration) internal {
        History.HistoricalBalances memory votingPower = _votingPower();
        uint256 delegateeVotes = votingPower.loadTop(registration.delegatee);

        uint256 newVotingPower = _currentVotingPower(registration);
        // get the change in voting power. Negative if the voting power is reduced
        int256 change = int256(newVotingPower) - int256(uint256(registration.latestVotingPower));

        // do nothing if there is no change
        if (change == 0) return;
        if (change > 0) {
            votingPower.push(registration.delegatee, delegateeVotes + uint256(change));
        } else {
            // if the change is negative, we multiply by -1 to avoid underflow when casting
            votingPower.push(registration.delegatee, delegateeVotes - uint256(change * -1));
        }

        registration.latestVotingPower = uint128(newVotingPower);

        emit VoteChange(who, registration.delegatee, change);
    }

    /**
     * @dev Calculates how much a user can withdraw.
     *
     * @param registration                The the memory location of the loaded registration.
     *
     * @return withdrawable               Amount which can be withdrawn.
     */
    function _getWithdrawableAmount(
        NFTBoostVaultStorage.Registration memory registration
    ) internal pure returns (uint256) {
        if (registration.withdrawn == registration.amount) {
            return 0;
        }

        uint256 withdrawable = registration.amount - registration.withdrawn;

        return withdrawable;
    }

    /**
     * @dev Helper that returns the current voting power of a registration.
     *
     * @dev This is not always the recorded voting power since it uses the latest multiplier.
     *
     * @param registration               The registration to check for voting power.
     *
     * @return                           The current voting power of the registration.
     */
    function _currentVotingPower(
        NFTBoostVaultStorage.Registration memory registration
    ) internal view virtual returns (uint256) {
        uint256 locked = registration.amount - registration.withdrawn;

        if (registration.tokenAddress != address(0) && registration.tokenId != 0) {
            return (locked * getMultiplier(registration.tokenAddress, registration.tokenId)) / MULTIPLIER_DENOMINATOR;
        }

        return locked;
    }

    /**
     * @dev A internal function for locking a user's ERC20 tokens in this contract
     *         for participation in governance. Calls the _lockNft function if a user
     *         has entered an ERC1155 token address and token id.
     *
     * @param from                      Address tokens are transferred from.
     * @param amount                    Amount of ERC20 tokens being transferred.
     * @param tokenAddress              Address of the ERC1155 token being transferred.
     * @param tokenId                   Id of the ERC1155 token being transferred.
     * @param nftAmount                 Amount of the ERC1155 token being transferred.
     */
    function _lockTokens(
        address from,
        uint256 amount,
        address tokenAddress,
        uint128 tokenId,
        uint128 nftAmount
    ) internal nonReentrant {
        token.transferFrom(from, address(this), amount);

        if (tokenAddress != address(0) && tokenId != 0) {
            _lockNft(from, tokenAddress, tokenId, nftAmount);
        }
    }

    /**
     * @dev A internal function for locking a user's ERC1155 token in this contract
     *         for participation in governance.
     *
     * @param from                      Address of owner token is transferred from.
     * @param tokenAddress              Address of the token being transferred.
     * @param tokenId                   Id of the token being transferred.
     * @param nftAmount                 Amount of token being transferred.
     */
    function _lockNft(address from, address tokenAddress, uint128 tokenId, uint128 nftAmount) internal nonReentrant {
        IERC1155(tokenAddress).safeTransferFrom(from, address(this), tokenId, nftAmount, bytes(""));
    }

    /** @dev A single function endpoint for loading storage for multipliers.
     *
     * @return                          A storage mapping which can be used to lookup a
     *                                  token's multiplier data and token id data.
     */
    function _getMultipliers()
        internal
        pure
        returns (mapping(address => mapping(uint128 => NFTBoostVaultStorage.AddressUintUint)) storage)
    {
        // This call returns a storage mapping with a unique non overwrite-able storage layout.
        return (NFTBoostVaultStorage.mappingAddressToPackedUintUint("multipliers"));
    }

    /** @dev A function to handles the receipt of a single ERC1155 token. This function is called
     *       at the end of a safeTransferFrom after the balance has been updated. To accept the transfer,
     *       this must return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))
     *
     * @return                          0xf23a6e61
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory) public virtual returns (bytes4) {
        return this.onERC1155Received.selector;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

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

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./external/council/libraries/History.sol";
import "./external/council/libraries/Storage.sol";

import "./libraries/HashedStorageReentrancyBlock.sol";

import "./interfaces/IBaseVotingVault.sol";

import { BVV_NotManager, BVV_NotTimelock, BVV_ZeroAddress } from "./errors/Governance.sol";

/**
 * @title BaseVotingVault
 * @author Non-Fungible Technologies, Inc.
 *
 * This contract is a base voting vault contract for use with Arcade voting vaults.
 * It includes basic voting vault functions like querying vote power, setting
 * the timelock and manager addresses, and getting the contracts token balance.
 */
abstract contract BaseVotingVault is HashedStorageReentrancyBlock, IBaseVotingVault {
    // ======================================== STATE ==================================================

    // Bring libraries into scope
    using History for History.HistoricalBalances;

    // ============================================ STATE ===============================================

    /// @notice The token used for voting in this vault.
    IERC20 public immutable token;

    /// @notice Number of blocks after which history can be pruned.
    uint256 public immutable staleBlockLag;

    // ============================================ EVENTS ==============================================

    // Event to track delegation data
    event VoteChange(address indexed from, address indexed to, int256 amount);

    // ========================================== CONSTRUCTOR ===========================================

    /**
     * @notice Deploys a base voting vault, setting immutable values for the token
     *         and staleBlockLag.
     *
     * @param _token                     The external erc20 token contract.
     * @param _staleBlockLag             The number of blocks before which the delegation history is forgotten.
     */
    constructor(IERC20 _token, uint256 _staleBlockLag) {
        if (address(_token) == address(0)) revert BVV_ZeroAddress();

        token = _token;
        staleBlockLag = _staleBlockLag;
    }

    // ==================================== TIMELOCK FUNCTIONALITY ======================================

    /**
     * @notice Timelock-only timelock update function.
     * @dev Allows the timelock to update the timelock address.
     *
     * @param timelock_                  The new timelock.
     */
    function setTimelock(address timelock_) external onlyTimelock {
        Storage.set(Storage.addressPtr("timelock"), timelock_);
    }

    /**
     * @notice Timelock-only manager update function.
     * @dev Allows the timelock to update the manager address.
     *
     * @param manager_                   The new manager address.
     */
    function setManager(address manager_) external onlyTimelock {
        Storage.set(Storage.addressPtr("manager"), manager_);
    }

    // ======================================= VIEW FUNCTIONS ===========================================

    /**
     * @notice Loads the voting power of a user.
     *
     * @param user                       The address we want to load the voting power of.
     * @param blockNumber                Block number to query the user's voting power at.
     *
     * @return votes                     The number of votes.
     */
    function queryVotePower(address user, uint256 blockNumber, bytes calldata) external override returns (uint256) {
        // Get our reference to historical data
        History.HistoricalBalances memory votingPower = _votingPower();

        // Find the historical data and clear everything more than 'staleBlockLag' into the past
        return votingPower.findAndClear(user, blockNumber, block.number - staleBlockLag);
    }

    /**
     * @notice Loads the voting power of a user without changing state.
     *
     * @param user                       The address we want to load the voting power of.
     * @param blockNumber                Block number to query the user's voting power at.
     *
     * @return votes                     The number of votes.
     */
    function queryVotePowerView(address user, uint256 blockNumber) external view returns (uint256) {
        // Get our reference to historical data
        History.HistoricalBalances memory votingPower = _votingPower();

        // Find the historical datum
        return votingPower.find(user, blockNumber);
    }

    /**
     * @notice A function to access the storage of the timelock address.
     * @dev The timelock can access all functions with the onlyTimelock modifier.
     *
     * @return timelock                  The timelock address.
     */
    function timelock() public pure returns (address) {
        return _timelock().data;
    }

    /**
     * @notice A function to access the storage of the manager address.
     *
     * @dev The manager can access all functions with the onlyManager modifier.
     *
     * @return manager                   The manager address.
     */
    function manager() public pure returns (address) {
        return _manager().data;
    }

    // =========================================== HELPERS ==============================================

    /**
     * @notice A function to access the storage of the token value
     *
     * @return balance                    A struct containing the balance uint.
     */
    function _balance() internal pure returns (Storage.Uint256 storage) {
        return Storage.uint256Ptr("balance");
    }

    /**
     * @notice A function to access the storage of the timelock address.
     *
     * @dev The timelock can access all functions with the onlyTimelock modifier.
     *
     * @return timelock                   A struct containing the timelock address.
     */
    function _timelock() internal pure returns (Storage.Address memory) {
        return Storage.addressPtr("timelock");
    }

    /**
     * @notice A function to access the storage of the manager address.
     *
     * @dev The manager can access all functions with the onlyManager modifier.
     *
     * @return manager                    A struct containing the manager address.
     */
    function _manager() internal pure returns (Storage.Address memory) {
        return Storage.addressPtr("manager");
    }

    /**
     * @notice Returns the historical voting power tracker.
     *
     * @return votingPower              Historical voting power tracker.
     */
    function _votingPower() internal pure returns (History.HistoricalBalances memory) {
        // This call returns a storage mapping with a unique non overwrite-able storage location.
        return (History.load("votingPower"));
    }

    /**
     * @notice Modifier to check that the caller is the manager.
     */
    modifier onlyManager() {
        if (msg.sender != manager()) revert BVV_NotManager();

        _;
    }

    /**
     * @notice Modifier to check that the caller is the timelock.
     */
    modifier onlyTimelock() {
        if (msg.sender != timelock()) revert BVV_NotTimelock();

        _;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title GovernanceErrors
 * @author Non-Fungible Technologies, Inc.
 *
 * This file contains custom errors for the Arcade governance vault contracts. All errors
 * are prefixed by the contract that throws them (e.g., "NBV_" for NFTBoostVault).
 * Errors located in one place to make it possible to holistically look at all
 * governance failure cases.
 */

// ======================================== NFT BOOST VAULT ==========================================
/// @notice All errors prefixed with NBV_, to separate from other contracts in governance.

/**
 * @notice Ensure caller ERC1155 token ownership for NFTBoostVault operations.
 *
 */
error NBV_DoesNotOwn();

/**
 * @notice Ensure caller has not already registered.
 */
error NBV_HasRegistration();

/**
 * @notice Ensure delegatee is not already registered as the delegate in user's Registration.
 */
error NBV_AlreadyDelegated();

/**
 * @notice Contract balance has to be bigger than amount being withdrawn.
 */
error NBV_InsufficientBalance();

/**
 * @notice Withdrawable tokens less than withdraw request amount.
 *
 * @param withdrawable              The returned withdrawable amount from
 *                                  a user's registration.
 */
error NBV_InsufficientWithdrawableBalance(uint256 withdrawable);

/**
 * @notice Multiplier limit exceeded.
 */
error NBV_MultiplierLimit();

/**
 * @notice No multiplier has been set for token.
 */
error NBV_NoMultiplierSet();

/**
 * @notice The provided token address and token id are invalid.
 *
 * @param tokenAddress              The token address provided.
 * @param tokenId                   The token id provided.
 */
error NBV_InvalidNft(address tokenAddress, uint256 tokenId);

/**
 * @notice User is calling withdraw() with zero amount.
 */
error NBV_ZeroAmount();

/**
 * @notice Cannot pass zero address as an address parameter.
 */
error NBV_ZeroAddress();

/**
 * @notice Provided addresses array holds more than 50 addresses.
 */
error NBV_ArrayTooManyElements();

/** @notice NFT Boost Voting Vault has already been unlocked.
 */
error NBV_AlreadyUnlocked();

/**
 * @notice ERC20 withdrawals from NFT Boost Voting Vault are frozen.
 */
error NBV_Locked();

// =================================== FROZEN LOCKING VAULT =====================================
/// @notice All errors prefixed with FLV_, to separate from other contracts in governance.

/**
 * @notice Withdraws from vault are frozen.
 */
error FLV_WithdrawsFrozen();

// ==================================== VESTING VOTING VAULT ======================================
/// @notice All errors prefixed with AVV_, to separate from other contracts in governance.

/**
 * @notice Block number parameters used to create a grant are invalid. Check that the start time is
 *         before the cliff, and the cliff is before the expiration.
 */
error AVV_InvalidSchedule();

/**
 * @notice Cliff amount should be less than the grant amount.
 */
error AVV_InvalidCliffAmount();

/**
 * @notice Insufficient balance to carry out the transaction.
 *
 * @param amountAvailable           The amount available in the vault.
 */
error AVV_InsufficientBalance(uint256 amountAvailable);

/**
 * @notice Grant has already been created for specified user.
 */
error AVV_HasGrant();

/**
 * @notice Grant has not been created for the specified user.
 */
error AVV_NoGrantSet();

/**
 * @notice Tokens cannot be claimed before the cliff.
 *
 * @param cliffBlock                The block number when grant claims begin.
 */
error AVV_CliffNotReached(uint256 cliffBlock);

/**
 * @notice Tokens cannot be re-delegated to the same address.
 */
error AVV_AlreadyDelegated();

/**
 * @notice Cannot withdraw zero tokens.
 */
error AVV_InvalidAmount();

/**
 * @notice Cannot pass zero address as an address parameter.
 */
error AVV_ZeroAddress();

// ==================================== IMMUTABLE VESTING VAULT ======================================

/**
 * @notice Grants cannot be revoked from the immutable vesting vault.
 */
error IVV_ImmutableGrants();

// ====================================== BASE VOTING VAULT ======================================

/**
 * @notice Caller is not the manager.
 */
error BVV_NotManager();

/**
 * @notice Caller is not the timelock.
 */
error BVV_NotTimelock();

/**
 * @notice Cannot pass zero address as an address parameter.
 */
error BVV_ZeroAddress();

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

import "./Storage.sol";

// This library is an assembly optimized storage library which is designed
// to track timestamp history in a struct which uses hash derived pointers.
// WARNING - Developers using it should not access the underlying storage
// directly since we break some assumptions of high level solidity. Please
// note this library also increases the risk profile of memory manipulation
// please be cautious in your usage of uninitialized memory structs and other
// anti patterns.
library History {
    // The storage layout of the historical array looks like this
    // [(128 bit min index)(128 bit length)] [0][0] ... [(64 bit block num)(192 bit data)] .... [(64 bit block num)(192 bit data)]
    // We give the option to the invoker of the search function the ability to clear
    // stale storage. To find data we binary search for the block number we need
    // This library expects the blocknumber indexed data to be pushed in ascending block number
    // order and if data is pushed with the same blocknumber it only retains the most recent.
    // This ensures each blocknumber is unique and contains the most recent data at the end
    // of whatever block it indexes [as long as that block is not the current one].

    // A struct which wraps a memory pointer to a string and the pointer to storage
    // derived from that name string by the storage library
    // WARNING - For security purposes never directly construct this object always use load
    struct HistoricalBalances {
        string name;
        // Note - We use bytes32 to reduce how easy this is to manipulate in high level sol
        bytes32 cachedPointer;
    }

    /// @notice The method by which inheriting contracts init the HistoricalBalances struct
    /// @param name The name of the variable. Note - these are globals, any invocations of this
    ///             with the same name work on the same storage.
    /// @return The memory pointer to the wrapper of the storage pointer
    function load(string memory name)
        internal
        pure
        returns (HistoricalBalances memory)
    {
        mapping(address => uint256[]) storage storageData =
            Storage.mappingAddressToUnit256ArrayPtr(name);
        bytes32 pointer;
        assembly {
            pointer := storageData.slot
        }
        return HistoricalBalances(name, pointer);
    }

    /// @notice An unsafe method of attaching the cached ptr in a historical balance memory objects
    /// @param pointer cached pointer to storage
    /// @return storageData A storage array mapping pointer
    /// @dev PLEASE DO NOT USE THIS METHOD WITHOUT SERIOUS REVIEW. IF AN EXTERNAL ACTOR CAN CALL THIS WITH
    //       ARBITRARY DATA THEY MAY BE ABLE TO OVERWRITE ANY STORAGE IN THE CONTRACT.
    function _getMapping(bytes32 pointer)
        private
        pure
        returns (mapping(address => uint256[]) storage storageData)
    {
        assembly {
            storageData.slot := pointer
        }
    }

    /// @notice This function adds a block stamp indexed piece of data to a historical data array
    ///         To prevent duplicate entries if the top of the array has the same blocknumber
    ///         the value is updated instead
    /// @param wrapper The wrapper which hold the reference to the historical data storage pointer
    /// @param who The address which indexes the array we need to push to
    /// @param data The data to append, should be at most 192 bits and will revert if not
    function push(
        HistoricalBalances memory wrapper,
        address who,
        uint256 data
    ) internal {
        // Check preconditions
        // OoB = Out of Bounds, short for contract bytecode size reduction
        require(data <= type(uint192).max, "OoB");
        // Get the storage this is referencing
        mapping(address => uint256[]) storage storageMapping =
            _getMapping(wrapper.cachedPointer);
        // Get the array we need to push to
        uint256[] storage storageData = storageMapping[who];
        // We load the block number and then shift it to be in the top 64 bits
        uint256 blockNumber = block.number << 192;
        // We combine it with the data, because of our require this will have a clean
        // top 64 bits
        uint256 packedData = blockNumber | data;
        // Load the array length
        (uint256 minIndex, uint256 length) = _loadBounds(storageData);
        // On the first push we don't try to load
        uint256 loadedBlockNumber = 0;
        if (length != 0) {
            (loadedBlockNumber, ) = _loadAndUnpack(storageData, length - 1);
        }
        // The index we push to, note - we use this pattern to not branch the assembly
        uint256 index = length;
        // If the caller is changing data in the same block we change the entry for this block
        // instead of adding a new one. This ensures each block numb is unique in the array.
        if (loadedBlockNumber == block.number) {
            index = length - 1;
        }
        // We use assembly to write our data to the index
        assembly {
            // Stores packed data in the equivalent of storageData[length]
            sstore(
                add(
                    // The start of the data slots
                    add(storageData.slot, 1),
                    // index where we store
                    index
                ),
                packedData
            )
        }
        // Reset the boundaries if they changed
        if (loadedBlockNumber != block.number) {
            _setBounds(storageData, minIndex, length + 1);
        }
    }

    /// @notice Loads the most recent timestamp of delegation power
    /// @param wrapper The memory struct which we want to search for historical data
    /// @param who The user who's balance we want to load
    /// @return the top slot of the array
    function loadTop(HistoricalBalances memory wrapper, address who)
        internal
        view
        returns (uint256)
    {
        // Load the storage pointer
        uint256[] storage userData = _getMapping(wrapper.cachedPointer)[who];
        // Load the length
        (, uint256 length) = _loadBounds(userData);
        // If it's zero no data has ever been pushed so we return zero
        if (length == 0) {
            return 0;
        }
        // Load the current top
        (, uint256 storedData) = _loadAndUnpack(userData, length - 1);
        // and return it
        return (storedData);
    }

    /// @notice Finds the data stored with the highest block number which is less than or equal to a provided
    ///         blocknumber.
    /// @param wrapper The memory struct which we want to search for historical data
    /// @param who The address which indexes the array to be searched
    /// @param blocknumber The blocknumber we want to load the historical data of
    /// @return The loaded unpacked data at this point in time.
    function find(
        HistoricalBalances memory wrapper,
        address who,
        uint256 blocknumber
    ) internal view returns (uint256) {
        // Get the storage this is referencing
        mapping(address => uint256[]) storage storageMapping =
            _getMapping(wrapper.cachedPointer);
        // Get the array we need to push to
        uint256[] storage storageData = storageMapping[who];
        // Pre load the bounds
        (uint256 minIndex, uint256 length) = _loadBounds(storageData);
        // Search for the blocknumber
        (, uint256 loadedData) =
            _find(storageData, blocknumber, 0, minIndex, length);
        // In this function we don't have to change the stored length data
        return (loadedData);
    }

    /// @notice Finds the data stored with the highest blocknumber which is less than or equal to a provided block number
    ///         Opportunistically clears any data older than staleBlock which is possible to clear.
    /// @param wrapper The memory struct which points to the storage we want to search
    /// @param who The address which indexes the historical data we want to search
    /// @param blocknumber The blocknumber we want to load the historical state of
    /// @param staleBlock A block number which we can [but are not obligated to] delete history older than
    /// @return The found data
    function findAndClear(
        HistoricalBalances memory wrapper,
        address who,
        uint256 blocknumber,
        uint256 staleBlock
    ) internal returns (uint256) {
        // Get the storage this is referencing
        mapping(address => uint256[]) storage storageMapping =
            _getMapping(wrapper.cachedPointer);
        // Get the array we need to push to
        uint256[] storage storageData = storageMapping[who];
        // Pre load the bounds
        (uint256 minIndex, uint256 length) = _loadBounds(storageData);
        // Search for the blocknumber
        (uint256 staleIndex, uint256 loadedData) =
            _find(storageData, blocknumber, staleBlock, minIndex, length);
        // We clear any data in the stale region
        // Note - Since find returns 0 if no stale data is found and we use > instead of >=
        //        this won't trigger if no stale data is found. Plus it won't trigger on minIndex == staleIndex
        //        == maxIndex and clear the whole array.
        if (staleIndex > minIndex) {
            // Delete the outdated stored info
            _clear(minIndex, staleIndex, storageData);
            // Reset the array info with stale index as the new minIndex
            _setBounds(storageData, staleIndex, length);
        }
        return (loadedData);
    }

    /// @notice Searches for the data stored at the largest blocknumber index less than a provided parameter.
    ///         Allows specification of a expiration stamp and returns the greatest examined index which is
    ///         found to be older than that stamp.
    /// @param data The stored data
    /// @param blocknumber the blocknumber we want to load the historical data for.
    /// @param staleBlock The oldest block that we care about the data stored for, all previous data can be deleted
    /// @param startingMinIndex The smallest filled index in the array
    /// @param length the length of the array
    /// @return Returns the largest stale data index seen or 0 for no seen stale data and the stored data
    function _find(
        uint256[] storage data,
        uint256 blocknumber,
        uint256 staleBlock,
        uint256 startingMinIndex,
        uint256 length
    ) private view returns (uint256, uint256) {
        // We explicitly revert on the reading of memory which is uninitialized
        require(length != 0, "uninitialized");
        // Do some correctness checks
        require(staleBlock <= blocknumber);
        require(startingMinIndex < length);
        // Load the bounds of our binary search
        uint256 maxIndex = length - 1;
        uint256 minIndex = startingMinIndex;
        uint256 staleIndex = 0;

        // We run a binary search on the block number fields in the array between
        // the minIndex and maxIndex. If we find indexes with blocknumber < staleBlock
        // we set staleIndex to them and return that data for an optional clearing step
        // in the calling function.
        while (minIndex != maxIndex) {
            // We use the ceil instead of the floor because this guarantees that
            // we pick the highest blocknumber less than or equal the requested one
            uint256 mid = (minIndex + maxIndex + 1) / 2;
            // Load and unpack the data in the midpoint index
            (uint256 pastBlock, uint256 loadedData) = _loadAndUnpack(data, mid);

            //  If we've found the exact block we are looking for
            if (pastBlock == blocknumber) {
                // Then we just return the data
                return (staleIndex, loadedData);

                // Otherwise if the loaded block is smaller than the block number
            } else if (pastBlock < blocknumber) {
                // Then we first check if this is possibly a stale block
                if (pastBlock < staleBlock) {
                    // If it is we mark it for clearing
                    staleIndex = mid;
                }
                // We then repeat the search logic on the indices greater than the midpoint
                minIndex = mid;

                // In this case the pastBlock > blocknumber
            } else {
                // We then repeat the search on the indices below the midpoint
                maxIndex = mid - 1;
            }
        }

        // We load at the final index of the search
        (uint256 _pastBlock, uint256 _loadedData) =
            _loadAndUnpack(data, minIndex);
        // This will only be hit if a user has misconfigured the stale index and then
        // tried to load father into the past than has been preserved
        require(_pastBlock <= blocknumber, "Search Failure");
        return (staleIndex, _loadedData);
    }

    /// @notice Clears storage between two bounds in array
    /// @param oldMin The first index to set to zero
    /// @param newMin The new minimum filled index, ie clears to index < newMin
    /// @param data The storage array pointer
    function _clear(
        uint256 oldMin,
        uint256 newMin,
        uint256[] storage data
    ) private {
        // Correctness checks on this call
        require(oldMin <= newMin);
        // This function is private and trusted and should be only called by functions which ensure
        // that oldMin < newMin < length
        assembly {
            // The layout of arrays in solidity is [length][data]....[data] so this pointer is the
            // slot to write to data
            let dataLocation := add(data.slot, 1)
            // Loop through each index which is below new min and clear the storage
            // Note - Uses strict min so if given an input like oldMin = 5 newMin = 5 will be a no op
            for {
                let i := oldMin
            } lt(i, newMin) {
                i := add(i, 1)
            } {
                // store at the starting data pointer + i 256 bits of zero
                sstore(add(dataLocation, i), 0)
            }
        }
    }

    /// @notice Loads and unpacks the block number index and stored data from a data array
    /// @param data the storage array
    /// @param i the index to load and unpack
    /// @return (block number, stored data)
    function _loadAndUnpack(uint256[] storage data, uint256 i)
        private
        view
        returns (uint256, uint256)
    {
        // This function is trusted and should only be called after checking data lengths
        // we use assembly for the sload to avoid reloading length.
        uint256 loaded;
        assembly {
            loaded := sload(add(add(data.slot, 1), i))
        }
        // Unpack the packed 64 bit block number and 192 bit data field
        return (
            loaded >> 192, // block number of the data
            loaded &
                0x0000000000000000ffffffffffffffffffffffffffffffffffffffffffffffff // the data
        );
    }

    /// @notice This function sets our non standard bounds data field where a normal array
    ///         would have length
    /// @param data the pointer to the storage array
    /// @param minIndex The minimum non stale index
    /// @param length The length of the storage array
    function _setBounds(
        uint256[] storage data,
        uint256 minIndex,
        uint256 length
    ) private {
        // Correctness check
        require(minIndex < length);

        assembly {
            // Ensure data cleanliness
            let clearedLength := and(
                length,
                0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff
            )
            // We move the min index into the top 128 bits by shifting it left by 128 bits
            let minInd := shl(128, minIndex)
            // We pack the data using binary or
            let packed := or(minInd, clearedLength)
            // We store in the packed data in the length field of this storage array
            sstore(data.slot, packed)
        }
    }

    /// @notice This function loads and unpacks our packed min index and length for our custom storage array
    /// @param data The pointer to the storage location
    /// @return minInd the first filled index in the array
    /// @return length the length of the array
    function _loadBounds(uint256[] storage data)
        private
        view
        returns (uint256 minInd, uint256 length)
    {
        // Use assembly to manually load the length storage field
        uint256 packedData;
        assembly {
            packedData := sload(data.slot)
        }
        // We use a shift right to clear out the low order bits of the data field
        minInd = packedData >> 128;
        // We use a binary and to extract only the bottom 128 bits
        length =
            packedData &
            0x00000000000000000000000000000000ffffffffffffffffffffffffffffffff;
    }
}

// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.3;

// This library allows for secure storage pointers across proxy implementations
// It will return storage pointers based on a hashed name and type string.
library Storage {
    // This library follows a pattern which if solidity had higher level
    // type or macro support would condense quite a bit.

    // Each basic type which does not support storage locations is encoded as
    // a struct of the same name capitalized and has functions 'load' and 'set'
    // which load the data and set the data respectively.

    // All types will have a function of the form 'typename'Ptr('name') -> storage ptr
    // which will return a storage version of the type with slot which is the hash of
    // the variable name and type string. This pointer allows easy state management between
    // upgrades and overrides the default solidity storage slot system.

    /// @dev The address type container
    struct Address {
        address data;
    }

    /// @notice A function which turns a variable name for a storage address into a storage
    ///         pointer for its container.
    /// @param name the variable name
    /// @return data the storage pointer
    function addressPtr(string memory name)
        internal
        pure
        returns (Address storage data)
    {
        bytes32 typehash = keccak256("address");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /// @notice A function to load an address from the container struct
    /// @param input the storage pointer for the container
    /// @return the loaded address
    function load(Address storage input) internal view returns (address) {
        return input.data;
    }

    /// @notice A function to set the internal field of an address container
    /// @param input the storage pointer to the container
    /// @param to the address to set the container to
    function set(Address storage input, address to) internal {
        input.data = to;
    }

    /// @dev The uint256 type container
    struct Uint256 {
        uint256 data;
    }

    /// @notice A function which turns a variable name for a storage uint256 into a storage
    ///         pointer for its container.
    /// @param name the variable name
    /// @return data the storage pointer
    function uint256Ptr(string memory name)
        internal
        pure
        returns (Uint256 storage data)
    {
        bytes32 typehash = keccak256("uint256");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /// @notice A function to load an uint256 from the container struct
    /// @param input the storage pointer for the container
    /// @return the loaded uint256
    function load(Uint256 storage input) internal view returns (uint256) {
        return input.data;
    }

    /// @notice A function to set the internal field of a unit256 container
    /// @param input the storage pointer to the container
    /// @param to the address to set the container to
    function set(Uint256 storage input, uint256 to) internal {
        input.data = to;
    }

    /// @notice Returns the storage pointer for a named mapping of address to uint256
    /// @param name the variable name for the pointer
    /// @return data the mapping pointer
    function mappingAddressToUnit256Ptr(string memory name)
        internal
        pure
        returns (mapping(address => uint256) storage data)
    {
        bytes32 typehash = keccak256("mapping(address => uint256)");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /// @notice Returns the storage pointer for a named mapping of address to uint256[]
    /// @param name the variable name for the pointer
    /// @return data the mapping pointer
    function mappingAddressToUnit256ArrayPtr(string memory name)
        internal
        pure
        returns (mapping(address => uint256[]) storage data)
    {
        bytes32 typehash = keccak256("mapping(address => uint256[])");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /// @notice Allows external users to calculate the slot given by this lib
    /// @param typeString the string which encodes the type
    /// @param name the variable name
    /// @return the slot assigned by this lib
    function getPtr(string memory typeString, string memory name)
        external
        pure
        returns (uint256)
    {
        bytes32 typehash = keccak256(abi.encodePacked(typeString));
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        return (uint256)(offset);
    }

    // A struct which represents 1 packed storage location with a compressed
    // address and uint96 pair
    struct AddressUint {
        address who;
        uint96 amount;
    }

    /// @notice Returns the storage pointer for a named mapping of address to uint256[]
    /// @param name the variable name for the pointer
    /// @return data the mapping pointer
    function mappingAddressToPackedAddressUint(string memory name)
        internal
        pure
        returns (mapping(address => AddressUint) storage data)
    {
        bytes32 typehash = keccak256("mapping(address => AddressUint)");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

interface IBaseVotingVault {
    function queryVotePower(address user, uint256 blockNumber, bytes calldata extraData) external returns (uint256);

    function queryVotePowerView(address user, uint256 blockNumber) external view returns (uint256);

    function setTimelock(address timelock_) external;

    function setManager(address manager_) external;

    function timelock() external pure returns (address);

    function manager() external pure returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../libraries/NFTBoostVaultStorage.sol";

interface INFTBoostVault {
    /**
     * @notice Events
     */
    event MultiplierSet(address tokenAddress, uint128 tokenId, uint128 multiplier);
    event WithdrawalsUnlocked();

    /**
     * @notice View functions
     */
    function getIsLocked() external view returns (uint256);

    function getRegistration(address who) external view returns (NFTBoostVaultStorage.Registration memory);

    function getMultiplier(address tokenAddress, uint128 tokenId) external view returns (uint256);

    /**
     * @notice NFT boost vault functionality
     */
    function addNftAndDelegate(
        address user,
        uint128 amount,
        uint128 tokenId,
        address tokenAddress,
        address delegatee
    ) external;

    function delegate(address to) external;

    function withdraw(uint128 amount) external;

    function addTokens(uint128 amount) external;

    function withdrawNft() external;

    function updateNft(uint128 newTokenId, address newTokenAddress) external;

    function updateVotingPower(address[] memory userAddresses) external;

    /**
     * @notice Only Manager function
     */
    function setMultiplier(address tokenAddress, uint128 tokenId, uint128 multiplierValue) external;

    /**
     * @notice Only Timelock function
     */
    function unlock() external;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

import "../external/council/libraries/History.sol";
import "../external/council/libraries/Storage.sol";

/**
 * @title HashedStorageReentrancyBlock
 * @author Non-Fungible Technologies, Inc.
 *
 * Helper contract to prevent reentrancy attacks using hashed storage. This contract is used
 * to protect against reentrancy attacks in the Arcade voting vault contracts.
 */
abstract contract HashedStorageReentrancyBlock {
    // =========================================== HELPERS ==============================================

    /**
     * @dev Returns the storage pointer to the entered state variable.
     *
     * @return Storage              pointer to the entered state variable.
     */
    function _entered() internal pure returns (Storage.Uint256 memory) {
        return Storage.uint256Ptr("entered");
    }

    // ========================================= MODIFIERS =============================================

    /**
     * @dev Re-entrancy guard modifier using hashed storage.
     */
    modifier nonReentrant() {
        Storage.Uint256 memory entered = _entered();
        // Check the state variable before the call is entered
        require(entered.data == 1, "REENTRANCY");

        // Store that the function has been entered
        entered.data = 2;

        // Run the function code
        _;

        // Clear the state
        entered.data = 1;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.18;

/**
 * @title NFTBoostVaultStorage
 * @author Non-Fungible Technologies, Inc.
 *
 * Contract based on Council's `Storage.sol` with modified scope to match the NFTBoostVault
 * requirements. This library allows for secure storage pointers across proxy
 * implementations and will return storage pointers based on a hashed name and type string.
 */
library NFTBoostVaultStorage {
    /**
    * This library follows a pattern which if solidity had higher level
    * type or macro support would condense quite a bit.

    * Each basic type which does not support storage locations is encoded as
    * a struct of the same name capitalized and has functions 'load' and 'set'
    * which load the data and set the data respectively.

    * All types will have a function of the form 'typename'Ptr('name') -> storage ptr
    * which will return a storage version of the type with slot which is the hash of
    * the variable name and type string. This pointer allows easy state management between
    * upgrades and overrides the default solidity storage slot system.
    */

    /// @dev struct which represents 1 packed storage location (Registration)
    struct Registration {
        uint128 amount; // token amount
        uint128 latestVotingPower;
        uint128 withdrawn; // amount of tokens withdrawn from voting vault
        uint128 tokenId; // ERC1155 token id
        address tokenAddress; // the address of the ERC1155 token
        address delegatee;
    }

    /// @dev represents 1 packed storage location with a compressed uint128 pair
    struct AddressUintUint {
        uint128 tokenId;
        uint128 multiplier;
    }

    /**
     * @notice Returns the storage pointer for a named mapping of address to registration data
     *
     * @param name                      The variable name for the pointer.
     *
     * @return data                     The mapping pointer.
     */
    function mappingAddressToRegistrationPtr(
        string memory name
    ) internal pure returns (mapping(address => Registration) storage data) {
        bytes32 typehash = keccak256("mapping(address => Registration)");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }

    /**
     * @notice Returns the storage pointer for a named mapping of address to uint128 pair
     *
     * @param name                      The variable name for the pointer.
     *
     * @return data                     The mapping pointer.
     */
    function mappingAddressToPackedUintUint(
        string memory name
    ) internal pure returns (mapping(address => mapping(uint128 => AddressUintUint)) storage data) {
        bytes32 typehash = keccak256("mapping(address => mapping(uint128 => AddressUintUint))");
        bytes32 offset = keccak256(abi.encodePacked(typehash, name));
        assembly {
            data.slot := offset
        }
    }
}