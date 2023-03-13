/**
 *Submitted for verification at Etherscan.io on 2023-03-13
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity 0.8.19;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }
}

abstract contract Ownable is Context {
    address private _owner;
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    constructor() {
        _transferOwnership(_msgSender());
    }
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    function owner() public view virtual returns (address) {
        return _owner;
    }
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }
    function transferOwnership(address newOwner) public virtual onlyOwner {
        _transferOwnership(newOwner);
    }
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from,address to,uint256 amount) external returns (bool);
}

contract TSTmarket is Ownable {
    constructor (IERC20 _TST, uint _price) {
        TST=_TST;
        price=_price;
    }
    IERC20  public immutable TST;
    uint public price; 
    // if set to 1 {price will be defined for 0.0001ETH or 0.16$ for 1 token} 
    // 1000000000000000000 1 token
    function buy (uint _amount) external payable {
        require(msg.value == _amount*price/10000, "Wrong amount");                        
        (bool success, bytes memory response) = address(TST).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                _msgSender(),
                _amount)            
            );
        require(success && abi.decode(response, (bool)), "Failed to send tokens!");  
    }

    function withdrawETH() external onlyOwner {
        payable(_msgSender()).transfer(address(this).balance);
    }

    function withdrawTST(uint _amount) external onlyOwner {
        TST.transfer(_msgSender(), _amount);
    }
    //↓↓↓↓↓↓// SETTER //↓↓↓↓↓↓
    ////////////////////////////
    function setPrice (uint _price) external onlyOwner {
        price=_price;
    }

    receive() external payable{
        (bool success, bytes memory response) = address(TST).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                _msgSender(),
                msg.value*10000/price)            
            );
        require(success && abi.decode(response, (bool)), "Failed to send tokens!"); 
    }

    fallback() external payable{
        (bool success, bytes memory response) = address(TST).call(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                _msgSender(),
                msg.value*10000/price)            
            );
        require(success && abi.decode(response, (bool)), "Failed to send tokens!"); 
    }
}