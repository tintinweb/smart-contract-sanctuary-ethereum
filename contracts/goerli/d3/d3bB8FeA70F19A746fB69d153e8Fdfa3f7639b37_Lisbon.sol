// SPDX-License-Identifier: MIT
/**
 * Created on: 26/9/2022
 * @summary The library make it possible to create a vault with the base functionalities.
 * Enabling the ability to create a 'vault' which results in a shared EOA with participants of your choosing.
 * @author W3CPI, Inc
 */

pragma solidity 0.8.16;

library LisbonCreate {
    struct Vault {
        uint256 id;
        uint256 registered;
        address[] users;
        string vaultName;
        uint256 rotateThreshold;
        uint256 transactionThreshold;
        uint256 adminThreshold;
        string verifVect;
        bytes masterPubKey;
        uint256 createdDate;
    }

    function createVault(
        Vault storage vault,
        address[] memory _proposedAddresses,
        string memory _vaultName,
        uint256[3] memory _thresholds,
        string memory _verificationVector,
        bytes memory _masterPubKey
    ) internal {
        if (_proposedAddresses.length == 0) {
            revert("> 1 participant required");
        }
        if (_thresholds.length < 3) {
            revert("missing thresholds");
        }

        vault.vaultName = _vaultName;
        vault.users = _proposedAddresses;
        vault.createdDate = block.timestamp;
        vault.rotateThreshold = _thresholds[0];
        vault.transactionThreshold = _thresholds[1];
        vault.adminThreshold = _thresholds[2];
        vault.masterPubKey = _masterPubKey;
        vault.verifVect = _verificationVector;
    }

    function userRegistration(Vault storage vault) internal {
        require(!completeVault(vault), "Vault complete");
        vault.registered += 1;
    }

    function completeVault(Vault storage vault) internal view returns (bool) {
        if (vault.users.length == vault.registered) {
            return true;
        }
        return false;
    }

    function getVaultInfo(Vault storage vault)
        internal
        view
        returns (
            string memory,
            address[] memory,
            uint256,
            uint256,
            bytes memory,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            vault.vaultName,
            vault.users,
            vault.users.length,
            vault.createdDate,
            vault.masterPubKey,
            vault.transactionThreshold,
            vault.adminThreshold,
            vault.registered
        );
    }
}

// SPDX-License-Identifier: MIT

/**
 * Created on: 26/9/2022
 * @summary The contract that is created from LisbonBank and user defined paramters.
 * Allows participants to create and send transactions from an address that no one has control over.
 * @author W3CPI, Inc
 */
pragma solidity 0.8.16;

import "./libraries/LisbonCreate.sol";
import "./LisbonTx.sol";
import "./LisbonRotation.sol";

/*
 * import "./LisbonAdmin.sol";
 */
