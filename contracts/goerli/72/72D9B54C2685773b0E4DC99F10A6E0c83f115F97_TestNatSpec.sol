// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract TestNatSpec {
    constructor() {
        test1(0, 0);
        test2(0, 0);
        test3(0, 0);
        test4(0, 0);
        test5(0, 0);
        test6(0, 0);
    }

    /**
     * @notice This is standard comment style and spacing, should work
     * @param param1 param1 details
     * @param param2 param2 details
     * @return return1 return1 details
     */
    function test1(uint256 param1, uint256 param2) pure public returns (uint256) {
        return param1 + param2;
    }

    /**
     * @notice Extra * in endcomment
     * @param param1 param1 details
     * @param param2 param2 details
     * @return return1 return1 details
     **/
    function test2(uint256 param1, uint256 param2) pure public returns (uint256) {
        return param1 + param2;
    }

    /**
     * @notice Newline after comments
     * @param param1 param1 details
     * @param param2 param2 details
     * @return return1 return1 details
     */

    function test3(uint256 param1, uint256 param2) pure public returns (uint256) {
        return param1 + param2;
    }

    /**
     * @notice Newline after comments and extra * in endcomment
     * @param param1 param1 details
     * @param param2 param2 details
     * @return return1 return1 details
     **/

    function test4(uint256 param1, uint256 param2) pure public returns (uint256) {
        return param1 + param2;
    }

    /**
     *
     * @notice Newlines spread through comments
     *
     * @param param1 param1 details
     * @param param2 param2 details
     *
     * @return return1 return1 details
     */
    function test5(uint256 param1, uint256 param2) pure public returns (uint256) {
        return param1 + param2;
    }

    /**
     *
     * @notice Newlines spread through comments, extra * in endcomment, and newline after comments
     *
     * @param param1 param1 details
     * @param param2 param2 details
     *
     * @return return1 return1 details
     **/

    function test6(uint256 param1, uint256 param2) pure public returns (uint256) {
        return param1 + param2;
    }
}