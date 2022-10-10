/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @dev Decomposing Solidity's uint256 numbers 
 * to information with fixed-decimals
 * 
 * @notice     bytes32 [256 bits] [0 ~ 2**256-1] [78 decimals (1.15*10**77)]
 * 
 * Address   | bytes20 [160 bits] [0 ~ 2**160-1] [49 decimals (1.46*10**48)]
 * USD value | bytes6  [ 48 bits] [0 ~ 2**48-1 ] [15 decimals (2.81*10**14)]
 * Timestamp | bytes4  [ 32 bits] [0 ~ 2**32-1 ] [10 decimals (4.29*10**9 )]
 * APY       | bytes2  [ 16 bits] [0 ~ 2**16-1 ] [ 5 decimals (6.55*10**4 )]
 *
 * @notice `uint32` for timestamps will be okay till year 2106 
 * (https://ethereum.stackexchange.com/a/39238)
 * @notice The 5 decimals for APY is interpreted as xx.xxx %
 */
contract WecoverNumeric {

    uint8 private constant _addrByte = 20;
    uint8 private constant _usdByte  = 6;
    uint8 private constant _timeByte = 4;
    uint8 private constant _apyByte  = 2;

    uint256 private constant _max_uint = 2**256-1;
    uint256 private constant _max_usd  = 2**48-1;
    uint256 private constant _max_time = 2**32-1;
    uint256 private constant _max_apy  = 2**16-1;
    bytes32 private constant _ones = bytes32(_max_uint);

    /**
     * @dev number: 0x[][][]...[][] (256 bits where [] = bit)
     * The first (starting from the left) 20 []'s are for address,
     * next 6 []'s are for usd, and so on.
     * 
     * @notice bytes2([][][][][][][][]) will add 8 [0]'s on right hand side
     * (bytes start from the left)
     *
     * @notice unlike bytes2, uint16(uint8([][][][][][][][])) will add 8 [0]'s on the left hand side.
     *
     * @param start: starting bit (inclusive), 0 ~ 31
     * @param end: ending bit (inclusive), 0 ~ 31
     * @custom:ref https://jeancvllr.medium.com/solidity-tutorial-all-about-bytes-9d88fdb22676
     * @custom:ref https://github.com/ethereum/solidity-examples/blob/master/docs/bytes/Bytes.md
     */
    function _getBits(bytes32 number, uint8 start, uint8 end) internal pure returns(bytes32) {
        bytes32 mask = _ones << (255 - (end-start));
        return (number << start) & mask;
    }

    function addr_(bytes32 number) public pure returns(address) {
        // return address(bytes20(_getBits(number, 0, 159)));
        return address(bytes20(number));
    }

    function usd_(bytes32 number) public pure returns(uint48) {
        // return uint48(bytes6(_getBits(number, 160, 207)));
        return uint48(bytes6(number << 160));
    }

    function time_(bytes32 number) public pure returns(uint32) {
        // return uint32(bytes4(_getBits(number, 208, 239)));
        return uint32(bytes4(number << 208));
    }

    function apy_(bytes32 number) public pure returns(uint16) {
        // return uint16(bytes2(_getBits(number, 240, 255)));
        return uint16(bytes2(number << 240));
    }

    /**
     * @notice This function costs ~ 400 gas
     * @custom:ref https://ethereum.stackexchange.com/a/72347
     */
    function concat_(address ad_, uint48 us_, uint32 ti_, uint16 ap_) public pure returns(bytes32) {
        return bytes32(uint256(uint160(ad_)) << 96 | (uint96(uint80(us_) << 32 | ti_) << 16 | ap_));
        // return bytes32(uint256(uint240(uint208(uint160(ad_)) << 48 | us_) << 32 | ti_) << 16 | ap_);
        // This will cost ~ 2200 gas
        // return bytes32(bytes.concat(bytes.concat(bytes.concat(bytes20(ad_), bytes6(us_)), bytes4(ti_)), bytes2(ap_)));
    }

    /**
     * @notice This function costs ~ 100 gas
     */
    function set(bytes32 number, address ad_) public pure returns(bytes32) {
        return bytes32(bytes20(ad_)) | (number << 160 >> 160);
        // return bytes32(uint256(uint160(ad_)) << 96 | uint96(bytes12(number << 160)));
        // This will cost ~ 2000 gas
        // return concat_(ad_, usd_(number), time_(number), apy_(number));
    }

    /**
     * @notice This function costs ~ 400 gas
     */
    function set(bytes32 number, uint48 us_) public pure returns(bytes32) {
        return concat_(addr_(number), us_, time_(number), apy_(number));
    }

    function set(bytes32 number, uint32 ti_) public pure returns(bytes32) {
        return concat_(addr_(number), usd_(number), ti_, apy_(number));
    }

    function set(bytes32 number, uint16 ap_) public pure returns(bytes32) {
        return bytes32(uint256(ap_)) | (number >> 16 << 16);
        // return concat_(addr_(number), usd_(number), time_(number), ap_);
    }

    function safeUSD(uint256 us_) public pure returns(uint48) {
        require(us_ < _max_usd);
        return uint48(us_);
    }

    function safeTime(uint256 ti_) public pure returns(uint32) {
        require(ti_ < _max_time);
        return uint32(ti_);
    }

    function safeAPY(uint256 ap_) public pure returns(uint16) {
        require(ap_ < _max_apy);
        return uint16(ap_);
    }
}