pragma solidity ^0.8.10;

import { IDataStructures } from './IDataStructures.sol';

// SPDX-License-Identifier: BUSL-1.1

interface IAccountManager {
    /// @dev Get LifecycleStatus of a KNOT by public key
    /// @param _blsPublicKey - Public Key of the Validator
    function blsPublicKeyToLifecycleStatus(bytes calldata _blsPublicKey) external view returns (IDataStructures.LifecycleStatus);

    /// @dev Get Account by public key
    /// @param _blsPublicKey - Public key of the validator
    function getAccountByPublicKey(bytes calldata _blsPublicKey) external view returns (IDataStructures.Account memory);

    /// @notice Get all last known state about a KNOT
    /// @param _blsPublicKey Public key of the validator
    function getLastKnownStateByPublicKey(bytes calldata _blsPublicKey) external view returns (IDataStructures.ETH2DataReport memory);

    /// @dev Get the number of deposits registered on this contract
    function numberOfAccounts() external view returns (uint256);

    /// @dev Get the specific Account from the Account array
    /// @param _index - Index of the account to be fetched
    function getAccount(uint256 _index) external view returns(IDataStructures.Account memory);

    /// @dev Get the block Account happened
    /// @param _blsPublicKey - public key of the user
    function getDepositBlock(bytes calldata _blsPublicKey) external view returns (uint256);

    /// @notice Returns the last known active balance for a KNOT that came from a balance reporting adaptor
    /// @param _blsPublicKey - public key of the validator
    function getLastKnownActiveBalance(bytes calldata _blsPublicKey) external view returns (uint64);

    /// @notice Returns the last report epoch for a KNOT that came from a balance reporting adaptor
    /// @param _blsPublicKey - public key of the validator
    function getLastReportEpoch(bytes calldata _blsPublicKey) external view returns (uint64);

    /// @dev External function to check if the derivative tokens were claimed
    /// @param _blsPublicKey - BLS public key used for validation
    function claimedTokens(bytes calldata _blsPublicKey) external view returns (bool);

    /// @notice Obtain the original BLS signature generated for the 32 ETH deposit to the Ethereum Foundation deposit contract
    function getSignatureByBLSKey(bytes calldata _blsPublicKey) external view returns (bytes memory);

    /// @dev Function to check if the key is already deposited
    /// @param _blsPublicKey - BLS public key of the validator
    function isKeyDeposited(bytes calldata _blsPublicKey) external view returns (bool);

    /// @dev Check if validator initials have been registered
    /// @param _blsPublicKey - BLS public key of the validator
    function areInitialsRegistered(bytes calldata _blsPublicKey) external view returns (bool);
}

pragma solidity ^0.8.10;

// SPDX-License-Identifier: BUSL-1.1

import { IDataStructures } from "./IDataStructures.sol";

interface IBalanceReporter {
    /// @notice Report an increased KNOT balance that has come from beacon chain inflation rewards
    /// @dev This method only cares about active balance increases when effective balance is 32 (otherwise a slashing or leaking is assumed to have happened)
    /// @param _stakeHouse Associated StakeHouse for the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    /// @param _eth2Report Beacon chain report for the given KNOT
    /// @param _signatureMetadata Signature over ETH2 data report ensuring the integrity of the data against a public node
    function balanceIncrease(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _signatureMetadata
    ) external;

    /// @notice When a KNOT has voluntarily withdrawn from the beacon chain, it can be reported here (for a healthy KNOT i.e. no bal reduction / slashing)
    /// @dev Assumption is that no slashing has happened and if it has, the appropriate slashing method should be called
    /// @param _stakeHouse Associated StakeHouse for the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    /// @param _eth2Report Beacon chain report for the given KNOT
    /// @param _signatureMetadata Authenticating the beacon chain report
    function voluntaryWithdrawal(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _signatureMetadata
    ) external;

    /// @dev Adaptor extension for reporting a balance reduction and or slashing
    /// @param _stakeHouse Associated StakeHouse for the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    /// @param _eth2Report Beacon chain report for the given KNOT
    /// @param _signatureMetadata Authenticating the beacon chain report
    function slash(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _signatureMetadata
    ) external;

    /// @notice Allows for reporting of a balance reduction of a validator that is still performing duties + topping up that SLOT at the same time
    /// @param _stakeHouse Associated StakeHouse for the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    /// @param _slasher Address slashing the validator's collateralised SLOT registry
    /// @param _buyAmount Amount of SLOT purchasing in the same transaction which is not the same as amount being slashed (dictated by latest balance)
    /// @param _eth2Report Beacon chain report for the given KNOT
    /// @param _signatureMetadata Authenticating the beacon chain report
    function slashAndTopUpSlot(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        address _slasher,
        uint256 _buyAmount,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _signatureMetadata
    ) external payable;

    /// @dev Adaptor extension for topping up slashed SLOT tokens
    /// @param _stakeHouse Associated StakeHouse for the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    /// @param _recipient - Address receiving the collateralised SLOT tokens
    /// @param _amount - Amount being bought
    function topUpSlashedSlot(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        address _recipient,
        uint256 _amount
    ) external payable;

    /// @notice for a healthy and active KNOT that wants to exit the StakeHouse universe and burn all their dETH and SLOT, use this method
    /// @dev This method assumes msg.sender owns all tokens
    /// @param _stakeHouse Associated StakeHouse for the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    /// @param _eth2Report Beacon chain report for the given KNOT
    /// @param _signatureMetadata Authenticating the beacon chain report
    function rageQuitKnot(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _signatureMetadata
    ) external payable;

    /// @notice for a healthy and active KNOT that wants to exit the StakeHouse universe and burn all their dETH and SLOT, use this method if multi party coordination is required via signatures
    /// @param _stakeHouse Address of the registry containing the KNOT
    /// @param _blsPublicKey BLS public key of the KNOT that is part of the house
    /// @param _ethRecipient Account that will be the recipient of the ETH that comes from the beacon chain balance of the BLS public key
    /// @param _eth2Report Beacon chain report containing the latest state of the KNOT
    /// @param _reportAndTokenHolderSignatures Signatures for report, free floating slot owner, savETH index owner and collateralised SLOT holders
    function multipartyRageQuit(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        address _ethRecipient,
        address _freeFloatingSlotOwner,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature[] calldata _reportAndTokenHolderSignatures
    ) external payable;

    /// @notice Allows a KNOT owner to manually top up a KNOT by sending ETH to the Ethereum Foundation deposit contract
    /// @param _blsPublicKey KNOT ID i.e. BLS public key of the validator
    function topUpKNOT(bytes calldata _blsPublicKey) external payable;
}

pragma solidity ^0.8.10;

// SPDX-License-Identifier: BUSL-1.1

interface IDataStructures {
    /// @dev Data structure used for ETH2 data reporting
    struct ETH2DataReport {
        bytes blsPublicKey; /// Public key of the validator
        bytes withdrawalCredentials; /// Withdrawal credentials submitted to the beacon chain
        bool slashed; /// Slashing status
        uint64 activeBalance; /// Validator active balance
        uint64 effectiveBalance; /// Validator effective balance
        uint64 exitEpoch; /// Exit epoch of the validator
        uint64 activationEpoch; /// Activation Epoch of the validator
        uint64 withdrawalEpoch; /// Withdrawal Epoch of the validator
        uint64 currentCheckpointEpoch; /// Epoch of the checkpoint during data reporting
    }

    /// @dev Signature over the hash of essential data
    struct EIP712Signature {
        // we are able to pack these two unsigned ints into a
        uint248 deadline; // deadline defined in ETH1 blocks
        uint8 v; // signature component 1
        bytes32 r; // signature component 2
        bytes32 s; // signature component 3
    }

    /// @dev Data Structure used for Accounts
    struct Account {
        address depositor; /// ECDSA address executing the deposit
        bytes blsSignature; /// BLS signature over the SSZ "DepositMessage" container
        uint256 depositBlock; /// Block During which the deposit to EF Deposit Contract was completed
    }

    /// @dev lifecycle status enumeration of the user
    enum LifecycleStatus {
        UNBEGUN,
        INITIALS_REGISTERED,
        DEPOSIT_COMPLETED,
        TOKENS_MINTED,
        EXITED
    }
}

pragma solidity ^0.8.10;

// SPDX-License-Identifier: BUSL-1.1

interface ISavETHManager {
    /// @notice Allows any account to create a savETH index in order to group KNOTs together that earn exclusive dETH rewards. The index will be owned by _owner
    /// @param _owner Address that will own the new index. ID of the index is auto generated and assigned to this account
    function createIndex(address _owner) external returns (uint256);

    /// @notice Allow an owner of an index to approve another account to transfer ownership (like a marketplace)
    /// @param _indexId ID of the index being approved
    /// @param _spender Authorised spender or zero address to clear approval
    function approveForIndexOwnershipTransfer(
        uint256 _indexId,
        address _spender
    ) external;

    /// @notice Transfer ownership of an index of KNOTs to a new owner
    /// @param _indexId ID of the index having ownership transferred
    /// @param _to Account receiving ownership of the index
    function transferIndexOwnership(uint256 _indexId, address _to) external;

    /// @notice Allows an index owner or KNOT spender to transfer ownership of a KNOT to another index
    /// @param _stakeHouse Registry that the KNOT is part of
    /// @param _blsPublicKey of the KNOT
    /// @param _newIndexId ID of the index receiving the KNOT
    function transferKnotToAnotherIndex(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        uint256 _newIndexId
    ) external;

    /// @notice Allows an index owner to approve a marketplace to transfer ownership of a KNOT from one index to another
    /// @param _stakeHouse Registry that the KNOT is part of
    /// @param _blsPublicKey of the KNOT
    /// @param _spender Account that can transfer the knot that is isolated within an index
    function approveSpendingOfKnotInIndex(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        address _spender
    ) external;

    /// @notice Move a KNOT that is part of an index into the open index in order to get access to the savETH <> dETH
    /// @param _stakeHouse Registry that the KNOT is part of
    /// @param _blsPublicKey of the KNOT
    /// @param _recipient Address receiving savETH
    function addKnotToOpenIndex(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        address _recipient
    ) external;

    /// @notice Given a KNOT that is part of the open index, allow a savETH holder to isolate the KNOT into their own index gaining exclusive rights to the network inflation rewards
    /// @param _stakeHouse Address of StakeHouse that the KNOT belongs to
    /// @param _blsPublicKey KNOT ID within the StakeHouse
    /// @param _targetIndexId ID of the index that the KNOT will be added to
    function isolateKnotFromOpenIndex(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        uint256 _targetIndexId
    ) external;

    /// @notice In a single transaction, add knot to open index and withdraw dETH in registry
    /// @param _stakeHouse Address of StakeHouse that the KNOT belongs to
    /// @param _blsPublicKey KNOT ID that belongs to an index
    /// @param _recipient Recipient of dETH tokens
    function addKnotToOpenIndexAndWithdraw(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        address _recipient
    ) external;

    /// @notice In a single transaction, deposit dETH and isolate a knot into an index
    /// @param _stakeHouse Address of StakeHouse that the KNOT belongs to
    /// @param _blsPublicKey KNOT ID that requires adding to an index
    /// @param _indexId ID of the index that the KNOT is being added into
    function depositAndIsolateKnotIntoIndex(
        address _stakeHouse,
        bytes calldata _blsPublicKey,
        uint256 _indexId
    ) external;

    /// @notice Allows a SaveETH holder to exchange some or all of their SaveETH for dETH
    /// @param _amount of SaveETH to burn
    function withdraw(address _recipient, uint128 _amount) external;

    /// @notice Deposit dETH in exchange for SaveETH
    /// @param _amount of dETH being deposited
    function deposit(address _recipient, uint128 _amount) external;

    /// @notice Total number of dETH rewards minted for knot from inflation rewards
    function dETHRewardsMintedForKnot(bytes calldata _blsPublicKey) external view returns (uint256);

    /// @notice Approved spender that can transfer ownership of a KNOT from one index to another (a marketplace for example)
    function approvedKnotSpender(bytes calldata _blsPublicKey) external view returns (address);

    /// @notice Approved spender that can transfer ownership of an entire index (a marketplace for example)
    function approvedIndexSpender(uint256 _indexId) external view returns (address);

    /// @notice Given an index identifier, returns the owner of the index or zero address if index not created
    function indexIdToOwner(uint256 _indexId) external view returns (address);

    /// @notice Total dETH isolated for a knot associated with an index. Returns zero if knot is not part of an index
    function knotDETHBalanceInIndex(uint256 _indexId, bytes calldata _blsPublicKey) external view returns (uint256);

    /// @notice ID of KNOT associated index. Zero if part of open index or non zero if part of a user-owned index
    function associatedIndexIdForKnot(bytes calldata _blsPublicKey) external view returns (uint256);

    /// @notice Returns true if KNOT is part of the open index where they can spend their savETH. Otherwise they are part of a user owned index
    function isKnotPartOfOpenIndex(bytes calldata _blsPublicKey) external view returns (bool);

    /// @notice Total number of dETH deposited into the open index that is not part of user owned indices
    function dETHUnderManagementInOpenIndex() external view returns (uint256);

    /// @notice Total number of dETH minted across all KNOTs
    function dETHInCirculation() external view returns (uint256);

    /// @notice Total amount of dETH isolated in user owned indices
    function totalDETHInIndices() external view returns (uint256);

    /// @notice Helper to convert dETH to savETH based on the current exchange rate
    function dETHToSavETH(uint256 _amount) external view returns (uint256);

    /// @notice Helper to convert savETH to dETH based on the current exchange rate
    function savETHToDETH(uint256 _amount) external view returns (uint256);

    /// @notice Address of the dETH token
    function dETHToken() external view returns (address);

    /// @notice Address of the savETH token
    function savETHToken() external view returns (address);
}

pragma solidity ^0.8.10;

// SPDX-License-Identifier: BUSL-1.1

interface ISlotSettlementRegistry {

    ////////////
    // Events //
    ////////////

    /// @notice Collateralised SLOT deducted from a collateralised SLOT owner
    event SlotSlashed(bytes memberId, uint256 amount);

    /// @notice Collateralised SLOT purchased from KNOT
    event SlashedSlotPurchased(bytes memberId, uint256 amount);

    /// @notice KNOT has exited the protocol exercising their redemption rights
    event RageQuitKnot(bytes memberId);

    event CollateralisedOwnerAddedToKnot(bytes knotId, address indexed owner);

    /// @notice User is able to trigger beacon chain withdrawal
    event UserEnabledForWithdrawal(address indexed user, bytes memberId);

    /// @notice User has withdrawn ETH from beacon chain - do not allow any more withdrawals
    event UserWithdrawn(address indexed user, bytes memberId);

    ////////////
    // View   //
    ////////////

    /// @notice Total collateralised SLOT owned by an account across all KNOTs in a given StakeHouse
    function totalUserCollateralisedSLOTBalanceInHouse(address _stakeHouse, address _user) external view returns (uint256);

    /// @notice Total collateralised SLOT owned by an account for a given KNOT in a Stakehouse
    function totalUserCollateralisedSLOTBalanceForKnot(address _stakeHouse, address _user, bytes calldata _blsPublicKey) external view returns (uint256);

    // @notice Given a KNOT and account, a flag represents whether the account has been a collateralised SLOT owner at some point in the past
    function isCollateralisedOwner(bytes calldata blsPublicKey, address _user) external view returns (bool);

    /// @notice If a user account has been able to rage quit a KNOT, this flag is set to true to allow beacon chain funds to be claimed
    function isUserEnabledForKnotWithdrawal(address _user, bytes calldata _blsPublicKey) external view returns (bool);

    /// @notice Once beacon chain funds have been redeemed, this flag is set to true in order to block double withdrawals
    function userWithdrawn(address _user, bytes calldata _blsPublicKey) external view returns (bool);

    /// @notice Total number of collateralised SLOT owners for a given KNOT
    /// @param _blsPublicKey BLS public key of the KNOT
    function numberOfCollateralisedSlotOwnersForKnot(bytes calldata _blsPublicKey) external view returns (uint256);

    /// @notice Fetch a collateralised SLOT owner address for a specific KNOT at a specific index
    function getCollateralisedOwnerAtIndex(bytes calldata _blsPublicKey, uint256 _index) external view returns (address);

    /// @dev Get the sum of total collateralized SLOT balances for multiple sETH tokens for specific owner
    /// @param _sETHList List of sETH token addresses from different Stakehouses
    /// @param _owner Address that has an sETH token balance within the sETH list
    function getCollateralizedSlotAccumulation(address[] calldata _sETHList, address _owner) external view returns (uint256);

    /// @notice Total amount of SLOT that has been slashed but not topped up yet
    /// @param _blsPublicKey BLS public key of KNOT
    function currentSlashedAmountForKnot(bytes calldata _blsPublicKey) external view returns (uint256 currentSlashedAmount);

    /// @notice Total amount of collateralised sETH owned by an account for a given KNOT
    /// @param _stakeHouse Address of Stakehouse registry contract
    /// @param _user Collateralised SLOT owner address
    /// @param _blsPublicKey BLS pub key of the validator
    function totalUserCollateralisedSETHBalanceForKnot(
        address _stakeHouse,
        address _user,
        bytes calldata _blsPublicKey
    ) external view returns (uint256);

    /// @notice Total collateralised sETH owned by a user across all KNOTs in the house
    /// @param _stakeHouse Address of the Stakehouse registry
    /// @param _user Collateralised SLOT owner in house
    function totalUserCollateralisedSETHBalanceInHouse(
        address _stakeHouse,
        address _user
    ) external view returns (uint256);

    /// @notice The total collateralised sETH circulating for the house i.e. (8 * number of knots) - total slashed
    /// @param _stakeHouse Address of the Stakehouse registry in order to fetch its exchange rate
    function totalCollateralisedSETHForStakehouse(
        address _stakeHouse
    ) external view returns (uint256);

    /// @notice Minimum amount of collateralised sETH a user must hold at a house level in order to rage quit a healthy knot
    function sETHRedemptionThreshold(address _stakeHouse) external view returns (uint256);

    /// @notice Given the total SLOT in the house (8 * number of KNOTs), how much is in circulation when filtering out total slashed
    /// @param _stakeHouse Address of the Stakehouse registry
    function circulatingSlot(
        address _stakeHouse
    ) external view returns (uint256);

    /// @notice Given the total amount of collateralised SLOT in the house (4 * number of KNOTs), how much is in circulation when filtering out total slashed
    /// @param _stakeHouse Address of the Stakehouse registry
    function circulatingCollateralisedSlot(
        address _stakeHouse
    ) external view returns (uint256);

    /// @notice Amount of sETH required per SLOT at the house level in order to rage quit
    /// @param _stakeHouse Address of the Stakehouse registry in order to fetch its exchange rate
    function redemptionRate(address _stakeHouse) external view returns (uint256);

    /// @notice Amount of sETH per SLOT for a given house calculated as total dETH minted in house / total SLOT from all KNOTs
    /// @param _stakeHouse Address of the Stakehouse registry in order to fetch its exchange rate
    function exchangeRate(address _stakeHouse) external view returns (uint256);

    /// @notice Returns the address of the sETH token for a given Stakehouse registry
    function stakeHouseShareTokens(address _stakeHouse) external view returns (address);

    /// @notice Returns the address of the associated house for an sETH token
    function shareTokensToStakeHouse(address _sETHToken) external view returns (address);

    /// @notice Returns the total amount of SLOT slashed at the Stakehouse level
    function stakeHouseCurrentSLOTSlashed(address _stakeHouse) external view returns (uint256);

    /// @notice Returns the total amount of SLOT slashed for a KNOT
    function currentSlashedAmountOfSLOTForKnot(bytes calldata _blsPublicKey) external view returns (uint256);

    /// @notice Total dETH minted by adding knots and minting inflation rewards within a house
    function dETHMintedInHouse(address _stakeHouse) external view returns (uint256);

    /// @notice Total SLOT minted for all KNOTs that have not rage quit the house
    function activeSlotMintedInHouse(address _stakeHouse) external view returns (uint256);

    /// @notice Total collateralised SLOT minted for all KNOTs that have not rage quit the house
    function activeCollateralisedSlotMintedInHouse(address _stakeHouse) external view returns (uint256);

    /// @notice Helper for calculating an active sETH balance from a SLOT amount
    /// @param _stakeHouse Target Stakehouse registry - each has their own exchange rate
    /// @param _slotAmount SLOT amount in wei
    function sETHForSLOTBalance(address _stakeHouse, uint256 _slotAmount) external view returns (uint256);

    /// @notice Helper for calculating a SLOT balance from an sETH amount
    /// @param _stakeHouse Target Stakehouse registry - each has their own exchange rate
    /// @param _sETHAmount sETH amount in wei
    function slotForSETHBalance(address _stakeHouse, uint256 _sETHAmount) external view returns (uint256);

}

pragma solidity ^0.8.10;

// SPDX-License-Identifier: BUSL-1.1

interface IStakeHouseRegistry {

    ////////////
    // Events //
    ////////////

    /// @notice A new member was added to the registry
    event MemberAdded(uint256 indexed knotIndex);

    /// @notice A member was kicked due to an action in another core module
    event MemberKicked(uint256 indexed knotIndex);

    /// @notice A member decided that they did not want to be part of the protocol
    event MemberRageQuit(uint256 indexed knotIndex);

    ////////////
    // View   //
    ////////////

    /// @notice number of members of a StakeHouse
    function numberOfMemberKNOTs() external view returns (uint256);

    /// @notice Total number of KNOTs that have rage quit from the house
    function numberOfRageQuitKnots() external view returns (uint256);

    /// @notice Total number of KNOTs that have been kicked from the house
    function numberOfKickedKnots() external view returns (uint256);

    /// @notice View for establishing if a future validator is allowed to become a member of a Stakehouse
    /// @param _blsPubKey of the validator registered on the beacon chain
    function isMemberPermitted(bytes calldata _blsPubKey) external view returns (bool);

    /// @notice total number of KNOTs in the house that have not rage quit
    function numberOfActiveKNOTsThatHaveNotRageQuit() external view returns (uint256);

    /// @notice Allows an external entity to check if a member is part of a stake house
    /// @param _memberId Bytes of the public key of the member
    function isActiveMember(bytes calldata _memberId) external returns (bool);

    /// @notice Check if a member is part of the registry but not rage quit (this ignores whether they have been kicked)
    /// @param _memberId Bytes of the public key of the member
    function hasMemberRageQuit(bytes calldata _memberId) external view returns (bool);

    /// @notice Get all info about a member at its assigned index
    function getMemberInfoAtIndex(uint256 _memberKNOTIndex) external view returns (
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint16 flags,           // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    );

    /// @notice Get all info about a member given its unique ID (validator pub key)
    function getMemberInfo(bytes memory _memberId) external view returns (
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint16 flags,           // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    );

    ////////////
    // Modify //
    ////////////

    /// @notice Called by house owner to set up a gate keeper smart contracts used when adding members
    /// @param _gateKeeper Address of gate keeper contract that will perform member checks. Set to zero to disable
    function setGateKeeper(address _gateKeeper) external;
}

pragma solidity ^0.8.10;

// SPDX-License-Identifier: BUSL-1.1

interface IStakeHouseUniverse {

    ////////////
    // Events //
    ////////////

    /// @notice Emitted when all of the core modules are initialised
    event CoreModulesInit();

    /// @notice Emitted after a Stakehouse has been deployed. A share token and brand are also deployed
    event NewStakeHouse(address indexed stakeHouse, uint256 indexed brandId);

    /// @notice Emitted after a member is added to an existing Stakehouse
    event MemberAddedToExistingStakeHouse(address indexed stakeHouse);

    /// @notice Emitted after a member is added to an existing house but a brand was created
    event MemberAddedToExistingStakeHouseAndBrandCreated(address indexed stakeHouse, uint256 indexed brandId);

    ////////////
    // View   //
    ////////////

    /// @notice Number of StakeHouses in the universe
    function numberOfStakeHouses() external view returns (uint256);

    /// @notice Returns the address of a StakeHouse assigned to an index
    /// @param _index Query which must be greater than zero
    function stakeHouseAtIndex(uint256 _index) external view returns (address);

    /// @notice number of members of a StakeHouse (aggregate number of KNOTs)
    /// @dev This enumerable method is used along with `numberOfStakeHouses`
    /// @param _index of a StakeHouse
    /// @return uint256 The number of total KNOTs / members of a StakeHouse
    function numberOfSubKNOTsAtIndex(uint256 _index) external view returns (uint256);

    /// @notice Given a StakeHouse index and a member index (i.e. coordinates to a member), return the member ID
    /// @param _index Coordinate assigned to Stakehouse
    /// @param _subIndex Coordinate assigned to a member of a Stakehouse
    function subKNOTAtIndexCoordinates(uint256 _index, uint256 _subIndex) external view returns (bytes memory);

    /// @notice Get all info about a StakeHouse KNOT (a member a.k.a a validator) given index coordinates
    /// @param _index StakeHouse index
    /// @param _subIndex Member index within the StakeHouse
    function stakeHouseKnotInfoGivenCoordinates(uint256 _index, uint256 _subIndex) external view returns (
        address stakeHouse,     // Address of registered StakeHouse
        address sETHAddress,    // Address of sETH address associated with StakeHouse
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint256 flags,          // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    );

    // @notice Get all info about a StakeHouse KNOT (a member a.k.a a validator)
    /// @param _blsPublicKey ID of member (Validator public key) assigned to StakeHouse
    function stakeHouseKnotInfo(bytes calldata _blsPublicKey) external view returns (
        address stakeHouse,     // Address of registered StakeHouse
        address sETHAddress,    // Address of sETH address associated with StakeHouse
        address applicant,      // Address of ETH account that added the member to the StakeHouse
        uint256 knotMemberIndex,// KNOT Index of the member within the StakeHouse
        uint256 flags,          // Flags associated with the member
        bool isActive           // Whether the member is active or knot
    );

    /// @notice Returns the address of the Stakehouse that a KNOT is associated with
    function memberKnotToStakeHouse(bytes calldata _blsPublicKey) external view returns (address);
}

pragma solidity ^0.8.10;

import { IDataStructures } from './IDataStructures.sol';

// SPDX-License-Identifier: BUSL-1.1

interface ITransactionRouter {
    /// @notice Fetch representative to representee status
    /// @param _user - User checked for representation
    /// @param _representative - Address representing the user
    function userToRepresentativeStatus(address _user, address _representative) external view returns (bool);

    /// @notice Signaling added representative
    event RepresentativeAdded(address indexed user, address indexed representative);

    /// @notice Signaling removed representative
    event RepresentativeRemoved(address indexed user, address indexed representative);

    /// @notice Select representative address to perform staking actions for you
    /// @param _representative - Address representing the user in the staking process
    /// @param _enabled Whether they are being activated or deactivated
    function authorizeRepresentative(address _representative, bool _enabled) external;

    /// @notice First user interaction in the process of registering validator
    /// @param _user - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _blsPublicKey - BLS public key of the validator
    function registerValidatorInitials(
        address _user, bytes calldata _blsPublicKey, bytes calldata _blsSignature
    ) external;

    /// @notice function to register the ETH2 validator by depositing 32ETH to EF deposit contract
    /// @param _user - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _blsPublicKey - BLS validation public key
    /// @param _ciphertext - Encryption packet for disaster recovery
    /// @param _aesEncryptorKey - Randomly generated AES key used for BLS signing key encryption
    /// @param _encryptionSignature - ECDSA signature used for encryption validity, issued by committee
    /// @param _dataRoot - Root of the DepositMessage SSZ container
    function registerValidator(
        address _user,
        bytes calldata _blsPublicKey,
        bytes calldata _ciphertext,
        bytes calldata _aesEncryptorKey,
        IDataStructures.EIP712Signature calldata _encryptionSignature,
        bytes32 _dataRoot
    ) external payable;

    /// @notice Adapter call to core for stakehouse creation
    /// @notice Direct extension for the function in AccountManager
    /// @param _user - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _blsPublicKey - BLS public key of the validator
    /// @param _ticker - Ticker of the stakehouse to be created
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _user
    /// @param _eth2Report - ETH2 data report for self-validation
    /// @param _reportSignature - ECDSA signature used for data validity proof by committee
    function createStakehouse(
        address _user,
        bytes calldata _blsPublicKey,
        string calldata _ticker,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) external;

    /// @notice Join the house and get derivative tokens
    /// @notice Direct extension for the function in AccountManager
    /// @param _user - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _eth2Report - ETH2 data report for self-validation
    /// @param _stakehouse - stakehouse address to join
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _user
    /// @param _blsPublicKey - BLS public key of the validator
    /// @param _reportSignature - ECDSA signature used for data validity proof by committee
    function joinStakehouse(
        address _user,
        bytes calldata _blsPublicKey,
        address _stakehouse,
        uint256 _brandTokenId,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) external;

    /// @notice Join the house and get derivative tokens + create the brand
    /// @notice Direct extension for the function in AccountManager
    /// @param _user - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _blsPublicKey - BLS public key of the validator
    /// @param _ticker - Ticker of the stakehouse
    /// @param _stakehouse - Stakehouse address the user wants to join
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _user
    /// @param _eth2Report - ETH2 data report for self-validation
    /// @param _reportSignature - ECDSA signature used for data validity proof by committee
    function joinStakeHouseAndCreateBrand(
        address _user,
        bytes calldata _blsPublicKey,
        string calldata _ticker,
        address _stakehouse,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) external;

    /// @notice Enable a user that has deposited through checkpoint A to exit via an escape hatch before even minting their derivative tokens
    /// @param _blsPublicKey Validator public key
    /// @param _stakehouse House to rage quit against
    /// @param _eth2Report Beacon chain report showing last known state of the validator
    /// @param _reportSignature Signature over the ETH 2 data report packet
    function rageQuitPostDeposit(
        address _user,
        bytes calldata _blsPublicKey,
        address _stakehouse,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) external;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: BUSL-1.1

/// @dev Library containing constants independent of network
library GeneralConstants {

    /// @dev Deposit amount required to form a knot (validator) inside the protocol
    uint256 constant DEPOSIT_AMOUNT = 32 ether;

    /// @dev Consensus-reward base token mint
    uint256 constant DETH_MINTED_AMOUNT = 24 ether;

    /// @dev SLOT Tokens collect network fees such as gas fees, MEV rewards, etc.
    uint256 constant SLOT_MINTED_AMOUNT = 8 ether;
}

/// @dev Library containing address constants for the Ethereum mainnet
library MainnetConstants {

    /// @dev chain id of the Ethereum mainnet
    uint256 constant CHAIN_ID = 1;

    /// @dev AccountManager address in the Ethereum mainnet
    address constant AccountManager = 0xDd6E67942a9566A70446f7400a21240C5f71377C;

    /// @dev SavETHManager address in the Ethereum mainnet
    address constant SavETHManager = 0x9CbC2Bf747510731eE3A38bf209a299261038369;

    /// @dev SlotSettlementRegistry address in the Ethereum mainnet
    address constant SlotSettlementRegistry = 0xC01DC3c7F83B12CFdF6C0AAa09c880EB45c48569;

    /// @dev StakeHouseUniverse address in the Ethereum mainnet
    address constant StakeHouseUniverse = 0xC6306C52ea0405D3630249f202751aE3043056bd;

    /// @dev TransactionRouter address in the Ethereum mainnet
    address constant TransactionRouter = 0x03F4310bfE3968934bC11DfA17B8DF809D7DEA80;

    /// @dev dETH address in the Ethereum mainnet
    address constant dETH = 0x3d1E5Cf16077F349e999d6b21A4f646e83Cd90c5;
}

/// @dev Library containing address constants for the Goerli network
library GoerliConstants {

    /// @dev chain id of the Goerli network
    uint256 constant CHAIN_ID = 5;

    /// @dev AccountManager address in the Goerli network
    address constant AccountManager = 0x952295078A226bF40c8cb076C16E0e7229F77B28;

    /// @dev SavETHManager address in the Goerli network
    address constant SavETHManager = 0x9Ef3Bb02CadA3e332Bbaa27cd750541c5FFb5b03;

    /// @dev SlotSettlementRegistry address in the Goerli network
    address constant SlotSettlementRegistry = 0x1a86d0FE29c57e19f340C5Af34dE82946F22eC5d;

    /// @dev StakeHouseUniverse address in the Goerli network
    address constant StakeHouseUniverse = 0xC38ee0eCc213293757dC5a30Cf253D3f40726E4c;

    /// @dev TransactionRouter address in the Goerli network
    address constant TransactionRouter = 0xc4b44383C15E4afeD9845393b215a75D44D3d24B;

    /// @dev dETH address in the Goerli network
    address constant dETH = 0x506C2B850D519065a4005b04b9ceed946A64CB6F;
}

pragma solidity ^0.8.0;

// SPDX-License-Identifier: BUSL-1.1

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

pragma solidity ^0.8.0;

// SPDX-License-Identifier: BUSL-1.1

import { IERC20 } from "./IERC20.sol";
import { ISavETHManager } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/ISavETHManager.sol";
import { IAccountManager } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IAccountManager.sol";
import { IBalanceReporter } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IBalanceReporter.sol";
import { ISlotSettlementRegistry } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/ISlotSettlementRegistry.sol";
import { IStakeHouseRegistry } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IStakeHouseRegistry.sol";
import { IStakeHouseUniverse } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IStakeHouseUniverse.sol";
import { ITransactionRouter } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/ITransactionRouter.sol";

import { MainnetConstants, GoerliConstants } from "./Constants.sol";

/// @title Implementable Stakehouse protocol smart contract consumer without worrying about the interfaces or addresses
abstract contract StakehouseAPI {

    /// @dev Get the interface connected to the AccountManager smart contract
    function getAccountManager() internal view virtual returns (IAccountManager accountManager) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            accountManager = IAccountManager(MainnetConstants.AccountManager);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            accountManager = IAccountManager(GoerliConstants.AccountManager);
        }

        else {
            _unsupported();
        }
    }

    /// @dev Get the interface connected to the Balance Reporter smart contract
    function getBalanceReporter() internal view virtual returns (IBalanceReporter balanceReporter) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            balanceReporter = IBalanceReporter(MainnetConstants.TransactionRouter);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            balanceReporter = IBalanceReporter(GoerliConstants.TransactionRouter);
        }

        else {
            _unsupported();
        }
    }

