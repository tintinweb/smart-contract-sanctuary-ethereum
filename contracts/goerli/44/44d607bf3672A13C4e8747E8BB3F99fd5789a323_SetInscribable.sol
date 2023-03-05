// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;
struct InscribableData {
    mapping(uint256 => mapping(uint256 => Inscription)) inscriptions;
    mapping(uint256 => uint256[]) scribe;
}
struct Inscription {
    string inscription;
    bool inscriptionExists;
    uint256 inscriptix;
}  

error AlreadyInscribed();

library SetInscribable {    
    function script(InscribableData storage self, uint256 inscriptionClass, uint256 tokenId) external {  

        if (self.inscriptions[inscriptionClass][tokenId].inscriptionExists) {
            revert AlreadyInscribed();
        }

        self.inscriptions[inscriptionClass][tokenId].inscriptix = self.scribe[inscriptionClass].length;

        self.scribe[inscriptionClass].push(tokenId);  

        self.inscriptions[inscriptionClass][tokenId].inscriptionExists = true;      
    }  

    function inscribe(InscribableData storage self, uint256 inscriptionClass, string memory inscription, uint256 tokenId) external {
        if ((self.scribe[inscriptionClass].length - 1) > self.inscriptions[inscriptionClass][tokenId].inscriptix) {            
            self.scribe[inscriptionClass][self.inscriptions[inscriptionClass][tokenId].inscriptix] = self.scribe[inscriptionClass][self.scribe[inscriptionClass].length - 1];            
        }
        self.scribe[inscriptionClass].pop();

        delete self.inscriptions[inscriptionClass][tokenId].inscriptix;

        self.inscriptions[inscriptionClass][tokenId].inscription = inscription;
    }

    function findInscription(InscribableData storage self, uint256 inscriptionClass, uint256 tokenId) external view returns (string memory) {
        return self.inscriptions[inscriptionClass][tokenId].inscription;
    }
    function inscriptionExists(InscribableData storage self, uint256 inscriptionClass, uint256 tokenId) external view returns (bool) {
        return self.inscriptions[inscriptionClass][tokenId].inscriptionExists;
    }

}