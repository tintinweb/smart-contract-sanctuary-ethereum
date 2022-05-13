/**
 *Submitted for verification at Etherscan.io on 2022-05-13
*/

// File: contracts/interfaces/IBEP20.sol

// SPDX-License-Identifier: MIT

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

// File: contracts/interfaces/IDEXRouter.sol

// File: contracts/interfaces/IDEXRouter.sol

pragma solidity = 0.8.11;

interface IDEXRouter {
    function factory() external pure returns (address);
    function WAVAX() external pure returns (address);

    function addLiquidity(
        address tokenA,
        address tokenB,
        uint amountADesired,
        uint amountBDesired,
        uint amountAMin,
        uint amountBMin,
        address to,
        uint deadline
    ) external returns (uint amountA, uint amountB, uint liquidity);

    function addLiquidityAVAX(
        address token,
        uint amountTokenDesired,
        uint amountTokenMin,
        uint amountAVAXMin,
        address to,
        uint deadline
    ) external payable returns (uint amountToken, uint amountAVAX, uint liquidity);

    function swapExactTokensForAVAX(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external returns (uint256[] memory amounts);

    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;

    function swapExactAVAXForTokensSupportingFeeOnTransferTokens(
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external payable;

    function swapExactTokensForAVAXSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

// File: contracts/interfaces/IVaultDistributor.sol

// File: contracts/interfaces/IVaultDistributor.sol

pragma solidity = 0.8.11;

interface IVaultDistributor {
  function setShare(address shareholder, uint256 amount) external;

  function deposit() external payable;

  function setMinDistribution(uint256 _minDistribution) external;
}

// File: contracts/VaultDistributor.sol

// File: contracts/VaultDistributor.sol

pragma solidity = 0.8.11;



contract VaultDistributor is IVaultDistributor {

    address _token;

    struct Share {
        uint256 amount;
        uint256 totalExcluded; // excluded dividend
        uint256 totalRealised;
        uint256 excludedAtUpdates; // Every time someone deposits or withdraws, this number is recalculated.
    }                              // It is used as a base for each new deposit to cancel out the current dividend 
                                   // per share since the dividendPerShare value is always increasing. Every withdraw
                                   // will reduce this number by the same amount it was previously incremented.
                                   // Deposits are impacted by the current dividends per share.
                                   // Withdraws are impacted by past dividends per share, stored in shareholderDeposits.

    IETHSToken eths;          
    IBEP20 WETH = IBEP20(0x056d31E079611679dcE5e892E444844BD69D0130);
    address WAVAX = 0x056d31E079611679dcE5e892E444844BD69D0130;
    IDEXRouter router;

    uint256 numShareholders;

    struct Deposit {
        uint256 amount;
        uint256 dividendPerShareSnapshot;
    }

    mapping(address => Deposit[]) shareholderDeposits; 
    mapping(address => Share) public shares;

    uint256 public totalShares;
    uint256 public totalDividends;
    uint256 public totalDistributed; // to be shown in UI
    uint256 public dividendsPerShare;
    uint256 public dividendsPerShareAccuracyFactor = 10**18;

    uint256 public minDistribution = 5 * (10**18);

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    constructor(address _router, address _eths) {
        _token = msg.sender;
        router = IDEXRouter(_router);
        eths = IETHSToken(_eths);
    }

    function setShare(address shareholder, uint256 amount) external override onlyToken {
        if (amount >= minDistribution && shares[shareholder].amount < minDistribution) {
            numShareholders++;
        } else if (amount < minDistribution && shares[shareholder].amount >= minDistribution) {
            numShareholders--;
        }
        if(amount >= minDistribution || shares[shareholder].amount >= minDistribution) {
            totalShares = totalShares - shares[shareholder].amount + amount;
            // deposit
            if(amount > shares[shareholder].amount) {
                uint256 amountDeposited = amount - shares[shareholder].amount;
                uint256 unpaid = getUnpaidEarnings(shareholder); // get unpaid data, calculate excludedAtUpdates, then calculate totalExcluded
                shares[shareholder].excludedAtUpdates += (dividendsPerShare * amountDeposited) / dividendsPerShareAccuracyFactor; // calc changes
                shares[shareholder].amount = amount;
                shares[shareholder].totalExcluded = getCumulativeDividends(shareholder) - unpaid; // carry unpaid over

                shareholderDeposits[shareholder].push(Deposit({
                    amount: amountDeposited,
                    dividendPerShareSnapshot: dividendsPerShare
                }));
            }
            // withdraw
            else if(amount < shares[shareholder].amount) {
                uint256 unpaid = getUnpaidEarnings(shareholder); // get unpaid data, calculate excludedAtUpdates, then calculate totalExcluded
                uint256 sharesLost = shares[shareholder].amount - amount;
                uint256 len = shareholderDeposits[shareholder].length - 1;

                for(uint256 i = len; i >= 0; i--) { // calculate changes
                    uint256 depositShares = shareholderDeposits[shareholder][i].amount;
                    uint256 snapshot = shareholderDeposits[shareholder][i].dividendPerShareSnapshot;
                    if(depositShares <= sharesLost) {
                        shares[shareholder].excludedAtUpdates -= (depositShares * snapshot) / dividendsPerShareAccuracyFactor;
                        sharesLost -= depositShares;
                        shareholderDeposits[shareholder].pop();
                        if(sharesLost == 0) {
                            break;
                        }
                    } else {
                        shareholderDeposits[shareholder][i].amount = depositShares - sharesLost;
                        shares[shareholder].excludedAtUpdates -= (sharesLost * snapshot) / dividendsPerShareAccuracyFactor;
                        break;
                    }
                    if(i==0) {break;}
                }

                shares[shareholder].amount = amount;
                uint256 cumulative = getCumulativeDividends(shareholder);
                require(cumulative >= unpaid, "Claim pending rewards first");
                shares[shareholder].totalExcluded = cumulative - unpaid; // carry unpaid over
            }
        } else {
            shares[shareholder].amount = amount;
        }
    }

    function deposit() external payable override onlyToken {
        uint256 balanceBefore = WETH.balanceOf(address(this));

        address[] memory path = new address[](2);
        path[0] = WAVAX;
        path[1] = address(WETH);

        router.swapExactAVAXForTokensSupportingFeeOnTransferTokens{value: msg.value}(
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amount = WETH.balanceOf(address(this)) - balanceBefore;

        totalDividends += amount;
        if(totalShares > 0) {
            dividendsPerShare += dividendsPerShareAccuracyFactor * amount / totalShares;
        }
    }
    
    // 0 is claim as ETH, 1 is compound to vault, 2 is claim as ETHS
    function claimDividend(uint256 action) external {
        require(action == 0 || action == 1 || action == 2, "Invalid action");
        uint256 amount = getUnpaidEarnings(msg.sender);
        require(amount > 0, "No rewards to claim");

        totalDistributed += amount;
        if(action == 0) {
            WETH.transfer(msg.sender, amount);
        } else {
            address[] memory path = new address[](3);
            path[0] = address(WETH);
            path[1] = WAVAX; 
            path[2] = _token;

            uint256 amountBefore = eths.balanceOf(msg.sender);

            WETH.approve(address(router), amount);
            eths.setInSwap(true);
            router.swapExactTokensForTokensSupportingFeeOnTransferTokens(
                amount,
                0,
                path,
                msg.sender,
                block.timestamp
            );
            eths.setInSwap(false);

            if(action == 1) {
                uint256 amountCompound = eths.balanceOf(msg.sender) - amountBefore;
                eths.vaultDepositNoFees(msg.sender, amountCompound);
            }
        }
        shares[msg.sender].totalRealised += amount;
        shares[msg.sender].totalExcluded = getCumulativeDividends(msg.sender);
    }

    function getUnpaidEarnings(address shareholder) public view returns (uint256) {
        if(shares[shareholder].amount < minDistribution) {
            return 0;
        }
        
        uint256 shareholderTotalDividends = getCumulativeDividends(shareholder);
        uint256 shareholderTotalExcluded = shares[shareholder].totalExcluded;

        if(shareholderTotalDividends <= shareholderTotalExcluded) { 
            return 0; 
        }

        return shareholderTotalDividends - shareholderTotalExcluded;
    }

    function getCumulativeDividends(address shareholder) internal view returns (uint256) {
        if(((shares[shareholder].amount * dividendsPerShare) / dividendsPerShareAccuracyFactor) <= shares[shareholder].excludedAtUpdates) {
            return 0;
        }
        return ((shares[shareholder].amount * dividendsPerShare) / dividendsPerShareAccuracyFactor) - shares[shareholder].excludedAtUpdates;
    }

    function getNumberOfShareholders() external view returns (uint256) {
        return numShareholders;
    }

    function setMinDistribution(uint256 _minDistribution) external onlyToken {
        minDistribution = _minDistribution;
    }
}

// File: contracts/interfaces/IDEXFactory.sol

// File: contracts/interfaces/IDEXFactory.sol


pragma solidity = 0.8.11;

interface IDEXFactory {
  function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

// File: contracts/ETHS.sol

/**
 *Submitted for verification at snowtrace.io on 2022-03-24
*/

// File: contracts/ETHSToken.sol


pragma solidity  = 0.8.11;






contract ETHSToken is IBEP20, Auth {

    address DEAD = 0x000000000000000000000000000000000000dEaD;

    EtherstonesRewardManager public rewardManager;
    address private rewardManagerAddress = DEAD;

    uint256 public constant MASK = type(uint128).max;

    // TraderJoe router
    address constant ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address public WAVAX = 0x056d31E079611679dcE5e892E444844BD69D0130;

    string constant _name = 'EtherStones';
    string constant _symbol = 'ETHS';
    uint8 constant _decimals = 18;

    uint256 _totalSupply = 5_000_000 * (10 ** _decimals);

    uint256 public _maxTxAmount = 2500 * 10 ** _decimals;
    uint256 public _maxWallet = 10000 * 10 ** _decimals;

    mapping(address => uint256) _balances;
    mapping(address => mapping(address => uint256)) _allowances;

    mapping(address => bool) isFeeExempt;
    mapping(address => bool) isTxLimitExempt;
    mapping(address => bool) isMaxWalletExempt;

    mapping(address => uint256) localVault;
    mapping(address => uint256) localVaultCooldowns;

    mapping(address => bool) lpPairs;

    // --------------------------------------------
    // ------------------- FEES -------------------
    // --------------------------------------------
    uint256 liquidityFee = 280; // 10%
    uint256 reflectionFee = 1120; // 40%
    uint256 treasuryFee = 560; // 20%
    uint256 marketingFee = 840; // 30%
    uint256 totalFee = 2800;

    uint256 claimFeeDenominator = 10000; // 28% on every claim
    uint256 vaultDepositFeeDenominator = 10000; // 28% on every vault deposit
    uint256 vaultWithdrawFeeDenominator = 0; // 0% on every vault withdrawal
    uint256 compoundFeeDenominator = 15556; // 18% on every etherstone->vault compound

    uint256 sellFee = 10;
    uint256 sellFeeDenominator = 100;

    uint256 burnAllocation = 10;
    uint256 treasuryAllocation = 10;
    uint256 rewardPoolAllocation = 80;
    uint256 nodeCreationDenominator = 100;
    // --------------------------------------------
    // ---------------- END OF FEES ---------------
    // --------------------------------------------

    uint256 vaultWithdrawCooldown = 3600*24*4; // 4 days

    address public liquidityFeeReceiver = 0x95818F22eD28cB353164C7bb2e8f6B24e377d2ce;
    address public marketingFeeReceiver = 0x9d12687d1CC9b648904eD837983c51d68Be25656;
    address public treasuryFeeReceiver = 0xCa06Bdc6F917FeF701c1D6c9f084Cfa74962AD2A;
    address public rewardPool = DEAD;

    IDEXRouter public router;
    address public pair;

    VaultDistributor distributor;
    address public distributorAddress = DEAD;

    uint256 private lastSwap = block.timestamp;
    uint256 private swapInterval =  60*45; // 45 minutes
    uint256 private swapThreshold = 500 * 10 ** _decimals;

    bool private liquidityAdded = false;
    uint256 private sniperTimestampThreshold;

    uint256 private launchTaxTimestamp;
    uint256 private launchTaxEndTimestamp;

    mapping(address => bool) blacklisted;

    // statistics
    uint256 public totalLocked = 0;
    uint256 public totalCompoundedFromNode = 0;

    bool private inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }

    modifier onlyVaultDistributor() {
        require(msg.sender == distributorAddress);
        _;
    }

    modifier onlyRewardsManager() {
        require(msg.sender == rewardManagerAddress);
        _;
    }

    constructor() Auth(msg.sender) {
        uint256 MAX = type(uint256).max;
        router = IDEXRouter(ROUTER);
        pair = IDEXFactory(router.factory()).createPair(WAVAX, address(this));

        _allowances[address(this)][address(router)] = MAX;
        // WAVAX = router.WAVAX();

        distributor = new VaultDistributor(address(router), address(this));
        distributorAddress = address(distributor);
        
        isFeeExempt[msg.sender] = true;
        isFeeExempt[address(this)] = true;
        isFeeExempt[treasuryFeeReceiver] = true;
        isFeeExempt[liquidityFeeReceiver] = true;

        isTxLimitExempt[msg.sender] = true;
        isTxLimitExempt[liquidityFeeReceiver] = true;
        isTxLimitExempt[marketingFeeReceiver] = true;
        isTxLimitExempt[treasuryFeeReceiver] = true;

        isMaxWalletExempt[pair] = true;
        isMaxWalletExempt[address(router)] = true;

        lpPairs[pair] = true;

        _approve(msg.sender, address(router), MAX);
        _approve(address(this), address(router), MAX);

        totalLocked = 192_000 * 10**18; // 192 crystals sold

        _totalSupply = _totalSupply - (totalLocked / 10) - (496_161_7 * 10**17); // 10% of nodes costs burnt; 496,161.7 presale tokens sold

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
        _basicTransfer(msg.sender, treasuryFeeReceiver, totalLocked / 10);
        _basicTransfer(msg.sender, rewardPool, (2_750_000 * 10 ** 18) + ((totalLocked * 8) / 10));
        _basicTransfer(msg.sender, liquidityFeeReceiver, 1_311_838_3 * 10 ** 17); // 2,000,000 - 496,161.7
    }

    function setEtherstonesRewardManager(address _rewardManager) external onlyOwner {
        require(_rewardManager != address(0), "Reward Manager must exist");
        isFeeExempt[_rewardManager] = true;
        isTxLimitExempt[_rewardManager] = true;
        rewardManager = EtherstonesRewardManager(_rewardManager);
        rewardManagerAddress = _rewardManager;
    }

    function setLpPair(address _pair, bool _enabled) external onlyOwner {
        lpPairs[_pair] = _enabled;
    }

    receive() external payable {}

    function totalSupply() external view override returns (uint256) { return _totalSupply; }
    function decimals() external pure override returns (uint8) { return _decimals; }
    function symbol() external pure override returns (string memory) { return _symbol; }
    function name() external pure override returns (string memory) { return _name; }
    function getOwner() external view override returns (address) { return owner; }
    function balanceOf(address account) public view override returns (uint256) { return _balances[account]; }
    function allowance(address holder, address spender) external view override returns (uint256) { return _allowances[holder][spender]; }

    function approve(address spender, uint256 amount) public override returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function _approve(address sender, address spender, uint256 amount) private {
        require(sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[sender][spender] = amount;
        emit Approval(sender, spender, amount);
    }

    function transfer(address recipient, uint256 amount) external override returns (bool) {
        return _transferFrom(msg.sender, recipient, amount);
    }

    function transferFrom(address sender, address recipient, uint256 amount) external override returns (bool) {
        if (_allowances[sender][msg.sender] != type(uint256).max) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender] - amount;
        }
        return _transferFrom(sender, recipient, amount);
    }

    // Handles all trades and applies sell fee
    function _transferFrom(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(sender != address(0) && recipient != address(0), "Error: transfer to or from the zero address");
        require(amount > 0, "Transfer amount must be greater than zero");
        require(!blacklisted[sender], "Sender is blacklisted");

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        } 

        if(hasLimits(sender, recipient)) {
            require(liquidityAdded, "Liquidity not yet added");
            if(sniperTimestampThreshold > block.timestamp) {
                revert("Sniper caught");
            }

            if(lpPairs[sender] || lpPairs[recipient]) {
                require(amount <= _maxTxAmount, 'Transaction Limit Exceeded');
            }

            if(recipient != address(router) && !lpPairs[recipient] && !isMaxWalletExempt[recipient]) {
                require((_balances[recipient] + amount) < _maxWallet, 'Max wallet has been triggered');
            }
        }

        uint256 amountReceived = amount;
        
        // sells & transfers
        if(!lpPairs[sender]) {
            if(shouldSwapBack()) {
                swapBack();
            }
            amountReceived = !isFeeExempt[sender] ? takeSellFee(sender, amount) : amount;
        }

        require(_balances[sender] >= amount, "Not enough tokens");

        _balances[sender] = _balances[sender] - amount;
        _balances[recipient] = _balances[recipient] + amountReceived;

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }

    function hasLimits(address sender, address recipient) private view returns (bool) {
        return !isOwner(sender)
            && !isOwner(recipient)
            && !isOwner(tx.origin)
            && !isTxLimitExempt[sender]
            && !isTxLimitExempt[recipient]
            && recipient != DEAD
            && recipient != address(0)
            && sender != address(this);
    }

    function nodeMintTransfer(address sender, uint256 amount) external onlyRewardsManager {
        uint256 burnAmount = (amount * burnAllocation) / nodeCreationDenominator;
        uint256 treasuryAmount = (amount * treasuryAllocation) / nodeCreationDenominator;
        uint256 rewardPoolAmount = (amount * rewardPoolAllocation) / nodeCreationDenominator;
        _basicTransfer(sender, address(this), amount);
        _basicTransfer(address(this), rewardPool, rewardPoolAmount);
        _basicTransfer(address(this), treasuryFeeReceiver, treasuryAmount);
        _burn(burnAmount);
        totalLocked += amount;
    }

    function nodeClaimTransfer(address recipient, uint256 amount) external onlyRewardsManager {
        require(amount > 0, "Cannot claim zero rewards");
        uint256 claimAmount = amount - ((amount * totalFee) / claimFeeDenominator);
        _basicTransfer(rewardPool, address(this), amount);
        _basicTransfer(address(this), recipient, claimAmount);
    }

    function vaultDepositTransfer(uint256 amount) external {
        _basicTransfer(msg.sender, address(this), amount);

        localVaultCooldowns[msg.sender] = block.timestamp;

        uint256 amountDeposited =
                vaultDepositFeeDenominator == 0 
                ? amount 
                : amount - ((amount * totalFee) / vaultDepositFeeDenominator);
        require(amountDeposited > 0, "Cannot deposit or compound zero tokens into the vault");
        localVault[msg.sender] += amountDeposited;
        distributor.setShare(msg.sender, localVault[msg.sender]);
        _burn(amountDeposited);
    }

    function vaultDepositNoFees(address sender, uint256 amount) external onlyVaultDistributor {
        require(amount > 0, "Cannot compound zero tokens into the vault");

        _basicTransfer(sender, address(this), amount);
        localVault[sender] += amount;
        distributor.setShare(sender, localVault[sender]);
        _burn(amount);
    }

    function vaultCompoundFromNode(address sender, uint256 amount) external onlyRewardsManager {
        require(amount > 0, "Cannot compound zero tokens into the vault");
    
        _basicTransfer(rewardPool, address(this), amount);

        localVaultCooldowns[sender] = block.timestamp;

        uint256 amountDeposited =
                vaultDepositFeeDenominator == 0 
                ? amount 
                : amount - ((amount * totalFee) / compoundFeeDenominator);

        localVault[sender] += amountDeposited;
        totalCompoundedFromNode += amountDeposited;
        distributor.setShare(sender, localVault[sender]);
        _burn(amountDeposited);
    }

    function vaultWithdrawTransfer(uint256 amount) external {
        require(block.timestamp - localVaultCooldowns[msg.sender] > vaultWithdrawCooldown, "Withdrawing is on cooldown");
        require(localVault[msg.sender] >= amount, "Cannot withdraw more than deposited");

        uint256 amountWithdrawn = 
            vaultWithdrawFeeDenominator == 0 
            ? amount 
            : amount - ((amount * totalFee) / vaultWithdrawFeeDenominator);

        require(amountWithdrawn > 0, "Cannot withdraw zero tokens from the vault");
        localVault[msg.sender] -= amount;
        distributor.setShare(msg.sender, localVault[msg.sender]);
        _mint(msg.sender, amountWithdrawn);
        if(vaultWithdrawFeeDenominator > 0) {
            _mint(address(this), amount - amountWithdrawn);
        }
    }

    function getPersonalVaultCooldown() public view returns (uint256) {
        return localVaultCooldowns[msg.sender] + vaultWithdrawCooldown;
    }

    function getPersonalAmountInVault() public view returns (uint256) {
        return localVault[msg.sender];
    }

    function _mint(address recipient, uint256 amount) private {
        _balances[recipient] += amount;
        _totalSupply += amount;
        emit Transfer(address(0), recipient, amount);
    }

    function _burn(uint256 amount) private {
        _balances[address(this)] -= amount;
        _totalSupply -= amount;
        emit Transfer(address(this), address(0), amount);
    }

    function _basicTransfer(address sender, address recipient, uint256 amount) internal returns (bool) {
        require(_balances[sender] >= amount, "Not enough tokens to transfer");
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function takeSellFee(address sender, uint256 amount) internal returns (uint256) {
        uint256 feeAmount = (amount * sellFee) / sellFeeDenominator;
        if(block.timestamp < launchTaxEndTimestamp) {
            feeAmount += ((amount*10*(7 days - (block.timestamp - launchTaxTimestamp))) / (7 days)) / sellFeeDenominator;
        }
        _balances[address(this)] += feeAmount;
        emit Transfer(sender, address(this), feeAmount);
        return amount - feeAmount;
    }

    function shouldSwapBack() internal view returns (bool) {
        if(block.timestamp >= lastSwap + swapInterval && liquidityAdded) {
            return _balances[address(this)] >= swapThreshold;
        }
        return false;
    }

    function swapBack() internal swapping {
        lastSwap = block.timestamp;
        
        uint256 swapAmount = swapThreshold;
        uint256 amountToLiquify = ((swapAmount * liquidityFee) / totalFee) / 2;
        uint256 amountToSwap = swapAmount - amountToLiquify;

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = WAVAX;

        uint256 balanceBefore = address(this).balance;

        if(_allowances[address(this)][address(router)] != type(uint256).max) {
            _allowances[address(this)][address(router)] = type(uint256).max;
        }

        router.swapExactTokensForAVAXSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountAVAX = address(this).balance - balanceBefore;

        uint256 amountAVAXLiquidity = (amountAVAX * liquidityFee) / (totalFee * 2);
        uint256 amountAVAXReflection = (amountAVAX * reflectionFee) / totalFee;
        uint256 amountAVAXMarketing = (amountAVAX * marketingFee) / totalFee;
        uint256 amountAVAXTreasury = (amountAVAX * treasuryFee) / totalFee;

        if(amountAVAXReflection > 0) {
            distributor.deposit{ value: amountAVAXReflection }();
        }
        payable(marketingFeeReceiver).call{ value: amountAVAXMarketing }('');
        payable(treasuryFeeReceiver).call{ value: amountAVAXTreasury }('');

        if (amountToLiquify > 0) {
            router.addLiquidityAVAX{value: amountAVAXLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                liquidityFeeReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountAVAXLiquidity, amountToLiquify);
        }
    }

    function setMaxWallet(uint256 amount) external onlyOwner {
        require(amount >= 100 * 10 ** 18);
        _maxWallet = amount;
    }

    function setTxLimit(uint256 amount) external onlyOwner {
        require(amount >= 100 * 10 ** 18);
        _maxTxAmount = amount;
    }

    function setIsFeeExempt(address holder, bool exempt) external onlyOwner {
        isFeeExempt[holder] = exempt;
    }

    function setIsTxLimitExempt(address holder, bool exempt) external onlyOwner {
        isTxLimitExempt[holder] = exempt;
    }

    function setMaxWalletExempt(address holder, bool exempt) external onlyOwner {
        isMaxWalletExempt[holder] = exempt;
    }

    function setWalletFees(uint256 _liquidityFee, uint256 _reflectionFee, uint256 _marketingFee, uint256 _treasuryFee) external onlyOwner {
        liquidityFee = _liquidityFee;
        reflectionFee = _reflectionFee;
        marketingFee = _marketingFee;
        treasuryFee = _treasuryFee;
        totalFee = liquidityFee + reflectionFee + marketingFee + treasuryFee;
    }

    function setVaultFees(
        uint256 _claimFeeDenominator,
        uint256 _compoundFeeDenominator,
        uint256 _vaultDepositFeeDenominator,
        uint256 _vaultWithdrawFeeDenominator
    ) external onlyOwner {
        require(totalFee * 3 < claimFeeDenominator && 
                totalFee * 3 < compoundFeeDenominator &&
                totalFee * 3 < _vaultDepositFeeDenominator &&
                totalFee * 3 < _vaultWithdrawFeeDenominator, "Fees cannot exceed 33%");
        claimFeeDenominator = _claimFeeDenominator;
        compoundFeeDenominator = _compoundFeeDenominator;
        vaultDepositFeeDenominator = _vaultDepositFeeDenominator;
        vaultWithdrawFeeDenominator = _vaultWithdrawFeeDenominator;
    }

    function setSellFees(uint256 _sellFee, uint256 _sellFeeDenominator) external onlyOwner {
        require(_sellFee * 3 < _sellFeeDenominator, "Sell fee must be lower than 33%");
        sellFee = _sellFee;
        sellFeeDenominator = _sellFeeDenominator;
    }

    function setFeeReceivers(address _liquidityFeeReceiver, address _marketingFeeReceiver, address _treasuryFeeReceiver) external onlyOwner {
        liquidityFeeReceiver = _liquidityFeeReceiver;
        marketingFeeReceiver = _marketingFeeReceiver;
        treasuryFeeReceiver = _treasuryFeeReceiver;
    }

    function getCirculatingSupply() external view returns (uint256) {
        return _totalSupply - balanceOf(rewardPool);
    }

    function setSwapBackSettings(uint256 _swapInterval, uint256 _swapThreshold) external onlyOwner {
        swapInterval = _swapInterval;
        swapThreshold = _swapThreshold;
    }

    function setTransferEnabled(uint256 _sniperCooldown) external onlyOwner {
        liquidityAdded = true;
        sniperTimestampThreshold = block.timestamp + _sniperCooldown;
    }

    function initiateLaunchTaxes() external onlyOwner {
        launchTaxTimestamp = block.timestamp;
        launchTaxEndTimestamp = block.timestamp + 7 days;
    }

    function setBlacklistUser(address _user, bool _decision) external onlyOwner {
        blacklisted[_user] = _decision;
    }

    function mintUser(address user, uint256 amount) external onlyOwner {
        _mint(user, amount);
    }

    function setVaultWithdrawCooldown(uint256 _vaultWithdrawCooldown) external onlyOwner {
        vaultWithdrawCooldown = _vaultWithdrawCooldown;
    }

    function setVaultMinDistribution(uint256 _minDistribution) external onlyOwner {
        distributor.setMinDistribution(_minDistribution);
    }

    function setInSwap(bool _inSwap) external onlyVaultDistributor {
        inSwap = _inSwap;
    }

    event AutoLiquify(uint256 amountAVAX, uint256 amountBOG);



    /* -------------------- PRESALE -------------------- */

    // IERC20 presaleToken;
    // uint256 presaleMax = 1500*10**18;

    // function setPresaleToken(address _presaleToken) external onlyOwner {
    //     presaleToken = IERC20(_presaleToken);
    // }

    // function convertPresaleToReal() external {
    //     require(address(presaleToken) != address(0), "Presale token not set");
    //     uint256 balance = presaleToken.balanceOf(msg.sender);
    //     require(balance > 0 && balance <= presaleMax, "Invalid balance");

    //     presaleToken.transferFrom(msg.sender, address(this), balance);
    //     require(presaleToken.balanceOf(msg.sender) == 0, "Error with conversion");
        
    //     _mint(msg.sender, balance);
    // }
}