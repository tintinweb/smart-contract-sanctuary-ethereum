# @version ^0.3.0


#############
# Constants #
#############

SDN_UPDATE_ARRAY_MAX_SIZE: constant(uint256) = 1000  # Must be > 0
sdnUpdateArrayMaxSize: public(uint256)  # We need this value when running the oracle


###########
# Structs #
###########

# Use in a `DynArray` to ban multiple addresses at once in order to save gas.
struct SdnUpdate:
    beneficiaryWallet: address
    addedBalance: uint256


###################
# State Variables #
###################

# The wallet who can update the `feeCollector` and `balanceUpdater` addresses
# It can also update the `feePercent`
admin: public(address)

# The wallet who can add and remove banned addresses
oracleAddress: public(address)

# The deposit contract, which sends funds to this contract
depositContractAddress: public(address)

# We don't allow wallets on the Office of Foreign Asset Control (OFAC) list of
# Specially Designated Nationals and Blocked Persons ("SDN List"):
# https://www.treasury.gov/ofac/downloads/sdnlist.txt
# https://home.treasury.gov/policy-issues/office-of-foreign-assets-control-sanctions-programs-and-information
# `True` if banned, `False` (default) if allowed.
isAddressBanned: public(HashMap[address, bool])

# The current number of banned addresses
numBannedAddresses: public(uint256)

# The wallet used to send unfrozen funds to. It is the same entity that insures withdrawals.
beneficiaryWallet:public(address)

# The ledger of frozen funds
frozenLedger: public(HashMap[address, uint256])

# The total frozen funds
totalFrozenFunds: public(uint256)


##########
# Events #
##########

# Fire whenver an address is banned
event AddressBanned:
    bannedAddress: address

# Fire whenver an address is unbanned
event AddressUnbanned:
    unbannedAddress: address


################################################
# Contract Initialization and Default Function #
################################################

@external
@nonpayable
def __init__(oracleAddress: address,
             depositContractAddress: address,
             beneficiaryWallet: address):

    # Set the contract's initial state
    self.admin = msg.sender
    self.oracleAddress = oracleAddress
    self.depositContractAddress = depositContractAddress

    # The wallet used to send unfrozen funds to. It is the same entity that insures withdrawals.
    self.beneficiaryWallet = beneficiaryWallet

    # Store this as a public variable so we can read it from the oracleAddress code
    assert SDN_UPDATE_ARRAY_MAX_SIZE > 0, "The `sdnUpdateArrayMaxSize` must be > 0."
    self.sdnUpdateArrayMaxSize = SDN_UPDATE_ARRAY_MAX_SIZE


@external
@payable
def __default__():

    # Only allow the `depositContractAddress` to call this function
    assert msg.sender == self.depositContractAddress, "You cannot send funds to this contract."


############################
# Administrative Functions #
############################

@external
@nonpayable
def set_admin_address(admin: address) -> address:

    # Only allow the `admin` to call this function
    assert msg.sender == self.admin, "You cannot update the admin address."

    # Set a new admin address
    self.admin = admin

    # Return the new admin address
    return self.admin


@external
@nonpayable
def set_oracle_address(newAddress: address) -> address:

    # Only allow the `admin` to call this function
    assert msg.sender == self.admin, "You cannot update the oracle address."

    # Set the new oracle address and return the old one
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
def set_beneficiary_wallet_address(beneficiaryWallet: address) -> address:

    # Only allow the `admin` to call this function
    assert msg.sender == self.admin, "You cannot update the beneficiary wallet address."

    # Set the new beneficiary wallet address and return the old one
    oldAddress: address = self.beneficiaryWallet
    self.beneficiaryWallet = beneficiaryWallet
    return self.beneficiaryWallet


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
def update_balance(sdnWallet: address,
                   amount: uint256):

    # Only allow the `oracleAddress` to call this function
    assert msg.sender == self.oracleAddress, "You cannot update the balance of an SDN wallet."

    # The sdnWallet must be banned
    assert self.isAddressBanned[sdnWallet] == True, \
    "The wallet address must be banned before calling this function."

    # We need enough funds in the contract to update the balance
    assert self.balance >= self.totalFrozenFunds + amount, "Not enough balance in the contract."

    # Update the internal ledger of frozen funds for the SDN wallet
    self.frozenLedger[sdnWallet] += amount
    self.totalFrozenFunds += amount


@external
@nonpayable
def ban_address(addressesToBan: DynArray[address, SDN_UPDATE_ARRAY_MAX_SIZE]):

    # Only allow the `oracleAddress` to call this function
    assert msg.sender == self.oracleAddress, "You cannot ban an address."

    # Iterate through each address
    for addressToBan in addressesToBan:

        # You can't ban an already banned address
        assert self.isAddressBanned[addressToBan] == False, \
        "The address is already banned."

        # Add the address to the banned address list
        self.isAddressBanned[addressToBan] = True

        # Increment the banned address counter
        self.numBannedAddresses += 1

        # Send an event to any listeners
        log AddressBanned(addressToBan)


@external
@nonpayable
@nonreentrant("unban_address")
def unban_address(addressesToUnban: DynArray[address, SDN_UPDATE_ARRAY_MAX_SIZE]):

    # Only allow the `oracleAddress` to call this function
    assert msg.sender == self.oracleAddress, "You cannot unban an address."

    # Iterate through each address
    for addressToUnban in addressesToUnban:

        # You can't unban an address that isn't already banned
        assert self.isAddressBanned[addressToUnban] == True, \
        "The address is not banned."

        # Send the balance of the banned address to the beneficiaryWallet
        unfrozenFunds: uint256 = self.frozenLedger[addressToUnban]

        # Ensure we have enough funds in the contract
        assert unfrozenFunds <= self.balance, "We can't unfreeze more than what is in the contract."

        # Remove the address from the banned address list
        self.isAddressBanned[addressToUnban] = False

        # Decrement the banned address counter
        self.numBannedAddresses -= 1

        # If there are funds, send them
        if unfrozenFunds > 0:
            assert self.balance >= unfrozenFunds, \
            "Not enough funds in the contract to unban the SDN Address"
            send(self.beneficiaryWallet, unfrozenFunds)
            self.frozenLedger[addressToUnban] = 0
            self.totalFrozenFunds -= unfrozenFunds

        # Send an event to any listeners
        log AddressUnbanned(addressToUnban)


##################
# User Functions #
##################

@external
@nonpayable
def is_address_banned(theAddress: address) -> bool:

    # Return if an address is banned or not
    return self.isAddressBanned[theAddress]