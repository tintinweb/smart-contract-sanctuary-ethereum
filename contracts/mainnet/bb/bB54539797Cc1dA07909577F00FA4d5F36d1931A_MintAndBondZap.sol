// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "../interfaces/IBondDepository.sol";
import "../interfaces/IERC721.sol";
import "../interfaces/INFTXVault.sol";
import "../interfaces/INFTXVaultFactory.sol";
import "../interfaces/zaps/IMintAndBond.sol";

import "../libraries/ReentrancyGuard.sol";
import "../libraries/SafeERC20.sol";
import "../libraries/SafeMath.sol";

import "../types/FloorAccessControlled.sol";

contract MintAndBondZap is IMintAndBond, ReentrancyGuard, FloorAccessControlled {

  using SafeERC20 for IERC20;
  using SafeMath for uint256;
  using SafeMath for uint64;

  struct Note {
    uint256 amount;
    uint256 matured;
    address vault;
    uint48 claimed;
  }

  INFTXVaultFactory public immutable nftxFactory;
  IBondDepository public immutable bondDepository;
  uint48 public timelock; // seconds
  mapping(address => mapping(address => Note[])) public notes; // user deposit data

  event CreateNote(address user, address vault, uint256 index, uint256 amount, uint48 expiry);
  event ClaimNote(address user, uint256[] indexes, address vault);

  constructor (
    address _authority,
    address _bondDepository,
    address _nftxFactory,
    uint48 _timelock
  ) FloorAccessControlled(IFloorAuthority(_authority))
  {
    bondDepository = IBondDepository(_bondDepository);
    nftxFactory = INFTXVaultFactory(_nftxFactory);
    timelock = _timelock;
  }

  /** 
   * @notice             mints into nftx and bonds maximum into floordao
   * @param _vaultId     the nftx vault id
   * @param _ids[]       the nft ids
   * @param _bondId      the floor bond id
   * @param _to          the recipient of bond payout
   * @param _maxPrice    the max bond price to account for slippage
   * @return remaining_  remaining vtokens to send back to user
   */
  function mintAndBond721(
    uint256 _vaultId, 
    uint256[] calldata _ids, 
    uint256 _bondId,
    address _to,
    uint256 _maxPrice
  ) external override returns (uint256 remaining_) {
    require(_to != address(0) && _to != address(this));
    require(_ids.length > 0);

    (,,,,uint64 maxPayout,,) = bondDepository.markets(_bondId);
    uint256 bondPrice = bondDepository.marketPrice(_bondId);
    // Max bond reduced by 5% to account for possible tx-failing maxBond reduction in next block
    uint256 maxBond = maxPayout.mul(bondPrice).div(100).mul(95); // 18 decimal
    uint256 amountToBond = (maxBond > _ids.length.mul(1e18))
      ? _ids.length.mul(1e18)
      : maxBond;
    
    // Get our vault by ID
    address vault = nftxFactory.vault(_vaultId);
    IERC20 vaultToken = IERC20(vault);

    // Store initial balance
    uint256 existingBalance = vaultToken.balanceOf(address(this));

    // Convert ERC721 to ERC20
    // The vault is an ERC20 in itself and can be used to transfer and manage
    _mint721(vault, _ids, _to);
    
    // Bond ERC20 in FloorDAO
    if (vaultToken.allowance(address(this), address(bondDepository)) < type(uint256).max) {
      vaultToken.approve(address(bondDepository), type(uint256).max);
    }
    bondDepository.deposit(_bondId, amountToBond, _maxPrice, _to, address(0));

    // Calculate remaining from initial balance and timelock
    remaining_ = vaultToken.balanceOf(address(this)).sub(existingBalance);
    if (remaining_ > 0) {
      _addToTimelock(vault, remaining_, _to);
    }
  }

  /**
   * @notice             claim notes for user
   * @param _user        the user to claim for
   * @param _indexes     the note indexes to claim
   * @return amount_     sum of amount sent in vToken
   */
  function claim(address _user, uint256[] memory _indexes, address _vault) external override nonReentrant returns (uint256 amount_) {
    uint48 time = uint48(block.timestamp);

    for (uint256 i = 0; i < _indexes.length; i++) {
      (uint256 pay, bool matured) = pendingFor(_user, _indexes[i], _vault);
      require(matured, "Depository: note not matured");
      if (matured) {
        notes[_user][_vault][_indexes[i]].claimed = time; // mark as claimed
        amount_ += pay;
      }
    }

    IERC20 vaultToken = IERC20(_vault);
    vaultToken.safeTransfer(_user, amount_);

    emit ClaimNote(_user, _indexes, _vault);
  }

  /**
   * @notice             calculate amount available to claim for a single note
   * @param _user        the user that the note belongs to
   * @param _index       the index of the note in the user's array
   * @param _vault       the nftx vault
   * @return amount_     the amount due, in vToken
   * @return matured_    if the amount can be claimed
   */
  function pendingFor(address _user, uint256 _index, address _vault) public view override returns (uint256 amount_, bool matured_) {
    Note memory note = notes[_user][_vault][_index];

    amount_ = note.amount;
    matured_ = note.claimed == 0 && note.matured <= block.timestamp && note.amount != 0;
  }

  /**
   * @notice prevents remaining vtokens from being immediately claimable
   * @param _timelock amount in 18 decimal
   */
  function setTimelock(uint48 _timelock) external override onlyGovernor {
    // protect against accidental/overflowing timelocks
    require(_timelock < 31560000, "Timelock is too long");
    timelock = _timelock;
  }

  /**
   * @notice rescues any tokens mistakenly sent to this address
   * @param _token token to be rescued
   */
  function rescue(address _token) external override onlyGovernor {
      IERC20(_token).safeTransfer(
          msg.sender,
          IERC20(_token).balanceOf(address(this))
      );
  }

  function _mint721(address vault, uint256[] memory ids, address from) internal {
    // Transfer tokens to zap and mint to NFTX
    address assetAddress = INFTXVault(vault).assetAddress();
    uint256 length = ids.length;

    IERC721 erc721 = IERC721(assetAddress);
    for (uint256 i; i < length; ++i) {
      erc721.transferFrom(from, address(this), ids[i]);
    }

    // Approve tokens to be used by vault
    erc721.setApprovalForAll(vault, true);

    // Ignored for ERC721 vaults
    uint256[] memory emptyIds;
    INFTXVault(vault).mint(ids, emptyIds);
  }

  function _addToTimelock(address _vault, uint256 _remaining, address _user) internal returns (uint256 index_) {
    uint48 expiry = uint48(block.timestamp) + timelock;

    // the index of the note is the next in the user's array
    index_ = notes[_user][_vault].length;

    // the new note is pushed to the user's array
    notes[_user][_vault].push(
      Note({
        amount: _remaining,
        matured: expiry,
        vault: _vault,
        claimed: 0
      })
    );

    emit CreateNote(_user, _vault, index_, _remaining, expiry);
  }

}

