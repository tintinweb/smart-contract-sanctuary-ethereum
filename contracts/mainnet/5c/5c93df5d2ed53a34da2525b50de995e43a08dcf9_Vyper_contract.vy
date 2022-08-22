# @dev ERC-721 Exchange
# @author internnos(https://github.com/internnos)
# @version 0.3.1

from vyper.interfaces import ERC721 as IERC721
from vyper.interfaces import ERC20 as IERC20


struct PricingInfo:
    is_on_sale: bool
    payment_token: address
    listing_price: uint256

struct BidInfo:
    payment_token: address
    price_bid: uint256
    expire_time: uint256

struct PaymentAllocation:
    platform: uint256
    seller: uint256



DAY: constant(uint256) = 86400
QUARTER_HOUR: constant(uint256) = DAY / 24 / 4
DECIMAL: constant(uint256) = 3

minimum_expire_time: uint256 
approved_tokens_as_payment: HashMap[address, bool]
listing_information: HashMap[address, HashMap[uint256, PricingInfo]]
bid_information: HashMap[address, HashMap[uint256, HashMap[address, BidInfo]]]
admin: address
treasury: public(address)
platform_fee_in_terms_of_decimal: uint256



event Bidding:
    sender: indexed(address)
    nft_collection: indexed(address)
    token_id: uint256
    payment_token: indexed(address)
    bidding_price: uint256
    expire_time: uint256

event ChangeExpireTime:
    before: uint256
    after: uint256

event Listing:
    maker: indexed(address)
    nft_collection: indexed(address)
    token_id: uint256
    payment_token: address
    listing_price: uint256


event ApproveTokenAsPayment:
    token: indexed(address)
    is_approved: bool

event OrdersMatched:
    sender: indexed(address)
    receiver: indexed(address)
    nft_collection: indexed(address)
    token_id: uint256
    payment_token: address
    price_matched: uint256

event ChangePlatformFee:
    before: uint256
    after: uint256

event ChangeTreasuryAddress:
    before: address
    after: address

@external
def __init__(_treasury: address, _platform_fee_in_terms_of_decimal: uint256):
    self.admin = msg.sender
    self.minimum_expire_time = QUARTER_HOUR
    self.treasury = _treasury
    self.platform_fee_in_terms_of_decimal = _platform_fee_in_terms_of_decimal


@external
@view
def check_listed_items(nft_collection: address, token_id: uint256) -> PricingInfo:
    return self.listing_information[nft_collection][token_id]

@external
def change_minimum_expire_time(_expire_time: uint256):
    assert _expire_time > 0, "ArtpediaExchange: expire time must be greater than 0"
    assert msg.sender == self.admin, "ArtpediaExchange: caller is not the Admin"
    log ChangeExpireTime(self.minimum_expire_time, _expire_time)
    self.minimum_expire_time = _expire_time
    
@external
def change_treasury_address(_treasury: address):
    assert _treasury != ZERO_ADDRESS, "ArtpediaExchange: cannot change into ZERO_ADDRESS"
    assert _treasury != self.treasury, "ArtpediaExchange: new treasury address must be different than the old one"
    assert msg.sender == self.admin, "ArtpediaExchange: caller is not the Admin"
    log ChangeTreasuryAddress(self.treasury, _treasury)
    self.treasury = _treasury

@external
def change_platform_fee_in_terms_of_decimal(_platform_fee_in_terms_of_decimal: uint256):
    assert _platform_fee_in_terms_of_decimal >= 1, "ArtpediaExchange: platform fee must be greater than 1 (because of rounding)"
    assert msg.sender == self.admin, "ArtpediaExchange: caller is not the Admin"
    log ChangePlatformFee(self.platform_fee_in_terms_of_decimal, _platform_fee_in_terms_of_decimal)
    self.platform_fee_in_terms_of_decimal = _platform_fee_in_terms_of_decimal


@view
@internal
def _check_approved_tokens_as_payment(token: address) -> bool:
    return self.approved_tokens_as_payment[token]


