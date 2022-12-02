/**
 *Submitted for verification at Etherscan.io on 2022-12-01
*/

/**
 *Submitted for verification at Etherscan.io on 2022-11-26
*/

// File: @chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol


pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  function getRoundData(uint80 _roundId)
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );

  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}

// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


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

// File: contracts/MamMarketGoerli.sol

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.9;



abstract contract PriceConsumerV3 {
    AggregatorV3Interface internal priceFeed;

    /**
     * Network: Mainnet
     * Aggregator: ETH/USD
     * Address: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
     */
    constructor() {
        priceFeed = AggregatorV3Interface(
            0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        );
    }

    /**
     * Returns the latest price
     */
    function getLatestPrice() public view returns (int) {
        (
            ,
            /*uint80 roundID*/ int price /*uint startedAt*/ /*uint timeStamp*/ /*uint80 answeredInRound*/,
            ,
            ,

        ) = priceFeed.latestRoundData();
        return price;
    }
}

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}





interface IUniswapV2Pair {
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external pure returns (string memory);

    function symbol() external pure returns (string memory);

    function decimals() external pure returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);

    function DOMAIN_SEPARATOR() external view returns (bytes32);

    function PERMIT_TYPEHASH() external pure returns (bytes32);

    function nonces(address owner) external view returns (uint256);

    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Burn(
        address indexed sender,
        uint256 amount0,
        uint256 amount1,
        address indexed to
    );
    event Swap(
        address indexed sender,
        uint256 amount0In,
        uint256 amount1In,
        uint256 amount0Out,
        uint256 amount1Out,
        address indexed to
    );
    event Sync(uint112 reserve0, uint112 reserve1);

    function MINIMUM_LIQUIDITY() external pure returns (uint256);

    function factory() external view returns (address);

    function token0() external view returns (address);

    function token1() external view returns (address);

    function getReserves()
        external
        view
        returns (
            uint112 reserve0,
            uint112 reserve1,
            uint32 blockTimestampLast
        );

    function price0CumulativeLast() external view returns (uint256);

    function price1CumulativeLast() external view returns (uint256);

    function kLast() external view returns (uint256);

    function mint(address to) external returns (uint256 liquidity);

    function burn(address to)
        external
        returns (uint256 amount0, uint256 amount1);

    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function skim(address to) external;

    function sync() external;

    function initialize(address, address) external;
}


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

abstract contract ERC165 is IERC165 {
    /**
     * @dev Mapping of interface ids to whether or not it's supported.
     */
    mapping(bytes4 => bool) private _supportedInterfaces;

    constructor () {
        // Derived contracts need only register support for their own interfaces,
        // we register support for ERC165 itself here
        _registerInterface(type(IERC165).interfaceId);
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     *
     * Time complexity O(1), guaranteed to always use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return _supportedInterfaces[interfaceId];
    }

    /**
     * @dev Registers the contract as an implementer of the interface defined by
     * `interfaceId`. Support of the actual ERC165 interface is automatic and
     * registering its interface id is not required.
     *
     * See {IERC165-supportsInterface}.
     *
     * Requirements:
     *
     * - `interfaceId` cannot be the ERC165 invalid interface (`0xffffffff`).
     */
    function _registerInterface(bytes4 interfaceId) internal virtual {
        require(interfaceId != 0xffffffff, "ERC165: invalid interface id");
        _supportedInterfaces[interfaceId] = true;
    }
}



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

interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
}



