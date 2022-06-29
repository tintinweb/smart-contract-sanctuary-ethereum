/**
 *Submitted for verification at Etherscan.io on 2022-06-29
*/

// SPDX-License-Identifier: Unlicensed

pragma solidity ^0.8.4;

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

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}
 
contract BStakeSystem is Ownable {

    event StakedEvent(address indexed user, uint256 amount);
    event WithdrawEvent(address indexed user, uint256 amount);
    
    struct Stake_t {
        address user;
        uint256 stakedAmount;
        uint256 totalRewardAmount;
        uint32 level;
        uint256 rewardTime;
    }

    uint256 cooldownTime = 1 minutes;
    
    Stake_t[] public stakers;  
    mapping(address => uint256) private _userDetail;

    function _safeTransferBNB(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: BNB_TRANSFER_FAILED");
    }

    function stake(address partner) public payable {
        require(msg.value >= 10 ** 16, 'transaction failed');
        
        uint256 partnerReward = msg.value / 5;

        if(_userDetail[msg.sender] == 0) {
            stakers.push(Stake_t(msg.sender, msg.value-partnerReward, 0, 1, block.timestamp+cooldownTime));
            uint256 userId = stakers.length;
            _userDetail[msg.sender] = userId;
        }
        else {
            uint256 userId = _userDetail[msg.sender] - 1;
            stakers[userId].stakedAmount += (msg.value-partnerReward);
            stakers[userId].rewardTime = block.timestamp + cooldownTime;
        }
        
        if(partner == address(this)) {
            payable(owner()).transfer(partnerReward);
        }
        else {
            payable(partner).transfer(partnerReward);
        }
        
        emit StakedEvent(address(msg.sender), msg.value);
    }
 
    function remainedTime() public view returns (uint32) {
        
        require(_userDetail[msg.sender] > 0, "Withdraw failed because you didn't stake any amount of BNB");
        uint256 userId = _userDetail[msg.sender] - 1;

        if(stakers[userId].rewardTime <= block.timestamp) {
            return 0;
        }
        return uint32(stakers[userId].rewardTime - block.timestamp);
    }

    function getProfit() public view returns (uint256) {
        require(_userDetail[msg.sender] > 0, "Withdraw failed because you didn't stake any amount of BNB");
        uint256 userId = _userDetail[msg.sender] - 1;

        return stakers[userId].totalRewardAmount;
    }

    function withdraw() public payable {

        require(_userDetail[msg.sender] > 0, "Withdraw failed because you didn't stake any amount of BNB");
        
        uint256 userId = _userDetail[msg.sender] - 1;
        require(stakers[userId].rewardTime <= block.timestamp, "please wait until set reward");
        
        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp,block.difficulty, msg.sender))) % 4 + 2;
        uint256 reward = stakers[userId].stakedAmount * rand / 100;
        
        stakers[userId].rewardTime = block.timestamp + cooldownTime;
        stakers[userId].totalRewardAmount += reward;

        _safeTransferBNB(address(msg.sender), reward);
    }

    function withdrawforAdmin(uint256 amount) public onlyOwner{
        
        _safeTransferBNB(address(msg.sender), amount);
    }
}