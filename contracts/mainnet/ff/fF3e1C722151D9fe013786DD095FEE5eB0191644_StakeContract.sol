// SPDX-License-Identifier: MIT
                                                                                                                                       
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////                                                                  :-                                                                            
//                                                                                                                                                          //
//                                                                                                                                                          //
//                                                                            /\                                                                            //
//                                                                           /=*\                                                                           //
//                                                                          -+  -#.\                                                                        //
//                                                                          #.  =#*=\                                                                       //
//                                                                     /\ -+      @ //                                                                      //
//                                                                    /*  .#       *:./.                                                                    //
//                                                                 :# .+==+.       *-=%\                                                                    //
//                                                                 +=  +=+         =*#.//                                                                   //
//                                                                 :#                . +-\                                                                  //
//                                                              :.  %.    ::@@@@@@::    .# \                                                                //
//       [email protected]@@@@@@@@@@@%#.                           ::::        %*-=* :+%@@@@@@@@@@@%+. -**%.          [email protected]@@@@@@@@@@@%*   :::.              @@:              //
//        [email protected]@@@####%@@@@-                          [email protected]@@+       -+ . :#@@@@@@@@@@@@@@@@@#:  -*           [email protected]@@@####%@@@@. [email protected]@@=              @@:              //
//        %@@@=    [email protected]@@%                           %@@@        ==  [email protected]@@@@@@@@@@@@@@@@@@@@*. %.         [email protected]@@@-    #@@@#  @@@%              [email protected]@@.             //
//       [email protected]@@%     :+#@:                          [email protected]@@=        :* *@@@ COOL SKULL CLUB @@@%.*         *@@@#     -+%@. [email protected]@@=               @@@%              //
//       %@@@=           :#######:   .####### :  [email protected]@@@          #[email protected]@@@@@@@@@@@@@@@@@@@@@@@@#%.        [email protected]@@@:          [email protected]@@% :###:   :###: *@@@+####:        //
//      [email protected]@@%          [email protected]@@@@@@@@@# *@@@@@@@@@@+ [email protected]@@-          [email protected]@@@@@@@@@@@@@@@@@@@@@@@@@@=         *@@@*           *@@@- %@@@   :@@@*[email protected]@@@@@@@@@@:       //
//     [email protected]@@@-         [email protected]@@%[email protected]@@=:@@@*...%@@@:[email protected]@@#            @@@@@%@@@@@@@@@@@@@@@@@@@@%         [email protected]@@@.          [email protected]@@# [email protected]@@=   %@@@.*@@@[email protected]@@%        //
//     [email protected]@@%       := *@@@-   @@@@ %@@@.  :@@@# *@@@:            *@@@@=-----#@@@#-----%@@@@*         #@@@*       :-  *@@@: %@@@   [email protected]@@*[email protected]@@#   *@@@=        //
//    [email protected]@@@:    +#@@*[email protected]@@#   [email protected]@@[email protected]@@+   #@@@:[email protected]@@#             .*@@=      :@@@   \,/  *@@*.       [email protected]@@@.    +#@@+ :@@@# [email protected]@@=   %@@@ *@@@.  :@@@%         //
//    [email protected]@@*    [email protected]@@@:*@@@:  [email protected]@@% %@@@   [email protected]@@* #@@@:               @@+     .*@@@-  /'\  #@@         #@@@+    [email protected]@@@. #@@@: @@@@   [email protected]@@=:@@@*   #@@@:         //
//    @@@@@%%%%@@@@+ @@@@###%@@@:[email protected]@@@###@@@@.:@@@@.              [email protected]@@#**[email protected]@-#[email protected]@%***%@@@=        [email protected]@@@@%%%%@@@@= [email protected]@@@[email protected]@@@%%%@@@@ #@@@%##%@@@+          //
//    -*#########*-  +########*: .*########+. +####*:              *@@@@@@@@. * :@@@@@@@@*          =*#########+:  +####*=*###**%@@%-:########*=.           //
//                                                                  .=+:[email protected]@@@@@%@@@@=-+=.                                                                   //
//                                                                       @@@@@@@@@@@                                                                        //
//                                                                       *@@@@@@@@@*                                                                        //
//                                                                         /SKULL/                                                                          //
//                                                                                                                                                          //
//                                                                                                                                                          //
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// @title : CoolSkullClubStaking
// @version: 1.0
// @description: Cool Skull Club Staking for the Ethereum Ecosystem
// @license: MIT
// @developer: @0xKayaoglu - kayaoglu.eth                                                                                                                                
// @artist: @0xRuhsten - ruhsten.eth
// @advisor: @cipekci - canipekci.eth
// @community: @thepunktum - punktum