@view
@external
def check_approved_tokens_as_payment(token: address) -> bool:
    return self._check_approved_tokens_as_payment(token)

@external
@view
def return_bade_items(_nft_collection: address, _token_id: uint256, user: address) -> BidInfo:
    return self.bid_information[_nft_collection][_token_id][user]

@internal
@view
def _calculate_token_allocation(_total_amount: uint256) -> PaymentAllocation:
    # platform_fee_in_percentage: uint256 = self.platform_fee_in_terms_of_decimal / DECIMAL
    platform_allocation: uint256 = _total_amount * self.platform_fee_in_terms_of_decimal / 10**DECIMAL / 100 
    seller_allocation: uint256 = _total_amount - platform_allocation
    # platform_allocation: uint256 = _total_amount - seller_allocation
    assert platform_allocation > 0 and seller_allocation > 0, 'ArtpediaExchange: listing/bidding fee is too small, consider using more than 49 wei'
    return PaymentAllocation(
        {
            platform: platform_allocation,
            seller: seller_allocation

        }
    )

@internal
def _is_approved_or_owner(
    _spender: address, _nft_collection: address, _token_id: uint256
) -> bool:
    owner: address = IERC721(_nft_collection).ownerOf(_token_id)
    is_owner: bool = owner == _spender
    is_approved: bool = IERC721(_nft_collection).getApproved(_token_id) == _spender
    is_operator: bool = IERC721(_nft_collection).isApprovedForAll(owner, _spender)

    return (is_owner or is_approved) or is_operator
    

@external
def listing(
    _nft_collection: address,
    _token_id: uint256,
    _payment_token: address,
    _listing_price: uint256,
):
    """
    @notice
        Create offer for ERC721 (NFT) by sender and propagated to the network. The sender must have the authorithy to give approval to the exchange.
    @param _nft_collection
        The address of the NFT collection
    @param _token_id
        The id of the NFT in the nft_collection
    @param _payment_token
        The address of ERC20 token requested as the payment
    @param _listing_price
        The price offered by the owner
    """
    assert (
        IERC721(_nft_collection).getApproved(_token_id) == self
    ), "ArtpediaExchange: exchange is not approved yet"
    assert (
        self.listing_information[_nft_collection][_token_id].is_on_sale == False
    ), "ArtpediaExchange: item already listed"
    assert (
        self._is_approved_or_owner(msg.sender, _nft_collection, _token_id) == True
    ), "ArtpediaExchange: listing caller is not owner nor approved(including operators)"
    self._calculate_token_allocation(_listing_price)
    assert self._check_approved_tokens_as_payment(
        _payment_token
    ), "ArtpediaExchange: not an approved ERC-20 on Artpedia"
    self.listing_information[_nft_collection][_token_id] = PricingInfo(
        {
            is_on_sale: True,
            payment_token: _payment_token,
            listing_price: _listing_price,
        }
    )
    #
    log Listing(msg.sender, _nft_collection, _token_id, _payment_token, _listing_price)


@internal
def _delisting(_nft_collection: address, _token_id: uint256, sender: address):
    """
    @dev Throws unless `msg.sender` is the current owner, an authorized admin for this NFT, or an approved address
    @notice
        Delist / cancel NFT from being sold in the exchange. The sender must be either the owner, approved, or operators.
        Will emit Listing event
    @param _nft_collection
        The address of the NFT collection
    @param _token_id
        The id of the NFT in the nft_collection

    """
    assert (
        self.listing_information[_nft_collection][_token_id].is_on_sale == True
    ), "ArtpediaExchange: item not listed"
    assert (
        self._is_approved_or_owner(sender, _nft_collection, _token_id) == True
    ), "ArtpediaExchange: cancel caller is not owner nor approved(including operators)"
    # TODO: remove approval from the exchange
    self.listing_information[_nft_collection][_token_id] = PricingInfo(
        {
            is_on_sale: False,
            payment_token: ZERO_ADDRESS,
            listing_price: 0,
        }
    )
    log Listing(sender, _nft_collection, _token_id, ZERO_ADDRESS, 0)




