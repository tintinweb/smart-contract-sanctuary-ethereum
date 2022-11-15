// SPDX-License-Identifier: MIT
pragma solidity >=0.7.3;

contract WorkingCapitalLoan {

    // Variable that maintains
    // owner address
    address private _owner;

    string public contract_version = "1.07";

    string contract_state = "UNSIGNED"; //: Unsigned, SignedByLender, SignedByBorrower, Funded, Late, Default, Closed, Cancelled
    bool isFiat = false;

    uint256 requestedAmount;

    uint256 fundedTotal = 0;
    uint256 withdrawnTotal = 0;
    uint256 interestToRepay = 0;
    uint256 repaidTotal = 0;

    string signatureDataLender;
    string signatureDataBorrower;

    uint256 interestRateBasisPoints;
    string interestCalculationModel;
    uint256 penaltyRateBasisPoints;
    string penaltyCalculationModel;

    string facilitatorDetails;

    string interestDate;
    string effectiveDate;
    string maturityDate;

    address payable lenderEtherAddress;
    address payable borrowerEtherAddress;
    string contractText;

    uint lastInterestCalculationDate;

    constructor(
        bool in_isFiat,
        string memory in_effectiveDate,
        uint256 in_requestedAmount,
        address payable in_lenderEtherAddress,
        address payable in_borrowerEtherAddress,
        string memory in_contractText,
        uint256 in_interestRateBasisPoints,
        string memory in_interestCalculationModel,
        uint256 in_penaltyRateBasisPoints,
        string memory in_penaltyCalculationModel,
        string memory in_facilitatorDetails
    ) {
        isFiat = in_isFiat;
        effectiveDate = in_effectiveDate;
        requestedAmount = in_requestedAmount;
        lenderEtherAddress = in_lenderEtherAddress;
        borrowerEtherAddress = in_borrowerEtherAddress;
        contractText = in_contractText;

        interestRateBasisPoints = in_interestRateBasisPoints;
        interestCalculationModel = in_interestCalculationModel;
        penaltyRateBasisPoints = in_penaltyRateBasisPoints;
        penaltyCalculationModel = in_penaltyCalculationModel;
        facilitatorDetails = in_facilitatorDetails;

        lastInterestCalculationDate = 0;

        _owner = msg.sender;
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return (keccak256(abi.encodePacked((a))) == keccak256(abi.encodePacked((b))));
    }

    function signAsLender(string memory in_signingData) public onlyOwner {
        require(compareStrings(contract_state,"UNSIGNED"));
        contract_state = "SIGNEDBYLENDER";
        signatureDataLender = in_signingData;
    }

    function signAsBorrower(string memory in_signingData) public {
        require(compareStrings(contract_state,"SIGNEDBYLENDER"));
        contract_state = "SIGNEDBYBORROWER";
        signatureDataBorrower = in_signingData;
    }

    //: payable - Receives the ether from the lender (receive() implementation)
    function fund() public payable onlyOwner {
        require(compareStrings(contract_state,"SIGNEDBYBORROWER") || compareStrings(contract_state,"FUNDINGREQUESTED"));
        contract_state = "FUNDED";
        fundedTotal += msg.value;
    }

    function withdraw(uint256 amount) public {
        require(compareStrings(contract_state,"FUNDED") && msg.sender == borrowerEtherAddress);
        contract_state = "ACTIVE";

        withdrawnTotal += amount;
        lenderEtherAddress.transfer(amount);
    }

    function repay() public payable {
        repaidTotal += msg.value;
    }

    function requestFunding() public {
        require(compareStrings(contract_state,"SIGNEDBYBORROWER"));
        contract_state = "FUNDINGREQUESTED";
    }

    function calculate() public onlyOwner {
        //- Calculate interest, set to late automatically
        // DAILY CALC
        require(block.timestamp - lastInterestCalculationDate >  2678399);

        if (compareStrings(interestCalculationModel,"MONTHLY_COMPOUND"))
        {
            interestToRepay += (withdrawnTotal+interestToRepay) * interestRateBasisPoints/1200;
        }

        if (compareStrings(interestCalculationModel,"SIMPLE"))
        {
            interestToRepay += withdrawnTotal * interestRateBasisPoints/100;
        }

        lastInterestCalculationDate = block.timestamp;
    }

    function markDefault() public onlyOwner {
        require(compareStrings(contract_state,"ACTIVE"));
        contract_state = "DEFAULT";
    }

    function cancelDefault() public onlyOwner {
        require(compareStrings(contract_state,"DEFAULT"));
        contract_state = "ACTIVE";
    }

    function finalize() public onlyOwner {
        // pay all the money in this contract back to the back
        lenderEtherAddress.transfer(address(this).balance);
        contract_state = "FINAL";
    }

    function close() public onlyOwner {
        finalize();
        contract_state = "CLOSED"; // Final State
    }

    function cancel() public onlyOwner {
        finalize();
        contract_state = "CANCELLED";
    }

    // - function to send ether to another contract/wallet - generic method to call a function on another contract
    // function call() {}

    // - function to see the current contract balance
    function getBalance() public {}

        // Publicly exposes who is the
    // owner of this contract
    function owner() public view returns (address) {
        return _owner;
    }

    // onlyOwner modifier that validates only
    // if caller of function is contract owner,
    // otherwise not
    modifier onlyOwner() {
        require(isOwner(), "Function accessible only by the owner !!");
        _;
    }

    // function for owners to verify their ownership.
    // Returns true for owners otherwise false
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

}