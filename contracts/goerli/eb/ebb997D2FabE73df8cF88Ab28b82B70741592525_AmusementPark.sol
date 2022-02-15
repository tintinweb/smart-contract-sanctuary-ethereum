/**
 *Submitted for verification at Etherscan.io on 2022-02-14
*/

//SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

//max 200 LoC
contract AmusementPark {

    /*
    The Amusement Park is designed to be navigated however the user wants, meaning there are several permutations available. 
    Each ride is designed to take the user onto another ride, 
    and the user wins the CTF challenge if they can complete each ride and leave the park with a Big Smile :) 
    If the user is able to leave the park without riding each of the rides, that would be an unforeseen vulnerability.
    */

    address payable attacker;
    address parkInstance;
    bool Carousel = false;
    bool BumperCars = false;
    bool Rollercoaster = false;
    bool HouseOfMirrors = false;

    bool public BigSmile = false; //This is the flag for this challenge. Set it to true to win.
    
    constructor() {
        parkInstance = address(this);
    }

    modifier insidePark() {
        require(msg.sender == parkInstance, "Only customers can ride these rides!");
        _;
    }

    modifier rodeAllRides() {
        require(Carousel && BumperCars && Rollercoaster && HouseOfMirrors, "Ride all the rides before leaving!");
        _;
    }

    function parkEntrance(bytes calldata ticket) public {
        attacker = payable(msg.sender);
        address(this).call(ticket);
    }

    function _Carousel(bytes calldata ticket) external insidePark {

        bytes memory nextRide;
        for(uint s = ticket.length; s > 0; s--) {
            nextRide = bytes.concat(nextRide, ticket[s-1]);
        }

        Carousel = true;
        address(this).call(nextRide);
        Carousel = false;
    }

    function _BumperCars(bytes calldata blueCar, uint40 redCar, bytes calldata yellowCar) external insidePark {
        bytes memory nextRide;

        require(keccak256(blueCar) == keccak256("blue"));
        require(redCar == uint40(bytes5(bytes.concat("255", "0", "0"))));
        bytes memory crash = abi.encodePacked(blueCar, redCar, yellowCar);

        ( , bytes memory _rainbowCar) = abi.decode(crash, (uint256, bytes));

        nextRide = abi.encodePacked(_rainbowCar);

        BumperCars = true;
        address(this).call(nextRide);
        BumperCars = false;
    }

    enum ride { UP, DOWN, LEFT, RIGHT, LOOPdeLOOP, EXIT }

    function _Rollercoaster(bytes[] memory ticket) external insidePark {
        ride[8] memory rideFeatures = [ride.UP, ride.LEFT, ride.UP, ride.DOWN, ride.LOOPdeLOOP, ride.RIGHT, ride.DOWN, ride.EXIT];

        uint256 cartChain = uint256(bytes32(ticket[0]));
        for (uint256 count = 0; count < 8; count++) {
            uint256 singleCart = cartChain & 7;
            require(uint256(rideFeatures[count]) == singleCart);
            cartChain >>= 3;
        }

        bytes memory nextRide = ticket[1];
        Rollercoaster = true;
        address(this).call(nextRide);
        Rollercoaster = false;
    }



    uint8 MIRR0R = 0;
    uint8 MlRROR = 0;
    uint8 MlRR0R = 0;
    function _HouseOfMirrors(bytes[] calldata houseLayout) external insidePark {
        
        if (uint256(bytes32(houseLayout[0])) >= 2 || (MIRR0R++ > 5 && MlRROR++ != 3 || ++MlRR0R < 4)) {
            attacker.call("");
        }
        else {
            uint256(bytes32(houseLayout[0])) < 1 ? MlRROR++ : MlRROR;
            require(++MIRR0R % MlRR0R++ != MlRROR++);
        }
        if (uint256(bytes32(houseLayout[1])) <= 2 || (uint256(bytes32(houseLayout[2])) == 0 ? MIRR0R++ == MlRROR++ : false || ++MlRR0R == uint256(bytes32(houseLayout[2])))) {
        }
        else{
            MIRR0R--;
            MlRROR--;
            MlRR0R--;
            attacker.call("");
        }

        require((MIRR0R == 9 && MlRROR == 5 && MlRR0R == 8) || BigSmile);
        
        bytes memory nextRide = houseLayout[3];
        HouseOfMirrors = true;
        address(this).call(nextRide);
        MIRR0R = 0;
        MlRROR = 0;
        MlRR0R = 0;
        HouseOfMirrors = false;
    }


    function _leavePark() external insidePark rodeAllRides {
        BigSmile = true;
    }

    fallback() external {
    }
}