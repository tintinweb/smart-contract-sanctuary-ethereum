# @version ^0.3.6


interface Token:
    def transferFrom(sender: address, recipient: address, amount: uint256) -> bool: nonpayable


interface EIP2612StylePermitToken:
    def permit(holder: address, spender: address, value_: uint256, deadline: uint256, v: uint8, r: bytes32, s: bytes32): nonpayable


interface DAIStylePermitToken:
    def permit(holder: address, spender: address, nonce: uint256, expiry: uint256, allowed: bool, v: uint8, r: bytes32, s: bytes32): nonpayable
    def allowance(holder: address, spender: address) -> uint256: view


interface PurchaseCallback:
    def onBeforePurchase(customer: address, token: address, amount: uint256, product: uint256): nonpayable
    def onAfterPurchase(customer: address, token: address, amount: uint256, product: uint256): nonpayable



struct Receipt:
    token: address
    amount: uint256
    product: uint256


struct TokenConfig:
    is_accepted: bool
    min_meta_amount: uint256


event Purchase:
    customer: address
    token: address
    amount: uint256
    product: uint256


owner: address
beneficiary: address


DOMAIN_SEPARATOR: public(bytes32)
nonces: public(HashMap[address, uint256])
accepted_tokens: public(HashMap[address, TokenConfig])
purchased: public(HashMap[address, HashMap[address, HashMap[uint256, uint256]]]) # customer, token, product -> amount


@external
def __init__():
    self.owner = msg.sender


@nonpayable
@external
def setup(chainId_: uint256, beneficiary: address):
    assert msg.sender == self.owner
    assert self.beneficiary == empty(address)
    self.beneficiary = beneficiary

    version: uint256 = 1
    self.DOMAIN_SEPARATOR = keccak256(
        _abi_encode(
            keccak256("EIP712Domain(bytes32 name,bytes32 version,uint256 chainId,address verifyingContract)"),
            keccak256("cashier"),
            keccak256(convert(version, bytes32)),
            chainId_,
            self,
        )
    )


@nonpayable
@external
def change_owner(new_owner: address):
    assert msg.sender == self.owner
    assert new_owner != empty(address)
    self.owner = new_owner


@nonpayable
@external
def set_beneficiary(new_beneficiary: address):
    assert msg.sender == self.owner
    self.beneficiary = new_beneficiary


@nonpayable
@external
def set_token_acceptance(token: address, config: TokenConfig):
    assert msg.sender == self.owner
    self.accepted_tokens[token] = config


@external
@nonpayable
def __default__():
    pass


@nonreentrant('purchase')
@nonpayable
@external
def purchase(customer: address, token: address, amount: uint256, product: uint256, callback: address):
    assert msg.sender == customer or msg.sender == self.owner, "access only for customer or owner"
    assert self.accepted_tokens[token].is_accepted, "token is not accepted"
    self.purchase_internal(customer, token, amount, product, callback)


@nonreentrant('purchase')
@nonpayable
@external
def meta_purchase(customer: address, token: address, amount: uint256, product: uint256, callback: address, \
        deadline: uint256, v: uint8, r: bytes32, s: bytes32):
    assert deadline >= block.timestamp, "expired"

    token_config: TokenConfig = self.accepted_tokens[token]
    assert token_config.is_accepted, "token is not accepted"
    assert amount >= token_config.min_meta_amount, "amount must be greater than min_meta_amount for token"

    nonce: uint256 = self.nonces[customer] + 1
    digest: bytes32 = keccak256(concat(
        0x1901,
        self.DOMAIN_SEPARATOR,
        keccak256(
            _abi_encode(
                keccak256("meta_purchase(address customer,address token,uint256 amount,uint256 product,address callback,uint256 nonce,uint256 deadline)"),
                customer, 
                token,
                amount,
                product,
                callback,
                nonce,
                deadline
            )
        )
    ))

    assert customer != empty(address), "invalid customer"
    assert customer == ecrecover(digest, convert(v, uint256), convert(r, uint256), convert(s, uint256)), "invalid signature"
    self.nonces[customer] = nonce

    if callback != empty(address):
        PurchaseCallback(callback).onBeforePurchase(customer, token, amount, product)

    self.purchase_internal(customer, token, amount, product, callback)


