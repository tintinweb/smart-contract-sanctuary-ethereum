# @version >=0.3.4
"""
@title The Bitbanter Raffle
@dev A contract to run a raffle to win a book I haven't yet written (or to allow some rich jerk to rugpull everyone else).
@dev No matter what, a portion of the proceeds goes to good people doing good work, and everyone who participated gets what will surely be a priceless, pixelated tulip NFT.
@dev If the raffle doesn't meet its arbitrary goal, the rest of the ETH is burned.
@dev If the raffle does meet its arbitrary goal (or some rich jerk rugpulls), someone receives a golden, pixelated tulip NFT, and the book will be encrypted against the public key of whoever holds it in 4 years time.
@dev Otherwise, rather than burning the ETH, the contract posts the rest of the ETH as collateral, borrows debt to pay my income taxes, then only allows me to withdraw the collateral if (and only if) ETH supercycles, 3AC-style. (1 ETH >= 8888.888888 USDC)
@dev This is an insane contract.
@author Josh Cincinnati (github: @acityinohio, website: https://www.bitbanter.com/)
"""
############### imports ###############
from vyper.interfaces import ERC20

############### variables ###############
# Bittulip Contract Address
BITTULIP_ADDR: constant(address) = 0x9Fd28D5610aD39bec5B273C4eEFF3C40e6Eed720

# Golden Bittulip Contract Address
GOLDEN_BITTULIP_ADDR: constant(address) = 0xA7C5Ec902E5293e22539682E4258bffe60E7A02C

# Maximum number of participants/how much it costs (in ETH) to rugpull everyone
MAX_RAFF: constant(uint256) = 42069

# USDC Contract Address
USDC_ADDR: constant(address) = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48

# Aave Lending Pool Address Provider Address
AAVE_ADDR: constant(address) = 0xB53C1a33016B2DC2fF3653530bfF1848a515c8c5

# Aave WETH Gateway Address
AAVE_WETH_ADDR: constant(address) = 0xcc9a0B7c43DC2a5F023Bb9b738E45B0Ef6B06E04

# The threshold whereby withdrawing collateral is allowed
# Aka when 1 ETH >= 8888.888888 USDC,
# Aka when 1 USDC <= 112500000000000 wei
THREEAC_SUPERCYCLE_CONFIRMED: constant(uint256) = 112500000000000

# the contract owner
owner: public(address)

# the block height for generating raffle randomness
blockRaff: public(uint256)

# whether the raffle has ended (defaults to false)
ended: public(bool)

# if the raffle succeeds,
# whether we're indebted to the faceless smart contract gods
aaveMaria: public(bool)

# participating rafflers stored in an array, MAX_RAFF-able
# if they participate multiple times, appended to array
raffleAddr: DynArray[address, MAX_RAFF]

############### events ###############
# when someone says governance and we nuke everything, as a treat
event SomeoneSaidGovernance: pass

# someone added their address to the raffle!
event NewRaffler:
	raffler: address

# someonne won the raffle! get ready to be disappointed in 4 years
event RaffleWinner:
	winner: address

# some rich person short-circuited the raffle! get ready to be _expensively_ disappointed in 4 years
event RichyRugpull:
	fatCat: address

# SuperCycle mode (aka take on pointless debt)...engaged
event SuperCycleEngaged: pass

############### interfaces ###############
# for the ERC-1155 tulips
# subset of methods
interface Tulip:
	def pause(): nonpayable
	def unpause(): nonpayable
	def paused() -> bool: view
	def renounceOwnership(): nonpayable
	def mint(receiver: address, id: uint256, amount: uint256, data: bytes32): nonpayable

# To point to the right price oracle, Aave lending pool, and Aave protocol data provider
# Note: use id = 0x0100000000000000000000000000000000000000000000000000000000000000 for "protocol data provider"
interface ALendingPoolAddressesProvider:
	def getLendingPool() -> address: view
	def getPriceOracle() -> address: view
	def getAddress(id: bytes32) -> address: view

# To get the all-important wei price of USDC
interface APriceOracle:
	def getAssetPrice(_asset: address) -> uint256: view

# To deposit and withdraw ETH collateral on Aave
# And get the WETH address used by Aave
interface AWETHGateway:
	def depositETH(lendingPool: address, onBehalfOf: address, referralCode: uint16): payable
	def withdrawETH(lendingPool: address, amount: uint256, to: address): nonpayable
	def getWETHAddress() -> address: view

