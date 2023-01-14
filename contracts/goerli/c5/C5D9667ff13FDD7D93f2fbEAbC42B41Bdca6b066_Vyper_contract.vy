# @version ^0.3.0


#############
# Constants #
#############

PUBLIC_KEY_LENGTH: constant(uint256) = 48
MESSAGE_LENGTH: constant(uint256) = 16
SIGNATURE_LENGTH: constant(uint256) = 96
WALLET_UPDATE_ARRAY_MAX_SIZE: constant(uint256) = 1000  # Must be > 0
walletUpdateArrayMaxSize: public(uint256)  # We need this value when running the oracle


###########
# Structs #
###########

# Use in a `DynArray` when updating beneficiary wallet balances in order to save gas.
struct WalletUpdate:
    beneficiaryWallet: address
    addedBalance: uint256


####################################
# Interface to OFAC Vault Contract #
####################################

interface OFAC_Vault_Interface:
    def is_address_banned(theAddress: address) -> bool: nonpayable


###################
# State Variables #
###################

# The administrative address who can update `oracleAddress`, `ofacVaultContractAddress`, and destroy
# the contract
admin: public(address)

# The wallet who can update the `rewardBalance` for each `beneficiaryWallet`
oracleAddress: public(address)

# The address of the OFAC Vault contract
ofacVaultContractAddress: public(address)

# The interface to the OFAC Vault contract
ofacVaultContract: OFAC_Vault_Interface

# A map of OFAC compliance for each validator public key
ofacCompliance: public(HashMap[Bytes[PUBLIC_KEY_LENGTH], bool])

# The deposit contract, which sends funds to this contract
depositContractAddress: public(address)

# The insurance contract, which is used to top off deficits from OFAC transactions
insuranceContractAddress: public(address)

# The address of the proxy contract, used by clients
proxyContractAddress: public(address)

# A map of {validatorPublicKey:beneficiaryWallet}
validators: public(HashMap[Bytes[PUBLIC_KEY_LENGTH], address])

# The number of validators waiting to be approved
numWaitingValidators: public(uint256)

# A map of {validatorPublicKey:isWaiting}
waitingValidators: public(HashMap[Bytes[PUBLIC_KEY_LENGTH], bool])

# The current number of active validators
numValidators: public(uint256)

# A map of {beneficiaryWallet:rewardBalance}
walletBalances: public(HashMap[address, uint256])

# The total balance of all validators. We store this particular value to ensure we have enough
# balance in the contract when updating individual validator balances.
totalWalletBalance: public(uint256)

# Use a map to ensure signed messages can't be used twice
signatures: public(HashMap[Bytes[SIGNATURE_LENGTH], bool])

# Used to check if someone can send funds here
allowedDepositWallets: public(HashMap[address, bool])


##########
# Events #
##########

# Fire whenever a validator is enqueued
event ValidatorQueued:
    beneficiaryWallet: address
    validatorPublicKey: Bytes[PUBLIC_KEY_LENGTH]
    validatorSignedMessage: Bytes[MESSAGE_LENGTH]
    validatorSignature: Bytes[SIGNATURE_LENGTH]
    isOfacCompliant: bool


# Fire whenever a validator is added
event ValidatorAdded:
    beneficiaryWallet: address
    validatorPublicKey: Bytes[PUBLIC_KEY_LENGTH]


# Fire whenever a validator is removed
event ValidatorRemoved:
    beneficiaryWallet: address
    validatorPublicKey: Bytes[PUBLIC_KEY_LENGTH]


# Fire whenever a `beneficiaryWallet`'s balance is added
event BalanceAdded:
    beneficiaryWallet: indexed(address)
    addedBalance: uint256


# Fire whenever a `beneficiaryWallet`'s balance is withdrawn
event BalanceWithdrawn:
    beneficiaryWallet: address
    previousBalance: uint256


################################################
# Contract Initialization and Default Function #
################################################

