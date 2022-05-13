/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// File: contracts/utils/Auth.sol



// File: contracts/Auth.sol


pragma solidity = 0.8.11;

abstract contract Auth {
  address internal owner;
  mapping(address => bool) internal authorizations;

  constructor(address _owner) {
    owner = _owner;
    authorizations[_owner] = true;
  }

  /**
   * Function modifier to require caller to be contract owner
   */
  modifier onlyOwner() {
    require(isOwner(msg.sender), '!OWNER');
    _;
  }

  /**
   * Function modifier to require caller to be authorized
   */
  modifier authorized() {
    require(isAuthorized(msg.sender), '!AUTHORIZED');
    _;
  }

  /**
   * Authorize address. Owner only
   */
  function authorize(address adr) public onlyOwner {
    authorizations[adr] = true;
  }

  /**
   * Remove address' authorization. Owner only
   */
  function unauthorize(address adr) public onlyOwner {
    authorizations[adr] = false;
  }

  /**
   * Check if address is owner
   */
  function isOwner(address account) public view returns (bool) {
    return account == owner;
  }

  /**
   * Return address' authorization status
   */
  function isAuthorized(address adr) public view returns (bool) {
    return authorizations[adr];
  }

  /**
   * Transfer ownership to new address. Caller must be owner. Leaves old owner authorized
   */
  function transferOwnership(address payable adr) public onlyOwner {
    owner = adr;
    authorizations[adr] = true;
    emit OwnershipTransferred(adr);
  }

  event OwnershipTransferred(address owner);
}

// File: contracts/interfaces/IBEP20.sol


// File: contracts/interfaces/IBEP20.sol


pragma solidity = 0.8.11;

interface IBEP20 {
  function totalSupply() external view returns (uint256);

  function decimals() external view returns (uint8);

  function symbol() external view returns (string memory);

  function name() external view returns (string memory);

  function getOwner() external view returns (address);

  function balanceOf(address account) external view returns (uint256);

  function transfer(address recipient, uint256 amount) external returns (bool);

  function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

  function approve(address spender, uint256 amount) external returns (bool);

  function transferFrom(
    address sender,
    address recipient,
    uint256 amount
  ) external returns (bool);

  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

// File: contracts/interfaces/IETHSToken.sol



// File: contracts/interfaces/IETHSToken.sol

pragma solidity = 0.8.11;

interface IETHSToken is IBEP20 {
    function nodeMintTransfer(address sender, uint256 amount) external;

    function depositAll(address sender, uint256 amount) external;

    function nodeClaimTransfer(address recipient, uint256 amount) external;

    function vaultDepositNoFees(address sender, uint256 amount) external;

    function vaultCompoundFromNode(address sender, uint256 amount) external;

