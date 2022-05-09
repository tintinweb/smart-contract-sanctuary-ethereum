//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { InitializableOwnable } from "./interfaces/InitializableOwnable.sol";
import { IWhitelist } from "./interfaces/IWhitelist.sol";

interface NFTContract {
    function balanceOf(address account) external view returns (uint256);
}

contract WhitelistWithNFT is InitializableOwnable, IWhitelist {

    address[] whitelistedNFTs;
    mapping(address => uint) nftCollectionAllowance;
    mapping(address => bool) whitelistActivated;
    mapping(address => uint) whitelist;

    /* ========== VIEWS ========== */

    function isWhitelisted(address user) external view returns(bool) {
        if (whitelist[user] > 0) {
            return true;
        } else if (!whitelistActivated[user]) {
            for (uint i = 0; i < whitelistedNFTs.length; i++) {
                if (NFTContract(whitelistedNFTs[i]).balanceOf(user) > 0) {
                    return true;
                }
            }
        }
        return false;
    }

    function allowedAllocation(address user) external view returns(uint) {
        if (whitelist[user] > 0) {
            return whitelist[user];
        } else if (!whitelistActivated[user]) {
            uint allocation = 0;
            for (uint i = 0; i < whitelistedNFTs.length; i++) {
                address collectionAddress = whitelistedNFTs[i];
                NFTContract nft = NFTContract(whitelistedNFTs[i]);
                if (nft.balanceOf(user) > 0) {
                    uint collectionAllocation = nftCollectionAllowance[collectionAddress];
                    allocation = collectionAllocation > allocation ? collectionAllocation : allocation;
                }
            }
            return allocation;
        }
        return 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function addCollection(address collection) external onlyOwner {
        whitelistedNFTs.push(collection);
    }

    function removeCollection(address collection) external onlyOwner {
    }

    function updateCollectionAllocation(address collection, uint allocation) external onlyOwner {
        nftCollectionAllowance[collection] = allocation;
    }

    function updateAllocation(address user, uint allocation) external onlyOwner {
        whitelist[user] = allocation;
        whitelistActivated[user] = true;
    }
}

// SPDX-License-Identifier: Apache-2.0

pragma solidity 0.8.13;

contract InitializableOwnable {

    address public owner;
    address public newOwner;

    bool internal initialized;

    // ============ Events ============

    event OwnerTransferRequested(
        address indexed oldOwner, 
        address indexed newOwner
    );

    event OwnershipTransferred(
        address indexed oldOwner, 
        address indexed newOwner
    );

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

    /* ========== MODIFIERS ========== */

    modifier notInitialized() {
        require(!initialized, "Not initialized");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IWhitelist {
    function isWhitelisted(address user) external returns(bool);
    function allowedAllocation(address user) external returns(uint);
    function updateAllocation(address user, uint allocation) external;
}