/**
 *Submitted for verification at Etherscan.io on 2022-02-07
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

interface IMasterChef{

    function deposit(uint256 _pid, uint256 _amount) external ;

    function withdraw(uint256 _pid, uint256 _amount) external ;
}

contract StakeElite is Ownable, Pausable {

    IMasterChef public MasterChef;
    IERC20 public EliteNativePair;
    IERC20 public EliteUSDPair;
    IERC20 public RewardToken;
    uint256 public EliteNativeDepositID;
    uint256 public EliteUsdDepositID;
    uint256 public curretnStakeID;
    uint256 public penaltyDays = 60 ;
    address payable public wallet;
    bool public initilizeContract;
    
    struct PlanInfo {
        uint256 planID;
        uint256 planDays;
        uint256 planReward;
        uint256 planReferalReward;
        uint256 planFee;
    }

    struct UserInfo{
        address user;
        uint256 amount;
        uint256 plan;
        address stakeToken;
        uint256 stakeTime;
        uint256 planDays;
        uint256 planReward;
        uint256 planReferalReward;
        uint256 planFee;
        bool unstake;
    }

    struct UserIDs{
        uint256[] userID;
    }

    mapping (uint256 => PlanInfo) private planDetails;
    mapping (address => mapping(uint256 => UserInfo)) private userDetails;
    mapping (address => UserIDs) private stakeIDs;
    mapping (address => address) private getReferal;

    event UpdatePlans(address indexed caller, uint256 planID, PlanInfo planDetails);
    event DepositTokens(address indexed caller,address indexed referal, address indexed StakeToken, uint256 stakeTokenAmount);
    event WithdrawToken(address indexed caller, address lpToken,uint256 stakeID, uint256 withdrawAmount, uint256 rewardAmount,  uint256 referalReward);
    event Recover(address indexed caller, address indexed tokenAddress, address indexed receiver, uint256 tokenAmount );

    /*
        before deploy the contract please check the masterchef addess and set the pair address and pool-ID correctly
    */

    constructor ( address _wallet) {
        MasterChef = IMasterChef(0x41806278bb4cBe2C1dE359537E4CeFbdD5D1aeA9); // For testnet only
        // MasterChef = IMasterChef(0x73feaa1eE314F8c655E354234017bE2193C9E24E); // For BSC mainnet only
        // MasterChef = IMasterChef(0xc2EdaD668740f1aA35E4D8f227fB8E17dcA888Cd); // For ETH mainnet only
        // MasterChef = IMasterChef(0x8CFD1B9B7478E7B0422916B72d1DB6A9D513D734); // For polygon mainnet only
        
        
        wallet = payable(_wallet);

        planDetails[1] = PlanInfo({planID: 1, planDays: 30, planReward: 2, planReferalReward: 1, planFee: 0 });
        planDetails[2] = PlanInfo({planID: 2, planDays: 182, planReward: 4, planReferalReward: 2, planFee: 1 * 1e18 });
        planDetails[3] = PlanInfo({planID: 3, planDays: 365, planReward: 10, planReferalReward: 5, planFee: 2 * 1e18 });
    }

    function initilize(address _EliteNatiavePair, address _EliteUSDPair, address _rewardToken, uint256 _EliteNativeID, uint256 _EliteUsdDepositID) external onlyOwner {
        require(!initilizeContract,"already initilized");
        EliteNativePair = IERC20(_EliteNatiavePair);
        EliteUSDPair = IERC20(_EliteUSDPair);
        RewardToken = IERC20(_rewardToken);
        EliteNativeDepositID = _EliteNativeID;
        EliteUsdDepositID = _EliteUsdDepositID;

        initilizeContract = true;

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

    function updatePlan(uint256 _planID, PlanInfo memory _planDetails) external onlyOwner {
        require(0 < _planID && _planID < 4,"invalid plan ID");
        planDetails[_planID] = PlanInfo({planID: _planID,
                    planDays: _planDetails.planDays, 
                    planReward: _planDetails.planReward, 
                    planReferalReward: _planDetails.planReferalReward, 
                    planFee: _planDetails.planFee 
                });

        emit UpdatePlans(msg.sender,_planID, _planDetails);
    }

    function updatePoolID(uint256 _EliteNativeID, uint256 _EliteUsdID, address _EliteNativePair, address _EliteUsdPair) external onlyOwner {
        EliteNativeDepositID = _EliteNativeID;
        EliteUsdDepositID = _EliteUsdID;
        EliteNativePair = IERC20(_EliteNativePair);
        EliteUSDPair = IERC20(_EliteUsdPair);
    }

    function setpenaltyDays(uint256 _newDays) external onlyOwner {
        penaltyDays = _newDays;
    }

    function setFeeWallet(address _newWallet) external onlyOwner {
        wallet = payable(_newWallet);
    }

    function deposit(address _LPAddress, uint256 _tokenAmount, uint256 _planID, address _referal) external {
        require(initilizeContract,"contract initilized");
        require(0 < _planID && _planID < 4,"invalid plan ID");

        if(getReferal[msg.sender] == address(0x0)){
            require(_referal != address(0x0) && (getReferal[_referal] != address(0x0) || _referal == owner()),"invalid referal address");
            getReferal[msg.sender] = _referal;
        }

        curretnStakeID++;
        UserInfo storage user = userDetails[msg.sender][curretnStakeID];
        PlanInfo storage plan = planDetails[_planID];
        user.user = msg.sender;
        user.amount = _tokenAmount;
        user.plan = _planID;
        user.stakeToken = _LPAddress;
        user.stakeTime = block.timestamp;
        user.planDays = plan.planDays;
        user.planFee = plan.planFee;
        user.planReward = plan.planReward;
        user.planReferalReward = plan.planReferalReward;

        

        stakeIDs[msg.sender].userID.push(curretnStakeID);

        depositToken( _LPAddress, _tokenAmount);
        
        emit DepositTokens(msg.sender,_referal, _LPAddress, _tokenAmount);
    }

    function depositToken(address _LPAddress, uint256 _tokenAmount) internal {
        if(address(EliteNativePair) == _LPAddress){

            EliteNativePair.transferFrom(msg.sender, address(this), _tokenAmount);
            EliteNativePair.approve(address(MasterChef),_tokenAmount);
            MasterChef.deposit(EliteNativeDepositID, _tokenAmount);

        } else if(address(EliteUSDPair) == _LPAddress){

            EliteUSDPair.transferFrom(msg.sender, address(this), _tokenAmount);
            EliteUSDPair.approve(address(MasterChef),_tokenAmount);
            MasterChef.deposit(EliteUsdDepositID, _tokenAmount);

        } else {
            revert("Invalid token to deposit");
        }
    }

    function withdraw(uint256 _stakeID) external payable {
        UserInfo storage user = userDetails[msg.sender][_stakeID];
        require(user.stakeTime > 0, "user not found");
        require(!user.unstake,"user already unstake");
        require(user.user == msg.sender, "user not a caller");
        require((30 * 86400) <= (block.timestamp - user.stakeTime)," unstake time not reached");
        user.unstake = true;

        if(user.plan > 1){
            require((penaltyDays * 86400) <= (block.timestamp - user.stakeTime)," unstake time not reached");
        }

        uint256 reward = user.amount * user.planReward / 100;
        uint256 referalReward = user.amount * user.planReferalReward / 100;

        if(address(EliteNativePair) == user.stakeToken){
            MasterChef.withdraw(EliteNativeDepositID, user.amount);
            EliteNativePair.transfer(msg.sender, user.amount);

        } else if(address(EliteUSDPair) == user.stakeToken){
            MasterChef.withdraw(EliteUsdDepositID, user.amount);
            EliteUSDPair.transfer(msg.sender, user.amount);
            
        }

        if(((user.planDays * 86400) > (block.timestamp - user.stakeTime)) && user.plan > 1 ) {
            require(user.planFee <= msg.value,"invalid plan fee");
            require(wallet.send(msg.value),"transaction failed");
            reward = 0; referalReward = 0;
        } else{
           
            RewardToken.transfer(msg.sender, reward );
            RewardToken.transfer(getReferal[msg.sender], referalReward);
        }

        emit WithdrawToken(msg.sender, user.stakeToken, _stakeID, user.amount, reward, referalReward);
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