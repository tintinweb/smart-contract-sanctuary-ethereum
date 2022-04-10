// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "IssuerData.sol";

contract Registry is Issuer{
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;


import "RegistryAuthorization.sol";

// this contract provides issuer data for registry smart contract

contract Issuer is RegistryAuthorization {

    event IsSuccess(
        bool value,
        bytes32 hashData,
        address issuer
        );
    
    function registerIssuer (address issuer, bytes32 _hashData) grantAccess public returns(bool success)  {
        issuerMapping[issuer] = _hashData;
        emit IsSuccess(true,_hashData,issuer);
        return true;
    }

    //testing and debugging
    event DebugVerifyIssuer(
        address _address,
        bool result
    );

    function verifyIssuer (address _address) public view returns(bool){
        return issuerMapping[_address]>0;
    }

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// this contract provides authorization for registry smart contract


contract RegistryAuthorization {

    address payable public owner;
    mapping(address => bool ) internal authorize_user;
    
    mapping (address=>bytes32) issuerMapping; //TODO change to ipfs address

    constructor() payable {
        owner = payable(msg.sender);
    }

    //grant authorization only for authorize user to perform issuer registration. 
    modifier grantAccess{
        require(msg.sender == owner || authorize_user[msg.sender]);
        _;
    }

    //grant authorization for issuer.
    modifier grantAccessIssuer {
        require(issuerMapping[msg.sender] > 0);
        _;
    }

    function registerAuthorizeUser(address _address) public grantAccess returns(bool success) {
        if(!(authorize_user[_address]==true)){
            authorize_user[_address] = true;
            return true;
        }else{
            return false;
        }
    }
}