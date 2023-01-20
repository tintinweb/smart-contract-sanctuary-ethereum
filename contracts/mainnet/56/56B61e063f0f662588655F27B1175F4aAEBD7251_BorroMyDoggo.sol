// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "./lib/IBAYCSewerPassClaim.sol";
import "./lib/IDelegationRegistry.sol";

contract BorroMyDoggo is IERC721Receiver, ReentrancyGuard {
    using BitMaps for BitMaps.BitMap;

    address constant public SEWER_PASS = 0x764AeebcF425d56800eF2c84F2578689415a2DAa;
    address constant public SEWER_PASS_CLAIM = 0xBA5a9E9CBCE12c70224446C24C111132BECf9F1d;
    address constant public BAYC = 0xBC4CA0EdA7647A8aB7C2061c2E118A18a936f13D;
    address constant public MAYC = 0x60E4d786628Fea6478F785A6d7e704777c86a7c6;
    address constant public BAKC = 0xba30E5F9Bb24caa003E9f2f0497Ad287FDF95623;
    address constant public FOOBAR = 0xe5ee2B9d5320f2D1492e16567F36b578372B3d9F;
    address constant public THOMAS = 0x3e6a203ab73C4B35Be1F65461D88Fb21DE26446e;
    uint64 constant public LENDER_FEE = 90;
    IDelegationRegistry delegateCash = IDelegationRegistry(0x00000000000076A84feF008CDAbe6409d2FE638B);

    BitMaps.BitMap private doggoLoaned;
    mapping(uint256 => uint256) public borroCost;
    address private currentMinter;

    /** borroDoggos allows bayc/mayc holder to mint tier 4/tier 2 sewer pass
        apes must be delegated to this contract address by ape owner using delegate.cash
        using doggo delegated and loaned by a doggo holder
        payment must be greater than or equal to sum of all doggos used and can be calculated with calculateBorroCost
        sewer passes will be minted and transfered to the account that calls this function
        minter must be direct owner or delegate for the BAYC/MAYC tokens supplied
        BAYC or MAYC can be supplied as empty arrays but total apes must equal total doggos
        90% of borro fees go to doggo owner, 5% to 0xfoobar for delegate.cash and 5% to 0xth0mas
    */
    function borroDoggos(uint256[] calldata baycIds, uint256[] calldata maycIds, uint256[] calldata doggoIds) external payable nonReentrant {
        require((baycIds.length + maycIds.length) == doggoIds.length, "APE/DOGGO COUNT MISMATCH");
        uint256 totalBorroCost = this.calculateBorroCost(doggoIds);
        require(msg.value >= totalBorroCost, "INSUFFICIENT PAYMENT");
        uint256 doggoIndex = 0;
        currentMinter = msg.sender;
        address apeOwner;
        for(uint256 i = 0;i < baycIds.length;i++) {
            apeOwner = IERC721(BAYC).ownerOf(baycIds[i]);
            require(apeOwner == msg.sender ||
                delegateCash.checkDelegateForToken(msg.sender, apeOwner, BAYC, baycIds[i]), "NOT APE OWNER OR DELEGATE");
            IBAYCSewerPassClaim(SEWER_PASS_CLAIM).claimBaycBakc(baycIds[i], doggoIds[doggoIndex]);
            payDoggoOwner(doggoIds[doggoIndex]);
            doggoIndex++;
        }
        for(uint256 i = 0;i < maycIds.length;i++) {
            apeOwner = IERC721(MAYC).ownerOf(maycIds[i]);
            require(apeOwner == msg.sender ||
                delegateCash.checkDelegateForToken(msg.sender, apeOwner, MAYC, maycIds[i]), "NOT APE OWNER OR DELEGATE");
            IBAYCSewerPassClaim(SEWER_PASS_CLAIM).claimMaycBakc(maycIds[i], doggoIds[doggoIndex]);
            payDoggoOwner(doggoIds[doggoIndex]);
            doggoIndex++;
        }
        currentMinter = address(0);
    }

    /** friendly utility function for ape holders to bulk mint sewer passes
        apes & doggos must be delegated to this contract address by owner using delegate.cash
        doggos used for tier 4 sewer passes first, when doggo count is exceeded tier 3 passes get minted
        if doggos are left after bayc sewer passes, doggos used to mint tier 2 sewer passes
        if maycs are left after doggo count is exceeded, tier 1 passes are minted
        donations appreciated but not required to use
    */
    function bulkMintSewerPass(uint256[] calldata baycIds, uint256[] calldata maycIds, uint256[] calldata doggoIds) external payable nonReentrant {
        uint256 doggoIndex = 0;
        currentMinter = msg.sender;
        address apeOwner;
        address doggoOwner;
        for(uint256 baycIndex = 0;baycIndex < baycIds.length;baycIndex++) {
            apeOwner = IERC721(BAYC).ownerOf(baycIds[baycIndex]);
            require(apeOwner == msg.sender ||
                delegateCash.checkDelegateForToken(msg.sender, apeOwner, BAYC, baycIds[baycIndex]), "NOT APE OWNER OR DELEGATE");
            if(doggoIndex >= doggoIds.length) {
                IBAYCSewerPassClaim(SEWER_PASS_CLAIM).claimBayc(baycIds[baycIndex]);
            } else {
                doggoOwner = IERC721(BAKC).ownerOf(doggoIds[doggoIndex]);
                require(doggoOwner == msg.sender ||
                    delegateCash.checkDelegateForToken(msg.sender, doggoOwner, BAKC, doggoIds[doggoIndex]), "NOT DOGGO OWNER OR DELEGATE");
                IBAYCSewerPassClaim(SEWER_PASS_CLAIM).claimBaycBakc(baycIds[baycIndex], doggoIds[doggoIndex]);
                doggoIndex++;
            }
        }
        for(uint256 maycIndex = 0;maycIndex < maycIds.length;maycIndex++) {
            apeOwner = IERC721(MAYC).ownerOf(maycIds[maycIndex]);
            require(apeOwner == msg.sender ||
                delegateCash.checkDelegateForToken(msg.sender, apeOwner, MAYC, maycIds[maycIndex]), "NOT APE OWNER OR DELEGATE");
            if(doggoIndex >= doggoIds.length) {
                IBAYCSewerPassClaim(SEWER_PASS_CLAIM).claimMayc(maycIds[maycIndex]);
            } else {
                doggoOwner = IERC721(BAKC).ownerOf(doggoIds[doggoIndex]);
                require(doggoOwner == msg.sender ||
                    delegateCash.checkDelegateForToken(msg.sender, doggoOwner, BAKC, doggoIds[doggoIndex]), "NOT DOGGO OWNER OR DELEGATE");
                IBAYCSewerPassClaim(SEWER_PASS_CLAIM).claimMaycBakc(maycIds[maycIndex], doggoIds[doggoIndex]);
                doggoIndex++;
            }
        }
        currentMinter = address(0);
    }

    /** calculate and send payment for use of doggo in minting sewer pass, cleans up state
    */
    function payDoggoOwner(uint256 doggoId) internal {
        address doggoOwner = IERC721(BAKC).ownerOf(doggoId);
        uint256 payment = borroCost[doggoId] * LENDER_FEE / 100;
        (bool sent, ) = payable(doggoOwner).call{value: payment}("");
        require(sent);
        borroCost[doggoId] = 0;
        doggoLoaned.unset(doggoId);
    }

    /** withdraw fees for 0xfoobar and 0xth0mas
    */
    function withdraw() external {
        uint256 feesCollected = address(this).balance;
        uint256 foobarShare = feesCollected / 2;
        (bool fbSent, ) = payable(FOOBAR).call{value: foobarShare}("");
        require(fbSent);
        (bool tSent, ) = payable(THOMAS).call{value: (feesCollected -foobarShare)}("");
        require(tSent);
    }

    /** loan doggos for bayc/mayc to mint higher tier sewer passes
        doggos must be delegated to this contract address by doggo owner using delegate.cash
        doggoIds = array of doggos to loan out, must be direct owner or delegate to call
        costToBorro = payment to be received when your doggo is used to mint a sewer pass, cost is in WEI
        payment will be sent to doggo owner wallet
        can be called again to adjust costToBorro
    */
    function loanDoggos(uint256[] calldata doggoIds, uint256 costToBorro) external {
        address doggoOwner;
        for(uint256 doggoIndex = 0;doggoIndex < doggoIds.length;doggoIndex++) {
            doggoOwner = IERC721(BAKC).ownerOf(doggoIds[doggoIndex]);
            require(doggoOwner == msg.sender ||
                delegateCash.checkDelegateForToken(msg.sender, doggoOwner, BAKC, doggoIds[doggoIndex]), "NOT DOGGO OWNER OR DELEGATE");
            doggoLoaned.set(doggoIds[doggoIndex]);
            borroCost[doggoIds[doggoIndex]] = costToBorro;
        }
    }

    /** takes doggo off loan, you can also revoke delegation to this contract with delegate.cash for same effect
    */
    function unloanDoggos(uint256[] calldata doggoIds) external {
        address doggoOwner;
        for(uint256 doggoIndex = 0;doggoIndex < doggoIds.length;doggoIndex++) {
            doggoOwner = IERC721(BAKC).ownerOf(doggoIds[doggoIndex]);
            require(doggoOwner == msg.sender ||
                delegateCash.checkDelegateForToken(msg.sender, doggoOwner, BAKC, doggoIds[doggoIndex]), "NOT DOGGO OWNER OR DELEGATE");
            doggoLoaned.unset(doggoIds[doggoIndex]);
            borroCost[doggoIds[doggoIndex]] = 0;
        }
    }

    struct DoggoLoaned {
        uint64 doggoId;
        uint64 borroCost;
    }

    /** utility function to return list of available doggos for sewer pass minting and cost to borro for each doggo
        find cheapest doggo ids to borrow and supply array to calculateBorroCost for total cost
    */
    function availableDoggos() external view returns(DoggoLoaned[] memory) {
        uint256 doggosAvailable = 0;
        address doggoOwner;
        for(uint256 doggoIndex = 0;doggoIndex < 10000;doggoIndex++) {
            try IERC721(BAKC).ownerOf(doggoIndex) returns (address result) { doggoOwner = result; } catch { doggoOwner = address(0); }
            if(doggoLoaned.get(doggoIndex) && 
              delegateCash.checkDelegateForToken(address(this), doggoOwner, BAKC, doggoIndex) &&
              !IBAYCSewerPassClaim(SEWER_PASS_CLAIM).bakcClaimed(doggoIndex)) {
                doggosAvailable++;
            }
        }

        DoggoLoaned[] memory loans = new DoggoLoaned[](doggosAvailable);
        uint256 currentIndex = 0;
        for(uint256 doggoIndex = 0;doggoIndex < 10000;doggoIndex++) {
            try IERC721(BAKC).ownerOf(doggoIndex) returns (address result) { doggoOwner = result; } catch { doggoOwner = address(0); }
            if(doggoLoaned.get(doggoIndex) && 
              delegateCash.checkDelegateForToken(address(this), doggoOwner, BAKC, doggoIndex) &&
              !IBAYCSewerPassClaim(SEWER_PASS_CLAIM).bakcClaimed(doggoIndex)) {
                  DoggoLoaned memory dl;
                  dl.doggoId = uint64(doggoIndex);
                  dl.borroCost = uint64(borroCost[doggoIndex]);
                loans[currentIndex] = dl;
                currentIndex++;
                if(currentIndex >= doggosAvailable) { break; }
            }
        }
        return loans;
    }

    /** calculates total cost of doggo borrowing
    */
    function calculateBorroCost(uint256[] calldata doggoIds) external view returns(uint256 totalBorroCost) {
        for(uint256 i = 0;i < doggoIds.length;i++) {
            require(doggoLoaned.get(doggoIds[i]), "DOGGO NOT LOANED");
            totalBorroCost += borroCost[doggoIds[i]];
        }
    }

    /** receives sewer pass from sewer pass mint function, transfers to current minter
    */
    function onERC721Received(address operator, address, uint256 tokenId, bytes calldata) external returns (bytes4) {
        require(operator == SEWER_PASS_CLAIM);
        require(currentMinter != address(0));
        IERC721(SEWER_PASS).safeTransferFrom(address(this), currentMinter, tokenId);
        return IERC721Receiver.onERC721Received.selector;
    }
}

