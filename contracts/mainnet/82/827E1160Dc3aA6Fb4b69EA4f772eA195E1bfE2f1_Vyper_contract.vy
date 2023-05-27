interface ERC20Interface:
    def transfer(recipient: address, amount: uint256) -> bool: nonpayable
    def transferFrom(sender: address, recipient: address, amount: uint256) -> bool: nonpayable
    def approve(spender: address, amount: uint256) -> bool: nonpayable
    def balanceOf(account: address) -> uint256: view

# Uniswap V2 Pair Interface
interface UniswapV2PairInterface:
    def swap(amount0Out: uint256, amount1Out: uint256, to: address, data: Bytes[32]): nonpayable

# Contract storage
weth_address: public(address)
owner: public(address)

@external
def __init__(contract_address: address):
    self.owner = msg.sender
    self.weth_address = contract_address

@external
def deposit_weth(amount: uint256) -> bool:
    assert msg.sender == self.owner
    return ERC20Interface(self.weth_address).transferFrom(msg.sender, self, amount)

@external
def approve_spender(token_address: address, spender: address, amount: uint256) -> bool:
    assert msg.sender == self.owner
    return ERC20Interface(token_address).approve(spender, amount)

@external
def swap_weth_for_tokens(pair_address: address, token0_address: address, token1_address: address, amount_weth: uint256, amount_out_min: uint256) -> bool:
    assert msg.sender == self.owner

    # Approve the pair to withdraw WETH from this contract
    assert ERC20Interface(self.weth_address).approve(pair_address, amount_weth)

    # Call the pair's swap method with the calculated minimum output amount
    if token0_address == self.weth_address:
        UniswapV2PairInterface(pair_address).swap(0, amount_out_min, self, empty(Bytes[32]))
    else:
        UniswapV2PairInterface(pair_address).swap(amount_out_min, 0, self, empty(Bytes[32]))

    return True


          
@external
def withdraw(token_address: address, amount: uint256) -> bool:
    assert msg.sender == self.owner
    return ERC20Interface(token_address).transfer(msg.sender, amount)