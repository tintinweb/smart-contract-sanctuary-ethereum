/**
 *Submitted for verification at Etherscan.io on 2022-06-10
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.5;
// THIS CONTRACT CONTAINS A BUG - DO NOT USE
contract Test {

    mapping(address => uint256) public balancOf;

    constructor(){
        balancOf[address(0x5B38Da6a701c568545dCfcB03FcB875f56beddC4)] = 123;
    }

    function getChainId() public view returns (uint) {
        uint256 chainId;
        assembly { chainId := chainid() }
        return chainId;
    }

    // function balanceOf(address owner) external view returns (uint) {
    //     bytes memory data = delegateToViewImplementation(abi.encodeWithSignature("balanceOf(address)", owner));
    //     return abi.decode(data, (uint));
    // }

    // function delegateToImplementation(bytes memory data) public returns (bytes memory) {
    //     return delegateTo(implementation, data);
    // }

    // function delegateTo(address callee, bytes memory data) internal returns (bytes memory) {
    //     (bool success, bytes memory returnData) = callee.delegatecall(data);
    //     assembly {
    //         if eq(success, 0) {
    //             revert(add(returnData, 0x20), "err001.")
    //         }
    //     }
    //     return returnData;
    // }

    // function delegateToViewImplementation(bytes memory data) public view returns (bytes memory) {
    //     (bool success, bytes memory returnData) = address(this).staticcall(abi.encodeWithSignature("delegateToImplementation(bytes)", data));
    //     assembly {
    //         if eq(success, 0) {
    //             revert(add(returnData, 0x20), "Error err.")
    //         }
    //     }
    //     return abi.decode(returnData, (bytes));
    // }

    function get() public view returns(bytes32){
        bytes32 a = bytes32(keccak256(abi.encode(123)));
        return a;
    }

    function getDecode(bytes memory a) public view returns(uint){
        uint b = abi.decode(a, (uint));
        return b;
    }

    function getKecca() public view returns(bytes32){
        bytes32 aaa = keccak256(abi.encodePacked("repayBorrowAndClaim(uint256,address)"));
        // bytes memory aaa = abi.encode(uint(5));
        return aaa;
    }

    function getKecca1() public view returns(bytes memory, uint256){
        bytes memory aaa = abi.encodeWithSignature("baz(uint32,bool)", 69, true);
        return (aaa, aaa.length);
    }

    function getKecca2() public view returns(bytes memory){
        bytes memory aaa = abi.encodeWithSignature("baz(uint32,bool)");
        return aaa;
    }

    function getKecca3() public view returns(bytes memory){
        bytes memory aaa = abi.encodeWithSignature("adoptDog(uint256)", 17);
        return aaa;
    }

    function getUint256Max() public view returns(uint256){
        // uint256 a;
        return 2**256-1;
    }

    function subTest(uint256 a) public view returns(uint256){
        uint256 b = (a * 5) - 1;
        return b;
    }

    function getETH(address user) public view returns(uint256){
        return address(user).balance;
    }

    function mul(uint256 a, uint256 b) public view returns(uint256){
        uint256 c = a * b;
        return c;
    }

    function uintMax() public view returns(uint256){
        return type(uint256).max;
    }

    // receive() external payable {}

    // function sendd() public{
    //     payable(address(this)).transfer(msg.value);
    // }
    
    uint256 public aa;

    function testTxOrigin(address payable borrower) public{
        require(msg.sender == borrower || tx.origin == borrower, "borrower is wrong");
        aa = 5;
    }

    function divdiv(uint256 a, uint256 b) public view returns(uint256){
        uint256 q = (a * b / 1e18 + a) ;
        return q;
    }

    function div1() public view returns(uint256){
        uint256 a = uint256(20139752276266564416453) * (uint256(1802215381691369288607489405) * 1e18 / uint256(1732951010380371323704545718)) / 1e18  - uint256(19945205479452000000000) - uint256(1000000000000000000000);
        return a;
    }

    function div2() public view returns(uint256){
        uint256 a = uint256(20139752276266564416453) * uint256(1039993203100845073) / 1e18 - uint256(19945205479452000000000) - uint256(1000000000000000000000);
        return a;
    }
    function div3() public view returns(uint256){
        uint256 a = uint256(1802215381691369288607489405) * 1e18 / uint256(1732951010380371323704545718);
        return a;
    }

    function div4() public view returns(uint256){
        uint256 a = uint256(20139752276266564416453) * uint256(1039969030224227107) / 1e18 - uint256(19945205479452000000000) - uint256(1000000000000000000000);
        return a;
    }

    function div5() public view returns(uint256){
        uint256 a = uint256(10) / 3 * 1e18;
        return a;
    }

    function hash(uint256[] memory tokenIds) public view returns(bytes32){
        bytes32 hash1 = keccak256(abi.encode(tokenIds));
        for(uint256 i=0; i<5; i++){
        }
        return hash1;
    }
    
    // function claim(uint256 orderId, uint256 floatAmount, bytes memory signature) external returns(address){
    //     bytes32 hash1 = keccak256(abi.encode(orderId, floatAmount));

    //     bytes32 hash2 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash1));

    //     address signer = recover(hash2, signature);
    //     return signer;
    // }

    function claim(string memory abc, bytes memory signature) external returns(address){
        bytes32 hash1 = keccak256(abi.encode(abc));

        bytes32 hash2 = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash1));

        address signer = recover(hash2, signature);
        return signer;
    }

    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        // Check the signature length
        if (signature.length != 65) {
            revert("ECDSA: invalid signature length");
        }

        // Divide the signature in r, s and v variables
        bytes32 r;
        bytes32 s;
        uint8 v;

        // ecrecover takes the signature parameters, and the only way to get them
        // currently is to use assembly.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }

        return recover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover-bytes32-bytes-} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(bytes32 hash, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (281): 0 < s < secp256k1n ÷ 2 + 1, and for v in (282): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        require(uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0, "ECDSA: invalid signature 's' value");
        require(v == 27 || v == 28, "ECDSA: invalid signature 'v' value");

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        require(signer != address(0), "ECDSA: invalid signature");

        return signer;
    }
}