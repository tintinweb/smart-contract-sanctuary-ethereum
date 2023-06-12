// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController3_1.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBCurrencies.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/structs/JBProjectMetadata.sol";
import "@jbx-protocol/juice-721-delegate/contracts/interfaces/IJBTiered721DelegateProjectDeployer.sol";
import "@jbx-protocol/juice-721-delegate/contracts/enums/JB721GovernanceType.sol";
import "@jbx-protocol/juice-721-delegate/contracts/structs/JBTiered721FundingCycleMetadata.sol";
import "@jbx-protocol/juice-721-delegate/contracts/libraries/JBTiered721FundingCycleMetadataResolver.sol";
import "./CroptopPublisher.sol";

/// @notice A contract that facilitates deploying a simple Juicebox project to receive posts from Croptop templates.
contract CroptopDeployer is IERC721Receiver {
    /// @notice The controller that projects are made from.
    IJBController3_1 public controller;

    /// @notice The deployer to launch Croptop recorded collections from.
    IJBTiered721DelegateProjectDeployer public deployer;

    /// @notice The contract storing NFT data for newly deployed collections.
    IJBTiered721DelegateStore public store;

    /// @notice The Croptop publisher.
    CroptopPublisher public publisher;

    /// @param _controller The controller that projects are made from.
    /// @param _deployer The deployer to launch Croptop projects from.
    /// @param _store The contract storing NFT data for newly deployed collections.
    /// @param _publisher The croptop publisher.
    constructor(
        IJBController3_1 _controller,
        IJBTiered721DelegateProjectDeployer _deployer,
        IJBTiered721DelegateStore _store,
        CroptopPublisher _publisher
    ) {
        controller = _controller;
        deployer = _deployer;
        store = _store;
        publisher = _publisher;
    }

    /// @notice Deploy a simple project meant to receive posts from Croptop templates.
    /// @param _owner The address that'll own the project.
    /// @param _terminal The contract that the project will begin receiving funds from.
    /// @param _projectMetadata The metadata containing project info.
    /// @param _allowedPosts The type of posts that the project should allow.
    /// @param _contractUri A link to the collection's metadata.
    /// @param _name The name of the collection where posts will go.
    /// @param _symbol The symbol of the collection where posts will go.
    /// @return projectId The ID of the newly created project.
    function deployProjectFor(
        address _owner,
        IJBPaymentTerminal _terminal,
        JBProjectMetadata calldata _projectMetadata,
        AllowedPost[] calldata _allowedPosts,
        string calldata _contractUri,
        string memory _name,
        string memory _symbol
    ) external returns (uint256 projectId) {
        // Initialize the terminal array .
        IJBPaymentTerminal[] memory _terminals = new IJBPaymentTerminal[](1);
        _terminals[0] = _terminal;

        // Deploy a blank project.
        projectId = deployer.launchProjectFor({
            _owner: address(this),
            _deployTieredNFTRewardDelegateData: JBDeployTiered721DelegateData({
                name: _name,
                symbol: _symbol,
                fundingCycleStore: controller.fundingCycleStore(),
                baseUri: "ipfs://",
                tokenUriResolver: IJBTokenUriResolver(address(0)),
                contractUri: _contractUri,
                owner: _owner,
                pricing: JB721PricingParams({
                    tiers: new JB721TierParams[](0),
                    currency: uint48(JBCurrencies.ETH),
                    decimals: 18,
                    prices: IJBPrices(address(0))
                }),
                reservedTokenBeneficiary: address(0),
                store: store,
                flags: JBTiered721Flags({
                    lockReservedTokenChanges: false,
                    lockVotingUnitChanges: false,
                    lockManualMintingChanges: false,
                    preventOverspending: false
                }),
                governanceType: JB721GovernanceType.NONE
            }),
            _launchProjectData: JBLaunchProjectData({
                projectMetadata: _projectMetadata,
                data: JBFundingCycleData({
                    duration: 0,
                    weight: 1000000000000000000000000,
                    discountRate: 0,
                    ballot: IJBFundingCycleBallot(address(0))
                }),
                metadata: JBPayDataSourceFundingCycleMetadata({
                    global: JBGlobalFundingCycleMetadata({
                        allowSetTerminals: false,
                        allowSetController: false,
                        pauseTransfers: false
                    }),
                    reservedRate: 0,
                    redemptionRate: 0,
                    ballotRedemptionRate: 0,
                    pausePay: false,
                    pauseDistributions: false,
                    pauseRedeem: false,
                    pauseBurn: false,
                    allowMinting: false,
                    allowTerminalMigration: false,
                    allowControllerMigration: false,
                    holdFees: false,
                    preferClaimedTokenOverride: false,
                    useTotalOverflowForRedemptions: false,
                    useDataSourceForRedeem: false,
                    metadata: JBTiered721FundingCycleMetadataResolver.packFundingCycleGlobalMetadata(
                        JBTiered721FundingCycleMetadata({pauseTransfers: false, pauseMintingReserves: false})
                        )
                }),
                mustStartAtOrAfter: 0,
                groupedSplits: new JBGroupedSplits[](0),
                fundAccessConstraints: new JBFundAccessConstraints[](0),
                terminals: _terminals,
                memo: "Deployed from Croptop"
            }),
            _controller: controller
        });

        // Configure allowed posts.
        if (_allowedPosts.length > 0) publisher.configureFor(projectId, _allowedPosts);

        //transfer to _owner.
        controller.projects().transferFrom(address(this), _owner, projectId);
    }

    // Need to implement this to own a Juicebox project.
    function onERC721Received(address _operator, address _from, uint256 _tokenId, bytes calldata _data)
        view
        external
        returns (bytes4)
    {
        _data;
        _tokenId;
        _operator;

        // Make sure the 721 received is the JBProjects contract.
        if (msg.sender != address(controller.projects())) revert();
        // Make sure the 721 is being received as a mint.
        if (_from != address(0)) revert();
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBController3_0_1.sol';
import './IJBDirectory.sol';
import './IJBFundAccessConstraintsStore.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBTokenStore.sol';

interface IJBController3_1 is IJBController3_0_1, IERC165 {
  event LaunchProject(uint256 configuration, uint256 projectId, string memo, address caller);

  event LaunchFundingCycles(uint256 configuration, uint256 projectId, string memo, address caller);

  event ReconfigureFundingCycles(
    uint256 configuration,
    uint256 projectId,
    string memo,
    address caller
  );

  event DistributeReservedTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    address caller
  );

  event DistributeToReservedTokenSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 tokenCount,
    address caller
  );

  event MintTokens(
    address indexed beneficiary,
    uint256 indexed projectId,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    uint256 reservedRate,
    address caller
  );

  event BurnTokens(
    address indexed holder,
    uint256 indexed projectId,
    uint256 tokenCount,
    string memo,
    address caller
  );

  event Migrate(uint256 indexed projectId, IJBMigratable to, address caller);

  event PrepMigration(uint256 indexed projectId, address from, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function tokenStore() external view returns (IJBTokenStore);

  function splitsStore() external view returns (IJBSplitsStore);

  function fundAccessConstraintsStore() external view returns (IJBFundAccessConstraintsStore);

  function directory() external view returns (IJBDirectory);

  function reservedTokenBalanceOf(uint256 _projectId) external view returns (uint256);

  function totalOutstandingTokensOf(uint256 _projectId) external view returns (uint256);

  function getFundingCycleOf(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function latestConfiguredFundingCycleOf(uint256 _projectId)
    external
    view
    returns (
      JBFundingCycle memory,
      JBFundingCycleMetadata memory metadata,
      JBBallotState
    );

  function currentFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function queuedFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function launchProjectFor(
    address _owner,
    JBProjectMetadata calldata _projectMetadata,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    string calldata _memo
  ) external returns (uint256);

  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    bool _useReservedRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  ) external;

  function distributeReservedTokensOf(uint256 _projectId, string memory _memo)
    external
    returns (uint256);

  function migrate(uint256 _projectId, IJBMigratable _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JBCurrencies {
  uint256 public constant ETH = 1;
  uint256 public constant USD = 2;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member content The metadata content.
  @member domain The domain within which the metadata applies.
*/
struct JBProjectMetadata {
  string content;
  uint256 domain;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBProjects.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController3_1.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBProjectMetadata.sol';
import '../structs/JBDeployTiered721DelegateData.sol';
import '../structs/JBLaunchProjectData.sol';
import '../structs/JBLaunchFundingCyclesData.sol';
import '../structs/JBReconfigureFundingCyclesData.sol';
import './IJBTiered721DelegateDeployer.sol';

interface IJBTiered721DelegateProjectDeployer {
  function directory() external view returns (IJBDirectory);

  function delegateDeployer() external view returns (IJBTiered721DelegateDeployer);

  function launchProjectFor(
    address _owner,
    JBDeployTiered721DelegateData memory _deployTieredNFTRewardDelegateData,
    JBLaunchProjectData memory _launchProjectData,
    IJBController3_1 _controller
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 _projectId,
    JBDeployTiered721DelegateData memory _deployTieredNFTRewardDelegateData,
    JBLaunchFundingCyclesData memory _launchFundingCyclesData,
    IJBController3_1 _controller
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBDeployTiered721DelegateData memory _deployTieredNFTRewardDelegateData,
    JBReconfigureFundingCyclesData memory _reconfigureFundingCyclesData,
    IJBController3_1 _controller
  ) external returns (uint256 configuration);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum JB721GovernanceType {
  NONE,
  ONCHAIN
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member pauseTransfers A flag indicating if the token transfer functionality should be paused during the funding cycle.
  @member pauseMintingReserves A flag indicating if voting unit expectations can change over time by adding new tiers with voting units.
*/
struct JBTiered721FundingCycleMetadata {
  bool pauseTransfers;
  bool pauseMintingReserves;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

import './../structs/JBTiered721FundingCycleMetadata.sol';

library JBTiered721FundingCycleMetadataResolver {
  function transfersPaused(uint256 _data) internal pure returns (bool) {
    return (_data & 1) == 1;
  }

  function mintingReservesPaused(uint256 _data) internal pure returns (bool) {
    return ((_data >> 1) & 1) == 1;
  }

  /**
    @notice
    Pack the tiered 721 funding cycle metadata.

    @param _metadata The metadata to validate and pack.

    @return packed The packed uint256 of all tiered 721 metadata params.
  */
  function packFundingCycleGlobalMetadata(
    JBTiered721FundingCycleMetadata memory _metadata
  ) internal pure returns (uint256 packed) {
    // pause transfers in bit 0.
    if (_metadata.pauseTransfers) packed |= 1;
    // pause mint reserves in bit 2.
    if (_metadata.pauseMintingReserves) packed |= 1 << 1;
  }

  /**
    @notice
    Expand the tiered 721 funding cycle metadata.

    @param _packedMetadata The packed metadata to expand.

    @return metadata The tiered 721 metadata object.
  */
  function expandMetadata(
    uint8 _packedMetadata
  ) internal pure returns (JBTiered721FundingCycleMetadata memory metadata) {
    return
      JBTiered721FundingCycleMetadata(
        transfersPaused(_packedMetadata),
        mintingReservesPaused(_packedMetadata)
      );
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBController3_1.sol";
import "@jbx-protocol/juice-contracts-v3/contracts/libraries/JBTokens.sol";
import "@jbx-protocol/juice-721-delegate/contracts/interfaces/IJBTiered721Delegate.sol";

/// @notice Criteria for allowed posts.
/// @custom:member nft The NFT to which this allowance applies.
/// @custom:member category A category that should allow posts.
/// @custom:member minimumPrice The minimum price that a post to the specified category should cost.
/// @custom:member minimumTotalSupply The minimum total supply of NFTs that can be made available when minting.
/// @custom:member maxTotalSupply The max total supply of NFTs that can be made available when minting. Leave as 0 for max.
/// @custom:member allowedAddresses A list of addresses that are allowed to post on the category through Croptop.
struct AllowedPost {
    address nft;
    uint256 category;
    uint256 minimumPrice;
    uint256 minimumTotalSupply;
    uint256 maximumTotalSupply;
    address[] allowedAddresses;
}

/// @notice A post to be published.
/// @custom:member encodedIPFSUri The encoded IPFS URI of the post that is being published.
/// @custom:member totalSupply The number of NFTs that should be made available, including the 1 that will be minted alongside this transaction.
/// @custom:member price The price being paid for buying the post that is being published.
/// @custom:member category The category that the post should be published in.
struct Post {
    bytes32 encodedIPFSUri;
    uint32 totalSupply;
    uint88 price;
    uint16 category;
}

/// @notice A contract that facilitates the permissioned publishing of NFT posts to a Juicebox project.
contract CroptopPublisher {
    error TOTAL_SUPPY_MUST_BE_POSITIVE();
    error EMPTY_ENCODED_IPFS_URI(bytes32 encodedUri);
    error INCOMPATIBLE_PROJECT(uint256 projectId, address dataSource);
    error INSUFFICIENT_ETH_SENT(uint256 expected, uint256 sent);
    error NOT_IN_ALLOW_LIST(address[] allowedAddresses);
    error MAX_TOTAL_SUPPLY_LESS_THAN_MIN();
    error PRICE_TOO_SMALL(uint256 minimumPrice);
    error TOTAL_SUPPLY_TOO_SMALL(uint256 minimumTotalSupply);
    error TOTAL_SUPPLY_TOO_BIG(uint256 maximumTotalSupply);
    error UNAUTHORIZED();
    error UNAUTHORIZED_TO_POST_IN_CATEGORY();

    event Collected(
        uint256 projectId, Post[] posts, address nftBeneficiary, address feeBeneficiary, uint256 fee, address caller
    );

    /// @notice Packed values that determine the allowance of posts.
    /// @custom:param _projectId The ID of the project.
    /// @custom:param _nft The NFT contract for which this allowance applies.
    /// @custom:param _category The category for which the allowance applies
    mapping(uint256 _projectId => mapping(address _nft => mapping(uint256 _category => uint256))) internal
        _packedAllowanceFor;

    /// @notice Stores addresses that are allowed to post onto an NFT category.
    /// @custom:param _projectId The ID of the project.
    /// @custom:param _nft The NFT contract for which this allowance applies.
    /// @custom:param _category The category for which the allowance applies.
    /// @custom:param _address The address to check an allowance for.
    mapping(uint256 _projectId => mapping(address _nft => mapping(uint256 _category => address[]))) internal
        _allowedAddresses;

    /// @notice The ID of the tier that an IPFS metadata has been saved to.
    /// @custom:param _projectId The ID of the project.
    /// @custom:param _encodedIPFSUri The IPFS URI.
    mapping(uint256 _projectId => mapping(bytes32 _encodedIPFSUri => uint256)) public tierIdForEncodedIPFSUriOf;

    /// @notice The divisor that describes the fee that should be taken.
    /// @dev This is equal to 100 divided by the fee percent.
    uint256 public feeDivisor = 20;

    /// @notice The controller that directs the projects being posted to.
    IJBController3_1 public controller;

    /// @notice The ID of the project to which fees will be routed.
    uint256 public feeProjectId;

    /// @notice Get the tiers for the provided encoded IPFS URIs.
    /// @param _projectId The ID of the project from which the tiers are being sought.
    /// @param _nft The NFT from which to get tiers.
    /// @param _encodedIPFSUris The URIs to get tiers of.
    /// @return tiers The tiers that correspond to the provided encoded IPFS URIs. If there's no tier yet, an empty tier is returned.
    function tiersFor(uint256 _projectId, address _nft, bytes32[] memory _encodedIPFSUris)
        external
        view
        returns (JB721Tier[] memory tiers)
    {
        uint256 _numberOfEncodedIPFSUris = _encodedIPFSUris.length;

        // Initialize the tier array being returned.
        tiers = new JB721Tier[](_numberOfEncodedIPFSUris);

        if (_nft == address(0)) {
            // Get the projects current data source from its current funding cyce's metadata.
            (, JBFundingCycleMetadata memory _metadata) = controller.currentFundingCycleOf(_projectId);

            // Set the NFT as the data source.
            _nft = _metadata.dataSource;
        }

        // Get the tier for each provided encoded IPFS URI.
        for (uint256 _i; _i < _numberOfEncodedIPFSUris;) {
            // Check if there's a tier ID stored for the encoded IPFS URI.
            uint256 _tierId = tierIdForEncodedIPFSUriOf[_projectId][_encodedIPFSUris[_i]];

            // If there's a tier ID stored, resolve it.
            if (_tierId != 0) {
                tiers[_i] = IJBTiered721Delegate(_nft).store().tierOf(_nft, _tierId, false);
            }

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice Post allowances for a particular category on a particular NFT.
    /// @param _projectId The ID of the project.
    /// @param _nft The NFT contract for which this allowance applies.
    /// @param _category The category for which this allowance applies.
    /// @return minimumPrice The minimum price that a poster must pay to record a new NFT.
    /// @return minimumTotalSupply The minimum total number of available tokens that a minter must set to record a new NFT.
    /// @return maximumTotalSupply The max total supply of NFTs that can be made available when minting. Leave as 0 for max.
    /// @return allowedAddresses The addresses allowed to post. Returns empty if all addresses are allowed.
    function allowanceFor(uint256 _projectId, address _nft, uint256 _category)
        public
        view
        returns (
            uint256 minimumPrice,
            uint256 minimumTotalSupply,
            uint256 maximumTotalSupply,
            address[] memory allowedAddresses
        )
    {
        if (_nft == address(0)) {
            // Get the projects current data source from its current funding cyce's metadata.
            (, JBFundingCycleMetadata memory _metadata) = controller.currentFundingCycleOf(_projectId);

            // Set the NFT as the data source.
            _nft = _metadata.dataSource;
        }

        // Get a reference to the packed values.
        uint256 _packed = _packedAllowanceFor[_projectId][_nft][_category];

        // minimum price in bits 0-103 (104 bits).
        minimumPrice = uint256(uint104(_packed));
        // minimum supply in bits 104-135 (32 bits).
        minimumTotalSupply = uint256(uint32(_packed >> 104));
        // minimum supply in bits 136-67 (32 bits).
        maximumTotalSupply = uint256(uint32(_packed >> 136));

        allowedAddresses = _allowedAddresses[_projectId][_nft][_category];
    }

    /// @param _controller The controller that directs the projects being posted to.
    /// @param _feeProjectId The ID of the project to which fees will be routed.
    constructor(IJBController3_1 _controller, uint256 _feeProjectId) {
        controller = _controller;
        feeProjectId = _feeProjectId;
    }

    /// @notice Publish an NFT to become mintable, and mint a first copy.
    /// @dev A fee is taken into the appropriate treasury.
    /// @param _projectId The ID of the project to which the NFT should be added.
    /// @param _posts An array of posts that should be published as NFTs to the specified project.
    /// @param _nftBeneficiary The beneficiary of the NFT mints.
    /// @param _feeBeneficiary The beneficiary of the fee project's token.
    /// @param _nftMetadataChunk 32 bytes that should be included in the pay function's metadata.
    /// @param _feeMetadata The metadata to send alongside the fee payment.
    function collectFrom(uint256 _projectId, Post[] memory _posts, address _nftBeneficiary, address _feeBeneficiary, bytes32 _nftMetadataChunk, bytes calldata _feeMetadata)
        external
        payable
    {
        // Keep a reference to the project terminal.
        IJBPaymentTerminal _projectTerminal; 

        // Keep a reference a reference to the fee.
        uint256 _fee;

        // Keep a reference to the mint metadata.
        bytes memory _mintMetadata;

        {
          // Get the projects current data source from its current funding cyce's metadata.
          (, JBFundingCycleMetadata memory _metadata) = controller.currentFundingCycleOf(_projectId);

          // Check to make sure the project's current data source is a IJBTiered721Delegate.
          if (!IERC165(_metadata.dataSource).supportsInterface(type(IJBTiered721Delegate).interfaceId)) {
              revert INCOMPATIBLE_PROJECT(_projectId, _metadata.dataSource);
          }

          // Setup the posts.
          (JB721TierParams[] memory _tierDataToAdd, uint256[] memory _tierIdsToMint, uint256 _totalPrice) =
              _setupPosts(_projectId, _metadata.dataSource, _posts);

          // Keep a reference to the fee that will be paid.
          _fee = _projectId == feeProjectId ? 0 : (_totalPrice / feeDivisor);

          // Make sure the amount sent to this function is at least the specified price of the tier plus the fee.
          if (_totalPrice + _fee < msg.value) {
              revert INSUFFICIENT_ETH_SENT(_totalPrice, msg.value);
          }

          // Add the new tiers.
          IJBTiered721Delegate(_metadata.dataSource).adjustTiers(_tierDataToAdd, new uint256[](0));

          // Get a reference to the project's current ETH payment terminal.
          _projectTerminal = controller.directory().primaryTerminalOf(_projectId, JBTokens.ETH);

          // Create the metadata for the payment to specify the tier IDs that should be minted.
          _mintMetadata = abi.encode(
              bytes32(feeProjectId), // Referral project ID.
              _nftMetadataChunk,
              type(IJBTiered721Delegate).interfaceId,
              true, // Allow overspending.
              _tierIdsToMint
          );
        }

        // Make the payment.
        _projectTerminal.pay{value: msg.value - _fee}(
            _projectId, msg.value - _fee, JBTokens.ETH, _nftBeneficiary, 0, false, "Minted from Croptop", _mintMetadata
        );

        // Pay a fee if there are funds left.
        if (address(this).balance != 0) {
            // Get a reference to the fee project's current ETH payment terminal.
            IJBPaymentTerminal _feeTerminal = controller.directory().primaryTerminalOf(feeProjectId, JBTokens.ETH);

            // Make the fee payment.
            _feeTerminal.pay{value: address(this).balance}(
                feeProjectId, address(this).balance, JBTokens.ETH, _feeBeneficiary, 0, false, "", _feeMetadata
            );
        }

        emit Collected(_projectId, _posts, _nftBeneficiary, _feeBeneficiary, _fee, msg.sender);
    }

    /// @notice Project owners can set the allowed criteria for publishing a new NFT to their project.
    /// @param _projectId The ID of the project having its publishing allowances set.
    /// @param _allowedPosts An array of criteria for allowed posts.
    function configureFor(uint256 _projectId, AllowedPost[] memory _allowedPosts) public {
        // Make sure the caller is the owner of the project.
        if (msg.sender != controller.projects().ownerOf(_projectId)) {
            revert UNAUTHORIZED();
        }

        // Get the projects current data source from its current funding cyce's metadata.
        (, JBFundingCycleMetadata memory _metadata) = controller.currentFundingCycleOf(_projectId);

        // Keep a reference to the number of post criteria.
        uint256 _numberOfAllowedPosts = _allowedPosts.length;

        // Keep a reference to the post criteria being iterated on.
        AllowedPost memory _allowedPost;

        // For each post criteria, save the specifications.
        for (uint256 _i; _i < _numberOfAllowedPosts;) {
            // Set the post criteria being iterated on.
            _allowedPost = _allowedPosts[_i];

            // Make sure there is a minimum supply.
            if (_allowedPost.minimumTotalSupply == 0) {
                revert TOTAL_SUPPY_MUST_BE_POSITIVE();
            }

            // Make sure there is a minimum supply.
            if (_allowedPost.minimumTotalSupply > _allowedPost.maximumTotalSupply) {
                revert MAX_TOTAL_SUPPLY_LESS_THAN_MIN();
            }

            // Set the _nft as the current data source if not set.
            if (_allowedPost.nft == address(0)) {
                _allowedPost.nft = _metadata.dataSource;
            }

            uint256 _packed;
            // minimum price in bits 0-103 (104 bits).
            _packed |= uint256(_allowedPost.minimumPrice);
            // minimum total supply in bits 104-135 (32 bits).
            _packed |= uint256(_allowedPost.minimumTotalSupply) << 104;
            // maximum total supply in bits 136-167 (32 bits).
            _packed |= uint256(_allowedPost.maximumTotalSupply) << 136;
            // Store the packed value.
            _packedAllowanceFor[_projectId][_allowedPost.nft][_allowedPost.category] = _packed;

            // Store the allow list.
            uint256 _numberOfAddresses = _allowedPost.allowedAddresses.length;
            // Reset the addresses.
            delete _allowedAddresses[_projectId][_allowedPost.nft][_allowedPost.category];
            // Add the number allowed addresses.
            if (_numberOfAddresses != 0) {
                // Keep a reference to the storage of the allowed addresses.
                for (uint256 _j = 0; _j < _numberOfAddresses;) {
                    _allowedAddresses[_projectId][_allowedPost.nft][_allowedPost.category].push(_allowedPost.allowedAddresses[_j]);
                    unchecked {
                        ++_j;
                    }
                }
            }

            unchecked {
                ++_i;
            }
        }
    }

    /// @notice Setup the posts.
    /// @param _projectId The ID of the project having posts set up.
    /// @param _nft The NFT address on which the posts will apply.
    /// @param _posts An array of posts that should be published as NFTs to the specified project.
    /// @return tierDataToAdd The tier data that will be created to represent the posts.
    /// @return tierIdsToMint The tier IDs of the posts that should be minted once published.
    /// @return totalPrice The total price being paid.
    function _setupPosts(uint256 _projectId, address _nft, Post[] memory _posts)
        internal
        returns (JB721TierParams[] memory tierDataToAdd, uint256[] memory tierIdsToMint, uint256 totalPrice)
    {
        // Keep a reference to the number of posts being published.
        uint256 _numberOfMints = _posts.length;

        // Set the max size of the tier data that will be added.
        tierDataToAdd = new JB721TierParams[](
                _numberOfMints
            );

        // Set the size of the tier IDs of the posts that should be minted once published.
        tierIdsToMint = new uint256[](_numberOfMints);

        // The tier ID that will be created, and the first one that should be minted from, is one more than the current max.
        uint256 _startingTierId = IJBTiered721Delegate(_nft).store().maxTierIdOf(_nft) + 1;

        // Keep a reference to the post being iterated on.
        Post memory _post;

        // Keep a reference to the total number of tiers being added.
        uint256 _numberOfTiersBeingAdded;

        // For each post, create tiers after validating to make sure they fulfill the allowance specified by the project's owner.
        for (uint256 _i; _i < _numberOfMints;) {
            // Get the current post being iterated on.
            _post = _posts[_i];

            // Make sure the post includes an encodedIPFSUri.
            if (_post.encodedIPFSUri == bytes32("")) {
                revert EMPTY_ENCODED_IPFS_URI(_post.encodedIPFSUri);
            }

            // Scoped section to prevent stack too deep.
            {
                // Check if there's an ID of a tier already minted for this encodedIPFSUri.
                uint256 _tierId = tierIdForEncodedIPFSUriOf[_projectId][_post.encodedIPFSUri];

                if (_tierId != 0) tierIdsToMint[_i] = _tierId;
            }

            // If no tier already exists, post the tier.
            if (tierIdsToMint[_i] == 0) {
                // Scoped error handling section to prevent Stack Too Deep.
                {
                    // Get references to the allowance.
                    (
                        uint256 _minimumPrice,
                        uint256 _minimumTotalSupply,
                        uint256 _maximumTotalSupply,
                        address[] memory _addresses
                    ) = allowanceFor(_projectId, _nft, _post.category);

                    // Make sure the category being posted to allows publishing.
                    if (_minimumTotalSupply == 0) {
                        revert UNAUTHORIZED_TO_POST_IN_CATEGORY();
                    }

                    // Make sure the price being paid for the post is at least the allowed minimum price.
                    if (_post.price < _minimumPrice) {
                        revert PRICE_TOO_SMALL(_minimumPrice);
                    }

                    // Make sure the total supply being made available for the post is at least the allowed minimum total supply.
                    if (_post.totalSupply < _minimumTotalSupply) {
                        revert TOTAL_SUPPLY_TOO_SMALL(_minimumTotalSupply);
                    }

                    // Make sure the total supply being made available for the post is at most the allowed maximum total supply.
                    if (_post.totalSupply > _maximumTotalSupply) {
                        revert TOTAL_SUPPLY_TOO_BIG(_maximumTotalSupply);
                    }

                    // Make sure the address is allowed to post.
                    if (_addresses.length != 0 && !_isAllowed(msg.sender, _addresses)) {
                        revert NOT_IN_ALLOW_LIST(_addresses);
                    }
                }

                // Set the tier.
                tierDataToAdd[_numberOfTiersBeingAdded] = JB721TierParams({
                    price: uint80(_post.price),
                    initialQuantity: _post.totalSupply,
                    votingUnits: 0,
                    reservedRate: 0,
                    reservedTokenBeneficiary: address(0),
                    encodedIPFSUri: _post.encodedIPFSUri,
                    category: uint8(_post.category),
                    allowManualMint: false,
                    shouldUseReservedTokenBeneficiaryAsDefault: false,
                    transfersPausable: false,
                    useVotingUnits: true
                });

                // Set the ID of the tier to mint.
                tierIdsToMint[_i] = _startingTierId + _numberOfTiersBeingAdded++;

                // Save the encodedIPFSUri as minted.
                tierIdForEncodedIPFSUriOf[_projectId][_post.encodedIPFSUri] = tierIdsToMint[_i];
            }

            // Increment the total price.
            totalPrice += _post.price;

            unchecked {
                ++_i;
            }
        }

        // Resize the array if there's a mismatch in length.
        if (_numberOfTiersBeingAdded != _numberOfMints) {
            assembly ("memory-safe") {
                mstore(tierDataToAdd, _numberOfTiersBeingAdded)
            }
        }
    }

    /// @notice Check if an address is included in an allow list.
    /// @param _address The candidate address.
    /// @param _addresses An array of allowed addresses.
    function _isAllowed(address _address, address[] memory _addresses) internal pure returns (bool) {
        uint256 _numberOfAddresses = _addresses.length;
        for (uint256 _i; _i < _numberOfAddresses;) {
            if (_address == _addresses[_i]) return true;
            unchecked {
                ++_i;
            }
        }
        return false;
    }
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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBPaymentTerminal.sol';

/** 
  @member terminal The terminal within which the distribution limit and the overflow allowance applies.
  @member token The token for which the fund access constraints apply.
  @member distributionLimit The amount of the distribution limit, as a fixed point number with the same number of decimals as the terminal within which the limit applies.
  @member distributionLimitCurrency The currency of the distribution limit.
  @member overflowAllowance The amount of the allowance, as a fixed point number with the same number of decimals as the terminal within which the allowance applies.
  @member overflowAllowanceCurrency The currency of the overflow allowance.
*/
struct JBFundAccessConstraints {
  IJBPaymentTerminal terminal;
  address token;
  uint256 distributionLimit;
  uint256 distributionLimitCurrency;
  uint256 overflowAllowance;
  uint256 overflowAllowanceCurrency;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
*/
struct JBFundingCycleData {
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBGlobalFundingCycleMetadata.sol';

/** 
  @member global Data used globally in non-migratable ecosystem contracts.
  @member reservedRate The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
  @member redemptionRate The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member ballotRedemptionRate The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member pausePay A flag indicating if the pay functionality should be paused during the funding cycle.
  @member pauseDistributions A flag indicating if the distribute functionality should be paused during the funding cycle.
  @member pauseRedeem A flag indicating if the redeem functionality should be paused during the funding cycle.
  @member pauseBurn A flag indicating if the burn functionality should be paused during the funding cycle.
  @member allowMinting A flag indicating if minting tokens should be allowed during this funding cycle.
  @member allowTerminalMigration A flag indicating if migrating terminals should be allowed during this funding cycle.
  @member allowControllerMigration A flag indicating if migrating controllers should be allowed during this funding cycle.
  @member holdFees A flag indicating if fees should be held during this funding cycle.
  @member preferClaimedTokenOverride A flag indicating if claimed tokens should always be prefered to unclaimed tokens when minting.
  @member useTotalOverflowForRedemptions A flag indicating if redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
  @member useDataSourceForPay A flag indicating if the data source should be used for pay transactions during this funding cycle.
  @member useDataSourceForRedeem A flag indicating if the data source should be used for redeem transactions during this funding cycle.
  @member dataSource The data source to use during this funding cycle.
  @member metadata Metadata of the metadata, up to uint8 in size.
*/
struct JBFundingCycleMetadata {
  JBGlobalFundingCycleMetadata global;
  uint256 reservedRate;
  uint256 redemptionRate;
  uint256 ballotRedemptionRate;
  bool pausePay;
  bool pauseDistributions;
  bool pauseRedeem;
  bool pauseBurn;
  bool allowMinting;
  bool allowTerminalMigration;
  bool allowControllerMigration;
  bool holdFees;
  bool preferClaimedTokenOverride;
  bool useTotalOverflowForRedemptions;
  bool useDataSourceForPay;
  bool useDataSourceForRedeem;
  address dataSource;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBSplit.sol';

/** 
  @member group The group indentifier.
  @member splits The splits to associate with the group.
*/
struct JBGroupedSplits {
  uint256 group;
  JBSplit[] splits;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBController.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBTokenStore.sol';

interface IJBController3_0_1 {
  function reservedTokenBalanceOf(uint256 _projectId) external view returns (uint256);
  function totalOutstandingTokensOf(uint256 _projectId) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBFundingCycleStore.sol';
import './IJBPaymentTerminal.sol';
import './IJBProjects.sol';

interface IJBDirectory {
  event SetController(uint256 indexed projectId, address indexed controller, address caller);

  event AddTerminal(uint256 indexed projectId, IJBPaymentTerminal indexed terminal, address caller);

  event SetTerminals(uint256 indexed projectId, IJBPaymentTerminal[] terminals, address caller);

  event SetPrimaryTerminal(
    uint256 indexed projectId,
    address indexed token,
    IJBPaymentTerminal indexed terminal,
    address caller
  );

  event SetIsAllowedToSetFirstController(address indexed addr, bool indexed flag, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function controllerOf(uint256 _projectId) external view returns (address);

  function isAllowedToSetFirstController(address _address) external view returns (bool);

  function terminalsOf(uint256 _projectId) external view returns (IJBPaymentTerminal[] memory);

  function isTerminalOf(uint256 _projectId, IJBPaymentTerminal _terminal)
    external
    view
    returns (bool);

  function primaryTerminalOf(uint256 _projectId, address _token)
    external
    view
    returns (IJBPaymentTerminal);

  function setControllerOf(uint256 _projectId, address _controller) external;

  function setTerminalsOf(uint256 _projectId, IJBPaymentTerminal[] calldata _terminals) external;

  function setPrimaryTerminalOf(
    uint256 _projectId,
    address _token,
    IJBPaymentTerminal _terminal
  ) external;

  function setIsAllowedToSetFirstController(address _address, bool _flag) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './IJBPaymentTerminal.sol';

interface IJBFundAccessConstraintsStore is IERC165 {
  event SetFundAccessConstraints(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed projectId,
    JBFundAccessConstraints constraints,
    address caller
  );

  function distributionLimitOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function setFor(
    uint256 _projectId,
    uint256 _configuration,
    JBFundAccessConstraints[] memory _fundAccessConstaints
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../enums/JBBallotState.sol';
import './../structs/JBFundingCycle.sol';
import './../structs/JBFundingCycleData.sol';

interface IJBFundingCycleStore {
  event Configure(
    uint256 indexed configuration,
    uint256 indexed projectId,
    JBFundingCycleData data,
    uint256 metadata,
    uint256 mustStartAtOrAfter,
    address caller
  );

  event Init(uint256 indexed configuration, uint256 indexed projectId, uint256 indexed basedOn);

  function latestConfigurationOf(uint256 _projectId) external view returns (uint256);

  function get(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory);

  function latestConfiguredOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBBallotState ballotState);

  function queuedOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentOf(uint256 _projectId) external view returns (JBFundingCycle memory fundingCycle);

  function currentBallotStateOf(uint256 _projectId) external view returns (JBBallotState);

  function configureFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    uint256 _metadata,
    uint256 _mustStartAtOrAfter
  ) external returns (JBFundingCycle memory fundingCycle);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBMigratable {
  function prepForMigrationOf(uint256 _projectId, address _from) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';

interface IJBPaymentTerminal is IERC165 {
  function acceptsToken(address _token, uint256 _projectId) external view returns (bool);

  function currencyForToken(address _token) external view returns (uint256);

  function decimalsForToken(address _token) external view returns (uint256);

  // Return value must be a fixed point number with 18 decimals.
  function currentEthOverflowOf(uint256 _projectId) external view returns (uint256);

  function pay(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    address _beneficiary,
    uint256 _minReturnedTokens,
    bool _preferClaimedTokens,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable returns (uint256 beneficiaryTokenCount);

  function addToBalanceOf(
    uint256 _projectId,
    uint256 _amount,
    address _token,
    string calldata _memo,
    bytes calldata _metadata
  ) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../structs/JBGroupedSplits.sol';
import './../structs/JBSplit.sol';
import './IJBDirectory.sol';
import './IJBProjects.sol';

interface IJBSplitsStore {
  event SetSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    address caller
  );

  function projects() external view returns (IJBProjects);

  function directory() external view returns (IJBDirectory);

  function splitsOf(
    uint256 _projectId,
    uint256 _domain,
    uint256 _group
  ) external view returns (JBSplit[] memory);

  function set(
    uint256 _projectId,
    uint256 _domain,
    JBGroupedSplits[] memory _groupedSplits
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBFundingCycleStore.sol';
import './IJBProjects.sol';
import './IJBToken.sol';

interface IJBTokenStore {
  event Issue(
    uint256 indexed projectId,
    IJBToken indexed token,
    string name,
    string symbol,
    address caller
  );

  event Mint(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    bool tokensWereClaimed,
    bool preferClaimedTokens,
    address caller
  );

  event Burn(
    address indexed holder,
    uint256 indexed projectId,
    uint256 amount,
    uint256 initialUnclaimedBalance,
    uint256 initialClaimedBalance,
    bool preferClaimedTokens,
    address caller
  );

  event Claim(
    address indexed holder,
    uint256 indexed projectId,
    uint256 initialUnclaimedBalance,
    uint256 amount,
    address caller
  );

  event Set(uint256 indexed projectId, IJBToken indexed newToken, address caller);

  event Transfer(
    address indexed holder,
    uint256 indexed projectId,
    address indexed recipient,
    uint256 amount,
    address caller
  );

  function tokenOf(uint256 _projectId) external view returns (IJBToken);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function unclaimedBalanceOf(address _holder, uint256 _projectId) external view returns (uint256);

  function unclaimedTotalSupplyOf(uint256 _projectId) external view returns (uint256);

  function totalSupplyOf(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _holder, uint256 _projectId) external view returns (uint256 _result);

  function issueFor(
    uint256 _projectId,
    string calldata _name,
    string calldata _symbol
  ) external returns (IJBToken token);

  function setFor(uint256 _projectId, IJBToken _token) external;

  function burnFrom(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function mintFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount,
    bool _preferClaimedTokens
  ) external;

  function claimFor(
    address _holder,
    uint256 _projectId,
    uint256 _amount
  ) external;

  function transferFrom(
    address _holder,
    uint256 _projectId,
    address _recipient,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBTokenUriResolver.sol';

interface IJBProjects is IERC721 {
  event Create(
    uint256 indexed projectId,
    address indexed owner,
    JBProjectMetadata metadata,
    address caller
  );

  event SetMetadata(uint256 indexed projectId, JBProjectMetadata metadata, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed resolver, address caller);

  function count() external view returns (uint256);

  function metadataContentOf(uint256 _projectId, uint256 _domain)
    external
    view
    returns (string memory);

  function tokenUriResolver() external view returns (IJBTokenUriResolver);

  function createFor(address _owner, JBProjectMetadata calldata _metadata)
    external
    returns (uint256 projectId);

  function setMetadataOf(uint256 _projectId, JBProjectMetadata calldata _metadata) external;

  function setTokenUriResolver(IJBTokenUriResolver _newResolver) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleStore.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol';
import './../enums/JB721GovernanceType.sol';
import './../interfaces/IJBTiered721DelegateStore.sol';
import './JB721PricingParams.sol';
import './JBTiered721Flags.sol';

/**
  @member name The name of the token.
  @member symbol The symbol that the token should be represented by.
  @member fundingCycleStore A contract storing all funding cycle configurations.
  @member baseUri A URI to use as a base for full token URIs.
  @member tokenUriResolver A contract responsible for resolving the token URI for each token ID.
  @member contractUri A URI where contract metadata can be found. 
  @member owner The address that should own this contract.
  @member pricing The tier pricing according to which token distribution will be made. 
  @member reservedTokenBeneficiary The address receiving the reserved token
  @member store The store contract to use.
  @member flags A set of flags that help define how this contract works.
  @member governanceType The type of governance to allow the NFTs to be used for.
*/
struct JBDeployTiered721DelegateData {
  string name;
  string symbol;
  IJBFundingCycleStore fundingCycleStore;
  string baseUri;
  IJBTokenUriResolver tokenUriResolver;
  string contractUri;
  address owner;
  JB721PricingParams pricing;
  address reservedTokenBeneficiary;
  IJBTiered721DelegateStore store;
  JBTiered721Flags flags;
  JB721GovernanceType governanceType;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBProjectMetadata.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundingCycleData.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundAccessConstraints.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBGroupedSplits.sol';
import './JBPayDataSourceFundingCycleMetadata.sol';

/**
  @member projectMetadata Metadata to associate with the project within a particular domain. This can be updated any time by the owner of the project.
  @member data Data that defines the project's first funding cycle. These properties will remain fixed for the duration of the funding cycle.
  @member metadata Metadata specifying the controller specific params that a funding cycle can have. These properties will remain fixed for the duration of the funding cycle.
  @member mustStartAtOrAfter The time before which the configured funding cycle cannot start.
  @member groupedSplits An array of splits to set for any number of groups. 
  @member fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
  @member terminals Payment terminals to add for the project.
  @member memo A memo to pass along to the emitted event.
*/
struct JBLaunchProjectData {
  JBProjectMetadata projectMetadata;
  JBFundingCycleData data;
  JBPayDataSourceFundingCycleMetadata metadata;
  uint256 mustStartAtOrAfter;
  JBGroupedSplits[] groupedSplits;
  JBFundAccessConstraints[] fundAccessConstraints;
  IJBPaymentTerminal[] terminals;
  string memo;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPaymentTerminal.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundingCycleData.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundAccessConstraints.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBGroupedSplits.sol';
import './JBPayDataSourceFundingCycleMetadata.sol';

/**
  @member data Data that defines the project's first funding cycle. These properties will remain fixed for the duration of the funding cycle.
  @member metadata Metadata specifying the controller specific params that a funding cycle can have. These properties will remain fixed for the duration of the funding cycle.
  @member mustStartAtOrAfter The time before which the configured funding cycle cannot start.
  @member groupedSplits An array of splits to set for any number of groups. 
  @member fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
  @member terminals Payment terminals to add for the project.
  @member memo A memo to pass along to the emitted event.
*/
struct JBLaunchFundingCyclesData {
  JBFundingCycleData data;
  JBPayDataSourceFundingCycleMetadata metadata;
  uint256 mustStartAtOrAfter;
  JBGroupedSplits[] groupedSplits;
  JBFundAccessConstraints[] fundAccessConstraints;
  IJBPaymentTerminal[] terminals;
  string memo;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundingCycleData.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBFundAccessConstraints.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBGroupedSplits.sol';
import './JBPayDataSourceFundingCycleMetadata.sol';

/**
  @member data Data that defines the project's first funding cycle. These properties will remain fixed for the duration of the funding cycle.
  @member metadata Metadata specifying the controller specific params that a funding cycle can have. These properties will remain fixed for the duration of the funding cycle.
  @member mustStartAtOrAfter The time before which the configured funding cycle cannot start.
  @member groupedSplits An array of splits to set for any number of groups. 
  @member fundAccessConstraints An array containing amounts that a project can use from its treasury for each payment terminal. Amounts are fixed point numbers using the same number of decimals as the accompanying terminal. The `_distributionLimit` and `_overflowAllowance` parameters must fit in a `uint232`.
  @member terminals Payment terminals to add for the project.
  @member memo A memo to pass along to the emitted event.
*/
struct JBReconfigureFundingCyclesData {
  JBFundingCycleData data;
  JBPayDataSourceFundingCycleMetadata metadata;
  uint256 mustStartAtOrAfter;
  JBGroupedSplits[] groupedSplits;
  JBFundAccessConstraints[] fundAccessConstraints;
  string memo;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '../enums/JB721GovernanceType.sol';
import '../structs/JBDeployTiered721DelegateData.sol';
import './IJBTiered721Delegate.sol';

interface IJBTiered721DelegateDeployer {
  event DelegateDeployed(
    uint256 indexed projectId,
    IJBTiered721Delegate newDelegate,
    JB721GovernanceType governanceType,
    IJBDirectory directory
  );

  function deployDelegateFor(
    uint256 _projectId,
    JBDeployTiered721DelegateData memory _deployTieredNFTRewardDelegateData,
    IJBDirectory _directory
  ) external returns (IJBTiered721Delegate delegate);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library JBTokens {
  /** 
    @notice 
    The ETH token address in Juicebox is represented by 0x000000000000000000000000000000000000EEEe.
  */
  address public constant ETH = address(0x000000000000000000000000000000000000EEEe);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBFundingCycleStore.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPrices.sol';
import './../structs/JB721PricingParams.sol';
import './../structs/JB721TierParams.sol';
import './../structs/JBTiered721MintReservesForTiersData.sol';
import './../structs/JBTiered721MintForTiersData.sol';
import './IJB721Delegate.sol';
import './IJBTiered721DelegateStore.sol';

interface IJBTiered721Delegate is IJB721Delegate {
  event Mint(
    uint256 indexed tokenId,
    uint256 indexed tierId,
    address indexed beneficiary,
    uint256 totalAmountContributed,
    address caller
  );

  event MintReservedToken(
    uint256 indexed tokenId,
    uint256 indexed tierId,
    address indexed beneficiary,
    address caller
  );

  event AddTier(uint256 indexed tierId, JB721TierParams data, address caller);

  event RemoveTier(uint256 indexed tierId, address caller);

  event SetDefaultReservedTokenBeneficiary(address indexed beneficiary, address caller);

  event SetEncodedIPFSUri(uint256 indexed tierId, bytes32 encodedIPFSUri, address caller);

  event SetBaseUri(string indexed baseUri, address caller);

  event SetContractUri(string indexed contractUri, address caller);

  event SetTokenUriResolver(IJBTokenUriResolver indexed newResolver, address caller);

  event AddCredits(
    uint256 indexed changeAmount,
    uint256 indexed newTotalCredits,
    address indexed account,
    address caller
  );

  event UseCredits(
    uint256 indexed changeAmount,
    uint256 indexed newTotalCredits,
    address indexed account,
    address caller
  );

  function codeOrigin() external view returns (address);

  function store() external view returns (IJBTiered721DelegateStore);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);
  
  function pricingContext() external view returns (uint256, uint256, IJBPrices);

  function creditsOf(address _address) external view returns (uint256);

  function firstOwnerOf(uint256 _tokenId) external view returns (address);

  function baseURI() external view returns (string memory);

  function contractURI() external view returns (string memory);

  function adjustTiers(
    JB721TierParams[] memory _tierDataToAdd,
    uint256[] memory _tierIdsToRemove
  ) external;

  function mintReservesFor(
    JBTiered721MintReservesForTiersData[] memory _mintReservesForTiersData
  ) external;

  function mintReservesFor(uint256 _tierId, uint256 _count) external;

  function mintFor(
    uint16[] calldata _tierIds,
    address _beneficiary
  ) external returns (uint256[] memory tokenIds);

  function setMetadata(
    string memory _baseUri,
    string calldata _contractMetadataUri,
    IJBTokenUriResolver _tokenUriResolver,
    uint256 _encodedIPFSUriTierId,
    bytes32 _encodedIPFSUri
  ) external;

  function initialize(
    uint256 _projectId,
    IJBDirectory _directory,
    string memory _name,
    string memory _symbol,
    IJBFundingCycleStore _fundingCycleStore,
    string memory _baseUri,
    IJBTokenUriResolver _tokenUriResolver,
    string memory _contractUri,
    JB721PricingParams memory _pricing,
    IJBTiered721DelegateStore _store,
    JBTiered721Flags memory _flags
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../enums/JBBallotState.sol';

interface IJBFundingCycleBallot is IERC165 {
  function duration() external view returns (uint256);

  function stateOf(
    uint256 _projectId,
    uint256 _configuration,
    uint256 _start
  ) external view returns (JBBallotState);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member allowSetTerminals A flag indicating if setting terminals should be allowed during this funding cycle.
  @member allowSetController A flag indicating if setting a new controller should be allowed during this funding cycle.
  @member pauseTransfers A flag indicating if the project token transfer functionality should be paused during the funding cycle.
*/
struct JBGlobalFundingCycleMetadata {
  bool allowSetTerminals;
  bool allowSetController;
  bool pauseTransfers;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBSplitAllocator.sol';

/** 
  @member preferClaimed A flag that only has effect if a projectId is also specified, and the project has a token contract attached. If so, this flag indicates if the tokens that result from making a payment to the project should be delivered claimed into the beneficiary's wallet, or unclaimed to save gas.
  @member preferAddToBalance A flag indicating if a distribution to a project should prefer triggering it's addToBalance function instead of its pay function.
  @member percent The percent of the whole group that this split occupies. This number is out of `JBConstants.SPLITS_TOTAL_PERCENT`.
  @member projectId The ID of a project. If an allocator is not set but a projectId is set, funds will be sent to the protocol treasury belonging to the project who's ID is specified. Resulting tokens will be routed to the beneficiary with the claimed token preference respected.
  @member beneficiary An address. The role the of the beneficary depends on whether or not projectId is specified, and whether or not an allocator is specified. If allocator is set, the beneficiary will be forwarded to the allocator for it to use. If allocator is not set but projectId is set, the beneficiary is the address to which the project's tokens will be sent that result from a payment to it. If neither allocator or projectId are set, the beneficiary is where the funds from the split will be sent.
  @member lockedUntil Specifies if the split should be unchangeable until the specified time, with the exception of extending the locked period.
  @member allocator If an allocator is specified, funds will be sent to the allocator contract along with all properties of this split.
*/
struct JBSplit {
  bool preferClaimed;
  bool preferAddToBalance;
  uint256 percent;
  uint256 projectId;
  address payable beneficiary;
  uint256 lockedUntil;
  IJBSplitAllocator allocator;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import './../structs/JBFundAccessConstraints.sol';
import './../structs/JBFundingCycleData.sol';
import './../structs/JBFundingCycleMetadata.sol';
import './../structs/JBGroupedSplits.sol';
import './../structs/JBProjectMetadata.sol';
import './IJBDirectory.sol';
import './IJBFundingCycleStore.sol';
import './IJBMigratable.sol';
import './IJBPaymentTerminal.sol';
import './IJBSplitsStore.sol';
import './IJBTokenStore.sol';

interface IJBController is IERC165 {
  event LaunchProject(uint256 configuration, uint256 projectId, string memo, address caller);

  event LaunchFundingCycles(uint256 configuration, uint256 projectId, string memo, address caller);

  event ReconfigureFundingCycles(
    uint256 configuration,
    uint256 projectId,
    string memo,
    address caller
  );

  event SetFundAccessConstraints(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    JBFundAccessConstraints constraints,
    address caller
  );

  event DistributeReservedTokens(
    uint256 indexed fundingCycleConfiguration,
    uint256 indexed fundingCycleNumber,
    uint256 indexed projectId,
    address beneficiary,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    address caller
  );

  event DistributeToReservedTokenSplit(
    uint256 indexed projectId,
    uint256 indexed domain,
    uint256 indexed group,
    JBSplit split,
    uint256 tokenCount,
    address caller
  );

  event MintTokens(
    address indexed beneficiary,
    uint256 indexed projectId,
    uint256 tokenCount,
    uint256 beneficiaryTokenCount,
    string memo,
    uint256 reservedRate,
    address caller
  );

  event BurnTokens(
    address indexed holder,
    uint256 indexed projectId,
    uint256 tokenCount,
    string memo,
    address caller
  );

  event Migrate(uint256 indexed projectId, IJBMigratable to, address caller);

  event PrepMigration(uint256 indexed projectId, address from, address caller);

  function projects() external view returns (IJBProjects);

  function fundingCycleStore() external view returns (IJBFundingCycleStore);

  function tokenStore() external view returns (IJBTokenStore);

  function splitsStore() external view returns (IJBSplitsStore);

  function directory() external view returns (IJBDirectory);

  function reservedTokenBalanceOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function distributionLimitOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 distributionLimit, uint256 distributionLimitCurrency);

  function overflowAllowanceOf(
    uint256 _projectId,
    uint256 _configuration,
    IJBPaymentTerminal _terminal,
    address _token
  ) external view returns (uint256 overflowAllowance, uint256 overflowAllowanceCurrency);

  function totalOutstandingTokensOf(uint256 _projectId, uint256 _reservedRate)
    external
    view
    returns (uint256);

  function getFundingCycleOf(uint256 _projectId, uint256 _configuration)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function latestConfiguredFundingCycleOf(uint256 _projectId)
    external
    view
    returns (
      JBFundingCycle memory,
      JBFundingCycleMetadata memory metadata,
      JBBallotState
    );

  function currentFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function queuedFundingCycleOf(uint256 _projectId)
    external
    view
    returns (JBFundingCycle memory fundingCycle, JBFundingCycleMetadata memory metadata);

  function launchProjectFor(
    address _owner,
    JBProjectMetadata calldata _projectMetadata,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 projectId);

  function launchFundingCyclesFor(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    IJBPaymentTerminal[] memory _terminals,
    string calldata _memo
  ) external returns (uint256 configuration);

  function reconfigureFundingCyclesOf(
    uint256 _projectId,
    JBFundingCycleData calldata _data,
    JBFundingCycleMetadata calldata _metadata,
    uint256 _mustStartAtOrAfter,
    JBGroupedSplits[] memory _groupedSplits,
    JBFundAccessConstraints[] memory _fundAccessConstraints,
    string calldata _memo
  ) external returns (uint256);

  function mintTokensOf(
    uint256 _projectId,
    uint256 _tokenCount,
    address _beneficiary,
    string calldata _memo,
    bool _preferClaimedTokens,
    bool _useReservedRate
  ) external returns (uint256 beneficiaryTokenCount);

  function burnTokensOf(
    address _holder,
    uint256 _projectId,
    uint256 _tokenCount,
    string calldata _memo,
    bool _preferClaimedTokens
  ) external;

  function distributeReservedTokensOf(uint256 _projectId, string memory _memo)
    external
    returns (uint256);

  function migrate(uint256 _projectId, IJBMigratable _to) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

enum JBBallotState {
  Active,
  Approved,
  Failed
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './../interfaces/IJBFundingCycleBallot.sol';

/** 
  @member number The funding cycle number for the cycle's project. Each funding cycle has a number that is an increment of the cycle that directly preceded it. Each project's first funding cycle has a number of 1.
  @member configuration The timestamp when the parameters for this funding cycle were configured. This value will stay the same for subsequent funding cycles that roll over from an originally configured cycle.
  @member basedOn The `configuration` of the funding cycle that was active when this cycle was created.
  @member start The timestamp marking the moment from which the funding cycle is considered active. It is a unix timestamp measured in seconds.
  @member duration The number of seconds the funding cycle lasts for, after which a new funding cycle will start. A duration of 0 means that the funding cycle will stay active until the project owner explicitly issues a reconfiguration, at which point a new funding cycle will immediately start with the updated properties. If the duration is greater than 0, a project owner cannot make changes to a funding cycle's parameters while it is active – any proposed changes will apply to the subsequent cycle. If no changes are proposed, a funding cycle rolls over to another one with the same properties but new `start` timestamp and a discounted `weight`.
  @member weight A fixed point number with 18 decimals that contracts can use to base arbitrary calculations on. For example, payment terminals can use this to determine how many tokens should be minted when a payment is received.
  @member discountRate A percent by how much the `weight` of the subsequent funding cycle should be reduced, if the project owner hasn't configured the subsequent funding cycle with an explicit `weight`. If it's 0, each funding cycle will have equal weight. If the number is 90%, the next funding cycle will have a 10% smaller weight. This weight is out of `JBConstants.MAX_DISCOUNT_RATE`.
  @member ballot An address of a contract that says whether a proposed reconfiguration should be accepted or rejected. It can be used to create rules around how a project owner can change funding cycle parameters over time.
  @member metadata Extra data that can be associated with a funding cycle.
*/
struct JBFundingCycle {
  uint256 number;
  uint256 configuration;
  uint256 basedOn;
  uint256 start;
  uint256 duration;
  uint256 weight;
  uint256 discountRate;
  IJBFundingCycleBallot ballot;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBToken {
  function projectId() external view returns (uint256);

  function decimals() external view returns (uint8);

  function totalSupply(uint256 _projectId) external view returns (uint256);

  function balanceOf(address _account, uint256 _projectId) external view returns (uint256);

  function mint(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function burn(
    uint256 _projectId,
    address _account,
    uint256 _amount
  ) external;

  function approve(
    uint256,
    address _spender,
    uint256 _amount
  ) external;

  function transfer(
    uint256 _projectId,
    address _to,
    uint256 _amount
  ) external;

  function transferFrom(
    uint256 _projectId,
    address _from,
    address _to,
    uint256 _amount
  ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
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
pragma solidity ^0.8.0;

interface IJBTokenUriResolver {
  function getUri(uint256 _projectId) external view returns (string memory tokenUri);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol';
import './../structs/JB721TierParams.sol';
import './../structs/JB721Tier.sol';
import './../structs/JBTiered721Flags.sol';

interface IJBTiered721DelegateStore {
  event CleanTiers(address indexed nft, address caller);

  function totalSupply(address _nft) external view returns (uint256);

  function balanceOf(address _nft, address _owner) external view returns (uint256);

  function maxTierIdOf(address _nft) external view returns (uint256);

  function tiersOf(
    address _nft,
    uint256[] calldata _categories,
    bool _includeResolvedUri,
    uint256 _startingSortIndex,
    uint256 _size
  ) external view returns (JB721Tier[] memory tiers);

  function tierOf(
    address _nft,
    uint256 _id,
    bool _includeResolvedUri
  ) external view returns (JB721Tier memory tier);

  function tierBalanceOf(
    address _nft,
    address _owner,
    uint256 _tier
  ) external view returns (uint256);

  function tierOfTokenId(
    address _nft,
    uint256 _tokenId,
    bool _includeResolvedUri
  ) external view returns (JB721Tier memory tier);

  function tierIdOfToken(uint256 _tokenId) external pure returns (uint256);

  function encodedIPFSUriOf(address _nft, uint256 _tierId) external view returns (bytes32);

  // function firstOwnerOf(address _nft, uint256 _tokenId) external view returns (address);

  function redemptionWeightOf(
    address _nft,
    uint256[] memory _tokenIds
  ) external view returns (uint256 weight);

  function totalRedemptionWeight(address _nft) external view returns (uint256 weight);

  function numberOfReservedTokensOutstandingFor(
    address _nft,
    uint256 _tierId
  ) external view returns (uint256);

  function numberOfReservesMintedFor(address _nft, uint256 _tierId) external view returns (uint256);

  function numberOfBurnedFor(address _nft, uint256 _tierId) external view returns (uint256);

  function isTierRemoved(address _nft, uint256 _tierId) external view returns (bool);

  function flagsOf(address _nft) external view returns (JBTiered721Flags memory);

  function votingUnitsOf(address _nft, address _account) external view returns (uint256 units);

  function tierVotingUnitsOf(
    address _nft,
    address _account,
    uint256 _tierId
  ) external view returns (uint256 units);

  function defaultReservedTokenBeneficiaryOf(address _nft) external view returns (address);

  function reservedTokenBeneficiaryOf(
    address _nft,
    uint256 _tierId
  ) external view returns (address);

  function tokenUriResolverOf(address _nft) external view returns (IJBTokenUriResolver);

  function encodedTierIPFSUriOf(address _nft, uint256 _tokenId) external view returns (bytes32);

  function recordAddTiers(
    JB721TierParams[] memory _tierData
  ) external returns (uint256[] memory tierIds);

  function recordMintReservesFor(
    uint256 _tierId,
    uint256 _count
  ) external returns (uint256[] memory tokenIds);

  function recordBurn(uint256[] memory _tokenIds) external;

  function recordMint(
    uint256 _amount,
    uint16[] calldata _tierIds,
    bool _isManualMint
  ) external returns (uint256[] memory tokenIds, uint256 leftoverAmount);

  function recordTransferForTier(uint256 _tierId, address _from, address _to) external;

  function recordRemoveTierIds(uint256[] memory _tierIds) external;

  function recordSetTokenUriResolver(IJBTokenUriResolver _resolver) external;

  function recordSetEncodedIPFSUriOf(uint256 _tierId, bytes32 _encodedIPFSUri) external;

  function recordFlags(JBTiered721Flags calldata _flag) external;

  function cleanTiers(address _nft) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBPrices.sol';
import './JB721TierParams.sol';

/**
  @member tiers The tiers to set.
  @member currency The currency that the tier contribution floors are denoted in.
  @member decimals The number of decimals included in the tier contribution floor fixed point numbers.
  @member prices A contract that exposes price feeds that can be used to resolved the value of a contributions that are sent in different currencies. Set to the zero address if payments must be made in `currency`.
*/
struct JB721PricingParams {
  JB721TierParams[] tiers;
  uint48 currency;
  uint48 decimals;
  IJBPrices prices;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member lockReservedTokenChanges A flag indicating if reserved tokens can change over time by adding new tiers with a reserved rate.
  @member lockVotingUnitChanges A flag indicating if voting unit expectations can change over time by adding new tiers with voting units.
  @member lockManualMintingChanges A flag indicating if manual minting expectations can change over time by adding new tiers with manual minting.
  @member preventOverspending A flag indicating if payments sending more than the value the NFTs being minted are worth should be reverted. 
*/
struct JBTiered721Flags {
  bool lockReservedTokenChanges;
  bool lockVotingUnitChanges;
  bool lockManualMintingChanges;
  bool preventOverspending;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/structs/JBGlobalFundingCycleMetadata.sol';

/** 
  @member global Data used globally in non-migratable ecosystem contracts.
  @member reservedRate The reserved rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_RESERVED_RATE`.
  @member redemptionRate The redemption rate of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member ballotRedemptionRate The redemption rate to use during an active ballot of the funding cycle. This number is a percentage calculated out of `JBConstants.MAX_REDEMPTION_RATE`.
  @member pausePay A flag indicating if the pay functionality should be paused during the funding cycle.
  @member pauseDistributions A flag indicating if the distribute functionality should be paused during the funding cycle.
  @member pauseRedeem A flag indicating if the redeem functionality should be paused during the funding cycle.
  @member pauseBurn A flag indicating if the burn functionality should be paused during the funding cycle.
  @member allowMinting A flag indicating if minting tokens should be allowed during this funding cycle.
  @member allowTerminalMigration A flag indicating if migrating terminals should be allowed during this funding cycle.
  @member allowControllerMigration A flag indicating if migrating controllers should be allowed during this funding cycle.
  @member holdFees A flag indicating if fees should be held during this funding cycle.
  @member preferClaimedTokenOverride A flag indicating if claimed tokens should always be prefered to unclaimed tokens when minting.
  @member useTotalOverflowForRedemptions A flag indicating if redemptions should use the project's balance held in all terminals instead of the project's local terminal balance from which the redemption is being fulfilled.
  @member useDataSourceForRedeem A flag indicating if the data source should be used for redeem transactions during this funding cycle.
  @member metadata Metadata of the metadata, up to uint8 in size.
*/
struct JBPayDataSourceFundingCycleMetadata {
  JBGlobalFundingCycleMetadata global;
  uint256 reservedRate;
  uint256 redemptionRate;
  uint256 ballotRedemptionRate;
  bool pausePay;
  bool pauseDistributions;
  bool pauseRedeem;
  bool pauseBurn;
  bool allowMinting;
  bool allowTerminalMigration;
  bool allowControllerMigration;
  bool holdFees;
  bool preferClaimedTokenOverride;
  bool useTotalOverflowForRedemptions;
  bool useDataSourceForRedeem;
  uint256 metadata;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './IJBPriceFeed.sol';

interface IJBPrices {
  event AddFeed(uint256 indexed currency, uint256 indexed base, IJBPriceFeed feed);

  function feedFor(uint256 _currency, uint256 _base) external view returns (IJBPriceFeed);

  function priceFor(
    uint256 _currency,
    uint256 _base,
    uint256 _decimals
  ) external view returns (uint256);

  function addFeedFor(
    uint256 _currency,
    uint256 _base,
    IJBPriceFeed _priceFeed
  ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
  @member price The minimum contribution to qualify for this tier.
  @member initialQuantity The initial `remainingAllowance` value when the tier was set.
  @member votingUnits The amount of voting significance to give this tier compared to others.
  @member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
  @member reservedRateBeneficiary The beneificary of the reserved tokens for this tier.
  @member encodedIPFSUri The URI to use for each token within the tier.
  @member category A category to group NFT tiers by.
  @member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
  @member shouldUseReservedRateBeneficiaryAsDefault A flag indicating if the `reservedTokenBeneficiary` should be stored as the default beneficiary for all tiers.
  @member transfersPausable A flag indicating if transfers from this tier can be pausable. 
  @member useVotingUnits A flag indicating if the voting units override should be used over the price as the tier's voting units.
*/
struct JB721TierParams {
  uint104 price;
  uint32 initialQuantity;
  uint32 votingUnits;
  uint16 reservedRate;
  address reservedTokenBeneficiary;
  bytes32 encodedIPFSUri;
  uint24 category;
  bool allowManualMint;
  bool shouldUseReservedTokenBeneficiaryAsDefault;
  bool transfersPausable;
  bool useVotingUnits;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member tierId The ID of the tier to mint within.
  @member count The number of reserved tokens to mint. 
*/
struct JBTiered721MintReservesForTiersData {
  uint256 tierId;
  uint256 count;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/** 
  @member tierIds The IDs of the tier to mint within.
  @member beneficiary The beneficiary to mint for. 
*/
struct JBTiered721MintForTiersData {
  uint16[] tierIds;
  address beneficiary;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBDirectory.sol';
import '@jbx-protocol/juice-contracts-v3/contracts/interfaces/IJBTokenUriResolver.sol';

interface IJB721Delegate {
  function projectId() external view returns (uint256);

  function directory() external view returns (IJBDirectory);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '../structs/JBSplitAllocationData.sol';

/**
  @title
  Split allocator

  @notice
  Provide a way to process a single split with extra logic

  @dev
  Adheres to:
  IERC165 for adequate interface integration

  @dev
  The contract address should be set as an allocator in the adequate split
*/
interface IJBSplitAllocator is IERC165 {
  /**
    @notice
    This function is called by JBPaymentTerminal.distributePayoutOf(..), during the processing of the split including it

    @dev
    Critical business logic should be protected by an appropriate access control. The token and/or eth are optimistically transfered
    to the allocator for its logic.
    
    @param _data the data passed by the terminal, as a JBSplitAllocationData struct:
                  address token;
                  uint256 amount;
                  uint256 decimals;
                  uint256 projectId;
                  uint256 group;
                  JBSplit split;
  */
  function allocate(JBSplitAllocationData calldata _data) external payable;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

/**
  @member id The tier's ID.
  @member price The price that must be paid to qualify for this tier.
  @member remainingQuantity Remaining number of tokens in this tier. Together with idCeiling this enables for consecutive, increasing token ids to be issued to contributors.
  @member initialQuantity The initial `remainingAllowance` value when the tier was set.
  @member votingUnits The amount of voting significance to give this tier compared to others.
  @member reservedRate The number of minted tokens needed in the tier to allow for minting another reserved token.
  @member reservedRateBeneficiary The beneificary of the reserved tokens for this tier.
  @member encodedIPFSUri The URI to use for each token within the tier.
  @member category A category to group NFT tiers by.
  @member allowManualMint A flag indicating if the contract's owner can mint from this tier on demand.
  @member transfersPausable A flag indicating if transfers from this tier can be pausable. 
  @member resolvedTokenUri A resolved token URI if a resolver is included for the NFT to which this tier belongs.
*/
struct JB721Tier {
  uint256 id;
  uint256 price;
  uint256 remainingQuantity;
  uint256 initialQuantity;
  uint256 votingUnits;
  uint256 reservedRate;
  address reservedTokenBeneficiary;
  bytes32 encodedIPFSUri;
  uint256 category;
  bool allowManualMint;
  bool transfersPausable;
  string resolvedUri;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IJBPriceFeed {
  function currentPrice(uint256 _targetDecimals) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './JBSplit.sol';

/** 
  @member token The token being sent to the split allocator.
  @member amount The amount being sent to the split allocator, as a fixed point number.
  @member decimals The number of decimals in the amount.
  @member projectId The project to which the split belongs.
  @member group The group to which the split belongs.
  @member split The split that caused the allocation.
*/
struct JBSplitAllocationData {
  address token;
  uint256 amount;
  uint256 decimals;
  uint256 projectId;
  uint256 group;
  JBSplit split;
}