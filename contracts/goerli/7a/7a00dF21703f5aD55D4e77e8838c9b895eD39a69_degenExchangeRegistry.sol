// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;
//  Libraries
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
//  Utilities
import "./utils/gasManager.sol";
//  Security
import "@openzeppelin/contracts/access/Ownable.sol";
import "./utils/addressControl.sol";
//  Interfaces
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
//  Interface Receiver's
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
//  Base Contract
import "./base/XchangeBase.sol";

/**
 *
 *               NYLON Blocks : Xchange standard degenXchange Mother Contract
 *               Version 0.2.0a
 *
 *   @notice    -   Public facing functions for the Xchange
 *
 *   @dev       -   We are added '1' to counting vars to save gas w ith removing >=/<=
 *
 *
 *             ███╗░░██╗██╗░░░██╗██╗░░░░░░█████╗░███╗░░██╗
 *             ████╗░██║╚██╗░██╔╝██║░░░░░██╔══██╗████╗░██║
 *             ██╔██╗██║░╚████╔╝░██║░░░░░██║░░██║██╔██╗██║
 *             ██║╚████║░░╚██╔╝░░██║░░░░░██║░░██║██║╚████║
 *             ██║░╚███║░░░██║░░░███████╗╚█████╔╝██║░╚███║
 *             ╚═╝░░╚══╝░░░╚═╝░░░╚══════╝░╚════╝░╚═╝░░╚══╝
 *                www.nylonblocks.io | nylonblocks.eth
 */
