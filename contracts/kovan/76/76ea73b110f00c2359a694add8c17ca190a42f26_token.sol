// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "./ERC20.sol";
import "./IERC20.sol";
import "./IERC20Metadata.sol";
import "./Context.sol";

contract token is ERC20{
    uint32 public release_time = uint32(block.timestamp);
    uint112 public constant max_token_number = uint112(1000000000000 ether);

    mapping(address => bool) public is_claim;
    address[] public yet_claim_people;
    uint112 public all_claim = max_token_number/2;

    constructor() ERC20("FUNKOCOOK", "FCK"){
        // _mint(0x5143250916C938e198FE8bFdB5c9A58D92782ba8,uint112(max_token_number/100*12));
        // _mint(0x5B47c22Fdf2b6e21fc381F045A81DFF68A5F6f54,uint112(max_token_number/100*38));
    }

    function claim() external{
        if( (uint32(block.timestamp)-release_time) <= 360 days && is_claim[msg.sender] == false ){
            is_claim[msg.sender] = true;
            yet_claim_people.push(msg.sender);
            _mint(msg.sender,return_claim_number());
        }   
        }

    function return_claim_number() public view returns(uint104){
        uint104 claim_number;

        if(yet_claim_people.length <= 1010){
            claim_number = uint104(all_claim/100*20/1010*1);
        }

        else if(yet_claim_people.length > 1010 && yet_claim_people.length <= 101010){
            claim_number = uint104((all_claim/100*80)/100000*1);
        }

        return claim_number;
    }

    function return_is_claim(address _address) public view returns(bool){
        return is_claim[_address];
    }
}