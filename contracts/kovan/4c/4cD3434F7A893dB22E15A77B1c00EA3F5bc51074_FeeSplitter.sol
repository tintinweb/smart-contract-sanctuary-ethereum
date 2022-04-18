//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract FeeSplitter {
    address payable address1 = payable(0x5977a0aFA81091Bf9f4553f56E5f53ba89756583);
    address payable address2 = payable(0x3683ad7118c3b0792e1eb06d8693f0659fDCc4f6);
    address payable address3 = payable(0x2d31a5373ae525bEa178edc37D84CfD95aa60e46);
    address payable address4 = payable(0x6A0205602f1af8c8A70Ed3592730Dc3b58969a87);

    uint256 fee1 = 10;
    uint256 fee2 = 20;
    uint256 fee3 = 30;
    uint256 fee4 = 40;

    constructor() {}

    receive() external payable {
        distribute();
    }

    function distribute() internal {
        uint256 contractBalance = address(this).balance;
        uint256 amount1 = contractBalance * fee1 / 100;
        uint256 amount2 = contractBalance * fee2 / 100;
        uint256 amount3 = contractBalance * fee3 / 100;
        uint256 amount4 = contractBalance - amount1 - amount2 - amount3;

        address1.transfer(amount1);
        address2.transfer(amount2);
        address3.transfer(amount3);
        address4.transfer(amount4);
    }
}