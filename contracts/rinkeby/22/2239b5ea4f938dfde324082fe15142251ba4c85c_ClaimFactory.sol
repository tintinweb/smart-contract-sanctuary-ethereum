// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.6;

import "./ECDSA.sol";
import "./EIP712.sol";
import "./Claim.sol";

contract ClaimFactory is EIP712 {
    address[] public claimContractAddresses;
    address private deploymentAddress;
    
    /// signature information
    string private constant SINGING_DOMAIN = "GLOWLABS";
    string private constant SIGNATURE_VERSION = "4";

    event ClaimCreated(Claim claim);

    constructor() EIP712(SINGING_DOMAIN, SIGNATURE_VERSION) {
        deploymentAddress = msg.sender;
    }


    /// @dev    Creates a new claim contract and returns its address- invoked by the company
    /// @param  companyTokenAddress The address of the company's token for claiming
    /// @param  companyName The name of the company
    /// @param  signature The signature from the frontend
    /// @return The address of the newly created claim contract
    function createNewClaimContract(address companyTokenAddress, string memory companyName, bytes memory signature) external returns (address) {
        /// server side signature
        require(check(companyName, signature) == msg.sender, "Signature Invalid"); 
        Claim claim = new Claim(companyTokenAddress);

        claimContractAddresses.push(address(claim));

        address claimContractAddress = address(claim);

        emit ClaimCreated(claim);
        
        return claimContractAddress;
    }


    /// @dev    Gets the claim addresses for the deployed contracts
    /// @return The claim addresses array
    function getClaimAddresses() external view returns (address[] memory) {
        return claimContractAddresses;
    }


    /// @dev    Only valid companies can invoke the createNewClaimContract function
    /// @param  name The name of the company
    /// @param  signature The signature from the frontend
    /// @return Address that is allowed to invoke the function
    function check(string memory name, bytes memory signature) public view returns (address) {
        return _verify( name, signature);
    }

    /// @dev    Helper for check()
    /// @param  name The name of the company
    /// @param  signature The signature from the frontend
    /// @return Address that is allowed to invoke the function
    function _verify(string memory name, bytes memory signature) internal view returns (address) {
        bytes32 digest = _hash(name);
        return ECDSA.recover(digest, signature);
    }

    /// @dev    Helper for _verify()
    /// @param  name The name of the company
    /// @return Bytes32 hash of the name
    function _hash(string memory name) internal view returns (bytes32) {
        return _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Web3Struct(string name)"),
            keccak256(bytes(name))
        )));
	}
}