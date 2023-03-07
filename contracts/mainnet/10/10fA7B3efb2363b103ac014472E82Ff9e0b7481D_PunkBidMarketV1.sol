// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

/// @notice Simple single owner authorization mixin.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/auth/Owned.sol)
abstract contract Owned {
    /*//////////////////////////////////////////////////////////////
                                 EVENTS
    //////////////////////////////////////////////////////////////*/

    event OwnershipTransferred(address indexed user, address indexed newOwner);

    /*//////////////////////////////////////////////////////////////
                            OWNERSHIP STORAGE
    //////////////////////////////////////////////////////////////*/

    address public owner;

    modifier onlyOwner() virtual {
        require(msg.sender == owner, "UNAUTHORIZED");

        _;
    }

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(address _owner) {
        owner = _owner;

        emit OwnershipTransferred(address(0), _owner);
    }

    /*//////////////////////////////////////////////////////////////
                             OWNERSHIP LOGIC
    //////////////////////////////////////////////////////////////*/

    function transferOwnership(address newOwner) public virtual onlyOwner {
        owner = newOwner;

        emit OwnershipTransferred(msg.sender, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// @notice Gas optimized merkle proof verification library.
/// @author Solmate (https://github.com/transmissions11/solmate/blob/main/src/utils/MerkleProofLib.sol)
/// @author Modified from Solady (https://github.com/Vectorized/solady/blob/main/src/utils/MerkleProofLib.sol)
library MerkleProofLib {
    function verify(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool isValid) {
        /// @solidity memory-safe-assembly
        assembly {
            if proof.length {
                // Left shifting by 5 is like multiplying by 32.
                let end := add(proof.offset, shl(5, proof.length))

                // Initialize offset to the offset of the proof in calldata.
                let offset := proof.offset

                // Iterate over proof elements to compute root hash.
                // prettier-ignore
                for {} 1 {} {
                    // Slot where the leaf should be put in scratch space. If
                    // leaf > calldataload(offset): slot 32, otherwise: slot 0.
                    let leafSlot := shl(5, gt(leaf, calldataload(offset)))

                    // Store elements to hash contiguously in scratch space.
                    // The xor puts calldataload(offset) in whichever slot leaf
                    // is not occupying, so 0 if leafSlot is 32, and 32 otherwise.
                    mstore(leafSlot, leaf)
                    mstore(xor(leafSlot, 32), calldataload(offset))

                    // Reuse leaf to store the hash to reduce stack operations.
                    leaf := keccak256(0, 64) // Hash both slots of scratch space.

                    offset := add(offset, 32) // Shift 1 word per cycle.

                    // prettier-ignore
                    if iszero(lt(offset, end)) { break }
                }
            }

            isValid := eq(leaf, root) // The proof is valid if the roots match.
        }
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import {Owned} from "solmate/auth/Owned.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";
import {IWETH9} from "./interfaces/IWETH9.sol";
import {ICryptoPunksMarket} from "./interfaces/ICryptoPunksMarket.sol";

error InvalidOffer();
error InvalidBid();

/// @title The punk.bid v1 contract
/// @notice A permissionless and on-chain bid-side order book for CryptoPunks  
contract PunkBidMarketV1 is Owned {
  /// @notice The WETH contract
  address public immutable WETH;

  /// @notice The CryptoPunks Market contract
  address public immutable CRYPTOPUNKS_MARKET;

  /// @notice The protocol fee earned on every sale
  uint256 public constant FEE = 0.25 ether;

  struct Bid {
    address bidder;
    uint96 expiration;
    uint256 weiAmount;
    bytes32 itemsChecksum;
  }

  struct BidUpdate {
    uint256 bidId;
    uint256 weiAmount;
  }

  /// @notice A mapping pointing bid ids to bid structs
  mapping(uint256 => Bid) public bids;

  /// @notice The next bid id to be created
  uint256 public nextBidId = 1;

  /// @notice Emitted when a bid is entered
  event BidEntered(
    uint256 indexed bidId,
    address indexed bidder,
    uint256 weiAmount,
    uint96 expiration,
    bytes32 itemsChecksum,
    string name,
    bytes cartMetadata
  );

  /// @notice Emitted when a bid is updated
  event BidUpdated(uint256 indexed bidId, uint256 weiAmount);

  /// @notice Emitted when a bid is cancelled
  event BidCancelled(uint256 indexed bidId);

  /// @notice Emitted when a bid is filled
  event BidFilled(
    uint256 indexed bidId,
    uint256 punkIndex,
    address seller,
    address bidder,
    uint256 weiAmount
  );

  constructor(address _WETH, address _CRYPTOPUNKS_MARKET) Owned(msg.sender) {
    WETH = _WETH;
    CRYPTOPUNKS_MARKET = _CRYPTOPUNKS_MARKET;
  }

  receive() external payable {}

  /// @notice Enter a new bid
  /// @param weiAmount The amount to bid on
  /// @param expiration The expiration date
  /// @param itemsChecksum The root hash of a merkle tree where each leaf is a hashed punk id
  /// @param name the name of your bid
  /// @param cartMetadata The metadata needed to infer the punks included in your bid
  /// @dev for more info on the cartMetadata format, see https://github.com/punkbid/punkbid-js-sdk
  function enterBid(
    uint256 weiAmount,
    uint96 expiration,
    bytes32 itemsChecksum,
    string calldata name,
    bytes calldata cartMetadata
  ) external {
    bids[nextBidId] = Bid(msg.sender, expiration, weiAmount, itemsChecksum);
    emit BidEntered(
      nextBidId++,
      msg.sender,
      weiAmount,
      expiration,
      itemsChecksum,
      name,
      cartMetadata
    );
  }

  /// @notice Update the price of your bids
  /// @param updates The ids of the bids to update along with their new price
  function updateBids(BidUpdate[] calldata updates) external {
    uint256 len = updates.length;

    for (uint256 i = 0; i < len; ) {
      BidUpdate calldata update = updates[i];
      require(bids[update.bidId].bidder == msg.sender);
      bids[update.bidId].weiAmount = update.weiAmount;
      emit BidUpdated(update.bidId, update.weiAmount);

      unchecked {
        ++i;
      }
    }
  }

  /// @notice Cancel your bids
  /// @param bidIds The ids of the bids to cancel
  function cancelBids(uint256[] calldata bidIds) external {
    uint256 len = bidIds.length;

    for (uint256 i = 0; i < len; ) {
      uint256 bidId = bidIds[i];
      require(bids[bidId].bidder == msg.sender);
      delete bids[bidId];
      emit BidCancelled(bidId);

      unchecked {
        ++i;
      }
    }
  }

  /// @notice Accept a bid and sell your punk
  /// @param punkIndex The id of the punk to be sold
  /// @param minWeiAmount The minimum amount of sale
  /// @param bidId The id of the bid to be sold into
  /// @param proof The merkle proof to validate the bid includes the punk to be sold
  function acceptBid(
    uint256 punkIndex,
    uint256 minWeiAmount,
    uint256 bidId,
    bytes32[] calldata proof
  ) external {
    ICryptoPunksMarket.Offer memory offer = ICryptoPunksMarket(
      CRYPTOPUNKS_MARKET
    ).punksOfferedForSale(punkIndex);
    if (!offer.isForSale || msg.sender != offer.seller || offer.minValue > 0)
      revert InvalidOffer();

    Bid memory bid = bids[bidId];
    if (
      bid.weiAmount < minWeiAmount ||
      bid.expiration < uint96(block.timestamp) ||
      !MerkleProofLib.verify(
        proof,
        bid.itemsChecksum,
        keccak256(abi.encodePacked(punkIndex))
      )
    ) revert InvalidBid();

    IWETH9(WETH).transferFrom(bid.bidder, address(this), bid.weiAmount);
    IWETH9(WETH).withdraw(bid.weiAmount);
    ICryptoPunksMarket(CRYPTOPUNKS_MARKET).buyPunk(punkIndex);
    ICryptoPunksMarket(CRYPTOPUNKS_MARKET).transferPunk(bid.bidder, punkIndex);

    emit BidFilled(bidId, punkIndex, msg.sender, bid.bidder, bid.weiAmount);
    delete bids[bidId];

    (bool sent, ) = msg.sender.call{value: bid.weiAmount - FEE}(new bytes(0));
    require(sent);
  }

  function withdraw() external onlyOwner {
    (bool sent, ) = msg.sender.call{value: address(this).balance}(new bytes(0));
    require(sent);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface ICryptoPunksMarket {
  struct Offer {
    bool isForSale;
    uint256 punkIndex;
    address seller;
    uint256 minValue;
    address onlySellTo;
  }

  function punksOfferedForSale(
    uint256 punkIndex
  ) external returns (Offer memory offer);

  function buyPunk(uint256 punkIndex) external payable;

  function offerPunkForSaleToAddress(uint256 punkIndex, uint256 minSalePriceInWei, address toAddress) external;

  function transferPunk(address to, uint256 punkIndex) external;

  function punkIndexToAddress(uint256) external returns (address);
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IWETH9 {
  function withdraw(uint wad) external;

  function transferFrom(
    address src,
    address dst,
    uint wad
  ) external returns (bool);

  function approve(address spender, uint256 amount) external returns (bool);

  function deposit() external payable;

  function balanceOf(address account) external view returns (uint256);
}