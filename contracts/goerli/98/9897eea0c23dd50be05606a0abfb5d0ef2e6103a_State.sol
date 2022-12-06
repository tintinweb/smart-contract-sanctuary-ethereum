/**
 *Submitted for verification at Etherscan.io on 2022-12-06
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @author Halborn - Copyright (C) 2021-Present
 * @notice State contract for Seraph storage
 * @dev This contract will be used to provide with some capabilities to the clients of Seraph
 *
 */

contract StateStorage {

    /// @notice Seraph address
    ISeraph constant public seraph = ISeraph(0x5bAE40b37adA3385d4fF41Ec9973D7DF4Aa9B13C);
    // test only 
   /*   ISeraph public seraph = ISeraph(0xAac09eEdCcf664a9A6a594Fc527A0A4eC6cc2788);

    function setSeraph (address _seraph) public {
        seraph = ISeraph(_seraph);
    }  */

       /// @notice Used to store the time frame in which the action can be executed
     struct Timelock{
        uint initdate;
        uint finishdate;
    }

    /// @notice Used by getters to represent a client identifier and the timelock associated
    mapping(bytes32 => Timelock) timelocks;

    /// @notice Used by getters to represent the admin address for the client
    mapping(bytes32 => address) clients_to_address;


    /// @notice Used by getters to represent the admin address for the client
    mapping(address => bytes32) address_to_clients;

    /// @notice Whether the contract was has been _initialised or not.
    /// @dev This value can only be set using the initializer modifier
    bool internal _initialised;

    /// @notice Listo of  clients.
    bytes32 [] public clients;

    /// @notice  wallet used for administrative purpose on Seraph. Halborn will not have control of
    /// the private key.
    ///
    /// @dev This wallet will be set during initialization. A setter will exist
    /// so the owner can change it and replicate the administration using a mutisig wallet.
    address public admin;


    /// @notice Owner of the contract, it will be a multisig wallet that is only capable of changing the admin
    /// KMS key
    address public owner;

}
interface ISeraph {
    function setClientProtected(bytes32 clientId, bool value) external;
    function clientProtected(bytes32 clientId) external view returns(bool);

}


/**
 * @author Halborn - Copyright (C) 2021-Present
 * @notice State contract for Seraph
 * @dev This contract will be used to provide with some capabilities to the clients of Seraph
 *
 */
