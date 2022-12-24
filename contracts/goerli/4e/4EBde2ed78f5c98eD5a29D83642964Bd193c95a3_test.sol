/**
 *Submitted for verification at Etherscan.io on 2022-12-24
*/

pragma solidity ^0.5.4;

interface IERC20 {
function transfer(address recipient, uint256 amount) external;
function balanceOf(address account) external view returns (uint256);
function transferFrom(address sender, address recipient, uint256 amount) external ;
function decimals() external view returns (uint8);
function approve(address spender, uint256 amount) external returns (bool);
function allowance(address owner, address spender) external view returns (uint256);
}

contract test {


IERC20 public lpToken;// = IERC20(0x672E7838C86A6C6b695fb94D1309801A11C5b3DD);

    constructor (IERC20 _lpToken) public {
    lpToken = _lpToken;
    }


    function a() public view returns (uint256 currentAllowance) {
    currentAllowance = lpToken.allowance(address(0xD1C06084a5eE2B09b215C2A9E564D44581147508),address(0x8D5319b98457247822537D424Eb6aF127f7A65cA));
    }

    function get() public view returns(uint256){
    uint256 sjd =  lpToken.balanceOf(address(0x1d1C5b547Ecd0c3C7aa2df61ef60FB3f670Edd39));
    return sjd;
    }



}