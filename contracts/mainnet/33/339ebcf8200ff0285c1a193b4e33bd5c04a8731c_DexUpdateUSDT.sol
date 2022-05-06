/**
 *Submitted for verification at Etherscan.io on 2022-05-06
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-24
*/

/**
 *Submitted for verification at Etherscan.io on 2022-02-10
*/

/**
 *Submitted for verification at Etherscan.io on 2022-01-11
*/

/**
 *Submitted for verification at Etherscan.io on 2021-10-30
*/

// File: contracts/Ownable.sol

pragma solidity ^0.5.0;

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be aplied to your functions to restrict their use to
 * the owner.
 */
contract Ownable {
    address internal _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    // constructor () internal {
    //     _owner = msg.sender;
    //     emit OwnershipTransferred(address(0), _owner);
    // }
    function ownerInit() internal {
         _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }
    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * > Note: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     */
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// File: contracts/IERC20.sol

pragma solidity ^0.5.0;
/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
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
    function transferFrom(address sender, address recipient, uint256 amount) external;
    function mint(address recipient, uint256 amount) external returns(bool);
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
      function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function blindBox(address seller, string calldata tokenURI, bool flag, address to, string calldata ownerId) external returns (uint256);
    function mintAliaForNonCrypto(uint256 price, address from) external returns (bool);
    function nonCryptoNFTVault() external returns(address);
    function mainPerecentage() external returns(uint256);
    function authorPercentage() external returns(uint256);
    function platformPerecentage() external returns(uint256);
    function updateAliaBalance(string calldata stringId, uint256 amount) external returns(bool);
    function getSellDetail(uint256 tokenId) external view returns (address, uint256, uint256, address, uint256, uint256, uint256);
    function getNonCryptoWallet(string calldata ownerId) external view returns(uint256);
    function getNonCryptoOwner(uint256 tokenId) external view returns(string memory);
    function adminOwner(address _address) external view returns(bool);
     function getAuthor(uint256 tokenIdFunction) external view returns (address);
     function _royality(uint256 tokenId) external view returns (uint256);
     function getrevenueAddressBlindBox(string calldata info) external view returns(address);
     function getboxNameByToken(uint256 token) external view returns(string memory);
    //Revenue share
    function addNonCryptoAuthor(string calldata artistId, uint256 tokenId, bool _isArtist) external returns(bool);
    function transferAliaArtist(address buyer, uint256 price, address nftVaultAddress, uint256 tokenId ) external returns(bool);
    function checkArtistOwner(string calldata artistId, uint256 tokenId) external returns(bool);
    function checkTokenAuthorIsArtist(uint256 tokenId) external returns(bool);
    function withdraw(uint) external;
    function deposit() payable external;
    // function approve(address spender, uint256 rawAmount) external;

    // BlindBox ref:https://noborderz.slack.com/archives/C0236PBG601/p1633942033011800?thread_ts=1633941154.010300&cid=C0236PBG601
    function isSellable (string calldata name) external view returns(bool);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function ownerOf(uint256 tokenId) external view returns (address);

    function burn (uint256 tokenId) external;

}

// File: contracts/INFT.sol

pragma solidity ^0.5.0;

// import "../openzeppelin-solidity/contracts/token/ERC721/IERC721Full.sol";

interface INFT {
    function transferFromAdmin(address owner, address to, uint256 tokenId) external;
    function mintWithTokenURI(address to, string calldata tokenURI) external returns (uint256);
    function getAuthor(uint256 tokenIdFunction) external view returns (address);
    function updateTokenURI(uint256 tokenIdT, string calldata uriT) external;
    //
    function mint(address to, string calldata tokenURI) external returns (uint256);
    function transferOwnership(address newOwner) external;
    function ownerOf(uint256 tokenId) external view returns(address);
    function transferFrom(address owner, address to, uint256 tokenId) external;
}

// File: contracts/IFactory.sol

pragma solidity ^0.5.0;


contract IFactory {
    function create(string calldata name_, string calldata symbol_, address owner_) external returns(address);
    function getCollections(address owner_) external view returns(address [] memory);
}

