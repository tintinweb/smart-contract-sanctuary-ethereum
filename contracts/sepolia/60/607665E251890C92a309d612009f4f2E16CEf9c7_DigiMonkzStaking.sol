// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

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
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IGenesis111.sol";
import "./interface/IGenesis2.sol";

contract DigiMonkzStaking is Ownable {
    Genesis111 public genesis111;
    Genesis2 public genesis2;

    uint256 period = 30 days;

    struct NftInfo {
        uint16 tokenId;
        uint256 stakedAt;
        uint256 lastClaimedAt;
        uint256 artifact;
    }
    mapping(uint16 => uint256) public artifactPerGen1Nft;
    mapping(uint16 => uint256) public artifactPerGen2Nft;
    mapping(address => uint256) public artifactPerStaker;
    mapping(address => NftInfo[]) public gen1InfoPerStaker;
    mapping(address => NftInfo[]) public gen2InfoPerStaker;

    event Stake(uint256 indexed tokenId);
    event Unstake(
        uint256 indexed tokenId,
        uint256 stakedAtTimestamp,
        uint256 removedFromStakeAtTimestamp
    );

    constructor(address _gen1Addr, address _gen2Addr) {
        genesis111 = Genesis111(_gen1Addr);
        genesis2 = Genesis2(_gen2Addr);
    }

    function gen1Stake(uint16 _tokenId) external returns (bool) {
        require(genesis111.ownerOf(_tokenId) == msg.sender);

        uint256 len = gen1InfoPerStaker[msg.sender].length;
        bool flag;
        for (uint256 i = 0; i < len; i++) {
            if (gen1InfoPerStaker[msg.sender][i].tokenId == _tokenId) {
                flag = true;
            }
        }
        require(flag == false);

        uint256 artifact = artifactPerGen1Nft[_tokenId];
        NftInfo memory stakingNft = NftInfo(
            _tokenId,
            block.timestamp,
            0,
            artifact
        );
        gen1InfoPerStaker[msg.sender].push(stakingNft);

        emit Stake(_tokenId);

        return true;
    }

    function gen2Stake(uint16 _tokenId) external returns (bool) {
        require(genesis2.ownerOf(_tokenId) == msg.sender);

        uint256 len = gen2InfoPerStaker[msg.sender].length;
        bool flag;
        for (uint256 i = 0; i < len; i++) {
            if (gen2InfoPerStaker[msg.sender][i].tokenId == _tokenId) {
                flag = true;
            }
        }
        require(flag == false);

        uint256 artifact = artifactPerGen2Nft[_tokenId];
        NftInfo memory stakingNft = NftInfo(
            _tokenId,
            block.timestamp,
            0,
            artifact
        );
        gen2InfoPerStaker[msg.sender].push(stakingNft);

        emit Stake(_tokenId);

        return true;
    }

    function gen1Unstake(uint16 _tokenId) external returns (bool) {
        require(genesis111.ownerOf(_tokenId) == msg.sender);

        uint256 len = gen1InfoPerStaker[msg.sender].length;
        require(len != 0);

        uint256 idx = len;
        for (uint256 i = 0; i < len; i++) {
            if (gen1InfoPerStaker[msg.sender][i].tokenId == _tokenId) {
                idx = i;
            }
        }
        require(idx != len);

        uint256 stakedTime = gen1InfoPerStaker[msg.sender][idx].stakedAt;
        if (idx != len - 1) {
            gen1InfoPerStaker[msg.sender][idx] = gen1InfoPerStaker[msg.sender][
                len - 1
            ];
        }
        gen1InfoPerStaker[msg.sender].pop();

        emit Unstake(_tokenId, stakedTime, block.timestamp);

        return true;
    }

    function gen2Unstake(uint16 _tokenId) external returns (bool) {
        require(genesis2.ownerOf(_tokenId) == msg.sender);

        uint256 len = gen2InfoPerStaker[msg.sender].length;
        require(len != 0);

        uint256 idx = len;
        for (uint256 i = 0; i < len; i++) {
            if (gen2InfoPerStaker[msg.sender][i].tokenId == _tokenId) {
                idx = i;
            }
        }
        require(idx != len);

        uint256 stakedTime = gen2InfoPerStaker[msg.sender][idx].stakedAt;
        if (idx != len - 1) {
            gen2InfoPerStaker[msg.sender][idx] = gen2InfoPerStaker[msg.sender][
                len - 1
            ];
        }
        gen2InfoPerStaker[msg.sender].pop();

        emit Unstake(_tokenId, stakedTime, block.timestamp);

        return true;
    }

    function getArtifactForGen1(uint16 _tokenId) public returns (uint256) {
        require(genesis111.ownerOf(_tokenId) == msg.sender);

        uint256 stakedTime;
        uint256 lastClaimedTime;
        uint256 idx;
        uint256 len = gen1InfoPerStaker[msg.sender].length;
        for (uint256 i = 0; i < len; i++) {
            if (gen1InfoPerStaker[msg.sender][i].tokenId == _tokenId) {
                stakedTime = gen1InfoPerStaker[msg.sender][i].stakedAt;
                lastClaimedTime = gen1InfoPerStaker[msg.sender][i]
                    .lastClaimedAt;
                idx = i;
                break;
            }
        }
        require(stakedTime != 0);

        uint256 numMonth;
        uint256 artifact;
        uint256 currentTime = block.timestamp;

        if (lastClaimedTime >= stakedTime) {
            numMonth =
                ((currentTime - stakedTime) / 30 days) -
                ((lastClaimedTime - stakedTime) / 30 days);
        } else {
            numMonth = (currentTime - stakedTime) / 30 days;
        }
        require(numMonth > 0);

        if (_tokenId >= 0 && _tokenId <= 10) {
            artifact = 25 * numMonth;
        } else if (_tokenId >= 11 && _tokenId <= 111) {
            artifact = 20 * numMonth;
        }

        artifactPerGen1Nft[_tokenId] += artifact;
        gen1InfoPerStaker[msg.sender][idx].lastClaimedAt = currentTime;
        gen1InfoPerStaker[msg.sender][idx].artifact += artifact;
        artifactPerStaker[msg.sender] += artifact;

        return artifact;
    }

    function getArtifactForGen2(uint16 _tokenId) public returns (uint256) {
        require(genesis2.ownerOf(_tokenId) == msg.sender);

        uint256 stakedTime;
        uint256 lastClaimedTime;
        uint256 idx;
        uint256 len = gen2InfoPerStaker[msg.sender].length;
        for (uint256 i = 0; i < len; i++) {
            if (gen2InfoPerStaker[msg.sender][i].tokenId == _tokenId) {
                stakedTime = gen2InfoPerStaker[msg.sender][i].stakedAt;
                lastClaimedTime = gen2InfoPerStaker[msg.sender][i]
                    .lastClaimedAt;
                idx = i;
                break;
            }
        }
        require(stakedTime != 0);

        uint256 numMonth;
        uint256 artifact;
        uint256 currentTime = block.timestamp;

        if (lastClaimedTime >= stakedTime) {
            numMonth =
                ((currentTime - stakedTime) / 30 days) -
                ((lastClaimedTime - stakedTime) / 30 days);
        } else {
            numMonth = (currentTime - stakedTime) / 30 days;
        }
        require(numMonth > 0);

        if (_tokenId >= 1 && _tokenId <= 11) {
            artifact = 15 * numMonth;
        } else {
            artifact = 10 * numMonth;
        }

        artifactPerGen2Nft[_tokenId] += artifact;
        gen2InfoPerStaker[msg.sender][idx].lastClaimedAt = currentTime;
        gen2InfoPerStaker[msg.sender][idx].artifact += artifact;
        artifactPerStaker[msg.sender] += artifact;

        return artifact;
    }

    function claimRewardWithGen1(
        uint256 _numArtifact,
        uint16[] memory _idxArray
    ) external returns (bool) {
        require(artifactPerStaker[msg.sender] >= _numArtifact);

        uint256 sum;
        uint256 len = _idxArray.length;
        uint16 tokenId;
        for (uint256 i = 0; i < len; i++) {
            tokenId = gen1InfoPerStaker[msg.sender][_idxArray[i]].tokenId;
            require(genesis111.ownerOf(tokenId) == msg.sender);
            sum += artifactPerGen1Nft[tokenId];
            artifactPerGen1Nft[tokenId] = 0;
            gen1InfoPerStaker[msg.sender][_idxArray[i]].artifact = 0;
        }
        require(sum >= _numArtifact);

        artifactPerStaker[msg.sender] -= sum;

        return true;
    }

    function claimRewardWithGen2(
        uint256 _numArtifact,
        uint16[] memory _idxArray
    ) external returns (bool) {
        require(artifactPerStaker[msg.sender] >= _numArtifact);

        uint256 sum;
        uint256 len = _idxArray.length;
        uint16 tokenId;
        for (uint256 i = 0; i < len; i++) {
            tokenId = gen2InfoPerStaker[msg.sender][_idxArray[i]].tokenId;
            require(genesis2.ownerOf(tokenId) == msg.sender);
            sum += artifactPerGen2Nft[tokenId];
            artifactPerGen2Nft[tokenId] = 0;
            gen2InfoPerStaker[msg.sender][_idxArray[i]].artifact = 0;
        }
        require(sum >= _numArtifact);

        artifactPerStaker[msg.sender] -= sum;

        return true;
    }

    function getGen1StakedArray(
        address _wallet
    ) external view returns (NftInfo[] memory) {
        NftInfo[] memory nftInfo;
        nftInfo = gen1InfoPerStaker[_wallet];
        return nftInfo;
    }

    function getGen2StakedArray(
        address _wallet
    ) external view returns (NftInfo[] memory) {
        NftInfo[] memory nftInfo;
        nftInfo = gen2InfoPerStaker[_wallet];
        return nftInfo;
    }

    function changePeriod(uint256 _period) public onlyOwner returns (uint256) {
        period = _period;

        return period;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface Genesis2 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface Genesis111 {
    function ownerOf(uint256 tokenId) external view returns (address owner);
}