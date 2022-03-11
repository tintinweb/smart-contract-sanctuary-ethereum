// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import './Ownable.sol';
import './Strings.sol';
import './IAiCasso.sol';
import './IERC721Enumerable.sol';
import './IAiCassoNFTStaking.sol';
import './ERC721Receiver.sol';


contract AiCassoStakingRecovery is Ownable, ERC721Receiver {
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
        require(numberOfTokens > 0);
        uint256 _balance = IAiCassoNFTStaking( AiCassoNFTStaking ).balanceOf(msg.sender);
        require(numberOfTokens <= _balance);
        uint256 _available = _balance - recovered[msg.sender];
        require(numberOfTokens <= _available, "you dont have available nft on stake contract");
        require(address(this).balance >= (numberOfTokens * 0.01 ether), "need more avax on balance recovery contract");

        recovered[msg.sender] += numberOfTokens;

        if (numberOfTokens <= 10) {
            IAiCasso( AiCassoNFT ).purchase{value: numberOfTokens * 0.01 ether}(numberOfTokens);
        } else {

            uint256 loops = numberOfTokens / 10;
            uint256 other = numberOfTokens - (loops * 10);

            for (uint256 i = 0; i < loops; i++) {
                IAiCasso( AiCassoNFT ).purchase{value: 0.10 ether}(10);
            }

            if (other > 0) {
                IAiCasso( AiCassoNFT ).purchase{value: other * 0.01 ether}(other);
            }
        }

        require(IERC721( AiCassoNFT ).balanceOf(address(this)) >= numberOfTokens, "check balance fail");

        for (uint256 i = 0; i < numberOfTokens; i++) {
            IERC721( AiCassoNFT ).transferFrom(
                address(this),
                msg.sender,
                IERC721Enumerable( AiCassoNFT ).tokenOfOwnerByIndex(address(this), (IERC721( AiCassoNFT ).balanceOf(address(this)) - 1))
            );
        }

//        uint[] memory _tokenIds = new uint[](numberOfTokens);
//        for (uint256 i = 0; i < numberOfTokens; i++) {
//            _tokenIds[i] = IERC721Enumerable( AiCassoNFT ).tokenOfOwnerByIndex(address(this), i);
//        }
//
//        for (uint256 i = 0; i < numberOfTokens; i++) {
//            IERC721( AiCassoNFT ).transferFrom(address(this), msg.sender, _tokenIds[i]);
//        }

    }

    function deposit() external onlyOwner payable { }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function available(address user) external view returns (uint256) {
        return IAiCassoNFTStaking( AiCassoNFTStaking ).balanceOf(user) - recovered[user];
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external override returns (bytes4) {
        return _ERC721_RECEIVED;
    }
}