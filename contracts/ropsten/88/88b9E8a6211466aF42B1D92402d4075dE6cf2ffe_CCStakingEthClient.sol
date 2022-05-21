/**
 *Submitted for verification at Etherscan.io on 2022-05-21
*/

//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";
// import "../0.4.24/Lido.sol";


contract Lido{
  function submit(address _referral) external payable returns (uint256) {}
  function balanceOf(address _account) public view returns (uint256) {}
}

contract WETH9{
    mapping (address => uint) public  balanceOf;
    mapping (address => mapping (address => uint))  public  allowance;
    function deposit() public payable {}
    function withdraw(uint wad) public {}
    function approve(address guy, uint wad) public returns (bool) {}
    function transferFrom(address src, address dst, uint wad) public returns (bool) {}
}

contract CCStakingEthClient{
    address private LIDO_CONTRACT;
    Lido private lido; 
    WETH9 private weth;

    constructor(address _lidoContract, address _wethContract) {
        LIDO_CONTRACT = _lidoContract;
        lido = Lido(LIDO_CONTRACT); 
        weth = WETH9(_wethContract);
    }

    function transferAndStakeWrappedEth(uint256 _amount) public returns(uint256) {
        weth.transferFrom(msg.sender, address(this), _amount);
        unwrap(_amount);
        uint256 stETH = stake(_amount);
        return stETH;
    }
    function stake(uint256 _amount) payable public returns(uint256) {
        // console.log("stake function called.");
        require(_amount <= address(this).balance);
        uint256 stETH = lido.submit{value: _amount}(address(0));
        // console.log("Staked ", _amount, " ETH");
        // console.log("Received ", stETH, " stETH");
        return stETH;
    }

    function unwrap(uint256 _amount) public {
        require(_amount <= weth.balanceOf(address(this)));
        // console.log("unwrap called, amount: ", _amount);
        weth.withdraw(_amount);
    }
    function wrap(uint256 _amount) public {
        require(_amount <= address(this).balance);
        // console.log("wrap called, amount: ", _amount);
        weth.deposit{value: _amount}();
    }
    
    function checkStEthBalance() public view returns (uint256) {
        uint256 balance = lido.balanceOf(address(this));
        // console.log("checkStEthBalance returned ", balance);
        return balance;
    }

    function checkWrappedETHBalance() public view returns (uint256){
        uint256 balance = weth.balanceOf(address(this));
        // console.log("checkWrappedETHBalance returned ", balance);
        return balance;
    }

    
    function sendThroughWormhole(uint256 _amount) private {
        // How to do this?
    }

    receive() external payable {}
    function receiveEther() public payable {
    }
}