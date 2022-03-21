# https://github.com/ilovejs/uniswap-v1-mz

from vyper.interfaces import ERC20

interface Factory:
    def getExchange(token_addr: address) -> address: view

interface Exchange:
    # TODO: check wei
    def getEthToTokenOutputPrice(tokens_bought: uint256) -> uint256: view

    # external
    # old timestamp migrate to uint256
    def ethToTokenTransferInput(min_tokens: uint256, deadline: uint256, recipient: address) -> uint256: payable

    # TODO: check return in wei
    def ethToTokenTransferOutput(tokens_bought: uint256, deadline: uint256, recipient: address) -> uint256: payable

event TokenPurchase:
    buyer: indexed(address)
    eth_sold: indexed(uint256) # wei
    tokens_bought: indexed(uint256)

event EthPurchase:
    buyer: indexed(address)
    tokens_sold: indexed(uint256)
    eth_bought: indexed(uint256) # wei

event AddLiquidity:
    provider: indexed(address)
    eth_amount: indexed(uint256)# wei
    token_amount: indexed(uint256)

event RemoveLiquidity:
    provider: indexed(address)
    eth_amount: indexed(uint256)# wei
    token_amount: indexed(uint256)

event Transfer:
    _from: indexed(address)
    _to: indexed(address)
    _value: uint256

event Approval:
    _owner: indexed(address)
    _spender: indexed(address)
    _value: uint256

name: public(bytes32)                             # Uniswap V1
symbol: public(bytes32)                           # UNI-V1
decimals: public(uint256)                         # 18
totalSupply: public(uint256)                      # total number of UNI in existence

# balances: uint256[address]                        # UNI balance of an address
balances: public(HashMap[address, uint256])

# allowances: (uint256[address])[address]           # UNI allowance of one address on another
allowances: public(HashMap[address, HashMap[address, uint256]])

# address of the ERC20 token traded on this contract
# old: token: address(ERC20)
token: public(ERC20)
tokenAddressRaw: address

# interface for the factory that created this contract
# factory: Factory
factory: Factory
factoryAddressRaw: address

# ZERO_ADDRESS: address

# @dev This function acts as a contract constructor which is not currently supported in contracts deployed
#      using create_with_code_of(). It is called once by the factory during contract creation.
@external
def setup(token_addr: address):

    # self.ZERO_ADDRESS = 0x0000000000000000000000000000000000000000

    # we redefine factory: Factory to be address to solve bug below
    # old: assert self.factory == ZERO_ADDRESS and self.token == ZERO_ADDRESS
    assert self.factory == Factory(ZERO_ADDRESS)
    assert self.token == ERC20(ZERO_ADDRESS)

    assert token_addr != ZERO_ADDRESS

    self.factory = Factory(msg.sender)
    self.token = ERC20(token_addr)

    # mz added this in
    self.factoryAddressRaw = msg.sender
    self.tokenAddressRaw = token_addr

    self.name = 0x556e697377617020563100000000000000000000000000000000000000000000
    self.symbol = 0x554e492d56310000000000000000000000000000000000000000000000000000
    self.decimals = 18

