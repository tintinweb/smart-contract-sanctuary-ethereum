// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/INftGenerator.sol";
import "./interfaces/ICreature.sol";
import "./interfaces/IRandomizer.sol";
import "./interfaces/IProtectionProgram.sol";

/// @title Is responsible for NFTs generation
contract NftGenerator is INftGenerator, Ownable {
    ICreature public creatureContract;
    IRandomizer private randomizerContract;
    IProtectionProgram private protectionProgramContract;

    /// @dev START storage for group
    uint256[] public groupToNftCounts;
    uint256[] public groupToNftPrices;
    address[] public groupToPaymentTokens;
    uint8[] public groupToNftGen;
    /// @dev END storage for group

    struct Chance {
        uint128 toMintBanker;
        uint128 toStealOnMint;
    }

    /// @notice Contain chances information
    Chance public chances;

    constructor(
        ICreature _creatureContract,
        IRandomizer _randomizerContract,
        IProtectionProgram _protectionProgramContract
    ) {
        creatureContract = _creatureContract;
        randomizerContract = _randomizerContract;
        protectionProgramContract = _protectionProgramContract;
    }

    modifier onlyEOA() {
        address _sender = msg.sender;
        require(_sender == tx.origin, "onlyEOA: invalid sender (1).");

        uint256 size;
        assembly {
            size := extcodesize(_sender)
        }
        require(size == 0, "onlyEOA: invalid sender (2).");

        _;
    }

    /// @notice When new token minted, it can be stolen. Set steal on mint chance.
    /// @param _chanceToStealOnMint Chance. Where 10^27 = 100%.
    function setStealOnMintChance(uint128 _chanceToStealOnMint) external override onlyOwner {
        require(
            _chanceToStealOnMint > 0 && _chanceToStealOnMint < _getDecimals(),
            "NftGenerator: invalid steal chance."
        );

        chances.toStealOnMint = _chanceToStealOnMint;
    }

    /// @notice When new token minted, it can be a banker. Set mint banker chance
    /// @param _chanceToMintBanker Chance. Where 10^27 = 100%
    function setMintBankerChance(uint128 _chanceToMintBanker) external override onlyOwner {
        require(
            _chanceToMintBanker > 0 && _chanceToMintBanker < _getDecimals(),
            "NftGenerator: invalid mint banker chance."
        );

        chances.toMintBanker = _chanceToMintBanker;
    }

    /// @notice Setting the data by which new nfts will be generated.
    /// @dev If set as payment token zero address, payment will be for a native token.
    /// @param _groupToNftCounts [100, 235...]. First group: 1-100, second group: 101-235...
    /// @param _groupToNftPrices [1*10^18, 2*10^18]. First group price per nft: 1*10^18...
    /// @param _groupToPaymentTokens ['0xa4fas...', '0x00000...']. Group payment token
    /// @param _groupToNftGen [0, 4]. Generation number.
    function setGroups(
        uint256[] calldata _groupToNftCounts,
        uint256[] calldata _groupToNftPrices,
        address[] calldata _groupToPaymentTokens,
        uint8[] calldata _groupToNftGen
    ) external override onlyOwner {
        require(_groupToNftCounts.length > 0, "NftGenerator: arrays is empty.");
        require(
            _groupToNftCounts.length == _groupToNftPrices.length &&
            _groupToNftCounts.length == _groupToNftGen.length &&
            _groupToNftCounts.length == _groupToPaymentTokens.length,
            "NftGenerator: different array length."
        );

        delete groupToNftCounts;
        delete groupToNftPrices;
        delete groupToNftGen;
        delete groupToPaymentTokens;

        for (uint256 i = 0; i < _groupToNftCounts.length; i++) {
            require(_groupToNftCounts[i] != 0, "NftGenerator: nft count can't be a zero.");

            if (i > 0) require(_groupToNftCounts[i] > _groupToNftCounts[i - 1],
                "NftGenerator: each next value should be bigger then previous.");

            groupToNftCounts.push(_groupToNftCounts[i]);
            groupToNftPrices.push(_groupToNftPrices[i]);
            groupToNftGen.push(_groupToNftGen[i]);
            groupToPaymentTokens.push(_groupToPaymentTokens[i]);
        }

        emit GroupsSetUp(_groupToNftCounts, groupToNftPrices, groupToNftGen, _groupToPaymentTokens);
    }

    /// @notice Return group length
    function getGroupLength() external view override returns (uint256) {
        return groupToNftCounts.length;
    }

    /// @notice Mint new nfts
    /// @param _to Nft receiver
    /// @param _amount Nft amount
    function mint(address _to, uint256 _amount) external payable override onlyEOA {
        ICreature _creatureContract = creatureContract;
        IRandomizer _randomizerContract = randomizerContract;
        IProtectionProgram _protectionProgramContract = protectionProgramContract;

        uint256 _currentNftNum = _creatureContract.totalSupply();
        uint256[] memory _groupToNftCounts = groupToNftCounts;

        uint256 _maxNftCount = _groupToNftCounts[_groupToNftCounts.length - 1];
        if (_currentNftNum + _amount > _maxNftCount) _amount = _maxNftCount - _currentNftNum;
        require(_amount > 0, "NftGenerator: nfts limit has been reached.");

        uint8[] memory _groupToNftGen = groupToNftGen;
        uint256[] memory _nftCountToGenerateInGroup = new uint256[](_groupToNftCounts.length);

        Chance memory _chances = chances;

        for (uint256 i = 0; i < _amount; i++) {
            _currentNftNum++;
            uint256 _groupNum = _getGroupNumberByNftNumber(_groupToNftCounts, _currentNftNum);

            _mintProcess(
                _to,
                _currentNftNum,
                _groupToNftGen[_groupNum],
                _chances,
                _creatureContract,
                _randomizerContract,
                _protectionProgramContract
            );

            _nftCountToGenerateInGroup[_groupNum]++;
        }

        _paymentProcess(_nftCountToGenerateInGroup);
    }

    /// @notice Withdraw native token from contract
    /// @param _to Token receiver
    function withdrawNative(address _to) external override onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    /// @notice Transfer stuck ERC20 tokens.
    /// @param _token Token address
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function withdrawStuckERC20(
        IERC20 _token,
        address _to,
        uint256 _amount
    ) external override onlyOwner {
        _token.transfer(_to, _amount);
    }

    /// @dev Mint new nft
    function _mintProcess(
        address _to,
        uint256 _num,
        uint8 _gen,
        Chance memory _chances,
        ICreature _creatureContract,
        IRandomizer _randomizerContract,
        IProtectionProgram _protectionProgramContract
    ) private {
        if (_randomizerContract.random(_getDecimals()) < _chances.toStealOnMint) {
            address _recipient = _protectionProgramContract.getRandomRebel();

            if (_recipient != address(0)) {
                _creatureContract.safeMint(_recipient, _num);
                if (_to != _recipient) {
                    emit CreatureStolen(_num, _to, _recipient);
                    _to = _recipient;
                }
            } else {
                _creatureContract.safeMint(_to, _num);
            }
        } else {
            _creatureContract.safeMint(_to, _num);
        }

        if (_randomizerContract.random(_getDecimals()) < _chances.toMintBanker) {
            _creatureContract.addBankerInfo(_num, _gen, _randomizerContract.random(_getDecimals()));
            emit BankerCreated(_num, _to);
        } else {
            _creatureContract.addRebelInfo(_num, uint8(5 + _randomizerContract.random(4)),
                _randomizerContract.random(_getDecimals()));
            emit RebelCreated(_num, _to);
        }
    }

    /// @dev Calculate payment amount and pay
    function _paymentProcess(uint256[] memory _nftCountToGenerateInGroup) private {
        uint256 _nativePrice;
        for (uint256 i = 0; i < _nftCountToGenerateInGroup.length; i++) {
            uint256 _totalPrice = groupToNftPrices[i] * _nftCountToGenerateInGroup[i];
            if (_totalPrice == 0) continue;

            address _paymentTokenAddress = groupToPaymentTokens[i];
            if (_paymentTokenAddress == address(0)) {
                _nativePrice += _totalPrice;
            } else {
                IERC20(_paymentTokenAddress).transferFrom(msg.sender, address(this), _totalPrice);
            }
        }

        if (_nativePrice > 0) {
            require(msg.value >= _nativePrice, "NftGenerator: insufficient funds for payment.");
            if (msg.value > _nativePrice) {
                payable(msg.sender).transfer(msg.value - _nativePrice);
            }
        }
    }

    /// @dev Detect group number by nft number
    function _getGroupNumberByNftNumber(uint256[] memory _groupToNftCounts, uint256 _nftNumber)
        private
        pure
        returns (uint256)
    {
        uint256 _groupNumber;
        for (uint256 i = 0; i < _groupToNftCounts.length; i++) {
            if (_groupToNftCounts[i] < _nftNumber) continue;

            _groupNumber = i;
            break;
        }

        return _groupNumber;
    }

    /// @dev Decimals for number.
    function _getDecimals() internal pure returns (uint256) {
        return 10**27;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

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
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

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
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
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
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for NftGenerator contract
interface INftGenerator {
    event GroupsSetUp(uint256[] nftCounts, uint256[] nftPrices, uint8[] nftGen, address[] groupToPaymentTokens);
    event BankerCreated(uint256 num, address recipient);
    event RebelCreated(uint256 num, address recipient);
    event CreatureStolen(uint256 num, address intendedRecipient, address actualRecipient);

    /// @notice When new token minted, it can be stolen. Set steal on mint chance
    /// @param _chanceToStealOnMint Chance. Where 10^27 = 100%
    function setStealOnMintChance(uint128 _chanceToStealOnMint) external;

    /// @notice When new token minted, it can be a banker. Set mint banker chance
    /// @param _chanceToMintBanker Chance. Where 10^27 = 100%
    function setMintBankerChance(uint128 _chanceToMintBanker) external;

    /// @notice Setting the data by which new nfts will be generated
    /// @dev If set as payment token zero address, payment will be for a native token
    /// @param _groupToNftCounts [100, 235...]. First group: 1-100, second group: 101-235...
    /// @param _groupToNftPrices [1*10^18, 2*10^18]. First group price per nft: 1*10^18...
    /// @param _groupToPaymentTokens ['0xa4fas...', '0x00000...']. Group payment token
    /// @param _groupToNftGen [0, 4]. Generation number
    function setGroups(
        uint256[] calldata _groupToNftCounts,
        uint256[] calldata _groupToNftPrices,
        address[] calldata _groupToPaymentTokens,
        uint8[] calldata _groupToNftGen
    ) external;

    /// @notice Return group length
    function getGroupLength() external view returns (uint256);

    /// @notice Mint new nfts
    /// @param _to Nft receiver
    /// @param _amount Nft amount
    function mint(address _to, uint256 _amount) external payable;

    /// @notice Withdraw native token from contract
    /// @param _to Token receiver
    function withdrawNative(address _to) external;

    /// @notice Transfer stuck ERC20 tokens.
    /// @param _token Token address
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function withdrawStuckERC20(IERC20 _token, address _to, uint256 _amount) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

/// @title Interface for Creature contract
interface ICreature is IERC721Enumerable {
    enum CreatureType { Banker, Rebel }

    /// @notice Once set generator address.
    /// @param _generator Address.
    function setGeneratorAddress(address _generator) external;

    /// @notice Mint new NFT.
    /// @param _to Address.
    /// @param _num NFT number.
    function safeMint(address _to, uint256 _num) external;

    /// @notice Add information about Banker.
    /// @param _num NFT number.
    /// @param _gen NFT generation.
    /// @param _rand Random num.
    function addBankerInfo(uint256 _num, uint8 _gen, uint256 _rand) external;

    /// @notice Add information about Rebel.
    /// @param _num NFT number.
    /// @param _tenureScore Tenure score.
    /// @param _rand Random num.
    function addRebelInfo(uint256 _num, uint8 _tenureScore, uint256 _rand) external;

    /// @notice Get information about Banker.
    /// @param _num NFT number.
    function getBankerInfo(uint256 _num) external view returns (
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8,
        uint8
    );

    /// @notice Get information about Rebel.
    /// @param _num Rebel number.
    function getRebelInfo(uint256 _num) external view returns (uint8, uint8, uint8, uint8, uint8);

    /// @notice Get total Rebels count.
    function getRebelsCount() external view returns (uint256);

    /// @notice Set base URI for nfts.
    /// @param _baseUri String.
    function setBaseUri(string memory _baseUri) external;

    /// @notice Return array with nfts by owner.
    /// @param _address Address.
    /// @param _from Index from.
    /// @param _amount Nfts amount in array.
    function getNftsByOwner(address _address, uint256 _from, uint256 _amount) external view returns(uint256[] memory, bool[] memory);

    function isRebel(uint256 _index) external view returns (bool);

    function rebels(uint256 _index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title Interface for Randomizer contract
interface IRandomizer {
    /// @notice Get conventionally random number in range 0 <= _result < _maxNum
    /// @param _maxNum Maximal value
    function random(uint256 _maxNum) external returns (uint256 _result);

    /// @notice Get conventionally random number in range 0 <= _result < _maxNum. View.
    /// @param _maxNum Maximal value.
    /// @param _val Additional num.
    function random(uint256 _maxNum, uint256 _val) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title Interface for ProtectionProgram contract
interface IProtectionProgram {
    event BankerAdded(uint256 num);
    event RebelAdded(uint256 num);
    event BankerClaimed(uint256 num, bool isWithdrawn);
    event RebelClaimed(uint256 num, bool isWithdrawn);
    event TokensClaimed(uint256[] nums, bool isWithdrawn);

    /// @notice Set bankers reward for each second
    /// @param _bankerRewardPerSecond Reward per second. Wei
    function setBankerRewardPerSecond(uint256 _bankerRewardPerSecond) external;

    /// @notice Set tax percent for rebels. When bankers claim rewards, part of rewards (tax) are collected by the rebels
    /// @param _taxPercent Percent in decimals. Where 10^27 = 100%
    function setTaxPercent(uint128 _taxPercent) external;

    /// @notice When banker claim reward, rebels have a chance to steal all of them. Set this chance
    /// @param _stealOnWithdrawChance Chance. Where 10^27 = 100%
    function setStealOnWithdrawChance(uint128 _stealOnWithdrawChance) external;

    /// @notice Bankers can withdraw funds if they have not claim rewards for a certain period of time
    /// @param _withdrawLockupPeriod Time. Seconds
    function setWithdrawLockupPeriod(uint64 _withdrawLockupPeriod) external;

    /// @notice Add nfts to protection program
    /// @dev Will be added only existed nfts where sender is nft owner
    /// @param _nums Nfts nums
    function add(uint256[] calldata _nums) external;

    /// @notice Claim rewards for selected nfts
    /// @dev Sender should be nft owner. Nft should be in the protection program
    /// @param _nums Nfts nums
    function claim(uint256[] calldata _nums) external;

    /// @notice Claim rewards for selected nfts and withdraw from protection program
    /// @dev Sender should be nft owner. Nft should be in the protection program
    /// @param _nums Nfts nums
    function withdraw(uint256[] calldata _nums) external;

    /// @notice Calculate reward amount for nfts. On withdraw, part of reward can be stolen.
    /// @dev Sender should be nft owner. Nft should be in the protection program
    /// @param _nums Nfts nums
    /// @return bankersReward Rewards for all bankers
    /// @return rebelsReward Rewards for all rebels
    function calculateRewards(uint256[] calldata _nums) external view returns (
        uint256 bankersReward,
        uint256 rebelsReward
    );

    /// @notice Return address of random rebel owner, dependent on rebel tenure score.
    function getRandomRebel() external returns (address);

    /// @notice Withdraw native token from contract
    /// @param _to Token receiver
    function withdrawNative(address _to) external;

    /// @notice Transfer stuck ERC20 tokens.
    /// @param _token Token address
    /// @param _to Address 'to'
    /// @param _amount Token amount
    function withdrawStuckERC20(IERC20 _token, address _to, uint256 _amount) external;

    /// @notice Return array with nfts by owner.
    /// @param _address Address.
    /// @param _from Index from.
    /// @param _amount Nfts amount in array.
    function getNftsByOwner(address _address, uint256 _from, uint256 _amount) external view returns(uint256[] memory, bool[] memory);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move this token by either {approve} or {setApprovalForAll}.
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
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

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
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

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