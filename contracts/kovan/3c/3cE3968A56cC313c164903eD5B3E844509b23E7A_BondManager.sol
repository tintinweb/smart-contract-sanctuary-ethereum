// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interfaces/IFNFTBond.sol";

import "./other/Ownable.sol";

import "./interfaces/IERC20.sol";
import "./libraries/SafeERC20.sol";
import "./libraries/SafeMath.sol";
import "./interfaces/IFrankTreasury.sol";


contract BondDiscountable {

    ///@dev Discount index. Used to map the bonds sold.
    uint16 internal discountIndex = 0;
    
    /// @dev Keep track of how many bonds have been sold during a discount
    /// @dev discountedBondsSold[discountIndex][updateFactor][levelID]
    mapping(uint16 => mapping(uint16 => mapping(bytes4 => uint16))) internal discountedBondsSold;

    /// @notice Info of a discount
    /// @param startTime Timestamp of when discount should start
    /// @param endTime Timestamp of when discount should end
    /// @param discountRate Discount percentage (out of 100)
    /// @param updateFrequency Amount in seconds of how often discount price should update
    /// @param purchaseLimit Mapping of how many bonds per level can be minted every price update.
    struct Discount {
        uint256 startTime;
        uint256 endTime;
        uint16 discountRate;
        uint64 updateFrequency;
        mapping(bytes4 => uint8) purchaseLimit;
    }

    /// @notice Discounts mapping.
    /// @dev discount[discountIndex]
    mapping(uint16 => Discount) public discount;

    /// @notice Create a discount
    /// @param _startTime Timestamp at which discount will start 
    /// @param _endTime Timestamp at which discount will end
    /// @param _discountRate Discount percentage (out of 100)
    /// @param _updateFrequency Amount in seconds of how often discount price should update
    /// @param _purchaseLimit Mapping of how many bonds per level can be minted every price update.
    function _startDiscount(
        uint256 _startTime,
        uint256 _endTime,
        uint16 _discountRate,
        uint64 _updateFrequency,
        uint8[] memory _purchaseLimit,
        bytes4[] memory _levelIDs
    ) internal {
        uint256 cTime = block.timestamp;
        require(_startTime >= cTime, "Bond Discountable: Start timestamp must be > than current timestamp.");
        require(_endTime > _startTime, "Bond Discountable: End timestamp must be > than current timestamp."); 
        require(_updateFrequency < (_endTime - _startTime), "Bond Discountable: Update frequency must be < than discount duration."); 
        require((_endTime - _startTime) % _updateFrequency == 0, "Bond Discountable: Discount duration must be divisible by the update frequency.");
        require(_discountRate <= 100 && _discountRate > 0, "Bond Discountable: Discount rate must be a percentage.");
        require(!isDiscountPlanned(), "Bond Discountable: There is already a planned discount.");
        require(_levelIDs.length == _purchaseLimit.length, "Bond Discountable: Invalid amount of param array elements.");

        discount[discountIndex].startTime = _startTime;
        discount[discountIndex].endTime = _endTime;
        discount[discountIndex].discountRate = _discountRate;
        discount[discountIndex].updateFrequency = _updateFrequency;

        for(uint i = 0; i < _levelIDs.length; i++) {
            discount[discountIndex].purchaseLimit[_levelIDs[i]] = _purchaseLimit[i];
        }
    }

    /// @notice Deactivate and cancel the discount
    function _deactivateDiscount() internal {
        discountIndex++;
    }

    /// @notice Returns the discount updateFactor
    /// updateFactor is the nth discount price update
    function getDiscountUpdateFactor() internal view returns (uint8 updateFactor) {
        uint256 currentTime = block.timestamp;
        updateFactor = uint8((currentTime - discount[discountIndex].startTime) / discount[discountIndex].updateFrequency);
    }

    /// @notice Returns whether a discount is planned for the future
    function isDiscountPlanned() public view returns (bool) {
        return !(discount[discountIndex].startTime == 0);
    }

    /// @notice Returns whether a discount is currently active
    function isDiscountActive() public view returns (bool) {
        if (isDiscountPlanned()) {
            uint256 cTime = block.timestamp;
            if (discount[discountIndex].startTime < cTime && discount[discountIndex].endTime > cTime) {
                return true;
            }
        }

        return false;
    }

    /*
    function isDiscountActive() public view returns (bool) {
        if (isDiscountPlanned()) {
            uint256 cTime = block.timestamp;
            if (discount[discountIndex].startTime < cTime && discount[discountIndex].endTime > cTime) {
                return true;
            }
        }

        return false;
    }
    */
}