# @notice Deposit ETH and Tokens (self.token) at current ratio to mint UNI tokens.
# @dev min_liquidity does nothing when total UNI supply is 0.
# @param min_liquidity Minimum number of UNI sender will mint if total UNI supply is greater than 0.
# @param max_tokens Maximum number of tokens deposited. Deposits max amount if total UNI supply is 0.
# @param deadline Time after which this transaction can no longer be executed.
# @return The amount of UNI minted.
@external
@payable
def addLiquidity(min_liquidity: uint256, max_tokens: uint256, deadline: uint256) -> uint256:

    # problem desc: https://ethereum.stackexchange.com/questions/96795/can-you-use-block-times-as-a-measure-of-duration
    # old: assert deadline > block.timestamp and (max_tokens > 0 and msg.value > 0)
    # we are not user solution as memtioned above. but compiler passed

    assert deadline > block.timestamp
    assert max_tokens > 0 and msg.value > 0

    total_liquidity: uint256 = self.totalSupply

    if total_liquidity > 0:
        assert min_liquidity > 0

        # eth_reserve in wei
        eth_reserve: uint256 = self.balance - msg.value
        token_reserve: uint256 = self.token.balanceOf(self)
        token_amount: uint256 = msg.value * token_reserve / eth_reserve + 1
        liquidity_minted: uint256 = msg.value * total_liquidity / eth_reserve
        assert max_tokens >= token_amount and liquidity_minted >= min_liquidity

        self.balances[msg.sender] += liquidity_minted
        self.totalSupply = total_liquidity + liquidity_minted
        assert self.token.transferFrom(msg.sender, self, token_amount)

        log AddLiquidity(msg.sender, msg.value, token_amount)
        log Transfer(ZERO_ADDRESS, msg.sender, liquidity_minted)
        return liquidity_minted
    else:
        assert (self.factory != Factory(ZERO_ADDRESS) and self.token != ERC20(ZERO_ADDRESS))

        assert msg.value >= 1000000000

        # mz use tokenAddress
        assert self.factory.getExchange(self.tokenAddressRaw) == self

        token_amount: uint256 = max_tokens

        # Converts a int128, uint256, or decimal value with units into one without units (used for assignment and math).
        # initial_liquidity: uint256 = as_unitless_number(self.balance)
        initial_liquidity: uint256 = self.balance

        self.totalSupply = initial_liquidity
        self.balances[msg.sender] = initial_liquidity

        assert self.token.transferFrom(msg.sender, self, token_amount)
        log AddLiquidity(msg.sender, msg.value, token_amount)
        log Transfer(ZERO_ADDRESS, msg.sender, initial_liquidity)
        return initial_liquidity

# min_eth in wei
# @dev Burn UNI tokens to withdraw ETH and Tokens at current ratio.
# @param amount Amount of UNI burned.
# @param min_eth Minimum ETH withdrawn.
# @param min_tokens Minimum Tokens withdrawn.
# @param deadline Time after which this transaction can no longer be executed.
# @return The amount of ETH and Tokens withdrawn.
@external
def removeLiquidity(amount: uint256, min_eth: uint256, min_tokens: uint256, deadline: uint256) -> (uint256, uint256):
    assert (amount > 0 and deadline > block.timestamp) and (min_eth > 0 and min_tokens > 0)
    total_liquidity: uint256 = self.totalSupply
    assert total_liquidity > 0
    token_reserve: uint256 = self.token.balanceOf(self)

    eth_amount: uint256 = amount * self.balance / total_liquidity
    token_amount: uint256 = amount * token_reserve / total_liquidity

    assert eth_amount >= min_eth and token_amount >= min_tokens
    self.balances[msg.sender] -= amount
    self.totalSupply = total_liquidity - amount
    send(msg.sender, eth_amount)
    assert self.token.transfer(msg.sender, token_amount)
    log RemoveLiquidity(msg.sender, eth_amount, token_amount)
    log Transfer(msg.sender, ZERO_ADDRESS, amount)

    return eth_amount, token_amount # TODO: eth_amount in wei

# @dev Pricing function for converting between ETH and Tokens.
# @param input_amount Amount of ETH or Tokens being sold.
# @param input_reserve Amount of ETH or Tokens (input type) in exchange reserves.
# @param output_reserve Amount of ETH or Tokens (output type) in exchange reserves.
# @return Amount of ETH or Tokens bought.
@internal
@view
def getInputPrice(input_amount: uint256, input_reserve: uint256, output_reserve: uint256) -> uint256:
    assert input_reserve > 0 and output_reserve > 0
    input_amount_with_fee: uint256 = input_amount * 997
    numerator: uint256 = input_amount_with_fee * output_reserve
    denominator: uint256 = (input_reserve * 1000) + input_amount_with_fee
    return numerator / denominator

# @dev Pricing function for converting between ETH and Tokens.
# @param output_amount Amount of ETH or Tokens being bought.
# @param input_reserve Amount of ETH or Tokens (input type) in exchange reserves.
# @param output_reserve Amount of ETH or Tokens (output type) in exchange reserves.
# @return Amount of ETH or Tokens sold.
@internal
@view
def getOutputPrice(output_amount: uint256, input_reserve: uint256, output_reserve: uint256) -> uint256:
    assert input_reserve > 0 and output_reserve > 0
    numerator: uint256 = input_reserve * output_amount * 1000
    denominator: uint256 = (output_reserve - output_amount) * 997
    return numerator / denominator + 1

