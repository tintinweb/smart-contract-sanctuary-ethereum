//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC721.sol";
import "./IterateMapping.sol";
import "./interfaces/IMasterChef.sol";
import "./interfaces/INFTMasterChef.sol";
import "./interfaces/INFTStaking.sol";

/**
 * @notice SecondSkin NFT Staking contract
 * @dev Just register NFT token ID but not lock NFT in our contract
 */
contract NFTStaking is Ownable, INFTStaking {
    using IterableMapping for ItMap;

    /// @notice Includes registered token ID array
    struct StakedInfo {
        uint256[] tokenIds; // registered token id array
        uint256 size; // use this to avoid compile error
    }

    /// @notice Secondskin NFT contract
    IERC721 public secondskinNFT;
    /// @notice MasterChef contract
    IMasterChef public masterChef;
    /// @notice NFT MasterChef contract
    INFTMasterChef public nftMasterChef;

    /// @notice Maximum register able NFT amount
    /// @dev This is used to avoid block gas limit
    uint256 public constant MAX_REGISTER_LIMIT = 12;
    /// @dev Use this instead of -1.
    /// This would be used for unknow index
    uint256 public constant MINUS_ONE = 999;

    /// @notice registered token id array in this contract
    /// @dev NOTE: secondskin nft has no tokenId: 0
    /// staker address => staking index => tokenId
    mapping(address => StakedInfo) public stakedIds;
    /// @notice need to track registered token IDs in smartchef
    /// so that we can provide booster option to secondskin NFT stakers
    /// We just check if registered "Secondskin NFT" token ID is hold in user wallet
    /// both at the beginning of stake and at end of unlock date
    /// user address => pool address => info
    mapping(address => mapping(address => ItMap)) public smartChefBoostData;
    /// @notice need to track registered token IDs in nftchef
    /// so that we can provide booster option to secondskin NFT stakers
    /// We just check if registered "Secondskin NFT" token ID is hold in user wallet
    /// both at the beginning of stake and at end of unlock date
    /// user address => pool address => info
    mapping(address => mapping(address => ItMap)) public nftChefBoostData;

    /// @dev when you register secondskin NFT in NFTStaking contract,
    event NFTStaked(address sender, uint256 tokenId);
    /// @dev when you unregister secondskin NFT in NFTStaking contract,
    event NFTUnstaked(address sender, uint256 tokenId);
    /// @dev if you have registered secondskin NFT in NFTStaking contract,
    /// you can get booster in smartchef contract
    event SmartChefBoosterAdded(
        address sender,
        address smartchefAddress,
        uint256 tokenId,
        uint256 timestamp
    );
    /// @dev if you have registered secondskin NFT in NFTStaking contract,
    /// you can get booster in nftchef contract
    event NFTChefBoosterAdded(
        address sender,
        address nftchefAddress,
        uint256 tokenId,
        uint256 timestamp
    );

    /// @notice Checks if the msg.sender is a owner of the NFT.
    modifier onlyTokenOwner(uint256 tokenId) {
        require(
            secondskinNFT.ownerOf(tokenId) == msg.sender,
            "You are not owner"
        );
        _;
    }

    /// @notice Checks if the msg.sender is sub smartchef
    modifier onlySmartChef() {
        require(
            address(masterChef) != address(0x0),
            "masterchef: zero address"
        );
        bool flag = false;
        address[] memory smartchefAddresses = masterChef.getAllChefAddress();
        uint256 smartchefNum = smartchefAddresses.length;
        for (uint256 si = 0; si < smartchefNum; si++) {
            address smarchefAddress = smartchefAddresses[si];
            if (smarchefAddress == msg.sender) {
                flag = true;
            }
        }
        require(flag, "You are not subchef");
        _;
    }

    /// @notice Checks if the msg.sender is sub nftchef
    modifier onlyNFTChef() {
        require(
            address(nftMasterChef) != address(0x0),
            "nftMasterChef: zero address"
        );
        bool flag = false;
        address[] memory nftchefAddresses = nftMasterChef.getAllChefAddress();
        uint256 nftchefNum = nftchefAddresses.length;
        for (uint256 si = 0; si < nftchefNum; si++) {
            address nftchefAddress = nftchefAddresses[si];
            if (nftchefAddress == msg.sender) {
                flag = true;
            }
        }
        require(flag, "You are not subchef");
        _;
    }

    /// @notice Check if target is not zero address
    /// @param addr: target address
    modifier _realAddress(address addr) {
        require(addr != address(0), "Cannot be zero address");
        _;
    }

    /**
     * @notice Constructor
     * @param _secondskinNFT: Altava SecondSkin NFT contract
     */
    constructor(IERC721 _secondskinNFT) {
        secondskinNFT = _secondskinNFT;
    }

    /**
     * @notice Set MasterChef contract by only admin
     */
    function setMasterChef(
        address newMasterChef
    ) external onlyOwner _realAddress(newMasterChef) {
        masterChef = IMasterChef(newMasterChef);
    }

    /**
     * @dev update secondskin nft address
     */
    function setSecondskinNFT(
        address _secondskinnft
    ) external onlyOwner _realAddress(_secondskinnft) {
        secondskinNFT = IERC721(_secondskinnft);
    }

    /**
     * @notice Set NFT MasterChef contract by only admin
     */
    function setNFTMasterChef(
        address newNFTMasterChef
    ) external onlyOwner _realAddress(newNFTMasterChef) {
        nftMasterChef = INFTMasterChef(newNFTMasterChef);
    }

    /**
     * @notice Register secondskin NFT token IDs
     * @dev Only IDs that sender holds can be registered
     * @param tokenIds: secondskin NFT token ID array
     */
    function stake(uint256[] calldata tokenIds) external {
        require(
            address(masterChef) != address(0x0),
            "masterchef: zero address"
        );
        uint256 len = tokenIds.length;
        require(len > 0, "Empty array");
        address _sender = msg.sender;
        _removeUnholdNFTs(_sender);

        StakedInfo memory stakedInfo = stakedIds[_sender];
        uint256 curRegisteredAmount = stakedInfo.tokenIds.length;
        require(
            len + curRegisteredAmount <= MAX_REGISTER_LIMIT,
            "Overflow max registration limit"
        );

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = tokenIds[i];
            _stake(tokenId);

            address[] memory smartchefAddresses = masterChef
                .getAllChefAddress();
            uint256 smartchefNum = smartchefAddresses.length;
            uint256 timestamp = block.timestamp;
            for (uint256 si = 0; si < smartchefNum; si++) {
                address smarchefAddress = smartchefAddresses[si];
                ItMap storage smartchefData = smartChefBoostData[_sender][
                    smarchefAddress
                ];
                if (
                    !smartchefData.contains(tokenId) &&
                    smartchefData.stakeStarted &&
                    smartchefData.keys.length < MAX_REGISTER_LIMIT
                ) {
                    smartchefData.insert(tokenId, timestamp);
                    // emit event
                    emit SmartChefBoosterAdded(
                        _sender,
                        smarchefAddress,
                        tokenId,
                        timestamp
                    );
                }
            }
        }
    }

    /**
     * @notice Unregister token IDs
     * @param tokenId: token ID to unregister
     */
    function unstake(uint256 tokenId) external onlyTokenOwner(tokenId) {
        address _sender = msg.sender;
        _removeUnholdNFTs(_sender);
        uint256 currentIndex = _getStakedIndex(_sender, tokenId);
        require(currentIndex != MINUS_ONE, "Not staked yet");

        StakedInfo storage stakedInfo = stakedIds[_sender];
        uint256 lastIndex = stakedInfo.tokenIds.length - 1;
        if (lastIndex != currentIndex) {
            stakedInfo.tokenIds[currentIndex] = stakedInfo.tokenIds[lastIndex];
        }
        stakedInfo.tokenIds.pop();
        // If userInfo is empty, free up storage space and get gas refund
        if (lastIndex == 0) {
            delete stakedIds[_sender];
        }

        emit NFTUnstaked(_sender, tokenId);
    }

    /**
     * @notice when Stake TAVA or Extend locked period in SmartChef contract
     * need to start tracking staked secondskin NFT token IDs for booster
     * @param sender: user address
     */
    function stakeFromSmartChef(
        address sender
    ) external override onlySmartChef returns (bool) {
        ItMap storage smartchefData = smartChefBoostData[sender][msg.sender];
        StakedInfo memory stakedInfo = stakedIds[sender];
        uint256 len = stakedInfo.tokenIds.length;
        uint256 curBlockTimestamp = block.timestamp;
        smartchefData.stakeStarted = true;

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = stakedInfo.tokenIds[i];
            smartchefData.insert(tokenId, curBlockTimestamp);
            // emit event
            emit SmartChefBoosterAdded(
                sender,
                msg.sender,
                tokenId,
                curBlockTimestamp
            );
        }
        return true;
    }

    /**
     * @notice when unstake TAVA in SmartChef contract
     * need to free space in nft staking contract
     */
    function unstakeFromSmartChef(
        address sender
    ) external override onlySmartChef returns (bool) {
        ItMap storage smartchefData = smartChefBoostData[sender][msg.sender];
        if (smartchefData.stakeStarted && smartchefData.keys.length > 0) {
            delete smartChefBoostData[sender][msg.sender];
        }
        return true;
    }

    /**
     * @notice when Stake TAVA or Extend locked period in NFTChef contract
     * need to start tracking staked secondskin NFT token IDs for booster
     * @param sender: user address
     */
    function stakeFromNFTChef(
        address sender
    ) external override onlyNFTChef returns (bool) {
        ItMap storage nftchefData = nftChefBoostData[sender][msg.sender];
        StakedInfo memory stakedInfo = stakedIds[sender];
        uint256 len = stakedInfo.tokenIds.length;
        uint256 curBlockTimestamp = block.timestamp;
        nftchefData.stakeStarted = true;

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = stakedInfo.tokenIds[i];
            nftchefData.insert(tokenId, curBlockTimestamp);
            // emit event
            emit NFTChefBoosterAdded(
                sender,
                msg.sender,
                tokenId,
                curBlockTimestamp
            );
        }
        return true;
    }

    /**
     * @notice when unstake TAVA in NFTChef contract
     * need to free space in nft staking contract
     */
    function unstakeFromNFTChef(
        address sender
    ) external override onlyNFTChef returns (bool) {
        ItMap storage nftchefData = nftChefBoostData[sender][msg.sender];
        if (nftchefData.stakeStarted && nftchefData.keys.length > 0) {
            delete nftChefBoostData[sender][msg.sender];
        }
        return true;
    }

    /**
     * @notice get registered token IDs for smartchef
     * @param sender: target address
     * @param smartchef: smartchef address
     * return timestamp array, registered count array at that ts
     */
    function getSmartChefBoostData(
        address sender,
        address smartchef
    ) external view override returns (uint256[] memory, uint256[] memory) {
        ItMap storage senderData = smartChefBoostData[sender][smartchef];
        uint256[] memory tempKeys = senderData.keys;

        uint256 stakedAmount = senderData.keys.length;
        uint256[] memory tempTss = new uint256[](stakedAmount);

        uint256 tempCount = 0;
        for (uint256 i = 0; i < stakedAmount; i++) {
            uint256 tokenId = tempKeys[i];
            bool isOwned = secondskinNFT.ownerOf(tokenId) == sender;
            if (isOwned) {
                uint256 ts = senderData.data[tokenId];

                tempTss[tempCount] = ts;
                tempCount++;
            }
        }

        return _removeDuplicateBasedOnTimestamp(tempTss, tempCount);
    }

    /**
     * @notice get registered token IDs for nftchef
     * @param sender: target address
     * @param nftchef: nftchef address
     */
    function getNFTChefBoostCount(
        address sender,
        address nftchef
    ) external view override returns (uint256) {
        ItMap storage data = nftChefBoostData[sender][nftchef];
        uint256 stakedAmount = data.keys.length;
        uint256 tempCount = 0;

        for (uint256 i = 0; i < stakedAmount; i++) {
            uint256 tokenId = data.keys[i];
            bool isOwned = secondskinNFT.ownerOf(tokenId) == sender;
            if (isOwned) {
                tempCount++;
            }
        }
        return tempCount;
    }

    /**
     * @notice get registered token IDs
     * @param sender: target address
     */
    function getStakedTokenIds(
        address sender
    ) external view override returns (uint256[] memory) {
        StakedInfo memory stakedInfo = stakedIds[sender];
        uint256 stakedAmount = stakedInfo.tokenIds.length;
        uint256 liveStakedAmount = getStakedNFTCount(sender);
        uint256 tempCount = 0;

        uint256[] memory tokenIds = new uint256[](liveStakedAmount);

        for (uint256 i = 0; i < stakedAmount; i++) {
            uint256 tokenId = stakedInfo.tokenIds[i];
            bool isOwned = secondskinNFT.ownerOf(tokenId) == sender;
            if (isOwned) {
                tokenIds[tempCount] = tokenId;
                tempCount++;
            }
        }
        return tokenIds;
    }

    /**
     * @notice Get registered amount by sender
     * @param sender: target address
     */
    function getStakedNFTCount(
        address sender
    ) public view returns (uint256 amount) {
        StakedInfo memory stakedInfo = stakedIds[sender];

        uint256 stakedAmount = stakedInfo.tokenIds.length;
        amount = 0;
        for (uint256 i = 0; i < stakedAmount; i++) {
            bool isOwned = secondskinNFT.ownerOf(stakedInfo.tokenIds[i]) ==
                sender;
            if (isOwned) {
                amount++;
            }
        }
    }

    /**
     * @dev In case user unhold the NFTs, they should be removed from staked info.
     */
    function _removeUnholdNFTs(address _sender) private {
        StakedInfo memory stakedInfo = stakedIds[_sender];
        uint256 len = stakedInfo.tokenIds.length;

        for (uint256 i = 0; i < len; i++) {
            uint256 tokenId = stakedInfo.tokenIds[i];
            if (secondskinNFT.ownerOf(tokenId) != _sender) {
                _removeHoldNFT(_sender, tokenId);
            }
        }
    }

    function _removeHoldNFT(address _sender, uint256 _tokenId) private {
        uint256 currentIndex = _getStakedIndex(_sender, _tokenId);

        StakedInfo storage stakedInfo = stakedIds[_sender];
        uint256 lastIndex = stakedInfo.tokenIds.length - 1;

        if (lastIndex != currentIndex) {
            stakedInfo.tokenIds[currentIndex] = stakedInfo.tokenIds[lastIndex];
        }
        stakedInfo.tokenIds.pop();
        emit NFTUnstaked(_sender, _tokenId);
    }

    /**
     * @notice Register secondskin NFT token ID
     * @dev Only ID that sender holds can be registered
     * @param tokenId: secondskin NFT token ID
     */
    function _stake(uint256 tokenId) private onlyTokenOwner(tokenId) {
        address _sender = msg.sender;

        uint256 currentIndex = _getStakedIndex(_sender, tokenId);

        /// Only for unregistered NFT
        if (currentIndex == MINUS_ONE) {
            StakedInfo storage stakedInfo = stakedIds[_sender];
            stakedInfo.tokenIds.push(tokenId);

            emit NFTStaked(_sender, tokenId);
        }
    }

    /**
     * @dev return registered index
     * if tokenId has not been registered, return MAX_LIMIT
     */
    function _getStakedIndex(
        address _sender,
        uint256 _tokenId
    ) private view returns (uint256) {
        StakedInfo memory stakedInfo = stakedIds[_sender];

        uint256 stakedAmount = stakedInfo.tokenIds.length;
        for (uint256 i = 0; i < stakedAmount; i++) {
            uint256 tokenId = stakedInfo.tokenIds[i];
            if (tokenId == _tokenId) {
                return i;
            }
        }
        // return out of range
        return MINUS_ONE;
    }

    /// @notice remove duplicated items and calculate duplicated counts
    /// @param inputKeys: target array
    /// return (itemValue array, itemCount array)
    function _removeDuplicateBasedOnTimestamp(
        uint256[] memory inputKeys, // timestamp
        uint256 arrayLen
    ) private pure returns (uint256[] memory, uint256[] memory) {
        uint256[] memory tempKeys = new uint256[](arrayLen);
        uint256[] memory tempValues = new uint256[](arrayLen);

        uint256 counter1 = 0;
        for (uint256 i = 0; i < arrayLen; ) {
            uint256 counter2 = 1;
            for (uint256 j = i + 1; j < arrayLen; j++) {
                if (inputKeys[i] == inputKeys[j]) {
                    counter2++;
                } else {
                    j = arrayLen;
                }
            }

            tempKeys[counter1] = inputKeys[i];
            tempValues[counter1] = counter2;
            counter1++;

            i += counter2;
        }

        uint256[] memory rltKeys = new uint256[](counter1);
        uint256[] memory rltValues = new uint256[](counter1);
        for (uint256 i = 0; i < counter1; i++) {
            rltKeys[i] = tempKeys[i];
            rltValues[i] = tempValues[i];
            if (i > 0) {
                rltValues[i] += rltValues[i - 1];
            }
        }

        return (rltKeys, rltValues);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

struct ItMap {
    // key => value
    mapping(uint256 => uint256) data;
    // key => index
    mapping(uint256 => uint256) indexs;
    // keys array
    uint256[] keys;
    // check boolean
    bool stakeStarted;
}

library IterableMapping {
    function insert(
        ItMap storage self,
        uint256 key,
        uint256 value
    ) internal {
        uint256 keyIndex = self.indexs[key];
        self.data[key] = value;
        if (keyIndex > 0) return;
        else {
            self.indexs[key] = self.keys.length + 1;
            self.keys.push(key);
            return;
        }
    }

    function remove(ItMap storage self, uint256 key) internal {
        uint256 index = self.indexs[key];
        if (index == 0) return;
        uint256 lastKey = self.keys[self.keys.length - 1];
        if (key != lastKey) {
            self.keys[index - 1] = lastKey;
            self.indexs[lastKey] = index;
        }
        delete self.data[key];
        delete self.indexs[key];
        self.keys.pop();
    }

    function contains(ItMap storage self, uint256 key)
        internal
        view
        returns (bool)
    {
        return self.indexs[key] > 0;
    }
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface INFTMasterChef {
    /**
     * @notice get chef address with id
     * @dev index starts from 1 but not zero
     * @param id: index
     */
    function getChefAddress(uint256 id) external view returns (address);

    /**
     * @notice get all smartchef contract's address
     */
    function getAllChefAddress() external view returns (address[] memory);
}

//SPDX-License-Identifier: UNLICENSED

pragma solidity 0.8.17;

interface INFTStaking {
    /**
     * @notice when Stake TAVA or Extend locked period in SmartChef contract
     * need to start tracking staked secondskin NFT token IDs for booster
     */
    function stakeFromSmartChef(address sender) external returns (bool);

    /**
     * @notice when unstake TAVA in SmartChef contract
     * need to free space in nft staking contract
     */
    function unstakeFromSmartChef(address sender) external returns (bool);

    /**
     * @notice when Stake TAVA or Extend locked period in NFTChef contract
     * need to start tracking staked secondskin NFT token IDs for booster
     * @param sender: user address
     */
    function stakeFromNFTChef(address sender) external returns (bool);

    /**
     * @notice when unstake TAVA in NFTChef contract
     * need to free space in nft staking contract
     */
    function unstakeFromNFTChef(address sender) external returns (bool);

    /**
     * @notice get registered token IDs
     * @param sender: target address
     */
    function getStakedTokenIds(address sender)
        external
        view
        returns (uint256[] memory result);

    /**
     * @notice get registered token IDs for smartchef
     * @param sender: target address
     * @param smartchef: smartchef address
     * return timestamp array, registered count array at that ts
     */
    function getSmartChefBoostData(address sender, address smartchef)
        external
        view
        returns (uint256[] memory, uint256[] memory);

    /**
     * @notice get registered token IDs for nftchef
     * @param sender: target address
     * @param nftchef: nftchef address
     */
    function getNFTChefBoostCount(address sender, address nftchef)
        external
        view
        returns (uint256);

    /**
     * @notice Get registered amount by sender
     * @param sender: target address
     */
    function getStakedNFTCount(address sender)
        external
        view
        returns (uint256 amount);
}

//SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.17;

interface IMasterChef {
    /**
     * @notice get all smartchef contract's address deployed by MasterChef
     */
    function getAllChefAddress() external view returns (address[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Note that the caller is responsible to confirm that the recipient is capable of receiving ERC721
     * or else they may be permanently lost. Usage of {safeTransferFrom} prevents loss, though the caller must
     * understand this adds an external call which potentially creates a reentrancy vulnerability.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
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