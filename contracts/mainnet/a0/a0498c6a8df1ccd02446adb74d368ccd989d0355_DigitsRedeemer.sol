/**
 *Submitted for verification at Etherscan.io on 2022-11-07
*/

// SPDX-License-Identifier: GPL-3.0
// File: @openzeppelin/contracts/utils/Strings.sol

/// @title Digits Redeemer
/// @author André Costa @ DigitsBrands

// File: @openzeppelin/contracts/utils/Context.sol


// OpenZeppelin Contracts v4.4.0 (utils/Context.sol)

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


// OpenZeppelin Contracts v4.4.0 (access/Ownable.sol)

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

// File: raribots.sol


// File: @openzeppelin/contracts/utils/Strings.sol

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

    function transferToStakingPool(
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

interface IAgentsRaffle {
    function addToStakers(address newStaker) external;
}

interface IDigitsRedeemer {
    /**
     * @dev Returns if the `tokenId` has been staked and therefore blocking transfers.
     */
    function isStaked(uint tokenId) external view returns (bool);
}

contract DigitsRedeemer is IDigitsRedeemer, Ownable {
    
    struct StakeInfo {
        uint timePeriod; //the option selected for staking (30, 60, 90, ... days)
        uint[] tokens; //list of all the tokens that are staked]
        uint256 endTime; //unix timestamp of end of staking
    }
    
    //get information for each address and each type of token
    mapping(address => StakeInfo) private addressToFoundingAgentsStaked;
    mapping(address => StakeInfo) private addressToDigitsAgentsStaked;

    //see if a token is staked or not
    mapping(uint => bool) private stakedTokensFounding;
    mapping(uint => bool) private stakedTokensDigits;

    //if a time period exists
    mapping(uint => bool) public timePeriodOptions;

    //dummy address that we use to sign the mint transaction to make sure it is valid
    address private dummy = 0x80E4929c869102140E69550BBECC20bEd61B080c;

    uint256 public nonce;

    IERC721Enumerable public DigitsAgents;
    IERC721Enumerable public FoundingAgents;
    IAgentsRaffle public AgentsRaffle;

    constructor() {
        DigitsAgents = IERC721Enumerable(0x3F39ca26C1f4A213E96b3676412A41969EC2BB2A);
        FoundingAgents = IERC721Enumerable(0x226a8FF878737179101701Ac16d071cD80cEc1E2);
        AgentsRaffle = IAgentsRaffle(0x45581C6Aa05E288E2Ed95636E9E4C7ab21AA237A);
    }

    //set ERC721Enumerable
    function setDigitsAgents(address newInterface) public onlyOwner {
        DigitsAgents = IERC721Enumerable(newInterface);
    }

    //set ERC721Enumerable
    function setAgentsRaffle(address newInterface) public onlyOwner {
        AgentsRaffle = IAgentsRaffle(newInterface);
    }

    //set signer public address
    function setDummy(address newDummy) external onlyOwner {
        dummy = newDummy;
    }

    //add time periods to the options
    function addTimePeriods(uint[] calldata timePeriods) public onlyOwner {
        for (uint i; i < timePeriods.length; i++) {
            timePeriodOptions[timePeriods[i]] = true;
        }
    }

    //remove time periods from the options
    function removeTimePeriods(uint[] calldata timePeriods) public onlyOwner {
        for (uint i; i < timePeriods.length; i++) {
            timePeriodOptions[timePeriods[i]] = false;
        }
    }

    //see if a time period is a current option
    function isTimePeriod(uint timePeriod) external view returns(bool) {
        return timePeriodOptions[timePeriod];
    }

    modifier onlyValidAccess(uint8 _v, bytes32 _r, bytes32 _s) {
        require( isValidAccessMessage(msg.sender,_v,_r,_s), 'Invalid Signature' );
        _;
    }
 
    /* 
    * @dev Verifies if message was signed by owner to give access to _add for this contract.
    *      Assumes Geth signature prefix.
    * @param _add Address of agent with access
    * @param _v ECDSA signature parameter v.
    * @param _r ECDSA signature parameters r.
    * @param _s ECDSA signature parameters s.
    * @return Validity of access message for a given address.
    */
    function isValidAccessMessage(address _add, uint8 _v, bytes32 _r, bytes32 _s) view public returns (bool) {
        bytes32 hash = keccak256(abi.encodePacked(address(this), _add, nonce));
        return dummy == ecrecover(keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash)), _v, _r, _s);
    }

    //stake specific tokenIds and for specific timeperiods
    function stake(uint[] calldata tokenIds, bool isFoundingAgents, uint timePeriod, uint8 _v, bytes32 _r, bytes32 _s) onlyValidAccess(_v,  _r, _s) external {
        require(timePeriodOptions[timePeriod], "Invalid Time Period!");
        if (isFoundingAgents) {
            require(addressToFoundingAgentsStaked[msg.sender].endTime <= block.timestamp + (timePeriod * 86400), "New time period must be equal or greater!");

            for (uint i = 0; i < tokenIds.length; i++) {
                require(msg.sender == FoundingAgents.ownerOf(tokenIds[i]), "Sender must be owner");
                require(!stakedTokensFounding[tokenIds[i]], "Token is already Staked!");
                
                addressToFoundingAgentsStaked[msg.sender].tokens.push(tokenIds[i]);
                //set the info for the stake
                stakedTokensFounding[tokenIds[i]] = true;
            }
            addressToFoundingAgentsStaked[msg.sender].timePeriod = timePeriod;
            addressToFoundingAgentsStaked[msg.sender].endTime = block.timestamp + (timePeriod * 86400);
        }
        else {
            require(addressToDigitsAgentsStaked[msg.sender].endTime <= block.timestamp + (timePeriod * 86400), "New time period must be equal or greater!");

            for (uint i = 0; i < tokenIds.length; i++) {
                require(msg.sender == DigitsAgents.ownerOf(tokenIds[i]), "Sender must be owner");
                require(!stakedTokensDigits[tokenIds[i]], "Token is already Staked!");
                
                addressToDigitsAgentsStaked[msg.sender].tokens.push(tokenIds[i]);
                //set the info for the stake
                stakedTokensDigits[tokenIds[i]] = true;
            }
            addressToDigitsAgentsStaked[msg.sender].timePeriod = timePeriod;
            addressToDigitsAgentsStaked[msg.sender].endTime = block.timestamp + (timePeriod * 86400);
        }

        AgentsRaffle.addToStakers(msg.sender);
        nonce++;
          
    }

    //unstake all nfts somebody has
    function unstake(bool isFoundingAgents) public {
        if (isFoundingAgents) {
            require(block.timestamp >= addressToFoundingAgentsStaked[msg.sender].endTime, "Staking Period is not over yet!");
        }
        else {
            require(block.timestamp >= addressToDigitsAgentsStaked[msg.sender].endTime, "Staking Period is not over yet!");
        }
        
        _unstake(msg.sender, isFoundingAgents);
        
    }

    //emergency unstake nft for a set of addresses
    function emergencyUnstake(address[] calldata unstakers, bool isFoundingAgents) external onlyOwner {
        for (uint i; i < unstakers.length; i++) {
            _unstake(unstakers[i], isFoundingAgents);
        }
    }

    function _unstake(address unstaker, bool isFoundingAgents) internal {
        if (isFoundingAgents) {
            for (uint i; i < addressToFoundingAgentsStaked[unstaker].tokens.length; i++) {
                stakedTokensFounding[addressToFoundingAgentsStaked[unstaker].tokens[i]] = false;
            }

            addressToFoundingAgentsStaked[unstaker].timePeriod = 0;
            addressToFoundingAgentsStaked[unstaker].endTime = 0;
            delete addressToFoundingAgentsStaked[unstaker].tokens; 
        }
        else {
            for (uint i; i < addressToDigitsAgentsStaked[unstaker].tokens.length; i++) {
                stakedTokensDigits[addressToDigitsAgentsStaked[unstaker].tokens[i]] = false;
            }

            addressToDigitsAgentsStaked[unstaker].timePeriod = 0;
            addressToDigitsAgentsStaked[unstaker].endTime = 0;
            delete addressToDigitsAgentsStaked[unstaker].tokens; 
        }
        
    }

    //get the info for a staked token
    function getStakedInfo(address staker, bool isFoundingAgents) external view returns(StakeInfo memory) {
        if (isFoundingAgents) {
            return addressToFoundingAgentsStaked[staker];
        }
        else {
            return addressToDigitsAgentsStaked[staker];
        }
    }
    
    //Returns if the `tokenId` has been staked and therefore blocking transfers.
    function isStaked(uint tokenId) public view returns (bool) {
        if (msg.sender == 0x3F39ca26C1f4A213E96b3676412A41969EC2BB2A) {
            return stakedTokensDigits[tokenId];
        }
        else if (msg.sender == 0x226a8FF878737179101701Ac16d071cD80cEc1E2) {
            return stakedTokensFounding[tokenId];
        }
        else {
            return stakedTokensFounding[tokenId];
        }
    }
}