/**
 *Submitted for verification at Etherscan.io on 2022-05-03
*/

// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

contract Model {

    struct Vehicle {
        int id;
        int rating;
        // int rsu;
    }

    struct RSU_response {
        int rsu;
        int traffic;
        int accident;
        int reliabilityScore;
    }

    struct Vehicle_response {
        int vehicle_id;
        int past_rating;
        int new_rating;
    }

    struct Input {
        int rsu;
        int[] _vehicle_ids;
        int[] _traffic;
        int[] _accident;
    }

    int public constant MULTIPLIER = 100;

    address private admin;
    int public vehicle_count;
    mapping(int => Vehicle) public vehicles;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Permission denied");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function register_vehicle() external returns (int) {
        vehicle_count += 1;
        vehicles[vehicle_count] = Vehicle(vehicle_count,500);
        return vehicle_count;
    }

    function get_all_vehicles() external view returns(Vehicle[] memory all_vehicle) {
        all_vehicle = new Vehicle[](uint(vehicle_count));
        for(uint i=1; int(i)<=vehicle_count; ++i) {
            Vehicle storage vehicle = vehicles[int(i)];
            all_vehicle[i-1] = vehicle;
        }
    }

    function consensus(
        int[] memory _vehicle_ids,
        int[] memory _input
    ) internal view returns(int output) {
        int total_rating = 0;
        int weighted_response = 0;

        for(uint i=0; i < _vehicle_ids.length; ++i) {
            Vehicle storage vehicle = vehicles[_vehicle_ids[i]];
            if (vehicle.rating <= 200) continue;
            
            weighted_response += vehicle.rating * _input[i];
            total_rating += vehicle.rating;
        }
        require(total_rating > 0, "No trusted vehicle present");

        int rem = weighted_response % total_rating;
        output = weighted_response / total_rating;
        if (2*rem > total_rating) output += 1;
    }

    function find_reliability(
        int[] memory _vehicle_ids
    ) public view returns(int reliabilityScore) {
        int count = 0;
        int sum = 0;

        for(uint i=0; i<_vehicle_ids.length; ++i) {
            Vehicle storage vehicle = vehicles[_vehicle_ids[i]];
            if (vehicle.rating <= 200) continue;
            sum += vehicle.rating;
            count += 1;
        }
        if (count == 0) return 0;
        reliabilityScore = (MULTIPLIER * sum) / (1000 * count);
    }

    function rating_change(
        int evaluated,
        int provided,
        int range
    ) internal pure returns(int delta) {
        require(range > 1, "There should be atleast two options to choose from");
        int slope = 120/(range-1);
        int dif = evaluated - provided;
        if (dif < 0) dif = -dif;
        delta = 20 - slope*dif;
    }

    function compute_state(
        int _rsuID, 
        int[] memory _vehicle_ids,
        int[] memory _traffic,
        int[] memory _accident
    ) public returns(RSU_response memory rsu_resp) {

        // Ensuring clean data is sent
        require(_vehicle_ids.length > 0, "No data found");
        require(_vehicle_ids.length == _traffic.length, "Missing data in the parameters");
        require(_vehicle_ids.length == _accident.length, "Missing data in the parameters");

        for(uint i=0; i<_vehicle_ids.length; ++i) {
            Vehicle storage vehicle = vehicles[_vehicle_ids[i]];
            require(vehicle.rating != 0, "Vehicle not found");
        }

        // Calculating State
        rsu_resp.rsu = _rsuID;
        rsu_resp.traffic = consensus(_vehicle_ids, _traffic);
        rsu_resp.accident = consensus(_vehicle_ids, _accident);
        rsu_resp.reliabilityScore = find_reliability(_vehicle_ids);

        // Updating ratings of vehicle
        for(uint i=0; i<_vehicle_ids.length; ++i) {
            Vehicle storage vehicle = vehicles[_vehicle_ids[i]];

            // Vehicles with rating <= 100 are blocked till they pay the penalty
            if (vehicle.rating <= 100) continue;

            int traffic_dr = rating_change(rsu_resp.traffic, _traffic[i], 5);
            int accident_dr = rating_change(rsu_resp.accident, _accident[i], 2);
            int delta_rating = (traffic_dr + accident_dr) * rsu_resp.reliabilityScore / (int256(_vehicle_ids.length) * MULTIPLIER);
            assert(-100 <= delta_rating && delta_rating <= 20);

            int updated_rating = vehicle.rating + delta_rating;

            if (updated_rating <= 0) {
                vehicle.rating = 1;
            } else if (updated_rating >= 1000) {
                vehicle.rating = 1000;
            } else {
                vehicle.rating = updated_rating;
            }
        }
    }

    function simulate(
        Input[] calldata input
    ) external returns(
        RSU_response[] memory rsu_resp,
        Vehicle_response[] memory vehicle_resp) {

            uint tot_vehicles = 0;
            uint tot_rsu = 0;

            // Calculating # of vehicles & RSUs
            for(uint i=0; i<input.length;++i) {
                tot_vehicles += input[i]._vehicle_ids.length;
                if (input[i].rsu !=0) tot_rsu += 1;
            }

            rsu_resp = new RSU_response[](tot_rsu);
            vehicle_resp = new Vehicle_response[](tot_vehicles);

            // Initialising vehicle_resp
            uint id = 0;
            for(uint i=0; i<input.length;++i) {
                for(uint j=0; j<input[i]._vehicle_ids.length; ++j) {
                    Vehicle storage vehicle = vehicles[input[i]._vehicle_ids[j]];
                    vehicle_resp[id] = Vehicle_response(
                        input[i]._vehicle_ids[j],
                        vehicle.rating,
                        vehicle.rating
                    );
                    id += 1;
                }
            }

            // Solving for each RSU
            for(uint i=0; i<input.length; ++i) {
                rsu_resp[i] = compute_state(
                    input[i].rsu,
                    input[i]._vehicle_ids,
                    input[i]._traffic,
                    input[i]._accident
                );
            }
            
            // Updating new rating of vehicle_resp
            for(uint i=0; i<vehicle_resp.length; ++i) {
                Vehicle storage vehicle = vehicles[vehicle_resp[i].vehicle_id];
                vehicle_resp[i].new_rating = vehicle.rating;
            }
        }

    function overwrite_rating(int vehicle_id, int rating) external onlyAdmin {
        Vehicle storage vehicle = vehicles[vehicle_id];
        require(vehicle.rating != 0, "Vehicle not found");
        require(rating <= 1000, "Cannot assign rating more than 1000");
        vehicle.rating = rating;
    }

    function give_penalty(int vehicle_id) external payable {
        Vehicle storage vehicle = vehicles[vehicle_id];
        require(vehicle.rating != 0, "Vehicle not found");
        require(vehicle.rating <= 100, "Penalty not required");
        // require(msg.value != 0, "No fees sent");
        vehicle.rating = 150;
    }
}