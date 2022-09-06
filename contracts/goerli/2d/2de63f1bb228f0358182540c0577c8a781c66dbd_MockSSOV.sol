//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.16;

interface ISSOV {
    function epochStrikeTokens(uint256 _epoch, uint256 strike)
        external
        view
        returns (address);

    function getEpochStrikes(uint256 _epoch)
        external
        view
        returns (uint256[] memory);

    function getAddress(bytes32 name) external view returns (address);

    function currentEpoch() external view returns (uint256);

    function isVaultReady(uint256) external view returns (bool);

    function epochStrikes(uint256 _epoch, uint256 strikeIndex)
        external
        view
        returns (uint256);

    function settle(
        uint256 strikeIndex,
        uint256 amount,
        uint256 _epoch
    ) external returns (uint256);

    function getEpochTimes(uint256 _epoch)
        external
        view
        returns (uint256 start, uint256 end);

    function calculatePremium(
        uint256 _strike,
        uint256 _amount,
        uint256 _expiry
    ) external view returns (uint256 premium);

    function getCollateralPrice() external view returns (uint256);
}

contract MockSSOV {
    struct EpochTime {
        uint256 start;
        uint256 end;
    }

    address public token;

    mapping(uint256 => mapping(uint256 => address)) public epochStrikeTokens;

    mapping(uint256 => EpochTime) public epochTimes;
    mapping(uint256 => uint256[]) public epochStrikes;

    uint256 public epoch = 1;
    uint256 public premium = 200000000000000000; // 0.2 token
    uint256 public price = 3500000000; // $35

    constructor(address _token) {
        token = _token;
    }

    function currentEpoch() public view returns (uint256) {
        return epoch;
    }

    function setCurrentEpoch(uint256 _epoch) public {
        epoch = _epoch;
    }

    function setPrice(uint256 _price) public {
        price = _price;
    }

    function getCollateralPrice() public view returns (uint256) {
        return price;
    }

    function setEpochStrikeTokens(
        uint256 _epoch,
        uint256 strike,
        address _token
    ) public returns (bool) {
        epochStrikeTokens[_epoch][strike] = _token;
        epochStrikes[_epoch].push(strike);
        return true;
    }

    function setEpochTimes(
        uint256 _epoch,
        uint256 start,
        uint256 end
    ) public returns (bool) {
        epochTimes[_epoch] = EpochTime(start, end);
        return true;
    }

    function getEpochTimes(uint256 _epoch)
        public
        view
        returns (uint256, uint256)
    {
        return (epochTimes[_epoch].start, epochTimes[_epoch].end);
    }

    function setPremium(uint256 _premium) external {
        premium = _premium;
    }

    function calculatePremium(
        uint256,
        uint256 amount,
        uint256
    ) public view returns (uint256) {
        return (premium * amount) / 1 ether;
    }

    function getAddress(bytes32 name) public view returns (address) {
        if (name == bytes32("DPX")) return token;
        else return address(0);
    }

    function getEpochStrikes(uint256 _epoch)
        external
        view
        returns (uint256[] memory)
    {
        return epochStrikes[_epoch];
    }
}