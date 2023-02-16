# @version 0.3.7
# @license Apache-2.0

#    ____        _ __    __   ____  _ ________                     __ 
#   / __ )__  __(_) /___/ /  / __ \(_) __/ __/__  ________  ____  / /_
#  / __  / / / / / / __  /  / / / / / /_/ /_/ _ \/ ___/ _ \/ __ \/ __/
# / /_/ / /_/ / / / /_/ /  / /_/ / / __/ __/  __/ /  /  __/ / / / /__ 
#/_____/\__,_/_/_/\__,_/  /_____/_/_/ /_/  \___/_/   \___/_/ /_/\__(_)

#//////////////////////////////////////////////////////////////////////////
#                              Interfaces
#//////////////////////////////////////////////////////////////////////////

interface IERC1155TL:
    def externalMint(_tokenId: uint256, _addresses: DynArray[address, 100], _amounts: DynArray[uint256, 100]): nonpayable

interface IOwnableAccessControl:
    def owner() -> address: view
    def hasRole(_role: bytes32, _operator: address) -> bool: view
    

#//////////////////////////////////////////////////////////////////////////
#                              Constants
#//////////////////////////////////////////////////////////////////////////

ADMIN_ROLE: constant(bytes32) = keccak256("ADMIN_ROLE")

#//////////////////////////////////////////////////////////////////////////
#                                Enums
#//////////////////////////////////////////////////////////////////////////

enum DropPhase:
    NOT_CONFIGURED
    BEFORE_SALE
    PRESALE
    PUBLIC_SALE
    ENDED

enum DropParam:
    MERKLE_ROOT
    ALLOWANCE
    COST
    DURATION
    PAYOUT_ADDRESS

#//////////////////////////////////////////////////////////////////////////
#                                Struct
#//////////////////////////////////////////////////////////////////////////

struct Drop:
    supply: uint256
    decay_rate: int256
    allowance: uint256
    payout_receiver: address
    start_time: uint256
    presale_duration: uint256
    presale_cost: uint256
    presale_merkle_root: bytes32
    public_duration: uint256
    public_cost: uint256

#//////////////////////////////////////////////////////////////////////////
#                                Events
#//////////////////////////////////////////////////////////////////////////

event OwnershipTransferred:
    previousOwner: indexed(address)
    newOwner: indexed(address)

event DropConfigured:
    configurer: indexed(address)
    nft_contract: indexed(address)
    token_id: uint256

event Purchase:
    buyer: indexed(address)
    receiver: indexed(address)
    nft_addr: indexed(address)
    token_id: uint256
    amount: uint256
    price: uint256
    is_presale: bool

event DropClosed:
    closer: indexed(address)
    nft_contract: indexed(address)
    token_id: uint256

event DropUpdated:
    phase_param: DropPhase
    param_updated: DropParam
    value: bytes32

event Paused:
    status: bool

#//////////////////////////////////////////////////////////////////////////
#                                Contract Vars
#//////////////////////////////////////////////////////////////////////////
owner: public(address)

# nft_caddr => token_id => Drop
drops: HashMap[address, HashMap[uint256, Drop]]

# nft_caddr => token_id => round_id => user => num_minted
num_minted: HashMap[address, HashMap[uint256, HashMap[uint256, HashMap[address, uint256]]]]

# nft_addr => token_id => round_num
drop_round: HashMap[address, HashMap[uint256, uint256]]

# determine if the contract is paused or not
paused: bool

#//////////////////////////////////////////////////////////////////////////
#                                Constructor
#//////////////////////////////////////////////////////////////////////////

@external
def __init__(_owner: address):
    self.owner = _owner
    log OwnershipTransferred(empty(address), _owner)

#//////////////////////////////////////////////////////////////////////////
#                         Owner Write Function
#//////////////////////////////////////////////////////////////////////////

@external
def set_paused(_paused: bool):
    if self.owner != msg.sender:
        raise "not authorized"

    self.paused = _paused

    log Paused(_paused)

#//////////////////////////////////////////////////////////////////////////
#                         Admin Write Function
#//////////////////////////////////////////////////////////////////////////

