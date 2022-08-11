/**
 *Submitted for verification at Etherscan.io on 2022-08-11
*/

/**
 * This contract is developed in conjunction with:
 * OmniHorse
 *
 * Homepage: https://omnihorse.io
 * Twitter:  https://twitter.com/omnihorse_nft
 *
 * ============================================================================
 * Price controller contract for OmniHorse NFT
 * 
 * The purpose of this contract is govern discounts to users who won or bought
 * our airdropped NFT tokens, Omnihorse Riding Equipment, listed on Opensea
 * https://opensea.io/collection/omnihorse-riding-equipment
 *
 * ============================================================================
 * How it works?
 * Ex:
 *     Airdrop supply: 10_000
 *
 * Users with an Airdrop NFT get a discount price
 *
 * Each user has a limit of two discounted mints per wallet
 * Each Airdrop NFT has a voucher status, once used to mint an NFT it's status
 * becomes used, please visit our site to interact with our contracts to 
 * check if a specific ID is a valid voucher
 */

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

contract Ownable {
  /**
   * @dev Error constants.
   */
  string public constant NOT_CURRENT_OWNER = "018001";
  string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = "018002";

  /**
   * @dev Current owner address.
   */
  address public owner;

  /**
   * @dev An event which is triggered when the owner is changed.
   * @param previousOwner The address of the previous owner.
   * @param newOwner The address of the new owner.
   */
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  /**
   * @dev The constructor sets the original `owner` of the contract to the sender account.
   */
  constructor() {
    owner = msg.sender;
  }

  /**
   * @dev Throws if called by any account other than the owner.
   */
  modifier onlyOwner() {
    require(msg.sender == owner, NOT_CURRENT_OWNER);
    _;
  }

  /**
   * @dev Allows the current owner to transfer control of the contract to a newOwner.
   * @param _newOwner The address to transfer ownership to.
   */
  function transferOwnership(address _newOwner) public onlyOwner {
    require(_newOwner != address(0), CANNOT_TRANSFER_TO_ZERO_ADDRESS);
    emit OwnershipTransferred(owner, _newOwner);
    owner = _newOwner;
  }
}

interface IERC721A {
  error ApprovalCallerNotOwnerNorApproved();
  error ApprovalQueryForNonexistentToken();
  error ApproveToCaller();
  error BalanceQueryForZeroAddress();
  error MintToZeroAddress();
  error MintZeroQuantity();
  error OwnerQueryForNonexistentToken();
  error TransferCallerNotOwnerNorApproved();
  error TransferFromIncorrectOwner();
  error TransferToNonERC721ReceiverImplementer();
  error TransferToZeroAddress();
  error URIQueryForNonexistentToken();
  error MintERC2309QuantityExceedsLimit();
  error OwnershipNotInitializedForExtraData();

  struct TokenOwnership {
    address addr;
    uint64 startTimestamp;
    bool burned;
    uint24 extraData;
  }

  function totalSupply() external view returns (uint256);

  function supportsInterface(bytes4 interfaceId) external view returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
  event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
  event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

  function balanceOf(address owner) external view returns (uint256 balance);

  function ownerOf(uint256 tokenId) external view returns (address owner);

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId,
    bytes calldata data
  ) external;

  function safeTransferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function transferFrom(
    address from,
    address to,
    uint256 tokenId
  ) external;

  function approve(address to, uint256 tokenId) external;

  function setApprovalForAll(address operator, bool _approved) external;

  function getApproved(uint256 tokenId) external view returns (address operator);

  function isApprovedForAll(address owner, address operator) external view returns (bool);

  function name() external view returns (string memory);

  function symbol() external view returns (string memory);

  function tokenURI(uint256 tokenId) external view returns (string memory);

  event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

interface IERC721AQueryable is IERC721A {
  /**
   * Invalid query range (`start` >= `stop`).
   */
  error InvalidQueryRange();

  /**
   * @dev Returns the `TokenOwnership` struct at `tokenId` without reverting.
   *
   * If the `tokenId` is out of bounds:
   *   - `addr` = `address(0)`
   *   - `startTimestamp` = `0`
   *   - `burned` = `false`
   *
   * If the `tokenId` is burned:
   *   - `addr` = `<Address of owner before token was burned>`
   *   - `startTimestamp` = `<Timestamp when token was burned>`
   *   - `burned = `true`
   *
   * Otherwise:
   *   - `addr` = `<Address of owner>`
   *   - `startTimestamp` = `<Timestamp of start of ownership>`
   *   - `burned = `false`
   */
  function explicitOwnershipOf(uint256 tokenId) external view returns (TokenOwnership memory);

