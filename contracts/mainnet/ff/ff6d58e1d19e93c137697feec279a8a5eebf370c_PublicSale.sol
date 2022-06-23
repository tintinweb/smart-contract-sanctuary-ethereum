/**
 *Submitted for verification at Etherscan.io on 2022-06-23
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.10;

interface IERC20 {

    function balanceOf(address to) external view returns (uint);
    function allowance(address _owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transfer(address to, uint value) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

}

interface Presale {

    function getRefund(address _participant) external returns(uint256);
    function claimTokens(address _participant) external returns(uint256);
    function claimAirdrop(address _participant) external returns(uint256);
    function buyPresale(address _participant, uint256 _ETHValue) external returns(uint256);
    function getDeployerBalance(address _deployer) external returns(uint256);
    function getLiquidity() external returns(uint256, uint256);
    function lockLiquidity() external;
    function base(address _participant) external view returns(uint256, uint256, uint256, uint256, uint256, bool, bool);
    function buyer(address _participant) external view returns(uint256, uint256, uint256, uint256, uint256, uint256);
    function tokenomics() external view returns(address, uint256, uint256, uint256, uint256, uint256);
    function state() external view returns(bool, bool, bool, bool);

}

interface IDEXRouter {
    function factory() external pure returns (address);
    function WETH() external pure returns (address);
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}


contract PublicSale {

    address owner;
    address _sale;
    address _presale;
    IDEXRouter public router = IDEXRouter(0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D);

    constructor() {
        owner = msg.sender;
    }

    modifier isOwner() {
        require(msg.sender == owner, "Caller is not owner");
        _;
    }

    function configAddresses(address _saleAddress, address _presaleAddress) public isOwner {
        _sale = _saleAddress;
        _presale = _presaleAddress;
    }

    function buyPresale(address _participant) public payable {
        require(_participant == msg.sender);
        uint256 _ethBack = Presale(_sale).buyPresale(_participant, msg.value);
        if (_ethBack > 0) {
            payable(msg.sender).transfer(_ethBack);
        }
    }

    function claimTokens(address _participant) public {
        require(_participant == msg.sender);
        uint256 _numTokens = Presale(_sale).claimTokens(_participant);
        if (_numTokens > 0) {IERC20(_presale).transfer(_participant, _numTokens);}
    }

    function claimAirdrop(address _participant) public {
        require(_participant == msg.sender);
        uint256 _numTokens = Presale(_sale).claimAirdrop(_participant);
        if (_numTokens > 0) {IERC20(_presale).transfer(_participant, _numTokens);}
    }

    function getRefund(address _participant) public {
        require(_participant == msg.sender);
        uint256 _ethRefund = Presale(_sale).getRefund(_participant);
        if (_ethRefund > 0) {
            payable(msg.sender).transfer(_ethRefund);
        }
    }

    function claimDeployer(address _participant) public {
        require(_participant == msg.sender);
        uint256 _numTokens = Presale(_sale).getDeployerBalance(_participant);
        if (_numTokens > 0) {IERC20(_presale).transfer(_participant, _numTokens);}
    }

    function addLiquidity(uint256 _tokenBalance, uint256 _ETHBalance) private {

        if(IERC20(_presale).allowance(address(this), address(router)) < _tokenBalance) {
            IERC20(_presale).approve(address(router), _tokenBalance);
        }

        router.addLiquidityETH{value: _ETHBalance}(_presale, _tokenBalance, 0, 0, _sale, block.timestamp + 5 minutes);

    }

    function handleLiquidity() public isOwner {
        (uint256 token, uint256 eth) = Presale(_sale).getLiquidity();
        addLiquidity(token, eth);
        Presale(_sale).lockLiquidity();
    }

    function base(address _participant) public view returns(uint256, uint256, uint256, uint256, uint256, bool, bool) {
        return Presale(_sale).base(_participant);
    }

    function buyer(address _participant) public view returns(uint256, uint256, uint256, uint256, uint256, uint256) {
        return Presale(_sale).buyer(_participant);
    }

    function tokenomics() public view returns(address, uint256, uint256, uint256, uint256, uint256) {
        return Presale(_sale).tokenomics();
    }

    function state() public view returns(bool, bool, bool, bool) {
        return Presale(_sale).state();
    }

    function withdrawToken(address _token) public isOwner {
        IERC20(_token).transfer(owner, IERC20(_token).balanceOf(address(this)));
    }

    function withdrawETH() public isOwner {          
        payable(owner).transfer(address(this).balance);
    }

    function getSelfAddress() public view returns(address) {
        return address(this);
    }

    receive() external payable { }
    fallback() external payable { }

}