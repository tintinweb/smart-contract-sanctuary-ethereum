/*
Welcome to Moonrock, a cryptocurrency that merges the world of digital finance with the passion of potheads for moonrock. Moonrock is an innovative digital asset created to cater to the cannabis community, specifically those who appreciate the unique qualities and allure of moonrock, a potent and highly concentrated form of marijuana.

Whether you're a cannabis connoisseur or simply intrigued by the intersection of cryptocurrency and cannabis culture, Moonrock offers an exciting avenue to dive into this niche and embrace a digital currency inspired by the love for moonrock.

Light up your joint and don’t miss this party 🎉

https://t.me/MoonRockETH
https://moonrockerc.com
https://twitter.com/MoonrockERC
*/

pragma solidity 0.8.17;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function moon(address recipient, uint256 amount) external returns (bool);
    function soon(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function moonrock(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Moonrock is IERC20{
    

    function name() public pure returns (string memory) {
        return "Moonrock";
    }

    function symbol() public pure returns (string memory) {
        return "Moonrock";
    }

    function decimals() public pure returns (uint8) {
        return 0;
    }

    function totalSupply() public pure override returns (uint256) {
        return 1000000000;
    }

    
    function balanceOf(address account) public view override returns (uint256) {
        return 0;
    }

    
    function moon(address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function soon(address owner, address spender) public view override returns (uint256) {
        return 0;
    }

    
    function approve(address spender, uint256 amount) public override returns (bool) {
        
        return true;
    }

    
    function moonrock(address sender, address recipient, uint256 amount) public override returns (bool) {
        
        return true;
    }

    receive() external payable {}
    
}