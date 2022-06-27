// SPDX-License-Identifier: MIT LICENSE
pragma solidity ^0.8.4;
import "./IERC721.sol";
import "./ERC165.sol";
import "./IFirepit.sol";
import "./Metamallows.sol";
import "./Ownable.sol";
contract Mallowland is ERC165, Ownable {
    Metamallows metamallows;
    IFirepit firepit;

    function setDependecies(address _metamallowAddress, address _firepitAddress) external onlyOwner{
        metamallows = Metamallows(_metamallowAddress);
        firepit = IFirepit(_firepitAddress);
    }
    
    function balanceOf(address owner) public view returns (uint256) {
        uint256 numTokens;
        uint[] memory aux = new uint[](1);
        for (uint256 i = 0; i < metamallows.totalSupply(); i++) {
            aux[0] = i;
            if (firepit.isOwnerOfStakedTokens(aux, owner)) {
                numTokens++;
            }
        }
        return metamallows.balanceOf(owner) + numTokens;
    }

    /**
     * @inheritdoc ERC165
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC165) returns (bool) {
        return interfaceId == type(IERC721).interfaceId || super.supportsInterface(interfaceId);
    }
}