@external 
def configure_drop(
    _nft_addr: address,
    _token_id: uint256,
    _supply: uint256,
    _decay_rate: int256,
    _allowance: uint256,
    _payout_receiver: address,
    _start_time: uint256,
    _presale_duration: uint256,
    _presale_cost: uint256,
    _presale_merkle_root: bytes32,
    _public_duration: uint256,
    _public_cost: uint256
):
    # Check if paused
    if self.paused:
        raise "contract is paused"

    if _start_time == 0:
        raise "start time cannot be 0"

    # Make sure the sender is the owner or admin on the contract
    if not self._is_drop_admin(_nft_addr, msg.sender):
        raise "not authorized"

    drop: Drop = self.drops[_nft_addr][_token_id]

    # Check if theres an existing drop that needs to be closed
    if self._get_drop_phase(_nft_addr, _token_id) != DropPhase.NOT_CONFIGURED:
        raise "there is an existing drop"

    # Allowlist doesnt work with burn down/extending mints
    if _decay_rate != 0 and _presale_duration != 0:
        raise "cant have allowlist with burn/extending"

    # No supply for velocity mint
    if _decay_rate < 0 and _supply != max_value(uint256):
        raise "cant have burn down and a supply"

    drop = Drop({
        supply: _supply,
        decay_rate: _decay_rate,
        allowance: _allowance,
        payout_receiver: _payout_receiver,
        start_time: _start_time,
        presale_duration: _presale_duration,
        presale_cost: _presale_cost,
        presale_merkle_root: _presale_merkle_root,
        public_duration: _public_duration,
        public_cost: _public_cost
    })

    self.drops[_nft_addr][_token_id] = drop

    log DropConfigured(msg.sender, _nft_addr, _token_id)

@external
def close_drop(
    _nft_addr: address,
    _token_id: uint256
):
    if self.paused:
        raise "contract is paused"
        
    if not self._is_drop_admin(_nft_addr, msg.sender):
        raise "unauthorized"
    
    self.drops[_nft_addr][_token_id] = empty(Drop)
    self.drop_round[_nft_addr][_token_id] += 1

    log DropClosed(msg.sender, _nft_addr, _token_id)

@external
def update_drop_param(
    _nft_addr: address, 
    _token_id: uint256, 
    _phase: DropPhase, 
    _param: DropParam, 
    _param_value: bytes32
):
    if not self._is_drop_admin(_nft_addr, msg.sender):
        raise "unauthorized"

    if _phase == DropPhase.PRESALE:
        if _param == DropParam.MERKLE_ROOT:
            self.drops[_nft_addr][_token_id].presale_merkle_root = _param_value
        elif _param == DropParam.COST:
            self.drops[_nft_addr][_token_id].presale_cost = convert(_param_value, uint256)
        elif _param == DropParam.DURATION:
            self.drops[_nft_addr][_token_id].presale_duration = convert(_param_value, uint256)
        else:
            raise "unknown param update"
    elif _phase == DropPhase.PUBLIC_SALE:
        if _param == DropParam.ALLOWANCE:
            self.drops[_nft_addr][_token_id].allowance = convert(_param_value, uint256)
        elif _param == DropParam.COST:
            self.drops[_nft_addr][_token_id].presale_cost = convert(_param_value, uint256)
        elif _param == DropParam.DURATION:
            self.drops[_nft_addr][_token_id].public_duration = convert(_param_value, uint256)
        else:
            raise "unknown param update"
    elif _phase == DropPhase.NOT_CONFIGURED:
        if _param == DropParam.PAYOUT_ADDRESS:
            self.drops[_nft_addr][_token_id].payout_receiver = convert(_param_value, address)
        else:
            raise "unknown param update"
    else:
        raise "unknown param update"

    log DropUpdated(_phase, _param, _param_value)


#//////////////////////////////////////////////////////////////////////////
#                         External Write Function
#//////////////////////////////////////////////////////////////////////////

@external
@payable
@nonreentrant("lock")
def mint(
    _nft_addr: address,
    _token_id: uint256,
    _num_mint: uint256,
    _receiver: address,
    _proof: DynArray[bytes32, 100],
    _allowlist_allocation: uint256
):
    if self.paused:
        raise "contract is paused"

    drop: Drop = self.drops[_nft_addr][_token_id]

    if drop.supply == 0:
        raise "no supply left"
    
    drop_phase: DropPhase = self._get_drop_phase(_nft_addr, _token_id)

    if drop_phase == DropPhase.PRESALE:
        leaf: bytes32 = keccak256(
            concat(
                convert(_receiver, bytes32), 
                convert(_allowlist_allocation, bytes32)
            )
        )
        root: bytes32 = self.drops[_nft_addr][_token_id].presale_merkle_root
        
        # Check if user is part of allowlist
        if not self._verify_proof(_proof, root, leaf):
            raise "not part of allowlist"

        mint_num: uint256 = self._determine_mint_num(
            _nft_addr, 
            _token_id,
            _receiver,
            _num_mint,
            _allowlist_allocation, 
            drop.presale_cost
        )

        self._settle_up(
            _nft_addr,
            _token_id,
            _receiver,
            drop.payout_receiver,
            mint_num,
            drop.presale_cost
        )

        log Purchase(msg.sender, _receiver, _nft_addr, _token_id, mint_num, drop.presale_cost, True)

    elif drop_phase == DropPhase.PUBLIC_SALE:
        if block.timestamp > drop.start_time + drop.presale_duration + drop.public_duration:
            raise "public sale is no more"

        mint_num: uint256 = self._determine_mint_num(
            _nft_addr, 
            _token_id,
            _receiver,
            _num_mint,
            drop.allowance,
            drop.public_cost
        )

        adjust: uint256 = mint_num * convert(abs(drop.decay_rate), uint256)
        if drop.decay_rate < 0:
            if adjust > drop.public_duration:
                self.drops[_nft_addr][_token_id].public_duration = 0
            else:
                self.drops[_nft_addr][_token_id].public_duration -= adjust
        elif drop.decay_rate > 0:
            self.drops[_nft_addr][_token_id].public_duration += adjust

        self._settle_up(
            _nft_addr,
            _token_id,
            _receiver,
            drop.payout_receiver,
            mint_num,
            drop.public_cost
        )

        log Purchase(msg.sender, _receiver, _nft_addr, _token_id, mint_num, drop.public_cost, False)

    else:
        raise "you shall not mint"

