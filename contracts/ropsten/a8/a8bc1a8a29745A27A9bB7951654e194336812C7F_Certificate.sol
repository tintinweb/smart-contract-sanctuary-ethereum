/**
 *Submitted for verification at Etherscan.io on 2022-02-28
*/

pragma solidity ^0.4.18;

contract Certificate{

    address owner;
    uint256 numCertificateIssued;

    function Certificate() public{
        owner = msg.sender;
        numCertificateIssued = 0;
    }
    
    modifier onlyOwner{
        require(msg.sender == owner);
        _;
    }
    
    struct DocumentBody{
        address issuerAddress;
        string issuerName; //bytes16
        string recipientName; //bytes16
        //bytes16 date;
        string certificate;//bytes32
        uint256 blockNumber;
        bool isused;// judge repeat 

    }

    mapping (string => DocumentBody) documents;


    event DocumentIssued(
        string recipient, 
        string certificate, 
        string certifier
    );

    event issueCount(
        uint count
    );
    
     /**
     * @dev Issues document.
     */
    function issueDocument(string documentId,string recipient, string certificateType, string _certifier)onlyOwner payable public{//} returns (bool) {
        //require(documents[document].issuerAddress == address(0));
        var certificate = documents[documentId];//msg.sender]; 
        certificate.issuerAddress = msg.sender;
        certificate.issuerName = _certifier;
        certificate.recipientName = recipient;
        certificate.certificate = certificateType;
        certificate.blockNumber = block.number;
        certificate.isused = true;
        numCertificateIssued +=1;
        DocumentIssued(recipient, certificateType, _certifier);
        issueCount(numCertificateIssued);

        //return true;
    }

   //event DocumentRevoked(bytes16 recipient);

    /**
     * @dev Revokes existing document and sets the recipient to 0x0.
     */
    function revokeDocument(string documentId, string recipient) public returns (string,string,string,uint256) {
        require(keccak256(documents[documentId].recipientName) == keccak256(recipient));//keccak256 gas cost is low than string comparision
        //documents[document].recipient = address(0);
        delete documents[documentId];
        //DocumentRevoked(recipient);
        numCertificateIssued -=1;
        issueCount(numCertificateIssued);
        return(documents[documentId].issuerName,documents[documentId].recipientName,documents[documentId].certificate,documents[documentId].blockNumber) ;
    }

    function verifyDocument(string documentId, string recipient,string certificateType)view public returns(bool){
        if(keccak256(documents[documentId].recipientName) == keccak256(recipient) &&
        keccak256(documents[documentId].certificate) == keccak256(certificateType)){
            return true;
        }else{
            return false;
        }
    }

    function checkRepeat(string documentId) view public returns(bool){
            return documents[documentId].isused;
    }


    function totalDocument() view public returns(uint256){
        return numCertificateIssued;
    }

}