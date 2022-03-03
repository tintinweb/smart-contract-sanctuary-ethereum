# @version 0.3.1
"""
@title Curve Ethereum State Sender
"""


interface AnyCallProxy:
    def anyCall(
        _to: address, _data: Bytes[68], _fallback: address, _to_chain_id: uint256
    ): nonpayable

interface RootGaugeFactory:
    def get_bridger(_chain_id: uint256) -> address: view

interface VotingEscrow:
    def epoch() -> uint256: view
    def point_history(_idx: uint256) -> Point: view
    def user_point_epoch(_user: address) -> uint256: view


struct Point:
    bias: int128
    slope: int128  # - dweight / dt
    ts: uint256
    blk: uint256  # block


WEEK: constant(uint256) = 86400 * 7

ANYCALL_PROXY: constant(address) = 0x37414a8662bC1D25be3ee51Fb27C2686e2490A89
ROOT_GAUGE_FACTORY: constant(address) = 0xabC000d88f23Bb45525E447528DBF656A9D55bf5
VOTING_ESCROW: constant(address) = 0x5f3b5DfEb7B28CDbD7FAba78963EE202a494e2A2


# chain_id => last block number sent
_last_sent: HashMap[uint256, uint256]


@external
def send_blockhash(_block_number: uint256, _chain_id: uint256):
    """
    @notice Send the blockhash of `_block_number` to `_chain_id`
    @dev The `_block_number` chosen must be within `block_number_bounds()`
    @param _block_number The block number to push the blockhash of
    @param _chain_id The chain id of the chain to push the data to
    """
    last_sent: uint256 = self._last_sent[_chain_id]
    # must wait 1024 blocks since the last block sent before sending a new block
    assert self._last_sent[_chain_id] < block.number - 1024  # dev: sending too soon
    # must send a block that has >40 confirmations
    assert block.number - _block_number > 40  # dev: block too fresh
    # must send a block that is <256 blocks old
    assert block.number - _block_number < 256  # dev: block too stale

    block_hash: bytes32 = blockhash(_block_number)
    assert block_hash != EMPTY_BYTES32  # dev: invalid blockhash
    assert RootGaugeFactory(ROOT_GAUGE_FACTORY).get_bridger(_chain_id) != ZERO_ADDRESS  # dev: invalid chain_id

    # update the last block sent
    self._last_sent[_chain_id] = _block_number

    AnyCallProxy(ANYCALL_PROXY).anyCall(
        self,
        _abi_encode(
            _block_number,
            block_hash,
            method_id=method_id("set_eth_blockhash(uint256,bytes32)")
        ),
        ZERO_ADDRESS,
        _chain_id
    )


@view
@external
def block_number_bounds() -> uint256[2]:
    """
    @notice The lower and upper bounds (exclusive) of valid block numbers to push.
    @dev The block number closest to the upper bound should be chosen to send cross chain
    """
    return [block.number - 256, block.number - 40]


@view
@external
def generate_eth_get_proof_params(_user: address) -> (address, uint256[20], uint256):
    """
    @notice Generate the params arguments required for the `eth_getProof` RPC call
    @dev This method should be called at the same block number as the blockhash the proof
        will be verified against. For blocks greater than `block.number - 256` this method
        should be called via an archive node.
    @param _user The account the storage proof will be generated for
    """
    # initialize positions array
    positions: uint256[20] = empty(uint256[20])

    # `VotingEscrow.epoch()`
    positions[0] = 3

    # `VotingEscrow.point_history(uint256)`
    global_epoch: uint256 = VotingEscrow(VOTING_ESCROW).epoch()
    point_history_pos: uint256 = convert(keccak256(_abi_encode(convert(keccak256(_abi_encode(convert(4, bytes32))), uint256) + global_epoch)), uint256)

    for i in range(4):
        positions[1 + i] = point_history_pos + i

    # `VotingEscrow.user_point_epoch(address)`
    positions[5] = convert(keccak256(_abi_encode(convert(6, bytes32), _user)), uint256)

    # `VotingEscrow.user_point_history(address,uint256)`
    user_epoch: uint256 = VotingEscrow(VOTING_ESCROW).user_point_epoch(_user)
    user_point_history_pos: uint256 = convert(keccak256(_abi_encode(convert(keccak256(_abi_encode(keccak256(_abi_encode(convert(5, bytes32), _user)))), uint256) + user_epoch)), uint256)

    for i in range(4):
        positions[6 + i] = user_point_history_pos + i

    # `VotingEscrow.locked(address)`
    # uint256 locked_pos = uint256(keccak256());
    locked_pos: uint256 = convert(keccak256(_abi_encode(keccak256(_abi_encode(convert(2, bytes32), _user)))), uint256)

    positions[10] = locked_pos
    positions[11] = locked_pos + 1

    # `VotingEscrow.slope_changes(uint256)`
    # Slots for the 8 weeks worth of slope changes
    last_point: Point = VotingEscrow(VOTING_ESCROW).point_history(global_epoch)
    start_time: uint256 = (last_point.ts / WEEK) * WEEK + WEEK

    for i in range(8):
        positions[12 + i] = convert(keccak256(_abi_encode(convert(7, bytes32), start_time + WEEK * i)), uint256)

    return VOTING_ESCROW, positions, block.number


@view
@external
def get_last_block_number_sent(_chain_id: uint256) -> uint256:
    """
    @notice Get the last block number which had its blockhash sent to `_chain_id`
    @param _chain_id The chain id of interest
    """
    last_block: uint256 = self._last_sent[_chain_id]
    if last_block == 0:
        last_block = 14309414
    return last_block