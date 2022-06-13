// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./interfaces/IAGStakeFull.sol";
import "./interfaces/IAlphaGangGenerative.sol";
import "./interfaces/IAlphaGangOG.sol";
import "./interfaces/IGangToken.sol";

contract AGStakeX is IAGStake, Ownable, ERC721Holder, ERC1155Holder {
    // address to timestamp of last update
    mapping(address => uint256) public lastUpdate;

    // TODO decide if immutable for savings
    IAlphaGangOG immutable AlphaGangOG;
    IAlphaGangGenerative AlphaGangG2;
    IGangToken immutable GANG;

    // maps OG tokenId to mapping of address to count of staked tokens
    mapping(uint256 => mapping(address => uint256)) public vaultOG;

    // Mapping: address to token to staked timestamp
    mapping(address => mapping(uint256 => uint256)) public override vaultG2;

    /**
     * token ID to staked at timestamp or 0 if token is not staked
     * Note 1 is more gas optimal than 0 for unstaked state but we won't expect too many of these changes
     */
    mapping(address => uint256) public stakedAtG2;

    // Mapping: address to count of tokens staked
    mapping(address => uint256) public ownerG2StakedCount;

    /**
     * mapping of address to timestamp when last OG was staked
     * Note This offers less granular controll of staking tokens at a benefit of less complexity/gas savings
     */
    mapping(address => uint256) stakedAtOG;

    // OG rate 300 per week
    uint256 public ogStakeRate = 496031746031746;
    // G2 rate 30 per week
    uint256 public G2StakeRate = 49603174603175;
    // Bonus base for holding OG tokens
    uint256 bonusBase = 500_000;
    // Bonus for holding all 3 kind of OG tokens
    uint256 triBonus = 100_000;

    uint256 constant BASE = 1_000_000;

    uint256 public PRICE_WHALE = 49000000000000000; // 0.049 ether
    uint256 public PRICE = 69000000000000000; // 0.069 ether

    constructor(
        IAlphaGangOG _og,
        IAlphaGangGenerative _G2,
        IGangToken _token
    ) {
        AlphaGangOG = _og;
        AlphaGangG2 = _G2;
        GANG = _token;
    }

    /**
     * @dev Stake tokens for generative.
     * Note This makes stakeAll obsolete, since we'd have to check every token minted to get all user tokens with ERC721A.
     */
    function stakeG2(uint256[] calldata tokenIds) public override {
        uint256 timeNow = block.timestamp;
        // for extra check both msg.sender and tx origin are correct:
        address _owner = msg.sender;
        if (msg.sender == address(this)) {
            _owner = tx.origin;
        }
        // address _owner = tx.origin;
        _claim(_owner);

        for (uint8 i = 0; i < tokenIds.length; i++) {
            // verify the ownership
            require(
                AlphaGangG2.ownerOf(tokenIds[i]) == _owner,
                "Not your token"
            );

            require(vaultG2[_owner][tokenIds[i]] == 0, "Token already staked");

            // stake the token for _owner
            AlphaGangG2.transferFrom(_owner, address(this), tokenIds[i]);
            vaultG2[_owner][tokenIds[i]] = timeNow;
        }
        // update lastStake time for _owner
        // stakedAtG2[_owner] = timeNow;
        unchecked {
            ownerG2StakedCount[_owner] += tokenIds.length;
        }

        emit StakedG2(_owner, tokenIds, timeNow);
    }

    /**
     * @dev Unstake tokens for generative.
     *
     * @param tokenIds Array of tokens to unstake
     */
    function unstakeG2(uint256[] memory tokenIds) external {
        address _owner = msg.sender;
        _claim(_owner);

        for (uint8 i = 0; i < tokenIds.length; ++i) {
            require(
                AlphaGangG2.ownerOf(tokenIds[i]) == _owner,
                "Not your token"
            );
            require(
                vaultG2[_owner][tokenIds[i]] < block.timestamp + 72 hours,
                "Token locked for 3 days"
            );
            vaultG2[_owner][tokenIds[i]] = 0;

            AlphaGangG2.transferFrom(address(this), _owner, tokenIds[i]);
        }

        ownerG2StakedCount[_owner] -= tokenIds.length;

        emit UnstakedG2(_owner, tokenIds, block.timestamp);
    }

    function claim() external {
        _claim(msg.sender);
    }

    function claimForAddress(address account) external {
        _claim(account);
    }

    function _claim(address account) internal {
        uint256 earned;

        // if there is no last update just set the first timestamp for address
        if (lastUpdate[account] > 0) {
            earned = earningInfo(account);
        }

        lastUpdate[account] = block.timestamp;

        if (earned > 0) {
            GANG.mint(account, earned);
        }

        emit Claimed(account, earned, block.timestamp);
    }

    // Check how much tokens account has for claiming
    function earningInfo(address account) public view returns (uint256 earned) {
        uint256 earnedWBonus;
        uint256 earnedNBonus;

        uint256 timestamp = block.timestamp;
        uint256 _lastUpdate = lastUpdate[account];

        // no earnings so far
        if (_lastUpdate == 0) return 0;

        uint256 tokenCountOG;

        uint256[] memory stakedCountOG = stakedOGBalanceOf(account);

        // bonus is applied for holding all 3 assets(can only be applied once)
        uint256 triBonusCount;
        unchecked {
            for (uint32 i; i < 3; ++i) {
                if (stakedCountOG[i] > 0) {
                    tokenCountOG += stakedCountOG[i];
                    ++triBonusCount;
                }
            }
        }

        uint256 bonus = BASE; // multiplier of 1

        unchecked {
            // add G2 tokens to bonusBase
            earnedWBonus += G2StakeRate * ownerG2StakedCount[account]; // count of owners tokens times rate for G2

            // Calculate bonus to be applied
            if (tokenCountOG > 0) {
                // Order: 50, Mac, Riri, bonus is halved by 50% for each additional token
                uint256 _bonusBase = bonusBase;

                // Add a single token to bonusBase
                earnedWBonus += ogStakeRate;
                // Add rest to noBonusBase
                earnedNBonus += ogStakeRate * (tokenCountOG - 1);

                // calculate total bonus to be applied, start adding bonus for more hodls
                for (uint32 i = 0; i < tokenCountOG; ++i) {
                    bonus += _bonusBase;
                    _bonusBase /= 2;
                }

                // triBonus for holding all 3 OGs
                if (triBonusCount == 3) {
                    bonus += triBonus;
                }
            }
        }

        // calculate and return how much is earned
        return
            (((earnedWBonus * bonus) / BASE) + earnedNBonus) *
            (timestamp - _lastUpdate);
    }

    /** OG Functions */
    function stakeSingleOG(uint256 tokenId, uint256 tokenCount) external {
        address _owner = msg.sender;

        // claim unstaked tokens, since count/rate will change
        _claim(_owner);

        AlphaGangOG.safeTransferFrom(
            _owner,
            address(this),
            tokenId,
            tokenCount,
            ""
        );

        stakedAtOG[_owner] = block.timestamp;

        unchecked {
            vaultOG[tokenId][_owner] += tokenCount;
        }

        emit StakedOG(
            _owner,
            _asSingletonArray(tokenId),
            _asSingletonArray(tokenCount),
            block.timestamp
        );
    }

    function unstakeSingleOG(uint256 tokenId, uint256 tokenCount) external {
        address _owner = msg.sender;
        uint256 _totalStaked = vaultOG[tokenId][_owner];

        require(
            _totalStaked >= 0,
            "You do have any tokens available for unstaking"
        );
        require(
            _totalStaked >= tokenCount,
            "You do not have requested token amount available for unstaking"
        );
        require(
            stakedAtOG[_owner] < block.timestamp + 72 hours,
            "Tokens locked for 3 days"
        );

        // claim rewards before unstaking
        _claim(_owner);

        unchecked {
            vaultOG[tokenId][_owner] -= tokenCount;
        }

        AlphaGangOG.safeTransferFrom(
            address(this),
            _owner,
            tokenId,
            tokenCount,
            ""
        );

        emit UnstakedOG(
            msg.sender,
            _asSingletonArray(tokenId),
            _asSingletonArray(tokenCount),
            block.timestamp
        );
    }

    /**
     * @dev
     *
     * Note this will stake all available tokens, but makes it possible to not immediately stake G2 tokens (@Hax)
     */
    // TODO allow OGs pass how many generatives they want to stake
    function stakeOGAndMint(uint256 _stakeCount) external payable {
        // check if OG minting is active
        require(AlphaGangG2.ogMintActive(), "OG Mint not active");

        address _owner = msg.sender;
        uint256[] memory totalAvailable = unstakedOGBalanceOf(_owner);

        // TODO call updateOwnerRewards

        // get the count of tokens
        uint256 _totalOGsToBeStaked = totalAvailable[0] +
            totalAvailable[1] +
            totalAvailable[2];
        // make sure there are tokens to be staked
        require(_totalOGsToBeStaked > 0, "No tokens to stake");

        // get the price, whales get discount
        uint256 _price = _totalOGsToBeStaked > 2 ? PRICE_WHALE : PRICE;

        /**
         * Ammount of eth is sent to G2 contract, but checked here first
         * all OG get 2 tokens for WL + one additional for each token staked
         * in addition whales(3+ tokens) get reduced price
         */
        uint256 g2MintCount = _totalOGsToBeStaked + 2;

        // Rather than rolling back we assume user wants to stake all tokens
        if (_stakeCount > g2MintCount) {
            _stakeCount = g2MintCount;
        }

        require(msg.value >= g2MintCount * _price, "Not enought Eth");

        uint256 timeNow = block.timestamp;

        uint256[] memory tokens = new uint256[](3);
        tokens[0] = 1;
        tokens[1] = 2;
        tokens[2] = 3;

        // claim and update the timestamp for this account
        _claim(_owner);

        AlphaGangOG.safeBatchTransferFrom(
            _owner,
            address(this),
            tokens,
            totalAvailable,
            ""
        );

        // Update stake time
        stakedAtOG[_owner] = timeNow;

        // loop over and update the vault
        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                vaultOG[i][_owner] += totalAvailable[i - 1];
            }
        }

        // call mint on Gen2
        uint256 firstTokenId = AlphaGangG2.ogMint{value: msg.value}(
            g2MintCount,
            _owner
        );

        // if _stake is selected
        if (_stakeCount > 0) {
            unchecked {
                for (uint256 i = 0; i < _stakeCount; i++) {
                    require(
                        AlphaGangG2.ownerOf(firstTokenId + i) == _owner,
                        "Not your token"
                    );

                    // stake the token for _owner
                    AlphaGangG2.transferFrom(
                        _owner,
                        address(this),
                        firstTokenId + i
                    );

                    // update lastStake time for _owner
                    vaultG2[_owner][firstTokenId + i] = timeNow;
                }

                ownerG2StakedCount[_owner] += g2MintCount;
            }
        }

        emit StakedAndMinted(
            msg.sender,
            tokens,
            totalAvailable,
            block.timestamp
        );
    }

    /**
     * @dev Stakes all OG tokens of {_owner} by transfering them to this contract.
     *
     * Emits a {StakedOG} event.
     */
    function stakeAllOG() external {
        address _owner = msg.sender;
        uint256[] memory totalAvailable = unstakedOGBalanceOf(_owner);

        // claim for owner
        _claim(_owner);

        uint256[] memory tokens = new uint256[](3);
        tokens[0] = 1;
        tokens[1] = 2;
        tokens[2] = 3;

        AlphaGangOG.safeBatchTransferFrom(
            _owner,
            address(this),
            tokens,
            totalAvailable,
            ""
        );

        // Update stake time
        stakedAtOG[_owner] = block.timestamp;

        // loop over and update the vault
        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                vaultOG[i][_owner] += totalAvailable[i - 1];
            }
        }

        emit StakedOG(msg.sender, tokens, totalAvailable, block.timestamp);
    }

    function unstakeAllOG() external {
        address _owner = msg.sender;
        require(
            stakedAtOG[_owner] < block.timestamp + 72 hours,
            "Tokens locked for 3 days"
        );

        // claim for owner
        _claim(_owner);

        uint256[] memory _totalStaked = stakedOGBalanceOf(_owner);

        uint256[] memory tokens = new uint256[](3);
        tokens[0] = 1;
        tokens[1] = 2;
        tokens[2] = 3;

        // loop over and update the vault
        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                vaultOG[i][_owner] -= _totalStaked[i - 1];
            }
        }

        AlphaGangOG.safeBatchTransferFrom(
            address(this),
            _owner,
            tokens,
            _totalStaked,
            ""
        );

        emit UnstakedOG(_owner, tokens, _totalStaked, block.timestamp);
    }

    /** Views */
    function stakedOGBalanceOf(address account)
        public
        view
        returns (uint256[] memory _tokenBalance)
    {
        uint256[] memory tokenBalance = new uint256[](3);

        unchecked {
            for (uint32 i = 1; i < 4; i++) {
                uint256 stakedCount = vaultOG[i][account];
                if (stakedCount > 0) {
                    tokenBalance[i - 1] += stakedCount;
                }
            }
        }
        return tokenBalance;
    }

    function unstakedOGBalanceOf(address account)
        public
        view
        returns (uint256[] memory _tokenBalance)
    {
        // This consumes ~4k gas less than batchBalanceOf with address array
        uint256[] memory totalTokenBalance = new uint256[](3);
        totalTokenBalance[0] = AlphaGangOG.balanceOf(account, 1);
        totalTokenBalance[1] = AlphaGangOG.balanceOf(account, 2);
        totalTokenBalance[2] = AlphaGangOG.balanceOf(account, 3);

        return totalTokenBalance;
    }

    /** Utils */
    function _asSingletonArray(uint256 element)
        private
        pure
        returns (uint256[] memory)
    {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }

    /**
     * @dev
     * (@Hax) Migrate feature in case we need to manage tokens
     * Eg. someone sends token to staking contract directly or we need to migrate
     *
     */
    function setApprovalForAll(address operator, bool approved)
        external
        onlyOwner
    {
        AlphaGangG2.setApprovalForAll(operator, approved);
        AlphaGangOG.setApprovalForAll(operator, approved);
    }

    /**
     * @dev Withdraw any ether that might get sent/stuck on this contract
     */
    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function stakedG2TokensOfOwner(address account)
        external
        view
        returns (uint256[] memory)
    {
        uint256 supply = AlphaGangG2.totalSupply();

        uint256 ownerStakedTokenCount = ownerG2StakedCount[account];
        uint256[] memory tokens = new uint256[](ownerStakedTokenCount);

        uint256 index = 0;
        for (uint256 tokenId = 1; tokenId <= supply; tokenId++) {
            if (vaultG2[account][tokenId] > 0) {
                tokens[index] = tokenId;
            }
        }
        return tokens;
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IAGStake {
    event StakedG2(address owner, uint256[] tokenIds, uint256 timestamp);
    event UnstakedG2(address owner, uint256[] tokenIds, uint256 timestamp);
    event StakedOG(
        address owner,
        uint256[] tokenIds,
        uint256[] counts,
        uint256 timestamp
    );
    event StakedAndMinted(
        address owner,
        uint256[] tokenIds,
        uint256[] counts,
        uint256 timestamp
    );
    event UnstakedOG(
        address owner,
        uint256[] tokenIds,
        uint256[] counts,
        uint256 timestamp
    );
    event Claimed(address owner, uint256 amount, uint256 timestamp);

    function vaultG2(address, uint256) external view returns (uint256);

    function stakeG2(uint256[] calldata tokenIds) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IAlphaGangGenerative {
    function balanceOf(address account) external view returns (uint256);

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function ogMint(uint256 _mintAmount, address _owner)
        external
        payable
        returns (uint256 _nextTokenId);

    function ownerOf(uint256 tokenId) external view returns (address);

    function setApprovalForAll(address operator, bool approved) external;

    function totalSupply() external view returns (uint256);

    function ogMintActive() external view returns (bool);

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory ownerTokens);
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IAlphaGangOG {
    function balanceOf(address account, uint256 id)
        external
        view
        returns (uint256);

    // change to transfer
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external;

    function setApprovalForAll(address operator, bool approved) external;
}

// SPDX-License-Identifier: MIT LICENSE

pragma solidity ^0.8.0;

interface IGangToken {
    function mint(address to, uint256 amount) external;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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