contract State is StateStorage {

    event NewAdmin(address _old, address _new);

    event ClientAddressAdded(address whitelisted_address, bytes32 indexed  clientId);

    event NewSeraphRemovalRequest(address whitelisted_address, bytes32 indexed clientId);

    event NewSeraphRemovalExecution(address whitelisted_address,bytes32 indexed _clientId);

    event cancelledRemovalRequest(address whitelisted_address,bytes32 indexed _clientId);

    /**
     * @notice Function used during the contract initialisation to transfer ownership to a multisig wallet and
     * KMS administrative permissions.
     *
     * @dev Should only be callable once. The {newOwner} will be the new owner of the contract and
     * {newAdmin} will be the wallet with administrative permission. NOTE: When the
     * contrat is deployed, no owner or administrative wallets are present. That means, that the state contract is
     * not operable until {initState} is called.
     *
     * @param newOwner The owner of thecontract. It will only be allowed to change KMS admin wallet
     * @param newAdmin The KMS admin wallet. It will be allowed to administrate the contract.
     */
    function initState(address newOwner, address newAdmin) external initializer {

        require(newOwner != address(0), "State: owner != 0");
        require(newAdmin != address(0), "State: admin != 0");

        owner = newOwner;
        admin = newAdmin;

        emit NewAdmin(address(0), newAdmin);
    }

    /**
     * @notice Modifier used to verify that the sender is the KMS administrative wallet
     */
    modifier onlySeraphAdmin(){
        require(msg.sender == admin, "State: Only Serap wallet allowed");
        _;
    }

    /**
     * @notice Modifier used to verify that the sender is the owner of this contract
     */
    modifier onlyOwner(){
        require(msg.sender == owner, "State: Only owner allowed");
        _;
    }

    /**
     * @notice Modifier used to verify that the contract is not initialised already
     */
    modifier initializer(){
        require(!_initialised, "State: Contract already initialised");
        _;
        _initialised = true;
    }

    
    /**
     * @notice Function that allows to register and change data bout clients
     *
     * @param clientid The client identifier to get the contracts from
     * @param whitelisted_address The authorized address for that client
     */
    function addClient(bytes32 clientid, address whitelisted_address) onlySeraphAdmin external { 
        require(whitelisted_address!= address(0), "Whitelisted address can't be 0");
        require(seraph.clientProtected(clientid), "Client protection already deactivated");
        address old_address =  clients_to_address[clientid];
        delete address_to_clients[old_address];
        clients_to_address[clientid] = whitelisted_address;
        address_to_clients[whitelisted_address] = clientid;
        if (old_address == address(0)) {
            clients.push(clientid);
        }
        emit ClientAddressAdded( whitelisted_address, clientid);
       
    }


    /**
     * @notice Function intitiate the timelock to remove Seraph
     */
    function removeSeraph() public {
        bytes32 clientid = address_to_clients [msg.sender];
        require(clientid != bytes32(0), "Client not registered");
        require(seraph.clientProtected(clientid), "Client protection already deactivated");
        require(timelocks[clientid].initdate==0 || block.timestamp > timelocks[clientid].finishdate, "Client has already an active timelock");
        Timelock memory tmp_timelock = Timelock(block.timestamp + 120, block.timestamp + 120 + 300);
        timelocks[clientid] = tmp_timelock;
        emit NewSeraphRemovalRequest(msg.sender, clientid);
    }

       /**
     * @notice Function intitiate the timelock to remove Seraph
     */
    function cancelRemoval() public {
        bytes32 clientid = address_to_clients [msg.sender];
        Timelock memory tmp_timelock = timelocks[clientid];
        require(tmp_timelock.initdate != 0, "No timelock");
        timelocks[clientid].initdate = 0;
        timelocks[clientid].finishdate = 0;
        emit cancelledRemovalRequest(msg.sender,clientid);

    }


     /**
     * @notice Function that deactivate Seraph if called between the first 24h to
     * 7 days after the timelock creation
     */
    function executeRemoval() public {
        bytes32 clientid = address_to_clients[msg.sender];
        Timelock memory tmp_timelock = timelocks[clientid];
        require(block.timestamp >= tmp_timelock.initdate && block.timestamp <= tmp_timelock.finishdate, "Timelock times not valid");
        seraph.setClientProtected(clientid,false);
        timelocks[clientid].initdate = 0;
        timelocks[clientid].finishdate = 0;
        emit NewSeraphRemovalExecution(msg.sender,clientid);

    }

    /////////////////////////
    // Getter functions //
    /////////////////////////

    /**
     * @notice Getter that returns the address for a client
     *
     * @param clientId The client identifier to get the contracts from
     * @return The whitelisted address for the client
     */
    function getAddress(bytes32 clientId) external view returns(address) {
        return clients_to_address[clientId];
    }


    /**
     * @notice Getter that returns all the clients id
     *
     * @return All the clientsId
     */
    function getAllClientsIds() external view returns(bytes32[] memory) {
        return clients;
    }


    /**
     * @notice Getter that returns the times of thetimelock for a client
     *
     * @param clientId The client identifier to get the contracts from
     * @return The start and endtime of the timelock
     */
    function getTimelock(bytes32 clientId) external view returns(uint, uint) {
        uint startdate = timelocks[clientId].initdate;
        uint finishdate = timelocks[clientId].finishdate;
        return (startdate, finishdate) ;
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
        require(newWallet != address(0), "State: != 0");
        emit NewAdmin(admin, newWallet);

        admin = newWallet;
    }
}