  /**
   * @dev Returns an array of `TokenOwnership` structs at `tokenIds` in order.
   * See {ERC721AQueryable-explicitOwnershipOf}
   */
  function explicitOwnershipsOf(uint256[] memory tokenIds) external view returns (TokenOwnership[] memory);

  /**
   * @dev Returns an array of token IDs owned by `owner`,
   * in the range [`start`, `stop`)
   * (i.e. `start <= tokenId < stop`).
   *
   * This function allows for tokens to be queried if the collection
   * grows too big for a single call of {ERC721AQueryable-tokensOfOwner}.
   *
   * Requirements:
   *
   * - `start` < `stop`
   */
  function tokensOfOwnerIn(
    address owner,
    uint256 start,
    uint256 stop
  ) external view returns (uint256[] memory);

  /**
   * @dev Returns an array of token IDs owned by `owner`.
   *
   * This function scans the ownership mapping and is O(totalSupply) in complexity.
   * It is meant to be called off-chain.
   *
   * See {ERC721AQueryable-tokensOfOwnerIn} for splitting the scan into
   * multiple smaller scans if the collection is large enough to cause
   * an out-of-gas error (10K pfp collections should be fine).
   */
  function tokensOfOwner(address owner) external view returns (uint256[] memory);
}

interface IGetPrice {
  /**
   * @dev Get the price from the price controller contract and save user and voucher data
   */
  function getPrice(address, uint256) external returns (uint256);

  /**
   * @dev Get only the price from the price controller contract
   */
  function getOnlyPrice(address, uint256) external view returns (uint256);

  /**
   * @dev Set the voucher data for one or many vouchers given the aidrop NFT ID(s)
   */
  function setUsed(
    uint256[] calldata,
    address,
    bool
  ) external;

  /**
   * @dev Get the voucher status given an airdrop NFT ID
   */
  function isUsed(uint256) external view returns (bool);

  /**
   * @dev Get the voucher data given an airdrop NFT ID
   */
  function getData(uint256) external view returns (used memory);

  /**
   * @dev Get user data given an address
   */
  function getUser(address) external view returns (user memory);

  struct used {
    address user;
    bool used;
    uint256 timestamp;
  }

  struct user {
    uint256 discount;
    uint256 claimed;
  }
}

