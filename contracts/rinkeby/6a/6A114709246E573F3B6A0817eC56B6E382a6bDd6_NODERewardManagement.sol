/**
 *Submitted for verification at Etherscan.io on 2022-02-20
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;



library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}


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


interface IVOCToken {
    function mint(address account, uint256 amount) external;

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function addLiquidityforGenesis(uint256 tokenAmount, uint256 ethAmount)
        external;

    function totalSupply() external view returns (uint256);
}

contract NODERewardManagement {
    using SafeMath for uint256;
    using IterableMapping for IterableMapping.Map;

    struct NodeEntity {
        string name;
        uint256 creationTime;
        uint256 lastDistributeTime;
        uint256 lastAnnualBonusTime;
        uint256 rewardAvailable;
    }

    IterableMapping.Map private nodeOwners;
    mapping(address => NodeEntity[]) private _nodesOfUser;

    uint256 private startTime;
    uint256 private dailyDistributeTime;

    uint256 private DetaforDay = 60 * 3; // real : 60 * 60 * 24, test : 60 * 3
    uint256 private DetaforYear = 60 * 3 * 3; // real : 60 * 60 * 24 * 365, test : 60 * 3 * 3

    address public gateKeeper;
    address public token;
    address public genesis;

    bool private isEarlyBirdTime = true;
    bool private isStart = false;

    uint256 public gasForDistribution = 300000;
    uint256 public totalNodesCreated = 0;
    uint256 private removeNodePenaltyAmount = 0;
    uint256 public nodePrice = 100 * (10**18);
    uint256 public annualBonus = 1 * (10**18);

    bool public distribution = false;
    bool public distributionAnnual = false;
    bool public autoDistri = true;

    constructor() {
        gateKeeper = msg.sender;
    }

    modifier onlySentry() {
        require(msg.sender == token || msg.sender == gateKeeper, "Fuck off");
        _;
    }

    modifier onlyGenesis() {
        require(msg.sender == genesis, "Not Genesis");
        _;
    }

    modifier started() {
        require(isStart, "Not Start");
        _;
    }

    function uint2str(uint256 _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint256 j = _i;
        uint256 len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint256 k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function isNameAvailable(address account, string memory nodeName)
        private
        view
        returns (bool)
    {
        NodeEntity[] memory nodes = _nodesOfUser[account];
        for (uint256 i = 0; i < nodes.length; i++) {
            if (keccak256(bytes(nodes[i].name)) == keccak256(bytes(nodeName))) {
                return false;
            }
        }
        return true;
    }

    function binary_search(
        NodeEntity[] memory arr,
        uint256 low,
        uint256 high,
        uint256 x
    ) private view returns (int256) {
        if (high >= low) {
            uint256 mid = (high + low).div(2);
            if (arr[mid].creationTime == x) {
                return int256(mid);
            } else if (arr[mid].creationTime > x) {
                return binary_search(arr, low, mid - 1, x);
            } else {
                return binary_search(arr, mid + 1, high, x);
            }
        } else {
            return -1;
        }
    }

    function isNodeOwner(address account) private view returns (bool) {
        return nodeOwners.get(account) > 0;
    }

    function _isNodeOwner(address account) external view returns (bool) {
        return isNodeOwner(account);
    }

    function _getNodeNumberOf(address account) public view returns (uint256) {
        return nodeOwners.get(account);
    }

    function setToken(address token_) external onlySentry {
        require(token_ != address(0), "Token CANNOT BE ZERO");
        token = token_;
    }

    
    function setGenesis(address _genesis) external onlySentry {
        require(_genesis != address(0), "Genesis CANNOT BE ZERO");
        genesis = _genesis;
    }

    function claimable(NodeEntity memory node) private view returns (bool) {
        return node.lastAnnualBonusTime + DetaforYear <= block.timestamp;
    }

    function _changeNodePrice(uint256 newNodePrice) external onlySentry {
        nodePrice = newNodePrice;
    }

    function _changeAutoDistri(bool newMode) external onlySentry {
        autoDistri = newMode;
    }

    function createNode(address account, string memory nodeName)
        external
        onlySentry started
    {
        require(
            isNameAvailable(account, nodeName),
            "CREATE NODE: Name not available"
        );
        _nodesOfUser[account].push(
            NodeEntity({
                name: nodeName,
                creationTime: block.timestamp,
                lastDistributeTime: block.timestamp,
                lastAnnualBonusTime: block.timestamp,
                rewardAvailable: 0
            })
        );
        nodeOwners.set(account, _nodesOfUser[account].length);
        totalNodesCreated++;
        if (autoDistri && !distribution && distributionAnnual) {
            distributeRewardsDaily();
            distributeRewards();
        }
    }

    function removeNode(address account, uint256 _creationTime) external onlySentry started {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        bool found = false;
        int256 index = binary_search(nodes, 0, numberOfNodes, _creationTime);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        delete nodes[validIndex];
        nodeOwners.set(account, nodes.length);
        totalNodesCreated--;
        removeNodePenaltyAmount++;
        if (autoDistri && !distribution && distributionAnnual) {
            distributeRewardsDaily();
            distributeRewards();
        }
    }

    function removeNodeAll(address account, uint256 nodeCount) external onlySentry started {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        for (uint i = 0; i < nodeCount; i++) {
                delete nodes[i];
        }
        nodeOwners.set(account, 0);
        totalNodesCreated.sub(nodeCount);
        removeNodePenaltyAmount.add(nodeCount);
        if (autoDistri && !distribution && distributionAnnual) {
            distributeRewardsDaily();
            distributeRewards();
        }
    }

    function _getRewardAmountOf(address account)
        external
        view
        returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");
        uint256 nodesCount;
        uint256 rewardCount = 0;

        NodeEntity[] storage nodes = _nodesOfUser[account];
        nodesCount = nodes.length;

        for (uint256 i = 0; i < nodesCount; i++) {
            rewardCount += nodes[i].rewardAvailable;
        }

        return rewardCount;
    }

    function _getRewardAmountOf(address account, uint256 _creationTime)
        external
        view
        returns (uint256)
    {
        require(isNodeOwner(account), "GET REWARD OF: NO NODE OWNER");

        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        uint256 rewardNode = node.rewardAvailable;
        return rewardNode;
    }

    function _getNodesNames(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET NAMES: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory names = nodes[0].name;
        string memory separator = "#";
        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];
            names = string(abi.encodePacked(names, separator, _node.name));
        }
        return names;
    }

    function _getNodesCreationTime(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET CREATIME: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _creationTimes = uint2str(nodes[0].creationTime);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _creationTimes = string(
                abi.encodePacked(
                    _creationTimes,
                    separator,
                    uint2str(_node.creationTime)
                )
            );
        }
        return _creationTimes;
    }

    function _getNodeWithCreatime(
        NodeEntity[] storage nodes,
        uint256 _creationTime
    ) private view returns (NodeEntity storage) {
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        bool found = false;
        int256 index = binary_search(nodes, 0, numberOfNodes, _creationTime);
        uint256 validIndex;
        if (index >= 0) {
            found = true;
            validIndex = uint256(index);
        }
        require(found, "NODE SEARCH: No NODE Found with this blocktime");
        return nodes[validIndex];
    }

    function _burn(uint256 index) internal {
        require(index < nodeOwners.size());
        nodeOwners.remove(nodeOwners.getKeyAtIndex(index));
        
    }


    function distributeRewardsDaily() private returns (uint256) {
        if (dailyDistributeTime.add(DetaforDay) < block.timestamp) {
            distribution = true;
            uint256 numberOfnodeOwners = nodeOwners.keys.length;
            if(numberOfnodeOwners > 0) {
                uint256 totalRewardAmount = 0;
                uint256 mintTokenAmount = 0;
                (totalRewardAmount, mintTokenAmount) = calcRewardNode();

                uint256 rewardNode = totalRewardAmount.div(totalNodesCreated);

                uint256 localLastIndex = 0;
                uint256 iterations = 0;
                uint256 nodesCount;
                NodeEntity[] storage nodes;
                NodeEntity storage _node;

                IVOCToken(token).mint(token, mintTokenAmount);
                while (iterations < numberOfnodeOwners) {
                    if (localLastIndex >= nodeOwners.keys.length) {
                        localLastIndex = 0;
                    }
                    nodes = _nodesOfUser[nodeOwners.keys[localLastIndex]];
                    nodesCount = nodes.length;
                    for (uint256 i = 0; i < nodesCount; i++) {
                        _node = nodes[i];
                        _node.rewardAvailable += rewardNode;
                    }
                    iterations++;
                }

                distribution = false;
                return (iterations);
            }
            
        }
        return 0;
    }

    function distributeRewards() private returns (uint256) {
        distributionAnnual = true;
        uint256 numberOfnodeOwners = nodeOwners.keys.length;

        if(numberOfnodeOwners > 0) {
            NodeEntity[] storage nodes;
            NodeEntity storage _node;
            uint256 iterations = 0;
            uint256 localLastIndex = 0;
            uint256 nodesCount;
            while (iterations < numberOfnodeOwners) {
                nodes = _nodesOfUser[nodeOwners.keys[localLastIndex]];
                nodesCount = nodes.length;
                for (uint256 i = 0; i < nodesCount; i++) {
                    _node = nodes[i];
                    if (claimable(_node)) {
                        _node.rewardAvailable += annualBonus;
                        _node.lastAnnualBonusTime += DetaforYear;
                    }
                }
                iterations++;
            }
            distributionAnnual = false;

            return iterations;

        }
        
        return 0;
        
    }

    function calcRewardNode() private returns (uint256, uint256) {
        uint256 totalSupply = IVOCToken(token).totalSupply();
        uint256 increaseTokenAmount = totalSupply.div(10000);
        uint256 totalRewardAmount = increaseTokenAmount.add(
            removeNodePenaltyAmount
        );
        removeNodePenaltyAmount = 0;
        if (isEarlyBirdTime) {
            uint256 earlyBirdReward = calcEarlyBirdReward();
            totalRewardAmount.add(earlyBirdReward);
            increaseTokenAmount.add(earlyBirdReward);
        }
        dailyDistributeTime.add(DetaforDay);
        return (totalRewardAmount, increaseTokenAmount);
    }

    function calcEarlyBirdReward() private returns (uint256) {
        uint256 mintTokenAmount = 0;
        uint256 deltaTime = dailyDistributeTime.sub(startTime);
        if (deltaTime < DetaforYear) {
            mintTokenAmount = 7500 * (10**18);
        } else if (deltaTime < (DetaforYear + DetaforDay)) {
            mintTokenAmount = 270000 * (10**18);
        } else if (deltaTime < (2 * DetaforYear)) {
            mintTokenAmount = 5000 * (10**18);
        } else if (deltaTime < (2 * DetaforYear + DetaforDay)) {
            mintTokenAmount = 180000 * (10**18);
        } else if (deltaTime < (3 * DetaforYear)) {
            mintTokenAmount = 2500 * (10**18);
        } else {
            mintTokenAmount = 90000 * (10**18);
            isEarlyBirdTime = false;
        }
        return mintTokenAmount;
    }

    function _cashoutNodeReward(address account, uint256 _creationTime)
        external
        onlySentry
        returns (uint256)
    {
        require(_creationTime > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 numberOfNodes = nodes.length;
        require(
            numberOfNodes > 0,
            "CASHOUT ERROR: You don't have nodes to cash-out"
        );
        NodeEntity storage node = _getNodeWithCreatime(nodes, _creationTime);
        uint256 rewardNode = node.rewardAvailable;
        node.rewardAvailable = 0;
        return rewardNode;
    }

    function _cashoutAllNodesReward(address account)
        external
        onlySentry
        returns (uint256)
    {
        NodeEntity[] storage nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        require(nodesCount > 0, "NODE: CREATIME must be higher than zero");
        NodeEntity storage _node;
        uint256 rewardsTotal = 0;
        for (uint256 i = 0; i < nodesCount; i++) {
            _node = nodes[i];
            rewardsTotal += _node.rewardAvailable;
            _node.rewardAvailable = 0;
        }
        return rewardsTotal;
    }

    function _getNodesRewardAvailable(address account)
        external
        view
        returns (string memory)
    {
        require(isNodeOwner(account), "GET REWARD: NO NODE OWNER");
        NodeEntity[] memory nodes = _nodesOfUser[account];
        uint256 nodesCount = nodes.length;
        NodeEntity memory _node;
        string memory _rewardsAvailable = uint2str(nodes[0].rewardAvailable);
        string memory separator = "#";

        for (uint256 i = 1; i < nodesCount; i++) {
            _node = nodes[i];

            _rewardsAvailable = string(
                abi.encodePacked(
                    _rewardsAvailable,
                    separator,
                    uint2str(_node.rewardAvailable)
                )
            );
        }
        return _rewardsAvailable;
    }

    function _distributeRewards() external onlySentry started {
        distributeRewardsDaily();
        distributeRewards();
    }

    function start() external onlyGenesis {
        startTime = block.timestamp;
        isStart = true;
    }
}