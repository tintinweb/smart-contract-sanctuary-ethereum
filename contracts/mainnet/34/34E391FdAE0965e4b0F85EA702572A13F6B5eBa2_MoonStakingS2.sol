// SPDX-License-Identifier: MIT
// File: @openzeppelin/contracts/token/ERC721/IERC721Receiver.sol

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

// File: @openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol

// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

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

// File: @openzeppelin/contracts/security/ReentrancyGuard.sol

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

// OpenZeppelin Contracts (last updated v4.8.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(
        address indexed from,
        address indexed to,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(
        address indexed owner,
        address indexed approved,
        uint256 indexed tokenId
    );

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(
        address indexed owner,
        address indexed operator,
        bool approved
    );

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
    function transferFrom(address from, address to, uint256 tokenId) external;

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
    function getApproved(
        uint256 tokenId
    ) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(
        address owner,
        address operator
    ) external view returns (bool);
}

// File: @openzeppelin/contracts/utils/Context.sol

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

// File: @openzeppelin/contracts/access/Ownable.sol

// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

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

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
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

// File: MoonStakingS2.sol

pragma solidity ^0.8.17;

interface IMoonStaking {
    function getTokenYield(
        address contractAddress,
        uint256 tokenId
    ) external view returns (uint256);

    function getStakerNFT(
        address staker
    )
        external
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        );

    function balanceOf(address owner) external view returns (uint256 balance);
}