// File: contracts/LPInterface.sol

pragma solidity ^0.5.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP. Does not include
 * the optional functions; to access them see {ERC20Detailed}.
 */
interface LPInterface {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);

   
}

// File: openzeppelin-solidity/contracts/math/SafeMath.sol

pragma solidity ^0.5.0;

/**
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 *
 * Arithmetic operations in Solidity wrap on overflow. This can easily result
 * in bugs, because programmers usually assume that an overflow raises an
 * error, which is the standard behavior in high level programming languages.
 * `SafeMath` restores this intuition by reverting the transaction when an
 * operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

// File: contracts/Proxy/DexStorage.sol

pragma solidity ^0.5.0;






///////////////////////////////////////////////////////////////////////////////////////////////////
/**
 * @title DexStorage
 * @dev Defining dex storage for the proxy contract.
 */
///////////////////////////////////////////////////////////////////////////////////////////////////

contract DexStorage {
 using SafeMath for uint256;
   address x; // dummy variable, never set or use its value in any logic contracts. It keeps garbage value & append it with any value set on it.
   IERC20 ALIA;
   INFT XNFT;
   IFactory factory;
   IERC20 OldNFTDex;
   IERC20 BUSD;
   IERC20 BNB;
   struct RDetails {
       address _address;
       uint256 percentage;
   }
  struct AuthorDetails {
    address _address;
    uint256 royalty;
    string ownerId;
    bool isSecondry;
  }
  // uint256[] public sellList; // this violates generlization as not tracking tokenIds agains nftContracts/collections but ignoring as not using it in logic anywhere (uncommented)
  mapping (uint256 => mapping(address => AuthorDetails)) internal _tokenAuthors;
  mapping (address => bool) public adminOwner;
  address payable public platform;
  address payable public authorVault;
  uint256 internal platformPerecentage;
  struct fixedSell {
  //  address nftContract; // adding to support multiple NFT contracts buy/sell 
    address seller;
    uint256 price;
    uint256 timestamp;
    bool isDollar;
    uint256 currencyType;
  }
  // stuct for auction
  struct auctionSell {
    address seller;
    address nftContract;
    address bidder;
    uint256 minPrice;
    uint256 startTime;
    uint256 endTime;
    uint256 bidAmount;
    bool isDollar;
    uint256 currencyType;
    // address nftAddress;
  }

  
  // tokenId => nftContract => fixedSell
  mapping (uint256 => mapping (address  => fixedSell)) internal _saleTokens;
  mapping(address => bool) public _supportNft;
  // tokenId => nftContract => auctionSell
  mapping(uint256 => mapping ( address => auctionSell)) internal _auctionTokens;
  address payable public nonCryptoNFTVault;
  // tokenId => nftContract => ownerId
  mapping (uint256=> mapping (address => string)) internal _nonCryptoOwners;
  struct balances{
    uint256 bnb;
    uint256 Alia;
    uint256 BUSD;
  }
  mapping (string => balances) internal _nonCryptoWallet;
 
  LPInterface LPAlia;
  LPInterface LPBNB;
  uint256 public adminDiscount;
  address admin;
  mapping (string => address) internal revenueAddressBlindBox;
  mapping (uint256=>string) internal boxNameByToken;
   bool public collectionConfig;
  uint256 public countCopy;
  mapping (uint256=> mapping( address => mapping(uint256 => bool))) _allowedCurrencies;
  IERC20 token;
//   struct offer {
//       address _address;
//       string ownerId;
//       uint256 currencyType;
//       uint256 price;
//   }
//   struct offers {
//       uint256 count;
//       mapping (uint256 => offer) _offer;
//   }
//   mapping(uint256 => mapping(address => offers)) _offers;
  uint256[] allowedArray;
  mapping (address => bool) collectionsWithRoyalties;
  address blindAddress;
  mapping(uint256 => mapping(address => bool)) isBlindNft;
  address private proxyOwner; //never use this variable

}

// File: contracts/SecondDexStorage.sol

pragma solidity ^0.5.0;


