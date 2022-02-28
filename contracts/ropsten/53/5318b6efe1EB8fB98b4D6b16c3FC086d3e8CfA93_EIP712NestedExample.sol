pragma solidity ^0.5.0;
pragma experimental ABIEncoderV2;

contract EIP712NestedExample {
    uint256 constant chainId = 5; // for Goerli test net. Change it to suit your network.

    struct Unit {
        string actionType;
        uint256 timestamp;
        Identity authorizer;
    }

    struct Identity {
        uint256 userId;
        address wallet;
    }
    /* if chainId is not a compile time constant and instead dynamically initialized,
     * the hash calculation seems to be off and ecrecover() returns an unexpected signing address
    // uint256 internal chainId;
    // constructor(uint256 _chainId) public{
    //     chainId = _chainId;
    // }
    */

    // EIP-712 boilerplate begins
    event SignatureExtracted(address indexed signer, string action);

    // string private constant EIP712_DOMAIN = "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)";
    // string private constant IDENTITY_TYPE = "Identity(uint256 userId,address wallet)";
    // string private constant UNIT_TYPE = "Unit(string actionType,uint256 timestamp,Identity authorizer)Identity(uint256 userId,address wallet)";

    // type hashes. Hash of the following strings:
    // 1. EIP712 Domain separator.
    // 2. string describing identity type
    // 3. string describing message type (enclosed identity type description included in the string)

    bytes32 private constant EIP712_DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant IDENTITY_TYPEHASH = keccak256("Identity(uint256 userId,address wallet)");
    bytes32 private constant UNIT_TYPEHASH = keccak256("Unit(string actionType,uint256 timestamp,Identity authorizer)Identity(uint256 userId,address wallet)");

    bytes32 private DOMAIN_SEPARATOR = keccak256(abi.encode(
        EIP712_DOMAIN_TYPEHASH,
        keccak256("VerifierApp101"),  // string name
        keccak256("1"),  // string version
        chainId,  // uint256 chainId
        0x8c1eD7e19abAa9f23c476dA86Dc1577F1Ef401f5  // address verifyingContract
    ));


     // functions to generate hash representation of the struct objects
    function hashIdentity(Identity memory identity) private pure returns (bytes32) {
        return keccak256(abi.encode(
            IDENTITY_TYPEHASH,
            identity.userId,
            identity.wallet
        ));
    }
    function hashUnit(Unit memory unitobj) private view returns (bytes32) {
        return keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(
                    UNIT_TYPEHASH,
                    keccak256(bytes(unitobj.actionType)),
                    unitobj.timestamp,
                    hashIdentity(unitobj.authorizer)
                ))
            ));
    }

    function submitProof(Unit memory _msg, bytes32 sigR, bytes32 sigS, uint8 sigV) public {
        address recovered_signer = ecrecover(hashUnit(_msg), sigV, sigR, sigS);
        emit SignatureExtracted(recovered_signer, _msg.actionType);

    }

    // this contains a pre-filled struct Unit and the signature values for the same struct calculated by sign_nested.js
    function testVerify() public view returns (bool) {
        Identity memory authorizer_obj = Identity({
            userId: 123,
            wallet: 0x00EAd698A5C3c72D5a28429E9E6D6c076c086997
        });

        Unit memory _msgobj = Unit({
           actionType: 'Action7440',
           timestamp: 1570112162,
           authorizer: authorizer_obj
        });

        bytes32 sigR = 0xa3fca59577ccc13eeac30d0e7bf3f851392cada84f8e96adeaaffd28432f32e3;
        bytes32 sigS = 0x07af1f752bbae28378cd7c6cd495dfaf25dfc7ec93d872547367e0785cafd425;
        uint8 sigV = 27;

        address signer = 0x00EAd698A5C3c72D5a28429E9E6D6c076c086997;

        return signer == ecrecover(hashUnit(_msgobj), sigV, sigR, sigS);
    }
}