# eth_sold -> wei
@internal
def ethToTokenInput(eth_sold: uint256, min_tokens: uint256, deadline: uint256, buyer: address, recipient: address) -> uint256:

    assert deadline >= block.timestamp and (eth_sold > 0 and min_tokens > 0)
    token_reserve: uint256 = self.token.balanceOf(self)

    # tokens_bought: uint256 = self.getInputPrice(
    #     as_unitless_number(eth_sold),
    #     as_unitless_number(self.balance - eth_sold),
    #     token_reserve)

    tokens_bought: uint256 = self.getInputPrice(
        eth_sold,
        self.balance - eth_sold,
        token_reserve)

    assert tokens_bought >= min_tokens
    assert self.token.transfer(recipient, tokens_bought)

    log TokenPurchase(buyer, eth_sold, tokens_bought)
    return tokens_bought

# @notice Convert ETH to Tokens.
# @dev User specifies exact input (msg.value).
# @dev User cannot specify minimum output or deadline.
@external
@payable
def __default__():
    self.ethToTokenInput(msg.value, 1, block.timestamp, msg.sender, msg.sender)

# @notice Convert ETH to Tokens and transfers Tokens to recipient.
# @dev User specifies exact input (msg.value) and minimum output
# @param min_tokens Minimum Tokens bought.
# @param deadline Time after which this transaction can no longer be executed.
# @param recipient The address that receives output Tokens.
# @return Amount of Tokens bought.
@external
@payable
def ethToTokenTransferInput(min_tokens: uint256, deadline: uint256, recipient: address) -> uint256:
    assert recipient != self and recipient != ZERO_ADDRESS
    return self.ethToTokenInput(msg.value, min_tokens, deadline, msg.sender, recipient)

# @notice Convert ETH to Tokens.
# @dev User specifies exact input (msg.value) and minimum output.
# @param min_tokens Minimum Tokens bought.
# @param deadline Time after which this transaction can no longer be executed.
# @return Amount of Tokens bought.
@external
@payable
def ethToTokenSwapInput(min_tokens: uint256, deadline: uint256) -> uint256:
    return self.ethToTokenInput(msg.value, min_tokens, deadline, msg.sender, msg.sender)

# max_eth, eth_refund -> wei
@internal
def ethToTokenOutput(tokens_bought: uint256, max_eth: uint256, deadline: uint256, buyer: address, recipient: address) -> uint256:
    assert deadline >= block.timestamp and (tokens_bought > 0 and max_eth > 0)
    token_reserve: uint256 = self.token.balanceOf(self)

    # eth_sold: uint256 = self.getOutputPrice(tokens_bought, as_unitless_number(self.balance - max_eth), token_reserve)
    eth_sold: uint256 = self.getOutputPrice(
        tokens_bought,
        self.balance - max_eth,
        token_reserve)

    # Throws if eth_sold > max_eth

    eth_refund: uint256 = max_eth - as_wei_value(eth_sold, 'wei')

    if eth_refund > 0:
        send(buyer, eth_refund)

    assert self.token.transfer(recipient, tokens_bought)
    log TokenPurchase(buyer, as_wei_value(eth_sold, 'wei'), tokens_bought)

    return as_wei_value(eth_sold, 'wei')

# @notice Convert ETH to Tokens.
# @dev User specifies maximum input (msg.value) and exact output.
# @param tokens_bought Amount of tokens bought.
# @param deadline Time after which this transaction can no longer be executed.
# @return Amount of ETH sold.
@external
@payable
def ethToTokenSwapOutput(tokens_bought: uint256, deadline: uint256) -> uint256:
    return as_wei_value(self.ethToTokenOutput(tokens_bought, msg.value, deadline, msg.sender, msg.sender), "wei")

# @notice Convert ETH to Tokens and transfers Tokens to recipient.
# @dev User specifies maximum input (msg.value) and exact output.
# @param tokens_bought Amount of tokens bought.
# @param deadline Time after which this transaction can no longer be executed.
# @param recipient The address that receives output Tokens.
# @return Amount of ETH sold.
@external
@payable
def ethToTokenTransferOutput(tokens_bought: uint256, deadline: uint256, recipient: address) -> uint256:
    assert recipient != self and recipient != ZERO_ADDRESS
    return as_wei_value(self.ethToTokenOutput(tokens_bought, msg.value, deadline, msg.sender, recipient), "wei")

