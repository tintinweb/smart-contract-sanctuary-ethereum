/**
 *Submitted for verification at Etherscan.io on 2022-07-05
*/

//dichiarazione della versione del compiler solidity
pragma solidity ^0.5.12;

//dichiarazione del contratto
contract NotarizzareEticasa {

  //declare the event that will be fired when a file is certified.
  event FileCertificato(address author, string fileHash, uint timestamp, uint fileSize, string fileExtension);

  //declare a structured data that describes a certified file
  struct FileCertificate {
    address author;
    string fileHash;
    uint timestamp;
    uint fileSize;
    string fileExtension;
  }

  // dichiara un oggetto che conterrà il certificato in hash
  mapping (string => FileCertificate) fileCertificatesMap;

  //function that allows users to certify a file
  function certifyFile(uint fileSize, string memory fileHash, string memory fileExtension) public payable {
    FileCertificate memory newFileCertificate = FileCertificate(msg.sender, fileHash, block.timestamp, fileSize, fileExtension);
    fileCertificatesMap[fileHash] = newFileCertificate;
    emit FileCertificato(msg.sender, fileHash, block.timestamp, fileSize, fileExtension);
  }

  //verifica se il file è già stato certificato sulla blockchain
  function verifyFile(string memory fileHash) public view returns (address, string memory, uint, uint, string memory) {
    return (fileCertificatesMap[fileHash].author, fileCertificatesMap[fileHash].fileHash, fileCertificatesMap[fileHash].timestamp, fileCertificatesMap[fileHash].fileSize, fileCertificatesMap[fileHash].fileExtension);
  }


}