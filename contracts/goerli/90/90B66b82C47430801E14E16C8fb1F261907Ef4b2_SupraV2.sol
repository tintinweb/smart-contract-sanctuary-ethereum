/*  
    ------------------------------------DEVELOPER INSTRUCTONS-----------------------------------------------
    TODO : Access control :::: Anchor contract
    ----------------------------------------------------------------------------------------------
    1. Function StoreFeed modified to accept weather data format. 
    2. StorageWeather maintains required struct and mapping for weather information.
    3. It includes all previous stored data and functionalities for price.
    -----------------------------------------------------------------------------------------------
    Note : Storage contract needs to be defined in advance. 


*/ 


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./SupraV1.sol";

interface IOracle_V2{
    function setWeatherInfo(string memory city, string memory val_1, string memory val_2, string memory val_3) external;
}

contract SupraV2 is SupraV1, IOracle_V2  {
   
    IOracle_V2 two_storageContract;

    function setOracleContract(address _oracleContract) public virtual override {
        two_storageContract = IOracle_V2(_oracleContract);
    }

    function storeFeed(string memory _feeds, bool flag, uint targetDB) public override returns (string memory) {
            string[] memory _feedArray;
            _feeds = cancat(_feeds, "-");
            _feedArray = splitStr("-", _feeds);
            
            uint arrayLength = _feedArray.length;
            string memory key = "";
            string memory value_1 = "";
            string memory value_2 = "";
            string memory value_3 = "";
   
            for (uint i=0; i<arrayLength; i++) {
                string[] memory _values;
                _values = splitStr(":", cancat(_feedArray[i], ":")); 
               
                if (targetDB == 1){
                    key = _values[0];
                    value_1 = _values[1];
                    handlerPriceDB(key, value_1, flag);
                } else if(targetDB == 2) {
                    key = _values[0];
                    value_1 = _values[1];
                    value_2 = _values[2];
                    value_3 = _values[3];
                    setWeatherInfo(key, value_1, value_2, value_3);   
                     
                }
            }

        return "success";
    }

    function setWeatherInfo(string memory city, string memory val_1, string memory val_2, string memory val_3) public override{
        two_storageContract.setWeatherInfo(city, val_1, val_2, val_3);
    }
 

}

/*  
    ------------------------------------DEVELOPER INSTRUCTONS-----------------------------------------------

    TODO : Access control :::: Anchor contract
    ----------------------------------------------------------------------------------------------
    1. Supports single currency pair as well dynamic range.
    2. For each service(say price feed) there is a dedicated struct and mapping.
    3. Function StoreFeed simply separates the key value and send it to Storage engine.
    4. This contract is only for one service. (i.e price feed data).
    5. Functions marked as virtual can be override by inheriting contracts.
    6. TargetDB : (PriceData : 1, WeatherData : 2) and so on..  


    TODO : Make sure current implementation contract is set in oracle contract.
    -----------------------------------------------------------------------------------------------
*/ 

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "./Strings.sol";

// interface IOracleContract_V1{
interface IOracleContract_V1{
    function setCurrentPrice(string memory currencyPair, string memory price) external;
    function setWeeklyPrice(string memory currencyPair, string memory price) external;
}


contract SupraV1 is IOracleContract_V1 {
    using strings for *;

    IOracleContract_V1 one_storageContract;
    
  
    function setOracleContract(address _oracleContract) public virtual {
        one_storageContract = IOracleContract_V1(_oracleContract);
    }

    // True == current data | False == weekly data    
    function storeFeed(string memory _feeds, bool flag, uint targetDB) public virtual returns (string memory) {
        // require("only bridge specific public key can call");

           string[] memory _feedArray;
            _feeds = cancat(_feeds, "-");
            _feedArray = splitStr("-", _feeds);
            
            uint arrayLength = _feedArray.length;
            string memory key = "";
            string memory value_1 = "";
       

            for (uint i=0; i<arrayLength; i++) {
                string[] memory _values;
                _values = splitStr(":", cancat(_feedArray[i], ":")); 
               
                key = _values[0];
                value_1 = _values[1];
          
                if (targetDB == 1){
                    handlerPriceDB(key, value_1, flag);
                } 
            }

        return "success";
    }

    function handlerPriceDB(string memory key, string memory value, bool flag) internal returns (bool){
     if(flag){
            setCurrentPrice(key, value);
        } else {
            setWeeklyPrice(key, value);
        }
        return true;
    }

    function splitStr(string memory splitter, string memory str) internal pure returns (string[] memory) {
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

    function setCurrentPrice(string memory currency_pair, string memory price) public override {
        one_storageContract.setCurrentPrice(currency_pair, price);
    }

    function setWeeklyPrice(string memory currency_pair, string memory price) public override {
        one_storageContract.setWeeklyPrice(currency_pair, price);
    }

}

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

library strings {
    struct slice {
        uint _len;
        uint _ptr;
    }

    function toSlice(string memory self) internal pure returns (slice memory) {
        uint ptr;
        assembly {
            ptr := add(self, 0x20)
        }
        return slice(bytes(self).length, ptr);
    }

    function copy(slice memory self) internal pure returns (slice memory) {
        return slice(self._len, self._ptr);
    }

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

    function empty(slice memory self) internal pure returns (bool) {
        return self._len == 0;
    }

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

    function nextRune(slice memory self) internal pure returns (slice memory ret) {
        nextRune(self, ret);
    }

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

    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }

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

    function find(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len -= ptr - self._ptr;
        self._ptr = ptr;
        return self;
    }

    function rfind(slice memory self, slice memory needle) internal pure returns (slice memory) {
        uint ptr = rfindPtr(self._len, self._ptr, needle._len, needle._ptr);
        self._len = ptr - self._ptr;
        return self;
    }

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

    function split(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        split(self, needle, token);
    }


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

    function rsplit(slice memory self, slice memory needle) internal pure returns (slice memory token) {
        rsplit(self, needle, token);
    }

    function count(slice memory self, slice memory needle) internal pure returns (uint cnt) {
        uint ptr = findPtr(self._len, self._ptr, needle._len, needle._ptr) + needle._len;
        while (ptr <= self._ptr + self._len) {
            cnt++;
            ptr = findPtr(self._len - (ptr - self._ptr), ptr, needle._len, needle._ptr) + needle._len;
        }
    }


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


    function toString(slice memory self) internal pure returns (string memory) {
        string memory ret = new string(self._len);
        uint retptr;
        assembly { retptr := add(ret, 32) }

        memcpy(retptr, self._ptr, self._len);
        return ret;
    }

}