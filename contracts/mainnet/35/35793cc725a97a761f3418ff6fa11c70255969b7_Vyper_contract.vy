# @version 0.3.7
"""
@title ib_burner
@license MIT
@author Long J'hat
@notice
    Contract to recycle Fixed Forex profits into ibEUR and send it to distributor.
    -- It works, until it doesn't.
"""

from vyper.interfaces import ERC20


interface Synthetix:
    def exchangeAtomically(
        src: bytes32,
        src_amount: uint256,
        dst: bytes32,
        code: bytes32,
        min_dst_amount: uint256,
    ) -> uint256: nonpayable

interface Resolver:
    def getAddress(key: bytes32) -> address: view


interface Curve:
    def get_dy(i: int128, j: int128, dx: uint256) -> uint256: view
    def exchange(
        i: int128,
        j: int128,
        _dx: uint256,
        _min_dy: uint256,
        _receiver: address = msg.sender,
    ) -> uint256: nonpayable


interface FeeDist:
    def checkpoint_token(): nonpayable
    def checkpoint_total_supply(): nonpayable
    def commit_admin(admin: address): nonpayable
    def apply_admin(): nonpayable


MSIG: constant(address) = 0x0D5Dc686d0a2ABBfDaFDFb4D0533E886517d4E83
SNX: public(Synthetix)

ADDRESSES: immutable(Resolver)

CURVE_EUR: immutable(Curve)
CURVE_AUD: immutable(Curve)
CURVE_CHF: immutable(Curve)
CURVE_GBP: immutable(Curve)
CURVE_JPY: immutable(Curve)
CURVE_KRW: immutable(Curve)

IB_EUR: immutable(ERC20)
IB_AUD: immutable(ERC20)
IB_CHF: immutable(ERC20)
IB_GBP: immutable(ERC20)
IB_JPY: immutable(ERC20)
IB_KRW: immutable(ERC20)

S_EUR: immutable(ERC20)
S_AUD: immutable(ERC20)
S_CHF: immutable(ERC20)
S_GBP: immutable(ERC20)
S_JPY: immutable(ERC20)
S_KRW: immutable(ERC20)

DIST: immutable(FeeDist)


@external
def __init__():
    ADDRESSES = Resolver(0x823bE81bbF96BEc0e25CA13170F5AaCb5B79ba83)

    CURVE_EUR = Curve(0x19b080FE1ffA0553469D20Ca36219F17Fcf03859)
    CURVE_AUD = Curve(0x3F1B0278A9ee595635B61817630cC19DE792f506)
    CURVE_CHF = Curve(0x9c2C8910F113181783c249d8F6Aa41b51Cde0f0c)
    CURVE_GBP = Curve(0xD6Ac1CB9019137a896343Da59dDE6d097F710538)
    CURVE_JPY = Curve(0x8818a9bb44Fbf33502bE7c15c500d0C783B73067)
    CURVE_KRW = Curve(0x8461A004b50d321CB22B7d034969cE6803911899)

    IB_EUR = ERC20(0x96E61422b6A9bA0e068B6c5ADd4fFaBC6a4aae27)
    IB_AUD = ERC20(0xFAFdF0C4c1CB09d430Bf88c75D88BB46DAe09967)
    IB_CHF = ERC20(0x1CC481cE2BD2EC7Bf67d1Be64d4878b16078F309)
    IB_GBP = ERC20(0x69681f8fde45345C3870BCD5eaf4A05a60E7D227)
    IB_JPY = ERC20(0x5555f75e3d5278082200Fb451D1b6bA946D8e13b)
    IB_KRW = ERC20(0x95dFDC8161832e4fF7816aC4B6367CE201538253)

    S_EUR = ERC20(0xD71eCFF9342A5Ced620049e616c5035F1dB98620)
    S_AUD = ERC20(0xF48e200EAF9906362BB1442fca31e0835773b8B4)
    S_CHF = ERC20(0x0F83287FF768D1c1e17a42F44d644D7F22e8ee1d)
    S_GBP = ERC20(0x97fe22E7341a0Cd8Db6F6C021A24Dc8f4DAD855F)
    S_JPY = ERC20(0xF6b1C627e95BFc3c1b4c9B825a032Ff0fBf3e07d)
    S_KRW = ERC20(0x269895a3dF4D73b077Fc823dD6dA1B95f72Aaf9B)

    DIST = FeeDist(0xB9d18ab94cf61bB2Bcebe6aC8Ba8c19fF0CDB0cA)

    # infinite approves
    IB_AUD.approve(CURVE_AUD.address, max_value(uint256))
    IB_CHF.approve(CURVE_CHF.address, max_value(uint256))
    IB_GBP.approve(CURVE_GBP.address, max_value(uint256))
    IB_JPY.approve(CURVE_JPY.address, max_value(uint256))
    IB_KRW.approve(CURVE_KRW.address, max_value(uint256))

    self.SNX = Synthetix(ADDRESSES.getAddress(convert(b"Synthetix", bytes32)))

    S_AUD.approve(self.SNX.address, max_value(uint256))
    S_CHF.approve(self.SNX.address, max_value(uint256))
    S_GBP.approve(self.SNX.address, max_value(uint256))
    S_JPY.approve(self.SNX.address, max_value(uint256))
    S_KRW.approve(self.SNX.address, max_value(uint256))

    S_EUR.approve(CURVE_EUR.address, max_value(uint256))