contract degenExchangeRegistry is XchangeBase, GasManager {
    constructor(
        uint64 subscriptionId_,
        address vrfCoordinator_,
        address feeWallet_,
        ISwapRouter routerAddress_,
        address chainLinkToken_,
        address wethToken_,
        bytes memory VRFsubscriptionId_,
        uint256 maxGasPrice_
    )
        XchangeBase(
            subscriptionId_,
            vrfCoordinator_,
            feeWallet_,
            routerAddress_,
            chainLinkToken_,
            wethToken_,
            VRFsubscriptionId_
        )
        GasManager(maxGasPrice_)
    {}

    modifier addressHasDraws() override {
        require(
            _userDepositCount[_msgSender()] > 0,
            "Need to deposit an NFT in order to draw a new one."
        );
        _;
    }

    modifier activeNFTCount() override {
        require(
            _getAvailableNFTsInDraw() > MINIMAL_TOKENS_FOR_DRAW,
            "Not Enough NFTs in the vault to draw"
        );
        _;
    }

    modifier isPaused() override {
        require(
            !_checkPausedStatus(),
            "Sorry the draw is paused at the moment"
        );
        _;
    }

    /**
     *           Deposit functions
     */
    function enterNFTDraw(
        address addressForNFTContract_,
        uint256 tokenId_,
        bytes4 interfaceId_
    ) public payable override isPaused {
        require(msg.value == _getDrawFee(), "Need to include the deposit fee");
        require(
            _userDepositCount[_msgSender()] < MAX_CONCURRENT_ENTRIES_PER_WALLET,
            "Max entries per wallet reached"
        );
        require(_acceptedInterface(interfaceId_), "Only accepts ERC721 & 1155");
        require(
            _checkAddress(addressForNFTContract_),
            "Thats not a contract Address"
        );

        _enterNFTDraw(addressForNFTContract_, tokenId_, interfaceId_);
    }

    /**
     *       @notice -   THIS FUNCTION IS ONE WAY. YOU DO NOT GET A DRAW FOR SUBMITTING
     *                   Used for entering an NFT to the pool but not receiving a draw entry
     *                   Made for NFT projects to build their community
     */
    function submitNFT(
        address addressForNFTContract_,
        uint256 tokenId_,
        bytes4 interfaceId_
    ) public override isPaused {
        require(_acceptedInterface(interfaceId_), "Only accepts ERC721 & 1155");
        require(
            _checkAddress(addressForNFTContract_),
            "Thats not a contract Address"
        );
        _submitNFT(addressForNFTContract_, tokenId_, interfaceId_);
    }

    /**
     *           @dev   -   Draw functions
     */
    function triggerDraw()
        public
        override
        addressHasDraws
        activeNFTCount
        isPaused
        gasManager
    {
        _triggerDraw();
    }

    function supportsInterface(bytes4 interfaceId_)
        public
        view
        virtual
        override
        returns (bool)
    {
        return
            interfaceId_ == type(IERC1155).interfaceId ||
            interfaceId_ == type(IERC721).interfaceId ||
            super.supportsInterface(interfaceId_);
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords)
        internal
        override
    {
        _fulfillRandomWords(requestId, randomWords);
    }

    /**
     *       ONLY FOR DEVELOPMENT
     *       This will be replaced with a direct submission function to buy link and submit to the VRN service
     */

    function removeETH(address payable to_, uint256 amount_) public onlyOwner {
        require(address(this).balance > amount_, "Remove ETH: Balance to low");
        payable(to_).transfer(amount_);
    }

    function removeNFTEntryFromDraw(uint256 NFTIndex_, string memory reason_)
        public
        override
        onlyOwner
    {
        _removeNFTEntryFromDraw(NFTIndex_, reason_);
    }

    /**
     *          @dev    -   Setters
     */

    function setDrawPaused() public override onlyOwner {
        _setDrawPaused();
    }

    function setDrawFee(uint256 amount_) public onlyOwner {
        _setDrawFee(amount_);
    }

    /**
     *           @dev   -   Getters
     */
    function getAllTokensInDraw() public view returns (TokenData[] memory) {
        return _getAllTokensInDraw();
    }

    function getNFTsDepositedCount() public view returns (uint256) {
        return _getNFTsDepositedCount();
    }

    function getDrawFee() public view returns (uint256) {
        return _getDrawFee();
    }

    function getAvailableNFTsInDraw() public view returns (uint256) {
        return _getAvailableNFTsInDraw();
    }

    function getTotalDrawsHappened() public view returns (uint256) {
        return _getTotalDrawsHappened();
    }

    function getAddressRemainingPlays(address playersAddress_)
        public
        view
        returns (uint256)
    {
        return _getAddressRemainingPlays(playersAddress_);
    }

    function getMaxEntriesPerWallet() public pure returns (uint256) {
        return _getMaxEntriesPerWallet();
    }

    function getPendingDrawCount() public view returns (uint256) {
        return _getPendingDrawCount();
    }

    function getCallbackGasLimit() public view returns (uint256) {
        return _getCallbackGasLimit();
    }

    function checkPausedStatus() public view returns (bool) {
        return _checkPausedStatus();
    }

    /**
     *          @dev    -   Random Numbers
     */
    function setNewVRFInfo(uint64 subscriptionId_, bytes32 keyHash_)
        public
        override
        onlyOwner
    {
        _setNewVRFInfo(subscriptionId_, keyHash_);
    }

    function setCallbackGasLimit(uint32 newGaslimit_)
        public
        override
        onlyOwner
    {
        _setCallbackGasLimit(newGaslimit_);
    }

    function getVRFInfo()
        public
        view
        override
        returns (
            uint64,
            bytes32,
            uint32
        )
    {
        return _getVRFInfo();
    }

    /**
     *          @dev    -   Gas Manager Functions
     */
    function gasManagerIsActive() public view override returns (bool active_) {
        return _gasManagerIsActive();
    }

    function getGasManagerMaxGas()
        public
        view
        override
        returns (uint256 maxGasInWei_)
    {
        return _getGasManagerMaxGas();
    }

    function setGasManagerActive() public override onlyOwner {
        _setGasManagerActive();
    }

    function setGasManagerMaxCost(uint256 maxGasInWei_)
        public
        override
        onlyOwner
    {
        _setGasManagerMaxCost(maxGasInWei_);
    }

    /**
     *          @dev    -   Link Funder
     */
    function exchangeAllEthAndFund() public override onlyOwner {
        _exchangeAllEthAndFund();
    }

    function exchangeEthAmountAndFund(uint256 amount_)
        public
        override
        onlyOwner
    {
        _exchangeEthAmountAndFund(amount_);
    }

    function exchangeAllWEthAndFund() public override onlyOwner {
        _exchangeAllWethAndFund();
    }

    receive() external payable override(IFundLINKSubscription) {}

    function fundWithLink(uint256 linkAmount_) public override onlyOwner {
        require(
            linkAmount_ < _getLinkBalance(),
            "Contract Link Balance Too low"
        );

        _fundSubscription(linkAmount_);
    }

    function setSplitAmount(uint8 newSplit_) public override onlyOwner {
        _setSplitAmount(newSplit_);
    }

    function getSplitAmount() public view returns (uint8) {
        return _getBalanceSplitAmount();
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "../interfaces/IGasManager.sol";

abstract contract GasManager is IGasManager {
    uint256 private _maxGasPrice;
    bool private _gasManagerActive = true;

    constructor(uint256 gasLimitWei_) {
        _maxGasPrice = gasLimitWei_;
    }

    modifier gasManager() override {
        if (_gasManagerActive) require(tx.gasprice < _maxGasPrice, "GasManager: Gas to high");
        _;
    }

    function _gasManagerIsActive() internal view returns (bool active_) {
        return _gasManagerActive;
    }

    function _getGasManagerMaxGas()
        internal
        view
        returns (uint256 maxGasInWei_)
    {
        return _maxGasPrice;
    }

    function _setGasManagerActive() internal {
        _gasManagerActive = _gasManagerActive ? false : true;
        emit GasManagerActivationChange(_gasManagerActive);
    }

    function _setGasManagerMaxCost(uint256 maxGasInWei_) internal {
        _maxGasPrice = maxGasInWei_;
        emit GasPriceAcceptanceChanged(maxGasInWei_);
    }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

//  Libraries
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
//  Utilities
import "../utils/randomNumber.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";
//  Security
import "@openzeppelin/contracts/access/Ownable.sol";
//  Interfaces
import "../interfaces/IXchange.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

/**
 *   @note    -   IERC721 interfaceId - 0x80ac58cd
 *   @note    -   IERC1155 interfaceId - 0xd9b67a26
 *
 */
/**
 *
 *               NYLON Blocks : degenXchange Base Contract
 *               Version 0.2.0a
 *
 *   @notice    -   Holds all logic for the Xchange protocol
 *   @notice    -   Using ChainLink VRF for random numbers
 *
 *
 *   @dev       -   We are added '1' to counting vars to save gas w ith removing >=/<=
 *
 *
 *             ███╗░░██╗██╗░░░██╗██╗░░░░░░█████╗░███╗░░██╗
 *             ████╗░██║╚██╗░██╔╝██║░░░░░██╔══██╗████╗░██║
 *             ██╔██╗██║░╚████╔╝░██║░░░░░██║░░██║██╔██╗██║
 *             ██║╚████║░░╚██╔╝░░██║░░░░░██║░░██║██║╚████║
 *             ██║░╚███║░░░██║░░░███████╗╚█████╔╝██║░╚███║
 *             ╚═╝░░╚══╝░░░╚═╝░░░╚══════╝░╚════╝░╚═╝░░╚══╝
 *                www.nylonblocks.io | nylonblocks.eth
 */
abstract contract XchangeBase is RandomNumber, ERC165, IXchange, Ownable {
    using Address for address;
    using Strings for uint256;

    TokenData[] private _tokensInDraw;

    address immutable FEE_PAYABLE_ADDRESS;

    uint256 constant MINIMAL_TOKENS_FOR_DRAW = 2; //  +1 for actual number (3)
    uint256 constant MAX_CONCURRENT_ENTRIES_PER_WALLET = 1;

    uint256 internal _depositFee = 0.002 ether;
    uint256 private _depositCount = 0;
    uint256 private _drawCount = 0;

    bool internal _drawPaused = false;

    mapping(address => uint32) private _addressActiveDeposits;
    uint8 private _maxPoolControl = 50;

    //  Draws in cue
    //  Mapping of requestIds to Draw trigger address
    uint256 private _DrawsInLine = 0;
    mapping(uint256 => address) internal _requestIdToDrawerAddress;
    // TODO could be _drawIdToRequestId
    //  Mapping of requestIds to DrawId
    mapping(uint256 => uint256) internal _drawTriggers;
    //  Mapping of amount of draws to spend to wallet address
    mapping(address => uint256) internal _userDepositCount;
    mapping(uint256 => uint256) private _DrawIdToVRN;
    // Mapping to check if drawId is complete
    mapping(uint256 => bool) private _completeDraws;

    constructor(
        uint64 subscriptionId_,
        address vrfCoordinator_,
        address feeWallet_,
        ISwapRouter routerAddress_,
        address chainLinkToken_,
        address wethToken_,
        bytes memory VRFsubscriptionId_
    )
        RandomNumber(
            subscriptionId_,
            vrfCoordinator_,
            _keyHash,
            1,
            routerAddress_,
            chainLinkToken_,
            wethToken_,
            VRFsubscriptionId_
        )
    {
        FEE_PAYABLE_ADDRESS = feeWallet_;

        // Add an empty entry to the array to fill index 0
        unchecked {
            TokenData memory zeroToken;
            zeroToken.contractOfToken = address(0x0);
            zeroToken.ownerAddress = address(0x0);
            zeroToken.tokenId = 0;
            _tokensInDraw.push(zeroToken);
        }
    }

    modifier isUserBeingControlling() {
        require(
            _addressActiveDeposits[_msgSender()] <
                ((_getNFTsDepositedCount() / 100) * _maxPoolControl),
            "Your being greedy! Think your a whale? You cant have that many deposits"
        );
        _;
    }

    /**
     *           Deposit functions
     */
    function _enterNFTDraw(
        address addressForNFTContract_,
        uint256 tokenId_,
        bytes4 interfaceId_
    ) internal {
        _switchTransferInterface(
            addressForNFTContract_,
            tokenId_,
            interfaceId_,
            1,
            _msgSender()
        );

        unchecked {
            TokenData memory newEntry = TokenData(
                tokenId_,
                addressForNFTContract_,
                interfaceId_,
                false,
                _msgSender(),
                address(0x0)
            );
            // TODO is this possible? _tokensInDraw.push(TokenData({contractOfToken: addressForNFTContract_, ownerAddress: _msgSender(), interfaceId: interfaceId_, tokenId: tokenId_, gifted: false, gifter: address(0x0)}));
            _tokensInDraw.push(newEntry);
            _userDepositCount[_msgSender()]++;
            _depositCount++;
        }

        _addressActiveDeposits[_msgSender()]++;

        emit DepositedNFT(_msgSender(), addressForNFTContract_, tokenId_);
    }

    /**
     *       @notice -   THIS FUNCTION IS ONE WAY. YOU DO NOT GET A DRAW FOR SUBMITTING
     *                   Used for entering an NFT to the pool but not receiving a draw entry
     *                   Made for NFT projects to build their community
     */
    function _submitNFT(
        address addressForNFTContract_,
        uint256 tokenId_,
        bytes4 interfaceId_
    ) internal {
        _switchTransferInterface(
            addressForNFTContract_,
            tokenId_,
            interfaceId_,
            1,
            _msgSender()
        );

        TokenData memory newEntry = TokenData(
            tokenId_,
            addressForNFTContract_,
            interfaceId_,
            true,
            address(0x0),
            _msgSender()
        );

        _tokensInDraw.push(newEntry);
        _userDepositCount[address(0x0)]++;
        _depositCount++;

        emit GiftedNFT(_msgSender(), addressForNFTContract_, tokenId_);
    }

    /**
     *          @dev -  Draw functions
     */
    function _triggerDraw() internal {
        uint256 requestId = _requestRandomNumbers();
        if (requestId > 0) {
            address requester_ = _msgSender();
            _drawCount++;
            _requestIdToDrawerAddress[requestId] = requester_;
            _DrawsInLine++;
            _drawTriggers[requestId] = _drawCount;
            _userDepositCount[_requestIdToDrawerAddress[requestId]]--;
        } else {
            revert FailedToRequestRandomNumbers(requestId);
        }
        emit DrawInitiated(_msgSender(), _drawCount);
    }

    /**
     *          @dev -  Random numbers return
     */

    function _fulfillRandomWords(
        uint256 requestId,
        uint256[] memory randomWords
    ) internal {
        // TODO can be these requires be at the top to cancel out newNumber creation?
        //          @raymondchooi they could, but i was trying to catch all incoming data to store it
        require(
            _requestIdToDrawerAddress[requestId] ==
                address(_requestIdToDrawerAddress[requestId]),
            "Request ID Not found"
        );
        require(
            !_completeDraws[_drawTriggers[requestId]],
            "Draw has already been completed"
        );

        _DrawIdToVRN[_drawTriggers[requestId]] = randomWords[0];
        _fulfillFinalDraw(randomWords[0], requestId);
    }

    function _fulfillFinalDraw(uint256 returnedNumber_, uint256 requestId_)
        internal
    {
        uint256 roll = returnedNumber_ % _getNFTsDepositedCount();

        unchecked {
            address drawerAddress = _requestIdToDrawerAddress[requestId_];
            uint256 originalRoll = roll;
            bool topReached;
            bool isAllChecked;

            if (roll < 1) roll++;
            while (
                _tokensInDraw[roll].ownerAddress == drawerAddress ||
                !isAllChecked
            ) {
                if (topReached) {
                    roll--;
                    if (roll < 1) isAllChecked = true;
                    roll = originalRoll;
                } else if (roll + 1 > _getNFTsDepositedCount()) {
                    roll = originalRoll;
                    topReached = true;
                } else roll++;
            }
        }

        TokenData storage drawnToken = _tokensInDraw[roll];
        _switchTransferInterface(
            drawnToken.contractOfToken,
            drawnToken.tokenId,
            drawnToken.interfaceId,
            0,
            _requestIdToDrawerAddress[requestId_]
        );
        _removeNFTFromDrawArray(roll);

        _depositCount--;
        _DrawsInLine--;

        _addressActiveDeposits[drawnToken.ownerAddress]--;

        _completeDraws[_drawTriggers[requestId_]] = true;
        emit DrawComplete(
            _requestIdToDrawerAddress[requestId_],
            drawnToken.contractOfToken,
            drawnToken.tokenId,
            _drawTriggers[requestId_]
        );
    }

    /**
     *       @dev -   NFT management
     */

    function _removeNFTEntryFromDraw(uint256 NFTIndex_, string memory reason_)
        internal
    {
        TokenData storage toRemove = _tokensInDraw[NFTIndex_];

        address returnAddress = toRemove.gifted
            ? toRemove.gifter
            : toRemove.ownerAddress;

        _switchTransferInterface(
            toRemove.contractOfToken,
            toRemove.tokenId,
            toRemove.interfaceId,
            0,
            returnAddress
        );
        _addressActiveDeposits[toRemove.ownerAddress]--;
        _removeNFTFromDrawArray(NFTIndex_);
        _userDepositCount[toRemove.ownerAddress]--;
        _depositCount--;
        emit ForceRemoveNFT(
            toRemove.ownerAddress,
            toRemove.contractOfToken,
            toRemove.tokenId,
            reason_
        );
    }

    function _removeNFTFromDrawArray(uint256 index_) private {
        if (index_ > _tokensInDraw.length) return;
        else if (index_ == _tokensInDraw.length || _tokensInDraw.length < 3)
            _tokensInDraw.pop();
        else {
            unchecked {
                _tokensInDraw[index_] = _tokensInDraw[_tokensInDraw.length - 1];
                _tokensInDraw.pop();
            }
        }
    }

    /**
     *     @dev -       Transferring in & iut
     *      @notice    -   1 = in && 0 = out
     */

    function _switchTransferInterface(
        address addressForNFTContract_,
        uint256 tokenId_,
        bytes4 interfaceId_,
        uint256 inOrOut_,
        address receiver_
    ) private {
        if (interfaceId_ == type(IERC721).interfaceId) {
            if (inOrOut_ > 0) {
                _transferInERC721(addressForNFTContract_, tokenId_);
            } else {
                _transferOutERC721(addressForNFTContract_, tokenId_, receiver_);
            }
            return;
        }
        if (interfaceId_ == type(IERC1155).interfaceId) {
            if (inOrOut_ > 0) {
                _transferInERC1155(addressForNFTContract_, tokenId_);
            } else {
                _transferOutERC1155(
                    addressForNFTContract_,
                    tokenId_,
                    receiver_
                );
            }
            return;
        }
        revert InvalidContractInterface(interfaceId_);
    }

    function _transferInERC721(address addressForNFTContract_, uint256 tokenId_)
        private
    {
        IERC721(addressForNFTContract_).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenId_
        );
    }

    function _transferInERC1155(
        address addressForNFTContract_,
        uint256 tokenId_
    ) private {
        bytes memory data;
        IERC1155(addressForNFTContract_).safeTransferFrom(
            _msgSender(),
            address(this),
            tokenId_,
            1,
            data
        );
    }

    function _transferOutERC721(
        address addressForNFTContract_,
        uint256 tokenId_,
        address receiver_
    ) private {
        IERC721(addressForNFTContract_).safeTransferFrom(
            address(this),
            receiver_,
            tokenId_
        );
    }

    function _transferOutERC1155(
        address addressForNFTContract_,
        uint256 tokenId_,
        address receiver_
    ) private {
        bytes memory data;
        IERC1155(addressForNFTContract_).safeTransferFrom(
            address(this),
            receiver_,
            tokenId_,
            1,
            data
        );
    }

    /**
     *           Supported interfaces & token IO
     */

    function _acceptedInterface(bytes4 interfaceId_)
        internal
        pure
        returns (bool)
    {
        return
            interfaceId_ == type(IERC1155).interfaceId ||
            interfaceId_ == type(IERC721).interfaceId;
    }

    function _checkAddress(address address_) internal view returns (bool) {
        return address_.code.length > 0;
    }

    function onERC721Received(
        address operator_,
        address from_,
        uint256 tokenId_,
        bytes calldata data_
    ) external pure returns (bytes4) {
        return IERC721Receiver.onERC721Received.selector;
    }

    function onERC1155Received(
        address operator_,
        address from_,
        uint256 id_,
        uint256 value_,
        bytes calldata data_
    ) external pure returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

    /**
     *           @notice Setters
     */

    function _setDrawPaused() internal onlyOwner {
        _drawPaused ? _drawPaused = false : _drawPaused = true;
    }

    function _setDrawFee(uint256 amount_) internal onlyOwner {
        _depositFee = amount_;
    }

    /**
     *           Getters
     */
    function _getAllTokensInDraw() internal view returns (TokenData[] memory) {
        return _tokensInDraw;
    }

    function _getNFTsDepositedCount() internal view returns (uint256) {
        return _depositCount;
    }

    function _getDrawFee() internal view returns (uint256) {
        return _depositFee;
    }

    function _getAvailableNFTsInDraw() internal view returns (uint256) {
        return _getNFTsDepositedCount() - _DrawsInLine;
    }

    function _getTotalDrawsHappened() internal view returns (uint256) {
        return _drawCount;
    }

    function _getAddressRemainingPlays(address address_)
        internal
        view
        returns (uint256)
    {
        return _userDepositCount[address_];
    }

    function _getMaxEntriesPerWallet() internal pure returns (uint256) {
        return MAX_CONCURRENT_ENTRIES_PER_WALLET;
    }

    function _getPendingDrawCount() internal view returns (uint256) {
        return _DrawsInLine;
    }

    function _checkPausedStatus() internal view returns (bool) {
        return _drawPaused;
    }
}

pragma solidity >=0.4.22 <0.9.0;

//  Libraries
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
//  Security
import "@openzeppelin/contracts/access/Ownable.sol";
//  Interface
import "../interfaces/IAddressControl.sol";

abstract contract AddressControl is IAddressControl {
    using Address for address;

    uint256 internal _totalAcceptedAddresses;
    mapping(address => bool) internal _acceptedAddresses;
    mapping(address => bytes4) internal _acceptedAddressInterface;
    mapping(address => address) internal _projectContract;
    mapping(address => string) internal _projectName;

    modifier acceptedTokenAddress(address NFTAddress_) override {
        require(_checkAllowed(NFTAddress_), "Non-approved NFT Contract");
        _;
    }

    function _addAddress(
        address contractAddress_,
        bytes4 interfaceId_,
        string memory projectName_,
        address projectContact_
    ) internal {
        _acceptedAddressInterface[contractAddress_] = interfaceId_;
        _acceptedAddresses[contractAddress_] = true;
        _totalAcceptedAddresses++;
        _projectContract[contractAddress_] = projectContact_;
        _projectName[contractAddress_] = projectName_;
        emit AddressAdded(contractAddress_, interfaceId_, projectName_);
    }

    function _revokeAddress(address contractAddress_, string memory reason_)
        internal
    {
        _acceptedAddresses[contractAddress_] = false;
        _totalAcceptedAddresses--;
        emit AddressRevoked(contractAddress_, reason_);
    }

    function _checkAllowed(address contractAddress_)
        internal
        view
        returns (bool)
    {
        return _acceptedAddresses[contractAddress_];
    }

    function _getProjectName(address contractAddress_)
        internal
        view
        returns (string memory)
    {
        return _projectName[contractAddress_];
    }

    function _getProjectInterfaceId(address contractAddress_)
        internal
        view
        returns (bytes4)
    {
        return _acceptedAddressInterface[contractAddress_];
    }

    function _updateProjectName(
        address contractAddress_,
        string memory projectName_
    ) internal {
        _projectName[contractAddress_] = projectName_;
    }

    function _getContractContact(address contractAddress_)
        internal
        view
        returns (address)
    {
        return _projectContract[contractAddress_];
    }

    function _bulkAddAddress(SubmissionData[] memory inputData_) internal {
        for (uint256 i = 0; i < inputData_.length; i++) {
            _addAddress(
                inputData_[i].contractAddress,
                inputData_[i].interfaceId,
                inputData_[i].projectName,
                inputData_[i].projectContact
            );
        }
    }

    function _getAllowedProjectData(address contractAddress_)
        internal
        view
        acceptedTokenAddress(contractAddress_)
        returns (SubmissionData memory)
    {
        SubmissionData memory addressData;
        addressData.contractAddress = contractAddress_;
        addressData.interfaceId = _getProjectInterfaceId(contractAddress_);
        addressData.projectName = _getProjectName(contractAddress_);
        addressData.projectContact = _getContractContact(contractAddress_);
        return addressData;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165 is IERC165 {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165).interfaceId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
interface IGasManager {
    event GasPriceAcceptanceChanged(uint256 newGasPriceInWei_);
    event GasManagerActivationChange(bool active_);

    modifier gasManager() virtual;

    function gasManagerIsActive() external view returns(bool active_);
    function getGasManagerMaxGas() external view returns(uint256 maxGasInWei_);
    function setGasManagerActive() external;
    function setGasManagerMaxCost(uint256 maxGasInWei_) external;

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;
//  API
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";
import "./fundLINKSubscription.sol";
//  Interfaces
import "../interfaces/IRandomNumber.sol";

abstract contract RandomNumber is
    VRFConsumerBaseV2,
    FundLINKSubscription,
    IRandomNumber
{
    VRFCoordinatorV2Interface internal immutable COORDINATOR;

    //  Subscription Id
    //  Goerli coordinator
    //  The gas lane to use, which specifies the maximum gas price to bump to.
    //  Callback gas limit
    //  How many confirmations to wait for, min 3
    //  How many sets of random numbers
    uint64 internal _VRFsubscriptionId;
    bytes32 internal _keyHash =
        0x79d3d8832d904592c0bf9818b621522c988bb8b0c05cdc3b15aea1b6e8db0c15;
    uint32 internal _callbackGaslimit = 2500000;
    uint16 internal _minimumRequestConfirmations = 3;
    uint32 immutable _amountOfNumbersToRequest;

    constructor(
        uint64 VRFsubscriptionId_,
        address vrfCoordinator_,
        bytes32 keyHash_,
        uint32 amountOfNumbersToRequest_,
        ISwapRouter routerAddress_,
        address chainLinkToken_,
        address wethToken_,
        bytes memory VRFsubscriptionIdBytes_
    )
        VRFConsumerBaseV2(vrfCoordinator_)
        FundLINKSubscription(
            routerAddress_,
            chainLinkToken_,
            wethToken_,
            VRFsubscriptionIdBytes_,
            vrfCoordinator_
        )
    {
        COORDINATOR = VRFCoordinatorV2Interface(vrfCoordinator_);
        _VRFsubscriptionId = VRFsubscriptionId_;
        _keyHash = keyHash_;
        _amountOfNumbersToRequest = amountOfNumbersToRequest_;
    }

    function _requestRandomNumbers() internal returns (uint256 requestId_) {
        return
            COORDINATOR.requestRandomWords(
                _keyHash,
                _VRFsubscriptionId,
                _minimumRequestConfirmations,
                _callbackGaslimit,
                _amountOfNumbersToRequest
            );
    }

    /**
     *           @dev    -   Setters
     */
    function _setCallbackGasLimit(uint32 newGaslimit_) internal {
        _callbackGaslimit = newGaslimit_;
    }

    function _setNewVRFInfo(uint64 VRFsubscriptionId_, bytes32 keyHash_)
        internal
    {
        _VRFsubscriptionId = VRFsubscriptionId_;
        _keyHash = keyHash_;
        emit VRFDataChanged(VRFsubscriptionId_, keyHash_);
    }

    /**
     *           @dev    -   Getters
     */
    function _getVRFInfo()
        internal
        view
        returns (
            uint64,
            bytes32,
            uint32
        )
    {
        return (_VRFsubscriptionId, _keyHash, _callbackGaslimit);
    }

    function _getCallbackGasLimit() internal view returns (uint256) {
        return _callbackGaslimit;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IXchange {
    struct TokenData {
        uint256 tokenId;
        address contractOfToken;
        bytes4 interfaceId;
        bool gifted;
        address ownerAddress;
        address gifter;
    }
    //      Events
    event DrawComplete(
        address drawer_,
        address nftContractAddress_,
        uint256 tokenId_,
        uint256 drawId_
    );
    event DepositedNFT(
        address depositor_,
        address nftContractAddress_,
        uint256 tokenId_
    );
    event GiftedNFT(
        address depositor_,
        address nftContractAddress_,
        uint256 tokenId_
    );
    event DrawInitiated(address drawer_, uint256 drawId_);

    event ForceRemoveNFT(
        address depositor_,
        address nftContractAddress_,
        uint256 tokenId_,
        string reason_
    );


    //  Errors
    error InvalidContractInterface(bytes4 interfaceId_);
    error FailedToRequestRandomNumbers(uint256 requestId_);

    //  Modifiers
    modifier addressHasDraws() virtual;
    modifier activeNFTCount() virtual;
    modifier isPaused() virtual;

    //  Functions
    function enterNFTDraw(
        address addressForNFTContract_,
        uint256 tokenId_,
        bytes4 interfaceId_
    ) external payable;

    function submitNFT(
        address addressForNFTContract_,
        uint256 tokenId_,
        bytes4 interfaceId_
    ) external;

    function triggerDraw() external;

    function removeNFTEntryFromDraw(uint256 NFTIndex_, string memory reason_)
        external;

    function setDrawPaused() external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155Receiver is IERC165 {
    /**
     * @dev Handles the receipt of a single ERC1155 token type. This function is
     * called at the end of a `safeTransferFrom` after the balance has been updated.
     *
     * NOTE: To accept the transfer, this must return
     * `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`
     * (i.e. 0xf23a6e61, or its own function selector).
     *
     * @param operator The address which initiated the transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param id The ID of the token being transferred
     * @param value The amount of tokens being transferred
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))` if transfer is allowed
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    /**
     * @dev Handles the receipt of a multiple ERC1155 token types. This function
     * is called at the end of a `safeBatchTransferFrom` after the balances have
     * been updated.
     *
     * NOTE: To accept the transfer(s), this must return
     * `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`
     * (i.e. 0xbc197c81, or its own function selector).
     *
     * @param operator The address which initiated the batch transfer (i.e. msg.sender)
     * @param from The address which previously owned the token
     * @param ids An array containing ids of each token being transferred (order and length must match values array)
     * @param values An array containing amounts of each token being transferred (order and length must match ids array)
     * @param data Additional data with no specified format
     * @return `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))` if transfer is allowed
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
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
pragma solidity ^0.8.7;
//  APIs
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import "@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol";
//  Utilities
//  Security
import "@openzeppelin/contracts/access/Ownable.sol";
//  Interfaces
import "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "../interfaces/IFundLINKSubscription.sol";
import "../interfaces/IExtra.sol";

/**
 *
 *               NYLON Blocks : Fund LINK VRF Subscriber
 *               Version 0.2.0a
 *
 *   @notice    -   Provides function to fund LINK Subscriber
 *   @notice    -   ETH > WETH > LINK > Subscription
 *
 *
 *   @dev       -   We are added '1' to counting vars to save gas w ith removing >=/<=
 *
 *
 *             ███╗░░██╗██╗░░░██╗██╗░░░░░░█████╗░███╗░░██╗
 *             ████╗░██║╚██╗░██╔╝██║░░░░░██╔══██╗████╗░██║
 *             ██╔██╗██║░╚████╔╝░██║░░░░░██║░░██║██╔██╗██║
 *             ██║╚████║░░╚██╔╝░░██║░░░░░██║░░██║██║╚████║
 *             ██║░╚███║░░░██║░░░███████╗╚█████╔╝██║░╚███║
 *             ╚═╝░░╚══╝░░░╚═╝░░░╚══════╝░╚════╝░╚═╝░░╚══╝
 *                www.nylonblocks.io | nylonblocks.eth
 */
abstract contract FundLINKSubscription is IFundLINKSubscription {
    ISwapRouter public immutable SWAP_ROUTER;

    address public immutable CHAIN_LINK_TOKEN;
    address public immutable WETH_TOKEN;
    address public immutable VRF_COORDINATOR;

    bytes private _subscriptionId;
    uint8 private _balanceSplitAmount = 2; //50%
    uint24 private _feeTier = 3000;

    constructor(
        ISwapRouter routerAddress_,
        address chainLinkToken_,
        address wethToken_,
        bytes memory VRFsubscriptionId_,
        address VRFCoordinator_
    ) {
        SWAP_ROUTER = routerAddress_;
        CHAIN_LINK_TOKEN = chainLinkToken_;
        WETH_TOKEN = wethToken_;
        VRF_COORDINATOR = VRFCoordinator_;
        _subscriptionId = VRFsubscriptionId_;
    }

    /**
     *      @dev - Front end functions
     */

    function _exchangeAllEthAndFund() internal {
        uint256 amountInWei = address(this).balance / _getBalanceSplitAmount();
        require(
            amountInWei < address(this).balance,
            "Balance To Low for that amount"
        );

        uint256 Weth = _convertEthToWeth(amountInWei);
        _approveWeth(Weth);
        uint256 receivedLink = _swapWEthForLink(Weth);

        _fundSubscription(receivedLink);

        emit SubscriptionFunded(receivedLink, amountInWei, _getSubscriptionId());
    }

    function _exchangeEthAmountAndFund(uint256 amount_) internal {
        require(
            amount_ < address(this).balance,
            "Balance To Low for that amount"
        );

        uint256 Weth = _convertEthToWeth(amount_);
        _approveWeth(Weth);
        uint256 receivedLink = _swapWEthForLink(Weth);

        bool success = _fundSubscription(receivedLink);

        if (!success) revert FundLinkContractFailed();

        emit SubscriptionFunded(receivedLink, amount_, _getSubscriptionId());
    }

    function _exchangeAllWethAndFund() internal {
        uint256 weth = _getWethBalance();
        require(weth > 0, "WETH balance is to low");
        _approveWeth(weth);
        uint256 receivedLink = _swapWEthForLink(weth);

        bool success = _fundSubscription(receivedLink);

        if (!success) revert FundLinkContractFailed();

        emit SubscriptionFunded(receivedLink, weth, _getSubscriptionId());
    }

    /**
     *  @dev    -   Currency converters
     */

    function _convertEthToWeth(uint256 amount_) private returns (uint256) {
        IWETH(WETH_TOKEN).deposit{value: amount_}();
        return IERC20(WETH_TOKEN).balanceOf(address(this));
    }

    function _swapWEthForLink(uint256 amountInWei_)
        private
        returns (uint256 receivedLink)
    {
        //  Build the swap parameters
        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams(
                WETH_TOKEN,
                CHAIN_LINK_TOKEN,
                _feeTier,
                address(this),
                block.timestamp + 50,
                amountInWei_,
                1,
                0
            );

        receivedLink = SWAP_ROUTER.exactInputSingle(params);

        if (receivedLink < 1) revert SwapEthForLinkFailed();

        emit SwapMade(amountInWei_, receivedLink);
        return receivedLink;
    }

    /**
     *  @dev    -   Subscription
     */

    function _fundSubscription(uint256 amountOfLink_)
        internal
        returns (bool success)
    {
        success = ILinkTransfer(CHAIN_LINK_TOKEN).transferAndCall(
            VRF_COORDINATOR,
            amountOfLink_,
            _subscriptionId
        );
        if (!success) revert FundLinkContractFailed();
        return success;
    }

    /**
     *  @dev    -   Getters, Setters & Helpers
     */
    function _approveWeth(uint256 amount_) private {
        bool success = IERC20(WETH_TOKEN).approve(
            address(SWAP_ROUTER),
            amount_
        );
        if (!success) revert FailedToApproveWeth();
    }

    function _setFeeTier(uint24 newFeeTier_) internal {
        _feeTier = newFeeTier_;
    }

    function _getLinkBalance() internal view returns (uint256) {
        return IERC20(CHAIN_LINK_TOKEN).balanceOf(address(this));
    }

    function _setSplitAmount(uint8 newSplit_) internal {
        _balanceSplitAmount = newSplit_;
    }

    function _getWethBalance() internal view returns (uint256) {
        return IERC20(WETH_TOKEN).balanceOf(address(this));
    }

    function _getBalanceSplitAmount() internal view returns (uint8) {
        return _balanceSplitAmount;
    }

    function _getSubscriptionId() internal view returns (bytes memory) {
        return _subscriptionId;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IRandomNumber {
    event VRFDataChanged(uint64 VRFsubscriptionId_, bytes32 keyHash_);

    function getVRFInfo()
        external
        view
        returns (
            uint64,
            bytes32,
            uint32
        );

    function setCallbackGasLimit(uint32 newGaslimit_) external;

    function setNewVRFInfo(uint64 subscriptionId_, bytes32 keyHash_) external;
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface VRFCoordinatorV2Interface {
  /**
   * @notice Get configuration relevant for making requests
   * @return minimumRequestConfirmations global min for request confirmations
   * @return maxGasLimit global max for request gas limit
   * @return s_provingKeyHashes list of registered key hashes
   */
  function getRequestConfig()
    external
    view
    returns (
      uint16,
      uint32,
      bytes32[] memory
    );

  /**
   * @notice Request a set of random words.
   * @param keyHash - Corresponds to a particular oracle job which uses
   * that key for generating the VRF proof. Different keyHash's have different gas price
   * ceilings, so you can select a specific one to bound your maximum per request cost.
   * @param subId  - The ID of the VRF subscription. Must be funded
   * with the minimum subscription balance required for the selected keyHash.
   * @param minimumRequestConfirmations - How many blocks you'd like the
   * oracle to wait before responding to the request. See SECURITY CONSIDERATIONS
   * for why you may want to request more. The acceptable range is
   * [minimumRequestBlockConfirmations, 200].
   * @param callbackGasLimit - How much gas you'd like to receive in your
   * fulfillRandomWords callback. Note that gasleft() inside fulfillRandomWords
   * may be slightly less than this amount because of gas used calling the function
   * (argument decoding etc.), so you may need to request slightly more than you expect
   * to have inside fulfillRandomWords. The acceptable range is
   * [0, maxGasLimit]
   * @param numWords - The number of uint256 random values you'd like to receive
   * in your fulfillRandomWords callback. Note these numbers are expanded in a
   * secure way by the VRFCoordinator from a single random value supplied by the oracle.
   * @return requestId - A unique identifier of the request. Can be used to match
   * a request to a response in fulfillRandomWords.
   */
  function requestRandomWords(
    bytes32 keyHash,
    uint64 subId,
    uint16 minimumRequestConfirmations,
    uint32 callbackGasLimit,
    uint32 numWords
  ) external returns (uint256 requestId);

  /**
   * @notice Create a VRF subscription.
   * @return subId - A unique subscription id.
   * @dev You can manage the consumer set dynamically with addConsumer/removeConsumer.
   * @dev Note to fund the subscription, use transferAndCall. For example
   * @dev  LINKTOKEN.transferAndCall(
   * @dev    address(COORDINATOR),
   * @dev    amount,
   * @dev    abi.encode(subId));
   */
  function createSubscription() external returns (uint64 subId);

  /**
   * @notice Get a VRF subscription.
   * @param subId - ID of the subscription
   * @return balance - LINK balance of the subscription in juels.
   * @return reqCount - number of requests for this subscription, determines fee tier.
   * @return owner - owner of the subscription.
   * @return consumers - list of consumer address which are able to use this subscription.
   */
  function getSubscription(uint64 subId)
    external
    view
    returns (
      uint96 balance,
      uint64 reqCount,
      address owner,
      address[] memory consumers
    );

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @param newOwner - proposed new owner of the subscription
   */
  function requestSubscriptionOwnerTransfer(uint64 subId, address newOwner) external;

  /**
   * @notice Request subscription owner transfer.
   * @param subId - ID of the subscription
   * @dev will revert if original owner of subId has
   * not requested that msg.sender become the new owner.
   */
  function acceptSubscriptionOwnerTransfer(uint64 subId) external;

  /**
   * @notice Add a consumer to a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - New consumer which can use the subscription
   */
  function addConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Remove a consumer from a VRF subscription.
   * @param subId - ID of the subscription
   * @param consumer - Consumer to remove from the subscription
   */
  function removeConsumer(uint64 subId, address consumer) external;

  /**
   * @notice Cancel a subscription
   * @param subId - ID of the subscription
   * @param to - Where to send the remaining LINK to
   */
  function cancelSubscription(uint64 subId, address to) external;

  /*
   * @notice Check to see if there exists a request commitment consumers
   * for all consumers and keyhashes for a given sub.
   * @param subId - ID of the subscription
   * @return true if there exists at least one unfulfilled request for the subscription, false
   * otherwise.
   */
  function pendingRequestExists(uint64 subId) external view returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/** ****************************************************************************
 * @notice Interface for contracts using VRF randomness
 * *****************************************************************************
 * @dev PURPOSE
 *
 * @dev Reggie the Random Oracle (not his real job) wants to provide randomness
 * @dev to Vera the verifier in such a way that Vera can be sure he's not
 * @dev making his output up to suit himself. Reggie provides Vera a public key
 * @dev to which he knows the secret key. Each time Vera provides a seed to
 * @dev Reggie, he gives back a value which is computed completely
 * @dev deterministically from the seed and the secret key.
 *
 * @dev Reggie provides a proof by which Vera can verify that the output was
 * @dev correctly computed once Reggie tells it to her, but without that proof,
 * @dev the output is indistinguishable to her from a uniform random sample
 * @dev from the output space.
 *
 * @dev The purpose of this contract is to make it easy for unrelated contracts
 * @dev to talk to Vera the verifier about the work Reggie is doing, to provide
 * @dev simple access to a verifiable source of randomness. It ensures 2 things:
 * @dev 1. The fulfillment came from the VRFCoordinator
 * @dev 2. The consumer contract implements fulfillRandomWords.
 * *****************************************************************************
 * @dev USAGE
 *
 * @dev Calling contracts must inherit from VRFConsumerBase, and can
 * @dev initialize VRFConsumerBase's attributes in their constructor as
 * @dev shown:
 *
 * @dev   contract VRFConsumer {
 * @dev     constructor(<other arguments>, address _vrfCoordinator, address _link)
 * @dev       VRFConsumerBase(_vrfCoordinator) public {
 * @dev         <initialization with other arguments goes here>
 * @dev       }
 * @dev   }
 *
 * @dev The oracle will have given you an ID for the VRF keypair they have
 * @dev committed to (let's call it keyHash). Create subscription, fund it
 * @dev and your consumer contract as a consumer of it (see VRFCoordinatorInterface
 * @dev subscription management functions).
 * @dev Call requestRandomWords(keyHash, subId, minimumRequestConfirmations,
 * @dev callbackGasLimit, numWords),
 * @dev see (VRFCoordinatorInterface for a description of the arguments).
 *
 * @dev Once the VRFCoordinator has received and validated the oracle's response
 * @dev to your request, it will call your contract's fulfillRandomWords method.
 *
 * @dev The randomness argument to fulfillRandomWords is a set of random words
 * @dev generated from your requestId and the blockHash of the request.
 *
 * @dev If your contract could have concurrent requests open, you can use the
 * @dev requestId returned from requestRandomWords to track which response is associated
 * @dev with which randomness request.
 * @dev See "SECURITY CONSIDERATIONS" for principles to keep in mind,
 * @dev if your contract could have multiple requests in flight simultaneously.
 *
 * @dev Colliding `requestId`s are cryptographically impossible as long as seeds
 * @dev differ.
 *
 * *****************************************************************************
 * @dev SECURITY CONSIDERATIONS
 *
 * @dev A method with the ability to call your fulfillRandomness method directly
 * @dev could spoof a VRF response with any random value, so it's critical that
 * @dev it cannot be directly called by anything other than this base contract
 * @dev (specifically, by the VRFConsumerBase.rawFulfillRandomness method).
 *
 * @dev For your users to trust that your contract's random behavior is free
 * @dev from malicious interference, it's best if you can write it so that all
 * @dev behaviors implied by a VRF response are executed *during* your
 * @dev fulfillRandomness method. If your contract must store the response (or
 * @dev anything derived from it) and use it later, you must ensure that any
 * @dev user-significant behavior which depends on that stored value cannot be
 * @dev manipulated by a subsequent VRF request.
 *
 * @dev Similarly, both miners and the VRF oracle itself have some influence
 * @dev over the order in which VRF responses appear on the blockchain, so if
 * @dev your contract could have multiple VRF requests in flight simultaneously,
 * @dev you must ensure that the order in which the VRF responses arrive cannot
 * @dev be used to manipulate your contract's user-significant behavior.
 *
 * @dev Since the block hash of the block which contains the requestRandomness
 * @dev call is mixed into the input to the VRF *last*, a sufficiently powerful
 * @dev miner could, in principle, fork the blockchain to evict the block
 * @dev containing the request, forcing the request to be included in a
 * @dev different block with a different hash, and therefore a different input
 * @dev to the VRF. However, such an attack would incur a substantial economic
 * @dev cost. This cost scales with the number of blocks the VRF oracle waits
 * @dev until it calls responds to a request. It is for this reason that
 * @dev that you can signal to an oracle you'd like them to wait longer before
 * @dev responding to the request (however this is not enforced in the contract
 * @dev and so remains effective only in the case of unmodified oracle software).
 */
abstract contract VRFConsumerBaseV2 {
  error OnlyCoordinatorCanFulfill(address have, address want);
  address private immutable vrfCoordinator;

  /**
   * @param _vrfCoordinator address of VRFCoordinator contract
   */
  constructor(address _vrfCoordinator) {
    vrfCoordinator = _vrfCoordinator;
  }

  /**
   * @notice fulfillRandomness handles the VRF response. Your contract must
   * @notice implement it. See "SECURITY CONSIDERATIONS" above for important
   * @notice principles to keep in mind when implementing your fulfillRandomness
   * @notice method.
   *
   * @dev VRFConsumerBaseV2 expects its subcontracts to have a method with this
   * @dev signature, and will call it once it has verified the proof
   * @dev associated with the randomness. (It is triggered via a call to
   * @dev rawFulfillRandomness, below.)
   *
   * @param requestId The Id initially returned by requestRandomness
   * @param randomWords the VRF output expanded to the requested number of words
   */
  function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

  // rawFulfillRandomness is called by VRFCoordinator when it receives a valid VRF
  // proof. rawFulfillRandomness then calls fulfillRandomness, after validating
  // the origin of the call
  function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
    if (msg.sender != vrfCoordinator) {
      revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
    }
    fulfillRandomWords(requestId, randomWords);
  }
}

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256) external;
}

interface ILinkTransfer {
    function transferAndCall(
        address _to,
        uint256 _value,
        bytes calldata _data
    ) external returns (bool success);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface IFundLINKSubscription {
    event SubscriptionFunded(
        uint256 amountLink_,
        uint256 amountETH_,
        bytes subscriptionId_
    );

    event SwapMade(uint256 ethSent_, uint256 linkReturned_);

    error SwapEthForLinkFailed();
    error FailedToApproveWeth();
    error FundLinkContractFailed();

    receive() external payable;

    function exchangeAllEthAndFund() external;

    function exchangeAllWEthAndFund() external;

    function exchangeEthAmountAndFund(uint256 amount_) external;

    function fundWithLink(uint256 linkAmount_) external;

    function setSplitAmount(uint8 newSplit_) external;
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.6.0;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

library TransferHelper {
    /// @notice Transfers tokens from the targeted address to the given destination
    /// @notice Errors with 'STF' if transfer fails
    /// @param token The contract address of the token to be transferred
    /// @param from The originating address from which the tokens will be transferred
    /// @param to The destination address of the transfer
    /// @param value The amount to be transferred
    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) =
            token.call(abi.encodeWithSelector(IERC20.transferFrom.selector, from, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'STF');
    }

    /// @notice Transfers tokens from msg.sender to a recipient
    /// @dev Errors with ST if transfer fails
    /// @param token The contract address of the token which will be transferred
    /// @param to The recipient of the transfer
    /// @param value The value of the transfer
    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.transfer.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'ST');
    }

    /// @notice Approves the stipulated contract to spend the given allowance in the given token
    /// @dev Errors with 'SA' if transfer fails
    /// @param token The contract address of the token to be approved
    /// @param to The target of the approval
    /// @param value The amount of the given token the target will be allowed to spend
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(abi.encodeWithSelector(IERC20.approve.selector, to, value));
        require(success && (data.length == 0 || abi.decode(data, (bool))), 'SA');
    }

    /// @notice Transfers ETH to the recipient address
    /// @dev Fails with `STE`
    /// @param to The destination of the transfer
    /// @param value The value to be transferred
    function safeTransferETH(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}(new bytes(0));
        require(success, 'STE');
    }
}

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.7.5;
pragma abicoder v2;

import '@uniswap/v3-core/contracts/interfaces/callback/IUniswapV3SwapCallback.sol';

/// @title Router token swapping functionality
/// @notice Functions for swapping tokens via Uniswap V3
interface ISwapRouter is IUniswapV3SwapCallback {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactInputSingleParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInputSingle(ExactInputSingleParams calldata params) external payable returns (uint256 amountOut);

    struct ExactInputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
    }

    /// @notice Swaps `amountIn` of one token for as much as possible of another along the specified path
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactInputParams` in calldata
    /// @return amountOut The amount of the received token
    function exactInput(ExactInputParams calldata params) external payable returns (uint256 amountOut);

    struct ExactOutputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
        uint160 sqrtPriceLimitX96;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another token
    /// @param params The parameters necessary for the swap, encoded as `ExactOutputSingleParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutputSingle(ExactOutputSingleParams calldata params) external payable returns (uint256 amountIn);

    struct ExactOutputParams {
        bytes path;
        address recipient;
        uint256 deadline;
        uint256 amountOut;
        uint256 amountInMaximum;
    }

    /// @notice Swaps as little as possible of one token for `amountOut` of another along the specified path (reversed)
    /// @param params The parameters necessary for the multi-hop swap, encoded as `ExactOutputParams` in calldata
    /// @return amountIn The amount of the input token
    function exactOutput(ExactOutputParams calldata params) external payable returns (uint256 amountIn);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC20.sol)

pragma solidity ^0.8.0;

import "../token/ERC20/IERC20.sol";

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

// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

/// @title Callback for IUniswapV3PoolActions#swap
/// @notice Any contract that calls IUniswapV3PoolActions#swap must implement this interface
interface IUniswapV3SwapCallback {
    /// @notice Called to `msg.sender` after executing a swap via IUniswapV3Pool#swap.
    /// @dev In the implementation you must pay the pool tokens owed for the swap.
    /// The caller of this method must be checked to be a UniswapV3Pool deployed by the canonical UniswapV3Factory.
    /// amount0Delta and amount1Delta can both be 0 if no tokens were swapped.
    /// @param amount0Delta The amount of token0 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token0 to the pool.
    /// @param amount1Delta The amount of token1 that was sent (negative) or must be received (positive) by the pool by
    /// the end of the swap. If positive, the callback must send that amount of token1 to the pool.
    /// @param data Any data passed through by the caller via the IUniswapV3PoolActions#swap call
    function uniswapV3SwapCallback(
        int256 amount0Delta,
        int256 amount1Delta,
        bytes calldata data
    ) external;
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

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

interface IAddressControl {
    struct SubmissionData {
        string projectName;
        address contractAddress;
        bytes4 interfaceId;
        address projectContact;
    }

    event AddressAdded(
        address contractAddress,
        bytes4 interfaceId,
        string projectName
    );
    event AddressRevoked(address contractAddress_, string reason_);
    event AddressAccepted(address contractAddress_);

    modifier acceptedTokenAddress(address NFTAddress_) virtual;

    function addAddress(
        address contractAddress_,
        bytes4 interfaceId_,
        string memory projectName_,
        address projectContact_
    ) external;

    function addBulkAddress(SubmissionData[] memory inputData_) external;

    function revokeAddress(address contractAddress_, string memory _reason)
        external;

    function getAllowedProjectData(address contractAddress_)
        external
        returns (SubmissionData memory);
}