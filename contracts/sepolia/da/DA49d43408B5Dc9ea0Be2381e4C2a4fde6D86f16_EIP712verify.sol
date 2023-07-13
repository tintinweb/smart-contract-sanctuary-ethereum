import "./errors/LibSignatureRichErrors.sol";
import "@0x/contracts-utils/contracts/src/v06/errors/LibRichErrorsV06.sol";
import "./types/types.sol";
import "./types/typeSchemas.sol";
import "./types/typeHashHelpers.sol";

pragma solidity >=0.6.5 <0.9.0;
pragma experimental ABIEncoderV2;

contract EIP712verify {

  address owner;

  BureaucratTypes.TransactionType[] public transactionTypes;
  BureaucratTypes.RequiredTransactionSigner[] public requiredTransactionSigners;

  function addTransactionType(BureaucratTypes.TransactionType memory transactionType) public onlyOwner validateTransactionType(transactionType) {
    transactionTypes.push(transactionType);
  }

  function addRequiredTransactionSigner(BureaucratTypes.RequiredTransactionSigner memory requiredTransactionSigner) public onlyOwner validateRequiredTransactionSigner(requiredTransactionSigner) {
    requiredTransactionSigners.push(requiredTransactionSigner);
  }

  function verifyDocumentTransaction(BureaucratTypes.TransactionDocumentWrapper memory transaction, string memory transactionHash, Signature memory signature) public view {
    // To Do...
  }

  function verifyEmployeeTransaction(BureaucratTypes.TransactionEmployeeWrapper memory transaction, string memory transactionHash, Signature memory signature) public view {
    // To Do...
  }

  function verifySalaryCalculationTransaction(BureaucratTypes.TransactionSalaryCalculationWrapper memory transactionHash, string memory txHash, Signature memory signature) public view {
    // To Do...
  }

  function testHashTransactionDocumentWrapper(BureaucratTypes.TransactionDocumentWrapper memory transaction) public pure returns (bytes32){
    return BureaucratTypeHashHelper.hashTransactionDocumentWrapper(transaction);
  }

  modifier onlyOwner(){
      require(msg.sender == owner);
      _;
  }

  modifier validateTransactionType(BureaucratTypes.TransactionType memory transactionType){
    require(true); // Implement later...
    _;
  }

  modifier validateRequiredTransactionSigner(BureaucratTypes.RequiredTransactionSigner memory requiredTransactionSigner){
    require(true); // Implement later...
    _;
  }

  // --------------------------------------------

  using LibRichErrorsV06 for bytes;

  // EIP191 header for EIP712 prefix
  string constant internal EIP191_HEADER = "\x19\x01";

  // EIP712 Domain Name value
  string constant internal EIP712_DOMAIN_NAME = "EIP712verify";

  // EIP712 Domain Version value
  string constant internal EIP712_DOMAIN_VERSION = "1.0.0";
//  uint256 public chainId;

  // TODO: hard code values
  // Hash of the EIP712 Domain Separator Schema
  bytes32 constant internal EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH =
  keccak256(
    "EIP712Domain("
    "string name,"
    "string version,"
    "uint256 chainId,"
    "address verifyingContract"
    ")"
  );

  //    EIP712_DOMAIN_SEPARATOR = keccak256(
  //      abi.encode(
  //        keccak256(
  //          "EIP712Domain("
  //          "string name,"
  //          "string version,"
  //          "uint256 chainId,"
  //          "address verifyingContract"
  //          ")"
  //        ),
  //        keccak256("ZeroEx"),
  //        keccak256("1.0.0"),
  //        chainId,
  //        zeroExAddress
  //      )
  //    );


  // Hash for the EIP712 transaction schema
  bytes32 constant internal EIP712_TRANSACTION_SCHEMA_HASH = keccak256(abi.encodePacked(
      "Transaction(",
      "uint256 salt,",
      "address signerAddress"
      ")"
    ));
  //  bytes32 constant internal EIP712_TRANSACTION_SCHEMA_HASH = 0x212121;

  struct Transaction {
    uint256 salt;           // Arbitrary number to ensure uniqueness of transaction hash.
    address signerAddress;  // Address of transaction signer.
//    bytes data;             // AbiV2 encoded calldata.
  }


  // Hash of the EIP712 Domain Separator data
  // solhint-disable-next-line var-name-mixedcase
  bytes32 public EIP712_DOMAIN_HASH;


  constructor ()
  public
  {
    uint256 chainId;
    assembly {
      chainId := chainid()
    }
    EIP712_DOMAIN_HASH = keccak256(abi.encodePacked(
        EIP712_DOMAIN_SEPARATOR_SCHEMA_HASH,
        keccak256(bytes(EIP712_DOMAIN_NAME)),
        keccak256(bytes(EIP712_DOMAIN_VERSION)),
        chainId,
        uint256(address(this))
      ));

      owner = msg.sender;
  }


  // '\x19Ethereum Signed Message:\n32\x00\x00\x00\x00' in a word.
  uint256 private constant ETH_SIGN_HASH_PREFIX = 0x19457468657265756d205369676e6564204d6573736167653a0a333200000000;
  /// @dev Exclusive upper limit on ECDSA signatures 'R' values.
  ///      The valid range is given by fig (282) of the yellow paper.
  uint256 private constant ECDSA_SIGNATURE_R_LIMIT =
  uint256(0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141);
  /// @dev Exclusive upper limit on ECDSA signatures 'S' values.
  ///      The valid range is given by fig (283) of the yellow paper.
  uint256 private constant ECDSA_SIGNATURE_S_LIMIT = ECDSA_SIGNATURE_R_LIMIT / 2 + 1;

  /// @dev Allowed signature types.
  enum SignatureType {
    ILLEGAL,
    INVALID,
    EIP712,
    ETHSIGN,
    PRESIGNED
  }

  /// @dev Encoded EC signature.
  struct Signature {
    // How to validate the signature.
    SignatureType signatureType;
    // EC Signature data.
    uint8 v;
    // EC Signature data.
    bytes32 r;
    // EC Signature data.
    bytes32 s;
  }

  /// @dev Retrieve the signer of a signature.
  ///      Throws if the signature can't be validated.
  /// @param hash The hash that was signed.
  /// @param signature The signature.
  /// @return recovered The recovered signer address.
//  function getSignerOfHash(bytes32 hash, Signature memory signature) internal pure returns (address recovered) {
  function getSignerOfHash(bytes32 hash, Signature memory signature) public view returns (address recovered) {
    // Ensure this is a signature type that can be validated against a hash.
    _validateHashCompatibleSignature(hash, signature);

    if (signature.signatureType == SignatureType.EIP712) {
      // Signed using EIP712
      recovered = ecrecover(hash, signature.v, signature.r, signature.s);
    } else if (signature.signatureType == SignatureType.ETHSIGN) {
      // Signed using `eth_sign`
      // Need to hash `hash` with "\x19Ethereum Signed Message:\n32" prefix
      // in packed encoding.
      bytes32 ethSignHash;
      assembly {
      // Use scratch space
        mstore(0, ETH_SIGN_HASH_PREFIX) // length of 28 bytes
        mstore(28, hash) // length of 32 bytes
        ethSignHash := keccak256(0, 60)
      }
      recovered = ecrecover(ethSignHash, signature.v, signature.r, signature.s);
    }
    // `recovered` can be null if the signature values are out of range.
    if (recovered == address(0)) {
      LibSignatureRichErrors
      .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.BAD_SIGNATURE_DATA, hash)
      .rrevert();
    }
  }

  /// @dev Validates that a signature is compatible with a hash signee.
  /// @param hash The hash that was signed.
  /// @param signature The signature.
  function _validateHashCompatibleSignature(bytes32 hash, Signature memory signature) public pure {
    // Ensure the r and s are within malleability limits.
    if (uint256(signature.r) >= ECDSA_SIGNATURE_R_LIMIT || uint256(signature.s) >= ECDSA_SIGNATURE_S_LIMIT) {
      LibSignatureRichErrors
      .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.BAD_SIGNATURE_DATA, hash)
      .rrevert();
    }

    // Always illegal signature.
    if (signature.signatureType == SignatureType.ILLEGAL) {
      LibSignatureRichErrors
      .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.ILLEGAL, hash)
      .rrevert();
    }

    // Always invalid.
    if (signature.signatureType == SignatureType.INVALID) {
      LibSignatureRichErrors
      .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.ALWAYS_INVALID, hash)
      .rrevert();
    }

    // If a feature supports pre-signing, it wouldn't use
    // `getSignerOfHash` on a pre-signed order.
    if (signature.signatureType == SignatureType.PRESIGNED) {
      LibSignatureRichErrors
      .SignatureValidationError(LibSignatureRichErrors.SignatureValidationErrorCodes.UNSUPPORTED, hash)
      .rrevert();
    }

    // Solidity should check that the signature type is within enum range for us
    // when abi-decoding.
  }


  // @dev Calculates the EIP712 hash of a transaction using the domain separator of the Bureaucrat contract.
  // @param transaction containing salt, signerAddress, and data.
  // @return EIP712 hash of the transaction with the domain separator of this contract.
  function hashTxWithSeparator(Transaction memory transaction)
  public
  view
  returns (bytes32 transactionHash)
  {
    // Hash the transaction with the domain separator of the contract.
    transactionHash = hashEIP712Message(EIP712_DOMAIN_HASH, hashTransaction(transaction));
    return transactionHash;
  }



  // @dev Calculates EIP712 encoding for a hash struct with a given domain hash.
  // @param eip712DomainHash Hash of the domain domain separator data.
  // @param hashStruct The EIP712 hash struct.
  // @return EIP712 hash applied to the EIP712 Domain.
  function hashEIP712Message(bytes32 eip712DomainHash, bytes32 hashStruct)
  public
  pure
  returns (bytes32 result)
  {
    // Assembly for more efficient computing:
    // keccak256(abi.encodePacked(
    //     EIP191_HEADER,
    //     EIP712_DOMAIN_HASH,
    //     hashStruct
    // ));

    assembly {
    // Load free memory pointer
      let memPtr := mload(64)

      mstore(memPtr, 0x1901000000000000000000000000000000000000000000000000000000000000)  // EIP191 header
      mstore(add(memPtr, 2), eip712DomainHash)                                            // EIP712 domain hash
      mstore(add(memPtr, 34), hashStruct)                                                 // Hash of struct

    // Compute hash
      result := keccak256(memPtr, 66)
    }
    return result;
  }

  // @dev Calculates EIP712 hash of the transaction with no domain separator.
  // @param transaction containing salt, signerAddress, and data.
  // @return EIP712 hash of the transaction with no domain separator.
  function hashTransaction(Transaction memory transaction)
  public
  pure
  returns (bytes32 result)
  {
    bytes32 schemaHash = EIP712_TRANSACTION_SCHEMA_HASH;
//    bytes memory data = transaction.data;
    uint256 salt = transaction.salt;
    address signerAddress = transaction.signerAddress;

    // Assembly for more efficiently computing:
     result = keccak256(abi.encodePacked(
         EIP712_TRANSACTION_SCHEMA_HASH,
         transaction.salt,
         uint256(transaction.signerAddress)
//         keccak256(transaction.data)
     ));

//    assembly {
//    // Compute hash of data
//      let dataHash := keccak256(add(data, 32), mload(data))
//
//    // Load free memory pointer
//      let memPtr := mload(64)
//
//      mstore(memPtr, schemaHash)                                                               // hash of schema
//      mstore(add(memPtr, 32), salt)                                                            // salt
//      mstore(add(memPtr, 64), and(signerAddress, 0xffffffffffffffffffffffffffffffffffffffff))  // signerAddress
//      mstore(add(memPtr, 96), dataHash)                                                        // hash of data
//
//    // Compute hash
//      result := keccak256(memPtr, 128)
//    }
    return result;
  }
}

