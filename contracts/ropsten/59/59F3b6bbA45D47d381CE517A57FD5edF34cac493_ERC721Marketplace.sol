//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721Marketplace {
  using Counters for Counters.Counter;

  enum ListingStatus {
    active,
    sold,
    cancelled
  }

  enum AuctionStatus {
    active,
    closed,
    sold,
    cancelled
  }

  struct Item {
    uint256[] listingIds;
    uint256[] auctionIds;
    uint256[] saleIds;
  }

  struct Listing {
    uint256 id;
    uint256 tokenId;
    address tokenAddress;
    address seller;
    uint256 startDate;
    uint256 endDate;
    uint256 price;
    uint256 saleId;
    ListingStatus status;
  }

  struct Auction {
    uint256 id;
    uint256 tokenId;
    address tokenAddress;
    address seller;
    uint256 startDate;
    uint256 endDate;
    uint256 startingPrice;
    address highestBidder;
    uint256 saleId;
    AuctionStatus status;
  }

  struct Sale {
    uint256 id;
    uint256 tokenId;
    address tokenAddress;
    address seller;
    address buyer;
    uint256 price;
  }

  // Events
  event ListingCreated(
    uint256 listingId,
    uint256 tokenId,
    address tokenAddress,
    address seller,
    uint256 startDate,
    uint256 endDate,
    uint256 price
  );
  event ListingSold(uint256 listingId, uint256 saleId);
  event ListingCancelled(uint256 listingId);

  event AuctionCreated(
    uint256 auctionId,
    uint256 tokenId,
    address tokenAddress,
    address seller,
    uint256 startDate,
    uint256 endDate,
    uint256 startingPrice
  );
  event AuctionClosed(uint256 auctionId);
  event AuctionSold(uint256 auctionId, address highestBidder, uint256 saleId);
  event AuctionCancelled(uint256 auctionId);
  event AuctionBid(uint256 auctionId, address bidder, uint256 bid);
  event AuctionWithdrawal(uint256 auctionId, address withdrawer);

  event NewSale(
    uint256 saleId,
    uint256 tokenId,
    address tokenAddress,
    address seller,
    address buyer,
    uint256 price
  );

  Counters.Counter private _listingIdCounter;
  Counters.Counter private _auctionIdCounter;
  Counters.Counter private _saleIdCounter;

  mapping(address => mapping(uint256 => Item)) private items;
  mapping(uint256 => Auction) private auctions;
  mapping(uint256 => mapping(address => uint256)) private auctionFunds;
  mapping(uint256 => Listing) private listings;
  mapping(uint256 => Sale) private sales;

  // Listing Methods
  function createListing(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _price,
    uint256 _startDate,
    uint256 _endDate
  ) public {
    IERC721 _token = IERC721(_tokenAddress);
    address _tokenOwner = _token.ownerOf(_tokenId);
    address _seller = msg.sender;

    // Date
    uint256 __startDate = _startDate;
    uint256 __endDate = _endDate;
    if (__startDate == 0) {
      // solhint-disable-next-line not-rely-on-time
      __startDate = block.timestamp;
    } else {
      // solhint-disable-next-line not-rely-on-time
      require(_startDate > block.timestamp, "startDate cannot be in the past");
    }
    require(_endDate > _startDate, "invalid date range");

    // Token Ownership Transfer
    require(
      _tokenOwner == address(this) || _tokenOwner == _seller,
      "must be token owner"
    );
    if (_tokenOwner == _seller) {
      _token.transferFrom(_seller, address(this), _tokenId);
    }

    // Listing Creation
    uint256 _listingId = _listingIdCounter.current();
    _listingIdCounter.increment();

    Listing memory _listing = Listing({
      id: _listingId,
      tokenId: _tokenId,
      tokenAddress: _tokenAddress,
      seller: _seller,
      price: _price,
      status: ListingStatus.active,
      startDate: __startDate,
      endDate: __endDate,
      saleId: 0
    });
    listings[_listingId] = _listing;

    // Update Item
    items[_tokenAddress][_tokenId].listingIds.push(_listingId);

    emit ListingCreated(
      _listing.id,
      _listing.tokenId,
      _listing.tokenAddress,
      _listing.seller,
      _listing.startDate,
      _listing.endDate,
      _listing.price
    );
  }

  function buyFromListing(uint256 _listingId) public payable {
    address _buyer = msg.sender;
    Listing memory _listing = listings[_listingId];

    require(_listing.status == ListingStatus.active, "listing must be active");
    require(msg.value == _listing.price, "value must equal listing price");

    // Create sale
    uint256 _saleId = _saleIdCounter.current();
    _saleIdCounter.increment();

    Sale memory _sale = Sale({
      id: _saleId,
      tokenId: _listing.tokenId,
      tokenAddress: _listing.tokenAddress,
      seller: _listing.seller,
      buyer: _buyer,
      price: _listing.price
    });
    sales[_saleId] = _sale;

    // Update Listing
    _listing.saleId = _saleId;
    _listing.status = ListingStatus.sold;
    listings[_listingId] = _listing;

    // Update item
    items[_listing.tokenAddress][_listing.tokenId].saleIds.push(_saleId);

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = payable(_listing.seller).call{value: msg.value}("");
    require(success, "Failed to send money");

    emit ListingSold(_listing.id, _listing.saleId);
    emit NewSale(
      _sale.id,
      _sale.tokenId,
      _sale.tokenAddress,
      _sale.seller,
      _sale.buyer,
      _sale.price
    );
  }

  function cancelListing(uint256 _listingId) public {
    Listing memory _listing = listings[_listingId];

    require(_listing.status == ListingStatus.active, "listing must be active");

    // Update Listing
    _listing.status = ListingStatus.cancelled;
    listings[_listingId] = _listing;

    emit ListingCancelled(_listing.id);
  }

  // Auction Methods
  function createAuction(
    address _tokenAddress,
    uint256 _tokenId,
    uint256 _startingPrice,
    uint256 _startDate,
    uint256 _endDate
  ) public {
    IERC721 _token = IERC721(_tokenAddress);
    address _tokenOwner = _token.ownerOf(_tokenId);
    address _seller = msg.sender;

    // Date
    uint256 __startDate = _startDate;
    uint256 __endDate = _endDate;
    if (__startDate == 0) {
      // solhint-disable-next-line not-rely-on-time
      __startDate = block.timestamp;
    } else {
      // solhint-disable-next-line not-rely-on-time
      require(__startDate > block.timestamp, "startDate cannot be in the past");
    }
    require(__endDate > __startDate, "invalid date range");

    // Token Ownership Transfer
    require(
      _tokenOwner == address(this) || _tokenOwner == _seller,
      "must be token owner"
    );
    if (_tokenOwner == _seller) {
      _token.transferFrom(_seller, address(this), _tokenId);
    }

    // Auction Creation
    uint256 _auctionId = _auctionIdCounter.current();
    _auctionIdCounter.increment();

    Auction memory _auction = Auction({
      id: _auctionId,
      tokenId: _tokenId,
      tokenAddress: _tokenAddress,
      seller: _seller,
      startDate: __startDate,
      endDate: __endDate,
      startingPrice: _startingPrice,
      highestBidder: address(0),
      status: AuctionStatus.active,
      saleId: 0
    });
    auctions[_auctionId] = _auction;

    // Update Item
    items[_tokenAddress][_tokenId].auctionIds.push(_auctionId);

    emit AuctionCreated(
      _auction.id,
      _auction.tokenId,
      _auction.tokenAddress,
      _auction.seller,
      _auction.startDate,
      _auction.endDate,
      _auction.startingPrice
    );
  }

  function auctionFundOf(uint256 auctionId, address bidder)
    public
    view
    returns (uint256)
  {
    return auctionFunds[auctionId][bidder];
  }

  function auctionHighestBid(uint256 auctionId) public view returns (uint256) {
    Auction memory _auction = auctions[auctionId];
    return auctionFunds[auctionId][_auction.highestBidder];
  }

  function bidAuction(uint256 auctionId) public payable {
    address _bidder = msg.sender;
    uint256 _amount = msg.value;
    Auction memory _auction = auctions[auctionId];
    uint256 _highestBid = auctionFunds[auctionId][_auction.highestBidder];

    // Validate bid
    require(
      // solhint-disable-next-line not-rely-on-time
      block.timestamp >= _auction.startDate,
      "auction hasn't started yet"
    );
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp < _auction.endDate, "auction hasn already ended");
    require(_bidder != _auction.seller, "seller cannot bid");
    uint256 _bid = auctionFunds[auctionId][_bidder] + _amount;
    require(
      _bid > _highestBid && _bid > _auction.startingPrice,
      "insuficient bid"
    );

    // Update auction
    auctionFunds[auctionId][_bidder] = _bid;
    _auction.highestBidder = _bidder;
    auctions[auctionId] = _auction;

    emit AuctionBid(_auction.id, _bidder, _bid);
  }

  function withdrawFromAuction(uint256 auctionId) public {
    address _withdrawer = msg.sender;
    Auction memory _auction = auctions[auctionId];

    // Validate withdrawal
    require(_withdrawer != _auction.seller, "seller cannot withdraw fund");
    require(
      _auction.status != AuctionStatus.active,
      "cannot withdraw fund from active auction"
    );
    if (_auction.status == AuctionStatus.sold) {
      require(
        _withdrawer != _auction.highestBidder,
        "winner cannot withdraw fund"
      );
    }

    // withdrawal
    uint256 _availableFund = auctionFunds[auctionId][_withdrawer];
    require(_availableFund > 0, "insuficient fund");
    auctionFunds[auctionId][_withdrawer] = 0;

    // update auction
    auctions[auctionId] = _auction;

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = payable(_withdrawer).call{value: _availableFund}("");
    require(success, "Failed to send money");

    emit AuctionWithdrawal(_auction.id, _withdrawer);
  }

  function closeAuction(uint256 _auctionId) public {
    Auction memory _auction = auctions[_auctionId];

    require(_auction.status == AuctionStatus.active, "auction must be active");
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp > _auction.endDate, "auction hasn't ended yet");

    if (_auction.highestBidder == address(0)) {
      // Update Auction
      _auction.status = AuctionStatus.closed;
      auctions[_auctionId] = _auction;

      emit AuctionClosed(_auctionId);
      return;
    }

    // Create sale
    uint256 _saleId = _saleIdCounter.current();
    _saleIdCounter.increment();

    uint256 _auctionFinalPrice = auctionFunds[_auctionId][
      _auction.highestBidder
    ];
    Sale memory _sale = Sale({
      id: _saleId,
      tokenId: _auction.tokenId,
      tokenAddress: _auction.tokenAddress,
      seller: _auction.seller,
      buyer: _auction.highestBidder,
      price: _auctionFinalPrice
    });
    sales[_saleId] = _sale;

    // Update Auction
    _auction.saleId = _saleId;
    _auction.status = AuctionStatus.sold;
    auctions[_auctionId] = _auction;

    // Update item
    items[_auction.tokenAddress][_auction.tokenId].saleIds.push(_saleId);

    // solhint-disable-next-line avoid-low-level-calls
    (bool success, ) = payable(_auction.seller).call{value: _auctionFinalPrice}(
      ""
    );
    require(success, "Failed to send money");

    emit AuctionSold(_auction.id, _auction.highestBidder, _auction.saleId);
    emit NewSale(
      _sale.id,
      _sale.tokenId,
      _sale.tokenAddress,
      _sale.seller,
      _sale.buyer,
      _sale.price
    );
  }

  function cancelAuction(uint256 _auctionId) public {
    Auction memory _auction = auctions[_auctionId];

    require(_auction.status == AuctionStatus.active, "auction is not active");
    // solhint-disable-next-line not-rely-on-time
    require(block.timestamp < _auction.endDate, "auction has already ended");

    _auction.status = AuctionStatus.cancelled;
    auctions[_auctionId] = _auction;

    emit AuctionCancelled(_auction.id);
  }

  // // Getters
  // function sale(uint256 saleId) public view returns (Sale memory) {
  //   return sales[saleId];
  // }

  // function auction(uint256 auctionId) public view returns (Auction memory) {
  //   return auctions[auctionId];
  // }

  // function listing(uint256 listingId) public view returns (Listing memory) {
  //   return listings[listingId];
  // }

  // function itemSales(address tokenAdress, uint256 tokenId)
  //   public
  //   view
  //   returns (Sale[] memory)
  // {
  //   uint256[] memory _saleIds = items[tokenAdress][tokenId].saleIds;
  //   Sale[] memory _sales = new Sale[](_saleIds.length);

  //   for (uint256 i = 0; i < _saleIds.length; ++i) {
  //     uint256 _saleId = _saleIds[i];
  //     _sales[i] = sales[_saleId];
  //   }

  //   return _sales;
  // }

  // function itemAuctions(address tokenAdress, uint256 tokenId)
  //   public
  //   view
  //   returns (Auction[] memory)
  // {
  //   uint256[] memory _auctionIds = items[tokenAdress][tokenId].auctionIds;
  //   Auction[] memory _auctions = new Auction[](_auctionIds.length);

  //   for (uint256 i = 0; i < _auctionIds.length; ++i) {
  //     uint256 _auctionId = _auctionIds[i];
  //     _auctions[i] = auctions[_auctionId];
  //   }

  //   return _auctions;
  // }

  // function itemListings(address tokenAdress, uint256 tokenId)
  //   public
  //   view
  //   returns (Listing[] memory)
  // {
  //   uint256[] memory _listingIds = items[tokenAdress][tokenId].listingIds;
  //   Listing[] memory _listings = new Listing[](_listingIds.length);

  //   for (uint256 i = 0; i < _listingIds.length; ++i) {
  //     uint256 _listingId = _listingIds[i];
  //     _listings[i] = listings[_listingId];
  //   }

  //   return _listings;
  // }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/ERC721.sol)

