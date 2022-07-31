//  ________  ___       ___  ___  ________  ________  ________  ________  _______
// |\   ____\|\  \     |\  \|\  \|\   __  \|\   __  \|\   __  \|\   __  \|\  ___ \
// \ \  \___|\ \  \    \ \  \\\  \ \  \|\ /\ \  \|\  \ \  \|\  \ \  \|\  \ \   __/|
//  \ \  \    \ \  \    \ \  \\\  \ \   __  \ \   _  _\ \   __  \ \   _  _\ \  \_|/__
//   \ \  \____\ \  \____\ \  \\\  \ \  \|\  \ \  \\  \\ \  \ \  \ \  \\  \\ \  \_|\ \
//    \ \_______\ \_______\ \_______\ \_______\ \__\\ _\\ \__\ \__\ \__\\ _\\ \_______\
//     \|_______|\|_______|\|_______|\|_______|\|__|\|__|\|__|\|__|\|__|\|__|\|_______|
//
// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./interfaces/ILLC.sol";
import "./interfaces/ILLCTier.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract LLCStorage is Ownable {
    enum LLCTier {
        NONE,
        LEGENDARY,
        SUPER_RARE,
        RARE,
        COMMON
    }

    /// @dev LLC NFT contract
    address public LLC;

    /// @dev LLC NFT Tier contract
    address public LLC_TIER;

    /// @dev Legendary Token Ids
    uint256[] public legendaryTokenIds;

    /// @dev Super Rare Token Ids
    uint256[] public superRareTokenIds;

    /// @dev Rare Token Ids
    uint256[] public rareTokenIds;

    /// @dev Common TokenIds
    uint256[] public commonTokenIds;

    /// @dev TokenIds
    uint256[] public allTokenIds;

    /// @dev Available LLC Supply
    uint80 public availableSupply;

    /// @dev Available Legendary LLC Supply
    uint32 public legendaryAvailableSupply;

    /// @dev Available SuperRare LLC Supply
    uint32 public superRareAvailableSupply;

    /// @dev Available Rare LLC Supply
    uint32 public rareAvailableSupply;

    /// @dev Available Common LLC Supply
    uint80 public commonAvailableSupply;

    /// @dev Minters
    mapping(address => bool) public minters;

    /// @dev Legendary Token Index by tokenId
    mapping(uint256 => uint256) public legendaryTokenIndexes;

    /// @dev Super Rare Token Index by tokenId
    mapping(uint256 => uint256) public superRareTokenIndexes;

    /// @dev Rare Token Index by tokenId
    mapping(uint256 => uint256) public rareTokenIndexes;

    /// @dev Common Token Index by tokenId
    mapping(uint256 => uint256) public commonTokenIndexes;

    /// @dev All Token Index by tokenId
    mapping(uint256 => uint256) public allTokenIndexes;

    constructor(address _llc, address _llcTier) {
        LLC = _llc;
        LLC_TIER = _llcTier;
    }

    /// @dev Update Token Index
    function _updateAllTokenIndex(uint256 _tokenId) private {
        uint256 allTokenIndex = allTokenIndexes[_tokenId];
        if (allTokenIndex < availableSupply - 1) {
            uint256 nextTokenId = allTokenIds[availableSupply - 1];
            allTokenIds[allTokenIndex] = nextTokenId;
            allTokenIndexes[nextTokenId] = allTokenIndex;
        }

        availableSupply--;
    }

    /// @dev Update Legendary Token Index
    function _updateLegendaryTokenIndex(uint256 _tokenId) private {
        uint256 tokenIndex = legendaryTokenIndexes[_tokenId];
        uint32 length = legendaryAvailableSupply - 1;
        if (tokenIndex < length) {
            uint256 nextTokenId = legendaryTokenIds[length];
            legendaryTokenIds[tokenIndex] = nextTokenId;
            legendaryTokenIndexes[nextTokenId] = tokenIndex;
        }

        legendaryAvailableSupply = length;
    }

    /// @dev Update SuperRare Token Index
    function _updateSuperRareTokenIndex(uint256 _tokenId) private {
        uint256 tokenIndex = superRareTokenIndexes[_tokenId];
        uint32 length = superRareAvailableSupply - 1;
        if (tokenIndex < length) {
            uint256 nextTokenId = superRareTokenIds[length];
            superRareTokenIds[tokenIndex] = nextTokenId;
            superRareTokenIndexes[nextTokenId] = tokenIndex;
        }

        superRareAvailableSupply = length;
    }

    /// @dev Update Rare Token Index
    function _updateRareTokenIndex(uint256 _tokenId) private {
        uint256 tokenIndex = rareTokenIndexes[_tokenId];
        uint32 length = rareAvailableSupply - 1;
        if (tokenIndex < length) {
            uint256 nextTokenId = rareTokenIds[length];
            rareTokenIds[tokenIndex] = nextTokenId;
            rareTokenIndexes[nextTokenId] = tokenIndex;
        }

        rareAvailableSupply = length;
    }

    /// @dev Update Common Token Index
    function _updateCommonTokenIndex(uint256 _tokenId) private {
        uint256 tokenIndex = commonTokenIndexes[_tokenId];
        uint32 length = rareAvailableSupply - 1;
        if (tokenIndex < length) {
            uint256 nextTokenId = commonTokenIds[length];
            commonTokenIds[tokenIndex] = nextTokenId;
            commonTokenIndexes[nextTokenId] = tokenIndex;
        }

        commonAvailableSupply = length;
    }

    /// @dev Mint LLC
    function _mint(bool _isRandomized) private returns (uint256 tokenId) {
        require(availableSupply > 0, "Not available LLC");

        uint256 tokenIndex = 0;
        if (_isRandomized) {
            tokenIndex = getRandomNumber() % availableSupply;
        }
        tokenId = allTokenIds[tokenIndex];

        _updateAllTokenIndex(tokenId);

        uint256 tier = getLLCTier().LLCRarities(tokenId);
        if (tier == getLLCTier().LEGENDARY_RARITY()) {
            _updateLegendaryTokenIndex(tokenId);
            return tokenId;
        }

        if (tier == getLLCTier().SUPER_RARE_RARITY()) {
            _updateSuperRareTokenIndex(tokenId);
            return tokenId;
        }

        if (tier == getLLCTier().RARE_RARITY()) {
            _updateRareTokenIndex(tokenId);
            return tokenId;
        }

        _updateCommonTokenIndex(tokenId);
    }

    /// @dev Mint Legendary LLC
    function _mintLegendary(bool _isRandomized)
        private
        returns (uint256 tokenId)
    {
        require(legendaryAvailableSupply > 0, "No more Legendary LLC");

        uint256 tokenIndex = 0;
        if (_isRandomized) {
            tokenIndex = getRandomNumber() % legendaryAvailableSupply;
        }
        tokenId = legendaryTokenIds[tokenIndex];

        _updateAllTokenIndex(tokenId);
        _updateLegendaryTokenIndex(tokenId);
    }

    /// @dev Mint Super Rare LLC
    function _mintSuperRare(bool _isRandomized)
        private
        returns (uint256 tokenId)
    {
        require(superRareAvailableSupply > 0, "No more SuperRare LLC");

        uint256 tokenIndex = 0;
        if (_isRandomized) {
            tokenIndex = getRandomNumber() % superRareAvailableSupply;
        }
        tokenId = superRareTokenIds[tokenIndex];

        _updateAllTokenIndex(tokenId);
        _updateSuperRareTokenIndex(tokenId);
    }

    /// @dev Mint Rare LLC
    function _mintRare(bool _isRandomized)
        private
        returns (uint256 tokenId)
    {
        require(rareAvailableSupply > 0, "No more Rare LLC");

        uint256 tokenIndex = 0;
        if (_isRandomized) {
            tokenIndex = getRandomNumber() % rareAvailableSupply;
        }
        tokenId = rareTokenIds[tokenIndex];

        _updateAllTokenIndex(tokenId);
        _updateRareTokenIndex(tokenId);
    }

    /// @dev Mint Common LLC
    function _mintCommon(bool _isRandomized)
        private
        returns (uint256 tokenId)
    {
        require(commonAvailableSupply > 0, "No more Common LLC");

        uint256 tokenIndex = 0;
        if (_isRandomized) {
            tokenIndex = getRandomNumber() % commonAvailableSupply;
        }
        tokenId = commonTokenIds[tokenIndex];

        _updateAllTokenIndex(tokenId);
        _updateCommonTokenIndex(tokenId);
    }

    /// @dev Register TokenId
    function registerTokenId(uint256 _tokenId) public onlyOwner {
        uint256 tokenId = _tokenId;

        allTokenIds.push(tokenId);
        allTokenIndexes[tokenId] = availableSupply;
        availableSupply++;

        uint256 tier = getLLCTier().LLCRarities(tokenId);
        if (tier == getLLCTier().LEGENDARY_RARITY()) {
            legendaryTokenIds.push(tokenId);
            legendaryTokenIndexes[tokenId] = legendaryAvailableSupply;
            legendaryAvailableSupply++;
            return;
        }

        if (tier == getLLCTier().SUPER_RARE_RARITY()) {
            superRareTokenIds.push(tokenId);
            superRareTokenIndexes[tokenId] = superRareAvailableSupply;
            superRareAvailableSupply++;
            return;
        }

        if (tier == getLLCTier().RARE_RARITY()) {
            rareTokenIds.push(tokenId);
            rareTokenIndexes[tokenId] = rareAvailableSupply;
            rareAvailableSupply++;
            return;
        }

        commonTokenIds.push(tokenId);
        commonTokenIndexes[tokenId] = commonAvailableSupply;
        commonAvailableSupply++;
    }

    /// @dev Mint LLC
    function mint(uint256 _amount) external onlyOwner {
        uint256 amount = _amount;
        uint256 prevSupply = getLLC().mintedTotalSupply();
        getLLC().mint(address(this), amount);

        uint256 afterSupply = getLLC().mintedTotalSupply();
        require(afterSupply - prevSupply == amount, "Not minted yet");

        for (uint256 i = prevSupply; i < afterSupply; i++) {
            uint256 tokenId = getLLC().tokenByIndex(i);
            registerTokenId(tokenId);
        }
    }

    /// @dev Mint LLC by tier
    function mintByTier(LLCTier _tier, bool _isRandomized) external onlyMinter returns (uint256) {
        LLCTier tier = _tier;
        if (tier == LLCTier.LEGENDARY) {
            return _mintLegendary(_isRandomized);
        }
        if (tier == LLCTier.SUPER_RARE) {
            return _mintSuperRare(_isRandomized);
        }
        if (tier == LLCTier.RARE) {
            return _mintRare(_isRandomized);
        }
        if (tier == LLCTier.COMMON) {
            return _mintCommon(_isRandomized);
        }

        return _mint(_isRandomized);
    }

    /// @dev Set LLC contract address
    function setLLC(address _llc) external onlyOwner {
        LLC = _llc;
    }

    /// @dev Set LLCTier contract address
    function setLLCTier(address _llcTier) external onlyOwner {
        LLC_TIER = _llcTier;
    }

    /// @dev Add minter address
    function addMinter(address _minter) external onlyOwner {
        require(!minters[_minter], "Already added");
        minters[_minter] = true;
    }

    /// @dev Remove minter address
    function removeMinter(address _minter) external onlyOwner {
        require(minters[_minter], "Not added");
        minters[_minter] = false;
    }

    /// @dev Get LLC contract address
    function getLLC() public view returns (ILLC) {
        return ILLC(LLC);
    }

    /// @dev Get LLCTier contract address
    function getLLCTier() public view returns (ILLCTier) {
        return ILLCTier(LLC_TIER);
    }

    function getRandomNumber() public view returns (uint256) {
        return
            uint256(
                keccak256(
                    abi.encodePacked(_msgSender(), block.number, block.coinbase)
                )
            );
    }

    modifier onlyMinter() {
        require(minters[_msgSender()], "LLCStorage: Only minter can call");
        _;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface ILLC {
    function mint(address, uint256) external;

    function totalSupply() external view returns (uint256);

    function tokenCount() external view returns (uint256);

    function mintedTotalSupply() external view returns (uint256);

    function tokenByIndex(uint256) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface ILLCTier {
    function LEGENDARY_RARITY() external returns (uint256);

    function SUPER_RARE_RARITY() external returns (uint256);

    function RARE_RARITY() external returns (uint256);

    function LLCRarities(uint256) external returns (uint256);
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