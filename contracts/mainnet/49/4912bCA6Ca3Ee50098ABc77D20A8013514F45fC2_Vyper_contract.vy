# @version 0.3.3

"""
@title PAC GOV Governance Token
@dev Based on brownie-mix/vyper-token
"""


from vyper.interfaces import ERC20

implements: ERC20


event Approval:
   owner: indexed(address)
   spender: indexed(address)
   value: uint256

event Transfer:
   sender: indexed(address)
   receiver: indexed(address)
   value: uint256

event NewOwner:
   owner: address

event NewMinter:
   minter: address

name: public(String[64])
symbol: public(String[32])
decimals: public(uint256)
totalSupply: public(uint256)

balances: HashMap[address, uint256]
allowances: HashMap[address, HashMap[address, uint256]]

owner: public(address)
minter: public(address)


# ERC-20 FUNCTIONS

@external
def __init__():
    self.name = "PAC DAO GOV"
    self.symbol = "PACG"
    self.decimals = 18
    self.totalSupply = 0
    self.owner = 0xf27AC88ac7e80487f21e5c2C847290b2AE5d7B8e 


@view
@external
def balanceOf(owner: address) -> uint256:
    """
    @notice Getter to check the current balance of an address
    @param owner Address to query the balance of
    @return Token balance
    """
    return self.balances[owner]


@view
@external
def allowance(owner: address, spender: address) -> uint256:
    """
    @notice Getter to check the amount of tokens that an owner allowed to a spender
    @param owner The address which owns the funds
    @param spender The address which will spend the funds
    @return The amount of tokens still available for the spender
    """
    return self.allowances[owner][spender]


@external
def approve(spender: address, amount: uint256) -> bool:
    """
    @notice Approve an address to spend the specified amount of tokens on behalf of msg.sender
    @dev Beware that changing an allowance with this method brings the risk that someone may use both the old and the new allowance by unfortunate transaction ordering. One possible solution to mitigate this race condition is to first reduce the spender's allowance to 0 and set the desired amount afterwards: https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
    @param spender The address which will spend the funds.
    @param amount The amount of tokens to be spent.
    @return Success boolean
    """
    self.allowances[msg.sender][spender] = amount
    log Approval(msg.sender, spender, amount)
    return True


@internal
def _transfer(_from: address, _to: address, _amount: uint256):
    """
    @dev Internal shared #logic for transfer and transferFrom
    """
    assert self.balances[_from] >= _amount, "Insufficient balance"
    self.balances[_from] -= _amount
    self.balances[_to] += _amount

    if _to == ZERO_ADDRESS:
        self.totalSupply -= _amount
    log Transfer(_from, _to, _amount)


@external
def transfer(to_addr: address, amount: uint256) -> bool:
    """
    @notice Transfer tokens to a specified address
    @dev Vyper does not allow underflows, so attempting to transfer more
         tokens than an account has will revert
    @param to_addr The address to transfer to
    @param amount The amount to be transferred
    @return Success boolean
    """
    self._transfer(msg.sender, to_addr, amount)
    return True


@external
def transferFrom(from_addr: address, to_addr: address, amount: uint256) -> bool:
    """
    @notice Transfer tokens from one address to another
    @dev Vyper does not allow underflows, so attempting to transfer more
         tokens than an account has will revert
    @param from_addr The address which you want to send tokens from
    @param to_addr The address which you want to transfer to
    @param amount The amount of tokens to be transferred
    @return Success boolean
    """
    assert self.allowances[from_addr][msg.sender] >= amount, "Insufficient allowance"
    self.allowances[from_addr][msg.sender] -= amount
    self._transfer(from_addr, to_addr, amount)
    return True


# MINT FUNCTIONS


@internal
def _mint(_to_addr: address, _amount: uint256):
    """
    @notice Internal Mint Function
    @dev Update mint
    @param _to_addr The address to_addr receive to_addrkens
    @param _amount Amount of to_addrkens to_addr mint
    """
    self.balances[_to_addr] += _amount
    self.totalSupply += _amount
    log Transfer(ZERO_ADDRESS, _to_addr, _amount)


@external
def mint(to_addr: address, amount: uint256):
    """
    @notice Mint Function
    @dev Mint function for accounts with minter role
    @param to_addr The address to receive tokens
    @param amount Amount of tokens to mint
    """
    assert msg.sender == self.owner or msg.sender == self.minter, "Only minters"
    if to_addr != ZERO_ADDRESS:
        self._mint(to_addr, amount)


@external
def mint_many(to_list: address[8], value_list: uint256[8]):
    """
    @notice Mint in packs of eight
    @dev Sender must have minter role, accepts batches of eight with ZERO_ADDRESS as empty
    @param to_list Up to eight addresses to receive tokens (ZERO_ADDR to skip)
    @param value_list Up to eight indexed values of tokens to mint
    """
    assert self.owner == msg.sender or msg.sender == self.minter, "Only minters"
    for i in range(8):
        if to_list[i] != ZERO_ADDRESS:
            self._mint(to_list[i], value_list[i])


# BURN FUNCTION


@external
def burn(quantity: uint256):
    """
    @notice Burn tokens
    @dev Transfer to ZERO_ADDRESS, throws if invlaid amount
    @param quantity Number of tokens to burn from sender
    """
    self._transfer(msg.sender, ZERO_ADDRESS, quantity)


# ADMIN FUNCTIONS


@external
def transfer_owner(new_owner: address):
    """
    @notice Set contract owner
    @dev Sender must be current owner
    @param new_owner New contract owner address
    """
    assert self.owner == msg.sender, "Only owner"
    self.owner = new_owner
    log NewOwner(new_owner)



@external
def update_minter(new_minter: address):
    """
    @notice Update minter contract address
    @dev Only one address can serve as minter
    @param new_minter New address to receive minting privilege
    """
    assert self.owner == msg.sender, "Only owner"
    self.minter = new_minter
    log NewMinter(new_minter)


@external
@nonreentrant("lock")
def claim_erc20(token_addr: address):
    """
    @notice Deliver any deposited ERC20 to owner
    @param token_addr Address of ERC20 token to claim
    """
    assert msg.sender == self.owner, "Only owner"
    ERC20(token_addr).transfer(self.owner, ERC20(token_addr).balanceOf(self))