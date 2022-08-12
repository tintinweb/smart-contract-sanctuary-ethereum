# @version >=0.3.4
#
############### imports ###############
from vyper.interfaces import ERC20

############### variables ###############
BITTULIP_ADDR: constant(address) = 0x011D81D0EddB6e0181A06F497da2566E3a4ec8E4

GOLDEN_BITTULIP_ADDR: constant(address) = 0x9a99cd6C169e7b69C15EeEFD2BFf6B96afAae1a2 

MAX_RAFF: constant(uint256) = 3

USDC_ADDR: constant(address) = 0xe22da380ee6B445bb8273C81944ADEB6E8450422

AAVE_ADDR: constant(address) = 0x88757f2f99175387aB4C6a4b3067c77A695b0349

AAVE_WETH_ADDR: constant(address) = 0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70

THREEAC_SUPERCYCLE_CONFIRMED: constant(uint256) = 1000000000000000

owner: public(address)
blockRaff: public(uint256)
ended: public(bool)
aaveMaria: public(bool)

raffleAddr: DynArray[address, MAX_RAFF]

############### events ###############
event SomeoneSaidGovernance: pass

event NewRaffler:
	raffler: address

event RaffleWinner:
	winner: address

event RichyRugpull:
	fatCat: address

event SuperCycleEngaged: pass

############### interfaces ###############
interface Tulip:
	def pause(): nonpayable
	def unpause(): nonpayable
	def paused() -> bool: view
	def renounceOwnership(): nonpayable
	def mint(receiver: address, id: uint256, amount: uint256, data: bytes32): nonpayable

interface ALendingPoolAddressesProvider:
	def getLendingPool() -> address: view
	def getPriceOracle() -> address: view
	def getAddress(id: bytes32) -> address: view

interface APriceOracle:
	def getAssetPrice(_asset: address) -> uint256: view

interface AWETHGateway:
	def depositETH(lendingPool: address, onBehalfOf: address, referralCode: uint16): payable
	def withdrawETH(lendingPool: address, amount: uint256, to: address): nonpayable
	def getWETHAddress() -> address: view

interface ALendingPool:
	def borrow(asset: address, amount: uint256, interestRateMode: uint256, referralCode: uint16, onBehalfOf: address): nonpayable
	def repay(asset: address, amount: uint256, rateMode: uint256, onBehalfOf: address): nonpayable

interface AProtocolDataProvider:
	def getReserveTokensAddresses(asset: address) -> (address, address, address): view

############### init and internal functions ###############

@external
def __init__():
	self.owner = msg.sender

@internal
def _cleanUpAisleTen():
	high_five: uint256 = self.balance/8
	send(0x9D727911B54C455B0071A7B682FcF4Bc444B5596, high_five)
	send(0x15322B546e31F5Bfe144C4ae133A9Db6F0059fe3, high_five)
	send(0x750EF1D7a0b4Ab1c97B7A623D7917CcEb5ea779C, high_five)
	send(0xFA8E3920daF271daB92Be9B87d9998DDd94FEF08, high_five)
	if Tulip(BITTULIP_ADDR).paused():
		Tulip(BITTULIP_ADDR).unpause()
	Tulip(BITTULIP_ADDR).renounceOwnership()
	Tulip(GOLDEN_BITTULIP_ADDR).renounceOwnership()
	self.ended = True


############### raffle functions ###############

@external
def someoneSaidGovernance():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert not self.ended, "Raffle already over, stop trying to mint more golden bit tulips"
	assert self.balance < as_wei_value(MAX_RAFF, "ether"), "Stop trying to cheat the raffle design Josh"
	Tulip(GOLDEN_BITTULIP_ADDR).mint(self.owner, 1, 1, empty(bytes32))
	self._cleanUpAisleTen()
	log SomeoneSaidGovernance()
	selfdestruct(empty(address))

@external
def missionAccomplishedBanner(addr: address):
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.ended, "Raffle not over yet, stop trying to cheat the raffle design Josh"
	assert not self.aaveMaria, "The debt position is already open; you can't do this twice jackass"
	lending_pool: address = ALendingPoolAddressesProvider(AAVE_ADDR).getLendingPool()
	borrow_amount: uint256 = (self.balance * 10**6 / 2) / (APriceOracle(ALendingPoolAddressesProvider(AAVE_ADDR).getPriceOracle()).getAssetPrice(USDC_ADDR))
	AWETHGateway(AAVE_WETH_ADDR).depositETH(lending_pool, self, 0, value=self.balance)
	ALendingPool(lending_pool).borrow(USDC_ADDR, borrow_amount, 2, 0, self)
	ERC20(USDC_ADDR).transfer(addr, ERC20(USDC_ADDR).balanceOf(self))
	self.aaveMaria = True
	log SuperCycleEngaged()

