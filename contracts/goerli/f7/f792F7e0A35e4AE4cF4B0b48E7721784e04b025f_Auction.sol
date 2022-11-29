// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

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
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

pragma solidity ^0.8.9;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/// @author Nikita Lyapin<[email protected]>
contract Auction is ReentrancyGuard {

    event ActiveCreated(
        address indexed owner
    );

    event LotListed(
        address indexed seller,
        uint256 price
    );

    event OfferReceived(
        address indexed seller,
        address indexed buyer,
        uint256 price
    );

    event OfferMade(
        address indexed buyer,
        uint256 price
    );

    event ActiveSold(
        address indexed buyer,
        uint256 price
    );

    struct Active {
        address owner;
    }

    struct Lot {
        bool availableForPurchase;
        address bestOfferInitiator;
        uint256 bestOfferPrice;
        uint256 price;
    }

    Active[] public allActives;

    mapping(uint256 => Lot) public allLots;

    receive() external payable {
        revert();
    }

    fallback() external payable {

    }

    modifier onlyHolder(uint256 _activeId) {
        require(allActives[_activeId].owner == msg.sender, "NAO");
        _;
    }

    modifier activeExists(uint256 _activeId) {
        require(_activeId < allActives.length, "");
        _;
    }

    function createActive() external {
        Active memory active = Active(msg.sender);

        allActives.push(active);

        emit ActiveCreated(msg.sender);
    }

    function listActiveForSale(uint256 _activeId, uint256 _price)
        external
        onlyHolder(_activeId)
        activeExists(_activeId)
    {
        // Lot not active
        require(allLots[_activeId].availableForPurchase == false, "LOA");

        Lot memory freshLot = Lot(true, address(0), 0, _price);

        allLots[_activeId] = freshLot;

        emit LotListed(msg.sender, _price);
    }

    function dropLot(uint256 _activeId) external onlyHolder(_activeId) {
        Lot memory lot = allLots[_activeId];
        lot.availableForPurchase = false;
        lot.bestOfferInitiator = address(0);
        lot.bestOfferPrice = 0;
        lot.price = 0;
        
        allLots[_activeId] = lot;
    }
    
    function acceptOffer(uint256 _activeId)
        external
        onlyHolder(_activeId)
        activeExists(_activeId)
        nonReentrant
    {
        Lot memory activeLot = allLots[_activeId];
        
        // Purchase not enabled
        require(activeLot.availableForPurchase == true, "PNE");
        // Zero price provided
        require(activeLot.bestOfferPrice > 0, "ZPP");
        // Zero address provided
        require(activeLot.bestOfferInitiator != address(0), "ZAP");
        // Don't be silly
        require(activeLot.price <= activeLot.bestOfferPrice, "DBS");

        (bool success,) = payable(msg.sender).call{ value: activeLot.bestOfferPrice }("");

        // Transfer reverted
        require(success, "TR");

        emit OfferReceived(
            msg.sender,
            activeLot.bestOfferInitiator,
            activeLot.bestOfferPrice
        );

        allActives[_activeId].owner = activeLot.bestOfferInitiator;

        activeLot.price = 0;
        activeLot.availableForPurchase = false;
        activeLot.bestOfferInitiator = address(0);
        activeLot.bestOfferPrice = 0;

        allLots[_activeId] = activeLot;
    }

    function buyActive(uint256 _activeId)
        external
        payable
        activeExists(_activeId)
        nonReentrant
    {
        Active memory active = allActives[_activeId];
        // Self buy
        require(active.owner != msg.sender, "SB");

        Lot memory lot = allLots[_activeId];
        // Purchase not enabled
        require(lot.availableForPurchase, "PNE");
        // Wrong price
        require(msg.value == lot.price, "WP");

        (bool success,) = payable(active.owner).call{ value: msg.value }("");

        // Transfer reverted
        require(success, "TR");


        emit ActiveSold(msg.sender, lot.price);

        lot.price = 0;
        lot.availableForPurchase = false;
        lot.bestOfferInitiator = address(0);
        lot.bestOfferPrice = 0;

        allActives[_activeId].owner = msg.sender;
        allLots[_activeId] = lot;

    }

    function makeOffer(uint256 _activeId)
        external
        payable
        activeExists(_activeId)
        nonReentrant
    {
        // Self buy
        require(allActives[_activeId].owner != msg.sender, "SB");
    
        Lot memory lot = allLots[_activeId];
        // Sold or Doesn't exist
        require(lot.availableForPurchase, "SODX");
        // More valueable price provided
        require(msg.value > lot.bestOfferPrice, "MVPP");
        
        if(lot.bestOfferInitiator != address(0)) {
            (bool success, ) = payable(lot.bestOfferInitiator).call{ value: lot.bestOfferPrice }("");

            // Transfer reverted
            require(success, "TR");
        }
        
        lot.bestOfferInitiator = msg.sender;
        lot.bestOfferPrice = msg.value;

        allLots[_activeId] = lot;

        emit OfferMade(msg.sender, msg.value);
    }

    function revokeOffer(uint256 _activeId)
        external
        activeExists(_activeId)
    {
        Lot memory lot = allLots[_activeId];

        // Lot not active
        require(lot.availableForPurchase, "LOA");
        // Wrong initiator
        require(lot.bestOfferInitiator == msg.sender, "WI");

        lot.bestOfferInitiator = address(0);
        lot.bestOfferPrice = 0;

        allLots[_activeId] = lot;
    }

    function getAllLotsByOwner(address _owner) external view returns(Lot[] memory) {
        Lot[] memory result;
        Active[] memory actives = allActives;

        uint i;
        uint lotsLength = 0;
        for(i = 0; i < actives.length; i++) {
            if(actives[i].owner == _owner && allLots[i].availableForPurchase) {
                lotsLength++;
            }
        }

        result = new Lot[](lotsLength);

        uint lastAllocatedLotIndex = 0;
        for(i = 0; i < actives.length; i++) {
            if(actives[i].owner == _owner && allLots[i].availableForPurchase) {
                Lot memory lot = allLots[i];
                result[lastAllocatedLotIndex] = lot;
                lastAllocatedLotIndex++;
            }
        }

        return result;
    }

    function getAllActivesByOwner(address _owner) external view returns(Active[] memory) {
        Active[] memory result;
        Active[] memory actives = allActives;

        uint i;
        uint activesLength = 0;
        for(i = 0; i < actives.length; i++) {
            if(actives[i].owner == _owner) {
                activesLength++;
            }
        }

        result = new Active[](activesLength);

        uint lastAllocatedActiveIndex = 0;
        for(i = 0; i < actives.length; i++) {
            if(actives[i].owner == _owner) {
                Active memory active = actives[i];
                result[lastAllocatedActiveIndex] = active;
                lastAllocatedActiveIndex++;
            }
        }

        return result;
    }
}