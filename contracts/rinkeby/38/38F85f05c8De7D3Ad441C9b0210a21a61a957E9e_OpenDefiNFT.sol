// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "./ERC1155MintableAndBurnable.sol";

contract OpenDefiNFT is ERC1155MintableAndBurnable {
    // stores NFT name
    string public name;
    // stores NFT symbol
    string public symbol;

    /**
     * @dev To call the function which initialises the nft and insurance token details.
     */
    function __OpenDefiNFT_init(
        string memory _uri,
        string memory _name,
        string memory _symbol,
        address[] memory _backedAssets,
        address owner,
        address _exchangeAddress
    ) external initializer {
        __ERC1155_init(_uri, owner);

        for (uint256 index = 0; index < _backedAssets.length; index++) {
            require(_backedAssets[index] != address(0), "Invalid  address  ");
            backedAssets[index] = _backedAssets[index];
        }
        backedAssetID = _backedAssets.length;

        name = _name;
        symbol = _symbol;
        collectionFactory = msg.sender;
        exchangeAddress = _exchangeAddress;
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;
pragma abicoder v2;

import "./ERC1155BackedAsset.sol";
import "../royalties/Royalties.sol";
import "../interfaces/IExchange.sol";

contract ERC1155MintableAndBurnable is ERC1155BackedAsset, Royalties {
    using SafeMathUpgradeable for uint256;
    using SafeERC20Upgradeable for IERC20Upgradeable;

    // Struct to store the NFT mint details
    struct Mint1155Data {
        uint256 tokenId;
        bytes tokenURI;
        uint256 supply;
        uint256[] backedAssetList;
        uint256[] nftPrices;
        LibPart.Part[] creators;
        LibPart.Part[] royalties;
    }

    // Mapping from token id to supply
    mapping(uint256 => uint256) private supply;
    // Mapping from token id to backed asset amounts
    mapping(uint256 => uint256[]) private backedAssetAmounts;
    // Mapping from token id to creators
    mapping(uint256 => LibPart.Part[]) public creators;

    /**
     * @dev Creates amount tokens of token type id, and assigns them to account.
     *
     *
     * Requirements:
     *
     * - `amount` cannot be less than or equal to zero.
     */
    function mint(Mint1155Data memory data) external whenNotPaused onlyOwner {
        Mint1155Data[] memory datum = new Mint1155Data[](1);
        datum[0] = data;
        _mintWithAsset(datum);
    }

    function mintBatch(Mint1155Data[] memory data)
        external
        whenNotPaused
        onlyOwner
    {
        _mintWithAsset(data);
    }

    function _mintWithAsset(Mint1155Data[] memory data) internal {
        for (uint256 index = 0; index < data.length; index++) {
            require(data[index].supply > 0, "amount  incorrect");

            if (supply[data[index].tokenId] == 0) {
                require(data[index].supply > 0, "supply incorrect  ");

                _saveSupply(data[index].tokenId, data[index].supply);
                _saveCreators(data[index].tokenId, data[index].creators);
                IExchange(exchangeAddress).saveNFTLaunchPrice(
                    data[index].tokenId,
                    data[index].nftPrices
                );
                _saveRoyalties(data[index].tokenId, data[index].royalties);
                _saveBackedAssets(
                    data[index].tokenId,
                    data[index].supply,
                    data[index].backedAssetList
                );
            } else {
                _saveSupply(
                    data[index].tokenId,
                    data[index].supply.add(supply[data[index].tokenId])
                );

                for (
                    uint256 innerIndex = 0;
                    innerIndex < data[index].backedAssetList.length;
                    innerIndex++
                ) {
                    uint256 amountReceived = _transferBackedAsset(
                        msg.sender,
                        address(this),
                        innerIndex,
                        data[index].backedAssetList[innerIndex].mul(
                            data[index].supply
                        )
                    );

                    require(
                        amountReceived >=
                            backedAssetAmounts[data[index].tokenId][innerIndex],
                        "Not enough tokens received"
                    );
                }
            }

            _mint(
                exchangeAddress,
                data[index].tokenId,
                data[index].supply,
                data[index].tokenURI
            );
        }
    }

    /**
     * @dev The function will burn the NFT token and reimburse the backed ERC 20 tokens.
     * The function will revert if burns are paused
     */
    function burn(uint256 id, uint256 amount)
        external
        whenBurnNotPaused
        whenNotPaused
    {
        _burnWithAssets(
            _asSingletonArray(_msgSender()),
            _asSingletonArray(id),
            _asSingletonArray(amount)
        );
    }

    /**
     * @dev The function will burn the NFT token and reimburse the backed ERC 20 tokens.
     * The function will revert if burns are paused
     */
    function forceBurn(
        address[] memory from,
        uint256[] memory id,
        uint256[] memory amount
    ) external onlyOwner {
        _burnWithAssets(from, id, amount);
    }

    function burnFromExchange(uint256[] memory id, uint256[] memory amount)
        external
        onlyOwner
    {
        _burnWithAssets(_asSingletonArray(exchangeAddress), id, amount);
    }

    /**
     * @dev The function will burn the NFT token and reimburse the backed ERC 20 tokens.
     * The function will revert if burns are paused
     */
    function burnBatch(uint256[] memory ids, uint256[] memory amounts)
        external
        whenBurnNotPaused
        whenNotPaused
    {
        _burnWithAssets(_asSingletonArray(_msgSender()), ids, amounts);
    }

    function _burnWithAssets(
        address[] memory from,
        uint256[] memory ids,
        uint256[] memory amount
    ) internal {
        for (uint256 index = 0; index < ids.length; index++) {
            address _account = from[0];
            if (from.length != 1) _account = from[index];
            require(supply[ids[index]] >= amount[index], "No Token exist");
            require(
                balanceOf(_account, ids[index]) >= amount[index],
                "Not enough balance"
            );

            _saveSupply(ids[index], supply[ids[index]].sub(amount[index]));

            uint256[] memory assets = backedAssetAmounts[ids[index]];

            for (
                uint256 innerIndex = 0;
                innerIndex < assets.length;
                innerIndex++
            ) {
                _transferBackedAsset(
                    address(this),
                    _account,
                    innerIndex,
                    assets[innerIndex].mul(amount[index])
                );
            }

            _burn(_account, ids[index], amount[index]);
        }
    }

    /**
     * @dev The function will save the backed asset detials of respective NFT token
     *
     * Requirements:
     * Number of backed asset passed should be equal to the initial backed asset count.
     */
    function _saveBackedAssets(
        uint256 _id,
        uint256 _amount,
        uint256[] memory _backedAssetList
    ) internal {
        require(
            _backedAssetList.length == backedAssetID,
            "invalid asset list length"
        );

        for (uint256 index = 0; index < _backedAssetList.length; index++) {
            uint256 amountReceived = _transferBackedAsset(
                msg.sender,
                address(this),
                index,
                _backedAssetList[index].mul(_amount)
            );

            backedAssetAmounts[_id].push(amountReceived.div(_amount));
        }
    }

    /**
     * @dev To call function which will add backed assets
     *
     * Requirements:
     * Caller should be owner
     */
    function addBackedAssets(
        address asset,
        uint256[] memory tokenIds,
        uint256[] memory amounts
    ) external onlyOwner whenNotPaused {
        require(asset != address(0), "Invalid address");
        require(tokenIds.length == amounts.length, "Invalid address");

        backedAssets[backedAssetID] = asset;
        backedAssetID = backedAssetID.add(1);

        for (uint256 index = 0; index < tokenIds.length; index++) {
            uint256 _supply = supply[tokenIds[index]];
            uint256 amountReceived = _transferERC(
                msg.sender,
                address(this),
                asset,
                amounts[index].mul(_supply)
            );
            backedAssetAmounts[tokenIds[index]].push(
                amountReceived.div(_supply)
            );
        }
    }

    /**
     * @dev Function to save the total supply of NFT
     */
    function _saveSupply(uint256 tokenId, uint256 _supply) internal {
        //require(supply[tokenId] == 0, "Value not zero");
        supply[tokenId] = _supply;
    }

    /**
     * @dev This function is used to save the creator details of each NFT
     *
     * Requirements:
     * Creator account address should not be a null address
     * Creator share should be greater than zero.
     * Total amount of creators share should be 10000
     */
    function _saveCreators(uint256 tokenId, LibPart.Part[] memory _creators)
        internal
    {
        LibPart.Part[] storage creatorsOfToken = creators[tokenId];
        uint256 total = 0;
        for (uint256 i = 0; i < _creators.length; i++) {
            require(
                _creators[i].account != address(0x0),
                "Account should be present"
            );
            require(
                _creators[i].value != 0,
                "Creator share should be positive"
            );
            creatorsOfToken.push(_creators[i]);
            total = total.add(_creators[i].value);
        }
        require(
            total == 10000,
            "total amount of creators share should be 10000"
        );
    }

    /**
     * @dev Function to fetch the creator details of particular NFT
     *
     */
    function getCreators(uint256 _id)
        external
        view
        returns (LibPart.Part[] memory)
    {
        return creators[_id];
    }

    /**
     * @dev Function to retrieve the supply data
     *
     */
    function getSupply(uint256 tokenId) external view returns (uint256) {
        return supply[tokenId];
    }

    /**
     * @dev Function to fetch the backed asset amounts.
     *
     */
    function getBackedAssetAmounts(uint256 _id)
        external
        view
        returns (uint256[] memory)
    {
        return backedAssetAmounts[_id];
    }

    /**
     * @dev To call functions which will add creator and royalty data
     *
     * Requirements:
     * Caller should be owner
     */
    function addCreatorsOrRoyalties(Mint1155Data memory data)
        external
        onlyOwner
        whenNotPaused
    {
        _saveCreators(data.tokenId, data.creators);
        _saveRoyalties(data.tokenId, data.royalties);
    }

    /**
     * @dev To call function which will update royalty account data
     *
     * Requirements:
     * Caller should be owner
     */
    function updateRoyaltyAccount(
        uint256 _id,
        address _from,
        address _to
    ) external onlyOwner whenNotPaused {
        _updateAccount(_id, _from, _to);
    }

    /**
     * @dev To call function which will update creator account data
     *
     * Requirements:
     * Caller should be owner
     */
    function updateCreatorAccount(
        uint256 _id,
        address _from,
        address _to
    ) external onlyOwner whenNotPaused {
        uint256 length = creators[_id].length;
        for (uint256 i = 0; i < length; i++) {
            if (creators[_id][i].account == _from) {
                creators[_id][i].account = payable(_to);
            }
        }
    }

    function updateBackedAssetAmount(
        uint256[] memory _ids,
        uint256[] memory _backedAssetAmount,
        uint256 _assetId
    ) external onlyOwner whenNotPaused {
        require(_backedAssetAmount.length == _ids.length, "Lengths unequal");

        uint256 toTransfer;
        for (uint256 index = 0; index < _ids.length; index++) {
            require(supply[_ids[index]] > 0, "NFT do not exist");

            uint256 initialAmount = 0;
            if (backedAssetAmounts[_ids[index]].length > _assetId)
                initialAmount = backedAssetAmounts[_ids[index]][_assetId];

            require(_backedAssetAmount[index] != initialAmount, "No change");

            if (initialAmount < _backedAssetAmount[index]) {
                uint256 amountReceived = _transferBackedAsset(
                    msg.sender,
                    address(this),
                    _assetId,
                    (_backedAssetAmount[index].sub(initialAmount)).mul(
                        supply[_ids[index]]
                    )
                ).div(supply[_ids[index]]);

                if (backedAssetAmounts[_ids[index]].length > _assetId) {
                    backedAssetAmounts[_ids[index]][_assetId] = amountReceived;
                } else {
                    backedAssetAmounts[_ids[index]].push(amountReceived);
                }
            } else {
                toTransfer = toTransfer
                    .add(initialAmount.sub(_backedAssetAmount[index]))
                    .mul(supply[_ids[index]]);

                backedAssetAmounts[_ids[index]][_assetId] = _backedAssetAmount[
                    index
                ];
            }
        }

        if (toTransfer > 0) {
            _transferBackedAsset(
                address(this),
                msg.sender,
                _assetId,
                toTransfer
            );
        }
    }

    function safeWithdrawBackedAsset() external onlyOwner {
        for (uint256 index = 0; index < backedAssetID; index++) {
            _transferBackedAsset(
                address(this),
                owner(),
                index,
                IERC20Upgradeable(backedAssets[index]).balanceOf(address(this))
            );
        }
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "./ERC1155Upgradeable.sol";

contract ERC1155BackedAsset is ERC1155Upgradeable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using SafeMathUpgradeable for uint256;

    // Storage variable to store the backed asset id.
    uint256 public backedAssetID;
    // Mapping from token id to backed asset address.
    mapping(uint256 => address) public backedAssets;

    // Event Emitted when a backed asset is updated.
    event AssetUpdated(uint256 id, address indexed newAddress);
    // Event emitted when an asset is blocked.
    event AssetBlocked(uint256 id);

    /**
     @dev It updates the backed asset address.
     @dev If the backed asset is paused or hacked due to some reason, it will impact the NFTs
     @dev hence to avoid this, the token address can be replaced with new address.
     */

    function updateBackedAsset(
        uint256 assetId,
        uint256 toTransfer,
        address assetAddress,
        address withdrawTo
    ) external whenNotPaused onlyOwner {
        address oldAddress = backedAssets[assetId];

        require(assetId < backedAssetID, "Invalid id ");
        require(assetAddress != address(0), "zero  address");

        backedAssets[assetId] = assetAddress;

        uint256 balanceNeeded = 0;
        if (oldAddress != address(0))
            balanceNeeded = IERC20Upgradeable(oldAddress).balanceOf(
                address(this)
            );

        if (balanceNeeded > 0) {
            if (withdrawTo != address(0))
                IERC20Upgradeable(oldAddress).safeTransfer(
                    withdrawTo,
                    balanceNeeded
                );

            // to ensure deflationary tokens do not affect backed asset calculations
            uint256 amountReceived = _transferBackedAsset(
                msg.sender,
                address(this),
                assetId,
                toTransfer
            );

            require(
                amountReceived >= balanceNeeded,
                "Not enough amount received"
            );
        }

        emit AssetUpdated(assetId, assetAddress);
    }

    /**
     * @dev It will freeze the backed asset of each NFT by transferring to owners address.
     * @dev Emits the event with the Asset Id as data.
     */
    function blockBackedAsset(uint256 assetId, address withdrawTo)
        external
        whenNotPaused
        onlyOwner
    {
        require(assetId < backedAssetID, "Invalid ID");

        address oldAddress = backedAssets[assetId];
        require(oldAddress != address(0), "Already blocked");

        backedAssets[assetId] = address(0);

        if (withdrawTo != address(0))
            IERC20Upgradeable(oldAddress).safeTransfer(
                withdrawTo,
                IERC20Upgradeable(oldAddress).balanceOf(address(this))
            );

        emit AssetBlocked(assetId);
    }

    /**
     * @dev function will transfer specified backed asset token while minting the new NFT by the owner.
     * Asset token address should be valid
     * Transfer amount should be greater than zero
     * Backed Asset amounts are transfered.
     */
    function _transferBackedAsset(
        address _from,
        address _to,
        uint256 _assetId,
        uint256 _amount
    ) internal returns (uint256 amount) {
        require(_assetId < backedAssetID, "Invalid asset id");

        address _asset = backedAssets[_assetId];
        if (_asset == address(0)) return 0;

        amount = _transferERC(_from, _to, _asset, _amount);
    }

    /**
     * @dev function will transfer specified backed asset token while minting the new NFT by the owner.
     * Asset token address should be valid
     * Transfer amount should be greater than zero
     * Backed Asset amounts are transfered.
     */
    function _transferERC(
        address _from,
        address _to,
        address _asset,
        uint256 _amount
    ) internal returns (uint256 amount) {
        if (_asset == address(0)) return 0;
        if (_amount == 0) return 0;

        uint256 initialBalance = IERC20Upgradeable(_asset).balanceOf(_to);
        if (_from == address(this)) {
            IERC20Upgradeable(_asset).safeTransfer(_to, _amount);
        } else IERC20Upgradeable(_asset).safeTransferFrom(_from, _to, _amount);

        uint256 finalBalance = IERC20Upgradeable(_asset).balanceOf(_to);
        amount = finalBalance.sub(initialBalance);
    }

    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma abicoder v2;

import "./AbstractRoyalties.sol";
import "../interfaces/IRoyalties.sol";
import "../interfaces/IERC2981.sol";

contract Royalties is AbstractRoyalties, IRoyalties, IERC2981 {
    /*
     * @notice return royalty details for the provide token id.
     */
    function getRoyalties(uint256 id)
        external
        view
        override
        returns (LibPart.Part[] memory)
    {
        return royalties[id];
    }

    /*
     * @notice emits RoyalitiesSet event, called by _saveRoyalties()
     * can be updated to include additional logic which should go with this function
     */
    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties)
        internal
        override
    {
        emit RoyaltiesSet(id, _royalties);
    }

    /*
     *Token (ERC721, ERC721Minimal, ERC721MinimalMeta, ERC1155 ) can have a number of different royalties beneficiaries
     *calculate sum all royalties, but royalties beneficiary will be only one royalties[0].account, according to rules of IERC2981
     */
    function royaltyInfo(uint256 id, uint256 _salePrice)
        external
        view
        override
        returns (address receiver, uint256 royaltyAmount)
    {
        if (royalties[id].length == 0) {
            receiver = address(0);
            royaltyAmount = 0;
            return (receiver, royaltyAmount);
        }
        LibPart.Part[] memory _royalties = royalties[id];
        receiver = _royalties[0].account;
        uint256 percent;
        for (uint256 i = 0; i < _royalties.length; i++) {
            percent += _royalties[i].value;
        }
        //don`t need require(percent < 10000, "Token royalty > 100%"); here, because check later in calculateRoyalties
        royaltyAmount = (percent * _salePrice) / 10000;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @dev Interface for the Exchange
interface IExchange {
    function __OpenDefiExchange_init(
        bool _isPrivateCollection,
        address _collection,
        address _insuranceToken,
        address _owner,
        uint256 _insuranceInterval,
        uint256 _insurancePrice,
        uint256[] memory _feeConfig,
        address[] memory _feeTokens
    ) external;

    /**
     * @dev function allows the buyers to puchase nft from a list of options.
     * Appropriate Fee is calculated and added to the purchase.
     * Minimum protection date period is calculated and added to each NFT purchases.
     */
    function buyNFT(
        address buyer,
        uint256 amount,
        uint256 tokenId,
        uint256 feeTokenId,
        bool isInsured,
        bytes memory data
    ) external;

    /**
     * @dev Function to save the initial NFT price
     *
     * Requirements:
     * The number price passed should be equal to the fee token id.
     */
    function saveNFTLaunchPrice(uint256 _id, uint256[] memory _nftPrice)
        external;

    /**
     * @dev Function to get the NFT price
     *
     */
    function getNFTPrice(uint256 _id) external view returns (uint256[] memory);

    /**
     * @dev To update the NFT prices '_nftPrice'
     *
     * Requirements:
     * Caller should be owner
     * token id og nft should be valid
     * fee token id should be valid
     */
    function updateNFTPrice(
        uint256 _id,
        uint256 feeTokenId,
        uint256 _nftPrice
    ) external;

    /**
     * @dev Buyer can redeem the NFT which was bought before.
     * The contract not be paused for burn.
     * The buyer should have posses the token inorder to redeem it.
     */
    function redeemNFT(
        address buyer,
        uint256 amount,
        uint256 tokenId,
        uint256 purchaseId,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20Upgradeable.sol";
import "../../../utils/AddressUpgradeable.sol";

/**
 * @title SafeERC20
 * @dev Wrappers around ERC20 operations that throw on failure (when the token
 * contract returns false). Tokens that return no value (and instead revert or
 * throw on failure) are also supported, non-reverting calls are assumed to be
 * successful.
 * To use this library you can add a `using SafeERC20 for IERC20;` statement to your contract,
 * which allows you to call the safe operations as `token.safeTransfer(...)`, etc.
 */
library SafeERC20Upgradeable {
    using AddressUpgradeable for address;

    function safeTransfer(
        IERC20Upgradeable token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
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
        IERC20Upgradeable token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(
        IERC20Upgradeable token,
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
    function _callOptionalReturn(IERC20Upgradeable token, bytes memory data) private {
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

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC1155/IERC1155ReceiverUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/introspection/ERC165Upgradeable.sol";
import "./TokenPausableUpgradeable.sol";

/**
 *
 * @dev Implementation of the basic standard multi-token.
 * See https://eips.ethereum.org/EIPS/eip-1155
 * Originally based on code by Enjin: https://github.com/enjin/erc-1155
 *
 * _Available since v3.1._
 */
contract ERC1155Upgradeable is
    ERC165Upgradeable,
    TokenPausableUpgradeable,
    IERC1155Upgradeable
{
    using SafeMathUpgradeable for uint256;
    using AddressUpgradeable for address;

    // Mapping from token ID to account balances
    mapping(uint256 => mapping(address => uint256)) internal _balances;

    // Mapping from account to operator approvals
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    mapping(address => uint256) public totalHoldings;

    uint256 public nftHoldersLimit;

    // Used as the URI for all token types by relying on ID substitution, e.g. https://token-cdn-domain/{id}.json
    string private _uri;

    /**
     * @dev See {_setURI}.
     */
    function __ERC1155_init(string memory uri_, address owner_) internal {
        __Ownable_init();
        _setURI(uri_);
        _transferOwnership(owner_);
    }

    /**
     * @dev See {IERC1155MetadataURI-uri}.
     *
     * This implementation returns the same URI for *all* token types. It relies
     * on the token type ID substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * Clients calling this function must replace the `\{id\}` substring with the
     * actual token type ID.
     */
    function uri(uint256) external view returns (string memory) {
        return _uri;
    }

    /// @notice Updates the URI of the NFT with latest passed value..
    /**
     * @dev The function will replace the alreay existing value of the URI with newly passed value.
     * Burn functionality must be paused before
     */
    function updateURI(string memory newuri) external onlyOwner {
        _setURI(newuri);
    }

    /// @notice Updates the NFT holder limit
    /**
     * @dev The function will replace the alreay existing value of the nft holder limit
     */
    function updateNFTHolderLimit(uint256 newLimit) external onlyOwner {
        nftHoldersLimit = newLimit;
    }

    /**
     * @dev See {IERC1155-balanceOf}.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     */
    function balanceOf(address account, uint256 id)
        public
        view
        virtual
        override
        returns (uint256)
    {
        require(account != address(0), "balance query for the zero address");
        return _balances[id][account];
    }

    /**
     * @dev See {IERC1155-balanceOfBatch}.
     *
     * Requirements:
     *
     * - `accounts` and `ids` must have the same length.
     */
    function balanceOfBatch(address[] memory accounts, uint256[] memory ids)
        public
        view
        virtual
        override
        returns (uint256[] memory)
    {
        require(
            accounts.length == ids.length,
            "accounts and ids length mismatch"
        );

        uint256[] memory batchBalances = new uint256[](accounts.length);

        for (uint256 i = 0; i < accounts.length; ++i) {
            batchBalances[i] = balanceOf(accounts[i], ids[i]);
        }

        return batchBalances;
    }

    /**
     * @dev See {IERC1155-setApprovalForAll}.
     */
    function setApprovalForAll(address operator, bool approved)
        public
        virtual
        override
    {
        require(
            _msgSender() != operator,
            "setting  approval status fo  r self"
        );

        _operatorApprovals[_msgSender()][operator] = approved;
        emit ApprovalForAll(_msgSender(), operator, approved);
    }

    /**
     * @dev See {IERC1155-isApprovedForAll}.
     */
    function isApprovedForAll(address account, address operator)
        public
        view
        virtual
        override
        returns (bool)
    {
        return _operatorApprovals[account][operator];
    }

    /**
     * @dev See {IERC1155-safeTransferFrom}.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public virtual override whenTransferNotPaused {
        require(to != address(0), "transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            from,
            to,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][from] = _balances[id][from].sub(
            amount,
            "insufficient balance for transfer"
        );
        _balances[id][to] = _balances[id][to].add(amount);

        totalHoldings[from] = totalHoldings[from].sub(amount);
        totalHoldings[to] = totalHoldings[to].add(amount);

        emit TransferSingle(operator, from, to, id, amount);

        _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    /**
     * @dev See {IERC1155-safeBatchTransferFrom}.
     */
    function safeBatchTransferFrom(
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public virtual override whenTransferNotPaused {
        require(
            ids.length == amounts.length,
            "ids and amounts length mismatch"
        );
        require(to != address(0), "transfer to the zero address");
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "transfer caller is not owner nor approved"
        );

        address operator = _msgSender();

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        for (uint256 i = 0; i < ids.length; ++i) {
            uint256 id = ids[i];
            uint256 amount = amounts[i];

            _balances[id][from] = _balances[id][from].sub(
                amount,
                "insufficient balance for transfer"
            );
            _balances[id][to] = _balances[id][to].add(amount);

            totalHoldings[from] = totalHoldings[from].sub(amount);
            totalHoldings[to] = totalHoldings[to].add(amount);
        }

        emit TransferBatch(operator, from, to, ids, amounts);

        _doSafeBatchTransferAcceptanceCheck(
            operator,
            from,
            to,
            ids,
            amounts,
            data
        );
    }

    /**
     * @dev Sets a new URI for all token types, by relying on the token type ID
     * substitution mechanism
     * https://eips.ethereum.org/EIPS/eip-1155#metadata[defined in the EIP].
     *
     * By this mechanism, any occurrence of the `\{id\}` substring in either the
     * URI or any of the amounts in the JSON file at said URI will be replaced by
     * clients with the token type ID.
     *
     * For example, the `https://token-cdn-domain/\{id\}.json` URI would be
     * interpreted by clients as
     * `https://token-cdn-domain/000000000000000000000000000000000000000000000000000000000004cce0.json`
     * for token type ID 0x4cce0.
     *
     * See {uri}.
     *
     * Because these URIs cannot be meaningfully represented by the {URI} event,
     * this function emits no events.
     */
    function _setURI(string memory newuri) internal virtual {
        _uri = newuri;
    }

    /**
     * @dev Creates `amount` tokens of token type `id`, and assigns them to `account`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - If `account` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function _mint(
        address account,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual {
        require(account != address(0), "mint to the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            address(0),
            account,
            _asSingletonArray(id),
            _asSingletonArray(amount),
            data
        );

        _balances[id][account] = _balances[id][account].add(amount);
        totalHoldings[account] = totalHoldings[account].add(amount);

        emit TransferSingle(operator, address(0), account, id, amount);

        _doSafeTransferAcceptanceCheck(
            operator,
            address(0),
            account,
            id,
            amount,
            data
        );
    }

    /**
     * @dev Destroys `amount` tokens of token type `id` from `account`
     *
     * Requirements:
     *
     * - `account` cannot be the zero address.
     * - `account` must have at least `amount` tokens of token type `id`.
     */
    function _burn(
        address account,
        uint256 id,
        uint256 amount
    ) internal virtual whenBurnNotPaused {
        require(account != address(0), "burn from the zero address");

        address operator = _msgSender();

        _beforeTokenTransfer(
            operator,
            account,
            address(0),
            _asSingletonArray(id),
            _asSingletonArray(amount),
            ""
        );

        _balances[id][account] = _balances[id][account].sub(
            amount,
            "burn amount exceeds balance"
        );

        totalHoldings[account] = totalHoldings[account].sub(amount);

        emit TransferSingle(operator, account, address(0), id, amount);
    }

    /**
     * @dev Hook that is called before any token transfer. This includes minting
     * and burning, as well as batched variants.
     *
     * The same hook is called on both single and batched variants. For single
     * transfers, the length of the `id` and `amount` arrays will be 1.
     *
     * Calling conditions (for each `id` and `amount` pair):
     *
     * - When `from` and `to` are both non-zero, `amount` of ``from``'s tokens
     * of token type `id` will be  transferred to `to`.
     * - When `from` is zero, `amount` tokens of token type `id` will be minted
     * for `to`.
     * - when `to` is zero, `amount` of ``from``'s tokens of token type `id`
     * will be burned.
     * - `from` and `to` are never both zero.
     * - `ids` and `amounts` have the same, non-zero length.
     *
     * To learn more about hooks, head to xref:ROOT:extending-contracts.adoc#using-hooks[Using Hooks].
     */
    function _beforeTokenTransfer(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) internal whenTransferNotPaused {
        uint256 totalAmounts = 0;
        for (uint256 index = 0; index < amounts.length; index++) {
            totalAmounts = totalAmounts.add(amounts[index]);
        }

        require(
            nftHoldersLimit == 0 ||
                totalHoldings[to].add(totalAmounts) < nftHoldersLimit,
            "cannot hold more NFTs"
        );
    }

    function _doSafeTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155Received(
                    operator,
                    from,
                    id,
                    amount,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155ReceiverUpgradeable(to).onERC1155Received.selector
                ) {
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _doSafeBatchTransferAcceptanceCheck(
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) private {
        if (to.isContract()) {
            try
                IERC1155ReceiverUpgradeable(to).onERC1155BatchReceived(
                    operator,
                    from,
                    ids,
                    amounts,
                    data
                )
            returns (bytes4 response) {
                if (
                    response !=
                    IERC1155ReceiverUpgradeable(to)
                        .onERC1155BatchReceived
                        .selector
                ) {
                    revert("ERC1155Receiver rejected tokens");
                }
            } catch Error(string memory reason) {
                revert(reason);
            } catch {
                revert("transfer to non ERC1155Receiver implementer");
            }
        }
    }

    function _asSingletonArray(uint256 element)
        internal
        pure
        returns (uint256[] memory array)
    {
        array = new uint256[](1);
        array[0] = element;
    }

    function _asSingletonArray(address element)
        internal
        pure
        returns (address[] memory array)
    {
        array = new address[](1);
        array[0] = element;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId)
        public
        view
        virtual
        override(ERC165Upgradeable, IERC165Upgradeable)
        returns (bool)
    {
        return
            interfaceId == type(IERC1155Upgradeable).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    uint256[47] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155Upgradeable is IERC165Upgradeable {
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
     * - If the caller is not `from`, it must be have been approved to spend ``from``'s tokens via {setApprovalForAll}.
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
// OpenZeppelin Contracts v4.4.1 (utils/math/SafeMath.sol)

pragma solidity ^0.8.0;

// CAUTION
// This version of SafeMath should only be used with Solidity 0.8 or later,
// because it relies on the compiler's built in overflow checks.

/**
 * @dev Wrappers over Solidity's arithmetic operations.
 *
 * NOTE: `SafeMath` is generally not needed starting with Solidity 0.8, since the compiler
 * now has built in overflow checking.
 */
library SafeMathUpgradeable {
    /**
     * @dev Returns the addition of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryAdd(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            uint256 c = a + b;
            if (c < a) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the substraction of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function trySub(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b > a) return (false, 0);
            return (true, a - b);
        }
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, with an overflow flag.
     *
     * _Available since v3.4._
     */
    function tryMul(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
            // benefit is lost if 'b' is also tested.
            // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
            if (a == 0) return (true, 0);
            uint256 c = a * b;
            if (c / a != b) return (false, 0);
            return (true, c);
        }
    }

    /**
     * @dev Returns the division of two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryDiv(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a / b);
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers, with a division by zero flag.
     *
     * _Available since v3.4._
     */
    function tryMod(uint256 a, uint256 b) internal pure returns (bool, uint256) {
        unchecked {
            if (b == 0) return (false, 0);
            return (true, a % b);
        }
    }

    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator.
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {trySub}.
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b <= a, errorMessage);
            return a - b;
        }
    }

    /**
     * @dev Returns the integer division of two unsigned integers, reverting with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a / b;
        }
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * reverting with custom message when dividing by zero.
     *
     * CAUTION: This function is deprecated because it requires allocating memory for the error
     * message unnecessarily. For custom revert reasons use {tryMod}.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
        unchecked {
            require(b > 0, errorMessage);
            return a % b;
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/IERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../../utils/introspection/IERC165Upgradeable.sol";

/**
 * @dev _Available since v3.1._
 */
interface IERC1155ReceiverUpgradeable is IERC165Upgradeable {
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
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "../../proxy/utils/Initializable.sol";

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
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "../interfaces/IOpenDefiCollectionFactory.sol";

abstract contract TokenPausableUpgradeable is
    Initializable,
    OwnableUpgradeable
{
    // Bool variable to flag when burn is paused/unpaused
    bool private _burnPaused;
    // Bool variable to flag when transfer is paused/unpaused
    bool private _transferPaused;
    // Bool variable to flag when contract is paused
    bool private _paused;
    // To store collection factory address.
    address public collectionFactory;
    // To store exchange contract address.
    address public exchangeAddress;

    /**
     * @dev Emitted when the burn pause is triggered by `account`.
     */
    event BurnPaused(address account);
    /**
     * @dev Emitted when the transfer pause is triggered by `account`.
     */
    event TransferPaused(address account);

    /**
     * @dev Emitted when the burn pause is lifted by `account`.
     */
    event BurnUnpaused(address account);
    /**
     * @dev Emitted when the transfer pause is lifted by `account`.
     */
    event TransferUnpaused(address account);

    /**
     * @dev Emitted when the pause is lifted by `account`.
     */
    event Unpaused(address account);
    /**
     * @dev Emitted when the pause is triggered by `account`.
     */
    event Paused(address account);

    /**
     * @dev Returns true if the factory is paused, and false otherwise.
     */
    function factoryPauseStatus() internal view returns (bool) {
        return IOpenDefiCollectionFactory(collectionFactory).paused();
    }

    /**
     * @dev Returns true if the burning is paused, and false otherwise.
     */
    function burnPaused() public view virtual returns (bool) {
        return _burnPaused;
    }

    /**
     * @dev Returns true if the NFT transfer is paused, and false otherwise.
     */
    function transferPaused() public view virtual returns (bool) {
        return _transferPaused;
    }

    /**
     * @dev Returns true if the NFT collection is paused, and false otherwise.
     */
    function paused() public view virtual returns (bool) {
        return factoryPauseStatus() || _paused;
    }

    /**
     * @dev Modifier to make a function callable only when the burn is not paused.
     *
     * Requirements:
     *
     * - The burn must not be paused.
     */
    modifier whenBurnNotPaused() {
        require(!burnPaused(), "burn paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the transfer is not paused.
     *
     * Requirements:
     *
     * - The transfer must not be paused.
     */
    modifier whenTransferNotPaused() {
        require(!transferPaused(), "transfer paused   ");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the contract is not paused.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    modifier whenNotPaused() {
        require(!paused(), "paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the burn is paused.
     *
     * Requirements:
     *
     * - The burn must be paused.
     */
    modifier whenBurnPaused() {
        require(burnPaused(), "burn not paused");
        _;
    }

    /**
     * @dev Modifier to make a function callable only when the transfers are paused.
     *
     * Requirements:
     *
     * - The transfer must be paused.
     */
    modifier whenTransferPaused() {
        require(transferPaused(), "transfer not paused");
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
        require(paused(), "not paused");
        _;
    }

    /**
     * @dev Triggers stopped state for burns.
     *
     * Requirements:
     *
     * - The burns must not be paused.
     */
    function pauseBurn() external onlyOwner whenBurnNotPaused {
        _burnPaused = true;
        emit BurnPaused(_msgSender());
    }

    /**
     * @dev Triggers stopped state for transfers.
     *
     * Requirements:
     *
     * - The transfers must not be paused.
     */
    function pauseTransfer() external onlyOwner whenTransferNotPaused {
        _transferPaused = true;
        emit TransferPaused(_msgSender());
    }

    /**
     * @dev Triggers stopped state for contract.
     *
     * Requirements:
     *
     * - The contract must not be paused.
     */
    function pause() external onlyOwner whenNotPaused {
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
    function unpause() external onlyOwner whenPaused {
        _paused = false;
        emit Unpaused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The burn must be paused.
     */
    function unpauseBurn() external onlyOwner whenBurnPaused {
        _burnPaused = false;
        emit BurnUnpaused(_msgSender());
    }

    /**
     * @dev Returns to normal state.
     *
     * Requirements:
     *
     * - The transfers must be paused.
     */
    function unpauseTransfers() external onlyOwner whenTransferPaused {
        _transferPaused = false;
        emit TransferUnpaused(_msgSender());
    }

    uint256[9] private __gap;
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
interface IERC165Upgradeable {
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
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.0;

import "../../utils/AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
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
 * contract, which may impact the proxy. To initialize the implementation contract, you can either invoke the
 * initializer manually, or you can include a constructor to automatically mark it as initialized when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() initializer {}
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     */
    bool private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Modifier to protect an initializer function from being invoked twice.
     */
    modifier initializer() {
        // If the contract is initializing we ignore whether _initialized is set in order to support multiple
        // inheritance patterns, but we only do this in the context of a constructor, because in other contexts the
        // contract may have been reentered.
        require(_initializing ? _isConstructor() : !_initialized, "Initializable: contract is already initialized");

        bool isTopLevelCall = !_initializing;
        if (isTopLevelCall) {
            _initializing = true;
            _initialized = true;
        }

        _;

        if (isTopLevelCall) {
            _initializing = false;
        }
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} modifier, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    function _isConstructor() private view returns (bool) {
        return !AddressUpgradeable.isContract(address(this));
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/ContextUpgradeable.sol";
import "../proxy/utils/Initializable.sol";

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
abstract contract OwnableUpgradeable is Initializable, ContextUpgradeable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    function __Ownable_init() internal onlyInitializing {
        __Ownable_init_unchained();
    }

    function __Ownable_init_unchained() internal onlyInitializing {
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

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

/// @dev Interface for the OpenDefi Collection Factory
interface IOpenDefiCollectionFactory {
    /**
     * @dev Called to view latest collection id
     */
    function latestCollectionId() external view returns (uint256);

    /**
     * @dev Called to view status of factory
     */
    function isFactoryPublic() external view returns (bool);

    /**
     * @dev Called to view collection address mapped to a collection id
     * @param collectionId - the collection id mapped for collection address
     * @return collectionAddress - address of collection
     */
    function collections(uint256 collectionId) external view returns (address);

    function exchanges(uint256 collectionId) external view returns (address);

    function paused() external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "../proxy/utils/Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../libraries/LibPart.sol";

abstract contract AbstractRoyalties {
    /*
     * @notice return royalty details for the provided token id.
     */
    mapping(uint256 => LibPart.Part[]) internal royalties;

    /*
     * @notice saves royalty details `_royalties` for the provided token `_id`.
     */
    function _saveRoyalties(uint256 id, LibPart.Part[] memory _royalties)
        internal
    {
        uint256 totalValue;
        for (uint256 i = 0; i < _royalties.length; i++) {
            require(
                _royalties[i].account != address(0x0),
                "Recipient should be present"
            );
            require(
                _royalties[i].value != 0,
                "Royalty value should be positive"
            );
            totalValue += _royalties[i].value;
            royalties[id].push(_royalties[i]);
        }
        require(totalValue < 10000, "Royalty total value should be < 10000");
        _onRoyaltiesSet(id, _royalties);
    }

    /*
     * @notice updates royalty address `_from` to `_to` for the given NFT token _id.
     */
    function _updateAccount(
        uint256 _id,
        address _from,
        address _to
    ) internal {
        uint256 length = royalties[_id].length;
        for (uint256 i = 0; i < length; i++) {
            if (royalties[_id][i].account == _from) {
                royalties[_id][i].account = payable(_to);
            }
        }
    }

    /*
     * @notice Hook that can be called after setting royalties
     */
    function _onRoyaltiesSet(uint256 id, LibPart.Part[] memory _royalties)
        internal
        virtual;
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;
pragma abicoder v2;

import "../libraries/LibPart.sol";

/// @dev Interface for the Royalties
interface IRoyalties {
    /**
     * @dev Emitted when the royalties are set for the given NFT id.
     */
    event RoyaltiesSet(uint256 tokenId, LibPart.Part[] royalties);

    /**
     * @notice Called to view the royalties details
     * @param id - the asset id to query royalty details
     * @return royalty details
     */
    function getRoyalties(uint256 id)
        external
        view
        returns (LibPart.Part[] memory);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "../libraries/LibPart.sol";

/// @dev Interface for the NFT Royalty Standard
interface IERC2981 {
    /**
     * ERC165 bytes to add to interface array - set in parent contract
     * implementing this standard
     *
     * bytes4(keccak256("royaltyInfo(uint256,uint256)")) == 0x2a55205a
     * bytes4 private constant _INTERFACE_ID_ERC2981 = 0x2a55205a;
     * _registerInterface(_INTERFACE_ID_ERC2981);
     * @notice Called with the sale price to determine how much royalty
     *         is owed and to whom.
     * @param _tokenId - the NFT asset queried for royalty information
     * @param _salePrice - the sale price of the NFT asset specified by _tokenId
     * @return receiver - address of who should be sent the royalty payment
     * @return royaltyAmount - the royalty payment amount for _salePrice
     */
    function royaltyInfo(uint256 _tokenId, uint256 _salePrice)
        external
        view
        returns (address receiver, uint256 royaltyAmount);
}

// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

library LibPart {
    bytes32 public constant TYPE_HASH =
        keccak256("Part(address account,uint96 value)");

    /// @notice Stores account address and amount which can be used for fee related purposes
    struct Part {
        address payable account;
        uint96 value;
    }
}