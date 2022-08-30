// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/INFTProtocolDEX.sol";
import "./DEXConstants.sol";
import "./DEXAccessControl.sol";

contract NFTProtocolDEX is
    INFTProtocolDEX,
    DEXAccessControl,
    DEXConstants,
    ERC1155Holder,
    ERC721Holder,
    ReentrancyGuard
{
    using Address for address;
    using SafeERC20 for IERC20;

    /**
     * @inheritdoc INFTProtocolDEX
     */
    string public constant name = "NFTProtocolDEX";

    /**
     * @inheritdoc INFTProtocolDEX
     */
    uint16 public constant majorVersion = 3;

    /**
     * @inheritdoc INFTProtocolDEX
     */
    uint16 public constant minorVersion = 0;

    /**
     * @inheritdoc INFTProtocolDEX
     */
    address public immutable token;

    /**
     * @inheritdoc INFTProtocolDEX
     * @dev Default is 0.001 Ether.
     */
    uint256 public flatFee = 1_000_000_000_000_000;

    /**
     * @inheritdoc INFTProtocolDEX
     * @dev Default is 10,000 tokens.
     */
    uint256 public lowFee = 10_000 * 10**18;

    /**
     * @inheritdoc INFTProtocolDEX
     * @dev Default is 100,000 tokens.
     */
    uint256 public highFee = 100_000 * 10**18;

    /**
     * @inheritdoc INFTProtocolDEX
     */
    uint256 public numSwaps;

    /**
     * @dev Map of Ether balances.
     */
    mapping(address => uint256) private _balances;

    /**
     * @dev Total value locked, including all swap ether, excluding the contract owner's fees.
     */
    uint256 public tvl;

    /**
     * @dev Mapping from swapID to swap structures for all swaps,
     * including closed and dropped swaps.
     */
    mapping(uint256 => Swap) private _swaps;

    /**
     * @dev Mapping from swapID to swap whitelist.
     */
    mapping(uint256 => mapping(address => bool)) private _whitelists;

    /**
     * @dev Valid swap check.
     */
    modifier validSwap(uint256 swapID) {
        require(swapID < numSwaps, "Invalid swapID");
        _;
    }

    /**
     * @dev Valid side check.
     */
    modifier validSide(uint8 side) {
        require(side == MAKER_SIDE || side == TAKER_SIDE, "Invalid side");
        _;
    }

    /**
     * Initializes the contract with the address of the NFT Protocol token
     * and the address of the administrator account.
     * @param token_ address of the NFT Protocol ERC20 token
     * @param admin_ address of the administrator account (multisig)
     */
    constructor(address token_, address admin_) DEXAccessControl(admin_) {
        token = token_;
        emit FeesChanged(flatFee, lowFee, highFee);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function is not available:
     * - in `deprecated` or `locked` mode, see :sol:func:deprecated and :sol:func:locked, respectively.
     * - to the contract administrator, see :sol:func:owner.
     */
    function makeSwap(
        Component[] calldata make_,
        Component[] calldata take_,
        bool custodial_,
        uint256 expiration_,
        address[] calldata whitelist_
    ) external payable override supported unlocked notOwner nonReentrant {
        require(make_.length > 0, "Make side is empty");
        require(take_.length > 0, "Take side is empty");
        require(_notExpired(expiration_), "Invalid expiration");

        // Calc make value, pay amount, and updated balance, also checks asset types.
        address sender = _msgSender();
        (uint256 pay, uint256 updated) = _requiredValue(sender, make_, msg.value, 0);
        _checkComponents(take_);

        // Check sent value.
        require(msg.value >= pay, "Insufficient Ether value");

        // Create swap.
        _addSwap(make_, take_, custodial_, expiration_, whitelist_);

        // Update tvl.
        tvl += msg.value;

        // Transfer in maker assets.
        _transferAssetsIn(make_, custodial_);

        // Update balance.
        _updateBalance(updated, numSwaps);

        // Finalize swap.
        numSwaps += 1;

        // Issue event.
        emit SwapMade(numSwaps - 1, make_, take_, sender, custodial_, expiration_, whitelist_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function is not available:
     * - in `locked` mode, see :sol:func:locked,
     * - to the contract administrator, see :sol:func:owner.
     */
    function takeSwap(uint256 swapID_, uint256 seqNum_) external payable override unlocked notOwner nonReentrant {
        address sender = _msgSender();
        (Swap storage swp, uint256 pay, uint256 updated, uint256 fee) = _takerSwapAndValues(sender, swapID_, msg.value);
        require(swp.seqNum == seqNum_, "Wrong seqNum");
        require(msg.value >= pay, "Insufficient Ether value (price + fee)");

        // Close out swap.
        swp.status = CLOSED_SWAP;
        swp.taker = sender;

        // Update balance.
        _updateBalance(updated, swapID_);

        // Transfer assets from DEX to taker.
        _transferAssetsOut(swp.components[MAKER_SIDE], swp.maker, swp.custodial);

        // Transfer assets from taker to maker.
        for (uint256 i = 0; i < swp.components[TAKER_SIDE].length; i++) {
            _transferAsset(swp.components[TAKER_SIDE][i], sender, swp.maker);
        }

        // Credit fee to owner.
        address owner_ = owner();
        _balances[owner_] += fee;
        tvl += msg.value;
        tvl -= fee;

        // Issue events.
        emit SwapTaken(swapID_, swp.seqNum, sender, fee);
        emit Deposited(owner(), fee);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function is not available:
     * - in `locked` mode, see :sol:func:locked,
     * - to the contract administrator, see :sol:func:owner.
     */
    function dropSwap(uint256 swapID_) external override unlocked notOwner nonReentrant {
        Swap storage swp = _swaps[swapID_];
        require(swp.status == OPEN_SWAP, "Swap not open");
        require(_msgSender() == swp.maker, "Not swap maker");

        // Drop swap.
        swp.status = DROPPED_SWAP;

        // Transfer assets back to maker.
        for (uint256 i = 0; i < swp.components[MAKER_SIDE].length; i++) {
            if (swp.custodial || swp.components[MAKER_SIDE][i].assetType == ETHER_ASSET) {
                _transferAsset(swp.components[MAKER_SIDE][i], address(this), swp.maker);
            }
        }

        // Issue event.
        emit SwapDropped(swapID_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function is not available:
     * - in `locked` mode, see :sol:func:locked,
     * - to the contract administrator, see :sol:func:owner.
     */
    function amendSwapEther(
        uint256 swapID_,
        uint8 side_,
        uint256 value_
    ) external payable override unlocked notOwner nonReentrant validSide(side_) validSwap(swapID_) {
        Swap storage swp = _swaps[swapID_];
        require(swp.status == OPEN_SWAP, "Swap not open");
        address sender = _msgSender();
        require(sender == swp.maker, "Not swap maker");
        require(_notExpired(swp.expiration), "Swap expired");
        Component[] storage comps = swp.components[side_];

        // Set ether asset.
        (uint256 previous, uint256 index) = _setEtherAsset(comps, value_);
        require(value_ != previous, "Ether value unchanged");
        require(value_ > 0 || comps.length > 1, "Swap side becomes empty");

        // Update balance.
        uint256 balance_ = _balances[sender];
        if (side_ == TAKER_SIDE && msg.value > 0) {
            _updateBalance(balance_ + msg.value, swapID_);
        } else if (side_ == MAKER_SIDE) {
            if (value_ > previous) {
                require(balance_ + msg.value >= value_ - previous, "Insufficient Ether value");
            }
            _updateBalance(balance_ + msg.value + previous - value_, swapID_);
        }

        // Update tvl.
        tvl += msg.value;

        // Update seqNum.
        swp.seqNum += 1;

        // Issue event.
        emit SwapEtherAmended(swapID_, swp.seqNum, side_, index, previous, value_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function requires the swap to be defined.
     */
    function swap(uint256 swapID_) external view override validSwap(swapID_) returns (Swap memory) {
        return _swaps[swapID_];
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function requires the swap to be defined.
     */
    function whitelistedWith(address sender_, uint256 swapID_) public view override validSwap(swapID_) returns (bool) {
        return _whitelists[swapID_][sender_];
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function whitelisted(uint256 swapID_) external view override returns (bool) {
        return whitelistedWith(_msgSender(), swapID_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function requires the swap to be defined and open.
     */
    function requireCanTakeSwapWith(address sender_, uint256 swapID_) public view override unlocked validSwap(swapID_) {
        (Swap storage swp, , , ) = _takerSwapAndValues(sender_, swapID_, 0);
        _requireComponents(swp.components[TAKER_SIDE], sender_, true);
        if (!swp.custodial) {
            _requireComponents(swp.components[MAKER_SIDE], swp.maker, false);
        }
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function requireCanTakeSwap(uint256 swapID_) external view override {
        return requireCanTakeSwapWith(_msgSender(), swapID_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function requireMakerAssets(uint256 swapID) external view override unlocked validSwap(swapID) {
        Swap memory swp = _swaps[swapID];
        require(swp.status == OPEN_SWAP, "Swap not open");
        require(!swp.custodial, "Swap custodial");
        _requireComponents(swp.components[MAKER_SIDE], swp.maker, false);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function requireTakerAssetsWith(address sender_, uint256 swapID_) public view override unlocked validSwap(swapID_) {
        (Swap storage swp, , , ) = _takerSwapAndValues(sender_, swapID_, 0);
        _requireComponents(swp.components[TAKER_SIDE], sender_, true);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function requireTakerAssets(uint256 swapID_) public view override {
        return requireTakerAssetsWith(_msgSender(), swapID_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function balanceOf(address of_) public view override returns (uint256) {
        return _balances[of_];
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function balance() external view override returns (uint256) {
        return balanceOf(_msgSender());
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function withdraw(uint256 value_) external override {
        _withdraw(value_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function withdrawFull() external override {
        _withdraw(_balances[_msgSender()]);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function makerSendValueWith(address sender_, Component[] calldata make_)
        public
        view
        override
        supported
        unlocked
        returns (uint256)
    {
        (uint256 pay, ) = _requiredValue(sender_, make_, 0, 0);
        return pay;
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function makerSendValue(Component[] calldata make_) external view override returns (uint256) {
        return makerSendValueWith(_msgSender(), make_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function takerSendValueWith(address sender_, uint256 swapID_) public view override unlocked returns (uint256) {
        (, uint256 pay, , ) = _takerSwapAndValues(sender_, swapID_, 0);
        return pay;
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function takerSendValue(uint256 swapID_) external view override unlocked returns (uint256) {
        return takerSendValueWith(_msgSender(), swapID_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function amendSwapEtherSendValueWith(
        address sender_,
        uint256 swapID_,
        uint8 side_,
        uint256 value_
    ) public view override unlocked validSide(side_) returns (uint256) {
        Swap storage swp = _swaps[swapID_];
        require(swp.status == OPEN_SWAP, "Swap not open");
        require(sender_ == swp.maker, "Not swap maker");
        require(_notExpired(swp.expiration), "Swap expired");
        Component[] storage comps = swp.components[side_];

        // Ether value.
        uint256 current = _getEtherAsset(comps);
        require(value_ != current, "Ether value unchanged");
        require(value_ > 0 || comps.length > 1, "Swap side becomes empty");

        // Value required to amend swap Ether.
        uint256 balance_ = _balances[sender_];
        if (side_ == MAKER_SIDE && value_ > current && balance_ < value_ - current) {
            return value_ - current - balance_;
        }

        return 0;
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function amendSwapEtherSendValue(
        uint256 swapID_,
        uint8 side_,
        uint256 value_
    ) external view override returns (uint256) {
        return amendSwapEtherSendValueWith(_msgSender(), swapID_, side_, value_);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function takerFeeWith(address sender_) public view override unlocked returns (uint256) {
        uint256 balance_ = IERC20(token).balanceOf(sender_);
        if (balance_ >= highFee) {
            return 0;
        }
        if (balance_ < lowFee) {
            return flatFee;
        }
        // Take 10% off as soon as feeBypassLow is reached.
        uint256 startFee = (flatFee * 9) / 10;
        return startFee - (startFee * (balance_ - lowFee)) / (highFee - lowFee);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     */
    function takerFee() external view override returns (uint256) {
        return takerFeeWith(_msgSender());
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function can only be called by the contract administrator, see :sol:func:`owner`.
     */
    function setFees(
        uint256 flatFee_,
        uint256 lowFee_,
        uint256 highFee_
    ) external override supported onlyOwner {
        require(lowFee_ <= highFee_, "lowFee must be <= highFee");
        flatFee = flatFee_;
        lowFee = lowFee_;
        highFee = highFee_;
        emit FeesChanged(flatFee, lowFee, highFee);
    }

    /**
     * @inheritdoc INFTProtocolDEX
     *
     * @dev This function can only be called by the contract administrator, see :sol:func:`owner`.
     */
    function rescue() external override onlyOwner nonReentrant {
        address sender = _msgSender();
        uint256 balance_ = _balances[sender];
        uint256 total = address(this).balance - tvl;
        require(total > balance_, "No value to rescue");
        uint256 amount = total - balance_;
        _balances[sender] += amount;
        emit Deposited(sender, amount);
        emit Rescued(sender, amount);
    }

    /**
     * Appends a new swap to the list.
     */
    function _addSwap(
        Component[] calldata make_,
        Component[] calldata take_,
        bool custodial_,
        uint256 expiration_,
        address[] calldata whitelist_
    ) internal {
        _swaps[numSwaps].id = numSwaps;
        _swaps[numSwaps].custodial = custodial_;
        _swaps[numSwaps].expiration = expiration_;
        _swaps[numSwaps].maker = _msgSender();
        for (uint256 i = 0; i < make_.length; i++) {
            _swaps[numSwaps].components[MAKER_SIDE].push(make_[i]);
        }
        for (uint256 i = 0; i < take_.length; i++) {
            _swaps[numSwaps].components[TAKER_SIDE].push(take_[i]);
        }

        // Initialize whitelist mapping for this swap.
        _swaps[numSwaps].whitelist = whitelist_.length > 0;
        for (uint256 i = 0; i < whitelist_.length; i++) {
            _whitelists[numSwaps][whitelist_[i]] = true;
        }
    }

    /**
     * Transfers assets in.
     */
    function _transferAssetsIn(Component[] calldata make_, bool custodial_) internal {
        address sender = _msgSender();
        for (uint256 i = 0; i < make_.length; i++) {
            if (custodial_ || make_[i].assetType == ETHER_ASSET) {
                _transferAsset(make_[i], sender, address(this));
            } else {
                _requireAssets(make_[i], sender, msg.value);
            }
        }
    }

    /**
     * Transfers assets out.
     */
    function _transferAssetsOut(
        Component[] storage comps,
        address from,
        bool custodial
    ) internal {
        address sender = _msgSender();
        for (uint256 i = 0; i < comps.length; i++) {
            if (custodial || comps[i].assetType == ETHER_ASSET) {
                _transferAsset(comps[i], address(this), sender);
            } else {
                _transferAsset(comps[i], from, sender);
            }
        }
    }

    /**
     * Sets the ether component to value, create one if needed.
     * Returns the previous Ether value.
     */
    function _setEtherAsset(Component[] storage comps, uint256 value) internal returns (uint256, uint256) {
        for (uint256 i = 0; i < comps.length; i++) {
            if (comps[i].assetType == ETHER_ASSET) {
                uint256 previous = comps[i].amounts[0];
                comps[i].amounts[0] = value;
                return (previous, i);
            }
        }
        Component memory comp = Component({
            assetType: ETHER_ASSET,
            tokenAddress: address(0),
            tokenIDs: new uint256[](0),
            amounts: new uint256[](1)
        });
        comp.amounts[0] = value;
        comps.push(comp);
        return (0, comps.length - 1);
    }

    /**
     * Gets the Ether component value.
     */
    function _getEtherAsset(Component[] memory comps) internal pure returns (uint256) {
        for (uint256 i = 0; i < comps.length; i++) {
            if (comps[i].assetType == ETHER_ASSET) {
                return comps[i].amounts[0];
            }
        }
        return 0;
    }

    /**
     * Transfers asset from one account to another.
     */
    function _transferAsset(
        Component memory comp,
        address from,
        address to
    ) internal {
        // All component checks were conducted before.
        if (comp.assetType == ERC1155_ASSET) {
            IERC1155 nft = IERC1155(comp.tokenAddress);
            nft.safeBatchTransferFrom(from, to, comp.tokenIDs, comp.amounts, "");
        } else if (comp.assetType == ERC721_ASSET) {
            IERC721 nft = IERC721(comp.tokenAddress);
            nft.safeTransferFrom(from, to, comp.tokenIDs[0]);
        } else if (comp.assetType == ERC20_ASSET) {
            IERC20 coin = IERC20(comp.tokenAddress);
            uint256 amount = comp.amounts[0];
            if (from == address(this)) {
                coin.safeTransfer(to, amount);
            } else {
                coin.safeTransferFrom(from, to, amount);
            }
        } else {
            // Ether, single length amounts array was checked before.
            _balances[to] += comp.amounts[0];
        }
    }

    /**
     * Verifies ownerships, balances, and approval for list of components.
     */
    function _requireComponents(
        Component[] memory comps,
        address wallet,
        bool includeEther
    ) internal view {
        for (uint256 i = 0; i < comps.length; i++) {
            if (includeEther || comps[i].assetType != ETHER_ASSET) {
                _requireAssets(comps[i], wallet, 0);
            }
        }
    }

    /**
     * Verifies ownerships, balances, and approval of component assets.
     */
    function _requireAssets(
        Component memory comp,
        address wallet,
        uint256 sentValue
    ) internal view {
        if (comp.assetType == ERC1155_ASSET) {
            _requireERC1155Assets(comp, wallet);
        } else if (comp.assetType == ERC721_ASSET) {
            _requireERC721Asset(comp, wallet);
        } else if (comp.assetType == ERC20_ASSET) {
            _requireERC20Asset(comp, wallet);
        } else {
            _requireSufficientValue(comp, wallet, sentValue);
        }
    }

    /**
     * Verifies balance and approval of ERC1155 assets.
     */
    function _requireERC1155Assets(Component memory comp, address wallet) internal view {
        IERC1155 nft = IERC1155(comp.tokenAddress);

        // Create accounts for batch balance.
        address[] memory wallets = new address[](comp.tokenIDs.length);
        for (uint256 i = 0; i < comp.tokenIDs.length; i++) {
            wallets[i] = wallet;
        }

        // Batch balance.
        uint256[] memory balances = nft.balanceOfBatch(wallets, comp.tokenIDs);
        require(balances.length == comp.tokenIDs.length, "Invalid balanceOfBatch call");
        for (uint256 i = 0; i < comp.tokenIDs.length; i++) {
            require(balances[i] >= comp.amounts[i], "Insufficient ERC1155 balance");
        }

        // Check if DEX has approval for all.
        bool approved = nft.isApprovedForAll(wallet, address(this));
        require(approved, "DEX not ERC1155 approved");
    }

    /**
     * Verifies balance and approval of ERC721 asset.
     */
    function _requireERC721Asset(Component memory comp, address wallet) internal view {
        IERC721 nft = IERC721(comp.tokenAddress);

        // Check owner.
        address owner = nft.ownerOf(comp.tokenIDs[0]);
        require(owner == wallet, "Not ERC721 token owner");

        // Check approval.
        bool approved = nft.isApprovedForAll(wallet, address(this));
        if (!approved) {
            approved = address(this) == nft.getApproved(comp.tokenIDs[0]);
        }
        require(approved, "DEX not ERC721 approved");
    }

    /**
     * Verifies balance and approval of ERC20 asset.
     */
    function _requireERC20Asset(Component memory comp, address wallet) internal view {
        IERC20 coin = IERC20(comp.tokenAddress);

        // Check balance needed, since ERC20 does not update allowance at transfer (only transferFrom).
        uint256 balance_ = coin.balanceOf(wallet);
        require(balance_ >= comp.amounts[0], "Insufficient ERC20 balance");

        // Check allowance.
        uint256 allowance = coin.allowance(wallet, address(this));
        require(allowance >= comp.amounts[0], "Insufficient ERC20 allowance");
    }

    /**
     * Checks a required Ether value against a wallet balances and sent value.
     * This function ignores transaction (gas) and taker fees.
     */
    function _requireSufficientValue(
        Component memory comp,
        address wallet,
        uint256 sentValue
    ) internal view {
        uint256 balance_ = _balances[wallet];
        require(wallet.balance + balance_ + sentValue >= comp.amounts[0], "Insufficient Ether value");
    }

    /**
     * Checks components against the balance of a sender, the sent value, and a fee.
     * This function ignores transaction (gas) fees.
     */
    function _requiredValue(
        address sender,
        Component[] memory comps,
        uint256 sentValue,
        uint256 fee
    ) internal view returns (uint256, uint256) {
        uint256 value = _checkComponents(comps);
        uint256 balance_ = _balances[sender];
        if (balance_ + sentValue >= value + fee) {
            return (0, balance_ + sentValue - value - fee);
        }
        return (value + fee - balance_, 0);
    }

    /**
     * Checks all assets in a component array.
     */
    function _checkComponents(Component[] memory comps) internal pure returns (uint256) {
        uint256 total;
        bool etherSeen;
        for (uint256 i = 0; i < comps.length; i++) {
            // Allow only one ether component.
            if (comps[i].assetType == ETHER_ASSET) {
                require(!etherSeen, "Multiple ether components");
                etherSeen = true;
            }
            total += _checkComponent(comps[i]);
        }
        return total;
    }

    /**
     * Checks asset type and array sizes within a component.
     */
    function _checkComponent(Component memory comp) internal pure returns (uint256) {
        if (comp.assetType == ERC1155_ASSET) {
            require(comp.tokenIDs.length == comp.amounts.length, "TokenIDs and amounts len differ");
        } else if (comp.assetType == ERC721_ASSET) {
            require(comp.tokenIDs.length == 1, "TokenIDs array length must be 1");
        } else if (comp.assetType == ERC20_ASSET) {
            require(comp.amounts.length == 1, "Amounts array length must be 1");
        } else if (comp.assetType == ETHER_ASSET) {
            require(comp.amounts.length == 1, "Amounts array length must be 1");
            return comp.amounts[0];
        } else {
            revert("Invalid asset type");
        }
        return 0;
    }

    /**
     * Checks an expiration parameter against the current block.
     */
    function _notExpired(uint256 expiration) internal view returns (bool) {
        return expiration == 0 || expiration > block.number;
    }

    /**
     * Returns information about a swap take operation.
     *
     * @return (swap, value to send, updated balance, fee)
     */
    function _takerSwapAndValues(
        address sender,
        uint256 swapID,
        uint256 sentValue
    )
        internal
        view
        validSwap(swapID)
        returns (
            Swap storage,
            uint256,
            uint256,
            uint256
        )
    {
        // Get swap.
        Swap storage swp = _swaps[swapID];
        require(swp.status == OPEN_SWAP, "Swap not open");
        require(sender != swp.maker, "Sender is swap maker");
        require(!swp.whitelist || _whitelists[swapID][sender], "Not in whitelist");
        require(_notExpired(swp.expiration), "Swap expired");

        // Return total Ether to be provided by the taker (including), updated balance.
        uint256 fee = takerFeeWith(sender);
        (uint256 pay, uint256 updated) = _requiredValue(sender, swp.components[TAKER_SIDE], sentValue, fee);
        return (swp, pay, updated, fee);
    }

    /**
     * Updates the balance of an account.
     */
    function _updateBalance(uint256 updated, uint256 swapID) internal {
        address sender = _msgSender();
        uint256 balance_ = _balances[sender];
        _balances[sender] = updated;
        if (updated > balance_) {
            emit Deposited(sender, updated - balance_);
        } else if (updated < balance_) {
            emit Spent(sender, balance_ - updated, swapID);
        }
    }

    /**
     * Withdraws funds from an account.
     */
    function _withdraw(uint256 value) internal nonReentrant {
        require(value > 0, "Ether value is zero");
        address sender = _msgSender();
        uint256 balance_ = _balances[sender];
        require(value <= balance_, "Ether value exceeds balance");
        _balances[sender] -= value;
        if (sender != owner()) {
            tvl -= value;
        }
        (bool ok, ) = sender.call{value: value}("");
        require(ok, "Withdrawal failed");
        emit Withdrawn(sender, value);
    }

    /**
     * Receives Ether funds.
     */
    receive() external payable supported unlocked notOwner {
        uint256 amount = msg.value;
        require(amount > 0, "Ether value is zero");
        address sender = _msgSender();
        _balances[sender] += amount;
        tvl += amount;
        emit Deposited(sender, amount);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC20/utils/SafeERC20.sol)

pragma solidity ^0.8.0;

import "../IERC20.sol";
import "../extensions/draft-IERC20Permit.sol";
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

    function safePermit(
        IERC20Permit token,
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal {
        uint256 nonceBefore = token.nonces(owner);
        token.permit(owner, spender, value, deadline, v, r, s);
        uint256 nonceAfter = token.nonces(owner);
        require(nonceAfter == nonceBefore + 1, "SafeERC20: permit did not succeed");
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
// OpenZeppelin Contracts (last updated v4.5.0) (token/ERC1155/utils/ERC1155Holder.sol)

pragma solidity ^0.8.0;

import "./ERC1155Receiver.sol";

/**
 * Simple implementation of `ERC1155Receiver` that will allow a contract to hold ERC1155 tokens.
 *
 * IMPORTANT: When inheriting this contract, you must include a way to use the received tokens, otherwise they will be
 * stuck.
 *
 * @dev _Available since v3.1._
 */
contract ERC1155Holder is ERC1155Receiver {
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    function onERC1155BatchReceived(
        address,
        address,
        uint256[] memory,
        uint256[] memory,
        bytes memory
    ) public virtual override returns (bytes4) {
        return this.onERC1155BatchReceived.selector;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library Math {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a >= b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. It the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`.
        // We also know that `k`, the position of the most significant bit, is such that `msb(a) = 2**k`.
        // This gives `2**k < a <= 2**(k+1)` → `2**(k/2) <= sqrt(a) < 2 ** (k/2+1)`.
        // Using an algorithm similar to the msb conmputation, we are able to compute `result = 2**(k/2)` which is a
        // good first aproximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1;
        uint256 x = a;
        if (x >> 128 > 0) {
            x >>= 128;
            result <<= 64;
        }
        if (x >> 64 > 0) {
            x >>= 64;
            result <<= 32;
        }
        if (x >> 32 > 0) {
            x >>= 32;
            result <<= 16;
        }
        if (x >> 16 > 0) {
            x >>= 16;
            result <<= 8;
        }
        if (x >> 8 > 0) {
            x >>= 8;
            result <<= 4;
        }
        if (x >> 4 > 0) {
            x >>= 4;
            result <<= 2;
        }
        if (x >> 2 > 0) {
            result <<= 1;
        }

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        uint256 result = sqrt(a);
        if (rounding == Rounding.Up && result * result < a) {
            result += 1;
        }
        return result;
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

pragma solidity ^0.8.0;

interface INFTProtocolDEX {
    /**
     * Structure representing a single component of a swap.
     */
    struct Component {
        uint8 assetType;
        address tokenAddress;
        uint256[] tokenIDs;
        uint256[] amounts;
    }

    /**
     * Swap structure.
     */
    struct Swap {
        uint256 id;
        uint8 status;
        Component[][2] components;
        address maker;
        address taker;
        bool whitelist;
        bool custodial;
        uint256 expiration;
        uint256 seqNum;
    }

    /**
     * Returns the name of the DEX contract.
     */
    function name() external view returns (string memory);

    /**
     * Returns the major version of the DEX contract.
     */
    function majorVersion() external view returns (uint16);

    /**
     * Returns the minor version of the DEX contract.
     */
    function minorVersion() external view returns (uint16);

    /**
     * Returns the address of NFT Protocol Token.
     */
    function token() external view returns (address);

    /**
     * The total number of swaps in the contract.
     */
    function numSwaps() external view returns (uint256);

    /**
     * Returns `True` if sender is in the whitelist of a swap.
     *
     * @param sender_ Account of the sender.
     * @param swapID_ ID of the swap.
     */
    function whitelistedWith(address sender_, uint256 swapID_) external view returns (bool);

    /**
     * Same as :sol:func:`whitelisted` with the sender account.
     */
    function whitelisted(uint256 swapID_) external view returns (bool);

    /**
     * Checks if a swap can be taken by the caller.
     *
     * This function reverts with a message if the swap cannot be taken by the caller.
     * Reasons include:
     * - Swap not open.
     * - Swap has a whitelist and caller is not included.
     * - Taker assets are not available.
     * - Swap is non-custodial and maker has not made all assets available (e.g., moved assets or revoked allowances).
     * - Sender is swap maker.
     *
     * @param sender_ Address of the hypothetical swap taker.
     * @param swapID_ ID of the swap.
     */
    function requireCanTakeSwapWith(address sender_, uint256 swapID_) external view;

    /**
     * Same as :sol:func:`requireCanTakeSwapWith` with the sender account.
     */
    function requireCanTakeSwap(uint256 swapID_) external view;

    /**
     * Checks if all maker assets are available for non-custodial swaps, including balances and allowances.
     *
     * @param swapID_ ID of the swap.
     */
    function requireMakerAssets(uint256 swapID_) external view;

    /**
     * Checks if all taker assets are available.
     *
     * @param sender_ Address of the hypothetical swap taker.
     * @param swapID_ ID of the swap.
     */
    function requireTakerAssetsWith(address sender_, uint256 swapID_) external view;

    /**
     * Same as :sol:func:`requireTakerAssetsWith` with the sender account.
     */
    function requireTakerAssets(uint256 swapID_) external view;

    /**
     * Returns the total ether value locked (tvl), including all deposited swap ether,
     * excluding the fees collected by the administrator.
     */
    function tvl() external view returns (uint256);

    /**
     * Opens a swap with a list of assets on the maker side (`make_`) and on the taker side (`take_`).
     *
     * All assets listed on the maker side have to be available in the caller's account.
     * They are transferred to the DEX contract during this contract call.
     *
     * If the maker list contains Ether assets, then the total Ether funds have to be sent along with
     * the message of this contract call.
     *
     * Emits a :sol:event:`SwapMade` event, if successful.
     *
     * @param make_ Array of components for the maker side of the swap.
     * @param take_ Array of components for the taker side of the swap.
     * @param custodial_ True if the swap is custodial, e.g., maker assets are transfered into the DEX.
     * @param expiration_ Block number at which the swap expires, 0 for no expiration.
     * @param whitelist_ List of addresses that shall be permitted to take the swap.
     * If empty, then whitelisting will be disabled for this swap.
     */
    function makeSwap(
        Component[] calldata make_,
        Component[] calldata take_,
        bool custodial_,
        uint256 expiration_,
        address[] calldata whitelist_
    ) external payable;

    /**
     * Takes a swap that is currently open.
     *
     * All assets listed on the taker side have to be available in the caller's account, see :sol:func:`make`.
     * They are transferred to the maker's account in exchange for the maker's assets that currently reside within the DEX contract for custodial swaps,
     * which are transferred to the taker's account. For non-custodial swaps, the maker assets are transfered from the maker account.
     * This functions checks allowances, ownerships, and balances of all assets that are involved in this swap.
     *
     * The fee for this trade has to be sent along with the message of this contract call, see :sol:func:`fees`.
     *
     * If the taker list contains ETHER assets, then the total ETHER value also has to be added in WEI to the value that is sent along with
     * the message of this contract call.
     *
     * This function requires the caller to provide the most recent sequence number of the swap, which only changes when
     * the swap ether component is updated. The sequence number is used to prevent mempool front-running attacks.
     *
     * @param swapID_ ID of the swap to be taken.
     * @param seqNum_ Most recent sequence number of the swap.
     */
    function takeSwap(uint256 swapID_, uint256 seqNum_) external payable;

    /**
     * Drop a swap and return the assets on the maker side back to the maker.
     *
     * All ERC1155, ERC721, and ERC20 assets will the transferred back directly to the maker.
     * Ether assets are booked to the maker account and can be extracted via :sol:func:`withdraw` and :sol:func:`withdrawFull`.
     *
     * Only the swap maker will be able to call this function successfully.
     *
     * Only swaps that are currently open can be dropped.
     *
     * @param swapID_ id of the swap to be dropped.
     */
    function dropSwap(uint256 swapID_) external;

    /**
     * Amend ether value of a swap.
     *
     * @param swapID_ ID fo the swap to be modified.
     * @param side_ Swap side to modify, see :sol:func:`MAKER_SIDE` and :sol:func:`TAKER_SIDE`.
     * @param value_ New Ether value in Wei to be set for the swap side.
     */
    function amendSwapEther(
        uint256 swapID_,
        uint8 side_,
        uint256 value_
    ) external payable;

    /**
     * Returns the total Ether value in Wei that is required by the sender to take a swap.
     *
     * @param sender_ Address of the sender.
     * @param swapID_ ID of the swap.
     */
    function takerSendValueWith(address sender_, uint256 swapID_) external view returns (uint256);

    /**
     * Same as :sol:func:`takerSendValueWith` with the sender account.
     */
    function takerSendValue(uint256 swapID_) external view returns (uint256);

    /**
     * Returns the total Ether value in Wei that is required by the sender to make a swap.
     *
     * @param sender_ Address of the sender.
     * @param make_ Component array for make side of the swap, see :sol:func:`makeSwap`.
     */
    function makerSendValueWith(address sender_, Component[] calldata make_) external view returns (uint256);

    /**
     * Same as :sol:func:`makerSendValueWith` with the sender account.
     */
    function makerSendValue(Component[] calldata make_) external view returns (uint256);

    /**
     * Returns the total Ether value in Wei that is required by the caller to send in order to adjust the Ether of a swap,
     * see :sol:func:`adjustSwapEther`.
     *
     * @param sender_ Sender account.
     * @param swapID_ ID of the swap to be modified.
     * @param side_ Swap side to modify, see :sol:func:`MAKER_SIDE` and :sol:func:`TAKER_SIDE`.
     * @param value_ New Ether value in Wei to be set for the swap side.
     */
    function amendSwapEtherSendValueWith(
        address sender_,
        uint256 swapID_,
        uint8 side_,
        uint256 value_
    ) external view returns (uint256);

    /**
     * Same as :sol:func:`amendSwapEtherSendValueWith` with the sender account.
     */
    function amendSwapEtherSendValue(
        uint256 swapID_,
        uint8 side_,
        uint256 value_
    ) external view returns (uint256);

    /**
     * Returns the Wei of Ether balance of a user, see :sol:func:`withdraw` and :sol:func:`withdrawFull`.
     *
     * @param of_ Address of the account.
     */
    function balanceOf(address of_) external view returns (uint256);

    /**
     * Same as :sol:func:`balanceOf` with the sender account.
     */
    function balance() external view returns (uint256);

    /**
     * Withdraw funds in Wei of Ether from the contract, see :sol:func:`balance`.
     *
     * @param value_ Wei of Ether to withdraw.
     */
    function withdraw(uint256 value_) external;

    /**
     * Withdraw all Ether funds from the contract that are available to the caller, see :sol:func:`withdraw`.
     */
    function withdrawFull() external;

    /**
     * Rescue funds that are stuck in the DEX, e.g., no user has access to.
     * This function only runs successfully if , which should never happen.
     */
    function rescue() external;

    /**
     * Get a swap, including closed and dropped swaps.
     *
     * @param swapID_ ID of the swap.
     * @return Swap data structure.
     */
    function swap(uint256 swapID_) external view returns (Swap memory);

    /**
     * The flat fee in Wei of Ether to take a swap, see :sol:func:`setFlatFee`.
     *
     * @return Flat fee in Wei of Ether.
     */
    function flatFee() external view returns (uint256);

    /**
     * The threshold of NFT Protocol token holdings for swap takersto get a 10% discount on the flat fee.
     *
     * @return Threshold for amounts in smallest unit of NFT Protocol token holdings to get a 10% discount.
     */
    function lowFee() external view returns (uint256);

    /**
     * The threshold of NFT Protocol token holdings for swap takes to waive the flat fee.
     *
     * @return Threshold for amount in smallest unit of NFT Protocol token holdings to waive the flat fee.
     */
    function highFee() external view returns (uint256);

    /**
     * Returns the taker fee owed for a swap, taking into account the holdings of NFT Protocol tokens,
     * see :sol:func:`flatFee`, :sol:func:`lowFee`, :sol:func:`highFee`.
     *
     * @param sender_ Address of the sender.
     */
    function takerFeeWith(address sender_) external view returns (uint256);

    /**
     * Same as :sol:func:`takerFeeOf` with the sender account.
     */
    function takerFee() external view returns (uint256);

    /**
     * Set the flat fee structure for swaps taking.
     *
     * @param flatFee_ Flat fee in Wei of Ether paid by the taker of swap,
     * if they hold less than `lowFee_` in smallest units of NFT Protocol token.
     * @param lowFee_ Threshold in smallest unit of NFT Protocol token to be held by the swap taker to get a 10% fee discount.
     * @param highFee_ Threshold in smallest unit of NFT Protocol token to be held by the swap taker to pay no fees.
     */
    function setFees(
        uint256 flatFee_,
        uint256 lowFee_,
        uint256 highFee_
    ) external;

    /**
     * Emitted when a swap was opened, see :sol:func:`makeSwap`.
     *
     * @param swapID ID of the swap.
     * @param make Array of swap components on the maker side, see :sol:struct:`Component`.
     * @param take Array of swap components on the taker side, see :sol:struct:`Component`.
     * @param maker Account of the swap maker.
     * @param custodial True if swap is custodial.
     * @param expiration Block where the swap expires, 0 for no expiration.
     * @param whitelist Array of addresses that are allowed to take the swap.
     */
    event SwapMade(
        uint256 indexed swapID,
        Component[] make,
        Component[] take,
        address indexed maker,
        bool indexed custodial,
        uint256 expiration,
        address[] whitelist
    );

    /**
     * Emitted when a swap was executed, see :sol:func:`takeSwap`.
     *
     * @param swapID ID of the swap that was taken.
     * @param seqNum Sequence number of the swap.
     * @param taker Address of the account that executed the swap.
     * @param fee Fee value in Wei of Ether paid by the swap taker.
     */
    event SwapTaken(uint256 indexed swapID, uint256 seqNum, address indexed taker, uint256 fee);

    /**
     * Emitted when a swap was dropped, ie. cancelled.
     *
     * @param swapID ID of the dropped swap.
     */
    event SwapDropped(uint256 indexed swapID);

    /**
     * Emitted when a Ether component of a swap was amended, see :sol:func:`amendSwapEther`.
     *
     * @param swapID ID of the swap.
     * @param seqNum New sequence number of the swap.
     * @param side Swap side, either MAKER_SIDE or TAKER_SIDE.
     * @param index Index of the amended or added Ether component in the components array.
     * @param from Previous amount of Ether in Wei.
     * @param to Updated amount of Ether in Wei.
     */
    event SwapEtherAmended(
        uint256 indexed swapID,
        uint256 seqNum,
        uint8 indexed side,
        uint256 index,
        uint256 from,
        uint256 to
    );

    /**
     * Emitted when the flat fee parameters have changed, see :sol:func:`setFees`.
     *
     * @param flatFee Fee to be paid by a swap taker in Wei of Ether.
     * @param lowFee Threshold of NFT Protocol tokens to be held by a swap taker in order to get a 10% fee discount.
     * @param highFee Threshold of NFT Protocol tokens to be held by a swap taker in order to pay no fees.
     */
    event FeesChanged(uint256 flatFee, uint256 lowFee, uint256 highFee);

    /**
     * Emitted when Ether funds were deposited into the DEX, see :sol:func:`balance`.
     *
     * @param account Address of the account.
     * @param value Wei of Ether deposited.
     */
    event Deposited(address indexed account, uint256 value);

    /**
     * Emitted when Ether funds were withdrawn from the DEX, see :sol:func:`balance`.
     *
     * @param account Address of the account.
     * @param value Wei of Ether withdrawn.
     */
    event Withdrawn(address indexed account, uint256 value);

    /**
     * Emitted when Ether funds were spent during a make or take swap operation, see :sol:func:`balance`.
     *
     * @param spender Address of the spender.
     * @param value Wei of Ether spent.
     * @param swapID ID of the swap, the Ether was spent on, see :sol:func:`takeSwap`, :sol:func:`amendSwapEther`.
     */
    event Spent(address indexed spender, uint256 value, uint256 indexed swapID);

    /**
     * Emitted when funds were rescued, see :sol:func:`rescue`.
     *
     * @param recipient Address of the beneficiary, e.g., the administrator account.
     * @param value Wei of Ether rescued.
     */
    event Rescued(address indexed recipient, uint256 value);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IDEXConstants.sol";

abstract contract DEXConstants {
    uint8 public constant MAKER_SIDE = 0;
    uint8 public constant TAKER_SIDE = 1;

    uint8 public constant ERC1155_ASSET = 0;
    uint8 public constant ERC721_ASSET = 1;
    uint8 public constant ERC20_ASSET = 2;
    uint8 public constant ETHER_ASSET = 3;

    uint8 public constant OPEN_SWAP = 0;
    uint8 public constant CLOSED_SWAP = 1;
    uint8 public constant DROPPED_SWAP = 2;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interface/IDEXAccessControl.sol";

contract DEXAccessControl is IDEXAccessControl, Ownable {
    /**
     * @inheritdoc IDEXAccessControl
     */
    bool public locked = false;

    /**
     * @inheritdoc IDEXAccessControl
     */
    bool public deprecated = false;

    /**
     * @dev Unlocked DEX function modifier.
     */
    modifier unlocked() {
        require(!locked, "DEX locked");
        _;
    }

    /**
     * @dev Supported (not deprecated) function modifier.
     */
    modifier supported() {
        require(!deprecated, "DEX deprecated");
        _;
    }

    /**
     * @dev Not owner function modifier.
     */
    modifier notOwner() {
        require(owner() != _msgSender(), "Owner prohibited");
        _;
    }

    /**
     * Initializes access control.
     * @param owner_ Address of the administrator account (multisig).
     */
    constructor(address owner_) {
        transferOwnership(owner_);
    }

    /**
     * @inheritdoc IDEXAccessControl
     * @dev This function is only accessible by the administrator account.
     */
    function lock(bool lock_) external override onlyOwner {
        require(lock_ != locked, "State unchanged");
        locked = lock_;
        emit Locked(locked);
    }

    /**
     * @inheritdoc IDEXAccessControl
     * @dev This function is only accessible by the administrator account.
     */
    function deprecate(bool deprecate_) external override onlyOwner {
        require(deprecate_ != deprecated, "State unchanged");
        deprecated = deprecate_;
        emit Deprecated(deprecated);
    }

    /**
     * @dev This function is disabled.
     */
    function renounceOwnership() public override onlyOwner {
        revert("Disabled");
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
// OpenZeppelin Contracts v4.4.1 (token/ERC20/extensions/draft-IERC20Permit.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 Permit extension allowing approvals to be made via signatures, as defined in
 * https://eips.ethereum.org/EIPS/eip-2612[EIP-2612].
 *
 * Adds the {permit} method, which can be used to change an account's ERC20 allowance (see {IERC20-allowance}) by
 * presenting a message signed by the account. By not relying on {IERC20-approve}, the token holder account doesn't
 * need to send a transaction, and thus is not required to hold Ether at all.
 */
interface IERC20Permit {
    /**
     * @dev Sets `value` as the allowance of `spender` over ``owner``'s tokens,
     * given ``owner``'s signed approval.
     *
     * IMPORTANT: The same issues {IERC20-approve} has related to transaction
     * ordering also apply here.
     *
     * Emits an {Approval} event.
     *
     * Requirements:
     *
     * - `spender` cannot be the zero address.
     * - `deadline` must be a timestamp in the future.
     * - `v`, `r` and `s` must be a valid `secp256k1` signature from `owner`
     * over the EIP712-formatted function arguments.
     * - the signature must use ``owner``'s current nonce (see {nonces}).
     *
     * For more information on the signature format, see the
     * https://eips.ethereum.org/EIPS/eip-2612#specification[relevant EIP
     * section].
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;

    /**
     * @dev Returns the current nonce for `owner`. This value must be
     * included whenever a signature is generated for {permit}.
     *
     * Every successful call to {permit} increases ``owner``'s nonce by one. This
     * prevents a signature from being used multiple times.
     */
    function nonces(address owner) external view returns (uint256);

    /**
     * @dev Returns the domain separator used in the encoding of the signature for {permit}, as defined by {EIP712}.
     */
    // solhint-disable-next-line func-name-mixedcase
    function DOMAIN_SEPARATOR() external view returns (bytes32);
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
// OpenZeppelin Contracts v4.4.1 (token/ERC1155/utils/ERC1155Receiver.sol)

pragma solidity ^0.8.0;

import "../IERC1155Receiver.sol";
import "../../../utils/introspection/ERC165.sol";

/**
 * @dev _Available since v3.1._
 */
abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165, IERC165) returns (bool) {
        return interfaceId == type(IERC1155Receiver).interfaceId || super.supportsInterface(interfaceId);
    }
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

pragma solidity ^0.8.0;

interface IDEXConstants {
    /**
     * @dev Returns the index of maker side in the swap components array.
     */
    function MAKER_SIDE() external pure returns (uint8);

    /**
     * @dev Returns the index of taker side in the swap components array.
     */
    function TAKER_SIDE() external pure returns (uint8);

    /**
     * @dev Returns the asset type for ERC1155 swap components.
     */
    function ERC1155_ASSET() external pure returns (uint8);

    /**
     * @dev Returns the asset type for ERC721 swap components.
     */
    function ERC721_ASSET() external pure returns (uint8);

    /**
     * @dev Returns the asset type for ERC20 swap components.
     */
    function ERC20_ASSET() external pure returns (uint8);

    /**
     * @dev Returns to asset type for Ether swap components.
     */
    function ETHER_ASSET() external pure returns (uint8);

    /**
     * @dev Returns the swap status for open (i.e. active) swaps.
     */
    function OPEN_SWAP() external pure returns (uint8);

    /**
     * @dev Returns the swap status for closed swaps.
     */
    function CLOSED_SWAP() external pure returns (uint8);

    /**
     * @dev Returns the swap status for dropped swaps.
     */
    function DROPPED_SWAP() external pure returns (uint8);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDEXAccessControl {
    /**
     * Return the locked state of the DEX.
     * In locked state, all transactional functions are disabled.
     * @return `True` if the DEX is in locked state, `false` if the DEX is in unlocked state.
     */
    function locked() external view returns (bool);

    /**
     * Return the deprecated state of the DEX.
     * In deprecated state, no new swaps can be opened. All other functions remain intact.
     * @return `True` if the DEX is in deprecated state.
     */
    function deprecated() external view returns (bool);

    /**
     * Lock the DEX in case of an emergency.
     * @param lock_ `True` to lock the DEX, `false` to unlock the DEX.
     */
    function lock(bool lock_) external;

    /**
     * Deprecate the DEX if a new contract is rolled out.
     * @param deprecate_ `True` to deprecate the DEX, `false` to lift DEX deprecation.
     */
    function deprecate(bool deprecate_) external;

    /**
     * Emitted when the DEX locked state changed, see :sol:func:`locked`.
     * @param locked_ `True` if the DEX was locked, `false` if the DEX was unlocked.
     */
    event Locked(bool locked_);

    /**
     * Emitted when the DEX deprecated state changed, see :sol:func:`deprecated`.
     * @param deprecated_ `True` if the DEX was deprecated, `false` if DEX deprecation was lifted.
     */
    event Deprecated(bool deprecated_);
}