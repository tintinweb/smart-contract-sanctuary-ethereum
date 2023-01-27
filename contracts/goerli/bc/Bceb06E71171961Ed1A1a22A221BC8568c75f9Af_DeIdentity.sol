//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract DeIdentity {
    // Structure to define an identity token
    struct IdentityToken {
        address user;
        bool isSigned;
        bool isRejected;
        bytes attribute1;
        bytes attribute2;
        bytes attribute3;
        bytes attribute4;
        bytes attribute5;
        bytes[] signature;
    }

    // Mapping to store the identity tokens
    mapping(address => IdentityToken) identityTokens;

    address public admin;
    address[] public identityTokensKeys;
    address[] public serviceProviders;
    struct ServiceToken {
        address serviceProvider;
        address user;
        bytes serviceAttribute1;
        bytes serviceAttribute2;
        bytes serviceAttribute3;
        bytes serviceAttribute4;
        // bytes serviceAttribute5;
        bytes identityAttributeReference1;
        bytes identityAttributeReference2;
        bytes identityAttributeReference3;
        bytes identityAttributeReference4;
        bytes identityAttributeReference5;
        uint validTill;
    }

    // Mapping to store the service tokens
    mapping(address => ServiceToken[]) serviceTokens;
    mapping(address => bytes) public providerPublicKeys;

    constructor() {
        admin = msg.sender;
    }

    //Function to store public key
    function storePublicKey(bytes memory _publicKey) public {
        providerPublicKeys[msg.sender] = _publicKey;
    }

    //Funtion to retrive public key
    function getPublicKey(address _address) public view returns (bytes memory) {
        return providerPublicKeys[_address];
    }

    //function to get user identity token if verified
    function getMyToken() public view returns (int256) {
        if (identityTokens[msg.sender].isSigned == true) {
            return 0;
        } else if (identityTokens[msg.sender].isRejected == true) {
            return 1;
        } else {
            return 2;
        }
    }

    // Function to add service providers
    function addServiceProvider(address serviceProvider) public {
        require(msg.sender == admin, "Only admin can add service providers.");
        serviceProviders.push(serviceProvider);
    }

    //Function to get all service providers
    function getServiceProviders() public view returns (address[] memory) {
        return serviceProviders;
    }

    // Function to create an identity token
    function createIdentityToken(
        bytes memory attribute1,
        bytes memory attribute2,
        bytes memory attribute3,
        bytes memory attribute4,
        bytes memory attribute5
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
            new bytes[](0)
        );
        identityTokensKeys.push(msg.sender);
    }

    // get all untouched identity tokens
    // function getUnsignedRejectedIdentityTokens()
    //     public
    //     view
    //     returns (address[] memory)
    // {
    //     // Create an empty array to store the unsigned and rejected identity tokens
    //     address[] memory unsignedRejectedTokens;

    //     // Iterate over the keys
    //     for (uint256 i = 0; i < identityTokensKeys.length; i++) {
    //         address user = identityTokensKeys[i];
    //         // Check if the token is not signed and not rejected
    //         if (
    //             !identityTokens[user].isSigned &&
    //             !identityTokens[user].isRejected
    //         ) {
    //             // Add the token to the array
    //             unsignedRejectedTokens[unsignedRejectedTokens.length] = user;
    //         }
    //     }
    //     // Return the array of unsigned and rejected identity tokens
    //     return unsignedRejectedTokens;
    // }

    function getUnsignedRejectedIdentityTokens()
        public
        view
        returns (address[] memory)
    {
        // Create an empty array to store the unsigned and rejected identity tokens
        address[] memory unsignedRejectedTokens;
        unsignedRejectedTokens = new address[](100);
        // Iterate over the keys
        for (uint256 i = 0; i < identityTokensKeys.length; i++) {
            address user = identityTokensKeys[i];
            // Check if the token is not signed and not rejected
            uint256 a = 0;
            if (
                !identityTokens[user].isSigned &&
                !identityTokens[user].isRejected
            ) {
                // Use safe math to increase the array size
                // unsignedRejectedTokens.length = unsignedRejectedTokens.length.add(1);
                // Add the token to the array
                unsignedRejectedTokens[a] = user;
                a = i + 1;
            }
        }
        // Return the array of unsigned and rejected identity tokens
        return unsignedRejectedTokens;
    }

    // Function to get particular Identity token
    function getIdentityToken(address _user)
        public
        view
        returns (IdentityToken memory)
    {
        return identityTokens[_user];
    }

    // Function to sign an identity token by the admin
    function signIdentityToken(
        address user,
        bytes memory attribute1Hash,
        bytes memory attribute2Hash,
        bytes memory attribute3Hash,
        bytes memory attribute4Hash,
        bytes memory attribute5Hash
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
        bytes memory serviceAttribute1,
        bytes memory serviceAttribute2,
        bytes memory serviceAttribute3,
        bytes memory serviceAttribute4,
        // bytes memory serviceAttribute5,
        bytes memory identityAttributeReference1,
        bytes memory identityAttributeReference2,
        bytes memory identityAttributeReference3,
        bytes memory identityAttributeReference4,
        bytes memory identityAttributeReference5,
        uint validTill
    ) public {
        serviceTokens[serviceProvider].push(
            ServiceToken(
                serviceProvider,
                msg.sender,
                serviceAttribute1,
                serviceAttribute2,
                serviceAttribute3,
                serviceAttribute4,
                // serviceAttribute5,
                identityAttributeReference1,
                identityAttributeReference2,
                identityAttributeReference3,
                identityAttributeReference4,
                identityAttributeReference5,
                validTill
                // false
            )
        );
    }

    // function getServiceTokens(address serviceProvider)
    //     public
    //     view
    //     returns (ServiceToken[] memory)
    // {
    //     // uint256 count = serviceTokens[msg.sender].length;
    //     // ServiceToken[] memory result = new ServiceToken[](count);
    //     // for (uint256 i = 0; i < count; i++) {
    //     //     if (
    //     //         serviceTokens[msg.sender][i].serviceProvider == serviceProvider
    //     //     ) {
    //     //         result[i] = serviceTokens[msg.sender][i];
    //     //     }
    //     // }
    //     // return result;
    //      return serviceTokens[serviceProvider];
    // }

    function getServiceTokens(address serviceProvider)
        public
        view
        returns (ServiceToken[] memory)
    {
        ServiceToken[] memory result = new ServiceToken[](serviceTokens[serviceProvider].length);
        uint counter = 0;
        for (uint i = 0; i < serviceTokens[serviceProvider].length; i++) {
            if (serviceTokens[serviceProvider][i].validTill > block.timestamp) {
                result[counter] = serviceTokens[serviceProvider][i];
                counter++;
            }
        }
        return result;
    }
    function getServiceTokensAgain(address serviceProvider)
        public
        view
        returns (ServiceToken[] memory)
    {
        
        return serviceTokens[serviceProvider];
    }
