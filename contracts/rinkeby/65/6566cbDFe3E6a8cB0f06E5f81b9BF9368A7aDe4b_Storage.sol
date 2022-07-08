// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/**
 * @title Storage
 * @dev Store & retrieve value in a variable
 * @custom:dev-run-script ./scripts/deploy_with_ethers.ts
 */
contract Storage {

    uint256 public number;
    address public sender;
    address public origin;

    event AAA(address sender, uint256 val);

    function val_change() public {
        number = 123;
    }

    function store(uint256 num) public returns (bool, uint256){
        val_change();
        emit AAA (msg.sender, num);

        if (num == 0)
            revert("qqqqqqqqqqqqqqqqq");

        if (num % 2== 1)
            return (true, num);
         
        else
            return (false, num);
    }
}