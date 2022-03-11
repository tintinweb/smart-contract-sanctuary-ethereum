/**
 *Submitted for verification at Etherscan.io on 2022-03-10
*/

// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;


contract  OpenSeed{

    struct Proposal {
        //string name;
        //uint id; 
        //string desc;
        uint index;
        uint proposal_block_number;
        uint256 data_sha256;
        string data_ipfs;
        bytes32 seed;
        string doi;
    }


    mapping(address => Proposal[]) public proposals;
    
    event _submit(address,uint);

    function submit(Proposal memory prop) external {
        prop.proposal_block_number = block.number;
        Proposal[] storage addr_props = proposals[msg.sender];
        prop.index = addr_props.length;
        addr_props.push(prop);
    }

    function request(uint _proposal_block_number) external returns (bytes32) {
        require(block.number > _proposal_block_number,"Please Waiting...");
        require(block.number - _proposal_block_number <= 256,"" );

        (bool _isExist, Proposal memory _prop)  = _getProp(_proposal_block_number);

        require(_isExist, "No Proposal!");
        require(_prop.seed != "", "");
        
        bytes32 seed = blockhash(_proposal_block_number + 1);

        Proposal[] storage addr_props = proposals[msg.sender];
        Proposal storage prop = addr_props[_prop.index];
        prop.seed = seed;

        return seed;
    }


    function _getSeed(uint _proposal_block_number) public view returns (bytes32){
        
        require(block.number > _proposal_block_number,"Please Waiting...");
        
        if(block.number - _proposal_block_number <= 256){
            return blockhash(_proposal_block_number + 1);
        }else{
            (bool _isExist, Proposal memory _prop)  = _getProp(_proposal_block_number);
            if(_isExist){
                return _prop.seed;
            }else{
                return "";
            }
        }
    }

    function _getProp(uint _proposal_block_number) public view returns (bool,Proposal memory){
        
        Proposal[] memory addr_props = proposals[msg.sender];

        for(uint i = addr_props.length - 1; i >=0; i--){
            if (addr_props[i].proposal_block_number == _proposal_block_number){
                return (true, addr_props[i]);
            }
        }
        return (false, Proposal(0,0,0,",","",""));
    }

    function close(uint _proposal_block_number,string memory _doi) external{
        (bool _isExist, Proposal memory _prop)  = _getProp(_proposal_block_number);
        require(_isExist,"");
        _prop.doi = _doi;
    }

}