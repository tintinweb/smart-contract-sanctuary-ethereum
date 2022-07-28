//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ITuttiiTokenContract.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

struct Listing {
    address seller;
    uint price;
    uint amount;
    uint expiresAt;
}

struct Offer {
    address buyer;
    uint price;
    uint amount;
    uint expiresAt;
}

// TODO Add comments
contract TuttiiMarketplace is Ownable {
    event ListingCreated(
        address indexed tokenAddress,
        uint indexed tokenId,
        address seller,
        uint price,
        uint amount,
        uint expiresAt
    );
    event ListingCanceled(
        address indexed tokenAddress,
        uint indexed tokenId,
        address seller
    );
    event ListingAccepted(
        address indexed tokenAddress,
        uint indexed tokenId,
        address seller,
        uint price,
        uint amount,
        address buyer
    );

    event OfferCreated(
        address indexed tokenAddress,
        uint indexed tokenId,
        uint price,
        uint amount,
        uint expiresAt,
        address buyer
    );
    event OfferCanceled(
        address indexed tokenAddress,
        uint indexed tokenId,
        address buyer
    );
    event OfferAccepted(
        address indexed tokenAddress,
        uint indexed tokenId,
        uint price,
        uint amount,
        address buyer
    );

    mapping(address => mapping(uint256 => Listing[])) public listings;
    mapping(address => mapping(uint256 => Offer[])) public offers;

    AggregatorV3Interface internal priceFeed;
    IERC20 currency;

    constructor(address _currency, address _agregatorV3Interface) {
        currency = IERC20(_currency);
        priceFeed = AggregatorV3Interface(_agregatorV3Interface);
    }

    function listingsCount(address tokenAddress, uint tokenId) external view returns (uint) {
        return listings[tokenAddress][tokenId].length;
    }

    function offersCount(address tokenAddress, uint tokenId) external view returns (uint) {
        return offers[tokenAddress][tokenId].length;
    }

    function readListings(address[] memory tokenAddress, uint[] memory tokenIds) external view returns (Listing[][][] memory _listings) {
        _listings = new Listing[][][](tokenAddress.length);

        for (uint i = 0; i < tokenAddress.length; i++) {
            _listings[i] = new Listing[][](tokenIds.length); 
            for (uint j = 0; j < tokenIds.length; j++) {
                _listings[i][j] = listings[tokenAddress[i]][tokenIds[j]];
            } 
        }
    }

    function readOffers(address[] memory tokenAddress, uint[] memory tokenIds) external view returns (Offer[][][] memory _offers) {
        _offers = new Offer[][][](tokenAddress.length);

        for (uint i = 0; i < tokenAddress.length; i++) { 
            _offers[i] = new Offer[][](tokenIds.length); 
            for (uint j = 0; j < tokenIds.length; j++) {
                _offers[i][j] = offers[tokenAddress[i]][tokenIds[j]];
            } 
        }
    }

    function createListing(
        address tokenAddress,
        uint tokenId,
        uint price,
        uint amount,
        uint expiresAt
    ) external {
        ITuttiiTokenContract tokenContract = ITuttiiTokenContract(tokenAddress);
        require(
            tokenContract.balanceOf(msg.sender, tokenId) >= amount,
            "Not an owner of enough tokens"
        );
        require(price > 10000, "Price is too low");
        require(expiresAt > block.timestamp, "Expiration date is not in future");

        Listing memory newListing = Listing({
            seller: msg.sender,
            price: price,
            amount: amount,
            expiresAt: expiresAt
        });

        bool replacedExisting;
        for (uint i = 0; i < listings[tokenAddress][tokenId].length; i++) {
            if (listings[tokenAddress][tokenId][i].seller == msg.sender) {
                listings[tokenAddress][tokenId][i] = newListing;
                replacedExisting = true;
            }
        }
        if (!replacedExisting) {
            listings[tokenAddress][tokenId].push(newListing);
        }

        emit ListingCreated({
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            amount: amount,
            expiresAt: expiresAt
        });
    }

    function cancelListing(address tokenAddress, uint tokenId) external {
        bool anyCanceled;
        for (uint i = 0; i < listings[tokenAddress][tokenId].length; i++) {
            if (listings[tokenAddress][tokenId][i].seller == msg.sender) {
                listings[tokenAddress][tokenId][i] = listings[tokenAddress][
                    tokenId
                ][listings[tokenAddress][tokenId].length - 1];
                listings[tokenAddress][tokenId].pop();
                anyCanceled = true;
            }
        }
        if (anyCanceled) {
            emit ListingCanceled({
                tokenAddress: tokenAddress,
                tokenId: tokenId,
                seller: msg.sender
            });
        }
    }

    function buyListing(
        address tokenAddress,
        uint tokenId,
        address seller,
        uint amount
    ) external payable {
        ITuttiiTokenContract tokenContract = ITuttiiTokenContract(tokenAddress);

        uint listingIndex = listings[tokenAddress][tokenId].length;
        for (uint i = 0; i < listings[tokenAddress][tokenId].length; i++) {
            if (listings[tokenAddress][tokenId][i].seller == seller) {
                listingIndex = i;
                break;
            }
        }
        require(listingIndex < listings[tokenAddress][tokenId].length, "Listing does not exists");
                   
        Listing storage listing = listings[tokenAddress][tokenId][listingIndex];

        require(listing.expiresAt >= block.timestamp, "Listing is expired");
        require(listing.seller != msg.sender, "Can't buy your own listing");
        require(listing.amount >= amount, "Requested amount is larger than in a listing");
        require(
            tokenContract.balanceOf(listing.seller, tokenId) >= amount,
            "Seller doesn't have enough tokens"
        );
        
        uint salePriceInWETH = convertToWETH(listing.price * amount);
        require(
            currency.allowance(msg.sender, address(this)) >=
            salePriceInWETH &&
                currency.balanceOf(msg.sender) >=
                salePriceInWETH,
            "Don't have enough money"
        );

        transferRoyalties(tokenContract, tokenId, msg.sender, listing.seller, salePriceInWETH);

        emit ListingAccepted({
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            price: listing.price,
            amount: amount,
            seller: seller,
            buyer: msg.sender
        });

        tokenContract.safeTransferFrom(
            listing.seller,
            msg.sender,
            tokenId,
            amount,
            ""
        );

        // calculate new amount
        uint newAmount = listing.amount - amount;
        uint sellerBalance = tokenContract.balanceOf(listing.seller, tokenId); 
        if (newAmount > sellerBalance) {
            newAmount = sellerBalance;
        }
        // delete if amount is 0
        if (newAmount == 0) {
            listings[tokenAddress][tokenId][listingIndex] = listings[tokenAddress][tokenId][listings[tokenAddress][tokenId].length - 1];
            listings[tokenAddress][tokenId].pop();
        } else {
            listing.amount = newAmount;
        }
    }

    function createOffer(
        address tokenAddress,
        uint tokenId,
        uint price,
        uint amount,
        uint expiresAt
    ) external {
        uint fullPrice = price * amount;
        require(
            currency.allowance(msg.sender, address(this)) >= fullPrice &&
                currency.balanceOf(msg.sender) >= fullPrice,
            "Don't have enough money"
        );
        require(price > 10000, "Price is too low");

        ITuttiiTokenContract tokenContract = ITuttiiTokenContract(tokenAddress);
        require(tokenContract.totalSupply(tokenId) >= amount, "Amount is greater than token total supply");
        require(expiresAt > block.timestamp, "Expiration date is not in future");

        Offer memory newOffer = Offer({
            buyer: msg.sender,
            price: price,
            amount: amount,
            expiresAt: expiresAt
        });

        bool replacedExisting;
        for (uint i = 0; i < offers[tokenAddress][tokenId].length; i++) {
            if (offers[tokenAddress][tokenId][i].buyer == msg.sender) {
                offers[tokenAddress][tokenId][i] = newOffer;
                replacedExisting = true;
            }
        }
        if (!replacedExisting) {
            offers[tokenAddress][tokenId].push(newOffer);
        }

        emit OfferCreated({
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            price: price,
            amount: amount,
            expiresAt: expiresAt,
            buyer: msg.sender
        });
    }

    function cancelOffer(address tokenAddress, uint tokenId) external {
        uint offersLength = offers[tokenAddress][tokenId].length;
        for (uint i = 0; i < offersLength; i++) {
            if (offers[tokenAddress][tokenId][i].buyer == msg.sender) {
                offers[tokenAddress][tokenId][i] = offers[tokenAddress][tokenId][offersLength - 1];
                offers[tokenAddress][tokenId].pop();
                
                emit OfferCanceled({
                    tokenAddress: tokenAddress,
                    tokenId: tokenId,
                    buyer: msg.sender
                });
                return;
            }
        }
    }

    function acceptOffer(address tokenAddress, uint tokenId, address buyer, uint amount) external {
        ITuttiiTokenContract tokenContract = ITuttiiTokenContract(tokenAddress);
        
        uint offerIndex = offers[tokenAddress][tokenId].length;
        for (uint i = 0; i < offers[tokenAddress][tokenId].length; i++) {
            if (offers[tokenAddress][tokenId][i].buyer == buyer) {
                offerIndex = i;
                break;
            }
        }
        require(offerIndex < offers[tokenAddress][tokenId].length, "Offer does not exists");
        Offer storage offer = offers[tokenAddress][tokenId][offerIndex];
        
        require(offer.expiresAt >= block.timestamp, "Offer is expired");
        require(offer.buyer != msg.sender, "Can't buy your own listing");
        require(offer.amount >= amount, "Requested amount is larger than in an offer");
        require(
            tokenContract.balanceOf(msg.sender, tokenId) >= amount,
            "You don't have enough tokens"
        );
        uint salePriceInWETH = convertToWETH(offer.price * amount);
        require(
            currency.allowance(offer.buyer, address(this)) >=
                salePriceInWETH &&
                currency.balanceOf(offer.buyer) >=
                salePriceInWETH,
            "Buyer doesn't have enough money"
        );

        transferRoyalties(tokenContract, tokenId, buyer, msg.sender, salePriceInWETH);

        emit OfferAccepted({
            tokenAddress: tokenAddress,
            tokenId: tokenId,
            price: offer.price,
            amount: amount,
            buyer: offer.buyer
        });

        tokenContract.safeTransferFrom(
            msg.sender,
            offer.buyer,
            tokenId,
            amount,
            ""
        );

        // update offer
        uint newAmount = offer.amount - amount;
        // delete if amount is 0
        if (newAmount == 0) {
            offers[tokenAddress][tokenId][offerIndex] = offers[tokenAddress][tokenId][offers[tokenAddress][tokenId].length - 1];
            offers[tokenAddress][tokenId].pop();
        } else {
            offers[tokenAddress][tokenId][offerIndex].amount = newAmount;
        }

        // update listing if any
        uint listingLength = listings[tokenAddress][tokenId].length;
        uint sellerBalance = tokenContract.balanceOf(msg.sender, tokenId); 
        for (uint i = 0; i < listingLength; i++) {
            if (listings[tokenAddress][tokenId][i].seller == msg.sender) {
                // found listing, need to calc new amount
                if(sellerBalance == 0) {
                    listings[tokenAddress][tokenId][i] = listings[tokenAddress][tokenId][listingLength - 1];
                    listings[tokenAddress][tokenId].pop();
                } else if (sellerBalance < listings[tokenAddress][tokenId][i].amount) {
                    listings[tokenAddress][tokenId][i].amount = sellerBalance;
                }
                return;
            }
        }
    }

    function transferRoyalties(ITuttiiTokenContract tokenContract, uint tokenId, address buyer, address seller, uint salePrice) private {
        (uint[] memory fees, address[] memory beneficiaries) = tokenContract
            .royaltyInfo(
                seller,
                tokenId,
                salePrice
            );

        for (uint j = 0; j < fees.length; j++) {
            bool transferResult = currency.transferFrom(
                buyer,
                beneficiaries[j],
                fees[j]
            );
            require(transferResult, "Failed to transfer funds");
        }
    }

    function getLatestRate() public view returns (uint) {
        (
            /*uint80 roundID*/,
            int price,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = priceFeed.latestRoundData();
        return uint(price);
    }

    function convertToWETH(uint usdAmount) public view returns (uint wethAmount) {
        uint wethRate = getLatestRate(); // price of WETH in USD with 8 decimals
        // weth amount = usd amount 
        wethAmount = usdAmount * (10 ** 26) / wethRate;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";

interface ITuttiiTokenContract is IERC1155 {
    function royaltyInfo(
        address seller,
        uint tokenId,
        uint salePrice
    )
        external
        view
        returns (uint[] memory fees, address[] memory beneficiaries);

    function totalSupply(uint tokenId) external view returns (uint);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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
pragma solidity ^0.8.0;

interface AggregatorV3Interface {
  function decimals() external view returns (uint8);

  function description() external view returns (string memory);

  function version() external view returns (uint256);

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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