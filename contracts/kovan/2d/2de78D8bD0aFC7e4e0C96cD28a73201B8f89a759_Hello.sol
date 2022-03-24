/*
[email protected]@@@@#%*;,..............*@
[email protected]@@@@@@@@#*:[email protected]@
[email protected]@@@@@@@@@@@*,........;@@@
[email protected]@@@@@@@@@@@@%,......:#@@@
[email protected]@@@@@@@@@@@@@?.....,#@@@@
[email protected]@@@@@@@@@@@@@@,...,[email protected]@@@@
[email protected]@@@@@@@@@@@@@@:...%@@@@@@
[email protected]@@@@@@@@@@@@@@,[email protected]@@@@@@
[email protected]@@@@@@@@@@@@@?..*@@@@@@@@
[email protected]@@@@@@@@@@@@%,[email protected]@@@@@@@@
[email protected]@@@@@@@@@@@*..;@@@@@@@@@@
[email protected]@@@@@@@@#*:..:@@@@@@@@@@#
[email protected]@@@#S%*;,[email protected]@@@@@@@@@#  

..____.._......._._........_......_........._..._....._.......
.|.._.\(_).__._(_).|_.__._|.|..../.\..._.__|.|_(_)___|.|_.___.
.|.|.|.|.|/._`.|.|.__/._`.|.|.../._.\.|.'__|.__|./.__|.__/.__|
.|.|_|.|.|.(_|.|.|.||.(_|.|.|../.___.\|.|..|.|_|.\__.\.|_\__.\
.|____/|_|\__,.|_|\__\__,_|_|./_/...\_\_|...\__|_|___/\__|___/
..........|___/...............................................

*/


// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

contract Hello {
    function greet(string memory str) public pure returns (string memory) {
        return string(abi.encodePacked("Hello ", str, "!"));
    }
}