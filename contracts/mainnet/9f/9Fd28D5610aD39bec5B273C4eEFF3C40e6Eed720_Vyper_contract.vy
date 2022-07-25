# @version >=0.3.3
"""
@title The Bit Tulip Contract
@dev Implementation of ERC-1155 non-fungible token standard ownable, with approval, OPENSEA compatible (name, symbol)
@author Dr. Pixel (github: @Doc-Pixel) -- modified by Josh Cincinnati (github: @acityinohio)
"""
############### imports ###############
from vyper.interfaces import ERC165

############### variables ###############
# maximum items in a batch call. Set to 128, to be determined what the practical limits are.
BATCH_SIZE: constant(uint256) = 128             

# callback number of bytes
CALLBACK_NUMBYTES: constant(uint256) = 4096

# URI length set to 10000. (yay on-chain) 
MAX_URI_LENGTH: constant(uint256) = 10000       

# the contract owner
# not part of the core spec but a common feature for NFT projects
owner: public(address)                          

# pause status True / False
# not part of the core spec but a common feature for NFT projects
paused: public(bool)                            

# the contracts URI to find the metadata
_uri: String[MAX_URI_LENGTH]

# NFT marketplace compatibility
name: public(String[128])
symbol: public(String[16])

# Interface IDs
ERC165_INTERFACE_ID: constant(bytes4)  = 0x01ffc9a7
ERC1155_INTERFACE_ID: constant(bytes4) = 0xd9b67a26
ERC1155_INTERFACE_ID_METADATA: constant(bytes4) = 0x0e89341c

# mappings

# Mapping from token ID to account balances
balanceOf: public(HashMap[address, HashMap[uint256, uint256]])

# Mapping from account to operator approvals
isApprovedForAll: public( HashMap[address, HashMap[address, bool]])

############### events ###############
event Paused:
    # Emits a pause event with the address that paused the contract
    account: address

event unPaused:
    # Emits an unpause event with the address that paused the contract
    account: address

event OwnershipTransferred:
    # Emits smart contract ownership transfer from current to new owner
    previousOwner: address 
    newOwner: address

event TransferSingle:
    # Emits on transfer of a single token
    operator:   indexed(address)
    fromAddress: indexed(address)
    to: indexed(address)
    id: uint256
    value: uint256

event TransferBatch:
    # Emits on batch transfer of tokens. the ids array correspond with the values array by their position
    operator: indexed(address) # indexed
    fromAddress: indexed(address)
    to: indexed(address)
    ids: DynArray[uint256, BATCH_SIZE]
    values: DynArray[uint256, BATCH_SIZE]

event ApprovalForAll:
    # This emits when an operator is enabled or disabled for an owner. The operator manages all tokens for an owner
    account: indexed(address)
    operator: indexed(address)
    approved: bool

event URI:
    # This emits when the URI gets changed
    value: String[MAX_URI_LENGTH]
    id: uint256

############### interfaces ###############
implements: ERC165

interface IERC1155Receiver:
    def onERC1155Received(
       operator: address,
       sender: address,
       id: uint256,
       amount: uint256,
       data: Bytes[CALLBACK_NUMBYTES],
   ) -> bytes32: payable
    def onERC1155BatchReceived(
        operator: address,
        sender: address,
        ids: DynArray[uint256, BATCH_SIZE],
        amounts: DynArray[uint256, BATCH_SIZE],
        data: Bytes[CALLBACK_NUMBYTES],
    ) -> bytes4: payable

interface IERC1155MetadataURI:
    def uri(id: uint256) -> String[MAX_URI_LENGTH]: view

############### functions ###############

