# @version 0.3.1

total_shares_burnt: public(uint256)
LIDO: immutable(address)
VOTING: immutable(address)


@external
def __init__(
    _lido: address,
    _voting: address
):
    LIDO = _lido
    VOTING = _voting

@external
@view
def getCoverSharesBurnt() -> uint256:
    return self.total_shares_burnt

@external
@view
def LIDO() -> address:
    return LIDO

@external
@view
def VOTING() -> address:
    return VOTING

@external
def increment_total_shares_burnt(inc: uint256):
    self.total_shares_burnt += inc