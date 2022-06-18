/**
 *Submitted for verification at Etherscan.io on 2022-06-17
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

 contract signer {
    struct doc {
        string content;
        bytes32 id;
        address initiator;
    }

 constructor() {
    owner = msg.sender;
 }
    address private owner;
    mapping (address => doc) docs;
    mapping (address => address) parties;

    event tosign (address indexed initiator, address indexed cosigner);

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }
    
    function depot(string memory _text, address _dest) public {
        doc memory docum;
        docum.content=_text;
        docum.id=sha256(bytes(_text));
        docum.initiator=msg.sender;
        docs[_dest]=docum;
    }

    function isdepot(address _cosigner) public view returns(string memory) {
        require(docs[_cosigner].initiator!=address(0));
        return docs[_cosigner].content;
    }

    function signit() public {
        if (docs[msg.sender].initiator!=address(0)) {
            doc memory docum;
            docum = docs[msg.sender];
            parties[docum.initiator]=msg.sender;
        }
    }

    function checkinitiator(address _init) public view returns(bool) {
        if (parties[_init]== address(0)) return false;
        if (docs[parties[_init]].initiator!=_init) return false;
        return true;
    }

    function checkcosigner(address _cosigner) public view returns(bool) {
        if (docs[_cosigner].initiator==address(0)) return false;
        if (parties[docs[_cosigner].initiator]!=_cosigner) return false;
        return true;
    }

 
}