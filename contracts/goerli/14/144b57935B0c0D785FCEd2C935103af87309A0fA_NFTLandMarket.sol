// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./lib/SignatureVerification.sol";
import "./lib/Pauseable.sol";
import "./lib/TransferHelper.sol";
import "./interface/INFTLandCollection.sol";

struct SaleParameters {
    uint256 tokenId;
    address tokenAddress;
    address offerer;
    uint256 amount;
    uint256 price;
    uint256 startTime; // 毫秒时间戳
    address creator; // 如果是外部NFT则为address(0)
    uint256 totalSupply; // 如果是外部NFT则为0
    uint8 tokenType;
    bool minted;
}

struct EIP712Domain {
    string name;
    string version;
    uint256 chainId;
    address verifyingContract;
    bytes32 salt;
}

enum SaleState {
    Created,
    Executed,
    Canceled
}

contract NFTLandMarket is SignatureVerification, Ownable, ReentrancyGuard, Pauseable {
    bytes32 constant salt = 0xcab6554389422575ff776cbe4c196fff08454285c466423b2f91b6ebfa166ca5;
    uint256 private constant CHAINID = 5;
    bytes32 private constant SALE_PARAMETERS_TYPEHASH =
        keccak256(
            "SaleParameters(uint256 tokenId,address tokenAddress,address offerer,uint256 amount,uint256 price,uint256 startTime,address creator,uint256 totalSupply,uint8 tokenType,bool minted)"
        );
    bytes32 private constant EIP712_DOMAIN_TYPEHASH =
        keccak256(
            "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"
        );
    bytes32 private immutable DOMAIN_SEPARATOR;
    uint8 private constant TOKEN_TYPE_ERC721 = 1;
    uint8 private constant TOKEN_TYPE_ERC1155 = 2;

    address private nftlandCollection;
    mapping(bytes => SaleState) private saleStateMap;

    event SaleExecuted(bytes signature, address offerer, address buyer);

    event SaleCanceled(bytes signature);

    constructor() {
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                EIP712_DOMAIN_TYPEHASH,
                keccak256("nftland"),
                keccak256("1.0"),
                CHAINID,
                address(this),
                salt
            )
        );
    }

    modifier notResolvedSaleOrder(bytes memory _signature) {
        require(
            saleStateMap[_signature] < SaleState.Executed,
            "saleorder already executed or canceled"
        );
        _;
    }

    function cancelSale(SaleParameters memory _sale, bytes memory _signature)
        external
        notPaused
        notResolvedSaleOrder(_signature)
    {
        bool verifyOk = _verify(msg.sender, getSaleTypedDataHash(_sale), _signature);
        require(verifyOk, "sale signature incorrect");

        saleStateMap[_signature] = SaleState.Canceled;
        emit SaleCanceled(_signature);
    }

    function executeSaleOrder(SaleParameters memory _sale, bytes memory _signature)
        external
        payable
        notPaused
        nonReentrant
        notResolvedSaleOrder(_signature)
    {
        bool verifyOk = _verify(_sale.offerer, getSaleTypedDataHash(_sale), _signature);
        require(verifyOk, "sale signature incorrect");
        require(msg.value == _sale.price * _sale.amount, "please pay the correct price");
        saleStateMap[_signature] = SaleState.Executed;

        address offerer = _sale.offerer;
        address tokenAddress = _sale.tokenAddress;
        uint tokenId = _sale.tokenId;
        uint amount = _sale.amount;
        uint totalSupply = _sale.totalSupply;
        // 1. 如果地址是内部NFT,mint代币
        if (tokenAddress == nftlandCollection) {
            bool exist = INFTLandCollection(tokenAddress).exist(tokenId);
            if (!exist) {
                INFTLandCollection(tokenAddress).mint(offerer, tokenId, totalSupply);
            }
        }

        // 2. 进行转账
        // 如何区分ERC721和ERC1155
        // ERC721
        // function transferFrom(address from, address to, uint256 tokenId) external;
        // function safeTransferFrom(address from, address to, uint256 tokenId) external;
        // function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
        // ERC1155
        // function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;
        bool success;
        if (_sale.tokenType == TOKEN_TYPE_ERC1155) {
           success = TransferHelper.erc1155SafeTransferfrom(
                tokenAddress,
                offerer,
                msg.sender,
                tokenId,
                amount
            );
        } else {
            success = TransferHelper.erc721SafeTransferFrom(tokenAddress, offerer, msg.sender, tokenId);
        }

        // 3. 记录sale状态, 触发事件
        saleStateMap[_signature] = SaleState.Executed;
        emit SaleExecuted(_signature, offerer, msg.sender);
    }

    function getSaleTypedDataHash(SaleParameters memory _sale) private view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, getSaleStructHash(_sale)));
    }

    function getSaleStructHash(SaleParameters memory _sale) private pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    SALE_PARAMETERS_TYPEHASH,
                    _sale.tokenId,
                    _sale.tokenAddress,
                    _sale.offerer,
                    _sale.amount,
                    _sale.price,
                    _sale.startTime,
                    _sale.creator,
                    _sale.totalSupply,
                    _sale.tokenType,
                    _sale.minted
                )
            );
    }

    function getSaleState(bytes memory _signature) public view returns (SaleState) {
        return saleStateMap[_signature];
    }

    function setNFTLandCollection(address _addr) external onlyOwner {
        nftlandCollection = _addr;
    }

    function withdraw(address _to) external onlyOwner nonReentrant {
        require(_to != address(0), "withdraw to zero address is not allowed");
        payable(_to).transfer(address(this).balance);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

contract SignatureVerification {
    function _verify(
        address _signer,
        bytes32 _hashedMessage,
        bytes memory _signature
    ) internal pure returns (bool) {
        (bytes32 r, bytes32 s, uint8 v) = _splitSignature(_signature);
        address signerDerived = ecrecover(_hashedMessage, v, r, s);
        return signerDerived == _signer;
    }

    function _splitSignature(bytes memory _signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_signature.length == 65, "invalid signature length");

        assembly {
            /*
            First 32 bytes stores the length of the signature

            add(sig, 32) = pointer of sig + 32
            effectively, skips first 32 bytes of signature

            mload(p) loads next 32 bytes starting at the memory address p into memory
            */

            // first 32 bytes, after the length prefix
            r := mload(add(_signature, 32))
            // second 32 bytes
            s := mload(add(_signature, 64))
            // final byte (first byte of the next 32 bytes)
            v := byte(0, mload(add(_signature, 96)))
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract Pauseable {
    uint private constant NOT_PAUSED = 1;
    uint private constant PAUSED = 2;
    
    uint private status;

    constructor() {
        status = NOT_PAUSED;
    }

    modifier notPaused() {
        require(status != PAUSED, "paused");
        _;
    }

    function pause() public {
        status = NOT_PAUSED;
    }

    function resume() public {
        status = PAUSED;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

library TransferHelper {
    function erc721SafeTransferFrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId
    ) internal returns (bool success){
        (success,) = _token.call(
            // bytess4(keccak256(bytes('safeTransferFrom(address,address,uint256)')))
            abi.encodeWithSelector(0x42842e0e, _from, _to, _tokenId)
        );
    }

    function erc1155SafeTransferfrom(
        address _token,
        address _from,
        address _to,
        uint256 _tokenId,
        uint256 _amount
    ) internal returns (bool success) {
        (success,) = _token.call(
            // bytess4(keccak256(bytes('safeTransferFrom(address,address,uint256,uint256,bytes)')))
            abi.encodeWithSelector(0xf242432a, _from, _to, _tokenId, _amount, "")
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface INFTLandCollection {
    function mint(address _account, uint _id, uint _amount) external;
    function exist(uint _id) view external returns (bool);
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