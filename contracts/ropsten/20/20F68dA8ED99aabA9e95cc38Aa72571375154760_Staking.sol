// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import '@openzeppelin/contracts/utils/introspection/IERC165.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import '@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol';
import '@openzeppelin/contracts/utils/Address.sol';
import '@openzeppelin/contracts/utils/Context.sol';
import '@openzeppelin/contracts/utils/Strings.sol';
import '@openzeppelin/contracts/utils/introspection/ERC165.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';
import '@openzeppelin/contracts/utils/math/SafeMath.sol';

library SafeMathInt {
    int256 private constant MIN_INT256 = int256(1) << 255;
    int256 private constant MAX_INT256 = ~(int256(1) << 255);

    /**
     * @dev Multiplies two int256 variables and fails on overflow.
     */
    function mul(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a * b;

        // Detect overflow when multiplying MIN_INT256 with -1
        require(c != MIN_INT256 || (a & MIN_INT256) != (b & MIN_INT256));
        require((b == 0) || (c / b == a));
        return c;
    }

    /**
     * @dev Division of two int256 variables and fails on overflow.
     */
    function div(int256 a, int256 b) internal pure returns (int256) {
        // Prevent overflow when dividing MIN_INT256 by -1
        require(b != -1 || a != MIN_INT256);

        // Solidity already throws when dividing by 0.
        return a / b;
    }

    /**
     * @dev Subtracts two int256 variables and fails on overflow.
     */
    function sub(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a - b;
        require((b >= 0 && c <= a) || (b < 0 && c > a));
        return c;
    }

    /**
     * @dev Adds two int256 variables and fails on overflow.
     */
    function add(int256 a, int256 b) internal pure returns (int256) {
        int256 c = a + b;
        require((b >= 0 && c >= a) || (b < 0 && c < a));
        return c;
    }

    /**
     * @dev Converts to absolute value, and fails on overflow.
     */
    function abs(int256 a) internal pure returns (int256) {
        require(a != MIN_INT256);
        return a < 0 ? -a : a;
    }

    function toUint256Safe(int256 a) internal pure returns (uint256) {
        require(a >= 0);
        return uint256(a);
    }
}

library SafeMathUint {
    function toInt256Safe(uint256 a) internal pure returns (int256) {
        int256 b = int256(a);
        require(b >= 0);
        return b;
    }
}

interface IEtherWarsGame {
    function getNFTRarity(uint256 tokenID) external view returns (uint8);

    function getNFTGen(uint256 tokenID) external view returns (uint8);

    function getNFTMetadata(uint256 tokenID) external view returns (uint8, uint8);

    function retrieveStolenNFTs() external returns (bool, uint256[] memory);
}

