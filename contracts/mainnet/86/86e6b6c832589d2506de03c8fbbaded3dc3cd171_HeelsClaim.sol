// Developed by Orcania (https://orcania.io/)
// SPDX-License-Identifier: MIT
pragma solidity =0.7.6;

import "OMS.sol";


interface IERC721 {

    function balanceOf(address _owner) external view returns (uint256);

    function adminMint(address to, uint256 amount) external;

}

interface IERC1155 {

    function adminMint(address user, uint256 amount, uint256 id) external;

}

contract HeelsClaim is OMS { 
    IERC721 immutable DAW = IERC721(0xF1268733C6FB05EF6bE9cF23d24436Dcd6E0B35E);
    IERC721 immutable Heels = IERC721(0xB1444F1d64B5920e8a5c3B62F57808a68bD9b6e9);
    IERC1155 immutable HeelsSpecial = IERC1155(0xa9Bcc11a59b9085a426155418c511d7a8605835B);

    mapping(address => uint256) private _heels; //how many heels this address gets
    mapping(address => bool) private _claimed; //If user claimed or not

    uint256 private dawHeelsMints;

    //Read Functions======================================================================================================================================================

    //Amount of heels a user has available to claim
    function heels(address user) external view returns(uint256) {
        if(_claimed[user]) {return 0;}
        else if(_heels[user] > 0) {return (_heels[user] * 2) + 1;}
        else if(DAW.balanceOf(user) != 0) {return 1;}
        else {return 0;}
    }

    function hasToClaim(address user) external view returns(bool) {
        if(_claimed[user]) {return false;}

        if(_heels[user] > 0) {return true;}
        if(DAW.balanceOf(user) > 0) {return true;}
    }

    function claimed(address user) external view returns(bool) {
        return _claimed[user];
    }
    
    //Moderator Functions======================================================================================================================================================

    function setHeels(address[] calldata users) external Manager{
        uint256 length = users.length;

        for(uint256 t; t < length; ++t) {
            ++_heels[users[t]];
        }

    }

    function claim() external {
        require(!_claimed[msg.sender], "ALREADY_CLAIMED");

        uint256 heels = _heels[msg.sender];
        if(heels > 0) {
            Heels.adminMint(msg.sender, heels);
            HeelsSpecial.adminMint(msg.sender, heels, 0);

            if(dawHeelsMints++ < 333) {
                HeelsSpecial.adminMint(msg.sender, 1, 1); //DAW edition
            }
        }
        else if(DAW.balanceOf(msg.sender) > 0) {
            if(dawHeelsMints++ < 333) {
                HeelsSpecial.adminMint(msg.sender, 1, 1); //DAW edition
            }
        }

        _claimed[msg.sender] = true;
    }
}