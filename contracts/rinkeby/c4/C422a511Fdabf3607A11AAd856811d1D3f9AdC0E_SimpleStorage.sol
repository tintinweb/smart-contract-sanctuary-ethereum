// SPDX-License-Identifier: MIT
pragma solidity 0.8.8;

contract SimpleStorage {
    uint256 number;

    mapping(string => uint256) public mapNameToYear;

    struct Cars {
        string name;
        uint256 year;
    }

    Cars[] public eachCar;

    function storeCars(string memory _eachCarName, uint256 _eachCarYear)
        public
    {
        eachCar.push(Cars(_eachCarName, _eachCarYear));
        mapNameToYear[_eachCarName] = _eachCarYear;
    }

    function store(uint256 _number) public virtual {
        number = _number;
    }

    function retrieve() public view returns (uint256) {
        return number;
    }
}