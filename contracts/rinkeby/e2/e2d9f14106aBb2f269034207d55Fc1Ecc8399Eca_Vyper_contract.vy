# @version 0.3.3

"""
@title PAC DAO 2022 Congressional Scorecard Minter
@notice Minter for 
@author pacdao.eth 
@license MIT
"""

#
#                        ::
#                        ::
#                       .::.
#                     ..::::..
#                    .:-::::-:.
#                   .::::::::::.
#                   :+========+:
#                   ::.:.::.:.::
#            ..     :+========+:    ..
# @@@@@@@...........:.:.:..:.:.:[email protected]@@@@@@@
# @@@@@@@@@@* :::. .:.:.:..:.:.:   . .  [email protected]@@@@@@@@
# @@@@@@@@@@@@@***: :....::-.:.:.:.:[email protected]@@@@@@@@@@@@@
# @@@@@@@@@@@@@@@@..+==========+...:@@@@@@@@@@@@@@@
# https://ascii-generator.site/

from vyper.interfaces import ERC20

interface ERC721:
   def mint(recipient: address, metadata: uint256): nonpayable
   def set_owner(new_owner: address): nonpayable

# General Properties
max_seat_count: constant(uint256) = 600
seat_count: public(uint256)
claimed_seats: public(uint256)
is_live: public(bool)
seats: public(HashMap[uint256, address])

# Addresses
nft_addr: public(address)
owner: public(address)

# Auction Variables
auction_bids: public(HashMap[uint256, HashMap[address, uint256]]) # Seat, Addr, Amt 
auction_leaders: public(HashMap[uint256, address])
auction_deadline: public(HashMap[uint256, uint256])
auction_duration: public(uint256)
auction_interval: public(uint256)
redeemed: public(HashMap[address, uint256])

# Batch Properties
min_price: public(uint256)
min_interval: public(uint256)
max_mint_batch_quantity: public(uint256)

# User Variables
seat_by_index: public(HashMap[address, HashMap[uint256, uint256]])
user_claim_count: public(HashMap[address, uint256])

# Seat Status
seats_filled: public(DynArray[uint256, max_seat_count])
seats_minted: public(DynArray[uint256, max_seat_count]) 


event SeatReserved:
   seat_id: uint256
   owner: address


@external
def __init__(
    nft_addr: address,
):
    self.nft_addr = nft_addr
    self.seat_count = 539

    self.is_live = True
    self.auction_duration = 60 * 60 * 24  #auction_duration
    self.auction_interval = 1000000000000000

    self.owner = msg.sender
    self.min_price = 1000000000000000
    self.min_interval = 1000000000000000
    self.max_mint_batch_quantity = 1000000000000000


### INTERNAL FUNCTIONS

@internal
@view
def _auction_status(seat_id : uint256) -> uint256:
    if self.seats[seat_id] != ZERO_ADDRESS:
        if self.auction_deadline[seat_id] > block.timestamp:
            return 1
        else:
            return 2
    else:
        return 0 


@internal
@view
def _top_bid(seat: uint256) -> uint256:
    if self.auction_deadline[seat] > 0:
        return self.auction_bids[seat][self.auction_leaders[seat]] 
    elif self.seats[seat] != ZERO_ADDRESS:
        return self.min_price
    else:
        return 0 


@internal
@view
def _current_leader(seat: uint256) -> address:
    if self.seats[seat] == self:
        return self.auction_leaders[seat]
    else:
        return self.seats[seat]

@internal
def _mint(target: address, seat_id: uint256):
    """
    @notice Internal function to call the mint function on the external NFT contract
    @param target Address of the owner of the NFT
    """
    ERC721(self.nft_addr).mint(target, seat_id)


@internal
def _reserve_seat(target: address, seat_id: uint256):
    """
    @notice Earmark a specific seat to an address
    @param target The address currently claiming the seat
    @param seat_id Index of the seat being claimed
    """
    assert self.seats[seat_id] == ZERO_ADDRESS  # dev: Seat Assigned
    assert seat_id > 0  # dev: Invalid Seat

    self.seats[seat_id] = target
    self.seat_by_index[target][self.user_claim_count[target]] = seat_id
    self.seats_filled.append(seat_id)
    self.claimed_seats += 1
    self.user_claim_count[target] += 1
    log SeatReserved(seat_id, target)


@internal
def get_pseudorandom_number(seed: uint256) -> uint256:
    """
    @notice A semi-random number, good enough for gov't work
    @param An offset to prevent sequential numbers
    """
    return (block.timestamp * (1+seed)) % self.seat_count + 1


### LITE VIEWS

@external
@view
def auction_status(seat: uint256) -> uint256:
    return self._auction_status(seat)


@external
@view
def auction_max_bid(seat: uint256) -> uint256:
    return self._top_bid(seat)


@external
@view
def current_leader(seat: uint256) -> address:
    return self._current_leader(seat)



