//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DePassword {
    error IndexOutOfBound(uint256 targetIndex, uint256 maximumIndex);

    struct Credential {
        string name;
        string website;
        string maskedUsername;
        string encryptedUsername;
        string encryptedPassword;
    }
    struct File {
        string name;
        string fileName;
        string fileType;
        string swarmReference;
    }

    mapping(address => Credential[]) private _credentials;
    mapping(address => File[]) private _files;
    mapping(address => string) private _keys;

    function updateKey(string calldata _key) public {
        _keys[msg.sender] = _key;
    }

    function getKey() public view returns (string memory) {
        return _keys[msg.sender];
    }

    function fileCount() public view returns (uint256 count) {
        return _files[msg.sender].length;
    }

    function addFile(File calldata _file) public {
        _files[msg.sender].push(_file);
    }

    function deleteFile(uint256 index) public {
        uint256 maxIndex = fileCount();
        if (index >= maxIndex) {
            revert IndexOutOfBound({
                targetIndex: index,
                maximumIndex: maxIndex
            });
        }

        _files[msg.sender][index] = _files[msg.sender][maxIndex - 1];
        _files[msg.sender].pop();
    }

    function listFiles() public view returns (File[] memory files) {
        uint256 maxIndex = fileCount();
        files = new File[](maxIndex);
        for (uint256 i = 0; i < maxIndex; i++) {
            File storage file = _files[msg.sender][i];

            files[i] = file;
        }
    }

    function credentialCount() public view returns (uint256 count) {
        return _credentials[msg.sender].length;
    }

    function addCredential(Credential calldata _credential) public {
        _credentials[msg.sender].push(_credential);
    }

    function updateCredential(uint256 index, Credential calldata _credential)
        public
    {
        uint256 maxIndex = credentialCount();
        if (index >= maxIndex) {
            revert IndexOutOfBound({
                targetIndex: index,
                maximumIndex: maxIndex
            });
        }

        _credentials[msg.sender][index] = _credential;
    }

    function deleteCredential(uint256 index) public {
        uint256 maxIndex = credentialCount();
        if (index >= maxIndex) {
            revert IndexOutOfBound({
                targetIndex: index,
                maximumIndex: maxIndex
            });
        }

        _credentials[msg.sender][index] = _credentials[msg.sender][
            maxIndex - 1
        ];
        _credentials[msg.sender].pop();
    }

    function listCredentials()
        public
        view
        returns (Credential[] memory credentials)
    {
        uint256 maxIndex = credentialCount();
        credentials = new Credential[](maxIndex);
        for (uint256 i = 0; i < maxIndex; i++) {
            Credential storage credential = _credentials[msg.sender][i];

            credentials[i] = credential;
        }
    }
}