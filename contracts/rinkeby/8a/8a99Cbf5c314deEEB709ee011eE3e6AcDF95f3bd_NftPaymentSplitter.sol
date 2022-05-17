// SPDX-License-Identifier: MIT
// Derived from OpenZeppelin Contracts v4.4.1 (finance/PaymentSplitter.sol)

/// @title Creat00r Blacklist NftPaymentSplitter
/// @author Bitstrays Team

//////////////////////////////////////////////////////////////////////////////////////
//                                                                                  //
//                                                                                  //
//                                 ,▄▄                                              //
//                                 ▓███▄▄▓██▄                                       //
//                            ,╔▄██████▌     ║████Γ                                 //
//                         ╔██▀   █████▌     ║████      ╟██▄                        //
//                      ╓█▀╙     ]██████     ║███▌      ╟█████▓,                    //
//                   ,▄█▀        ║██████⌐    ║███▌      ▐████████▄                  //
//                  ▄█╙          ╟██████▒    ║███▌       ██████████▄                //
//                ╓█▀            ║██████▌    ║███▒       ████████████▄              //
//               ▐█              ╫██████▌    ║███▒       ██████████████             //
//              ▄█               ╟██████▌    ║███▒       ███████████████            //
//             ╔█                ╟██████▌    ║███▌       ████████████████           //
//            ,█⌐                ║██████⌐    ║███▌      ▐████████████████▌          //
//            ║▌                 ╙██████     ║███▌      ║█████████████████          //
//            █▌                  █████▌     ║████      ╟█████████████████▌         //
//           ]█     ]▄            ╟████▌     ║████▒    ]████████████╙╟████▌         //
//           ▐█     ▐█             ████      ║█████    ╟███████████▌ ▐████▌         //
//            ▓▒     █▒            └▀▀       ║██████,,▓████████████▌ ╟████▌         //
//            ╟▌     ║█                      ║█████████████████████ ]█████⌐         //
//            ╙█      ╟█                     ║████████████████████╜ ╣████▌          //
//             ╟▌      ╫▌                    ║███████████████████⌐ ▓█████           //
//              ╫▌      ╚█µ                  ║█████████████████▀ ,▓█████`           //
//               ╟█      └▀█                 ║████████████████` ▄██████             //
//                ╚█µ      `▀█▄              ║█████████████▀ ,▄██████▀              //
//                 `██        ╙▀█▄,          ║█████████▀╙ ,▄████████╙               //
//                   ╙█▄         `╙▀██▄▄╦╓╓,╓╚▀▀▀▀▀╙  ,╗▄█████████╙                 //
//                     "▀█╦              ╙╙╙╙╔▄▄▄▓█████████████▀                    //
//                        ╙▀█▄,              ║█████████████▀▀                       //
//                           `╙▀█▄╦╓         ║████████▀▀╙                           //
//                                 ╙▀▀▀█████▓                                       //
//                                                                                  //
//                                                                                  //
//////////////////////////////////////////////////////////////////////////////////////


pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165Checker.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title NftPaymentSplitter
 * @dev This contract allows to split Ether payments among a group of NFT holders. The sender does not need to be aware
 * that the Ether will be split in this way, since it is handled transparently by the contract.
 * This contract is derived from the openzeppelin payment splitter and modified for NFT payment splitting.
 *
 * The split will be equal parts. The way this is specified is by assigning each
 * NFT to a number of shares. Of all the Ether that this contract receives, each account will then be able to claim
 * an amount proportional to the percentage of total shares they were assigned.
 *
 * `PaymentSplitter` follows a _pull payment_ model. This means that payments are not automatically forwarded to the
 * accounts but kept in this contract, and the actual transfer is triggered as a separate step by calling the {release}
 * function.
 *
 * NOTE: This contract assumes that ERC20 tokens will behave similarly to native tokens (Ether). Rebasing tokens, and
 * tokens that apply fees during transfers, are likely to not be supported as expected. If in doubt, we encourage you
 * to run tests before sending real value to this contract.
 * There are only two types of shares the owner shares and the NFT holder share.
 */
