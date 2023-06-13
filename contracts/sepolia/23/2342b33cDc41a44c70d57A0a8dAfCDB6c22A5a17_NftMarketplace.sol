// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol"; // Import necessario per poter richiamare alcune funzioni che manipolano gli NFT, tra cui la funzione di approvazione per lavorare con un NFT e la funzione per trasferire un NFT
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; //Import necessario per il modifier nonReentrant
import "@chainlink/contracts/src/v0.8/AutomationCompatible.sol";

error NftMarketplace__NotApprovedForMarketplace();
error NftMarketplace__AlreadyListed(address nftAddress, uint256 tokenId);
error NftMarketplace__NotOwner();
error NftMarketplace__NotListed(address nftAddress, uint256 tokenId);
error NftMarketplace__TransferFailed();
error NftMarketplace__StillTimeToRecess();
error NftMarketplace__NotInStaking(address nftAddress, uint256 tokenId);
error NftMarketplace__NotAllowed();

// Contratto che gestisce la compravendita di NFT. Ereditiamo da ReentrancyGuard per alcune funzionalità di sicurezza e dall'interfaccia AutomationCompatible per introdurre dell'automazione nelle funzioni
contract NftMarketplace is ReentrancyGuard, AutomationCompatibleInterface {
    // Struttura dati per gestire lo staking di un NFT appena effettuato l'acquisto del corrispondente prodotto.
    // Nel lasso di tempo in cui è possibile riportare indietro un prodotto il marketplace detiene in staking l'NFT prima di trasferirlo ufficialmente.
    // Bisogna quindi tenere traccia dell'NFT in staking, del tempo rimanente, del venditore e dell'acquirente
    struct Transaction {
        address seller;
        address buyer;
        uint startTimestamp; // Timestamp del momento dell'acquisto
    }

    // Evento che sarà emesso dopo il listing di un NFT
    event ItemListed(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    // Evento emesso a seguito del completamento della funzione di acquisto
    event ItemBought(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event ItemCancelled(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    event TokenGetBack(
        address indexed nftAddress,
        uint256 indexed tokenId,
        address owner
    );

    event Token_Transfered(
        address from,
        address to,
        address indexed nftAddress,
        uint256 indexed tokenId
    );

    // Utilizziamo una struttura dati che effettua il seguente mapping per un NFT messo in lista di vendita:
    // Contract NFT address -> NFT Token Id -> Seller address
    mapping(address => mapping(uint256 => address)) private s_listings;

    // Mapping per un NFT che si trova nello staking
    mapping(address => mapping(uint256 => Transaction)) private s_stakings;

    //Tempo limite entro il quale poter restituire il prodotto (e dunque l'NFT)
    uint s_returnTime;

    // Modifiers

    // Modifier per assicurarci che non venga (ri)messo in vendita un NFT già listato in precedenza
    modifier checkListed(address nftAddress, uint256 tokenId) {
        address seller = s_listings[nftAddress][tokenId];
        address defaultAddress; // 0x0000000000000000000000000000000000000000
        if (seller != defaultAddress) {
            // Se il venditore è diverso dall'account "vuoto" allora revert perché l'NFT è già stato messo in vendita
            revert NftMarketplace__AlreadyListed(nftAddress, tokenId);
        }
        _;
    }

    // Modifier per fare in modo un NFT possa essere messo in vendita esclusivamente dal legittimo proprietario
    modifier onlyNftOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId); // La funzione ownerOf di IERC721 restituisce l'indirizzo del proprietario dell?NFT con l'id passato come parametro
        if (owner != spender) {
            //Se l'indirizzo del proprietario non corrisponde con l'indirizzo di chi sta tentando di mettere in vendita l'NFT facciamo il revert
            revert NftMarketplace__NotOwner();
        }
        _;
    }

    // Modifier per verificare che un NFT è in lista di vendita. Verrà utilizzato nella funzione di acquisto
    modifier isListed(address nftAddress, uint256 tokenId) {
        address seller = s_listings[nftAddress][tokenId]; // preleviamo l'indirizzo del venditore dal listing
        address defaultAddress;
        if (seller == defaultAddress) {
            // Se l'indirizzo del venditore è un indirizzo nullo allora revert: l'NFT non è in vendita
            revert NftMarketplace__NotListed(nftAddress, tokenId);
        }
        _;
    }

    // Modifier per controllare che il trasferimento dell'NFT possa avvenire, decorso il tempo di recesso. E' una sorta di trigger
    modifier stakeCheck(address nftAddress, uint256 tokenId) {
        uint start = s_stakings[nftAddress][tokenId].startTimestamp;
        if (block.timestamp < (start + s_returnTime)) {
            revert NftMarketplace__StillTimeToRecess();
        }
        _;
    }

    // Modifier che permette la restituzione dell'NFT solo se esso è in staking (cioè siamo ancora nel periodo di recesso)
    modifier inStaking(address nftAddress, uint256 tokenId) {
        uint startTimestamp = s_stakings[nftAddress][tokenId].startTimestamp;
        if (startTimestamp == 0) {
            revert NftMarketplace__NotInStaking(nftAddress, tokenId);
        }
        _;
    }

    // Modifier affinché la restituzione dell'NFT sia richiamabile solamente da colui che risulta il buyer nella struttura dati Transaction
    modifier onlyBuyer(address nftAddress, uint256 tokenId) {
        address buyer = s_stakings[nftAddress][tokenId].buyer;
        if (msg.sender != buyer) {
            revert NftMarketplace__NotAllowed();
        }
        _;
    }

    // Constructor
    constructor(uint returnTime) {
        s_returnTime = returnTime;
    }

    /////////////////////
    // Main Functions //
    ////////////////////

    // La funzione per pubblicare un annuncio di vendita la definiamo come external perché vogliamo che possa essere richiamata anche da progetti esterni o account esterni
    // Dobbiamo assicurarci inoltre che l'NFT in questione non sia già stato messo in vendita precedentemente e che chi richiama la funzione sia effettivamente il proprietario dell'NFT. Queste due verifiche le facciamo tramite due modifiers
    function listItem(
        address nftAddress,
        uint256 tokenId
    )
        external
        checkListed(nftAddress, tokenId)
        onlyNftOwner(nftAddress, tokenId, msg.sender)
    {
        // I proprietari di NFT, quando pubblicano un "annuncio di vendita", mantengono comunque la proprietà dei propri NFT ma danno l'approvazione al marketplace di trasferire l'NFT per loro conto.

        // Ci dobbiamo assicurare che il contratto marketplace ottenga l'approvazione per lavorare con l'NFT.
        // A tal proposito possiamo richiamare la funzione getApproved() dell'interfaccia IERC721 che abbiamo importato
        IERC721 nft = IERC721(nftAddress); // Creiamo un oggetto di tipo IERC721 passando all'interfaccia l'indirizzo del contratto relativo all'NFT da manipolare
        if (nft.getApproved(tokenId) != address(this)) {
            //Alla getApproved passiamo l'id del token. Se l'account approvato per manipolare il token con quell'id risulta diverso dall'account relativo al marketplace allora facciamo il revert
            revert NftMarketplace__NotApprovedForMarketplace();
        }

        s_listings[nftAddress][tokenId] = msg.sender; // Update del mapping con le informazioni sul venitore, cioè colui che richiama la funzione listItem
        emit ItemListed(msg.sender, nftAddress, tokenId); // Emissione dell'evento relativo al listing avvenuto
    }

    //Funzione di acquisto che innesca lo staking dell'NFT per il lasso di tempo di possibile rimborso
    //External perchè solamente persone o altri smart contract al di fuori di questo andranno a richiamare la funzione buyItem.
    //N.B pagamento non gestito tramite criptomoneta
    function buyItem(
        address nftAddress,
        uint256 tokenId
    ) external isListed(nftAddress, tokenId) nonReentrant {
        // Recupero del venditore
        address nftSeller = s_listings[nftAddress][tokenId];

        // Si popola la struttura dati Transaction che interessa l'NFT
        s_stakings[nftAddress][tokenId].seller = nftSeller;
        s_stakings[nftAddress][tokenId].buyer = msg.sender;
        s_stakings[nftAddress][tokenId].startTimestamp = block.timestamp;

        // A questo punto dobbiamo eliminare l'annuncio di vendita dal mapping s_listings
        delete (s_listings[nftAddress][tokenId]); // La funzione delete permette di eliminare un entry da un mapping

        emit ItemBought(msg.sender, nftAddress, tokenId);
    }

    function transferTokenAfterTime(
        address nftAddress,
        uint256 tokenId
    ) external stakeCheck(nftAddress, tokenId) inStaking(nftAddress, tokenId) {
        // Terminato il tempo per la restituzione (senza precedente recesso): avviene il passaggio ufficiale di proprietà
        // Trasferimento del token dal venditore all'acquirente (recuperati dalla struttura dati Transaction)
        address from = s_stakings[nftAddress][tokenId].seller;
        address to = s_stakings[nftAddress][tokenId].buyer;

        // Reset dell'entry legata all'NFT in questione all'interno del mapping
        delete (s_stakings[nftAddress][tokenId]);

        // Per il trasferiento utilizziamo la funzione safeTransferFrom di IERC721 a cui dobbiamo passare: from, to e tokenId
        IERC721(nftAddress).safeTransferFrom(from, to, tokenId);
        emit Token_Transfered(from, to, nftAddress, tokenId);
    }

    function takeBackToken(
        address nftAddress,
        uint256 tokenId
    ) external inStaking(nftAddress, tokenId) onlyBuyer(nftAddress, tokenId) {
        address owner = s_stakings[nftAddress][tokenId].seller;
        delete (s_stakings[nftAddress][tokenId]);
        emit TokenGetBack(nftAddress, tokenId, owner);
    }

    // Le due seguenti funzioni servono per redere compatibile lo smart contract con l'interfaccia AutomationCompatible
    // La checkUpkeep riceve come parametro di input dei bytes: gli passeremo l'indirizzo dell'NFT e il token id codificati
    function checkUpkeep(
        bytes calldata address_id_encoded
    )
        external
        view
        override
        returns (bool upkeepNeeded, bytes memory performData)
    {
        (address nftAddress, uint256 tokenId) = multiDecodeNFTData(
            address_id_encoded
        );
        uint256 startTimestamp = s_stakings[nftAddress][tokenId].startTimestamp;

        upkeepNeeded = block.timestamp > (startTimestamp + s_returnTime);
        performData = address_id_encoded;
    }

    function performUpkeep(bytes calldata performData) external override {
        //We highly recommend revalidating the upkeep in the performUpkeep function
        (address nftAddress, uint256 tokenId) = multiDecodeNFTData(performData);
        uint256 startTimestamp = s_stakings[nftAddress][tokenId].startTimestamp;
        if (block.timestamp > (startTimestamp + s_returnTime)) {
            address seller = s_stakings[nftAddress][tokenId].seller;
            address buyer = s_stakings[nftAddress][tokenId].buyer;

            // Trasferimento del token dal venditore all'acquirente (cioè a chi sta richiamando la funzione corrente)
            // Per fare ciò utilizziamo la funzione safeTransferFrom di IERC721 a cui dobbiamo passare: from, to e tokenId
            IERC721(nftAddress).safeTransferFrom(seller, buyer, tokenId);
        }
    }

    // Funzione per rimuovere un NFT dal marketplace.
    // Utilizziamo il modifer per assicurarci che solo il proprietario dell'NFT possa richiamare tale funzione
    // Utilizziamo il modifier per assicurarci che l?NFT da rimuovere sia stato precedentemente messo in vendita
    function cancelListing(
        address nftAddress,
        uint256 tokenId
    )
        external
        onlyNftOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        delete (s_listings[nftAddress][tokenId]);
        emit ItemCancelled(msg.sender, nftAddress, tokenId);
    }

    // Funzioni ausiliarie
    function multiEncodeNFTData(
        address nftAddress,
        uint256 tokenId
    ) public pure returns (bytes memory) {
        bytes memory someString = abi.encode(nftAddress, tokenId);
        return someString;
    }

    function multiDecodeNFTData(
        bytes memory encoded
    ) public pure returns (address, uint256) {
        (address nftAddress, uint256 tokenId) = abi.decode(
            encoded,
            (address, uint256)
        );
        return (nftAddress, tokenId);
    }

    /*  // Aggiornamento informazioni del Listing (prezzo di vendita)
    function updateListing(
        address nftAddress,
        uint256 tokenId,
        uint256 newPrice
    )
        external
        onlyNftOwner(nftAddress, tokenId, msg.sender)
        isListed(nftAddress, tokenId)
    {
        s_listings[nftAddress][tokenId].price = newPrice;
        emit ItemListed(msg.sender, nftAddress, tokenId, newPrice); // Update = nuovo Listing
    } */

    /* // Funzione tramite cui ogni venditore può ritirare quanto accumulato dalle vendite portate a termine
    function withdrawProceeds() external {
        uint256 proceeds = s_proceeds[msg.sender]; // Ricaviamo la somma disponibile per il prelievo (quanto ottenuto fino a questo momento dalle vendite)
        if (proceeds <= 0) {
            revert NftMarketplace__NoProceeds();
        }
        // Se la somma disponibile al ritiro è maggiore di 0 allora aggiornamento della struttura dati e invio dei soldi a chi ha richiamato la funzione
        s_proceeds[msg.sender] = 0;

        (bool success, ) = payable(msg.sender).call{value: proceeds}("");
        if (!success) {
            revert NftMarketplace__TransferFailed();
        }
    }
 */
    // Getters

    function getSeller(
        address nftAddress,
        uint256 tokenId
    ) public view returns (address) {
        return s_listings[nftAddress][tokenId];
    }

    function getTransaction(
        address nftAddress,
        uint256 tokenId
    ) public view returns (address, address) {
        address nftSeller = s_stakings[nftAddress][tokenId].seller;
        address nftBuyer = s_stakings[nftAddress][tokenId].buyer;
        return (nftSeller, nftBuyer);
    }

    function getReturnTime() public view returns (uint) {
        return s_returnTime;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract AutomationBase {
  error OnlySimulatedBackend();

  /**
   * @notice method that allows it to be simulated via eth_call by checking that
   * the sender is the zero address.
   */
  function preventExecution() internal view {
    if (tx.origin != address(0)) {
      revert OnlySimulatedBackend();
    }
  }

  /**
   * @notice modifier that allows it to be simulated via eth_call by checking
   * that the sender is the zero address.
   */
  modifier cannotExecute() {
    preventExecution();
    _;
  }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./AutomationBase.sol";
import "./interfaces/AutomationCompatibleInterface.sol";

abstract contract AutomationCompatible is AutomationBase, AutomationCompatibleInterface {}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface AutomationCompatibleInterface {
  /**
   * @notice method that is simulated by the keepers to see if any work actually
   * needs to be performed. This method does does not actually need to be
   * executable, and since it is only ever simulated it can consume lots of gas.
   * @dev To ensure that it is never called, you may want to add the
   * cannotExecute modifier from KeeperBase to your implementation of this
   * method.
   * @param checkData specified in the upkeep registration so it is always the
   * same for a registered upkeep. This can easily be broken down into specific
   * arguments using `abi.decode`, so multiple upkeeps can be registered on the
   * same contract and easily differentiated by the contract.
   * @return upkeepNeeded boolean to indicate whether the keeper should call
   * performUpkeep or not.
   * @return performData bytes that the keeper should call performUpkeep with, if
   * upkeep is needed. If you would like to encode data to decode later, try
   * `abi.encode`.
   */
  function checkUpkeep(bytes calldata checkData) external returns (bool upkeepNeeded, bytes memory performData);

  /**
   * @notice method that is actually executed by the keepers, via the registry.
   * The data returned by the checkUpkeep simulation will be passed into
   * this method to actually be executed.
   * @dev The input to this method should not be trusted, and the caller of the
   * method should not even be restricted to any single registry. Anyone should
   * be able call it, and the input should be validated, there is no guarantee
   * that the data passed in is the performData returned from checkUpkeep. This
   * could happen due to malicious keepers, racing keepers, or simply a state
   * change while the performUpkeep transaction is waiting for confirmation.
   * Always validate the data passed in.
   * @param performData is the data which was passed back from the checkData
   * simulation. If it is encoded, it can easily be decoded into other types by
   * calling `abi.decode`. This data should not be trusted, and should be
   * validated against the contract's current state.
   */
  function performUpkeep(bytes calldata performData) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (security/ReentrancyGuard.sol)

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

    /**
     * @dev Returns true if the reentrancy guard is currently set to "entered", which indicates there is a
     * `nonReentrant` function in the call stack.
     */
    function _reentrancyGuardEntered() internal view returns (bool) {
        return _status == _ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.9.0) (token/ERC721/IERC721.sol)

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function setApprovalForAll(address operator, bool approved) external;

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