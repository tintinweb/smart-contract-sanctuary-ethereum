// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./ECDSA.sol";
import "./EIP712.sol";
import "./Claim.sol";

contract ClaimFactory is EIP712 {
    Claim[] public companyClaimAddresses;
    address private deploymentAddress;
    
    //signature
    string private constant SINGING_DOMAIN = "GLOWLABS";
    string private constant SIGNATURE_VERSION = "4";

    event ClaimCreated(Claim claim);

    constructor() EIP712(SINGING_DOMAIN, SIGNATURE_VERSION) {
        deploymentAddress = msg.sender;
    }

    /// @notice Will need to add signature verification from the frontend to create a new claim contract
    function createNewClaimContract(address companyTokenAddress, string memory companyName, bytes memory signature) external {
        /// msg.sender will be the company deploying the contract with their token as a param
        require(check(companyName, signature) == msg.sender, "Signature Invalid"); //server side signature
        Claim claim = new Claim(companyTokenAddress);

        companyClaimAddresses.push(claim);
        emit ClaimCreated(claim);
    }

    function getClaims() external view returns (Claim[] memory) {
        return companyClaimAddresses;
    }

    /// @dev Only valid companies can invoke the createNreClaimContract function
    function check(string memory name, bytes memory signature) public view returns (address) {
        return _verify( name, signature);
    }

    function _verify(string memory name, bytes memory signature) internal view returns (address) {
        bytes32 digest = _hash(name);
        return ECDSA.recover(digest, signature);
    }

    function _hash(string memory name) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Web3Struct(string name)"),
            keccak256(bytes(name))
        )));
	}
}