// SPDX-License-Identifier: AGPL-3.0
pragma solidity >=0.7.5;

import "./IERC20.sol";

interface IBondDepository {

  // Info about each type of market
  struct Market {
    uint256 capacity; // capacity remaining
    IERC20 quoteToken; // token to accept as payment
    bool capacityInQuote; // capacity limit is in payment token (true) or in FLOOR (false, default)
    uint64 totalDebt; // total debt from market
    uint64 maxPayout; // max tokens in/out (determined by capacityInQuote false/true, respectively)
    uint64 sold; // base tokens out
    uint256 purchased; // quote tokens in
  }

  // Info for creating new markets
  struct Terms {
    bool fixedTerm; // fixed term or fixed expiration
    uint64 controlVariable; // scaling variable for price
    uint48 vesting; // length of time from deposit to maturity if fixed-term
    uint48 conclusion; // timestamp when market no longer offered (doubles as time when market matures if fixed-expiry)
    uint64 maxDebt; // 9 decimal debt maximum in FLOOR
  }

  // Additional info about market.
  struct Metadata {
    uint48 lastTune; // last timestamp when control variable was tuned
    uint48 lastDecay; // last timestamp when market was created and debt was decayed
    uint48 length; // time from creation to conclusion. used as speed to decay debt.
    uint48 depositInterval; // target frequency of deposits
    uint48 tuneInterval; // frequency of tuning
    uint8 quoteDecimals; // decimals of quote token
  }