// SPDX-License-Identifier: CC0-1.0
pragma solidity ^0.8.17;

/**
 * @title An immutable registry contract to be deployed as a standalone primitive
 * @dev See EIP-5639, new project launches can read previous cold wallet -> hot wallet delegations
 * from here and integrate those permissions into their flow
 */
interface IDelegationRegistry {
    /// @notice Delegation type
    enum DelegationType {
        NONE,
        ALL,
        CONTRACT,
        TOKEN
    }

    /// @notice Info about a single delegation, used for onchain enumeration
    struct DelegationInfo {
        DelegationType type_;
        address vault;
        address delegate;
        address contract_;
        uint256 tokenId;
    }

    /// @notice Info about a single contract-level delegation
    struct ContractDelegation {
        address contract_;
        address delegate;
    }

    /// @notice Info about a single token-level delegation
    struct TokenDelegation {
        address contract_;
        uint256 tokenId;
        address delegate;
    }

    /// @notice Emitted when a user delegates their entire wallet
    event DelegateForAll(address vault, address delegate, bool value);

    /// @notice Emitted when a user delegates a specific contract
    event DelegateForContract(address vault, address delegate, address contract_, bool value);

    /// @notice Emitted when a user delegates a specific token
    event DelegateForToken(address vault, address delegate, address contract_, uint256 tokenId, bool value);

