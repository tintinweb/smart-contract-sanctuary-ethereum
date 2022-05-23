pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY

import "../token/token_two_interface.sol";
import "../recovery/recovery.sol";
import "../randomiser/randomiser.sol";

struct vData {
    address from;
    uint256 max_mint;
    bytes   signature;
}

contract TheWorldTodayMainSaleTwo is recovery,randomiser {

    token_two_interface             public  token;
    address                         public  oldToken;
    mapping (address => bool)               admins;
    uint256                         public  sale_price    = 8e16;

    address payable                 public  wallet;
    bool                            public  minting = false;
    uint256            constant     public  max_public_mint = 100;

    uint256              constant   public  base = 1147;
    uint256                         public  counter = 1147;
    mapping(address => uint256)     public  public_minted;

    modifier onlyAdmin() {
        require(admins[msg.sender] || (msg.sender == owner()),"onlyAdmin = no entry");
        _;
    }

    event SetAdmin(address _addr, bool _state);

    function enable_minting(bool _minting) external onlyAdmin {
        minting = _minting;
    }

    constructor(
        token_two_interface  _token, 
        address[] memory _admins,
        address payable _wallet
    )  recovery(_wallet) randomiser(1) {
        token = _token;
        wallet = _wallet;
        for (uint j = 0; j < _admins.length; j++) {
            admins[_admins[j]] = true;
        }
        setNumTokensLeft(1, 13800 - 1147);
    }


    function public_main_mint(uint256 number_to_mint) external payable {
        require(minting,"minting not enabled");
        bool adminMint = (admins[msg.sender] || (msg.sender == owner())) && msg.value == 0;
        if ( !adminMint ){
            require(msg.value == number_to_mint * sale_price,"incorrect amount sent");
            require(number_to_mint <= max_public_mint,"number requested in one tx exceeds max_public_mint");
        }
        _mintCards(number_to_mint,msg.sender);
        public_minted[msg.sender] += number_to_mint;
        sendETH(wallet,msg.value);
    }

    function sendETH(address dest, uint amount) internal {
        (bool sent, ) = payable(dest).call{value: amount}(""); // don't use send or xfer (gas)
        require(sent, "Failed to send Ether");
    }



    function _mintCards(uint number_of_tokens, address user) internal {
        uint256 newCounter = counter + number_of_tokens;
        require(newCounter < 13801,"Not enough tokens left to mint");
        uint256[] memory tokenIDArray = new uint256[](number_of_tokens);
        bytes32 srn = blockhash(block.number);
        //console.log(number_of_tokens," being minted ",tokenIDArray.length);
        for (uint pos = 0; pos < number_of_tokens; pos++) {
            
            tokenIDArray[pos] = randomTokenURI(1,uint256(srn)) + base;
            //console.log(tokenIDArray[pos]);
            srn = keccak256(abi.encodePacked(srn,pos,msg.sender));
        }
        token.mintBatchToOneR(user, tokenIDArray);

        counter += number_of_tokens;

    }

    function setAdmin(address _addr, bool _state) external  onlyAdmin {
        admins[_addr] = _state;
        emit SetAdmin(_addr,_state);
    }


}

pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


interface token_two_interface {

    function setAllowed(address _addr, bool _state) external;

    function permitted(address) external view returns (bool);

    function mintBatchToOne(address recipient, uint256[] memory tokenIds) external;

    function mintBatchToOneR(address recipient, uint256[] memory tokenIds) external;

    function mintBatchToMany(address[] memory recipients , uint256[] memory tokenIds ) external;

    function mintReplacement(address user, uint256 tokenId) external;

}

pragma solidity ^0.8.7;
// SPDX-Licence-Identifier: RIGHT-CLICK-SAVE-ONLY


import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract recovery is Ownable {

    address recover;
    constructor(address _recovery) {
        recover = _recovery;
    }
    
    // blackhole prevention methods
    function retrieveETH() external  {
            uint256 _balance = address(this).balance;
            (bool sent, ) = recover.call{value: _balance}(""); // don't use send or xfer (gas)
            require(sent, "Failed to send Ether");
    }
    
    function retrieveERC20(address _tracker) external  {
        uint256 balance = IERC20(_tracker).balanceOf(address(this));
        IERC20(_tracker).transfer(recover, balance);
    }

    function retrieve721(address _tracker, uint256 id) external onlyOwner {
        IERC721(_tracker).transferFrom(address(this), msg.sender, id);
    }



}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "hardhat/console.sol";


contract randomiser {

    struct random_tool {
        bool        substituted;
        uint128     value;
    }

    mapping(uint => uint)                          num_tokens_left;
    mapping(uint => mapping (uint => random_tool)) random_eyes;
    uint256                             immutable  startsWithZero;

    constructor(uint256 oneIfStartsWithZero) {
        startsWithZero = oneIfStartsWithZero;
    }

    function getTID(uint256 projectID, uint256 pos) internal view returns (uint128){
        random_tool memory data = random_eyes[projectID][pos];
        if (!data.substituted) return uint128(pos);
        return data.value;
    }

    function randomTokenURI(uint256 projectID, uint256 rand) internal returns (uint256) {
        uint256 ntl = num_tokens_left[projectID];
        require(ntl > 0,"All tokens taken");
        uint256 nt = (rand % ntl--);
        random_tool memory data = random_eyes[projectID][nt];

        uint128 endval = getTID(projectID,ntl);
        random_eyes[projectID][nt] = random_tool( true,endval);
        num_tokens_left[projectID] = ntl;

        if (data.substituted) return data.value+startsWithZero;
        return nt+startsWithZero;
    }

    function setNumTokensLeft(uint256 projectID, uint256 num) internal {
        num_tokens_left[projectID] = num;
    }

    function numLeft(uint projectID) external view returns (uint) {
        return num_tokens_left[projectID];
    }

}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
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