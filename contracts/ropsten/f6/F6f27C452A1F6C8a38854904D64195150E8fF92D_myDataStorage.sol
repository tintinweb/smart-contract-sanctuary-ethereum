/**
 *Submitted for verification at Etherscan.io on 2022-02-23
*/

pragma solidity ^0.8.11;

contract myDataStorage{
    event updateData(string _oldData, string _newData);
    string private dataStore;

    constructor(string memory _msgdata){
        string memory oldData_= dataStore;
        dataStore = _msgdata;
        emit updateData(oldData_, _msgdata);
    }

    function updateDataStore(string memory _msg) public {
        string memory oldData= dataStore;
        dataStore= _msg;
        emit updateData(oldData, _msg);
    }

    function getDataStore()public view returns(string memory data_){
        return dataStore;
    }
}