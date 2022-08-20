/**
 *Submitted for verification at Etherscan.io on 2022-08-20
*/

// File: @openzeppelin/contracts/utils/Strings.sol


// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

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

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// File: intern.sol

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;


contract intern{
    struct transaction{
        string BuyerPAN;
        string SellerPAN;
        uint InvoiceAmount;
        uint InvoiceDate;
        bool status;
    }
    
    mapping(string => transaction)public transactionDetails;
    mapping(address => string)public addressToString;
    mapping(string => address payable)public stringToAddress;

    function transact(string memory buyerPAN,string memory sellerPAN,uint invoiceAmount)public payable{
        
        transactionDetails[buyerPAN].BuyerPAN = buyerPAN;
        transactionDetails[buyerPAN].SellerPAN = sellerPAN;
        transactionDetails[buyerPAN].InvoiceAmount = invoiceAmount;
        transactionDetails[buyerPAN].InvoiceDate = block.timestamp;
        transactionDetails[buyerPAN].status = true;
    }
    function getPAN(address addr) public view returns(string memory){
        return addressToString[addr];
    }

    function getaddr(string memory PAN)public view returns(address){
        return stringToAddress[PAN];
    }

    function register(string memory PAN,address addr)public {
        stringToAddress[PAN] = payable(addr);
        addressToString[addr] = PAN;
    }


    //working in progress

    function getSellerPAN(string memory buyerPAN) public view returns(string memory){
        return transactionDetails[buyerPAN].SellerPAN;
    }

    function getInvoiceAmount(string memory buyerPAN) public view returns(uint){
        return transactionDetails[buyerPAN].InvoiceAmount;
    }

    function getTransactionDate(string memory buyerPAN) public view returns(string memory){

       uint256 timest=transactionDetails[buyerPAN].InvoiceDate;
       uint256 year;
       uint256 month;
       uint256 day;
       (year,month,day)=timestampToDate(timest);

       string memory d;
       string memory m;
       string memory y;
       d=Strings.toString(day);
       m=Strings.toString(month);
       y=Strings.toString(year);

       bytes memory b;
       b = abi.encodePacked(d,"/",m,"/",y);

       string memory str = string(b);
       return str;
    }

    function getTransactionStatus(string memory buyerPAN) public view returns(bool){
                return transactionDetails[buyerPAN].status;
    }

    //Timesstamp to date
    function _daysToDate(uint256 _days)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
        int256 __days = int256(_days);
        int256  OFFSET19700101 = 2440588;
        int256 L = __days + 68569 + OFFSET19700101;
        int256 N = (4 * L) / 146097;
        L = L - (146097 * N + 3) / 4;
        int256 _year = (4000 * (L + 1)) / 1461001;
        L = L - (1461 * _year) / 4 + 31;
        int256 _month = (80 * L) / 2447;
        int256 _day = L - (2447 * _month) / 80;
        L = _month / 11;
        _month = _month + 2 - 12 * L;
        _year = 100 * (N - 49) + _year + L;

        year = uint256(_year);
        month = uint256(_month);
        day = uint256(_day);
    }

    function timestampToDate(uint256 timestamp)
        internal
        pure
        returns (
            uint256 year,
            uint256 month,
            uint256 day
        )
    {
                uint256  SECONDS_PER_DAY = 24 * 60 * 60;

        (year, month, day) = _daysToDate(timestamp / SECONDS_PER_DAY);
    }
}