contract Staking is Ownable, IERC721Receiver {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    using SafeMathUint for uint256;
    using SafeMathInt for int256;

    IEtherWarsGame nftContract;
    IERC20 token;

    uint256 private totalFarmed;

    struct UserInfo {
        uint256[] stakedSoldiers;
        uint256[] stakedOfficers;
        uint256[] stakedGenerals;
        uint256 numberOfSteals; // resets after block.timestamp > lastSteal + 24h
        uint256 lastSteal; // timestamp
    }

    struct NFTInfo {
        address owner;
        uint8 nftType;
        uint256 depositTime;
        uint256 lastHarvest;
        uint256 amountStolen;
    }

    mapping(address => UserInfo) public userInfo;
    mapping(uint256 => NFTInfo) public nftInfo;

    uint256[] private stakedSoldiers;
    uint256[] private stakedOfficers; // array of staked officers TokenIDs
    uint256[] private stakedGenerals;

    uint256 private soldierReward = 10000 * 10**18;
    uint256 private generalReward = 20000 * 10**18;

    uint256 public stealPrice = 5 * 10**15;
    uint256 private stealChangeStartTime;
    uint256 private stealchangeNewPrice;

    uint256 private DAY = 60 * 60 * 24;

    bool private farmStarted = false;
    uint256 private farmStartDate;

    constructor(address _token, address _nftContract) {
        nftContract = IEtherWarsGame(_nftContract);
        token = IERC20(_token);
    }

    receive() external payable {
        revert();
    }

    function getCurrentStealPrice() public view returns (uint256) {
        if (block.timestamp <= stealChangeStartTime + 3600) {
            return stealchangeNewPrice;
        } else {
            return stealPrice;
        }
    }

    function getNFTpending(uint256 tokenId) external view returns (uint256) {
        NFTInfo storage nft = nftInfo[tokenId];
        if (nft.nftType == 0) {
            return _pendingSoldiersReward(tokenId);
        } else if (nft.nftType == 1) {
            return _pendingOfficersReward(tokenId);
        } else if (nft.nftType == 2) {
            return _pendingGeneralsReward(tokenId);
        } else {
            return 0;
        }
    }

    function startFarming(uint256 _startDate) external {
        require(_msgSender() == owner() || _msgSender() == address(nftContract), 'Caller is not authorised');
        if (_msgSender() == address(nftContract)) {
            if (farmStartDate == 0) {
                farmStartDate = _startDate;
            }
        } else {
            if (_startDate != 0) {
                farmStartDate = _startDate;
            } else {
                farmStartDate = block.timestamp;
            }
        }
    }

    function getNumOfStakedSoldiers() public view returns (uint256) {
        return stakedSoldiers.length;
    }

    function getNumOfStakedOfficers() public view returns (uint256) {
        return stakedOfficers.length;
    }

    function getNumOfStakedGenerals() public view returns (uint256) {
        return stakedGenerals.length;
    }

    function getTotalFarmed() public view returns (uint256) {
        return totalFarmed;
    }

    function stake(uint256 tokenId) external {
        _retrieveStolenNFTs();
        _stake(tokenId);
    }

    function stakeMultiple(uint256[] calldata tokenIds) external {
        _retrieveStolenNFTs();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _stake(tokenIds[i]);
        }
    }

    function getStakedTokens(address owner) external view returns (uint256[] memory) {
        UserInfo storage user = userInfo[owner];
        uint256 length = user.stakedSoldiers.length + user.stakedOfficers.length + user.stakedGenerals.length;
        uint256[] memory tokenIds = new uint256[](length);
        uint256 counter;
        for (uint256 i = 0; i < user.stakedSoldiers.length; i++) {
            tokenIds[counter] = user.stakedSoldiers[i];
            counter++;
        }
        for (uint256 i = 0; i < user.stakedOfficers.length; i++) {
            tokenIds[counter] = user.stakedOfficers[i];
            counter++;
        }
        for (uint256 i = 0; i < user.stakedGenerals.length; i++) {
            tokenIds[counter] = user.stakedGenerals[i];
            counter++;
        }
        return (tokenIds);
    }

    function unstake(uint256 tokenId) external {
        _retrieveStolenNFTs();
        _unstake(tokenId);
    }

    function unstakeMultiple(uint256[] calldata tokenIds) external {
        _retrieveStolenNFTs();
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _unstake(tokenIds[i]);
        }
    }

    function harvest(uint256 tokenId) external {
        _retrieveStolenNFTs();
        _harvestNormal(tokenId);
    }

    function harvestAll() external {
        _retrieveStolenNFTs();
        UserInfo storage user = userInfo[_msgSender()];
        for (uint256 i = 0; i < user.stakedSoldiers.length; i++) {
            _harvestNormal(user.stakedSoldiers[i]);
        }
        for (uint256 i = 0; i < user.stakedOfficers.length; i++) {
            _harvestNormal(user.stakedOfficers[i]);
        }
        for (uint256 i = 0; i < user.stakedGenerals.length; i++) {
            _harvestNormal(user.stakedGenerals[i]);
        }
    }

    function pendingReward(address _address) external view returns (uint256) {
        return _pendingReward(_address);
    }

    function changeStealPrice(uint256 newPrice) external onlyOwner {
        stealPrice = newPrice;
    }

    function stealReward(uint256 tokenId) external payable {
        UserInfo storage user = userInfo[_msgSender()];
        NFTInfo storage nft = nftInfo[tokenId];
        require(nft.nftType == 1, 'Function is only for staked Officers');
        uint256 price = getCurrentStealPrice();
        require(msg.value >= price, 'Not enough payed');
        _stealReward(user);
        if (msg.value > price) {
            payable(msg.sender).transfer(msg.value - price);
        }
    }

    function changeStealPrice(uint256 newPrice, uint256 startTime) external onlyOwner {
        stealchangeNewPrice = newPrice;
        stealChangeStartTime = startTime;
    }

    function retrieveFunds() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawAnyToken(IERC20 asset) external onlyOwner {
        asset.safeTransfer(owner(), asset.balanceOf(address(this)));
    }

    /// @dev Internal Functions

    function _stake(uint256 tokenId) internal {
        UserInfo storage user = userInfo[_msgSender()];
        NFTInfo storage nft = nftInfo[tokenId];

        (uint8 nftType, ) = nftContract.getNFTMetadata(tokenId);
        IERC721(address(nftContract)).safeTransferFrom(_msgSender(), address(this), tokenId);
        if (nftType == 0) {
            user.stakedSoldiers.push(tokenId);
            stakedSoldiers.push(tokenId);
        } else if (nftType == 1) {
            user.stakedOfficers.push(tokenId);
            stakedOfficers.push(tokenId);
            _add(tokenId);
        } else if (nftType == 2) {
            user.stakedGenerals.push(tokenId);
            stakedGenerals.push(tokenId);
        } else {
            revert('Token metadata is unreachable');
        }
        nft.owner = _msgSender();
        nft.nftType = nftType;
        nft.depositTime = block.timestamp;
        nft.lastHarvest = block.timestamp;
    }

    function _unstake(uint256 tokenId) internal {
        _harvestUnstake(tokenId);
        UserInfo storage user = userInfo[_msgSender()];
        NFTInfo storage nft = nftInfo[tokenId];
        require(nft.owner == _msgSender(), 'Caller is not the owner');
        bool found;
        if (nft.nftType == 0) {
            for (uint256 i = 0; i < user.stakedSoldiers.length; i++) {
                if (user.stakedSoldiers[i] == tokenId) {
                    for (uint256 x = i; x < user.stakedSoldiers.length - 1; x++) {
                        user.stakedSoldiers[x] = user.stakedSoldiers[x + 1];
                    }
                    user.stakedSoldiers.pop();
                    found = true;
                }
            }
            for (uint256 i = 0; i < stakedSoldiers.length; i++) {
                if (stakedSoldiers[i] == tokenId) {
                    for (uint256 x = i; x < stakedSoldiers.length - 1; x++) {
                        stakedSoldiers[x] = stakedSoldiers[x + 1];
                    }
                    stakedSoldiers.pop();
                }
            }
        } else if (nft.nftType == 1) {
            for (uint256 i = 0; i < user.stakedOfficers.length; i++) {
                if (user.stakedOfficers[i] == tokenId) {
                    for (uint256 x = i; x < user.stakedOfficers.length - 1; x++) {
                        user.stakedOfficers[x] = user.stakedOfficers[x + 1];
                    }
                    user.stakedOfficers.pop();
                    found = true;
                }
            }
            for (uint256 i = 0; i < stakedOfficers.length; i++) {
                if (stakedOfficers[i] == tokenId) {
                    for (uint256 x = i; x < stakedOfficers.length - 1; x++) {
                        stakedOfficers[x] = stakedOfficers[x + 1];
                    }
                    stakedOfficers.pop();
                }
            }
            _remove(tokenId);
        } else if (nft.nftType == 2) {
            for (uint256 i = 0; i < user.stakedGenerals.length; i++) {
                if (user.stakedGenerals[i] == tokenId) {
                    for (uint256 x = i; x < user.stakedGenerals.length - 1; x++) {
                        user.stakedGenerals[x] = user.stakedGenerals[x + 1];
                    }
                    user.stakedGenerals.pop();
                    found = true;
                }
            }
            for (uint256 i = 0; i < stakedGenerals.length; i++) {
                if (stakedGenerals[i] == tokenId) {
                    for (uint256 x = i; x < stakedGenerals.length - 1; x++) {
                        stakedGenerals[x] = stakedGenerals[x + 1];
                    }
                    stakedGenerals.pop();
                }
            }
        } else {
            revert('Token metadata is unreachable');
        }

        nft.owner = address(0);
        require(found, 'Error');
        IERC721(address(nftContract)).safeTransferFrom(address(this), _msgSender(), tokenId);
    }

    function _harvestNormal(uint256 tokenId) internal {
        NFTInfo storage nft = nftInfo[tokenId];
        require(nft.owner == _msgSender(), 'Caller is not token staker');
        if (farmStartDate != 0 && farmStartDate <= block.timestamp) {
            uint256 pendingReward_;
            uint256 timeDiff;
            if (farmStartDate > nft.lastHarvest) {
                timeDiff = block.timestamp - farmStartDate;
            } else {
                timeDiff = block.timestamp - nft.lastHarvest;
            }
            if (nft.nftType == 0) {
                pendingReward_ = _pendingSoldiersReward(tokenId);
                if (
                    stakedOfficers.length > 0 &&
                    userInfo[_msgSender()].stakedGenerals.length == 0 &&
                    pendingReward_ < 30000 * 10**18
                ) {
                    uint256 tax = (pendingReward_ * 2) / 10;
                    pendingReward_ -= tax;
                    distributeDividends(tax);
                }
            } else if (nft.nftType == 1) {
                withdrawDividend(tokenId);
            } else if (nft.nftType == 2) {
                pendingReward_ = (timeDiff * generalReward) / DAY;
            } else {
                revert('Token metadata is unreachable');
            }
            nft.lastHarvest = block.timestamp;
            nft.amountStolen = 0;
            if (pendingReward_ > 0) {
                totalFarmed += pendingReward_;
                token.safeTransfer(_msgSender(), pendingReward_);
            }
        }
    }

    function _harvestUnstake(uint256 tokenId) internal {
        NFTInfo storage nft = nftInfo[tokenId];
        require(nft.owner == _msgSender(), 'Caller is not token staker');
        if (farmStartDate != 0 && farmStartDate <= block.timestamp) {
            uint256 pendingReward_;
            uint256 timeDiff;
            if (farmStartDate > nft.lastHarvest) {
                timeDiff = block.timestamp - farmStartDate;
            } else {
                timeDiff = block.timestamp - nft.lastHarvest;
            }
            if (nft.nftType == 0) {
                pendingReward_ = _pendingSoldiersReward(tokenId);
                require(pendingReward_ >= 30000 * 10**18, '30000 tokens were not farmed yet');
                if (stakedOfficers.length > 0) {
                    uint256 _probability = uint256(
                        keccak256(abi.encodePacked(blockhash(block.number), tx.origin, block.timestamp))
                    ) % 100000;

                    if (_probability < 35000) {
                        uint256 tax = (pendingReward_ * 5) / 10;
                        pendingReward_ -= tax;
                        distributeDividends(tax);
                    }
                }
            } else if (nft.nftType == 1) {
                withdrawDividend(tokenId);
            } else if (nft.nftType == 2) {
                pendingReward_ = (timeDiff * generalReward) / DAY;
            }
            nft.lastHarvest = block.timestamp;
            nft.amountStolen = 0;
            if (pendingReward_ > 0) {
                totalFarmed += pendingReward_;
                token.safeTransfer(nftInfo[tokenId].owner, pendingReward_);
            }
        }
    }

    function _pendingReward(address _address) internal view returns (uint256 pendingReward_) {
        UserInfo storage user = userInfo[_address];
        if (user.stakedSoldiers.length > 0) {
            for (uint256 i = 0; i < user.stakedSoldiers.length; i++) {
                pendingReward_ += _pendingSoldiersReward(user.stakedSoldiers[i]);
            }
        }
        if (user.stakedOfficers.length > 0) {
            for (uint256 i = 0; i < user.stakedOfficers.length; i++) {
                pendingReward_ += _pendingOfficersReward(user.stakedOfficers[i]);
            }
        }
        if (user.stakedGenerals.length > 0) {
            for (uint256 i = 0; i < user.stakedGenerals.length; i++) {
                pendingReward_ += _pendingGeneralsReward(user.stakedGenerals[i]);
            }
        }
    }

    function _pendingSoldiersReward(uint256 tokenId) internal view returns (uint256) {
        if (farmStartDate == 0 || farmStartDate > block.timestamp) {
            return 0;
        }
        NFTInfo storage nft = nftInfo[tokenId];
        if (nft.owner != address(0)) {
            uint256 timeDiff;
            if (farmStartDate > nft.lastHarvest) {
                timeDiff = block.timestamp - farmStartDate;
            } else {
                timeDiff = block.timestamp - nft.lastHarvest;
            }
            return (timeDiff * soldierReward) / DAY - nft.amountStolen;
        } else {
            return 0;
        }
    }

    function _pendingOfficersReward(uint256 tokenId) internal view returns (uint256) {
        return dividendOf(tokenId);
    }

    function _pendingGeneralsReward(uint256 tokenId) internal view returns (uint256) {
        if (farmStartDate == 0 || farmStartDate > block.timestamp) {
            return 0;
        }
        NFTInfo storage nft = nftInfo[tokenId];
        if (nft.owner != address(0)) {
            uint256 timeDiff;
            if (farmStartDate > nft.lastHarvest) {
                timeDiff = block.timestamp - farmStartDate;
            } else {
                timeDiff = block.timestamp - nft.lastHarvest;
            }
            return (timeDiff * generalReward) / DAY;
        } else {
            return 0;
        }
    }

    function _retrieveStolenNFTs() internal {
        if (stakedOfficers.length > 0) {
            (bool returned, uint256[] memory _stolenNFTs) = nftContract.retrieveStolenNFTs();
            if (returned) {
                for (uint256 i = 0; i < _stolenNFTs.length; i++) {
                    uint256 _luckyWinner = uint256(
                        keccak256(abi.encodePacked(blockhash(block.number), tx.origin, block.timestamp, i))
                    ) % stakedOfficers.length;
                    uint256 winId = stakedOfficers[_luckyWinner];
                    address winner = nftInfo[winId].owner;
                    IERC721(address(nftContract)).safeTransferFrom(address(this), winner, _stolenNFTs[i]);
                }
            }
        }
    }

    function _stealReward(UserInfo storage user) internal {
        uint256 _randomSoldier = uint256(
            keccak256(abi.encodePacked(blockhash(block.number), tx.origin, block.timestamp + 20))
        ) % stakedSoldiers.length;

        uint256 tokenId = stakedSoldiers[_randomSoldier];
        address owner = nftInfo[tokenId].owner;
        uint256 totalStolenReward;
        for (uint256 i = 0; i < userInfo[owner].stakedSoldiers.length; i++) {
            uint256 stolenReward;
            tokenId = userInfo[owner].stakedSoldiers[i];
            if (user.stakedGenerals.length > 0) {
                stolenReward = (_pendingSoldiersReward(tokenId) * 5) / 10;
                totalStolenReward += stolenReward;
            } else {
                stolenReward = (_pendingSoldiersReward(tokenId) * 3) / 10;
                totalStolenReward += stolenReward;
            }
            nftInfo[tokenId].amountStolen += stolenReward;
        }
        totalFarmed += totalStolenReward;
        token.safeTransfer(_msgSender(), totalStolenReward);
    }

    /// @dev Officers Staking

    uint256 internal constant magnitude = 2**128;

    uint256 internal magnifiedDividendPerShare;

    mapping(uint256 => int256) internal magnifiedDividendCorrections;
    mapping(uint256 => uint256) internal withdrawnDividends;

    function distributeDividends(uint256 amount) internal {
        require(stakedOfficers.length > 0);

        magnifiedDividendPerShare = magnifiedDividendPerShare.add((amount).mul(magnitude) / stakedOfficers.length);
    }

    function withdrawDividend(uint256 tokenId) internal {
        require(nftInfo[tokenId].owner == _msgSender(), 'Caller is not the staker');
        uint256 _withdrawableDividend = withdrawableDividendOf(tokenId);
        if (_withdrawableDividend > 0) {
            withdrawnDividends[tokenId] = withdrawnDividends[tokenId].add(_withdrawableDividend);
            token.safeTransfer(_msgSender(), _withdrawableDividend);
        }
    }

    function dividendOf(uint256 tokenId) internal view returns (uint256) {
        return withdrawableDividendOf(tokenId);
    }

    function withdrawableDividendOf(uint256 tokenId) internal view returns (uint256) {
        return accumulativeDividendOf(tokenId).sub(withdrawnDividends[tokenId]);
    }

    function withdrawnDividendOf(uint256 tokenId) internal view returns (uint256) {
        return withdrawnDividends[tokenId];
    }

    function accumulativeDividendOf(uint256 tokenId) internal view returns (uint256) {
        return
            magnifiedDividendPerShare.toInt256Safe().add(magnifiedDividendCorrections[tokenId]).toUint256Safe() /
            magnitude;
    }

    function _add(uint256 tokenId) internal {
        magnifiedDividendCorrections[tokenId] = magnifiedDividendCorrections[tokenId].sub(
            (magnifiedDividendPerShare).toInt256Safe()
        );
    }

    function _remove(uint256 tokenId) internal {
        magnifiedDividendCorrections[tokenId] = magnifiedDividendCorrections[tokenId].add(
            (magnifiedDividendPerShare).toInt256Safe()
        );
    }

    event Received();

    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes calldata _data
    ) external override returns (bytes4) {
        _operator;
        _from;
        _tokenId;
        _data;
        emit Received();
        return 0x150b7a02;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional metadata extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Metadata is IERC721 {
    /**
     * @dev Returns the token collection name.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the token collection symbol.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the Uniform Resource Identifier (URI) for `tokenId` token.
     */
    function tokenURI(uint256 tokenId) external view returns (string memory);
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
// OpenZeppelin Contracts (last updated v4.6.0) (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

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
        return a + b;
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
        return a - b;
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
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
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
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
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
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
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
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
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