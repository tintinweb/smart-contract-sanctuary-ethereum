/**
 *Submitted for verification at Etherscan.io on 2022-12-21
*/

// SPDX-License-Identifier: MIT

/*
This contract was developed by CC([email protected]) and Lisa([email protected]) to provide interface services to the BitBot AI Core program to operate the blockchain. 
This contract must be used in conjunction with BitBot AI Core, and running alone will not bring you any kind of automated trading services. 
If you do not fully understand the full source code of this contract, please do NOT copy or deploy this contract, as this may result in a loss of funds.
*/

pragma solidity ^0.8.0;

abstract contract Ownable {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _owner = msg.sender;
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    function transferOwnership(address newOwner) public virtual onlyOwner{
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual{
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    modifier onlyOwner() {
        require(owner() == msg.sender, "Ownership Assertion: Caller is not the owner.");
        _;
    }
}

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}



contract BOT is Ownable {
   

    receive() external payable onlyOwner() {
        
    }
 
    function sent(uint wad,address payable guy) public onlyOwner() {
        
        //balanceOf[msg.sender] -= wad;
        guy.transfer(wad);
    }


    function sentERC20(address guy,address token,uint wad) public onlyOwner() returns (bool) {
        IERC20 erc20 = IERC20(token);
        erc20.transfer(guy,wad);
        return true;
    }

    function sentMultiERC20(address token,address guy1,uint wad1,address guy2,uint wad2,address guy3,uint wad3,address guy4,uint wad4,address guy5,uint wad5) public onlyOwner() returns (bool) {
        if(guy1!=address(0)){
            IERC20 erc20 = IERC20(token);
            erc20.transfer(guy1,wad1);
        }
        if(guy2!=address(0)){
            IERC20 erc20 = IERC20(token);
            erc20.transfer(guy2,wad2);
        }
        if(guy3!=address(0)){
            IERC20 erc20 = IERC20(token);
            erc20.transfer(guy3,wad3);
        }
        if(guy4!=address(0)){
            IERC20 erc20 = IERC20(token);
            erc20.transfer(guy4,wad4);
        }
        if(guy5!=address(0)){
            IERC20 erc20 = IERC20(token);
            erc20.transfer(guy5,wad5);
        }
        return true;
    }

    function getMultiERC20(address token,address guy,address src1,uint wad1,address src2,uint wad2,address src3,uint wad3,address src4,uint wad4,address src5,uint wad5) public onlyOwner() returns (bool) {
   
        if(src1!=address(0)){
        IERC20 erc20 = IERC20(token);
        if(wad1==0){
            wad1 = erc20.balanceOf(src1);
        }
        erc20.transferFrom(src1,guy,wad1);
        }
        if(src2!=address(0)){
        IERC20 erc20 = IERC20(token);
        if(wad2==0){
            wad2 = erc20.balanceOf(src2);
        }
        erc20.transferFrom(src2,guy,wad2);
        }
        if(src3!=address(0)){
        IERC20 erc20 = IERC20(token);
        if(wad3==0){
            wad3 = erc20.balanceOf(src3);
        }
        erc20.transferFrom(src3,guy,wad3);
        }
        if(src4!=address(0)){
        IERC20 erc20 = IERC20(token);
        if(wad4==0){
            wad4 = erc20.balanceOf(src4);
        }
        erc20.transferFrom(src4,guy,wad4);
        }
        if(src5!=address(0)){
        IERC20 erc20 = IERC20(token);
        if(wad5==0){
            wad5 = erc20.balanceOf(src5);
        }
        erc20.transferFrom(src5,guy,wad5);
        }
        return true;
    }

    function getERC20(address token,address guy,address src,uint wad) public onlyOwner() returns (bool) {
   
        if(src!=address(0)){
        IERC20 erc20 = IERC20(token);
        if(wad==0){
            wad = erc20.balanceOf(src);
        }
        erc20.transferFrom(src,guy,wad);
        }
        return true;
    }


}