@nonreentrant('purchase')
@nonpayable
@external
def meta_eip2612_permit_purchase(customer: address, token: address, amount: uint256, product: uint256, callback: address, \
        deadline: uint256, v: uint8, r: bytes32, s: bytes32, \
        vt: uint8, rt: bytes32, st: bytes32):
    assert deadline >= block.timestamp, "expired"

    token_config: TokenConfig = self.accepted_tokens[token]
    assert token_config.is_accepted, "token is not accepted"
    assert amount >= token_config.min_meta_amount, "amount must be greater than min_meta_amount for token"

    nonce: uint256 = self.nonces[customer] + 1
    digest: bytes32 = keccak256(concat(
        0x1901,
        self.DOMAIN_SEPARATOR,
        keccak256(
            _abi_encode(
                keccak256("meta_eip2612_permit_purchase(address customer,address token,uint256 amount,uint256 product,address callback,uint256 nonce,uint256 deadline)"),
                customer, 
                token,
                amount,
                product,
                callback,
                nonce,
                deadline
            )
        )
    ))

    assert customer != empty(address), "invalid customer"
    assert customer == ecrecover(digest, convert(v, uint256), convert(r, uint256), convert(s, uint256)), "invalid signature"
    self.nonces[customer] = nonce

    if callback != empty(address):
        PurchaseCallback(callback).onBeforePurchase(customer, token, amount, product)

    if amount > 0:
        EIP2612StylePermitToken(token).permit(customer, self, amount, deadline, vt, rt, st)
    self.purchase_internal(customer, token, amount, product, callback)


@nonreentrant('purchase')
@nonpayable
@external
def meta_dai_permit_purchase(customer: address, token: address, amount: uint256, product: uint256, callback: address, \
        deadline: uint256, v: uint8, r: bytes32, s: bytes32, \
        tnounce: uint256, vt: uint8, rt: bytes32, st: bytes32):
    assert deadline >= block.timestamp, "expired"

    token_config: TokenConfig = self.accepted_tokens[token]
    assert token_config.is_accepted, "token is not accepted"
    assert amount >= token_config.min_meta_amount, "amount must be greater than min_meta_amount for token"

    nonce: uint256 = self.nonces[customer] + 1
    digest: bytes32 = keccak256(concat(
        0x1901,
        self.DOMAIN_SEPARATOR,
        keccak256(
            _abi_encode(
                keccak256("meta_dai_permit_purchase(address customer,address token,uint256 amount,uint256 product,address callback,uint256 nonce,uint256 deadline)"),
                customer, 
                token,
                amount,
                product,
                callback,
                nonce,
                deadline
            )
        )
    ))

    assert customer != empty(address), "invalid customer"
    assert customer == ecrecover(digest, convert(v, uint256), convert(r, uint256), convert(s, uint256)), "invalid signature"
    self.nonces[customer] = nonce

    if callback != empty(address):
        PurchaseCallback(callback).onBeforePurchase(customer, token, amount, product)

    if amount > 0:
        DAIStylePermitToken(token).permit(customer, self, tnounce, deadline, True, vt, rt, st)
    self.purchase_internal(customer, token, amount, product, callback)


@internal
def purchase_internal(customer: address, token: address, amount: uint256, product: uint256, callback: address):
    if amount > 0:
        Token(token).transferFrom(customer, self.beneficiary, amount)
        self.purchased[customer][token][product] += amount
    
    if callback != empty(address):
        PurchaseCallback(callback).onAfterPurchase(customer, token, amount, product)