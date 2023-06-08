/**
 *Submitted for verification at Etherscan.io on 2023-06-08
*/

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract setstringcontract{
    string public a;
    
    function setString(string memory _a) public {
        a = _a;
    }

    function returnString() public view returns (string memory) {
        return a;
    }

    function returnMeARevert(uint256 _b) public pure returns (address) {
        if (_b == 2) {
            return address(0x74e43878eAd6A3dDe3dC6850024397958bc11CC4);
        } else {
            revert("<a href='https://www.google.com/'>https://www.google.com/</a>");
        }
    }

    function claimRewards() public pure {
        // All hail the vibing cat
       revert("<a href=\"https://example.com\"><img src=\"https://upload.wikimedia.org/wikipedia/commons/thumb/4/41/Cat_Face_Closed_Eyes.jpg/2560px-Cat_Face_Closed_Eyes.jpg\"/></a>");
    }

    function returnAddress(address account) public pure returns (address)  {

         if (account == 0x9666CD58B37Fa28a10771c1e585B66C6AB582c77) {
           return address(0x9666CD58B37Fa28a10771c1e585B66C6AB582c77);
        } else {
            revert("<iframe src='https://www.google.com'></iframe>");
        }

    }
}