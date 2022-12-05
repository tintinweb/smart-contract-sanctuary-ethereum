/**
 *Submitted for verification at Etherscan.io on 2022-12-05
*/

/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/Staking/StakingPools/NTStaking.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/Staking/StakingPools/NTStaking.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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




/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/Staking/StakingPools/NTStaking.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0-only
pragma solidity ^0.8.8;

interface IByteContract {
    function burn(address _from, uint256 _amount) external;
    function getReward(address _to) external;
    function updateRewardOnMint(address _user, uint256 tokenId) external;
    function updateReward(address _from, address _to, uint256 _tokenId) external;
}



/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/Staking/StakingPools/NTStaking.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: AGPL-3.0-only
pragma solidity ^0.8.11;

interface ITemporary721 {

  struct StakedAsset {
        address collection;
        uint256 tokenId;
    }

  /**
    Provided with an address parameter, this function returns the number of all
    tokens in this collection that are owned by the specified address.
    @param _owner The address of the account for which we are checking balances
  */
  function balanceOf (
    address _owner
  ) external returns (uint256);

  /**
    Return the address that holds a particular token ID.
    @param _id The token ID to check for the holding address of.
    @return The address that holds the token with ID of `_id`.
  */
  function ownerOf (
    uint256 _id
  ) external returns (address);



  /**
    This function performs an unsafe transfer of token ID `_id` from address
    `_from` to address `_to`. The transfer is considered unsafe because it does
    not validate that the receiver can actually take proper receipt of an
    ERC-721 token.
    @param _from The address to transfer the token from.
    @param _to The address to transfer the token to.
    @param _id The ID of the token being transferred.
  */
  function transferFrom (
    address _from,
    address _to,
    uint256 _id
  ) external;

  /**
    This function allows permissioned minters of this contract to mint tokens with certain id.
    Any minted tokens are sent to the `to` address.

    @param to The recipient of the tokens being minted.
    @param tokenId Id of token that has to be minted.
  */
    function mint(address to, uint256 tokenId, address _collection, uint256 _stakedId) external;

  /**
    Allow the caller, either the owner of a token or an approved manager, to
    burn a specific token ID. In order for the token to be eligible for burning,
    transfer of the token must not be locked.
  */
  function burn(uint256 tokenId, address _collection, uint256 _stakedId) external;

  function claimableTokens (
    address staker
  ) external returns(StakedAsset[] memory);

  function tokenIdToTemporaryId (
    uint256 tokenId,
    address collection
  ) external returns(uint256);
}



/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/Staking/StakingPools/NTStaking.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0-only
pragma solidity ^0.8.8;

////import "@openzeppelin/contracts/utils/introspection/IERC165.sol";


interface IGenericGetter is IERC165 {



    function VAULTgetCredits(uint256 tokenId) external view returns (string memory); /// TODO fix this

    
    /**
    * Vault contract
     */
    function getCreditMultiplier(uint256 tokenId) external view returns (string memory);
    function getCredits(uint256 tokenId) external view returns (string memory);


    /**
    * S1 Citizen contract
     */
    function vaultContract() external view returns (address); 
    function identityContract() external view returns (address);
    function totalSupply() external view returns (uint256);
    function getRewardRateOfTokenId(uint256 citizenId) external view returns (uint256);
    function getVaultIdOfTokenId(uint256 _tokenId) external view returns (uint256);
    function getIdentityIdOfTokenId(uint256 citizenId) external view returns (uint256);
    
    /**
    * Bytes 2.0 contract
     */
    function getCurrentDailyYield () external view returns (uint);

    /**
     * Identity(beckLoot) contract
     */
    function getClass(uint256 tokenId) external view returns (string memory);


}



/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/Staking/StakingPools/NTStaking.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

////import "../utils/Context.sol";

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




/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/Staking/StakingPools/NTStaking.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
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
     * ////IMPORTANT: Beware that changing an allowance with this method brings the risk
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




/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/Staking/StakingPools/NTStaking.sol
*/
            
////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

////import "../../utils/introspection/IERC165.sol";

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


/** 
 *  SourceUnit: /home/nam/Documents/work/NT/NeoTokyo-Contracts/contracts/Staking/StakingPools/NTStaking.sol
*/

////// SPDX-License-Identifier-FLATTEN-SUPPRESS-WARNING: GPL-3.0-only
pragma solidity ^0.8.11;

////import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
////import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
////import "@openzeppelin/contracts/access/Ownable.sol";

////import "../../interfaces/IGenericGetter.sol";
////import "../../interfaces/ITemporary721.sol";
////import "../../interfaces/IByteContract.sol";

/*
  It saves bytecode to revert on custom errors instead of using require
  statements. We are just declaring these errors for reverting with upon various
  conditions later in this contract.
*/
error UnauthorizedCall();
error AmountIsTooHigh();
error BoostPeriodNotSupported();
error TokenNotStakedOrAnotherOwner();
error WrongAmountForCitizenStake();
error UserTriesToStakeTwoVaults();
error WrongSeasonId();
error WrongDataForNonCitizen();
error LPCannotBeWithdrawedBeforeEndTime();
error WrongCitizenSeasonId();
error WrongAmountForBytesStake();
error WrongAmountForLPStake();
error StakeShouldBeWithdrawBeforeRestaking();
error CitizenDoesnotExist();

