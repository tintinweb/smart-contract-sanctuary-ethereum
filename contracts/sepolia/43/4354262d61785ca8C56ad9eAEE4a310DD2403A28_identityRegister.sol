/**
 *Submitted for verification at Etherscan.io on 2023-06-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract identityRegister {
    struct data {
        uint numberOfUser;
        mapping(uint => string) fingerKeys;
        mapping(address => bool) exist;
    }
    mapping(string => data) datas;

    string public demoFingerKey =
        '[[[18,2,7,0,6,5,2,0,0,3,3,5,1,6,6,7,4,161,40,247,160,125,140,34,58,129,132,111,109,26,36,236],"ac0608178b0370b3577d8f84eac3f4fbfd420af1491beffe7506cd92ee695102"],[[4,1,3,5,0,3,0,7,7,0,2,0,4,6,3,0,7,2,2,95,148,235,99,34,210,38,136,111,116,94,176,240],"9c19c92a0a4d021a7e25b2d6c6d4a4a344850d3937cb08a127bb99561cca1fa1"],[[17,7,4,4,5,5,7,4,7,5,6,1,5,7,5,5,4,192,56,180,42,25,35,188,131,105,85,239,105,103,101,19],"ccee6104496be7536768dd8cf42ee90588418f484da0dc000417cb239ac3980d"],[[23,1,5,5,1,3,4,6,2,4,0,3,7,1,2,6,10,90,235,47,214,143,147,246,9,203,3,193,250,20,177,249],"f223d3678f17e1b5e97ab2777d9d4c5f49b4248b0fa7e52edbf3bba7f014f56d"],[[12,6,5,4,4,0,6,5,1,0,2,4,6,0,2,3,0,3,245,83,31,185,35,94,34,44,154,169,234,163,231,231],"574b724ce59953d009cb42873bb655f1134c099b95285939aa9dacb3873d7275"],[[3,1,5,6,2,5,1,2,7,1,2,2,7,7,3,3,3,0,0,5,18,250,249,85,51,128,25,28,108,0,52,69],"6cf56a3480a2b22dcf1dad207b127cd0ae04fdc550aed6e79cd857e00680a142"],[[13,4,0,5,6,6,0,4,3,5,7,7,3,0,1,5,3,28,201,243,68,76,46,126,35,188,34,211,47,113,216,201],"34d8515a7f4595244e13752ded2d8f8fb72da29c381f71988c9f9c34b73e3e2c"],[[5,2,2,7,1,7,5,6,0,6,0,3,7,6,6,0,5,3,7,201,169,17,100,133,68,67,103,244,119,115,210,43],"0a5c38df719522b961b8fad2ed4f44208f6f438e46600b685198798e11640e9a"],[[9,2,3,0,7,6,5,2,1,6,6,2,7,4,2,0,6,7,171,112,64,210,53,91,234,208,66,41,168,3,129,47],"468461af73a1385667a773493a585951e243a4fdc309961f7c008a22c3016239"],[[11,7,6,6,7,1,2,6,2,7,5,3,3,0,2,7,6,1,27,223,179,113,174,167,218,231,129,97,48,178,9,158],"14fd70305279a5e41e8d43a0b2d352014d0a2ca7298dd93c707b5ec017396ea0"],[[13,3,2,0,5,4,6,4,1,3,0,2,5,3,0,1,4,6,125,33,86,132,104,232,196,92,94,129,97,238,119,184],"7cad7c622208a05508977e75baa16911446df9aefb4ed0da687acdb0a57f59bf"],[[16,5,7,0,3,5,3,7,0,0,4,2,2,4,0,6,2,47,137,168,227,14,184,68,196,204,113,197,227,31,174,200],"aaa46e85a788bfe61847f5445a416901f7e93b450e8df80f0139947dd41c19a1"],[[15,5,1,6,3,3,7,1,7,7,3,5,0,5,3,6,5,77,14,158,112,47,132,222,79,223,247,111,26,77,113,0],"73f139f6aa56c66742934d26d3721ff7104ab29a6a3e8196fb4410955ff56897"],[[8,3,5,5,2,4,6,0,6,1,5,1,6,0,4,1,1,7,85,77,138,11,238,110,197,43,241,32,168,95,204,44],"28c4d9fcb60c164dfb6e355d8921c4b426affb89858c5ebba30153f292e72119"],[[18,4,4,0,2,1,6,7,7,3,4,1,4,0,6,1,7,46,234,113,192,62,231,237,235,206,208,1,113,221,151,18],"bb36c177793789519a55bf413c2169fbd1fddba546ec53492deb75aa8fe92eff"],[[21,7,6,7,2,7,4,1,7,7,0,6,1,5,6,0,5,198,75,158,92,14,215,84,49,20,129,224,202,247,207,169],"ed224f69b3d89271e48fbb311cecdfb09a7f1fac837242c636ce128072316621"],[[1,0,1,1,1,6,1,2,3,6,1,2,6,6,3,0,4,6,1,3,21,148,142,223,77,195,103,149,49,105,133,154],"f26850b1c9d3522ede44eee46a021b6891439bbdbc914f37d0141827810fd38a"],[[10,6,3,5,0,0,1,4,3,5,5,7,3,2,3,3,5,17,198,186,87,251,73,236,75,245,25,250,224,227,131,157],"6577da100090353ff6dba8d8c3fcef4efec8647841432ec5f4d7e555cab11e0c"],[[18,1,6,0,2,3,5,6,3,7,1,2,0,1,1,4,9,205,67,58,254,166,98,178,241,130,171,7,104,27,42,213],"487f5ce557fdc0715e9dff7c407100a5fad1f82447e692bcd23d11415733f115"],[[13,4,1,1,5,1,2,3,3,4,2,6,6,5,4,5,6,121,213,191,231,79,184,68,200,76,68,204,2,46,221,195],"4535b13eb0384ca599673faa80bcbc3e93ea1c58d1b344d57403cae59ddaa294"]]';

    uint constant lenPointsNumber = 3;
    uint constant lenInfoPerPoints = 2;

    function getPotentialFingerKey(
        string memory userInfo
    ) external view returns (string[] memory) {
        uint _numberOfUser = datas[userInfo].numberOfUser;
        string[] memory allMatch = new string[](_numberOfUser);
        for (uint i = 0; i < _numberOfUser; i++) {
            allMatch[i] = datas[userInfo].fingerKeys[i];
        }
        return (allMatch);
    }

    /**
        @dev userInfo = prenom || name || birthdate
    */
    function getTotalNumberOfMatchingUser(
        string memory userInfo
    ) external view returns (uint) {
        return datas[userInfo].numberOfUser;
    }

    function setUserRigistering(
        string memory userInfo,
        string memory userFingerKey
    ) public {
        /*require(
            datas[userInfo].exist[msg.sender] == false,
            "user already register"
        );*/
        datas[userInfo].exist[msg.sender] = true;
        datas[userInfo].fingerKeys[
            datas[userInfo].numberOfUser
        ] = userFingerKey;
        datas[userInfo].numberOfUser++;
    }
}