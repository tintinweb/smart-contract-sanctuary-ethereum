// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
//TODO: remove when deploying
// import "hardhat/console.sol";

import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

struct StakingOptionsData {
    bool exists;
    bool active;
    uint pointsIssued;
    uint votesIssued;
    address vaultAddress;
    uint duration;
    uint voteMultiplier;
}

struct PositionsData {
    bool exists;
    uint nftId;
    uint combinedPoints;
    uint combinedVotes;
    uint positionsCount;
    PositionData[] positions;

}

struct PositionData {
    bool exists;
    uint depositedAmount;
    uint depositedTime;
    uint lockedUntillBlock;
    uint pointsIssued;
    uint votesIssued;
    uint multiplier;
}

contract TokenStakingContract is AccessControlEnumerable {
    
    using SafeERC20 for IERC20;

    bytes32 public constant MODERATOR_ROLE = keccak256("MODERATOR_ROLE");

    bool private _initialised;

    uint private _pointMultiplier = 10**10;
    uint private _totalPointsIssued;
    uint private _totalVotesIssued;
    StakingOptionsData[] private _stakingOptions;
    mapping(uint => uint) private _totalVotesOnNft;
    mapping(uint => uint) private _totalPointsOnNft;
    mapping(address => uint) private _vaultAddressToOptionId;
    mapping(uint => mapping (address => PositionsData)) private _positions;

    address private _vaultAddress;
    IERC20 private _tokenInstance;
    INftContract private _nftInstance;

    constructor() {
        _grantRole(DEFAULT_ADMIN_ROLE, _msgSender());
    }

    // **************************************************
    // ****************** PUBLIC REGION *****************
    // **************************************************
    function stakeTokens(uint nftId_, uint stakingOptionId_, uint amount_) public {
        require(_stakingOptions[stakingOptionId_].active, "Staking option is not active!");
        require(_nftInstance.ownerOf(nftId_) == _msgSender(), "Sender is not the owner of this NFT!");
        require(amount_ > 0, "Amount must be greater than 0!");

        StakingOptionsData memory stakingOption = _stakingOptions[stakingOptionId_];
        VaultContract stakingVault = VaultContract(stakingOption.vaultAddress);
        PositionsData storage nftPositionData = _positions[nftId_][stakingOption.vaultAddress];
        
        uint pointsIssued;
        uint votesIssued;
        if (!nftPositionData.exists) {
            _positions[nftId_][stakingOption.vaultAddress].exists = true;
            _positions[nftId_][stakingOption.vaultAddress].nftId = nftId_;
        }

        if(stakingOption.pointsIssued == 0) {
            if (stakingVault.tokenBalance() > 0) {
                stakingVault.withdrawTokens(_vaultAddress, stakingVault.tokenBalance());
            }
            pointsIssued = amount_ * _pointMultiplier;
            votesIssued = pointsIssued * stakingOption.voteMultiplier;
        } else {
            pointsIssued = amount_ * getPointMultiplier(stakingOptionId_);
            votesIssued = pointsIssued * stakingOption.voteMultiplier;
        }

        _totalPointsIssued += pointsIssued;
        _totalVotesIssued += votesIssued;
        _totalPointsOnNft[nftId_] += pointsIssued;
        _totalVotesOnNft[nftId_] += votesIssued;
        _stakingOptions[stakingOptionId_].pointsIssued += pointsIssued;
        _stakingOptions[stakingOptionId_].votesIssued += votesIssued;
        nftPositionData.combinedPoints += pointsIssued;
        nftPositionData.combinedVotes += votesIssued;
        nftPositionData.positions.push(
            PositionData(
                true,
                amount_, 
                block.timestamp, 
                block.number + stakingOption.duration, 
                pointsIssued,
                votesIssued,
                stakingOption.voteMultiplier
            )
        );
        _tokenInstance.safeTransferFrom(_msgSender(), _stakingOptions[stakingOptionId_].vaultAddress, amount_);
        emit PositionAdded(nftId_, stakingOptionId_, amount_, pointsIssued, block.number + stakingOption.duration);
    }
    
    function unstakeTokens(uint nftId_, uint stakingOptionId_, uint positionId_) public {
        require(_nftInstance.ownerOf(nftId_) == _msgSender(), "Sender is not the owner of this NFT!");
        require(_stakingOptions[stakingOptionId_].exists, "StakingOption does not exist!");
        PositionsData storage positions = _positions[nftId_][_stakingOptions[stakingOptionId_].vaultAddress];
        PositionData storage position = positions.positions[positionId_];
        require(position.exists, "Position does not exist!");
        require(position.lockedUntillBlock < block.number, "Position is still locked!");

        VaultContract stakingVault = VaultContract(_stakingOptions[stakingOptionId_].vaultAddress);
        uint positionTokens = getPositionTokens(nftId_, stakingOptionId_, positionId_);

        _totalPointsIssued -= position.pointsIssued;
        _totalVotesIssued -= position.votesIssued;
        _stakingOptions[stakingOptionId_].pointsIssued -= position.pointsIssued;
        _stakingOptions[stakingOptionId_].votesIssued -= position.votesIssued;
        _totalPointsOnNft[nftId_] -= position.pointsIssued;
        _totalVotesOnNft[nftId_] -= position.votesIssued;
        positions.combinedPoints -= position.pointsIssued;
        positions.combinedVotes -= position.votesIssued;

        emit PositionRemoved(nftId_, stakingOptionId_, positionTokens, position.pointsIssued, position.votesIssued);

        if (positionId_ == positions.positions.length - 1) {
            positions.positions.pop();
        } else {
            positions.positions[positionId_] = positions.positions[positions.positions.length - 1];
            positions.positions.pop();
        }
        stakingVault.withdrawTokens(_msgSender(), positionTokens);
    }
    function unstakePartial(uint nftId_, uint stakingOptionId_, uint positionId_, uint pointAmount_) public {
        
        require(_nftInstance.ownerOf(nftId_) == _msgSender(), "Sender is not the owner of this NFT!");
        require(_stakingOptions[stakingOptionId_].exists, "StakingOption does not exist!");
        PositionsData storage positions = _positions[nftId_][_stakingOptions[stakingOptionId_].vaultAddress];
        PositionData storage position = positions.positions[positionId_];
        require(position.exists, "Position does not exist!");
        require(position.lockedUntillBlock < block.number, "Position is still locked!");
        require(position.pointsIssued > pointAmount_, "Point amount is greater than the position points!");

        VaultContract stakingVault = VaultContract(_stakingOptions[stakingOptionId_].vaultAddress);
        uint positionTokens = getPositionTokens(nftId_, stakingOptionId_, positionId_);
        uint partialPositionTokens = (positionTokens * pointAmount_) / position.pointsIssued;
        uint partialPositionVotes = (position.pointsIssued - pointAmount_) * position.multiplier;

        _totalPointsIssued -= pointAmount_;
        _totalVotesIssued -= partialPositionVotes;
        _stakingOptions[stakingOptionId_].pointsIssued -= pointAmount_;
        _stakingOptions[stakingOptionId_].votesIssued -= partialPositionVotes;
        _totalPointsOnNft[nftId_] -= pointAmount_;

        _totalVotesOnNft[nftId_] -= partialPositionVotes;
        positions.combinedPoints -= pointAmount_;
        positions.combinedVotes -= partialPositionVotes;

        position.depositedAmount -= partialPositionTokens;
        position.pointsIssued -= pointAmount_;
        position.votesIssued -= partialPositionVotes;
        position.depositedTime = block.timestamp;

        stakingVault.withdrawTokens(_msgSender(), partialPositionTokens);

        emit PositionRemoved(nftId_, stakingOptionId_, partialPositionTokens, pointAmount_, partialPositionVotes);    
    }

    function mergePositions(uint nftId_, uint stakingOptionId_, uint position1Id_, uint position2Id_) public {
        require(_nftInstance.ownerOf(nftId_) == _msgSender(), "Sender is not the owner of this NFT!");
        require(_stakingOptions[stakingOptionId_].exists, "StakingOption does not exist!");
        PositionsData storage positions = _positions[nftId_][_stakingOptions[stakingOptionId_].vaultAddress];
        PositionData storage position1 = positions.positions[position1Id_];
        PositionData memory position2 = positions.positions[position2Id_];
        require(position1Id_ < position2Id_, "Position2 must be bigger!");

        _totalVotesIssued = _totalVotesIssued - position1.votesIssued - position2.votesIssued;
        _totalVotesOnNft[nftId_] = _totalVotesOnNft[nftId_] - position1.votesIssued - position2.votesIssued;
        positions.combinedVotes = positions.combinedVotes - position1.votesIssued - position2.votesIssued;
        _stakingOptions[stakingOptionId_].votesIssued = _stakingOptions[stakingOptionId_].votesIssued - position1.votesIssued - position2.votesIssued;

        position1.depositedAmount += position2.depositedAmount;
        position1.depositedTime = block.timestamp;
        position1.lockedUntillBlock = position1.lockedUntillBlock >= position2.lockedUntillBlock ? position1.lockedUntillBlock : position2.lockedUntillBlock;
        position1.pointsIssued += position2.pointsIssued;
        position1.votesIssued = position1.pointsIssued * _stakingOptions[stakingOptionId_].voteMultiplier;
        position1.multiplier = _stakingOptions[stakingOptionId_].voteMultiplier;

        _totalVotesIssued += position1.votesIssued;
        _totalVotesOnNft[nftId_] += position1.votesIssued;
        positions.combinedVotes += position1.votesIssued;
        _stakingOptions[stakingOptionId_].votesIssued += position1.votesIssued;

        if (position2Id_ == positions.positions.length - 1) {
            positions.positions.pop();
        } else {
            positions.positions[position2Id_] = positions.positions[positions.positions.length - 1];
            positions.positions.pop();
        }

        emit PositionsMerged(nftId_, stakingOptionId_, position1Id_, position2Id_);
    }

    // **************************************************
    // ****************** MODERATOR REGION **************
    // **************************************************
    function addStakingOption(uint duration_, uint voteMultiplier_) public onlyRole(MODERATOR_ROLE) {
        address newVaultAddress = address(new VaultContract(address(_tokenInstance)));
        
        _vaultAddressToOptionId[newVaultAddress] = _stakingOptions.length;
        _stakingOptions.push(StakingOptionsData(true, true, 0, 0, newVaultAddress, duration_, voteMultiplier_));
        emit StakingOptionAdded(_stakingOptions.length - 1, newVaultAddress, duration_, voteMultiplier_);
    }
    function editStakingOption(uint stakingOptionId_, uint variableId_, bytes memory newValue_) public onlyRole(MODERATOR_ROLE) {
        require(_stakingOptions[stakingOptionId_].exists, "Staking option does not exist!");

        if (variableId_ == 0) {
            bool newValue = abi.decode(newValue_, (bool));
            require(newValue != _stakingOptions[stakingOptionId_].active);
            emit StakingOptionActiveChanged(stakingOptionId_, _stakingOptions[stakingOptionId_].active, newValue);
            _stakingOptions[stakingOptionId_].active = newValue;
        } else if(variableId_ == 1) {
            uint newValue = abi.decode(newValue_, (uint));
            require(newValue != _stakingOptions[stakingOptionId_].duration);
            emit StakingOptionDurationChanged(stakingOptionId_, _stakingOptions[stakingOptionId_].duration, newValue);
            _stakingOptions[stakingOptionId_].duration = newValue;
        } else if (variableId_ == 2) {
            uint newValue = abi.decode(newValue_, (uint));
            require(newValue != _stakingOptions[stakingOptionId_].voteMultiplier);
            emit StakingOptionMultiplierChanged(stakingOptionId_, _stakingOptions[stakingOptionId_].voteMultiplier, newValue); 
            _stakingOptions[stakingOptionId_].voteMultiplier = newValue;
        } else {
            revert("Variable ID is not valid!");
        }
    }
    function switchStakingOptions(uint stakingOptionId1_, uint stakingOptionId2_) public onlyRole(MODERATOR_ROLE) {
        require(_stakingOptions[stakingOptionId1_].exists, "Staking option 1 does not exist!");
        require(_stakingOptions[stakingOptionId2_].exists, "Staking option 2 does not exist!");
        require(stakingOptionId1_ < stakingOptionId2_, "Staking option 1 is bigger!");

        StakingOptionsData memory temp = _stakingOptions[stakingOptionId1_];
        _stakingOptions[stakingOptionId1_] = _stakingOptions[stakingOptionId2_];
        _vaultAddressToOptionId[_stakingOptions[stakingOptionId1_].vaultAddress] = stakingOptionId1_;
        _stakingOptions[stakingOptionId2_] = temp;
        _vaultAddressToOptionId[_stakingOptions[stakingOptionId2_].vaultAddress] = stakingOptionId2_;
        emit StakingOptionsSwitched(stakingOptionId1_, stakingOptionId2_);
    }
    function removeStakingOption(uint stakingOptionId_) public onlyRole(MODERATOR_ROLE) {
        require(!_stakingOptions[stakingOptionId_].active, "Staking option is active!");
        require(VaultContract(_stakingOptions[stakingOptionId_].vaultAddress).tokenBalance() == 0, "Vault is not empty!");

        _vaultAddressToOptionId[_stakingOptions[stakingOptionId_].vaultAddress] = 0;
        if (stakingOptionId_ == _stakingOptions.length - 1) {
            _stakingOptions.pop();
        } else {
            _stakingOptions[stakingOptionId_] = _stakingOptions[_stakingOptions.length - 1];
            _stakingOptions.pop();
        }
        emit StakingOptionRemoved(stakingOptionId_);
    }

    function removePositionAsModerator(uint nftId_, uint stakingOptionId_, uint positionId_) public onlyRole(MODERATOR_ROLE) {
        require(_stakingOptions[stakingOptionId_].exists, "Staking option does not exist!");
        PositionsData storage positions = _positions[nftId_][_stakingOptions[stakingOptionId_].vaultAddress];
        PositionData storage position = positions.positions[positionId_];
        require(_positions[nftId_][_stakingOptions[stakingOptionId_].vaultAddress].positions[positionId_].exists, "Position does not exist!");

        VaultContract stakingVault = VaultContract(_stakingOptions[stakingOptionId_].vaultAddress);
        uint positionTokens = getPositionTokens(nftId_, stakingOptionId_, positionId_);

        _totalPointsIssued -= position.pointsIssued;
        _totalVotesIssued -= position.votesIssued;
        _stakingOptions[stakingOptionId_].pointsIssued -= position.pointsIssued;
        _stakingOptions[stakingOptionId_].votesIssued -= position.votesIssued;
        _totalPointsOnNft[nftId_] -= position.pointsIssued;
        _totalVotesOnNft[nftId_] -= position.votesIssued;
        positions.combinedPoints -= position.pointsIssued;
        positions.combinedVotes -= position.votesIssued;

        emit PositionRemovedAsModerator(nftId_, stakingOptionId_, positionId_, positionTokens, position.pointsIssued);

        if (positionId_ == positions.positions.length - 1) {
            positions.positions.pop();
        } else {
            positions.positions[positionId_] = positions.positions[positions.positions.length - 1];
            positions.positions.pop();
        }
        stakingVault.withdrawTokens(_msgSender(), positionTokens);
    }

    function setVaultAddress(address vaultAddress_) public onlyRole(MODERATOR_ROLE) {
		require(_vaultAddress != vaultAddress_);
		emit VaultAddressChanged(_vaultAddress, vaultAddress_);
		_vaultAddress = vaultAddress_;
	}
	function setTokenInstance(address newTokenInstance_) public onlyRole(MODERATOR_ROLE) {
		require(address(_tokenInstance) != newTokenInstance_);
		emit TokenInstanceChanged(address(_tokenInstance), newTokenInstance_);
		_tokenInstance = IERC20(newTokenInstance_);
	}
    function setNftInstance(address newNftInstance_) public onlyRole(MODERATOR_ROLE) {
        require(address(_nftInstance) != newNftInstance_);
        emit NftInstanceChanged(address(_nftInstance), newNftInstance_);
        _nftInstance = INftContract(newNftInstance_);
    }

    // **************************************************
	// *************** DEFAULT_ADMIN REGION *************
	// **************************************************
	function init(
		address defaultAdminAddress_,
		address moderatorAddress_,
        address vaultAddress_,
        address tokenAddress_,
        address nftAddress_
	) public onlyRole(DEFAULT_ADMIN_ROLE) {
		require(!_initialised, "Contract is already initialised!");

		_grantRole(DEFAULT_ADMIN_ROLE, defaultAdminAddress_);
		_grantRole(MODERATOR_ROLE, defaultAdminAddress_);
		_grantRole(MODERATOR_ROLE, moderatorAddress_);

        _vaultAddress = vaultAddress_;
        _tokenInstance = IERC20(tokenAddress_);
        _nftInstance = INftContract(nftAddress_);

		_initialised = true;
		_revokeRole(DEFAULT_ADMIN_ROLE, _msgSender());
	}

    // **************************************************
	// ************** PUBLIC GETTERS REGION *************
	// **************************************************
    function initialised() public view returns (bool) {
        return _initialised;
    }

    function getPointMultiplier(uint stakingOptionId_) public view returns (uint) {
        if (_totalPointsIssued == 0) {
            return 1;
        }
        StakingOptionsData memory stakingOption = _stakingOptions[stakingOptionId_];
        return _totalPointsIssued / VaultContract(stakingOption.vaultAddress).tokenBalance();
    }
    function totalPointsIssued() public view returns (uint) {
        return _totalPointsIssued;
    }
    function totalVotesIssued() public view returns (uint) {
        return _totalVotesIssued;
    }
    function totalTokensStaked() public view returns (uint) {
        uint totalTokens = 0;
        for (uint i = 0; i < _stakingOptions.length; i++) {
            totalTokens += _tokenInstance.balanceOf(_stakingOptions[i].vaultAddress);
        }
        return totalTokens;
    }
    function hasPositions(uint256 tokenId_) public view returns (bool) {
        return _totalPointsOnNft[tokenId_] != 0 ? true : false;
    }
    function totalPointsOnNft(uint256 tokenId_) public view returns (uint) {
        return _totalPointsOnNft[tokenId_];
    }
    function totalVotesOnNft(uint256 tokenId_) public view returns (uint) {
        return _totalVotesOnNft[tokenId_];
    }
    function getVaultAddressToOptionId(address vaultAddress_) public view returns (uint) {
        return _vaultAddressToOptionId[vaultAddress_];
    }

    function getStakingOptionsCount() public view returns (uint) {
        return _stakingOptions.length;
    }
    function getStakingOption(uint stakingOptionId_) public view returns (StakingOptionsData memory) {
        return _stakingOptions[stakingOptionId_];
    }
    function getStakingOptions(uint startIndex_, uint endIndex_) public view returns (StakingOptionsData[] memory) {
        uint endIndex = endIndex_;
        if (getStakingOptionsCount() < endIndex) {
            endIndex = getStakingOptionsCount();
        }
        StakingOptionsData[] memory result = new StakingOptionsData[](endIndex - startIndex_);
        for (uint i = startIndex_; i < endIndex; i++) {
            result[i - startIndex_] = _stakingOptions[i];
        }
        return result;
    }

    function getPositionsCount(uint nftId_, uint stakingOptionId_) public view returns (uint) {
        address vaultAddress = _stakingOptions[stakingOptionId_].vaultAddress;
        return _positions[nftId_][vaultAddress].positions.length;
    }
    function getPositionsData(uint nftId_, uint stakingOptionId_) public view returns (PositionsData memory) {
        address vaultAddress = _stakingOptions[stakingOptionId_].vaultAddress;
        PositionsData memory result = PositionsData({
            exists: _positions[nftId_][vaultAddress].exists,
            nftId: nftId_,
            combinedPoints: _positions[nftId_][vaultAddress].combinedPoints,
            combinedVotes: _positions[nftId_][vaultAddress].combinedVotes,
            positionsCount: _positions[nftId_][vaultAddress].positions.length,
            positions : new PositionData[](0)
        });
        return result;
    }
    function getPosition(uint nftId_, uint stakingOptionId_, uint positionId_) public view returns (PositionData memory) {
        address vaultAddress = _stakingOptions[stakingOptionId_].vaultAddress;
        return _positions[nftId_][vaultAddress].positions[positionId_];
    }
    function getPositions(uint nftId_, uint stakingOptionId_, uint startIndex_, uint endIndex_) public view returns (PositionData[] memory) {
        address vaultAddress = _stakingOptions[stakingOptionId_].vaultAddress;
        uint endIndex = endIndex_;
        if (getPositionsCount(nftId_, stakingOptionId_) < endIndex) {
            endIndex = getPositionsCount(nftId_, stakingOptionId_);
        }
        PositionData[] memory result = new PositionData[](endIndex - startIndex_);
        for (uint i = startIndex_; i < endIndex; i++) {
            result[i - startIndex_] = _positions[nftId_][vaultAddress].positions[i];
        }
        return result;
    }
    function getPositionTokens(uint nftId_, uint stakingOptionId_, uint positionId_) public view returns (uint) {
        address vaultAddress_ = _stakingOptions[stakingOptionId_].vaultAddress;
        uint totalTokenBalance = VaultContract(vaultAddress_).tokenBalance();
        uint points = _positions[nftId_][vaultAddress_].positions[positionId_].pointsIssued;
        uint totalPoints = _stakingOptions[_vaultAddressToOptionId[vaultAddress_]].pointsIssued;
        return (totalTokenBalance * points) / totalPoints;
    }

    function getVaultAddress() public view returns (address) {
        return _vaultAddress;
    }
    function getTokenAddress() public view returns (address) {
        return address(_tokenInstance);
    }
    function getNftAddress() public view returns (address) {
        return address(_nftInstance);
    }

    // **************************************************
	// ****************** EVENTS REGION *****************
	// **************************************************
    event PositionAdded(uint indexed nftId_, uint indexed stakingOptionId_, uint amount_, uint unlockBlock_, uint pointsIssued);
    event PositionRemoved(uint indexed nftId_, uint indexed stakingOptionId_, uint positionId_, uint amount, uint pointsRemoved);
    event PositionPointsRemoved(uint indexed nftId_, uint indexed stakingOptionId_, uint positionId_, uint tokens, uint points, uint votes);
    event PositionsMerged(uint indexed nftId_, uint indexed stakingOptionId_, uint positionId1_, uint positionId2_);

    event StakingOptionAdded(uint indexed stakingOptionId_, address vaultAddress_, uint duration_, uint multiplier_);
    event StakingOptionActiveChanged(uint indexed stakingOptionId_, bool oldValue_, bool newValue_);
    event StakingOptionDurationChanged(uint indexed stakingOptionId_, uint oldValue_, uint newValue_);
    event StakingOptionMultiplierChanged(uint indexed stakingOptionId_, uint oldValue_, uint newValue_);
    event StakingOptionsSwitched(uint indexed stakingOptionId1, uint indexed stakingOptionId2);
    event StakingOptionRemoved(uint indexed stakingOptionId_);

    event PositionRemovedAsModerator(uint indexed nftId_, uint indexed stakingOptionId_, uint positionId_, uint amount, uint pointsRemoved);

    event VaultAddressChanged(address oldValue_, address newValue_);
    event TokenInstanceChanged(address oldValue_, address newValue_);
    event NftInstanceChanged(address oldValue_, address newValue_);
}

