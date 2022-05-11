# @version 0.3.1
# @notice A contract to recover tokens from RewardsManager contract
# @license MIT

interface IRewardsManager:
    def owner() -> address: view
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
def recover(manager: address, token: address, amount: uint256 = MAX_UINT256)-> uint256:
    recovered_amount: uint256 = 0
    is_owner: bool = IRewardsManager(manager).owner() == self
    current_balance: uint256 = IERC20(token).balanceOf(manager)
    amount_to_recover: uint256 = min(amount, current_balance)

    if is_owner and amount_to_recover > 0:
        IRewardsManager(manager).recover_erc20(token, amount_to_recover, AGENT)
        recovered_amount = amount_to_recover

    if is_owner:
        IRewardsManager(manager).transfer_ownership(AGENT)

    log Recover(msg.sender, manager, token, amount, recovered_amount)
    return recovered_amount

event Recover:
    sender: indexed(address)
    manager: indexed(address)
    token: indexed(address)
    amount: uint256
    recovered_amount: uint256