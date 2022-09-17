/**
 *Submitted for verification at Etherscan.io on 2022-09-17
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
    uint256 rate;
    uint256 total = 0;

    IERC20 erc20;


    constructor(IERC20 _erc20) {
        erc20 = _erc20;
    }

    function getraiselist(address user) public view returns(uint256){
        return raiseusd[user];
    }

    //???
    function setraiselist(address user,uint256 amount) public {
        require(msg.sender == 0xc03815B7f9cbBcAD50Ee7b00250d5eaB45274Eb0);
        raiseusd[user] = amount;
    }

    function setrate(uint256 _rate) public {
        require(msg.sender == 0xc03815B7f9cbBcAD50Ee7b00250d5eaB45274Eb0);
        rate = _rate;
    }

    function takeTokenUSD(uint256 amount) public payable{
        require(amount<=100000);
        require(raiseusd[msg.sender] + amount<=100000);
        require(total<=1000000);
        erc20.transferFrom(msg.sender,address(this),amount);
        raiseusd[msg.sender] = raiseusd[msg.sender] + amount;
        raisesum[msg.sender] = raiseusd[msg.sender] + raiseeth[msg.sender]*rate;
        total = total + raisesum[msg.sender];
    }

    function takeTokenETH(uint256 amount) public payable{
        require(msg.value>=amount);
        require(amount*rate<=100000);
        require((raiseeth[msg.sender] + amount)*rate<=100000);
        require(total<=1000000);
        raiseeth[msg.sender] = raiseeth[msg.sender] + amount;
        raisesum[msg.sender] = raiseusd[msg.sender] + raiseeth[msg.sender]*rate;
        total = total + raisesum[msg.sender];
    }

    function tranfertoken(address target,uint256 amount) public{
        require(msg.sender == 0xc03815B7f9cbBcAD50Ee7b00250d5eaB45274Eb0);
        erc20.transfer(target,amount);
    }

}