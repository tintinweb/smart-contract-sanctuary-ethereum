//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title AmericanaFactory
 * @author floop (floop.eth)
 * @notice This contract is used to facilitate new physical item listings and their accompanied
 *          escrow's on the Americana Marketplace.
 */

interface IMinter {
  function mint(address, uint256) external;
}

contract AmericanaFactory is ReentrancyGuard {
  string public constant implementation = "AmericanaFactory";
  string public constant version = "1.0";

  IMinter public MinterContract;

  event ListingCreated(uint24 _itemId, address _seller, uint256 _amount);
  event EscrowCreated(uint24 _itemId, address _buyer, uint256 _amount);
  event EscrowApproved(address _buyer, address _seller, uint256 _amount);
  event EscrowRejected(address _buyer, address _seller, uint256 _amount);
  event NewAuthorization(address _newAuthorized);
  event RemoveAuthorization(address _removeAuthorized);
  event FeeChange(uint256 _oldFee, uint256 _newFee);
  event EscrowFundsWithdrawal(uint256 _escrowId, uint256 _ammount, address _recipient);
  event ContractPauseSwap(bool _swappedTo);
  event FeesWithdrawal(address _feeRecipient, uint256 _pendingFees);
  event BuyerWantsPhysical(address _buyer, uint256 _escrowID);
  event NFTMinted(address _buyer, uint256 _escrowID);
  event NFTAvailableToMint(address _buyer, uint256 _escrowID);
  event NewMintAddress(address _newMintContractAddress);
  event UpdateEscrowType(uint256 _escrowID, bool _wantsNFT);
  event NewMaxEscrowDuration(uint8 _days);

  error Unauthorized();
  error ListingActive();
  error EscrowActive();
  error ListingInactive();
  error EscrowInactive();
  error ZeroPrice();
  error ImproperValueSent();
  error ImproperItemID();
  error WithdrawalFail();
  error Ineligible();
  error Paused();

  modifier onlyAuthorized() {
    if (isAuthorized[msg.sender] == false) revert Unauthorized();
    _;
  }
  modifier notPaused() {
    if (paused == true) revert Paused();
    _;
  }

  struct Escrow {
    address payable buyer;
    uint32 timestamp; // good until year 2106
    uint24 itemID; // 16,777,215 possibilities
    bool wantsNFT;
  }

  struct Listing {
    address payable seller;
    uint72 price; // max 4726 ether
    uint24 itemID; // 16,777,215 possibilities
  }

  address payable public feeRecipient;
  address public AmericanaMintAddress;

  bool public paused;

  uint32 public maxEscrowDuration;

  uint256 public marketFee;
  uint256 public pendingFees;

  mapping(address => bool) public isAuthorized;
  mapping(uint24 => Escrow) public escrowByID;
  mapping(uint24 => Listing) public listingsByID;
  mapping(uint24 => bool) public availableToMint;

  // IMPORTANT!: For future reference, when adding new variables for following versions of the factory.
  // All the previous ones should be kept in place and not change locations, types or names.
  // If they're modified this would cause issues with the memory slots.

  constructor(
    address payable _feeRecipient,
    uint8 _maxEscrowDurationInDays,
    uint256 _marketFee,
    address _minterAddress,
    address admin
  ) {
    isAuthorized[msg.sender] = true;
    isAuthorized[admin] = true;
    maxEscrowDuration = _maxEscrowDurationInDays * 86400; //1 day
    pendingFees = 0;
    paused = false;
    marketFee = _marketFee;
    feeRecipient = _feeRecipient;
    AmericanaMintAddress = _minterAddress;
    MinterContract = IMinter(_minterAddress);
  }

  //REMOVE THIS BEFORE MAINNET DEPLOYEMENT, USED TO SELF DESTRUCT TESTING CONTRACTS
  //REMOVE THIS BEFORE MAINNET DEPLOYEMENT, USED TO SELF DESTRUCT TESTING CONTRACTS
  //REMOVE THIS BEFORE MAINNET DEPLOYEMENT, USED TO SELF DESTRUCT TESTING CONTRACTS
  //REMOVE THIS BEFORE MAINNET DEPLOYEMENT, USED TO SELF DESTRUCT TESTING CONTRACTS
  function _selfDesctruct(address payable receiver) public {
    selfdestruct(receiver);
  }

  //we cant gurantee that people wont make listings with itemids that we  did not provide them.

  //so we will have to track legit items on backend to display and query contract before issuing new itemids.

  //this also means that someone could in theory pay like $4 per listing and start eating up itemID's
  function createListing(uint24 _itemId, uint72 _price) external notPaused {
    if (listingsByID[_itemId].price != 0) revert ImproperItemID();
    if (_price == 0) revert ZeroPrice();

    listingsByID[_itemId] = Listing(payable(msg.sender), _price, _itemId);
    emit ListingCreated(_itemId, msg.sender, _price);
  }

  function createEscrow(uint24 _itemid, bool _wantsNFT) external payable notPaused {
    if (listingsByID[_itemid].seller == payable(address(0))) revert ListingInactive();
    if (escrowByID[_itemid].buyer != payable(address(0))) revert EscrowActive();
    if (listingsByID[_itemid].price != msg.value) revert ImproperValueSent();

    escrowByID[_itemid] = Escrow(payable(msg.sender), uint32(block.timestamp), _itemid, _wantsNFT);

    emit EscrowCreated(_itemid, msg.sender, msg.value);
  }

  function mint(uint24 _itemid) external notPaused {
    if (availableToMint[_itemid] == false) revert Ineligible();

    availableToMint[_itemid] = false;

    MinterContract.mint(escrowByID[_itemid].buyer, 1);

    emit NFTMinted(escrowByID[_itemid].buyer, _itemid);

    escrowByID[_itemid].buyer = payable(address(0));
  }

  //used to solidify max authenitication time and reduce chance of funds locking in contract
  function withdrawEscrowFunds(uint24 _itemid) external nonReentrant {
    if (escrowByID[_itemid].buyer != msg.sender) revert Ineligible();
    if (listingsByID[_itemid].seller == payable(address(0))) revert Ineligible();
    if (block.timestamp < escrowByID[_itemid].timestamp + maxEscrowDuration) revert Ineligible();

    (bool success, ) = escrowByID[_itemid].buyer.call{ value: listingsByID[_itemid].price }("");
    if (success == false) revert WithdrawalFail();

    escrowByID[_itemid].buyer = payable(address(0));

    emit EscrowFundsWithdrawal(_itemid, listingsByID[_itemid].price, escrowByID[_itemid].buyer);
  }

  //Authorized functions

  //deal with funds of items that pass authentication
  function approveItem(uint24 _itemid) external onlyAuthorized nonReentrant {
    if (escrowByID[_itemid].buyer == payable(address(0))) revert EscrowInactive();
    if (listingsByID[_itemid].seller == payable(address(0))) revert ListingInactive();

    uint256 fee = (marketFee * listingsByID[_itemid].price) / 1000;

    pendingFees += fee;

    (bool success, ) = listingsByID[_itemid].seller.call{ value: listingsByID[_itemid].price - fee }("");
    if (success == false) revert WithdrawalFail();

    if (escrowByID[_itemid].wantsNFT) {
      availableToMint[_itemid] = true;
      emit NFTAvailableToMint(escrowByID[_itemid].buyer, _itemid);
    } else {
      emit BuyerWantsPhysical(escrowByID[_itemid].buyer, _itemid);
    }

    emit EscrowApproved(escrowByID[_itemid].buyer, listingsByID[_itemid].seller, listingsByID[_itemid].price);

    listingsByID[_itemid].seller = payable(address(0));
  }

  //deal with funds of items that fail authentication
  function rejectItem(uint24 _itemid) external onlyAuthorized nonReentrant {
    if (escrowByID[_itemid].buyer == payable(address(0))) revert EscrowInactive();
    if (listingsByID[_itemid].seller == payable(address(0))) revert ListingInactive();

    (bool success, ) = escrowByID[_itemid].buyer.call{ value: listingsByID[_itemid].price }("");
    if (success == false) revert WithdrawalFail();

    emit EscrowRejected(escrowByID[_itemid].buyer, listingsByID[_itemid].seller, listingsByID[_itemid].price);

    escrowByID[_itemid].buyer = payable(address(0));
    listingsByID[_itemid].seller = payable(address(0));
  }

  function swapPause() external onlyAuthorized {
    paused = !paused;

    emit ContractPauseSwap(!paused);
  }

  function changeMaxEscrowDuration(uint8 _days) external onlyAuthorized {
    require(_days >= 14 && _days <= 30);

    maxEscrowDuration = _days * 86400; //1 day

    emit NewMaxEscrowDuration(_days);
  }

  function addAuthorized(address addressToAuthorize) external onlyAuthorized {
    isAuthorized[addressToAuthorize] = true;

    emit NewAuthorization(addressToAuthorize);
  }

  function removeAuthorized(address addressToRemoveAuthorize) external onlyAuthorized {
    isAuthorized[addressToRemoveAuthorize] = false;

    emit RemoveAuthorization(addressToRemoveAuthorize);
  }

  function updateEscrowType(uint24 _itemid, bool _wantsNFT) external onlyAuthorized {
    require(escrowByID[_itemid].wantsNFT != _wantsNFT, "AmericanaFactory: Updating to same type");
    escrowByID[_itemid].wantsNFT = _wantsNFT;

    emit UpdateEscrowType(_itemid, _wantsNFT);
  }

  //struct getters
  function getEscrowByID(uint24 _itemid) external view returns (Escrow memory) {
    return escrowByID[_itemid];
  }

  function getListingByID(uint24 _itemid) external view returns (Listing memory) {
    return listingsByID[_itemid];
  }

  //fee stuff
  function changeMarketFee(uint256 newFee) external onlyAuthorized {
    require(newFee <= 100, "AmericanaFactory: Max fee of 10%");
    marketFee = newFee;

    emit FeeChange(marketFee, newFee);
  }

  function withdrawFees() external onlyAuthorized {
    require(pendingFees > 0, "AmericanaFactory: No fees to withdraw");
    uint256 fees = pendingFees;
    pendingFees = 0;
    (bool success, ) = feeRecipient.call{ value: fees }("");
    require(success, "AmericanaFactory: Failed to withdraw ether");

    emit FeesWithdrawal(feeRecipient, pendingFees);
  }

  //contract interoperability
  function updateMinterAddress(address _newMinter) external onlyAuthorized {
    AmericanaMintAddress = _newMinter;
    MinterContract = IMinter(_newMinter);
    emit NewMintAddress(_newMinter);
  }

  //reverts any eth sent to contract
  receive() external payable {
    revert("Contract cannot receive ether");
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

    constructor()  {
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