contract NFTMarketplace is PriceConsumerV3 {
    using SafeMath for uint256;

    IERC20 public ammo;
    address public pairAddress = 0x3211963A74F6C76e39Ea91B3296ecf677e526E55;
    

    uint256 public count = 0;
    //Keeps track of the number of items sold on the marketplace
    uint256 public itemsSold = 0;
    //owner is the contract address that created the smart contract
    address payable owner;
    //The fee charged by the marketplace to be allowed to list an NFT
    
    

    //The structure to store info about a listed token
    struct ListedToken {
        uint256 listId;
        uint256 tokenId;
        IERC721 nft;
        uint256 minimumPriceIncrement;
        uint256 currentPrice;
        uint256 endTime;
        address currentWinner;
        bool auction;
        bool currentlyListed;
    }

    event BulkListing(uint256);
    event TimeReset(uint256, uint256);

    //the event emitted when a token is successfully listed
    event TokenListedSuccess (
        uint256 indexed listId,
        uint256 minimumPriceIncrement,
        uint256 initialPrice,
        uint256 endTime,
        bool auction,
        bool currentlyListed
    );

    //This mapping maps tokenId to token info and is helpful when retrieving details about a tokenId
    mapping(uint256 => ListedToken) private idToListedToken;
    mapping(uint256 => ListedToken) public listIds;
    uint256[] public activeList;
    uint256 public feedDecimals = 8;
    uint256 public decimals = 18;

    constructor(address _ammo) {
        owner = payable(msg.sender);
        ammo = IERC20(_ammo);
    }

    function getOwner() external view returns (address) {
        return owner;
    }

    function getTotalListed() public view returns (uint256) {
        return count - itemsSold;
    }

    
    
    function createListedToken(address _nft, uint256 tokenId, uint256 _initialPrice, uint256 _increment, uint256 _endTime) external {
        IERC721 nft = IERC721(_nft);
        require(msg.sender == owner, "Not authorized to list");
        require(nft.ownerOf(tokenId) == msg.sender, "Not the token owner or invalid tokenId");
        require(_initialPrice >= 0, "Make sure the price isn't negative");
        

        uint256 listId = count + 1;
        uint256 endTime;
        bool auction = false;

        if(_endTime > 0) {
            
            endTime = block.timestamp + _endTime;
            auction = true;
        }

        //Update the mapping of tokenId's to Token details, useful for retrieval functions
        listIds[listId] = ListedToken(
            listId,
            tokenId,
            nft,
            _increment,
            _initialPrice,
            endTime,
            msg.sender,
            auction,
            true
        );

        nft.transferFrom(msg.sender, address(this), tokenId);
        count++;
        activeList.push(listId);
        //Emit the event for successful transfer. The frontend parses this message and updates the end user
        emit TokenListedSuccess(
            listId,
            _increment,
            _initialPrice,
            endTime,
            auction,
            true
        );
    }

    function bulkListingCreate(address _nft, uint16[] calldata _tokenIds, uint256[] calldata _initialPrices, uint256[] calldata _increments, uint256[] calldata _endTimes) external {
        require(msg.sender == owner, "Not authorized to list");
        uint256 endTime;
        uint256 listId;
        bool auction;
        uint16 tokenId;
        IERC721 nft = IERC721(_nft);
        

        for(uint8 i; i < _tokenIds.length; i++) {
            tokenId = _tokenIds[i];
            require(nft.ownerOf(tokenId) == msg.sender, "Not the token owner or invalid tokenId");
            

            listId = count + 1;

            auction = false;
            

        if(_endTimes[i] > 0) {
            
            endTime = block.timestamp + _endTimes[i];
            auction = true;
        }

        listIds[listId] = ListedToken(
            listId,
            _tokenIds[i],
            nft,
            _increments[i],
            _initialPrices[i],
            endTime,
            msg.sender,
            auction,
            true
        );

        nft.transferFrom(msg.sender, address(this), tokenId);
        count++;
        activeList.push(listId);

        }

        emit BulkListing(_tokenIds.length);

          
    }

    function getActiveListIds() public view returns (uint256[] memory) {
        uint256 nftCount = getTotalListed();
        uint256[] memory tokens = new uint256[](nftCount);
        uint256 currentIndex = 0;

        for(uint8 i = 0; i < activeList.length; i++) {
            if(activeList[i] != 0){
                tokens[currentIndex] = activeList[i];
                currentIndex++;
            }
        }
        return tokens;
    }
    
    

    function getEndTime(uint256 listId) public view returns (uint256) {
        return listIds[listId].endTime;
    }

    function getCurrentWinner(uint256 listId) public view returns (address) {
        return listIds[listId].currentWinner;
    }

    function isAuction(uint256 listId) public view returns (bool) {
        return listIds[listId].auction;
    }

    function getMinIncrement(uint256 listId) public view returns (uint256) {
        return listIds[listId].minimumPriceIncrement;
    }
 

    function getTrueTokenID(uint256 listId) public view returns (uint256){
        return listIds[listId].tokenId;
    }

    function getCurrentUSDPrice(uint256 listId) public view returns (uint256){
        return listIds[listId].currentPrice;
    }

    
    function getTokenPrice() public view returns(uint)
   {
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    //IERC20 token1 = IERC20(pair.token1());
    (uint Res0, uint Res1,) = pair.getReserves();

    // decimals
    
    return(Res0/Res1); // return amount of token0 needed to buy token1
   }

   function getRoundedETHPrice() public view returns (uint){
       uint256 rawPrice = uint256(getLatestPrice());
       uint256 ethPrice = rawPrice/10**feedDecimals;
       return ethPrice * 10**decimals;
   }

   function getPriceOfItem(uint256 listId) public view returns (uint, uint, uint, uint){
        uint256 usdPrice = (listIds[listId].currentPrice)*(10**feedDecimals);
        uint256 ethPrice = uint256(getLatestPrice());
        //uint256 tokenPrice = getTokenPrice();
        uint256 tokenPrice = getTokenPrice();
        uint256 ratio = ethPrice/tokenPrice;
        uint256 price = (usdPrice/ratio)*(10**decimals);


        return (usdPrice, ethPrice, tokenPrice, price);

   }

   function getUSDFromValue(uint256 value) public view returns (uint) {
       uint256 ethPrice = uint256(getLatestPrice());
       uint256 tokenPrice = getTokenPrice();
       //ammo value
       uint256 ammoValue = value/(10**decimals);
       //ammoValue * ethPrice/tokenPrice 
       uint256 newRatio = ethPrice / tokenPrice;
       uint256 usdPrice = ammoValue * newRatio;

       return usdPrice/(10**feedDecimals);

   }

   function getMinimumBid(uint256 listId) public view returns (uint) {
       (, uint256 ethPrice, uint256 tokenPrice, uint256 price) = getPriceOfItem(listId);
       uint256 minIncrementUSD = (listIds[listId].minimumPriceIncrement)*(10**feedDecimals);
       uint256 minRatio = ethPrice/tokenPrice;
        uint256 minIncrement =(minIncrementUSD/minRatio) * 10 ** decimals;

        return price + minIncrement;
   }





    function getContract(uint256 listId) public view returns (IERC721){
        return listIds[listId].nft;
    }



    function bid(uint256 listId, uint256 value) external {
        //Get current price of ETH in USD and the token Price in ETH
        uint256 price = getMinimumBid(listId);
        
        if(listIds[listId].auction) {
            
            //Minimum accepted bid is the current price + minimum increment in Ammo
            uint256 minimumAcceptedBid = price;
            require(value >= minimumAcceptedBid && block.timestamp < listIds[listId].endTime, "Insufficient bid amount or expired auction");
            require(ammo.balanceOf(msg.sender) >= minimumAcceptedBid, "Insufficient balance");

            
            listIds[listId].currentPrice = getUSDFromValue(value);  
            listIds[listId].currentWinner = msg.sender;
        }
        else {
            require(value >= price, "Please submit the asking price in order to complete the purchase");
        

        //update the details of the token
        listIds[listId].currentlyListed = false;
        //idToListedToken[tokenId].seller = msg.sender;
        itemsSold++;
        for(uint8 i = 0; i < activeList.length; i++) {
            if(activeList[i] == listId) {
                delete activeList[i];
            }
        }
        

        IERC721 nft = IERC721(getContract(listId));

        //Actually transfer the token to the new owner
        nft.transferFrom(address(this), msg.sender, getTrueTokenID(listId));
        //approve the marketplace to sell NFTs on your behalf
        //nft.approve(address(this), tokenId);

        //Transfer the proceeds from the sale to the seller of the NFT
        ammo.transferFrom(msg.sender, owner, value);
    }


    }

    function finalize(uint256 listId) external {
        (,,,uint256 price) = getPriceOfItem(listId);
        address winner = listIds[listId].currentWinner;
        

        require(block.timestamp > listIds[listId].endTime, "Auction has not ended");
        require(msg.sender == listIds[listId].currentWinner);
        require(ammo.balanceOf(msg.sender) >= price, "Insufficient balance");
        listIds[listId].currentlyListed = false;

        //idToListedToken[tokenId].seller = winner;
        itemsSold++;

        for(uint8 i = 0; i < activeList.length; i++) {
            if(activeList[i] == listId) {
                delete activeList[i];
            }
        }

        IERC721 nft = IERC721(getContract(listId));
        

        //Actually transfer the token to the new owner
        nft.transferFrom(address(this), winner, getTrueTokenID(listId));
        //approve the marketplace to sell NFTs on your behalf
        //approve(address(this), tokenId);

        ammo.transferFrom(winner, owner, price);


    }

    function resetTime(uint256 listId, uint256 _newEndTime) external {
        require(msg.sender == owner, "Not authorized to reset auction time");
        uint256 newEndTime = block.timestamp + _newEndTime;
        listIds[listId].endTime = newEndTime;

        emit TimeReset(listId, newEndTime);

    }

    function setPairAddress(address _newPair) external {
        require(msg.sender == owner, "Not authorized to trigger this function");
        pairAddress = _newPair;
    }

    function setAmmoAddress(address _newAddress) external {
        require(msg.sender == owner, "Not authorized to trigger this function");
        ammo = IERC20(_newAddress);
    }

    function changeFeedDecimals(uint256 _value) external {
        require(msg.sender == owner, "Not authorized to trigger this function");
        feedDecimals = _value;

    }

    function emergencyTokenWithdraw() external {
        require(msg.sender == owner, "Not authorized to withdraw tokens");
        uint256 balance = ammo.balanceOf(address(this));
        ammo.transfer(msg.sender, balance );
    }

    function emergencyNFTWithdraw(uint256[] calldata _listIds) external {
        require(msg.sender == owner, "Not authorized to withdraw tokens");
        IERC721 nft;
        for(uint8 i = 0; i < _listIds.length; i++) {
            nft = IERC721(getContract(_listIds[i]));
            nft.transferFrom(address(this), msg.sender, getTrueTokenID(_listIds[i]));
            listIds[_listIds[i]].currentlyListed = false;
            itemsSold++;
            for(uint8 j = 0; j < activeList.length; j++) {
            if(activeList[j] == _listIds[i]) {
                delete activeList[j];
            }
        }
            


        }
    }

    //This is to remove the native currency of the network (e.g. ETH, BNB, MATIC, etc.)
    function emergencyWithdraw() public {
        require(msg.sender == owner, "Not authorized to withdraw tokens");
        // This will payout the owner the contract balance.
        // Do not remove this otherwise you will not be able to withdraw the funds.
        // =============================================================================
        (bool os, ) = payable(owner).call{value: address(this).balance}("");
        require(os);
        // =============================================================================
    }

     receive() external payable {}
    




    
            


    

    
}