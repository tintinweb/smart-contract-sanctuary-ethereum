// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

contract MOLOCH_VAULT {
    bytes32 immutable Moloch; receive() external payable {}
    bytes32 immutable hy7UIH;
    bytes32 private immutable hsah;
    mapping(address => bool) public realHacker;

    struct Cabal {
        address payable identity;
        string password;
    }
    string[2] public question;
    Cabal[] private cabals;
    
    
    function initiation(address payable _id, string memory _passW) public returns(bool){
        Cabal[] memory updatedCabal = cabals;
        uint lengthBefore = updatedCabal.length;
        Cabal memory newCabal = Cabal({password: _passW,
                                 identity: _id});
        realCabals.push(newCabal);
        uint lengthAfter = realCabals.length;
        bool initiated = true;
        require(lengthAfter  >= lengthBefore,"None added");
        require(initiated, "Status declined");
        return initiated;
    }
    Cabal[] public realCabals;

    function sendGrant(address payable _grantee) public payable {
        require(Moloch == keccak256(abi.encodePacked(msg.sender)) || realHacker[msg.sender], "Far $rm success!!");
        (bool success,) = _grantee.call{value: 1 wei}("");
        require(success);
    }

    bool savage;
    

    function uhER778(string[3] memory _openSecrete) public payable {
        uint RGDTjhU = address(this).balance;
        require(hsah == keccak256(abi.encode(_openSecrete[0])) && msg.value < 3 gwei, "success"); 
        require(hy7UIH == keccak256(abi.encodePacked(_openSecrete[1],_openSecrete[2])), "Hahahaha!!");
        require(keccak256(abi.encode(_openSecrete[1])) != keccak256(abi.encode(question[0])),"grant awarded!!");
        (bool success,) = payable(msg.sender).call{value: 1 wei}("");
        require(success);
        uint YHUiiFD = address(this).balance;
        require(YHUiiFD - RGDTjhU == 1, "sacrifice your shallow desires" );
        realHacker[msg.sender] = true;
    }


    constructor( string memory molochPass,string[2] memory _b, address payable[3] memory a, string[3] memory _passss)payable {
        /*
        Intelligence. Perhaps Irrelevant;
        All value in string _passss were moloch-encrypted before input as added sec.
        string molochPass is Moloch-hash-algorithm preimage to 3rd value passed in string[3] _passss.
        Moloch-encryption algorithm was used to tweet
        "THE FUTURE OF HUMANITY REQUIRES THE SACRIFICE YOUR SHALLOW DESIRES" 
        On 11/02/2023 via @Kodak_Rome
        Link: "https://twitter.com/Kodak_Rome/status/1624372583310262279?t=_iNw3oWhcMmISeECaDBTTA&s=19"
        */  

        Moloch = keccak256(abi.encodePacked(msg.sender));
        hsah = keccak256(abi.encode(molochPass)); 
        question[0] = _b[0]; question[1] = _b[1];
        hy7UIH = keccak256(abi.encodePacked(question[0],question[1]));

        for(uint256 i = 0; i < a.length; i++) {
    
            Cabal memory aMember = Cabal({password: _passss[i],
                                 identity: a[i]});
            cabals.push(aMember);
        }
    }
}