@external
def __init__():
    """
    @dev contract initialization on deployment
    @dev will set name and symbol, interfaces, owner and URI
    @dev self.paused will default to false
    @dev rather than use params, setting all info here manually
    @param name the smart contract name
    @param symbol the smart contract symbol
    @param uri the new uri for the contract
    """
    self.name = "Bit Tulip"
    self.symbol = "BITTULIP"
    self.owner = msg.sender
    # base64 encoded string for URI
    self._uri = "data:application/json;base64,ewogICJuYW1lIjoiQml0IFR1bGlwIiwKICAiZGVzY3JpcHRpb24iOiJBbiBvbi1jaGFpbiByZXByZXNlbnRhdGlvbiBvZiBhIHR1bGlwIHRoYXQgc2lnbmlmaWVzIHBhcnRpY2lwYXRpb24gaW4gdGhlIGJpdGJhbnRlciBib29rIHJhZmZsZS4gVmFsdWUgdW5jbGVhci4iLAogICJpbWFnZSI6ImRhdGE6aW1hZ2UvcG5nO2Jhc2U2NCxpVkJPUncwS0dnb0FBQUFOU1VoRVVnQUFBUUFBQUFFQUNBWUFBQUJjY3FobUFBQUFCbUpMUjBRQS93RC9BUCtndmFlVEFBQUFDWEJJV1hNQUFDNGpBQUF1SXdGNHBUOTJBQUFBQjNSSlRVVUg1Z1lLRVRnT0FmY2ZRQUFBQUJsMFJWaDBRMjl0YldWdWRBQkRjbVZoZEdWa0lIZHBkR2dnUjBsTlVGZUJEaGNBQUFseFNVUkJWSGphN2QxYmpGeDFIUWZ3bloyWjNiYmI3bTRSWVZ0NkI5bzBhckVJZ2FCQlJVbElUQXdSTldvaTFLREdpTUZJWWtpODRRdUphQ1NpeEFpbW9ieWdDVEVOSWhFRHlJTkU0d04zVWxvdXRSZlVVbWwzdXp1NzNabWQzZlhKRnhOL2Y1TS9wMmQyNXZONS9hWTc1emJmL2lmLy96bW4wdGZYdDloSDE2cFVxMkcrT0Q4ZjVuZmR0alBNZi9tcmcyRys3N1hKTUY5WWNQbVZxZDhoQUFVQUtBQkFBUUFLQUZBQWdBSUF1azJ0MXcvQXVuUGpRL0RkcjIwTDg0TkhwOFA4am5zUGxicC9xWG4rM1hkY0h1YVhYYlFxekk4ZE94SG1ieHlMajgvRVpMdlEvZi9pcDllRWVhV3ZFdWEvZnVSNG1FOU50NWYwOVc4RUFINENBQW9BVUFDQUFnQVVBS0FBZ0s1VDZldng1d0hzMkRZWTVyKzk5d05odnZIS3g0czlRWlY0bm5yOW1tVmgvdURQRS9QODF6Nlp0WDNOMlhpZS80T1hqWVg1WDE5b1pIMys5ZGVlRStiMzczMHo2KzkvODB1Yncvekh1dytIK2VKaVozKzlqQURBVHdCQUFRQUtBRkFBZ0FJQUZBRFFkVHIrZVFCYjFzZjNveDg4T3BYM0FZbHAyc1pNM3YzZXFYbjgxRHh4S3IvdmpvdkMvTktQUFZMcTltOWVINit6U0swRHVQN2FjOFA4L3IzSENyMytUazAydzN4NEtENCtweHJXQVFBS0FGQUFnQUlBRkFDZ0FBQUZBSnhScGE4RDJMeHVaWmkvZm1ReTYrOWZzWE0wekhkOWNsMllGMzA3ZCs0OCt4ZHVmYjdRN2N1OW4zMzhWTHlPWXNmV2VKMUE3anovMnJGNEhjRS9qc1hQQzdodzg0b3czM3ZQKzhQOGQzODhHdVozN2o1a0JBQW9BRUFCQUFvQVVBQ0FBZ0FVQVBCMjZ2ajNBcFQ5WFBXWEgvdG9tRy85MEVOaFhodFkyZEg3dCtRdjRNUTZpcUt2cjJQUGZEYk1ILzc5eTJIKzVlODhYK3J4TXdJQVB3RUFCUUFvQUVBQkFBb0FVQUJBMXluOWVRQkZ6NFBuM20rLy9lckhPM3IveHNiV2h2bmtWUHc4aGY3KytQK0E2Y1pVcWZ0ZjlqeC95aXNIM2dqekg5N3pzaEVBb0FBQUJRQW9BRUFCQUFvQVVBREFtVlRyOVFQUTZmUE1LZU1UNDFuYmw4b0hseTJQTDZCYWIxOUMrMTZOMTFuTXpIYjI4eDZNQU1CUEFFQUJBQW9BVUFDQUFnQVVBTkIxU3AvRXZmUGI3d3Z6VzI1L3VxTVBZTzd6QnJJYnZCSjMrUHpDZkppMzU5cnh2Mi9ILzc3VmJJWDV5T2pxTUQrVnVZNmg3UE8zL2Z6QjFDY1lBUUFLQUZBQWdBSUFGQUNnQUFBRkFKeEp5WFVBd3l2cllUN1ptTXZhZ0FjZWVqWE1iN2w5YVIvZ290Y0p6TTdPaEhtOUhzOVRwOTRMa05xKzFQNU5ucHJvNk9PZmEzNStNWEY4UFE4QVVBQ0FBZ0FVQUtBQUFBVUFLQURnakVxdUF6ZzFGZC92dldQN1dXSCs0djc0ZnUrM3htZkQvTkU5SHduemEzWTlzYVJQUU80NmdkeDUrdFE2Z2R6UEwvdjREUTdrcllOSWZqOGFDMkcrZnMxQW1JK3NUSnoveFBNRWpwL3NTM3kvbWtZQWdBSUFGQUNnQUFBRkFBb0FVQUJBYjZuMDlmV0ZFN2xGei9OdVdiOHN6SGRkdHlITXYvZVRWL0lPUUtXeXBFOWc3dmxKN2YvQVFIeCtXcTNaVXJldlZxc25ML0RJWEh1dXI4enJ2MmhEcTVZYkFRQUtBRkFBZ0FJQUZBQW9BRUFCQUwwbCtUeUFSL2Q4T015djJmVmsxZ1ljUERwYjZnSEl2WjgrWmZsZ2ZEOTZlejYrbnp3MVQxMzBld2ZxdFdxWU41dkZ6dk12VzdZODhmbng4eXFxMWY1Q3Q2OXNxZk03dW1yQUNBQlFBSUFDQUJRQW9BQkFBUUFLQU9ndHllY0JiTnN5RXY2Qi9hL252Zjg5ZDU2MTArL1hIbGs1Rk9iTnVjVDk2SlY0SHI3VnpMc2Z2K2gxQkxubnQxYUw1N0hiN1ZaWGYwRnpqLy9veUtBUkFLQUFBQVVBS0FCQUFZQUNBQlFBMEZ1UzZ3QlNidDYxTGN6dnVtOS8xZ1p1MnJBbXpFZFd4UFBFTHh3NGt2WDV1Zk93bCsvY0d1YlA3VHVVT0VOeFJ6ZWJ6VUszUDNrQkxmSDNLaFN0Nk9OLzRZYjR2UWl2SFcwYkFRQUtBRkFBZ0FJQUZBQW9BRUFCQUwwbGV4MUF5azAzdkRmTTc5N3piS0U3dUduanVqQS9mT1R2V1g4L2Q1NzN2TEYzaFBuRTVFejgrWWwxQXFuTk96MHpuWGNCWmE0REdCcGFGZWJUMDFPbGZrR0tuc2ZmODZOM2gvbWJiN1grajYvdy96YlZXRFFDQUJRQW9BQUFCUUFvQUZBQWdBSUFla3ZoNndCU05tMko1K2x2L3Z5N3d2d2IzMyswcDAvZzhLcmhNSitjbW5TVll3UUFLQUJBQVFBS0FCUUFvQUFBQlFEMGp0TFhBZFRydFRDLytvcjR2UUNYdkdkRm1HKy80T3d3Lzh6WG40b1BVTW5QdlMvN3VmNUZmMzdIZjBHNi9Qd2JBWUNmQUlBQ0FCUUFvQUFBQlFBb0FLRHIxTXJlZ0tzdUh3bnpTM2ZFOC95My91RHB1T0ZLcnJpUmtlR3NmMy9XNnRFd1B6aytFZWE1OC94bHo0T1hyZFBYUWVTZUh5TUE4Qk1BVUFDQUFnQVVBS0FBQUFVQWRKM3NkUUMxV2pYTWIvelUrakQveFFOL0szUUhMN2w0WjVnLy9leHpoWDcrZkxzZDV0VnFmUHlXMWVPT0xucWV2dGVmQjNCNlpqck1iN254Z2pCLzdLbTN3dnoxTjlwR0FJQUNBQlFBb0FBQUJRQW9BRUFCQUcrbjdQY0NiTjI4S3N6M0hmaG5tRmZyUS9FR2R2bjk2TDArejU3clcxL1pHT1lueHB0aC9zU2ZUOFQvZm1JaHpDY2FDMFlBZ0FJQUZBQ2dBQUFGQUNnQVFBRUFuU1I3SFVCLzRuNzJyOTV3YVpqL2JQZGZuSVdjRTVpNVRtTG54UmVIK2JQUFBKUDE5M1BYT2R4OTI0VmgvdE05aDhMODFTTnRGNGtSQUtBQUFBVUFLQUJRQUE0QktBQkFBUUM5SkhzZFFLNXE0cjBDdFVSRlZmdmp6VDkvdzBDWXYzRGc5TkkrZ1puckFGYVBqb1o1YXk2ZVI1K2VibVI5ZnU0NmdXMmI2bUgreW1IckFJd0FBQVVBS0FCQUFRQUtBQlFBb0FDQW5sTDZPb0N5blROMmRwaWYrODc0dlFmbmpRMkhlYTBTcnpONCtBOEg4azVnd2U5TkdCbU85Mjh1c1U1ZzV2Uk0xdWZucmhQbzl2ZEtHQUVBQ2dCUUFJQUNBQlFBb0FBQUJRRDhsNTVmQjNCR2puQmdjYUhZdzkvdDgrQ3BkUUl6TTlOaHZubkQ2akEvZm1MT0NBQlFBSUFDQUJRQW9BQUFCUUFvQUdBcHNRNmdZTlY2L042RGRxdmM1OVl2dE9QNzlSZm1Fdmw4blBmWFZtVGwyZnVYV0dmeDFHK3VDdlByYm5vcHpFK096eXpwNjlNSUFQd0VBQlFBb0FBQUJRQW9BRUFCQUYybjVoQVVhKzNhTlZuL1BuVS9mKzV6OC8vMS9PZkNmSzUxT3JHQjFjejk2MHZzWDV5M1cvSDkrc2RQTnNQOHhmMVRZVDdaYUJvQkFBb0FVQUNBQWdBVUFLQUFBQVVBTENXZUIxQ3dScU1SNWtORFEvRUp5bHdIY09VblBoN21mOXI3c0pOa0JBQW9BRUFCQUFvQVVBQ0FBZ0FVQU5BOVBBOGdVNlUvbnFmUG5lZlBkZmlsbDV3a2pBQUFCUUFvQUVBQmdBSUFGQUNnQUlEZTRYa0FtZXJMNjJIZW1tbkZKeUJ6SFVEcWVRQkZyelBBQ0FCUUFJQUNBQlFBb0FBQUJRQW9BS0NqV0FlUUtUVVBuendCbWMvOXovMzdHQUVBQ2dCUUFJQUNBQlFBb0FBQUJRQjBGZThGU0IyZ3dXSVBVZTQ4ZjMydzZpUmhCQUFvQUVBQkFBb0FVQUNBQWdBVUFQQWYvd1pVRTF1Q21vWFYxd0FBQUFCSlJVNUVya0pnZ2c9PSIKfQo="

