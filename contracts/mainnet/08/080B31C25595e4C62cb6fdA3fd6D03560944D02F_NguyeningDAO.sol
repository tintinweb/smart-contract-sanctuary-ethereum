// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

//OpenZEPP
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

library IterableMapping {
    // Iterable mapping from address to uint;
    struct Map {
        address[] keys;
        mapping(address => uint256) values;
        mapping(address => uint256) indexOf;
        mapping(address => bool) inserted;
    }

    function get(Map storage map, address key) public view returns (uint256) {
        return map.values[key];
    }

    function getIndexOfKey(Map storage map, address key)
        public
        view
        returns (int256)
    {
        if (!map.inserted[key]) {
            return -1;
        }
        return int256(map.indexOf[key]);
    }

    function getKeyAtIndex(Map storage map, uint256 index)
        public
        view
        returns (address)
    {
        return map.keys[index];
    }

    function size(Map storage map) public view returns (uint256) {
        return map.keys.length;
    }

    function set(
        Map storage map,
        address key,
        uint256 val
    ) public {
        if (map.inserted[key]) {
            map.values[key] = val;
        } else {
            map.inserted[key] = true;
            map.values[key] = val;
            map.indexOf[key] = map.keys.length;
            map.keys.push(key);
        }
    }

    function remove(Map storage map, address key) public {
        if (!map.inserted[key]) {
            return;
        }

        delete map.inserted[key];
        delete map.values[key];

        uint256 index = map.indexOf[key];
        uint256 lastIndex = map.keys.length - 1;
        address lastKey = map.keys[lastIndex];

        map.indexOf[lastKey] = index;
        delete map.indexOf[key];

        map.keys[index] = lastKey;
        map.keys.pop();
    }
}