pragma solidity ^0.8.13;

import "./ERC721A/IERC721A.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakeContract is ReentrancyGuard {

    address private CONTRACT_WALLET = address(this);

    struct StakedToken {
        address staker;
        address skullType;
        uint256 tokenId;
    }
    
    struct Staker {
        uint256 amountStaked;
        StakedToken[] stakedTokens;
    }

    mapping ( address => mapping(address => Staker)) public stakers;
    mapping ( address => mapping(uint256 => address)) public stakerAddress;

    function _stake( address _owner, address _contract, uint256 _tokenId ) public {
        
        require(
            IERC721A(_contract).ownerOf(_tokenId) == _owner,
            "You don't own this token!"
        );
        
        IERC721A(_contract).transferFrom( _owner, CONTRACT_WALLET, _tokenId );
        
        StakedToken memory stakedToken = StakedToken(_owner, _contract, _tokenId);
        stakers[_owner][_contract].stakedTokens.push(stakedToken);
        stakers[_owner][_contract].amountStaked++;
        stakerAddress[_contract][_tokenId] = _owner;

    }

    function _unstake( address _owner, address _contract, uint256 _tokenId ) public {
        
        require(
            stakers[_owner][_contract].amountStaked > 0,
            "You have no tokens staked"
        );

        require(stakerAddress[_contract][_tokenId] == _owner, "You don't own this token!");

        uint256 index = 0;
        for (uint256 i = 0; i < stakers[_owner][_contract].stakedTokens.length; i++) {
            if (
                stakers[_owner][_contract].stakedTokens[i].tokenId == _tokenId 
                && 
                stakers[_owner][_contract].stakedTokens[i].staker != address(0)
            ) {
                index = i;
                break;
            }
        }

        stakers[_owner][_contract].stakedTokens[index].staker = address(0);
        stakers[_owner][_contract].amountStaked--;
        stakerAddress[_contract][_tokenId] = address(0);

        IERC721A(_contract).transferFrom( CONTRACT_WALLET, _owner, _tokenId );

    }

    function Stake( address _contract, uint256[] memory _tokenIds ) external nonReentrant {
        
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            _stake(msg.sender, _contract, _tokenIds[i]);
        }

    }

    function UnStake( address _contract, uint256[] memory _tokenIds ) external nonReentrant {
       
        for (uint256 i = 0; i < _tokenIds.length; ++i) {
            _unstake(msg.sender, _contract, _tokenIds[i]);
        }

    }

    function getStakedTokens(address _user, address _contract) public view returns (StakedToken[] memory) {
        if (stakers[_user][_contract].amountStaked > 0) {
            
            StakedToken[] memory _stakedTokens = new StakedToken[](stakers[_user][_contract].amountStaked);
            uint256 _index = 0;

            for (uint256 j = 0; j < stakers[_user][_contract].stakedTokens.length; j++) {
                if (stakers[_user][_contract].stakedTokens[j].staker != (address(0))) {
                    _stakedTokens[_index] = stakers[_user][_contract].stakedTokens[j];
                    _index++;
                }
            }

            return _stakedTokens;
        }
        
        else {
            return new StakedToken[](0);
        }
    }

}

