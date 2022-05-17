// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


/// @title Responsible for creating freelancer profiles
contract Profile {
    mapping(address => uint256) private addressToIndex;

    address[] private addresses;
    string[] public ipfsHashes;

    event UserCreated(
        uint256 index,
        address userAddress,
        string ipfsHash
    );

    event UserUpdated(
        uint256 index,
        address userAddress,
        string ipfsHash
    );

    function User() public {
        // mappings are virtually initialized to zero values so we need to "waste" the first element of the arrays
        // instead of wasting it we use it to create a user for the contract itself
        addresses.push(msg.sender);
        ipfsHashes.push("not-available");
    }

    function createUser2(string memory ipfsHash) public returns (bool success) {
        require(!userExists(msg.sender), "User already exists");
        addresses.push(msg.sender);
        ipfsHashes.push(ipfsHash);
        addressToIndex[msg.sender] = addresses.length - 1;

        return true;
    }

    /**
     * @dev    Creates a user
     * @param  ipfsHash Contains metadata about the user
     * @return success
     */
    function createUser(string memory ipfsHash)
        public
        returns (bool success)
    {
        require(!userExists(msg.sender));

        addresses.push(msg.sender);
        ipfsHashes.push(ipfsHash);
        addressToIndex[msg.sender] = addresses.length - 1;

        emit UserCreated(addresses.length - 1, msg.sender, ipfsHash);
        return true;
    }

    /**
     *  @dev    Lets a user update their metadata by updating the ipfs hash
     *  @param  ipfsHash The username chosen by the user
     *  @return success
    */
    function updateUser(string memory ipfsHash) public returns (bool success) {
        require(userExists(msg.sender), "User already exists");

        ipfsHashes[addressToIndex[msg.sender]] = ipfsHash;
        emit UserUpdated(addresses.length - 1, msg.sender, ipfsHash);
        return true;
    }

    /**
     *  @dev    Checks if a user has already been created
     *  @param  userAddress The account address to check
     *  @return hasIndeed
    */
    function userExists(address userAddress)
        public
        view
        returns (bool hasIndeed)
    {
        return (addressToIndex[userAddress] > 0 || userAddress == addresses[0]);
    }

    /**************************/
    /***   View Functions   ***/
    /**************************/

    /**
     *  @dev    Returns the user count
     *  @return count
    */
    function getUserCount() public view returns (uint256 count) {
        return addresses.length;
    }

    /**
     *  @dev    Returns a user if exist by its index
     *  @param  index The index of the user
    */
    function getUserByIndex(uint256 index)
        public
        view
        returns (
            address userAddress,
            string memory ipfsHash
        )
    {
        require(index < addresses.length, "!user");
        return (addresses[index], ipfsHashes[index]);
    }

    /**
     *  @dev    Returns a user if exist by its address
     *  @param  userAddress The address of the user
    */
    function getUserByAddress(address userAddress)
        public
        view
        returns (
            uint256 index,
            string memory ipfsHash
        )
    {
        require(index < addresses.length);
        return (
            addressToIndex[userAddress],
            ipfsHashes[addressToIndex[userAddress]]
        );
    }
}