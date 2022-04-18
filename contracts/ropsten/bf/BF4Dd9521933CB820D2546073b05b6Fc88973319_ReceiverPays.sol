// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

contract ReceiverPays {

    bytes32 public DOMAIN_TYPEHASH;
    bytes32 public DOMAIN_SEPARATOR;
 

    string public constant name = "Uniswap V2";
    mapping(address => uint256) public nonces;

    bytes32 PERMIT_TYPEHASH;
    bytes32 structHash;
    bytes32 digest0;
    bytes32 digest;
    address recoveredAddress;

    constructor() {}
     

   function permit(address owner,address spender,uint256 value,uint256 deadline,uint8 v,bytes32 r,bytes32 s) external {

        DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
        DOMAIN_SEPARATOR = keccak256(abi.encode(DOMAIN_TYPEHASH,keccak256(bytes(name)),keccak256(bytes("1")),1,address(this)));
 
        PERMIT_TYPEHASH = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
        structHash = keccak256(abi.encode(PERMIT_TYPEHASH,owner,spender,value,nonces[owner]++,deadline));

        digest0 = keccak256(abi.encode("\x19\x01",DOMAIN_SEPARATOR,structHash));
        digest = keccak256(abi.encodePacked("\x19\x01",DOMAIN_SEPARATOR,structHash));
 
        recoveredAddress = ecrecover(digest, v, r, s);
    }

    // destroy the contract and reclaim the leftover funds.  销毁合同并收回剩余的资金。
    // 客户在这里销毁之前创建的合约，并收回剩余资金
    function shutdown() public {
        selfdestruct(payable(msg.sender));
    }
    

}