pragma solidity ^0.8.0;

import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./extensions/IERC721Metadata.sol";
import "../../utils/Address.sol";
import "../../utils/Context.sol";
import "../../utils/Strings.sol";
import "../../utils/introspection/ERC165.sol";

/**
 * @dev Implementation of https://eips.ethereum.org/EIPS/eip-721[ERC721] Non-Fungible Token Standard, including
 * the Metadata extension, but not including the Enumerable extension, which is available separately as
 * {ERC721Enumerable}.
 */
contract ERC721 is Context, ERC165, IERC721, IERC721Metadata {
    using Address for address;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;

    // Mapping from token ID to owner address
    mapping(uint256 => address) private _owners;

    // Mapping owner address to token count
    mapping(address => uint256) private _balances;

    // Mapping from token ID to approved address
    mapping(uint256 => address) private _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    /**
     * @dev Initializes the contract by setting a `name` and a `symbol` to the token collection.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(address owner) public view virtual override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _balances[owner];
    }

    /**
     * @dev See {IERC721-ownerOf}.
     */
    function ownerOf(uint256 tokenId) public view virtual override returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: owner query for nonexistent token");
        return owner;
    }

    /**
     * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString())) : "";
    }

    /**
     * @dev Base URI for computing {tokenURI}. If set, the resulting URI for each
     * token will be the concatenation of the `baseURI` and the `tokenId`. Empty
     * by default, can be overridden in child contracts.
     */
    function _baseURI() internal view virtual returns (string memory) {
        return "";
    }

    /**
     * @dev See {IERC721-approve}.
     */
    function approve(address to, uint256 tokenId) public virtual override {
        address owner = ERC721.ownerOf(tokenId);
        require(to != owner, "ERC721: approval to current owner");

        require(
            _msgSender() == owner || isApprovedForAll(owner, _msgSender()),
            "ERC721: approve caller is not owner nor approved for all"
        );

        _approve(to, tokenId);
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(uint256 tokenId) public view virtual override returns (address) {
        require(_exists(tokenId), "ERC721: approved query for nonexistent token");

        return _tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved) public virtual override {
        _setApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(address owner, address operator) public view virtual override returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    /**
     * @dev See {IERC721-transferFrom}.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        //solhint-disable-next-line max-line-length
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");

        _transfer(from, to, tokenId);
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public virtual override {
        safeTransferFrom(from, to, tokenId, "");
    }

    /**
     * @dev See {IERC721-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721: transfer caller is not owner nor approved");
        _safeTransfer(from, to, tokenId, _data);
    }

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * `_data` is additional data, it has no specified format and it is sent in call to `to`.
     *
     * This internal function is equivalent to {safeTransferFrom}, and can be used to e.g.
     * implement alternative mechanisms to perform token transfer, such as signature-based.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeTransfer(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _transfer(from, to, tokenId);
        require(_checkOnERC721Received(from, to, tokenId, _data), "ERC721: transfer to non ERC721Receiver implementer");
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     * and stop existing when they are burned (`_burn`).
     */
    function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

    /**
     * @dev Returns whether `spender` is allowed to manage `tokenId`.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function _isApprovedOrOwner(address spender, uint256 tokenId) internal view virtual returns (bool) {
        require(_exists(tokenId), "ERC721: operator query for nonexistent token");
        address owner = ERC721.ownerOf(tokenId);
        return (spender == owner || isApprovedForAll(owner, spender) || getApproved(tokenId) == spender);
    }

    /**
     * @dev Safely mints `tokenId` and transfers it to `to`.
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function _safeMint(address to, uint256 tokenId) internal virtual {
        _safeMint(to, tokenId, "");
    }

    /**
     * @dev Same as {xref-ERC721-_safeMint-address-uint256-}[`_safeMint`], with an additional `data` parameter which is
     * forwarded in {IERC721Receiver-onERC721Received} to contract recipients.
     */
    function _safeMint(
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal virtual {
        _mint(to, tokenId);
        require(
            _checkOnERC721Received(address(0), to, tokenId, _data),
            "ERC721: transfer to non ERC721Receiver implementer"
        );
    }

    /**
     * @dev Mints `tokenId` and transfers it to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {_safeMint} whenever possible
     *
     * Requirements:
     *
     * - `tokenId` must not exist.
     * - `to` cannot be the zero address.
     *
     * Emits a {Transfer} event.
     */
    function _mint(address to, uint256 tokenId) internal virtual {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");

        _beforeTokenTransfer(address(0), to, tokenId);

        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);

        _afterTokenTransfer(address(0), to, tokenId);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(uint256 tokenId) internal virtual {
        address owner = ERC721.ownerOf(tokenId);

        _beforeTokenTransfer(owner, address(0), tokenId);

        // Clear approvals
        _approve(address(0), tokenId);

        _balances[owner] -= 1;
        delete _owners[tokenId];

        emit Transfer(owner, address(0), tokenId);

        _afterTokenTransfer(owner, address(0), tokenId);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *  As opposed to {transferFrom}, this imposes no restrictions on msg.sender.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {
        require(ERC721.ownerOf(tokenId) == from, "ERC721: transfer from incorrect owner");
        require(to != address(0), "ERC721: transfer to the zero address");

        _beforeTokenTransfer(from, to, tokenId);

        // Clear approvals from the previous owner
        _approve(address(0), tokenId);

        _balances[from] -= 1;
        _balances[to] += 1;
        _owners[tokenId] = to;

        emit Transfer(from, to, tokenId);

        _afterTokenTransfer(from, to, tokenId);
    }

    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(address to, uint256 tokenId) internal virtual {
        _tokenApprovals[tokenId] = to;
        emit Approval(ERC721.ownerOf(tokenId), to, tokenId);
    }

    /**
     * @dev Approve `operator` to operate on all of `owner` tokens
     *
     * Emits a {ApprovalForAll} event.
     */
    function _setApprovalForAll(
        address owner,
        address operator,
        bool approved
    ) internal virtual {
        require(owner != operator, "ERC721: approve to caller");
        _operatorApprovals[owner][operator] = approved;
        emit ApprovalForAll(owner, operator, approved);
    }

    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) private returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver.onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert("ERC721: transfer to non ERC721Receiver implementer");
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning.
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, ``from``'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, ``from``'s `tokenId` will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly

                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
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