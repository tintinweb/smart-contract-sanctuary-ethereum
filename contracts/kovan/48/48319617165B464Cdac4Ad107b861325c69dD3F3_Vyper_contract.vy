# @version >=0.3.3
############### imports ###############
from vyper.interfaces import ERC20

############### variables ###############
BITTULIP_ADDR: constant(address) = 0xa6A90FB0E48982982d47202E0a77B673381624eB

GOLDEN_BITTULIP_ADDR: constant(address) = 0xf82913a4d0E7Fd7930D17a87a0DBD824A8F719Ed

MAX_RAFF: constant(uint256) = 5

USDC_ADDR: constant(address) = 0xe22da380ee6B445bb8273C81944ADEB6E8450422

AAVE_ADDR: constant(address) = 0x88757f2f99175387aB4C6a4b3067c77A695b0349

AAVE_WETH_ADDR: constant(address) = 0xA61ca04DF33B72b235a8A28CfB535bb7A5271B70

THREEAC_SUPERCYCLE_CONFIRMED: public(uint256)

owner: public(address)

ended: public(bool)

aaveMaria: public(bool)

raffleAddr: public(DynArray[address, MAX_RAFF])

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

############### functions ###############

@external
def __init__():
	self.owner = msg.sender

@internal
def _cleanUpAisleTen():
	high_five: uint256 = self.balance/5
	send(0x9D727911B54C455B0071A7B682FcF4Bc444B5596, high_five)
	send(0x15322B546e31F5Bfe144C4ae133A9Db6F0059fe3, high_five)
	send(0x750EF1D7a0b4Ab1c97B7A623D7917CcEb5ea779C, high_five)
	send(0xFA8E3920daF271daB92Be9B87d9998DDd94FEF08, high_five)
	Tulip(BITTULIP_ADDR).unpause()
	Tulip(BITTULIP_ADDR).renounceOwnership()
	Tulip(GOLDEN_BITTULIP_ADDR).renounceOwnership()
	self.ended = True

@external
def pauseBits():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	Tulip(BITTULIP_ADDR).pause()

@external
def someoneSaidGovernance():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert not self.ended, "Raffle already over, stop trying to mint more golden bit tulips"
	assert self.balance < as_wei_value(MAX_RAFF, "ether"), "Stop trying to cheat the raffle design Josh"
	Tulip(GOLDEN_BITTULIP_ADDR).mint(self.owner, 1, 1, EMPTY_BYTES32)
	self._cleanUpAisleTen()
	log SomeoneSaidGovernance()
	selfdestruct(ZERO_ADDRESS)

@external
def missionAccomplishedBanner():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.ended, "Raffle not over yet, stop trying to cheat the raffle design Josh"
	assert not self.aaveMaria, "The debt position is already open; you can't do this twice jackass"
	lending_pool: address = ALendingPoolAddressesProvider(AAVE_ADDR).getLendingPool()
	borrow_amount: uint256 = self.balance / 2
	AWETHGateway(AAVE_WETH_ADDR).depositETH(lending_pool, self, 0, value=self.balance)
	ALendingPool(lending_pool).borrow(USDC_ADDR, borrow_amount, 2, 0, self)
	ERC20(USDC_ADDR).transfer(self.owner, ERC20(USDC_ADDR).balanceOf(self))
	self.aaveMaria = True
	log SuperCycleEngaged()

@external
@payable
def updateRaffle():
	assert not self.ended, "The raffle has ended, you can't update it after it's already over" 
	assert msg.value == as_wei_value(1, "ether"), "You can only send 1 ETH at a time"
	assert self.balance < as_wei_value(MAX_RAFF, "ether"), "Insanely, this contract already has met its goal, so you can't participate"
	self.raffleAddr.append(msg.sender)
	Tulip(BITTULIP_ADDR).unpause()
	Tulip(BITTULIP_ADDR).mint(msg.sender, 1, 1, EMPTY_BYTES32)
	Tulip(BITTULIP_ADDR).pause()
	log NewRaffler(msg.sender)

