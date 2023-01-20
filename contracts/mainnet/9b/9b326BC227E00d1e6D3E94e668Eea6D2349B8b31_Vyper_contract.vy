# @version 0.3.7

"""
@title 🏕️ NPC Orthodoxy Camp
@notice 🥩 Steak your NPC-er for re-education and earn worthless $THING CBDCs
@author npcers.eth

         :=+******++=-:                 
      -+*+======------=+++=:            
     %+========------------=++=.        
    %+=======------------------++:      
   *+=======--------------------:++     
  =*=======------------------------*.   
 .%========-------------------------*.  
 %+=======-------------------------:-%  
+*========--------------------------:%  
%=========--------------------------:%. 
%=========--------------------+**=--:++ 
%+========-----=*%%%=--------%%%%%+-::*:
:%========-----+%%%%%=-------=%%%%%-::+=
 -%======-------+%%%%=----=*=--+**=-::%:
  :%+====---------==----===%%=------::% 
    %+===-------------======%%=------:=+
    .%===------------=======+%%------::%
     %+==-----------=========+%%-------+
     %===------------*%%%%%%%%%%%-----%.
     %====-----------============----%: 
     *+==%+----------+%%%%%%%%%%%--=*.  
     -%==+%=---------=+=========--*=    
      +===+%+--------------------*-     
       =====*%=------------------%      
       .======*%*=------------=*+.      
         -======+*%*+--------*+         
          .-========+***+++=-.          
             .-=======:           

"""

from vyper.interfaces import ERC721
from vyper.interfaces import ERC20


#######################################################################################
# 🔌 INTERFACES                                                                       #
#######################################################################################

interface ESG_NPC:
    def balanceOf(_owner: address) -> uint256: view
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def transferFrom(_from: address, _to: address, _value: uint256) -> bool: nonpayable
    def wrap(ids: DynArray[uint256, 100]): nonpayable

interface CurrentThing:
    def balanceOf(_owner: address) -> uint256: view
    def transfer(_to: address, _value: uint256) -> bool: nonpayable
    def new_current_thing(current_thing: String[256]): nonpayable
    def current_epoch() -> uint256: view
    def mint(recipient: address, amount: uint256): nonpayable


#######################################################################################
# 💾 STATE VARIABLES                                                                  #
#######################################################################################

# 📬 Addresses
npc_nft: public(ERC721)
npc_esg: public(ESG_NPC)
thing: public(CurrentThing)
owner: public(address)

# 🥩 Steakers
steaked_nfts: public(HashMap[address, DynArray[uint256, 6000]])
steaked_coin: public(HashMap[address, uint256])
steaked_users: public(DynArray[address, 6000])

# 🏋️ Weights
period_user_start: public( HashMap[address, uint256] )  # User -> Block Height 
finalized_rewards: public( HashMap[address, uint256] )  # Settled prior periods

# 🖨 Brrr.... 
inflation_rate: public(uint256)                         # Rewards per block

# 🔪 Kill Conditions
kill_time: public(uint256)                              # Admin function delay


#######################################################################################
# 🐣 INITIALIZATION                                                                   #
#######################################################################################

@external
def __init__(npc_nft: address, npc_esg: address, thing: address):
    """
    @param npc_nft Address of NPC NFT
    @param npc_esg Address of Wrapped NPC token
    @param thing Address of $THING token
    """
    self.npc_nft = ERC721(npc_nft)
    self.npc_esg = ESG_NPC(npc_esg)
    self.npc_nft.setApprovalForAll(npc_esg, True)

    self.thing = CurrentThing(thing)
    self.inflation_rate = 1000  * 10 ** 18 / 7200 

    self.owner = msg.sender
    self.kill_time = 0


#######################################################################################
# 👀 VIEW FUNCTIONS                                                                   #
#######################################################################################

# INFORMATION

@external
@view
def current_epoch() -> uint256:
    """
    @notice Retrieve the current epoch number
    @return Epoch number
    """
    return self._current_epoch()


# USER BALANCES

@external
@view
def balance_nft(user: address) -> uint256:
    """
    @notice Check balance of NPC NFTs user has steaked
    @param user Address of user
    @return User balance
    """
    return(self._nft_balance_of(user) )


@external
@view
def balance_esg(user: address) -> uint256:
    """
    @notice Check balance of esgNPCs user has steaked
    @param user Address of user
    @return User balance
    """
    return(self.steaked_coin[user] )