contract NftPaymentSplitter is Context, Ownable {
    using ERC165Checker for address;

    event PayeeAdded(uint256 tokenId, uint256 shares);
    event PaymentReleased(uint256 tokenId, address to, uint256 amount);
    event ERC20PaymentReleased(
        uint256 tokenId,
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event UnclaimedPaymentReleased(uint256 tokenId, address to, uint256 amount);
    event UnclaimedERC20PaymentReleased(
        uint256 tokenId,
        IERC20 indexed token,
        address to,
        uint256 amount
    );
    event PaymentReceived(address from, uint256 amount);

    uint256 private _totalShares;
    uint256 private _totalReleased;
    uint256 private _maxSupply;
    uint256 private _sharesPerToken;
    uint256 private _totalSharesOffset; //offset for unitialized tokenids
    address public creat00rWallet;
    address public dev1Wallet;
    address public dev2Wallet;

    uint32 private constant _creat00rId = 0;
    uint32 private constant _dev1Id = 334;
    uint32 private constant _dev2Id = 335;


    bytes4 public constant IID_IERC721 = type(IERC721).interfaceId;
    IERC721 public immutable nftCollection;

    mapping(uint256 => uint256) private _shares;
    mapping(uint256 => uint256) private _released;

    mapping(IERC20 => uint256) private _erc20TotalReleased;
    mapping(IERC20 => mapping(uint256 => uint256)) private _erc20Released;

    /**
     * @dev Creates an instance of `NftPaymentSplitter` where each tokenId in `nftCollection_`  is assigned
     * the same shared defined in `sharesPerToken_`. The `creat00rShare_` and `creat00rAddress_` are
     * used for the collection owner to define a bigger share propotion. 
     *
     * Note
     * creat00rShare_ is using the tokenId 0 which may not work for collections where the tokenId 0 exists
     * this can be easy modified if required
     */
    constructor(
        uint256 maxSupply_,
        uint256 sharesPerToken_,
        uint256[] memory creat00rsShare_,
        address[] memory creat00rWallets_,
        address nftCollection_
    ) payable {
        require(
            nftCollection_ != address(0),
            "ERC721 collection address can't be zero address"
        );
        require(
            nftCollection_.supportsInterface(IID_IERC721),
            "collection address does not support ERC721"
        );
        require(maxSupply_ > 0, "PaymentSplitter: no payees");

        _maxSupply = maxSupply_;
        _sharesPerToken = sharesPerToken_;

        _totalSharesOffset = maxSupply_ * sharesPerToken_;
        nftCollection = IERC721(nftCollection_);

        _setupCreat00rShares(creat00rsShare_, creat00rWallets_);

    }

    /**
     * @dev The Ether received will be logged with {PaymentReceived} events. Note that these events are not fully
     * reliable: it's possible for a contract to receive Ether without triggering this function. This only affects the
     * reliability of the events, and not the actual splitting of Ether.
     *
     * To learn more about this see the Solidity documentation for
     * https://solidity.readthedocs.io/en/latest/contracts.html#fallback-function[fallback
     * functions].
     */
    receive() external payable virtual {
        emit PaymentReceived(_msgSender(), msg.value);
    }

    /**
     * @dev Getter for the total shares held by payees.
     */
    function totalShares() public view returns (uint256) {
        return _calculateTotalShares();
    }

    /**
     * @dev Getter for the total amount of Ether already released.
     */
    function totalReleased() public view returns (uint256) {
        return _totalReleased;
    }

    /**
     * @dev calculate the total shares using offset (maxSupply_ * sharesPerToken_)
     * offset will be reduce until 0 once everyone claimed once
     *
     */
    function _calculateTotalShares() internal view returns (uint256) {
        return _totalShares + _totalSharesOffset;
    }

    /**
     * @dev Getter for the total amount of `token` already released. `token` should be the address of an IERC20
     * contract.
     */
    function totalReleased(IERC20 token) public view returns (uint256) {
        return _erc20TotalReleased[token];
    }

    /**
     * @dev Getter for the amount of shares held by an NFT tokenId.
     */
    function shares(uint256 tokenId) public view returns (uint256) {
        uint256 tokenShares = _shares[tokenId];
        // if shares are unitialized but within range return default allocation
        if (tokenShares == 0 && tokenId <= _maxSupply) {
            tokenShares = _sharesPerToken;
        }
        return tokenShares;
    }

    /**
     * @dev Getter for the amount of Ether already released to a payee (NFT tokenId).
     */
    function released(uint256 tokenId) public view returns (uint256) {
        return _released[tokenId];
    }

    /**
     * @dev Getter for the amount of `token` tokens already released to a payee (NFT tokenId). `token` should be the address of an
     * IERC20 contract.
     */
    function released(IERC20 token, uint256 tokenId)
        public
        view
        returns (uint256)
    {
        return _erc20Released[token][tokenId];
    }

    /**
     * @dev Triggers a transfer to `tokenId` holder of the amount of Ether they are owed, according to their percentage of the
     * total shares and their previous withdrawals.
     * Initializes payee (NFT tokenId) during first release
     */
    function release(uint256 tokenId) public virtual {
        require(
            tokenId <= _maxSupply || _isCreat00r(tokenId),
            "PaymentSplitter: tokenId is outside range"
        );
        if (_shares[tokenId] == 0) {
            _addPayee(tokenId, _sharesPerToken);
        }
        require(_shares[tokenId] > 0, "PaymentSplitter: tokenId has no shares");

        address payable account;
        if (_isCreat00r(tokenId)) {
            account = payable(_getCreat00r(tokenId));
        } else {
            account = payable(nftCollection.ownerOf(tokenId));
        }

        uint256 totalReceived = address(this).balance + totalReleased();
        uint256 payment = _pendingPayment(
            tokenId,
            totalReceived,
            released(tokenId)
        );

        require(payment != 0, "PaymentSplitter: tokenId is not due payment");

        _released[tokenId] += payment;
        _totalReleased += payment;

        Address.sendValue(account, payment);
        emit PaymentReleased(tokenId, account, payment);
    }

    /**
     * @dev Triggers a transfer to `tokenId` holder of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     * Initializes payee (NFT tokenId) during first release.
     */
    function release(IERC20 token, uint256 tokenId) public virtual {
        require(
            tokenId <= _maxSupply || _isCreat00r(tokenId),
            "PaymentSplitter: tokenId is outside range"
        );
        if (_shares[tokenId] == 0) {
            _addPayee(tokenId, _sharesPerToken);
        }
        require(_shares[tokenId] > 0, "PaymentSplitter: tokenId has no shares");

        address account;
        if (_isCreat00r(tokenId)) {
            account = _getCreat00r(tokenId);
        } else {
            account = nftCollection.ownerOf(tokenId);
        }

        uint256 totalReceived = token.balanceOf(address(this)) +
            totalReleased(token);
        uint256 payment = _pendingPayment(
            tokenId,
            totalReceived,
            released(token, tokenId)
        );

        require(payment != 0, "PaymentSplitter: tokenId is not due payment");

        _erc20Released[token][tokenId] += payment;
        _erc20TotalReleased[token] += payment;

        SafeERC20.safeTransfer(token, account, payment);
        emit ERC20PaymentReleased(tokenId, token, account, payment);
    }

    /**
     * @dev internal logic for computing the pending payment of an `account` given the token historical balances and
     * already released amounts.
     */
    function _pendingPayment(
        uint256 tokenId,
        uint256 totalReceived,
        uint256 alreadyReleased
    ) private view returns (uint256) {
        return
            (totalReceived * _shares[tokenId]) /
            _calculateTotalShares() -
            alreadyReleased;
    }

    /**
     * @dev Add a new payee to the contract.
     * reduce _totalSharesOffset for each tokenId until 0.
     * Only called once per tokenId/owner
     * @param tokenId nft tokenId
     * @param shares_ The number of shares owned by the payee.
     */
    function _addPayee(uint256 tokenId, uint256 shares_) private {
        require(
            tokenId <= _maxSupply || _isCreat00r(tokenId),
            "PaymentSplitter: tokenId must be < _maxSupply"
        );
        require(shares_ > 0, "PaymentSplitter: shares are 0");
        require(
            _shares[tokenId] == 0,
            "PaymentSplitter: tokenId already has shares"
        );

        _shares[tokenId] = shares_;
        _totalShares = _totalShares + shares_;
        if (!_isCreat00r(tokenId) && _totalSharesOffset - shares_ >= 0) {
            _totalSharesOffset = _totalSharesOffset - shares_;
        }
        emit PayeeAdded(tokenId, shares_);
    }

    function _isCreat00r(uint256 tokenId) internal pure returns (bool){
        return (tokenId == _creat00rId || tokenId == _dev1Id || tokenId == _dev2Id);
    }


    function _getCreat00r(uint256 tokenId) internal view returns (address){
        if(tokenId == _creat00rId) {
            return creat00rWallet; 
        }
        if(tokenId == _dev1Id) {
            return dev1Wallet; 
        }
        if(tokenId == _dev2Id) {
            return dev2Wallet; 
        }
        revert("Invalid creat00r tokenId");
    }

    function _setupCreat00rShares(uint256[] memory creat00rsShare_, address[] memory creat00rWallets_) internal {
        require(creat00rsShare_.length == creat00rWallets_.length);
        require(creat00rWallets_.length == 3);
 
        require(creat00rsShare_[0]>creat00rsShare_[1] && creat00rsShare_[0]>creat00rsShare_[2]);

        creat00rWallet = creat00rWallets_[0];
        _addPayee(_creat00rId, creat00rsShare_[0]);
        dev1Wallet = creat00rWallets_[1];
        _addPayee(_dev1Id, creat00rsShare_[1]);
        dev2Wallet = creat00rWallets_[2];
        _addPayee(_dev2Id, creat00rsShare_[2]);
    }

    /**
     * @notice
     *  function to update _creat00rAddress
     *  opensea ever shuts down or is compromised
     * @dev Only callable by the owner.
     * @param creat00rWallet_ nft tokenId
     */
    function setCreat00rAddress(address creat00rWallet_) external onlyOwner {
        require(creat00rWallet_ != address(0), "Zero Address not allowed");
        creat00rWallet = creat00rWallet_;
    }

    /**
     * @dev Triggers a transfer for `tokenIds` of the amount of Ether they are owed to creat00r, according to their percentage of the
     * total shares and their previous withdrawals.
     * Only allow payout if list of tokenIds does not exists (NFT's have not been minted)
     * (valid tokenIds's range 1-100)
     */
    function releaseUnlcaimed(uint256[] memory tokenIds) external onlyOwner {
        (bool success, bytes memory result) = address(nftCollection).call(abi.encodeWithSignature("claimExpiration()", msg.sender));
        uint claimExpiration = abi.decode(result, (uint));
        require(success && claimExpiration < block.timestamp, "nftCollection claim window still active");
        uint256 totalPayment = 0;
        bool isValidUnclaimedList = true;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenId <= 100, "Invalid claim id range[1,100]");
            try nftCollection.ownerOf(tokenId) {
                isValidUnclaimedList = false;
            } catch Error(
                string memory /*reason*/
            ) {
                if (_shares[tokenId] == 0) {
                    _addPayee(tokenId, _sharesPerToken);
                }
                require(_shares[tokenId] > 0, "PaymentSplitter: tokenId has no shares");
                uint256 totalReceived = address(this).balance + totalReleased() - totalPayment;
                uint256 payment = _pendingPayment(
                    tokenId,
                    totalReceived,
                    released(tokenId)
                );

                _released[tokenId] += payment;
                _totalReleased += payment;
                totalPayment += payment;
                emit UnclaimedPaymentReleased(
                    tokenId,
                    creat00rWallet,
                    payment
                );
            }
        }
        require(
            totalPayment != 0,
            "PaymentSplitter: tokenId is not due payment"
        );
        require(isValidUnclaimedList, "Invalid list of unclaimed token");
        Address.sendValue(payable(creat00rWallet), totalPayment);
    }


    /**
     * @dev Triggers a transfer for `tokenIds` of the amount of `token` tokens they are owed, according to their
     * percentage of the total shares and their previous withdrawals. `token` must be the address of an IERC20
     * contract.
     * Only allow payout if list of tokenIds does not exists (NFT's have not been minted).
     * (valid tokenIds's range 1-100)
     */
    function releaseUnlcaimed(IERC20 token, uint256[] memory tokenIds)
        external
        onlyOwner
    {   
        (bool success, bytes memory result) = address(nftCollection).call(abi.encodeWithSignature("claimExpiration()", msg.sender));
        uint claimExpiration = abi.decode(result, (uint));
        require(success && claimExpiration < block.timestamp, "nftCollection claim window still active");
        uint256 totalPayment = 0;
        bool isValidUnclaimedList = true;
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(tokenId <= 100, "Invalid claim id range[1,100]");
            try nftCollection.ownerOf(tokenId) {
                isValidUnclaimedList = false;
            } catch Error(
                string memory /*reason*/
            ) {
                if (_shares[tokenId] == 0) {
                    _addPayee(tokenId, _sharesPerToken);
                }
                uint256 totalReceived = token.balanceOf(address(this)) + totalReleased(token) - totalPayment;
                uint256 payment = _pendingPayment(
                    tokenId,
                    totalReceived,
                    released(token, tokenId)
                );

                //skip update storage since we have nothing to pay
                _erc20Released[token][tokenId] += payment;
                _erc20TotalReleased[token] += payment;
                totalPayment += payment;
                emit UnclaimedERC20PaymentReleased(
                    tokenId,
                    token,
                    creat00rWallet,
                    payment
                );
            }
        }
        require(
            totalPayment != 0,
            "PaymentSplitter: account is not due payment"
        );
        require(isValidUnclaimedList, "List contains existing tokenIds");
        SafeERC20.safeTransfer(token, creat00rWallet, totalPayment);
    }
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
// OpenZeppelin Contracts v4.4.1 (token/ERC721/IERC721.sol)

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
// OpenZeppelin Contracts v4.4.1 (utils/Address.sol)

