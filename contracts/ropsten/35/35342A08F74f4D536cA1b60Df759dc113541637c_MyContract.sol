/**
 *Submitted for verification at Etherscan.io on 2022-06-11
*/

pragma solidity ^0.5.4;

interface IERC20 {
  function transfer(address recipient, uint256 amount) external;
  function balanceOf(address account) external view returns (uint256);
  function transferFrom(address sender, address recipient, uint256 amount) external ;
  function decimals() external view returns (uint8);
}

contract Context {
    constructor() internal {}

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;
        return msg.data;
    }
}


contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), 'Ownable: caller is not the owner');
        _;
    }

    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract  MyContract is Ownable{
  IERC20 public usdt;
  IERC20 public stcl;
  address public guiji;
  constructor(IERC20 _usdt,IERC20 _stcl,address _guiji) public  {
    usdt = _usdt;
    stcl = _stcl;
    guiji = _guiji;
  }

  event TransferStclOut(address toAddr, uint amount);
  event TransferUsdtIn(address sender, uint amount, string uuid);
  event TransferStclIn(address sender, uint amount, string uuid);

  function updateGuiji(address newGuiji) public onlyOwner {
    guiji = newGuiji;
  }
  
  
  function transferStcltOut(address toAddr, uint256 amount) onlyOwner public  {
    stcl.transfer(toAddr, amount);
    emit TransferStclOut(toAddr, amount);
  }

  function transferUsdtIn(address from,uint amount, string memory uuid) public  {
    
    usdt.transferFrom(from, guiji, amount);
    emit TransferUsdtIn(from, amount, uuid);
  }
  
  function transferStclIn(address from,uint amount,string memory uuid) public  {
    uint s1 = amount / 10;
    uint s2 = amount - s1;
    stcl.transferFrom(from, guiji, s1);
    stcl.transferFrom(from, address(0x0000000000000000000000000000000000000000), s2);
    emit TransferStclIn(from, amount, uuid);
  }
  
}