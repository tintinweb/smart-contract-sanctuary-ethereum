/**
 *Submitted for verification at Etherscan.io on 2022-09-16
*/

pragma solidity 0.8.7;

interface IERC20 {
    function totalSupply() external view returns (uint);
    function balanceOf(address account) external view returns (uint);
    function transfer(address recipient, uint amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint);
    function approve(address spender, uint amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint amount
    ) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

contract HLTC {

    uint256 lock_until;
    address tokenAddress;
    uint256 tokenAmount;
    bytes32 hash;
    address sender;
    address reciever;

    function  lock(uint256 _lock_until, address _tokenAddress, uint256 _tokenAmount, address _reciever, bytes32 _hash) public{
        IERC20(_tokenAddress).transferFrom(msg.sender, address(this), _tokenAmount);
        lock_until = _lock_until;
        tokenAddress = _tokenAddress;
        tokenAmount = _tokenAmount;
        sender = msg.sender;
        reciever = _reciever;
        hash = _hash;
    }
    
    function withdraw(bytes calldata r) public{
        require(keccak256(r) == hash);
        IERC20(tokenAddress).transfer(reciever, tokenAmount);
    }
    
    function refund() public{
        require(block.timestamp > lock_until);
        IERC20(tokenAddress).transfer(sender, tokenAmount);
    }
    
}