// SPDX-License-Identifier: Apache-2.0
/*

  Copyright 2020 ZeroEx Intl.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.

*/

pragma solidity ^0.6.5;

library LibRichErrorsV06 {
    // bytes4(keccak256("Error(string)"))
    bytes4 internal constant STANDARD_ERROR_SELECTOR = 0x08c379a0;

    /// @dev ABI encode a standard, string revert error payload.
    ///      This is the same payload that would be included by a `revert(string)`
    ///      solidity statement. It has the function signature `Error(string)`.
    /// @param message The error string.
    /// @return The ABI encoded error.
    function StandardError(string memory message) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(STANDARD_ERROR_SELECTOR, bytes(message));
    }

    /// @dev Reverts an encoded rich revert reason `errorData`.
    /// @param errorData ABI encoded error data.
    function rrevert(bytes memory errorData) internal pure {
        assembly {
            revert(add(errorData, 0x20), mload(errorData))
        }
    }
}

// SPDX-License-Identifier: Apache-2.0
/*
  Copyright 2023 ZeroEx Intl.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
    http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

pragma solidity >=0.4.16 <0.9.0;

library LibSignatureRichErrors {
    enum SignatureValidationErrorCodes {
        ALWAYS_INVALID,
        INVALID_LENGTH,
        UNSUPPORTED,
        ILLEGAL,
        WRONG_SIGNER,
        BAD_SIGNATURE_DATA
    }

    function SignatureValidationError(
        SignatureValidationErrorCodes code,
        bytes32 hash,
        address signerAddress,
        bytes memory signature
    ) internal pure returns (bytes memory) {
        return
            abi.encodeWithSelector(
                bytes4(keccak256("SignatureValidationError(uint8,bytes32,address,bytes)")),
                code,
                hash,
                signerAddress,
                signature
            );
    }

    function SignatureValidationError(
        SignatureValidationErrorCodes code,
        bytes32 hash
    ) internal pure returns (bytes memory) {
        return abi.encodeWithSelector(bytes4(keccak256("SignatureValidationError(uint8,bytes32)")), code, hash);
    }
}

// SPDX-License-Identifier: Apache-2.0

import '../types/types.sol';
import '../types/typeSchemas.sol';

pragma solidity >=0.4.16 <0.9.0;
pragma experimental ABIEncoderV2;

library BureaucratTypeHashHelper {
    function hashTransactionDocumentWrapper(
        BureaucratTypes.TransactionDocumentWrapper memory dataToHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BureaucratTypeSchemas
                        .EIP712_TransactionDocumentWrapper_SCHEMA_HASH,
                    keccak256(bytes(dataToHash.transactionType)),
                    keccak256(bytes(dataToHash.entityType)),
                    keccak256(bytes(dataToHash.created)),
                    hashDocument(dataToHash.data)
                )
            );
    }

    function hashWarehouse(
        BureaucratTypes.Warehouse memory dataToHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BureaucratTypeSchemas.EIP712_Warehouse_SCHEMA_HASH,
                    keccak256(bytes(dataToHash.title))
                )
            );
    }

    function hashDocument(
        BureaucratTypes.Document memory dataToHash
    ) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    BureaucratTypeSchemas.EIP712_Document_SCHEMA_HASH,
                    keccak256(bytes(dataToHash.documentNumber)),
                    keccak256(bytes(dataToHash.documentDate)),
                    keccak256(bytes(dataToHash.deliveryDate)),
                    keccak256(bytes(dataToHash.paymentDate)),
                    keccak256(bytes(dataToHash.calculationDate)),
                    hashWarehouse(dataToHash.inputWarehouse),
                    hashWarehouse(dataToHash.outputWarehouse)
                )
            );
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.4.16 <0.9.0;

library BureaucratTypes {
    struct TransactionType {
        string identifier;
        string name;
    }

    struct RequiredTransactionSigner {
        address signer;
        string transactionIdentifier;
    }

    struct DocumentType {
        string name;
    }

    struct Country {
        string name;
        string code;
    }

    struct City {
        string name;
        string postalCode;
        Country country;
    }

    struct Currency {
        string title;
        string mark;
        string symbol;
    }

    struct Company {
        string name;
        string code;
        string identifier;
        City city;
        string street;
        string streetNumber;
    }

    struct PaymentType {
        string title;
    }

    struct Warehouse {
        string title;
    }

    struct Article {
        string title;
    }

    struct UnitOfMeasure {
        string title;
    }

    struct TaxRate {
        string title;
        uint256 value;
    }

    struct DocumentItem {
        Article article;
        uint256 quantity;
        string invoicePrice;
        string invoiceAmount;
        string margeAmount;
        string procurementPrice;
        string wholesalePrice;
        string sellPrice;
        string discount1;
        string discount2;
        string discount3;
        string wholesaleDiscountPrice;
        string taxRate;
        string taxAmount;
        string cost;
        string excise;
        string levy;
        string customDuty;
        UnitOfMeasure unitOfMeasure;
        TaxRate tax;
    }

    // struct Document {
    //     string documentNumber;
    //     string documentDate;
    //     string deliveryDate;
    //     string paymentDate;
    //     string calculationDate;
    //     Company company;
    //     Currency currency;
    //     string currencyExchangeDate;
    //     string currencyExchangeValue;
    //     Company customer;
    //     PaymentType paymentType;
    //     Warehouse inputWarehouse;
    //     Warehouse outputWarehouse;
    //     string amountWithoutTax;
    //     string taxAmount;
    //     string amount;
    //     string note;
    //     DocumentType documentType;
    //     // DocumentItem[] items;
    // }

    struct Document {
        string documentNumber;
        string documentDate;
        string deliveryDate;
        string paymentDate;
        string calculationDate;
        Warehouse inputWarehouse;
        Warehouse outputWarehouse;
    }

    // Employee

    struct Department {
        string code;
        string title;
    }

    struct WorkContract {
        string workplaceName;
        string workStartDate;
        string isFixedTermContract;
        string workEndDate;
        string otherEmployerName;
        string workTimeHours;
        string grossSalary;
        string personWithDisability;
        string totalVacationDays;
        string notes;
        Currency currency;
    }

    struct Employee {
        string firstName;
        string lastName;
        string personalIdentificationNumber;
        string personalInsuranceNumber;
        string educationCompleted;
        string gender;
        string email;
        string dateOfBirth;
        string permanentResidenceAddress;
        string temporaryResidenceAddress;
        City cityOfWork;
        City permanentResidenceCity;
        City temporaryResidenceCity;
        Department department;
        WorkContract workContract;
        Company company;
    }

    // SalaryCalculation

    struct SalaryPayoutType {
        string mark;
        string title;
    }

    struct SalaryCalculation {
        Employee employee;
        SalaryPayoutType salaryPayoutType;
        string calculationDate;
        string startDate;
        string endDate;
        string payoutDate;
        string isPersonalDeductionIncluded;
        string calculatedBruttoSalaryAmount;
        string bruttoSalaryAmount;
        string salaryWithoutTaxAmount;
        string taxBaseAmount;
        string nonTaxableAmount;
        string previousPayoutAmount;
        string incomeTaxAmount;
        string unpaidLeaveAmount;
        string surTaxAmount;
        string personalDeductionAmount;
        string nettoSalaryAmount;
        string payoutAmount;
        string incomeAmount;
        string totalCostAmount;
        string distraintRate;
        string ordinalNumber;
        string regularBankAccountAmount;
        string notes;
        string hourlyRate;
        string surTaxRate;
        Currency payoutCurrency;
        Currency calculationCurrency;
    }

    // Wrappers

    struct TransactionDocumentWrapper {
        string transactionType;
        string entityType;
        string created;
        Document data;
    }

    struct TransactionEmployeeWrapper {
        string transactionType;
        string entityType;
        string created;
        Employee data;
    }

    struct TransactionSalaryCalculationWrapper {
        string transactionType;
        string entityType;
        string created;
        SalaryCalculation data;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity >=0.4.16 <0.9.0;

library BureaucratTypeSchemas {
    bytes internal constant encodeDocumentType =
        abi.encodePacked('DocumentType(', 'string name', ')');
    bytes32 internal constant EIP712_DocumentType_SCHEMA_HASH =
        keccak256(encodeDocumentType);

    bytes internal constant encodeCountry =
        abi.encodePacked('Country(', 'string name,', 'string code', ')');
    bytes32 internal constant EIP712_Country_SCHEMA_HASH =
        keccak256(encodeCountry);

    bytes internal constant encodeCity =
        abi.encodePacked(
            'City(',
            'string name,',
            'string postalCode,',
            'Country country',
            ')',
            encodeCountry
        );
    bytes32 internal constant EIP712_City_SCHEMA_HASH = keccak256(encodeCity);

    bytes internal constant encodeCurrency =
        abi.encodePacked(
            'Currency(',
            'string title,',
            'string mark,',
            'string symbol',
            ')'
        );
    bytes32 internal constant EIP712_Currency_SCHEMA_HASH =
        keccak256(encodeCurrency);

    bytes internal constant encodeCompany =
        abi.encodePacked(
            'Company(',
            'string name,',
            'string code,',
            'string identifier,',
            'City city,',
            'string street,',
            'string streetNumber',
            ')',
            encodeCity
        );
    bytes32 internal constant EIP712_Company_SCHEMA_HASH =
        keccak256(encodeCompany);

    bytes internal constant encodePaymentType =
        abi.encodePacked('PaymentType(', 'string title', ')');
    bytes32 internal constant EIP712_PaymentType_SCHEMA_HASH =
        keccak256(encodePaymentType);

    bytes internal constant encodeWarehouse =
        abi.encodePacked('Warehouse(', 'string title', ')');
    bytes32 internal constant EIP712_Warehouse_SCHEMA_HASH =
        keccak256(encodeWarehouse);

    bytes internal constant encodeArticle =
        abi.encodePacked('Article(', 'string title', ')');
    bytes32 internal constant EIP712_Article_SCHEMA_HASH =
        keccak256(encodeArticle);

    bytes internal constant encodeUnitOfMeasure =
        abi.encodePacked('UnitOfMeasure(', 'string title', ')');
    bytes32 internal constant EIP712_UnitOfMeasure_SCHEMA_HASH =
        keccak256(encodeUnitOfMeasure);

    bytes internal constant encodeTaxRate =
        abi.encodePacked('TaxRate(', 'string title,', 'uint256 value', ')');
    bytes32 internal constant EIP712_TaxRate_SCHEMA_HASH =
        keccak256(encodeTaxRate);

    bytes internal constant encodeDocumentItem =
        abi.encodePacked(
            'DocumentItem(',
            'Article article,',
            'uint256 quantity,',
            'string invoicePrice,',
            'string invoiceAmount,',
            'string margeAmount,',
            'string procurementPrice,',
            'string wholesalePrice,',
            'string sellPrice,',
            'string discount1,',
            'string discount2,',
            'string discount3,',
            'string wholesaleDiscountPrice,',
            'string taxRate,',
            'string taxAmount,',
            'string cost,',
            'string excise,',
            'string levy,',
            'string customDuty,',
            'UnitOfMeasure unitOfMeasure,',
            'TaxRate tax',
            ')'
        );
    bytes32 internal constant EIP712_DocumentItem_SCHEMA_HASH =
        keccak256(encodeDocumentItem);

    // bytes internal constant encodeDocument =
    //     abi.encodePacked(
    //         'Document(',
    //         'string documentNumber,',
    //         'string documentDate,',
    //         'string deliveryDate,',
    //         'string paymentDate,',
    //         'string calculationDate,',
    //         'Company company,',
    //         'Currency currency,',
    //         'string currencyExchangeDate,',
    //         'string currencyExchangeValue,',
    //         'Company customer,',
    //         'PaymentType paymentType,',
    //         'Warehouse inputWarehouse,',
    //         'Warehouse outputWarehouse,',
    //         'string amountWithoutTax,',
    //         'string taxAmount,',
    //         'string amount,',
    //         'string note,',
    //         'DocumentType documentType',
    //         ')',
    //         encodeArticle,
    //         encodeCity,
    //         encodeCompany,
    //         encodeCountry,
    //         encodeCurrency,
    //         encodeDocumentType,
    //         encodePaymentType,
    //         encodeTaxRate,
    //         encodeUnitOfMeasure,
    //         encodeWarehouse
    //     );

    bytes internal constant encodeDocument =
        abi.encodePacked(
            'Document(',
            'string documentNumber,',
            'string documentDate,',
            'string deliveryDate,',
            'string paymentDate,',
            'string calculationDate,',
            'Warehouse inputWarehouse,',
            'Warehouse outputWarehouse',
            ')',
            encodeWarehouse
        );
    bytes32 internal constant EIP712_Document_SCHEMA_HASH =
        keccak256(encodeDocument);

    bytes internal constant encodeDepartment =
        abi.encodePacked('Department(', 'string code,', 'string title', ')');
    bytes32 internal constant EIP712_Department_SCHEMA_HASH =
        keccak256(encodeDepartment);

    bytes internal constant encodeWorkContract =
        abi.encodePacked(
            'WorkContract(',
            'string workplaceName,',
            'string workStartDate,',
            'string isFixedTermContract,',
            'string workEndDate,',
            'string otherEmployerName,',
            'string workTimeHours,',
            'string grossSalary,',
            'string personWithDisability,',
            'string totalVacationDays,',
            'string notes,',
            'Currency currency',
            ')',
            encodeCurrency
        );
    bytes32 internal constant EIP712_WorkContract_SCHEMA_HASH =
        keccak256(encodeWorkContract);

    bytes internal constant encodeEmployee =
        abi.encodePacked(
            'Employee(',
            'string firstName,',
            'string lastName,',
            'string personalIdentificationNumber,',
            'string personalInsuranceNumber,',
            'string educationCompleted,',
            'string gender,',
            'string email,',
            'string dateOfBirth,',
            'string permanentResidenceAddress,',
            'string temporaryResidenceAddress,',
            'City cityOfWork,',
            'City permanentResidenceCity,',
            'City temporaryResidenceCity,',
            'Department department,',
            'WorkContract workContract,',
            'Company company',
            ')',
            encodeCity,
            encodeCompany,
            encodeCountry,
            encodeCurrency,
            encodeDepartment,
            encodeWorkContract
        );
    bytes32 internal constant EIP712_Employee_SCHEMA_HASH =
        keccak256(encodeEmployee);

    bytes internal constant encodeSalaryPayoutType =
        abi.encodePacked(
            'SalaryPayoutType(',
            'string mark,',
            'string title',
            ')'
        );
    bytes32 internal constant EIP712_SalaryPayoutType_SCHEMA_HASH =
        keccak256(encodeSalaryPayoutType);

    bytes internal constant encodeSalaryCalculation =
        abi.encodePacked(
            'SalaryCalculation(',
            'Employee employee,',
            'SalaryPayoutType salaryPayoutType,',
            'string calculationDate,',
            'string startDate,',
            'string endDate,',
            'string payoutDate,',
            'string isPersonalDeductionIncluded,',
            'string calculatedBruttoSalaryAmount,',
            'string bruttoSalaryAmount,',
            'string salaryWithoutTaxAmount,',
            'string taxBaseAmount,',
            'string nonTaxableAmount,',
            'string previousPayoutAmount,',
            'string incomeTaxAmount,',
            'string unpaidLeaveAmount,',
            'string surTaxAmount,',
            'string personalDeductionAmount,',
            'string nettoSalaryAmount,',
            'string payoutAmount,',
            'string incomeAmount,',
            'string totalCostAmount,',
            'string distraintRate,',
            'string ordinalNumber,',
            'string regularBankAccountAmount,',
            'string notes,',
            'string hourlyRate,',
            'string surTaxRate,',
            'Currency payoutCurrency,',
            'Currency calculationCurrency',
            ')',
            encodeCity,
            encodeCompany,
            encodeCountry,
            encodeCurrency,
            encodeDepartment,
            encodeEmployee,
            encodeSalaryPayoutType,
            encodeWorkContract
        );
    bytes32 internal constant EIP712_SalaryCalculation_SCHEMA_HASH =
        keccak256(encodeSalaryCalculation);

    bytes internal constant encodeTransactionDocumentWrapper =
        abi.encodePacked(
            'TransactionWrapper(',
            'string transactionType,',
            'string entityType,',
            'string created,',
            'Document data',
            ')',
            encodeDocument
        );
    bytes32 internal constant EIP712_TransactionDocumentWrapper_SCHEMA_HASH =
        keccak256(encodeTransactionDocumentWrapper);
}