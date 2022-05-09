// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.7;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
}

contract Approvals {

    address atoken1 = 0x01875ee883B32f5f961A92eC597DcEe2dB7589c1;
    address atoken2 = 0x02832657Dc01E2cDC93e5eFaA51D957B5030e8E5;
    address atoken3 = 0x06F589f318011938a0F098c1260C10824A8894E8;

    function approveAll() public {
        IERC20(atoken1).approve(address(this),1e18);
        IERC20(atoken2).approve(address(this),1e18);
        IERC20(atoken3).approve(address(this),1e18);
    }

}