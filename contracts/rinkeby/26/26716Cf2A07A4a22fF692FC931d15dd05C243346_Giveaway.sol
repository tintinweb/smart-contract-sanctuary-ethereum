/**
 *Submitted for verification at Etherscan.io on 2022-08-09
*/

// SPDX-License-Identifier: MIT

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol


// OpenZeppelin Contracts v4.4.1 (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        // On the first call to nonReentrant, _notEntered will be true
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;

        _;

        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// File: @openzeppelin/contracts/utils/introspection/IERC165.sol


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

// File: @openzeppelin/contracts/token/ERC721/IERC721.sol


// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;


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


pragma solidity ^0.8.4;

abstract contract Maps {
        function indexOfAddress(address[] memory arr, address searchFor)
        public
        pure
        returns (uint256)
    {
        for (uint256 i = 0; i < arr.length; i++) {
            if (arr[i] == searchFor) {
                return i;
            }
        }
        revert("Address Not Found");
    }
}

pragma solidity ^0.8.4;

abstract contract Guilds {
    struct Guild {
        uint256 TokenId;
        string GuildName;
        string GuildDesc;
        address Admin;
        address[] GuildMembers;
        address[] GuildMods;
        string GuildType;
        uint256[] Appeals;
        uint256 UnlockDate;
        uint256 LockDate;
        string GuildRules;
        bool FreezeMetaData;
        address[] Kicked;
    }

    function getGuildById(uint256 _id) external virtual view returns (Guild memory guild);

    function balanceOf(address account, uint256 id)
        external
        virtual
        view
        returns (uint256);

    function totalSupply(uint256 id) public view virtual returns (uint256);
}

pragma solidity ^0.8.4;

contract Giveaway is ReentrancyGuard, Maps {
    Guilds private guilds;

    struct Raffle {
        uint256 GuildId;
        uint256 TotalEntries;
        address Staker;
        IERC721 StakedCollection;
        uint256 StakedTokenId;
        address[] Participates;
        uint initialNumber;
    }

    mapping(uint256 => Raffle) raffle;
    mapping(uint256 => bool) raffleExists;
    address GuildsAddress = 0x476ffB49bD1Cf6B53E112F503d56aBAbc6E0823F;
    string private _name;
    string private _symbol;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        guilds = Guilds(GuildsAddress); 
    }

    Guilds.Guild guild;

    function name() public view virtual returns (string memory) {
        return _name;
    }

    function symbol() public view virtual returns (string memory) {
        return _symbol;
    } 

    function stake(uint256 _tokenId, IERC721 nftCollection, uint256 _guildId, uint256 _spots) external nonReentrant {
        Guilds.Guild memory _guild = guilds.getGuildById(_guildId);
        require(!raffleExists[_guildId], "Each guild can have only one giveaway at a time");
        require(_guild.Admin == msg.sender, "Only guild master can start a giveaway");
        require(guilds.totalSupply(_guildId) >= _spots, "Not enough spots to giveaway");
        require(
            nftCollection.ownerOf(_tokenId) == msg.sender,
            "You don't own this token!"
        );

        nftCollection.transferFrom(msg.sender, address(this), _tokenId);

        raffle[_guildId].GuildId = _guildId;
        raffle[_guildId].TotalEntries = _spots;
        raffle[_guildId].Staker = msg.sender;
        raffle[_guildId].StakedCollection = nftCollection;
        raffle[_guildId].StakedTokenId = _tokenId;
        raffle[_guildId].Participates;
        raffle[_guildId].initialNumber = uint(keccak256(abi.encodePacked(block.timestamp,block.difficulty,  
        msg.sender))) % _spots;
        raffleExists[_guildId] = true;
    }

    function reward(uint256 _guildId) external nonReentrant {
        Guilds.Guild memory _guild = guilds.getGuildById(_guildId);
        require(raffleExists[_guildId], "Raffle is not existed");
        require(msg.sender == _guild.Admin, "Only guild master can raffle");
        countEntries(_guildId);
        require(raffle[_guildId].Participates.length >= raffle[_guildId].TotalEntries, "Giveaway is not finished");
        uint256 winnerIndex = rand(_guildId, raffle[_guildId].Participates.length);
        address winner = raffle[_guildId].Participates[winnerIndex];
        raffle[_guildId].StakedCollection.transferFrom(address(this), winner, raffle[_guildId].StakedTokenId);
        delete raffle[_guildId];
    }

    function totalEntriesOfRaffle(uint256 _guildId) public view returns(uint256) {
        return raffle[_guildId].TotalEntries;
    }

    function rewardToken(uint256 _guildId) public view returns(uint256) {
        return raffle[_guildId].StakedTokenId;
    }

    function rewardCollection(uint256 _guildId) public view returns(IERC721) {
        return raffle[_guildId].StakedCollection;
    }

    function countEntries(uint256 _guildId) private {
        Guilds.Guild memory _guild = guilds.getGuildById(_guildId);
        // push mods:
        for (uint256 i; i < _guild.GuildMods.length; i++) {
            if (_guild.GuildMods[i] != address(0)) {
            uint256 _entriesForAddress = guilds.balanceOf(_guild.GuildMods[i], _guildId);
            for (uint256 e; e < _entriesForAddress; e++) {
            raffle[_guildId].Participates.push(_guild.GuildMods[i]);
            }
            }
        }

        // push members:
        for (uint256 i; i < _guild.GuildMembers.length; i++) {
            if (_guild.GuildMembers[i] != address(0)) {
            uint256 _entriesForAddress = guilds.balanceOf(_guild.GuildMembers[i], _guildId);
            for (uint256 e; e < _entriesForAddress; e++) {
            raffle[_guildId].Participates.push(_guild.GuildMembers[i]);
            }
            }
        }
    }

    function rand(uint256 _guildId, uint256 _spots) private returns(uint) {
        return uint(keccak256(abi.encodePacked(raffle[_guildId].initialNumber++))) % _spots;
    }
}