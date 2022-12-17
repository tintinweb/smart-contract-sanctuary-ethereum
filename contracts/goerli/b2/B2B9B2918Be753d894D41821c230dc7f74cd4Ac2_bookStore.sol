pragma solidity ^0.8.15;



contract bookStore{
    // //declaring counters for index of bookData array

    // using Counters for Counters.Counter;
    // Counters.Counter private _bookIds;

    //creating the structure for storing the information about books
    address public owner;

    modifier onlyowner(){
        owner = msg.sender;
        _;
    }

    
    struct bookData {
        string bookName;
        uint256 bookPrice;
        string bookDescription;
        string ipfsLink;
       // uint256 index;
    }

    struct cidToAdd{
        address ownerAddress;
        uint index;
    }

    //a particular owner can own multiple books therefore map of struct array is creating

    mapping(address => bookData[]) public map_ownerToBook;

    //creating a map which will store Cid as the key value and point to a struct havind address, index as its member this will help to change the ownership.

    mapping(string => cidToAdd) public map_cidToOwner;

    //event, so that the front end can fetch the info

    event ownerData(address owner, string bookname, uint bookprice, string bookdescription, string ipfslink);
    event cidevent(string cid,address add,uint index);
    event moneytransfer(address receiver, address sender, uint money, string newIpfsValue, address newCidOwner);

    //function for new Owners
    function setBookData(address _owner,string memory _bookName,uint256 _bookPrice,string memory _bookDescription,string memory _ipfsLink) public {
            
            map_ownerToBook[_owner].push(bookData(_bookName,_bookPrice,_bookDescription,_ipfsLink));

            setCid(_ipfsLink, _owner);
            
            emit ownerData(_owner,_bookName,_bookPrice,_bookDescription,_ipfsLink);
    }

    /*
    * this function will set the map cidToOwner
     */
    function setCid(string memory _cid,address _ownerAddress) public {
        
        map_cidToOwner[_cid].ownerAddress = _ownerAddress;
        
        map_cidToOwner[_cid].index = map_ownerToBook[_ownerAddress].length-1;

        emit cidevent(_cid, // Cid of the book uploaded on ipfs
                      _ownerAddress, // owner of the cid
                      map_cidToOwner[_cid].index // the index of bookStore struct where this book info is added
                    );
    }

    /*
    * This function will handle the ownership transfer of the book using both declared maps
     */

     function handleTransfer(string memory _cid, address _receiver) public{

        address temp_address = map_cidToOwner[_cid].ownerAddress; //getting the owner of this Cid
        uint temp_index = map_cidToOwner[_cid].index; // getting the index where this cid is present in the other mapping

        map_ownerToBook[temp_address][temp_index].ipfsLink = "SOLD";
        map_ownerToBook[_receiver].push(bookData(//This will create a new entry for the buyer in the map_ownerToBook
                                        map_ownerToBook[temp_address][temp_index].bookName,
                                        map_ownerToBook[temp_address][temp_index].bookPrice,
                                        map_ownerToBook[temp_address][temp_index].bookDescription,
                                        _cid));

        setCid(_cid, _receiver);

        emit moneytransfer(_receiver,// cid will be transferred to this address after the ether is paid
                           temp_address,//the owner of the book
                           map_ownerToBook[temp_address][temp_index].bookPrice, //price of the book
                           map_ownerToBook[temp_address][temp_index].ipfsLink, //the cid which is now transferred to the receiver
                           map_cidToOwner[_cid].ownerAddress //new owner of the the cid
                        );
     }

    function sendMoney(string memory _cid,address _receiver) public{
        
        // _to.transfer(amount);//transferring the money to the owner of the book


        handleTransfer(_cid, _receiver); // if balance is ok, then this function will transfer the book cid to the new owner
    }

    function destroy(address apocalypse) public onlyowner {

		selfdestruct(payable(apocalypse));
    }
}