#//////////////////////////////////////////////////////////////////////////
#                         External Read Function
#//////////////////////////////////////////////////////////////////////////

@view
@external
def get_drop(_nft_addr: address, _token_id: uint256) -> Drop:
    return self.drops[_nft_addr][_token_id]

@view
@external
def get_num_minted(_nft_addr: address, _token_id: uint256, _user: address) -> uint256:
    round_id: uint256 = self.drop_round[_nft_addr][_token_id]
    return self.num_minted[_nft_addr][_token_id][round_id][_user]

@view
@external
def get_drop_phase(_nft_addr: address, _token_id: uint256) -> DropPhase:
    return self._get_drop_phase(_nft_addr, _token_id)

@view
@external
def is_paused() -> bool:
    return self.paused

#//////////////////////////////////////////////////////////////////////////
#                         Internal Read Function
#//////////////////////////////////////////////////////////////////////////

@view
@internal
def _is_drop_admin(_nft_addr: address, _operator: address) -> bool:
    return IOwnableAccessControl(_nft_addr).owner() == _operator \
        or IOwnableAccessControl(_nft_addr).hasRole(ADMIN_ROLE, _operator)

@view
@internal
def _get_drop_phase(_nft_addr: address, _token_id: uint256) -> DropPhase:
    drop: Drop = self.drops[_nft_addr][_token_id]

    if drop.start_time == 0:
        return DropPhase.NOT_CONFIGURED

    if drop.supply == 0:
        return DropPhase.ENDED

    if block.timestamp < drop.start_time:
        return DropPhase.BEFORE_SALE

    if drop.start_time <= block.timestamp and block.timestamp < drop.start_time + drop.presale_duration:
        return DropPhase.PRESALE

    if drop.start_time + drop.presale_duration <= block.timestamp \
        and block.timestamp < drop.start_time + drop.presale_duration + drop.public_duration:
        return DropPhase.PUBLIC_SALE

    return DropPhase.ENDED

@pure
@internal
def _verify_proof(_proof: DynArray[bytes32, 100], _root: bytes32, _leaf: bytes32) -> bool:
    computed_hash: bytes32 = _leaf
    for p in _proof:
        if convert(computed_hash, uint256) < convert(p, uint256):
            computed_hash = keccak256(concat(computed_hash, p))  
        else: 
            computed_hash = keccak256(concat(p, computed_hash))
    return computed_hash == _root

#//////////////////////////////////////////////////////////////////////////
#                         Internal Write Function
#//////////////////////////////////////////////////////////////////////////

@internal
@payable
def _determine_mint_num(
    _nft_addr: address,
    _token_id: uint256,
    _receiver: address,
    _num_mint: uint256,
    _allowance: uint256,
    _cost: uint256
) -> uint256:
    drop: Drop = self.drops[_nft_addr][_token_id]

    drop_round: uint256 = self.drop_round[_nft_addr][_token_id]
    curr_minted: uint256 = self.num_minted[_nft_addr][_token_id][drop_round][_receiver]

    mint_num: uint256 = _num_mint

    if curr_minted == _allowance:
        raise "already hit mint allowance"

    if curr_minted + _num_mint > _allowance:
        mint_num = _allowance - curr_minted

    if mint_num > drop.supply:
        mint_num = drop.supply

    if msg.value < mint_num * _cost:
        raise "not enough funds sent"

    self.drops[_nft_addr][_token_id].supply -= mint_num
    self.num_minted[_nft_addr][_token_id][drop_round][_receiver] += mint_num

    return mint_num

@internal
@payable
def _settle_up(
    _nft_addr: address,
    _token_id: uint256,
    _receiver: address,
    _payout_receiver: address,
    _mint_num: uint256,
    _cost: uint256
):
    if msg.value > _mint_num * _cost:
        raw_call(
            msg.sender,
            b"",
            max_outsize=0,
            value=msg.value - (_mint_num * _cost),
            revert_on_failure=True
        )
    
    addrs: DynArray[address, 1] = [_receiver]
    amts: DynArray[uint256, 1] = [_mint_num]

    IERC1155TL(_nft_addr).externalMint(_token_id, addrs, amts)

    raw_call(
        _payout_receiver,
        b"",
        max_outsize=0,
        value=_mint_num * _cost,
        revert_on_failure=True
    )