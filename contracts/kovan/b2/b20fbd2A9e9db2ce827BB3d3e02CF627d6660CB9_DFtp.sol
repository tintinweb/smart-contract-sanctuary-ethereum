// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DFtp {
    struct Data {
        uint256 id;
        string name;
        string description;
        string hashUrl;
        string category;
        address author;
        bool visible;//public to everyone or private to the sharedPeers
        address[] sharedPeers;
        uint256 createdAt;
    }

    Data[] private myStorage;


    function getNumberOfItems() public view returns (uint256){
        return myStorage.length;
    }

    // upload files to blocks in the EVN
    function addFile(
        uint256 _id,
        string memory _name,
        string memory _description,
        string memory _hashUrl,
        string memory _category,
        bool visible,//public to everyone or private to the sharedPeers
        address[] memory _sharedPeers,
        uint256 _createdAt
    ) public {
        Data memory myData = Data(
            _id,
            _name,
            _description,
            _hashUrl,
            _category,
            msg.sender,
            visible,
            _sharedPeers,
            _createdAt
        );
        //i would save this to my db
        myStorage.push(myData);
    }

    // get all fiels uploaded by an address
    function getAllMyUploadedFiles() public view returns (Data[] memory) {

        Data[] memory result = new Data[](myStorage.length);
        Data[] memory arr = myStorage;
        uint256 k = 0; //result array index
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].author == msg.sender) {
                result[k] = arr[i];
                k++;
            }
        }

        return result;
    }

    // get all public files Visible to an address
    function getAllPublicSharedFiles()
        public view
        returns (Data[] memory)
    {
        Data[] memory result = new Data[](myStorage.length);
        Data[] memory arr = myStorage;
        uint256 k = 0; //result array index
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].author != msg.sender && arr[i].visible ) {
                result[k] = arr[i];
                k++;
            }
        }

        return result;
    }

    // get all private files visible to an address
    function getAllPrivateSharedFiles()
        public view
        returns (Data[] memory)
    {
        Data[] memory result = new Data[](myStorage.length);
        Data[] memory arr = myStorage;
        uint256 k = 0; //result array index
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].author != msg.sender && !arr[i].visible && arr[i].sharedPeers.length > 0) {
                for (uint256 j = 0; j < arr[i].sharedPeers.length; j++) {
                    if (arr[i].sharedPeers[j] == msg.sender) {
                        result[k] = arr[i];
                        k++;
                    }
                }
            }
        }

        return result;
    }

    // Change Visbility of a file
    function changeVisibility(
        uint256 id,
        bool visible
    ) public{
        //we would query our file storage to get the exact file
        Data[] memory arr = myStorage;
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].author == msg.sender && arr[i].id == id)  {
                require(arr[i].visible != visible, "This Visible status is already active" );
                myStorage[i].visible = visible;
            }
        }

    }

    // remove SharedPeers in a file
    function removeSharedPeers(
        uint256 id,
        address[] memory _sharedPeers
    ) public{
        //we would query our file storage to get the exact file
        Data[] memory arr = myStorage;

        uint c = 0;
        
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].author == msg.sender && arr[i].id == id)  {
                address [] memory add = arr[i].sharedPeers;
                address [] memory newAdd = new address[](add.length);
                for(uint j =0; j<_sharedPeers.length; j++ ){
                    address removeItem = _sharedPeers[j];
                    for(uint k=0; k<arr.length; k++){
                        if(add[k] != removeItem){
                            //i would add a new address
                            newAdd[c] = add[k];
                            c++;
                        }
                    }
                    
                    
                }
                
                //Now we add the new array index to the file

                myStorage[i].sharedPeers = newAdd;
            }
        }

    }

    // Add SharedPeers in a file
    function addSharedPeers(
        uint256 _id,
        address[] memory _sharedPeers
    ) public{
        //we would query our file storage to get the exact file
        Data[] memory arr = myStorage;

        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i].author == msg.sender && arr[i].id == _id)  {
                for(uint j =0; j<_sharedPeers.length; j++ ){
                    myStorage[i].sharedPeers.push(_sharedPeers[j]);//we would push in the new addreses inside the file
                }
            }
        }

    }


}