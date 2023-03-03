/**
 *Submitted for verification at Etherscan.io on 2023-03-02
*/

/*
the owner of the contract (EData) can add the addresses of gemeentes to a list.
the owner can remove addresses from the list.
the address also is attached to a description of the gemeente it belongs to.

any address (gemeente) that is in the list can add hashes to the hashlist.
hashes can be invalidated by the original sender of the hash.

the owner can clear the list and remove specific entries from the list.

anyone can get a list of the hashes, and can get the list of addresses (gemeentes).
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.4.16 <0.9.0;
pragma experimental ABIEncoderV2;

contract ListStorage {
    address public owner;
    // we store a hash (bytes32),
    // the sender of the hash,
    // the an array of invalidated (bool) hashes,
    // the timestamp of invalidation
    struct Hash {
        bytes32 hash;
        address sender;
        uint256 timestamp;
        bool[] invalidated;
        uint256 invalidated_timestamp;
    }
    // list of all stored hashes
    Hash[] submittedFiles;

    struct Gemeente {
        address gemeenteAddress;
        string gemeenteNaam;
    }

    // store gemeentes as a hashmap so that lookup is fast
    /*
    {
        0x1234: "Almelo",
        0x5678: "Wierden",
        0x9abc: "Enschede"}
    }
    */
    mapping(address => string) gemeentesNames; // used for getting gemeente name
    Gemeente[] gemeentes; // used for getting all gemeentes

    constructor() {
        owner = msg.sender;
    }

    // modifier for only owner to use
    modifier onlyOwner() {
        require(msg.sender == owner, "caller is not owner");
        _;
    }

    modifier onlyGemeente() {
        require(
            GemeenteGeregistreerd(msg.sender),
            "caller is not a registered gemeente"
        );
        _;
    }

    // return whether a given address is in the list
    function GemeenteGeregistreerd(address gemeenteAddress)
        public
        view
        returns (bool)
    {
        return bytes(gemeentesNames[gemeenteAddress]).length > 0;
    }

    // return the gemeente name for a given address
    function getGemeenteName(address gemeenteAddress)
        public
        view
        returns (string memory)
    {
        return gemeentesNames[gemeenteAddress];
    }

    function getGemeentes() public view returns (Gemeente[] memory) {
        return gemeentes;
    }

    // adding and removing gemeentes from the dict
    function addGemeente(address gemeenteAddress, string memory gemeenteNaam)
        public
        onlyOwner
    {
        // make sure the address is not already in the list
        require(
            !GemeenteGeregistreerd(gemeenteAddress),
            "gemeente is already registered"
        );
        gemeentesNames[gemeenteAddress] = gemeenteNaam;
        gemeentes.push(Gemeente(gemeenteAddress, gemeenteNaam));
    }

    function removeGemeente(address gemeenteAddress) public onlyOwner {
        gemeentesNames[gemeenteAddress] = "";
        for (uint256 i = 0; i < gemeentes.length; i++) {
            if (gemeentes[i].gemeenteAddress == gemeenteAddress) {
                delete gemeentes[i];
                break;
            }
        }
    }

    // function to add a hash to the list
    function addFile(bytes32 hash) public onlyGemeente {
        submittedFiles.push(
            Hash(hash, msg.sender, block.timestamp, new bool[](0), 0)
        );
    }

    // function to get all stored hashes
    function getSubmittedFiles() public view returns (Hash[] memory) {
        return submittedFiles;
    }

    // function to invalidate a hash, only available to the original sender
    // this is done using the index, so that the cost of this function does
    // not increase linearly with the size of the list
    function invalidateSubmission(uint256 index) public {
        require(
            submittedFiles[index].sender == msg.sender,
            "caller is not the original sender"
        );
        submittedFiles[index].invalidated.push(true);
        submittedFiles[index].invalidated_timestamp = block.timestamp;
    }

    function clearSubmissions() public onlyOwner {
        delete submittedFiles;
    }

    // function to remove a specific entry of the list for the owner
    function removeSubmission(uint256 index) public onlyOwner {
        uint256 length = submittedFiles.length;
        submittedFiles[index] = submittedFiles[length - 1];
        submittedFiles.pop();
    }
}