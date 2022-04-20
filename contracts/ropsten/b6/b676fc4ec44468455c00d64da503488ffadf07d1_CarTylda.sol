/**
 *Submitted for verification at Etherscan.io on 2022-04-20
*/

// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

/** 
 * @title Ballot
 * @dev Implements voting process along with vote delegation
 */
contract CarTylda {

    struct CarParamM1 {
        bytes32 object_id;
        bytes32 record_number;
        bytes32 record_driv_card1;
        bytes32 record_driv_card2;
        bytes32 record_gps_timestamp;
        bytes32 record_latitude;
        bytes32 record_longitude;
        bytes32 record_altitude;
        bytes32 record_gps_speed;
        bytes32 record_gps_distance;
        bytes32 record_inputs;
        bytes32 record_outputs;
        bytes32 record_first_fuel;
        bytes32 record_second_fuel;
        bytes32 record_third_fuel;
        bytes32 record_fourth_fuel;
    }

    struct CarParamM2 {
        bytes32 record_timestamp;
        bytes32 record_direction;
        bytes32 record_input_first_counter;
        bytes32 record_input_second_counter;
        bytes32 record_input_third_counter;
        bytes32 record_rpm;
        bytes32 record_type;
        bytes32 record_accel;
        bytes32 record_ar;
        bytes32 record_as1;
        bytes32 record_as2;
    }

    struct CarParamM3 {
        bytes32 record_dynstate;
        bytes32 record_oagps;
        bytes32 record_operator;
        bytes32 record_osg;
        bytes32 record_reset;
        bytes32 record_sat_2d3d;
        bytes32 record_sat_used;
        bytes32 record_signal_level;
        bytes32 record_sim;
        bytes32 record_sr;
        bytes32 record_ssp;
        bytes32 record_stsp1;
        bytes32 record_stsp2;
        bytes32 record_szil1;
        bytes32 record_szil2;
    }

    struct CarParamM4 {
        bytes32 record_idtype;
        bytes32 record_voltage;
        bytes32 record_zagps;
        bytes32 record_zw;
        bytes32 record_can_axis_pressure;
        bytes32 record_can_distance;
        bytes32 record_can_driver_state;
        bytes32 record_can_driver2_state;
        bytes32 record_can_driver_alarm;
        bytes32 record_can_driver2_alarm;
        bytes32 record_can_fuel;
        bytes32 record_can_fuel_usage;
        bytes32 record_can_gear;
    }

    struct CarParamM5 {
        bytes32 record_can_rpm;
        bytes32 record_can_totalfuelused;
        bytes32 record_can_service_distance;
        bytes32 record_events;
        bytes32 record_accessories;
        bytes32 record_caralarm;
        bytes32 record_dashboard;
        bytes32 record_obd;
        bytes32 record_x;
        bytes32 record_y;
        bytes32 record_ecodriving;
        bytes32 record_eco_acc;
        bytes32 record_eco_dec;
        bytes32 record_eco_speed;
        bytes32 record_eco_rpm;
    }

    struct CarParamM6 {
        bytes32 record_einputs;
        bytes32 record_eoutputs;
        bytes32 record_eanalog;
        bytes32 record_counter_1;
        bytes32 record_counter_2;
        bytes32 record_tpms;
        bytes32 record_gx;
        bytes32 record_gy;
        bytes32 record_gz;
        bytes32 record_dallas_first_id;
        bytes32 record_dallas_second_id;
        bytes32 record_dallas_third_id;
    }

    struct CarParamT1 {
        bytes32 record_temperature_T1;
        bytes32 record_temperature_T2;
        bytes32 record_temperature_T3;
        bytes32 record_temperature_T4;
        bytes32 record_temperature_T5;
        bytes32 record_temperature_T6;
        bytes32 record_temperature_TP1;
        bytes32 record_temperature_TP2;
    }

    struct CarParamT2 {
        bytes32 record_ble1_temperature;
        bytes32 record_ble1_battery;
        bytes32 record_ble1_humidity;
        bytes32 record_ble2_temperature;
        bytes32 record_ble2_battery;
        bytes32 record_ble2_humidity;
        bytes32 record_ble3_temperature;
        bytes32 record_ble3_battery;
        bytes32 record_ble3_humidity;
        bytes32 record_ble4_temperature;
        bytes32 record_ble4_battery;
        bytes32 record_ble4_humidity;
    }

    struct CarParamC1 {
        bytes32 record_driver_card1_number;
        bytes32 record_driver_card1_type;
        bytes32 record_driver_card1_country;
        bytes32 record_driver_card2_number;
        bytes32 record_driver_card2_type;
        bytes32 record_driver_card2_country;    
    }
   
    struct CarParam {
        CarParamM1 m1;
        CarParamM2 m2;
        CarParamM3 m3;
        CarParamM4 m4;
        CarParamM5 m5;
        CarParamM6 m6;
        CarParamT1 t1;
        CarParamT2 t2;
        CarParamC1 c1;
    }
    
    CarParam[] carParams;
    address public ownerperson;

    /** 
     * Construct
     */
    constructor() {
        ownerperson = msg.sender;        
    }
    
    /** 
     * Track new params for cat     
     */
    function trackParams(
        bytes32 object_id,
        bytes32 record_number,
        bytes32 record_driv_card1,
        bytes32 record_driv_card2,
        bytes32 record_gps_timestamp,
        bytes32 record_latitude,
        bytes32 record_longitude      
    ) public {
        require(
            msg.sender == ownerperson,
            "Only owner can give right to function."
        );
       
        CarParam memory carParam = CarParam({
            m1: CarParamM1({
                object_id: object_id,
                record_number: record_number,
                record_driv_card1: record_driv_card1,
                record_driv_card2: record_driv_card2,
                record_gps_timestamp: record_gps_timestamp,
                record_latitude: record_latitude,
                record_longitude: record_longitude,

                record_altitude: "",
                record_gps_speed: "",
                record_gps_distance: "",
                record_inputs: "",
                record_outputs: "",
                record_first_fuel: "",
                record_second_fuel: "",
                record_third_fuel: "",
                record_fourth_fuel: ""
            }),
            m2: CarParamM2({
                record_timestamp: "",
                record_direction: "",
                record_input_first_counter: "",
                record_input_second_counter: "",
                record_input_third_counter: "",
                record_rpm: "",
                record_type: "",
                record_accel: "",
                record_ar: "",
                record_as1: "",
                record_as2: ""
            }),
            m3: CarParamM3({
                record_dynstate: "",
                record_oagps: "",
                record_operator: "",
                record_osg: "",
                record_reset: "",
                record_sat_2d3d: "",
                record_sat_used: "",
                record_signal_level: "",
                record_sim: "",
                record_sr: "",
                record_ssp: "",
                record_stsp1: "",
                record_stsp2: "",
                record_szil1: "",
                record_szil2: ""
            }),
            m4: CarParamM4({
                record_idtype: "",
                record_voltage: "",
                record_zagps: "",
                record_zw: "",
                record_can_axis_pressure: "",
                record_can_distance: "",
                record_can_driver_state: "",
                record_can_driver2_state: "",
                record_can_driver_alarm: "",
                record_can_driver2_alarm: "",
                record_can_fuel: "",
                record_can_fuel_usage: "",
                record_can_gear: ""
            }),
            m5: CarParamM5({
                record_can_rpm: "",
                record_can_totalfuelused: "",
                record_can_service_distance: "",
                record_events: "",
                record_accessories: "",
                record_caralarm: "",
                record_dashboard: "",
                record_obd: "",
                record_x: "",
                record_y: "",
                record_ecodriving: "",
                record_eco_acc: "",
                record_eco_dec: "",
                record_eco_speed: "",
                record_eco_rpm: ""
            }),
            m6: CarParamM6({
                record_einputs: "",
                record_eoutputs: "",
                record_eanalog: "",
                record_counter_1: "",
                record_counter_2: "",
                record_tpms: "",
                record_gx: "",
                record_gy: "",
                record_gz: "",
                record_dallas_first_id: "",
                record_dallas_second_id: "",
                record_dallas_third_id: ""
            }),
            t1: CarParamT1({
                record_temperature_T1: "",
                record_temperature_T2: "",
                record_temperature_T3: "",
                record_temperature_T4: "",
                record_temperature_T5: "",
                record_temperature_T6: "",
                record_temperature_TP1: "",
                record_temperature_TP2: ""
            }),
            t2: CarParamT2({
                record_ble1_temperature: "",
                record_ble1_battery: "",
                record_ble1_humidity: "",
                record_ble2_temperature: "",
                record_ble2_battery: "",
                record_ble2_humidity: "",
                record_ble3_temperature: "",
                record_ble3_battery: "",
                record_ble3_humidity: "",
                record_ble4_temperature: "",
                record_ble4_battery: "",
                record_ble4_humidity: ""
            }),
            c1: CarParamC1({
                record_driver_card1_number: "",
                record_driver_card1_type: "",
                record_driver_card1_country: "",
                record_driver_card2_number: "",
                record_driver_card2_type: "",
                record_driver_card2_country: ""
            })
        });

        carParams.push(carParam);
    }
}