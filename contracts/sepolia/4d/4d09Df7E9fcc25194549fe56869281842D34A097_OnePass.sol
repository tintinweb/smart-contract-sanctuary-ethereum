// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

contract OnePass {
    address private owner;
    string private contractHash;
    uint256 private vaultCount = 0;
    uint256 private loginCount = 0;

    struct User {
        string fName;
        string lName;
        string contact;
        string email;
        string hashPassPhrase;
        string encPrivateKey;
        string publicKey;
        string masterEncKey;
        string[] transactionHashes;
        uint256 numVaults;
        AssignedVault[] assignedVaults;
    }

    struct AssignedVault {
        uint256 vaultIndex;
        string vaultName;
        string note;
    }

    struct VaultUser {
        bool isOwner;
        uint256 index;
        string email;
        string encVaultPass;
    }

    struct Vault {
        uint256 index;
        string name;
        string note;
        string owner;
        uint256 numLogins;
        uint256 numUsers;
        string vaultKeyHash;
        VaultUser[] vaultUsers;
        Login[] logins;
    }

    struct Login {
        uint256 index;
        string owner;
        string name;
        string website;
        string userName;
        string password;
    }

    struct TxnHash {
        string tHash;
    }

    mapping(uint256 => Vault) private vaults;
    mapping(uint256 => Login) private vaultLogins;
    mapping (string => AssignedVault) private assignedVaults;
    mapping(string => User) private users;
    mapping(string => VaultUser) private vaultUsers;

    //Constructor
    function InitiateContract(string memory contHash) public {
        owner = msg.sender;
        contractHash = contHash;
    }

    // Require Owner
    function requireOwner() private view {
        require(msg.sender == owner, "You are not the user");
    }

    // Compare Strings
    function compareStrings(
        string memory str1,
        string memory str2
    ) public pure returns (bool success) {
        if (bytes(str1).length != bytes(str2).length) {
            return false;
        }
        return keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2));
    }

    // Find Vault User
    function findVaultUser(
        string memory email,
        uint256 vaultIndex
    ) private view returns (bool success){
        for(uint256 i = 0; i < vaults[vaultIndex].numUsers; i++ ){
            if(compareStrings(email, vaults[vaultIndex].vaultUsers[i].email) == true){
                return true;
            }
            else {
                continue;
            }
        }
        return false;
    }

    // Require object owner
    function requireObjOwner(
        string memory str1,
        string memory str2
    ) private pure {
        require(bytes(str1).length == bytes(str2).length, "You are not the owner of the object");
        require(keccak256(abi.encodePacked(str1)) == keccak256(abi.encodePacked(str2)), "You are not the owner of the object");
    }

    // User Functions
    function addUserKeys(
        string memory email,
        string memory encPrivateKey,
        string memory publicKey,
        string memory masterEncKey
    ) public returns (bool success) {
        requireOwner();

        users[email].email = email;
        users[email].encPrivateKey = encPrivateKey;
        users[email].publicKey = publicKey;
        users[email].masterEncKey = masterEncKey;
        return true;
    }

    function addUserData(
        string memory email,
        string memory fName,
        string memory lName,
        string memory contact,
        string memory hashPassPhrase
    ) public returns (bool success) {
        requireOwner();
        require(compareStrings(users[email].email, "") == false, "User Not Found");
        requireObjOwner(email, users[email].email);
        users[email].fName = fName;
        users[email].lName = lName;
        users[email].contact = contact;
        users[email].hashPassPhrase = hashPassPhrase;

        return true;
    }

    function addTxnHash(
        string memory email,
        string memory txnHash
    ) public returns (bool success) {
        requireOwner();
        require(compareStrings(users[email].email, "") == false, "User Not Found");
        users[email].transactionHashes.push(txnHash);
        return true;
    }

    function getAllTxnHashes(
        string memory _email
    ) public view returns (string memory email, string[] memory) {
        require(compareStrings(users[_email].email, "") == false, "User Not Found");
        return (users[_email].email, users[_email].transactionHashes);
    }

    function getPrivateKey(
        string memory email
    ) public view returns (string memory encPrivateKey) {
        require(compareStrings(users[email].email, "") == false, "User Not Found");
        return users[email].encPrivateKey;
    }

    function getPublicKey(
        string memory email
    ) public view returns (string memory publicKey) {
        require(compareStrings(users[email].email, "") == false, "User Not Found");
        return users[email].publicKey;
    }

    function getMasterEncKey(
        string memory email
    ) public view returns (string memory masterEncKey) {
        require(compareStrings(users[email].email, "") == false, "User Not Found");
        return users[email].masterEncKey;
    }

    function getUserData(
        string memory _email
    )
        public
        view
        returns (
            string memory email,
            string memory fName,
            string memory lName,
            string memory contact,
            AssignedVault[] memory
        )
    {
        return (
            users[_email].email,
            users[_email].fName,
            users[_email].lName,
            users[_email].contact,
            users[_email].assignedVaults
        );
    }

    function removeUser(string memory email) public returns (bool success) {
        requireOwner();
        delete users[email];
        return true;
    }

    function getUserHashPass(
        string memory email
    ) public view returns (string memory hashPassPhrase) {
        return users[email].hashPassPhrase;
    }

    // Vault Functions
    function createVault(
        string memory email,
        string memory name,
        string memory note,
        string memory encVaultKey,
        string memory vaultKeyHash
    ) public returns (bool sucess) {
        requireOwner();
        require(compareStrings(users[email].email, "") == false, "User Not Found");
        User storage tempUser = users[email];
        Vault storage tempVault = vaults[vaultCount];

        tempVault.index = vaultCount;
        tempVault.name = name;
        tempVault.note = note;
        tempVault.owner = email;
        tempVault.numLogins = 0;
        tempVault.numUsers = 0;
        tempVault.vaultKeyHash = vaultKeyHash;

        VaultUser storage user = vaultUsers[email];
        user.email = email;
        user.isOwner = true;
        user.encVaultPass = encVaultKey;
        user.index = tempVault.numUsers;

        AssignedVault storage asVault = assignedVaults[vaultKeyHash];
        asVault.vaultName = name;
        asVault.vaultIndex = tempUser.numVaults;
        asVault.note = note;

        tempUser.assignedVaults.push(asVault);
        tempUser.numVaults++;

        tempVault.vaultUsers.push(user);
        tempVault.numUsers++;
        vaultCount++;

        delete assignedVaults[vaultKeyHash];
        delete vaultUsers[email];
        return true;
    }

    function getVault(uint256 index) public view returns (Vault memory) {
        return vaults[index];
    }

    function getVaultKeyHash(uint256 vaultIndex) public view returns(string memory vaultKeyHash){
        return vaults[vaultIndex].vaultKeyHash;
    }

    function getAssignVaults(string memory email) public view returns(AssignedVault[] memory){
        return users[email].assignedVaults;
    }

    function getUserEncVaultKey(
        string memory email, 
        uint256 vaultIndex
        ) public view returns(string memory encVaultKey){
            for(uint256 i; i < vaults[vaultIndex].numUsers; i++){
                if(compareStrings(vaults[vaultIndex].vaultUsers[i].email, email) == true){
                    return vaults[vaultIndex].vaultUsers[i].encVaultPass;
                }
            }
        }

    function getUserVaults(
        string memory email
    ) public view returns(
        Vault[] memory
    ){
        Vault[] memory userVaults = new Vault[](vaultCount);
        uint256 counter = 0;
        for(uint256 i = 0; i  < vaultCount; i++){
            for(uint256 j = 0; j < vaults[i].numUsers; j++){
                if(compareStrings(email, vaults[i].vaultUsers[j].email) == true){
                    userVaults[counter] = vaults[i];
                    counter++;
                }
            }
        }
        return userVaults;
    }

    function updateVault(
        uint256 vaultIndex,
        string memory userEmail,
        string memory name,
        string memory note
    ) public returns (bool success) {
        requireOwner();
        require(compareStrings(users[userEmail].email, "") == false, "User Not Found");
        requireObjOwner(userEmail, vaults[vaultIndex].owner);
        vaults[vaultIndex].name = name;
        vaults[vaultIndex].note = note;
        return true;
    }

    function addVaultUser(
        uint256 vaultIndex,
        string memory userEmail,
        string memory addUserEmail,
        string memory encVaultKey
    ) public returns (bool success) {
        requireOwner();
        require(compareStrings(users[addUserEmail].email, "") == false, "User Not Found");
        requireObjOwner(userEmail, vaults[vaultIndex].owner);
        User storage tempUser = users[addUserEmail];

        AssignedVault storage tempVault = assignedVaults[encVaultKey];
        tempVault.vaultIndex = tempUser.numVaults;
        tempVault.vaultName = vaults[vaultIndex].name;
        tempVault.note = vaults[vaultIndex].note;

        tempUser.assignedVaults.push(tempVault);
        
        VaultUser storage user = vaultUsers[addUserEmail];
        user.email = addUserEmail;
        user.isOwner = false;
        user.encVaultPass = encVaultKey;
        user.index = vaults[vaultIndex].numUsers;

        vaults[vaultIndex].vaultUsers.push(user);
        vaults[vaultIndex].numUsers++;
        delete vaultUsers[addUserEmail];
        delete assignedVaults[encVaultKey];
        return true;
    }

    function removeVaultUser(
        string memory email,
        uint256 vaultIndex,
        uint256 userIndex
    ) public returns (bool success) {
        requireOwner();
        requireObjOwner(email, vaults[vaultIndex].owner);
        require(compareStrings(users[email].email, "") == false, "User Not Found");

        Vault storage tempVault = vaults[vaultIndex];
        User storage tempUser = users[email];
        
        for(uint256 i = 0; i < tempUser.numVaults; i++){
            if(compareStrings(tempUser.assignedVaults[i].vaultName, tempVault.name) == true){
                tempUser.assignedVaults[i].vaultName = '';
                tempUser.assignedVaults[i].note = '';
                break;
            }
        }
        
        for(uint256 i = 0; i < tempVault.numUsers; i++){
            if(compareStrings(tempVault.vaultUsers[i].email, vaults[vaultIndex].vaultUsers[userIndex].email) == true){
                tempVault.vaultUsers[i].isOwner = false;
                tempVault.vaultUsers[i].encVaultPass = "";
                tempVault.vaultUsers[i].email = "";
            }
        }
        delete vaults[vaultIndex].vaultUsers[userIndex];
        return true;
    }

    function removeVault(
        string memory userEmail,
        uint256 vaultIndex
    ) public returns (bool success) {
        requireOwner();
        require(compareStrings(users[userEmail].email, "") == false, "User Not Found");
        requireObjOwner(userEmail, vaults[vaultIndex].owner);
        Vault storage tempVault = vaults[vaultIndex];
        for(uint256 i = 0; i < tempVault.numUsers; i++){
            if(compareStrings(tempVault.vaultUsers[i].email, "") == false){
                User storage tempUser = users[tempVault.vaultUsers[i].email];
                for(uint256 j = 0; j < tempUser.numVaults; j++){
                    if(compareStrings(tempUser.assignedVaults[j].vaultName, tempVault.name) == true){
                        tempUser.assignedVaults[j].vaultName = "";
                        tempUser.assignedVaults[j].note = "";
                        break;
                    }
                }
                break;
            }
        }

        delete vaults[vaultIndex];
        return true;
    }

    // // Login Functions
    function addVaultLogin(
        string memory email,
        string memory name,
        string memory website,
        string memory userName,
        string memory password,
        uint256 vaultIndex
    ) public returns (bool success) {
        requireOwner();
        require(compareStrings(users[email].email, "") == false, "User Not Found");
        require(findVaultUser(email, vaultIndex) == true, "User not authorized");
        Login storage login = vaultLogins[loginCount];

        login.owner = email;
        login.name = name;
        login.website = website;
        login.userName = userName;
        login.password = password;
        login.index = vaults[vaultIndex].numLogins;

        vaults[vaultIndex].logins.push(login);
        vaults[vaultIndex].numLogins++;
        loginCount++;
        delete vaultLogins[loginCount];
        return true;
    }

    function getAllVaultLogins(
        uint256 vaultIndex
    ) public view returns (Login[] memory) {
        return vaults[vaultIndex].logins;
    }

    function updateVaultLogin(
        uint256 loginIndex,
        uint256 vaultIndex,
        string memory email,
        string memory name,
        string memory website,
        string memory userName,
        string memory password
    ) public returns (bool success) {
        requireOwner();
        require(compareStrings(users[email].email, "") == false, "User Not Found");
        requireObjOwner(email, vaults[vaultIndex].logins[loginIndex].owner);

        vaults[vaultIndex].logins[loginIndex].name = name;
        vaults[vaultIndex].logins[loginIndex].website = website;
        vaults[vaultIndex].logins[loginIndex].userName = userName;
        vaults[vaultIndex].logins[loginIndex].password = password;
        return true;
    }

    function removeVaultLogin(
        string memory email,
        uint256 vaultIndex,
        uint256 loginIndex
    ) public returns (bool success) {
        requireOwner();
        require(compareStrings(users[email].email, "") == false, "User Not Found");
        requireObjOwner(email, vaults[vaultIndex].logins[loginIndex].owner);
        delete vaults[vaultIndex].logins[loginIndex];
        return true;
    }

    function getOwner() public view returns (address ownerAddress) {
        return owner;
    }
}