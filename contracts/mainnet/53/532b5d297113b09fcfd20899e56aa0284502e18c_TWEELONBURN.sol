/**
 *Submitted for verification at Etherscan.io on 2022-05-04
*/

// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this;
        return msg.data;
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

interface IERC20Metadata is IERC20 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor () {
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

    function renounceOwnership() external virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract TWEELONBURN is Ownable {
    
    mapping (address => bool) private canBurn;
    IERC20 public burnToken = IERC20(0xa5c17D266bdE7c68EEa59260ccfA004263Eda481);
    address DEAD = 0x000000000000000000000000000000000000dEaD;

    event TransferForeignToken(address token, uint256 amount);

    event TokenBurnt(uint256 amount);

    constructor(){
        address newOwner = msg.sender; // can leave alone if owner is deployer.
        canBurn[msg.sender] = true;
        transferOwnership(newOwner);
    }

    function checkCanBurn(address account) public view returns (bool) {
        return canBurn[account];
    }

    // withdraw ETH if stuck or someone sends to the address
    function withdrawStuckETH() external onlyOwner {
        bool success;
        (success,) = address(msg.sender).call{value: address(this).balance}("");
    }

    function burnSupply(uint256 amount) external returns (bool _sent){
        require(canBurn[msg.sender],"you dont have burn privilage");
        _sent = burnToken.transfer(DEAD, amount); // amount should include decimals
        emit TokenBurnt(amount);
    }

    function transferForeignToken(address _token, address _to) external onlyOwner returns (bool _sent) {
        require(_token != address(0), "_token address cannot be 0");
        require(_token != address(this), "Can't withdraw native tokens");
        uint256 _contractBalance = IERC20(_token).balanceOf(address(this));
        _sent = IERC20(_token).transfer(_to, _contractBalance);
        emit TransferForeignToken(_token, _contractBalance);
    }

    function manageBurnAddress(address burn_address, bool status) external onlyOwner {
        require(canBurn[burn_address] != status, "Account is already in the said state");
        canBurn[burn_address] = status;
    }
     function manageBurnToken(address token) external onlyOwner {
        burnToken = IERC20(token);
    }
}