//     function getServiceTokens(address serviceProvider) public view returns (ServiceToken[] memory) {
//     ServiceToken[] memory serviceTokensArr;
//     for (uint i = 0; i < serviceTokenCount; i++) {
//         if (block.timestamp <= serviceTokens[serviceProvider][i].validTill) {
//             serviceTokensArr.push(serviceTokens[serviceProvider][i]);
//         }
//     }
//     return serviceTokensArr;
// }
//     function getServiceTokens(address serviceProvider) public view returns (ServiceToken[] memory) {
//     ServiceToken[] memory serviceTokensArr;
//     for (uint i = 0; i < serviceTokens[serviceProvider].length; i++) {
//         if (block.timestamp <= serviceTokens[serviceProvider][i].validTill) {
//             serviceTokensArr.push(serviceTokens[serviceProvider][i]);
//         }
//     }
//     return serviceTokensArr;
// }
//     function getServiceTokensByProvider(address serviceProvider) public view returns (ServiceToken[] memory) {
//     ServiceToken[] memory result = new ServiceToken[](0);
//     for (address i = address(0); i < address(serviceTokens.length); i++) {
//         for (uint256 j = 0; j < serviceTokens[i].length; j++) {
//             if (serviceTokens[i][j].serviceProvider == serviceProvider) {
//                 result.push(serviceTokens[i][j]);
//             }
//         }
//     }
//     return result;
// }
}