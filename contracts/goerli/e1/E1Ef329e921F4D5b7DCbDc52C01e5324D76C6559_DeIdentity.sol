//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DeIdentity {
    // Structure to define an identity token
    struct IdentityToken {
        address user;
        bool isSigned;
        bool isRejected;
        bytes32 attribute1;
        bytes32 attribute2;
        bytes32 attribute3;
        bytes32 attribute4;
        bytes32 attribute5;
        bytes32[] signature;
    }

    // Mapping to store the identity tokens
    mapping(address => IdentityToken) identityTokens;
    address public admin;
    address[] public identityTokensKeys;
    address[] public serviceProviders;
    struct ServiceToken {
        address serviceProvider;
        address user;
        bytes32[] serviceAttribute;
        bytes32[] identityAttributeReference; // optional
        bool isVerified;
    }

    // Mapping to store the service tokens
    mapping(address => ServiceToken[]) serviceTokens;

    constructor() {
        admin = msg.sender;
    }

    // Function to add service providers
    function addServiceProvider(address serviceProvider) public {
        require(msg.sender == admin, "Only admin can add service providers.");
        serviceProviders.push(serviceProvider);
    }

    //Function to get all service providers
    function getServiceProviders()public view returns(address[] memory){
        return serviceProviders;
    }
    // Function to create an identity token
    function createIdentityToken(
        bytes32 attribute1,
        bytes32 attribute2,
        bytes32 attribute3,
        bytes32 attribute4,
        bytes32 attribute5
    ) public {
        require(
            !identityTokens[msg.sender].isSigned,
            "Identity token already created."
        );
        identityTokens[msg.sender] = IdentityToken(
            msg.sender,
            false,
            false,
            attribute1,
            attribute2,
            attribute3,
            attribute4,
            attribute5,
            new bytes32[](0)
        );
        identityTokensKeys.push(msg.sender);
    }

    // get all untouched identity tokens
    function getUnsignedRejectedIdentityTokens()
        public
        view
        returns (address[] memory)
    {
        // Create an empty array to store the unsigned and rejected identity tokens
        address[] memory unsignedRejectedTokens;

        // Iterate over the keys
        for (uint256 i = 0; i < identityTokensKeys.length; i++) {
            address user = identityTokensKeys[i];
            // Check if the token is not signed and not rejected
            if (
                !identityTokens[user].isSigned &&
                !identityTokens[user].isRejected
            ) {
                // Add the token to the array
                unsignedRejectedTokens[unsignedRejectedTokens.length] = user;
            }
        }
        // Return the array of unsigned and rejected identity tokens
        return unsignedRejectedTokens;
    }

    // Function to sign an identity token by the admin
    function signIdentityToken(
        address user,
        bytes32 attribute1Hash,
        bytes32 attribute2Hash,
        bytes32 attribute3Hash,
        bytes32 attribute4Hash,
        bytes32 attribute5Hash
    ) public {
        require(msg.sender == admin, "Only admin can sign identity token.");
        require(
            !identityTokens[user].isSigned,
            "Identity token already signed."
        );
        require(
            !identityTokens[user].isRejected,
            "Identity token is rejected, can't be signed."
        );
        identityTokens[user].isSigned = true;

        //Add the signature hash of each attribute here
        identityTokens[user].signature.push(attribute1Hash);
        identityTokens[user].signature.push(attribute2Hash);
        identityTokens[user].signature.push(attribute3Hash);
        identityTokens[user].signature.push(attribute4Hash);
        identityTokens[user].signature.push(attribute5Hash);
    }

    function addServiceToken(
        address serviceProvider,
        bytes32[] memory serviceAttribute,
        bytes32[] memory identityAttributeReference
    ) public {
        serviceTokens[msg.sender].push(
            ServiceToken(
                serviceProvider,
                msg.sender,
                serviceAttribute,
                identityAttributeReference,
                false
            )
        );
    }

    function getServiceTokens(address serviceProvider)
        public
        view
        returns (ServiceToken[] memory)
    {
        uint256 count = serviceTokens[msg.sender].length;
        ServiceToken[] memory result = new ServiceToken[](count);
        for (uint256 i = 0; i < count; i++) {
            if (
                serviceTokens[msg.sender][i].serviceProvider == serviceProvider
            ) {
                result[i] = serviceTokens[msg.sender][i];
            }
        }
        return result;
    }
}