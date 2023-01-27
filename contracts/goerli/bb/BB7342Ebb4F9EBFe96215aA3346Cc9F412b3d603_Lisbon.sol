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
        string encryptionMessage;
        string encryptedShares;
        bytes masterPubKey;
        uint256 createdDate;
    }

    event vault_(
        string name,
        address[] users,
        uint256 transactionThreshold,
        uint256 adminThreshold,
        uint256 rotateThreshold
    );
    event userRegistered(
        uint256 users,
        uint256 registered,
        bool registerComplete
    );

    function createVault(
        Vault storage vault,
        address[] memory _proposedAddresses,
        string memory _vaultName,
        uint256[3] memory _thresholds,
        string memory _encryptionMessage
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
        vault.encryptionMessage = _encryptionMessage;
    }

    function userRegistration(Vault storage vault) internal {
        require(
            vault.users.length != vault.registered,
            "Vault registration complete"
        );
        vault.registered += 1;
        bool registerComplete = false;
        if (vault.users.length == vault.registered) {
            registerComplete = true;
        }
        emit userRegistered(
            vault.users.length,
            vault.registered,
            registerComplete
        );
    }

    function completeVault(Vault storage vault, bytes memory _masterPubKey)
        internal
    {
        if (vault.users.length == vault.registered) {
            if (vault.masterPubKey.length < 4) {
                vault.masterPubKey = _masterPubKey;
            }
        }
    }

    function modifUser(
        Vault storage vault,
        uint256 _choice,
        address _user
    ) internal {
        if (_choice == 1) {
            vault.users.push(_user);
        } else if (_choice == 0) {
            // remove user
            for (uint256 i = 0; i < vault.users.length; i++) {
                if (vault.users[i] == _user) {
                    // swap the last element with the one we want to erase
                    vault.users[i] = vault.users[vault.users.length - 1];
                    vault.users.pop();
                    vault.registered -= 1;
                    break;
                }
                if (i == vault.users.length - 1) {
                    revert("User not found");
                }
            }
        }
    }

    function changeRotationThreshold(Vault storage vault, uint256 _newThreshold)
        internal
    {
        vault.rotateThreshold = _newThreshold;
    }

    function changeTransactionThreshold(
        Vault storage vault,
        uint256 _newThreshold
    ) internal {
        vault.transactionThreshold = _newThreshold;
    }

    function changeAdminThreshold(Vault storage vault, uint256 _newThreshold)
        internal
    {
        vault.adminThreshold = _newThreshold;
    }

    function changeVaultName(Vault storage vault, string memory _newName)
        internal
    {
        vault.vaultName = _newName;
    }

    function getVaultInfo(Vault storage vault)
        internal
        view
        returns (
            string memory,
            address[] memory,
            uint256,
            bytes memory,
            uint256[3] memory,
            uint256,
            string memory
        )
    {
        return (
            vault.vaultName,
            vault.users,
            vault.createdDate,
            vault.masterPubKey,
            [
                vault.transactionThreshold,
                vault.adminThreshold,
                vault.rotateThreshold
            ],
            vault.registered,
            vault.encryptionMessage
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
import "./SafetyVault.sol";
import "./LisbonTx.sol";
import "./LisbonRotation.sol";
import "./LisbonAdmin.sol";

contract Lisbon is SafetyVault, LisbonTx, LisbonRotation, LisbonAdmin {
    using LisbonCreate for LisbonCreate.Vault;

    LisbonCreate.Vault vault;
    LisbonTx private Tx;
    LisbonRotation private Rotation;
    LisbonAdmin private Admin;

    address payable immutable W3CPI_WALLET;
    uint256 randomId = 1;

    mapping(address => uint256[]) public userVaults;
    mapping(uint256 => mapping(address => bool)) public userIsRegistered;
    mapping(uint256 => mapping(address => string))
        public userPublicKeyForEncryption;
    mapping(uint256 => mapping(address => string))
        public userEncryptedShareForVaults;
    mapping(uint256 => LisbonCreate.Vault) public createdVaults;
    mapping(uint256 => uint256[]) public transactionsInVault;

    modifier isUserRegistered(uint256 vaultId) {
        require(userIsRegistered[vaultId][msg.sender], "User not registered");
        _;
    }

    modifier UserExistModifier(uint256 vaultId) {
        uint256 i = 0;
        if (userVaults[msg.sender].length == 0) {
            revert("User does not exist in no vault");
        }
        while (i < userVaults[msg.sender].length) {
            if (userVaults[msg.sender][i] == vaultId) {
                break;
            } else if (i == userVaults[msg.sender].length - 1) {
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
        Rotation = new LisbonRotation();
        Admin = new LisbonAdmin();
    }

    function create(
        address[] memory _proposedAddresses,
        string memory _vaultName,
        uint256[3] memory _thresholds,
        string[] memory _userPublicKeyForEncryption,
        string memory _encryptionMessage
    ) external {
        safeNumber(_thresholds[0]);
        safeNumber(_thresholds[1]);
        safeNumber(_thresholds[2]);

        createdVaults[randomId].createVault(
            _proposedAddresses,
            _vaultName,
            _thresholds,
            _encryptionMessage
        );
        for (uint256 i = 0; i < _proposedAddresses.length; i++) {
            // this needs more verification as well.
            if (_proposedAddresses[i] == address(0)) {
                revert("invalid address");
            }
            //assign vault id to each user
            userVaults[_proposedAddresses[i]].push(randomId);
        }
        //initially we will only have the creator's public key for encryption
        userPublicKeyForEncryption[randomId][
            _proposedAddresses[0]
        ] = _userPublicKeyForEncryption[0];
        //register creator
        if (_proposedAddresses[0] == msg.sender) {
            userIsRegistered[randomId][msg.sender] = true;
            createdVaults[randomId].userRegistration();
        }
        randomId += 1;
    }

    function register(
        uint256 vaultId,
        string memory _userPublicKeyForEncryption
    ) public UserExistModifier(vaultId) {

        if ((createdVaults[vaultId].createdDate + 14 days) < block.timestamp) {
            revert("registration for this vault is closed");
        }

        for (uint256 i = 0; i < createdVaults[vaultId].users.length; i++) {
            if (createdVaults[vaultId].users[i] == msg.sender) {
                userIsRegistered[vaultId][msg.sender] = true;
                userPublicKeyForEncryption[vaultId][
                    msg.sender
                ] = _userPublicKeyForEncryption;
                createdVaults[vaultId].userRegistration();
            }
        }
    }

    function userCompleteVault(
        uint256 vaultId,
        string[] memory encryptedShares,
        bytes memory _masterPubKey
    ) public UserExistModifier(vaultId) {
        address[] memory vaultUserArray = createdVaults[vaultId].users;
        for (uint256 i = 0; i < vaultUserArray.length; i++) {
            userEncryptedShareForVaults[vaultId][
                vaultUserArray[i]
            ] = encryptedShares[i];
        }
        createdVaults[vaultId].completeVault(_masterPubKey);
    }

    // store encrypted shares for users

    function proposeTransaction(bytes memory abiEncodedTx, uint256 vaultId)
        public
        UserExistModifier(vaultId)
    //isUserRegistered(vaultId) //commenting until I fix the  vaultsubmission not registering the proposer
    {
        uint256 thresholdTx = (createdVaults[vaultId].transactionThreshold *
            createdVaults[vaultId].registered) / 100;

        uint256 txs = Tx.submitTransaction(
            abiEncodedTx,
            msg.sender,
            thresholdTx,
            vaultId
        );
        transactionsInVault[vaultId].push(txs);
    }

    // if the transaction is in the vault verify
    // do a loop to check if the transaction is in the vault
    function userConfirmTx(
        uint256 txId,
        bytes memory confirmation,
        uint256 vaultId
    ) public UserExistModifier(vaultId) {
        Tx.userConfirmTransaction(txId, confirmation, msg.sender, vaultId);
    }

    function proposeUserForRotation(
        uint256 vaultId,
        address addressProposed,
        uint256 addOrRemove
    ) public {
        uint256 thresholdRotation = (createdVaults[vaultId].rotateThreshold *
            createdVaults[vaultId].registered) / 100;

        Rotation.submitRotationProposal(
            vaultId,
            addressProposed,
            addOrRemove,
            thresholdRotation,
            msg.sender
        );
    }

    function userVoteForRotation(uint256 vaultId)
        public
        UserExistModifier(vaultId)
    {

        Rotation.userConfirmRotation(vaultId, msg.sender);
    }

    // modify this, we need to get the user address and the approval so we can rotate it
    function doRotation(
        uint256 vaultId,
        string memory _userPublicKeyForEncryption,
        string memory _userEncryptedShare
    ) public UserExistModifier(vaultId) {
        address _participant;
        bool vote;
        uint256 addOrRemove;
        (_participant, vote, addOrRemove) = Rotation
            .getRotationDetailsForRotate(vaultId);

        if (vote == false) {
            revert("Not ready to rotate");
        }
        // add user case
        if (addOrRemove == 1) {
            addUser(
                _userPublicKeyForEncryption,
                _userEncryptedShare,
                _participant,
                vaultId,
                createdVaults[vaultId].users
            );
        }
        // remove user case
        else if (addOrRemove == 2) {
            removeUser(_participant, vaultId, createdVaults[vaultId].users);
        }
        // erase rotation proposal in rotation contract
    }

    function addUser(
        string memory _userPublicKeyForEncryption,
        string memory _userEncryptedShare,
        address _user,
        uint256 _vaultId,
        address[] memory _userAddresses
    ) internal {
        userVaults[_user].push(_vaultId);
        userIsRegistered[_vaultId][_user] = false;
        createdVaults[_vaultId].modifUser(1, _user);
        userPublicKeyForEncryption[_vaultId][
            _user
        ] = _userPublicKeyForEncryption;
        userEncryptedShareForVaults[_vaultId][_user] = _userEncryptedShare;
        Rotation.cleanupRotation(_vaultId, _userAddresses);
    }

    function removeUser(
        address _user,
        uint256 _vaultId,
        address[] memory _userAddresses
    ) internal {
        createdVaults[_vaultId].modifUser(0, _user);
        // we may need to do big changes here
        // create an mapping(address => address) internal owners
        userIsRegistered[_vaultId][_user] = false;
        Rotation.cleanupRotation(_vaultId, _userAddresses);
    }

    // add a modifer to check if the user is from the vault
    // verify is the user is from the vault
    function proposeThresholdChange(
        uint256 vaultId,
        uint256 newThreshold,
        uint256 thresholdType
    ) public UserExistModifier(vaultId) {
        Admin.submitThresholdChangeProposal(
            vaultId,
            newThreshold,
            thresholdType,
            msg.sender,
            (createdVaults[vaultId].adminThreshold *
                createdVaults[vaultId].registered) / 100
        );
    }

    // add a modifer to check if the user is from the vault
    function voteOnThresholdChange(uint256 vaultId) public {
        Admin.userVoteOnThresholdChange(vaultId, msg.sender);
    }

    // add a modifer to check if the user is from the vault
    function voteOnNameChange(uint256 vaultId) public {
        Admin.userVoteOnNameChange(vaultId, msg.sender);
    }

    function performThresholdChange(uint256 vaultId)
        public
        UserExistModifier(vaultId)
    {
        uint256 newThreshold;
        uint256 types;
        bool isThresholdCanChange;
        uint256 numberThresholdVotes;
        string memory newName;
        uint256 numberNameVotes;
        uint256 registeredAddresses = createdVaults[vaultId].registered;

        (
            newThreshold,
            types,
            isThresholdCanChange,
            numberThresholdVotes,
            newName,
            numberNameVotes
        ) = Admin.getThresholdStatusForChange(vaultId);
        if (
            numberThresholdVotes <=
            (createdVaults[vaultId].adminThreshold * registeredAddresses) / 100
        ) {
            revert("votes not received");
        }
        // if the vote is enough, we change the threshold
        if (types == 1) {
            createdVaults[vaultId].changeRotationThreshold(newThreshold);
        } else if (types == 2) {
            createdVaults[vaultId].changeTransactionThreshold(newThreshold);
        } else if (types == 3) {
            createdVaults[vaultId].changeAdminThreshold(newThreshold);
        }
        Admin.cleanupThresholdProposal(vaultId, createdVaults[vaultId].users);
    }

    function proposeNameChange(uint256 vaultId, string memory newName)
        public
        UserExistModifier(vaultId)
    {
        Admin.submitNameChangeProposal(
            vaultId,
            newName,
            (createdVaults[vaultId].adminThreshold *
                createdVaults[vaultId].registered) / 100
        );
    }

    function performNameChange(uint256 vaultId)
        public
        UserExistModifier(vaultId)
    {
        uint256 newThreshold;
        uint256 types;
        bool isThresholdCanChange;
        uint256 numberThresholdVotes;
        string memory newName;
        uint256 newNameVotes;
        uint256 adminth = (createdVaults[vaultId].adminThreshold *
            createdVaults[vaultId].registered) / 100;

        (
            newThreshold,
            types,
            isThresholdCanChange,
            numberThresholdVotes,
            newName,
            newNameVotes
        ) = Admin.getThresholdStatusForChange(vaultId);
        if (newNameVotes < adminth) {
            revert("votes not received");
        }
        createdVaults[vaultId].changeVaultName(newName);
        Admin.cleanupNameProposal(vaultId, createdVaults[vaultId].users);
    }

    function getVaultInfo(uint256 vaultId)
        public
        view
        returns (
            string memory,
            address[] memory,
            uint256,
            bytes memory,
            uint256[3] memory,
            uint256,
            string memory
        )
    {
        return createdVaults[vaultId].getVaultInfo();
    }

    function getTransactionInfo(uint256 txId)
        public
        view
        returns (
            bytes memory,
            bytes memory,
            uint256,
            bool
        )
    {
        return Tx.getTransactionDetails(txId, msg.sender);
    }

    function getUserVaults() public view returns (uint256[] memory) {
        return userVaults[msg.sender];
    }

    function getVaultTransactions(uint256 _vaultId)
        public
        view
        returns (uint256[] memory)
    {
        return transactionsInVault[_vaultId];
    }

    //this might not be needed, I currently just make individual calls to each of those values in the return.
    //function getShares(uint256 vaultId) public view returns (string[2] memory) {
    //    return (
    //        [
    //            userPublicKeyForEncryption[vaultId][msg.sender],
    //            userEncryptedShareForVaults[vaultId][msg.sender]
    //        ]
    //    );
    //}


    function getAllSignedShares(uint256 _txId, uint256 vaultId)
        public
        view
        returns (bytes[] memory)
    {
        address[] storage registeredAddresses = createdVaults[vaultId].users;
        return Tx.gatherSignedShares(_txId, registeredAddresses);
    }

    function getRotationInfo(uint256 _vaultId)
        public
        view
        returns (
            address,
            bool,
            uint256,
            bool,
            uint256
        )
    {
        return Rotation.getRotationDetails(_vaultId, msg.sender);
    }

    function getVaultChangeProposalInfo(uint256 _vaultId)
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            bool[2] memory,
            bool[2] memory,
            uint256[2] memory
        )
    {
        return Admin.getThresholdStatusForVault(_vaultId);
    }
}

// SPDX-License-Identifier: MIT
/**
 * Created on: 5/10/2022
 * @summary
 * @author W3CPI, Inc
 */

pragma solidity 0.8.16;

import "./SafetyVault.sol";

contract LisbonAdmin is SafetyVault {
    event ThresholdVote(
        uint256 vaultID,
        string _type,
        address thresholdUser,
        uint256 thProposed
    );
    event thCanChange(uint256 vaultId, bool isThresholdCanChange);

    event look(uint256 i, bytes32 b, string str);
    struct Administration {
        string newName;
        uint256 newThreshold;
        uint256 thresholdType;
        bool isThresholdCanChange;
        bool isNameCanChange;
        uint256 AdminThreshold;
        uint256 thresholdVotes;
        uint256 nameVotes;
    }

    mapping(address => mapping(uint256 => bool)) nameVoter;
    mapping(address => mapping(uint256 => bool)) thresholdVoter;
    mapping(uint256 => Administration) public admin;

    modifier alreadyVotedThreshold(uint256 _vaultId, address _voterAddress) {
        require(
            thresholdVoter[_voterAddress][_vaultId] == false,
            "You've already voted"
        );
        _;
    }

    modifier alreadyVotedName(uint256 _vaultId, address _voterAddress) {
        require(
            nameVoter[_voterAddress][_vaultId] == false,
            "You've already voted"
        );
        _;
    }

    modifier VoteThresholdComplete(uint256 _vaultId) {
        require(!admin[_vaultId].isThresholdCanChange, "Vote complete");
        _;
    }

    modifier VoteNameComplete(uint256 _vaultId) {
        require(!admin[_vaultId].isNameCanChange, "Vote complete");
        _;
    }

    // Submit request to change transaction threshold
    // verify is the user is from the vault
    function submitThresholdChangeProposal(
        uint256 _vaultId,
        uint256 _NewThreshold,
        uint256 _thTypes,
        address _addressproposer,
        uint256 _VaultCurrentThreshold
    ) public {
        emit look(
            admin[_vaultId].thresholdVotes,
            keccak256(abi.encodePacked(admin[_vaultId].newName)),
            admin[_vaultId].newName
        );
        require(
            admin[_vaultId].thresholdVotes == 0,
            "Threshold already proposed"
        );
        //not sure we want to say for sure you vote for the threshold you submit
        //thresholdVoter[_addressproposer][_vaultId] = true;
        admin[_vaultId].newThreshold = _NewThreshold;
        admin[_vaultId].thresholdType = _thTypes;
        admin[_vaultId].AdminThreshold = _VaultCurrentThreshold;

        if (_thTypes == 1) {
            emit ThresholdVote(
                _vaultId,
                "rotation",
                _addressproposer,
                _NewThreshold
            );
        } else if (_thTypes == 2) {
            emit ThresholdVote(_vaultId, "tx", _addressproposer, _NewThreshold);
        } else if (_thTypes == 3) {
            emit ThresholdVote(
                _vaultId,
                "admin",
                _addressproposer,
                _NewThreshold
            );
        }
    }

    function submitNameChangeProposal(
        uint256 _vaultId,
        string memory _name,
        uint256 _adminTH
    ) public {
        require(
            (keccak256(abi.encodePacked(admin[_vaultId].newName))) ==
                (keccak256(abi.encodePacked(""))),
            "name already proposed"
        );
        admin[_vaultId].AdminThreshold = _adminTH;
        admin[_vaultId].newName = _name;
    }

    // submit vote from users from the vault
    function userVoteOnThresholdChange(uint256 _vaultId, address _addressVoter)
        public
        alreadyVotedThreshold(_vaultId, _addressVoter)
        VoteThresholdComplete(_vaultId)
    {
        admin[_vaultId].thresholdVotes += 1;
        thresholdVoter[_addressVoter][_vaultId] == true;
        if (admin[_vaultId].thresholdVotes >= admin[_vaultId].AdminThreshold) {
            admin[_vaultId].isThresholdCanChange = true;
            emit thCanChange(_vaultId, admin[_vaultId].isThresholdCanChange);
        }
        if (admin[_vaultId].thresholdType == 1) {
            emit ThresholdVote(
                _vaultId,
                "rotation",
                _addressVoter,
                admin[_vaultId].newThreshold
            );
        } else if (admin[_vaultId].thresholdType == 2) {
            emit ThresholdVote(
                _vaultId,
                "tx",
                _addressVoter,
                admin[_vaultId].newThreshold
            );
        } else if (admin[_vaultId].thresholdType == 3) {
            emit ThresholdVote(
                _vaultId,
                "admin",
                _addressVoter,
                admin[_vaultId].newThreshold
            );
        }
    }

    function userVoteOnNameChange(uint256 _vaultId, address _addressVoter)
        public
        alreadyVotedName(_vaultId, _addressVoter)
        VoteNameComplete(_vaultId)
    {
        nameVoter[_addressVoter][_vaultId] == true;
        admin[_vaultId].nameVotes += 1;
        if (admin[_vaultId].nameVotes >= admin[_vaultId].AdminThreshold) {
            admin[_vaultId].isNameCanChange = true;
        }
        emit thCanChange(_vaultId, admin[_vaultId].isNameCanChange);
    }

    function getThresholdStatusForChange(uint256 _vaultId)
        public
        view
        returns (
            uint256,
            uint256,
            bool,
            uint256,
            string memory,
            uint256
        )
    {
        return (
            admin[_vaultId].newThreshold,
            admin[_vaultId].thresholdType,
            admin[_vaultId].isThresholdCanChange,
            admin[_vaultId].thresholdVotes,
            admin[_vaultId].newName,
            admin[_vaultId].nameVotes
        );
    }

    function getThresholdStatusForVault(uint256 _vaultId)
        public
        view
        returns (
            string memory,
            uint256,
            uint256,
            bool[2] memory,
            bool[2] memory,
            uint256[2] memory
        )
    {
        return (
            admin[_vaultId].newName,
            admin[_vaultId].newThreshold,
            admin[_vaultId].thresholdType,
            [
                admin[_vaultId].isThresholdCanChange,
                admin[_vaultId].isNameCanChange
            ],
            [
                thresholdVoter[msg.sender][_vaultId],
                nameVoter[msg.sender][_vaultId]
            ],
            [admin[_vaultId].thresholdVotes, admin[_vaultId].nameVotes]
        );
    }

    function cleanupNameProposal(
        uint256 _vaultId,
        address[] memory _userAddresses
    ) public {
        admin[_vaultId].newName = "";
        admin[_vaultId].nameVotes = 0;
        admin[_vaultId].isNameCanChange = false;
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            nameVoter[_userAddresses[i]][_vaultId] = false;
        }
    }

    function cleanupThresholdProposal(
        uint256 _vaultId,
        address[] memory _userAddresses
    ) public {
        admin[_vaultId].thresholdVotes = 0;
        admin[_vaultId].isThresholdCanChange = false;
        admin[_vaultId].newThreshold = 0;
        admin[_vaultId].thresholdType = 0;
        for (uint256 i = 0; i < _userAddresses.length; i++) {
            thresholdVoter[_userAddresses[i]][_vaultId] = false;
        }
    }
}

// SPDX-License-Identifier: MIT
/**
 * Created on: 4/10/2022
 * @summary
 * @author W3CPI, Inc
 */

pragma solidity 0.8.16;

// add rotate threshold instead of participant
contract LisbonRotation {
    struct RotateParticipant {
        uint256 vault_id;
        address proposedRotateUser;
        uint256 userVotes;
        uint256 addOrRemove;
        uint256 rotationThreshold;
        bool readyToRotate;
    }

    mapping(uint256 => RotateParticipant) statusRotation;
    mapping(address => mapping(uint256 => bool)) voter;

    event RotateUser(
        uint256 vault_id,
        address proposedRotateUser,
        uint256 userVotes,
        uint256 addOrRemove,
        bool readyToRotate,
        uint256 rotationThreshold
    );
    event ParticipantRotationVote(
        address _userAddress,
        uint256 _vote,
        uint256 _rotationThreshold
    );
    event ParticipantRotationComplete(
        bool readyToRotate,
        uint256 _vote,
        address _rotationThreshold
    );
    event idv(uint256 vid);
    event dataBeforeRotation(
        uint256 idVault,
        address userProposedToRotate,
        bool canBeRotate
    );
    event dataAfterRotation(
        uint256 idVault,
        address userProposedToRotate,
        bool canBeRotate
    );
    event ThreshldRotationReached(uint256 threshold);

    modifier notAddRemovable(address _userAddress, address _proposer) {
        require(_proposer != _userAddress, "Can't rotate yourself");
        _;
    }

    //think about how to verify that the user don't vote twice
    modifier rotateTwice(uint256 vaultId, address _voterAddress) {
        require(voter[_voterAddress][vaultId] == false, "You've already voted");
        _;
    }

    // do the proposer already exist in lisbon contract
    function submitRotationProposal(
        uint256 _vaultId,
        address _proposedRotateUser,
        uint256 _addOrRemove,
        uint256 _rotationThreshold,
        address proposer
    ) public notAddRemovable(_proposedRotateUser, proposer) {
        require(
            statusRotation[_vaultId].userVotes == 0,
            "rotation not finished"
        );

        statusRotation[_vaultId] = RotateParticipant(
            _vaultId,
            _proposedRotateUser,
            0,
            _addOrRemove,
            _rotationThreshold,
            false
        );

        emit RotateUser(
            _vaultId,
            _proposedRotateUser,
            1,
            _addOrRemove,
            false,
            _rotationThreshold
        );
    }

    //add checks to see if the user is already in the vault
    function userConfirmRotation(uint256 _vaultId, address _voter)
        public
        rotateTwice(_vaultId, _voter)
    {
        statusRotation[_vaultId].userVotes += 1;
        voter[_voter][_vaultId] = true;
        emit ParticipantRotationVote(
            _voter,
            statusRotation[_vaultId].userVotes,
            statusRotation[_vaultId].rotationThreshold
        );
        if (
            statusRotation[_vaultId].userVotes >=
            statusRotation[_vaultId].rotationThreshold
        ) {
            emit ThreshldRotationReached(
                statusRotation[_vaultId].rotationThreshold
            );
            statusRotation[_vaultId].readyToRotate = true;
            emit ParticipantRotationComplete(
                statusRotation[_vaultId].readyToRotate,
                statusRotation[_vaultId].addOrRemove,
                statusRotation[_vaultId].proposedRotateUser
            );
        }
    }

    // get the address of the participant to be rotated, if he can rotate and see if you need to add or remove user
    function getRotationDetailsForRotate(uint256 _vaultId)
        public
        returns (
            address,
            bool,
            uint256
        )
    {
        emit dataBeforeRotation(
            _vaultId,
            statusRotation[_vaultId].proposedRotateUser,
            statusRotation[_vaultId].readyToRotate
        );

        address _proposedRotateUser = statusRotation[_vaultId]
            .proposedRotateUser;
        bool _readyToRotate = statusRotation[_vaultId].readyToRotate;
        uint256 _addOrRemove = statusRotation[_vaultId].addOrRemove;

        emit dataAfterRotation(
            _vaultId,
            statusRotation[_vaultId].proposedRotateUser,
            statusRotation[_vaultId].readyToRotate
        );

        return (_proposedRotateUser, _readyToRotate, _addOrRemove);
    }

    function getRotationDetails(uint256 _vaultId, address _voterAddress)
        external
        view
        returns (
            address,
            bool,
            uint256,
            bool,
            uint256
        )
    {
        address proposedRotateUser = statusRotation[_vaultId]
            .proposedRotateUser;
        bool readyToRotate = statusRotation[_vaultId].readyToRotate;
        uint256 addOrRemove = statusRotation[_vaultId].addOrRemove;
        bool userVote = voter[_voterAddress][_vaultId];
        uint256 totalVotes = statusRotation[_vaultId].userVotes;
        return (
            proposedRotateUser,
            readyToRotate,
            addOrRemove,
            userVote,
            totalVotes
        );
    }

    function cleanupRotation(uint256 _vaultId, address[] memory _userAddresses)
        public
    {
        statusRotation[_vaultId] = RotateParticipant(
            _vaultId,
            address(0),
            0,
            0,
            0,
            false
        );

        for (uint256 i = 0; i < _userAddresses.length; i++) {
            voter[_userAddresses[i]][_vaultId] = false;
        }
    }
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
    event TransactionSent(uint256 txId);
    event ThreshldTxReached(uint256 txId, uint256 threshold);
    // test
    event info(uint256 countapprouve);

    mapping(uint256 => bytes) public txList;
    mapping(uint256 => uint256) public txApprovedCount;
    mapping(uint256 => mapping(address => bytes)) public userApprovedTx;
    mapping(uint256 => bool) public txSent;
    mapping(uint256 => uint256) public txSendingPeriod;
    mapping(uint256 => uint256) public thresholdTxPerVault;

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

    function submitTransaction(
        bytes memory abiEncodedTx,
        address addr,
        uint256 _thresholdTxPerVault,
        uint256 _vaultID
    ) public returns (uint256) {
        txList[txCounter] = abiEncodedTx;
        txSendingPeriod[txCounter] = (block.timestamp + 14 days);
        txCounter += 1;
        thresholdTxPerVault[_vaultID] = _thresholdTxPerVault;

        emit SubmitTransaction(addr, txList[txCounter - 1], txCounter - 1);
        return txCounter - 1;
    }

    // not relevant bc we already verify the belonging to the vault from every users
    function VerifySignedTransaction(bytes memory _signature)
        internal
        pure
        returns (bool)
    {
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
        //This will be removed as we are focused on non-messages right now
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        address signeraddress = ecrecover(ethSignedMessageHash, v, r, s);

        return (signeraddress != address(0));
    }

    function userConfirmTransaction(
        uint256 _txId,
        bytes memory _confirmation,
        address addr,
        uint256 _vaultID
    )
        external
        tx_Exists(_txId)
        tx_Sent(_txId)
        approved(_txId, addr)
        tx_Period(_txId)
    {
        /*  
            Cannot do the test so I do that       
            if (VerifySignedTransaction(_confirmation)) {
         */

        txApprovedCount[_txId] += 1;
        userApprovedTx[_txId][addr] = _confirmation;
        if (txApprovedCount[_txId] >= thresholdTxPerVault[_txId]) {
            emit ThreshldTxReached(_txId, thresholdTxPerVault[_vaultID]);
            //this marks it sent before its sent currently.
            //txReadyToBeSent(
            //    _txId /*,  _confirmation */
            //);
        }
        emit TransactionConfirm(addr, _txId);
    }

    function getTransactionDetails(uint256 _txId, address addr)
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

    function gatherSignedShares(uint256 _txId, address[] memory registeredUsers)
        external
        view
        returns (bytes[] memory)
    {
        uint256 arrLength = registeredUsers.length;
        bytes[] memory signedTx = new bytes[](arrLength);
        for (uint256 i = 0; i < arrLength; i++) {
            if (bytes(userApprovedTx[_txId][registeredUsers[i]]).length > 0) {
                signedTx[i] = userApprovedTx[_txId][registeredUsers[i]];
            }
        }
        return signedTx;
    }

    function txReadyToBeSent(
        uint256 _txId /* ,
        bytes memory _receipt */
    ) public tx_Exists(_txId) tx_Sent(_txId) {
        /* if (VerifySignedTransaction(_receipt)) { */
        // goal being we just want to make sure that the tx data has in fact been sent.
        //I guess comparing a tx receipt hash to the data in _txID to make sure it looks good?
        txSent[_txId] = true;
        emit TransactionSent(_txId);
        /*  }
        revert(
            "Tx was not marked sent. Submitted hash didn't align with TX data"
        ); */
    }
}

// SPDX-License-Identifier: MIT

/**
 * Created on: 01/12/2022
 * @summary The contract that is created for consolidate security on every contract that is on lisbon.
 * @author W3CPI, Inc
 */
pragma solidity 0.8.16;

contract SafetyVault {
    function safeNumber(uint256 _number) public pure {
        require(_number >= 0 && _number < 100, "number invalid");
    }
}