# TODO arg min_eth in wei
@internal
def tokenToEthInput(tokens_sold: uint256, min_eth: uint256, deadline: uint256, buyer: address, recipient: address) -> uint256:

    assert deadline >= block.timestamp and (tokens_sold > 0 and min_eth > 0)

    token_reserve: uint256 = self.token.balanceOf(self)
    # eth_bought: uint256 = self.getInputPrice(tokens_sold, token_reserve, as_unitless_number(self.balance))
    eth_bought: uint256 = self.getInputPrice(tokens_sold, token_reserve, self.balance)

    wei_bought: uint256 = as_wei_value(eth_bought, 'wei')
    assert wei_bought >= min_eth

    send(recipient, wei_bought)

    assert self.token.transferFrom(buyer, self, tokens_sold)

    log EthPurchase(buyer, tokens_sold, wei_bought)
    return as_wei_value(wei_bought, "wei")

## TODO min_eth in wei
# @notice Convert Tokens to ETH.
# @dev User specifies exact input and minimum output.
# @param tokens_sold Amount of Tokens sold.
# @param min_eth Minimum ETH purchased.
# @param deadline Time after which this transaction can no longer be executed.
# @return Amount of ETH bought.
@external
def tokenToEthSwapInput(tokens_sold: uint256, min_eth: uint256, deadline: uint256) -> uint256:
    return as_wei_value(self.tokenToEthInput(tokens_sold, min_eth, deadline, msg.sender, msg.sender), "wei")

# @notice Convert Tokens to ETH and transfers ETH to recipient.
# @dev User specifies exact input and minimum output.
# @param tokens_sold Amount of Tokens sold.
# @param min_eth Minimum ETH purchased.
# @param deadline Time after which this transaction can no longer be executed.
# @param recipient The address that receives output ETH.
# @return Amount of ETH bought.
@external
def tokenToEthTransferInput(tokens_sold: uint256, min_eth: uint256, deadline: uint256, recipient: address) -> uint256:
    assert recipient != self and recipient != ZERO_ADDRESS
    return as_wei_value(self.tokenToEthInput(tokens_sold, min_eth, deadline, msg.sender, recipient), "wei")

# TODO: eth_bought in wei
@internal
def tokenToEthOutput(eth_bought: uint256, max_tokens: uint256, deadline: uint256, buyer: address, recipient: address) -> uint256:

    assert deadline >= block.timestamp and eth_bought > 0

    token_reserve: uint256 = self.token.balanceOf(self)
    # tokens_sold: uint256 = self.getOutputPrice(as_unitless_number(eth_bought), token_reserve, as_unitless_number(self.balance))
    tokens_sold: uint256 = self.getOutputPrice(eth_bought, token_reserve, self.balance)

    # tokens sold is always > 0
    assert max_tokens >= tokens_sold
    send(recipient, eth_bought)
    assert self.token.transferFrom(buyer, self, tokens_sold)
    log EthPurchase(buyer, tokens_sold, eth_bought)

    return tokens_sold

# TODO: eth_bought in wei
# @notice Convert Tokens to ETH.
# @dev User specifies maximum input and exact output.
# @param eth_bought Amount of ETH purchased.
# @param max_tokens Maximum Tokens sold.
# @param deadline Time after which this transaction can no longer be executed.
# @return Amount of Tokens sold.
@external
def tokenToEthSwapOutput(eth_bought: uint256, max_tokens: uint256, deadline: uint256) -> uint256:
    return self.tokenToEthOutput(eth_bought, max_tokens, deadline, msg.sender, msg.sender)

# TODO: eth_bought in wei
# @notice Convert Tokens to ETH and transfers ETH to recipient.
# @dev User specifies maximum input and exact output.
# @param eth_bought Amount of ETH purchased.
# @param max_tokens Maximum Tokens sold.
# @param deadline Time after which this transaction can no longer be executed.
# @param recipient The address that receives output ETH.
# @return Amount of Tokens sold.
@external
def tokenToEthTransferOutput(eth_bought: uint256, max_tokens: uint256, deadline: uint256, recipient: address) -> uint256:
    assert recipient != self and recipient != ZERO_ADDRESS
    return self.tokenToEthOutput(eth_bought, max_tokens, deadline, msg.sender, recipient)

