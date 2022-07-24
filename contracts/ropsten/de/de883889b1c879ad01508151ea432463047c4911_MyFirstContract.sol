/**
 *Submitted for verification at Etherscan.io on 2022-07-22
*/

pragma solidity 0.8.7;

// SPDX-License-Identifier: AFL-3.0​
/**​
 * @title MyFirstContract​
 * @dev A rudimentary NFT contract.​
**/
contract MyFirstContract {
    address author; //address of the author’s wallet​
    address owner; //address of the owner’s wallet​
    uint64 fileHash; //Hash on IPFS​

   //Constructor: executed during the contract deployment​
    constructor(uint64 _fileHash) {
        //Set the owner and the author as the wallet which deploy the contract​
        author = msg.sender;
        owner = msg.sender;
        fileHash = _fileHash;
    }

    function giveTo(address _newOwner) public {
        require(owner == msg.sender, "You need to be the current owner to give it");
        owner = _newOwner;
    }


    function getAuthor() public view returns(address){
        return author;
    }


    function getOwner() public view returns(address){
        return owner;
    }

    function getFileHash() public view returns(uint64){
        return fileHash;
    }

}