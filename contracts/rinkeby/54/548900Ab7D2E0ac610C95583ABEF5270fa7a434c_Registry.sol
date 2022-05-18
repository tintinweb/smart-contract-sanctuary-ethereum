// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "IssuerHandler.sol";

contract Registry is IssuerHandler{
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "RegistryAuthorization.sol";

// this contract provides issuer data for registry smart contract

contract IssuerHandler is RegistryAuthorization {
    event IsSuccess(
        bool value,
        bytes32 hashData,
        address issuer,
        string message
    );

    function registerIssuer(address issuer, bytes32 _hashData)
        public
        grantAccess
        returns (bool success)
    {
        if (checkIssuerExist(issuer)) {
            emit IsSuccess(
                false,
                _hashData,
                issuer,
                "allready registered"
            );
            return false;
        }
        issuerMapping[issuer] = _hashData;
        emit IsSuccess(true, _hashData, issuer, "stored");
        return true;
    }

    function checkIssuerExist(address _address) public view returns (bool) {
        return issuerMapping[_address] > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// this contract provides authorization for registry smart contract


contract RegistryAuthorization {

    address payable public owner;
    mapping(address => bool ) internal authorize_user;
    
    mapping (address=>bytes32) issuerMapping;

    constructor() payable {
        owner = payable(msg.sender);
    }

    //grant authorization only for authorize user to perform issuer registration. 
    modifier grantAccess{
        require(msg.sender == owner || authorize_user[msg.sender]);
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