  // Control variable adjustment data
  struct Adjustment {
    uint64 change;
    uint48 lastAdjustment;
    uint48 timeToAdjusted;
    bool active;
  }


  /**
   * @notice deposit market
   * @param _bid uint256
   * @param _amount uint256
   * @param _maxPrice uint256
   * @param _user address
   * @param _referral address
   * @return payout_ uint256
   * @return expiry_ uint256
   * @return index_ uint256
   */
  function deposit(
    uint256 _bid,
    uint256 _amount,
    uint256 _maxPrice,
    address _user,
    address _referral
  ) external returns (
    uint256 payout_, 
    uint256 expiry_,
    uint256 index_
  );

  function create (
    IERC20 _quoteToken, // token used to deposit
    uint256[3] memory _market, // [capacity, initial price]
    bool[2] memory _booleans, // [capacity in quote, fixed term]
    uint256[2] memory _terms, // [vesting, conclusion]
    uint32[2] memory _intervals // [deposit interval, tune interval]
  ) external returns (uint256 id_);
  function close(uint256 _id) external;

  function isLive(uint256 _bid) external view returns (bool);
  function liveMarkets() external view returns (uint256[] memory);
  function liveMarketsFor(address _quoteToken) external view returns (uint256[] memory);
  function payoutFor(uint256 _amount, uint256 _bid) external view returns (uint256);
  function markets(uint256 _bid) external view returns (
    uint256 capacity,
    IERC20 quoteToken,
    bool capacityInQuote,
    uint64 totalDebt,
    uint64 maxPayout,
    uint64 sold,
    uint256 purchased
  );
  function marketPrice(uint256 _bid) external view returns (uint256);
  function currentDebt(uint256 _bid) external view returns (uint256);
  function debtRatio(uint256 _bid) external view returns (uint256);
  function debtDecay(uint256 _bid) external view returns (uint64);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

/**
 * @dev ERC-721 non-fungible token standard.
 * See https://github.com/ethereum/EIPs/blob/master/EIPS/eip-721.md.
 */
interface IERC721
{

  /**
   * @dev Emits when ownership of any NFT changes by any mechanism. This event emits when NFTs are
   * created (`from` == 0) and destroyed (`to` == 0). Exception: during contract creation, any
   * number of NFTs may be created and assigned without emitting Transfer. At the time of any
   * transfer, the approved address for that NFT (if any) is reset to none.
   */
  event Transfer(
    address indexed _from,
    address indexed _to,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when the approved address for an NFT is changed or reaffirmed. The zero
   * address indicates there is no approved address. When a Transfer event emits, this also
   * indicates that the approved address for that NFT (if any) is reset to none.
   */
  event Approval(
    address indexed _owner,
    address indexed _approved,
    uint256 indexed _tokenId
  );

  /**
   * @dev This emits when an operator is enabled or disabled for an owner. The operator can manage
   * all NFTs of the owner.
   */
  event ApprovalForAll(
    address indexed _owner,
    address indexed _operator,
    bool _approved
  );

  /**
   * @notice Throws unless `msg.sender` is the current owner, an authorized operator, or the
   * approved address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is
   * the zero address. Throws if `_tokenId` is not a valid NFT. When transfer is complete, this
   * function checks if `_to` is a smart contract (code size > 0). If so, it calls
   * `onERC721Received` on `_to` and throws if the return value is not
   * `bytes4(keccak256("onERC721Received(address,uint256,bytes)"))`.
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   * @param _data Additional data with no specified format, sent in call to `_to`.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata _data
  )
    external;

  /**
   * @notice This works identically to the other function with an extra data parameter, except this
   * function just sets data to ""
   * @dev Transfers the ownership of an NFT from one address to another address. This function can
   * be changed to payable.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @notice The caller is responsible to confirm that `_to` is capable of receiving NFTs or else
   * they may be permanently lost.
   * @dev Throws unless `msg.sender` is the current owner, an authorized operator, or the approved
   * address for this NFT. Throws if `_from` is not the current owner. Throws if `_to` is the zero
   * address. Throws if `_tokenId` is not a valid NFT.  This function can be changed to payable.
   * @param _from The current owner of the NFT.
   * @param _to The new owner.
   * @param _tokenId The NFT to transfer.
   */
  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  )
    external;

