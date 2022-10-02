// SPDX-License-Identifier: MIT
pragma solidity ^0.8.16;

//  _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _                         
// |   ____  _          ____                 |
// |  / ___|(_) _   _  |  _ \   ___ __   __  |
// | | |  _ | || | | | | | | | / _ \\ \ / /  |
// | | |_| || || |_| | | |_| ||  __/ \ V /   |
// |  \____||_| \__,_| |____/  \___|  \_/    |
// | _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ | 

//Giuliano Neroni DEV
//https://www.giulianoneroni.com/

import "./IUniswap.sol";
import "./abstract.sol";
import "./interface.sol";

contract Swappy is Ownable, ReentrancyGuard {

    address public swappyWallet;
    using SafeERC20 for IERC20;

    IERC20 public chainStable;
    
    constructor () {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}
    receive() external payable {}

    function getAddress() public view returns (address) {
        return(address(this));}

    function setChainStable(address _chainStable) public onlyOwner() {
        chainStable = IERC20(_chainStable);}

    function setSwappyWallet(address _swappyWallet) public onlyOwner() {
        swappyWallet = _swappyWallet;}

    function tokenBalanceAllowance(address _tokenToSwap) public view returns (uint256, uint256) {
        IERC20 tokenToSwap = IERC20(_tokenToSwap);
        uint256 balance = tokenToSwap.balanceOf(msg.sender);
        uint256 allowance = tokenToSwap.allowance(msg.sender, address(this));
        return (balance, allowance);}

    function swappyStable(uint256 amount, address tokenTo, uint256 blockchainTo) public returns (address, uint256) {
        uint256 balance = chainStable.balanceOf(msg.sender);
        require(balance >= amount, "You have no token to swap");
        require(chainStable.allowance(msg.sender, address(this)) >= amount, "Approve Necessary");
        //maxApproveValue = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        chainStable.safeTransferFrom(msg.sender, swappyWallet, amount);
        return(tokenTo, blockchainTo);}

    function swappyAnyOther(address _tokenToSwap, uint256 amount, address tokenTo, uint256 blockchainTo) external returns (address, uint256) {
        IERC20 tokenToSwap = IERC20(_tokenToSwap);
        uint256 balance = tokenToSwap.balanceOf(msg.sender);
        require(balance >= amount, "You have no token to swap");
        require(tokenToSwap.allowance(msg.sender, address(this)) >= amount, "Approve Necessary");
        //maxApproveValue = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        tokenToSwap.safeTransferFrom(msg.sender, swappyWallet, amount);
        return(tokenTo, blockchainTo);}

    function swappyETH(uint256 amount, address tokenTo, uint256 blockchainTo) public payable returns (address, uint256) {
        require(msg.sender.balance >= amount, "You have no token to swap");
        (bool sent,) = swappyWallet.call{value: amount}("");
        require(sent, "Failed to send Ether");
        return(tokenTo, blockchainTo);}

    function transferAnyNewERC20Token(address _tokenAddr, address _to, uint _amount) public onlyOwner {  
        require(NewIERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");}

    function transferAnyOldERC20Token(address _tokenAddr, address _to, uint _amount) public onlyOwner {    
        OldIERC20(_tokenAddr).transfer(_to, _amount);}}