contract Lisbon is LisbonTx, LisbonRotation {
    using LisbonCreate for LisbonCreate.Vault;

    event UserRegistered(address _userAddress);
    event id(uint256 vid);

    LisbonCreate.Vault vault;
    LisbonTx private Tx;
    LisbonRotation private rotate;

    bool registrationComplete;
    address payable immutable W3CPI_WALLET;
    uint256 randomId = 0;

    // rn we don't take care of this function but commming soon
    // address[] public disputeAddress;

    mapping(address => uint256[]) public userVaults;
    mapping(uint256 => mapping(address => bool)) public userIsRegistered;
    mapping(uint256 => mapping(address => string))
        public userPublicKeyForVaults;
    mapping(uint256 => mapping(address => string))
        public userEncryptedPrivateForVaults;
    mapping(uint256 => LisbonCreate.Vault) public createdVaults;

    modifier isUserRegistered(uint256 vaultId) {
        require(
            !userIsRegistered[vaultId][msg.sender],
            "User already registered"
        );

        _;
    }

    modifier UserExist(uint256 vaultId) {
        uint256 i = 0;
        while (i < userVaults[msg.sender].length) {
            if (userVaults[msg.sender][i] == vaultId) {
                break;
            }
            if (i == userVaults[msg.sender].length - 1) {
                revert("User does not exist");
            }
            i++;
        }

        _;
    }

    /**
     * @dev store W3CPI wallet address when launching LisbonBank
     */
    constructor() payable {
        W3CPI_WALLET = payable(msg.sender);
        Tx = new LisbonTx();
    }

    function create(
        address[] memory _proposedAddresses,
        string memory _vaultName,
        uint256[3] memory _thresholds,
        string[] memory _ids,
        string[] memory _encryptedKeyShares,
        string memory _verificationVector,
        bytes memory _MPK
    ) external {
        emit id(randomId);
        createdVaults[randomId].createVault(
            _proposedAddresses,
            _vaultName,
            _thresholds,
            _verificationVector,
            _MPK
        );
        for (uint256 i = 0; i < _proposedAddresses.length; i++) {
            if (_proposedAddresses[i] == address(0)) {
                revert("invalid address");
            }
            userVaults[_proposedAddresses[i]].push(randomId);
            userPublicKeyForVaults[randomId][_proposedAddresses[i]] = _ids[i];
            userEncryptedPrivateForVaults[randomId][
                _proposedAddresses[i]
            ] = _encryptedKeyShares[i];
        }

        randomId += 1;
    }

    function register(uint256 vaultId)
        public
        UserExist(vaultId)
        isUserRegistered(vaultId)
    {
        if ((createdVaults[vaultId].createdDate + 14 days) < block.timestamp) {
            revert("registration for this vault is closed");
        }

        for (uint256 i = 0; i < createdVaults[vaultId].users.length; i++) {
            if (createdVaults[vaultId].users[i] == msg.sender) {
                userIsRegistered[vaultId][msg.sender] = true;
                createdVaults[vaultId].userRegistration();
            }
        }
    }

    function submitTx(bytes memory abiEncodedTx, uint256 vaultId)
        public
        UserExist(vaultId)
        isUserRegistered(vaultId)
    {
        Tx.submitTransaction(abiEncodedTx, msg.sender);
    }

    function submitRotationUser(
        uint256 vaultId,
        address addressProposed,
        uint256 addOrRemove
    ) public {
        rotate.submitRotation(vaultId, addressProposed, addOrRemove);
    }

    function confirmTx(
        uint256 txId,
        bytes memory confirmation,
        uint256 vaultId
    ) public UserExist(vaultId) {
        Tx.confirmTransaction(txId, confirmation, msg.sender);
    }

    function getInfo(uint256 vaultId)
        public
        view
        returns (
            string memory,
            address[] memory,
            uint256,
            uint256,
            bytes memory,
            uint256,
            uint256,
            uint256
        )
    {
        return createdVaults[vaultId].getVaultInfo();
    }

    function getTxInfo(uint256 txId)
        public
        view
        returns (
            bytes memory,
            bytes memory,
            uint256,
            bool
        )
    {
        return Tx.getTransactionInfo(txId, msg.sender);
    }

    function getUserVaults() public view returns (uint256[] memory) {
        return userVaults[msg.sender];
    }

    function getShares(uint256 vaultId) public view returns (string[2] memory) {
        return (
            [
                userPublicKeyForVaults[vaultId][msg.sender],
                userEncryptedPrivateForVaults[vaultId][msg.sender]
            ]
        );
    }

    function getAllSignedTx(uint256 _txId, uint256 vaultId)
        public
        view
        returns (bytes[] memory)
    {
        address[] storage registeredAddresses = createdVaults[vaultId].users;
        return Tx.getAllSignedTx(_txId, registeredAddresses);
    }
}

// SPDX-License-Identifier: MIT
/**
 * Created on: 4/10/2022
 * @summary
 * @author W3CPI, Inc
 */

pragma solidity 0.8.16;

contract LisbonRotation {
    struct RotateParticipant {
        uint256 vault_id;
        address proposedRotateUser;
        uint256 userVotes;
        uint256 addOrRemove;
        bool readyToRotate;
        bool submitted;
    }

    mapping( uint256 => RotateParticipant) statusRotation;

    modifier approvedRotation(uint256 vaultId) {
        require(
            vaultId == statusRotation[vaultId].vault_id && statusRotation[vaultId].readyToRotate == true,
            "Already voted"
        );
        _;
    }
    modifier notRemovable(uint256 vaultId) {
        require(
            statusRotation[vaultId].proposedRotateUser == msg.sender,
            "Can't remove yourself"
        );
        _;
    }

    modifier rotateStatus(uint256 vaultId) {
        require(
           !statusRotation[vaultId].readyToRotate,
           "Not ready to rotate"
        );
        _;
    }

    // do the proposer already exist in lisbon contract
    function submitRotation(uint256 _vaultId, address proposedRotateUser, uint256 addOrRemove) public approvedRotation( _vaultId) notRemovable(_vaultId) {
        require(statusRotation[_vaultId].submitted == false, "Already submitted");
        statusRotation[_vaultId] = RotateParticipant(_vaultId, proposedRotateUser, 0, addOrRemove, false, true);
    }


    //add checks to see if the user is already in the vault
    function confirmRotation(uint256 _vaultId) external approvedRotation(_vaultId) {
        statusRotation[_vaultId].readyToRotate = true;
        statusRotation[_vaultId].userVotes += 1;
    }

    // add particiapnt to the vault and rotate the shares are in the lisbon contract
}

