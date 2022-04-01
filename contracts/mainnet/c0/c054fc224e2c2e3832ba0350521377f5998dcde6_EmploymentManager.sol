/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IERC20 {
    function balanceOf(address address_) external view returns (uint256);
    function transfer(address to_, uint256 amount_) external returns (bool);
    function transferFrom(address from_, address to_, uint256 amount_) external;
}

contract EmploymentManager { 

    // On-Chain Trustless Employment. Fun!
    // Created by: 0xInuarashi || https://twitter.com/0xInuarashi || 0xInuarashi#1234

    // Events
    event AgreementCreated(address indexed employer_, address indexed benefactor_,
        address indexed currency_, uint16 totalEpochs_, uint256 paymentPerEpoch_);
    event EmployerSignedEpoch(address indexed employer_, address indexed benefactor_,
        uint256 index_, uint16 employerEpoch_);
    event BenefactorSignedEpoch(address indexed benefactor_, 
        address indexed employer_, uint256 index_, uint16 benefactorEpoch_,
        address currency_, uint256 paymentPerEpoch_);
    event EmployerWithdrewVoidAgreement(address indexed employer_, 
        address indexed benefactor_, uint256 index_, uint16 employerEpoch_,
        uint16 benefactorEpoch_, address currency_, uint256 totalDeposit_,
        uint256 totalPaid_, uint256 remainingBalance_);

    // Structs
    struct Agreement {
        uint32 creationTimestamp; // 4 | 28
        uint16 totalEpochs; // 2 | 26

        address employer; // 20 | 6
        uint32 employerSigned; // 4 | 2
        uint16 employerEpoch; // 2 | 0

        address benefactor; // 20 | 12
        uint32 benefactorSigned; // 4 | 8
        uint16 benefactorEpoch; // 2 | 6

        address currency; // 20 | 12
        
        uint256 totalDeposit; // 32 | 0
        uint256 totalPaid; // 32 | 0
        uint256 paymentPerEpoch; // 32 | 0
    }

    // Constants
    uint32 constant public epochTime = 28 days;
    uint32 constant public cutoffTime = 20 days;

    // Mappings
    mapping(uint256 => Agreement) public indexToAgreement;

    // Enumerable   
    uint256 public indexToAgreementLength;

    // Internal Functions
    function _sendETH(address payable address_, uint256 amount_) internal {
        (bool success, ) = payable(address_).call{value: amount_}("");
        require(success, "Transfer failed");
    }
    function _employerSign(uint256 index_) internal {
        indexToAgreement[index_].employerSigned = uint32(block.timestamp);
        indexToAgreement[index_].employerEpoch++;
    }
    function _benefactorSign(uint256 index_) internal {
        indexToAgreement[index_].benefactorSigned = uint32(block.timestamp);
        indexToAgreement[index_].benefactorEpoch++;
    }

    // Create Employment Agreement
    function createEmploymentAgreement(address payable benefactor_, address currency_,
    uint16 totalEpochs_, uint256 paymentPerEpoch_) external payable {

        require(benefactor_ != address(0),
            "Benefactor cannot be 0x0!");
        
        // Deposit Currency to the Contract
        uint256 _totalPayment = uint256(totalEpochs_) * paymentPerEpoch_;

        if (currency_ == address(0)) { 
            require(msg.value == _totalPayment,
                "Incorrect msg.value sent!");
        }
        else {
            require(IERC20(currency_).balanceOf(msg.sender) >= _totalPayment,
                "You don't own enough ERC20!");

            IERC20(currency_).transferFrom(msg.sender, address(this), _totalPayment);
        }

        // Create Agreement Struct
        indexToAgreement[indexToAgreementLength] = Agreement(
            uint32(block.timestamp),
            totalEpochs_,

            msg.sender,
            0,
            0,

            benefactor_,
            0,
            0,

            currency_,

            _totalPayment,
            0,
            paymentPerEpoch_
        );

        // Increment the Agreement Length Tracker
        indexToAgreementLength++;

        // Emit Event
        emit AgreementCreated(msg.sender, benefactor_, currency_, 
        totalEpochs_, paymentPerEpoch_);
    }

    function employerSignEpoch(uint256 index_) external {
        
        // Initialize Struct into Local Memory
        Agreement memory _Agreement = indexToAgreement[index_];

        // Sender Must be Employer
        require(_Agreement.employer == msg.sender,
            "You are not the employer!");
        // Employer Epoch must be equal to Benefactor Epoch to sign
        require(_Agreement.employerEpoch == _Agreement.benefactorEpoch,
            "Benefactor has not signed the last epoch yet!");
        // There must be remaining epochs
        require(_Agreement.totalEpochs > _Agreement.employerEpoch,
            "No epochs remaining!");
        
        // Calculate Cutoff Time
        // Note: _nextSignStart is calculated from the creationTimestamp
        // in order to keep epochs constant due to inefficiencies in signing time
        uint32 _nextSignStart = _Agreement.creationTimestamp +
            (_Agreement.employerEpoch * epochTime);
        
        // Time of Signing is within bounds
        require( uint32(block.timestamp) >= _nextSignStart,
            "Next Epoch has not started yet!");
        // Time of Signing is not past the cutoff time (15 days)
        require( uint32(block.timestamp) < (_nextSignStart + cutoffTime), 
            "Exceeded cutoff time! Agreement Void!");
        
        // If passes all checks, allow employer to sign.
        _employerSign(index_);
        
        // Emit Event
        emit EmployerSignedEpoch(msg.sender, _Agreement.benefactor, index_,
        _Agreement.employerEpoch);
    }

    function benefactorSignAndClaimEpoch(uint256 index_) external {
        
        // Initialize Struct into Local Memory
        Agreement memory _Agreement = indexToAgreement[index_];

        // Sender Must be Benefactor
        require(_Agreement.benefactor == msg.sender,
            "You are not the benefactor!");
        // Benefactor Epoch must be behind Employer Epoch
        require(_Agreement.employerEpoch > _Agreement.benefactorEpoch,
            "Employer has not signed this epoch yet!");

        // Sign the Agreement
        _benefactorSign(index_);

        // Record the Payment
        indexToAgreement[index_].totalPaid += _Agreement.paymentPerEpoch;

        // Claim the Payment
        if (_Agreement.currency == address(0)) {
            // It is ETH
            _sendETH(payable(msg.sender), _Agreement.paymentPerEpoch);
        }
        else {
            // It is ERC20
            IERC20(_Agreement.currency).transfer(msg.sender, _Agreement.paymentPerEpoch);
        }

        // Emit Event
        emit BenefactorSignedEpoch(msg.sender, _Agreement.employer, index_,
        _Agreement.benefactorEpoch, _Agreement.currency, _Agreement.paymentPerEpoch);
    }

    function employerWithdrawVoidAgreement(uint256 index_) external {

        // Load Struct into Local Memory
        Agreement memory _Agreement = indexToAgreement[index_];

        // Sender Must be Employer
        require(_Agreement.employer == msg.sender,
            "You are not the employer!");
        
        // Calculate Cutoff Time
        // Note: _nextSignStart is calculated from the creationTimestamp
        // in order to keep epochs constant due to inefficiencies in signing time
        uint32 _nextSignStart = _Agreement.creationTimestamp +
            (_Agreement.employerEpoch * epochTime);
        
        // Time of Signing is past the cutoff time (15 days) from _nextSignStart
        require( uint32(block.timestamp) > (_nextSignStart + cutoffTime), 
            "Agreement is still valid!");

        // Calculate Remaining Balance
        uint256 _totalPaid = _Agreement.totalPaid;
        uint256 _remainingBalance = _Agreement.totalDeposit - _Agreement.totalPaid;

        // Record the Payment
        indexToAgreement[index_].totalPaid += _remainingBalance;

        // Claim the Payment
        if (_Agreement.currency == address(0)) {
            // It is ETH
            _sendETH(payable(msg.sender), _remainingBalance);
        }
        else {
            // It is ERC20
            IERC20(_Agreement.currency).transfer(msg.sender, _remainingBalance);
        }

        // Emit Event
        emit EmployerWithdrewVoidAgreement(msg.sender, _Agreement.benefactor, index_,
        _Agreement.employerEpoch, _Agreement.benefactorEpoch, _Agreement.currency,
        _Agreement.totalDeposit, _totalPaid, _remainingBalance);
    }
}