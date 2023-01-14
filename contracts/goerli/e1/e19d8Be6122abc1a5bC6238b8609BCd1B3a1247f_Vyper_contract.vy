# @version ^0.3.0

###################
# State Variables #
###################

# The administrative address who can update `oracleAddress`, the contract pointers, and destroy
# the contract
admin: public(address)

# The wallet who can transfer funds from this contract to the withdraw contract
oracleAddress: public(address)

# The deposit contract, which sends funds to this contract
depositContractAddress: public(address)

# The withdraw contract, where this contract sends funds
withdrawContractAddress: public(address)


##########
# Events #
##########

# Fires whenever we call the transfer function
event BalanceTransferred:
    withdrawContractAddress: address
    value: uint256


################################################
# Contract Initialization and Default Function #
################################################

@external
@nonpayable
def __init__(oracleAddress: address,
             depositContractAddress: address,
             withdrawContractAddress: address):

    # Set the contract's initial state
    self.admin = msg.sender
    self.oracleAddress = oracleAddress
    self.depositContractAddress = depositContractAddress
    self.withdrawContractAddress = withdrawContractAddress


@external
@payable
def __default__():

    # Only allow the `depositContractAddress` to send funds here
    assert msg.sender == self.depositContractAddress, \
    "You cannot send funds to this contract."


############################
# Administrative Functions #
############################

@external
@nonpayable
def set_admin_address(admin: address) -> address:

    # Only allow the `admin` to call this function
    assert msg.sender == self.admin, "You cannot update the admin address."

    # Set the new admin address and return the old one
    oldAddress: address = self.admin
    self.admin = admin
    return oldAddress


@external
@nonpayable
def set_oracle_address(newAddress: address) -> address:

    # Only the `admin` may change this address
    assert msg.sender == self.admin, "You cannot update the oracle address."

    # Set the new address and return the old one
    oldAddress: address = self.oracleAddress
    self.oracleAddress = newAddress
    return oldAddress


@external
@nonpayable
def set_deposit_contract_address(newAddress: address) -> address:

    # Only the `admin` may change this address
    assert msg.sender == self.admin, "You cannot update the deposit contract address."

    # Set the new address and return the old one
    oldAddress: address = self.depositContractAddress
    self.depositContractAddress = newAddress
    return oldAddress


@external
@nonpayable
def set_withdraw_contract_address(newAddress: address) -> address:

    # Only the admin may change this address
    assert msg.sender == self.admin, "You cannot set the withdraw contract address."

    # Set the new address and return the old one
    oldAddress: address = self.withdrawContractAddress
    self.withdrawContractAddress = newAddress
    return oldAddress


@external
def destroy_contract():

    # Only allow the `admin` to call this function
    assert msg.sender == self.admin, "You cannot destroy the contract."

    # Destroy the contract
    selfdestruct(msg.sender)


####################
# Oracle Functions #
####################

@external
@nonpayable
def transfer_balance(amount: uint256) -> uint256:

    # Only the oracle may call this function
    assert msg.sender == self.oracleAddress, "Only the oracle can transfer the balance."

    # There should be a balance
    assert self.balance > 0, "There is no ETH to transfer."

    # We can't send 0 ETH
    assert amount > 0, "You must send a positive non-zero amount."

    # We can't send more than what is in the contract
    assert amount <= self.balance, "We can't send more than the entire balance of the contract."

    # Return the old balance
    oldBalance: uint256 = self.balance

    # Send the amount to the withdraw contract address
    send(self.withdrawContractAddress, amount)

    # Emit an event which will be caught by the oracle.
    log BalanceTransferred(self.withdrawContractAddress, amount)

    return oldBalance