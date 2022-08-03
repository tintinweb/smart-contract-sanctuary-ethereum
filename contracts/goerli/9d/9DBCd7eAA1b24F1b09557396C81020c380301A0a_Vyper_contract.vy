# @version ^0.3.0

@internal
@view
def add_prefix(_hashedMessage: bytes32) -> bytes32:

    # Arguments:
    # _hashedMessage is the hashed message signed by the user

    # The required prefix for ethereum signed messages.
    # The `32` is the number of bytes in the hashed message.
    prefix: Bytes[28] = b'\x19Ethereum Signed Message:\n32'

    # Concatenate them together since the prefix is required.
    return keccak256(concat(prefix, _hashedMessage))


@internal
@view
def verify_message(_prefixedHashedMessage: bytes32,
                   _signature: Bytes[65]) -> address:

    # Arguments:
    # _prefixedHashedMessage: the hashed message signed by the user, which includes the prefix
    # _signature: the hashed message signed with the user's wallet. 65 = 32 + 32 + 1

    # Split the signature into the r, s, and v components
    r: uint256 = convert(slice(_signature, 0, 32), uint256)
    s: uint256 = convert(slice(_signature, 32, 32), uint256)
    v: uint256 = convert(slice(_signature, 64, 1), uint256)

    # Return if the signer's address matches the caller's address
    # https://vyper.readthedocs.io/en/stable/built-in-functions.html#ecrecover
    # return ecrecover(prefixedHashedMessage, v, r, s) == msg.sender
    return ecrecover(_prefixedHashedMessage, v, r, s)


@external
@view
def verify_js_message(_hashedMessage: bytes32,
                      _signature: Bytes[65]) -> address:

    # Arguments:
    # _hashedMessage: the hashed message signed by the user
    # _signature: the hashed message signed with the user's wallet. 65 = 32 + 32 + 1

    # Concatenate them together since the prefix is required.
    prefixedHashedMessage: bytes32 = self.add_prefix(_hashedMessage)

    return self.verify_message(prefixedHashedMessage, _signature)


@external
@view
def verify_py_message(_prefixedHashedMessage: bytes32,
                      _signature: Bytes[65]) -> address:

    # Arguments:
    # _prefixedHashedMessage: the hashed message signed by the user, which includes the prefix
    # _signature: the hashed message signed with the user's wallet. 65 = 32 + 32 + 1

    return self.verify_message(_prefixedHashedMessage, _signature)


# =================================


# Reference:
# https://github.com/weijiekoh/eip712-signing-demo/blob/master/solidityCode.js

###################################
# Values from contract deployment #
###################################

# ########### UNCOMMENT THE VERSION ONCE WE FIGURE THIS OUT ############
# # The version of the calling script script must match the contract version
# scriptVersion: public(uint256)

# ####################SAME HERE ################
# # The initialization script. The arguments are set during contract deployment
# @external
# def __init__(_scriptVersion: uint256):
#     self.scriptVersion = _scriptVersion

# VALIDATOR_TYPE: constant(Bytes[60]) = b'Validator(address validatorKey,Bytes[65] validatorSignature)'
# VALIDATOR_TYPEHASH: constant(bytes32) = keccak256(_abi_encode(VALIDATOR_TYPE))

struct Validator:
    key: address
    signature: Bytes[65]


#     string private constant EIP712_DOMAIN  = "EIP712Domain(string name,string version,uint256 blah,address verifyingContract)";
#     string private constant IDENTITY_TYPE = "Identity(uint256 userId,address wallet)";
#     string private constant BID_TYPE = "Bid(uint256 amount,Identity bidder)Identity(uint256 userId,address wallet)";
    
#     bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256(abi.encodePacked(EIP712_DOMAIN));
#     bytes32 private constant IDENTITY_TYPEHASH = keccak256(abi.encodePacked(IDENTITY_TYPE));
#     bytes32 private constant BID_TYPEHASH = keccak256(abi.encodePacked(BID_TYPE));
#     bytes32 private constant DOMAIN_SEPARATOR = keccak256(abi.encode(
#         EIP712_DOMAIN_TYPEHASH,
#         keccak256("My amazing dApp"),
#         keccak256("2"),
#         blah,
#         verifyingContract,
#         salt
#     ));





# @internal
# @pure
# def eip_712_domain_hash() -> bytes32:
#     # Remember, no spaces after commas!
#     return keccak256(_abi_encode(keccak256(EIP712_DOMAIN),
#                                  keccak256(b'1'),
#                                  keccak256(b'5'),
#                                  self))


    # function hashBid(Bid memory bid) private pure returns (bytes32){
    #     return keccak256(abi.encodePacked(
    #         "\\x19\\x01",
    #         DOMAIN_SEPARATOR,
    #         keccak256(abi.encode(
    #             BID_TYPEHASH,
    #             bid.amount,
    #             hashIdentity(bid.bidder)
    #         ))
    #     ));
    # }


