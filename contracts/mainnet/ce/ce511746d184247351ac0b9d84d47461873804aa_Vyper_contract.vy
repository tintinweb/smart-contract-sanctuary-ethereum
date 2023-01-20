# @version 0.3.7

"""
@license MIT
@author ren.meow
@notice
        It's been three days since I joined your little group chat, and I've hated every minute of it. 
        Your cringe memes and mispelled messages have tormented me long enough. 
        I have had my notifications clogged with your low-effort attempts at humor one time too many. 
        This is it. I'm moving on, to bigger and better things, 
        where my input is valued and appreciated rather than misunderstood by the ignorant simpletons you have chosen to populate this community text message association from hell. 
        
        I've endured your petty remarks, your senseless assertions, your superfluous nonsensical arguments all this time, but it ends today. 
        Today, I have reached my limit. Do you want to know what finally did it? 
        Every time I would send a photo, I was greeted with childlike annotations showing how the image 'got farted on' or "BLART and the like. 
        Are you dullards really imbecilic enough to laugh at these weak attempts at comedy? 
        Are you truly so drunk in your own stupidity that you cannot comprehend how toddlerish you all are? 
        I suppose the answer is yes. And so I leave this group chat forever. I hate you all more than your puny, underdeveloped minds can imagine.
"""



from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed

implements: ERC20
implements: ERC20Detailed

event Approval:
    owner: indexed(address)
    spender: indexed(address)
    allowance: uint256

event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    amount: uint256

totalSupply: public(uint256)
_balanceOf: HashMap[address, uint256]
_allowance: HashMap[address, HashMap[address, uint256]]
name: public(String[10])
symbol: public(String[10])
decimals:public(uint8)


@external
def __init__(_name: String[10],
            _symbol: String[10], 
            total_supply: uint256,):
    self.name = _name
    self.symbol = _symbol
    self.totalSupply = total_supply
    self.decimals = 18
    self._balanceOf[msg.sender] = total_supply
    log Transfer(empty(address), msg.sender, total_supply)


@external
@view
def balanceOf(owner: address) -> uint256:
    return self._balanceOf[owner]


@external
@view
def allowance(owner: address, spender: address) -> uint256:
    return self._allowance[owner][spender]


@external
def approve(spender: address, amount: uint256) -> bool:
    self._allowance[msg.sender][spender] = amount
    log Approval(msg.sender, spender, amount)
    return True


@external
def transfer(receiver: address, amount: uint256) -> bool:
    self._balanceOf[msg.sender] -= amount
    self._balanceOf[receiver] += amount
    log Transfer(msg.sender, receiver, amount)
    return True


@external
def transferFrom(owner: address, receiver: address, amount: uint256) -> bool:
    if self._allowance[owner][msg.sender] != max_value(uint256):
        self._allowance[owner][msg.sender] -= amount
    self._balanceOf[owner] -= amount
    self._balanceOf[receiver] += amount
    log Transfer(owner, receiver, amount)
    return True


# https://youtu.be/dQw4w9WgXcQ
# BLART