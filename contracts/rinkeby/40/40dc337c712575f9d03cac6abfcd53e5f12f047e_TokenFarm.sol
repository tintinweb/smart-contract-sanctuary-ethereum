/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

pragma solidity ^0.5.0;

interface USDCToken {
    function transfer(address dst, uint wad) external returns (bool);
    function transferFrom(address src, address dst, uint wad) external returns (bool);
    function balanceOf(address guy) external view returns (uint);
}

contract TokenFarm {
    USDCToken public usdcToken;
    address owner;
    mapping(address => uint) public stakingBalance;

    /*
       Kovan DAI: 0x4F96Fe3b7A6Cf9725f59d353F723c1bDb64CA6Aa
    */
    constructor() public {
        usdcToken = USDCToken(0x4DBCdF9B62e891a7cec5A2568C3F4FAF9E8Abe2b);
        owner = msg.sender;
    }

    function stakeTokens(uint _amount) public {

        // amount should be > 0
        require(_amount > 0, "amount should be > 0");

        // transfer Dai to this contract for staking
        usdcToken.transferFrom(msg.sender, address(this), _amount);
        
        // update staking balance
        stakingBalance[msg.sender] = stakingBalance[msg.sender] + _amount;
    }

    // Unstaking Tokens (Withdraw)
    function unstakeTokens() public {
        uint balance = stakingBalance[msg.sender];

        // balance should be > 0
        require (balance > 0, "staking balance cannot be 0");

        // Transfer Mock Dai tokens to this contract for staking
        usdcToken.transfer(msg.sender, balance);

        // reset staking balance to 0
        stakingBalance[msg.sender] = 0;
    }
}