contract VaultContract {
    address public owner;
    IERC20 private _tokenInstance;
    constructor(address tokenContract_) {
        owner = msg.sender;
        _tokenInstance = IERC20(tokenContract_);
    }
    function withdrawTokens(address reciever_, uint amount_) public {
        require(msg.sender == owner, "Sender is not the owner of this vault!");
        _tokenInstance.transfer(reciever_, amount_);
    }
    function tokenBalance() public view returns (uint) {
        return _tokenInstance.balanceOf(address(this));
    }
}

interface INftContract {
    function ownerOf(uint tokenId_) external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (access/AccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControlEnumerable.sol";
import "./AccessControl.sol";
import "../utils/structs/EnumerableSet.sol";

/**
 * @dev Extension of {AccessControl} that allows enumerating the members of each role.
 */
abstract contract AccessControlEnumerable is IAccessControlEnumerable, AccessControl {
    using EnumerableSet for EnumerableSet.AddressSet;

    mapping(bytes32 => EnumerableSet.AddressSet) private _roleMembers;

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlEnumerable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) public view virtual override returns (address) {
        return _roleMembers[role].at(index);
    }

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) public view virtual override returns (uint256) {
        return _roleMembers[role].length();
    }

    /**
     * @dev Overload {_grantRole} to track enumerable memberships
     */
    function _grantRole(bytes32 role, address account) internal virtual override {
        super._grantRole(role, account);
        _roleMembers[role].add(account);
    }

