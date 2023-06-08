// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

import "./EnumerableSet.sol";
import "./Counters.sol";
import "./IERC1155.sol";
import "./IERC721.sol";
import "./IERC721Receiver.sol";
import "./TransferHelper.sol";
import "./SafeMath.sol";
import "./IChallenge.sol";
import "./IERC20.sol";
import "./Initializable.sol";
import "./UUPSUpgradeable.sol";
import "./IVRFConsumerBase.sol";
import "./AccessControlUpgradeable.sol";
import "./TermData.sol";

contract Gacha is
    Initializable,
    IERC721Receiver,
    AccessControlUpgradeable,
    UUPSUpgradeable,
    TermData
{
    // Import necessary libraries
    // EnumerableSet for managing sets of addresses and uints
    using EnumerableSet for EnumerableSet.AddressSet;
    // Counters for managing the count of tokens
    using Counters for Counters.Counter;
    // SafeMath for safe arithmetic operations to prevent integer overflow or underflow
    using SafeMath for uint256;

    // Mapping to keep track if the daily result has been sent with a specific gacha contract
    mapping(address => mapping(address => bool)) public isSendDailyResultWithGacha;

    // Array to store IDs of all tokens
    uint256[] private listIdToken;

    // Set of addresses for required balance NFTs
    EnumerableSet.AddressSet private requireBalanceNftAddress;

    // Mapping to store whether an NFT is a required balance NFT
    mapping(address => bool) public typeNfts;

    // Boolean to check if the default gacha contract is being used
    bool public isDefaultGachaContract;

    // Name of the gacha game
    string public gachaName;

    // Sponsor of the gacha game
    string public gachaSponsor;

    // Boolean to check if the gacha game is closed
    bool public iscloseGacha;

    // Address of the wallet where returned NFTs are transferred to
    address public returnedNFTWallet;

    // Mapping to keep track of the number of times a gacha contract is activated
    mapping(address => mapping(uint256 => uint256)) public countTimeActiveGacha;

    // This address points to the VRFConsumerBase contract for RANDOM_MUTIPLE_TIME type
    address public VRFConsumerBaseMultipleTime;

    // This address points to the VRFConsumerBase contract for RANDOM_ONLY_TIME type
    address public VRFConsumerBaseOnlyTime;

    // The address of the contract containing the RandomNumberClassic interface, which is used to call the getRandomNumber function
    address public randomClassicAddress;

    // A public variable to store the address of the wallet that will receive the funds
    address public receiveAdminWallet;

    // Define the role that can upgrade the contract
    bytes32 public constant UPGRADER_ROLE = keccak256("UPGRADER_ROLE");

    // Define the role that can update gacha reward
    bytes32 public constant UPDATER_REWARDS_ROLE = keccak256("UPDATER_REWARDS_ROLE");

    // Define the role that can update contract activities
    bytes32 public constant UPDATER_ACTIVITIES_ROLE = keccak256("UPDATER_ACTIVITIES_ROLE");

    // Define the role that can close gạcha
    bytes32 public constant CLOSE_GACHA_ROLE = keccak256("CLOSE_GACHA_ROLE");

    /**
     * @dev Initialize the contract with ChallengeInfo and other necessary data.
     * @param _challengeInfo Challenge information including the target steps, duration, etc.
     * @param _requireBalanceNftAddress An array of addresses for the required balance NFTs for participating in the challenge.
     * @param _typeNfts An array of boolean values indicating whether the NFT at the corresponding index in _requireBalanceNftAddress is a Type 1 or Type 2 NFT.
     * @param _rateOfLost The rate at which rewards decrease with each passing day without submitting step count data.
     * @param _isDefaultGachaContract A boolean value indicating whether the contract is the default Gacha contract or not.
     * @param _gachaName The name of the Gacha contract.
     * @param _gachaSponsor The sponsor of the Gacha contract.
     */
    function initialize(
        ChallengeInfo memory _challengeInfo,
        address[] memory _requireBalanceNftAddress,
        bool[] memory _typeNfts,
        uint256 _rateOfLost,
        bool _isDefaultGachaContract,
        TypeRandomReward _typeRandomReward,
        TimeRandomReward _timeRandomReward,
        address _VRFConsumerBaseMultipleTime,
        address _VRFConsumerBaseOnlyTime,
        address[] memory receiveWallet,
        string memory _gachaName,
        string memory _gachaSponsor
    ) external initializer {
        // Call the parent contract's initializer.
        __UUPSUpgradeable_init();
        __AccessControl_init();

        // Set the required balance NFT addresses and their corresponding types
        require(
            _requireBalanceNftAddress.length == _typeNfts.length,
            "INVALID REQUIRE BALANCE NFT ADDRESS."
        );
        challengeInfo = _challengeInfo;
        for (uint256 i = 0; i < _requireBalanceNftAddress.length; i++) {
            requireBalanceNftAddress.add(_requireBalanceNftAddress[i]);
            typeNfts[_requireBalanceNftAddress[i]] = _typeNfts[i];
        }

        // Set the default gacha contract flag
        isDefaultGachaContract = _isDefaultGachaContract;

        // Set the name of the gacha
        gachaName = _gachaName;

        // Set the sponsor of the gacha
        gachaSponsor = _gachaSponsor;

        // Grant roles to specified addresses
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(UPGRADER_ROLE, msg.sender);
        _grantRole(UPDATER_REWARDS_ROLE, msg.sender);
        _grantRole(UPDATER_ACTIVITIES_ROLE, msg.sender);
        _grantRole(CLOSE_GACHA_ROLE, msg.sender);

        // Set the rate of lost rewards for reward
        rewardTokens[0].unlockRate = _rateOfLost;

        // Set the type of random reward to be used
        typeRandomReward = _typeRandomReward;

        // Set the type of time-based random reward to be used
        timeRandomReward = _timeRandomReward;

        // Assigns new values to VRFConsumerBaseMultipleTime and VRFConsumerBaseOnlyTime
        VRFConsumerBaseMultipleTime = _VRFConsumerBaseMultipleTime;
        VRFConsumerBaseOnlyTime = _VRFConsumerBaseOnlyTime;

        // Set the receiveWallet wallet address
        returnedNFTWallet = receiveWallet[0];
        receiveAdminWallet = receiveWallet[1];
    }

    /**
     * @dev function to be able to accept native currency of the network.
     * @dev Fallback function to receive ETH payments.
     */
    receive() external payable {}

    /**
     * @dev Function to generate random rewards for the user who has completed the daily step challenge.
     * @param _challengeAddress The address of the daily step challenge contract.
     * @return A boolean value indicating whether the function was successful or not.
     */
    function randomRewards(
        address _challengeAddress,
        uint256[] memory _dataStep
    ) external returns (bool) {
        // Modifier to restrict access to only admins
        require(
            !isSendDailyResultWithGacha[msg.sender][_challengeAddress],
            "ALREADY SEND DAILY RESULT WITH GACHA CONTRACT."
        );

        // Modifier only challenge address can call function
        require(
            _challengeAddress == msg.sender,
            "ONLY CHALLENGE CONTRACT CAN CALL SEND DAILY RESULT WITH GACHA."
        );

        // Get the address of the challenger from the challenge contract
        address challengerAddress = IChallenge(_challengeAddress).challenger();

        // Get the address of the challenger from the challenge contract
        uint256 currentDate = block.timestamp.div(86400);

        // Check if the number of times the challenger has activated gacha on the current date has not exceeded the limit set in the challengeInfo
        require(
            countTimeActiveGacha[challengerAddress][currentDate] <
                challengeInfo.timeLimitActiveGacha,
            "THE NUMBER OF ACTIVE GACHA TIMES IN A DAY HAS EXCEEDED THE LIMIT."
        );

        // Increase the count of active gacha times for the current date of the challenger
        countTimeActiveGacha[challengerAddress][
            currentDate
        ] = countTimeActiveGacha[challengerAddress][currentDate].add(1);

        // Initialize a new UserInfor object for the challenger
        UserInfor memory newUserInfor;
        userInfor[challengerAddress] = newUserInfor;

        // Set a flag to indicate whether the challenger won the prize or not
        bool isWonThePrize = false;

        /**
         * Check if the challenger has the required balance NFTs to participate in the gacha
         * and the NFT type is in the list of required NFT types
         * If not, return false and the gacha result will be skipped
         * Otherwise, continue to the next step
         */
        if (checkRequireBalanceNft(_challengeAddress, _dataStep)) {
            // Generate a random index for the reward
            uint256 randomIndexReward = checkAbilityReward();

            /**
             * If the random index reward is not equal to 0 (which means the user has the ability to win a reward),
             * then the function proceeds to the next steps to select and distribute the reward.
             */
            if (randomIndexReward != 0) {
                // Get the index of the selected reward token
                uint256 indexTokenReward;

                // Get the selected reward token's information from the rewardTokens mapping
                RewardToken memory currentRewardToken = rewardTokens[
                    randomIndexReward
                ];

                if(rewardTokens[randomIndexReward].rewardActivationCount < rewardTokens[randomIndexReward].maxNumberAllowed) {
                    // Get the address of the selected reward token
                    address currentTokenAddress = currentRewardToken.addressToken;

                    // Check if the current reward token is an ERC20 token
                    if (currentRewardToken.typeToken == TypeToken.ERC20) {
                        // Transfer the ERC20 token reward to the challenger's address
                        TransferHelper.safeTransfer(
                            currentTokenAddress,
                            challengerAddress,
                            currentRewardToken.rewardValue
                        );
                    }

                    // If the reward token type is ERC721
                    if (currentRewardToken.typeToken == TypeToken.ERC721) {
                        // Get the next available token ID to mint
                        uint256 currentIndexNFT = IChallenge(currentTokenAddress)
                            .nextTokenIdToMint();

                        // If the reward is to mint a new NFT
                        if (currentRewardToken.isMintNft) {
                            // Mint a new NFT
                            IChallenge(
                                IChallenge(_challengeAddress).erc721Address(0)
                            ).safeMintNFT721Heper(
                                    currentTokenAddress,
                                    challengerAddress
                                );
                            // Set the reward index to the newly minted token ID
                            indexTokenReward = currentIndexNFT;
                        } else {
                            /**
                            * If the reward is to transfer an existing NFT
                            * Loop through all available token IDs
                            */
                            for (uint256 j = 0; j < currentIndexNFT; j++) {
                                // If the token is owned by the Gacha contract
                                if (
                                    IChallenge(currentTokenAddress).ownerOf(j) ==
                                    address(this)
                                ) {
                                    TransferHelper.safeTransferFrom(
                                        currentTokenAddress,
                                        address(this),
                                        challengerAddress,
                                        j
                                    );
                                    // Set the reward index to the transferred token ID
                                    indexTokenReward = j;
                                    break;
                                }
                            }
                        }
                    }

                    // Checks if the token is of type ERC1155
                    if (currentRewardToken.typeToken == TypeToken.ERC1155) {
                        // If the token is to be minted, mint it using the safeMintNFT1155Heper function in the challenge's ERC721 contract
                        if (currentRewardToken.isMintNft) {
                            IChallenge(
                                IChallenge(_challengeAddress).erc721Address(0)
                            ).safeMintNFT1155Heper(
                                    currentTokenAddress, // The address of the ERC1155 token contract
                                    challengerAddress, // The address of the challenger who won the reward
                                    currentRewardToken.indexToken, // The index of the token to be minted
                                    currentRewardToken.rewardValue // The reward value of the token
                                );
                        } else {
                            // If the token is not to be minted, transfer it from the contract address to the challenger's address using the safeTransferNFT1155 function
                            TransferHelper.safeTransferNFT1155(
                                currentTokenAddress, // The address of the ERC1155 token contract
                                address(this), // The address of the contract
                                challengerAddress, // The address of the challenger who won the reward
                                currentRewardToken.indexToken, // The index of the token to be transferred
                                currentRewardToken.rewardValue, // The reward value of the token
                                "ChallengeApp" // The data to be passed along with the transaction
                            );
                        }

                        // Set the index of the token reward to the current reward token's index
                        indexTokenReward = currentRewardToken.indexToken;
                    }

                    // Check if the reward token is of type native token (ETH)
                    // Transfer the reward value in ETH to the challenger address
                    if (currentRewardToken.typeToken == TypeToken.NATIVE_TOKEN) {
                        TransferHelper.saveTransferEth(
                            payable(challengerAddress),
                            currentRewardToken.rewardValue
                        );
                    }

                    // Set isWonThePrize to true to indicate that the user has won a prize
                    isWonThePrize = true;

                    // Determine the name of the token, depending on whether it's a native token or an ERC20/ERC721/ERC1155 token
                    string memory tokenName;
                    if (currentRewardToken.typeToken == TypeToken.NATIVE_TOKEN) {
                        tokenName = "Native Token";
                    } else {
                        tokenName = IChallenge(currentTokenAddress).name();
                    }

                    // Store the user's information into the userInfor mapping
                    userInfor[challengerAddress] = UserInfor(
                        true, // Set the user's flag to indicate that they have won the challenge
                        randomIndexReward, // Store the index of the reward token that the user has won
                        indexTokenReward, // Store the index of the specific token within the ERC721/ERC1155 contract that the user has won (if applicable)
                        currentTokenAddress, // Store the address of the token that the user has won
                        currentRewardToken.rewardValue, // Store the amount of the token that the user has won
                        tokenName // Store the name of the token that the user has won
                    );
                    
                    // Increment the max number allowed for the selected reward token
                    rewardTokens[randomIndexReward].rewardActivationCount = rewardTokens[randomIndexReward].rewardActivationCount.add(1);

                    if(rewardTokens[randomIndexReward].rewardActivationCount == rewardTokens[randomIndexReward].maxNumberAllowed) {
                        rewardTokens[0].unlockRate = rewardTokens[0].unlockRate.add(rewardTokens[randomIndexReward].unlockRate);
                        rewardTokens[randomIndexReward].unlockRate = 0;
                    }
                }
            }
        }

        // If the user won the prize and the challenge is finished, mark the user as having received the daily result with gacha for this challenge
        if (isWonThePrize && IChallenge(_challengeAddress).isFinished()) {
            isSendDailyResultWithGacha[msg.sender][_challengeAddress] = true;
        }

        // Emit an event indicating that the daily result with gacha has been sent to the user
        emit SendDailyResultGacha(msg.sender, address(this));

        // Return whether the user won the prize or not
        return isWonThePrize;
    }

    /**
     * This function is used by the admin to close the current gacha.
     * It is only callable by the admin address. Once the gacha is closed,
     * users will not be able to participate in it anymore.
     * After closing the gacha, the admin can distribute the prizes to the winners.
     */
    function closeGacha() external onlyRole(CLOSE_GACHA_ROLE) {
        // Make sure that the gacha is not already closed
        require(!iscloseGacha, "GACHA ALREADY CLOSE.");

        // Make sure that the address for returned NFT wallet is set up
        require(
            returnedNFTWallet != address(0),
            "RETURNED NFT WALLET NOT YET SET UP."
        );

        // Loop through each token ID in the list of token IDs
        for (uint256 i = 0; i < listIdToken.length; i++) {
            // Get the reward token associated with the current token ID
            RewardToken memory currentRewardToken = rewardTokens[
                listIdToken[i]
            ];

            // Get the address of the token for the current reward token
            address tokenAddress = currentRewardToken.addressToken;

            // Check if the current reward token is not an ERC1155 mintable NFT, execute the following block of code if true
            if (!currentRewardToken.isMintNft) {
                // Check if currentRewardToken is not an ERC1155 token
                if (currentRewardToken.typeToken != TypeToken.ERC1155) {
                    // Check if currentRewardToken is a native token (ETH)
                    if (
                        currentRewardToken.typeToken == TypeToken.NATIVE_TOKEN
                    ) {
                        // Transfer ETH to the returnedNFTWallet
                        TransferHelper.saveTransferEth(
                            payable(returnedNFTWallet),
                            address(this).balance
                        );
                    } else {
                        // Get the balance of tokens held by this contract
                        uint256 balanceToken = IERC20(tokenAddress).balanceOf(
                            address(this)
                        );

                        // Check if there are tokens held by this contract
                        if (balanceToken > 0) {
                            // Check if currentRewardToken is an ERC20 token
                            if (
                                currentRewardToken.typeToken == TypeToken.ERC20
                            ) {
                                // Transfer the ERC20 tokens to the returnedNFTWallet
                                TransferHelper.safeTransfer(
                                    tokenAddress,
                                    returnedNFTWallet,
                                    balanceToken
                                );
                            }

                            // Check if currentRewardToken is an ERC721 token
                            if (
                                currentRewardToken.typeToken == TypeToken.ERC721
                            ) {
                                // Get the next token ID to mint
                                uint256 currentIndexNFT = IChallenge(
                                    tokenAddress
                                ).nextTokenIdToMint();
                                // Loop through each token ID
                                for (uint256 j = 0; j < currentIndexNFT; j++) {
                                    // Check if the contract is the owner of the token
                                    if (
                                        IChallenge(tokenAddress).ownerOf(j) ==
                                        address(this)
                                    ) {
                                        // Transfer the ERC721 token to the returnedNFTWallet
                                        TransferHelper.safeTransferFrom(
                                            tokenAddress,
                                            address(this),
                                            returnedNFTWallet,
                                            j
                                        );
                                    }
                                }
                            }
                        }
                    }
                } else {
                    // Get the balance of the ERC1155 token with the given index token for the current
                    uint256 balanceTokenERC1155 = IERC1155(tokenAddress)
                        .balanceOf(
                            address(this),
                            currentRewardToken.indexToken
                        );

                    // Check if the balance is greater than 0
                    if (balanceTokenERC1155 > 0) {
                        // Safely transfer the ERC1155 token to the returned NFT wallet using the TransferHelper library
                        TransferHelper.safeTransferNFT1155(
                            tokenAddress,
                            address(this),
                            returnedNFTWallet,
                            currentRewardToken.indexToken,
                            balanceTokenERC1155,
                            "ChallengeApp"
                        );
                    }
                }
            }
        }

        // Set iscloseGacha flag to true
        iscloseGacha = true;

        // Emit an event to notify listeners that the challenge has been closed
        emit CloseGacha(msg.sender, address(this));
    }

    /**
     * @dev Function to add a new reward to the list of available rewards.
     * @param _addressToken The address of the token to be used as a reward.
     * @param _unlockRate The unlock rate for the reward.
     * @param _rewardValue The amount of the reward to be distributed.
     * @param _indexToken The index of the reward token.
     * @param _typeToken The type of token used as a reward.
     * @param _isMintNft A boolean indicating whether the reward is an NFT that should be minted.
     */
    function addNewReward(
        address _addressToken,
        uint256 _unlockRate,
        uint256 _rewardValue,
        uint256 _indexToken,
        TypeToken _typeToken,
        bool _isMintNft,
        uint256 _reciveOption,
        uint256 _maxNumberAllowed
    ) external onlyRole(UPDATER_REWARDS_ROLE) {
        /**
         * Revert the transaction if the token address is zero and the token type is not a native token,
         * or if the token address is not zero and the token type is a native token.
         */
        if (
            (_addressToken == address(0) &&
                _typeToken != TypeToken.NATIVE_TOKEN) ||
            (_addressToken != address(0) &&
                _typeToken == TypeToken.NATIVE_TOKEN)
        ) {
            revert("ZERO ADDRESS.");
        }

        // Require the reward value to be greater than zero.
        require(_rewardValue > 0, "INVALID REWARD VALUE.");

        // Find the first empty slot in the list of rewards.
        uint256 indexOfTokenReward = 0;

        for (uint256 i = 1; i <= listIdToken.length; i++) {
            if (
                rewardTokens[i].addressToken == address(0) &&
                rewardTokens[i].typeToken != TypeToken.NATIVE_TOKEN
            ) {
                indexOfTokenReward = i;
                break;
            }
        }

        // If there is no empty slot, increment the total number of rewards and use the new index.
        if (indexOfTokenReward == 0) {
            indexOfTokenReward = listIdToken.length.add(1);
        }

        // Add the new reward to the list of rewards and update the list of reward IDs.
        addReward(
            indexOfTokenReward,
            _addressToken,
            _unlockRate,
            _rewardValue,
            _indexToken,
            _typeToken,
            _isMintNft,
            _reciveOption,
            _maxNumberAllowed
        );
        listIdToken.push(indexOfTokenReward);

        // Emit an event to notify listeners that a new reward has been added.
        emit AddNewReward(
            _addressToken,
            _unlockRate,
            _typeToken,
            address(this)
        );
    }

    /**
     * @dev Function to delete a token reward by its index.
     * @param _indexOfTokenReward Index of the token reward to be deleted.
     */
    function deleteReward(
        uint256 _indexOfTokenReward
    ) external onlyRole(UPDATER_REWARDS_ROLE) {
        // Loop through the list of token IDs to check if the given index of token reward exists
        bool isExistIndexToken = false;
        for (uint256 i = 0; i < listIdToken.length; i++) {
            if (_indexOfTokenReward == listIdToken[i]) {
                isExistIndexToken = true;
                break;
            }
        }

        // statement to ensure that the specified index of the reward token exists in the list of reward tokens
        require(isExistIndexToken, "INDEX OF TOKEN REWARD NOT EXIST.");

        // Delete the reward token from the rewardTokens mapping
        delete rewardTokens[_indexOfTokenReward];

        /**
         * Loop through the list of reward token IDs and find the index of the reward token to be deleted
         * Then replace the deleted token with the last token in the list and remove the last element of the list
         */
        for (uint256 i = 0; i < listIdToken.length; i++) {
            if (listIdToken[i] == _indexOfTokenReward) {
                listIdToken[i] = listIdToken[listIdToken.length.sub(1)];
            }
        }

        // Remove the last element from the list of token IDs
        listIdToken.pop();

        // Emit an event to signal that a reward has been deleted
        emit DeleteReward(msg.sender, _indexOfTokenReward, address(this));
    }

    /**
     * @dev Updates the challenge information.
     * @param _challengeInfo The new challenge information.
     */
    function updateChallengeInfor(
        ChallengeInfo memory _challengeInfo
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        challengeInfo = _challengeInfo;
    }

    /**
     * @dev Updates the rate of lost rewards.
     * @param _rateOfLost The new rate of lost rewards.
     */
    function updateRateOfLost(
        uint256 _rateOfLost
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(_rateOfLost > 0, "RATE OF LOST IS INVALID.");
        rewardTokens[0].unlockRate = _rateOfLost;
    }

    /**
     * @dev Updates the status of the default gacha contract flag.
     * @param _isDefaultGachaContract The new status of the flag.
     */
    function updateStatusDefaultGachaContract(
        bool _isDefaultGachaContract
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        // Require that the new status is not equal to the current status.
        require(
            isDefaultGachaContract != _isDefaultGachaContract,
            "THIS STATUS HAS BEEN SETTING."
        );

        // Update the status.
        isDefaultGachaContract = _isDefaultGachaContract;
    }

    /**
     * This function updates the address of the wallet where returned NFTs will be sent.
     * It can only be called by the current returned NFT wallet address or if there is no current returned NFT wallet address set.
     * The new address must not be the zero address.
     */
    function updateReturnedNFTWallet(
        address _returnedNFTWallet
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(
            _returnedNFTWallet != address(0),
            "INVALID RETURNED NFT WALLET ADDRESS."
        );
        returnedNFTWallet = _returnedNFTWallet;
    }

    /**
     * @dev Updates the address of the wallet to receive administrative fees.
     * @param _receiveAdminWallet The new wallet address to receive administrative fees.
     * @notice Only the default admin role is allowed to call this function.
     * @notice Throws an error if the new address is invalid.
     */
    function updateReceiveAdminWallet(
        address _receiveAdminWallet
    ) public onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(
            _receiveAdminWallet != address(0),
            "RECEIVE ADMIN WALLET IS NOT INVALID"
        );
        receiveAdminWallet = _receiveAdminWallet;
    }

    /**
     * @dev Update the name and sponsor of the gacha.
     * @param _gachaName The new name of the gacha.
     * @param _gachaSponsor The new sponsor of the gacha.
     */
    function updateGachaNameAndGachaSponsor(
        string memory _gachaName,
        string memory _gachaSponsor
    ) external onlyRole(UPDATER_REWARDS_ROLE) {
        gachaName = _gachaName;
        gachaSponsor = _gachaSponsor;
    }

    /**
     * @dev Set the maximum number allowed for a specific reward.
     * @param _indexOfReward The index of the reward in the rewardTokens array.
     * @param _maxNumberAllowed The new maximum number allowed for the reward.
     */
    function setMaxNumberAllowedOfReward(
        uint256 _indexOfReward,
        uint256 _maxNumberAllowed
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        // Update the maximum number allowed for the specified reward
        rewardTokens[_indexOfReward].maxNumberAllowed = _maxNumberAllowed;
    }

    /**
     * @dev Sets the VRF consumer base addresses for both `VRFConsumerBaseMultipleTime`
     * and `VRFConsumerBaseOnlyTime` used to generate random numbers using Chainlink VRF.
     * @param _VRFConsumerBaseMultipleTime The VRF consumer base address for multiple-time gachas.
     * @param _VRFConsumerBaseOnlyTime The VRF consumer base address for only-time gachas.
     * @param _randomClassicAddress The address of the contract that generates random numbers using the classic method.
     * @param _typeRandomReward The type of random reward to set.
     * @param _timeRandomReward The TimeRandomReward enum value to set
     * Requirements:
     * - `_VRFConsumerBaseMultipleTime`, `_VRFConsumerBaseOnlyTime`, and `_randomClassicAddress` cannot be zero addresses.
     */
    function setVRFConsumerBaseInfos(
        address _VRFConsumerBaseMultipleTime,
        address _VRFConsumerBaseOnlyTime,
        address _randomClassicAddress,
        TypeRandomReward _typeRandomReward,
        TimeRandomReward _timeRandomReward
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(
            _VRFConsumerBaseMultipleTime != address(0) &&
                _VRFConsumerBaseOnlyTime != address(0) &&
                _randomClassicAddress != address(0),
            "VRF CONSUMER BASE IS INVALID."
        );
        VRFConsumerBaseMultipleTime = _VRFConsumerBaseMultipleTime;
        VRFConsumerBaseOnlyTime = _VRFConsumerBaseOnlyTime;
        randomClassicAddress = _randomClassicAddress;

        typeRandomReward = _typeRandomReward;
        timeRandomReward = _timeRandomReward;
    }

    /**
     * @dev Update the list of NFT addresses that must be held by the user in order to participate in the Gacha game.
     * @param _nftAddress Address of the NFT contract.
     * @param _flag Flag indicating whether the address of the NFT contract should be added or removed from the list.
     * @param _isTypeErc721 Boolean indicating whether the NFT contract is of type ERC721 or ERC1155.
     * @notice Only the admin can call this function.
     */
    function updateRequireBalanceNftAddress(
        address _nftAddress,
        bool _flag,
        bool _isTypeErc721
    ) external onlyRole(UPDATER_ACTIVITIES_ROLE) {
        require(_nftAddress != address(0), "INVALID NFT ADDRESS.");
        if (_flag) {
            requireBalanceNftAddress.add(_nftAddress);
        } else {
            requireBalanceNftAddress.remove(_nftAddress);
        }
        typeNfts[_nftAddress] = _isTypeErc721;
    }

    /**
     * @dev Add a reward token with the specified parameters to the rewardTokens mapping.
     * @param _indexOfTokenReward The index of the reward token to add.
     * @param _addressToken The address of the reward token contract.
     * @param _unlockRate The unlock rate of the reward token.
     * @param _rewardValue The reward value of the reward token.
     * @param _indexToken The index of the reward token in the listIdToken array.
     * @param _typeToken The type of the reward token.
     * @param _isMintNft Whether or not the reward token is an NFT that needs to be minted.
     * @param _maxNumberAllowed The maximum number allowed for the reward token.
     */
    function addReward(
        uint256 _indexOfTokenReward,
        address _addressToken,
        uint256 _unlockRate,
        uint256 _rewardValue,
        uint256 _indexToken,
        TypeToken _typeToken,
        bool _isMintNft,
        uint256 _reciveOption,
        uint256 _maxNumberAllowed
    ) private {
        // Set the new reward token at the given index
        rewardTokens[_indexOfTokenReward] = RewardToken(
            _addressToken,
            _unlockRate,
            _rewardValue,
            _indexToken,
            _typeToken,
            _isMintNft,
            _reciveOption,
            _maxNumberAllowed,
            0
        );
    }

    /**
     * @dev Check if the reward conditions are met for the given challenge address
     * @param _challengeAddress The address of the challenge to check reward conditions for
     * @return A boolean indicating whether the reward conditions are met
     **/
    function checkRewardConditions(
        address _challengeAddress,
        uint256[] memory _dataStep
    ) private view returns (bool) {
        /**
        @dev Retrieve the duration of the challenge from the IChallenge contract
        @param _challengeAddress The address of the challenge to retrieve information from
        @return uint256 representing the duration of the challenge
        */
        uint256 challengeDuration = IChallenge(_challengeAddress).duration();

        /**
        @dev Store the current challenge information in memory
        @param challengeInfo The struct containing the information about the current challenge  
        */
        ChallengeInfo memory currentChallengeInfo = challengeInfo;

        // Check if the target steps per day for the current challenge is less than or equal to the goal of the new challenge
        if (
            currentChallengeInfo.targetStepPerDay <=
            IChallenge(_challengeAddress).goal()
        ) {
            /**
            @dev Checks if the current challenge's duration is less than or equal to the challenge's duration of the given challenge address.
            @param _challengeAddress The address of the challenge contract to compare the duration with.
            @return A boolean indicating whether the current challenge's duration is less than or equal to the challenge's duration of the given challenge address.
            */
            if (currentChallengeInfo.challengeDuration <= challengeDuration) {
                // A boolean variable to keep track of whether the step data to be sent is correct or not.
                bool isCorrectStepDataToSend = false;

                // Loop through each element in the _dataStep array
                for (uint256 i = 0; i < _dataStep.length; i++) {
                    // Check if the current stepDataToSend is less than or equal to the current element in the array
                    if (currentChallengeInfo.stepDataToSend <= _dataStep[i]) {
                        // If it is, set the isCorrectStepDataToSend variable to true and break out of the loop
                        isCorrectStepDataToSend = true;
                        break;
                    }
                }

                // Check if the step data to send is correct
                if (isCorrectStepDataToSend) {
                    // Check if the required days for the challenge is greater than or equal to the challenge duration minus the tolerated percentage of the challenge duration
                    if (
                        IChallenge(_challengeAddress).dayRequired() >=
                        challengeDuration.sub(
                            challengeDuration.div(
                                currentChallengeInfo.toleranceAmount
                            )
                        )
                    ) {
                        // This condition checks if the current challenge meets the criteria for paying dividends to the investors
                        if (
                            // Check if the amount of base deposit is less than or equal to the total reward and allow give up, OR
                            (currentChallengeInfo.amountBaseDeposit <=
                                IChallenge(_challengeAddress).totalReward() &&
                                IChallenge(_challengeAddress).allowGiveUp(1)) ||
                            (currentChallengeInfo.amountTokenDeposit <=
                                IChallenge(_challengeAddress).totalReward() &&
                                !IChallenge(_challengeAddress).allowGiveUp(1))
                            // Check if the amount of token deposit is less than or equal to the total reward and not allow give up
                        ) {
                            // Check if the dividend status is pending
                            if (
                                currentChallengeInfo.dividendStatus ==
                                DividendStatus.DIVIDEND_PENDING
                            ) {
                                return true;
                            }

                            // Get the percentage of award receivers
                            uint256[] memory awardReceiversPercent = IChallenge(
                                _challengeAddress
                            ).getAwardReceiversPercent();

                            if (
                                currentChallengeInfo.dividendStatus ==
                                DividendStatus.DIVIDEND_SUCCESS
                            ) {
                                // Get the donation address from the challenge's ERC721 contract
                                address donationAddress = IChallenge(
                                    IChallenge(_challengeAddress).erc721Address(
                                        0
                                    )
                                ).donationWalletAddress();
                                require(
                                    donationAddress != address(0),
                                    "DONATION ADDRESS SHOULD BE DEFINED."
                                );

                                // Check if the first award receiver is the donation address with 98% of the reward
                                if (awardReceiversPercent[0] == 98) {
                                    if (
                                        IChallenge(_challengeAddress)
                                            .getAwardReceiversAtIndex(
                                                0,
                                                true
                                            ) == donationAddress
                                    ) {
                                        return true;
                                    }
                                }
                            }

                            // Check if the dividend distribution has failed
                            if (
                                currentChallengeInfo.dividendStatus ==
                                DividendStatus.DIVIDEND_FAIL
                            ) {
                                /**
                                 * Loop through the list of receivers and check if the receiver gets 98% of the reward and the receiver is an admin
                                 * Check if any of the award receivers are admins with 98% of the reward
                                 */
                                for (
                                    uint256 i = 1;
                                    i < awardReceiversPercent.length;
                                    i++
                                ) {
                                    if (awardReceiversPercent[i] == 98) {
                                        if (
                                            IChallenge(_challengeAddress)
                                                .getAwardReceiversAtIndex(
                                                    0,
                                                    false
                                                ) == receiveAdminWallet
                                        ) {
                                            return true;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Return false if none of the conditions are met
        return false;
    }

    /**
     * @dev Private function to check the ability to reward based on current reward token
     * @return The index of the current reward token, or 0 if there is no valid token to reward
     */
    function checkAbilityReward() private returns (uint256) {
        // Calculate the total unlock reward by summing up the unlock rates of all reward tokens.
        uint256 totalUnlockReward = rewardTokens[0].unlockRate;

        // Loop through the list of token IDs and sum up their corresponding unlock rates
        for (uint256 i = 0; i < listIdToken.length; i++) {
            totalUnlockReward = totalUnlockReward.add(
                rewardTokens[listIdToken[i]].unlockRate
            );
        }

        // Declare a variable to store the random number
        uint256 randomNumber;

        // Check if the time random reward is set to RANDOM_MUTIPLE_TIME
        if (timeRandomReward == TimeRandomReward.RANDOM_MUTIPLE_TIME) {
            // Check if the type of random reward is set to normal random number
            if (typeRandomReward == TypeRandomReward.NORMAL_RANDOM_NUMBER) {
                // If so, generate a random number based on the total unlock reward
                randomNumber = IVRFConsumerBase(randomClassicAddress)
                    .createRandomNumberMultipleTime(totalUnlockReward);
            } else {
                // If not, generate a random number using VRFConsumerBase and the total unlock reward
                randomNumber =
                    IVRFConsumerBase(VRFConsumerBaseMultipleTime)
                        .randomResult() %
                    totalUnlockReward;

                // Call the getRandomNumber function on the VRFConsumerBase contract
                IVRFConsumerBase(VRFConsumerBaseMultipleTime).getRandomNumber();
            }
        } else {
            if (typeRandomReward == TypeRandomReward.NORMAL_RANDOM_NUMBER) {
                // Call the getRandomNumber function on the VRFConsumerBase contract
                IVRFConsumerBase(randomClassicAddress)
                    .createRandomNumberOnlyTime(totalUnlockReward);

                // If so, generate a random number based on the total unlock reward
                randomNumber = IVRFConsumerBase(randomClassicAddress)
                    .randomResult();
            } else {
                // If not, generate a random number using VRFConsumerBase and the total unlock reward
                randomNumber =
                    IVRFConsumerBase(VRFConsumerBaseOnlyTime).randomResult() %
                    totalUnlockReward;

                // Call the getRandomNumber function on the VRFConsumerBase contract
                IVRFConsumerBase(VRFConsumerBaseOnlyTime).getRandomNumber();
            }
        }

        // If the random number is less than or equal to the unlock rate of the first reward token, return the ID of the first reward token.
        if (randomNumber <= rewardTokens[0].unlockRate) {
            return 0;
        }

        // Otherwise, loop through all other reward tokens and check if the random number is within the unlock rate range of each token.
        uint256 totalUnlock = rewardTokens[0].unlockRate;
        uint256 idReward;

        // Loop through the list of token IDs and check if the random number falls within their unlock rates
        for (uint256 i = 0; i < listIdToken.length; i++) {
            if (
                randomNumber <=
                rewardTokens[listIdToken[i]].unlockRate + totalUnlock
            ) {
                idReward = listIdToken[i];
                break;
            }
            totalUnlock = totalUnlock.add(
                rewardTokens[listIdToken[i]].unlockRate
            );
        }
        // Return the ID of the reward token to be given.
        return idReward;
    }

    /**
     * @dev Checks if the required NFT balance conditions are met for the challenge.
     * @param _challengeAddress The address of the challenge contract.
     * @return A boolean indicating whether the required NFT balance conditions are met.
     */
    function checkRequireBalanceNft(
        address _challengeAddress,
        uint256[] memory _dataStep
    ) public view returns (bool) {
        // Check if the reward conditions are met
        if (!checkRewardConditions(_challengeAddress, _dataStep)) {
            return false;
        }

        // Get the address of the challenger from the challenge contract
        address challengerAddress = IChallenge(_challengeAddress).challenger();

        // Calculate the current date in seconds
        uint256 currentDate = block.timestamp.div(86400);
        if (
            countTimeActiveGacha[challengerAddress][currentDate] >=
            challengeInfo.timeLimitActiveGacha
        ) {
            return false;
        }

        // If using the default gacha contract, return true
        if (isDefaultGachaContract) {
            return true;
        }

        // Check the balance of NFTs for the specific type of require balance
        if (
            challengeInfo.typeRequireBalanceNft ==
            TypeRequireBalanceNft.REQUIRE_BALANCE_WALLET
        ) {
            // Check the balance of NFTs in the challenger's wallet
            return checkBalanceNft(challengerAddress);
        }

        // Check the balance of NFTs in the challenge contract
        if (
            challengeInfo.typeRequireBalanceNft ==
            TypeRequireBalanceNft.REQUIRE_BALANCE_CONTRACT
        ) {
            return checkBalanceNft(_challengeAddress);
        }

        // Check the balance of NFTs in both the challenger's wallet and the challenge contract
        if (
            challengeInfo.typeRequireBalanceNft ==
            TypeRequireBalanceNft.REQUIRE_BALANCE_ALL
        ) {
            return
                checkBalanceNft(challengerAddress) &&
                checkBalanceNft(_challengeAddress);
        }

        // Return false if none of the above conditions are met
        return false;
    }

    /**
     * @dev Check if the specified address has the required balance of NFTs
     * @param _fromAddress The address to check the balance of NFTs for
     * @return True if the address has the required balance, false otherwise
     */
    function checkBalanceNft(address _fromAddress) private view returns (bool) {
        // Loop through all the NFTs that are required for the challenge
        for (uint256 i = 0; i < requireBalanceNftAddress.values().length; i++) {
            // If the NFT is an ERC-721 token
            if (typeNfts[requireBalanceNftAddress.values()[i]]) {
                // If the address has a balance of this token
                if (
                    IERC721(requireBalanceNftAddress.values()[i]).balanceOf(
                        _fromAddress
                    ) > 0
                ) {
                    return true;
                }
            } else {
                // If the NFT is an ERC-1155 token
                // Get the current index token for this NFT
                uint256 currentIndexToken = IERC1155(
                    requireBalanceNftAddress.values()[i]
                ).nextTokenIdToMint();

                // Loop through all the tokens for this NFT that the address has a balance of
                for (uint256 j = 0; j < currentIndexToken; j++) {
                    if (
                        IERC1155(requireBalanceNftAddress.values()[i])
                            .balanceOf(_fromAddress, j) > 0
                    ) {
                        return true;
                    }
                }
            }
        }

        // If the address doesn't have the required balance of NFTs for the challenge
        return false;
    }

    /**
     * @dev Returns an array of all the addresses in the `requireBalanceNftAddress` mapping.
     */
    function getRequireBalanceNftAddress()
        external
        view
        returns (address[] memory)
    {
        return requireBalanceNftAddress.values();
    }

    /**
     * @dev Returns an array of all token IDs that have been minted in the current contract.
     * @return An array of token IDs.
     */
    function getListIdToken() external view returns (uint256[] memory) {
        return listIdToken;
    }

    /**
     * @dev Returns the total number of rewards in the contract.
     * @return The total number of rewards.
     */
    function getTotalNumberReward() public view returns (uint256) {
        return listIdToken.length;
    }

    /**
     * @dev Internal function to authorize the upgrade of the contract implementation.
     * @param newImplementation Address of the new implementation contract.
     */
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyRole(UPGRADER_ROLE) {}

    /*
     * @dev Standard function that ERC721 token contracts must implement to allow safe transfer of tokens to this contract.
     * @param _operator The address which called safeTransferFrom function.
     * @param _from The address which previously owned the token.
     * @param _tokenId The NFT identifier which is being transferred.
     * @param _data Additional data with no specified format.
     * @return A bytes4 indicating success or failure.
     */
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external virtual override returns (bytes4) {
        return this.onERC721Received.selector;
    }

    /*
     * @dev Standard function that ERC1155 token contracts must implement to allow safe transfer of tokens to this contract.
     * @param _operator The address which called safeTransferFrom function.
     * @param _from The address which previously owned the token.
     * @param _tokenId The NFT identifier which is being transferred.
     * @param _data Additional data with no specified format.
     * @return A bytes4 indicating success or failure.
     */
    function onERC1155Received(
        address,
        address,
        uint256,
        uint256,
        bytes memory
    ) public pure returns (bytes4) {
        return this.onERC1155Received.selector;
    }

    /**
     * @dev Returns whether the contract supports a given interface.
     * Implements ERC165 and AccessControl interfaces.
     * @param interfaceId The interface identifier, as specified in ERC-165 and AccessControl.
     * @return True if the contract supports `interfaceId`, false otherwise.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(AccessControlUpgradeable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

abstract contract TermData {
    // Enum defining the types of tokens that can be used in the system
    enum TypeToken {
        ERC20,
        ERC721,
        ERC1155,
        NATIVE_TOKEN
    }

    // Enum defining the statuses for a dividend payout
    enum DividendStatus {
        DIVIDEND_PENDING,
        DIVIDEND_SUCCESS,
        DIVIDEND_FAIL
    }

    // Enum defining the states of a challenge
    enum ChallengeState {
        PROCESSING,
        SUCCESS,
        FAILED,
        GAVE_UP,
        CLOSED
    }

    // Enum defining the types of requirements for NFT balances
    enum TypeRequireBalanceNft {
        REQUIRE_BALANCE_WALLET,
        REQUIRE_BALANCE_CONTRACT,
        REQUIRE_BALANCE_ALL
    }

    /*
     * There are two types:
     * - NORMAL_RANDOM_NUMBER: Uses a normal random number generator
     * - VRF_CHAINLINK_RANDOM_NUMBER: Uses the Chainlink VRF (Verifiable Random Function)
     */
    enum TypeRandomReward {
        NORMAL_RANDOM_NUMBER,
        VRF_CHAINLINK_RANDOM_NUMBER
    }
     
    /**
     * Definition of TimeRandomReward enum
     *
     * - RANDOM_ONLY_TIME: only allowed to receive a random reward once during the specified time period
     * - RANDOM_MUTIPLE_TIME: allowed to receive random rewards multiple times during the specified time period
     */
    enum TimeRandomReward {
        RANDOM_ONLY_TIME,
        RANDOM_MUTIPLE_TIME
    }

    /**
     * @dev This struct defines the properties of a RewardToken.
     * @param addressToken The address of the token to be rewarded.
     * @param unlockRate The unlock rate of the token.
     * @param rewardValue The reward value of the token.
     * @param indexToken The index of the token.
     * @param typeToken The type of the token.
     * @param isMintNft A boolean value to determine whether the token is an NFT.
     * @param maxNumberAllowed The maximum number allowed for the token.
     */
    struct RewardToken {
        address addressToken;
        uint256 unlockRate;
        uint256 rewardValue;
        uint256 indexToken;
        TypeToken typeToken;
        bool isMintNft;
        uint256 reciveOption;
        uint256 maxNumberAllowed;
        uint256 rewardActivationCount;
    }

    /**
     * @dev Struct to store information about a challenge.
     * @param targetStepPerDay The target step count per day for the challenge.
     * @param challengeDuration The duration of the challenge in days.
     * @param stepDataToSend The step count data to send for the challenge.
     * @param toleranceAmount The amount of tolerance allowed for the challenge.
     *  @param dividendStatus The status of dividend for the challenge.
     * @param amountBaseDeposit The amount of base deposit for the challenge.
     * @param amountTokenDeposit The amount of token deposit for the challenge.
     * @param timeLimitActiveGacha The time limit for the active gacha instance for the challenge.
     * @param typeRequireBalanceNft The type of required balance NFT for the challenge.
     */
    struct ChallengeInfo {
        uint256 targetStepPerDay;
        uint256 challengeDuration;
        uint256 stepDataToSend;
        uint256 toleranceAmount;
        DividendStatus dividendStatus;
        uint256 amountBaseDeposit;
        uint256 amountTokenDeposit;
        uint256 timeLimitActiveGacha;
        TypeRequireBalanceNft typeRequireBalanceNft;
    }

    /**
     * @dev User information struct to store information about user's reward status.
     * @param statusRandom The status of user reward random.
     * @param indexReward The index of user reward.
     * @param indexToken The index of reward token.
     * @param tokenAddress The address of reward token.
     * @param rewardValue The value of reward.
     * @param nameReward The name of reward.
     */
    struct UserInfor {
        bool statusRandom;
        uint256 indexReward;
        uint256 indexToken;
        address tokenAddress;
        uint256 rewardValue;
        string nameReward;
    }

    /**
     * @dev Event emitted when a new reward is added to a gacha.
     * @param _addressToken The address of the token to be rewarded.
     * @param _unlockRate The rate at which the reward will be unlocked.
     * @param _typeToken The type of token to be rewarded.
     * @param _gachaAddress The address of the gacha the reward is being added to.
     */
    event AddNewReward(
        address indexed _addressToken,
        uint256 _unlockRate,
        TypeToken _typeToken,
        address _gachaAddress
    );

    /**
     * @dev Event emitted when a reward is deleted from a gacha.
     * @param _caller The address of the caller who deleted the reward.
     * @param _indexOfTokenReward The index of the reward being deleted.
     * @param _gachaAddress The address of the gacha the reward is being deleted from.
     */
    event DeleteReward(
        address indexed _caller,
        uint256 _indexOfTokenReward,
        address _gachaAddress
    );

    /**
     * @dev Event emitted when a daily result is sent for a gacha.
     * @param _caller The address of the caller who sent the daily result.
     * @param _gachaAddress The address of the gacha the daily result is being sent for.
     */
    event SendDailyResultGacha(address indexed _caller, address _gachaAddress);

    /**
     * @dev Event emitted when a challenge is closed for a gacha.
     * @param _caller The address of the caller who closed the challenge.
     * @param _gachaAddress The address of the gacha the challenge is being closed for.
     */
    event CloseGacha(address indexed _caller, address _gachaAddress);

    // Mapping to store information about reward tokens
    mapping(uint256 => RewardToken) public rewardTokens;

    // Mapping to store user information
    mapping(address => UserInfor) public userInfor;

    // Struct to store challenge information
    ChallengeInfo public challengeInfo;

    // The type of random reward to be used
    TypeRandomReward public typeRandomReward;

    // The type of time-based random reward to be used
    TimeRandomReward public timeRandomReward;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (access/AccessControl.sol)

pragma solidity ^0.8.0;

import "./IAccessControlUpgradeable.sol";
import "./ContextUpgradeable.sol";
import "./StringsUpgradeable.sol";
import "./ERC165Upgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Contract module that allows children to implement role-based access
 * control mechanisms. This is a lightweight version that doesn't allow enumerating role
 * members except through off-chain means by accessing the contract event logs. Some
 * applications may benefit from on-chain enumerability, for those cases see
 * {AccessControlEnumerable}.
 *
 * Roles are referred to by their `bytes32` identifier. These should be exposed
 * in the external API and be unique. The best way to achieve this is by
 * using `public constant` hash digests:
 *
 * ```
 * bytes32 public constant MY_ROLE = keccak256("MY_ROLE");
 * ```
 *
 * Roles can be used to represent a set of permissions. To restrict access to a
 * function call, use {hasRole}:
 *
 * ```
 * function foo() public {
 *     require(hasRole(MY_ROLE, msg.sender));
 *     ...
 * }
 * ```
 *
 * Roles can be granted and revoked dynamically via the {grantRole} and
 * {revokeRole} functions. Each role has an associated admin role, and only
 * accounts that have a role's admin role can call {grantRole} and {revokeRole}.
 *
 * By default, the admin role for all roles is `DEFAULT_ADMIN_ROLE`, which means
 * that only accounts with this role will be able to grant or revoke other
 * roles. More complex role relationships can be created by using
 * {_setRoleAdmin}.
 *
 * WARNING: The `DEFAULT_ADMIN_ROLE` is also its own admin: it has permission to
 * grant and revoke this role. Extra precautions should be taken to secure
 * accounts that have been granted it.
 */
abstract contract AccessControlUpgradeable is Initializable, ContextUpgradeable, IAccessControlUpgradeable, ERC165Upgradeable {
    function __AccessControl_init() internal onlyInitializing {
    }

    function __AccessControl_init_unchained() internal onlyInitializing {
    }
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
    }

    mapping(bytes32 => RoleData) private _roles;

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    /**
     * @dev Modifier that checks that an account has a specific role. Reverts
     * with a standardized message including the required role.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     *
     * _Available since v4.1._
     */
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IAccessControlUpgradeable).interfaceId || super.supportsInterface(interfaceId);
    }

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) public view virtual override returns (bool) {
        return _roles[role].members[account];
    }

    /**
     * @dev Revert with a standard message if `_msgSender()` is missing `role`.
     * Overriding this function changes the behavior of the {onlyRole} modifier.
     *
     * Format of the revert message is described in {_checkRole}.
     *
     * _Available since v4.6._
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, _msgSender());
    }

    /**
     * @dev Revert with a standard message if `account` is missing `role`.
     *
     * The format of the revert reason is given by the following regular expression:
     *
     *  /^AccessControl: account (0x[0-9a-f]{40}) is missing role (0x[0-9a-f]{64})$/
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert(
                string(
                    abi.encodePacked(
                        "AccessControl: account ",
                        StringsUpgradeable.toHexString(account),
                        " is missing role ",
                        StringsUpgradeable.toHexString(uint256(role), 32)
                    )
                )
            );
        }
    }

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) public view virtual override returns (bytes32) {
        return _roles[role].adminRole;
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleGranted} event.
     */
    function grantRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     *
     * May emit a {RoleRevoked} event.
     */
    function revokeRole(bytes32 role, address account) public virtual override onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been revoked `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     *
     * May emit a {RoleRevoked} event.
     */
    function renounceRole(bytes32 role, address account) public virtual override {
        require(account == _msgSender(), "AccessControl: can only renounce roles for self");

        _revokeRole(role, account);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event. Note that unlike {grantRole}, this function doesn't perform any
     * checks on the calling account.
     *
     * May emit a {RoleGranted} event.
     *
     * [WARNING]
     * ====
     * This function should only be called from the constructor when setting
     * up the initial roles for the system.
     *
     * Using this function in any other way is effectively circumventing the admin
     * system imposed by {AccessControl}.
     * ====
     *
     * NOTE: This function is deprecated in favor of {_grantRole}.
     */
    function _setupRole(bytes32 role, address account) internal virtual {
        _grantRole(role, account);
    }

    /**
     * @dev Sets `adminRole` as ``role``'s admin role.
     *
     * Emits a {RoleAdminChanged} event.
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }

    /**
     * @dev Grants `role` to `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleGranted} event.
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            emit RoleGranted(role, account, _msgSender());
        }
    }

    /**
     * @dev Revokes `role` from `account`.
     *
     * Internal function without access restriction.
     *
     * May emit a {RoleRevoked} event.
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            emit RoleRevoked(role, account, _msgSender());
        }
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

// Interface for the VRF Consumer Base
interface IVRFConsumerBase {
    function getRandomNumber() external returns (bytes32 requestId);

    function randomResult() external view returns(uint256);

    function createRandomNumberOnlyTime(uint256 _randomWithLimitValue) external;

    function createRandomNumberMultipleTime(uint256 _randomWithLimitValue) external view returns(uint256);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (proxy/utils/UUPSUpgradeable.sol)

pragma solidity ^0.8.0;

import "./draft-IERC1822Upgradeable.sol";
import "./ERC1967UpgradeUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev An upgradeability mechanism designed for UUPS proxies. The functions included here can perform an upgrade of an
 * {ERC1967Proxy}, when this contract is set as the implementation behind such a proxy.
 *
 * A security mechanism ensures that an upgrade does not turn off upgradeability accidentally, although this risk is
 * reinstated if the upgrade retains upgradeability but removes the security mechanism, e.g. by replacing
 * `UUPSUpgradeable` with a custom implementation of upgrades.
 *
 * The {_authorizeUpgrade} function must be overridden to include access restriction to the upgrade mechanism.
 *
 * _Available since v4.1._
 */
abstract contract UUPSUpgradeable is Initializable, IERC1822ProxiableUpgradeable, ERC1967UpgradeUpgradeable {
    function __UUPSUpgradeable_init() internal onlyInitializing {
    }

    function __UUPSUpgradeable_init_unchained() internal onlyInitializing {
    }
    /// @custom:oz-upgrades-unsafe-allow state-variable-immutable state-variable-assignment
    address private immutable __self = address(this);

    /**
     * @dev Check that the execution is being performed through a delegatecall call and that the execution context is
     * a proxy contract with an implementation (as defined in ERC1967) pointing to self. This should only be the case
     * for UUPS and transparent proxies that are using the current contract as their implementation. Execution of a
     * function through ERC1167 minimal proxies (clones) would not normally pass this test, but is not guaranteed to
     * fail.
     */
    modifier onlyProxy() {
        require(address(this) != __self, "Function must be called through delegatecall");
        require(_getImplementation() == __self, "Function must be called through active proxy");
        _;
    }

    /**
     * @dev Check that the execution is not being performed through a delegate call. This allows a function to be
     * callable on the implementing contract but not through proxies.
     */
    modifier notDelegated() {
        require(address(this) == __self, "UUPSUpgradeable: must not be called through delegatecall");
        _;
    }

    /**
     * @dev Implementation of the ERC1822 {proxiableUUID} function. This returns the storage slot used by the
     * implementation. It is used to validate the implementation's compatibility when performing an upgrade.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy. This is guaranteed by the `notDelegated` modifier.
     */
    function proxiableUUID() external view virtual override notDelegated returns (bytes32) {
        return _IMPLEMENTATION_SLOT;
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeTo(address newImplementation) external virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, new bytes(0), false);
    }

    /**
     * @dev Upgrade the implementation of the proxy to `newImplementation`, and subsequently execute the function call
     * encoded in `data`.
     *
     * Calls {_authorizeUpgrade}.
     *
     * Emits an {Upgraded} event.
     */
    function upgradeToAndCall(address newImplementation, bytes memory data) external payable virtual onlyProxy {
        _authorizeUpgrade(newImplementation);
        _upgradeToAndCallUUPS(newImplementation, data, true);
    }

    /**
     * @dev Function that should revert when `msg.sender` is not authorized to upgrade the contract. Called by
     * {upgradeTo} and {upgradeToAndCall}.
     *
     * Normally, this function will use an xref:access.adoc[access control] modifier such as {Ownable-onlyOwner}.
     *
     * ```solidity
     * function _authorizeUpgrade(address) internal override onlyOwner {}
     * ```
     */
    function _authorizeUpgrade(address newImplementation) internal virtual;

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.1) (proxy/utils/Initializable.sol)

pragma solidity ^0.8.2;

import "./AddressUpgradeable.sol";

/**
 * @dev This is a base contract to aid in writing upgradeable contracts, or any kind of contract that will be deployed
 * behind a proxy. Since proxied contracts do not make use of a constructor, it's common to move constructor logic to an
 * external initializer function, usually called `initialize`. It then becomes necessary to protect this initializer
 * function so it can only be called once. The {initializer} modifier provided by this contract will have this effect.
 *
 * The initialization functions use a version number. Once a version number is used, it is consumed and cannot be
 * reused. This mechanism prevents re-execution of each "step" but allows the creation of new initialization steps in
 * case an upgrade adds a module that needs to be initialized.
 *
 * For example:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * contract MyToken is ERC20Upgradeable {
 *     function initialize() initializer public {
 *         __ERC20_init("MyToken", "MTK");
 *     }
 * }
 * contract MyTokenV2 is MyToken, ERC20PermitUpgradeable {
 *     function initializeV2() reinitializer(2) public {
 *         __ERC20Permit_init("MyToken");
 *     }
 * }
 * ```
 *
 * TIP: To avoid leaving the proxy in an uninitialized state, the initializer function should be called as early as
 * possible by providing the encoded function call as the `_data` argument to {ERC1967Proxy-constructor}.
 *
 * CAUTION: When used with inheritance, manual care must be taken to not invoke a parent initializer twice, or to ensure
 * that all initializers are idempotent. This is not verified automatically as constructors are by Solidity.
 *
 * [CAUTION]
 * ====
 * Avoid leaving a contract uninitialized.
 *
 * An uninitialized contract can be taken over by an attacker. This applies to both a proxy and its implementation
 * contract, which may impact the proxy. To prevent the implementation contract from being used, you should invoke
 * the {_disableInitializers} function in the constructor to automatically lock it when it is deployed:
 *
 * [.hljs-theme-light.nopadding]
 * ```
 * /// @custom:oz-upgrades-unsafe-allow constructor
 * constructor() {
 *     _disableInitializers();
 * }
 * ```
 * ====
 */
abstract contract Initializable {
    /**
     * @dev Indicates that the contract has been initialized.
     * @custom:oz-retyped-from bool
     */
    uint8 private _initialized;

    /**
     * @dev Indicates that the contract is in the process of being initialized.
     */
    bool private _initializing;

    /**
     * @dev Triggered when the contract has been initialized or reinitialized.
     */
    event Initialized(uint8 version);

    /**
     * @dev A modifier that defines a protected initializer function that can be invoked at most once. In its scope,
     * `onlyInitializing` functions can be used to initialize parent contracts.
     *
     * Similar to `reinitializer(1)`, except that functions marked with `initializer` can be nested in the context of a
     * constructor.
     *
     * Emits an {Initialized} event.
     */
    modifier initializer() {
        bool isTopLevelCall = !_initializing;
        require(
            (isTopLevelCall && _initialized < 1) || (!AddressUpgradeable.isContract(address(this)) && _initialized == 1),
            "Initializable: contract is already initialized"
        );
        _initialized = 1;
        if (isTopLevelCall) {
            _initializing = true;
        }
        _;
        if (isTopLevelCall) {
            _initializing = false;
            emit Initialized(1);
        }
    }

    /**
     * @dev A modifier that defines a protected reinitializer function that can be invoked at most once, and only if the
     * contract hasn't been initialized to a greater version before. In its scope, `onlyInitializing` functions can be
     * used to initialize parent contracts.
     *
     * A reinitializer may be used after the original initialization step. This is essential to configure modules that
     * are added through upgrades and that require initialization.
     *
     * When `version` is 1, this modifier is similar to `initializer`, except that functions marked with `reinitializer`
     * cannot be nested. If one is invoked in the context of another, execution will revert.
     *
     * Note that versions can jump in increments greater than 1; this implies that if multiple reinitializers coexist in
     * a contract, executing them in the right order is up to the developer or operator.
     *
     * WARNING: setting the version to 255 will prevent any future reinitialization.
     *
     * Emits an {Initialized} event.
     */
    modifier reinitializer(uint8 version) {
        require(!_initializing && _initialized < version, "Initializable: contract is already initialized");
        _initialized = version;
        _initializing = true;
        _;
        _initializing = false;
        emit Initialized(version);
    }

    /**
     * @dev Modifier to protect an initialization function so that it can only be invoked by functions with the
     * {initializer} and {reinitializer} modifiers, directly or indirectly.
     */
    modifier onlyInitializing() {
        require(_initializing, "Initializable: contract is not initializing");
        _;
    }

    /**
     * @dev Locks the contract, preventing any future reinitialization. This cannot be part of an initializer call.
     * Calling this in the constructor of a contract will prevent that contract from being initialized or reinitialized
     * to any version. It is recommended to use this to lock implementation contracts that are designed to be called
     * through proxies.
     *
     * Emits an {Initialized} event the first time it is successfully executed.
     */
    function _disableInitializers() internal virtual {
        require(!_initializing, "Initializable: contract is initializing");
        if (_initialized < type(uint8).max) {
            _initialized = type(uint8).max;
            emit Initialized(type(uint8).max);
        }
    }

    /**
     * @dev Returns the highest version that has been initialized. See {reinitializer}.
     */
    function _getInitializedVersion() internal view returns (uint8) {
        return _initialized;
    }

    /**
     * @dev Returns `true` if the contract is currently initializing. See {onlyInitializing}.
     */
    function _isInitializing() internal view returns (bool) {
        return _initializing;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

interface IERC20 {
     function balanceOf(address account) external view returns (uint256);
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

interface IChallenge {
    //It returns the goal of the challenge.
    function goal() external view returns(uint256);

    //It returns the duration of the challenge.
    function duration() external view returns(uint256);

    //It returns the number of days required to complete the challenge.
    function dayRequired() external view returns(uint256);

    //It returns the total balance of the base token.
    function totalReward() external view returns(uint256);

    //It returns the balance of the token.
    function getBalanceToken() external view returns(uint256[] memory);

    function allowGiveUp(uint256 _index) external view returns(bool);

    function donationWalletAddress() external view returns(address);

    function returnedNFTWallet() external view returns(address);

    function getAwardReceiversPercent() external view returns(uint256[] memory);

    function challenger() external view returns(address);

    function getAwardReceiversAtIndex(uint256 _index, bool _isAddressSuccess) external view returns(address);

    function isFinished() external view returns(bool);

    function erc721Address(uint256 _index) external view returns(address);

    function nextTokenIdToMint() external view returns(uint256);

    function ownerOf(uint256 _tokenIndex) external view returns(address);

    function safeMintNFT721Heper(address _tokenAddress, address _challengerAddress) external;

    function name() external view returns(string memory);
    
    function safeMintNFT1155Heper(
        address _tokenAddress, 
        address _challengerAddress,
        uint256 _indexToken,
        uint256 _rewardToken
    ) external;

    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) external;
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.16;

library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     *
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     *
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     *
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     *
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

/**
    helper methods for interacting with ERC20 tokens that do not consistently return true/false
    with the addition of a transfer function to send eth or an erc20 token
*/
library TransferHelper {
    function safeApprove(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x095ea7b3, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function saveTransferEth(
        address payable recipient, 
        uint256 amount
    ) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    function safeTransfer(
        address token,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa9059cbb, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FAILED"
        );
    }
    
    function safeApproveForAllNFT1155(
        address token,
        address operator,
        bool approved
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa22cb465, operator, approved)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_NFT1155_FAILED"
        );
    }
    
    function safeTransferNFT1155(
        address token,
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory dataValue
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xf242432a, from, to, id, amount, dataValue)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_NFT1155_FAILED"
        );
    }

    function safeMintNFT1155(
        address token,
        address account, 
        uint256 id, 
        uint256 amount, 
        bytes memory dataValue
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x280f4e28, account, id, amount, dataValue)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: MINT_NFT1155_FAILED"
        );
    }

    function safeMintNFT(
        address token,
        address to
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x40d097c3, to)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: MINT_NFT_FAILED"
        );
    }

    function safeApproveForAll(
        address token,
        address to,
        bool value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0xa22cb465, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: APPROVE_FAILED"
        );
    }

    function safeTransferFrom(
        address token,
        address from,
        address to,
        uint256 value
    ) internal {
        (bool success, bytes memory data) = token.call(
            abi.encodeWithSelector(0x23b872dd, from, to, value)
        );
        require(
            success && (data.length == 0 || abi.decode(data, (bool))),
            "TransferHelper: TRANSFER_FROM_FAILED"
        );
    }

    // sends ETH or an erc20 token
    function safeTransferBaseToken(
        address token,
        address payable to,
        uint256 value,
        bool isERC20
    ) internal {
        if (!isERC20) {
            to.transfer(value);
        } else {
            (bool success, bytes memory data) = token.call(
                abi.encodeWithSelector(0xa9059cbb, to, value)
            );
            require(
                success && (data.length == 0 || abi.decode(data, (bool))),
                "TransferHelper: TRANSFER_FAILED"
            );
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC721/IERC721Receiver.sol)

pragma solidity ^0.8.0;

/**
 * @title ERC721 token receiver interface
 * @dev Interface for any contract that wants to support safeTransfers
 * from ERC721 asset contracts.
 */
interface IERC721Receiver {
    /**
     * @dev Whenever an {IERC721} `tokenId` token is transferred to this contract via {IERC721-safeTransferFrom}
     * by `operator` from `from`, this function is called.
     *
     * It must return its Solidity selector to confirm the token transfer.
     * If any other value is returned or the interface is not implemented by the recipient, the transfer will be reverted.
     *
     * The selector can be obtained in Solidity with `IERC721Receiver.onERC721Received.selector`.
     */
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC721/IERC721.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC721 compliant contract.
 */
interface IERC721 is IERC165 {
    /**
     * @dev Emitted when `tokenId` token is transferred from `from` to `to`.
     */
    event Transfer(address indexed from, address indexed to, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables `approved` to manage the `tokenId` token.
     */
    event Approval(address indexed owner, address indexed approved, uint256 indexed tokenId);

    /**
     * @dev Emitted when `owner` enables or disables (`approved`) `operator` to manage all of its assets.
     */
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    /**
     * @dev Returns the number of tokens in ``owner``'s account.
     */
    function balanceOf(address owner) external view returns (uint256 balance);

    /**
     * @dev Returns the owner of the `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function ownerOf(uint256 tokenId) external view returns (address owner);

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes calldata data
    ) external;

    /**
     * @dev Safely transfers `tokenId` token from `from` to `to`, checking first that contract recipients
     * are aware of the ERC721 protocol to prevent tokens from being forever locked.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must exist and be owned by `from`.
     * - If the caller is not `from`, it must have been allowed to move this token by either {approve} or {setApprovalForAll}.
     * - If `to` refers to a smart contract, it must implement {IERC721Receiver-onERC721Received}, which is called upon a safe transfer.
     *
     * Emits a {Transfer} event.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Transfers `tokenId` token from `from` to `to`.
     *
     * WARNING: Usage of this method is discouraged, use {safeTransferFrom} whenever possible.
     *
     * Requirements:
     *
     * - `from` cannot be the zero address.
     * - `to` cannot be the zero address.
     * - `tokenId` token must be owned by `from`.
     * - If the caller is not `from`, it must be approved to move this token by either {approve} or {setApprovalForAll}.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    /**
     * @dev Gives permission to `to` to transfer `tokenId` token to another account.
     * The approval is cleared when the token is transferred.
     *
     * Only a single account can be approved at a time, so approving the zero address clears previous approvals.
     *
     * Requirements:
     *
     * - The caller must own the token or be an approved operator.
     * - `tokenId` must exist.
     *
     * Emits an {Approval} event.
     */
    function approve(address to, uint256 tokenId) external;

    /**
     * @dev Approve or remove `operator` as an operator for the caller.
     * Operators can call {transferFrom} or {safeTransferFrom} for any token owned by the caller.
     *
     * Requirements:
     *
     * - The `operator` cannot be the caller.
     *
     * Emits an {ApprovalForAll} event.
     */
    function setApprovalForAll(address operator, bool _approved) external;

    /**
     * @dev Returns the account approved for `tokenId` token.
     *
     * Requirements:
     *
     * - `tokenId` must exist.
     */
    function getApproved(uint256 tokenId) external view returns (address operator);

    /**
     * @dev Returns if the `operator` is allowed to manage all of the assets of `owner`.
     *
     * See {setApprovalForAll}
     */
    function isApprovedForAll(address owner, address operator) external view returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (token/ERC1155/IERC1155.sol)

pragma solidity ^0.8.0;

import "./IERC165.sol";

/**
 * @dev Required interface of an ERC1155 compliant contract, as defined in the
 * https://eips.ethereum.org/EIPS/eip-1155[EIP].
 *
 * _Available since v3.1._
 */
interface IERC1155 is IERC165 {
    function balanceOf(address account, uint256 id) external view returns (uint256);

    function nextTokenIdToMint() external view returns(uint256);

    /**
     * @dev Transfers `amount` tokens of token type `id` from `from` to `to`.
     *
     * Emits a {TransferSingle} event.
     *
     * Requirements:
     *
     * - `to` cannot be the zero address.
     * - If the caller is not `from`, it must have been approved to spend ``from``'s tokens via {setApprovalForAll}.
     * - `from` must have a balance of tokens of type `id` of at least `amount`.
     * - If `to` refers to a smart contract, it must implement {IERC1155Receiver-onERC1155Received} and return the
     * acceptance magic value.
     */
    function safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes calldata data
    ) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Counters.sol)

pragma solidity ^0.8.0;

/**
 * @title Counters
 * @author Matt Condon (@shrugs)
 * @dev Provides counters that can only be incremented, decremented or reset. This can be used e.g. to track the number
 * of elements in a mapping, issuing ERC721 ids, or counting request ids.
 *
 * Include with `using Counters for Counters.Counter;`
 */
library Counters {
    struct Counter {
        // This variable should never be directly accessed by users of the library: interactions must be restricted to
        // the library's function. As of Solidity v0.5.2, this cannot be enforced, though there is a proposal to add
        // this feature: see https://github.com/ethereum/solidity/issues/4637
        uint256 _value; // default: 0
    }

    function current(Counter storage counter) internal view returns (uint256) {
        return counter._value;
    }

    function increment(Counter storage counter) internal {
        unchecked {
            counter._value += 1;
        }
    }

    function decrement(Counter storage counter) internal {
        uint256 value = counter._value;
        require(value > 0, "Counter: decrement overflow");
        unchecked {
            counter._value = value - 1;
        }
    }

    function reset(Counter storage counter) internal {
        counter._value = 0;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/structs/EnumerableSet.sol)
// This file was procedurally generated from scripts/generate/templates/EnumerableSet.js.

pragma solidity ^0.8.0;

/**
 * @dev Library for managing
 * https://en.wikipedia.org/wiki/Set_(abstract_data_type)[sets] of primitive
 * types.
 *
 * Sets have the following properties:
 *
 * - Elements are added, removed, and checked for existence in constant time
 * (O(1)).
 * - Elements are enumerated in O(n). No guarantees are made on the ordering.
 *
 * ```
 * contract Example {
 *     // Add the library methods
 *     using EnumerableSet for EnumerableSet.AddressSet;
 *
 *     // Declare a set state variable
 *     EnumerableSet.AddressSet private mySet;
 * }
 * ```
 *
 * As of v3.3.0, sets of type `bytes32` (`Bytes32Set`), `address` (`AddressSet`)
 * and `uint256` (`UintSet`) are supported.
 *
 * [WARNING]
 * ====
 * Trying to delete such a structure from storage will likely result in data corruption, rendering the structure
 * unusable.
 * See https://github.com/ethereum/solidity/pull/11843[ethereum/solidity#11843] for more info.
 *
 * In order to clean an EnumerableSet, you can either remove all elements one by one or create a fresh instance using an
 * array of EnumerableSet.
 * ====
 */
library EnumerableSet {
    // To implement this library for multiple types with as little code
    // repetition as possible, we write it in terms of a generic Set type with
    // bytes32 values.
    // The Set implementation uses private functions, and user-facing
    // implementations (such as AddressSet) are just wrappers around the
    // underlying Set.
    // This means that we can only create new EnumerableSets for types that fit
    // in bytes32.

    struct Set {
        // Storage of set values
        bytes32[] _values;
        // Position of the value in the `values` array, plus 1 because index 0
        // means a value is not in the set.
        mapping(bytes32 => uint256) _indexes;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function _add(Set storage set, bytes32 value) private returns (bool) {
        if (!_contains(set, value)) {
            set._values.push(value);
            // The value is stored at length-1, but we add 1 to all indexes
            // and use 0 as a sentinel value
            set._indexes[value] = set._values.length;
            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function _remove(Set storage set, bytes32 value) private returns (bool) {
        // We read and store the value's index to prevent multiple reads from the same storage slot
        uint256 valueIndex = set._indexes[value];

        if (valueIndex != 0) {
            // Equivalent to contains(set, value)
            // To delete an element from the _values array in O(1), we swap the element to delete with the last one in
            // the array, and then remove the last element (sometimes called as 'swap and pop').
            // This modifies the order of the array, as noted in {at}.

            uint256 toDeleteIndex = valueIndex - 1;
            uint256 lastIndex = set._values.length - 1;

            if (lastIndex != toDeleteIndex) {
                bytes32 lastValue = set._values[lastIndex];

                // Move the last value to the index where the value to delete is
                set._values[toDeleteIndex] = lastValue;
                // Update the index for the moved value
                set._indexes[lastValue] = valueIndex; // Replace lastValue's index to valueIndex
            }

            // Delete the slot where the moved value was stored
            set._values.pop();

            // Delete the index for the deleted slot
            delete set._indexes[value];

            return true;
        } else {
            return false;
        }
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function _contains(Set storage set, bytes32 value) private view returns (bool) {
        return set._indexes[value] != 0;
    }

    /**
     * @dev Returns the number of values on the set. O(1).
     */
    function _length(Set storage set) private view returns (uint256) {
        return set._values.length;
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function _at(Set storage set, uint256 index) private view returns (bytes32) {
        return set._values[index];
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function _values(Set storage set) private view returns (bytes32[] memory) {
        return set._values;
    }

    // Bytes32Set

    struct Bytes32Set {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _add(set._inner, value);
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(Bytes32Set storage set, bytes32 value) internal returns (bool) {
        return _remove(set._inner, value);
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(Bytes32Set storage set, bytes32 value) internal view returns (bool) {
        return _contains(set._inner, value);
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(Bytes32Set storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(Bytes32Set storage set, uint256 index) internal view returns (bytes32) {
        return _at(set._inner, index);
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(Bytes32Set storage set) internal view returns (bytes32[] memory) {
        bytes32[] memory store = _values(set._inner);
        bytes32[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // AddressSet

    struct AddressSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(AddressSet storage set, address value) internal returns (bool) {
        return _add(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(AddressSet storage set, address value) internal returns (bool) {
        return _remove(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(AddressSet storage set, address value) internal view returns (bool) {
        return _contains(set._inner, bytes32(uint256(uint160(value))));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(AddressSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(AddressSet storage set, uint256 index) internal view returns (address) {
        return address(uint160(uint256(_at(set._inner, index))));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(AddressSet storage set) internal view returns (address[] memory) {
        bytes32[] memory store = _values(set._inner);
        address[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }

    // UintSet

    struct UintSet {
        Set _inner;
    }

    /**
     * @dev Add a value to a set. O(1).
     *
     * Returns true if the value was added to the set, that is if it was not
     * already present.
     */
    function add(UintSet storage set, uint256 value) internal returns (bool) {
        return _add(set._inner, bytes32(value));
    }

    /**
     * @dev Removes a value from a set. O(1).
     *
     * Returns true if the value was removed from the set, that is if it was
     * present.
     */
    function remove(UintSet storage set, uint256 value) internal returns (bool) {
        return _remove(set._inner, bytes32(value));
    }

    /**
     * @dev Returns true if the value is in the set. O(1).
     */
    function contains(UintSet storage set, uint256 value) internal view returns (bool) {
        return _contains(set._inner, bytes32(value));
    }

    /**
     * @dev Returns the number of values in the set. O(1).
     */
    function length(UintSet storage set) internal view returns (uint256) {
        return _length(set._inner);
    }

    /**
     * @dev Returns the value stored at position `index` in the set. O(1).
     *
     * Note that there are no guarantees on the ordering of values inside the
     * array, and it may change when more values are added or removed.
     *
     * Requirements:
     *
     * - `index` must be strictly less than {length}.
     */
    function at(UintSet storage set, uint256 index) internal view returns (uint256) {
        return uint256(_at(set._inner, index));
    }

    /**
     * @dev Return the entire set in an array
     *
     * WARNING: This operation will copy the entire storage to memory, which can be quite expensive. This is designed
     * to mostly be used by view accessors that are queried without any gas fees. Developers should keep in mind that
     * this function has an unbounded cost, and using it as part of a state-changing function may render the function
     * uncallable if the set grows to a point where copying to memory consumes too much gas to fit in a block.
     */
    function values(UintSet storage set) internal view returns (uint256[] memory) {
        bytes32[] memory store = _values(set._inner);
        uint256[] memory result;

        /// @solidity memory-safe-assembly
        assembly {
            result := store
        }

        return result;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (proxy/ERC1967/ERC1967Upgrade.sol)

pragma solidity ^0.8.2;

import "./IBeaconUpgradeable.sol";
import "./draft-IERC1822Upgradeable.sol";
import "./AddressUpgradeable.sol";
import "./StorageSlotUpgradeable.sol";
import "./Initializable.sol";

/**
 * @dev This abstract contract provides getters and event emitting update functions for
 * https://eips.ethereum.org/EIPS/eip-1967[EIP1967] slots.
 *
 * _Available since v4.1._
 *
 * @custom:oz-upgrades-unsafe-allow delegatecall
 */
abstract contract ERC1967UpgradeUpgradeable is Initializable {
    function __ERC1967Upgrade_init() internal onlyInitializing {
    }

    function __ERC1967Upgrade_init_unchained() internal onlyInitializing {
    }
    // This is the keccak-256 hash of "eip1967.proxy.rollback" subtracted by 1
    bytes32 private constant _ROLLBACK_SLOT = 0x4910fdfa16fed3260ed0e7147f7cc6da11a60208b5b9406d12a635614ffd9143;

    /**
     * @dev Storage slot with the address of the current implementation.
     * This is the keccak-256 hash of "eip1967.proxy.implementation" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;

    /**
     * @dev Emitted when the implementation is upgraded.
     */
    event Upgraded(address indexed implementation);

    /**
     * @dev Returns the current implementation address.
     */
    function _getImplementation() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 implementation slot.
     */
    function _setImplementation(address newImplementation) private {
        require(AddressUpgradeable.isContract(newImplementation), "ERC1967: new implementation is not a contract");
        StorageSlotUpgradeable.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
    }

    /**
     * @dev Perform implementation upgrade
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeTo(address newImplementation) internal {
        _setImplementation(newImplementation);
        emit Upgraded(newImplementation);
    }

    /**
     * @dev Perform implementation upgrade with additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCall(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        _upgradeTo(newImplementation);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(newImplementation, data);
        }
    }

    /**
     * @dev Perform implementation upgrade with security checks for UUPS proxies, and additional setup call.
     *
     * Emits an {Upgraded} event.
     */
    function _upgradeToAndCallUUPS(
        address newImplementation,
        bytes memory data,
        bool forceCall
    ) internal {
        // Upgrades from old implementations will perform a rollback test. This test requires the new
        // implementation to upgrade back to the old, non-ERC1822 compliant, implementation. Removing
        // this special case will break upgrade paths from old UUPS implementation to new ones.
        if (StorageSlotUpgradeable.getBooleanSlot(_ROLLBACK_SLOT).value) {
            _setImplementation(newImplementation);
        } else {
            try IERC1822ProxiableUpgradeable(newImplementation).proxiableUUID() returns (bytes32 slot) {
                require(slot == _IMPLEMENTATION_SLOT, "ERC1967Upgrade: unsupported proxiableUUID");
            } catch {
                revert("ERC1967Upgrade: new implementation is not UUPS");
            }
            _upgradeToAndCall(newImplementation, data, forceCall);
        }
    }

    /**
     * @dev Storage slot with the admin of the contract.
     * This is the keccak-256 hash of "eip1967.proxy.admin" subtracted by 1, and is
     * validated in the constructor.
     */
    bytes32 internal constant _ADMIN_SLOT = 0xb53127684a568b3173ae13b9f8a6016e243e63b6e8ee1178d6a717850b5d6103;

    /**
     * @dev Emitted when the admin account has changed.
     */
    event AdminChanged(address previousAdmin, address newAdmin);

    /**
     * @dev Returns the current admin.
     */
    function _getAdmin() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value;
    }

    /**
     * @dev Stores a new address in the EIP1967 admin slot.
     */
    function _setAdmin(address newAdmin) private {
        require(newAdmin != address(0), "ERC1967: new admin is the zero address");
        StorageSlotUpgradeable.getAddressSlot(_ADMIN_SLOT).value = newAdmin;
    }

    /**
     * @dev Changes the admin of the proxy.
     *
     * Emits an {AdminChanged} event.
     */
    function _changeAdmin(address newAdmin) internal {
        emit AdminChanged(_getAdmin(), newAdmin);
        _setAdmin(newAdmin);
    }

    /**
     * @dev The storage slot of the UpgradeableBeacon contract which defines the implementation for this proxy.
     * This is bytes32(uint256(keccak256('eip1967.proxy.beacon')) - 1)) and is validated in the constructor.
     */
    bytes32 internal constant _BEACON_SLOT = 0xa3f0ad74e5423aebfd80d3ef4346578335a9a72aeaee59ff6cb3582b35133d50;

    /**
     * @dev Emitted when the beacon is upgraded.
     */
    event BeaconUpgraded(address indexed beacon);

    /**
     * @dev Returns the current beacon.
     */
    function _getBeacon() internal view returns (address) {
        return StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value;
    }

    /**
     * @dev Stores a new beacon in the EIP1967 beacon slot.
     */
    function _setBeacon(address newBeacon) private {
        require(AddressUpgradeable.isContract(newBeacon), "ERC1967: new beacon is not a contract");
        require(
            AddressUpgradeable.isContract(IBeaconUpgradeable(newBeacon).implementation()),
            "ERC1967: beacon implementation is not a contract"
        );
        StorageSlotUpgradeable.getAddressSlot(_BEACON_SLOT).value = newBeacon;
    }

    /**
     * @dev Perform beacon upgrade with additional setup call. Note: This upgrades the address of the beacon, it does
     * not upgrade the implementation contained in the beacon (see {UpgradeableBeacon-_setImplementation} for that).
     *
     * Emits a {BeaconUpgraded} event.
     */
    function _upgradeBeaconToAndCall(
        address newBeacon,
        bytes memory data,
        bool forceCall
    ) internal {
        _setBeacon(newBeacon);
        emit BeaconUpgraded(newBeacon);
        if (data.length > 0 || forceCall) {
            _functionDelegateCall(IBeaconUpgradeable(newBeacon).implementation(), data);
        }
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a delegate call.
     *
     * _Available since v3.4._
     */
    function _functionDelegateCall(address target, bytes memory data) private returns (bytes memory) {
        require(AddressUpgradeable.isContract(target), "Address: delegate call to non-contract");

        // solhint-disable-next-line avoid-low-level-calls
        (bool success, bytes memory returndata) = target.delegatecall(data);
        return AddressUpgradeable.verifyCallResult(success, returndata, "Address: low-level delegate call failed");
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.5.0) (interfaces/draft-IERC1822.sol)

pragma solidity ^0.8.0;

/**
 * @dev ERC1822: Universal Upgradeable Proxy Standard (UUPS) documents a method for upgradeability through a simplified
 * proxy whose upgrades are fully controlled by the current implementation.
 */
interface IERC1822ProxiableUpgradeable {
    /**
     * @dev Returns the storage slot that the proxiable contract assumes is being used to store the implementation
     * address.
     *
     * IMPORTANT: A proxy pointing at a proxiable contract should not be considered proxiable itself, because this risks
     * bricking a proxy that upgrades to it, by delegating to itself until out of gas. Thus it is critical that this
     * function revert if invoked through a proxy.
     */
    function proxiableUUID() external view returns (bytes32);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Address.sol)

pragma solidity ^0.8.1;

/**
 * @dev Collection of functions related to the address type
 */
library AddressUpgradeable {
    /**
     * @dev Returns true if `account` is a contract.
     *
     * [IMPORTANT]
     * ====
     * It is unsafe to assume that an address for which this function returns
     * false is an externally-owned account (EOA) and not a contract.
     *
     * Among others, `isContract` will return false for the following
     * types of addresses:
     *
     *  - an externally-owned account
     *  - a contract in construction
     *  - an address where a contract will be created
     *  - an address where a contract lived, but was destroyed
     * ====
     *
     * [IMPORTANT]
     * ====
     * You shouldn't rely on `isContract` to protect against flash loan attacks!
     *
     * Preventing calls from contracts is highly discouraged. It breaks composability, breaks support for smart wallets
     * like Gnosis Safe, and does not provide security since it can be circumvented by calling from a contract
     * constructor.
     * ====
     */
    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize/address.code.length, which returns 0
        // for contracts in construction, since the code is only stored at the end
        // of the constructor execution.

        return account.code.length > 0;
    }

    /**
     * @dev Replacement for Solidity's `transfer`: sends `amount` wei to
     * `recipient`, forwarding all available gas and reverting on errors.
     *
     * https://eips.ethereum.org/EIPS/eip-1884[EIP1884] increases the gas cost
     * of certain opcodes, possibly making contracts go over the 2300 gas limit
     * imposed by `transfer`, making them unable to receive funds via
     * `transfer`. {sendValue} removes this limitation.
     *
     * https://diligence.consensys.net/posts/2019/09/stop-using-soliditys-transfer-now/[Learn more].
     *
     * IMPORTANT: because control is transferred to `recipient`, care must be
     * taken to not create reentrancy vulnerabilities. Consider using
     * {ReentrancyGuard} or the
     * https://solidity.readthedocs.io/en/v0.5.11/security-considerations.html#use-the-checks-effects-interactions-pattern[checks-effects-interactions pattern].
     */
    function sendValue(address payable recipient, uint256 amount) internal {
        require(address(this).balance >= amount, "Address: insufficient balance");

        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Address: unable to send value, recipient may have reverted");
    }

    /**
     * @dev Performs a Solidity function call using a low level `call`. A
     * plain `call` is an unsafe replacement for a function call: use this
     * function instead.
     *
     * If `target` reverts with a revert reason, it is bubbled up by this
     * function (like regular Solidity function calls).
     *
     * Returns the raw returned data. To convert to the expected return value,
     * use https://solidity.readthedocs.io/en/latest/units-and-global-variables.html?highlight=abi.decode#abi-encoding-and-decoding-functions[`abi.decode`].
     *
     * Requirements:
     *
     * - `target` must be a contract.
     * - calling `target` with `data` must not revert.
     *
     * _Available since v3.1._
     */
    function functionCall(address target, bytes memory data) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, "Address: low-level call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`], but with
     * `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, 0, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but also transferring `value` wei to `target`.
     *
     * Requirements:
     *
     * - the calling contract must have an ETH balance of at least `value`.
     * - the called Solidity function must be `payable`.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value
    ) internal returns (bytes memory) {
        return functionCallWithValue(target, data, value, "Address: low-level call with value failed");
    }

    /**
     * @dev Same as {xref-Address-functionCallWithValue-address-bytes-uint256-}[`functionCallWithValue`], but
     * with `errorMessage` as a fallback revert reason when `target` reverts.
     *
     * _Available since v3.1._
     */
    function functionCallWithValue(
        address target,
        bytes memory data,
        uint256 value,
        string memory errorMessage
    ) internal returns (bytes memory) {
        require(address(this).balance >= value, "Address: insufficient balance for call");
        (bool success, bytes memory returndata) = target.call{value: value}(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(address target, bytes memory data) internal view returns (bytes memory) {
        return functionStaticCall(target, data, "Address: low-level static call failed");
    }

    /**
     * @dev Same as {xref-Address-functionCall-address-bytes-string-}[`functionCall`],
     * but performing a static call.
     *
     * _Available since v3.3._
     */
    function functionStaticCall(
        address target,
        bytes memory data,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        (bool success, bytes memory returndata) = target.staticcall(data);
        return verifyCallResultFromTarget(target, success, returndata, errorMessage);
    }

    /**
     * @dev Tool to verify that a low level call to smart-contract was successful, and revert (either by bubbling
     * the revert reason or using the provided one) in case of unsuccessful call or if target was not a contract.
     *
     * _Available since v4.8._
     */
    function verifyCallResultFromTarget(
        address target,
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal view returns (bytes memory) {
        if (success) {
            if (returndata.length == 0) {
                // only check isContract if the call was successful and the return data is empty
                // otherwise we already know that it was a contract
                require(isContract(target), "Address: call to non-contract");
            }
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    /**
     * @dev Tool to verify that a low level call was successful, and revert if it wasn't, either by bubbling the
     * revert reason or using the provided one.
     *
     * _Available since v4.3._
     */
    function verifyCallResult(
        bool success,
        bytes memory returndata,
        string memory errorMessage
    ) internal pure returns (bytes memory) {
        if (success) {
            return returndata;
        } else {
            _revert(returndata, errorMessage);
        }
    }

    function _revert(bytes memory returndata, string memory errorMessage) private pure {
        // Look for revert reason and bubble it up if present
        if (returndata.length > 0) {
            // The easiest way to bubble the revert reason is using memory via assembly
            /// @solidity memory-safe-assembly
            assembly {
                let returndata_size := mload(returndata)
                revert(add(32, returndata), returndata_size)
            }
        } else {
            revert(errorMessage);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
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
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/ERC165.sol)

pragma solidity ^0.8.0;

import "./IERC165Upgradeable.sol";
import "./Initializable.sol";

/**
 * @dev Implementation of the {IERC165} interface.
 *
 * Contracts that want to implement ERC165 should inherit from this contract and override {supportsInterface} to check
 * for the additional interface id that will be supported. For example:
 *
 * ```solidity
 * function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
 *     return interfaceId == type(MyInterface).interfaceId || super.supportsInterface(interfaceId);
 * }
 * ```
 *
 * Alternatively, {ERC165Storage} provides an easier to use but more expensive implementation.
 */
abstract contract ERC165Upgradeable is Initializable, IERC165Upgradeable {
    function __ERC165_init() internal onlyInitializing {
    }

    function __ERC165_init_unchained() internal onlyInitializing {
    }
    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
        return interfaceId == type(IERC165Upgradeable).interfaceId;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/Strings.sol)

pragma solidity ^0.8.0;

import "./MathUpgradeable.sol";

/**
 * @dev String operations.
 */
library StringsUpgradeable {
    bytes16 private constant _SYMBOLS = "0123456789abcdef";
    uint8 private constant _ADDRESS_LENGTH = 20;

    /**
     * @dev Converts a `uint256` to its ASCII `string` decimal representation.
     */
    function toString(uint256 value) internal pure returns (string memory) {
        unchecked {
            uint256 length = MathUpgradeable.log10(value) + 1;
            string memory buffer = new string(length);
            uint256 ptr;
            /// @solidity memory-safe-assembly
            assembly {
                ptr := add(buffer, add(32, length))
            }
            while (true) {
                ptr--;
                /// @solidity memory-safe-assembly
                assembly {
                    mstore8(ptr, byte(mod(value, 10), _SYMBOLS))
                }
                value /= 10;
                if (value == 0) break;
            }
            return buffer;
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation.
     */
    function toHexString(uint256 value) internal pure returns (string memory) {
        unchecked {
            return toHexString(value, MathUpgradeable.log256(value) + 1);
        }
    }

    /**
     * @dev Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length.
     */
    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            buffer[i] = _SYMBOLS[value & 0xf];
            value >>= 4;
        }
        require(value == 0, "Strings: hex length insufficient");
        return string(buffer);
    }

    /**
     * @dev Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
     */
    function toHexString(address addr) internal pure returns (string memory) {
        return toHexString(uint256(uint160(addr)), _ADDRESS_LENGTH);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

pragma solidity ^0.8.0;
import "./Initializable.sol";

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
abstract contract ContextUpgradeable is Initializable {
    function __Context_init() internal onlyInitializing {
    }

    function __Context_init_unchained() internal onlyInitializing {
    }
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (access/IAccessControl.sol)

pragma solidity ^0.8.0;

/**
 * @dev External interface of AccessControl declared to support ERC165 detection.
 */
interface IAccessControlUpgradeable {
    /**
     * @dev Emitted when `newAdminRole` is set as ``role``'s admin role, replacing `previousAdminRole`
     *
     * `DEFAULT_ADMIN_ROLE` is the starting admin for all roles, despite
     * {RoleAdminChanged} not being emitted signaling this.
     *
     * _Available since v3.1._
     */
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);

    /**
     * @dev Emitted when `account` is granted `role`.
     *
     * `sender` is the account that originated the contract call, an admin role
     * bearer except when using {AccessControl-_setupRole}.
     */
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Emitted when `account` is revoked `role`.
     *
     * `sender` is the account that originated the contract call:
     *   - if using `revokeRole`, it is the admin role bearer
     *   - if using `renounceRole`, it is the role bearer (i.e. `account`)
     */
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);

    /**
     * @dev Returns `true` if `account` has been granted `role`.
     */
    function hasRole(bytes32 role, address account) external view returns (bool);

    /**
     * @dev Returns the admin role that controls `role`. See {grantRole} and
     * {revokeRole}.
     *
     * To change a role's admin, use {AccessControl-_setRoleAdmin}.
     */
    function getRoleAdmin(bytes32 role) external view returns (bytes32);

    /**
     * @dev Grants `role` to `account`.
     *
     * If `account` had not been already granted `role`, emits a {RoleGranted}
     * event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function grantRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from `account`.
     *
     * If `account` had been granted `role`, emits a {RoleRevoked} event.
     *
     * Requirements:
     *
     * - the caller must have ``role``'s admin role.
     */
    function revokeRole(bytes32 role, address account) external;

    /**
     * @dev Revokes `role` from the calling account.
     *
     * Roles are often managed via {grantRole} and {revokeRole}: this function's
     * purpose is to provide a mechanism for accounts to lose their privileges
     * if they are compromised (such as when a trusted device is misplaced).
     *
     * If the calling account had been granted `role`, emits a {RoleRevoked}
     * event.
     *
     * Requirements:
     *
     * - the caller must be `account`.
     */
    function renounceRole(bytes32 role, address account) external;
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/math/Math.sol)

pragma solidity ^0.8.0;

/**
 * @dev Standard math utilities missing in the Solidity language.
 */
library MathUpgradeable {
    enum Rounding {
        Down, // Toward negative infinity
        Up, // Toward infinity
        Zero // Toward zero
    }

    /**
     * @dev Returns the largest of two numbers.
     */
    function max(uint256 a, uint256 b) internal pure returns (uint256) {
        return a > b ? a : b;
    }

    /**
     * @dev Returns the smallest of two numbers.
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }

    /**
     * @dev Returns the average of two numbers. The result is rounded towards
     * zero.
     */
    function average(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b) / 2 can overflow.
        return (a & b) + (a ^ b) / 2;
    }

    /**
     * @dev Returns the ceiling of the division of two numbers.
     *
     * This differs from standard division with `/` in that it rounds up instead
     * of rounding down.
     */
    function ceilDiv(uint256 a, uint256 b) internal pure returns (uint256) {
        // (a + b - 1) / b can overflow on addition, so we distribute.
        return a == 0 ? 0 : (a - 1) / b + 1;
    }

    /**
     * @notice Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0
     * @dev Original credit to Remco Bloemen under MIT license (https://xn--2-umb.com/21/muldiv)
     * with further edits by Uniswap Labs also under MIT license.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator
    ) internal pure returns (uint256 result) {
        unchecked {
            // 512-bit multiply [prod1 prod0] = x * y. Compute the product mod 2^256 and mod 2^256 - 1, then use
            // use the Chinese Remainder Theorem to reconstruct the 512 bit result. The result is stored in two 256
            // variables such that product = prod1 * 2^256 + prod0.
            uint256 prod0; // Least significant 256 bits of the product
            uint256 prod1; // Most significant 256 bits of the product
            assembly {
                let mm := mulmod(x, y, not(0))
                prod0 := mul(x, y)
                prod1 := sub(sub(mm, prod0), lt(mm, prod0))
            }

            // Handle non-overflow cases, 256 by 256 division.
            if (prod1 == 0) {
                return prod0 / denominator;
            }

            // Make sure the result is less than 2^256. Also prevents denominator == 0.
            require(denominator > prod1);

            ///////////////////////////////////////////////
            // 512 by 256 division.
            ///////////////////////////////////////////////

            // Make division exact by subtracting the remainder from [prod1 prod0].
            uint256 remainder;
            assembly {
                // Compute remainder using mulmod.
                remainder := mulmod(x, y, denominator)

                // Subtract 256 bit number from 512 bit number.
                prod1 := sub(prod1, gt(remainder, prod0))
                prod0 := sub(prod0, remainder)
            }

            // Factor powers of two out of denominator and compute largest power of two divisor of denominator. Always >= 1.
            // See https://cs.stackexchange.com/q/138556/92363.

            // Does not overflow because the denominator cannot be zero at this stage in the function.
            uint256 twos = denominator & (~denominator + 1);
            assembly {
                // Divide denominator by twos.
                denominator := div(denominator, twos)

                // Divide [prod1 prod0] by twos.
                prod0 := div(prod0, twos)

                // Flip twos such that it is 2^256 / twos. If twos is zero, then it becomes one.
                twos := add(div(sub(0, twos), twos), 1)
            }

            // Shift in bits from prod1 into prod0.
            prod0 |= prod1 * twos;

            // Invert denominator mod 2^256. Now that denominator is an odd number, it has an inverse modulo 2^256 such
            // that denominator * inv = 1 mod 2^256. Compute the inverse by starting with a seed that is correct for
            // four bits. That is, denominator * inv = 1 mod 2^4.
            uint256 inverse = (3 * denominator) ^ 2;

            // Use the Newton-Raphson iteration to improve the precision. Thanks to Hensel's lifting lemma, this also works
            // in modular arithmetic, doubling the correct bits in each step.
            inverse *= 2 - denominator * inverse; // inverse mod 2^8
            inverse *= 2 - denominator * inverse; // inverse mod 2^16
            inverse *= 2 - denominator * inverse; // inverse mod 2^32
            inverse *= 2 - denominator * inverse; // inverse mod 2^64
            inverse *= 2 - denominator * inverse; // inverse mod 2^128
            inverse *= 2 - denominator * inverse; // inverse mod 2^256

            // Because the division is now exact we can divide by multiplying with the modular inverse of denominator.
            // This will give us the correct result modulo 2^256. Since the preconditions guarantee that the outcome is
            // less than 2^256, this is the final result. We don't need to compute the high bits of the result and prod1
            // is no longer required.
            result = prod0 * inverse;
            return result;
        }
    }

    /**
     * @notice Calculates x * y / denominator with full precision, following the selected rounding direction.
     */
    function mulDiv(
        uint256 x,
        uint256 y,
        uint256 denominator,
        Rounding rounding
    ) internal pure returns (uint256) {
        uint256 result = mulDiv(x, y, denominator);
        if (rounding == Rounding.Up && mulmod(x, y, denominator) > 0) {
            result += 1;
        }
        return result;
    }

    /**
     * @dev Returns the square root of a number. If the number is not a perfect square, the value is rounded down.
     *
     * Inspired by Henry S. Warren, Jr.'s "Hacker's Delight" (Chapter 11).
     */
    function sqrt(uint256 a) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        // For our first guess, we get the biggest power of 2 which is smaller than the square root of the target.
        //
        // We know that the "msb" (most significant bit) of our target number `a` is a power of 2 such that we have
        // `msb(a) <= a < 2*msb(a)`. This value can be written `msb(a)=2**k` with `k=log2(a)`.
        //
        // This can be rewritten `2**log2(a) <= a < 2**(log2(a) + 1)`
        // → `sqrt(2**k) <= sqrt(a) < sqrt(2**(k+1))`
        // → `2**(k/2) <= sqrt(a) < 2**((k+1)/2) <= 2**(k/2 + 1)`
        //
        // Consequently, `2**(log2(a) / 2)` is a good first approximation of `sqrt(a)` with at least 1 correct bit.
        uint256 result = 1 << (log2(a) >> 1);

        // At this point `result` is an estimation with one bit of precision. We know the true value is a uint128,
        // since it is the square root of a uint256. Newton's method converges quadratically (precision doubles at
        // every iteration). We thus need at most 7 iteration to turn our partial result with one bit of precision
        // into the expected uint128 result.
        unchecked {
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            result = (result + a / result) >> 1;
            return min(result, a / result);
        }
    }

    /**
     * @notice Calculates sqrt(a), following the selected rounding direction.
     */
    function sqrt(uint256 a, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = sqrt(a);
            return result + (rounding == Rounding.Up && result * result < a ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 2, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 128;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 64;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 32;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 16;
            }
            if (value >> 8 > 0) {
                value >>= 8;
                result += 8;
            }
            if (value >> 4 > 0) {
                value >>= 4;
                result += 4;
            }
            if (value >> 2 > 0) {
                value >>= 2;
                result += 2;
            }
            if (value >> 1 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 2, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log2(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log2(value);
            return result + (rounding == Rounding.Up && 1 << result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 10, rounded down, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >= 10**64) {
                value /= 10**64;
                result += 64;
            }
            if (value >= 10**32) {
                value /= 10**32;
                result += 32;
            }
            if (value >= 10**16) {
                value /= 10**16;
                result += 16;
            }
            if (value >= 10**8) {
                value /= 10**8;
                result += 8;
            }
            if (value >= 10**4) {
                value /= 10**4;
                result += 4;
            }
            if (value >= 10**2) {
                value /= 10**2;
                result += 2;
            }
            if (value >= 10**1) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log10(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log10(value);
            return result + (rounding == Rounding.Up && 10**result < value ? 1 : 0);
        }
    }

    /**
     * @dev Return the log in base 256, rounded down, of a positive value.
     * Returns 0 if given 0.
     *
     * Adding one to the result gives the number of pairs of hex symbols needed to represent `value` as a hex string.
     */
    function log256(uint256 value) internal pure returns (uint256) {
        uint256 result = 0;
        unchecked {
            if (value >> 128 > 0) {
                value >>= 128;
                result += 16;
            }
            if (value >> 64 > 0) {
                value >>= 64;
                result += 8;
            }
            if (value >> 32 > 0) {
                value >>= 32;
                result += 4;
            }
            if (value >> 16 > 0) {
                value >>= 16;
                result += 2;
            }
            if (value >> 8 > 0) {
                result += 1;
            }
        }
        return result;
    }

    /**
     * @dev Return the log in base 10, following the selected rounding direction, of a positive value.
     * Returns 0 if given 0.
     */
    function log256(uint256 value, Rounding rounding) internal pure returns (uint256) {
        unchecked {
            uint256 result = log256(value);
            return result + (rounding == Rounding.Up && 1 << (result * 8) < value ? 1 : 0);
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (utils/StorageSlot.sol)

pragma solidity ^0.8.0;

/**
 * @dev Library for reading and writing primitive types to specific storage slots.
 *
 * Storage slots are often used to avoid storage conflict when dealing with upgradeable contracts.
 * This library helps with reading and writing to such slots without the need for inline assembly.
 *
 * The functions in this library return Slot structs that contain a `value` member that can be used to read or write.
 *
 * Example usage to set ERC1967 implementation slot:
 * ```
 * contract ERC1967 {
 *     bytes32 internal constant _IMPLEMENTATION_SLOT = 0x360894a13ba1a3210667c828492db98dca3e2076cc3735a920a3ca505d382bbc;
 *
 *     function _getImplementation() internal view returns (address) {
 *         return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
 *     }
 *
 *     function _setImplementation(address newImplementation) internal {
 *         require(Address.isContract(newImplementation), "ERC1967: new implementation is not a contract");
 *         StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value = newImplementation;
 *     }
 * }
 * ```
 *
 * _Available since v4.1 for `address`, `bool`, `bytes32`, and `uint256`._
 */
library StorageSlotUpgradeable {
    struct AddressSlot {
        address value;
    }

    struct BooleanSlot {
        bool value;
    }

    struct Bytes32Slot {
        bytes32 value;
    }

    struct Uint256Slot {
        uint256 value;
    }

    /**
     * @dev Returns an `AddressSlot` with member `value` located at `slot`.
     */
    function getAddressSlot(bytes32 slot) internal pure returns (AddressSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `BooleanSlot` with member `value` located at `slot`.
     */
    function getBooleanSlot(bytes32 slot) internal pure returns (BooleanSlot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Bytes32Slot` with member `value` located at `slot`.
     */
    function getBytes32Slot(bytes32 slot) internal pure returns (Bytes32Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }

    /**
     * @dev Returns an `Uint256Slot` with member `value` located at `slot`.
     */
    function getUint256Slot(bytes32 slot) internal pure returns (Uint256Slot storage r) {
        /// @solidity memory-safe-assembly
        assembly {
            r.slot := slot
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (proxy/beacon/IBeacon.sol)

pragma solidity ^0.8.0;

/**
 * @dev This is the interface that {BeaconProxy} expects of its beacon.
 */
interface IBeaconUpgradeable {
    /**
     * @dev Must return an address that can be used as a delegate call target.
     *
     * {BeaconProxy} will check that this address is a contract.
     */
    function implementation() external view returns (address);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/introspection/IERC165.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC165 standard, as defined in the
 * https://eips.ethereum.org/EIPS/eip-165[EIP].
 *
 * Implementers can declare support of contract interfaces, which can then be
 * queried by others ({ERC165Checker}).
 *
 * For an implementation, see {ERC165}.
 */
interface IERC165Upgradeable {
    /**
     * @dev Returns true if this contract implements the interface defined by
     * `interfaceId`. See the corresponding
     * https://eips.ethereum.org/EIPS/eip-165#how-interfaces-are-identified[EIP section]
     * to learn more about how these ids are created.
     *
     * This function call must use less than 30 000 gas.
     */
    function supportsInterface(bytes4 interfaceId) external view returns (bool);
}