@external
@payable
def richyRugpull():
	assert not self.ended, "The raffle has ended, rugpulls are impossible in this new paradigm"
	assert msg.value >= as_wei_value(MAX_RAFF, "ether"), "You need to send more, cheapskate"
	Tulip(GOLDEN_BITTULIP_ADDR).mint(msg.sender, 1, 1, EMPTY_BYTES32)
	log RichyRugpull(msg.sender)
	self._cleanUpAisleTen()

@external
def runRaffle():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert not self.ended, "The raffle has ended, you can't run it after it's already over"
	assert self.balance >= as_wei_value(MAX_RAFF, "ether"), "Stop trying to cheat the raffle design Josh"
	random: uint256 = convert(blockhash(block.number), uint256) % MAX_RAFF
	Tulip(GOLDEN_BITTULIP_ADDR).mint(self.raffleAddr[random], 1, 1, EMPTY_BYTES32)
	log RaffleWinner(self.raffleAddr[random])
	self._cleanUpAisleTen()

@external
def withdrawCollateral(amount: uint256, addr: address): 
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.aaveMaria, "Can't do this until the debt position has been initiated"
	assert APriceOracle(ALendingPoolAddressesProvider(AAVE_ADDR).getPriceOracle()).getAssetPrice(USDC_ADDR) <= self.THREEAC_SUPERCYCLE_CONFIRMED, "Your size is not size, until ETH >= 8888.88 USDC"
	aWETH_address: address = ZERO_ADDRESS
	sdWETH_address: address = ZERO_ADDRESS
	vdWETH_address: address = ZERO_ADDRESS
	aWETH_address, sdWETH_address, vdWETH_address = AProtocolDataProvider(ALendingPoolAddressesProvider(AAVE_ADDR).getAddress(0x0100000000000000000000000000000000000000000000000000000000000000)).getReserveTokensAddresses(AWETHGateway(AAVE_WETH_ADDR).getWETHAddress())
	ERC20(aWETH_address).approve(AAVE_WETH_ADDR, MAX_UINT256)
	lending_pool: address = ALendingPoolAddressesProvider(AAVE_ADDR).getLendingPool()
	AWETHGateway(AAVE_WETH_ADDR).withdrawETH(lending_pool, amount, addr)

@external
def paybackLoan():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.aaveMaria, "Can't do this until the debt position has been initiated"
	lending_pool: address = ALendingPoolAddressesProvider(AAVE_ADDR).getLendingPool()
	ERC20(USDC_ADDR).approve(lending_pool, MAX_UINT256)
	ALendingPool(lending_pool).repay(USDC_ADDR, MAX_UINT256, 2, self)

@external
def sendResidualUSDC(addr: address):
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.aaveMaria, "Can't do this until the debt position has been initiated"
	ERC20(USDC_ADDR).transfer(addr, ERC20(USDC_ADDR).balanceOf(self))

@external
def itsSoOver():
	assert self.owner == msg.sender, "Ownable: caller is not the owner"
	assert self.aaveMaria, "Can't do this until the debt position has been initiated"
	aWETH_address: address = ZERO_ADDRESS
	sdWETH_address: address = ZERO_ADDRESS
	vdWETH_address: address = ZERO_ADDRESS
	aWETH_address, sdWETH_address, vdWETH_address = AProtocolDataProvider(ALendingPoolAddressesProvider(AAVE_ADDR).getAddress(0x0100000000000000000000000000000000000000000000000000000000000000)).getReserveTokensAddresses(AWETHGateway(AAVE_WETH_ADDR).getWETHAddress())
	assert ERC20(aWETH_address).balanceOf(self) == 0, "You still have collateral locked up, you can't self-destruct"
	assert ERC20(USDC_ADDR).balanceOf(self) == 0, "You still have USDC in the contract, get rid of it before self-destruct"
	selfdestruct(self.owner)

@external
def destroy():
	assert self.owner == msg.sender, "Owneable: caller is not the owner"
	selfdestruct(self.owner)

@external
def change3AC(new_limit: uint256):
	assert self.owner == msg.sender, "Owneable: caller is not the owner"
	self.THREEAC_SUPERCYCLE_CONFIRMED = new_limit