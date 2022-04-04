/**
 *Submitted for verification at Etherscan.io on 2022-04-04
*/

// Matt Gawin - Waste24.net Smart Contract for ESR Sp. z o.o.

pragma solidity ^0.8.4;

contract Waste24Contract {

    string[] listOfValidAddresses;
    string[] private tempList;
    address waste24Wallet = 0x7EBDAf4634298f33CE118A9F2AAE3d3c656db15E;

    function addDeviceToContract(string[] memory deviceAddress) public {
        if(msg.sender == waste24Wallet)
        {
            for (uint i; i< deviceAddress.length;i++) {
                if(!validateList(deviceAddress[i])) listOfValidAddresses.push(deviceAddress[i]);
            }
        }
    }

    function removeDeviceFromContract(string[] memory deviceAddress) public {
        if(msg.sender == waste24Wallet)
        {
            for (uint i; i< deviceAddress.length;i++) {
                for (uint i2; i2< listOfValidAddresses.length;i2++) {
                    if(!equals(listOfValidAddresses[i2],deviceAddress[i])) tempList.push(listOfValidAddresses[i2]);
                }
                listOfValidAddresses = tempList;
                delete tempList;
            }
        }
    }

    function getContractInfo() public view returns (string memory) {
        return "This contract validates a list of authorized capacity sensor addresses for sending automatic dispositions. Contract was created for ESR Sp. z o.o. by Waste24.net";
    }

    function equals(string memory a, string memory b) private pure returns (bool) {
        if(bytes(a).length != bytes(b).length) return false;
        else return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }

    function listActiveDevices() public view returns (string[] memory) {
        return listOfValidAddresses;
    }

    function validateList(string memory deviceAddress) private view returns (bool) {
        for (uint i; i< listOfValidAddresses.length;i++){
            if(equals(listOfValidAddresses[i],deviceAddress)) return true;
        }
        return false;
    }

    function checkDeviceValidityInContract(string memory deviceAddress) public view returns (bool) {
        return validateList(deviceAddress);
    }
}