    /// @notice Emitted when a user revokes all delegations
    event RevokeAllDelegates(address vault);

    /// @notice Emitted when a user revoes all delegations for a given delegate
    event RevokeDelegate(address vault, address delegate);

    /**
     * -----------  WRITE -----------
     */

    /**
     * @notice Allow the delegate to act on your behalf for all contracts
     * @param delegate The hotwallet to act on your behalf
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForAll(address delegate, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific contract
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForContract(address delegate, address contract_, bool value) external;

    /**
     * @notice Allow the delegate to act on your behalf for a specific token
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param value Whether to enable or disable delegation for this address, true for setting and false for revoking
     */
    function delegateForToken(address delegate, address contract_, uint256 tokenId, bool value) external;

    /**
     * @notice Revoke all delegates
     */
    function revokeAllDelegates() external;

    /**
     * @notice Revoke a specific delegate for all their permissions
     * @param delegate The hotwallet to revoke
     */
    function revokeDelegate(address delegate) external;

    /**
     * @notice Remove yourself as a delegate for a specific vault
     * @param vault The vault which delegated to the msg.sender, and should be removed
     */
    function revokeSelf(address vault) external;

    /**
     * -----------  READ -----------
     */

    /**
     * @notice Returns all active delegations a given delegate is able to claim on behalf of
     * @param delegate The delegate that you would like to retrieve delegations for
     * @return info Array of DelegationInfo structs
     */
    function getDelegationsByDelegate(address delegate) external view returns (DelegationInfo[] memory);

