// SPDX-License-Identifier: UNLICENSED
pragma solidity >0.8.9;

contract Farm {
    uint256 public immutable factor;
    uint256 public immutable basePrice;
    uint256 public immutable creatorCommission;
    uint256 public immutable ownerCommission;
    uint256 public immutable creationTimestamp;
    address payable public immutable nftOwner;
    uint256 public immutable partsQuantity;
    Part[] public parts;

    struct Part {
        uint256 id;
        FarmPart farmPart;
    }

    constructor(
        uint256 _factor,
        uint256 _basePrice,
        uint256 _creatorCommission,
        uint256 _ownerCommission,
        address payable _nftOwner,
        uint256 _partsQuantity
    ) {
        require(_partsQuantity > 0);

        factor = _factor;
        basePrice = _basePrice;
        creatorCommission = _creatorCommission;
        ownerCommission = _ownerCommission;
        creationTimestamp = block.timestamp;
        nftOwner = _nftOwner;
        partsQuantity = _partsQuantity;
        createParts();
    }

    function createParts() private {
        for (uint256 i = 0; i < partsQuantity; i++) {
            parts.push(Part({id: i, farmPart: new FarmPart(i)}));
        }
    }
}

contract FarmPart {
    uint256 public immutable id;
    address public immutable ownerContract;

    constructor(uint256 _id) {
        id = _id;
        ownerContract = msg.sender;
    }
}