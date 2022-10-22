// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./SafeMath.sol";

contract TipContract {
    using SafeMath for uint256;

    // we need only 10 accounts
    uint256 public index_of_payers = 0;
    uint256 private totalTip;

    // calculted tip
    uint256 private tiptip;

    //events
    event TipEvent(uint256 tiptip, string message);

    // for manager and people addresses
    address payable private manager;
    address payable[] bill_payers;

    // to keep the track of already payed person
    mapping(address => bool) exists;

    // the person who will deploy this contract will be the manager
    constructor() {
        manager = payable(msg.sender);
    }

    //modifiers we need as restriction
    modifier notOwner() {
        require(msg.sender != manager, "Manager can't pay");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == manager, "Only Manager");
        _;
    }

    // calculating the tip each person have to give
    function calculate_tip(
        uint256 _bill_price,
        uint256 _tip_per,
        uint256 _no_of_people
    ) public onlyOwner returns (uint256) {
        //require((_bill_price * _tip_per) >= 10000);
        assert((_bill_price).mul(_tip_per) >= 1000);
        tiptip = (((_bill_price).mul(_tip_per)).div(10000)).div(_no_of_people);
        emit TipEvent(tiptip, "OUR CALCULATED TIP IN WEI");
        return tiptip;
    }

    // a function to check if the person already have payed the tip or not
    function AlreadyPayed() private view returns (bool) {
        if (exists[msg.sender] == true) {
            return true;
        } else {
            return false;
        }
    }

    // function for payers to pay tip
    function Pay_Tip() public payable notOwner {
        assert(AlreadyPayed() == false);
        assert(msg.value == tiptip);
        assert(index_of_payers <= 9);

        bill_payers.push(payable(msg.sender));
        exists[msg.sender] = true;
        index_of_payers++;
        totalTip += msg.value;
    }

    // this function will send all the money to the manager's acc
    function Transfer_to_Manager() public onlyOwner {
        manager.transfer(address(this).balance);
    }

    //getter functions
    function getTip() public view returns (uint256) {
        return tiptip;
    }

    function getTotalTip() public view returns (uint256) {
        return totalTip;
    }
}

//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        // assert(b > 0); // Solidity automatically throws when dividing by 0
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}