# TODO: min_eth_bought in wei
@internal
def tokenToTokenInput(tokens_sold: uint256, min_tokens_bought: uint256, min_eth_bought: uint256, deadline: uint256, buyer: address, recipient: address, exchange_addr: address) -> uint256:
    assert (deadline >= block.timestamp and tokens_sold > 0) and (min_tokens_bought > 0 and min_eth_bought > 0)
    assert exchange_addr != self and exchange_addr != ZERO_ADDRESS
    token_reserve: uint256 = self.token.balanceOf(self)

    # eth_bought: uint256 = self.getInputPrice(tokens_sold, token_reserve, as_unitless_number(self.balance))
    eth_bought: uint256 = self.getInputPrice(tokens_sold, token_reserve, self.balance)

    wei_bought: uint256 = as_wei_value(eth_bought, 'wei')
    assert wei_bought >= min_eth_bought
    assert self.token.transferFrom(buyer, self, tokens_sold)

    tokens_bought: uint256 = Exchange(exchange_addr).ethToTokenTransferInput(min_tokens_bought, deadline, recipient, value=wei_bought)

    log EthPurchase(buyer, tokens_sold, wei_bought)
    return tokens_bought

# TODO: min_eth_bought in wei
# @notice Convert Tokens (self.token) to Tokens (token_addr).
# @dev User specifies exact input and minimum output.
# @param tokens_sold Amount of Tokens sold.
# @param min_tokens_bought Minimum Tokens (token_addr) purchased.
# @param min_eth_bought Minimum ETH purchased as intermediary.
# @param deadline Time after which this transaction can no longer be executed.
# @param token_addr The address of the token being purchased.
# @return Amount of Tokens (token_addr) bought.
@external
def tokenToTokenSwapInput(tokens_sold: uint256, min_tokens_bought: uint256, min_eth_bought: uint256, deadline: uint256, token_addr: address) -> uint256:
    exchange_addr: address = self.factory.getExchange(token_addr)
    return self.tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, msg.sender, exchange_addr)

# TODO: min_eth_bought in wei
# @notice Convert Tokens (self.token) to Tokens (token_addr) and transfers
#         Tokens (token_addr) to recipient.
# @dev User specifies exact input and minimum output.
# @param tokens_sold Amount of Tokens sold.
# @param min_tokens_bought Minimum Tokens (token_addr) purchased.
# @param min_eth_bought Minimum ETH purchased as intermediary.
# @param deadline Time after which this transaction can no longer be executed.
# @param recipient The address that receives output ETH.
# @param token_addr The address of the token being purchased.
# @return Amount of Tokens (token_addr) bought.
@external
def tokenToTokenTransferInput(tokens_sold: uint256, min_tokens_bought: uint256, min_eth_bought: uint256, deadline: uint256, recipient: address, token_addr: address) -> uint256:
    exchange_addr: address = self.factory.getExchange(token_addr)
    return self.tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, recipient, exchange_addr)

@internal
def tokenToTokenOutput(tokens_bought: uint256, max_tokens_sold: uint256, max_eth_sold: uint256, deadline: uint256, buyer: address, recipient: address, exchange_addr: address) -> uint256:
    assert deadline >= block.timestamp and (tokens_bought > 0 and max_eth_sold > 0)
    assert exchange_addr != self and exchange_addr != ZERO_ADDRESS

    eth_bought: uint256 = Exchange(exchange_addr).getEthToTokenOutputPrice(tokens_bought)
    token_reserve: uint256 = self.token.balanceOf(self)

    # tokens_sold: uint256 = self.getOutputPrice(as_unitless_number(eth_bought), token_reserve, as_unitless_number(self.balance))
    tokens_sold: uint256 = self.getOutputPrice(eth_bought, token_reserve, self.balance)

    # tokens sold is always > 0
    assert max_tokens_sold >= tokens_sold and max_eth_sold >= eth_bought
    assert self.token.transferFrom(buyer, self, tokens_sold)
    eth_sold: uint256 = Exchange(exchange_addr).ethToTokenTransferOutput(tokens_bought, deadline, recipient, value=eth_bought)

    log EthPurchase(buyer, tokens_sold, eth_bought)
    return tokens_sold

