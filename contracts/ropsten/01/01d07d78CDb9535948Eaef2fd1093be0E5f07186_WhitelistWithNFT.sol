//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { InitializableOwnable } from "./interfaces/InitializableOwnable.sol";
import { IWhitelist } from "./interfaces/IWhitelist.sol";

interface ContractWithBalance {
    function balanceOf(address account) external view returns (uint256);
}

contract WhitelistWithNFT is InitializableOwnable, IWhitelist {

    /* ========== STATE VARIABLES ========== */

    address[] public nfts;
    mapping(address => uint) public nftAllocations;

    address[] public tokens;
    mapping(address => uint) public tokenAllocations;
    mapping(address => uint) public tokenThresholds;

    mapping(address => bool) whitelistActivated;
    mapping(address => uint) userAllocations;

    uint8 maxReferrals = 2;
    mapping(address => uint8) referralsCount;

    constructor(
        address[] memory nfts_,
        uint[] memory nftAllocations_,
        address[] memory tokens_,
        uint[] memory tokenAllocations_,
        uint[] memory tokenThresholds_
    ) {
        require(nfts_.length == nftAllocations_.length, "Corrupt nft data");
        require(tokens_.length == tokenAllocations_.length && 
                tokens_.length == tokenThresholds_.length, "Corrupt token data");
        initOwner(msg.sender);
        nfts = nfts_;
        for (uint i = 0; i < nfts_.length; i++) {
            nftAllocations[nfts_[i]] = nftAllocations_[i];
        }
        tokens = tokens_;
        for (uint i = 0; i < tokens_.length; i++) {
            tokenAllocations[tokens_[i]] = tokenAllocations_[i];
            tokenThresholds[tokens_[i]] = tokenThresholds_[i];
        }
    }

    /* ========== VIEWS ========== */

    function isWhitelisted(address user) external view returns(bool) {
        if (userAllocations[user] > 0) {
            return true;
        } else if (!whitelistActivated[user]) {
            for (uint i = 0; i < nfts.length; i++) {
                if (ContractWithBalance(nfts[i]).balanceOf(user) > 0) {
                    return true;
                }
            }
            for (uint i = 0; i < tokens.length; i++) {
                address token = tokens[i];
                if (ContractWithBalance(token).balanceOf(user) > tokenThresholds[token]) {
                    return true;
                }
            }
        }
        return false;
    }

    function allowedAllocation(address user) public view returns(uint) {
        if (userAllocations[user] > 0) {
            return userAllocations[user];
        } else if (!whitelistActivated[user]) {
            uint allocation = 0;
            for (uint i = 0; i < nfts.length; i++) {
                address collectionAddress = nfts[i];
                ContractWithBalance nft = ContractWithBalance(nfts[i]);
                if (nft.balanceOf(user) > 0) {
                    uint collectionAllocation = nftAllocations[collectionAddress];
                    allocation = collectionAllocation > allocation ? collectionAllocation : allocation;
                }
            }
            for (uint i = 0; i < tokens.length; i++) {
                address tokenAddress = tokens[i];
                ContractWithBalance token = ContractWithBalance(tokens[i]);
                if (token.balanceOf(user) > tokenThresholds[tokenAddress]) {
                    uint tokenAllocation = tokenAllocations[tokenAddress];
                    allocation = tokenAllocation > allocation ? tokenAllocation : allocation;
                }
            }
            return allocation;
        }
        return 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function addCollection(address collection, uint allocation) external onlyOwner {
        nfts.push(collection);
        nftAllocations[collection] = allocation;
        emit CollectionAdded(collection, allocation);
    }

    function removeCollection(address collection) external onlyOwner {
        for (uint i = 0; i < nfts.length; i++) {
            if (nfts[i] == collection) {
                nfts[i] = nfts[nfts.length-1];
                nfts.pop();
                nftAllocations[collection] = 0;
                emit CollectionRemoved(collection);
                break;
            }
        }
    }

    function updateCollectionAllocation(address collection, uint allocation) external onlyOwner {
        nftAllocations[collection] = allocation;
        emit CollectionAllocationUpdated(collection, allocation);
    }

    function addToken(address token, uint allocation, uint threshold) external onlyOwner {
        tokens.push(token);
        tokenAllocations[token] = allocation;
        tokenThresholds[token] = threshold;
        emit TokenAdded(token, allocation, threshold);
    }

    function removeToken(address token) external onlyOwner {
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                tokens[i] = tokens[tokens.length-1];
                tokens.pop();
                tokenAllocations[token] = 0;
                tokenThresholds[token] = 0;
                emit TokenRemoved(token);
                break;
            }
        }
    }

    function updateTokenAllocationAndThreshold(
        address token, 
        uint allocation,
        uint threshold
    ) external onlyOwner {
        tokenAllocations[token] = allocation;
        tokenThresholds[token] = threshold;
        emit TokenAllocationAndThresholdUpdated(token, allocation, threshold);
    }

    function updateAllocation(address user, uint allocation) external onlyAdminOrOwner {
        updateUserAllocation(user, allocation);
    }

    function updateUserAllocation(address user, uint allocation) internal {
        userAllocations[user] = allocation;
        whitelistActivated[user] = true;
        emit UserAllocationUpdated(user, allocation);
    }

    function setMaxReferrals(uint8 maxReferrals_) external {
        maxReferrals = maxReferrals_;
        emit MaxReferralsUpdated(maxReferrals_);
    }

    function referFriend(address user) external {
        uint referrerAllocation;
        uint userAllocation = userAllocations[user];
        if (userAllocation > 0) {
            referrerAllocation = userAllocation;
        } else {
            referrerAllocation = allowedAllocation(msg.sender);
        }
        require(referrerAllocation > 0, "You are not whitelisted");
        require(referralsCount[msg.sender] < maxReferrals, "Too many referrals");
        uint newAllocation = referrerAllocation / 2;
        referralsCount[msg.sender] += 1;
        updateUserAllocation(user, newAllocation);
        emit Referral(msg.sender, user, newAllocation);
    }

    /* ========== EVENTS ========== */

    event CollectionAdded(
        address indexed collection, 
        uint indexed allocation
    );
    event CollectionRemoved(
        address indexed collection
    );
    event CollectionAllocationUpdated(
        address indexed collection,
        uint indexed allocation
    );

    event TokenAdded(
        address indexed token, 
        uint indexed allocation, 
        uint indexed threshold
    );
    event TokenRemoved(
        address indexed token
    );
    event TokenAllocationAndThresholdUpdated(
        address indexed token, 
        uint indexed allocation, 
        uint indexed threshold
    );

    event MaxReferralsUpdated(
        uint8 value
    );
    event Referral(
        address indexed referrer, 
        address indexed friend, 
        uint indexed allocation
    );

    event UserAllocationUpdated(
        address indexed user, 
        uint indexed allocation
    );
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

