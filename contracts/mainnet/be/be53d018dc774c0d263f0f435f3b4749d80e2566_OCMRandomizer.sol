// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./VRFConsumerBase.sol";
import "./Ownable.sol";

//
//   
//    ______     __   __     ______     __  __     ______     __     __   __    
//   /\  __ \   /\ "-.\ \   /\  ___\   /\ \_\ \   /\  __ \   /\ \   /\ "-.\ \   
//   \ \ \/\ \  \ \ \-.  \  \ \ \____  \ \  __ \  \ \  __ \  \ \ \  \ \ \-.  \  
//    \ \_____\  \ \_\\"\_\  \ \_____\  \ \_\ \_\  \ \_\ \_\  \ \_\  \ \_\\"\_\ 
//     \/_____/   \/_/ \/_/   \/_____/   \/_/\/_/   \/_/\/_/   \/_/   \/_/ \/_/ 
//                                                                              
//    __    __     ______     __   __     __  __     ______     __  __          
//   /\ "-./  \   /\  __ \   /\ "-.\ \   /\ \/ /    /\  ___\   /\ \_\ \         
//   \ \ \-./\ \  \ \ \/\ \  \ \ \-.  \  \ \  _"-.  \ \  __\   \ \____ \        
//    \ \_\ \ \_\  \ \_____\  \ \_\\"\_\  \ \_\ \_\  \ \_____\  \/\_____\       
//     \/_/  \/_/   \/_____/   \/_/ \/_/   \/_/\/_/   \/_____/   \/_____/       
//                                                                              
//   
// 
// OnChainMonkey (OCM) Genesis was the first 100% On-Chain PFP collection in 1 transaction 
// (contract: 0x960b7a6BCD451c9968473f7bbFd9Be826EFd549A)
// 
// created by Metagood
//
// OCM Desserts will be an On-Chain collection that OCM Genesis can eat (burn) to create the
// new Karma collection.
//
// OCM Desserts, being 100% On-Chain, will also live forever, just like OCM Genesis. However,
// the Desserts will need to be burned to create Karma, so the Dessert supply will be 
// decreasing over time.
//
// This is not the OCM Dessert contract, but the official OCM randomizer. This smart contract
// will be the fair and transparent way to generate randomness on chain by using the Chainlink 
// VRF (Verifiable Random Function).
//
// The first call will generate the OCM Dessert distribution.
//
//....................................................................................................
//....................................................................................................
//....................................................................................................
//....................................................................................................
//......................................':ldk0KNWWMMMMWWNK0kdl:'......................................
//..................................:oONMMMMMMMMMMMMMMMMMMMMMMMMNOo;..................................
//..............................'lONMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMWOl'..............................
//............................cOWMMMMMMMMMMWX0kdolllcllodk0XWMMMMMMMMMMWOc............................
//..........................dXMMMMMMMMWKxl,..................,lxKWMMMMMMMMXd..........................
//........................oNMMMMMMMWOl'..........................'lOWMMMMMMMNo........................
//......................lXMMMMMMW0l..................................l0MMMMMMMXl......................
//....................'0MMMMMMMO;......................................;OMMMMMMMO'....................
//...................,XMMMMMMX:..........................................:XMMMMMMX,...................
//..................;NMMMMMMO..............................................OMMMMMMN;..................
//.................'XMMMMMMx...kKKKKKKKKKKKKKKKKc........'KKKKKKKKKKKKKKk...xMMMMMMX'.................
//..........'coxkOkKMMMMMMx....kXXXXXXXXXXXXXXXXc........'XXXXXXXXXXXXXXk....xMMMMMMKkOkxoc,..........
//.......'dXMMMMMMMMMMMMM0....................................................0MMMMMMMMMMMMMXd'.......
//.....'kWMMMMMMMMMMMMMMW,......,ooc...loc...loo'........'l...col...cooc......;WMMMMMMMMMMMMMMWk......
//....,XMMMMMMWKOKMMMMMMk.......'XMW:..':...dMMO.........,Wd...:'..cWMMO.......kMMMMMMKkKWMMMMMMX'....
//....OMMMMMMO,..oMMMMMMl........'kWWOl;;:oKMNo...........cWKo:;:lOWMM0'.......lMMMMMMd..,OMMMMMMO....
//...'WMMMMMK....xMMMMMM:..........'lkKXNX0xc..............'dXMMMMMW0c.........:MMMMMMx....KMMMMMW'...
//...'WMMMMMX....xMMMMMM:.....................................';:;,............:MMMMMMx....XMMMMMW'...
//....kMMMMMM0:..oMMMMMMo......................................................oMMMMMMo..:0MMMMMMk....
//.....KMMMMMMMNKXMMMMMMO......................................................OMMMMMMXKNMMMMMMMK'....
//......dNMMMMMMMMMMMMMMW:................',:clooddddddoolc:,'................:WMMMMMMMMMMMMMMNd......
//........l0WMMMMMMMMMMMMK...........:dOXWMMMMXokMMMMMMkoXMMMMWXOd:...........KMMMMMMMMMMMMW0l........
//...........;coddd0MMMMMMk.......l0WMMMMMMMMMXokMMMMMMkoXMMMMMMMMMW0l.......OMMMMMM0dddoc;...........
//..................KMMMMMMO....'XMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMK'....kMMMMMMK..................
//..................,XMMMMMM0'..cMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMc..'0MMMMMMX'..................
//...................'KMMMMMMNo..oNMMMMWWWWWWWWWWWWWWWWWWWWWWWWWWMMMMNo..lNMMMMMMK'...................
//.....................kMMMMMMMKc..ckXWxllllllllllllllllllllllllxWXkc..cKMMMMMMMk.....................
//......................:KMMMMMMMXd,..';ldkOKXNWWMMMMMMWWNXKOkdl;...,dXMMMMMMMK:......................
//........................cXMMMMMMMMKd;..........................;dKMMMMMMMMXc........................
//..........................cKMMMMMMMMMNOd:,................,:dONMMMMMMMMMKc..........................
//............................;xNMMMMMMMMMMMWX0kxddddddxk0XWMMMMMMMMMMMNx;............................
//...............................:xXMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMMXx:...............................
//..................................'cx0NMMMMMMMMMMMMMMMMMMMMMMN0xc'..................................
//.......................................,:ldkO0KXNNNNXXKOkdl:,.......................................
//....................................................................................................
//....................................................................................................
//....................................................................................................

