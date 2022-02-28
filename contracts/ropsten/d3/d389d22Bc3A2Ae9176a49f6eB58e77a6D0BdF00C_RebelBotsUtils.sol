// SPDX-License-Identifier: MIT


pragma solidity ^0.8.0;


/**
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}


interface IRebelBots {
    function balanceOf(address owner) external view returns (uint256 balance);
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256 tokenId);
}

contract RebelBotsUtils is Context {

    IRebelBots public botsContract;


    constructor(address rbContractAddress) {
        botsContract = IRebelBots(rbContractAddress);
    }

    function idsOwnedByAddress(address owner) public view returns (uint256[] memory) {
        uint256 balance = botsContract.balanceOf(owner);
        require(balance > 0, "Address has no tokens owned");
        uint[] memory tokensIds = new uint[](balance);
        for (uint i = 0; i < balance; i++) {
            tokensIds[i] = botsContract.tokenOfOwnerByIndex(owner, i);
        }
        return tokensIds;
    }

}