## contract status ##
@external
def pause():
    """
    @dev Pause the contract, checks if the caller is the owner and if the contract is paused already
    @dev emits a pause event 
    @dev not part of the core spec but a common feature for NFT projects
    """
    assert self.owner == msg.sender, "Ownable: caller is not the owner"
    assert not self.paused, "the contract is already paused"
    self.paused = True
    log Paused(msg.sender)

@external
def unpause():
    """
    @dev Unpause the contract, checks if the caller is the owner and if the contract is paused already
    @dev emits an unpause event 
    @dev not part of the core spec but a common feature for NFT projects
    """
    assert self.owner == msg.sender, "Ownable: caller is not the owner"
    assert self.paused, "the contract is not paused"
    self.paused = False
    log unPaused(msg.sender)

## ownership ##
@external
def transferOwnership(newOwner: address):
    """
    @dev Transfer the ownership. Checks for contract pause status, current owner and prevent transferring to
    @dev zero address
    @dev emits an OwnershipTransferred event with the old and new owner addresses
    @param newOwner The address of the new owner.
    """
    assert not self.paused, "The contract has been paused"
    assert self.owner == msg.sender, "Ownable: caller is not the owner"
    assert newOwner != self.owner, "This account already owns the contract"
    assert newOwner != ZERO_ADDRESS, "Transfer to ZERO_ADDRESS not allowed. Use renounceOwnership() instead."
    oldOwner: address = self.owner
    self.owner = newOwner
    log OwnershipTransferred(oldOwner, newOwner)

