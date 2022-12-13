// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

contract TestNatSpec {

	uint256 public test;

    constructor() {}

    /**
     * @notice This is standard comment style and spacing, should work
     * @param param1 param1 details
     * @param param2 param2 details
     * @return return1 return1 details
     */
    function test1(uint256 param1, uint256 param2)
        public
        returns (uint256)
    {
        test = param1 + param2;
		return test;
    }

    /**
     * @notice Extra * in endcomment
     * @param param1 param1 details
     * @param param2 param2 details
     * @return return1 return1 details
     **/
    function test2(uint256 param1, uint256 param2)
        public
        returns (uint256)
    {
        test = param1 + param2;
		return test;
    }

    /**
     * @notice Newline after comments
     * @param param1 param1 details
     * @param param2 param2 details
     * @return return1 return1 details
     */

    function test3(uint256 param1, uint256 param2)
        public
        returns (uint256)
    {
        test = param1 + param2;
		return test;
    }

    /**
     * @notice Newline after comments and extra * in endcomment
     * @param param1 param1 details
     * @param param2 param2 details
     * @return return1 return1 details
     **/

    function test4(uint256 param1, uint256 param2)
        public
        returns (uint256)
    {
        test = param1 + param2;
		return test;
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
    function test5(uint256 param1, uint256 param2)
        public
        returns (uint256)
    {
        test = param1 + param2;
		return test;
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

    function test6(uint256 param1, uint256 param2)
        public
        returns (uint256)
    {
        test = param1 + param2;
		return test;
    }
}