contract NodeManager is Ownable {
    // Declare all necessary variables
    using IterableMapping for IterableMapping.Map;
    uint256 public setupFee = 0.01 ether; // ONE-TIME ETH-USD FEE TO SETUP NODE
    uint256 public nodeFee = 100 * (10**18); // COST TO SETUP EACH NODE IN $WIN TOKENS
    uint256 public nodeReward = 1 * (10**18); // MAXIMUM REWARDS FOR NODE PER DAY
    uint256 public burnCount; // Keep track of total tokens burned
    uint256 public nodeLimit = 100; // Node Limit Per account
    uint256 public minAgeReduction = 8 hours;
    uint256 public totalNodes;
    uint256 public burnAmount = 20; // Tokent amount to be burned per node creation
    address public gateKeeper;
    address public token;

    struct RewardModel {
        uint256 rewardRate;
        uint256 lastUpdated;
    }

    struct NodeModel {
        uint256 creationTime;
        uint256 lastClaimTime;
        uint256 nodeLevel;
        uint256 rewards;
    }

    IterableMapping.Map private nodeOwners;
    mapping(address => NodeModel[]) private userNodes;
    RewardModel public rewardManager;

    constructor(address _gate, address _token) {
        token = _token;
        gateKeeper = _gate;
        rewardManager.rewardRate = nodeReward;
        rewardManager.lastUpdated = block.timestamp;
    }

    modifier onlyController() {
        require(
            msg.sender == token ||
                msg.sender == gateKeeper ||
                msg.sender == owner(),
            "ERROR: You are not authorized."
        );
        _;
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k-1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function setRewardRate(uint256 _amount) external onlyController{
        require(_amount > 0 && _amount <= nodeReward, "Set Reward ERROR: Amount is not within boundaries.");
        rewardManager.rewardRate = _amount;
        rewardManager.lastUpdated = block.timestamp;
    }

    function totalRewards(address _account, uint256 _timeStamp)
        external
        view
        returns (uint256)
    {
        //REQUIRE TO BE A NODE OWNER
        require(
            nodeOwners.get(_account) > 0,
            "NODE ERROR: USER DO NOT OWN ANY NODES."
        );

        uint256 rewardCount;

        NodeModel[] memory nodes = userNodes[_account];

        for (uint256 i = 0; i < nodes.length; i++) {
            //NEED GET TOTAL AMOUNT OF REWARDS
            rewardCount += getRewardWithDecay(nodes[i], _timeStamp);
            rewardCount += nodes[i].rewards;
        }

        return rewardCount;
    }

    function claimAll(address _account, uint256 _timeStamp)
        external
        onlyController
    {
        //Need to add requirement to the GateKeeper
        NodeModel[] storage nodes = userNodes[_account];
        for (uint256 i = 0; i < nodes.length; i++) {
            //Update node last claim time
            nodes[i].lastClaimTime = _timeStamp;
            nodes[i].rewards = 0;
        }
        //Last claim updated for all nodes, now rewards will be sent via main contract.
        //Rewards will be send from distribution pool which could be the token contract itself.
    }

    function updatePendingRewards(address _account, uint256 _amount) external onlyController{
        userNodes[_account][0].rewards += _amount;
    }

    function createNode(
        uint256 _amount,
        address _account,
        uint256 _level
    ) external onlyController {
        for (uint256 i = 0; i < _amount; i++) {
            userNodes[_account].push(
                NodeModel({
                    creationTime: block.timestamp,
                    lastClaimTime: block.timestamp,
                    nodeLevel: _level,
                    rewards: 0
                })
            );
        }
        totalNodes = totalNodes + _amount;
        nodeOwners.set(_account, userNodes[_account].length);
    }

    function levelUp(address _account, uint256 _index, uint256 _level) external onlyController{
        NodeModel[] storage nodes = userNodes[_account];
        nodes[_index].rewards = nodes[_index].rewards + getRewardWithDecay(nodes[_index], block.timestamp);
        uint256 currentLevel = nodes[_index].nodeLevel;
        nodes[_index].nodeLevel = currentLevel + _level;
        currentLevel++;
        nodes[_index].lastClaimTime = block.timestamp;
        totalNodes = totalNodes + _level;
        uint256 creationTime = nodes[_index].creationTime;
        uint256 newCreationTime;
        for(uint256 i = 0; i < _level; i++){
            uint256 addAge = (block.timestamp - creationTime)/(currentLevel + i);
            if(addAge < minAgeReduction)
                newCreationTime += minAgeReduction;
            else
                newCreationTime += addAge;
        }

        if(creationTime + newCreationTime >= block.timestamp)
            nodes[_index].creationTime = block.timestamp;
        else
            nodes[_index].creationTime += newCreationTime;
    }

    function getAllUserNodes(address _account) external view returns(string memory){
        require(nodeOwners.get(_account) > 0, "GET NODE ERROR: USER DO NOT OWN ANY NODES.");
        NodeModel[] memory nodes = userNodes[_account];
        string memory separator = "#";
        string memory insep = ",";
        string memory data; 
        {data = string(abi.encodePacked(uint2str(0), insep, uint2str(nodes[0].creationTime), insep, uint2str(nodes[0].lastClaimTime)));}
        {data = string(abi.encodePacked(data, insep, uint2str(nodes[0].nodeLevel), insep, uint2str(nodes[0].rewards)));}
        for (uint256 i = 1; i < nodes.length; i++) {
            {data = string(abi.encodePacked(data, separator, uint2str(i), insep, uint2str(nodes[i].creationTime))); }
            {data = string(abi.encodePacked(data, insep, uint2str(nodes[i].lastClaimTime), insep, uint2str(nodes[i].nodeLevel), insep, uint2str(nodes[i].rewards))); }
        }
        return data;
    }

    function getRangeUserNodes(address _account, uint256 _start, uint256 _end) external view returns(string memory){
        require(nodeOwners.get(_account) > 0, "GET NODE ERROR: USER DO NOT OWN ANY NODES.");
        NodeModel[] memory nodes = userNodes[_account];
        uint256 nodesCount = nodes.length;
        require(_end <= nodesCount && _start <= nodesCount && _start < _end, "Get Node ERROR: Need start or end to be within range.");
        string memory separator = "#";
        string memory insep = ",";
        string memory data; 
        {data = string(abi.encodePacked(uint2str(_start), insep, uint2str(nodes[_start].creationTime), insep, uint2str(nodes[_start].lastClaimTime))); }
        {data = string(abi.encodePacked(data, insep, uint2str(nodes[_start].nodeLevel), insep, uint2str(nodes[_start].rewards)));}
        
        for (uint256 i = _start+1; i <= _end; i++) {
            {data = string(abi.encodePacked(data, separator, uint2str(i), insep, uint2str(nodes[i].creationTime)));}
            {data = string(abi.encodePacked(data, insep, uint2str(nodes[i].lastClaimTime), insep, uint2str(nodes[i].nodeLevel), insep, uint2str(nodes[i].rewards)));}
        }
        return data;
    }

    function getNodeByIndex(address _account, uint256 _index) external view returns(string memory){
        require(nodeOwners.get(_account) > 0, "GET NODE ERROR: USER DO NOT OWN ANY NODES.");
        NodeModel[] memory nodes = userNodes[_account];
        require(_index < nodes.length, "Get Node ERROR: Index is not within range.");
        string memory insep = ",";
        return string(abi.encodePacked(uint2str(_index), insep, uint2str(nodes[_index].creationTime), insep, uint2str(nodes[_index].lastClaimTime), insep, uint2str(nodes[_index].nodeLevel), insep, uint2str(nodes[_index].rewards)));
    }

    function getRewardWithDecay(NodeModel memory node, uint256 _timeStamp) private view returns (uint256) {
        uint256 rewardCount;
        uint256 decay;

        if(_timeStamp >= node.creationTime + 540 days){
            decay = (((_timeStamp - node.lastClaimTime) * ((rewardManager.rewardRate * node.nodeLevel) / 1 days)) / 10) * 9;
        }
        else if(_timeStamp >= node.creationTime + 360 days){
            decay = (((_timeStamp - node.lastClaimTime) * ((rewardManager.rewardRate * node.nodeLevel) / 1 days)) / 4) * 3;
        } else if(_timeStamp >= node.creationTime + 180 days){
            decay = ((_timeStamp - node.lastClaimTime) * ((rewardManager.rewardRate * node.nodeLevel) / 1 days)) / 2;
        } else if(_timeStamp >= node.creationTime + 90 days){
            decay = ((_timeStamp - node.lastClaimTime) * ((rewardManager.rewardRate * node.nodeLevel) / 1 days)) / 4;
        } else {
            decay = 0;
        }
        rewardCount = (_timeStamp - node.lastClaimTime) * ((rewardManager.rewardRate * node.nodeLevel) / 1 days) - decay;

        return rewardCount;
    }

    function getRewardsByIndex(address _account, uint256 _timeStamp, uint256 _index) external view returns (uint256){
        require(nodeOwners.get(_account) > 0, "GET NODE ERROR: USER DO NOT OWN ANY NODES.");
        NodeModel[] memory nodes = userNodes[_account];
        require(_index < nodes.length, "Get Node ERROR: Index is not within range.");
        return getRewardWithDecay(nodes[_index], _timeStamp) + nodes[_index].rewards;
    }

    function getNodeNumberOf(address _account) external view returns (uint256) {
        return nodeOwners.get(_account);
    }

    function getLastRewardRateUpdate() external view returns (uint256){
        return rewardManager.lastUpdated;
    }

    function setSetupFee(uint256 _amount) external onlyController {
        setupFee = _amount;
    }

    function setNodeFee(uint256 _amount) external onlyController {
        nodeFee = _amount;
    }

    function setReward(uint256 _amount) external onlyController {
        nodeReward = _amount;
    }

    function setBurnAmount(uint256 _amount) external onlyController {
        burnAmount = _amount;
    }

    function setNodeLimit(uint256 _amount) external onlyController {
        nodeLimit = _amount;
    }

    function setGateKeeper(address _account) external onlyController {
        gateKeeper = _account;
    }

    function setToken(address _account) external onlyController {
        token = _account;
    }

    function updateBurnCount(uint256 _amount) external onlyController {
        burnCount += _amount;
    }

    function setBurnCount(uint256 _amount) external onlyController {
        burnCount = _amount;
    }

    function setMinAgeReduction(uint256 _amount) external onlyController {
        minAgeReduction = _amount;
    }

    function getRewardRate() external view onlyController returns(uint256){
        return rewardManager.rewardRate;
    }
}

contract NguyeningDAO is Ownable, ERC20, ERC20Burnable {
    NodeManager public nodeManager;
    address public distributionPool;
    uint256 public rewardTimer = 1 days;
    bool isPaused;
    mapping(address => bool) private blackList;

    constructor(address _distributionPool) ERC20("NguyeningDAO", "WIN") {
        _mint(msg.sender, 10000000 * (10**18));
        distributionPool = _distributionPool;
        isPaused = false;
    }

    modifier contractPaused() {
        require(isPaused == false);
        _;
    }

    function _transfer(
        address from,
        address to,
        uint256 amount
    ) internal override contractPaused {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");
        require(!blackList[from] && !blackList[to], "Blacklisted address");

        super._transfer(from, to, amount);
    }

    function claimAllRewards() public contractPaused {
        address account = msg.sender;
        uint256 time = block.timestamp;
        require(
            nodeManager.getNodeNumberOf(account) > 0,
            "CLAIM ERROR: YOU DONT HAVE ANY NODES."
        );
        require(
            account != address(0),
            "CLAIM ERROR: ADDRESS CANNOT BE A ZERO ADDRESS."
        );
        require(!blackList[account], "CLAIM ERROR: BLACKLISTED ADDRESS.");
        uint256 rewardAmount = nodeManager.totalRewards(account, time);
        require(rewardAmount > 0, "CLAIM ERROR: NOT ENOUGH REWARDS.");
        require(
            balanceOf(distributionPool) >= rewardAmount,
            "CLAIM ERROR: POOL DOES NOT HAVE ENOUGH REWARDS. WAIT TILL REPLENISH."
        );
        nodeManager.claimAll(account, time);
        _transfer(distributionPool, account, rewardAmount);
        updateRewardRate();
    }

    function makeNodes(uint256 _amount, uint256 _level) public payable contractPaused {
        address account = msg.sender;
        require(
            nodeManager.getNodeNumberOf(account) + _amount <=
                nodeManager.nodeLimit(),
            "NODE CREATION: YOU WILL EXCEEDED THE NODE LIMIT."
        );
        require(
            account != address(0),
            "NODE CREATION: ADDRESS CANNOT BE A ZERO ADDRESS."
        );
        require(_level > 0, "NODE CREATION: LEVEL MUST BE GREATER THAN ZERO.");
        require(!blackList[account], "NODE CREATION: BLACKLISTED ADDRESS.");
        uint256 nodePrice = nodeManager.nodeFee() *
            _amount *
            _level;
        uint256 setupFee = nodeManager.setupFee() *
            _amount *
            _level;
        require(msg.value >= setupFee, "NODE CREATION: User did not send enough ETH.");
        require(
            balanceOf(account) >= nodePrice,
            "NODE CREATION: Not enough tokens to create node(s)."
        );
        super._transfer(account, distributionPool, nodePrice);
        nodeManager.createNode(_amount, account, _level);
        uint256 burnAmount = (nodeManager.burnAmount() * (10**18)) * _amount * _level;
        if (burnAmount >= 0 && balanceOf(distributionPool) > burnAmount) {
            super._burn(distributionPool, burnAmount);
            nodeManager.updateBurnCount(nodeManager.burnAmount() * _amount * _level);
        }
        updateRewardRate();
    }

    function levelUpNode(uint256 _index, uint256 _level) public payable contractPaused {
        address account = msg.sender;
        uint256 myNodes = nodeManager.getNodeNumberOf(account);
        require(
            myNodes > 0,
            "LEVEL UP ERROR: YOU DONT HAVE ANY NODES."
        );
        require((_index+1) <= myNodes, "LEVEL UP ERROR: THIS NODE INDEX DOES NOT EXIST.");
        require(
            account != address(0),
            "LEVEL UP ERROR: ADDRESS CANNOT BE A ZERO ADDRESS."
        );
        require(_level > 0, "LEVEL UP ERROR: LEVEL MUST BE GREATER THAN ZERO.");
        require(!blackList[account], "CLAIM ERROR: BLACKLISTED ADDRESS.");
        uint256 nodePrice = nodeManager.nodeFee() * _level;
        uint256 setupFee = nodeManager.setupFee() * _level;
        require(msg.value >= setupFee, "LEVEL UP ERROR: User did not send enough ETH.");
        require(
            balanceOf(account) >= nodePrice,
            "LEVEL UP ERROR: Not enough tokens to create node(s)."
        );
        super._transfer(account, distributionPool, nodePrice);
        nodeManager.levelUp(account, _index, _level);
        uint256 burnAmount = (nodeManager.burnAmount() * (10**18)) * _level;
        if (burnAmount >= 0 && balanceOf(distributionPool) > burnAmount) {
            super._burn(distributionPool, burnAmount);
            nodeManager.updateBurnCount(nodeManager.burnAmount() * _level);
        }
        updateRewardRate();
    }

    function compoundRewardsToLevel(uint256 _index) public payable contractPaused {
        address account = msg.sender;
        uint256 myNodes = nodeManager.getNodeNumberOf(account);
        require(
             myNodes > 0,
            "COMPOUND ERROR: YOU DONT HAVE ANY NODES."
        );
        require(
            account != address(0),
            "COMPOUND ERROR: ADDRESS CANNOT BE A ZERO ADDRESS."
        );
        require(!blackList[account], "COMPOUND ERROR: BLACKLISTED ADDRESS.");
        uint256 totalReward = nodeManager.totalRewards(account,block.timestamp);
        uint256 level =  totalReward / nodeManager.nodeFee();
        require(
            level > 0,
            "COMPOUND ERROR: NOT ENOUGH REWARDS TO COMPUND TO LEVEL"
        );
        require((_index+1) <= myNodes, "COMPOUND ERROR: THIS NODE INDEX DOES NOT EXIST.");
        uint256 setupFee = nodeManager.setupFee() * level;
        require(msg.value >= setupFee, "COMPOUNED ERROR: DID NOT SEND ENOUGH ETH FOR SETUP FEE.");
        nodeManager.claimAll(account, block.timestamp);
        nodeManager.levelUp(account, _index, level);
        nodeManager.updatePendingRewards(account, totalReward % nodeManager.nodeFee());
        uint256 burnAmount = (nodeManager.burnAmount() * (10**18)) *
            level;
        if (burnAmount >= 0 && balanceOf(distributionPool) > burnAmount) {
            super._burn(distributionPool, burnAmount);
            nodeManager.updateBurnCount(
                nodeManager.burnAmount() * level
            );
        }
        updateRewardRate();
    }

    function compoundRewards(uint256 _level) public payable contractPaused{
        address account = msg.sender;
        require(
            nodeManager.getNodeNumberOf(account) > 0,
            "COMPOUND ERROR: YOU DONT HAVE ANY NODES."
        );
        require(_level > 0, "COMPOUND ERROR: THE LEVEL MUST BE GREATER THAN ZERO.");
        require(
            account != address(0),
            "COMPOUND ERROR: ADDRESS CANNOT BE A ZERO ADDRESS."
        );
        require(!blackList[account], "COMPOUND ERROR: BLACKLISTED ADDRESS.");
        uint256 totalReward = nodeManager.totalRewards(account, block.timestamp);
        uint256 amountOfNodes =  totalReward / (nodeManager.nodeFee() * _level);
        require(
            amountOfNodes > 0,
            "COMPOUND ERROR: NOT ENOUGH REWARDS TO COMPUND TO NODE"
        );
        require(
            nodeManager.getNodeNumberOf(account) + amountOfNodes <=
                nodeManager.nodeLimit(),
            "COMPOUND ERROR: YOU WILL EXCEEDED THE NODE LIMIT."
        );
        uint256 setupFee = nodeManager.setupFee() * amountOfNodes * _level;
        require(msg.value >= setupFee, "COMPOUNED ERROR: DID NOT SEND ENOUGH ETH FOR SETUP FEE.");
        nodeManager.claimAll(account, block.timestamp);
        nodeManager.createNode(amountOfNodes, account, _level);
        nodeManager.updatePendingRewards(account, totalReward % nodeManager.nodeFee());
        uint256 burnAmount = (nodeManager.burnAmount() * (10**18)) *
            amountOfNodes * _level;
        if (burnAmount >= 0 && balanceOf(distributionPool) > burnAmount) {
            super._burn(distributionPool, burnAmount);
            nodeManager.updateBurnCount(
                nodeManager.burnAmount() * amountOfNodes * _level
            );
        }
        updateRewardRate();
    }

    function getNodeRewards(address _account) public view contractPaused returns (uint256) {
        return nodeManager.totalRewards(_account, block.timestamp);
    }

    function updateRewardRate() private {
        uint256 lastUpdated = nodeManager.getLastRewardRateUpdate();
        if(block.timestamp >= (lastUpdated + rewardTimer)){
            uint256 poolBalance = balanceOf(distributionPool);
            uint256 nodeReward = nodeManager.nodeReward();
            uint256 totalDailyRewards = getTotalNodeCount() * nodeReward;
            uint256 newReward;
            if(poolBalance/totalDailyRewards >= 75){
                newReward = nodeReward;
            } else if(poolBalance/totalDailyRewards >= 60){
                newReward = (nodeReward / 10) * 8;
            } else if(poolBalance/totalDailyRewards >= 40){
                newReward = (nodeReward / 10) * 6;
            } else if(poolBalance/totalDailyRewards >= 25){
                newReward = (nodeReward / 10) * 4;
            } else {
                newReward = (nodeReward / 10) * 2;
            }
            nodeManager.setRewardRate(newReward);
        }
    }

    function getNodeCount(address _account) public view contractPaused returns (uint256) {
        return nodeManager.getNodeNumberOf(_account);
    }

    function getTotalNodeCount() public view contractPaused returns (uint256) {
        return nodeManager.totalNodes();
    }

    function getNodeSetupFee() public view contractPaused returns (uint256) {
        return nodeManager.setupFee();
    }

    function getNodeFee() public view contractPaused returns (uint256) {
        return nodeManager.nodeFee();
    }

    function getRewardAmountPerNode() public view contractPaused returns (uint256) {
        return nodeManager.getRewardRate();
    }

    function getBurnAmount() public view contractPaused returns (uint256) {
        return nodeManager.burnAmount();
    }

    function getAllUserNodes(address _account) public view contractPaused returns(string memory){
        return nodeManager.getAllUserNodes(_account);
    }

    function getNodeByIndex(address _account, uint256 _index) public view contractPaused returns(string memory){
        return nodeManager.getNodeByIndex(_account, _index);
    }

    function getRangeUserNodes(address _account, uint256 _start, uint256 _end) public view contractPaused returns(string memory){
        return nodeManager.getRangeUserNodes(_account, _start, _end);
    }

    function getRewardByIndex(address _account, uint256 _index) public view contractPaused returns(uint256){
        return nodeManager.getRewardsByIndex(_account, block.timestamp, _index);
    }

    function getBurnCount() public view contractPaused returns(uint256){
        return nodeManager.burnCount();
    }

    function getNodeLimit() public view contractPaused returns(uint256){
        return nodeManager.nodeLimit();
    }

    function getBalanceOfDistPool() public view contractPaused returns(uint256){
        return balanceOf(distributionPool);
    }

    function getBaseReward() public view contractPaused returns(uint256){
        return nodeManager.nodeReward();
    }

    function getMinAgeReduction() public view contractPaused returns(uint256 age){
        return nodeManager.minAgeReduction();
    }

    //Owner Functions
    function pauseContract(bool _pause) public onlyOwner {
        isPaused = _pause;
    }

    function setRewardRate(uint256 _amount) public onlyOwner{
        nodeManager.setRewardRate(_amount);
    }

    function setDistributionPool(address _contract) public onlyOwner {
        distributionPool = _contract;
    }

    function setNodeManager(address _contract) external onlyOwner {
        nodeManager = NodeManager(_contract);
    }

    function claimETH() public payable onlyOwner {
        require(payable(msg.sender).send(address(this).balance));
    }
    function setSetupFee(uint256 _amount) public onlyOwner {
        nodeManager.setSetupFee(_amount);
    }

    function setNodeFee(uint256 _amount) public onlyOwner {
        nodeManager.setNodeFee(_amount);
    }

    function setBaseReward(uint256 _amount) public onlyOwner {
        nodeManager.setReward(_amount);
    }

    function setBurnAmount(uint256 _amount) public onlyOwner {
        nodeManager.setBurnAmount(_amount);
    }

    function setNodeLimit(uint256 _amount) public onlyOwner {
        nodeManager.setNodeLimit(_amount);
    }

    function setGateKeeper(address _account) public onlyOwner {
        nodeManager.setGateKeeper(_account);
    }

    function setToken(address _account) public onlyOwner {
        nodeManager.setToken(_account);
    }

    function setBurnCount(uint256 _amount) public onlyOwner {
        nodeManager.setBurnCount(_amount);
    }

    function setRewardTimer(uint256 _amount) public onlyOwner {
        rewardTimer = _amount;
    }

    function ageReduction(uint256 _amount) public onlyOwner {
        nodeManager.setMinAgeReduction(_amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/ERC20Burnable.sol)

pragma solidity ^0.8.0;

import "../ERC20.sol";
import "../../../utils/Context.sol";

/**
 * @dev Extension of {ERC20} that allows token holders to destroy both their own
 * tokens and those that they have an allowance for, in a way that can be
 * recognized off-chain (via event analysis).
 */
abstract contract ERC20Burnable is Context, ERC20 {
    /**
     * @dev Destroys `amount` tokens from the caller.
     *
     * See {ERC20-_burn}.
     */
    function burn(uint256 amount) public virtual {
        _burn(_msgSender(), amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, deducting from the caller's
     * allowance.
     *
     * See {ERC20-_burn} and {ERC20-allowance}.
     *
     * Requirements:
     *
     * - the caller must have allowance for ``accounts``'s tokens of at least
     * `amount`.
     */
    function burnFrom(address account, uint256 amount) public virtual {
        uint256 currentAllowance = allowance(account, _msgSender());
        require(currentAllowance >= amount, "ERC20: burn amount exceeds allowance");
        unchecked {
            _approve(account, _msgSender(), currentAllowance - amount);
        }
        _burn(account, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/ERC20.sol)

pragma solidity ^0.8.0;

import "./IERC20.sol";
import "./extensions/IERC20Metadata.sol";
import "../../utils/Context.sol";

/**
 * @dev Implementation of the {IERC20} interface.
 *
 * This implementation is agnostic to the way tokens are created. This means
 * that a supply mechanism has to be added in a derived contract using {_mint}.
 * For a generic mechanism see {ERC20PresetMinterPauser}.
 *
 * TIP: For a detailed writeup see our guide
 * https://forum.zeppelin.solutions/t/how-to-implement-erc20-supply-mechanisms/226[How
 * to implement supply mechanisms].
 *
 * We have followed general OpenZeppelin Contracts guidelines: functions revert
 * instead returning `false` on failure. This behavior is nonetheless
 * conventional and does not conflict with the expectations of ERC20
 * applications.
 *
 * Additionally, an {Approval} event is emitted on calls to {transferFrom}.
 * This allows applications to reconstruct the allowance for all accounts just
 * by listening to said events. Other implementations of the EIP may not emit
 * these events, as it isn't required by the specification.
 *
 * Finally, the non-standard {decreaseAllowance} and {increaseAllowance}
 * functions have been added to mitigate the well-known issues around setting
 * allowances. See {IERC20-approve}.
 */
contract ERC20 is Context, IERC20, IERC20Metadata {
    mapping(address => uint256) private _balances;

    mapping(address => mapping(address => uint256)) private _allowances;

    uint256 private _totalSupply;

    string private _name;
    string private _symbol;

    /**
     * @dev Sets the values for {name} and {symbol}.
     *
     * The default value of {decimals} is 18. To select a different value for
     * {decimals} you should overload it.
     *
     * All two of these values are immutable: they can only be set once during
     * construction.
     */
    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
    }

    /**
     * @dev Returns the name of the token.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev Returns the symbol of the token, usually a shorter version of the
     * name.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    /**
     * @dev Returns the number of decimals used to get its user representation.
     * For example, if `decimals` equals `2`, a balance of `505` tokens should
     * be displayed to a user as `5.05` (`505 / 10 ** 2`).
     *
     * Tokens usually opt for a value of 18, imitating the relationship between
     * Ether and Wei. This is the value {ERC20} uses, unless this function is
     * overridden;
     *
     * NOTE: This information is only used for _display_ purposes: it in
     * no way affects any of the arithmetic of the contract, including
     * {IERC20-balanceOf} and {IERC20-transfer}.
     */
    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    /**
     * @dev See {IERC20-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _totalSupply;
    }

    /**
     * @dev See {IERC20-balanceOf}.
     */
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }

    /**
     * @dev See {IERC20-allowance}.
     */
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev See {IERC20-approve}.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(_msgSender(), spender, amount);
        return true;
    }

    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public virtual override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        unchecked {
            _approve(sender, _msgSender(), currentAllowance - amount);
        }

        return true;
    }

    /**
     * @dev Atomically increases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        _approve(_msgSender(), spender, _allowances[_msgSender()][spender] + addedValue);
        return true;
    }

    /**
     * @dev Atomically decreases the allowance granted to `spender` by the caller.
     *
     * This is an alternative to {approve} that can be used as a mitigation for
     * problems described in {IERC20-approve}.
     *
     * Emits an {Approval} event indicating the updated allowance.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `spender` must have allowance for the caller of at least
     * `subtractedValue`.
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        uint256 currentAllowance = _allowances[_msgSender()][spender];
        require(currentAllowance >= subtractedValue, "ERC20: decreased allowance below zero");
        unchecked {
            _approve(_msgSender(), spender, currentAllowance - subtractedValue);
        }

        return true;
    }

    /**
     * @dev Moves `amount` of tokens from `sender` to `recipient`.
     *
     * This internal function is equivalent to {transfer}, and can be used to
     * e.g. implement automatic token fees, slashing mechanisms, etc.
     *
     * Emits a {Transfer} event.
     *
     * Requirements:
     *
     * - `sender` cannot be the zero address.
     * - `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     */
    function _transfer(
        address sender,
        address recipient,
        uint256 amount
    ) internal virtual {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        unchecked {
            _balances[sender] = senderBalance - amount;
        }
        _balances[recipient] += amount;

        emit Transfer(sender, recipient, amount);

        _afterTokenTransfer(sender, recipient, amount);
    }

    /** @dev Creates `amount` tokens and assigns them to `account`, increasing
     * the total supply.
     *
     * Emits a {Transfer} event with `from` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function _mint(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: mint to the zero address");

        _beforeTokenTransfer(address(0), account, amount);

        _totalSupply += amount;
        _balances[account] += amount;
        emit Transfer(address(0), account, amount);

        _afterTokenTransfer(address(0), account, amount);
    }

    /**
     * @dev Destroys `amount` tokens from `account`, reducing the
     * total supply.
     *
     * Emits a {Transfer} event with `to` set to the zero address.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens.
     */
    function _burn(address account, uint256 amount) internal virtual {
        require(account != address(0), "ERC20: burn from the zero address");

        _beforeTokenTransfer(account, address(0), amount);

        uint256 accountBalance = _balances[account];
        require(accountBalance >= amount, "ERC20: burn amount exceeds balance");
        unchecked {
            _balances[account] = accountBalance - amount;
        }
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);

        _afterTokenTransfer(account, address(0), amount);
    }

    /**
     * @dev Sets `amount` as the allowance of `spender` over the `owner` s tokens.
     *
     * This internal function is equivalent to `approve`, and can be used to
     * e.g. set automatic allowances for certain subsystems, etc.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `owner` cannot be the zero address.
     * - `spender` cannot be the zero address.
     */
    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev Hook that is called before any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * will be transferred to `to`.
     * - when `from` is zero, `amount` tokens will be minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens will be burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}

    /**
     * @dev Hook that is called after any transfer of tokens. This includes
     * minting and burning.
     *
     * Calling conditions:
     *
     * - when `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * has been transferred to `to`.
     * - when `from` is zero, `amount` tokens have been minted for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens have been burned.
     * - `from` and `to` are never both zero.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;

/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
}