# TODO: max_eth_sold in wei
# @notice Convert Tokens (self.token) to Tokens (token_addr).
# @dev User specifies maximum input and exact output.
# @param tokens_bought Amount of Tokens (token_addr) bought.
# @param max_tokens_sold Maximum Tokens (self.token) sold.
# @param max_eth_sold Maximum ETH purchased as intermediary.
# @param deadline Time after which this transaction can no longer be executed.
# @param token_addr The address of the token being purchased.
# @return Amount of Tokens (self.token) sold.
@external
def tokenToTokenSwapOutput(tokens_bought: uint256, max_tokens_sold: uint256, max_eth_sold: uint256, deadline: uint256, token_addr: address) -> uint256:
    exchange_addr: address = self.factory.getExchange(token_addr)
    return self.tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, msg.sender, exchange_addr)

# TODO max_eth_sold wei
# @notice Convert Tokens (self.token) to Tokens (token_addr) and transfers
#         Tokens (token_addr) to recipient.
# @dev User specifies maximum input and exact output.
# @param tokens_bought Amount of Tokens (token_addr) bought.
# @param max_tokens_sold Maximum Tokens (self.token) sold.
# @param max_eth_sold Maximum ETH purchased as intermediary.
# @param deadline Time after which this transaction can no longer be executed.
# @param recipient The address that receives output ETH.
# @param token_addr The address of the token being purchased.
# @return Amount of Tokens (self.token) sold.
@external
def tokenToTokenTransferOutput(tokens_bought: uint256, max_tokens_sold: uint256, max_eth_sold: uint256, deadline: uint256, recipient: address, token_addr: address) -> uint256:
    exchange_addr: address = self.factory.getExchange(token_addr)
    return self.tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, recipient, exchange_addr)

# TODO min_eth_bought wei
# @notice Convert Tokens (self.token) to Tokens (exchange_addr.token).
# @dev Allows trades through contracts that were not deployed from the same factory.
# @dev User specifies exact input and minimum output.
# @param tokens_sold Amount of Tokens sold.
# @param min_tokens_bought Minimum Tokens (token_addr) purchased.
# @param min_eth_bought Minimum ETH purchased as intermediary.
# @param deadline Time after which this transaction can no longer be executed.
# @param exchange_addr The address of the exchange for the token being purchased.
# @return Amount of Tokens (exchange_addr.token) bought.
@external
def tokenToExchangeSwapInput(tokens_sold: uint256, min_tokens_bought: uint256, min_eth_bought: uint256, deadline: uint256, exchange_addr: address) -> uint256:
    return self.tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, msg.sender, exchange_addr)

# TODO min_eth_bought wei
# @notice Convert Tokens (self.token) to Tokens (exchange_addr.token) and transfers
#         Tokens (exchange_addr.token) to recipient.
# @dev Allows trades through contracts that were not deployed from the same factory.
# @dev User specifies exact input and minimum output.
# @param tokens_sold Amount of Tokens sold.
# @param min_tokens_bought Minimum Tokens (token_addr) purchased.
# @param min_eth_bought Minimum ETH purchased as intermediary.
# @param deadline Time after which this transaction can no longer be executed.
# @param recipient The address that receives output ETH.
# @param exchange_addr The address of the exchange for the token being purchased.
# @return Amount of Tokens (exchange_addr.token) bought.
@external
def tokenToExchangeTransferInput(tokens_sold: uint256, min_tokens_bought: uint256, min_eth_bought: uint256, deadline: uint256, recipient: address, exchange_addr: address) -> uint256:
    assert recipient != self
    return self.tokenToTokenInput(tokens_sold, min_tokens_bought, min_eth_bought, deadline, msg.sender, recipient, exchange_addr)

# TODO max_eth_sold wei
# @notice Convert Tokens (self.token) to Tokens (exchange_addr.token).
# @dev Allows trades through contracts that were not deployed from the same factory.
# @dev User specifies maximum input and exact output.
# @param tokens_bought Amount of Tokens (token_addr) bought.
# @param max_tokens_sold Maximum Tokens (self.token) sold.
# @param max_eth_sold Maximum ETH purchased as intermediary.
# @param deadline Time after which this transaction can no longer be executed.
# @param exchange_addr The address of the exchange for the token being purchased.
# @return Amount of Tokens (self.token) sold.
@external
def tokenToExchangeSwapOutput(tokens_bought: uint256, max_tokens_sold: uint256, max_eth_sold: uint256, deadline: uint256, exchange_addr: address) -> uint256:
    return self.tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, msg.sender, exchange_addr)

