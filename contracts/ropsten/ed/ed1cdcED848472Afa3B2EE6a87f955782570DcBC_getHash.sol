// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract getHash {

	bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");


    
    function _hashTypedDataV4(bytes32 structHash, string memory name, string memory version, address idkaddress) internal view virtual returns (bytes32) {
    	return keccak256(abi.encodePacked("\x19\x01", _domainSeparatorV4(name, version, idkaddress), structHash));
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash,
        address idkaddress
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, idkaddress));
    }

    function _domainSeparatorV4(string memory name, string memory version, address idkaddress) internal view returns (bytes32) {
		bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        return _buildDomainSeparator(typeHash, hashedName, hashedVersion, idkaddress);
    }

    function computeHash(
    	address owner,
    	address spender,
    	address value,
    	uint256 deadline,
    	string memory name,
    	string memory version,
    	uint256 nonce,
    	address idkaddress
    	)
		    external
	        view
	        returns (
	            bytes32 hash
	        )
	    {    

    	bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, nonce, deadline));
    
    	hash = _hashTypedDataV4(structHash, name, version, idkaddress);
	}

}