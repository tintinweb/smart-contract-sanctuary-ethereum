/**
 *Submitted for verification at Etherscan.io on 2022-11-16
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

    /**
     * @title Ruhrkraft Smart Contract file
     * @author Ivan
     */
contract TransactionStorage {

    /**
     * @dev Each transaction contains 1 - Hash of the transaction, 2 - Month when it happened, 3 - Year when it happened, 4 - Identification Number for query
     */

    struct Transaction {
        string hash;
        string month;
        int256 year;
        int256 id;
    }
    /**
     * @dev Events are used to emit information every time a function is called to your front-end, in this case we trigger an event, every time a new transaction is saved in the contract. Therefore, you can listen to them and track which transactions have been successfully saved and which failed
     */
    event TransactionLog(
        int256 _year,
        string _month,
        int256 indexed _id,
        string indexed _hash
    );
    /**
     * @dev Example of an array to check whether the Keccak function is working correctly. Used only for testing
     */
    string[] exampleHashArray = ["Hash1","Hash2","Hash3"];
    Transaction[] transaction;

    /**
     * @notice Mapping is used to save gas costs, because arrays are very expensive
     * @dev Here we use nested mapping to return Transaction attributes
     */
    mapping(int256 => mapping(string => string[])) monthlyTransactions;
    mapping(int256 => mapping(string => mapping(string => int256))) id;
    mapping(int256 => mapping(string => mapping(int256 => string))) hash;

     /**
     * @dev This function is used to retrieve all transactions made at specific month
     * @param _year and _month when transactions is made
     * @return a list of all transactions and their total number 
     */
    function getTransactions(int256 _year, string memory _month)
        public
        view
        returns (string[] memory, uint256)
    {
        return (
            monthlyTransactions[_year][_month],
            monthlyTransactions[_year][_month].length
        );
    }
     /**
     * @dev This function is used to retrieve the id of transaction made at specific time by quering its hash
     * @param _year, _month and _hash as input
     * @return the id of the requested transaction 
     */
    function getId(
        int256 _year,
        string memory _month,
        string memory _hash
    ) public view returns (int256) {
        return id[_year][_month][_hash];
    }
     /**
     * @dev This function is used to retrieve the hash of transaction made at specific time by quering its id
     * @param _year, _month and _hash as input
     * @return the hash of the requested transaction 
     */
    function getHash(
        int256 _year,
        string memory _month,
        int256 _id
    ) public view returns (string memory) {
        return hash[_year][_month][_id];
    }
     /**
     * @dev This function is used to save new transactions in the smart contract
     * @param _year, _month, _id and _hash as input will be used to initiate a new trasaction. Afterwards an event will be emitted to inform about its successful execution 
     */
    function setTransactions(
        int256 _year,
        string memory _month,
        int256 _id,
        string memory _hash
    ) public {
        monthlyTransactions[_year][_month].push(_hash);
        id[_year][_month][_hash] = _id;
        hash[_year][_month][_id] = _hash;

        emit TransactionLog(_year, _month, _id, _hash);
    }
     /**
     * @dev This function is used to hash all transactions for a specific year and month
     * @param _year and _month, will be used to get back a list of all transactions for that period and hash them using Keccak256 hashing function
     */
    function hashEntireMonth(int256 _year, string memory _month)
        public
        view
        returns (bytes32)
    {
        string[] memory transactions = monthlyTransactions[_year][_month];

        bytes32 hashed = keccak256(abi.encode(transactions));
        return hashed;
    }
     /**
     * @dev This function is used to test whether the hashing function is working properly
     */
    function exampleHashing() public view returns (bytes32) {
        return keccak256(abi.encode(exampleHashArray));
    }
     /**
     * @dev This function is used if we want to manually hash all transactions for a specific time and period
     * @param _exampleHashArray is an array of hashes which have to input
     * @return Then we return their hashed value
     */
    function manualHashing(string[] memory _exampleHashArray)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_exampleHashArray));
    }
}