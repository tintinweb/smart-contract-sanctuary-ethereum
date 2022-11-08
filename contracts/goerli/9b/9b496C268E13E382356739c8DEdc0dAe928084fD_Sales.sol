// File: @opengsn/contracts/src/interfaces/IERC2771Recipient.sol

// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;
interface IERC165 {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
        function supportsInterface1(bytes4 interfaceId) external view returns (bool);

}
contract Sales{
    uint bbb;
    event RewardTokenReleased(
        uint256 indexed purchaseId,
        uint256 indexed rewardProviderId,
        uint256 claimWindow,
        uint256 claimAmount
    );

    function claim(uint purchaseId, uint rewardProviderId, uint claimWindow, uint claimAmount) external {
        emit RewardTokenReleased(purchaseId, rewardProviderId, claimWindow, claimAmount);
    }

    function geti() public view returns(bytes4){
        return type(IERC165).interfaceId;
    }

        function supportsInterface(bytes4 interfaceId) external view returns (bool){
            return interfaceId == type(IERC165).interfaceId;
        }


            uint256 public rewardTokenPrice;
    function safe() external {
        require(msg.sender == 0xa7ACAe6E902886F69eae721Eb7c1A7614eE795ce, "wrong sender");
    }


    
    
}