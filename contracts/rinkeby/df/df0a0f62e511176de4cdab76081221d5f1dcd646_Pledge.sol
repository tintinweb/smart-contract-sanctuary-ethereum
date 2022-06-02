/**
 *Submitted for verification at Etherscan.io on 2022-06-02
*/

pragma solidity 0.8.13;
// SPDX-License-Identifier: MIT

library Address {
    function isContract(address account) internal view returns (bool) {
        bytes32 codehash;
        // 空字符串hash值
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;  
        //内联编译（inline assembly）语言，是用一种非常底层的方式来访问EVM
        assembly { codehash := extcodehash(account) }
        return (codehash != accountHash && codehash != 0x0);
    }
}

library SafeERC20 {
    using Address for address;
 
    function safeTransfer(ERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }
 
    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }
 
    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),"SafeERC20: approve from non-zero to non-zero allowance");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }
 
    function callOptionalReturn(ERC20 token, bytes memory data) private {
        require(address(token).isContract(), "SafeERC20: call to non-contract");
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}
 
interface ERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}
 
contract Pledge {
    using SafeERC20 for ERC20;

    address private owner;
    
    mapping(uint256 => CommitInfo) public commits;

    //代币合约地址
    ERC20 public _PledgeToken = ERC20(0xb1c65ea084FD0Ee04293FFF7b37A2CEc649F9A77);

    //质押总额
    uint256 public _pledgeTotalAmount = 0;

    uint256 public _commitId = 1;

    uint256 public _aridropAmount = 0;

    uint256 public _currentAridropNum = 0;

    //地址 已释放的FCN、FIL总数量、锁仓的FCN
    struct CommitInfo {
        bool isBonus;
        address userAddress;
        uint256 releaseFCN;
        uint256 totalFIL;
        uint256 frozenFCN;
        uint256 pledgeAmount;
        uint256 airdropNum;
    }
 
    constructor () {
        owner = msg.sender;
    }

	//提交信息 已释放的FCN、FIL总数量、锁仓的FCN
    function commit(uint256 _releaseFCN, uint256 _totalFIL, uint256 _frozenFCN) external returns(uint256){
        commits[_commitId] = CommitInfo(
            false,
            msg.sender,
            _releaseFCN,
            _totalFIL,
            _frozenFCN,
            0,
            0
        );
        uint256 id = _commitId;
        _commitId ++;
        return id;
    }

    //管理员录入信息
    function entry(uint256 _id, uint256 _amount) external onlyOwner {
        CommitInfo storage info = commits[_id];
        info.pledgeAmount = _amount;
        info.isBonus = true;
        _pledgeTotalAmount += _amount;
    }

	//提取收益
    function takeProfit(uint256 _id) public {
        require(address(msg.sender) == address(tx.origin), "no contract");
        CommitInfo storage info = commits[_id];
        require(info.userAddress == msg.sender, "error address");
        require(info.isBonus, "no reward");
        require(info.pledgeAmount > 0, "no reward");
        uint256 number = _currentAridropNum - info.airdropNum;
        require(number > 0, "no reward");

        uint256 pledgeBalance = _PledgeToken.balanceOf(address(this));

        // 质押数量 * 分红总量 / 质押总量
        uint256 profits = info.pledgeAmount * _aridropAmount / _pledgeTotalAmount;

        require(pledgeBalance >= profits, "no balance");
        _PledgeToken.safeTransfer(address(msg.sender), profits);

        info.airdropNum ++;
    }
    
	//管理员空投
    function doAirdrop(uint256 _amount) external onlyOwner {
        uint256 pledgeBalance = _PledgeToken.balanceOf(address(this));
        require(_amount <= pledgeBalance, "no balance");
        _aridropAmount = _amount;
        _currentAridropNum ++;
    }

    //查询空投收益
    function getAirdropProfit(uint256 _id) external view returns(uint256) {
        require(address(msg.sender) == address(tx.origin), "no contract");
        CommitInfo storage info = commits[_id];
        uint256 number = _currentAridropNum - info.airdropNum;
        require(number > 0, "no reward");
        uint256 profits = info.pledgeAmount * _aridropAmount / _pledgeTotalAmount;
        return profits;
    }

    function changeOwner(address paramOwner) public onlyOwner {
		owner = paramOwner;
    }

    function withdraw(address _token, address _target, uint256 _amount) external onlyOwner {
        require(ERC20(_token).balanceOf(address(this)) >= _amount, "no balance");
		ERC20(_token).safeTransfer(_target, _amount);
    }

    modifier onlyOwner(){
        require(msg.sender == owner);
        _;
    }
 
    function getOwner() public view returns (address) {
        return owner;
    }

}