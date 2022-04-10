// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "Handler.sol";

contract Certificate is CertificateHandler {
   constructor(address registrySC) CertificateHandler(registrySC) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "CertificateAuthorization.sol";
import "Helper.sol";

contract CertificateHandler is CertificateAuthorization, Helper {

    constructor(address registrySC) CertificateAuthorization(registrySC){}
    
    function registerCertificate(
        bytes32 certificate_hash, 
        bytes32 holder_id,
        string memory payload,
        bytes32 data_address
    )
        public
        grantAccess
        returns (bool success)
    {
        if (
            isCertificateExist(certificate_hash, holder_to_certificates[holder_id]) > 0
        ) {
            emit IsSuccess(false,"already");
            return false;
        } else {
            if (!compareHash(certificate_hash, payload, holder_id)){
                emit IsSuccess(false,"failhash");
                return false;
            }
            holder_to_certificates[holder_id].push(
            COV_CERTIFICATE(certificate_hash,data_address,block.timestamp,msg.sender));
            emit IsSuccess(true,"stored");
            return true;
        }
    }

    function verifyCertificate(bytes32 certificate_hash,bytes32 holder_id) public returns(bool){
        uint256 index = isCertificateExist(certificate_hash, holder_to_certificates[holder_id]);
        if(index>0){
            emit certificateExist(
                true,
                holder_to_certificates[holder_id][index-1]
            );
            return true;
        }
        emit IsSuccess(true,"verified");
        return false;
    }


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

// this contract provides authorization for certificate smart contract

interface IssuerData {
    function verifyIssuer(address issuer) external returns (bool);
}

contract CertificateAuthorization {
    address private _Registry;
    mapping(address => mapping(uint256 => bool)) internal seenNonces;

    //owner mean the one who deployed this contract
    address payable private owner;

    //constructor will be inherit by child class
    constructor(address registry_sc) {
        owner = payable(msg.sender);
        _Registry = registry_sc;
    }

    //debugging code
    event DebugRegistryAddress(
        address Registry_sc
    );

    //debugging code
    function getRegistryAddress()public view returns(address){
        return _Registry;
    }

    function verifyIssuer(address sender) private returns(bool) {
        return IssuerData(_Registry).verifyIssuer(sender);
    }

    modifier grantAccess(){
        require(verifyIssuer(msg.sender) == true);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "Data.sol";

contract Helper is Data{
   
   event IsSuccess(bool value,string result);
   event isFailed(bool value);
   event certificateExist(
      bool is_exist,
      COV_CERTIFICATE certificate_data
   );
    //function will return index + 1 if data is present in certificates storage.
   function isCertificateExist(
        bytes32 hash_data,
        COV_CERTIFICATE[] memory arrayCOVTranscript
    ) internal pure returns(uint256){
        for (uint256 i = 0; i < arrayCOVTranscript.length; i++) {
            if (arrayCOVTranscript[i].cov_hash == hash_data) {
                return i+1;
            }
        }
        // returning 0 mean not found.
        return 0;
    }

    function compareHash(bytes32 certificateHash, string memory payload, bytes32 holderID) internal view returns(bool){
        bytes32 generated_hash = keccak256(abi.encodePacked(holderID, payload , msg.sender));
        return generated_hash == certificateHash;
    }

    //unused function 
    // function verifySignature(bytes32 holderID,bytes32 certificateHash,bytes memory signature,uint256 nonce) 
    // internal 
    // returns(bool){
    //     // This recreates the message hash that was signed on the client.
    //     bytes32 hash = keccak256(abi.encodePacked(holderID, certificateHash, msg.sender, nonce));
    //     bytes32 messageHash = hash.toEthSignedMessageHash();

    //     // Verify that the message's signer is the owner of the order
    //     address signer = messageHash.recover(signature);
    //     emit CompareHash(signer,msg.sender,hash);
    //     //require(signer == msg.sender);

    //     require(!seenNonces[signer][nonce]);
    //     seenNonces[signer][nonce] = true;  

    //     return true;
    // }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Data {

    struct COV_CERTIFICATE {
        bytes32 cov_hash;
        bytes32 data_address;
        uint256 timestamp;
        address issuer;
    }
    mapping(bytes32 => COV_CERTIFICATE[]) internal holder_to_certificates;

}