@external
def renounceOwnership():
    """
    @dev Transfer the ownership to ZERO_ADDRESS, this will lock the contract
    @dev emits an OwnershipTransferred event with the old and new ZERO_ADDRESS owner addresses
    """
    assert not self.paused, "The contract has been paused"
    assert self.owner == msg.sender, "Ownable: caller is not the owner"
    oldOwner: address = self.owner
    self.owner = ZERO_ADDRESS
    log OwnershipTransferred(oldOwner, ZERO_ADDRESS)

@external
@view
def balanceOfBatch(accounts: DynArray[address, BATCH_SIZE], ids: DynArray[uint256, BATCH_SIZE]) -> DynArray[uint256,BATCH_SIZE]:  # uint256[BATCH_SIZE]:
    """
    @dev check the balance for an array of specific IDs and addresses
    @dev will return an array of balances
    @dev Can also be used to check ownership of an ID
    @param accounts a dynamic array of the addresses to check the balance for
    @param ids a dynamic array of the token IDs to check the balance
    """
    assert len(accounts) == len(ids), "ERC1155: accounts and ids length mismatch"
    batchBalances: DynArray[uint256, BATCH_SIZE] = []
    j: uint256 = 0
    for i in ids:
        batchBalances.append(self.balanceOf[accounts[j]][i])
        j += 1
    return batchBalances