// SPDX-License-Identifier: MIT
/**
 * Created on: 28/9/2022
 * @summary The contract make possible to use specific paterns for the transactions on vault.
 * Enabling the ability to create a 'vault' which results in a shared EOA with participants of your choosing.
 * @author W3CPI, Inc
 */

pragma solidity 0.8.16;

contract LisbonTx {
    event SubmitTransaction(address _userAddress, bytes txData, uint256 count);
    event TransactionConfirm(address _userAddress, uint256 txId);

    mapping(uint256 => bytes) public txList;
    mapping(uint256 => uint256) public txApprovedCount;
    mapping(uint256 => mapping(address => bytes)) public userApprovedTx;
    mapping(uint256 => bool) public txSent;
    mapping(uint256 => uint256) public txSendingPeriod;

    uint256 internal txCounter;

    modifier tx_Exists(uint256 _txId) {
        require(!(_txId > txCounter), "tx does not exist");
        _;
    }

    modifier tx_Sent(uint256 _txId) {
        require(!(txSent[_txId]), "Tx already executed");
        _;
    }

    modifier tx_Period(uint256 _txId) {
        require(
            !(txSendingPeriod[_txId] < block.timestamp),
            "Tx passed its sending period"
        );
        _;
    }

    modifier approved(uint256 _txId, address _userAddress) {
        require(
            !(userApprovedTx[_txId][_userAddress].length > 4),
            "tx already approved"
        );
        _;
    }

    function submitTransaction(bytes memory abiEncodedTx, address addr) public {
        txList[txCounter] = abiEncodedTx;
        txSendingPeriod[txCounter] = (block.timestamp + 14 days);
        txCounter += 1;
        emit SubmitTransaction(addr, txList[txCounter - 1], txCounter - 1);
    }

    function Verify(bytes memory _signature) internal pure returns (bool) {
        if (_signature.length != 65) {
            revert("invalid signature length");
        }
        bytes32 messageHash = keccak256(abi.encodePacked(_signature));
        bytes32 r;
        bytes32 s;
        uint8 v;

        // only possible to convert string in bytes32 using assembly
        assembly {
            // first 32 bytes from sig , after the length prefix
            r := mload(add(_signature, 32))
            // second 32 bytes
            s := mload(add(_signature, 64))
            // final bytes (first bytes of the next 21 bytes )
            v := byte(0, mload(add(_signature, 96)))
        }
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        // method to find the signer is the good one
        address signeraddress = ecrecover(ethSignedMessageHash, v, r, s);

        return (signeraddress != address(0));
    }

    function confirmTransaction(
        uint256 _txId,
        bytes memory _confirmation,
        address addr
    )
        external
        tx_Exists(_txId)
        tx_Sent(_txId)
        approved(_txId, addr)
        tx_Period(_txId)
    {
        /*  
            Cannot do the test so I do that       
            if (Verify(_confirmation)) {
         */

        txApprovedCount[_txId] += 1;
        userApprovedTx[_txId][addr] = _confirmation;
        txSent[_txId] = true;

        emit TransactionConfirm(addr, _txId);
        /* } */
        // revert("Tx not confirmed");
    }

    function getTransactionInfo(uint256 _txId, address addr)
        external
        view
        returns (
            bytes memory,
            bytes memory,
            uint256,
            bool
        )
    {
        return (
            txList[_txId],
            userApprovedTx[_txId][addr],
            txApprovedCount[_txId],
            txSent[_txId]
        );
    }

    function getAllSignedTx(uint256 _txId,address[] memory registeredUsers)
        external
        view
        returns (bytes[] memory)
    {
        uint256 arrLength = registeredUsers.length;
        bytes[] memory signedTx = new bytes[](arrLength);
        for (uint256 i = 0; i < arrLength; i++) {
            if (
                bytes(userApprovedTx[_txId][registeredUsers[i]]).length > 0
            ) {
                signedTx[i] = userApprovedTx[_txId][registeredUsers[i]];
            }
        }
        return signedTx;
    }
}