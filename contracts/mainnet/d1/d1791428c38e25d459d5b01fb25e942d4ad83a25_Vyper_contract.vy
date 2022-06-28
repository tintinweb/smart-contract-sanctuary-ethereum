# @version ^0.3.3

interface Vault():
    def deposit(amount: uint256, recipient: address) -> uint256: nonpayable
    def withdraw(maxShares: uint256, recipient: address, max_loss: uint256) -> uint256: nonpayable
    def transferFrom(_from : address, _to : address, _value : uint256) -> bool: nonpayable
    def transfer(_to : address, _value : uint256) -> bool: nonpayable
    def token() -> address: nonpayable
    def balanceOf(owner: address) -> uint256: view

interface WEth(ERC20):
    def deposit(): payable
    def approve(_spender : address, _value : uint256) -> bool: nonpayable
    def withdraw(amount: uint256): nonpayable

VAULT: immutable(Vault)
WETH: immutable(WEth)
started_withdraw: bool

@external
def __init__(vault: address):
    weth: address = Vault(vault).token()
    VAULT = Vault(vault)
    WETH = WEth(weth)
    WEth(weth).approve(vault, MAX_UINT256)
    self.started_withdraw = False

@internal
def _deposit(sender: address, amount: uint256):
    assert amount != 0 #dev: "!value"
    WETH.deposit(value= amount)
    VAULT.deposit(amount, sender)

@external
@payable
def deposit():
    self._deposit(msg.sender, msg.value)

@external
@nonpayable
def withdraw(amount: uint256, max_loss: uint256 = 1):
    self.started_withdraw = True
    VAULT.transferFrom(msg.sender, self, amount)
    weth_amount: uint256 = VAULT.withdraw(amount, self, max_loss)
    assert amount != 0 #dev: "!amount"
    WETH.withdraw(weth_amount)
    send(msg.sender, weth_amount)
    left_over: uint256 = VAULT.balanceOf(self)
    if left_over > 0:
        VAULT.transfer(msg.sender, left_over)
    self.started_withdraw = False

@external
@payable
def __default__():
    if self.started_withdraw == False:
        self._deposit(msg.sender, msg.value)