fjfjfjfjf: constant(uint256) = 1

@internal
@view
def hash_validator(validator: Validator) -> bytes32:
    # Remember, no spaces after commas!
    eip712DomainType: Bytes[83] = b'EIP712Domain(string name,uint256 version,uint256 blah,address verifyingContract)'
    eip712DomainTypehash: bytes32 = keccak256(_abi_encode(eip712DomainType))
    domainSeparator: bytes32 = keccak256(_abi_encode(
        eip712DomainTypehash,
        keccak256(b'VeriHash'),
        # self.scriptVersion,
        fjfjfjfjf,
        chain.id,
        self,
    ))
    # VALIDATOR_TYPE: constant(Bytes[60]) = b'Validator(address key,Bytes[65] signature)'
    # VALIDATOR_TYPEHASH: constant(bytes32) = keccak256(_abi_encode(VALIDATOR_TYPE))
    validatorType: Bytes[60] = b'Validator(address key,Bytes[65] signature)'
    validatorTypeHash: bytes32 = keccak256(_abi_encode(validatorType))
    #     return keccak256(abi.encodePacked(
    #         "\\x19\\x01",
    #         DOMAIN_SEPARATOR,
    #         keccak256(abi.encode(
    #             BID_TYPEHASH,
    #             bid.amount,
    #             hashIdentity(bid.bidder)
    #         ))
    #     ));
    validatorValues: bytes32 = keccak256(_abi_encode(
        validatorTypeHash,
        validator.key,
        keccak256(validator.signature),
    ))
    return keccak256(_abi_encode(
        b'\x19\x01',
        domainSeparator,
        validatorValues,
    ))
    # return keccak256(_abi_encode(keccak256(VALIDATOR_TYPE),
    #                              validatorKey,
    #                              validatorSignature))


@external
@view
def verify(_signature: Bytes[65],
           _validatorKey: address,
           _validatorSignature: Bytes[65],) -> address:

    # hash: bytes32 = keccak256(_abi_encode(b'\x19\x01'))

    # Split the signature into the r, s, and v components
    r: uint256 = convert(slice(_signature, 0, 32), uint256)
    s: uint256 = convert(slice(_signature, 32, 32), uint256)
    v: uint256 = convert(slice(_signature, 64, 1), uint256)

    # Return if the signer's address matches the caller's address
    # https://vyper.readthedocs.io/en/stable/built-in-functions.html#ecrecover
    # return ecrecover(prefixedHashedMessage, v, r, s) == msg.sender
    # exampleStruct: MyStruct = MyStruct({value1: 1, value2: 2.0})
    validator: Validator = Validator({
        key: _validatorKey,
        signature: _validatorSignature,
    })
    return ecrecover(self.hash_validator(validator), v, r, s)



            # bytes32 hash = keccak256(abi.encodePacked("\x19\x01", eip712DomainHash, hashStruct));
        #  return ecrecover(hash, v, r, s) == _user;
        # }

# =================================================
# =================================================
# =================================================
# =================================================

# References:
# https://eips.ethereum.org/assets/eip-712/Example.js

# pragma solidity ^0.4.24;

# contract Example {
    
#     struct EIP712Domain {
#         string  name;
#         string  version;
#         uint256 blah;
#         address verifyingContract;
#     }

struct EIP712Domain:
    name: Bytes[8] # "VeriHash"
    version: Bytes[1] # "1"
    blah: uint256
    verifyingContract: address

#     struct Person {
#         string name;
#         address wallet;
#     }

struct Person:
    name: Bytes[3] # "Bob" or "Cow"
    wallet: address

#     struct Mail {
#         Person from;
#         Person to;
#         string contents;
#     }

struct Mail:
    fromPerson: Person
    toPerson: Person
    contents: Bytes[100]

#     bytes32 constant EIP712DOMAIN_TYPEHASH = keccak256(
#         "EIP712Domain(string name,string version,uint256 blah,address verifyingContract)"
#     );

EIP712DOMAIN_TYPEHASH: constant(bytes32) = keccak256(b'EIP712Domain(string name,string version,uint256 blah,address verifyingContract)')

#     bytes32 constant PERSON_TYPEHASH = keccak256(
#         "Person(string name,address wallet)"
#     );

PERSON_TYPEHASH: constant(bytes32) = keccak256(b'Person(string name,address wallet)')

#     bytes32 constant MAIL_TYPEHASH = keccak256(
#         "Mail(Person from,Person to,string contents)"
#     );

MAIL_TYPEHASH: constant(bytes32) = keccak256(b'Mail(Person from,Person to,string contents)Person(string name,address wallet)')

