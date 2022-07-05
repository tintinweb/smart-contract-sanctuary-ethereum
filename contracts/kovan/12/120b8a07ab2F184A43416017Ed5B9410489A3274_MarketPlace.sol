// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import '@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol';
import './Auction.sol';
import './Sale.sol';
import './Minting.sol';

/**
 * @title Auction contract
 * @dev Auction contract for ERC721 token lots
 */
contract MarketPlace is Initializable, IERC721Receiver, Auction, Sale, Minting {
    function initialize (
        address newOwner,
        address paymentToken,
        address nftToken
    ) public initializer returns (bool) {
        require(newOwner != address(0), 'Owner address should not be zero');
        require(paymentToken != address(0), 'Payment token address should not be zero');
        require(nftToken != address(0), 'Nft token address should not be zero');
        _owner = msg.sender;
        addRole('admin', newOwner);
        addRole('manager', newOwner);
        transferOwnership(newOwner);
        _paymentToken = IERC20(paymentToken);
        _nftToken = IERC721Token(nftToken);
        _feeReceiver = newOwner;
        _fee = 10;
        return true;
    }

    // Manager functions
    /**
    * @dev Setting new ETNA fee amount
    */
    function setFee (uint8 newFee) external hasRole('admin') returns (bool) {
        _fee = newFee;
        return true;
    }

    /**
    * @dev set payment token address
    */
    function setPaymentToken (address paymentToken) external hasRole('admin') returns (bool) {
        require(paymentToken != address(0), 'Payment token address should not be zero');
        _paymentToken = IERC20(paymentToken);
        return true;
    }

    /**
    * @dev set nft token address
    */
    function setNftToken (address nftToken) external hasRole('admin') returns (bool) {
        require(nftToken != address(0), 'Nft token address should not be zero');
        _nftToken = IERC721Token(nftToken);
        return true;
    }

    /**
    * @dev set fee receiver address
    */
    function setFeeReceiver (address feeReceiver) external hasRole('admin') returns (bool) {
        require(feeReceiver != address(0), 'Fee receiver address should not be zero');
        _feeReceiver = feeReceiver;
        return true;
    }

    // view functions
    /**
    * @dev return payment token address
    */
    function getPaymentToken () external view returns (address) {
        return address(_paymentToken);
    }

    /**
    * @dev return nft token address
    */
    function getNftToken () external view returns (address) {
        return address(_nftToken);
    }

    /**
    * @dev return fee receiver address
    */
    function getFeeReceiver () external view returns (address) {
        return _feeReceiver;
    }

    /**
    * @dev return auction fee
    */
    function fee () external view returns (uint256) {
        return _fee;
    }

    /**
    * @dev Standard callback fot the ERC721 token receiver.
    */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function timestamp () external view returns (uint256) {
        return block.timestamp;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "../../utils/Address.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts. Equivalent to `reinitializer(1)`.
     */
    modifier initializer() {
        bool isTopLevelCall = _setInitializedVersion(1);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * `initializer` is equivalent to `reinitializer(1)`, so a reinitializer may be used after the original
     * initialization step. This is essential to configure modules that are added through upgrades and that require
     * initialization.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     */
    modifier reinitializer(uint8 version) {
        bool isTopLevelCall = _setInitializedVersion(version);
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(version);
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     */
    function _disableInitializers() internal virtual {
        _setInitializedVersion(type(uint8).max);
    }

    function _setInitializedVersion(uint8 version) private returns (bool) {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, and for the lowest level
        // of initializers, because in other contexts the contract may have been reentered.
        if (_initializing) {
            require(
                version == 1 && !Address.isContract(address(this)),
                "Initializable: contract is already initialized"
            );
            return false;
        } else {
            require(_initialized < version, "Initializable: contract is already initialized");
            _initialized = version;
            return true;
        }
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

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import './ProxyAccessControl.sol';

/**
 * @title Auction contract
 * @dev Auction contract for ERC721 token lots
 */
contract Auction is ProxyAccessControl {
    event NewLot (
        uint256 indexed lotId,
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 step,
        uint256 startBid,
        uint256 singlePaymentValue,
        address owner
    );
    event Bid (
        address sender,
        uint256 indexed lotId,
        uint256 amount
    );
    event AuctionCompleted (
        uint256 indexed lotId,
        address buyer
    );

    /**
    * @dev Create new lot with specified lot Id
    */
    function createLot (
        uint256 tokenId,
        uint256 startTime,
        uint256 endTime,
        uint256 step,
        uint256 startBid,
        uint256 singlePaymentValue
    ) external returns (bool) {
        require(startTime > block.timestamp, 'Start time should be in future');
        require(endTime > startTime, 'End time should be greater than start time');
        _lotsNumber ++;
        if (singlePaymentValue > 0) {
            require(singlePaymentValue > startBid,
                'The value for buying at once should be greater than the start bid');
            _lots[_lotsNumber].singlePaymentValue = singlePaymentValue;
        }
        _nftToken.safeTransferFrom(msg.sender, address(this), tokenId);

        _lots[_lotsNumber].tokenId = tokenId;
        _lots[_lotsNumber].startTime = startTime;
        _lots[_lotsNumber].endTime = endTime;
        _lots[_lotsNumber].step = step;
        _lots[_lotsNumber].startBid = startBid;
        _lots[_lotsNumber].owner = msg.sender;
        _userLotsNumber[msg.sender] ++;
        _userLotIds[msg.sender][_userLotsNumber[msg.sender]] = _lotsNumber;

        emit NewLot (
            _lotsNumber,
            tokenId,
            startTime,
            endTime,
            step,
            startBid,
            singlePaymentValue,
            msg.sender
        );
        return true;
    }

    /**
    * @dev Make a bid
    */
    function bid (uint256 lotId, uint256 amount) external returns (bool) {
        require (lotIsActive(lotId), 'This lot is not active');
        require (
            _lots[lotId].lastBid == 0 && amount >= _lots[lotId].startBid ||
                _lots[lotId].lastBid > 0 && amount >= _lots[lotId].lastBid + _lots[lotId].step
                || _lots[lotId].singlePaymentValue > 0 && amount >= _lots[lotId].singlePaymentValue,
            'Amount less than should be, check lot data'
        );
        bool complete;
        if (_lots[lotId].singlePaymentValue > 0 && amount >= _lots[lotId].singlePaymentValue) {
            amount = _lots[lotId].singlePaymentValue;
            complete = true;
        }
        require(
            _paymentToken.transferFrom(msg.sender, address(this), amount),
                'Token transfer to the contract failed'
        );
        require(_proceedBid(lotId, amount, msg.sender), 'Bid proceeding failed');
        if (complete) {
            require(completeLot(lotId), 'Bid completing failed');
        }
        return true;
    }

    /**
    * @dev Internal function for processing bid
    */
    function _proceedBid (
        uint256 lotId, uint256 amount, address sender
    ) private returns (bool) {
        address _previousBidSender = _lots[lotId].lastBidSender;
        uint256 _previousBid = _lots[lotId].lastBid;
        _lots[lotId].lastBidSender = msg.sender;
        _lots[lotId].lastBidTime = block.timestamp;
        _lots[lotId].lastBid = amount;
        if (_previousBidSender != address(0) && _previousBid > 0) {
            require(
                _paymentToken.transfer(_previousBidSender, _previousBid),
                    'Token transfer to the previous bid sender failed'
            );
        }
        emit Bid (
            sender,
            lotId,
            amount
        );
        return true;
    }

    /**
     * @dev completeLot function can be sent by anybody.
     * If no bid was sent ERC721 token will be sent to the address stored at the _lots[lotId].tokenRefundAddress
     * otherwise ERC721 token will be sent to the last bid sender and last bid value will be sent
     * to the address stored at the _lots[lotId].ethReceiver
     */
    function completeLot (
        uint256 lotId
    ) public returns (bool) {
        require (_lots[lotId].startTime > 0, 'This lot is not exist');
        require (_lots[lotId].completed == 0, 'This lot is already completed');
        require (
            _lots[lotId].endTime < block.timestamp 
                || _lots[lotId].singlePaymentValue > 0 
                    && _lots[lotId].singlePaymentValue == _lots[lotId].lastBid,
            'This lot is active yet'
        );
        if (_lots[lotId].lastBid == 0) {
            // no bid happened, send ERC721 token to the refund address
            _nftToken.safeTransferFrom(
                address(this),
                _lots[lotId].owner,
                _lots[lotId].tokenId
            );
        } else {
            _nftToken.safeTransferFrom(
            // auction was successful, send ERC721 token to the last bid sender
                address(this),
                _lots[lotId].lastBidSender,
                _lots[lotId].tokenId
            );
            uint256 feeAmount = _lots[lotId].lastBid * _fee / 100;
            uint256 paymentAmount = _lots[lotId].lastBid - feeAmount;
            require(_paymentToken.transfer(_feeReceiver, feeAmount));
            require(_paymentToken.transfer(_lots[lotId].owner, paymentAmount));
        }
        _lots[lotId].completed = block.timestamp;
        emit AuctionCompleted (
            lotId,
            _lots[lotId].lastBidSender
        );
        return true;
    }

    /**
    * @dev return lots number
    */
    function getLotsNumber () external view returns (uint256) {
        return _lotsNumber;
    }

    /**
    * @dev return log data
    */
    function getLotData (uint256 lotId) external view returns (
        uint256[] memory uintValues,
        address lastBidSender,
        address owner
    ) {
        uint256[] memory _uintValues = new uint256[](9);
        _uintValues[0] = _lots[lotId].tokenId;
        _uintValues[1] = _lots[lotId].startTime;
        _uintValues[2] = _lots[lotId].endTime;
        _uintValues[3] = _lots[lotId].step;
        _uintValues[4] = _lots[lotId].startBid;
        _uintValues[5] = _lots[lotId].lastBid;
        _uintValues[6] = _lots[lotId].lastBidTime;
        _uintValues[7] = _lots[lotId].singlePaymentValue;
        _uintValues[8] = _lots[lotId].completed;
        return (
            _uintValues,
            _lots[lotId].lastBidSender,
            _lots[lotId].owner
        );
    }

    /**
    * @dev return user's lots number
    */
    function getUserLotsNumber (address userAddress) external view returns (uint256) {
        return _userLotsNumber[userAddress];
    }

    /**
    * @dev return user lot id by index
    */
    function getUserLotId (
        address userAddress,
        uint256 index
    ) external view returns (uint256) {
        return _userLotIds[userAddress][index];
    }

    function lotIsActive (uint256 lotId) public view returns (bool) {
        return _lots[lotId].completed == 0 &&
            _lots[lotId].startTime > 0 &&
            _lots[lotId].startTime < block.timestamp &&
            _lots[lotId].endTime > block.timestamp &&
            (
                _lots[lotId].singlePaymentValue == 0
                || _lots[lotId].singlePaymentValue > _lots[lotId].lastBid
            );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import './ProxyAccessControl.sol';

/**
 * @title Auction contract
 * @dev Auction contract for ERC721 token lots
 */
contract Sale is ProxyAccessControl {
    event NewSaleRecord (
        uint256 indexed saleRecordId,
        uint256 tokenId,
        uint256 price,
        address owner
    );
    event SaleCompleted (
        uint256 indexed saleRecordId,
        address buyer
    );

    /**
    * @dev Create sale record with specified tokenId
    */
    function createSaleRecord (
        uint256 tokenId,
        uint256 price
    ) external returns (bool) {
        require(price > 0, 'Price should be greater than zero');
        _saleRecordsNumber ++;
        _nftToken.safeTransferFrom(msg.sender, address(this), tokenId);

        _saleRecords[_saleRecordsNumber].owner = msg.sender;
        _saleRecords[_saleRecordsNumber].tokenId = tokenId;
        _saleRecords[_saleRecordsNumber].price = price;
        _lots[_lotsNumber].owner = msg.sender;
        _userSaleRecordsNumber[msg.sender] ++;
        _userSaleRecordIds[msg.sender][_userSaleRecordsNumber[msg.sender]] = _saleRecordsNumber;

        emit NewSaleRecord (
            _saleRecordsNumber,
            tokenId,
            price,
            msg.sender
        );
        return true;
    }

    /**
    * @dev Buy token
    */
    function buy (uint256 saleRecordId) external returns (bool) {
        require (saleRecordIsActive(saleRecordId), 'This sale record is not active');
        uint256 amount = _saleRecords[saleRecordId].price;
        require(
            _paymentToken.transferFrom(msg.sender, address(this), amount),
                'Token transfer to the contract failed'
        );
        _nftToken.safeTransferFrom(
            address(this),
            msg.sender,
            _saleRecords[saleRecordId].tokenId
        );
        uint256 feeAmount = amount * _fee / 100;
        uint256 paymentAmount = amount - feeAmount;
        require(_paymentToken.transfer(_feeReceiver, feeAmount));
        require(_paymentToken.transfer(_saleRecords[saleRecordId].owner, paymentAmount));
        _saleRecords[saleRecordId].buyer = msg.sender;
        _saleRecords[saleRecordId].completed = block.timestamp;
        emit SaleCompleted (
            saleRecordId,
            msg.sender
        );
        return true;
    }

    /**
    * @dev Buy token
    */
    function cancelSaleRecord (uint256 saleRecordId) external returns (bool) {
        require (
            _saleRecords[saleRecordId].owner == msg.sender,
                'Caller is not the sale record owner'
        );
        require (
            _saleRecords[saleRecordId].completed == 0,
                'This sale record is already completed'
        );
        uint256 amount = _saleRecords[saleRecordId].price;
        _nftToken.safeTransferFrom(
            address(this),
            msg.sender,
            _saleRecords[saleRecordId].tokenId
        );
        _saleRecords[saleRecordId].completed = block.timestamp;
        emit SaleCompleted (
            saleRecordId,
            address(0)
        );
        return true;
    }

    /**
    * @dev return lots number
    */
    function getSaleRecordsNumber () external view returns (uint256) {
        return _saleRecordsNumber;
    }

    /**
    * @dev return log data
    */
    function getSaleRecordData (uint256 saleRecordId) external view returns (
        uint256 tokenId,
        uint256 price,
        uint256 completed,
        address owner,
        address buyer
    ) {
        return (
            _saleRecords[saleRecordId].tokenId,
            _saleRecords[saleRecordId].price,
            _saleRecords[saleRecordId].completed,
            _saleRecords[saleRecordId].owner,
            _saleRecords[saleRecordId].buyer
        );
    }

    /**
    * @dev return user's lots number
    */
    function getUserSaleRecordsNumber (address userAddress) external view returns (uint256) {
        return _userSaleRecordsNumber[userAddress];
    }

    /**
    * @dev return user lot id by index
    */
    function getUserSaleRecordId (
        address userAddress,
        uint256 index
    ) external view returns (uint256) {
        return _userSaleRecordIds[userAddress][index];
    }

    function saleRecordIsActive (uint256 saleRecordId) public view returns (bool) {
        return _saleRecords[saleRecordId].completed == 0 &&
            _saleRecords[saleRecordId].price > 0;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import './ProxyAccessControl.sol';

/**
 * @title Auction contract
 * @dev Auction contract for ERC721 token lots
 */
contract Minting is ProxyAccessControl {
    event NewMintingRecord (
        uint256 indexed mintingRecordId,
        uint256 price,
        address owner,
        string tokenUri
    );
    event MintingRecordAccepted (
        uint256 indexed mintingRecordId
    );
    event MintingRecordCompleted (
        uint256 indexed mintingRecordId,
        address buyer
    );

    /**
    * @dev Create minting record with specified tokenUri
    */
    function createMintingRecord (
        string calldata tokenUri,
        uint256 price
    ) external returns (bool) {
        require(price > 0, 'Price should be greater than zero');
        require(
            !tokenUriInUse(tokenUri),
                'This token uri is already in use'
        );
        _tokenUriInUse[keccak256(abi.encode(tokenUri))] = true;
        _mintingRecordsNumber ++;
        _mintingRecords[_mintingRecordsNumber].owner = msg.sender;
        _mintingRecords[_mintingRecordsNumber].tokenUri = tokenUri;
        _mintingRecords[_mintingRecordsNumber].price = price;

        _userMintingRecordsNumber[msg.sender] ++;
        _userMintingRecordIds[msg.sender][_userMintingRecordsNumber[msg.sender]] = _mintingRecordsNumber;

        emit NewMintingRecord (
            _mintingRecordsNumber,
            price,
            msg.sender,
            tokenUri
        );
        return true;
    }

    /**
    * @dev Cancel minting record
    */
    function cancelMintingRecord (
        uint256 mintingRecordId
    ) external hasRole('manager') returns (bool) {
        require(
            _mintingRecords[mintingRecordId].price > 0,
                'Minting record does not exists'
        );
        require(
            _mintingRecords[mintingRecordId].cancelled == 0,
                'This minting record is already cancelled'
        );
        require(
            _mintingRecords[mintingRecordId].completed == 0,
                'This minting record is already completed'
        );

        _tokenUriInUse[keccak256(abi.encode(
            _mintingRecords[mintingRecordId].tokenUri
        ))] = false;
        _mintingRecords[mintingRecordId].cancelled = block.timestamp;
        emit MintingRecordCompleted (
            mintingRecordId,
            address(0)
        );
        return true;
    }

    /**
    * @dev Accept minting record
    */
    function acceptMintingRecord (
        uint256 mintingRecordId
    ) external hasRole('manager') returns (bool) {
        require(
            _mintingRecords[mintingRecordId].price > 0,
                'Minting record does not exists'
        );
        require(
            _mintingRecords[mintingRecordId].cancelled == 0,
                'This minting record is already cancelled'
        );
        require(
            _mintingRecords[mintingRecordId].accepted == 0,
                'This minting record is already accepted'
        );

        _mintingRecords[mintingRecordId].accepted = block.timestamp;
        emit MintingRecordAccepted (
            mintingRecordId
        );
        return true;
    }

    /**
    * @dev Pay for minting NFT
    */
    function getNft (uint256 mintingRecordId) external returns (bool) {
        require (mintingRecordIsActive(mintingRecordId), 'This minting record is not active');
        uint256 amount = _mintingRecords[mintingRecordId].price;
        require(
            _paymentToken.transferFrom(msg.sender, address(this), amount),
                'Token transfer to the contract failed'
        );
        _nftToken.mint(
            msg.sender,
            _mintingRecords[mintingRecordId].tokenUri
        );
        uint256 feeAmount = amount * _fee / 100;
        uint256 paymentAmount = amount - feeAmount;
        require(_paymentToken.transfer(_feeReceiver, feeAmount));
        require(_paymentToken.transfer(_mintingRecords[mintingRecordId].owner, paymentAmount));
        _mintingRecords[mintingRecordId].buyer = msg.sender;
        _mintingRecords[mintingRecordId].completed = block.timestamp;
        emit MintingRecordCompleted (
            mintingRecordId,
            msg.sender
        );
        return true;
    }

    /**
    * @dev return lots number
    */
    function getMintingRecordsNumber () external view returns (uint256) {
        return _mintingRecordsNumber;
    }

    /**
    * @dev return log data
    */
    function getMintingRecordData (uint256 mintingRecordId) external view returns (
        uint256 price,
        uint256 accepted,
        uint256 completed,
        uint256 cancelled,
        address owner,
        address buyer,
        string memory tokenUri
    ) {
        return (
            _mintingRecords[mintingRecordId].price,
            _mintingRecords[mintingRecordId].accepted,
            _mintingRecords[mintingRecordId].completed,
            _mintingRecords[mintingRecordId].cancelled,
            _mintingRecords[mintingRecordId].owner,
            _mintingRecords[mintingRecordId].buyer,
            _mintingRecords[mintingRecordId].tokenUri
        );
    }

    /**
    * @dev return user's lots number
    */
    function getUserMintingRecordsNumber (address userAddress) external view returns (uint256) {
        return _userMintingRecordsNumber[userAddress];
    }

    /**
    * @dev return user lot id by index
    */
    function getUserMintingRecordId (
        address userAddress,
        uint256 index
    ) external view returns (uint256) {
        return _userMintingRecordIds[userAddress][index];
    }

    function mintingRecordIsActive (uint256 mintingRecordId) public view returns (bool) {
        return _mintingRecords[mintingRecordId].completed == 0 &&
            _mintingRecords[mintingRecordId].accepted > 0 &&
            _mintingRecords[mintingRecordId].cancelled == 0;
    }

    function tokenUriInUse (
        string memory tokenUri
    ) public view returns (bool) {
        return _tokenUriInUse[keccak256(abi.encode(tokenUri))]
            || _nftToken.tokenIdByTokenUri(tokenUri) > 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

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
pragma solidity 0.8.2;
import './Storage.sol';

/**
 * @dev Access control contract,
 * functions names are self explanatory
 */
contract ProxyAccessControl is Storage {
    modifier onlyOwner() {
        require(msg.sender == _owner, 'Caller is not the owner');
        _;
    }
    modifier hasRole(string memory role) {
        require(checkRole(role, msg.sender), 'Caller is not authorized');
        _;
    }

    constructor () {
        _owner = msg.sender;
    }

    // admin functions
    function transferOwnership(address newOwner) public onlyOwner returns (bool) {
        require(newOwner != address(0), 'newOwner should not be zero address');
        _owner = newOwner;
        return true;
    }

    function addRole (
        string memory role,
        address userAddress
    ) public onlyOwner returns (bool) {
        _roles[keccak256(abi.encode(role))][userAddress] = true;
        return true;
    }

    function revokeRole (
        string memory role,
        address userAddress
    ) public onlyOwner returns (bool) {
        _roles[keccak256(abi.encode(role))][userAddress] = false;
        return true;
    }

    function checkRole (
        string memory role,
        address userAddress
    ) public view returns (bool) {
        return _roles[keccak256(abi.encode(role))][userAddress];
    }

    /**
     * @dev Owner address getter
     */
    function owner() public view returns (address) {
        return _owner;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import '@openzeppelin/contracts/token/ERC721/IERC721.sol';
import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

interface IERC721Token is IERC721 {
    function mint (
        address to,
        string calldata tokenURI
    ) external returns (bool);
    function tokenIdByTokenUri (
        string calldata tokenUri
    ) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

/**
 * @title Auction contract
 * @dev Auction contract for ERC721 token lots
 */
contract Storage {
    struct Lot { // auction is over if timestamp > endTime or lastBid > 0 && lastBid == singlePaymentValue
        uint256 tokenId; // ERC721 token id for the current lot
        uint256 startTime; // start time
        uint256 endTime; // start time
        uint256 step; // minimal diff between last bid and a new bid
        uint256 startBid; // minimal value for a first bid
        uint256 lastBid; // value of the last bid, zero at the beginning
        uint256 lastBidTime; // timestamp of the last bid, zero at the beginning
        uint256 singlePaymentValue; // Value of a single payment for buying at once
        uint256 completed; // timestamp when seller received payment or get back nft
        address lastBidSender; // address of the last bid sender
        address owner; // address of the lot owner
    }
    struct SaleRecord { // fixed price record
        uint256 tokenId; // ERC721 token id for the current record
        uint256 price; // ERC721 token price
        uint256 completed; // timestamp when seller received payment or get back nft
        address owner; // address of the record owner
        address buyer; // address of the buyer
    }
    struct MintingRecord { // fixed price record
        uint256 price; // ERC721 token price
        uint256 accepted; // timestamp when admin accepts record
        uint256 completed; // timestamp when nft is minted and seller received payment
        uint256 cancelled; // timestamp when manager cancel record
        address owner; // address of the record owner
        address buyer; // address of the buyer
        string tokenUri; // ERC721 token uri
    }

    // variables order should not be changed ever when used with proxy
    uint8 internal _fee; // in percents

    // lot data storage
    uint256 internal _lotsNumber;
    mapping (uint256 => Lot) internal _lots; // lot data storage
    mapping (address => uint256) internal _userLotsNumber;
    mapping (address => mapping (uint256 => uint256)) internal _userLotIds;

    // fixed sale data storage
    uint256 internal _saleRecordsNumber;
    mapping (uint256 => SaleRecord) internal _saleRecords; // lot data storage
    mapping (address => uint256) internal _userSaleRecordsNumber;
    mapping (address => mapping (uint256 => uint256)) internal _userSaleRecordIds;

    // minting data storage
    uint256 internal _mintingRecordsNumber;
    mapping (uint256 => MintingRecord) internal _mintingRecords; // lot data storage
    mapping (address => uint256) internal _userMintingRecordsNumber;
    mapping (address => mapping (uint256 => uint256)) internal _userMintingRecordIds;
    mapping (bytes32 => bool) internal _tokenUriInUse;

    // access control storage
    mapping (bytes32 => mapping (address => bool)) internal _roles;
    address internal _owner;

    // settings storage
    IERC20 internal _paymentToken;
    IERC721Token internal _nftToken;
    address _feeReceiver;
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