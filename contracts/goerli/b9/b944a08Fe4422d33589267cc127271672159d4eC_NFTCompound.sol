pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "./lib/IERC721Burnable.sol";
import "./interface/IERC721Mint.sol";

contract NFTCompound is Ownable, Pausable{

    //签名管理员配置
    mapping(address => bool) public signAddressConfig;
    //所有合成项列表
    CompoundItem[] public compoundItemList;
    //CopyERC721合约地址
    address public copyERC721;

    //合成项信息
    struct CompoundItem {
        uint256 index;  //当前索引
        address tokenA;
        address tokenB;
        address tokenNew;

        bool open; //是否开放合成

        uint256[] tokenABurn;   //tokenA销毁记录
        uint256[] tokenBBurn;   //tokenB销毁记录
        uint256[] tokenNewMint; //tokenNew铸造记录
    }

    //合成事件
    event Compound(address indexed account_, uint256 indexed itemIndex_, uint256 indexed tokenAId_, uint256 tokenBId_, uint256 tokenNewId_);
    //添加合成配置事件
    event AddCompound(uint256 indexed itemIndex_, address indexed tokenA_, address indexed tokenB_, address tokenNew_, bool open_);
    //修改合成配置事件
    event UpdateCompound(uint256 indexed itemIndex_, bool open_);

    //合成事件
    event Compound(address indexed tokenAAddress_, address indexed tokenBAddress_, uint256 indexed tokenAId_, uint256 tokenBId_);
    //销毁铸造合成事件
    event Compound(address indexed tokenAAddress_, address indexed tokenBAddress_, address indexed newTokenAddress_, uint256 tokenAId_, uint256 tokenBId_, string tokenURI);

    modifier itemOpenCheck(uint256 itemIndex_){
        //索引是否超出范围
        require(itemIndex_ < compoundItemList.length, "itemIndex error");
        require(compoundItemList[itemIndex_].open, "Compound item close");
        _;
    }

    constructor(address signAddress_){
        signAddressConfig[signAddress_] = true;
    }

     /*
     * @notice 用户发起合成
     * @param itemIndex_    合成项索引
     * @param tokenAId_ 合成前tokenA的ID
     * @param tokenBId_ 合成前tokenB的ID
     */
    function compound(uint256 itemIndex_, uint256 tokenAId_, uint256 tokenBId_, uint256 newTokenId_, string calldata newTokenURI_, uint8 v, bytes32 r, bytes32 s) public whenNotPaused itemOpenCheck(itemIndex_){
        address sender = msg.sender;
        address signAddress = ecrecover(keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, itemIndex_, tokenAId_, tokenBId_, newTokenId_, newTokenURI_)))), v, r, s);
            
        require(signAddressConfig[signAddress], "only sign admin");
        CompoundItem storage _compoundItem = compoundItemList[itemIndex_];
        //销毁tokenA
        IERC721Burnable(_compoundItem.tokenA).burn(tokenAId_);
        //销毁tokenB
        IERC721Burnable(_compoundItem.tokenB).burn(tokenBId_);
        //铸造新的token
        IERC721Mint(_compoundItem.tokenNew).mint(sender, newTokenId_, newTokenURI_);
        //记录tokenA销毁
        _compoundItem.tokenABurn.push(tokenAId_);
        //记录tokenB销毁
        _compoundItem.tokenBBurn.push(tokenBId_);
        ////记录tokenNew铸造
        _compoundItem.tokenNewMint.push(newTokenId_);
        emit Compound(sender, itemIndex_, tokenAId_, tokenBId_, newTokenId_);
        
    }

    /*
     * @notice 用户发起合成
     * @dev 链上销毁，链下铸造的形式
     * @param tokenAAddress_    合成前的tokenA地址
     * @param tokenBAddress_    合成前的tokenB地址
     * @param tokenAId_ 合成前tokenA的ID
     * @param tokenBId_ 合成前tokenB的ID
     */
    function compound(address tokenAAddress_, address tokenBAddress_, uint256 tokenAId_, uint256 tokenBId_, uint8 v, bytes32 r, bytes32 s) public whenNotPaused {
        address sender = msg.sender;
        address signAddress = ecrecover(keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encodePacked(sender, tokenAAddress_, tokenBAddress_, tokenAId_, tokenBId_)))), v, r, s);
            
        require(signAddressConfig[signAddress], "only sign admin");
        //销毁tokenA
        IERC721Burnable(tokenAAddress_).burn(tokenAId_);
        //销毁tokenB
        IERC721Burnable(tokenBAddress_).burn(tokenBId_);
        emit Compound(tokenAAddress_, tokenBAddress_, tokenAId_, tokenBId_);
        
    }

    /*
     * @notice 用户发起合成
     * @dev 销毁后铸造新的NFT
     * @param tokenAAddress_    合成前的tokenA地址
     * @param tokenBAddress_    合成前的tokenB地址
     * @param tokenAId_ 合成前tokenA的ID
     * @param tokenBId_ 合成前tokenB的ID
     */
    function compoundV3(address tokenAAddress_, address tokenBAddress_, address newTokenAddress_, uint256 tokenAId_, uint256 tokenBId_, string memory tokenURI, uint8 v, bytes32 r, bytes32 s) public whenNotPaused {
        address sender = msg.sender;
        address signAddress = ecrecover(keccak256(abi.encode(
            "\x19Ethereum Signed Message:\n32",
            keccak256(abi.encode(sender, tokenAAddress_, tokenBAddress_, newTokenAddress_, tokenAId_, tokenBId_, tokenURI)))), v, r, s);
            
        require(signAddressConfig[signAddress], "only sign admin");
        //销毁tokenA
        IERC721Burnable(tokenAAddress_).burn(tokenAId_);
        //销毁tokenB
        IERC721Burnable(tokenBAddress_).burn(tokenBId_);
        //铸造新的token
        IERC721Mint(copyERC721).safeMint(newTokenAddress_, sender, tokenURI);
        emit Compound(tokenAAddress_, tokenBAddress_, newTokenAddress_, tokenAId_, tokenBId_, tokenURI);
        
    }

    /*
     * @notice 获取所有合成项配置
     */
    function compoundItemListAll() view public returns(CompoundItem[] memory){
        return compoundItemList;
    }

    /*
     * @notice 获取配置的合成项数量
     */
    function compoundItemCount() view public returns(uint256) {
        return compoundItemList.length;
    }

    /*
     * @notice 添加合成项配置
     * @param tokenA_
     * @param tokenB_
     * @param tokenNew_
     * @param open_
     *
     */
    function addCompound(address tokenA_, address tokenB_, address tokenNew_, bool open_) external {
        require(isContract(tokenA_), "tokenA not contract");
        require(isContract(tokenB_), "tokenB not contract");
        require(isContract(tokenNew_), "tokenNew not contract");
        //保存配置
        compoundItemList.push(
            CompoundItem({
                index: compoundItemList.length,
                tokenA: tokenA_,
                tokenB: tokenB_,
                tokenNew: tokenNew_,
                open: open_,
                tokenABurn: new uint256[](0),
                tokenBBurn: new uint256[](0),
                tokenNewMint: new uint256[](0)
            })
        );
        emit AddCompound(compoundItemList.length - 1, tokenA_, tokenB_, tokenNew_, open_);
    }

    /*
     * @notice 修改合成项配置
     * @dev 根据当前业务，仅支持修改open参数
     * @param itemIndex_
     * @param open_
     */
    function updateCompound(uint256 itemIndex_, bool open_) external onlyOwner {
        //索引是否超出范围
        require(itemIndex_ < compoundItemList.length, "itemIndex error");
        //是否没有改变
        require(compoundItemList[itemIndex_].open != open_, "no change");
        //修改
        compoundItemList[itemIndex_].open = open_;
        emit UpdateCompound(itemIndex_, open_);
    }

    
    /*
     * @notice 暂停
     */
    function pause() external whenNotPaused onlyOwner {
        _pause();
    }

    /*
     * @notice 开启(取消暂停)
     */
    function unpause() external whenPaused onlyOwner {
        _unpause();
    }

     /*
     * @notice 添加或取消签名管理员
     * @param addr_ 配置的地址
     * @param status_ 使用状态（true添加管理员-false移除管理员）
     */
    function changeSignAddressConfig(address addr_, bool status_) external onlyOwner {
        signAddressConfig[addr_] = status_;
    }

    
     /*
     * @notice 修改copyERC721合约地址
     */
    function changeCopyERC721(address copyERC721_) external onlyOwner {
        copyERC721 = copyERC721_;
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }
    
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Burnable is IERC721{

    function burn(uint256 tokenId) external;
}

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IERC721Mint is IERC721 {

    function mint(address, uint256, string calldata) external;

    function safeMint(address token, address to, string memory tokenURI) external;
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
// OpenZeppelin Contracts (last updated v4.7.0) (security/Pausable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which allows children to implement an emergency stop
 * mechanism that can be triggered by an authorized account.
 *
 * This module is used through inheritance. It will make available the
 * modifiers `whenNotPaused` and `whenPaused`, which can be applied to
 * the functions of your contract. Note that they will not be pausable by
 * simply including this module, only once the modifiers are put in place.
 */
abstract contract Pausable is Context {
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);

    bool private _paused;

    /**
     * @dev Initializes the contract in unpaused state.
     */
    constructor() {
        _paused = false;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        _requireNotPaused();
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is paused.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    modifier whenPaused() {
        _requirePaused();
        _;
    }

    /**
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Throws if the contract is paused.
     */
    function _requireNotPaused() internal view virtual {
        require(!paused(), "Pausable: paused");
    }

    /**
     * @dev Throws if the contract is not paused.
     */
    function _requirePaused() internal view virtual {
        require(paused(), "Pausable: not paused");
    }

    /**
     * @dev Triggers stopped state.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function _pause() internal virtual whenNotPaused {
        _paused = true;
        emit Paused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The contract must be paused.
     */
    function _unpause() internal virtual whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }
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