# TODO max_eth_sold wei
# @notice Convert Tokens (self.token) to Tokens (exchange_addr.token) and transfers
#         Tokens (exchange_addr.token) to recipient.
# @dev Allows trades through contracts that were not deployed from the same factory.
# @dev User specifies maximum input and exact output.
# @param tokens_bought Amount of Tokens (token_addr) bought.
# @param max_tokens_sold Maximum Tokens (self.token) sold.
# @param max_eth_sold Maximum ETH purchased as intermediary.
# @param deadline Time after which this transaction can no longer be executed.
# @param recipient The address that receives output ETH.
# @param token_addr The address of the token being purchased.
# @return Amount of Tokens (self.token) sold.
@external
def tokenToExchangeTransferOutput(tokens_bought: uint256, max_tokens_sold: uint256, max_eth_sold: uint256, deadline: uint256, recipient: address, exchange_addr: address) -> uint256:
    assert recipient != self
    return self.tokenToTokenOutput(tokens_bought, max_tokens_sold, max_eth_sold, deadline, msg.sender, recipient, exchange_addr)

# eth_sold -> wei
# @notice Public price function for ETH to Token trades with an exact input.
# @param eth_sold Amount of ETH sold.
# @return Amount of Tokens that can be bought with input ETH.
@external
@view
def getEthToTokenInputPrice(eth_sold: uint256) -> uint256:
    assert eth_sold > 0
    token_reserve: uint256 = self.token.balanceOf(self)

    # return self.getInputPrice(as_unitless_number(eth_sold), as_unitless_number(self.balance), token_reserve)
    return self.getInputPrice(eth_sold, self.balance, token_reserve)

# @notice Public price function for ETH to Token trades with an exact output.
# @param tokens_bought Amount of Tokens bought.
# @return Amount of ETH needed to buy output Tokens.
@external
@view
def getEthToTokenOutputPrice(tokens_bought: uint256) -> uint256:
    assert tokens_bought > 0
    token_reserve: uint256 = self.token.balanceOf(self)

    # eth_sold: uint256 = self.getOutputPrice(tokens_bought, as_unitless_number(self.balance), token_reserve)
    eth_sold: uint256 = self.getOutputPrice(tokens_bought, self.balance, token_reserve)

    return as_wei_value(eth_sold, 'wei')

# @notice Public price function for Token to ETH trades with an exact input.
# @param tokens_sold Amount of Tokens sold.
# @return Amount of ETH that can be bought with input Tokens.
@external
@view
def getTokenToEthInputPrice(tokens_sold: uint256) -> uint256:
    assert tokens_sold > 0
    token_reserve: uint256 = self.token.balanceOf(self)

    # eth_bought: uint256 = self.getInputPrice(tokens_sold, token_reserve, as_unitless_number(self.balance))
    eth_bought: uint256 = self.getInputPrice(tokens_sold, token_reserve, self.balance)

    return as_wei_value(eth_bought, 'wei')

# eth_bought -> wei
# @notice Public price function for Token to ETH trades with an exact output.
# @param eth_bought Amount of output ETH.
# @return Amount of Tokens needed to buy output ETH.
@external
@view
def getTokenToEthOutputPrice(eth_bought: uint256) -> uint256:
    assert eth_bought > 0
    token_reserve: uint256 = self.token.balanceOf(self)

    # return self.getOutputPrice(as_unitless_number(eth_bought), token_reserve, as_unitless_number(self.balance))
    return self.getOutputPrice(eth_bought, token_reserve, self.balance)

# @return Address of Token that is sold on this exchange.
@external
@view
def tokenAddress() -> address:
    return self.tokenAddressRaw

# @return Address of factory that created this exchange.
# old def factoryAddress() -> address(Factory):
@external
@view
def factoryAddress() -> address:
    return self.factoryAddressRaw

# ERC20 compatibility for exchange liquidity modified from
# https://github.com/ethereum/vyper/blob/master/examples/tokens/ERC20.vy
@external
@view
def balanceOf(_owner : address) -> uint256:
    return self.balances[_owner]

@external
def transfer(_to : address, _value : uint256) -> bool:
    self.balances[msg.sender] -= _value
    self.balances[_to] += _value
    log Transfer(msg.sender, _to, _value)
    return True

@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    self.balances[_from] -= _value
    self.balances[_to] += _value
    self.allowances[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True

@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowances[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True

@external
@view
def allowance(_owner : address, _spender : address) -> uint256:
    return self.allowances[_owner][_spender]