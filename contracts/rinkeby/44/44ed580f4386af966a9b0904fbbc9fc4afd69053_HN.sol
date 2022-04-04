/**
 *Submitted for verification at Etherscan.io on 2022-04-04
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

interface GenericNFT {
    function balanceOf(address owner) external view returns(uint256);
}

contract HN is Ownable {
    GenericNFT private genericnft;

    uint256   public trialPrice      = 0.025 ether;
    uint256   public trialTime       = 1;
    bool      public saleEnabled     = false;
    bool      public trialEnabled    = false;
    bool      public transferEnabled = false;

    mapping(address => uint256) public subscriptionEndDate;
    mapping(address => uint256) public referrals;
    mapping(address => bool)    public trialUsed;
    mapping(address => bool)    public blacklisted;
    mapping(uint256 => bool)    public blockedPlans;

    struct Plans {
        uint256 _id;
        uint256 _price;
        uint256 _time;
        uint256 _expires;
        bool    _groupBuy;
        address _groupContract;
        bool    _checkHolder;
        bool    _onlyOnce;
        mapping(address => bool) _checkIfPlanUsed;
    }

    Plans[] public plans;

    event subscriptionChanged(address holder, uint256 planType, uint256 expires);
    event trialChanged(address holder, uint256 expires);
    event batchSubscriptionChange(address[] holders, uint256 expires);
    event subscriptionTransfered(address holder, address target);    

    modifier trialsEnabled() {
        require(trialEnabled, "New trials are currently disabled!");
        _;
    }

    modifier salesEnabled() {
        require(saleEnabled, "New subscriptions are currently disabled!");
        _;
    }

    modifier transfersEnabled() {
        require(transferEnabled, "Transfers are currently disabled!");
        _;
    }

    modifier isNotBlacklisted() {
        require(blacklisted[msg.sender] == false, "Your wallet has been blocked from accesing the application! Contact us.");
        _;
    }

    function addPlan(uint256 _id, uint256 _price, uint256 _time, uint256 _expires, bool _groupBuy, address _groupContract, bool _checkHolder, bool _onlyOnce) external payable onlyOwner {
        Plans storage newPlan = plans.push();
        newPlan._id = _id;
        newPlan._price = _price;
        newPlan._time = _time;
        newPlan._expires = _expires;
        newPlan._groupBuy = _groupBuy;
        newPlan._groupContract = _groupContract;
        newPlan._checkHolder = _checkHolder;
        newPlan._onlyOnce = _onlyOnce;
    }

    function setSaleSettings(bool _saleEnabled, uint256 _trialPrice, uint256 _trialTime, bool _trialEnabled, bool _transferEnabled) external payable onlyOwner {
        saleEnabled     = _saleEnabled;
        trialPrice      = _trialPrice;
        trialTime       = _trialTime;
        trialEnabled    = _trialEnabled;
        transferEnabled = _transferEnabled;
    }
    
    function startTrialSubscription() external payable trialsEnabled() salesEnabled() isNotBlacklisted() {
        require(tx.origin == msg.sender, "Can' start a trial subscription as a contract");
        require(msg.value >= trialPrice, "Not enough ETH to start your trial!");
        require(trialUsed[msg.sender] == false, "You already started a trial membership!");
        require(subscriptionEndDate[msg.sender] == 0, "You already had a subscription!");

        trialUsed[msg.sender] = true;
        subscriptionEndDate[msg.sender] = block.timestamp + (86400 * trialTime);

        emit trialChanged(msg.sender, subscriptionEndDate[msg.sender]);
    }

    function updateSubscription(uint256 _plan, address _ref) external payable salesEnabled() isNotBlacklisted() {
        require(tx.origin == msg.sender, "Can't update a subscription as a contract");
        require(plans[_plan]._expires > 0, "This plan doesn't exist");
        require(blockedPlans[plans[_plan]._id] == false, "This plan is blocked from being purchased");
        require(plans[_plan]._expires >= block.timestamp, "You can't purchase this plan anymore!");
        require(!plans[_plan]._groupBuy, "You can only purchase this plan with groupbuySubscription");

        if (plans[_plan]._onlyOnce) {
            require(!plans[_plan]._checkIfPlanUsed[msg.sender], "You already purchased this plan once!");
        }

        uint256 _price = getPlanPrice(_plan);
        uint256 _time  = getPlanTime(_plan);

        require(msg.value >= _price, "Not enough ETH to update your subscription!");

        if (subscriptionEndDate[msg.sender] == 0) {
            referrals[_ref] += 1;
        }

        if (plans[_plan]._onlyOnce) {
            plans[_plan]._checkIfPlanUsed[msg.sender] = true;
        }

        if (subscriptionEndDate[msg.sender] >= block.timestamp) {
            subscriptionEndDate[msg.sender] = subscriptionEndDate[msg.sender] + (86400 * _time);
        } else {
            subscriptionEndDate[msg.sender] = block.timestamp + (86400 * _time);
        }

        emit subscriptionChanged(msg.sender, _plan, subscriptionEndDate[msg.sender]);

        delete _price;
        delete _time;
    }

    function groupbuySubscription(uint256 _plan) external payable salesEnabled() isNotBlacklisted() {
        require(tx.origin == msg.sender, "Can't purchase a plan as a contract");
        require(plans[_plan]._expires > 0, "This plan doesn't exist");
        require(blockedPlans[plans[_plan]._id] == false, "This plan is blocked from being purchased");
        require(plans[_plan]._expires >= block.timestamp, "You can't purchase this plan anymore!");
        require(plans[_plan]._groupBuy, "You can only purchase this plan with updateSubscription");

        if (plans[_plan]._checkHolder) {
            genericnft = GenericNFT(plans[_plan]._groupContract);
            require(genericnft.balanceOf(msg.sender) >= 1, "You don't hold this nft!");
        }

        if (plans[_plan]._onlyOnce) {
            require(!plans[_plan]._checkIfPlanUsed[msg.sender], "You already purchased this plan once!");
        }

        uint256 _price = getPlanPrice(_plan);
        uint256 _time  = getPlanTime(_plan);

        require(msg.value >= _price, "Not enough ETH to purchase the plan!");

        if (plans[_plan]._onlyOnce) {
            plans[_plan]._checkIfPlanUsed[msg.sender] = true;
        }

        if (subscriptionEndDate[msg.sender] >= block.timestamp) {
            subscriptionEndDate[msg.sender] = subscriptionEndDate[msg.sender] + (86400 * _time);
        } else {
            subscriptionEndDate[msg.sender] = block.timestamp + (86400 * _time);
        }

        emit subscriptionChanged(msg.sender, _plan, subscriptionEndDate[msg.sender]);

        delete _price;
        delete _time;
    }

    function transferSubscription(address _target) external payable transfersEnabled() isNotBlacklisted() {
        require(tx.origin == msg.sender, "Can't transfer a license as a contract");
        require(subscriptionEndDate[msg.sender] >= block.timestamp, "You can't transfer a expired subscription to a new wallet!");
        require(subscriptionEndDate[_target] <= block.timestamp, "The target wallet can't have a active subscription!");

        subscriptionEndDate[_target] = subscriptionEndDate[msg.sender];
        subscriptionEndDate[msg.sender] = 1;

        emit subscriptionTransfered(msg.sender, _target);
    }

    function addTimeToWallets(address[] calldata _holders, uint256 _time) external payable onlyOwner {
        for (uint256 i;i < _holders.length;i++) {
            subscriptionEndDate[_holders[i]] = block.timestamp + (86400 * _time);
        }

        emit batchSubscriptionChange(_holders, block.timestamp + (86400 * _time));
    }

    function setBlacklistWallet(address _holder, bool _state) external payable onlyOwner {
        blacklisted[_holder] = _state;
    }

    function getPlanGroupbuyStatus(uint256 _plan) public view returns(bool) {
        return plans[_plan]._groupBuy;
    }

    function getPlanContract(uint256 _plan) public view returns(address) {
        return plans[_plan]._groupContract;
    }

    function getPlanHolderStatus(uint256 _plan) public view returns(bool) {
        return plans[_plan]._checkHolder;
    }

    function getPlanPrice(uint256 _plan) public view returns(uint256) {
        return plans[_plan]._price;
    }

    function setPlanGroupbuy(uint256 _plan, bool _groupbuy) public payable onlyOwner {
        plans[_plan]._groupBuy = _groupbuy;
    }

    function setPlanExpires(uint256 _plan, uint256 _expires) public payable onlyOwner {
        plans[_plan]._expires = _expires;
    }

    function setPlanTime(uint256 _plan, uint256 _time) public payable onlyOwner {
        plans[_plan]._time = _time;
    }

    function setPlanPrice(uint256 _plan, uint256 _price) public payable onlyOwner {
        plans[_plan]._price = _price;
    }

    function setPlanHolderContract(uint256 _plan, address _contract) public payable onlyOwner {
        plans[_plan]._groupContract = _contract;
    }

    function setPlanHolderStatus(uint256 _plan, bool _state) public payable onlyOwner {
        plans[_plan]._checkHolder = _state;
    }

    function setPlanOnlyOnceStatus(uint256 _plan, bool _state) public payable onlyOwner {
        plans[_plan]._onlyOnce = _state;
    }

    function setPlanUsedStatus(uint256 _plan, address _address, bool _state) public payable onlyOwner {
        plans[_plan]._checkIfPlanUsed[_address] = _state;
    }

    function getPlanTime(uint256 _plan) public view returns(uint256) {
        return plans[_plan]._time;
    }

    function getPlanExpiration(uint256 _plan) public view returns(uint256) {
        return plans[_plan]._expires;
    }

    function isAddressActive(address _holder) public view returns(bool) {
        return subscriptionEndDate[_holder] >= block.timestamp && blacklisted[_holder] == false ? true : false;
    }

    function getSubscriptionEndDate(address _holder) public view returns(uint256) {
        return subscriptionEndDate[_holder];
    }

    function getReferrals(address _ref) public view returns(uint256) {
        return referrals[_ref];
    }

    function blockPlan(uint256 _id, bool _state) public payable onlyOwner {
        blockedPlans[_id] = _state;
    }

    function withdraw() public payable onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);

        delete balance;
    }
}