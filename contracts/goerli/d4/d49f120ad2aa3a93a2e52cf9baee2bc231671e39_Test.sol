/**
 *Submitted for verification at Etherscan.io on 2022-10-10
*/

pragma solidity 0.7.1;

interface ITest {
    /**
     * @notice Ahhhhhh, I'm fooing
     */
    function foo() external view returns (bool);

    /**
     * @param guy - is it guy or guy2?
     */
    function bar(address guy) external view returns (uint256);
}
contract Test is ITest {
    function foo() external view override returns (bool) {
        return true;
    }

    function bar(address guy2) external view override returns (uint256) {
        return 2;
    }
}