  /**
   * @notice The zero address indicates there is no approved address. Throws unless `msg.sender` is
   * the current NFT owner, or an authorized operator of the current owner.
   * @param _approved The new approved NFT controller.
   * @dev Set or reaffirm the approved address for an NFT. This function can be changed to payable.
   * @param _tokenId The NFT to approve.
   */
  function approve(
    address _approved,
    uint256 _tokenId
  )
    external;

  /**
   * @notice The contract MUST allow multiple operators per owner.
   * @dev Enables or disables approval for a third party ("operator") to manage all of
   * `msg.sender`'s assets. It also emits the ApprovalForAll event.
   * @param _operator Address to add to the set of authorized operators.
   * @param _approved True if the operators is approved, false to revoke approval.
   */
  function setApprovalForAll(
    address _operator,
    bool _approved
  )
    external;

  /**
   * @dev Returns the number of NFTs owned by `_owner`. NFTs assigned to the zero address are
   * considered invalid, and this function throws for queries about the zero address.
   * @notice Count all NFTs assigned to an owner.
   * @param _owner Address for whom to query the balance.
   * @return Balance of _owner.
   */
  function balanceOf(
    address _owner
  )
    external
    view
    returns (uint256);

  /**
   * @notice Find the owner of an NFT.
   * @dev Returns the address of the owner of the NFT. NFTs assigned to the zero address are
   * considered invalid, and queries about them do throw.
   * @param _tokenId The identifier for an NFT.
   * @return Address of _tokenId owner.
   */
  function ownerOf(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @notice Throws if `_tokenId` is not a valid NFT.
   * @dev Get the approved address for a single NFT.
   * @param _tokenId The NFT to find the approved address for.
   * @return Address that _tokenId is approved for.
   */
  function getApproved(
    uint256 _tokenId
  )
    external
    view
    returns (address);

  /**
   * @notice Query if an address is an authorized operator for another address.
   * @dev Returns true if `_operator` is an approved operator for `_owner`, false otherwise.
   * @param _owner The address that owns the NFTs.
   * @param _operator The address that acts on behalf of the owner.
   * @return True if approved for all, false otherwise.
   */
  function isApprovedForAll(
    address _owner,
    address _operator
  )
    external
    view
    returns (bool);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

import "../interfaces/INFTXVaultFactory.sol";


interface INFTXVault {
    function manager() external view returns (address);
    function assetAddress() external view returns (address);
    function vaultFactory() external view returns (INFTXVaultFactory);

    function is1155() external view returns (bool);
    function allowAllItems() external view returns (bool);
    function enableMint() external view returns (bool);
    function enableRandomRedeem() external view returns (bool);
    function enableTargetRedeem() external view returns (bool);
    function enableRandomSwap() external view returns (bool);
    function enableTargetSwap() external view returns (bool);

    function vaultId() external view returns (uint256);
    function nftIdAt(uint256 holdingsIndex) external view returns (uint256);
    function allHoldings() external view returns (uint256[] memory);
    function totalHoldings() external view returns (uint256);
    function mintFee() external view returns (uint256);
    function randomRedeemFee() external view returns (uint256);
    function targetRedeemFee() external view returns (uint256);
    function randomSwapFee() external view returns (uint256);
    function targetSwapFee() external view returns (uint256);
    function vaultFees() external view returns (uint256, uint256, uint256, uint256, uint256);

    function __NFTXVault_init(
        string calldata _name,
        string calldata _symbol,
        address _assetAddress,
        bool _is1155,
        bool _allowAllItems
    ) external;

    function finalizeVault() external;

    function setVaultMetadata(
        string memory name_, 
        string memory symbol_
    ) external;

    function setVaultFeatures(
        bool _enableMint,
        bool _enableRandomRedeem,
        bool _enableTargetRedeem,
        bool _enableRandomSwap,
        bool _enableTargetSwap
    ) external;

    function setFees(
        uint256 _mintFee,
        uint256 _randomRedeemFee,
        uint256 _targetRedeemFee,
        uint256 _randomSwapFee,
        uint256 _targetSwapFee
    ) external;
    function disableVaultFees() external;

    // This function allows for an easy setup of any eligibility module contract from the EligibilityManager.
    // It takes in ABI encoded parameters for the desired module. This is to make sure they can all follow
    // a similar interface.
    function deployEligibilityStorage(
        uint256 moduleIndex,
        bytes calldata initData
    ) external returns (address);

    // The manager has control over options like fees and features
    function setManager(address _manager) external;

    function mint(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts /* ignored for ERC721 vaults */
    ) external returns (uint256);

    function mintTo(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts, /* ignored for ERC721 vaults */
        address to
    ) external returns (uint256);

    function redeem(uint256 amount, uint256[] calldata specificIds)
        external
        returns (uint256[] calldata);

    function redeemTo(
        uint256 amount,
        uint256[] calldata specificIds,
        address to
    ) external returns (uint256[] calldata);

    function swap(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts, /* ignored for ERC721 vaults */
        uint256[] calldata specificIds
    ) external returns (uint256[] calldata);

    function swapTo(
        uint256[] calldata tokenIds,
        uint256[] calldata amounts, /* ignored for ERC721 vaults */
        uint256[] calldata specificIds,
        address to
    ) external returns (uint256[] calldata);

    function allValidNFTs(uint256[] calldata tokenIds)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;


interface INFTXVaultFactory {
  // Read functions.
  function numVaults() external view returns (uint256);
  function zapContract() external view returns (address);
  function feeDistributor() external view returns (address);
  function eligibilityManager() external view returns (address);
  function vault(uint256 vaultId) external view returns (address);
  function allVaults() external view returns (address[] memory);
  function vaultsForAsset(address asset) external view returns (address[] memory);
  function isLocked(uint256 id) external view returns (bool);
  function excludedFromFees(address addr) external view returns (bool);
  function factoryMintFee() external view returns (uint64);
  function factoryRandomRedeemFee() external view returns (uint64);
  function factoryTargetRedeemFee() external view returns (uint64);
  function factoryRandomSwapFee() external view returns (uint64);
  function factoryTargetSwapFee() external view returns (uint64);
  function vaultFees(uint256 vaultId) external view returns (uint256, uint256, uint256, uint256, uint256);

  event NewFeeDistributor(address oldDistributor, address newDistributor);
  event NewZapContract(address oldZap, address newZap);
  event FeeExclusion(address feeExcluded, bool excluded);
  event NewEligibilityManager(address oldEligManager, address newEligManager);
  event NewVault(uint256 indexed vaultId, address vaultAddress, address assetAddress);
  event UpdateVaultFees(uint256 vaultId, uint256 mintFee, uint256 randomRedeemFee, uint256 targetRedeemFee, uint256 randomSwapFee, uint256 targetSwapFee);
  event DisableVaultFees(uint256 vaultId);
  event UpdateFactoryFees(uint256 mintFee, uint256 randomRedeemFee, uint256 targetRedeemFee, uint256 randomSwapFee, uint256 targetSwapFee);

  // Write functions.
  function __NFTXVaultFactory_init(address _vaultImpl, address _feeDistributor) external;
  function createVault(
      string calldata name,
      string calldata symbol,
      address _assetAddress,
      bool is1155,
      bool allowAllItems
  ) external returns (uint256);
  function setFeeDistributor(address _feeDistributor) external;
  function setEligibilityManager(address _eligibilityManager) external;
  function setZapContract(address _zapContract) external;
  function setFeeExclusion(address _excludedAddr, bool excluded) external;

  function setFactoryFees(
    uint256 mintFee, 
    uint256 randomRedeemFee, 
    uint256 targetRedeemFee,
    uint256 randomSwapFee, 
    uint256 targetSwapFee
  ) external; 
  function setVaultFees(
      uint256 vaultId, 
      uint256 mintFee, 
      uint256 randomRedeemFee, 
      uint256 targetRedeemFee,
      uint256 randomSwapFee, 
      uint256 targetSwapFee
  ) external;
  function disableVaultFees(uint256 vaultId) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.7.5;

interface IMintAndBond {

  function mintAndBond721(
    uint256 vaultId,
    uint256[] calldata ids,
    uint256 bondId,
    address to,
    uint256 maxPrice
  ) external returns (uint256);
  function claim(address _user, uint256[] memory _indexes, address _vault) external returns (uint256);
  function pendingFor(address _user, uint256 _index, address _vault) external view returns (uint256, bool);
  function setTimelock(uint48 _timelock) external;
  function rescue(address _token) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.7.5;

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
     * by making the `nonReentrant` function external, and make it call a
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
}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import {IERC20} from "../interfaces/IERC20.sol";

/// @notice Safe IERC20 and ETH transfer library that safely handles missing return values.
/// @author Modified from Uniswap (https://github.com/Uniswap/uniswap-v3-periphery/blob/main/contracts/libraries/TransferHelper.sol)
/// Taken from Solmate
library SafeERC20 {
    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FROM_FAILED");
    }

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.transfer.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "TRANSFER_FAILED");
    }

    function safeApprove(
        IERC20 token,
        address to,
        uint256 amount
    ) internal {
        (bool success, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20.approve.selector, to, amount)
        );

        require(success && (data.length == 0 || abi.decode(data, (bool))), "APPROVE_FAILED");
    }