@external
@nonpayable
def __init__(oracleAddress: address,
             ofacVaultContractAddress: address,
             depositContractAddress: address,
             insuranceContractAddress: address,
             proxyContractAddress: address):

    # Set the contract's initial state
    self.admin = msg.sender
    self.oracleAddress = oracleAddress
    self.ofacVaultContractAddress = ofacVaultContractAddress
    self.ofacVaultContract = OFAC_Vault_Interface(ofacVaultContractAddress)
    self.depositContractAddress = depositContractAddress
    self.insuranceContractAddress = insuranceContractAddress
    self.proxyContractAddress = proxyContractAddress

    # Allow certain contract addresses to deposit here
    self.allowedDepositWallets[depositContractAddress] = True
    self.allowedDepositWallets[insuranceContractAddress] = True
    self.allowedDepositWallets[proxyContractAddress] = True

    # Store this as a public variable so we can read it from the oracle code
    assert WALLET_UPDATE_ARRAY_MAX_SIZE > 0, "The `walletUpdateArrayMaxSize` must be > 0."
    self.walletUpdateArrayMaxSize = WALLET_UPDATE_ARRAY_MAX_SIZE


@internal
@nonpayable
def _check(theAddress: address) -> bool:
    return self.ofacVaultContract.is_address_banned(theAddress)


@external
@payable
def __default__():

    # Only certain addresses can call this function
    assert self.allowedDepositWallets[msg.sender] == True, "You cannot send funds to this contract."


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
def set_ofac_vault_contract_address(newAddress: address) -> address:

    # Only the `admin` may change this address
    assert msg.sender == self.admin, "You cannot set the OFAC Vault contract address."

    # Set the new address and return the old one
    oldAddress: address = self.ofacVaultContractAddress
    self.ofacVaultContractAddress = newAddress
    self.ofacVaultContract = OFAC_Vault_Interface(newAddress)
    return oldAddress


@external
@nonpayable
def set_deposit_contract_address(newAddress: address) -> address:

    # Only the `admin` may change this address
    assert msg.sender == self.admin, "You cannot update the deposit contract address."

    # Set the new address and return the old one
    oldAddress: address = self.depositContractAddress
    self.depositContractAddress = newAddress
    self.allowedDepositWallets[oldAddress] = False
    self.allowedDepositWallets[newAddress] = True
    return oldAddress


@external
@nonpayable
def set_insurance_contract_address(newAddress: address) -> address:

    # Only the `admin` may change this address
    assert msg.sender == self.admin, "You cannot update the insurance contract address."

    # Set the new address and return the old one
    oldAddress: address = self.insuranceContractAddress
    self.insuranceContractAddress = newAddress
    self.allowedDepositWallets[oldAddress] = False
    self.allowedDepositWallets[newAddress] = True
    return oldAddress


@external
@nonpayable
def set_proxy_contract_address(newAddress: address) -> address:

    # Only the `admin` may change this address
    assert msg.sender == self.admin, "You cannot update the proxy contract address."

    # Set the new address and return the old one
    oldAddress: address = self.proxyContractAddress
    self.proxyContractAddress = newAddress
    self.allowedDepositWallets[oldAddress] = False
    self.allowedDepositWallets[newAddress] = True
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
def add_balance(walletUpdates: DynArray[WalletUpdate, WALLET_UPDATE_ARRAY_MAX_SIZE]):

    # Only allow the `oracleAddress` to call this function
    assert msg.sender == self.oracleAddress, "You cannot update a balance."

    # Iterate through each update and add it
    for walletUpdate in walletUpdates:

        # Ensure there is enough of a balance in the contract for these funds
        assert self.balance >= self.totalWalletBalance + walletUpdate.addedBalance, \
        "We do not have enough funds in the contract to update this balance. Add more!"

        # Add the `walletUpdate.addedBalance` to the `totalWalletBalance`
        self.totalWalletBalance += walletUpdate.addedBalance

        # Add more to the validator's balance. We cannot remove balance.
        self.walletBalances[walletUpdate.beneficiaryWallet] += walletUpdate.addedBalance

        # Send an event to any listeners
        log BalanceAdded(walletUpdate.beneficiaryWallet, walletUpdate.addedBalance)


