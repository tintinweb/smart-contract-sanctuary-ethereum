/**
 *Submitted for verification at Etherscan.io on 2023-06-02
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {

    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _transferOwnership(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
   
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract BTCContributions is Ownable {

    IERC20 public BTC;
    address public developer;

    event FundRaised(address from,uint amount);

    constructor(){
	BTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599); 
        developer = msg.sender;
    }

    function contribute(uint _amount) public {
        require(developer != address(0),"Set Developer Address");
        address account = msg.sender;
        BTC.transferFrom(account, developer, _amount);
        emit FundRaised(account,_amount);
    }

    function setDeveloper(address _newDev) public onlyOwner {
        developer = _newDev;
    }

    function setBtc(address _token) public onlyOwner {
        BTC = IERC20(_token);
    }

    function rescueTokens(address _token,uint _amount) public onlyOwner {
        IERC20(_token).transfer(msg.sender,_amount);
    }

    function rescueFunds() public onlyOwner {
        payable(msg.sender).transfer(address(this).balance);
    }


}