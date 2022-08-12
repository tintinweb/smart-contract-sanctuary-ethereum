// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract vault{

// a contract where the owner create grant for a beneficiary;
//allows beneficiary to withdraw only when time elapse;
// allows owner to withdraw before the time elapse;
// get information of a beneficiary;
// amount of ethers in the smart conteact 

// 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
// 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2

// *********** State Variables *********** //
    
    address public owner;


    struct BeneficiaryProperties{
        uint256 amountAllocated;
        address beneficiary;
        uint256 time;
        // bool status;
    }

    // BeneficiaryProperties[] _beneficiaryProperties;
    mapping(uint256 => BeneficiaryProperties) _beneficiaryProperties;
    mapping(address => uint256) _getBeneficiary;

    modifier onlyOwner{
        require(msg.sender == owner, "You are not the owner");
        _;
    }

    uint256 ID = 1;
    uint256[] id;
    BeneficiaryProperties[] public bp;

    modifier hasTimeElapse(uint256 _id){
        BeneficiaryProperties memory BP = _beneficiaryProperties[_id];
        require(block.timestamp >= BP.time, "Tranquilo, you time never reach");
        _;
    }

    constructor(){
        owner = msg.sender;
    }

    // Create the grant give to the beneficiaries
    function createGrant(address _beneficiary, uint256 _time) external payable onlyOwner returns(uint){
        require(msg.value > 0, "You need to have more than zero ethers");
        BeneficiaryProperties storage BP = _beneficiaryProperties[ID];
        BP.time = _time;
        BP.amountAllocated = msg.value;
        BP.beneficiary = _beneficiary;
        uint256 _id = ID;
        id.push(_id);
        bp.push(BP);

        ID++;  //Increment state variable ID

        return _id;
        // 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
        
    }

    // Payable keyword helps to reduce gas

    // Allows Beneficiaries withdraw specific amount from their balance
    function withdrawSpecificAmount(uint256 _id, uint256 _withdrawal) external hasTimeElapse(_id){
        BeneficiaryProperties storage BP = _beneficiaryProperties[_id];

        address user = BP.beneficiary;
        require(user == msg.sender, "You are not a beneficiary for this grant");

        uint256 totalAmount = BP.amountAllocated;
        require(totalAmount > 0, "This beneficiary has no money");
        require(_withdrawal <= totalAmount, "Balance exhausted");
        BP.amountAllocated -= _withdrawal;
        payable(user).transfer(_withdrawal);

    }

    // Allows Beneficiaries withdraw everything in their balance
    function withdrawAmount(uint256 _id) external hasTimeElapse(_id){
        BeneficiaryProperties storage BP = _beneficiaryProperties[_id];

        address user = BP.beneficiary;
        require(user == msg.sender, " You are not a beneficiary for this grant");

        uint256 _amount = BP.amountAllocated;
        require(_amount > 0, "This beneficiary has no money");


        // how to call a function in a function
        uint getBal = getBalance();
        require(getBal >= _amount, "Insufficient fund");

        BP.amountAllocated = 0;
        payable(user).transfer(_amount);
    }   


    function revertGrant(uint256 _id) external onlyOwner{
        BeneficiaryProperties storage BP = _beneficiaryProperties[_id];
        uint256 _amount = BP.amountAllocated;
        BP.amountAllocated = 0;
        payable(owner).transfer(_amount);
    }

    function returnBeneficiaryInfo(uint256 _id) external view returns(BeneficiaryProperties memory BP){
        BP = _beneficiaryProperties[_id];
    }

    function getBalance() public view returns(uint256){
         return address(this).balance;
    }

    function getAllBeneficiary() external view returns(BeneficiaryProperties[] memory _bp){
        uint256[] memory all = id;
        _bp = new BeneficiaryProperties[](all.length); //Empty is default value of beneficiary property

        for(uint256 i = 0; i < all.length; i++){
            _bp[i] = _beneficiaryProperties[all[i]];
        }
    }
}