/**
 *Submitted for verification at Etherscan.io on 2022-07-08
*/

pragma solidity ^0.8.0;

contract Verification {


struct Verified {

    bool verified;
    string Twitter;
    string Name;
    address collectionAdd;
}

uint public verifiedCollectionsCount = 0;
address owner;


mapping (address => Verified) public verifiedCollection;
mapping (uint => Verified) public verifiedCollections;


constructor () {
    owner = msg.sender;
}

modifier onlyOwner {
    if(msg.sender != owner) {
        revert();
    }
     _;
}


function verifyCollection(address nftAdd, string memory twitterAcc, string memory name) external onlyOwner {

verifiedCollection[nftAdd] = Verified({
    verified: true,
    Twitter: twitterAcc,
    Name: name,
    collectionAdd: nftAdd
});
verifiedCollections[verifiedCollectionsCount] = verifiedCollection[nftAdd];
verifiedCollectionsCount++;


}



function giveVerifiedCollections() public view onlyOwner returns(Verified[] memory) {

Verified[] memory verifiedCo = new Verified[](verifiedCollectionsCount);


    for(uint i; i < verifiedCollectionsCount; i++) {
    verifiedCo[i] = verifiedCollections[i];
}  

return verifiedCo;

}


function cancelVerification(address nftAdd, uint _id) public onlyOwner {
    delete verifiedCollection[nftAdd];
    delete verifiedCollections[_id];
}


function isVerified(address nftAdd) public view returns(Verified memory) {
     return verifiedCollection[nftAdd];
}

}