    function setInSwap(bool _inSwap) external;
}

// File: contracts/interfaces/IERC20.sol



// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity = 0.8.11;

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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

// File: contracts/EtherstonesRewardManager.sol

// SPDX-License-Identifier: MIT
// File: contracts/EtherstonesRewardManager.sol

pragma solidity = 0.8.11;



contract EtherstonesRewardManager is Auth {

    uint256 public ETHSDecimals = 10 ** 18;

    uint256 public totalPebbles;
    uint256 public totalShards;
    uint256 public totalStones;
    uint256 public totalCrystals;

    uint256[2] public minMaxPebbles = [5, 8];
    uint256[2] public minMaxShards = [25, 40];
    uint256[2] public minMaxStones = [125, 200];
    uint256[2] public minMaxCrystals = [625, 1000];

    IETHSToken public ethsToken;

    address public rewardPool;

    uint256 public nodeCooldown = 12*3600; //12 hours

    uint256 constant ONE_DAY = 86400; //seconds

    struct EtherstoneNode {
        string name;
        uint256 id;
        uint256 lastInteract;
        uint256 lockedETHS;
        uint256 nodeType; // 0: Pebble, 1: Shard, 2: Stone, 3: Crystal
        uint256 tier; // 0: Emerald, 1: Sapphire, 2: Amethyst, 3: Ruby, 4: Radiant
        uint256 timesCompounded;
        address owner;
    }

    // 0.66%, 0.75%, 0.84%, 0.93%
    uint256[4] public baseNodeDailyInterest = [6600, 7500, 8400, 9300];
    uint256 public nodeDailyInterestDenominator = 1000000;

    // 0.0004, 0.0006, 0.0008, 0.001
    uint256[4] public baseCompoundBoost = [4, 6, 8, 10];
    uint256 public baseCompoundBoostDenominator = 1000000;

    // 1x, 1.05x, 1.1x, 1.15x, 1.2x
    uint256[5] public tierMultipliers = [100, 105, 110, 115, 120];
    uint256 public tierMultipliersDenominator = 100;

    uint256[5] public tierCompoundTimes = [0, 10, 60, 180, 540];

    mapping(address => uint256[]) accountNodes;
    mapping(uint256 => EtherstoneNode) nodeMapping;

    bool public nodeMintingEnabled = true;

    constructor(address _ethsTokenAddress) Auth(msg.sender) {
        totalPebbles = 0;
        totalShards = 0;
        totalCrystals = 0;
        totalStones = 0;

        ethsToken = IETHSToken(_ethsTokenAddress);
    }

    function mintNode(string memory _name, uint256 _amount, uint256 _nodeType) public {
        require(nodeMintingEnabled, "Node minting is disabled");
        require(_nodeType >= 0 && _nodeType <= 3, "Node type is invalid");
        uint256 nameLen = utfStringLength(_name);
        require(utfStringLength(_name) <= 16 && nameLen > 0, "String name is invalid");

        uint256 nodeID = getNumberOfNodes() + 1;
        EtherstoneNode memory nodeToCreate;

        if(_nodeType == 0) {
            require(_amount >= minMaxPebbles[0]*ETHSDecimals && _amount <= minMaxPebbles[1]*ETHSDecimals, "Pebble amount outside of valid range");
            nodeToCreate = EtherstoneNode({
                name: _name,
                id: nodeID,
                lastInteract: block.timestamp,
                lockedETHS: _amount,
                nodeType: _nodeType,
                tier: 0,
                timesCompounded: 0,
                owner: msg.sender
            });
            totalPebbles++;
        }
        if(_nodeType == 1) {
            require(_amount >= minMaxShards[0]*ETHSDecimals && _amount <= minMaxShards[1]*ETHSDecimals, "Shard amount outside of valid range");
            nodeToCreate = EtherstoneNode({
                name: _name,
                id: nodeID,
                lastInteract: block.timestamp,
                lockedETHS: _amount,
                nodeType: _nodeType,
                tier: 0,
                timesCompounded: 0,
                owner: msg.sender
            });
            totalShards++;
        }
        else if (_nodeType == 2) {
            require(_amount >= minMaxStones[0]*ETHSDecimals && _amount <= minMaxStones[1]*ETHSDecimals, "Stone amount outside of valid range");
            nodeToCreate = EtherstoneNode({
                name: _name,
                id: nodeID,
                lastInteract: block.timestamp,
                lockedETHS: _amount,
                nodeType: _nodeType,
                tier: 0,
                timesCompounded: 0,
                owner: msg.sender
            });
            totalStones++;
        }
        else if(_nodeType == 3) {
            require(_amount >= minMaxCrystals[0]*ETHSDecimals && _amount <= minMaxCrystals[1]*ETHSDecimals, "Crystal amount outside of valid range");
            nodeToCreate = EtherstoneNode({
                name: _name,
                id: nodeID,
                lastInteract: block.timestamp,
                lockedETHS: _amount,
                nodeType: _nodeType,
                tier: 0,
                timesCompounded: 0,
                owner: msg.sender
            });
            totalCrystals++;
        }

        nodeMapping[nodeID] = nodeToCreate;
        accountNodes[msg.sender].push(nodeID);

        ethsToken.nodeMintTransfer(msg.sender, _amount);
    }

    function compoundAllAvailableEtherstoneReward() external {
        uint256 numOwnedNodes = accountNodes[msg.sender].length;
        require(numOwnedNodes > 0, "Must own nodes to claim rewards");
        uint256 totalCompound = 0;
        for(uint256 i = 0; i < numOwnedNodes; i++) {
            if(block.timestamp - nodeMapping[accountNodes[msg.sender][i]].lastInteract > nodeCooldown) {
                uint256 nodeID = nodeMapping[accountNodes[msg.sender][i]].id;
                totalCompound += calculateRewards(nodeID);
                updateNodeInteraction(nodeID, block.timestamp, true);
            }
        }
        ethsToken.vaultCompoundFromNode(msg.sender, totalCompound);
    }

    function compoundEtherstoneReward(uint256 _id) external {
        EtherstoneNode memory etherstoneNode = getEtherstoneNodeById(_id);
        require(msg.sender == etherstoneNode.owner, "Must be owner of node to compound");
        require(block.timestamp - etherstoneNode.lastInteract > nodeCooldown, "Node is on cooldown");
        uint256 amount = calculateRewards(etherstoneNode.id);
        updateNodeInteraction(etherstoneNode.id, block.timestamp, true);
        ethsToken.vaultCompoundFromNode(msg.sender, amount);
    }

    function claimAllAvailableEtherstoneReward() external {
        uint256 numOwnedNodes = accountNodes[msg.sender].length;
        require(numOwnedNodes > 0, "Must own nodes to claim rewards");
        uint256 totalClaim = 0;
        for(uint256 i = 0; i < numOwnedNodes; i++) {
            if(block.timestamp - nodeMapping[accountNodes[msg.sender][i]].lastInteract > nodeCooldown) {
                uint256 nodeID = nodeMapping[accountNodes[msg.sender][i]].id;
                if(!inCompounder[nodeID]) {
                    totalClaim += calculateRewards(nodeID);
                    updateNodeInteraction(nodeID, block.timestamp, false);
                }
            }
        }
        ethsToken.nodeClaimTransfer(msg.sender, totalClaim);
    }

    function claimEtherstoneReward(uint256 _id) external {
        require(!inCompounder[_id], "Node cannot be in autocompounder");
        EtherstoneNode memory etherstoneNode = getEtherstoneNodeById(_id);
        require(msg.sender == etherstoneNode.owner, "Must be owner of node to claim");
        require(block.timestamp - etherstoneNode.lastInteract > nodeCooldown, "Node is on cooldown");
        uint256 amount = calculateRewards(etherstoneNode.id);
        updateNodeInteraction(_id, block.timestamp, false);
        ethsToken.nodeClaimTransfer(etherstoneNode.owner, amount);
    }

    function calculateRewards(uint256 _id) public view returns (uint256) {
        EtherstoneNode memory etherstoneNode = getEtherstoneNodeById(_id);
        // (locked amount * daily boost + locked amount * daily interest) * days elapsed
        return ((((((etherstoneNode.lockedETHS
                                  * etherstoneNode.timesCompounded
                                  * baseCompoundBoost[etherstoneNode.nodeType]) / baseCompoundBoostDenominator)
                                  * tierMultipliers[etherstoneNode.tier]) / tierMultipliersDenominator)
                                  + (etherstoneNode.lockedETHS * baseNodeDailyInterest[etherstoneNode.nodeType]) / nodeDailyInterestDenominator)
                                  * (block.timestamp - etherstoneNode.lastInteract) / ONE_DAY);
    }

    function updateNodeInteraction(uint256 _id, uint256 _timestamp, bool _compounded) private {
        nodeMapping[_id].lastInteract = _timestamp;
        if(_compounded) {
            nodeMapping[_id].timesCompounded += nodeMapping[_id].timesCompounded != tierCompoundTimes[4] ? 1 : 0;
        } else {
            nodeMapping[_id].timesCompounded = 0;
        }
        nodeMapping[_id].tier = getTierByCompoundTimes(nodeMapping[_id].timesCompounded);
    }

    function getTierByCompoundTimes(uint256 _compoundTimes) private view returns (uint256) {
        if(_compoundTimes >= tierCompoundTimes[0] && _compoundTimes < tierCompoundTimes[1]) {
            return 0;
        } else if(_compoundTimes >= tierCompoundTimes[1] && _compoundTimes < tierCompoundTimes[2]) {
            return 1;
        } else if(_compoundTimes >= tierCompoundTimes[2] && _compoundTimes < tierCompoundTimes[3]) {
            return 2;
        } else if(_compoundTimes >= tierCompoundTimes[3] && _compoundTimes < tierCompoundTimes[4]) {
            return 3;
        } else {
            return 4;
        }
    }

    function getEtherstoneNodeById(uint256 _id) public view returns (EtherstoneNode memory){
        return nodeMapping[_id];
    }

    function getOwnedNodes(address _address) public view returns (EtherstoneNode[] memory) {
        uint256[] memory ownedNodesIDs = accountNodes[_address];
        EtherstoneNode[] memory ownedNodes = new EtherstoneNode[](ownedNodesIDs.length);
        for(uint256 i = 0; i < ownedNodesIDs.length; i++) {
            ownedNodes[i] = nodeMapping[ownedNodesIDs[i]];
        }
        return ownedNodes;
    }

    function getNumberOfNodes() public view returns (uint256) {
        return totalPebbles + totalShards + totalStones + totalCrystals;
    }

    // used for dashboard display
    function getDailyNodeEmission(uint256 _id) external view returns (uint256) {
        EtherstoneNode memory etherstoneNode = getEtherstoneNodeById(_id);
        return (((((etherstoneNode.lockedETHS
                                  * etherstoneNode.timesCompounded
                                  * baseCompoundBoost[etherstoneNode.nodeType]) / baseCompoundBoostDenominator)
                                  * tierMultipliers[etherstoneNode.tier]) / tierMultipliersDenominator)
                                  + (etherstoneNode.lockedETHS * baseNodeDailyInterest[etherstoneNode.nodeType]) / nodeDailyInterestDenominator);
    }

    function setBaseDailyNodeInterest(uint256 basePebbleInterest, uint256 baseShardInterest, uint256 baseStoneInterest, uint256 baseCrystalInterest) external onlyOwner {
        require(basePebbleInterest > 0 && baseShardInterest > 0 && baseStoneInterest > 0 && baseCrystalInterest > 0, "Interest must be greater than zero");
        baseNodeDailyInterest[0] = basePebbleInterest;
        baseNodeDailyInterest[1] = baseShardInterest;
        baseNodeDailyInterest[2] = baseStoneInterest;
        baseNodeDailyInterest[3] = baseCrystalInterest;
    }

    function setBaseCompoundBoost(uint256 basePebbleBoost, uint256 baseShardBoost, uint256 baseStoneBoost, uint256 baseCrystalBoost) external onlyOwner {
        require(basePebbleBoost > 0 && baseShardBoost > 0 && baseStoneBoost > 0 && baseCrystalBoost > 0, "Boost must be greater than zero");
        baseCompoundBoost[0] = basePebbleBoost;
        baseCompoundBoost[1] = baseShardBoost;
        baseCompoundBoost[2] = baseStoneBoost;
        baseCompoundBoost[3] = baseCrystalBoost;
    }

    function setPebbleMinMax(uint256 min, uint256 max) external onlyOwner {
        require(min > 0 && max > 0 && max > min, "Invalid Pebble minimum and maximum");
        minMaxPebbles[0] = min;
        minMaxPebbles[1] = max;
    }

    function setShardMinMax(uint256 min, uint256 max) external onlyOwner {
        require(min > 0 && max > 0 && max > min, "Invalid Shard minimum and maximum");
        minMaxShards[0] = min;
        minMaxShards[1] = max;
    }

    function setStoneMinMax(uint256 min, uint256 max) external onlyOwner {
        require(min > 0 && max > 0 && max > min, "Invalid Stone minimum and maximum");
        minMaxStones[0] = min;
        minMaxStones[1] = max;
    }

    function setCrystalMinMax(uint256 min, uint256 max) external onlyOwner {
        require(min > 0 && max > 0 && max > min, "Invalid Crystal minimum and maximum");
        minMaxCrystals[0] = min;
        minMaxCrystals[1] = max;
    }
    
    function setNodeMintingEnabled(bool decision) external onlyOwner {
        nodeMintingEnabled = decision;
    }

    function setTierCompoundTimes(uint256 emerald, uint256 sapphire, uint256 amethyst, uint256 ruby, uint256 radiant) external onlyOwner {
        tierCompoundTimes[0] = emerald;
        tierCompoundTimes[1] = sapphire;
        tierCompoundTimes[2] = amethyst;
        tierCompoundTimes[3] = ruby;
        tierCompoundTimes[4] = radiant;
    }

    function setTierMultipliers(uint256 emerald, uint256 sapphire, uint256 amethyst, uint256 ruby, uint256 radiant) external onlyOwner {
        tierMultipliers[0] = emerald;
        tierMultipliers[1] = sapphire;
        tierMultipliers[2] = amethyst;
        tierMultipliers[3] = ruby;
        tierMultipliers[4] = radiant;
    }

    function transferNode(uint256 _id, address _owner, address _recipient) public authorized {
        require(_owner != _recipient, "Cannot transfer to self");
        require(!inCompounder[_id], "Unable to transfer node in compounder");
        uint256 len = accountNodes[_owner].length;
        bool success = false;
        for(uint256 i = 0; i < len; i++) {
            if(accountNodes[_owner][i] == _id) {
                accountNodes[_owner][i] = accountNodes[_owner][len-1];
                accountNodes[_owner].pop();
                accountNodes[_recipient].push(_id);
                nodeMapping[_id].owner = _recipient;
                success = true;
                break;
            }
        }
        require(success, "Transfer failed");
    }

    function massTransferNodes(uint256[] memory _ids, address[] memory _owners, address[] memory _recipients) external authorized {
        require(_ids.length == _owners.length && _owners.length == _recipients.length, "Invalid parameters");
        uint256 len = _ids.length;
        for(uint256 i = 0; i < len; i++) {
            transferNode(_ids[i], _owners[i], _recipients[i]);
        }
    }

    function utfStringLength(string memory str) pure internal returns (uint length) {
        uint i=0;
        bytes memory string_rep = bytes(str);

        while (i<string_rep.length)
        {
            if (string_rep[i]>>7==0)
                i+=1;
            else if (string_rep[i]>>5==bytes1(uint8(0x6)))
                i+=2;
            else if (string_rep[i]>>4==bytes1(uint8(0xE)))
                i+=3;
            else if (string_rep[i]>>3==bytes1(uint8(0x1E)))
                i+=4;
            else
                //For safety
                i+=1;

            length++;
        }
    }

    // /* presale max crystal logic */
    // IERC20 presaleCrystal;
    // uint256 oneCrystal = 10 ** 18;

    // function setPresaleCrystal(address _presaleCrystalAddress) external onlyOwner {
    //     presaleCrystal = IERC20(_presaleCrystalAddress);
    // }

    // function convertPresaleCrystalToReal(string memory _name) external {
    //     require(address(presaleCrystal) != address(0), "Presale token not set");
    //     uint256 balance = presaleCrystal.balanceOf(msg.sender);
    //     require(balance == oneCrystal, "Invalid balance");

    //     presaleCrystal.transferFrom(msg.sender, address(this), balance);
    //     require(presaleCrystal.balanceOf(msg.sender) == 0, "Error with conversion");
        
    //     uint256 nameLen = utfStringLength(_name);
    //     require(utfStringLength(_name) <= 16 && nameLen > 0, "String name is invalid");

    //     uint256 nodeID = getNumberOfNodes() + 1;

    //     nodeMapping[nodeID] = EtherstoneNode({
    //         name: _name,
    //         id: nodeID,
    //         lastInteract: block.timestamp,
    //         lockedETHS: 1000*10**18,
    //         nodeType: 3,
    //         tier: 0,
    //         timesCompounded: 0,
    //         owner: msg.sender
    //     });
    //     accountNodes[msg.sender].push(nodeID);
    //     totalCrystals++;
    // }

    // /* automate compounding */

    // address[] usersInCompounder;
    // mapping(address => uint256[]) nodesInCompounder;
    mapping(uint256 => bool) inCompounder;
    // uint256 public numNodesInCompounder;

    // function addToCompounder(uint256 _id) public {
    //     require(msg.sender == nodeMapping[_id].owner, "Must be owner of node");

    //     if(inCompounder[_id]) {
    //         return;
    //     }

    //     if(nodesInCompounder[msg.sender].length == 0) {
    //         usersInCompounder.push(msg.sender);
    //     }
    //     nodesInCompounder[msg.sender].push(_id);
    //     inCompounder[_id] = true;
    //     numNodesInCompounder++;
    // }

    // function removeFromCompounder(uint256 _id) public {
    //     require(msg.sender == nodeMapping[_id].owner, "Must be owner of node");
    //     require(inCompounder[_id], "Node must be in compounder");

    //     uint256 len = nodesInCompounder[msg.sender].length;
    //     for(uint256 i = 0; i < len; i++) {
    //         if(nodesInCompounder[msg.sender][i] == _id) {
    //             nodesInCompounder[msg.sender][i] = nodesInCompounder[msg.sender][len-1];
    //             nodesInCompounder[msg.sender].pop();
    //             break;
    //         }
    //     }
    //     inCompounder[_id] = false;
    //     numNodesInCompounder--;

    //     if(nodesInCompounder[msg.sender].length == 0) { // remove user
    //         removeCompounderUser(msg.sender);
    //     }
    // }

    // function removeCompounderUser(address _address) private {
    //     uint256 len = usersInCompounder.length;
    //     for(uint256 i = 0; i < len; i++) {
    //         if(usersInCompounder[i] == _address) {
    //             usersInCompounder[i] = usersInCompounder[len-1];
    //             usersInCompounder.pop();
    //             break;
    //         }
    //     }
    // }

    // function addAllToCompounder() external {
    //     uint256 lenBefore = nodesInCompounder[msg.sender].length;
    //     nodesInCompounder[msg.sender] = accountNodes[msg.sender];
    //     uint256 lenAfter = nodesInCompounder[msg.sender].length;
    //     require(lenAfter > lenBefore, "No nodes added to compounder");
    //     if(lenBefore == 0) {
    //         usersInCompounder.push(msg.sender);
    //     }
    //     for(uint256 i = 0; i < lenAfter; i++) {
    //         inCompounder[nodesInCompounder[msg.sender][i]] = true;
    //     }
    //     numNodesInCompounder += lenAfter - lenBefore;
    // }

    // function removeAllFromCompounder() external {
    //     uint256 len = nodesInCompounder[msg.sender].length;
    //     require(len > 0, "No nodes able to be removed");
    //     for(uint256 i = 0; i < len; i++) {
    //         inCompounder[nodesInCompounder[msg.sender][i]] = false;
    //     }
    //     delete nodesInCompounder[msg.sender];
    //     removeCompounderUser(msg.sender);
    //     numNodesInCompounder -= len;
    // }

    // function autoCompound() external {
    //     uint256 len = usersInCompounder.length;
    //     for(uint256 i = 0; i < len; i++) {
    //         compoundAllForUserInCompounder(usersInCompounder[i]);
    //     }
    // }

    // function compoundAllForUserInCompounder(address _address) private {
    //     uint256[] memory ownedInCompounder = nodesInCompounder[_address];
    //     uint256 totalCompound = 0;
    //     uint256 len = ownedInCompounder.length;
    //     for(uint256 i = 0; i < len; i++) {
    //         if(block.timestamp - nodeMapping[ownedInCompounder[i]].lastInteract > nodeCooldown) {
    //             uint256 nodeID = nodeMapping[ownedInCompounder[i]].id;
    //             totalCompound += calculateRewards(nodeID);
    //             updateNodeInteraction(nodeID, block.timestamp, true);
    //         }
    //     }
    //     if(totalCompound > 0) {
    //         ethsToken.vaultCompoundFromNode(_address, totalCompound);
    //     }
    // }

    // function getOwnedNodesInCompounder() external view returns (uint256[] memory) {
    //     return nodesInCompounder[msg.sender];
    // }
}