# To set collateral, borrow, and repay Aave
interface ALendingPool:
	def borrow(asset: address, amount: uint256, interestRateMode: uint256, referralCode: uint16, onBehalfOf: address): nonpayable
	def repay(asset: address, amount: uint256, rateMode: uint256, onBehalfOf: address): nonpayable

# Aave protocol data provider, to get address for WETH aToken (needed for EIP-20 approval)
# First address is aTokenAddress, second is stableDebtTokenAddress, third is variableDebtTokenAddress
interface AProtocolDataProvider:
	def getReserveTokensAddresses(asset: address) -> (address, address, address): view

############### init and internal functions ###############

@external
def __init__():
	"""
	@dev contract initialization on deployment
	@dev set sender as owner
	"""
	self.owner = msg.sender

## mop up, we're done with the raffle
@internal
def _cleanUpAisleTen():
	"""
	@dev unpauses the nfts, disowns them
	@dev (with a little something something for good people)
	"""
	# good people doing good work deserve good things
	# look at us, funding good things non-quadratically
	high_five: uint256 = self.balance/8
	# zachxbt
	send(0x9D727911B54C455B0071A7B682FcF4Bc444B5596, high_five)
	# coin center
	send(0x15322B546e31F5Bfe144C4ae133A9Db6F0059fe3, high_five)
	# give directly
	send(0x750EF1D7a0b4Ab1c97B7A623D7917CcEb5ea779C, high_five)
	# internet archive
	send(0xFA8E3920daF271daB92Be9B87d9998DDd94FEF08, high_five)
	# unpause bit tulips, if paused
	if Tulip(BITTULIP_ADDR).paused():
		Tulip(BITTULIP_ADDR).unpause()
	# unown
	Tulip(BITTULIP_ADDR).renounceOwnership()
	Tulip(GOLDEN_BITTULIP_ADDR).renounceOwnership()
	# end raffle
	self.ended = True


############### raffle functions ###############

## someone said governance...or I got bored.
## anyway burn this place (and its ETH) to the ground.
## it's over. it's so over.
@external
def someoneSaidGovernance():
	"""
	@dev I'm so done. Keep your tulips, and I'll keep mine. Let (my) ETH burn.
	@dev Unpauses the ERC-1155s, mints the golden tulip to me if the raffle hasn't happened and the goal hasn't been reached.
	@dev Revokes ownership to make them fully dEcEnTrAlIzEd, self-destructs this contract.
	"""
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert not self.ended, "Raffle already over, stop trying to mint more golden bit tulips"
	assert self.balance < as_wei_value(MAX_RAFF, "ether"), "Stop trying to cheat the raffle design Josh"
	# mint golden tulip to me
	Tulip(GOLDEN_BITTULIP_ADDR).mint(self.owner, 1, 1, empty(bytes32))
	# clean up the raffle
	self._cleanUpAisleTen()
	# log it
	log SomeoneSaidGovernance()
	# send it (my eth) to ZERO
	selfdestruct(empty(address))

## or the raffle or richy rugpull ended successfully, it's time for a supercycle
@external
def missionAccomplishedBanner(addr: address):
	"""
	@dev run after the raffle is over, or someone richy rugpulled
	@dev If this contract manages to get >=MAX_RAFF ETH, then yes, we are probably at the beginning of a pre-blowup, 3AC-approved supercycle.
	@dev That means we use the power of Smart Contracts to pay taxes through leverage instead of selling the principal.
	@dev Up Only, WAGMI Frens, Yadda Yadda Yadda.
	@param addr Address to send the USDC loan, hopefully where I can convert it to actual dollars ASAP because lord will I have taxes to pay.
	"""
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.ended, "Raffle not over yet, stop trying to cheat the raffle design Josh"
	assert not self.aaveMaria, "The debt position is already open; you can't do this twice jackass"
	# get the lending pool address
	lending_pool: address = ALendingPoolAddressesProvider(AAVE_ADDR).getLendingPool()
	# set borrow amount at 50% of balance -- price oracle works in dollars but USDC has six decimals so that's why the math is weird
	borrow_amount: uint256 = (self.balance * 10**6 / 2) / (APriceOracle(ALendingPoolAddressesProvider(AAVE_ADDR).getPriceOracle()).getAssetPrice(USDC_ADDR))
	# deposit ETH into contract using WETH Gateway
	AWETHGateway(AAVE_WETH_ADDR).depositETH(lending_pool, self, 0, value=self.balance)
	# borrow 50% of the deposited ETH in USDC, variable interest baby YOLO
	ALendingPool(lending_pool).borrow(USDC_ADDR, borrow_amount, 2, 0, self)
	# send USDC to addr
	ERC20(USDC_ADDR).transfer(addr, ERC20(USDC_ADDR).balanceOf(self))
	# set aaveMaria to true
	self.aaveMaria = True
	# log it
	log SuperCycleEngaged()

