# @version ^0.3.0

#################################
# Interfaces to other contracts #
#################################

interface OFAC_Vault_Interface:
    def is_address_banned(theAddress: address) -> bool: nonpayable


###################
# State Variables #
###################

# The administrator of the contract. They can set the oracle address, the fee percent, the fee
# recipient address, the withdraw contract address, and destroy the contract itself.
admin: public(address)

# The oracle can transfer the funds in this contract to the withdraw contract.
oracleAddress: public(address)

# The address of the OFAC Vault contract
ofacVaultContractAddress: public(address)

# The interface to the OFAC Vault contract
ofacVaultContract: OFAC_Vault_Interface

# The address of the insurance contract, used to pay our clients if something bad happens
insuranceContractAddress: public(address)

# The address of the contract validators use to interact, register, and collect their rewards
withdrawContractAddress: public(address)


##########
# Events #
##########

# Fires whenever we call the transfer function
event BalanceTransferred:
    ofacVaultContractAddress: address
    frozenValue: uint256
    insuranceContractAddress: address
    insuranceAmount: uint256
    withdrawContractAddress: address
    withdrawFunds: uint256


################################################
# Contract Initialization and Default Function #
################################################

@external
@nonpayable
def __init__(oracleAddress: address,
             ofacVaultContractAddress: address,
             insuranceContractAddress: address,
             withdrawContractAddress: address):

    # Set the contract's initial state
    self.admin = msg.sender
    self.oracleAddress = oracleAddress
    self.ofacVaultContractAddress = ofacVaultContractAddress
    self.ofacVaultContract = OFAC_Vault_Interface(self.ofacVaultContractAddress)
    self.insuranceContractAddress = insuranceContractAddress
    self.withdrawContractAddress = withdrawContractAddress


@external
@payable
def __default__():

    # Ensure the calling address is not banned
    assert self.ofacVaultContract.is_address_banned(msg.sender) == False, \
    "You are on the US Treasury's SDN list. We cannot do business with you."


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

    # Only the admin may change this address
    assert msg.sender == self.admin, "You cannot update the oracle address."

    # Set the new address and return the old one
    oldAddress: address = self.oracleAddress
    self.oracleAddress = newAddress
    return oldAddress


@external
@nonpayable
def set_ofac_vault_contract_address(newAddress: address) -> address:

    # Only the admin may change this address
    assert msg.sender == self.admin, "You cannot set the OFAC Vault contract address."

    # Set the new address and return the old one
    oldAddress: address = self.ofacVaultContractAddress
    self.ofacVaultContractAddress = newAddress
    self.ofacVaultContract = OFAC_Vault_Interface(newAddress)
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
@nonpayable
def set_insurance_contract_address(newAddress: address) -> address:

    # Only the admin may change this address
    assert msg.sender == self.admin, "You cannot set the insurance contract address."

    # Set the new address and return the old one
    oldAddress: address = self.insuranceContractAddress
    self.insuranceContractAddress = newAddress
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
def transfer_balance(frozenAmount: uint256, insuranceAmount: uint256) -> uint256:

    # Only the oracle may call this function
    assert msg.sender == self.oracleAddress, "Only the oracle can transfer the balance."

    # There should be a balance
    assert self.balance > 0, "There is no ETH to transfer."

    # We can't hold more than what is in the contract
    assert frozenAmount + insuranceAmount <= self.balance, \
    "We can't deduct more ETH than is in the contract for freezeing and insurance."

    # We need to separate frozen OFAC and Insurance ETH from the funds we can use to withdraw from
    oldBalance: uint256 = self.balance
    withdrawFunds: uint256 = self.balance - frozenAmount - insuranceAmount

    # Send the frozen funds to the OFAC vault contract and the rest of the balance to
    # the withdraw contract.
    if frozenAmount > 0:
        send(self.ofacVaultContractAddress, frozenAmount)
    if insuranceAmount > 0:
        send(self.insuranceContractAddress, insuranceAmount)
    if withdrawFunds > 0:
        send(self.withdrawContractAddress, withdrawFunds)

    # Emit an event which will be caught by the oracle.
    log BalanceTransferred(self.ofacVaultContractAddress, frozenAmount,
                           self.insuranceContractAddress, insuranceAmount,
                           self.withdrawContractAddress, withdrawFunds)

    return oldBalance