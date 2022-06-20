// File src/strategies/liquity/lqty-bailout.sol

pragma solidity ^0.6.7;

contract WithdrawEth {

    function withdrawAll() external {
        address payable governance = 0xE37D0de73125af8ce56EF56dc948845779356208;

        uint256 _eth = address(this).balance;
        governance.transfer(_eth);
    }
}