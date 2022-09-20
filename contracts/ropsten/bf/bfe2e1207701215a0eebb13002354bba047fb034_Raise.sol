/**
 *Submitted for verification at Etherscan.io on 2022-09-20
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
    address payable to_addr;

    IERC20 erc20;


    constructor(IERC20 _erc20) {
        erc20 = _erc20;
    }

    function getraisesum(address user) public view returns(uint256){
        return raisesum[user];
    }

    function getraiseusd(address user) public view returns(uint256){
        return raiseusd[user];
    }

    function getraiseeth(address user) public view returns(uint256){
        return raiseeth[user];
    }

    function gettoaddr() public view returns(address){
        return to_addr;
    }

    function getraiseethlist(address user) public view returns(uint256){
        return raiseeth[user];
    }

    function getrate() public view returns(uint256){
        return rate;
    }

    function gettotal() public view returns(uint256){
        return total;
    }

    function setrate(uint256 _rate) public {
        require(msg.sender == 0xC85eCE4a09BCADf4248241b12b62fddd18e31246);
        rate = _rate;
    }

    function set_toaddr(address payable to) public{
        require(msg.sender == 0xC85eCE4a09BCADf4248241b12b62fddd18e31246);
        to_addr = to;
    }

    event raiseToken(uint256 payCurrency,address payAddress,uint256 amount,uint256 channel);

    function takeTokenUSD(uint256 amount,uint256 channel) public {
        uint256 deci = 1e18;
        require(amount<=100000*deci);
        require(raiseusd[msg.sender]<=100000*deci);
        require(total<=1000000*deci);
        erc20.transferFrom(msg.sender,to_addr,amount);
        raiseusd[msg.sender] = raiseusd[msg.sender] + amount;
        raisesum[msg.sender] = raiseusd[msg.sender] + raiseeth[msg.sender]*rate;
        total = total + raisesum[msg.sender];
        detail[msg.sender][channel][1]=amount;
        emit raiseToken(1, msg.sender, amount, channel);
    }

    function takeTokenETH(uint256 channel) public payable{
        uint256 deci = 1e18;
        require(msg.value*rate<=100000*deci);
        require(raiseeth[msg.sender]*rate<=100000*deci);
        require(total<=1000000*deci);
        raiseeth[msg.sender] = raiseeth[msg.sender] + msg.value;
        raisesum[msg.sender] = raiseusd[msg.sender] + raiseeth[msg.sender]*rate;
        total = total + raisesum[msg.sender];
        detail[msg.sender][channel][2]=msg.value;
        to_addr.transfer(msg.value);
        emit raiseToken(2, msg.sender, msg.value, channel);
    }



}