/**
 *Submitted for verification at Etherscan.io on 2022-09-22
*/

//SPDX-License-Identifier: MIT
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
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }

    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract Staking{
    IERC20 public governanceToken;
    IERC20 public milEth;
    address public feeReceiver = address(0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2);

    struct User{
         uint256 rewardTokens;
         uint256 stakedTokens;
         uint256 withdrawnTokens;
    }
    struct Transaction{
        uint256 depositTime;
        uint256 depositTokens;
    }
    uint256 public totalStaked;
    mapping(address=>uint256) public prevReward;
    mapping(address=>Transaction[]) public transactions;
    mapping(address=>User) public users;
    
    constructor( IERC20 _milEth,IERC20 _governanceToken) {
        governanceToken = _governanceToken;
        milEth = _milEth;
    }
    
    function rewardCalculation(address _user)public view returns(uint256){
        uint256 totalReward;
        for(uint256 i;i<transactions[_user].length;i++){
          uint256 point=(block.timestamp - transactions[_user][i].depositTime)/(30 seconds)*10**18;
          totalReward= ((7*point)/10000)*transactions[_user][i].depositTokens;
        }
        return totalReward/10**18;
    }

    function stake(uint256 _numberOfTokens) public {
        require(milEth.balanceOf(msg.sender) >= _numberOfTokens,"You don't have enough tokens to stake");
        require(governanceToken.balanceOf(address(this)) >= _numberOfTokens, "System is out of goverenance tokens!");
        uint256 taxedAmount = (_numberOfTokens*5)/1000;
        users[msg.sender].rewardTokens += rewardCalculation(msg.sender);
        uint256 amountToDeposit = _numberOfTokens-taxedAmount;
        milEth.transferFrom(msg.sender, address(this), _numberOfTokens);
        milEth.transfer(feeReceiver, taxedAmount);
        governanceToken.transfer(msg.sender, _numberOfTokens);
        transactions[msg.sender].push(Transaction(block.timestamp,amountToDeposit));
        users[msg.sender].stakedTokens += _numberOfTokens;
        totalStaked+=_numberOfTokens;
    }
    
    function withdraw()public{
        require(users[msg.sender].withdrawnTokens <= users[msg.sender].stakedTokens,"You don't have any reward!");
        uint256 rewardOfUser=rewardCalculation(msg.sender);
        users[msg.sender].rewardTokens += rewardOfUser+prevReward[msg.sender];
        milEth.transfer(msg.sender, users[msg.sender].rewardTokens);
        users[msg.sender].withdrawnTokens += users[msg.sender].rewardTokens;
        prevReward[msg.sender]=0;
        users[msg.sender].rewardTokens = 0;
        for(uint256 i=0;i<transactions[msg.sender].length;i++){
            transactions[msg.sender][i].depositTime=block.timestamp;
        }
    }
    
    function totalDeposited(address _investor)public view returns(uint256){
        uint256 totalAmount;
        for(uint256 i=0;i<transactions[_investor].length;i++){
            totalAmount+=transactions[_investor][i].depositTokens;
        }
        return totalAmount;
    }
    function unstake()public{
        require(totalDeposited(msg.sender)>0,"You don't have tokens to unstake!");
        require(governanceToken.transferFrom(msg.sender, address(this), users[msg.sender].stakedTokens), "You need to refund governance tokens!");
        uint256 taxedAmount = (totalDeposited(msg.sender)*15)/1000;
        milEth.transfer(feeReceiver,taxedAmount);
        milEth.transfer(msg.sender,totalDeposited(msg.sender)-taxedAmount);
        prevReward[msg.sender]+=rewardCalculation(msg.sender);
        delete transactions[msg.sender];
    }

}