    /**
     * @dev Overload {_revokeRole} to track enumerable memberships
     */
    function _revokeRole(bytes32 role, address account) internal virtual override {
        super._revokeRole(role, account);
        _roleMembers[role].remove(account);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControlEnumerable.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";

/**
 * @dev External interface of AccessControlEnumerable declared to support ERC165 detection.
 */
interface IAccessControlEnumerable is IAccessControl {
    /**
     * @dev Returns one of the accounts that have `role`. `index` must be a
     * value between 0 and {getRoleMemberCount}, non-inclusive.
     *
     * Role bearers are not sorted in any particular way, and their ordering may
     * change at any point.
     *
     * WARNING: When using {getRoleMember} and {getRoleMemberCount}, make sure
     * you perform all queries on the same block. See the following
     * https://forum.openzeppelin.com/t/iterating-over-elements-on-enumerableset-in-openzeppelin-contracts/2296[forum post]
     * for more information.
     */
    function getRoleMember(bytes32 role, uint256 index) external view returns (address);

    /**
     * @dev Returns the number of accounts that have `role`. Can be used
     * together with {getRoleMember} to enumerate all bearers of a role.
     */
    function getRoleMemberCount(bytes32 role) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControl.sol";
import "../utils/Context.sol";
import "../utils/Strings.sol";
import "../utils/introspection/ERC165.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControl is Context, IAccessControl, ERC165 {
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControl).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        Strings.toHexString(uint160(account), 20),
                        " is missing role ",
                        Strings.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 *  Trying to delete such a structure from storage will likely result in data corruption, rendering the structure unusable.
 *  See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 *  In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        return _values(set._inner);
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControl {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}