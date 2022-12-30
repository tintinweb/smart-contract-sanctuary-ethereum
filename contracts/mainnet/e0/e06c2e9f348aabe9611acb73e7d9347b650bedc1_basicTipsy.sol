/**
 *Submitted for verification at Etherscan.io on 2022-12-30
*/

/**
 *Submitted for verification at BscScan.com on 2022-03-06
*/

pragma solidity ^0.8.0;

contract basicTipsy {

    function name() public view returns (string memory) {
        return "TipsyCoin";
    }

    function symbol() public view returns (string memory) {
        return "$tipsy";
    }

    function decimals() public view returns (uint8) {
        return 18;
    }

    function totalSupply() public pure returns (uint256) {
        return 0;
    }

    function balanceOf(address account) public view returns (uint256) {
        return 0;
    }

    function transfer(address to, uint256 amount) public returns (bool) {
   
    revert("TipsyETH not ready yet");

    }

    function allowance(address owner, address spender) public returns (uint256) {
        revert("TipsyETH not ready yet");
    }

    function approve(address spender, uint256 amount) public returns (bool) {
    revert("TipsyETH not ready yet");
    }

        function transferFrom(
        address from,
        address to,
        uint256 amount
    ) public returns (bool) {
    revert("TipsyETH not ready yet");
    }

    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    revert("TipsyETH not ready yet");
    }

    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    revert("TipsyETH not ready yet");
    }
}