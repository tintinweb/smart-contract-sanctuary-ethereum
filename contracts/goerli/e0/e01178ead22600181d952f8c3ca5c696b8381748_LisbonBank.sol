// SPDX-License-Identifier: MIT
/**
 * Created on: 6/1/2022
 * @summary The contract that faciliates the usage of the Lisbon Protocol.
 * Enabling the ability to create a 'vault' which results in a shared EOA with participants of your choosing.
 * @author W3CPI, Inc
 */
pragma solidity 0.8.17;
import "./LisbonVault.sol";

/**
 * @title LisbonBank
 */
contract LisbonBank {
    mapping(address => address[]) UserVaults;
    address payable immutable W3CPI_WALLET;

    /**
     * @dev Get all vaults tied to a user
     * @return Array of vaults that are tied to the requestor.
     */
    function getUserVaults() external view returns (address[] memory) {
        return UserVaults[msg.sender];
    }

    /**
     * @dev store W3CPI wallet address when launching LisbonBank
     */
    constructor() payable {
        W3CPI_WALLET = payable(msg.sender);
    }

    /* ============ Setters ============ */

    /**
     * @dev Accepts parameters and launches a new instance of a LisbonVault. LisbonVault is the smart contract for a group of participants who want to engage in a new vault.
     * @param _proposedAddresses Array of addresses being submitted for a new vault
     * @param _vaultName String of the name of the vault - primarily for readability later
     * @param _thresholds Array of percentage thresholds to perform an action,[ launch, rotate, transaction ]  (launch = finalize vault, rotate = remove or add new participant, transaction = perform TX)
     * @param _ids Array of the ids (external keys) of each participant. These keys are the individial, newly created, group external keys for this specific vault. These determine the group master external key.
     * @param _encryptedKeyShares Array of the private keys of each participant. These keys are the individial, newly created, group private keys for this specific vault.  These determine the group master private key.
     * @param _MPK The long form external key for this account
     * @param _MAddress Short form address of the master external key. The ethereum address.
     * @return v Address of the newly created LisbonVault
     */
    function createVault(
        address[] memory _proposedAddresses,
        string memory _vaultName,
        uint256[] memory _thresholds,
        string[] memory _ids,
        string[] memory _encryptedKeyShares,
        string memory _verificationVector,
        bytes memory _MPK,
        address _MAddress
    ) external returns (address) {
        LisbonVault v = new LisbonVault(
            _proposedAddresses,
            _vaultName,
            _thresholds,
            _ids,
            _encryptedKeyShares,
            _verificationVector,
            _MPK,
            _MAddress
        );
        for (uint256 i = 0; i < _proposedAddresses.length; i++) {
            UserVaults[_proposedAddresses[i]].push(address(v));
        }
        return address(v);
    }
}

// SPDX-License-Identifier: MIT

/**
 * Created on: 6/1/2022
 * @summary The contract that is created from LisbonBank and user defined paramters.
 * Allows participants to create and send transactions from an address that no one has control over.
 * @author W3CPI, Inc
 */
pragma solidity 0.8.17;

/**
 * @title LisbonVault
 */