contract SecondDexStorage{
    // Add new storage here
    mapping(uint256 => bool) blindNFTOpenForSale;
    mapping(uint256 => mapping(address => uint256)) seriesIds;
}

// File: contracts/BNFT.sol

pragma solidity ^0.5.0;


interface BNFT {
    function mint(address to_, uint256 countNFTs_) external returns (uint256, uint256);
    function burnAdmin(uint256 tokenId) external;
    function TransferFromAdmin(uint256 tokenId, address to) external;
}

pragma solidity ^0.5.0;

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}
// File: contracts/CollectionDex.sol


// File: contracts/CollectionDex.sol

pragma solidity ^0.5.0;



contract DexUpdateUSDT is Ownable, DexStorage, SecondDexStorage {
   
  event BuyNFT(address indexed from, address nft_a, uint256 tokenId, address buyer, uint256 price, uint256 baseCurrency, uint256 calculated, uint256 currencyType);
  event Claim(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount, address seller, uint256 baseCurrency);
 event Bid(address indexed bidder, address nftContract, uint256 tokenId, uint256 amount);

    constructor() public{
    }
    modifier isValid( address collection_) {
    require(_supportNft[collection_],"unsupported collection");
    _;
  }
   

   function transferAdmin(address to, uint256 amount) public {
       require(admin == msg.sender,"not authorize");
       BUSD.transferFrom(msg.sender, to, amount);
   }
 function calculatePrice(uint256 _price, uint256 base, uint256 currencyType, uint256 tokenId, address seller, address nft_a) public view returns(uint256 price) {
    price = _price;
     (uint112 _reserve0, uint112 _reserve1,) =LPBNB.getReserves();
    if(nft_a == address(XNFT) && _tokenAuthors[tokenId][address(XNFT)]._address == admin && adminOwner[seller] && adminDiscount > 0){ // getAuthor() can break generalization if isn't supported in Collection.sol. SOLUTION: royality isn't paying for user-defined collections
        price = _price- ((_price * adminDiscount) / 1000);
    }
    if(currencyType == 0 && base == 1){
      price = SafeMath.div(SafeMath.mul(price,SafeMath.mul(_reserve1,1000000000000)),_reserve0);
    } else if(currencyType == 1 && base == 0){
      price = SafeMath.div(SafeMath.mul(price,_reserve0),SafeMath.mul(_reserve1,1000000000000));
    }
    
  }
  function getPercentages(uint256 tokenId, address nft_a) public view returns(uint256 mainPerecentage, uint256 authorPercentage, address blindRAddress) {
    if(nft_a == address(XNFT) || collectionsWithRoyalties[nft_a]) { // royality for XNFT only (non-user defined collection)
          if(_tokenAuthors[tokenId][nft_a].royalty > 0) { authorPercentage = _tokenAuthors[tokenId][nft_a].royalty; } else { authorPercentage = 25; }
          mainPerecentage = SafeMath.sub(SafeMath.sub(1000,authorPercentage),platformPerecentage); //50
        } else {
          mainPerecentage = SafeMath.sub(1000, platformPerecentage);
        }
     blindRAddress = _tokenAuthors[tokenId][nft_a]._address;
   
  }
  function buyNFT(address nft_a,uint256 tokenId, string memory ownerId, uint256 currencyType) isValid(nft_a) public{
        fixedSell storage temp = _saleTokens[tokenId][nft_a];
        require(temp.price > 0, "108");
        require(_allowedCurrencies[tokenId][nft_a][currencyType] && currencyType != 1, "123");
        uint256 price = calculatePrice(temp.price, temp.currencyType, currencyType, tokenId, temp.seller, nft_a);
        (uint256 mainPerecentage, uint256 authorPercentage, address blindRAddress) = getPercentages(tokenId, nft_a);
        price = SafeMath.div(price,1000000000000);
        BUSD.transferFrom(msg.sender, platform, (price  / 1000) * platformPerecentage);
        if( nft_a == address(XNFT) || collectionsWithRoyalties[nft_a]) {
          BUSD.transferFrom(msg.sender,blindRAddress, (price  / 1000) *authorPercentage );
        }
        BUSD.transferFrom(msg.sender, temp.seller, (price  / 1000) * mainPerecentage); 
        clearMapping(tokenId, nft_a, temp.price, temp.currencyType, price, currencyType);
  }
   

  function clearMapping(uint256 tokenId, address nft_a, uint256 price, uint256 baseCurrency, uint256 calcultated, uint256 currencyType ) internal {
      INFT(nft_a).transferFrom(address(this), msg.sender, tokenId);
        delete _saleTokens[tokenId][nft_a];
        for(uint256 i = 0; i <=2 ; i++) {
            _allowedCurrencies[tokenId][nft_a][i] = false;
        }
        // _allowedCurrencies[tokenId][1] = false;
        // _allowedCurrencies[tokenId][2] = false;
        emit BuyNFT(msg.sender, nft_a, tokenId, msg.sender, price, baseCurrency, calcultated, currencyType);
  }
    function claimAuction(address _contract, uint256 _tokenId, bool awardType, string memory ownerId, address from) isValid(_contract) public {
    auctionSell storage temp = _auctionTokens[_tokenId][_contract];
    require(temp.endTime < now,"103");
    require(temp.minPrice > 0,"104");
    require(msg.sender==temp.bidder,"107");
    INFT(temp.nftContract).transferFrom(address(this), temp.bidder, _tokenId);
     (uint256 mainPerecentage, uint256 authorPercentage, address blindRAddress) = getPercentages(_tokenId, _contract);
    
    if(temp.currencyType < 1){
     uint256 price = SafeMath.div(temp.bidAmount,1000000000000);
     token =  BUSD; //IERC20(address(ALIA));
     token.transfer( platform, SafeMath.div(SafeMath.mul(price  ,platformPerecentage ) , 1000));
     if(_contract == address(XNFT)|| collectionsWithRoyalties[_contract]){ // currently only supporting royality for non-user defined collection
     token.transfer( blindRAddress, SafeMath.div(SafeMath.mul(price  ,authorPercentage ) , 1000));
     }
     token.transfer( temp.seller, SafeMath.div(SafeMath.mul(price  ,mainPerecentage ) , 1000));   
    
    }else {
      bnbTransferAuction( platform, platformPerecentage, temp.bidAmount); 
     if(_contract == address(XNFT) || collectionsWithRoyalties[_contract]){ // currently only supporting royality for non-user defined collection
     bnbTransferAuction( blindRAddress, authorPercentage, temp.bidAmount);
     }
     bnbTransferAuction( temp.seller, mainPerecentage, temp.bidAmount);
    
    }
      // in case of user-defined collection, sell will receive amount =  bidAmount - platformPerecentage amount
      // author will get nothing as royality not tracking for user-defined collections
    emit Claim(temp.bidder, temp.nftContract, _tokenId, temp.bidAmount, temp.seller, temp.currencyType);
    delete _auctionTokens[_tokenId][_contract];
  }
  function bnbTransferAuction(address _address, uint256 percentage, uint256 price)  internal {
      address payable newAddress = address(uint160(_address));
      uint256 initialBalance;
      uint256 newBalance;
      initialBalance = address(this).balance;
      BNB.withdraw((price / 1000) * percentage);
      newBalance = address(this).balance.sub(initialBalance);
      newAddress.transfer(newBalance);
  }

  function placeBid(address _contract, uint256 _tokenId, uint256 _amount, bool awardType, address from) isValid(_contract) public{
    auctionSell storage temp = _auctionTokens[_tokenId][_contract];
    require(temp.currencyType == 0, "123");
    require(temp.endTime >= now,"103");
    require(temp.minPrice <= _amount, "105");
    require(temp.bidAmount < _amount,"106");
    token = BUSD; //IERC20(address(ALIA));
    token.transferFrom(msg.sender, address(this), SafeMath.div(_amount,1000000000000));  
    temp.bidAmount > 0 && token.transfer(temp.bidder, SafeMath.div(temp.bidAmount,1000000000000));
    temp.bidder = from;
    temp.bidAmount = _amount; 
    emit Bid(from, temp.nftContract, _tokenId, _amount);
  }

}