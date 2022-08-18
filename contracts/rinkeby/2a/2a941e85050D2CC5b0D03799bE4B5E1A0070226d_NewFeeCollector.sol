// SPDX-License-Identifier: MIT
pragma solidity ^0.8.1;
import "@openzeppelin/contracts/access/Ownable.sol";

contract NewFeeCollector is Ownable {
    address public marketplace;
    address public hexArtMarketplace;
    uint256 public HSIMarketPlaceCollection;
    uint256 public HexartMarketPlaceCollection;
    uint256 public HexartArtistFeeCollection;

    enum COLLECTORTYPES {
        BUYBURN,
        BUYDISTRIBUTE,
        HEXMARKET,
        HEDRONFLOW,
        BONUS
    }

    struct FeesCollectors {
        address payable feeAddress;
        uint256 share;
        uint256 hexArtShare;
        uint256 artistShare;
        uint256 amount;
        uint256 enumId;
    }

    mapping(uint256 => FeesCollectors) public feeMap;

    /*
     *@notice Set Marketplace address.
     *@param _marketplace address
     */
    function setMarketAddress(address _marketplace) public onlyOwner {
        require(_marketplace != address(0), "Zero address is not allowed.");
        require(
            _marketplace != marketplace,
            "Cannot add the same address as marketplace"
        );

        marketplace = _marketplace;
    }

    /*
     *@notice Set Hexart Marketplace address.
     *@param _marketplace address
     */
    function setHexArtMarketAddress(address _marketplace) public onlyOwner {
        require(_marketplace != address(0), "Zero address is not allowed.");
        require(
            _marketplace != marketplace,
            "Cannot add the same address as marketplace"
        );

        hexArtMarketplace = _marketplace;
    }

    /*
     *@notice Set Fee collector wallet details
     *@param feeType COLLECTORTYPES(enum)
     *@param wallet address payable
     *@param share uint256
     */
    function setFees(
        COLLECTORTYPES feeType,
        address payable wallet,
        uint256 share,
        uint256 _hexArtShare,
        uint256 _artistShare
    ) external onlyOwner {
        require(wallet != address(0), "Zero address not allowed");
        require(share != 0, "Share must be greater than 0.");

        feeMap[uint256(feeType)] = FeesCollectors({
            feeAddress: wallet,
            share: share,
            hexArtShare: _hexArtShare,
            artistShare: _artistShare,
            amount: 0,
            enumId: uint256(feeType)
        });
    }

    /*
     *@notice Update Fee collector wallet address and share
     *@param feeType COLLECTORTYPES(enum)
     *@param wallet address payable
     *@param share uint256
     */
    function updateFees(
        COLLECTORTYPES feeType,
        address payable wallet,
        uint256 share,
        uint256 _hexArtShare,
        uint256 _artistShare
    ) external onlyOwner {
        require(wallet != address(0), "Zero address not allowed");
        require(share != 0, "Share must be greater than 0.");

        feeMap[uint256(feeType)] = FeesCollectors({
            feeAddress: wallet,
            share: share,
            hexArtShare: _hexArtShare,
            artistShare: _artistShare,
            amount: feeMap[uint256(feeType)].amount,
            enumId: uint256(feeType)
        });
    }

    /*
     *@notice Assigns fees amount to fee collector structs
     *@param uint256 value, buying amount for NFT, recieved from marketplace
     *@param uint256 addShare, total fees share amount for NFT, recieved from marketplace
     */
    function manageFees(uint256 value, uint256 addShare) external {
        require(msg.sender == marketplace, "Only marketplace are allowed");

        for (uint256 i = 0; i < 5; i++) {
            uint256 shareAmount = updateAmount(i, value, addShare);
            addShare = addShare - shareAmount;
        }
    }

    function manageHexArtFees(uint256 value) external returns (bool) {
        require(
            msg.sender == hexArtMarketplace,
            "Only marketplace are allowed"
        );
        for (uint256 i = 0; i < 5; i++) {
            updateHexArtAmount(i, value);
        }
        return true;
    }

    function manageArtistFees(uint256 value) external returns (bool) {
        require(
            msg.sender == hexArtMarketplace,
            "Only marketplace are allowed"
        );
        for (uint256 i = 0; i < 5; i++) {
            updateArtistAmount(i, value);
        }
        return true;
    }

    /*
     *@notice Update amount to fee collector structs used by manageFees function
     *@param  uint256 id, Index of COLLECTORTYPES
     *@param uint256 value, buying amount for NFT, recieved from marketplace
     *@param uint256 addShare, total fees share amount for NFT, recieved from marketplace
     */
    function updateAmount(
        uint256 id,
        uint256 value,
        uint256 addShare
    ) internal returns (uint256) {
        uint256 shareAmount = (value * feeMap[id].share) / 1000000;
        if (shareAmount <= addShare) {
            feeMap[id].amount = feeMap[id].amount + shareAmount;
            HSIMarketPlaceCollection = HSIMarketPlaceCollection + shareAmount;
        } else {
            feeMap[id].amount = feeMap[id].amount + addShare;
            HSIMarketPlaceCollection = HSIMarketPlaceCollection + addShare;
        }

        return shareAmount;
    }

    /*
     *@notice Update amount to fee collector structs used by manageFees function
     *@param  uint256 id, Index of COLLECTORTYPES
     *@param uint256 value, buying amount for NFT, recieved from marketplace
     *@param uint256 addShare, total fees share amount for NFT, recieved from marketplace
     */
    function updateHexArtAmount(uint256 id, uint256 value)
        internal
        returns (uint256)
    {
        uint256 shareAmount = (value * feeMap[id].hexArtShare) / 1000000;

        feeMap[id].amount = feeMap[id].amount + shareAmount;
        HexartMarketPlaceCollection = HexartMarketPlaceCollection + shareAmount;

        return shareAmount;
    }

    /*
     *@notice Update amount to fee collector structs used by manageFees function
     *@param  uint256 id, Index of COLLECTORTYPES
     *@param uint256 value, buying amount for NFT, recieved from marketplace
     *@param uint256 addShare, total fees share amount for NFT, recieved from marketplace
     */
    function updateArtistAmount(uint256 id, uint256 value)
        internal
        returns (uint256)
    {
        uint256 shareAmount = (value * feeMap[id].artistShare) / 100;

        feeMap[id].amount = feeMap[id].amount + shareAmount;
        HexartArtistFeeCollection = HexartArtistFeeCollection + shareAmount;

        return shareAmount;
    }

    /*
     @notice Claim Balance for the type of COLLECTORTYPES
     *@param  uint256 id, Index of COLLECTORTYPES
    */
    function claimBalances(uint256 id) internal {
        uint256 totalAmount = (feeMap[id].amount);
        require(
            totalAmount <= getBalance() && totalAmount > 0,
            "Not enough balance to claim"
        );

        feeMap[id].feeAddress.transfer(feeMap[id].amount);
        feeMap[id].amount = 0;
    }

    /*
     *@notice Claim Hexmarket amount
     */
    function claimHexmarket() external {
        uint256 id = uint256(COLLECTORTYPES.HEXMARKET);
        claimBalances(id);
        claimHedronFlow();
    }

    /*
     *@notice Claim Bonus amount
     */
    function claimBonus() external {
        uint256 id = uint256(COLLECTORTYPES.BONUS);
        claimBalances(id);
    }

    /*
     *@notice Claim HedronFlow amount
     */
    function claimHedronFlow() public {
        uint256 id = uint256(COLLECTORTYPES.HEDRONFLOW);
        claimBalances(id);
    }

    /*
     *@notice Claim Buy and Burn amount
     */
    function claimBuyBurn() external {
        uint256 id = uint256(COLLECTORTYPES.BUYBURN);
        claimBalances(id);
    }

    /*
     *@notice Claim Buy and distribute  amount.
     */
    function claimBuyDistribute() external {
        uint256 id = uint256(COLLECTORTYPES.BUYDISTRIBUTE);
        claimBalances(id);
    }

    /*
     *@notice  Get balance of this contract.
     *@return uint
     */
    function getBalance() internal view returns (uint256) {
        return address(this).balance;
    }

    /*
     *  @notice Withdraw the extra eth available after distribution.
     */
    function withdrawDust() external onlyOwner {
        uint256 withdrawableAmount;
        uint256 nonwithdrawableAmount;
        for (uint256 i = 0; i < 5; i++) {
            nonwithdrawableAmount += feeMap[i].amount;
        }
        withdrawableAmount = address(this).balance - nonwithdrawableAmount;
        require(withdrawableAmount > 0, "No extra ETH is available");
        payable(msg.sender).transfer(withdrawableAmount);
    }

    receive() external payable {}
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