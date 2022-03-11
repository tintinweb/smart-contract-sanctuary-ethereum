// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Ownable.sol';
import './Strings.sol';
import './IAiCasso.sol';
import './IERC721Enumerable.sol';
import './IAiCassoNFTStaking.sol';


contract AiCassoStakingRecovery is Ownable {
    using Strings for uint256;


    address public immutable AiCassoNFT;
    address public immutable AiCassoNFTStaking;


    mapping(address => uint256) private recovered;

    constructor (
        address _AiCassoNFT,
        address _AiCassoNFTStaking
    ) {
        require( _AiCassoNFT != address(0) );
        AiCassoNFT = _AiCassoNFT;
        require( _AiCassoNFTStaking != address(0) );
        AiCassoNFTStaking = _AiCassoNFTStaking;
    }


    function recovery(uint256 numberOfTokens) external {
        require(numberOfTokens <= IAiCassoNFTStaking( AiCassoNFTStaking ).balanceOf(msg.sender));
        uint256 _available = IAiCassoNFTStaking( AiCassoNFTStaking ).balanceOf(msg.sender) - recovered[msg.sender];
        require(numberOfTokens <= _available);
        require(address(this).balance >= (numberOfTokens * 0.01 ether));

        recovered[msg.sender] += numberOfTokens;

        if (numberOfTokens <= 10) {
            IAiCasso( AiCassoNFT ).purchase{value: numberOfTokens * 0.01 ether}(numberOfTokens);
        } else {

            uint256 loops = numberOfTokens / 10;
            uint256 other = (loops * 10) - numberOfTokens;

            for (uint256 i = 0; i < loops; i++) {
                IAiCasso( AiCassoNFT ).purchase{value: 0.10 ether}(10);
            }

            if (other > 0) {
                IAiCasso( AiCassoNFT ).purchase{value: other * 0.01 ether}(other);
            }

        }


        uint[] memory _tokenIds = new uint[](numberOfTokens);
        for (uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIds[i] = IERC721Enumerable( AiCassoNFT ).tokenOfOwnerByIndex(msg.sender, i);
        }

        for (uint256 i = 0; i < numberOfTokens; i++) {
            IERC721Enumerable( AiCassoNFT ).safeTransferFrom(address(this), msg.sender, _tokenIds[i]);
        }

    }

    function deposit() external onlyOwner payable { }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function available(address user) external view returns (uint256) {
        return IAiCassoNFTStaking( AiCassoNFTStaking ).balanceOf(user) - recovered[user];
    }
}