@external
@view
def balanceOf(user: address) -> uint256:
    """
    @notice Retrieve total balance (NPC + esgNPC) user has steaked
    @param user Address of user
    @return Total balance
    """
    return(self._nft_balance_of(user) * 10 ** 18 + self.steaked_coin[user]) 


@external
@view
def reward_balance(user: address) -> uint256:
    """
    @notice Total rewards available to claim 
    @param user Address to check
    @return Amount of $THING available to claim
    """
    return self._reward_balance(user) 


@external
@view
def reward_uncached(user: address) -> uint256:
    """
    @notice Rewards earned this epoch, exclusive of previously cached rewards 
    @dev Mostly included for tests, may want to remove before launch
    @param user Address of user
    @return Rewards accumulated just this epoch
    """
    return self._recent_rewards(user)


# MULTIPLIERS

@external
@view
def calc_multiplier(id: uint256, epoch: uint256) -> uint256:
    """
    @notice Calculate the multiplier for a particular NPC in a given epoch
    @dev Rename to calc_nft_multplier
    @param id NFT identifier
    @param epoch Epoch number
    @return Multiplier for staking single NFT, 18 digits
    """
    return self._calc_multiplier(id, epoch)


@external
@view
def calc_avg_multiplier_nft(user: address, epoch: uint256) -> uint256:
    """
    @notice Average multiplier for a steaked user's entire NFT collection
    @dev Reverts if no balance of steaked NFTs
    @param user Staked user
    @param epoch Epoch number
    @return Multiplier, 18 digits
    """
    return self._calc_avg_multiplier(user, epoch)


@external
@view
def calc_avg_multiplier_esg(bal: uint256, epoch: uint256) -> uint256:
    """
    @notice Multiplier for depositing wrapped esgNPC
    @dev Calculated as the average multiplier for the first 10 NPC NFTs, exact units
    @param bal Balance affects the bulk bonus
    @param epoch Weight at epoch
    @return Multiplier, 18 digits
    """
    return self._calc_avg_coin_multiplier(bal, epoch)


# RATE CALCULATION

@external
@view
def bulk_bonus(quantity: uint256) -> uint256:
    """
    @notice Calculate bonus multiplier applied for staking several NPCs
    @param quantity Balance of NFTs to steak
    @return Multiplier, 18 digits
    """
    return self._bulk_bonus(quantity)


@external
@view
def current_rate_for_user(addr: address) -> uint256:
    """
    @notice Earnings per block for user
    @param addr Address to check
    @return Earnings per block
    """
    return self._curr_weight_for_user(addr) * self.inflation_rate / 10 ** 18


#######################################################################################
# 📝 STATE MODIFYING FUNCTION                                                         #
#######################################################################################

@external
def steak_npc(nft_ids: DynArray[uint256, 100]):
    """
    @notice Stake NPC NFT to earn rewards
    @param nft_ids List of NPC ids to steak
    """
    assert self.npc_nft.isApprovedForAll(msg.sender, self)
    assert self.kill_time == 0
    
    for id in nft_ids:
        self.npc_nft.transferFrom(msg.sender, self, id)
        self.steaked_nfts[msg.sender].append(id)
    
    self._add_to_steaked_users(msg.sender)
    self._store_recent_rewards(msg.sender)


@external
def steak_esg_npc(quantity: uint256):
    """
    @notice Stake esgNPC to earn rewards
    @param quantity Amount of NPC to steak
    """
    assert self.npc_esg.balanceOf(msg.sender) >= quantity 
    assert self.kill_time == 0

    # Staking minimum
    assert quantity >= 10 ** 18 

    self.npc_esg.transferFrom(msg.sender, self, quantity)
    self.steaked_coin[msg.sender] += quantity

    self._add_to_steaked_users(msg.sender)
    self._store_recent_rewards(msg.sender)


@external
def withdraw():
    """
    @notice Withdraw accrued $THING and NPCs
    """
    self._withdraw(msg.sender, msg.sender)


@external
def wrap():
    """
    @notice Wrap all steaked NPCs into esgNPCs
    """
    self._wrap_for_user(msg.sender)
    self._store_recent_rewards(msg.sender)


@external
def withdraw_wrapped():
    """
    @notice Wrap NPC to esgNPC, then withdraw all
    """
    self._wrap_for_user(msg.sender)
    self._withdraw(msg.sender, msg.sender)


@external
def withdraw_rewards():
    """
    @notice Withdraw accrued $THING rewards, but stay steaked
    """
    self._withdraw_rewards(msg.sender)



