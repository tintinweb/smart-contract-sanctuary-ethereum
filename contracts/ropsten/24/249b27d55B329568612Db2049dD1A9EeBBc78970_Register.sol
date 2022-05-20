//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;
pragma experimental ABIEncoderV2;
import "@openzeppelin/contracts/utils/Strings.sol";

contract Register{
    struct RegistrationInfo {
        address owner;
        uint askingPrice;
    }
    struct ReturnTypeRegistrationInfo {
        uint plotNumber;
        RegistrationInfo info;
    }
    mapping (uint => RegistrationInfo) Plots;
    uint[] keyArray;

    event OwnershipTransfered(uint plotNumber,address newOwner);
    event NewRegistration(uint plotNumber, address ownerAddres, uint askingPrice);
    event ChangeAskingPrice(uint plotNumber, uint newAskingPrice);

    function checkRegistration(uint plotNumber) public view returns (RegistrationInfo memory info){
        return Plots[plotNumber];
    }
    function getRegistrationList() public view returns (ReturnTypeRegistrationInfo[] memory data){
        ReturnTypeRegistrationInfo[] memory array;
        for(uint i=0; i<keyArray.length; i++){
         ReturnTypeRegistrationInfo memory object = ReturnTypeRegistrationInfo(keyArray[i],Plots[keyArray[i]]);
         array[i] = object;
        }
        return array;
    }

    function transferOwnership(uint plotNumber) public payable{
        require(msg.value >= Plots[plotNumber].askingPrice);
        payable(Plots[plotNumber].owner).transfer(msg.value);
        RegistrationInfo storage newOwner = Plots[plotNumber];
        newOwner.owner = msg.sender;
        emit OwnershipTransfered(plotNumber, msg.sender);
    }

    function registerPlot(uint plotNumber,uint price) public{
        RegistrationInfo memory newOwner = RegistrationInfo(msg.sender,price);
        Plots[plotNumber] = newOwner;
        keyArray.push(plotNumber);
        emit NewRegistration(plotNumber, msg.sender, price);
    }

    function changeAskingPrice(uint plotNumber, uint newAskingPrice) public {
        require(msg.sender == Plots[plotNumber].owner,'Only the owner can change the asking Price');
        Plots[plotNumber].askingPrice = newAskingPrice;
        emit ChangeAskingPrice(plotNumber, newAskingPrice);
    }
}

// SPDX-License-Identifier: MIT
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