// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.17;

// import "@ganache/console.log/console.sol";
import "./DigitalTwinContract.sol"; 

contract MasterContract {
    
    event DigitalTwinCreated(TwinInfo twinInfo);
    event ProductTransactionCreated(ProductTransaction productTransaction);

    struct TwinInfo {
        bytes deviceId;
        address deviceAddress;
    }

    struct ProductTransaction {
        bytes productId;
        uint timestamp;
        bytes data;
    }

    uint indexProductTransactions;
    mapping(bytes => address) public devices;
    mapping(uint => ProductTransaction) public productTransactions;

    function createDeviceDigitalTwin(
        bytes memory _deviceId, bytes memory _publicKey
    ) public returns(TwinInfo memory) {
        
        DigitalTwinContract twin = new DigitalTwinContract(_deviceId, _publicKey);
        devices[_deviceId] = address(twin);
        TwinInfo memory twinInfo = TwinInfo(_deviceId, address(twin));

        emit DigitalTwinCreated(twinInfo);
        return twinInfo;
    }

    function createTransaction(
        address _deviceAddress, bytes memory _signature, bytes memory _data
    ) public {
        
        DigitalTwinContract twin = DigitalTwinContract(_deviceAddress);
        twin.createTransaction(_signature, _data);
        
        // TODO extraer productId para guardar o enviar en un parametro nuevo
        
        ProductTransaction memory transaction = ProductTransaction("1", block.timestamp, _data);
        productTransactions[indexProductTransactions] = transaction;
        indexProductTransactions++;

        //console.log("IMPRIMIR PRODUCT TRANSACTION");
        //console.logBytes(transaction.productId);

        emit ProductTransactionCreated(transaction);
    }
}