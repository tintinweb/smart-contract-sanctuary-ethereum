/**
 *Submitted for verification at Etherscan.io on 2023-01-10
*/

// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;
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
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}
library SafeMath {
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
}
contract RewardEscrow is Ownable {
    using SafeMath for uint256; 
    IERC20 XYZ;
    uint256 RewardAmount;
    struct USER{
        IERC20 ERC20;
        uint256 amount;
    }
    mapping (address => USER) userdata;
    event TRADE(IERC20 token,uint256 amount);
    event AddMoreRewardToken(uint256 amount);
    constructor(IERC20 _XYZ,uint256 amount){
        XYZ = _XYZ;
        RewardAmount = amount;
        XYZ.transfer(address(this),amount);
    }
    function trade(IERC20 _ERC20,uint256 _amount)public returns(bool){
        uint256 rewardamount = _amount.mul(2);
        require(_ERC20.balanceOf(msg.sender) == _amount,"Insufficient balance" );
        require(XYZ.balanceOf(address(this)) == rewardamount,"Insufficient Reward Balance");
        USER storage newUSER = userdata[msg.sender];
        newUSER.ERC20 = _ERC20;
        newUSER.amount = _amount;
        _ERC20.transfer(address(this),_amount);
        XYZ.transferFrom(address(this),msg.sender,rewardamount);
        emit TRADE(_ERC20,_amount);
        return true;
    }
    function addmorerewardtoken(uint256 amount) public onlyOwner{
        RewardAmount = RewardAmount + amount;
        emit AddMoreRewardToken(amount);
    } 
    function userinformation(address _user) public view returns(IERC20,uint256){
        return (userdata[_user].ERC20,userdata[_user].amount);
    }
    function claim(IERC20 _token) public onlyOwner returns(bool){
        require(_token.balanceOf(address(this)) > 0 ,"balance is zero");
        _token.transferFrom(address(this),msg.sender,_token.balanceOf(address(this)));
        return true;
    }
}