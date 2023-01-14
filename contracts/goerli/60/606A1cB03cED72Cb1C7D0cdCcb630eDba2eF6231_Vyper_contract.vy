# @version ^0.3.0

##########
# README #
##########

# Unpool's MEV Smoothing Interface Contract
# https://verihash.io/
# https://unpool.fi/

# TLDR: If you run a validator, use this contract to interface with the three MEV smoothing
# contracts. This interface contract has "pointers" to the `deposit` and `withdraw` contracts,
# because Unpool will update the logic within those contracts periodically. We want the contract
# our Validators use to have a static address, but the ability to upgrade logic on the "backend" if
# needed.


#############
# Constants #
#############

PUBLIC_KEY_LENGTH: constant(uint256) = 48
MESSAGE_LENGTH: constant(uint256) = 16
SIGNATURE_LENGTH: constant(uint256) = 96


#######################
# Contract Interfaces #
#######################

interface OFAC_Vault_Interface:
    def is_address_banned(theAddress: address) -> bool: nonpayable


interface Withdraw_Contract_Interface:
    def add_validator(validatorPublicKey: Bytes[PUBLIC_KEY_LENGTH],
                      validatorSignedMessage: Bytes[MESSAGE_LENGTH],
                      validatorSignature: Bytes[SIGNATURE_LENGTH],
                      isOfacCompliant: bool): nonpayable
    def remove_validator(validatorPublicKey: Bytes[PUBLIC_KEY_LENGTH]) -> address: nonpayable
    def withdraw(amount: uint256) -> uint256: nonpayable
    def withdraw_all() -> uint256: nonpayable


###################
# State Variables #
###################

# The administrator of the contract. They can change the addresses of the other contracts called by
# this proxy contract.
admin: public(address)

# The address of the OFAC Vault contract
ofacVaultContractAddress: public(address)

# The interface to the OFAC Vault contract
ofacVaultContract: OFAC_Vault_Interface

# The address of the Withdraw contract
withdrawContractAddress: public(address)

# The interface to the Deposit contract
withdrawContract: Withdraw_Contract_Interface


################################################
# Contract Initialization and Default Function #
################################################

@external
@nonpayable
def __init__(ofacVaultContractAddress: address,
             withdrawContractAddress: address):

    # Set the contract's initial state
    self.admin = msg.sender
    self.ofacVaultContractAddress = ofacVaultContractAddress
    self.ofacVaultContract = OFAC_Vault_Interface(ofacVaultContractAddress)
    self.withdrawContractAddress = withdrawContractAddress
    self.withdrawContract = Withdraw_Contract_Interface(withdrawContractAddress)


@internal
@nonpayable
def _check(theAddress: address) -> bool:
    return self.ofacVaultContract.is_address_banned(theAddress)


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
def set_ofac_vault_contract_address(newAddress: address) -> address:

    # Only the admin may change this address
    assert msg.sender == self.admin, "You cannot set the OFAC vault contract address."

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
    self.withdrawContract = Withdraw_Contract_Interface(newAddress)
    return oldAddress


@external
def destroy_contract():

    # Only allow the `admin` to call this function
    assert msg.sender == self.admin, "You cannot destroy the contract."

    # Destroy the contract
    selfdestruct(msg.sender)


#######################
# Validator Functions #
#######################

@external
@nonpayable
def add_validator(validatorPublicKey: Bytes[PUBLIC_KEY_LENGTH],
                  validatorSignedMessage: Bytes[MESSAGE_LENGTH],
                  validatorSignature: Bytes[SIGNATURE_LENGTH],
                  isOfacCompliant: bool):

    """ Arguments:
    validatorPublicKey: The BLS public key of the validator, from the Geth keystore file.
    validatorSignedMessage: The message signed with the validator private key.
    validatorSignature: The BLS signature of the signed message. Cannot be used more than once.
    isOfacCompliant: In order to do business with VeriHash Inc., A user must specify if they must
        comply with the United State's Office of Foreign Asset Control (OFAC) requirement of not
        doing business with any entity on the list of Specially Designated Nationals and Blocked
        Persons ("SDN List"):
        https://www.treasury.gov/ofac/downloads/sdnlist.txt
        https://home.treasury.gov/policy-issues/financial-sanctions/specially-designated-nationals-and-blocked-persons-list-sdn-human-readable-lists
    """

    # Ensure the calling address is not banned
    assert self._check(msg.sender) == False, \
    "You are on the US Treasury's SDN list. We cannot do business with you."

    self.withdrawContract.add_validator(validatorPublicKey,
                                        validatorSignedMessage,
                                        validatorSignature,
                                        isOfacCompliant)


@external
@nonpayable
def remove_validator(validatorPublicKey: Bytes[PUBLIC_KEY_LENGTH]) -> address:

    # Ensure the calling address is not banned
    assert self._check(msg.sender) == False, \
    "You are on the US Treasury's SDN list. We cannot do business with you."

    return self.withdrawContract.remove_validator(validatorPublicKey)


@external
@nonpayable
@nonreentrant("withdraw")
def withdraw(amount: uint256) -> uint256:
    """ Withdraw a partial beneficiary wallet's balance. """

    # Ensure the calling address is not banned
    assert self._check(msg.sender) == False, \
    "You are on the US Treasury's SDN list. We cannot do business with you."

    return self.withdrawContract.withdraw(amount)


@external
@nonpayable
@nonreentrant("withdraw_all")
def withdraw_all() -> uint256:
    """ Withdraw the entire beneficiary wallet's balance. """

    # Ensure the calling address is not banned
    assert self._check(msg.sender) == False, \
    "You are on the US Treasury's SDN list. We cannot do business with you."

    return self.withdrawContract.withdraw_all()