pragma solidity ^0.8.0;

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
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165Checker.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Library used to query support of an interface declared via {IERC165}.
 *
 * Note that these functions return the actual result of the query: they do not
 * `revert` if an interface is not supported. It is up to the caller to decide
 * what to do in these cases.
 */
library ERC165Checker {
    // As per the EIP-165 spec, no interface should ever match 0xffffffff
    bytes4 private constant _INTERFACE_ID_INVALID = 0xffffffff;

    /**
     * @dev Returns true if `account` supports the {IERC165} interface,
     */
    function supportsERC165(address account) internal view returns (bool) {
        // Any contract that implements ERC165 must explicitly indicate support of
        // InterfaceId_ERC165 and explicitly indicate non-support of InterfaceId_Invalid
        return
            _supportsERC165Interface(account, type(IERC165).interfaceId) &&
            !_supportsERC165Interface(account, _INTERFACE_ID_INVALID);
    }

    /**
     * @dev Returns true if `account` supports the interface defined by
     * `interfaceId`. Support for {IERC165} itself is queried automatically.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsInterface(address account, bytes4 interfaceId) internal view returns (bool) {
        // query support of both ERC165 as per the spec and support of _interfaceId
        return supportsERC165(account) && _supportsERC165Interface(account, interfaceId);
    }

    /**
     * @dev Returns a boolean array where each value corresponds to the
     * interfaces passed in and whether they're supported or not. This allows
     * you to batch check interfaces for a contract where your expectation
     * is that some interfaces may not be supported.
     *
     * See {IERC165-supportsInterface}.
     *
     * _Available since v3.4._
     */
    function getSupportedInterfaces(address account, bytes4[] memory interfaceIds)
        internal
        view
        returns (bool[] memory)
    {
        // an array of booleans corresponding to interfaceIds and whether they're supported or not
        bool[] memory interfaceIdsSupported = new bool[](interfaceIds.length);

        // query support of ERC165 itself
        if (supportsERC165(account)) {
            // query support of each interface in interfaceIds
            for (uint256 i = 0; i < interfaceIds.length; i++) {
                interfaceIdsSupported[i] = _supportsERC165Interface(account, interfaceIds[i]);
            }
        }

        return interfaceIdsSupported;
    }

    /**
     * @dev Returns true if `account` supports all the interfaces defined in
     * `interfaceIds`. Support for {IERC165} itself is queried automatically.
     *
     * Batch-querying can lead to gas savings by skipping repeated checks for
     * {IERC165} support.
     *
     * See {IERC165-supportsInterface}.
     */
    function supportsAllInterfaces(address account, bytes4[] memory interfaceIds) internal view returns (bool) {
        // query support of ERC165 itself
        if (!supportsERC165(account)) {
            return false;
        }

        // query support of each interface in _interfaceIds
        for (uint256 i = 0; i < interfaceIds.length; i++) {
            if (!_supportsERC165Interface(account, interfaceIds[i])) {
                return false;
            }
        }

        // all interfaces supported
        return true;
    }

    /**
     * @notice Query if a contract implements an interface, does not check ERC165 support
     * @param account The address of the contract to query for support of an interface
     * @param interfaceId The interface identifier, as specified in ERC-165
     * @return true if the contract at account indicates support of the interface with
     * identifier interfaceId, false otherwise
     * @dev Assumes that account contains a contract that supports ERC165, otherwise
     * the behavior of this method is undefined. This precondition can be checked
     * with {supportsERC165}.
     * Interface identification is specified in ERC-165.
     */
    function _supportsERC165Interface(address account, bytes4 interfaceId) private view returns (bool) {
        bytes memory encodedParams = abi.encodeWithSelector(IERC165.supportsInterface.selector, interfaceId);
        (bool success, bytes memory result) = account.staticcall{gas: 30000}(encodedParams);
        if (result.length < 32) return false;
        return success && abi.decode(result, (bool));
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

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
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

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