// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity >=0.6.0 <0.9.0;

contract Sensor {
    struct Sensor_data {
        uint256 temp;
        uint256 airq;
        uint256 brightness;
        uint256 timestamp;
    }

    mapping(string => Sensor_data[]) sensors_info;

    function store(
        string memory _sensor_id,
        uint256 _temp,
        uint256 _airq,
        uint256 _brightness,
        uint256 _timestamp
    ) public {
        Sensor_data memory sensor_data = Sensor_data(
            _temp,
            _airq,
            _brightness,
            _timestamp
        );
        sensors_info[_sensor_id].push(sensor_data);
    }

    function get_latest_info(string memory _sensor_id)
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        uint256 len = sensors_info[_sensor_id].length;
        require(len != 0, "no such sensor id");
        return (
            sensors_info[_sensor_id][len - 1].temp,
            sensors_info[_sensor_id][len - 1].airq,
            sensors_info[_sensor_id][len - 1].brightness,
            sensors_info[_sensor_id][len - 1].timestamp
        );
    }
}