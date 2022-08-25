# @version 0.3.6

"""
@title PAC DAO 2022 Congressional Scorecard Minter
@notice Minter for PAC DAO PHATCAT NFT
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

from vyper.interfaces import ERC20

interface ERC721:
    def mint(recipient: address, metadata: uint256): nonpayable
    def set_owner(new_owner: address): nonpayable

# General Properties
max_seat_count: constant(uint256) = 600
seat_count: public(uint256)  # Cap a bit smaller in case we add rares
claimed_seats: public(uint256)
is_live: public(bool)
seats: public(HashMap[uint256, address])

# Addresses
nft_addr: public(address)
owner: public(address)

# Auction Variables
auction_bids: public(HashMap[uint256, HashMap[address, uint256]])  # Seat, Addr, Amt
auction_leaders: public(HashMap[uint256, address])
auction_deadline: public(HashMap[uint256, uint256])
auction_duration: public(uint256)
auction_interval: public(uint256)

# Batch Properties
min_price: public(uint256)
MAX_MINT_BATCH_QUANTITY: constant(uint256) = 10
max_mint_batch_quantity: public(uint256)

# Freebies
used_coupon: public(HashMap[address, bool])
whitelist: public(HashMap[address, bool])
coupon_token: public(address)

# Seat Status
seats_filled: public(DynArray[uint256, max_seat_count])
seats_minted: public(DynArray[uint256, max_seat_count])
losers_redeemed: public(HashMap[address, uint256])
no_mint_list: public(DynArray[uint256, max_seat_count])


event SeatReserved:
    seat_id: uint256
    owner: address


@external
def __init__():
    self.seat_count = 539

    self.is_live = True
    self.auction_duration = 60 * 60 * 24
    self.auction_interval = 1000000000000000

    self.owner = msg.sender
    self.min_price = 100000000000000000
    self.max_mint_batch_quantity = MAX_MINT_BATCH_QUANTITY

    self.no_mint_list = [367, 369, 392, 333]


### INTERNAL FUNCTIONS


@internal
@view
def _auction_status(seat_id: uint256) -> uint256:
    if self.seats[seat_id] != empty(address):
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
    elif self.seats[seat] != empty(address):
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
    assert self.seats[seat_id] == empty(address)  # dev: Seat Assigned
    assert seat_id > 0  # dev: Invalid Seat

    self.seats[seat_id] = target
    self.seats_filled.append(seat_id)

    log SeatReserved(seat_id, target)


@internal
def _get_pseudorandom_number(seed: uint256) -> uint256:
    """
    @notice A semi-random number, good enough for gov't work
    @dev Uses 1 + seed to avoid multiplication by zero
    @param seed Passing sequential values of seed returns different seats
    """
    return (block.timestamp * (1 + seed)) % self.seat_count + 1


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
def user_wins(addr: address) -> DynArray[uint256, max_seat_count]:
    ret_array: DynArray[uint256, max_seat_count] = []
    for i in range(max_seat_count):
        if self.seats[i] == addr:
            ret_array.append(i)
    return ret_array


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
def user_bids(user: address) -> uint256[max_seat_count]:
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
    @return Every seat's current auction deadline
    """

    ret_arr: uint256[max_seat_count] = empty(uint256[max_seat_count])
    for i in range(max_seat_count):
        if self.seats[i] != empty(address) and self.auction_deadline[i] == 0:
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


### INTERNAL FUNCTIONS


@internal
def _auction_update(seat_id: uint256, addr: address, amount: uint256):
    self.auction_deadline[seat_id] = block.timestamp + self.auction_duration
    self.auction_bids[seat_id][addr] += amount

    _leader: address = self.auction_leaders[seat_id]
    if self.auction_bids[seat_id][addr] > self.auction_bids[seat_id][_leader]:
        self.auction_leaders[seat_id] = addr


@internal
@payable
def _auction_start(seat_id: uint256, msg_value: uint256, msg_sender: address):

    self._reserve_seat(self, seat_id)
    self._auction_update(seat_id, msg.sender, msg.value)


@external
@view
def is_seat_open_for_auction(seat_id: uint256) -> bool:
    """
    @notice See if an auction is presently biddable
    @param seat_id Index of seat to bid on
    @dev Misleading name change to is_biddable or something
    @return True if biddable
    """
    if self.auction_deadline[seat_id] > 0:  # Auction has started
        if block.timestamp < self.auction_deadline[seat_id]:
            return True
        else:
            return False

    else:  # No auction started
        if self.seats[seat_id] != empty(address):
            return False  # Seat claimed
        else:
            return True


