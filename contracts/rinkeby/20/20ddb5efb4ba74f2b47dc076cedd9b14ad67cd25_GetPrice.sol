/**
 *Submitted for verification at Etherscan.io on 2022-08-01
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
contract Ownable {
    /**
     * @dev Error constants.
     */
    string public constant NOT_CURRENT_OWNER = '018001';
    string public constant CANNOT_TRANSFER_TO_ZERO_ADDRESS = '018002';

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

    struct TokenOwnership { address addr; uint64 startTimestamp; bool burned; uint24 extraData; }
    function totalSupply() external view returns (uint256);
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    function balanceOf(address owner) external view returns (uint256 balance);
    function ownerOf(uint256 tokenId) external view returns (address owner);
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
    function safeTransferFrom(address from, address to, uint256 tokenId) external;
    function transferFrom(address from, address to, uint256 tokenId) external;
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
    function tokensOfOwnerIn(address owner, uint256 start, uint256 stop) external view returns (uint256[] memory);

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
  function getPrice(address, uint256) external returns(uint256);
  function getOnlyPrice(address, uint256) external view returns(uint256);
  function setUsed(uint256[] calldata, address, bool) external;
  function isUsed(uint256) external view returns(bool);
  function getData(uint256) external view returns(used memory);
  function getUser(address) external view returns(user memory);

  struct used {
    address user;
    bool used;
    uint256 timestamp;
  }

  struct user {
    uint256 discount1;
    uint256 discount2;
    uint256 claimed;
  }
}



contract GetPrice is IGetPrice, Ownable {
  mapping(uint256 => used) usedNft;
  mapping(address => user) claimed;

  // two discounts 20% and 50%
  // if wallet mints one at 50%, they must hold a any 50% at time of next mint
  // only 2 discount mints per wallet (in total)
  // if wallet mints one at 20%, obtaining an unused 50% is the only way to get a 50% mint

  uint256 price;
  uint256 discount1; // 50%
  uint256 discount2; // 20%
  // uint256 discount3;

  uint256 tierIndex0;
  uint256 tierIndex1;
  uint256 tierIndex2;
  // uint256 tierIndex3;

  address nftContract;
  IERC721AQueryable airdropContract;
  enum PRICE{PRICE1, PRICE2, PRICE3}

  function setPrice(uint256 price_, uint256 discount1_, uint256 discount2_/* , uint256 discount3_ */) public onlyOwner {
    price = price_;
    discount1 = discount1_;
    discount2 = discount2_;
    // discount3 = discount3_;
  }

  function setContract(address nftContract_, IERC721AQueryable airdropContract_) public onlyOwner {
    nftContract = nftContract_;
    airdropContract = airdropContract_;
  }

  function setTierIndex(uint256 tierIndex0_, uint256 tierIndex1_, uint256 tierInder2_/* , uint256 tierIndex3_ */) public onlyOwner {
    tierIndex0 = tierIndex0_;
    tierIndex1 = tierIndex1_;
    tierIndex2 = tierInder2_;
    // tierIndex3 = tierIndex3_;
  }

  function _price() public view returns(uint256) { return price; }
  function _discount1() public view returns(uint256) { return discount1; }
  function _discount2() public view returns(uint256) { return discount2; }
  // function _discount3() public view returns(uint256) { return discount3; }
  function _nftContract() public view returns(address) { return nftContract; }

  function getPrice(address account_, uint256 amount_) public override(IGetPrice) returns(uint256) {
    require(msg.sender == nftContract, "Only NFT contract can call");
    user storage user_ = claimed[account_];
    uint256 i;
    uint256 length;
    bool unused_;
    bool used_;
    uint256 balance = airdropContract.balanceOf(account_);
    if(balance == 0 || user_.claimed >= 2) { return price * amount_; } // check if no nfts or claimed 2 discounts already

    // check 50% airdrop NFTs
    uint256[] memory tokens1 = airdropContract.tokensOfOwnerIn(account_, tierIndex0, tierIndex1);
    length = tokens1.length;
    unchecked {
      used_ = length != 0;
      for(i=0; length != i;) {
        if(usedNft[tokens1[i]].used) {
          unused_ = true;
          setUsed(tokens1[i], account_, true, block.timestamp);
        }
        ++i;
      }
    }

    // check 20% airdrop NFTs
    uint256[] memory tokens2 = airdropContract.tokensOfOwnerIn(account_, tierIndex1+1, tierIndex2);
    length = tokens2.length;
    unchecked {
      for(i=0; length != i;) {
        if(usedNft[tokens2[i]].used) {
          setUsed(tokens2[i], account_, true, block.timestamp);
        }
        ++i;
      }
    }

    if(user_.claimed == 1) {
      user_.claimed = 2;
      if(user_.discount1 == 1 && used_) { // needs any 50%
        return discount1 + ((amount_ - 1) * price);
      }
      else { // if(user_.discount2 == 1) needs unused 50%
        return (unused_ ? discount1 : discount2) + ((amount_ - 1) * price);
      }
    } else {
      user_.claimed = 2;
      return 2*(unused_ ? discount1 : discount2) + ((amount_ - 2) * price);
    }
  }

  function getOnlyPrice(address account_, uint256 amount_) public view override(IGetPrice) returns(uint256) {
    require(msg.sender == nftContract, "Only NFT contract can call");
    user memory user_ = claimed[account_];
    uint256 i;
    uint256 length;
    bool unused_;
    bool used_;
    uint256 balance = airdropContract.balanceOf(account_);
    if(balance == 0 || user_.claimed >= 2) { return price * amount_; } // check if no nfts or claimed 2 discounts already

    // check 50% airdrop NFTs
    uint256[] memory tokens1 = airdropContract.tokensOfOwnerIn(account_, tierIndex0, tierIndex1);
    length = tokens1.length;
    unchecked {
      used_ = length != 0;
      for(i=0; length != i;) {
        if(usedNft[tokens1[i]].used) { unused_ = true; }
        ++i;
      }
    }

    if(user_.claimed == 1) {
      if(user_.discount1 == 1 && used_) { // needs any 50%
        return discount1 + ((amount_ - 1) * price);
      }
      else { // if(user_.discount2 == 1) needs unused 50%
        return (unused_ ? discount1 : discount2) + ((amount_ - 1) * price);
      }
    } else {
      return 2*(unused_ ? discount1 : discount2) + ((amount_ - 2) * price);
    }
  }

  function setUsed(uint256 id_, address user_, bool used_, uint256 timestamp_) internal {
    usedNft[id_] = used(user_, used_, timestamp_);
  }

  function setUsed(uint256[] calldata tokenId_, address user_, bool state) public virtual override(IGetPrice) onlyOwner {
    unchecked {
      uint256 last = tokenId_.length;
      for(uint256 i=0; last != i;) {
        require(user_ == airdropContract.ownerOf(tokenId_[i]), "Not owner of NFT");
        setUsed(tokenId_[i], user_, state, block.timestamp);
        ++i;
      }
    }
  }

  function isUsed(uint256 tokenId_) external view override(IGetPrice) returns(bool) {
    return usedNft[tokenId_].used;
  }
  function getData(uint256 tokenId_) external view override(IGetPrice) returns(used memory) {
    return usedNft[tokenId_];
  }
  function getUser(address user_) external view override(IGetPrice) returns(user memory) {
    return claimed[user_];
  }
}