@external
@view
def calculate_token_allocation(_total_amount: uint256) -> PaymentAllocation:
    return self._calculate_token_allocation(_total_amount)


@internal
def _send_payment_to_entitled_parties(_payment_token: address, _total_amount: uint256, _from: address, _to: address):
    payment_allocation: PaymentAllocation = self._calculate_token_allocation(_total_amount)
    IERC20(_payment_token).transferFrom(_from, _to, payment_allocation.seller)
    IERC20(_payment_token).transferFrom(_from, self.treasury, payment_allocation.platform)



@external
def delisting(_nft_collection: address, _token_id: uint256):
    """
    @dev Throws unless `msg.sender` is the current owner, an authorized admin for this NFT, or an approved address
    @notice
        Delist / cancel NFT from being sold in the exchange. The sender must be either the owner, approved, or operators.
        Will emit Listing event
    @param _nft_collection
        The address of the NFT collection
    @param _token_id
        The id of the NFT in the nft_collection

    """
    self._delisting(_nft_collection, _token_id, msg.sender)


@external
def approve_token_as_payment(_erc_20_token: address, _is_approved: bool):
    """
    @dev Throws unless `msg.sender` is the admin of the exchange
    @notice
        Approve ERC20 token as the payment of the NFT
    @param _erc_20_token
        ERC20 token that is given approval
    @param _is_approved
        is the token approved or not, can be used for turning off approval

    """
    assert self.admin == msg.sender, "ArtpediaExchange: caller is not the Admin"
    assert (
        self.approved_tokens_as_payment[_erc_20_token] != _is_approved
    ), "ArtpediaExchange: ERC-20 token already has the same approval"
    self.approved_tokens_as_payment[_erc_20_token] = _is_approved
    log ApproveTokenAsPayment(_erc_20_token, _is_approved)

@external
@nonreentrant("transferFrom")
def buy(_nft_collection: address, _token_id: uint256):
    """
    @notice
        Buy ERC721 instantly / spot buy
    @param _nft_collection
        The address of the NFT collection
    @param _token_id
        The id of the NFT in the nft_collection
    """
    pricing_info: PricingInfo = self.listing_information[_nft_collection][_token_id]
    assert pricing_info.is_on_sale == True, "ArtpediaExchange: item not listed"
    assert IERC20(pricing_info.payment_token).balanceOf(msg.sender) >= pricing_info.listing_price, "ArtpediaExchange: buyer does not have enough ERC-20 Tokens"
    assert IERC20(pricing_info.payment_token).allowance(msg.sender, self) >= pricing_info.listing_price, "ArtpediaExchange: insufficient allowance"

    erc_721_owner: address = IERC721(_nft_collection).ownerOf(_token_id)
    
    assert erc_721_owner != msg.sender, "ArtpediaExchange: caller is ERC-721 owner"
    self._delisting(_nft_collection, _token_id, self)
    # Transfer NFT from seller into buyer
    IERC721(_nft_collection).safeTransferFrom(erc_721_owner, msg.sender, _token_id, b"")

    # Transfer ERC-20 from buyer into seller and treasury
    self._send_payment_to_entitled_parties(pricing_info.payment_token, pricing_info.listing_price, msg.sender, erc_721_owner)
    
    log OrdersMatched(msg.sender, erc_721_owner, _nft_collection, _token_id, pricing_info.payment_token, pricing_info.listing_price)
    

