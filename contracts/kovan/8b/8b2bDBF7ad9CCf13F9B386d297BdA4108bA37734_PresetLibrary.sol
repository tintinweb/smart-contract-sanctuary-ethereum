pragma solidity >=0.5.0 <0.6.0;

library PresetLibrary {

    uint8 public constant nothing = 0;
    uint8 public constant planet = 1;
    uint8 public constant moon = 2;
    uint8 public constant station = 3;

    uint8 public constant objectType = 0;
    uint8 public constant size = 1;
    uint8 public constant class = 2;
    uint8 public constant rings = 3;
    uint8 public constant slot = 3;
    uint8 public constant speed = 4;

    /* check type */

    function isNothing(uint8 id) external pure returns (
        bool
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[objectType] == nothing;
    }

    function isPlanet(uint8 id) external pure returns (
        bool
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[objectType] == planet;
    }

    function isMoon(uint8 id) external pure returns (
        bool
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[objectType] == moon;
    }

    function isStation(uint8 id) external pure returns (
        bool
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[objectType] == station;
    }

    /* get values */

    function getName(uint8 id) external pure returns (
        string memory
    ) {
        (string memory name, ) = getSolarSystem(id);
        return name;
    }

    function getSize(uint8 id) external pure returns (
        uint8
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[size];
    }

    function getClass(uint8 id) external pure returns (
        uint8
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[class];
    }

    function getRings(uint8 id) external pure returns (
        uint8
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[rings];
    }

    function getSlot(uint8 id) external pure returns (
        uint8
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[slot];
    }

    function getSpeed(uint8 id) external pure returns (
        uint8
    ) {
        ( , uint8[5] memory template) = getSolarSystem(id);
        return template[speed];
    }

    /* get whole object */
    //TODO: make this a datastructure and reduce contract size
    function getSolarSystem(
        uint8 index
    ) internal pure returns(
        string memory, // name
        uint8[5] memory
    ) {
        if (index == 0) {
            return (
                'Mercury', [
                    planet,
                    3,   //size
                    1,   //class K, Desert Wasteland
                    0,   //rings
                    250  //orbital speed
                ]
            );
        }

        if (index == 1) {
             return (
                'Icarus', [
                    station,
                    1,   //size
                    0,   //class
                    0,   //
                    15   //oribtal speed
                ]
            );
        }

        if (index == 2) {
            return (
                'Venus', [
                    planet,
                    12,  //size
                    5,   //class H, Volcanic
                    0,   //rings
                    83   //orbital speed
                ]
            );
        }

        if (index == 3) {
            return (
                'Port Hesperus', [
                    station,
                    1,   //size
                    0,   //class
                    1,   //slot
                    15   //orbital speed
                ]
            );
        }

        if (index == 4) {
            return (
                'Earth', [
                    planet,
                    12,  //size
                    0,   //class M, Earthline
                    0,   //rings
                    50   //orbital speed
                ]
            );
        }

        if (index == 5) {
            return (
                'I.S.S.', [
                    station,
                    6,   //size
                    0,   //class
                    0,   //
                    10   //orbital speed
                ]
            );
        }

        if (index == 6) {
            return (
                'Luna', [
                    moon,
                    10,   //size
                    1,   //class K, Desert Wasteland
                    1,   //slot
                    100   //orbital speed
                ]
            );
        }

        if (index == 7) {
            return (
                'Mars', [
                    planet,
                    6,   //size
                    1,   //class K, Desert Wasteland
                    0,   //rings
                    26   //orbital speed
                ]
            );
        }

        if (index == 8) {
            return (
                'Tiangong', [
                    station,
                    4,   //size
                    4,   //class K, Desert Wasteland
                    0,   //
                    15   //orbital speed
                ]
            );
        }

        if (index == 9) {
            return (
                'Phobos', [
                    moon,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    0,   //slot
                    185  //orbital speed
                ]
            );
        }

        if (index == 10) {
            return (
                'Deimos', [
                    moon,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    3,   //slot
                    42   //orbital speed
                ]
            );
        }

        if (index == 11) {
            return (
                'Jupiter', [
                    planet,
                    54,  //size
                    6,   //class U, Gas / Vapor
                    0,   //rings
                    5    //orbital speed
                ]
            );
        }

        if (index == 12) {
            return (
                'Tycho Station', [
                    station,
                    12,  //size
                    0,   //class
                    0,   //
                    7    //orbital speed
                ]
            );
        }

        if (index == 13) {
            return (
                'Io', [
                    moon,
                    10,   //size
                    1,   //class K, Desert Wasteland
                    1,   //slot
                    41   //orbital speed
                ]
            );
        }

        if (index == 14) {
            return (
                'Europa', [
                    moon,
                    8,   //size
                    1,   //class K, Desert Wasteland
                    2,   //slots
                    42   //orbital speed
                ]
            );
        }

        if (index == 15) {
            return (
                'Ganymede', [
                    moon,
                    14,   //size
                    1,    //class K, Desert Wasteland
                    3,    //slot
                    56    //orbital speed
                ]
            );
        }

        if (index == 16) {
            return (
                'Callisto', [
                    moon,
                    14,   //size
                    1,    //class K, Desert Wasteland
                    4,    //slot
                    26    //orbital speed
                ]
            );
        }

        if (index == 17) {
            return (
                'Saturn', [
                    planet,
                    36,  //size
                    6,   //class U, Gas / Vapor
                    10,  //rings
                    4    //orbital speed
                ]
            );
        }

        if (index == 18) {
            return (
                'Ticonderoga', [
                    station,
                    10,  //size
                    1,   //class
                    0,   //
                    15   //orbital speed
                ]
            );
        }

        if (index == 19) {
            return (
                'Enceladus', [
                    moon,
                    3,   //size
                    1,   //class K, Desert Wasteland
                    0,   //slot
                    111  //orbital speed
                ]
            );
        }

        if (index == 20) {
            return (
                'Tethys', [
                    moon,
                    3,   //size
                    1,   //class K, Desert Wasteland
                    1,   //slot
                    46   //orbital speed
                ]
            );
        }

        if (index == 21) {
            return (
                'Dione', [
                    moon,
                    3,   //size
                    1,   //class K, Desert Wasteland
                    2,   //slot
                    21   //orbital speed
                ]
            );
        }

        if (index == 22) {
            return (
                'Rhea', [
                    moon,
                    5,   //size
                    1,   //class K, Desert Wasteland
                    3,   //slot
                    71   //orbital speed
                ]
            );
        }

        if (index == 23) {
            return (
                'Titan', [
                    moon,
                    14,   //size
                    1,   //class K, Desert Wasteland
                    4,   //slot
                    67   //orbital speed
                ]
            );
        }

        if (index == 24) {
            return (
                'Iapetus', [
                    moon,
                    5,   //size
                    1,   //class K, Desert Wasteland
                    5,   //slot
                    31   //orbital speed
                ]
            );
        }

        if (index == 25) {
            return (
                'Uranus', [
                    planet,
                    24,  //size
                    4,   //class C, Glacial / Ice
                    1,   //rings
                    3    //orbital speed
                ]
            );
        }

        if (index == 26) {
            return (
                'Oberon', [
                    station,
                    3,   //size
                    0,   //class
                    0,   //
                    15   //orbital speed
                ]
            );
        }

        if (index == 27) {
            return (
                'Puck', [
                    moon,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    0,   //slot
                    29   //orbital speed
                ]
            );
        }

        if (index == 28) {
            return (
                'Miranda', [
                    moon,
                    3,   //size
                    1,   //class K, Desert Wasteland
                    1,   //slot
                    5    //orbital speed
                ]
            );
        }

        if (index == 29) {
            return (
                'Ariel', [
                    moon,
                    5,   //size
                    1,   //class K, Desert Wasteland
                    2,   //slot
                    33   //orbital speed
                ]
            );
        }

        if (index == 30) {
            return (
                'Umbriel', [
                    moon,
                    5,   //size
                    1,   //class K, Desert Wasteland
                    3,   //slot
                    10   //orbital speed
                ]
            );
        }

        if (index == 31) {
            return (
                'Titania', [
                    moon,
                    5,   //size
                    1,   //class K, Desert Wasteland
                    4,   //slot
                    41   //orbital speed
                ]
            );
        }

        if (index == 32) {
            return (
                'Oberon', [
                    moon,
                    5,   //size
                    1,   //class K, Desert Wasteland
                    5,   //slot
                    20   //orbital speed
                ]
            );
        }

        if (index == 33) {
            return (
                'Neptune', [
                    planet,
                    24,  //size
                    4,   //class C, Glacial / Ice
                    0,   //rings
                    10   //orbital speed
                ]
            );
        }

        if (index == 34) {
            return (
                'Terra Venture', [
                    station,
                    3,   //size
                    0,   //class
                    0,   //
                    15   //orbital speed
                ]
            );
        }

        if (index == 35) {
            return (
                'Proteus', [
                    moon,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    1,   //slot
                    25   //orbital speed
                ]
            );
        }

        if (index == 36) {
            return (
                'Triton', [
                    moon,
                    9,   //size
                    1,   //class K, Desert Wasteland
                    2,   //slot
                    22   //orbital speed
                ]
            );
        }

        if (index == 37) {
            return (
                'Nereid', [
                    moon,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    3,   //slot
                    28   //orbital speed
                ]
            );
        }

        if (index == 38) {
            return (
                'Pluto', [
                    planet,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    0,   //rings or slots
                    1    //orbital speed
                ]
            );
        }

        if (index == 39) {
            return (
                'Nerva Beacon', [
                    station,
                    1,   //size
                    1,   //class
                    0,   //
                    15    //orbital speed
                ]
            );
        }

        if (index == 40) {
            return (
                'Charon', [
                    moon,
                    1,   //size
                    1,   //class K, Desert Wasteland
                    3,   //slot
                    21   //orbital speed
                ]
            );
        }

        return (
            '', [
                nothing,
                0,
                0,
                0,
                0
            ]
        );
    }
}