contract LisbonVault {
    event submitDisputeEvent(address _userAddress);
    event CreationComplete(address contractAddress);
    event UserRegistered(address _userAddress);
    event ParticipantRotationVote(address _userAddress);
    event ThresholdVote(address _userAddress, string _type);
    event TransactionConfirm(address _userAddress, uint256 indexed txIndex);
    event TransactionSent(uint256 indexed txIndex);
    event ThresholdChangeComplete(address contractAddress, string _type);
    event ParticipantRotationComplete(
        address contractAddress,
        address _newParticipant
    );
    event SendTransactionComplete(address contractAddress, bytes txData);
    event SubmitTransaction(address _userAddress, bytes txData);
    event SubmitRotateParticipant(
        address _userAddress,
        address _newParticipant
    );
    event SubmitThresholdChange(address contractAddress, string _type);

    //TX stuff
    mapping(uint256 => bytes) public txList;
    mapping(uint256 => uint256) public txApprovedCount;
    mapping(uint256 => mapping(address => bytes)) public userApprovedTx;
    mapping(uint256 => bool) public txSent;
    mapping(uint256 => uint256) public txSendingPeriod;
    uint256 txCounter;
    //end TX Stuff

    struct RotateParticipantStruct {
        address proposedRotateUserAddress;
        uint256 userVotes;
        uint256 addOrRemove;
        bool readyToRotate;
        uint256 submitted;
    }
    RotateParticipantStruct rotateParticipantStatus;

    mapping(address => string) public id_share;
    mapping(address => string) public encrypted_share;
    mapping(address => bool) public userConfirmRegistration;
    mapping(address => bool) public approvedRotation;
    mapping(address => bool) public approvedRotationThresholdChange;
    mapping(address => bool) public approvedTransactionThresholdChange;
    mapping(address => bool) public approvedAdminThresholdChange;
    mapping(address => bool) private userExists; // I like this as an extra check, relying on id_share might not work because those keys can be different even for the same address.

    address payable public immutable masterAddress;

    address[] public proposedAddresses;
    address[] public registeredAddresses;
    address[] public disputeAddresses;
    string public vaultName; // might make this modifiable in the future
    bytes masterPublicKey;
    string verificationVector; // might change when we do participant rotation, otherwise make it immutable
    bool registrationComplete;
    uint256 public rotateThreshold;
    uint256 public transactionThreshold;
    uint256 public adminThreshold;
    uint256 immutable createdDate;
    uint256 public rotationThresholdVotes;
    uint256 public adminThresholdVotes;
    uint256 public transactionThresholdVotes;
    uint256 public proposedTransactionPercentage;
    uint256 public proposedRotationPercentage;
    uint256 public proposedAdminPercentage;

    modifier isUserRegistered() {
        if (!userConfirmRegistration[msg.sender]) {
            revert("User hasn't registered yet");
        }
        _;
    }

    modifier isRegistrationComplete() {
        if (!registrationComplete) {
            revert("Registration is not complete yet");
        }
        _;
    }

    modifier txExists(uint256 _txId) {
        if (_txId > txCounter) {
            revert("tx does not exist");
        }
        _;
    }

    /**
     * @dev Accepts parameters and launches a new instance of a LisbonVault. LisbonVault is the smart contract for a group of participants who want to engage in a new vault.
     * @param _proposedAddresses Array of addresses being submitted for a new vault
     * @param _vaultName String of the name of the vault - primarily for readability later
     * @param _thresholds Array of percentage thresholds to perform an action,[ rotate, transaction, administrative ]  (rotate = remove or add new participant, transaction = perform TX, admin = change thresholds, etc))
     * @param _ids Array of the ids (public keys) of each participant. These keys are the individial, newly created, group public keys for this specific vault. These determine the group master public key.
     * @param _encryptedKeyShares Array of the private keys of each participant. These keys are the individial, newly created, group private keys for this specific vault.  These determine the group master private key.
     * @param _verificationVector The public keys for verifying the participants in the multisig key
     * @param _MPK The long form public key for this account
     * @param _MAddress Short form address of the master public key. The ethereum address.
     */
    constructor(
        address[] memory _proposedAddresses,
        string memory _vaultName,
        uint256[] memory _thresholds,
        string[] memory _ids,
        string[] memory _encryptedKeyShares,
        string memory _verificationVector,
        bytes memory _MPK,
        address _MAddress
    ) {
        uint256 proposedAddressesLength = _proposedAddresses.length;
        if (proposedAddressesLength == 0) {
            revert("> 1 participant required");
        }
        if (_thresholds.length < 3) {
            revert("missing thresholds");
        }

        for (uint256 i = 0; i < proposedAddressesLength; i++) {
            if (_proposedAddresses[i] == address(0)) {
                revert("invalid address");
            }
            if (userExists[_proposedAddresses[i]]) {
                revert("A proposed address is a dupe");
            }
            id_share[_proposedAddresses[i]] = _ids[i];
            encrypted_share[_proposedAddresses[i]] = _encryptedKeyShares[i];
            userExists[_proposedAddresses[i]] = true;
        }

        if (address(uint160(uint256(keccak256(_MPK)))) != _MAddress) {
            revert("Keys don't match");
        }

        vaultName = _vaultName;
        proposedAddresses = _proposedAddresses;
        rotateThreshold = _thresholds[0];
        transactionThreshold = _thresholds[1];
        adminThreshold = _thresholds[2];
        masterPublicKey = _MPK;
        masterAddress = payable(_MAddress);
        createdDate = block.timestamp;
        verificationVector = _verificationVector;

        // If a person is creating a vault for one person (themselves) automatically register,
        if (proposedAddresses[0] == tx.origin) {
            registeredAddresses.push(tx.origin);
            userConfirmRegistration[tx.origin] = true;
            if (_proposedAddresses.length == 1) {
                registrationComplete = true;
            }
        }

        emit CreationComplete(address(this));
    }

    /////*****  *******  *****/////
    /////*****  Setters  *****/////
    /////*****  *******  *****/////

    /**
     * @dev Function called when a user confirmed the vault data and registers their account with the vault
     */
    function doRegisterUser() external {
        if (!userExists[msg.sender]) {
            revert("This user is not a part of the vault");
        }
        if (userConfirmRegistration[msg.sender]) {
            revert("Already registered in Vault");
        }
        if ((createdDate + 14 days) < block.timestamp) {
            revert("registration for this vault is closed");
        }
        registeredAddresses.push(msg.sender);
        userConfirmRegistration[msg.sender] = true;

        // this if fails to account for someone who fails to register,
        //need another function that marks this 'registration complete' if (createdDate + 14 days) < block.timestamp
        if (registeredAddresses.length == proposedAddresses.length) {
            registrationComplete = true;
        }
        emit UserRegistered(msg.sender);
    }

    /**
     * @dev Submit the transaction details for others to confirm and send
     * @param abiEncodedTx Encoded transaction data -- replacing a struct of all that info
     */
    function doSubmitTransactionDetails(bytes memory abiEncodedTx)
        public
        isUserRegistered
        isRegistrationComplete
    {
        txList[txCounter] = abiEncodedTx;
        txSendingPeriod[txCounter] = (block.timestamp + 14 days);
        txCounter += 1;
        emit SubmitTransaction(msg.sender, abiEncodedTx);
    }

    error Blah(address theAddress);

    function Verify(bytes memory _signature) public pure returns (bool) {
        // build revert if signature length is wrong
        bytes32 messageHash = keccak256(abi.encodePacked(_signature));
        bytes32 r;
        bytes32 s;
        uint8 v;

        // only possible to convert string in bytes32 using assembly
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
        bytes32 ethSignedMessageHash = keccak256(
            abi.encodePacked("\x19Ethereum Signed Message:\n32", messageHash)
        );
        address signeraddress = ecrecover(ethSignedMessageHash, v, r, s);
        //this isn't complete yet, I believe we need to start storing the address from each of the public keys generated
        //get public address of this from public key
        //id_share[msg.sender]
        return (signeraddress != address(0));
    }

    /**
     * @dev approve the transaction forwarded by a vault participant to the vault
     * @param _txId the Id of the transaction forwarded
     * @param _confirmation the 'part' of a users tx confirmation used to re-construct the transaction
     */
    function doUserConfirmTransaction(uint256 _txId, bytes memory _confirmation)
        external
        isUserRegistered
        txExists(_txId)
    {
        if (txSent[_txId]) {
            revert("Tx already executed");
        }
        if (txSendingPeriod[_txId] < block.timestamp) {
            revert("Tx passed its sending period");
        }
        if (userApprovedTx[_txId][msg.sender].length > 4) {
            revert("tx already approved");
        }

        if (Verify(_confirmation)) {
            txApprovedCount[_txId] += 1;
            userApprovedTx[_txId][msg.sender] = _confirmation;
            emit TransactionConfirm(msg.sender, _txId);
        }
    }

    /**
     * @dev When transaction has been sent, fire this tx to mark the transaction as sent
     */
    //function confirmTransactionSent(uint256 _txId) public isUserRegistered {
    //    txSent[_txId] = true;
    //    emit TransactionSent(_txId);
    //}

    /**
     * @dev Submit participant for adding or removal to the smart contract
     * @param _proposedRotateUserAddress the address of Vault users
     * @param _addOrRemove String add or remove
     */
    function submitParticipantRotationRequest(
        address _proposedRotateUserAddress,
        uint256 _addOrRemove
    ) external isUserRegistered isRegistrationComplete {
        if (rotateParticipantStatus.proposedRotateUserAddress != address(0)) {
            revert("User already proposed - please vote!");
        }
        if (_addOrRemove == 2 && registeredAddresses.length == 1) {
            revert("Can't remove yourself");
        }
        if (userExists[_proposedRotateUserAddress]) {
            revert("Already registered");
        }
        if (approvedRotation[msg.sender]) {
            revert("Already voted");
        }
        for (uint256 i = 0; i < registeredAddresses.length; i++) {
            if (_proposedRotateUserAddress == registeredAddresses[i]) {
                revert("Proposed user already exists");
            }
        }
        rotateParticipantStatus
            .proposedRotateUserAddress = _proposedRotateUserAddress;
        rotateParticipantStatus.addOrRemove = _addOrRemove;
        rotateParticipantStatus.userVotes += 1;
        approvedRotation[msg.sender] = true;
        rotateParticipantStatus.submitted = 1;
        emit SubmitRotateParticipant(msg.sender, _proposedRotateUserAddress);
    }

    /**
     * @dev Confirm participant for adding or removal to the smart contract
     */
    function confirmParticipantRotationRequest() external isUserRegistered {
        if (approvedRotation[msg.sender] == true) {
            revert("User already voted");
        }
        approvedRotation[msg.sender] = true;
        rotateParticipantStatus.userVotes += 1;
        if (
            rotateParticipantStatus.userVotes >=
            (rotateThreshold * registeredAddresses.length) / 100
        ) {
            rotateParticipantStatus.readyToRotate = true;
        }
        emit ParticipantRotationVote(msg.sender);
    }

    /**
     * @dev Add the proposed participant to the list of registered recipients, rotate keys if needed
     * @param _proposedAddresses Array of the proposed participants
     * @param _ids Array of the ids (public keys) of each participant. These keys are the individial, newly created, group public keys for this specific vault. These determine the group master public key.
     * @param _privatekeys Array of the private keys of each participant. These keys are the individial, newly created, group private keys for this specific vault.  These determine the group master private key.
     */
    function addProposedParticipantAndRotateShares(
        address[] memory _proposedAddresses,
        string[] memory _ids,
        string[] memory _privatekeys
    ) public isUserRegistered {
        if (!rotateParticipantStatus.readyToRotate) {
            revert("Not ready to rotate");
        }
        if (
            rotateParticipantStatus.userVotes >=
            (rotateThreshold * registeredAddresses.length) / 100
        ) {
            revert("Threshold of votes not yet met");
        }
        if (proposedAddresses.length < 1) {
            revert("At least one participant required");
        }
        uint256 proposedAddressesLength = _proposedAddresses.length;
        //uint8 confirmed;
        for (uint256 i = 0; i < proposedAddressesLength; i++) {
            if (_proposedAddresses[i] == address(0)) {
                revert("invalid participant address");
            }
            if (userExists[_proposedAddresses[i]]) {
                revert("Duplicate address proposed");
            }
            if (
                rotateParticipantStatus.proposedRotateUserAddress ==
                _proposedAddresses[i]
            ) {
                userConfirmRegistration[_proposedAddresses[i]] = true;
            }
            id_share[_proposedAddresses[i]] = _ids[i];
            encrypted_share[_proposedAddresses[i]] = _privatekeys[i];
            userExists[_proposedAddresses[i]] = true;
            approvedRotation[_proposedAddresses[i]] = false;
        }
        emit ParticipantRotationComplete(
            address(this),
            rotateParticipantStatus.proposedRotateUserAddress
        );
        rotateParticipantStatus
            .proposedRotateUserAddress = 0x0000000000000000000000000000000000000000;
        rotateParticipantStatus.addOrRemove = 0;
        rotateParticipantStatus.userVotes = 0;
        rotateParticipantStatus.submitted = 0;
    }

    /**
     * @dev Submit request to change transaction threshold
     * @param _threshold Proposed Transaction Threshold #
     */
    function submitTransactionThresholdChange(uint256 _threshold)
        public
        isUserRegistered
    {
        if (proposedTransactionPercentage != 0) {
            revert("Transaction threshold proposed already");
        }
        proposedTransactionPercentage = _threshold;
        emit SubmitThresholdChange(msg.sender, "Transaction");
    }

    /**
     * @dev Submit request to change participant rotation threshold
     * @param _threshold Proposed Rotation Threshold #
     */
    function submitRotationThresholdChange(uint256 _threshold)
        public
        isUserRegistered
    {
        if (proposedTransactionPercentage != 0) {
            revert("Proposed Rotation threshold proposed already");
        }
        proposedRotationPercentage = _threshold;
        emit SubmitThresholdChange(msg.sender, "Participant Rotation");
    }

    /**
     * @dev Submit request to change adminthreshold
     * @param _threshold Proposed Admin Threshold #
     */
    function submitAdminThresholdChange(uint256 _threshold)
        public
        isUserRegistered
    {
        if (proposedTransactionPercentage != 0) {
            revert("Admin threshold proposed already");
        }
        proposedAdminPercentage = _threshold;
        emit SubmitThresholdChange(msg.sender, "Admin");
    }

    /**
     * @dev Submit vote to approve proposed transaction threshold
     */
    function voteOnTransactionThresholdChange() public isUserRegistered {
        if (approvedTransactionThresholdChange[msg.sender]) {
            revert("Voted already");
        }
        approvedTransactionThresholdChange[msg.sender] = true;
        transactionThresholdVotes = transactionThresholdVotes++;
        emit ThresholdVote(msg.sender, "Transaction");
    }

    /**
     * @dev Submit vote to approve proposed rotation threshold
     */
    function voteOnRotationThresholdChange() public isUserRegistered {
        if (approvedRotationThresholdChange[msg.sender]) {
            revert("Voted already");
        }
        approvedRotationThresholdChange[msg.sender] = true;
        rotationThresholdVotes = rotationThresholdVotes++;
        emit ThresholdVote(msg.sender, "Rotation");
    }

    /**
     * @dev Submit vote to approve proposed admin threshold
     */
    function voteOnAdminThresholdChange() public isUserRegistered {
        if (approvedAdminThresholdChange[msg.sender]) {
            revert("Voted already");
        }
        approvedAdminThresholdChange[msg.sender] = true;
        adminThresholdVotes = adminThresholdVotes++;
        emit ThresholdVote(msg.sender, "Admin");
    }

    /**
     * @dev Perform the transaction threshold # change
     */
    function performTransactionThresholdChange() private {
        if (
            transactionThresholdVotes <
            (adminThreshold * registeredAddresses.length) / 100
        ) {
            revert("votes not received");
        }
        transactionThreshold = proposedTransactionPercentage;
        for (uint256 i = 0; i < registeredAddresses.length; i++) {
            approvedTransactionThresholdChange[registeredAddresses[i]] = false;
        }
        emit ThresholdChangeComplete(address(this), "Transaction");
    }

    /**
     * @dev Perform the rotation threshold # change
     */
    function performRotationThresholdChange() private {
        if (
            rotationThresholdVotes <
            (adminThreshold * registeredAddresses.length) / 100
        ) {
            revert("votes not received");
        }
        rotateThreshold = proposedRotationPercentage;
        for (uint256 i = 0; i < registeredAddresses.length; i++) {
            approvedRotationThresholdChange[registeredAddresses[i]] = false;
        }
        emit ThresholdChangeComplete(address(this), "Participant Rotation");
    }

    /**
     * @dev Perform the admin threshold # change
     */
    function performAdminThresholdChange() private {
        if (
            adminThresholdVotes <
            (adminThreshold * registeredAddresses.length) / 100
        ) {
            revert("votes not received");
        }
        adminThreshold = proposedAdminPercentage;
        for (uint256 i = 0; i < registeredAddresses.length; i++) {
            approvedAdminThresholdChange[registeredAddresses[i]] = false;
        }
        emit ThresholdChangeComplete(address(this), "Admin");
    }

    /**
     * @dev Submit invalid share and alert everyone
     */
    function submitShareDispute() public isUserRegistered {
        for (uint256 i = 0; i < proposedAddresses.length; i++) {
            if (proposedAddresses[i] == msg.sender) {
                disputeAddresses.push(msg.sender);
            }
        }
        emit submitDisputeEvent(msg.sender);
    }

    /////*****  *******  *****/////
    /////*****  Getters  *****/////
    /////*****  *******  *****/////

    /**
     * @dev Return information related to a specific vault
     * @return Array of vault address, master public key [0,1]
     * @return Array String of vault name, current phase of vault
     * @return Array of participant addresses
     * @return Array Num of transaction threshold, participants required to confirm a transaction before it is submitted, balance of Master public key
     * @return Array Num of user statuses, have they registered, and, eventually, others.
     * @return Array Num of vault  statuses, registered addresseses length, proposed participant to rotate submitted, transaction counter, created date, threshold #s for admin, transaction, rotation, dispute count
     */
    function getVaultInfo()
        external
        view
        returns (
            address[2] memory,
            string[2] memory,
            address[] memory,
            uint256[3] memory,
            bool[2] memory,
            uint256[8] memory
        )
    {
        address[2] memory addresses = [address(this), masterAddress];
        string memory currentPhase;
        if (registrationComplete) {
            currentPhase = "Registration Complete";
        } else {
            currentPhase = "Pre-Registration";
        }

        string[2] memory nameAndStatus = [vaultName, currentPhase];
        uint256[3] memory transactionData = [
            txCounter,
            transactionThreshold,
            address(masterAddress).balance
        ];
        bool[2] memory userStatuses = [
            userConfirmRegistration[msg.sender],
            false
        ];
        uint256[8] memory vaultStatuses = [
            registeredAddresses.length,
            rotateParticipantStatus.submitted,
            txCounter,
            createdDate,
            transactionThreshold,
            rotateThreshold,
            adminThreshold,
            disputeAddresses.length
        ];
        return (
            addresses,
            nameAndStatus,
            proposedAddresses,
            transactionData,
            userStatuses,
            vaultStatuses
        );
    }

    /**
     * @dev Gather an individuals public and private shares for a vault
     * @return Array [id (aka public key), secretkey] for this group
     */
    function getParticipantShares() external view returns (string[3] memory) {
        return (
            [
                id_share[msg.sender],
                encrypted_share[msg.sender],
                verificationVector
            ]
        );
    }

    /**
     * @dev Get the information regarding the submitted transaction details
     * @param _txId id of the transaction that we want to get info from
     * @return string serialized TX data
     * @return Num how many confirmed TX we have
     */
    function getTransactionSubmissionInfo(uint256 _txId)
        external
        view
        txExists(_txId)
        returns (
            bytes memory,
            bytes memory,
            uint256,
            bool
        )
    {
        return (
            txList[_txId],
            userApprovedTx[_txId][msg.sender],
            txApprovedCount[_txId],
            txSent[_txId]
        );
    }

    /**
     * @dev Get the information regarding the submitted transaction details
     * @return proposedRotateUserAddress Address we propose to rotate
     * @return userVotes Number how many votes does the motion have
     * @return addOrRemove String Adding or Removing this participant
     * @return readyToRotate bool Votes have been reached, ready to perform rotation
     * @return submitted Number Do we have a proposed rotation or not
     */
    function getRotationProposalInfo()
        external
        view
        isUserRegistered
        returns (
            address,
            uint256,
            uint256,
            uint256,
            bool
        )
    {
        return (
            rotateParticipantStatus.proposedRotateUserAddress,
            rotateParticipantStatus.userVotes,
            rotateParticipantStatus.addOrRemove,
            rotateParticipantStatus.submitted,
            rotateParticipantStatus.readyToRotate
        );
    }

    /**
     * @dev Gather all encrypted secrets for a particular transaction,
     * @return Array of all ids and secret keys of the participants
     */
    function getAllSharesForTx(uint256 _txId)
        external
        view
        returns (string[] memory, bytes[] memory)
    {
        uint256 arrLength = registeredAddresses.length;
        string[] memory ids = new string[](arrLength);
        bytes[] memory pks = new bytes[](arrLength);
        for (uint256 i = 0; i < arrLength; i++) {
            if (
                bytes(userApprovedTx[_txId][registeredAddresses[i]]).length > 0
            ) {
                pks[i] = userApprovedTx[_txId][registeredAddresses[i]];
                ids[i] = id_share[proposedAddresses[i]];
            }
        }
        return (ids, pks);
    }

    /**
     * @dev Gather all signed txs to send the transaction
     * @return Array of all ids and secret keys of the participants
     */
    function getAllSignedTx(uint256 _txId)
        external
        view
        returns (bytes[] memory, string[] memory)
    {
        uint256 arrLength = registeredAddresses.length;
        string[] memory ids = new string[](arrLength);
        bytes[] memory signedTx = new bytes[](arrLength);
        for (uint256 i = 0; i < arrLength; i++) {
            if (
                bytes(userApprovedTx[_txId][registeredAddresses[i]]).length > 0
            ) {
                signedTx[i] = userApprovedTx[_txId][registeredAddresses[i]];
                ids[i] = id_share[proposedAddresses[i]];
            }
        }
        return (signedTx, ids);
    }
}