@external
@view
def is_auction_ended(seat_id: uint256) -> bool:
    """
    @notice See if an auction is presently over
    @param seat_id Index of seat to check
    @return True if auction ended
    """
    if (
        self.auction_deadline[seat_id] > 0
        and block.timestamp >= self.auction_deadline[seat_id]
    ):
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
    assert self.is_live == True  # dev: Auction has ended
    assert (
        msg.value / self.auction_interval * self.auction_interval == msg.value
    ), "Min interval violation"
    assert seat_id not in self.no_mint_list  # dev: No Auction for this Seat

    if self.auction_deadline[seat_id] == 0:
        self._auction_start(seat_id, msg.value, msg.sender)
    else:
        assert self._auction_status(seat_id) != 2, "Auction ended"
        self._auction_update(seat_id, msg.sender, msg.value)


### MINT FUNCTIONS


@external
def generate_mint(seat_id: uint256):
    """
    @notice Mint an NFT at auction close
    @param seat_id Seat id for completed auction
    """
    assert self.seats[seat_id] != empty(address)  # dev: "Seat not assigned"
    assert seat_id not in self.seats_minted  # dev: "Seat already minted"

    target: address = empty(address)

    if self.auction_deadline[seat_id] > 0:  # Auction has started
        assert (
            self.auction_deadline[seat_id] < block.timestamp
        )  # dev: "Auction has not ended"
        target = self.auction_leaders[seat_id]
    else:
        target = self.seats[seat_id]

    self._mint(target, seat_id)
    self.seats_minted.append(seat_id)


### RANDOM BATCH FUNCTIONS


@internal
def _get_pseudorandom_seat(seed: uint256) -> uint256:
    """
    @notice Select an unfilled seat at pseudorandom
    @param seed An offset to prevent sequential numbers
    """

    # Grab a random seat_id
    # It may be filled as this fills up, so it is just a starting point

    _seat_id: uint256 = self._get_pseudorandom_number(seed)
    _offset: uint256 = 0
    _val: uint256 = 0
    _ret: uint256 = 0

    # We need to loop over a constant
    for j in range(max_seat_count):

        # If our number falls between the dynamic seat_count and the fixed max
        _offset = (_seat_id + j) / self.seat_count

        # Start with the pseudorandom draw and increment upwards
        _val = _seat_id + j - (self.seat_count * _offset)

        # Return seat if valid
        if self.seats[_val] == empty(address):
            if _val > 0 and _val not in self.no_mint_list:
                _ret = _val
                break

    if _ret == 0:
        raise  # dev: No Seat Available

    return _ret


@internal
@view
def _has_coupon(addr: address) -> bool:
    has_coupon: bool = False
    if self.used_coupon[addr] == True:
        has_coupon = False
    elif self.whitelist[addr] == True:
        has_coupon = True
    elif self.coupon_token == empty(address):
        has_coupon = False
    elif self.used_coupon[addr]:
        has_coupon = False
    elif ERC20(self.coupon_token).balanceOf(addr) > 0:
        has_coupon = True

    return has_coupon


@external
@view
def has_coupon(addr: address) -> bool:
    """
    @notice Check if the user is authorized for one free mint
    @param addr Address to check eligibility
    @return bool True if eligible for one free mint
    """
    return self._has_coupon(addr)


@internal
@view
def _batch_price(quantity: uint256, addr: address) -> uint256:
    if self._has_coupon(addr):
        return self.min_price * (quantity - 1)
    else:
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
    assert msg.value >= self._batch_price(
        quantity, msg.sender
    )  # dev: Did not pay enough
    assert quantity <= self.max_mint_batch_quantity  # dev: Mint batch capped

    for i in range(MAX_MINT_BATCH_QUANTITY):
        # End early
        if i >= quantity:
            break

        # Get Pseudorandom Number
        seat_id: uint256 = self._get_pseudorandom_seat(i)

        self._reserve_seat(msg.sender, seat_id)
        self._mint(msg.sender, seat_id)
        self.seats_minted.append(seat_id)

    if self._has_coupon(msg.sender):
        self.used_coupon[msg.sender] = True