@external
def update_snx():
    self.SNX = Synthetix(ADDRESSES.getAddress(convert(b"Synthetix", bytes32)))

    S_AUD.approve(self.SNX.address, max_value(uint256))
    S_CHF.approve(self.SNX.address, max_value(uint256))
    S_GBP.approve(self.SNX.address, max_value(uint256))
    S_JPY.approve(self.SNX.address, max_value(uint256))
    S_KRW.approve(self.SNX.address, max_value(uint256))


@external
def exchange_all():
    """
    Convert all profits from non-EUR tokens to EUR.
    """
    self.exchange(IB_AUD, convert(b"sAUD", bytes32), CURVE_AUD)
    self.exchange(IB_CHF, convert(b"sCHF", bytes32), CURVE_CHF)
    self.exchange(IB_GBP, convert(b"sGBP", bytes32), CURVE_GBP)
    self.exchange(IB_JPY, convert(b"sJPY", bytes32), CURVE_JPY)
    self.exchange(IB_KRW, convert(b"sKRW", bytes32), CURVE_KRW)


@internal
def exchange(ib: ERC20, s: bytes32, c: Curve):
    amount: uint256 = ib.balanceOf(self)
    if amount > 0:
        amount_received: uint256 = c.exchange(0, 1, amount, 0, self)
        if amount_received > 0:
            self.SNX.exchangeAtomically(s, amount_received, convert(b"sEUR", bytes32), convert(b"ibAMM", bytes32), 0)


@external
def commit_admin(admin: address):
    """
    NOTE: necessary!
    """
    assert msg.sender == MSIG # !msig
    DIST.commit_admin(admin)


@external
def apply_admin():
    """
    NOTE: necessary!
    """
    assert msg.sender == MSIG # !msig
    DIST.apply_admin()


@external
def distribute():
    """
    Convert sEUR to ibEUR and distribute. Create checkpoints.
    """
    amount: uint256 = S_EUR.balanceOf(self)
    if amount > 0:
        CURVE_EUR.exchange(1, 0, amount, 0, self)
    IB_EUR.transfer(DIST.address, IB_EUR.balanceOf(self))
    DIST.checkpoint_token()
    DIST.checkpoint_total_supply()


@external
def distribute_no_checkpoint():
    """
    Convert sEUR to ibEUR and distribute.
    """
    amount: uint256 = S_EUR.balanceOf(self)
    if amount > 0:
        CURVE_EUR.exchange(1, 0, amount, 0, self)
    IB_EUR.transfer(DIST.address, IB_EUR.balanceOf(self))


@payable
@external
def __default__():
    pass


@external
def collect_eth():
    assert msg.sender == MSIG # !msig
    send(msg.sender, self.balance)


@external
def collect_dust(token: ERC20):
    assert msg.sender == MSIG # !msig
    assert token.transfer(msg.sender, token.balanceOf(self), default_return_value=True)