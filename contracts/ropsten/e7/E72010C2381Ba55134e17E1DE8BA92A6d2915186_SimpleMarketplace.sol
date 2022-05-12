// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.7.3;

contract SimpleMarketplace {
    enum StateType {
        ItemAvailable,
        OfferPlaced,
        Accepted
    }

    address public InstanceOwner;
    string public Description;
    int public AskingPrice;
    StateType public State;

    address public InstanceBuyer;
    int public OfferPrice;

    constructor(string memory description, int price) public {
        InstanceOwner = msg.sender;
        AskingPrice = price;
        Description = description;
        State = StateType.ItemAvailable;
    }

    function MakeOffer(int offerPrice) public {
        if (offerPrice == 0 || State != StateType.ItemAvailable || InstanceOwner == msg.sender) {
            revert();
        }

        InstanceBuyer = msg.sender;
        OfferPrice = offerPrice;
        State = StateType.OfferPlaced;
    }

    function Reject() public {
        if ( State != StateType.OfferPlaced || InstanceOwner != msg.sender) {
            revert();
        }

        InstanceBuyer = 0x0000000000000000000000000000000000000000;
        State = StateType.ItemAvailable;
    }

    function AcceptOffer() public {
        if ( msg.sender != InstanceOwner ) {
            revert();
        }

        State = StateType.Accepted;
    }
}