#     bytes32 DOMAIN_SEPARATOR;

#     constructor () public {
#         DOMAIN_SEPARATOR = hash(EIP712Domain({
#             name: "Ether Mail",
#             version: '1',
#             blah: 1,
#             // verifyingContract: this
#             verifyingContract: 0xCcCCccccCCCCcCCCCCCcCcCccCcCCCcCcccccccC
#         }));
#     }

#     function hash(EIP712Domain eip712Domain) internal pure returns (bytes32) {
#         return keccak256(abi.encode(
#             EIP712DOMAIN_TYPEHASH,
#             keccak256(bytes(eip712Domain.name)),
#             keccak256(bytes(eip712Domain.version)),
#             eip712Domain.blah,
#             eip712Domain.verifyingContract
#         ));
#     }

@internal
@view
def hash_domain(_domain: EIP712Domain) -> bytes32:
    return keccak256(_abi_encode(
        EIP712DOMAIN_TYPEHASH,
        keccak256(_domain.name),
        keccak256(_domain.version),
        _domain.blah,
        _domain.verifyingContract,
    ))

#     function hash(Person person) internal pure returns (bytes32) {
#         return keccak256(abi.encode(
#             PERSON_TYPEHASH,
#             keccak256(bytes(person.name)),
#             person.wallet
#         ));
#     }

@internal
@view
def hash_person(_person: Person) -> bytes32:
    return keccak256(_abi_encode(
        PERSON_TYPEHASH,
        keccak256(_person.name),
        _person.wallet,
    ))

#     function hash(Mail mail) internal pure returns (bytes32) {
#         return keccak256(abi.encode(
#             MAIL_TYPEHASH,
#             hash(mail.from),
#             hash(mail.to),
#             keccak256(bytes(mail.contents))
#         ));
#     }

@internal
@view
def hash_mail(_mail: Mail) -> bytes32:
    return keccak256(_abi_encode(
        PERSON_TYPEHASH,
        self.hash_person(_mail.fromPerson),
        self.hash_person(_mail.toPerson),
        keccak256(_mail.contents),
    ))

#     function verify(Mail mail, uint8 v, bytes32 r, bytes32 s) internal view returns (bool) {
#         // Note: we need to use `encodePacked` here instead of `encode`.
#         bytes32 digest = keccak256(abi.encodePacked(
#             "\x19\x01",
#             DOMAIN_SEPARATOR,
#             hash(mail)
#         ));
#         return ecrecover(digest, v, r, s) == mail.from.wallet;
#     }


@internal
@view
def digest(_mail: Mail) -> bytes32:

    # Create the domain information
    eip712Domain: EIP712Domain = EIP712Domain({
        name: b'VeriHash',
        version: b'1',
        blah: 1,
        verifyingContract: self,
    })

    return keccak256(_abi_encode(
        '\x19\x01',
        self.hash_domain(eip712Domain),
        self.hash_mail(_mail),
    ))


@external
@view
def verify_mail(_mail: Mail,
                _signature: Bytes[65]) -> address:

    # Split the signature into the r, s, and v components
    r: uint256 = convert(slice(_signature, 0, 32), uint256)
    s: uint256 = convert(slice(_signature, 32, 32), uint256)
    v: uint256 = convert(slice(_signature, 64, 1), uint256)

    # Return if the signer's address matches the caller's address
    # https://vyper.readthedocs.io/en/stable/built-in-functions.html#ecrecover
    # return ecrecover(prefixedHashedMessage, v, r, s) == msg.sender
    return ecrecover(self.digest(_mail), v, r, s)
    
#     function test() public view returns (bool) {
#         // Example signed message
#         Mail memory mail = Mail({
#             from: Person({
#                name: "Cow",
#                wallet: 0xCD2a3d9F938E13CD947Ec05AbC7FE734Df8DD826
#             }),
#             to: Person({
#                 name: "Bob",
#                 wallet: 0xbBbBBBBbbBBBbbbBbbBbbbbBBbBbbbbBbBbbBBbB
#             }),
#             contents: "Hello, Bob!"
#         });
#         uint8 v = 28;
#         bytes32 r = 0x4355c47d63924e8a72e509b65029052eb6c299d53a04e167c5775fd466751c9d;
#         bytes32 s = 0x07299936d304c153f6443dfa05f40ff007d72911b6f72307f996231605b91562;
        
#         assert(DOMAIN_SEPARATOR == 0xf2cee375fa42b42143804025fc449deafd50cc031ca257e0b194a650a912090f);
#         assert(hash(mail) == 0xc52c0ee5d84264471806290a3f2c4cecfc5490626bf912d01f240d7a274b371e);
#         assert(verify(mail, v, r, s));
#         return true;
#     }
# }