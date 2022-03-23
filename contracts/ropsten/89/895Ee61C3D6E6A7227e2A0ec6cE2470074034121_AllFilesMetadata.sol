/**
 *Submitted for verification at Etherscan.io on 2022-03-23
*/

// SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.12;



// Part: FileContract

contract FileContract {
    mapping(string => string) private publicKeyToEncryptionKey;

    string private FileName;
    string private IPFSAddress;
    string public OwnerPublicKey;
    string private EncryptionKey;
    string public SecretKey;
    bool public PublicType;
    address owner;

    function addFileMetadata(
        string memory _FileName,
        string memory _IPFSAddress,
        string memory _PublicKey,
        address _owner
    ) external {
        FileName = _FileName;
        IPFSAddress = _IPFSAddress;
        OwnerPublicKey = _PublicKey;
        owner = _owner;
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function mapping_to_encryptionkey(string memory _publickey)
        external
        view
        returns (string memory)
    {
        string memory encryptionKey = publicKeyToEncryptionKey[_publickey];
        return encryptionKey;
    }

    function addEncryptionKey(string memory _EncryptionKey) external {
        bool _false = compareStrings(EncryptionKey, _EncryptionKey);
        require(_false == false);
        EncryptionKey = _EncryptionKey;
        SecretKey = "";
        PublicType = false;
        publicKeyToEncryptionKey[OwnerPublicKey] = _EncryptionKey;
    }

    function addSecretKey(string memory _SecretKey) external {
        bool _false = compareStrings(SecretKey, _SecretKey);
        require(_false == false);
        PublicType = true;
        SecretKey = _SecretKey;
        EncryptionKey = "";
    }

    function RetrievesIPFSAddress() external view returns (string memory) {
        return (IPFSAddress);
    }

    function RetrievesSecretKey() external view returns (string memory) {
        return (SecretKey);
    }
}

// Part: UserContract

contract UserContract {
    string public UserPublicKey;
    string private RegistrationKey;
    FileContract[] public AllFileSharedMe;

    function addUserMetadata(
        string memory _UserPublicKey,
        string memory _RegistrationKey
    ) public {
        UserPublicKey = _UserPublicKey;
        RegistrationKey = _RegistrationKey;
    }

    function addFileContract(FileContract _FileDeployedAddress) public {
        AllFileSharedMe.push(_FileDeployedAddress);
    }

    function compareStrings(string memory a, string memory b)
        internal
        pure
        returns (bool)
    {
        return (keccak256(abi.encodePacked((a))) ==
            keccak256(abi.encodePacked((b))));
    }

    function validateUser(string memory _ResultRegistrationKey)
        external
        view
        returns (bool)
    {
        bool asRegistrationKey = compareStrings(
            _ResultRegistrationKey,
            RegistrationKey
        );
        return asRegistrationKey;
    }

    function ReturnAllFilesAddress()
        external
        view
        returns (FileContract[] memory)
    {
        return (AllFileSharedMe);
    }
}

// Part: AllUsersMetadata

contract AllUsersMetadata {
    mapping(string => UserContract) public PublicKeyToUserSmartContract;

    function addUserContract(
        string memory _UserPublicKey,
        string memory _RegistrationKey
    ) public returns (UserContract, string memory) {
        UserContract userContract = new UserContract();
        userContract.addUserMetadata(_UserPublicKey, _RegistrationKey);
        PublicKeyToUserSmartContract[_UserPublicKey] = userContract;
        return (userContract, "User File Created!");
    }

    function ValidateUser(
        string memory _PublicKey,
        string memory _ResultRegistrationKey
    ) public view returns (bool) {
        UserContract usercontract = UserContract(
            PublicKeyToUserSmartContract[_PublicKey]
        );
        bool isvalidated = usercontract.validateUser(_ResultRegistrationKey);
        return isvalidated;
    }

    function ReturnAllFiles(UserContract _usercontract)
        public
        view
        returns (FileContract[] memory)
    {
        UserContract a = UserContract(_usercontract);
        FileContract[] memory filecontract;
        filecontract = a.ReturnAllFilesAddress();
        return (filecontract);
    }

    function ThisAddress() public view returns (address) {
        return address(this);
    }

    function AddFileDeployedAddress(
        string memory _UserPublicKey,
        FileContract _FileDeployedAddress
    ) external {
        UserContract userContract = PublicKeyToUserSmartContract[
            _UserPublicKey
        ];
        userContract.addFileContract(_FileDeployedAddress);
    }
}

// File: AllFilesMetadata.sol

contract AllFilesMetadata {
    mapping(string => FileContract) public PublicKeyToDepoyedAddress;
    mapping(string => address) public PublicKeyToOwnerAddress;

    FileContract[] public AllPublicFiles;
    address public addressAllUserMetadata;
    bool StoreUserFactory;

    function setAddressAllUserMetadata(address _addressAllUserMetadata)
        external
    {
        require(StoreUserFactory == false);
        addressAllUserMetadata = _addressAllUserMetadata;
        StoreUserFactory = true;
    }

    function setAddress(
        string memory _OwnerPublicKey,
        FileContract _fileContract
    ) internal {
        AllUsersMetadata UserFactory = AllUsersMetadata(addressAllUserMetadata);
        UserFactory.AddFileDeployedAddress(_OwnerPublicKey, _fileContract);
    }

    function AddUserFile(
        string memory _FileName,
        string memory _IPFSAddress,
        string memory _OwnerPublicKey
    ) public returns (FileContract, string memory) {
        FileContract fileContract = new FileContract();
        fileContract.addFileMetadata(
            _FileName,
            _IPFSAddress,
            _OwnerPublicKey,
            msg.sender
        );
        PublicKeyToDepoyedAddress[_OwnerPublicKey] = fileContract;
        PublicKeyToOwnerAddress[_OwnerPublicKey] = msg.sender;
        setAddress(_OwnerPublicKey, fileContract);
        return (fileContract, "File metadata was created!");
    }

    function publickeyToEncryptionKey(string memory _publickey)
        public
        view
        returns (string memory)
    {
        require(msg.sender == PublicKeyToOwnerAddress[_publickey]);
        FileContract filecontract = PublicKeyToDepoyedAddress[_publickey];
        string memory encryptionKey;
        encryptionKey = filecontract.mapping_to_encryptionkey(_publickey);
        return encryptionKey;
    }

    function RetrieveSecretKey(string memory _publickey)
        public
        view
        returns (string memory)
    {
        require(msg.sender == PublicKeyToOwnerAddress[_publickey]);
        FileContract filecontract = PublicKeyToDepoyedAddress[_publickey];
        string memory SecretKey;
        SecretKey = filecontract.RetrievesSecretKey();
        return SecretKey;
    }

    function RetrieveIPFSAddress(string memory _publickey)
        public
        view
        returns (string memory)
    {
        require(msg.sender == PublicKeyToOwnerAddress[_publickey]);
        FileContract filecontract = PublicKeyToDepoyedAddress[_publickey];
        string memory ipfsAddress;
        ipfsAddress = filecontract.RetrievesIPFSAddress();
        return ipfsAddress;
    }

    function setShareMode(
        string memory _publicKey,
        string memory _EncryptionKey
    ) public returns (string memory) {
        require(PublicKeyToOwnerAddress[_publicKey] == msg.sender);
        FileContract filecontract = PublicKeyToDepoyedAddress[_publicKey];
        filecontract.addEncryptionKey(_EncryptionKey);
        return ("File Share mode was created!");
    }

    function setPublicMode(string memory _publicKey, string memory _SecretKey)
        public
        returns (string memory)
    {
        require(PublicKeyToOwnerAddress[_publicKey] == msg.sender);
        FileContract filecontract = PublicKeyToDepoyedAddress[_publicKey];
        filecontract.addSecretKey(_SecretKey);
        AllPublicFiles.push(filecontract);
        return ("Public File mode was created");
    }

    function ReturnsAllPublicFiles()
        public
        view
        returns (FileContract[] memory)
    {
        return (AllPublicFiles);
    }
}