    function safeTransferETH(address to, uint256 amount) internal {
        (bool success, ) = to.call{value: amount}(new bytes(0));

        require(success, "ETH_TRANSFER_FAILED");
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.7.5;


// TODO(zx): Replace all instances of SafeMath with OZ implementation
library SafeMath {

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    // Only used in the  BondingCalculator.sol
    function sqrrt(uint256 a) internal pure returns (uint c) {
        if (a > 3) {
            c = a;
            uint b = add( div( a, 2), 1 );
            while (b < c) {
                c = b;
                b = div( add( div( a, b ), b), 2 );
            }
        } else if (a != 0) {
            c = 1;
        }
    }

}

// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.7.5;

import "../interfaces/IFloorAuthority.sol";

abstract contract FloorAccessControlled {

    /* ========== EVENTS ========== */

    event AuthorityUpdated(IFloorAuthority indexed authority);

    string UNAUTHORIZED = "UNAUTHORIZED"; // save gas

    /* ========== STATE VARIABLES ========== */

    IFloorAuthority public authority;


    /* ========== Constructor ========== */

    constructor(IFloorAuthority _authority) {
        authority = _authority;
        emit AuthorityUpdated(_authority);
    }
    

    /* ========== MODIFIERS ========== */
    
    modifier onlyGovernor() {
        require(msg.sender == authority.governor(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyGuardian() {
        require(msg.sender == authority.guardian(), UNAUTHORIZED);
        _;
    }
    
    modifier onlyPolicy() {
        require(msg.sender == authority.policy(), UNAUTHORIZED);
        _;
    }

    modifier onlyVault() {
        require(msg.sender == authority.vault(), UNAUTHORIZED);
        _;
    }
    
    /* ========== GOV ONLY ========== */
    
    function setAuthority(IFloorAuthority _newAuthority) external onlyGovernor {
        authority = _newAuthority;
        emit AuthorityUpdated(_newAuthority);
    }
}

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

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
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

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

// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity >=0.7.5;

interface IFloorAuthority {
    /* ========== EVENTS ========== */
    
    event GovernorPushed(address indexed from, address indexed to, bool _effectiveImmediately);
    event GuardianPushed(address indexed from, address indexed to, bool _effectiveImmediately);    
    event PolicyPushed(address indexed from, address indexed to, bool _effectiveImmediately);    
    event VaultPushed(address indexed from, address indexed to, bool _effectiveImmediately);    

    event GovernorPulled(address indexed from, address indexed to);
    event GuardianPulled(address indexed from, address indexed to);
    event PolicyPulled(address indexed from, address indexed to);
    event VaultPulled(address indexed from, address indexed to);

    /* ========== VIEW ========== */
    
    function governor() external view returns (address);
    function guardian() external view returns (address);
    function policy() external view returns (address);
    function vault() external view returns (address);
}