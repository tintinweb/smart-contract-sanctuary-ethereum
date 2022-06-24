// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

interface IToken is IERC721 {
    function owner() external view returns (address);

    function mint(address to, uint256 tokenId) external;
}

contract FirstSaleStorfrontERC721 is Pausable {
    struct Payment {
        address token;
        uint256 totalWithdrawal;
    }

    struct Beneficiary {
        uint256 share;
        address wallet;
        mapping(uint256 => uint256) withdrawalMap;
    }

    struct BeneficiarySetting {
        uint256 share;
        address wallet;
    }

    enum SaleKind {
        NONE,
        AIRDROPE,
        PURCHASE,
        DUTCH_AUCTION
    }

    struct Sale {
        SaleKind kind;
        bool isWhitelistSale;
        bool isAccessConfinesSale;
        uint256 startTimestampInSeconds;
        uint256 endTimestampInSeconds;
        uint256 fromTokenId;
        uint256 toTokenId;
        uint256 initialPrice;
    }

    struct AccessConfines {
        address token;
        uint256 idCount;
        mapping(uint256 => uint256) idMap;
    }

    struct AccessConfinesList {
        uint256 count;
        mapping(uint256 => AccessConfines) map;
    }

    struct DutchAuction {
        uint256 tickCount;
        uint256 tickSizeInSeconds;
        uint256 lossStartTimestampInSeconds;
        uint256 lossPerTick;
    }

    struct AccessConfinesSetting {
        address token;
        uint256[] idList;
    }

    struct SaleSetting {
        Sale sale;
        AccessConfinesSetting[] accessConfinesList;
        DutchAuction dutchAuction;
    }

    struct AccessRequest {
        uint256 confinesId;
        uint256 accessTokenIndex;
        uint256 accessTokenIdIndex;
        uint256 accessTokenId;
    }

    uint256 private constant TOTAL_SHARE = 100_000;

    address private _token;
    address private _signer;

    uint256 private _paymentCount;
    mapping(uint256 => Payment) private _paymentMap;

    uint256 private _beneficiaryCount;
    mapping(uint256 => Beneficiary) private _beneficiaryMap;

    uint256 private _saleCount;
    mapping(uint256 => Sale) private _saleMap;

    mapping(uint256 => AccessConfinesList) private _accessConfinesListMap;

    mapping(uint256 => DutchAuction) private _dutchAuctionMap;

    modifier onlyTokenOwner() {
        require(
            _msgSender() == IToken(_token).owner(),
            "sender is not token owner"
        );
        _;
    }

    function token() external view returns (address) {
        return _token;
    }

    function signer() external view returns (address) {
        return _signer;
    }

    function paymentTokenList() external view returns (address[] memory list) {
        uint256 count = _paymentCount;
        list = new address[](count);

        while (0 < count) {
            --count;

            list[count] = _paymentMap[count].token;
        }
    }

    function beneficiaryList()
        external
        view
        returns (BeneficiarySetting[] memory list)
    {
        uint256 count = _beneficiaryCount;
        list = new BeneficiarySetting[](count);

        while (0 < count) {
            --count;

            list[count] = _beneficiarySetting(_beneficiaryMap[count]);
        }
    }

    function possibleWithdrawList(uint256 beneficiaryId)
        external
        view
        returns (uint256[] memory list)
    {
        if (_beneficiaryCount <= beneficiaryId) {
            return new uint256[](0);
        }

        uint256 count = _paymentCount;
        list = new uint256[](count);

        Beneficiary storage b = _beneficiaryMap[beneficiaryId];
        uint256 share = b.share;
        mapping(uint256 => uint256) storage withdrawalMap = b.withdrawalMap;
        while (0 < count) {
            --count;

            Payment storage p = _paymentMap[count];
            list[count] = _possibleWithdraw(
                share,
                withdrawalMap[count],
                _totalPayment(p.token, p.totalWithdrawal)
            );
        }
    }

    function saleCount() external view returns (uint256) {
        return _saleCount;
    }

    function saleSettingList()
        external
        view
        returns (SaleSetting[] memory list)
    {
        uint256 count = _saleCount;
        list = new SaleSetting[](count);

        while (0 < count) {
            --count;

            list[count] = _saleSetting(count);
        }
    }

    function saleSetting(uint256 saleId)
        external
        view
        returns (SaleSetting memory)
    {
        return _saleSetting(saleId);
    }

    function currentSaleId(uint256 timestampInSeconds)
        external
        view
        returns (uint256)
    {
        return _currentSaleId(timestampInSeconds);
    }

    function priceOf(uint256 timestampInSeconds)
        external
        view
        returns (uint256)
    {
        uint256 saleId = _currentSaleId(timestampInSeconds);
        return _price(_saleMap[saleId], saleId, timestampInSeconds);
    }

    function initiate(
        address token_,
        address signer_,
        address[] calldata paymentTokenList_,
        BeneficiarySetting[] calldata beneficiaryList_,
        SaleSetting[] calldata saleList_
    ) external {
        require(_saleCount == 0, "already initiate");

        require(token_ != address(0), "incorrect token");
        _token = token_;

        require(signer_ != address(0), "incorrect signer");
        _signer = signer_;

        _setPaymentMap(paymentTokenList_);

        _setBeneficiaryMap(beneficiaryList_);

        _setSaleList(saleList_);
    }

    function setSale(SaleSetting calldata setting, uint256 saleId)
        external
        onlyTokenOwner
    {
        uint256 count = _saleCount;

        require(saleId < count, "incorrect sale id");

        uint256 previousSaleEnd;
        if (0 < saleId) {
            previousSaleEnd = _saleMap[saleId - 1].endTimestampInSeconds;
        }

        uint256 nextSaleStart;
        if (saleId < count - 1) {
            nextSaleStart = _saleMap[saleId + 1].startTimestampInSeconds;
        } else {
            nextSaleStart = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        }

        _setSale(setting, saleId, previousSaleEnd, nextSaleStart);
    }

    function withdraw(uint256 beneficiaryId) external {
        require(beneficiaryId < _beneficiaryCount, "incorrect beneficiary id");

        uint256 count = _paymentCount;

        Beneficiary storage b = _beneficiaryMap[beneficiaryId];
        uint256 share = b.share;
        address wallet = b.wallet;

        mapping(uint256 => uint256) storage withdrawalMap = b.withdrawalMap;
        while (0 < count) {
            --count;

            uint256 withdrawal = withdrawalMap[count];

            Payment storage p = _paymentMap[count];
            address pToken = p.token;
            uint256 totalWithdrawal = p.totalWithdrawal;

            uint256 amount = _possibleWithdraw(
                share,
                withdrawal,
                _totalPayment(pToken, totalWithdrawal)
            );

            if (amount == 0) {
                continue;
            }

            p.totalWithdrawal = totalWithdrawal + amount;

            withdrawalMap[count] = withdrawal + amount;

            _sendTo(p.token, wallet, amount);
        }
    }

    function buy(
        uint256 saleId,
        bytes calldata whitelistSignature,
        AccessRequest calldata accessRequest,
        uint256[] calldata requestTokenIdList,
        uint256 paymentId
    ) external payable whenNotPaused {
        require(saleId < _saleCount, "incorrect sale id");

        Sale storage sale = _saleMap[saleId];

        uint256 time = block.timestamp;
        address sender = _msgSender();

        require(
            sale.startTimestampInSeconds <= time &&
                time < sale.endTimestampInSeconds,
            "time confines not fulfilled"
        );

        _checkWhitelistConfines(
            sale.isWhitelistSale,
            saleId,
            whitelistSignature,
            sender
        );

        _checkAccessConfines(
            sale.isAccessConfinesSale,
            _accessConfinesListMap[saleId],
            accessRequest,
            sender
        );

        require(paymentId < _paymentCount, "incorrect payment id");

        _savePayment(
            sender,
            _paymentMap[paymentId].token,
            requestTokenIdList.length * _price(sale, saleId, time),
            msg.value
        );

        _batchMint(sale, requestTokenIdList, sender);
    }

    function turnPauseSetting(bool turnOn) external onlyTokenOwner {
        if (turnOn) {
            _pause();
        } else {
            _unpause();
        }
    }

    function _beneficiarySetting(Beneficiary storage b)
        private
        view
        returns (BeneficiarySetting memory s)
    {
        s.share = b.share;
        s.wallet = b.wallet;
    }

    function _totalPayment(address pToken, uint256 totalWithdrawal)
        private
        view
        returns (uint256)
    {
        return
            pToken != address(0)
                ? totalWithdrawal + IERC20(pToken).balanceOf(address(this))
                : totalWithdrawal + address(this).balance;
    }

    function _possibleWithdraw(
        uint256 share,
        uint256 withdrawal,
        uint256 totalPayment
    ) private pure returns (uint256) {
        uint256 totalPossibleWithdraw = (totalPayment * share) / TOTAL_SHARE;

        require(withdrawal <= totalPossibleWithdraw, "error: 0");

        return totalPossibleWithdraw - withdrawal;
    }

    function _saleSetting(uint256 saleId)
        private
        view
        returns (SaleSetting memory s)
    {
        s.sale = _saleMap[saleId];

        s.accessConfinesList = _accessConfinesList(saleId);

        s.dutchAuction = _dutchAuctionMap[saleId];
    }

    function _accessConfinesList(uint256 saleId)
        private
        view
        returns (AccessConfinesSetting[] memory list)
    {
        AccessConfinesList storage cList = _accessConfinesListMap[saleId];

        uint256 count = cList.count;
        list = new AccessConfinesSetting[](count);

        mapping(uint256 => AccessConfines) storage cMap = cList.map;
        while (0 < count) {
            --count;

            list[count] = _accessConfines(cMap[count]);
        }
    }

    function _accessConfines(AccessConfines storage c)
        private
        view
        returns (AccessConfinesSetting memory s)
    {
        s.token = c.token;
        s.idList = _mapToList(c.idCount, c.idMap);
    }

    function _mapToList(uint256 count, mapping(uint256 => uint256) storage map)
        private
        view
        returns (uint256[] memory list)
    {
        list = new uint256[](count);

        while (0 < count) {
            --count;

            list[count] = map[count];
        }
    }

    function _currentSaleId(uint256 time) private view returns (uint256) {
        uint256 count = _paymentCount;

        while (0 < count) {
            --count;

            Sale storage sale = _saleMap[count];

            if (
                sale.startTimestampInSeconds <= time &&
                time < sale.endTimestampInSeconds
            ) {
                return count;
            }
        }

        revert("current sale id is not exist");
    }

    function _price(
        Sale storage sale,
        uint256 saleId,
        uint256 time
    ) private view returns (uint256) {
        if (sale.kind == SaleKind.DUTCH_AUCTION) {
            return
                _dutchAuctionPrice(
                    _dutchAuctionMap[saleId],
                    sale.initialPrice,
                    time
                );
        }

        return sale.initialPrice;
    }

    function _dutchAuctionPrice(
        DutchAuction storage auction,
        uint256 initialPrice,
        uint256 time
    ) private view returns (uint256) {
        uint256 lossStart = auction.lossStartTimestampInSeconds;
        if (time < lossStart) {
            return initialPrice;
        }

        uint256 tickCount = auction.tickCount;
        uint256 tick = 1 + (time - lossStart) / auction.tickSizeInSeconds;
        if (tickCount < tick) {
            tick = tickCount;
        }

        return initialPrice - tick * auction.lossPerTick;
    }

    function _setPaymentMap(address[] calldata paymentTokenList_) private {
        uint256 count = paymentTokenList_.length;

        require(0 < count, "payment setting is empty");

        _paymentCount = count;

        while (0 < count) {
            --count;

            _paymentMap[count].token = paymentTokenList_[count];
        }
    }

    function _setBeneficiaryMap(BeneficiarySetting[] calldata beneficiaryList_)
        private
    {
        uint256 count = beneficiaryList_.length;

        require(0 < count, "beneficiary setting is empty");

        _beneficiaryCount = count;

        uint256 totalShare;

        while (0 < count) {
            --count;

            BeneficiarySetting calldata s = beneficiaryList_[count];

            require(s.wallet != address(0), "incorrect wallet");
            require(0 < s.share, "incorrect share");

            Beneficiary storage b = _beneficiaryMap[count];
            b.share = s.share;
            b.wallet = s.wallet;

            totalShare += s.share;
        }

        require(totalShare == TOTAL_SHARE, "incorrect total share");
    }

    function _setSaleList(SaleSetting[] calldata saleList_) private {
        uint256 count = saleList_.length;

        require(0 < count, "sale setting is empty");

        _saleCount = count;

        uint256 nextSaleStart = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        while (0 < count) {
            --count;

            SaleSetting calldata setting = saleList_[count];

            _setSale(setting, count, 0, nextSaleStart);

            nextSaleStart = setting.sale.startTimestampInSeconds;
        }
    }

    function _setSale(
        SaleSetting calldata setting,
        uint256 saleId,
        uint256 previousSaleEnd,
        uint256 nextSaleStart
    ) private {
        Sale calldata s = setting.sale;

        require(s.kind != SaleKind.NONE, "incorrect sale kind");

        if (s.kind != SaleKind.AIRDROPE) {
            require(0 < s.initialPrice, "");
        } else {
            require(s.initialPrice == 0, "");
        }

        if (s.kind != SaleKind.DUTCH_AUCTION) {
            delete _dutchAuctionMap[saleId];
        } else {
            _setDutchAuction(setting.dutchAuction, saleId, s.initialPrice);
        }

        require(
            previousSaleEnd <= s.startTimestampInSeconds &&
                s.startTimestampInSeconds < s.endTimestampInSeconds &&
                s.endTimestampInSeconds <= nextSaleStart,
            "incorrect time frame"
        );

        require(s.fromTokenId < s.toTokenId, "incorrect id interval");

        if (!s.isAccessConfinesSale) {
            _accessConfinesListMap[saleId].count = 0;
        } else {
            _setAccessConfinesList(
                _accessConfinesListMap[saleId],
                setting.accessConfinesList
            );
        }

        _saleMap[saleId] = s;
    }

    function _setDutchAuction(
        DutchAuction calldata auction,
        uint256 saleId,
        uint256 initialPrice
    ) private {
        require(
            0 < auction.tickCount &&
                0 < auction.lossPerTick &&
                0 < auction.tickSizeInSeconds &&
                auction.tickCount * auction.lossPerTick < initialPrice,
            "incorrect dutch auction"
        );

        _dutchAuctionMap[saleId] = auction;
    }

    function _setAccessConfinesList(
        AccessConfinesList storage cList,
        AccessConfinesSetting[] calldata sList
    ) private {
        uint256 count = sList.length;

        require(0 < count, "access setting is empty");

        _saleCount = count;

        cList.count = count;

        mapping(uint256 => AccessConfines) storage cMap = cList.map;
        while (0 < count) {
            --count;

            AccessConfinesSetting calldata s = sList[count];

            AccessConfines storage c = cMap[count];
            c.token = s.token;
            c.idCount = s.idList.length;

            if (s.idList.length == 0) {
                continue;
            }

            _listToMap(c.idMap, s.idList);
        }
    }

    function _listToMap(
        mapping(uint256 => uint256) storage map,
        uint256[] calldata list
    ) private {
        uint256 count = list.length;

        while (0 < count) {
            --count;

            map[count] = list[count];
        }
    }

    function _sendTo(
        address pToken,
        address to,
        uint256 amount
    ) private {
        if (pToken != address(0)) {
            SafeERC20.safeTransfer(IERC20(pToken), to, amount);
        } else {
            _sendCoinTo(to, amount);
        }
    }

    function _sendCoinTo(address to, uint256 amount) private {
        (bool success, ) = to.call{value: amount}("");
        require(success, "coin transfer failed");
    }

    function _checkWhitelistConfines(
        bool isWhitelistSale,
        uint256 saleId,
        bytes calldata signature,
        address sender
    ) private view {
        if (!isWhitelistSale) {
            return;
        }

        bytes32 sHash = keccak256(
            abi.encodeWithSignature(
                "WhitelistHash(address,address,uint256,address)",
                address(this),
                _token,
                saleId,
                sender
            )
        );

        require(
            SignatureChecker.isValidSignatureNow(_signer, sHash, signature),
            "whitelist confines not fulfilled"
        );
    }

    function _checkAccessConfines(
        bool isAccessConfinesSale,
        AccessConfinesList storage cList,
        AccessRequest calldata aRequest,
        address sender
    ) private view {
        if (!isAccessConfinesSale) {
            return;
        }

        require(aRequest.confinesId < cList.count, "incorrect confines id");

        AccessConfines storage c = cList.map[aRequest.confinesId];

        uint256 tokenId;

        uint256 idCount = c.idCount;
        if (0 < idCount) {
            require(
                aRequest.accessTokenIdIndex < idCount,
                "incorrect token id index"
            );

            tokenId = c.idMap[aRequest.accessTokenIdIndex];
        } else {
            tokenId = aRequest.accessTokenId;
        }

        require(
            sender == IERC721(c.token).ownerOf(tokenId),
            "access confines not fulfilled"
        );
    }

    function _savePayment(
        address sender,
        address pToken,
        uint256 requestAmount,
        uint256 coinAmount
    ) private {
        if (0 < requestAmount) {
            if (pToken != address(0)) {
                SafeERC20.safeTransferFrom(
                    IERC20(pToken),
                    sender,
                    address(this),
                    requestAmount
                );
            } else {
                require(requestAmount <= coinAmount, "insufficient funds");
                coinAmount -= requestAmount;
            }
        }

        if (0 < coinAmount) {
            _sendCoinTo(sender, coinAmount);
        }
    }

    function _batchMint(
        Sale storage sale,
        uint256[] calldata requestTokenIdList,
        address sender
    ) private {
        uint256 count = requestTokenIdList.length;

        require(0 < count, "id list is empty");

        uint256 fromId = sale.fromTokenId;
        uint256 toId = sale.toTokenId;
        while (0 < count) {
            --count;

            uint256 tokenId = requestTokenIdList[count];

            require(fromId <= tokenId && tokenId < toId, "incorrect token id");

            IToken(_token).mint(sender, tokenId);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/SignatureChecker.sol)

pragma solidity ^0.8.0;

import "./ECDSA.sol";
import "../Address.sol";
import "../../interfaces/IERC1271.sol";

/**
 * @dev Signature verification helper that can be used instead of `ECDSA.recover` to seamlessly support both ECDSA
 * signatures from externally owned accounts (EOAs) as well as ERC1271 signatures from smart contract wallets like
 * Argent and Gnosis Safe.
 *
 * _Available since v4.1._
 */
library SignatureChecker {
    /**
     * @dev Checks if a signature is valid for a given signer and data hash. If the signer is a smart contract, the
     * signature is validated against that smart contract using ERC1271, otherwise it's validated using `ECDSA.recover`.
     *
     * NOTE: Unlike ECDSA signatures, contract signatures are revocable, and the outcome of this function can thus
     * change through time. It could return true at block N and false at block N+1 (or the opposite).
     */
    function isValidSignatureNow(
        address signer,
        bytes32 hash,
        bytes memory signature
    ) internal view returns (bool) {
        (address recovered, ECDSA.RecoverError error) = ECDSA.tryRecover(hash, signature);
        if (error == ECDSA.RecoverError.NoError && recovered == signer) {
            return true;
        }

        (bool success, bytes memory result) = signer.staticcall(
            abi.encodeWithSelector(IERC1271.isValidSignature.selector, hash, signature)
        );
        return (success && result.length == 32 && abi.decode(result, (bytes4)) == IERC1271.isValidSignature.selector);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (security/Pausable.sol)

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
     * @dev Returns true if the contract is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "Pausable: paused");
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
        require(paused(), "Pausable: not paused");
        _;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/utils/ERC721Holder.sol)

pragma solidity ^0.8.0;

import "../IERC721Receiver.sol";

/**
 * @dev Implementation of the {IERC721Receiver} interface.
 *
 * Accepts all token transfers.
 * Make sure the contract is able to use its token with {IERC721-safeTransferFrom}, {IERC721-approve} or {IERC721-setApprovalForAll}.
 */
contract ERC721Holder is IERC721Receiver {
    /**
     * @dev See {IERC721Receiver-onERC721Received}.
     *
     * Always returns `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC721Received.selector;
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../../../utils/Address.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    /**
     * @dev Deprecated. This function has issues similar to the ones found in
     * {IERC20-approve}, and its usage is discouraged.
     *
     * Whenever possible, use {safeIncreaseAllowance} and
     * {safeDecreaseAllowance} instead.
     */
    function safeApprove(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        // safeApprove should only be called when setting an initial allowance,
        // or when resetting it to zero. To increase and decrease it, use
        // 'safeIncreaseAllowance' and 'safeDecreaseAllowance'
        require(
            (value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(oldAllowance >= value, "SafeERC20: decreased allowance below zero");
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
        }
    }

    /**
     * @dev Imitates a Solidity high-level call (i.e. a regular function call to a contract), relaxing the requirement
     * on the return value: the return value is optional (but if data is returned, it must not be false).
     * @param token The token targeted by the call.
     * @param data The call data (encoded using abi.encode or one of its variants).
     */
    function _callOptionalReturn(IERC20 token, bytes memory data) private {
        // We need to perform a low level call here, to bypass Solidity's return data size checking mechanism, since
        // we're implementing it ourselves. We use {Address.functionCall} to perform this call, which verifies that
        // the target address contains contract code and also asserts for success in the low-level call.

        bytes memory returndata = address(token).functionCall(data, "SafeERC20: low-level call failed");
        if (returndata.length > 0) {
            // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (interfaces/IERC1271.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC1271 standard signature validation method for
 * contracts as defined in https://eips.ethereum.org/EIPS/eip-1271[ERC-1271].
 *
 * _Available since v4.1._
 */
interface IERC1271 {
    /**
     * @dev Should return whether the signature provided is valid for the provided data
     * @param hash      Hash of the data to be signed
     * @param signature Signature byte array associated with _data
     */
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/cryptography/ECDSA.sol)

pragma solidity ^0.8.0;

import "../Strings.sol";

/**
 * @dev Elliptic Curve Digital Signature Algorithm (ECDSA) operations.
 *
 * These functions can be used to verify that a message was signed by the holder
 * of the private keys of a given address.
 */
library ECDSA {
    enum RecoverError {
        NoError,
        InvalidSignature,
        InvalidSignatureLength,
        InvalidSignatureS,
        InvalidSignatureV
    }

    function _throwError(RecoverError error) private pure {
        if (error == RecoverError.NoError) {
            return; // no error: do nothing
        } else if (error == RecoverError.InvalidSignature) {
            revert("ECDSA: invalid signature");
        } else if (error == RecoverError.InvalidSignatureLength) {
            revert("ECDSA: invalid signature length");
        } else if (error == RecoverError.InvalidSignatureS) {
            revert("ECDSA: invalid signature 's' value");
        } else if (error == RecoverError.InvalidSignatureV) {
            revert("ECDSA: invalid signature 'v' value");
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature` or error string. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     *
     * Documentation for signature generation:
     * - with https://web3js.readthedocs.io/en/v1.3.4/web3-eth-accounts.html#sign[Web3.js]
     * - with https://docs.ethers.io/v5/api/signer/#Signer-signMessage[ethers]
     *
     * _Available since v4.3._
     */
    function tryRecover(bytes32 hash, bytes memory signature) internal pure returns (address, RecoverError) {
        // Check the signature length
        // - case 65: r,s,v signature (standard)
        // - case 64: r,vs signature (cf https://eips.ethereum.org/EIPS/eip-2098) _Available since v4.1._
        if (signature.length == 65) {
            bytes32 r;
            bytes32 s;
            uint8 v;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                s := mload(add(signature, 0x40))
                v := byte(0, mload(add(signature, 0x60)))
            }
            return tryRecover(hash, v, r, s);
        } else if (signature.length == 64) {
            bytes32 r;
            bytes32 vs;
            // ecrecover takes the signature parameters, and the only way to get them
            // currently is to use assembly.
            assembly {
                r := mload(add(signature, 0x20))
                vs := mload(add(signature, 0x40))
            }
            return tryRecover(hash, r, vs);
        } else {
            return (address(0), RecoverError.InvalidSignatureLength);
        }
    }

    /**
     * @dev Returns the address that signed a hashed message (`hash`) with
     * `signature`. This address can then be used for verification purposes.
     *
     * The `ecrecover` EVM opcode allows for malleable (non-unique) signatures:
     * this function rejects them by requiring the `s` value to be in the lower
     * half order, and the `v` value to be either 27 or 28.
     *
     * IMPORTANT: `hash` _must_ be the result of a hash operation for the
     * verification to be secure: it is possible to craft signatures that
     * recover to arbitrary addresses for non-hashed data. A safe way to ensure
     * this is by receiving a hash of the original message (which may otherwise
     * be too long), and then calling {toEthSignedMessageHash} on it.
     */
    function recover(bytes32 hash, bytes memory signature) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, signature);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `r` and `vs` short-signature fields separately.
     *
     * See https://eips.ethereum.org/EIPS/eip-2098[EIP-2098 short signatures]
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address, RecoverError) {
        bytes32 s = vs & bytes32(0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff);
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        return tryRecover(hash, v, r, s);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `r and `vs` short-signature fields separately.
     *
     * _Available since v4.2._
     */
    function recover(
        bytes32 hash,
        bytes32 r,
        bytes32 vs
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, r, vs);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Overload of {ECDSA-tryRecover} that receives the `v`,
     * `r` and `s` signature fields separately.
     *
     * _Available since v4.3._
     */
    function tryRecover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address, RecoverError) {
        // EIP-2 still allows signature malleability for ecrecover(). Remove this possibility and make the signature
        // unique. Appendix F in the Ethereum Yellow paper (https://ethereum.github.io/yellowpaper/paper.pdf), defines
        // the valid range for s in (301): 0 < s < secp256k1n ÷ 2 + 1, and for v in (302): v ∈ {27, 28}. Most
        // signatures from current libraries generate a unique signature with an s-value in the lower half order.
        //
        // If your library generates malleable signatures, such as s-values in the upper range, calculate a new s-value
        // with 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - s1 and flip v from 27 to 28 or
        // vice versa. If your library also generates signatures with 0/1 for v instead 27/28, add 27 to v to accept
        // these malleable signatures as well.
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            return (address(0), RecoverError.InvalidSignatureS);
        }
        if (v != 27 && v != 28) {
            return (address(0), RecoverError.InvalidSignatureV);
        }

        // If the signature is valid (and not malleable), return the signer address
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            return (address(0), RecoverError.InvalidSignature);
        }

        return (signer, RecoverError.NoError);
    }

    /**
     * @dev Overload of {ECDSA-recover} that receives the `v`,
     * `r` and `s` signature fields separately.
     */
    function recover(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        (address recovered, RecoverError error) = tryRecover(hash, v, r, s);
        _throwError(error);
        return recovered;
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from a `hash`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes32 hash) internal pure returns (bytes32) {
        // 32 is the length in bytes of hash,
        // enforced by the type signature above
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    /**
     * @dev Returns an Ethereum Signed Message, created from `s`. This
     * produces hash corresponding to the one signed with the
     * https://eth.wiki/json-rpc/API#eth_sign[`eth_sign`]
     * JSON-RPC method as part of EIP-191.
     *
     * See {recover}.
     */
    function toEthSignedMessageHash(bytes memory s) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n", Strings.toString(s.length), s));
    }

    /**
     * @dev Returns an Ethereum Signed Typed Data, created from a
     * `domainSeparator` and a `structHash`. This produces hash corresponding
     * to the one signed with the
     * https://eips.ethereum.org/EIPS/eip-712[`eth_signTypedData`]
     * JSON-RPC method as part of EIP-712.
     *
     * See {recover}.
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
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
// OpenZeppelin Contracts v4.4.1 (utils/Strings.sol)

pragma solidity ^0.8.0;

/**
 * @dev String operations.
 */
library Strings {
    bytes16 private constant _HEX_SYMBOLS = "0123456789abcdef";

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
}