@external
@view
def mint_batch_price(quantity: uint256, addr: address) -> uint256:
    """
    @notice Get the price needed for minting a batch
    @param quantity The target number of seats to mint
    @return Cost to mint quantity (in Wei)
    """
    return self._batch_price(quantity, addr)


### ADMIN FUNCTIONS


@external
def admin_set_nft_addr(addr: address):
    """
    @notice Point minting contract to a different NFT
    @param addr New NFT address
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    self.nft_addr = addr


@external
def admin_claim(index: uint256):
    """
    @notice Admin function to immediately claim a seat
    @param index Seat ID to claim
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    self._mint(msg.sender, index)
    self.seats_minted.append(index)


@external
def admin_nft_owner(new_owner: address):
    """
    @notice Update owner of NFT
    @param new_owner New NFT owner address
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    ERC721(self.nft_addr).set_owner(new_owner)


@external
def admin_new_owner(new_owner: address):
    """
    @notice Update owner of minter contract
    @param new_owner New contract owner address
    """
    assert msg.sender == self.owner  # dev: "Admin Only"
    self.owner = new_owner


@external
def admin_end_auction(seat_id: uint256):
    """
    @notice Admin emergency function to end auction immediately
    @param seat_id Seta to stop auction
    """
    assert msg.sender == self.owner  # dev: "Admin Only"
    self.auction_deadline[seat_id] = block.timestamp - 1


@external
def admin_withdraw(target: address, amount: uint256):
    """
    @notice Withdraw funds to admin
    @dev Can only be used if auctions have been disabled
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    assert self.is_live == False

    send(target, amount)


@external
def admin_withdraw_erc20(coin: address, target: address, amount: uint256):
    """
    @notice Withdraw ERC20 tokens accidentally sent to contract
    @param coin ERC20 address
    @param target Address to receive
    @param amount Wei
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    ERC20(coin).transfer(target, amount)


@external
def admin_set_min_price(amount: uint256):
    """
    @notice Update min price used for minting packs
    @param amount min amount in Wei
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    self.min_price = amount


@external
def admin_set_contract_status(status: bool):
    """
    @notice Disable or enable all payable functions
    @param status Boolean
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    self.is_live = status


@external
def admin_add_to_no_mint_list(seat_id: uint256):
    """
    @notice Prevent bids on a seat
    @param seat_id Seat to withhold
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    self.no_mint_list.append(seat_id)


@external
def admin_remove_from_no_mint_list(seat_id: uint256):
    """
    @notice Remove a seat from the no mint list
    @param seat_id Seat to make eligible
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    new_list: DynArray[uint256, 600] = []

    for i in self.no_mint_list:
        if i != seat_id:
            new_list.append(i)

    self.no_mint_list = new_list


@external
def admin_update_coupon_token(token: address):
    """
    @notice Holders of any ERC20 coupon token are eligible for one free random mint
    @param token Address of ERC20 token
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    self.coupon_token = token


@external
def admin_update_seat_count(seat_count: uint256):
    """
    @notice Holders of any ERC20 coupon token are eligible for one free random mint
    @param seat_count Update to this number
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    self.seat_count = seat_count


@external
def admin_add_to_whitelist(addr: address):
    """
    @notice Whitelist a specific address for one free mint
    """
    assert self.owner == msg.sender  # dev: "Admin Only"
    self.whitelist[msg.sender] = True


### AUCTION REDEMPTIONS


@internal
@view
def _redeemable_balance(acct: address) -> uint256:
    bal: uint256 = 0
    for i in range(max_seat_count):
        if self._auction_status(i) == 2 and self.auction_leaders[i] != acct:
            bal += self.auction_bids[i][acct]

    return bal - self.losers_redeemed[acct]


@external
@view
def redeemable_balance(acct: address) -> uint256:
    """
    @notice Auction runners-up may claim their balance after the auction is ended
    @param acct The address to check the current balance of.
    @return Value in Wei
    """
    return self._redeemable_balance(acct)


@external
def redeem_missing(acct: address):
    """
    @notice Retrieve outstanding funds after auction redemption
    @param acct Address for which to claim funds
    @dev Non-reentrant
    """
    claim_amt: uint256 = self._redeemable_balance(acct)
    assert claim_amt > 0  # dev: "No claim"
    self.losers_redeemed[acct] = claim_amt
    send(acct, claim_amt)