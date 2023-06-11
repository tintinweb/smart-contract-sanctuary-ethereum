// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13;

import "./Users.sol";
// import "./Verifier.sol";

contract Authentication {
    Users private usersContract;
    // Verifier private verifierContract;

    constructor(address _usersContractAddress) {
        usersContract = Users(_usersContractAddress);
        // verifierContract = Verifier(_verifierContractAddress);
    }

    //login with nickName and signature
    function loginUser(bytes32 messageHash, uint8 v, bytes32 r, bytes32 s, string memory nickName) public view returns (bool) {
        address signer = usersContract.getUserByNickName(nickName);
        bytes32 prefixedHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash));
        address recoveredSigner = ecrecover(prefixedHash, v, r, s);
        // return recoveredSigner;
        return recoveredSigner == signer;
    }

    // function authenticateObject(uint256 _objectIndex, uint256[] memory _proof, uint256[] memory _inputs) public view returns (bool) {
    //     // return verifierContract.verifyProof(_proof, _inputs, _objectIndex);
    // }
}

// SPDX-License-Identifier: MIT 
pragma solidity ^0.8.13;

contract Users {
    struct User {
        string nickname;
        address publicKey;
        address accountAddress;
    }
    
    mapping (address => User) users;
    mapping (string => address) nicknameToAddress;

    event UserRegistered(string nickName, address publicKey, address accountAddress);

    //registerUser
    function registerUser(string memory nickName, address publicKey, address walletAddress) public returns (bool) {
        require(nicknameToAddress[nickName] == address(0), "Nickname already exists");
        require(walletAddress != address(0), "Invalid wallet address");
        require(publicKey != address(0), "Invalid public key");
        require(users[publicKey].publicKey != publicKey, "User already exists");
        
        require(bytes(nickName).length > 0, "Nickname can't be empty");

        users[publicKey] = User(nickName, publicKey, walletAddress);
        nicknameToAddress[nickName] = publicKey;

        emit UserRegistered(nickName, publicKey, walletAddress);

        return true;
    }

    //getUserByNickName
    function getUserByNickName(string memory nickName) public view returns (address) {
        return nicknameToAddress[nickName];
    }

    // function getUser() public view returns (string memory nickName, address publicKey) {
    //     User storage user = users[publicKey];
    //     require(user.publicKey == publicKey, "User does not exist");

    //     return (user.nickname, user.publicKey);
    // }

    function isUserRegistered(string memory nickName) public view returns (bool) {
        address userAddress = nicknameToAddress[nickName];
        if (userAddress != address(0)) {
            return true;
        }
        return false;
    }

    function getAccountAddress(string memory nickName) public view returns (address){
        require(nicknameToAddress[nickName] != address(0), "User does not exist");
        return users[nicknameToAddress[nickName]].accountAddress;
    }

    // function updateUser(string memory nickName, address publicKey) public {
    //     User storage user = users[msg.sender];
    //     require(users[publicKey].publicKey == publicKey, "User does not exist");

    //     user.nickname = nickName;
    // }

    // function deleteUser(address publicKey) public {
    //     require(users[publicKey].publicKey == publicKey, "User does not exist");

    //     delete users[publicKey];
    // }
}