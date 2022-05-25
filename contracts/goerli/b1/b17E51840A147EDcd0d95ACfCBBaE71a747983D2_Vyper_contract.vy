interface IStarknetCore:
    # Sends a message to an L2 contract.
    # Returns the hash of the message.
    def sendMessageToL2(toAddress: uint256, selector: uint256, payload: uint256[2]) -> (bytes32): nonpayable

    #Consumes a message that was sent from an L2 contract.
    #Returns the hash of the message.
    def consumeMessageFromL2(fromAddress: uint256, payload: uint256[3]) -> (bytes32): nonpayable

# The StarkNet core contract.
starknetCore: IStarknetCore

userBalances: public(HashMap[uint256, uint256])

MESSAGE_WITHDRAW: constant(uint256) = 0

# The selector of the "deposit" l1_handler.
DEPOSIT_SELECTOR: constant(uint256) = 352040181584456735608515580760888541466059565068553383579463728554843487745


# Initializes the contract state.
@external
def __init__(starknetCore_: address):
    self.starknetCore = IStarknetCore(starknetCore_)

@external
def withdraw(l2ContractAddress: uint256, user: uint256, amount: uint256):
    # Construct the withdrawal message's payload.
    payload: uint256[3] = [MESSAGE_WITHDRAW, user, amount]

    # Consume the message from the StarkNet core contract.
    # This will revert the (Ethereum) transaction if the message does not exist.
    self.starknetCore.consumeMessageFromL2(l2ContractAddress, payload)

    # Update the L1 balance.
    self.userBalances[user] += amount

@external
def deposit(l2ContractAddress: uint256, user: uint256, amount: uint256):
    assert amount < 2**64, "Invalid amount"
    assert amount <= self.userBalances[user], "Insufficient balance"

    # Update the L1 balance.
    self.userBalances[user] -= amount

    # Construct the deposit message's payload.
    payload: uint256[2] = [user, amount]

    # Send the message to the StarkNet core contract.
    self.starknetCore.sendMessageToL2(l2ContractAddress, DEPOSIT_SELECTOR, payload)