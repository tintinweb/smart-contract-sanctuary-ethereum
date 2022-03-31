/**
 *Submitted for verification at Etherscan.io on 2022-03-30
*/

// File: TuskMarket_flat.sol


// File: @openzeppelin/contracts/token/ERC20/IERC20.sol


// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

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
     * by making the `nonReentrant` function external, and making it call a
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

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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
}

// File: @openzeppelin/contracts/utils/Counters.sol


// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// File: @openzeppelin/contracts/utils/Context.sol


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

// File: @openzeppelin/contracts/access/Ownable.sol


// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;


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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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

// File: contracts/elontusks/TuskMarket.sol

//SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

/**
 * @title Elon Tusk Market
 * @author Decentralized Devs - Angelo
 */






contract TUSKMARKET is ReentrancyGuard,Ownable{
	
    event Purchased(bool  indexed _isNft, uint256 indexed _saleIf, address indexed _buyer);
   
     using Counters for Counters.Counter;

     struct SaleNft {
           //NFT Contract 
           address nftcontract;
           //ID of the NFT
           uint256 nftID;
           //NFT price 
           uint256 price;
           //Sold Status 
           bool sold;
           //state
           bool active;
           //Purchased By
           address purchasedBy;

         }

    struct EcommerceSale {
        //Ecommerce price
        uint256 price;
        //Qty
        uint256 qty;
        //Items Sold
        uint256 sold; 
         //state
        bool active;

        address[] buyers; 
    }
    bool marketOpen = true;
    address erc20TransferAddress = 0x8d9B3C0Ce66932FBfBc04A324165f5bBBA1D6395;
    mapping(uint256 => SaleNft) public nfts; 
    mapping(uint256 => EcommerceSale) public ecommerceItems;
    mapping(address => bool) public allowedTokens;

    //Counters 
    Counters.Counter public _nftCounter;
    Counters.Counter public _ecomCounter;

    constructor(address _tuskToken) ReentrancyGuard() {
        allowedTokens[_tuskToken] = true;
    }

    function setMarketState(bool _state) public onlyOwner{
        marketOpen = _state;
    }


    //buyers
    function buyNft(
        //currency
        address _currency,
        uint256 _saleID
    ) public nonReentrant {
        //check if market is open
         require(marketOpen, "Market is not open");
         //check counter 
         require(_saleID >= 0 && _saleID <= _nftCounter.current(), "Invalid Sale Id");
         require(allowedTokens[_currency], "Invalid Currency");
         SaleNft storage nft = nfts[_saleID];
         require(nft.active, "NFT is not ready to be sold");
         require(!nft.sold, "NFT Already sold");
         uint256 balance = IERC20(_currency).balanceOf(msg.sender);
         //check balance 
         require(balance >= nft.price, "Not enough Currency");
         //transfer Erc20 
          IERC20(_currency).transferFrom(msg.sender, address(erc20TransferAddress), nft.price);
        //transfer NFT 
             IERC721(nft.nftcontract).transferFrom(
            address(this),
            msg.sender,
            nft.nftID
        );

        nft.sold = true;
        nft.purchasedBy = msg.sender;

        emit Purchased(true,_saleID , msg.sender);
    }


    function buyEcommerce(
        //currency
        address _currency,
        uint256 _saleID
    ) public nonReentrant {
        //check if market is open
         require(marketOpen, "Market is not open");
         //check counter 
         require(_saleID >= 0 && _saleID <= _ecomCounter.current(), "Invalid Sale Id");
         require(allowedTokens[_currency], "Invalid Currency");
        EcommerceSale storage ecomSale = ecommerceItems[_saleID];

        require(ecomSale.active, "Ecommerce Item is not ready to be sold");
         require(ecomSale.sold < ecomSale.qty, "No stocks");
         uint256 balance = IERC20(_currency).balanceOf(msg.sender);

         //check balance 
         require(balance >= ecomSale.price, "Not enough Currency");
         //transfer Erc20 
         IERC20(_currency).transferFrom(msg.sender, address(erc20TransferAddress), ecomSale.price);
         ecomSale.sold =  ecomSale.sold + 1;
         ecomSale.buyers.push(msg.sender);
         emit Purchased(false, _saleID , msg.sender);
    }

    function getEcomSaleBuyers(uint256 _saleId) public view returns(address[] memory){
        require(_saleId >= 0 && _saleId <= _ecomCounter.current(), "Invalid Sale Id");
         EcommerceSale storage ecomSale = ecommerceItems[_saleId];
         return ecomSale.buyers;
    }



    //Admin stuff

    function setErc20TransferAddress(address _ta) public onlyOwner{
        erc20TransferAddress = _ta;
    }

    function setCurrencyToken(address _cAddress, bool _state) public onlyOwner{
        allowedTokens[_cAddress] = _state;
    }

    //list NFTs
    function listNft(
        address _contractAddress,
        uint256 _nftId, 
        uint256 _price
    ) public onlyOwner {
        //transfer the NFT to this contract 
        //Transfer NFT to Openlottery 
         IERC721(_contractAddress).transferFrom(
            msg.sender,
            address(this),
            _nftId
        );

        //create a listing
         SaleNft storage saleNft = nfts[_nftCounter.current()];
         saleNft.price = _price;
         saleNft.nftID = _nftId;
         saleNft.active = true;
         saleNft.nftcontract = _contractAddress;
        //increment Counter
         _nftCounter.increment();
    }

    //list Ecom Item
    function listEcom(
        uint256 _price,
        uint256 _qty
    ) public onlyOwner {
        EcommerceSale storage ecomSale = ecommerceItems[_ecomCounter.current()];
        ecomSale.price = _price;
        ecomSale.qty = _qty;
        ecomSale.active = true;
        _ecomCounter.increment();
    }

    function setState(bool _ifNft, uint256 _counterId, bool _state) public onlyOwner {
            if(_ifNft){
                 SaleNft storage saleNft = nfts[_counterId];
                 saleNft.active = _state;
            }else{
                 EcommerceSale storage ecomSale = ecommerceItems[_counterId];
                 ecomSale.active = _state;
            }
    }

     function setPrice(bool _ifNft, uint256 _counterId, uint256 _price) public onlyOwner {
            if(_ifNft){
                 SaleNft storage saleNft = nfts[_counterId];
                 saleNft.price = _price;
            }else{
                 EcommerceSale storage ecomSale = ecommerceItems[_counterId];
                 ecomSale.price = _price;
            }
    }


     function changeEommQty( uint256 _counterId, uint256 _qty) public onlyOwner {
            EcommerceSale storage ecomSale = ecommerceItems[_counterId];
            ecomSale.qty = _qty;
        }

    function getNftDetails(uint256 _id) public view  returns(SaleNft memory) {
           SaleNft storage saleNft = nfts[_id];
           return saleNft;
    }

    function overideTransfer(address _contract, address _to, uint256 _nftId) public onlyOwner {
         IERC721(_contract).transferFrom(
            address(this),
            _to,
            _nftId
        );
    }

     function getEcomDetails(uint256 _id) public view  returns(EcommerceSale memory) {
           EcommerceSale storage ecomSale = ecommerceItems[_id];
           return ecomSale;
    }
     
}