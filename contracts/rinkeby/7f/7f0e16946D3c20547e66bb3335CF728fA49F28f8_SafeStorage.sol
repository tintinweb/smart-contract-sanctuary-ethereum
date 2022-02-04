// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "./SafeMath.sol";
import "./IERC20.sol";

contract SafeStorage{

    event Store(uint256 amount);
    event Out(uint256 amount);
    address tokenAddress = 0xc41B5E5f8EBa25c77B38aaf01AcC62eE7d4E5F30;
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    using SafeMath for uint256;
    mapping(address => uint256) public storageBalance;

    // function setStorage() public {
    //     storageBalance[msg.sender] = 0;
    // }
    
    function deposit(uint256 _amount) public returns (uint256){
        
        IERC20(tokenAddress).transfer(address(this),_amount);
        if(storageBalance[msg.sender] == 0){
            storageBalance[msg.sender] = _amount;
        }
        else{
            // storageBalance[msg.sender] = storageBalance[msg.sender].add(_amount);
            storageBalance[msg.sender] += _amount;
        }
        emit Store(_amount);
        return storageBalance[msg.sender];
    }

    function getMyStorageBalance() public view returns (uint256){
        return storageBalance[msg.sender];
    }

    function withDrawal(uint256 _amount) public returns (uint256){
        IERC20(tokenAddress).approve(address(this),IERC20(tokenAddress).balanceOf(msg.sender));
        IERC20(tokenAddress).transferFrom(address(this), msg.sender,_amount);
        // storageBalance[msg.sender] = storageBalance[msg.sender].sub(_amount);
        storageBalance[msg.sender] -= _amount;
        emit Out(_amount);
        return storageBalance[msg.sender];
    }
}

pragma solidity ^0.8.2;

library SafeMath {

  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    // assert(b > 0); // Solidity automatically throws when dividing by 0
    uint256 c = a / b;
    // assert(a == b * c + a % b); // There is no case in which this doesn't hold
    return c;
  }

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

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

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