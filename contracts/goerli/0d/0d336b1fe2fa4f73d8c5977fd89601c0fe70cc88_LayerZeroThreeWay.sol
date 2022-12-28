pragma solidity >=0.8.17;

import "./imports.sol";

/*
    LayerZero Goerli
      lzChainId:10121 lzEndpoint:0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23
      contract: 0x0D336B1fE2fa4F73D8c5977fD89601C0fE70CC88

    LayerZero Optimism Goerli
      lzChainId:10132 lzEndpoint:0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1
      contract: 0x44D52aF46ee6A06EAf71e01081C2E9ACA3BE71EB

    Goerli Arbitrum
      lzChainId:10143 lzEndpoint:0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab
      contract:   

    MATIC testnet
      lzChainId:10109 lzEndpoint:0xf69186dfBa60DdB133E91E9A4B5673624293d8F8
      contract: 0x91c0aA85B4d15Bd3A2e0AEA28a1BaF1B238598eD

*/

contract LayerZeroThreeWay is LzApp {
    string public data = "Nothing received yet";
    uint16 public destChainId=0;
    
    // uint16 constant GOERLI_CHAIN = 10121;
    // uint16 constant OPTIMISM_CHAIN = 10132;
    // uint16 constant ARBITRUM_CHAIN = 10143;
    // uint16 constant POLYGON_CHAIN = 10109;
    bool public relay;

    address[] public endpoints = [0xbfD2135BFfbb0B5378b56643c2Df8a87552Bfa23,
                                    0xae92d5aD7583AD66E49A0c67BAd18F6ba52dDDc1,
                                    0x6aB5Ae6822647046626e83ee6dB8187151E1d5ab,
                                    0xf69186dfBa60DdB133E91E9A4B5673624293d8F8];

    uint16[] public chainIds = [10121, 10132, 10143, 10109];


    ILayerZeroEndpoint public endpoint;
    
    constructor(uint16 _from, uint16 _to, bool _r) LzApp(endpoints[_from]) payable {
        require(_from != _to);
        destChainId = chainIds[_to];
        relay=_r;
    }
    
    function setDestChainId(uint16 _d) external {
      destChainId = _d;
    }

    function _blockingLzReceive(uint16, bytes memory, uint64, bytes memory _payload) internal override {
       data = abi.decode(_payload, (string));
       if (relay)
        send(data);
    }

    function send(string memory _message) public payable {
        bytes memory payload = abi.encode(_message);
        // uint16 version = 1;
        // uint gasForDestinationLzReceive = address(this).balance;
        // bytes memory adapterParams = abi.encodePacked(version, gasForDestinationLzReceive);        
        _lzSend(destChainId, payload, payable(0xDBB8eA5CC7Abf30afBBa71e74DC8A0c7882872E1), 
        address(0x0),bytes(""), address(this).balance);
    }
    receive() external payable {}

    function withdraw() external {
      payable(0xDBB8eA5CC7Abf30afBBa71e74DC8A0c7882872E1).transfer(address(this).balance);
    }



}