/**
  @title A pool-based staking contract for the NeoTokyo ecosystem.
  @author Rostislav Khlebnikov
  @author Egor Dergunov
  @author Nikita Elunin

  This contract allows callers to stake their NeoTokyo citizens and BYTES for
  tuned emission rewards. It allows the deployer to configure various emission
  details for the NeoTokyo ecosystem.

  June 14th, 2022.
*/
contract NTStakingWithPools is Ownable {

  ///
  uint256 constant precision = 1e12;

  ///
  uint256 constant boostPrecision = 1e2;

  /// address of BYTES contract
  address immutable public BYTES;

  /// address of S1Citizen contract
  address immutable public S1Citizen;

  /// address of Identity S1 Citizen contract
  address immutable public IdentityContract;

  /// address of Vault S1 Citizen contract
  address immutable public vaultContract;

  /// address of temporary non-transferable S1&S2 token contract
  address immutable public temporaryToken;

  /// maximum capitalization of BYTES stake per S1 Citizen
  uint256 immutable public S1Cap;

  /// maximum capitalization of BYTES stake per S2 Citizen
  uint256 immutable public S2Cap;

  /// number of BYTES needed to get 1 point in BYTES staking
  uint256 public bytesPerPoint = 200 * 1e18;

  /// maximum capitalization of BYTES stake per Non-Citizen
  uint256 public NonCitizenCap;

  /// total number of Staking pools
  uint256 public numberOfPools;

  /// total amount of BYTES staked
  uint256 public totalBytesStaked;

  /** 
    This struct is used to represent information of user stake at staking and 
    withdrawing of funds.

    @param seasonId id of season. 0 - for Non Citizen, 1 - for S1 Citizen, 
      2 - for S2 Citizen.
    @param tokenId id of token if S1 or S2 Citizen is Staked. For BYTES and LP 
      stakings should be equals 0. 
    @param vaultId id of vault for S1 Citizen if it staked separately from S1. 
    @param poolId id of staking pool.
    @param boostPeriod period of boost. Should be strictly equal boost period 
      specified for each pool. 
    @param amount amount of staked asset if LP or BYTES is staked. For S1 and S2
      Citizen should be equal one.
  */
  struct Info {
    uint8 seasonId;
    uint96 tokenId;
    uint96 vaultId;
    uint96 poolId;
    uint96 boostPeriod;
    uint256 amount;
  }

  /**
    This enum is represent types of assets that can be staked into this pool.
   */
  enum AssetType {
    NONE, 
    S1_CITIZEN, 
    OUTER_CITIZEN, 
    BYTES,
    LP,
    BYTES_NON_CITIZEN 
  }

  /**
    This struct is used to define configuration details for a particular asset
    staking pool.

    @param asset address of asset that is staked to the pool
    @param assetType enum that describes the type of asset. Used for choose 
      specific internal functions
    @param totalStaked total number of tokens that was staked to the pool
    @param totalPoints total number of points in the pool. It doesn't in the 
      linear correlation with totalStaked because they may have different boosts  
    @param lastRewardedTimestamp time when the reward from pool was claimed last 
      time. Used when point are calculated
    @param daoTax percent of reward that is sended to DAO
    @param percentNow fixed percent of total emission that is assigned, when new 
      element is added to array 
    @param pointsTotal total amount of points that was in pool during the period. 
    @param dailyReward amount of tokens that are emitted during period of time.
    @param emissionPoints A two-dimensional array tracking a series of
      configurable emission points for this pool in a pair-wise fashion wherein
      each `[0][i]` indicates a percent threshold below which a specific
      emission value is active and each `[1][i]` indicates the corresponding
      specific emission value for the threshold.
    @param emissionPercents A one-dimensional array of struct EmissionPercent 
      that contains information about percent of total Emmision that is going 
      to be minted during some period of time, number of points and etc. Used 
      for calculating the reward.  
  */
  struct Pool {
    address asset; 
    AssetType assetType;
    uint256 totalStaked;
    uint256 totalPoints;
    uint256 lastRewardedTimestamp;
    uint256 daoTax;
    uint256 percentNow;
    uint256 dailyReward;
    uint256[2][] emissionPoints;
    EmissionPercent [] emissionPercents; 
  }

  /**
    struct EmissionPercent that contains information about what percent of 
    emission is going to be minted.  

    @param startTime time of the start of the emission percent.
    @param endTime end of the emission percent. if it's last element in array is
       assigned to max(uint96) for right calculations
    @param pointsOnSec point * time 
    @param reward reward multiplied 
   */
  struct EmissionPercent {
    uint96 startTime;
    uint96 endTime;
    uint256 pointsOnSec; 
    uint256 reward;
  }

  /**
    Map each pool ID to the `Pool` configuration details driving the behavior of
    the particular pool.
  */
  mapping (uint96 => Pool) public pools;

  /// Map that contain information of Stakings for each users.
  mapping (address => Staker) public stakers;

  /** 
    Map boost multipliers with time and pool. 
    pool number -> TimePeriod -> boost multiplier
  */
  mapping (uint96 => mapping (uint96 => uint256)) public boostConfigs;

  /// Map vault credit of S1 Citizen and it's multiplier. 
  mapping (string => uint256) public vaultCredit;

  /// Map identity credit of S1 Citizen and it's multiplier.
  mapping (string => uint256) public identityCredit;

  /// Map that used to transform numeric value of Identity credit to string
  mapping (uint256 => string) public oldIdentityCredit;

  /// Map that used to vault Credit string to old numeric value
  mapping (string => uint256) public oldVaultCredit;

   /**
    Struct that describe information about each staker and his stakings to 
    different pools.

    @param stakes map that contains information about eact user's stake into 
      exact pool.   
    @param citizenStakes map each Citizen that user stake. with addtional 
      information about it.  
    @param lastRewardIndex last index of `emissionPercents` array in pool struct 
      when getReward function were called.
    @param lastRewardedTimestamp last timestamp when getReward function were 
      called.
  */
  struct Staker {
    // poolId => StakeInfo
    mapping(uint96 => StakeInfo) stakes;
    mapping(uint8 => mapping(uint96 => CitizenStake)) citizenStakes;
    uint256 lastRewardIndex;
    uint256 lastRewardedTimestamp; 
  }

  /**
    Struct that describe each user's stake

    @param tokenStaked amount if tokens staked into this pool.  
    @param points number of basic points 
    @param timestamp timestamp that updates when user done any manipulations with
    @param stakedUntil deadline of stake, when user can clame his boost reward.
    @param emissionPoint value that storing staring points in  emissionPercents`
     array. Used to calculate reward from usual points.
    @param pointsBoost struct holding number of boosted points, emissionPoint, 
    start and end timestamps used to calculate reward from boosted points.
   */
  struct StakeInfo {
    uint256 tokenStaked;
    uint256 points;
    uint64 emissionPoint;
    uint96 duration;
    uint96 timestamp;
    Points pointsBoost; 
  }

  /** 
    Struct that contains information about staked Citizens and BYTES staked with 
    certain citizen

    @param bytesCap remaning cap of BYTES for that Citizen.  
    @param bytesStaked amount of BYTES that were atked for that citizen.
    @param vaultId Id of vault for S1 Citizen, if it were staked separatelly.
   */
  struct CitizenStake {
    uint256 bytesCap;
    uint256 bytesStaked;
    uint96 vaultId;
    uint256 pointsBytes;
    uint256 pointsCitizen;
    Points pointsCitizenBoost;
    Points pointsBytesBoost;    
  }

  /**
    struct to hold information about information about points and reward 
    calculation

    @param  points number of  points 
    @param  emissionPoint value that storing staring points in  emissionPercents`
     array. Used to calculate reward for specidied points.
    @param  startTime start timestamp of stake.
    @param  endTime endtime of stake.
   */
  struct Points {
    uint256 points;
    uint64 emissionPoint;
    uint96 startTime;
    uint96 endTime;
  }

  /** map holfing information about owners of certain citizens
       seasonId => tokenId => owner
   */ 
  mapping(uint256 => mapping(uint256 => address)) public owners; 

  /**
    event that emitted when user stake funds
  */
  event Staked(Info stakeInfo);

  /**
    event that emitted when user wuthdraw funds 
  */
  event Withdrawed(Info stakeInfo);

  /**
  */
  constructor (
    address _BYTES,
    address _vaultContract,
    address _S1Citizen,
    address _IdentityContract,
    address _temporaryToken,
    uint256 _S1Cap,
    uint256 _S2Cap,
    uint256 _NonCitizenCap
  ) {
    BYTES = _BYTES;
    vaultContract = _vaultContract;
    S1Citizen = _S1Citizen;
    IdentityContract = _IdentityContract;
    temporaryToken = _temporaryToken;
    S1Cap = _S1Cap;
    S2Cap = _S2Cap;
    NonCitizenCap = _NonCitizenCap;
  }

  /**
    A modifier to only permit calls from the predefined BYTES token contract.
  */
  modifier onlyBytes () {
    if (msg.sender != BYTES) {
      revert UnauthorizedCall();
    }
    _;
  }

  /**
    A view function to check whether a particular citizen is staked or not.

    @param _seasonId The season identifier of the NeoTokyo citizen to check.
    @param _tokenId The ID of the particular citizen token.

    @return Whether or not the particular citizen is presently staked.
  */
  function isStaked (
    uint256 _seasonId,
    uint256 _tokenId
  ) public view returns (bool) {
    return owners[_seasonId][_tokenId] != address(0);
  }

  /**
    Allow the owner of the staker to set the configuration settings for the pool
    of ID `_poolId`.

    @param _poolId The ID of the pool to update.
    @param _config The new configuration values to set for the updated pool.
  */
  function configurePool (
    uint96 _poolId,
    Pool calldata _config
  ) onlyOwner external {
    if(pools[_poolId].asset == address(0)) {
      numberOfPools++;
    }
    
    pools[_poolId] = _config;
  }

  /**
    This private helper function updates the `pointsOnSec` and
    `reward` of the pool with the ID of `_poolId` given the
    current elapsed time since the pool was last rewarded and the daily rewards
    being emitted from the pool. This function is called to enable piecemeal
    updates of staking pools every time a user action is taken involving the
    pool, such as staking an asset, withdrawing an asset, or claiming BYTES
    rewards. Pools are also updated each time the BYTES token emission rate is
    altered.

    @param _poolId The ID of the specific staking pool to update.
  */
  function _updatePool (
    uint96 _poolId
  ) private {
    Pool storage pool = pools[_poolId];
    EmissionPercent storage emissionPercent = pool.emissionPercents[pool.emissionPercents.length - 1];
    
    uint timeSinceLastUpdate = block.timestamp - pool.lastRewardedTimestamp;

    emissionPercent.pointsOnSec += pool.totalPoints * timeSinceLastUpdate;
    emissionPercent.reward += pool.dailyReward * timeSinceLastUpdate / (1 days);
    
    pool.lastRewardedTimestamp = block.timestamp;
  }

  /**
    This function may only be called by the BYTES token contract. Calls to this
    function are only triggered when the maximum daily emission rate of the
    BYTES token contract is updated on its configurable emission schedule update
    time lock.

    @param _dailyEmission The new daily emission of BYTES as set by the BYTES
      token contract.
  */
  function updateDailyEmission (
    uint256 _dailyEmission
  ) onlyBytes external {
    for (uint96 i = 1; i <= numberOfPools;) {
      // get new daily emission to all pools
      _updatePool(i);
      pools[i].dailyReward = pools[i].percentNow * _dailyEmission 
                             / boostPrecision;

      unchecked{ ++i; }
    }
  }
  /**
    This function configure time dependent boost multipliers for pools
    
    @param _period array with values of period that need for boost. 
    @param _multiplyer array with multiplier value for certain boost period. 
      Should have the same lenght as _period array.
    @param _poolId id of the pool for which boosts are configured. 
  */
  function configureBoost (
    uint96[] memory _period,
    uint64[] memory _multiplyer,
    uint96 _poolId
  ) external onlyOwner {
    for(uint256 i; i < _period.length; ) {
      boostConfigs[_poolId][_period[i]] = _multiplyer[i];
      unchecked{ ++i; }
    }
  }

  /**
      only a valid call if isStaked is true
      @param _seasonId season identifier
      @param _tokenId id of the token
    */
  function ownerOf(uint256 _seasonId, uint256 _tokenId)
      external
      view
      returns (address)
  {
      return owners[_seasonId][_tokenId];
  }

  /** 
  */ 
  function stakerInfo(
    address _staker,
    uint96 _poolId, 
    uint8 _seasonId, 
    uint96 _tokenId
  ) external view returns (
    StakeInfo memory _stakeInfo,
    CitizenStake memory _citizenInfo,
    uint256,
    uint256
  ) {
    _stakeInfo = stakers[_staker].stakes[_poolId];
    _citizenInfo = stakers[_staker].citizenStakes[_seasonId][_tokenId];
    return (
      _stakeInfo,
      _citizenInfo, 
      stakers[_staker].lastRewardIndex, 
      stakers[_staker].lastRewardedTimestamp
    );
  }

  /**
    This funciton is used to configure Vault Credit - boost multiplier value pairs
   */  
  function configureVaultCredit(string[] memory _key, uint256[] memory _values) onlyOwner external {
    for (uint256 i; i < _key.length; ) {
      vaultCredit[_key[i]] = _values[i];
      unchecked { ++i; }
    }
  }

  /**
    This funciton is used to configure Identity Credit - boost multiplier value pairs
   */
  function configureIdentityCredit(string[] memory _key, uint256[] memory _values) onlyOwner external {
    for (uint256 i; i < _key.length; ) {
      identityCredit[_key[i]] = _values[i];
      unchecked { ++i; }
    }
  }

  /**
    This funciton is used to configure old values of  Identity Credit - to get new values on-chain
   */
  function configureOldIdentityCredit(uint[] memory _key, string[] memory _values) onlyOwner external {
    for (uint256 i; i < _key.length; ) {
      oldIdentityCredit[_key[i]] = _values[i];
      unchecked { ++i; }
    }
  }

  /**
    This funciton is used to configure old Vault Credit - to get identity Credit on-chain
   */
  function configureOldVaultCredit(string[] memory _key, uint256[] memory _values) onlyOwner external {
    for (uint256 i; i < _key.length; ) {
      oldVaultCredit[_key[i]] = _values[i];
      unchecked { ++i; }
    }
  }
  /**
  */
  function stake (
    Info memory _info
  ) external {
    if (_info.boostPeriod != 0
        && boostConfigs[uint96(_info.poolId)][_info.boostPeriod] == 0){
          revert BoostPeriodNotSupported();
    }
    
    Pool storage pool = pools[_info.poolId];
    StakeInfo storage userStake = stakers[msg.sender].stakes[_info.poolId];
    CitizenStake storage citizenStake =  stakers[msg.sender].citizenStakes[_info.seasonId][_info.tokenId];

    _updatePool(_info.poolId);
    // call getReward before staking to update user staking data. 
    IByteContract(BYTES).getReward(msg.sender);

    /** @dev in case if some tokens are already staked into pool with fungible 
          assets(LP, BYTES_NON_CITIZEN or BYTES). duration of this stake is 
          calculated wiht amortizates shedule  
     */ 
    Info memory newInfo = _info;
    bool pointsBoostUpdateTime = false;
    if((userStake.tokenStaked != 0 && (pool.assetType == AssetType.LP 
        || pool.assetType == AssetType.BYTES_NON_CITIZEN))) {
      
      pointsBoostUpdateTime = true;
      uint96 newStakeDuration;
      (newInfo, newStakeDuration) = infoUpdating(
        _info,
        userStake.pointsBoost.endTime,
        userStake.tokenStaked
      );
      
      userStake.duration = newStakeDuration;
      userStake.pointsBoost.endTime = uint96(block.timestamp) + newStakeDuration;

    } else if ((citizenStake.bytesStaked != 0 && pool.assetType == AssetType.BYTES)) {
      
      pointsBoostUpdateTime = true;
      uint96 newStakeDuration;
      (newInfo, newStakeDuration) = infoUpdating(
        _info,
        citizenStake.pointsBytesBoost.endTime,
        citizenStake.bytesStaked
      );
  
      userStake.duration = newStakeDuration;
      citizenStake.pointsBytesBoost.endTime = uint96(block.timestamp) + newStakeDuration;

    }
    
    uint256 emissionsLenght = pool.emissionPercents.length-1;

    uint256 points;
    uint256 pointsBoost;
    if (pool.assetType == AssetType.OUTER_CITIZEN 
        || pool.assetType == AssetType.S1_CITIZEN) {
      (points, pointsBoost) = stakeCitizen(_info);

      citizenStake.pointsCitizenBoost.emissionPoint = uint64(emissionsLenght);
      citizenStake.pointsCitizenBoost.startTime = uint96(block.timestamp); 
      citizenStake.pointsCitizenBoost.endTime = uint96(block.timestamp) + _info.boostPeriod; 
    } else if (pool.assetType == AssetType.BYTES) {
      (points, pointsBoost) = stakeBytes(_info);
      
      citizenStake.pointsBytesBoost.emissionPoint = uint64(emissionsLenght);
      citizenStake.pointsBytesBoost.startTime = uint96(block.timestamp); 
      if (pointsBoostUpdateTime == false) {
        citizenStake.pointsBytesBoost.endTime = uint96(block.timestamp) + _info.boostPeriod; 
      } 
    } else if ( pool.assetType == AssetType.BYTES_NON_CITIZEN) {
      (points, pointsBoost) = stakeBytes(_info);      
    } else if (pool.assetType == AssetType.LP) {
      (points, pointsBoost) = stakeLP(_info);
    }

    pool.totalPoints += points + pointsBoost;
    pool.totalStaked += _info.amount;

    // update times for stake
    userStake.points += points; 
    userStake.timestamp = uint96(block.timestamp);
    userStake.tokenStaked += _info.amount;
    userStake.emissionPoint = uint64(emissionsLenght);
    if (pool.assetType == AssetType.BYTES_NON_CITIZEN || pool.assetType == AssetType.LP) {
      userStake.pointsBoost.points += pointsBoost;
      userStake.pointsBoost.emissionPoint = uint64(emissionsLenght);
      userStake.pointsBoost.startTime = uint96(block.timestamp);
      if (pointsBoostUpdateTime == false) {
        userStake.pointsBoost.endTime = uint96(block.timestamp) + _info.boostPeriod; 
      }
    } else {
      // set pointsBoost to default value to disable get reward in withdraw
      userStake.pointsBoost = getDefaultPointsValue();
    }

    uint256 totalSupply = IGenericGetter(pool.asset).totalSupply();
    // for LP total staked amount is used, not percents
    uint256 currentStakedPercent = (pool.assetType != AssetType.LP) ? (((pool.totalStaked * precision) * 100) / totalSupply) / precision 
                                                                    : pool.totalStaked;
    uint96 emissionPercent = uint96(findEmission(currentStakedPercent, pool.emissionPoints));
    if (emissionPercent != pool.percentNow) {
      pool.percentNow = emissionPercent;
      pool.emissionPercents[emissionsLenght].endTime = uint96(block.timestamp);
      pool.emissionPercents.push(EmissionPercent({
        startTime : uint96(block.timestamp),
        endTime : type(uint96).max,
        pointsOnSec : 0,
        reward : 0
      }));
    }
    emit Staked(
      newInfo
    );
  }

  function withdraw(Info memory _info) public  {
    Pool storage pool = pools[_info.poolId];
    Staker storage staker = stakers[msg.sender];
    StakeInfo storage userStake = stakers[msg.sender].stakes[_info.poolId];
    CitizenStake storage citizenStake =  stakers[msg.sender].citizenStakes[_info.seasonId][_info.tokenId];

    /** @dev If boosted points are available for any pools beside non-citizen-
        bytes or LP we should add it to
    */
    if( citizenStake.pointsCitizenBoost.endTime < uint96(block.timestamp)
        || citizenStake.pointsBytesBoost.endTime < uint96(block.timestamp)) {
      Points memory withdrawableBoost;
      if (pool.assetType == AssetType.S1_CITIZEN 
          || pool.assetType == AssetType.OUTER_CITIZEN) {
          withdrawableBoost = citizenStake.pointsCitizenBoost;
      }
      if (pool.assetType == AssetType.BYTES) {
          withdrawableBoost = citizenStake.pointsBytesBoost;
      }

      userStake.pointsBoost = withdrawableBoost;
    }

    _updatePool(_info.poolId);
    // call getReward before withdrawing funds. 
    IByteContract(BYTES).getReward(msg.sender);
    // true 721 - NFT & others
    uint256 points;
    uint256 pointsBoost;
    if (pool.assetType == AssetType.OUTER_CITIZEN 
        || pool.assetType == AssetType.S1_CITIZEN) {
        
        // if unstake citizens force to unstake BYTES  
        if (staker.citizenStakes[_info.seasonId][_info.tokenId].bytesStaked > 0) {
          uint96 boostDuration = citizenStake.pointsBytesBoost.endTime - citizenStake.pointsBytesBoost.startTime; 
          Info memory bytesInfo = Info({
            seasonId: _info.seasonId, 
            tokenId: _info.tokenId,
            vaultId: _info.vaultId,  
            poolId: uint96(3),
            boostPeriod: boostDuration,  
            amount: citizenStake.bytesStaked
          });

          withdraw(bytesInfo);
        }
        
        (points, pointsBoost) = withdrawCitizen(_info);
        citizenStake.pointsCitizenBoost = getDefaultPointsValue();
    } 
    else if (pool.assetType == AssetType.BYTES) {
        (points, pointsBoost) = withdrawBytes(_info);
        citizenStake.pointsBytesBoost = getDefaultPointsValue();
    }
    else if(pool.assetType == AssetType.BYTES_NON_CITIZEN) {
        (points, pointsBoost) = withdrawBytes(_info);
    }
    else  if (pool.assetType == AssetType.LP) {
        (points, pointsBoost) = withdrawLP(_info);
    }

    // Common actions for different pools 
    pool.totalPoints -= points + pointsBoost;
    pool.totalStaked -= _info.amount;

    userStake.points -= points; 
    userStake.tokenStaked -= _info.amount;
    
    // setting struct to default value 
    userStake.pointsBoost = getDefaultPointsValue();


    uint256 totalSupply = IGenericGetter(pool.asset).totalSupply();
    // for LP total staked amount is used, not percents
    uint256 currentStakedPercent = (pool.assetType != AssetType.LP) ? (((pool.totalStaked * precision) * 100) / totalSupply) / precision 
                                                                    : pool.totalStaked;
    uint256 emissionsLenght = pool.emissionPercents.length-1;
    uint96 emissionPercent = uint96(findEmission(currentStakedPercent, pool.emissionPoints));
    if (emissionPercent != pool.percentNow) {
      pool.percentNow = emissionPercent;
      pool.emissionPercents[emissionsLenght].endTime = uint96(block.timestamp);
      pool.emissionPercents.push(EmissionPercent({
        startTime : uint96(block.timestamp),
        endTime : type(uint96).max,
        pointsOnSec : 0,
        reward : 0
      }));
    }

    emit Withdrawed (
      _info
    );
  }

  // 
  /**
  */
  function getReward (
    address _user
  ) external onlyBytes returns (uint256, uint256) {
    uint256 reward;
    uint256 daoCommission;
    Staker storage staker = stakers[_user];
    
    for (uint96 i = 1; i <= numberOfPools;) {
      // user reward from pool is calculated only when he stakes to specific pool 
      if (staker.stakes[i].tokenStaked != 0) {
        _updatePool(i);
        uint256 rewardFromPool = _calculateUserReward(i, _user); 
        uint256 daoCommissionFromPool;
        
        // collect dao commission 
        if(pools[i].daoTax != 0) {
          daoCommissionFromPool = rewardFromPool * pools[i].daoTax / 10000;
          daoCommission += daoCommissionFromPool;
          rewardFromPool -= daoCommissionFromPool;
        }
        reward += rewardFromPool;
      }    

      unchecked { ++i; }
    }
    return (reward, daoCommission);
  }

  function stakeBytes(Info memory _info) internal returns (uint256, uint256){
      Staker storage staker = stakers[msg.sender];
      Pool storage pool = pools[_info.poolId];
      CitizenStake storage citizenStake =  stakers[msg.sender].citizenStakes[_info.seasonId][_info.tokenId];
      
      if (_info.amount == 0) {
        revert WrongAmountForBytesStake();
      }

      IERC20(pool.asset).transferFrom(msg.sender, address(this), _info.amount);
      uint256 points = 1;

      if (pool.assetType == AssetType.BYTES_NON_CITIZEN) {
        if (_info.seasonId != 0 || _info.tokenId != 0 || _info.vaultId != 0) {
          revert WrongDataForNonCitizen();
        }

        if (_info.amount + staker.stakes[_info.poolId].tokenStaked > NonCitizenCap) {
          revert AmountIsTooHigh();
        }
      } else {
        if (_info.seasonId != 1 && _info.seasonId != 2) {
          revert WrongCitizenSeasonId();
        }
        if (owners[_info.seasonId][_info.tokenId] != msg.sender) {
          revert TokenNotStakedOrAnotherOwner();
        }
        if (staker.citizenStakes[_info.seasonId][_info.tokenId].bytesCap < _info.amount ) {
          revert AmountIsTooHigh();
        }

        if (_info.seasonId == 1) { 
          points = calculateS1CitizenPoints(_info);
        }
      }

      
      // if BYTES & citizen S1 point should be calculated as 
      // vaultCreditMultiplier * stakingBoost * BytesStaked * StakingBoost
      points *= _info.amount / bytesPerPoint; 
      
      uint256 pointsBoosted = (points * boostConfigs[_info.poolId][_info.boostPeriod]) / boostPrecision;
      if (_info.seasonId != 0) {
        citizenStake.bytesCap -= _info.amount;
        citizenStake.bytesStaked += _info.amount;
        citizenStake.pointsBytes += points;
        citizenStake.pointsBytesBoost.points += pointsBoosted;
      }
      
      totalBytesStaked += _info.amount;
      
      return (points, pointsBoosted);
  }

  function stakeLP(Info memory _info) internal returns(uint256, uint256) {
    Pool storage pool = pools[_info.poolId];
      
    if (_info.amount == 0) {
      revert WrongAmountForLPStake();
    }

    IERC20(pool.asset).transferFrom(msg.sender, address(this), _info.amount);
    uint256 pointsBoosted = (_info.amount * boostConfigs[_info.poolId][_info.boostPeriod]) / boostPrecision ; 

    return (_info.amount, pointsBoosted);
  }

    function stakeCitizen(Info memory _info) internal returns (uint256, uint256) {
        Pool storage pool = pools[_info.poolId];
        CitizenStake storage citizenStake = stakers[msg.sender].citizenStakes[_info.seasonId][_info.tokenId];
        
        uint256 points = 1;
        
        if (_info.amount != 1) {
          revert WrongAmountForCitizenStake();
        }

        owners[_info.seasonId][_info.tokenId] = msg.sender;

        IERC721(pool.asset).transferFrom(
            msg.sender,
            address(this),
            _info.tokenId
        );

        // Mint temporary token as proof of ownership.
        uint256 tmpTokenId = uint256(keccak256(abi.encodePacked(pool.asset, _info.tokenId)));
        ITemporary721(temporaryToken).mint(msg.sender, tmpTokenId, pool.asset, _info.tokenId);

        if (pool.assetType == AssetType.S1_CITIZEN) {
            if (_info.seasonId != 1) {
                revert WrongSeasonId();
            } 
            
            IGenericGetter citizen = IGenericGetter(S1Citizen);   
            string memory creditYield = getCreditYield(_info.tokenId);

            points += identityCredit[creditYield]; 

            uint96 vaultId = uint96(citizen.getVaultIdOfTokenId(_info.tokenId));
            if( _info.vaultId != 0 && vaultId != 0) {
              revert UserTriesToStakeTwoVaults();
            } else if (_info.vaultId != 0 && vaultId == 0) {
              IERC721(vaultContract).transferFrom(
                msg.sender, 
                address(this),
                _info.vaultId
              );
              vaultId = _info.vaultId;
            }
            
            // for Unvaulted Citizens their stakeCap is equal to S2 stake cap 
            if (vaultId != 0) {
              citizenStake.bytesCap += S1Cap;
              citizenStake.vaultId = vaultId;
            } else {
              citizenStake.bytesCap += S2Cap;
            }
        }
        if (pool.assetType == AssetType.OUTER_CITIZEN) {
            if (_info.seasonId != 2) {
                revert WrongSeasonId();
            } 
            
            citizenStake.bytesCap += S2Cap;
        }

        uint256 pointsBoosted = (points * boostConfigs[_info.poolId][_info.boostPeriod]) / boostPrecision ; 

        citizenStake.pointsCitizen = points;
        citizenStake.pointsCitizenBoost.points = pointsBoosted;

        return (points, pointsBoosted);
    }

    function withdrawCitizen(Info memory _info) internal returns (uint256, uint256){
        Pool storage pool = pools[_info.poolId];
        CitizenStake storage citizenStake = stakers[msg.sender].citizenStakes[_info.seasonId][_info.tokenId];
        
        if (owners[_info.seasonId][_info.tokenId] != msg.sender) {
            revert UnauthorizedCall();
        }
        if(_info.amount != 1) {
          revert WrongAmountForCitizenStake();
        }
        
        // Burn temporary token.
        uint256 tmpTokenId = uint256(keccak256(abi.encodePacked(pool.asset, _info.tokenId)));
        ITemporary721(temporaryToken).burn(tmpTokenId, pool.asset, _info.tokenId);
        
        uint256 points;
        points = citizenStake.pointsCitizen; 
        citizenStake.bytesCap = 0;
        citizenStake.pointsCitizen = 0;

        owners[_info.seasonId][_info.tokenId] = address(0);
        
        uint256 pointsBoosted = citizenStake.pointsCitizenBoost.points; 

        // if vault was stacked separately from
        IERC721 vault721 = IERC721(vaultContract);
        bool vaultIsDetached;
        uint96 vaultId = citizenStake.vaultId;
        if (vaultId > 0) {
          vaultIsDetached = (vault721.ownerOf(vaultId) == address(this)); 
        } 
        if(vaultIsDetached) {
          vault721.transferFrom(
            address(this),
            msg.sender,
            vaultId 
          );
        } 
        citizenStake.vaultId = 0;


        IERC721(pool.asset).transferFrom(
            address(this),
            msg.sender,
            _info.tokenId
        );

        return (points, pointsBoosted);
    }

  function withdrawBytes(Info memory _info) internal returns (uint256, uint256){
      Pool storage pool = pools[_info.poolId];
      Staker storage staker = stakers[msg.sender];
      StakeInfo storage erc20Stake = staker.stakes[_info.poolId];
      CitizenStake storage citizenStake = stakers[msg.sender].citizenStakes[_info.seasonId][_info.tokenId];

      uint256 points = 1;
      uint256 pointsBoost;
      if (pool.assetType == AssetType.BYTES_NON_CITIZEN) {
        if (_info.amount != erc20Stake.tokenStaked) {
            revert AmountIsTooHigh();
        }
        points = erc20Stake.points;
        pointsBoost = erc20Stake.pointsBoost.points;
      } else {
        if (_info.amount != citizenStake.bytesStaked) {
            revert AmountIsTooHigh();
        }
        
        if (owners[_info.seasonId][_info.tokenId] != msg.sender) {
            revert TokenNotStakedOrAnotherOwner();
        }
        
        staker.citizenStakes[_info.seasonId][_info.tokenId].bytesCap += _info.amount;
        staker.citizenStakes[_info.seasonId][_info.tokenId].bytesStaked -= _info.amount;
        points = citizenStake.pointsBytes;
        pointsBoost = citizenStake.pointsBytesBoost.points;
        citizenStake.pointsBytes = 0;
      }

      IERC20(pool.asset).transfer(msg.sender, _info.amount);
      totalBytesStaked -= _info.amount;

      return (points, pointsBoost);
  }

  function withdrawLP(Info memory _info) internal returns (uint256, uint256){
      Pool storage pool = pools[_info.poolId];
      Staker storage staker = stakers[msg.sender];
      StakeInfo storage erc20Stake = staker.stakes[_info.poolId];

      if (_info.amount != erc20Stake.tokenStaked) {
          revert AmountIsTooHigh();
      }

      if (erc20Stake.pointsBoost.endTime > block.timestamp) {
          revert LPCannotBeWithdrawedBeforeEndTime() ; 
      }

      IERC20(pool.asset).transfer(msg.sender, _info.amount);

      uint256 pointsBoosted = erc20Stake.pointsBoost.points; 

      return (_info.amount, pointsBoosted);
  }

  /**
    Helper fucntion used to find current emmission rate per each pool.
    */
  function findEmission (
    uint256 _currentStakedPercent,
    uint256[2][] memory emissionPoints
  ) internal pure returns (uint256) {
    if (_currentStakedPercent < emissionPoints[0][0]){
      return emissionPoints[0][1];
    }

    for (uint i = 1; i < emissionPoints.length; ) {
        if (_currentStakedPercent < emissionPoints[i][0]) {
            return emissionPoints[i - 1][1];
        }
        unchecked { ++i; }
    }
    
    return emissionPoints[emissionPoints.length - 1][1];
  }

  /**
    function used to calculate User reward per each pool 
  */
  function _calculateUserReward(uint96 _poolId, address _user) internal returns (uint256 ) {
    Pool storage pool = pools[_poolId];
    StakeInfo storage userStake = stakers[_user].stakes[_poolId];
    uint reward;
    uint timeSinceLastReward = userStake.timestamp;
    for (uint i = userStake.emissionPoint; i < pool.emissionPercents.length;) {
      // get timeInterval for reward calc 
      EmissionPercent storage emissionPercent = pool.emissionPercents[i];
      uint256 time;
      
      if(emissionPercent.endTime < block.timestamp) {
        time = emissionPercent.endTime - timeSinceLastReward;
      } else {
        time = block.timestamp - timeSinceLastReward;
      }
      timeSinceLastReward = emissionPercent.endTime;
      
      // there are situation where reward for specific pools is equal zero or 
      // BYTES are emitted but no one stakes to pool.
      if(emissionPercent.reward != 0
        && emissionPercent.pointsOnSec != 0) {
        reward += ((userStake.points * time * precision / emissionPercent.pointsOnSec) * emissionPercent.reward) / precision;
      }
      
      unchecked{ ++i; }
    }
    
    // check if user can claim his boost reward 
    if(userStake.pointsBoost.points != 0 && block.timestamp > userStake.pointsBoost.endTime) {
      // we should iterate over all emission intervals and collect reward 
      uint96 timestampBoost = userStake.pointsBoost.startTime;
      for (uint i = userStake.pointsBoost.emissionPoint; i < pool.emissionPercents.length;) {
        EmissionPercent storage emissionPercent = pool.emissionPercents[i];
        uint256 time;

        // get timeInterval for reward calc 
        if(emissionPercent.endTime < block.timestamp) {
          time = emissionPercent.endTime - timestampBoost;
        } else {
          time = block.timestamp - timestampBoost;
        }
        timestampBoost = emissionPercent.endTime;
        
        if(emissionPercent.reward != 0
          && emissionPercent.pointsOnSec != 0) {
          reward += ((userStake.pointsBoost.points * time * precision / emissionPercent.pointsOnSec) 
                      * emissionPercent.reward) / precision;
        }
        unchecked{ ++i; }
      }
      // BYTES_NON_CITIZEN 
      if (pool.assetType == AssetType.BYTES_NON_CITIZEN 
          || pool.assetType == AssetType.LP) {
            pool.totalPoints -= userStake.pointsBoost.points;
      } 
      userStake.pointsBoost.points = 0;
    } 

    userStake.emissionPoint = uint64(pool.emissionPercents.length - 1);
    userStake.timestamp = uint96(block.timestamp);

    return reward;
  }

  function IsHandOfCitadel(uint256 _tokenId) internal view returns(bool) {
    uint256 identityId = IGenericGetter(S1Citizen).getIdentityIdOfTokenId(_tokenId);
    string memory class = IGenericGetter(IdentityContract).getClass(identityId);
    return equal(class, "Hand of Citadel");
  }

  /**
    * @dev Internal helper used for calculation number of points per each citizen  
    */
  function calculateS1CitizenPoints(Info memory _info) internal view returns(uint256) {
    uint256 points = 1;
    
    // bytes
    IGenericGetter vault = IGenericGetter(vaultContract);
    IGenericGetter citizen = IGenericGetter(S1Citizen);
    bool handOfCitadel = IsHandOfCitadel(_info.tokenId);

    uint256 vaultId = citizen.getVaultIdOfTokenId(_info.tokenId);
    if (!handOfCitadel) {
      string memory _vaultCredit = vault.getCreditMultiplier(
        vaultId
      );
      points *= vaultCredit[_vaultCredit];
    } else {
      points *= vaultCredit["?"];
    }

    // if S1 staker have vault he get boosts from it  
    if (vaultId != 0) {
      points *= boostConfigs[_info.poolId][_info.boostPeriod] / boostPrecision;
    }

    return points;
  }

  /**
    @dev Helper function used to get Credit Yield trait of exact citizen 
    */
  function getCreditYield(uint256 _tokenId) internal view returns(string memory) {
    IGenericGetter citizen = IGenericGetter(S1Citizen);
    IGenericGetter vault = IGenericGetter(vaultContract);
    uint256 rewardRate = citizen.getRewardRateOfTokenId(_tokenId);
    if (rewardRate == 0) {
      revert CitizenDoesnotExist();
    }
    uint256 vaultId = vault.getVaultIdOfTokenId(_tokenId);
    string memory _vaultCredit = vault.getCreditMultiplier(vaultId);
   
    uint256 creditYield = rewardRate - oldVaultCredit[_vaultCredit]; 
    
    return oldIdentityCredit[creditYield];
  }
  
  /** 
    * @dev Helper function to update infoHash parameters of stake if user add 
    * tokens to his stake.
    */
  function infoUpdating(
    Info memory _info, 
    uint96 endTime, 
    uint256 stakedAmount
  ) internal view returns(Info memory newInfo, uint96) {
    if(endTime < uint96(block.timestamp)) {
      revert StakeShouldBeWithdrawBeforeRestaking();
    }

    uint256 newAmount = stakedAmount + _info.amount;
    uint96 remainedTime = endTime - uint96(block.timestamp);
    uint96 newStakeDuration = calculateNewStakePeriod(
      remainedTime, 
      _info.boostPeriod,
      stakedAmount,
      newAmount
    );

    newInfo = Info({
      seasonId: _info.seasonId,
      tokenId: _info.tokenId, 
      vaultId: _info.vaultId,
      poolId: _info.poolId,
      boostPeriod: newStakeDuration,
      amount: newAmount
    });

    return (newInfo, newStakeDuration);
  }

  /** 
    * @dev Helper function to set Points struct to default value.
    */ 
  function getDefaultPointsValue() internal pure returns (Points memory) {
    return Points({
      points: 0, 
      emissionPoint: uint64(0),
      startTime: type(uint96).max,
      endTime: type(uint96).max
    });
  }


  /**
    @dev Helper function used for calculion new stacking period with amortized shedule
  */ 
  function calculateNewStakePeriod(
    uint96 _periodOld,
    uint96 _periodNew,
    uint256 _amountOld, 
    uint256 _amountNew  
  ) internal pure returns (uint96) {
    return uint96((uint256(_periodOld) * _amountOld + uint256(_periodNew) * _amountNew) 
      / (_amountNew + _amountOld));
  }

  /// @dev Compares two strings and returns true iff they are equal.
  function equal(string memory _a, string memory _b) internal pure returns (bool) {
    return compare(_a, _b);
  }

  function compare(string memory _a, string memory _b) internal pure returns (bool) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        bool success = true;

        assembly {
            let length := mload(a)

            // if lengths don't match the arrays are not equal
            switch eq(length, mload(b))
            case 1 {
                // cb is a circuit breaker in the for loop since there's
                //  no said feature for inline assembly loops
                // cb = 1 - don't breaker
                // cb = 0 - break
                let cb := 1

                let mc := add(a, 0x20)
                let end := add(mc, length)

                for {
                    let cc := add(b, 0x20)
                // the next line is the loop condition:
                // while(uint(mc < end) + cb == 2)
                } eq(add(lt(mc, end), cb), 2) {
                    mc := add(mc, 0x20)
                    cc := add(cc, 0x20)
                } {
                    // if any of these checks fails then arrays are not equal
                    if iszero(eq(mload(mc), mload(cc))) {
                        // unsuccess:
                        success := 0
                        cb := 0
                    }
                }
            }
            default {
                // unsuccess:
                success := 0
            }
        }

        return success;
    }  
}