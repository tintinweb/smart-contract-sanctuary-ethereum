/**
 *Submitted for verification at Etherscan.io on 2022-11-03
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }
}

// File: @openzeppelin/[email protected]/utils/Context.sol


// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// File: @openzeppelin/[email protected]/access/Ownable.sol


// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;


/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// File: doctor.sol


pragma solidity ^0.8.0;

contract hospital is Ownable  {

    struct  medicalInstitution{
        string nome;
        string email;
        uint256 identificador;
        bool funcionando ;
        mapping(address => bool) activeDoctors;    
    }
    mapping(address => address[]) listDoctor; 
    mapping (address => medicalInstitution)   addressToMedicalInstitution;
    
    function addhospital(string memory nome,address hospitalAddress,string memory email,uint256 numberIdentifier) external onlyOwner{
        require(!InstitutionIsWorking(hospitalAddress));
        addressToMedicalInstitution[hospitalAddress].nome = nome;
        addressToMedicalInstitution[hospitalAddress].email = email;
        addressToMedicalInstitution[hospitalAddress].identificador = numberIdentifier;
        addressToMedicalInstitution[hospitalAddress].funcionando = true;
    }
    function getMedicalInstitution(address  Institution ) public view returns(string memory, string memory ,uint256,bool){
        return( addressToMedicalInstitution[Institution].nome,
        addressToMedicalInstitution[Institution].email,
        addressToMedicalInstitution[Institution].identificador,
        addressToMedicalInstitution[Institution].funcionando) ;
    }
    function getMedicalList(address  Institution)public  view returns(address[] memory){
        //return addressToMedicalInstitution[Institution].listDoctor;
        return listDoctor[Institution];
    }
    function checkDoctor(address Institution,address doctor) public view returns(bool){
        return addressToMedicalInstitution[Institution].activeDoctors[doctor];
    }
    function addDoctor(address doctor) external {
        require(InstitutionIsWorking(msg.sender));
        //addressToMedicalInstitution[doctor].listDoctor.push(doctor);
        listDoctor[msg.sender].push(doctor);
        addressToMedicalInstitution[msg.sender].activeDoctors[doctor]= true;
    }
    function removeDoctor(address doctor) public {
        require(InstitutionIsWorking(msg.sender));
        uint256 indexToremove = getIndexListDoctor(doctor);
        uint256 indexLastElement = listDoctor[msg.sender].length -1;
        listDoctor[msg.sender][indexToremove] = listDoctor[msg.sender][indexLastElement];
        listDoctor[msg.sender].pop();
        addressToMedicalInstitution[msg.sender].activeDoctors[doctor]=false;
        
    }
    function getIndexListDoctor(address doctor) public view  returns(uint256){
        require(InstitutionIsWorking(msg.sender));
        for (uint index = 0; index < listDoctor[msg.sender].length ; index++) {
            if(doctor == listDoctor[msg.sender][index]){
                return index;
            }

        }
        //require(false);
        return listDoctor[msg.sender].length;
        
    }
    function InstitutionIsWorking(address istitution) public view returns (bool) {
        return addressToMedicalInstitution[istitution].funcionando;
    }

}


contract doctorContract{
    hospital public hospitalInstitution;
    struct doctor{
        string name;
        uint NumberIdentifier;
    }
    mapping(address => doctor) public addressToDoctor;
    mapping(address => address[]) public activeHospital;
    constructor (hospital hospitalContract){
        hospitalInstitution = hospitalContract;
    }
    function registerDoctor(string memory name, uint number)external{
        addressToDoctor[msg.sender].name = name;
        addressToDoctor[msg.sender].NumberIdentifier=number;
    }
    
    function associateWithTheHospital(address hospitalAddress) external {
        require(hospitalInstitution.checkDoctor(hospitalAddress,msg.sender)); 
        activeHospital[msg.sender].push(hospitalAddress);   
    }
    function getActiveHospital(address _doctor) external view returns(address[] memory){
        return   activeHospital[_doctor];
    }
}


contract Consultation{
    doctorContract contractDoctor;
    hospital _hospitalContract;
    PatientContract _patientContract;
    constructor (doctorContract _contractDoctor, hospital hospitalContract,PatientContract patientContract){
        contractDoctor = _contractDoctor;
        _hospitalContract = hospitalContract;
        _patientContract = patientContract;
    }

    /* é o primeiro hash de uma consulta gerado pelo 
    numero secreto e a prova de merkle
    */
    mapping(bytes32 => string[]) public _prontuarioMedico;

    enum status {notValid,inValidation,valid,finalize}
    /*struct patient{
        address merkleTree;
    }*/

    struct verificationConsultation{
        bytes32 secretNumberPatientHash;
        uint256 doctorSecretNumber;
        status validConsultation;
    }

    struct medicalAppointment{
        address hospital;
        bool validationByHospital;
        address doctor;
        verificationConsultation verification;
        uint256 Data;
        bytes32 _consultationMerkleTree;
        string _estruturaDaMerkleTree;
        uint256 consultationNumber;
        uint256 consultationBlock;
    }
    mapping(address =>  mapping(uint256 => medicalAppointment)) public consultationInVerification;
    mapping(address => medicalAppointment[]) public consultation;
    mapping (address => uint256 ) public _consultationNumber;
    // address patient => bytes32 MerkleTree info;
    //mapping(address => bytes32) patientMerkleTree;

    function createMedicalConsultation(bytes32 _secretNumberPatientHash,
    address doctor,address _hospital) external {
        require(checkDoctor(doctor,_hospital),"doctor not valid in this hospital");
        require(_patientContract.checkRegister(msg.sender),"you are not registered in the PatientContract");
        _consultationNumber[msg.sender] = _consultationNumber[msg.sender] +1;
        uint256 consultationNumber = _consultationNumber[msg.sender];
        consultationInVerification[msg.sender][consultationNumber].verification.secretNumberPatientHash = _secretNumberPatientHash;
        consultationInVerification[msg.sender][consultationNumber].hospital = _hospital;
        consultationInVerification[msg.sender][consultationNumber].doctor = doctor;
        consultationInVerification[msg.sender][consultationNumber].consultationNumber =consultationNumber;
        consultationInVerification[msg.sender][consultationNumber].consultationBlock = block.number;
    }
    /*function createPatient(bytes32 patientMerkleHash) external{
        patientMerkleTree[msg.sender] =  patientMerkleHash;
    }*/
    function checkDoctor(address doctor, address _hospital) public view returns(bool) {
        return _hospitalContract.checkDoctor(_hospital, doctor);
    }

     function validatingPatientConsultationByHospital(address _patient,address doctor,uint256 consultationNumber)external{
        
        require(checkDoctor(consultationInVerification[_patient][consultationNumber].hospital,msg.sender), "you are not a valid doctor in this hospital");
        require( consultationInVerification[_patient][consultationNumber].hospital == msg.sender, "consuta de outro hospital" ); 
        consultationInVerification[_patient][consultationNumber].validationByHospital = true; 
        
    }

    function validatingPatientConsultationByDoctor(address _patient, uint256 secretNumber,bool MerkleTree,
    uint256 consultationNumber, bytes32 consultationMerkleTree,string memory estruturaDaMerkleTree
    )external{
        require(MerkleTree, "markle tree does not accept");
        require(consultationInVerification[_patient][consultationNumber].validationByHospital, "");
        require( _checkingSecretNumber(_patient,consultationNumber,secretNumber),"secret number does not match the patient's hash");
        require(checkDoctor(msg.sender,consultationInVerification[_patient][consultationNumber].hospital),"you are not a valid doctor in this hospital");
        consultationInVerification[_patient][consultationNumber].verification.doctorSecretNumber = secretNumber; 
        consultationInVerification[_patient][consultationNumber].verification.validConsultation = status.valid ;
        consultationInVerification[_patient][consultationNumber]._consultationMerkleTree = consultationMerkleTree;
         consultationInVerification[_patient][consultationNumber]._estruturaDaMerkleTree = estruturaDaMerkleTree;
        consultation[_patient].push(consultationInVerification[_patient][consultationNumber]);
    }



    function _checkingSecretNumber(address patientAddress,uint consultationNumber,uint secretNumber) internal view returns(bool){
        return _compararBytes32(
            consultationInVerification[patientAddress][consultationNumber].verification.secretNumberPatientHash,
            _hashUint(secretNumber)
        ) ;
    }
    function _hashUint(uint256 number)pure public returns(bytes32){
        //hashTool.calculeHash(
        return keccak256(abi.encodePacked(Strings.toString(number)));
        //return keccak256(abi.encode(number));
    }
    //function _hashUin1(uint256 number)pure public returns(bytes memory ){
    //    return abi.encode(number);
    //}

    function _compararBytes32( bytes32 value1, bytes32 value2) pure internal returns(bool){
        return value1 == value2;
    }

    //todo converter para o ingles 
    // preciso de uma boa tradução de prontuario medico 
    function SetProntuarioMedico(bytes32 passoDoMerkleConsulta, 
    string[] memory hashDoDocumento,
    address hospital
    ) external {
        require(checkDoctor(msg.sender, hospital));
        _prontuarioMedico[passoDoMerkleConsulta] = hashDoDocumento;
    }
   

}

