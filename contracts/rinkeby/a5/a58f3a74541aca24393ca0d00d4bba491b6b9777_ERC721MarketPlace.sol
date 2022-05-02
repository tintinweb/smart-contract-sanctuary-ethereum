/**
 *Submitted for verification at Etherscan.io on 2022-05-02
*/

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol



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

// File: @openzeppelin/contracts/interfaces/IERC2981.sol


// OpenZeppelin Contracts (last updated v4.6.0) (interfaces/IERC2981.sol)

pragma solidity ^0.8.0;


/**
 * @dev Interface for the NFT Royalty Standard.
 *
 * A standardized way to retrieve royalty payment information for non-fungible tokens (NFTs) to enable universal
 * support for royalty payments across all NFT marketplaces and ecosystem participants.
 *
 * _Available since v4.5._
 */
interface IERC2981 is IERC165 {
    /**
     * @dev Returns how much royalty is owed and to whom, based on a sale price that may be denominated in any unit of
     * exchange. The royalty amount is denominated and should be paid in that same unit of exchange.
     */
    function royaltyInfo(uint256 tokenId, uint256 salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol



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

// File: contracts/IERC721Mintable.sol


pragma solidity ^0.8.13;


interface IERC721Mintable is IERC721, IERC2981 {
    function mintingCharge() external view returns(uint);
    
    function royalities(uint256 _tokenId) external view returns (uint256);

    function creators(uint256 _tokenId) external view returns (address payable);

}
// File: contracts/utils/AddressArray.sol

// library for address array 
library AddressArray {
    using AddressArray for addresses;

    struct addresses {
        address[] array;
    }

    function add(addresses storage self, address _address)
        external
    {
        if(! exists(self, _address)){
            self.array.push(_address);
        }
    }

    function getIndexByAddress(
        addresses storage self,
        address _address
    ) internal view returns (uint, bool) {
        uint index;
        bool exists_;

        for (uint i = 0; i < self.array.length; i++) {
            if (self.array[i] == _address) {
                index = i;
                exists_ = true;

                break;
            }
        }
        return (index, exists_);
    }

    function remove(
        addresses storage self,
        address _address
    ) internal {
       for (uint i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _address 
            ) {
                delete self.array[i];
            }
        }
    }


    function exists(
        addresses storage self,
        address _address
    ) internal view returns (bool) {
        for (uint i = 0; i < self.array.length; i++) {
            if (
                self.array[i] == _address 
            ) {
                return true;
            }
        }
        return false;
    }
}
// File: contracts/utils/TokenDetArray.sol


pragma solidity ^0.8.13;

// librray for TokenDets
library TokenDetArray {
    // Using for array of strcutres for storing mintable address and token id
    using TokenDetArray for TokenDets;

    struct TokenDet {
        address NFTAddress;
        uint256 tokenID;
    }

    // custom type array TokenDets
    struct TokenDets {
        TokenDet[] array;
    }

    function add(TokenDets storage self, TokenDet memory _tokenDet) public {
        if (!self.exists(_tokenDet)) {
            self.array.push(_tokenDet);
        }
    }

    function getIndexByTokenDet(
        TokenDets storage self,
        TokenDet memory _tokenDet
    ) internal view returns (uint256, bool) {
        uint256 index;
        bool tokenExists = false;
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _tokenDet.NFTAddress &&
                self.array[i].tokenID == _tokenDet.tokenID
            ) {
                index = i;
                tokenExists = true;
                break;
            }
        }
        return (index, tokenExists);
    }

    function remove(TokenDets storage self, TokenDet memory _tokenDet)
        internal
        returns (bool)
    {
        (uint256 i, bool tokenExists) = self.getIndexByTokenDet(_tokenDet);
        if (tokenExists == true) {
            self.array[i] = self.array[self.array.length - 1];
            self.array.pop();
            return true;
        }
        return false;
    }

    function exists(TokenDets storage self, TokenDet memory _tokenDet)
        internal
        view
        returns (bool)
    {
        for (uint256 i = 0; i < self.array.length; i++) {
            if (
                self.array[i].NFTAddress == _tokenDet.NFTAddress &&
                self.array[i].tokenID == _tokenDet.tokenID
            ) {
                return true;
            }
        }
        return false;
    }
}
// File: @openzeppelin/contracts/utils/Context.sol



pragma solidity ^0.8.0;

