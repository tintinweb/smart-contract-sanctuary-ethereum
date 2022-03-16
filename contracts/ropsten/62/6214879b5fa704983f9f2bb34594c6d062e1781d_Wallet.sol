/**
 *Submitted for verification at Etherscan.io on 2022-03-16
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.12;


interface IERC20 {

    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);


    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeMath {
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
      assert(b <= a);
      return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
      uint256 c = a + b;
      assert(c >= a);
      return c;
    }
}

contract Wallet {
    using SafeMath for uint256;

    // <Mapping (Account Address => (Token Address => Balance)
    mapping(address => mapping(address => uint256)) public walletBalance;

    //Locked Token Status
    struct Locked {
        uint256 lockedBalance;
        uint256 lockTime;
        uint256 lockedPeriod;
    }
    // Mapping <Locker Address => <Token Address><Locked Struct>>
    mapping(address => mapping(address => Locked)) public lockedStatus;

    //Fee Balance
    // Mapping <Token Address><Fee Balance>
    mapping(address => uint256) public feeBalance;


    //Wallet Manager
    address public manager;



    constructor() {
        manager = msg.sender;
    }


    // Receive Tokens from an Address into the Smart Contract 
    function receiveToken(address _tokenAddr, uint256 _amount) public returns(bool) {
        require(_amount > 0, "amount must be greater than zero");
        IERC20 token = IERC20(_tokenAddr);
        require(token.balanceOf(msg.sender) >= _amount, "insufficient token balance");
        require(token.allowance(msg.sender, address(this)) >= _amount, "token allowance must be greater");
        token.transferFrom(msg.sender, address(this), _amount);
        walletBalance[msg.sender][_tokenAddr].add(_amount);

        return true;
    }

    //Send tokens from the Smart Contract to Another Addresss
    function sendToken(address _tokenAddr, address _recipient, uint256 _amount) public returns(bool){
        require(_tokenAddr != address(0), "provide a valid token contract address");
        require(_recipient != address(0), "provide a valid receipient address");
        require(_amount > 0, "amount must be greater than zero");
        IERC20 token = IERC20(_tokenAddr);
        require(walletBalance[msg.sender][_tokenAddr] >= _amount, "insufficient holder's token balance");
        require(token.balanceOf(address(this)) >= _amount, "insufficient contract's token balance");
        walletBalance[msg.sender][_tokenAddr].sub(_amount);

        //Take Fee
        feeBalance[_tokenAddr] = _amount / 100;
        
        //Send token to the Recipient Address
        token.transfer(_recipient, _amount.sub(_amount / 100));

        return true;
    }


    function lockToken(address _tokenAddr, uint256 _amount, uint256 _lockPeriod) public returns(uint256) {
        require(_tokenAddr != address(0), "provide a valid token contract address");
        require(_amount > 0, "amount must be greater than zero");
        require(_lockPeriod > 0, "locked period must be greater than zero");

        require(walletBalance[msg.sender][_tokenAddr] >= _amount, "insufficient holder's token balance");
        
        walletBalance[msg.sender][_tokenAddr].sub(_amount);
        lockedStatus[msg.sender][_tokenAddr].lockedBalance.add(_amount);
        lockedStatus[msg.sender][_tokenAddr].lockTime = block.timestamp;
        lockedStatus[msg.sender][_tokenAddr].lockedPeriod.add(_amount);

        return _amount;
    }


    function unlockToken(address _tokenAddr, uint256 _amount) public view returns(uint256) {
        require(_tokenAddr != address(0), "provide a valid token contract address");
        require(_amount > 0 && _amount <= lockedStatus[msg.sender][_tokenAddr].lockedBalance, "amount must be greater than zero");
        require(block.timestamp > lockedStatus[msg.sender][_tokenAddr].lockTime + lockedStatus[msg.sender][_tokenAddr].lockedPeriod, "locked period must be greater than zero");        
        
        lockedStatus[msg.sender][_tokenAddr].lockedBalance.sub(_amount);
        walletBalance[msg.sender][_tokenAddr].add(_amount);

        return _amount;
    }



    function changeManager(address _manager) public {
        require(msg.sender == manager, "only previous manager can change manager");
        manager = _manager;
    }


    function withdrawFees(address _tokenAddr) public {
        require(msg.sender == manager, "only manager can withdraw fees");
        IERC20(_tokenAddr).transfer(msg.sender, feeBalance[_tokenAddr]);
    }

}