@external
@nonpayable
def remove_invalid_waiting_validator(validatorPublicKey: Bytes[PUBLIC_KEY_LENGTH]):
    """ If a waiting validator is invalid, the oracle will remove it from the queue. """

    # Only allow the `oracleAddress` to call this function
    assert msg.sender == self.oracleAddress, "You cannot remove an invalid validator."

    # Ensure we can only remove waiting validators
    assert self.waitingValidators[validatorPublicKey] == True, \
    "The validator is not in the waiting queue."

    # The validator is no longer waiting
    self.waitingValidators[validatorPublicKey] = False

    # Decrement the number of waiting validators
    self.numWaitingValidators -= 1


@external
@nonpayable
def verify_validator(validatorPublicKey: Bytes[PUBLIC_KEY_LENGTH],
                     beneficiaryWallet: address) -> address:

    # Only allow the `oracleAddress` to call this function
    assert msg.sender == self.oracleAddress, "You cannot verify a validator."

    # Ensure the calling address is not banned
    assert self._check(beneficiaryWallet) == False, \
    "The beneficiary wallet is on the US Treasury's SDN list. We cannot do business with it."

    # Ensure the validator slot is open
    assert self.validators[validatorPublicKey] == empty(address), \
    "The validator was already added."

    # Ensure we only add a waiting validator
    assert self.waitingValidators[validatorPublicKey] == True, \
    "The validator is not in the waiting queue."

    # If we haven't failed, add the calling wallet at the validator key owner
    self.validators[validatorPublicKey] = beneficiaryWallet

    # The validator is no longer waiting
    self.waitingValidators[validatorPublicKey] = False

    # Decrement the number of waiting validators
    self.numWaitingValidators -= 1

    # Increment the number of validators counter
    self.numValidators += 1

    # Send an event to any listeners
    log ValidatorAdded(beneficiaryWallet, validatorPublicKey)

    # Return the wallet associated with the `validatorPublicKey` 
    return self.validators[validatorPublicKey]


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

    # Size sanity checks
    assert len(validatorPublicKey) == PUBLIC_KEY_LENGTH, \
    "The validator public key length is not correct. Please retry with a valid BLS public key."
    assert len(validatorSignedMessage) == MESSAGE_LENGTH, \
    "The signed message length is not correct. Please ensure you are using the signature generation script."
    assert len(validatorSignature) == SIGNATURE_LENGTH, \
    "The signature length is not correct. Please retry with a correct BLS signature."

    # Ensure the transaction origin is not banned
    assert self._check(tx.origin) == False, \
    "You are on the US Treasury's SDN list. We cannot do business with you."

    # Ensure the calling address is the proxy contract
    assert msg.sender == self.proxyContractAddress, \
    "You can only add a validator via the proxy contract."

    # Revert the transaction if someone has already added the validator.
    # It should be the zero address.
    assert self.validators[validatorPublicKey] == empty(address), \
    "Validator exists. Please remove using the original beneficiary's wallet."

    # Ensure the validator is not already waiting
    assert self.waitingValidators[validatorPublicKey] == False, \
    "The validator is already in the waiting queue."

    # Ensure someone has not already used the `validatorSignature`
    assert self.signatures[validatorSignature] == False, \
    "Signature already used to previously add a validator. Please re-sign a new message."

    # Add the `validatorSignature` to a hashmap in order to stop replay attacks
    self.signatures[validatorSignature] = True

    # Tag the validator as waiting
    self.waitingValidators[validatorPublicKey] = True

    # Increment the number of waiting validators
    self.numWaitingValidators += 1

    # Set the OFAC compliance boolean
    self.ofacCompliance[validatorPublicKey] = isOfacCompliant

    # Send an event to the oracle to verify a new validator
    log ValidatorQueued(tx.origin,
                        validatorPublicKey,
                        validatorSignedMessage,
                        validatorSignature,
                        isOfacCompliant)


