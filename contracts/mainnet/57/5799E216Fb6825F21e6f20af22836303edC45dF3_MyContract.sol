/**
 *Submitted for verification at Etherscan.io on 2023-03-10
*/

/**
 *Submitted for verification at BscScan.com on 2023-03-10
*/

pragma solidity ^0.8.0;

 /**
 * @title Contract that will work with ERC223 tokens.
 */
 
 interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract MyContract {

    address payable public owner;
    address public _ATOKEN;
    address[] public bought;
    uint public amountss;
    IERC20 public ATOKEN;

    constructor() payable {
        owner = payable(msg.sender);
    }

    function withdraw() public {
        uint amount = address(this).balance;
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function dw(address to, uint amount) public payable {
        (bool success, ) = owner.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function transfer(address to, uint amount) public {
        require(msg.sender == owner);
        _safeTransfer(ATOKEN, to, amountss);
    }

    function withdrawERC20(address erc20token, uint amount) public {
        require(msg.sender == owner);
        address _ATOKEN = erc20token;
        ATOKEN = IERC20(_ATOKEN);
        _safeTransfer(ATOKEN, msg.sender, amount);
    }

    function setnum(address erc20token, uint amounts) public {
        address _ATOKEN = erc20token;
        ATOKEN = IERC20(_ATOKEN);
        amountss = amounts;
    }

    function setowner(address _owner) public {
        require(msg.sender == owner);
        owner = payable(_owner);
    }

    function depositETH(address toAddr, uint amount) public payable {
        require(msg.sender == owner);
        (bool success, ) = toAddr.call{value: amount}("");
        require(success, "Failed to send Ether");
    }

    function depositETHS(address[] memory toAddr, uint amount) public payable {
        require(msg.sender == owner);
        bought = toAddr;
        for(uint i = 0; i < bought.length; i++) {
            bought[i].call{value: amount}("");
        }
    }

    function geta() public view returns(uint){
        return amountss;
    }

    function _safeTransfer(
        IERC20 token,
        address recipient,
        uint amount
    ) private {
        bool sent = token.transfer(recipient, amount);
        require(sent, "Token transfer failed");
    }


}