## add your lucky address to the lucky list
## are you feeling lucky? ...you shouldn't tbh
@external
@payable
def updateRaffle():
	"""
	@dev If it doesn't already exist, adds sender's address to the raffle list, alongside the weight of their contribution.
	@dev User allowed to contribute more in successive transactions if they want (why they would I have no idea).
	@dev Must only send 1 ETH, raffle must not have ended, and we must have raised less than MAX_RAFF ETH
	"""
	assert not self.ended, "The raffle has ended, you can't update it after it's already over" 
	assert msg.value == as_wei_value(1, "ether"), "You can only send 1 ETH at a time"
	assert self.balance <= as_wei_value(MAX_RAFF, "ether"), "Insanely, this contract already has met its goal, so you can't participate"
	## it's time to update
	self.raffleAddr.append(msg.sender)
	# unpause bit tulips (check to see if paused first)
	if Tulip(BITTULIP_ADDR).paused():
		Tulip(BITTULIP_ADDR).unpause()
	# mint their tulip
	Tulip(BITTULIP_ADDR).mint(msg.sender, 1, 1, empty(bytes32))
	# pause bit tulips
	Tulip(BITTULIP_ADDR).pause()
	# log the new raffler
	log NewRaffler(msg.sender)

## oh look at you big shot
## you want the golden tulip? fine
@external
@payable
def richyRugpull():
	"""
	@dev When a whale wants to buy your book at the market-clearing price, you let them.
	@dev But hey, if they rugpull you, look on the bright side:
	@dev ...at least you got a tulip NFT out of it?
	"""
	assert not self.ended, "The raffle has ended, rugpulls are impossible in this new paradigm"
	assert msg.value >= as_wei_value(MAX_RAFF, "ether"), "You need to send more, cheapskate"
	# they're the totally fair winner, based on equal parts skill and luck!
	# mint the golden tulip and end the raffle
	Tulip(GOLDEN_BITTULIP_ADDR).mint(msg.sender, 1, 1, empty(bytes32))
	# log the richy rugpull
	log RichyRugpull(msg.sender)
	# clean up the raffle
	self._cleanUpAisleTen()

## or if we met the goal, give 'em that raffle-dazzle
## first need to set block height for the randomness source
@external
def setBlockRaff():
	"""
	@dev sets the block height to use as anchor for quote-unqoute randomness
	@dev this is far from perfect but whatever this is all a joke anyway
	"""
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert not self.ended, "The raffle has ended, you can't run it after it's already over"
	assert self.blockRaff == 0, "can't set blockRaff twice"
	assert self.balance >= as_wei_value(MAX_RAFF, "ether"), "Stop trying to cheat the raffle design Josh"
	# locks randomness source to current block number + 100
	self.blockRaff = block.number + 100

## then we run the raffle
@external
def runRaffle():
	"""
	@dev time to run this very well designed random raffle that can't possibly be cheated
	"""
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert not self.ended, "The raffle has ended, you can't run it after it's already over"
	assert self.balance >= as_wei_value(MAX_RAFF, "ether"), "Stop trying to cheat the raffle design Josh"
	assert self.blockRaff > 0, "blockRaff must be initialized"
	assert block.number > self.blockRaff, "Current block must be higher than blockRaff"
	## source randomness from 100 block hashes trailing blockRaff
	## yeah I know, this isn't robust, there are many things wrong with this, a miner could be bribed etc
	## but I refuse to pay for the chainlink VRF
	## furthermore I'm not convinced the chainlink randomness isn't just Sergey flipping a coin 
	## anyway this will select a number from 0 inclusive to MAX_RAFF-1
	source: uint256 = convert(blockhash(self.blockRaff - 1), uint256)
	for i in range(2, 100):
		source = source ^ convert(blockhash(self.blockRaff - i), uint256)
	random: uint256 = source % MAX_RAFF
	## since the raffleAddrs are in an array up to length MAX_RAFF, we simply mint the golden tulip to the winner and end the raffle
	Tulip(GOLDEN_BITTULIP_ADDR).mint(self.raffleAddr[random], 1, 1, empty(bytes32))
	# log the winner!
	log RaffleWinner(self.raffleAddr[random])
	# clean up the raffle
	self._cleanUpAisleTen()