contract MoonStakingS2 is ERC721Holder, Ownable, ReentrancyGuard {
    IERC721 public GenesisNFT;
    IERC721 public MutantNFT;
    IERC721 public DekuNFT;
    IMoonStaking public MoonStakingS1;

    uint256 public constant SECONDS_IN_DAY = 86400;
    uint256 public startTimestamp;
    bool public stakingLaunched;
    bool public depositPaused;
    bool public genesisOwnershipRequired;

    struct Staker {
        uint256 accumulatedAmount; // DO need this
        uint256 lastCheckpoint; // AND his
        uint256[] stakedGENESIS;
        uint256[] stakedMUTANT;
        uint256[] stakedDEKU;
    }

    mapping(address => Staker) private _stakers;
    mapping(uint256 => uint256) private _yieldmapping;

    enum ContractTypes {
        GENESIS,
        MUTANT,
        DEKU
    }

    mapping(address => ContractTypes) private _contractTypes;

    mapping(address => uint256) public _baseRates;
    mapping(address => mapping(uint256 => uint256)) private _rarityMultiplyer;
    mapping(address => mapping(uint256 => address)) private _ownerOfToken;
    uint256[] private _mutantRewards;

    mapping(address => bool) private _authorised;
    address[] public authorisedLog;

    event Stake721(
        address indexed staker,
        address contractAddress,
        uint256 tokensAmount
    );

    event Unstake721(
        address indexed staker,
        address contractAddress,
        uint256 tokensAmount
    );

    event ForceWithdraw721(
        address indexed receiver,
        address indexed tokenAddress,
        uint256 indexed tokenId
    );

    constructor(address _genesis, address _mooonstakings1) {
        GenesisNFT = IERC721(_genesis);
        _contractTypes[_genesis] = ContractTypes.GENESIS;
        _baseRates[_genesis] = 250 ether;
        MoonStakingS1 = IMoonStaking(_mooonstakings1);
        _yieldmapping[150000000000000000000] = 250000000000000000000;
        _yieldmapping[180000000000000000000] = 300000000000000000000;
        _yieldmapping[210000000000000000000] = 350000000000000000000;
        _yieldmapping[240000000000000000000] = 425000000000000000000;
        _yieldmapping[300000000000000000000] = 550000000000000000000;
        genesisOwnershipRequired = true;
    }

    modifier authorised() {
        require(
            _authorised[_msgSender()],
            "The token contract is not authorised"
        );
        _;
    }

    function _validateGenesisOwnership(
        address user
    ) internal view returns (bool) {
        if (!genesisOwnershipRequired) return true;
        if (balanceOf(user) > 0) {
            return true;
        }
        return GenesisNFT.balanceOf(user) > 0;
    }

    function stake721(
        address contractAddress,
        uint256[] memory tokenIds
    ) public nonReentrant {
        require(!depositPaused, "Deposit paused");
        require(stakingLaunched, "Staking is not launched yet");
        require(
            (contractAddress != address(0) &&
                contractAddress == address(GenesisNFT)) ||
                contractAddress == address(MutantNFT) ||
                contractAddress == address(DekuNFT),
            "Unknown contract or staking is not yet enabled for this NFT"
        );
        if (contractAddress == address(MutantNFT) && genesisOwnershipRequired) {
            require(
                _validateGenesisOwnership(_msgSender()),
                "You do not have any Genesis NFTs"
            );
        }
        ContractTypes contractType = _contractTypes[contractAddress];

        Staker storage user = _stakers[_msgSender()];

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                IERC721(contractAddress).ownerOf(tokenIds[i]) == _msgSender(),
                "Not the owner of staking NFT"
            );
            IERC721(contractAddress).safeTransferFrom(
                _msgSender(),
                address(this),
                tokenIds[i]
            );

            _ownerOfToken[contractAddress][tokenIds[i]] = _msgSender();

            if (contractType == ContractTypes.GENESIS) {
                user.stakedGENESIS.push(tokenIds[i]);
            }
            if (contractType == ContractTypes.MUTANT) {
                user.stakedMUTANT.push(tokenIds[i]);
            }
            if (contractType == ContractTypes.DEKU) {
                user.stakedDEKU.push(tokenIds[i]);
            }
        }

        accumulate(_msgSender());

        emit Stake721(_msgSender(), contractAddress, tokenIds.length);
    }

    function unstake721(
        address contractAddress,
        uint256[] memory tokenIds
    ) public nonReentrant {
        require(
            (contractAddress != address(0) &&
                contractAddress == address(GenesisNFT)) ||
                contractAddress == address(MutantNFT) ||
                contractAddress == address(DekuNFT),
            "Unknown contract or staking is not yet enabled for this NFT"
        );
        ContractTypes contractType = _contractTypes[contractAddress];
        Staker storage user = _stakers[_msgSender()];

        for (uint256 i; i < tokenIds.length; i++) {
            require(
                IERC721(contractAddress).ownerOf(tokenIds[i]) == address(this),
                "Not the owner"
            );

            _ownerOfToken[contractAddress][tokenIds[i]] = address(0);

            if (contractType == ContractTypes.GENESIS) {
                user.stakedGENESIS = _prepareForDeletion(
                    user.stakedGENESIS,
                    tokenIds[i]
                );
                user.stakedGENESIS.pop();
            }
            if (contractType == ContractTypes.MUTANT) {
                user.stakedMUTANT = _prepareForDeletion(
                    user.stakedMUTANT,
                    tokenIds[i]
                );
                user.stakedMUTANT.pop();
            }
            if (contractType == ContractTypes.DEKU) {
                user.stakedDEKU = _prepareForDeletion(
                    user.stakedDEKU,
                    tokenIds[i]
                );
                user.stakedDEKU.pop();
            }

            IERC721(contractAddress).safeTransferFrom(
                address(this),
                _msgSender(),
                tokenIds[i]
            );
        }

        accumulate(_msgSender()); // TODO make sure this is up to date

        emit Unstake721(_msgSender(), contractAddress, tokenIds.length);
    }

    function getTokenYield(
        address contractAddress,
        uint256 tokenId
    ) public view returns (uint256) {
        if (contractAddress == address(GenesisNFT)) {
            return getGenesisYield(tokenId);
        } else if (contractAddress == address(MutantNFT)) {
            return getMutantsYield(tokenId);
        } else if (contractAddress == address(DekuNFT)) {
            return getDekuYield(tokenId);
        } else {
            return 0;
        }
    }

    function getGenesisYield(uint genesisId) public view returns (uint256) {
        uint s1Yield = MoonStakingS1.getTokenYield(
            address(GenesisNFT),
            genesisId
        );
        return _yieldmapping[s1Yield];
    }

    function getMutantsYield(uint mutantId) public view returns (uint256) {
        if (mutantId > 16000) {
            return _mutantRewards[2];
        } else if (mutantId > 10000) {
            return _mutantRewards[1];
        } else {
            return _mutantRewards[0];
        }
    }

    function getDekuYield(uint dekuId) public view returns (uint256) {
        uint256 tokenYield = _rarityMultiplyer[address(DekuNFT)][dekuId] *
            _baseRates[address(DekuNFT)];
        if (tokenYield == 0) {
            tokenYield = _baseRates[address(DekuNFT)];
        }

        return tokenYield;
    }

    function getStakerYield(address staker) public view returns (uint256) {
        // return _stakers[staker].currentYield;
        uint256[] memory remoteGenesis;
        (remoteGenesis, , , , ) = MoonStakingS1.getStakerNFT(staker);
        uint256 yield = 0;
        for (uint256 i = 0; i < remoteGenesis.length; i++) {
            yield += getGenesisYield(remoteGenesis[i]);
        }

        // uint256[] localGenesis = _stakers[staker].stakedGENESIS;
        for (uint256 i = 0; i < _stakers[staker].stakedGENESIS.length; i++) {
            yield += getGenesisYield(_stakers[staker].stakedGENESIS[i]);
        }

        uint256[] memory localMutant = _stakers[staker].stakedMUTANT;
        for (uint256 i = 0; i < localMutant.length; i++) {
            yield += getMutantsYield(localMutant[i]);
        }

        uint256[] memory localDeku = _stakers[staker].stakedDEKU;
        for (uint256 i = 0; i < localDeku.length; i++) {
            yield += getMutantsYield(localDeku[i]);
        }

        return yield;
    }

    function getStakerNFT(
        address staker
    )
        public
        view
        returns (
            uint256[] memory,
            uint256[] memory,
            uint256[] memory,
            uint256[] memory
        )
    {
        uint256[] memory remoteGenesis;
        (remoteGenesis, , , , ) = MoonStakingS1.getStakerNFT(staker);
        return (
            _stakers[staker].stakedGENESIS,
            _stakers[staker].stakedMUTANT,
            _stakers[staker].stakedDEKU,
            remoteGenesis
        );
    }

    /* Moving the token last in list */
    function _prepareForDeletion(
        uint256[] memory list,
        uint256 tokenId
    ) internal pure returns (uint256[] memory) {
        bool inlist = false;
        for (uint256 i = 0; i < list.length; i++) {
            if (list[i] == tokenId) {
                list[i] = list[list.length - 1];
                list[list.length - 1] = tokenId;
                inlist = true;
                break;
            }
        }
        require(inlist, "Not the owner or duplicate NFT in list");
        return list;
    }

    function getCurrentReward(address staker) public view returns (uint256) {
        require(stakingLaunched, "Staking not launched");
        Staker memory user = _stakers[staker];
        uint256 userYield = getStakerYield(staker);
        if (user.lastCheckpoint == 0) {
            if (userYield != 0) {
                return
                    ((block.timestamp - startTimestamp) * userYield) /
                    SECONDS_IN_DAY;
            }
            return 0;
        }
        return
            ((block.timestamp - user.lastCheckpoint) * userYield) /
            SECONDS_IN_DAY;
    }

    function getAccumulatedAmount(
        address staker
    ) external view returns (uint256) {
        return _stakers[staker].accumulatedAmount + getCurrentReward(staker);
    }

    function accumulate(address staker) internal {
        _stakers[staker].accumulatedAmount += getCurrentReward(staker);
        _stakers[staker].lastCheckpoint = block.timestamp;
    }

    function updateAccumulatedAmount(address staker) public {
        accumulate(staker);
    }

    /**
     * CONTRACTS
     */
    function ownerOf(
        address contractAddress,
        uint256 tokenId
    ) public view returns (address) {
        return _ownerOfToken[contractAddress][tokenId];
    }

    function balanceOf(address user) public view returns (uint256) {
        uint oldBalanceOf = MoonStakingS1.balanceOf(user);
        return _stakers[user].stakedGENESIS.length + oldBalanceOf;
    }

    function setDEKUContract(
        address _deku,
        uint256 _baseReward
    ) public onlyOwner {
        DekuNFT = IERC721(_deku);
        _contractTypes[_deku] = ContractTypes.DEKU;
        _baseRates[_deku] = _baseReward;
    }

    function setMUTANTContract(
        address _mutant,
        uint256[] memory _mutantrewards
    ) public onlyOwner {
        require(_mutantrewards.length == 3, "wrong number of rewards");
        MutantNFT = IERC721(_mutant);
        _contractTypes[_mutant] = ContractTypes.MUTANT;
        _mutantRewards = _mutantrewards;
    }

    /**
     * ADMIN
     */
    function authorise(address toAuth) public onlyOwner {
        _authorised[toAuth] = true;
        authorisedLog.push(toAuth);
    }

    function unauthorise(address addressToUnAuth) public onlyOwner {
        _authorised[addressToUnAuth] = false;
    }

    function forceWithdraw721(
        address tokenAddress,
        uint256[] memory tokenIds
    ) public onlyOwner {
        require(tokenIds.length <= 50, "50 is max per tx");
        pauseDeposit(true);
        for (uint256 i; i < tokenIds.length; i++) {
            address receiver = _ownerOfToken[tokenAddress][tokenIds[i]];
            if (
                receiver != address(0) &&
                IERC721(tokenAddress).ownerOf(tokenIds[i]) == address(this)
            ) {
                IERC721(tokenAddress).transferFrom(
                    address(this),
                    receiver,
                    tokenIds[i]
                );
                emit ForceWithdraw721(receiver, tokenAddress, tokenIds[i]);
            }
        }
    }

    function pauseDeposit(bool _pause) public onlyOwner {
        depositPaused = _pause;
    }

    function launchStaking() public onlyOwner {
        require(!stakingLaunched, "Staking has been launched already");
        stakingLaunched = true;
        startTimestamp = block.timestamp;
    }

    function updateBaseYield(
        address _contract,
        uint256 _yield
    ) public onlyOwner {
        _baseRates[_contract] = _yield;
    }

    function setIndividualRates(
        address contractAddress,
        uint256[] memory tokenIds,
        uint256[] memory rates
    ) public onlyOwner {
        // TODO redo this for Deku only?
        require(
            (contractAddress != address(0) &&
                contractAddress == address(GenesisNFT)) ||
                contractAddress == address(MutantNFT) ||
                contractAddress == address(DekuNFT),
            "Unknown contract"
        );
        require(tokenIds.length == rates.length, "Lists not same length");
        for (uint256 i; i < tokenIds.length; i++) {
            _rarityMultiplyer[contractAddress][tokenIds[i]] = rates[i];
        }
    }

    function setGenesisOwnershipRequired(bool _newvalue) public onlyOwner {
        genesisOwnershipRequired = _newvalue;
    }

    function withdrawETH() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}