    /// @dev Get the interface connected to the savETH registry adaptor smart contract
    function getSavETHRegistry() internal view virtual returns (ISavETHManager savETHManager) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            savETHManager = ISavETHManager(MainnetConstants.SavETHManager);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            savETHManager = ISavETHManager(GoerliConstants.SavETHManager);
        }

        else {
            _unsupported();
        }
    }

    /// @dev Get the interface connected to the SLOT registry smart contract
    function getSlotRegistry() internal view virtual returns (ISlotSettlementRegistry slotSettlementRegistry) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            slotSettlementRegistry = ISlotSettlementRegistry(MainnetConstants.SlotSettlementRegistry);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            slotSettlementRegistry = ISlotSettlementRegistry(GoerliConstants.SlotSettlementRegistry);
        }

        else {
            _unsupported();
        }
    }

    /// @dev Get the interface connected to an arbitrary Stakehouse registry smart contract
    function getStakeHouseRegistry(address _stakeHouse) internal view virtual returns (IStakeHouseRegistry stakehouse) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            stakehouse = IStakeHouseRegistry(_stakeHouse);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            stakehouse = IStakeHouseRegistry(_stakeHouse);
        }

        else {
            _unsupported();
        }
    }

    /// @dev Get the interface connected to the Stakehouse universe smart contract
    function getStakeHouseUniverse() internal view virtual returns (IStakeHouseUniverse universe) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            universe = IStakeHouseUniverse(MainnetConstants.StakeHouseUniverse);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            universe = IStakeHouseUniverse(GoerliConstants.StakeHouseUniverse);
        }

        else {
            _unsupported();
        }
    }

    /// @dev Get the interface connected to the Transaction Router adaptor smart contract
    function getTransactionRouter() internal view virtual returns (ITransactionRouter transactionRouter) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            transactionRouter = ITransactionRouter(MainnetConstants.TransactionRouter);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            transactionRouter = ITransactionRouter(GoerliConstants.TransactionRouter);
        }

        else {
            _unsupported();
        }
    }

    /// @notice Get the dETH instance
    function getDETH() internal view virtual returns (IERC20 dETH) {
        uint256 chainId = _getChainId();

        if(chainId == MainnetConstants.CHAIN_ID) {
            dETH = IERC20(MainnetConstants.dETH);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            dETH = IERC20(GoerliConstants.dETH);
        }

        else {
            _unsupported();
        }
    }

    /// @dev If the network does not match one of the choices stop the flow
    function _unsupported() internal pure {
        revert('Network unsupported');
    }

    /// @dev Helper function to get the id of the current chain
    function _getChainId() internal view returns (uint256 chainId) {
        assembly {
            chainId := chainid()
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeaconUpgradeable.sol";
import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../../utils/AddressUpgradeable.sol";
import "../../utils/StorageSlotUpgradeable.sol";
import "../utils/Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "../../interfaces/draft-IERC1822Upgradeable.sol";
import "../ERC1967/ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate that the this implementation remains valid after an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract PausableUpgradeable is Initializable, ContextUpgradeable {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    function __Pausable_init() internal onlyInitializing {
        __Pausable_init_unchained();
    }

    function __Pausable_init_unchained() internal onlyInitializing {
        _paused = false;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        require(paused(), "Pausable: not paused");
        _;
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20Upgradeable.sol";
import "./extensions/IERC20MetadataUpgradeable.sol";
import "../../utils/ContextUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
contract ERC20Upgradeable is Initializable, ContextUpgradeable, IERC20Upgradeable, IERC20MetadataUpgradeable {
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
    function __ERC20_init(string memory name_, string memory symbol_) internal onlyInitializing {
        __ERC20_init_unchained(name_, symbol_);
    }

    function __ERC20_init_unchained(string memory name_, string memory symbol_) internal onlyInitializing {
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
        _approve(owner, spender, _allowances[owner][spender] + addedValue);
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
        uint256 currentAllowance = _allowances[owner][spender];
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
     * @dev Spend `amount` form the allowance of `owner` toward `spender`.
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

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[45] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./draft-IERC20PermitUpgradeable.sol";
import "../ERC20Upgradeable.sol";
import "../../../utils/cryptography/draft-EIP712Upgradeable.sol";
import "../../../utils/cryptography/ECDSAUpgradeable.sol";
import "../../../utils/CountersUpgradeable.sol";
import "../../../proxy/utils/Initializable.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20PermitUpgradeable is Initializable, ERC20Upgradeable, IERC20PermitUpgradeable, EIP712Upgradeable {
    using CountersUpgradeable for CountersUpgradeable.Counter;

    mapping(address => CountersUpgradeable.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    function __ERC20Permit_init(string memory name) internal onlyInitializing {
        __EIP712_init_unchained(name, "1");
        __ERC20Permit_init_unchained(name);
    }

    function __ERC20Permit_init_unchained(string memory) internal onlyInitializing {
        _PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSAUpgradeable.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        CountersUpgradeable.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20MetadataUpgradeable is IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
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
library CountersUpgradeable {
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSAUpgradeable.sol";
import "../../proxy/utils/Initializable.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712Upgradeable is Initializable {
    /* solhint-disable var-name-mixedcase */
    bytes32 private _HASHED_NAME;
    bytes32 private _HASHED_VERSION;
    bytes32 private constant _TYPE_HASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    function __EIP712_init(string memory name, string memory version) internal onlyInitializing {
        __EIP712_init_unchained(name, version);
    }

    function __EIP712_init_unchained(string memory name, string memory version) internal onlyInitializing {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        return _buildDomainSeparator(_TYPE_HASH, _EIP712NameHash(), _EIP712VersionHash());
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSAUpgradeable.toTypedDataHash(_domainSeparatorV4(), structHash);
    }

    /**
     * @dev The hash of the name parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712NameHash() internal virtual view returns (bytes32) {
        return _HASHED_NAME;
    }

    /**
     * @dev The hash of the version parameter for the EIP712 domain.
     *
     * NOTE: This function reads from storage by default, but can be redefined to return a constant value if gas costs
     * are a concern.
     */
    function _EIP712VersionHash() internal virtual view returns (bytes32) {
        return _HASHED_VERSION;
    }

    /**
     * This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../StringsUpgradeable.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSAUpgradeable {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", StringsUpgradeable.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library StringsUpgradeable {
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
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822Proxiable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/beacon/BeaconProxy.sol)

pragma solidity ^0.8.0;

import "./IBeacon.sol";
import "../Proxy.sol";
import "../ERC1967/ERC1967Upgrade.sol";

/**
 * @dev This contract implements a proxy that gets the implementation address for each call from an {UpgradeableBeacon}.
 *
 * The beacon address is stored in storage slot `uint256(keccak256('eip1967.proxy.beacon')) - 1`, so that it doesn't
 * conflict with the storage layout of the implementation behind the proxy.
 *
 * _Available since v3.4._
 */
contract BeaconProxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the proxy with `beacon`.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon. This
     * will typically be an encoded function call, and allows initializing the storage of the proxy like a Solidity
     * constructor.
     *
     * Requirements:
     *
     * - `beacon` must be a contract with the interface {IBeacon}.
     */
    constructor(address beacon, bytes memory data) payable {
        _upgradeBeaconToAndCall(beacon, data, false);
    }

    /**
     * @dev Returns the current beacon address.
     */
    function _beacon() internal view virtual returns (address) {
        return _getBeacon();
    }

    /**
     * @dev Returns the current implementation address of the associated beacon.
     */
    function _implementation() internal view virtual override returns (address) {
        return IBeacon(_getBeacon()).implementation();
    }

    /**
     * @dev Changes the proxy to use a new beacon. Deprecated: see {_upgradeBeaconToAndCall}.
     *
     * If `data` is nonempty, it's used as data in a delegate call to the implementation returned by the beacon.
     *
     * Requirements:
     *
     * - `beacon` must be a contract.
     * - The implementation returned by `beacon` must be a contract.
     */
    function _setBeacon(address beacon, bytes memory data) internal virtual {
        _upgradeBeaconToAndCall(beacon, data, false);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeacon {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (proxy/ERC1967/ERC1967Proxy.sol)

pragma solidity ^0.8.0;

import "../Proxy.sol";
import "./ERC1967Upgrade.sol";

/**
 * @dev This contract implements an upgradeable proxy. It is upgradeable because calls are delegated to an
 * implementation address that can be changed. This address is stored in storage in the location specified by
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967], so that it doesn't conflict with the storage layout of the
 * implementation behind the proxy.
 */
contract ERC1967Proxy is Proxy, ERC1967Upgrade {
    /**
     * @dev Initializes the upgradeable proxy with an initial implementation specified by `_logic`.
     *
     * If `_data` is nonempty, it's used as data in a delegate call to `_logic`. This will typically be an encoded
     * function call, and allows initializing the storage of the proxy like a Solidity constructor.
     */
    constructor(address _logic, bytes memory _data) payable {
        _upgradeToAndCall(_logic, _data, false);
    }

    /**
     * @dev Returns the current implementation address.
     */
    function _implementation() internal view virtual override returns (address impl) {
        return ERC1967Upgrade._getImplementation();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "../beacon/IBeacon.sol";
import "../../interfaces/draft-IERC1822.sol";
import "../../utils/Address.sol";
import "../../utils/StorageSlot.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967Upgrade {
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlot.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822Proxiable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlot.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlot.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlot.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(Address.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            Address.isContract(IBeacon(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlot.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            Address.functionDelegateCall(IBeacon(newBeacon).implementation(), data);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/Proxy.sol)

pragma solidity ^0.8.0;

/**
 * @dev This abstract contract provides a fallback function that delegates all calls to another contract using the EVM
 * instruction `delegatecall`. We refer to the second contract as the _implementation_ behind the proxy, and it has to
 * be specified by overriding the virtual {_implementation} function.
 *
 * Additionally, delegation to the implementation can be triggered manually through the {_fallback} function, or to a
 * different contract through the {_delegate} function.
 *
 * The success and return data of the delegated call will be returned back to the caller of the proxy.
 */
abstract contract Proxy {
    /**
     * @dev Delegates the current call to `implementation`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _delegate(address implementation) internal virtual {
        assembly {
            // Copy msg.data. We take full control of memory in this inline assembly
            // block because it will not return to Solidity code. We overwrite the
            // Solidity scratch pad at memory position 0.
            calldatacopy(0, 0, calldatasize())

            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), implementation, 0, calldatasize(), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 {
                revert(0, returndatasize())
            }
            default {
                return(0, returndatasize())
            }
        }
    }

    /**
     * @dev This is a virtual function that should be overridden so it returns the address to which the fallback function
     * and {_fallback} should delegate.
     */
    function _implementation() internal view virtual returns (address);

    /**
     * @dev Delegates the current call to the address returned by `_implementation()`.
     *
     * This function does not return to its internal call site, it will return directly to the external caller.
     */
    function _fallback() internal virtual {
        _beforeFallback();
        _delegate(_implementation());
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if no other
     * function in the contract matches the call data.
     */
    fallback() external payable virtual {
        _fallback();
    }

    /**
     * @dev Fallback function that delegates calls to the address returned by `_implementation()`. Will run if call data
     * is empty.
     */
    receive() external payable virtual {
        _fallback();
    }

    /**
     * @dev Hook that is called before falling back to the implementation. Can happen as part of a manual `_fallback`
     * call, or as part of the Solidity `fallback` or `receive` functions.
     *
     * If overridden should call `super._beforeFallback()`.
     */
    function _beforeFallback() internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

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
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!Address.isContract(address(this)) && _initialized == 1),
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
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
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
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initialized`
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Internal function that returns the initialized version. Returns `_initializing`
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

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
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
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
     * @dev Moves `amount` of tokens from `from` to `to`.
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
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

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
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
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
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

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
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
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
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
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
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
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
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
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
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
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
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

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
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlot {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IBrandCentral {
    /// @notice Address of the contract managing list of restricted tickers
    function claimAuction() external view returns (address);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IBrandNFT {
    /// @notice Return the address of the minting contract
    function brandCentral() external view returns (address);

    /// @notice Utility for converting string to lowercase equivalent
    function toLowerCase(string memory _base) external pure returns (string memory);

    /// @notice Get the token ID from a brand ticker
    function lowercaseBrandTickerToTokenId(string memory _ticker) external view returns (uint256);

    /// @notice Allow a brand owner to set their image and description which will surface in NFT explorers
    function setBrandMetadata(uint256 _tokenId, string calldata _description, string calldata _imageURI) external;

    /// @notice Vanilla ERC721 transfer function
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

interface ICIP {
    function applyForDecryption(
        bytes calldata _knotId,
        address _stakehouse,
        bytes calldata _aesPublicKey
    ) external;
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

/// @notice Required interface for gatekeeping whether a member is allowed in a Stakehouse registry, brand or anything else for that matter
interface IGateKeeper {
    /// @notice Called by the Stakehose registry or Community Central before adding a member to a house or brand
    /// @param _blsPubKey BLS public key of the KNOT being added to the Stakehouse registry or brand
    function isMemberPermitted(bytes calldata _blsPubKey) external view returns (bool);
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { LSDNFactory } from "../liquid-staking/LSDNFactory.sol";

interface IGiantMevAndFeesPool {
    function init(LSDNFactory _factory, address _lpDeployer, address _upgradeManager) external;
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { LSDNFactory } from "../liquid-staking/LSDNFactory.sol";

interface IGiantSavETHVaultPool {
    function init(
        LSDNFactory _factory,
        address _lpDeployer,
        address _feesAndMevGiantPool,
        address _upgradeManager
    ) external;
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

interface ILiquidStakingManager {

    function stakehouse() external view returns (address);

    /// @param _dao address of the DAO
    /// @param _syndicateFactory address of the syndicate factory
    /// @param _smartWalletFactory address of the smart wallet factory
    /// @param _lpTokenFactory LP token factory address required for deployment of savETH vault
    /// @param _stakehouseTicker 3-5 character long name for the stakehouse to be deployed
    function init(
        address _dao,
        address _syndicateFactory,
        address _smartWalletFactory,
        address _lpTokenFactory,
        address _brand,
        address _savETHVaultDeployer,
        address _stakingFundsVaultDeployer,
        address _optionalGatekeeperDeployer,
        uint256 _optionalCommission,
        bool _deployOptionalGatekeeper,
        string calldata _stakehouseTicker
    ) external;

    /// @notice function to check valid BLS public key for LSD network
    /// @param _blsPublicKeyOfKnot BLS public key to check validity for
    /// @return true if BLS public key is a part of LSD network, false otherwise
    function isBLSPublicKeyPartOfLSDNetwork(bytes calldata _blsPublicKeyOfKnot) external view returns (bool);

    /// @notice function to check if BLS public key registered with the network or has been withdrawn before staking
    /// @param _blsPublicKeyOfKnot BLS public key to check validity for
    /// @return true if BLS public key is banned, false otherwise
    function isBLSPublicKeyBanned(bytes calldata _blsPublicKeyOfKnot) external view returns (bool);
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

interface ILiquidStakingManagerChildContract {
    function liquidStakingManager() external view returns (address);
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

/// @dev Interface for initializing a newly deployed LP token
interface ILPTokenInit {
    function init(
        address _deployer,
        address _transferHookProcessor,
        string calldata tokenSymbol,
        string calldata tokenName
    ) external;
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { IDataStructures } from '@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol';

/// @notice Interface to necessary to operate a representative in stakehouse protocol
interface IRepresentative {

    /// @notice Get status about representative verification of the contract
    /// @param _representee - representeee address
    function isRepresentativeApproved(address _representee) external view returns (bool);

    /// @notice Register validator initials for the representative (initial interaction step)
    /// @param _representee - Representee address
    /// @param _blsPublicKey - BLS public key of the representee (knotId)
    /// @param _blsSignature - Signature over the SSZ DepositData container of the Representee
    function registerValidatorInitials(
        address _representee, bytes calldata _blsPublicKey, bytes calldata _blsSignature
    ) external;

    /// @notice Complete deposit for the representative (After initials were registered)
    /// @param _representee - Representee address
    /// @param _blsPublicKey - BLS validation public key
    /// @param _ciphertext - Encryption packet for disaster recovery
    /// @param _aesEncryptorKey - Randomly generated AES key used for BLS signing key encryption
    /// @param _encryptionSignature - ECDSA signature used for encryption validity, issued by committee
    /// @param _dataRoot - Root of the DepositMessage SSZ container
    function registerDeposit(
        address _representee,
        bytes calldata _blsPublicKey,
        bytes calldata _ciphertext,
        bytes calldata _aesEncryptorKey,
        IDataStructures.EIP712Signature calldata _encryptionSignature,
        bytes32 _dataRoot
    ) external payable;

    /// @notice Create stakehouse on behalf of representee
    /// @param _representee - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _blsPublicKey - BLS public key of the validator
    /// @param _ticker - Ticker of the stakehouse to be created
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _user
    /// @param _eth2Report - ETH2 data report for self-validation
    /// @param _reportSignature - ECDSA signature used for data validity proof by committee
    function createStakehouse(
        address _representee,
        bytes calldata _blsPublicKey,
        string calldata _ticker,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) external;

    /// @notice Join the house on behalf of representee and get derivative tokens
    /// @param _representee - User registering the stake for _blsPublicKey (managed by representative)
    /// @param _eth2Report - ETH2 data report for self-validation
    /// @param _stakehouse - stakehouse address to join
    /// @param _savETHIndexId ID of the savETH registry index that will receive savETH for the KNOT. Set to zero to create a new index owned by _user
    /// @param _blsPublicKey - BLS public key of the validator
    /// @param _reportSignature - ECDSA signature used for data validity proof by committee
    function joinStakehouse(
        address _representee,
        bytes calldata _blsPublicKey,
        address _stakehouse,
        uint256 _brandTokenId,
        uint256 _savETHIndexId,
        IDataStructures.ETH2DataReport calldata _eth2Report,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IRestrictedTickerRegistry {
    /// @notice Function for determining if a ticker is restricted for claiming or not
    function isRestrictedBrandTicker(string calldata _lowerTicker) external view returns (bool);
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

interface ISyndicateFactory {

    /// @notice Emitted when a new syndicate instance is deployed
    event SyndicateDeployed(address indexed implementation);

    /// @notice Deploy a new knot syndicate with an initial set of KNOTs registered with the syndicate
    /// @param _contractOwner Ethereum public key that will receive management rights of the contract
    /// @param _priorityStakingEndBlock Block number when priority sETH staking ends and anyone can stake
    /// @param _priorityStakers Optional list of addresses that will have priority for staking sETH against each knot registered
    /// @param _blsPubKeysForSyndicateKnots List of BLS public keys of Stakehouse protocol registered KNOTs participating in syndicate
    function deploySyndicate(
        address _contractOwner,
        uint256 _priorityStakingEndBlock,
        address[] calldata _priorityStakers,
        bytes[] calldata _blsPubKeysForSyndicateKnots
    ) external returns (address);

    /// @notice Helper function to calculate the address of a syndicate contract before it is deployed (CREATE2)
    /// @param _deployer Address of the account that will trigger the deployment of a syndicate contract
    /// @param _contractOwner Address of the account that will be the initial owner for parameter management and knot expansion
    /// @param _numberOfInitialKnots Number of initial knots that will be registered to the syndicate
    function calculateSyndicateDeploymentAddress(
        address _deployer,
        address _contractOwner,
        uint256 _numberOfInitialKnots
    ) external view returns (address);

    /// @notice Helper function to generate the CREATE2 salt required for deployment
    /// @param _deployer Address of the account that will trigger the deployment of a syndicate contract
    /// @param _contractOwner Address of the account that will be the initial owner for parameter management and knot expansion
    /// @param _numberOfInitialKnots Number of initial knots that will be registered to the syndicate
    function calculateDeploymentSalt(
        address _deployer,
        address _contractOwner,
        uint256 _numberOfInitialKnots
    ) external pure returns (bytes32);
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

/// @dev Interface for initializing a newly deployed Syndicate
interface ISyndicateInit {
    function initialize(
        address _contractOwner,
        uint256 _priorityStakingEndBlock,
        address[] memory _priorityStakers,
        bytes[] memory _blsPubKeysForSyndicateKnots
    ) external;
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

interface ITransferHookProcessor {
    function beforeTokenTransfer(address _from, address _to, uint256 _amount) external;
    function afterTokenTransfer(address _from, address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

interface IWETH {
    function withdraw(uint256 amount) external;

    function balanceOf(address user) view external returns(uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

interface Errors {
    // common
    error EmptyArray();
    error InconsistentArrayLength();
    error InvalidAmount();
    error InvalidBalance();
    error InvalidCaller();
    
    // GiantMevAndFeesPool
    error InvalidStakingFundsVault();
    error NoDerivativesMinted();
    error OutsideRange();
    error TokenMismatch();

    // GiantSavETHVaultPool
    error InvalidSavETHVault();
    error FeesAndMevPoolCannotMatch();
    error DETHNotReadyForWithdraw();
    error InvalidWithdrawlBatch();
    error NoCommonInterest();
    error ETHStakedOrDerivativesMinted();
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { StakehouseAPI } from "@blockswaplab/stakehouse-solidity-api/contracts/StakehouseAPI.sol";
import { IDataStructures } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol";

import { LPTokenFactory } from "./LPTokenFactory.sol";
import { LPToken } from "./LPToken.sol";

interface ILSM {
    function isBLSPublicKeyBanned(bytes calldata _blsPublicKey) external view returns (bool);
}

/// @dev For pools accepting ETH for validator staking, this contract will manage issuing LPs for deposits
abstract contract ETHPoolLPFactory is StakehouseAPI {

    /// @notice signalize withdrawing of ETH by depositor
    event ETHWithdrawnByDepositor(address depositor, uint256 amount);

    /// @notice signalize burning of LP token
    event LPTokenBurnt(bytes blsPublicKeyOfKnot, address token, address depositor, uint256 amount);

    /// @notice signalize issuance of new LP token
    event NewLPTokenIssued(bytes blsPublicKeyOfKnot, address token, address firstDepositor, uint256 amount);

    /// @notice signalize issuance of existing LP token
    event LPTokenMinted(bytes blsPublicKeyOfKnot, address token, address depositor, uint256 amount);

    /// @dev Base name and symbol used for deploying new LP tokens per KNOT
    string internal baseLPTokenName;
    string internal baseLPTokenSymbol;

    /// @notice count of unique LP tokens issued for ETH deposits
    uint256 public numberOfLPTokensIssued;

    /// @notice Maximum amount that can be staked per validator in WEI
    uint256 public maxStakingAmountPerValidator;

    /// @notice Minimum amount that can be staked per validator in WEI
    uint256 public constant MIN_STAKING_AMOUNT = 0.001 ether;

    /// @notice Factory for the deployment of KNOT<>LP Tokens that can be used to redeem dETH
    LPTokenFactory public lpTokenFactory;

    /// @notice LP token address deployed for a KNOT's BLS public key
    mapping(bytes => LPToken) public lpTokenForKnot;

    /// @notice KNOT BLS public key associated with the LP token
    mapping(LPToken => bytes) public KnotAssociatedWithLPToken;

    /// @notice Allow users to rotate the ETH from many LP to another in the event that a BLS key is never staked
    /// @param _oldLPTokens Array of old LP tokens to be burnt
    /// @param _newLPTokens Array of new LP tokens to be minted in exchange of old LP tokens
    /// @param _amounts Array of amount of tokens to be exchanged
    function batchRotateLPTokens(
        LPToken[] calldata _oldLPTokens,
        LPToken[] calldata _newLPTokens,
        uint256[] calldata _amounts
    ) external {
        uint256 numOfRotations = _oldLPTokens.length;
        require(numOfRotations > 0, "Empty arrays");
        require(numOfRotations == _newLPTokens.length, "Inconsistent arrays");
        require(numOfRotations == _amounts.length, "Inconsistent arrays");

        for (uint256 i; i < numOfRotations; ++i) {
            rotateLPTokens(
                _oldLPTokens[i],
                _newLPTokens[i],
                _amounts[i]
            );
        }
    }

    /// @notice Allow users to rotate the ETH from one LP token to another in the event that the BLS key is never staked
    /// @param _oldLPToken Instance of the old LP token (to be burnt)
    /// @param _newLPToken Instane of the new LP token (to be minted)
    /// @param _amount Amount of LP tokens to be rotated/converted from old to new
    function rotateLPTokens(LPToken _oldLPToken, LPToken _newLPToken, uint256 _amount) public {
        require(address(_oldLPToken) != address(0), "Zero address");
        require(address(_newLPToken) != address(0), "Zero address");
        require(_oldLPToken != _newLPToken, "Incorrect rotation to same token");
        require(_amount >= MIN_STAKING_AMOUNT, "Amount cannot be zero");
        require(_amount % MIN_STAKING_AMOUNT == 0, "Amount not multiple of min staking");
        require(_amount <= _oldLPToken.balanceOf(msg.sender), "Not enough balance");
        require(_oldLPToken.lastInteractedTimestamp(msg.sender) + 30 minutes < block.timestamp, "Liquidity is still fresh");
        require(_amount + _newLPToken.totalSupply() <= maxStakingAmountPerValidator, "Not enough mintable tokens");

        bytes memory blsPublicKeyOfPreviousKnot = KnotAssociatedWithLPToken[_oldLPToken];
        bytes memory blsPublicKeyOfNewKnot = KnotAssociatedWithLPToken[_newLPToken];

        require(blsPublicKeyOfPreviousKnot.length == 48, "Incorrect BLS public key");
        require(blsPublicKeyOfNewKnot.length == 48, "Incorrect BLS public key");

        require(
            getAccountManager().blsPublicKeyToLifecycleStatus(blsPublicKeyOfPreviousKnot) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
            "Lifecycle status must be one"
        );

        require(
            getAccountManager().blsPublicKeyToLifecycleStatus(blsPublicKeyOfNewKnot) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
            "Lifecycle status must be one"
        );

        // M-02
        ILSM manager = ILSM(_newLPToken.liquidStakingManager());
        require(!manager.isBLSPublicKeyBanned(blsPublicKeyOfNewKnot), "BLS public key is banned");

        // burn old tokens and mint new ones
        _oldLPToken.burn(msg.sender, _amount);
        emit LPTokenBurnt(blsPublicKeyOfPreviousKnot, address(_oldLPToken), msg.sender, _amount);

        _newLPToken.mint(msg.sender, _amount);
        emit LPTokenMinted(KnotAssociatedWithLPToken[_newLPToken], address(_newLPToken), msg.sender, _amount);
    }

    /// @dev Internal business logic for processing staking deposits for single or batch deposits
    function _depositETHForStaking(bytes calldata _blsPublicKeyOfKnot, uint256 _amount, bool _enableTransferHook) internal {
        require(_amount >= MIN_STAKING_AMOUNT, "Min amount not reached");
        require(_amount % MIN_STAKING_AMOUNT == 0, "Amount not multiple of min staking");
        require(_blsPublicKeyOfKnot.length == 48, "Invalid BLS public key");

        // LP token issued for the KNOT
        // will be zero for a new KNOT because the mapping doesn't exist
        LPToken lpToken = lpTokenForKnot[_blsPublicKeyOfKnot];
        if(address(lpToken) != address(0)) {
            // KNOT and it's LP token is already registered
            // mint the respective LP tokens for the user

            // total supply after minting the LP token must not exceed maximum staking amount per validator
            require(lpToken.totalSupply() + _amount <= maxStakingAmountPerValidator, "Amount exceeds the staking limit for the validator");

            // mint LP tokens for the depoistor with 1:1 ratio of LP tokens and ETH supplied
            lpToken.mint(msg.sender, _amount);
            emit LPTokenMinted(_blsPublicKeyOfKnot, address(lpToken), msg.sender, _amount);
        }
        else {
            // check that amount doesn't exceed max staking amount per validator
            require(_amount <= maxStakingAmountPerValidator, "Amount exceeds the staking limit for the validator");

            // mint new LP tokens for the new KNOT
            // add the KNOT in the mapping
            string memory tokenNumber = Strings.toString(numberOfLPTokensIssued);
            string memory tokenName = string(abi.encodePacked(baseLPTokenName, tokenNumber));
            string memory tokenSymbol = string(abi.encodePacked(baseLPTokenSymbol, tokenNumber));

            // deploy new LP token and optionally enable transfer notifications
            LPToken newLPToken = _enableTransferHook ?
                             LPToken(lpTokenFactory.deployLPToken(address(this), address(this), tokenSymbol, tokenName)) :
                             LPToken(lpTokenFactory.deployLPToken(address(this), address(0), tokenSymbol, tokenName));

            // increase the count of LP tokens
            numberOfLPTokensIssued++;

            // register the BLS Public Key with the LP token
            lpTokenForKnot[_blsPublicKeyOfKnot] = newLPToken;
            KnotAssociatedWithLPToken[newLPToken] = _blsPublicKeyOfKnot;

            // mint LP tokens for the depoistor with 1:1 ratio of LP tokens and ETH supplied
            newLPToken.mint(msg.sender, _amount);
            emit NewLPTokenIssued(_blsPublicKeyOfKnot, address(newLPToken), msg.sender, _amount);
        }
    }
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ITransferHookProcessor } from "../interfaces/ITransferHookProcessor.sol";

contract GiantLP is ERC20 {
    uint256 constant MIN_TRANSFER_AMOUNT = 0.001 ether;

    /// @notice Address of giant pool that deployed the giant LP token
    address public pool;

    /// @notice Optional address of contract that will process transfers of giant LP
    ITransferHookProcessor public transferHookProcessor;

    /// @notice Last interacted timestamp for a given address
    mapping(address => uint256) public lastInteractedTimestamp;

    constructor(
        address _pool,
        address _transferHookProcessor,
        string memory _name,
        string memory _symbol
    ) ERC20(_name, _symbol) {
        pool = _pool;
        transferHookProcessor = ITransferHookProcessor(_transferHookProcessor);
    }

    function mint(address _recipient, uint256 _amount) external {
        require(msg.sender == pool, "Only pool");
        _mint(_recipient, _amount);
    }

    function burn(address _recipient, uint256 _amount) external {
        require(msg.sender == pool, "Only pool");
        _burn(_recipient, _amount);
    }

    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        require(_from != _to && _amount >= MIN_TRANSFER_AMOUNT, "Transfer Error");
        if (address(transferHookProcessor) != address(0)) ITransferHookProcessor(transferHookProcessor).beforeTokenTransfer(_from, _to, _amount);
    }

    function _afterTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        lastInteractedTimestamp[_from] = block.timestamp;
        lastInteractedTimestamp[_to] = block.timestamp;
        if (address(transferHookProcessor) != address(0)) ITransferHookProcessor(transferHookProcessor).afterTokenTransfer(_from, _to, _amount);
    }
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { GiantLP } from "./GiantLP.sol";

contract GiantLPDeployer {

    event NewDeployment(address indexed instance);

    /// @notice Deploy a giant LP on behalf of the LSDN factory
    function deployToken(
        address _pool,
        address _transferHookProcessor,
        string memory _name,
        string memory _symbol
    ) external returns (address) {
        address newToken = address(new GiantLP(_pool, _transferHookProcessor, _name, _symbol));

        emit NewDeployment(newToken);

        return newToken;
    }
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: BUSL-1.1

import { GiantLP } from "./GiantLP.sol";
import { StakingFundsVault } from "./StakingFundsVault.sol";
import { LPToken } from "./LPToken.sol";
import { GiantPoolBase } from "./GiantPoolBase.sol";
import { SyndicateRewardsProcessor } from "./SyndicateRewardsProcessor.sol";
import { LSDNFactory } from "./LSDNFactory.sol";
import { LPToken } from "./LPToken.sol";
import { GiantLPDeployer } from "./GiantLPDeployer.sol";
import { Errors } from "./Errors.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import { MainnetConstants, GoerliConstants } from "@blockswaplab/stakehouse-solidity-api/contracts/StakehouseAPI.sol";
import { IDataStructures } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol";
import { IAccountManager } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IAccountManager.sol";

/// @notice A giant pool that can provide liquidity to any liquid staking network's staking funds vault
contract GiantMevAndFeesPool is
    GiantPoolBase,
    SyndicateRewardsProcessor,
    UUPSUpgradeable,
    OwnableUpgradeable
{
    using EnumerableSet for EnumerableSet.UintSet;

    error ContractPaused();
    error ReentrancyCall();

    /// @notice Emitted when a user withdraws their LSD LP token by burning their giant LP
    event LPWithdrawn(address indexed lp, address indexed user);

    /// @notice Emitted when pause or unpause is triggered
    event Paused(bool activated);

    /// @notice Total amount of LP allocated to receive pro-rata MEV and fees rewards
    uint256 public totalLPAssociatedWithDerivativesMinted;

    /// @notice Snapshotting pro-rata share of tokens for last claim by address
    mapping(address => uint256) public lastAccumulatedLPAtLastLiquiditySize;

    /// @notice Whether the contract is paused
    bool public paused;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(LSDNFactory _factory, address _lpDeployer, address _upgradeManager) external virtual initializer {
        lpTokenETH = GiantLP(GiantLPDeployer(_lpDeployer).deployToken(address(this), address(this), "GiantETHLP", "gMevETH"));
        liquidStakingDerivativeFactory = _factory;
        batchSize = 4 ether;
        _transferOwnership(_upgradeManager);
        __ReentrancyGuard_init();
    }

    /// @dev Owner based upgrades
    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    /// @notice Allow the contract owner to trigger pausing of core features
    function togglePause(bool _paused) external onlyOwner {
        paused = _paused;
        emit Paused(_paused);
    }

    /// @notice Stake ETH against multiple BLS keys within multiple LSDNs and specify the amount of ETH being supplied for each key
    /// @dev Uses contract balance for funding and get Staking Funds Vault LP in exchange for ETH
    /// @param _stakingFundsVault List of mev and fees vaults being interacted with
    /// @param _ETHTransactionAmounts ETH being attached to each savETH vault in the list
    /// @param _blsPublicKeyOfKnots For every staking funds vault, the list of BLS keys of LSDN validators receiving funding
    /// @param _amounts List of amounts of ETH being staked per BLS public key
    function batchDepositETHForStaking(
        address[] calldata _stakingFundsVault,
        uint256[] calldata _ETHTransactionAmounts,
        bytes[][] calldata _blsPublicKeyOfKnots,
        uint256[][] calldata _amounts
    ) external whenContractNotPaused nonReentrant {
        uint256 numOfVaults = _stakingFundsVault.length;
        if (numOfVaults == 0) revert Errors.EmptyArray();
        if (numOfVaults != _ETHTransactionAmounts.length) revert Errors.InconsistentArrayLength();
        if (numOfVaults != _blsPublicKeyOfKnots.length) revert Errors.InconsistentArrayLength();
        if (numOfVaults != _amounts.length) revert Errors.InconsistentArrayLength();

        updateAccumulatedETHPerLP();

        for (uint256 i; i < numOfVaults; ++i) {
            // As ETH is being deployed to a staking funds vault, it is no longer idle
            idleETH -= _ETHTransactionAmounts[i];

            if (!liquidStakingDerivativeFactory.isStakingFundsVault(_stakingFundsVault[i])) revert Errors.InvalidStakingFundsVault();

            StakingFundsVault(payable(_stakingFundsVault[i])).batchDepositETHForStaking{ value: _ETHTransactionAmounts[i] }(
                _blsPublicKeyOfKnots[i],
                _amounts[i]
            );

            uint256 numOfPublicKeys = _blsPublicKeyOfKnots[i].length;
            for (uint256 j; j < numOfPublicKeys; ++j) {
                // because of withdrawal batch allocation, partial funding amounts would add too much complexity for later allocation
                if (_amounts[i][j] != 4 ether) revert Errors.InvalidAmount();
                _onStake(_blsPublicKeyOfKnots[i][j]);
                isBLSPubKeyFundedByGiantPool[_blsPublicKeyOfKnots[i][j]] = true;
            }
        }
    }

    /// @notice Allow a giant LP to claim a % of the revenue received by the MEV and Fees Pool
    function claimRewards(
        address _recipient,
        address[] calldata _stakingFundsVaults,
        bytes[][] calldata _blsPublicKeysForKnots
    ) external whenContractNotPaused {
        if (totalLPAssociatedWithDerivativesMinted == 0) revert Errors.NoDerivativesMinted();

        _fetchGiantPoolRewards(_stakingFundsVaults, _blsPublicKeysForKnots);

        claimExistingRewards(_recipient);
    }

    /// @notice Fetch ETH rewards from staking funds vaults funded from the giant pool without sending to giant LPs
    function fetchGiantPoolRewards(
        address[] calldata _stakingFundsVaults,
        bytes[][] calldata _blsPublicKeysForKnots
    ) public whenContractNotPaused nonReentrant {
        _fetchGiantPoolRewards(_stakingFundsVaults, _blsPublicKeysForKnots);
        updateAccumulatedETHPerLP();
    }

    /// @notice Allow a user to claim their reward balance without fetching upstream ETH rewards (that are in syndicates)
    function claimExistingRewards(address _recipient) public whenContractNotPaused nonReentrant {
        updateAccumulatedETHPerLP();
        _transferETH(
            _recipient,
            _distributeETHRewardsToUserForToken(
                msg.sender,
                address(lpTokenETH),
                _getTotalLiquidityInActiveRangeForUser(msg.sender),
                _recipient
            )
        );
    }

    /// @notice Any ETH that has not been utilized by a Staking Funds vault can be brought back into the giant pool
    /// @param _stakingFundsVaults List of staking funds vaults this contract will contact
    /// @param _lpTokens List of LP tokens that the giant pool holds which represents ETH in a staking funds vault
    /// @param _amounts Amounts of LP within the giant pool being burnt
    function bringUnusedETHBackIntoGiantPool(
        address[] calldata _stakingFundsVaults,
        LPToken[][] calldata _lpTokens,
        uint256[][] calldata _amounts
    ) external whenContractNotPaused nonReentrant {
        uint256 numOfVaults = _stakingFundsVaults.length;
        if (numOfVaults == 0) revert Errors.EmptyArray();
        if (numOfVaults != _lpTokens.length) revert Errors.InconsistentArrayLength();
        if (numOfVaults != _amounts.length) revert Errors.InconsistentArrayLength();

        updateAccumulatedETHPerLP();

        for (uint256 i; i < numOfVaults; ++i) {
            StakingFundsVault vault = StakingFundsVault(payable(_stakingFundsVaults[i]));
            if (!liquidStakingDerivativeFactory.isStakingFundsVault(address(vault))) revert Errors.InvalidStakingFundsVault();

            vault.burnLPTokensForETH(_lpTokens[i], _amounts[i]);

            uint256 numOfTokens = _lpTokens[i].length;
            for (uint256 j; j < numOfTokens; ++j) {
                // Increase the amount of ETH that's idle
                idleETH += _amounts[i][j];

                bytes memory blsPubKey = vault.KnotAssociatedWithLPToken(_lpTokens[i][j]);
                _onBringBackETHToGiantPool(blsPubKey);
                isBLSPubKeyFundedByGiantPool[blsPubKey] = false;
            }
        }
    }

    /// @notice Allow giant pool LP holders to withdraw LP tokens from LSD networks that they funded
    /// @param _lpToken Address of the LP token that the user is withdrawing from the giant pool
    /// @param _amount Of LP tokens user is withdrawing and also amount of giant tokens being burnt
    function withdrawLP(
        LPToken _lpToken,
        uint256 _amount
    ) external whenContractNotPaused nonReentrant {
        // Check the token that the giant pool should own was deployed by an authenticated staking funds vault
        address stakingFundsVault = _lpToken.deployer();
        if (!liquidStakingDerivativeFactory.isStakingFundsVault(stakingFundsVault)) revert Errors.InvalidStakingFundsVault();
        if (_lpToken.balanceOf(address(this)) < _amount) revert Errors.InvalidBalance();
        if (lpTokenETH.balanceOf(msg.sender) < _amount) revert Errors.InvalidBalance();
        if (_amount < MIN_STAKING_AMOUNT) revert Errors.InvalidAmount();

        bytes memory blsPublicKey = StakingFundsVault(payable(stakingFundsVault)).KnotAssociatedWithLPToken(_lpToken);
        if (!_isDerivativesMinted(blsPublicKey)) revert Errors.NoDerivativesMinted();

        _lpToken.transfer(msg.sender, _amount);
        lpTokenETH.burn(msg.sender, _amount);

        uint256 batchId = allocatedWithdrawalBatchForBlsPubKey[blsPublicKey];
        _reduceUserAmountFundedInBatch(batchId, msg.sender, _amount);

        emit LPWithdrawn(address(_lpToken), msg.sender);
    }

    /// @notice Distribute any new ETH received to LP holders
    function updateAccumulatedETHPerLP() public whenContractNotPaused {
        _updateAccumulatedETHPerLP(totalLPAssociatedWithDerivativesMinted);
    }

    /// @notice Allow giant LP token to notify pool about transfers so the claimed amounts can be processed
    function beforeTokenTransfer(address _from, address _to, uint256 _amount) external whenContractNotPaused {
        if (msg.sender != address(lpTokenETH)) revert Errors.InvalidCaller();

        updateAccumulatedETHPerLP();

        // Make sure that `_from` gets total accrued before transfer as post transferred anything owed will be wiped
        if (_from != address(0)) {
            (uint256 activeLiquidityFrom, uint256 lpBalanceFromBefore) = _distributePendingETHRewards(_from);
            if (lpTokenETH.balanceOf(_from) != lpBalanceFromBefore) revert ReentrancyCall();

            lastAccumulatedLPAtLastLiquiditySize[_from] = accumulatedETHPerLPShare;
            claimed[_from][msg.sender] = activeLiquidityFrom == 0 ?
                0 : (accumulatedETHPerLPShare * (activeLiquidityFrom - _amount)) / PRECISION;
        }

        // Make sure that `_to` gets total accrued before transfer as post transferred anything owed will be wiped
        if (_to != address(0)) {
            (uint256 activeLiquidityTo, uint256 lpBalanceToBefore) = _distributePendingETHRewards(_to);
            if (lpTokenETH.balanceOf(_to) != lpBalanceToBefore) revert ReentrancyCall();
            if (lpBalanceToBefore > 0) {
                claimed[_to][msg.sender] = (accumulatedETHPerLPShare * (activeLiquidityTo + _amount)) / PRECISION;
            } else {
                claimed[_to][msg.sender] = (accumulatedETHPerLPShare * _amount) / PRECISION;
            }

            lastAccumulatedLPAtLastLiquiditySize[_to] = accumulatedETHPerLPShare;
        }
    }

    /// @notice Total rewards received by this contract from the syndicate excluding idle ETH from LP depositors
    function totalRewardsReceived() public view override returns (uint256) {
        return address(this).balance + totalClaimed - idleETH;
    }

    /// @notice Preview total ETH accrued by an address from Syndicate rewards
    function previewAccumulatedETH(
        address _user,
        address[] calldata _stakingFundsVaults,
        LPToken[][] calldata _lpTokens
    ) external view returns (uint256) {
        uint256 numOfVaults = _stakingFundsVaults.length;
        if (numOfVaults != _lpTokens.length) revert Errors.InconsistentArrayLength();

        uint256 accumulated;
        for (uint256 i; i < numOfVaults; ++i) {
            accumulated += StakingFundsVault(payable(_stakingFundsVaults[i])).batchPreviewAccumulatedETH(
                address(this),
                _lpTokens[i]
            );
        }

        return _previewAccumulatedETH(
            _user,
            address(lpTokenETH),
            _getTotalLiquidityInActiveRangeForUser(_user),
            totalLPAssociatedWithDerivativesMinted,
            accumulated
        );
    }

    /// @notice Get total liquidity that is in active reward range for user
    function getTotalLiquidityInActiveRangeForUser(address _user) external view returns (uint256) {
        return _getTotalLiquidityInActiveRangeForUser(_user);
    }

    /// @dev Re-usable function for distributing rewards based on having an LP balance and active liquidity from minting derivatives
    function _distributePendingETHRewards(address _receiver) internal returns (
        uint256 activeLiquidityReceivingRewards,
        uint256 lpTokenETHBalance
    ) {
        lpTokenETHBalance = lpTokenETH.balanceOf(_receiver);
        if (lpTokenETHBalance > 0) {
            activeLiquidityReceivingRewards = _getTotalLiquidityInActiveRangeForUser(_receiver);
            if (activeLiquidityReceivingRewards > 0) {
                _transferETH(
                    _receiver,
                    _distributeETHRewardsToUserForToken(
                        _receiver,
                        address(lpTokenETH),
                        activeLiquidityReceivingRewards,
                        _receiver
                    )
                );
            }
        }
    }

    /// @notice Allow liquid staking managers to notify the giant pool about derivatives minted for a key
    function _onMintDerivatives(bytes calldata _blsPublicKey) internal override {
        // use this to update active liquidity range for distributing rewards
        if (isBLSPubKeyFundedByGiantPool[_blsPublicKey]) {
            // Capture accumulated LP at time of minting derivatives
            accumulatedETHPerLPAtTimeOfMintingDerivatives[_blsPublicKey] = accumulatedETHPerLPShare;

            totalLPAssociatedWithDerivativesMinted += 4 ether;
        }
    }

    /// @dev Total claimed for a user and LP token needs to be based on when derivatives were minted so that pro-rated share is not earned too early causing phantom balances
    function _getTotalClaimedForUserAndToken(
        address _user,
        address _token,
        uint256 _currentBalance
    ) internal override view returns (uint256) {
        uint256 claimedSoFar = claimed[_user][_token];

        // Handle the case where all LP is withdrawn or some derivatives are not minted
        if (_currentBalance == 0) revert Errors.InvalidAmount();

        if (claimedSoFar > 0) {
            claimedSoFar = (lastAccumulatedLPAtLastLiquiditySize[_user] * _currentBalance) / PRECISION;
        } else {
            uint256 batchId = setOfAssociatedDepositBatches[_user].at(0);
            bytes memory blsPublicKey = allocatedBlsPubKeyForWithdrawalBatch[batchId];
            claimedSoFar = (_currentBalance * accumulatedETHPerLPAtTimeOfMintingDerivatives[blsPublicKey]) / PRECISION;
        }

        // Either user has a claimed amount or their claimed amount needs to be based on accumulated ETH at time of minting derivatives
        return claimedSoFar;
    }

    /// @dev Use _getTotalClaimedForUserAndToken to correctly track and save total claimed by a user for a token
    function _increaseClaimedForUserAndToken(
        address _user,
        address _token,
        uint256 _increase,
        uint256 _balance
    ) internal override {
        // _getTotalClaimedForUserAndToken will factor in accumulated ETH at time of minting derivatives
        lastAccumulatedLPAtLastLiquiditySize[_user] = accumulatedETHPerLPShare;
        claimed[_user][_token] = _getTotalClaimedForUserAndToken(_user, _token, _balance) + _increase;
    }

    /// @dev Utility for fetching total ETH that is eligble to receive rewards for a user
    function _getTotalLiquidityInActiveRangeForUser(address _user) internal view returns (uint256) {
        uint256 totalLiquidityInActiveRangeForUser;
        uint256 totalNumOfBatches = setOfAssociatedDepositBatches[_user].length();

        for (uint256 i; i < totalNumOfBatches; ++i) {
            uint256 batchId = setOfAssociatedDepositBatches[_user].at(i);

            if (!_isDerivativesMinted(allocatedBlsPubKeyForWithdrawalBatch[batchId])) {
                // Derivatives are not minted for this batch so continue as elements in enumerable set are not guaranteed any order
                continue;
            }

            totalLiquidityInActiveRangeForUser += totalETHFundedPerBatch[_user][batchId];
        }

        return totalLiquidityInActiveRangeForUser;
    }

    /// @dev Given a BLS pub key, whether derivatives are minted
    function _isDerivativesMinted(bytes memory _blsPubKey) internal view returns (bool) {
        return getAccountManager().blsPublicKeyToLifecycleStatus(_blsPubKey) == IDataStructures.LifecycleStatus.TOKENS_MINTED;
    }

    /// @dev Internal business logic for fetching fees and mev rewards from specified LSD networks
    function _fetchGiantPoolRewards(
        address[] calldata _stakingFundsVaults,
        bytes[][] calldata _blsPublicKeysForKnots
    ) internal {
        uint256 numOfVaults = _stakingFundsVaults.length;
        if (numOfVaults == 0) revert Errors.EmptyArray();
        if (numOfVaults != _blsPublicKeysForKnots.length) revert Errors.InconsistentArrayLength();
        for (uint256 i; i < numOfVaults; ++i) {
            StakingFundsVault vault = StakingFundsVault(payable(_stakingFundsVaults[i]));
            if (!liquidStakingDerivativeFactory.isStakingFundsVault(address(vault))) revert Errors.InvalidStakingFundsVault();
            vault.claimRewards(
                address(this),
                _blsPublicKeysForKnots[i]
            );
        }
    }

    // @dev Get the interface connected to the AccountManager smart contract
    function getAccountManager() internal view virtual returns (IAccountManager accountManager) {
        uint256 chainId;

        assembly {
            chainId := chainid()
        }

        if(chainId == MainnetConstants.CHAIN_ID) {
            accountManager = IAccountManager(MainnetConstants.AccountManager);
        }

        else if (chainId == GoerliConstants.CHAIN_ID) {
            accountManager = IAccountManager(GoerliConstants.AccountManager);
        }

        else {
            revert('CHAIN');
        }
    }

    function _assertContractNotPaused() internal override {
        if (paused) revert ContractPaused();
    }
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: BUSL-1.1

import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

import { LSDNFactory } from "./LSDNFactory.sol";
import { GiantLP } from "./GiantLP.sol";
import { LPToken } from "./LPToken.sol";
import { ITransferHookProcessor } from "../interfaces/ITransferHookProcessor.sol";
import { ETHTransferHelper } from "../transfer/ETHTransferHelper.sol";

abstract contract GiantPoolBase is ITransferHookProcessor, ReentrancyGuardUpgradeable, ETHTransferHelper {

    using EnumerableSet for EnumerableSet.UintSet;

    error BelowMinimum();
    error InvalidAmount();
    error InvalidWithdrawal();
    error ComeBackLater();
    error BLSKeyStaked();
    error BLSKeyNotStaked();
    error ErrorWithdrawing();
    error OnlyManager();
    error InvalidCaller();
    error InvalidBalance();
    error NotEnoughIdleETH();
    error InvalidTransfer();
    error InvalidJump();
    error InvalidExistingPosition();
    error NoRecycledETH();
    error NoFundingInSelectedBatch();
    error BatchAllocated();
    error UnableToDeleteRecycledBatch();
    error NoFullBatchAvailable();

    /// @notice Emitted when an account deposits Ether into the giant pool
    event ETHDeposited(address indexed sender, uint256 amount);

    /// @notice Emitted when giant LP is burnt to recover ETH
    event LPBurnedForETH(address indexed sender, uint256 amount);

    /// @notice Emitted when a deposit associates a depositor with a ticket for withdrawal
    event WithdrawalBatchAssociatedWithUser(address indexed user, uint256 indexed batchId);

    /// @notice Emitted when user updates their staked position
    event WithdrawalBatchUpdated(address indexed user, uint256 indexed batchId, uint256 newAmount);

    /// @notice Emitted when a withdrawal batch associated with a depositor is removed
    event WithdrawalBatchRemovedFromUser(address indexed user, uint256 indexed batchId);

    /// @notice Emitted when a withdrawal batch is associated with a BLS pub key
    event WithdrawalBatchAssociatedWithBLSKey(bytes key, uint256 indexed batchId);

    /// @notice Emitted when a withdrawal batch is disassociated with a BLS pub key
    event WithdrawalBatchDisassociatedWithBLSKey(bytes key, uint256 indexed batchId);

    /// @notice Emitted when a user is jumping a deposit queue because another user withdrew
    event QueueJumped(address indexed user, uint256 indexed targetPosition, uint256 indexed existingPosition, uint256 amount);

    /// @notice Minimum amount of Ether that can be deposited into the contract
    uint256 public constant MIN_STAKING_AMOUNT = 0.001 ether;

    /// @notice Size of funding offered per BLS public key
    uint256 public batchSize;

    /// @notice Total amount of ETH sat idle ready for either withdrawal or depositing into a liquid staking network
    uint256 public idleETH;

    /// @notice Historical amount of ETH received by all depositors
    uint256 public totalETHFromLPs;

    /// @notice LP token representing all ETH deposited and any ETH converted into savETH vault LP tokens from any liquid staking network
    GiantLP public lpTokenETH;

    /// @notice Address of the liquid staking derivative factory that provides a source of truth on individual networks that can be funded
    LSDNFactory public liquidStakingDerivativeFactory;

    /// @notice Number of batches of 24 ETH that have been deposited to the open pool
    uint256 public depositBatchCount;

    /// @notice Number of batches that have been deployed to a liquid staking network
    uint256 public stakedBatchCount;

    /// @notice Based on a user deposit, all the historical batch positions later used for claiming
    mapping(address => EnumerableSet.UintSet) internal setOfAssociatedDepositBatches;

    /// @notice Whether the giant pool funded the ETH for staking
    mapping(bytes => bool) internal isBLSPubKeyFundedByGiantPool;

    /// @notice For a given BLS key, allocated withdrawal batch
    mapping(bytes => uint256) public allocatedWithdrawalBatchForBlsPubKey;

    /// @notice For a given withdrawal batch, allocated BLS key
    mapping(uint256 => bytes) public allocatedBlsPubKeyForWithdrawalBatch;

    /// @notice Given a user and batch ID, total ETH contributed
    mapping(address => mapping(uint256 => uint256)) public totalETHFundedPerBatch;

    /// @notice Whenever a deposit batch ID is released by a user withdrawing, we recycle the batch ID so the gaps are filled by future depositors
    EnumerableSet.UintSet internal setOfRecycledDepositBatches;

    /// @notice For a given batch ID that has been recycled, how much ETH new depositors can fund in recycled batches
    mapping(uint256 => uint256) public ethRecycledFromBatch;

    /// @notice Track any staked batches that are recycled
    EnumerableSet.UintSet internal setOfRecycledStakedBatches;

    modifier whenContractNotPaused() {
        _assertContractNotPaused();
        _;
    }

    /// @notice Add ETH to the ETH LP pool at a rate of 1:1. LPs can always pull out at same rate.
    function depositETH(uint256 _amount) external payable nonReentrant whenContractNotPaused {
        if (_amount < MIN_STAKING_AMOUNT) revert InvalidAmount();
        if (_amount % MIN_STAKING_AMOUNT != 0) revert InvalidAmount();
        if (msg.value != _amount) revert InvalidAmount();

        // The ETH capital has not yet been deployed to a liquid staking network
        idleETH += msg.value;
        totalETHFromLPs += msg.value;

        // Mint giant LP at ratio of 1:1
        lpTokenETH.mint(msg.sender, msg.value);

        // If anything extra needs to be done
        _afterDepositETH(msg.value);

        emit ETHDeposited(msg.sender, msg.value);
    }

    /// @notice Withdraw ETH but only from withdrawal batches that have not been staked yet
    /// @param _amount of LP tokens user is burning in exchange for same amount of ETH
    function withdrawETH(
        uint256 _amount
    ) external nonReentrant whenContractNotPaused {
        if (_amount == 0) revert InvalidAmount();
        if (lpTokenETH.balanceOf(msg.sender) < _amount) revert InvalidBalance();
        if (idleETH < _amount) revert NotEnoughIdleETH();

        // Revert early if user is not part of any batches
        uint256 totalNumOfBatches = setOfAssociatedDepositBatches[msg.sender].length();
        if (totalNumOfBatches == 0) revert InvalidWithdrawal();

        // Check how new the lpTokenETH liquidity of msg.sender
        if (lpTokenETH.lastInteractedTimestamp(msg.sender) + 45 minutes > block.timestamp) revert ComeBackLater();

        // Send the ETH
        _withdrawETH(_amount);

        // Update associated batch IDs for msg.sender
        // Withdraw ETH from the batch added last unless it is staked in which case user must redeem dETH
        uint256 ethLeftToWithdraw = _amount;
        for (uint256 i = totalNumOfBatches; i > 0; --i) {
            uint256 batchAtIndex = setOfAssociatedDepositBatches[msg.sender].at(i - 1);

            if (allocatedBlsPubKeyForWithdrawalBatch[batchAtIndex].length != 0) {
                continue;
            }

            uint256 ethFromBatch = totalETHFundedPerBatch[msg.sender][batchAtIndex];
            uint256 amountToRecycle = ethLeftToWithdraw >= ethFromBatch ? ethFromBatch : ethLeftToWithdraw;
            if (ethLeftToWithdraw >= ethFromBatch) {
                ethLeftToWithdraw -= amountToRecycle;
            } else {
                ethLeftToWithdraw = 0;
            }

            _reduceUserAmountFundedInBatch(batchAtIndex, msg.sender, amountToRecycle);

            // Recycle any batches that are less than the current deposit count so that we can fill gaps with future depositors
            if (batchAtIndex < depositBatchCount) {
                setOfRecycledDepositBatches.add(batchAtIndex);
                ethRecycledFromBatch[batchAtIndex] += amountToRecycle;
            }

            // Break out of the loop when we have matched the withdrawal amounts over batches
            if (ethLeftToWithdraw == 0) break;
        }

        // If we get out of the loop and the amount left to withdraw is not zero then there was not enough withdrawable ETH to match the withdrawal amount
        if (ethLeftToWithdraw != 0) revert ErrorWithdrawing();
    }

    /// @notice Allow liquid staking managers to notify the giant pool about derivatives minted for a key
    function onMintDerivatives(bytes calldata _blsPublicKey) external {
        if (!liquidStakingDerivativeFactory.isLiquidStakingManager(msg.sender)) revert OnlyManager();
        _onMintDerivatives(_blsPublicKey);
    }

    /// @notice Total amount of ETH an LP can withdraw on the basis of whether the ETH has been used in staking
    function withdrawableAmountOfETH(address _user) external view returns (uint256) {
        uint256 withdrawableAmount;

        uint256 _stakedBatchCount = stakedBatchCount; // Cache

        // If the user does not have an allocated batch, the withdrawable amount will return zero
        uint256 totalNumOfBatches = setOfAssociatedDepositBatches[_user].length();
        for (uint256 i = totalNumOfBatches; i > 0; --i) {
            uint256 batchAtIndex = setOfAssociatedDepositBatches[_user].at(i - 1);

            if (allocatedBlsPubKeyForWithdrawalBatch[batchAtIndex].length == 0) {
                withdrawableAmount += totalETHFundedPerBatch[_user][batchAtIndex];
            }
        }

        return withdrawableAmount;
    }

    /// @notice Get the total number of withdrawal tickets allocated to an address
    function getSetOfAssociatedDepositBatchesSize(address _user) external view returns (uint256) {
        return setOfAssociatedDepositBatches[_user].length();
    }

    /// @notice Get the withdrawal ticket batch ID at an index
    function getAssociatedDepositBatchIDAtIndex(address _user, uint256 _index) external view returns (uint256) {
        return setOfAssociatedDepositBatches[_user].at(_index);
    }

    /// @notice Get total number of recycled deposit batches
    function getRecycledDepositBatchesSize() external view returns (uint256) {
        return setOfRecycledDepositBatches.length();
    }

    /// @notice Get batch ID at a specific index for recycled deposit batches
    function getRecycledDepositBatchIDAtIndex(uint256 _index) external view returns (uint256) {
        return setOfRecycledDepositBatches.at(_index);
    }

    /// @notice Get total number of recycled staked batches
    function getRecycledStakedBatchesSize() external view returns (uint256) {
        return setOfRecycledStakedBatches.length();
    }

    /// @notice Get batch ID at a specific index for recycled staked batches
    function getRecycledStakedBatchIDAtIndex(uint256 _index) external view returns (uint256) {
        return setOfRecycledStakedBatches.at(_index);
    }

    /// @notice Allow giant LP token to notify pool about transfers so the claimed amounts can be processed
    function afterTokenTransfer(address _from, address _to, uint256 _amount) external {
        if (msg.sender != address(lpTokenETH)) revert InvalidCaller();
        if (_from != address(0) && _to != address(0)) {
            EnumerableSet.UintSet storage setOfAssociatedDepositBatchesForFrom = setOfAssociatedDepositBatches[_from];
            uint256 amountLeftToTransfer = _amount;

            // Transfer redemption rights of batches to the recipient address
            // They may already have the rights to some batches but they will gain a larger share afterwards
            uint256 numOfBatchesFromAddress = setOfAssociatedDepositBatchesForFrom.length();
            for (uint256 i = numOfBatchesFromAddress; i > 0; --i) {
                // Duplicates are avoided due to use of enumerable set
                uint256 batchId = setOfAssociatedDepositBatchesForFrom.at(i - 1);
                uint256 totalETHFunded = totalETHFundedPerBatch[_from][batchId];
                if (amountLeftToTransfer >= totalETHFunded) {
                    // Clean up the state for the 'from' account
                    _reduceUserAmountFundedInBatch(batchId, _from, totalETHFunded);

                    // Adjust how much is left to transfer
                    amountLeftToTransfer -= totalETHFunded;

                    // Add _to user to the batch
                    _addUserToBatch(batchId, _to, totalETHFunded);
                } else {
                    // Adjust the _from user total funded
                    _reduceUserAmountFundedInBatch(batchId, _from, amountLeftToTransfer);

                    // Add _to user to the batch
                    _addUserToBatch(batchId, _to, amountLeftToTransfer);

                    // There will no longer be any amount left to transfer
                    amountLeftToTransfer = 0;
                }

                // We can leave the loop once the required batches have been given to recipient
                if (amountLeftToTransfer == 0) break;
            }

            if (amountLeftToTransfer != 0) revert InvalidTransfer();
        }
    }

    /// @notice If another giant pool user withdraws ETH freeing up an earlier space in the queue, allow them to jump some of their funding there
    /// @param _targetPosition Batch ID of the target batch user wants their funding associated
    /// @param _existingPosition Batch ID of the existing batch user is transferring their funding from
    /// @param _user Address of the user that has funded giant pool allowing others to help jump the queue
    function jumpTheQueue(uint256 _targetPosition, uint256 _existingPosition, address _user) external {
        // Make sure that the target is less than existing - forcing only one direction.
        // Existing cannot be more than the deposit batch count
        if (_targetPosition > _existingPosition) revert InvalidJump();
        if (_existingPosition > depositBatchCount) revert InvalidExistingPosition();

        // Check that the target has ETH recycled due to withdrawal
        uint256 ethRecycled = ethRecycledFromBatch[_targetPosition];
        if (ethRecycled == 0) revert NoRecycledETH();

        // Check that the user has funding in existing batch and neither existing or target batch has been allocated
        uint256 totalExistingFunding = totalETHFundedPerBatch[_user][_existingPosition];
        if (totalExistingFunding == 0) revert NoFundingInSelectedBatch();
        if (allocatedBlsPubKeyForWithdrawalBatch[_targetPosition].length != 0) revert BatchAllocated();
        if (allocatedBlsPubKeyForWithdrawalBatch[_existingPosition].length != 0) revert BatchAllocated();

        // Calculate how much can jump from existing to target
        uint256 amountThatCanJump = totalExistingFunding > ethRecycled ? ethRecycled : totalExistingFunding;

        // Adjust how much ETH from withdrawals is recycled, removing batch if it hits zero
        ethRecycledFromBatch[_targetPosition] -= amountThatCanJump;
        if (ethRecycledFromBatch[_targetPosition] == 0) {
            if (!setOfRecycledDepositBatches.remove(_targetPosition)) revert UnableToDeleteRecycledBatch();
        }

        // If users existing position is less than deposit count, treat it as recycled
        if (_existingPosition < depositBatchCount) {
            ethRecycledFromBatch[_existingPosition] += amountThatCanJump;
            setOfRecycledDepositBatches.add(_existingPosition);
        }

        // Reduce funding from existing position and add user funded amount to new batch
        _reduceUserAmountFundedInBatch(_existingPosition, _user, amountThatCanJump);
        _addUserToBatch(_targetPosition, _user, amountThatCanJump);

        emit QueueJumped(_user, _targetPosition, _existingPosition, amountThatCanJump);
    }

    /// @dev Business logic for managing withdrawal of ETH
    function _withdrawETH(uint256 _amount) internal {
        // Burn giant tokens
        lpTokenETH.burn(msg.sender, _amount);

        // Adjust idle ETH
        idleETH -= _amount;
        totalETHFromLPs -= _amount;

        // Send ETH to the recipient
        _transferETH(msg.sender, _amount);

        emit LPBurnedForETH(msg.sender, _amount);
    }

    /// @dev Allow an inheriting contract to have a hook for performing operations after depositing ETH
    function _afterDepositETH(uint256 _totalDeposited) internal virtual {
        uint256 totalToFundFromNewBatches = _totalDeposited;

        while (setOfRecycledDepositBatches.length() > 0) {
            uint256 batchId = setOfRecycledDepositBatches.at(0);
            uint256 ethRecycled = ethRecycledFromBatch[batchId];
            uint256 amountToAssociateWithBatch = ethRecycled >= totalToFundFromNewBatches ? totalToFundFromNewBatches : ethRecycled;

            totalToFundFromNewBatches -= amountToAssociateWithBatch;
            ethRecycledFromBatch[batchId] -= amountToAssociateWithBatch;
            if (ethRecycledFromBatch[batchId] == 0) {
                setOfRecycledDepositBatches.remove(batchId);
            }

            _addUserToBatch(batchId, msg.sender, amountToAssociateWithBatch);

            if (totalToFundFromNewBatches == 0) return;
        }

        uint256 currentBatchNum = depositBatchCount;
        uint256 newComputedBatchNum = totalETHFromLPs / batchSize;
        uint256 numOfBatchesFunded = newComputedBatchNum - currentBatchNum;

        if (numOfBatchesFunded == 0) {
            _addUserToBatch(currentBatchNum, msg.sender, totalToFundFromNewBatches);
        } else {
            uint256 ethBeforeDeposit = totalETHFromLPs - totalToFundFromNewBatches;
            uint256 ethLeftToAllocate = totalToFundFromNewBatches;

            // User can withdraw from multiple batches later
            uint256 ethContributedToThisBatch = batchSize - (ethBeforeDeposit % batchSize);
            for (uint256 i = currentBatchNum; i <= newComputedBatchNum; ++i) {
                _addUserToBatch(i, msg.sender, ethContributedToThisBatch);

                ethLeftToAllocate -= ethContributedToThisBatch;
                if (ethLeftToAllocate >= batchSize) {
                    ethContributedToThisBatch = batchSize;
                } else if (ethLeftToAllocate > 0) {
                    ethContributedToThisBatch = ethLeftToAllocate;
                } else {
                    break;
                }
            }

            // Move the deposit batch count forward
            depositBatchCount = newComputedBatchNum;
        }
    }

    /// @dev Re-usable logic for adding a user to a batch given an amount of batch funding
    function _addUserToBatch(uint256 _batchIndex, address _user, uint256 _amount) internal {
        totalETHFundedPerBatch[_user][_batchIndex] += _amount;
        if (setOfAssociatedDepositBatches[_user].add(_batchIndex)) {
            emit WithdrawalBatchAssociatedWithUser(_user, _batchIndex);
        } else {
            emit WithdrawalBatchUpdated(_user, _batchIndex, totalETHFundedPerBatch[_user][_batchIndex]);
        }
    }

    /// @dev Re-usable logic for reducing amount of user funding for a given batch
    function _reduceUserAmountFundedInBatch(uint256 _batchIndex, address _user, uint256 _amount) internal {
        totalETHFundedPerBatch[_user][_batchIndex] -= _amount;
        if (totalETHFundedPerBatch[_user][_batchIndex] == 0) {
            // Remove the batch from the user and if it succeeds emit an event
            if (setOfAssociatedDepositBatches[_user].remove(_batchIndex)) {
                emit WithdrawalBatchRemovedFromUser(_user, _batchIndex);
            }
        } else {
            emit WithdrawalBatchUpdated(_user, _batchIndex, totalETHFundedPerBatch[_user][_batchIndex]);
        }
    }

    /// @dev Allow liquid staking managers to notify the giant pool about ETH sent to the deposit contract for a key
    function _onStake(bytes calldata _blsPublicKey) internal virtual {
        if (isBLSPubKeyFundedByGiantPool[_blsPublicKey]) revert BLSKeyStaked();

        uint256 numOfRecycledStakedBatches = setOfRecycledStakedBatches.length();
        for (uint256 i; i < numOfRecycledStakedBatches; ++i) {
            uint256 batchToAllocate = setOfRecycledStakedBatches.at(i);
            if (ethRecycledFromBatch[batchToAllocate] == 0) {
                _allocateStakingCountToBlsKey(_blsPublicKey, batchToAllocate);
                setOfRecycledStakedBatches.remove(batchToAllocate);
                // Return out the function since we found a recycled batch to allocate
                return;
            }
        }

        // There were no recycled batches to allocate so we find a new one
        while (stakedBatchCount < depositBatchCount) {
            bool allocated;
            if (ethRecycledFromBatch[stakedBatchCount] == 0) {
                // Allocate batch to BLS key
                _allocateStakingCountToBlsKey(_blsPublicKey, stakedBatchCount);
                allocated = true;
            } else {
                // If we need to skip because the batch is not full, then put it in recycled bucket
                setOfRecycledStakedBatches.add(stakedBatchCount);
            }

            // increment staked count post allocation
            stakedBatchCount++;

            // If we allocated a staked batch count, we can leave this method
            if (allocated) return;
        }

        revert NoFullBatchAvailable();
    }

    /// @dev Allocate a staking count to a BLS public key for later rewards queue
    function _allocateStakingCountToBlsKey(bytes calldata _blsPublicKey, uint256 _count) internal {
        // Allocate redemption path for all LPs with the same deposit count
        allocatedWithdrawalBatchForBlsPubKey[_blsPublicKey] = _count;
        allocatedBlsPubKeyForWithdrawalBatch[_count] = _blsPublicKey;

        // Log the allocation
        emit WithdrawalBatchAssociatedWithBLSKey(_blsPublicKey, _count);
    }

    /// @dev When bringing ETH back to giant pool, free up a staked batch count
    function _onBringBackETHToGiantPool(bytes memory _blsPublicKey) internal virtual {
        uint256 allocatedBatch = allocatedWithdrawalBatchForBlsPubKey[_blsPublicKey];
        if (!isBLSPubKeyFundedByGiantPool[_blsPublicKey]) revert BLSKeyNotStaked();

        setOfRecycledStakedBatches.add(allocatedBatch);

        delete allocatedWithdrawalBatchForBlsPubKey[_blsPublicKey];
        delete allocatedBlsPubKeyForWithdrawalBatch[allocatedBatch];

        emit WithdrawalBatchDisassociatedWithBLSKey(_blsPublicKey, allocatedBatch);
    }

    /// @notice Allow liquid staking managers to notify the giant pool about derivatives minted for a key
    function _onMintDerivatives(bytes calldata _blsPublicKey) internal virtual {}

    /// @notice Allow inheriting contract to specify checks for whether contract is paused
    function _assertContractNotPaused() internal virtual {}
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: BUSL-1.1

import { StakehouseAPI } from "@blockswaplab/stakehouse-solidity-api/contracts/StakehouseAPI.sol";
import { GiantLP } from "./GiantLP.sol";
import { SavETHVault } from "./SavETHVault.sol";
import { LPToken } from "./LPToken.sol";
import { GiantPoolBase } from "./GiantPoolBase.sol";
import { LSDNFactory } from "./LSDNFactory.sol";
import { Errors } from "./Errors.sol";
import { GiantLPDeployer } from "./GiantLPDeployer.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import { EnumerableSet } from "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";

error ContractPaused();

/// @notice A giant pool that can provide protected deposit liquidity to any liquid staking network
contract GiantSavETHVaultPool is StakehouseAPI, GiantPoolBase, UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {

    using EnumerableSet for EnumerableSet.UintSet;

    /// @notice Emitted when giant LP is burnt to receive dETH
    event LPBurnedForDETH(address indexed savETHVaultLPToken, address indexed sender, uint256 amount);

    /// @notice Associated fees and mev pool address
    address public feesAndMevGiantPool;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(
        LSDNFactory _factory,
        address _lpDeployer,
        address _feesAndMevGiantPool,
        address _upgradeManager
    ) external virtual initializer {
        _init(_factory, _lpDeployer, _feesAndMevGiantPool, _upgradeManager);
        __Pausable_init();
        __ReentrancyGuard_init();
    }

    /// @dev Owner based upgrades
    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    /// @notice Allow the contract owner to trigger pausing of core features
    function pause() external onlyOwner {
        _pause();
    }

    /// @notice Allow the contract owner to trigger unpausing of core features
    function unpause() external onlyOwner {
        _unpause();
    }

    /// @notice Given the liquidity of the giant pool, stake ETH to receive protected deposits from many liquid staking networks (LSDNs)
    /// @dev Take ETH from the contract balance in order to send money to the individual vaults
    /// @param _savETHVaults List of savETH vaults that belong to individual liquid staking derivative networks
    /// @param _ETHTransactionAmounts ETH being attached to each savETH vault in the list
    /// @param _blsPublicKeys For every savETH vault, the list of BLS keys of LSDN validators receiving funding
    /// @param _stakeAmounts For every savETH vault, the amount of ETH each BLS key will receive in funding
    function batchDepositETHForStaking(
        address[] calldata _savETHVaults,
        uint256[] calldata _ETHTransactionAmounts,
        bytes[][] calldata _blsPublicKeys,
        uint256[][] calldata _stakeAmounts
    ) public whenContractNotPaused nonReentrant {
        uint256 numOfSavETHVaults = _savETHVaults.length;
        if (numOfSavETHVaults == 0) revert Errors.EmptyArray();
        if (numOfSavETHVaults != _ETHTransactionAmounts.length) revert Errors.InconsistentArrayLength();
        if (numOfSavETHVaults != _blsPublicKeys.length) revert Errors.InconsistentArrayLength();
        if (numOfSavETHVaults != _stakeAmounts.length) revert Errors.InconsistentArrayLength();

        // For every vault specified, supply ETH from the giant pool to the savETH pool of each BLS key
        uint256 totalNumberOfKeys;
        for (uint256 i; i < numOfSavETHVaults; ++i) {
            uint256 transactionAmount = _ETHTransactionAmounts[i];

            // As ETH is being deployed to a savETH pool vault, it is no longer idle
            idleETH -= transactionAmount;

            if (!liquidStakingDerivativeFactory.isSavETHVault(_savETHVaults[i])) revert Errors.InvalidSavETHVault();

            // Deposit ETH for staking of BLS key
            SavETHVault(_savETHVaults[i]).batchDepositETHForStaking{ value: transactionAmount }(
                _blsPublicKeys[i],
                _stakeAmounts[i]
            );

            uint256 numOfPublicKeys = _blsPublicKeys[i].length;
            for (uint256 j; j < numOfPublicKeys; ++j) {
                // because of withdrawal batch allocation, partial funding amounts would add too much complexity for later allocation
                if (_stakeAmounts[i][j] != 24 ether) revert Errors.InvalidAmount();
                _onStake(_blsPublicKeys[i][j]);
                isBLSPubKeyFundedByGiantPool[_blsPublicKeys[i][j]] = true;
            }

            totalNumberOfKeys += numOfPublicKeys;
        }

        if (feesAndMevGiantPool.balance < 4 ether * totalNumberOfKeys) revert Errors.FeesAndMevPoolCannotMatch();
    }

    /// @notice Allow a user to burn their giant LP in exchange for dETH that is ready to withdraw from a set of savETH vaults
    /// @param _savETHVaults List of savETH vaults being interacted with
    /// @param _lpTokens List of savETH vault LP being burnt from the giant pool in exchange for dETH
    /// @param _amounts Amounts of giant LP the user owns which is burnt 1:1 with savETH vault LP and in turn that will give a share of dETH
    function withdrawDETH(
        address[] calldata _savETHVaults,
        LPToken[][] calldata _lpTokens,
        uint256[][] calldata _amounts
    ) external whenContractNotPaused nonReentrant {
        uint256 numOfVaults = _savETHVaults.length;
        if (numOfVaults == 0) revert Errors.EmptyArray();
        if (numOfVaults != _lpTokens.length) revert Errors.InconsistentArrayLength();
        if (numOfVaults != _amounts.length) revert Errors.InconsistentArrayLength();

        // Firstly capture current dETH balance and see how much has been deposited after the loop
        uint256 dETHReceivedFromAllSavETHVaults = getDETH().balanceOf(address(this));
        for (uint256 i; i < numOfVaults; ++i) {
            SavETHVault vault = SavETHVault(_savETHVaults[i]);
            if (!liquidStakingDerivativeFactory.isSavETHVault(address(vault))) revert Errors.InvalidSavETHVault();

            // Simultaneously check the status of LP tokens held by the vault and the giant LP balance of the user
            uint256 numOfTokens = _lpTokens[i].length;
            for (uint256 j; j < numOfTokens; ++j) {
                LPToken token = _lpTokens[i][j];
                uint256 amount = _amounts[i][j];

                // Check the user has enough giant LP to burn and that the pool has enough savETH vault LP
                _assertUserHasEnoughGiantLPToClaimVaultLP(token, amount);

                // Magic - check user is part of the correct withdrawal batch
                uint256 allocatedWithdrawalBatch = allocatedWithdrawalBatchForBlsPubKey[vault.KnotAssociatedWithLPToken(token)];
                _reduceUserAmountFundedInBatch(allocatedWithdrawalBatch, msg.sender, amount);

                // Burn giant LP from user before sending them dETH
                lpTokenETH.burn(msg.sender, amount);

                emit LPBurnedForDETH(address(token), msg.sender, amount);
            }

            // Withdraw dETH from specific LSD network
            vault.burnLPTokens(_lpTokens[i], _amounts[i]);
        }

        // Calculate how much dETH has been received from burning
        dETHReceivedFromAllSavETHVaults = getDETH().balanceOf(address(this)) - dETHReceivedFromAllSavETHVaults;

        // Send giant LP holder dETH owed
        getDETH().transfer(msg.sender, dETHReceivedFromAllSavETHVaults);
    }

    /// @notice Any ETH that has not been utilized by a savETH vault can be brought back into the giant pool
    /// @param _savETHVaults List of savETH vaults where ETH is staked
    /// @param _lpTokens List of LP tokens that the giant pool holds which represents ETH in a savETH vault
    /// @param _amounts Amounts of LP within the giant pool being burnt
    function bringUnusedETHBackIntoGiantPool(
        address[] calldata _savETHVaults,
        LPToken[][] calldata _lpTokens,
        uint256[][] calldata _amounts
    ) external whenContractNotPaused nonReentrant {
        uint256 numOfVaults = _savETHVaults.length;
        if (numOfVaults == 0) revert Errors.EmptyArray();
        if (numOfVaults != _lpTokens.length) revert Errors.InconsistentArrayLength();
        if (numOfVaults != _amounts.length) revert Errors.InconsistentArrayLength();
        for (uint256 i; i < numOfVaults; ++i) {
            SavETHVault vault = SavETHVault(_savETHVaults[i]);
            if (!liquidStakingDerivativeFactory.isSavETHVault(address(vault))) revert Errors.InvalidSavETHVault();

            uint256 numOfTokens = _lpTokens[i].length;
            for (uint256 j; j < numOfTokens; ++j) {
                if (vault.isDETHReadyForWithdrawal(address(_lpTokens[i][j]))) revert Errors.ETHStakedOrDerivativesMinted();

                // Disassociate stake count
                bytes memory blsPubKey = vault.KnotAssociatedWithLPToken(_lpTokens[i][j]);
                _onBringBackETHToGiantPool(blsPubKey);
                isBLSPubKeyFundedByGiantPool[blsPubKey] = false;

                // Increase the amount of ETH that's idle
                idleETH += _amounts[i][j];
            }

            // Burn LP tokens belonging to a specific vault in order to get the vault to send ETH
            vault.burnLPTokens(_lpTokens[i], _amounts[i]);
        }
    }

    function beforeTokenTransfer(address _from, address _to, uint256) external {
        // Do nothing
    }

    // For bringing back ETH to the giant pool from a savETH vault
    receive() external payable {
        require(liquidStakingDerivativeFactory.isSavETHVault(msg.sender), "Only savETH vault");
    }

    /// @dev Check the msg.sender has enough giant LP to burn and that the pool has enough savETH vault LP
    function _assertUserHasEnoughGiantLPToClaimVaultLP(LPToken _token, uint256 _amount) internal view {
        if (_amount < MIN_STAKING_AMOUNT) revert Errors.InvalidAmount();
        if (_token.balanceOf(address(this)) < _amount) revert Errors.InvalidBalance();
    }

    function _assertContractNotPaused() internal override {
        if (paused()) revert ContractPaused();
    }

    function _init(
        LSDNFactory _factory,
        address _lpDeployer,
        address _feesAndMevGiantPool,
        address _upgradeManager
    ) internal virtual {
        lpTokenETH = GiantLP(GiantLPDeployer(_lpDeployer).deployToken(address(this), address(this), "GiantETHLP", "gETH"));
        liquidStakingDerivativeFactory = _factory;
        feesAndMevGiantPool = _feesAndMevGiantPool;
        batchSize = 24 ether;
        _transferOwnership(_upgradeManager);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { Address } from "@openzeppelin/contracts/utils/Address.sol";

import { StakehouseAPI } from "@blockswaplab/stakehouse-solidity-api/contracts/StakehouseAPI.sol";
import { ITransactionRouter } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/ITransactionRouter.sol";
import { IBalanceReporter } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IBalanceReporter.sol";
import { IDataStructures } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol";
import { IStakeHouseRegistry } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IStakeHouseRegistry.sol";

import { SavETHVaultDeployer } from "./SavETHVaultDeployer.sol";
import { StakingFundsVaultDeployer } from "./StakingFundsVaultDeployer.sol";
import { StakingFundsVault } from "./StakingFundsVault.sol";
import { SavETHVault } from "./SavETHVault.sol";
import { LSDNFactory } from "./LSDNFactory.sol";
import { LPToken } from "./LPToken.sol";
import { LPTokenFactory } from "./LPTokenFactory.sol";
import { SyndicateFactory } from "../syndicate/SyndicateFactory.sol";
import { Syndicate } from "../syndicate/Syndicate.sol";
import { OptionalHouseGatekeeper } from "./OptionalHouseGatekeeper.sol";
import { OptionalGatekeeperFactory } from "./OptionalGatekeeperFactory.sol";
import { OwnableSmartWalletFactory } from "../smart-wallet/OwnableSmartWalletFactory.sol";
import { IOwnableSmartWalletFactory } from "../smart-wallet/interfaces/IOwnableSmartWalletFactory.sol";
import { IOwnableSmartWallet } from "../smart-wallet/interfaces/IOwnableSmartWallet.sol";
import { ISyndicateFactory } from "../interfaces/ISyndicateFactory.sol";
import { ILiquidStakingManager } from "../interfaces/ILiquidStakingManager.sol";
import { IBrandNFT } from "../interfaces/IBrandNFT.sol";
import { IBrandCentral } from "../interfaces/IBrandCentral.sol";
import { IRestrictedTickerRegistry } from "../interfaces/IRestrictedTickerRegistry.sol";
import { ICIP } from "../interfaces/ICIP.sol";
import { ETHTransferHelper } from "../transfer/ETHTransferHelper.sol";

error EmptyArray();
error ZeroAddress();
error OnlyEOA();
error InconsistentArrayLength();
error OnlyDAO();
error OnlyDAOOrNodeRunner();
error InvalidTickerLength();
error TickerAlreadyTaken();
error InvalidAddress();
error NodeRunnerNotWhitelisted();
error NotEnoughETHToStake();
error InvalidAmount();
error GoMintDerivatives();
error HouseAlreadyCreated();
error BLSPubKeyBanned();
error OnlyNodeRunner();
error InitialsNotRegistered();
error DAOKillSwitchNotActivated();
error OnlyCIP();
error NewRunnerHasASmartWallet();
error NodeRunnerNotPermitted();
error BLSKeyAlreadyRegistered();
error BLSKeyNotRegistered();
error InvalidEOA();
error DepositNotCompleted();
error InvalidCommission();
error NothingReceived();

contract LiquidStakingManager is ILiquidStakingManager, Initializable, ReentrancyGuard, StakehouseAPI, ETHTransferHelper {

    /// @notice signalize change in status of whitelisting
    event WhitelistingStatusChanged(address indexed dao, bool updatedStatus);

    /// @notice signalize updated whitelist status of node runner
    event NodeRunnerWhitelistingStatusChanged(address indexed nodeRunner, bool updatedStatus);

    /// @notice signalize creation of a new smart wallet
    event SmartWalletCreated(address indexed smartWallet, address indexed nodeRunner);

    /// @notice signalize appointing of a representative for a smart wallet by the node runner
    event RepresentativeAppointed(address indexed smartWallet, address indexed eoaRepresentative);

    /// @notice signalize staking of a KNOT
    event KnotStaked(bytes _blsPublicKeyOfKnot, address indexed trigerringAddress);

    /// @notice signalize creation of stakehouse
    event StakehouseCreated(string stakehouseTicker, address indexed stakehouse);

    /// @notice signalize joining a stakehouse
    event StakehouseJoined(bytes blsPubKey);

    ///@notice signalize removal of representative from smart wallet
    event RepresentativeRemoved(address indexed smartWallet, address indexed eoaRepresentative);

    /// @notice signalize refund of withdrawal of 4 ETH for a BLS public key by the node runner
    event ETHWithdrawnFromSmartWallet(address indexed associatedSmartWallet, bytes blsPublicKeyOfKnot, address nodeRunner);

    /// @notice signalize that the network has updated its ticker before its house was created
    event NetworkTickerUpdated(string newTicker);

    /// @notice signalize that the node runner has claimed rewards from the syndicate
    event NodeRunnerRewardsClaimed(address indexed nodeRunner, address indexed recipient);

    /// @notice signalize that the node runner of the smart wallet has been rotated
    event NodeRunnerOfSmartWalletRotated(address indexed wallet, address indexed oldRunner, address indexed newRunner);

    /// @notice signalize banning of a node runner
    event NodeRunnerBanned(address indexed nodeRunner);

    /// @notice signalize that the dao management address has been moved
    event UpdateDAOAddress(address indexed oldAddress, address indexed newAddress);

    /// @notice signalize that the dao commission from network revenue has been updated
    event DAOCommissionUpdated(uint256 old, uint256 newCommission);

    /// @notice signalize that a new BLS public key for an LSD validator has been registered
    event NewLSDValidatorRegistered(address indexed nodeRunner, bytes blsPublicKey);

    /// @notice Address of brand NFT
    address public brand;

    /// @notice stakehouse created by the LSD network
    address public override stakehouse;

    /// @notice Fees and MEV EIP1559 distribution contract for the LSD network
    address public syndicate;

    /// @notice address of the DAO deploying the contract
    address public dao;

    /// @notice address of optional gatekeeper for admiting new knots to the house created by the network
    OptionalHouseGatekeeper public gatekeeper;

    /// @notice instance of the syndicate factory that deploys the syndicates
    ISyndicateFactory public syndicateFactory;

    /// @notice instance of the smart wallet factory that deploys the smart wallets for node runners
    IOwnableSmartWalletFactory public smartWalletFactory;

    /// @notice string name for the stakehouse 3-5 characters long
    string public stakehouseTicker;

    /// @notice DAO staking funds vault
    StakingFundsVault public stakingFundsVault;

    /// @notice SavETH vault
    SavETHVault public savETHVault;

    /// @notice Address of the factory that deployed the liquid staking manager
    LSDNFactory public factory;

    /// @notice whitelisting indicator. true for enables and false for disabled
    bool public enableWhitelisting;

    /// @notice mapping to store if a node runner is whitelisted
    mapping(address => bool) public isNodeRunnerWhitelisted;

    /// @notice EOA representative appointed for a smart wallet
    mapping(address => address) public smartWalletRepresentative;

    /// @notice Smart wallet used to deploy KNOT
    mapping(bytes => address) public smartWalletOfKnot;

    /// @notice Smart wallet issued to the Node runner. Node runner address <> Smart wallet address
    mapping(address => address) public smartWalletOfNodeRunner;

    /// @notice Node runner issued to Smart wallet. Smart wallet address <> Node runner address
    mapping(address => address) public nodeRunnerOfSmartWallet;

    /// @notice Track number of staked KNOTs of a smart wallet
    mapping(address => uint256) public stakedKnotsOfSmartWallet;

    /// @notice smart wallet <> dormant rep.
    mapping(address => address) public smartWalletDormantRepresentative;

    /// @notice Track BLS public keys that have been banned. 
    /// If banned, the BLS public key will be mapped to its respective smart wallet
    mapping(bytes => address) public bannedBLSPublicKeys;

    /// @notice Track node runner addresses that are banned.
    /// Malicious node runners can be banned by the DAO
    mapping(address => bool) public bannedNodeRunners;

    /// @notice count of KNOTs interacted with LSD network
    uint256 public numberOfKnots;

    /// @notice Commission percentage to 5 decimal places
    uint256 public daoCommissionPercentage;

    /// @notice 100% to 5 decimal places
    uint256 public constant MODULO = 100_00000;

    /// @notice Maximum commission that can be requested from the DAO
    uint256 public constant MAX_COMMISSION = MODULO / 2;

    modifier onlyDAO() {
        if (msg.sender != dao) revert OnlyDAO();
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc ILiquidStakingManager
    function init(
        address _dao,
        address _syndicateFactory,
        address _smartWalletFactory,
        address _lpTokenFactory,
        address _brand,
        address _savETHVaultDeployer,
        address _stakingFundsVaultDeployer,
        address _optionalGatekeeperDeployer,
        uint256 _optionalCommission,
        bool _deployOptionalGatekeeper,
        string calldata _stakehouseTicker
    ) external virtual override initializer {
        _init(
            _dao,
            _syndicateFactory,
            _smartWalletFactory,
            _lpTokenFactory,
            _brand,
            _savETHVaultDeployer,
            _stakingFundsVaultDeployer,
            _optionalGatekeeperDeployer,
            _optionalCommission,
            _deployOptionalGatekeeper,
            _stakehouseTicker
        );
    }

    /// @notice Allow DAO or node runner to recover the signing key of a validator
    /// @param _safeBox Address of the safe box performing recovery
    /// @param _nodeRunner Address of the node runner associated with a BLS key
    /// @param _blsPublicKey BLS public key of validator requesting signing key recovery
    /// @param _hAesPublicKey Hybrid encryption public key that can unlock multiparty computation used for recovery
    function recoverSigningKey(
        address _safeBox,
        address _nodeRunner,
        bytes calldata _blsPublicKey,
        bytes calldata _hAesPublicKey
    ) external nonReentrant {
        address smartWallet = smartWalletOfNodeRunner[_nodeRunner];
        if (smartWallet == address(0)) revert ZeroAddress();
        if (smartWalletOfKnot[_blsPublicKey] != smartWallet) revert BLSKeyNotRegistered();
        if (msg.sender != dao && msg.sender != _nodeRunner) revert OnlyDAOOrNodeRunner();
        IOwnableSmartWallet(smartWallet).execute(
            _safeBox,
            abi.encodeWithSelector(
                ICIP.applyForDecryption.selector,
                _blsPublicKey,
                stakehouse,
                _hAesPublicKey
            )
        );
    }

    /// @notice Allow the rage quit of a knot from the Stakehouse protocol
    /// @param _nodeRunner Address of the node runner that has a smart wallet associated with the BLS public key
    /// @param _blsPublicKey BLS public key of the KNOT being rage quit
    /// @param _balanceReport of the KNOT before rage quit
    /// @param _signature Signature from the designated verifier over the balance report
    function rageQuit(
        address _nodeRunner,
        bytes calldata _blsPublicKey,
        IDataStructures.ETH2DataReport calldata _balanceReport,
        IDataStructures.EIP712Signature calldata _signature
    ) external {
        address smartWallet = smartWalletOfNodeRunner[_nodeRunner];
        if (smartWallet == address(0)) revert ZeroAddress();
        if (smartWalletOfKnot[_blsPublicKey] != smartWallet) revert BLSKeyNotRegistered();
        if (msg.sender != dao && msg.sender != _nodeRunner) revert OnlyDAOOrNodeRunner();
        IOwnableSmartWallet(smartWallet).execute(
            address(getTransactionRouter()),
            abi.encodeWithSelector(
                IBalanceReporter.rageQuitKnot.selector,
                stakehouse,
                _blsPublicKey,
                _balanceReport,
                _signature
            )
        );
    }

    /// @notice After kill switch has been enabled by the DAO, allow a node operator to transfer ownership of their smart wallet
    /// @param _newOwner Address of the account that will take ownership of wallet and collateralized slot
    function transferSmartWalletOwnership(address _newOwner) external {
        if (dao != address(0)) revert DAOKillSwitchNotActivated();

        address smartWallet = smartWalletOfNodeRunner[msg.sender];
        if (smartWallet == address(0)) revert ZeroAddress();

        IOwnableSmartWallet(smartWallet).transferOwnership(_newOwner);
    }

    /// @notice Allow the DAO to manage whether the house can received members outside LSD (if it has a deployed gatekeeper)
    function toggleHouseGatekeeper(bool _enabled) external onlyDAO {
        if (_enabled) {
            IStakeHouseRegistry(stakehouse).setGateKeeper(address(gatekeeper));
        } else {
            IStakeHouseRegistry(stakehouse).setGateKeeper(address(0));
        }
    }

    /// @notice For knots no longer operational, DAO can de register the knot from the syndicate
    function deRegisterKnotFromSyndicate(bytes[] calldata _blsPublicKeys) external onlyDAO nonReentrant {
        Syndicate(payable(syndicate)).deRegisterKnots(_blsPublicKeys);
    }

    /// @notice Allows the DAO to append to the list of knots that are part of the syndicate
    /// @param _newBLSPublicKeyBeingRegistered List of BLS public keys being added to the syndicate
    function registerKnotsToSyndicate(
        bytes[] calldata _newBLSPublicKeyBeingRegistered
    ) external onlyDAO nonReentrant {
        Syndicate(payable(syndicate)).registerKnotsToSyndicate(_newBLSPublicKeyBeingRegistered);
    }

    /// @notice Allows the DAO to manage the syndicate activation distance based on the consensus layer activation queue
    function updateSyndicateActivationDistanceInBlocks(uint256 _distance) external onlyDAO {
        Syndicate(payable(syndicate)).updateActivationDistanceInBlocks(_distance);
    }

    /// @notice Configure the house that users are joining when minting derivatives only for an empty LSD network
    function configureStakeHouse(bytes calldata _blsPublicKeyOfKnot) external onlyDAO {
        if (numberOfKnots != 0) revert HouseAlreadyCreated();

        numberOfKnots = 1;
        stakehouse = getStakeHouseUniverse().memberKnotToStakeHouse(_blsPublicKeyOfKnot);
        if (stakehouse == address(0)) revert ZeroAddress();

        _deploySyndicateAndApproveSETH(_blsPublicKeyOfKnot, IERC20(getSlotRegistry().stakeHouseShareTokens(stakehouse)));
    }

    /// @notice Liquid staking DAO can set the description and image of the brand NFT for the network
    function updateBrandInfo(
        uint256 _tokenId, string calldata _description, string calldata _imageURI
    ) external onlyDAO {
        IBrandNFT(brand).setBrandMetadata(_tokenId, _description, _imageURI);
    }

    /// @notice Allow DAO to migrate to a new address
    function updateDAOAddress(address _newAddress) external onlyDAO {
        emit UpdateDAOAddress(dao, _newAddress);
        dao = _newAddress;
    }

    /// @notice Allow DAO to take a commission of network revenue
    function updateDAORevenueCommission(uint256 _commissionPercentage) external onlyDAO {
        _updateDAORevenueCommission(_commissionPercentage);
    }

    /// @notice Allow the DAO to rotate the network ticker before the network house is created
    function updateTicker(string calldata _newTicker) external onlyDAO {
        _updateTicker(_newTicker);
    }

    /// @notice function to change whether node runner whitelisting of node runners is required by the DAO
    /// @param _changeWhitelist boolean value. true to enable and false to disable
    function updateWhitelisting(bool _changeWhitelist) external onlyDAO returns (bool) {
        enableWhitelisting = _changeWhitelist;
        emit WhitelistingStatusChanged(msg.sender, enableWhitelisting);

        return enableWhitelisting;
    }

    /// @notice Function to enable/disable whitelisting of a multiple node operators
    /// @param _nodeRunners List of node runners being whitelisted
    /// @param isWhitelisted true if the node runner should be whitelisted. false otherwise.
    function updateNodeRunnerWhitelistStatus(address[] calldata _nodeRunners, bool isWhitelisted) external onlyDAO {
        for (uint256 i; i < _nodeRunners.length; ++i) {
            isNodeRunnerWhitelisted[_nodeRunners[i]] = isWhitelisted;
            emit NodeRunnerWhitelistingStatusChanged(_nodeRunners[i], isWhitelisted);
        }
    }

    /// @notice Allow a node runner to rotate the EOA representative they use for their smart wallet
    /// @dev if any KNOT is staked for a smart wallet, no rep can be appointed or updated until the derivatives are minted
    /// @param _newRepresentative address of the new representative to be appointed
    function rotateEOARepresentative(address _newRepresentative) external {
        if (Address.isContract(_newRepresentative)) revert OnlyEOA();
        if (_newRepresentative == address(0)) revert ZeroAddress();

        address smartWallet = smartWalletOfNodeRunner[msg.sender];
        if (smartWallet == address(0)) revert OnlyNodeRunner();
        if (stakedKnotsOfSmartWallet[smartWallet] != 0) revert GoMintDerivatives();

        // unauthorize old representative
        _authorizeRepresentative(smartWallet, smartWalletRepresentative[smartWallet], false);

        // authorize new representative
        _authorizeRepresentative(smartWallet, _newRepresentative, true);
    }

    /// @notice Allow node runners to withdraw ETH from their smart wallet. ETH can only be withdrawn until the KNOT has not been staked.
    /// @dev A banned node runner cannot withdraw ETH for the KNOT. 
    /// @param _blsPublicKeyOfKnot BLS public key of the KNOT for which the ETH needs to be withdrawn
    function withdrawETHForKnot(address _recipient, bytes calldata _blsPublicKeyOfKnot) external nonReentrant {
        if (_recipient == address(0)) revert ZeroAddress();
        if (!isBLSPublicKeyPartOfLSDNetwork(_blsPublicKeyOfKnot)) revert BLSKeyNotRegistered();
        if (isBLSPublicKeyBanned(_blsPublicKeyOfKnot)) revert BLSPubKeyBanned();

        address associatedSmartWallet = smartWalletOfKnot[_blsPublicKeyOfKnot];
        if (smartWalletOfNodeRunner[msg.sender] != associatedSmartWallet) revert OnlyNodeRunner();
        if (
            getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnot) != IDataStructures.LifecycleStatus.INITIALS_REGISTERED
        ) revert InitialsNotRegistered();

        // update the mapping
        bannedBLSPublicKeys[_blsPublicKeyOfKnot] = associatedSmartWallet;

        // refund 4 ether from smart wallet to node runner's EOA
        IOwnableSmartWallet(associatedSmartWallet).rawExecute(_recipient, "", 4 ether);

        emit ETHWithdrawnFromSmartWallet(associatedSmartWallet, _blsPublicKeyOfKnot, msg.sender);
    }

    /// @notice In the event the node runner coordinates with the DAO to sell their wallet, allow rotation
    /// @dev EOA representative rotation done outside this method because there may be knots currently staked etc.
    /// @param _current address of the present node runner of the smart wallet
    /// @param _new address of the new node runner of the smart wallet
    function manageNodeRunnerSmartWallet(
        address _current,
        address _new,
        bool _wasPreviousNodeRunnerMalicious
    ) external onlyDAO {
        if (_new != address(0) && _new != _current) {
            address wallet = smartWalletOfNodeRunner[_current];
            if (wallet == address(0)) revert ZeroAddress();
            if (wallet.balance >= 4 ether) revert InvalidAmount();

            if (smartWalletOfNodeRunner[_new] != address(0)) revert NewRunnerHasASmartWallet();

            smartWalletOfNodeRunner[_new] = wallet;
            nodeRunnerOfSmartWallet[wallet] = _new;

            delete smartWalletOfNodeRunner[_current];

            emit NodeRunnerOfSmartWalletRotated(wallet, _current, _new);
        }

        if (_wasPreviousNodeRunnerMalicious) {
            bannedNodeRunners[_current] = true;
            emit NodeRunnerBanned(_current);
        }
    }

    /// @notice function to allow a node runner to claim ETH from the syndicate from their smart wallet
    /// @param _recipient End recipient of ETH from syndicate rewards
    /// @param _blsPubKeys list of BLS public keys to claim reward for
    function claimRewardsAsNodeRunner(
        address _recipient,
        bytes[] calldata _blsPubKeys
    ) external nonReentrant {
        uint256 numOfKeys = _blsPubKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        if (_recipient == address(0)) revert ZeroAddress();

        address smartWallet = smartWalletOfNodeRunner[msg.sender];
        if (smartWallet == address(0)) revert ZeroAddress();

        for(uint256 i; i < numOfKeys; ++i) {
            // check that the node runner doesn't claim rewards for KNOTs from other smart wallets
            if (smartWalletOfKnot[_blsPubKeys[i]] != smartWallet) revert OnlyNodeRunner();
        }

        // Fetch ETH accrued
        uint256 balBefore = address(this).balance;
        IOwnableSmartWallet(smartWallet).execute(
            syndicate,
            abi.encodeWithSelector(
                Syndicate.claimAsCollateralizedSLOTOwner.selector,
                address(this),
                _blsPubKeys
            )
        );

        (uint256 nodeRunnerAmount, uint256 daoAmount) = _calculateCommission(address(this).balance - balBefore);

        _transferETH(_recipient, nodeRunnerAmount);

        if (daoAmount > 0) _transferETH(dao, daoAmount);

        emit NodeRunnerRewardsClaimed(msg.sender, _recipient);
    }

    /// @notice register a node runner to LSD by creating a new smart wallet
    /// @param _blsPublicKeys list of BLS public keys
    /// @param _blsSignatures list of BLS signatures
    /// @param _eoaRepresentative EOA representative of wallet
    function registerBLSPublicKeys(
        bytes[] calldata _blsPublicKeys,
        bytes[] calldata _blsSignatures,
        address _eoaRepresentative
    ) external payable nonReentrant {
        uint256 len = _blsPublicKeys.length;
        if (len == 0) revert EmptyArray();
        if (len != _blsSignatures.length) revert InconsistentArrayLength();
        if (msg.value != len * 4 ether) revert InvalidAmount();
        if (Address.isContract(_eoaRepresentative)) revert OnlyEOA();
        if (!_isNodeRunnerValid(msg.sender)) revert NodeRunnerNotPermitted();
        if (isNodeRunnerBanned(msg.sender)) revert NodeRunnerNotPermitted();

        address smartWallet = smartWalletOfNodeRunner[msg.sender];

        if(smartWallet == address(0)) {
            // create new wallet owned by liquid staking manager
            smartWallet = smartWalletFactory.createWallet(address(this));
            emit SmartWalletCreated(smartWallet, msg.sender);

            // associate node runner with the newly created wallet
            smartWalletOfNodeRunner[msg.sender] = smartWallet;
            nodeRunnerOfSmartWallet[smartWallet] = msg.sender;

            _authorizeRepresentative(smartWallet, _eoaRepresentative, true);
        }

        // Ensure that the node runner does not whitelist multiple EOA representatives - they can only have 1 active at a time
        if(smartWalletRepresentative[smartWallet] != address(0)) {
            if (smartWalletRepresentative[smartWallet] != _eoaRepresentative) revert InvalidEOA();
        }

        // transfer ETH to smart wallet
        _transferETH(smartWallet, msg.value);

        for(uint256 i; i < len; ++i) {
            bytes calldata _blsPublicKey = _blsPublicKeys[i];

            // check if the BLS public key is part of LSD network and is not banned
            if (isBLSPublicKeyPartOfLSDNetwork(_blsPublicKey)) revert BLSKeyAlreadyRegistered();
            if (bannedBLSPublicKeys[_blsPublicKey] != address(0)) revert BLSPubKeyBanned();

            if (
                getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKey) != IDataStructures.LifecycleStatus.UNBEGUN
            ) revert BLSKeyAlreadyRegistered();

            // register validtor initals for each of the KNOTs
            IOwnableSmartWallet(smartWallet).execute(
                address(getTransactionRouter()),
                abi.encodeWithSelector(
                    ITransactionRouter.registerValidatorInitials.selector,
                    smartWallet,
                    _blsPublicKey,
                    _blsSignatures[i]
                )
            );

            // register the smart wallet with the BLS public key
            smartWalletOfKnot[_blsPublicKey] = smartWallet;

            emit NewLSDValidatorRegistered(msg.sender, _blsPublicKey);
        }
    }

    /// @inheritdoc ILiquidStakingManager
    function isBLSPublicKeyPartOfLSDNetwork(bytes calldata _blsPublicKeyOfKnot) public virtual view returns (bool) {
        return smartWalletOfKnot[_blsPublicKeyOfKnot] != address(0);
    }

    /// @inheritdoc ILiquidStakingManager
    function isBLSPublicKeyBanned(bytes calldata _blsPublicKeyOfKnot) public virtual view returns (bool) {
        bool isPartOfNetwork = isBLSPublicKeyPartOfLSDNetwork(_blsPublicKeyOfKnot);
        return !isPartOfNetwork ? true : bannedBLSPublicKeys[_blsPublicKeyOfKnot] != address(0);
    }

    /// @notice function to check if a node runner address is banned
    /// @param _nodeRunner address of the node runner
    /// @return true if the node runner is banned, false otherwise
    function isNodeRunnerBanned(address _nodeRunner) public view returns (bool) {
        return bannedNodeRunners[_nodeRunner];
    }

    /// @notice Anyone can call this to trigger staking once they have all of the required input params from BLS authentication
    /// @param _blsPublicKeyOfKnots List of knots being staked with the Ethereum deposit contract (32 ETH sourced within the network)
    /// @param _ciphertexts List of backed up validator operations encrypted and stored to the Ethereum blockchain
    /// @param _aesEncryptorKeys List of public identifiers of credentials that performed the trustless backup
    /// @param _encryptionSignatures List of EIP712 signatures attesting to the correctness of the BLS signature
    /// @param _dataRoots List of serialized SSZ containers of the DepositData message for each validator used by Ethereum deposit contract
    function stake(
        bytes[] calldata _blsPublicKeyOfKnots,
        bytes[] calldata _ciphertexts,
        bytes[] calldata _aesEncryptorKeys,
        IDataStructures.EIP712Signature[] calldata _encryptionSignatures,
        bytes32[] calldata _dataRoots
    ) external nonReentrant {
        uint256 numOfValidators = _blsPublicKeyOfKnots.length;
        if (numOfValidators == 0) revert EmptyArray();
        if (numOfValidators != _ciphertexts.length) revert InconsistentArrayLength();
        if (numOfValidators != _aesEncryptorKeys.length) revert InconsistentArrayLength();
        if (numOfValidators != _encryptionSignatures.length) revert InconsistentArrayLength();
        if (numOfValidators != _dataRoots.length) revert InconsistentArrayLength();

        for (uint256 i; i < numOfValidators; ++i) {
            bytes calldata blsPubKey = _blsPublicKeyOfKnots[i];
            // check if BLS public key is registered with liquid staking derivative network and not banned
            if (isBLSPublicKeyBanned(blsPubKey)) revert BLSPubKeyBanned();

            address associatedSmartWallet = smartWalletOfKnot[blsPubKey];
            if (associatedSmartWallet == address(0)) revert InitialsNotRegistered();
            if (isNodeRunnerBanned(nodeRunnerOfSmartWallet[associatedSmartWallet])) revert NodeRunnerNotPermitted();
            if (
                getAccountManager().blsPublicKeyToLifecycleStatus(blsPubKey) != IDataStructures.LifecycleStatus.INITIALS_REGISTERED
            ) revert InitialsNotRegistered();

            // check minimum balance of smart wallet, dao staking fund vault and savETH vault
            _assertEtherIsReadyForValidatorStaking(blsPubKey);

            _stake(
                blsPubKey,
                _ciphertexts[i],
                _aesEncryptorKeys[i],
                _encryptionSignatures[i],
                _dataRoots[i]
            );

            address representative = smartWalletRepresentative[associatedSmartWallet];

            if(representative != address(0)) {
                // unauthorize the EOA representative on the Stakehouse
                _authorizeRepresentative(associatedSmartWallet, representative, false);
                // make the representative dormant before unauthorizing it
                smartWalletDormantRepresentative[associatedSmartWallet] = representative;
            }
        }
    }

    /// @notice Anyone can call this to trigger creating a knot which will mint derivatives once the balance has been reported
    /// @param _blsPublicKeyOfKnots List of BLS public keys registered with the network becoming knots and minting derivatives
    /// @param _beaconChainBalanceReports List of beacon chain balance reports
    /// @param _reportSignatures List of attestations for the beacon chain balance reports
    function mintDerivatives(
        bytes[] calldata _blsPublicKeyOfKnots,
        IDataStructures.ETH2DataReport[] calldata _beaconChainBalanceReports,
        IDataStructures.EIP712Signature[] calldata _reportSignatures
    ) external nonReentrant {
        uint256 numOfKnotsToProcess = _blsPublicKeyOfKnots.length;
        if (numOfKnotsToProcess == 0) revert EmptyArray();
        if (numOfKnotsToProcess != _beaconChainBalanceReports.length) revert InconsistentArrayLength();
        if (numOfKnotsToProcess != _reportSignatures.length) revert InconsistentArrayLength();

        for (uint256 i; i < numOfKnotsToProcess; ++i) {
            // check if BLS public key is registered and not banned
            if (isBLSPublicKeyBanned(_blsPublicKeyOfKnots[i])) revert BLSPubKeyBanned();

            // check that the BLS pub key has deposited lifecycle
            if(
                getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnots[i]) != IDataStructures.LifecycleStatus.DEPOSIT_COMPLETED
            ) revert DepositNotCompleted();

            // Expand the staking funds vault shares that can claim rewards
            stakingFundsVault.updateDerivativesMinted(_blsPublicKeyOfKnots[i]);

            // Poke the giant pools in the event they need to know about the minting of derivatives they funded
            factory.giantSavETHPool().onMintDerivatives(_blsPublicKeyOfKnots[i]);
            factory.giantFeesAndMev().onMintDerivatives(_blsPublicKeyOfKnots[i]);

            // The first knot will create the Stakehouse
            if(numberOfKnots == 0) {
                _createLSDNStakehouse(
                    _blsPublicKeyOfKnots[i],
                    _beaconChainBalanceReports[i],
                    _reportSignatures[i]
                );
            }
            else {
                // join stakehouse
                _joinLSDNStakehouse(
                    _blsPublicKeyOfKnots[i],
                    _beaconChainBalanceReports[i],
                    _reportSignatures[i]
                );
            }

            address smartWallet = smartWalletOfKnot[_blsPublicKeyOfKnots[i]];
            stakedKnotsOfSmartWallet[smartWallet] -= 1;

            if(stakedKnotsOfSmartWallet[smartWallet] == 0) {
                _authorizeRepresentative(smartWallet, smartWalletDormantRepresentative[smartWallet], true);

                // delete the dormant representative as it is set active
                delete smartWalletDormantRepresentative[smartWallet];
            }
        }
    }

    receive() external payable {}

    /// @notice Every liquid staking derivative network has a single fee recipient determined by its syndicate contract
    /// @dev The syndicate contract is only deployed after the first KNOT to mint derivatives creates the network Stakehouse
    /// @dev Because the syndicate contract for the LSDN is deployed with CREATE2, we can predict the fee recipient ahead of time
    /// @dev This is important because node runners need to configure their nodes before or immediately after staking
    function getNetworkFeeRecipient() external view returns (address) {
        // Always 1 knot initially registered to the syndicate because we expand it one by one
        return syndicateFactory.calculateSyndicateDeploymentAddress(
            address(this),
            address(this),
            1
        );
    }

    /// @dev Internal method for managing the initialization of the staking manager contract
    function _init(
        address _dao,
        address _syndicateFactory,
        address _smartWalletFactory,
        address _lpTokenFactory,
        address _brand,
        address _savETHVaultDeployer,
        address _stakingFundsVaultDeployer,
        address _optionalGatekeeperDeployer,
        uint256 _optionalCommission,
        bool _deployOptionalGatekeeper,
        string calldata _stakehouseTicker
    ) internal {
        if (_dao == address(0)) revert ZeroAddress();

        brand = _brand;
        dao = _dao;
        syndicateFactory = ISyndicateFactory(_syndicateFactory);
        smartWalletFactory = IOwnableSmartWalletFactory(_smartWalletFactory);

        _updateTicker(_stakehouseTicker);

        _updateDAORevenueCommission(_optionalCommission);

        _initStakingFundsVault(_stakingFundsVaultDeployer, _lpTokenFactory);
        _initSavETHVault(_savETHVaultDeployer, _lpTokenFactory);

        factory = LSDNFactory(msg.sender);

        if (_deployOptionalGatekeeper) {
            gatekeeper = OptionalGatekeeperFactory(_optionalGatekeeperDeployer).deploy(address(this));
            enableWhitelisting = true;
            emit WhitelistingStatusChanged(dao, enableWhitelisting);
        }
    }

    /// @dev function checks if a node runner is valid depending upon whitelisting status
    /// @param _nodeRunner address of the user requesting to become node runner
    /// @return true if eligible. reverts with message if not eligible
    function _isNodeRunnerValid(address _nodeRunner) internal view returns (bool) {
        return enableWhitelisting && !isNodeRunnerWhitelisted[_nodeRunner] ? false : true;
    }

    /// @dev Manage the removal and appointing of smart wallet representatives including managing state
    function _authorizeRepresentative(
        address _smartWallet, 
        address _eoaRepresentative, 
        bool _isEnabled
    ) internal {
        if(!_isEnabled && smartWalletRepresentative[_smartWallet] != address(0)) {

            // authorize the EOA representative on the Stakehouse
            IOwnableSmartWallet(_smartWallet).execute(
                address(getTransactionRouter()),
                abi.encodeWithSelector(
                    ITransactionRouter.authorizeRepresentative.selector,
                    _eoaRepresentative,
                    _isEnabled
                )
            );

            // delete the mapping
            delete smartWalletRepresentative[_smartWallet];

            emit RepresentativeRemoved(_smartWallet, _eoaRepresentative);
        }
        else if(_isEnabled && smartWalletRepresentative[_smartWallet] == address(0)) {

            // authorize the EOA representative on the Stakehouse
            IOwnableSmartWallet(_smartWallet).execute(
                address(getTransactionRouter()),
                abi.encodeWithSelector(
                    ITransactionRouter.authorizeRepresentative.selector,
                    _eoaRepresentative,
                    _isEnabled
                )
            );

            // store EOA to the wallet mapping
            smartWalletRepresentative[_smartWallet] = _eoaRepresentative;

            emit RepresentativeAppointed(_smartWallet, _eoaRepresentative);
        } else {
            revert("Error");
        }
    }

    /// @dev Internal method for doing just staking - pre-checks done outside this method to avoid stack too deep
    function _stake(
        bytes calldata _blsPublicKey,
        bytes calldata _cipherText,
        bytes calldata _aesEncryptorKey,
        IDataStructures.EIP712Signature calldata _encryptionSignature,
        bytes32 dataRoot
    ) internal {
        address smartWallet = smartWalletOfKnot[_blsPublicKey];

        // send 24 ether from savETH vault to smart wallet
        savETHVault.withdrawETHForStaking(smartWallet, 24 ether);

        // send 4 ether from DAO staking funds vault
        stakingFundsVault.withdrawETH(smartWallet, 4 ether);

        // interact with transaction router using smart wallet to deposit 32 ETH
        IOwnableSmartWallet(smartWallet).execute(
            address(getTransactionRouter()),
            abi.encodeWithSelector(
                ITransactionRouter.registerValidator.selector,
                smartWallet,
                _blsPublicKey,
                _cipherText,
                _aesEncryptorKey,
                _encryptionSignature,
                dataRoot
            ),
            32 ether
        );

        // increment number of staked KNOTs in the wallet
        stakedKnotsOfSmartWallet[smartWallet] += 1;

        emit KnotStaked(_blsPublicKey, msg.sender);
    }

    /// @dev The second knot onwards will join the LSDN stakehouse and expand the registered syndicate knots
    function _joinLSDNStakehouse(
        bytes calldata _blsPubKey,
        IDataStructures.ETH2DataReport calldata _beaconChainBalanceReport,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) internal {
        // total number of knots created with the syndicate increases
        numberOfKnots += 1;

        // The savETH will go to the savETH vault, the collateralized SLOT for syndication owned by the smart wallet
        // sETH will also be minted in the smart wallet but will be moved out and distributed to the syndicate for claiming by the DAO
        address associatedSmartWallet = smartWalletOfKnot[_blsPubKey];

        // Join the LSDN stakehouse
        string memory lowerTicker = IBrandNFT(brand).toLowerCase(stakehouseTicker);
        IOwnableSmartWallet(associatedSmartWallet).execute(
            address(getTransactionRouter()),
            abi.encodeWithSelector(
                ITransactionRouter.joinStakehouse.selector,
                associatedSmartWallet,
                _blsPubKey,
                stakehouse,
                IBrandNFT(brand).lowercaseBrandTickerToTokenId(lowerTicker),
                savETHVault.indexOwnedByTheVault(),
                _beaconChainBalanceReport,
                _reportSignature
            )
        );

        // Register the knot to the syndicate
        bytes[] memory _blsPublicKeyOfKnots = new bytes[](1);
        _blsPublicKeyOfKnots[0] = _blsPubKey;
        Syndicate(payable(syndicate)).registerKnotsToSyndicate(_blsPublicKeyOfKnots);

        // Autostake DAO sETH with the syndicate
        _autoStakeWithSyndicate(associatedSmartWallet, _blsPubKey);

        emit StakehouseJoined(_blsPubKey);
    }

    /// @dev Perform all the steps required to create the LSDN stakehouse that other knots will join
    function _createLSDNStakehouse(
        bytes calldata _blsPublicKeyOfKnot,
        IDataStructures.ETH2DataReport calldata _beaconChainBalanceReport,
        IDataStructures.EIP712Signature calldata _reportSignature
    ) internal {
        // create stakehouse and mint derivative for first bls key - the others are just used to create the syndicate
        // The savETH will go to the savETH vault, the collateralized SLOT for syndication owned by the smart wallet
        // sETH will also be minted in the smart wallet but will be moved out and distributed to the syndicate for claiming by the DAO
        address associatedSmartWallet = smartWalletOfKnot[_blsPublicKeyOfKnot];
        IOwnableSmartWallet(associatedSmartWallet).execute(
            address(getTransactionRouter()),
            abi.encodeWithSelector(
                ITransactionRouter.createStakehouse.selector,
                associatedSmartWallet,
                _blsPublicKeyOfKnot,
                stakehouseTicker,
                savETHVault.indexOwnedByTheVault(),
                _beaconChainBalanceReport,
                _reportSignature
            )
        );

        // Number of knots has increased
        numberOfKnots += 1;

        // Capture the address of the Stakehouse for future knots to join
        stakehouse = getStakeHouseUniverse().memberKnotToStakeHouse(_blsPublicKeyOfKnot);
        IERC20 sETH = IERC20(getSlotRegistry().stakeHouseShareTokens(stakehouse));

        // Give liquid staking manager ability to manage keepers and set a house keeper if decided by the network
        IOwnableSmartWallet(associatedSmartWallet).execute(
            stakehouse,
            abi.encodeWithSelector(
                Ownable.transferOwnership.selector,
                address(this)
            )
        );

        IStakeHouseRegistry(stakehouse).setGateKeeper(address(gatekeeper));

        // Let the liquid staking manager take ownership of the brand NFT for management
        IOwnableSmartWallet(associatedSmartWallet).execute(
            brand,
            abi.encodeWithSelector(
                IBrandNFT.transferFrom.selector,
                associatedSmartWallet,
                address(this),
                IBrandNFT(brand).lowercaseBrandTickerToTokenId(IBrandNFT(brand).toLowerCase(stakehouseTicker))
            )
        );

        // Approve any future sETH for being staked in the Syndicate
        _deploySyndicateAndApproveSETH(_blsPublicKeyOfKnot, sETH);

        // Auto-stake sETH by pulling sETH out the smart wallet and staking in the syndicate
        _autoStakeWithSyndicate(associatedSmartWallet, _blsPublicKeyOfKnot);

        emit StakehouseCreated(stakehouseTicker, stakehouse);
    }

    function _deploySyndicateAndApproveSETH(
        bytes calldata _blsPublicKeyOfKnot,
        IERC20 _sETH
    ) internal {
        // Deploy the EIP1559 transaction reward sharing contract but no priority required because sETH will be auto staked
        address[] memory priorityStakers = new address[](0);
        bytes[] memory initialKnots = new bytes[](1);
        initialKnots[0] = _blsPublicKeyOfKnot;
        syndicate = syndicateFactory.deploySyndicate(
            address(this),
            0,
            priorityStakers,
            initialKnots
        );

        // Contract approves syndicate to take sETH on behalf of the DAO
        _sETH.approve(syndicate, (2 ** 256) - 1);
    }

    /// @dev Remove the sETH from the node runner smart wallet in order to auto-stake the sETH in the syndicate
    function _autoStakeWithSyndicate(address _associatedSmartWallet, bytes memory _blsPubKey) internal {
        IERC20 sETH = IERC20(getSlotRegistry().stakeHouseShareTokens(stakehouse));

        uint256 stakeAmount = 12 ether;
        IOwnableSmartWallet(_associatedSmartWallet).execute(
            address(sETH),
            abi.encodeWithSelector(
                IERC20.transfer.selector,
                address(this),
                stakeAmount
            )
        );

        // Create the payload for staking
        bytes[] memory stakingKeys = new bytes[](1);
        stakingKeys[0] = _blsPubKey;

        uint256[] memory stakeAmounts = new uint256[](1);
        stakeAmounts[0] = stakeAmount;

        // Stake the sETH to be received by the LPs of the Staking Funds Vault (fees and mev)
        Syndicate(payable(syndicate)).stake(stakingKeys, stakeAmounts, address(stakingFundsVault));
    }

    /// @dev Something that can be overriden during testing
    function _initSavETHVault(address _savETHVaultDeployer, address _lpTokenFactory) internal virtual {
        // Use an external deployer to reduce the size of the liquid staking manager
        savETHVault = SavETHVault(
            SavETHVaultDeployer(_savETHVaultDeployer).deploySavETHVault(address(this), _lpTokenFactory)
        );
    }

    /// @dev Something that can be overriden during testing
    function _initStakingFundsVault(address _stakingFundsVaultDeployer, address _tokenFactory) internal virtual {
        stakingFundsVault = StakingFundsVault(
            payable(StakingFundsVaultDeployer(_stakingFundsVaultDeployer).deployStakingFundsVault(
                address(this),
                _tokenFactory
            ))
        );
    }

    /// @dev This can be overriden to customise fee percentages
    function _calculateCommission(uint256 _received) internal virtual view returns (uint256 _nodeRunner, uint256 _dao) {
        if (_received == 0) revert NothingReceived();

        if (daoCommissionPercentage > 0) {
            uint256 daoAmount = (_received * daoCommissionPercentage) / MODULO;
            uint256 rest = _received - daoAmount;
            return (rest, daoAmount);
        }

        return (_received, 0);
    }

    /// @dev Check the savETH vault, staking funds vault and node runner smart wallet to ensure 32 ether required for staking has been achieved
    function _assertEtherIsReadyForValidatorStaking(bytes calldata blsPubKey) internal view {
        address associatedSmartWallet = smartWalletOfKnot[blsPubKey];
        if (associatedSmartWallet.balance < 4 ether) revert NotEnoughETHToStake();

        LPToken stakingFundsLP = stakingFundsVault.lpTokenForKnot(blsPubKey);
        if (stakingFundsLP.totalSupply() < 4 ether) revert NotEnoughETHToStake();

        LPToken savETHVaultLP = savETHVault.lpTokenForKnot(blsPubKey);
        if (savETHVaultLP.totalSupply() < 24 ether) revert NotEnoughETHToStake();
    }

    /// @dev Internal method for dao to trigger updating commission it takes of node runner revenue
    function _updateDAORevenueCommission(uint256 _commissionPercentage) internal {
        if (_commissionPercentage > MAX_COMMISSION) revert InvalidCommission();

        emit DAOCommissionUpdated(daoCommissionPercentage, _commissionPercentage);

        daoCommissionPercentage = _commissionPercentage;
    }

    /// @dev Re-usable logic for updating LSD ticker used to mint derivatives
    function _updateTicker(string calldata _newTicker) internal {
        if (bytes(_newTicker).length < 3 || bytes(_newTicker).length > 5) revert InvalidTickerLength();
        if (numberOfKnots != 0) revert HouseAlreadyCreated();

        IBrandNFT brandNFT = IBrandNFT(brand);
        string memory lowerTicker = brandNFT.toLowerCase(_newTicker);
        if (
            brandNFT.lowercaseBrandTickerToTokenId(lowerTicker) != 0
        ) revert TickerAlreadyTaken();

        IBrandCentral brandCentral = IBrandCentral(brandNFT.brandCentral());
        IRestrictedTickerRegistry restrictedRegistry = IRestrictedTickerRegistry(brandCentral.claimAuction());

        if (restrictedRegistry.isRestrictedBrandTicker(lowerTicker)) revert TickerAlreadyTaken();

        stakehouseTicker = _newTicker;

        emit NetworkTickerUpdated(_newTicker);
    }
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ERC20PermitUpgradeable } from "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/draft-ERC20PermitUpgradeable.sol";
import { ILPTokenInit } from "../interfaces/ILPTokenInit.sol";
import { ILiquidStakingManagerChildContract } from "../interfaces/ILiquidStakingManagerChildContract.sol";
import { ITransferHookProcessor } from "../interfaces/ITransferHookProcessor.sol";

contract LPToken is ILPTokenInit, ILiquidStakingManagerChildContract, Initializable, ERC20PermitUpgradeable {

    uint256 constant MIN_TRANSFER_AMOUNT = 0.001 ether;

    /// @notice Contract deployer that can control minting and burning but is associated with a liquid staking manager
    address public deployer;

    /// @notice Optional hook for processing transfers
    ITransferHookProcessor transferHookProcessor;

    /// @notice Whenever the address last interacted with a token
    mapping(address => uint256) public lastInteractedTimestamp;

    modifier onlyDeployer {
        require(msg.sender == deployer, "Only savETH vault");
        _;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @param _deployer Address of the account deploying the LP token
    /// @param _transferHookProcessor Optional contract account that can be notified about transfer hooks
    function init(
        address _deployer,
        address _transferHookProcessor,
        string calldata _tokenSymbol,
        string calldata _tokenName
    ) external override initializer {
        deployer = _deployer;
        transferHookProcessor = ITransferHookProcessor(_transferHookProcessor);
        __ERC20_init(_tokenName, _tokenSymbol);
        __ERC20Permit_init(_tokenName);
    }

    /// @notice Mints a given amount of LP tokens
    /// @dev Only savETH vault can mint
    function mint(address _recipient, uint256 _amount) external onlyDeployer {
        _mint(_recipient, _amount);
    }

    /// @notice Allows a LP token owner to burn their tokens
    function burn(address _recipient, uint256 _amount) external onlyDeployer {
        _burn(_recipient, _amount);
    }

    /// @notice In order to know the liquid staking network and manager associated with the LP token, call this
    function liquidStakingManager() external view returns (address) {
        return ILiquidStakingManagerChildContract(deployer).liquidStakingManager();
    }

    /// @dev If set, notify the transfer hook processor before token transfer
    function _beforeTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        require(_amount >= MIN_TRANSFER_AMOUNT, "Min transfer amount");
        require(_from != _to, "Self transfer");
        if (address(transferHookProcessor) != address(0)) transferHookProcessor.beforeTokenTransfer(_from, _to, _amount);
    }

    /// @dev If set, notify the transfer hook processor after token transfer
    function _afterTokenTransfer(address _from, address _to, uint256 _amount) internal override {
        lastInteractedTimestamp[_from] = block.timestamp;
        lastInteractedTimestamp[_to] = block.timestamp;
        if (address(transferHookProcessor) != address(0)) transferHookProcessor.afterTokenTransfer(_from, _to, _amount);
    }
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { ILPTokenInit } from "../interfaces/ILPTokenInit.sol";
import { UpgradeableBeacon } from "../proxy/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

/// @notice Contract for deploying a new LP token
contract LPTokenFactory {

    /// @notice Emitted when a new LP token instance is deployed
    event LPTokenDeployed(address indexed factoryCloneToken);

    /// @notice Address of LP token implementation that is cloned on each LP token
    address public lpTokenImplementation;

    /// @notice Address of the implementation beacon
    address public beacon;

    /// @param _lpTokenImplementation Address of LP token implementation that is cloned on each LP token deployment
    constructor(address _lpTokenImplementation, address _upgradeManager) {
        require(_lpTokenImplementation != address(0), "Address cannot be zero");

        lpTokenImplementation = _lpTokenImplementation;
        beacon = address(new UpgradeableBeacon(lpTokenImplementation, _upgradeManager));
    }

    /// @notice Deploys a new LP token
    /// @param _tokenSymbol Symbol of the LP token to be deployed
    /// @param _tokenName Name of the LP token to be deployed
    function deployLPToken(
        address _deployer,
        address _transferHookProcessor,
        string calldata _tokenSymbol,
        string calldata _tokenName
    ) external returns (address) {
        require(address(_deployer) != address(0), "Zero address");
        require(bytes(_tokenSymbol).length != 0, "Symbol cannot be zero");
        require(bytes(_tokenName).length != 0, "Name cannot be zero");

        address newInstance = address(new BeaconProxy(
                beacon,
                abi.encodeCall(
                    ILPTokenInit(payable(lpTokenImplementation)).init,
                    (
                        _deployer,
                        _transferHookProcessor,
                        _tokenSymbol,
                        _tokenName
                    )
                )
            ));

        emit LPTokenDeployed(newInstance);

        return newInstance;
    }
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { ERC1967Proxy } from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import { UUPSUpgradeable } from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import { OwnableUpgradeable } from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import { LiquidStakingManager } from "./LiquidStakingManager.sol";
import { GiantPoolBase } from "./GiantPoolBase.sol";
import { UpgradeableBeacon } from "../proxy/UpgradeableBeacon.sol";
import { IGiantSavETHVaultPool } from "../interfaces/IGiantSavETHVaultPool.sol";
import { IGiantMevAndFeesPool } from "../interfaces/IGiantMevAndFeesPool.sol";

/// @notice Contract for deploying a new Liquid Staking Derivative Network (LSDN)
contract LSDNFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {

    /// @notice Emitted when a new liquid staking manager is deployed
    event LSDNDeployed(address indexed LiquidStakingManager);

    /// @notice Beacon for any liquid staking manager proxies
    address public liquidStakingManagerBeacon;

    /// @notice Address of the liquid staking manager implementation that is cloned on each deployment
    address public liquidStakingManagerImplementation;

    /// @notice Address of the factory that will deploy a syndicate for the network after the first knot is created
    address public syndicateFactory;

    /// @notice Address of the factory for deploying LP tokens in exchange for ETH supplied to stake a KNOT
    address public lpTokenFactory;

    /// @notice Address of the factory for deploying smart wallets used by node runners during staking
    address public smartWalletFactory;

    /// @notice Address of brand NFT
    address public brand;

    /// @notice Address of the contract that can deploy new instances of SavETHVault
    address public savETHVaultDeployer;

    /// @notice Address of the contract that can deploy new instances of StakingFundsVault
    address public stakingFundsVaultDeployer;

    /// @notice Address of the contract that can deploy new instances of optional gatekeepers for controlling which knots can join the LSDN house
    address public optionalGatekeeperDeployer;

    /// @notice Address of associated giant protected staking pool
    GiantPoolBase public giantSavETHPool;

    /// @notice Address of giant fees and mev pool
    GiantPoolBase public giantFeesAndMev;

    /// @notice Establishes whether a given liquid staking manager address was deployed by this factory
    mapping(address => bool) public isLiquidStakingManager;

    /// @notice Establishes whether a given savETH vault belongs to a LSD network deployed by the factory
    mapping(address => bool) public isSavETHVault;

    /// @notice Establishes whether a given Staking funds vault belongs to a LSD network deployed by the factory
    mapping(address => bool) public isStakingFundsVault;

    /// @notice Initialization parameters required to deploy the LSDN factory
    struct InitParams {
        address _liquidStakingManagerImplementation;
        address _syndicateFactory;
        address _lpTokenFactory;
        address _smartWalletFactory;
        address _brand;
        address _savETHVaultDeployer;
        address _stakingFundsVaultDeployer;
        address _optionalGatekeeperDeployer;
        address _giantSavETHImplementation;
        address _giantFeesAndMevImplementation;
        address _giantLPDeployer;
        address _upgradeManager;
    }

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @notice External one time function for initializing the factory
    function init(InitParams memory _params) external initializer {
        _init(_params);
        _transferOwnership(_params._upgradeManager);
    }

    /// @dev Owner based upgrades
    function _authorizeUpgrade(address newImplementation)
    internal
    onlyOwner
    override
    {}

    /// @dev Internal initialization logic that can be called from mock harness contracts
    function _init(InitParams memory _params) internal {
        require(_params._liquidStakingManagerImplementation != address(0), "Zero Address");
        require(_params._syndicateFactory != address(0), "Zero Address");
        require(_params._lpTokenFactory != address(0), "Zero Address");
        require(_params._smartWalletFactory != address(0), "Zero Address");
        require(_params._brand != address(0), "Zero Address");
        require(_params._savETHVaultDeployer != address(0), "Zero Address");
        require(_params._stakingFundsVaultDeployer != address(0), "Zero Address");
        require(_params._optionalGatekeeperDeployer != address(0), "Zero Address");

        liquidStakingManagerImplementation = _params._liquidStakingManagerImplementation;
        syndicateFactory = _params._syndicateFactory;
        lpTokenFactory = _params._lpTokenFactory;
        smartWalletFactory = _params._smartWalletFactory;
        brand = _params._brand;
        savETHVaultDeployer = _params._savETHVaultDeployer;
        stakingFundsVaultDeployer = _params._stakingFundsVaultDeployer;
        optionalGatekeeperDeployer = _params._optionalGatekeeperDeployer;

        liquidStakingManagerBeacon = address(new UpgradeableBeacon(
                liquidStakingManagerImplementation,
                _params._upgradeManager
            ));

        ERC1967Proxy giantFeesAndMevProxy = new ERC1967Proxy(
            _params._giantFeesAndMevImplementation,
            abi.encodeCall(
                IGiantMevAndFeesPool(_params._giantFeesAndMevImplementation).init,
                (LSDNFactory(address(this)), _params._giantLPDeployer, _params._upgradeManager)
            )
        );
        giantFeesAndMev = GiantPoolBase(address(giantFeesAndMevProxy));

        ERC1967Proxy giantSavETHProxy = new ERC1967Proxy(
            _params._giantSavETHImplementation,
            abi.encodeCall(
                IGiantSavETHVaultPool(_params._giantSavETHImplementation).init,
                (LSDNFactory(address(this)), _params._giantLPDeployer, address(giantFeesAndMev), _params._upgradeManager)
            )
        );
        giantSavETHPool = GiantPoolBase(address(giantSavETHProxy));

    }

    /// @notice Deploys a new LSDN and the liquid staking manger required to manage the network
    /// @param _dao Address of the entity that will govern the liquid staking network
    /// @param _stakehouseTicker Liquid staking derivative network ticker (between 3-5 chars)
    function deployNewLiquidStakingDerivativeNetwork(
        address _dao,
        uint256 _optionalCommission,
        bool _deployOptionalHouseGatekeeper,
        string calldata _stakehouseTicker
    ) public returns (address) {
        // Clone a new liquid staking manager instance
        address newInstance = _deployNewInstance(_dao, _optionalCommission, _deployOptionalHouseGatekeeper, _stakehouseTicker);

        _registerLSDInstance(newInstance);

        emit LSDNDeployed(newInstance);

        return newInstance;
    }

    /// @dev deploy a new beacon based liquid staking manager instance
    function _deployNewInstance(
        address _dao,
        uint256 _optionalCommission,
        bool _deployOptionalHouseGatekeeper,
        string calldata _stakehouseTicker
    ) internal returns (address) {
        return address(new BeaconProxy(
                liquidStakingManagerBeacon,
                abi.encodeCall(
                    LiquidStakingManager(payable(liquidStakingManagerImplementation)).init,
                    (
                        _dao,
                        syndicateFactory,
                        smartWalletFactory,
                        lpTokenFactory,
                        brand,
                        savETHVaultDeployer,
                        stakingFundsVaultDeployer,
                        optionalGatekeeperDeployer,
                        _optionalCommission,
                        _deployOptionalHouseGatekeeper,
                        _stakehouseTicker
                    )
                )
            ));
    }

    /// @dev Register the core contracts of an LSD network that were deployed by the factory
    function _registerLSDInstance(address _newInstance) internal {
        LiquidStakingManager lsdInstance = LiquidStakingManager(payable(_newInstance));

        // Record that the manager was deployed by this contract
        isLiquidStakingManager[_newInstance] = true;
        isSavETHVault[address(lsdInstance.savETHVault())] = true;
        isStakingFundsVault[address(lsdInstance.stakingFundsVault())] = true;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { OptionalHouseGatekeeper } from "./OptionalHouseGatekeeper.sol";

contract OptionalGatekeeperFactory {

    event NewOptionalGatekeeperDeployed(address indexed keeper, address indexed manager);

    function deploy(address _liquidStakingManager) external returns (OptionalHouseGatekeeper) {
        OptionalHouseGatekeeper newKeeper = new OptionalHouseGatekeeper(_liquidStakingManager);

        emit NewOptionalGatekeeperDeployed(address(newKeeper), _liquidStakingManager);

        return newKeeper;
    }
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { IGateKeeper } from "../interfaces/IGateKeeper.sol";
import { ILiquidStakingManager } from "../interfaces/ILiquidStakingManager.sol";

/// @title Liquid Staking Derivative Network Gatekeeper that only lets knots from within the network join the network house
contract OptionalHouseGatekeeper is IGateKeeper {

    /// @notice Address of the core registry for the associated liquid staking network
    ILiquidStakingManager public liquidStakingManager;

    constructor(address _manager) {
        liquidStakingManager = ILiquidStakingManager(_manager);
    }

    /// @notice Method called by the house before admitting a new KNOT member and giving house sETH
    function isMemberPermitted(bytes calldata _blsPublicKeyOfKnot) external override view returns (bool) {
        return liquidStakingManager.isBLSPublicKeyPartOfLSDNetwork(_blsPublicKeyOfKnot) && !liquidStakingManager.isBLSPublicKeyBanned(_blsPublicKeyOfKnot);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { IDataStructures } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol";

import { ILiquidStakingManager } from "../interfaces/ILiquidStakingManager.sol";

import { StakingFundsVault } from "./StakingFundsVault.sol";
import { LPToken } from "./LPToken.sol";
import { ETHPoolLPFactory } from "./ETHPoolLPFactory.sol";
import { LPTokenFactory } from "./LPTokenFactory.sol";
import { ETHTransferHelper } from "../transfer/ETHTransferHelper.sol";

contract SavETHVault is Initializable, ETHPoolLPFactory, ReentrancyGuard, ETHTransferHelper {

    /// @notice signalize transfer of dETH to depositor
    event DETHRedeemed(address depositor, uint256 amount);

    /// @notice signalize withdrawal of ETH for staking
    event ETHWithdrawnForStaking(address withdrawalAddress, address liquidStakingManager, uint256 amount);

    /// @notice signalize deposit of dETH and isolation of KNOT in the index
    event DETHDeposited(bytes blsPublicKeyOfKnot, uint128 dETHDeposited, uint256 lpTokensIssued);

    /// @notice Liquid staking manager instance
    ILiquidStakingManager public liquidStakingManager;

    /// @notice index id of the savETH index owned by the vault
    uint256 public indexOwnedByTheVault;

    /// @notice Amount of tokens minted each time a KNOT is added to the universe. Denominated in ether due to redemption rights
    uint256 public constant KNOT_BATCH_AMOUNT = 24 ether;

    /// @notice dETH related details for a KNOT
    /// @dev If dETH is not withdrawn, then for a non-existing dETH balance
    /// the structure would result in zero balance even though dETH isn't withdrawn for KNOT
    /// withdrawn parameter tracks the status of dETH for a KNOT
    struct KnotDETHDetails {
        uint256 savETHBalance;
        bool withdrawn;
    }

    /// @notice dETH associated with the KNOT
    mapping(bytes => KnotDETHDetails) public dETHForKnot;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    function init(address _liquidStakingManagerAddress, LPTokenFactory _lpTokenFactory) external virtual initializer {
        _init(_liquidStakingManagerAddress, _lpTokenFactory);
    }

    modifier onlyManager {
        require(msg.sender == address(liquidStakingManager), "Not the savETH vault manager");
        _;
    }

    /// @notice Stake ETH against multiple BLS keys and specify the amount of ETH being supplied for each key
    /// @param _blsPublicKeyOfKnots BLS public key of the validators being staked and that are registered with the LSD network
    /// @param _amounts Amount of ETH being supplied for the BLS public key at the same array index
    function batchDepositETHForStaking(bytes[] calldata _blsPublicKeyOfKnots, uint256[] calldata _amounts) external payable {
        uint256 numOfValidators = _blsPublicKeyOfKnots.length;
        require(numOfValidators > 0, "Empty arrays");
        require(numOfValidators == _amounts.length, "Inconsistent array lengths");

        uint256 totalAmount;
        for (uint256 i; i < numOfValidators; ++i) {
            require(liquidStakingManager.isBLSPublicKeyBanned(_blsPublicKeyOfKnots[i]) == false, "BLS public key is not part of LSD network");
            require(
                getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnots[i]) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
                "Lifecycle status must be one"
            );

            uint256 amount = _amounts[i];
            totalAmount += amount;
            _depositETHForStaking(_blsPublicKeyOfKnots[i], amount, false);
        }

        // Ensure that the sum of LP tokens issued equals the ETH deposited into the contract
        require(msg.value == totalAmount, "Invalid ETH amount attached");
    }

    /// @notice function to allow users to deposit any amount of ETH for staking
    /// @param _blsPublicKeyOfKnot BLS Public Key of the potential KNOT for which user is contributing
    /// @param _amount number of ETH (input in wei) contributed by the user for staking
    /// @return amount of ETH contributed for staking by the user
    function depositETHForStaking(bytes calldata _blsPublicKeyOfKnot, uint256 _amount) public payable returns (uint256) {
        require(liquidStakingManager.isBLSPublicKeyBanned(_blsPublicKeyOfKnot) == false, "BLS public key is banned or not a part of LSD network");
        require(
            getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnot) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
            "Lifecycle status must be one"
        );

        require(msg.value == _amount, "Must provide correct amount of ETH");
        _depositETHForStaking(_blsPublicKeyOfKnot, _amount, false);

        return _amount;
    }
    
    /// @notice fetch dETH required to be deposited to isolate KNOT in the index
    /// @param _blsPublicKeyOfKnot BLS public key of the KNOT to be isolated
    /// @return uint128 dETH amount
    function dETHRequiredToIsolateWithdrawnKnot(bytes calldata _blsPublicKeyOfKnot) public view returns (uint128) {

        KnotDETHDetails memory dETHDetails = dETHForKnot[_blsPublicKeyOfKnot];
        require(dETHDetails.withdrawn == true, "KNOT is already isolated");

        LPToken token = lpTokenForKnot[_blsPublicKeyOfKnot];
        uint256 lpSharesBurned = KNOT_BATCH_AMOUNT - token.totalSupply();

        uint256 dETHRequiredForIsolation = KNOT_BATCH_AMOUNT + getSavETHRegistry().dETHRewardsMintedForKnot(_blsPublicKeyOfKnot);

        uint256 savETHBurnt = (dETHDetails.savETHBalance * lpSharesBurned) / KNOT_BATCH_AMOUNT;
        uint256 currentSavETH = dETHDetails.savETHBalance - savETHBurnt;
        uint256 currentDETH = getSavETHRegistry().savETHToDETH(currentSavETH);

        return uint128(dETHRequiredForIsolation - currentDETH);
    }

    /// @notice function to allows users to deposit dETH in exchange of LP shares
    /// @param _blsPublicKeyOfKnot BLS Public Key of the KNOT for which user is contributing
    /// @param _amount number of dETH (input in wei) contributed by the user
    /// @return amount of LP shares issued to the user
    function depositDETHForStaking(bytes calldata _blsPublicKeyOfKnot, uint128 _amount) public returns (uint256) {
        require(_amount >= uint128(0.001 ether), "Amount must be at least 0.001 ether");
        
        // only allow dETH deposits for KNOTs that have minted derivatives
        require(
            getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnot) == IDataStructures.LifecycleStatus.TOKENS_MINTED,
            "Lifecycle status must be three"
        );

        uint128 requiredDETH = dETHRequiredToIsolateWithdrawnKnot(_blsPublicKeyOfKnot);
        require(_amount == requiredDETH, "Amount must be equal to dETH required to isolate");
        require(uint128(getDETH().balanceOf(msg.sender)) >= _amount, "Insufficient dETH balance");

        // transfer dETH from user to the pool
        getDETH().transferFrom(msg.sender, address(this), uint256(_amount));
        getSavETHRegistry().deposit(address(this), _amount);

        getSavETHRegistry().isolateKnotFromOpenIndex(
            liquidStakingManager.stakehouse(),
            _blsPublicKeyOfKnot,
            indexOwnedByTheVault
        );

        LPToken token = lpTokenForKnot[_blsPublicKeyOfKnot];
        uint256 lpSharesBurned = KNOT_BATCH_AMOUNT - token.totalSupply();
        // mint the previously burned LP shares
        token.mint(msg.sender, lpSharesBurned);

        KnotDETHDetails storage dETHDetails = dETHForKnot[_blsPublicKeyOfKnot];
        // update withdrawn status to allow future withdrawals
        dETHDetails.withdrawn = false;
        dETHDetails.savETHBalance = 0;

        emit DETHDeposited(_blsPublicKeyOfKnot, _amount, lpSharesBurned);

        return lpSharesBurned;
    }

    /// @notice Burn multiple LP tokens in a batch to claim either ETH (if not staked) or dETH (if derivatives minted)
    /// @param _blsPublicKeys List of BLS public keys that have received liquidity
    /// @param _amounts Amount of each LP token that the user wants to burn in exchange for either ETH (if not staked) or dETH (if derivatives minted)
    function burnLPTokensByBLS(bytes[] calldata _blsPublicKeys, uint256[] calldata _amounts) external {
        uint256 numOfTokens = _blsPublicKeys.length;
        require(numOfTokens > 0, "Empty arrays");
        require(numOfTokens == _amounts.length, "Inconsistent array length");
        for (uint256 i; i < numOfTokens; ++i) {
            LPToken token = lpTokenForKnot[_blsPublicKeys[i]];
            burnLPToken(token, _amounts[i]);
        }
    }

    /// @notice Burn multiple LP tokens in a batch to claim either ETH (if not staked) or dETH (if derivatives minted)
    /// @param _lpTokens List of LP token addresses held by the caller
    /// @param _amounts Amount of each LP token that the user wants to burn in exchange for either ETH (if not staked) or dETH (if derivatives minted)
    function burnLPTokens(LPToken[] calldata _lpTokens, uint256[] calldata _amounts) external {
        uint256 numOfTokens = _lpTokens.length;
        require(numOfTokens > 0, "Empty arrays");
        require(numOfTokens == _amounts.length, "Inconsisent array length");
        for (uint256 i; i < numOfTokens; ++i) {
            burnLPToken(_lpTokens[i], _amounts[i]);
        }
    }

    /// @notice function to allow users to burn LP token in exchange of ETH or dETH
    /// @param _lpToken instance of LP token to be burnt
    /// @param _amount number of LP tokens the user wants to burn
    /// @return amount of ETH withdrawn
    function burnLPToken(LPToken _lpToken, uint256 _amount) public nonReentrant returns (uint256) {
        require(_amount >= MIN_STAKING_AMOUNT, "Amount cannot be zero");
        require(_amount <= _lpToken.balanceOf(msg.sender), "Not enough balance");

        // get BLS public key for the LP token
        bytes memory blsPublicKeyOfKnot = KnotAssociatedWithLPToken[_lpToken];
        IDataStructures.LifecycleStatus validatorStatus = getAccountManager().blsPublicKeyToLifecycleStatus(blsPublicKeyOfKnot);

        require(
            validatorStatus == IDataStructures.LifecycleStatus.INITIALS_REGISTERED ||
            validatorStatus == IDataStructures.LifecycleStatus.TOKENS_MINTED,
            "Cannot burn LP tokens"
        );

        // before burning, check the last LP token interaction and make sure its more than 30 mins old before permitting ETH withdrawals
        bool isStaleLiquidity = _lpToken.lastInteractedTimestamp(msg.sender) + 30 minutes < block.timestamp;

        // burn the amount of LP token from depositor's wallet
        _lpToken.burn(msg.sender, _amount);
        emit LPTokenBurnt(blsPublicKeyOfKnot, address(_lpToken), msg.sender, _amount);

        if(validatorStatus == IDataStructures.LifecycleStatus.TOKENS_MINTED) {
            // return dETH
            // amount of dETH redeemed by user for given LP token
            uint256 redemptionValue;

            KnotDETHDetails storage dETHDetails = dETHForKnot[blsPublicKeyOfKnot];

            if(!dETHDetails.withdrawn) {
                // withdraw dETH if not done already

                // get dETH balance for the KNOT
                uint256 dETHBalance = getSavETHRegistry().knotDETHBalanceInIndex(indexOwnedByTheVault, blsPublicKeyOfKnot);
                uint256 savETHBalance = getSavETHRegistry().dETHToSavETH(dETHBalance);
                // This require should never fail but is there for sanity purposes
                require(dETHBalance >= 24 ether, "Nothing to withdraw");

                // withdraw savETH from savETH index to the savETH vault
                // contract gets savETH and not the dETH
                getSavETHRegistry().addKnotToOpenIndex(liquidStakingManager.stakehouse(), blsPublicKeyOfKnot, address(this));

                // update mapping
                dETHDetails.withdrawn = true;
                dETHDetails.savETHBalance = savETHBalance;
                dETHForKnot[blsPublicKeyOfKnot] = dETHDetails;
            }

            // redeem savETH from the vault
            redemptionValue = (dETHDetails.savETHBalance * _amount) / 24 ether;

            // withdraw dETH (after burning the savETH)
            getSavETHRegistry().withdraw(msg.sender, uint128(redemptionValue));

            uint256 dETHRedeemed = getSavETHRegistry().savETHToDETH(redemptionValue);

            emit DETHRedeemed(msg.sender, dETHRedeemed);
            return redemptionValue;
        }

        // Before allowing ETH withdrawals we check the value of isStaleLiquidity fetched before burn
        require(isStaleLiquidity, "Liquidity is still fresh");

        // return ETH for LifecycleStatus.INITIALS_REGISTERED
        _transferETH(msg.sender, _amount);
        emit ETHWithdrawnByDepositor(msg.sender, _amount);

        return _amount;
    }

    /// @notice function to allow liquid staking manager to withdraw ETH for staking
    /// @param _smartWallet address of the smart wallet that receives ETH
    /// @param _amount amount of ETH to be withdrawn
    /// @return amount of ETH withdrawn
    function withdrawETHForStaking(
        address _smartWallet,
        uint256 _amount
    ) public onlyManager nonReentrant returns (uint256) {
        require(_amount >= 24 ether, "Amount cannot be less than 24 ether");
        require(address(this).balance >= _amount, "Insufficient withdrawal amount");
        require(_smartWallet != address(0), "Zero address");
        require(_smartWallet != address(this), "This address");

        _transferETH(_smartWallet, _amount);

        emit ETHWithdrawnForStaking(_smartWallet, msg.sender, _amount);

        return _amount;
    }

    /// @notice Utility function that proxies through to the liquid staking manager to check whether the BLS key ever registered with the network
    function isBLSPublicKeyPartOfLSDNetwork(bytes calldata _blsPublicKeyOfKnot) public virtual view returns (bool) {
        return liquidStakingManager.isBLSPublicKeyPartOfLSDNetwork(_blsPublicKeyOfKnot);
    }

    /// @notice Utility function that proxies through to the liquid staking manager to check whether the BLS key ever registered with the network but is now banned
    function isBLSPublicKeyBanned(bytes calldata _blsPublicKeyOfKnot) public view returns (bool) {
        return liquidStakingManager.isBLSPublicKeyBanned(_blsPublicKeyOfKnot);
    }

    /// @notice Utility function that determins whether an LP can be burned for dETH if the associated derivatives have been minted
    function isDETHReadyForWithdrawal(address _lpTokenAddress) external view returns (bool) {
        bytes memory blsPublicKeyOfKnot = KnotAssociatedWithLPToken[LPToken(_lpTokenAddress)];
        IDataStructures.LifecycleStatus validatorStatus = getAccountManager().blsPublicKeyToLifecycleStatus(blsPublicKeyOfKnot);
        return validatorStatus == IDataStructures.LifecycleStatus.TOKENS_MINTED;
    }

    /// @dev Logic required for initialization
    function _init(address _liquidStakingManagerAddress, LPTokenFactory _lpTokenFactory) internal {
        require(_liquidStakingManagerAddress != address(0), "Zero address");
        require(address(_lpTokenFactory) != address(0), "Zero address");

        lpTokenFactory = _lpTokenFactory;
        liquidStakingManager = ILiquidStakingManager(_liquidStakingManagerAddress);

        baseLPTokenName = "dstETHToken_";
        baseLPTokenSymbol = "dstETH_";
        maxStakingAmountPerValidator = 24 ether;

        // create a savETH index owned by the vault
        indexOwnedByTheVault = getSavETHRegistry().createIndex(address(this));
    }
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { SavETHVault } from "./SavETHVault.sol";
import { LPTokenFactory } from "./LPTokenFactory.sol";
import { UpgradeableBeacon } from "../proxy/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract SavETHVaultDeployer {

    event NewVaultDeployed(address indexed instance);

    /// @notice Implementation at the time of deployment
    address public implementation;

    /// @notice Beacon referenced by each deployment of a savETH vault
    address public beacon;

    constructor(address _upgradeManager) {
        implementation = address(new SavETHVault());
        beacon = address(new UpgradeableBeacon(implementation, _upgradeManager));
    }

    function deploySavETHVault(address _liquidStakingManger, address _lpTokenFactory) external returns (address) {
        address newVault = address(new BeaconProxy(
                beacon,
                abi.encodeCall(
                    SavETHVault(payable(implementation)).init,
                    (_liquidStakingManger, LPTokenFactory(_lpTokenFactory))
                )
            ));

        emit NewVaultDeployed(newVault);

        return newVault;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { StakehouseAPI } from "@blockswaplab/stakehouse-solidity-api/contracts/StakehouseAPI.sol";
import { IDataStructures } from "@blockswaplab/stakehouse-contract-interfaces/contracts/interfaces/IDataStructures.sol";

import { ITransferHookProcessor } from "../interfaces/ITransferHookProcessor.sol";
import { Syndicate } from "../syndicate/Syndicate.sol";
import { ETHPoolLPFactory } from "./ETHPoolLPFactory.sol";
import { LiquidStakingManager } from "./LiquidStakingManager.sol";
import { LPTokenFactory } from "./LPTokenFactory.sol";
import { LPToken } from "./LPToken.sol";
import { SyndicateRewardsProcessor } from "./SyndicateRewardsProcessor.sol";
import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";

/// @title MEV and fees vault for a specified liquid staking network
contract StakingFundsVault is
    Initializable,
    ITransferHookProcessor,
    StakehouseAPI,
    ETHPoolLPFactory,
    SyndicateRewardsProcessor,
    ReentrancyGuard
{

    /// @notice signalize that the vault received ETH
    event ETHDeposited(address sender, uint256 amount);

    /// @notice signalize ETH withdrawal from the vault
    event ETHWithdrawn(address receiver, address admin, uint256 amount);

    /// @notice signalize ERC20 token recovery by the admin
    event ERC20Recovered(address admin, address recipient, uint256 amount);

    /// @notice signalize unwrapping of WETH in the vault
    event WETHUnwrapped(address admin, uint256 amount);

    /// @notice Emitted when an LP from another liquid staking network is migrated
    event LPAddedForMigration(address indexed lpToken);

    /// @notice Emitted when an LP token has been swapped for a new one from this vault
    event LPMigrated(address indexed fromLPToken);

    /// @notice Address of the network manager
    LiquidStakingManager public liquidStakingNetworkManager;

    /// @notice Total number of LP tokens issued in WEI
    uint256 public totalShares;

    /// @notice Total amount of ETH from LPs that has not been staked in the Ethereum deposit contract
    uint256 public totalETHFromLPs;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @param _liquidStakingNetworkManager address of the liquid staking network manager
    function init(address _liquidStakingNetworkManager, LPTokenFactory _lpTokenFactory) external virtual initializer {
        _init(LiquidStakingManager(payable(_liquidStakingNetworkManager)), _lpTokenFactory);
    }

    modifier onlyManager() {
        require(msg.sender == address(liquidStakingNetworkManager), "Only network manager");
        _;
    }

    /// @notice Allows the liquid staking manager to notify funds vault about new derivatives minted to enable MEV claiming
    function updateDerivativesMinted(bytes calldata _blsPublicKey) external onlyManager {
        // update accumulated per LP before shares expand
        updateAccumulatedETHPerLP();

        // From this point onwards, we can use this variable to track ETH accrued to LP holders of this key
        accumulatedETHPerLPAtTimeOfMintingDerivatives[_blsPublicKey] = accumulatedETHPerLPShare;

        // We know 4 ETH for the KNOT came from this vault so increase the shares to get a % of vault rewards
        totalShares += 4 ether;
    }

    /// @notice For knots that have minted derivatives, update accumulated ETH per LP
    function updateAccumulatedETHPerLP() public {
        _updateAccumulatedETHPerLP(totalShares);
    }

    /// @notice Batch deposit ETH for staking against multiple BLS public keys
    /// @param _blsPublicKeyOfKnots List of BLS public keys being staked
    /// @param _amounts Amounts of ETH being staked for each BLS public key
    function batchDepositETHForStaking(bytes[] calldata _blsPublicKeyOfKnots, uint256[] calldata _amounts) external nonReentrant payable {
        uint256 numOfValidators = _blsPublicKeyOfKnots.length;
        require(numOfValidators > 0, "Empty arrays");
        require(numOfValidators == _amounts.length, "Inconsistent array lengths");

        // Track total ETH from LPs
        totalETHFromLPs += msg.value;

        // Update accrued ETH to contract per LP
        updateAccumulatedETHPerLP();

        uint256 totalAmount;
        for (uint256 i; i < numOfValidators; ++i) {
            require(liquidStakingNetworkManager.isBLSPublicKeyBanned(_blsPublicKeyOfKnots[i]) == false, "BLS public key is not part of LSD network");
            require(
                getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnots[i]) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
                "Lifecycle status must be one"
            );

            uint256 amount = _amounts[i];
            totalAmount += amount;

            _depositETHForStaking(_blsPublicKeyOfKnots[i], amount, true);
        }

        // Ensure that the sum of LP tokens issued equals the ETH deposited into the contract
        require(msg.value == totalAmount, "Invalid ETH amount attached");
    }

    /// @notice Deposit ETH against a BLS public key for staking
    /// @param _blsPublicKeyOfKnot BLS public key of validator registered by a node runner
    /// @param _amount Amount of ETH being staked
    function depositETHForStaking(bytes calldata _blsPublicKeyOfKnot, uint256 _amount) public nonReentrant payable returns (uint256) {
        require(liquidStakingNetworkManager.isBLSPublicKeyBanned(_blsPublicKeyOfKnot) == false, "BLS public key is banned or not a part of LSD network");
        require(
            getAccountManager().blsPublicKeyToLifecycleStatus(_blsPublicKeyOfKnot) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
            "Lifecycle status must be one"
        );

        require(msg.value == _amount, "Must provide correct amount of ETH");

        // Track total ETH from LPs
        totalETHFromLPs += _amount;

        // Update accrued ETH to contract per LP
        updateAccumulatedETHPerLP();

        _depositETHForStaking(_blsPublicKeyOfKnot, _amount, true);

        return _amount;
    }

    /// @notice Burn a batch of LP tokens in order to get back ETH that has not been staked by BLS public key
    /// @param _blsPublicKeys List of BLS public keys that received ETH for staking
    /// @param _amounts List of amounts of LP tokens being burnt
    function burnLPTokensForETHByBLS(bytes[] calldata _blsPublicKeys, uint256[] calldata _amounts) external {
        uint256 numOfTokens = _blsPublicKeys.length;
        require(numOfTokens > 0, "Empty arrays");
        require(numOfTokens == _amounts.length, "Inconsistent array length");
        for (uint256 i; i < numOfTokens; ++i) {
            LPToken token = lpTokenForKnot[_blsPublicKeys[i]];
            require(address(token) != address(0), "No ETH staked for specified BLS key");
            burnLPForETH(token, _amounts[i]);
        }
    }

    /// @notice Burn a batch of LP tokens in order to get back ETH that has not been staked
    /// @param _lpTokens Address of LP tokens being burnt
    /// @param _amounts Amount of LP tokens being burnt
    function burnLPTokensForETH(LPToken[] calldata _lpTokens, uint256[] calldata _amounts) external {
        uint256 numOfTokens = _lpTokens.length;
        require(numOfTokens > 0, "Empty arrays");
        require(numOfTokens == _amounts.length, "Inconsistent array length");
        for (uint256 i; i < numOfTokens; ++i) {
            burnLPForETH(_lpTokens[i], _amounts[i]);
        }
    }

    /// @notice For a user that has deposited ETH that has not been staked, allow them to burn LP to get ETH back
    /// @param _lpToken Address of the LP token being burnt
    /// @param _amount Amount of LP token being burnt
    function burnLPForETH(LPToken _lpToken, uint256 _amount) public nonReentrant {
        require(_amount >= MIN_STAKING_AMOUNT, "Amount cannot be zero");
        require(_amount <= _lpToken.balanceOf(msg.sender), "Not enough balance");
        require(address(_lpToken) != address(0), "Zero address specified");

        bytes memory blsPublicKeyOfKnot = KnotAssociatedWithLPToken[_lpToken];
        require(
            getAccountManager().blsPublicKeyToLifecycleStatus(blsPublicKeyOfKnot) == IDataStructures.LifecycleStatus.INITIALS_REGISTERED,
            "Cannot burn LP tokens"
        );
        require(_lpToken.lastInteractedTimestamp(msg.sender) + 30 minutes < block.timestamp, "Too new");

        updateAccumulatedETHPerLP();

        _lpToken.burn(msg.sender, _amount);

        // Track total ETH from LPs
        totalETHFromLPs -= _amount;

        _transferETH(msg.sender, _amount);

        emit ETHWithdrawnByDepositor(msg.sender, _amount);

        emit LPTokenBurnt(blsPublicKeyOfKnot, address(_lpToken), msg.sender, _amount);
    }

    /// @notice Any LP tokens for BLS keys that have had their derivatives minted can claim ETH from the syndicate contract
    /// @param _blsPubKeys List of BLS public keys being processed
    function claimRewards(
        address _recipient,
        bytes[] calldata _blsPubKeys
    ) external nonReentrant {
        // Withdraw any ETH accrued on free floating SLOT from syndicate to this contract
        // If a partial list of BLS keys that have free floating staked are supplied, then partial funds accrued will be fetched
        _claimFundsFromSyndicateForDistribution(
            liquidStakingNetworkManager.syndicate(),
            _blsPubKeys
        );

        uint256 totalToSend;
        uint256 numOfKeys = _blsPubKeys.length;
        for (uint256 i; i < numOfKeys; ++i) {
            // Ensure that the BLS key has its derivatives minted
            require(
                getAccountManager().blsPublicKeyToLifecycleStatus(_blsPubKeys[i]) == IDataStructures.LifecycleStatus.TOKENS_MINTED,
                "Derivatives not minted"
            );

            // If msg.sender has a balance for the LP token associated with the BLS key, then send them any accrued ETH
            LPToken token = lpTokenForKnot[_blsPubKeys[i]];
            require(address(token) != address(0), "Invalid BLS key");
            totalToSend += _distributeETHRewardsToUserForToken(msg.sender, address(token), token.balanceOf(msg.sender), _recipient);
        }

        (uint256 lpAmount, uint256 daoAmount) = _calculateCommission(totalToSend);

        _transferETH(_recipient, lpAmount);

        if (daoAmount > 0) _transferETH(liquidStakingNetworkManager.dao(), daoAmount);

    }

    /// @notice function to allow admins to withdraw ETH from the vault for staking purpose
    /// @param _wallet address of the smart wallet that receives ETH
    /// @param _amount number of ETH withdrawn
    /// @return number of ETH withdrawn
    function withdrawETH(address _wallet, uint256 _amount) public onlyManager nonReentrant returns (uint256) {
        require(_amount >= 4 ether, "Amount cannot be less than 4 ether");
        require(_amount <= address(this).balance, "Not enough ETH to withdraw");
        require(_wallet != address(0), "Zero address");

        // As this tracks ETH that has not been sent to deposit contract, update it
        totalETHFromLPs -= _amount;

        // Transfer the ETH to the wallet
        _transferETH(_wallet, _amount);

        emit ETHWithdrawn(_wallet, msg.sender, _amount);

        return _amount;
    }

    /// @notice LP token holders can unstake sETH and leave the LSD network by burning their LP tokens
    /// @param _blsPublicKeys List of associated BLS public keys
    /// @param _amount Amount of LP token from user being burnt.
    function unstakeSyndicateSETHByBurningLP(
        bytes[] calldata _blsPublicKeys,
        uint256 _amount
    ) external nonReentrant {
        require(_blsPublicKeys.length == 1, "One unstake at a time");
        require(_amount > 0, "No amount specified");

        LPToken token = lpTokenForKnot[_blsPublicKeys[0]];
        require(token.balanceOf(msg.sender) >= _amount, "Not enough LP");

        // Bring ETH accrued into this contract and distribute it amongst existing LPs
        Syndicate syndicate = Syndicate(payable(liquidStakingNetworkManager.syndicate()));
        _claimFundsFromSyndicateForDistribution(address(syndicate), _blsPublicKeys);
        updateAccumulatedETHPerLP();

        // This will transfer rewards to user
        token.burn(msg.sender, _amount);

        // Reduce the shares in the contract
        totalShares -= _amount;

        // Unstake and send sETH to caller
        uint256[] memory amountsForUnstaking = new uint256[](1);
        amountsForUnstaking[0] = _amount * 3;
        syndicate.unstake(address(this), msg.sender, _blsPublicKeys, amountsForUnstaking);
    }

    /// @notice Preview total ETH accumulated by a staking funds LP token holder associated with many KNOTs that have minted derivatives
    function batchPreviewAccumulatedETH(address _user, LPToken[] calldata _token) external view returns (uint256) {
        uint256 totalUnclaimed;
        for (uint256 i; i < _token.length; ++i) {
            bytes memory associatedBLSPublicKeyOfLpToken = KnotAssociatedWithLPToken[_token[i]];
            if (getAccountManager().blsPublicKeyToLifecycleStatus(associatedBLSPublicKeyOfLpToken) != IDataStructures.LifecycleStatus.TOKENS_MINTED) {
                continue;
            }

            address payable syndicate = payable(liquidStakingNetworkManager.syndicate());
            totalUnclaimed += Syndicate(syndicate).previewUnclaimedETHAsFreeFloatingStaker(
                address(this),
                associatedBLSPublicKeyOfLpToken
            );
        }

        uint256 totalAccumulated;
        for (uint256 i; i < _token.length; ++i) {
            totalAccumulated += _previewAccumulatedETH(
                _user,
                address(_token[i]),
                _token[i].balanceOf(_user),
                totalShares,
                totalUnclaimed
            );
        }

        if (totalAccumulated == 0) return 0;

        (uint256 totalDueToUser, uint256 daoAmount) = _calculateCommission(totalAccumulated);
        return _user == liquidStakingNetworkManager.dao() ? totalDueToUser + daoAmount : totalDueToUser;
    }

    /// @notice before an LP token is transferred, pay the user any unclaimed ETH rewards
    function beforeTokenTransfer(address _from, address _to, uint256 _amount) external override {
        address syndicate = liquidStakingNetworkManager.syndicate();
        if (syndicate != address(0)) {
            LPToken token = LPToken(msg.sender);
            bytes memory blsPubKey = KnotAssociatedWithLPToken[token];
            require(blsPubKey.length > 0, "Invalid token");

            if (getAccountManager().blsPublicKeyToLifecycleStatus(blsPubKey) == IDataStructures.LifecycleStatus.TOKENS_MINTED) {
                // Claim any ETH for the BLS key mapped to this token
                bytes[] memory keys = new bytes[](1);
                keys[0] = blsPubKey;
                _claimFundsFromSyndicateForDistribution(syndicate, keys);

                // Update the accumulated ETH per minted derivative LP share
                updateAccumulatedETHPerLP();

                // distribute any due rewards for the `from` user
                if (_from != address(0)) {
                    uint256 fromBalance = token.balanceOf(_from);

                    uint256 dueForFrom = _distributeETHRewardsToUserForToken(_from, address(token), fromBalance, _from);
                    if (dueForFrom > 0) {
                        (uint256 lpAmount, uint256 daoAmount) = _calculateCommission(dueForFrom);

                        _transferETH(_from, lpAmount);

                        if (daoAmount > 0) _transferETH(liquidStakingNetworkManager.dao(), daoAmount);
                    }

                    if (token.balanceOf(_from) != fromBalance) revert("ReentrancyCall");

                    // Ensure claimed amount is based on new balance
                    claimed[_from][address(token)] = fromBalance == 0 ?
                        0 : ((fromBalance - _amount) * accumulatedETHPerLPShare) / PRECISION;
                }

                // in case the new user has existing rewards - give it to them so that the after transfer hook does not wipe pending rewards
                if (_to != address(0)) {
                    uint256 toBalance = token.balanceOf(_to);

                    uint256 dueForTo = _distributeETHRewardsToUserForToken(_to, address(token), toBalance, _to);
                    if (dueForTo > 0) {
                        (uint256 lpAmount, uint256 daoAmount) = _calculateCommission(dueForTo);

                        _transferETH(_to, lpAmount);

                        if (daoAmount > 0) _transferETH(liquidStakingNetworkManager.dao(), daoAmount);
                    }

                    if (token.balanceOf(_to) != toBalance) revert("ReentrancyCall");

                    claimed[_to][address(token)] = ((toBalance + _amount) * accumulatedETHPerLPShare) / PRECISION;
                }
            }
        }
    }

    /// @notice After an LP token is transferred, ensure that the new account cannot claim historical rewards
    function afterTokenTransfer(address, address _to, uint256) external override {
        // No need to do anything here
    }

    /// @notice Claim ETH to this contract from the syndicate that was accrued by a list of actively staked validators
    /// @param _blsPubKeys List of BLS public key identifiers of validators that have sETH staked in the syndicate for the vault
    function claimFundsFromSyndicateForDistribution(bytes[] memory _blsPubKeys) external {
        _claimFundsFromSyndicateForDistribution(liquidStakingNetworkManager.syndicate(), _blsPubKeys);
    }

    /// @notice Total rewards received filtering out ETH that has been deposited by LPs
    function totalRewardsReceived() public view override returns (uint256) {
        return address(this).balance + totalClaimed - totalETHFromLPs;
    }

    /// @notice Return the address of the liquid staking manager associated with the vault
    function liquidStakingManager() external view returns (address) {
        return address(liquidStakingNetworkManager);
    }

    /// @dev Claim ETH from syndicate for a list of BLS public keys for later distribution amongst LPs
    function _claimFundsFromSyndicateForDistribution(address _syndicate, bytes[] memory _blsPubKeys) internal {
        require(_syndicate != address(0), "Invalid configuration");

        // Claim all of the ETH due from the syndicate for the auto-staked sETH
        Syndicate syndicateContract = Syndicate(payable(_syndicate));
        syndicateContract.claimAsStaker(address(this), _blsPubKeys);

        updateAccumulatedETHPerLP();
    }

    /// @dev Total claimed for a user and LP token needs to be based on when derivatives were minted so that pro-rated share is not earned too early causing phantom balances
    function _getTotalClaimedForUserAndToken(address _user, address _token, uint256 _balance) internal override view returns (uint256) {
        uint256 claimedSoFar = claimed[_user][_token];
        bytes memory blsPubKey = KnotAssociatedWithLPToken[LPToken(_token)];

        // Either user has a claimed amount or their claimed amount needs to be based on accumulated ETH at time of minting derivatives
        return claimedSoFar > 0 ?
                claimedSoFar : (_balance * accumulatedETHPerLPAtTimeOfMintingDerivatives[blsPubKey]) / PRECISION;
    }

    /// @dev Use _getTotalClaimedForUserAndToken to correctly track and save total claimed by a user for a token
    function _increaseClaimedForUserAndToken(
        address _user,
        address _token,
        uint256 _increase,
        uint256 _balance
    ) internal override {
        // _getTotalClaimedForUserAndToken will factor in accumulated ETH at time of minting derivatives
        claimed[_user][_token] = _getTotalClaimedForUserAndToken(_user, _token, _balance) + _increase;
    }

    /// @dev Initialization logic
    function _init(LiquidStakingManager _liquidStakingNetworkManager, LPTokenFactory _lpTokenFactory) internal virtual {
        require(address(_liquidStakingNetworkManager) != address(0), "Zero Address");
        require(address(_lpTokenFactory) != address(0), "Zero Address");

        liquidStakingNetworkManager = _liquidStakingNetworkManager;
        lpTokenFactory = _lpTokenFactory;

        baseLPTokenName = "ETHLPToken_";
        baseLPTokenSymbol = "ETHLP_";
        maxStakingAmountPerValidator = 4 ether;
    }

    /// @dev Calculate DAO commission
    function _calculateCommission(uint256 _received) internal virtual view returns (uint256 _lp, uint256 _dao) {
        if (_received == 0) revert("Nothing received");

        uint256 commission = liquidStakingNetworkManager.daoCommissionPercentage();

        if (commission > 0) {
            uint256 daoAmount = (_received * commission) / liquidStakingNetworkManager.MODULO();
            uint256 rest = _received - daoAmount;
            return (rest, daoAmount);
        }

        return (_received, 0);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { StakingFundsVault } from "./StakingFundsVault.sol";
import { LPTokenFactory } from "./LPTokenFactory.sol";
import { UpgradeableBeacon } from "../proxy/UpgradeableBeacon.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract StakingFundsVaultDeployer {

    event NewVaultDeployed(address indexed instance);

    /// @notice Implementation at the time of deployment
    address public implementation;

    /// @notice Beacon referenced by each deployment of a staking funds vault
    address public beacon;

    constructor(address _upgradeManager) {
        implementation = address(new StakingFundsVault());
        beacon = address(new UpgradeableBeacon(implementation, _upgradeManager));
    }

    function deployStakingFundsVault(address _liquidStakingManager, address _tokenFactory) external returns (address) {
        address newVault = address(new BeaconProxy(
                beacon,
                abi.encodeCall(
                    StakingFundsVault(payable(implementation)).init,
                    (_liquidStakingManager, LPTokenFactory(_tokenFactory))
                )
            ));

        emit NewVaultDeployed(newVault);

        return newVault;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import { ETHTransferHelper } from "../transfer/ETHTransferHelper.sol";

error ZeroAddress();

/// @notice Allows a contract to receive rewards from a syndicate and distribute it amongst LP holders
abstract contract SyndicateRewardsProcessor is ETHTransferHelper {

    /// @notice Emitted when ETH is received by the contract and processed
    event ETHReceived(uint256 amount);

    /// @notice Emitted when ETH from syndicate is distributed to a user
    event ETHDistributed(address indexed user, address indexed recipient, uint256 amount);

    /// @notice Precision used in rewards calculations for scaling up and down
    uint256 public constant PRECISION = 1e24;

    /// @notice Total accumulated ETH per share of LP<>KNOT that has minted derivatives scaled to 'PRECISION'
    uint256 public accumulatedETHPerLPShare;

    /// @notice Total ETH claimed by all users of the contract
    uint256 public totalClaimed;

    /// @notice Last total rewards seen by the contract
    uint256 public totalETHSeen;

    /// @notice How much historical ETH had accrued to the LP tokens at time of minting derivatives of a BLS key
    mapping(bytes => uint256) public accumulatedETHPerLPAtTimeOfMintingDerivatives;

    /// @notice Total ETH claimed by a given address for a given token
    mapping(address => mapping(address => uint256)) public claimed;

    /// @dev Internal logic for previewing accumulated ETH for an LP user
    function _previewAccumulatedETH(
        address _sender,
        address _token,
        uint256 _balanceOfSender,
        uint256 _numOfShares,
        uint256 _unclaimedETHFromSyndicate
    ) internal view returns (uint256) {
        if (_balanceOfSender > 0) {
            uint256 claim = _getTotalClaimedForUserAndToken(_sender, _token, _balanceOfSender);

            uint256 received = totalRewardsReceived() + _unclaimedETHFromSyndicate;
            uint256 unprocessed = received - totalETHSeen;

            uint256 newAccumulatedETH = accumulatedETHPerLPShare + ((unprocessed * PRECISION) / _numOfShares);

            return ((newAccumulatedETH * _balanceOfSender) / PRECISION) - claim;
        }
        return 0;
    }

    /// @dev Any due rewards from node running can be distributed to msg.sender if they have an LP balance
    function _distributeETHRewardsToUserForToken(
        address _user,
        address _token,
        uint256 _balance,
        address _recipient
    ) internal virtual returns (uint256) {
        if (_recipient == address(0)) revert ZeroAddress();
        uint256 balance = _balance;
        uint256 due;
        if (balance > 0) {
            // Calculate how much ETH rewards the address is owed / due 
            due = ((accumulatedETHPerLPShare * balance) / PRECISION) - _getTotalClaimedForUserAndToken(_user, _token, balance);
            if (due > 0) {
                _increaseClaimedForUserAndToken(_user, _token, due, balance);

                totalClaimed += due;

                emit ETHDistributed(_user, _recipient, due);
            }
        }

        return due;
    }

    /// @dev Overrideable logic for fetching the amount of tokens claimed by a user
    function _getTotalClaimedForUserAndToken(
        address _user,
        address _token,
        uint256         // Optional balance for use where needed
    ) internal virtual view returns (uint256);

    /// @dev Overrideable logic for updating the amount of tokens claimed by a user
    function _increaseClaimedForUserAndToken(
        address _user,
        address _token,
        uint256 _increase,
        uint256             // Optional balance for use where needed
    ) internal virtual;

    /// @dev Internal logic for tracking accumulated ETH per share
    function _updateAccumulatedETHPerLP(uint256 _numOfShares) internal {
        if (_numOfShares > 0) {
            uint256 received = totalRewardsReceived();
            uint256 unprocessed = received - totalETHSeen;

            if (unprocessed > 0) {
                emit ETHReceived(unprocessed);

                // accumulated ETH per minted share is scaled to avoid precision loss. it is scaled down later
                accumulatedETHPerLPShare += (unprocessed * PRECISION) / _numOfShares;

                totalETHSeen = received;
            }
        }
    }

    /// @notice Total rewards received by this contract from the syndicate
    function totalRewardsReceived() public virtual view returns (uint256);

    /// @notice Allow the contract to receive ETH
    receive() external payable {}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import "@openzeppelin/contracts/proxy/beacon/IBeacon.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/// @title Beacon with upgradeable implementation
contract UpgradeableBeacon is IBeacon, Ownable {
    using Address for address;

    address private implementation_;

    /// @notice Emitted when the implementation returned by the beacon is changed.
    event Upgraded(address indexed implementation);

    /// @param _implementation Address of the logic contract
    constructor(address _implementation, address _owner) {
        _setImplementation(_implementation);

        transferOwnership(_owner);
    }

    /// @return current implementation address
    function implementation() override external view returns (address) {
        return implementation_;
    }

    /// @notice Allows an admin to change the implementation / logic address
    /// @param _implementation Address of the new implementation
    function updateImplementation(address _implementation) external onlyOwner {
        _setImplementation(_implementation);
    }

    /// @dev internal method for setting the implementation making sure the supplied address is a contract
    function _setImplementation(address _implementation) private {
        require(_implementation != address(0), "Invalid implementation");
        require(_implementation.isContract(), "_setImplementation: Implementation address does not have a contract");
        implementation_ = _implementation;
        emit Upgraded(implementation_);
    }
}

// Based on https://github.com/OpenZeppelin/openzeppelin-contracts/blob/0db76e98f90550f1ebbb3dea71c7d12d5c533b5c/contracts/proxy/UpgradeableBeacon.sol

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IOwnableSmartWalletEvents {
    event TransferApprovalChanged(
        address indexed from,
        address indexed to,
        bool status
    );
}

interface IOwnableSmartWallet is IOwnableSmartWalletEvents {
    /// @dev Initialization function used instead of a constructor,
    ///      since the intended creation method is cloning
    function initialize(address initialOwner) external;

    /// @dev Makes an arbitrary function call with value to a contract, with provided calldata
    /// @param target Address of a contract to call
    /// @param callData Data to pass with the call
    /// @notice Payable. The passed value will be forwarded to the target.
    function execute(address target, bytes memory callData)
        external
        payable
        returns (bytes memory);

    /// @dev Makes an arbitrary function call with value to a contract, with provided calldata and value
    /// @param target Address of a contract to call
    /// @param callData Data to pass with the call
    /// @param value ETH value to pass to the target
    /// @notice Payable. Allows the user to explicitly state the ETH value, in order to,
    ///         e.g., pay with the contract's own balance.
    function execute(
        address target,
        bytes memory callData,
        uint256 value
    ) external payable returns (bytes memory);

    /// @notice Makes an arbitrary call to an address attaching value and optional calldata using raw .call{value}
    /// @param target Address of the destination
    /// @param callData Optional data to pass with the call
    /// @param value Optional ETH value to pass to the target
    function rawExecute(
        address target,
        bytes memory callData,
        uint256 value
    ) external payable returns (bytes memory);

    /// @dev Transfers ownership from the current owner to another address
    /// @param newOwner The address that will be the new owner
    function transferOwnership(address newOwner) external;

    /// @dev Changes authorization status for transfer approval from msg.sender to an address
    /// @param to Address to change allowance status for
    /// @param status The new approval status
    function setApproval(address to, bool status) external;

    /// @dev Returns whether the address 'to' can transfer a wallet from address 'from'
    /// @param from The owner address
    /// @param to The spender address
    /// @notice The owner can always transfer the wallet to someone, i.e.,
    ///         approval from an address to itself is always 'true'
    function isTransferApproved(address from, address to)
        external
        view
        returns (bool);

    /// @dev Returns the current owner of the wallet
    function owner() external view returns (address);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IOwnableSmartWalletFactoryEvents {
    event WalletCreated(address indexed wallet, address indexed owner);
}

interface IOwnableSmartWalletFactory is IOwnableSmartWalletFactoryEvents {
    function createWallet() external returns (address wallet);

    function createWallet(address owner) external returns (address wallet);

    function walletExists(address wallet) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {IOwnableSmartWallet} from "./interfaces/IOwnableSmartWallet.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Initializable} from "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

/// @title Ownable smart wallet
/// @notice Ownable and transferrable smart wallet that allows the owner to
///         interact with any contracts the same way as from an EOA. The
///         main intended use is to make non-transferrable positions and assets
///         liquid and usable in strategies.
/// @notice Intended to be used with a factory and the cloning pattern.
contract OwnableSmartWallet is IOwnableSmartWallet, Ownable, Initializable {
    using Address for address;

    /// @dev A map from owner and spender to transfer approval. Determines whether
    ///      the spender can transfer this wallet from the owner. Can be used
    ///      to put this wallet in possession of a strategy (e.g., as collateral).
    mapping(address => mapping(address => bool)) internal _isTransferApproved;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @inheritdoc IOwnableSmartWallet
    function initialize(address initialOwner)
        external
        override
        initializer // F: [OSW-1]
    {
        require(
            initialOwner != address(0),
            "OwnableSmartWallet: Attempting to initialize with zero address owner"
        );
        _transferOwnership(initialOwner); // F: [OSW-1]
    }

    /// @inheritdoc IOwnableSmartWallet
    function execute(address target, bytes memory callData)
        external
        override
        payable
        onlyOwner // F: [OSW-6A]
        returns (bytes memory)
    {
        return target.functionCallWithValue(callData, msg.value); // F: [OSW-6]
    }

    /// @inheritdoc IOwnableSmartWallet
    function execute(
        address target,
        bytes memory callData,
        uint256 value
    )
        external
        override
        payable
        onlyOwner // F: [OSW-6A]
        returns (bytes memory)
    {
        return target.functionCallWithValue(callData, value); // F: [OSW-6]
    }

    /// @inheritdoc IOwnableSmartWallet
    function rawExecute(
        address target,
        bytes memory callData,
        uint256 value
    )
    external
    override
    payable
    onlyOwner
    returns (bytes memory)
    {
        (bool result, bytes memory message) = target.call{value: value}(callData);
        require(result, "Failed to execute");
        return message;
    }

    /// @inheritdoc IOwnableSmartWallet
    function owner()
        public
        view
        override(IOwnableSmartWallet, Ownable)
        returns (address)
    {
        return Ownable.owner(); // F: [OSW-1]
    }

    /// @inheritdoc IOwnableSmartWallet
    function transferOwnership(address newOwner)
        public
        override(IOwnableSmartWallet, Ownable)
    {
        // Only the owner themselves or an address that is approved for transfers
        // is authorized to do this
        require(
            isTransferApproved(owner(), msg.sender),
            "OwnableSmartWallet: Transfer is not allowed"
        ); // F: [OSW-4]

        // Approval is revoked, in order to avoid unintended transfer allowance
        // if this wallet ever returns to the previous owner
        if (msg.sender != owner()) {
            _setApproval(owner(), msg.sender, false); // F: [OSW-5]
        }
        _transferOwnership(newOwner); // F: [OSW-5]
    }

    /// @inheritdoc IOwnableSmartWallet
    function setApproval(address to, bool status) external onlyOwner override {
        require(
            to != address(0),
            "OwnableSmartWallet: Approval cannot be set for zero address"
        ); // F: [OSW-2A]
        _setApproval(msg.sender, to, status);
    }

    /// @dev IMPLEMENTATION: _setApproval
    /// @param from The owner address
    /// @param to The spender address
    /// @param status Status of approval
    function _setApproval(
        address from,
        address to,
        bool status
    ) internal {
        bool statusChanged = _isTransferApproved[from][to] != status;
        _isTransferApproved[from][to] = status; // F: [OSW-2]
        if (statusChanged) {
            emit TransferApprovalChanged(from, to, status); // F: [OSW-2]
        }
    }

    /// @inheritdoc IOwnableSmartWallet
    function isTransferApproved(address from, address to)
        public
        override
        view
        returns (bool)
    {
        return from == to ? true : _isTransferApproved[from][to]; // F: [OSW-2, 3]
    }

    receive() external payable {
        // receive ETH
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {OwnableSmartWallet} from "./OwnableSmartWallet.sol";
import {IOwnableSmartWallet} from "./interfaces/IOwnableSmartWallet.sol";
import {IOwnableSmartWalletFactory} from "./interfaces/IOwnableSmartWalletFactory.sol";

/// @title Ownable smart wallet factory
contract OwnableSmartWalletFactory is IOwnableSmartWalletFactory {

    /// @dev Address of the contract to clone from
    address public immutable masterWallet;

    /// @dev Whether a wallet is created by this factory
    /// @notice Can be used to verify that the address is actually
    ///         OwnableSmartWallet and not an impersonating malicious
    ///         account
    mapping(address => bool) public walletExists;

    constructor() {
        masterWallet = address(new OwnableSmartWallet());

        emit WalletCreated(masterWallet, address(this)); // F: [OSWF-2]
    }

    function createWallet() external returns (address wallet) {
        wallet = _createWallet(msg.sender); // F: [OSWF-1]
    }

    function createWallet(address owner) external returns (address wallet) {
        wallet = _createWallet(owner); // F: [OSWF-1]
    }

    function _createWallet(address owner) internal returns (address wallet) {
        require(owner != address(0), 'Wallet cannot be address 0');

        wallet = Clones.clone(masterWallet);
        IOwnableSmartWallet(wallet).initialize(owner); // F: [OSWF-1]
        walletExists[wallet] = true;

        emit WalletCreated(wallet, owner); // F: [OSWF-1]
    }
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: BUSL-1.1

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { StakehouseAPI } from "@blockswaplab/stakehouse-solidity-api/contracts/StakehouseAPI.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import { ISyndicateInit } from "../interfaces/ISyndicateInit.sol";
import { ETHTransferHelper } from "../transfer/ETHTransferHelper.sol";
import {
    ZeroAddress,
    EmptyArray,
    InconsistentArrayLengths,
    InvalidBLSPubKey,
    InvalidNumberOfCollateralizedOwners,
    KnotSlashed,
    FreeFloatingStakeAmountTooSmall,
    KnotIsNotRegisteredWithSyndicate,
    NotPriorityStaker,
    KnotIsFullyStakedWithFreeFloatingSlotTokens,
    InvalidStakeAmount,
    KnotIsNotAssociatedWithAStakeHouse,
    UnableToStakeFreeFloatingSlot,
    NothingStaked,
    TransferFailed,
    NotCollateralizedOwnerAtIndex,
    InactiveKnot,
    DuplicateArrayElements,
    KnotIsAlreadyRegistered,
    KnotHasAlreadyBeenDeRegistered,
    NotKickedFromBeaconChain
} from "./SyndicateErrors.sol";

interface IExtendedAccountManager {
    function blsPublicKeyToLastState(bytes calldata _blsPublicKey) external view returns (
        bytes memory, // BLS public key
        bytes memory, // Withdrawal credentials
        bool,  // Slashed
        uint64,// Active balance
        uint64,// Effective balance
        uint64,// Exit epoch
        uint64,// Activation epoch
        uint64,// Withdrawal epoch
        uint64 // Current checkpoint epoch
    );
}

/// @notice Syndicate registry and funds splitter for EIP1559 execution layer transaction tips across SLOT shares
/// @dev This contract can be extended to allow lending and borrowing of time slots for borrower to redeem any revenue generated within the specified window
contract Syndicate is ISyndicateInit, Initializable, Ownable, ReentrancyGuard, StakehouseAPI, ETHTransferHelper {

    /// @notice Emitted when the contract is initially deployed
    event ContractDeployed();

    /// @notice Emitted when accrued ETH per SLOT share type is updated
    event UpdateAccruedETH(uint256 unprocessed);

    /// @notice Emitted when new collateralized SLOT owners for a knot prompts re-calibration
    event CollateralizedSLOTReCalibrated(bytes BLSPubKey);

    /// @notice Emitted when a new KNOT is associated with the syndicate contract
    event KNOTRegistered(bytes BLSPubKey);

    /// @notice Emitted when a KNOT is de-registered from the syndicate
    event KnotDeRegistered(bytes BLSPubKey);

    /// @notice Emitted when a priority staker is added to the syndicate
    event PriorityStakerRegistered(address indexed staker);

    /// @notice Emitted when a user stakes free floating sETH tokens
    event Staked(bytes BLSPubKey, uint256 amount);

    /// @notice Emitted when a user unstakes free floating sETH tokens
    event UnStaked(bytes BLSPubKey, uint256 amount);

    /// @notice Emitted when either an sETH staker or collateralized SLOT owner claims ETH
    event ETHClaimed(bytes BLSPubKey, address indexed user, address recipient, uint256 claim, bool indexed isCollateralizedClaim);

    /// @notice Emitted when the owner specifies a new activation distance
    event ActivationDistanceUpdated();

    /// @notice Precision used in rewards calculations for scaling up and down
    uint256 public constant PRECISION = 1e24;

    /// @notice Total accrued ETH per free floating share for new and old stakers
    uint256 public accumulatedETHPerFreeFloatingShare;

    /// @notice Total accrued ETH for all collateralized SLOT holders per knot which is then distributed based on individual balances
    uint256 public accumulatedETHPerCollateralizedSlotPerKnot;

    /// @notice Last cached highest seen balance for all collateralized shares
    uint256 public lastSeenETHPerCollateralizedSlotPerKnot;

    /// @notice Last cached highest seen balance for all free floating shares
    uint256 public lastSeenETHPerFreeFloating;

    /// @notice Total number of sETH token shares staked across all houses
    uint256 public totalFreeFloatingShares;

    /// @notice Total amount of ETH drawn down by syndicate beneficiaries regardless of SLOT type
    uint256 public totalClaimed;

    /// @notice Number of knots registered with the syndicate which can be across any house
    uint256 public numberOfActiveKnots;

    /// @notice Informational - is the knot registered to this syndicate or not - the node should point to this contract
    mapping(bytes => bool) public isKnotRegistered;

    /// @notice Block number after which if there are sETH staking slots available, it can be supplied by anyone on the market
    uint256 public priorityStakingEndBlock;

    /// @notice Syndicate deployer can highlight addresses that get priority for staking free floating house sETH up to a certain block before anyone can do it
    mapping(address => bool) public isPriorityStaker;

    /// @notice Total amount of free floating sETH staked
    mapping(bytes => uint256) public sETHTotalStakeForKnot;

    /// @notice Amount of sETH staked by user against a knot
    mapping(bytes => mapping(address => uint256)) public sETHStakedBalanceForKnot;

    /// @notice Amount of ETH claimed by user from sETH staking
    mapping(bytes => mapping(address => uint256)) public sETHUserClaimForKnot;

    /// @notice Total amount of ETH that has been allocated to the collateralized SLOT owners of a KNOT
    mapping(bytes => uint256) public totalETHProcessedPerCollateralizedKnot;

    /// @notice Total amount of ETH accrued for the collateralized SLOT owner of a KNOT
    mapping(bytes => mapping(address => uint256)) public accruedEarningPerCollateralizedSlotOwnerOfKnot;

    /// @notice Total amount of ETH claimed by the collateralized SLOT owner of a KNOT
    mapping(bytes => mapping(address => uint256)) public claimedPerCollateralizedSlotOwnerOfKnot;

    /// @notice Whether a BLS public key, that has been previously registered, is no longer part of the syndicate and its shares (free floating or SLOT) cannot earn any more rewards
    mapping(bytes => bool) public isNoLongerPartOfSyndicate;

    /// @notice Once a BLS public key is no longer part of the syndicate, the accumulated ETH per free floating SLOT share is snapshotted so historical earnings can be drawn down correctly
    mapping(bytes => uint256) public lastAccumulatedETHPerFreeFloatingShare;

    /// @notice Future activation block of a KNOT i.e. from what block they can start to accrue rewards. Enforced delay to protect against dilution
    mapping(bytes => uint256) public activationBlock;

    /// @notice List of proposers that required historical activation
    bytes[] public proposersToActivate;

    /// @notice Distance in blocks new proposers must wait before being able to receive Syndicate rewards
    uint256 public activationDistance;

    /// @notice Monotonically increasing pointer used to track which proposers have been activated
    uint256 public activationPointer;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @param _contractOwner Ethereum public key that will receive management rights of the contract
    /// @param _priorityStakingEndBlock Block number when priority sETH staking ends and anyone can stake
    /// @param _priorityStakers Optional list of addresses that will have priority for staking sETH against each knot registered
    /// @param _blsPubKeysForSyndicateKnots List of BLS public keys of Stakehouse protocol registered KNOTs participating in syndicate
    function initialize(
        address _contractOwner,
        uint256 _priorityStakingEndBlock,
        address[] memory _priorityStakers,
        bytes[] memory _blsPubKeysForSyndicateKnots
    ) external virtual override initializer {
        _initialize(
            _contractOwner,
            _priorityStakingEndBlock,
            _priorityStakers,
            _blsPubKeysForSyndicateKnots
        );
    }

    /// @notice Allows the contract owner to append to the list of knots that are part of the syndicate
    /// @param _newBLSPublicKeyBeingRegistered List of BLS public keys being added to the syndicate
    function registerKnotsToSyndicate(
        bytes[] calldata _newBLSPublicKeyBeingRegistered
    ) external onlyOwner {
        // update accrued ETH per SLOT type
        activateProposers();
        _registerKnotsToSyndicate(_newBLSPublicKeyBeingRegistered);
    }

    /// @notice Make knot shares of a registered list of BLS public keys inactive - the action cannot be undone and no further ETH accrued
    function deRegisterKnots(bytes[] calldata _blsPublicKeys) external onlyOwner {
        _deRegisterKnots(_blsPublicKeys);
    }

    /// @notice Allow syndicate users to inform the contract that a beacon chain kicking has taken place -
    /// @notice The associated SLOT shares should not continue to earn pro-rata shares
    /// @param _blsPublicKeys List of BLS keys reported to the Stakehouse protocol
    function informSyndicateKnotsAreKickedFromBeaconChain(bytes[] calldata _blsPublicKeys) external {
        for (uint256 i; i < _blsPublicKeys.length; ++i) {
            (,,bool slashed,,,,,,) = IExtendedAccountManager(address(getAccountManager())).blsPublicKeyToLastState(
                _blsPublicKeys[i]
            );

            if (!slashed) revert NotKickedFromBeaconChain();
        }

        _deRegisterKnots(_blsPublicKeys);
    }

    /// @notice Allows the contract owner to append to the list of priority sETH stakers
    /// @param _priorityStakers List of staker addresses eligible for sETH staking
    function addPriorityStakers(address[] calldata _priorityStakers) external onlyOwner {
        activateProposers();
        _addPriorityStakers(_priorityStakers);
    }

    /// @notice Should this block be in the future, it means only those listed in the priority staker list can stake sETH
    /// @param _endBlock Arbitrary block number after which anyone can stake up to 4 SLOT in sETH per KNOT
    function updatePriorityStakingBlock(uint256 _endBlock) external onlyOwner {
        activateProposers();
        priorityStakingEndBlock = _endBlock;
    }

    /// @notice Allow syndicate owner to manage activation distance for new proposers
    function updateActivationDistanceInBlocks(uint256 _distance) external onlyOwner {
        activationDistance = _distance;
        emit ActivationDistanceUpdated();
    }

    /// @notice Total number knots that registered with the syndicate
    function numberOfRegisteredKnots() external view returns (uint256) {
        return proposersToActivate.length;
    }

    /// @notice Total number of registered proposers that are yet to be activated
    function totalProposersToActivate() external view returns (uint256) {
        return proposersToActivate.length - activationPointer;
    }

    /// @notice Allow for a fixed number of proposers to be activated to start earning pro-rata ETH
    function activateProposers() public {
        // Snapshot historical earnings
        if (numberOfActiveKnots > 0) {
            updateAccruedETHPerShares();
        }

        // Retrieve number of proposers to activate capping total number that are activated
        uint256 currentActivated = numberOfActiveKnots;
        uint256 numToActivate = proposersToActivate.length - activationPointer;
        numToActivate = numToActivate > 15 ? 15 : numToActivate;
        while (numToActivate > 0) {
            bytes memory blsPublicKey = proposersToActivate[activationPointer];

            // The expectation is that everyone in the queue of proposers to activate have increasing activation block numbers
            if (block.number < activationBlock[blsPublicKey]) {
                break;
            }

            totalFreeFloatingShares += sETHTotalStakeForKnot[blsPublicKey];

            // incoming knot collateralized SLOT holders do not get historical earnings
            totalETHProcessedPerCollateralizedKnot[blsPublicKey] = accumulatedETHPerCollateralizedSlotPerKnot;

            // incoming knot free floating SLOT holders do not get historical earnings
            lastAccumulatedETHPerFreeFloatingShare[blsPublicKey] = accumulatedETHPerFreeFloatingShare;

            numberOfActiveKnots += 1;
            activationPointer += 1;
            numToActivate -= 1;
        }

        if (currentActivated == 0) {
            updateAccruedETHPerShares();
        }
    }

    /// @notice Update accrued ETH per SLOT share without distributing ETH as users of the syndicate individually pull funds
    function updateAccruedETHPerShares() public {
        // Ensure there are registered KNOTs. Syndicates are deployed with at least 1 registered but this can fall to zero.
        // Fee recipient should be re-assigned in the event that happens as any further ETH can be collected by owner
        if (numberOfActiveKnots > 0) {
            // All time, total ETH that was earned per slot type (free floating or collateralized)
            uint256 totalEthPerSlotType = calculateETHForFreeFloatingOrCollateralizedHolders();

            // Process free floating if there are staked shares
            uint256 freeFloatingUnprocessed;
            if (totalFreeFloatingShares > 0) {
                freeFloatingUnprocessed = getUnprocessedETHForAllFreeFloatingSlot();
                accumulatedETHPerFreeFloatingShare += _calculateNewAccumulatedETHPerFreeFloatingShare(freeFloatingUnprocessed, false);
                lastSeenETHPerFreeFloating = totalEthPerSlotType;
            }

            uint256 collateralizedUnprocessed = ((totalEthPerSlotType - lastSeenETHPerCollateralizedSlotPerKnot) / numberOfActiveKnots);
            accumulatedETHPerCollateralizedSlotPerKnot += collateralizedUnprocessed;
            lastSeenETHPerCollateralizedSlotPerKnot = totalEthPerSlotType;

            emit UpdateAccruedETH(freeFloatingUnprocessed + collateralizedUnprocessed);
        }
    }

    /// @notice Stake up to 4 collateralized SLOT worth of sETH per KNOT to get a portion of syndicate rewards
    /// @param _blsPubKeys List of BLS public keys for KNOTs registered with the syndicate
    /// @param _sETHAmounts Per BLS public key, the total amount of sETH that will be staked (up to 4 collateralized SLOT per KNOT)
    /// @param _onBehalfOf Allows a caller to specify an address that will be assigned stake ownership and rights to claim
    function stake(bytes[] calldata _blsPubKeys, uint256[] calldata _sETHAmounts, address _onBehalfOf) external {
        uint256 numOfKeys = _blsPubKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        if (numOfKeys != _sETHAmounts.length) revert InconsistentArrayLengths();
        if (_onBehalfOf == address(0)) revert ZeroAddress();

        // Make sure we have the latest accrued information
        activateProposers();

        for (uint256 i; i < numOfKeys; ++i) {
            bytes memory _blsPubKey = _blsPubKeys[i];
            uint256 _sETHAmount = _sETHAmounts[i];

            if (_sETHAmount < 1 gwei) revert FreeFloatingStakeAmountTooSmall();
            if (!isKnotRegistered[_blsPubKey]) revert KnotIsNotRegisteredWithSyndicate();
            if (isNoLongerPartOfSyndicate[_blsPubKey]) revert KnotIsNotRegisteredWithSyndicate();

            if (block.number < priorityStakingEndBlock && !isPriorityStaker[_onBehalfOf]) revert NotPriorityStaker();

            uint256 totalStaked = sETHTotalStakeForKnot[_blsPubKey];
            if (totalStaked == 12 ether) revert KnotIsFullyStakedWithFreeFloatingSlotTokens();

            if (_sETHAmount + totalStaked > 12 ether) revert InvalidStakeAmount();

            if (block.number > activationBlock[_blsPubKey]) {
                // Pre activation block we cannot increase but post activation we need to instantly increase shares
                totalFreeFloatingShares += _sETHAmount;
            }

            sETHTotalStakeForKnot[_blsPubKey] += _sETHAmount;
            sETHStakedBalanceForKnot[_blsPubKey][_onBehalfOf] += _sETHAmount;
            sETHUserClaimForKnot[_blsPubKey][_onBehalfOf] += (_sETHAmount * accumulatedETHPerFreeFloatingShare) / PRECISION;

            (address stakeHouse,,,,,bool isActive) = getStakeHouseUniverse().stakeHouseKnotInfo(_blsPubKey);
            if (stakeHouse == address(0)) revert KnotIsNotAssociatedWithAStakeHouse();
            if (!isActive) revert InactiveKnot();

            IERC20 sETH = IERC20(getSlotRegistry().stakeHouseShareTokens(stakeHouse));

            bool transferResult = sETH.transferFrom(msg.sender, address(this), _sETHAmount);
            if (!transferResult) revert UnableToStakeFreeFloatingSlot();

            emit Staked(_blsPubKey, _sETHAmount);
        }
    }

    /// @notice Unstake an sETH position against a particular KNOT and claim ETH on exit
    /// @param _unclaimedETHRecipient The address that will receive any unclaimed ETH received to the syndicate
    /// @param _sETHRecipient The address that will receive the sETH that is being unstaked
    /// @param _blsPubKeys List of BLS public keys for KNOTs registered with the syndicate
    /// @param _sETHAmounts Per BLS public key, the total amount of sETH that will be unstaked
    function unstake(
        address _unclaimedETHRecipient,
        address _sETHRecipient,
        bytes[] calldata _blsPubKeys,
        uint256[] calldata _sETHAmounts
    ) external nonReentrant {
        uint256 numOfKeys = _blsPubKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        if (numOfKeys != _sETHAmounts.length) revert InconsistentArrayLengths();
        if (_unclaimedETHRecipient == address(0)) revert ZeroAddress();
        if (_sETHRecipient == address(0)) revert ZeroAddress();

        // Claim all ETH owed before unstaking but even if nothing is owed `updateAccruedETHPerShares` will be called
        _claimAsStaker(_unclaimedETHRecipient, _blsPubKeys);

        for (uint256 i; i < numOfKeys; ++i) {
            bytes memory _blsPubKey = _blsPubKeys[i];
            uint256 _sETHAmount = _sETHAmounts[i];
            if (sETHStakedBalanceForKnot[_blsPubKey][msg.sender] < _sETHAmount) revert NothingStaked();
            if (block.number < activationBlock[_blsPubKey]) revert InactiveKnot();

            (address stakeHouse,,,,,bool isActive) = getStakeHouseUniverse().stakeHouseKnotInfo(_blsPubKey);
            IERC20 sETH = IERC20(getSlotRegistry().stakeHouseShareTokens(stakeHouse));

            // Only decrease totalFreeFloatingShares in the event that the knot is still active in the syndicate
            if (!isNoLongerPartOfSyndicate[_blsPubKey]) {
                totalFreeFloatingShares -= _sETHAmount;
            }

            sETHTotalStakeForKnot[_blsPubKey] -= _sETHAmount;
            sETHStakedBalanceForKnot[_blsPubKey][msg.sender] -= _sETHAmount;

            uint256 accumulatedETHPerShare = _getCorrectAccumulatedETHPerFreeFloatingShareForBLSPublicKey(_blsPubKey);
            sETHUserClaimForKnot[_blsPubKey][msg.sender] =
                (accumulatedETHPerShare * sETHStakedBalanceForKnot[_blsPubKey][msg.sender]) / PRECISION;

            // If the stakehouse lets the syndicate know the knot is no longer active, kick knot from syndicate to prevent more rewards being earned
            if (!isNoLongerPartOfSyndicate[_blsPubKey] && !isActive) {
                _deRegisterKnot(_blsPubKey);
            }

            bool transferResult = sETH.transfer(_sETHRecipient, _sETHAmount);
            if (!transferResult) revert TransferFailed();

            emit UnStaked(_blsPubKey, _sETHAmount);
        }
    }

    /// @notice Claim ETH cashflow from the syndicate as an sETH staker proportional to how much the user has staked
    /// @param _recipient Address that will receive the share of ETH funds
    /// @param _blsPubKeys List of BLS public keys that the caller has staked against
    function claimAsStaker(address _recipient, bytes[] calldata _blsPubKeys) public nonReentrant {
        _claimAsStaker(_recipient, _blsPubKeys);
    }

    /// @param _blsPubKeys List of BLS public keys that the caller has staked against
    function claimAsCollateralizedSLOTOwner(
        address _recipient,
        bytes[] calldata _blsPubKeys
    ) external nonReentrant {
        uint256 numOfKeys = _blsPubKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        if (_recipient == address(0)) revert ZeroAddress();
        if (_recipient == address(this)) revert ZeroAddress();

        // Make sure we have the latest accrued information for all shares
        activateProposers();

        uint256 totalToTransfer;
        for (uint256 i; i < numOfKeys; ++i) {
            bytes memory _blsPubKey = _blsPubKeys[i];
            if (!isKnotRegistered[_blsPubKey]) revert KnotIsNotRegisteredWithSyndicate();
            if (block.number < activationBlock[_blsPubKey]) revert InactiveKnot();

            // process newly accrued ETH and distribute it to collateralized SLOT owners for the given knot
            _updateCollateralizedSlotOwnersLiabilitySnapshot(_blsPubKey);

            // Calculate total amount of unclaimed ETH
            uint256 userShare = accruedEarningPerCollateralizedSlotOwnerOfKnot[_blsPubKey][msg.sender];

            // This is designed to cope with falling SLOT balances i.e. when collateralized SLOT is burnt after applying penalties
            uint256 unclaimedUserShare = userShare - claimedPerCollateralizedSlotOwnerOfKnot[_blsPubKey][msg.sender];

            // Send ETH to the user if there is an unclaimed amount
            if (unclaimedUserShare > 0) {
                // Increase total claimed and claimed at the user level
                totalClaimed += unclaimedUserShare;
                claimedPerCollateralizedSlotOwnerOfKnot[_blsPubKey][msg.sender] = userShare;

                // Send ETH to user
                totalToTransfer += unclaimedUserShare;

                emit ETHClaimed(
                    _blsPubKey,
                    msg.sender,
                    _recipient,
                    unclaimedUserShare,
                    true
                );
            }
        }

        _transferETH(_recipient, totalToTransfer);
    }

    /// @notice For any new ETH received by the syndicate, at the knot level allocate ETH owed to each collateralized owner
    /// @param _blsPubKey BLS public key relating to the collateralized owners that need updating
    function updateCollateralizedSlotOwnersAccruedETH(bytes memory _blsPubKey) external {
        activateProposers();
        _updateCollateralizedSlotOwnersLiabilitySnapshot(_blsPubKey);
    }

    /// @notice For any new ETH received by the syndicate, at the knot level allocate ETH owed to each collateralized owner and do it for a batch of knots
    /// @param _blsPubKeys List of BLS public keys related to the collateralized owners that need updating
    function batchUpdateCollateralizedSlotOwnersAccruedETH(bytes[] memory _blsPubKeys) external {
        uint256 numOfKeys = _blsPubKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        activateProposers();
        for (uint256 i; i < numOfKeys; ++i) {
            _updateCollateralizedSlotOwnersLiabilitySnapshot(_blsPubKeys[i]);
        }
    }

    /// @notice Syndicate contract can receive ETH
    receive() external payable {
        // No logic here because one cannot assume that more than 21K GAS limit is forwarded
    }

    /// @notice Calculate the amount of unclaimed ETH for a given BLS publice key + free floating SLOT staker without factoring in unprocessed rewards
    /// @param _blsPubKey BLS public key of the KNOT that is registered with the syndicate
    /// @param _user The address of a user that has staked sETH against the BLS public key
    function calculateUnclaimedFreeFloatingETHShare(bytes memory _blsPubKey, address _user) public view returns (uint256) {
        // Check the user has staked sETH for the KNOT
        uint256 stakedBal = sETHStakedBalanceForKnot[_blsPubKey][_user];

        // Get the amount of ETH eligible for the user based on their staking amount
        uint256 accumulatedETHPerShare = _getCorrectAccumulatedETHPerFreeFloatingShareForBLSPublicKey(_blsPubKey);
        uint256 userShare = (accumulatedETHPerShare * stakedBal) / PRECISION;

        // When the user is claiming ETH from the syndicate for the first time, we need to adjust for the activation
        // This will ensure that rewards accrued before activation are not considered
        uint256 adjustedClaimForActivation;
        if (!isNoLongerPartOfSyndicate[_blsPubKey] && sETHUserClaimForKnot[_blsPubKey][_user] == 0) {
            adjustedClaimForActivation = (lastAccumulatedETHPerFreeFloatingShare[_blsPubKey] * stakedBal) / PRECISION;
        }

        // Calculate how much their unclaimed share of ETH is based on total ETH claimed so far
        return userShare - sETHUserClaimForKnot[_blsPubKey][_user] - adjustedClaimForActivation;
    }

    /// @notice Using `highestSeenBalance`, this is the amount that is separately allocated to either free floating or collateralized SLOT holders
    function calculateETHForFreeFloatingOrCollateralizedHolders() public view returns (uint256) {
        // Get total amount of ETH that can be drawn down by all SLOT holders associated with a knot
        uint256 ethPerKnot = totalETHReceived();

        // Get the amount of ETH eligible for free floating sETH or collateralized SLOT stakers
        return ethPerKnot / 2;
    }

    /// @notice Preview how many proposers can be activated either manually or when the accrued ETH per shares are updated
    function previewActivateableProposers() public view returns (uint256) {
        uint256 index = activationPointer;
        uint256 numToActivate = proposersToActivate.length - index;
        numToActivate = numToActivate > 15 ? 15 : numToActivate;
        uint256 numOfActivateable;
        while(numToActivate > 0) {
            bytes memory blsPublicKey = proposersToActivate[index];

            if (block.number < activationBlock[blsPublicKey]) {
                break;
            } else {
                numOfActivateable += 1;
            }

            index += 1;
            numToActivate -= 1;
        }

        return numOfActivateable;
    }

    /// @notice Total free floating shares that can be activated in the next block
    function previewTotalFreeFloatingSharesToActivate() public view returns (uint256) {
        uint256 index = activationPointer;
        uint256 numToActivate = proposersToActivate.length - index;
        numToActivate = numToActivate > 15 ? 15 : numToActivate;
        uint256 totalSharesToActivate;
        while(numToActivate > 0) {
            bytes memory blsPublicKey = proposersToActivate[index];

            if (block.number < activationBlock[blsPublicKey]) {
                break;
            } else {
                totalSharesToActivate += sETHTotalStakeForKnot[blsPublicKey];
            }

            index += 1;
            numToActivate -= 1;
        }

        return totalSharesToActivate;
    }

    /// @notice Calculate the total unclaimed ETH across an array of BLS public keys for a free floating staker
    function batchPreviewUnclaimedETHAsFreeFloatingStaker(
        address _staker,
        bytes[] calldata _blsPubKeys
    ) external view returns (uint256) {
        uint256 accumulated;
        uint256 numOfKeys = _blsPubKeys.length;
        for (uint256 i; i < numOfKeys; ++i) {
            accumulated += previewUnclaimedETHAsFreeFloatingStaker(_staker, _blsPubKeys[i]);
        }

        return accumulated;
    }

    /// @notice Preview the amount of unclaimed ETH available for an sETH staker against a KNOT which factors in unprocessed rewards from new ETH sent to contract
    /// @param _blsPubKey BLS public key of the KNOT that is registered with the syndicate
    /// @param _staker The address of a user that has staked sETH against the BLS public key
    function previewUnclaimedETHAsFreeFloatingStaker(
        address _staker,
        bytes calldata _blsPubKey
    ) public view returns (uint256) {
        uint256 currentAccumulatedETHPerFreeFloatingShare = accumulatedETHPerFreeFloatingShare;
        uint256 updatedAccumulatedETHPerFreeFloatingShare =
                            currentAccumulatedETHPerFreeFloatingShare + calculateNewAccumulatedETHPerFreeFloatingShare();

        uint256 stakedBal = sETHStakedBalanceForKnot[_blsPubKey][_staker];
        uint256 userShare = (updatedAccumulatedETHPerFreeFloatingShare * stakedBal) / PRECISION;

        return userShare - sETHUserClaimForKnot[_blsPubKey][_staker];
    }

    /// @notice Calculate the total unclaimed ETH across an array of BLS public keys for a collateralized SLOT staker
    function batchPreviewUnclaimedETHAsCollateralizedSlotOwner(
        address _staker,
        bytes[] calldata _blsPubKeys
    ) external view returns (uint256) {
        uint256 accumulated;
        uint256 numOfKeys = _blsPubKeys.length;
        for (uint256 i; i < numOfKeys; ++i) {
            accumulated += previewUnclaimedETHAsCollateralizedSlotOwner(_staker, _blsPubKeys[i]);
        }

        return accumulated;
    }

    /// @notice Preview the amount of unclaimed ETH available for a collatearlized SLOT staker against a KNOT which factors in unprocessed rewards from new ETH sent to contract
    /// @param _staker Address of a collateralized SLOT owner for a KNOT
    /// @param _blsPubKey BLS public key of the KNOT that is registered with the syndicate
    function previewUnclaimedETHAsCollateralizedSlotOwner(
        address _staker,
        bytes calldata _blsPubKey
    ) public view returns (uint256) {
        if (numberOfActiveKnots + previewActivateableProposers() == 0) return 0;

        // Per collateralized SLOT per KNOT before distributing to individual collateralized owners
        uint256 accumulatedSoFar = accumulatedETHPerCollateralizedSlotPerKnot
                    + ((calculateETHForFreeFloatingOrCollateralizedHolders() - lastSeenETHPerCollateralizedSlotPerKnot) / (numberOfActiveKnots + previewActivateableProposers()));

        uint256 unprocessedForKnot = accumulatedSoFar - totalETHProcessedPerCollateralizedKnot[_blsPubKey];

        // Fetch information on what has been processed so far against the ECDSA address of the collateralized SLOT owner
        uint256 currentAccrued = accruedEarningPerCollateralizedSlotOwnerOfKnot[_blsPubKey][_staker];

        // Fetch information about the knot including total slashed amount
        uint256 currentSlashedAmount = getSlotRegistry().currentSlashedAmountOfSLOTForKnot(_blsPubKey);
        uint256 numberOfCollateralisedSlotOwnersForKnot = getSlotRegistry().numberOfCollateralisedSlotOwnersForKnot(_blsPubKey);
        (address stakeHouse,,,,,) = getStakeHouseUniverse().stakeHouseKnotInfo(_blsPubKey);

        // Find the collateralized SLOT owner and work out how much they're owed
        for (uint256 i; i < numberOfCollateralisedSlotOwnersForKnot; ++i) {
            address collateralizedOwnerAtIndex = getSlotRegistry().getCollateralisedOwnerAtIndex(_blsPubKey, i);
            if (collateralizedOwnerAtIndex == _staker) {
                uint256 balance = getSlotRegistry().totalUserCollateralisedSLOTBalanceForKnot(
                    stakeHouse,
                    collateralizedOwnerAtIndex,
                    _blsPubKey
                );

                if (currentSlashedAmount < 4 ether) {
                    currentAccrued +=
                    numberOfCollateralisedSlotOwnersForKnot > 1 ? balance * unprocessedForKnot / (4 ether - currentSlashedAmount)
                    : unprocessedForKnot;
                }
                break;
            }
        }

        return currentAccrued - claimedPerCollateralizedSlotOwnerOfKnot[_blsPubKey][_staker];
    }

    /// @notice Amount of ETH per free floating share that hasn't yet been allocated to each share
    function getUnprocessedETHForAllFreeFloatingSlot() public view returns (uint256) {
        return calculateETHForFreeFloatingOrCollateralizedHolders() - lastSeenETHPerFreeFloating;
    }

    /// @notice Amount of ETH per collateralized share that hasn't yet been allocated to each share
    function getUnprocessedETHForAllCollateralizedSlot() public view returns (uint256) {
        if (numberOfActiveKnots == 0) return 0;
        return ((calculateETHForFreeFloatingOrCollateralizedHolders() - lastSeenETHPerCollateralizedSlotPerKnot) / numberOfActiveKnots);
    }

    /// @notice New accumulated ETH per free floating share that hasn't yet been applied
    /// @dev The return value is scaled by 1e24
    function calculateNewAccumulatedETHPerFreeFloatingShare() public view returns (uint256) {
        uint256 ethSinceLastUpdate = getUnprocessedETHForAllFreeFloatingSlot();
        return _calculateNewAccumulatedETHPerFreeFloatingShare(ethSinceLastUpdate, true);
    }

    /// @notice New accumulated ETH per collateralized share per knot that hasn't yet been applied
    function calculateNewAccumulatedETHPerCollateralizedSharePerKnot() public view returns (uint256) {
        uint256 ethSinceLastUpdate = getUnprocessedETHForAllCollateralizedSlot();
        return accumulatedETHPerCollateralizedSlotPerKnot + ethSinceLastUpdate;
    }

    /// @notice Total amount of ETH received by the contract
    function totalETHReceived() public view returns (uint256) {
        return address(this).balance + totalClaimed;
    }

    /// @dev Internal logic for initializing the syndicate contract
    function _initialize(
        address _contractOwner,
        uint256 _priorityStakingEndBlock,
        address[] memory _priorityStakers,
        bytes[] memory _blsPubKeysForSyndicateKnots
    ) internal {
        // Transfer ownership from the deployer to the address specified as the owner
        _transferOwnership(_contractOwner);

        // Add the initial set of knots to the syndicate
        _registerKnotsToSyndicate(_blsPubKeysForSyndicateKnots);

        // Optionally process priority staking if the required params and array is configured
        if (_priorityStakingEndBlock > block.number) {
            priorityStakingEndBlock = _priorityStakingEndBlock;
            _addPriorityStakers(_priorityStakers);
        }

        emit ContractDeployed();
    }

    /// Given an amount of ETH allocated to the collateralized SLOT owners of a KNOT, distribute this amongs the current set of collateralized owners (a dynamic set of addresses and balances)
    function _updateCollateralizedSlotOwnersLiabilitySnapshot(bytes memory _blsPubKey) internal {
        // Establish how much new ETH is for the new KNOT
        uint256 unprocessedETHForCurrentKnot =
                    accumulatedETHPerCollateralizedSlotPerKnot - totalETHProcessedPerCollateralizedKnot[_blsPubKey];

        // Get information about the knot i.e. associated house and whether its active
        (address stakeHouse,,,,,bool isActive) = getStakeHouseUniverse().stakeHouseKnotInfo(_blsPubKey);

        // Assuming that there is unprocessed ETH and the knot is still part of the syndicate
        if (unprocessedETHForCurrentKnot > 0) {
            uint256 currentSlashedAmount = getSlotRegistry().currentSlashedAmountOfSLOTForKnot(_blsPubKey);

            // Don't allocate ETH when the current slashed amount is four. Syndicate will wait until ETH is topped up to claim revenue
            if (currentSlashedAmount < 4 ether) {
                // This copes with increasing numbers of collateralized slot owners and also copes with SLOT that has been slashed but not topped up
                uint256 numberOfCollateralisedSlotOwnersForKnot = getSlotRegistry().numberOfCollateralisedSlotOwnersForKnot(_blsPubKey);

                if (numberOfCollateralisedSlotOwnersForKnot == 1) {
                    // For only 1 collateralized SLOT owner, they get the full amount of unprocessed ETH for the knot
                    address collateralizedOwnerAtIndex = getSlotRegistry().getCollateralisedOwnerAtIndex(_blsPubKey, 0);
                    accruedEarningPerCollateralizedSlotOwnerOfKnot[_blsPubKey][collateralizedOwnerAtIndex] += unprocessedETHForCurrentKnot;
                } else {
                    for (uint256 i; i < numberOfCollateralisedSlotOwnersForKnot; ++i) {
                        address collateralizedOwnerAtIndex = getSlotRegistry().getCollateralisedOwnerAtIndex(_blsPubKey, i);
                        uint256 balance = getSlotRegistry().totalUserCollateralisedSLOTBalanceForKnot(
                            stakeHouse,
                            collateralizedOwnerAtIndex,
                            _blsPubKey
                        );

                        accruedEarningPerCollateralizedSlotOwnerOfKnot[_blsPubKey][collateralizedOwnerAtIndex] +=
                            balance * unprocessedETHForCurrentKnot / (4 ether - currentSlashedAmount);
                    }
                }

                // record so unprocessed goes to zero
                totalETHProcessedPerCollateralizedKnot[_blsPubKey] = accumulatedETHPerCollateralizedSlotPerKnot;
            }
        }

        // if the knot is no longer active, no further accrual of rewards are possible snapshots are possible but ETH accrued up to that point
        // Basically, under a rage quit or voluntary withdrawal from the beacon chain, the knot kick is auto-propagated to syndicate
        if (!isActive && !isNoLongerPartOfSyndicate[_blsPubKey]) {
            _deRegisterKnot(_blsPubKey);
        }
    }

    /// @dev Business logic for calculating per free floating share how much ETH from 1559 rewards is owed
    function _calculateNewAccumulatedETHPerFreeFloatingShare(uint256 _ethSinceLastUpdate, bool _previewFreeFloatingSharesToActivate) internal view returns (uint256) {
        uint256 sharesToActivate = _previewFreeFloatingSharesToActivate ? previewTotalFreeFloatingSharesToActivate() : 0;
        return (totalFreeFloatingShares + sharesToActivate) > 0 ? (_ethSinceLastUpdate * PRECISION) / (totalFreeFloatingShares + sharesToActivate) : 0;
    }

    /// @dev Business logic for adding a new set of knots to the syndicate for collecting revenue
    function _registerKnotsToSyndicate(bytes[] memory _blsPubKeysForSyndicateKnots) internal {
        uint256 knotsToRegister = _blsPubKeysForSyndicateKnots.length;
        if (knotsToRegister == 0) revert EmptyArray();

        for (uint256 i; i < knotsToRegister; ++i) {
            bytes memory blsPubKey = _blsPubKeysForSyndicateKnots[i];

            if (isKnotRegistered[blsPubKey]) revert KnotIsAlreadyRegistered();

            // Health check - if knot is inactive or slashed, should it really be part of the syndicate?
            // KNOTs closer to 32 effective at all times is the target
            (address stakeHouse,,,,,bool isActive) = getStakeHouseUniverse().stakeHouseKnotInfo(blsPubKey);
            if (!isActive) revert InactiveKnot();

            if (proposersToActivate.length > 0) {
                (address houseAddressForSyndicate,,,,,) = getStakeHouseUniverse().stakeHouseKnotInfo(proposersToActivate[0]);
                if (houseAddressForSyndicate != stakeHouse) revert KnotIsNotAssociatedWithAStakeHouse();
            }

            uint256 numberOfCollateralisedSlotOwnersForKnot = getSlotRegistry().numberOfCollateralisedSlotOwnersForKnot(blsPubKey);
            if (numberOfCollateralisedSlotOwnersForKnot < 1) revert InvalidNumberOfCollateralizedOwners();
            if (getSlotRegistry().currentSlashedAmountOfSLOTForKnot(blsPubKey) != 0) revert InvalidNumberOfCollateralizedOwners();

            isKnotRegistered[blsPubKey] = true;
            activationBlock[blsPubKey] = _computeNextActivationBlock();
            proposersToActivate.push(blsPubKey);
            emit KNOTRegistered(blsPubKey);
        }
    }

    /// @dev Business logic for adding priority stakers to the syndicate
    function _addPriorityStakers(address[] memory _priorityStakers) internal {
        uint256 numOfStakers = _priorityStakers.length;
        if (numOfStakers == 0) revert EmptyArray();
        for (uint256 i; i < numOfStakers; ++i) {
            address staker = _priorityStakers[i];

            if (isPriorityStaker[staker]) revert DuplicateArrayElements();

            isPriorityStaker[staker] = true;

            emit PriorityStakerRegistered(staker);
        }
    }

    /// @dev Business logic for de-registering a set of knots from the syndicate and doing the required snapshots to ensure historical earnings are preserved
    function _deRegisterKnots(bytes[] calldata _blsPublicKeys) internal {
        uint256 numOfKeys = _blsPublicKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        for (uint256 i; i < numOfKeys; ++i) {
            bytes memory blsPublicKey = _blsPublicKeys[i];

            // Execute the business logic for de-registering the single knot
            _deRegisterKnot(blsPublicKey);
        }
    }

    /// @dev Business logic for de-registering a specific knots assuming all accrued ETH has been processed
    function _deRegisterKnot(bytes memory _blsPublicKey) internal {
        if (!isKnotRegistered[_blsPublicKey]) revert KnotIsNotRegisteredWithSyndicate();
        if (isNoLongerPartOfSyndicate[_blsPublicKey]) revert KnotHasAlreadyBeenDeRegistered();

        // Update global system params before doing de-registration
        activateProposers();

        // We flag that the knot is no longer part of the syndicate
        isNoLongerPartOfSyndicate[_blsPublicKey] = true;

        // Do one final snapshot of ETH owed to the collateralized SLOT owners so they can claim later
        _updateCollateralizedSlotOwnersLiabilitySnapshot(_blsPublicKey);

        // For the free floating and collateralized SLOT of the knot, snapshot the accumulated ETH per share
        lastAccumulatedETHPerFreeFloatingShare[_blsPublicKey] = accumulatedETHPerFreeFloatingShare;

        // We need to reduce `totalFreeFloatingShares` in order to avoid further ETH accruing to shares of de-registered knot
        totalFreeFloatingShares -= sETHTotalStakeForKnot[_blsPublicKey];

        // Total number of registered knots with the syndicate reduces by one
        numberOfActiveKnots -= 1;

        emit KnotDeRegistered(_blsPublicKey);
    }

    /// @dev Work out the accumulated ETH per free floating share value that must be used for distributing ETH
    function _getCorrectAccumulatedETHPerFreeFloatingShareForBLSPublicKey(
        bytes memory _blsPublicKey
    ) internal view returns (uint256) {
        if (isNoLongerPartOfSyndicate[_blsPublicKey]) {
            return lastAccumulatedETHPerFreeFloatingShare[_blsPublicKey];
        }

        return accumulatedETHPerFreeFloatingShare;
    }

    /// @dev Business logic for allowing a free floating SLOT holder to claim their share of ETH
    function _claimAsStaker(address _recipient, bytes[] calldata _blsPubKeys) internal {
        uint256 numOfKeys = _blsPubKeys.length;
        if (numOfKeys == 0) revert EmptyArray();
        if (_recipient == address(0)) revert ZeroAddress();
        if (_recipient == address(this)) revert ZeroAddress();

        // Make sure we have the latest accrued information
        activateProposers();

        uint256 totalToTransfer;
        for (uint256 i; i < numOfKeys; ++i) {
            bytes memory _blsPubKey = _blsPubKeys[i];
            if (!isKnotRegistered[_blsPubKey]) revert KnotIsNotRegisteredWithSyndicate();
            if (block.number < activationBlock[_blsPubKey]) revert InactiveKnot();

            uint256 unclaimedUserShare = calculateUnclaimedFreeFloatingETHShare(_blsPubKey, msg.sender);

            // this means that user can call the funtion even if there is nothing to claim but the
            // worst that will happen is that they will just waste gas. this is needed for unstaking
            if (unclaimedUserShare > 0) {
                // Increase total claimed at the contract level
                totalClaimed += unclaimedUserShare;

                // Work out which accumulated ETH per free floating share value was used
                uint256 accumulatedETHPerShare = _getCorrectAccumulatedETHPerFreeFloatingShareForBLSPublicKey(_blsPubKey);

                // Update the total ETH claimed by the free floating SLOT holder based on their share of sETH
                sETHUserClaimForKnot[_blsPubKey][msg.sender] =
                (accumulatedETHPerShare * sETHStakedBalanceForKnot[_blsPubKey][msg.sender]) / PRECISION;

                // Calculate how much ETH to send to the user
                totalToTransfer += unclaimedUserShare;

                emit ETHClaimed(
                    _blsPubKey,
                    msg.sender,
                    _recipient,
                    unclaimedUserShare,
                    false
                );
            }
        }

        _transferETH(_recipient, totalToTransfer);
    }

    function _computeNextActivationBlock() internal view returns (uint256) {
        // As per ethereum spec, this is SLOT + 1 + 4 Epochs (4 * 32 = 128) - it is an approximation
        uint256 activationDistance = activationDistance > 0 ? activationDistance : 1 + 128;
        return block.number + activationDistance;
    }
}

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

error ZeroAddress();
error EmptyArray();
error InconsistentArrayLengths();
error InvalidBLSPubKey();
error InvalidNumberOfCollateralizedOwners();
error KnotSlashed();
error FreeFloatingStakeAmountTooSmall();
error KnotIsNotRegisteredWithSyndicate();
error NotPriorityStaker();
error KnotIsFullyStakedWithFreeFloatingSlotTokens();
error InvalidStakeAmount();
error KnotIsNotAssociatedWithAStakeHouse();
error UnableToStakeFreeFloatingSlot();
error NothingStaked();
error TransferFailed();
error NotCollateralizedOwnerAtIndex();
error InactiveKnot();
error DuplicateArrayElements();
error KnotIsAlreadyRegistered();
error KnotHasAlreadyBeenDeRegistered();
error NotKickedFromBeaconChain();

pragma solidity ^0.8.18;

// SPDX-License-Identifier: MIT

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { BeaconProxy } from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import { ISyndicateFactory } from "../interfaces/ISyndicateFactory.sol";
import { ISyndicateInit } from "../interfaces/ISyndicateInit.sol";
import { UpgradeableBeacon } from "../proxy/UpgradeableBeacon.sol";

/// @notice Contract for deploying a new KNOT syndicate
contract SyndicateFactory is ISyndicateFactory, Initializable {

    /// @notice Address of syndicate implementation that is cloned on each syndicate deployment
    address public syndicateImplementation;

    address public beacon;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() initializer {}

    /// @param _syndicateImpl Address of syndicate implementation that is cloned on each syndicate deployment
    function init(address _syndicateImpl, address _upgradeManager) external initializer {
        _init(_syndicateImpl, _upgradeManager);
    }

    function _init(address _syndicateImpl, address _upgradeManager) internal {
        syndicateImplementation = _syndicateImpl;
        beacon = address(new UpgradeableBeacon(syndicateImplementation, _upgradeManager));
    }

    /// @inheritdoc ISyndicateFactory
    function deploySyndicate(
        address _contractOwner,
        uint256 _priorityStakingEndBlock,
        address[] calldata _priorityStakers,
        bytes[] calldata _blsPubKeysForSyndicateKnots
    ) public override returns (address) {
        // Use CREATE2 to deploy the new instance of the syndicate
        bytes32 salt = calculateDeploymentSalt(msg.sender, _contractOwner, _blsPubKeysForSyndicateKnots.length);
        address newInstance = address(new BeaconProxy{salt: salt}(beacon, bytes("")));

        // Initialize the new syndicate instance with the params from the deployer
        ISyndicateInit(newInstance).initialize(
            _contractOwner,
            _priorityStakingEndBlock,
            _priorityStakers,
            _blsPubKeysForSyndicateKnots
        );

        // Off chain logging of all deployed instances from this factory
        emit SyndicateDeployed(newInstance);

        return newInstance;
    }

    /// @inheritdoc ISyndicateFactory
    function calculateSyndicateDeploymentAddress(
        address _deployer,
        address _contractOwner,
        uint256 _numberOfInitialKnots
    ) external override view returns (address) {
        bytes32 salt = calculateDeploymentSalt(_deployer, _contractOwner, _numberOfInitialKnots);
        return address(uint160(uint(keccak256(abi.encodePacked(
                bytes1(0xff),
                address(this),
                salt,
                keccak256(abi.encodePacked(
                    type(BeaconProxy).creationCode,
                    abi.encode(beacon, bytes("")) // <-- abi.encode the parameters
                ))
            )))));
    }

    /// @inheritdoc ISyndicateFactory
    function calculateDeploymentSalt(
        address _deployer,
        address _contractOwner,
        uint256 _numberOfInitialKnots
    ) public override pure returns (bytes32) {
        return keccak256(abi.encode(_deployer, _contractOwner, _numberOfInitialKnots));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

error FailedToTransfer();

/// @dev Contract that has the logic to take care of transferring ETH and can be overriden as needed
contract ETHTransferHelper {
    function _transferETH(address _recipient, uint256 _amount) internal virtual {
        if (_amount > 0) {
            (bool success,) = _recipient.call{value: _amount}("");
            if (!success) revert FailedToTransfer();
        }
    }
}