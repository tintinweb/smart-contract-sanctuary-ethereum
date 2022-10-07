// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IProgrammableMinter} from '../../interfaces/minters/IProgrammableMinter.sol';
import {ContractRegistrar} from '../govs/ContractRegistrar.sol';
import {IERC721} from '@openzeppelin/contracts/token/ERC721/IERC721.sol';


/**
 * @title TransferMinter
 * 
 * @author TheBards Protocol
 * 
 * @notice Minting in the form of transfering.
 */
contract TransferMinter is ContractRegistrar, IProgrammableMinter {

	constructor(
        address _hub
    ) {
        ContractRegistrar._initialize(_hub);
    }
	
    /// @inheritdoc IProgrammableMinter
	function mint(
		bytes memory metaData
	) 
		external 
		override
		returns (address, uint256)
	{	
		(
			address tokenContract,
			uint256 tokenId,
			address seller,
			address collector
        ) = abi.decode(
            metaData, 
            (address, uint256, address, address)
        );
		if (seller == collector){
			return (tokenContract, tokenId);
		}

		IERC721(tokenContract).safeTransferFrom(seller, collector, tokenId);
		return (tokenContract, tokenId);
	}
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @title IMinter
 * @author TheBards Protocol
 *
 * @notice This is the standard interface for all TheBards-compatible NFT minting modules.
 * Support any programmable NFT minting needs.
 */
interface IProgrammableMinter {

	/**
	 * @notice Mint programmable NFT.
	 * 
	 * @param metaData Meta data.
	 */
	function mint(
		bytes memory metaData
	) external returns (address, uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IContractRegistrar} from '../../interfaces/govs/IContractRegistrar.sol';
import {IBardsHub} from '../../interfaces/IBardsHub.sol';
import {Events} from '../../utils/Events.sol';
import {IBardsShareToken} from '../../interfaces/tokens/IBardsShareToken.sol';
import {IBardsCurationToken} from '../../interfaces/tokens/IBardsCurationToken.sol';
import {IBardsStaking} from '../../interfaces/tokens/IBardsStaking.sol';
import {IRewardsManager} from '../../interfaces/govs/IRewardsManager.sol';
import {IEpochManager} from '../../interfaces/govs/IEpochManager.sol';
import {IBardsDaoData} from '../../interfaces/govs/IBardsDaoData.sol';
import {IProgrammableMinter} from '../../interfaces/minters/IProgrammableMinter.sol';
import {IWETH} from '../trades/IWETH.sol';

/**
 * @title ContractRegistrar
 * 
 * @author TheBards Protocol
 * 
 * @notice This contract provides an interface to interact with the HUB.
 *
 * Inspired by Livepeer:
 * https://github.com/livepeer/protocol/blob/streamflow/contracts/Controller.sol
 */
abstract contract ContractRegistrar is IContractRegistrar {
	address internal HUB;
    mapping(bytes32 => address) private addressCache;

	modifier onlyHub() {
        require(msg.sender == HUB, "Only HUB can call");
        _;
    }

    modifier onlyGov(){
        require(msg.sender == bardsHub().getGovernance(), 'Only governance can call');
        _;
    }

    /**
     * @notice Initialize the controller.
     */
    function _initialize(address _HUB) internal {
        _setHub(_HUB);
    }

    /// @inheritdoc IContractRegistrar
    function setHub(address _HUB) external override onlyHub {
        _setHub(_HUB);
    }

    /**
     * @notice Set HUB.
     * @param _HUB Controller contract address
     */
    function _setHub(address _HUB) internal {
        require(_HUB != address(0), "HUB must be set");
        HUB = _HUB;
        emit Events.HUBSet(_HUB, block.timestamp);
    }

    /**
     * @notice Return IBardsHub interface.
     * @return IBardsHub contract registered with HUB
     */
    function bardsHub() internal view returns (IBardsHub) {
        return IBardsHub(HUB);
    }

    /**
     * @notice Return IWETH interface.
     * @return IWETH contract registered with HUB
     */
    function iWETH() internal view returns (IWETH) {
        return IWETH(_resolveContract(keccak256("WETH")));
    }

    /**
     * @notice Return BardsBardsDaoDataStaking interface.
     * @return BardsDaoData contract registered with HUB
     */
    function bardsDataDao() internal view returns (IBardsDaoData) {
        return IBardsDaoData(_resolveContract(keccak256("BardsDaoData")));
    } 

    /**
     * @notice Return BardsStaking interface.
     * @return BardsStaking contract registered with HUB
     */
    function bardsStaking() internal view returns (IBardsStaking) {
        return IBardsStaking(_resolveContract(keccak256("BardsStaking")));
    } 

    /**
     * @notice Return BardsCurationToken interface.
     * @return Bards Curation token contract registered with HUB
     */
    function bardsCurationToken() internal view returns (IBardsCurationToken) {
        return IBardsCurationToken(_resolveContract(keccak256("BardsCurationToken")));
    }

    /**
     * @notice Return RewardsManager interface.
     * 
     * @return Rewards manager contract registered with HUB
     */
    function rewardsManager() internal view returns (IRewardsManager) {
        return IRewardsManager(_resolveContract(keccak256("RewardsManager")));
    }

    /**
     * @notice Return EpochManager interface.
     * 
     * @return Epoch manager contract registered with HUB
     */
    function epochManager() internal view returns (IEpochManager) {
        return IEpochManager(_resolveContract(keccak256("EpochManager")));
    }

    /**
     * @notice Return transferMinter as default minter interface.
     * 
     * @return Transfer Minter contract registered with HUB
     */
    function defaultMinter() internal view returns (IProgrammableMinter) {
        return IProgrammableMinter(_resolveContract(keccak256("TransferMinter")));
    }

    /**
     * @notice Resolve a contract address from the cache or the HUB if not found.
     * @return Address of the contract
     */
    function _resolveContract(bytes32 _nameHash) internal view returns (address) {
        address contractAddress = addressCache[_nameHash];
        if (contractAddress == address(0)) {
            contractAddress = bardsHub().getContractAddressRegistered(_nameHash);
        }
        return contractAddress;
    }

    /**
     * @notice Cache a contract address from the HUB _registry.
     * @param _name Name of the contract to sync into the cache
     */
    function _syncContract(string memory _name) internal {
        bytes32 nameHash = keccak256(abi.encodePacked(_name));
        address contractAddress = bardsHub().getContractAddressRegistered(nameHash);
        if (addressCache[nameHash] != contractAddress) {
            addressCache[nameHash] = contractAddress;
            emit Events.ContractSynced(nameHash, contractAddress, block.timestamp);
        }
    }

    /**
     * @notice Sync protocol contract addresses from the HUB _registry.
     * This function will cache all the contracts using the latest addresses
     * Anyone can call the function whenever a contract change in the
     * HUB to ensure the protocol is using the latest version
     */
    function syncAllContracts() external {
        _syncContract("WETH");
        _syncContract("BardsDaoData");
        _syncContract("BardsStaking");
        _syncContract("BardsCurationToken");
        _syncContract("RewardsManager");
        _syncContract("EpochManager");
        _syncContract("TransferMinter");
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from './DataTypes.sol';

library Events {
    /**
     * @notice Emitted when the NFT contract's name and symbol are set at initialization.
     *
     * @param name The NFT name set.
     * @param symbol The NFT symbol set.
     * @param timestamp The current block timestamp.
     */
    event BaseInitialized(string name, string symbol, uint256 timestamp);

     /**
     * @notice Emitted when the hub state is set.
     *
     * @param caller The caller who set the state.
     * @param prevState The previous protocol state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param newState The newly set state, an enum of either `Paused`, `PublishingPaused` or `Unpaused`.
     * @param timestamp The current block timestamp.
     */
    event StateSet(
        address indexed caller,
        DataTypes.ProtocolState indexed prevState,
        DataTypes.ProtocolState indexed newState,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the governance address is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the governance address.
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event GovernanceSet(
        address indexed caller,
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a dispatcher is set for a specific profile.
     *
     * @param curationId The token ID of the curation for which the dispatcher is set.
     * @param dispatcher The dispatcher set for the given profile.
     * @param timestamp The current block timestamp.
     */
    event DispatcherSet(
        uint256 indexed curationId, 
        address indexed dispatcher, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when `theBards` set `operator` access.
     */
    event OperatorSet(
        address indexed theBards, 
        address indexed operator, 
        bool allowed, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when `curationId` set `allocationId` access.
     */
    event AllocationIdSet(
        uint256 curationId,
        uint256 allocationId,
        bytes curationMetaData,
        uint256 stakeToCuration,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the emergency admin is changed. We emit the caller even though it should be the previous
     * governance address, as we cannot guarantee this will always be the case due to upgradeability.
     *
     * @param caller The caller who set the emergency admin address.
     * @param oldEmergencyAdmin The previous emergency admin address.
     * @param newEmergencyAdmin The new emergency admin address set.
     * @param timestamp The current block timestamp.
     */
    event EmergencyAdminSet(
        address indexed caller,
        address indexed oldEmergencyAdmin,
        address indexed newEmergencyAdmin,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the cooldown blocks is updated.
     * @param oldCooldownBlocks The previous emergency admin address.
     * @param newCooldownBlocks The new emergency admin address set.
     * @param timestamp The current block timestamp.
     */
    event CooldownBlocksUpdated(
        uint32 indexed oldCooldownBlocks, 
        uint32 indexed newCooldownBlocks, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param curationBps The bps of curation.
     * @param timestamp The current block timestamp.
     */
    event CurationBpsUpdated(
        uint256 indexed tokenId, 
        uint32 curationBps, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param sellers The addressers of the sellers.
     * @param timestamp The current block timestamp.
     */
    event CurationSellersUpdated(
        uint256 indexed tokenId, 
        address[] sellers, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param sellerFundsRecipients The addresses where funds are sent after the trade.
     * @param timestamp The current block timestamp.
     */
    event CurationSellerFundsRecipientsUpdated(
        uint256 indexed tokenId, 
        address[] sellerFundsRecipients, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param curationFundsRecipients The curation Ids where funds are sent after the trade.
     * @param timestamp The current block timestamp.
     */
    event CurationFundsRecipientsUpdated(
        uint256 indexed tokenId, 
        uint256[] curationFundsRecipients, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param sellerFundsBpses The fee that is sent to the sellers.
     * @param timestamp The current block timestamp.
     */
    event CurationSellerFundsBpsesUpdated(
        uint256 indexed tokenId, 
        uint32[] sellerFundsBpses, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param curationFundsBpses The fee that is sent to the curations.
     * @param timestamp The current block timestamp.
     */
    event CurationFundsBpsesUpdated(
        uint256 indexed tokenId, 
        uint32[] curationFundsBpses, 
        uint256 timestamp
    );
   
    /**
     * @notice Emitted when the fee for a NFT is updated.
     * @param tokenId The token Id of a NFT.
     * @param stakingBps The bps of staking.
     * @param timestamp The current block timestamp.
     */
    event StakingBpsUpdated(
        uint256 indexed tokenId, 
        uint32 stakingBps, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when an curation is created.
     * @param tokenId The token Id of a NFT.
     * @param curationData The curation data.
     * @param timestamp The current block timestamp.
     */
    event CurationUpdated(
        uint256 indexed tokenId,
        bytes curationData,
        uint256 timestamp
    );

     /**
     * @notice Emitted when the Bards protocol treasury address is set.
     *
     * @param prevTreasury The previous treasury address.
     * @param newTreasury The new treasury address set.
     * @param timestamp The current block timestamp.
     */
    event ProtocolTreasurySet(
        address indexed prevTreasury,
        address indexed newTreasury,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the Bards protocol fee is set.
     *
     * @param prevProtocolFee The previous treasury fee in BPS.
     * @param newProtocolFee The new treasury fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event ProtocolFeeSet(
        uint32 indexed prevProtocolFee,
        uint32 indexed newProtocolFee,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the Bards protocol default curation fee is set.
     *
     * @param prevDefaultCurationBps The previous default curation fee in BPS.
     * @param newDefaultCurationBps The new default curation fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event DefaultCurationFeeSet(
        uint32 indexed prevDefaultCurationBps,
        uint32 indexed newDefaultCurationBps,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the Bards protocol default staking fee is set.
     *
     * @param prevDefaultStakingBps The previous default staking fee in BPS.
     * @param newDefaultStakingBps The new default staking fee in BPS.
     * @param timestamp The current block timestamp.
     */
    event DefaultStakingFeeSet(
        uint32 indexed prevDefaultStakingBps,
        uint32 indexed newDefaultStakingBps,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a currency is added to or removed from the Protocol fee whitelist.
     *
     * @param currency The currency address.
     * @param prevWhitelisted Whether or not the currency was previously whitelisted.
     * @param whitelisted Whether or not the currency is whitelisted.
     * @param timestamp The current block timestamp.
     */
    event ProtocolCurrencyWhitelisted(
        address indexed currency,
        bool indexed prevWhitelisted,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @notice Emitted when the Bards protocol governance address is set.
     *
     * @param prevGovernance The previous governance address.
     * @param newGovernance The new governance address set.
     * @param timestamp The current block timestamp.
     */
    event ProtocolGovernanceSet(
        address indexed prevGovernance,
        address indexed newGovernance,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a market module inheriting from the `MarketModuleBase` is constructed.
     *
     * @param stakingAddress The address of staking.
     * @param royaltyEngine The address of royaltyEngine.
     * @param timestamp The current block timestamp.
     */
    event MarketModuleBaseInitialized(
        address indexed stakingAddress,
        address indexed royaltyEngine,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a mint module is added to or removed from the whitelist.
     *
     * @param minterModule The address of the mint module.
     * @param whitelisted Whether or not the follow module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event MinterModuleWhitelisted(
        address indexed minterModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a market module is added to or removed from the whitelist.
     *
     * @param marketModule The address of the market module.
     * @param whitelisted Whether or not the follow module is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event MarketModuleWhitelisted(
        address indexed marketModule,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a a default profile is set for a wallet as its main identity
     *
     * @param wallet The wallet which set or unset its default profile.
     * @param profileId The token ID of the profile being set as default, or zero.
     * @param timestamp The current block timestamp.
     */
    event DefaultProfileSet(
        address indexed wallet, 
        uint256 indexed profileId, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when a profile is created.
     *
     * @param profileId The newly created profile's token ID.
     * @param creator The profile creator, who created the token with the given profile ID.
     * @param to The address receiving the profile with the given profile ID.
     * @param handle The handle set for the profile.
     * @param contentURI The content uri set for the profile.
     * @param marketModule The profile's newly set market module. This CAN be the zero address.
     * @param marketModuleReturnData The data returned from the market module's initialization. This is abi encoded
     * and totally depends on the market module chosen.
     * @param minterMarketModule The profile's newly set mint module. This CAN be the zero address.
     * @param minterMarketModuleReturnData The data returned from the mint module's initialization. This is abi encoded
     * and totally depends on the mint module chosen.
     * @param timestamp The current block timestamp.
     */
    event ProfileCreated(
        uint256 indexed profileId,
        address indexed creator,
        address indexed to,
        string handle,
        string contentURI,
        address marketModule,
        bytes marketModuleReturnData,
        address minterMarketModule,
        bytes minterMarketModuleReturnData,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a curation is created.
     *
     * @param profileId The newly created profile's token ID.
     * @param curationId The newly created curation's token ID.
     * @param contentURI The content uri set for the profile.
     * @param marketModule The profile's newly set market module. This CAN be the zero address.
     * @param marketModuleReturnData The data returned from the market module's initialization. This is abi encoded
     * and totally depends on the market module chosen.
     * @param minterMarketModule The profile's newly set mint module. This CAN be the zero address.
     * @param minterMarketModuleReturnData The data returned from the mint module's initialization. This is abi encoded
     * and totally depends on the mint module chosen.
     * @param timestamp The current block timestamp.
     */
    event CurationCreated(
        uint256 indexed profileId,
        uint256 indexed curationId,
        string contentURI,
        address marketModule,
        bytes marketModuleReturnData,
        address minterMarketModule,
        bytes minterMarketModuleReturnData,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a curation's market module is set.
     *
     * @param curationId The profile's token ID.
     * @param marketModule The profile's newly set follow module. This CAN be the zero address.
     * @param marketModuleReturnData The data returned from the follow module's initialization. This is abi encoded
     * and totally depends on the follow module chosen.
     * @param timestamp The current block timestamp.
     */
    event MarketModuleSet(
        uint256 indexed curationId,
        address marketModule,
        bytes marketModuleReturnData,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a curation's minter market module is set.
     *
     * @param curationId The profile's token ID.
     * @param minterMarketModule The profile's newly set follow module. This CAN be the zero address.
     * @param minterMarketModuleReturnData The data returned from the follow module's initialization. This is abi encoded
     * and totally depends on the follow module chosen.
     * @param timestamp The current block timestamp.
     */
    event MinterMarketModuleSet(
        uint256 indexed curationId,
        address minterMarketModule,
        bytes minterMarketModuleReturnData,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a profile creator is added to or removed from the whitelist.
     *
     * @param profileCreator The address of the profile creator.
     * @param whitelisted Whether or not the profile creator is being added to the whitelist.
     * @param timestamp The current block timestamp.
     */
    event ProfileCreatorWhitelisted(
        address indexed profileCreator,
        bool indexed whitelisted,
        uint256 timestamp
    );

    /**
     * @notice Emitted when royalties are paid
     * 
     * @param tokenContract The ERC-721 token address of the royalty payout
     * @param tokenId The ERC-721 token ID of the royalty payout
     * @param recipient The recipient address of the royalty
     * @param amount The amount paid to the recipient
     * @param timestamp The current block timestamp.
     */
    event RoyaltyPayout(
        address indexed tokenContract, 
        uint256 indexed tokenId, 
        address recipient, 
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when sell fee are paid
     * 
     * @param tokenContract The ERC-721 token address of the sell fee payout
     * @param tokenId The ERC-721 token ID of the sell fee payout
     * @param recipient The recipient address of the sell fee
     * @param amount The amount paid to the recipient
     * @param timestamp The current block timestamp.
     */
    event SellFeePayout(
        address indexed tokenContract, 
        uint256 indexed tokenId, 
        address recipient, 
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when curation fees are paid
     * 
     * @param tokenContract The ERC-721 token address of the curation fee payout
     * @param tokenId The ERC-721 token ID of the curation fee payout
     * @param amount The amount paid to the recipient
     * @param timestamp The current block timestamp.
     */
    event CurationFeePayout(
        address indexed tokenContract, 
        uint256 indexed tokenId,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when minters are added. 
     * 
     * @param account A minter address
     * @param timestamp The current block timestamp.
     */
    event MinterAdded(
        address indexed account, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when minters are removed.
     * 
     * @param account A minter address
     * @param timestamp The current block timestamp.
     */
    event MinterRemoved(
        address indexed account,
        uint256 timestamp
    );

    /**
     * @notice Emitted when defaultReserveRatio is setted.
     * 
     * @param prevDefaultReserveRatio The previous defaultReserveRatio.
     * @param newDefaultReserveRatio The new defaultReserveRatio.
     * @param timestamp The current block timestamp.
     */
    event DefaultReserveRatioSet(
        uint32 indexed prevDefaultReserveRatio,
        uint32 indexed newDefaultReserveRatio,
        uint256 timestamp
    );

    /**
     * @notice Emitted when newMinimumStaking is setted.
     * 
     * @param prevMinimumStaking The previous newMinimumStaking.
     * @param newMinimumStaking The new newMinimumStaking.
     * @param timestamp The current block timestamp.
     */
    event MinimumStakingSet(
        uint256 indexed prevMinimumStaking,
        uint256 indexed newMinimumStaking,
        uint256 timestamp
    );

    /**
     * @notice Emitted when stakingTaxPercentage is setted.
     * 
     * @param prevStakingTaxPercentage The previous stakingTaxPercentage.
     * @param newStakingTaxPercentage The new stakingTaxPercentage.
     * @param timestamp The current block timestamp.
     */
    event StakingTaxPercentageSet(
        uint32 indexed prevStakingTaxPercentage,
        uint32 indexed newStakingTaxPercentage,
        uint256 timestamp
    );

    /**
     * @notice Emitted when bardsShareTokenImpl is setted.
     * 
     * @param prevBardsShareTokenImpl The previous bardsShareTokenImpl.
     * @param newBardsShareTokenImpl The new bardsShareTokenImpl.
     * @param timestamp The current block timestamp.
     */
    event BardsShareTokenImplSet(
        address indexed prevBardsShareTokenImpl,
        address indexed newBardsShareTokenImpl,
        uint256 timestamp
    );

    /**
     * @notice Emitted when bardsCurationTokenImpl is setted.
     * 
     * @param prevBardsCurationTokenImpl The previous bardsCurationTokenImpl.
     * @param newBardsCurationTokenImpl The new bardsCurationTokenImpl.
     * @param timestamp The current block timestamp.
     */
    event BardsCurationTokenImplSet(
        address indexed prevBardsCurationTokenImpl,
        address indexed newBardsCurationTokenImpl,
        uint256 timestamp
    );

    /**
     * @notice Emitted when contract address update
     * 
     * @param id contract id
     * @param contractAddress contract Address
     * @param timestamp The current block timestamp.
     */
    event ContractRegistered(
        bytes32 indexed id, 
        address contractAddress,
        uint256 timestamp
    );

    /**
     * @notice Emitted when contract with `nameHash` is synced to `contractAddress`.
     * 
     * @param nameHash name Hash
     * @param contractAddress contract Address
     * @param timestamp The current block timestamp.
     */
    event ContractSynced(
        bytes32 indexed nameHash, 
        address contractAddress,
        uint256 timestamp
    );

    /**
     * @notice Emitted when hub setted
     * 
     * @param hub the hub address.
     * @param timestamp The current block timestamp.
     */
    event HUBSet(
        address indexed hub,
        uint256 timestamp
    );

    /**
     * @notice Emitted when BardsDaoData setted
     * 
     * @param bardsDaoData the hub address.
     * @param timestamp The current block timestamp.
     */
    event BardsDaoDataSet(
        address indexed bardsDaoData,
        uint256 timestamp
    );

    /**
     * @notice Emitted when epoch run
     * 
     * @param epoch epoch 
     * @param caller epoch
     * @param timestamp The current block timestamp.
     */
    event EpochRun(
        uint256 indexed epoch, 
        address caller,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a curation's URI is set.
     *
     * @param curationId The token ID of the curation for which the URI is set.
     * @param contentURI The URI set for the given profile.
     * @param timestamp The current block timestamp.
     */
    event CurationContentURISet(
        uint256 indexed curationId, 
        string contentURI, 
        uint256 timestamp
    );

    /**
     * @notice Emitted when epoch length updated
     * 
     * @param epoch epoch
     * @param epochLength epoch length
     * @param timestamp The current block timestamp.
     */
    event EpochLengthUpdate(
        uint256 indexed epoch, 
        uint256 epochLength,
        uint256 timestamp
    );

    /**
     * @notice Emitted when rewards are assigned to a curation.
     */
    event RewardsAssigned(
        uint256 indexed curationId,
        uint256 indexed allocationId,
        uint256 epoch,
        uint256 amount,
        uint256 timestamp
    );

    /**
     * @notice Emitted when rewards are denied to a curation.
     */
    event RewardsDenied(
        uint256 indexed curationId, 
        uint256 indexed allocationId, 
        uint256 epoch,
        uint256 timestamp
    );

    /**
     * @notice Emitted when a curation is denied for claiming rewards.
     */
    event RewardsDenylistUpdated(
        uint256 indexed curationId, 
        uint256 sinceBlock,
        uint256 timestamp
    );

    /**
     * @notice Emitted when IssuanceRate update
     * 
     * @param prevIssuanceRate The preivous issuance rate of BCT token.
     * @param newIssuanceRate The new issuance rate of BCT token.
     * @param timestamp The current block timestamp.
     */
    event IssuanceRateSet(
        uint256 prevIssuanceRate,
        uint256 newIssuanceRate,
        uint256 timestamp
    );

    /**
     * @notice Emitted when TargetBondingRate update
     * 
     * @param prevTargetBondingRate The preivous target bonding rate of BCT token.
     * @param newTargetBondingRate The new target bonding rate of BCT token.
     * @param timestamp The current block timestamp.
     */
    event TargetBondingRateSet(
        uint256 prevTargetBondingRate,
        uint256 newTargetBondingRate,
        uint256 timestamp
    );

    /**
     * @notice Emitted when InflationChange update
     * 
     * @param prevInflationChange The preivous inflation Change of BCT token.
     * @param newInflationChange The new inflation Change of BCT token.
     * @param timestamp The current block timestamp.
     */
    event InflationChangeSet(
        uint256 prevInflationChange,
        uint256 newInflationChange,
        uint256 timestamp
    );

    /**
     * @notice Emitted when MinimumStakeingToken update
     * 
     * @param prevMinimumStakeingToken The previous Minimum amount of tokens on a curation required to accrue rewards.
     * @param newMinimumStakeingToken The New minimum amount of tokens on a curation required to accrue rewards.
     * @param timestamp The current block timestamp.
     */
    event MinimumStakeingTokenSet(
        uint256 prevMinimumStakeingToken,
        uint256 newMinimumStakeingToken,
        uint256 timestamp
    );

    /**
     * @notice Emitted when ThawingPeriod update
     * 
     * @param prevThawingPeriod The previous Period in blocks to wait for token withdrawals after unstaking
     * @param newThawingPeriod The new Period in blocks to wait for token withdrawals after unstaking
     * @param timestamp The current block timestamp.
     */
    event ThawingPeriodSet(
        uint32 prevThawingPeriod,
        uint32 newThawingPeriod,
        uint256 timestamp
    );

    /**
     * @notice Emitted when ThawingPeriod update
     * 
     * @param prevChannelDisputeEpochs The previous Period in blocks to wait for token withdrawals after unstaking
     * @param newChannelDisputeEpochs The new Period in blocks to wait for token withdrawals after unstaking
     * @param timestamp The current block timestamp.
     */
    event ChannelDisputeEpochsSet(
        uint32 prevChannelDisputeEpochs,
        uint32 newChannelDisputeEpochs,
        uint256 timestamp
    );

    /**
     * @notice Emitted when stakingAddress update
     * 
     * @param prevStakingAddress The previous stakingAddress
     * @param newStakingAddress The new stakingAddress
     * @param timestamp The current block timestamp.
     */
    event StakingAddressSet(
        address prevStakingAddress,
        address newStakingAddress,
        uint256 timestamp
    );

    /**
     * @notice Emitted when ReserveRatio update
     * 
     * @param prevStakingReserveRatio The previous prevStakingReserveRatio.
     * @param newStakingReserveRatio The new newStakingReserveRatio.
     * @param timestamp The current block timestamp.
     */
    event DefaultStakingReserveRatioSet(
        uint32 prevStakingReserveRatio,
        uint32 newStakingReserveRatio,
        uint256 timestamp
    );

    /**
     * @notice Emitted when RebateRatio update
     * 
     * @param alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param alphaDenominator Denominator of `alpha` in the cobb-douglas function
     * @param timestamp The current block timestamp.
     */
    event RebateRatioSet(
        uint32 alphaNumerator,
        uint32 alphaDenominator,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `delegator` deposited `tokens` on `curationId` as share.
     * The `delegator` receives `share` amount according to the pool bonding curve.
     * An amount of `stakingTax` will be collected and burned.
     */
    event CurationPoolStaked(
        address indexed delegator,
        uint256 indexed curationId,
        uint256 tokens,
        uint256 shares,
        uint256 stakingTax,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `delegator` undelegated `tokens` from `curationId`.
     * Tokens get locked for withdrawal after a period of time.
     * 
     * @param delegator delegator
     * @param curationId Curation Id
     * @param shares shares to be burnt
     * @param tokens tokens to be locked
     * @param until A time tokens unlock for withdrawal.
     * @param timestamp The current block timestamp.
     */
    event StakeDelegatedLocked(
        address indexed delegator,
        uint256 indexed curationId,
        uint256 shares,
        uint256 tokens,
        uint256 until,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `delegator` withdrew delegated `tokens` from `curationId`.
     * 
     * @param curationId Curation Id
     * @param delegator delegator
     * @param tokens Amount of tokens withdrawn.
     * @param timestamp The current block timestamp.
     */
    event StakeDelegatedWithdrawn(
        uint256 indexed curationId,
        address indexed delegator,
        uint256 tokens,
        uint256 timestamp
    );

    /**
     * @notice Emitted when hub allocated `tokens` amount to `curationId`
     * during `epoch`.
     * `allocationId` indexer derived address used to identify the allocation.
     */
    event AllocationCreated(
        uint256 indexed curationId,
        uint256 indexed allocationId,
        uint256 epoch,
        uint256 timestamp
    );

    /**
     * @notice Emitted when hub close an allocation in `epoch` for `curationId`.
     * An amount of `tokens` get unallocated from `curationId`.
     * The `effectiveAllocation` are the tokens allocated from creation to closing.
     */
    event AllocationClosed(
        uint256 indexed curationId,
        uint256 epoch,
        uint256 tokens,
        uint256 indexed allocationId,
        uint256 effectiveAllocationStake,
        address sender,
        uint256 stakeToCuration,
        bool isCurator,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `curator` claimed a rebate on `curationId` during `epoch`
     * related to the `forEpoch` rebate pool.
     * The rebate is for `tokens` amount and `unclaimedAllocationsCount` are left for claim
     * in the rebate pool. `delegationFees` collected and sent to delegation pool.
     */
    event RebateClaimed(
        uint256 indexed curationId,
        uint256 indexed allocationId,
        address currency,
        uint256 epoch,
        uint256 forEpoch,
        uint256 tokens,
        uint256 unclaimedAllocationsCount,
        uint256 delegationFees,
        uint256 timestamp
    );

    /**
     * @notice Emitted when `indexer` collected `tokens` amount in `epoch` for `allocationId`.
     * These funds are related to `curationId`.
     * The `from` value is the sender of the collected funds.
     */
    event AllocationCollected(
        uint256 indexed curationId,
        uint256 epoch,
        uint256 tokens,
        uint256 indexed allocationId,
        address from,
        address currency,
        uint256 timestamp
    );

    /**
     * @notice Emitted upon a successful collect action.
     *
     * @param collector The address collecting the NFT.
     * @param curationId The token ID of the curation.
     * @param tokenContractPointed The address of the NFT contract whose NFT is being collected.
     * @param tokenIdPointed The token ID of NFT being collected.
     * @param collectModuleData The data passed to the collect module.
     * @param timestamp The current block timestamp.
     */
    event Collected(
        address indexed collector,
        uint256 indexed curationId,
        address tokenContractPointed,
        uint256 tokenIdPointed,
        bytes collectModuleData,
        uint256 timestamp
    );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from '../utils/DataTypes.sol';

/**
 * @title IBardsHub
 * @author TheBards Protocol
 * 
 * @notice This is the interface for the TheBards contract, the main entry point for the TheBards Protocol.
 */
interface IBardsHub {

	// -- Governance --

	/**
     * @notice Initializes the TheBards NFT, setting the initial governance address as well as the name and symbol in
     * the BardsNFTBase contract.
     *
     * @param name The name to set for the hub NFT.
     * @param symbol The symbol to set for the hub NFT.
     * @param newGovernance The governance address to set.
     * @param cooldownBlocks Number of blocks to set the curation parameters cooldown period
     */
    function initialize(
        string calldata name,
        string calldata symbol,
        address newGovernance,
        uint32 cooldownBlocks
    ) external;

    /**
     * @notice Sets the privileged governance role. This function can only be called by the current governance
     * address.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) 
		  external;

    /**
     * @notice Sets the emergency admin, which is a permissioned role able to set the protocol state. This function
     * can only be called by the governance address.
     *
     * @param newEmergencyAdmin The new emergency admin address to set.
     */
    function setEmergencyAdmin(address newEmergencyAdmin) 
		  external;

    /**
     * @notice Set the time in blocks an curator needs to wait to change curation parameters.
     * @param _blocks Number of blocks to set the curation parameters cooldown period
     */
    function setCooldownBlocks(uint32 _blocks) 
		  external;

	/**
     * @notice Sets the protocol state to either a global pause, a publishing pause or an unpaused state. This function
     * can only be called by the governance address or the emergency admin address.
     *
     * Note that this reverts if the emergency admin calls it if:
     *      1. The emergency admin is attempting to unpause.
     *      2. The emergency admin is calling while the protocol is already paused.
     *
     *   ########################################################
     *   ##                 Unpaused | Paused | CurationPaused ##
     *   ## governance     |   yes   |   yes  |      yes       ##
     *   ## emergency admin|   no    |   yes  |      yes       ##
     *   ## other          |   no    |   no   |      no        ##
     *   ########################################################
     *
     * @param newState The state to set, as a member of the ProtocolState enum.
     */
    function setState(DataTypes.ProtocolState newState) 
		external;

    /**
    * @notice Updates a curation with the specified parameters. 
    */
	  function updateCuration(DataTypes.InitializeCurationData memory _vars) external;

    // /**
    //  * @notice Sets the sellerFundsRecipients of the sellers for a NFT
    //  * 
    //  * @param tokenId The token Id of the NFT to set fee params.
    //  * @param sellerFundsRecipients The bpses of seller funds
    //  */
    // function setSellerFundsRecipientsParams(uint256 tokenId, address[] calldata sellerFundsRecipients) external;

    // /**
    //  * @notice Sets the curationFundsRecipients of the sellers for a NFT
    //  * 
    //  * @param tokenId The token Id of the NFT to set fee params.
    //  * @param curationFundsRecipients The bpses of curation funds
    //  */
    // function setCurationFundsRecipientsParams(uint256 tokenId, uint256[] calldata curationFundsRecipients) external;


  //   /**
  //    * @notice Sets the fee that is sent to the sellers for a NFT
  //    * 
  //    * @param tokenId The token Id of the NFT to set fee params.
  //    * @param sellerFundsBpses The fee that is sent to the sellers.
  //    */
  //   function setSellerFundsBpsesParams(uint256 tokenId, uint32[] calldata sellerFundsBpses) external;

  //   /**
  //    * @notice Sets the fee that is sent to the curation for a NFT
  //    * 
  //    * @param tokenId The token Id of the NFT to set fee params.
  //    * @param curationFundsBpses The fee that is sent to the curations.
  //    */
  //   function setCurationFundsBpsesParams(uint256 tokenId, uint32[] calldata curationFundsBpses) external;

	// /**
  //    * @notice Sets fee parameters for a NFT
	//  *
  //    * @param tokenId The token Id of the NFT to set fee params.
  //    * @param curationBps The bps of curation
  //    * @param stakingBps The bps of staking
  //    */
  //   function setBpsParams(uint256 tokenId, uint32 curationBps, uint32 stakingBps) external;

	/**
     * @notice Adds or removes a market module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param marketModule The market module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the market module should be whitelisted.
     */
    function whitelistMarketModule(address marketModule, bool whitelist) 
		external;

  	/**
     * @notice Adds or removes a mint module from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param minterModule The mint module contract address to add or remove from the whitelist.
     * @param whitelist Whether or not the mint module should be whitelisted.
     */
    function whitelistMinterModule(address minterModule, bool whitelist) 
		external;

	/**
     * @notice Adds or removes a profile creator from the whitelist. This function can only be called by the current
     * governance address.
     *
     * @param profileCreator The profile creator address to add or remove from the whitelist.
     * @param whitelist Whether or not the profile creator should be whitelisted.
     */
    function whitelistProfileCreator(address profileCreator, bool whitelist) 
		external;

	// -- Registry --

    /**
     * @notice Register contract id and mapped address
     * @param _id Contract id (keccak256 hash of contract name)
     * @param _contractAddress Contract address
     */
    function registerContract(bytes32 _id, address _contractAddress) external;

    /**
     * @notice Unregister a contract address
     * @param _id Contract id (keccak256 hash of contract name)
     */
    function unsetContract(bytes32 _id) external;

    /**
     * @notice Get contract registered address by its id
     * @param _id Contract id
     */
    function getContractAddressRegistered(bytes32 _id) external view returns (address);

	// -- Pausing --

	// -- Epoch Manage --

	// -- Reward Manage --

	// -- cruation funtions --
	/**
     * @notice Creates a profile with the specified parameters, minting a self curation as NFT to the given recipient.
     *
     * @param vars A CreateCurationData struct containing the needed parameters.
     *
     * @return uint256 An integer representing the profile's token ID.
     */
    function createProfile(DataTypes.CreateCurationData calldata vars) 
		external 
		returns (uint256);

    // /**
    //  * @notice Creates a profile with the specified parameterse via signature with the specified parameters.
    //  *
    //  * @param vars A CreateCurationWithSigData struct containing the regular parameters and an EIP712Signature struct.
    //  *
    //  * @return uint256 An integer representing the profile's token ID.
    //  */
    // function createProfileWithSig(DataTypes.CreateCurationWithSigData calldata vars) 
    // external 
    // returns (uint256);

    /**
     * @notice Sets the mapping between wallet and its main profile identity.
     *
     * @param profileId The token ID of the profile to set as the main profile identity.
     */
    function setDefaultProfile(uint256 profileId) 
		external;

    /**
     * @notice Sets the mapping between curation Id and its allocation ID.
     *
     * @param vars A SetAllocationIdData struct, including the regular parameters
     */
    function setAllocationId(DataTypes.SetAllocationIdData calldata vars) 
		external;

    /**
     * @notice Sets the mapping between curation Id and its allocation ID via signature with the specified parameters.
     *
     * @param vars A SetAllocationIdWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setAllocationIdWithSig(DataTypes.SetAllocationIdWithSigData calldata vars) 
		external;

    /**
     * @notice Sets the mapping between wallet and its main profile identity via signature with the specified parameters.
     *
     * @param vars A SetDefaultProfileWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setDefaultProfileWithSig(DataTypes.SetDefaultProfileWithSigData calldata vars)
        external;

    /**
     * @notice Sets a curation's content URI.
     *
     * @param curationId The token ID of the curation to set the URI for.
     * @param contentURI The URI to set for the given curation.
     */
    function setCurationContentURI(uint256 curationId, string calldata contentURI) external;

    /**
     * @notice Sets a curation's content URI via signature with the specified parameters.
     *
     * @param vars A SetCurationContentURIWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setCurationContentURIWithSig(DataTypes.SetCurationContentURIWithSigData calldata vars)
        external;

	    /**
     * @notice Sets a curation's market module, must be called by the curator.
     *
     * @param vars The SetMarketModuleData struct containing the following parameters:
     *   curationId The token ID of the profile to set the market module for.
     *   tokenContract The address of NFT token to curate.
     *   tokenId The NFT token ID to curate.
     *   marketModule The market module to set for the given curation, must be whitelisted.
     *   marketModuleInitData The data to be passed to the market module for initialization.
     */
    function setMarketModule( 
        DataTypes.SetMarketModuleData calldata vars
    ) external;

    /**
     * @notice Sets a curation's market module via signature with the specified parameters.
     *
     * @param vars A SetMarketModuleWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setMarketModuleWithSig(DataTypes.SetMarketModuleWithSigData calldata vars) 
		external;

	    /**
     * @notice Sets a curation's mint module, must be called by the curator.
     *
     * @param vars The SetMarketModuleData struct containing the following parameters:
     *   curationId The token ID of the profile to set the mint module for.
     *   tokenContract The address of NFT token to curate.
     *   tokenId The NFT token ID to curate.
     *   marketModule The mint module to set for the given curation, must be whitelisted.
     *   marketModuleInitData The data to be passed to the mint module for initialization.
     */
    function setMinterMarketModule( 
        DataTypes.SetMarketModuleData calldata vars
    ) external;

    /**
     * @notice Sets a curation's mint module via signature with the specified parameters.
     *
     * @param vars A SetMarketModuleWithSigData struct, including the regular parameters and an EIP712Signature struct.
     */
    function setMinterMarketModuleWithSig(DataTypes.SetMarketModuleWithSigData calldata vars) 
		external;

    /**
     * @notice Creates a curation to a given profile, must be called by the profile owner.
     *
     * @param vars A CreateCurationData struct containing the needed parameters.
     *
     * @return uint256 An integer representing the curation's token ID.
     */
    function createCuration(DataTypes.CreateCurationData calldata vars) external returns (uint256);

    /**
     * @notice Adds or removes a currency from the whitelist. This function can only be called by governance.
     *
     * @param currency The currency to add or remove from the whitelist.
     * @param toWhitelist Whether to add or remove the currency from the whitelist.
     */
    function whitelistCurrency(address currency, bool toWhitelist) external;

    /**
     * @notice Creates a curation via signature with the specified parameters.
     *
     * @param vars A CreateCurationWithSigData struct containing the regular parameters and an EIP712Signature struct.
     *
     * @return uint256 An integer representing the curation's token ID.
     */
    function createCurationWithSig(
      DataTypes.CreateCurationWithSigData calldata vars
    ) external returns (uint256);

    /**
     * @notice Collects a given curation, executing market module logic and transfering curation to the caller.
     *
     * @param vars A SimpleDoCollectData struct containing the regular parameters as well as the collector's address and
     * an EIP712Signature struct.
     *
     * @return (addresss, uint256) An  address and integer pair representing the minted token ID.
     */
    function collect(
      DataTypes.SimpleDoCollectData calldata vars
    ) external returns (address, uint256);

    /**
     * @notice Collects a given curation via signature with the specified parameters.
     *
     * @param vars A CollectWithSigData struct containing the regular parameters as well as the collector's address and
     * an EIP712Signature struct.
     *
     * @return (addresss, uint256) An  address and integer pair representing the minted token ID.
     */
    function collectWithSig(
      DataTypes.DoCollectWithSigData calldata vars
    ) external returns (address, uint256);

    /// ************************
    /// *****VIEW FUNCTIONS*****
    /// ************************

    /**
     * @notice Returns whether `spender` is allowed to manage things for `curator`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     * 
     * @param operator The address of operator
     * @param curator The address of curation.
     */
    function isAuthForCurator(address operator, address curator)
      external
      view
      returns (bool);

    /**
     * @notice Returns whether or not a profile creator is whitelisted.
     *
     * @param profileCreator The address of the profile creator to check.
     *
     * @return bool True if the profile creator is whitelisted, false otherwise.
     */
    function isProfileCreatorWhitelisted(address profileCreator) 
		external 
		view 
		returns (bool);

    /**
     * @notice Returns default profile for a given wallet address
     *
     * @param wallet The address to find the default mapping
     *
     * @return uint256 The default profile id, which will be 0 if not mapped.
     */
    function defaultProfile(address wallet) 
		external 
		view 
		returns (uint256);

    /**
     * @notice Returns whether or not a market module is whitelisted.
     *
     * @param marketModule The address of the market module to check.
     *
     * @return bool True if the the market module is whitelisted, false otherwise.
     */
    function isMarketModuleWhitelisted(address marketModule) 
		external 
		view 
		returns (bool);

    /**
     * @notice Returns whether or not a mint module is whitelisted.
     *
     * @param minterModule The address of the mint module to check.
     *
     * @return bool True if the the mint module is whitelisted, false otherwise.
     */
    function isMinterModuleWhitelisted(address minterModule) 
		external 
		view 
		returns (bool);

    /**
     * @notice Returns whether a currency is whitelisted.
     *
     * @param currency The currency to query the whitelist for.
     *
     * @return bool True if the queried currency is whitelisted, false otherwise.
     */
    function isCurrencyWhitelisted(address currency) external view returns (bool);

    /**
     * @notice Returns the currently configured governance address.
     *
     * @return address The address of the currently configured governance.
     */
    function getGovernance() 
		external 
		view 
		returns (address);
    
	/**
     * @notice Returns the market module associated with a given curation.
     *
     * @param curationId The token ID of the profile that published the curation to query.
     *
     * @return address The address of the market module associated with the queried curation.
     */
    function getMarketModule(uint256 curationId) 
		external 
		view 
		returns (address);

	/**
     * @notice Returns the minter market module associated with a given curation.
     *
     * @param curationId The token ID of the profile that published the curation to query.
     *
     * @return address The address of the mint module associated with the queried curation.
     */
    function getMinterMarketModule(uint256 curationId) 
		external 
		view 
		returns (address);

	/**
     * @notice Returns the handle associated with a profile.
     *
     * @param profileId The token ID of the profile to query the handle for.
     *
     * @return string The handle associated with the profile.
     */
    function getHandle(uint256 profileId) 
		external 
		view 
		returns (string memory);

	    /**
     * @notice Returns the URI associated with a given curation.
     *
     * @param curationId The token ID of the curation to query.
     *
     * @return string The URI associated with a given publication.
     */
    function getContentURI(uint256 curationId) 
		external 
		view 
		returns (string memory);

    /**
     * @notice Returns the profile token ID according to a given handle.
     *
     * @param handle The handle to resolve the profile token ID with.
     *
     * @return uint256 The profile ID the passed handle points to.
     */
    function getProfileIdByHandle(string calldata handle) 
		external 
		view 
		returns (uint256);

    /**
     * @notice Returns the full profile struct associated with a given profile token ID.
     *
     * @param profileId The token ID of the profile to query.
     *
     * @return ProfileStruct The profile struct of the given profile.
     */
    function getProfile(uint256 profileId) 
		external 
		view 
		returns (DataTypes.CurationStruct memory);

    /**
     * @notice Returns the full curationId struct.
     *
     * @param curationId The token ID of the curation to query.
     *
     * @return CurationStruct The curation struct associated with the queried curation.
     */
    function getCuration(uint256 curationId)
        external
        view
        returns (DataTypes.CurationStruct memory);

    /**
     * @notice Returns the allocation Id.
     *
     * @param curationId The token ID of the curation to query.
     *
     * @return allocationId The allocation ID associated with the queried curation.
     */
    function getAllocationIdById(uint256 curationId)
        external
        view
        returns (uint256);

    /**
     * @notice remove allocations in _isToBeClaimedByAllocByCurator.
     */
    function removeAllocation(
        address curator, 
        uint256 allocationId
    ) external;

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IContractRegistrar {
	/**
     * @notice Set HUB
     * @param _HUB HUB contract address
     */
	function setHub(address _HUB) external;
	
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";

/**
 * @title IBardsShareToken
 * @author TheBards Protocol
 * 
 * @notice This is the interface for the BardsShareToken contract.
 */
interface IBardsShareToken is IERC20Upgradeable {

    /**
     * @notice Bards Share Token Contract initializer.
     */
    function initialize() external;

    /**
     * @dev Burn tokens from an address.
     * @param _account Address from where tokens will be burned
     * @param _amount Amount of tokens to burn
     */
	function burnFrom(address _account, uint256 _amount) external;

	/**
     * @dev Mint new tokens.
     * @param _to Address to send the newly minted tokens
     * @param _amount Amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external;
	
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

/**
 * @title RewardManager Interface
 * 
 * @author Thebards Protocol
 * 
 * @notice The interface of RewardManager contract.
 */
interface IRewardsManager {

    /**
     * @notice Initializes the governance, treasury, treasury fee, default curation fee, and default staking fee amounts.
     *
     * @param _HUB The address of HUB
     * @param _issuanceRate The issuance rate
     * @param _inflationChange The issuance change
     * @param _targetBondingRate The target bonding rate
     */
    function initialize(
        address _HUB,
        uint256 _issuanceRate,
        uint256 _inflationChange,
        uint256 _targetBondingRate
    ) external;

	// -- Config --

	  /**
     * @notice Sets the issuance rate.
     * The issuance rate is defined as a percentage increase of the total supply per block.
     * This means that it needs to be greater than 1.0, any number under 1.0 is not
     * allowed and an issuance rate of 1.0 means no issuance.
     * To accommodate a high precision the issuance rate is expressed in wei.
     * @param _issuanceRate Issuance rate expressed in wei
     */
    function setIssuanceRate(
        uint256 _issuanceRate
    ) external;


    /**
     * @notice Set inflationChange. Only callable by gov
     * @param _inflationChange Inflation change as a percentage of total token supply
     */
    function setInflationChange(
        uint256 _inflationChange
    ) external;

    /**
     * @notice Set targetBondingRate. Only callable by gov
     * @param _targetBondingRate Target bonding rate as a percentage of total bonded tokens / total token supply
     */
    function setTargetBondingRate(
        uint256 _targetBondingRate
    ) external;

	  /**
     * @notice Sets the minimum staked tokens on a curation to start accruing rewards.
     * Can be set to zero which means that this feature is not being used.
     * @param _minimumStakeingToken Minimum signaled tokens
     */
    function setMinimumStakingToken(
        uint256 _minimumStakeingToken
    ) external;

    /**
     * @notice Denies to claim rewards for a curation.
     * @param _curationId curation ID
     * @param _deny Whether to set the curation as denied for claiming rewards or not
     */
    function setDenied(
        uint256 _curationId, 
        bool _deny
    ) external;

    /**
     * @notice Denies to claim rewards for multiple curations.
     * @param _curationIds Array of curation ID
     * @param _deny Array of denied status for claiming rewards for each curation
     */
    function setDeniedMany(
        uint256[] calldata _curationIds, 
        bool[] calldata _deny
    ) external;

    /**
     * @notice Tells if curation is in deny list
     * @param _curationId Curation ID to check
     * @return Whether the curation is denied for claiming rewards or not
     */
    function isDenied(
        uint256 _curationId
    ) 
      external 
      view 
      returns (bool);

	/**
     * @notice Gets the issuance of rewards per staking since last updated.
     *
     * Compound interest formula: `a = p(1 + r/n)^nt`
     * The formula is simplified with `n = 1` as we apply the interest once every time step.
     * The `r` is passed with +1 included. So for 10% instead of 0.1 it is 1.1
     * The simplified formula is `a = p * r^t`
     *
     * Notation:
     * t: time steps are in blocks since last updated
     * p: total supply of BCT tokens
     * a: inflated amount of total supply for the period `t` when interest `r` is applied
     * x: newly accrued rewards token for the period `t`
     *
     * @return newly accrued rewards per signal since last update
     */
    function getNewRewardsPerStaking() 
        external 
        view 
        returns (uint256);

    /**
     * @notice Gets the currently accumulated rewards per staking.
     * @return Currently accumulated rewards per staking
     */
    function getAccRewardsPerStaking() 
        external 
        view 
        returns (uint256);

    /**
     * @notice Gets the accumulated rewards for the curation.
     * @param _curationId Curation Id
     * @return Accumulated rewards for curation
     */
    function getAccRewardsForCuration(
        uint256 _curationId
    )
        external
        view
        returns (uint256);

    /**
     * @notice Gets the accumulated rewards per allocated token for the curation.
     * @param _curationId Curation Id
     * @return Accumulated rewards per allocated token for the curation
     * @return Accumulated rewards for curation
     */
    function getAccRewardsPerAllocatedToken(
        uint256 _curationId
    )
        external
        view
        returns (uint256, uint256);

    /**
     * @dev Calculate current rewards for a given allocation on demand.
     * @param _allocationId Allocation
     * @return Rewards amount for an allocation
     */
    function getRewards(
        uint256 _allocationId
    ) 
      external 
      view 
      returns (uint256);

    /**
     * @notice Updates the accumulated rewards per staking and save checkpoint block number.
     * Must be called before `issuanceRate` or `total staked BCT` changes
     * Called from the BardsStaking contract on mint() and burn()
     * @return Accumulated rewards per staking
     */
    function updateAccRewardsPerStaking() 
        external 
        returns (uint256);

    /**
     * Set IssuanceRate based upon the current bonding rate and target bonding rate
     */
    function onUpdateIssuanceRate() external;

    /**
     * @notice Pull rewards from the contract for a particular allocation.
     * This function can only be called by the BardsStaking contract.
     * This function will mint the necessary tokens to reward based on the inflation calculation.
     * @param _allocationId Allocation
     * @return Assigned rewards amount
     */
    function takeRewards(
        uint256 _allocationId
    ) 
      external 
      returns (uint256);

    // -- Hooks --

    /**
     * @notice Triggers an update of rewards for a curation.
     * Must be called before `staked BCT` on a curation changes.
     * Note: Hook called from the BardsStaking contract on mint() and burn()
     * @param _curationId Curation Id
     * @return Accumulated rewards for curation
     */
    function onCurationStakingUpdate(
        uint256 _curationId
    ) 
      external 
      returns (uint256);

    /**
     * @notice Triggers an update of rewards for a curation.
     * Must be called before allocation on a curation changes.
     * NOTE: Hook called from the BardStaking contract on allocate() and closeAllocation()
     *
     * @param _curationId Curation Id
     * @return Accumulated rewards per allocated token for a curation
     */
    function onCurationAllocationUpdate(
        uint256 _curationId
    ) 
      external 
      returns (uint256);
	
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title IBardsDaoData
 * @author TheBards Protocol
 *
 * @notice This is the interface for the BardsDaoData contract, 
 * which allows an optional fee percentage, recipient governancor to be set for TheBards protocol Dao.
 */
interface IBardsDaoData {

    /**
     * @notice Initializes the governance, treasury, treasury fee, default curation fee, and default staking fee amounts.
     *
     * @param governance The governance address which has additional control over setting certain parameters.
     * @param treasury The treasury address to direct fees to.
     * @param protocolFee The treasury fee in BPS to levy on collects.
     * @param defaultCurationBps The default curation fee in BPS to levy on collects.
     * @param defaultStakingBps The default staking fee in BPS to levy on collects.
     */
    function initialize(
        address governance,
        address treasury,
        uint32 protocolFee,
        uint32 defaultCurationBps,
        uint32 defaultStakingBps
    ) external;

    /**
     * @notice Sets the governance address. This function can only be called by governance.
     *
     * @param newGovernance The new governance address to set.
     */
    function setGovernance(address newGovernance) external;

    /**
     * @notice Sets the treasury address. This function can only be called by governance.
     *
     * @param newTreasury The new treasury address to set.
     */
    function setTreasury(address newTreasury) external;

    /**
     * @notice Sets the protocol fee. This function can only be called by governance.
     *
     * @param newProtocolFee The new treasury fee to set.
     */
    function setProtocolFee(uint32 newProtocolFee) external;

    /**
     * @notice Sets the Default Curation Bps. This function can only be called by governance.
     *
     * @param newDefaultCurationBps The new default curation Bps to set.
     */
    function setDefaultCurationBps(uint32 newDefaultCurationBps) external;

    /**
     * @notice Sets the default staking Bps. This function can only be called by governance.
     *
     * @param newDefaultStakingBps The new default staking Bps to set.
     */
    function setDefaultStakingBps(uint32 newDefaultStakingBps) external;

    /// ************************
    /// *****VIEW FUNCTIONS*****
    /// ************************

    /**
     * @notice Returns the governance address.
     *
     * @return address The governance address.
     */
    function getGovernance() external view returns (address);

    /**
     * @notice Returns the treasury address.
     *
     * @return address The treasury address.
     */
    function getTreasury() external view returns (address);

    /**
     * @notice Returns the protocol fee bps.
     *
     * @return uint32 The protocol fee bps.
     */
    function getProtocolFee() external view returns (uint32);

    /**
     * @notice Returns the default curation fee bps.
     *
     * @return uint32 The default curation fee bps.
     */
    function getDefaultCurationBps() external view returns (uint32);

    /**
     * @notice Returns the default staking fee bps.
     *
     * @return uint32 The default staking fee bps.
     */
    function getDefaultStakingBps() external view returns (uint32);

    /**
     * @notice Returns the protocol fee setting in a single call.
     *
     * @return ProtocolFeeSetting The DataType contains the treasury address and the protocol fee.
     */
    function getProtocolFeeSetting() external view returns (DataTypes.ProtocolFeeSetting memory);

    /**
     * @notice Returns the treasury address and protocol fee in a single call.
     *
     * @return tuple First, the treasury address, second, the protocol fee.
     */
    function getProtocolFeePair() external view returns (address, uint32);

    /**
     * @notice Computes the fee for a given uint256 amount
     * @param _amount The amount to compute the fee for
     * @return The amount to be paid out to the fee recipient
     */
    function getFeeAmount(uint256 _amount) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title IBardsCurationToken
 * @author TheBards Protocol
 *
 * @notice This is the standard interface for the BardsCurationToken contract.
 */
interface IBardsCurationToken is IERC20 {
     // -- Mint and Burn --
    function burn(uint256 amount) external;

    /**
     * @notice burn tokens from.
     * @param _from Address to burn tokens
     * @param _amount Amount of tokens to mint
     */
    function burnFrom(address _from, uint256 _amount) external;

    /**
     * @notice Mint new tokens.
     * @param _to Address to send the newly minted tokens
     * @param _amount Amount of tokens to mint
     */
    function mint(address _to, uint256 _amount) external;

    /**
     * @notice Add a new minter.
     * @param _account Address of the minter
     */
    function addMinter(address _account) external;

    /**
     * @notice Remove a minter.
     * @param _account Address of the minter
     */
    function removeMinter(address _account) external;

    /**
     * @notice Renounce to be a minter.
     */
    function renounceMinter() external;

    /**
     * @notice Return if the `_account` is a minter or not.
     * @param _account Address to check
     * @return True if the `_account` is minter
     */
    function isMinter(address _account) external view returns (bool);

    /**
     * @notice Approve token allowance by validating a message signed by the holder.
     *
     * @param _owner The token owern.
     * @param _spender The token spender.
     * @param _value Amount of tokens to approve the spender.
     * @param _sig The EIP712 signature struct.
     */
    function permit(
        address _owner,
        address _spender,
        uint256 _value,
        DataTypes.EIP712Signature calldata _sig
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

interface IEpochManager {

    /**
     * @notice Initialize contract
     *
     * @param _HUB The address of HUB
     * @param _epochLength The epoch length
     */
    function initialize(
        address _HUB, 
        uint256 _epochLength
    ) external;

	// -- Configuration --

    function setEpochLength(uint256 _epochLength) external;

    // -- Epochs

    function runEpoch() external;

    // -- Getters --

    function isCurrentEpochRun() external view returns (bool);

    function blockNum() external view returns (uint256);

    function blockHash(uint256 _block) external view returns (bytes32);

    function currentEpoch() external view returns (uint256);

    function currentEpochBlock() external view returns (uint256);

    function currentEpochBlockSinceStart() external view returns (uint256);

    function epochsSince(uint256 _epoch) external view returns (uint256);

    function epochsSinceUpdate() external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IWETH is IERC20 {
    function deposit() external payable;

    function withdraw(uint256 wad) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;

import {DataTypes} from '../../utils/DataTypes.sol';

/**
 * @title IBardsStaking
 * 
 * @author TheBards Protocol
 * 
 * @notice The interface of BardsStaking
 * 
 */
interface IBardsStaking {

    /**
     * @notice initialize the contract.
     * 
     * @param _HUB The address of HUB;
     * @param _bondingCurve The address of bonding curve;
     * @param _bardsShareTokenImpl The address of bards share token;
     * @param _defaultStakingReserveRatio The default staking reserve ratio;
     * @param _stakingTaxPercentage The percentage of staking tax;
     * @param _minimumStaking The minimum staking;
     * @param _stakingAddress The fund address of staking;
     * @param _rebateAlphaNumerator The alphaNumerator of rebating;
     * @param _rebateAlphaDenominator The alphaDenominator of rebating;
     * @param _thawingPeriod The thawing period;
     * @param _channelDisputeEpochs _channelDisputeEpochs
     * @param _maxAllocationEpochs _maxAllocationEpochs
     */
    function initialize(
        address _HUB,
        address _bondingCurve,
        address _bardsShareTokenImpl,
        uint32 _defaultStakingReserveRatio,
        uint32 _stakingTaxPercentage,
        uint256 _minimumStaking,
        address _stakingAddress,
        uint32 _rebateAlphaNumerator,
        uint32 _rebateAlphaDenominator,
        uint32 _thawingPeriod,
        uint32 _channelDisputeEpochs,
        uint32 _maxAllocationEpochs
    ) external;

    /**
     * @notice Set the address of tokens.
     * 
     * @param _stakingAddress The address of staking tokens;
     */
    function setStakingAddress(address _stakingAddress) external;

    /**
     * @notice Set the default reserve ratio percentage for a curation pool.
     * 
     * Update the default reserver ratio to `_defaultReserveRatio`
     * @param _defaultReserveRatio Reserve ratio (in PPM)
     */
    function setDefaultReserveRatio(uint32 _defaultReserveRatio) external;

    /**
     * @notice Set the minimum stake required to.
     * 
     * @param _minimumStaking Minimum stake
     */
    function setMinimumStaking(uint256 _minimumStaking) external;

    /**
     * @notice Set the thawing period for unstaking.
     * 
     * @param _thawingPeriod Period in blocks to wait for token withdrawals after unstaking
     */
    function setThawingPeriod(uint32 _thawingPeriod) external;

    /**
     * @notice Set the period in epochs that need to pass before fees in rebate pool can be claimed.
     * 
     * @param _channelDisputeEpochs Period in epochs
     */
    function setChannelDisputeEpochs(uint32 _channelDisputeEpochs) external;

    /**
     * @notice Set the max time allowed for stake on allocations.
     * 
     * @param _maxAllocationEpochs Allocation duration limit in epochs
     */
    function setMaxAllocationEpochs(uint32 _maxAllocationEpochs) external;

    /**
     * @notice Set the rebate ratio (fees to allocated stake).
     * 
     * @param _alphaNumerator Numerator of `alpha` in the cobb-douglas function
     * @param _alphaDenominator Denominator of `alpha` in the cobb-douglas function
     */
    function setRebateRatio(uint32 _alphaNumerator, uint32 _alphaDenominator) external;

    /**
     * @notice Set a staking tax percentage to burn when staked funds are deposited.
     * @param _percentage Percentage of staked tokens to burn as staking tax
     */
    function setStakingTaxPercentage(uint32 _percentage) external;

    /**
     * @notice Set the master copy to use as clones for the Bards Share Tokens.
     * @param _bardsShareTokenImpl Address of implementation contract to use for Bards Share Tokens.
     */
    function setBardsShareTokenImpl(address _bardsShareTokenImpl) external;

    /**
     * @notice Returns whether `_curationId` is staked.
     * 
     * @param _curationId The curation ID.
     */
    function isStaked(uint256 _curationId) external view returns (bool);

    // -- Staking --

    /**
     * @notice Deposit tokens on the curation.
     * 
     * @param _curationId curation Id
     * @param _tokens Amount of tokens to stake
     */
    function stake(uint256 _curationId, uint256 _tokens) external returns (uint256 shareOut, uint256 stakingTax) ;

    /**
     * @notice Unstake shares from the curation stake, lock them until thawing period expires.
     * 
     * @param _curationId Curation Id to unstake
     * @param _shares Amount of shares to unstake
     */
    function unstake(uint256 _curationId, uint256 _shares) external returns(uint256);

    /**
     * @notice Withdraw staked tokens once the thawing period has passed.
     * 
     * @param _curationId curation Id
     * @param _stakeToCuration Re-delegate to new curation if non-zero, withdraw if zero address
     */ 
    function withdrawStaked(uint256 _curationId, uint256 _stakeToCuration) external returns (uint256);

    // -- Channel management and allocations --

    /**
     * @notice Allocate available tokens to a curation.
     * 
     * @param _createAllocationData Data of struct CreateAllocationData
     */
    function allocate(
        DataTypes.CreateAllocateData calldata _createAllocationData
    ) external;

    /**
     * @notice Close an allocation and free the staked tokens.
     * 
     * @param _allocationId The allocation identifier.
     * @param _stakeToCuration Restake to curation.
     */
    function closeAllocation(uint256 _allocationId, uint256 _stakeToCuration) external;

    /**
     * @notice Close multiple allocations and free the staked tokens.
     * 
     * @param _allocationIds An array of allocationId
     * @param _stakeToCurations An array of curations for restaking.
     */
    function closeAllocationMany(uint256[] calldata _allocationIds, uint256[] calldata _stakeToCurations) external;

    /**
     * @notice Close and allocate. This will perform a close and then create a new Allocation
     * atomically on the same transaction.
     * 
     * @param _closingAllocationID The identifier of the allocation to be closed
     * @param _stakeToCuration The curation of restaking.
     * @param _createAllocationData Data of struct CreateAllocationData
     */
    function closeAndAllocate(
        uint256 _closingAllocationID,
        uint256 _stakeToCuration,
        DataTypes.CreateAllocateData calldata _createAllocationData
    ) external;

    /**
     * @notice Collect fees from market and assign them to an allocation.
     * Funds received are only accepted from a valid sender.
     * To avoid reverting on the withdrawal from channel flow this function will:
     * 1) Accept calls with zero tokens.
     * 2) Accept calls after an allocation passed the dispute period, in that case, all
     *    the received tokens are burned.
     * @param _currency Currency of token to collect.
     * @param _tokens Amount of tokens to collect
     * @param _allocationId Allocation where the tokens will be assigned
     */
    function collect(address _currency, uint256 _tokens, uint256 _allocationId) external;

    /**
     * @notice Collect the delegation rewards.
     * This function will assign the collected fees to the delegation pool.
     * @param _curationId Curation to which the tokens to distribute are related
     * @param _currency The currency of token.
     * @param _tokens Total tokens received used to calculate the amount of fees to collect
     */
    function collectStakingFees(
        uint256 _curationId, 
        address _currency, 
        uint256 _tokens
    ) external;

    /**
     * @notice Claim tokens from the rebate pool.
     * 
     * @param _allocationId Allocation from where we are claiming tokens
     * @param _stakeToCuration Restake to new curation
     */
    function claim(uint256 _allocationId, uint256 _stakeToCuration) external;

    /**
     * @notice Claim tokens from the rebate pool for many allocations.
     * 
     * @param _allocationIds Array of allocations from where we are claiming tokens
     * @param _stakeToCuration Restake to new curation
     */
    function claimMany(uint256[] calldata _allocationIds, uint256 _stakeToCuration) external;

    // -- Getters and calculations --

    /**
     * @notice Return the current state of an allocation.
     * @param _allocationId Address used as the allocation identifier
     * @return AllocationState
     */
    function getAllocationState(uint256 _allocationId) external view returns (DataTypes.AllocationState);

    /**
     * @notice Return if allocationId is used.
     * 
     * @param _allocationId Address used as signer for an allocation
     * @return True if allocationId already used
     */
    function isAllocation(uint256 _allocationId) external view returns (bool);

    /**
     * @notice Return the total amount of tokens allocated to curation.
     * 
     * @param _allocationId allocation Id
     * @param _currency The address of currency
     * @return Total tokens allocated to curation
     */
    function getFeesCollectedInAllocation(
        uint256 _allocationId, 
        address _currency
    )
        external
        view
        returns (uint256);

    /**
     * @notice Return the total amount of tokens allocated to curation.
     * 
     * @param _curationId _curationId
     * @return Total tokens allocated to curation
     */
    function getCurationAllocatedTokens(uint256 _curationId)
        external
        view
        returns (uint256);

    /**
     * @notice Get the address of staking tokens.
     * 
     * @return The address of Staking tokens.
     */
    function getStakingAddress() 
        external
        view
        returns (address);

    /**
     * @notice Get the total staking tokens.
     * 
     * @return The total Staking tokens.
     */
    function getTotalStakingToken() 
        external
        view
        returns (uint256);

    function getSimpleAllocation(
        uint256 _allocationId
    ) 
        external 
        view 
        returns (DataTypes.SimpleAllocation memory);

    /**
     * @notice Get the reserveRatio of curation.
     *
     * @param _curationId The curation ID
     * 
     * @return reserveRatio The reserveRatio of curation.
     */
    function getReserveRatioOfCuration(uint256 _curationId) 
        external
        view
        returns (uint32 reserveRatio);

    /**
     * @notice Returns amount of staked BCT tokens ready to be withdrawn after thawing period.
     * @param _curationId curation Id.
     * @param _delegator Delegator owning the share tokens
     * @return Are there any withdrawable tokens.
     */
    function getWithdrawableBCTTokens(uint256 _curationId, address _delegator)
        external
        view
        returns (uint256);

    /**
     * @notice Get the amount of share a delegator has in a curation staking pool.
     * 
     * @param _delegator Delegator owning the share tokens
     * @param _curationId curation Id.
     * 
     * @return Amount of share owned by a delegator for the curation
     */
    function getDelegatorShare(
        address _delegator, 
        uint256 _curationId
    )
        external
        view
        returns (uint256);

    /**
     * @notice Get the amount of share in a curation staking pool.
     * 
     * @param _curationId curation Id.
     * 
     * @return Amount of share minted for the curation
     */
    function getStakingPoolShare(uint256 _curationId) 
        external 
        view 
        returns (uint256);

    /**
     * @notice Get the amount of share in a curation staking pool.
     * 
     * @param _curationId curation Id.
     * 
     * @return Amount of share minted for the curation
     */
    function getStakingPoolToken(uint256 _curationId) 
        external 
        view 
        returns (uint256);

    /**
     * @notice Return whether the delegator has staked to the curation.
     * 
     * @param _curationId  Curation Id where funds have been staked
     * @param _delegator Address of the delegator
     * @return True if delegator of curation
     */
    function isDelegator(uint256 _curationId, address _delegator) external view returns (bool);

    /**
     * @notice Return whether the seller is one of the stakeholders of curation.
     * 
     * @param _allocationId _allocationId
     * @param _seller Address of the seller of curation NFT
     * @return True if delegator of curation
     */
    function isSeller(uint256 _allocationId, address _seller) external view returns (bool);

    /**
     * @notice Calculate amount of share that can be bought with tokens in a staking pool.
     * 
     * @param _curationId Curation to mint share
     * @param _tokens Amount of tokens used to mint share
     * @return Amount of share that can be bought with tokens
     */
    function tokensToShare(uint256 _curationId, uint256 _tokens)
        external
        view
        returns (uint256, uint256);

    /**
     * @notice Calculate number of tokens to get when burning shares from a staking pool.
     * 
     * @param _curationId Curation to burn share
     * @param _shares Amount of share to burn
     * 
     * @return Amount of tokens to get for an amount of shares
     */
    function shareToTokens(uint256 _curationId, uint256 _shares)
        external
        view
        returns (uint256);
}

// SPDX-License-Identifier: MIT

import {IBardsStaking} from '../interfaces/tokens/IBardsStaking.sol';

pragma solidity ^0.8.12;

/**
 * @title DataTypes
 * @author TheBards Protocol
 *
 * @notice A standard library of data types used throughout the bards Protocol.
 */
library DataTypes {

	enum ContentType {
		Microblog,
        Article,
        Audio,
        Video
	}

	enum CurationType {
		Profile,
        Content,
        Combined,
        Protfolio,
        Feed,
        Dapp
	}

    /**
     * @notice An enum containing the different states the protocol can be in, limiting certain actions.
     *
     * @param Unpaused The fully unpaused state.
     * @param CurationPaused The state where only curation creation functions are paused.
     * @param Paused The fully paused state.
     */
    enum ProtocolState {
        Unpaused,
        CurationPaused,
        Paused
    }

    /**
     * @notice A struct containing the necessary information to reconstruct an EIP-712 typed data signature.
     *
     * @param v The signature's recovery parameter.
     * @param r The signature's r parameter.
     * @param s The signature's s parameter
     * @param deadline The signature's deadline
     */
    struct EIP712Signature {
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 deadline;
    }

    /**
     * @notice Contains the owner address and the mint timestamp for every NFT.
     *
     * Note: Instead of the owner address in the _tokenOwners private mapping, we now store it in the
     * _tokenData mapping, alongside the unchanging mintTimestamp.
     *
     * @param owner The token owner.
     * @param mintTimestamp The mint timestamp.
     */
    struct TokenData {
        address owner;
        uint96 mintTimestamp;
    }

    /**
     * A struct containing the parameters required for the `permit` function of bardsCurationToken.
     * @param owner The address of the owner of token.
     * @param spender The address of the spender who will be approved.
     * @param value The token amount.
     */
    struct BCTPermitData{
        address owner;
        address spender;
        uint256 value;
    }

    /**
     * A struct containing the parameters required for the `permitWithSig` function of bardsCurationToken.
     * @param owner The address of the owner of token.
     * @param spender The address of the spender who will be approved.
     * @param value The token amount.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct BCTPermitWithSigData{
        address owner;
        address spender;
        uint256 value;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `SetAllocationIdData()` function. 
     *
     * @param curationId The token ID of the curation.
     * @param allocationId The allocation id.
     * @param curationMetaData The encoding of curation Data.
     * @param stakeToCuration The curation Id restake to
     */
    struct SetAllocationIdData {
        uint256 curationId;
        uint256 allocationId;
        bytes curationMetaData;
        uint256 stakeToCuration; 
    }

    /**
     * @notice A struct containing the parameters required for the `setAllocationIdWithSig()` function. Parameters are
     * the same as the regular `setAllocationId()` function, with an added EIP712Signature.
     *
     * @param curationId The token ID of the curation.
     * @param allocationId The address of the allocation.
     * @param curationMetaData The encoding of curation Data.
     * @param stakeToCuration The curation Id restake to
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetAllocationIdWithSigData {
        uint256 curationId;
        uint256 allocationId;
        bytes curationMetaData;
        uint256 stakeToCuration;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setDefaultProfileWithSig()` function. Parameters are
     * the same as the regular `setDefaultProfile()` function, with an added EIP712Signature.
     *
     * @param wallet The address of the wallet setting the default profile.
     * @param profileId The token ID of the profile which will be set as default, or zero.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetDefaultProfileWithSigData {
        address wallet;
        uint256 profileId;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the parameters required for the `setMarketModule()` function.
     *
     * @param curationId The token ID of the curation to change the marketModule for.
	 * @param tokenContract The address of NFT token to curate.
     * @param tokenId The NFT token ID to curate.
     * @param marketModule The marketModule to set for the given curation, must be whitelisted.
     * @param marketModuleInitData The data to be passed to the marketModule for initialization.
     */
    struct SetMarketModuleData {
        uint256 curationId;
        address tokenContract;
        uint256 tokenId;
        address marketModule;
        bytes marketModuleInitData;
    }

    /**
     * @notice A struct containing the parameters required for the `setMarketModuleWithSig()` function. Parameters are
     * the same as the regular `setMarketModule()` function, with an added EIP712Signature.
     *
     * @param curationId The token ID of the curation to change the marketModule for.
	 * @param tokenContract The address of NFT token to curate.
     * @param tokenId The NFT token ID to curate.
     * @param marketModule The marketModule to set for the given curation, must be whitelisted.
     * @param marketModuleInitData The data to be passed to the marketModule for initialization.
     * @param sig The EIP712Signature struct containing the profile owner's signature.
     */
    struct SetMarketModuleWithSigData {
        uint256 curationId;
        address tokenContract;
        uint256 tokenId;
        address marketModule;
        bytes marketModuleInitData;
        EIP712Signature sig;
    }

    /**
     * @notice Contains the curation BPS and staking BPS for every Curation.
     *
	 * @param sellerFundsRecipients The addresses where funds are sent after the trade.
	 * @param curationFundsRecipients The curation Id where funds are sent after the trade.
	 * @param sellerFundsBpses The fee percents that is sent to the sellers.
	 * @param curationFundsBpses The fee percents that is sent to the curation.
	 * @param curationBps The points fee of willing to share of the NFT income to curators.
	 * @param stakingBps The points fee of willing to share of the NFT income to delegators who staking tokens.
     * @param updatedAtBlock Period that need to pass to update curation data parameters
     */
    struct CurationData {
        address[] sellerFundsRecipients;
        uint256[] curationFundsRecipients;
		uint32[] sellerFundsBpses;
        uint32[] curationFundsBpses;
		uint32 curationBps;
		uint32 stakingBps;
        uint256 updatedAtBlock;
    }

    /**
     * @notice A struct containing the parameters required for the `createCuration()` function.
     *
     * @param tokenId The token id.
     * @param curationData The data of CurationData curation.
     */
    struct InitializeCurationData {
        uint256 tokenId;
        bytes curationData;
    }

    /**
     * @notice The metadata for a free market.
     * @param seller The seller of nft
     * @param minter The programmable minter module.
     */
    struct FreeMarketData {
        address seller;
        address minter;
    }

    /**
     * @notice The metadata for a fix price market.
     * @param seller The seller of nft
     * @param currency The currency to ask.
     * @param price The fix price of nft.
     * @param treasury The recipient of the fee
     * @param minter The programmable minter module.
     */
    struct FixPriceMarketData {
        address seller;
        address currency;
        uint256 price;
        address treasury;
        address minter;
    }

    /**
     * @notice The metadata of a protocol fee setting
     * @param feeBps The basis points fee
     * @param treasury The recipient of the fee
     * @param curationBps The default points fee of willing to share of the NFT income to curators.
	 * @param stakingBps The default points fee of willing to share of the NFT income to delegators who staking tokens.
     */
    struct ProtocolFeeSetting {
        uint32 feeBps;
        address treasury;
        uint32 defaultCurationBps;
		uint32 defaultStakingBps;
    }

    /**
     * @notice A struct containing data associated with each new Content Curation.
     *
     * @param curationType The Type of curation.
     * @param handle The profile's associated handle.
       @param tokenContractPointed The token contract address this curation points to, default is the bards hub.
     * @param tokenIdPointed The token ID this curation points to.
     * @param contentURI The URI associated with this publication.
     * @param marketModule The address of the current market module in use by this curation to trade itself, can be empty.
     * @param minterMarketModule The address of the current mint market module in use by this curation. 
     * @param curationFrom The curation Id that this curation minted from.
     * Make sure each curation can mint its own NFTs. minterMarketModule is marketModule, but the initialization parameters are different.
     */
    struct CurationStruct {
        CurationType curationType;
        string handle;
        address tokenContractPointed;
        uint256 tokenIdPointed;
        string contentURI;
        address marketModule;
        address minterMarketModule;
        uint256 allocationId;
        uint256 curationFrom;
    }

    /**
     * @notice A struct containing the parameters required for the `setCurationContentURIWithSig()` function. Parameters are the same
     * as the regular `setCurationContentURI()` function, with an added EIP712Signature.
     *
     * @param curationId The token ID of the curation to set the URI for.
     * @param contentURI The URI to set for the given curation.
     * @param sig The EIP712Signature struct containing the curation owner's signature.
     */
    struct SetCurationContentURIWithSigData {
        uint256 curationId;
        string contentURI;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the paramters required for the `collect` function.
     * 
     * @param curationId The token ID of the curation being collected's parent profile.
     * @param curationIds A array of curation IDs sharing trade fees.
     * @param collectMetaData The meta data for collecting.
     * @param fromCuration Whether to mint from scratch in curation.
     * 
     */
    struct SimpleDoCollectData {
        uint256 curationId;
        uint256[] curationIds;
        bytes collectMetaData;
        bool fromCuration;
    }

    /**
     * @notice A struct containing the paramters required for the `_collect` function.
     * 
     * @param collector The address executing the collect.
     * @param curationId The token ID of the curation being collected's parent profile.
     * @param curationIds A array of curation IDs sharing trade fees.
     * @param collectMetaData The meta data for collecting.
     * @param fromCuration Whether to mint from scratch in curation.
     * 
     */
    struct DoCollectData {
        address collector;
        uint256 curationId;
        uint256[] curationIds;
        bytes collectMetaData;
        bool fromCuration;
    }

    /**
     * @notice A struct containing the paramters required for the `collectWithSig` function.
     * 
     * @param collector The address executing the collect.
     * @param curationId The token ID of the curation being collected's parent profile.
     * @param curationIds A array of curation IDs sharing trade fees.
     * @param collectMetaData The meta data for collecting.
     * @param fromCuration Whether to mint from scratch in curation.
     * @param sig
     */
    struct DoCollectWithSigData {
        address collector;
        uint256 curationId;
        uint256[] curationIds;
        bytes collectMetaData;
        bool fromCuration;
        EIP712Signature sig;
    }

    /**
     * @notice A struct containing the paramters required for the `collect` function.
     * 
     * @param collector The address executing the collect.
     * @param curationId The token ID of the curation being collected's parent profile.
     * @param tokenContract The address of token.
     * @param tokenId The token id.
     * @param curationIds A array of curation IDs sharing trade fees.
     * @param collectMetaData The meta data for collecting.
     * 
     */
    struct MarketCollectData {
        address collector;
        uint256 curationId;
        address tokenContract;
        uint256 tokenId;
        uint256[] curationIds;
        bytes collectMetaData;
    }

    /**
     * @notice A struct containing the parameters required for the `createProfile()` and `creationCuration` function.
     *
     * @param to The address receiving the curation.
     * @param curationType The Type of curation.
     * @param profileId the profile id creating the curation.
     * @param curationId the curation ID.
     * @param tokenContractPointed The token contract address this curation points to, default is the bards hub.
     * @param tokenIdPointed The token ID this curation points to.
     * @param handle The handle to set for the profile, must be unique and non-empty.
     * @param contentURI The URI to set for the profile metadata.
     * @param marketModule The market module to use, can be the zero address to trade itself.
     * @param marketModuleInitData The market module initialization data, if any.
     * @param minterMarketModule The minter market module to use, can be the zero address. Make sure each curation can mint its own NFTs.
     * minterMarketModule is marketModule, but the initialization parameters are different.
     * @param minterMarketModuleInitData The minter market module initialization data, if any.
     * @param curationMetaData The data of CurationData struct.
     * @param curationFrom The curation Id that this curation minted from.
     */
    struct CreateCurationData {
        address to;
        CurationType curationType;
        uint256 profileId;
        uint256 curationId;
        address tokenContractPointed;
        uint256 tokenIdPointed;
        string handle;
        string contentURI;
        address marketModule;
        bytes marketModuleInitData;
        address minterMarketModule;
        bytes minterMarketModuleInitData;
        bytes curationMetaData;
        uint256 curationFrom;
    }

    /**
     * @notice A struct containing the parameters required for the `createProfile()` and `creationCuration` function.
     *
     * @param curationType The Type of curation.
     * @param profileId the profile id creating the curation
     * @param curationId the curation ID.
     * @param tokenContractPointed The token contract address this curation points to, default is the bards hub.
     * @param tokenIdPointed The token ID this curation points to.
     * @param handle The handle to set for the profile, must be unique and non-empty.
     * @param contentURI The URI to set for the profile metadata.
     * @param marketModule The market module to use, can be the zero address to trade itself.
     * @param marketModuleInitData The market module initialization data, if any.
     * @param minterMarketModule The minter market module to use, can be the zero address. Make sure each curation can mint its own NFTs.
     * minterMarketModule is marketModule, but the initialization parameters are different.
     * @param minterMarketModuleInitData The minter market module initialization data, if any.
     * @param curationMetaData The data of CurationData struct.
     * @param curationFrom The curation Id that this curation minted from.
     * @param sig
     */
    struct CreateCurationWithSigData {
        CurationType curationType;
        uint256 profileId;
        uint256 curationId;
        address tokenContractPointed;
        uint256 tokenIdPointed;
        string handle;
        string contentURI;
        address marketModule;
        bytes marketModuleInitData;
        address minterMarketModule;
        bytes minterMarketModuleInitData;
        bytes curationMetaData;
        uint256 curationFrom;
        EIP712Signature sig;
    }

    /**
     * @notice Possible states an allocation can be
     * States:
     * - Null = indexer == address(0)
     * - Active = not Null && tokens > 0
     * - Closed = Active && closedAtEpoch != 0
     * - Finalized = Closed && closedAtEpoch + channelDisputeEpochs > now()
     * - Claimed = not Null && tokens == 0
     */
    enum AllocationState {
        Null,
        Active,
        Closed,
        Finalized,
        Claimed
    }

    /**
     * @notice A struct containing the parameters required for the multi-currency fees earned.
     * 
     * @param totalShare Total share during the fees pool's epoch
     * @param currencies The currencies of tokens.
     * @param fees Fees earned, currency -> amount.
     */
    struct MultiCurrencyFees{
        uint256 totalShare;
        address[] currencies;
        mapping (address => uint256) fees;
    }

    /**
     * @notice A struct containing the parameters required for the staking module.
     * 
     * @param tokens BCT Tokens stored as reserves for the curation.
     * @param fees fees earned excluding BCT, which can be withdrawn without thawing period, epoch -> MultiCurrencyFees.
     * @param reserveRatio Ratio for the bonding curve.
     * @param bst Curation token contract for this curation staking pool.
     * @param shares Shares minted totally.
     * @param delegators All delegators.
     */
    struct CurationStakingPool {
        uint256 tokens;
        uint32 reserveRatio;
        address bst;
        uint256 shares;
        mapping(uint256 => MultiCurrencyFees) fees;
        mapping(address => Delegation) delegators;
    }

    /**
     * @notice Individual delegation data of a delegator in a pool. 
     * Will auto-withdraw before updating shares.
     * 
     * @param tokens tokens be staked in curation by delegator.
     * @param shares Shares owned by a delegator in the pool
     * @param tokensLocked Tokens locked for undelegation
     * @param tokensLockedUntil Block when locked tokens can be withdrawn
     * @param lastWithdrawFeesEpoch The last withdraw fees Epoch.
     */
    struct Delegation {
        uint256 shares;
        uint256 tokensLocked;
        uint256 tokensLockedUntil;
        uint256 lastWithdrawFeesEpoch;
    }

    /**
     * @notice Stores accumulated rewards and snapshots related to a particular Curation.
     * 
     * @param accRewardsForCuration Accumulated rewards for curation 
     * @param accRewardsForCurationSnapshot Accumulated rewards for curation snapshot
     * @param accRewardsPerStakingSnapshot Accumulated rewards per staking for curation snapshot
     * @param accRewardsPerAllocatedToken Accumulated rewards per allocated token.
     */
    struct CurationReward {
        uint256 accRewardsForCuration;
        uint256 accRewardsForCurationSnapshot;
        uint256 accRewardsPerStakingSnapshot;
        uint256 accRewardsPerAllocatedToken;
    }

    /**
     * @notice Allocate tokens for the purpose of curation fees and rewards.
     * An allocation is created in the allocate() function and consumed in claim()
     * 
     * @param curator The address of curator.
     * @param curationId curation Id
     * @param recipientsMeta The snapshot of recipients from curationData.
     * @param createdAtEpoch Epoch when it was created
     * @param closedAtEpoch Epoch when it was closed
     * @param collectedFees Collected fees for the allocation
     * @param effectiveAllocationStake Effective allocation when closed
     * @param accRewardsPerAllocatedToken Snapshot used for reward calc
     */
    struct Allocation {
        address curator;
        uint256 curationId;
        bytes recipientsMeta;
        // uint256 tokens;
        uint256 createdAtEpoch;
        uint256 closedAtEpoch;
        MultiCurrencyFees collectedFees;
        uint256 effectiveAllocationStake;
        uint256 accRewardsPerAllocatedToken;
    }

    /**
     * @notice Allocate tokens for the purpose of curation fees and rewards.
     * An allocation is created in the allocate() function and consumed in claim()
     * 
     * @param curator The address of curator.
     * @param curationId curation Id
     * @param recipientsMeta The snapshot of recipients from curationData.
     * @param tokens Tokens allocated to a curation, currency => tokens
     * @param createdAtEpoch Epoch when it was created
     * @param closedAtEpoch Epoch when it was closed
     * @param effectiveAllocationStake Effective allocation when closed
     * @param accRewardsPerAllocatedToken Snapshot used for reward calc
     */
    struct SimpleAllocation {
        address curator;
        uint256 curationId;
        bytes recipientsMeta;
        uint256 tokens;
        uint256 createdAtEpoch;
        uint256 closedAtEpoch;
        uint256 effectiveAllocationStake;
        uint256 accRewardsPerAllocatedToken;
    }

    /**
     * @notice Tracks stats for allocations closed on a particular epoch for claiming.
     * The pool also keeps tracks of total fees collected and stake used.
     * Only one rebate pool exists per epoch
     * 
     * @param fees total trade fees in the rebate pool
     * @param effectiveAllocationStake total effective allocation of stake
     * @param claimedRewards total claimed rewards from the rebate pool
     * @param unclaimedAllocationsCount amount of unclaimed allocations
     * @param alphaNumerator numerator of `alpha` in the cobb-douglas function
     * @param alphaDenominator denominator of `alpha` in the cobb-douglas function
     */
    struct RebatePool {
        MultiCurrencyFees fees;
        mapping (address => uint256) effectiveAllocationStake;
        MultiCurrencyFees claimedRewards;
        uint32 unclaimedAllocationsCount;
        uint32 alphaNumerator;
        uint32 alphaDenominator;
    }

    /**
     * @notice The struct for creating allocate
     * 
     * @param allocationId The allocation Id.
     * @param curator The address of curator.
     * @param curationId Curation Id.
     * @param recipientsMeta The snapshot of recipients from curationData.
     * 
     */
    struct CreateAllocateData {
        uint256 allocationId;
        address curator;
        uint256 curationId;
        bytes recipientsMeta;
    }

    struct UpdateCurationDataParamsData {
        address owner;
        uint256 tokenId;
        uint256 newAllocationId;
        uint32 minimalCooldownBlocks;
        IBardsStaking bardsStaking;
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