#######################################################################################
# 🔒 ADMIN FUNCTIONS                                                                  #
#######################################################################################

@external
def admin_trigger_epoch(current_thing: String[256]):
    """
    @notice Admin function to set epoch
    """
    assert msg.sender == self.owner
    self._close_epoch_rewards()
    self.thing.new_current_thing(current_thing)


@external
def admin_shutdown():
    """
    @notice Admin function to stop streaming
    """
    assert msg.sender == self.owner

    self.kill_time = block.number + 6 * 60 * 24 * 7  # Kill time kicked to future
    self.inflation_rate = 0
    self._close_epoch_rewards()


@external
def admin_set_inflation(new_rate: uint256):
    """
    @notice Admin function to stop streaming
    """
    assert msg.sender == self.owner
    self._close_epoch_rewards()
    self.inflation_rate = new_rate


@external
def admin_force_withdraw(from_user: address, to_user: address):
    """
    @notice Allow admin to force claim for user after kill
    """
    assert msg.sender == self.owner
    assert block.number > self.kill_time 

    self._withdraw(from_user, to_user)


@external
def admin_force_transfer_nft(npc_id: uint256):
    """
    @notice Admin function to claim an NFT
    """
    assert msg.sender == self.owner
    assert block.number > self.kill_time
    self.npc_nft.transferFrom(self, self.owner, npc_id)


@external
def admin_force_transfer_coin(bal: uint256):
    """
    @notice Admin function to claim an NFT
    """
    assert msg.sender == self.owner
    assert block.number > self.kill_time
    self.npc_esg.transfer(self.owner, bal)


@external
def admin_reclaim_erc20(addr: address, bal: uint256):
    """
    @notice Admin function to claim ERC20 tokens accidentally sent to contract
    """
    assert msg.sender == self.owner
    assert block.number > self.kill_time
    ERC20(addr).transfer(self.owner, bal)


@external
def admin_reclaim_erc721(addr: address, id: uint256):
    """
    @notice Admin function to claim an NFT accidentally sent to contract
    """
    assert msg.sender == self.owner
    assert block.number > self.kill_time
    ERC721(addr).transferFrom(self, self.owner, id)


@external
def admin_transfer_owner(new_owner: address):
    """
    @notice Allow admin to force claim of ERC20 tokens after contract kill cooldown
    """
    assert msg.sender == self.owner
    self.owner = new_owner 


@external
def admin_approve_operator(operator: address):
    assert msg.sender == self.owner
    assert block.number > self.kill_time
    
    self.npc_nft.setApprovalForAll(operator, True)


########################################################################################
# 🔧 INTERNAL FUNCTIONS                                                                #
########################################################################################

# 👀 VIEWS

@internal
@view
def _nft_balance_of(user: address) -> uint256:
    """
    @dev Number of unwrapped NFTs steaked by a user
    """
    return(len(self.steaked_nfts[user]))


@internal
@view
def _current_epoch() -> uint256:
    """
    @dev Each new "Current Thing" advances the epoch incrementer by 1
    """
    return self.thing.current_epoch()


# 🥩 STEAKING LOGIC

@internal
@view
def _calc_avg_multiplier(user: address, epoch: uint256) -> uint256:
    """
    @dev For user in a given epoch, calculate the average multiplier for all steaked, unwrapped NPCs, no units
    """

    # Sum up all multipliers for all NPCs
    adder: uint256 = 0
    for i in range(6000):
        if i >= len(self.steaked_nfts[user]):
            break
        adder += self._calc_multiplier(self.steaked_nfts[user][i] , epoch)
   
    # Divide by bonus for staking a higher quantity
    retval: uint256 = 0
    if self._nft_balance_of(user) > 0:
        retval = self._bulk_bonus(self._nft_balance_of(user)) * adder / self._nft_balance_of(user) 
    return retval


@internal
@view
def _calc_avg_coin_multiplier(bal: uint256, epoch: uint256) -> uint256:
    """
    @dev Return the multiplier for a quantity of steaked, wrapped ESG-NPCs
    """
    adder: uint256 = 0
    for i in range(10):
        adder += self._calc_multiplier(i, epoch) 

    # Returns sqrt 10 ** 18 == 10 ** 9, times 10 iterations
    return adder * self._bulk_bonus(bal) / 10 ** 10


@internal
@view
def _bulk_bonus(quantity: uint256) -> uint256:
    """
    @dev Bonus for staking a larger number of NPCs
    """
    return isqrt(quantity * 10 ** 18 * 10 ** 18)


