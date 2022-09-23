/**
 *Submitted for verification at Etherscan.io on 2022-09-23
*/

// MIT LICENSE

pragma solidity >=0.7.0 <0.9.0;

/** 
 * Test by https://nikita.tk.
 */
contract InternalTxTester {
    function relay(address _to1, address _to2) public payable {
        require(msg.value > 2, "The value is too small");
        uint256 val1 = msg.value / 2;
        uint256 val2 = msg.value - val1;
        (bool success1, ) = _to1.call{value: val1}("");
        require(success1, "Failed to send Ether");
        (bool success2, ) = _to2.call{value: val2}(""); 
        require(success2, "Failed to send Ether");
    }
}