    /**
     * @notice Returns an array of wallet-level delegates for a given vault
     * @param vault The cold wallet who issued the delegation
     * @return addresses Array of wallet-level delegates for a given vault
     */
    function getDelegatesForAll(address vault) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault and contract
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract you're delegating
     * @return addresses Array of contract-level delegates for a given vault and contract
     */
    function getDelegatesForContract(address vault, address contract_) external view returns (address[] memory);

    /**
     * @notice Returns an array of contract-level delegates for a given vault's token
     * @param vault The cold wallet who issued the delegation
     * @param contract_ The address for the contract holding the token
     * @param tokenId The token id for the token you're delegating
     * @return addresses Array of contract-level delegates for a given vault's token
     */
    function getDelegatesForToken(address vault, address contract_, uint256 tokenId)
        external
        view
        returns (address[] memory);

    /**
     * @notice Returns all contract-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of ContractDelegation structs
     */
    function getContractLevelDelegations(address vault)
        external
        view
        returns (ContractDelegation[] memory delegations);

    /**
     * @notice Returns all token-level delegations for a given vault
     * @param vault The cold wallet who issued the delegations
     * @return delegations Array of TokenDelegation structs
     */
    function getTokenLevelDelegations(address vault) external view returns (TokenDelegation[] memory delegations);

    /**
     * @notice Returns true if the address is delegated to act on the entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForAll(address delegate, address vault) external view returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a token contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForContract(address delegate, address vault, address contract_)
        external
        view
        returns (bool);

    /**
     * @notice Returns true if the address is delegated to act on your behalf for a specific token, the token's contract or an entire vault
     * @param delegate The hotwallet to act on your behalf
     * @param contract_ The address for the contract you're delegating
     * @param tokenId The token id for the token you're delegating
     * @param vault The cold wallet who issued the delegation
     */
    function checkDelegateForToken(address delegate, address vault, address contract_, uint256 tokenId)
        external
        view
        returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IBAYCSewerPassClaim {
    function claimBaycBakc(uint256 baycTokenId, uint256 bakcTokenId) external;
    function claimBayc(uint256 baycTokenId) external;
    function claimMaycBakc(uint256 maycTokenId, uint256 bakcTokenId) external;
    function claimMayc(uint256 maycTokenId) external;
    function checkClaimed(uint8 collectionId, uint256 tokenId) external view returns (bool);
    function bakcClaimed(uint256 doggoId) external view returns (bool);
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
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/structs/BitMaps.sol)
pragma solidity ^0.8.0;

/**
 * @dev Library for managing uint256 to bool mapping in a compact and efficient way, providing the keys are sequential.
 * Largely inspired by Uniswap's https://github.com/Uniswap/merkle-distributor/blob/master/contracts/MerkleDistributor.sol[merkle-distributor].
 */
library BitMaps {
    struct BitMap {
        mapping(uint256 => uint256) _data;
    }

    /**
     * @dev Returns whether the bit at `index` is set.
     */
    function get(BitMap storage bitmap, uint256 index) internal view returns (bool) {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        return bitmap._data[bucket] & mask != 0;
    }

    /**
     * @dev Sets the bit at `index` to the boolean `value`.
     */
    function setTo(
        BitMap storage bitmap,
        uint256 index,
        bool value
    ) internal {
        if (value) {
            set(bitmap, index);
        } else {
            unset(bitmap, index);
        }
    }

    /**
     * @dev Sets the bit at `index`.
     */
    function set(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] |= mask;
    }

    /**
     * @dev Unsets the bit at `index`.
     */
    function unset(BitMap storage bitmap, uint256 index) internal {
        uint256 bucket = index >> 8;
        uint256 mask = 1 << (index & 0xff);
        bitmap._data[bucket] &= ~mask;
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