## mint ##
@external
def mint(receiver: address, id: uint256, amount:uint256, data:bytes32):
    """
    @dev mint one new token with a certain ID
    @dev this can be a new token or "topping up" the balance of a non-fungible token ID
    @param receiver the account that will receive the minted token
    @param id the ID of the token
    @param amount of tokens for this ID
    @param data the data associated with this mint. Usually stays empty
    """
    assert not self.paused, "The contract has been paused"
    assert self.owner == msg.sender, "Only the contract owner can mint"
    assert receiver != ZERO_ADDRESS, "Can not mint to ZERO ADDRESS"
    operator: address = msg.sender
    self.balanceOf[receiver][id] += amount
    log TransferSingle(operator, ZERO_ADDRESS, receiver, id, amount)


@external
def mintBatch(receiver: address, ids: DynArray[uint256, BATCH_SIZE], amounts: DynArray[uint256, BATCH_SIZE], data: bytes32):
    """
    @dev mint a batch of new tokens with the passed IDs
    @dev this can be new tokens or "topping up" the balance of existing non-fungible token IDs in the contract
    @param receiver the account that will receive the minted token
    @param ids array of ids for the tokens
    @param amounts amounts of tokens for each ID in the ids array
    @param data the data associated with this mint. Usually stays empty
    """
    assert not self.paused, "The contract has been paused"
    assert self.owner == msg.sender, "Only the contract owner can mint"
    assert receiver != ZERO_ADDRESS, "Can not mint to ZERO ADDRESS"
    assert len(ids) == len(amounts), "ERC1155: ids and amounts length mismatch"
    operator: address = msg.sender
    
    for i in range(BATCH_SIZE):
        if i >= len(ids):
            break
        self.balanceOf[receiver][ids[i]] += amounts[i]
    
    log TransferBatch(operator, ZERO_ADDRESS, receiver, ids, amounts)

## burn ##
@external
def burn(id: uint256, amount: uint256):
    """
    @dev burn one or more token with a certain ID
    @dev the amount of tokens will be deducted from the holder's balance
    @param receiver the account that will receive the minted token
    @param id the ID of the token to burn
    @param amount of tokens to burnfor this ID
    """
    assert not self.paused, "The contract has been paused"
    assert self.balanceOf[msg.sender][id] > 0 , "caller does not own this ID"
    self.balanceOf[msg.sender][id] -= amount
    log TransferSingle(msg.sender, msg.sender, ZERO_ADDRESS, id, amount)
    