@external
@nonpayable
def remove_validator(validatorPublicKey: Bytes[PUBLIC_KEY_LENGTH]) -> address:

    # Ensure the transaction origin is not banned
    assert self._check(tx.origin) == False, \
    "You are on the US Treasury's SDN list. We cannot do business with you."

    # Ensure the calling address is the proxy contract
    assert msg.sender == self.proxyContractAddress, \
    "You can only remove a validator via the proxy contract."

    # Only allow removal of existing validators
    assert self.validators[validatorPublicKey] != empty(address), "Validator does not exist."

    # Only allow the original wallet to remove a validator
    assert self.validators[validatorPublicKey] == tx.origin, \
    "Only the original beneficiary can remove a validator."

    # Ensure the validator is not already waiting
    assert self.waitingValidators[validatorPublicKey] == False, \
    "Please wait until the validator is out of the waiting queue before removal."

    # Remove the validator
    self.validators[validatorPublicKey] = empty(address)

    # Decrement the number of validators counter
    self.numValidators -= 1

    # Send an event to any listeners
    log ValidatorRemoved(tx.origin, validatorPublicKey)

    # Return the wallet associated with the `validatorPublicKey` 
    # It should be `empty(address)`
    return self.validators[validatorPublicKey]


@external
@nonpayable
@nonreentrant("withdraw")
def withdraw(amount: uint256) -> uint256:
    """ Withdraw a partial beneficiary wallet's balance. """

    # Ensure the transaction origin is not banned
    assert self._check(tx.origin) == False, \
    "You are on the US Treasury's SDN list. We cannot do business with you."

    # Ensure the calling address is the proxy contract
    assert msg.sender == self.proxyContractAddress, \
    "You can only withdraw from your balance via the proxy contract."

    # Ensure the caller has a balance that can cover the request
    assert self.walletBalances[tx.origin] >= amount, \
    "You do not have enough balance to withdraw that amount."

    # Ensure we have enough funds in the contract
    assert amount <= self.balance, "We can't withdraw more than what is in the contract."

    # Remove the withdraw amount from the balance
    self.walletBalances[tx.origin] -= amount

    # Remove the balance from the `totalWalletBalance`
    self.totalWalletBalance -= amount

    # Send any balance to the caller
    send(tx.origin, amount)

    # Send an event to any listeners
    log BalanceWithdrawn(tx.origin, amount)

    # Return the new balance
    return self.walletBalances[tx.origin]


@external
@nonpayable
@nonreentrant("withdraw_all")
def withdraw_all() -> uint256:
    """ Withdraw the entire beneficiary wallet's balance. """

    # Ensure the transaction origin is not banned
    assert self._check(tx.origin) == False, \
    "You are on the US Treasury's SDN list. We cannot do business with you."

    # Ensure the calling address is the proxy contract
    assert msg.sender == self.proxyContractAddress, \
    "You can only withdraw from your balance via the proxy contract."

    # Ensure the caller has a balance
    assert self.walletBalances[tx.origin] > 0, "You do not have any balance."

    # The entire balance is the amount
    amount: uint256 = self.walletBalances[tx.origin]

    # Ensure we have enough funds in the contract
    assert amount <= self.balance, "We can't withdraw more than what is in the contract."

    # Remove the entire balance
    self.walletBalances[tx.origin] = 0

    # Remove the balance from the `totalWalletBalance`
    self.totalWalletBalance -= amount

    # Send any balance to the caller
    send(tx.origin, amount)

    # Send an event to any listeners
    log BalanceWithdrawn(tx.origin, amount)

    # Return the new balance
    return 0