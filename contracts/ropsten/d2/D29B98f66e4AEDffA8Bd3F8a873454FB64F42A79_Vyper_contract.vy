# @version 0.3.3
"""
@title Turnstone-EVM
@author Volume.Finance
"""

MAX_VALIDATORS: constant(uint256) = 320
MAX_PAYLOAD: constant(uint256) = 20480

POWER_THRESHOLD: constant(uint256) = 2_863_311_530 # 2/3 of 2^32, Validator powers will be normalized to sum to 2 ^ 32 in every valset update.
TURNSTONE_ID: immutable(bytes32)

struct Valset:
    validators: DynArray[address, MAX_VALIDATORS] # Validator addresses
    powers: DynArray[uint256, MAX_VALIDATORS] # Powers of given validators, in the same order as validators array
    valset_id: uint256 # nonce of this validator set

struct Signature:
    v: uint256
    r: uint256
    s: uint256

struct Consensus:
    valset: Valset # Valset data
    signatures: DynArray[Signature, MAX_VALIDATORS] # signatures in the same order as validator array in valset

struct LogicCallArgs:
    logic_contract_address: address # the arbitrary contract address to external call
    payload: Bytes[MAX_PAYLOAD] # payloads

event ValsetUpdated:
    checkpoint: bytes32
    valset_id: uint256

event LogicCallEvent:
    logic_contract_address: address
    payload: Bytes[MAX_PAYLOAD]
    message_id: uint256

last_checkpoint: public(bytes32)
message_id_used: public(HashMap[uint256, bool])

# turnstone_id: unique identifier for turnstone instance
# valset: initial validator set
@external
def __init__(turnstone_id: bytes32, valset: Valset):
    TURNSTONE_ID = turnstone_id
    cumulative_power: uint256 = 0
    i: uint256 = 0
    # check cumulative power is enough
    for validator in valset.validators:
        cumulative_power += valset.powers[i]
        if cumulative_power >= POWER_THRESHOLD:
            break
        i += 1
    assert cumulative_power >= POWER_THRESHOLD, "Insufficient Power"
    new_checkpoint: bytes32 = keccak256(_abi_encode(valset.validators, valset.powers, valset.valset_id, turnstone_id, method_id=method_id("checkpoint(address[],uint256[],uint256,bytes32)")))
    self.last_checkpoint = new_checkpoint
    log ValsetUpdated(new_checkpoint, valset.valset_id)

@external
@pure
def turnstone_id() -> bytes32:
    return TURNSTONE_ID

# utility function to verify EIP712 signature
@internal
@pure
def verify_signature(signer: address, hash: bytes32, sig: Signature) -> bool:
    message_digest: bytes32 = keccak256(concat(convert("\x19Ethereum Signed Message:\n32", Bytes[28]), hash))
    return signer == ecrecover(message_digest, sig.v, sig.r, sig.s)

# consensus: validator set and signatures
# hash: what we are checking they have signed
@internal
def check_validator_signatures(consensus: Consensus, hash: bytes32):
    i: uint256 = 0
    cumulative_power: uint256 = 0
    for sig in consensus.signatures:
        if sig.v != 0:
            assert self.verify_signature(consensus.valset.validators[i], hash, sig), "Invalid Signature"
            cumulative_power += consensus.valset.powers[i]
            if cumulative_power >= POWER_THRESHOLD:
                break
        i += 1
    assert cumulative_power >= POWER_THRESHOLD, "Insufficient Power"

# Make a new checkpoint from the supplied validator set
# A checkpoint is a hash of all relevant information about the valset. This is stored by the contract,
# instead of storing the information directly. This saves on storage and gas.
# The format of the checkpoint is:
# keccak256 hash of abi_encoded checkpoint(validators[], powers[], valset_id, turnstone_id)
# The validator powers must be decreasing or equal. This is important for checking the signatures on the
# next valset, since it allows the caller to stop verifying signatures once a quorum of signatures have been verified.
@internal
@view
def make_checkpoint(valset: Valset) -> bytes32:
    return keccak256(_abi_encode(valset.validators, valset.powers, valset.valset_id, TURNSTONE_ID, method_id=method_id("checkpoint(address[],uint256[],uint256,bytes32)")))

# This updates the valset by checking that the validators in the current valset have signed off on the
# new valset. The signatures supplied are the signatures of the current valset over the checkpoint hash
# generated from the new valset.
# Anyone can call this function, but they must supply valid signatures of constant_powerThreshold of the current valset over
# the new valset.
# valset: new validator set to update with
# consensus: current validator set and signatures
@external
def update_valset(consensus: Consensus, new_valset: Valset):
    # check if new valset_id is greater than current valset_id
    assert new_valset.valset_id > consensus.valset.valset_id, "Invalid Valset ID"
    cumulative_power: uint256 = 0
    i: uint256 = 0
    # check cumulative power is enough
    for validator in new_valset.validators:
        cumulative_power += new_valset.powers[i]
        if cumulative_power >= POWER_THRESHOLD:
            break
        i += 1
    assert cumulative_power >= POWER_THRESHOLD, "Insufficient Power"
    # check if the supplied current validator set matches the saved checkpoint
    assert self.last_checkpoint == self.make_checkpoint(consensus.valset), "Incorrect Checkpoint"
    # calculate the new checkpoint
    new_checkpoint: bytes32 = self.make_checkpoint(new_valset)
    # check if enough validators signed new validator set (new checkpoint)
    self.check_validator_signatures(consensus, new_checkpoint)
    self.last_checkpoint = new_checkpoint
    log ValsetUpdated(new_checkpoint, new_valset.valset_id)

# This makes calls to contracts that execute arbitrary logic
# message_id is to prevent replay attack and every message_id can be used only once
@external
def submit_logic_call(consensus: Consensus, args: LogicCallArgs, message_id: uint256, deadline: uint256):
    assert block.timestamp <= deadline, "Timeout"
    assert not self.message_id_used[message_id], "Used Message_ID"
    self.message_id_used[message_id] = True
    # check if the supplied current validator set matches the saved checkpoint
    assert self.last_checkpoint == self.make_checkpoint(consensus.valset), "Incorrect Checkpoint"
    # signing data is keccak256 hash of abi_encoded logic_call(args, message_id, turnstone_id, deadline)
    args_hash: bytes32 = keccak256(_abi_encode(args, message_id, TURNSTONE_ID, deadline, method_id=method_id("logic_call((address,bytes),uint256,bytes32,uint256)")))
    # check if enough validators signed args_hash
    self.check_validator_signatures(consensus, args_hash)
    # make call to logic contract
    raw_call(args.logic_contract_address, args.payload)
    log LogicCallEvent(args.logic_contract_address, args.payload, message_id)