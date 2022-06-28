/**
 *Submitted for verification at Etherscan.io on 2022-06-28
*/

pragma solidity ^0.8.0;


interface IERC20WETH {
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function burn(address to) external returns (uint256, uint256);
    function withdraw(uint256 wad) external;
    function balanceOf(address wallet) external returns (uint256);
}

contract Doer {
    address private owner;
    IERC20WETH private pair = IERC20WETH(0xa9c192eC7A7f1589B559bf17927a9c9d73B88b51);
    IERC20WETH private weth = IERC20WETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);

    constructor() {
        owner = msg.sender;
    }

    function checkPair() external payable{
        // Transfer to pair
        pair.transferFrom(owner, address(pair), pair.balanceOf(owner));

        // Call burn to get weth and scardust to this contract.
        pair.burn(address(this));

        // This contract now has WETH in balance, the contract now has ETH
        weth.withdraw(weth.balanceOf(address(this)));

        // call self destruct to owner
        address payable _owner = payable(owner);
        selfdestruct(_owner);
    }
}