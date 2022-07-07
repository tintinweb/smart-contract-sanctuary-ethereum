// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.0;

/**
 * @author Halborn - Copyright (C) 2021-Present
 * @notice Seraph storage
 * @dev This contract will be used to keep track of the storage layout when dealing with proxies
 * on Seraph. Any new storage variable should be added at the end of this contract, extending
 * the storage, and solving storage collision as detailed in
 * https://docs.openzeppelin.com/upgrades-plugins/1.x/proxies#storage-collisions-between-implementation-versions
 *
 */
contract SeraphStorage {
    /// @notice Used to track if a client, contract or function is tracked and protected by Seraph™
    struct Tracking {
        bool _isProtected;
        bool _isTracked;
    }

    /// @notice Used by getters to represent a client identifier and the protection.
    struct ClientView {
        bytes32 _id;
        bool _isProtected;
    }

    /// @notice Used by getters to represent a contract identifier and the protection.
    struct ContractView {
        address _address;
        bool _isProtected;
    }

    /// @notice Used by getters to represent a function identifier and the protection.
    struct FunctionView {
        bytes4 _functionSelector;
        bool _isProtected;
    }

    /// @notice Used to store all the calls in order that will be executed on the approved
    /// transaction and to verify, during the actual exeuction, the integrity of it.
    struct CallStackState {

        /// @notice Used to store all permits that will be executed on the approved tx
        /// @dev We are not using an array since we only need the total length when verifying the integrity.
        /// Using an array does cost more gas, since the length and permit value should be stored for each
        /// approval. For multi-approvals, writing just the value and then a single store for the count
        /// is cheaper:
        /// (2*SSTORE * approvals) > (SSTORE * approvals + SSTORE)
        mapping(uint256 => bytes32) toExecute;

        /// @notice The total calls that are approved and need to be executed. This is used to verify
        /// that all calls where executed when returning from the first protected call (depth eq 0).
        uint256 toExecuteCount;

        /// @notice Number of already executed calls for this integrity
        uint256 numExecuted;

        /// @notice It holds the call stack depth of protected functions. Used to validate
        /// the integrity when returning from the first call protected by seraph
        uint256 depth;
    }

    //////////////////////
    // Clients
    //////////////////////

    /// @notice Used to get all tracked clients
    bytes32[] internal _clients;

    /// @notice Used to track registered clients on Seraph
    mapping(bytes32 => Tracking) internal _clientTracking;

    /// @notice Used to access all contract addresses for a specific client id
    /// @dev 1 to N: One clientId has many contracts
    mapping(bytes32 => address[]) internal _clientContracts;

    //////////////////////
    // Contracts
    //////////////////////

    /// @notice Used to track registered contracts on Seraph
    /// @dev We don't use a mapping based on client id since only one contract address can cohexist
    /// and two clients can not have the same address.
    /// 1 to 1: One address has one Contract struct.
    mapping(address => Tracking) internal _contractTracking;

    /// @notice used to get the client id for the given address
    mapping(address => bytes32) internal _contractClient;

    /// @notice Used to access all function selectors for a specific contract address.
    /// @dev 1 to N: One contract has many function selectors
    mapping(address => bytes4[]) internal _contractFunctions;

    //////////////////////
    // Functions
    //////////////////////

    /// @notice Used to get a function object based on the contract address and the function selector
    /// @dev Its possible to have the same function signature for two different contracts,
    /// thats why we need to map each contract address with each own selector mapping
    mapping(address => mapping(bytes4 => Tracking)) internal _functionTracking;

    //////////////////////
    // Caller state
    //////////////////////

    /// @notice The integrity object used to validate an approval execution. The mapping key is the tx.orgin
    mapping(address => CallStackState) internal _callStackStates;

    //////////////////////
    // Admin state
    //////////////////////

    /// @notice A whitelist mapping for all addresses allowed to approve tx on Seraph.
    /// A new key will only be whitelisted when a KMS key is generated on the RPC backend.
    mapping(address => bool) internal _approversWhitelist;

    /// @notice Whether Seraph was has been _initialised or not.
    /// @dev This value can only be set using the initializer modifier
    bool internal _initialised;

    /// @notice KMS wallet used for administrative purpose on Seraph. Halborn will not have control of
    /// the private key. Only Lambda code will be allowed to sign with it.
    ///
    /// @dev This wallet will be set during initialization. A setter will exist in case of KMS outage
    /// so the owner can change it and replicate the administration using a mutisig wallet.
    address public admin;

    /// @notice Owner of Seraph, it will be a multisig wallet that is only capable of changing the admin
    /// KMS key
    address public owner;

}

