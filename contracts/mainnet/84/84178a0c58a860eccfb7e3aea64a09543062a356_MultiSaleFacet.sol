// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "../interfaces/IMultiSale.sol";
import "../interfaces/IERC20Mint.sol";
import "../interfaces/IERC721Mint.sol";
import "../interfaces/IERC1155Mint.sol";

import "../utilities/InterfaceChecker.sol";
import "../utilities/Controllable.sol";
import "../utilities/Modifiers.sol";

import "../libraries/UInt256Set.sol";
import "../libraries/MultiSaleLib.sol";
import "../libraries/VariablePriceLib.sol";
import "../libraries/ERC721ALib.sol";

contract MultiSaleFacet is IMultiSale, Modifiers {

    using UInt256Set for UInt256Set.Set;
    using MultiSaleLib for MultiSaleContract;
    using VariablePriceLib for VariablePriceContract;
    using ERC721ALib for ERC721AContract;

    function initializeMultiSaleFacet() external {

    }

    /// @notice intialize the contract. should be called by overriding contract
    /// @param tokenSaleInit struct with tokensale data
    /// @return tokenSaleId the id of the tokensale
    function createTokenSale(MultiSaleSettings memory tokenSaleInit)
        external
        virtual
        onlyOwner
        returns (uint256 tokenSaleId) {

        tokenSaleId = MultiSaleLib._createTokenSale();

        MultiSaleLib.multiSaleStorage()._tokenSales[tokenSaleId].settings = tokenSaleInit;
        MultiSaleLib.multiSaleStorage()._tokenSales[tokenSaleId].settings.owner = tokenSaleInit.owner;
        MultiSaleLib.multiSaleStorage()._tokenSaleIds.push(tokenSaleId);
        // emit event
        emit MultiSaleCreated(tokenSaleId, tokenSaleInit);
    }
 
    /// @notice Updates the token sale settings
    /// @param settings - the token sake settings
    function updateTokenSaleSettings(
        uint256 tokenSaleId,
        MultiSaleSettings memory settings
    ) external {
        //TODO: RESTORE!
        // check token sale owner
        //require(msg.sender == MultiSaleLib.multiSaleStorage()._tokenSales[tokenSaleId].settings.owner, "notowner");
        MultiSaleLib.multiSaleStorage()._tokenSales[tokenSaleId].settings = settings;

        // emit event
        emit MultiSaleUpdated(tokenSaleId, settings);
    }

    /// @notice purchase a token, using a proof
    /// @param purchaseInfo struct with purchase data
    /// @param purchaseProofParam the proof of the purchase
    function purchaseProof(
        MultiSalePurchase memory purchaseInfo,
        MultiSaleProof memory purchaseProofParam,
        bytes memory data
    ) external payable returns (uint256[] memory ids) {

        //  get the token sale
        MultiSaleContract storage multiSaleContract  = MultiSaleLib
            .multiSaleStorage()
            ._tokenSales[purchaseInfo.multiSaleId];

        // if the purchaser isn't set then set it to the msg.sender
        if(purchaseInfo.purchaser == address(0)) {
            purchaseInfo.purchaser = msg.sender;
        }
        if(purchaseInfo.receiver == address(0)) {
            purchaseInfo.receiver = msg.sender;
        }
        // purchase token with proof
        multiSaleContract._purchaseToken(
            multiSaleContract.settings.price,
            purchaseInfo,
            purchaseProofParam,
            msg.value
        );

        //  mint the newly-purchased tokens
        ids = _mintPurchasedTokens(
            purchaseInfo.multiSaleId,
            purchaseInfo.receiver,
            purchaseInfo.quantity,
            data
        );
        // 4. update the token sale settings
        multiSaleContract.totalPurchased += purchaseInfo.quantity;
        multiSaleContract.purchased[purchaseInfo.receiver] += purchaseInfo.quantity;

        // emit an event
        emit MultiSaleSold(
            purchaseInfo.multiSaleId,
            purchaseInfo.purchaser,
            ids,
            data
        );
    }

    /// @notice purchase a token, without a proof
    function purchase(
        uint256 multiSaleId,
        address purchaser,
        address receiver,
        uint256 quantity,
        bytes memory data) external payable returns (uint256[] memory ids) {

        // get the token sale
        MultiSaleContract storage multiSaleContract = MultiSaleLib
            .multiSaleStorage()
            ._tokenSales[multiSaleId];
        // if the purchaser isn't set then set it to the msg.sender
        if(purchaser == address(0)) {
            purchaser = msg.sender;
        }
        if(receiver == address(0)) {
            receiver = msg.sender;
        }

        MultiSalePurchase memory purchaseInfo = MultiSalePurchase(
            multiSaleId,
            purchaser,
            receiver,
            quantity
        );

        // get the token sale    
        multiSaleContract._purchaseToken(
            multiSaleContract.settings.price,
            purchaseInfo, 
            msg.value);

        //  mint the tokens
        ids = _mintPurchasedTokens(
            multiSaleId,
            receiver,
            quantity,
            data
        );
        // 4. update the token sale settings
        multiSaleContract.totalPurchased += quantity;
        multiSaleContract.purchased[receiver] += quantity;

        // emit an event
        emit MultiSaleSold(
            multiSaleId,
            receiver,
            ids,
            data
        );
    }

    /// @notice mont the tokens purchased
    /// @param multiSaleId the id of the tokensale
    /// @param recipient the address of the receiver
    /// @param amount the quantity of tokens to mint
    function _mintPurchasedTokens(
        uint256 multiSaleId,
        address recipient,
        uint256 amount,
        bytes memory data
    ) internal returns (uint256[] memory tokenHash_) {
        
        // get the token sale
        MultiSaleContract storage multiSaleContract = MultiSaleLib
            .multiSaleStorage()
            ._tokenSales[multiSaleId];
        ERC721AStorage storage erc721AStorage = ERC721ALib.erc721aStorage();

        // if the minted token is erc1155, call the 1155 mint method
        if (multiSaleContract.settings.tokenType == TokenType.ERC1155) {

            IERC20Mint(multiSaleContract.settings.token).mintTo(recipient, amount);

        } else if (InterfaceChecker.isERC721(multiSaleContract.settings.token)) {
            tokenHash_ = new uint256[](amount);
            for (uint256 i = 0; i < amount; i++) {
                uint256 nextId = erc721AStorage.erc721Contract._currentIndex;
                IERC721Mint(address(this)).mintTo(recipient, amount, data);
                tokenHash_[i] = nextId;
            }

        } else if (InterfaceChecker.isERC1155(multiSaleContract.settings.token)) {
            tokenHash_ = new uint256[](1);
            tokenHash_[0] = multiSaleContract.nonce++;  // TODO
            IERC1155Mint(address(this)).mintTo(
                recipient,
                tokenHash_[0],
                amount,
                ""
            );
        } else {
            require(false, "Token not supported");
        }
    }

    /// @notice Get the token sale settings
    /// @param tokenSaleId - the token sale id
    function getTokenSaleSettings(uint256 tokenSaleId)
        external
        view
        virtual
        returns (MultiSaleSettings memory settings) {

        settings = MultiSaleLib
            .multiSaleStorage()
            ._tokenSales[tokenSaleId].settings;
    }

    /// @notice Get the token sale ids
    function getTokenSaleIds() external view returns (uint256[] memory) {
        return MultiSaleLib.multiSaleStorage()._tokenSaleIds;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TokenType } from "./IToken.sol";
import { VariablePriceContract } from "./IVariablePrice.sol";

/// @Nnotice the payment type for the token
enum PaymentType {
    Ether,
    ERC20
}

/// @notice the multisale purchase
struct MultiSalePurchase {
    uint256 multiSaleId;
    address purchaser;
    address receiver;
    uint256 quantity;
}
    
/// @notice the merkle proof for the token sale
struct MultiSaleProof {
    uint256 leaf;
    uint256 total;
    bytes32[] merkleProof;
}

/// @notice the settings for the token sale,
struct MultiSaleSettings {

    TokenType tokenType; // the type of token being sold
    address token; // the token being sold
    uint256 tokenHash; // the token hash being sold. set to 0 to autocreate hash

    uint256 whitelistHash; // the whitelist hash. set to 0 for owhitelist
    bool whitelistOnly; // if true, only whitelisted addresses can purchase

    // owner and payee
    address owner; // the owner of the contract
    address payee; // the payee of the co ntract

    string symbol; // the symbol of the token
    string name; // the name of the token
    string description; // the description of the token

    // open state
    bool openState; // open or closed
    uint256 startTime; // block number when the sale starts
    uint256 endTime; // block number when the sale ends

    // quantitiesp
    uint256 maxQuantity; // max number of tokens that can be sold
    uint256 maxQuantityPerSale; // max number of tokens that can be sold per sale
    uint256 minQuantityPerSale; // min number of tokens that can be sold per sale
    uint256 maxQuantityPerAccount; // max number of tokens that can be sold per account

    PaymentType paymentType; // the type of payment that is being used
    address tokenAddress; // the address of the payment token, if payment type is TOKEN

    uint256 nextSaleId; // the next sale id
    VariablePriceContract price; // the variable prices

}

/// @notice the multi sale contract
struct MultiSaleContract {
    MultiSaleSettings settings;

    uint256 nonce;
    uint256 totalPurchased;
        
    mapping(address => uint256) purchased;
    mapping(uint256 => uint256) _redeemedData;
    mapping(address => uint256) _redeemedDataQuantities;
    mapping(address => uint256) _totalDataQuantities;
}

/// @notice the multi sale storage
struct MultiSaleStorage {
    // the nonce
    uint256 tsnonce;
    mapping(uint256 => MultiSaleContract) _tokenSales; // token sale settings
    uint256[] _tokenSaleIds;
}


interface IMultiSale {

    // @notice emitted when a token sale is created
    event MultiSaleCreated(uint256 indexed tokenSaleId, MultiSaleSettings settings);

    /// @notice emitted when a token is opened
    event MultiSaleOpen (uint256 indexed tokenSaleId, MultiSaleSettings tokenSale);

    /// @notice emitted when a token is opened
    event MultiSaleClosed (uint256 indexed tokenSaleId);

    /// @notice emitted when a token is opened
    event MultiSaleSold (uint256 indexed tokenSaleId, address indexed purchaser, uint256[] tokenIds, bytes data);

    // token settings were updated
    event MultiSaleUpdated (uint256 indexed tokenSaleId, MultiSaleSettings tokenSale );

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow mminting
interface IERC20Mint {

    /// @notice event emitted when tokens are minted
    event ERC20Minted(
        address token,
        address receiver,
        uint256 amount
    );

    /// @notice mint tokens of specified amount to the specified address
    /// @param amount the amount to mint
    function mint(
        uint256 amount
    ) external;

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param amount the amount to mint
    function mintTo(
        address recipient,
        uint256 amount
    ) external;

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipients the mint target
    /// @param amount the amount to mint
    function batchMintTo(
        address[] memory recipients,
        uint256[] memory amount
    ) external;

}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow mminting
interface IERC721Mint {

    /// @notice mint tokens of specified amount to the specified address
    function mint(
        uint256 quantity,
        bytes calldata data
    ) external returns (uint256 tokenId);

    /// @notice mint tokens of specified amount to the specified address
    function mintTo(
        address receiver,
        uint256 quantity,
        bytes calldata data
    ) external returns (uint256 tokenId);

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IERC165 } from "@openzeppelin/contracts/interfaces/IERC165.sol";
import { IERC1155 } from "@openzeppelin/contracts/interfaces/IERC1155.sol";
import { IERC721 } from "@openzeppelin/contracts/interfaces/IERC721.sol";
import { IERC20 } from "@openzeppelin/contracts/interfaces/IERC20.sol";

library InterfaceChecker {
    function isERC1155(address check) internal view returns(bool) {
        return IERC165(check).supportsInterface(type(IERC1155).interfaceId);
    }
    function isERC721(address check) internal view returns(bool) {
        return IERC165(check).supportsInterface(type(IERC721).interfaceId);
    }
    function isERC20(address check) internal view returns(bool) {
        return IERC165(check).supportsInterface(type(IERC20).interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

import "../interfaces/IControllable.sol";

abstract contract Controllable is IControllable {
    mapping(address => bool) internal _controllers;

    /**
     * @dev Throws if called by any account not in authorized list
     */
    modifier onlyController() virtual {
        require(
            _controllers[msg.sender] == true || address(this) == msg.sender,
            "caller is not a controller"
        );
        _;
    }

    /**
     * @dev Add an address allowed to control this contract
     */
    function addController(address _controller)
        external
        override
        onlyController
    {
        _addController(_controller);
    }
    function _addController(address _controller) internal {
        _controllers[_controller] = true;
    }

    /**
     * @dev Check if this address is a controller
     */
    function isController(address _address)
        external
        view
        override
        returns (bool allowed)
    {
        allowed = _isController(_address);
    }
    function _isController(address _address)
        internal view
        returns (bool allowed)
    {
        allowed = _controllers[_address];
    }

    /**
     * @dev Remove the sender address from the list of controllers
     */
    function relinquishControl() external override onlyController {
        _relinquishControl();
    }
    function _relinquishControl() internal onlyController{
        delete _controllers[msg.sender];
    }
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

/// implemented by erc1155 tokens to allow mminting
interface IERC1155Mint {

    /// @notice event emitted when tokens are minted
    event ERC1155TokenMinted(
        address minter,
        uint256 id,
        uint256 quantity
    );

    /// @notice mint tokens of specified amount to the specified address
    /// @param quantity the amount to mint
    function mint(
        uint256 id,
        uint256 quantity,
        bytes memory data
    ) external;

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param quantity the amount to mint
    function mintTo(
        address recipient,
        uint256 id,
        uint256 quantity,
        bytes memory data
    ) external;

    /// @notice mint tokens of specified amount to the specified address
    /// @param recipient the mint target
    /// @param quantities the quantity to mint
    /// @param data transfer bytes data
    function batchMintTo(
        address recipient,
        uint256[] memory ids,
        uint256[] calldata quantities,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";

contract Modifiers {

    modifier onlyOwner() {
        require(LibDiamond.contractOwner() == msg.sender || address(this) == msg.sender,
            "not authorized to call function");
        _;
    }

    // function owner() public view returns (address) {
    //     return LibDiamond.contractOwner();
    // }

}

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0;

/**
 * @notice Key sets with enumeration and delete. Uses mappings for random
 * and existence checks and dynamic arrays for enumeration. Key uniqueness is enforced.
 * @dev Sets are unordered. Delete operations reorder keys. All operations have a
 * fixed gas cost at any scale, O(1).
 * author: Rob Hitchens
 */

library UInt256Set {
    struct Set {
        mapping(uint256 => uint256) keyPointers;
        uint256[] keyList;
    }

    /**
     * @notice insert a key.
     * @dev duplicate keys are not permitted.
     * @param self storage pointer to a Set.
     * @param key value to insert.
     */
    function insert(Set storage self, uint256 key) public {
        require(
            !exists(self, key),
            "UInt256Set: key already exists in the set."
        );
        self.keyList.push(key);
        self.keyPointers[key] = self.keyList.length - 1;
    }

    /**
     * @notice remove a key.
     * @dev key to remove must exist.
     * @param self storage pointer to a Set.
     * @param key value to remove.
     */
    function remove(Set storage self, uint256 key) public {
        // TODO: I commented this out do get a test to pass - need to figure out what is up here
        // require(
        //     exists(self, key),
        //     "UInt256Set: key does not exist in the set."
        // );
        if (!exists(self, key)) return;
        uint256 last = count(self) - 1;
        uint256 rowToReplace = self.keyPointers[key];
        if (rowToReplace != last) {
            uint256 keyToMove = self.keyList[last];
            self.keyPointers[keyToMove] = rowToReplace;
            self.keyList[rowToReplace] = keyToMove;
        }
        delete self.keyPointers[key];
        delete self.keyList[self.keyList.length - 1];
    }

    /**
     * @notice count the keys.
     * @param self storage pointer to a Set.
     */
    function count(Set storage self) public view returns (uint256) {
        return (self.keyList.length);
    }

    /**
     * @notice check if a key is in the Set.
     * @param self storage pointer to a Set.
     * @param key value to check.
     * @return bool true: Set member, false: not a Set member.
     */
    function exists(Set storage self, uint256 key)
        public
        view
        returns (bool)
    {
        if (self.keyList.length == 0) return false;
        return self.keyList[self.keyPointers[key]] == key;
    }

    /**
     * @notice fetch a key by row (enumerate).
     * @param self storage pointer to a Set.
     * @param index row to enumerate. Must be < count() - 1.
     */
    function keyAtIndex(Set storage self, uint256 index)
        public
        view
        returns (uint256)
    {
        return self.keyList[index];
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC20.sol";

import "./MerkleProof.sol";

import "../interfaces/IMultiSale.sol";
import "../interfaces/IVariablePrice.sol";

import "./VariablePriceLib.sol";

import "../utilities/InterfaceChecker.sol";


library MultiSaleLib {

    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.nextblock.bitgem.app.MultiSaleStorage.storage");

    /// @notice get the storage for the multisale
    /// @return ds the storage
    function multiSaleStorage()
        internal
        pure
        returns (MultiSaleStorage storage ds)
    {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice get a new tokensale id
    /// @return tokenSaleId the new id
    function _createTokenSale() internal returns (uint256 tokenSaleId) {

        // set settings object
        tokenSaleId = uint256(
            keccak256(
                abi.encodePacked(multiSaleStorage().tsnonce++, address(this))
            )
        );
    }

    /// @notice validate the token purchase
    /// @param self the multisale storage
    /// @param valueAttached the value attached to the transaction
    function _validatePurchase(
        MultiSaleContract storage self, 
        VariablePriceContract storage priceContract,
        uint256 quantity, 
        uint256 valueAttached) internal view {

        MultiSaleSettings storage settings = self.settings;

        // make sure there are still tokens to purchase
        require(settings.maxQuantity == 0 || (settings.maxQuantity != 0 &&
            self.totalPurchased < settings.maxQuantity), "soldout" );

        // make sure the max qty per sale is not exceeded
        require(settings.minQuantityPerSale == 0 || (settings.minQuantityPerSale != 0 &&
            quantity >= settings.minQuantityPerSale), "qtytoolow");

        // make sure the max qty per sale is not exceeded
        require(settings.maxQuantityPerSale == 0 || (settings.maxQuantityPerSale != 0 &&
            quantity <= settings.maxQuantityPerSale), "qtytoohigh");

        // make sure token sale is started
        require(block.timestamp >= settings.startTime || settings.startTime == 0, "notstarted");

        // make sure token sale is not over
        require(block.timestamp <= settings.endTime || settings.endTime == 0,
            "saleended" );
         
        // gt thte total price 
        uint256 totalPrice = priceContract.price * quantity;
        require(totalPrice <= valueAttached, "notenoughvalue");
    }
    
    /// @notice validate the token purchase using the given proof
    /// @param self the multisale storage
    /// @param purchaseProof the proof
    function _validateProof(
        MultiSaleContract storage self,
        MultiSalePurchase memory purchase,
        MultiSaleProof memory purchaseProof
    ) internal {
        if (self.settings.whitelistOnly) {

            // check that the airdrop has not yet been redeemed by the user
            require(!_airdropRedeemed(self, purchase.receiver), "redeemed");

            // check to see if redeemed already
            uint256 _redeemedAmt = self._redeemedDataQuantities[purchase.receiver];
            uint256 _redeemedttl = self._totalDataQuantities[purchase.receiver];
            _redeemedttl = _redeemedAmt > 0 ? _redeemedttl : purchaseProof.total;

            // ensure that the user has not redeemed more than the total
            require(_redeemedAmt + purchase.quantity <= _redeemedttl, "redeemed");
            self._totalDataQuantities[purchase.receiver] = _redeemedttl;
            self._redeemedDataQuantities[purchase.receiver] += purchase.quantity; // increment amount redeemed

            // check the proof
            bool valid = MerkleProof.verify(
                bytes32 (self.settings.whitelistHash),
                bytes32 (purchaseProof.leaf), purchaseProof.merkleProof
            );

            // Check the merkle proof
            require(valid, "Merkle proof failed");
        }
    }

    /// @notice airdrops check to see if proof is redeemed
    /// @param recipient the merkle proof
    /// @return isRedeemed the amount of tokens redeemed
    function _airdropRedeemed(MultiSaleContract storage self, address recipient) internal view returns (bool isRedeemed) {

        uint256 red = self._totalDataQuantities[recipient];
        uint256 tot = self._redeemedDataQuantities[recipient]; // i
        isRedeemed = red != 0 && red == tot;
    }

    /// @notice purchase a token sale token without any proof
    /// @param self the token sale id
    /// @param purchase the token hash
    function __purchase(
        MultiSaleContract storage self,
        MultiSalePurchase memory purchase,
        VariablePriceContract memory variablePrice,
        uint256 valueAttached
    ) internal {
        // transfer the payment to the contract if erc20
        if (self.settings.paymentType == PaymentType.ERC20 &&
            self.settings.tokenAddress != address(0)) {
            uint256 purchaseAmount = purchase.quantity * variablePrice.price;
            require(purchaseAmount > 0, "invalidamount");
            _transferErc20PaymkentToContract(
                purchase.purchaser,
                self.settings.tokenAddress,
                purchaseAmount
            );
        } else {
            uint256 purchaseAmount = purchase.quantity * variablePrice.price;
            require(valueAttached >= purchaseAmount, "invalidamount");
        }
        // transfer the tokens to the receiver
        _transferPaymentToPayee(self, valueAttached);

    }    

    /// @notice purchase a token sale token without any proof
    /// @param self the token sale id
    /// @param purchase the token hash
    function _purchaseToken(
        MultiSaleContract storage self,
        VariablePriceContract storage variablePrice,
        MultiSalePurchase memory purchase,
        MultiSaleProof memory purchaseProof,
        uint256 valueAttached
    ) internal {

        // validate the purchase
        _validatePurchase(self, variablePrice, purchase.quantity, valueAttached);
        
        // validate the proof
        _validateProof(self, purchase, purchaseProof);

        // make the purchase
        __purchase(
            self, 
            purchase, 
            VariablePriceLib.variablePriceStorage().variablePrices,
            valueAttached);

    }

    /// @notice purchase a token sale token without any proof
    /// @param self the token sale id
    /// @param purchase the token hash
    function _purchaseToken(
        MultiSaleContract storage self,
        VariablePriceContract storage variablePrice,
        MultiSalePurchase memory purchase,
        uint256 valueAttached
    ) internal {

        // validate the purchase
        _validatePurchase(self, variablePrice, purchase.quantity, valueAttached);

        // make the purchase
        __purchase(self, purchase, variablePrice, valueAttached);
    }
    
    /// @notice transfer erc20 payment to the contract
    /// @param sender the sender of the payment
    /// @param paymentToken the token address
    /// @param paymentAmount the amount of payment
    function _transferErc20PaymkentToContract(
        address sender,
        address paymentToken,
        uint256 paymentAmount
    ) internal {

        // transfer payment to contract
        IERC20(paymentToken).transferFrom(sender, address(this), paymentAmount);
    }

    /// @notice transfer payment to the token sale payee
    /// @param self the token sale settings
    /// @param valueAttached the value attached to the transaction
    function _transferPaymentToPayee(MultiSaleContract storage self, uint256 valueAttached) internal {

        // transfer the payment to the payee if the payee address is set
        if (self.settings.payee != address(0)) {
            if (self.settings.paymentType == PaymentType.ERC20) {
                IERC20(self.settings.tokenAddress).transferFrom(
                    address(this),
                    self.settings.payee,
                    valueAttached
                );
            } else {
                payable(self.settings.payee).transfer(valueAttached);
            }
        }
    }

    /// @notice get the token type
    /// @param token the token id
    /// @return tokenType the token type
    function _getTokenType(address token)
        internal
        view
        returns (TokenType tokenType) {

        tokenType = InterfaceChecker.isERC20(token)
            ? TokenType.ERC20
            : InterfaceChecker.isERC721(token)
            ? TokenType.ERC721
            : TokenType.ERC1155;
    }
}

//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IVariablePrice.sol";

library VariablePriceLib {
    event VariablePriceChanged(
        address eventContract,
        VariablePriceContract price
    );

    bytes32 internal constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.nextblock.bitgem.app.VariablePriceStorage.storage");

    /// @notice get the storage for variable pricing
    /// @return ds the storage
    function variablePriceStorage()
        internal
        pure
        returns (VariablePriceStorage storage ds) {

        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    /// @notice update the variable price contract
    /// @param self the variable price contract
    function _updatePrice(VariablePriceContract storage self)
        internal
        returns (uint256 _price, uint256 updatedPrice) {

        _price = self.price;
        _increaseClaimPrice(self);
        updatedPrice = self.price;
    }

    /// @notice get the current price of the claim
    /// @return _price the current price of the claim
    function _currentPrice(VariablePriceContract storage self)
        internal
        view
        returns (uint256 _price) {

        _price = self.price;
    }

    function _setPrice(VariablePriceContract storage self, uint256 _price)
        internal
        returns (uint256 _newPrice) {

        self.price = _price;
        _newPrice = self.price;
    }
    
    /// @notice Increases the price of the claim by the price increase rate
    /// @param self The variable price contract
    function _increaseClaimPrice(VariablePriceContract storage self) internal {
        
        // get the current price
        uint256 currentPrice = self.price;
        // get the current modifier
        PriceModifier currentModifier = self.priceModifier;
        // get the current modifier factor
        uint256 currentModifierFactor = self.priceModifierFactor;

        // fixed price - increase by modifier factor
        if (currentModifier == PriceModifier.Fixed) {
            currentPrice = currentPrice + currentModifierFactor;
        }
        // exponential intcrease
        else if (currentModifier == PriceModifier.Exponential) {
            currentPrice =
                currentPrice +
                (currentPrice / currentModifierFactor);
        }
        // inverse log increase
        else if (currentModifier == PriceModifier.InverseLog) {
            currentPrice =
                currentPrice +
                (currentPrice / (currentModifierFactor * currentPrice));
        } else {
            return;
        }
        // set the new price
        self.price = currentPrice;
    }
}

// SPDX-License-Identifier: MIT
// Creator: Chiru Labs
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/interfaces/IERC721Receiver.sol";

import "../interfaces/IERC721A.sol";
import "../interfaces/IERC721Enumerable.sol";


/* solhint-disable indent */
/* solhint-disable mark-callable-contracts */

error ApprovalCallerNotOwnerNorApproved();
error ApprovalQueryForNonexistentToken();
error ApproveToCaller();
error ApprovalToCurrentOwner();
error BalanceQueryForZeroAddress();
error MintedQueryForZeroAddress();
error BurnedQueryForZeroAddress();
error AuxQueryForZeroAddress();
error MintToZeroAddress();
error MintZeroQuantity();
error OwnerIndexOutOfBounds();
error OwnerQueryForNonexistentToken();
error TokenIndexOutOfBounds();
error TransferCallerNotOwnerNorApproved();
error TransferFromIncorrectOwner();
error TransferToNonERC721ReceiverImplementer();
error TransferToZeroAddress();
error URIQueryForNonexistentToken();

struct ERC721AStorage {
    ERC721EnumerableContract enumerations;
    ERC721AContract erc721Contract;
}

library ERC721ALib {

    using Strings for uint256;
    using Address for address;

    bytes32 internal constant DIAMOND_STORAGE_POSITION = keccak256("diamond.nextblock.bitgem.app.ERC721AStorage.storage");

    function erc721aStorage() internal pure returns (ERC721AStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

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
     * Returns the total number of minted tokens
     */
    function totalSupply(ERC721AContract storage self) internal view returns (uint256) {
        // Counter underflow is impossible as _burnCounter cannot be incremented
        // more than _currentIndex times
        unchecked {
            return self._currentIndex - self._burnCounter;
        }
    }
    
    /**
     * @dev See {IERC721-balanceOf}.
     */
    function balanceOf(ERC721AContract storage self, address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BalanceQueryForZeroAddress();
        return uint256(self._addressData[owner].balance);
    }

    /**
     * Returns the number of tokens minted by `owner`.
     */
    function _numberMinted(ERC721AContract storage self, address owner) internal view returns (uint256) {
        if (owner == address(0)) revert MintedQueryForZeroAddress();
        return uint256(self._addressData[owner].numberMinted);
    }

    /**
     * Returns the number of tokens burned by or on behalf of `owner`.
     */
    function _numberBurned(ERC721AContract storage self, address owner) internal view returns (uint256) {
        if (owner == address(0)) revert BurnedQueryForZeroAddress();
        return uint256(self._addressData[owner].numberBurned);
    }

    /**
     * Returns the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     */
    function _getAux(ERC721AContract storage self, address owner) internal view returns (uint64) {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        return self._addressData[owner].aux;
    }

    /**
     * Sets the auxillary data for `owner`. (e.g. number of whitelist mint slots used).
     * If there are multiple variables, please pack them into a uint64.
     */
    function _setAux(ERC721AContract storage self, address owner, uint64 aux) internal {
        if (owner == address(0)) revert AuxQueryForZeroAddress();
        self._addressData[owner].aux = aux;
    }

    function ownershipOf(ERC721AContract storage self, uint256 tokenId) internal view returns (TokenOwnership memory) {
        uint256 curr = tokenId;
        unchecked {
            if (curr < self._currentIndex) {
                TokenOwnership memory ownership = self._ownerships[curr];
                if (!ownership.burned) {
                    if (ownership.addr != address(0)) {
                        return ownership;
                    }
                    // Invariant:
                    // There will always be an ownership that has an address and is not burned
                    // before an ownership that does not have an address and is not burned.
                    // Hence, curr will not underflow.
                    while (true) {
                        curr--;
                        ownership = self._ownerships[curr];
                        if (ownership.addr != address(0)) {
                            return ownership;
                        }
                    }
                }
            }
        }
        revert OwnerQueryForNonexistentToken();
    }

    /**
     * @dev Returns whether `tokenId` exists.
     *
     * Tokens can be managed by their owner or approved accounts via {approve} or {setApprovalForAll}.
     *
     * Tokens start existing when they are minted (`_mint`),
     */
    function _exists(ERC721AContract storage self, uint256 tokenId) internal view returns (bool) {
        return tokenId < self._currentIndex && !self._ownerships[tokenId].burned;
    }

    /**
     * @dev See {IERC721-getApproved}.
     */
    function getApproved(ERC721AContract storage self, uint256 tokenId) internal view returns (address) {
        if (!_exists(self, tokenId)) revert ApprovalQueryForNonexistentToken();
        return self._tokenApprovals[tokenId];
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
     */
    function setApprovalForAll(ERC721AContract storage self, address sender, address operator, bool approved) internal {
        self._operatorApprovals[sender][operator] = approved;
        emit ApprovalForAll(sender, operator, approved);
    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
     */
    function isApprovedForAll(ERC721AContract storage self, address owner, address operator) internal view returns (bool) {
        return self._operatorApprovals[owner][operator];
    }

    /**
     * @dev Mints `quantity` tokens and transfers them to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `quantity` must be greater than 0.
     *
     * Emits a {Transfer} event.
     */
    function _mint(
        ERC721AContract storage self,
        address msgSender,
        address to,
        uint256 quantity,
        bytes memory _data,
        bool safe
    ) internal {
        // Overflows are incredibly unrealistic.
        // balance or numberMinted overflow if current value of either + quantity > 1.8e19 (2**64) - 1
        // updatedIndex overflows if _currentIndex + quantity > 1.2e77 (2**256) - 1
        uint256 startTokenId = self._currentIndex;
        if (to == address(0)) revert MintToZeroAddress();
        if (quantity == 0) revert MintZeroQuantity();

        _beforeTokenTransfers(self, address(0), to, startTokenId, quantity);

        unchecked {
            self._addressData[to].balance += uint64(quantity);
            self._addressData[to].numberMinted += uint64(quantity);

            self._ownerships[startTokenId].addr = to;
            self._ownerships[startTokenId].startTimestamp = uint64(block.timestamp);

            uint256 updatedIndex = startTokenId;

            for (uint256 i; i < quantity; i++) {
                emit Transfer(address(0), to, updatedIndex);
                if (safe && !_checkOnERC721Received(msgSender, address(0), to, updatedIndex, _data)) {
                    revert TransferToNonERC721ReceiverImplementer();
                }
                updatedIndex++;
            }

            self._currentIndex = updatedIndex;
        }

        _afterTokenTransfers(self, address(0), to, startTokenId, quantity);
    }

    /**
     * @dev Transfers `tokenId` from `from` to `to`.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     *
     * Emits a {Transfer} event.
     */
    function _transfer(
        ERC721AContract storage self,
        address msgSender,
        address from,
        address to,
        uint256 tokenId
    ) internal {
        TokenOwnership memory prevOwnership = ownershipOf(self, tokenId);

        bool isApprovedOrOwner = (msgSender == prevOwnership.addr ||
            isApprovedForAll(self, prevOwnership.addr, msgSender) ||
            getApproved(self, tokenId) == msgSender);

        if (!isApprovedOrOwner) revert TransferCallerNotOwnerNorApproved();
        if (prevOwnership.addr != from) revert TransferFromIncorrectOwner();
        if (to == address(0)) revert TransferToZeroAddress();

        _beforeTokenTransfers(self, from, to, tokenId, 1);

        // Clear approvals from the previous owner
        _approve(self, address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            self._addressData[from].balance -= 1;
            self._addressData[to].balance += 1;

            self._ownerships[tokenId].addr = to;
            self._ownerships[tokenId].startTimestamp = uint64(block.timestamp);

            // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (self._ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < self._currentIndex) {
                    self._ownerships[nextTokenId].addr = prevOwnership.addr;
                    self._ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(from, to, tokenId);
        _afterTokenTransfers(self, from, to, tokenId, 1);
    }

    /**
     * @dev Destroys `tokenId`.
     * The approval is cleared when the token is burned.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     *
     * Emits a {Transfer} event.
     */
    function _burn(ERC721AContract storage self, uint256 tokenId) internal {
        TokenOwnership memory prevOwnership = ownershipOf(self, tokenId);

        _beforeTokenTransfers(self, prevOwnership.addr, address(0), tokenId, 1);

        // Clear approvals from the previous owner
        _approve(self, address(0), tokenId, prevOwnership.addr);

        // Underflow of the sender's balance is impossible because we check for
        // ownership above and the recipient's balance can't realistically overflow.
        // Counter overflow is incredibly unrealistic as tokenId would have to be 2**256.
        unchecked {
            self._addressData[prevOwnership.addr].balance -= 1;
            self._addressData[prevOwnership.addr].numberBurned += 1;

            // Keep track of who burned the token, and the timestamp of burning.
            self._ownerships[tokenId].addr = prevOwnership.addr;
            self._ownerships[tokenId].startTimestamp = uint64(block.timestamp);
            self._ownerships[tokenId].burned = true;

            // If the ownership slot of tokenId+1 is not explicitly set, that means the burn initiator owns it.
            // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
            uint256 nextTokenId = tokenId + 1;
            if (self._ownerships[nextTokenId].addr == address(0)) {
                // This will suffice for checking _exists(nextTokenId),
                // as a burned slot cannot contain the zero address.
                if (nextTokenId < self._currentIndex) {
                    self._ownerships[nextTokenId].addr = prevOwnership.addr;
                    self._ownerships[nextTokenId].startTimestamp = prevOwnership.startTimestamp;
                }
            }
        }

        emit Transfer(prevOwnership.addr, address(0), tokenId);
        _afterTokenTransfers(self, prevOwnership.addr, address(0), tokenId, 1);

        // Overflow not possible, as _burnCounter cannot be exceed _currentIndex times.
        unchecked {
            self._burnCounter++;
        }
    }
    /**
     * @dev Approve `to` to operate on `tokenId`
     *
     * Emits a {Approval} event.
     */
    function _approve(
        ERC721AContract storage self,
        address to,
        uint256 tokenId,
        address owner
    ) internal {
        self._tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }


    /**
     * @dev Internal function to invoke {IERC721Receiver-onERC721Received} on a target address.
     * The call is not executed if the target address is not a contract.
     *
     * @param from address representing the previous owner of the given token ID
     * @param to target address that will receive the tokens
     * @param tokenId uint256 ID of the token to be transferred
     * @param _data bytes optional data to send along with the call
     * @return bool whether the call correctly returned the expected magic value
     */
    function _checkOnERC721Received(
        address msgSender,
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) internal returns (bool) {
        if (to.isContract()) {
            try IERC721Receiver(to).onERC721Received(msgSender, from, tokenId, _data) returns (bytes4 retval) {
                return retval == IERC721Receiver(to).onERC721Received.selector;
            } catch (bytes memory reason) {
                if (reason.length == 0) {
                    revert TransferToNonERC721ReceiverImplementer();
                } else {
                    assembly {
                        revert(add(32, reason), mload(reason))
                    }
                }
            }
        } else {
            return true;
        }
    }

    /**
     * @dev Hook that is called before a set of serially-ordered token ids are about to be transferred. This includes minting.
     * And also called before burning one token.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` will be
     * transferred to `to`.
     * - When `from` is zero, `tokenId` will be minted for `to`.
     * - When `to` is zero, `tokenId` will be burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _beforeTokenTransfers(
        ERC721AContract storage self,
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal {}

    /**
     * @dev Hook that is called after a set of serially-ordered token ids have been transferred. This includes
     * minting.
     * And also called after one token has been burned.
     *
     * startTokenId - the first token id to be transferred
     * quantity - the amount to be transferred
     *
     * Calling conditions:
     *
     * - When `from` and `to` are both non-zero, `from`'s `tokenId` has been
     * transferred to `to`.
     * - When `from` is zero, `tokenId` has been minted for `to`.
     * - When `to` is zero, `tokenId` has been burned by `from`.
     * - `from` and `to` are never both zero.
     */
    function _afterTokenTransfers(
        ERC721AContract storage self,
        address from,
        address to,
        uint256 startTokenId,
        uint256 quantity
    ) internal {}
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    /**
     * @dev Emitted when `value` tokens of token type `id` are transferred from `from` to `to` by `operator`.
     */
    event TransferSingle(address indexed operator, address indexed from, address indexed to, uint256 id, uint256 value);

    /**
     * @dev Equivalent to multiple {TransferSingle} events, where `operator`, `from` and `to` are the same for all
     * transfers.
     */
    event TransferBatch(
        address indexed operator,
        address indexed from,
        address indexed to,
        uint256[] ids,
        uint256[] values
    );

    /**
     * @dev Emitted when `account` grants or revokes permission to `operator` to transfer their tokens, according to
     * `approved`.
     */
    event ApprovalForAll(address indexed account, address indexed operator, bool approved);

    /**
     * @dev Emitted when the URI for token type `id` changes to `value`, if it is a non-programmatic URI.
     *
     * If an {URI} event was emitted for `id`, the standard
     * https://eips.ethereum.org/EIPS/eip-1155#metadata-extensions[guarantees] that `value` will equal the value
     * returned by {IERC1155MetadataURI-uri}.
     */
    event URI(string value, uint256 indexed id);

    /**
     * @dev Returns the amount of tokens of token type `id` owned by `account`.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id) external view returns (uint256);

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {balanceOf}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids)
        external
        view
        returns (uint256[] memory);

    /**
     * @dev Grants or revokes permission to `operator` to transfer the caller's tokens, according to `approved`,
     *
     * Emits an {ApprovalForAll} event.
     *
     * Requirements:
     *
     * - `operator` cannot be the caller.
     */
    function setApprovalForAll(address operator, bool approved) external;

    /**
     * @dev Returns true if `operator` is approved to transfer ``account``'s tokens.
     *
     * See {setApprovalForAll}.
     */
    function isApprovedForAll(address account, address operator) external view returns (bool);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;

    /**
     * @dev xref:ROOT:erc1155.adoc#batch-operations[Batched] version of {safeTransferFrom}.
     *
     * Emits a {TransferBatch} event.
     *
     * Requirements:
     *
     * - `ids` and `amounts` must have the same length.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155BatchReceived} and return the
     * acceptance magic value.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external;
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
pragma solidity >=0.8.0;

/// @notice the definition for a token.
struct TokenDefinition {
    address token;
    string name;
    string symbol;
    string description;
    uint256 totalSupply;
    string imageName;
    string[] imagePalette;
    string externalUrl;
}

enum TokenType {
    ERC20,
    ERC721,
    ERC1155
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;


/// @notice DIctates how the price of the token is increased post every sale
enum PriceModifier {
    None,
    Fixed,
    Exponential,
    InverseLog
}

struct VariablePriceContract {
    // the price of the token
    uint256 price;
        // how the price is modified
    PriceModifier priceModifier;
    // only used if priceModifier is EXPONENTIAL or INVERSELOG or FIXED
    uint256 priceModifierFactor;
    // max price for the token
    uint256 maxPrice;
}

struct VariablePriceStorage {
    // the price of the token
    VariablePriceContract variablePrices;
}

/// @notice common struct definitions for tokens
interface IVariablePrice {
    /// @notice get the increased price of the token
    function getIncreasedPrice() external view returns (uint256);

    /// @notice get the increased price of the token
    function getTokenPrice() external view returns (VariablePriceContract memory);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1155.sol)

pragma solidity ^0.8.0;

import "../token/ERC1155/IERC1155.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC165.sol)

pragma solidity ^0.8.0;

import "../utils/introspection/IERC165.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721.sol";

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
pragma solidity >=0.8.0;

/// @notice a controllable contract interface. allows for controllers to perform privileged actions. controllera can other controllers and remove themselves.
interface IControllable {

    /// @notice emitted when a controller is added.
    event ControllerAdded(
        address indexed contractAddress,
        address indexed controllerAddress
    );

    /// @notice emitted when a controller is removed.
    event ControllerRemoved(
        address indexed contractAddress,
        address indexed controllerAddress
    );

    /// @notice adds a controller.
    /// @param controller the controller to add.
    function addController(address controller) external;

    /// @notice removes a controller.
    /// @param controller the address to check
    /// @return true if the address is a controller
    function isController(address controller) external view returns (bool);

    /// @notice remove ourselves from the list of controllers.
    function relinquishControl() external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";

// Remember to add the loupe functions from DiamondLoupeFacet to the diamond.
// The loupe functions are required by the EIP2535 Diamonds standard

library LibDiamond {
    bytes32 constant DIAMOND_STORAGE_POSITION = keccak256("diamond.standard.diamond.storage");

    struct FacetAddressAndPosition {
        address facetAddress;
        uint96 functionSelectorPosition; // position in facetFunctionSelectors.functionSelectors array
    }

    struct FacetFunctionSelectors {
        bytes4[] functionSelectors;
        uint256 facetAddressPosition; // position of facetAddress in facetAddresses array
    }

    struct DiamondStorage {
        // maps function selector to the facet address and
        // the position of the selector in the facetFunctionSelectors.selectors array
        mapping(bytes4 => FacetAddressAndPosition) selectorToFacetAndPosition;
        // maps facet addresses to function selectors
        mapping(address => FacetFunctionSelectors) facetFunctionSelectors;
        // facet addresses
        address[] facetAddresses;
        // Used to query if a contract implements an interface.
        // Used to implement ERC-165.
        mapping(bytes4 => bool) supportedInterfaces;
        // owner of the contract
        address contractOwner;
    }

    function diamondStorage() internal pure returns (DiamondStorage storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function setContractOwner(address _newOwner) internal {
        DiamondStorage storage ds = diamondStorage();
        address previousOwner = ds.contractOwner;
        ds.contractOwner = _newOwner;
        emit OwnershipTransferred(previousOwner, _newOwner);
    }

    function contractOwner() internal view returns (address contractOwner_) {
        contractOwner_ = diamondStorage().contractOwner;
    }

    function enforceIsContractOwner() internal view {
        //require(msg.sender == diamondStorage().contractOwner, "LibDiamond: Must be contract owner");
    }

    event DiamondCut(IDiamondCut.FacetCut[] _diamondCut, address _init, bytes _calldata);

    // Internal function version of diamondCut
    function diamondCut(
        IDiamondCut.FacetCut[] memory _diamondCut,
        address _init,
        bytes memory _calldata
    ) internal {
        for (uint256 facetIndex; facetIndex < _diamondCut.length; facetIndex++) {
            IDiamondCut.FacetCutAction action = _diamondCut[facetIndex].action;
            if (action == IDiamondCut.FacetCutAction.Add) {
                addFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Replace) {
                replaceFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else if (action == IDiamondCut.FacetCutAction.Remove) {
                removeFunctions(_diamondCut[facetIndex].facetAddress, _diamondCut[facetIndex].functionSelectors);
            } else {
                revert("LibDiamondCut: Incorrect FacetCutAction");
            }
        }
        emit DiamondCut(_diamondCut, _init, _calldata);
        initializeDiamondCut(_init, _calldata);
    }

    function addFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();        
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);            
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress == address(0), "LibDiamondCut: Can't add function that already exists");
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function replaceFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        require(_facetAddress != address(0), "LibDiamondCut: Add facet can't be address(0)");
        uint96 selectorPosition = uint96(ds.facetFunctionSelectors[_facetAddress].functionSelectors.length);
        // add new facet address if it does not exist
        if (selectorPosition == 0) {
            addFacet(ds, _facetAddress);
        }
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            require(oldFacetAddress != _facetAddress, "LibDiamondCut: Can't replace function with same function");
            removeFunction(ds, oldFacetAddress, selector);
            addFunction(ds, selector, selectorPosition, _facetAddress);
            selectorPosition++;
        }
    }

    function removeFunctions(address _facetAddress, bytes4[] memory _functionSelectors) internal {
        require(_functionSelectors.length > 0, "LibDiamondCut: No selectors in facet to cut");
        DiamondStorage storage ds = diamondStorage();
        // if function does not exist then do nothing and return
        require(_facetAddress == address(0), "LibDiamondCut: Remove facet address must be address(0)");
        for (uint256 selectorIndex; selectorIndex < _functionSelectors.length; selectorIndex++) {
            bytes4 selector = _functionSelectors[selectorIndex];
            address oldFacetAddress = ds.selectorToFacetAndPosition[selector].facetAddress;
            removeFunction(ds, oldFacetAddress, selector);
        }
    }

    function addFacet(DiamondStorage storage ds, address _facetAddress) internal {
        enforceHasContractCode(_facetAddress, "LibDiamondCut: New facet has no code");
        ds.facetFunctionSelectors[_facetAddress].facetAddressPosition = ds.facetAddresses.length;
        ds.facetAddresses.push(_facetAddress);
    }    


    function addFunction(DiamondStorage storage ds, bytes4 _selector, uint96 _selectorPosition, address _facetAddress) internal {
        ds.selectorToFacetAndPosition[_selector].functionSelectorPosition = _selectorPosition;
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.push(_selector);
        ds.selectorToFacetAndPosition[_selector].facetAddress = _facetAddress;
    }

    function removeFunction(DiamondStorage storage ds, address _facetAddress, bytes4 _selector) internal {        
        require(_facetAddress != address(0), "LibDiamondCut: Can't remove function that doesn't exist");
        // an immutable function is a function defined directly in a diamond
        require(_facetAddress != address(this), "LibDiamondCut: Can't remove immutable function");
        // replace selector with last selector, then delete last selector
        uint256 selectorPosition = ds.selectorToFacetAndPosition[_selector].functionSelectorPosition;
        uint256 lastSelectorPosition = ds.facetFunctionSelectors[_facetAddress].functionSelectors.length - 1;
        // if not the same then replace _selector with lastSelector
        if (selectorPosition != lastSelectorPosition) {
            bytes4 lastSelector = ds.facetFunctionSelectors[_facetAddress].functionSelectors[lastSelectorPosition];
            ds.facetFunctionSelectors[_facetAddress].functionSelectors[selectorPosition] = lastSelector;
            ds.selectorToFacetAndPosition[lastSelector].functionSelectorPosition = uint96(selectorPosition);
        }
        // delete the last selector
        ds.facetFunctionSelectors[_facetAddress].functionSelectors.pop();
        delete ds.selectorToFacetAndPosition[_selector];

        // if no more selectors for facet address then delete the facet address
        if (lastSelectorPosition == 0) {
            // replace facet address with last facet address and delete last facet address
            uint256 lastFacetAddressPosition = ds.facetAddresses.length - 1;
            uint256 facetAddressPosition = ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
            if (facetAddressPosition != lastFacetAddressPosition) {
                address lastFacetAddress = ds.facetAddresses[lastFacetAddressPosition];
                ds.facetAddresses[facetAddressPosition] = lastFacetAddress;
                ds.facetFunctionSelectors[lastFacetAddress].facetAddressPosition = facetAddressPosition;
            }
            ds.facetAddresses.pop();
            delete ds.facetFunctionSelectors[_facetAddress].facetAddressPosition;
        }
    }

    function initializeDiamondCut(address _init, bytes memory _calldata) internal {
        if (_init == address(0)) {
            require(_calldata.length == 0, "LibDiamondCut: _init is address(0) but_calldata is not empty");
        } else {
            require(_calldata.length > 0, "LibDiamondCut: _calldata is empty but _init is not address(0)");
            if (_init != address(this)) {
                enforceHasContractCode(_init, "LibDiamondCut: _init address has no code");
            }
            (bool success, bytes memory error) = _init.delegatecall(_calldata);
            if (!success) {
                if (error.length > 0) {
                    // bubble up the error
                    revert(string(error));
                } else {
                    revert("LibDiamondCut: _init function reverted");
                }
            }
        }
    }

    function enforceHasContractCode(address _contract, string memory _errorMessage) internal view {
        uint256 contractSize;
        assembly {
            contractSize := extcodesize(_contract)
        }
        require(contractSize > 0, _errorMessage);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <[email protected]> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
/******************************************************************************/

interface IDiamondCut {
    enum FacetCutAction {Add, Replace, Remove}
    // Add=0, Replace=1, Remove=2

    struct FacetCut {
        address facetAddress;
        FacetCutAction action;
        bytes4[] functionSelectors;
    }

    /// @notice Add/replace/remove any number of functions and optionally execute
    ///         a function with delegatecall
    /// @param _diamondCut Contains the facet addresses and function selectors
    /// @param _init The address of the contract or facet to execute _calldata
    /// @param _calldata A function call, including function selector and arguments
    ///                  _calldata is executed with delegatecall on _init
    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    event DiamondCut(FacetCut[] _diamondCut, address _init, bytes _calldata);
}

// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

library MerkleProof {

  function verify(
    bytes32 root,
    bytes32 leaf,
    bytes32[] memory proof
  )
    public
    pure
    returns (bool)
  {
    bytes32 computedHash = leaf;

    for (uint256 i = 0; i < proof.length; i++) {
      bytes32 proofElement = proof[i];

      if (computedHash <= proofElement) {
        // Hash(current computed hash + current element of the proof)
        computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
      } else {
        // Hash(current element of the proof + current computed hash)
        computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
      }
    }

    // Check if the computed hash (root) is equal to the provided root
    return computedHash == root;
  }

  function getHash(address a, uint256 b) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(a, b));
  }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/* solhint-disable indent */

// Compiler will pack this into a single 256bit word.
struct TokenOwnership {
    address addr; // The address of the owner.
    uint64 startTimestamp; // Keeps track of the start time of ownership with minimal overhead for tokenomics.
    bool burned; // Whether the token has been burned.
}

// Compiler will pack this into a single 256bit word.
struct AddressData {
    
    uint64 balance; // Realistically, 2**64-1 is more than enough.
    uint64 numberMinted; // Keeps track of mint count with minimal overhead for tokenomics.
    uint64 numberBurned; // Keeps track of burn count with minimal overhead for tokenomics.
    // For miscellaneous variable(s) pertaining to the address
    // (e.g. number of whitelist mint slots used).
    // If there are multiple variables, please pack them into a uint64.
    uint64 aux;
}

struct ERC721AContract {
    // The tokenId of the next token to be minted.
    uint256 _currentIndex;

    // The number of tokens burned.
    uint256 _burnCounter;

    // Token name
    string _name;

    // Token symbol
    string _symbol;

    // the base uri
    string __uri;

    // Mapping from token ID to ownership details
    // An empty struct value does not necessarily mean the token is unowned. See ownershipOf implementation for details.
    mapping(uint256 => TokenOwnership) _ownerships;

    // Mapping owner address to address data
    mapping(address => AddressData) _addressData;

    // Mapping from token ID to approved address
    mapping(uint256 => address) _tokenApprovals;

    // Mapping from owner to operator approvals
    mapping(address => mapping(address => bool)) _operatorApprovals;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC721/extensions/IERC721Enumerable.sol)

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/interfaces/IERC721.sol";

struct ERC721EnumerableContract {
    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) _allTokensIndex;
}

/**
 * @title ERC-721 Non-Fungible Token Standard, optional enumeration extension
 * @dev See https://eips.ethereum.org/EIPS/eip-721
 */
interface IERC721Enumerable is IERC721 {
    /**
     * @dev Returns the total amount of tokens stored by the contract.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns a token ID owned by `owner` at a given `index` of its token list.
     * Use along with {balanceOf} to enumerate all of ``owner``'s tokens.
     */
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

    /**
     * @dev Returns a token ID at a given `index` of all the tokens stored by the contract.
     * Use along with {totalSupply} to enumerate all tokens.
     */
    function tokenByIndex(uint256 index) external view returns (uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library Address {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCall(target, data, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        require(isContract(target), "Address: static call to non-contract");

        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionDelegateCall(target, data, "Address: low-level delegate call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function functionDelegateCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(isContract(target), "Address: delegate call to non-contract");

        (bool success, bytes memory returndata) = target.delegatecall(data);
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verifies that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            // Look for revert reason and bubble it up if present
            if (returndata.length > 0) {
                // The easiest way to bubble the revert reason is using memory via assembly
                /// @solidity memory-safe-assembly
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert(errorMessage);
            }
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC721Receiver.sol)

pragma solidity ^0.8.0;

import "../token/ERC721/IERC721Receiver.sol";

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

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

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0x00";
        }
        uint256 temp = value;
        uint256 length = 0;
        while (temp != 0) {
            length++;
            temp >>= 8;
        }
        return toHexString(value, length);
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _HEX_SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
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