@internal
@view
def _curr_weight_for_user(user: address) -> uint256:
    """
    @dev Total weight for user's wrapped and unwrapped NPCs
    """

    _nft_weight: uint256 = 0

    # Unwrapped NPCs 
    if self._nft_balance_of(user) > 0:
        _nft_weight += self._nft_balance_of(user) * self._calc_avg_multiplier(user, self._current_epoch())

    # Wrapped NPCs
    _coin_weight: uint256 = self.steaked_coin[user] * self._calc_avg_coin_multiplier(self.steaked_coin[user], self._current_epoch()) / 10 ** 18

    return _nft_weight + _coin_weight    


# 💰 REWARDS

@internal
@view
def _recent_rewards(user: address) -> uint256:
    """
    @dev Rewards accrued since user last hit a checkpoint
    """
    blocks: uint256 = block.number - self.period_user_start[user]
    return blocks * self._curr_weight_for_user(user) * self.inflation_rate  / 10 ** 18


@internal
@view
def _reward_balance(addr: address) -> uint256:
    """
    @dev Current user balance is rewards cachd at checkpoint plus uncached rewards
    """
    return self.finalized_rewards[addr] + self._recent_rewards(addr)


@internal
@view
def _calc_multiplier(id: uint256, epoch: uint256) -> uint256:
    """
    @dev Function to calculate a pseudorandom, deterministic multiplier for an NPC in any epoch, Poisson distribution
    """
    hash: bytes32 = keccak256( concat(convert(id, bytes32), convert(epoch, bytes32) ))

    ret_val: uint256 = 1
    for i in range(10):
        if convert(slice(hash,i,1), uint256) < 20:
            ret_val += 1

    return ret_val 


# 💾 STATE MODIFYING

@internal
def _withdraw(user: address, to_user: address):
    """
    @dev Withdraw all NPCs
    """
    # Withdraw NPCs
    if len(self.steaked_nfts[user]) > 0:
        nfts: DynArray[uint256, 6000] = self.steaked_nfts[user]
        for i in nfts:
            self.npc_nft.transferFrom(self, to_user, i)

    # Withdraw Wrapped NPCs
    if self.steaked_coin[user] > 0:
        self.npc_esg.transfer(to_user, self.steaked_coin[user])

    # Withdraw $THING
    self._withdraw_rewards(user)
    self._clear_staking(user)


@internal
def _wrap_for_user(user: address):
    """
    @dev Wrap user's NPC into wrapped ESG-NPCs
    """
    _bal: uint256 = 0
    for i in range(6000):
        if i >= len(self.steaked_nfts[user]):
            break
        self.npc_esg.wrap([self.steaked_nfts[user][i]])
        _bal += 10 ** 18
    self.steaked_nfts[user] = []
    self.steaked_coin[user] += _bal


@internal
def _withdraw_rewards(user: address):
    """
    @dev Close out user position
    """
    qty: uint256 = self.steaked_coin[user] + self._reward_balance(user)
    contract_balance : uint256 = self.thing.balanceOf(self)
    if qty < contract_balance:
        self.thing.transfer(user, qty)
    else:
        self.thing.mint(user, qty - contract_balance)
        self.thing.transfer(user, contract_balance)

    self.period_user_start[user] = block.number
    self.finalized_rewards[user] = 0


@internal
def _add_to_steaked_users(user: address):
    """
    @dev Add a user to the index of steaked users
    """
    if user not in self.steaked_users:
        self.steaked_users.append(user)


@internal
def _remove_from_steaked_users(user: address):
    """
    @dev Remove a user from index of steaked users
    """
    assert user != empty(address)
    assert user in self.steaked_users

    temp_array: DynArray[address, 6000] = []

    for cur_user in self.steaked_users:
        if cur_user != user:
            temp_array.append(cur_user)

    self.steaked_users = temp_array


@internal
def _store_recent_rewards(user: address):
    """
    @dev Set user checkpoint for rewards period
    """
    if self.period_user_start[user] > 0:
        self.finalized_rewards[user] += self._recent_rewards(user) 

    # Update weights
    self.period_user_start[user] = block.number


@internal
def _close_epoch_rewards():
    """
    @dev When writing a new current thing, set new checkpoints for all users (expensivo)
    """
    for i in self.steaked_users: 
        self._store_recent_rewards(i)


@internal
def _clear_staking(addr: address):
    """
    @dev Close out a user's position
    """
    self.steaked_coin[addr] = 0
    self.steaked_nfts[addr] = []
    self._remove_from_steaked_users(addr)