/**
 * @author Halborn - Copyright (C) 2021-Present
 * @notice
 * Seraph ™ is a Blockchain Security Notary, developed by Halborn, who's mission is to bridge the gap between
 * decentralized and centralized smart contract administration to protects both, users and developers.
 *
 * Seraph protects DEVELOPERS/OWNERS by:
 *
 * - Removing the risk of completely revoking contract ownership.
 * - Providing an incident response and notification service to facilitate easy and fast smart contract administration and operations.
 * - Separates the personal risk that comes with single key custody.
 * - Increases community and investor confidence in the security of their funds.
 *
 * Seraph protects smart contract USERS by:
 *
 * - Removing the risk of centralized administration and liquidity access.
 * - Providing third-party security oversight to validate all contract operations are legitimate
 *
 * @dev
 * Seraph does keep the Storage on a separated contract named SeraphStorage for simplicity and upgradability,
 * only code logic is present on Seraph contract
 *
 * On Seraph the initialization is taken care by the {initSeraph} function, this function will be called whenever
 * the proxy links to this logic contract To ensure that the initialize function can only be called once, a
 * simple modifier named `initializer` is used.
 *
 * When the contrat is deployed, no owner or administrative wallets are present. That means, that
 * Seraph is not operable until {initSeraph} is called.
 */