contract PatientContract{
    hospital _hospitalContract;
    constructor(hospital hospitalContract){
        _hospitalContract= hospitalContract;
    }
    struct patientStructure {
        bytes32 merkleTree;
        bool checkMarkle;
        uint256 numero;
    }
    mapping(address => patientStructure) public _patientMerkleTree;
    function registerPatient(bytes32 merkleTree,uint256 numero, address patient) external {
        require(_hospitalContract.InstitutionIsWorking(msg.sender));
        require(!checkRegister(patient));
        _patientMerkleTree[patient].merkleTree = merkleTree;
        _patientMerkleTree[patient].numero = numero;
    }
    function ConfirmPatientHash() external {
        require(!checkRegister(msg.sender));
        require(getPatientMerkleHash(msg.sender) != bytes32(0));
        _patientMerkleTree[msg.sender].checkMarkle= true;
    }
    function getPatientMerkleHash(address patient) public view returns(bytes32){
        return _patientMerkleTree[patient].merkleTree;
    }
    function checkRegister(address patient ) public view returns(bool) {
        return _patientMerkleTree[patient].checkMarkle;
    }
    
}

contract hashTool{

    function transformeToHex(string memory value) public pure returns (bytes memory){
        return abi.encodePacked(value);
    }
    function calculeHash(bytes memory value)public pure returns(bytes32){
        return keccak256(value);
    }
    function calculeHashOfBytes32(bytes32  value1,bytes32  value2)public pure returns(bytes32){
        return keccak256(abi.encodePacked(value1,value2));
    }
    
    function merkleTree(bytes32[] memory value )public pure returns(bytes32){

        require((value.length % 2) == 0, "sua lista precisa ter quantidade par de elementos. Entao adicione ao final da lista 0x0000000000000000000000000000000000000000000000000000000000000000");
            
        uint256 numberOfLoop1 = value.length  ;
        uint256 numberOfLoop2 = numberOfLoop1/2;
        for (uint i=0; (2**i)<numberOfLoop1; i++) {
            for(uint p=0;p<numberOfLoop2; p++ ){
                value[p] = calculeHashOfBytes32(value[p*2],value[(p*2)+1]);
            }
            if(numberOfLoop2 % 2 == 0 ){
                numberOfLoop2 = numberOfLoop2 / 2;
            }
            else {
                value[numberOfLoop2] = bytes32(0);
                numberOfLoop2 = (numberOfLoop2 / 2) +1;
            }    
        }
        return value[0];
    }
    

    function hashList(string[] memory listValue) pure external returns(bytes32[] memory){
        uint tamanhoEntrada = listValue.length;
        bytes32[] memory outputList = new bytes32[](tamanhoEntrada);
        for( uint i= 0 ; i< listValue.length ; i++){
            outputList[i]=calculeHash(transformeToHex(listValue[i]));
        }
        return outputList;
    }

    function RemainderOfDivisionOfTwoHexadecimal(bytes32 value1, bytes32 value2 ) pure public returns (uint256){
        return uint256(value1) % uint256(value2) ;
    }
    function hashOfRemainderOfDivisionOfTwoHexadecimal(bytes32 value1, bytes32 value2)public view returns(bytes32){
        return calculeHash(
            transformeToHex(
                Strings.toString(
                    RemainderOfDivisionOfTwoHexadecimal(value1,value2)
                    )
                )
            );

    }
    function RestoDeDivisaoHexLista(bytes32 Hex,bytes32[] memory registros,uint256[] memory ListaComStrVazia  )
    public view
    returns(
        uint256[] memory
        //uint256
    )
    {
        require(registros.length == ListaComStrVazia.length);
        uint256 divisor = uint256(Hex);

        
        for( uint i= 0 ; i< registros.length ; i++){
            ListaComStrVazia[i] = uint256(registros[i]) % divisor;
        }
        //return 1;
        return ListaComStrVazia;

    }
    function convertHextoDecimal(bytes32 value)public pure returns(uint256){
        return uint256(value);

    }
}