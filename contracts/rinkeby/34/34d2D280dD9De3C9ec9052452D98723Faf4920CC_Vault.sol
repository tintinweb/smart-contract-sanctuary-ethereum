// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract Vault {
    // a contract where the owner create grant for a beneficiary:
    // allows beneficiary to withdraw only when time elapse
    // allows owner to withdraw before time elapse
    // get information of the beneficiary
    // amount of ethers in the smart contract


    //***************** state variables *****************/

    address public owner;

    struct BeneficiaryProperties {
        uint amountAllocated;
        address beneficiary;
        uint time;
        bool status;
    }

    uint ID = 1;

    mapping(uint => BeneficiaryProperties) public _beneficiaryProperties;

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    uint[] id;
    BeneficiaryProperties[] public bp;

    modifier hasTimeElapsed(uint _id) {
        BeneficiaryProperties memory BP = _beneficiaryProperties[_id];
        require(BP.time <= block.timestamp, "time never reach");
        _;
    }

    constructor () {
        owner = msg.sender;
    }

    function createGrant(address _beneficiary, uint _time) external payable onlyOwner returns (uint256 ){
        require(msg.value > 0, "zero ether not allowed");
        BeneficiaryProperties storage BP = _beneficiaryProperties[ID];
        BP.amountAllocated = msg.value;
        BP.beneficiary = _beneficiary;
        BP.time = _time;
        uint _id = ID;

        id.push(_id);
        bp.push(BP);

        ID++; // increment the state variable ID

        return _id;
    }

    function withdrawAmount(uint _id, uint _amount) external payable hasTimeElapsed(_id){
        BeneficiaryProperties storage BP = _beneficiaryProperties[_id];

        address user = BP.beneficiary;
        require(user == msg.sender, "not a beneficiary for a grant");

        uint amount = BP.amountAllocated;

        require(amount > 0, "beneficiary has no money");

        require(amount >= _amount, "Insufficient balance");

        BP.amountAllocated -= _amount;

        payable(user).transfer(_amount);
    }

    // payable keyword reduces gas
    function withdraw(uint _id) external hasTimeElapsed(_id) {
        BeneficiaryProperties storage BP = _beneficiaryProperties[_id];

        address user = BP.beneficiary;
        require(user == msg.sender, "not a beneficiary for a grant!");

        uint _amount = BP.amountAllocated;
        require(_amount > 0, "this beneficiary has no money!");

        // how to call a function in a function
        uint getBal = getBalance();
        require(getBal >= _amount, "Insufficient fund");

        BP.amountAllocated = 0;

        payable(user).transfer(_amount);

    }


    function revertGrant(uint _id) external onlyOwner{
        BeneficiaryProperties storage BP = _beneficiaryProperties[_id];
        
        uint _amount = BP.amountAllocated;
        BP.amountAllocated = 0;

        payable(owner).transfer(_amount);
    }

    function returnBeneficiaryInfo(uint _id) external view returns (BeneficiaryProperties memory BP) {
        BP = _beneficiaryProperties[_id];
    }

    function getBeneficiaryBalance(uint _id) external view returns (uint bal) {
        BeneficiaryProperties memory BP = _beneficiaryProperties[_id];
        bal = BP.amountAllocated;
    }

    function getBalance() public view returns (uint256 bal) {
        bal = address(this).balance;
    }

    function getAllBeneficiary() external view returns(BeneficiaryProperties[] memory _bp) {
        uint[] memory all = id;
        _bp = new BeneficiaryProperties[](all.length); // Empty of default value of beneficiary property

        for(uint i = 0; i < all.length; i++){
            _bp[i] = _beneficiaryProperties[all[i]];
        }
    }
}