library Strings {
    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT licence
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

//
// Use ChainLink's VRF to distribute the Desserts for OnChainMonkey
//
// First call sets the Desserts
// Later calls to the VRF generate random numbers to be used in future features
//
contract OCMRandomizer is VRFConsumerBase, Ownable {
    using Strings for uint256;
    bytes32 internal keyHash;
    uint256 internal fee;
    
    uint256[] public randomResults; // track all random numbers, first random number is used for Desserts
    uint256 public counter = 0;     // counter of random numbers generated
    uint256 public offset;          // offset of Desserts, set once and locked after first random number

    event RandomRequested(bytes32 indexed requestId, address indexed requester);
    event RandomFullfilled(bytes32 indexed requestId, uint256 indexed result);

    /**
     * Constructor inherits VRFConsumerBase
     * 
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     * Request testnet LINK and ETH here: https://faucets.chain.link/
     *
     * retreived from: https://docs.chain.link/docs/vrf-contracts/
     * Network: Mainnet
     * LINK Token  0x514910771AF9Ca656af840dff83E8264EcF986CA
     * VRF Coordinator  0xf0d54349aDdcf704F77AE15b96510dEA15cb7952
     * Key Hash  0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445
     */
    constructor() 
        VRFConsumerBase(
            0xf0d54349aDdcf704F77AE15b96510dEA15cb7952, // VRF Coordinator
            0x514910771AF9Ca656af840dff83E8264EcF986CA  // LINK Token
        )
    {
        keyHash = 0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445;
        fee = 2 * 10 ** 18; // 2 LINK (Varies by network)
    }
    
    /** 
     * Requests randomness, first call is used for Desserts 
     */
    function getRandomNumber() external onlyOwner returns (bytes32 requestId) {
        require(block.number > 14181581, "Not time yet");
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK");
        requestId = requestRandomness(keyHash, fee);
        emit RandomRequested(requestId, msg.sender);
        return requestId;
    }

    //
    // Dessert distribution for each OCM# (j)
    //
    // If offset is 0, 15 Dessert3s at j = 364, 1301, 1453, 1527, 1601, 1629, 2214, 4097, 5227, 5956, 6694, 6754, 7442, 9132, 9850
    // Overall distribution of Desserts is 15 Dessert3, 4485 Dessert2, 5500 Dessert1
    //
    function dessert(uint256 j) public view returns (uint256) {
        require(counter > 0, "Dessert not served");
        require(j>0 && j<10001, 'error');
        j = (j + offset) % 10000; // this is the fair and random offset from the VRF
        uint256 r = (uint256(keccak256(abi.encode(j.toString())))) % 10000; // this is the fixed sequence with the desired rarity distribution
        if (r < 8) {
            return 3; // Dessert3
        } else if (r >= 5538) {
            return 2; // Dessert2
        } else {
            return 1; // Dessert1
        }
    }    

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResults.push(randomness);
        if (counter == 0) {
            offset = randomness % 10000; // There is very minor bias in ideal uniform probability distribution because randomness 2**256 % 10000 != 0
        }
        counter++; // Counter could wrap around to 2**256 in theory, but not in practice
        emit RandomFullfilled(requestId, randomness);        
    }

    // Withdraw function to avoid locking LINK in the contract
    function withdrawLink() external onlyOwner {
        LINK.transfer(owner(), LINK.balanceOf(address(this)));
    }
}