### MEGAVIEWS 
@external
@view
def user_wins(addr : address) -> DynArray[uint256, max_seat_count]:
    ret_array : DynArray[uint256, max_seat_count] = []
    for i in range(max_seat_count):
        if self.seats[i] ==addr:
            ret_array.append(i)
    return ret_array


# BIG MEGALOOP METHODS

@external
@view
def auction_statuses() -> uint256[max_seat_count]:
    """
    @notice Retrieve auction status for every seat
    @return 1 if auction is live, 2 if auction ended, 0 otherwise
    """

    ret_arr: uint256[max_seat_count] = empty(uint256[max_seat_count])
    for i in range(max_seat_count):
        ret_arr[i] = self._auction_status(i) 

    return ret_arr



@external
@view
def auction_max_bids() -> uint256[max_seat_count]:
    """
    @notice Retrieve top bid for all seats
    @dev Schedule to replace with specific seat lookup
    """

    ret_arr: uint256[max_seat_count] = empty(uint256[max_seat_count])
    for i in range(max_seat_count):
        ret_arr[i] = self._top_bid(i)
	
    return ret_arr


   

@external
@view
def seat_winners() -> address[max_seat_count]:
    """
    @notice View all seats with current leader
    @return ZERO_ADDR if not started, or the current user address
    """
    ret_arr: address[max_seat_count] = empty(address[max_seat_count])
    for i in range(max_seat_count):
        ret_arr[i] = self._current_leader(i)

    return ret_arr


@external
@view
def user_bids(user : address) -> uint256[max_seat_count]:
    """
    @notice function taking in user addr and returns array of all bids
    @return all_bids 
    @dev Can also call directly at self.auction_bids
    """
    ret_arr: uint256[max_seat_count] = empty(uint256[max_seat_count])
    for i in range(max_seat_count):
        ret_arr[i] = self.auction_bids[i][user]

    return ret_arr



@external
@view
def auction_deadlines() -> uint256[max_seat_count]:
    """
    @notice View all seats with current deadline
    @return Every seat's current deadline
    """

    ret_arr: uint256[max_seat_count] = empty(uint256[max_seat_count])
    for i in range(max_seat_count):
        if self.seats[i] != ZERO_ADDRESS and self.auction_deadline[i] == 0:
            ret_arr[i] = block.timestamp
        else:
            ret_arr[i] = self.auction_deadline[i]

    return ret_arr


@external
@view
def mint_statuses() -> bool[max_seat_count]:
    """
    @notice View all seats with mint status
    @return Array of all mint statuses
    """

    ret_arr: bool[max_seat_count] = empty(bool[max_seat_count])
    for i in range(max_seat_count):
        if i in self.seats_minted:
            ret_arr[i] = True
        else:
            ret_arr[i] = False

    return ret_arr


# INTERNAL FUNCTIONS

@internal
def _auction_update(seat_id: uint256, addr: address, amount: uint256):
    self.auction_deadline[seat_id] = block.timestamp + self.auction_duration
    self.auction_bids[seat_id][addr] += amount

    _leader: address = self.auction_leaders[seat_id]
    if self.auction_bids[seat_id][addr] > self.auction_bids[seat_id][_leader]:
        self.auction_leaders[seat_id] = addr


@internal
@payable
def _auction_start(
    seat_id: uint256, msg_value: uint256, msg_sender: address
):

    self._reserve_seat(self, seat_id)
    self._auction_update(seat_id, msg.sender, msg.value)


@external
@view
def is_seat_open_for_auction(seat_id : uint256) -> bool:
    """
    @notice See if an auction is presently biddable
    @param seat_id Index of seat to bid on
    @dev Misleading name change to is_biddable or something
    @return True if biddable
    """
    if self.auction_deadline[seat_id] > 0: # Auction has started
        if block.timestamp < self.auction_deadline[seat_id]:
            return True
        else:
            return False

    else: # No auction started
        if self.seats[seat_id] != ZERO_ADDRESS:
            return False # Seat claimed
        else:
            return True
        

@external
@view
def is_auction_ended(seat_id : uint256) -> bool:
    """
    @notice See if an auction is presently over
    @param seat_id Index of seat to check
    @return True if auction ended
    """
    if self.auction_deadline[seat_id] > 0 and block.timestamp >= self.auction_deadline[seat_id]:
        return True
    return False

 
@external
@payable
def auction_bid(seat_id: uint256):
    """
    @notice Main bidding function, must be in units of auction_interval()
    @param seat_id The seat to open a bid on
    """

    assert msg.value > 0, "No value"
    assert seat_id > 0 and seat_id <= self.seat_count, "Invalid Seat"
    assert msg.value / self.auction_interval * self.auction_interval == msg.value, "Min interval violation"

    if self.auction_deadline[seat_id] == 0:
        self._auction_start(seat_id, msg.value, msg.sender)
    else:
        assert self._auction_status(seat_id) != 2, "Auction ended"
        self._auction_update(seat_id, msg.sender, msg.value)


