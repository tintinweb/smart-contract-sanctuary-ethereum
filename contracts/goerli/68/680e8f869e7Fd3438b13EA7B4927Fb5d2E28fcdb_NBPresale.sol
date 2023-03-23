// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "../node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "./IAggregatorV3.sol";

contract NBPresale is Ownable, ReentrancyGuard {
    bool public isPresaleActive = true;
    bool public isWithdrawingAllowed = false;

    uint256 public currentRound; // 0 = first round, 46 = last round
    uint256 public affiliateBonusPercentage;
    uint256 public minimumUsdtInvestment;

    uint256[] public tokenUnitPriceUsd; // scale is 100,000 ( 1 USD = 100,000)
    uint256[] public roundRewardPoolArray;

    uint256 public totalUsdtRaised;
    uint256 public totalTokensMinted;

    address public affiliateRewardAddress;
    address public usdtAddress;
    address public usdcAddress;

    mapping(address => uint256) public unclaimedBalance;
    mapping(address => uint256) public unclaimedRefferalBalance;
    mapping(uint256 => uint256) public amountRaisedInRound; // tokens

    IERC20 public token;
    IERC20 public usdt;
    IERC20 public usdc;

    IAggregatorV3 internal priceFeed;

    event TokensPurchased(
        address indexed buyer,
        uint256 usdAmount,
        uint256 tokenAmount
    );

    event TokensClaimed(address indexed buyer, uint256 tokenAmount);

    event ETHSurplusRefunded(uint256 ethAmount);

    /**
     * @dev Constructor functions, called once when contract is deployed
     */

    constructor(
        address _tokenAddress,
        address _usdtAddress,
        address _usdcAddress,
        address _affiliateRewardAddress,
        uint256 _affiliateBonusPercentage,
        uint256 _minimumUsdtInvestment,
        uint256[] memory _tokenUnitPriceUsd,
        uint256[] memory _roundRewardPoolArray,
        address _priceFeedAddress
    ) {
        token = IERC20(_tokenAddress);
        usdt = IERC20(_usdtAddress);
        usdc = IERC20(_usdcAddress);
        affiliateRewardAddress = _affiliateRewardAddress;
        affiliateBonusPercentage = _affiliateBonusPercentage;
        minimumUsdtInvestment = _minimumUsdtInvestment;
        tokenUnitPriceUsd = _tokenUnitPriceUsd;
        roundRewardPoolArray = _roundRewardPoolArray;
        priceFeed = IAggregatorV3(_priceFeedAddress);
    }

    /**
     * @dev Changes the contract settings
     * @param _tokenAddress The address of the token contract (NET)
     * @param _usdtAddress The address of the USDT contract
     * @param _usdcAddress The address of the USDC contract
     * @param _affiliateRewardAddress The address of the affiliate reward contract from where the rewards are sent from
     * @param _affiliateBonusPercentage The percentage of the affiliate bonus
     * @param _minimumUsdtInvestment The minimum amount of USDT that can be invested
     * @param _tokenUnitPriceUsd The price of the token in USD (scale is 100,000)
     * @param _roundRewardPoolArray The reward pool for each round (wei)
     * @param _priceFeedAddress The address of the Chainlink price feed
     */
    function changeContractSettings(
        address _tokenAddress,
        address _usdtAddress,
        address _usdcAddress,
        address _affiliateRewardAddress,
        uint256 _affiliateBonusPercentage,
        uint256 _minimumUsdtInvestment,
        uint256[] memory _tokenUnitPriceUsd,
        uint256[] memory _roundRewardPoolArray,
        address _priceFeedAddress
    ) public onlyOwner {
        token = IERC20(_tokenAddress);
        usdt = IERC20(_usdtAddress);
        usdc = IERC20(_usdcAddress);
        affiliateRewardAddress = _affiliateRewardAddress;
        affiliateBonusPercentage = _affiliateBonusPercentage;
        minimumUsdtInvestment = _minimumUsdtInvestment;
        tokenUnitPriceUsd = _tokenUnitPriceUsd;
        roundRewardPoolArray = _roundRewardPoolArray;
        priceFeed = IAggregatorV3(_priceFeedAddress);
    }

    /**
     * @dev Get the ETH price in USD from the Chainlink price feed
     * @notice The price feed returns the price in wei (18 decimals)
     */
    function getEthPrice() public view returns (uint256) {
        (, int256 price, , , ) = priceFeed.latestRoundData();
        // Get ETH in wei scale
        return uint256(price * 1e10);
    }

    /**
     * @dev Convert ETH to USD using the Chainlink price feed
     * @notice The price feed returns the price in wei (18 decimals)
     */
    function convertEthToUsd(
        uint256 ethIn
    ) public view returns (uint256 usdOut) {
        uint256 ethPrice = getEthPrice();
        usdOut = (ethIn * ethPrice) / 1e18;
        return usdOut;
    }

    /**
     * @dev Convert USD to ETH using the Chainlink price feed
     * @notice The price feed returns the price in wei (18 decimals)
     */
    function convertUsdToEth(
        uint256 usdIn
    ) public view returns (uint256 ethOut) {
        uint256 ethPrice = getEthPrice();
        ethOut = (usdIn * 1e18) / ethPrice;
        return ethOut;
    }

    /**
     * @dev Enables or disables the presale
     * @param _isPresaleActive Whether the presale is active or not
     */
    function setPresaleActive(bool _isPresaleActive) public onlyOwner {
        isPresaleActive = _isPresaleActive;
    }

    /**
     * @dev Gets the current round price in USD, scale is 100,000 ( 1 USD = 100,000)
     * @return uint256 The current round price in USD
     */
    function getCurrentRoundPrice() public view returns (uint256) {
        return tokenUnitPriceUsd[currentRound];
    }

    /**
     * @dev Gets whether the current round is the last round
     * @return bool
     */
    function isLastRound() public view returns (bool) {
        return currentRound + 1 == roundRewardPoolArray.length;
    }

    /**
     * @dev Set whether withdrawing is allowed or not.
     * @notice Also hides claiming buttons from the UI
     * @param _isWithdrawingAllowed Whether withdrawing is allowed or not
     * @return bool Whether withdrawing is allowed or not
     */
    function setIsWithdrawingAllowed(
        bool _isWithdrawingAllowed
    ) public onlyOwner returns (bool) {
        isWithdrawingAllowed = _isWithdrawingAllowed;
        return isWithdrawingAllowed;
    }

    /**
     * @dev Gets the amount of tokens you will get for a given amount of USDT in a given round
     * @param usdtIn The amount of USDT which goes in
     * @param roundIndex The round index
     * @return uint256 The amount of tokens you will get
     */
    function getTokenRewardForUsdtInRound(
        uint256 usdtIn,
        uint256 roundIndex
    ) internal view returns (uint256) {
        return (usdtIn * 100000) / tokenUnitPriceUsd[roundIndex];
    }

    /**
     * @dev Gets the amount of USDT you will get for a given amount of tokens in a given round
     * @param tokens The amount of tokens which goes in
     * @param roundIndex The round index
     * @return uint256 The amount of USDT you will get
     */
    function getUsdtValueForTokens(
        uint256 tokens,
        uint256 roundIndex
    ) internal view returns (uint256) {
        return (tokens * tokenUnitPriceUsd[roundIndex]) / 100000;
    }

    /**
     * @dev Processes (registers) an amount of tokens in the contract (also distributes bonus)
     * @param tokensToMint The amount of tokens to mint
     * @param usdtIn The amount of USDT which goes in
     * @param refferal The address of the refferal
     * @param userWallet The address of the user wallet which buys the tokens
     */
    function processTokens(
        uint256 tokensToMint,
        uint256 usdtIn,
        address refferal,
        address userWallet
    ) internal {
        // Calculate the bonus
        if (refferal != address(0)) {
            // Calculate 20% percent of the tokens to mint
            uint256 tokensToMintBonus = (tokensToMint *
                affiliateBonusPercentage) / 100;
            unclaimedRefferalBalance[refferal] += tokensToMintBonus;
        }

        unclaimedBalance[userWallet] += tokensToMint;
        totalUsdtRaised += usdtIn;
        amountRaisedInRound[currentRound] += tokensToMint;
        totalTokensMinted += tokensToMint;

        emit TokensPurchased(userWallet, usdtIn, tokensToMint);
    }

    /**
     * @dev Does all the requires checks and processes the token buying
     * @notice This function is called by the buyTokensXXX functions
     * @notice Also moves into next round when needed
     * @param currency The currency used to buy tokens, IERC20(address(0)) for ETH (for ETH surplus refunding)
     * @param usdtIn The amount of USDT which goes in
     * @param refferal The address of the refferee (if any), address(0) if none
     * @param userWallet The address of the user's wallet which buys the tokens
     */
    function initializeTokenBuying(
        IERC20 currency,
        uint256 usdtIn,
        address refferal,
        address userWallet
    ) internal {
        require(isPresaleActive, "Presale has not started yet");

        require(usdtIn > 0, "Investment is 0");

        require(
            currentRound < roundRewardPoolArray.length,
            "Presale has ended"
        );

        require(
            usdtIn >= minimumUsdtInvestment,
            "Investment is less than minimum"
        );

        require(
          userWallet != refferal,
          "Refferal cannot be the same as the user"
        );

        // Calculate tokens to mint
        uint256 tokensRewardForSentUsdt = getTokenRewardForUsdtInRound(
            usdtIn,
            currentRound
        );

        uint256 currentRemainingTokensInRound = roundRewardPoolArray[
            currentRound
        ] - amountRaisedInRound[currentRound];

        // Reward for user is less than remaining tokens in round, so we don't need to move to next round
        if (tokensRewardForSentUsdt < currentRemainingTokensInRound) {
            processTokens(
                tokensRewardForSentUsdt,
                usdtIn,
                refferal,
                userWallet
            );
        } else if (
            tokensRewardForSentUsdt > currentRemainingTokensInRound &&
            currentRound + 1 == roundRewardPoolArray.length
        ) {
            // Reward for user is more than the remaining tokens in round, but we are in the last round, so we reward all the tokens remaining and don't move to the next round
            uint256 satisifableTokenAmount = currentRemainingTokensInRound;
            uint256 satisifableTokenAmountUsd = getUsdtValueForTokens(
                satisifableTokenAmount,
                currentRound
            );

            processTokens(
                satisifableTokenAmount,
                satisifableTokenAmountUsd,
                refferal,
                userWallet
            );

            uint256 surplusUsd = usdtIn - satisifableTokenAmountUsd;

            // Get the address of the currency contract
            address currencyAddress = address(currency);

            if (currencyAddress == address(0)) {
                // If currencyAddress is address(0), the currency is ETH, we need to refund the surplus in ETH
                uint256 ethSurplus = convertUsdToEth(surplusUsd);
                (bool sent, ) = payable(userWallet).call{value: ethSurplus}("");
                require(sent, "Failed to send Ether surplus");

                emit ETHSurplusRefunded(ethSurplus);
            } else {
                // Refund the surplus in the currency picked
                currency.transfer(userWallet, surplusUsd);
            }
            isPresaleActive = false;
        }
        // Reward for user is more than the remaining tokens in round, so we reward all the tokens remaining and move the others to the new round at the new rate
        else {
            uint256 satisifableTokenAmount = currentRemainingTokensInRound;
            uint256 satisifableTokenAmountUsd = getUsdtValueForTokens(
                satisifableTokenAmount,
                currentRound
            );

            uint256 surplusUsd = usdtIn - satisifableTokenAmountUsd;
            uint256 tokensRewardForSurplusUsd = getTokenRewardForUsdtInRound(
                surplusUsd,
                currentRound + 1
            );

            processTokens(
                satisifableTokenAmount,
                satisifableTokenAmountUsd,
                refferal,
                userWallet
            );

            currentRound += 1;

            processTokens(
                tokensRewardForSurplusUsd,
                surplusUsd,
                refferal,
                userWallet
            );
        }
    }

    /**
     * @dev Buys tokens with USDT, intialises buying process
     * @param usdtIn The amount of USDT to buy tokens with
     * @param refferal The address of the refferee (if any), address(0) if none
     */
    function buyTokensUSDT(uint256 usdtIn, address refferal) external {
        // Transfer the USDT to the contract
        usdt.transferFrom(msg.sender, address(this), usdtIn);
        initializeTokenBuying(usdt, usdtIn, refferal, msg.sender);
    }

    /**
     * @dev Buys tokens with USDC, intialises buying process
     * @param usdcIn The amount of USDC to buy tokens with
     * @param refferal The address of the refferee (if any), address(0) if none
     */
    function buyTokensUSDC(uint256 usdcIn, address refferal) external {
        // Transfer the USDT to the contract
        usdc.transferFrom(msg.sender, address(this), usdcIn);
        initializeTokenBuying(usdc, usdcIn, refferal, msg.sender);
    }

    /**
     * @dev Buys tokens with ETH, intialises buying process
     * @param refferal The address of the refferee (if any), address(0) if none
     * @notice The ETH sent is transformed (not swapped) to USDT and then used to buy tokens
     */
    function buyTokensETH(address refferal) external payable {
        uint256 usdtIn = convertEthToUsd(msg.value);
        initializeTokenBuying(IERC20(address(0)), usdtIn, refferal, msg.sender);
    }

    /**
     * @dev Buys tokens with Fiat, intialises buying process. Since when buying with Fiat transaction is Originating from Wert.io, msg.sender is Wert.io, so we need to pass the userWallet address
     * @param refferal The address of the refferee (if any), address(0) if none
     * @notice The ETH sent is transformed (not swapped) to USDT and then used to buy tokens
     */
    function buyTokensFiat(
        address userWallet,
        address refferal
    ) external payable {
        uint256 usdtIn = convertEthToUsd(msg.value);
        initializeTokenBuying(IERC20(address(0)), usdtIn, refferal, userWallet);
    }

    /**
     * @dev Claims tokens after the presale has ended
     * @notice The tokens are claimed to the address which bought them
     */
    function claimTokens() public nonReentrant {
        require(unclaimedBalance[msg.sender] > 0, "No tokens to claim");

        require(isWithdrawingAllowed, "Withdrawals are not allowed yet");

        uint256 tokensToClaim = unclaimedBalance[msg.sender];
        unclaimedBalance[msg.sender] = 0;

        token.transfer(msg.sender, tokensToClaim);

        emit TokensClaimed(msg.sender, tokensToClaim);
    }

    /**
     * @dev Claims the refferal (affiliate) tokens after the presale has ended
     * @notice The tokens are claimed to the address which bought them
     */
    function claimRefferalTokens() public nonReentrant {
        require(unclaimedRefferalBalance[msg.sender] > 0, "No tokens to claim");

        require(isWithdrawingAllowed, "Withdrawals are not allowed yet");

        uint256 tokensToClaim = unclaimedRefferalBalance[msg.sender];
        unclaimedRefferalBalance[msg.sender] = 0;

        token.transferFrom(affiliateRewardAddress, msg.sender, tokensToClaim);

        emit TokensClaimed(msg.sender, tokensToClaim);
    }

    /**
     * @dev Withdraw ETH from the contract to the sender's wallet.
     * @notice Only callable by the owner
     */
    function withdrawEth() public onlyOwner nonReentrant {
        uint256 balance = address(this).balance;
        (bool sent, ) = payable(msg.sender).call{value: balance}("");
        require(sent, "Failed to send Ether");
    }

    /**
     * @dev Withdraw USDC from the contract to the sender's wallet.
     * @notice Only callable by the owner
     */
    function withdrawUsdc() public onlyOwner nonReentrant {
        uint256 balance = usdc.balanceOf(address(this));
        usdc.transfer(msg.sender, balance);
    }

    /**
     * @dev Withdraw USDT from the contract to the sender's wallet.
     * @notice Only callable by the owner
     */
    function withdrawUsdt() public onlyOwner nonReentrant {
        uint256 balance = usdt.balanceOf(address(this));
        usdt.transfer(msg.sender, balance);
    }

    /**
     * @dev Withdraw NET from the contract to the sender's wallet.
     * @notice Only callable by the owner
     */
    function withdrawNet() public onlyOwner nonReentrant {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(msg.sender, balance);
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (utils/cryptography/MerkleProof.sol)

pragma solidity ^0.8.0;

/**
 * @dev These functions deal with verification of Merkle Tree proofs.
 *
 * The tree and the proofs can be generated using our
 * https://github.com/OpenZeppelin/merkle-tree[JavaScript library].
 * You will find a quickstart guide in the readme.
 *
 * WARNING: You should avoid using leaf values that are 64 bytes long prior to
 * hashing, or use a hash function other than keccak256 for hashing leaves.
 * This is because the concatenation of a sorted pair of internal nodes in
 * the merkle tree could be reinterpreted as a leaf value.
 * OpenZeppelin's JavaScript library generates merkle trees that are safe
 * against this attack out of the box.
 */
library MerkleProof {
    /**
     * @dev Returns true if a `leaf` can be proved to be a part of a Merkle tree
     * defined by `root`. For this, a `proof` must be provided, containing
     * sibling hashes on the branch from the leaf to the root of the tree. Each
     * pair of leaves and each pair of pre-images are assumed to be sorted.
     */
    function verify(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProof(proof, leaf) == root;
    }

    /**
     * @dev Calldata version of {verify}
     *
     * _Available since v4.7._
     */
    function verifyCalldata(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        return processProofCalldata(proof, leaf) == root;
    }

    /**
     * @dev Returns the rebuilt hash obtained by traversing a Merkle tree up
     * from `leaf` using `proof`. A `proof` is valid if and only if the rebuilt
     * hash matches the root of the tree. When processing the proof, the pairs
     * of leafs & pre-images are assumed to be sorted.
     *
     * _Available since v4.4._
     */
    function processProof(bytes32[] memory proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Calldata version of {processProof}
     *
     * _Available since v4.7._
     */
    function processProofCalldata(bytes32[] calldata proof, bytes32 leaf) internal pure returns (bytes32) {
        bytes32 computedHash = leaf;
        for (uint256 i = 0; i < proof.length; i++) {
            computedHash = _hashPair(computedHash, proof[i]);
        }
        return computedHash;
    }

    /**
     * @dev Returns true if the `leaves` can be simultaneously proven to be a part of a merkle tree defined by
     * `root`, according to `proof` and `proofFlags` as described in {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerify(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProof(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Calldata version of {multiProofVerify}
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function multiProofVerifyCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32 root,
        bytes32[] memory leaves
    ) internal pure returns (bool) {
        return processMultiProofCalldata(proof, proofFlags, leaves) == root;
    }

    /**
     * @dev Returns the root of a tree reconstructed from `leaves` and sibling nodes in `proof`. The reconstruction
     * proceeds by incrementally reconstructing all inner nodes by combining a leaf/inner node with either another
     * leaf/inner node or a proof sibling node, depending on whether each `proofFlags` item is true or false
     * respectively.
     *
     * CAUTION: Not all merkle trees admit multiproofs. To use multiproofs, it is sufficient to ensure that: 1) the tree
     * is complete (but not necessarily perfect), 2) the leaves to be proven are in the opposite order they are in the
     * tree (i.e., as seen from right to left starting at the deepest layer and continuing at the next layer).
     *
     * _Available since v4.7._
     */
    function processMultiProof(
        bytes32[] memory proof,
        bool[] memory proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    /**
     * @dev Calldata version of {processMultiProof}.
     *
     * CAUTION: Not all merkle trees admit multiproofs. See {processMultiProof} for details.
     *
     * _Available since v4.7._
     */
    function processMultiProofCalldata(
        bytes32[] calldata proof,
        bool[] calldata proofFlags,
        bytes32[] memory leaves
    ) internal pure returns (bytes32 merkleRoot) {
        // This function rebuild the root hash by traversing the tree up from the leaves. The root is rebuilt by
        // consuming and producing values on a queue. The queue starts with the `leaves` array, then goes onto the
        // `hashes` array. At the end of the process, the last hash in the `hashes` array should contain the root of
        // the merkle tree.
        uint256 leavesLen = leaves.length;
        uint256 totalHashes = proofFlags.length;

        // Check proof validity.
        require(leavesLen + proof.length - 1 == totalHashes, "MerkleProof: invalid multiproof");

        // The xxxPos values are "pointers" to the next value to consume in each array. All accesses are done using
        // `xxx[xxxPos++]`, which return the current value and increment the pointer, thus mimicking a queue's "pop".
        bytes32[] memory hashes = new bytes32[](totalHashes);
        uint256 leafPos = 0;
        uint256 hashPos = 0;
        uint256 proofPos = 0;
        // At each step, we compute the next hash using two values:
        // - a value from the "main queue". If not all leaves have been consumed, we get the next leaf, otherwise we
        //   get the next hash.
        // - depending on the flag, either another value for the "main queue" (merging branches) or an element from the
        //   `proof` array.
        for (uint256 i = 0; i < totalHashes; i++) {
            bytes32 a = leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++];
            bytes32 b = proofFlags[i] ? leafPos < leavesLen ? leaves[leafPos++] : hashes[hashPos++] : proof[proofPos++];
            hashes[i] = _hashPair(a, b);
        }

        if (totalHashes > 0) {
            return hashes[totalHashes - 1];
        } else if (leavesLen > 0) {
            return leaves[0];
        } else {
            return proof[0];
        }
    }

    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        return a < b ? _efficientHash(a, b) : _efficientHash(b, a);
    }

    function _efficientHash(bytes32 a, bytes32 b) private pure returns (bytes32 value) {
        /// @solidity memory-safe-assembly
        assembly {
            mstore(0x00, a)
            mstore(0x20, b)
            value := keccak256(0x00, 0x40)
        }
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts v4.4.1 (utils/Context.sol)

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

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.6.0) (token/ERC20/IERC20.sol)

pragma solidity ^0.8.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.8.0) (security/ReentrancyGuard.sol)

pragma solidity ^0.8.0;

/**
 * @dev Contract module that helps prevent reentrant calls to a function.
 *
 * Inheriting from `ReentrancyGuard` will make the {nonReentrant} modifier
 * available, which can be applied to functions to make sure there are no nested
 * (reentrant) calls to them.
 *
 * Note that because there is a single `nonReentrant` guard, functions marked as
 * `nonReentrant` may not call one another. This can be worked around by making
 * those functions `private`, and then adding `external` `nonReentrant` entry
 * points to them.
 *
 * TIP: If you would like to learn more about reentrancy and alternative ways
 * to protect against it, check out our blog post
 * https://blog.openzeppelin.com/reentrancy-after-istanbul/[Reentrancy After Istanbul].
 */
abstract contract ReentrancyGuard {
    // Booleans are more expensive than uint256 or any type that takes up a full
    // word because each write operation emits an extra SLOAD to first read the
    // slot's contents, replace the bits taken up by the boolean, and then write
    // back. This is the compiler's defense against contract upgrades and
    // pointer aliasing, and it cannot be disabled.

    // The values being non-zero value makes deployment a bit more expensive,
    // but in exchange the refund on every call to nonReentrant will be lower in
    // amount. Since refunds are capped to a percentage of the total
    // transaction's gas, it is best to keep them low in cases like this one, to
    // increase the likelihood of the full refund coming into effect.
    uint256 private constant _NOT_ENTERED = 1;
    uint256 private constant _ENTERED = 2;

    uint256 private _status;

    constructor() {
        _status = _NOT_ENTERED;
    }

    /**
     * @dev Prevents a contract from calling itself, directly or indirectly.
     * Calling a `nonReentrant` function from another `nonReentrant`
     * function is not supported. It is possible to prevent this from happening
     * by making the `nonReentrant` function external, and making it call a
     * `private` function that does the actual work.
     */
    modifier nonReentrant() {
        _nonReentrantBefore();
        _;
        _nonReentrantAfter();
    }

    function _nonReentrantBefore() private {
        // On the first call to nonReentrant, _status will be _NOT_ENTERED
        require(_status != _ENTERED, "ReentrancyGuard: reentrant call");

        // Any calls to nonReentrant after this point will fail
        _status = _ENTERED;
    }

    function _nonReentrantAfter() private {
        // By storing the original value once again, a refund is triggered (see
        // https://eips.ethereum.org/EIPS/eip-2200)
        _status = _NOT_ENTERED;
    }
}

// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v4.7.0) (access/Ownable.sol)

pragma solidity ^0.8.0;

import "../utils/Context.sol";

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IAggregatorV3 {
  function latestRoundData()
    external
    view
    returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    );
}