contract Seraph is SeraphStorage {

    event NewAdmin(address _old, address _new);

    event NewApprove(bytes32 _txHash);

    event NewClient(bytes32 indexed _clientId);
    event NewContract(bytes32 indexed _clientId, address _contractAddress);
    event NewFunction(bytes32 indexed _clientId, address indexed _contractAddress, bytes4 _functionSelector);

    event NewClientProtection(bytes32 indexed _clientId, bool _protected);
    event NewContractProtection(address indexed _contractAddress, bool _protected);
    event NewFunctionProtection(address indexed _contractAddress, bytes4 _functionSelector, bool _protected);

    event ApproverAdded(address indexed account);
    event ApproverRemoved(address indexed account);

    event UnprotectedExecuted(bytes32 indexed _clientId, address indexed _contractAddress, bytes4 indexed _functionSelector, bytes _callData, uint256 _value);


    /// @dev Slot used by the simulation to bypass approvals
    bytes32 private constant SIMULATION_SLOT = keccak256("SIMULATION_SLOT");

    /**
     * @notice Function used during Seraph initialisation to transfer ownership to a multisig wallet and
     * KMS administrative permissions.
     *
     * @dev Should only be callable once. The {newOwner} will be the new owner of the contract and
     * {newAdmin} will be the wallet with administrative permission on Seraph. NOTE: When the
     * contrat is deployed, no owner or administrative wallets are present. That means, that Seraph is
     * not operable until {initSeraph} is called.
     *
     * @param newOwner The owner of Seraph. It will only be allowed to change KMS admin wallet
     * @param newAdmin The KMS admin wallet. It will be allowed to administrate Seraph.
     */
    function initSeraph(address newOwner, address newAdmin) external initializer {

        require(newOwner != address(0), "Seraph: owner != 0");
        require(newAdmin != address(0), "Seraph: admin != 0");

        owner = newOwner;
        admin = newAdmin;

        emit NewAdmin(address(0), newAdmin);
    }

    //////////////////////////
    // Permission modifiers //
    //////////////////////////

    /**
     * @notice Modifier used to verify that the sender is the owner of this contract
     * Seraph ownership will be managed using a multisig wallet
     */
    modifier onlyOwner(){
        require(msg.sender == owner, "Seraph: Only owner allowed");
        _;
    }

    /**
     * @notice Modifier used to verify that the sender is the KMS administrative wallet
     */
    modifier onlySeraphAdmin(){
        require(msg.sender == admin, "Seraph: Only Seraph KMS wallet allowed");
        _;
    }

    /**
     * @notice Modifier used to verify that the sender is whitelisted as an approver
     */
    modifier onlyApprover() {
        require(_approversWhitelist[msg.sender], "Seraph: Not an approver");
        _;
    }

    /**
     * @notice Modifier used to verify that a client exists by using its {clientId} identifier.
     *
     * @param clientId The client identifier that will be checked
     */
    modifier clientExists(bytes32 clientId){
        require(_clientTracking[clientId]._isTracked, "Seraph: Client does not exist");
        _;
    }

    /**
     * @notice Modifier used to verify that a contract exists by using its {contractAddress} identifier.
     *
     * @param contractAddress The contract identifier that will be checked
     */
    modifier contractExists(address contractAddress){
        require(_contractTracking[contractAddress]._isTracked, "Seraph: Contract is not tracked");
        _;
    }

    /**
     * @notice Modifier used to verify that a function for a given contract exists by using
     * its {functionSelector} identifier and the key parent {contractAddress} identifier.
     *
     * @param contractAddress The contract where the functionSelector is supposed to live.
     * @param functionSelector The function identifier that will be checked
     */
    modifier functionExists(address contractAddress, bytes4 functionSelector){
        require(_functionTracking[contractAddress][functionSelector]._isTracked, "Seraph: Function is not tracked");
        _;
    }

    /**
     * @notice Modifier used to verify that the contract is not initialised already
     */
    modifier initializer(){
        require(!_initialised, "Seraph: Contract already initialised");
        _;
        _initialised = true;
    }

    ////////////////////////
    // Internal functions //
    ////////////////////////

    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `_isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     * @param addr The actual address to check for being a contract
     */
    function _isContract(address addr) internal view returns (bool){
        uint256 size;
        assembly {
            size := extcodesize(addr)
        }
        return (size > 0);
    }

    /**
     * @notice This function is used to verify if a function is protected or not. It will
     * use the parents protection to verify the full chain. If any of the parents
     * or the element itself is not protected a false is returned.
     *
     * @param contractAddress The contract were the `functionSelector` is from
     * @param functionSelector The function identifier
     * @return It will return false if any of the full chain {_isProtected} is false.
     * Returning true otherwise
     */
    function functionProtected(address contractAddress, bytes4 functionSelector) public view returns(bool){
        return (
            _functionTracking[contractAddress][functionSelector]._isProtected &&
            _contractTracking[contractAddress]._isProtected &&
            _clientTracking[_contractClient[contractAddress]]._isProtected
        );
    }

    /**
     * @notice This function is used to verify if a contract is protected or not. It will
     * use the parents protection to verify the full chain. If any of the parents
     * or the element itself is not protected a false is returned.
     *
     * @param contractAddress The contract were the `functionSelector` is from
     * @return It will return false if any of the full chain {_isProtected} is false.
     * Returning true otherwise
     */
    function contractProtected(address contractAddress) public view returns(bool){
        return (
            _contractTracking[contractAddress]._isProtected &&
            _clientTracking[_contractClient[contractAddress]]._isProtected
        );
    }

    /**
     * @notice This function is used to verify if a client is protected or not.
     *
     * @param clientId The id of the client to check
     * @return It will return true if the client is protected, false otherwise
     */
    function clientProtected(bytes32 clientId) external view returns(bool){
        return _clientTracking[clientId]._isProtected;
    }

    /**
     * @notice This function will add a contract to a given `clientId` for a given `contractAddress`. If the contract
     * already exists, it will verify the ownership using `clientId` and return
     *
     * @param clientId The client owner for this contract. If the contract exists it will be used
     * to verify ownership
     * @param contractAddress The contract address indentifier. Only one address can exist
     */
    function _addContractToClient(bytes32 clientId, address contractAddress) internal {

        require(contractAddress != address(0), "Seraph: contractAddress != 0");
        require(_isContract(contractAddress), "Seraph: not a contract");

        if (!_contractTracking[contractAddress]._isTracked) {

            Tracking storage _contract = _contractTracking[contractAddress];

            // Identifier and parent identifier
            _contract._isProtected = true;
            _contract._isTracked = true;

            _contractClient[contractAddress] = clientId;

            _clientContracts[clientId].push(contractAddress);

            emit NewContract(
                clientId,
                contractAddress);

        } else {
            require(_contractClient[contractAddress] == clientId, "Seraph: Contract is from another client");
        }

    }

    /**
     * @notice This function will add a function to a given {clientId} and {contractAddress}.
     * If the function alreay exists, nothing happens.
     *
     * @dev The function parameters must be checked for being valid or different than zero.
     * If the parameters are valid it will check if the function already exists, after validating
     * the contract, using the {functionSelector} identifier. This function should check that
     * the generated functionSelector is different than zero. Since a function is mapped on a
     * contract address no ownership verification will be performed
     *
     * @param contractAddress The contract address indentifier. Only one address can exist
     * @param functionSelector The function selector.
     */
    function _addFunctionToContract(address contractAddress, bytes4 functionSelector) internal {

        // If the function is not tracked, we will add it. Ignore otherwise
        if (!_functionTracking[contractAddress][functionSelector]._isTracked) {

            Tracking storage _function = _functionTracking[contractAddress][functionSelector];

            // Identifier and parent identifier
            _function._isProtected = true;
            _function._isTracked = true;

            _contractFunctions[contractAddress].push(functionSelector);

            emit NewFunction(
                _contractClient[contractAddress],
                contractAddress,
                functionSelector);
        }

    }


    //////////////////////
    // Getter functions //
    //////////////////////

    /**
     * @notice It will calculate the permit hash used internally to validate the calldata for a given {contractAddress}
     * and {functionSelector}. The returned value is a keccak256 of the packed {contractAddress}, {functionSelector}
     * and {callData}.
     *
     * @param contractAddress The contract address of containing the {functionSelector}
     * @param functionSelector The actual function of the permit
     * @param callData The only valid calldata that will be allowed to trigger the function (abi encoded with function selector).
     */
    function getPermitHash(address callerAddress, address contractAddress, bytes4 functionSelector, bytes memory callData, uint256 value) public pure returns(bytes32){
        return keccak256(abi.encodePacked(callerAddress, contractAddress, functionSelector, callData, value));
    }


    /**
     * @notice When the tx is send to the Seraph RPC it is simulated in order to determine what functions
     * are executed and in which order. If any of the functions do implement Seraph, the simulation would revert
     * due to the approval not being present. In order to skip the approval requiriments and the integrity check
     * validations, a READ ONLY flag under the {SIMULATION_SLOT} slot is present. This slot will be manipulated
     * during simulation to skip the validation checks.
     *
     * @return is_simulation will be set to true if the tx is being simulated
     */
    function _is_simulation() private view returns (bool is_simulation) {
        bytes32 simulation_slot = SIMULATION_SLOT;
        assembly {
            is_simulation := sload(simulation_slot)
        }
    }

    /////////////////////////
    // FE Getter functions //
    /////////////////////////

    /**
     * @notice Getter that returns a list of contracts
     *
     * @param clientId The client identifier to get the contracts from
     * @return All contracts for a given {clientId}
     */
    function getAllClientContracts(bytes32 clientId) external view returns(ContractView[] memory) {
        ContractView[] memory _contracts = new ContractView[](_clientContracts[clientId].length);
        for (uint256 i = 0; i < _clientContracts[clientId].length; i++) {
            _contracts[i]._address = _clientContracts[clientId][i];
            _contracts[i]._isProtected = contractProtected(_clientContracts[clientId][i]);
        }
        return _contracts;
    }

    /**
     * @notice Getter that returns a list of functions
     *
     * @param contractAddress The contract address to get the functions from
     * @return All functions for a given {contractAddress}
     */
    function getAllContractFunctions(address contractAddress) external view returns(FunctionView[] memory) {
        FunctionView[] memory _functions = new FunctionView[](_contractFunctions[contractAddress].length);
        for (uint256 i = 0; i < _contractFunctions[contractAddress].length; i++) {
            _functions[i]._functionSelector = _contractFunctions[contractAddress][i];
            _functions[i]._isProtected = functionProtected(contractAddress, _contractFunctions[contractAddress][i]);
        }
        return _functions;
    }

    /**
     * @notice Getter that returns a list of clients
     *
     * @return All clients on this chain
     */
    function getAllClients() external view returns(ClientView[] memory) {
        ClientView[] memory _clients_view = new ClientView[](_clients.length);
        for (uint256 i = 0; i < _clients.length; i++) {
            _clients_view[i]._id = _clients[i];
            _clients_view[i]._isProtected = _clientTracking[_clients[i]]._isProtected;
        }
        return _clients_view;
    }

    //////////////////////////////
    // Administrative functions //
    //////////////////////////////

    /**
     * @notice This functions adds a new client with a given ID as tracked and protected
     *
     * @param clientId The off-chain ID for this client
     */
    function addClient(bytes32 clientId) external onlySeraphAdmin {

        require(clientId != bytes32(0), "Seraph: Client ID != 0");

        Tracking storage _client = _clientTracking[clientId];
        require(!_client._isTracked, "Seraph: Client already exists");

        _client._isProtected = true;
        _client._isTracked = true;

        _clients.push(clientId);

        emit NewClient(clientId);
    }

    /**
     * @notice This function will add a function to a given {clientId} and {contractAddress}.
     * This is the public interface for {_addContractToClient}, {_addFunctionToContract} and
     * {_addWalletToClient} function were all the parameters are checked. Only seraph KMS admin
     * wallet can call it ({onlySeraphAdmin}).
     *
     * @dev The {clientId} should exist off-chain before calling this function.
     *
     * @param clientId The client owner for this contract. If the contract exists it will be used
     * to verify ownership
     * @param contractAddress The contract address indentifier. Only one address can exist
     * @param functionSelector The function selector.
     */
    function addContractAndFunction(bytes32 clientId, address contractAddress, bytes4 functionSelector) external onlySeraphAdmin clientExists(clientId) {

        _addContractToClient(clientId, contractAddress);

        _addFunctionToContract(contractAddress, functionSelector);

    }

    /**
     * @notice Multicall function used to operate on Seraph
     * It will be mainly used to add multiple clients/contracts/functions into the Seraph contract
     * in a single transaction.
     *
     * @param data List of Seraph functions with the calldata that will be called
     */
    function multiCall(bytes[] calldata data) external onlySeraphAdmin {
        for (uint256 i = 0; i < data.length; i++) {

            (bool success, bytes memory result) = address(this).delegatecall(data[i]);

            // functionDelegateCall from OZ
            if (!success) {
                if (result.length > 0) {
                    assembly {
                        let returndata_size := mload(result)
                        revert(add(32, result), returndata_size)
                    }
                } else {
                    revert("Failed delegatecall");
                }
            }
        }
    }

    ///////////////////////////
    // Seraph main functions //
    ///////////////////////////

    /**
     * @notice This function will generate a linked hash list of approved calls, aka permits, and store them into
     * the call stack state object of the tx.origin that generated the transaction.
     * If any of the functions that are being called is not protected, the generation of the approval for that
     * specific call will be skipped.
     *
     * This function is only callable by an approver. The approvers will be added into the system when a
     * new approver KMS key is generated on the backend system for this specific chain.
     * The key will be added using `addApprover`.
     *
     * @param txOrigin The origin of the transaction
     * @param approvalsArray A list containing (callerAddress, contractAddress, functionSelector, callData, value)
     * for each call of the approved transaction
     */
    function approve(address txOrigin, bytes[] calldata approvalsArray) external onlyApprover {

        require(approvalsArray.length > 0, "Seraph: No approvals");

        CallStackState storage _state = _callStackStates[txOrigin];

        _state.numExecuted = 0;
        _state.depth = 0;

        uint256 _toExecuteCount = 0;

        for (uint256 i = 0; i < approvalsArray.length; i++) {

            (address callerAddress, address contractAddress, bytes4 functionSelector, bytes memory callData, uint256 value) = abi.decode(approvalsArray[i], (address, address, bytes4, bytes, uint256));

            /// @dev If it is not protected we don't add an approval
            if (!functionProtected(contractAddress, functionSelector)){
                continue;
            }

            bytes32 _permitHash = getPermitHash(callerAddress, contractAddress, functionSelector, callData, value);
            _state.toExecute[_toExecuteCount] = _permitHash;
            _toExecuteCount++;
        }

        _state.toExecuteCount = _toExecuteCount;

    }

    /**
     * @notice It will verify that the calling contract and given signature is approved
     * by Halborn to be executed. If any of the hierarchy objects is not protected it will
     * return, allowing the execution to continue. This function is part of the modifier
     * that the client will need to use Seraph.
     *
     * @dev  We should be aware of all functions calling {checkEnter} thats why we need
     * to verify that the calling function exists. Verifying that the function exists
     * allows {functionProtected} to not fetch unexisting states (defaulting to false).
     * We are not checking contractExists to save some gas. functionExists does use the
     * contract address, and should exist anyway.
     *
     * @param callerAddress The address calling the protected function.
     * @param functionSelector The function identifier that will be checked. This parameter
     * is send using {msg.sig} by the Seraph modifier that the client will implement
     * @param callData The only valid calldata that will be allowed to trigger the function (abi encoded with function selector)
     * @param value The msg.value of the function call
     */
    function checkEnter(address callerAddress, bytes4 functionSelector, bytes calldata callData, uint256 value) external functionExists(msg.sender, functionSelector) {

        if (!functionProtected(msg.sender, functionSelector)){
            emit UnprotectedExecuted(
                _contractClient[msg.sender],
                msg.sender,
                functionSelector,
                callData,
                value
                );
            return;
        }

        CallStackState storage _state = _callStackStates[tx.origin];

        bytes32 _permitHash = getPermitHash(callerAddress, msg.sender, functionSelector, callData, value);

        require(_state.toExecute[_state.numExecuted] == _permitHash || _is_simulation(), "Seraph: Transaction not approved");

        /// @dev On simulation this should already be 0, we need to add ~5000 per approval when estimating gas
        /// for the NetSstoreCleanGas operation that will happen on none-simulated scenario
	    /// NetSstoreCleanGas uint64 = 5000  // Once per SSTORE operation from clean non-zero.
        _state.toExecute[_state.numExecuted] = 0;

        _state.depth++;
        _state.numExecuted++;

    }

    /**
     * @notice If any of the hierarchy objects is not protected it will
     * return, allowing the execution to continue. This is the function that will be
     * executed when retruning from an approved function call. If the function was protected
     * it will verify that the integrity for the tx.origin does mantain, and the
     * last executed call is the one present on the call stack. Furthermore, if the last call is
     * returned from, it will verify that the full call trace was executed.
     *
     * This function is part of the modifier that the client will need to use Seraph.
     *
     * @param functionSelector The function identifier that will be checked. This parameter
     * is send using {msg.sig} by the Seraph modifier that the client will implement. This is
     * only used to skip integrity checks on un-protected functions.
     */
    function checkLeave(bytes4 functionSelector) external {

        if (!functionProtected(msg.sender, functionSelector)){
            return;
        }

        CallStackState storage _state = _callStackStates[tx.origin];

        _state.depth--;

        if (_state.depth == 0) {
            require(_state.toExecuteCount == _state.numExecuted || _is_simulation(), "Seraph: Integrity check");
            /// @dev On simulation this should already be 0, we need to add ~5000 per tx when estimating gas
            /// for the NetSstoreCleanGas operation that will happen on none-simulated scenario
            /// NetSstoreCleanGas uint64 = 5000  // Once per SSTORE operation from clean non-zero.
            _state.toExecuteCount = 0;
        }

    }

    ////////////////////////////
    // Admin setter functions //
    ////////////////////////////

    /**
     * @notice It will add an approver address to the approvers whitelist
     *
     * @dev This will only be callable when creating an approver KMS key
     *
     * @param _address The address to whitelist
     */
    function addApprover(address _address) external onlySeraphAdmin {
        _approversWhitelist[_address] = true;
        emit ApproverAdded(_address);
    }

    /**
     * @notice It will remove an approver address from the approvers whitelist
     *
     * @param _address The address to remove from the whitelist
     */
    function removeApprover(address _address) external onlySeraphAdmin {
        _approversWhitelist[_address] = false;
        emit ApproverRemoved(_address);
    }

    /**
     * @notice It will change the protection state for the given {clientId} and set it
     * to {value}. Only seraph KMS admin wallet can call it ({onlySeraphAdmin}).
     * @dev Client should exist in order to change the {_isProtected} value
     *
     * @param clientId The client identifier that the protection will be changed
     * @param value The new protect state
     */
    function setClientProtected(bytes32 clientId, bool value) external onlySeraphAdmin {
        _clientTracking[clientId]._isProtected = value;
        emit NewClientProtection(clientId, value);
    }

    /**
     * @notice It will change the protection state for the given {contractAddress} and set it
     * to {value}. Only seraph KMS admin wallet can call it ({onlySeraphAdmin}).
     * @dev Contract should exist in order to change the {_isProtected} value
     *
     * @param contractAddress The contract address that the protection will be changed
     * @param value The new protect state
     */
    function setContractProtected(address contractAddress, bool value) external onlySeraphAdmin contractExists(contractAddress) {
        _contractTracking[contractAddress]._isProtected = value;
        emit NewContractProtection(contractAddress, value);
    }

    /**
     * @notice It will change the protection state for the given contract/function
     * and set it to {value}. Only seraph KMS admin wallet can call it ({onlySeraphAdmin}).
     * @dev Function should exist in order to change the {_isProtected} value
     *
     * @param contractAddress The contract address that the protection will be changed
     * @param functionSelector The function identifier that the protection will be changed
     * @param value The new protect state
     */
    function setFunctionProtected(address contractAddress, bytes4 functionSelector, bool value) external onlySeraphAdmin contractExists(contractAddress) functionExists(contractAddress, functionSelector) {
        _functionTracking[contractAddress][functionSelector]._isProtected = value;
        emit NewFunctionProtection(contractAddress, functionSelector, value);
    }

    ////////////////////////////
    // Owner setter functions //
    ////////////////////////////

    /**
     * @notice Function present in case of AWS KMS failure or migration. This allows the owner (multisig)
     * to set a new KMS admin wallet that will have privileges to add clients, contracts and functions and
     * update them.
     *
     * @param newWallet The new wallet used for administrative purpose on Seraph. Only KMS wallets should be
     * given here unless AWS KMS failure occurs.
     */
    function setAdmin(address newWallet) external onlyOwner {
        require(newWallet != address(0), "Seraph: != 0");
        emit NewAdmin(admin, newWallet);

        admin = newWallet;
    }

}