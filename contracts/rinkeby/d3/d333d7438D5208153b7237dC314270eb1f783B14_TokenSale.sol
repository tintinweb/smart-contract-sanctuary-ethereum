// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import './ERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract TokenSale is ERC721 {
  struct Sale {
    address seller;
    uint256 price;
    uint256 tokenId;
    uint256 saleId;
    SaleStatus status;
    SaleType saleType;
    uint256 startDate;
    uint256 endDate;
    Bid[] bids;
  }

  struct Bid {
    uint256 price;
    address bidder;
  }

  enum SaleStatus {
    Default,
    InProgress,
    Done,
    Ended
  }

  enum SaleType {
    FixedPrice,
    Auction
  }

  struct Offer {
    bool isAvailable;
    uint256 price;
    uint256 endsOn;
  }

  // Fungible token address used for the token trading
  IERC20 ft;

  // This mapping maps tokenId to sale status
  mapping(uint256 => bool) private tokenSaleStatus;

  // This mapping maps tokenId to sales for that tokenId
  mapping(uint256 => mapping(uint256 => Sale)) private sales;

  // This mapping maps tokenId to sales counts
  mapping(uint256 => uint256) private salesLength;

  // TODO - Check offer storage efficiency to see if we can use a mapping instead
  // or change it to a array of offers to save space
  mapping(address => mapping(address => mapping(uint256 => Offer))) offers;

  // This event triggers when a token is sold
  event TokenSold(address from, address to, uint256 tokenId);

  // This event triggers when a sale is created
  event SaleCreated(uint256 tokenId, uint256 saleId);

  // This event triggers when a offer made on a token
  event OfferMade(
    address from,
    address to,
    uint256 tokenId,
    uint256 offerAmount
  );

  // This event triggers when a offer is accepted
  event OfferAccepted(address from, address to, uint256 tokenId);

  // This event triggers when a offer is updated
  event OfferUpdated(address from, address to, uint256 tokenId);

  // This event triggers when a bid is placed on a auction
  event NewBid(uint256 tokenId, uint256 saleId, uint256 bidId);

  // This event triggers when a sale is updated
  event SaleUpdated(uint256 tokenId, uint256 saleId, SaleStatus status);

  constructor(
    address contractAddress,
    string memory tokenName,
    string memory tokenSymbol,
    string memory baseUri
  ) ERC721(tokenName, tokenSymbol, baseUri) {
    ft = IERC20(contractAddress);
  }

  function setFungibleToken(address contractAddress) public onlyOwner {
    ft = IERC20(contractAddress);
  }

  function getFTAddress() public view returns (address ftAddress) {
    ftAddress = address(ft);
  }

  function createFixedPriceSale(
    uint256 tokenId,
    uint256 price,
    uint256 startDate,
    uint256 endDate
  ) public {
    require(ownerOf(tokenId) == _msgSender(), 'Token unauthorized');
    require(!checkSaleProgress(tokenId), 'Token is already in sale');

    uint256 newSaleId = salesLength[tokenId];
    Sale storage newSale = sales[tokenId][newSaleId];
    newSale.seller = _msgSender();
    newSale.price = price;
    newSale.tokenId = tokenId;
    newSale.saleId = salesLength[tokenId];
    newSale.status = SaleStatus.InProgress;
    newSale.saleType = SaleType.FixedPrice;
    newSale.startDate = startDate;
    newSale.endDate = endDate;
    tokenSaleStatus[tokenId] = true;
    salesLength[tokenId]++;

    emit SaleCreated(tokenId, newSale.saleId);
  }

  function createAuctionSale(
    uint256 tokenId,
    uint256 price,
    uint256 startDate,
    uint256 endDate
  ) public {
    require(ownerOf(tokenId) == _msgSender(), 'Token unauthorized');
    require(!checkSaleProgress(tokenId), 'Token is already in sale');

    uint256 newSaleId = salesLength[tokenId];
    Sale storage newSale = sales[tokenId][newSaleId];
    newSale.seller = _msgSender();
    newSale.price = price;
    newSale.tokenId = tokenId;
    newSale.saleId = salesLength[tokenId];
    newSale.status = SaleStatus.InProgress;
    newSale.saleType = SaleType.Auction;
    newSale.startDate = startDate;
    newSale.endDate = endDate;
    tokenSaleStatus[tokenId] = true;
    salesLength[tokenId]++;

    emit SaleCreated(tokenId, newSale.saleId);
  }

  function placeBid(
    uint256 tokenId,
    uint256 saleId,
    uint256 price
  ) external {
    Sale memory sale = getSaleById(tokenId, saleId);
    require(checkSaleProgress(sale.tokenId), 'Token sale: Sale ended');
    uint256 bidsCount = sale.bids.length;
    if (bidsCount > 0) {
      Bid memory lastBid = sale.bids[bidsCount - 1];
      require(
        lastBid.price < price,
        'Token Sale: bid amount is less than last bid'
      );
    }

    Bid memory newBid = Bid({ bidder: _msgSender(), price: price });
    sales[tokenId][saleId].bids.push(newBid);
    emit NewBid(tokenId, saleId, bidsCount);
  }

  function getSaleById(uint256 tokenId, uint256 saleId)
    public
    view
    returns (Sale memory sale)
  {
    sale = sales[tokenId][saleId];
  }

  function getSalePrice(uint256 tokenId, uint256 saleId)
    public
    view
    returns (uint256 price)
  {
    Sale memory sale = getSaleById(tokenId, saleId);
    if (sale.saleType == SaleType.FixedPrice) {
      return sale.price;
    } else if (sale.saleType == SaleType.Auction) {
      uint256 bidsCount = sale.bids.length;
      require(bidsCount > 0, 'Token sale: no bids made');
      return sale.bids[bidsCount - 1].price;
    }
  }

  function buyToken(uint256 tokenId, uint256 saleId) public {
    Sale memory saleData = getSaleById(tokenId, saleId);

    require(
      ownerOf(saleData.tokenId) != _msgSender(),
      'Owner can not buy token'
    );

    if (saleData.saleType == SaleType.FixedPrice) {
      require(
        saleData.startDate <= block.timestamp,
        'Token sale: Sale is not started yet'
      );
      require(saleData.endDate > block.timestamp, 'Token sale: Sale is ended');
      require(
        saleData.status == SaleStatus.InProgress,
        'Token sale: Sale is ended'
      );
    } else if (saleData.saleType == SaleType.Auction) {
      uint256 bidsCount = saleData.bids.length;
      require(
        saleData.bids[bidsCount - 1].bidder == _msgSender(),
        'Token sale: Unauthorized action'
      );
      require(
        saleData.status == SaleStatus.InProgress,
        'Token sale: Auction is ended'
      );
      require(
        saleData.endDate < block.timestamp,
        'Token sale: Auction is in-progress'
      );
    }

    uint256 salePrice = getSalePrice(tokenId, saleId);

    ft.transferFrom(_msgSender(), saleData.seller, salePrice);
    transferFrom(saleData.seller, _msgSender(), saleData.tokenId);
    _updateSaleStatus(tokenId, saleId, SaleStatus.Done);

    emit TokenSold(saleData.seller, _msgSender(), saleData.tokenId);
  }

  function checkSaleProgress(uint256 tokenId)
    public
    view
    returns (bool status)
  {
    status = tokenSaleStatus[tokenId];
  }

  function endSale(uint256 tokenId, uint256 saleId) public {
    require(
      ownerOf(tokenId) == _msgSender(),
      'Unauthorized action: Token owner can only end sale'
    );

    _updateSaleStatus(tokenId, saleId, SaleStatus.Ended);
  }

  function _updateSaleStatus(
    uint256 tokenId,
    uint256 saleId,
    SaleStatus status
  ) internal {
    Sale storage sale = sales[tokenId][saleId];
    sale.status = status;
    tokenSaleStatus[sale.tokenId] = status == SaleStatus.InProgress;
    emit SaleUpdated(tokenId, saleId, status);
  }

  function totalSales(uint256 tokenId) public view returns (uint256 count) {
    count = salesLength[tokenId];
  }

  /**
   * This function is used to buy the token for the initial price
   * @param playID id of the play to buy
   */
  function mintAndBuy(uint256 playID) public {
    Play memory play = plays[playID];
    ft.transferFrom(_msgSender(), address(this), play.initialPrice);
    _mint(playID, _msgSender());
  }

  function getOffer(
    address maker,
    address receiver,
    uint256 tokenId
  ) public view returns (Offer memory) {
    return offers[receiver][maker][tokenId];
  }

  function makeOffer(
    uint256 tokenId,
    address receiver,
    uint256 amount,
    uint256 endsOn
  ) public {
    Offer storage offer = offers[receiver][_msgSender()][tokenId];
    require(
      receiver != _msgSender(),
      'Token sale: sender and receiver can not be same'
    );
    require(
      ownerOf(tokenId) == receiver,
      'Token sale: Receiver does not own the token'
    );
    require(amount != offer.price, 'Token sale: Same offer price as before');
    offer.price = amount;
    offer.isAvailable = true;
    offer.endsOn = endsOn;
    emit OfferMade(_msgSender(), receiver, tokenId, amount);
  }

  function acceptOffer(uint256 tokenId, address offerFrom) public {
    require(
      ownerOf(tokenId) == _msgSender(),
      'Token sale: Unauthorized action'
    );
    Offer storage offer = offers[_msgSender()][offerFrom][tokenId];
    require(
      offer.isAvailable && offer.endsOn > block.timestamp,
      'Token sale: Offer expired'
    );
    ft.transferFrom(offerFrom, _msgSender(), offer.price);
    transferFrom(_msgSender(), offerFrom, tokenId);
    offer.isAvailable = false;
    emit OfferAccepted(offerFrom, _msgSender(), tokenId);
  }

  function endOffer(
    address from,
    address to,
    uint256 tokenId
  ) public {
    require(
      _msgSender() == from || _msgSender() == to,
      'Token sale:  operation not permitted'
    );
    Offer storage offer = offers[to][from][tokenId];
    require(offer.isAvailable, 'Offer already ended/declined');
    offer.isAvailable = false;
    emit OfferUpdated(from, to, tokenId);
  }

  function _beforeTokenTransfer(
    address,
    address,
    uint256 tokenId
  ) internal override(ERC721) {
    if (checkSaleProgress(tokenId)) {
      uint256 lastSaleId = totalSales(tokenId);
      _updateSaleStatus(tokenId, lastSaleId - 1, SaleStatus.Ended);
    }
  }

  function destroy() public payable onlyOwner {
    address payable receiver = payable(address(_msgSender()));
    selfdestruct(receiver);
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/utils/cryptography/ECDSA.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/utils/Address.sol';

import './AccessControl.sol';

contract ERC721 is
  IERC721,
  IERC721Metadata,
  AccessControl,
  ERC165,
  IERC721Enumerable
{
  using Address for address;

  string public _name;
  string public _symbol;
  string public _baseUri;

  struct Token {
    uint256 playID;
    uint256 serialNumber;
  }

  struct Play {
    string url;
    uint8 tokenType;
    uint256 initialPrice;
  }

  Token[] internal tokens;
  Play[] internal plays;

  uint256 private _totalSupply = 0;
  mapping(uint256 => address) private tokenOwners;
  mapping(address => uint256) private ownershipTokenCount;
  mapping(uint256 => address) private _tokenApprovals;
  mapping(address => mapping(address => bool)) private _operatorApprovals;
  mapping(uint256 => uint256) private tokenSNCount;

  uint16[4] _tokenType = [
    60000, // common
    1000, //  rare
    10, //    epic
    3 //      Legendary
  ];

  constructor(
    string memory tokenName,
    string memory tokenSymbol,
    string memory baseUri
  ) {
    _name = tokenName;
    _symbol = tokenSymbol;
    _baseUri = baseUri;
  }

  event PlayCreated(uint256 playID, string url, uint256 tokenType);

  event TokenCreated(uint256 playID, uint256 tokenId, uint256 serialNumber);

  function name() public view override returns (string memory) {
    return _name;
  }

  function symbol() public view override returns (string memory) {
    return _symbol;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    override
    returns (string memory url)
  {
    require(
      _exists(tokenId),
      'ERC721URIStorage: URI query for nonexistent token'
    );
    uint256 playId = getTokenById(tokenId).playID;
    string memory tokenUri = getPlayBy(playId).url;
    if (bytes(_baseUri).length > 0) {
      return string(abi.encodePacked(_baseUri, tokenUri));
    }
    if (bytes(tokenUri).length > 0) {
      return tokenUri;
    }

    return '';
  }

  function getPlayBy(uint256 playID) public view returns (Play memory play) {
    play = plays[playID];
  }

  function getPlayCount() public view returns (uint256 count) {
    count = plays.length;
  }

  function createPlay(
    string memory _url,
    uint8 tokenType,
    uint256 initialPrice
  ) public onlyMinter returns (uint256) {
    require(tokenType < _tokenType.length);
    Play memory newPlay = Play({
      url: _url,
      tokenType: tokenType,
      initialPrice: initialPrice
    });
    plays.push(newPlay);
    uint256 newPlayID = plays.length - 1;
    emit PlayCreated(newPlayID, _url, tokenType);
    return newPlayID;
  }

  function tokenSNCountOf(uint256 playID) public view returns (uint256) {
    return tokenSNCount[playID];
  }

  function _mint(uint256 playID, address to) internal returns (uint256) {
    Play memory play = plays[playID];

    require(
      tokenSNCountOf(playID) < _tokenType[play.tokenType],
      'ERC721: Token mint exceeded the limit of play'
    );

    uint256 newTokenId = tokens.length;
    _beforeTokenTransfer(address(0), to, newTokenId);

    uint256 tokenSerialNumber = tokenSNCount[playID];
    tokenSNCount[playID]++;

    Token memory newToken = Token({
      playID: playID,
      serialNumber: tokenSerialNumber
    });
    tokens.push(newToken);
    tokenOwners[newTokenId] = to;

    _totalSupply++;
    ownershipTokenCount[to]++;

    emit TokenCreated(playID, tokenSerialNumber, newTokenId);

    return newTokenId;
  }

  function balanceOf(address _owner)
    public
    view
    override(IERC721)
    returns (uint256 balance)
  {
    balance = ownershipTokenCount[_owner];
  }

  function getTokenById(uint256 _tokenId) public view returns (Token memory) {
    return tokens[_tokenId];
  }

  function tokenByIndex(uint256 index)
    public
    pure
    override(IERC721Enumerable)
    returns (uint256 tokenId)
  {
    return index;
  }

  function tokenOfOwnerByIndex(address _owner, uint256 _index)
    public
    view
    override
    returns (uint256)
  {
    uint256 count = 0;
    for (uint256 i = 0; i < _totalSupply; i++) {
      if (tokenOwners[i] == _owner) {
        if (count == _index) {
          return i;
        } else {
          count++;
        }
      }
    }
    revert();
  }

  function totalSupply() public view override returns (uint256) {
    return _totalSupply;
  }

  function ownerOf(uint256 tokenId)
    public
    view
    override(IERC721)
    returns (address _owner)
  {
    _owner = tokenOwners[tokenId];
  }

  function _exists(uint256 tokenId) internal view returns (bool) {
    return tokenOwners[tokenId] != address(0);
  }

  function setApprovalForAll(address operator, bool approved)
    public
    override(IERC721)
  {
    require(operator != _msgSender(), 'ERC721: approve to caller');

    _operatorApprovals[_msgSender()][operator] = approved;
    emit ApprovalForAll(_msgSender(), operator, approved);
  }

  function getApproved(uint256 tokenId)
    public
    view
    override(IERC721)
    returns (address approvedTo)
  {
    require(_exists(tokenId), 'ERC721: approved query for nonexistent token');

    approvedTo = _tokenApprovals[tokenId];
  }

  function approve(address to, uint256 tokenId) public override(IERC721) {
    require(to != address(0));
    require(ownerOf(tokenId) == _msgSender());

    _approve(to, tokenId);
  }

  function _approve(address to, uint256 tokenId) internal {
    _tokenApprovals[tokenId] = to;
    emit Approval(_msgSender(), to, tokenId);
  }

  function isApprovedForAll(address _owner, address operator)
    public
    view
    override(IERC721)
    returns (bool)
  {
    return _operatorApprovals[_owner][operator];
  }

  function _isApprovedOrOwner(address spender, uint256 tokenId)
    internal
    view
    returns (bool)
  {
    require(_exists(tokenId), 'ERC721: operator query for nonexistent token');
    address _owner = this.ownerOf(tokenId);
    return (spender == _owner ||
      getApproved(tokenId) == spender ||
      isApprovedForAll(_owner, spender));
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) external virtual override {
    require(_from != address(0));
    require(_to != address(0));
    require(ownerOf(_tokenId) == _from);

    transferFrom(_from, _to, _tokenId);

    require(_checkOnERC721Received(_from, _to, _tokenId, ''));
  }

  function transferFrom(
    address _from,
    address _to,
    uint256 _tokenId
  ) public virtual override(IERC721) {
    require(_isApprovedOrOwner(_from, _tokenId), 'ERC721: User not authorized');
    require(_to != address(0));
    _transfer(_from, _to, _tokenId);
    emit Transfer(_from, _to, _tokenId);
  }

  function _transfer(
    address _from,
    address _to,
    uint256 _tokenId
  ) internal {
    _beforeTokenTransfer(_from, _to, _tokenId);

    ownershipTokenCount[_to]++;
    tokenOwners[_tokenId] = _to;

    // Reset operator of the token after token transfer
    _approve(address(0), _tokenId);

    if (_from != address(0)) {
      ownershipTokenCount[_from]--;
    }
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC165, IERC165)
    returns (bool)
  {
    return
      interfaceId == type(IERC721).interfaceId ||
      interfaceId == type(IERC721Metadata).interfaceId ||
      interfaceId == type(IERC721Enumerable).interfaceId ||
      super.supportsInterface(interfaceId);
  }

  function safeTransferFrom(
    address _from,
    address _to,
    uint256 _tokenId,
    bytes calldata data
  ) public override {
    require(_from != address(0));
    require(_to != address(0));
    require(ownerOf(_tokenId) == _from);

    transferFrom(_from, _to, _tokenId);

    require(_checkOnERC721Received(_from, _to, _tokenId, data));
  }

  function owner() public view override(Ownable) returns (address) {
    return super.owner();
  }

  function mint(uint256 playID) public onlyMinter {
    _mint(playID, _msgSender());
  }

  function _checkOnERC721Received(
    address from,
    address to,
    uint256 tokenId,
    bytes memory _data
  ) private returns (bool) {
    if (to.isContract()) {
      try
        IERC721Receiver(to).onERC721Received(_msgSender(), from, tokenId, _data)
      returns (bytes4 retval) {
        return retval == IERC721Receiver.onERC721Received.selector;
      } catch (bytes memory reason) {
        if (reason.length == 0) {
          revert('ERC721: transfer to non ERC721Receiver implementer');
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

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal virtual {}
}

// SPDX-License-Identifier: MIT

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
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s;
        uint8 v;
        assembly {
            s := and(vs, 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff)
            v := add(shr(255, vs), 27)
        }
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

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

// SPDX-License-Identifier: MIT

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

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/access/Ownable.sol';

contract AccessControl is Ownable {
  address private _minter;

  event MinterChanged(address indexed oldMinter, address indexed newMinter);

  constructor() {
    setMinter(_msgSender());
  }

  modifier onlyMinter() {
    require(_msgSender() == _minter, 'Mintable: caller is not the minter');
    _;
  }

  function setMinter(address newMinter) public onlyOwner {
    address oldMinter = newMinter;
    _minter = newMinter;
    emit MinterChanged(oldMinter, newMinter);
  }

  function minter() public view returns (address) {
    return _minter;
  }
}

// SPDX-License-Identifier: MIT

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
        _setOwner(_msgSender());
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
        _setOwner(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT

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