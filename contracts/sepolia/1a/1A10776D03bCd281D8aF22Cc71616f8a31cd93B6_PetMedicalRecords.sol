/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

pragma solidity >=0.8.0 <0.9.0;

contract PetMedicalRecords {
    struct Pet {
        string ownerName;
        address ownerAddress;
        string petName;
        string breed;
        uint256 age;
        string gender;
    }

    struct Hospital {
        string name;
        address hospitalAddress;
        string location;
    }

    struct Diagnosis {
        uint256 petId;
        string visitDate;
        string doctorName;
        string affectedArea;
        string diseaseName;
        string treatment;
        string medication;
    }

    struct Payment {
        uint256 totalAmount;
        uint256 consultationFee;
        uint256 medicationCost;
        uint256 otherCosts;
        bool paid;
    }

    mapping(uint256 => Pet) public pets;
    mapping(uint256 => Hospital) public hospitals;
    mapping(uint256 => Diagnosis[]) public medicalRecords;
    mapping(uint256 => Payment) public payments;

    // modifier onlyRegisteredPet(uint256 petId) {
    //     require(pets[petId].ownerAddress == msg.sender, "Only registered pet owners can access this function");
    //     _;
    // }

    modifier onlyOwner(uint256 petId) {
        require(pets[petId].ownerAddress == msg.sender, "Only the owner can access this function");
        _;
    }

    modifier onlyRegisteredHospital(uint256 hospitalId) {
        require(hospitals[hospitalId].hospitalAddress == msg.sender, "Only registered hospitals can access this function");
        _;
    }

    // 寵物註冊功能
    function registerPet(
        uint256 petId,
        string memory ownerName,
        string memory petName,
        string memory breed,
        uint256 age,
        string memory gender,
        address ownerAddress
    ) public {
        Pet memory newPet = Pet(ownerName, ownerAddress, petName, breed, age, gender);
        pets[petId] = newPet;
    }

    // 修改寵物資訊功能
    function updatePetInfo(
        uint256 petId,
        string memory ownerName,
        string memory petName,
        string memory breed,
        uint256 age,
        string memory gender
    ) public onlyOwner(petId) {
        Pet storage pet = pets[petId];
        pet.ownerName = ownerName;
        pet.petName = petName;
        pet.breed = breed;
        pet.age = age;
        pet.gender = gender;
    }

    // 醫院註冊功能
    function registerHospital(
        uint256 hospitalId,
        string memory name,
        address hospitalAddress,
        string memory location
    ) public {
        Hospital memory newHospital = Hospital(name, hospitalAddress, location);
        hospitals[hospitalId] = newHospital;
    }

    // 新增就診紀錄功能
    function addMedicalRecord(
        uint256 petId,
        uint256 hospitalId,
        string memory visitDate,
        string memory doctorName,
        string memory affectedArea,
        string memory diseaseName,
        string memory treatment,
        string memory medication
    ) public onlyRegisteredHospital(hospitalId) {
        Diagnosis memory newDiagnosis = Diagnosis(
            petId,
            visitDate,
            doctorName,
            affectedArea,
            diseaseName,
            treatment,
            medication
        );
        medicalRecords[petId].push(newDiagnosis);
    }

    // 新增收費功能
    function addPayment(
        uint256 petId,
        uint256 hospitalId,
        uint256 totalAmount,
        uint256 consultationFee,
        uint256 medicationCost,
        uint256 otherCosts
    ) public onlyRegisteredHospital(hospitalId) {
        Payment memory newPayment = Payment(totalAmount, consultationFee, medicationCost, otherCosts, false);
        payments[petId] = newPayment;
    }

    // 執行付款功能
    function makePayment(uint256 petId,uint256 hospitalId) public payable{
        Payment storage payment = payments[petId];
        require(payment.paid == false, "Payment has already been made");

        require(msg.value >= payment.totalAmount, "Insufficient payment amount");

        payment.paid = true;

        payable(hospitals[hospitalId].hospitalAddress).transfer(payment.totalAmount);
    }

    // function make_payable(address x) internal pure returns(address payable){
    //     return address(uint160(x));
    // }
    // function pay() public payable {
    //     owner[msg.sender] =owner({
    //         owner :msg.sender ,
    //         owner : msg.value,
    //         ownerTime : now
    //     });
    // }
    // function sendMoney() public onlyOwner(petId) { 
    //     make_payable(hospitals[hospitalId].hospitalAddress).transfer(address(this).balance);
    // }

    // 接收以太幣時觸發的操作
    receive() external payable {}
}