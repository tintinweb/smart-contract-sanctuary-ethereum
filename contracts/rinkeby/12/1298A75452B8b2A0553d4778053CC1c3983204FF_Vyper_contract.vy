# @version ^0.2
from vyper.interfaces import ERC20 
 
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256
	
struct ExactInputSingleParams:
	tokenIn: address
	tokenOut: address
	fee: uint256
	recipient: address
	deadline: uint256
	amountIn: uint256
	amountInMaximum: uint256
	sqrtPriceLimitX96: uint256
	
interface SwapRouter:
  def exactInputSingle(params: ExactInputSingleParams) -> uint256[3]: nonpayable
  
  
USDT:constant(address) = 0xB0Dfaaa92e4F3667758F2A864D50F94E8aC7a56B
UNISWAP: constant(address) = 0xe34139463bA50bD61336E0c446Bd8C0867c6fE65	
WETH: constant(address) = 0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889
DUMMY: constant(address) =  0xfe4F5145f6e09952a5ba9e956ED0C25e3Fa4c7F1
LINK: constant(address) = 0x326C977E6efc84E512bB9C30f76E30c160eD06FB

owner: public(address)
charity: public(address)
seller : public(address)
startup : public(address)
bot: public(address)
broker: public(address)

@external
def __init__(_charity: address, _seller: address,_startup: address,_broker: address,_bot: address):
	self.broker = _broker
	self.charity = _charity
	self.seller = _seller
	self.startup = _startup
	self.bot = _bot
	self.owner = msg.sender
	
@internal
def distributer():
	curamount:uint256 = ERC20(DUMMY).balanceOf(self)
	ERC20(DUMMY).approve(self, curamount)
	sendamount:uint256 = curamount*40/100
	ERC20(DUMMY).transferFrom(self, self.broker, sendamount)
	log Transfer(self, self.broker, sendamount)
	ERC20(DUMMY).transferFrom(self, self.bot, 1)
	log Transfer(self, self.bot, 1)
	curamount = curamount-sendamount - 1
	sendamount = curamount*30/100
	ERC20(DUMMY).transferFrom(self, self.charity, sendamount)
	log Transfer(self, self.charity, sendamount)
	ERC20(DUMMY).transferFrom(self, self.seller, sendamount)
	log Transfer(self, self.seller, sendamount)
	ERC20(DUMMY).transferFrom(self, self.startup, sendamount)
	log Transfer(self, self.startup, sendamount)
@external
def deposite(amountIn: uint256):
   ERC20(LINK).transferFrom(msg.sender,self, amountIn)
   
@external
def approveUniswap():
   ERC20(LINK).approve(UNISWAP,self.balance)
   
@external
def swapToDAI():
   
   amountIn: uint256 = self.balance