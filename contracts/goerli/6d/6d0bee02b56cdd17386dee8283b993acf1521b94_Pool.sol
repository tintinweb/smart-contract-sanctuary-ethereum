// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract Broker {
    address public lender;
    address public storage_provider;

    constructor(address _lender, address _storage_provider) {
        lender = _lender;
        storage_provider = _storage_provider;
    }

    function getLender() public view returns (address) {
        return lender;
    }

    function getStorageProvider() public view returns (address) {
        return storage_provider;
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "./Broker.sol";

contract Pool {
    struct BrokerInfo {
        address lender;
        address storageProvider;
    }

    mapping(address => BrokerInfo) public loans;

    event NewBrokerDeployed(address brokerInfo, address lender, address storageProvider);

    function getBrokerInfo(address _brokerInfo) external view returns (BrokerInfo memory) {
        return loans[_brokerInfo];
    }

    function deployBroker(address _lender, address _storageProvider) external returns (address) {
        Broker b = new Broker(_lender, _storageProvider);
        address new_broker_address = address(b);

        BrokerInfo memory brokerInfo = BrokerInfo(_lender, _storageProvider);

        loans[new_broker_address] = brokerInfo;

        emit NewBrokerDeployed(new_broker_address, _lender, _storageProvider);

        return new_broker_address;
    }
}