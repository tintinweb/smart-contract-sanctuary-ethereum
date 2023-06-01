/**
 *Submitted for verification at Etherscan.io on 2023-06-01
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


// 
struct MintData {
    uint8 coreMinted;
    uint8 teamMinted;
    uint8 partnersMinted;
    uint8 seedMinted;
    uint8 publicMinted;
    uint96 seedSalePrice;
    uint96 publicSalePrice;
    bool seedActive;
    bool publicActive;
}

interface ICryptoHubShares {
    function approve(address to, uint256 tokenId) external;

    function balanceOf(address owner) external view returns (uint256);

    function baseURI() external view returns (string memory);

    function decreaseWhitelist(
        address[] calldata _addresses,
        uint8[] calldata _quantity
    ) external;

    function getApproved(uint256 tokenId) external view returns (address);

    function getMintData() external view returns (MintData memory);

    function getWhitelistedQuantity(
        address _address
    ) external view returns (uint8);

    function increaseWhitelist(
        address[] calldata _addresses,
        uint8[] calldata _quantity
    ) external;

    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);

    function mintCore(address _ceo, address _cto, address _cmo) external;

    function mintPartners(address[] calldata _to) external;

    function mintPublic(uint8 _quantity) external;

    function mintPublicFor(address _for, uint8 _quantity) external;

    function mintSeed(uint8 _quantity) external;

    function mintSeedFor(address _for, uint8 _quantity) external;

    function mintTeam(address[] calldata _to) external;

    function name() external view returns (string memory);

    function owner() external view returns (address);

    function ownerOf(uint256 tokenId) external view returns (address);

    function renounceOwnership() external;

    function royaltyInfo(
        uint256 _tokenId,
        uint256 _salePrice
    ) external view returns (address, uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;

    function setPublicActive(bool _active) external;

    function setPublicPrice(uint96 _price) external;

    function setRoyalty(address _newOwner, uint96 _newRoyalty) external;

    function setSeedActive(bool _active) external;

    function setSeedPrice(uint96 _price) external;

    function shareFor(uint256 _tokenId) external pure returns (uint256);

    function sharesOf(address _address) external view returns (uint256);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function totalSupply() external view returns (uint256 total);

    function transferFrom(address from, address to, uint256 tokenId) external;

    function transferOwnership(address newOwner) external;

    function withdraw() external;
}

// 
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)
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

// 
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)
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

// 
struct LockData {
    address owner;
    uint48 ownershipStart;
    uint48 ownershipPeriod;
}

struct UserLock {
    uint32 tokenId;
    uint48 ownershipStart;
    uint48 ownershipPeriod;
}

contract CryptoHubEscrow is Ownable {
    ICryptoHubShares public immutable shares;

    mapping(uint32 => LockData) public locks;

    mapping(address => uint32[]) private _locksByOwner;

    constructor(ICryptoHubShares _shares, address _owner) {
        shares = _shares;
        _transferOwnership(_owner);
    }

    function locksByOwner(
        address _user
    ) external view returns (uint32[] memory) {
        return _locksByOwner[_user];
    }

    function getFullUserLocks(
        address _user
    ) external view returns (UserLock[] memory) {
        uint32[] memory _locks = _locksByOwner[_user];
        UserLock[] memory _result = new UserLock[](_locks.length);

        for (uint256 i = 0; i < _locks.length; i++) {
            _result[i] = UserLock({
                tokenId: _locks[i],
                ownershipStart: locks[_locks[i]].ownershipStart,
                ownershipPeriod: locks[_locks[i]].ownershipPeriod
            });
        }

        return _result;
    }

    function getAllLocksForUser(
        address _user
    ) external view returns (uint32[] memory) {
        uint32[] memory activeLocks = new uint32[](_locksByOwner[_user].length);

        uint32 _active = 0;

        for (uint256 i = 0; i < _locksByOwner[_user].length; i++) {
            if (_isLocked(_locksByOwner[_user][i])) {
                activeLocks[_active] = _locksByOwner[_user][i];
                _active++;
            }
        }

        uint32[] memory _result = new uint32[](_active);

        for (uint256 i = 0; i < _active; i++) {
            _result[i] = activeLocks[i];
        }

        return _result;
    }

    event NFTAssigned(
        address indexed _user,
        uint256 indexed _tokenId,
        uint48 _expiration
    );

    function assignNFTTo(
        address _user,
        uint32 _tokenId,
        uint48 _ownershipPeriod
    ) public onlyOwner {
        bool isLocked = _isLocked(_tokenId);
        address oldOwner = locks[_tokenId].owner;

        // Cleanup old lock if it exists
        if (!isLocked && oldOwner != address(0) && oldOwner != _user) {
            address owner = locks[_tokenId].owner;
            delete locks[_tokenId];

            uint32[] storage _locks = _locksByOwner[owner];

            for (uint256 i = 0; i < _locks.length; i++) {
                if (_locks[i] == _tokenId) {
                    _locks[i] = _locks[_locks.length - 1];
                    _locks.pop();
                    break;
                }
            }
        }
        require(!isLocked, "Token already locked to an address");

        require(
            shares.ownerOf(_tokenId) == address(this),
            "Token not owned by this contract"
        );

        locks[_tokenId] = LockData({
            owner: _user,
            ownershipStart: uint48(block.timestamp),
            ownershipPeriod: _ownershipPeriod
        });

        _locksByOwner[_user].push(_tokenId);

        emit NFTAssigned(
            _user,
            _tokenId,
            uint48(block.timestamp) + _ownershipPeriod
        );
    }

    function assignManyNFTs(
        address[] calldata _users,
        uint32[][] calldata _tokenIds,
        uint48[] calldata _ownershipPeriods
    ) external onlyOwner {
        /*
        solidity will fail for accessing out of bound array elements
        require(
            _users.length == _tokenIds.length &&
                _users.length == _ownershipPeriods.length,
            "Invalid input"
        );
        */

        for (uint256 i = 0; i < _users.length; i++) {
            for (uint256 j = 0; j < _tokenIds[i].length; j++) {
                assignNFTTo(_users[i], _tokenIds[i][j], _ownershipPeriods[i]);
            }
        }
    }

    function transferNFT(uint32 _tokenId, address _to) external onlyOwner {
        require(!_isLocked(_tokenId), "Token already locked to an address");

        shares.safeTransferFrom(address(this), _to, _tokenId);
    }

    function extendOwnershipPeriod(
        uint32 _tokenId,
        uint48 _timeToAdd
    ) external onlyOwner {
        require(_isLocked(_tokenId), "Token not locked to an address");

        locks[_tokenId].ownershipPeriod += _timeToAdd;

        emit NFTAssigned(
            locks[_tokenId].owner,
            _tokenId,
            uint48(block.timestamp) + locks[_tokenId].ownershipPeriod
        );
    }

    function giveForEver(uint32 _tokenId, address _to) external onlyOwner {
        require(_isLocked(_tokenId), "Token not locked to an address");
        require(
            locks[_tokenId].owner == _to,
            "Token not locked to this address"
        );

        // delete lock
        delete locks[_tokenId];
        // remove lock from owner
        _cleanupLocks(_to);

        shares.safeTransferFrom(address(this), _to, _tokenId);

        emit NFTAssigned(_to, _tokenId, uint48(block.timestamp));
    }

    function _cleanupLocks(address _owner) internal {
        uint32[] storage _locks = _locksByOwner[_owner];

        for (uint256 i = 0; i < _locks.length; i++) {
            if (!_isLocked(_locks[i])) {
                _locks[i] = _locks[_locks.length - 1];
                _locks.pop();
            }
        }
    }

    function balanceOf(address _user) external view returns (uint32) {
        uint32 _active = 0;
        uint32[] storage _locks = _locksByOwner[_user];
        unchecked {
            for (uint256 i = 0; i < _locks.length; i++) {
                if (_isLocked(_locks[i])) {
                    _active++;
                }
            }
        }

        return _active;
    }

    function sharesOf(address _user) external view returns (uint32) {
        uint32 _active = 0;
        uint32[] storage _locks = _locksByOwner[_user];
        unchecked {
            for (uint256 i = 0; i < _locks.length; i++) {
                if (_isLocked(_locks[i])) {
                    _active += uint32(shares.shareFor(_locks[i]));
                }
            }
        }

        return _active;
    }

    function _isLocked(uint32 _tokenId) internal view returns (bool) {
        LockData storage _lock = locks[_tokenId];
        return
            _lock.owner != address(0) &&
            _lock.ownershipStart + _lock.ownershipPeriod > block.timestamp;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}