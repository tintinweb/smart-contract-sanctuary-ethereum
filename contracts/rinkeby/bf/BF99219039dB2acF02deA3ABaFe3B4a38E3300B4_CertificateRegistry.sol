// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "Handler.sol";

contract CertificateRegistry is CertificateHandler {
   constructor(address registrySC) CertificateHandler(registrySC) {}
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "CertificateAuthorization.sol";

contract CertificateHandler is CertificateAuthorization{

    constructor(address registrySC) CertificateAuthorization(registrySC){}
    
    function registerCertificate(
        bytes32 certificate_hash, 
        bytes32 holder_id,
        bytes32 data_address
    )
        public
        grantAccess
        returns (bool success)
    {
        uint256 index = isCertificateExist(certificate_hash, holder_to_certificates[holder_id]);
        if (index-1 > 0) {
            emit IsSuccess(false,"already");
            emit certificateExist(
                true,
                holder_to_certificates[holder_id][index-1]
            );
            return false;
        } else {
            uint256 timestamp = block.timestamp;
            holder_to_certificates[holder_id].push(
            COV_CERTIFICATE(certificate_hash,data_address,msg.sender,timestamp));
            emit IsSuccess(true,"stored");
            emit timestampEvent(timestamp);
            return true;
        }
    }

    function verifyCertificate(bytes32 certificate_hash,bytes32 holder_id) public view returns(bool,COV_CERTIFICATE memory){
        uint256 index = isCertificateExist(certificate_hash, holder_to_certificates[holder_id]);
        if(index-1>0){
            return (true,holder_to_certificates[holder_id][index-1]);
        }
        return (false,holder_to_certificates[holder_id][index-1]);
    }

    function getCertificatesByUser(bytes32 holder_id) 
        public
        view
        returns(COV_CERTIFICATE[] memory certificate_data)
    {
        return holder_to_certificates[holder_id];
    }


}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;
import "Helper.sol";

// this contract provides authorization for certificate smart contract

interface IssuerData {
    function checkIssuerExist(address issuer) external returns (bool);
}

contract CertificateAuthorization is Helper{
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

    function checkSignerIsIssuer(address sender) private returns(bool) {
        return IssuerData(_Registry).checkIssuerExist(sender);
    }

    modifier grantAccess(){
        require(checkSignerIsIssuer(msg.sender) == true);
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "Data.sol";

contract Helper is CertificateData{
   
   event IsSuccess(bool value,string result);
   event isFailed(bool value);
   event certificateExist(
      bool is_exist,
      COV_CERTIFICATE certificate_data
   );
   event getCertificate(
       bool is_exist,
       COV_CERTIFICATE[] certificate_data
   );
   event timestampEvent(
       uint256 timestamp
   );
    //function will return index + 1 if data is present in certificates storage.
   function isCertificateExist(
        bytes32 hash_data,
        COV_CERTIFICATE[] memory arrayCOVTranscript
    ) internal pure returns(uint256){
        for (uint256 i = 0; i < arrayCOVTranscript.length; i++) {
            if (arrayCOVTranscript[i].cov_certificate_identifier == hash_data) {
                return i+1;
            }
        }
        // returning 1 mean not found. Since index will be return with +1 value
        return 1;
    }

    function compareHash(bytes32 certificateHash, string memory payload, bytes32 holderID) internal pure returns(bool){
        bytes32 generated_hash = keccak256(abi.encodePacked(holderID, payload));
        return generated_hash == certificateHash;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract CertificateData {

    struct COV_CERTIFICATE {
        bytes32 cov_certificate_identifier;
        bytes32 certificate_data;
        address issuer;
        uint256 timestamp;
    }
    mapping(bytes32 => COV_CERTIFICATE[]) internal holder_to_certificates;

}