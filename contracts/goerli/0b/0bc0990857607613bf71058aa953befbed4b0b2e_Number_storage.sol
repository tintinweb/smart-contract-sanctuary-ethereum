/**
 *Submitted for verification at Etherscan.io on 2022-11-24
*/

contract Number_storage {
    mapping(address => uint256) public favourite_number_to_address;

    function save_number(uint256 fav_number) public {
        favourite_number_to_address[msg.sender] = fav_number;
    }
}