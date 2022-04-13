/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract DecentralizedLibrary {
    //Variables
    address[] public upLoaders; //Variable to track the addressees that has uploaded
    mapping(address => string[]) public _uploadedCIDS; //Variable to track the uploaded cids of an address

    //FUNCTION 01
    //first upload oooof
    function _upload(string[] memory _cidsToUpload) public {
        _uploadedCIDS[msg.sender] = _cidsToUpload;
        upLoaders.push(msg.sender);
    }

    //FUNCTION 02
    //subsequent uploads
    function _subsequentUpload(string[] memory _newCidsToUpload) public {
        // string[] memory _existingCIDS;
        // _existingCIDS = _getListOfUploadedCIDS(msg.sender);
        string[] memory _updatedCIDS;
        _updatedCIDS = _addTwoArrays(msg.sender, _newCidsToUpload); //helper function 1
        _uploadedCIDS[msg.sender] = _updatedCIDS;
    }

    //FUNCTION 03
    //view all uploads of an address
    function _getListOfUploadedCIDS(address _address)
        public
        view
        returns (string[] memory)
    {
        return _uploadedCIDS[_address];
    }

    //FUNCTION 04
    //share an array of cids with an existing address
    function _shareWithExisting(string[] memory _cidsToShare, address _address)
        public
    {
        // string[] memory _existingCIDS;
        // _existingCIDS = _getListOfUploadedCIDS(_address);
        string[] memory _updatedCIDS;
        _updatedCIDS = _addTwoArrays(_address, _cidsToShare); //helper function 1
        _uploadedCIDS[_address] = _updatedCIDS;
    }

    //FUNCTION 05
    //share an array of cids with a new address
    function _shareWithNew(string[] memory _cidsToShare, address _address)
        public
    {
        upLoaders.push(_address);
        _uploadedCIDS[_address] = _cidsToShare;
    }

    //HELPER FUNCTION 01
    function _addTwoArrays(address _address, string[] memory _newCidsToUpload)
        public
        returns (string[] memory)
    {
        string[] storage _updatedCIDS = _uploadedCIDS[_address]; //create an array that references the existing one in the mapping
        for (uint8 i = 0; i < _newCidsToUpload.length; i += 1) {
            _updatedCIDS.push(_newCidsToUpload[i]); //add the items from the new one to the old one
        }
        return _updatedCIDS; //final array is updated
    }

    //HELPER FUNCTION 02
    //return ether balance of the wallet calling the function
    function viewBalance() public view returns (uint256) {
        return msg.sender.balance;
    }

    //HELPER FUNCTION 03
    //confirm if address is in the mapping
    function isAnUploader(address _address) public view returns (bool) {
        for (uint8 s = 0; s < upLoaders.length; s += 1) {
            if (_address == upLoaders[s]) return (true);
        }
        return (false);
    }
}