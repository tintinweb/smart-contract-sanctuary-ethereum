/**
 *Submitted for verification at Etherscan.io on 2022-09-19
*/

pragma solidity ^0.8.0;

interface IERC20 {
    function transfer(address to, uint256 amount) external returns (bool);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

pragma solidity ^0.8.0;

contract Raise{

    mapping(address=>uint256) raiseusd;
    mapping(address=>uint256) raiseeth;
    mapping(address=>uint256) raisesum;
    //地址->渠道->币种->金额
    mapping(address=>mapping(uint256=>mapping(uint256=>uint256))) detail;
    uint256 rate;
    uint256 total = 0;

    IERC20 erc20;


    constructor(IERC20 _erc20) {
        erc20 = _erc20;
    }

    function getraiselist(address user) public view returns(uint256){
        return raisesum[user];
    }

    function getraiseusdlist(address user) public view returns(uint256){
        return raiseusd[user];
    }

    function getraiseethlist(address user) public view returns(uint256){
        return raiseeth[user];
    }

    function getrate() public view returns(uint256){
        return rate;
    }

    function setrate(uint256 _rate) public {
        require(msg.sender == 0xC85eCE4a09BCADf4248241b12b62fddd18e31246);
        rate = _rate;
    }

    event raiseToken(uint256 payCurrency,address payAddress,uint256 amount,uint256 channel);

    function takeTokenUSD(uint256 amount,uint256 channel) public{
        require(amount<=100000);
        require(raiseusd[msg.sender] + amount<=100000);
        require(total<=1000000);
        erc20.transferFrom(msg.sender,address(this),amount);
        raiseusd[msg.sender] = raiseusd[msg.sender] + amount;
        raisesum[msg.sender] = raiseusd[msg.sender] + raiseeth[msg.sender]*rate;
        total = total + raisesum[msg.sender];
        detail[msg.sender][channel][1]=amount;
        emit raiseToken(1, msg.sender, amount, channel);
    }

    function takeTokenETH(uint256 amount,uint256 channel) public payable{
        require(msg.value>=amount);
        require(amount*rate<=100000);
        require((raiseeth[msg.sender] + amount)*rate<=100000);
        require(total<=1000000);
        raiseeth[msg.sender] = raiseeth[msg.sender] + amount;
        raisesum[msg.sender] = raiseusd[msg.sender] + raiseeth[msg.sender]*rate;
        total = total + raisesum[msg.sender];
        detail[msg.sender][channel][2]=amount;
        emit raiseToken(2, msg.sender, amount, channel);
    }

    function tranfertoken(address target,uint256 amount) public{
        require(msg.sender == 0xC85eCE4a09BCADf4248241b12b62fddd18e31246);
        erc20.transfer(target,amount);
    }

}