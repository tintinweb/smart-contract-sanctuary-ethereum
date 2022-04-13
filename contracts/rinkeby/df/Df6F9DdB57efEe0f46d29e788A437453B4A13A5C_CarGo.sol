/**
 *Submitted for verification at Etherscan.io on 2022-04-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

contract CarGo {
    uint256 DEPOSIT = 0.0001 ether;
    uint256 PENALTY = 0.00001 ether;
    address SERVICE_PROVIDER = 0x528437b2A0777594E356E69559Ee70630EEb472B;

    // car attributes (carID (uint256)represents the car)
    mapping(uint256 => uint256) carBalance;
    mapping(uint256 => uint256) startTime;
    mapping(uint256 => uint256) endTime;
    mapping(uint256 => uint256) carPrice;
    mapping(uint256 => uint256) extraTime;
    mapping(uint256 => uint256) extraTimeCharge;
    mapping(uint256 => address) carOwner;
    mapping(uint256 => address) carRenter; // this links the renter with the car
    mapping(uint256 => address) carAdress;
    mapping(uint256 => bool) carOccupied;
    mapping(uint256 => string) accessToken;
    mapping(uint256 => bool) carRegistered;

    // retner attributes
    mapping(address => uint256) renterBalance;
    mapping(address => bool) renterRegistered;
    mapping(address => bool) renterOccupied;

    event RegisterCar(uint256 _carID, uint256 _price, uint256 _extraPrice);
    event RegisterRenter(address _address);
    event InitBooking(address _address);
    event EndBooking(address _address, uint256 _endTime);

    modifier checkDeposit() {
        require(msg.value >= DEPOSIT, "Not enough Ether provided as deposit");
        _;
    }

    function isSignatureValid(
        address _address,
        bytes32 _hash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) private pure returns (bool) {
        address _signer = ecrecover(_hash, _v, _r, _s);
        return (_signer == _address);
    }

    function registerCar(
        address _carAdress,
        uint256 _carID,
        uint256 _price,
        uint256 _extraPrice,
        bytes32 _hash,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) external payable checkDeposit {
        // require(
        //     SERVICE_PROVIDER == ecrecover(_hash, _v, _r, _s),
        //     "NOT SIGNED BY SERVICE PROVIDER"
        // );
        require(
            isSignatureValid(SERVICE_PROVIDER, _hash, _v, _r, _s),
            "NOT SIGNED BY SERVICE PROVIDER"
        );
        require(carRegistered[_carID] == false, "CAR IS ALREADY REGISTERED");
        carBalance[_carID] = msg.value;
        carOwner[_carID] = msg.sender;
        carPrice[_carID] = _price;
        carRegistered[_carID] = true;
        extraTimeCharge[_carID] = _extraPrice;
        carOccupied[_carID] = false;
        carAdress[_carID] = _carAdress;
        emit RegisterCar(_carID, _price, _extraPrice);
    }

    // Register retner on-chain
    function registerRenter(
        bytes32 _hash,
        bytes32 _r,
        bytes32 _s,
        uint8 _v
    ) external payable checkDeposit {
        // require(
        //     SERVICE_PROVIDER == ecrecover(_hash, _v, _r, _s),
        //     "NOT SIGNED BY SERVICE PROVIDER"
        // );
        require(
            isSignatureValid(SERVICE_PROVIDER, _hash, _v, _r, _s),
            "NOT SIGNED BY SERVICE PROVIDER"
        );
        require(
            renterRegistered[msg.sender] == false,
            "RENTER IS ALREADY REGISTERED"
        );
        renterBalance[msg.sender] = msg.value;
        renterRegistered[msg.sender] = true;
        emit RegisterRenter(msg.sender);
    }

    function setAccessToken(
        uint256 _carID,
        string memory _encryptedBD,
        address _renter
    ) public {
        require(carOccupied[_carID] == false, "CAR IS USED");
        require(msg.sender == carOwner[_carID], "YOU ARE NOT THE OWNER");
        accessToken[_carID] = _encryptedBD;
        carRenter[_carID] = _renter;
    }

    function getAccessToken(uint256 _carID)
        public
        view
        returns (string memory)
    {
        return accessToken[_carID];
    }

    // Check that car is not in use, car signed the beginTime and that the correct driver
    function beginBooking(
        bytes32 _hash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s,
        uint256 _carID,
        uint256 _beginTime
    ) public {
        require(msg.sender == carRenter[_carID], "YOU ARE NOT THE RENTER");
        require(
            isSignatureValid(carAdress[_carID], _hash, _v, _r, _s),
            "TIME WAS NOT SIGNED BY THE CAR"
        );
        startTime[_carID] = _beginTime;
        carOccupied[_carID] = true;
        renterOccupied[msg.sender] = true;
    }

    function setExtraTime(uint256 _carID, uint256 _extraTime) public {
        require(msg.sender == carOwner[_carID], "YOU ARE NOT THE OWNER");
        extraTime[_carID] = _extraTime;
    }

    function endBooking(
        uint256 _carID,
        uint256 _endTime,
        bytes32 _hash,
        uint8 _v,
        bytes32 _r,
        bytes32 _s
    ) public {
        require(
            msg.sender == carRenter[_carID],
            "YOU ARE NOT THE CURRENT RENTER"
        );
        require(
            isSignatureValid(carAdress[_carID], _hash, _v, _r, _s),
            "TIME WAS NOT SIGNED BY THE CAR"
        );

        uint256 fee = carPrice[_carID] * (startTime[_carID] - _endTime);

        if (extraTime[_carID] > 0) {
            fee += extraTime[_carID] * extraTimeCharge[_carID];
        }

        carBalance[_carID] += fee;
        carOccupied[_carID] = false;
        renterBalance[msg.sender] -= fee;
        renterOccupied[msg.sender] = false;
        emit EndBooking(msg.sender, _endTime);
    }

    function cancelBooking(uint256 _carID) public {
        if (msg.sender == carOwner[_carID]) {
            require(
                startTime[_carID] <= 0,
                "Ride has started, you can't cancel it"
            );
            carRenter[_carID] = address(0);
            accessToken[_carID] = "";
        } else if (msg.sender == carRenter[_carID]) {
            if (startTime[_carID] > 0) {
                renterBalance[msg.sender] -= PENALTY;
                uint256 fee = renterBalance[msg.sender] - PENALTY;
                carBalance[_carID] += fee;
                carOccupied[_carID] = false;
                renterOccupied[msg.sender] = false;
            } else {
                carRenter[_carID] = address(0);
                accessToken[_carID] = "";
            }
        }
    }

    function withdrawMoneyToOwner(uint256 _carID) public {
        require(msg.sender == carOwner[_carID], "YOU ARE NOT THE OWNER");
        require(carOccupied[_carID] == false);

        uint256 _amount = carBalance[_carID];
        carBalance[_carID] = 0;
        address _to = carOwner[_carID];

        payable(_to).transfer(_amount);
    }

    function withdrawMoneyToRenter() public {
        require(
            renterOccupied[msg.sender] == false,
            "CANT WITHDRAW WHEN RENTER IS STILL DRIVING"
        );
        uint256 _amount = renterBalance[msg.sender];
        renterBalance[msg.sender] = 0;
        payable(msg.sender).transfer(_amount);
    }

    // This function is used when the owner has withdrawed all the money but wants to rent the car again, so needs to deposit again money
    // function sendDeposit(uint256 _carID)
    //     public
    //     payable
    //     checkDeposit
    // {
    //     if (msg.sender == carOwner[_carID]) {
    //         carBalance[_carID] = msg.value;
    //     }
    //     renterBalance[msg.sender] = msg.value;
    //     renterRegistered[msg.sender] = true;
    //     emit RegisterRenter(msg.sender);
    // }
}