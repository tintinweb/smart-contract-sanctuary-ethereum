/**
 *Submitted for verification at Etherscan.io on 2022-02-27
*/

// File: contracts/ERC20.sol



// import "./ERC721A.sol";

pragma solidity 0.8.10;


// import "@openzeppelin/contracts/access/Ownable.sol";

// contract ERC20  {

//     mapping(address => uint256) public map;

    
//     function balanceOf(address user) public view returns(uint256) {
//         return map[user];
//     }

//     function setMapping(address user, uint balance) public {
//         map[user] = balance;
//     }
// }

contract Again {

    event Test(bytes data);

    function great(bytes memory data) public {
        emit Test(data);
    }
}