@external
def burnBatch(ids: DynArray[uint256, BATCH_SIZE], amounts: DynArray[uint256, BATCH_SIZE]):
    """
    @dev burn a batch of tokens with the passed IDs
    @dev this can be burning non fungible tokens or reducing the balance of existing non-fungible token IDs in the contract
    @dev inside the loop ownership will be checked for each token. We can not burn tokens we do not own
    @param ids array of ids for the tokens to burn
    @param amounts array of amounts of tokens for each ID in the ids array
    """
    assert not self.paused, "The contract has been paused"
    assert len(ids) == len(amounts), "ERC1155: ids and amounts length mismatch"
    operator: address = msg.sender 
    
    for i in range(BATCH_SIZE):
        if i >= len(ids):
            break
        self.balanceOf[msg.sender][ids[i]] -= amounts[i]
    
    log TransferBatch(msg.sender, msg.sender, ZERO_ADDRESS, ids, amounts)

## approval ##
@external
def setApprovalForAll(owner: address, operator: address, approved: bool):
    """
    @dev set an operator for a certain NFT owner address
    @param account the NFT owner address
    @param operator the operator address
    """
    assert owner == msg.sender, "You can only set operators for your own account"
    assert not self.paused, "The contract has been paused"
    assert owner != operator, "ERC1155: setting approval status for self"
    self.isApprovedForAll[owner][operator] = approved
    log ApprovalForAll(owner, operator, approved)

@external
def safeTransferFrom(sender: address, receiver: address, id: uint256, amount: uint256, bytes: bytes32):
    """
    @dev transfer token from one address to another.
    @param sender the sending account (current owner)
    @param receiver the receiving account
    @param id the token id that will be sent
    @param amount the amount of tokens for the specified id
    """
    assert not self.paused, "The contract has been paused"
    assert receiver != ZERO_ADDRESS, "ERC1155: transfer to the zero address"
    assert sender != receiver
    assert sender == msg.sender or self.isApprovedForAll[sender][msg.sender], "Caller is neither owner nor approved operator for this ID"
    assert self.balanceOf[sender][id] > 0 , "caller does not own this ID or ZERO balance"
    operator: address = msg.sender
    self.balanceOf[sender][id] -= amount
    self.balanceOf[receiver][id] += amount
    log TransferSingle(operator, sender, receiver, id, amount)

@external
def safeBatchTransferFrom(sender: address, receiver: address, ids: DynArray[uint256, BATCH_SIZE], amounts: DynArray[uint256, BATCH_SIZE], _bytes: bytes32):
    """
    @dev transfer tokens from one address to another.
    @param sender the sending account
    @param receiver the receiving account
    @param ids a dynamic array of the token ids that will be sent
    @param amounts a dynamic array of the amounts for the specified list of ids.
    """
    assert not self.paused, "The contract has been paused"
    assert receiver != ZERO_ADDRESS, "ERC1155: transfer to the zero address"
    assert sender != receiver
    assert sender == msg.sender or self.isApprovedForAll[sender][msg.sender], "Caller is neither owner nor approved operator for this ID"
    assert len(ids) == len(amounts), "ERC1155: ids and amounts length mismatch"
    operator: address = msg.sender
    for i in range(BATCH_SIZE):
        if i >= len(ids):
            break
        id: uint256 = ids[i]
        amount: uint256 = amounts[i]
        self.balanceOf[sender][id] -= amount
        self.balanceOf[receiver][id] += amount
    
    log TransferBatch(operator, sender, receiver, ids, amounts)

# URI #
@external
def setURI(uri: String[MAX_URI_LENGTH]):
    """
    @dev set the URI for the contract
    @param uri the new uri for the contract
    """
    assert not self.paused, "The contract has been paused"
    assert self._uri != uri, "new and current URI are identical"
    assert msg.sender == self.owner, "Only the contract owner can update the URI"
    self._uri = uri
    log URI(uri, 0)

@external
@view
def uri(id: uint256) -> String[MAX_URI_LENGTH]:
    """
    @dev retrieve the uri, this function can optionally be extended to return dynamic uris. out of scope.
    @param id NFT ID to retrieve the uri for. 
    """
    return self._uri

@pure
@external
def supportsInterface(interfaceId: bytes4) -> bool:
    """
    @dev Returns True if the interface is supported
    @param interfaceID bytes4 interface identifier
    """
    return interfaceId in [
        ERC165_INTERFACE_ID,
        ERC1155_INTERFACE_ID,
        ERC1155_INTERFACE_ID_METADATA, 
    ]