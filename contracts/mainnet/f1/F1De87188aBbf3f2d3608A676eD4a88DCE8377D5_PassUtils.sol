// ░██████╗████████╗░█████╗░██████╗░██████╗░██╗░░░░░░█████╗░░█████╗░██╗░░██╗
// ██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██╔══██╗██║░░░░░██╔══██╗██╔══██╗██║░██╔╝
// ╚█████╗░░░░██║░░░███████║██████╔╝██████╦╝██║░░░░░██║░░██║██║░░╚═╝█████═╝░
// ░╚═══██╗░░░██║░░░██╔══██║██╔══██╗██╔══██╗██║░░░░░██║░░██║██║░░██╗██╔═██╗░
// ██████╔╝░░░██║░░░██║░░██║██║░░██║██████╦╝███████╗╚█████╔╝╚█████╔╝██║░╚██╗
// ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝░╚════╝░░╚════╝░╚═╝░░╚═╝

// SPDX-License-Identifier: MIT
// StarBlock DAO Contracts, https://www.starblockdao.io/

pragma solidity ^0.8.0;

//import "@openzeppelin/contracts/access/Ownable.sol";
//import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

import "./Ownable.sol";
import "./ReentrancyGuard.sol";
import "./IERC721Metadata.sol";

interface IPassUtils {
    function hasPass(address _user) external view returns (bool);
    function ownedPasses(address _user) external view returns (IERC721Metadata[] memory _passes, uint256[] memory _ownedAmounts);
}

contract PassUtils is IPassUtils, Ownable, ReentrancyGuard {
    IERC721Metadata[] public passes;

    function passesLength() external view returns (uint256) {
        return passes.length;
    }

    function addPasses(IERC721Metadata[] memory _passes) external onlyOwner nonReentrant {
        for(uint256 index = 0; index < _passes.length; index ++){
            passes.push(_passes[index]);
        }
    }

    function removePasses(IERC721Metadata[] memory _passes) external onlyOwner nonReentrant {
        _removeFromArray(_passes, passes);
    }

    // remove the _array1 element from _array2
    function _removeFromArray(IERC721Metadata[] memory _array1, IERC721Metadata[] storage _array2) internal {
        for(uint256 index1 = 0; index1 < _array1.length; index1 ++){
            uint256 removeIndex;
            bool exist = false;
            for(uint256 index2 = 0; index2 < _array2.length; index2 ++){
                if(_array1[index1] == _array2[index2]){
                    removeIndex = index2;
                    exist = true;
                    break;
                }
            }
            if(exist){
                _array2[removeIndex] = _array2[_array2.length - 1];
                _array2.pop();
            }
        }
    }

    function hasPass(address _user) external view returns (bool _has) {
        for(uint256 index = 0; index < passes.length; index ++){
            if(passes[index].balanceOf(_user) > 0){
                _has = true;
                break;
            }
        }
    }

    function ownedPasses(address _user) external view returns (IERC721Metadata[] memory _passes, uint256[] memory _ownedAmounts) {
        uint256 amount = 0;
        for(uint256 index = 0; index < passes.length; index ++){
            if(passes[index].balanceOf(_user) > 0){
                amount ++;
            }
        }
        if(amount > 0){
            _passes = new IERC721Metadata[](amount);
            _ownedAmounts = new uint256[](amount);
            uint256 ownedIndex = 0;
            for(uint256 index = 0; index < passes.length; index ++){
                IERC721Metadata pass = passes[index];
                uint256 ownedAmount = pass.balanceOf(_user);
                if(ownedAmount > 0){
                    _passes[ownedIndex] = pass;
                    _ownedAmounts[ownedIndex] = ownedAmount;
                    ownedIndex ++;
                    if(ownedIndex == amount){
                        break;
                    }
                }
            }
        }
    }
}