// SPDX-License-Identifier: Apache-2.0
//
//  _______           __       ________  _____     
// |_   __ \         [  |     |_   __  ||_   _|    
//   | |__) |__   _   | |.--.   | |_ \_|  | |      
//   |  ___/[  | | |  | '/'`\ \ |  _|     | |   _  
//  _| |_    | \_/ |, |  \__/ |_| |_     _| |__/ | 
// |_____|   '.__.'_/[__;.__.'|_____|   |________| 
// 
// PubFL is a Ethereum-based reputation system to facilitate federated learning. 
// This contract is part of the PubFL research paper by Anton Wahrstätter. The contracts do only 
// represent Proof-of-Concepts and have not been developed to be used in productive
// environments. Do not use them, except for testing purpose.                                              

pragma solidity =0.8.9;

import "./PubFLModel.sol";

contract PubFLManager {
    
    mapping(address => mapping(uint256 => address)) public ModelOf;
    mapping(address => uint256) public ModelCountOf;

    constructor(){}

    function deployModel(bytes32 _modelHash, uint _min_collateral, uint _max_collateral, uint _reward, 
                         uint8 _min_rounds, uint8 _punishfactor, uint8 _freeriderPenalty) public payable {
        ModelCountOf[msg.sender] += 1;
        require(msg.value >= _reward + _min_collateral, "NEV");
        PubFLModel model = new PubFLModel{value:_reward}(_modelHash,
                                                         _min_collateral, 
                                                         _max_collateral, 
                                                         _reward,
                                                         _min_rounds, 
                                                         _punishfactor,
                                                         _freeriderPenalty);
        model.register{value:msg.value - _reward}(msg.sender);
        ModelOf[msg.sender][ModelCountOf[msg.sender]] = address(model);
    }
}