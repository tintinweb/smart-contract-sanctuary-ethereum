/**
 *Submitted for verification at Etherscan.io on 2022-04-07
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

abstract contract OwnerHelper{

    address private owner;

    event logOwnerTransfer(address indexed preOwner, address indexed newOwner);

    modifier onlyOwner{
        require(msg.sender == owner,"not owner");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    function ownerTrnasferOwnership (address _to) onlyOwner public {
        require(_to != address(0x0), "invalid address for _to");
        require(msg.sender != _to,"not possible transfer your ownership to me");
        address preOwner = owner;
        owner = _to;
        emit logOwnerTransfer(preOwner,owner);
    }


}


abstract contract IssuerHelper is OwnerHelper{

    mapping(address => bool) public issuers; // 발행기관

    event logAddIssuer(address indexed _issuer);
    event logDeleteIssuer(address indexed _issuer);

    modifier onlyIssuer{
        require(isIssuer(msg.sender) == true,"not issure");
        _;
    }

    constructor (){
        issuers[msg.sender] = true; // 컨트랙트 발행자는 자동 issuers 입니다.
    }

    function isIssuer(address who) public view returns(bool){
        require(who != address(0x0), "invalid address");
        return issuers[who];
    }

    function addIssuer(address who) onlyOwner public returns(bool){
        require(who != address(0x0),"invalid address");
        require(isIssuer(who) != true,"this address is aleady Issure");
        
        issuers[who] = true;
        
        emit logAddIssuer(who);
        return true;
    }

    function deleteIssuer(address who) onlyOwner public returns(bool){
        require(who != address(0x0), "invalid address");
        require(isIssuer(who) == true, "not Issuer");
        
        issuers[who] = false;
        
        emit logDeleteIssuer(who);
        return true;
    }

}

contract HumanProtectionManager is IssuerHelper{

    uint256 private credentialNumber; // 다음 증명서 발행번호
    mapping(uint256 => string) private certificateType; // 증명서 종류
    uint256[] private registeredCertificate ;
    
    struct Credential{
        uint256 id;                 // 발행번호
        address issuer;             // 발행한 인증기관
        uint256 certificateType;    // 증명서 타입
        string info;                // 세부정보
        uint256 createData;         // 발행일자
    }

    mapping(address=>mapping(uint256=>Credential)) private credentials;     // 각각의 계정들이 가지고있는 증명서들
    mapping(address=>uint8) private credentialCountOfAddress; // 각각의 계쩡이 몇개의 증명서를 들고 있는지 저장하는 변수

    // credential 발행시 로그를 남긴다.
    event logClaimCredential(address indexed inoculator, uint256 indexed credentialType, address indexed issure, uint256 credentialId);

    constructor(){
        credentialNumber = 1; // 맨처음 발행되는 credential 의 발행번호는 1 입니다.

        certificateType[1] = "Flu";
        registeredCertificate.push(1);

        /* TEST SETTING
        certificateType[2] = "Tdap";
        certificateType[3] = "PPSV23";
        certificateType[4] = "PCV13";
        certificateType[5] = "HepA";
        certificateType[6] = "HepB";
        certificateType[7] = "Var";
        certificateType[8] = "MMR";
        certificateType[9] = "HPV";
        certificateType[10] = "HZV";
        certificateType[11] = "MCV4";
        certificateType[12] = "Hib";

        certificateType[13] = "Pfizer";
        certificateType[14] = "Moderna";
        certificateType[15] = "AstraZeneca";
        certificateType[16] = "Janssen";

        for(uint256 i = 2; i<=16 ; i++){registeredCertificate.push(i);}
        */
    }

    event debugValue(uint256 value);

    // 증명서 유형 추가
    function addCertificateType(uint256 certificateTypeNumber, string calldata certificateName) onlyIssuer public returns(bool success){
        require(bytes(certificateType[certificateTypeNumber]).length == 0,"This certificate is already registered");
        certificateType[certificateTypeNumber] = certificateName;
        registeredCertificate.push(certificateTypeNumber);
        success = true;
    }

    // 등록된 모든 증명서유형 가져오기
    function getRegisteredCertificateTypes() public view returns(uint256[] memory){
        return registeredCertificate;
    }

    // 증명서 유형 이름 가져오기
    function getCertificateType(uint256 certificateTypeNumber) public view returns(string memory certificateTypeName){
        certificateTypeName =  certificateType[certificateTypeNumber];
    }

    // 증명서 발행
    function claimCredential (address inoculator, uint256 certificateTypeNumber, string calldata _info) onlyIssuer public returns(bool success){
        require(inoculator != address(0x0), "invalid address of inoculator");
        require(bytes(certificateType[certificateTypeNumber]).length != 0, "invalid certificateType");

        Credential storage credential = credentials[inoculator][credentialCountOfAddress[inoculator]];
        credential.id = credentialNumber;
        credential.issuer = msg.sender;
        credential.certificateType = certificateTypeNumber;
        credential.info = _info;
        credential.createData = block.timestamp;

        emit logClaimCredential(inoculator,certificateTypeNumber, msg.sender, credentialNumber); // 발행 로그

        credentialNumber++;
        credentialCountOfAddress[inoculator] ++;


        return true;
    }

    // 접종자의 특정 증명서 가져오기
    function getCredentialByAddress(address inoculator, uint256 index) public view returns(Credential memory){
        require(inoculator != address(0x0), "invalid address of inoculator");
        require(credentials[inoculator][index].id != 0,"no Credential");
        return credentials[inoculator][index];
    }

    // 접종자의 모든 증명서 가져오기
    /*
    function getCredentialsOfAddress(address inoculator) public view returns (Credential[] memory){
        require(credentialCountOfAddress[inoculator] != 0, "no credentials");
        
        Credential[] memory credentialArr = new Credential[](credentialCountOfAddress[inoculator]); // 계정이 가지고 있는 크리덴셜 개수 만큼 저장할 배열을 만든다.
        
        for(uint256 i = 0 ; i <= credentialCountOfAddress[inoculator] ; i++ ){
            credentialArr[i] = credentials[inoculator][i];
            //credentialArr.push(credentials[inoculator][i]);
        }

        return credentialArr;           
    }
    */

    // 증명서 개수 가져오기
    function getCredentialCountOfAddress(address inoculator) public view returns(uint256 count){
        require(inoculator != address(0x0),"invalid address");
        count = credentialCountOfAddress[inoculator];
    }

    // 증명서 검증
    function checkCredentialValid(address inoculator, uint256 _credentialId) public view returns(bool) {
        require(inoculator != address(0x0), "invalid address of inoculator");
        require(credentialCountOfAddress[inoculator] != 0,"no credential of inoculator");
        
        for(uint256 i = 0; i< credentialCountOfAddress[inoculator]; i++){
            if(credentials[inoculator][i].id == _credentialId){
                return true;
            }
        }

        return false;
    }



}