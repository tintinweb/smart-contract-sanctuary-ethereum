/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

//SPDX-License-Identifier: Unlicense

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

contract authorizedUser {
    event userRegistered(address indexed user);
    event userDeregistered(address indexed user);
    
    mapping(address => bool) users;
    
    modifier onlyRegisteredUsers {
        require(users[msg.sender], "You must be an authorized User to send data");
        _;
    }
    
    function registerProducer() public {
        address auser = msg.sender;
        emit userRegistered(auser);
        users[auser] = true;
    }

    function deregisterUser() public {
        address auser = msg.sender;
        emit userDeregistered(auser);
        users[auser] = false;
    }
}

///@notice this is a simple storage contract to add data from MCS to Ethereum blockchain 
contract DataStorage is authorizedUser {

    ///@notice Library counters to increase the number of id every time each data added to blockchain
    using Counters for Counters.Counter;
    Counters.Counter private ID;

    //dataCount to keep internally the number of added data
    uint256 dataCount;

    //owner is the address who has deployed this contract
    address private _owner;

    ///@notice event to notify every part of the smart contract
    event RequestCreated(address from, uint256 id);
    event Add(address from, uint256 id, string data, uint256 timestamp);
    event Transfer(address from, address receiver, uint id, string data, uint256 timestamp);

    ///@notice this is the basic structure to store each part and data to blockchain
    struct DataStore {
        address from;
        uint256 id;
        string data;
        uint256 timestamp;
    }

    DataStore[] datastore;
    mapping(uint256 => uint256) idOfData; ///@dev mapping id to each data storage

    ///@notice this struct is used to record the data transfer
    struct DataTransfer {
        address sender;
        address receiver;
        uint256 id;
        string data;
        uint256 timestamp;
    }

    DataTransfer[] datatransfer;

    struct Requests{
        address request;
        uint256 id;
    }

    Requests[] requests;

    //set the owner
    constructor () {
        _owner = msg.sender;
    }

    ///@dev returns the address of the current owner
    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Caller is not the owner");
        _;
    }

    ///@notice this is the core function to add each data to blockchain using a device or manually from web or mobile app
    function addDataToBlockchain(string memory _data) public onlyRegisteredUsers{
        ID.increment();
        uint256 _id = ID.current();
        uint256 idx = idOfData[_id];
        idx = datastore.length;
        idOfData[_id] = idx;
        dataCount += 1;
        datastore.push(DataStore(msg.sender, _id, _data, block.timestamp));
        emit Add(msg.sender, _id, _data, block.timestamp);
    }

    function request(uint256 _id) public {
        requests.push(Requests({
            request: msg.sender,
            id: _id
        }));
        emit RequestCreated(msg.sender, _id);
    }

    ///@notice when a request appears, the owner can call this function to transfer the data to receiver (requested address)
    function transfer (address _receiver, uint256 _id, string memory _data) public onlyOwner{
        datatransfer.push(DataTransfer(msg.sender, _receiver, _id, _data, block.timestamp));
        for (uint i = 0; i<requests.length; i++){
            if(requests[i].request == _receiver){
                if(requests.length > 1){
                    requests[i] = requests[requests.length-1];
                }
                requests.pop();
                break;
            }
        }
        emit Transfer(msg.sender, _receiver, _id, _data, block.timestamp);
    }

    ///@notice from the web interface, we can call this function to view all stored data
    function getAllDataStore() public view returns (DataStore[] memory) {
        return datastore;
    }

    ///@notice from the web interface, we can call this function to view all transactions
    function getAllDataTransfer() public view returns (DataTransfer[] memory) {
        return datatransfer;
    }

    ///@notice you can see the total count data storage number
    function getDataCount() public view returns (uint256) {
        return dataCount;
    }

    ///@notice see all requested addresses
    function getRequests() public view returns (Requests[] memory) {
        return requests;
    }

    ///@notice you can call this function from UI to view single data using its id
    function getDataByID(uint256 _id) public view returns(address, uint256, string memory, uint256){
        uint256 index = idOfData[_id];
        require(datastore.length > index);
        return (datastore[_id].from, datastore[_id].id, datastore[_id].data, datastore[_id].timestamp);
    }
}