// SPDX-License-Identifier: MIT
// ERC721A Contracts v4.2.0
// Creator: Chiru Labs

pragma solidity ^0.8.4;

/**
 * @dev Interface of ERC721A.
 */
interface IERC721A {
    /**
     * The caller must own the token or be an approved operator.
     */
    error ApprovalCallerNotOwnerNorApproved();

    /**
     * The token does not exist.
     */
    error ApprovalQueryForNonexistentToken();

    /**
     * The caller cannot approve to their own address.
     */
    error ApproveToCaller();

    /**
     * Cannot query the balance for the zero address.
     */
    error BalanceQueryForZeroAddress();

    /**
     * Cannot mint to the zero address.
     */
    error MintToZeroAddress();

    /**
     * The quantity of tokens minted must be more than zero.
     */
    error MintZeroQuantity();

    /**
     * The token does not exist.
     */
    error OwnerQueryForNonexistentToken();

    /**
     * The caller must own the token or be an approved operator.
     */
    error TransferCallerNotOwnerNorApproved();

    /**
     * The token must be owned by `from`.
     */
    error TransferFromIncorrectOwner();

    /**
     * Cannot safely transfer to a contract that does not implement the
     * ERC721Receiver interface.
     */
    error TransferToNonERC721ReceiverImplementer();

    /**
     * Cannot transfer to the zero address.
     */
    error TransferToZeroAddress();

    /**
     * The token does not exist.
     */
    error URIQueryForNonexistentToken();

    /**
     * The `quantity` minted with ERC2309 exceeds the safety limit.
     */
    error MintERC2309QuantityExceedsLimit();

    /**
     * The `extraData` cannot be set on an unintialized ownership slot.
     */
    error OwnershipNotInitializedForExtraData();

    // =============================================================
    //                            STRUCTS
    // =============================================================

    struct TokenOwnership {
        // The address of the owner.
        address addr;
        // Stores the start time of ownership with minimal overhead for tokenomics.
        uint64 startTimestamp;
        // Whether the token has been burned.
        bool burned;
        // Arbitrary data similar to `startTimestamp` that can be set via {_extraData}.
        uint24 extraData;
    }

    // =============================================================
    //                         TOKEN COUNTERS
    // =============================================================

    /**
     * @dev Returns the total number of tokens in existence.
     * Burned tokens will reduce the count.
     * To get the total number of tokens minted, please see {_totalMinted}.
     */
    function totalSupply() external view returns (uint256);

    // =============================================================
    //                            IERC165
    // =============================================================

    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * [EIP section](https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified)
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);

    // =============================================================
    //                            IERC721
    // =============================================================

    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables
     * (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in `owner`'s account.
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
     * @dev Safely transfers `tokenId` token from `from` to `to`,
     * checking first that contract recipients are aware of the ERC721 protocol
     * to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be have been allowed to move
     * this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement
     * {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
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
     * @dev Equivalent to `safeTransferFrom(from, to, tokenId, '')`.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom}
     * whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token
     * by either {approve} or {setApprovalForAll}.
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
     * Only a single account can be approved at a time, so approving the
     * zero address clears previous approvals.
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
     * Operators can call {transferFrom} or {safeTransferFrom}
     * for any token owned by the caller.
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
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);

    // =============================================================
    //                        IERC721Metadata
    // =============================================================

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

    // =============================================================
    //                           IERC2309
    // =============================================================

    /**
     * @dev Emitted when tokens in `fromTokenId` to `toTokenId`
     * (inclusive) is transferred from `from` to `to`, as defined in the
     * [ERC2309](https://eips.ethereum.org/EIPS/eip-2309) standard.
     *
     * See {_mintERC2309} for more details.
     */
    event ConsecutiveTransfer(uint256 indexed fromTokenId, uint256 toTokenId, address indexed from, address indexed to);
}

// SPDX-License-Identifier: MIT
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