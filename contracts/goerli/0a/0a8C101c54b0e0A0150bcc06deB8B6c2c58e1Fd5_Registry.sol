//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

import "contracts/Agreements.sol";

contract Registry {
    address private immutable owner;
    address private immutable secondaryOwner;
    mapping (string => address) private collection;

    constructor(bytes memory _secondaryOwner) {
        owner = msg.sender;
        secondaryOwner = bytesToAddress(_secondaryOwner);
    }

    modifier ownerOnly(){
        require(msg.sender == owner || msg.sender == secondaryOwner, "Unauthorized");
        _;
    }

    modifier agreementExist(string memory key){
        require(collection[key] != address(0), "Key Don't Exist");
        _;
    }

    modifier agreementDontExist(string memory key){
        require(collection[key] == address(0), "Existing Key");
        _;
    }

    modifier agreementIsNotEmpty(string memory agreement){
        bytes memory _agreement = bytes(agreement);
        require(_agreement.length != 0, "Invalid Agreement");
        _;
    }

    event Updated(string key);

    function bytesToAddress(bytes memory bys) private pure returns (address addr) {
        assembly {
            addr := mload(add(bys, 20))
        } 
    }

    function getAgreement(string memory key) ownerOnly agreementExist(key) public view returns (string memory) {
        Agreement agreement = Agreement(collection[key]);
        return agreement.get();
    }

    function addAgreement(string memory key, string memory agreement) ownerOnly agreementIsNotEmpty(agreement) agreementDontExist(key) public {
        address addr = address(new Agreement(agreement));
        collection[key] = addr;
        emit Updated(key);
    }
}

//SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0 <0.9.0;

contract Agreement {
     string private agreement;

    constructor(string memory _agreement) {
     agreement = _agreement;
    }

    modifier agreementExist(){
        bytes memory _agreement = bytes(agreement);
        require(_agreement.length != 0, "Invalid Agreement");
        _;
    }

    function get() agreementExist public view returns(string memory) {
      return agreement;
    }
}