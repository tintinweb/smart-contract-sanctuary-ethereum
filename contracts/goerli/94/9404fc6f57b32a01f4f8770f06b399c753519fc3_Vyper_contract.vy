# @version 0.3.1
# @notice A contract to recover tokens from RewardsManager contract
# @license MIT

interface IRewardsManager:
    def recover_erc20(token: address, amount: uint256, recipient: address): nonpayable
    def transfer_ownership(_to: address): nonpayable

interface IERC20:
    def balanceOf(account: address) -> uint256: view

AGENT: immutable(address)

@external
def __init__(agent: address):
    AGENT = agent

@pure
@external
def agent() -> address:
    return AGENT

@external
def recover(manager: address, token: address, amount: uint256 = MAX_UINT256):
    current_balance: uint256 = IERC20(token).balanceOf(manager)
    recover_balance: uint256 = min(amount, current_balance)
    if recover_balance > 0:
        IRewardsManager(manager).recover_erc20(token, recover_balance, AGENT)

@external
def release_ownership(manager: address):
    IRewardsManager(manager).transfer_ownership(AGENT)