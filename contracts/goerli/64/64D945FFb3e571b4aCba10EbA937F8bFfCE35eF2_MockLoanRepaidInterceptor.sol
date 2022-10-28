// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import "../interfaces/IBNFT.sol";
import "../interfaces/IBNFTRegistry.sol";
import "../interfaces/ILendPoolLoan.sol";
import "../interfaces/ILoanRepaidInterceptor.sol";
import "../interfaces/ILendPoolAddressesProvider.sol";

contract MockLoanRepaidInterceptor is ILoanRepaidInterceptor {
  ILendPoolAddressesProvider public addressProvider;

  bool public isBeforeHookCalled;
  bool public isAfterHookCalled;

  event BeforeHookCalled(address indexed nftAsset, uint256 nftTokenId);
  event AfterHookCalled(address indexed nftAsset, uint256 nftTokenId);

  constructor(address addressProvider_) {
    addressProvider = ILendPoolAddressesProvider(addressProvider_);
  }

  function addLoanRepaidInterceptor(address nftAddress, uint256 tokenId) public {
    ILendPoolLoan poolLoan = ILendPoolLoan(addressProvider.getLendPoolLoan());
    poolLoan.addLoanRepaidInterceptor(nftAddress, tokenId);
  }

  function deleteLoanRepaidInterceptor(address nftAddress, uint256 tokenId) public {
    ILendPoolLoan poolLoan = ILendPoolLoan(addressProvider.getLendPoolLoan());
    poolLoan.deleteLoanRepaidInterceptor(nftAddress, tokenId);
  }

  function resetCallState() public {
    isBeforeHookCalled = false;
    isAfterHookCalled = false;
  }

  function beforeLoanRepaid(address nftAsset, uint256 nftTokenId) public override returns (bool) {
    nftAsset;
    nftTokenId;
    isBeforeHookCalled = true;
    emit BeforeHookCalled(nftAsset, nftTokenId);
    return true;
  }

  function afterLoanRepaid(address nftAsset, uint256 nftTokenId) public override returns (bool) {
    nftAsset;
    nftTokenId;
    isAfterHookCalled = true;
    emit AfterHookCalled(nftAsset, nftTokenId);
    return true;
  }
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IBNFT {
  /**
   * @dev Emitted when an bNFT is initialized
   * @param underlyingAsset_ The address of the underlying asset
   **/
  event Initialized(address indexed underlyingAsset_);

  /**
   * @dev Emitted when the ownership is transferred
   * @param oldOwner The address of the old owner
   * @param newOwner The address of the new owner
   **/
  event OwnershipTransferred(address oldOwner, address newOwner);

  /**
   * @dev Emitted when the claim admin is updated
   * @param oldAdmin The address of the old admin
   * @param newAdmin The address of the new admin
   **/
  event ClaimAdminUpdated(address oldAdmin, address newAdmin);

  /**
   * @dev Emitted on mint
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address receive the bNFT token
   **/
  event Mint(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on burn
   * @param user The address initiating the burn
   * @param nftAsset address of the underlying asset of NFT
   * @param nftTokenId token id of the underlying asset of NFT
   * @param owner The owner address of the burned bNFT token
   **/
  event Burn(address indexed user, address indexed nftAsset, uint256 nftTokenId, address indexed owner);

  /**
   * @dev Emitted on flashLoan
   * @param target The address of the flash loan receiver contract
   * @param initiator The address initiating the flash loan
   * @param nftAsset address of the underlying asset of NFT
   * @param tokenId The token id of the asset being flash borrowed
   **/
  event FlashLoan(address indexed target, address indexed initiator, address indexed nftAsset, uint256 tokenId);

  event ClaimERC20Airdrop(address indexed token, address indexed to, uint256 amount);

  event ClaimERC721Airdrop(address indexed token, address indexed to, uint256[] ids);

  event ClaimERC1155Airdrop(address indexed token, address indexed to, uint256[] ids, uint256[] amounts, bytes data);

  event ExecuteAirdrop(address indexed airdropContract);

  event FlashLoanApprovalForAll(address indexed owner, address indexed operator, bool approved);

  /**
   * @dev Initializes the bNFT
   * @param underlyingAsset_ The address of the underlying asset of this bNFT (E.g. PUNK for bPUNK)
   */
  function initialize(
    address underlyingAsset_,
    string calldata bNftName,
    string calldata bNftSymbol,
    address owner_,
    address claimAdmin_
  ) external;

  /**
   * @dev Mints bNFT token to the user address
   *
   * Requirements:
   *  - The caller can be contract address and EOA.
   *  - `nftTokenId` must not exist.
   *
   * @param to The owner address receive the bNFT token
   * @param tokenId token id of the underlying asset of NFT
   **/
  function mint(address to, uint256 tokenId) external;

  /**
   * @dev Burns user bNFT token
   *
   * Requirements:
   *  - The caller can be contract address and EOA.
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   **/
  function burn(uint256 tokenId) external;

  /**
   * @dev Allows smartcontracts to access the tokens within one transaction, as long as the tokens taken is returned.
   *
   * Requirements:
   *  - `nftTokenIds` must exist.
   *
   * @param receiverAddress The address of the contract receiving the tokens, implementing the IFlashLoanReceiver interface
   * @param nftTokenIds token ids of the underlying asset
   * @param params Variadic packed params to pass to the receiver as extra information
   */
  function flashLoan(
    address receiverAddress,
    uint256[] calldata nftTokenIds,
    bytes calldata params
  ) external;

  /**
   * @dev Approve or remove the flash loan `operator` as an operator for the caller.
   * Operators can call {flashLoan} for any token owned by the caller.
   *
   * Requirements:
   *
   * - The `operator` cannot be the caller.
   */
  function setFlashLoanApprovalForAll(address operator, bool approved) external;

  /**
   * @dev Returns if the `operator` is allowed to call flash loan of the assets of `owner`.
   */
  function isFlashLoanApprovedForAll(address owner, address operator) external view returns (bool);

  function claimERC20Airdrop(
    address token,
    address to,
    uint256 amount
  ) external;

  function claimERC721Airdrop(
    address token,
    address to,
    uint256[] calldata ids
  ) external;

  function claimERC1155Airdrop(
    address token,
    address to,
    uint256[] calldata ids,
    uint256[] calldata amounts,
    bytes calldata data
  ) external;

  function executeAirdrop(address airdropContract, bytes calldata airdropParams) external;

  /**
   * @dev Returns the owner of the `nftTokenId` token.
   *
   * Requirements:
   *  - `tokenId` must exist.
   *
   * @param tokenId token id of the underlying asset of NFT
   */
  function minterOf(uint256 tokenId) external view returns (address);

  /**
   * @dev Returns the address of the underlying asset.
   */
  function underlyingAsset() external view returns (address);

  /**
   * @dev Returns the contract-level metadata.
   */
  function contractURI() external view returns (string memory);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface IBNFTRegistry {
  event Initialized(address genericImpl, string namePrefix, string symbolPrefix);
  event GenericImplementationUpdated(address genericImpl);
  event BNFTCreated(address indexed nftAsset, address bNftImpl, address bNftProxy, uint256 totals);
  event BNFTUpgraded(address indexed nftAsset, address bNftImpl, address bNftProxy, uint256 totals);
  event CustomeSymbolsAdded(address[] nftAssets, string[] symbols);
  event ClaimAdminUpdated(address oldAdmin, address newAdmin);

  function getBNFTAddresses(address nftAsset) external view returns (address bNftProxy, address bNftImpl);

  function getBNFTAddressesByIndex(uint16 index) external view returns (address bNftProxy, address bNftImpl);

  function getBNFTAssetList() external view returns (address[] memory);

  function allBNFTAssetLength() external view returns (uint256);

  function initialize(
    address genericImpl,
    string memory namePrefix_,
    string memory symbolPrefix_
  ) external;

  function setBNFTGenericImpl(address genericImpl) external;

  /**
   * @dev Create bNFT proxy and implement, then initialize it
   * @param nftAsset The address of the underlying asset of the BNFT
   **/
  function createBNFT(address nftAsset) external returns (address bNftProxy);

  /**
   * @dev Create bNFT proxy with already deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the BNFT
   * @param bNftImpl The address of the deployed implement of the BNFT
   **/
  function createBNFTWithImpl(address nftAsset, address bNftImpl) external returns (address bNftProxy);

  /**
   * @dev Update bNFT proxy to an new deployed implement, then initialize it
   * @param nftAsset The address of the underlying asset of the BNFT
   * @param bNftImpl The address of the deployed implement of the BNFT
   * @param encodedCallData The encoded function call.
   **/
  function upgradeBNFTWithImpl(
    address nftAsset,
    address bNftImpl,
    bytes memory encodedCallData
  ) external;

  function batchUpgradeBNFT(address[] calldata nftAssets) external;

  function batchUpgradeAllBNFT() external;

  /**
   * @dev Adding custom symbol for some special NFTs like CryptoPunks
   * @param nftAssets_ The addresses of the NFTs
   * @param symbols_ The custom symbols of the NFTs
   **/
  function addCustomeSymbols(address[] memory nftAssets_, string[] memory symbols_) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

import {DataTypes} from "../libraries/types/DataTypes.sol";

interface ILendPoolLoan {
  /**
   * @dev Emitted on initialization to share location of dependent notes
   * @param pool The address of the associated lend pool
   */
  event Initialized(address indexed pool);

  /**
   * @dev Emitted when a loan is created
   * @param user The address initiating the action
   */
  event LoanCreated(
    address indexed user,
    address indexed onBehalfOf,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is updated
   * @param user The address initiating the action
   */
  event LoanUpdated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is repaid by the borrower
   * @param user The address initiating the action
   */
  event LoanRepaid(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is auction by the liquidator
   * @param user The address initiating the action
   */
  event LoanAuctioned(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    uint256 amount,
    uint256 borrowIndex,
    address bidder,
    uint256 price,
    address previousBidder,
    uint256 previousPrice
  );

  /**
   * @dev Emitted when a loan is redeemed
   * @param user The address initiating the action
   */
  event LoanRedeemed(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amountTaken,
    uint256 borrowIndex
  );

  /**
   * @dev Emitted when a loan is liquidate by the liquidator
   * @param user The address initiating the action
   */
  event LoanLiquidated(
    address indexed user,
    uint256 indexed loanId,
    address nftAsset,
    uint256 nftTokenId,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  );

  event LoanRepaidInterceptorUpdated(address nftAsset, uint256 tokenId, address indexed interceptor, bool approved);

  function initNft(address nftAsset, address bNftAddress) external;

  /**
   * @dev Create store a loan object with some params
   * @param initiator The address of the user initiating the borrow
   * @param onBehalfOf The address receiving the loan
   */
  function createLoan(
    address initiator,
    address onBehalfOf,
    address nftAsset,
    uint256 nftTokenId,
    address bNftAddress,
    address reserveAsset,
    uint256 amount,
    uint256 borrowIndex
  ) external returns (uint256);

  /**
   * @dev Update the given loan with some params
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The loan must be in state Active
   * @param initiator The address of the user initiating the borrow
   */
  function updateLoan(
    address initiator,
    uint256 loanId,
    uint256 amountAdded,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Repay the given loan
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the repay
   * @param loanId The loan getting burned
   * @param bNftAddress The address of bNFT
   */
  function repayLoan(
    address initiator,
    uint256 loanId,
    address bNftAddress,
    uint256 amount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Auction the given loan
   *
   * Requirements:
   *  - The price must be greater than current highest price
   *  - The loan must be in state Active or Auction
   *
   * @param initiator The address of the user initiating the auction
   * @param loanId The loan getting auctioned
   * @param bidPrice The bid price of this auction
   */
  function auctionLoan(
    address initiator,
    uint256 loanId,
    address onBehalfOf,
    uint256 bidPrice,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Redeem the given loan with some params
   *
   * Requirements:
   *  - The caller must be a holder of the loan
   *  - The loan must be in state Auction
   * @param initiator The address of the user initiating the borrow
   */
  function redeemLoan(
    address initiator,
    uint256 loanId,
    uint256 amountTaken,
    uint256 borrowIndex
  ) external;

  /**
   * @dev Liquidate the given loan
   *
   * Requirements:
   *  - The caller must send in principal + interest
   *  - The loan must be in state Active
   *
   * @param initiator The address of the user initiating the auction
   * @param loanId The loan getting burned
   * @param bNftAddress The address of bNFT
   */
  function liquidateLoan(
    address initiator,
    uint256 loanId,
    address bNftAddress,
    uint256 borrowAmount,
    uint256 borrowIndex
  ) external;

  function approveLoanRepaidInterceptor(address interceptor, bool approved) external;

  function isLoanRepaidInterceptorApproved(address interceptor) external view returns (bool);

  function purgeLoanRepaidInterceptor(
    address nftAddress,
    uint256[] calldata tokenIds,
    address interceptor
  ) external;

  function addLoanRepaidInterceptor(address nftAsset, uint256 tokenId) external;

  function deleteLoanRepaidInterceptor(address nftAsset, uint256 tokenId) external;

  function getLoanRepaidInterceptors(address nftAsset, uint256 tokenId) external view returns (address[] memory);

  function borrowerOf(uint256 loanId) external view returns (address);

  function getCollateralLoanId(address nftAsset, uint256 nftTokenId) external view returns (uint256);

  function getLoan(uint256 loanId) external view returns (DataTypes.LoanData memory loanData);

  function getLoanCollateralAndReserve(uint256 loanId)
    external
    view
    returns (
      address nftAsset,
      uint256 nftTokenId,
      address reserveAsset,
      uint256 scaledAmount
    );

  function getLoanReserveBorrowScaledAmount(uint256 loanId) external view returns (address, uint256);

  function getLoanReserveBorrowAmount(uint256 loanId) external view returns (address, uint256);

  function getLoanHighestBid(uint256 loanId) external view returns (address, uint256);

  function getNftCollateralAmount(address nftAsset) external view returns (uint256);

  function getUserNftCollateralAmount(address user, address nftAsset) external view returns (uint256);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

interface ILoanRepaidInterceptor {
  /**
   * @dev Handles before the loan is repaid by the borrower
   * @param nftAsset The address of the underlying asset of the BNFT
   * @param nftTokenId The token id of the underlying asset of the BNFT
   **/
  function beforeLoanRepaid(address nftAsset, uint256 nftTokenId) external returns (bool);

  /**
   * @dev Handles after the loan is repaid by the borrower
   * @param nftAsset The address of the underlying asset of the BNFT
   * @param nftTokenId The token id of the underlying asset of the BNFT
   **/
  function afterLoanRepaid(address nftAsset, uint256 nftTokenId) external returns (bool);
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

/**
 * @title LendPoolAddressesProvider contract
 * @dev Main registry of addresses part of or connected to the protocol, including permissioned roles
 * - Acting also as factory of proxies and admin of those, so with right to change its implementations
 * - Owned by the Bend Governance
 * @author Bend
 **/
interface ILendPoolAddressesProvider {
  event MarketIdSet(string newMarketId);
  event LendPoolUpdated(address indexed newAddress, bytes encodedCallData);
  event ConfigurationAdminUpdated(address indexed newAddress);
  event EmergencyAdminUpdated(address indexed newAddress);
  event LendPoolConfiguratorUpdated(address indexed newAddress, bytes encodedCallData);
  event ReserveOracleUpdated(address indexed newAddress);
  event NftOracleUpdated(address indexed newAddress);
  event LendPoolLoanUpdated(address indexed newAddress, bytes encodedCallData);
  event ProxyCreated(bytes32 id, address indexed newAddress);
  event AddressSet(bytes32 id, address indexed newAddress, bool hasProxy, bytes encodedCallData);
  event BNFTRegistryUpdated(address indexed newAddress);
  event IncentivesControllerUpdated(address indexed newAddress);
  event UIDataProviderUpdated(address indexed newAddress);
  event BendDataProviderUpdated(address indexed newAddress);
  event WalletBalanceProviderUpdated(address indexed newAddress);

  function getMarketId() external view returns (string memory);

  function setMarketId(string calldata marketId) external;

  function setAddress(bytes32 id, address newAddress) external;

  function setAddressAsProxy(
    bytes32 id,
    address impl,
    bytes memory encodedCallData
  ) external;

  function getAddress(bytes32 id) external view returns (address);

  function getLendPool() external view returns (address);

  function setLendPoolImpl(address pool, bytes memory encodedCallData) external;

  function getLendPoolConfigurator() external view returns (address);

  function setLendPoolConfiguratorImpl(address configurator, bytes memory encodedCallData) external;

  function getPoolAdmin() external view returns (address);

  function setPoolAdmin(address admin) external;

  function getEmergencyAdmin() external view returns (address);

  function setEmergencyAdmin(address admin) external;

  function getReserveOracle() external view returns (address);

  function setReserveOracle(address reserveOracle) external;

  function getNFTOracle() external view returns (address);

  function setNFTOracle(address nftOracle) external;

  function getLendPoolLoan() external view returns (address);

  function setLendPoolLoanImpl(address loan, bytes memory encodedCallData) external;

  function getBNFTRegistry() external view returns (address);

  function setBNFTRegistry(address factory) external;

  function getIncentivesController() external view returns (address);

  function setIncentivesController(address controller) external;

  function getUIDataProvider() external view returns (address);

  function setUIDataProvider(address provider) external;

  function getBendDataProvider() external view returns (address);

  function setBendDataProvider(address provider) external;

  function getWalletBalanceProvider() external view returns (address);

  function setWalletBalanceProvider(address provider) external;
}

// SPDX-License-Identifier: agpl-3.0
pragma solidity 0.8.4;

library DataTypes {
  struct ReserveData {
    //stores the reserve configuration
    ReserveConfigurationMap configuration;
    //the liquidity index. Expressed in ray
    uint128 liquidityIndex;
    //variable borrow index. Expressed in ray
    uint128 variableBorrowIndex;
    //the current supply rate. Expressed in ray
    uint128 currentLiquidityRate;
    //the current variable borrow rate. Expressed in ray
    uint128 currentVariableBorrowRate;
    uint40 lastUpdateTimestamp;
    //tokens addresses
    address bTokenAddress;
    address debtTokenAddress;
    //address of the interest rate strategy
    address interestRateAddress;
    //the id of the reserve. Represents the position in the list of the active reserves
    uint8 id;
  }

  struct NftData {
    //stores the nft configuration
    NftConfigurationMap configuration;
    //address of the bNFT contract
    address bNftAddress;
    //the id of the nft. Represents the position in the list of the active nfts
    uint8 id;
    uint256 maxSupply;
    uint256 maxTokenId;
  }

  struct ReserveConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 48-55: Decimals
    //bit 56: Reserve is active
    //bit 57: reserve is frozen
    //bit 58: borrowing is enabled
    //bit 59: stable rate borrowing enabled
    //bit 60-63: reserved
    //bit 64-79: reserve factor
    uint256 data;
  }

  struct NftConfigurationMap {
    //bit 0-15: LTV
    //bit 16-31: Liq. threshold
    //bit 32-47: Liq. bonus
    //bit 56: NFT is active
    //bit 57: NFT is frozen
    uint256 data;
  }

  /**
   * @dev Enum describing the current state of a loan
   * State change flow:
   *  Created -> Active -> Repaid
   *                    -> Auction -> Defaulted
   */
  enum LoanState {
    // We need a default that is not 'Created' - this is the zero value
    None,
    // The loan data is stored, but not initiated yet.
    Created,
    // The loan has been initialized, funds have been delivered to the borrower and the collateral is held.
    Active,
    // The loan is in auction, higest price liquidator will got chance to claim it.
    Auction,
    // The loan has been repaid, and the collateral has been returned to the borrower. This is a terminal state.
    Repaid,
    // The loan was delinquent and collateral claimed by the liquidator. This is a terminal state.
    Defaulted
  }

  struct LoanData {
    //the id of the nft loan
    uint256 loanId;
    //the current state of the loan
    LoanState state;
    //address of borrower
    address borrower;
    //address of nft asset token
    address nftAsset;
    //the id of nft token
    uint256 nftTokenId;
    //address of reserve asset token
    address reserveAsset;
    //scaled borrow amount. Expressed in ray
    uint256 scaledAmount;
    //start time of first bid time
    uint256 bidStartTimestamp;
    //bidder address of higest bid
    address bidderAddress;
    //price of higest bid
    uint256 bidPrice;
    //borrow amount of loan
    uint256 bidBorrowAmount;
    //bidder address of first bid
    address firstBidderAddress;
  }

  struct ExecuteDepositParams {
    address initiator;
    address asset;
    uint256 amount;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteWithdrawParams {
    address initiator;
    address asset;
    uint256 amount;
    address to;
  }

  struct ExecuteBorrowParams {
    address initiator;
    address asset;
    uint256 amount;
    address nftAsset;
    uint256 nftTokenId;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteBatchBorrowParams {
    address initiator;
    address[] assets;
    uint256[] amounts;
    address[] nftAssets;
    uint256[] nftTokenIds;
    address onBehalfOf;
    uint16 referralCode;
  }

  struct ExecuteRepayParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
  }

  struct ExecuteBatchRepayParams {
    address initiator;
    address[] nftAssets;
    uint256[] nftTokenIds;
    uint256[] amounts;
  }

  struct ExecuteAuctionParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 bidPrice;
    address onBehalfOf;
  }

  struct ExecuteRedeemParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
    uint256 bidFine;
  }

  struct ExecuteLiquidateParams {
    address initiator;
    address nftAsset;
    uint256 nftTokenId;
    uint256 amount;
  }

  struct ExecuteLendPoolStates {
    uint256 pauseStartTime;
    uint256 pauseDurationTime;
  }
}