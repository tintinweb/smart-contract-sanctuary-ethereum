// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
pragma experimental ABIEncoderV2;

contract storeData {

    struct energyStream {
        address addr; // the stream's owner
        uint startDeliveryTimestamp;
        uint endDeliveryTimestamp;
        uint price; // price desired
        uint64 energy;  // amount of energy to buy or sell
    }

 
    energyStream[] public EnergyStreams;
    mapping(address => uint256) public requestNumber;

    function askForEnergy(uint price, uint64 energy,uint64 startTime,uint64 stopTime) public {
        // make an energyStream to add the params to
        energyStream memory stream;
        stream.addr = msg.sender;
        stream.price = price;
        stream.energy = energy;
        stream.startDeliveryTimestamp = startTime;
        stream.endDeliveryTimestamp = stopTime;

        // push this stream onto the array of energyStreams of stream's owner's address located in the buyEnergy_map
        requestNumber[msg.sender]= EnergyStreams.length;
        EnergyStreams.push(stream);
    }
    function seeRequests(address _address) public view returns(energyStream memory) {
        return EnergyStreams[requestNumber[_address]];
    }

}