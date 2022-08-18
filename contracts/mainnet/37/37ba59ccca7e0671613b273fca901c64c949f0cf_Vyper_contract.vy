# @version 0.3.3

"""
@title PAC DAO v2 Gov Token Bridge
@notice Allows holders of PAC DAO v1 Gov Token to Upgrade 
"""

from vyper.interfaces import ERC20

interface MintableToken:
   def mint(to :address, amount: uint256): nonpayable


v1_token: public(ERC20)
gov_token: public(MintableToken)


@external
def __init__(gov_token: address, v1_token: address):
    self.v1_token = ERC20(v1_token)
    self.gov_token = ERC20(gov_token)


@external
def upgrade(to_addr: address):
    """
    @notice Upgrade from v1 to v2.  Requires approval and balance of v1 token.
    @dev Reverts without balance or approval, may be called on behalf of an address.
    @param to_addr Address to upgrade
    """

    assert self.v1_token.balanceOf(to_addr) > 0, "No balance"
    _balance: uint256 = self.v1_token.balanceOf(to_addr)
    assert self.v1_token.allowance(to_addr, self) >= _balance, "No Approval"

    self.v1_token.transferFrom(to_addr, self, self.v1_token.balanceOf(to_addr))
    self.gov_token.mint(to_addr, _balance)


@external
@nonreentrant("lock")
def withdraw_erc20(coin: address, amount: uint256):
    """
    @notice Withdraw ERC20 tokens accidentally sent to contract
    @param coin ERC-20 Token with transfer function
    @param amount Quantity of tokens to transfer
    """

    assert msg.sender == 0xf27AC88ac7e80487f21e5c2C847290b2AE5d7B8e, "Only owner"
    ERC20(coin).transfer(self.gov_token.address, amount)