contract BondManager is Ownable, BondDiscountable {

    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    /// @notice fNFT Bond interface.
    IFNFTBond public bond;

    /// @notice Token used to mint Bonds and issue rewards.
    IERC20 public baseToken;

    IFrankTreasury public treasury;

    /// @notice Total number of unweighted shares.
    uint256 public totalUnweightedShares;
    /// @notice Total number of weighted shares.
    uint256 public totalWeightedShares;

    /// @notice Accumulated rewards per weigted shares. Used to calculate rewardDebt.
    uint256 public accRewardsPerWS = 0;
    /// @notice Accumulated shares per unweighted shares. Used to calculate shareDebt.
    uint256 public accSharesPerUS = 0;

    /// @dev Precision constants.
    uint256 private GLOBAL_PRECISION = 10**18;
    uint256 private WEIGHT_PRECISION = 100;

    /// @notice Whether bonds can be currently minted.
    bool public isSaleActive = true;

    event CreateDiscount (
        uint16 indexed discountIndex,
        uint256 startTime,
        uint256 endTime,
        uint16 discountRate,
        uint64 updateFrequency,
        uint8[] purchaseLimit
    );

    event Set (
        bool isSaleActive
    );

    event Update (
        uint256 issuedRewards,
        uint256 issuedShares
    );

    /// @param _bond fNFT Bond contract address.
    /// @param _baseToken Base Token contract address.
    /// @param _treasury Treasury address.
    constructor(address _bond, address _baseToken, address _treasury) {
        require(_bond != address(0));
        require(_baseToken != address(0));

        bond = IFNFTBond(_bond);
        baseToken = IERC20(_baseToken);

        setTreasury(_treasury);
    }

    function setTreasury(address _treasury) public onlyOwner {
        require(_treasury != address(0));

        treasury = IFrankTreasury(_treasury);
    }

    /// @notice external onlyOwner implementation of _startDiscount (BondDiscountable) function.
    /// @param _startAt Timestamp at which the discount will start.
    /// @param _endAt Timestamp at which the discount will end.
    /// @param _discountRate Discount percentage (out of 100).
    /// @param _updateFrequency Amount in seconds of how often discount price should update.
    /// @param _purchaseLimit Array of how many bonds per level can be minted every price update.
    function startDiscountAt(uint256 _startAt, uint256 _endAt, uint16 _discountRate, uint64 _updateFrequency, uint8[] memory _purchaseLimit) external onlyOwner {
        _startDiscount(_startAt, _endAt, _discountRate, _updateFrequency, _purchaseLimit, bond.getActiveBondLevels());
        emit CreateDiscount(discountIndex, _startAt, _endAt, _discountRate, _updateFrequency, _purchaseLimit);
    }

    /// @notice external onlyOwner implementation of _startDiscount (BondDiscountable) function.
    /// @param _startIn Amount of seconds until the discount start.
    /// @param _endIn Amount of seconds until the discount end.
    /// @param _discountRate Discount percentage (out of 100).
    /// @param _updateFrequency Amount in seconds of how often discount price should update.
    /// @param _purchaseLimit Array of how many bonds per level can be minted every price update.
    function startDiscountIn(uint256 _startIn, uint256 _endIn, uint16 _discountRate, uint64 _updateFrequency, uint8[] memory _purchaseLimit) external onlyOwner {
        uint256 cTime = block.timestamp;

        _startDiscount(cTime + _startIn, cTime + _endIn, _discountRate, _updateFrequency, _purchaseLimit, bond.getActiveBondLevels());
        emit CreateDiscount(discountIndex, cTime + _startIn, cTime + _endIn, _discountRate, _updateFrequency, _purchaseLimit);
    }

    /// @notice external onlyOwner implementation of _deactivateDiscount (BondDiscountable) function
    function deactivateDiscount() external onlyOwner {
        _deactivateDiscount();
    }

    /// @notice external onlyOwner implementation of _addBondLevelAtIndex (fNFT Bond) function.
    /// @param _name Bond level name. Showed on Farmer Frank's UI.
    /// @param _price Bond base price. Meaning that price doesn't take into account decimals (ex 10**18).
    /// @param _weight Weight percentage of Bond level (>= 100).
    /// @dev Doesn't take _index as a parameter and appends the Bond level at the end of the active levels array.
    function addBondLevel(string memory _name, uint256 _price, uint16 _weight, uint32 _sellableAmount) external onlyOwner returns (bytes4) {
        return bond._addBondLevelAtIndex(_name, _price, _weight,  _sellableAmount, bond.totalActiveBondLevels());
    }

    /// @notice external onlyOwner implementation of _addBondLevelAtIndex (fNFT Bond) function.
    /// @param _name Bond level name. Showed on Farmer Frank's UI.
    /// @param _price Bond base price. Meaning that price doesn't take into account decimals (ex 10**18).
    /// @param _weight Weight percentage of Bond level (>= 100).
    /// @param _index Index of activeBondLevels array where the Bond level will be inserted.
    function addBondLevelAtIndex(string memory _name, uint256 _price, uint16 _weight, uint32 _sellableAmount, uint16 _index) external onlyOwner returns (bytes4) {
        return bond._addBondLevelAtIndex(_name, _price, _weight, _sellableAmount, _index);
    }

    /// @notice external onlyOwner implementation of _changeBondLevel (fNFT Bond) function.
    /// @param levelID Bond level hex ID being changed.
    /// @param _name New Bond level name.
    /// @param _price New Bond base price.
    /// @param _weight New Weight percentage of Bond level (>= 100).
    function changeBondLevel(bytes4 levelID, string memory _name, uint256 _price, uint16 _weight, uint32 _sellableAmount) external onlyOwner {
        bond._changeBondLevel(levelID, _name, _price, _weight, _sellableAmount);
    }

    /// @notice external onlyOwner implementation of _deactivateBondLevel (fNFT Bond) function.
    /// @param levelID Bond level hex ID.
    function deactivateBondLevel(bytes4 levelID) external onlyOwner {
        bond._deactivateBondLevel(levelID);
    }

    /// @notice external onlyOwner implementation of _activateBondLevel (fNFT Bond) function.
    /// @param levelID Bond level hex ID.
    /// @param _index Index of activeBondLevels array where the Bond level will be inserted.
    function activateBondLevel(bytes4 levelID, uint16 _index) external onlyOwner {
        bond._activateBondLevel(levelID, _index);
    }

    /// @notice Rearrange bond level in activeBondLevels array.
    /// @param levelID Bond level hex ID.
    /// @param _index Index of activeBondLevels array where the Bond level will be rearranged.
    /// @dev Simply it removes the Bond level from the array and it adds it back to the desired index.
    function rearrangeBondLevel(bytes4 levelID, uint16 _index) external onlyOwner {
        bond._deactivateBondLevel(levelID);
        bond._activateBondLevel(levelID, _index);
    }

    /// @notice external onlyOnwer implementation of setBaseURI (fNFT Bond function)
    /// @param baseURI_ string to set as baseURI
    function setBaseURI(string memory baseURI_) external onlyOwner {
        return bond.setBaseURI(baseURI_);
    }

    /// @notice Toggle fNFT Bond sale
    function toggleSale() external onlyOwner {
        isSaleActive = !isSaleActive;
        emit Set(isSaleActive);
    }

    /// @notice Public function that users will be utilizing to mint their Bond.
    /// @param levelID Bond level hex ID (provided by the dAPP or retreived through getActiveBondLevels() in fNFT Bond contract).
    /// @param _amount Amount of fNFT Bonds being minted. Remember there is a limit of 20 Bonds per transaction.
    function createMultipleBondsWithTokens(bytes4 levelID, uint16 _amount) public {
        require(isSaleActive);
        require(_amount > 0);

        address sender = _msgSender();
        require(sender != address(0), "fNFT Bond Manager: Creation from the zero address is prohibited.");

        // Gets price and whether there is a discount.
        (uint256 bondPrice, bool discountActive) = getPrice(levelID);

        // If there is a discount, contract must check that there are enough Bonds left for that discount updateFactor period.
        if(discountActive) {
            uint8 updateFactor = getDiscountUpdateFactor();
            uint16 _bondsSold = uint16(SafeMath.add(discountedBondsSold[discountIndex][updateFactor][levelID], _amount));
            require(_bondsSold <= discount[discountIndex].purchaseLimit[levelID], "C01");

            // If there are, it increments the mapping by the amount being minted.
            discountedBondsSold[discountIndex][updateFactor][levelID] = _bondsSold;
        }

        // Checks that buyer has enough funds to mint the bond.
        require(baseToken.balanceOf(sender) >= bondPrice * _amount, "C02");

        // Transfers funds to trasury contract.
        //baseToken.safeTransferFrom(_msgSender(), address(this), SafeMath.mul(bondPrice, _amount));
        treasury.bondDeposit(bondPrice * _amount, sender);

        // Increments shares metrics.
        totalUnweightedShares += bondPrice * _amount;
        totalWeightedShares += ((bondPrice * bond.getBondLevel(levelID).weight / WEIGHT_PRECISION) * _amount);

        // Call fNFT mintBond function.
        //bond.mintBonds(sender, levelID, uint8(_amount), bondPrice);
    }

    /// @notice Deposit rewards and shares for users to be claimed to this contract.
    /// @param _issuedRewards Amount of rewards to be deposited to the contract claimable by users.
    /// @param _issuedShares Amount of new shares claimable by users.
    function depositRewards(uint256 _issuedRewards, uint256 _issuedShares) external {
        require(_msgSender() == address(treasury));

        baseToken.transferFrom(_msgSender(), address(this), _issuedRewards);

        // Increase accumulated shares and rewards.
        accSharesPerUS += _issuedShares * GLOBAL_PRECISION / totalUnweightedShares;
        accRewardsPerWS += _issuedRewards * GLOBAL_PRECISION / totalWeightedShares;

        emit Update(_issuedRewards, _issuedShares);
    }

    /// @notice Internal claim function.
    /// @param _bondID Unique fNFT Bond uint ID.
    /// @param sender Transaction sender.
    function _claim(uint256 _bondID, address sender) internal {
        (uint256 claimableShares, uint256 claimableRewards) = getClaimableAmounts(_bondID);
        require((claimableShares != 0 || claimableRewards != 0));

        // the bond.claim() call below will increase the underlying shares for _bondID, thus we must increment the total number of shares as well.
        totalUnweightedShares += claimableShares;
        totalWeightedShares += claimableShares * bond.getBond(_bondID).weight / WEIGHT_PRECISION;

        // Call fNFT claim function which increments shares and debt.
        bond.claim(sender, _bondID, claimableRewards, claimableShares);

        // Send rewards to user.
        baseToken.safeTransfer(sender, claimableRewards);
    }

    /// @notice Public implementation of _claim function.
    /// @param _bondID Unique fNFT Bond uint ID.
    function claim(uint256 _bondID) public {
        address sender = _msgSender();
        _claim(_bondID, sender);
    }

    /// @notice Claim rewards and shares for all Bonds owned by the sender.
    /// @dev Should the sender own many bonds, the function will fail due to gas constraints.
    /// Therefore this function will be called from the dAPP only when it verifies that a
    /// user owns a low / moderate amount of Bonds.
    function claimAll() public {
        address sender = _msgSender();

        uint256[] memory bondsIDsOf = bond.getBondsIDsOf(sender);

        for(uint i = 0; i < bondsIDsOf.length; i++) {
            _claim(bondsIDsOf[i], sender);
        }
    }

    /// @notice Claim rewards and shares for Bonds in an array.
    /// @dev If the sender owns many Bonds, calling multiple transactions is necessary.
    /// dAPP will query off-chain (requiring 0 gas) all Bonds IDs owned by the sender.
    /// It will divide the array in smaller chunks and will call this function multiple
    /// times until rewards are claimed for all Bonds. 
    function batchClaim(uint256[] memory _bondIDs) public {
        for(uint i = 0; i < _bondIDs.length; i++) {
            claim(_bondIDs[i]);
        }
    }

    /// @notice Get the price for a particular Bond level.
    /// @param levelID Bond level hex ID
    function getPrice(bytes4 levelID) public view returns (uint256, bool) {
        // Multiplies base price by GLOBAL_PRECISION (token decimals)
        
        uint256 price = bond.getBondLevel(levelID).price;
        if(isDiscountActive()) {
            // Calculates total number of price updates during the discount time frame.
            uint256 totalUpdates = (discount[discountIndex].endTime - discount[discountIndex].startTime) / discount[discountIndex].updateFrequency;
            // Calculates the price when discount starts: the lowest price. Simply, the base price discounted by the discount rate.
            uint256 discountStartPrice = price - ((price * discount[discountIndex].discountRate) / 100);
            // Calculates how much price will increase at every price update.
            uint256 updateIncrement = (price - discountStartPrice) / totalUpdates;
            // Finally calcualtes the price using the above variables.
            return (discountStartPrice + (updateIncrement * getDiscountUpdateFactor()), true);
        } else {
            return (price, false);
        }
        
    }

    /// @notice Get claimable amount of shares and rewards for a particular Bond.
    /// @param _bondID Unique fNFT Bond uint ID
    function getClaimableAmounts(uint256 _bondID) public view returns (uint256 claimableShares, uint256 claimableRewards) {
        IFNFTBond.Bond memory _bond = bond.getBond(_bondID);

        claimableShares = (_bond.unweightedShares * accSharesPerUS / GLOBAL_PRECISION) - _bond.shareDebt;
        claimableRewards = (_bond.weightedShares * accRewardsPerWS / GLOBAL_PRECISION) - _bond.rewardDebt;
    }

    function linkBondManager() external onlyOwner {
        bond._linkBondManager(address(this));
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes memory) {
        this;
        return msg.data;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./context.sol";

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(_owner == _msgSender(), "Ownable: caller is not the owner");
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
        require(
            newOwner != address(0),
            "Ownable: new owner is the zero address"
        );
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
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
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
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
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
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
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
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
        // Gas optimization: this is TKNaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouTKNd) while Solidity
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
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouTKNd) while Solidity uses an
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
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./Address.sol";
import "../interfaces/IERC20.sol";

library SafeERC20 {
    using Address for address;

    function safeTransfer(
        IERC20 token,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transfer.selector, to, value)
        );
    }

    function safeTransferFrom(
        IERC20 token,
        address from,
        address to,
        uint256 value
    ) internal {
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.transferFrom.selector, from, to, value)
        );
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
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(token.approve.selector, spender, value)
        );
    }

    function safeIncreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        uint256 newAllowance = token.allowance(address(this), spender) + value;
        _callOptionalReturn(
            token,
            abi.encodeWithSelector(
                token.approve.selector,
                spender,
                newAllowance
            )
        );
    }

    function safeDecreaseAllowance(
        IERC20 token,
        address spender,
        uint256 value
    ) internal {
        unchecked {
            uint256 oldAllowance = token.allowance(address(this), spender);
            require(
                oldAllowance >= value,
                "SafeERC20: decreased allowance below zero"
            );
            uint256 newAllowance = oldAllowance - value;
            _callOptionalReturn(
                token,
                abi.encodeWithSelector(
                    token.approve.selector,
                    spender,
                    newAllowance
                )
            );
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

        bytes memory returndata = address(token).functionCall(
            data,
            "SafeERC20: low-level call failed"
        );
        if (returndata.length > 0) {
            // Return data is optional
            require(
                abi.decode(returndata, (bool)),
                "SafeERC20: ERC20 operation did not succeed"
            );
        }
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(
            address(this).balance >= amount,
            "Address: insufficient balance"
        );

        (bool success, ) = recipient.call{value: amount}("");
        require(
            success,
            "Address: unable to send value, recipient may have reverted"
        );
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
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
        return
            functionCallWithValue(
                target,
                data,
                value,
                "Address: low-level call with value failed"
            );
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
        require(
            address(this).balance >= value,
            "Address: insufficient balance for call"
        );
        require(isContract(target), "Address: call to non-contract");

        (bool success, bytes memory returndata) = target.call{value: value}(
            data
        );
        return verifyCallResult(success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data)
        internal
        view
        returns (bytes memory)
    {
        return
            functionStaticCall(
                target,
                data,
                "Address: low-level static call failed"
            );
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
    function functionDelegateCall(address target, bytes memory data)
        internal
        returns (bytes memory)
    {
        return
            functionDelegateCall(
                target,
                data,
                "Address: low-level delegate call failed"
            );
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

interface IFrankTreasury {
    function BondManager() external view returns (address);
    function JOE() external view returns (address);
    function SJoeStaking() external view returns (address);
    function TraderJoeRouter() external view returns (address);
    function VeJoeStaking() external view returns (address);
    function owner() external view returns (address);
    function renounceOwnership() external;
    function strategy() external view returns ( uint16 PROPORTION_REINVESTMENTS, address LIQUIDITY_POOL);
    function transferOwnership(address newOwner) external;
    function setBondManager(address _bondManager) external;
    function setFee(uint256 _fee) external;
    function setDistributionThreshold(uint256 _threshold) external;
    function setStrategy(uint16[2] memory _DISTRIBUTION_BONDED_JOE, uint16[3] memory _DISTRIBUTION_REINVESTMENTS, uint16 _PROPORTION_REINVESTMENTS, address _LIQUIDITY_POOL) external;
    function distribute() external;
    function bondDeposit(uint256 _amount, address _sender) external;
    function addAndFarmLiquidity(uint256 _amount, address _pool) external;
    function removeLiquidity(uint256 _amount, address _pool) external;
    function harvest() external;
    function execute(address target, uint256 value, bytes calldata data) external returns ( bool, bytes memory );
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0; 

interface IFNFTBond {

    struct Bond {
        uint256 bondID;
        uint48 mint;
        bytes4 levelID;
        uint16 weight;
        uint256 earned;
        uint256 unweightedShares;
        uint256 weightedShares;
        uint256 rewardDebt;
        uint256 shareDebt;
    }

    struct BondLevel {
        bytes4 levelID;
        bool active;
        uint256 price;
        uint16 weight;
        uint64 sellableAmount;
        string name;
    }

    function bondManager() external view returns (address);

    function totalActiveBondLevels() external view returns (uint8);

    function _linkBondManager(address _bondManager) external;

    function _addBondLevelAtIndex(string memory _name, uint256 _price, uint16 _weight, uint32 _sellableAmount, uint16 _index) external returns (bytes4);

    function _changeBondLevel(bytes4 levelID, string memory _name, uint256 _price, uint16 _weight, uint32 _sellableAmount) external;

    function _deactivateBondLevel(bytes4 levelID) external;

    function _activateBondLevel(bytes4 levelID, uint16 _index) external;

    function mintBonds(address _account, bytes4 levelID, uint8 _amount, uint256 _price) external;

    function claim(address _account, uint256 _bondID, uint256 issuedRewards, uint256 issuedShares) external;

    function setBaseURI(string memory baseURI_ ) external;

    function getActiveBondLevels() external view returns (bytes4[] memory);

    function getBondLevel(bytes4 _levelID) external view returns (BondLevel memory);

    function getBond(uint256 _bondID) external view returns (Bond memory);

    function getBondsIDsOf(address _account) external view returns (uint256[] memory);

    function tokenURI(uint256 _bondID) external view returns (string memory);

}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

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
    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

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
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}