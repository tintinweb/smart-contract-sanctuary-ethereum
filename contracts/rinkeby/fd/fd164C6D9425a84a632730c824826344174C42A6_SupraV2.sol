// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Supra.sol";
import "./Storage.sol";
import "./IStorage.sol";

contract SupraV2 is Supra {

    IStorage storageContract;

    mapping(address => bool) accessAllowed;

    function UserStorageAccess() public {
        accessAllowed[msg.sender] = true;
    }

    function allowAccess (address _address) isAllowed public {
         accessAllowed[_address] = true;
    }

    function denyAccess (address _address) isAllowed public {
         accessAllowed[_address] = false;
     }

   function returnTimestamp() external returns(uint256){
       return block.timestamp;
   }

   modifier isAllowed() {
        require(accessAllowed[msg.sender] == true);
        _;
    }

   function setStorageContract(address _feedStorageAddress) public {
        storageContract = IStorage(_feedStorageAddress);
    }

    function updateCurrentPrice(string memory currency_pair, string memory price) isAllowed public returns(bool){
        storageContract.setCurrentPrice(currency_pair, price);
        return true;
    }

    function updateWeeklyPrice(string memory currency_pair, string memory price) isAllowed public returns(bool){
        storageContract.setWeeklyPrice(currency_pair, price);
        return true;
    }

    function updateTemperatureData(string memory key, string memory value) isAllowed public returns (bool){
        storageContract.handlerTemperatureDB(key, value);
        return true;
    }




}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

// import "@openzeppelin/contracts-upgradeable/proxy/Initializable.sol";
import "./Strings.sol";
import "./Storage.sol";

