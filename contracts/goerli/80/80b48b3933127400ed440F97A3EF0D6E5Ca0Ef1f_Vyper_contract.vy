# @version ^0.3.0

###################
# State Variables #
###################

# The administrator of the contract. They can set the oracle address, the fee percent, the fee
# recipient address, the validator contract address, and destroy the contract itself.
admin: public(address)

# The oracle can transfer the funds in this contract to the validator contract.
oracleAddress: public(address)

# We charge fees to use our services
feePercent: public(uint256)

# The wallet used to collect the fees
feeRecipientAddress: public(address)

# The address of the contract validators use to interact register and collect their rewards
validatorContractAddress: public(address)


# Fire whenever the contract receives funds
event FundsDeposited:
    depositingWallet: indexed(address)
    value: uint256


# Fires whenever we call the transfer function
event BalanceTransferred:
    blockNumber: indexed(uint256)
    feeRecipientAddress: address
    fees: uint256
    validatorContractAddress: address
    value: uint256


@external
@nonpayable
def __init__(oracleAddress: address,
             feePercent: uint256,
             feeRecipientAddress: address,
             validatorContractAddress: address):

    # Set the contract's initial state
    self.admin = msg.sender
    self.oracleAddress = oracleAddress
    self.feePercent = feePercent
    self.feeRecipientAddress = feeRecipientAddress
    self.validatorContractAddress = validatorContractAddress


@external
@payable
def __default__():

    # Send an event to any listeners when funds are added
    log FundsDeposited(msg.sender, msg.value)


@external
@nonpayable
def set_oracle_address(newAddress: address) -> address:

    # Only the admin may change this address
    assert msg.sender == self.admin, "Access denied!"

    # Set the new address and return the old one
    oldAddress: address = self.oracleAddress
    self.oracleAddress = newAddress
    return oldAddress


@external
@nonpayable
def set_fee_percent(feePercent: uint256) -> uint256:

    # Only the admin may change this address
    assert msg.sender == self.admin, "Access denied!"

    # Ensure the range is good. It cannot be <0 due to the `feePercent` type itself being uint256.
    assert feePercent <= 100, "The fee percent must be <= 100."

    # Set the new fee and return the old one
    oldFeePercent: uint256 = self.feePercent
    self.feePercent = feePercent
    return oldFeePercent


@external
@nonpayable
def set_fee_recipient_address(newAddress: address) -> address:

    # Only the admin may change this address
    assert msg.sender == self.admin, "Access denied!"

    # Set the new address and return the old one
    oldAddress: address = self.feeRecipientAddress
    self.feeRecipientAddress = newAddress
    return oldAddress


@external
@nonpayable
def set_validator_contract_address(newAddress: address) -> address:

    # Only the admin may change this address
    assert msg.sender == self.admin, "Access denied!"

    # Set the new address and return the old one
    oldAddress: address = self.validatorContractAddress
    self.validatorContractAddress = newAddress
    return oldAddress


@external
@nonpayable
def transfer_balance_to_validator_contract():

    # Only the oracle may call this function
    assert msg.sender == self.oracleAddress, "Access denied!"

    # There should be a balance
    assert self.balance > 0

    # The portion of fees. We round down the fees because we love you.
    decimalFeePercent: decimal = convert(self.feePercent, decimal)
    decimalBalance: decimal = convert(self.balance, decimal)
    decimalFees: decimal = decimalBalance * (decimalFeePercent / 100.0)
    fees: uint256 = convert(decimalFees, uint256)
    remainingBalance: uint256 = self.balance - fees

    # Send the fees to the admin and the rest of the balance to the validator contract.
    send(self.feeRecipientAddress, fees)
    send(self.validatorContractAddress, remainingBalance)

    # Emit an event which will be caught by the oracle.
    log BalanceTransferred(block.number,
                           self.feeRecipientAddress, fees,
                           self.validatorContractAddress, remainingBalance)


@external
def destroy_contract():
    assert(msg.sender == self.admin)
    selfdestruct(msg.sender)