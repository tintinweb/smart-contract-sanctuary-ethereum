// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// BokkyPooBah's DateTime Library v1.01
//
// A gas-efficient Solidity date and time library
//
// https://github.com/bokkypoobah/BokkyPooBahsDateTimeLibrary
//
// Tested date range 1970/01/01 to 2345/12/31
//
// Conventions:
// Unit      | Range         | Notes
// :-------- |:-------------:|:-----
// timestamp | >= 0          | Unix timestamp, number of seconds since 1970/01/01 00:00:00 UTC
// year      | 1970 ... 2345 |
// month     | 1 ... 12      |
// day       | 1 ... 31      |
// hour      | 0 ... 23      |
// minute    | 0 ... 59      |
// second    | 0 ... 59      |
// dayOfWeek | 1 ... 7       | 1 = Monday, ..., 7 = Sunday
//
//
// Enjoy. (c) BokkyPooBah / Bok Consulting Pty Ltd 2018-2019. The MIT Licence.
// ----------------------------------------------------------------------------

library BokkyPooBahsDateTimeLibrary {

    uint constant SECONDS_PER_DAY = 24 * 60 * 60;
    uint constant SECONDS_PER_HOUR = 60 * 60;
    uint constant SECONDS_PER_MINUTE = 60;
    int constant OFFSET19700101 = 2440588;

    uint constant DOW_MON = 1;
    uint constant DOW_TUE = 2;
    uint constant DOW_WED = 3;
    uint constant DOW_THU = 4;
    uint constant DOW_FRI = 5;
    uint constant DOW_SAT = 6;
    uint constant DOW_SUN = 7;

    // ------------------------------------------------------------------------
    // Calculate the number of days from 1970/01/01 to year/month/day using
    // the date conversion algorithm from
    //   https://aa.usno.navy.mil/faq/JD_formula.html
    // and subtracting the offset 2440588 so that 1970/01/01 is day 0
    //
    // days = day
    //      - 32075
    //      + 1461 * (year + 4800 + (month - 14) / 12) / 4
    //      + 367 * (month - 2 - (month - 14) / 12 * 12) / 12
    //      - 3 * ((year + 4900 + (month - 14) / 12) / 100) / 4
    //      - offset
    // ------------------------------------------------------------------------
    function _daysFromDate(uint year, uint month, uint day) internal pure returns (uint _days) {
        require(year >= 1970);
        int _year = int(year);
        int _month = int(month);
        int _day = int(day);

        int __days = _day
          - 32075
          + 1461 * (_year + 4800 + (_month - 14) / 12) / 4
          + 367 * (_month - 2 - (_month - 14) / 12 * 12) / 12
          - 3 * ((_year + 4900 + (_month - 14) / 12) / 100) / 4
          - OFFSET19700101;

        _days = uint(__days);
    }

    // ------------------------------------------------------------------------
    // Calculate year/month/day from the number of days since 1970/01/01 using
    // the date conversion algorithm from
    //   http://aa.usno.navy.mil/faq/docs/JD_Formula.php
    // and adding the offset 2440588 so that 1970/01/01 is day 0
    //
    // int L = days + 68569 + offset
    // int N = 4 * L / 146097
    // L = L - (146097 * N + 3) / 4
    // year = 4000 * (L + 1) / 1461001
    // L = L - 1461 * year / 4 + 31
    // month = 80 * L / 2447
    // dd = L - 2447 * month / 80
    // L = month / 11
    // month = month + 2 - 12 * L
    // year = 100 * (N - 49) + year + L
    // ------------------------------------------------------------------------
    function _daysToDate(uint _days) internal pure returns (uint year, uint month, uint day) {
        int __days = int(_days);

        int L = __days + 68569 + OFFSET19700101;
        int N = 4 * L / 146097;
        L = L - (146097 * N + 3) / 4;
        int _year = 4000 * (L + 1) / 1461001;
        L = L - 1461 * _year / 4 + 31;
        int _month = 80 * L / 2447;
        int _day = L - 2447 * _month / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint(_year);
        month = uint(_month);
        day = uint(_day);
    }

    function timestampFromDate(uint year, uint month, uint day) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY;
    }
    function timestampFromDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (uint timestamp) {
        timestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + hour * SECONDS_PER_HOUR + minute * SECONDS_PER_MINUTE + second;
    }
    function timestampToDate(uint timestamp) internal pure returns (uint year, uint month, uint day) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function timestampToDateTime(uint timestamp) internal pure returns (uint year, uint month, uint day, uint hour, uint minute, uint second) {
        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
        secs = secs % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
        second = secs % SECONDS_PER_MINUTE;
    }

    function isValidDate(uint year, uint month, uint day) internal pure returns (bool valid) {
        if (year >= 1970 && month > 0 && month <= 12) {
            uint daysInMonth = _getDaysInMonth(year, month);
            if (day > 0 && day <= daysInMonth) {
                valid = true;
            }
        }
    }
    function isValidDateTime(uint year, uint month, uint day, uint hour, uint minute, uint second) internal pure returns (bool valid) {
        if (isValidDate(year, month, day)) {
            if (hour < 24 && minute < 60 && second < 60) {
                valid = true;
            }
        }
    }
    function isLeapYear(uint timestamp) internal pure returns (bool leapYear) {
        (uint year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        leapYear = _isLeapYear(year);
    }
    function _isLeapYear(uint year) internal pure returns (bool leapYear) {
        leapYear = ((year % 4 == 0) && (year % 100 != 0)) || (year % 400 == 0);
    }
    function isWeekDay(uint timestamp) internal pure returns (bool weekDay) {
        weekDay = getDayOfWeek(timestamp) <= DOW_FRI;
    }
    function isWeekEnd(uint timestamp) internal pure returns (bool weekEnd) {
        weekEnd = getDayOfWeek(timestamp) >= DOW_SAT;
    }
    function getDaysInMonth(uint timestamp) internal pure returns (uint daysInMonth) {
        (uint year, uint month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
        daysInMonth = _getDaysInMonth(year, month);
    }
    function _getDaysInMonth(uint year, uint month) internal pure returns (uint daysInMonth) {
        if (month == 1 || month == 3 || month == 5 || month == 7 || month == 8 || month == 10 || month == 12) {
            daysInMonth = 31;
        } else if (month != 2) {
            daysInMonth = 30;
        } else {
            daysInMonth = _isLeapYear(year) ? 29 : 28;
        }
    }
    // 1 = Monday, 7 = Sunday
    function getDayOfWeek(uint timestamp) internal pure returns (uint dayOfWeek) {
        uint _days = timestamp / SECONDS_PER_DAY;
        dayOfWeek = (_days + 3) % 7 + 1;
    }

    function getYear(uint timestamp) internal pure returns (uint year) {
        (year,,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getMonth(uint timestamp) internal pure returns (uint month) {
        (,month,) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getDay(uint timestamp) internal pure returns (uint day) {
        (,,day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
    function getHour(uint timestamp) internal pure returns (uint hour) {
        uint secs = timestamp % SECONDS_PER_DAY;
        hour = secs / SECONDS_PER_HOUR;
    }
    function getMinute(uint timestamp) internal pure returns (uint minute) {
        uint secs = timestamp % SECONDS_PER_HOUR;
        minute = secs / SECONDS_PER_MINUTE;
    }
    function getSecond(uint timestamp) internal pure returns (uint second) {
        second = timestamp % SECONDS_PER_MINUTE;
    }

    function addYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year += _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        month += _months;
        year += (month - 1) / 12;
        month = (month - 1) % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _days * SECONDS_PER_DAY;
        require(newTimestamp >= timestamp);
    }
    function addHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _hours * SECONDS_PER_HOUR;
        require(newTimestamp >= timestamp);
    }
    function addMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp >= timestamp);
    }
    function addSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp + _seconds;
        require(newTimestamp >= timestamp);
    }

    function subYears(uint timestamp, uint _years) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        year -= _years;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subMonths(uint timestamp, uint _months) internal pure returns (uint newTimestamp) {
        (uint year, uint month, uint day) = _daysToDate(timestamp / SECONDS_PER_DAY);
        uint yearMonth = year * 12 + (month - 1) - _months;
        year = yearMonth / 12;
        month = yearMonth % 12 + 1;
        uint daysInMonth = _getDaysInMonth(year, month);
        if (day > daysInMonth) {
            day = daysInMonth;
        }
        newTimestamp = _daysFromDate(year, month, day) * SECONDS_PER_DAY + timestamp % SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subDays(uint timestamp, uint _days) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _days * SECONDS_PER_DAY;
        require(newTimestamp <= timestamp);
    }
    function subHours(uint timestamp, uint _hours) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _hours * SECONDS_PER_HOUR;
        require(newTimestamp <= timestamp);
    }
    function subMinutes(uint timestamp, uint _minutes) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _minutes * SECONDS_PER_MINUTE;
        require(newTimestamp <= timestamp);
    }
    function subSeconds(uint timestamp, uint _seconds) internal pure returns (uint newTimestamp) {
        newTimestamp = timestamp - _seconds;
        require(newTimestamp <= timestamp);
    }

    function diffYears(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _years) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear,,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear,,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _years = toYear - fromYear;
    }
    function diffMonths(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _months) {
        require(fromTimestamp <= toTimestamp);
        (uint fromYear, uint fromMonth,) = _daysToDate(fromTimestamp / SECONDS_PER_DAY);
        (uint toYear, uint toMonth,) = _daysToDate(toTimestamp / SECONDS_PER_DAY);
        _months = toYear * 12 + toMonth - fromYear * 12 - fromMonth;
    }
    function diffDays(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _days) {
        require(fromTimestamp <= toTimestamp);
        _days = (toTimestamp - fromTimestamp) / SECONDS_PER_DAY;
    }
    function diffHours(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _hours) {
        require(fromTimestamp <= toTimestamp);
        _hours = (toTimestamp - fromTimestamp) / SECONDS_PER_HOUR;
    }
    function diffMinutes(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _minutes) {
        require(fromTimestamp <= toTimestamp);
        _minutes = (toTimestamp - fromTimestamp) / SECONDS_PER_MINUTE;
    }
    function diffSeconds(uint fromTimestamp, uint toTimestamp) internal pure returns (uint _seconds) {
        require(fromTimestamp <= toTimestamp);
        _seconds = toTimestamp - fromTimestamp;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./base/ModuleManager.sol";
import "./base/OwnerManager.sol";
import "./base/FallbackManager.sol";
import "./base/GuardManager.sol";
import "./common/EtherPaymentFallback.sol";
import "./common/Singleton.sol";
import "./common/SignatureDecoder.sol";
import "./common/SecuredTokenTransfer.sol";
import "./common/StorageAccessible.sol";
import "./interfaces/ISignatureValidator.sol";
import "./external/GnosisSafeMath.sol";

/// @title Gnosis Safe - A multisignature wallet with support for confirmations using signed messages based on ERC191.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract GnosisSafe is
    EtherPaymentFallback,
    Singleton,
    ModuleManager,
    OwnerManager,
    SignatureDecoder,
    SecuredTokenTransfer,
    ISignatureValidatorConstants,
    FallbackManager,
    StorageAccessible,
    GuardManager
{
    using GnosisSafeMath for uint256;

    string public constant VERSION = "1.3.0";

    // keccak256(
    //     "EIP712Domain(uint256 chainId,address verifyingContract)"
    // );
    bytes32 private constant DOMAIN_SEPARATOR_TYPEHASH = 0x47e79534a245952e8b16893a336b85a3d9ea9fa8c573f3d803afb92a79469218;

    // keccak256(
    //     "SafeTx(address to,uint256 value,bytes data,uint8 operation,uint256 safeTxGas,uint256 baseGas,uint256 gasPrice,address gasToken,address refundReceiver,uint256 nonce)"
    // );
    bytes32 private constant SAFE_TX_TYPEHASH = 0xbb8310d486368db6bd6f849402fdd73ad53d316b5a4b2644ad6efe0f941286d8;

    event SafeSetup(address indexed initiator, address[] owners, uint256 threshold, address initializer, address fallbackHandler);
    event ApproveHash(bytes32 indexed approvedHash, address indexed owner);
    event SignMsg(bytes32 indexed msgHash);
    event ExecutionFailure(bytes32 txHash, uint256 payment);
    event ExecutionSuccess(bytes32 txHash, uint256 payment);

    uint256 public nonce;
    bytes32 private _deprecatedDomainSeparator;
    // Mapping to keep track of all message hashes that have been approved by ALL REQUIRED owners
    mapping(bytes32 => uint256) public signedMessages;
    // Mapping to keep track of all hashes (message or transaction) that have been approved by ANY owners
    mapping(address => mapping(bytes32 => uint256)) public approvedHashes;

    // This constructor ensures that this contract can only be used as a master copy for Proxy contracts
    constructor() {
        // By setting the threshold it is not possible to call setup anymore,
        // so we create a Safe with 0 owners and threshold 1.
        // This is an unusable Safe, perfect for the singleton
        threshold = 1;
    }

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    /// @param to Contract address for optional delegate call.
    /// @param data Data payload for optional delegate call.
    /// @param fallbackHandler Handler for fallback calls to this contract
    /// @param paymentToken Token that should be used for the payment (0 is ETH)
    /// @param payment Value that should be paid
    /// @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
    function setup(
        address[] calldata _owners,
        uint256 _threshold,
        address to,
        bytes calldata data,
        address fallbackHandler,
        address paymentToken,
        uint256 payment,
        address payable paymentReceiver
    ) external {
        // setupOwners checks if the Threshold is already set, therefore preventing that this method is called twice
        setupOwners(_owners, _threshold);
        if (fallbackHandler != address(0)) internalSetFallbackHandler(fallbackHandler);
        // As setupOwners can only be called if the contract has not been initialized we don't need a check for setupModules
        setupModules(to, data);

        if (payment > 0) {
            // To avoid running into issues with EIP-170 we reuse the handlePayment function (to avoid adjusting code of that has been verified we do not adjust the method itself)
            // baseGas = 0, gasPrice = 1 and gas = payment => amount = (payment + 0) * 1 = payment
            handlePayment(payment, 0, 1, paymentToken, paymentReceiver);
        }
        emit SafeSetup(msg.sender, _owners, _threshold, to, fallbackHandler);
    }

    /// @dev Allows to execute a Safe transaction confirmed by required number of owners and then pays the account that submitted the transaction.
    ///      Note: The fees are always transferred, even if the user transaction fails.
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @param safeTxGas Gas that should be used for the Safe transaction.
    /// @param baseGas Gas costs that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Gas price that should be used for the payment calculation.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param signatures Packed signature data ({bytes32 r}{bytes32 s}{uint8 v})
    function execTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures
    ) public payable virtual returns (bool success) {
        bytes32 txHash;
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            bytes memory txHashData =
                encodeTransactionData(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    // Payment info
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    // Signature info
                    nonce
                );
            // Increase nonce and execute transaction.
            nonce++;
            txHash = keccak256(txHashData);
            checkSignatures(txHash, txHashData, signatures);
        }
        address guard = getGuard();
        {
            if (guard != address(0)) {
                Guard(guard).checkTransaction(
                    // Transaction info
                    to,
                    value,
                    data,
                    operation,
                    safeTxGas,
                    // Payment info
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    // Signature info
                    signatures,
                    msg.sender
                );
            }
        }
        // We require some gas to emit the events (at least 2500) after the execution and some to perform code until the execution (500)
        // We also include the 1/64 in the check that is not send along with a call to counteract potential shortings because of EIP-150
        require(gasleft() >= ((safeTxGas * 64) / 63).max(safeTxGas + 2500) + 500, "GS010");
        // Use scope here to limit variable lifetime and prevent `stack too deep` errors
        {
            uint256 gasUsed = gasleft();
            // If the gasPrice is 0 we assume that nearly all available gas can be used (it is always more than safeTxGas)
            // We only substract 2500 (compared to the 3000 before) to ensure that the amount passed is still higher than safeTxGas
            success = execute(to, value, data, operation, gasPrice == 0 ? (gasleft() - 2500) : safeTxGas);
            gasUsed = gasUsed.sub(gasleft());
            // If no safeTxGas and no gasPrice was set (e.g. both are 0), then the internal tx is required to be successful
            // This makes it possible to use `estimateGas` without issues, as it searches for the minimum gas where the tx doesn't revert
            require(success || safeTxGas != 0 || gasPrice != 0, "GS013");
            // We transfer the calculated tx costs to the tx.origin to avoid sending it to intermediate contracts that have made calls
            uint256 payment = 0;
            if (gasPrice > 0) {
                payment = handlePayment(gasUsed, baseGas, gasPrice, gasToken, refundReceiver);
            }
            if (success) emit ExecutionSuccess(txHash, payment);
            else emit ExecutionFailure(txHash, payment);
        }
        {
            if (guard != address(0)) {
                Guard(guard).checkAfterExecution(txHash, success);
            }
        }
    }

    function handlePayment(
        uint256 gasUsed,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver
    ) private returns (uint256 payment) {
        // solhint-disable-next-line avoid-tx-origin
        address payable receiver = refundReceiver == address(0) ? payable(tx.origin) : refundReceiver;
        if (gasToken == address(0)) {
            // For ETH we will only adjust the gas price to not be higher than the actual used gas price
            payment = gasUsed.add(baseGas).mul(gasPrice < tx.gasprice ? gasPrice : tx.gasprice);
            require(receiver.send(payment), "GS011");
        } else {
            payment = gasUsed.add(baseGas).mul(gasPrice);
            require(transferToken(gasToken, receiver, payment), "GS012");
        }
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param data That should be signed (this is passed to an external validator contract)
     * @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
     */
    function checkSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures
    ) public view {
        // Load threshold to avoid multiple storage loads
        uint256 _threshold = threshold;
        // Check that a threshold is set
        require(_threshold > 0, "GS001");
        checkNSignatures(dataHash, data, signatures, _threshold);
    }

    /**
     * @dev Checks whether the signature provided is valid for the provided data, hash. Will revert otherwise.
     * @param dataHash Hash of the data (could be either a message hash or transaction hash)
     * @param data That should be signed (this is passed to an external validator contract)
     * @param signatures Signature data that should be verified. Can be ECDSA signature, contract signature (EIP-1271) or approved hash.
     * @param requiredSignatures Amount of required valid signatures.
     */
    function checkNSignatures(
        bytes32 dataHash,
        bytes memory data,
        bytes memory signatures,
        uint256 requiredSignatures
    ) public view {
        // Check that the provided signature data is not too short
        require(signatures.length >= requiredSignatures.mul(65), "GS020");
        // There cannot be an owner with address 0.
        address lastOwner = address(0);
        address currentOwner;
        uint8 v;
        bytes32 r;
        bytes32 s;
        uint256 i;
        for (i = 0; i < requiredSignatures; i++) {
            (v, r, s) = signatureSplit(signatures, i);
            if (v == 0) {
                // If v is 0 then it is a contract signature
                // When handling contract signatures the address of the contract is encoded into r
                currentOwner = address(uint160(uint256(r)));

                // Check that signature data pointer (s) is not pointing inside the static part of the signatures bytes
                // This check is not completely accurate, since it is possible that more signatures than the threshold are send.
                // Here we only check that the pointer is not pointing inside the part that is being processed
                require(uint256(s) >= requiredSignatures.mul(65), "GS021");

                // Check that signature data pointer (s) is in bounds (points to the length of data -> 32 bytes)
                require(uint256(s).add(32) <= signatures.length, "GS022");

                // Check if the contract signature is in bounds: start of data is s + 32 and end is start + signature length
                uint256 contractSignatureLen;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    contractSignatureLen := mload(add(add(signatures, s), 0x20))
                }
                require(uint256(s).add(32).add(contractSignatureLen) <= signatures.length, "GS023");

                // Check signature
                bytes memory contractSignature;
                // solhint-disable-next-line no-inline-assembly
                assembly {
                    // The signature data for contract signatures is appended to the concatenated signatures and the offset is stored in s
                    contractSignature := add(add(signatures, s), 0x20)
                }
                require(ISignatureValidator(currentOwner).isValidSignature(data, contractSignature) == EIP1271_MAGIC_VALUE, "GS024");
            } else if (v == 1) {
                // If v is 1 then it is an approved hash
                // When handling approved hashes the address of the approver is encoded into r
                currentOwner = address(uint160(uint256(r)));
                // Hashes are automatically approved by the sender of the message or when they have been pre-approved via a separate transaction
                require(msg.sender == currentOwner || approvedHashes[currentOwner][dataHash] != 0, "GS025");
            } else if (v > 30) {
                // If v > 30 then default va (27,28) has been adjusted for eth_sign flow
                // To support eth_sign and similar we adjust v and hash the messageHash with the Ethereum message prefix before applying ecrecover
                currentOwner = ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)), v - 4, r, s);
            } else {
                // Default is the ecrecover flow with the provided data hash
                // Use ecrecover with the messageHash for EOA signatures
                currentOwner = ecrecover(dataHash, v, r, s);
            }
            require(currentOwner > lastOwner && owners[currentOwner] != address(0) && currentOwner != SENTINEL_OWNERS, "GS026");
            lastOwner = currentOwner;
        }
    }

    /// @dev Allows to estimate a Safe transaction.
    ///      This method is only meant for estimation purpose, therefore the call will always revert and encode the result in the revert data.
    ///      Since the `estimateGas` function includes refunds, call this method to get an estimated of the costs that are deducted from the safe with `execTransaction`
    /// @param to Destination address of Safe transaction.
    /// @param value Ether value of Safe transaction.
    /// @param data Data payload of Safe transaction.
    /// @param operation Operation type of Safe transaction.
    /// @return Estimate without refunds and overhead fees (base transaction and payload data gas costs).
    /// @notice Deprecated in favor of common/StorageAccessible.sol and will be removed in next version.
    function requiredTxGas(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation
    ) external returns (uint256) {
        uint256 startGas = gasleft();
        // We don't provide an error message here, as we use it to return the estimate
        require(execute(to, value, data, operation, gasleft()));
        uint256 requiredGas = startGas - gasleft();
        // Convert response to string and return via error message
        revert(string(abi.encodePacked(requiredGas)));
    }

    /**
     * @dev Marks a hash as approved. This can be used to validate a hash that is used by a signature.
     * @param hashToApprove The hash that should be marked as approved for signatures that are verified by this contract.
     */
    function approveHash(bytes32 hashToApprove) external {
        require(owners[msg.sender] != address(0), "GS030");
        approvedHashes[msg.sender][hashToApprove] = 1;
        emit ApproveHash(hashToApprove, msg.sender);
    }

    /// @dev Returns the chain id used by this contract.
    function getChainId() public view returns (uint256) {
        uint256 id;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            id := chainid()
        }
        return id;
    }

    function domainSeparator() public view returns (bytes32) {
        return keccak256(abi.encode(DOMAIN_SEPARATOR_TYPEHASH, getChainId(), this));
    }

    /// @dev Returns the bytes that are hashed to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Gas that should be used for the safe transaction.
    /// @param baseGas Gas costs for that are independent of the transaction execution(e.g. base transaction fee, signature check, payment of the refund)
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash bytes.
    function encodeTransactionData(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes memory) {
        bytes32 safeTxHash =
            keccak256(
                abi.encode(
                    SAFE_TX_TYPEHASH,
                    to,
                    value,
                    keccak256(data),
                    operation,
                    safeTxGas,
                    baseGas,
                    gasPrice,
                    gasToken,
                    refundReceiver,
                    _nonce
                )
            );
        return abi.encodePacked(bytes1(0x19), bytes1(0x01), domainSeparator(), safeTxHash);
    }

    /// @dev Returns hash to be signed by owners.
    /// @param to Destination address.
    /// @param value Ether value.
    /// @param data Data payload.
    /// @param operation Operation type.
    /// @param safeTxGas Fas that should be used for the safe transaction.
    /// @param baseGas Gas costs for data used to trigger the safe transaction.
    /// @param gasPrice Maximum gas price that should be used for this transaction.
    /// @param gasToken Token address (or 0 if ETH) that is used for the payment.
    /// @param refundReceiver Address of receiver of gas payment (or 0 if tx.origin).
    /// @param _nonce Transaction nonce.
    /// @return Transaction hash.
    function getTransactionHash(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address refundReceiver,
        uint256 _nonce
    ) public view returns (bytes32) {
        return keccak256(encodeTransactionData(to, value, data, operation, safeTxGas, baseGas, gasPrice, gasToken, refundReceiver, _nonce));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";

/// @title Executor - A contract that can execute transactions
/// @author Richard Meissner - <[email protected]>
contract Executor {
    function execute(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 txGas
    ) internal returns (bool success) {
        if (operation == Enum.Operation.DelegateCall) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := delegatecall(txGas, to, add(data, 0x20), mload(data), 0, 0)
            }
        } else {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                success := call(txGas, to, value, add(data, 0x20), mload(data), 0, 0)
            }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/SelfAuthorized.sol";

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract FallbackManager is SelfAuthorized {
    event ChangedFallbackHandler(address handler);

    // keccak256("fallback_manager.handler.address")
    bytes32 internal constant FALLBACK_HANDLER_STORAGE_SLOT = 0x6c9a6c4a39284e37ed1cf53d337577d14212a4870fb976a4366c693b939918d5;

    function internalSetFallbackHandler(address handler) internal {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, handler)
        }
    }

    /// @dev Allows to add a contract to handle fallback calls.
    ///      Only fallback calls without value and with data will be forwarded.
    ///      This can only be done via a Safe transaction.
    /// @param handler contract to handle fallback calls.
    function setFallbackHandler(address handler) public authorized {
        internalSetFallbackHandler(handler);
        emit ChangedFallbackHandler(handler);
    }

    // solhint-disable-next-line payable-fallback,no-complex-fallback
    fallback() external {
        bytes32 slot = FALLBACK_HANDLER_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let handler := sload(slot)
            if iszero(handler) {
                return(0, 0)
            }
            calldatacopy(0, 0, calldatasize())
            // The msg.sender address is shifted to the left by 12 bytes to remove the padding
            // Then the address without padding is stored right after the calldata
            mstore(calldatasize(), shl(96, caller()))
            // Add 20 bytes for the address appended add the end
            let success := call(gas(), handler, 0, 0, add(calldatasize(), 20), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if iszero(success) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "../interfaces/IERC165.sol";

interface Guard is IERC165 {
    function checkTransaction(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation,
        uint256 safeTxGas,
        uint256 baseGas,
        uint256 gasPrice,
        address gasToken,
        address payable refundReceiver,
        bytes memory signatures,
        address msgSender
    ) external;

    function checkAfterExecution(bytes32 txHash, bool success) external;
}

abstract contract BaseGuard is Guard {
    function supportsInterface(bytes4 interfaceId) external view virtual override returns (bool) {
        return
            interfaceId == type(Guard).interfaceId || // 0xe6d7a83a
            interfaceId == type(IERC165).interfaceId; // 0x01ffc9a7
    }
}

/// @title Fallback Manager - A contract that manages fallback calls made to this contract
/// @author Richard Meissner - <[email protected]>
contract GuardManager is SelfAuthorized {
    event ChangedGuard(address guard);
    // keccak256("guard_manager.guard.address")
    bytes32 internal constant GUARD_STORAGE_SLOT = 0x4a204f620c8c5ccdca3fd54d003badd85ba500436a431f0cbda4f558c93c34c8;

    /// @dev Set a guard that checks transactions before execution
    /// @param guard The address of the guard to be used or the 0 address to disable the guard
    function setGuard(address guard) external authorized {
        if (guard != address(0)) {
            require(Guard(guard).supportsInterface(type(Guard).interfaceId), "GS300");
        }
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            sstore(slot, guard)
        }
        emit ChangedGuard(guard);
    }

    function getGuard() internal view returns (address guard) {
        bytes32 slot = GUARD_STORAGE_SLOT;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            guard := sload(slot)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/Enum.sol";
import "../common/SelfAuthorized.sol";
import "./Executor.sol";

/// @title Module Manager - A contract that manages modules that can execute transactions via this contract
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract ModuleManager is SelfAuthorized, Executor {
    event EnabledModule(address module);
    event DisabledModule(address module);
    event ExecutionFromModuleSuccess(address indexed module);
    event ExecutionFromModuleFailure(address indexed module);

    address internal constant SENTINEL_MODULES = address(0x1);

    mapping(address => address) internal modules;

    function setupModules(address to, bytes memory data) internal {
        require(modules[SENTINEL_MODULES] == address(0), "GS100");
        modules[SENTINEL_MODULES] = SENTINEL_MODULES;
        if (to != address(0))
            // Setup has to complete successfully or transaction fails.
            require(execute(to, 0, data, Enum.Operation.DelegateCall, gasleft()), "GS000");
    }

    /// @dev Allows to add a module to the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Enables the module `module` for the Safe.
    /// @param module Module to be whitelisted.
    function enableModule(address module) public authorized {
        // Module address cannot be null or sentinel.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        // Module cannot be added twice.
        require(modules[module] == address(0), "GS102");
        modules[module] = modules[SENTINEL_MODULES];
        modules[SENTINEL_MODULES] = module;
        emit EnabledModule(module);
    }

    /// @dev Allows to remove a module from the whitelist.
    ///      This can only be done via a Safe transaction.
    /// @notice Disables the module `module` for the Safe.
    /// @param prevModule Module that pointed to the module to be removed in the linked list
    /// @param module Module to be removed.
    function disableModule(address prevModule, address module) public authorized {
        // Validate module address and check that it corresponds to module index.
        require(module != address(0) && module != SENTINEL_MODULES, "GS101");
        require(modules[prevModule] == module, "GS103");
        modules[prevModule] = modules[module];
        modules[module] = address(0);
        emit DisabledModule(module);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations.
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModule(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public virtual returns (bool success) {
        // Only whitelisted modules are allowed.
        require(msg.sender != SENTINEL_MODULES && modules[msg.sender] != address(0), "GS104");
        // Execute transaction without further confirmations.
        success = execute(to, value, data, operation, gasleft());
        if (success) emit ExecutionFromModuleSuccess(msg.sender);
        else emit ExecutionFromModuleFailure(msg.sender);
    }

    /// @dev Allows a Module to execute a Safe transaction without any further confirmations and return data
    /// @param to Destination address of module transaction.
    /// @param value Ether value of module transaction.
    /// @param data Data payload of module transaction.
    /// @param operation Operation type of module transaction.
    function execTransactionFromModuleReturnData(
        address to,
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) public returns (bool success, bytes memory returnData) {
        success = execTransactionFromModule(to, value, data, operation);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // Load free memory location
            let ptr := mload(0x40)
            // We allocate memory for the return data by setting the free memory location to
            // current free memory location + data size + 32 bytes for data size value
            mstore(0x40, add(ptr, add(returndatasize(), 0x20)))
            // Store the size
            mstore(ptr, returndatasize())
            // Store the data
            returndatacopy(add(ptr, 0x20), 0, returndatasize())
            // Point the return data to the correct memory location
            returnData := ptr
        }
    }

    /// @dev Returns if an module is enabled
    /// @return True if the module is enabled
    function isModuleEnabled(address module) public view returns (bool) {
        return SENTINEL_MODULES != module && modules[module] != address(0);
    }

    /// @dev Returns array of modules.
    /// @param start Start of the page.
    /// @param pageSize Maximum number of modules that should be returned.
    /// @return array Array of modules.
    /// @return next Start of the next page.
    function getModulesPaginated(address start, uint256 pageSize) external view returns (address[] memory array, address next) {
        // Init array with max page size
        array = new address[](pageSize);

        // Populate return array
        uint256 moduleCount = 0;
        address currentModule = modules[start];
        while (currentModule != address(0x0) && currentModule != SENTINEL_MODULES && moduleCount < pageSize) {
            array[moduleCount] = currentModule;
            currentModule = modules[currentModule];
            moduleCount++;
        }
        next = currentModule;
        // Set correct size of returned array
        // solhint-disable-next-line no-inline-assembly
        assembly {
            mstore(array, moduleCount)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "../common/SelfAuthorized.sol";

/// @title OwnerManager - Manages a set of owners and a threshold to perform actions.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract OwnerManager is SelfAuthorized {
    event AddedOwner(address owner);
    event RemovedOwner(address owner);
    event ChangedThreshold(uint256 threshold);

    address internal constant SENTINEL_OWNERS = address(0x1);

    mapping(address => address) internal owners;
    uint256 internal ownerCount;
    uint256 internal threshold;

    /// @dev Setup function sets initial storage of contract.
    /// @param _owners List of Safe owners.
    /// @param _threshold Number of required confirmations for a Safe transaction.
    function setupOwners(address[] memory _owners, uint256 _threshold) internal {
        // Threshold can only be 0 at initialization.
        // Check ensures that setup function can only be called once.
        require(threshold == 0, "GS200");
        // Validate that threshold is smaller than number of added owners.
        require(_threshold <= _owners.length, "GS201");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "GS202");
        // Initializing Safe owners.
        address currentOwner = SENTINEL_OWNERS;
        for (uint256 i = 0; i < _owners.length; i++) {
            // Owner address cannot be null.
            address owner = _owners[i];
            require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this) && currentOwner != owner, "GS203");
            // No duplicate owners allowed.
            require(owners[owner] == address(0), "GS204");
            owners[currentOwner] = owner;
            currentOwner = owner;
        }
        owners[currentOwner] = SENTINEL_OWNERS;
        ownerCount = _owners.length;
        threshold = _threshold;
    }

    /// @dev Allows to add a new owner to the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @notice Adds the owner `owner` to the Safe and updates the threshold to `_threshold`.
    /// @param owner New owner address.
    /// @param _threshold New threshold.
    function addOwnerWithThreshold(address owner, uint256 _threshold) public authorized {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(owner != address(0) && owner != SENTINEL_OWNERS && owner != address(this), "GS203");
        // No duplicate owners allowed.
        require(owners[owner] == address(0), "GS204");
        owners[owner] = owners[SENTINEL_OWNERS];
        owners[SENTINEL_OWNERS] = owner;
        ownerCount++;
        emit AddedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /// @dev Allows to remove an owner from the Safe and update the threshold at the same time.
    ///      This can only be done via a Safe transaction.
    /// @notice Removes the owner `owner` from the Safe and updates the threshold to `_threshold`.
    /// @param prevOwner Owner that pointed to the owner to be removed in the linked list
    /// @param owner Owner address to be removed.
    /// @param _threshold New threshold.
    function removeOwner(
        address prevOwner,
        address owner,
        uint256 _threshold
    ) public authorized {
        // Only allow to remove an owner, if threshold can still be reached.
        require(ownerCount - 1 >= _threshold, "GS201");
        // Validate owner address and check that it corresponds to owner index.
        require(owner != address(0) && owner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == owner, "GS205");
        owners[prevOwner] = owners[owner];
        owners[owner] = address(0);
        ownerCount--;
        emit RemovedOwner(owner);
        // Change threshold if threshold was changed.
        if (threshold != _threshold) changeThreshold(_threshold);
    }

    /// @dev Allows to swap/replace an owner from the Safe with another address.
    ///      This can only be done via a Safe transaction.
    /// @notice Replaces the owner `oldOwner` in the Safe with `newOwner`.
    /// @param prevOwner Owner that pointed to the owner to be replaced in the linked list
    /// @param oldOwner Owner address to be replaced.
    /// @param newOwner New owner address.
    function swapOwner(
        address prevOwner,
        address oldOwner,
        address newOwner
    ) public authorized {
        // Owner address cannot be null, the sentinel or the Safe itself.
        require(newOwner != address(0) && newOwner != SENTINEL_OWNERS && newOwner != address(this), "GS203");
        // No duplicate owners allowed.
        require(owners[newOwner] == address(0), "GS204");
        // Validate oldOwner address and check that it corresponds to owner index.
        require(oldOwner != address(0) && oldOwner != SENTINEL_OWNERS, "GS203");
        require(owners[prevOwner] == oldOwner, "GS205");
        owners[newOwner] = owners[oldOwner];
        owners[prevOwner] = newOwner;
        owners[oldOwner] = address(0);
        emit RemovedOwner(oldOwner);
        emit AddedOwner(newOwner);
    }

    /// @dev Allows to update the number of required confirmations by Safe owners.
    ///      This can only be done via a Safe transaction.
    /// @notice Changes the threshold of the Safe to `_threshold`.
    /// @param _threshold New threshold.
    function changeThreshold(uint256 _threshold) public authorized {
        // Validate that threshold is smaller than number of owners.
        require(_threshold <= ownerCount, "GS201");
        // There has to be at least one Safe owner.
        require(_threshold >= 1, "GS202");
        threshold = _threshold;
        emit ChangedThreshold(threshold);
    }

    function getThreshold() public view returns (uint256) {
        return threshold;
    }

    function isOwner(address owner) public view returns (bool) {
        return owner != SENTINEL_OWNERS && owners[owner] != address(0);
    }

    /// @dev Returns array of owners.
    /// @return Array of Safe owners.
    function getOwners() public view returns (address[] memory) {
        address[] memory array = new address[](ownerCount);

        // populate return array
        uint256 index = 0;
        address currentOwner = owners[SENTINEL_OWNERS];
        while (currentOwner != SENTINEL_OWNERS) {
            array[index] = currentOwner;
            currentOwner = owners[currentOwner];
            index++;
        }
        return array;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Enum - Collection of enums
/// @author Richard Meissner - <[email protected]>
contract Enum {
    enum Operation {Call, DelegateCall}
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title EtherPaymentFallback - A contract that has a fallback to accept ether payments
/// @author Richard Meissner - <[email protected]>
contract EtherPaymentFallback {
    event SafeReceived(address indexed sender, uint256 value);

    /// @dev Fallback function accepts Ether transactions.
    receive() external payable {
        emit SafeReceived(msg.sender, msg.value);
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SecuredTokenTransfer - Secure token transfer
/// @author Richard Meissner - <[email protected]>
contract SecuredTokenTransfer {
    /// @dev Transfers a token and returns if it was a success
    /// @param token Token that should be transferred
    /// @param receiver Receiver to whom the token should be transferred
    /// @param amount The amount of tokens that should be transferred
    function transferToken(
        address token,
        address receiver,
        uint256 amount
    ) internal returns (bool transferred) {
        // 0xa9059cbb - keccack("transfer(address,uint256)")
        bytes memory data = abi.encodeWithSelector(0xa9059cbb, receiver, amount);
        // solhint-disable-next-line no-inline-assembly
        assembly {
            // We write the return value to scratch space.
            // See https://docs.soliditylang.org/en/v0.7.6/internals/layout_in_memory.html#layout-in-memory
            let success := call(sub(gas(), 10000), token, 0, add(data, 0x20), mload(data), 0, 0x20)
            switch returndatasize()
                case 0 {
                    transferred := success
                }
                case 0x20 {
                    transferred := iszero(or(iszero(success), iszero(mload(0))))
                }
                default {
                    transferred := 0
                }
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SelfAuthorized - authorizes current contract to perform actions
/// @author Richard Meissner - <[email protected]>
contract SelfAuthorized {
    function requireSelfCall() private view {
        require(msg.sender == address(this), "GS031");
    }

    modifier authorized() {
        // This is a function call as it minimized the bytecode size
        requireSelfCall();
        _;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title SignatureDecoder - Decodes signatures that a encoded as bytes
/// @author Richard Meissner - <[email protected]>
contract SignatureDecoder {
    /// @dev divides bytes signature into `uint8 v, bytes32 r, bytes32 s`.
    /// @notice Make sure to perform a bounds check for @param pos, to avoid out of bounds access on @param signatures
    /// @param pos which signature to read. A prior bounds check of this parameter should be performed, to avoid out of bounds access
    /// @param signatures concatenated rsv signatures
    function signatureSplit(bytes memory signatures, uint256 pos)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        // The signature format is a compact form of:
        //   {bytes32 r}{bytes32 s}{uint8 v}
        // Compact means, uint8 is not padded to 32 bytes.
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let signaturePos := mul(0x41, pos)
            r := mload(add(signatures, add(signaturePos, 0x20)))
            s := mload(add(signatures, add(signaturePos, 0x40)))
            // Here we are loading the last 32 bytes, including 31 bytes
            // of 's'. There is no 'mload8' to do this.
            //
            // 'byte' is not working due to the Solidity parser, so lets
            // use the second best option, 'and'
            v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title Singleton - Base for singleton contracts (should always be first super contract)
///         This contract is tightly coupled to our proxy contract (see `proxies/GnosisSafeProxy.sol`)
/// @author Richard Meissner - <[email protected]>
contract Singleton {
    // singleton always needs to be first declared variable, to ensure that it is at the same location as in the Proxy contract.
    // It should also always be ensured that the address is stored alone (uses a full word)
    address private singleton;
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title StorageAccessible - generic base contract that allows callers to access all internal storage.
/// @notice See https://github.com/gnosis/util-contracts/blob/bb5fe5fb5df6d8400998094fb1b32a178a47c3a1/contracts/StorageAccessible.sol
contract StorageAccessible {
    /**
     * @dev Reads `length` bytes of storage in the currents contract
     * @param offset - the offset in the current contract's storage in words to start reading from
     * @param length - the number of words (32 bytes) of data to read
     * @return the bytes that were read.
     */
    function getStorageAt(uint256 offset, uint256 length) public view returns (bytes memory) {
        bytes memory result = new bytes(length * 32);
        for (uint256 index = 0; index < length; index++) {
            // solhint-disable-next-line no-inline-assembly
            assembly {
                let word := sload(add(offset, index))
                mstore(add(add(result, 0x20), mul(index, 0x20)), word)
            }
        }
        return result;
    }

    /**
     * @dev Performs a delegatecall on a targetContract in the context of self.
     * Internally reverts execution to avoid side effects (making it static).
     *
     * This method reverts with data equal to `abi.encode(bool(success), bytes(response))`.
     * Specifically, the `returndata` after a call to this method will be:
     * `success:bool || response.length:uint256 || response:bytes`.
     *
     * @param targetContract Address of the contract containing the code to execute.
     * @param calldataPayload Calldata that should be sent to the target contract (encoded method name and arguments).
     */
    function simulateAndRevert(address targetContract, bytes memory calldataPayload) external {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let success := delegatecall(gas(), targetContract, add(calldataPayload, 0x20), mload(calldataPayload), 0, 0)

            mstore(0x00, success)
            mstore(0x20, returndatasize())
            returndatacopy(0x40, 0, returndatasize())
            revert(0, add(returndatasize(), 0x40))
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/**
 * @title GnosisSafeMath
 * @dev Math operations with safety checks that revert on error
 * Renamed from SafeMath to GnosisSafeMath to avoid conflicts
 * TODO: remove once open zeppelin update to solc 0.5.0
 */
library GnosisSafeMath {
    /**
     * @dev Multiplies two numbers, reverts on overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-solidity/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b);

        return c;
    }

    /**
     * @dev Subtracts two numbers, reverts on overflow (i.e. if subtrahend is greater than minuend).
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Adds two numbers, reverts on overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @notice More details at https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/introspection/IERC165.sol
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

contract ISignatureValidatorConstants {
    // bytes4(keccak256("isValidSignature(bytes,bytes)")
    bytes4 internal constant EIP1271_MAGIC_VALUE = 0x20c13b0b;
}

abstract contract ISignatureValidator is ISignatureValidatorConstants {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param _data Arbitrary length data signed on the behalf of address(this)
     * @param _signature Signature byte array associated with _data
     *
     * MUST return the bytes4 magic value 0x20c13b0b when function passes.
     * MUST NOT modify state (using STATICCALL for solc < 0.5, view modifier for solc > 0.5)
     * MUST allow external calls
     */
    function isValidSignature(bytes memory _data, bytes memory _signature) public view virtual returns (bytes4);
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

/// @title IProxy - Helper interface to access masterCopy of the Proxy on-chain
/// @author Richard Meissner - <[email protected]>
interface IProxy {
    function masterCopy() external view returns (address);
}

/// @title GnosisSafeProxy - Generic proxy contract allows to execute all transactions applying the code of a master contract.
/// @author Stefan George - <[email protected]>
/// @author Richard Meissner - <[email protected]>
contract GnosisSafeProxy {
    // singleton always needs to be first declared variable, to ensure that it is at the same location in the contracts to which calls are delegated.
    // To reduce deployment costs this variable is internal and needs to be retrieved via `getStorageAt`
    address internal singleton;

    /// @dev Constructor function sets address of singleton contract.
    /// @param _singleton Singleton address.
    constructor(address _singleton) {
        require(_singleton != address(0), "Invalid singleton address provided");
        singleton = _singleton;
    }

    /// @dev Fallback function forwards all transactions and returns all received return data.
    fallback() external payable {
        // solhint-disable-next-line no-inline-assembly
        assembly {
            let _singleton := and(sload(0), 0xffffffffffffffffffffffffffffffffffffffff)
            // 0xa619486e == keccak("masterCopy()"). The value is right padded to 32-bytes with 0s
            if eq(calldataload(0), 0xa619486e00000000000000000000000000000000000000000000000000000000) {
                mstore(0, _singleton)
                return(0, 0x20)
            }
            calldatacopy(0, 0, calldatasize())
            let success := delegatecall(gas(), _singleton, 0, calldatasize(), 0, 0)
            returndatacopy(0, 0, returndatasize())
            if eq(success, 0) {
                revert(0, returndatasize())
            }
            return(0, returndatasize())
        }
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;

import "./GnosisSafeProxy.sol";
import "./IProxyCreationCallback.sol";

/// @title Proxy Factory - Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
/// @author Stefan George - <[email protected]>
contract GnosisSafeProxyFactory {
    event ProxyCreation(GnosisSafeProxy proxy, address singleton);

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param singleton Address of singleton contract.
    /// @param data Payload for message call sent to new proxy contract.
    function createProxy(address singleton, bytes memory data) public returns (GnosisSafeProxy proxy) {
        proxy = new GnosisSafeProxy(singleton);
        if (data.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(call(gas(), proxy, 0, add(data, 0x20), mload(data), 0, 0), 0) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(proxy, singleton);
    }

    /// @dev Allows to retrieve the runtime code of a deployed Proxy. This can be used to check that the expected Proxy was deployed.
    function proxyRuntimeCode() public pure returns (bytes memory) {
        return type(GnosisSafeProxy).runtimeCode;
    }

    /// @dev Allows to retrieve the creation code used for the Proxy deployment. With this it is easily possible to calculate predicted address.
    function proxyCreationCode() public pure returns (bytes memory) {
        return type(GnosisSafeProxy).creationCode;
    }

    /// @dev Allows to create new proxy contact using CREATE2 but it doesn't run the initializer.
    ///      This method is only meant as an utility to be called from other methods
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function deployProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) internal returns (GnosisSafeProxy proxy) {
        // If the initializer changes the proxy address should change too. Hashing the initializer data is cheaper than just concatinating it
        bytes32 salt = keccak256(abi.encodePacked(keccak256(initializer), saltNonce));
        bytes memory deploymentData = abi.encodePacked(type(GnosisSafeProxy).creationCode, uint256(uint160(_singleton)));
        // solhint-disable-next-line no-inline-assembly
        assembly {
            proxy := create2(0x0, add(0x20, deploymentData), mload(deploymentData), salt)
        }
        require(address(proxy) != address(0), "Create2 call failed");
    }

    /// @dev Allows to create new proxy contact and execute a message call to the new proxy within one transaction.
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function createProxyWithNonce(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce
    ) public returns (GnosisSafeProxy proxy) {
        proxy = deployProxyWithNonce(_singleton, initializer, saltNonce);
        if (initializer.length > 0)
            // solhint-disable-next-line no-inline-assembly
            assembly {
                if eq(call(gas(), proxy, 0, add(initializer, 0x20), mload(initializer), 0, 0), 0) {
                    revert(0, 0)
                }
            }
        emit ProxyCreation(proxy, _singleton);
    }

    /// @dev Allows to create new proxy contact, execute a message call to the new proxy and call a specified callback within one transaction
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    /// @param callback Callback that will be invoked after the new proxy contract has been successfully deployed and initialized.
    function createProxyWithCallback(
        address _singleton,
        bytes memory initializer,
        uint256 saltNonce,
        IProxyCreationCallback callback
    ) public returns (GnosisSafeProxy proxy) {
        uint256 saltNonceWithCallback = uint256(keccak256(abi.encodePacked(saltNonce, callback)));
        proxy = createProxyWithNonce(_singleton, initializer, saltNonceWithCallback);
        if (address(callback) != address(0)) callback.proxyCreated(proxy, _singleton, initializer, saltNonce);
    }

    /// @dev Allows to get the address for a new proxy contact created via `createProxyWithNonce`
    ///      This method is only meant for address calculation purpose when you use an initializer that would revert,
    ///      therefore the response is returned with a revert. When calling this method set `from` to the address of the proxy factory.
    /// @param _singleton Address of singleton contract.
    /// @param initializer Payload for message call sent to new proxy contract.
    /// @param saltNonce Nonce that will be used to generate the salt to calculate the address of the new proxy contract.
    function calculateCreateProxyWithNonceAddress(
        address _singleton,
        bytes calldata initializer,
        uint256 saltNonce
    ) external returns (GnosisSafeProxy proxy) {
        proxy = deployProxyWithNonce(_singleton, initializer, saltNonce);
        revert(string(abi.encodePacked(proxy)));
    }
}

// SPDX-License-Identifier: LGPL-3.0-only
pragma solidity >=0.7.0 <0.9.0;
import "./GnosisSafeProxy.sol";

interface IProxyCreationCallback {
    function proxyCreated(
        GnosisSafeProxy proxy,
        address _singleton,
        bytes calldata initializer,
        uint256 saltNonce
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/Governor.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";
import "../token/ERC1155/IERC1155Receiver.sol";
import "../utils/cryptography/ECDSA.sol";
import "../utils/cryptography/EIP712.sol";
import "../utils/introspection/ERC165.sol";
import "../utils/math/SafeCast.sol";
import "../utils/structs/DoubleEndedQueue.sol";
import "../utils/Address.sol";
import "../utils/Context.sol";
import "../utils/Timers.sol";
import "./IGovernor.sol";

/**
 * @dev Core of the governance system, designed to be extended though various modules.
 *
 * This contract is abstract and requires several function to be implemented in various modules:
 *
 * - A counting module must implement {quorum}, {_quorumReached}, {_voteSucceeded} and {_countVote}
 * - A voting module must implement {_getVotes}
 * - Additionally, the {votingPeriod} must also be implemented
 *
 * _Available since v4.3._
 */
abstract contract Governor is Context, ERC165, EIP712, IGovernor, IERC721Receiver, IERC1155Receiver {
    using DoubleEndedQueue for DoubleEndedQueue.Bytes32Deque;
    using SafeCast for uint256;
    using Timers for Timers.BlockNumber;

    bytes32 public constant BALLOT_TYPEHASH = keccak256("Ballot(uint256 proposalId,uint8 support)");
    bytes32 public constant EXTENDED_BALLOT_TYPEHASH =
        keccak256("ExtendedBallot(uint256 proposalId,uint8 support,string reason,bytes params)");

    struct ProposalCore {
        Timers.BlockNumber voteStart;
        Timers.BlockNumber voteEnd;
        bool executed;
        bool canceled;
    }

    string private _name;

    mapping(uint256 => ProposalCore) private _proposals;

    // This queue keeps track of the governor operating on itself. Calls to functions protected by the
    // {onlyGovernance} modifier needs to be whitelisted in this queue. Whitelisting is set in {_beforeExecute},
    // consumed by the {onlyGovernance} modifier and eventually reset in {_afterExecute}. This ensures that the
    // execution of {onlyGovernance} protected calls can only be achieved through successful proposals.
    DoubleEndedQueue.Bytes32Deque private _governanceCall;

    /**
     * @dev Restricts a function so it can only be executed through governance proposals. For example, governance
     * parameter setters in {GovernorSettings} are protected using this modifier.
     *
     * The governance executing address may be different from the Governor's own address, for example it could be a
     * timelock. This can be customized by modules by overriding {_executor}. The executor is only able to invoke these
     * functions during the execution of the governor's {execute} function, and not under any other circumstances. Thus,
     * for example, additional timelock proposers are not able to change governance parameters without going through the
     * governance protocol (since v4.6).
     */
    modifier onlyGovernance() {
        require(_msgSender() == _executor(), "Governor: onlyGovernance");
        if (_executor() != address(this)) {
            bytes32 msgDataHash = keccak256(_msgData());
            // loop until popping the expected operation - throw if deque is empty (operation not authorized)
            while (_governanceCall.popFront() != msgDataHash) {}
        }
        _;
    }

    /**
     * @dev Sets the value for {name} and {version}
     */
    constructor(string memory name_) EIP712(name_, version()) {
        _name = name_;
    }

    /**
     * @dev Function to receive ETH that will be handled by the governor (disabled if executor is a third party contract)
     */
    receive() external payable virtual {
        require(_executor() == address(this));
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(IERC165, ERC165) returns (bool) {
        // In addition to the current interfaceId, also support previous version of the interfaceId that did not
        // include the castVoteWithReasonAndParams() function as standard
        return
            interfaceId ==
            (type(IGovernor).interfaceId ^
                this.castVoteWithReasonAndParams.selector ^
                this.castVoteWithReasonAndParamsBySig.selector ^
                this.getVotesWithParams.selector) ||
            interfaceId == type(IGovernor).interfaceId ||
            interfaceId == type(IERC1155Receiver).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IGovernor-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IGovernor-version}.
     */
    function version() public view virtual override returns (string memory) {
        return "1";
    }

    /**
     * @dev See {IGovernor-hashProposal}.
     *
     * The proposal id is produced by hashing the ABI encoded `targets` array, the `values` array, the `calldatas` array
     * and the descriptionHash (bytes32 which itself is the keccak256 hash of the description string). This proposal id
     * can be produced from the proposal data which is part of the {ProposalCreated} event. It can even be computed in
     * advance, before the proposal is submitted.
     *
     * Note that the chainId and the governor address are not part of the proposal id computation. Consequently, the
     * same proposal (with same operation and same description) will have the same id if submitted on multiple governors
     * across multiple networks. This also means that in order to execute the same operation twice (on the same
     * governor) the proposer will have to change the description in order to avoid proposal id conflicts.
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual override returns (uint256) {
        return uint256(keccak256(abi.encode(targets, values, calldatas, descriptionHash)));
    }

    /**
     * @dev See {IGovernor-state}.
     */
    function state(uint256 proposalId) public view virtual override returns (ProposalState) {
        ProposalCore storage proposal = _proposals[proposalId];

        if (proposal.executed) {
            return ProposalState.Executed;
        }

        if (proposal.canceled) {
            return ProposalState.Canceled;
        }

        uint256 snapshot = proposalSnapshot(proposalId);

        if (snapshot == 0) {
            revert("Governor: unknown proposal id");
        }

        if (snapshot >= block.number) {
            return ProposalState.Pending;
        }

        uint256 deadline = proposalDeadline(proposalId);

        if (deadline >= block.number) {
            return ProposalState.Active;
        }

        if (_quorumReached(proposalId) && _voteSucceeded(proposalId)) {
            return ProposalState.Succeeded;
        } else {
            return ProposalState.Defeated;
        }
    }

    /**
     * @dev See {IGovernor-proposalSnapshot}.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteStart.getDeadline();
    }

    /**
     * @dev See {IGovernor-proposalDeadline}.
     */
    function proposalDeadline(uint256 proposalId) public view virtual override returns (uint256) {
        return _proposals[proposalId].voteEnd.getDeadline();
    }

    /**
     * @dev Part of the Governor Bravo's interface: _"The number of votes required in order for a voter to become a proposer"_.
     */
    function proposalThreshold() public view virtual returns (uint256) {
        return 0;
    }

    /**
     * @dev Amount of votes already cast passes the threshold limit.
     */
    function _quorumReached(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Is the proposal successful or not.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual returns (bool);

    /**
     * @dev Get the voting weight of `account` at a specific `blockNumber`, for a vote as described by `params`.
     */
    function _getVotes(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) internal view virtual returns (uint256);

    /**
     * @dev Register a vote for `proposalId` by `account` with a given `support`, voting `weight` and voting `params`.
     *
     * Note: Support is generic and can represent various things depending on the voting system used.
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory params
    ) internal virtual;

    /**
     * @dev Default additional encoded parameters used by castVote methods that don't include them
     *
     * Note: Should be overridden by specific implementations to use an appropriate value, the
     * meaning of the additional params, in the context of that implementation
     */
    function _defaultParams() internal view virtual returns (bytes memory) {
        return "";
    }

    /**
     * @dev See {IGovernor-propose}.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual override returns (uint256) {
        require(
            getVotes(_msgSender(), block.number - 1) >= proposalThreshold(),
            "Governor: proposer votes below proposal threshold"
        );

        uint256 proposalId = hashProposal(targets, values, calldatas, keccak256(bytes(description)));

        require(targets.length == values.length, "Governor: invalid proposal length");
        require(targets.length == calldatas.length, "Governor: invalid proposal length");
        require(targets.length > 0, "Governor: empty proposal");

        ProposalCore storage proposal = _proposals[proposalId];
        require(proposal.voteStart.isUnset(), "Governor: proposal already exists");

        uint64 snapshot = block.number.toUint64() + votingDelay().toUint64();
        uint64 deadline = snapshot + votingPeriod().toUint64();

        proposal.voteStart.setDeadline(snapshot);
        proposal.voteEnd.setDeadline(deadline);

        emit ProposalCreated(
            proposalId,
            _msgSender(),
            targets,
            values,
            new string[](targets.length),
            calldatas,
            snapshot,
            deadline,
            description
        );

        return proposalId;
    }

    /**
     * @dev See {IGovernor-execute}.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual override returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);

        ProposalState status = state(proposalId);
        require(
            status == ProposalState.Succeeded || status == ProposalState.Queued,
            "Governor: proposal not successful"
        );
        _proposals[proposalId].executed = true;

        emit ProposalExecuted(proposalId);

        _beforeExecute(proposalId, targets, values, calldatas, descriptionHash);
        _execute(proposalId, targets, values, calldatas, descriptionHash);
        _afterExecute(proposalId, targets, values, calldatas, descriptionHash);

        return proposalId;
    }

    /**
     * @dev Internal execution mechanism. Can be overridden to implement different execution mechanism
     */
    function _execute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        string memory errorMessage = "Governor: call reverted without message";
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            Address.verifyCallResult(success, returndata, errorMessage);
        }
    }

    /**
     * @dev Hook before execution is triggered.
     */
    function _beforeExecute(
        uint256, /* proposalId */
        address[] memory targets,
        uint256[] memory, /* values */
        bytes[] memory calldatas,
        bytes32 /*descriptionHash*/
    ) internal virtual {
        if (_executor() != address(this)) {
            for (uint256 i = 0; i < targets.length; ++i) {
                if (targets[i] == address(this)) {
                    _governanceCall.pushBack(keccak256(calldatas[i]));
                }
            }
        }
    }

    /**
     * @dev Hook after execution is triggered.
     */
    function _afterExecute(
        uint256, /* proposalId */
        address[] memory, /* targets */
        uint256[] memory, /* values */
        bytes[] memory, /* calldatas */
        bytes32 /*descriptionHash*/
    ) internal virtual {
        if (_executor() != address(this)) {
            if (!_governanceCall.empty()) {
                _governanceCall.clear();
            }
        }
    }

    /**
     * @dev Internal cancel mechanism: locks up the proposal timer, preventing it from being re-submitted. Marks it as
     * canceled to allow distinguishing it from executed proposals.
     *
     * Emits a {IGovernor-ProposalCanceled} event.
     */
    function _cancel(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal virtual returns (uint256) {
        uint256 proposalId = hashProposal(targets, values, calldatas, descriptionHash);
        ProposalState status = state(proposalId);

        require(
            status != ProposalState.Canceled && status != ProposalState.Expired && status != ProposalState.Executed,
            "Governor: proposal not active"
        );
        _proposals[proposalId].canceled = true;

        emit ProposalCanceled(proposalId);

        return proposalId;
    }

    /**
     * @dev See {IGovernor-getVotes}.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        return _getVotes(account, blockNumber, _defaultParams());
    }

    /**
     * @dev See {IGovernor-getVotesWithParams}.
     */
    function getVotesWithParams(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) public view virtual override returns (uint256) {
        return _getVotes(account, blockNumber, params);
    }

    /**
     * @dev See {IGovernor-castVote}.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev See {IGovernor-castVoteWithReason}.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, reason);
    }

    /**
     * @dev See {IGovernor-castVoteWithReasonAndParams}.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual override returns (uint256) {
        address voter = _msgSender();
        return _castVote(proposalId, voter, support, reason, params);
    }

    /**
     * @dev See {IGovernor-castVoteBySig}.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(BALLOT_TYPEHASH, proposalId, support))),
            v,
            r,
            s
        );
        return _castVote(proposalId, voter, support, "");
    }

    /**
     * @dev See {IGovernor-castVoteWithReasonAndParamsBySig}.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override returns (uint256) {
        address voter = ECDSA.recover(
            _hashTypedDataV4(
                keccak256(
                    abi.encode(
                        EXTENDED_BALLOT_TYPEHASH,
                        proposalId,
                        support,
                        keccak256(bytes(reason)),
                        keccak256(params)
                    )
                )
            ),
            v,
            r,
            s
        );

        return _castVote(proposalId, voter, support, reason, params);
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function. Uses the _defaultParams().
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason
    ) internal virtual returns (uint256) {
        return _castVote(proposalId, account, support, reason, _defaultParams());
    }

    /**
     * @dev Internal vote casting mechanism: Check that the vote is pending, that it has not been cast yet, retrieve
     * voting weight using {IGovernor-getVotes} and call the {_countVote} internal function.
     *
     * Emits a {IGovernor-VoteCast} event.
     */
    function _castVote(
        uint256 proposalId,
        address account,
        uint8 support,
        string memory reason,
        bytes memory params
    ) internal virtual returns (uint256) {
        ProposalCore storage proposal = _proposals[proposalId];
        require(state(proposalId) == ProposalState.Active, "Governor: vote not currently active");

        uint256 weight = _getVotes(account, proposal.voteStart.getDeadline(), params);
        _countVote(proposalId, account, support, weight, params);

        if (params.length == 0) {
            emit VoteCast(account, proposalId, support, weight, reason);
        } else {
            emit VoteCastWithParams(account, proposalId, support, weight, reason, params);
        }

        return weight;
    }

    /**
     * @dev Relays a transaction or function call to an arbitrary target. In cases where the governance executor
     * is some contract other than the governor itself, like when using a timelock, this function can be invoked
     * in a governance proposal to recover tokens or Ether that was sent to the governor contract by mistake.
     * Note that if the executor is simply the governor itself, use of `relay` is redundant.
     */
    function relay(
        address target,
        uint256 value,
        bytes calldata data
    ) external payable virtual onlyGovernance {
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        Address.verifyCallResult(success, returndata, "Governor: relay reverted without message");
    }

    /**
     * @dev Address through which the governor executes action. Will be overloaded by module that execute actions
     * through another contract such as a timelock.
     */
    function _executor() internal view virtual returns (address) {
        return address(this);
    }

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/IGovernor.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/ERC165.sol";

/**
 * @dev Interface of the {Governor} core.
 *
 * _Available since v4.3._
 */
abstract contract IGovernor is IERC165 {
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }

    /**
     * @dev Emitted when a proposal is created.
     */
    event ProposalCreated(
        uint256 proposalId,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );

    /**
     * @dev Emitted when a proposal is canceled.
     */
    event ProposalCanceled(uint256 proposalId);

    /**
     * @dev Emitted when a proposal is executed.
     */
    event ProposalExecuted(uint256 proposalId);

    /**
     * @dev Emitted when a vote is cast without params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     */
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight, string reason);

    /**
     * @dev Emitted when a vote is cast with params.
     *
     * Note: `support` values should be seen as buckets. Their interpretation depends on the voting module used.
     * `params` are additional encoded parameters. Their intepepretation also depends on the voting module used.
     */
    event VoteCastWithParams(
        address indexed voter,
        uint256 proposalId,
        uint8 support,
        uint256 weight,
        string reason,
        bytes params
    );

    /**
     * @notice module:core
     * @dev Name of the governor instance (used in building the ERC712 domain separator).
     */
    function name() public view virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Version of the governor instance (used in building the ERC712 domain separator). Default: "1"
     */
    function version() public view virtual returns (string memory);

    /**
     * @notice module:voting
     * @dev A description of the possible `support` values for {castVote} and the way these votes are counted, meant to
     * be consumed by UIs to show correct vote options and interpret the results. The string is a URL-encoded sequence of
     * key-value pairs that each describe one aspect, for example `support=bravo&quorum=for,abstain`.
     *
     * There are 2 standard keys: `support` and `quorum`.
     *
     * - `support=bravo` refers to the vote options 0 = Against, 1 = For, 2 = Abstain, as in `GovernorBravo`.
     * - `quorum=bravo` means that only For votes are counted towards quorum.
     * - `quorum=for,abstain` means that both For and Abstain votes are counted towards quorum.
     *
     * If a counting module makes use of encoded `params`, it should  include this under a `params` key with a unique
     * name that describes the behavior. For example:
     *
     * - `params=fractional` might refer to a scheme where votes are divided fractionally between for/against/abstain.
     * - `params=erc721` might refer to a scheme where specific NFTs are delegated to vote.
     *
     * NOTE: The string can be decoded by the standard
     * https://developer.mozilla.org/en-US/docs/Web/API/URLSearchParams[`URLSearchParams`]
     * JavaScript class.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual returns (string memory);

    /**
     * @notice module:core
     * @dev Hashing function used to (re)build the proposal id from the proposal details..
     */
    function hashProposal(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public pure virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Current state of a proposal, following Compound's convention
     */
    function state(uint256 proposalId) public view virtual returns (ProposalState);

    /**
     * @notice module:core
     * @dev Block number used to retrieve user's votes and quorum. As per Compound's Comp and OpenZeppelin's
     * ERC20Votes, the snapshot is performed at the end of this block. Hence, voting for this proposal starts at the
     * beginning of the following block.
     */
    function proposalSnapshot(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:core
     * @dev Block number at which votes close. Votes close at the end of this block, so it is possible to cast a vote
     * during this block.
     */
    function proposalDeadline(uint256 proposalId) public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of block, between the proposal is created and the vote starts. This can be increassed to
     * leave time for users to buy voting power, or delegate it, before the voting of a proposal starts.
     */
    function votingDelay() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Delay, in number of blocks, between the vote start and vote ends.
     *
     * NOTE: The {votingDelay} can delay the start of the vote. This must be considered when setting the voting
     * duration compared to the voting delay.
     */
    function votingPeriod() public view virtual returns (uint256);

    /**
     * @notice module:user-config
     * @dev Minimum number of cast voted required for a proposal to be successful.
     *
     * Note: The `blockNumber` parameter corresponds to the snapshot used for counting vote. This allows to scale the
     * quorum depending on values such as the totalSupply of a token at this block (see {ERC20Votes}).
     */
    function quorum(uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber`.
     *
     * Note: this can be implemented in a number of ways, for example by reading the delegated balance from one (or
     * multiple), {ERC20Votes} tokens.
     */
    function getVotes(address account, uint256 blockNumber) public view virtual returns (uint256);

    /**
     * @notice module:reputation
     * @dev Voting power of an `account` at a specific `blockNumber` given additional encoded parameters.
     */
    function getVotesWithParams(
        address account,
        uint256 blockNumber,
        bytes memory params
    ) public view virtual returns (uint256);

    /**
     * @notice module:voting
     * @dev Returns whether `account` has cast a vote on `proposalId`.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual returns (bool);

    /**
     * @dev Create a new proposal. Vote start {IGovernor-votingDelay} blocks after the proposal is created and ends
     * {IGovernor-votingPeriod} blocks after the voting starts.
     *
     * Emits a {ProposalCreated} event.
     */
    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public virtual returns (uint256 proposalId);

    /**
     * @dev Execute a successful proposal. This requires the quorum to be reached, the vote to be successful, and the
     * deadline to be reached.
     *
     * Emits a {ProposalExecuted} event.
     *
     * Note: some module can modify the requirements for execution, for example by adding an additional timelock.
     */
    function execute(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) public payable virtual returns (uint256 proposalId);

    /**
     * @dev Cast a vote
     *
     * Emits a {VoteCast} event.
     */
    function castVote(uint256 proposalId, uint8 support) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason
     *
     * Emits a {VoteCast} event.
     */
    function castVoteWithReason(
        uint256 proposalId,
        uint8 support,
        string calldata reason
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParams(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote using the user's cryptographic signature.
     *
     * Emits a {VoteCast} event.
     */
    function castVoteBySig(
        uint256 proposalId,
        uint8 support,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);

    /**
     * @dev Cast a vote with a reason and additional encoded parameters using the user's cryptographic signature.
     *
     * Emits a {VoteCast} or {VoteCastWithParams} event depending on the length of params.
     */
    function castVoteWithReasonAndParamsBySig(
        uint256 proposalId,
        uint8 support,
        string calldata reason,
        bytes memory params,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual returns (uint256 balance);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (governance/extensions/GovernorCountingSimple.sol)

pragma solidity ^0.8.0;

import "../Governor.sol";

/**
 * @dev Extension of {Governor} for simple, 3 options, vote counting.
 *
 * _Available since v4.3._
 */
abstract contract GovernorCountingSimple is Governor {
    /**
     * @dev Supported vote types. Matches Governor Bravo ordering.
     */
    enum VoteType {
        Against,
        For,
        Abstain
    }

    struct ProposalVote {
        uint256 againstVotes;
        uint256 forVotes;
        uint256 abstainVotes;
        mapping(address => bool) hasVoted;
    }

    mapping(uint256 => ProposalVote) private _proposalVotes;

    /**
     * @dev See {IGovernor-COUNTING_MODE}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function COUNTING_MODE() public pure virtual override returns (string memory) {
        return "support=bravo&quorum=for,abstain";
    }

    /**
     * @dev See {IGovernor-hasVoted}.
     */
    function hasVoted(uint256 proposalId, address account) public view virtual override returns (bool) {
        return _proposalVotes[proposalId].hasVoted[account];
    }

    /**
     * @dev Accessor to the internal vote counts.
     */
    function proposalVotes(uint256 proposalId)
        public
        view
        virtual
        returns (
            uint256 againstVotes,
            uint256 forVotes,
            uint256 abstainVotes
        )
    {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];
        return (proposalVote.againstVotes, proposalVote.forVotes, proposalVote.abstainVotes);
    }

    /**
     * @dev See {Governor-_quorumReached}.
     */
    function _quorumReached(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return quorum(proposalSnapshot(proposalId)) <= proposalVote.forVotes + proposalVote.abstainVotes;
    }

    /**
     * @dev See {Governor-_voteSucceeded}. In this module, the forVotes must be strictly over the againstVotes.
     */
    function _voteSucceeded(uint256 proposalId) internal view virtual override returns (bool) {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        return proposalVote.forVotes > proposalVote.againstVotes;
    }

    /**
     * @dev See {Governor-_countVote}. In this module, the support follows the `VoteType` enum (from Governor Bravo).
     */
    function _countVote(
        uint256 proposalId,
        address account,
        uint8 support,
        uint256 weight,
        bytes memory // params
    ) internal virtual override {
        ProposalVote storage proposalVote = _proposalVotes[proposalId];

        require(!proposalVote.hasVoted[account], "GovernorVotingSimple: vote already cast");
        proposalVote.hasVoted[account] = true;

        if (support == uint8(VoteType.Against)) {
            proposalVote.againstVotes += weight;
        } else if (support == uint8(VoteType.For)) {
            proposalVote.forVotes += weight;
        } else if (support == uint8(VoteType.Abstain)) {
            proposalVote.abstainVotes += weight;
        } else {
            revert("GovernorVotingSimple: invalid value for enum VoteType");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (governance/extensions/GovernorSettings.sol)

pragma solidity ^0.8.0;

import "../Governor.sol";

/**
 * @dev Extension of {Governor} for settings updatable through governance.
 *
 * _Available since v4.4._
 */
abstract contract GovernorSettings is Governor {
    uint256 private _votingDelay;
    uint256 private _votingPeriod;
    uint256 private _proposalThreshold;

    event VotingDelaySet(uint256 oldVotingDelay, uint256 newVotingDelay);
    event VotingPeriodSet(uint256 oldVotingPeriod, uint256 newVotingPeriod);
    event ProposalThresholdSet(uint256 oldProposalThreshold, uint256 newProposalThreshold);

    /**
     * @dev Initialize the governance parameters.
     */
    constructor(
        uint256 initialVotingDelay,
        uint256 initialVotingPeriod,
        uint256 initialProposalThreshold
    ) {
        _setVotingDelay(initialVotingDelay);
        _setVotingPeriod(initialVotingPeriod);
        _setProposalThreshold(initialProposalThreshold);
    }

    /**
     * @dev See {IGovernor-votingDelay}.
     */
    function votingDelay() public view virtual override returns (uint256) {
        return _votingDelay;
    }

    /**
     * @dev See {IGovernor-votingPeriod}.
     */
    function votingPeriod() public view virtual override returns (uint256) {
        return _votingPeriod;
    }

    /**
     * @dev See {Governor-proposalThreshold}.
     */
    function proposalThreshold() public view virtual override returns (uint256) {
        return _proposalThreshold;
    }

    /**
     * @dev Update the voting delay. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingDelaySet} event.
     */
    function setVotingDelay(uint256 newVotingDelay) public virtual onlyGovernance {
        _setVotingDelay(newVotingDelay);
    }

    /**
     * @dev Update the voting period. This operation can only be performed through a governance proposal.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function setVotingPeriod(uint256 newVotingPeriod) public virtual onlyGovernance {
        _setVotingPeriod(newVotingPeriod);
    }

    /**
     * @dev Update the proposal threshold. This operation can only be performed through a governance proposal.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function setProposalThreshold(uint256 newProposalThreshold) public virtual onlyGovernance {
        _setProposalThreshold(newProposalThreshold);
    }

    /**
     * @dev Internal setter for the voting delay.
     *
     * Emits a {VotingDelaySet} event.
     */
    function _setVotingDelay(uint256 newVotingDelay) internal virtual {
        emit VotingDelaySet(_votingDelay, newVotingDelay);
        _votingDelay = newVotingDelay;
    }

    /**
     * @dev Internal setter for the voting period.
     *
     * Emits a {VotingPeriodSet} event.
     */
    function _setVotingPeriod(uint256 newVotingPeriod) internal virtual {
        // voting period must be at least one block long
        require(newVotingPeriod > 0, "GovernorSettings: voting period too low");
        emit VotingPeriodSet(_votingPeriod, newVotingPeriod);
        _votingPeriod = newVotingPeriod;
    }

    /**
     * @dev Internal setter for the proposal threshold.
     *
     * Emits a {ProposalThresholdSet} event.
     */
    function _setProposalThreshold(uint256 newProposalThreshold) internal virtual {
        emit ProposalThresholdSet(_proposalThreshold, newProposalThreshold);
        _proposalThreshold = newProposalThreshold;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (governance/utils/IVotes.sol)
pragma solidity ^0.8.0;

/**
 * @dev Common interface for {ERC20Votes}, {ERC721Votes}, and other {Votes}-enabled contracts.
 *
 * _Available since v4.5._
 */
interface IVotes {
    /**
     * @dev Emitted when an account changes their delegate.
     */
    event DelegateChanged(address indexed delegator, address indexed fromDelegate, address indexed toDelegate);

    /**
     * @dev Emitted when a token transfer or delegate change results in changes to a delegate's number of votes.
     */
    event DelegateVotesChanged(address indexed delegate, uint256 previousBalance, uint256 newBalance);

    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the delegate that `account` has chosen.
     */
    function delegates(address account) external view returns (address);

    /**
     * @dev Delegates votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) external;

    /**
     * @dev Delegates votes from signer to `delegatee`.
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/Clones.sol)

pragma solidity ^0.8.0;

/**
 * @dev https://eips.ethereum.org/EIPS/eip-1167[EIP 1167] is a standard for
 * deploying minimal proxy contracts, also known as "clones".
 *
 * > To simply and cheaply clone contract functionality in an immutable way, this standard specifies
 * > a minimal bytecode implementation that delegates all calls to a known, fixed address.
 *
 * The library includes functions to deploy a proxy using either `create` (traditional deployment) or `create2`
 * (salted deterministic deployment). It also includes functions to predict the addresses of clones deployed using the
 * deterministic method.
 *
 * _Available since v3.4._
 */
library Clones {
    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create opcode, which should never revert.
     */
    function clone(address implementation) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create(0, 0x09, 0x37)
        }
        require(instance != address(0), "ERC1167: create failed");
    }

    /**
     * @dev Deploys and returns the address of a clone that mimics the behaviour of `implementation`.
     *
     * This function uses the create2 opcode and a `salt` to deterministically deploy
     * the clone. Using the same `implementation` and `salt` multiple time will revert, since
     * the clones cannot be deployed twice at the same address.
     */
    function cloneDeterministic(address implementation, bytes32 salt) internal returns (address instance) {
        /// @solidity memory-safe-assembly
        assembly {
            // Cleans the upper 96 bits of the `implementation` word, then packs the first 3 bytes
            // of the `implementation` address with the bytecode before the address.
            mstore(0x00, or(shr(0xe8, shl(0x60, implementation)), 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000))
            // Packs the remaining 17 bytes of `implementation` with the bytecode after the address.
            mstore(0x20, or(shl(0x78, implementation), 0x5af43d82803e903d91602b57fd5bf3))
            instance := create2(0, 0x09, 0x37, salt)
        }
        require(instance != address(0), "ERC1167: create2 failed");
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(
        address implementation,
        bytes32 salt,
        address deployer
    ) internal pure returns (address predicted) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(add(ptr, 0x38), deployer)
            mstore(add(ptr, 0x24), 0x5af43d82803e903d91602b57fd5bf3ff)
            mstore(add(ptr, 0x14), implementation)
            mstore(ptr, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73)
            mstore(add(ptr, 0x58), salt)
            mstore(add(ptr, 0x78), keccak256(add(ptr, 0x0c), 0x37))
            predicted := keccak256(add(ptr, 0x43), 0x55)
        }
    }

    /**
     * @dev Computes the address of a clone deployed using {Clones-cloneDeterministic}.
     */
    function predictDeterministicAddress(address implementation, bytes32 salt)
        internal
        view
        returns (address predicted)
    {
        return predictDeterministicAddress(implementation, salt, address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.openzeppelin.com/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * NOTE: If `amount` is the maximum `uint256`, the allowance is not updated on
     * `transferFrom`. This is semantically equivalent to an infinite approval.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * NOTE: Does not update the allowance if the current allowance
     * is the maximum `uint256`.
     *
     * Requirements:
     *
     * - `from` and `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     * - the caller must have allowance for ``from``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public virtual override returns (bool) {
        address spender = _msgSender();
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = _msgSender();
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = _msgSender();
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(owner, spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `from` to `to`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `from` must have a balance of at least `amount`.
     */
    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(from, to, amount);

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[from] = fromBalance - amount;
            // Overflow not possible: the sum of all balances is capped by totalSupply, and the sum is preserved by
            // decrementing then incrementing.
            _balances[to] += amount;
        }

        emit Transfer(from, to, amount);

        _afterTokenTransfer(from, to, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        unchecked {
            // Overflow not possible: balance + amount is at most totalSupply + amount, which is checked above.
            _balances[account] += amount;
        }
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
            // Overflow not possible: amount <= accountBalance <= totalSupply.
            _totalSupply -= amount;
        }

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Updates `owner` s allowance for `spender` based on spent `amount`.
     *
     * Does not update the allowance amount in case of infinite allowance.
     * Revert if not enough allowance is available.
     *
     * Might emit an {Approval} event.
     */
    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/extensions/ERC20Permit.sol)

pragma solidity ^0.8.0;

import "./IERC20Permit.sol";
import "../ERC20.sol";
import "../../../utils/cryptography/ECDSA.sol";
import "../../../utils/cryptography/EIP712.sol";
import "../../../utils/Counters.sol";

/**
 * @dev Implementation of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on `{IERC20-approve}`, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 *
 * _Available since v3.4._
 */
abstract contract ERC20Permit is ERC20, IERC20Permit, EIP712 {
    using Counters for Counters.Counter;

    mapping(address => Counters.Counter) private _nonces;

    // solhint-disable-next-line var-name-mixedcase
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
    /**
     * @dev In previous versions `_PERMIT_TYPEHASH` was declared as `immutable`.
     * However, to ensure consistency with the upgradeable transpiler, we will continue
     * to reserve a slot.
     * @custom:oz-renamed-from _PERMIT_TYPEHASH
     */
    // solhint-disable-next-line var-name-mixedcase
    bytes32 private _PERMIT_TYPEHASH_DEPRECATED_SLOT;

    /**
     * @dev Initializes the {EIP712} domain separator using the `name` parameter, and setting `version` to `"1"`.
     *
     * It's a good idea to use the same `name` that is defined as the ERC20 token name.
     */
    constructor(string memory name) EIP712(name, "1") {}

    /**
     * @dev See {IERC20Permit-permit}.
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= deadline, "ERC20Permit: expired deadline");

        bytes32 structHash = keccak256(abi.encode(_PERMIT_TYPEHASH, owner, spender, value, _useNonce(owner), deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        require(signer == owner, "ERC20Permit: invalid signature");

        _approve(owner, spender, value);
    }

    /**
     * @dev See {IERC20Permit-nonces}.
     */
    function nonces(address owner) public view virtual override returns (uint256) {
        return _nonces[owner].current();
    }

    /**
     * @dev See {IERC20Permit-DOMAIN_SEPARATOR}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view override returns (bytes32) {
        return _domainSeparatorV4();
    }

    /**
     * @dev "Consume a nonce": return the current value and increment.
     *
     * _Available since v4.1._
     */
    function _useNonce(address owner) internal virtual returns (uint256 current) {
        Counters.Counter storage nonce = _nonces[owner];
        current = nonce.current();
        nonce.increment();
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/extensions/ERC20Votes.sol)

pragma solidity ^0.8.0;

import "./ERC20Permit.sol";
import "../../../utils/math/Math.sol";
import "../../../governance/utils/IVotes.sol";
import "../../../utils/math/SafeCast.sol";
import "../../../utils/cryptography/ECDSA.sol";

/**
 * @dev Extension of ERC20 to support Compound-like voting and delegation. This version is more generic than Compound's,
 * and supports token supply up to 2^224^ - 1, while COMP is limited to 2^96^ - 1.
 *
 * NOTE: If exact COMP compatibility is required, use the {ERC20VotesComp} variant of this module.
 *
 * This extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 *
 * _Available since v4.2._
 */
abstract contract ERC20Votes is IVotes, ERC20Permit {
    struct Checkpoint {
        uint32 fromBlock;
        uint224 votes;
    }

    bytes32 private constant _DELEGATION_TYPEHASH =
        keccak256("Delegation(address delegatee,uint256 nonce,uint256 expiry)");

    mapping(address => address) private _delegates;
    mapping(address => Checkpoint[]) private _checkpoints;
    Checkpoint[] private _totalSupplyCheckpoints;

    /**
     * @dev Get the `pos`-th checkpoint for `account`.
     */
    function checkpoints(address account, uint32 pos) public view virtual returns (Checkpoint memory) {
        return _checkpoints[account][pos];
    }

    /**
     * @dev Get number of checkpoints for `account`.
     */
    function numCheckpoints(address account) public view virtual returns (uint32) {
        return SafeCast.toUint32(_checkpoints[account].length);
    }

    /**
     * @dev Get the address `account` is currently delegating to.
     */
    function delegates(address account) public view virtual override returns (address) {
        return _delegates[account];
    }

    /**
     * @dev Gets the current votes balance for `account`
     */
    function getVotes(address account) public view virtual override returns (uint256) {
        uint256 pos = _checkpoints[account].length;
        unchecked {
            return pos == 0 ? 0 : _checkpoints[account][pos - 1].votes;
        }
    }

    /**
     * @dev Retrieve the number of votes for `account` at the end of `blockNumber`.
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastVotes(address account, uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_checkpoints[account], blockNumber);
    }

    /**
     * @dev Retrieve the `totalSupply` at the end of `blockNumber`. Note, this value is the sum of all balances.
     * It is NOT the sum of all the delegated votes!
     *
     * Requirements:
     *
     * - `blockNumber` must have been already mined
     */
    function getPastTotalSupply(uint256 blockNumber) public view virtual override returns (uint256) {
        require(blockNumber < block.number, "ERC20Votes: block not yet mined");
        return _checkpointsLookup(_totalSupplyCheckpoints, blockNumber);
    }

    /**
     * @dev Lookup a value in a list of (sorted) checkpoints.
     */
    function _checkpointsLookup(Checkpoint[] storage ckpts, uint256 blockNumber) private view returns (uint256) {
        // We run a binary search to look for the earliest checkpoint taken after `blockNumber`.
        //
        // Initially we check if the block is recent to narrow the search range.
        // During the loop, the index of the wanted checkpoint remains in the range [low-1, high).
        // With each iteration, either `low` or `high` is moved towards the middle of the range to maintain the invariant.
        // - If the middle checkpoint is after `blockNumber`, we look in [low, mid)
        // - If the middle checkpoint is before or equal to `blockNumber`, we look in [mid+1, high)
        // Once we reach a single value (when low == high), we've found the right checkpoint at the index high-1, if not
        // out of bounds (in which case we're looking too far in the past and the result is 0).
        // Note that if the latest checkpoint available is exactly for `blockNumber`, we end up with an index that is
        // past the end of the array, so we technically don't find a checkpoint after `blockNumber`, but it works out
        // the same.
        uint256 length = ckpts.length;

        uint256 low = 0;
        uint256 high = length;

        if (length > 5) {
            uint256 mid = length - Math.sqrt(length);
            if (_unsafeAccess(ckpts, mid).fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(ckpts, mid).fromBlock > blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        unchecked {
            return high == 0 ? 0 : _unsafeAccess(ckpts, high - 1).votes;
        }
    }

    /**
     * @dev Delegate votes from the sender to `delegatee`.
     */
    function delegate(address delegatee) public virtual override {
        _delegate(_msgSender(), delegatee);
    }

    /**
     * @dev Delegates votes from signer to `delegatee`
     */
    function delegateBySig(
        address delegatee,
        uint256 nonce,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual override {
        require(block.timestamp <= expiry, "ERC20Votes: signature expired");
        address signer = ECDSA.recover(
            _hashTypedDataV4(keccak256(abi.encode(_DELEGATION_TYPEHASH, delegatee, nonce, expiry))),
            v,
            r,
            s
        );
        require(nonce == _useNonce(signer), "ERC20Votes: invalid nonce");
        _delegate(signer, delegatee);
    }

    /**
     * @dev Maximum token supply. Defaults to `type(uint224).max` (2^224^ - 1).
     */
    function _maxSupply() internal view virtual returns (uint224) {
        return type(uint224).max;
    }

    /**
     * @dev Snapshots the totalSupply after it has been increased.
     */
    function _mint(address account, uint256 amount) internal virtual override {
        super._mint(account, amount);
        require(totalSupply() <= _maxSupply(), "ERC20Votes: total supply risks overflowing votes");

        _writeCheckpoint(_totalSupplyCheckpoints, _add, amount);
    }

    /**
     * @dev Snapshots the totalSupply after it has been decreased.
     */
    function _burn(address account, uint256 amount) internal virtual override {
        super._burn(account, amount);

        _writeCheckpoint(_totalSupplyCheckpoints, _subtract, amount);
    }

    /**
     * @dev Move voting power when tokens are transferred.
     *
     * Emits a {IVotes-DelegateVotesChanged} event.
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        super._afterTokenTransfer(from, to, amount);

        _moveVotingPower(delegates(from), delegates(to), amount);
    }

    /**
     * @dev Change delegation for `delegator` to `delegatee`.
     *
     * Emits events {IVotes-DelegateChanged} and {IVotes-DelegateVotesChanged}.
     */
    function _delegate(address delegator, address delegatee) internal virtual {
        address currentDelegate = delegates(delegator);
        uint256 delegatorBalance = balanceOf(delegator);
        _delegates[delegator] = delegatee;

        emit DelegateChanged(delegator, currentDelegate, delegatee);

        _moveVotingPower(currentDelegate, delegatee, delegatorBalance);
    }

    function _moveVotingPower(
        address src,
        address dst,
        uint256 amount
    ) private {
        if (src != dst && amount > 0) {
            if (src != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[src], _subtract, amount);
                emit DelegateVotesChanged(src, oldWeight, newWeight);
            }

            if (dst != address(0)) {
                (uint256 oldWeight, uint256 newWeight) = _writeCheckpoint(_checkpoints[dst], _add, amount);
                emit DelegateVotesChanged(dst, oldWeight, newWeight);
            }
        }
    }

    function _writeCheckpoint(
        Checkpoint[] storage ckpts,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) private returns (uint256 oldWeight, uint256 newWeight) {
        uint256 pos = ckpts.length;

        unchecked {
            Checkpoint memory oldCkpt = pos == 0 ? Checkpoint(0, 0) : _unsafeAccess(ckpts, pos - 1);

            oldWeight = oldCkpt.votes;
            newWeight = op(oldWeight, delta);

            if (pos > 0 && oldCkpt.fromBlock == block.number) {
                _unsafeAccess(ckpts, pos - 1).votes = SafeCast.toUint224(newWeight);
            } else {
                ckpts.push(
                    Checkpoint({fromBlock: SafeCast.toUint32(block.number), votes: SafeCast.toUint224(newWeight)})
                );
            }
        }
    }

    function _add(uint256 a, uint256 b) private pure returns (uint256) {
        return a + b;
    }

    function _subtract(uint256 a, uint256 b) private pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint[] storage ckpts, uint256 pos) private pure returns (Checkpoint storage result) {
        assembly {
            mstore(0, ckpts.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address-functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://consensys.net/diligence/blog/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Checkpoints.sol)
// This file was procedurally generated from scripts/generate/templates/Checkpoints.js.

pragma solidity ^0.8.0;

import "./math/Math.sol";
import "./math/SafeCast.sol";

/**
 * @dev This library defines the `History` struct, for checkpointing values as they change at different points in
 * time, and later looking up past values by block number. See {Votes} as an example.
 *
 * To create a history of checkpoints define a variable type `Checkpoints.History` in your contract, and store a new
 * checkpoint for the current transaction block using the {push} function.
 *
 * _Available since v4.5._
 */
library Checkpoints {
    struct History {
        Checkpoint[] _checkpoints;
    }

    struct Checkpoint {
        uint32 _blockNumber;
        uint224 _value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise. Because the number returned corresponds to that at the end of the
     * block, the requested block number must be in the past, excluding the current block.
     */
    function getAtBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCast.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value at a given block number. If a checkpoint is not available at that block, the closest one
     * before it is returned, or zero otherwise. Similar to {upperLookup} but optimized for the case when the searched
     * checkpoint is probably "recent", defined as being among the last sqrt(N) checkpoints where N is the number of
     * checkpoints.
     */
    function getAtProbablyRecentBlock(History storage self, uint256 blockNumber) internal view returns (uint256) {
        require(blockNumber < block.number, "Checkpoints: block not yet mined");
        uint32 key = SafeCast.toUint32(blockNumber);

        uint256 len = self._checkpoints.length;

        uint256 low = 0;
        uint256 high = len;

        if (len > 5) {
            uint256 mid = len - Math.sqrt(len);
            if (key < _unsafeAccess(self._checkpoints, mid)._blockNumber) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }

        uint256 pos = _upperBinaryLookup(self._checkpoints, key, low, high);

        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Pushes a value onto a History so that it is stored as the checkpoint for the current block.
     *
     * Returns previous value and new value.
     */
    function push(History storage self, uint256 value) internal returns (uint256, uint256) {
        return _insert(self._checkpoints, SafeCast.toUint32(block.number), SafeCast.toUint224(value));
    }

    /**
     * @dev Pushes a value onto a History, by updating the latest value using binary operation `op`. The new value will
     * be set to `op(latest, delta)`.
     *
     * Returns previous value and new value.
     */
    function push(
        History storage self,
        function(uint256, uint256) view returns (uint256) op,
        uint256 delta
    ) internal returns (uint256, uint256) {
        return push(self, op(latest(self), delta));
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(History storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(History storage self)
        internal
        view
        returns (
            bool exists,
            uint32 _blockNumber,
            uint224 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._blockNumber, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(History storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint[] storage self,
        uint32 key,
        uint224 value
    ) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint memory last = _unsafeAccess(self, pos - 1);

            // Checkpoint keys must be non-decreasing.
            require(last._blockNumber <= key, "Checkpoint: decreasing keys");

            // Update or push new checkpoint
            if (last._blockNumber == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint({_blockNumber: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint({_blockNumber: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._blockNumber < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint[] storage self, uint256 pos) private pure returns (Checkpoint storage result) {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace224 {
        Checkpoint224[] _checkpoints;
    }

    struct Checkpoint224 {
        uint32 _key;
        uint224 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace224 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(
        Trace224 storage self,
        uint32 key,
        uint224 value
    ) internal returns (uint224, uint224) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace224 storage self, uint32 key) internal view returns (uint224) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace224 storage self) internal view returns (uint224) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace224 storage self)
        internal
        view
        returns (
            bool exists,
            uint32 _key,
            uint224 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint224 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace224 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint224[] storage self,
        uint32 key,
        uint224 value
    ) private returns (uint224, uint224) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint224 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoint keys must be non-decreasing.
            require(last._key <= key, "Checkpoint: decreasing keys");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint224({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint224({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint224[] storage self,
        uint32 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint224[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint224 storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }

    struct Trace160 {
        Checkpoint160[] _checkpoints;
    }

    struct Checkpoint160 {
        uint96 _key;
        uint160 _value;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into a Trace160 so that it is stored as the checkpoint.
     *
     * Returns previous value and new value.
     */
    function push(
        Trace160 storage self,
        uint96 key,
        uint160 value
    ) internal returns (uint160, uint160) {
        return _insert(self._checkpoints, key, value);
    }

    /**
     * @dev Returns the value in the oldest checkpoint with key greater or equal than the search key, or zero if there is none.
     */
    function lowerLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _lowerBinaryLookup(self._checkpoints, key, 0, len);
        return pos == len ? 0 : _unsafeAccess(self._checkpoints, pos)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint with key lower or equal than the search key.
     */
    function upperLookup(Trace160 storage self, uint96 key) internal view returns (uint160) {
        uint256 len = self._checkpoints.length;
        uint256 pos = _upperBinaryLookup(self._checkpoints, key, 0, len);
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns the value in the most recent checkpoint, or zero if there are no checkpoints.
     */
    function latest(Trace160 storage self) internal view returns (uint160) {
        uint256 pos = self._checkpoints.length;
        return pos == 0 ? 0 : _unsafeAccess(self._checkpoints, pos - 1)._value;
    }

    /**
     * @dev Returns whether there is a checkpoint in the structure (i.e. it is not empty), and if so the key and value
     * in the most recent checkpoint.
     */
    function latestCheckpoint(Trace160 storage self)
        internal
        view
        returns (
            bool exists,
            uint96 _key,
            uint160 _value
        )
    {
        uint256 pos = self._checkpoints.length;
        if (pos == 0) {
            return (false, 0, 0);
        } else {
            Checkpoint160 memory ckpt = _unsafeAccess(self._checkpoints, pos - 1);
            return (true, ckpt._key, ckpt._value);
        }
    }

    /**
     * @dev Returns the number of checkpoint.
     */
    function length(Trace160 storage self) internal view returns (uint256) {
        return self._checkpoints.length;
    }

    /**
     * @dev Pushes a (`key`, `value`) pair into an ordered list of checkpoints, either by inserting a new checkpoint,
     * or by updating the last one.
     */
    function _insert(
        Checkpoint160[] storage self,
        uint96 key,
        uint160 value
    ) private returns (uint160, uint160) {
        uint256 pos = self.length;

        if (pos > 0) {
            // Copying to memory is important here.
            Checkpoint160 memory last = _unsafeAccess(self, pos - 1);

            // Checkpoint keys must be non-decreasing.
            require(last._key <= key, "Checkpoint: decreasing keys");

            // Update or push new checkpoint
            if (last._key == key) {
                _unsafeAccess(self, pos - 1)._value = value;
            } else {
                self.push(Checkpoint160({_key: key, _value: value}));
            }
            return (last._value, value);
        } else {
            self.push(Checkpoint160({_key: key, _value: value}));
            return (0, value);
        }
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _upperBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key > key) {
                high = mid;
            } else {
                low = mid + 1;
            }
        }
        return high;
    }

    /**
     * @dev Return the index of the oldest checkpoint whose key is greater or equal than the search key, or `high` if there is none.
     * `low` and `high` define a section where to do the search, with inclusive `low` and exclusive `high`.
     *
     * WARNING: `high` should not be greater than the array's length.
     */
    function _lowerBinaryLookup(
        Checkpoint160[] storage self,
        uint96 key,
        uint256 low,
        uint256 high
    ) private view returns (uint256) {
        while (low < high) {
            uint256 mid = Math.average(low, high);
            if (_unsafeAccess(self, mid)._key < key) {
                low = mid + 1;
            } else {
                high = mid;
            }
        }
        return high;
    }

    /**
     * @dev Access an element of the array without performing bounds check. The position is assumed to be within bounds.
     */
    function _unsafeAccess(Checkpoint160[] storage self, uint256 pos)
        private
        pure
        returns (Checkpoint160 storage result)
    {
        assembly {
            mstore(0, self.slot)
            result.slot := add(keccak256(0, 0x20), pos)
        }
    }
}

// SPDX-License-Identifier: MIT
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./math/Math.sol";

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = Math.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, Math.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Timers.sol)

pragma solidity ^0.8.0;

/**
 * @dev Tooling for timepoints, timers and delays
 */
library Timers {
    struct Timestamp {
        uint64 _deadline;
    }

    function getDeadline(Timestamp memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(Timestamp storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(Timestamp storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(Timestamp memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(Timestamp memory timer) internal view returns (bool) {
        return timer._deadline > block.timestamp;
    }

    function isExpired(Timestamp memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.timestamp;
    }

    struct BlockNumber {
        uint64 _deadline;
    }

    function getDeadline(BlockNumber memory timer) internal pure returns (uint64) {
        return timer._deadline;
    }

    function setDeadline(BlockNumber storage timer, uint64 timestamp) internal {
        timer._deadline = timestamp;
    }

    function reset(BlockNumber storage timer) internal {
        timer._deadline = 0;
    }

    function isUnset(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline == 0;
    }

    function isStarted(BlockNumber memory timer) internal pure returns (bool) {
        return timer._deadline > 0;
    }

    function isPending(BlockNumber memory timer) internal view returns (bool) {
        return timer._deadline > block.number;
    }

    function isExpired(BlockNumber memory timer) internal view returns (bool) {
        return isStarted(timer) && timer._deadline <= block.number;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV // Deprecated in v4.8
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            /// @solidity memory-safe-assembly
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/EIP712.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";

/**
 * @dev https://eips.ethereum.org/EIPS/eip-712[EIP 712] is a standard for hashing and signing of typed structured data.
 *
 * The encoding specified in the EIP is very generic, and such a generic implementation in Solidity is not feasible,
 * thus this contract does not implement the encoding itself. Protocols need to implement the type-specific encoding
 * they need in their contracts using a combination of `abi.encode` and `keccak256`.
 *
 * This contract implements the EIP 712 domain separator ({_domainSeparatorV4}) that is used as part of the encoding
 * scheme, and the final step of the encoding to obtain the message digest that is then signed via ECDSA
 * ({_hashTypedDataV4}).
 *
 * The implementation of the domain separator was designed to be as efficient as possible while still properly updating
 * the chain id to protect against replay attacks on an eventual fork of the chain.
 *
 * NOTE: This contract implements the version of the encoding known as "v4", as implemented by the JSON RPC method
 * https://docs.metamask.io/guide/signing-data.html[`eth_signTypedDataV4` in MetaMask].
 *
 * _Available since v3.4._
 */
abstract contract EIP712 {
    /* solhint-disable var-name-mixedcase */
    // Cache the domain separator as an immutable value, but also store the chain id that it corresponds to, in order to
    // invalidate the cached domain separator if the chain id changes.
    bytes32 private immutable _CACHED_DOMAIN_SEPARATOR;
    uint256 private immutable _CACHED_CHAIN_ID;
    address private immutable _CACHED_THIS;

    bytes32 private immutable _HASHED_NAME;
    bytes32 private immutable _HASHED_VERSION;
    bytes32 private immutable _TYPE_HASH;

    /* solhint-enable var-name-mixedcase */

    /**
     * @dev Initializes the domain separator and parameter caches.
     *
     * The meaning of `name` and `version` is specified in
     * https://eips.ethereum.org/EIPS/eip-712#definition-of-domainseparator[EIP 712]:
     *
     * - `name`: the user readable name of the signing domain, i.e. the name of the DApp or the protocol.
     * - `version`: the current major version of the signing domain.
     *
     * NOTE: These parameters cannot be changed except through a xref:learn::upgrading-smart-contracts.adoc[smart
     * contract upgrade].
     */
    constructor(string memory name, string memory version) {
        bytes32 hashedName = keccak256(bytes(name));
        bytes32 hashedVersion = keccak256(bytes(version));
        bytes32 typeHash = keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
        );
        _HASHED_NAME = hashedName;
        _HASHED_VERSION = hashedVersion;
        _CACHED_CHAIN_ID = block.chainid;
        _CACHED_DOMAIN_SEPARATOR = _buildDomainSeparator(typeHash, hashedName, hashedVersion);
        _CACHED_THIS = address(this);
        _TYPE_HASH = typeHash;
    }

    /**
     * @dev Returns the domain separator for the current chain.
     */
    function _domainSeparatorV4() internal view returns (bytes32) {
        if (address(this) == _CACHED_THIS && block.chainid == _CACHED_CHAIN_ID) {
            return _CACHED_DOMAIN_SEPARATOR;
        } else {
            return _buildDomainSeparator(_TYPE_HASH, _HASHED_NAME, _HASHED_VERSION);
        }
    }

    function _buildDomainSeparator(
        bytes32 typeHash,
        bytes32 nameHash,
        bytes32 versionHash
    ) private view returns (bytes32) {
        return keccak256(abi.encode(typeHash, nameHash, versionHash, block.chainid, address(this)));
    }

    /**
     * @dev Given an already https://eips.ethereum.org/EIPS/eip-712#definition-of-hashstruct[hashed struct], this
     * function returns the hash of the fully encoded EIP712 message for this domain.
     *
     * This hash can be used together with {ECDSA-recover} to obtain the signer of a message. For example:
     *
     * ```solidity
     * bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
     *     keccak256("Mail(address to,string contents)"),
     *     mailTo,
     *     keccak256(bytes(mailContents))
     * )));
     * address signer = ECDSA.recover(digest, signature);
     * ```
     */
    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_domainSeparatorV4(), structHash);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/draft-EIP712.sol)

pragma solidity ^0.8.0;

// EIP-712 is Final as of 2022-08-11. This file is deprecated.

import "./EIP712.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1, "Math: mulDiv overflow");

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result << 3) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/SafeCast.sol)
// This file was procedurally generated from scripts/generate/templates/SafeCast.js.

pragma solidity ^0.8.0;

/**
 * @dev Wrappers over Solidity's uintXX/intXX casting operators with added overflow
 * checks.
 *
 * Downcasting from uint256/int256 in Solidity does not revert on overflow. This can
 * easily result in undesired exploitation or bugs, since developers usually
 * assume that overflows raise errors. `SafeCast` restores this intuition by
 * reverting the transaction when such an operation overflows.
 *
 * Using this library instead of the unchecked operations eliminates an entire
 * class of bugs, so it's recommended to use it always.
 *
 * Can be combined with {SafeMath} and {SignedSafeMath} to extend it to smaller types, by performing
 * all math on `uint256` and `int256` and then downcasting.
 */
library SafeCast {
    /**
     * @dev Returns the downcasted uint248 from uint256, reverting on
     * overflow (when the input is greater than largest uint248).
     *
     * Counterpart to Solidity's `uint248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toUint248(uint256 value) internal pure returns (uint248) {
        require(value <= type(uint248).max, "SafeCast: value doesn't fit in 248 bits");
        return uint248(value);
    }

    /**
     * @dev Returns the downcasted uint240 from uint256, reverting on
     * overflow (when the input is greater than largest uint240).
     *
     * Counterpart to Solidity's `uint240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toUint240(uint256 value) internal pure returns (uint240) {
        require(value <= type(uint240).max, "SafeCast: value doesn't fit in 240 bits");
        return uint240(value);
    }

    /**
     * @dev Returns the downcasted uint232 from uint256, reverting on
     * overflow (when the input is greater than largest uint232).
     *
     * Counterpart to Solidity's `uint232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toUint232(uint256 value) internal pure returns (uint232) {
        require(value <= type(uint232).max, "SafeCast: value doesn't fit in 232 bits");
        return uint232(value);
    }

    /**
     * @dev Returns the downcasted uint224 from uint256, reverting on
     * overflow (when the input is greater than largest uint224).
     *
     * Counterpart to Solidity's `uint224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.2._
     */
    function toUint224(uint256 value) internal pure returns (uint224) {
        require(value <= type(uint224).max, "SafeCast: value doesn't fit in 224 bits");
        return uint224(value);
    }

    /**
     * @dev Returns the downcasted uint216 from uint256, reverting on
     * overflow (when the input is greater than largest uint216).
     *
     * Counterpart to Solidity's `uint216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toUint216(uint256 value) internal pure returns (uint216) {
        require(value <= type(uint216).max, "SafeCast: value doesn't fit in 216 bits");
        return uint216(value);
    }

    /**
     * @dev Returns the downcasted uint208 from uint256, reverting on
     * overflow (when the input is greater than largest uint208).
     *
     * Counterpart to Solidity's `uint208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toUint208(uint256 value) internal pure returns (uint208) {
        require(value <= type(uint208).max, "SafeCast: value doesn't fit in 208 bits");
        return uint208(value);
    }

    /**
     * @dev Returns the downcasted uint200 from uint256, reverting on
     * overflow (when the input is greater than largest uint200).
     *
     * Counterpart to Solidity's `uint200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toUint200(uint256 value) internal pure returns (uint200) {
        require(value <= type(uint200).max, "SafeCast: value doesn't fit in 200 bits");
        return uint200(value);
    }

    /**
     * @dev Returns the downcasted uint192 from uint256, reverting on
     * overflow (when the input is greater than largest uint192).
     *
     * Counterpart to Solidity's `uint192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toUint192(uint256 value) internal pure returns (uint192) {
        require(value <= type(uint192).max, "SafeCast: value doesn't fit in 192 bits");
        return uint192(value);
    }

    /**
     * @dev Returns the downcasted uint184 from uint256, reverting on
     * overflow (when the input is greater than largest uint184).
     *
     * Counterpart to Solidity's `uint184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toUint184(uint256 value) internal pure returns (uint184) {
        require(value <= type(uint184).max, "SafeCast: value doesn't fit in 184 bits");
        return uint184(value);
    }

    /**
     * @dev Returns the downcasted uint176 from uint256, reverting on
     * overflow (when the input is greater than largest uint176).
     *
     * Counterpart to Solidity's `uint176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toUint176(uint256 value) internal pure returns (uint176) {
        require(value <= type(uint176).max, "SafeCast: value doesn't fit in 176 bits");
        return uint176(value);
    }

    /**
     * @dev Returns the downcasted uint168 from uint256, reverting on
     * overflow (when the input is greater than largest uint168).
     *
     * Counterpart to Solidity's `uint168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toUint168(uint256 value) internal pure returns (uint168) {
        require(value <= type(uint168).max, "SafeCast: value doesn't fit in 168 bits");
        return uint168(value);
    }

    /**
     * @dev Returns the downcasted uint160 from uint256, reverting on
     * overflow (when the input is greater than largest uint160).
     *
     * Counterpart to Solidity's `uint160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toUint160(uint256 value) internal pure returns (uint160) {
        require(value <= type(uint160).max, "SafeCast: value doesn't fit in 160 bits");
        return uint160(value);
    }

    /**
     * @dev Returns the downcasted uint152 from uint256, reverting on
     * overflow (when the input is greater than largest uint152).
     *
     * Counterpart to Solidity's `uint152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toUint152(uint256 value) internal pure returns (uint152) {
        require(value <= type(uint152).max, "SafeCast: value doesn't fit in 152 bits");
        return uint152(value);
    }

    /**
     * @dev Returns the downcasted uint144 from uint256, reverting on
     * overflow (when the input is greater than largest uint144).
     *
     * Counterpart to Solidity's `uint144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toUint144(uint256 value) internal pure returns (uint144) {
        require(value <= type(uint144).max, "SafeCast: value doesn't fit in 144 bits");
        return uint144(value);
    }

    /**
     * @dev Returns the downcasted uint136 from uint256, reverting on
     * overflow (when the input is greater than largest uint136).
     *
     * Counterpart to Solidity's `uint136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toUint136(uint256 value) internal pure returns (uint136) {
        require(value <= type(uint136).max, "SafeCast: value doesn't fit in 136 bits");
        return uint136(value);
    }

    /**
     * @dev Returns the downcasted uint128 from uint256, reverting on
     * overflow (when the input is greater than largest uint128).
     *
     * Counterpart to Solidity's `uint128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v2.5._
     */
    function toUint128(uint256 value) internal pure returns (uint128) {
        require(value <= type(uint128).max, "SafeCast: value doesn't fit in 128 bits");
        return uint128(value);
    }

    /**
     * @dev Returns the downcasted uint120 from uint256, reverting on
     * overflow (when the input is greater than largest uint120).
     *
     * Counterpart to Solidity's `uint120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toUint120(uint256 value) internal pure returns (uint120) {
        require(value <= type(uint120).max, "SafeCast: value doesn't fit in 120 bits");
        return uint120(value);
    }

    /**
     * @dev Returns the downcasted uint112 from uint256, reverting on
     * overflow (when the input is greater than largest uint112).
     *
     * Counterpart to Solidity's `uint112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toUint112(uint256 value) internal pure returns (uint112) {
        require(value <= type(uint112).max, "SafeCast: value doesn't fit in 112 bits");
        return uint112(value);
    }

    /**
     * @dev Returns the downcasted uint104 from uint256, reverting on
     * overflow (when the input is greater than largest uint104).
     *
     * Counterpart to Solidity's `uint104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toUint104(uint256 value) internal pure returns (uint104) {
        require(value <= type(uint104).max, "SafeCast: value doesn't fit in 104 bits");
        return uint104(value);
    }

    /**
     * @dev Returns the downcasted uint96 from uint256, reverting on
     * overflow (when the input is greater than largest uint96).
     *
     * Counterpart to Solidity's `uint96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.2._
     */
    function toUint96(uint256 value) internal pure returns (uint96) {
        require(value <= type(uint96).max, "SafeCast: value doesn't fit in 96 bits");
        return uint96(value);
    }

    /**
     * @dev Returns the downcasted uint88 from uint256, reverting on
     * overflow (when the input is greater than largest uint88).
     *
     * Counterpart to Solidity's `uint88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toUint88(uint256 value) internal pure returns (uint88) {
        require(value <= type(uint88).max, "SafeCast: value doesn't fit in 88 bits");
        return uint88(value);
    }

    /**
     * @dev Returns the downcasted uint80 from uint256, reverting on
     * overflow (when the input is greater than largest uint80).
     *
     * Counterpart to Solidity's `uint80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toUint80(uint256 value) internal pure returns (uint80) {
        require(value <= type(uint80).max, "SafeCast: value doesn't fit in 80 bits");
        return uint80(value);
    }

    /**
     * @dev Returns the downcasted uint72 from uint256, reverting on
     * overflow (when the input is greater than largest uint72).
     *
     * Counterpart to Solidity's `uint72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toUint72(uint256 value) internal pure returns (uint72) {
        require(value <= type(uint72).max, "SafeCast: value doesn't fit in 72 bits");
        return uint72(value);
    }

    /**
     * @dev Returns the downcasted uint64 from uint256, reverting on
     * overflow (when the input is greater than largest uint64).
     *
     * Counterpart to Solidity's `uint64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v2.5._
     */
    function toUint64(uint256 value) internal pure returns (uint64) {
        require(value <= type(uint64).max, "SafeCast: value doesn't fit in 64 bits");
        return uint64(value);
    }

    /**
     * @dev Returns the downcasted uint56 from uint256, reverting on
     * overflow (when the input is greater than largest uint56).
     *
     * Counterpart to Solidity's `uint56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toUint56(uint256 value) internal pure returns (uint56) {
        require(value <= type(uint56).max, "SafeCast: value doesn't fit in 56 bits");
        return uint56(value);
    }

    /**
     * @dev Returns the downcasted uint48 from uint256, reverting on
     * overflow (when the input is greater than largest uint48).
     *
     * Counterpart to Solidity's `uint48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toUint48(uint256 value) internal pure returns (uint48) {
        require(value <= type(uint48).max, "SafeCast: value doesn't fit in 48 bits");
        return uint48(value);
    }

    /**
     * @dev Returns the downcasted uint40 from uint256, reverting on
     * overflow (when the input is greater than largest uint40).
     *
     * Counterpart to Solidity's `uint40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toUint40(uint256 value) internal pure returns (uint40) {
        require(value <= type(uint40).max, "SafeCast: value doesn't fit in 40 bits");
        return uint40(value);
    }

    /**
     * @dev Returns the downcasted uint32 from uint256, reverting on
     * overflow (when the input is greater than largest uint32).
     *
     * Counterpart to Solidity's `uint32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v2.5._
     */
    function toUint32(uint256 value) internal pure returns (uint32) {
        require(value <= type(uint32).max, "SafeCast: value doesn't fit in 32 bits");
        return uint32(value);
    }

    /**
     * @dev Returns the downcasted uint24 from uint256, reverting on
     * overflow (when the input is greater than largest uint24).
     *
     * Counterpart to Solidity's `uint24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toUint24(uint256 value) internal pure returns (uint24) {
        require(value <= type(uint24).max, "SafeCast: value doesn't fit in 24 bits");
        return uint24(value);
    }

    /**
     * @dev Returns the downcasted uint16 from uint256, reverting on
     * overflow (when the input is greater than largest uint16).
     *
     * Counterpart to Solidity's `uint16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v2.5._
     */
    function toUint16(uint256 value) internal pure returns (uint16) {
        require(value <= type(uint16).max, "SafeCast: value doesn't fit in 16 bits");
        return uint16(value);
    }

    /**
     * @dev Returns the downcasted uint8 from uint256, reverting on
     * overflow (when the input is greater than largest uint8).
     *
     * Counterpart to Solidity's `uint8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v2.5._
     */
    function toUint8(uint256 value) internal pure returns (uint8) {
        require(value <= type(uint8).max, "SafeCast: value doesn't fit in 8 bits");
        return uint8(value);
    }

    /**
     * @dev Converts a signed int256 into an unsigned uint256.
     *
     * Requirements:
     *
     * - input must be greater than or equal to 0.
     *
     * _Available since v3.0._
     */
    function toUint256(int256 value) internal pure returns (uint256) {
        require(value >= 0, "SafeCast: value must be positive");
        return uint256(value);
    }

    /**
     * @dev Returns the downcasted int248 from int256, reverting on
     * overflow (when the input is less than smallest int248 or
     * greater than largest int248).
     *
     * Counterpart to Solidity's `int248` operator.
     *
     * Requirements:
     *
     * - input must fit into 248 bits
     *
     * _Available since v4.7._
     */
    function toInt248(int256 value) internal pure returns (int248 downcasted) {
        downcasted = int248(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 248 bits");
    }

    /**
     * @dev Returns the downcasted int240 from int256, reverting on
     * overflow (when the input is less than smallest int240 or
     * greater than largest int240).
     *
     * Counterpart to Solidity's `int240` operator.
     *
     * Requirements:
     *
     * - input must fit into 240 bits
     *
     * _Available since v4.7._
     */
    function toInt240(int256 value) internal pure returns (int240 downcasted) {
        downcasted = int240(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 240 bits");
    }

    /**
     * @dev Returns the downcasted int232 from int256, reverting on
     * overflow (when the input is less than smallest int232 or
     * greater than largest int232).
     *
     * Counterpart to Solidity's `int232` operator.
     *
     * Requirements:
     *
     * - input must fit into 232 bits
     *
     * _Available since v4.7._
     */
    function toInt232(int256 value) internal pure returns (int232 downcasted) {
        downcasted = int232(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 232 bits");
    }

    /**
     * @dev Returns the downcasted int224 from int256, reverting on
     * overflow (when the input is less than smallest int224 or
     * greater than largest int224).
     *
     * Counterpart to Solidity's `int224` operator.
     *
     * Requirements:
     *
     * - input must fit into 224 bits
     *
     * _Available since v4.7._
     */
    function toInt224(int256 value) internal pure returns (int224 downcasted) {
        downcasted = int224(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 224 bits");
    }

    /**
     * @dev Returns the downcasted int216 from int256, reverting on
     * overflow (when the input is less than smallest int216 or
     * greater than largest int216).
     *
     * Counterpart to Solidity's `int216` operator.
     *
     * Requirements:
     *
     * - input must fit into 216 bits
     *
     * _Available since v4.7._
     */
    function toInt216(int256 value) internal pure returns (int216 downcasted) {
        downcasted = int216(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 216 bits");
    }

    /**
     * @dev Returns the downcasted int208 from int256, reverting on
     * overflow (when the input is less than smallest int208 or
     * greater than largest int208).
     *
     * Counterpart to Solidity's `int208` operator.
     *
     * Requirements:
     *
     * - input must fit into 208 bits
     *
     * _Available since v4.7._
     */
    function toInt208(int256 value) internal pure returns (int208 downcasted) {
        downcasted = int208(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 208 bits");
    }

    /**
     * @dev Returns the downcasted int200 from int256, reverting on
     * overflow (when the input is less than smallest int200 or
     * greater than largest int200).
     *
     * Counterpart to Solidity's `int200` operator.
     *
     * Requirements:
     *
     * - input must fit into 200 bits
     *
     * _Available since v4.7._
     */
    function toInt200(int256 value) internal pure returns (int200 downcasted) {
        downcasted = int200(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 200 bits");
    }

    /**
     * @dev Returns the downcasted int192 from int256, reverting on
     * overflow (when the input is less than smallest int192 or
     * greater than largest int192).
     *
     * Counterpart to Solidity's `int192` operator.
     *
     * Requirements:
     *
     * - input must fit into 192 bits
     *
     * _Available since v4.7._
     */
    function toInt192(int256 value) internal pure returns (int192 downcasted) {
        downcasted = int192(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 192 bits");
    }

    /**
     * @dev Returns the downcasted int184 from int256, reverting on
     * overflow (when the input is less than smallest int184 or
     * greater than largest int184).
     *
     * Counterpart to Solidity's `int184` operator.
     *
     * Requirements:
     *
     * - input must fit into 184 bits
     *
     * _Available since v4.7._
     */
    function toInt184(int256 value) internal pure returns (int184 downcasted) {
        downcasted = int184(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 184 bits");
    }

    /**
     * @dev Returns the downcasted int176 from int256, reverting on
     * overflow (when the input is less than smallest int176 or
     * greater than largest int176).
     *
     * Counterpart to Solidity's `int176` operator.
     *
     * Requirements:
     *
     * - input must fit into 176 bits
     *
     * _Available since v4.7._
     */
    function toInt176(int256 value) internal pure returns (int176 downcasted) {
        downcasted = int176(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 176 bits");
    }

    /**
     * @dev Returns the downcasted int168 from int256, reverting on
     * overflow (when the input is less than smallest int168 or
     * greater than largest int168).
     *
     * Counterpart to Solidity's `int168` operator.
     *
     * Requirements:
     *
     * - input must fit into 168 bits
     *
     * _Available since v4.7._
     */
    function toInt168(int256 value) internal pure returns (int168 downcasted) {
        downcasted = int168(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 168 bits");
    }

    /**
     * @dev Returns the downcasted int160 from int256, reverting on
     * overflow (when the input is less than smallest int160 or
     * greater than largest int160).
     *
     * Counterpart to Solidity's `int160` operator.
     *
     * Requirements:
     *
     * - input must fit into 160 bits
     *
     * _Available since v4.7._
     */
    function toInt160(int256 value) internal pure returns (int160 downcasted) {
        downcasted = int160(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 160 bits");
    }

    /**
     * @dev Returns the downcasted int152 from int256, reverting on
     * overflow (when the input is less than smallest int152 or
     * greater than largest int152).
     *
     * Counterpart to Solidity's `int152` operator.
     *
     * Requirements:
     *
     * - input must fit into 152 bits
     *
     * _Available since v4.7._
     */
    function toInt152(int256 value) internal pure returns (int152 downcasted) {
        downcasted = int152(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 152 bits");
    }

    /**
     * @dev Returns the downcasted int144 from int256, reverting on
     * overflow (when the input is less than smallest int144 or
     * greater than largest int144).
     *
     * Counterpart to Solidity's `int144` operator.
     *
     * Requirements:
     *
     * - input must fit into 144 bits
     *
     * _Available since v4.7._
     */
    function toInt144(int256 value) internal pure returns (int144 downcasted) {
        downcasted = int144(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 144 bits");
    }

    /**
     * @dev Returns the downcasted int136 from int256, reverting on
     * overflow (when the input is less than smallest int136 or
     * greater than largest int136).
     *
     * Counterpart to Solidity's `int136` operator.
     *
     * Requirements:
     *
     * - input must fit into 136 bits
     *
     * _Available since v4.7._
     */
    function toInt136(int256 value) internal pure returns (int136 downcasted) {
        downcasted = int136(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 136 bits");
    }

    /**
     * @dev Returns the downcasted int128 from int256, reverting on
     * overflow (when the input is less than smallest int128 or
     * greater than largest int128).
     *
     * Counterpart to Solidity's `int128` operator.
     *
     * Requirements:
     *
     * - input must fit into 128 bits
     *
     * _Available since v3.1._
     */
    function toInt128(int256 value) internal pure returns (int128 downcasted) {
        downcasted = int128(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 128 bits");
    }

    /**
     * @dev Returns the downcasted int120 from int256, reverting on
     * overflow (when the input is less than smallest int120 or
     * greater than largest int120).
     *
     * Counterpart to Solidity's `int120` operator.
     *
     * Requirements:
     *
     * - input must fit into 120 bits
     *
     * _Available since v4.7._
     */
    function toInt120(int256 value) internal pure returns (int120 downcasted) {
        downcasted = int120(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 120 bits");
    }

    /**
     * @dev Returns the downcasted int112 from int256, reverting on
     * overflow (when the input is less than smallest int112 or
     * greater than largest int112).
     *
     * Counterpart to Solidity's `int112` operator.
     *
     * Requirements:
     *
     * - input must fit into 112 bits
     *
     * _Available since v4.7._
     */
    function toInt112(int256 value) internal pure returns (int112 downcasted) {
        downcasted = int112(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 112 bits");
    }

    /**
     * @dev Returns the downcasted int104 from int256, reverting on
     * overflow (when the input is less than smallest int104 or
     * greater than largest int104).
     *
     * Counterpart to Solidity's `int104` operator.
     *
     * Requirements:
     *
     * - input must fit into 104 bits
     *
     * _Available since v4.7._
     */
    function toInt104(int256 value) internal pure returns (int104 downcasted) {
        downcasted = int104(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 104 bits");
    }

    /**
     * @dev Returns the downcasted int96 from int256, reverting on
     * overflow (when the input is less than smallest int96 or
     * greater than largest int96).
     *
     * Counterpart to Solidity's `int96` operator.
     *
     * Requirements:
     *
     * - input must fit into 96 bits
     *
     * _Available since v4.7._
     */
    function toInt96(int256 value) internal pure returns (int96 downcasted) {
        downcasted = int96(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 96 bits");
    }

    /**
     * @dev Returns the downcasted int88 from int256, reverting on
     * overflow (when the input is less than smallest int88 or
     * greater than largest int88).
     *
     * Counterpart to Solidity's `int88` operator.
     *
     * Requirements:
     *
     * - input must fit into 88 bits
     *
     * _Available since v4.7._
     */
    function toInt88(int256 value) internal pure returns (int88 downcasted) {
        downcasted = int88(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 88 bits");
    }

    /**
     * @dev Returns the downcasted int80 from int256, reverting on
     * overflow (when the input is less than smallest int80 or
     * greater than largest int80).
     *
     * Counterpart to Solidity's `int80` operator.
     *
     * Requirements:
     *
     * - input must fit into 80 bits
     *
     * _Available since v4.7._
     */
    function toInt80(int256 value) internal pure returns (int80 downcasted) {
        downcasted = int80(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 80 bits");
    }

    /**
     * @dev Returns the downcasted int72 from int256, reverting on
     * overflow (when the input is less than smallest int72 or
     * greater than largest int72).
     *
     * Counterpart to Solidity's `int72` operator.
     *
     * Requirements:
     *
     * - input must fit into 72 bits
     *
     * _Available since v4.7._
     */
    function toInt72(int256 value) internal pure returns (int72 downcasted) {
        downcasted = int72(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 72 bits");
    }

    /**
     * @dev Returns the downcasted int64 from int256, reverting on
     * overflow (when the input is less than smallest int64 or
     * greater than largest int64).
     *
     * Counterpart to Solidity's `int64` operator.
     *
     * Requirements:
     *
     * - input must fit into 64 bits
     *
     * _Available since v3.1._
     */
    function toInt64(int256 value) internal pure returns (int64 downcasted) {
        downcasted = int64(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 64 bits");
    }

    /**
     * @dev Returns the downcasted int56 from int256, reverting on
     * overflow (when the input is less than smallest int56 or
     * greater than largest int56).
     *
     * Counterpart to Solidity's `int56` operator.
     *
     * Requirements:
     *
     * - input must fit into 56 bits
     *
     * _Available since v4.7._
     */
    function toInt56(int256 value) internal pure returns (int56 downcasted) {
        downcasted = int56(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 56 bits");
    }

    /**
     * @dev Returns the downcasted int48 from int256, reverting on
     * overflow (when the input is less than smallest int48 or
     * greater than largest int48).
     *
     * Counterpart to Solidity's `int48` operator.
     *
     * Requirements:
     *
     * - input must fit into 48 bits
     *
     * _Available since v4.7._
     */
    function toInt48(int256 value) internal pure returns (int48 downcasted) {
        downcasted = int48(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 48 bits");
    }

    /**
     * @dev Returns the downcasted int40 from int256, reverting on
     * overflow (when the input is less than smallest int40 or
     * greater than largest int40).
     *
     * Counterpart to Solidity's `int40` operator.
     *
     * Requirements:
     *
     * - input must fit into 40 bits
     *
     * _Available since v4.7._
     */
    function toInt40(int256 value) internal pure returns (int40 downcasted) {
        downcasted = int40(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 40 bits");
    }

    /**
     * @dev Returns the downcasted int32 from int256, reverting on
     * overflow (when the input is less than smallest int32 or
     * greater than largest int32).
     *
     * Counterpart to Solidity's `int32` operator.
     *
     * Requirements:
     *
     * - input must fit into 32 bits
     *
     * _Available since v3.1._
     */
    function toInt32(int256 value) internal pure returns (int32 downcasted) {
        downcasted = int32(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 32 bits");
    }

    /**
     * @dev Returns the downcasted int24 from int256, reverting on
     * overflow (when the input is less than smallest int24 or
     * greater than largest int24).
     *
     * Counterpart to Solidity's `int24` operator.
     *
     * Requirements:
     *
     * - input must fit into 24 bits
     *
     * _Available since v4.7._
     */
    function toInt24(int256 value) internal pure returns (int24 downcasted) {
        downcasted = int24(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 24 bits");
    }

    /**
     * @dev Returns the downcasted int16 from int256, reverting on
     * overflow (when the input is less than smallest int16 or
     * greater than largest int16).
     *
     * Counterpart to Solidity's `int16` operator.
     *
     * Requirements:
     *
     * - input must fit into 16 bits
     *
     * _Available since v3.1._
     */
    function toInt16(int256 value) internal pure returns (int16 downcasted) {
        downcasted = int16(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 16 bits");
    }

    /**
     * @dev Returns the downcasted int8 from int256, reverting on
     * overflow (when the input is less than smallest int8 or
     * greater than largest int8).
     *
     * Counterpart to Solidity's `int8` operator.
     *
     * Requirements:
     *
     * - input must fit into 8 bits
     *
     * _Available since v3.1._
     */
    function toInt8(int256 value) internal pure returns (int8 downcasted) {
        downcasted = int8(value);
        require(downcasted == value, "SafeCast: value doesn't fit in 8 bits");
    }

    /**
     * @dev Converts an unsigned uint256 into a signed int256.
     *
     * Requirements:
     *
     * - input must be less than or equal to maxInt256.
     *
     * _Available since v3.0._
     */
    function toInt256(uint256 value) internal pure returns (int256) {
        // Note: Unsafe cast below is okay because `type(int256).max` is guaranteed to be positive
        require(value <= uint256(type(int256).max), "SafeCast: value doesn't fit in an int256");
        return int256(value);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (utils/structs/DoubleEndedQueue.sol)
pragma solidity ^0.8.4;

import "../math/SafeCast.sol";

/**
 * @dev A sequence of items with the ability to efficiently push and pop items (i.e. insert and remove) on both ends of
 * the sequence (called front and back). Among other access patterns, it can be used to implement efficient LIFO and
 * FIFO queues. Storage use is optimized, and all operations are O(1) constant time. This includes {clear}, given that
 * the existing queue contents are left in storage.
 *
 * The struct is called `Bytes32Deque`. Other types can be cast to and from `bytes32`. This data structure can only be
 * used in storage, and not in memory.
 * ```
 * DoubleEndedQueue.Bytes32Deque queue;
 * ```
 *
 * _Available since v4.6._
 */
library DoubleEndedQueue {
    /**
     * @dev An operation (e.g. {front}) couldn't be completed due to the queue being empty.
     */
    error Empty();

    /**
     * @dev An operation (e.g. {at}) couldn't be completed due to an index being out of bounds.
     */
    error OutOfBounds();

    /**
     * @dev Indices are signed integers because the queue can grow in any direction. They are 128 bits so begin and end
     * are packed in a single storage slot for efficient access. Since the items are added one at a time we can safely
     * assume that these 128-bit indices will not overflow, and use unchecked arithmetic.
     *
     * Struct members have an underscore prefix indicating that they are "private" and should not be read or written to
     * directly. Use the functions provided below instead. Modifying the struct manually may violate assumptions and
     * lead to unexpected behavior.
     *
     * Indices are in the range [begin, end) which means the first item is at data[begin] and the last item is at
     * data[end - 1].
     */
    struct Bytes32Deque {
        int128 _begin;
        int128 _end;
        mapping(int128 => bytes32) _data;
    }

    /**
     * @dev Inserts an item at the end of the queue.
     */
    function pushBack(Bytes32Deque storage deque, bytes32 value) internal {
        int128 backIndex = deque._end;
        deque._data[backIndex] = value;
        unchecked {
            deque._end = backIndex + 1;
        }
    }

    /**
     * @dev Removes the item at the end of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popBack(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        value = deque._data[backIndex];
        delete deque._data[backIndex];
        deque._end = backIndex;
    }

    /**
     * @dev Inserts an item at the beginning of the queue.
     */
    function pushFront(Bytes32Deque storage deque, bytes32 value) internal {
        int128 frontIndex;
        unchecked {
            frontIndex = deque._begin - 1;
        }
        deque._data[frontIndex] = value;
        deque._begin = frontIndex;
    }

    /**
     * @dev Removes the item at the beginning of the queue and returns it.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function popFront(Bytes32Deque storage deque) internal returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        value = deque._data[frontIndex];
        delete deque._data[frontIndex];
        unchecked {
            deque._begin = frontIndex + 1;
        }
    }

    /**
     * @dev Returns the item at the beginning of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function front(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 frontIndex = deque._begin;
        return deque._data[frontIndex];
    }

    /**
     * @dev Returns the item at the end of the queue.
     *
     * Reverts with `Empty` if the queue is empty.
     */
    function back(Bytes32Deque storage deque) internal view returns (bytes32 value) {
        if (empty(deque)) revert Empty();
        int128 backIndex;
        unchecked {
            backIndex = deque._end - 1;
        }
        return deque._data[backIndex];
    }

    /**
     * @dev Return the item at a position in the queue given by `index`, with the first item at 0 and last item at
     * `length(deque) - 1`.
     *
     * Reverts with `OutOfBounds` if the index is out of bounds.
     */
    function at(Bytes32Deque storage deque, uint256 index) internal view returns (bytes32 value) {
        // int256(deque._begin) is a safe upcast
        int128 idx = SafeCast.toInt128(int256(deque._begin) + SafeCast.toInt256(index));
        if (idx >= deque._end) revert OutOfBounds();
        return deque._data[idx];
    }

    /**
     * @dev Resets the queue back to being empty.
     *
     * NOTE: The current items are left behind in storage. This does not affect the functioning of the queue, but misses
     * out on potential gas refunds.
     */
    function clear(Bytes32Deque storage deque) internal {
        deque._begin = 0;
        deque._end = 0;
    }

    /**
     * @dev Returns the number of items in the queue.
     */
    function length(Bytes32Deque storage deque) internal view returns (uint256) {
        // The interface preserves the invariant that begin <= end so we assume this will not overflow.
        // We also assume there are at most int256.max items in the queue.
        unchecked {
            return uint256(int256(deque._end) - int256(deque._begin));
        }
    }

    /**
     * @dev Returns true if the queue is empty.
     */
    function empty(Bytes32Deque storage deque) internal view returns (bool) {
        return deque._end <= deque._begin;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeAware, ISafe} from "./SafeAware.sol";
import {IModuleMetadata} from "./interfaces/IModuleMetadata.sol";

// When the base contract (implementation) that proxies use is created,
// we use this no-op address when an address is needed to make contracts initialized but unusable
address constant IMPL_INIT_NOOP_ADDR = address(1);
ISafe constant IMPL_INIT_NOOP_SAFE = ISafe(payable(IMPL_INIT_NOOP_ADDR));

/**
 * @title EIP1967Upgradeable
 * @dev Minimal implementation of EIP-1967 allowing upgrades of itself by a Safe transaction
 * @dev Note that this contract doesn't have have an initializer as the implementation
 * address must already be set in the correct slot (in our case, the proxy does on creation)
 */
abstract contract EIP1967Upgradeable is SafeAware {
    event Upgraded(IModuleMetadata indexed implementation, string moduleId, uint256 version);

    // EIP1967_IMPL_SLOT = keccak256('eip1967.proxy.implementation') - 1
    bytes32 internal constant EIP1967_IMPL_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
    address internal constant IMPL_CONTRACT_FLAG = address(0xffff);

    // As the base contract doesn't use the implementation slot,
    // set a flag in that slot so that it is possible to detect it
    constructor() {
        address implFlag = IMPL_CONTRACT_FLAG;
        assembly {
            sstore(EIP1967_IMPL_SLOT, implFlag)
        }
    }

    /**
     * @notice Upgrades the proxy to a new implementation address
     * @dev The new implementation should be a contract that implements a way to perform upgrades as well
     * otherwise the proxy will freeze on that implementation forever, since the proxy doesn't contain logic to change it.
     * It also must conform to the IModuleMetadata interface (this is somewhat of an implicit guard against bad upgrades)
     * @param _newImplementation The address of the new implementation address the proxy will use
     */
    function upgrade(IModuleMetadata _newImplementation) public onlySafe {
        assembly {
            sstore(EIP1967_IMPL_SLOT, _newImplementation)
        }

        emit Upgraded(_newImplementation, _newImplementation.moduleId(), _newImplementation.moduleVersion());
    }

    function _implementation() internal view returns (IModuleMetadata impl) {
        assembly {
            impl := sload(EIP1967_IMPL_SLOT)
        }
    }

    /**
     * @dev Checks whether the context is foreign to the implementation
     * or the proxy by checking the EIP-1967 implementation slot.
     * If we were running in proxy context, the impl address would be stored there
     * If we were running in impl conext, the IMPL_CONTRACT_FLAG would be stored there
     */
    function _isForeignContext() internal view returns (bool) {
        return address(_implementation()) == address(0);
    }

    function _isImplementationContext() internal view returns (bool) {
        return address(_implementation()) == IMPL_CONTRACT_FLAG;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeAware} from "./SafeAware.sol";

/**
 * @dev Context variant with ERC2771 support.
 * Copied and modified from https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/metatx/ERC2771Context.sol (MIT licensed)
 */
abstract contract ERC2771Context is SafeAware {
    // SAFE_SLOT = keccak256("firm.erc2271context.forwarders") - 1
    bytes32 internal constant ERC2271_TRUSTED_FORWARDERS_BASE_SLOT =
        0xde1482070091aef895249374204bcae0fa9723215fa9357228aa489f9d1bd669;

    event TrustedForwarderSet(address indexed forwarder, bool enabled);

    function setTrustedForwarder(address forwarder, bool enabled) external onlySafe {
        _setTrustedForwarder(forwarder, enabled);
    }

    function _setTrustedForwarder(address forwarder, bool enabled) internal {
        _trustedForwarders()[forwarder] = enabled;

        emit TrustedForwarderSet(forwarder, enabled);
    }

    function isTrustedForwarder(address forwarder) public view virtual returns (bool) {
        return _trustedForwarders()[forwarder];
    }

    function _msgSender() internal view virtual override returns (address sender) {
        if (isTrustedForwarder(msg.sender)) {
            // The assembly code is more direct than the Solidity version using `abi.decode`.
            /// @solidity memory-safe-assembly
            assembly {
                sender := shr(96, calldataload(sub(calldatasize(), 20)))
            }
        } else {
            return msg.sender;
        }
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        if (isTrustedForwarder(msg.sender)) {
            return msg.data[:msg.data.length - 20];
        } else {
            return msg.data;
        }
    }

    function _trustedForwarders() internal pure returns (mapping(address => bool) storage trustedForwarders) {
        assembly {
            trustedForwarders.slot := ERC2271_TRUSTED_FORWARDERS_BASE_SLOT
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISafe} from "./interfaces/ISafe.sol";
import {ERC2771Context} from "./ERC2771Context.sol";
import {EIP1967Upgradeable, IMPL_INIT_NOOP_ADDR, IMPL_INIT_NOOP_SAFE} from "./EIP1967Upgradeable.sol";
import {IModuleMetadata} from "./interfaces/IModuleMetadata.sol";

abstract contract FirmBase is EIP1967Upgradeable, ERC2771Context, IModuleMetadata {
    event Initialized(ISafe indexed safe, IModuleMetadata indexed implementation);

    function __init_firmBase(ISafe safe_, address trustedForwarder_) internal {
        // checks-effects-interactions violated so that the init event always fires first
        emit Initialized(safe_, _implementation());

        __init_setSafe(safe_);
        if (trustedForwarder_ != address(0) || trustedForwarder_ != IMPL_INIT_NOOP_ADDR) {
            _setTrustedForwarder(trustedForwarder_, true);
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {AddressUint8FlagsLib} from "./utils/AddressUint8FlagsLib.sol";

import {IRoles} from "../roles/interfaces/IRoles.sol";

uint8 constant ROLES_FLAG_TYPE = 0x01;

abstract contract RolesAuth {
    using AddressUint8FlagsLib for address;

    // ROLES_SLOT = keccak256("firm.rolesauth.roles") - 1
    bytes32 internal constant ROLES_SLOT = 0x7aaf26e54f46558e57a4624b01631a5da30fe5fe9ba2f2500c3aee185f8fb90b;

    function roles() public view returns (IRoles rolesAddr) {
        assembly {
            rolesAddr := sload(ROLES_SLOT)
        }
    }

    function _setRoles(IRoles roles_) internal {
        assembly {
            sstore(ROLES_SLOT, roles_)
        }
    }

    error UnexistentRole(uint8 roleId);

    function _validateAuthorizedAddress(address authorizedAddr) internal view {
        if (authorizedAddr.isFlag(ROLES_FLAG_TYPE)) {
            uint8 roleId = authorizedAddr.flagValue();
            if (!roles().roleExists(roleId)) {
                revert UnexistentRole(roleId);
            }
        }
    }

    function _isAuthorized(address actor, address authorizedAddr) internal view returns (bool) {
        if (authorizedAddr.isFlag(ROLES_FLAG_TYPE)) {
            return roles().hasRole(actor, authorizedAddr.flagValue());
        } else {
            return actor == authorizedAddr;
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {ISafe} from "./interfaces/ISafe.sol";

/**
 * @title SafeAware
 * @dev Base contract for Firm components that need to be aware of a Safe
 * as their admin
 */
abstract contract SafeAware {
    // SAFE_SLOT = keccak256("firm.safeaware.safe") - 1
    bytes32 internal constant SAFE_SLOT = 0xb2c095c1a3cccf4bf97d6c0d6a44ba97fddb514f560087d9bf71be2c324b6c44;

    /**
     * @notice Address of the Safe that this module is tied to
     */
    function safe() public view returns (ISafe safeAddr) {
        assembly {
            safeAddr := sload(SAFE_SLOT)
        }
    }

    error SafeAddressZero();
    error AlreadyInitialized();

    /**
     * @dev Contracts that inherit from SafeAware, including derived contracts as
     * EIP1967Upgradeable or Safe, should call this function on initialization
     * Will revert if called twice
     * @param _safe The address of the GnosisSafe to use, won't be modifiable unless
     * implicitly implemented by the derived contract, which is not recommended
     */
    function __init_setSafe(ISafe _safe) internal {
        if (address(_safe) == address(0)) {
            revert SafeAddressZero();
        }
        if (address(safe()) != address(0)) {
            revert AlreadyInitialized();
        }
        assembly {
            sstore(SAFE_SLOT, _safe)
        }
    }

    error UnauthorizedNotSafe();
    /**
     * @dev Modifier to be used by derived contracts to limit access control to priviledged
     * functions so they can only be called by the Safe
     */
    modifier onlySafe() {
        if (_msgSender() != address(safe())) {
            revert UnauthorizedNotSafe();
        }

        _;
    }

    function _msgSender() internal view virtual returns (address sender); 
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {FirmBase} from "./FirmBase.sol";
import {ISafe} from "./interfaces/ISafe.sol";

/**
 * @title SafeModule
 * @dev More minimal implementation of Safe's Module.sol without an owner
 * and using unstructured storage
 * @dev Note that this contract doesn't have an initializer and SafeState
 * must be set explicly if desired, but defaults to being unset
 */
abstract contract SafeModule is FirmBase {
    error BadExecutionContext();

    // Sometimes it makes sense to have some code from the module ran on the Safe context
    // via a DelegateCall operation.
    // Since the functions the Safe can enter through have to be external,
    // we need to ensure that we aren't in the context of the module (or it's implementation)
    // for extra security
    // NOTE: this would break if Safe were to start using the EIP-1967 implementation slot
    // as it is how foreign context detection works
    modifier onlyForeignContext() {
        if (!_isForeignContext()) {
            revert BadExecutionContext();
        }
        _;
    }

    /**
     * @dev Executes a transaction through the target intended to be executed by the avatar
     * @param to Address being called
     * @param value Ether value being sent
     * @param data Calldata
     * @param operation Operation type of transaction: 0 = call, 1 = delegatecall
     */
    function _moduleExec(address to, uint256 value, bytes memory data, ISafe.Operation operation)
        internal
        returns (bool success)
    {
        return safe().execTransactionFromModule(to, value, data, operation);
    }

    /**
     * @dev Executes a transaction through the target intended to be executed by the avatar
     * and returns the call status and the return data of the call
     * @param to Address being called
     * @param value Ether value being sent
     * @param data Calldata
     * @param operation Operation type of transaction: 0 = call, 1 = delegatecall
     */
    function _moduleExecAndReturnData(address to, uint256 value, bytes memory data, ISafe.Operation operation)
        internal
        returns (bool success, bytes memory returnData)
    {
        return safe().execTransactionFromModuleReturnData(to, value, data, operation);
    }

    function _moduleExecDelegateCallToSelf(bytes memory data) internal returns (bool success) {
        return _moduleExec(address(_implementation()), 0, data, ISafe.Operation.DelegateCall);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {SafeAware} from "./SafeAware.sol";

import {ISemaphore} from "../semaphore/interfaces/ISemaphore.sol";

ISemaphore constant NO_SEMAPHORE = ISemaphore(address(0));
abstract contract SemaphoreAuth is SafeAware {
    // SEMAPHORE_SLOT = keccak256("firm.semaphoreauth.semaphore") - 1
    bytes32 internal constant SEMAPHORE_SLOT = 0x3e4ab72c2ecd29625ea852b1de3f6381681f0f5fb2b0bab359fabdd96dbc1b94;

    event SemaphoreSet(ISemaphore semaphore);

    function semaphore() public view returns (ISemaphore semaphoreAddr) {
        assembly {
            semaphoreAddr := sload(SEMAPHORE_SLOT)
        }
    }

    function setSemaphore(ISemaphore semaphore_) public onlySafe {
        _setSemaphore(semaphore_);
    }

    function _setSemaphore(ISemaphore semaphore_) internal {
        assembly {
            sstore(SEMAPHORE_SLOT, semaphore_)
        }
        emit SemaphoreSet(semaphore_);
    }

    function _semaphoreCheckCall(address target, uint256 value, bytes memory data, bool isDelegateCall) internal view {
        ISemaphore semaphore_ = semaphore();
        if (semaphore_ != NO_SEMAPHORE &&
            !semaphore_.canPerform(address(this), target, value, data, isDelegateCall)
        ) {
            revert ISemaphore.SemaphoreDisallowed();
        }
    }

    function _semaphoreCheckCalls(address[] memory targets, uint256[] memory values, bytes[] memory datas, bool isDelegateCall) internal view {
        ISemaphore semaphore_ = semaphore();
        if (semaphore_ != NO_SEMAPHORE &&
            !semaphore_.canPerformMany(address(this), targets, values, datas, isDelegateCall)
        ) {
            revert ISemaphore.SemaphoreDisallowed();
        }
    }

    function _filterCallsToTarget(
        address filteredTarget,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas
    ) internal pure returns (address[] memory, uint256[] memory, bytes[] memory) {
        uint256 filteringCalls;
        for (uint256 i = 0; i < targets.length;) {
            if (targets[i] == filteredTarget) {
                filteringCalls++;
            }
            unchecked {
                i++;
            }
        }

        if (filteringCalls == 0) {
            return (targets, values, calldatas);
        }

        if (filteringCalls == targets.length) {
            return (new address[](0), new uint256[](0), new bytes[](0));
        }

        uint256 filteredCalls = 0;

        address[] memory filteredTargets = new address[](targets.length - filteringCalls);
        uint256[] memory filteredValues = new uint256[](values.length - filteringCalls);
        bytes[] memory filteredCalldatas = new bytes[](calldatas.length - filteringCalls);

        for (uint256 i = 0; i < targets.length;) {
            if (targets[i] == filteredTarget) {
                unchecked {
                    i++;
                }
                continue;
            }

            filteredTargets[filteredCalls] = targets[i];
            filteredValues[filteredCalls] = values[i];
            filteredCalldatas[filteredCalls] = calldatas[i];

            unchecked {
                i++;
                filteredCalls++;
            }
        }

        return (filteredTargets, filteredValues, filteredCalldatas);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IModuleMetadata {
    function moduleId() external pure returns (string memory);
    function moduleVersion() external pure returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Minimum viable interface of a Safe that Firm's protocol needs
interface ISafe {
    enum Operation {
        Call,
        DelegateCall
    }

    receive() external payable;

    /**
     * @dev Allows modules to execute transactions
     * @notice Can only be called by an enabled module.
     * @notice Must emit ExecutionFromModuleSuccess(address module) if successful.
     * @notice Must emit ExecutionFromModuleFailure(address module) if unsuccessful.
     * @param to Destination address of module transaction.
     * @param value Ether value of module transaction.
     * @param data Data payload of module transaction.
     * @param operation Operation type of module transaction: 0 == call, 1 == delegate call.
     */
    function execTransactionFromModule(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success);

    function execTransactionFromModuleReturnData(address to, uint256 value, bytes memory data, Operation operation)
        external
        returns (bool success, bytes memory returnData);

    /**
     * @dev Returns if a certain address is an owner of this Safe
     * @return Whether the address is an owner or not
     */
    function isOwner(address owner) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

library AddressUint8FlagsLib {
    // Address uint8 flag format: 0x00..00[flag uint8 byte][type of flag byte]

    // - The last byte of the address is used to signal the type of flag
    // - The second to last to store the specific uint8 being flagged
    // - All other bytes in the address must be 0
    uint256 internal constant ADDR_UINT8_FLAG_MASK = ~uint160(0xFF00);

    function isFlag(address addr, uint8 flagType) internal pure returns (bool) {
        // An address 0x00...00[roleId byte]01 is interpreted as a flag for flagType=0x01
        // Eg. In the case of roles, 0x0000000000000000000000000000000000000201 flags roleId=2
        // Therefore if any other byte other than the roleId byte or the 0x01 byte
        // is set, it will be considered not to be a valid role flag
        return (uint256(uint160(addr)) & ADDR_UINT8_FLAG_MASK) == uint256(flagType);
    }

    function flagValue(address addr) internal pure returns (uint8) {
        return uint8(uint160(addr) >> 8);
    }

    function toFlag(uint8 value, uint8 flagType) internal pure returns (address) {
        return address(uint160(uint256(value) << 8) + flagType);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {IERC20} from "openzeppelin/interfaces/IERC20.sol";
import {SafeERC20} from "openzeppelin/token/ERC20/utils/SafeERC20.sol";

import {FirmBase, IMPL_INIT_NOOP_ADDR, IMPL_INIT_NOOP_SAFE} from "../bases/FirmBase.sol";
import {SafeModule, ISafe} from "../bases/SafeModule.sol";
import {IRoles, RolesAuth} from "../bases/RolesAuth.sol";

import {TimeShiftLib, EncodedTimeShift} from "./TimeShiftLib.sol";

address constant NATIVE_ASSET = address(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);
uint256 constant NO_PARENT_ID = 0;
uint256 constant INHERITED_AMOUNT = 0;
uint40 constant INHERITED_RESET_TIME = 0;

/**
 * @title Budget
 * @author Firm ([email protected])
 * @notice Budgeting module for efficient spending from a Safe using allowance chains
 * to delegate spending authority
 */
contract Budget is FirmBase, SafeModule, RolesAuth {
    string public constant moduleId = "org.firm.budget";
    uint256 public constant moduleVersion = 1;

    using TimeShiftLib for uint40;
    using SafeERC20 for IERC20;

    struct Allowance {
        uint256 parentId;
        uint256 amount;
        uint256 spent;
        address token;
        uint40 nextResetTime;
        address spender;
        EncodedTimeShift recurrency;
        bool isDisabled;
    }

    mapping(uint256 => Allowance) public allowances;
    uint256 public allowancesCount;

    event AllowanceCreated(
        uint256 indexed allowanceId,
        uint256 indexed parentAllowanceId,
        address indexed spender,
        address token,
        uint256 amount,
        EncodedTimeShift recurrency,
        uint40 nextResetTime,
        string name
    );
    event AllowanceStateChanged(uint256 indexed allowanceId, bool isEnabled);
    event AllowanceAmountChanged(uint256 allowanceId, uint256 amount);
    event AllowanceSpenderChanged(uint256 allowanceId, address spender);
    event AllowanceNameChanged(uint256 allowanceId, string name);
    event PaymentExecuted(
        uint256 indexed allowanceId,
        address indexed actor,
        address token,
        address indexed to,
        uint256 amount,
        uint40 nextResetTime,
        string description
    );
    event MultiPaymentExecuted(
        uint256 indexed allowanceId,
        address indexed actor,
        address token,
        address[] tos,
        uint256[] amounts,
        uint40 nextResetTime,
        string description
    );
    event AllowanceDebited(
        uint256 indexed allowanceId,
        address indexed actor,
        address token,
        uint256 amount,
        uint40 nextResetTime,
        bytes description
    );

    error UnexistentAllowance(uint256 allowanceId);
    error DisabledAllowance(uint256 allowanceId);
    error UnauthorizedNotAllowanceAdmin(uint256 allowanceId);
    error TokenMismatch(address patentToken, address childToken);
    error InheritedAmountNotAllowed();
    error ZeroAmountPayment();
    error BadInput();
    error UnauthorizedPaymentExecution(uint256 allowanceId, address actor);
    error Overbudget(uint256 allowanceId, uint256 amount, uint256 remainingBudget);
    error PaymentExecutionFailed(uint256 allowanceId, address token, address to, uint256 amount);
    error NativeValueMismatch();

    constructor() {
        // Initialize with impossible values in constructor so impl base cannot be used
        initialize(IMPL_INIT_NOOP_SAFE, IRoles(IMPL_INIT_NOOP_ADDR), IMPL_INIT_NOOP_ADDR);
    }

    function initialize(ISafe safe_, IRoles roles_, address trustedForwarder_) public {
        // calls SafeAware.__init_setSafe which reverts on reinitialization
        __init_firmBase(safe_, trustedForwarder_);
        _setRoles(roles_);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // ALLOWANCE MANAGEMENT
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Creates a new allowance giving permission to spend funds from the Safe to a given address or addresses with a certain role
     * @dev Note 1: that child allowances can be greater than the allowed amount of its parent budget and have different recurrency
     * Note 2: It is possible to create child allowances for allowances that are disabled (either its parent disabled or any of its ancestors up to the top-level)
     * @param parentAllowanceId ID for the parent allowance (value is 0 for top-level allowances without dependencies)
     * @param spender Address or role identifier of the entities authorized to execute payments from this allowance
     * @param token Address of the token (must be the same as the parent's token)
     * @param amount Amount of token that can be spent per period
     * @param recurrency Unit of time for the allowance spent amount to be reset (value is 0 for the allowance to inherit its parent's recurrency)
     * @param name Name of the allowance being created
     * @return allowanceId ID of the allowance created
     */
    function createAllowance(
        uint256 parentAllowanceId,
        address spender,
        address token,
        uint256 amount,
        EncodedTimeShift recurrency,
        string memory name
    ) public returns (uint256 allowanceId) {
        uint40 nextResetTime;

        if (spender == address(0) || token == address(0)) {
            revert BadInput();
        }

        if (parentAllowanceId == NO_PARENT_ID) {
            // Top-level allowances can only be created by the Safe
            if (_msgSender() != address(safe())) {
                revert UnauthorizedNotSafe();
            }

            // We don't allow setting inherited amounts on top-level allowances as
            // it could be prone to a client-side mistake to send 0 as the amount which will
            // will create an allowance that allows completely wiping the safe (for the token)
            if (amount == INHERITED_AMOUNT) {
                revert InheritedAmountNotAllowed();
            }

            // For top-level allowances, recurrency needs to be set and cannot be zero (inherited)
            // applyShift reverts with InvalidTimeShift if recurrency is unspecified
            // Therefore, nextResetTime is always greater than the current time
            nextResetTime = uint40(block.timestamp).applyShift(recurrency);
        } else {
            // Reverts if parentAllowanceId doesn't exist
            Allowance storage parentAllowance = _getAllowance(parentAllowanceId);

            // Not checking whether the parentAllowance is enabled is an explicit decision
            // Disabling any allowance in a given allowance chain will result in all its
            // children not being able to execute payments
            // This allows for disabling a certain allowance to reconfigure the whole tree
            // of sub-allowances below it, before enabling it again

            // Sub-allowances can be created by entities authorized to spend from a particular allowance
            if (!_isAuthorized(_msgSender(), parentAllowance.spender)) {
                revert UnauthorizedNotAllowanceAdmin(parentAllowanceId);
            }
            if (token != parentAllowance.token) {
                revert TokenMismatch(parentAllowance.token, token);
            }
            // Recurrency can be zero in sub-allowances and is inherited from the parent
            if (!recurrency.isInherited()) {
                // If recurrency is not inherited, amount cannot be inherited
                if (amount == INHERITED_AMOUNT) {
                    revert InheritedAmountNotAllowed();
                }

                // Will revert with InvalidTimeShift if recurrency is invalid
                nextResetTime = uint40(block.timestamp).applyShift(recurrency);
            }
        }

        // Checks that if it is a role flag, a roles instance has been set and the role exists
        _validateAuthorizedAddress(spender);

        unchecked {
            // The index of the first allowance is 1, so NO_PARENT_ID can be 0 (optimization)
            allowanceId = ++allowancesCount;
        }

        Allowance storage allowance = allowances[allowanceId];
        if (parentAllowanceId != NO_PARENT_ID) {
            allowance.parentId = parentAllowanceId;
        }
        if (nextResetTime != INHERITED_RESET_TIME) {
            allowance.recurrency = recurrency;
            allowance.nextResetTime = nextResetTime;
        }
        allowance.spender = spender;
        allowance.token = token;
        allowance.amount = amount;

        emit AllowanceCreated(allowanceId, parentAllowanceId, spender, token, amount, recurrency, nextResetTime, name);
    }

    /**
     * @notice Changes the enabled/disabled state of the allowance
     * @dev Note: Disabling an allowance will implicitly disable payments from all its descendant allowances
     * @param allowanceId ID of the allowance whose state is being changed
     * @param isEnabled Whether to enable or disable the allowance
     */
    function setAllowanceState(uint256 allowanceId, bool isEnabled) external {
        Allowance storage allowance = _getAllowanceAndValidateAdmin(allowanceId);
        allowance.isDisabled = !isEnabled;
        emit AllowanceStateChanged(allowanceId, isEnabled);
    }

    /**
     * @notice Changes the amount that an allowance can spend
     * @dev Note: It is possible to decrease the amount in an allowance to a smaller amount of what's already been spent
     * which will cause the allowance not to be able to execute any more payments until it resets (and the new amount will be enforced)
     * @param allowanceId ID of the allowance whose amount is being changed
     * @param amount New allowance amount to be set
     */
    function setAllowanceAmount(uint256 allowanceId, uint256 amount) external {
        Allowance storage allowance = _getAllowanceAndValidateAdmin(allowanceId);

        // Same checks for what allowances can have an inherited amount as in the creation
        if (amount == INHERITED_AMOUNT && (allowance.parentId == NO_PARENT_ID || !allowance.recurrency.isInherited())) {
            revert InheritedAmountNotAllowed();
        }

        allowance.amount = amount;
        emit AllowanceAmountChanged(allowanceId, amount);
    }

    /**
     * @notice Changes the spender of an allowance
     * @dev Note: Changing the spender also changes who the admin is for all the sub-allowances
     * @param allowanceId ID of the allowance whose spender is being changed
     * @param spender New spender account for the allowance
     */
    function setAllowanceSpender(uint256 allowanceId, address spender) external {
        if (spender == address(0)) {
            revert BadInput();
        }

        _validateAuthorizedAddress(spender);

        Allowance storage allowance = _getAllowanceAndValidateAdmin(allowanceId);
        allowance.spender = spender;
        emit AllowanceSpenderChanged(allowanceId, spender);
    }

    /**
     * @notice Changes the name of an allowance
     * @dev Note: This has no on-chain side-effects and only emits an event for off-chain consumption
     * @param allowanceId ID of the allowance whose name is being changed
     * @param name New name for the allowance
     */
    function setAllowanceName(uint256 allowanceId, string memory name) external {
        _getAllowanceAndValidateAdmin(allowanceId);
        emit AllowanceNameChanged(allowanceId, name);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // PAYMENT EXECUTION
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Executes a payment from an allowance
     * @param allowanceId ID of the allowance from which the payment is made
     * @param to Address that will receive the payment
     * @param amount Amount of the allowance's token being sent
     * @param description Description of the payment
     */
    function executePayment(uint256 allowanceId, address to, uint256 amount, string memory description)
        external
        returns (uint40 nextResetTime)
    {
        Allowance storage allowance = _getAllowance(allowanceId);
        address actor = _msgSender();

        if (!_isAuthorized(actor, allowance.spender)) {
            revert UnauthorizedPaymentExecution(allowanceId, actor);
        }

        if (amount == 0) {
            revert ZeroAmountPayment();
        }

        address token = allowance.token;

        // Make sure the payment is within budget all the way up to its top-level budget
        (nextResetTime,) = _checkAndUpdateAllowanceChain(allowanceId, amount, add);

        if (!_performTransfer(token, to, amount)) {
            revert PaymentExecutionFailed(allowanceId, token, to, amount);
        }

        emit PaymentExecuted(allowanceId, actor, token, to, amount, nextResetTime, description);
    }

    /**
     * @notice Executes multiple payments from an allowance
     * @param allowanceId ID of the allowance from which payments are made
     * @param tos Addresses that will receive the payment
     * @param amounts Amounts of the allowance's token being sent
     * @param description Description of the payments
     */
    function executeMultiPayment(
        uint256 allowanceId,
        address[] calldata tos,
        uint256[] calldata amounts,
        string memory description
    ) external returns (uint40 nextResetTime) {
        Allowance storage allowance = _getAllowance(allowanceId);
        address actor = _msgSender();

        if (!_isAuthorized(actor, allowance.spender)) {
            revert UnauthorizedPaymentExecution(allowanceId, actor);
        }

        uint256 count = tos.length;
        if (count == 0 || count != amounts.length) {
            revert BadInput();
        }

        uint256 totalAmount = 0;
        for (uint256 i = 0; i < count;) {
            if (amounts[i] == 0) {
                revert ZeroAmountPayment();
            }

            totalAmount += amounts[i];

            unchecked {
                i++;
            }
        }

        (nextResetTime,) = _checkAndUpdateAllowanceChain(allowanceId, totalAmount, add);

        address token = allowance.token;
        if (!_performMultiTransfer(token, tos, amounts)) {
            revert PaymentExecutionFailed(allowanceId, token, address(0), totalAmount);
        }

        emit MultiPaymentExecuted(allowanceId, actor, token, tos, amounts, nextResetTime, description);
    }

    /**
     * @notice Deposit funds into safe debiting funds into an allowance. Frequently used to return a payment
     * @dev Anyone is allowed to perform this action, independently of whether they could have spent funds in the first place
     * @param allowanceId ID of the allowance to be debited (along with its ancester tree)
     * @param amount Amount being debited
     * @param description Description of the debit
     */
    function debitAllowance(uint256 allowanceId, uint256 amount, bytes calldata description)
        external
        payable
        returns (uint40 nextResetTime)
    {
        Allowance storage allowance = _getAllowance(allowanceId);
        address actor = _msgSender();
        address payable safeAddr = payable(address(safe()));
        uint256 balanceDelta = 0;

        // Since funds are going to the safe which is trusted we don't need to follow checks-effects-interactions
        // A malicious token could re-enter, but it would only have effects in allowances for that bad token
        // And we don't need to worry about 'callbacks' since the safe is always the receiver and shouldn't do it
        if (allowance.token != NATIVE_ASSET) {
            if (msg.value != 0) {
                revert NativeValueMismatch();
            }

            IERC20 token = IERC20(allowance.token);
            uint256 prevBalance = token.balanceOf(safeAddr);
            token.safeTransferFrom(actor, safeAddr, amount);
            balanceDelta = token.balanceOf(safeAddr) - prevBalance;
        } else {
            if (msg.value != amount) {
                revert NativeValueMismatch();
            }

            safeAddr.transfer(amount);
            balanceDelta = amount; // For native asset transfers, assume balance delta is the amount
        }

        (nextResetTime,) = _checkAndUpdateAllowanceChain(allowanceId, balanceDelta, zeroCappedSub);

        emit AllowanceDebited(allowanceId, actor, allowance.token, amount, nextResetTime, description);
    }

    function _performTransfer(address token, address to, uint256 amount) internal returns (bool) {
        if (token == NATIVE_ASSET) {
            return _moduleExec(to, amount, hex"", ISafe.Operation.Call);
        } else {
            (bool callSuccess, bytes memory retData) =
                _moduleExecAndReturnData(token, 0, abi.encodeCall(IERC20.transfer, (to, amount)), ISafe.Operation.Call);

            return callSuccess && (((retData.length == 32 && abi.decode(retData, (bool))) || retData.length == 0));
        }
    }

    function _performMultiTransfer(address token, address[] calldata tos, uint256[] calldata amounts)
        internal
        returns (bool)
    {
        return _moduleExecDelegateCallToSelf(
            abi.encodeCall(this.__safeContext_performMultiTransfer, (token, tos, amounts))
        );
    }

    function __safeContext_performMultiTransfer(address token, address[] calldata tos, uint256[] calldata amounts)
        external
        onlyForeignContext
    {
        uint256 length = tos.length;

        if (token == NATIVE_ASSET) {
            for (uint256 i = 0; i < length;) {
                (bool callSuccess,) = tos[i].call{value: amounts[i]}(hex"");
                require(callSuccess);
                unchecked {
                    i++;
                }
            }
        } else {
            for (uint256 i = 0; i < length;) {
                (bool callSuccess, bytes memory retData) =
                    token.call(abi.encodeCall(IERC20.transfer, (tos[i], amounts[i])));
                require(callSuccess && (((retData.length == 32 && abi.decode(retData, (bool))) || retData.length == 0)));
                unchecked {
                    i++;
                }
            }
        }
    }

    function _getAllowanceAndValidateAdmin(uint256 allowanceId) internal view returns (Allowance storage allowance) {
        allowance = _getAllowance(allowanceId);
        if (!_isAdminOnAllowance(allowance, _msgSender())) {
            revert UnauthorizedNotAllowanceAdmin(allowance.parentId);
        }
    }

    function _getAllowance(uint256 allowanceId) internal view returns (Allowance storage allowance) {
        allowance = allowances[allowanceId];

        if (allowance.spender == address(0)) {
            revert UnexistentAllowance(allowanceId);
        }
    }

    function isAdminOnAllowance(uint256 allowanceId, address actor) public view returns (bool) {
        return _isAdminOnAllowance(_getAllowance(allowanceId), actor);
    }

    function _isAdminOnAllowance(Allowance storage allowance, address actor) internal view returns (bool) {
        // Changes to the allowance state can be done by the same entity that could
        // create that allowance in the first place (a spender of the parent allowance)
        // In the case of top-level allowances, only the safe can enable/disable them
        // For child allowances, spenders of the parent can change the state of the child
        uint256 parentId = allowance.parentId;
        return parentId == NO_PARENT_ID ? actor == address(safe()) : _isAuthorized(actor, allowances[parentId].spender);
    }

    function _checkAndUpdateAllowanceChain(
        uint256 allowanceId,
        uint256 amount,
        function(uint256, uint256) pure returns (uint256) op
    ) internal returns (uint40 nextResetTime, bool allowanceResets) {
        // Can do 'unsafely' as this function only used when allowanceId always points to an allowance which exists
        // (checked through _getAllowance or a parentId which always exists)
        Allowance storage allowance = allowances[allowanceId];

        if (allowance.isDisabled) {
            revert DisabledAllowance(allowanceId);
        }

        if (allowance.nextResetTime == INHERITED_RESET_TIME) {
            // Note that since top-level allowances are not allowed to have an inherited reset time,
            // this branch is only ever executed for sub-allowances (which always have a parentId)
            (nextResetTime, allowanceResets) = _checkAndUpdateAllowanceChain(allowance.parentId, amount, op);
        } else {
            nextResetTime = allowance.nextResetTime;

            // Reset time has past, so we need to reset the allowance
            if (uint40(block.timestamp) >= nextResetTime) {
                EncodedTimeShift recurrency = allowance.recurrency;
                // For a non-recurrent allowance, after the reset time has passed,
                // the allowance is disabled and cannot be used anymore
                if (recurrency.isNonRecurrent()) {
                    revert DisabledAllowance(allowanceId);
                } else {
                    allowanceResets = true;
                    nextResetTime = uint40(block.timestamp).applyShift(recurrency);
                    allowance.nextResetTime = nextResetTime;
                }
            }

            // Recursively update all parent allowances before checking the amounts (inheritance forces this)
            if (allowance.parentId != NO_PARENT_ID) {
                _checkAndUpdateAllowanceChain(allowance.parentId, amount, op);
            }
        }

        if (allowance.amount != INHERITED_AMOUNT) {
            uint256 spentAfter = op(allowanceResets ? 0 : allowance.spent, amount);
            if (spentAfter > allowance.amount) {
                revert Overbudget(allowanceId, amount, allowance.amount - allowance.spent);
            }

            allowance.spent = spentAfter;
        }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function zeroCappedSub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a - b : 0;
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

// Formal verification for library and formula: https://twitter.com/Zellic_io/status/1510341868021854209
import {BokkyPooBahsDateTimeLibrary as DateTimeLib} from "datetime/BokkyPooBahsDateTimeLibrary.sol";

type EncodedTimeShift is bytes6;

struct TimeShift {
    TimeShiftLib.TimeUnit unit;
    int40 offset;
}

function encode(TimeShift memory shift) pure returns (EncodedTimeShift) {
    return EncodedTimeShift.wrap(bytes6(abi.encodePacked(uint8(shift.unit), shift.offset)));
}

function decode(EncodedTimeShift encoded) pure returns (TimeShiftLib.TimeUnit unit, int40 offset) {
    uint48 encodedValue = uint48(EncodedTimeShift.unwrap(encoded));
    unit = TimeShiftLib.TimeUnit(uint8(encodedValue >> 40));
    offset = int40(uint40(uint48(encodedValue)));
}

// Note this is an efficient way to check for inherited time shifts
// Even if an offset is specified, it will be ignored, but it is still
// considered an inherited time shift
function isInherited(EncodedTimeShift encoded) pure returns (bool) {
    return EncodedTimeShift.unwrap(encoded) < 0x010000000000;
}

// Note this is an efficient way to check for non-recurrent time shifts
// Any value lower than 0x070000000000 is a recurrent time shift
function isNonRecurrent(EncodedTimeShift encoded) pure returns (bool) {
    return EncodedTimeShift.unwrap(encoded) > 0x06ffffffffff;
}

using {decode, isInherited, isNonRecurrent} for EncodedTimeShift global;
using {encode} for TimeShift global;

library TimeShiftLib {
    using TimeShiftLib for *;

    enum TimeUnit {
        Inherit,
        Daily, // 1
        Weekly, // 2
        Monthly, // 3
        Quarterly, // 4
        Semiyearly, // 5
        Yearly, // 6
        NonRecurrent
    }

    error InvalidTimeShift();

    function applyShift(uint40 time, EncodedTimeShift shift) internal pure returns (uint40) {
        (TimeUnit unit, int40 offset) = shift.decode();

        if (unit == TimeUnit.NonRecurrent) {
            // Ensure offset is positive and in the future
            // (We cast to int48 so we don't overflow for any possible uint40 value)
            if (int48(offset) > int48(uint48(time))) {
                return uint40(offset);
            } else {
                revert InvalidTimeShift();
            }
        }

        uint40 realTime = uint40(int40(time) + offset);
        (uint256 y, uint256 m, uint256 d) = realTime.toDate();

        // Gas opt: split branches for shorter paths and handle the most common cases first
        if (uint8(unit) > 3) {
            if (unit == TimeUnit.Yearly) {
                (y, m, d) = (y + 1, 1, 1);
            } else if (unit == TimeUnit.Quarterly) {
                (y, m, d) = m < 10 ? (y, (1 + (m - 1) / 3) * 3 + 1, 1) : (y + 1, 1, 1);
            } else if (unit == TimeUnit.Semiyearly) {
                (y, m, d) = m < 7 ? (y, 7, 1) : (y + 1, 1, 1);
            } else {
                revert InvalidTimeShift();
            }
        } else {
            if (unit == TimeUnit.Monthly) {
                (y, m, d) = m < 12 ? (y, m + 1, 1) : (y + 1, 1, 1);
            } else if (unit == TimeUnit.Weekly) {
                (y, m, d) = addDays(y, m, d, 8 - DateTimeLib.getDayOfWeek(realTime));
            } else if (unit == TimeUnit.Daily) {
                (y, m, d) = addDays(y, m, d, 1);
            } else {
                revert InvalidTimeShift();
            }
        }

        // All time shifts are relative to the beginning of the day UTC before removing the offset
        uint256 shiftedTs = DateTimeLib.timestampFromDateTime(y, m, d, 0, 0, 0);
        return uint40(int40(uint40(shiftedTs)) - offset);
    }

    /**
     * @dev IT WILL ONLY TRANSITION ONE MONTH IF NECESSARY
     */
    function addDays(uint256 y, uint256 m, uint256 d, uint256 daysToAdd)
        private
        pure
        returns (uint256, uint256, uint256)
    {
        uint256 daysInMonth = DateTimeLib._getDaysInMonth(y, m);
        uint256 d2 = d + daysToAdd;

        return d2 <= daysInMonth ? (y, m, d2) : m < 12 ? (y, m + 1, d2 - daysInMonth) : (y + 1, 1, d2 - daysInMonth);
    }

    function toDate(uint40 timestamp) internal pure returns (uint256 y, uint256 m, uint256 d) {
        return DateTimeLib._daysToDate(timestamp / 1 days);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {AddressUint8FlagsLib} from "../bases/utils/AddressUint8FlagsLib.sol";

import {IBouncer} from "./interfaces/IBouncer.sol";

uint8 constant EMBEDDED_BOUNCER_FLAG_TYPE = 0x02;

enum EmbeddedBouncerType {
    DenyAll,
    AllowAll,
    AllowTransferToClassHolder,
    AllowTransferToAllHolders
}

abstract contract BouncerChecker {
    using AddressUint8FlagsLib for address;

    function numberOfClasses() public view virtual returns (uint256);
    function balanceOf(address account, uint256 classId) public view virtual returns (uint256);

    function bouncerAllowsTransfer(IBouncer bouncer, address from, address to, uint256 classId, uint256 amount)
        internal
        view
        returns (bool)
    {
        if (address(bouncer).isFlag(EMBEDDED_BOUNCER_FLAG_TYPE)) {
            EmbeddedBouncerType bouncerType = EmbeddedBouncerType(address(bouncer).flagValue());
            return embeddedBouncerAllowsTransfer(bouncerType, from, to, classId, amount);
        } else {
            return bouncer.isTransferAllowed(from, to, classId, amount);
        }
    }

    function embeddedBouncerAllowsTransfer(
        EmbeddedBouncerType bouncerType,
        address,
        address to,
        uint256 classId,
        uint256
    ) private view returns (bool) {
        if (bouncerType == EmbeddedBouncerType.AllowAll) {
            return true;
        } else if (bouncerType == EmbeddedBouncerType.DenyAll) {
            return false;
        } else if (bouncerType == EmbeddedBouncerType.AllowTransferToClassHolder) {
            return balanceOf(to, classId) > 0;
        } else if (bouncerType == EmbeddedBouncerType.AllowTransferToAllHolders) {
            uint256 count = numberOfClasses();
            for (uint256 i = 0; i < count;) {
                if (balanceOf(to, i) > 0) {
                    return true;
                }
                unchecked {
                    i++;
                }
            }
            return false;
        } else {
            return false;
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {Clones} from "openzeppelin/proxy/Clones.sol";

import {FirmBase, IMPL_INIT_NOOP_SAFE, IMPL_INIT_NOOP_ADDR} from "../bases/FirmBase.sol";
import {ISafe} from "../bases/interfaces/ISafe.sol";

import {EquityToken, ERC20, ERC20Votes} from "./EquityToken.sol";
import {ICaptableVotes} from "./interfaces/ICaptableVotes.sol";
import {BouncerChecker} from "./BouncerChecker.sol";
import {IBouncer} from "./interfaces/IBouncer.sol";
import {IAccountController} from "./controllers/AccountController.sol";

uint32 constant NO_CONVERSION_FLAG = type(uint32).max;
IAccountController constant NO_CONTROLLER = IAccountController(address(0));

/*
THE TRANSFER OF THE SECURITIES REFERENCED HEREIN IS SUBJECT TO CERTAIN TRANSFER
RESTRICTIONS SET FORTH IN THE COMPANY’S BYLAWS, WHICH MAY BE OBTAINED UPON
WRITTEN REQUEST TO THE COMPANY AT ITS DESIGNATED ELECTRONIC ADDRESS.
THE COMPANY SHALL NOT REGISTER OR OTHERWISE RECOGNIZE OR GIVE EFFECT TO ANY
PURPORTED TRANSFER OF SECURITIES THAT DOES NOT COMPLY WITH SUCH TRANSFER RESTRICTIONS.*/

/**
 * @title Captable
 * @author Firm ([email protected])
 * @notice Captable manages ownership and voting rights in a company, controlling
 * a set of equity tokens representing classes of stock
 */
contract Captable is FirmBase, BouncerChecker, ICaptableVotes {
    string public constant moduleId = "org.firm.captable";
    uint256 public constant moduleVersion = 1;

    using Clones for address;

    struct Class {
        EquityToken token;
        uint16 votingWeight;
        uint32 convertsToClassId;
        uint128 authorized;
        uint128 convertible;
        string name;
        string ticker;
        IBouncer bouncer;
        bool isFrozen;
        mapping(address => bool) isManager;
    }

    mapping(uint256 => Class) public classes;
    uint256 internal classCount;

    mapping(address => mapping(uint256 => IAccountController)) public controllers;

    string public name;

    // Above this limit, voting power getters that iterate through all tokens become
    // very expensive. See `CaptableClassLimitTest` tests for worst-case benchmarks
    uint32 internal constant CLASSES_LIMIT = 128;

    address internal immutable equityTokenImpl;

    event ClassCreated(
        uint256 indexed classId,
        EquityToken indexed token,
        string name,
        string ticker,
        uint128 authorized,
        uint32 convertsToClassId,
        uint16 votingWeight,
        IBouncer indexed bouncer
    );
    event AuthorizedChanged(uint256 indexed classId, uint128 authorized);
    event ConvertibleChanged(uint256 indexed classId, uint128 convertible);
    event ClassManagerSet(uint256 indexed classId, address indexed manager, bool isManager);
    event ClassFrozen(uint256 indexed classId);
    event BouncerChanged(uint256 indexed classId, IBouncer indexed bouncer);
    event Issued(address indexed to, uint256 indexed classId, uint256 amount, address indexed actor);
    event Converted(address indexed account, uint256 indexed fromClassId, uint256 toClassId, uint256 amount);
    event ControllerSet(address indexed account, uint256 indexed classId, IAccountController indexed controller);
    event ForcedTransfer(
        address indexed from, address indexed to, uint256 classId, uint256 amount, address actor, string reason
    );

    error ClassCreationAboveLimit();
    error UnexistentClass(uint256 classId);
    error BadInput();
    error FrozenClass(uint256 classId);
    error TransferBlocked(IBouncer bouncer, address from, address to, uint256 classId, uint256 amount);
    error ConversionBlocked(IAccountController controller, address account, uint256 classId, uint256 amount);
    error UnauthorizedNotController(uint256 classId);
    error IssuedOverAuthorized(uint256 classId);
    error ConvertibleOverAuthorized(uint256 classId);
    error UnauthorizedNotManager(uint256 classId);
    error AccountIsNonHolder(address account, uint256 classId);

    constructor() {
        initialize("", IMPL_INIT_NOOP_SAFE, IMPL_INIT_NOOP_ADDR);
        equityTokenImpl = address(new EquityToken());
    }

    function initialize(string memory name_, ISafe safe_, address trustedForwarder_) public {
        // calls SafeAware.__init_setSafe which reverts on reinitialization
        __init_firmBase(safe_, trustedForwarder_);
        name = name_;
    }

    /**
     * @notice Creates a new class of equity
     * @dev For gas reasons only 128 classes of equity can be created at the moment
     * @param className Name of the class (cannot be changed later)
     * @param ticker Ticker of the class (cannot be changed later)
     * @param authorized Number of shares authorized for issuance (must be > 0)
     *        It has to fit in the authorized amount of the class it converts into
     * @param convertsToClassId ID of the class that holders can convert to (NO_CONVERSION_FLAG if none)
     * @param votingWeight Voting weight of the class (will be multiplied by balance when checking votes)
     * @param bouncer Bouncer that will be used to check transfers
     *        It cannot be zero. For allow all transfers, use `EmbeddedBouncerType.AllowAll` (addrFlag=0x00..0102)
     * @return classId ID of the newly created class
     * @return token Token contract of the newly created class
     */
    function createClass(
        string calldata className,
        string calldata ticker,
        uint128 authorized,
        uint32 convertsToClassId,
        uint16 votingWeight,
        IBouncer bouncer
    ) external onlySafe returns (uint256 classId, EquityToken token) {
        if (authorized == 0 || address(bouncer) == address(0)) {
            revert BadInput();
        }
        unchecked {
            if ((classId = classCount++) >= CLASSES_LIMIT) {
                revert ClassCreationAboveLimit();
            }
        }

        // When creating the first class, unless convertsToClassId == NO_CONVERSION_FLAG,
        // this will implicitly revert, since there's no convertsToClassId for which
        // _getClass() won't revert (_getClass() is called within _changeConvertibleAmount())
        if (convertsToClassId != NO_CONVERSION_FLAG) {
            _changeConvertibleAmount(convertsToClassId, authorized, true);
        }

        // Deploys token with a non-upgradeable EIP-1967 token
        // Doesn't use create2 since the salt would just be the classId and this account's nonce is just as good
        token = EquityToken(equityTokenImpl.clone());
        token.initialize(this, uint32(classId));

        address safe = _msgSender(); // since the onlySafe modifier is used, this is the safe address
        Class storage class = classes[classId];
        class.token = token;
        class.votingWeight = votingWeight;
        class.authorized = authorized;
        class.name = className;
        class.ticker = ticker;
        class.convertsToClassId = convertsToClassId;
        class.bouncer = bouncer;
        class.isManager[safe] = true; // safe addr is set as manager for class

        emit ClassCreated(classId, token, className, ticker, authorized, convertsToClassId, votingWeight, bouncer);
        emit ClassManagerSet(classId, safe, true);
    }

    /**
     * @notice Sets the amount of authorized shares for the class
     * @dev The amount of authorized shares can only be decreased if the amount of issued shares
     *      plus the convertible amount doesn't exceed the new authorized amount
     * @param classId ID of the class
     * @param newAuthorized New authorized amount
     */
    function setAuthorized(uint256 classId, uint128 newAuthorized) external onlySafe {
        if (newAuthorized == 0) {
            revert BadInput();
        }

        Class storage class = _getClass(classId);
        _ensureClassNotFrozen(class, classId);

        uint128 oldAuthorized = class.authorized;
        bool isDecreasing = newAuthorized < oldAuthorized;

        // When decreasing the authorized amount, make sure that the issued amount
        // plus the convertible amount doesn't exceed the new authorized amount
        if (isDecreasing) {
            if (_issuedFor(class) + class.convertible > newAuthorized) {
                revert IssuedOverAuthorized(classId);
            }
        }

        // If the class converts into another class, update the convertible amount of that class
        if (class.convertsToClassId != NO_CONVERSION_FLAG) {
            uint128 delta = isDecreasing ? oldAuthorized - newAuthorized : newAuthorized - oldAuthorized;
            _changeConvertibleAmount(class.convertsToClassId, delta, !isDecreasing);
        }

        class.authorized = newAuthorized;

        emit AuthorizedChanged(classId, newAuthorized);
    }

    function _changeConvertibleAmount(uint256 classId, uint128 amount, bool isIncrease) internal {
        Class storage class = _getClass(classId);
        uint128 newConvertible = isIncrease ? class.convertible + amount : class.convertible - amount;

        // Ensure that there's enough authorized space for the new convertible if we are increasing
        if (isIncrease && _issuedFor(class) + newConvertible > class.authorized) {
            revert ConvertibleOverAuthorized(classId);
        }

        class.convertible = newConvertible;

        emit ConvertibleChanged(classId, newConvertible);
    }

    /**
     * @notice Set bouncer to control transfers of class of shares
     * @dev Freezing the class will remove the ability to ever change the bouncer again
     * @param classId ID of the class
     * @param bouncer Bouncer that will be used to check transfers
     *        It cannot be zero. For allow all transfers, use `EmbeddedBouncerType.AllowAll` (addrFlag=0x00..0102)
     */
    function setBouncer(uint256 classId, IBouncer bouncer) external onlySafe {
        if (address(bouncer) == address(0)) {
            revert BadInput();
        }

        Class storage class = _getClass(classId);

        _ensureClassNotFrozen(class, classId);

        class.bouncer = bouncer;

        emit BouncerChanged(classId, bouncer);
    }

    /**
     * @notice Sets whether an address can manage a class of shares (issue and control holder accounts)
     * @dev Warning: managers can set controllers for accounts, which can be used to transfer shares or remove controllers (e.g. vesting)
     * @dev Freezing the class will remove the ability to ever change managers, effectively freezing the set
     *      of accounts that can issue for the class or set controllers
     * @param classId ID of the class
     * @param manager Address of the manager
     * @param isManager Whether the address is set as a manager
     */
    function setManager(uint256 classId, address manager, bool isManager) external onlySafe {
        Class storage class = _getClass(classId);

        _ensureClassNotFrozen(class, classId);

        class.isManager[manager] = isManager;

        emit ClassManagerSet(classId, manager, isManager);
    }

    /**
     * @notice Freeze class of shares, preventing further changes to authorized amount, managers or bouncers
     * @dev Freezing the class is a non-reversible operation
     * @param classId ID of the class
     */
    function freeze(uint256 classId) external onlySafe {
        Class storage class = _getClass(classId);

        _ensureClassNotFrozen(class, classId);

        class.isFrozen = true;

        emit ClassFrozen(classId);
    }

    function _ensureClassNotFrozen(Class storage class, uint256 classId) internal view {
        if (class.isFrozen) {
            revert FrozenClass(classId);
        }
    }

    function _ensureSenderIsManager(Class storage class, uint256 classId) internal view {
        if (!class.isManager[_msgSender()]) {
            revert UnauthorizedNotManager(classId);
        }
    }

    /**
     * @notice Issue shares for an account
     * @dev Can be done by any manager of the class
     * @param account Address of the account to issue shares for
     * @param classId ID of the class
     * @param amount Amount of shares to issue
     */
    function issue(address account, uint256 classId, uint256 amount) public {
        if (amount == 0) {
            revert BadInput();
        }

        Class storage class = _getClass(classId);
        _ensureSenderIsManager(class, classId);

        if (_issuedFor(class) + class.convertible + amount > class.authorized) {
            revert IssuedOverAuthorized(classId);
        }

        class.token.mint(account, amount);

        emit Issued(account, classId, amount, _msgSender());
    }

    /**
     * @notice Issue shares for an account and set controller over these shares
     * @dev Can be done by any manager of the class
     * @param account Address of the account to issue shares for
     * @param classId ID of the class
     * @param amount Amount of shares to issue
     * @param controller Controller to set for the account in this class
     * @param controllerParams Parameters to pass to the controller on initialization
     */
    function issueAndSetController(
        address account,
        uint256 classId,
        uint256 amount,
        IAccountController controller,
        bytes calldata controllerParams
    ) external {
        // `issue` verifies that the class exists and sender is manager on classId
        issue(account, classId, amount);
        _setController(account, classId, amount, controller, controllerParams);
    }

    /**
     * @notice Set controller over shares for an account in a class
     * @dev Can be done by any manager of the class
     * @param account Address of the account to set controller for
     * @param classId ID of the class
     * @param controller Controller to set for the account in this class
     * @param controllerParams Parameters to pass to the controller on initialization
     */
    function setController(
        address account,
        uint256 classId,
        IAccountController controller,
        bytes calldata controllerParams
    ) external {
        Class storage class = _getClass(classId);
        _ensureSenderIsManager(class, classId);

        uint256 classBalance = class.token.balanceOf(account);
        if (classBalance == 0) {
            revert AccountIsNonHolder(account, classId);
        }
        
        _setController(account, classId, classBalance, controller, controllerParams);
    }

    /**
     * @dev This function assumes that the caller has already checked that the sender is a manager
     * and that the balance in the class for the account is non-zero
     */
    function _setController(
        address account,
        uint256 classId,
        uint256 amount,
        IAccountController controller,
        bytes calldata controllerParams
    ) internal {
        controllers[account][classId] = controller;
        controller.addAccount(account, classId, amount, controllerParams);

        emit ControllerSet(account, classId, controller);
    }

    /**
     * @notice Function called by the controller to remove itself as controller when it is no longer in use
     * @dev Can be done by the controller, likely can be triggered by the user in the controller
     * @param account Address of the account to remove controller for
     * @param classId ID of the class
     */
    function controllerDettach(address account, uint256 classId) external {
        // If it was no longer the controller for the account, consider this
        // a no-op, as it might have been the controller in the past and
        // removed by a class manager (controller had no way to know it was removed)
        if (msg.sender == address(controllers[account][classId])) {
            controllers[account][classId] = NO_CONTROLLER;
            emit ControllerSet(account, classId, NO_CONTROLLER);
        }
    }

    /**
     * @notice Forcibly transfer shares from one account to another
     * @dev Can be done by the controller of an account
     * @param account Address of the account to transfer shares from
     * @param to Address of the account to transfer shares to
     * @param classId ID of the class
     * @param amount Amount of shares to transfer
     * @param reason Reason for the transfer
     */
    function controllerForcedTransfer(
        address account,
        address to,
        uint256 classId,
        uint256 amount,
        string calldata reason
    ) external {
        // Controllers use msg.sender directly as they should be contracts that
        // call this one and should never be using metatxs
        if (msg.sender != address(controllers[account][classId])) {
            revert UnauthorizedNotController(classId);
        }

        _getClass(classId).token.forcedTransfer(account, to, amount);

        emit ForcedTransfer(account, to, classId, amount, msg.sender, reason);
    }

    /**
     * @notice Forcibly transfer shares from one account to another
     * @dev Can be done by any manager of the class (likely used to bypass the bouncer with authorization of the manager)
     * @param account Address of the account to transfer shares from
     * @param to Address of the account to transfer shares to
     * @param classId ID of the class
     * @param amount Amount of shares to transfer
     * @param reason Reason for the transfer
     */
    function managerForcedTransfer(address account, address to, uint256 classId, uint256 amount, string calldata reason)
        external
    {
        Class storage class = _getClass(classId);

        _ensureSenderIsManager(class, classId);

        class.token.forcedTransfer(account, to, amount);

        emit ForcedTransfer(account, to, classId, amount, _msgSender(), reason);
    }

    /**
     * @notice Convert shares from one class to another
     * @dev Can only be triggered voluntarely by the owner of the shares and can be blocked by the class bouncer
     * @param fromClassId ID of the class to convert from
     * @param amount Amount of shares to convert
     */
    function convert(uint256 fromClassId, uint256 amount) external {
        Class storage fromClass = _getClass(fromClassId);
        uint256 toClassId = fromClass.convertsToClassId;
        Class storage toClass = _getClass(toClassId);

        address sender = _msgSender();

        // if user has a controller for the origin class id, ensure controller allows the transfer
        IAccountController controller = controllers[sender][fromClassId];
        if (controller != NO_CONTROLLER) {
            if (!controller.isTransferAllowed(sender, sender, fromClassId, amount)) {
                revert ConversionBlocked(controller, sender, fromClassId, amount);
            }
        }

        // Class conversions cannot be blocked by class bouncer, as token
        // ownership doesn't change (always goes from sender to sender)

        fromClass.authorized -= uint128(amount);
        toClass.convertible -= uint128(amount);

        fromClass.token.burn(sender, amount);
        toClass.token.mint(sender, amount);

        emit Converted(sender, fromClassId, toClassId, amount);
    }

    /**
     * @notice Function called by EquityToken to check whether a transfer can go through
     * @param from Address of the account transferring shares
     * @param to Address of the account receiving shares
     * @param classId ID of the class
     * @param amount Amount of shares to transfer
     */
    function ensureTransferIsAllowed(address from, address to, uint256 classId, uint256 amount) external view {
        Class storage class = _getClass(classId);

        // First, ensure the class bouncer allows the transfer
        if (!bouncerAllowsTransfer(class.bouncer, from, to, classId, amount)) {
            revert TransferBlocked(class.bouncer, from, to, classId, amount);
        }

        // Then, if the holder has a controller for their shares in this class, check that
        // it allows the transfer
        IAccountController controller = controllers[from][classId];
        // from has a controller for this class id
        if (address(controller) != address(0)) {
            if (!controller.isTransferAllowed(from, to, classId, amount)) {
                revert TransferBlocked(controller, from, to, classId, amount);
            }
        }
    }

    function numberOfClasses() public view override returns (uint256) {
        return classCount;
    }

    function authorizedFor(uint256 classId) external view returns (uint256) {
        return _getClass(classId).authorized;
    }

    function issuedFor(uint256 classId) external view returns (uint256) {
        return _issuedFor(_getClass(classId));
    }

    function _issuedFor(Class storage class) internal view returns (uint256) {
        return class.token.totalSupply();
    }

    function balanceOf(address account, uint256 classId) public view override returns (uint256) {
        return _getClass(classId).token.balanceOf(account);
    }

    function getVotes(address account) external view returns (uint256 totalVotes) {
        return _weightedSumAllClasses(abi.encodeCall(ERC20Votes.getVotes, (account)));
    }

    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256) {
        return _weightedSumAllClasses(abi.encodeCall(ERC20Votes.getPastVotes, (account, blockNumber)));
    }

    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256) {
        return _weightedSumAllClasses(abi.encodeCall(ERC20Votes.getPastTotalSupply, (blockNumber)));
    }

    function getTotalVotes() external view returns (uint256) {
        return _weightedSumAllClasses(abi.encodeCall(ERC20.totalSupply, ()));
    }

    function _weightedSumAllClasses(bytes memory data) internal view returns (uint256 total) {
        uint256 n = classCount;
        for (uint256 i = 0; i < n;) {
            Class storage class = classes[i];
            uint256 votingWeight = class.votingWeight;
            if (votingWeight > 0) {
                (bool ok, bytes memory returnData) = address(class.token).staticcall(data);
                require(ok && returnData.length == 32);
                total += votingWeight * abi.decode(returnData, (uint256));
            }
            unchecked {
                i++;
            }
        }
    }

    function nameFor(uint256 classId) public view returns (string memory) {
        return string(abi.encodePacked(name, bytes(" "), _getClass(classId).name));
    }

    function tickerFor(uint256 classId) public view returns (string memory) {
        return _getClass(classId).ticker;
    }

    function _getClass(uint256 classId) internal view returns (Class storage class) {
        class = classes[classId];

        if (address(class.token) == address(0)) {
            revert UnexistentClass(classId);
        }
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {ERC20, ERC20Votes, ERC20Permit} from "openzeppelin/token/ERC20/extensions/ERC20Votes.sol";

import {Captable} from "./Captable.sol";
import {IMPL_INIT_NOOP_ADDR} from "../bases/FirmBase.sol";

/*
THE TRANSFER OF THE SECURITIES REFERENCED HEREIN IS SUBJECT TO CERTAIN TRANSFER
RESTRICTIONS SET FORTH IN THE COMPANY’S BYLAWS, WHICH MAY BE OBTAINED UPON
WRITTEN REQUEST TO THE COMPANY AT ITS DESIGNATED ELECTRONIC ADDRESS.
THE COMPANY SHALL NOT REGISTER OR OTHERWISE RECOGNIZE OR GIVE EFFECT TO ANY
PURPORTED TRANSFER OF SECURITIES THAT DOES NOT COMPLY WITH SUCH TRANSFER RESTRICTIONS.*/

/**
 * @title Equity token
 * @author Firm ([email protected])
 * @notice ERC20 with vote delegation controlled by a Captable contract
 */
contract EquityToken is ERC20Votes {
    Captable public captable;
    uint32 public classId;

    error AlreadyInitialized();
    error UnauthorizedNotCaptable();

    modifier onlyCaptable() {
        // We use msg.sender directly here because Captable will never do meta-txs into this contract
        if (msg.sender != address(captable)) {
            revert UnauthorizedNotCaptable();
        }

        _;
    }

    constructor() ERC20("", "") ERC20Permit("") {
        initialize(Captable(IMPL_INIT_NOOP_ADDR), 0);
    }

    function initialize(Captable captable_, uint32 classId_) public {
        if (address(captable) != address(0)) {
            revert AlreadyInitialized();
        }

        captable = captable_;
        classId = classId_;
    }

    function mint(address account, uint256 amount) external onlyCaptable {
        _mint(account, amount);
    }

    function burn(address account, uint256 amount) external onlyCaptable {
        _burn(account, amount);
    }

    function forcedTransfer(address from, address to, uint256 amount) external onlyCaptable {
        _transfer(from, to, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
        // Transfers triggered by Captable are always allowed and not checked
        if (msg.sender != address(captable)) {
            captable.ensureTransferIsAllowed(from, to, classId, amount);
        }

        super._beforeTokenTransfer(from, to, amount);
    }

    function name() public view override returns (string memory) {
        return captable.nameFor(classId);
    }

    function symbol() public view override returns (string memory) {
        return captable.tickerFor(classId);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.0;

import {FirmBase, ISafe, IMPL_INIT_NOOP_ADDR, IMPL_INIT_NOOP_SAFE} from "../../bases/FirmBase.sol";

import {Captable} from "../Captable.sol";
import {IBouncer} from "../interfaces/IBouncer.sol";

abstract contract IAccountController is IBouncer {
    function addAccount(address owner, uint256 classId, uint256 amount, bytes calldata extraParams) external virtual;
}

abstract contract AccountController is FirmBase, IAccountController {
    // CAPTABLE_SLOT = keccak256("firm.accountcontroller.captable") - 1
    bytes32 internal constant CAPTABLE_SLOT = 0xff0072f9b8f3624c7501bc21bf62fd5a141de3e4b1703f9e7f919a1ff011f4e6;

    constructor() {
        initialize(Captable(IMPL_INIT_NOOP_ADDR), IMPL_INIT_NOOP_ADDR);
    }

    function initialize(Captable captable_, address trustedForwarder_) public {
        ISafe safe = address(captable_) != IMPL_INIT_NOOP_ADDR ? captable_.safe() : IMPL_INIT_NOOP_SAFE;

        // Will revert if reinitialized
        __init_firmBase(safe, trustedForwarder_);
        assembly {
            sstore(CAPTABLE_SLOT, captable_)
        }
    }

    function captable() public view returns (Captable _captable) {
        assembly {
            _captable := sload(CAPTABLE_SLOT)
        }
    }

    error UnauthorizedNotCaptable();
    error AccountAlreadyExists();
    error AccountDoesntExist();

    modifier onlyCaptable() {
        // We use msg.sender directly here because Captable will never do meta-txs into this contract
        if (msg.sender != address(captable())) {
            revert UnauthorizedNotCaptable();
        }

        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBouncer {
    function isTransferAllowed(address from, address to, uint256 classId, uint256 amount)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// More minimal interface of OZ's IVotes.sol which exposes the functions neccesary for vote counting
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/governance/utils/IVotes.sol
// It can safely be casted to IVotes for contracts that just call these view functions
interface ICaptableVotes {
    /**
     * @dev Returns the current amount of votes that `account` has.
     */
    function getVotes(address account) external view returns (uint256);

    /**
     * @dev Returns the amount of votes that `account` had at the end of a past block (`blockNumber`).
     */
    function getPastVotes(address account, uint256 blockNumber) external view returns (uint256);

    /**
     * @dev Returns the total supply of votes available at the end of a past block (`blockNumber`).
     *
     * NOTE: This value is the sum of all available votes, which is not necessarily the sum of all delegated votes.
     * Votes that have not been delegated are still part of total supply, even though they would not participate in a
     * vote.
     */
    function getPastTotalSupply(uint256 blockNumber) external view returns (uint256);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {GnosisSafe} from "safe/GnosisSafe.sol";
import {GnosisSafeProxyFactory} from "safe/proxies/GnosisSafeProxyFactory.sol";

import {ISafe} from "../bases/interfaces/ISafe.sol";
import {Roles} from "../roles/Roles.sol";
import {Budget, EncodedTimeShift} from "../budget/Budget.sol";
import {Captable, IBouncer} from "../captable/Captable.sol";
import {Voting, NO_SEMAPHORE} from "../voting/Voting.sol";
import {Semaphore, ISemaphore} from "../semaphore/Semaphore.sol";

import {FirmRelayer} from "../metatx/FirmRelayer.sol";

import {UpgradeableModuleProxyFactory, LATEST_VERSION} from "./UpgradeableModuleProxyFactory.sol";
import {AddressUint8FlagsLib} from "../bases/utils/AddressUint8FlagsLib.sol";
import {FirmAddresses, SemaphoreTargetsFlag, SEMAPHORE_TARGETS_FLAG_TYPE, exceptionTargetFlagToAddress} from "./config/SemaphoreTargets.sol";

string constant ROLES_MODULE_ID =     "org.firm.roles";
string constant BUDGET_MODULE_ID =    "org.firm.budget";
string constant CAPTABLE_MODULE_ID =  "org.firm.captable";
string constant VOTING_MODULE_ID =    "org.firm.voting";
string constant SEMAPHORE_MODULE_ID = "org.firm.semaphore";

contract FirmFactory {
    using AddressUint8FlagsLib for address;

    GnosisSafeProxyFactory public immutable safeFactory;
    address public immutable safeImpl;

    UpgradeableModuleProxyFactory public immutable moduleFactory;
    FirmRelayer public immutable relayer;

    address internal immutable cachedThis;

    error EnableModuleFailed();
    error InvalidContext();
    error InvalidConfig();

    event NewFirmCreated(address indexed creator, GnosisSafe indexed safe);

    constructor(
        GnosisSafeProxyFactory _safeFactory,
        UpgradeableModuleProxyFactory _moduleFactory,
        FirmRelayer _relayer,
        address _safeImpl
    ) {
        safeFactory = _safeFactory;
        moduleFactory = _moduleFactory;
        relayer = _relayer;
        safeImpl = _safeImpl;

        cachedThis = address(this);
    }

    struct SafeConfig {
        address[] owners;
        uint256 requiredSignatures;
    }

    struct FirmConfig {
        // if false, only roles and budget are created
        bool withCaptableAndVoting;
        bool withSemaphore;
        // budget and roles are always created
        BudgetConfig budgetConfig;
        RolesConfig rolesConfig;
        // optional depending on 'withCaptableAndVoting'
        CaptableConfig captableConfig;
        VotingConfig votingConfig;
        // optional depending on 'withSemaphore'
        SemaphoreConfig semaphoreConfig;
    }

    struct BudgetConfig {
        AllowanceCreationInput[] allowances;
    }

    struct AllowanceCreationInput {
        uint256 parentAllowanceId;
        address spender;
        address token;
        uint256 amount;
        EncodedTimeShift recurrency;
        string name;
    }

    struct RolesConfig {
        RoleCreationInput[] roles;
    }

    struct RoleCreationInput {
        bytes32 roleAdmins;
        string name;
        address[] grantees;
    }

    struct CaptableConfig {
        string name;
        ClassCreationInput[] classes;
        ShareIssuanceInput[] issuances;
    }

    struct ClassCreationInput {
        string className;
        string ticker;
        uint128 authorized;
        uint32 convertsToClassId;
        uint16 votingWeight;
        IBouncer bouncer;
    }

    struct ShareIssuanceInput {
        uint256 classId;
        address account;
        uint256 amount;
    }

    struct VotingConfig {
        uint256 quorumNumerator;
        uint256 votingDelay;
        uint256 votingPeriod;
        uint256 proposalThreshold;
    }

    struct SemaphoreConfig {
        bool safeDefaultAllowAll; // if true, Safe will allow all calls by default (if false, it will be Voting the default)
        bool safeAllowDelegateCalls;
        bool votingAllowValueCalls;
        SemaphoreException[] semaphoreExceptions; // exceptions for which calls are only allowed in the non-default executor
    }

    struct SemaphoreException {
        Semaphore.ExceptionType exceptionType;
        address target; // can use flags for target for Safe and Voting
        bytes4 sig;
    }

    function createBarebonesFirm(address owner, uint256 nonce) public returns (GnosisSafe safe) {
        return createFirm(defaultOneOwnerSafeConfig(owner), defaultBarebonesFirmConfig(), nonce);
    }

    function createFirm(SafeConfig memory safeConfig, FirmConfig memory firmConfig, uint256 nonce)
        public
        returns (GnosisSafe safe)
    {
        bytes memory setupFirmData = abi.encodeCall(this.setupFirm, (firmConfig, nonce));
        bytes memory safeInitData = abi.encodeCall(
            GnosisSafe.setup,
            (
                safeConfig.owners,
                safeConfig.requiredSignatures,
                address(this),
                setupFirmData,
                address(0),
                address(0),
                0,
                payable(0)
            )
        );

        safe = GnosisSafe(payable(safeFactory.createProxyWithNonce(safeImpl, safeInitData, nonce)));

        emit NewFirmCreated(msg.sender, safe);
    }

    // Safe will delegatecall here as part of its setup, can only run on a delegatecall
    function setupFirm(FirmConfig calldata config, uint256 nonce) external {
        // Ensure that we are running on a delegatecall and not in a direct call to this external function
        // cachedThis is set to the address of this contract in the constructor as an immutable
        GnosisSafe safe = GnosisSafe(payable(address(this)));
        if (address(safe) == cachedThis) {
            revert InvalidContext();
        }

        if (config.withSemaphore && !config.withCaptableAndVoting) {
            revert InvalidConfig();
        }

        Roles roles = setupRoles(config.rolesConfig, nonce);
        Budget budget = setupBudget(config.budgetConfig, roles, nonce);
        safe.enableModule(address(budget));

        if (!config.withCaptableAndVoting) {
            return;
        }

        ISemaphore semaphore = config.withSemaphore ? createSemaphore(config.semaphoreConfig, nonce) : NO_SEMAPHORE;

        Captable captable = setupCaptable(config.captableConfig, nonce);
        Voting voting = setupVoting(config.votingConfig, captable, semaphore, nonce);
        safe.enableModule(address(voting));

        if (semaphore == NO_SEMAPHORE) {
            return;
        }

        FirmAddresses memory firmAddresses = FirmAddresses({
            semaphore: Semaphore(address(semaphore)),
            safe: safe,
            voting: voting,
            budget: budget,
            roles: roles,
            captable: captable
        });
        configSemaphore(config.semaphoreConfig, firmAddresses);
        safe.setGuard(address(semaphore));
    }

    function setupBudget(BudgetConfig calldata config, Roles roles, uint256 nonce) internal returns (Budget budget) {
        // Function should only be run in Safe context. It assumes that this check already ocurred
        budget = Budget(
            moduleFactory.deployUpgradeableModule(
                BUDGET_MODULE_ID,
                LATEST_VERSION,
                abi.encodeCall(Budget.initialize, (ISafe(payable(address(this))), roles, address(relayer))),
                nonce
            )
        );

        // As we are the safe, we can just create the top-level allowances as the safe has that power
        uint256 allowanceCount = config.allowances.length;
        for (uint256 i = 0; i < allowanceCount;) {
            AllowanceCreationInput memory allowance = config.allowances[i];

            budget.createAllowance(
                allowance.parentAllowanceId,
                allowance.spender,
                allowance.token,
                allowance.amount,
                allowance.recurrency,
                allowance.name
            );

            unchecked {
                ++i;
            }
        }
    }

    function setupRoles(RolesConfig calldata config, uint256 nonce) internal returns (Roles roles) {
        // Function should only be run in Safe context. It assumes that this check already ocurred
        roles = Roles(
            moduleFactory.deployUpgradeableModule(
                ROLES_MODULE_ID,
                LATEST_VERSION,
                abi.encodeCall(Roles.initialize, (ISafe(payable(address(this))), address(relayer))),
                nonce
            )
        );

        // As we are the safe, we can just create the roles and assign them as the safe has the root role
        uint256 roleCount = config.roles.length;
        for (uint256 i = 0; i < roleCount;) {
            RoleCreationInput memory role = config.roles[i];
            uint8 roleId = roles.createRole(role.roleAdmins, role.name);

            uint256 granteeCount = role.grantees.length;
            for (uint256 j = 0; j < granteeCount;) {
                roles.setRole(role.grantees[j], roleId, true);

                unchecked {
                    ++j;
                }
            }

            unchecked {
                ++i;
            }
        }
    }

    function setupCaptable(CaptableConfig calldata config, uint256 nonce) internal returns (Captable captable) {
        // Function should only be run in Safe context. It assumes that this check already ocurred
        captable = Captable(
            moduleFactory.deployUpgradeableModule(
                CAPTABLE_MODULE_ID,
                LATEST_VERSION,
                abi.encodeCall(Captable.initialize, (config.name, ISafe(payable(address(this))), address(relayer))),
                nonce
            )
        );

        // As we are the safe, we can just create the classes and issue shares
        uint256 classCount = config.classes.length;
        for (uint256 i = 0; i < classCount;) {
            ClassCreationInput memory class = config.classes[i];
            captable.createClass(
                class.className,
                class.ticker,
                class.authorized,
                class.convertsToClassId,
                class.votingWeight,
                class.bouncer
            );

            unchecked {
                ++i;
            }
        }

        uint256 issuanceCount = config.issuances.length;
        for (uint256 i = 0; i < issuanceCount;) {
            ShareIssuanceInput memory issuance = config.issuances[i];
            // it is possible that this reverts if the class does not exist or
            // the amount to be issued goes over the authorized amount
            captable.issue(issuance.account, issuance.classId, issuance.amount);

            unchecked {
                ++i;
            }
        }
    }

    function setupVoting(VotingConfig calldata config, Captable captable, ISemaphore semaphore, uint256 nonce)
        internal
        returns (Voting voting)
    {
        // Function should only be run in Safe context. It assumes that this check already ocurred
        bytes memory votingInitData = abi.encodeCall(
            Voting.initialize,
            (
                ISafe(payable(address(this))),
                semaphore,
                captable,
                config.quorumNumerator,
                config.votingDelay,
                config.votingPeriod,
                config.proposalThreshold,
                address(relayer)
            )
        );
        voting = Voting(
            payable(moduleFactory.deployUpgradeableModule(VOTING_MODULE_ID, LATEST_VERSION, votingInitData, nonce))
        );
    }

    function defaultOneOwnerSafeConfig(address owner) public pure returns (SafeConfig memory) {
        address[] memory owners = new address[](1);
        owners[0] = owner;
        return SafeConfig({owners: owners, requiredSignatures: 1});
    }

    function defaultBarebonesFirmConfig() public pure returns (FirmConfig memory) {
        BudgetConfig memory budgetConfig = BudgetConfig({allowances: new AllowanceCreationInput[](0)});
        RolesConfig memory rolesConfig = RolesConfig({roles: new RoleCreationInput[](0)});
        CaptableConfig memory captableConfig;
        VotingConfig memory votingConfig;
        SemaphoreConfig memory semaphoreConfig;

        return FirmConfig({
            withCaptableAndVoting: false,
            withSemaphore: false,
            budgetConfig: budgetConfig,
            rolesConfig: rolesConfig,
            captableConfig: captableConfig,
            votingConfig: votingConfig,
            semaphoreConfig: semaphoreConfig
        });
    }

    function createSemaphore(SemaphoreConfig calldata config, uint256 nonce) internal returns (Semaphore semaphore) {
        semaphore = Semaphore(
            moduleFactory.deployUpgradeableModule(
                SEMAPHORE_MODULE_ID,
                LATEST_VERSION,
                abi.encodeCall(Semaphore.initialize, (ISafe(payable(address(this))), config.safeAllowDelegateCalls, address(relayer))),
                nonce
            )
        );
    }

    function configSemaphore(SemaphoreConfig calldata config, FirmAddresses memory firmAddresses) internal {
        Semaphore semaphore = firmAddresses.semaphore;
        Voting voting = firmAddresses.voting;

        if (!config.safeDefaultAllowAll) {
            semaphore.setSemaphoreState(address(voting), Semaphore.DefaultMode.Allow, false, config.votingAllowValueCalls);
            semaphore.setSemaphoreState(address(this), Semaphore.DefaultMode.Disallow, config.safeAllowDelegateCalls, true);
        } else {
            semaphore.setSemaphoreState(address(voting), Semaphore.DefaultMode.Disallow, false, config.votingAllowValueCalls);
            // Safe state is the same that was already set in the initializer, no need to set again
        }

        uint256 exceptionsLength = config.semaphoreExceptions.length;
        Semaphore.ExceptionInput[] memory exceptions = new Semaphore.ExceptionInput[](exceptionsLength * 2);

        for (uint256 i = 0; i < exceptionsLength;) {
            SemaphoreException memory exception = config.semaphoreExceptions[i];

            address target = exception.target;

            if (target.isFlag(SEMAPHORE_TARGETS_FLAG_TYPE)) {
                target = exceptionTargetFlagToAddress(firmAddresses, exception.target.flagValue());
            }

            exceptions[i * 2] = Semaphore.ExceptionInput(true, exception.exceptionType, address(voting), target, exception.sig);
            exceptions[i * 2 + 1] = Semaphore.ExceptionInput(true, exception.exceptionType, address(this), target, exception.sig);

            unchecked {
                i++;
            }
        }

        semaphore.addExceptions(exceptions);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {Ownable} from "openzeppelin/access/Ownable.sol";
import {IModuleMetadata} from "../bases/interfaces/IModuleMetadata.sol";

uint256 constant LATEST_VERSION = type(uint256).max;

contract UpgradeableModuleProxyFactory is Ownable {
    error ProxyAlreadyDeployedForNonce();
    error FailedInitialization();
    error ModuleVersionAlreadyRegistered();
    error UnexistentModuleVersion();

    event ModuleRegistered(IModuleMetadata indexed implementation, string moduleId, uint256 version);
    event ModuleProxyCreated(address indexed proxy, IModuleMetadata indexed implementation);

    mapping(string => mapping(uint256 => IModuleMetadata)) internal modules;
    mapping(string => uint256) public latestModuleVersion;

    function register(IModuleMetadata implementation) external onlyOwner {
        string memory moduleId = implementation.moduleId();
        uint256 version = implementation.moduleVersion();

        if (address(modules[moduleId][version]) != address(0)) {
            revert ModuleVersionAlreadyRegistered();
        }

        modules[moduleId][version] = implementation;

        if (version > latestModuleVersion[moduleId]) {
            latestModuleVersion[moduleId] = version;
        }

        emit ModuleRegistered(implementation, moduleId, version);
    }

    function getImplementation(string memory moduleId, uint256 version)
        public
        view
        returns (IModuleMetadata implementation)
    {
        if (version == LATEST_VERSION) {
            version = latestModuleVersion[moduleId];
        }
        implementation = modules[moduleId][version];
        if (address(implementation) == address(0)) {
            revert UnexistentModuleVersion();
        }
    }

    function deployUpgradeableModule(string memory moduleId, uint256 version, bytes memory initializer, uint256 salt)
        public
        returns (address proxy)
    {
        return deployUpgradeableModule(getImplementation(moduleId, version), initializer, salt);
    }

    function deployUpgradeableModule(IModuleMetadata implementation, bytes memory initializer, uint256 salt)
        public
        returns (address proxy)
    {
        proxy = createProxy(implementation, keccak256(abi.encodePacked(keccak256(initializer), salt)));

        (bool success,) = proxy.call(initializer);
        if (!success) {
            revert FailedInitialization();
        }
    }
    
    /**
     * @dev Proxy EVM code from factory/proxy-asm generated with ETK
     */
    function createProxy(IModuleMetadata implementation, bytes32 salt) internal returns (address proxy) {
        bytes memory initcode = abi.encodePacked(
            hex"73",
            implementation,
            hex"7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc55603b8060403d393df3363d3d3760393d3d3d3d3d363d7f360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc545af4913d913e3d9257fd5bf3"
        );

        assembly {
            proxy := create2(0, add(initcode, 0x20), mload(initcode), salt)
        }

        if (proxy == address(0)) {
            revert ProxyAlreadyDeployedForNonce();
        }

        emit ModuleProxyCreated(proxy, implementation);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {AddressUint8FlagsLib} from "../../bases/utils/AddressUint8FlagsLib.sol";

import {GnosisSafe} from "safe/GnosisSafe.sol";
import {Roles} from "../../roles/Roles.sol";
import {Budget} from "../../budget/Budget.sol";
import {Captable} from "../../captable/Captable.sol";
import {Voting} from "../../voting/Voting.sol";
import {Semaphore} from "../../semaphore/Semaphore.sol";

uint8 constant SEMAPHORE_TARGETS_FLAG_TYPE = 0x03;

enum SemaphoreTargetsFlag {
    Safe,
    Voting,
    Budget,
    Roles,
    Captable,
    Semaphore
}

struct FirmAddresses {
    GnosisSafe safe;
    Voting voting;
    Budget budget;
    Roles roles;
    Captable captable;
    Semaphore semaphore;
}

function exceptionTargetFlagToAddress(FirmAddresses memory firmAddresses, uint8 flagValue) pure returns (address) {
    SemaphoreTargetsFlag flag = SemaphoreTargetsFlag(flagValue);

    if (flag == SemaphoreTargetsFlag.Safe) {
        return address(firmAddresses.safe);
    } else if (flag == SemaphoreTargetsFlag.Semaphore) {
        return address(firmAddresses.semaphore);
    } else if (flag == SemaphoreTargetsFlag.Captable) {
        return address(firmAddresses.captable);
    } else if (flag == SemaphoreTargetsFlag.Voting) {
        return address(firmAddresses.voting);
    } else if (flag == SemaphoreTargetsFlag.Roles) {
        return address(firmAddresses.roles);
    } else if (flag == SemaphoreTargetsFlag.Budget) {
        return address(firmAddresses.budget);
    } else {
        assert(false); // if-else should be exhaustive and we should never reach here
        return address(0); // silence compiler warning, unreacheable 
    }
}

// Only used for testing/scripts
function targetFlag(SemaphoreTargetsFlag targetType) pure returns (address) {
    return AddressUint8FlagsLib.toFlag(uint8(targetType), SEMAPHORE_TARGETS_FLAG_TYPE);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {ECDSA} from "openzeppelin/utils/cryptography/ECDSA.sol";
import {EIP712} from "openzeppelin/utils/cryptography/draft-EIP712.sol";

/**
 * @title FirmRelayer
 * @author Firm ([email protected])
 * @notice Relayer for gas-less transactions
 * @dev Custom ERC2771 forwarding relayer tailor made for Firm's UX needs and return value assertions
 * Inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/v4.7.3/contracts/metatx/MinimalForwarder.sol (MIT licensed)
 */
contract FirmRelayer is EIP712 {
    using ECDSA for bytes32;

    // NOTE: Assertions are its own separate array since it results in smaller calldata
    // than if the Call struct had an assertions array member for common cases
    // in which there will be one assertion per call and many calls will not
    // have assertions, resulting in more expensive encoding (1 more word for each empty array)
    struct RelayRequest {
        address from;
        uint256 nonce;
        Call[] calls;
        Assertion[] assertions;
    }

    struct Call {
        address to;
        uint256 value;
        uint256 gas;
        bytes data;
        uint256 assertionIndex; // one-indexed, 0 signals no assertions
    }

    struct Assertion {
        uint256 position;
        bytes32 expectedValue;
    }

    // See https://eips.ethereum.org/EIPS/eip-712#definition-of-typed-structured-data-%F0%9D%95%8A
    // string internal constant ASSERTION_TYPE = "Assertion(uint256 position,bytes32 expectedValue)";
    // string internal constant CALL_TYPE = "Call(address to,uint256 value,uint256 gas,bytes data,uint256 assertionIndex)";
    // bytes32 internal constant REQUEST_TYPEHASH = keccak256(
    //    abi.encodePacked(
    //        "RelayRequest(address from,uint256 nonce,Call[] calls,Assertion[] assertions)", ASSERTION_TYPE, CALL_TYPE
    //    )
    //);
    // bytes32 internal constant ASSERTION_TYPEHASH = keccak256(abi.encodePacked(ASSERTION_TYPE));
    // bytes32 internal constant CALL_TYPEHASH = keccak256(abi.encodePacked(CALL_TYPE));
    // bytes32 internal constant ZERO_HASH = keccak256("");
    // All hashes are hardcoded as an optimization
    bytes32 internal constant REQUEST_TYPEHASH = 0x4e408063141dd503cd4ffb41da06a207a002e1632bbb7a1c2058bb5100bbdd68;
    bytes32 internal constant ASSERTION_TYPEHASH = 0xb8e6765a43e49f2a6e73bf063f697a2d4a289bc2c471f51c126f382b1370ecde;
    bytes32 internal constant CALL_TYPEHASH = 0xe1f11d512d9db71c9cfb8c40837bacb6c300df10de574e99f55b8fe640ecb2f3;
    bytes32 internal constant ZERO_HASH = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;

    uint256 internal constant ASSERTION_WORD_SIZE = 32;
    uint256 internal constant RELAY_GAS_BUFFER = 10000;
    uint256 internal constant MAX_REVERT_DATA = 320;

    mapping(address => uint256) public getNonce;

    error BadSignature();
    error BadNonce(uint256 expectedNonce);
    error CallExecutionFailed(uint256 callIndex, address to, bytes revertData);
    error BadAssertionIndex(uint256 callIndex);
    error AssertionPositionOutOfBounds(uint256 callIndex, uint256 returnDataLenght);
    error UnexpectedReturnValue(uint256 callIndex, bytes32 actualValue, bytes32 expectedValue);
    error UnauthorizedSenderNotFrom();
    error InsufficientGas();
    error BadExecutionContext();

    event Relayed(address indexed relayer, address indexed signer, uint256 nonce, uint256 numCalls);
    event SelfRelayed(address indexed sender, uint256 numCalls);
    event RelayExecutionFailed(address indexed relayer, address indexed signer, uint256 nonce, bytes revertData);

    constructor() EIP712("Firm Relayer", "0.0.1") {}

    /**
     * @notice Verify whether a request has been signed properly
     * @param request RelayRequest containing the calls to be performed and assertions
     * @param signature signature of the EIP712 typed data hash of the request
     * @return true if the signature is a valid signature for the request
     */
    function verify(RelayRequest calldata request, bytes calldata signature) public view returns (bool) {
        (address signer, ECDSA.RecoverError error) = requestTypedDataHash(request).tryRecover(signature);

        return error == ECDSA.RecoverError.NoError && signer == request.from;
    }

    /**
     * @notice Relay a batch of calls checking assertions on behalf of a signer (ERC2771)
     * @param request RelayRequest containing the calls to be performed and assertions
     * @param signature signature of the EIP712 typed data hash of the request
     */
    function relay(RelayRequest calldata request, bytes calldata signature) external payable {
        if (!verify(request, signature)) {
            revert BadSignature();
        }

        address signer = request.from;
        if (getNonce[signer] != request.nonce) {
            revert BadNonce(getNonce[signer]);
        }
        getNonce[signer] = request.nonce + 1;

        // We check how much gas all calls are going to use and make sure we have enough
        // This is to ensure that the external execute call will not fail due to OOG
        // which would allow to block the request by forcing it to fail
        uint256 callsGas = 0;
        uint256 callsLength = request.calls.length;
        for (uint256 i = 0; i < callsLength;) {
            callsGas += request.calls[i].gas;
            unchecked {
                i++;
            }
        }

        if (gasleft() < callsGas + RELAY_GAS_BUFFER) {
            revert InsufficientGas();
        }

        // We perform the execution as an external call so if the execution fails,
        // everything that happened in that sub-call is reverted, but not this
        // top-level call. This is important because we don't want to revert the
        // nonce increase if the execution fails.
        (bool ok, bytes memory returnData) = address(this).call(
            abi.encodeWithSelector(this.__externalSelfCall_execute.selector, signer, request.calls, request.assertions)
        );

        if (ok) {
            emit Relayed(msg.sender, signer, request.nonce, request.calls.length);
        } else {
            emit RelayExecutionFailed(msg.sender, signer, request.nonce, returnData);
        }
    }

    /**
     * @notice Relay a batch of calls checking assertions for the sender
     * @dev The reason why someone may want to use this is both being able to
     * batch calls using the same mechanism as relayed requests plus checking
     * assertions.
     * NOTE: selfRelay doesn't increase an account's nonce (native account nonces are relied on)
     * @param calls Array of calls to be made
     * @param assertions Array of assertions that calls can use
     */
    function selfRelay(Call[] calldata calls, Assertion[] calldata assertions) external payable {
        _execute(msg.sender, calls, assertions);

        emit SelfRelayed(msg.sender, calls.length);
    }

    function __externalSelfCall_execute(address asSender, Call[] calldata calls, Assertion[] calldata assertions) external {
        if (msg.sender != address(this)) {
            revert BadExecutionContext();
        }

        _execute(asSender, calls, assertions);
    }

    function _execute(address asSender, Call[] calldata calls, Assertion[] calldata assertions) internal {
        for (uint256 i = 0; i < calls.length;) {
            Call calldata call = calls[i];

            address to = call.to;
            uint256 value = call.value;
            uint256 callGas = call.gas;
            bytes memory payload = abi.encodePacked(call.data, asSender);
            uint256 returnDataSize;
            bool success;

            /// @solidity memory-safe-assembly
            assembly {
                success := call(callGas, to, value, add(payload, 0x20), mload(payload), 0, 0)
                returnDataSize := returndatasize()
            }

            if (!success) {
                // Prevent revert data from being too large
                uint256 revertDataSize = returnDataSize > MAX_REVERT_DATA ? MAX_REVERT_DATA : returnDataSize;
                bytes memory revertData = new bytes(revertDataSize);
                /// @solidity memory-safe-assembly
                assembly {
                    returndatacopy(add(revertData, 0x20), 0, revertDataSize)
                }
                revert CallExecutionFailed(i, call.to, revertData);
            }

            uint256 assertionIndex = call.assertionIndex;
            if (assertionIndex != 0) {
                if (assertionIndex > assertions.length) {
                    revert BadAssertionIndex(i);
                }

                Assertion calldata assertion = assertions[assertionIndex - 1];
                uint256 assertionPosition = assertion.position;
                if (assertion.position + ASSERTION_WORD_SIZE > returnDataSize) {
                    revert AssertionPositionOutOfBounds(i, returnDataSize);
                }

                // Only copy the return data word we need to check
                bytes32 returnValue;
                /// @solidity memory-safe-assembly
                assembly {
                    let copyPosition := mload(0x40)
                    returndatacopy(copyPosition, assertionPosition, ASSERTION_WORD_SIZE)
                    returnValue := mload(copyPosition)
                }
                if (returnValue != assertion.expectedValue) {
                    revert UnexpectedReturnValue(i, returnValue, assertion.expectedValue);
                }
            }
            unchecked {
                i++;
            }
        }
    }

    function requestTypedDataHash(RelayRequest calldata request) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(
                abi.encode(REQUEST_TYPEHASH, request.from, request.nonce, hash(request.calls), hash(request.assertions))
            )
        );
    }

    function hash(Call[] calldata calls) internal pure returns (bytes32) {
        uint256 length = calls.length;
        if (length == 0) {
            return ZERO_HASH;
        }
        bytes32[] memory hashes = new bytes32[](length);
        for (uint256 i = 0; i < length;) {
            Call calldata call = calls[i];
            hashes[i] = keccak256(
                abi.encode(CALL_TYPEHASH, call.to, call.value, call.gas, keccak256(call.data), call.assertionIndex)
            );
            unchecked {
                i++;
            }
        }
        return keccak256(abi.encodePacked(hashes));
    }

    function hash(Assertion[] calldata assertions) internal pure returns (bytes32) {
        uint256 length = assertions.length;
        if (length == 0) {
            return ZERO_HASH;
        }
        bytes32[] memory hashes = new bytes32[](length);
        for (uint256 i = 0; i < length;) {
            Assertion calldata assertion = assertions[i];
            hashes[i] = keccak256(abi.encode(ASSERTION_TYPEHASH, assertion.position, assertion.expectedValue));
            unchecked {
                i++;
            }
        }
        return keccak256(abi.encodePacked(hashes));
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {FirmBase, IMPL_INIT_NOOP_SAFE, IMPL_INIT_NOOP_ADDR} from "../bases/FirmBase.sol";
import {ISafe} from "../bases/SafeAware.sol";

import {
    IRoles,
    ROOT_ROLE_ID,
    ROLE_MANAGER_ROLE_ID,
    ONLY_ROOT_ROLE_AS_ADMIN,
    NO_ROLE_ADMINS,
    SAFE_OWNER_ROLE_ID
} from "./interfaces/IRoles.sol";

/**
 * @title Roles
 * @author Firm ([email protected])
 * @notice Role management module supporting up to 256 roles optimized for batched actions
 * Inspired by Solmate's RolesAuthority and OpenZeppelin's AccessControl
 * https://github.com/Rari-Capital/solmate/blob/main/src/auth/authorities/RolesAuthority.sol)
 * https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/AccessControl.sol
 */
contract Roles is FirmBase, IRoles {
    string public constant moduleId = "org.firm.roles";
    uint256 public constant moduleVersion = 1;

    mapping(address => bytes32) public getUserRoles;
    mapping(uint8 => bytes32) public getRoleAdmins;
    uint256 public roleCount;

    event RoleCreated(uint8 indexed roleId, bytes32 roleAdmins, string name, address indexed actor);
    event RoleNameChanged(uint8 indexed roleId, string name, address indexed actor);
    event RoleAdminsSet(uint8 indexed roleId, bytes32 roleAdmins, address indexed actor);
    event UserRolesChanged(address indexed user, bytes32 oldUserRoles, bytes32 newUserRoles, address indexed actor);

    error UnauthorizedNoRole(uint8 requiredRole);
    error UnauthorizedNotAdmin(uint8 roleId);
    error UnexistentRole(uint8 roleId);
    error RoleLimitReached();
    error InvalidRoleAdmins();

    bytes32 internal constant SAFE_OWNER_ROLE_MASK = ~bytes32(uint256(1) << SAFE_OWNER_ROLE_ID);

    ////////////////////////////////////////////////////////////////////////////////
    // INITIALIZATION
    ////////////////////////////////////////////////////////////////////////////////

    constructor() {
        initialize(IMPL_INIT_NOOP_SAFE, IMPL_INIT_NOOP_ADDR);
    }

    function initialize(ISafe safe_, address trustedForwarder_) public {
        // calls SafeAware.__init_setSafe which reverts if already initialized
        __init_firmBase(safe_, trustedForwarder_);

        assert(_createRole(ONLY_ROOT_ROLE_AS_ADMIN, "Root") == ROOT_ROLE_ID);
        assert(_createRole(ONLY_ROOT_ROLE_AS_ADMIN, "Role Manager") == ROLE_MANAGER_ROLE_ID);

        // Safe given the root role on initialization (which admins for the role can revoke)
        // Addresses with the root role have permission to do anything
        // By assigning just the root role, it also gets the role manager role (and all roles to be created)
        getUserRoles[address(safe_)] = ONLY_ROOT_ROLE_AS_ADMIN;
    }

    ////////////////////////////////////////////////////////////////////////////////
    // ROLE CREATION AND MANAGEMENT
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Creates a new role
     * @dev Requires the sender to hold the Role Manager role
     * @param roleAdmins Bitmap of roles that can perform admin actions on the new role
     * @param name Name of the role
     * @return roleId ID of the new role
     */
    function createRole(bytes32 roleAdmins, string memory name) public returns (uint8 roleId) {
        if (!hasRole(_msgSender(), ROLE_MANAGER_ROLE_ID)) {
            revert UnauthorizedNoRole(ROLE_MANAGER_ROLE_ID);
        }

        return _createRole(roleAdmins, name);
    }

    function _createRole(bytes32 roleAdmins, string memory name) internal returns (uint8 roleId) {
        uint256 roleId_ = roleCount;
        if (roleId_ == SAFE_OWNER_ROLE_ID) {
            revert RoleLimitReached();
        }

        if (roleAdmins == NO_ROLE_ADMINS || !_allRoleAdminsExist(roleAdmins, roleId_ + 1)) {
            revert InvalidRoleAdmins();
        }

        unchecked {
            roleId = uint8(roleId_);
            roleCount++;
        }

        getRoleAdmins[roleId] = roleAdmins;

        emit RoleCreated(roleId, roleAdmins, name, _msgSender());
    }

    /**
     * @notice Changes the roles that can perform admin actions on a role
     * @dev For the Root role, the sender must be an admin of Root
     * For all other roles, the sender should hold the Role Manager role
     * @param roleId ID of the role
     * @param roleAdmins Bitmap of roles that can perform admin actions on this role
     */
    function setRoleAdmins(uint8 roleId, bytes32 roleAdmins) external {
        if ((roleAdmins == NO_ROLE_ADMINS && roleId != ROOT_ROLE_ID) || !_allRoleAdminsExist(roleAdmins, roleCount)) {
            revert InvalidRoleAdmins();
        }

        if (!roleExists(roleId)) {
            revert UnexistentRole(roleId);
        }

        if (roleId == SAFE_OWNER_ROLE_ID) {
            revert UnauthorizedNotAdmin(SAFE_OWNER_ROLE_ID);
        }

        if (roleId == ROOT_ROLE_ID) {
            // Root role is treated as a special case. Only root role admins can change it
            if (!isRoleAdmin(_msgSender(), ROOT_ROLE_ID)) {
                revert UnauthorizedNotAdmin(ROOT_ROLE_ID);
            }
        } else {
            // For all other roles, the general role manager role can change any roles admins
            if (!hasRole(_msgSender(), ROLE_MANAGER_ROLE_ID)) {
                revert UnauthorizedNoRole(ROLE_MANAGER_ROLE_ID);
            }
        }

        getRoleAdmins[roleId] = roleAdmins;

        emit RoleAdminsSet(roleId, roleAdmins, _msgSender());
    }

    /**
     * @notice Changes the name of a role
     * @dev Requires the sender to hold the Role Manager role
     * @param roleId ID of the role
     * @param name New name for the role
     */
    function setRoleName(uint8 roleId, string memory name) external {
        if (!roleExists(roleId)) {
            revert UnexistentRole(roleId);
        }

        address sender = _msgSender();
        if (!hasRole(_msgSender(), ROLE_MANAGER_ROLE_ID)) {
            revert UnauthorizedNoRole(ROLE_MANAGER_ROLE_ID);
        }

        emit RoleNameChanged(roleId, name, sender);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // USER ROLE MANAGEMENT
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Grants or revokes a role for a user
     * @dev Requires the sender to hold a role that is an admin for the role being set
     * @param user Address being granted or revoked the role
     * @param roleId ID of the role being granted or revoked
     * @param isGrant Whether the role is being granted or revoked
     */
    function setRole(address user, uint8 roleId, bool isGrant) external {
        if (roleId == SAFE_OWNER_ROLE_ID) {
            revert UnauthorizedNotAdmin(SAFE_OWNER_ROLE_ID);
        }

        bytes32 oldUserRoles = getUserRoles[user];
        bytes32 newUserRoles = oldUserRoles;

        address sender = _msgSender();
        // Implicitly checks that roleId had been created
        if (!_isRoleAdmin(sender, getUserRoles[sender], roleId)) {
            revert UnauthorizedNotAdmin(roleId);
        }

        if (isGrant) {
            newUserRoles |= bytes32(1 << roleId);
        } else {
            newUserRoles &= ~bytes32(1 << roleId);
        }

        getUserRoles[user] = newUserRoles;

        emit UserRolesChanged(user, oldUserRoles, newUserRoles, sender);
    }

    /**
     * @notice Grants and revokes a set of role for a user
     * @dev Requires the sender to hold roles that can admin all roles being set
     * @param user Address being granted or revoked the roles
     * @param grantingRoles ID of all roles being granted
     * @param revokingRoles ID of all roles being revoked
     */
    function setRoles(address user, uint8[] memory grantingRoles, uint8[] memory revokingRoles) external {
        address sender = _msgSender();
        bytes32 senderRoles = getUserRoles[sender];
        bytes32 oldUserRoles = getUserRoles[user];
        bytes32 newUserRoles = oldUserRoles;

        uint256 grantsLength = grantingRoles.length;
        for (uint256 i = 0; i < grantsLength;) {
            uint8 roleId = grantingRoles[i];
            if (roleId == SAFE_OWNER_ROLE_ID || !_isRoleAdmin(sender, senderRoles, roleId)) {
                revert UnauthorizedNotAdmin(roleId);
            }

            newUserRoles |= bytes32(1 << roleId);
            unchecked {
                i++;
            }
        }

        uint256 revokesLength = revokingRoles.length;
        for (uint256 i = 0; i < revokesLength;) {
            uint8 roleId = revokingRoles[i];
            if (roleId == SAFE_OWNER_ROLE_ID || !_isRoleAdmin(sender, senderRoles, roleId)) {
                revert UnauthorizedNotAdmin(roleId);
            }

            newUserRoles &= ~(bytes32(1 << roleId));
            unchecked {
                i++;
            }
        }

        getUserRoles[user] = newUserRoles;

        emit UserRolesChanged(user, oldUserRoles, newUserRoles, sender);
    }

    /**
     * @notice Checks whether a user holds a particular role
     * @param user Address being checked for if it holds the role
     * @param roleId ID of the role being checked
     * @return True if the user holds the role or has the root role
     */
    function hasRole(address user, uint8 roleId) public view returns (bool) {
        if (roleId == SAFE_OWNER_ROLE_ID) {
            return safe().isOwner(user) || _hasRootRole(getUserRoles[user]);
        }

        bytes32 userRoles = getUserRoles[user];
        // either user has the specified role or user has root role (whichs gives it permission to do anything)
        // Note: For root it will return true even if the role hasn't been created yet
        return uint256(userRoles >> roleId) & 1 != 0 || isRoleAdmin(user, roleId);
    }

    /**
     * @notice Checks whether a user has a role that can admin a particular role
     * @param user Address being checked for admin rights over the role
     * @param roleId ID of the role being checked
     * @return True if the user has admin rights over the role
     */
    function isRoleAdmin(address user, uint8 roleId) public view returns (bool) {
        // Safe owner role has no admin as it is a dynamic role (assigned and revoked by the Safe)
        return roleId < SAFE_OWNER_ROLE_ID ? _isRoleAdmin(user, getUserRoles[user], roleId) : false;
    }

    /**
     * @notice Checks whether a role exists
     * @param roleId ID of the role being checked
     * @return True if the role has been created
     */
    function roleExists(uint8 roleId) public view returns (bool) {
        return roleId == ROOT_ROLE_ID // Root role is allowed to be left without admins
            || roleId == SAFE_OWNER_ROLE_ID // Safe owner role doesn't have admins as it is a dynamic role
            || getRoleAdmins[roleId] != NO_ROLE_ADMINS; // All other roles must have admins if they exist
    }

    function _isRoleAdmin(address user, bytes32 userRoles, uint8 roleId) internal view returns (bool) {
        bytes32 roleAdmins = getRoleAdmins[roleId];

        // A user is considered an admin of a role if any of the following are true:
        // - User explicitly has a role that is an admin of the role
        // - User has the root role, the role exists, and the role checked is not the root role (allows for root to be left without admins)
        // - User is an owner of the safe and the safe owner role is an admin of the role

        return (userRoles & roleAdmins) != 0
            || (_hasRootRole(userRoles) && roleExists(roleId) && roleId != ROOT_ROLE_ID)
            || (uint256(roleAdmins >> SAFE_OWNER_ROLE_ID) & 1 != 0 && safe().isOwner(user));
    }

    function _hasRootRole(bytes32 userRoles) internal pure returns (bool) {
        // Since root role is always at ID 0, we don't need to shift
        return uint256(userRoles) & 1 != 0;
    }

    function _allRoleAdminsExist(bytes32 roleAdmins, uint256 _roleCount) internal pure returns (bool) {
        // Since the last roleId always exists, we remove that bit from the roleAdmins
        return uint256(roleAdmins & SAFE_OWNER_ROLE_MASK) < (1 << _roleCount);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

uint8 constant ROOT_ROLE_ID = 0;
uint8 constant ROLE_MANAGER_ROLE_ID = 1;
// The last possible role is an unassingable role which is dynamic
// and having it or not depends on whether the user is an owner in the Safe
uint8 constant SAFE_OWNER_ROLE_ID = 255;

bytes32 constant ONLY_ROOT_ROLE_AS_ADMIN = bytes32(uint256(1));
bytes32 constant NO_ROLE_ADMINS = bytes32(0);

interface IRoles {
    function roleExists(uint8 roleId) external view returns (bool);
    function hasRole(address user, uint8 roleId) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {BaseGuard, Enum} from "safe/base/GuardManager.sol";

import {FirmBase, ISafe, IMPL_INIT_NOOP_ADDR, IMPL_INIT_NOOP_SAFE} from "../bases/FirmBase.sol";

import {ISemaphore} from "./interfaces/ISemaphore.sol";

/**
 * @title Semaphore
 * @author Firm ([email protected])
 * @notice Simple access control system intended to balance permissions between pairs of accounts
 * Compliant with the Safe Guard interface and designed to limit power of Safe owners via multisig txs
 */
contract Semaphore is FirmBase, BaseGuard, ISemaphore {
    string public constant moduleId = "org.firm.semaphore";
    uint256 public constant moduleVersion = 1;

    enum DefaultMode {
        Disallow,
        Allow
    }

    struct SemaphoreState {
        // Configurable state
        DefaultMode defaultMode;
        bool allowDelegateCalls;
        bool allowValueCalls;
        
        // Counters
        uint64 numTotalExceptions;
        uint32 numSigExceptions;
        uint32 numTargetExceptions;
        uint32 numTargetSigExceptions;
    } // 1 slot

    enum ExceptionType {
        Sig,
        Target,
        TargetSig
    }

    struct ExceptionInput {
        bool add;
        ExceptionType exceptionType;
        address caller;
        address target;  // only used for Target and TargetSig (ignored for Sig)
        bytes4 sig;      // only used for Sig and TargetSig (ignored for Target)
    }

    // caller => state
    mapping (address => SemaphoreState) public state;
    // caller => sig => bool (whether executing functions with this sig on any target is an exception to caller's defaultMode)
    mapping (address => mapping (bytes4 => bool)) public sigExceptions;
    // caller => target => bool (whether calling this target is an exception to caller's defaultMode)
    mapping (address => mapping (address => bool)) public targetExceptions;
    // caller => target => sig => bool (whether executing functions with this sig on this target is an exception to caller's defaultMode)
    mapping (address => mapping (address => mapping (bytes4 => bool))) public targetSigExceptions;

    event SemaphoreStateSet(address indexed caller, DefaultMode defaultMode, bool allowDelegateCalls, bool allowValueCalls);
    event ExceptionSet(address indexed caller, bool added, ExceptionType exceptionType, address target, bytes4 sig);

    error ExceptionAlreadySet(ExceptionInput exception);

    constructor() {
        // Initialize with impossible values in constructor so impl base cannot be used
        initialize(IMPL_INIT_NOOP_SAFE, false, IMPL_INIT_NOOP_ADDR);
    }

    function initialize(ISafe safe_, bool safeAllowsDelegateCalls, address trustedForwarder_) public {
        // calls SafeAware.__init_setSafe which reverts on reinitialization
        __init_firmBase(safe_, trustedForwarder_);

        // state[safe] represents the state when performing checks on the Safe multisig transactions checked via
        // Safe is marked as allowed by default (too dangerous to disallow by default or leave as an option)
        // Value calls are allowed by default for Safe
        _setSemaphoreState(address(safe_), DefaultMode.Allow, safeAllowsDelegateCalls, true);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // STATE AND EXCEPTIONS MANAGEMENT
    ////////////////////////////////////////////////////////////////////////////////

    /**
     * @notice Sets the base state for a caller
     * @dev Note: Use with extreme caution on live organizations, can lead to irreversible loss of access and funds
     * @param defaultMode Whether calls from this caller are allowed by default
     * @param allowDelegateCalls Whether this caller is allowed to perform delegatecalls
     * @param allowValueCalls Whether this caller is allowed to perform calls with non-zero value (native asset transfers)
     */
    function setSemaphoreState(address caller, DefaultMode defaultMode, bool allowDelegateCalls, bool allowValueCalls) external onlySafe {
        _setSemaphoreState(caller, defaultMode, allowDelegateCalls, allowValueCalls);
    }

    function _setSemaphoreState(address caller, DefaultMode defaultMode, bool allowDelegateCalls, bool allowValueCalls) internal {
        SemaphoreState storage s = state[caller];
        s.defaultMode = defaultMode;
        s.allowDelegateCalls = allowDelegateCalls;
        s.allowValueCalls = allowValueCalls;

        emit SemaphoreStateSet(caller, defaultMode, allowDelegateCalls, allowValueCalls);
    }

    /**
     * @notice Adds expections to the default mode for calls
     * @dev Note: Use with extreme caution on live organizations, can lead to irreversible loss of access and funds
     * @param exceptions Array of new exceptions to be applied
     */
    function addExceptions(ExceptionInput[] calldata exceptions) external onlySafe {
        for (uint256 i = 0; i < exceptions.length;) {
            ExceptionInput memory e = exceptions[i];
            SemaphoreState storage s = state[e.caller];

            if (e.exceptionType == ExceptionType.Sig) {
                if (e.add == sigExceptions[e.caller][e.sig]) {
                    revert ExceptionAlreadySet(e);
                }
                sigExceptions[e.caller][e.sig] = e.add;
                s.numSigExceptions = e.add ? s.numSigExceptions + 1 : s.numSigExceptions - 1;
            } else if (e.exceptionType == ExceptionType.Target) {
                if (e.add == targetExceptions[e.caller][e.target]) {
                    revert ExceptionAlreadySet(e);
                }
                targetExceptions[e.caller][e.target] = e.add;
                s.numTargetExceptions = e.add ? s.numTargetExceptions + 1 : s.numTargetExceptions - 1;
            } else if (e.exceptionType == ExceptionType.TargetSig) {
                if (e.add == targetSigExceptions[e.caller][e.target][e.sig]) {
                    revert ExceptionAlreadySet(e);
                }
                targetSigExceptions[e.caller][e.target][e.sig] = e.add;
                s.numTargetSigExceptions = e.add ? s.numTargetSigExceptions + 1 : s.numTargetSigExceptions - 1;
            }

            // A local counter for the specific exception type + the global exception type is added for the caller
            // Since per caller we need 1 slot of storage for its config, we can keep these counters within that same slot
            // As exception checking will be much more frequent and there will be many cases without exceptions,
            // it allows us to perform checks by just reading 1 slot if there are no exceptions and 2 if there's one
            // instead of always having to read 3 different slots (different mappings) for each possible exception that could be set
            s.numTotalExceptions = e.add ? s.numTotalExceptions + 1 : s.numTotalExceptions - 1;

            emit ExceptionSet(e.caller, e.add, e.exceptionType, e.target, e.sig);

            unchecked {
                i++;
            }
        }
    }

    ////////////////////////////////////////////////////////////////////////////////
    // CALL CHECKS (ISEMAPHORE)
    ////////////////////////////////////////////////////////////////////////////////

    function canPerform(address caller, address target, uint256 value, bytes calldata data, bool isDelegateCall) public view returns (bool) {
        SemaphoreState memory s = state[caller];

        if ((isDelegateCall && !s.allowDelegateCalls) ||
            (value > 0 && !s.allowValueCalls)) {
            return false;
        }

        // If there's an exception for this call, we flip the default mode for the caller
        return isException(s, caller, target, data)
            ? s.defaultMode == DefaultMode.Disallow
            : s.defaultMode == DefaultMode.Allow;
    }

    function canPerformMany(address caller, address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, bool isDelegateCall) public view returns (bool) {
        if (targets.length != values.length || targets.length != calldatas.length) {
            return false;
        }
        
        SemaphoreState memory s = state[caller];

        if (isDelegateCall && !s.allowDelegateCalls) {
            return false;
        }
        
        for (uint256 i = 0; i < targets.length;) {
            if (values[i] > 0 && !s.allowValueCalls) {
                return false;
            }

            bool isAllowed = isException(s, caller, targets[i], calldatas[i])
                ? s.defaultMode == DefaultMode.Disallow
                : s.defaultMode == DefaultMode.Allow;

            if (!isAllowed) {
                return false;
            }

            unchecked {
                i++;
            }
        }

        return true;
    }

    function isException(SemaphoreState memory s, address from, address target, bytes calldata data) internal view returns (bool) {
        if (s.numTotalExceptions == 0) {
            return false;
        }

        bytes4 sig = data.length >= 4 ? bytes4(data[:4]) : bytes4(0);
        return
            (s.numSigExceptions > 0 && sigExceptions[from][sig]) ||
            (s.numTargetExceptions > 0 && targetExceptions[from][target]) ||
            (s.numTargetSigExceptions > 0 && targetSigExceptions[from][target][sig]);
    }

    ////////////////////////////////////////////////////////////////////////////////
    // SAFE GUARD COMPLIANCE
    ////////////////////////////////////////////////////////////////////////////////

    function checkTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        Enum.Operation operation,
        uint256, uint256, uint256, address, address payable, bytes memory, address
    ) external view {
        if (!canPerform(msg.sender, to, value, data, operation == Enum.Operation.DelegateCall)) {
            revert ISemaphore.SemaphoreDisallowed();
        }
    }

    function checkAfterExecution(bytes32 txHash, bool success) external {}
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISemaphore {
    error SemaphoreDisallowed();
    
    function canPerform(address caller, address target, uint256 value, bytes calldata data, bool isDelegateCall) external view returns (bool);
    function canPerformMany(address caller, address[] calldata targets, uint256[] calldata values, bytes[] calldata calldatas, bool isDelegateCall) external view returns (bool);
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {Governor, IGovernor, Context} from "openzeppelin/governance/Governor.sol";
import {GovernorSettings} from "openzeppelin/governance/extensions/GovernorSettings.sol";
import {GovernorCountingSimple} from "openzeppelin/governance/extensions/GovernorCountingSimple.sol";

import {GovernorCaptableVotes, ICaptableVotes} from "./lib/GovernorCaptableVotes.sol";
import {GovernorCaptableVotesQuorumFraction} from "./lib/GovernorCaptableVotesQuorumFraction.sol";

// Base contract which aggregates all the different OpenZeppelin Governor extensions
// and makes it possible to use behind a proxy instead of with a constructor
abstract contract OZGovernor is
    Governor,
    GovernorSettings,
    GovernorCountingSimple,
    GovernorCaptableVotes,
    GovernorCaptableVotesQuorumFraction
{
    constructor() Governor(name()) GovernorSettings(1, 1, 1) {}

    function _setupGovernor(
        ICaptableVotes token_,
        uint256 quorumNumerator_,
        uint256 votingDelay_,
        uint256 votingPeriod_,
        uint256 proposalThreshold_
    ) internal {
        _setToken(token_);
        _updateQuorumNumerator(quorumNumerator_);
        _setVotingDelay(votingDelay_);
        _setVotingPeriod(votingPeriod_);
        _setProposalThreshold(proposalThreshold_);
    }

    function name() public pure override returns (string memory) {
        return "FirmVoting";
    }

    function quorumDenominator() public pure override returns (uint256) {
        return 10000;
    }

    // Reject receiving assets

    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     */
    function onERC721Received(address, address, uint256, bytes memory) public virtual override returns (bytes4) {
        // Reject receiving assets
        return bytes4(0);
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155Received}.
     */
    function onERC1155Received(address, address, uint256, uint256, bytes memory)
        public
        virtual
        override
        returns (bytes4)
    {
        // Reject receiving assets
        return bytes4(0);
    }

    /**
     * @dev See {IERC1155Receiver-onERC1155BatchReceived}.
     */
    function onERC1155BatchReceived(address, address, uint256[] memory, uint256[] memory, bytes memory)
        public
        virtual
        override
        returns (bytes4)
    {
        // Reject receiving assets
        return bytes4(0);
    }

    // The following functions are overrides required by Solidity.

    function votingDelay() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingDelay();
    }

    function votingPeriod() public view override(IGovernor, GovernorSettings) returns (uint256) {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorCaptableVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function proposalThreshold() public view override(Governor, GovernorSettings) returns (uint256) {
        return super.proposalThreshold();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {OZGovernor, Context} from "./OZGovernor.sol";
import {ICaptableVotes} from "../captable/interfaces/ICaptableVotes.sol";

import {FirmBase, ISafe, ERC2771Context, IMPL_INIT_NOOP_ADDR, IMPL_INIT_NOOP_SAFE} from "../bases/FirmBase.sol";
import {SafeModule} from "../bases/SafeModule.sol";
import {SemaphoreAuth, ISemaphore, NO_SEMAPHORE} from "../bases/SemaphoreAuth.sol";
import {SafeAware} from "../bases/SafeAware.sol";

/**
 * @title Voting
 * @author Firm ([email protected])
 * @notice Voting module wrapping OpenZeppelin's Governor compatible with Firm's Captable
 * https://docs.openzeppelin.com/contracts/4.x/api/governance
 */
contract Voting is FirmBase, SafeModule, SemaphoreAuth, OZGovernor {
    string public constant moduleId = "org.firm.voting";
    uint256 public constant moduleVersion = 1;

    error ProposalExecutionFailed(uint256 proposalId);

    constructor() {
        // Initialize with impossible values in constructor so impl base cannot be used
        initialize(
            IMPL_INIT_NOOP_SAFE, NO_SEMAPHORE, ICaptableVotes(IMPL_INIT_NOOP_ADDR), quorumDenominator(), 0, 1, 1, IMPL_INIT_NOOP_ADDR
        );
    }

    function initialize(
        ISafe safe_,
        ISemaphore semaphore_,
        ICaptableVotes token_,
        uint256 quorumNumerator_,
        uint256 votingDelay_,
        uint256 votingPeriod_,
        uint256 proposalThreshold_,
        address trustedForwarder_
    ) public {
        // calls SafeAware.__init_setSafe which reverts on reinitialization
        __init_firmBase(safe_, trustedForwarder_);
        _setSemaphore(semaphore_);
        _setupGovernor(token_, quorumNumerator_, votingDelay_, votingPeriod_, proposalThreshold_);
    }

    function _executor() internal view override returns (address) {
        return address(safe());
    }

    function propose(
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        string memory description
    ) public override returns (uint256) {
        // Since Voting config functions can only be called by voting itself, we need to filter them out
        // to avoid locking the voting module. Semaphore checks do not apply to these calls.
        (
            address[] memory checkingTargets,
            uint256[] memory checkingValues,
            bytes[] memory checkingCalldatas
        ) = _filterCallsToTarget(address(this), targets, values, calldatas);

        // Will revert if one of the external calls in the proposal is not allowed by the semaphore
        _semaphoreCheckCalls(checkingTargets, checkingValues, checkingCalldatas, false);

        return super.propose(targets, values, calldatas, description);
    }

    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override {
        bytes memory data =
            abi.encodeCall(this.__safeContext_execute, (proposalId, targets, values, calldatas, descriptionHash));

        if (!_moduleExecDelegateCallToSelf(data)) {
            revert ProposalExecutionFailed(proposalId);
        }
    }

    function __safeContext_execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) external onlyForeignContext {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    // Since both OZGovernor and FirmBase use ERC-2771 contexts but use different implementations
    // we need to override the following functions to specify to use FirmBase's implementation

    function _msgSender() internal view override(Context, ERC2771Context, SafeAware) returns (address) {
        return ERC2771Context._msgSender();
    }

    function _msgData() internal view override(Context, ERC2771Context) returns (bytes calldata) {
        return ERC2771Context._msgData();
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {Governor} from "@openzeppelin/contracts/governance/Governor.sol";

import {ICaptableVotes} from "../../captable/interfaces/ICaptableVotes.sol";

// Slightly modified of GovernorVotes from OpenZeppelin to use the more limited ICaptableVotes interface
// and set it with an internal function instead of a constructor argument
abstract contract GovernorCaptableVotes is Governor {
    ICaptableVotes public token;

    function _setToken(ICaptableVotes token_) internal {
        token = token_;
    }

    /**
     * Read the voting weight from the token's built in snapshot mechanism (see {Governor-_getVotes}).
     */
    function _getVotes(address account, uint256 blockNumber, bytes memory /*params*/ )
        internal
        view
        virtual
        override
        returns (uint256)
    {
        return token.getPastVotes(account, blockNumber);
    }
}

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.17;

import {GovernorCaptableVotes} from "./GovernorCaptableVotes.sol";
import "openzeppelin/utils/math/SafeCast.sol";
import "openzeppelin/utils/Checkpoints.sol";

// Zero-modifications version of GovernorVotesQuorumFraction from OpenZeppelin
// which inherits from our own GovernorCaptableVotes instead of GovernorVotes
abstract contract GovernorCaptableVotesQuorumFraction is GovernorCaptableVotes {
    using Checkpoints for Checkpoints.History;

    uint256 private _quorumNumerator; // DEPRECATED
    Checkpoints.History private _quorumNumeratorHistory;

    event QuorumNumeratorUpdated(uint256 oldQuorumNumerator, uint256 newQuorumNumerator);

    /**
     * @dev Initialize quorum as a fraction of the token's total supply.
     *
     * The fraction is specified as `numerator / denominator`. By default the denominator is 100, so quorum is
     * specified as a percent: a numerator of 10 corresponds to quorum being 10% of total supply. The denominator can be
     * customized by overriding {quorumDenominator}.
     *     constructor(uint256 quorumNumeratorValue) {
     *         _updateQuorumNumerator(quorumNumeratorValue);
     *     }
     */

    /**
     * @dev Returns the current quorum numerator. See {quorumDenominator}.
     */
    function quorumNumerator() public view virtual returns (uint256) {
        return _quorumNumeratorHistory._checkpoints.length == 0 ? _quorumNumerator : _quorumNumeratorHistory.latest();
    }

    /**
     * @dev Returns the quorum numerator at a specific block number. See {quorumDenominator}.
     */
    function quorumNumerator(uint256 blockNumber) public view virtual returns (uint256) {
        // If history is empty, fallback to old storage
        uint256 length = _quorumNumeratorHistory._checkpoints.length;
        if (length == 0) {
            return _quorumNumerator;
        }

        // Optimistic search, check the latest checkpoint
        Checkpoints.Checkpoint memory latest = _quorumNumeratorHistory._checkpoints[length - 1];
        if (latest._blockNumber <= blockNumber) {
            return latest._value;
        }

        // Otherwise, do the binary search
        return _quorumNumeratorHistory.getAtBlock(blockNumber);
    }

    /**
     * @dev Returns the quorum denominator. Defaults to 100, but may be overridden.
     */
    function quorumDenominator() public view virtual returns (uint256) {
        return 100;
    }

    /**
     * @dev Returns the quorum for a block number, in terms of number of votes: `supply * numerator / denominator`.
     */
    function quorum(uint256 blockNumber) public view virtual override returns (uint256) {
        return (token.getPastTotalSupply(blockNumber) * quorumNumerator(blockNumber)) / quorumDenominator();
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - Must be called through a governance proposal.
     * - New numerator must be smaller or equal to the denominator.
     */
    function updateQuorumNumerator(uint256 newQuorumNumerator) external virtual onlyGovernance {
        _updateQuorumNumerator(newQuorumNumerator);
    }

    /**
     * @dev Changes the quorum numerator.
     *
     * Emits a {QuorumNumeratorUpdated} event.
     *
     * Requirements:
     *
     * - New numerator must be smaller or equal to the denominator.
     */
    function _updateQuorumNumerator(uint256 newQuorumNumerator) internal virtual {
        require(
            newQuorumNumerator <= quorumDenominator(),
            "GovernorVotesQuorumFraction: quorumNumerator over quorumDenominator"
        );

        uint256 oldQuorumNumerator = quorumNumerator();

        // Make sure we keep track of the original numerator in contracts upgraded from a version without checkpoints.
        if (oldQuorumNumerator != 0 && _quorumNumeratorHistory._checkpoints.length == 0) {
            _quorumNumeratorHistory._checkpoints.push(
                Checkpoints.Checkpoint({_blockNumber: 0, _value: SafeCast.toUint224(oldQuorumNumerator)})
            );
        }

        // Set new quorum for future proposals
        _quorumNumeratorHistory.push(newQuorumNumerator);

        emit QuorumNumeratorUpdated(oldQuorumNumerator, newQuorumNumerator);
    }
}