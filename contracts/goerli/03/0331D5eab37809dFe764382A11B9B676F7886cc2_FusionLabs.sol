//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IResult.sol";

contract FusionLabs is Ownable, IERC721Receiver {

    struct Host {
        address owner;
        bool burned;
        bool locked;
        bool used;
    }

    struct Stimulus {
        address owner;
        bool burned;
        bool locked;
        bool used;
    }

    IERC721 host;
    IERC721 stimulus;
    IResult result;

    mapping(uint256 => Host) hosts;
    mapping(uint256 => Stimulus) stimuli;
    mapping(uint256 => uint256) pairs;
    mapping(uint256 => bool) fusioned;
    mapping(address => uint256[]) locked;

    uint256 totalFusioned;
    uint256 maxLocked;

    event Received(uint256 _tokenId, address _owner, bytes data);
    event Fusioned(uint256 _hostTokenId, uint256 _stimulusTokenId);

    constructor(  
        IERC721 _host,
        IERC721 _stimulus,
        IResult _result,
        uint256 _maxLocked
    ) {
        host = _host;
        stimulus = _stimulus;
        result = _result;
        maxLocked = _maxLocked;
    }

    //Modifiers
    modifier onlyHostOwner(uint256 _tokenId) {
        require(host.ownerOf(_tokenId) == msg.sender, "only host owner");
        require(host.getApproved(_tokenId) == address(this), "owner does not approved their host");
        _;
    }

    modifier onlyLockedHostOwner(uint256 _tokenId) {
        require(hosts[_tokenId].owner == msg.sender, "only host owner");
        _;
    }
    
    modifier onlyStimulusOwner(uint256 _tokenId) {
        require(stimulus.ownerOf(_tokenId) == msg.sender, "only stimulus owner");
        require(stimulus.getApproved(_tokenId) == address(this), "owner does not approved their stimulus");
        _;
    }

    modifier onlyLockedStimulusOwner(uint256 _tokenId) {
        require(stimuli[_tokenId].owner == msg.sender, "only stimulus owner");
        _;
    }

    modifier onlyFusionAble(uint256 _hostTokenId, uint256 _stimulusTokenId) {
        require(hosts[_hostTokenId].locked, "token does not locked");
        require(!hosts[_hostTokenId].used, "token is already fusioned");
        require(stimuli[_stimulusTokenId].locked, "token does not locked");
        require(!stimuli[_stimulusTokenId].used, "token is already fusioned");
        require(!fusioned[_hostTokenId], "token is already fusioned");
        _;
    }

    modifier cancelAble(uint256 _hostTokenId) {
        require(hosts[_hostTokenId].locked, "token does not locked");
        require(!hosts[_hostTokenId].used, "token is already used");
        _;
    }

    //Locking 
    function lock(uint256 _hostTokenId, uint256 _stimulusTokenId) public 
        onlyHostOwner(_hostTokenId)
        onlyStimulusOwner(_stimulusTokenId)
    { 
        pairs[_hostTokenId] = _stimulusTokenId;
        locked[msg.sender].push(_hostTokenId);
        _lockHost(_hostTokenId);
        _lockStimulus(_stimulusTokenId);
    }

    function getFusionablePairs(address _owner) public view returns(string memory) {
        string memory useables;
        uint256[] memory lockedHosts = locked[_owner];
        for(uint256 i; i < lockedHosts.length; ++i) {
            if(hosts[lockedHosts[i]].locked && !hosts[lockedHosts[i]].used) {
                useables = string(abi.encodePacked(useables,'{"host":',toString(lockedHosts[i]),', "stimulus":',toString(pairs[lockedHosts[i]]),'},'));
            }
        }
        useables = substring(useables, 0, bytes(useables).length - 1);
        useables = string(abi.encodePacked('[',useables,']'));
    
        return useables;
    }


    function _lockHost (uint256 _tokenId) internal {
        host.safeTransferFrom(msg.sender, address(this), _tokenId, "0x01"); 
        hosts[_tokenId].owner = msg.sender;
        hosts[_tokenId].locked = true; 
    }

    function _lockStimulus (uint256 _tokenId) internal {
        stimulus.safeTransferFrom(msg.sender, address(this), _tokenId, "0x02");
        stimuli[_tokenId].owner = msg.sender;
        stimuli[_tokenId].locked = true;
    }

    function fusion(uint256 _hostTokenId, uint256 _stimulusTokenId) public 
        onlyLockedHostOwner(_hostTokenId)
        onlyLockedStimulusOwner(_stimulusTokenId)
        onlyFusionAble(_hostTokenId, _stimulusTokenId)
    {
        hosts[_hostTokenId].used = true;
        stimuli[_stimulusTokenId].used = true;
        fusioned[_hostTokenId] = true; 
        _mintTo(msg.sender);
        emit Fusioned(_hostTokenId, _stimulusTokenId);
    }

    function getFusionedOf(uint256 _hostTokenId) public view returns(uint256) {
        return pairs[_hostTokenId];
    }

    function _mintTo(address _to) internal {
        result.mint(_to);
    }

    function cancelFusion(uint256 _hostTokenId) public onlyLockedHostOwner(_hostTokenId) cancelAble(_hostTokenId) {
        uint256 stimulusTokenId = pairs[_hostTokenId];
        _withdrawHost(_hostTokenId);
        _withdrawStimulus(stimulusTokenId);
        uint256[] storage lockedHost = locked[msg.sender];
        for(uint256 i = 0; i < lockedHost.length; ++i) {
            if(lockedHost[i] == _hostTokenId) {
                _removeCancelLocked(i, lockedHost);
            }
        }
    }

    function _removeCancelLocked(uint256 index, uint256[] storage array) internal {
        for(uint i = index; i < array.length-1; i++){
            array[i] = array[i+1];      
        }
        array.pop();
    }

    function _withdrawHost(uint256 _hostTokenId) internal {
        host.safeTransferFrom(address(this), msg.sender, _hostTokenId , "0x01");
    }
    
    function _withdrawStimulus(uint256 _stimulusTokenId) internal {
        stimulus.safeTransferFrom(address(this), msg.sender, _stimulusTokenId , "0x02");
    }

    function isHostLocked(uint256 _tokenId) public view returns(bool) {
        return hosts[_tokenId].locked;
    }

    function isStimulusLocked(uint256 _tokenId) public view returns(bool) {
        return stimuli[_tokenId].locked;
    }
    
    function isFusionable(uint256 _hostTokenId, uint256 _stimulusTokenId) public view returns(bool) {
        require(isHostLocked(_hostTokenId), 'not locked yet');
        require(isStimulusLocked(_stimulusTokenId), 'not locked yet');
        require(!hosts[_hostTokenId].used, 'host has been fusioned');
        require(!stimuli[_stimulusTokenId].used, 'stimuli has been fusioned');
        require(!fusioned[_hostTokenId], 'token has been fusion');
        return pairs[_hostTokenId] == _stimulusTokenId;
    }

    function ownerOf(uint256 _hostTokenId, uint256 _stimulusTokenId, address _owner) public view returns(bool) {
        require(hosts[_hostTokenId].owner == _owner, "not host owner or not it pair.");
        require(stimuli[_stimulusTokenId].owner == _owner, "not stimulus owner or not its pair." );
        return true;
    }

    function onERC721Received(address operator, address from,  uint256 _tokenId, bytes calldata data) external override returns(bytes4) {
        emit Received(_tokenId, from, data);
        return this.onERC721Received.selector;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }

    function substring(
        string memory str,
        uint256 startIndex,
        uint256 endIndex
    ) internal pure returns (string memory) {
        bytes memory strBytes = bytes(str);
        bytes memory result = new bytes(endIndex - startIndex);
        for (uint256 i = startIndex; i < endIndex; i++) {
            result[i - startIndex] = strBytes[i];
        }
        return string(result);
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IResult  {
  function mint(address _to) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

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