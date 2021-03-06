//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IItems {
    function bossDropMint(address _addr) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function totalSupply() external view returns (uint256);
}

interface IHeroes {
    function bossDropMint(address _addr) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) external;

    function totalSupply() external view returns (uint256);
}

contract HeroStaking is Ownable {
    uint8 public bossRound = 1;

    mapping(address => User) addrToUser;
    mapping(address => mapping(uint8 => bool)) addrToClaimStatus;

    bool public stakingStatus = true;

    address public MetaAndMagicHeroesAddress;
    address public MetaAndMagicItemsAddress;

    struct User {
        uint16[] heroIds;
    }

    constructor() {}

    function stakeHeroes(
        uint16[] memory _stakeHeroes,
        uint16[] memory _unstakeHeroes
    ) public {
        require(stakingStatus, "Staking/unstaking is not available!");

        if (_stakeHeroes.length > 0 && _unstakeHeroes.length == 0) {
            for (uint256 i = 0; i < _stakeHeroes.length; i++) {
                IHeroes(MetaAndMagicHeroesAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _stakeHeroes[i],
                    ""
                );
                addrToUser[msg.sender].heroIds.push(_stakeHeroes[i]);
            }
        }
        // If stake amount is 0 and unstake amount more than 0, proceed to unstake whatever
        // This is assuming that it unstakes the correct items?
        else if (_stakeHeroes.length == 0 && _unstakeHeroes.length > 0) {
            // Make sure the user has something to unstake
            // Unstake amount must be less than or equals to currentStakedAmt
            require(
                _unstakeHeroes.length <= addrToUser[msg.sender].heroIds.length,
                "You cannot unstake more than you have!"
            );

            // Unstake items first
            for (uint256 i = 0; i < _unstakeHeroes.length; i++) {
                for (
                    uint256 a = 0;
                    a < addrToUser[msg.sender].heroIds.length;
                    a++
                ) {
                    if (
                        _unstakeHeroes[i] == addrToUser[msg.sender].heroIds[a]
                    ) {
                        IHeroes(MetaAndMagicHeroesAddress).safeTransferFrom(
                            address(this),
                            msg.sender,
                            addrToUser[msg.sender].heroIds[a],
                            ""
                        );
                        for (
                            uint256 ii = a;
                            ii < addrToUser[msg.sender].heroIds.length - 1;
                            ii++
                        ) {
                            addrToUser[msg.sender].heroIds[ii] = addrToUser[
                                msg.sender
                            ].heroIds[ii + 1];
                        }
                        addrToUser[msg.sender].heroIds.pop();
                    }
                }
            }
        } else if (_stakeHeroes.length > 0 && _unstakeHeroes.length > 0) {
            require(
                _unstakeHeroes.length <= addrToUser[msg.sender].heroIds.length,
                "You cannot unstake more than you have!"
            );

            // Unstake items first
            for (uint256 i = 0; i < _unstakeHeroes.length; i++) {
                for (
                    uint256 a = 0;
                    a < addrToUser[msg.sender].heroIds.length;
                    a++
                ) {
                    if (
                        _unstakeHeroes[i] == addrToUser[msg.sender].heroIds[a]
                    ) {
                        IHeroes(MetaAndMagicHeroesAddress).safeTransferFrom(
                            address(this),
                            msg.sender,
                            addrToUser[msg.sender].heroIds[a],
                            ""
                        );
                        for (
                            uint256 ii = a;
                            ii < addrToUser[msg.sender].heroIds.length - 1;
                            ii++
                        ) {
                            addrToUser[msg.sender].heroIds[ii] = addrToUser[
                                msg.sender
                            ].heroIds[ii + 1];
                        }
                        addrToUser[msg.sender].heroIds.pop();
                    }
                }
            }

            // Stake later
            for (uint256 i = 0; i < _stakeHeroes.length; i++) {
                IHeroes(MetaAndMagicHeroesAddress).safeTransferFrom(
                    msg.sender,
                    address(this),
                    _stakeHeroes[i],
                    ""
                );
                addrToUser[msg.sender].heroIds.push(_stakeHeroes[i]);
            }
        } else {
            revert("You cannot stake and unstake null or other error");
        }
    }
    function claimBossDrop(uint256[] memory itemIdsArr) public {

        require(
            !addrToClaimStatus[msg.sender][bossRound],
            "You have already claimed the boss drop for this round!"
        );

        uint256 itemTotalSupply = IItems(MetaAndMagicItemsAddress).totalSupply();

        // This eventually has to be gotten from another contract
        uint8[11] memory bossArr = [0,20,30,40,50,60,70,80,90,100,110];

        uint8 lowerLimit = bossArr[bossRound];
        uint8 upperLimit = bossArr[bossRound + 1];

        if (bossRound < 10) {

            if (itemTotalSupply >= lowerLimit && itemTotalSupply < upperLimit) 
            {   

                if (itemIdsArr.length == 0){

                    IItems(MetaAndMagicItemsAddress).bossDropMint(msg.sender);
                    addrToClaimStatus[msg.sender][bossRound] = true;
                }

                else if (itemIdsArr.length > 0) {

                    //"Burn"
                    for (uint i = 0; i < itemIdsArr.length; i++){
                        IItems(MetaAndMagicItemsAddress).safeTransferFrom(msg.sender, address(this), itemIdsArr[i], "");
                    }

                    IItems(MetaAndMagicItemsAddress).bossDropMint(msg.sender);
                    addrToClaimStatus[msg.sender][bossRound] = true;
                }
            }
        }
        // tokenId 110 onwards mint 10th boss drop
        else if (bossRound == 10) {
            
            if (itemIdsArr.length == 0){

                IItems(MetaAndMagicItemsAddress).bossDropMint(msg.sender);
                addrToClaimStatus[msg.sender][bossRound] = true;
            }

            else if (itemIdsArr.length > 0) {

                //"Burn"
                for (uint i = 0; i < itemIdsArr.length; i++){
                    IItems(MetaAndMagicItemsAddress).safeTransferFrom(msg.sender, address(this), itemIdsArr[i], "");
                }

                IItems(MetaAndMagicItemsAddress).bossDropMint(msg.sender);
                addrToClaimStatus[msg.sender][bossRound] = true;
            }
        }

        else {
            revert("Error! You cannot mint boss drop!");
        }
    }

    function setStakingStatus(bool _status) public onlyOwner {
        stakingStatus = _status;
    }

    function checkUserDetails(address _address)
        public
        view
        returns (User memory)
    {
        return addrToUser[_address];
    }

    function checkClaimStatus(address _address) public view returns (bool) {
        return addrToClaimStatus[_address][bossRound];
    }

    function setMetaAndMagicHeroesAddress(address _address) public onlyOwner {
        MetaAndMagicHeroesAddress = _address;
    }

    function setMetaAndMagicItemsAddress(address _address) public onlyOwner {
        MetaAndMagicItemsAddress = _address;
    }

    function setBossRound(uint8 _round) public onlyOwner {
        bossRound = _round;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual returns (bytes4) {
        return this.onERC721Received.selector;
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721Receiver.sol)

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
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