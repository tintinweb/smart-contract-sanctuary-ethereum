// SPDX-License-Identifier: MIT
pragma solidity ^0.8.12;

import "./ERC1155.sol";
import "./SpitToken.sol";
import "./ERC721.sol";
import "./FxBaseRootTunnel.sol";
import "./Ownable.sol";

/**
   __ _                                               
  / /| | __ _ _ __ ___   __ _/\   /\___ _ __ ___  ___ 
 / / | |/ _` | '_ ` _ \ / _` \ \ / / _ \ '__/ __|/ _ \
/ /__| | (_| | | | | | | (_| |\ V /  __/ |  \__ \  __/
\____/_|\__,_|_| |_| |_|\__,_| \_/ \___|_|  |___/\___|

**/

/// @title Llama Zoo
/// @author delta devs (https://twitter.com/deltadevelopers)

contract LlamaZoo is FxBaseRootTunnel, Ownable {
    /*///////////////////////////////////////////////////////////////
                            STORAGE
    //////////////////////////////////////////////////////////////*/

    /// @notice ERC721 instance of the PixelatedLlama contract.
    ERC721 public pixellatedLlamaContract;
    /// @notice ERC721 instance of the LlamaDraws contract.
    ERC721 public llamaDrawsContract;
    /// @notice ERC1155 instance of the StakingBoost contract.
    ERC1155 public boostContract;
    /// @notice ERC1155 instance of the Pixlet contract.
    ERC1155 public pixletContract;

    struct Staker {
        uint256[] stakedLlamas;
        uint256 stakedPixletCanvas;
        uint256 stakedLlamaDraws;
        uint128 stakedSilverBoosts;
        uint128 stakedGoldBoosts;
    }

    mapping(address => Staker) public userInfo;

    bool public stakingPaused;

    /*///////////////////////////////////////////////////////////////
                            CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/
    constructor(
        address checkpointManager,
        address fxRoot,
        address _pixellatedLlamaContract,
        address _llamaDrawsContract,
        address _boostContract,
        address _pixletContract
    ) FxBaseRootTunnel(checkpointManager, fxRoot) {
        pixellatedLlamaContract = ERC721(_pixellatedLlamaContract);
        llamaDrawsContract = ERC721(_llamaDrawsContract);
        boostContract = ERC1155(_boostContract);
        pixletContract = ERC1155(_pixletContract);
    }

    /*///////////////////////////////////////////////////////////////
                        CONTRACT SETTERS
    //////////////////////////////////////////////////////////////*/

    /// @notice Set the contract addresses for all contract instances.
    /// @param _pixellatedLlamaContract The contract address of PixellatedLlama.
    /// @param _llamaDrawsContract The contract address of LlamaDraws.
    /// @param _boostContract The contract address of RewardBooster.
    /// @param _pixletContract The contract address of the Pixlet contract.
    function setContractAddresses(
        address _pixellatedLlamaContract,
        address _llamaDrawsContract,
        address _boostContract,
        address _pixletContract
    ) public onlyOwner {
        pixellatedLlamaContract = ERC721(_pixellatedLlamaContract);
        llamaDrawsContract = ERC721(_llamaDrawsContract);
        boostContract = ERC1155(_boostContract);
        pixletContract = ERC1155(_pixletContract);
    }

    /// @notice Pauses staking and unstaking, for emergency purposes
    /// @dev If we have to migrate because of Polygon instability or state sync issues, this will save us
    function setStakingPaused(bool paused) public onlyOwner {
        stakingPaused = paused;
    }

    /// @notice For collab.land to give a role based on staking status
    function balanceOf(address owner) public view returns (uint256) {
        uint[] memory llamas = userInfo[owner].stakedLlamas;
        if(llamas.length == 0) return 0;
        for (uint256 i = 0; i < llamas.length; i++) {
           if(llamas[i] < 500) return 1;
        }
        return 2;
    }

    /// @dev Using the mapping directly wasn't returning the array, so we made this helper fuction.
    function getStakedTokens(address user)
        public
        view
        returns (
            uint256[] memory llamas,
            uint256 pixletCanvas,
            uint256 llamaDraws,
            uint128 silverBoosts,
            uint128 goldBoosts
        )
    {
        Staker memory staker = userInfo[user];
        return (
            staker.stakedLlamas,
            staker.stakedPixletCanvas,
            staker.stakedLlamaDraws,
            staker.stakedSilverBoosts,
            staker.stakedGoldBoosts
        );
    }

    /*///////////////////////////////////////////////////////////////
                        UTILITY STAKING LOGIC
    //////////////////////////////////////////////////////////////*/

    function bulkStake(
        uint256[] memory llamas,
        uint128 silverBoosts,
        uint128 goldBoosts,
        uint256 pixletStudio,
        uint256 llamaDraws
    ) public {
        if (llamas.length > 0) stakeMultipleLlamas(llamas);
        stakeBoosts(silverBoosts, goldBoosts);
        if (pixletStudio != 0) stakePixletCanvas(pixletStudio);
        if (llamaDraws != 0) stakeLlamaDraws(llamaDraws);
    }

    function bulkUnstake(
        uint256[] memory llamas,
        uint128 silverBoosts,
        uint128 goldBoosts,
        bool pixletStudio,
        bool llamaDraws
    ) public {
        if (llamas.length > 0) unstakeMultipleLlamas(llamas);
        unstakeBoosts(silverBoosts, goldBoosts);
        if (pixletStudio) unstakePixletCanvas();
        if (llamaDraws) unstakeLlamaDraws();
    }

    function stakeMultipleLlamas(uint256[] memory tokenIds) public {
        require(!stakingPaused, "Staking is currently paused.");
        uint256 animatedCount = 0;
        Staker storage staker = userInfo[msg.sender];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            if (tokenIds[i] < 500) ++animatedCount;
            staker.stakedLlamas.push(tokenIds[i]);
            pixellatedLlamaContract.transferFrom(
                msg.sender,
                address(this),
                tokenIds[i]
            );
        }
        if (animatedCount > 0) {
            _sendMessageToChild(
                abi.encode(
                    msg.sender,
                    uint256(TokenType.AnimatedLlama),
                    animatedCount,
                    true
                )
            );
        }
        if ((tokenIds.length - animatedCount) > 0) {
            _sendMessageToChild(
                abi.encode(
                    msg.sender,
                    uint256(TokenType.StaticLlama),
                    tokenIds.length - animatedCount,
                    true
                )
            );
        }
    }

    function unstakeMultipleLlamas(uint256[] memory tokenIds) public {
        require(!stakingPaused, "Staking is currently paused.");
        uint256 animatedCount = 0;
        Staker storage staker = userInfo[msg.sender];
        for (uint256 i = 0; i < tokenIds.length; i++) {
            uint256 tokenId = tokenIds[i];
            require(containsElement(staker.stakedLlamas, tokenId), "You do not own this llama.");
            if (tokenId < 500) ++animatedCount;
            pixellatedLlamaContract.transferFrom(
                address(this),
                msg.sender,
                tokenId
            );

            uint256[] memory stakedLlamas = staker.stakedLlamas;
            uint256 index;
            for (uint256 j; j < stakedLlamas.length; j++) {
                if (stakedLlamas[j] == tokenId) index = j;
            }
            if (stakedLlamas[index] == tokenId) {
                staker.stakedLlamas[index] = stakedLlamas[
                    staker.stakedLlamas.length - 1
                ];
                staker.stakedLlamas.pop();
            }
        }

        if (animatedCount > 0) {
            _sendMessageToChild(
                abi.encode(
                    msg.sender,
                    uint256(TokenType.AnimatedLlama),
                    animatedCount,
                    false
                )
            );
        }
        if ((tokenIds.length - animatedCount) > 0) {
            _sendMessageToChild(
                abi.encode(
                    msg.sender,
                    uint256(TokenType.StaticLlama),
                    tokenIds.length - animatedCount,
                    false
                )
            );
        }
    }

    /// @notice Stake a LlamaVerse llama.
    /// @param tokenId The tokenId of the llama to stake
    function stakeLlama(uint256 tokenId) external {
        require(!stakingPaused, "Staking is currently paused.");
        bool animated = tokenId < 500;
        Staker storage staker = userInfo[msg.sender];
        staker.stakedLlamas.push(tokenId);
        pixellatedLlamaContract.transferFrom(
            msg.sender,
            address(this),
            tokenId
        );
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(
                    animated ? TokenType.AnimatedLlama : TokenType.StaticLlama
                ),
                1,
                true
            )
        );
    }

    /// @notice Unstake a LlamaVerse llama.
    /// @param tokenId The tokenId of the llama to unstake
    function unstakeLlama(uint256 tokenId) external {
        require(!stakingPaused, "Staking is currently paused.");
        bool animated = tokenId < 500;
        Staker storage staker = userInfo[msg.sender];
        require(containsElement(staker.stakedLlamas, tokenId), "You do not own this llama.");

        pixellatedLlamaContract.transferFrom(
            address(this),
            msg.sender,
            tokenId
        );

        uint256[] memory stakedLlamas = staker.stakedLlamas;
        uint256 index;
        for (uint256 i; i < stakedLlamas.length; i++) {
            if (stakedLlamas[i] == tokenId) index = i;
        }
        if (stakedLlamas[index] == tokenId) {
            _sendMessageToChild(
                abi.encode(
                    msg.sender,
                    uint256(
                        animated
                            ? TokenType.AnimatedLlama
                            : TokenType.StaticLlama
                    ),
                    1,
                    false
                )
            );
            staker.stakedLlamas[index] = stakedLlamas[
                staker.stakedLlamas.length - 1
            ];
            staker.stakedLlamas.pop();
        }
    }

    /// @notice Stake silver boosts.
    /// @param amount The amount of boosts to stake.
    function stakeSilverBoosts(uint128 amount) public {
        require(!stakingPaused, "Staking is currently paused.");
        require(amount != 0, "Staking 0 is not allowed.");

        userInfo[msg.sender].stakedSilverBoosts += amount;
        boostContract.safeTransferFrom(
            msg.sender,
            address(this),
            2,
            amount,
            ""
        );
        _sendMessageToChild(
            abi.encode(msg.sender, uint256(TokenType.SilverBoost), amount, true)
        );
    }

    /// @notice Unstake silver boosts.
    /// @param amount The amount of boosts to unstake.
    function unstakeSilverBoosts(uint128 amount) public {
        require(!stakingPaused, "Staking is currently paused.");
        require(amount != 0, "Unstaking 0 is not allowed.");

        userInfo[msg.sender].stakedSilverBoosts -= amount;
        boostContract.safeTransferFrom(
            address(this),
            msg.sender,
            2,
            amount,
            ""
        );
        _sendMessageToChild(
            abi.encode(
                msg.sender,
                uint256(TokenType.SilverBoost),
                amount,
                false
            )
        );
    }

    /// @notice Stake gold boosts with the requested tokenID.
    /// @param amount The amount of boosts to stake.
    function stakeGoldBoosts(uint128 amount) public {
        require(!stakingPaused, "Staking is currently paused.");
        require(amount != 0, "Staking 0 is not allowed.");
        userInfo[msg.sender].stakedGoldBoosts += amount;
        boostContract.safeTransferFrom(
            msg.sender,
            address(this),
            1,
            amount,
            ""
        );
        _sendMessageToChild(
            abi.encode(msg.sender, uint256(TokenType.GoldBoost), amount, true)
        );
    }

    /// @notice Unstake gold boosts with the requested tokenID.
    /// @param amount The amount of boosts to stake.
    function unstakeGoldBoosts(uint128 amount) public {
        require(!stakingPaused, "Staking is currently paused.");
        require(amount != 0, "Unstaking 0 is not allowed.");
        userInfo[msg.sender].stakedGoldBoosts -= amount;
        boostContract.safeTransferFrom(
            address(this),
            msg.sender,
            1,
            amount,
            ""
        );
        _sendMessageToChild(
            abi.encode(msg.sender, uint256(TokenType.GoldBoost), amount, false)
        );
    }

    function stakeBoosts(uint128 silverAmount, uint128 goldAmount) public {
        if (silverAmount != 0) stakeSilverBoosts(silverAmount);
        if (goldAmount != 0) stakeGoldBoosts(goldAmount);
    }

    function unstakeBoosts(uint128 silverAmount, uint128 goldAmount) public {
        if (silverAmount != 0) unstakeSilverBoosts(silverAmount);
        if (goldAmount != 0) unstakeGoldBoosts(goldAmount);
    }

    /// @notice Stake a Pixlet Canvas with the requested tokenID.
    /// @param tokenId The token ID of the pixlet canvas to stake.
    function stakePixletCanvas(uint256 tokenId) public {
        require(!stakingPaused, "Staking is currently paused.");
        require(
            userInfo[msg.sender].stakedPixletCanvas == 0,
            "You already have a pixlet canvas staked."
        );

        userInfo[msg.sender].stakedPixletCanvas = tokenId;
        pixletContract.safeTransferFrom(
            msg.sender,
            address(this),
            tokenId,
            1,
            ""
        );

        _sendMessageToChild(
            abi.encode(msg.sender, uint256(TokenType.PixletCanvas), 1, true)
        );
    }

    /// @notice Unstake your Pixlet Canvas.
    function unstakePixletCanvas() public {
        require(!stakingPaused, "Staking is currently paused.");
        require(
            userInfo[msg.sender].stakedPixletCanvas != 0,
            "You do not have a pixlet canvas staked."
        );

        pixletContract.safeTransferFrom(
            address(this),
            msg.sender,
            userInfo[msg.sender].stakedPixletCanvas,
            1,
            ""
        );
        userInfo[msg.sender].stakedPixletCanvas = 0;

        _sendMessageToChild(
            abi.encode(msg.sender, uint256(TokenType.PixletCanvas), 1, false)
        );
    }

    /// @notice Stake a Llamadraws.
    /// @param tokenId The token ID of the llamadraws to stake.
    function stakeLlamaDraws(uint256 tokenId) public {
        require(!stakingPaused, "Staking is currently paused.");
        require(
            userInfo[msg.sender].stakedLlamaDraws == 0,
            "You already have a llamadraws staked."
        );

        userInfo[msg.sender].stakedLlamaDraws = tokenId;
        llamaDrawsContract.transferFrom(msg.sender, address(this), tokenId);

        _sendMessageToChild(
            abi.encode(msg.sender, uint256(TokenType.LlamaDraws), 1, true)
        );
    }

    /// @notice Unstake your Llamadraws.
    function unstakeLlamaDraws() public {
        require(!stakingPaused, "Staking is currently paused.");
        require(
            userInfo[msg.sender].stakedLlamaDraws != 0,
            "You do not have a llamadraws staked."
        );

        llamaDrawsContract.transferFrom(
            address(this),
            msg.sender,
            userInfo[msg.sender].stakedLlamaDraws
        );
        userInfo[msg.sender].stakedLlamaDraws = 0;

        _sendMessageToChild(
            abi.encode(msg.sender, uint256(TokenType.LlamaDraws), 1, false)
        );
    }

    function _processMessageFromChild(bytes memory message) internal override {
        // We don't need a message from child
    }

    function containsElement(uint[] memory elements, uint tokenId) internal returns (bool) {
        for (uint256 i = 0; i < elements.length; i++) {
           if(elements[i] == tokenId) return true;
        }
        return false;
    }


    /*///////////////////////////////////////////////////////////////
                        ERC ON RECEIVED LOGIC
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }

    /**
     * @notice Handle the receipt of a single ERC1155 token type.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeTransferFrom` after the balance has been updated.
     * This function MAY throw to revert and reject the transfer.
     * Return of other amount than the magic value MUST result in the transaction being reverted.
     * Note: The token contract address is always the message sender.
     * @param operator  The address which called the `safeTransferFrom` function.
     * @param from      The address which previously owned the token.
     * @param id        The id of the token being transferred.
     * @param amount    The amount of tokens being transferred.
     * @param data      Additional data with no specified format.
     * @return           `bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"))`.
     */
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155Received.selector;
    }

    /**
     * @notice Handle the receipt of multiple ERC1155 token types.
     * @dev An ERC1155-compliant smart contract MUST call this function on the token recipient contract, at the end of a `safeBatchTransferFrom` after the balances have been updated.
     * This function MAY throw to revert and reject the transfer.
     * Return of other amount than the magic value WILL result in the transaction being reverted.
     * Note: The token contract address is always the message sender.
     * @param operator  The address which called the `safeBatchTransferFrom` function.
     * @param from      The address which previously owned the token.
     * @param ids       An array containing ids of each token being transferred.
     * @param amounts   An array containing amounts of each token being transferred.
     * @param data      Additional data with no specified format.
     * @return           `bytes4(keccak256("onERC1155BatchReceived(address,address,uint256[],uint256[],bytes)"))`.
     */
    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata amounts,
        bytes calldata data
    ) external returns (bytes4) {
        return ERC1155TokenReceiver.onERC1155BatchReceived.selector;
    }
}