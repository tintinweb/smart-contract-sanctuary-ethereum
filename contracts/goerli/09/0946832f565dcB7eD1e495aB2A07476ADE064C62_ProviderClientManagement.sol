// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

pragma solidity ^0.8.0;

contract ProviderClientManagement {
    
    struct Provider {
        address walletAddress;
        bool exists;
    }
    
    struct Client {
        address walletAddress;
        address provider;
    }
    
    mapping (address => Provider) public providers;
    mapping (address => mapping (address => bool)) public providerClients;
    mapping (address => Client) public clients;
    
    address[] public providerList;
    address[] public clientList;
    
    function addProvider(address _walletAddress) public {
        require(!providers[_walletAddress].exists, "Provider already exists");
        
        providers[_walletAddress] = Provider(_walletAddress, true);
        providerList.push(_walletAddress);
    }
    
    function addClient(address _walletAddress, address _provider) public {
        require(clients[_walletAddress].walletAddress == address(0), "Client already exists");
        require(providers[_provider].exists, "Provider does not exist");
        require(!providerClients[_provider][_walletAddress], "Client already assigned to this provider");
        
        clients[_walletAddress] = Client(_walletAddress, _provider);
        providerClients[_provider][_walletAddress] = true;
        clientList.push(_walletAddress);
    }
    
    function getClientProvider(address _client) public view returns (address) {
        return clients[_client].provider;
    }
    
    function getProviderWallet(address _provider) public view returns (address) {
        return providers[_provider].walletAddress;
    }
    
}