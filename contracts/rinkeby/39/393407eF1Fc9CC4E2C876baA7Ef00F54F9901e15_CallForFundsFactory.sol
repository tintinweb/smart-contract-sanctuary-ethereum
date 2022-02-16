// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {CallForFundsProxy} from "./CallForFundsProxy.sol";

contract CallForFundsFactory {
    address public immutable logicAddress;

    event CallForFundsCreated(
        address indexed CallForFunds,
        address indexed creator,
        string title,
        string description,
        string indexed image,
        string category,
        string genre,
        string subgenre,
        uint8 timelineInDays,
        uint256 minFundingAmount,
        string deliverableMedium
    );

    constructor(address logicAddress_) {
        logicAddress = logicAddress_;
    }

    function createCallForFunds(
        string memory title_,
        string memory description_,
        string memory image_,
        string memory category_,
        string memory genre_,
        string memory subgenre_,
        uint8 timelineInDays_,
        uint256 minFundingAmount_,
        string memory deliverableMedium_
    ) external returns (address proxy) {
        proxy = address(
            new CallForFundsProxy{
                salt: keccak256(abi.encode(msg.sender, title_))
            }(
                msg.sender,
                title_,
                description_,
                image_,
                category_,
                genre_,
                subgenre_,
                deliverableMedium_,
                timelineInDays_,
                minFundingAmount_
            )
        );

        emit CallForFundsCreated(
            proxy,
            msg.sender,
            title_,
            description_,
            image_,
            category_,
            genre_,
            subgenre_,
            timelineInDays_,
            minFundingAmount_,
            deliverableMedium_
        );
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import {CallForFundsStorage} from "./CallForFundsStorage.sol";

interface ICallForFundsFactory {
    function logicAddress() external returns (address);
}

contract CallForFundsProxy is CallForFundsStorage {
    constructor(
        address creator_,
        string memory title_,
        string memory description_,
        string memory image_,
        string memory category_,
        string memory genre_,
        string memory subgenre_,
        string memory deliverableMedium_,
        uint8 timelineInDays_,
        uint256 minFundingAmount_
    ) {
        logicAddress = ICallForFundsFactory(msg.sender).logicAddress();

        creator = creator_;
        title = title_;
        description = description_;
        image = image_;
        category = category_;
        genre = genre_;
        subgenre = subgenre_;
        deliverableMedium = deliverableMedium_;
        timelineInDays = timelineInDays_;
        minFundingAmount = minFundingAmount_;

        fundingState = FundingState.OPEN;
    }

    fallback() external payable {
        address _impl = logicAddress;
        assembly {
            let ptr := mload(0x40)
            calldatacopy(ptr, 0, calldatasize())
            let result := delegatecall(gas(), _impl, ptr, calldatasize(), 0, 0)
            let size := returndatasize()
            returndatacopy(ptr, 0, size)

            switch result
            case 0 {
                revert(ptr, size)
            }
            default {
                return(ptr, size)
            }
        }
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

contract CallForFundsStorage {
    enum FundingState {
        OPEN,
        FAILED,
        MATCHED,
        STREAMING,
        DELIVERED
    }

    // change later to multisig?
    address public constant loudverseAdmin =
        0xA4E987fb3808d9FC206112967477793Ea8389450;

    address internal logicAddress;

    address public creator;
    string public title;
    string public description;
    string public image;
    string public category;
    string public genre;
    string public subgenre;
    string public deliverableMedium;
    uint8 public timelineInDays;
    uint256 public minFundingAmount;

    string public deliverableURI;

    FundingState public fundingState;
}