@external
def bid(_nft_collection: address, _token_id: uint256, _payment_token: address, _price_bid: uint256, _expire_time: uint256):
    """
    @notice
        Buy ERC-721 for unlisted item or item with different listing price(usually lower). 
        Override new bid by default. Can also bid using different ERC-20 from the listing ERC-20 tokens
    @param _nft_collection
        The address of the NFT collection
    @param _token_id
        The id of the NFT in the nft_collection
    """
    erc_721_owner: address = IERC721(_nft_collection).ownerOf(_token_id)
    assert erc_721_owner != msg.sender, "ArtpediaExchange: caller is ERC-721 owner"
    assert _payment_token != ZERO_ADDRESS, "ArtpediaExchange: cannot bid using zero address"

    self._calculate_token_allocation(_price_bid)
    assert self._check_approved_tokens_as_payment(
        _payment_token
    ), "ArtpediaExchange: not an approved ERC-20 on Artpedia"

    assert _expire_time >= self.minimum_expire_time, "ArtpediaExchange: expire time too low"
    
    assert IERC20(_payment_token).balanceOf(msg.sender) >= _price_bid, "ArtpediaExchange: buyer does not have enough ERC-20 Tokens"
    assert IERC20(_payment_token).allowance(msg.sender, self) >= _price_bid, "ArtpediaExchange: insufficient allowance"    
    self.bid_information[_nft_collection][_token_id][msg.sender] = BidInfo({
        payment_token: _payment_token,
        price_bid: _price_bid,
        expire_time: block.timestamp + _expire_time
    })
    
    log Bidding(msg.sender,_nft_collection, _token_id, _payment_token, _price_bid, block.timestamp+ _expire_time)


@external
@nonreentrant("transferFrom")
def accept_bid(_nft_collection: address, _token_id: uint256, _payment_token: address, _minimum_price: uint256, _taker: address):
    """
    @notice
        Accept bid from a taker. Throw error unless caller is not owner nor approved(including operators)
    @param _nft_collection
        The address of the NFT collection
    @param _token_id
        The id of the NFT in the NFT collection
    @param _payment_token
        The address of ERC20 token requested as the payment
    @param _minimum_price
        The price of the NFT to prevent frontrunning
    @param _taker
        Address of accepted bid
    
    """
    erc_721_owner: address = IERC721(_nft_collection).ownerOf(_token_id)
    assert (
        self._is_approved_or_owner(msg.sender, _nft_collection, _token_id) == True
    ), "ArtpediaExchange: caller is not owner nor approved(including operators)"
    bid_info: BidInfo = self.bid_information[_nft_collection][_token_id][_taker]

    assert bid_info.payment_token != ZERO_ADDRESS and bid_info.price_bid > 0, "ArtpediaExchange: accept non-existent bid"
    assert bid_info.expire_time > block.timestamp, "ArtpediaExchange: bid has expired"

    assert bid_info.payment_token == _payment_token and bid_info.price_bid >= _minimum_price, "ArtpediaExchange: bid frontrunning detected"
    if self.listing_information[_nft_collection][_token_id].is_on_sale == True:
        self._delisting(_nft_collection, _token_id, self)

    # Transfer NFT from seller into buyer
    IERC721(_nft_collection).safeTransferFrom(erc_721_owner, _taker, _token_id, b"")

    # Transfer ERC-20 from buyer into seller
    self._send_payment_to_entitled_parties(_payment_token, _minimum_price, _taker, erc_721_owner)
    
    log OrdersMatched(_taker, erc_721_owner, _nft_collection, _token_id, bid_info.payment_token, bid_info.price_bid)


@external
def cancel_bid(_nft_collection: address, _token_id: uint256):
    """
    @notice
        Cancel for existing bid. 
        Emit Bidding Event with 0 bid and 0 expire_time
        Throw error if bid is already cancelled, or sender is not owner nor approved
    @param _nft_collection
        The address of the NFT collection
    @param _token_id
        The id of the NFT in the nft_collection
    """

    bid_info: BidInfo = self.bid_information[_nft_collection][_token_id][msg.sender]
    assert bid_info.payment_token != ZERO_ADDRESS and bid_info.price_bid > 0, "ArtpediaExchange: no bid for this token_id"
    assert bid_info.expire_time > block.timestamp, "ArtpediaExchange: no bid for this token_id"

    self.bid_information[_nft_collection][_token_id][msg.sender] = BidInfo({
        payment_token: ZERO_ADDRESS,
        price_bid: 0,
        expire_time: 0
    })
    log Bidding(msg.sender,_nft_collection, _token_id, ZERO_ADDRESS, 0, 0)