contract Supra {
    using strings for *;
    string public name;

    struct Price {
        string currentPrice;
        uint256 currentPriceTimeStamp;
        string weeklyPrice;
        uint256 weeklyPriceTimeStamp;
    }

    struct Temperature {
        string currentTemp;
        uint256 updateTimestamp;
    }
    
    mapping(string => Price) priceDB;

    mapping(string => Temperature) temperatureDB;

    // function initialize() external initializer {
    //     name = "Test contract upgradeables official";
    // }

    // current price | last updated time
    function getCurrentPrice(string memory currencyPair) public view returns(string memory, uint256){
      return (priceDB[currencyPair].currentPrice, priceDB[currencyPair].currentPriceTimeStamp);
    }

    // weekly price | last updated time
    function getWeeklyPrice(string memory currencyPair) public view returns(string memory, uint256){
      return (priceDB[currencyPair].weeklyPrice, priceDB[currencyPair].weeklyPriceTimeStamp);
    }

    function getTemperatureData(string memory key) public view returns(string memory, uint256) {
        return(temperatureDB[key].currentTemp, temperatureDB[key].updateTimestamp);
    } 

    // True == current data | False == weekly data    
    function storePriceFeed(string memory _feeds, bool flag, uint targetDB) public returns (string memory) {
            string[] memory _feedArray;
            _feeds = cancat(_feeds, "-");
            _feedArray = splitStr("-", _feeds);
            
            uint arrayLength = _feedArray.length;

            for (uint i=0; i<arrayLength; i++) {
                string[] memory _values;
                _values = splitStr(":", cancat(_feedArray[i], ":")); 
                string memory key = _values[0];
                string memory value = _values[1];
    
                require(storageEngine(key, value, flag, targetDB), "Storage engine error");  // send to handler  
            }

        return "success";
    }

    function handlerPriceDB(string memory key, string memory value, bool flag) internal returns (bool){
     if(flag){
            priceDB[key].currentPrice = value;
            priceDB[key].currentPriceTimeStamp = block.timestamp;
        } else {
            priceDB[key].weeklyPrice = value;
            priceDB[key].weeklyPriceTimeStamp = block.timestamp;
        }
        return true;
    }

    function handlerTemperatureDB(string memory key, string memory value) internal returns (bool){
        temperatureDB[key].currentTemp = value;
        temperatureDB[key].updateTimestamp = block.timestamp;
        return true;
    }
   
    function storageEngine(string memory key, string memory value, bool flag, uint targetDB) internal returns (bool){
       if(targetDB == 1){
            require(handlerPriceDB(key, value, flag),"handler priceDB error");
       }else {
           require(handlerTemperatureDB(key, value),"handler priceDB error");
       }

        return true;
    }

    function splitStr(string memory splitter, string memory str) public pure returns (string[] memory) {
        strings.slice memory s = str.toSlice();
        strings.slice memory delim = splitter.toSlice();
        string[] memory parts = new string[](s.count(delim));
        for (uint i = 0; i < parts.length; i++) {
            parts[i] = s.split(delim).toString();
        }
        return parts;
    }

    function cancat(string memory a, string memory b) internal pure returns(string memory){
        return (string(abi.encodePacked(a,b)));
    }

    function strToUint(string memory _str) internal pure returns(uint256 res) {

        for (uint256 i = 0; i < bytes(_str).length; i++) {
            if ((uint8(bytes(_str)[i]) - 48) < 0 || (uint8(bytes(_str)[i]) - 48) > 9) {
                return 0;
            }
            res += (uint8(bytes(_str)[i]) - 48) * 10**(bytes(_str).length - i - 1);
        }

        return res;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Storage {

    struct priceFeedData {
        string currentPrice;
        string weeklyPrice;
        uint256 currentPriceTimeStamp; 
        uint256 weeklyPriceTimeStamp; 
    }

    struct temperatureData {
        string currentTemp;
        uint256 Timestamp;
    }

    mapping(string => priceFeedData) internal priceDB; 
    mapping(string => temperatureData) internal temperatureDB;
    mapping(bytes32 => bool) internal boolStorage;

    function setCurrentPrice(string memory currencyPair, string memory price) public {
        priceDB[currencyPair].currentPrice = price;
        priceDB[currencyPair].currentPriceTimeStamp = block.timestamp;
    }

    function setWeeklyPrice(string memory currencyPair, string memory price) public {
        priceDB[currencyPair].weeklyPrice = price;
        priceDB[currencyPair].weeklyPriceTimeStamp = block.timestamp;
    }

    function setTemperatureData(string memory key, string memory currentTemperature) public {
        temperatureDB[key].currentTemp = currentTemperature;
        temperatureDB[key].Timestamp = block.timestamp;
    }


     function getCurrentPrice(string memory currencyPair) public view returns(string memory, uint256){
      return (priceDB[currencyPair].currentPrice, priceDB[currencyPair].currentPriceTimeStamp);
    }

    function getWeeklyPrice(string memory currencyPair) public view returns(string memory, uint256){
      return (priceDB[currencyPair].weeklyPrice, priceDB[currencyPair].weeklyPriceTimeStamp);
    }

    function getTemperatureData(string memory key) public view returns(string memory,uint256) {
        return (temperatureDB[key].currentTemp, temperatureDB[key].Timestamp);
    }

}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IStorage {

    function updateCurrentPrice(string memory currency_pair, string memory price) external returns(bool);

    function updateWeeklyPrice(string memory currency_pair, string memory price) external returns(bool);

    function updateTemperatureData(string memory key, string memory value) external returns (bool);

    function setCurrentPrice(string memory currencyPair, string memory price) external;

    function setWeeklyPrice(string memory currencyPair, string memory price) external;

    function handlerTemperatureDB(string memory key, string memory value) external returns (bool);

    function getCurrentPrice() external;

    function getWeeklyPrice() external;

    function getTemperatureData() external;

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    /*
     * @dev Returns a slice containing the entire string.
     * @param self The string to make a slice from.
     * @return A newly allocated slice containing the entire string.
     */
    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }


    /*
     * @dev Returns a new slice containing the same data as the current slice.
     * @param self The slice to copy.
     * @return A new slice containing the same data as `self`.
     */
    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }



    /*
     * @dev Returns the length in runes of the slice. Note that this operation
     *      takes time proportional to the length of the slice; avoid using it
     *      in loops, and call `slice.empty()` if you only need to know whether
     *      the slice is empty or not.
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function len(slice memory self) internal pure returns (uint l) {
        // Starting at ptr-31 means the LSB will be the byte we care about
        uint ptr = self._ptr - 31;
        uint end = ptr + self._len;
        for (l = 0; ptr < end; l++) {
            uint8 b;
            assembly { b := and(mload(ptr), 0xFF) }
            if (b < 0x80) {
                ptr += 1;
            } else if(b < 0xE0) {
                ptr += 2;
            } else if(b < 0xF0) {
                ptr += 3;
            } else if(b < 0xF8) {
                ptr += 4;
            } else if(b < 0xFC) {
                ptr += 5;
            } else {
                ptr += 6;
            }
        }
    }

    /*
     * @dev Returns true if the slice is empty (has a length of 0).
     * @param self The slice to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }




    /*
     * @dev Extracts the first rune in the slice into `rune`, advancing the
     *      slice to point to the next rune and returning `self`.
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextRune(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first byte of the rune into the LSBs of b
        assembly { b := and(mload(sub(mload(add(self, 32)), 31)), 0xFF) }
        if (b < 0x80) {
            l = 1;
        } else if(b < 0xE0) {
            l = 2;
        } else if(b < 0xF0) {
            l = 3;
        } else {
            l = 4;
        }

        // Check for truncated codepoints
        if (l > self._len) {
            rune._len = self._len;
            self._ptr += self._len;
            self._len = 0;
            return rune;
        }

        self._ptr += l;
        self._len -= l;
        rune._len = l;
        return rune;
    }

    /*
     * @dev Returns the first rune in the slice, advancing the slice to point
     *      to the next rune.
     * @param self The slice to operate on.
     * @return A slice containing only the first rune from `self`.
     */
    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

    /*
     * @dev Returns the number of the first codepoint in the slice.
     * @param self The slice to operate on.
     * @return The number of the first codepoint in the slice.
     */
    function ord(slice memory self) internal pure returns (uint ret) {
        if (self._len == 0) {
            return 0;
        }

        uint word;
        uint length;
        uint divisor = 2 ** 248;

        // Load the rune into the MSBs of b
        assembly { word:= mload(mload(add(self, 32))) }
        uint b = word / divisor;
        if (b < 0x80) {
            ret = b;
            length = 1;
        } else if(b < 0xE0) {
            ret = b & 0x1F;
            length = 2;
        } else if(b < 0xF0) {
            ret = b & 0x0F;
            length = 3;
        } else {
            ret = b & 0x07;
            length = 4;
        }

        // Check for truncated codepoints
        if (length > self._len) {
            return 0;
        }

        for (uint i = 1; i < length; i++) {
            divisor = divisor / 256;
            b = (word / divisor) & 0xFF;
            if (b & 0xC0 != 0x80) {
                // Invalid UTF-8 sequence
                return 0;
            }
            ret = (ret * 64) | (b & 0x3F);
        }

        return ret;
    }

    /*
     * @dev Returns the keccak-256 hash of the slice.
     * @param self The slice to hash.
     * @return The hash of the slice.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

    /*
     * @dev Returns true if `self` starts with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function startsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        if (self._ptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let selfptr := mload(add(self, 0x20))
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }
        return equal;
    }

    /*
     * @dev If `self` starts with `needle`, `needle` is removed from the
     *      beginning of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function beyond(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        bool equal = true;
        if (self._ptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let selfptr := mload(add(self, 0x20))
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
            self._ptr += needle._len;
        }

        return self;
    }

    /*
     * @dev Returns true if the slice ends with `needle`.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function endsWith(slice memory self, slice memory needle) internal pure returns (bool) {
        if (self._len < needle._len) {
            return false;
        }

        uint selfptr = self._ptr + self._len - needle._len;

        if (selfptr == needle._ptr) {
            return true;
        }

        bool equal;
        assembly {
            let length := mload(needle)
            let needleptr := mload(add(needle, 0x20))
            equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
        }

        return equal;
    }

    /*
     * @dev If `self` ends with `needle`, `needle` is removed from the
     *      end of `self`. Otherwise, `self` is unmodified.
     * @param self The slice to operate on.
     * @param needle The slice to search for.
     * @return `self`
     */
    function until(slice memory self, slice memory needle) internal pure returns (slice memory) {
        if (self._len < needle._len) {
            return self;
        }

        uint selfptr = self._ptr + self._len - needle._len;
        bool equal = true;
        if (selfptr != needle._ptr) {
            assembly {
                let length := mload(needle)
                let needleptr := mload(add(needle, 0x20))
                equal := eq(keccak256(selfptr, length), keccak256(needleptr, length))
            }
        }

        if (equal) {
            self._len -= needle._len;
        }

        return self;
    }

    // Returns the memory address of the first byte of the first occurrence of
    // `needle` in `self`, or the first byte after `self` if not found.
    function findPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr = selfptr;
        uint idx;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                uint end = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr >= end)
                        return selfptr + selflen;
                    ptr++;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }

                for (idx = 0; idx <= selflen - needlelen; idx++) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr;
                    ptr += 1;
                }
            }
        }
        return selfptr + selflen;
    }

    // Returns the memory address of the first byte after the last occurrence of
    // `needle` in `self`, or the address of `self` if not found.
    function rfindPtr(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
        uint ptr;

        if (needlelen <= selflen) {
            if (needlelen <= 32) {
                bytes32 mask = bytes32(~(2 ** (8 * (32 - needlelen)) - 1));

                bytes32 needledata;
                assembly { needledata := and(mload(needleptr), mask) }

                ptr = selfptr + selflen - needlelen;
                bytes32 ptrdata;
                assembly { ptrdata := and(mload(ptr), mask) }

                while (ptrdata != needledata) {
                    if (ptr <= selfptr)
                        return selfptr;
                    ptr--;
                    assembly { ptrdata := and(mload(ptr), mask) }
                }
                return ptr + needlelen;
            } else {
                // For long needles, use hashing
                bytes32 hash;
                assembly { hash := keccak256(needleptr, needlelen) }
                ptr = selfptr + (selflen - needlelen);
                while (ptr >= selfptr) {
                    bytes32 testHash;
                    assembly { testHash := keccak256(ptr, needlelen) }
                    if (hash == testHash)
                        return ptr + needlelen;
                    ptr -= 1;
                }
            }
        }
        return selfptr;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    /*
     * @dev Modifies `self` to contain the part of the string from the start of
     *      `self` to the end of the first occurrence of `needle`. If `needle`
     *      is not found, `self` is set to the empty slice.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and `token` to everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function split(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = self._ptr;
        token._len = ptr - self._ptr;
        if (ptr == self._ptr + self._len) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
            self._ptr = ptr + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything after the first
     *      occurrence of `needle`, and returning everything before it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` up to the first occurrence of `delim`.
     */
    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and `token` to everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and `token` is set to the entirety of `self`.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function rsplit(slice memory self, slice memory needle, slice memory token) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        token._ptr = ptr;
        token._len = self._len - (ptr - self._ptr);
        if (ptr == self._ptr) {
            // Not found
            self._len = 0;
        } else {
            self._len -= token._len + needle._len;
        }
        return token;
    }

    /*
     * @dev Splits the slice, setting `self` to everything before the last
     *      occurrence of `needle`, and returning everything after it. If
     *      `needle` does not occur in `self`, `self` is set to the empty slice,
     *      and the entirety of `self` is returned.
     * @param self The slice to split.
     * @param needle The text to search for in `self`.
     * @return The part of `self` after the last occurrence of `delim`.
     */
    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    /*
     * @dev Counts the number of nonoverlapping occurrences of `needle` in `self`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return The number of occurrences of `needle` found in `self`.
     */
    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }

    /*
     * @dev Returns True if `self` contains `needle`.
     * @param self The slice to search.
     * @param needle The text to search for in `self`.
     * @return True if `needle` is found in `self`, false otherwise.
     */
    function contains(slice memory self, slice memory needle) internal pure returns (bool) {
        return rfindPtr(self._len, self._ptr, needle._len, needle._ptr) != self._ptr;
    }

    function memcpy(uint dest, uint src, uint length) private pure {
        // Copy word-length chunks while possible
        for(; length >= 32; length -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - length) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }

    /*
     * @dev Copies a slice to a new string.
     * @param self The slice to copy.
     * @return A newly allocated string containing the slice's text.
     */
    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

}