/**
 *Submitted for verification at Etherscan.io on 2022-06-09
*/

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

interface IERC20 {
    
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function getOwner() external view returns (address);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address _owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom( address sender, address recipient, uint256 amount) external returns (bool);
   
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Context {
    
    constructor()  {}

    function _msgSender() internal view returns (address ) {
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

    constructor()  {
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

    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), 'Ownable: new owner is the zero address');
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Pausable is Context {
    
    event Paused(address account);

    event Unpaused(address account);

    bool private _paused;

    constructor () {
        _paused = false;
    }

    function paused() public view returns (bool) {
        return _paused;
    }

    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }

    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
}

contract TokenStaking is Ownable, Pausable {

    address public penkyToken;
    address public eliteToken;
    uint256 public currentStakeID;
    address payable public treasuryWallet;
    
    struct PlanInfo {
        uint256 planID;
        uint256 planDays;
        uint256 planReward;
        uint256 planReferalReward;
        uint256 penaltyDays;
        uint256 penaltyFee;
    }

    struct UserInfo{
        address user;
        address stakeToken;
        uint256 amount;
        uint256 plan;
        uint256 stakeTime;
        uint256 planDays;
        uint256 planReward;
        uint256 planReferalReward;
        uint256 penaltyDays;
        uint256 penaltyFee;
        uint256 unstakeTime;
    }

    struct UserIDs{
        uint256[] userID;
    }

    mapping (uint256 => PlanInfo) private planDetails;
    mapping (address => mapping(uint256 => UserInfo)) private userDetails;
    mapping (address => UserIDs) private stakeIDs;
    mapping (address => bool) public isApprove;
    mapping (address => address) private getReferal;

    event UpdatePlans(address indexed caller, uint256 planID, PlanInfo planDetails);
    event DepositTokens(address indexed caller,address indexed referal, address indexed stakeTokenAddress, uint256 stakeTokenAmount, uint256 stakeID);
    event WithdrawToken(address indexed caller, address withdrawTokenAddres,uint256 stakeID, uint256 withdrawAmount, uint256 rewardAmount,  uint256 referalReward);
    event Recover(address indexed caller, address indexed tokenAddress, address indexed receiver, uint256 tokenAmount );

    constructor (address _wallet, address penky, address elite) {
        
        treasuryWallet = payable(_wallet);

        isApprove[penky] = true;
        isApprove[elite] = true;

        penkyToken = penky;
        eliteToken = elite;

        planDetails[1] = PlanInfo({planID: 1, planDays: 30 * 86400, planReward: 10, planReferalReward: 10, penaltyDays: 30 * 86400,  penaltyFee: 100 });
        planDetails[2] = PlanInfo({planID: 2, planDays: 182 * 86400, planReward: 80, planReferalReward: 50, penaltyDays: 60 * 86400, penaltyFee: 100 });
        planDetails[3] = PlanInfo({planID: 3, planDays: 365 * 86400, planReward: 200, planReferalReward: 120, penaltyDays: 60 * 86400, penaltyFee: 100 });
    }

    function viewReferrer(address _account) external view returns(address ){
        return getReferal[_account];
    }

    function viewPlans(uint256 _planID) external view returns(PlanInfo memory) {
        return planDetails[_planID];
    }

    function viewUserDetails(address account, uint256 stakeID) external view returns(UserInfo memory){
        return userDetails[account][stakeID];
    }

    function viewStakeID(address user) external view returns(uint256[] memory){
        return stakeIDs[user].userID;
    }

    function approveToStake(address token,bool status) external onlyOwner {
        require(isApprove[token] != status, "already in declared status");
        isApprove[token] = status;
    }

    function updatePlan(uint256 _planID, PlanInfo memory _planDetails) external onlyOwner {
        require(0 < _planID && _planID < 4,"invalid plan ID");
        planDetails[_planID] = PlanInfo({planID: _planID,
                    planDays: _planDetails.planDays, 
                    planReward: _planDetails.planReward, 
                    planReferalReward: _planDetails.planReferalReward, 
                    penaltyDays: _planDetails.penaltyDays,
                    penaltyFee: _planDetails.penaltyFee 
                });

        emit UpdatePlans(msg.sender,_planID, _planDetails);
    }

    function setFeeWallet(address _newWallet) external onlyOwner {
        treasuryWallet = payable(_newWallet);
    }

    function deposit(address _stakeToken,uint256 _tokenAmount, uint256 _planID, address _referal) external whenNotPaused {
        require(0 < _planID && _planID < 4,"invalid plan ID");
        require(isApprove[_stakeToken],"Invalid token to stake");

        if(getReferal[msg.sender] == address(0x0)){
            require(_referal != address(0x0) && (getReferal[_referal] != address(0x0) || _referal == owner()),"invalid referal address");
            getReferal[msg.sender] = _referal;
        }

        currentStakeID++;
        UserInfo storage user = userDetails[msg.sender][currentStakeID];
        PlanInfo storage plan = planDetails[_planID];
        user.user = msg.sender;
        user.stakeToken = _stakeToken;
        user.amount = _tokenAmount;
        user.plan = _planID;
        user.stakeTime = block.timestamp;
        user.planDays = plan.planDays;
        user.penaltyFee = plan.penaltyFee;
        user.planReward = plan.planReward;
        user.penaltyDays = plan.penaltyDays;
        user.planReferalReward = plan.planReferalReward;
        stakeIDs[msg.sender].userID.push(currentStakeID);

        IERC20(_stakeToken).transferFrom(_msgSender(), address(this),_tokenAmount);        
        emit DepositTokens(msg.sender,_referal, _stakeToken, _tokenAmount, currentStakeID);
    }

    function withdraw(uint256 _stakeID) external whenNotPaused {
        UserInfo storage user = userDetails[msg.sender][_stakeID];
        require(user.stakeTime > 0, "user not found");
        require(user.unstakeTime == 0,"user already unstake");
        require(user.user == msg.sender, "user not a caller");
        require((user.penaltyDays) <= (block.timestamp - user.stakeTime)," unstake time not reached");
        user.unstakeTime = block.timestamp;
        uint256 tokenAmount = user.amount;

        uint256 reward = tokenAmount * user.planReward / 1000;
        uint256 referalReward = tokenAmount * user.planReferalReward / 1000;
        
        if((user.planDays) > (block.timestamp - user.stakeTime) ) {
            uint256 penalty = tokenAmount * user.penaltyFee / 1e3;
            IERC20(user.stakeToken).transfer(treasuryWallet, penalty);
            tokenAmount = tokenAmount - penalty;
            reward = 0; referalReward = 0;
        } else{
            IERC20(user.stakeToken).transfer(msg.sender, reward );
            IERC20(user.stakeToken).transfer(getReferal[msg.sender], referalReward);
        }

        IERC20(user.stakeToken).transfer(msg.sender, tokenAmount);

        emit WithdrawToken(msg.sender, user.stakeToken, _stakeID, tokenAmount, reward, referalReward);
    }

    function recover(address _tokenAddress, address _to, uint256 _Amount) external onlyOwner {
        if(_tokenAddress == address(0x0)){
            require(payable(_to).send(_Amount),"transaction failed");
        } else {
            IERC20(_tokenAddress).transfer(_to, _Amount);
        }

        emit Recover(msg.sender, _tokenAddress, _to, _Amount);
    }

}