contract PriceController is IGetPrice, Ownable {
  mapping(uint256 => used) usedNft;
  mapping(address => user) claimed;

  // only 2 discount mints per wallet (in total)
  uint256 price;
  uint256 discount;

  address nftContract;
  IERC721AQueryable airdropContract;

  /**
   * @dev Admin can set the different price tiers
   *
   * @param price_ general price for buying NFTs
   * @param discount_ discount for buying NFT given the user owns and ID
   * between tierIndex0 and tierIndex1
   */
  function setPrice(
    uint256 price_,
    uint256 discount_
  ) public onlyOwner {
    price = price_;
    discount = discount_;
  }

  /**
   * @dev Admin can set the NFT contract that governs the price controller data
   * and the NFT contract houses airdrop NFTs
   *
   * @param nftContract_ NFT contract
   * @param airdropContract_ airdrop NFT contract
   */
  function setContract(address nftContract_, IERC721AQueryable airdropContract_) public onlyOwner {
    nftContract = nftContract_;
    airdropContract = airdropContract_;
  }

  /**
   * @dev Return default price
   */
  function _price() public view returns (uint256) {
    return price;
  }

  /**
   * @dev Return discount price
   */
  function _discount() public view returns (uint256) {
    return discount;
  }

  /**
   * @dev Return the NFT contract
   */
  function _nftContract() public view returns (address) {
    return nftContract;
  }

  /**
   * @dev Return the aidrop NFT contract
   */
  function _airdropContract() public view returns (address) {
    return address(airdropContract);
  }

  /**
   * @dev Get the price from the price controller contract and save user and voucher data
   *
   * @param account_ msg.sender address from the NFT contract
   * @param amount_ requested tokens for purchase
   * @return the adjusted price after all applicable discounts
   */
  function getPrice(address account_, uint256 amount_) public returns (uint256) {
    require(msg.sender == nftContract, "Only NFT contract can call");
    require(amount_ > 0, "Cannot mint zero");
    user storage user_ = claimed[account_];
    uint256[] memory airdropTokens = airdropContract.tokensOfOwner(account_);
    uint256 size = airdropTokens.length;
    uint256 unused;

    if (size == 0 || user_.claimed >= 2) { return price * amount_; }

     if(size == 1 || user_.claimed == 1 || amount_ == 1) {
      for(uint256 i=0; i<size; ) {
        if(!usedNft[airdropTokens[i]].used) { 
          unchecked { ++user_.claimed; }
          setUsed2(airdropTokens[i], account_, true, block.timestamp);
          return discount + (amount_ - 1) * price;
        }
        unchecked { ++i; }
      }
    }

    if(size > 1) {
      for(uint256 i=0; i<size; ) {
        if(unused < 2) {
          if(!usedNft[airdropTokens[i]].used) { 
            unchecked { 
              ++unused;
              ++user_.claimed;
            }
            setUsed2(airdropTokens[i], account_, true, block.timestamp);
          }
        }
        unchecked { ++i; }
      }
    }
    return unused * discount + (amount_ - unused) * price;
  }

  /**
   * @dev Get only the price from the price controller contract
   *
   * @param account_ msg.sender address from the NFT contract
   * @param amount_ requested tokens for purchase
   * @return the adjusted price after all applicable discounts
   */
  function getOnlyPrice(address account_, uint256 amount_) external view override(IGetPrice) returns (uint256) {
    require(msg.sender == nftContract, "Only NFT contract can call");
    require(amount_ > 0, "Cannot mint zero");
    user storage user_ = claimed[account_];
    uint256[] memory airdropTokens = airdropContract.tokensOfOwner(account_);
    uint256 size = airdropTokens.length;
    uint256 unused;

    if (size == 0 || user_.claimed >= 2) { return price * amount_; }

     if(size == 1 || user_.claimed == 1 || amount_ == 1) {
      for(uint256 i=0; i<size; ) {
        if(!usedNft[airdropTokens[i]].used) {
          return discount + (amount_ - 1) * price;
        }
        unchecked { ++i; }
      }
    }

    if(size > 1) {
      for(uint256 i=0; i<size; ) {
        if(unused < 2) {
          if(!usedNft[airdropTokens[i]].used) { 
            unchecked { ++unused; }
          }
        }
        unchecked { ++i; }
      }
    }
    return unused * discount + (amount_ - unused) * price;
  }

  /**
   * @dev Set the voucher data for a voucher given the aidrop NFT ID
   *
   * @param id_ aidrop NFT voucher
   * @param user_ user who minted NFTs using voucher
   * @param state_ set new status for voucher
   * @param timestamp_ timestamp of when voucher was used
   */
  function setUsed2(
    uint256 id_,
    address user_,
    bool state_,
    uint256 timestamp_
  ) internal {
    usedNft[id_] = used(user_, state_, timestamp_);
  }

  /**
   * @dev Admin can set the voucher data for one or many vouchers given the aidrop NFT ID(s)
   *
   * @param tokenId_ aidrop NFT voucher
   * @param user_ user who minted NFTs using voucher
   * @param state_ set new status for voucher
   */
  function setUsed(
    uint256[] calldata tokenId_,
    address user_,
    bool state_
  ) public virtual override(IGetPrice) onlyOwner {
    unchecked {
      uint256 last = tokenId_.length;
      for (uint256 i = 0; last != i; ) {
        require(user_ == airdropContract.ownerOf(tokenId_[i]), "Not owner of NFT");
        setUsed2(tokenId_[i], user_, state_, block.timestamp);
        ++i;
      }
    }
  }

  /**
   * @dev Get the voucher status given an airdrop NFT ID
   *
   * @param id_ aidrop NFT ID
   */
  function isUsed(uint256 id_) external view override(IGetPrice) returns (bool) {
    return usedNft[id_].used;
  }

  /**
   * @dev Get the voucher data given an airdrop NFT ID
   *
   * @param id_ aidrop NFT ID
   */
  function getData(uint256 id_) external view override(IGetPrice) returns (used memory) {
    return usedNft[id_];
  }

  /**
   * @dev Get user data given an address
   *
   * @param user_ user address
   */
  function getUser(address user_) external view override(IGetPrice) returns (user memory) {
    return claimed[user_];
  }
}