@external
@payable
def updateRaffle():
	assert not self.ended, "The raffle has ended, you can't update it after it's already over" 
	assert msg.value == as_wei_value(1, "ether"), "You can only send 1 ETH at a time"
	assert self.balance <= as_wei_value(MAX_RAFF, "ether"), "Insanely, this contract already has met its goal, so you can't participate"
	self.raffleAddr.append(msg.sender)
	if Tulip(BITTULIP_ADDR).paused():
		Tulip(BITTULIP_ADDR).unpause()
	Tulip(BITTULIP_ADDR).mint(msg.sender, 1, 1, empty(bytes32))
	Tulip(BITTULIP_ADDR).pause()
	log NewRaffler(msg.sender)

@external
@payable
def richyRugpull():
	assert not self.ended, "The raffle has ended, rugpulls are impossible in this new paradigm"
	assert msg.value >= as_wei_value(MAX_RAFF, "ether"), "You need to send more, cheapskate"
	Tulip(GOLDEN_BITTULIP_ADDR).mint(msg.sender, 1, 1, empty(bytes32))
	log RichyRugpull(msg.sender)
	self._cleanUpAisleTen()

@external
def setBlockRaff():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert not self.ended, "The raffle has ended, you can't run it after it's already over"
	assert self.blockRaff == 0, "can't set blockRaff twice"
	assert self.balance >= as_wei_value(MAX_RAFF, "ether"), "Stop trying to cheat the raffle design Josh"
	self.blockRaff = block.number + 100

@external
def runRaffle():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert not self.ended, "The raffle has ended, you can't run it after it's already over"
	assert self.balance >= as_wei_value(MAX_RAFF, "ether"), "Stop trying to cheat the raffle design Josh"
	assert self.blockRaff > 0, "blockRaff must be initialized"
	assert block.number > self.blockRaff, "Current block must be higher than blockRaff"
	source: uint256 = convert(blockhash(self.blockRaff - 1), uint256)
	for i in range(2, 100):
		source = source ^ convert(blockhash(self.blockRaff - i), uint256)
	random: uint256 = source % MAX_RAFF
	Tulip(GOLDEN_BITTULIP_ADDR).mint(self.raffleAddr[random], 1, 1, empty(bytes32))
	log RaffleWinner(self.raffleAddr[random])
	self._cleanUpAisleTen()

############### AAVE functions ###############

@external
def withdrawCollateral(amount: uint256, addr: address): 
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.aaveMaria, "Can't do this until the debt position has been initiated"
	assert APriceOracle(ALendingPoolAddressesProvider(AAVE_ADDR).getPriceOracle()).getAssetPrice(USDC_ADDR) <= THREEAC_SUPERCYCLE_CONFIRMED, "Your size is not size, until ETH >= 8888.88 USDC"
	aWETH_address: address = empty(address)
	sdWETH_address: address = empty(address)
	vdWETH_address: address = empty(address)
	aWETH_address, sdWETH_address, vdWETH_address = AProtocolDataProvider(ALendingPoolAddressesProvider(AAVE_ADDR).getAddress(0x0100000000000000000000000000000000000000000000000000000000000000)).getReserveTokensAddresses(AWETHGateway(AAVE_WETH_ADDR).getWETHAddress())
	ERC20(aWETH_address).approve(AAVE_WETH_ADDR, max_value(uint256))
	lending_pool: address = ALendingPoolAddressesProvider(AAVE_ADDR).getLendingPool()
	AWETHGateway(AAVE_WETH_ADDR).withdrawETH(lending_pool, amount, addr)

@external
def paybackLoan():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.aaveMaria, "Can't do this until the debt position has been initiated"
	lending_pool: address = ALendingPoolAddressesProvider(AAVE_ADDR).getLendingPool()
	ERC20(USDC_ADDR).approve(lending_pool, max_value(uint256))
	ALendingPool(lending_pool).repay(USDC_ADDR, max_value(uint256), 2, self)

@external
def sendResidualUSDC(addr: address):
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.aaveMaria, "Can't do this until the debt position has been initiated"
	ERC20(USDC_ADDR).transfer(addr, ERC20(USDC_ADDR).balanceOf(self))

@external
def itsSoOver():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.aaveMaria, "Can't do this until the debt position has been initiated"
	aWETH_address: address = empty(address)
	sdWETH_address: address = empty(address)
	vdWETH_address: address = empty(address)
	aWETH_address, sdWETH_address, vdWETH_address = AProtocolDataProvider(ALendingPoolAddressesProvider(AAVE_ADDR).getAddress(0x0100000000000000000000000000000000000000000000000000000000000000)).getReserveTokensAddresses(AWETHGateway(AAVE_WETH_ADDR).getWETHAddress())
	assert ERC20(aWETH_address).balanceOf(self) == 0, "You still have collateral locked up, you can't self-destruct"
	assert ERC20(USDC_ADDR).balanceOf(self) == 0, "You still have USDC in the contract, get rid of it before self-destruct"
	selfdestruct(self.owner)

####### testnet self-destruct ########
@external
def destroy():
	"""
	@dev just to use while testing
	"""
	assert self.owner == msg.sender, "Owneable: caller is not the owner"
	selfdestruct(self.owner)