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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

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
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/IERC20Metadata.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";

/**
 * @dev Interface for the optional metadata functions from the ERC20 standard.
 *
 * _Available since v4.1._
 */
interface IERC20Metadata is IERC20 {
    /**
     * @dev Returns the name of the token.
     */
    function name() external view returns (string memory);

    /**
     * @dev Returns the symbol of the token.
     */
    function symbol() external view returns (string memory);

    /**
     * @dev Returns the decimals places of the token.
     */
    function decimals() external view returns (uint8);
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

//SPDX-License-Identifier: MIT
/**
███    ███  █████  ████████ ██████  ██ ██   ██     ██████   █████   ██████  
████  ████ ██   ██    ██    ██   ██ ██  ██ ██      ██   ██ ██   ██ ██    ██ 
██ ████ ██ ███████    ██    ██████  ██   ███       ██   ██ ███████ ██    ██ 
██  ██  ██ ██   ██    ██    ██   ██ ██  ██ ██      ██   ██ ██   ██ ██    ██ 
██      ██ ██   ██    ██    ██   ██ ██ ██   ██     ██████  ██   ██  ██████  

Website: https://matrixdaoresearch.xyz/
Twitter: https://twitter.com/MatrixDAO_
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "./interfaces/INFTMatrixDao.sol";

contract MatrixVotingPower is IERC20, IERC20Metadata, Ownable {
    string constant NOT_IMPLEMENTED_MSG = "MatrixVotingPower: not implemented";
    uint256 constant ENDTOKEN_ID_LAST_TOKEN = 0;

    address public immutable nft;
    address public immutable mtx;

    mapping(uint256 => bool) public blackList;
    uint256 public numBlackList;

    constructor(address _nft, address _mtx){
        nft = _nft;
        mtx = _mtx;
    }

    function addToBlackList(uint256 tokenId) external onlyOwner {
        require(!blackList[tokenId], "MatrixVotingPower: already in the blacklist");
        blackList[tokenId] = true;
        numBlackList++;
    }

    function removeFromBlackList(uint256 tokenId) external onlyOwner {
        require(blackList[tokenId], "MatrixVotingPower: not in the blacklist");
        blackList[tokenId] = false;
        numBlackList--;
    }

    function name() external override pure returns (string memory) {
        return "Matrix DAO Voting Power";
    }

    function symbol() external override pure returns (string memory) {
        return "MTX";
    }

    function decimals() external override view returns (uint8) {
        return IERC20Metadata(mtx).decimals();
    }

    function totalSupply() external override view returns (uint256) {
        return INFTMatrixDao(nft).totalSupply();
    }

    function balanceOf(address account) external override view returns (uint256) {
        uint256 validNFT = 0;
        if(INFTMatrixDao(nft).balanceOf(account) != 0) {
            uint256[] memory tokenIds; 
            uint256 endTokenId;
            (tokenIds, endTokenId) = INFTMatrixDao(nft).ownedTokens(account, 1, ENDTOKEN_ID_LAST_TOKEN); 

            for(uint256 i=0;i<tokenIds.length;i++) {
                uint256 tokenId = tokenIds[i];
                if(!blackList[tokenId]){
                    validNFT++;
                }
            }

            if(validNFT > 0) {
                return IERC20(mtx).balanceOf(account);
            } else {
                return 0;
            }
        }
        return 0;
    }


    // Unused interfaces

    function transfer(address to, uint256 amount) external override returns (bool) {
        revert(NOT_IMPLEMENTED_MSG);
    }
    function allowance(address owner, address spender) external override view returns (uint256) {
        revert(NOT_IMPLEMENTED_MSG);
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        revert(NOT_IMPLEMENTED_MSG);
    }

    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external override returns (bool) {
        revert(NOT_IMPLEMENTED_MSG);
    }

}

//SPDX-License-Identifier: MIT
/**
███    ███  █████  ████████ ██████  ██ ██   ██     ██████   █████   ██████  
████  ████ ██   ██    ██    ██   ██ ██  ██ ██      ██   ██ ██   ██ ██    ██ 
██ ████ ██ ███████    ██    ██████  ██   ███       ██   ██ ███████ ██    ██ 
██  ██  ██ ██   ██    ██    ██   ██ ██  ██ ██      ██   ██ ██   ██ ██    ██ 
██      ██ ██   ██    ██    ██   ██ ██ ██   ██     ██████  ██   ██  ██████  

Website: https://matrixdaoresearch.xyz/
Twitter: https://twitter.com/MatrixDAO_
 */
pragma solidity ^0.8.0;

interface INFTMatrixDao {
  function allowReveal (  ) external view returns ( bool );
  function approve ( address to, uint256 tokenId ) external;
  function balanceOf ( address owner ) external view returns ( uint256 );
  function devMint ( uint256 _amount, address _to ) external;
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function maxCollection (  ) external view returns ( uint256 );
  function mint ( uint32 _amount, uint32 _allowAmount, uint64 _expireTime, bytes memory _signature ) external;
  function name (  ) external view returns ( string memory );
  function numberMinted ( address _minter ) external view returns ( uint256 minted );
  function ownedTokens ( address _addr, uint256 _startId, uint256 _endId ) external view returns ( uint256[] memory tokenIds, uint256 endTokenId );
  function owner (  ) external view returns ( address );
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function price (  ) external view returns ( uint256 );
  function renounceOwnership (  ) external;
  function reveal ( uint256 _tokenId, bytes32 _hash, bytes memory _signature ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId, bytes memory _data ) external;
  function setAllowReveal ( bool _allowReveal ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setPrice ( uint256 _newPrice ) external;
  function setSigner ( address _newSigner ) external;
  function setUnrevealURI ( string memory _newURI ) external;
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory );
  function tokenReveal ( uint256 _tokenId ) external view returns ( bool isRevealed );
  function tokenURI ( uint256 _tokenId ) external view returns ( string memory uri );
  function totalMinted (  ) external view returns ( uint256 minted );
  function totalSupply (  ) external view returns ( uint256 );
  function transferFrom ( address from, address to, uint256 tokenId ) external;
  function transferOwnership ( address newOwner ) external;
  function unrevealURI (  ) external view returns ( string memory );
  function withdraw ( address _to ) external;
}