### MINT FUNCTIONS

@external
def generate_mint(
    seat_id: uint256 
):
    """
    @notice Mint an NFT at auction close
    @param seat_id Seat id for completed auction
    """
    assert self.seats[seat_id] != ZERO_ADDRESS, "Seat not assigned"
    assert seat_id not in self.seats_minted, "Seat already minted"

    target : address = ZERO_ADDRESS

    if self.auction_deadline[seat_id] > 0: # Auction has started
        assert self.auction_deadline[seat_id] < block.timestamp, "Auction has not ended"
        target = self.auction_leaders[seat_id]
    else:
        target = self.seats[seat_id]

    self._mint(target, seat_id)
    self.seats_minted.append(seat_id)



### RANDOM BATCH FUNCTIONS

@internal
def get_pseudorandom_seat(seed: uint256) -> uint256:
    """
    @notice Select an unfilled seat at pseudorandom
    @param seed An offset
    """
    seat_id: uint256 = self.get_pseudorandom_number(seed)
    offset: bool = False
    _val: uint256 = 0

    for j in range(max_seat_count):
        if seat_id + j > max_seat_count:
            offset = True

        if offset:
            _val = seat_id + j - max_seat_count
        else:
            _val = seat_id + j

        if self.seats[_val] == ZERO_ADDRESS:
            return _val
    assert False  # dev: No Seat Available
    return 0



@internal
@view
def _batch_price(quantity: uint256) -> uint256:
    return self.min_price * quantity


@external
@payable
def mint_batch(quantity: uint256):
    """
    @notice Reserve a batch of several NFTs at one time
    @param quantity The number of NFTs to mint
    @dev Must pay ETH defined by mint_batch_price()
    """

    assert self.claimed_seats + quantity <= self.seat_count  # dev: Too few seats left!
    assert self.is_live == True  # dev: Auction has ended
    assert msg.value >= self._batch_price(quantity)  # dev: Did not pay enough
    assert quantity < self.max_mint_batch_quantity # dev: Mint batch capped

    for i in range(max_seat_count):
        if i >= quantity:
            break

        # Get Pseudorandom Number
        seat_id: uint256 = self.get_pseudorandom_seat(i)

        self._reserve_seat(msg.sender, seat_id)
        self._mint(msg.sender, seat_id)
        self.seats_minted.append(seat_id)


@external
@view
def mint_batch_price(quantity: uint256) -> uint256:
    """
    @notice Get the price needed for minting a batch
    @param quantity The target number of seats to mint
    @return Cost to mint quantity (in Wei)
    """
    return self._batch_price(quantity)



### ADMIN FUNCTIONS

@external
def admin_claim(index: uint256):
    assert self.owner == msg.sender
    self._mint(msg.sender, index)

@external
def admin_nft_owner(new_owner: address):
    assert self.owner == msg.sender
    ERC721(self.nft_addr).set_owner(new_owner)

@external
def admin_new_owner(new_owner: address):
   assert msg.sender == self.owner
   self.owner = new_owner
   
@external
def admin_withdraw(target: address, amount: uint256):
   """
   @notice Withdraw funds to admin
   @dev Could be used to rug, fix before launch
   """
   assert self.owner == msg.sender
   send(target, amount)

@external
def admin_withdraw_erc20(coin: address, target: address, amount: uint256):
   """
   @notice Withdraw ERC20 tokens accidentally sent to contract
   """
   assert self.owner == msg.sender
   ERC20(coin).transfer(target, amount)

@external
def admin_set_min_price(amount: uint256):
   """
   @notice Update min price used for minting packs
   """
   assert self.owner == msg.sender
   self.min_price = amount


# AUCTION REDEMPTIONS
@internal
@view
def _redeemable_balance(acct : address) -> uint256:
    bal : uint256 = 0
    for i in range(max_seat_count):
        if self._auction_status(i) == 2 and self.auction_leaders[i] != acct:
            bal += self.auction_bids[i][acct]

    return bal - self.redeemed[acct]

@external
@view
def redeemable_balance(acct : address) -> uint256:
    return self._redeemable_balance(acct)

@external
def redeem_missing(acct : address):
    """
    @notice Retrieve outstanding funds after auction redemption
    @dev XXX Redeems entire balance for testing
    """
    claim_amt : uint256 = self._redeemable_balance(acct)
    assert claim_amt > 0, "No claim"
    send(acct, claim_amt) 
    self.redeemed[acct] = claim_amt


### JUST FOR TESTING

@external
def end_auction(seat_id : uint256):
   self.auction_deadline[seat_id] = block.timestamp - 1


@external
def random(seed: uint256) -> uint256:
    """
    @notice Test the pseudorandom function
    @dev Used to test, delete this before running
    """
    return self.get_pseudorandom_number(seed)