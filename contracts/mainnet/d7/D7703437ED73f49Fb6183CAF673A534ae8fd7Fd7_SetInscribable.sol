// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
struct InscribableData {
    mapping(uint256 => mapping(uint256 => Inscription)) inscriptions;
    mapping(uint256 => Script[]) scribe;
    mapping(uint256 => bool) canInscribe;
}
struct Script {
    uint256 tokenId;
    string btcAddress;
}
struct Inscription {
    string inscription;
    string btcAddress;
    uint256 inscriptix;
    bool inscriptionRequestExists;
    bool inscriptionRequested;
}  

error AlreadyInscribed();
error AlreadyRequested();

library SetInscribable {    
    function script(InscribableData storage self, uint256 inscriptionClass, uint256 tokenId, string memory btcAddress) public {  

        if (self.inscriptions[inscriptionClass][tokenId].inscriptionRequested) {
            revert AlreadyRequested();
        }

        self.inscriptions[inscriptionClass][tokenId] = Inscription("",btcAddress,self.scribe[inscriptionClass].length,false,true);

        self.scribe[inscriptionClass].push(Script(tokenId,btcAddress));  
    }  

    function inscribe(InscribableData storage self, uint256 inscriptionClass, string memory inscription, uint256 tokenId) public {
        if (self.inscriptions[inscriptionClass][tokenId].inscriptionRequestExists) {
            revert AlreadyInscribed();
        }
        if ((self.scribe[inscriptionClass].length - 1) > self.inscriptions[inscriptionClass][tokenId].inscriptix) {            
            self.scribe[inscriptionClass][self.inscriptions[inscriptionClass][tokenId].inscriptix] = self.scribe[inscriptionClass][self.scribe[inscriptionClass].length - 1];            
        }
        self.scribe[inscriptionClass].pop();

        delete self.inscriptions[inscriptionClass][tokenId].inscriptix;

        self.inscriptions[inscriptionClass][tokenId].inscription = inscription;

        self.inscriptions[inscriptionClass][tokenId].inscriptionRequestExists = true;
    }

    function retrieveRequests(InscribableData storage self, uint256 inscriptionClass) public view returns (Script[] memory) {
        return self.scribe[inscriptionClass];
    }

    function findInscription(InscribableData storage self, uint256 inscriptionClass, uint256 tokenId) public view returns (string memory) {
        return self.inscriptions[inscriptionClass][tokenId].inscription;
    }

    function inscriptionRequestExists(InscribableData storage self, uint256 inscriptionClass, uint256 tokenId) public view returns (bool) {
        return self.inscriptions[inscriptionClass][tokenId].inscriptionRequestExists;
    }

    function inscribable(InscribableData storage self, uint256 inscriptionClass) public view returns (bool) {
        return self.canInscribe[inscriptionClass];
    }

    function setInscribable(InscribableData storage self, uint256 inscriptionClass, bool _canInscribe) public {
        self.canInscribe[inscriptionClass] = _canInscribe;
    }

}