/*
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

// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol



pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol


// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;


/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// File: contracts/ERC721Marketplace.sol


pragma solidity ^0.8.13;







contract ERC721MarketPlace is ERC721Holder, Ownable {
    // Storage

    using TokenDetArray for TokenDetArray.TokenDets;
    using AddressArray for AddressArray.addresses;

    mapping(address => uint256) public brokerage;
    mapping(address => mapping(uint256 => bool)) tokenOpenForSale;
    mapping(address => TokenDetArray.TokenDets) tokensForSalePerUser;
    TokenDetArray.TokenDets fixedPriceTokens;
    TokenDetArray.TokenDets auctionTokens;

    //auction type :
    // 1 : only direct buy
    // 2 : only bid
    // 3 : both buy and bid

    struct auction {
        address payable lastOwner;
        uint256 currentBid;
        address payable highestBidder;
        uint256 auctionType;
        uint256 startingPrice;
        uint256 buyPrice;
        bool buyer;
        uint256 startingTime;
        uint256 closingTime;
        address erc20Token;
    }

    mapping(address => mapping(uint256 => auction)) public auctions;

    TokenDetArray.TokenDets tokensForSale;
    AddressArray.addresses erc20TokensArray;

    mapping(address => uint256) brokerageBalance;

    // Events

    event Bid(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address bidder,
        uint256 amouont,
        uint256 time,
        address ERC20Address
    );
    event Buy(
        address indexed collection,
        uint256 tokenId,
        address indexed seller,
        address indexed buyer,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event Collect(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        address buyer,
        address collector,
        uint256 time,
        address ERC20Address
    );
    event OnSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event PriceUpdated(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 auctionType,
        uint256 oldAmount,
        uint256 amount,
        uint256 time,
        address ERC20Address
    );
    event OffSale(
        address indexed collection,
        uint256 indexed tokenId,
        address indexed seller,
        uint256 time,
        address ERC20Address
    );

    // Modifiers

    modifier erc20Allowed(address _erc20Token) {
        if (_erc20Token != address(0)) {
            require(erc20TokensArray.exists(_erc20Token), "ERC20 not allowed");
        }
        _;
    }

    modifier onSaleOnly(uint256 tokenID, address _mintableToken) {
        require(
            tokenOpenForSale[_mintableToken][tokenID] == true,
            "Token Not For Sale"
        );
        _;
    }

    modifier activeAuction(uint256 tokenID, address _mintableToken) {
        require(
            block.timestamp < auctions[_mintableToken][tokenID].closingTime,
            "Auction Time Over!"
        );
        _;
    }

    modifier auctionOnly(uint256 tokenID, address _mintableToken) {
        require(
            auctions[_mintableToken][tokenID].auctionType != 1,
            "Auction Not For Bid"
        );
        _;
    }

    modifier flatSaleOnly(uint256 tokenID, address _mintableToken) {
        require(
            auctions[_mintableToken][tokenID].auctionType != 2,
            "Auction for Bid only!"
        );
        _;
    }

    modifier tokenOwnerOnlly(uint256 tokenID, address _mintableToken) {
        // Sender will be owner only if no have bidded on auction.
        require(
            IERC721Mintable(_mintableToken).ownerOf(tokenID) == msg.sender,
            "You must be owner and Token should not have any bid"
        );
        _;
    }

    // Getters

    function getErc20Tokens() public view returns (address[] memory) {
        return erc20TokensArray.array;
    }

    function getTokensForSale()
        public
        view
        returns (TokenDetArray.TokenDet[] memory)
    {
        return tokensForSale.array;
    }

    function getFixedPriceTokensForSale()
        public
        view
        returns (TokenDetArray.TokenDet[] memory)
    {
        return fixedPriceTokens.array;
    }

    function getAuctionTokensForSale()
        public
        view
        returns (TokenDetArray.TokenDet[] memory)
    {
        return auctionTokens.array;
    }

    function getTokensForSalePerUser(address _user)
        public
        view
        returns (TokenDetArray.TokenDet[] memory)
    {
        return tokensForSalePerUser[_user].array;
    }

    function addERC20TokenPayment(address _erc20Token, uint256 _brokerage)
        public
        onlyOwner
    {
        erc20TokensArray.add(_erc20Token);
        brokerage[_erc20Token] = _brokerage;
    }

    function updateBrokerage(address _erc20Token, uint256 _brokerage)
        public
        onlyOwner
    {
        brokerage[_erc20Token] = _brokerage;
    }

    constructor(uint256 _brokerage) {
        brokerage[address(0)] = _brokerage;
        transferOwnership(msg.sender);
    }

    function removeERC20TokenPayment(address _erc20Token)
        public
        erc20Allowed(_erc20Token)
        onlyOwner
    {
        erc20TokensArray.remove(_erc20Token);
    }

    function bid(
        uint256 tokenID,
        address _mintableToken,
        uint256 amount
    )
        public
        payable
        onSaleOnly(tokenID, _mintableToken)
        activeAuction(tokenID, _mintableToken)
    {
        IERC721Mintable Token = IERC721Mintable(_mintableToken);

        auction memory _auction = auctions[_mintableToken][tokenID];

        if (_auction.erc20Token == address(0)) {
            require(
                msg.value > _auction.currentBid,
                "Insufficient bidding amount."
            );

            if (_auction.buyer == true) {
                _auction.highestBidder.transfer(_auction.currentBid);
            }
        } else {
            IERC20 erc20Token = IERC20(_auction.erc20Token);
            require(
                erc20Token.allowance(msg.sender, address(this)) >= amount,
                "Allowance is less than amount sent for bidding."
            );
            require(
                amount > _auction.currentBid,
                "Insufficient bidding amount."
            );
            erc20Token.transferFrom(msg.sender, address(this), amount);

            if (_auction.buyer == true) {
                erc20Token.transfer(
                    _auction.highestBidder,
                    _auction.currentBid
                );
            }
        }

        _auction.currentBid = _auction.erc20Token == address(0)
            ? msg.value
            : amount;

        Token.safeTransferFrom(Token.ownerOf(tokenID), address(this), tokenID);
        _auction.buyer = true;
        _auction.highestBidder = payable(msg.sender);

        auctions[_mintableToken][tokenID] = _auction;

        // Bid event
        emit Bid(
            _mintableToken,
            tokenID,
            _auction.lastOwner,
            _auction.highestBidder,
            _auction.currentBid,
            block.timestamp,
            _auction.erc20Token
        );
    }

    function _getCreatorAndRoyalty(
        TokenDetArray.TokenDet memory tokenDet,
        uint256 amount
    ) private view returns (address payable, uint256) {
        address creator;
        uint256 royalty;

        IERC721Mintable collection = IERC721Mintable(tokenDet.NFTAddress);

        try collection.royaltyInfo(tokenDet.tokenID, amount) returns (
            address receiver,
            uint256 royaltyAmount
        ) {
            creator = receiver;
            royalty = royaltyAmount;
        } catch {
            //  =
            try collection.royalities(tokenDet.tokenID) returns (
                uint256 royalities
            ) {
                try collection.creators(tokenDet.tokenID) returns (
                    address payable receiver
                ) {
                    creator = receiver;
                    royalty = (royalities * amount) / 10000;
                } catch {}
            } catch {}
        }
        return (payable(creator), royalty);
    }

    // Collect Function are use to collect funds and NFT from Broker
    function collect(uint256 tokenID, address _mintableToken) public {
        IERC721Mintable Token = IERC721Mintable(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        TokenDetArray.TokenDet memory _tokenDet = TokenDetArray.TokenDet(
            _mintableToken,
            tokenID
        );

        require(block.timestamp > _auction.closingTime, "Auction Not Over!");

        address payable lastOwner2 = _auction.lastOwner;
        // uint256 royalities = Token.royalities(tokenID);
        // address payable creator = Token.creators(tokenID);

        // uint256 royalty = (royalities * _auction.currentBid) / 10000;
        (address payable creator, uint royalty) = _getCreatorAndRoyalty(_tokenDet, _auction.currentBid);
        uint256 brokerageAmount = (brokerage[_auction.erc20Token] *
            _auction.currentBid) / 10000;

        uint256 lastOwner_funds = _auction.currentBid -
            royalty -
            brokerageAmount;

        if (_auction.buyer == true) {
            if (_auction.erc20Token == address(0)) {
                creator.transfer(royalty);
                lastOwner2.transfer(lastOwner_funds);
            } else {
                IERC20 erc20Token = IERC20(_auction.erc20Token);
                // transfer royalitiy to creator
                erc20Token.transfer(creator, royalty);
                erc20Token.transfer(lastOwner2, lastOwner_funds);
            }
            brokerageBalance[_auction.erc20Token] += brokerageAmount;
            tokenOpenForSale[_mintableToken][tokenID] = false;
            Token.safeTransferFrom(
                Token.ownerOf(tokenID),
                _auction.highestBidder,
                tokenID
            );

            // Buy event
            emit Buy(
                _tokenDet.NFTAddress,
                _tokenDet.tokenID,
                lastOwner2,
                _auction.highestBidder,
                _auction.currentBid,
                block.timestamp,
                _auction.erc20Token
            );
        }

        // Collect event
        emit Collect(
            _tokenDet.NFTAddress,
            _tokenDet.tokenID,
            lastOwner2,
            _auction.highestBidder,
            msg.sender,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.remove(_tokenDet);

        tokensForSalePerUser[lastOwner2].remove(_tokenDet);
        auctionTokens.remove(_tokenDet);
        delete auctions[_mintableToken][tokenID];
    }

    function buy(uint256 tokenID, address _mintableToken)
        public
        payable
        onSaleOnly(tokenID, _mintableToken)
        flatSaleOnly(tokenID, _mintableToken)
    {
        IERC721Mintable Token = IERC721Mintable(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        TokenDetArray.TokenDet memory _tokenDet = TokenDetArray.TokenDet(
            _mintableToken,
            tokenID
        );

        address payable lastOwner2 = _auction.lastOwner;
        // uint256 royalities = Token.royalities(tokenID);
        // address payable creator = Token.creators(tokenID);
        // uint256 royalty = (royalities * _auction.buyPrice) / 10000;
        (address payable creator, uint royalty) = _getCreatorAndRoyalty(_tokenDet, _auction.currentBid);

        uint256 brokerageAmount = (brokerage[_auction.erc20Token] *
            _auction.buyPrice) / 10000;

        uint256 lastOwner_funds = _auction.buyPrice -
            royalty -
            brokerageAmount;

        if (_auction.erc20Token == address(0)) {
            require(msg.value >= _auction.buyPrice, "Insufficient Payment");

            creator.transfer(royalty);
            lastOwner2.transfer(lastOwner_funds);
        } else {
            IERC20 erc20Token = IERC20(_auction.erc20Token);
            require(
                erc20Token.allowance(msg.sender, address(this)) >=
                    _auction.buyPrice,
                "Insufficient spent allowance "
            );
            // transfer royalitiy to creator
            erc20Token.transferFrom(msg.sender, creator, royalty);
            // transfer brokerage amount to broker
            erc20Token.transferFrom(msg.sender, address(this), brokerageAmount);
            // transfer remaining  amount to lastOwner
            erc20Token.transferFrom(msg.sender, lastOwner2, lastOwner_funds);
        }
        brokerageBalance[_auction.erc20Token] += brokerageAmount;

        tokenOpenForSale[_tokenDet.NFTAddress][_tokenDet.tokenID] = false;
        // _auction.buyer = true;
        // _auction.highestBidder = msg.sender;
        // _auction.currentBid = _auction.buyPrice;

        Token.safeTransferFrom(
            Token.ownerOf(_tokenDet.tokenID),
            // _auction.highestBidder,/
            msg.sender,
            _tokenDet.tokenID
        );

        // Buy event
        emit Buy(
            _tokenDet.NFTAddress,
            _tokenDet.tokenID,
            lastOwner2,
            msg.sender,
            _auction.buyPrice,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.remove(_tokenDet);
        tokensForSalePerUser[lastOwner2].remove(_tokenDet);

        fixedPriceTokens.remove(_tokenDet);
        delete auctions[_tokenDet.NFTAddress][_tokenDet.tokenID];
    }

    function withdraw() public onlyOwner {
        payable(msg.sender).transfer(brokerageBalance[address(0)]);
        brokerageBalance[address(0)] = 0;
    }

    function withdrawERC20(address _erc20Token) public onlyOwner {
        require(
            erc20TokensArray.exists(_erc20Token),
            "This erc20token payment not allowed"
        );
        IERC20 erc20Token = IERC20(_erc20Token);
        erc20Token.transfer(msg.sender, brokerageBalance[_erc20Token]);
        brokerageBalance[_erc20Token] = 0;
    }

    function putOnSale(
        uint256 _tokenID,
        uint256 _startingPrice,
        uint256 _auctionType,
        uint256 _buyPrice,
        uint256 _duration,
        address _mintableToken,
        address _erc20Token
    )
        public
        erc20Allowed(_erc20Token)
        tokenOwnerOnlly(_tokenID, _mintableToken)
    {
        IERC721Mintable Token = IERC721Mintable(_mintableToken);

        require(
            Token.getApproved(_tokenID) == address(this),
            "Broker Not approved"
        );
        auction memory _auction = auctions[_mintableToken][_tokenID];

        // Allow to put on sale to already on sale NFT \
        // only if it was on auction and have 0 bids and auction is over
        if (tokenOpenForSale[_mintableToken][_tokenID] == true) {
            require(
                _auction.auctionType == 2 &&
                    _auction.buyer == false &&
                    block.timestamp > _auction.closingTime,
                "This NFT is already on sale."
            );
        }

        auction memory newAuction = auction(
            payable(msg.sender),
            _startingPrice,
            payable(address(0)),
            _auctionType,
            _startingPrice,
            _buyPrice,
            false,
            block.timestamp,
            block.timestamp + _duration,
            _erc20Token
        );
        auctions[_mintableToken][_tokenID] = newAuction;
        TokenDetArray.TokenDet memory _tokenDet = TokenDetArray.TokenDet(
            _mintableToken,
            _tokenID
        );

        // Store data in all mappings if adding fresh token on sale
        if (
            tokenOpenForSale[_tokenDet.NFTAddress][_tokenDet.tokenID] == false
        ) {
            tokenOpenForSale[_tokenDet.NFTAddress][_tokenDet.tokenID] = true;

            tokensForSale.add(_tokenDet);
            tokensForSalePerUser[msg.sender].add(_tokenDet);

            // Add token to fixedPrice on Timed list
            if (_auctionType == 1) {
                fixedPriceTokens.add(_tokenDet);
            } else if (_auctionType == 2) {
                auctionTokens.add(_tokenDet);
            }
        }

        // OnSale event
        emit OnSale(
            _tokenDet.NFTAddress,
            _tokenDet.tokenID,
            msg.sender,
            _auctionType,
            newAuction.auctionType == 1
                ? newAuction.buyPrice
                : newAuction.startingPrice,
            block.timestamp,
            newAuction.erc20Token
        );
    }

    function updatePrice(
        uint256 tokenID,
        address _mintableToken,
        uint256 _newPrice,
        address _erc20Token
    )
        public
        onSaleOnly(tokenID, _mintableToken)
        erc20Allowed(_erc20Token)
        tokenOwnerOnlly(tokenID, _mintableToken)
    {
        // IERC721Mintable Token = IERC721Mintable(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];

        if (_auction.auctionType == 2) {
            require(
                block.timestamp < _auction.closingTime,
                "Auction Time Over!"
            );
        }
        emit PriceUpdated(
            _mintableToken,
            tokenID,
            _auction.lastOwner,
            _auction.auctionType,
            _auction.auctionType == 1
                ? _auction.buyPrice
                : _auction.startingPrice,
            _newPrice,
            block.timestamp,
            _auction.erc20Token
        );
        // Update Price
        if (_auction.auctionType == 1) {
            _auction.buyPrice = _newPrice;
        } else {
            _auction.startingPrice = _newPrice;
            _auction.currentBid = _newPrice;
        }
        _auction.erc20Token = _erc20Token;
        auctions[_mintableToken][tokenID] = _auction;
    }

    function putSaleOff(uint256 tokenID, address _mintableToken)
        public
        tokenOwnerOnlly(tokenID, _mintableToken)
    {
        // IERC721Mintable Token = IERC721Mintable(_mintableToken);
        auction memory _auction = auctions[_mintableToken][tokenID];
        TokenDetArray.TokenDet memory _tokenDet = TokenDetArray.TokenDet(
            _mintableToken,
            tokenID
        );
        tokenOpenForSale[_mintableToken][tokenID] = false;

        // OffSale event
        emit OffSale(
            _mintableToken,
            tokenID,
            msg.sender,
            block.timestamp,
            _auction.erc20Token
        );

        tokensForSale.remove(_tokenDet);

        tokensForSalePerUser[msg.sender].remove(_tokenDet);
        // Remove token from list
        if (_auction.auctionType == 1) {
            fixedPriceTokens.remove(_tokenDet);
        } else if (_auction.auctionType == 2) {
            auctionTokens.remove(_tokenDet);
        }
        delete auctions[_mintableToken][tokenID];
    }

    function getOnSaleStatus(address _mintableToken, uint256 tokenID)
        public
        view
        returns (bool)
    {
        return tokenOpenForSale[_mintableToken][tokenID];
    }
}