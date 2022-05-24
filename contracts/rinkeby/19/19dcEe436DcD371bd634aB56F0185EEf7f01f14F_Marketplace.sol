// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract Marketplace is ReentrancyGuard {
    // Variables
    address payable public immutable carteraStrambolics; // the account that receives fees
    uint256 public immutable tarifa; // the fee percentage on sales
    uint256 public totalNft;

    //Structs
    struct Producto {
        uint256 idProducto;
        IERC721 coleccion;
        uint256 idNft;
        uint256 precio;
        address payable vendedor;
        bool vendido;
    }

    //Events
    event Comprado(
        uint256 idProducto,
        address indexed coleccion,
        uint256 idNft,
        uint256 precio,
        address indexed vendedor,
        address indexed comprador
    );

    event EnVenta(
        uint256 idProducto,
        address indexed coleccion,
        uint256 idNft,
        uint256 precio,
        address indexed vendedor
    );

    // idProducto -> Producto
    mapping(uint256 => Producto) public productos;

    //initiate constructor

    // _tarifa  es necesario pasarsela en el constructor  -------> es el porcentaje que cobra el contrato cuando se venden en él

    constructor(uint256 _tarifa) {
        carteraStrambolics = payable(msg.sender);
        tarifa = _tarifa;
    }

    //Obtains the total price of an Nft. It includes the listed price + the market comission
    function listarPrecio(uint256 _idProducto) public view returns (uint256) {
        return ((productos[_idProducto].precio * (100 + tarifa)) / 100);
    }

    // Make item to offer on the marketplace
    function venderNFT(
        IERC721 _coleccion,
        uint256 _idNft,
        uint256 _precio
    ) external nonReentrant {
        require(
            msg.sender == _coleccion.ownerOf(_idNft),
            "Only the NFT owner can sell it"
        );
        require(_precio > 0, "The price has to be bigger than 0");
        // increment totalNft
        totalNft++;
        // transfer NFT
        _coleccion.transferFrom(msg.sender, address(this), _idNft);
        // add new item to productos mapping
        productos[totalNft] = Producto(
            totalNft,
            _coleccion,
            _idNft,
            _precio,
            payable(msg.sender),
            false
        );
        // emit EnVenta event
        emit EnVenta(
            totalNft,
            address(_coleccion),
            _idNft,
            _precio,
            msg.sender
        );
    }

    // Allows the connected walet to acquiere a listed NFT
    function comprarNFT(uint256 _idProducto) external payable nonReentrant {
        uint256 _PrecioTotal = listarPrecio(_idProducto);
        Producto storage item = productos[_idProducto];
        require(
            _idProducto > 0 && _idProducto <= totalNft,
            "this NFT doesn't exist"
        );
        require(
            msg.value >= _PrecioTotal,
            "not enough funds to purchase this item"
        );
        require(!item.vendido, "this NFT has already been sold");
        // pay the price to seller
        item.vendedor.transfer(_PrecioTotal - item.precio);
        // pay the Market fee to carteraStrambolics
        carteraStrambolics.transfer(item.precio);

        // // pay the price to seller
        // item.vendedor.transfer(item.precio);
        // // pay the Market fee to carteraStrambolics
        // carteraStrambolics.transfer(_PrecioTotal - item.precio);

        // update item to sold
        item.vendido = true;
        // transfer nft to buyer
        item.coleccion.transferFrom(address(this), msg.sender, item.idNft);
        // emit Bought event
        emit Comprado(
            _idProducto,
            address(item.coleccion),
            item.idNft,
            item.precio,
            item.vendedor,
            msg.sender
        );
    }

    //Retirar fondos del contrato?
    // function retiraFondos() external onlyOwner nonReentrant {
    //     (bool success, ) = msg.sender.call{value: address(this).balance}("");
    //     require(success, "Transfer failed.");
    // }

    /* Funciones ne Falta

    // Actualiza el precio de un Nft 
    function actualizarPrecio()  {
   
    }

    // Retirar fondos del contrato?
    function actualizarPrecio()  {
   
    }

    // Permite revender un Nft que se haya comprado
    // No estoy segurop si la funcion venderNft es suficiente
    function reVenderNft() {
        
    }


    Notas:
    
    1. Este contrato esta basado en https://github.com/dappuniversity/nft_marketplace

    2. Esta publicado en Rinkebi https://rinkeby.etherscan.io/address/0xb502ac5be1c6c038039097a63cd3b0d89665a0c0#readContract

    3. Tal y como esta, esta pagando el prico del NFT al contrato, y el porcentage de la plataforma al dueno del NFT
    deriamos cambiar esto antes de re-publicar.

    4. Para poner un NFT en venta, se pone el precio el valor en Wei (0.1 eth = valor a poner en la consola 100000000000000)
    para comprar, se pone el valor en eth (100000000000000 wei = valor a poner en la consola 0.1eth).
    
    5. Para poder compra un Nft que se ha puesto en venta por 100000000000000, hace falata poner un valor de 0.101 para cubrir el precio total que incluye el ((precio del NFT) + (1% de la comicion de la plataforma))
    */
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.0 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.0 (security/ReentrancyGuard.sol)

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
// OpenZeppelin Contracts v4.4.0 (utils/introspection/IERC165.sol)

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