// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/ICreature.sol";
import "./interfaces/IGenerator.sol";

/// @title This contract responsible for NFTs generation
contract Generator is IGenerator, Ownable {
    address public creatureAddress;

    Groups private __groups;

    constructor(address _creatureAddress) {
        creatureAddress = _creatureAddress;
    }

    modifier onlyEOA() {
        address _sender = msg.sender;
        require(_sender == tx.origin, "onlyEOA: invalid sender (1)");

        uint256 size;
        assembly {
            size := extcodesize(_sender)
        }
        require(size == 0, "onlyEOA: invalid sender (2)");

        _;
    }

    /**
     * @notice Setting the data by which new NFTs will be generated
     * @dev If set as payment token zero address, payment will be for a native token
     * @param _amounts [100, 235...]. First group: 1-100, second group: 101-235...
     * @param _prices [1*10^18, 2*10^18]. First group price per nft: 1*10^18...
     * @param _paymentTokens ['0xa4fas...', '0x00000...']. Group payment token
     */
    function setGroups(
        uint256[] calldata _amounts,
        uint256[] calldata _prices,
        address[] calldata _paymentTokens
    ) external onlyOwner {
        require(_amounts.length > 0, "Generator: arrays is empty");
        require(_amounts[0] > 0, "Generator: amount is zero");
        require(
            _amounts.length == _prices.length &&
            _amounts.length == _paymentTokens.length,
            "Generator: different arr length"
        );

        delete __groups;

        for (uint256 _i; _i < _amounts.length; _i++) {
            if (_i > 0) require(_amounts[_i] > _amounts[_i - 1], "Generator: invalid amount value");
        }

        __groups = Groups(_amounts, _prices, _paymentTokens);

        emit GroupsSetUp(_amounts, _prices, _paymentTokens);
    }

    /**
     * @notice Mint new NFTs
     * @param _to NFT recipient
     * @param _amount NFT amount to mint
     */
    function mint(address _to, uint256 _amount) external payable override onlyEOA {
        ICreature _creatureContract = ICreature(creatureAddress);

        uint256[] memory _groupAmounts = __groups.amounts;

        uint256 _maxAmount = _groupAmounts[_groupAmounts.length - 1];
        uint256 _mintedAmount = _creatureContract.totalSupply();

        if (_mintedAmount + _amount > _maxAmount) {
            _amount = _maxAmount - _mintedAmount;
        }

        require(_amount > 0, "Generator: nothing to mint");

        uint256 _nftNumToMint = _mintedAmount;
        uint256[] memory _generatedAmountInGroup = new uint256[](_groupAmounts.length);

        for (uint256 _i; _i < _amount; _i++) {
            _nftNumToMint++;

            uint256 _index = __getGroupIndexByNftNumber(_groupAmounts, _nftNumToMint);

            _creatureContract.safeMint(_to, _nftNumToMint);

            _generatedAmountInGroup[_index]++;
        }

        __paymentProcess(_generatedAmountInGroup);
    }

    /**
     * @notice Withdraw native tokens from contract
     */
    function withdrawNative(address _to) external override onlyOwner {
        payable(_to).transfer(address(this).balance);
    }

    /**
     * @notice Withdraw ERC20 tokens from contract
     */
    function withdrawERC20(IERC20 _token, address _to, uint256 _amount) external override onlyOwner {
        _token.transfer(_to, _amount);
    }

    /**
     * @notice Return groups info
     */
    function getGroups() external view override returns (uint256[] memory, uint256[] memory, address[] memory) {
        return (__groups.amounts, __groups.prices, __groups.paymentTokens);
    }

    /**
     * @dev Calculate payment amount and pay
     */
    function __paymentProcess(uint256[] memory _generatedAmountInGroup) private {
        uint256 _forNativePayment;

        for (uint256 _i; _i < _generatedAmountInGroup.length; _i++) {
            if (_generatedAmountInGroup[_i] == 0) continue;

            uint256 _totalGroupPrice = __groups.prices[_i] * _generatedAmountInGroup[_i];

            address _paymentTokenAddress = __groups.paymentTokens[_i];
            if (_paymentTokenAddress == address(0)) {
                _forNativePayment += _totalGroupPrice;
            } else {
                IERC20(_paymentTokenAddress).transferFrom(msg.sender, address(this), _totalGroupPrice);
            }
        }

        if (_forNativePayment != 0) {
            require(msg.value >= _forNativePayment, "Generator: insufficient funds");
            if (msg.value > _forNativePayment) payable(msg.sender).transfer(msg.value - _forNativePayment);
        }
    }

    /**
     * @dev Detect group index by NFT number
     */
    function __getGroupIndexByNftNumber(uint256[] memory _counts, uint256 _num) private pure returns (uint256) {
        uint256 _index;

        for (uint256 _i; _i < _counts.length; _i++) {
            if (_counts[_i] < _num) continue;

            _index = _i;
            break;
        }

        return _index;
    }
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
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

import "./ICreatureType.sol";
import "./IProtectionProgram.sol";

/// @title Interface for Creature contract
interface ICreature is ICreatureType, IERC721EnumerableUpgradeable {
    struct Creature {
        uint8 gen;
        uint8 tenure;
        CreatureType creatureType;
    }

    /**
     * @notice Set `Generator` contract address
     * @param _generatorAddress `Generator` contract address
     */
    function setGeneratorAddress(address _generatorAddress) external;

    /**
     * @notice Set `ProtectionProgram` contract address
     * @param _protectionProgramAddress `ProtectionProgram` contract address
     */
    function setProtectionProgramAddress(address _protectionProgramAddress) external;

    /**
     * @notice Mint new NFT, can be called only from `Generator` contract
     * @param _to NFT recipient
     * @param _id NFT ID
     */
    function safeMint(address _to, uint256 _id) external;

    /**
     * @dev Call to create a signature
     * @param _ids NFTs ID
     * @param _gens NFTs gen
     * @param _tenures NFTs tenure score
     */
    function addCreaturesInfo(
        uint256[] calldata _ids,
        uint8[] calldata _gens,
        uint8[] calldata _tenures
    ) external;

    /**
     * @dev Call to create a signature and stake to `ProtectionProgram` contract
     * @param _ids NFTs ID
     * @param _gens NFTs gen
     * @param _tenures NFTs tenure score
     */
    function addCreaturesInfoAndStake(
        uint256[] calldata _ids,
        uint8[] calldata _gens,
        uint8[] calldata _tenures
    ) external;

    /**
     * @dev Return info about NFT
     * @param _id NFT ID
     */
    function getCreatureInfo(uint256 _id) external view returns (uint256, uint256, CreatureType);

    /**
     * @dev Set base URI for NFTs
     * @param _baseUri https://www.google.com/ as example
     */
    function setBaseUri(string memory _baseUri) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGenerator {
    event GroupsSetUp(uint256[] amounts, uint256[] prices, address[] paymentTokens);

    struct Groups {
        uint256[] amounts;
        uint256[] prices;
        address[] paymentTokens;
    }

    /**
     * @notice Mint new NFTs
     * @param _to NFT recipient
     * @param _amount NFT amount to mint
     */
    function mint(address _to, uint256 _amount) external payable;

    /**
     * @notice Withdraw native tokens from contract
     */
    function withdrawNative(address _to) external;

    /**
     * @notice Withdraw ERC20 tokens from contract
     */
    function withdrawERC20(IERC20 _token, address _to, uint256 _amount) external;

    /**
     * @notice Return groups info
     */
    function getGroups() external view returns (uint256[] memory, uint256[] memory, address[] memory);
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "../IERC721Upgradeable.sol";

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721EnumerableUpgradeable is IERC721Upgradeable {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface ICreatureType {
    enum CreatureType { Undefined, Banker, Humal }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ICreature.sol";
import "./IRandomizer.sol";
import "./ICreatureType.sol";

/// @title Interface for `ProtectionProgram` contract
interface IProtectionProgram is ICreatureType {
    event BankerAdded(uint256 id);
    event HumalAdded(uint256 id);
    event Claimed(uint256[] ids, bool isWithdrawn, uint256 amount);

    struct Contracts {
        ICreature creature;
        IRandomizer randomizer;
        IERC20 rewardToken;
    }

    struct TenureInfo {
        uint256 totalTenureScore;
        uint256 currentRewardPerTenure;
    }

    struct Settings {
        uint256 bankerRewardPerSecond;
        uint128 taxPercent;
        uint128 stealOnWithdrawChance;
        uint64 withdrawLockupPeriod;
    }

    struct BankerStake {
        address owner;
        uint64 lastClaim;
    }

    struct HumalStake {
        address owner;
        uint256 tenure;
        uint256 baseRewardByTenure;
    }

    /**
     * @notice Set bankers reward for each second
     * @param _bankerRewardPerSecond Reward per second. Wei
     */
    function setBankerRewardPerSecond(uint256 _bankerRewardPerSecond) external;

    /**
     * @notice Set tax percent for humals. When bankers claim rewards, part of rewards (tax) are collected by the humals
     * @param _taxPercent Percent in decimals. Where 10^27 = 100%
     */
    function setTaxPercent(uint128 _taxPercent) external;

    /**
     * @notice When banker claim reward, humal have a chance to steal all of them. Set this chance
     * @param _chance Chance. Where 10^27 = 100%
     */
    function setStealOnWithdrawChance(uint128 _chance) external;

    /**
     * @notice Bankers can withdraw funds if they have not claim rewards for a certain period of time
     * @param _withdrawLockupPeriod Time. Seconds
     */
    function setWithdrawLockupPeriod(uint64 _withdrawLockupPeriod) external;

    /**
     * @notice Add NFTs to protection program
     * @dev Will be added only existed NFTs where sender is nft owner
     * @param _ids NFTs
     */
    function add(uint256[] calldata _ids) external;

    /**
     * @notice @notice Claim rewards for selected NFTs
     * @dev Sender should be nft owner. NFTs should be in the protection program
     * @param _ids NFTs
     */
    function claim(uint256[] calldata _ids) external;

    /**
     * @notice Claim rewards for selected NFTs and withdraw from protection program
     * @dev Sender should be nft owner. NFTs should be in the protection program
     * @param _ids NFTs
     */
    function withdraw(uint256[] calldata _ids) external;

    /**
     * @notice Calculate reward amount for NFTs. On withdraw, part of reward can be stolen
     * @dev Sender should be nft owner. Nft should be in the protection program
     * @param _ids NFTs
     * @return bankersReward Rewards for bankers
     * @return humalsReward Rewards for humals
     */
    function calculatePotentialRewards(uint256[] calldata _ids)
    external
    view
    returns (uint256 bankersReward, uint256 humalsReward);

    /**
     * @notice Withdraw native token from contract
     * @param _to Recipient
     */
    function withdrawNative(address _to) external;

    /**
     * @notice Transfer ERC20 tokens
     * @param _token Token address
     * @param _to Recipient
     * @param _amount Token amount
     */
    function withdrawERC20(address _token, address _to, uint256 _amount) external;

    /**
     * @notice Return array with NFTs by owner
     * @param _address Owner address
     * @param _from Index from
     * @param _amount Amount
     */
    function getNFTsByOwner(
        address _address,
        uint256 _from,
        uint256 _amount
    ) external view returns(uint256[] memory, bool[] memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721Upgradeable is IERC165Upgradeable {
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
interface IERC165Upgradeable {
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
pragma solidity ^0.8.9;

/// @title Interface for Randomizer contract
interface IRandomizer {
    /**
     * @notice Get conventionally random number in range 0 <= _result < _maxNum
     * @param _maxNum Maximal value
     */
    function random(uint256 _maxNum) external returns (uint256 _result);

    /**
     * @notice @notice Get conventionally random number in range 0 <= _result < _maxNum
     * @param _maxNum Maximal value
     * @param _val Additional num
     */
    function random(uint256 _maxNum, uint256 _val) external view returns (uint256);
}