// SPDX-License-Identifier: Unlicense
// moved from https://github.com/museum-of-war/auction
pragma solidity 0.8.15;

import "IERC721.sol";
import "IERC721Receiver.sol";
import "IERC1155.sol";
import "IERC1155Receiver.sol";
import "Ownable.sol";
import "IWithBalance.sol";

/// @title A Seller Contract for selling single or multiple ERC721 or ERC1155 tokens (modified version of NFTSeller)
/// @notice This contract can be used for selling any ERC721 and ERC1155 tokens
contract NFTSellerV2 is Ownable, IERC721Receiver, IERC1155Receiver {
    address[] public whitelistedPassCollections; //Only owners of tokens from any of these collections can buy if is onlyWhitelisted
    mapping(address => Sale) public nftContractSales;
    mapping(address => uint256) failedTransferCredits;
    //Each Sale is unique to each collection (smart contract).
    struct Sale {
        //map contract address to
        uint64 saleStart;
        uint64 saleEnd;
        uint128 price;
        address feeRecipient;
        bool onlyWhitelisted; // if true, than only owners of whitelistedPassCollections can buy tokens
        bool isERC1155;
    }

    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘           EVENTS            в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/

    event NftSaleCreated(
        address indexed nftContractAddress,
        uint128 price,
        uint64 saleStart,
        uint64 saleEnd,
        address feeRecipient,
        bool onlyWhitelisted,
        bool isERC1155
    );

    event NftSaleTokenAdded(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint256 amount
    );

    event TokenTransferredAndSellerPaid(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint256 amount,
        uint128 value,
        address buyer
    );

    event TokenSaleWithdrawn(
        address indexed nftContractAddress,
        uint256 indexed tokenId,
        uint256 amount
    );

    event TokensSaleClosed(
        address indexed nftContractAddress
    );
    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END             в•‘
      в•‘            EVENTS           в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘          MODIFIERS          в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/

    modifier needWhitelistedToken(address _nftContractAddress) {
        if (nftContractSales[_nftContractAddress].onlyWhitelisted) {
            bool isWhitelisted;
            for (uint256 i = 0; i < whitelistedPassCollections.length; i++) {
                if(IWithBalance(whitelistedPassCollections[i]).balanceOf(msg.sender) > 0) {
                    isWhitelisted = true;
                    break;
                }
            }
            require(isWhitelisted, "Sender has no whitelisted NFTs");
        }
        _;
    }

    modifier saleExists(address _nftContractAddress) {
        address _feeRecipient = nftContractSales[_nftContractAddress].feeRecipient;
        require(_feeRecipient != address(0), "Sale does not exist");
        _;
    }

    modifier saleOngoing(address _nftContractAddress) {
        require(
            _isSaleStarted(_nftContractAddress),
            "Sale has not started"
        );
        require(
            _isSaleOngoing(_nftContractAddress),
            "Sale has ended"
        );
        _;
    }

    modifier notZeroAddress(address _address) {
        require(_address != address(0), "Cannot specify 0 address");
        _;
    }

    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END             в•‘
      в•‘          MODIFIERS          в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/
    // constructor
    constructor(address[] memory _whitelistedPassCollectionsAddresses) {
        uint256 collectionsCount = _whitelistedPassCollectionsAddresses.length;
        for (uint256 i = 0; i < collectionsCount; i++) {
            whitelistedPassCollections.push(_whitelistedPassCollectionsAddresses[i]);
        }
    }
    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘     RECEIVERS FUNCTIONS      в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external virtual saleExists(msg.sender) returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] calldata,
        uint256[] calldata,
        bytes calldata
    ) external virtual saleExists(msg.sender) returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external virtual saleExists(msg.sender) returns (bytes4) {
        return this.onERC721Received.selector;
    }

    function supportsInterface(bytes4 interfaceId) external view virtual returns (bool) {
        return
        interfaceId == type(IERC1155Receiver).interfaceId ||
        interfaceId == type(IERC721Receiver).interfaceId;
    }
    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END              в•‘
      в•‘     RECEIVERS FUNCTIONS      в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘     WHITELIST FUNCTIONS      в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /*
     * Add whitelisted pass collection.
     */
    function addWhitelistedCollection(address _collectionContractAddress)
    external
    onlyOwner
    {
        whitelistedPassCollections.push(_collectionContractAddress);
    }

    /*
     * Remove whitelisted pass collection by index.
     */
    function removeWhitelistedCollection(uint256 index)
    external
    onlyOwner
    {
        whitelistedPassCollections[index] = whitelistedPassCollections[whitelistedPassCollections.length - 1];
        whitelistedPassCollections.pop();
    }
    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END              в•‘
      в•‘     WHITELIST FUNCTIONS      в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘     SALE CHECK FUNCTIONS     в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    function _isSaleStarted(address _nftContractAddress)
    internal
    view
    returns (bool)
    {
        return (block.timestamp >= nftContractSales[_nftContractAddress].saleStart);
    }

    function _isSaleOngoing(address _nftContractAddress)
    internal
    view
    returns (bool)
    {
        uint64 saleEndTimestamp = nftContractSales[_nftContractAddress].saleEnd;
        //if the saleEnd is set to 0, the sale is on-going and doesn't have specified end.
        return (saleEndTimestamp == 0 || block.timestamp < saleEndTimestamp);
    }

    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END              в•‘
      в•‘     SALE CHECK FUNCTIONS     в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/

    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘         SALE CREATION        в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/

    function _createNewSale(
        address _nftContractAddress,
        uint64 _saleStart,
        uint64 _saleEnd,
        uint128 _price,
        address _feeRecipient,
        bool _onlyWhitelisted,
        bool _isERC1155
    )
    internal
    notZeroAddress(_feeRecipient)
    {
        require(_saleEnd >= _saleStart || _saleEnd == 0, "Sale end must be after the start");
        require(
            nftContractSales[_nftContractAddress].feeRecipient == address(0),
            "Sale is already created"
        );

        Sale memory sale; // creating the sale
        sale.saleStart = _saleStart;
        sale.saleEnd = _saleEnd;
        sale.price = _price;
        sale.feeRecipient = _feeRecipient;
        sale.onlyWhitelisted = _onlyWhitelisted;
        sale.isERC1155 = _isERC1155;

        nftContractSales[_nftContractAddress] = sale;

        emit NftSaleCreated(
            _nftContractAddress,
            _price,
            _saleStart,
            _saleEnd,
            _feeRecipient,
            _onlyWhitelisted,
            _isERC1155
        );
    }

    function createNewERC721Sales(
        address _nftContractAddress,
        uint256[] memory _tokenIds,
        uint64 _saleStart,
        uint64 _saleEnd,
        uint128 _price,
        address _feeRecipient,
        bool _onlyWhitelisted
    )
    external
    onlyOwner
    {
        _createNewSale(_nftContractAddress, _saleStart, _saleEnd, _price, _feeRecipient, _onlyWhitelisted, false);

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];

            // Sending the NFT to this contract
            if (IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender) {
                IERC721(_nftContractAddress).transferFrom(
                    msg.sender,
                    address(this),
                    _tokenId
                );

                emit NftSaleTokenAdded(
                    _nftContractAddress,
                    _tokenId,
                    1
                );
            }
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "NFT transfer failed"
            );
        }
    }

    function createNewERC1155Sales(
        address _nftContractAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _tokenAmounts,
        uint64 _saleStart,
        uint64 _saleEnd,
        uint128 _price,
        address _feeRecipient,
        bool _onlyWhitelisted
    )
    external
    onlyOwner
    {
        _createNewSale(_nftContractAddress, _saleStart, _saleEnd, _price, _feeRecipient, _onlyWhitelisted, true);

        IERC1155(_nftContractAddress).safeBatchTransferFrom(
            msg.sender,
            address(this),
            _tokenIds,
            _tokenAmounts,
            ""
        );

        for (uint256 i = 0; i < _tokenIds.length; i++) {
            uint256 _tokenId = _tokenIds[i];
            uint256 _amount = _tokenAmounts[i];
            emit NftSaleTokenAdded(
                _nftContractAddress,
                _tokenId,
                _amount
            );
        }
    }

    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END              в•‘
      в•‘         SALE CREATION        в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/

    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘        BUY FUNCTIONS        в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/

    /*
    * Buy tokens with ETH.
    */
    function buyTokens(
        address _nftContractAddress,
        uint256[] memory _tokenIds,
        uint256[] memory _amounts
    )
    external
    payable
    saleExists(_nftContractAddress)
    saleOngoing(_nftContractAddress)
    needWhitelistedToken(_nftContractAddress)
    {
        address _feeRecipient = nftContractSales[_nftContractAddress].feeRecipient;
        // attempt to send the funds to the recipient
        (bool success, ) = payable(_feeRecipient).call{ value: msg.value, gas: 20000 }("");
        // if it failed, update their credit balance so they can pull it later
        if (!success) failedTransferCredits[_feeRecipient] = failedTransferCredits[_feeRecipient] + msg.value;

        uint128 price = nftContractSales[_nftContractAddress].price;

        if (nftContractSales[_nftContractAddress].isERC1155) {
            uint128[] memory values = new uint128[](_amounts.length);
            uint256 totalAmount = 0;
            for (uint256 i = 0; i < _amounts.length; i++) {
                totalAmount += _amounts[i];
                values[i] = uint128(_amounts[i] * price);
            }
            require(msg.value >= totalAmount * price, "Not enough funds to buy tokens");
            IERC1155(_nftContractAddress).safeBatchTransferFrom(address(this), msg.sender, _tokenIds, _amounts, "");
            for (uint256 i = 0; i < _amounts.length; i++) {
                emit TokenTransferredAndSellerPaid(_nftContractAddress, _tokenIds[i], _amounts[i], values[i], msg.sender);
            }
        } else {
            require(_amounts.length == 0, "ERC721 tokens cannot have amount");
            require(msg.value >= _tokenIds.length * price, "Not enough funds to buy tokens");
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                uint256 _tokenId = _tokenIds[i];
                IERC721(_nftContractAddress).safeTransferFrom(address(this), msg.sender, _tokenId);

                emit TokenTransferredAndSellerPaid(_nftContractAddress, _tokenId, 1, price, msg.sender);
            }
        }
    }

    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END              в•‘
      в•‘        BUY FUNCTIONS         в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/

    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘           WITHDRAW           в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    function withdrawSales(address _nftContractAddress, uint256[] memory _tokenIds, uint256[] memory _amounts)
    external
    onlyOwner
    {
        if (nftContractSales[_nftContractAddress].isERC1155) {
            IERC1155(_nftContractAddress).safeBatchTransferFrom(address(this), owner(), _tokenIds, _amounts, "");
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                emit TokenSaleWithdrawn(_nftContractAddress, _tokenIds[i], _amounts[i]);
            }
        } else {
            require(_amounts.length == 0, "ERC721 tokens cannot have amount");
            for (uint256 i = 0; i < _tokenIds.length; i++) {
                uint256 _tokenId = _tokenIds[i];
                IERC721(_nftContractAddress).transferFrom(address(this), owner(), _tokenId);
                emit TokenSaleWithdrawn(_nftContractAddress, _tokenId, 1);
            }
        }
    }

    function closeSales(address _nftContractAddress)
    external
    onlyOwner
    {
        delete nftContractSales[_nftContractAddress];
        emit TokensSaleClosed(_nftContractAddress);
    }

    /*
     * If the transfer of a bid has failed, allow to reclaim amount later.
     */
    function withdrawAllFailedCreditsOf(address recipient) external {
        uint256 amount = failedTransferCredits[recipient];

        require(amount != 0, "no credits to withdraw");

        failedTransferCredits[recipient] = 0;

        (bool successfulWithdraw, ) = recipient.call{
        value: amount,
        gas: 20000
        }("");
        require(successfulWithdraw, "withdraw failed");
    }

    /**********************************/
    /*в•”в•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•—
      в•‘             END              в•‘
      в•‘           WITHDRAW           в•‘
      в•љв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ђв•ќ*/
    /**********************************/
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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
    function safeTransferFrom(address from, address to, uint256 tokenId) external;

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
    function safeTransferFrom(address from, address to, uint256 tokenId, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

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
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(address operator, address from, uint256 tokenId, bytes calldata data) external returns (bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

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
    event TransferBatch(address indexed operator, address indexed from, address indexed to, uint256[] ids, uint256[] values);

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
    function balanceOfBatch(address[] calldata accounts, uint256[] calldata ids) external view returns (uint256[] memory);

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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(address from, address to, uint256 id, uint256 amount, bytes calldata data) external;

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
    function safeBatchTransferFrom(address from, address to, uint256[] calldata ids, uint256[] calldata amounts, bytes calldata data) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "IERC165.sol";

/**
 * _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {

    /**
        @dev Handles the receipt of a single ERC1155 token type. This function is
        called at the end of a `safeTransferFrom` after the balance has been updated.
        To accept the transfer, this must return
        `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
        (i.e. 0xf23a6e61, or its own function selector).
        @param operator The address which initiated the transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param id The ID of the token being transferred
        @param value The amount of tokens being transferred
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
    */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    )
        external
        returns(bytes4);

    /**
        @dev Handles the receipt of a multiple ERC1155 token types. This function
        is called at the end of a `safeBatchTransferFrom` after the balances have
        been updated. To accept the transfer(s), this must return
        `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
        (i.e. 0xbc197c81, or its own function selector).
        @param operator The address which initiated the batch transfer (i.e. msg.sender)
        @param from The address which previously owned the token
        @param ids An array containing ids of each token being transferred (order and length must match values array)
        @param values An array containing amounts of each token being transferred (order and length must match ids array)
        @param data Additional data with no specified format
        @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
    */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    )
        external
        returns(bytes4);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "Context.sol";
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
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

/*
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
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IWithBalance {
    function balanceOf(address owner) external view returns (uint256);
}