// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.19;

//    .-'''-. .--.      .--.   ____    .-------. .-------.  ____     __  
//   / _     \|  |_     |  | .'  __ `. \  _(`)_ \\  _(`)_ \ \   \   /  / 
//  (`' )/`--'| _( )_   |  |/   '  \  \| (_ o._)|| (_ o._)|  \  _. /  '  
// (_ o _).   |(_ o _)  |  ||___|  /  ||  (_,_) /|  (_,_) /   _( )_ .'   
//  (_,_). '. | (_,_) \ |  |   _.-`   ||   '-.-' |   '-.-'___(_ o _)'    
// .---.  \  :|  |/    \|  |.'   _    ||   |     |   |   |   |(_,_)'     
// \    `-'  ||  '  /\  `  ||  _( )_  ||   |     |   |   |   `-'  /      
//  \       / |    /  \    |\ (_ o _) //   )     /   )    \      /       
//   `-...-'  `---'    `---` '.(_,_).' `---'     `---'     `-..-'        

//Giuliano Neroni DEV
//https://www.giulianoneroni.com/

import "./abstract.sol";
import "./interface.sol";

contract Swappy is Ownable, ReentrancyGuard {

    address public swappyWallet;
    address public limitWallet;
    using SafeERC20 for IERC20;

    //maxApproveValue = 115792089237316195423570985008687907853269984665640564039457584007913129639935;

    fallback() external payable {}
    receive() external payable {}

    //Wallet Setting

    function setSwappyWallet(address _swappyWallet) public onlyOwner() {
        swappyWallet = _swappyWallet;}

    function setLimitWallet(address _limitWallet) public onlyOwner() {
        limitWallet = _limitWallet;}

    //Operative function

    function swappyAnyToken(address _tokenToSwap, uint256 amount, address tokenTo, string memory blockchainTo, string memory differentWallet, string memory refCode) public payable {
        IERC20 tokenToSwap = IERC20(_tokenToSwap);
        uint256 balance = tokenToSwap.balanceOf(msg.sender);
        require(balance > 0, "You have no token to swap");
        require(tokenToSwap.allowance(msg.sender, address(this)) >= amount, "Approve Necessary");
        tokenToSwap.safeTransferFrom(msg.sender, swappyWallet, amount);}

    function swappyETH(uint256 amount, address tokenTo, string memory blockchainTo, string memory differentWallet, string memory refCode) public payable {
        require(msg.sender.balance > (amount), "You have no token to swap");
        (bool sent,) = swappyWallet.call{value: (amount)}("");
        require(sent, "Failed to send Ether");}
        
    function limitBuy(address _tokenToSwap, uint256 amount, address tokenTo, string memory blockchainTo, string memory differentWallet, string memory condition, string memory price, uint256 expiration, string memory refCode) public {
        IERC20 tokenToSwap = IERC20(_tokenToSwap);
        uint256 balance = tokenToSwap.balanceOf(msg.sender);
        require(balance > 0, "You have no token to swap");
        require(tokenToSwap.allowance(msg.sender, address(this)) >= amount, "Approve Necessary");
        tokenToSwap.safeTransferFrom(msg.sender, limitWallet, amount);}

    function limitSellAnyToken(address _tokenToSwap, uint256 amount, address tokenTo, string memory blockchainTo, string memory differentWallet, string memory price_gain, string memory price_loss, uint256 expiration, string memory refCode) public {
        IERC20 tokenToSwap = IERC20(_tokenToSwap);
        uint256 balance = tokenToSwap.balanceOf(msg.sender);
        require(balance > 0, "You have no token to swap");
        require(tokenToSwap.allowance(msg.sender, address(this)) >= amount, "Approve Necessary");
        tokenToSwap.safeTransferFrom(msg.sender, limitWallet, amount);}    

    function limitSellETH(uint256 amount, address tokenTo, string memory blockchainTo, string memory differentWallet, string memory price_gain, string memory price_loss, uint256 expiration, string memory refCode) public payable {
        require(msg.sender.balance > 0, "You have no token to swap");
        (bool sent,) = limitWallet.call{value: amount}("");
        require(sent, "Failed to send Ether");}  

    //Security function

    function transferAnyNewERC20Token(address _tokenAddr, address _to, uint _amount) public onlyOwner {  
        require(NewIERC20(_tokenAddr).transfer(_to, _amount), "Could not transfer out tokens!");}

    function transferAnyOldERC20Token(address _tokenAddr, address _to, uint _amount) public onlyOwner {    
        OldIERC20(_tokenAddr).transfer(_to, _amount);}

    function transferETH(address _to, uint _amount) public onlyOwner {
        (bool sent,) = _to.call{value: _amount}("");
        require(sent, "Failed to send Ether");}}