contract InitializableOwnable {

    address public owner;
    address public newOwner;
    mapping(address => bool) admins;

    bool internal initialized;

    /* ========== MUTATIVE FUNCTIONS ========== */

    function initOwner(address _newOwner) public notInitialized {
        initialized = true;
        owner = _newOwner;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        emit OwnerTransferRequested(owner, _newOwner);
        newOwner = _newOwner;
    }

    function claimOwnership() public {
        require(msg.sender == newOwner, "Claim from wrong address");
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }

    function addAdmin(address user) public onlyOwner {
        emit AdminAdded(user);
        admins[user] = true;
    }

    function removeAdmin(address user) public onlyOwner {
        emit AdminRemoved(user);
        admins[user] = false;
    }

    /* ========== MODIFIERS ========== */

    modifier notInitialized() {
        require(!initialized, "Not initialized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAdminOrOwner() {
        require(admins[msg.sender] || owner == msg.sender, "Not admin or owner");
        _;
    }

    /* ========== EVENTS ========== */

    event OwnerTransferRequested(
        address indexed oldOwner, 
        address indexed newOwner
    );

    event OwnershipTransferred(
        address indexed oldOwner, 
        address indexed newOwner
    );

    event AdminAdded(address indexed admin);
    event AdminRemoved(address indexed admin);
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IWhitelist {
    function isWhitelisted(address user) external returns(bool);
    function allowedAllocation(address user) external returns(uint);
    function updateAllocation(address user, uint allocation) external;
}