############### AAVE functions ###############

@external
def withdrawCollateral(amount: uint256, addr: address): 
	"""
	@dev Allows contract to withdraw collateral to itself.
	@dev But only if we have reached,,,the True Supercycle (price oracle says 1 ETH >= 8888.88 USDC).
	@param amount Amount to withdraw in wei, use max_value(uint256) to withdraw everything.
	@param addr Address to send the collateral.
	"""
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.aaveMaria, "Can't do this until the debt position has been initiated"
	assert APriceOracle(ALendingPoolAddressesProvider(AAVE_ADDR).getPriceOracle()).getAssetPrice(USDC_ADDR) <= THREEAC_SUPERCYCLE_CONFIRMED, "Your size is not size, until ETH >= 8888.88 USDC"
	# gnarly four-liner to get the aWETH address
	aWETH_address: address = empty(address)
	sdWETH_address: address = empty(address)
	vdWETH_address: address = empty(address)
	aWETH_address, sdWETH_address, vdWETH_address = AProtocolDataProvider(ALendingPoolAddressesProvider(AAVE_ADDR).getAddress(0x0100000000000000000000000000000000000000000000000000000000000000)).getReserveTokensAddresses(AWETHGateway(AAVE_WETH_ADDR).getWETHAddress())
	# approve sends of aWETH by AWETHGateway, so it can burn as many aWETH tokens as it likes
	ERC20(aWETH_address).approve(AAVE_WETH_ADDR, max_value(uint256))
	# withdraws amount-in-wei collateral to contract	
	lending_pool: address = ALendingPoolAddressesProvider(AAVE_ADDR).getLendingPool()
	AWETHGateway(AAVE_WETH_ADDR).withdrawETH(lending_pool, amount, addr)

@external
def paybackLoan():
	"""
	@dev Pays back loan completely.
	@dev Possible to do this at any time, but uh, good luck doing this without withdrawing your supercycle-locked collateral.
	"""
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.aaveMaria, "Can't do this until the debt position has been initiated"
	# note: doesn't assert you have enough USDC to pay back in full; that's on you man
	# get lending pool address
	lending_pool: address = ALendingPoolAddressesProvider(AAVE_ADDR).getLendingPool()
	# set ERC20 USDC approval for lending pool address (so it can send)
	ERC20(USDC_ADDR).approve(lending_pool, max_value(uint256))
	# send max_value(uint256) to repay it all, in one crazy trade
	ALendingPool(lending_pool).repay(USDC_ADDR, max_value(uint256), 2, self)
	# should burn debt token (no approval/allowance needed)

@external
def sendResidualUSDC(addr: address):
	"""
	@dev Sends leftover USDC back to address specified by owner.
	@dev Intended to be called after paying back loan.
	@param addr Address to send said USDC.
	"""
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.aaveMaria, "Can't do this until the debt position has been initiated"
	# sends current balance of USDC back to addr
	ERC20(USDC_ADDR).transfer(addr, ERC20(USDC_ADDR).balanceOf(self))

@external
def itsSoOver():
	"""
	@dev Finally, destroy the contract.
	@dev No collateral. No debt. No ETH. Return to nothing.
	"""
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.aaveMaria, "Can't do this until the debt position has been initiated"
	# gnarly four-liner to get the aWETH address
	aWETH_address: address = empty(address)
	sdWETH_address: address = empty(address)
	vdWETH_address: address = empty(address)
	aWETH_address, sdWETH_address, vdWETH_address = AProtocolDataProvider(ALendingPoolAddressesProvider(AAVE_ADDR).getAddress(0x0100000000000000000000000000000000000000000000000000000000000000)).getReserveTokensAddresses(AWETHGateway(AAVE_WETH_ADDR).getWETHAddress())
	assert ERC20(aWETH_address).balanceOf(self) == 0, "You still have collateral locked up, you can't self-destruct"
	assert ERC20(USDC_ADDR).balanceOf(self) == 0, "You still have USDC in the contract, get rid of it before self-destruct"
	# self destructs, any leftover ETH (should be 0 though?) sent to owner
	selfdestruct(self.owner)