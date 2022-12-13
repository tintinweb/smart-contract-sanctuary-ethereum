// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/// @title A contract to test Etherscan's Nat Spec
/// @author Tester
/// @notice This will test Nat Spec on Etherscan
/// @dev You might want to know how this works
contract TestNatSpec {

	uint256 public testResult;

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
        testResult = param1 + param2;
		return testResult;
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
        testResult = param1 + param2;
		return testResult;
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
        testResult = param1 + param2;
		return testResult;
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
        testResult = param1 + param2;
		return testResult;
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
        testResult = param1 + param2;
		return testResult;
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
        testResult = param1 + param2;
		return testResult;
    }
}