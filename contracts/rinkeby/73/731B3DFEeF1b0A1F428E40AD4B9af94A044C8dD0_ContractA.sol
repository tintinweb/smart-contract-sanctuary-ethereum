pragma solidity ^0.8.0;

contract ContractA{
   string public name = "ContractA" ;

    // NOTE: these hashes are derived and verified in the constructor.
    bytes32 private constant _EIP_712_DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;
    bytes32 private constant _NAME_HASH = 0x9a2ed463836165738cfa54208ff6e7847fd08cbaac309aac057086cb0a144d13;
    bytes32 private constant _VERSION_HASH = 0xe2fd538c762ee69cab09ccd70e2438075b7004dd87577dc3937e9fcc8174bb64;
    bytes32 private constant _ORDER_TYPEHASH = 0xdba08a88a748f356e8faf8578488343eab21b1741728779c9dcfdc782bc800f8;



    function deriveDomainSeparator(uint256 chainId) public pure  returns (bytes32) {
return keccak256(
abi.encode(
_EIP_712_DOMAIN_TYPEHASH, // keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
_NAME_HASH, // keccak256("Wyvern Exchange Contract")
_VERSION_HASH, // keccak256(bytes("2.3"))
chainId, // NOTE: this is fixed, need to use solidity 0.5+ or make external call to support!
address(0x7f268357A8c2552623316e2562D90e642bB538E5)
));
}
}