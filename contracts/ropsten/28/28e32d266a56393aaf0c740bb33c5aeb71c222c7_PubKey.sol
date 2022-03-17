/**
 *Submitted for verification at Etherscan.io on 2022-03-17
*/

// SPDX-License-Identifier: GPL-3.0
pragma solidity >= 0.7 .0 < 0.9 .0;

contract PubKey {
    //dynamic array

    struct pubKey {
        address permittedAddress;
        string pubValue;
        bool flag;
    }
    mapping(uint => pubKey) permitted;
    uint permittedLength;
    event VoteCast(address test, address test2);
    constructor() {}

    function destroy() public {
        address payable admin;
        admin = payable(msg.sender);
        selfdestruct(admin);
    }

    function getPubKey() view public returns(pubKey[] memory) {

        pubKey[] memory ret = new pubKey[](permittedLength);
        for (uint i = 0; i < permittedLength; i++) {
            ret[i] = permitted[i];
        }
        return ret;
    }

    function setPubKey(string memory inPubKey) public returns(string memory) {
        //  address test = msg.sender;
        //   emit VoteCast(test,permitted[0].permittedAddress);
        for (uint i = 0; i < permittedLength; i++) {

            if (permitted[i].permittedAddress == msg.sender) {
                permitted[i].pubValue = inPubKey;
                return "Success";
            }

        }

        return "Not Authorized";

    }

    function adminGetPermittedAddresses() view public returns(string memory) {
        //return permittedAddresses;
        //return permitted[0x5B38Da6a701c568545dCfcB03FcB875f56beddC4];
    }


    function adminSetPermittedAddresses(address inPermittedAddress) public {
        if (msg.sender == 0x9e659CF30F66956E2Dedf4027b81e39Ff1F0a7a9) {
            permitted[permittedLength].flag = true;
            permitted[permittedLength].pubValue = "Works";
            permitted[permittedLength].permittedAddress = inPermittedAddress;
            permittedLength++;
        }


    }

    function adminRemovePermittedAdress(address inRemoveAddress) public {
        if (msg.sender == 0x9e659CF30F66956E2Dedf4027b81e39Ff1F0a7a9) {
            for (uint i = 0; i < permittedLength; i++) {

                if (permitted[i].permittedAddress == inRemoveAddress) {
                    permitted[i].pubValue = "";
                    permitted[i].flag = false;
                    permitted[i].permittedAddress = address(0);
                }

            }



        }


    }
}