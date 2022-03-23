/**
 *Submitted for verification at Etherscan.io on 2022-03-22
*/

/**
 *Submitted for verification at Etherscan.io on 2020-05-04
*/

pragma solidity =0.5.16;

contract EIP712Verify{
        
    uint chainId_ = 97;
    bytes32 public DOMAIN_SEPARATOR =   keccak256(abi.encode(
                                        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
                                        keccak256(bytes(name)),
                                        keccak256(bytes(version)),
                                        chainId_,
                                        address(this)
                                    ));
                                    
                                        
    //HERE                                   
    bytes32 public constant PERMIT_TYPEHASH = keccak256("Permit(address holder,address spender,uint256 nonce)");
    // bytes32 public constant PERMIT_TYPEHASH = 0xea2aa0a1be11a07ed86d755c93467f4f82362b452371d1ba94d1715123511acb;
    mapping (address => uint) public nonces;

        
    string  public constant name     = "Dai Stablecoin";
    string  public constant version  = "1";
    uint256 public totalSupply;
    //HERE
    // --- Approve by signature ---
    function permit(address holder, address spender, uint256 nonce,
                     uint8 v, bytes32 r, bytes32 s) public view returns (address)
    {
        bytes32 digest =
            keccak256(abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(abi.encode(PERMIT_TYPEHASH,
                                     holder,
                                     spender,
                                     nonce))
        ));

        require(holder != address(0), "Dai/invalid-address-0");
        require(holder == ecrecover(digest, v, r, s), "Dai/invalid-permit");
        require(nonce == nonces[holder], "Dai/invalid-nonce");
        return ecrecover(digest, v, r, s);
    }
}