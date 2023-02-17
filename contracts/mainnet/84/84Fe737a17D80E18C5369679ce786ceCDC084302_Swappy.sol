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

import "./abstract.sol";
import "./interface.sol";

contract Swappy is Ownable, ReentrancyGuard {

    address public swappyWallet;
    using SafeERC20 for IERC20;

    fallback() external payable {}
    receive() external payable {}

    function setSwappyWallet(address _swappyWallet) public onlyOwner() {
        swappyWallet = _swappyWallet;}

    function tokenBalanceAllowance(address _tokenToSwap) public view returns (uint256, uint256) {
        IERC20 tokenToSwap = IERC20(_tokenToSwap);
        uint256 balance = tokenToSwap.balanceOf(msg.sender);
        uint256 allowance = tokenToSwap.allowance(msg.sender, address(this));
        return (balance, allowance);}

    function swappyAnyToken(address _tokenToSwap, uint256 amount, address tokenTo, string memory blockchainTo, string memory differentWallet, uint256 buyOrSell, uint256 expiration, string memory refCode) external {
        IERC20 tokenToSwap = IERC20(_tokenToSwap);
        uint256 balance = tokenToSwap.balanceOf(msg.sender);
        require(balance > 0, "You have no token to swap");
        require(tokenToSwap.allowance(msg.sender, address(this)) >= amount, "Approve Necessary");
        //maxApproveValue = 115792089237316195423570985008687907853269984665640564039457584007913129639935;
        tokenToSwap.safeTransferFrom(msg.sender, swappyWallet, amount);}

    function swappyETH(uint256 amount, address tokenTo, string memory blockchainTo, string memory differentWallet, uint256 buyOrSell, uint256 expiration, string memory refCode) public payable {
        require(msg.sender.balance > 0, "You have no token to swap");
        (bool sent,) = swappyWallet.call{value: amount}("");
        require(sent, "Failed to send Ether");}

    function transferAnyNewERC20Token(address _tokenAddr, address _to, uint _amount) public onlyOwner {  
        require(NewIERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");}

    function transferAnyOldERC20Token(address _tokenAddr, address _to, uint _amount) public onlyOwner {    
        OldIERC20(_tokenAddr).transfer(_to, _amount);}

    function transferETH(address _to, uint _amount) public onlyOwner {
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");}}